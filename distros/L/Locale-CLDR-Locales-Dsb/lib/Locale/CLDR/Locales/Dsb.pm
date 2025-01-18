=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Dsb - Package for language Lower Sorbian

=cut

package Locale::CLDR::Locales::Dsb;
# This file auto generated from Data\common\main\dsb.xml
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
				'aa' => 'afaršćina',
 				'ab' => 'abchazšćina',
 				'ace' => 'achinezišćina',
 				'ada' => 'adangmešćina',
 				'ady' => 'adyghešćina',
 				'af' => 'afrikans',
 				'agq' => 'aghem',
 				'ain' => 'ainušćina',
 				'ak' => 'akanšćina',
 				'ale' => 'aleutišćina',
 				'alt' => 'pódpołdnjowa altaišćina',
 				'am' => 'amharšćina',
 				'an' => 'aragonšćina',
 				'ang' => 'anglosaksojšćina',
 				'ann' => 'obološćina',
 				'anp' => 'angikašćina',
 				'ar' => 'arabšćina',
 				'ar_001' => 'moderna wusokoarabšćina',
 				'arn' => 'arawkašćina',
 				'arp' => 'arapahošćina',
 				'ars' => 'najdi arabšćina',
 				'as' => 'asamšćina',
 				'asa' => 'pare',
 				'ast' => 'asturšćina',
 				'atj' => 'atikamekwišćina',
 				'av' => 'awaršćina',
 				'awa' => 'awandhišćina',
 				'ay' => 'aymaršćina',
 				'az' => 'azerbajdžanšćina',
 				'ba' => 'baškiršćina',
 				'ban' => 'balinezišćina',
 				'bas' => 'basaa',
 				'be' => 'běłorušćina',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bg' => 'bulgaršćina',
 				'bgc' => 'haryanvišćina',
 				'bho' => 'bhojpurišćina',
 				'bi' => 'bislamšćina',
 				'bin' => 'binišćina',
 				'bla' => 'siksikášćina',
 				'blo' => 'aniišćina',
 				'bm' => 'bambara',
 				'bn' => 'bengalšćina',
 				'bo' => 'tibetšćina',
 				'br' => 'bretonšćina',
 				'brx' => 'bodo',
 				'bs' => 'bosnišćina',
 				'bug' => 'bugišćina',
 				'byn' => 'blinšćina',
 				'ca' => 'katanlanšćina',
 				'cay' => 'cayugašćina',
 				'ccp' => 'čakma',
 				'ce' => 'čečenšćina',
 				'ceb' => 'cebuanšćina',
 				'cgg' => 'chiga',
 				'ch' => 'čamoršćina',
 				'chk' => 'chuukezišćina',
 				'chm' => 'marišćina',
 				'cho' => 'choctawšćina',
 				'chp' => 'chipewyanšćina',
 				'chr' => 'cherokee',
 				'chy' => 'cheyennešćina',
 				'ckb' => 'sorani',
 				'ckb@alt=variant' => 'centralna kurdišćina',
 				'clc' => 'chilcotinšćina',
 				'co' => 'korsišćina',
 				'cr' => 'kri',
 				'crg' => 'michifšćina',
 				'crj' => 'krotkozajtšna creešćina',
 				'crk' => 'plains creešćina',
 				'crl' => 'dłujkozajtšna creešćina',
 				'crm' => 'moode creešćina',
 				'crr' => 'carolina algonquianšćina',
 				'cs' => 'češćina',
 				'csw' => 'swampy creešćina',
 				'cu' => 'cerkwinosłowjańšćina',
 				'cv' => 'chuvashišćina',
 				'cy' => 'walizišćina',
 				'da' => 'danšćina',
 				'dak' => 'dakotašćina',
 				'dar' => 'dargwašćina',
 				'dav' => 'taita',
 				'de' => 'nimšćina',
 				'de_AT' => 'awstriska nimšćina',
 				'de_CH' => 'šwicarska wusokonimšćina',
 				'dgr' => 'dogribšćina',
 				'dje' => 'zarma',
 				'doi' => 'dogrišćina',
 				'dsb' => 'dolnoserbšćina',
 				'dua' => 'duala',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazagašćina',
 				'ebu' => 'embu',
 				'ee' => 'ewe',
 				'efi' => 'efikšćina',
 				'eka' => 'ekajukšćina',
 				'el' => 'grichišćina',
 				'en' => 'engelšćina',
 				'en_AU' => 'awstralska engelšćina',
 				'en_CA' => 'kanadiska engelšćina',
 				'en_GB' => 'britiska engelšćina',
 				'en_GB@alt=short' => 'UK-engelšćina',
 				'en_US' => 'ameriska engelšćina',
 				'en_US@alt=short' => 'US-engelšćina',
 				'eo' => 'esperanto',
 				'es' => 'špańšćina',
 				'es_419' => 'łatyńskoamerikańska špańšćina',
 				'es_ES' => 'europejska špańšćina',
 				'es_MX' => 'mexikańska špańšćina',
 				'et' => 'estišćina',
 				'eu' => 'baskišćina',
 				'ewo' => 'ewondo',
 				'fa' => 'persišćina',
 				'fa_AF' => 'dari',
 				'ff' => 'fulbšćina',
 				'fi' => 'finšćina',
 				'fil' => 'filipinšćina',
 				'fj' => 'fidžišćina',
 				'fo' => 'ferejšćina',
 				'fon' => 'fonšćina',
 				'fr' => 'francojšćina',
 				'fr_CA' => 'kanadiska francojšćina',
 				'fr_CH' => 'šwicarska francojšćina',
 				'frc' => 'cajun francojšćina',
 				'frr' => 'pódpołnocna frizišćina',
 				'fur' => 'friulšćina',
 				'fy' => 'frizišćina',
 				'ga' => 'iršćina',
 				'gaa' => 'gašćina',
 				'gag' => 'gagauzšćina',
 				'gd' => 'šotišćina',
 				'gez' => 'geezišćina',
 				'gil' => 'gilbertezišćina',
 				'gl' => 'galicišćina',
 				'gn' => 'guarani',
 				'gor' => 'gorontalošćina',
 				'got' => 'gotišćina',
 				'gsw' => 'šwicarska nimšćina',
 				'gu' => 'gudžaratšćina',
 				'guz' => 'gusii',
 				'gv' => 'manšćina',
 				'gwi' => 'gwichʼinšćina',
 				'ha' => 'hausa',
 				'hai' => 'haidašćina',
 				'haw' => 'hawaiišćina',
 				'hax' => 'pódpołdnjowa haidašćina',
 				'he' => 'hebrejšćina',
 				'hi' => 'hindišćina',
 				'hil' => 'hiligaynonšćina',
 				'hmn' => 'hmongšćina',
 				'hr' => 'chorwatšćina',
 				'hsb' => 'górnoserbšćina',
 				'ht' => 'haitišćina',
 				'hu' => 'hungoršćina',
 				'hup' => 'hupašćina',
 				'hur' => 'halkomelemšćina',
 				'hy' => 'armeńšćina',
 				'hz' => 'hererošćina',
 				'ia' => 'interlingua',
 				'iba' => 'ibanšćina',
 				'ibb' => 'ibibiošćina',
 				'id' => 'indonešćina',
 				'ie' => 'interlinguešćina',
 				'ig' => 'igbo',
 				'ii' => 'sichuan yi',
 				'ik' => 'inupiak',
 				'ikt' => 'pódwjacornokanadiska inuktitutšćina',
 				'ilo' => 'ilokošćina',
 				'inh' => 'ingushišćina',
 				'io' => 'ido',
 				'is' => 'islandšćina',
 				'it' => 'italšćina',
 				'iu' => 'inuitšćina',
 				'ja' => 'japańšćina',
 				'jbo' => 'lojbanšćina',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jv' => 'javašćina',
 				'ka' => 'georgišćina',
 				'kab' => 'kabylšćina',
 				'kac' => 'kachinšćina',
 				'kaj' => 'jjušćina',
 				'kam' => 'kamba',
 				'kbd' => 'kabardianšćina',
 				'kcg' => 'tyapšćina',
 				'kde' => 'makonde',
 				'kea' => 'kapverdšćina',
 				'kfo' => 'korošćina',
 				'kgp' => 'kaingangšćina',
 				'kha' => 'khasišćina',
 				'khq' => 'koyra chiini',
 				'ki' => 'kikuyu',
 				'kj' => 'kuanyamašćina',
 				'kk' => 'kazachšćina',
 				'kkj' => 'kako',
 				'kl' => 'grönlandšćina',
 				'kln' => 'kalenjin',
 				'km' => 'kambodžanšćina',
 				'kmb' => 'kimbundušćina',
 				'kn' => 'kannadšćina',
 				'ko' => 'korejańšćina',
 				'koi' => 'komi-permyak',
 				'kok' => 'konkani',
 				'kpe' => 'kpellešćina',
 				'kr' => 'kanurišćina',
 				'krc' => 'karachay-balkaršćina',
 				'kri' => 'krio',
 				'krl' => 'karelianšćina',
 				'kru' => 'kurukhšćina',
 				'ks' => 'kašmiršćina',
 				'ksb' => 'šambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kelnšćina',
 				'ku' => 'kurdišćina',
 				'kum' => 'kumykšćina',
 				'kv' => 'komišćina',
 				'kw' => 'kornišćina',
 				'kwk' => 'kwakʼwalašćina',
 				'kxv' => 'kuvišćina',
 				'ky' => 'kirgišćina',
 				'la' => 'łatyńšćina',
 				'lad' => 'ladinšćina',
 				'lag' => 'langi',
 				'lb' => 'luxemburgšćina',
 				'lez' => 'lezgianšćina',
 				'lg' => 'gandšćina',
 				'li' => 'limburšćina',
 				'lij' => 'liguriańšćina',
 				'lil' => 'lillooetšćina',
 				'lkt' => 'lakotšćina',
 				'lmo' => 'lombardišćina',
 				'ln' => 'lingala',
 				'lo' => 'laošćina',
 				'lou' => 'Louisiana kreolšćina',
 				'loz' => 'lozišćina',
 				'lrc' => 'pódpołnocna lurišćina',
 				'lsm' => 'saamiašćina',
 				'lt' => 'litawšćina',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-luluašćina',
 				'lun' => 'lundašćina',
 				'lus' => 'mizošćina',
 				'luy' => 'luhya',
 				'lv' => 'letišćina',
 				'mad' => 'madurezišćina',
 				'mag' => 'magahišćina',
 				'mai' => 'maithilšćina',
 				'mak' => 'makasaršćina',
 				'mas' => 'masaišćina',
 				'mdf' => 'mokshašćina',
 				'men' => 'mendišćina',
 				'mer' => 'meru',
 				'mfe' => 'mauriciska kreolšćina',
 				'mg' => 'malgašćina',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'marshallezišćina',
 				'mi' => 'maorišćina',
 				'mic' => 'mi\'kmaqšćina',
 				'min' => 'minangkabaušćina',
 				'mk' => 'makedońšćina',
 				'ml' => 'malajamšćina',
 				'mn' => 'mongolšćina',
 				'mni' => 'manipuršćina',
 				'moe' => 'innu-aimunšćina',
 				'moh' => 'mohawkšćina',
 				'mos' => 'mossišćina',
 				'mr' => 'maratišćina',
 				'ms' => 'malajšćina',
 				'mt' => 'maltašćina',
 				'mua' => 'mundang',
 				'mul' => 'wěcejrěcne',
 				'mus' => 'krik',
 				'mwl' => 'mirandezišćina',
 				'my' => 'burmašćina',
 				'myv' => 'erzyašćina',
 				'mzn' => 'mazanderanšćina',
 				'na' => 'naurušćina',
 				'nap' => 'neapolitanšćina',
 				'naq' => 'nama',
 				'nb' => 'norwegske bokmål',
 				'nd' => 'pódpołnocne ndebele',
 				'nds' => 'dolnonimšćina',
 				'ne' => 'nepalšćina',
 				'new' => 'newarišćina',
 				'ng' => 'ndongašćina',
 				'nia' => 'niazišćina',
 				'niu' => 'niueanšćina',
 				'nl' => 'nižozemšćina',
 				'nl_BE' => 'flamšćina',
 				'nmg' => 'kwasio',
 				'nn' => 'norwegske nynorsk',
 				'nnh' => 'ngiemboon',
 				'no' => 'norwegšćina',
 				'nog' => 'nogaišćina',
 				'nqo' => 'n’ko',
 				'nr' => 'pódpołdnjowa ndebelšćina',
 				'nso' => 'połnocna sothošćina',
 				'nus' => 'nuer',
 				'nv' => 'navaho',
 				'ny' => 'nyanja',
 				'nyn' => 'nyankole',
 				'oc' => 'okcitanšćina',
 				'ojb' => 'dłujkowjacorna ojibwašćina',
 				'ojc' => 'centralna ojibwašćina',
 				'ojs' => 'oji-creešćina',
 				'ojw' => 'pódwjacorna ojibwašćina',
 				'oka' => 'okanaganšćina',
 				'om' => 'oromo',
 				'or' => 'orojišćina',
 				'os' => 'osetšćina',
 				'pa' => 'pandžabšćina',
 				'pag' => 'pangasinanšćina',
 				'pam' => 'pampangašćina',
 				'pap' => 'papiamentošćina',
 				'pau' => 'palauanšćina',
 				'pcm' => 'nigerijanski pidgin',
 				'pis' => 'pijinšćina',
 				'pl' => 'pólšćina',
 				'pqm' => 'maliseet-passamaquoddyšćina',
 				'prg' => 'prusčina',
 				'ps' => 'paštunšćina',
 				'pt' => 'portugalšćina',
 				'pt_BR' => 'brazilska portugalšćina',
 				'pt_PT' => 'europejska portugalšćina',
 				'qu' => 'kečua',
 				'quc' => 'kʼicheʼ',
 				'raj' => 'rajasthanišćina',
 				'rap' => 'rapanuišćina',
 				'rar' => 'rarotonganšćina',
 				'rhg' => 'rohingyašćina',
 				'rm' => 'retoromańšćina',
 				'rn' => 'kirundišćina',
 				'ro' => 'rumunšćina',
 				'ro_MD' => 'moldawišćina',
 				'rof' => 'rombo',
 				'ru' => 'rušćina',
 				'rup' => 'armanianšćina',
 				'rw' => 'kinjarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanskrit',
 				'sad' => 'sandawešćina',
 				'sah' => 'jakutšćina',
 				'saq' => 'samburu',
 				'sat' => 'santalšćina',
 				'sba' => 'ngambayšćina',
 				'sbp' => 'sangu',
 				'sc' => 'sardinšćina',
 				'scn' => 'sicilianišćina',
 				'sco' => 'scotšćina',
 				'sd' => 'sindšćina',
 				'se' => 'lapšćina',
 				'seh' => 'sena',
 				'ses' => 'koyra senni',
 				'sg' => 'sango',
 				'sh' => 'serbochorwatšćina',
 				'shi' => 'tašelhit',
 				'shn' => 'shanšćina',
 				'si' => 'singalšćina',
 				'sk' => 'słowakšćina',
 				'sl' => 'słowjeńšćina',
 				'slh' => 'pódpołdnjowa lushootseedšćina',
 				'sm' => 'samošćina',
 				'sma' => 'pódpołdnjowa samišćina',
 				'smj' => 'lule-samišćina',
 				'smn' => 'inari-samišćina',
 				'sms' => 'skolt-samišćina',
 				'sn' => 'šonšćina',
 				'snk' => 'soninkešćina',
 				'so' => 'somališćina',
 				'sq' => 'albanšćina',
 				'sr' => 'serbišćina',
 				'srn' => 'sranan tongošćina',
 				'ss' => 'siswati',
 				'st' => 'pódpołdnjowa sotšćina (Sesotho)',
 				'stq' => 'saterfrizišćina',
 				'str' => 'straits salishšćina',
 				'su' => 'sundanšćina',
 				'suk' => 'sukumašćina',
 				'sv' => 'šwedšćina',
 				'sw' => 'swahilišćina',
 				'sw_CD' => 'kongojska swahilišćina',
 				'swb' => 'comorianšćina',
 				'syr' => 'syriacšćina',
 				'szl' => 'šlazyńšćina',
 				'ta' => 'tamilšćina',
 				'tce' => 'pódpołdnjowa tutchonšćina',
 				'te' => 'telugšćina',
 				'tem' => 'timnešćina',
 				'teo' => 'teso',
 				'tet' => 'tetumšćina',
 				'tg' => 'tadžikišćina',
 				'tgx' => 'tagishšćina',
 				'th' => 'thailandšćina',
 				'tht' => 'tahltanšćina',
 				'ti' => 'tigrinja',
 				'tig' => 'tigrešćina',
 				'tk' => 'turkmeńšćina',
 				'tl' => 'tagalog',
 				'tlh' => 'klingonšćina',
 				'tli' => 'tlingitšćina',
 				'tn' => 'tswana',
 				'to' => 'tonganšćina',
 				'tok' => 'toki ponašćina',
 				'tpi' => 'tok pisinšćina',
 				'tr' => 'turkojšćina',
 				'trv' => 'tarokošćina',
 				'ts' => 'tsonga',
 				'tt' => 'tataršćina',
 				'ttm' => 'połnocna tutchonšćina',
 				'tum' => 'tumbukašćina',
 				'tvl' => 'tuvalušćina',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitišćina',
 				'tyv' => 'tuvinianšćina',
 				'tzm' => 'centralnoatlaski tamazight',
 				'udm' => 'udmurtšćina',
 				'ug' => 'ujguršćina',
 				'uk' => 'ukrainšćina',
 				'umb' => 'umbundušćina',
 				'und' => 'njeznata rěc',
 				'ur' => 'urdušćina',
 				'uz' => 'usbekšćina',
 				've' => 'vendašćina',
 				'vec' => 'venetišćina',
 				'vi' => 'vietnamšćina',
 				'vmw' => 'makhuwašćina',
 				'vo' => 'volapük',
 				'vun' => 'vunjo',
 				'wa' => 'walonšćina',
 				'wae' => 'walzeršćina',
 				'wal' => 'wolayttašćina',
 				'war' => 'warayšćina',
 				'wo' => 'wolof',
 				'wuu' => 'wu chinšćina',
 				'xal' => 'kalmykšćina',
 				'xh' => 'xhosa',
 				'xnr' => 'kangrišćina',
 				'xog' => 'soga',
 				'yav' => 'yangben',
 				'ybb' => 'yembašćina',
 				'yi' => 'jidišćina',
 				'yo' => 'jorubšćina',
 				'yrl' => 'nheengatušćina',
 				'yue' => 'kantonšćina',
 				'yue@alt=menu' => 'chinšćina (kantonšćina)',
 				'za' => 'zhuang',
 				'zgh' => 'standardny marokkański tamazight',
 				'zh' => 'chinšćina',
 				'zh@alt=menu' => 'chinšćina (mandarin)',
 				'zh_Hans' => 'chinšćina (zjadnorjona)',
 				'zh_Hant' => 'chinšćina (tradicionalna)',
 				'zu' => 'zulu',
 				'zun' => 'zunišćina',
 				'zxx' => 'žedno rěcne wopśimjeśe',
 				'zza' => 'zazašćina',

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
			'Adlm' => 'adlamske pismo',
 			'Arab' => 'arabski',
 			'Aran' => 'nastaliqske pismo',
 			'Armn' => 'armeński',
 			'Beng' => 'bengalski',
 			'Bopo' => 'bopomofo',
 			'Brai' => 'braillowe pismo',
 			'Cakm' => 'chakmaske pismo',
 			'Cans' => 'zjadnotnjone kanadiske aboriginske złožkowe pismo',
 			'Cher' => 'cherokeeske pismo',
 			'Cyrl' => 'kyriliski',
 			'Deva' => 'devanagari',
 			'Ethi' => 'etiopiski',
 			'Geor' => 'georgiski',
 			'Grek' => 'grichiski',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'chinšćina z bopomofo',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hans' => 'zjadnorjone',
 			'Hans@alt=stand-alone' => 'zjadnorjone han',
 			'Hant' => 'tradionalne',
 			'Hant@alt=stand-alone' => 'tradicionalne han',
 			'Hebr' => 'hebrejski',
 			'Hira' => 'hiragana',
 			'Hrkt' => 'japańske złožkowe pismo',
 			'Jamo' => 'jamo',
 			'Jpan' => 'japański',
 			'Kana' => 'katakana',
 			'Khmr' => 'khmer',
 			'Knda' => 'kannada',
 			'Kore' => 'korejski',
 			'Laoo' => 'laoski',
 			'Latn' => 'łatyński',
 			'Mlym' => 'malayalamski',
 			'Mong' => 'mongolski',
 			'Mtei' => 'meitei-mayekse pismo',
 			'Mymr' => 'burmaski',
 			'Nkoo' => 'n’Koske pismo',
 			'Olck' => 'ol-chikiske pismo',
 			'Orya' => 'oriya',
 			'Rohg' => 'hanifiske pismo',
 			'Sinh' => 'singhaleski',
 			'Sund' => 'sundaneske pismo',
 			'Syrc' => 'syriacske pismo',
 			'Taml' => 'tamilski',
 			'Telu' => 'telugu',
 			'Tfng' => 'tifinanghske pismo',
 			'Thaa' => 'thaana',
 			'Thai' => 'thaiski',
 			'Tibt' => 'tibetski',
 			'Vaii' => 'vaiske pismo',
 			'Yiii' => 'yiske pismo',
 			'Zmth' => 'matematiski zapis',
 			'Zsye' => 'emoji',
 			'Zsym' => 'symbole',
 			'Zxxx' => 'bźez pisma',
 			'Zyyy' => 'powšykne',
 			'Zzzz' => 'njeznate pismo',

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
			'001' => 'swět',
 			'002' => 'Afrika',
 			'003' => 'Pódpołnocna Amerika',
 			'005' => 'Pódpołdnjowa Amerika',
 			'009' => 'Oceaniska',
 			'011' => 'Pódwjacorna Afrika',
 			'013' => 'Srjejźna Amerika',
 			'014' => 'pódzajtšna Afrika',
 			'015' => 'pódpołnocna Afrika',
 			'017' => 'srjejźna Afrika',
 			'018' => 'pódpołdnjowa Afrika',
 			'019' => 'Amerika',
 			'021' => 'pódpołnocny ameriski kontinent',
 			'029' => 'Karibiska',
 			'030' => 'pódzajtšna Azija',
 			'034' => 'pódpołdnjowa Azija',
 			'035' => 'krotkozajtšna Azija',
 			'039' => 'pódpołdnjowa Europa',
 			'053' => 'Awstralazija',
 			'054' => 'Melaneziska',
 			'057' => 'Mikroneziska (kupowy region)',
 			'061' => 'Polyneziska',
 			'142' => 'Azija',
 			'143' => 'centralna Azija',
 			'145' => 'pódwjacorna Azija',
 			'150' => 'Europa',
 			'151' => 'pódzajtšna Europa',
 			'154' => 'pódpołnocna Europa',
 			'155' => 'pódwjacorna Europa',
 			'202' => 'subsaharojska Afrika',
 			'419' => 'Łatyńska Amerika',
 			'AC' => 'Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Zjadnośone arabiske emiraty',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua a Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albańska',
 			'AM' => 'Armeńska',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktis',
 			'AR' => 'Argentinska',
 			'AS' => 'Ameriska Samoa',
 			'AT' => 'Awstriska',
 			'AU' => 'Awstralska',
 			'AW' => 'Aruba',
 			'AX' => 'Åland',
 			'AZ' => 'Azerbajdžan',
 			'BA' => 'Bosniska a Hercegowina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladeš',
 			'BE' => 'Belgiska',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgarska',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'St. Barthélemy',
 			'BM' => 'Bermudy',
 			'BN' => 'Brunei',
 			'BO' => 'Boliwiska',
 			'BQ' => 'Karibiska Nižozemska',
 			'BR' => 'Brazilska',
 			'BS' => 'Bahamy',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouvetowa kupa',
 			'BW' => 'Botswana',
 			'BY' => 'Běłoruska',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kokosowe kupy',
 			'CD' => 'Kongo-Kinshasa',
 			'CD@alt=variant' => 'Kongo (Demokratiska republika)',
 			'CF' => 'Centralnoafriska republika',
 			'CG' => 'Kongo-Brazzaville',
 			'CG@alt=variant' => 'Kongo (Republika)',
 			'CH' => 'Šwicarska',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Słonowokósćowy pśibrjog',
 			'CK' => 'Cookowe kupy',
 			'CL' => 'Chilska',
 			'CM' => 'Kamerun',
 			'CN' => 'China',
 			'CO' => 'Kolumbiska',
 			'CP' => 'Clippertonowa kupa',
 			'CR' => 'Kosta Rika',
 			'CU' => 'Kuba',
 			'CV' => 'Kap Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Gódowne kupy',
 			'CY' => 'Cypriska',
 			'CZ' => 'Česka republika',
 			'DE' => 'Nimska',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Džibuti',
 			'DK' => 'Dańska',
 			'DM' => 'Dominika',
 			'DO' => 'Dominikańska republika',
 			'DZ' => 'Algeriska',
 			'EA' => 'Ceuta a Melilla',
 			'EC' => 'Ekwador',
 			'EE' => 'Estniska',
 			'EG' => 'Egyptojska',
 			'EH' => 'Pódwjacorna Sahara',
 			'ER' => 'Eritreja',
 			'ES' => 'Špańska',
 			'ET' => 'Etiopiska',
 			'EU' => 'Europska unija',
 			'EZ' => 'europasmo',
 			'FI' => 'Finska',
 			'FJ' => 'Fidži',
 			'FK' => 'Falklandske kupy',
 			'FK@alt=variant' => 'Falklandske kupy (Malwiny)',
 			'FM' => 'Mikroneziska',
 			'FO' => 'Färöje',
 			'FR' => 'Francojska',
 			'GA' => 'Gabun',
 			'GB' => 'Zjadnośone kralejstwo',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Grenada',
 			'GE' => 'Georgiska',
 			'GF' => 'Francojska Guyana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grönlandska',
 			'GM' => 'Gambija',
 			'GN' => 'Gineja',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Ekwatorialna Gineja',
 			'GR' => 'Grichiska',
 			'GS' => 'Pódpołdnjowa Georgiska a Pódpołdnjowe Sandwichowe kupy',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Gineja-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Wósebna zastojnstwowa cona Hongkong',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heardowa kupa a McDonaldowe kupy',
 			'HN' => 'Honduras',
 			'HR' => 'Chorwatska',
 			'HT' => 'Haiti',
 			'HU' => 'Hungorska',
 			'IC' => 'Kanariske kupy',
 			'ID' => 'Indoneziska',
 			'IE' => 'Irska',
 			'IL' => 'Israel',
 			'IM' => 'Man',
 			'IN' => 'Indiska',
 			'IO' => 'Britiski indiskooceaniski teritorium',
 			'IO@alt=chagos' => 'Chagoske kupy',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Islandska',
 			'IT' => 'Italska',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordaniska',
 			'JP' => 'Japańska',
 			'KE' => 'Kenia',
 			'KG' => 'Kirgizistan',
 			'KH' => 'Kambodža',
 			'KI' => 'Kiribati',
 			'KM' => 'Komory',
 			'KN' => 'St. Kitts a Nevis',
 			'KP' => 'Pódpołnocna Koreja',
 			'KR' => 'Pódpołdnjowa Koreja',
 			'KW' => 'Kuwait',
 			'KY' => 'Kajmaniske kupy',
 			'KZ' => 'Kazachstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'St. Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberija',
 			'LS' => 'Lesotho',
 			'LT' => 'Litawska',
 			'LU' => 'Luxemburgska',
 			'LV' => 'Letiska',
 			'LY' => 'Libyska',
 			'MA' => 'Marokko',
 			'MC' => 'Monaco',
 			'MD' => 'Moldawska',
 			'ME' => 'Carna Góra',
 			'MF' => 'St. Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshallowe kupy',
 			'MK' => 'Pódpołnocna Makedańska',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar',
 			'MN' => 'Mongolska',
 			'MO' => 'Wósebna zastojnstwowa cona Macao',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Pódpołnocne Mariany',
 			'MQ' => 'Martinique',
 			'MR' => 'Mawretańska',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Malediwy',
 			'MW' => 'Malawi',
 			'MX' => 'Mexiko',
 			'MY' => 'Malajzija',
 			'MZ' => 'Mosambik',
 			'NA' => 'Namibija',
 			'NC' => 'Nowa Kaledoniska',
 			'NE' => 'Niger',
 			'NF' => 'Norfolkowa kupa',
 			'NG' => 'Nigerija',
 			'NI' => 'Nikaragua',
 			'NL' => 'Nižozemska',
 			'NO' => 'Norwegska',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nowoseelandska',
 			'NZ@alt=variant' => 'Aotearoa Nowoseelandska',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Francojska Polyneziska',
 			'PG' => 'Papua-Neuguinea',
 			'PH' => 'Filipiny',
 			'PK' => 'Pakistan',
 			'PL' => 'Pólska',
 			'PM' => 'St. Pierre a Miquelon',
 			'PN' => 'Pitcairnowe kupy',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestinski awtonomny teritorium',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugalska',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Katar',
 			'QO' => 'wenkowna Oceaniska',
 			'RE' => 'Réunion',
 			'RO' => 'Rumuńska',
 			'RS' => 'Serbiska',
 			'RU' => 'Ruska',
 			'RW' => 'Ruanda',
 			'SA' => 'Saudi-Arabiska',
 			'SB' => 'Salomony',
 			'SC' => 'Seychelle',
 			'SD' => 'Sudan',
 			'SE' => 'Šwedska',
 			'SG' => 'Singapur',
 			'SH' => 'St. Helena',
 			'SI' => 'Słowjeńska',
 			'SJ' => 'Svalbard a Jan Mayen',
 			'SK' => 'Słowakska',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalija',
 			'SR' => 'Surinamska',
 			'SS' => 'Pódpołdnjowy Sudan',
 			'ST' => 'São Tomé a Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syriska',
 			'SZ' => 'Swasiska',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks a Caicos kupy',
 			'TD' => 'Čad',
 			'TF' => 'Francojski pódpołdnjowy a antarktiski teritorium',
 			'TG' => 'Togo',
 			'TH' => 'Thailandska',
 			'TJ' => 'Tadźikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Pódzajtšny Timor',
 			'TM' => 'Turkmeniska',
 			'TN' => 'Tuneziska',
 			'TO' => 'Tonga',
 			'TR' => 'Turkojska',
 			'TT' => 'Trinidad a Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tansanija',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'UM' => 'Ameriska Oceaniska',
 			'UN' => 'Zjadnośone narody',
 			'US' => 'Zjadnośone staty Ameriki',
 			'US@alt=short' => 'USA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatikańske město',
 			'VC' => 'St. Vincent a Grenadiny',
 			'VE' => 'Venezuela',
 			'VG' => 'Britiske kněžniske kupy',
 			'VI' => 'Ameriske kněžniske kupy',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis a Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'pseudo-akcenty',
 			'XB' => 'pseudo-bidi',
 			'XK' => 'Kosowo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Pódpołdnjowa Afrika (Republika)',
 			'ZM' => 'Sambija',
 			'ZW' => 'Simbabwe',
 			'ZZ' => 'njeznaty region',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'kalender',
 			'cf' => 'format płaśidła',
 			'collation' => 'sortěrowański slěd',
 			'currency' => 'pjenjeze',
 			'hc' => 'góźinowy cyklus (12 vs 24)',
 			'lb' => 'system łamanja smužkow',
 			'ms' => 'system měrow',
 			'numbers' => 'licby',

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
 				'buddhist' => q{buddhistiski kalender},
 				'chinese' => q{chinski kalender},
 				'coptic' => q{koptiski kalendaŕ},
 				'dangi' => q{dangi kalender},
 				'ethiopic' => q{etiopiski kalender},
 				'ethiopic-amete-alem' => q{etiopiski amete-alem-kalendaŕ},
 				'gregorian' => q{gregoriański kalender},
 				'hebrew' => q{žydojski kalender},
 				'islamic' => q{islamski kalender},
 				'islamic-civil' => q{islamski ciwilny kalendaŕ},
 				'islamic-umalqura' => q{islamski umalqui-kalendaŕ},
 				'iso8601' => q{iso-8601-kalender},
 				'japanese' => q{japański kalender},
 				'persian' => q{persiski kalender},
 				'roc' => q{kalender republiki China},
 			},
 			'cf' => {
 				'account' => q{knigływjeźeński format płaśidła},
 				'standard' => q{standardny format płaśidła},
 			},
 			'collation' => {
 				'ducet' => q{sortěrowański slěd pó Unicoźe},
 				'search' => q{powšykne pytanje},
 				'standard' => q{standardny sortěrowański slěd},
 			},
 			'hc' => {
 				'h11' => q{12-góźinowy cyklus (0-11)},
 				'h12' => q{12-góźinowy cyklus (1-12)},
 				'h23' => q{24-góźinowy cyklus (0-23)},
 				'h24' => q{24-góźinowy cyklus (1-24)},
 			},
 			'lb' => {
 				'loose' => q{lichy stil łamanja smužkow},
 				'normal' => q{běžny stil łamanja smužkow},
 				'strict' => q{kšuty stil łamanja smužkow},
 			},
 			'ms' => {
 				'metric' => q{metriski system},
 				'uksystem' => q{britiski system měrow},
 				'ussystem' => q{amerikański system měrow},
 			},
 			'numbers' => {
 				'arab' => q{arabisko-indiske cyfry},
 				'arabext' => q{rozšyrjone arabisko-indiske cyfry},
 				'armn' => q{armeńske cyfry},
 				'armnlow' => q{armeńske cyfry małopisane},
 				'beng' => q{bengalske cyfry},
 				'cakm' => q{chakmaske cyfry},
 				'deva' => q{devanagari-cyfry},
 				'ethi' => q{etiopiske cyfry},
 				'fullwide' => q{połnošyroke cyfry},
 				'geor' => q{georgiske cyfry},
 				'grek' => q{grichiske cyfry},
 				'greklow' => q{grichiske cyfry małopisane},
 				'gujr' => q{gujarati-cyfry},
 				'guru' => q{gurmukhi-cyfry},
 				'hanidec' => q{chinske decimalne licby},
 				'hans' => q{zjadnorjone chinske cyfry},
 				'hansfin' => q{zjadnorjone chinske financne cyfry},
 				'hant' => q{tradicionalne chinske cyfry},
 				'hantfin' => q{tradicionalne chinske financne cyfry},
 				'hebr' => q{hebrejske cyfry},
 				'java' => q{javaske cyfry},
 				'jpan' => q{japańske cyfry},
 				'jpanfin' => q{japańske financne cyfry},
 				'khmr' => q{khmerske cyfry},
 				'knda' => q{kannada-cyfry},
 				'laoo' => q{laotiske cyfry},
 				'latn' => q{arabiske cyfry},
 				'mlym' => q{malayalamske cyfry},
 				'mtei' => q{meetei-mayekske cyfry},
 				'mymr' => q{burmaske cyfry},
 				'olck' => q{ol-chikiske cyfry},
 				'orya' => q{oriya-cyfry},
 				'roman' => q{romske cyfry},
 				'romanlow' => q{romske cyfry małopisane},
 				'taml' => q{tradicionalne tamilske cyfry},
 				'tamldec' => q{tamilske cyfry},
 				'telu' => q{telugu-cyfry},
 				'thai' => q{thaiske cyfry},
 				'tibt' => q{tibetske cyfry},
 				'vaii' => q{vaiske cyfry},
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
			'metric' => q{metriski},
 			'UK' => q{britiski},
 			'US' => q{ameriski},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Rěc: {0}',
 			'script' => 'Pismo: {0}',
 			'region' => 'Region: {0}',

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
			auxiliary => qr{[áàăâåäãąā æ ç ďđ éèĕêëėęē ğ íìĭîïİī ı ĺľ ňñ òŏôöőøō œ ř ş ß ť úùŭûůüűū ýÿ ż]},
			index => ['A', 'B', 'C', 'Č', 'Ć', 'D', 'E', 'F', 'G', 'H', '{Ch}', 'I', 'J', 'K', 'Ł', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Š', 'Ś', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž', 'Ź'],
			main => qr{[a b c č ć d e ě f g h {ch} i j k ł l m n ń oó p q r ŕ s š ś t u v w x y z ž ź]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’‚ "“„ « » ( ) \[ \] \{ \} § @ * / \& #]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'Č', 'Ć', 'D', 'E', 'F', 'G', 'H', '{Ch}', 'I', 'J', 'K', 'Ł', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'Š', 'Ś', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž', 'Ź'], };
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{„},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‚},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(njebjaski směr),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(njebjaski směr),
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
						'1' => q(exbi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(exbi{0}),
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
						'1' => q(yobi{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yobi{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(deci{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(deci{0}),
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
						'1' => q(centi{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(centi{0}),
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
						'1' => q(yokto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yokto{0}),
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
						'1' => q(mili{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(mili{0}),
					},
					# Long Unit Identifier
					'10p-30' => {
						'1' => q(quecto{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(quecto{0}),
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
						'1' => q(hekto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hekto{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(zeta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zeta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(yotta{0}),
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
						'1' => q(quetta{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(quetta{0}),
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
						'few' => q({0} jadnotki zemskego póspěšenja),
						'name' => q(jadnotki zemskego póspěšenja),
						'one' => q({0} jadnotka zemskego póspěšenja),
						'other' => q({0} jadnotkow zemskego póspěšenja),
						'two' => q({0} jadnotce zemskego póspěšenja),
					},
					# Core Unit Identifier
					'g-force' => {
						'few' => q({0} jadnotki zemskego póspěšenja),
						'name' => q(jadnotki zemskego póspěšenja),
						'one' => q({0} jadnotka zemskego póspěšenja),
						'other' => q({0} jadnotkow zemskego póspěšenja),
						'two' => q({0} jadnotce zemskego póspěšenja),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'few' => q({0} metry na kwadratnu sekundu),
						'name' => q(metry na kwadratnu sekundu),
						'one' => q({0} meter na kwadratnu sekundu),
						'other' => q({0} metrow kwadratnu sekundu),
						'two' => q({0} metra na kwadratnu sekundu),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'few' => q({0} metry na kwadratnu sekundu),
						'name' => q(metry na kwadratnu sekundu),
						'one' => q({0} meter na kwadratnu sekundu),
						'other' => q({0} metrow kwadratnu sekundu),
						'two' => q({0} metra na kwadratnu sekundu),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'few' => q({0} wobłukowe minuty),
						'name' => q(wobłukowe minuty),
						'one' => q({0} wobłukowa minuta),
						'other' => q({0} wobłukowych minutow),
						'two' => q({0} wobłukowej minuśe),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'few' => q({0} wobłukowe minuty),
						'name' => q(wobłukowe minuty),
						'one' => q({0} wobłukowa minuta),
						'other' => q({0} wobłukowych minutow),
						'two' => q({0} wobłukowej minuśe),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'few' => q({0} wobłukowe sekundy),
						'name' => q(wobłukowe sekundy),
						'one' => q({0} wobłukowa sekunda),
						'other' => q({0} wobłukowych sekundow),
						'two' => q({0} wobłukowej sekunźe),
					},
					# Core Unit Identifier
					'arc-second' => {
						'few' => q({0} wobłukowe sekundy),
						'name' => q(wobłukowe sekundy),
						'one' => q({0} wobłukowa sekunda),
						'other' => q({0} wobłukowych sekundow),
						'two' => q({0} wobłukowej sekunźe),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'few' => q({0} stopnje),
						'name' => q(wobłukowe stopnje),
						'one' => q({0} stopjeń),
						'other' => q({0} stopnjow),
						'two' => q({0} stopjenja),
					},
					# Core Unit Identifier
					'degree' => {
						'few' => q({0} stopnje),
						'name' => q(wobłukowe stopnje),
						'one' => q({0} stopjeń),
						'other' => q({0} stopnjow),
						'two' => q({0} stopjenja),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'few' => q({0} radianty),
						'name' => q(radianty),
						'one' => q({0} radiant),
						'other' => q({0} radiantow),
						'two' => q({0} radianta),
					},
					# Core Unit Identifier
					'radian' => {
						'few' => q({0} radianty),
						'name' => q(radianty),
						'one' => q({0} radiant),
						'other' => q({0} radiantow),
						'two' => q({0} radianta),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0} wobroty),
						'name' => q(wobroty),
						'one' => q({0} wobrot),
						'other' => q({0} wobrotow),
						'two' => q({0} wobrotaj),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0} wobroty),
						'name' => q(wobroty),
						'one' => q({0} wobrot),
						'other' => q({0} wobrotow),
						'two' => q({0} wobrotaj),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0} akry),
						'name' => q(akry),
						'one' => q({0} aker),
						'other' => q({0} akrow),
						'two' => q({0} akra),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0} akry),
						'name' => q(akry),
						'one' => q({0} aker),
						'other' => q({0} akrow),
						'two' => q({0} akra),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0} dunamy),
						'name' => q(dunamy),
						'one' => q({0} dunam),
						'other' => q({0} dunamow),
						'two' => q({0} dunama),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0} dunamy),
						'name' => q(dunamy),
						'one' => q({0} dunam),
						'other' => q({0} dunamow),
						'two' => q({0} dunama),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'few' => q({0} hektary),
						'name' => q(hektary),
						'one' => q({0} hektar),
						'other' => q({0} hektarow),
						'two' => q({0} hektara),
					},
					# Core Unit Identifier
					'hectare' => {
						'few' => q({0} hektary),
						'name' => q(hektary),
						'one' => q({0} hektar),
						'other' => q({0} hektarow),
						'two' => q({0} hektara),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'few' => q({0} kwadratne centimetry),
						'name' => q(kwadratne centimetry),
						'one' => q({0} kwadratny centimeter),
						'other' => q({0} kwadratnych centimetrow),
						'per' => q({0} na kwadratny centimeter),
						'two' => q({0} kwadratnej centimetra),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'few' => q({0} kwadratne centimetry),
						'name' => q(kwadratne centimetry),
						'one' => q({0} kwadratny centimeter),
						'other' => q({0} kwadratnych centimetrow),
						'per' => q({0} na kwadratny centimeter),
						'two' => q({0} kwadratnej centimetra),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0} kwadratne stopy),
						'name' => q(kwadratne stopy),
						'one' => q({0} kwadratna stopa),
						'other' => q({0} kwadratnych stopow),
						'two' => q({0} kwadratnej stopje),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0} kwadratne stopy),
						'name' => q(kwadratne stopy),
						'one' => q({0} kwadratna stopa),
						'other' => q({0} kwadratnych stopow),
						'two' => q({0} kwadratnej stopje),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0} kwadratne cole),
						'name' => q(kwadratne cole),
						'one' => q({0} kwadratny col),
						'other' => q({0} kwadratnych colow),
						'per' => q({0} na kwadratny col),
						'two' => q({0} kwadratnej cola),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0} kwadratne cole),
						'name' => q(kwadratne cole),
						'one' => q({0} kwadratny col),
						'other' => q({0} kwadratnych colow),
						'per' => q({0} na kwadratny col),
						'two' => q({0} kwadratnej cola),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'few' => q({0} kwadratne kilometry),
						'name' => q(kwadratne kilometry),
						'one' => q({0} kwadratny kilometer),
						'other' => q({0} kwadratnych kilometrow),
						'per' => q({0} na kwadratny kilometer),
						'two' => q({0} kwadratnej kilometra),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'few' => q({0} kwadratne kilometry),
						'name' => q(kwadratne kilometry),
						'one' => q({0} kwadratny kilometer),
						'other' => q({0} kwadratnych kilometrow),
						'per' => q({0} na kwadratny kilometer),
						'two' => q({0} kwadratnej kilometra),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'few' => q({0} kwadratne metry),
						'name' => q(kwadratne metry),
						'one' => q({0} kwadratny meter),
						'other' => q({0} kwadratnych metrow),
						'per' => q({0} na kwadratny meter),
						'two' => q({0} kwadratnej metra),
					},
					# Core Unit Identifier
					'square-meter' => {
						'few' => q({0} kwadratne metry),
						'name' => q(kwadratne metry),
						'one' => q({0} kwadratny meter),
						'other' => q({0} kwadratnych metrow),
						'per' => q({0} na kwadratny meter),
						'two' => q({0} kwadratnej metra),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0} kwadratne mile),
						'name' => q(kwadratne mile),
						'one' => q({0} kwadratna mila),
						'other' => q({0} kwadratnych milow),
						'per' => q({0} na kwadratnu milu),
						'two' => q({0} kwadratnej mili),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0} kwadratne mile),
						'name' => q(kwadratne mile),
						'one' => q({0} kwadratna mila),
						'other' => q({0} kwadratnych milow),
						'per' => q({0} na kwadratnu milu),
						'two' => q({0} kwadratnej mili),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0} kwadratne yardy),
						'name' => q(kwadratne yardy),
						'one' => q({0} kwadratny yard),
						'other' => q({0} kwadratnych yardow),
						'two' => q({0} kwadratnej yarda),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0} kwadratne yardy),
						'name' => q(kwadratne yardy),
						'one' => q({0} kwadratny yard),
						'other' => q({0} kwadratnych yardow),
						'two' => q({0} kwadratnej yarda),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'few' => q({0} kuski),
						'name' => q(kuski),
						'one' => q({0} kusk),
						'other' => q({0} kuskow),
						'two' => q({0} kuska),
					},
					# Core Unit Identifier
					'item' => {
						'few' => q({0} kuski),
						'name' => q(kuski),
						'one' => q({0} kusk),
						'other' => q({0} kuskow),
						'two' => q({0} kuska),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'few' => q({0} karaty),
						'name' => q(karaty),
						'one' => q({0} karat),
						'other' => q({0} karatow),
						'two' => q({0} karata),
					},
					# Core Unit Identifier
					'karat' => {
						'few' => q({0} karaty),
						'name' => q(karaty),
						'one' => q({0} karat),
						'other' => q({0} karatow),
						'two' => q({0} karata),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} miligramy na deciliter),
						'name' => q(miligramy na deciliter),
						'one' => q({0} miligram na deciliter),
						'other' => q({0} miligramow na deciliter),
						'two' => q({0} miligrama na deciliter),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} miligramy na deciliter),
						'name' => q(miligramy na deciliter),
						'one' => q({0} miligram na deciliter),
						'other' => q({0} miligramow na deciliter),
						'two' => q({0} miligrama na deciliter),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'few' => q({0} milimole na liter),
						'name' => q(milimole na liter),
						'one' => q({0} milimol na liter),
						'other' => q({0} milimolow na liter),
						'two' => q({0} milimola na liter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'few' => q({0} milimole na liter),
						'name' => q(milimole na liter),
						'one' => q({0} milimol na liter),
						'other' => q({0} milimolow na liter),
						'two' => q({0} milimola na liter),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'few' => q({0} mole),
						'name' => q(mole),
						'one' => q({0} mol),
						'other' => q({0} molow),
						'two' => q({0} mola),
					},
					# Core Unit Identifier
					'mole' => {
						'few' => q({0} mole),
						'name' => q(mole),
						'one' => q({0} mol),
						'other' => q({0} molow),
						'two' => q({0} mola),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'few' => q({0} procenty),
						'name' => q(procenty),
						'one' => q({0} procent),
						'other' => q({0} procentow),
						'two' => q({0} procenta),
					},
					# Core Unit Identifier
					'percent' => {
						'few' => q({0} procenty),
						'name' => q(procenty),
						'one' => q({0} procent),
						'other' => q({0} procentow),
						'two' => q({0} procenta),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'few' => q({0} promile),
						'name' => q(promile),
						'one' => q({0} promil),
						'other' => q({0} promilow),
						'two' => q({0} promila),
					},
					# Core Unit Identifier
					'permille' => {
						'few' => q({0} promile),
						'name' => q(promile),
						'one' => q({0} promil),
						'other' => q({0} promilow),
						'two' => q({0} promila),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'few' => q({0} milionśiny),
						'name' => q(milionśiny),
						'one' => q({0} milionśina),
						'other' => q({0} milionśinow),
						'two' => q({0} milionśinje),
					},
					# Core Unit Identifier
					'permillion' => {
						'few' => q({0} milionśiny),
						'name' => q(milionśiny),
						'one' => q({0} milionśina),
						'other' => q({0} milionśinow),
						'two' => q({0} milionśinje),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'few' => q({0} źaseśiny promila),
						'name' => q(źaseśiny promila),
						'one' => q({0} źaseśina promila),
						'other' => q({0} źaseśinow promila),
						'two' => q({0} źaseśinje promila),
					},
					# Core Unit Identifier
					'permyriad' => {
						'few' => q({0} źaseśiny promila),
						'name' => q(źaseśiny promila),
						'one' => q({0} źaseśina promila),
						'other' => q({0} źaseśinow promila),
						'two' => q({0} źaseśinje promila),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'few' => q({0} miliardniny),
						'name' => q(miliardnina),
						'one' => q({0} miliardnina),
						'other' => q({0} miliardninow),
						'two' => q({0} miliardninje),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'few' => q({0} miliardniny),
						'name' => q(miliardnina),
						'one' => q({0} miliardnina),
						'other' => q({0} miliardninow),
						'two' => q({0} miliardninje),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} litry na 100 kilometrow),
						'name' => q(litry na 100 kilometrow),
						'one' => q({0} liter na 100 kilometrow),
						'other' => q({0} litrow na 100 kilometrow),
						'two' => q({0} litra na 100 kilometrow),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} litry na 100 kilometrow),
						'name' => q(litry na 100 kilometrow),
						'one' => q({0} liter na 100 kilometrow),
						'other' => q({0} litrow na 100 kilometrow),
						'two' => q({0} litra na 100 kilometrow),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} litry na kilometer),
						'name' => q(litry na kilometer),
						'one' => q({0} liter na kilometer),
						'other' => q({0} litrow na kilometer),
						'two' => q({0} litra na kilometer),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} litry na kilometer),
						'name' => q(litry na kilometer),
						'one' => q({0} liter na kilometer),
						'other' => q({0} litrow na kilometer),
						'two' => q({0} litra na kilometer),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} mile na gallonu),
						'name' => q(mile na gallonu),
						'one' => q({0} mila na gallonu),
						'other' => q({0} milow na gallonu),
						'two' => q({0} mili na gallonu),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} mile na gallonu),
						'name' => q(mile na gallonu),
						'one' => q({0} mila na gallonu),
						'other' => q({0} milow na gallonu),
						'two' => q({0} mili na gallonu),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} mile na britisku galonu),
						'name' => q(mile na britisku galonu),
						'one' => q({0} mila na britisku galonu),
						'other' => q({0} milow na britisku galonu),
						'two' => q({0} mili na britisku galonu),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} mile na britisku galonu),
						'name' => q(mile na britisku galonu),
						'one' => q({0} mila na britisku galonu),
						'other' => q({0} milow na britisku galonu),
						'two' => q({0} mili na britisku galonu),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} pódzajtšo),
						'north' => q({0} połnoc),
						'south' => q({0} połudnjo),
						'west' => q({0} pódwjacor),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} pódzajtšo),
						'north' => q({0} połnoc),
						'south' => q({0} połudnjo),
						'west' => q({0} pódwjacor),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'few' => q({0} bity),
						'one' => q({0} bit),
						'other' => q({0} bitow),
						'two' => q({0} bita),
					},
					# Core Unit Identifier
					'bit' => {
						'few' => q({0} bity),
						'one' => q({0} bit),
						'other' => q({0} bitow),
						'two' => q({0} bita),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0} bytey),
						'one' => q({0} byte),
						'other' => q({0} byteow),
						'two' => q({0} bytea),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} bytey),
						'one' => q({0} byte),
						'other' => q({0} byteow),
						'two' => q({0} bytea),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'few' => q({0} gigabity),
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabitow),
						'two' => q({0} gigabita),
					},
					# Core Unit Identifier
					'gigabit' => {
						'few' => q({0} gigabity),
						'name' => q(gigabit),
						'one' => q({0} gigabit),
						'other' => q({0} gigabitow),
						'two' => q({0} gigabita),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'few' => q({0} gigabytey),
						'name' => q(gigabyte),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyteow),
						'two' => q({0} gigabytea),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'few' => q({0} gigabytey),
						'name' => q(gigabyte),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyteow),
						'two' => q({0} gigabytea),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'few' => q({0} kilobity),
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobitow),
						'two' => q({0} kilobita),
					},
					# Core Unit Identifier
					'kilobit' => {
						'few' => q({0} kilobity),
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobitow),
						'two' => q({0} kilobita),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'few' => q({0} kilobytey),
						'name' => q(kilobyte),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyteow),
						'two' => q({0} kilobytea),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'few' => q({0} kilobytey),
						'name' => q(kilobyte),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyteow),
						'two' => q({0} kilobytea),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'few' => q({0} megabity),
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabitow),
						'two' => q({0} megabita),
					},
					# Core Unit Identifier
					'megabit' => {
						'few' => q({0} megabity),
						'name' => q(megabit),
						'one' => q({0} megabit),
						'other' => q({0} megabitow),
						'two' => q({0} megabita),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'few' => q({0} megabytey),
						'name' => q(megabyte),
						'one' => q({0} megabyte),
						'other' => q({0} megabyteow),
						'two' => q({0} megabytea),
					},
					# Core Unit Identifier
					'megabyte' => {
						'few' => q({0} megabytey),
						'name' => q(megabyte),
						'one' => q({0} megabyte),
						'other' => q({0} megabyteow),
						'two' => q({0} megabytea),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'few' => q({0} petabytey),
						'name' => q(petabytey),
						'one' => q({0} petabyte),
						'other' => q({0} petabyteow),
						'two' => q({0} petabytea),
					},
					# Core Unit Identifier
					'petabyte' => {
						'few' => q({0} petabytey),
						'name' => q(petabytey),
						'one' => q({0} petabyte),
						'other' => q({0} petabyteow),
						'two' => q({0} petabytea),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'few' => q({0} terabity),
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabitow),
						'two' => q({0} terabita),
					},
					# Core Unit Identifier
					'terabit' => {
						'few' => q({0} terabity),
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabitow),
						'two' => q({0} terabita),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'few' => q({0} terabytey),
						'name' => q(terabyte),
						'one' => q({0} terabyte),
						'other' => q({0} terabyteow),
						'two' => q({0} terabytea),
					},
					# Core Unit Identifier
					'terabyte' => {
						'few' => q({0} terabytey),
						'name' => q(terabyte),
						'one' => q({0} terabyte),
						'other' => q({0} terabyteow),
						'two' => q({0} terabytea),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} lětstotki),
						'name' => q(lětstotki),
						'one' => q({0} lětstotk),
						'other' => q({0} lětstotkow),
						'two' => q({0} lětstotka),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} lětstotki),
						'name' => q(lětstotki),
						'one' => q({0} lětstotk),
						'other' => q({0} lětstotkow),
						'two' => q({0} lětstotka),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} dny),
						'one' => q({0} źeń),
						'other' => q({0} dnjow),
						'per' => q({0} wob źeń),
						'two' => q({0} dnja),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} dny),
						'one' => q({0} źeń),
						'other' => q({0} dnjow),
						'per' => q({0} wob źeń),
						'two' => q({0} dnja),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0} lětźasetki),
						'name' => q(lětźasetki),
						'one' => q({0} lětźasetk),
						'other' => q({0} lětźasetkow),
						'two' => q({0} lětźasetka),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0} lětźasetki),
						'name' => q(lětźasetki),
						'one' => q({0} lětźasetk),
						'other' => q({0} lětźasetkow),
						'two' => q({0} lětźasetka),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'few' => q({0} góźiny),
						'name' => q(góźiny),
						'one' => q({0} góźina),
						'other' => q({0} góźinow),
						'per' => q({0} na góźinu),
						'two' => q({0} góźinje),
					},
					# Core Unit Identifier
					'hour' => {
						'few' => q({0} góźiny),
						'name' => q(góźiny),
						'one' => q({0} góźina),
						'other' => q({0} góźinow),
						'per' => q({0} na góźinu),
						'two' => q({0} góźinje),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'few' => q({0} mikrosekundy),
						'name' => q(mikrosekundy),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekundow),
						'two' => q({0} mikrosekunźe),
					},
					# Core Unit Identifier
					'microsecond' => {
						'few' => q({0} mikrosekundy),
						'name' => q(mikrosekundy),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekundow),
						'two' => q({0} mikrosekunźe),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'few' => q({0} milisekundy),
						'name' => q(milisekundy),
						'one' => q({0} milisekunda),
						'other' => q({0} milisekundow),
						'two' => q({0} milisekunźe),
					},
					# Core Unit Identifier
					'millisecond' => {
						'few' => q({0} milisekundy),
						'name' => q(milisekundy),
						'one' => q({0} milisekunda),
						'other' => q({0} milisekundow),
						'two' => q({0} milisekunźe),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} minuty),
						'name' => q(minuty),
						'one' => q({0} minuta),
						'other' => q({0} minutow),
						'per' => q({0} za minutu),
						'two' => q({0} minuśe),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} minuty),
						'name' => q(minuty),
						'one' => q({0} minuta),
						'other' => q({0} minutow),
						'per' => q({0} za minutu),
						'two' => q({0} minuśe),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} mjasecy),
						'name' => q(mjasecy),
						'one' => q({0} mjasec),
						'other' => q({0} mjasecow),
						'per' => q({0} wob mjasec),
						'two' => q({0} mjaseca),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} mjasecy),
						'name' => q(mjasecy),
						'one' => q({0} mjasec),
						'other' => q({0} mjasecow),
						'per' => q({0} wob mjasec),
						'two' => q({0} mjaseca),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'few' => q({0} nanosekundy),
						'name' => q(nanosekundy),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekundow),
						'two' => q({0} nanosekunźe),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'few' => q({0} nanosekundy),
						'name' => q(nanosekundy),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekundow),
						'two' => q({0} nanosekunźe),
					},
					# Long Unit Identifier
					'duration-night' => {
						'few' => q({0} pśenocowanja),
						'name' => q(pśenocowanja),
						'one' => q({0} pśenocowanje),
						'other' => q({0} pśenocowanjow),
						'per' => q({0} na pśenocowanje),
						'two' => q({0} pśenocowani),
					},
					# Core Unit Identifier
					'night' => {
						'few' => q({0} pśenocowanja),
						'name' => q(pśenocowanja),
						'one' => q({0} pśenocowanje),
						'other' => q({0} pśenocowanjow),
						'per' => q({0} na pśenocowanje),
						'two' => q({0} pśenocowani),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} kwartale),
						'name' => q(kwartale),
						'one' => q({0} kwartal),
						'other' => q({0} kwartalow),
						'per' => q({0}/kwartal),
						'two' => q({0} kwartala),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} kwartale),
						'name' => q(kwartale),
						'one' => q({0} kwartal),
						'other' => q({0} kwartalow),
						'per' => q({0}/kwartal),
						'two' => q({0} kwartala),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} sekundy),
						'name' => q(sekundy),
						'one' => q({0} sekunda),
						'other' => q({0} sekundow),
						'per' => q({0} na sekundu),
						'two' => q({0} sekunźe),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} sekundy),
						'name' => q(sekundy),
						'one' => q({0} sekunda),
						'other' => q({0} sekundow),
						'per' => q({0} na sekundu),
						'two' => q({0} sekunźe),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} tyźenje),
						'name' => q(tyźenje),
						'one' => q({0} tyźeń),
						'other' => q({0} tyźenjow),
						'per' => q({0} wob tyźeń),
						'two' => q({0} tyźenja),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} tyźenje),
						'name' => q(tyźenje),
						'one' => q({0} tyźeń),
						'other' => q({0} tyźenjow),
						'per' => q({0} wob tyźeń),
						'two' => q({0} tyźenja),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} lěta),
						'name' => q(lěta),
						'one' => q({0} lěto),
						'other' => q({0} lět),
						'per' => q({0} wob lěto),
						'two' => q({0} lěśe),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} lěta),
						'name' => q(lěta),
						'one' => q({0} lěto),
						'other' => q({0} lět),
						'per' => q({0} wob lěto),
						'two' => q({0} lěśe),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'few' => q({0} ampery),
						'name' => q(ampery),
						'one' => q({0} ampere),
						'other' => q({0} amperow),
						'two' => q({0} ampera),
					},
					# Core Unit Identifier
					'ampere' => {
						'few' => q({0} ampery),
						'name' => q(ampery),
						'one' => q({0} ampere),
						'other' => q({0} amperow),
						'two' => q({0} ampera),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'few' => q({0} milliampery),
						'name' => q(milliampery),
						'one' => q({0} milliampere),
						'other' => q({0} milliamperow),
						'two' => q({0} milliampera),
					},
					# Core Unit Identifier
					'milliampere' => {
						'few' => q({0} milliampery),
						'name' => q(milliampery),
						'one' => q({0} milliampere),
						'other' => q({0} milliamperow),
						'two' => q({0} milliampera),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'few' => q({0} ohmy),
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohmow),
						'two' => q({0} ohma),
					},
					# Core Unit Identifier
					'ohm' => {
						'few' => q({0} ohmy),
						'name' => q(ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohmow),
						'two' => q({0} ohma),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'few' => q({0} volty),
						'name' => q(volty),
						'one' => q({0} volt),
						'other' => q({0} voltow),
						'two' => q({0} volta),
					},
					# Core Unit Identifier
					'volt' => {
						'few' => q({0} volty),
						'name' => q(volty),
						'one' => q({0} volt),
						'other' => q({0} voltow),
						'two' => q({0} volta),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'few' => q({0} britiske jadnotki śopłoty),
						'name' => q(britiske jadnotki śopłoty),
						'one' => q({0} britiska jadnotka śopłoty),
						'other' => q({0} britiskich jadnotkow śopłoty),
						'two' => q({0} britiskej jadnotce śopłoty),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'few' => q({0} britiske jadnotki śopłoty),
						'name' => q(britiske jadnotki śopłoty),
						'one' => q({0} britiska jadnotka śopłoty),
						'other' => q({0} britiskich jadnotkow śopłoty),
						'two' => q({0} britiskej jadnotce śopłoty),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'few' => q({0} kalorije),
						'name' => q(kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorijow),
						'two' => q({0} kaloriji),
					},
					# Core Unit Identifier
					'calorie' => {
						'few' => q({0} kalorije),
						'name' => q(kalorije),
						'one' => q({0} kalorija),
						'other' => q({0} kalorijow),
						'two' => q({0} kaloriji),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'few' => q({0} elektronvolty),
						'name' => q(elektronvolty),
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvoltow),
						'two' => q({0} elektronvolta),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'few' => q({0} elektronvolty),
						'name' => q(elektronvolty),
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvoltow),
						'two' => q({0} elektronvolta),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} kilokalorije),
						'name' => q(kilokalorije),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorijow),
						'two' => q({0} kilokaloriji),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} kilokalorije),
						'name' => q(kilokalorije),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorijow),
						'two' => q({0} kilokaloriji),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'few' => q({0} joule),
						'name' => q(joule),
						'one' => q({0} joule),
						'other' => q({0} joule),
						'two' => q({0} joule),
					},
					# Core Unit Identifier
					'joule' => {
						'few' => q({0} joule),
						'name' => q(joule),
						'one' => q({0} joule),
						'other' => q({0} joule),
						'two' => q({0} joule),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'few' => q({0} kilokalorije),
						'name' => q(kilokalorije),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorijow),
						'two' => q({0} kilokaloriji),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'few' => q({0} kilokalorije),
						'name' => q(kilokalorije),
						'one' => q({0} kilokalorija),
						'other' => q({0} kilokalorijow),
						'two' => q({0} kilokaloriji),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'few' => q({0} kilojoule),
						'name' => q(kilojoule),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoule),
						'two' => q({0} kilojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'few' => q({0} kilojoule),
						'name' => q(kilojoule),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoule),
						'two' => q({0} kilojoule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'few' => q({0} kilowattowe góźiny),
						'name' => q(kilowattowe góźiny),
						'one' => q({0} kilowattowa góźina),
						'other' => q({0} kilowattowych góźin),
						'two' => q({0} kilowattowej góźinje),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'few' => q({0} kilowattowe góźiny),
						'name' => q(kilowattowe góźiny),
						'one' => q({0} kilowattowa góźina),
						'other' => q({0} kilowattowych góźin),
						'two' => q({0} kilowattowej góźinje),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'few' => q({0} amerikańske jadnotki śopłoty),
						'name' => q(amerikańske jadnotki śopłoty),
						'one' => q({0} amerikańska jadnotka śopłoty),
						'other' => q({0} amerikańskich jadnotkow śopłoty),
						'two' => q({0} amerikańskej jadnotce śopłoty),
					},
					# Core Unit Identifier
					'therm-us' => {
						'few' => q({0} amerikańske jadnotki śopłoty),
						'name' => q(amerikańske jadnotki śopłoty),
						'one' => q({0} amerikańska jadnotka śopłoty),
						'other' => q({0} amerikańskich jadnotkow śopłoty),
						'two' => q({0} amerikańskej jadnotce śopłoty),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} kilowattowe góźiny na 100 kilometrow),
						'name' => q(kilowattowe góźiny na 100 kilometrow),
						'one' => q({0} kilowattowa góźina na 100 kilometrow),
						'other' => q({0} kilowattowych góźinow na 100 kilometrow),
						'two' => q({0} kilowattowej góźinje na 100 kilometrow),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} kilowattowe góźiny na 100 kilometrow),
						'name' => q(kilowattowe góźiny na 100 kilometrow),
						'one' => q({0} kilowattowa góźina na 100 kilometrow),
						'other' => q({0} kilowattowych góźinow na 100 kilometrow),
						'two' => q({0} kilowattowej góźinje na 100 kilometrow),
					},
					# Long Unit Identifier
					'force-newton' => {
						'few' => q({0} newtony),
						'name' => q(newtony),
						'one' => q({0} newton),
						'other' => q({0} newtonow),
						'two' => q({0} newtona),
					},
					# Core Unit Identifier
					'newton' => {
						'few' => q({0} newtony),
						'name' => q(newtony),
						'one' => q({0} newton),
						'other' => q({0} newtonow),
						'two' => q({0} newtona),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'few' => q({0} punty mócy),
						'name' => q(punty mócy),
						'one' => q({0} punt mócy),
						'other' => q({0} puntow mócy),
						'two' => q({0} punta mócy),
					},
					# Core Unit Identifier
					'pound-force' => {
						'few' => q({0} punty mócy),
						'name' => q(punty mócy),
						'one' => q({0} punt mócy),
						'other' => q({0} puntow mócy),
						'two' => q({0} punta mócy),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'few' => q({0} gigahertzy),
						'name' => q(gigahertzy),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertzow),
						'two' => q({0} gigahertza),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'few' => q({0} gigahertzy),
						'name' => q(gigahertzy),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertzow),
						'two' => q({0} gigahertza),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'few' => q({0} hertzy),
						'name' => q(hertzy),
						'one' => q({0} hertz),
						'other' => q({0} hertzow),
						'two' => q({0} hertza),
					},
					# Core Unit Identifier
					'hertz' => {
						'few' => q({0} hertzy),
						'name' => q(hertzy),
						'one' => q({0} hertz),
						'other' => q({0} hertzow),
						'two' => q({0} hertza),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'few' => q({0} kilohertzy),
						'name' => q(kilohertzy),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertzow),
						'two' => q({0} kilohertza),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'few' => q({0} kilohertzy),
						'name' => q(kilohertzy),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertzow),
						'two' => q({0} kilohertza),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'few' => q({0} megahertzy),
						'name' => q(megahertzy),
						'one' => q({0} megahertz),
						'other' => q({0} megahertzow),
						'two' => q({0} megahertza),
					},
					# Core Unit Identifier
					'megahertz' => {
						'few' => q({0} megahertzy),
						'name' => q(megahertzy),
						'one' => q({0} megahertz),
						'other' => q({0} megahertzow),
						'two' => q({0} megahertza),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'few' => q({0} typografiske em),
						'name' => q(typografiski em),
						'one' => q({0} typografiski em),
						'other' => q({0} typografiskich em),
						'two' => q({0} typografiskej em),
					},
					# Core Unit Identifier
					'em' => {
						'few' => q({0} typografiske em),
						'name' => q(typografiski em),
						'one' => q({0} typografiski em),
						'other' => q({0} typografiskich em),
						'two' => q({0} typografiskej em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'few' => q({0} megapiksele),
						'name' => q(megapiksele),
						'one' => q({0} megapiksel),
						'other' => q({0} megapikselow),
						'two' => q({0} megapiksela),
					},
					# Core Unit Identifier
					'megapixel' => {
						'few' => q({0} megapiksele),
						'name' => q(megapiksele),
						'one' => q({0} megapiksel),
						'other' => q({0} megapikselow),
						'two' => q({0} megapiksela),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'few' => q({0} piksele),
						'name' => q(piksele),
						'one' => q({0} piksel),
						'other' => q({0} pikselow),
						'two' => q({0} piksela),
					},
					# Core Unit Identifier
					'pixel' => {
						'few' => q({0} piksele),
						'name' => q(piksele),
						'one' => q({0} piksel),
						'other' => q({0} pikselow),
						'two' => q({0} piksela),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'few' => q({0} piksele na centimeter),
						'name' => q(piksele na centimeter),
						'one' => q({0} piksel na centimeter),
						'other' => q({0} pikselow na centimeter),
						'two' => q({0} piksela na centimeter),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'few' => q({0} piksele na centimeter),
						'name' => q(piksele na centimeter),
						'one' => q({0} piksel na centimeter),
						'other' => q({0} pikselow na centimeter),
						'two' => q({0} piksela na centimeter),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'few' => q({0} piksele na col),
						'name' => q(piksele na col),
						'one' => q({0} piksel na col),
						'other' => q({0} pikselow na col),
						'two' => q({0} piksela na col),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'few' => q({0} piksele na col),
						'name' => q(piksele na col),
						'one' => q({0} piksel na col),
						'other' => q({0} pikselow na col),
						'two' => q({0} piksela na col),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} astronomiske jadnotki),
						'name' => q(astronomiske jadnotki),
						'one' => q({0} astronomiska jadnotka),
						'other' => q({0} astronomiskich jadnotkow),
						'two' => q({0} astronomiskej jadnotce),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} astronomiske jadnotki),
						'name' => q(astronomiske jadnotki),
						'one' => q({0} astronomiska jadnotka),
						'other' => q({0} astronomiskich jadnotkow),
						'two' => q({0} astronomiskej jadnotce),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'few' => q({0} centimetry),
						'name' => q(centimetry),
						'one' => q({0} centimeter),
						'other' => q({0} centimetrow),
						'per' => q({0} na centimeter),
						'two' => q({0} centimetra),
					},
					# Core Unit Identifier
					'centimeter' => {
						'few' => q({0} centimetry),
						'name' => q(centimetry),
						'one' => q({0} centimeter),
						'other' => q({0} centimetrow),
						'per' => q({0} na centimeter),
						'two' => q({0} centimetra),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'few' => q({0} decimetry),
						'name' => q(decimetry),
						'one' => q({0} decimeter),
						'other' => q({0} decimetrow),
						'two' => q({0} decimetra),
					},
					# Core Unit Identifier
					'decimeter' => {
						'few' => q({0} decimetry),
						'name' => q(decimetry),
						'one' => q({0} decimeter),
						'other' => q({0} decimetrow),
						'two' => q({0} decimetra),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'few' => q({0} radiuse zemje),
						'name' => q(radius zemje),
						'one' => q({0} radius zemje),
						'other' => q({0} radiusow zemje),
						'two' => q({0} radiusa zemje),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'few' => q({0} radiuse zemje),
						'name' => q(radius zemje),
						'one' => q({0} radius zemje),
						'other' => q({0} radiusow zemje),
						'two' => q({0} radiusa zemje),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'few' => q({0} sahi),
						'name' => q(sahi),
						'one' => q({0} saha),
						'other' => q({0} sahow),
						'two' => q({0} saze),
					},
					# Core Unit Identifier
					'fathom' => {
						'few' => q({0} sahi),
						'name' => q(sahi),
						'one' => q({0} saha),
						'other' => q({0} sahow),
						'two' => q({0} saze),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0} crjeje),
						'name' => q(stopy),
						'one' => q({0} crjej),
						'other' => q({0} crjej),
						'per' => q({0} na stopu),
						'two' => q({0} crjeja),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0} crjeje),
						'name' => q(stopy),
						'one' => q({0} crjej),
						'other' => q({0} crjej),
						'per' => q({0} na stopu),
						'two' => q({0} crjeja),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'few' => q({0} furlongi),
						'name' => q(furlongi),
						'one' => q({0} furlong),
						'other' => q({0} furlongow),
						'two' => q({0} furlonga),
					},
					# Core Unit Identifier
					'furlong' => {
						'few' => q({0} furlongi),
						'name' => q(furlongi),
						'one' => q({0} furlong),
						'other' => q({0} furlongow),
						'two' => q({0} furlonga),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0} cole),
						'name' => q(cole),
						'one' => q({0} col),
						'other' => q({0} colow),
						'per' => q({0} na col),
						'two' => q({0} cola),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0} cole),
						'name' => q(cole),
						'one' => q({0} col),
						'other' => q({0} colow),
						'per' => q({0} na col),
						'two' => q({0} cola),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'few' => q({0} kilometry),
						'name' => q(kilometry),
						'one' => q({0} kilometer),
						'other' => q({0} kilometrow),
						'per' => q({0} na kilometer),
						'two' => q({0} kilometra),
					},
					# Core Unit Identifier
					'kilometer' => {
						'few' => q({0} kilometry),
						'name' => q(kilometry),
						'one' => q({0} kilometer),
						'other' => q({0} kilometrow),
						'per' => q({0} na kilometer),
						'two' => q({0} kilometra),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} swětłowe lěta),
						'name' => q(swětłowe lěta),
						'one' => q({0} swětłowe lěto),
						'other' => q({0} swětłowych lět),
						'two' => q({0} swětłowej lěśe),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} swětłowe lěta),
						'name' => q(swětłowe lěta),
						'one' => q({0} swětłowe lěto),
						'other' => q({0} swětłowych lět),
						'two' => q({0} swětłowej lěśe),
					},
					# Long Unit Identifier
					'length-meter' => {
						'few' => q({0} metry),
						'name' => q(metry),
						'one' => q({0} meter),
						'other' => q({0} metrow),
						'per' => q({0} na meter),
						'two' => q({0} metra),
					},
					# Core Unit Identifier
					'meter' => {
						'few' => q({0} metry),
						'name' => q(metry),
						'one' => q({0} meter),
						'other' => q({0} metrow),
						'per' => q({0} na meter),
						'two' => q({0} metra),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'few' => q({0} mikrometry),
						'name' => q(mikrometry),
						'one' => q({0} mikrometer),
						'other' => q({0} mikrometrow),
						'two' => q({0} mikrometra),
					},
					# Core Unit Identifier
					'micrometer' => {
						'few' => q({0} mikrometry),
						'name' => q(mikrometry),
						'one' => q({0} mikrometer),
						'other' => q({0} mikrometrow),
						'two' => q({0} mikrometra),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} mile),
						'name' => q(mile),
						'one' => q({0} mila),
						'other' => q({0} milow),
						'two' => q({0} mili),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} mile),
						'name' => q(mile),
						'one' => q({0} mila),
						'other' => q({0} milow),
						'two' => q({0} mili),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'few' => q({0} skandinawiske mile),
						'name' => q(skandinawiske mile),
						'one' => q({0} skandinawiska mila),
						'other' => q({0} skandinawiskich milow),
						'two' => q({0} skandinawiskej mili),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'few' => q({0} skandinawiske mile),
						'name' => q(skandinawiske mile),
						'one' => q({0} skandinawiska mila),
						'other' => q({0} skandinawiskich milow),
						'two' => q({0} skandinawiskej mili),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'few' => q({0} milimetry),
						'name' => q(milimetry),
						'one' => q({0} milimeter),
						'other' => q({0} milimetrow),
						'two' => q({0} milimetra),
					},
					# Core Unit Identifier
					'millimeter' => {
						'few' => q({0} milimetry),
						'name' => q(milimetry),
						'one' => q({0} milimeter),
						'other' => q({0} milimetrow),
						'two' => q({0} milimetra),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'few' => q({0} nanometry),
						'name' => q(nanometry),
						'one' => q({0} nanometer),
						'other' => q({0} nanometrow),
						'two' => q({0} nanometra),
					},
					# Core Unit Identifier
					'nanometer' => {
						'few' => q({0} nanometry),
						'name' => q(nanometry),
						'one' => q({0} nanometer),
						'other' => q({0} nanometrow),
						'two' => q({0} nanometra),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0} nawtiske mile),
						'name' => q(nawtiske mile),
						'one' => q({0} nawtiska mila),
						'other' => q({0} nawtiskich milow),
						'two' => q({0} nawtiskej mili),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} nawtiske mile),
						'name' => q(nawtiske mile),
						'one' => q({0} nawtiska mila),
						'other' => q({0} nawtiskich milow),
						'two' => q({0} nawtiskej mili),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'few' => q({0} parsec),
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
						'two' => q({0} parsec),
					},
					# Core Unit Identifier
					'parsec' => {
						'few' => q({0} parsec),
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
						'two' => q({0} parsec),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'few' => q({0} pikometry),
						'name' => q(pikometry),
						'one' => q({0} pikometer),
						'other' => q({0} pikometrow),
						'two' => q({0} pikometra),
					},
					# Core Unit Identifier
					'picometer' => {
						'few' => q({0} pikometry),
						'name' => q(pikometry),
						'one' => q({0} pikometer),
						'other' => q({0} pikometrow),
						'two' => q({0} pikometra),
					},
					# Long Unit Identifier
					'length-point' => {
						'few' => q({0} dypki),
						'name' => q(dypki),
						'one' => q({0} dypk),
						'other' => q({0} dypkow),
						'two' => q({0} dypka),
					},
					# Core Unit Identifier
					'point' => {
						'few' => q({0} dypki),
						'name' => q(dypki),
						'one' => q({0} dypk),
						'other' => q({0} dypkow),
						'two' => q({0} dypka),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'few' => q({0} radiuse słyńca),
						'name' => q(radiuse słyńca),
						'one' => q({0} radius słyńca),
						'other' => q({0} radiusow słyńca),
						'two' => q({0} radiusa słyńca),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'few' => q({0} radiuse słyńca),
						'name' => q(radiuse słyńca),
						'one' => q({0} radius słyńca),
						'other' => q({0} radiusow słyńca),
						'two' => q({0} radiusa słyńca),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} yardy),
						'name' => q(yardy),
						'one' => q({0} yard),
						'other' => q({0} yardow),
						'two' => q({0} yarda),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} yardy),
						'name' => q(yardy),
						'one' => q({0} yard),
						'other' => q({0} yardow),
						'two' => q({0} yarda),
					},
					# Long Unit Identifier
					'light-candela' => {
						'few' => q({0} kandele),
						'name' => q(kandele),
						'one' => q({0} kandela),
						'other' => q({0} kandelow),
						'two' => q({0} kandeli),
					},
					# Core Unit Identifier
					'candela' => {
						'few' => q({0} kandele),
						'name' => q(kandele),
						'one' => q({0} kandela),
						'other' => q({0} kandelow),
						'two' => q({0} kandeli),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'few' => q({0} lumeny),
						'name' => q(lumeny),
						'one' => q({0} lumen),
						'other' => q({0} lumenow),
						'two' => q({0} lumena),
					},
					# Core Unit Identifier
					'lumen' => {
						'few' => q({0} lumeny),
						'name' => q(lumeny),
						'one' => q({0} lumen),
						'other' => q({0} lumenow),
						'two' => q({0} lumena),
					},
					# Long Unit Identifier
					'light-lux' => {
						'few' => q({0} lux),
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
						'two' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'few' => q({0} lux),
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
						'two' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'few' => q({0} swěśeńske mócy słyńca),
						'name' => q(swěśeńske mócy słyńca),
						'one' => q({0} swěśeńska móc słyńca),
						'other' => q({0} swěśeńskich mócow słyńca),
						'two' => q({0} swěśeńskej mócy słyńca),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'few' => q({0} swěśeńske mócy słyńca),
						'name' => q(swěśeńske mócy słyńca),
						'one' => q({0} swěśeńska móc słyńca),
						'other' => q({0} swěśeńskich mócow słyńca),
						'two' => q({0} swěśeńskej mócy słyńca),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'few' => q({0} karaty),
						'name' => q(karaty),
						'one' => q({0} karat),
						'other' => q({0} karatow),
						'two' => q({0} karata),
					},
					# Core Unit Identifier
					'carat' => {
						'few' => q({0} karaty),
						'name' => q(karaty),
						'one' => q({0} karat),
						'other' => q({0} karatow),
						'two' => q({0} karata),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'few' => q({0} daltony),
						'name' => q(daltony),
						'one' => q({0} dalton),
						'other' => q({0} daltonow),
						'two' => q({0} daltona),
					},
					# Core Unit Identifier
					'dalton' => {
						'few' => q({0} daltony),
						'name' => q(daltony),
						'one' => q({0} dalton),
						'other' => q({0} daltonow),
						'two' => q({0} daltona),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'few' => q({0} kopice zemje),
						'name' => q(kopice zemje),
						'one' => q({0} kopica zemje),
						'other' => q({0} kopicow zemje),
						'two' => q({0} kopice zemje),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'few' => q({0} kopice zemje),
						'name' => q(kopice zemje),
						'one' => q({0} kopica zemje),
						'other' => q({0} kopicow zemje),
						'two' => q({0} kopice zemje),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'few' => q({0} gramy),
						'name' => q(gramy),
						'one' => q({0} gram),
						'other' => q({0} gramow),
						'per' => q({0} na gram),
						'two' => q({0} grama),
					},
					# Core Unit Identifier
					'gram' => {
						'few' => q({0} gramy),
						'name' => q(gramy),
						'one' => q({0} gram),
						'other' => q({0} gramow),
						'per' => q({0} na gram),
						'two' => q({0} grama),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'few' => q({0} kilogramy),
						'name' => q(kilogramy),
						'one' => q({0} kilogram),
						'other' => q({0} kilogramow),
						'per' => q({0} na kilogram),
						'two' => q({0} kilograma),
					},
					# Core Unit Identifier
					'kilogram' => {
						'few' => q({0} kilogramy),
						'name' => q(kilogramy),
						'one' => q({0} kilogram),
						'other' => q({0} kilogramow),
						'per' => q({0} na kilogram),
						'two' => q({0} kilograma),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'few' => q({0} mikrogramy),
						'name' => q(mikrogramy),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogramow),
						'two' => q({0} mikrograma),
					},
					# Core Unit Identifier
					'microgram' => {
						'few' => q({0} mikrogramy),
						'name' => q(mikrogramy),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogramow),
						'two' => q({0} mikrograma),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'few' => q({0} miligramy),
						'name' => q(miligramy),
						'one' => q({0} miligram),
						'other' => q({0} miligramow),
						'two' => q({0} miligrama),
					},
					# Core Unit Identifier
					'milligram' => {
						'few' => q({0} miligramy),
						'name' => q(miligramy),
						'one' => q({0} miligram),
						'other' => q({0} miligramow),
						'two' => q({0} miligrama),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'few' => q({0} unce),
						'name' => q(unce),
						'one' => q({0} unca),
						'other' => q({0} uncow),
						'per' => q({0} na uncu),
						'two' => q({0} uncy),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0} unce),
						'name' => q(unce),
						'one' => q({0} unca),
						'other' => q({0} uncow),
						'per' => q({0} na uncu),
						'two' => q({0} uncy),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'few' => q({0} troyske unce),
						'name' => q(troyske unce),
						'one' => q({0} troyska unca),
						'other' => q({0} troyskich uncow),
						'two' => q({0} troyskej uncy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'few' => q({0} troyske unce),
						'name' => q(troyske unce),
						'one' => q({0} troyska unca),
						'other' => q({0} troyskich uncow),
						'two' => q({0} troyskej uncy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0} punty),
						'name' => q(punty),
						'one' => q({0} punt),
						'other' => q({0} puntow),
						'per' => q({0} na punt),
						'two' => q({0} punta),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0} punty),
						'name' => q(punty),
						'one' => q({0} punt),
						'other' => q({0} puntow),
						'per' => q({0} na punt),
						'two' => q({0} punta),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'few' => q({0} mase słyńca),
						'name' => q(mase słyńca),
						'one' => q({0} masa słyńca),
						'other' => q({0} masow słyńca),
						'two' => q({0} masy słyńca),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'few' => q({0} mase słyńca),
						'name' => q(mase słyńca),
						'one' => q({0} masa słyńca),
						'other' => q({0} masow słyńca),
						'two' => q({0} masy słyńca),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'few' => q({0} kamjenje),
						'name' => q(kamjenje),
						'one' => q({0} kamjeń),
						'other' => q({0} kamjenjow),
						'two' => q({0} kamjenja),
					},
					# Core Unit Identifier
					'stone' => {
						'few' => q({0} kamjenje),
						'name' => q(kamjenje),
						'one' => q({0} kamjeń),
						'other' => q({0} kamjenjow),
						'two' => q({0} kamjenja),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0} ameriske tony),
						'name' => q(ameriske tony),
						'one' => q({0} ameriska tona),
						'other' => q({0} ameriskich tonow),
						'two' => q({0} ameriskej tonje),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} ameriske tony),
						'name' => q(ameriske tony),
						'one' => q({0} ameriska tona),
						'other' => q({0} ameriskich tonow),
						'two' => q({0} ameriskej tonje),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'few' => q({0} tony),
						'name' => q(tony),
						'one' => q({0} tona),
						'other' => q({0} tonow),
						'two' => q({0} tonje),
					},
					# Core Unit Identifier
					'tonne' => {
						'few' => q({0} tony),
						'name' => q(tony),
						'one' => q({0} tona),
						'other' => q({0} tonow),
						'two' => q({0} tonje),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} na {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} na {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'few' => q({0} gigawatty),
						'name' => q(gigawatty),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawattow),
						'two' => q({0} gigawatta),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'few' => q({0} gigawatty),
						'name' => q(gigawatty),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawattow),
						'two' => q({0} gigawatta),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} kónjece mócy),
						'name' => q(kónjece mócy),
						'one' => q({0} kónjeca móc),
						'other' => q({0} kónjecych mócow),
						'two' => q({0} kónjecej mócy),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} kónjece mócy),
						'name' => q(kónjece mócy),
						'one' => q({0} kónjeca móc),
						'other' => q({0} kónjecych mócow),
						'two' => q({0} kónjecej mócy),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'few' => q({0} kilowatty),
						'name' => q(kilowatty),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowattow),
						'two' => q({0} kilowatta),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'few' => q({0} kilowatty),
						'name' => q(kilowatty),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowattow),
						'two' => q({0} kilowatta),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'few' => q({0} megawatty),
						'name' => q(megawatty),
						'one' => q({0} megawatt),
						'other' => q({0} megawattow),
						'two' => q({0} megawatta),
					},
					# Core Unit Identifier
					'megawatt' => {
						'few' => q({0} megawatty),
						'name' => q(megawatty),
						'one' => q({0} megawatt),
						'other' => q({0} megawattow),
						'two' => q({0} megawatta),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'few' => q({0} miliwatty),
						'name' => q(miliwatty),
						'one' => q({0} miliwatt),
						'other' => q({0} miliwattow),
						'two' => q({0} miliwatta),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'few' => q({0} miliwatty),
						'name' => q(miliwatty),
						'one' => q({0} miliwatt),
						'other' => q({0} miliwattow),
						'two' => q({0} miliwatta),
					},
					# Long Unit Identifier
					'power-watt' => {
						'few' => q({0} watty),
						'name' => q(watty),
						'one' => q({0} watt),
						'other' => q({0} wattow),
						'two' => q({0} watta),
					},
					# Core Unit Identifier
					'watt' => {
						'few' => q({0} watty),
						'name' => q(watty),
						'one' => q({0} watt),
						'other' => q({0} wattow),
						'two' => q({0} watta),
					},
					# Long Unit Identifier
					'power2' => {
						'few' => q(kwadratne {0}),
						'one' => q(kwadratny {0}),
						'other' => q(kwadratnych {0}),
						'two' => q(kwadratnej {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'few' => q(kwadratne {0}),
						'one' => q(kwadratny {0}),
						'other' => q(kwadratnych {0}),
						'two' => q(kwadratnej {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'few' => q(kubikne {0}),
						'one' => q(kubikny {0}),
						'other' => q(kubiknych {0}),
						'two' => q(kubiknej {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'few' => q(kubikne {0}),
						'one' => q(kubikny {0}),
						'other' => q(kubiknych {0}),
						'two' => q(kubiknej {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'few' => q({0} atmosfery),
						'name' => q(atmosfery),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosferow),
						'two' => q({0} atmosferje),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'few' => q({0} atmosfery),
						'name' => q(atmosfery),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosferow),
						'two' => q({0} atmosferje),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'few' => q({0} bary),
						'name' => q(bary),
						'one' => q({0} bar),
						'other' => q({0} barow),
						'two' => q({0} bara),
					},
					# Core Unit Identifier
					'bar' => {
						'few' => q({0} bary),
						'name' => q(bary),
						'one' => q({0} bar),
						'other' => q({0} barow),
						'two' => q({0} bara),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'few' => q({0} hektopascale),
						'name' => q(hektopascale),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascalow),
						'two' => q({0} hektopascala),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'few' => q({0} hektopascale),
						'name' => q(hektopascale),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascalow),
						'two' => q({0} hektopascala),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0} cole słupika žywego slobra),
						'name' => q(cole žywoslobrowego słupika),
						'one' => q({0} col słupika žywego slobra),
						'other' => q({0} colow słupika žywego slobra),
						'two' => q({0} cola słupika žywego slobra),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} cole słupika žywego slobra),
						'name' => q(cole žywoslobrowego słupika),
						'one' => q({0} col słupika žywego slobra),
						'other' => q({0} colow słupika žywego slobra),
						'two' => q({0} cola słupika žywego slobra),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'few' => q({0} kilopascale),
						'name' => q(kilopascale),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascalow),
						'two' => q({0} kilopascala),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'few' => q({0} kilopascale),
						'name' => q(kilopascale),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascalow),
						'two' => q({0} kilopascala),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'few' => q({0} megapascale),
						'name' => q(megapascale),
						'one' => q({0} megapascal),
						'other' => q({0} megapascalow),
						'two' => q({0} megapascala),
					},
					# Core Unit Identifier
					'megapascal' => {
						'few' => q({0} megapascale),
						'name' => q(megapascale),
						'one' => q({0} megapascal),
						'other' => q({0} megapascalow),
						'two' => q({0} megapascala),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0} milibary),
						'name' => q(milibary),
						'one' => q({0} milibar),
						'other' => q({0} milibarow),
						'two' => q({0} milibara),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0} milibary),
						'name' => q(milibary),
						'one' => q({0} milibar),
						'other' => q({0} milibarow),
						'two' => q({0} milibara),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0} milimetry słupika žywego slobra),
						'name' => q(milimetry słupika žywego slobra),
						'one' => q({0} milimeter słupika žywego slobra),
						'other' => q({0} milimetrow słupika žywego slobra),
						'two' => q({0} milimetra słupika žywego slobra),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0} milimetry słupika žywego slobra),
						'name' => q(milimetry słupika žywego slobra),
						'one' => q({0} milimeter słupika žywego slobra),
						'other' => q({0} milimetrow słupika žywego slobra),
						'two' => q({0} milimetra słupika žywego slobra),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'few' => q({0} pascale),
						'name' => q(pascale),
						'one' => q({0} pascal),
						'other' => q({0} pascalow),
						'two' => q({0} pascala),
					},
					# Core Unit Identifier
					'pascal' => {
						'few' => q({0} pascale),
						'name' => q(pascale),
						'one' => q({0} pascal),
						'other' => q({0} pascalow),
						'two' => q({0} pascala),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0} punty na kwadratny col),
						'name' => q(punty na kwadratny col),
						'one' => q({0} punt na kwadratny col),
						'other' => q({0} puntow na kwadratny col),
						'two' => q({0} punta na kwadratny col),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0} punty na kwadratny col),
						'name' => q(punty na kwadratny col),
						'one' => q({0} punt na kwadratny col),
						'other' => q({0} puntow na kwadratny col),
						'two' => q({0} punta na kwadratny col),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q({0} stopnje beauforta),
						'name' => q(beaufort),
						'one' => q({0} stopjeń beauforta),
						'other' => q({0} stopnjow beauforta),
						'two' => q({0} stopnja beauforta),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q({0} stopnje beauforta),
						'name' => q(beaufort),
						'one' => q({0} stopjeń beauforta),
						'other' => q({0} stopnjow beauforta),
						'two' => q({0} stopnja beauforta),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'few' => q({0} kilometry na góźinu),
						'name' => q(kilometry na góźinu),
						'one' => q({0} kilometer na góźinu),
						'other' => q({0} kilometrow na góźinu),
						'two' => q({0} kilometra na góźinu),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'few' => q({0} kilometry na góźinu),
						'name' => q(kilometry na góźinu),
						'one' => q({0} kilometer na góźinu),
						'other' => q({0} kilometrow na góźinu),
						'two' => q({0} kilometra na góźinu),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0} suki),
						'name' => q(suki),
						'one' => q({0} suk),
						'other' => q({0} sukow),
						'two' => q({0} suka),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0} suki),
						'name' => q(suki),
						'one' => q({0} suk),
						'other' => q({0} sukow),
						'two' => q({0} suka),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'few' => q({0} spěšnosći swětła),
						'name' => q(spěšnosć swětła),
						'one' => q({0} spěšnosć swětła),
						'other' => q({0} spěšnosćow swětła),
						'two' => q({0} spěšnosći swětła),
					},
					# Core Unit Identifier
					'light-speed' => {
						'few' => q({0} spěšnosći swětła),
						'name' => q(spěšnosć swětła),
						'one' => q({0} spěšnosć swětła),
						'other' => q({0} spěšnosćow swětła),
						'two' => q({0} spěšnosći swětła),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'few' => q({0} metry na sekundu),
						'name' => q(metry na sekundu),
						'one' => q({0} meter na sekundu),
						'other' => q({0} metrow na sekundu),
						'two' => q({0} metra na sekundu),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'few' => q({0} metry na sekundu),
						'name' => q(metry na sekundu),
						'one' => q({0} meter na sekundu),
						'other' => q({0} metrow na sekundu),
						'two' => q({0} metra na sekundu),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} mile na góźinu),
						'name' => q(mile na góźinu),
						'one' => q({0} mila na góźinu),
						'other' => q({0} milow na góźinu),
						'two' => q({0} mili na góźinu),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} mile na góźinu),
						'name' => q(mile na góźinu),
						'one' => q({0} mila na góźinu),
						'other' => q({0} milow na góźinu),
						'two' => q({0} mili na góźinu),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'few' => q({0} stopnje celsiusa),
						'name' => q(stopnje celsiusa),
						'one' => q({0} stopjeń celsiusa),
						'other' => q({0} stopnjow celsiusa),
						'two' => q({0} stopnja celsiusa),
					},
					# Core Unit Identifier
					'celsius' => {
						'few' => q({0} stopnje celsiusa),
						'name' => q(stopnje celsiusa),
						'one' => q({0} stopjeń celsiusa),
						'other' => q({0} stopnjow celsiusa),
						'two' => q({0} stopnja celsiusa),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0} stopnje Fahrenheita),
						'name' => q(stopnje Fahrenheita),
						'one' => q({0} stopjeń Fahrenheita),
						'other' => q({0} stopnjow Fahrenheita),
						'two' => q({0} stopnja Fahrenheita),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0} stopnje Fahrenheita),
						'name' => q(stopnje Fahrenheita),
						'one' => q({0} stopjeń Fahrenheita),
						'other' => q({0} stopnjow Fahrenheita),
						'two' => q({0} stopnja Fahrenheita),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'few' => q({0} stopjenje),
						'one' => q({0} stopjeń),
						'other' => q({0} stopjenjow),
						'two' => q({0} stopjenja),
					},
					# Core Unit Identifier
					'generic' => {
						'few' => q({0} stopjenje),
						'one' => q({0} stopjeń),
						'other' => q({0} stopjenjow),
						'two' => q({0} stopjenja),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'few' => q({0} stopnje Kelvina),
						'name' => q(stopnje Kelvina),
						'one' => q({0} stopjeń Kelvina),
						'other' => q({0} stopnjow Kelvina),
						'two' => q({0} stopnja Kelvina),
					},
					# Core Unit Identifier
					'kelvin' => {
						'few' => q({0} stopnje Kelvina),
						'name' => q(stopnje Kelvina),
						'one' => q({0} stopjeń Kelvina),
						'other' => q({0} stopnjow Kelvina),
						'two' => q({0} stopnja Kelvina),
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
						'few' => q({0} newtonmetry),
						'name' => q(newtonmetry),
						'one' => q({0} newtonmeter),
						'other' => q({0} newtonmetrow),
						'two' => q({0} newtonmetra),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'few' => q({0} newtonmetry),
						'name' => q(newtonmetry),
						'one' => q({0} newtonmeter),
						'other' => q({0} newtonmetrow),
						'two' => q({0} newtonmetra),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'few' => q({0} librostopy),
						'name' => q(librostopy),
						'one' => q({0} librostopa),
						'other' => q({0} librostopow),
						'two' => q({0} librostopje),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'few' => q({0} librostopy),
						'name' => q(librostopy),
						'one' => q({0} librostopa),
						'other' => q({0} librostopow),
						'two' => q({0} librostopje),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'few' => q({0} aker-crjeje),
						'name' => q(aker-crjeje),
						'one' => q({0} aker-crjej),
						'other' => q({0} aker-crjej),
						'two' => q({0} aker-crjeja),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'few' => q({0} aker-crjeje),
						'name' => q(aker-crjeje),
						'one' => q({0} aker-crjej),
						'other' => q({0} aker-crjej),
						'two' => q({0} aker-crjeja),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'few' => q({0} barele),
						'name' => q(barele),
						'one' => q({0} barel),
						'other' => q({0} barelow),
						'two' => q({0} barela),
					},
					# Core Unit Identifier
					'barrel' => {
						'few' => q({0} barele),
						'name' => q(barele),
						'one' => q({0} barel),
						'other' => q({0} barelow),
						'two' => q({0} barela),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'few' => q({0} bušle),
						'name' => q(bušle),
						'one' => q({0} bušl),
						'other' => q({0} bušlow),
						'two' => q({0} bušla),
					},
					# Core Unit Identifier
					'bushel' => {
						'few' => q({0} bušle),
						'name' => q(bušle),
						'one' => q({0} bušl),
						'other' => q({0} bušlow),
						'two' => q({0} bušla),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'few' => q({0} centilitry),
						'name' => q(centilitry),
						'one' => q({0} centiliter),
						'other' => q({0} centilitrow),
						'two' => q({0} centilitra),
					},
					# Core Unit Identifier
					'centiliter' => {
						'few' => q({0} centilitry),
						'name' => q(centilitry),
						'one' => q({0} centiliter),
						'other' => q({0} centilitrow),
						'two' => q({0} centilitra),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'few' => q({0} kubikne centimetry),
						'name' => q(kubikne centimetry),
						'one' => q({0} kubikny centimeter),
						'other' => q({0} kubiknych centimetrow),
						'per' => q({0} na kubikny centimeter),
						'two' => q({0} kubiknej centimetra),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'few' => q({0} kubikne centimetry),
						'name' => q(kubikne centimetry),
						'one' => q({0} kubikny centimeter),
						'other' => q({0} kubiknych centimetrow),
						'per' => q({0} na kubikny centimeter),
						'two' => q({0} kubiknej centimetra),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0} kubikne crjeje),
						'name' => q(kubikne crjeje),
						'one' => q({0} kubikny crjej),
						'other' => q({0} kubiknych crjejow),
						'two' => q({0} kubiknej crjeja),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0} kubikne crjeje),
						'name' => q(kubikne crjeje),
						'one' => q({0} kubikny crjej),
						'other' => q({0} kubiknych crjejow),
						'two' => q({0} kubiknej crjeja),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0} kubikne cole),
						'name' => q(kubikne cole),
						'one' => q({0} kubikny col),
						'other' => q({0} kubiknych colow),
						'two' => q({0} kubiknej cola),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0} kubikne cole),
						'name' => q(kubikne cole),
						'one' => q({0} kubikny col),
						'other' => q({0} kubiknych colow),
						'two' => q({0} kubiknej cola),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'few' => q({0} kubikne kilometry),
						'name' => q(kubikne kilometry),
						'one' => q({0} kubikny kilometer),
						'other' => q({0} kubiknych kilometrow),
						'two' => q({0} kubiknej kilometra),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'few' => q({0} kubikne kilometry),
						'name' => q(kubikne kilometry),
						'one' => q({0} kubikny kilometer),
						'other' => q({0} kubiknych kilometrow),
						'two' => q({0} kubiknej kilometra),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'few' => q({0} kubikne metry),
						'name' => q(kubikne metry),
						'one' => q({0} kubikny meter),
						'other' => q({0} kubiknych metrow),
						'per' => q({0} na kubikny meter),
						'two' => q({0} kubiknej metra),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'few' => q({0} kubikne metry),
						'name' => q(kubikne metry),
						'one' => q({0} kubikny meter),
						'other' => q({0} kubiknych metrow),
						'per' => q({0} na kubikny meter),
						'two' => q({0} kubiknej metra),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0} kubikne mile),
						'name' => q(kubikne mile),
						'one' => q({0} kubikna mila),
						'other' => q({0} kubiknych milow),
						'two' => q({0} kubiknej mili),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0} kubikne mile),
						'name' => q(kubikne mile),
						'one' => q({0} kubikna mila),
						'other' => q({0} kubiknych milow),
						'two' => q({0} kubiknej mili),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0} kubikne yardy),
						'name' => q(kubikne yardy),
						'one' => q({0} kubikny yard),
						'other' => q({0} kubiknych yardow),
						'two' => q({0} kubiknej yarda),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0} kubikne yardy),
						'name' => q(kubikne yardy),
						'one' => q({0} kubikny yard),
						'other' => q({0} kubiknych yardow),
						'two' => q({0} kubiknej yarda),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0} taski),
						'name' => q(taski),
						'one' => q({0} taska),
						'other' => q({0} taskow),
						'two' => q({0} tasce),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0} taski),
						'name' => q(taski),
						'one' => q({0} taska),
						'other' => q({0} taskow),
						'two' => q({0} tasce),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'few' => q({0} metriske taski),
						'name' => q(metriske taski),
						'one' => q({0} metriska taska),
						'other' => q({0} metriskich taskow),
						'two' => q({0} metriskej tasce),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'few' => q({0} metriske taski),
						'name' => q(metriske taski),
						'one' => q({0} metriska taska),
						'other' => q({0} metriskich taskow),
						'two' => q({0} metriskej tasce),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'few' => q({0} decilitry),
						'name' => q(decilitry),
						'one' => q({0} deciliter),
						'other' => q({0} decilitrow),
						'two' => q({0} decilitra),
					},
					# Core Unit Identifier
					'deciliter' => {
						'few' => q({0} decilitry),
						'name' => q(decilitry),
						'one' => q({0} deciliter),
						'other' => q({0} decilitrow),
						'two' => q({0} decilitra),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} dessertowe łžycki),
						'name' => q(dessertowe łžycki),
						'one' => q({0} dessertowa łžycka),
						'other' => q({0} dessertowych łžyckow),
						'two' => q({0} dessertowej łžycce),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} dessertowe łžycki),
						'name' => q(dessertowe łžycki),
						'one' => q({0} dessertowa łžycka),
						'other' => q({0} dessertowych łžyckow),
						'two' => q({0} dessertowej łžycce),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} britiske łžycki),
						'name' => q(britiske łžycki),
						'one' => q({0} britiska łžycka),
						'other' => q({0} britiskich łžyckow),
						'two' => q({0} britiskej łžycce),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} britiske łžycki),
						'name' => q(britiske łžycki),
						'one' => q({0} britiska łžycka),
						'other' => q({0} britiskich łžyckow),
						'two' => q({0} britiskej łžycce),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} dramy),
						'name' => q(dramy),
						'one' => q({0} dram),
						'other' => q({0} dramow),
						'two' => q({0} drama),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} dramy),
						'name' => q(dramy),
						'one' => q({0} dram),
						'other' => q({0} dramow),
						'two' => q({0} drama),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0} chrapki),
						'name' => q(chrapki),
						'one' => q({0} chrapka),
						'other' => q({0} chrapkow),
						'two' => q({0} chrapce),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0} chrapki),
						'name' => q(chrapki),
						'one' => q({0} chrapka),
						'other' => q({0} chrapkow),
						'two' => q({0} chrapce),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} žydke unce),
						'name' => q(žydke unce),
						'one' => q({0} žydka unca),
						'other' => q({0} žydkych uncow),
						'two' => q({0} žydkej uncy),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} žydke unce),
						'name' => q(žydke unce),
						'one' => q({0} žydka unca),
						'other' => q({0} žydkych uncow),
						'two' => q({0} žydkej uncy),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} britiske běžece uncy),
						'name' => q(britiske běžne uncy),
						'one' => q({0} britiska běžeca unca),
						'other' => q({0} britiskich běžecych uncow),
						'two' => q({0} britiskej běžecej uncy),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} britiske běžece uncy),
						'name' => q(britiske běžne uncy),
						'one' => q({0} britiska běžeca unca),
						'other' => q({0} britiskich běžecych uncow),
						'two' => q({0} britiskej běžecej uncy),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} gallony),
						'name' => q(gallony),
						'one' => q({0} gallona),
						'other' => q({0} gallonow),
						'per' => q({0} na galonu),
						'two' => q({0} gallonje),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} gallony),
						'name' => q(gallony),
						'one' => q({0} gallona),
						'other' => q({0} gallonow),
						'per' => q({0} na galonu),
						'two' => q({0} gallonje),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} britiske galony),
						'name' => q(britiske galony),
						'one' => q({0} britiska galona),
						'other' => q({0} britiskich galonow),
						'per' => q({0} na britisku galonu),
						'two' => q({0} britiskej galonje),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} britiske galony),
						'name' => q(britiske galony),
						'one' => q({0} britiska galona),
						'other' => q({0} britiskich galonow),
						'per' => q({0} na britisku galonu),
						'two' => q({0} britiskej galonje),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'few' => q({0} hektolitry),
						'name' => q(hektolitry),
						'one' => q({0} hektoliter),
						'other' => q({0} hektolitrow),
						'two' => q({0} hektolitra),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'few' => q({0} hektolitry),
						'name' => q(hektolitry),
						'one' => q({0} hektoliter),
						'other' => q({0} hektolitrow),
						'two' => q({0} hektolitra),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'few' => q({0} litry),
						'name' => q(litry),
						'one' => q({0} liter),
						'other' => q({0} litrow),
						'per' => q({0} na liter),
						'two' => q({0} litra),
					},
					# Core Unit Identifier
					'liter' => {
						'few' => q({0} litry),
						'name' => q(litry),
						'one' => q({0} liter),
						'other' => q({0} litrow),
						'per' => q({0} na liter),
						'two' => q({0} litra),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'few' => q({0} megalitry),
						'name' => q(megalitry),
						'one' => q({0} megaliter),
						'other' => q({0} megalitrow),
						'two' => q({0} megalitra),
					},
					# Core Unit Identifier
					'megaliter' => {
						'few' => q({0} megalitry),
						'name' => q(megalitry),
						'one' => q({0} megaliter),
						'other' => q({0} megalitrow),
						'two' => q({0} megalitra),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'few' => q({0} mililitry),
						'name' => q(mililitry),
						'one' => q({0} mililiter),
						'other' => q({0} mililitrow),
						'two' => q({0} mililitra),
					},
					# Core Unit Identifier
					'milliliter' => {
						'few' => q({0} mililitry),
						'name' => q(mililitry),
						'one' => q({0} mililiter),
						'other' => q({0} mililitrow),
						'two' => q({0} mililitra),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'few' => q({0} pinty),
						'name' => q(pinty),
						'one' => q({0} pint),
						'other' => q({0} pintow),
						'two' => q({0} pinta),
					},
					# Core Unit Identifier
					'pint' => {
						'few' => q({0} pinty),
						'name' => q(pinty),
						'one' => q({0} pint),
						'other' => q({0} pintow),
						'two' => q({0} pinta),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'few' => q({0} metriske pinty),
						'name' => q(metriske pinty),
						'one' => q({0} metriski pint),
						'other' => q({0} metriskich pintow),
						'two' => q({0} metriskej pinta),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'few' => q({0} metriske pinty),
						'name' => q(metriske pinty),
						'one' => q({0} metriski pint),
						'other' => q({0} metriskich pintow),
						'two' => q({0} metriskej pinta),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'few' => q({0} quarty),
						'name' => q(quarty),
						'one' => q({0} quart),
						'other' => q({0} quartow),
						'two' => q({0} quarta),
					},
					# Core Unit Identifier
					'quart' => {
						'few' => q({0} quarty),
						'name' => q(quarty),
						'one' => q({0} quart),
						'other' => q({0} quartow),
						'two' => q({0} quarta),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} britiske běrtyle),
						'name' => q(britiske běrtyle),
						'one' => q({0} britiski běrtyl),
						'other' => q({0} britiskich běrtylow),
						'two' => q({0} britiskej běrtyla),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} britiske běrtyle),
						'name' => q(britiske běrtyle),
						'one' => q({0} britiski běrtyl),
						'other' => q({0} britiskich běrtylow),
						'two' => q({0} britiskej běrtyla),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} łžyce),
						'name' => q(łžyce),
						'one' => q({0} łžyca),
						'other' => q({0} łžycow),
						'two' => q({0} łžycy),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} łžyce),
						'name' => q(łžyce),
						'one' => q({0} łžyca),
						'other' => q({0} łžycow),
						'two' => q({0} łžycy),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} łžycki),
						'name' => q(łžycki),
						'one' => q({0} łžycka),
						'other' => q({0} łžyckow),
						'two' => q({0} łžycce),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} łžycki),
						'name' => q(łžycki),
						'one' => q({0} łžycka),
						'other' => q({0} łžyckow),
						'two' => q({0} łžycce),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'angle-arc-minute' => {
						'few' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
						'two' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'few' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
						'two' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'few' => q({0}″),
						'one' => q({0}″),
						'other' => q({0}″),
						'two' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'few' => q({0}″),
						'one' => q({0}″),
						'other' => q({0}″),
						'two' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'few' => q({0}°),
						'one' => q({0}°),
						'other' => q({0}°),
						'two' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'few' => q({0}°),
						'one' => q({0}°),
						'other' => q({0}°),
						'two' => q({0}°),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'few' => q({0} n),
						'name' => q(n),
						'one' => q({0} n),
						'other' => q({0} n),
						'two' => q({0} n),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'few' => q({0} n),
						'name' => q(n),
						'one' => q({0} n),
						'other' => q({0} n),
						'two' => q({0} n),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} d),
						'name' => q(d),
						'one' => q({0} ź),
						'other' => q({0} d),
						'two' => q({0} d),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} d),
						'name' => q(d),
						'one' => q({0} ź),
						'other' => q({0} d),
						'two' => q({0} d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'few' => q({0} g),
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'two' => q({0} g),
					},
					# Core Unit Identifier
					'hour' => {
						'few' => q({0} g),
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'two' => q({0} g),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} min),
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'two' => q({0} min),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} min),
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'two' => q({0} min),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} kw.),
						'name' => q(kw.),
						'one' => q({0} kw.),
						'other' => q({0} kw.),
						'per' => q({0}/kw.),
						'two' => q({0} kw.),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} kw.),
						'name' => q(kw.),
						'one' => q({0} kw.),
						'other' => q({0} kw.),
						'per' => q({0}/kw.),
						'two' => q({0} kw.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} s),
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'two' => q({0} s),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} s),
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'two' => q({0} s),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'few' => q({0} c),
						'name' => q(c),
						'one' => q({0} c),
						'other' => q({0} c),
						'two' => q({0} c),
					},
					# Core Unit Identifier
					'light-speed' => {
						'few' => q({0} c),
						'name' => q(c),
						'one' => q({0} c),
						'other' => q({0} c),
						'two' => q({0} c),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} šć),
						'name' => q(šć),
						'one' => q({0} šć),
						'other' => q({0} šć),
						'two' => q({0} šć),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} šć),
						'name' => q(šć),
						'one' => q({0} šć),
						'other' => q({0} šć),
						'two' => q({0} šć),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(směr),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(směr),
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
						'few' => q({0} ′),
						'name' => q(′),
						'one' => q({0} ′),
						'other' => q({0} ′),
						'two' => q({0} ′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'few' => q({0} ′),
						'name' => q(′),
						'one' => q({0} ′),
						'other' => q({0} ′),
						'two' => q({0} ′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'few' => q({0} ″),
						'name' => q(″),
						'one' => q({0} ″),
						'other' => q({0} ″),
						'two' => q({0} ″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'few' => q({0} ″),
						'name' => q(″),
						'one' => q({0} ″),
						'other' => q({0} ″),
						'two' => q({0} ″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'few' => q({0} °),
						'name' => q(°),
						'one' => q({0} °),
						'other' => q({0} °),
						'two' => q({0} °),
					},
					# Core Unit Identifier
					'degree' => {
						'few' => q({0} °),
						'name' => q(°),
						'one' => q({0} °),
						'other' => q({0} °),
						'two' => q({0} °),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0} wobr.),
						'name' => q(wobr.),
						'one' => q({0} wobr.),
						'other' => q({0} wobr.),
						'two' => q({0} wobr.),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0} wobr.),
						'name' => q(wobr.),
						'one' => q({0} wobr.),
						'other' => q({0} wobr.),
						'two' => q({0} wobr.),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ac),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0} dun.),
						'name' => q(dun.),
						'one' => q({0} dun.),
						'other' => q({0} dun.),
						'two' => q({0} dun.),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0} dun.),
						'name' => q(dun.),
						'one' => q({0} dun.),
						'other' => q({0} dun.),
						'two' => q({0} dun.),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ha),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'few' => q({0} kuse),
						'name' => q(kus),
						'one' => q({0} kus),
						'other' => q({0} kusow),
						'two' => q({0} kusa),
					},
					# Core Unit Identifier
					'item' => {
						'few' => q({0} kuse),
						'name' => q(kus),
						'one' => q({0} kus),
						'other' => q({0} kusow),
						'two' => q({0} kusa),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} mg/dl),
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
						'two' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} mg/dl),
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
						'two' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'few' => q({0} mmol/l),
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
						'two' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'few' => q({0} mmol/l),
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
						'two' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'few' => q({0} %),
						'one' => q({0} %),
						'other' => q({0} %),
						'two' => q({0} %),
					},
					# Core Unit Identifier
					'percent' => {
						'few' => q({0} %),
						'one' => q({0} %),
						'other' => q({0} %),
						'two' => q({0} %),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'few' => q({0} ‰),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
						'two' => q({0} ‰),
					},
					# Core Unit Identifier
					'permille' => {
						'few' => q({0} ‰),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
						'two' => q({0} ‰),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'few' => q({0} ‱),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
						'two' => q({0} ‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'few' => q({0} ‱),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
						'two' => q({0} ‱),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'few' => q({0} nano),
						'name' => q(nano),
						'one' => q({0} nano),
						'other' => q({0} nano),
						'two' => q({0} nano),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'few' => q({0} nano),
						'name' => q(nano),
						'one' => q({0} nano),
						'other' => q({0} nano),
						'two' => q({0} nano),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} l/100km),
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
						'two' => q({0} l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} l/100km),
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
						'two' => q({0} l/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} l/km),
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
						'two' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} l/km),
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
						'two' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
						'two' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
						'two' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} mpg brit.),
						'name' => q(mpg brit.),
						'one' => q({0} mpg brit.),
						'other' => q({0} mpg brit.),
						'two' => q({0} mpg brit.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} mpg brit.),
						'name' => q(mpg brit.),
						'one' => q({0} mpg brit.),
						'other' => q({0} mpg brit.),
						'two' => q({0} mpg brit.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} pz),
						'north' => q({0} pn),
						'south' => q({0} pł),
						'west' => q({0} pw),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} pz),
						'north' => q({0} pn),
						'south' => q({0} pł),
						'west' => q({0} pw),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} lětst.),
						'name' => q(lětst.),
						'one' => q({0} lětst.),
						'other' => q({0} lětst.),
						'two' => q({0} lětst.),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} lětst.),
						'name' => q(lětst.),
						'one' => q({0} lětst.),
						'other' => q({0} lětst.),
						'two' => q({0} lětst.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} dn.),
						'name' => q(dny),
						'one' => q({0} ź.),
						'other' => q({0} dn.),
						'per' => q({0}/ź.),
						'two' => q({0} dn.),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} dn.),
						'name' => q(dny),
						'one' => q({0} ź.),
						'other' => q({0} dn.),
						'per' => q({0}/ź.),
						'two' => q({0} dn.),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0} lětź.),
						'name' => q(lětź.),
						'one' => q({0} lětź.),
						'other' => q({0} lětź.),
						'two' => q({0} lětź.),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0} lětź.),
						'name' => q(lětź.),
						'one' => q({0} lětź.),
						'other' => q({0} lětź.),
						'two' => q({0} lětź.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'few' => q({0} góź.),
						'name' => q(góź.),
						'one' => q({0} góź.),
						'other' => q({0} góź.),
						'two' => q({0} góź.),
					},
					# Core Unit Identifier
					'hour' => {
						'few' => q({0} góź.),
						'name' => q(góź.),
						'one' => q({0} góź.),
						'other' => q({0} góź.),
						'two' => q({0} góź.),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} min.),
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
						'two' => q({0} min.),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} min.),
						'name' => q(min.),
						'one' => q({0} min.),
						'other' => q({0} min.),
						'per' => q({0}/min.),
						'two' => q({0} min.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} mjas.),
						'name' => q(mjas.),
						'one' => q({0} mjas.),
						'other' => q({0} mjas.),
						'per' => q({0} /mjas.),
						'two' => q({0} mjas.),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} mjas.),
						'name' => q(mjas.),
						'one' => q({0} mjas.),
						'other' => q({0} mjas.),
						'per' => q({0} /mjas.),
						'two' => q({0} mjas.),
					},
					# Long Unit Identifier
					'duration-night' => {
						'few' => q({0} nocy),
						'name' => q(nocy),
						'one' => q({0} noc),
						'other' => q({0} nocow),
						'per' => q({0} na noc),
						'two' => q({0} nocy),
					},
					# Core Unit Identifier
					'night' => {
						'few' => q({0} nocy),
						'name' => q(nocy),
						'one' => q({0} noc),
						'other' => q({0} nocow),
						'per' => q({0} na noc),
						'two' => q({0} nocy),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} kwart.),
						'name' => q(kwart.),
						'one' => q({0} kwart.),
						'other' => q({0} kwart.),
						'per' => q({0}/kwart.),
						'two' => q({0} kwart.),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} kwart.),
						'name' => q(kwart.),
						'one' => q({0} kwart.),
						'other' => q({0} kwart.),
						'per' => q({0}/kwart.),
						'two' => q({0} kwart.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} sek.),
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'two' => q({0} sek.),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} sek.),
						'name' => q(sek.),
						'one' => q({0} sek.),
						'other' => q({0} sek.),
						'two' => q({0} sek.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} tyź.),
						'name' => q(tyź.),
						'one' => q({0} tyź.),
						'other' => q({0} tyź.),
						'per' => q({0} /tyź.),
						'two' => q({0} tyź.),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} tyź.),
						'name' => q(tyź.),
						'one' => q({0} tyź.),
						'other' => q({0} tyź.),
						'per' => q({0} /tyź.),
						'two' => q({0} tyź.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} l.),
						'name' => q(l.),
						'one' => q({0} l.),
						'other' => q({0} l.),
						'per' => q({0}/l.),
						'two' => q({0} l.),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} l.),
						'name' => q(l.),
						'one' => q({0} l.),
						'other' => q({0} l.),
						'per' => q({0}/l.),
						'two' => q({0} l.),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(A),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(A),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(V),
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
					'energy-therm-us' => {
						'few' => q({0} US therms),
						'one' => q({0} US therm),
						'other' => q({0} US therms),
						'two' => q({0} US therms),
					},
					# Core Unit Identifier
					'therm-us' => {
						'few' => q({0} US therms),
						'one' => q({0} US therm),
						'other' => q({0} US therms),
						'two' => q({0} US therms),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fth),
					},
					# Long Unit Identifier
					'length-inch' => {
						'per' => q({0}/col),
					},
					# Core Unit Identifier
					'inch' => {
						'per' => q({0}/col),
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
					'mass-carat' => {
						'few' => q({0} Kt),
						'name' => q(Kt),
						'one' => q({0} Kt),
						'other' => q({0} Kt),
						'two' => q({0} Kt),
					},
					# Core Unit Identifier
					'carat' => {
						'few' => q({0} Kt),
						'name' => q(Kt),
						'one' => q({0} Kt),
						'other' => q({0} Kt),
						'two' => q({0} Kt),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} grainy),
						'one' => q({0} grain),
						'other' => q({0} grainow),
						'two' => q({0} graina),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} grainy),
						'one' => q({0} grain),
						'other' => q({0} grainow),
						'two' => q({0} graina),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'few' => q({0} oz. tr.),
						'name' => q(oz. tr.),
						'one' => q({0} oz. tr.),
						'other' => q({0} oz. tr.),
						'two' => q({0} oz. tr.),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'few' => q({0} oz. tr.),
						'name' => q(oz. tr.),
						'one' => q({0} oz. tr.),
						'other' => q({0} oz. tr.),
						'two' => q({0} oz. tr.),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(am.tony),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(am.tony),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} PS),
						'name' => q(PS),
						'one' => q({0} PS),
						'other' => q({0} PS),
						'two' => q({0} PS),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} PS),
						'name' => q(PS),
						'one' => q({0} PS),
						'other' => q({0} PS),
						'two' => q({0} PS),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(W),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q({0} Bft),
						'one' => q({0} Bft),
						'other' => q({0} Bft),
						'two' => q({0} Bft),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q({0} Bft),
						'one' => q({0} Bft),
						'other' => q({0} Bft),
						'two' => q({0} Bft),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0} sk),
						'name' => q(sk),
						'one' => q({0} sk),
						'other' => q({0} sk),
						'two' => q({0} sk),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0} sk),
						'name' => q(sk),
						'one' => q({0} sk),
						'other' => q({0} sk),
						'two' => q({0} sk),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'few' => q({0} spěšnosći sw.),
						'name' => q(spěšnosć sw.),
						'one' => q({0} spěšnosć sw.),
						'other' => q({0} spěšnosćow sw.),
						'two' => q({0} spěšnosći sw.),
					},
					# Core Unit Identifier
					'light-speed' => {
						'few' => q({0} spěšnosći sw.),
						'name' => q(spěšnosć sw.),
						'one' => q({0} spěšnosć sw.),
						'other' => q({0} spěšnosćow sw.),
						'two' => q({0} spěšnosći sw.),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} mph),
						'name' => q(mph),
						'one' => q({0} mph),
						'other' => q({0} mph),
						'two' => q({0} mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} mph),
						'name' => q(mph),
						'one' => q({0} mph),
						'other' => q({0} mph),
						'two' => q({0} mph),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'few' => q({0} Nm),
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
						'two' => q({0} Nm),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'few' => q({0} Nm),
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
						'two' => q({0} Nm),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'few' => q({0} cl),
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
						'two' => q({0} cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'few' => q({0} cl),
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
						'two' => q({0} cl),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(c),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(c),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(mc),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(mc),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'few' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
						'two' => q({0} dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'few' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
						'two' => q({0} dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} dess. łžk.),
						'name' => q(dess. łžk.),
						'one' => q({0} dess. łžk.),
						'other' => q({0} dess. łžk.),
						'two' => q({0} dess. łžk.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} dess. łžk.),
						'name' => q(dess. łžk.),
						'one' => q({0} dess. łžk.),
						'other' => q({0} dess. łžk.),
						'two' => q({0} dess. łžk.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} imp. łžk.),
						'name' => q(imp. łžk.),
						'one' => q({0} imp. łžk.),
						'other' => q({0} imp. łžk.),
						'two' => q({0} imp. łžk.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} imp. łžk.),
						'name' => q(imp. łžk.),
						'one' => q({0} imp. łžk.),
						'other' => q({0} imp. łžk.),
						'two' => q({0} imp. łžk.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} dr),
						'name' => q(dr),
						'one' => q({0} dr),
						'other' => q({0} dr),
						'two' => q({0} dr),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} dr),
						'name' => q(dr),
						'one' => q({0} dr),
						'other' => q({0} dr),
						'two' => q({0} dr),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0} chpk.),
						'name' => q(chpk.),
						'one' => q({0} chpk.),
						'other' => q({0} chpk.),
						'two' => q({0} chpk.),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0} chpk.),
						'name' => q(chpk.),
						'one' => q({0} chpk.),
						'other' => q({0} chpk.),
						'two' => q({0} chpk.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} fl. oz.),
						'name' => q(fl. oz.),
						'one' => q({0} fl. oz.),
						'other' => q({0} fl. oz.),
						'two' => q({0} fl. oz.),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} fl. oz.),
						'name' => q(fl. oz.),
						'one' => q({0} fl. oz.),
						'other' => q({0} fl. oz.),
						'two' => q({0} fl. oz.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} brit. fl oz),
						'name' => q(brit. fl oz),
						'one' => q({0} brit. fl oz),
						'other' => q({0} brit. fl oz),
						'two' => q({0} brit. fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} brit. fl oz),
						'name' => q(brit. fl oz),
						'one' => q({0} brit. fl oz),
						'other' => q({0} brit. fl oz),
						'two' => q({0} brit. fl oz),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
						'two' => q({0} gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
						'two' => q({0} gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} brit. gal.),
						'name' => q(brit. gal.),
						'one' => q({0} brit. gal.),
						'other' => q({0} brit. gal.),
						'per' => q({0}/brit. gal.),
						'two' => q({0} brit. gal.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} brit. gal.),
						'name' => q(brit. gal.),
						'one' => q({0} brit. gal.),
						'other' => q({0} brit. gal.),
						'per' => q({0}/brit. gal.),
						'two' => q({0} brit. gal.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'few' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
						'two' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'few' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
						'two' => q({0} hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} jiggery),
						'name' => q(jiggery),
						'one' => q({0} jigger),
						'other' => q({0} jiggerow),
						'two' => q({0} jiggera),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} jiggery),
						'name' => q(jiggery),
						'one' => q({0} jigger),
						'other' => q({0} jiggerow),
						'two' => q({0} jiggera),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'few' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
						'two' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'few' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
						'two' => q({0} Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'few' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
						'two' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'few' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
						'two' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} šćipki),
						'name' => q(šćipki),
						'one' => q({0} šćipka),
						'other' => q({0} šćipkow),
						'two' => q({0} šćipce),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} šćipki),
						'name' => q(šćipki),
						'one' => q({0} šćipka),
						'other' => q({0} šćipkow),
						'two' => q({0} šćipce),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} łž.),
						'name' => q(łž.),
						'one' => q({0} łž.),
						'other' => q({0} łž.),
						'two' => q({0} łž.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} łž.),
						'name' => q(łž.),
						'one' => q({0} łž.),
						'other' => q({0} łž.),
						'two' => q({0} łž.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} łžk.),
						'name' => q(łžk.),
						'one' => q({0} łžk.),
						'other' => q({0} łžk.),
						'two' => q({0} łžk.),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} łžk.),
						'name' => q(łžk.),
						'one' => q({0} łžk.),
						'other' => q({0} łžk.),
						'two' => q({0} łžk.),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:jo|j|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ně|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} a {1}),
				2 => q({0} a {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'group' => q(.),
			'superscriptingExponent' => q(·),
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
					'few' => '0 tysac',
					'one' => '0 tysac',
					'other' => '0 tysac',
					'two' => '0 tysac',
				},
				'10000' => {
					'few' => '00 tysac',
					'one' => '00 tysac',
					'other' => '00 tysac',
					'two' => '00 tysac',
				},
				'100000' => {
					'few' => '000 tysac',
					'one' => '000 tysac',
					'other' => '000 tysac',
					'two' => '000 tysac',
				},
				'1000000' => {
					'few' => '0 miliony',
					'one' => '0 milion',
					'other' => '0 milionow',
					'two' => '0 miliona',
				},
				'10000000' => {
					'few' => '00 milionow',
					'one' => '00 milionow',
					'other' => '00 milionow',
					'two' => '00 milionow',
				},
				'100000000' => {
					'few' => '000 milionow',
					'one' => '000 milionow',
					'other' => '000 milionow',
					'two' => '000 milionow',
				},
				'1000000000' => {
					'few' => '0 miliardy',
					'one' => '0 miliarda',
					'other' => '0 miliardow',
					'two' => '0 miliarźe',
				},
				'10000000000' => {
					'few' => '00 miliardow',
					'one' => '00 miliardow',
					'other' => '00 miliardow',
					'two' => '00 miliardow',
				},
				'100000000000' => {
					'few' => '000 miliardow',
					'one' => '000 miliardow',
					'other' => '000 miliardow',
					'two' => '000 miliardow',
				},
				'1000000000000' => {
					'few' => '0 biliony',
					'one' => '0 bilion',
					'other' => '0 bilionow',
					'two' => '0 biliona',
				},
				'10000000000000' => {
					'few' => '00 bilionow',
					'one' => '00 bilionow',
					'other' => '00 bilionow',
					'two' => '00 bilionow',
				},
				'100000000000000' => {
					'few' => '000 bilionow',
					'one' => '000 bilionow',
					'other' => '000 bilionow',
					'two' => '000 bilionow',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 tys'.'',
					'other' => '0 tys'.'',
				},
				'10000' => {
					'one' => '00 tys'.'',
					'other' => '00 tys'.'',
				},
				'100000' => {
					'one' => '000 tys'.'',
					'other' => '000 tys'.'',
				},
				'1000000' => {
					'one' => '0 mio'.'',
					'other' => '0 mio'.'',
				},
				'10000000' => {
					'one' => '00 mio'.'',
					'other' => '00 mio'.'',
				},
				'100000000' => {
					'one' => '000 mio'.'',
					'other' => '000 mio'.'',
				},
				'1000000000' => {
					'one' => '0 mrd'.'',
					'other' => '0 mrd'.'',
				},
				'10000000000' => {
					'one' => '00 mrd'.'',
					'other' => '00 mrd'.'',
				},
				'100000000000' => {
					'one' => '000 mrd'.'',
					'other' => '000 mrd'.'',
				},
				'1000000000000' => {
					'one' => '0 bil'.'',
					'other' => '0 bil'.'',
				},
				'10000000000000' => {
					'one' => '00 bil'.'',
					'other' => '00 bil'.'',
				},
				'100000000000000' => {
					'one' => '000 bil'.'',
					'other' => '000 bil'.'',
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
		'ADP' => {
			display_name => {
				'currency' => q(andorraska peseta),
				'few' => q(andorraske pesety),
				'one' => q(andorraska peseta),
				'other' => q(andorraskich pesetow),
				'two' => q(andorraskej peseśe),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(ZAE dirham),
				'few' => q(SAE dirhamy),
				'one' => q(ZAE dirham),
				'other' => q(SAE dirhamow),
				'two' => q(ZAE dirhama),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afghaniski afgani),
				'few' => q(afghaniske afganije),
				'one' => q(afghaniski afgani),
				'other' => q(afghaniskich afganijow),
				'two' => q(afghaniskej afganija),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(albański lek),
				'few' => q(albańske leki),
				'one' => q(albański lek),
				'other' => q(albańskich lekow),
				'two' => q(albańskej leka),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(armeński dram),
				'few' => q(armeńske dramy),
				'one' => q(armeński dram),
				'other' => q(armeńskich dramow),
				'two' => q(armeńskej drama),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(nižozemsko-antilski gulden),
				'few' => q(nižozemskoantilske guldeny),
				'one' => q(nižozemskoantilski gulden),
				'other' => q(nižozemskoantilskich guldenow),
				'two' => q(nižozemskoantilskej guldena),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(angolska kwanza),
				'few' => q(angolske kwanze),
				'one' => q(angolska kwanza),
				'other' => q(angolskich kwanzow),
				'two' => q(angolskej kwanzy),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(angolska kwanza \(1977–1990\)),
				'few' => q(angolske kwanze \(1977–1990\)),
				'one' => q(angolska kwanza \(1977–1990\)),
				'other' => q(angolskich kwanzow \(1977–1990\)),
				'two' => q(angolskej kwanzy \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(angolska nowa kwanza \(1990–2000\)),
				'few' => q(angolske nowe kwanze \(1990–2000\)),
				'one' => q(angolska nowa kwanza \(1990–2000\)),
				'other' => q(angolskich nowych kwanzow \(1990–2000\)),
				'two' => q(angolskej nowej kwanzy \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(angolska kwanza reajustado \(1995–1999\)),
				'few' => q(angolske kwanze reajustado \(1995–1999\)),
				'one' => q(angolska kwanza reajustado \(1995–1999\)),
				'other' => q(angolskich kwanzow reajustado \(1995–1999\)),
				'two' => q(angolskej kwanzy reajustado \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(argentinski austral),
				'few' => q(argentinske australy),
				'one' => q(argentinski austral),
				'other' => q(argentinskich australow),
				'two' => q(argentinskej australa),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(argentinski peso \(1983–1985\)),
				'few' => q(argentinske peso \(1983–1985\)),
				'one' => q(argentinski peso \(1983–1985\)),
				'other' => q(argentinskich peso \(1983–1985\)),
				'two' => q(argentinskej peso \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(argentinski peso),
				'few' => q(argentinske peso),
				'one' => q(argentinski peso),
				'other' => q(argentinskich peso),
				'two' => q(argentinskej peso),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(rakuski šiling),
				'few' => q(rakuske šilingi),
				'one' => q(rakuski šiling),
				'other' => q(rakuskich šilingow),
				'two' => q(rakuskej šilinga),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(awstralski dolar),
				'few' => q(awstralske dolary),
				'one' => q(awstralski dolar),
				'other' => q(awstralskich dolarow),
				'two' => q(awstralskej dolara),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(aruba-florin),
				'few' => q(aruba-floriny),
				'one' => q(aruba-florin),
				'other' => q(aruba-florinow),
				'two' => q(aruba-florina),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(azerbajdžaniski manat \(1993–2006\)),
				'few' => q(azerbajdžaniske manaty \(1993–2006\)),
				'one' => q(azerbajdžaniski manat \(1993–2006\)),
				'other' => q(azerbajdžaniskich manatow \(1993–2006\)),
				'two' => q(azerbajdžaniskej manata \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(azerbajdžaniski manat),
				'few' => q(azerbajdžaniske manaty),
				'one' => q(azerbajdžaniski manat),
				'other' => q(azerbajdžaniskich manatow),
				'two' => q(azerbajdžaniskej manata),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(bosniski dinar),
				'few' => q(bosniske dinary),
				'one' => q(bosniski dinar),
				'other' => q(bosniskich dinarow),
				'two' => q(bosniskej dinara),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(bosniska konwertibelna marka),
				'few' => q(bosniske konwertibelne marki),
				'one' => q(bosniska konwertibelna marka),
				'other' => q(bosniskich konwertibelnych markow),
				'two' => q(bosniskej konwertibelnej marce),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(barbadoski dolar),
				'few' => q(barbadoske dolary),
				'one' => q(barbadoski dolar),
				'other' => q(barbadoskich dolarow),
				'two' => q(barbadoskej dolara),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(bangladešska taka),
				'few' => q(bangladešske taki),
				'one' => q(bangladešska taka),
				'other' => q(bangladešskich takow),
				'two' => q(bangladešskej tace),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(belgiski frank \(konwertibelny\)),
				'few' => q(belgiske franki \(konwertibelne\)),
				'one' => q(belgiski frank \(konwertibelny\)),
				'other' => q(belgiskich frankow \(konwertibelnych\)),
				'two' => q(belgiskej franka \(konwertibelnej\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(belgiski frank),
				'few' => q(belgiske franki),
				'one' => q(belgiski frank),
				'other' => q(belgiskich frankow),
				'two' => q(belgiskej franka),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(belgiski financny frank),
				'few' => q(belgiske financne franki),
				'one' => q(belgiski financny frank),
				'other' => q(belgiskich financnych frankow),
				'two' => q(belgiskej financnej franka),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(bulgarski lew \(1962–1999\)),
				'few' => q(bulgarske lewy \(1962–1999\)),
				'one' => q(bulgarski lew \(1962–1999\)),
				'other' => q(bulgarskich lewow \(1962–1999\)),
				'two' => q(bulgarskej lewa \(1962–1999\)),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(bulgarski lew),
				'few' => q(bulgarske lewy),
				'one' => q(bulgarski lew),
				'other' => q(bulgarskich lewow),
				'two' => q(bulgarskej lewa),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(bahrainski dinar),
				'few' => q(bahrainske dinary),
				'one' => q(bahrainski dinar),
				'other' => q(bahrainskich dinarow),
				'two' => q(bahrainskej dinara),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(burundiski frank),
				'few' => q(burundiske franki),
				'one' => q(burundiski frank),
				'other' => q(burundiskich frankow),
				'two' => q(burundiskej franka),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(bermudaski dolar),
				'few' => q(bermudaske dolary),
				'one' => q(bermudaski dolar),
				'other' => q(bermudaskich dolarow),
				'two' => q(bermudaskej dolara),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(bruneiski dolar),
				'few' => q(bruneiske dolary),
				'one' => q(bruneiski dolar),
				'other' => q(bruneiskich dolarow),
				'two' => q(bruneiskej dolara),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(boliwiski boliviano),
				'few' => q(boliwiske boliviana),
				'one' => q(boliwiski boliviano),
				'other' => q(boliwiskich bolivianow),
				'two' => q(boliwiskej bolivianje),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(boliwiski peso),
				'few' => q(boliwiske peso),
				'one' => q(boliwiski peso),
				'other' => q(boliwiskich peso),
				'two' => q(boliwiskej peso),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(boliwiski mvdol),
				'few' => q(boliwiske mvdole),
				'one' => q(boliwiski mvdol),
				'other' => q(boliwiskich mvdolow),
				'two' => q(boliwiskej mvdola),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(brazilski nowy cruzeiro \(1967–1986\)),
				'few' => q(brazilske nowe cruzeiry \(1967–1986\)),
				'one' => q(brazilski nowy cruzeiro \(1967–1986\)),
				'other' => q(brazilskich nowych cruzeirow \(1967–1986\)),
				'two' => q(brazilskej nowej cruzeira \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(brazilski cruzado \(1986–1989\)),
				'few' => q(brazilske cruzada \(1986–1989\)),
				'one' => q(brazilski cruzado \(1986–1989\)),
				'other' => q(brazilskich cruzadow \(1986–1989\)),
				'two' => q(brazilskej cruzaźe \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(brazilski cruzeiro \(1990–1993\)),
				'few' => q(brazilske cruzeira \(1990–1993\)),
				'one' => q(brazilski cruzeiro \(1990–1993\)),
				'other' => q(brazilskich cruzeirow \(1990–1993\)),
				'two' => q(brazilskej cruzeirje \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(brazilski real),
				'few' => q(brazilske reale),
				'one' => q(brazilski real),
				'other' => q(brazilskich realow),
				'two' => q(brazilskej reala),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(brazilski nowy cruzado \(1989–1990\)),
				'few' => q(brazilske nowe cruzada),
				'one' => q(brazilski nowy cruzado \(1989–1990\)),
				'other' => q(brazilskich nowych cruzadow),
				'two' => q(brazilskej nowej cruzaźe \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(brazilski cruzeiro \(1993–1994\)),
				'few' => q(brazilske cruzeira \(1993–1994\)),
				'one' => q(brazilski cruzeiro \(1993–1994\)),
				'other' => q(brazilskich cruzeirow \(1993–1994\)),
				'two' => q(brazilskej cruzeirje \(1993–1994\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(bahamaski dolar),
				'few' => q(bahamaske dolary),
				'one' => q(bahamaski dolar),
				'other' => q(bahamaskich dolarow),
				'two' => q(bahamaskej dolara),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(bhutański ngultrum),
				'few' => q(bhutańske ngultrumy),
				'one' => q(bhutański ngultrum),
				'other' => q(bhutańskich ngultrumow),
				'two' => q(bhutańskej ngultruma),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(burmaski kyat),
				'few' => q(burmaske kyaty),
				'one' => q(burmaski kyat),
				'other' => q(burmaskich kyatow),
				'two' => q(burmaskej kyata),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(botswaniska pula),
				'few' => q(botswaniske pule),
				'one' => q(botswaniska pula),
				'other' => q(botswaniskich pulow),
				'two' => q(botswaniskej puli),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(běłoruski rubl \(1994–1999\)),
				'few' => q(běłoruske ruble \(1994–1999\)),
				'one' => q(běłoruski rubl \(1994–1999\)),
				'other' => q(běłoruskich rublow \(1994–1999\)),
				'two' => q(běłoruskej rubla \(1994–1999\)),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(běłoruski rubl),
				'few' => q(běłoruske ruble),
				'one' => q(běłoruski rubl),
				'other' => q(běłoruskich rublow),
				'two' => q(běłoruskej rubla),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(běłoruski rubl \(2000–2016\)),
				'few' => q(běłoruske ruble \(2000–2016\)),
				'one' => q(běłoruski rubl \(2000–2016\)),
				'other' => q(běłoruskich rublow \(2000–2016\)),
				'two' => q(běłoruskej rubla \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(belizeski dolar),
				'few' => q(belizeske dolary),
				'one' => q(belizeski dolar),
				'other' => q(belizeskich dolarow),
				'two' => q(belizeskej dolara),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(kanadiski dolar),
				'few' => q(kanadiske dolary),
				'one' => q(kanadiski dolar),
				'other' => q(kanadiskich dolarow),
				'two' => q(kanadiskej dolara),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(kongoski frank),
				'few' => q(kongoske franki),
				'one' => q(kongoski frank),
				'other' => q(kongoskich frankow),
				'two' => q(kongoskej franka),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(šwicarski frank),
				'few' => q(šwicarske franki),
				'one' => q(šwicarski frank),
				'other' => q(šwicarskich frankow),
				'two' => q(šwicarskej franka),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(chilski peso),
				'few' => q(chilske peso),
				'one' => q(chilski peso),
				'other' => q(chilskich peso),
				'two' => q(chilskej peso),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(chinski yuan \(offshore\)),
				'few' => q(chinske yuany \(offshore\)),
				'one' => q(chinski yuan \(offshore\)),
				'other' => q(chinskich yuanow \(offshore\)),
				'two' => q(chinskej yuanaj \(offshore\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(chinski yuan),
				'few' => q(chinske yuany),
				'one' => q(chinski yuan),
				'other' => q(chinskich yuanow),
				'two' => q(chinskej yuana),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(kolumbiski peso),
				'few' => q(kolumbiske peso),
				'one' => q(kolumbiski peso),
				'other' => q(kolumbiskich peso),
				'two' => q(kolumbiskej peso),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(kosta-rikański colón),
				'few' => q(kosta-rikańske colóny),
				'one' => q(kosta-rikański colón),
				'other' => q(kosta-rikańskich colónow),
				'two' => q(kosta-rikańskej colóna),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(kubański konwertibelny peso),
				'few' => q(kubańske konwertibelne peso),
				'one' => q(kubański konwertibelny peso),
				'other' => q(kubańskich konwertibelnych peso),
				'two' => q(kubańskej konwertibelnej peso),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(kubański peso),
				'few' => q(kubańske peso),
				'one' => q(kubański peso),
				'other' => q(kubańskich peso),
				'two' => q(kubańskej peso),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(kapverdski escudo),
				'few' => q(kapverdske escuda),
				'one' => q(kapverdski escudo),
				'other' => q(kapverdskich escudow),
				'two' => q(kapverdskej escuźe),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(česka krona),
				'few' => q(česke krony),
				'one' => q(česka krona),
				'other' => q(českich kronow),
				'two' => q(českej kronje),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(dźibutiski frank),
				'few' => q(dźibutiske franki),
				'one' => q(dźibutiski frank),
				'other' => q(dźibutiskich frankow),
				'two' => q(dźibutiskej franka),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(dańska krona),
				'few' => q(dańske krony),
				'one' => q(dańska krona),
				'other' => q(dańskich kronow),
				'two' => q(dańskej kronje),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(dominikański peso),
				'few' => q(dominikańske peso),
				'one' => q(dominikański peso),
				'other' => q(dominikańskich peso),
				'two' => q(dominikańskej peso),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(algeriski dinar),
				'few' => q(algeriske dinary),
				'one' => q(algeriski dinar),
				'other' => q(algeriskich dinarow),
				'two' => q(algeriskej dinara),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(egyptojski punt),
				'few' => q(egyptojske punty),
				'one' => q(egyptojski punt),
				'other' => q(egyptojskich puntow),
				'two' => q(egyptojskej punta),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(eritrejska nakfa),
				'few' => q(eritrejske nakfy),
				'one' => q(eritrejska nakfa),
				'other' => q(eritrejskich nakfow),
				'two' => q(eritrejskej nakfje),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(etiopiski birr),
				'few' => q(etiopiske birry),
				'one' => q(etiopiski birr),
				'other' => q(etiopiskich birrow),
				'two' => q(etiopiskej birra),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(fidźiski dolar),
				'few' => q(fidźiske dolary),
				'one' => q(fidźiski dolar),
				'other' => q(fidźiskich dolarow),
				'two' => q(fidźiskej dolara),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(falklandski punt),
				'few' => q(falklandske punty),
				'one' => q(falklandski punt),
				'other' => q(falklandskich puntow),
				'two' => q(falklandskej punta),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(britiski punt),
				'few' => q(britiske punty),
				'one' => q(britiski punt),
				'other' => q(britiskich puntow),
				'two' => q(britiskej punta),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(georgiski lari),
				'few' => q(georgiske lari),
				'one' => q(georgiski lari),
				'other' => q(georgiskich lari),
				'two' => q(georgiskej lari),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(ghanaski cedi),
				'few' => q(ghanaske cedi),
				'one' => q(ghanaski cedi),
				'other' => q(ghanaskich cedi),
				'two' => q(ghanaskej cedi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(gibraltiski punt),
				'few' => q(gibraltiske punty),
				'one' => q(gibraltiski punt),
				'other' => q(gibraltiskich puntow),
				'two' => q(gibraltiskej punta),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(gambiski dalasi),
				'few' => q(gambiske dalasi),
				'one' => q(gambiski dalasi),
				'other' => q(gambiskich dalasi),
				'two' => q(gambiskej dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(guineski frank),
				'few' => q(guineske franki),
				'one' => q(guineski frank),
				'other' => q(guineskich frankow),
				'two' => q(guineskej franka),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(guatemalski quetzal),
				'few' => q(guatemalske quetzale),
				'one' => q(guatemalski quetzal),
				'other' => q(guatemalskich quetzalow),
				'two' => q(guatemalskej quetzala),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Guinea-Bissau peso),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(guyański dolar),
				'few' => q(guyańske dolary),
				'one' => q(guyański dolar),
				'other' => q(guyańskich dolarow),
				'two' => q(guyańskej dolara),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(hongkongski dolar),
				'few' => q(hongkongske dolary),
				'one' => q(hongkongski dolar),
				'other' => q(hongkongskich dolarow),
				'two' => q(hongkongskej dolara),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(honduraska lempira),
				'few' => q(honduraske lempiry),
				'one' => q(honduraska lempira),
				'other' => q(honduraskich lempirow),
				'two' => q(honduraskej lempirje),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(chorwatska kuna),
				'few' => q(chorwatske kuny),
				'one' => q(chorwatska kuna),
				'other' => q(chorwatskich kunow),
				'two' => q(chorwatskej kunje),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(haitiska gourda),
				'few' => q(haitiske gourdy),
				'one' => q(haitiska gourda),
				'other' => q(haitiskich gourdow),
				'two' => q(haitiskej gourźe),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(madźarski forint),
				'few' => q(madźarske forinty),
				'one' => q(madźarski forint),
				'other' => q(madźarskich forintow),
				'two' => q(madźarskej forinta),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(indoneska rupija),
				'few' => q(indoneske rupije),
				'one' => q(indoneska rupija),
				'other' => q(indoneskich rupijow),
				'two' => q(indoneskej rupiji),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(israelski nowy šekel),
				'few' => q(israelske nowe šekele),
				'one' => q(israelski nowy šekel),
				'other' => q(israelskich nowych šekelow),
				'two' => q(israelskej nowej šekela),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(indiska rupija),
				'few' => q(indiske rupije),
				'one' => q(indiska rupija),
				'other' => q(indiskich rupijow),
				'two' => q(indiskej rupiji),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(irakski dinar),
				'few' => q(irakske dinary),
				'one' => q(irakski dinar),
				'other' => q(irakskich dinarow),
				'two' => q(irakskej dinara),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(irański rial),
				'few' => q(irańske riale),
				'one' => q(irański rial),
				'other' => q(irańskich rialow),
				'two' => q(irańskej riala),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(islandska krona),
				'few' => q(islandske krony),
				'one' => q(islandska krona),
				'other' => q(islandskich kronow),
				'two' => q(islandskej kronje),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(jamaiski dolar),
				'few' => q(jamaiske dolary),
				'one' => q(jamaiski dolar),
				'other' => q(jamaiskich dolarow),
				'two' => q(jamaiskej dolara),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(jordaniski dinar),
				'few' => q(jordaniske dinary),
				'one' => q(jordaniski dinar),
				'other' => q(jordaniskich dinarow),
				'two' => q(jordaniskej dinara),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(japański yen),
				'few' => q(japańske yeny),
				'one' => q(japański yen),
				'other' => q(japańskich yenow),
				'two' => q(japańskej yena),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(keniaski šiling),
				'few' => q(keniaske šilingi),
				'one' => q(keniaski šiling),
				'other' => q(keniaskich šilingow),
				'two' => q(keniaskej šilinga),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(kirgiski som),
				'few' => q(kirgiske somy),
				'one' => q(kirgiski som),
				'other' => q(kirgiskich somow),
				'two' => q(kirgiskej soma),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(kambodžaski riel),
				'few' => q(kambodžaske riele),
				'one' => q(kambodžaski riel),
				'other' => q(kambodžaskich rielow),
				'two' => q(kambodžaskej riela),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(komorski frank),
				'few' => q(komorske franki),
				'one' => q(komorski frank),
				'other' => q(komorskich frankow),
				'two' => q(komorskej franka),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(pódpołnocnokorejski won),
				'few' => q(pódpołnocnokorejske wony),
				'one' => q(pódpołnocnokorejski won),
				'other' => q(pódpołnocnokorejskich wonow),
				'two' => q(pódpołnocnokorejskej wona),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(pódpołdnjowokorejski won),
				'few' => q(pódpołdnjowokorejske wony),
				'one' => q(pódpołdnjowokorejski won),
				'other' => q(pódpołdnjowokorejskich wonow),
				'two' => q(pódpołdnjowokorejskej wona),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(kuwaitski dinar),
				'few' => q(kuwaitske dinary),
				'one' => q(kuwaitski dinar),
				'other' => q(kuwaitskich dinarow),
				'two' => q(kuwaitskej dinara),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(kajmaniski dolar),
				'few' => q(kajmaniske dolary),
				'one' => q(kajmaniski dolar),
				'other' => q(kajmaniskich dolarow),
				'two' => q(kajmaniskej dolara),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(kazachski tenge),
				'few' => q(kazachske tenge),
				'one' => q(kazachski tenge),
				'other' => q(kazachskich tenge),
				'two' => q(kazachskej tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(laoski kip),
				'few' => q(laoske kipy),
				'one' => q(laoski kip),
				'other' => q(laoskich kipow),
				'two' => q(laoskej kipa),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(libanoński punt),
				'few' => q(libanońske punty),
				'one' => q(libanoński punt),
				'other' => q(libanońskich puntow),
				'two' => q(libanońskej punta),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(sri-lankaska rupija),
				'few' => q(sri-lankaske rupije),
				'one' => q(sri-lankaska rupija),
				'other' => q(sri-lankaskich rupijow),
				'two' => q(sri-lankaskej rupiji),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(liberiski dolar),
				'few' => q(liberiske dolary),
				'one' => q(liberiski dolar),
				'other' => q(liberiskich dolarow),
				'two' => q(liberiskej dolara),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(lesothiski loti),
				'few' => q(lesothiske lotije),
				'one' => q(lesothiski loti),
				'other' => q(lesothiskich lotijow),
				'two' => q(lesothiskej lotija),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(litawski litas),
				'few' => q(litawske litasy),
				'one' => q(litawski litas),
				'other' => q(litawskich litasow),
				'two' => q(litawskej litasa),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(letiski lat),
				'few' => q(letiske laty),
				'one' => q(letiski lat),
				'other' => q(letiskich latow),
				'two' => q(letiskej lata),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(libyski dinar),
				'few' => q(libyske dinary),
				'one' => q(libyski dinar),
				'other' => q(libyskich dinarow),
				'two' => q(libyskej dinara),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(marokkoski dirham),
				'few' => q(marokkoske dirhamy),
				'one' => q(marokkoski dirham),
				'other' => q(marokkoskich dirhamow),
				'two' => q(marokkoskej dirhama),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(moldawiski leu),
				'few' => q(moldawiske leu),
				'one' => q(moldawiski leu),
				'other' => q(moldawiskich leu),
				'two' => q(moldawiskej leu),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(madagaskarski ariary),
				'few' => q(madagaskarske ariary),
				'one' => q(madagaskarski ariary),
				'other' => q(madagaskarskich ariary),
				'two' => q(madagaskarskej ariary),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(makedoński denar),
				'few' => q(makedońske denary),
				'one' => q(makedoński denar),
				'other' => q(makedońskich denarow),
				'two' => q(makedońskej denara),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(myanmarski kyat),
				'few' => q(myanmarske kyaty),
				'one' => q(myanmarski kyat),
				'other' => q(myanmarskich kyatow),
				'two' => q(myanmarskej kyata),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(mongolski tugrik),
				'few' => q(mongolske tugriki),
				'one' => q(mongolski tugrik),
				'other' => q(mongolskich tugrikow),
				'two' => q(mongolskej tugrika),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(macaoska pataca),
				'few' => q(macaoske pataca),
				'one' => q(macaoska pataca),
				'other' => q(macaoskich pataca),
				'two' => q(macaoskej pataca),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(mauretański ouguiya \(1973–2017\)),
				'few' => q(mauretańske ouguiya \(1973–2017\)),
				'one' => q(mauretański ouguiya \(1973–2017\)),
				'other' => q(mauretański ouguiya \(1973–2017\)),
				'two' => q(mauretańskej ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(mauretański ouguiya),
				'few' => q(mauretańske ouguiya),
				'one' => q(mauretański ouguiya),
				'other' => q(mauretański ouguiya),
				'two' => q(mauretańskej ouguiya),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(mauriciska rupija),
				'few' => q(mauriciske rupije),
				'one' => q(mauriciska rupija),
				'other' => q(mauriciskich rupijow),
				'two' => q(mauriciskej rupiji),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(malediwiska rupija),
				'few' => q(malediwiske rupije),
				'one' => q(malediwiska rupija),
				'other' => q(malediwiskich rupijow),
				'two' => q(malediwiskej rupiji),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(malawiski kwacha),
				'few' => q(malawiske kwachy),
				'one' => q(malawiski kwacha),
				'other' => q(malawiskich kwachow),
				'two' => q(malawiskej kwaše),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(mexiski peso),
				'few' => q(mexiske peso),
				'one' => q(mexiski peso),
				'other' => q(mexiskich peso),
				'two' => q(mexiskej peso),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(malajziski ringgit),
				'few' => q(malajziske ringgity),
				'one' => q(malajziski ringgit),
				'other' => q(malajziskich ringgitow),
				'two' => q(malajziskej ringgita),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Mozabicke escudo),
				'few' => q(mozabicke escuda),
				'one' => q(mozabicke escudo),
				'other' => q(mozabickich escud),
				'two' => q(mozabickej escuźe),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(mosambikski metical \(1980–2006\)),
				'few' => q(mosambikske meticale \(1980–2006\)),
				'one' => q(mosambikski metical \(1980–2006\)),
				'other' => q(mosambikskich meticalow \(1980–2006\)),
				'two' => q(mosambikskej meticala \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(mosambikski metical),
				'few' => q(mosambikske meticale),
				'one' => q(mosambikski metical),
				'other' => q(mosambikskich meticalow),
				'two' => q(mosambikskej meticala),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(namibiski dolar),
				'few' => q(namibiske dolary),
				'one' => q(namibiski dolar),
				'other' => q(namibiskich dolarow),
				'two' => q(namibiskej dolara),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(nigeriska naira),
				'few' => q(nigeriske nairy),
				'one' => q(nigeriska naira),
				'other' => q(nigeriskich nairow),
				'two' => q(nigeriskej nairje),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(nikaraguaska cordoba),
				'few' => q(nikaraguaske cordoby),
				'one' => q(nikaraguaska cordoba),
				'other' => q(nikaraguaskich cordobow),
				'two' => q(nikaraguaskej cordobje),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(norwegska krona),
				'few' => q(norwegske krony),
				'one' => q(norwegska krona),
				'other' => q(norwegskich kronow),
				'two' => q(norwegskej kronje),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(nepalska rupija),
				'few' => q(nepalske rupije),
				'one' => q(nepalska rupija),
				'other' => q(nepalskich rupijow),
				'two' => q(nepalskej rupiji),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(nowoseelandski dolar),
				'few' => q(nowoseelandske dolary),
				'one' => q(nowoseelandski dolar),
				'other' => q(nowoseelandskich dolarow),
				'two' => q(nowoseelandskej dolara),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(omański rial),
				'few' => q(omańske riale),
				'one' => q(omański rial),
				'other' => q(omańskich rialow),
				'two' => q(omańskej riala),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(panamaski balboa),
				'few' => q(panamaske balboa),
				'one' => q(panamaski balboa),
				'other' => q(panamaskich balboa),
				'two' => q(panamaskej balboa),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(peruski sol),
				'few' => q(peruske sole),
				'one' => q(peruski sol),
				'other' => q(peruskich solow),
				'two' => q(peruskej sola),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(papua-neuguinejska kina),
				'few' => q(papua-neuguinejske kiny),
				'one' => q(papua-neuguinejska kina),
				'other' => q(papua-neuguinejskich kinow),
				'two' => q(papua-neuguinejskej kinje),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(filipinski peso),
				'few' => q(filipinske peso),
				'one' => q(filipinski peso),
				'other' => q(filipinskich peso),
				'two' => q(filipinskej peso),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(pakistańska rupija),
				'few' => q(pakistańske rupije),
				'one' => q(pakistańska rupija),
				'other' => q(pakistańskich rupijow),
				'two' => q(pakistańskej rupiji),
			},
		},
		'PLN' => {
			symbol => 'zł',
			display_name => {
				'currency' => q(pólski złoty),
				'few' => q(pólske złote),
				'one' => q(pólski złoty),
				'other' => q(pólskich złotych),
				'two' => q(pólskej złotej),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(paraguayski guarani),
				'few' => q(paraguayske guaranije),
				'one' => q(paraguayski guarani),
				'other' => q(paraguayskich guaranijow),
				'two' => q(paraguayskej guaranija),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(katarski rial),
				'few' => q(katarske riale),
				'one' => q(katarski rial),
				'other' => q(katarskich rialow),
				'two' => q(katarskej riala),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(rumuński leu),
				'few' => q(rumuńske leu),
				'one' => q(rumuński leu),
				'other' => q(rumuńskich leu),
				'two' => q(rumuńskej leu),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(serbiski dinar),
				'few' => q(serbiske dinary),
				'one' => q(serbiski dinar),
				'other' => q(serbiskich dinarow),
				'two' => q(serbiskej dinara),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(ruski rubl),
				'few' => q(ruske ruble),
				'one' => q(ruski rubl),
				'other' => q(ruskich rublow),
				'two' => q(ruskej rubla),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(ruandiski frank),
				'few' => q(ruandiske franki),
				'one' => q(ruandiski frank),
				'other' => q(ruandiskich frankow),
				'two' => q(ruandiskej franka),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(saudi-arabiski rial),
				'few' => q(saudi-arabiske riale),
				'one' => q(saudi-arabiski rial),
				'other' => q(saudi-arabiskich rialow),
				'two' => q(saudi-arabiskej riala),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(salomoński dolar),
				'few' => q(salomońske dolary),
				'one' => q(salomoński dolar),
				'other' => q(salomońskich dolarow),
				'two' => q(salomońskej dolara),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(seychelska rupija),
				'few' => q(seychelske rupije),
				'one' => q(seychelska rupija),
				'other' => q(seychelskich rupijow),
				'two' => q(seychelskej rupiji),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(sudański punt),
				'few' => q(sudańske punty),
				'one' => q(sudański punt),
				'other' => q(sudańskich puntow),
				'two' => q(sudańskej punta),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(šwedska krona),
				'few' => q(šwedske krony),
				'one' => q(šwedska krona),
				'other' => q(šwedskich kronow),
				'two' => q(šwedskej kronje),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(singapurski dolar),
				'few' => q(singapurske dolary),
				'one' => q(singapurski dolar),
				'other' => q(singapurskich dolarow),
				'two' => q(singapurskej dolara),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(St. Helena punt),
				'few' => q(St. Helena punty),
				'one' => q(St. Helena punt),
				'other' => q(St. Helena puntow),
				'two' => q(St. Helena punta),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(sierra-leoneski leone),
				'few' => q(sierra-leoneske leone),
				'one' => q(sierra-leoneski leone),
				'other' => q(sierra-leoneskich leone),
				'two' => q(sierra-leoneskej leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(sierra-leoneski leone \(1964—2022\)),
				'few' => q(sierra-leoneske leone \(1964—2022\)),
				'one' => q(sierra-leoneski leone \(1964—2022\)),
				'other' => q(sierra-leoneskich leone \(1964—2022\)),
				'two' => q(sierra-leoneskej leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(somaliski šiling),
				'few' => q(somaliske šilingi),
				'one' => q(somaliski šiling),
				'other' => q(somaliskich šilingow),
				'two' => q(somaliskej šilinga),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(surinamski dolar),
				'few' => q(surinamske dolary),
				'one' => q(surinamski dolar),
				'other' => q(surinamskich dolarow),
				'two' => q(surinamskej dolara),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(pódpołdnjowosudański punt),
				'few' => q(pódpołdnjowosudańske punty),
				'one' => q(pódpołdnjowosudański punt),
				'other' => q(pódpołdnjowosudańskich puntow),
				'two' => q(pódpołdnjowosudańskej punta),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(são-tomeska dobra \(1977–2017\)),
				'few' => q(são-tomeske dobry \(1977–2017\)),
				'one' => q(são-tomeska dobra \(1977–2017\)),
				'other' => q(são-tomeskich dobrow \(1977–2017\)),
				'two' => q(são-tomeskej dobrje \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(são-tomeska dobra),
				'few' => q(são-tomeske dobry),
				'one' => q(são-tomeska dobra),
				'other' => q(são-tomeskich dobrow),
				'two' => q(são-tomeskej dobrje),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(el-salvadorski colón),
				'few' => q(el-salvadorske colóny),
				'one' => q(el-salvadorski colón),
				'other' => q(el-salvadorskich colónow),
				'two' => q(el-salvadorskej colóna),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(syriski punt),
				'few' => q(syriske punty),
				'one' => q(syriski punt),
				'other' => q(syriskich puntow),
				'two' => q(syriskej punta),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(swasiski lilangeni),
				'few' => q(swasiske lilangenije),
				'one' => q(swasiski lilangeni),
				'other' => q(swasiskich lilangenijow),
				'two' => q(swasiskej lilangenija),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(thaiski baht),
				'few' => q(thaiske bahty),
				'one' => q(thaiski baht),
				'other' => q(thaiskich bahtow),
				'two' => q(thaiskej bahta),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(tadźikiski somoni),
				'few' => q(tadźikiske somonije),
				'one' => q(tadźikiski somoni),
				'other' => q(tadźikiskich somonijow),
				'two' => q(tadźikiskej somonija),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(turkmeniski manat),
				'few' => q(turkmeniske manaty),
				'one' => q(turkmeniski manat),
				'other' => q(turkmeniskich manatow),
				'two' => q(turkmeniskej manata),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(tuneziski dinar),
				'few' => q(tuneziske dinary),
				'one' => q(tuneziski dinar),
				'other' => q(tuneziskich dinarow),
				'two' => q(tuneziskej dinara),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(tongaski paʻanga),
				'few' => q(tongaske pa’anga),
				'one' => q(tongaski pa’anga),
				'other' => q(tongaskich pa’anga),
				'two' => q(tongaskej pa’anga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(turkojska lira),
				'few' => q(turkojske liry),
				'one' => q(turkojska lira),
				'other' => q(turkojskich lirow),
				'two' => q(turkojskej lirje),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(trinidad-tobagoski dolar),
				'few' => q(trinidad-tobagoske dolary),
				'one' => q(trinidad-tobagoski dolar),
				'other' => q(trinidad-tobagoskich dolarow),
				'two' => q(trinidad-tobagoskej dolara),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(nowy taiwański dolar),
				'few' => q(nowe taiwańske dolary),
				'one' => q(nowy taiwański dolar),
				'other' => q(nowych taiwańskich dolarow),
				'two' => q(nowej taiwańskej dolara),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(tansaniski šiling),
				'few' => q(tansaniske šilingi),
				'one' => q(tansaniski šiling),
				'other' => q(tansaniskich šilingow),
				'two' => q(tansaniskej šilinga),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(ukrainska griwna),
				'few' => q(ukrainske griwny),
				'one' => q(ukrainska griwna),
				'other' => q(ukrainskich griwnow),
				'two' => q(ukrainskej griwnje),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(ugandaski šiling),
				'few' => q(ugandaske šilingi),
				'one' => q(ugandaski šiling),
				'other' => q(ugandaskich šilingow),
				'two' => q(ugandaskej šilinga),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(ameriski dolar),
				'few' => q(ameriske dolary),
				'one' => q(ameriski dolar),
				'other' => q(ameriskich dolarow),
				'two' => q(ameriskej dolara),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(uruguayski peso),
				'few' => q(uruguayske peso),
				'one' => q(uruguayski peso),
				'other' => q(uruguayskich peso),
				'two' => q(uruguayskej peso),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(usbekiski sum),
				'few' => q(usbekiske sumy),
				'one' => q(usbekiski sum),
				'other' => q(usbekiskich sumow),
				'two' => q(usbekiskej suma),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(venezuelski bolívar \(2008–2018\)),
				'few' => q(venezuelske bolívary \(2008–2018\)),
				'one' => q(venezuelski bolívar \(2008–2018\)),
				'other' => q(venezuelskich bolívarow \(2008–2018\)),
				'two' => q(venezuelskej bolívara \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(venezuelski bolívar),
				'few' => q(venezuelske bolívary),
				'one' => q(venezuelski bolívar),
				'other' => q(venezuelskich bolívarow),
				'two' => q(venezuelskej bolívara),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(vietnamski dong),
				'few' => q(vietnamske dongi),
				'one' => q(vietnamski dong),
				'other' => q(vietnamskich dongow),
				'two' => q(vietnamskej donga),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vanuatski vatu),
				'few' => q(vanuatske vatu),
				'one' => q(vanuatski vatu),
				'other' => q(vanuatskich vatu),
				'two' => q(vanuatskej vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(samoaska tala),
				'few' => q(samoaske tale),
				'one' => q(samoaski tala),
				'other' => q(samoaskich talow),
				'two' => q(samoaskej tali),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(CFA-frank \(BEAC\)),
				'few' => q(CFA-franki \(BEAC\)),
				'one' => q(CFA-frank \(BEAC\)),
				'other' => q(CFA-frankow \(BEAC\)),
				'two' => q(CFA-franka \(BEAC\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(pódzajtšnokaribiski dolar),
				'few' => q(pódzajtšnokaribiske dolary),
				'one' => q(pódzajtšnokaribiski dolar),
				'other' => q(pódzajtšnokaribiskich dolarow),
				'two' => q(pódzajtšnokaribiskej dolara),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(CFA-frank \(BCEAO\)),
				'few' => q(CFA-franki \(BCEAO\)),
				'one' => q(CFA-frank \(BCEAO\)),
				'other' => q(CFA-frankow \(BCEAO\)),
				'two' => q(CFA-franka \(BCEAO\)),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP-frank),
				'few' => q(CFP-franki),
				'one' => q(CFP-frank),
				'other' => q(CFP-frankow),
				'two' => q(CFP-franka),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(njeznate pjenjeze),
				'few' => q(njeznate pjenjeze),
				'one' => q(njeznate pjenjeze),
				'other' => q(njeznatych pjenjez),
				'two' => q(njeznate pjenjeze),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(jemeński rial),
				'few' => q(jemeńske riale),
				'one' => q(jemeński rial),
				'other' => q(jemeńskich rialow),
				'two' => q(jemeńskej riala),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(pódpołdnjowoafriski rand),
				'few' => q(pódpołdnjowoafriske randy),
				'one' => q(pódpołdnjowoafriski rand),
				'other' => q(pódpołdnjowoafriskich randow),
				'two' => q(pódpołdnjowoafriskej randa),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(sambiska kwacha),
				'few' => q(sambiske kwachy),
				'one' => q(sambiska kwacha),
				'other' => q(sambiskich kwachow),
				'two' => q(sambiskej kwaše),
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
							'jan.',
							'feb.',
							'měr.',
							'apr.',
							'maj.',
							'jun.',
							'jul.',
							'awg.',
							'sep.',
							'okt.',
							'now.',
							'dec.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'januara',
							'februara',
							'měrca',
							'apryla',
							'maja',
							'junija',
							'julija',
							'awgusta',
							'septembra',
							'oktobra',
							'nowembra',
							'decembra'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'jan',
							'feb',
							'měr',
							'apr',
							'maj',
							'jun',
							'jul',
							'awg',
							'sep',
							'okt',
							'now',
							'dec'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'j',
							'f',
							'm',
							'a',
							'm',
							'j',
							'j',
							'a',
							's',
							'o',
							'n',
							'd'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'januar',
							'februar',
							'měrc',
							'apryl',
							'maj',
							'junij',
							'julij',
							'awgust',
							'september',
							'oktober',
							'nowember',
							'december'
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
						mon => 'pón',
						tue => 'wał',
						wed => 'srj',
						thu => 'stw',
						fri => 'pět',
						sat => 'sob',
						sun => 'nje'
					},
					short => {
						mon => 'pó',
						tue => 'wa',
						wed => 'sr',
						thu => 'st',
						fri => 'pě',
						sat => 'so',
						sun => 'nj'
					},
					wide => {
						mon => 'pónjeźele',
						tue => 'wałtora',
						wed => 'srjoda',
						thu => 'stwórtk',
						fri => 'pětk',
						sat => 'sobota',
						sun => 'njeźela'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'p',
						tue => 'w',
						wed => 's',
						thu => 's',
						fri => 'p',
						sat => 's',
						sun => 'n'
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
					abbreviated => {0 => 'kw1',
						1 => 'kw2',
						2 => 'kw3',
						3 => 'kw4'
					},
					wide => {0 => '1. kwartal',
						1 => '2. kwartal',
						2 => '3. kwartal',
						3 => '4. kwartal'
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
					'am' => q{dop.},
					'pm' => q{wótp.},
				},
				'wide' => {
					'am' => q{dopołdnja},
					'pm' => q{wótpołdnja},
				},
			},
			'stand-alone' => {
				'wide' => {
					'am' => q{dopołdnja},
					'pm' => q{wótpołdnja},
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
				'0' => 'pś.Chr.n.',
				'1' => 'pó Chr.n.'
			},
			wide => {
				'0' => 'pśed Kristusowym naroźenim',
				'1' => 'pó Kristusowem naroźenju'
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
			'full' => q{EEEE, d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d.M.y G},
			'short' => q{d.M.yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d. MMMM y},
			'long' => q{d. MMMM y},
			'medium' => q{d.M.y},
			'short' => q{d.M.yy},
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
			'full' => q{H:mm:ss zzzz},
			'long' => q{H:mm:ss z},
			'medium' => q{H:mm:ss},
			'short' => q{H:mm},
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
		'generic' => {
			Bh => q{h 'hodź'. B},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d.},
			Ehm => q{E h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			GyMd => q{d.M.y GGGGG},
			H => q{HH 'hodź'.},
			MEd => q{E, d.M.},
			MMMEd => q{E, d. MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			h => q{h 'hodź'. a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M.y GGGGG},
			yyyyMEd => q{E, d.M.y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d. MMM y G},
			yyyyMMMM => q{LLLL y G},
			yyyyMMMd => q{d. MMM y G},
			yyyyMd => q{d.M.y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			EHm => q{E, 'zeg'. H:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d.},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			GyMd => q{d.M.y GGGGG},
			H => q{'zeg'. H},
			Hm => q{'zeg'. H:mm},
			Hms => q{H:mm:ss},
			Hmsv => q{H:mm:ss v},
			Hmv => q{H:mm v},
			MEd => q{E, d.M.},
			MMMEd => q{E, d. MMM},
			MMMMW => q{W. 'tyźeń' MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			d => q{d.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			yM => q{M.y},
			yMEd => q{E, d.M.y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d. MMM y},
			yMMMM => q{LLLL y},
			yMMMd => q{d. MMM y},
			yMd => q{d.M.y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{w. 'tyźeń' 'lěta' Y},
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
				B => q{h 'hodź'. B – h 'hodź'. B},
			},
			Bhm => {
				B => q{h:mm 'hodź'. B – h:mm 'hodź'. B},
			},
			Gy => {
				G => q{G y – G y},
			},
			GyM => {
				G => q{GGGGG y-MM – GGGGG y-MM},
				M => q{GGGGG y-MM – y-MM},
				y => q{GGGGG y-MM – y-MM},
			},
			GyMEd => {
				G => q{GGGGG y-MM-dd, E – GGGGG y-MM-dd, E},
				M => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				d => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				y => q{GGGGG y-MM-dd, E – y-MM-dd, E},
			},
			GyMMM => {
				G => q{G y MMM – G y MMM},
				y => q{G y MMM – y MMM},
			},
			GyMMMEd => {
				G => q{G y MMM d, E – G y MMM d, E},
				M => q{G y MMM d, E – MMM d, E},
				d => q{G y MMM d, E – MMM d, E},
				y => q{G y MMM d, E – y MMM d, E},
			},
			GyMMMd => {
				G => q{G y MMM d – G y MMM d},
				M => q{G y MMM d – MMM d},
				y => q{G y MMM d – y MMM d},
			},
			GyMd => {
				G => q{GGGGG y-MM-dd – GGGGG y-MM-dd},
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
			M => {
				M => q{M. – M.},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d.M. – E, d.M.},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d. – d. MMM},
			},
			Md => {
				M => q{d.M. – d.M.},
				d => q{d.M. – d.M.},
			},
			d => {
				d => q{d. – d.},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M.y – M.y G},
				y => q{M.y – M.y G},
			},
			yMEd => {
				M => q{E, d.M.y – E, d.M.y G},
				d => q{E, d.M.y – E, d.M.y G},
				y => q{E, d.M.y – E, d.M.y G},
			},
			yMMM => {
				M => q{LLL – LLL y G},
				y => q{LLL y – LLL y G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			yMMMM => {
				M => q{LLLL – LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y G},
				d => q{d. – d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			yMd => {
				M => q{d.M.y – d.M.y G},
				d => q{d.M.y – d.M.y G},
				y => q{d.M.y – d.M.y G},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h 'hodź'. B – h 'hodź'. B},
			},
			Bhm => {
				B => q{h:mm 'hodź'. B – h:mm 'hodź'. B},
			},
			Gy => {
				G => q{G y – G y},
			},
			GyM => {
				G => q{MM/y G – MM/y G},
				M => q{MM/y – MM/y G},
				y => q{MM.y – MM.y G},
			},
			GyMEd => {
				G => q{E, dd.MM.y G – E, dd.MM.y G},
				M => q{E, dd.MM. – E, dd.MM.y G},
				d => q{E, dd.MM.y – E, dd.MM.y G},
				y => q{E, dd.MM.y – E, dd.MM.y G},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d. MMM y G – E, d. MMM y G},
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			GyMMMd => {
				G => q{d. MMM y G – d. MMM y G},
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			GyMd => {
				G => q{dd.MM.y G – dd.MM.y G},
				M => q{dd.MM. – dd.MM.y G},
				d => q{dd.–dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
			},
			H => {
				H => q{'zeg'. H–H},
			},
			Hm => {
				H => q{'zeg'. H:mm – H:mm},
				m => q{'zeg'. H:mm – H:mm},
			},
			Hmv => {
				H => q{'zeg'. H:mm – H:mm v},
				m => q{'zeg'. H:mm – H:mm v},
			},
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{M. – M.},
			},
			MEd => {
				M => q{E, d.M. – E, d.M.},
				d => q{E, d.M. – E, d.M.},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d. – d. MMM},
			},
			Md => {
				M => q{d.M. – d.M.},
				d => q{d.M. – d.M.},
			},
			d => {
				d => q{d. – d.},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			yM => {
				M => q{M.y – M.y},
				y => q{M.y – M.y},
			},
			yMEd => {
				M => q{E, d.M.y – E, d.M.y},
				d => q{E, d.M.y – E, d.M.y},
				y => q{E, d.M.y – E, d.M.y},
			},
			yMMM => {
				M => q{LLL – LLL y},
				y => q{LLL y – LLL y},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y},
				d => q{E, d. – E, d. MMM y},
				y => q{E, d. MMM y – E, d. MMM y},
			},
			yMMMM => {
				M => q{LLLL – LLLL y},
				y => q{LLLL y – LLLL y},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y},
				d => q{d. – d. MMM y},
				y => q{d. MMM y – d. MMM y},
			},
			yMd => {
				M => q{d.M.y – d.M.y},
				d => q{d.M.y – d.M.y},
				y => q{d.M.y – d.M.y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(Casowe pasmo {0}),
		regionFormat => q({0} lěśojski cas),
		regionFormat => q({0} zymski cas),
		'Afghanistan' => {
			long => {
				'standard' => q#Afghaniski cas#,
			},
		},
		'Africa/Accra' => {
			exemplarCity => q#Akkra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Algier#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Daressalam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Džibuti#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Aaiún#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartum#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadišu#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Wagadugu#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto Novo#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripolis#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Srjejźoafriski cas#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Pódzajtšnoafriski cas#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Pódpołdnjowoafriski cas#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Pódwjacornoafriski lěśojski cas#,
				'generic' => q#Pódwjacornoafriski cas#,
				'standard' => q#Pódwjacornoafriski standardny cas#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaskojski lěśojski cas#,
				'generic' => q#Alaskojski cas#,
				'standard' => q#Alaskojski standardny cas#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amaconaski lěśojski cas#,
				'generic' => q#Amaconaski cas#,
				'standard' => q#Amaconaski standardny cas#,
			},
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kaimaniske kupy#,
		},
		'America/Havana' => {
			exemplarCity => q#Havanna#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaika#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexiko-město#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port-of-Spain#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St.Barthélemy#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Pódpołnocnoameriski centralny lěśojski cas#,
				'generic' => q#Pódpołnocnoameriski centralny cas#,
				'standard' => q#Pódpołnocnoameriski centralny standardny cas#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Pódpołnocnoameriski pódzajtšny lěśojski cas#,
				'generic' => q#Pódpołnocnoameriski pódzajtšny cas#,
				'standard' => q#Pódpołnocnoameriski pódzajtšny standardny cas#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Pódpołnocnoameriski górski lěśojski cas#,
				'generic' => q#Pódpołnocnoameriski górski cas#,
				'standard' => q#Pódpołnocnoameriski górski standardny cas#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Pódpołnocnoameriski pacifiski lěśojski cas#,
				'generic' => q#Pódpołnocnoameriski pacifiski cas#,
				'standard' => q#Pódpołnocnoameriski pacifiski standardny cas#,
			},
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont D’Urville#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Wostok#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Apiaski lěśojski cas#,
				'generic' => q#Apiaski cas#,
				'standard' => q#Apiaski standardny cas#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabiski lěśojski cas#,
				'generic' => q#Arabiski cas#,
				'standard' => q#Arabiski standardny cas#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentinski lěśojski cas#,
				'generic' => q#Argentinski cas#,
				'standard' => q#Argentinski standardny cas#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Pódwjacornoargentinski lěśojski cas#,
				'generic' => q#Pódwjacornoargentinski cas#,
				'standard' => q#Pódwjacornoargentinski standardny cas#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armeński lěśojski cas#,
				'generic' => q#Armeński cas#,
				'standard' => q#Armeński standardny cas#,
			},
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Biškek#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkutta#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaskus#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dušanbe#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Port Numbay#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamčatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karači#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosia#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Nowokuznjetsk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Nowosibirsk#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pjöngjang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangun#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho-Chi-Minh-město#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sachalin#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipeh#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taškent#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Wladiwostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Jerewan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantiski lěśojski cas#,
				'generic' => q#Atlantiski cas#,
				'standard' => q#Atlantiski standardny cas#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Acory#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermudy#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanary#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kap Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Färöje#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Pódpołdnjowa Georgiska#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Srjejźoawstralski lěśojski cas#,
				'generic' => q#Srjejźoawstralski cas#,
				'standard' => q#Srjejźoawstralski standardny cas#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Srjejźopódwjacorny awstralski lěśojski cas#,
				'generic' => q#Srjejźopódwjacorny awstralski cas#,
				'standard' => q#Srjejźopódwjacorny awstralski standardny cas#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Pódzajtšnoawstralski lěśojski cas#,
				'generic' => q#Pódzajtšnoawstralski cas#,
				'standard' => q#Pódzajtšnoawstralski standardny cas#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Pódwjacornoawstralski lěśojski cas#,
				'generic' => q#Pódwjacornoawstralski cas#,
				'standard' => q#Pódwjacornoawstralski standardny cas#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Azerbajdžaniski lěśojski cas#,
				'generic' => q#Azerbajdžaniski cas#,
				'standard' => q#Azerbajdžaniski standardny cas#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Acorski lěśojski cas#,
				'generic' => q#Acorski cas#,
				'standard' => q#Acorski standardny cas#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladešski lěśojski cas#,
				'generic' => q#Bangladešski cas#,
				'standard' => q#Bangladešski standardny cas#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Bhutański cas#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Boliwiski cas#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasília lěśojski cas#,
				'generic' => q#Brasília cas#,
				'standard' => q#Brasília standardny cas#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Bruneiski cas#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kapverdski lěśojski cas#,
				'generic' => q#Kapverdski cas#,
				'standard' => q#Kapverdski standardny cas#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorrski cas#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chathamski lěśojski cas#,
				'generic' => q#Chathamski cas#,
				'standard' => q#Chathamski standardny cas#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Chilski lěśojski cas#,
				'generic' => q#Chilski cas#,
				'standard' => q#Chilski standardny cas#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Chinski lěśojski cas#,
				'generic' => q#Chinski cas#,
				'standard' => q#Chinski standardny cas#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#cas Gódownych kupow#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#cas Kokosowych kupow#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolumbiski lěśojski cas#,
				'generic' => q#Kolumbiski cas#,
				'standard' => q#Kolumbiski standardny cas#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#lěśojski cas Cookowych kupow#,
				'generic' => q#cas Cookowych kupow#,
				'standard' => q#Standardny cas Cookowych kupow#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kubański lěśojski cas#,
				'generic' => q#Kubański cas#,
				'standard' => q#Kubański standardny cas#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davis cas#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#DumontDUrville cas#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Pódzajtšnotimorski cas#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#lěśojski cas Jatšowneje kupy#,
				'generic' => q#cas Jatšowneje kupy#,
				'standard' => q#standardny cas Jatšowneje kupy#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ekuadorski cas#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#koordiněrowany swětowy cas#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Njeznate#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athen#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Běłogrod#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brüssel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kišinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Iriski lěśojski cas#,
			},
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiew#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Britiski lěśojski cas#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburg#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskwa#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rom#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wien#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Wilna#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Wolgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Waršawa#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Srjejźnoeuropejski lěśojski cas#,
				'generic' => q#Srjejźnoeuropejski cas#,
				'standard' => q#Srjejźnoeuropejski standardny cas#,
			},
			short => {
				'daylight' => q#MESZ#,
				'generic' => q#MEZ#,
				'standard' => q#MEZ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Pódzajtšnoeuropejski lěśojski cas#,
				'generic' => q#Pódzajtšnoeuropejski cas#,
				'standard' => q#Pódzajtšnoeuropejski standardny cas#,
			},
			short => {
				'daylight' => q#OESZ#,
				'generic' => q#OEZ#,
				'standard' => q#OEZ#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Kaliningradski cas#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Pódwjacornoeuropejski lěśojski cas#,
				'generic' => q#Pódwjacornoeuropejski cas#,
				'standard' => q#Pódwjacornoeuropejski standardny cas#,
			},
			short => {
				'daylight' => q#WESZ#,
				'generic' => q#WEZ#,
				'standard' => q#WEZ#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falklandski lěśojski cas#,
				'generic' => q#Falklandski cas#,
				'standard' => q#Falklandski standardny cas#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fidźiski lěśojski cas#,
				'generic' => q#Fidźiski cas#,
				'standard' => q#Fidźiski standardny cas#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Francojskoguyański cas#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#cas francojskego pódpołdnjowego a antarktiskeho teritoriuma#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwichski cas#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagoski cas#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambierski cas#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Georgiski lěśojski cas#,
				'generic' => q#Georgiski cas#,
				'standard' => q#Georgiski standardny cas#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#cas Gilbertowych kupow#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Pódzajtšnogrönlandski lěśojski cas#,
				'generic' => q#Pódzajtšnogrönlandski cas#,
				'standard' => q#Pódzajtšnogrönlandski standardny cas#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Pódwjacornogrönlandski lěśojski cas#,
				'generic' => q#Pódwjacornogrönlandski cas#,
				'standard' => q#Pódwjacornogrönlandski standardny cas#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#cas Persiskego golfa#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyański cas#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaiisko-aleutski lěśojski cas#,
				'generic' => q#Hawaiisko-aleutski cas#,
				'standard' => q#Hawaiisko-aleutski standardny cas#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hongkongski lěśojski cas#,
				'generic' => q#Hongkongski cas#,
				'standard' => q#Hongkongski standardny cas#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Chowdski lěśojski cas#,
				'generic' => q#Chowdski cas#,
				'standard' => q#Chowdski standardny cas#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Indiski cas#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Gódowne kupy#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komory#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Malediwy#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indiskooceaniski cas#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indochinski cas#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Srjejźoindoneski cas#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Pódzajtšnoindoneski#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Pódwjacornoindoneski cas#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Irański lěśojski cas#,
				'generic' => q#Irański cas#,
				'standard' => q#Irański standardny cas#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutski lěśojski cas#,
				'generic' => q#Irkutski cas#,
				'standard' => q#Irkutski standardny cas#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israelski lěśojski cas#,
				'generic' => q#Israelski cas#,
				'standard' => q#Israelski standardny cas#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japański lěśojski cas#,
				'generic' => q#Japański cas#,
				'standard' => q#Japański standardny cas#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#kazachiski cas#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Pódzajtšnokazachski cas#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Pódwjacornokazachski cas#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Korejski lěśojski cas#,
				'generic' => q#Korejski cas#,
				'standard' => q#Korejski standardny cas#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosraeski cas#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarski lěśojski cas#,
				'generic' => q#Krasnojarski cas#,
				'standard' => q#Krasnojarski standardny cas#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgiski cas#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#cas Linijowych kupow#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#lěśojski cas kupy Lord-Howe#,
				'generic' => q#cas kupy Lord-Howe#,
				'standard' => q#Standardny cas kupy Lord-Howe#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadański lěśojski cas#,
				'generic' => q#Magadański cas#,
				'standard' => q#Magadański standardny cas#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malajziski cas#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Malediwski cas#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Marqueski cas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#cas Marshallowych kupow#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauriciski lěśojski cas#,
				'generic' => q#Mauriciski cas#,
				'standard' => q#Mauriciski standardny cas#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawson cas#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Mexiski pacifiski lěśojski cas#,
				'generic' => q#Mexiski pacifiski cas#,
				'standard' => q#Mexiski pacifiski standardny cas#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulan-Batorski lěśojski cas#,
				'generic' => q#Ulan-Batorski cas#,
				'standard' => q#Ulan-Batorski standardny cas#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskowski lěśojski cas#,
				'generic' => q#Moskowski cas#,
				'standard' => q#Moskowski standardny cas#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Myanmarski cas#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauruski cas#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepalski cas#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Nowokaledoniski lěśojski cas#,
				'generic' => q#Nowokaledoniski cas#,
				'standard' => q#Nowokaledoniski standardny cas#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Nowoseelandski lěśojski cas#,
				'generic' => q#Nowoseelandski cas#,
				'standard' => q#Nowoseelandski standardny cas#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Nowofundlandski lěśojski cas#,
				'generic' => q#Nowofundlandski cas#,
				'standard' => q#Nowofundlandski standardny cas#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niueski cas#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#lěśojski cas kupy Norfolk#,
				'generic' => q#cas kupy Norfolk#,
				'standard' => q#standardny cas kupy Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#lěśojski cas Fernando de Noronha#,
				'generic' => q#cas Fernando de Noronha#,
				'standard' => q#standardny cas Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Nowosibirski lěśojski cas#,
				'generic' => q#Nowosibirski cas#,
				'standard' => q#Nowosibirski standardny cas#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omski lěśojski cas#,
				'generic' => q#Omski cas#,
				'standard' => q#Omski standardny cas#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Jatšowne kupy#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidži#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistański lěśojski cas#,
				'generic' => q#Pakistański cas#,
				'standard' => q#Pakistański standardny cas#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palauski cas#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua-Nowoginejski cas#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguayski lěśojski cas#,
				'generic' => q#Paraguayski cas#,
				'standard' => q#Paraguayski standardny cas#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peruski lěśojski cas#,
				'generic' => q#Peruski cas#,
				'standard' => q#Peruski standardny cas#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filipinski lěśojski cas#,
				'generic' => q#Filipinski cas#,
				'standard' => q#Filipinski standardny cas#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#cas Phoenixowych kupow#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#St.-Pierre-a-Miqueloński lěśojski cas#,
				'generic' => q#St.-Pierre-a-Miqueloński cas#,
				'standard' => q#St.-Pierre-a-Miqueloński standardny cas#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#cas Pitcairnowych kupow#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponapski cas#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Pjöngjangski cas#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Reunionski cas#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#cas Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sachalinski lěśojski cas#,
				'generic' => q#Sachalinski cas#,
				'standard' => q#Sachalinski standardny cas#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoaski lěśojski cas#,
				'generic' => q#Samoaski cas#,
				'standard' => q#Samoaski standardny cas#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seychelski cas#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapurski cas#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Salomoński cas#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Pódpołdnjowogeorgiski cas#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinamski cas#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowa cas#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahitiski cas#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Tchajpejski lěśojski cas#,
				'generic' => q#Tchajpejski cas#,
				'standard' => q#Tchajpejski standardny cas#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadźikiski cas#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelauski cas#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tongaski lěśojski cas#,
				'generic' => q#Tongaski cas#,
				'standard' => q#Tongaski standardny cas#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuukski cas#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmeniski lěśojski cas#,
				'generic' => q#Turkmeniski cas#,
				'standard' => q#Turkmeniski standardny cas#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalski cas#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguayski lěśojski cas#,
				'generic' => q#Uruguayski cas#,
				'standard' => q#Uruguayski standardny cas#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Uzbekiski lěśojski cas#,
				'generic' => q#Uzbekiski cas#,
				'standard' => q#Uzbekiski standardny cas#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatski lěśojski cas#,
				'generic' => q#Vanuatski cas#,
				'standard' => q#Vanuatski standardny cas#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venezuelski cas#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Wladiwostokski lěśojski cas#,
				'generic' => q#Wladiwostokski cas#,
				'standard' => q#Wladiwostokski standardny cas#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Wolgogradski lěśojski cas#,
				'generic' => q#Wolgogradski cas#,
				'standard' => q#Wolgogradski standardny cas#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#cas Wostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#cas kupy Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#cas kupow Wallis a Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakutski lěśojski cas#,
				'generic' => q#Jakutski cas#,
				'standard' => q#Jakutski standardny cas#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinburgski lěśojski cas#,
				'generic' => q#Jekaterinburgski cas#,
				'standard' => q#Jekaterinburgski standardny cas#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Yukonowy cas#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
