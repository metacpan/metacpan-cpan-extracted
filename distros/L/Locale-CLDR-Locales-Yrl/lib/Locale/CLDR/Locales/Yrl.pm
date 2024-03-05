=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Yrl - Package for language Nheengatu

=cut

package Locale::CLDR::Locales::Yrl;
# This file auto generated from Data\common\main\yrl.xml
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
				'aa' => 'afari',
 				'ab' => 'abikasiyu',
 				'ace' => 'axemi',
 				'ach' => 'akuri',
 				'ada' => 'adãgime',
 				'ady' => 'adige',
 				'ae' => 'awesitiku',
 				'af' => 'afiriķãner',
 				'afh' => 'afirihiri',
 				'agq' => 'agẽ',
 				'ain' => 'ainú',
 				'ak' => 'akã',
 				'akk' => 'akadiãnu',
 				'ale' => 'areúti',
 				'alt' => 'autai meridiunau',
 				'am' => 'amáriku',
 				'an' => 'aragunẽi',
 				'ang' => 'ẽgirixi arkaiku',
 				'anp' => 'ãyika',
 				'ar' => 'arabi',
 				'ar_001' => 'arabi mudernu',
 				'arc' => 'aramaiku',
 				'arn' => 'mapudũgũ',
 				'arp' => 'araparu',
 				'ars' => 'arabi negede',
 				'arw' => 'arawaki',
 				'as' => 'asamei',
 				'asa' => 'asu',
 				'ast' => 'asiturianu',
 				'av' => 'awariku',
 				'awa' => 'awadi',
 				'ay' => 'aimará',
 				'az' => 'aserbayanu',
 				'az_Arab' => 'aseri sú',
 				'ba' => 'baxikiri',
 				'bal' => 'barúxi',
 				'ban' => 'barinei',
 				'bas' => 'basa',
 				'bax' => 'bamũ',
 				'bbj' => 'gumara',
 				'be' => 'bierurusu',
 				'bej' => 'beya',
 				'bem' => 'bẽba',
 				'bez' => 'bena',
 				'bfd' => 'bafuti',
 				'bg' => 'búgaru',
 				'bgn' => 'baruxi usidẽtawara',
 				'bho' => 'buyipuri',
 				'bi' => 'bisiramá',
 				'bik' => 'bikú',
 				'bin' => 'biní',
 				'bkm' => 'kũ',
 				'bla' => 'sikisika',
 				'bm' => 'bãbara',
 				'bn' => 'bẽgari',
 				'bo' => 'tibetanu',
 				'br' => 'beretãu',
 				'bra' => 'barayi',
 				'brx' => 'budu',
 				'bs' => 'businiu',
 				'bss' => 'akusi',
 				'bua' => 'buriatu',
 				'bug' => 'buginei',
 				'bum' => 'buru',
 				'byn' => 'birĩ',
 				'byv' => 'medũba',
 				'ca' => 'katará',
 				'cad' => 'cadu',
 				'car' => 'karibi',
 				'cay' => 'kayuga',
 				'cch' => 'atisã',
 				'ccp' => 'xakima',
 				'ce' => 'xexenu',
 				'ceb' => 'sebuanu',
 				'cgg' => 'xiga',
 				'ch' => 'xamuru',
 				'chb' => 'xibixa',
 				'chg' => 'xagatai',
 				'chk' => 'xukisi',
 				'chm' => 'mari',
 				'chn' => 'yarigãu xinoki',
 				'cho' => 'xokitau',
 				'chp' => 'xipewiyã',
 				'chr' => 'xerokí',
 				'chy' => 'xeyeni',
 				'ckb' => 'kurdu piterapura',
 				'co' => 'curisu',
 				'cop' => 'kupita',
 				'cr' => 'kiri',
 				'crh' => 'Kirimeya turiku',
 				'crs' => 'kiriuru frãsei seixeriwara',
 				'cs' => 'tieku',
 				'csb' => 'kaxubiã',
 				'cu' => 'isirawu ekeresiatiku',
 				'cv' => 'tiuwaxi',
 				'cy' => 'garei',
 				'da' => 'dinamarikei',
 				'dak' => 'dakuta',
 				'dar' => 'darigiwa',
 				'dav' => 'taita',
 				'de' => 'aremãu',
 				'de_CH' => 'aremãu iwaté (Suisa)',
 				'del' => 'deraware',
 				'den' => 'isireivei',
 				'dgr' => 'dogiri',
 				'din' => 'dĩka',
 				'dje' => 'sarima',
 				'doi' => 'dogiribi',
 				'dsb' => 'surábiu yatuka',
 				'dua' => 'duara',
 				'dum' => 'hurãdei médiu',
 				'dv' => 'diweí',
 				'dyo' => 'yora-funiyi',
 				'dyu' => 'diura',
 				'dz' => 'disũga',
 				'dzg' => 'dasaga',
 				'ebu' => 'ẽbu',
 				'ee' => 'ewe',
 				'efi' => 'efiki',
 				'egy' => 'egipisiu arkaiku',
 				'eka' => 'ekayuki',
 				'el' => 'geregu',
 				'elx' => 'eramite',
 				'en' => 'ẽgirixi',
 				'enm' => 'ẽgirixi médiu',
 				'eo' => 'esiperãtu',
 				'es' => 'isipãyu',
 				'et' => 'eituniyanu',
 				'eu' => 'basiku',
 				'ewo' => 'ewũdu',
 				'fa' => 'perisa',
 				'fan' => 'fãge',
 				'fat' => 'fãti',
 				'ff' => 'fura',
 				'fi' => 'firãdes',
 				'fil' => 'firipinu',
 				'fj' => 'fiyianu',
 				'fo' => 'faruwesi',
 				'fon' => 'fũmu',
 				'fr' => 'frãsei',
 				'frc' => 'frãsei kayũ',
 				'frm' => 'frãsei médiu',
 				'fro' => 'frãsei arkaiku',
 				'frr' => 'firísiu setẽtiriunau',
 				'frs' => 'firísiu usidẽtawara',
 				'fur' => 'friuranu',
 				'fy' => 'frísiu usidẽtawara',
 				'ga' => 'irãdeixi médiu',
 				'gaa' => 'ga',
 				'gag' => 'gagausi',
 				'gan' => 'gã',
 				'gay' => 'gayu',
 				'gba' => 'gibaya',
 				'gd' => 'gaériku ekusei',
 				'gez' => 'giixi',
 				'gil' => 'giubetei',
 				'gl' => 'garegu',
 				'gmh' => 'aremãu iwaté médiu',
 				'gn' => 'guwarani',
 				'goh' => 'aremãu arkaiku iwaté',
 				'gon' => 'gũdi',
 				'gor' => 'gurũtaru',
 				'got' => 'gútiku',
 				'grb' => 'gerebu',
 				'grc' => 'geregu arkaiku',
 				'gsw' => 'aremãu (Suisa)',
 				'gu' => 'guserate',
 				'guz' => 'gusiyi',
 				'gv' => 'mãkisi',
 				'gwi' => 'guwixi-ĩ',
 				'ha' => 'hausá',
 				'hai' => 'haida',
 				'hak' => 'haká',
 				'haw' => 'hawayanu',
 				'he' => 'heburaiku',
 				'hi' => 'hĩdi',
 				'hil' => 'irigainũ',
 				'hit' => 'hitita',
 				'hmn' => 'himũgi',
 				'ho' => 'hiri mutu',
 				'hr' => 'kuruata',
 				'hsb' => 'surábiu iwaté',
 				'hsn' => 'xiãgi',
 				'ht' => 'haitianu',
 				'hu' => 'ũgaru',
 				'hup' => 'hupa',
 				'hy' => 'arimẽniu',
 				'hz' => 'hereru',
 				'ia' => 'neẽgasuí',
 				'iba' => 'ibã',
 				'ibb' => 'ibibiu',
 				'id' => 'ĩdunésiu',
 				'ie' => 'neẽgapitera',
 				'ig' => 'igibu',
 				'ii' => 'sixuã yi',
 				'ik' => 'inupiaki',
 				'ilo' => 'irukanu',
 				'inh' => 'ĩguxi',
 				'io' => 'idu',
 				'is' => 'isirãdei',
 				'it' => 'itarianu',
 				'iu' => 'inukitituti',
 				'ja' => 'yapunei',
 				'jbo' => 'ruyibã',
 				'jgo' => 'ĩgẽba',
 				'jmc' => 'maxami',
 				'jpr' => 'yudaiku-perisa',
 				'jrb' => 'yudaiku-arabiku',
 				'jv' => 'yawanei',
 				'ka' => 'geurgianu',
 				'kaa' => 'kara-kaupaki',
 				'kab' => 'kabire',
 				'kac' => 'kaxĩ',
 				'kaj' => 'iyu',
 				'kam' => 'kãba',
 				'kaw' => 'kawi',
 				'kbd' => 'kabaridianu',
 				'kbl' => 'kanẽbu',
 				'kcg' => 'tiyapi',
 				'kde' => 'makũdi',
 				'kea' => 'kiriuru kabu-suikiriwara',
 				'kfo' => 'kuru',
 				'kg' => 'kũgurei',
 				'kgp' => 'kaĩgãgi',
 				'kha' => 'kasi',
 				'kho' => 'kutanei',
 				'khq' => 'kuyira xini',
 				'ki' => 'kikuyu',
 				'kj' => 'kuãyama',
 				'kk' => 'kasaki',
 				'kkj' => 'kaku',
 				'kl' => 'guruẽrãdei',
 				'kln' => 'karẽyĩ',
 				'km' => 'kimé',
 				'kmb' => 'kĩbũdu',
 				'kn' => 'kanarĩ',
 				'ko' => 'kurianu',
 				'koi' => 'kumi-perimiaki',
 				'kok' => 'kũkani',
 				'kos' => 'kusirayã',
 				'kpe' => 'kipere',
 				'kr' => 'kanúri',
 				'krc' => 'karaxai-bauká',
 				'krl' => 'karériu',
 				'kru' => 'kuruki',
 				'ks' => 'kaxemira',
 				'ksb' => 'xãbara',
 				'ksf' => 'bafia',
 				'ksh' => 'kurixi',
 				'ku' => 'kurdu',
 				'kum' => 'kumiki',
 				'kut' => 'kutenai',
 				'kv' => 'kumi',
 				'kw' => 'kúriniku',
 				'ky' => 'kirigixi',
 				'la' => 'ratĩ',
 				'lad' => 'radinu',
 				'lag' => 'rãgi',
 				'lah' => 'rãda',
 				'lam' => 'rãba',
 				'lb' => 'ruxẽbugei',
 				'lez' => 'resigi',
 				'lg' => 'rugãda',
 				'li' => 'rĩburgei',
 				'lkt' => 'rakuta',
 				'ln' => 'rĩgana',
 				'lo' => 'rausianu',
 				'lol' => 'mũgu',
 				'lou' => 'kiriuru ruisianawara',
 				'loz' => 'rusi',
 				'lrc' => 'ruri setẽtiriunau',
 				'lt' => 'rituanu',
 				'lu' => 'ruba-katãga',
 				'lua' => 'ruba-rurua',
 				'lui' => 'ruisenu',
 				'lun' => 'rũda',
 				'luo' => 'ruwu',
 				'lus' => 'ruxai',
 				'luy' => 'ruiya',
 				'lv' => 'retãu',
 				'mad' => 'madurei',
 				'maf' => 'mafa',
 				'mag' => 'magarí',
 				'mai' => 'maitiri',
 				'mak' => 'makasá',
 				'man' => 'mãdĩga',
 				'mas' => 'masai',
 				'mde' => 'maba',
 				'mdf' => 'mukisa',
 				'mdr' => 'mãdari',
 				'men' => 'mẽde',
 				'mer' => 'meru',
 				'mfe' => 'murisiẽ',
 				'mg' => 'maugaxe',
 				'mga' => 'irãdei médiu',
 				'mgh' => 'makua',
 				'mgo' => 'metá',
 				'mh' => 'marixarei',
 				'mi' => 'mauri',
 				'mic' => 'mikemake',
 				'min' => 'minãgikabau',
 				'mk' => 'masedũniu',
 				'ml' => 'marayara',
 				'mn' => 'mũgú',
 				'mnc' => 'mãxu',
 				'mni' => 'manipuri',
 				'moh' => 'muikanu',
 				'mos' => 'musi',
 				'mr' => 'marati',
 				'ms' => 'marayu',
 				'mt' => 'mautei',
 				'mua' => 'mũdãgi',
 				'mul' => 'siía nheẽga',
 				'mus' => 'kirik',
 				'mwl' => 'mirãdei',
 				'mwr' => 'mariwari',
 				'my' => 'birimanei',
 				'mye' => 'miyene',
 				'myv' => 'erisia',
 				'mzn' => 'masãdarani',
 				'na' => 'nauruanu',
 				'nan' => 'mĩ nã',
 				'nap' => 'napuritanu',
 				'naq' => 'nama',
 				'nb' => 'bukimau nuruegei',
 				'nd' => 'ĩdebere nutiwara',
 				'nds' => 'aremaũ yatuka',
 				'nds_NL' => 'sakisãu yatuka',
 				'ne' => 'neparei',
 				'new' => 'newari',
 				'ng' => 'dũgu',
 				'nia' => 'niyasi',
 				'niu' => 'niweanu',
 				'nl' => 'hurãdei',
 				'nl_BE' => 'faramẽgu',
 				'nmg' => 'kuwasiu',
 				'nn' => 'ninorisiki nuruegei',
 				'nnh' => 'ĩgiẽbũ',
 				'no' => 'nuruegei',
 				'nog' => 'nugai',
 				'non' => 'núridiku arkaiku',
 				'nqo' => 'nikú',
 				'nr' => 'ĩdebere suwara',
 				'nso' => 'sutu setẽtiriunau',
 				'nus' => 'nuiri',
 				'nv' => 'nawayu',
 				'nwc' => 'newari katuwa',
 				'ny' => 'niãya',
 				'nym' => 'niãmuwesi',
 				'nyn' => 'niãkuri',
 				'nyo' => 'niyuru',
 				'nzi' => 'ĩsima',
 				'oc' => 'usitãniku',
 				'oj' => 'uyibua',
 				'om' => 'urumu',
 				'or' => 'uriá',
 				'os' => 'usetu',
 				'osa' => 'usayi',
 				'ota' => 'turiku utumanu',
 				'pa' => 'pãyabi',
 				'pag' => 'pãgasinã',
 				'pal' => 'parawi',
 				'pam' => 'pãpãga',
 				'pap' => 'papiamẽtu',
 				'pau' => 'parauanu',
 				'pcm' => 'pidigĩ niyerianu',
 				'peo' => 'persa arkaiku',
 				'phn' => 'finísiu',
 				'pi' => 'pári',
 				'pl' => 'purunei',
 				'pon' => 'pũpeianu',
 				'prg' => 'purusianu',
 				'pro' => 'puruwẽsau arkaiku',
 				'ps' => 'paxitu',
 				'ps@alt=variant' => 'puxitu',
 				'pt' => 'putugei',
 				'qu' => 'kíxua',
 				'quc' => 'kixé',
 				'raj' => 'rayasitani',
 				'rap' => 'rapanui',
 				'rar' => 'rurutũganu',
 				'rm' => 'rumãxi',
 				'rn' => 'rũdi',
 				'ro' => 'rumenu',
 				'ro_MD' => 'mudáwiu',
 				'rof' => 'rũbu',
 				'rom' => 'rumani',
 				'root' => 'raisi',
 				'ru' => 'rusu',
 				'rup' => 'arumenu',
 				'rw' => 'kiniaruãda',
 				'rwk' => 'ruwa',
 				'sa' => 'sãsikiritu',
 				'sad' => 'sãdawe',
 				'sah' => 'saka',
 				'sam' => 'aramaiku samaritanu',
 				'saq' => 'sãburu',
 				'sas' => 'sasak',
 				'sat' => 'sãtari',
 				'sba' => 'ĩgãbai',
 				'sbp' => 'sãgu',
 				'sc' => 'saridú',
 				'scn' => 'sisirianu',
 				'sco' => 'isiutis',
 				'sd' => 'sĩdi',
 				'sdh' => 'kuridu meridiunau',
 				'se' => 'sami setẽtiriunau',
 				'see' => 'seneka',
 				'seh' => 'sena',
 				'sel' => 'seukupi',
 				'ses' => 'kuiraburu seni',
 				'sg' => 'sãgú',
 				'sga' => 'irãdesiarkaiku',
 				'sh' => 'seriwu-kruata',
 				'shi' => 'taxeriti',
 				'shn' => 'xãni',
 				'shu' => 'arabi xadianu',
 				'si' => 'sĩgarei',
 				'sid' => 'sidamu',
 				'sk' => 'esiruwaku',
 				'sl' => 'esiruwenu',
 				'sm' => 'samuanu',
 				'sma' => 'sami meridiunau',
 				'smj' => 'sami Lulewara',
 				'smn' => 'sami Inariwara',
 				'sms' => 'sami Skoltwara',
 				'sn' => 'xuna',
 				'snk' => 'sunĩkê',
 				'so' => 'sumari',
 				'sog' => 'sugidianu',
 				'sq' => 'aubanei',
 				'sr' => 'sériwiu',
 				'srn' => 'surinamei',
 				'srr' => 'serere',
 				'ss' => 'suási',
 				'ssy' => 'saru',
 				'st' => 'sutu suwara',
 				'su' => 'sũdanei',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumeriu',
 				'sv' => 'sueku',
 				'sw' => 'suaíri',
 				'sw_CD' => 'suairi kũguwara',
 				'swb' => 'kumurianu',
 				'syc' => 'siriaku katuwa',
 				'syr' => 'siriaku',
 				'ta' => 'tamiu',
 				'te' => 'térugu',
 				'tem' => 'timine',
 				'teo' => 'teso',
 				'ter' => 'terenu',
 				'tet' => 'tetũ',
 				'tg' => 'tadiyike',
 				'th' => 'tairãdei',
 				'ti' => 'tigirínia',
 				'tig' => 'tigiré',
 				'tiv' => 'tivi',
 				'tk' => 'turikumenu',
 				'tkl' => 'tukerauanu',
 				'tl' => 'tagaru',
 				'tlh' => 'kirĩgũ',
 				'tli' => 'tirĩgiti',
 				'tmh' => 'tamaxeki',
 				'tn' => 'tisuana',
 				'to' => 'tũganei',
 				'tog' => 'tũganei Niasawara',
 				'tpi' => 'tuki pisĩ',
 				'tr' => 'turku',
 				'trv' => 'taruku',
 				'ts' => 'tesũga',
 				'tsi' => 'tesĩmĩxianu',
 				'tt' => 'táritaru',
 				'tum' => 'tũbuka',
 				'tvl' => 'tuwaruanu',
 				'tw' => 'tui',
 				'twq' => 'tasawake',
 				'ty' => 'taitianu',
 				'tyv' => 'tuwinianu',
 				'tzm' => 'tamasiriti Átras katuwa',
 				'udm' => 'udimurite',
 				'ug' => 'wiguri',
 				'uga' => 'ugarítiku',
 				'uk' => 'ukaranianu',
 				'umb' => 'ũbũdu',
 				'und' => 'ũba uyukuau nheẽga',
 				'ur' => 'urdu',
 				'uz' => 'usibeki',
 				'vai' => 'wai',
 				've' => 'wẽda',
 				'vi' => 'wietinamita',
 				'vo' => 'wurapuke',
 				'vot' => 'wútiku',
 				'vun' => 'wũyu',
 				'wa' => 'warãu',
 				'wae' => 'wauseri',
 				'wal' => 'woraita',
 				'war' => 'warai',
 				'was' => 'waxu',
 				'wbp' => 'waripiri',
 				'wo' => 'worofi',
 				'wuu' => 'wurapuki',
 				'xal' => 'kaumiki',
 				'xh' => 'xosa',
 				'xog' => 'rusoga',
 				'yao' => 'yau',
 				'yap' => 'yapese',
 				'yav' => 'yãgibẽ',
 				'ybb' => 'yẽba',
 				'yi' => 'yídixi',
 				'yo' => 'yurubá',
 				'yrl' => 'nheẽgatu',
 				'yue' => 'kãtunei',
 				'yue@alt=menu' => 'kãtunei (katuwa)',
 				'za' => 'suãgi',
 				'zap' => 'saputeku',
 				'zbl' => 'rãgasaitá brisi',
 				'zen' => 'senaga',
 				'zgh' => 'tamasiriti marukinu padrãu',
 				'zh' => 'xinanheẽga',
 				'zh@alt=menu' => 'xinanheẽga, mãdarĩ',
 				'zh_Hans' => 'xinanheẽga iwasuĩma',
 				'zh_Hans@alt=long' => 'xinanheẽga mãdarĩ (iwasuĩma)',
 				'zh_Hant' => 'xinanheẽga katuwa',
 				'zh_Hant@alt=long' => 'xinanheẽga mãdarĩ (katuwa)',
 				'zu' => 'suru',
 				'zun' => 'sũyi',
 				'zxx' => 'ũba aykué nheẽga sesewaraitá',
 				'zza' => 'sasaki',

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
			'Arab' => 'arabika',
 			'Arab@alt=variant' => 'perisu-arabika',
 			'Armi' => 'arimi',
 			'Armn' => 'arimẽniu',
 			'Avst' => 'awétiku',
 			'Bali' => 'barineisi',
 			'Bamu' => 'bamũ',
 			'Batk' => 'bataki',
 			'Beng' => 'bẽgari',
 			'Blis' => 'rãgasaitá bliss',
 			'Bopo' => 'bupumufu',
 			'Brah' => 'brami',
 			'Brai' => 'braire',
 			'Bugi' => 'buginei',
 			'Buhd' => 'buwidi',
 			'Cakm' => 'kakimi',
 			'Cans' => 'yũpinimasá síraba irũ aburíjini kanadáwara suí',
 			'Cari' => 'karianu',
 			'Cham' => 'xãmi',
 			'Cher' => 'xerokí',
 			'Cirt' => 'runikarana',
 			'Copt' => 'kupitiku',
 			'Cprt' => 'sipiriuta',
 			'Cyrl' => 'siríriku',
 			'Cyrs' => 'siríriku isirawu ekeresiatiku',
 			'Deva' => 'dewanagari',
 			'Dsrt' => 'desereti',
 			'Egyd' => 'demútiku egipisiu',
 			'Egyh' => 'ierátiku egipisiu',
 			'Egyp' => 'egipsiu-ita kuatiara kuxiímawara',
 			'Ethi' => 'etiúpiku',
 			'Geok' => 'kutisuri geurgianu',
 			'Geor' => 'geurgianu',
 			'Glag' => 'garagurítiku',
 			'Goth' => 'gútiku',
 			'Grek' => 'geregu',
 			'Gujr' => 'guserati',
 			'Guru' => 'gumuki',
 			'Hanb' => 'hãbi',
 			'Hang' => 'hãgu',
 			'Hani' => 'hã',
 			'Hano' => 'hanunu',
 			'Hans' => 'iwasuĩma',
 			'Hans@alt=stand-alone' => 'hã iwasuĩma',
 			'Hant' => 'katuwa',
 			'Hant@alt=stand-alone' => 'hã katuwa',
 			'Hebr' => 'heburaiku',
 			'Hira' => 'hiragana',
 			'Hmng' => 'parau himũgi',
 			'Hrkt' => 'yapunei síraba irũ',
 			'Hung' => 'ũgaru kuxiímawara',
 			'Inds' => 'ĩdu',
 			'Ital' => 'itáriku kuxiímawara',
 			'Jamo' => 'yamu',
 			'Java' => 'yawanei',
 			'Jpan' => 'yapunei',
 			'Kali' => 'kaya ri',
 			'Kana' => 'katakaná',
 			'Khar' => 'karuxiti',
 			'Khmr' => 'kimé',
 			'Knda' => 'kãnará',
 			'Kore' => 'kureanu',
 			'Kthi' => 'kiti',
 			'Lana' => 'rana',
 			'Laoo' => 'rau',
 			'Latf' => 'ratĩ farakitú',
 			'Latg' => 'ratĩ gaériku',
 			'Latn' => 'ratĩ',
 			'Lepc' => 'repixa',
 			'Limb' => 'rĩbu',
 			'Lina' => 'satãbika A',
 			'Linb' => 'satãbika B',
 			'Lisu' => 'risu',
 			'Lyci' => 'rísiu',
 			'Lydi' => 'rídiu',
 			'Mand' => 'mãdaiku',
 			'Mani' => 'manikeanu',
 			'Maya' => 'maya-ita kuatiara kuxiímawara',
 			'Merc' => 'meruítiku kusiwu',
 			'Mero' => 'meruítiku',
 			'Mlym' => 'marayara',
 			'Mong' => 'mũgú',
 			'Moon' => 'Moon kuatiara',
 			'Mtei' => 'manipuri kuatiara',
 			'Mymr' => 'birimanei',
 			'Nkoo' => 'ĩku',
 			'Ogam' => 'ugãmiku',
 			'Olck' => 'uxiki',
 			'Orkh' => 'urikũ',
 			'Orya' => 'uriá',
 			'Osma' => 'usmania',
 			'Perm' => 'périmiku kuxiímawara',
 			'Phag' => 'phagipa',
 			'Phli' => 'phli',
 			'Phlp' => 'phlp',
 			'Phlv' => 'paravi kuxiímawara',
 			'Phnx' => 'finísiu',
 			'Plrd' => 'funétiku miau',
 			'Prti' => 'prti',
 			'Rjng' => 'reyãgi',
 			'Roro' => 'rũgurũgu',
 			'Runr' => 'rúniku',
 			'Samr' => 'samaritanu',
 			'Sara' => 'sarati',
 			'Saur' => 'sauraxitara',
 			'Sgnw' => 'sãgawa kuatiara',
 			'Shaw' => 'xawianu',
 			'Sinh' => 'sĩgarei',
 			'Sund' => 'sudãnei',
 			'Sylo' => 'siruti nagiri',
 			'Syrc' => 'siríaku',
 			'Syre' => 'siríaku esitarãgeru',
 			'Syrj' => 'siriaku usidẽtawara',
 			'Syrn' => 'siriaku uriẽtawara',
 			'Tagb' => 'tagibanua',
 			'Tale' => 'tai re',
 			'Talu' => 'tai rue pisasú',
 			'Taml' => 'tãmiu',
 			'Tavt' => 'tawiti',
 			'Telu' => 'térugu',
 			'Teng' => 'tẽguwari',
 			'Tfng' => 'tifinagi',
 			'Tglg' => 'tagaru',
 			'Thaa' => 'ta-ana',
 			'Thai' => 'tairãdei',
 			'Tibt' => 'tibetanu',
 			'Ugar' => 'ugarítiku',
 			'Vaii' => 'wai',
 			'Visp' => 'nheẽga xipiawera',
 			'Xpeo' => 'perisa kuxiímawara',
 			'Xsux' => 'sumériu-akadianu kune-sãgawa',
 			'Yiii' => 'yi',
 			'Zinh' => 'tauxariwa',
 			'Zmth' => 'matemátika kuatiara',
 			'Zsye' => 'Emuyi',
 			'Zsym' => 'zsym',
 			'Zxxx' => 'yũpinimasáĩma',
 			'Zyyy' => 'mayewera',
 			'Zzzz' => 'yũpinimasá ũbawa uyukuau',

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
			'001' => 'Iwi',
 			'002' => 'Afirika',
 			'003' => 'Amerika Nuti suí',
 			'005' => 'Amerika Su suí',
 			'009' => 'Useãniya',
 			'011' => 'Afirika Usidẽtawara',
 			'013' => 'Amerika Piterapura',
 			'014' => 'Afirika Uriẽtawara',
 			'015' => 'Afirika Nuti suí',
 			'017' => 'Afirika Piterapura',
 			'018' => 'Afirika Meridiyunau',
 			'019' => 'America-ita',
 			'021' => 'Amerika Setẽtiriunau',
 			'029' => 'Karíbi',
 			'030' => 'Ásiya Uriẽtawara',
 			'034' => 'Ásiya Meridiyunau',
 			'035' => 'Sudeti Ásiyatiku',
 			'039' => 'Eurupa Meridiyunau',
 			'053' => 'Ausitarasia',
 			'054' => 'Meranésiya',
 			'057' => 'Micuronesiya Tetãma',
 			'061' => 'Pulinesiya',
 			'142' => 'Ásiya',
 			'143' => 'Ásiya Piterapura',
 			'145' => 'Ásiya Usidẽtawara',
 			'150' => 'Eurupa',
 			'151' => 'Eurupa Uriẽtawara',
 			'154' => 'Eurupa Setẽtiriunau',
 			'155' => 'Eurupa Usidẽtawara',
 			'202' => 'Afirika Subisariana',
 			'419' => 'Amerika Latina',
 			'AC' => 'Asesãu Kapuãma',
 			'AD' => 'Ãdura',
 			'AE' => 'Emiradu Árabi Yepewasuwaitá',
 			'AF' => 'Afegãniretãma',
 			'AG' => 'Ãtigua asuí Babuda',
 			'AI' => 'Ãgira',
 			'AL' => 'Aubãniya',
 			'AM' => 'Arimẽniya',
 			'AO' => 'Ãgura',
 			'AQ' => 'Ãtartida',
 			'AR' => 'Argẽtina',
 			'AS' => 'Samua Amerikiwara',
 			'AT' => 'Ausitiriya',
 			'AU' => 'Ausitaraliya',
 			'AW' => 'Aruba',
 			'AX' => 'Kapuãma-ita Arãdi',
 			'AZ' => 'Aseriretãma',
 			'BA' => 'Businiya asuí Eseguwina',
 			'BB' => 'Babadu',
 			'BD' => 'Bãgaradexi',
 			'BE' => 'Beujika',
 			'BF' => 'Bukina Fasu',
 			'BG' => 'Bugáriya',
 			'BH' => 'Barẽi',
 			'BI' => 'Burũdi',
 			'BJ' => 'Benĩ',
 			'BL' => 'Sã Batulumeu',
 			'BM' => 'Bemuda',
 			'BN' => 'Burunei',
 			'BO' => 'Buríwia',
 			'BQ' => 'Tetãma Iwiboí-ita Karíbi suí',
 			'BR' => 'Brasiu',
 			'BS' => 'Bayama',
 			'BT' => 'Butãu',
 			'BV' => 'Kapuãma Buweti',
 			'BW' => 'Butisuwana',
 			'BY' => 'Bieru-rúsiya',
 			'BZ' => 'Belisi',
 			'CA' => 'Kanadá',
 			'CC' => 'Kapuãma-ita Kuku (Keering)',
 			'CD' => 'Kũgu - Kĩxasa',
 			'CD@alt=variant' => 'Repubirika Demukaratika Kũguyara',
 			'CF' => 'Repubirika Afirika-Piterapura',
 			'CG' => 'Repubirika Kũguyara',
 			'CG@alt=variant' => 'Kũgu',
 			'CH' => 'Suwisa',
 			'CI' => 'Mafim Kupé',
 			'CI@alt=variant' => 'Kute Divuá',
 			'CK' => 'Kapuãma-ita Kooki',
 			'CL' => 'Xiri',
 			'CM' => 'Puty-ita',
 			'CN' => 'Xina',
 			'CO' => 'Kurũbiya',
 			'CP' => 'Kiripetũ Kapuãma',
 			'CR' => 'Kupé Rika',
 			'CU' => 'Kuba',
 			'CV' => 'Kabu Suikiri',
 			'CW' => 'Kurasau',
 			'CX' => 'Kapuãma Kiritima',
 			'CY' => 'Xipiri',
 			'CZ' => 'Xekiya',
 			'CZ@alt=variant' => 'Repubirika Xeka',
 			'DE' => 'Aremãya',
 			'DG' => 'Diyegu Garasiya',
 			'DJ' => 'Dijibuti',
 			'DK' => 'Dinamaka',
 			'DM' => 'Dominika',
 			'DO' => 'Repubirika Duminikana',
 			'DZ' => 'Argeriya',
 			'EA' => 'Seuta asuí Merira',
 			'EC' => 'Ekuadú',
 			'EE' => 'Isituniya',
 			'EG' => 'Egitu',
 			'EH' => 'Saara Usidẽtawara',
 			'ER' => 'Eritireya',
 			'ES' => 'Isipãya',
 			'ET' => 'Etiupiya',
 			'EU' => 'Eurupa Yepewasusawa',
 			'EZ' => 'euru suna',
 			'FI' => 'Firãdiya',
 			'FJ' => 'Fiyi',
 			'FK' => 'Kapuãma-ita Mawina',
 			'FK@alt=variant' => 'Kapuãma-ita Mawina (Kapuãma-ita Falkland)',
 			'FM' => 'Mikuruneziya',
 			'FO' => 'Kapuãma-ita Faruwe',
 			'FR' => 'Frãsa',
 			'GA' => 'Gabãu',
 			'GB' => 'Reyinu Yepewasú',
 			'GD' => 'Garanada',
 			'GE' => 'Geugiya',
 			'GF' => 'Giyana Frãsa yara',
 			'GG' => 'Guwẽnisei',
 			'GH' => 'Gana',
 			'GI' => 'Gibarautá',
 			'GL' => 'Guruẽrãdiya',
 			'GM' => 'Gãbiya',
 			'GN' => 'Giné',
 			'GP' => 'Guadarupi',
 			'GQ' => 'Giné Ekuaturiyau',
 			'GR' => 'Geresiya',
 			'GS' => 'Kapuãma-ita Geugiya Su asuí Sãduwixi Su',
 			'GT' => 'Guatemara',
 			'GU' => 'Guwã',
 			'GW' => 'Giné Bisau',
 			'GY' => 'Giyana',
 			'HK' => 'Hũgi Kũgi, RAE Xina yara',
 			'HK@alt=short' => 'Hũgi Kũgi',
 			'HM' => 'Kapuãma-ita Heard asuí McDonald',
 			'HN' => 'Ũdura',
 			'HR' => 'Kuruwasiya',
 			'HT' => 'Aití',
 			'HU' => 'Ũgiriya',
 			'IC' => 'Kapuãma-ita Kanariya',
 			'ID' => 'Ĩdunesiya',
 			'IE' => 'Irãda',
 			'IL' => 'Isirayeu',
 			'IM' => 'Mã Kapuãma',
 			'IN' => 'Ĩdiya',
 			'IO' => 'Biritãniku Usuasawa Useyanu Ĩdiku',
 			'IQ' => 'Iraki',
 			'IR' => 'Irã',
 			'IS' => 'Isirãdiya',
 			'IT' => 'Itariya',
 			'JE' => 'Yesei',
 			'JM' => 'Yamaika',
 			'JO' => 'Yudãniya',
 			'JP' => 'Nipõ',
 			'KE' => 'Kẽniya',
 			'KG' => 'Kirigiretãma',
 			'KH' => 'Kãbuya',
 			'KI' => 'Kiribati',
 			'KM' => 'Kumure-ita',
 			'KN' => 'Sã Kirituwãu suí Newi',
 			'KP' => 'Kureya Nuti suí',
 			'KR' => 'Kureya Su suí',
 			'KW' => 'Kuwaiti',
 			'KY' => 'Kapuãma-ita Kaimã',
 			'KZ' => 'Kasakiretãma',
 			'LA' => 'Rawo',
 			'LB' => 'Ribanu',
 			'LC' => 'Sãta Lusiya',
 			'LI' => 'Rixitẽxitaĩ',
 			'LK' => 'Siri Rãka',
 			'LR' => 'Ribériya',
 			'LS' => 'Resutu',
 			'LT' => 'Rituwãniya',
 			'LU' => 'Ruxẽbugu',
 			'LV' => 'Retuniya',
 			'LY' => 'Ribiya',
 			'MA' => 'Maruku',
 			'MC' => 'Mũnaku',
 			'MD' => 'Mũduwa',
 			'ME' => 'Mũteneguru',
 			'MF' => 'Sã Matiyũ',
 			'MG' => 'Madagasiká',
 			'MH' => 'Kapuãma-ita Marshall',
 			'MK' => 'Masedũniya',
 			'ML' => 'Mari',
 			'MM' => 'Miyamá (Bimãniya)',
 			'MN' => 'Mũguriya',
 			'MO' => 'Makau, RAE Xina yara',
 			'MO@alt=short' => 'Makau',
 			'MP' => 'Kapuãma-ita Mariyãna Nuti suí',
 			'MQ' => 'Matinika',
 			'MR' => 'Mauritaniya',
 			'MS' => 'Mũtiserati',
 			'MT' => 'Mauta',
 			'MU' => 'Maurisiyu',
 			'MV' => 'Maudiwa-ita',
 			'MW' => 'Marawi',
 			'MX' => 'Mẽsiku',
 			'MY' => 'Malasiya',
 			'MZ' => 'Musãbiki',
 			'NA' => 'Namíbiya',
 			'NC' => 'Karedũniya Pisasú',
 			'NE' => 'Nige',
 			'NF' => 'Kapuãma Norfolk',
 			'NG' => 'Nigeriya',
 			'NI' => 'Nicaraguwa',
 			'NL' => 'Tetãma Iwiboí-ita',
 			'NO' => 'Nuruwega',
 			'NP' => 'Nepau',
 			'NR' => 'Nauru',
 			'NU' => 'Niwe',
 			'NZ' => 'Serãdiya Pisasú',
 			'OM' => 'Umã',
 			'PA' => 'Panamã',
 			'PE' => 'Peru',
 			'PF' => 'Pulinesiya Frãsa yara',
 			'PG' => 'Papuwa-Giné Pisasú',
 			'PH' => 'Firipina',
 			'PK' => 'Pakiretãma',
 			'PL' => 'Puluniya',
 			'PM' => 'Sã Peduru asuí Mikelãu',
 			'PN' => 'Kapuãma-ita Pitcairn',
 			'PR' => 'Igarapawa Riku',
 			'PS' => 'Tetãma Paretinu-ita yara',
 			'PS@alt=short' => 'Paretina',
 			'PT' => 'Putugau',
 			'PW' => 'Parau',
 			'PY' => 'Paraguwai',
 			'QA' => 'Katara',
 			'QO' => 'Useãniya (R)',
 			'RE' => 'Yumuatirisawa',
 			'RO' => 'Romẽniya',
 			'RS' => 'Sewiya',
 			'RU' => 'Rusiya',
 			'RW' => 'Huãda',
 			'SA' => 'Arawia Saudita',
 			'SB' => 'Kapuãma-ita Sarumũ',
 			'SC' => 'Seixeri',
 			'SD' => 'Ausudã',
 			'SE' => 'Suwesiya',
 			'SG' => 'Sĩgapura',
 			'SH' => 'Sãta Erena',
 			'SI' => 'Esiruwẽniya',
 			'SJ' => 'Siwaubati asuí Yã Mayeni',
 			'SK' => 'Esiruwakiya',
 			'SL' => 'Iwitera Leowa',
 			'SM' => 'Sã Marino',
 			'SN' => 'Senegau',
 			'SO' => 'Somariya',
 			'SR' => 'Suriname',
 			'SS' => 'Ausudã Su suí',
 			'ST' => 'Sã Tumé asuí Pirĩsipe',
 			'SV' => 'Eru Sawadu',
 			'SX' => 'Sĩti Maatẽ',
 			'SY' => 'Siriya',
 			'SZ' => 'Esuatíni',
 			'SZ@alt=variant' => 'Suwasiretãma',
 			'TA' => 'Tiritãu Kũya',
 			'TC' => 'Kapuãma-ita Tuka-ita asuí Kaiko-ita',
 			'TD' => 'Xade',
 			'TF' => 'Tetãma Su-ita Frãsa suí',
 			'TG' => 'Togu',
 			'TH' => 'Tairetãma',
 			'TJ' => 'Tayikiretãma',
 			'TK' => 'Tukerau',
 			'TL' => 'Timu-Semusawa',
 			'TL@alt=variant' => 'Repubirika Demukaratika Timu-Semusawa',
 			'TM' => 'Turkuranaretãma',
 			'TN' => 'Tunisiya',
 			'TO' => 'Tõga',
 			'TR' => 'Tukíya',
 			'TT' => 'Tirinidadi asuí Tobagu',
 			'TV' => 'Tuwaru',
 			'TW' => 'Taiwã',
 			'TZ' => 'Tãsaniya',
 			'UA' => 'Ukarãniya',
 			'UG' => 'Ugãda',
 			'UM' => 'Kapuãma Kuiriwaita Apekatu EUA suí',
 			'UN' => 'Nasãu Yepewasuwaitá',
 			'UN@alt=short' => 'ONU',
 			'US' => 'Tetãma-ita Yepewasú',
 			'US@alt=short' => 'EUA',
 			'UY' => 'Uruguwai',
 			'UZ' => 'Yũbuesara-retãma',
 			'VA' => 'Watikanu Tawa-wasu',
 			'VC' => 'Sã Wisẽti asuí Garanadĩna-ita',
 			'VE' => 'Wenesuera',
 			'VG' => 'Kapuã-ita Viyẽ-ita Biritãnika-ita',
 			'VI' => 'Kapuã-ira Viyẽ-ita Amerikana-ita',
 			'VN' => 'Wiyetinã',
 			'VU' => 'Wanuatu',
 			'WF' => 'Wari asuí Futuna',
 			'WS' => 'Samowa',
 			'XA' => 'Sutakirana-ita',
 			'XB' => 'Bidiresiunaurana',
 			'XK' => 'Kusuwu',
 			'YE' => 'Yemẽ',
 			'YT' => 'Mayuti',
 			'ZA' => 'Afirika Su suí',
 			'ZM' => 'Sãbiya',
 			'ZW' => 'Sĩbabuwe',
 			'ZZ' => 'Tetãma Ũbawaukuamamẽ',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'kuatiasawasupí arimã rikusawarupí',
 			'1994' => 'kuatiasawasupí resiawara muretewa',
 			'1996' => 'kuatiasawasupí arimã 1996 upé',
 			'1606NICT' => 'frãsanheẽga kaxiímawara 1606 upé',
 			'1694ACAD' => 'frãsanheẽga kuiriwara',
 			'1959ACAD' => 'akademiku',
 			'ABL1943' => 'Papira purakari-resé kuatiasawasupí 1943 suí',
 			'AO1990' => 'Kuatiasawasupí Ewakisawa Nheẽga Putugewara 1990',
 			'AREVELA' => 'arimẽniyu uriẽtawara',
 			'AREVMDA' => 'arimẽniyu usidẽtawara',
 			'BAKU1926' => 'aufabetu ratinu turku yepewasú',
 			'BISCAYAN' => 'bisikayawara',
 			'BISKE' => 'diyaretu sã giorgiu/bira',
 			'BOONT' => 'boontling',
 			'COLB1945' => 'Kõvẽsãu kuatiasawasupí Brasiu-Putugau 1945',
 			'FONIPA' => 'funétika Aufabetu Funétiku Ĩtertetãma-ita',
 			'FONUPA' => 'funétika Aufabetu Funétiku Urariku',
 			'HEPBURN' => 'romanisasawa hepburn',
 			'HOGNORSK' => 'nuruwegu iwaté',
 			'KKCOR' => 'kuatiasawasupí panhé-yara',
 			'LIPAW' => 'diyaretu ripovai Resian yara',
 			'MONOTON' => 'yepetũniku',
 			'NDYUKA' => 'diyaretu ĩdiyuka',
 			'NEDIS' => 'diyaretu natisuni',
 			'NJIVA' => 'diyaretu giniwa/niyiwa',
 			'OSOJS' => 'diyaretu usiaku/usuyani',
 			'PAMAKA' => 'diyaretu pamaka',
 			'PINYIN' => 'romanisasawa Piniyĩ',
 			'POLYTON' => 'tũniku-ita',
 			'POSIX' => 'kũputarawa',
 			'REVISED' => 'kuatiasawasupí musatãbikawa',
 			'ROZAJ' => 'resiawara',
 			'SAAHO' => 'saho',
 			'SCOTLAND' => 'ẽgirixi retewa esikusiyei',
 			'SCOUSE' => 'isikuse',
 			'SOLBA' => 'diyaretu situwisa/subika',
 			'TARASK' => 'kuatiasawasupí tarasikiewika',
 			'UCCOR' => 'kuatiasawasupí yepewasú',
 			'UCRCOR' => 'kuatiasawasupí musatãbikawa suí yespewasú',
 			'VALENCIA' => 'warẽsiwara',
 			'WADEGILE' => 'romanisasawa Wade-Giles',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Akayupawa',
 			'cf' => 'Rupisawa rikuyara',
 			'colalternate' => 'Remãtuwa sĩburu muakaripawa',
 			'colbackwards' => 'Asẽtu-ita muakaripawa yerewá',
 			'colcasefirst' => 'Wasupiriara-ita/mirĩpiriara-ita muakarisawa',
 			'colcaselevel' => 'Muakaripawa amũrupisawa irũ wasupiriara-ita yuí mirĩpiriara-ita yupú',
 			'collation' => 'Isirãsawa',
 			'colnormalization' => 'Muakaripawa nurmawaira',
 			'colnumeric' => 'Papasawa muakaripawa',
 			'colstrength' => 'Muakaripawa yepésawapawa',
 			'currency' => 'Rikuyara',
 			'hc' => 'Ara urariupura (12 vs 24)',
 			'lb' => 'Nimũ mupukasawa rupisawa',
 			'ms' => 'Musũgasawa tekô',
 			'numbers' => 'Papasawa-itá',
 			'timezone' => 'Kutu hurariyu',
 			'va' => 'Tedawasawa muyereusawa',
 			'x' => 'Purusawa mirapura',

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
 				'buddhist' => q{Akayupawa Budasuera},
 				'chinese' => q{Akayupawa Xinawara},
 				'coptic' => q{Akayupawa Kupitiku},
 				'dangi' => q{Akayupawa Dãgi},
 				'ethiopic' => q{Akayupawa Etíupi},
 				'ethiopic-amete-alem' => q{Akayupawa Amete Alem Etiupiwara},
 				'gregorian' => q{Akayupawa Greguriuwara},
 				'hebrew' => q{Akayupawa Yudeu},
 				'indian' => q{Akayupawa Tetãmapawa Ĩdiawara},
 				'islamic' => q{Akayupawa Islãsuera},
 				'islamic-civil' => q{Akayupawa Siwiu Islãsuera},
 				'islamic-umalqura' => q{Akayupawa Islãsuera (Umm al-Qura)},
 				'iso8601' => q{Akayupawa ISSO-8601},
 				'japanese' => q{Akayupawa Nipõwara},
 				'persian' => q{Akayupawa Persiyawara},
 				'roc' => q{Akayupawa Xina Repúbirikawara},
 			},
 			'cf' => {
 				'account' => q{Rikuyara rupisawa papasawa supé},
 				'standard' => q{Rikuyara rupisawa retewa},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Reyupurawaka sĩbulu-ita},
 				'shifted' => q{Reyupurawaka remãtuwa sĩbulu-ita},
 			},
 			'colbackwards' => {
 				'no' => q{Ypurawaka asẽtu-itá mayewera},
 				'yes' => q{Yupurawakasa asẽtu-ita amũrupisawa},
 			},
 			'colcasefirst' => {
 				'lower' => q{Reyupurawaka mirĩwa rupí},
 				'no' => q{Yupurawakasawa nurmawa turusuwa yuí mirĩwa piari},
 				'upper' => q{Reyupurawaka turusuwa rupí},
 			},
 			'colcaselevel' => {
 				'no' => q{Yupurawakasawa mirĩwa yuí turusúwa ãmurupí},
 				'yes' => q{Yupurawakasawa mirĩwa yuí turusúwa amũrupisawa},
 			},
 			'collation' => {
 				'big5han' => q{Xinanhẽẽga rikusawarupí muakaresawa - Big5},
 				'compat' => q{Muakaresawa rinũdewa nũgarásawa},
 				'dictionary' => q{Disiunariu muakaresawa},
 				'ducet' => q{Unicode muakaresawa retewa},
 				'eor' => q{Tekô eurupawara muakarésawa supé},
 				'gb2312han' => q{Xinanheẽga iwasuĩma muakarewa - GB2312},
 				'phonebook' => q{Terefuni sesewara muakaresawa},
 				'phonetic' => q{Yupurawakasawa terefuniara mukaresawa},
 				'pinyin' => q{Pin-yin mukaresawa},
 				'reformed' => q{Muakaresawa amũrupisawaira},
 				'search' => q{Sikaisá purusawa panhérupí},
 				'searchjl' => q{Resikai kũsuãti uyupiruwa hangul rupí},
 				'standard' => q{Mukaresawa retewa},
 				'stroke' => q{Sikisá-ita mukaresawa},
 				'traditional' => q{Mukaresawa rikusawarupí},
 				'unihan' => q{Mukaresawa radikawa - sikisá-ita},
 			},
 			'colnormalization' => {
 				'no' => q{Reyupurawaka nurmawasawaĩma},
 				'yes' => q{Reyupurawaka Unicode mayeweana},
 			},
 			'colnumeric' => {
 				'no' => q{Reyupurawaka díyitu-ita yeperawa rupí},
 				'yes' => q{Reyupurawaka díyitu-ita papasawa rupí},
 			},
 			'colstrength' => {
 				'identical' => q{Reyupurawaka opaĩ},
 				'primary' => q{Reyupurawaka letera básika nhũtú},
 				'quaternary' => q{Reyupurawaka asẽtu-ita/turusuwa-ita yuí mirĩwa-ita/turususawa/kãna},
 				'secondary' => q{Reyupurawaka asẽtu-ita},
 				'tertiary' => q{Reyupurawaka asẽtu-ita/turusuwa-ita yuí mirĩwa-ita/turususawa},
 			},
 			'd0' => {
 				'fwidth' => q{Turususawa teipausape},
 				'hwidth' => q{Turususawa pisawera},
 				'npinyin' => q{Papasawera},
 			},
 			'hc' => {
 				'h11' => q{Sistẽma 12 húra-ita (0-11)},
 				'h12' => q{Sistẽma 24 húra-ita (1-24)},
 				'h23' => q{Sistẽma 24 húra-ita (0-23)},
 				'h24' => q{Sistẽma 24 húra-ita (1-24)},
 			},
 			'lb' => {
 				'loose' => q{Mupenasawa ixama upé ikusawa yurawa irũ},
 				'normal' => q{Mupenasawa ixama upé ikusawa nurmawa irũ},
 				'strict' => q{Mupenasawa ixama upé ikusawa estiritu irũ},
 			},
 			'm0' => {
 				'bgn' => q{Sinimukasawa BGN EUA},
 				'ungegn' => q{Sinimukasawa UN GEGN},
 			},
 			'ms' => {
 				'metric' => q{Sistẽma métiriku},
 				'uksystem' => q{Sistẽma musãgasawa ĩperiawa},
 				'ussystem' => q{Sistẽma musãgasawa amerikapura},
 			},
 			'numbers' => {
 				'arab' => q{Augarismu-ita ĩdu-arabiku},
 				'arabext' => q{Augarismu-ita ĩdu-arabiku musapira},
 				'armn' => q{Augarismu-ita arimẽniyu},
 				'armnlow' => q{Augarismu-ita arimẽniyu mirĩwa},
 				'beng' => q{Augarismu-ita bẽgari},
 				'deva' => q{Augarismu-ita dewanagári},
 				'ethi' => q{Augarismu-ita etiopiwara},
 				'finance' => q{Papasawa-ita kariwa-rekuyara},
 				'fullwide' => q{Augarismu-ita teipausape},
 				'geor' => q{Augarismu-ita geurgianu},
 				'grek' => q{Augarismu-ita geregu},
 				'greklow' => q{Augarismu-ita geregu mirĩwa},
 				'gujr' => q{Augarismu-ita guserate},
 				'guru' => q{Augarismu-ita gurmuki},
 				'hanidec' => q{Augarismu-ita mukũi-pusawa xinawara},
 				'hans' => q{Augarismu-ita xinawara iwasuíma},
 				'hansfin' => q{Augarismu-ita kariwa-rekuyara xinawara iwasuíma},
 				'hant' => q{Augarismu-ita xinawara rikusawarupí},
 				'hantfin' => q{Augarismu-ita kariwa-rekuyara xinawara rikusawarupí},
 				'hebr' => q{Augarismu-ita yudeu},
 				'jpan' => q{Augarismu-ita nipõwara},
 				'jpanfin' => q{Augarismu-ita kariwa-rekuyara nipõwara},
 				'khmr' => q{Augarismu-ita kimé},
 				'knda' => q{Augarismu-ita kanarawara},
 				'laoo' => q{Augarismu-ita raosiwara},
 				'latn' => q{Augarismu-ita usidẽtawa},
 				'mlym' => q{Augarismu-ita marayaro},
 				'mong' => q{Augarismu-ita mũgúi},
 				'mymr' => q{Augarismu-ita Miyamawara},
 				'native' => q{Diyitu-wara-ita},
 				'orya' => q{Augarismu-ita uriá},
 				'roman' => q{Augarismu-ita romawara},
 				'romanlow' => q{Augarismu-ita romawara mirĩwa},
 				'taml' => q{Augarismu-ita tamir rikusawarupí},
 				'tamldec' => q{Augarismu-ita ramir},
 				'telu' => q{Augarismu-ita terugu},
 				'thai' => q{Augarismu-ita tairãdiyawara},
 				'tibt' => q{Augarismu-ita tibetewara},
 				'traditional' => q{Papasawa-ita rikusawarupí},
 				'vaii' => q{Diyitu-ita vai},
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
			'metric' => q{métiriku},
 			'UK' => q{Reyinu Yepewasú},
 			'US' => q{Tetãma-ita Yepewasú},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Nheẽga: {0}',
 			'script' => 'Letarasawa-ita: {0}',
 			'region' => 'Tẽdawa: {0}',

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
			auxiliary => qr{[ªáàăâåäā æ cç éèĕêëē f h íìĭîïī j l ñ oºóòŏôöõøō œ q úùŭûüū v ÿỹ z]},
			index => ['A', 'B', 'D', 'E', 'G', 'I', 'K', 'M', 'N', 'P', 'R', 'S', 'T', 'U', 'W', 'X', 'Y'],
			main => qr{[aã b d eẽ g iĩ k m n p r s t uũ w x y]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ¡ ? ¿ . … '‘’ "“” « » ( ) \[ \] § @ * / \\ \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'D', 'E', 'G', 'I', 'K', 'M', 'N', 'P', 'R', 'S', 'T', 'U', 'W', 'X', 'Y'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'medial' => '{0}… {1}',
			'word-final' => '{0}…',
		};
	},
);

has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					# Long Unit Identifier
					'' => {
						'name' => q(iwitú-ita mupikasawa),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(iwitú-ita mupikasawa),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0} kirĩba g),
						'other' => q({0} kirĩba g-ita),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0} kirĩba g),
						'other' => q({0} kirĩba g-ita),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(meturu segũdu kuadaradu rupi),
						'one' => q({0} meturu segũdu kuadaradu rupi),
						'other' => q({0} meturu-ita segũdu kuadaradu rupi),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(meturu segũdu kuadaradu rupi),
						'one' => q({0} meturu segũdu kuadaradu rupi),
						'other' => q({0} meturu-ita segũdu kuadaradu rupi),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(mirapara minutu-ita),
						'one' => q({0} mirapara minutu),
						'other' => q({0} mirapara minutu-ita),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(mirapara minutu-ita),
						'one' => q({0} mirapara minutu),
						'other' => q({0} mirapara minutu-ita),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(mirapara segũdu-ita),
						'one' => q({0} mirapara segũdu),
						'other' => q({0} mirapara segũdu-ita),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(mirapara segũdu-ita),
						'one' => q({0} mirapara segũdu),
						'other' => q({0} mirapara segũdu-ita),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0} garau),
						'other' => q({0} garau-ita),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0} garau),
						'other' => q({0} garau-ita),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radiano-ita),
						'one' => q({0} radiano),
						'other' => q({0} radiano-ita),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radiano-ita),
						'one' => q({0} radiano),
						'other' => q({0} radiano-ita),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(yatimanasawa),
						'one' => q({0} yatimanasawa),
						'other' => q({0} yatimanasawa-ita),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(yatimanasawa),
						'one' => q({0} yatimanasawa),
						'other' => q({0} yatimanasawa-ita),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(acre-ita),
						'one' => q({0} acre),
						'other' => q({0} acre-ita),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(acre-ita),
						'one' => q({0} acre),
						'other' => q({0} acre-ita),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunan-ita),
						'other' => q({0} dunan-ita),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunan-ita),
						'other' => q({0} dunan-ita),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hectare-ita),
						'one' => q({0} hectare),
						'other' => q({0} hectare-ita),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hectare-ita),
						'one' => q({0} hectare),
						'other' => q({0} hectare-ita),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(sẽtimeturu kuadaradu-ita),
						'one' => q({0} sẽtimeturu kuadaradu),
						'other' => q({0} sẽtimeturu kuadaradu-ita),
						'per' => q({0} sẽtimeturu kuadaradu rupi),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(sẽtimeturu kuadaradu-ita),
						'one' => q({0} sẽtimeturu kuadaradu),
						'other' => q({0} sẽtimeturu kuadaradu-ita),
						'per' => q({0} sẽtimeturu kuadaradu rupi),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(pí kuadaradu-ita),
						'one' => q({0} pí kuadaradu),
						'other' => q({0} pí kuadaradu-ita),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(pí kuadaradu-ita),
						'one' => q({0} pí kuadaradu),
						'other' => q({0} pí kuadaradu-ita),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(puregada kuadaradu-ita),
						'one' => q({0} puregada kuadaradu),
						'other' => q({0} puregada kuadaradu-ita),
						'per' => q({0} puregada kuadaradu rupi),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(puregada kuadaradu-ita),
						'one' => q({0} puregada kuadaradu),
						'other' => q({0} puregada kuadaradu-ita),
						'per' => q({0} puregada kuadaradu rupi),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(apekatusawa kuadaradu-ita),
						'one' => q({0} apekatusawa kuadaradu),
						'other' => q({0} apekatusawa kuadaradu-ita),
						'per' => q({0} apekatusawa kuadaradu rupi),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(apekatusawa kuadaradu-ita),
						'one' => q({0} apekatusawa kuadaradu),
						'other' => q({0} apekatusawa kuadaradu-ita),
						'per' => q({0} apekatusawa kuadaradu rupi),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(meturu kuadaradu-ita),
						'one' => q({0} meturu kuadaradu),
						'other' => q({0} meturu kuadaradu-ita),
						'per' => q({0} meturu kuadaradu rupi),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(meturu kuadaradu-ita),
						'one' => q({0} meturu kuadaradu),
						'other' => q({0} meturu kuadaradu-ita),
						'per' => q({0} meturu kuadaradu rupi),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(milha kuadaradu-ita),
						'one' => q({0} milha kuadaradu),
						'other' => q({0} milha kuadaradu-ita),
						'per' => q({0} milha kuadaradu rupi),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(milha kuadaradu-ita),
						'one' => q({0} milha kuadaradu),
						'other' => q({0} milha kuadaradu-ita),
						'per' => q({0} milha kuadaradu rupi),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(jarda kuadaradu-ita),
						'one' => q({0} jarda kuadaradu),
						'other' => q({0} jarda kuadaradu-ita),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(jarda kuadaradu-ita),
						'one' => q({0} jarda kuadaradu),
						'other' => q({0} jarda kuadaradu-ita),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(kilate-ita),
						'one' => q({0} kilate),
						'other' => q({0} kilate-ita),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(kilate-ita),
						'one' => q({0} kilate),
						'other' => q({0} kilate-ita),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mirigrama-ita desiritru rupi),
						'one' => q({0} mirigrama desiritru rupi),
						'other' => q({0} mirigrama-ita desiritru rupi),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mirigrama-ita desiritru rupi),
						'one' => q({0} mirigrama desiritru rupi),
						'other' => q({0} mirigrama-ita desiritru rupi),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mirimol-ita irerú-pukú rupi),
						'one' => q({0} mirimol irerú-pukú rupi),
						'other' => q({0} mirimol-ita irerú-pukú rupi),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mirimol-ita irerú-pukú rupi),
						'one' => q({0} mirimol irerú-pukú rupi),
						'other' => q({0} mirimol-ita irerú-pukú rupi),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(mol-ita),
						'other' => q({0} mol-ita),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mol-ita),
						'other' => q({0} mol-ita),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'one' => q({0} sẽtu rupi),
						'other' => q({0} sẽtu rupi),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q({0} sẽtu rupi),
						'other' => q({0} sẽtu rupi),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q({0} mil rupi),
						'other' => q({0} mil rupi),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q({0} mil rupi),
						'other' => q({0} mil rupi),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(pisawera-ita miliãu rupi),
						'one' => q({0} pisawera miliãu rupi),
						'other' => q({0} pisawera-ita miliãu rupi),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(pisawera-ita miliãu rupi),
						'one' => q({0} pisawera miliãu rupi),
						'other' => q({0} pisawera-ita miliãu rupi),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q({0} pitusá-pitasukasá),
						'other' => q({0} pitusá-pitasukasá-ita),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0} pitusá-pitasukasá),
						'other' => q({0} pitusá-pitasukasá-ita),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(irerú-pukú-ita 100 apekatusawa rupi),
						'one' => q({0} irerú-pukú 100 apekatusawa rupi),
						'other' => q({0} irerú-pukú-ita 100 apekatusawa rupi),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(irerú-pukú-ita 100 apekatusawa rupi),
						'one' => q({0} irerú-pukú 100 apekatusawa rupi),
						'other' => q({0} irerú-pukú-ita 100 apekatusawa rupi),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(irerú-pukú-ita apekatusawa rupi),
						'one' => q({0} irerú-pukú-ita apekatusawa rupi),
						'other' => q({0} irerú-pukú apekatusawa rupi),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(irerú-pukú-ita apekatusawa rupi),
						'one' => q({0} irerú-pukú-ita apekatusawa rupi),
						'other' => q({0} irerú-pukú apekatusawa rupi),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(milha-ita karóti rupi),
						'one' => q({0} milha karóti rupi),
						'other' => q({0} milha-ita karóti rupi),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(milha-ita karóti rupi),
						'one' => q({0} milha karóti rupi),
						'other' => q({0} milha-ita karóti rupi),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(milha-ita karóti ĩperiawa rupi),
						'one' => q({0} milha karóti ĩperiawa rupi),
						'other' => q({0} milha-ita karóti ĩperiawa rupi),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(milha-ita karóti ĩperiawa rupi),
						'one' => q({0} milha karóti ĩperiawa rupi),
						'other' => q({0} milha-ita karóti ĩperiawa rupi),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} Kurasí Semusawa),
						'north' => q({0} Kurasí Uwapikasawa),
						'south' => q({0} Su),
						'west' => q({0} Nuti),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} Kurasí Semusawa),
						'north' => q({0} Kurasí Uwapikasawa),
						'south' => q({0} Su),
						'west' => q({0} Nuti),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bit-ita),
						'other' => q({0} bit-ita),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bit-ita),
						'other' => q({0} bit-ita),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(byte-ita),
						'other' => q({0} byte-ita),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(byte-ita),
						'other' => q({0} byte-ita),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabit-ita),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit-ita),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabit-ita),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit-ita),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabyte-ita),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyte-ita),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabyte-ita),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyte-ita),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kirubit-ita),
						'one' => q({0} kirubit),
						'other' => q({0} kirubit-ita),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kirubit-ita),
						'one' => q({0} kirubit),
						'other' => q({0} kirubit-ita),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kirubyte-ita),
						'one' => q({0} kirubyte),
						'other' => q({0} kirubyte-ita),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kirubyte-ita),
						'one' => q({0} kirubyte),
						'other' => q({0} kirubyte-ita),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabit-ita),
						'one' => q({0} megabit),
						'other' => q({0} megabit-ita),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabit-ita),
						'one' => q({0} megabit),
						'other' => q({0} megabit-ita),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabyte-ita),
						'one' => q({0} megabyte),
						'other' => q({0} megabyte-ita),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabyte-ita),
						'one' => q({0} megabyte),
						'other' => q({0} megabyte-ita),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabyte-ita),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte-ita),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabyte-ita),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte-ita),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabit-ita),
						'one' => q({0} terabit),
						'other' => q({0} terabit-ita),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabit-ita),
						'one' => q({0} terabit),
						'other' => q({0} terabit-ita),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabyte-ita),
						'one' => q({0} terabyte),
						'other' => q({0} terabyte-ita),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabyte-ita),
						'one' => q({0} terabyte),
						'other' => q({0} terabyte-ita),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(sékuru-ita),
						'one' => q({0} sékuru),
						'other' => q({0} sékuru-ita),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(sékuru-ita),
						'one' => q({0} sékuru),
						'other' => q({0} sékuru-ita),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ara-ita),
						'other' => q({0} ara-ita),
						'per' => q({0} ara rupi),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ara-ita),
						'other' => q({0} ara-ita),
						'per' => q({0} ara rupi),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dékada-ita),
						'one' => q({0} dékada),
						'other' => q({0} dékada-ita),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dékada-ita),
						'one' => q({0} dékada),
						'other' => q({0} dékada-ita),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(hura-ita),
						'one' => q({0} hura),
						'other' => q({0} hura-ita),
						'per' => q({0} hura rupi),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(hura-ita),
						'one' => q({0} hura),
						'other' => q({0} hura-ita),
						'per' => q({0} hura rupi),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrusegũdu-ita),
						'one' => q({0} mikrusegũdu),
						'other' => q({0} mikrusegũdu-ita),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrusegũdu-ita),
						'one' => q({0} mikrusegũdu),
						'other' => q({0} mikrusegũdu-ita),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(mirisegũdu-ita),
						'one' => q({0} mirisegũdu-ita),
						'other' => q({0} mirisegũdu rupi),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(mirisegũdu-ita),
						'one' => q({0} mirisegũdu-ita),
						'other' => q({0} mirisegũdu rupi),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minutu-ita),
						'one' => q({0} minutu),
						'other' => q({0} minutu-ita),
						'per' => q({0} minutu rupi),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minutu-ita),
						'one' => q({0} minutu),
						'other' => q({0} minutu-ita),
						'per' => q({0} minutu rupi),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(yasí-ita),
						'other' => q({0} yasí-ita),
						'per' => q({0} yasí rupi),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(yasí-ita),
						'other' => q({0} yasí-ita),
						'per' => q({0} yasí rupi),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanusegũdu-ita),
						'one' => q({0} nanusegũdu),
						'other' => q({0} nanusegũdu-ita),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanusegũdu-ita),
						'one' => q({0} nanusegũdu),
						'other' => q({0} nanusegũdu-ita),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(segũdu-ita),
						'one' => q({0} segũdu),
						'other' => q({0} segũdu-ita),
						'per' => q({0} segũdu rupi),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(segũdu-ita),
						'one' => q({0} segũdu),
						'other' => q({0} segũdu-ita),
						'per' => q({0} segũdu rupi),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sẽmãna-ita),
						'one' => q({0} sẽmãna),
						'other' => q({0} sẽmãna-ita),
						'per' => q({0} sẽmãna rupi),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sẽmãna-ita),
						'one' => q({0} sẽmãna),
						'other' => q({0} sẽmãna-ita),
						'per' => q({0} sẽmãna rupi),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(akayú-ita),
						'other' => q({0} akayú-ita),
						'per' => q({0} akayú rupi),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(akayú-ita),
						'other' => q({0} akayú-ita),
						'per' => q({0} akayú rupi),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ampere-ita),
						'one' => q({0} ampere),
						'other' => q({0} ampere-ita),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ampere-ita),
						'one' => q({0} ampere),
						'other' => q({0} ampere-ita),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miriampere-ita),
						'one' => q({0} miriampere),
						'other' => q({0} miriampere-ita),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miriampere-ita),
						'one' => q({0} miriampere),
						'other' => q({0} miriampere-ita),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohm-ita),
						'one' => q({0} ohm),
						'other' => q({0} ohm-ita),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohm-ita),
						'one' => q({0} ohm),
						'other' => q({0} ohm-ita),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(volt-ita),
						'one' => q({0} volt),
						'other' => q({0} volt-ita),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(volt-ita),
						'one' => q({0} volt),
						'other' => q({0} volt-ita),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(yepesawa sakusawa biritãnika-ita),
						'one' => q({0} yepesawa sakusawa biritãnika),
						'other' => q({0} yepesawa sakusawa biritãnika-ita),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(yepesawa sakusawa biritãnika-ita),
						'one' => q({0} yepesawa sakusawa biritãnika),
						'other' => q({0} yepesawa sakusawa biritãnika-ita),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(karuria),
						'one' => q({0} karuria),
						'other' => q({0} karuria-ita),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(karuria),
						'one' => q({0} karuria),
						'other' => q({0} karuria-ita),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elétron-volt-ita),
						'one' => q({0} elétron-volt),
						'other' => q({0} elétron-volt-ita),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elétron-volt-ita),
						'one' => q({0} elétron-volt),
						'other' => q({0} elétron-volt-ita),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Karuria),
						'one' => q({0} Karuria),
						'other' => q({0} Karuria-ita),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Karuria),
						'one' => q({0} Karuria),
						'other' => q({0} Karuria-ita),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(joule-ita),
						'one' => q({0} joule),
						'other' => q({0} joule-ita),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(joule-ita),
						'one' => q({0} joule),
						'other' => q({0} joule-ita),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kirukaruria-ita),
						'one' => q({0} kirukaruria),
						'other' => q({0} kirukaruria-ita),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kirukaruria-ita),
						'one' => q({0} kirukaruria),
						'other' => q({0} kirukaruria-ita),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kirujoule-ita),
						'one' => q({0} kirujoule),
						'other' => q({0} kirujoule-ita),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kirujoule-ita),
						'one' => q({0} kirujoule),
						'other' => q({0} kirujoule-ita),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kiruwatt-hura-ita),
						'one' => q({0} kiruwatt-hura),
						'other' => q({0} kiruwatt-hura-ita),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kiruwatt-hura-ita),
						'one' => q({0} kiruwatt-hura),
						'other' => q({0} kiruwatt-hura-ita),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(yepesawa sakusawa EUA-suí-ita),
						'one' => q({0} yepesawa sakusawa EUA-suí),
						'other' => q({0} yepesawa sakusawa EUA-suí-ita),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(yepesawa sakusawa EUA-suí-ita),
						'one' => q({0} yepesawa sakusawa EUA-suí),
						'other' => q({0} yepesawa sakusawa EUA-suí-ita),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newton-ita),
						'one' => q({0} newton),
						'other' => q({0} newton-ita),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newton-ita),
						'one' => q({0} newton),
						'other' => q({0} newton-ita),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(kirĩba libra-ita),
						'one' => q({0} kirĩba libra),
						'other' => q({0} kirĩba libra-ita),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(kirĩba libra-ita),
						'one' => q({0} kirĩba libra),
						'other' => q({0} kirĩba libra-ita),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigahertz-ita),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz-ita),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigahertz-ita),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz-ita),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(hertz-ita),
						'one' => q({0} hertz),
						'other' => q({0} hertz-ita),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(hertz-ita),
						'one' => q({0} hertz),
						'other' => q({0} hertz-ita),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kiruhertz-ita),
						'one' => q({0} kiruhertz),
						'other' => q({0} kiruhertz-ita),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kiruhertz-ita),
						'one' => q({0} kiruhertz),
						'other' => q({0} kiruhertz-ita),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megahertz-ita),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz-ita),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megahertz-ita),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz-ita),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(pitusá-ita sẽtimeturu rupi),
						'one' => q({0} pitusá sẽtimeturu rupi),
						'other' => q({0} pitusá-ita sẽtimeturu rupi),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(pitusá-ita sẽtimeturu rupi),
						'one' => q({0} pitusá sẽtimeturu rupi),
						'other' => q({0} pitusá-ita sẽtimeturu rupi),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(pitusá-ita puregada rupi),
						'one' => q({0} pitusá puregada rupi),
						'other' => q({0} pitusá-ita puregada rupi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(pitusá-ita puregada rupi),
						'one' => q({0} pitusá puregada rupi),
						'other' => q({0} pitusá-ita puregada rupi),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(tipografia em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(tipografia em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapikisel-ita),
						'one' => q({0} megapikisel),
						'other' => q({0} megapikisel-ita),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapikisel-ita),
						'one' => q({0} megapikisel),
						'other' => q({0} megapikisel-ita),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pikisel-ita),
						'one' => q({0} pikisel),
						'other' => q({0} pikisel-ita),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pikisel-ita),
						'one' => q({0} pikisel),
						'other' => q({0} pikisel-ita),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(pikisel-ita sẽtimeturu rupi),
						'one' => q({0} pikisel sẽtimeturu rupi),
						'other' => q({0} pikisel-ita sẽtimeturu rupi),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(pikisel-ita sẽtimeturu rupi),
						'one' => q({0} pikisel sẽtimeturu rupi),
						'other' => q({0} pikisel-ita sẽtimeturu rupi),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pikisel-ita puregada rupi),
						'one' => q({0} pikisel puregada rupi),
						'other' => q({0} pikisel-ita puregada rupi),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pikisel-ita puregada rupi),
						'one' => q({0} pikisel puregada rupi),
						'other' => q({0} pikisel-ita puregada rupi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(yepesawa iwakasara-ita),
						'one' => q({0} yepesawa iwakasara),
						'other' => q({0} yepesawa iwakasara-ita),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(yepesawa iwakasara-ita),
						'one' => q({0} yepesawa iwakasara),
						'other' => q({0} yepesawa iwakasara-ita),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sẽtimeturu-ita),
						'one' => q({0} sẽtimeturu),
						'other' => q({0} sẽtimeturu-ita),
						'per' => q({0} sẽtimeturu rupi),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sẽtimeturu-ita),
						'one' => q({0} sẽtimeturu),
						'other' => q({0} sẽtimeturu-ita),
						'per' => q({0} sẽtimeturu rupi),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(desimeturu-ita),
						'one' => q({0} desimeturu),
						'other' => q({0} desimeturu-ita),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(desimeturu-ita),
						'one' => q({0} desimeturu),
						'other' => q({0} desimeturu-ita),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(barasa-ita),
						'one' => q({0} barasa),
						'other' => q({0} barasa-ita),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(barasa-ita),
						'one' => q({0} barasa),
						'other' => q({0} barasa-ita),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(pí-ita),
						'other' => q({0} pí-ita),
						'per' => q({0} pí rupi),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(pí-ita),
						'other' => q({0} pí-ita),
						'per' => q({0} pí rupi),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlong-ita),
						'one' => q({0} furlong),
						'other' => q({0} furlong-ita),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong-ita),
						'one' => q({0} furlong),
						'other' => q({0} furlong-ita),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(puregada-ita),
						'one' => q({0} puregada),
						'other' => q({0} puregada-ita),
						'per' => q({0} puregada rupi),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(puregada-ita),
						'one' => q({0} puregada),
						'other' => q({0} puregada-ita),
						'per' => q({0} puregada rupi),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(apekatusawa-ita),
						'one' => q({0} apekatusawa),
						'other' => q({0} apekatusawa-ita),
						'per' => q({0} apekatusawa rupi),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(apekatusawa-ita),
						'one' => q({0} apekatusawa),
						'other' => q({0} apekatusawa-ita),
						'per' => q({0} apekatusawa rupi),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(akayú-werawa-ita),
						'other' => q({0} akayú-werawa-ita),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(akayú-werawa-ita),
						'other' => q({0} akayú-werawa-ita),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(meturu-ita),
						'one' => q({0} meturu),
						'other' => q({0} meturu-ita),
						'per' => q({0} meturu rupi),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(meturu-ita),
						'one' => q({0} meturu),
						'other' => q({0} meturu-ita),
						'per' => q({0} meturu rupi),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikrumeturu-ita),
						'one' => q({0} mikrumeturu),
						'other' => q({0} mikrumeturu-ita),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikrumeturu-ita),
						'one' => q({0} mikrumeturu),
						'other' => q({0} mikrumeturu-ita),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(milha-ita),
						'one' => q({0} milha),
						'other' => q({0} milha-ita),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milha-ita),
						'one' => q({0} milha),
						'other' => q({0} milha-ita),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(milha esikãdinaua-ita),
						'one' => q({0} milha esikãdinaua),
						'other' => q({0} milha esikãdinaua-ita),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(milha esikãdinaua-ita),
						'one' => q({0} milha esikãdinaua),
						'other' => q({0} milha esikãdinaua-ita),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(mirimeturu-ita),
						'one' => q({0} mirimeturu),
						'other' => q({0} mirimeturu-ita),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(mirimeturu-ita),
						'one' => q({0} mirimeturu),
						'other' => q({0} mirimeturu-ita),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanumeturu-ita),
						'one' => q({0} nanumeturu),
						'other' => q({0} nanumeturu-ita),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanumeturu-ita),
						'one' => q({0} nanumeturu),
						'other' => q({0} nanumeturu-ita),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(milha paranãuara-ita),
						'one' => q({0} milha paranãuara),
						'other' => q({0} milha paranãuara-ita),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(milha paranãuara-ita),
						'one' => q({0} milha paranãuara),
						'other' => q({0} milha paranãuara-ita),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsec-ita),
						'one' => q({0} parsec),
						'other' => q({0} parsec-ita),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsec-ita),
						'one' => q({0} parsec),
						'other' => q({0} parsec-ita),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(picometuru-ita),
						'one' => q({0} picometuru),
						'other' => q({0} picometuru-ita),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(picometuru-ita),
						'one' => q({0} picometuru),
						'other' => q({0} picometuru-ita),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pitusá-ita),
						'one' => q({0} pitusá),
						'other' => q({0} pitusá-ita),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pitusá-ita),
						'one' => q({0} pitusá),
						'other' => q({0} pitusá-ita),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(kuarasiawa-ita),
						'one' => q({0} kuarasiawa),
						'other' => q({0} kuarasiawa-ita),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(kuarasiawa-ita),
						'one' => q({0} kuarasiawa),
						'other' => q({0} kuarasiawa-ita),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(jarda-ita),
						'one' => q({0} jarda),
						'other' => q({0} jarda-ita),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(jarda-ita),
						'one' => q({0} jarda),
						'other' => q({0} jarda-ita),
					},
					# Long Unit Identifier
					'light-lux' => {
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(kuarasí muturisawa-ita),
						'one' => q({0} kuarasí muturisawa),
						'other' => q({0} kuarasí muturisawa-ita),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(kuarasí muturisawa-ita),
						'one' => q({0} kuarasí muturisawa),
						'other' => q({0} kuarasí muturisawa-ita),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(cuirate-ita),
						'one' => q({0} cuirate),
						'other' => q({0} cuirate-ita),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(cuirate-ita),
						'one' => q({0} cuirate),
						'other' => q({0} cuirate-ita),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(dalton-ita),
						'one' => q({0} dalton),
						'other' => q({0} dalton-ita),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(dalton-ita),
						'one' => q({0} dalton),
						'other' => q({0} dalton-ita),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(iwí susuẽga-ita),
						'one' => q({0} iwí susuẽga),
						'other' => q({0} iwí susuẽga-ita),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(iwí susuẽga-ita),
						'one' => q({0} iwí susuẽga),
						'other' => q({0} iwí susuẽga-ita),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grama-ita),
						'one' => q({0} grama),
						'other' => q({0} grama-ita),
						'per' => q({0} grama rupi),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grama-ita),
						'one' => q({0} grama),
						'other' => q({0} grama-ita),
						'per' => q({0} grama rupi),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(pusesawa-ita),
						'one' => q({0} pusesawa),
						'other' => q({0} pusesawa-ita),
						'per' => q({0} pusesawa rupi),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(pusesawa-ita),
						'one' => q({0} pusesawa),
						'other' => q({0} pusesawa-ita),
						'per' => q({0} pusesawa rupi),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mikrugrama-ita),
						'one' => q({0} mikrugrama),
						'other' => q({0} mikrugrama-ita),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mikrugrama-ita),
						'one' => q({0} mikrugrama),
						'other' => q({0} mikrugrama-ita),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(mirigrama-ita),
						'one' => q({0} mirigrama),
						'other' => q({0} mirigrama-ita),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(mirigrama-ita),
						'one' => q({0} mirigrama),
						'other' => q({0} mirigrama-ita),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(iauareté-ita),
						'one' => q({0} iauareté),
						'other' => q({0} iauareté-ita),
						'per' => q({0} iauareté rupi),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(iauareté-ita),
						'one' => q({0} iauareté),
						'other' => q({0} iauareté-ita),
						'per' => q({0} iauareté rupi),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(iauareté troy-ita),
						'one' => q({0} iauareté troy),
						'other' => q({0} iauareté troy-ita),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(iauareté troy-ita),
						'one' => q({0} iauareté troy),
						'other' => q({0} iauareté troy-ita),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(libra-ita),
						'one' => q({0} libra),
						'other' => q({0} libra-ita),
						'per' => q({0} libra rupi),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(libra-ita),
						'one' => q({0} libra),
						'other' => q({0} libra-ita),
						'per' => q({0} libra rupi),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(kuarasí susuẽga-ita),
						'one' => q({0} kuarasí susuẽga),
						'other' => q({0} kuarasí susuẽga-ita),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(kuarasí susuẽga-ita),
						'one' => q({0} kuarasí susuẽga),
						'other' => q({0} kuarasí susuẽga-ita),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stone-ita),
						'one' => q({0} stone),
						'other' => q({0} stone-ita),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stone-ita),
						'one' => q({0} stone),
						'other' => q({0} stone-ita),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tonerada-ita),
						'one' => q({0} tonerada),
						'other' => q({0} tonerada-ita),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tonerada-ita),
						'one' => q({0} tonerada),
						'other' => q({0} tonerada-ita),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(tonerada metirika-ita),
						'one' => q({0} tonerada metirika-ita),
						'other' => q({0} tonerada metirika-ita),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(tonerada metirika-ita),
						'one' => q({0} tonerada metirika-ita),
						'other' => q({0} tonerada metirika-ita),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} {1} rupi),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} {1} rupi),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigawatt-ita),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt-ita),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigawatt-ita),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt-ita),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(kawaru-wapú-ita),
						'one' => q({0} kawaru-wapú),
						'other' => q({0} kawaru-wapú-ita),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(kawaru-wapú-ita),
						'one' => q({0} kawaru-wapú),
						'other' => q({0} kawaru-wapú-ita),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kiruwatt-ita),
						'one' => q({0} kiruwatt),
						'other' => q({0} kiruwatt-ita),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kiruwatt-ita),
						'one' => q({0} kiruwatt),
						'other' => q({0} kiruwatt-ita),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(megawatt-ita),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt-ita),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(megawatt-ita),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt-ita),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(miriwatt-ita),
						'one' => q({0} miriwatt),
						'other' => q({0} miriwatt-ita),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(miriwatt-ita),
						'one' => q({0} miriwatt),
						'other' => q({0} miriwatt-ita),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(watt-ita),
						'one' => q({0} watt),
						'other' => q({0} watt-ita),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watt-ita),
						'one' => q({0} watt),
						'other' => q({0} watt-ita),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(yãgasawa-ita),
						'one' => q({0} yãgasawa),
						'other' => q({0} yãgasawa-ita),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(yãgasawa-ita),
						'one' => q({0} yãgasawa),
						'other' => q({0} yãgasawa-ita),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(bar-ita),
						'other' => q({0} bar-ita),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(bar-ita),
						'other' => q({0} bar-ita),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hectopascal-ita),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascal-ita),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hectopascal-ita),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascal-ita),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(merikuriju puregada-ita),
						'one' => q({0} merikuriju puregada),
						'other' => q({0} merikuriju puregada-ita),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(merikuriju puregada-ita),
						'one' => q({0} merikuriju puregada),
						'other' => q({0} merikuriju puregada-ita),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kirupascal-ita),
						'one' => q({0} kirupascal),
						'other' => q({0} kirupascal-ita),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kirupascal-ita),
						'one' => q({0} kirupascal),
						'other' => q({0} kirupascal-ita),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapascal-ita),
						'one' => q({0} megapascal),
						'other' => q({0} megapascal-ita),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapascal-ita),
						'one' => q({0} megapascal),
						'other' => q({0} megapascal-ita),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(miribar-ita),
						'one' => q({0} miribar),
						'other' => q({0} miribar-ita),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(miribar-ita),
						'one' => q({0} miribar),
						'other' => q({0} miribar-ita),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(merikuriju mirimeturu-ita),
						'one' => q({0} merikuriju mirimeturu),
						'other' => q({0} merikuriju mirimeturu-ita),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(merikuriju mirimeturu-ita),
						'one' => q({0} merikuriju mirimeturu),
						'other' => q({0} merikuriju mirimeturu-ita),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(pascal-ita),
						'one' => q({0} pascal),
						'other' => q({0} pascal-ita),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(pascal-ita),
						'one' => q({0} pascal),
						'other' => q({0} pascal-ita),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(libra-ita puregada kuadaradu rupi),
						'one' => q({0} libra puregada kuadaradu rupi),
						'other' => q({0} libra-ita puregada kuadaradu rupi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(libra-ita puregada kuadaradu rupi),
						'one' => q({0} libra puregada kuadaradu rupi),
						'other' => q({0} libra-ita puregada kuadaradu rupi),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(apekatusawa-ita hura rupi),
						'one' => q({0} apekatusawa hura rupi),
						'other' => q({0} apekatusawa-ita hura rupi),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(apekatusawa-ita hura rupi),
						'one' => q({0} apekatusawa hura rupi),
						'other' => q({0} apekatusawa-ita hura rupi),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(kitanga-ita),
						'other' => q({0} kitanga-ita),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(kitanga-ita),
						'other' => q({0} kitanga-ita),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(meturu-ita segũdu rupi),
						'one' => q({0} meturu segũdu rupi),
						'other' => q({0} meturu-ita segũdu rupi),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(meturu-ita segũdu rupi),
						'one' => q({0} meturu segũdu rupi),
						'other' => q({0} meturu-ita segũdu rupi),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(milha-ita hura rupi),
						'one' => q({0} milha hura rupi),
						'other' => q({0} milha-ita hura rupi),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(milha-ita hura rupi),
						'one' => q({0} milha hura rupi),
						'other' => q({0} milha-ita hura rupi),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(garau Celsius-ita),
						'one' => q({0} garau Celsius),
						'other' => q({0} garau Celsius-ita),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(garau Celsius-ita),
						'one' => q({0} garau Celsius),
						'other' => q({0} garau Celsius-ita),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(garau Fahrenheit-ita),
						'one' => q({0} garau Fahrenheit),
						'other' => q({0} garau Fahrenheit-ita),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(garau Fahrenheit-ita),
						'one' => q({0} garau Fahrenheit),
						'other' => q({0} garau Fahrenheit-ita),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvin-ita),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin-ita),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvin-ita),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin-ita),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(newton-meturu-ita),
						'one' => q({0} newton-meturu),
						'other' => q({0} newton-meturu-ita),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newton-meturu-ita),
						'one' => q({0} newton-meturu),
						'other' => q({0} newton-meturu-ita),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pí-libra),
						'one' => q({0} pí-libra),
						'other' => q({0} pí-libra-ita),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pí-libra),
						'one' => q({0} pí-libra),
						'other' => q({0} pí-libra-ita),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acre-pí-ita),
						'other' => q({0} acre-pí-ita),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre-pí-ita),
						'other' => q({0} acre-pí-ita),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(bariu-ita),
						'one' => q({0} bariu),
						'other' => q({0} bariu-ita),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(bariu-ita),
						'one' => q({0} bariu),
						'other' => q({0} bariu-ita),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sẽtiritru-ita),
						'one' => q({0} sẽtiritru),
						'other' => q({0} sẽtiritru-ita),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sẽtiritru-ita),
						'one' => q({0} sẽtiritru),
						'other' => q({0} sẽtiritru-ita),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(sẽtimeturu kúbiku-ita),
						'one' => q({0} sẽtimeturu kúbiku),
						'other' => q({0} sẽtimeturu kúbiku-ita),
						'per' => q({0} sẽtimeturu kúbiku rupi),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(sẽtimeturu kúbiku-ita),
						'one' => q({0} sẽtimeturu kúbiku),
						'other' => q({0} sẽtimeturu kúbiku-ita),
						'per' => q({0} sẽtimeturu kúbiku rupi),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(pí kúbiku-ita),
						'one' => q({0} pí kúbiku),
						'other' => q({0} pí kúbiku-ita),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(pí kúbiku-ita),
						'one' => q({0} pí kúbiku),
						'other' => q({0} pí kúbiku-ita),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(puregada kúbika-ita),
						'one' => q({0} puregada kúbika),
						'other' => q({0} puregada kúbika-ita),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(puregada kúbika-ita),
						'one' => q({0} puregada kúbika),
						'other' => q({0} puregada kúbika-ita),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(apekatusawa kúbiku-ita),
						'one' => q({0} apekatusawa kúbiku),
						'other' => q({0} apekatusawa kúbiku-ita),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(apekatusawa kúbiku-ita),
						'one' => q({0} apekatusawa kúbiku),
						'other' => q({0} apekatusawa kúbiku-ita),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(meturu kúbiku-ita),
						'one' => q({0} meturu kúbiku),
						'other' => q({0} meturu kúbiku-ita),
						'per' => q({0} meturu kúbiku rupi),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(meturu kúbiku-ita),
						'one' => q({0} meturu kúbiku),
						'other' => q({0} meturu kúbiku-ita),
						'per' => q({0} meturu kúbiku rupi),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(milha kúbika-ita),
						'one' => q({0} milha kúbika),
						'other' => q({0} milha kúbika-ita),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(milha kúbika-ita),
						'one' => q({0} milha kúbika),
						'other' => q({0} milha kúbika-ita),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(jarda kúbika-ita),
						'one' => q({0} jarda kúbika),
						'other' => q({0} jarda kúbika-ita),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(jarda kúbika-ita),
						'one' => q({0} jarda kúbika),
						'other' => q({0} jarda kúbika-ita),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(xikara-ita),
						'one' => q({0} xikara),
						'other' => q({0} xikara-ita),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(xikara-ita),
						'one' => q({0} xikara),
						'other' => q({0} xikara-ita),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(xikara métirika-ita),
						'one' => q({0} xikara métirika),
						'other' => q({0} xikara métirika-ita),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(xikara métirika-ita),
						'one' => q({0} xikara métirika),
						'other' => q({0} xikara métirika-ita),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(desiritru-ita),
						'one' => q({0} desiritru),
						'other' => q({0} desiritru-ita),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(desiritru-ita),
						'one' => q({0} desiritru),
						'other' => q({0} desiritru-ita),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(iauareté fruida-ita),
						'one' => q({0} iauareté fruida),
						'other' => q({0} iauareté fruida-ita),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(iauareté fruida-ita),
						'one' => q({0} iauareté fruida),
						'other' => q({0} iauareté fruida-ita),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(iauareté fruida ĩperiawa-ita),
						'one' => q({0} iauareté fruida ĩperiawa),
						'other' => q({0} iauareté fruida ĩperiawa-ita),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(iauareté fruida ĩperiawa-ita),
						'one' => q({0} iauareté fruida ĩperiawa),
						'other' => q({0} iauareté fruida ĩperiawa-ita),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(karóti-ita),
						'one' => q({0} karóti),
						'other' => q({0} karóti-ita),
						'per' => q({0} karóti rupi),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(karóti-ita),
						'one' => q({0} karóti),
						'other' => q({0} karóti-ita),
						'per' => q({0} karóti rupi),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(karóti ĩperiawa-ita),
						'one' => q({0} karóti ĩperiawa),
						'other' => q({0} karóti ĩperiawa-ita),
						'per' => q({0} karóti ĩperiawa rupi),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(karóti ĩperiawa-ita),
						'one' => q({0} karóti ĩperiawa),
						'other' => q({0} karóti ĩperiawa-ita),
						'per' => q({0} karóti ĩperiawa rupi),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hectoritru-ita),
						'one' => q({0} hectoritru),
						'other' => q({0} hectoritru-ita),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hectoritru-ita),
						'one' => q({0} hectoritru),
						'other' => q({0} hectoritru-ita),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(irerú-pukú-ita),
						'one' => q({0} irerú-pukú),
						'other' => q({0} irerú-pukú-ita),
						'per' => q({0} irerú-pukú rupi),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(irerú-pukú-ita),
						'one' => q({0} irerú-pukú),
						'other' => q({0} irerú-pukú-ita),
						'per' => q({0} irerú-pukú rupi),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megaritru-ita),
						'one' => q({0} megaritru),
						'other' => q({0} megaritru-ita),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megaritru-ita),
						'one' => q({0} megaritru),
						'other' => q({0} megaritru-ita),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(miriritru-ita),
						'one' => q({0} miriritru),
						'other' => q({0} miriritru-ita),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(miriritru-ita),
						'one' => q({0} miriritru),
						'other' => q({0} miriritru-ita),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pint-ita),
						'one' => q({0} pint),
						'other' => q({0} pint-ita),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pint-ita),
						'one' => q({0} pint),
						'other' => q({0} pint-ita),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(pint métiriku-ita),
						'one' => q({0} pint métiriku),
						'other' => q({0} pint métiriku-ita),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pint métiriku-ita),
						'one' => q({0} pint métiriku),
						'other' => q({0} pint métiriku-ita),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(irundisawa-ita),
						'one' => q({0} irundisawa),
						'other' => q({0} irundisawa-ita),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(irundisawa-ita),
						'one' => q({0} irundisawa),
						'other' => q({0} irundisawa-ita),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(kuyera-kaĩbewara-ita),
						'one' => q({0} kuyera-kaĩbewara),
						'other' => q({0} kuyera-kaĩbewara-ita),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(kuyera-kaĩbewara-ita),
						'one' => q({0} kuyera-kaĩbewara),
						'other' => q({0} kuyera-kaĩbewara-ita),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(kuyera xawara-ita),
						'one' => q({0} kuyera xawara),
						'other' => q({0} kuyera-ita xawara),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(kuyera xawara-ita),
						'one' => q({0} kuyera xawara),
						'other' => q({0} kuyera-ita xawara),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} acre),
						'other' => q({0} acre),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} acre),
						'other' => q({0} acre),
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
					'coordinate' => {
						'east' => q({0}L),
						'west' => q({0}O),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}L),
						'west' => q({0}O),
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
						'name' => q(Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TB),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ms),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/seg),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/seg),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sem.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sem.),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0} bsa.),
						'other' => q({0} bsa.),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0} bsa.),
						'other' => q({0} bsa.),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(pí-ita),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(pí-ita),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mil),
						'one' => q({0} milha),
						'other' => q({0} milha),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mil),
						'one' => q({0} milha),
						'other' => q({0} milha),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q({0} ql),
						'other' => q({0} ql),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0} ql),
						'other' => q({0} ql),
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
					'mass-stone' => {
						'name' => q(stone),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stone),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(ton),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(ton),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(ft³),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fl. oz.),
						'one' => q({0} fl. oz.),
						'other' => q({0} fl. oz.),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl. oz.),
						'one' => q({0} fl. oz.),
						'other' => q({0} fl. oz.),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(irerú-pukú),
						'one' => q({0}l),
						'other' => q({0}l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(irerú-pukú),
						'one' => q({0}l),
						'other' => q({0}l),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(mupikasawa),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(mupikasawa),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(kirĩba g),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(kirĩba g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(meturu-itá/seg²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(meturu-itá/seg²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'other' => q({0} arcmin),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'other' => q({0} arcmin),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arcseg),
						'other' => q({0} arcseg),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arcseg),
						'other' => q({0} arcseg),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(garau),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(garau),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radiano),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radiano),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunan),
						'other' => q({0} dunan),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunan),
						'other' => q({0} dunan),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(pí-itá²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(pí-itá²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(puregada-itá²),
						'other' => q({0} pur²),
						'per' => q({0} pur² rupi),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(puregada-itá²),
						'other' => q({0} pur²),
						'per' => q({0} pur² rupi),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(meturu-itá²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(meturu-itá²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(milha-itá²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(milha-itá²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(jarda-itá²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(jarda-itá²),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(kirate),
						'other' => q({0} k),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(kirate),
						'other' => q({0} k),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'other' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'other' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mirimol/ritru),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mirimol/ritru),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(sẽtu rupi),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(sẽtu rupi),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(mil rupi),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(mil rupi),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(pisawera miliãu rupi),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(pisawera miliãu rupi),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(pitusá-pitasukasá),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(pitusá-pitasukasá),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'other' => q({0} l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100 km),
						'other' => q({0} l/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(ritru-itá/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(ritru-itá/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(milha-itá/gal),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(milha-itá/gal),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(milhas/gal. imp.),
						'other' => q({0} mpg imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(milhas/gal. imp.),
						'other' => q({0} mpg imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} L),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} L),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gbit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gbit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GByte),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GByte),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kbit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kbit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kByte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kByte),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mbit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mbit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MByte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MByte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PByte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PByte),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tbit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tbit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TByte),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TByte),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(sék.),
						'one' => q({0} sék.),
						'other' => q({0} sék),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(sék.),
						'one' => q({0} sék.),
						'other' => q({0} sék),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ara),
						'other' => q({0} ara),
						'per' => q({0}/ara),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ara),
						'other' => q({0} ara),
						'per' => q({0}/ara),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dék.),
						'one' => q({0} dék.),
						'other' => q({0} dék),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dék.),
						'one' => q({0} dék.),
						'other' => q({0} dék),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(hura),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(hura),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(mirisegũdu),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(mirisegũdu),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(yasí),
						'other' => q({0} yasí),
						'per' => q({0}/yasí),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(yasí),
						'other' => q({0} yasí),
						'per' => q({0}/yasí),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(seg),
						'other' => q({0} seg),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(seg),
						'other' => q({0} seg),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sẽmãna),
						'one' => q({0} sem.),
						'other' => q({0} sem),
						'per' => q({0}/sem.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sẽmãna),
						'one' => q({0} sem.),
						'other' => q({0} sem),
						'per' => q({0}/sem.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(akayú),
						'other' => q({0} akayú),
						'per' => q({0}/akayú),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(akayú),
						'other' => q({0} akayú),
						'per' => q({0}/akayú),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miriamp),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miriamp),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(BTU),
						'other' => q({0} BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTU),
						'other' => q({0} BTU),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elétron-volt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elétron-volt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kirujoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kirujoule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kW-hura),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kW-hura),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(thm EUA),
						'other' => q({0} thm EUA),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(thm EUA),
						'other' => q({0} thm EUA),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(libra-kirĩba),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(libra-kirĩba),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapixel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapixel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pixel),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pixel),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(ua),
						'other' => q({0} ua),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ua),
						'other' => q({0} ua),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(barasa),
						'other' => q({0} brs.),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(barasa),
						'other' => q({0} brs.),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(pí-itá),
						'other' => q({0} pí),
						'per' => q({0}/pí),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(pí-itá),
						'other' => q({0} pí),
						'per' => q({0}/pí),
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
						'name' => q(pur.),
						'other' => q({0} pur.),
						'per' => q({0}/pur.),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(pur.),
						'other' => q({0} pur.),
						'per' => q({0}/pur.),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(akayú-werawa),
						'other' => q({0} akayú-werawa),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(akayú-werawa),
						'other' => q({0} akayú-werawa),
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
					'length-mile' => {
						'name' => q(milha),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milha),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(mn),
						'other' => q({0} mn),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(mn),
						'other' => q({0} mn),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsec),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsec),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pitusá),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pitusá),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(kuarasiawa),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(kuarasiawa),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(jarda),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(jarda),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(kuarasí muturisawa),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(kuarasí muturisawa),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(cuirate),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(cuirate),
						'other' => q({0} ct),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(iwí susuẽga),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(iwí susuẽga),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grama),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grama),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz troy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz troy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(libra),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(libra),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(kuarasí susuẽga),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(kuarasí susuẽga),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stones),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stones),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tonerada),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tonerada),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(cv),
						'other' => q({0} cv),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(cv),
						'other' => q({0} cv),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mmHg),
						'other' => q({0} mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mmHg),
						'other' => q({0} mmHg),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(kitanga),
						'other' => q({0} kitanga),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(kitanga),
						'other' => q({0} kitanga),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(meturu/seg),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(meturu/seg),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(milha-itá/hura),
						'other' => q({0} mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(milha-itá/hura),
						'other' => q({0} mph),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(garau C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(garau C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(garau F),
						'other' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(garau F),
						'other' => q({0} °F),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acre-pí),
						'other' => q({0} acre-pí),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre-pí),
						'other' => q({0} acre-pí),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(koroti),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(koroti),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cl),
						'other' => q({0} cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cl),
						'other' => q({0} cl),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(pí-itá³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(pí-itá³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(puregada-irá³),
						'other' => q({0} pur³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(puregada-irá³),
						'other' => q({0} pur³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(jarda-itá³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(jarda-itá³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(xíkara),
						'one' => q({0} xík.),
						'other' => q({0} xík),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(xíkara),
						'one' => q({0} xík.),
						'other' => q({0} xík),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(xícm),
						'other' => q({0} xícm),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(xícm),
						'other' => q({0} xícm),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dl),
						'other' => q({0} dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dl),
						'other' => q({0} dl),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gal. imp.),
						'other' => q({0} gal. imp.),
						'per' => q({0}/gal. imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal. imp.),
						'other' => q({0} gal. imp.),
						'per' => q({0}/gal. imp.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hl),
						'other' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hl),
						'other' => q({0} hl),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litros),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litros),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(Ml),
						'other' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(Ml),
						'other' => q({0} Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ml),
						'other' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ml),
						'other' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pint),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pint),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(ptm),
						'other' => q({0} ptm),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(ptm),
						'other' => q({0} ptm),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(qts),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(qts),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(k. kaĩbewara),
						'other' => q({0} k. kaĩbewara),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(k. kaĩbewara),
						'other' => q({0} k. kaĩbewara),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(k. xawara),
						'other' => q({0} k. xawara),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(k. xawara),
						'other' => q({0} k. xawara),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:eẽ|e|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ũbaá|u|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} asuí {1}),
				2 => q({0} asuí {1}),
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
					'one' => '0 miu',
					'other' => '0 miu',
				},
				'10000' => {
					'one' => '00 miu',
					'other' => '00 miu',
				},
				'100000' => {
					'one' => '000 miu',
					'other' => '000 miu',
				},
				'1000000' => {
					'one' => '0 miliãu',
					'other' => '0 miliãu-ita',
				},
				'10000000' => {
					'one' => '00 miliãu',
					'other' => '00 miliãu-ita',
				},
				'100000000' => {
					'one' => '000 miliãu',
					'other' => '000 miliãu-ita',
				},
				'1000000000' => {
					'one' => '0 biliãu',
					'other' => '0 biliãu-ita',
				},
				'10000000000' => {
					'one' => '00 biliãu',
					'other' => '00 biliãu-ita',
				},
				'100000000000' => {
					'one' => '000 biliãu',
					'other' => '000 biliãu-ita',
				},
				'1000000000000' => {
					'one' => '0 tiriliãu',
					'other' => '0 tiriliãu-ita',
				},
				'10000000000000' => {
					'one' => '00 tiriliãu',
					'other' => '00 tiriliãu-ita',
				},
				'100000000000000' => {
					'one' => '000 tiriliãu',
					'other' => '000 tiriliãu-ita',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 miu',
					'other' => '0 miu',
				},
				'10000' => {
					'one' => '00 miu',
					'other' => '00 miu',
				},
				'100000' => {
					'one' => '000 miu',
					'other' => '000 miu',
				},
				'1000000' => {
					'one' => '0 mi',
					'other' => '0 mi',
				},
				'10000000' => {
					'one' => '00 mi',
					'other' => '00 mi',
				},
				'100000000' => {
					'one' => '000 mi',
					'other' => '000 mi',
				},
				'1000000000' => {
					'one' => '0 bi',
					'other' => '0 bi',
				},
				'10000000000' => {
					'one' => '00 bi',
					'other' => '00 bi',
				},
				'100000000000' => {
					'one' => '000 bi',
					'other' => '000 bi',
				},
				'1000000000000' => {
					'one' => '0 tiri',
					'other' => '0 tiri',
				},
				'10000000000000' => {
					'one' => '00 tiri',
					'other' => '00 tiri',
				},
				'100000000000000' => {
					'one' => '000 tiri',
					'other' => '000 tiri',
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
				'currency' => q(Peseta Ãdurawara),
				'one' => q(Peseta Ãdurawara),
				'other' => q(Peseta-ita Ãdurawara),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(Dirhã Emiradu-ita Árabe Yepewasú),
				'one' => q(Dirhã EAU suí),
				'other' => q(Dirhã-ita EAU suí),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Afegani \(1927–2002\)),
				'one' => q(Afegani Afegãniretãma suí \(AFA\)),
				'other' => q(Afegani-ita Afegãniretãma suí \(AFA\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afegani afegawara),
				'one' => q(Afegani afegawara),
				'other' => q(Afegani-ita afegawara),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(Reki Aubaniawara \(1946–1965\)),
				'one' => q(Reki Aubaniawara \(1946–1965\)),
				'other' => q(Reki-ita Aubaniawara \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Reki aubanei),
				'one' => q(Reki aubanei),
				'other' => q(Reki-ita aubanei),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Darã arimeniawara),
				'one' => q(Darã arimeniawara),
				'other' => q(Darã-ita arimeniawara),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Fulurĩ Ãtíria Hurãdawara),
				'one' => q(Fulurĩ Ãtíria Hurãdawara),
				'other' => q(Fulurĩ-ita Ãtíria Hurãdawara),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kuãsa ãgulawara),
				'one' => q(Kuãsa ãgulawara),
				'other' => q(Kuãsa-ita ãgulawara),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Kuãsa ãgulawara \(1977–1990\)),
				'one' => q(Kuãsa ãgulawara \(AOK\)),
				'other' => q(Kuãsa-ita ãgulawara \(AOK\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Kuãsa ãgulawara pisasuwa \(1990–2000\)),
				'one' => q(Kuãsa ãgulawara pisasuwa \(AON\)),
				'other' => q(Kuãsa-ita ãgulawara pisasuwa-ita \(AON\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Kuãsa ãgulawara yumũnhãwa yuiri \(1995–1999\)),
				'one' => q(Kuãsa ãgulawara yumunhãwa yuiri \(AOR\)),
				'other' => q(Kuãsa-ita ãgulawara yumunhãwa-ita yuiri \(AOR\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Austarau Argẽtinawara),
				'one' => q(Austarau Argẽtinawara),
				'other' => q(Austarau-ita Argẽtinawara),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(Pusewa tekú Argẽtinawara \(1970–1983\)),
				'one' => q(Pusewa tekú Argẽtinawara \(1970–1983\)),
				'other' => q(Pusewa-ita tekú Argẽtinawara \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(Pusewa argẽtinu \(1981–1970\)),
				'one' => q(Pusewa argẽtinu \(1981–1970\)),
				'other' => q(Pusewa-ita argẽtinu-ita \(1981–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Pusewa argẽtinu \(1983–1985\)),
				'one' => q(Pusewa argẽtinu \(1983–1985\)),
				'other' => q(Pusewa-ita argẽtinu-ita \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Pusewa argẽtinu),
				'one' => q(Pusewa argẽtinu),
				'other' => q(Pusewa-ita argẽtinu-ita),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Xirĩ ausitíriaku),
				'one' => q(Xirĩ ausitíriaku),
				'other' => q(Xirĩ-ita ausitíriaku-ita),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(Dóra Ausitaraliwara),
				'one' => q(Dóra Ausitaraliwara),
				'other' => q(Dóra-ita Ausitaraliwara),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Fulurĩ Arubawara),
				'one' => q(Fulurĩ Arubawara),
				'other' => q(Fulurĩ-ita Arubawara),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Manati Aseriretãmawara \(1993–2006\)),
				'one' => q(Manati Aseriretãmawara \(1993–2006\)),
				'other' => q(Manati-ita Aseriretãmawara \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Manati aseri),
				'one' => q(Manati aseri),
				'other' => q(Manati-ita aseri-ita),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Dinari Businiya-Eseguwinawara \(1992–1994\)),
				'one' => q(Dinari Businiya-Eseguwinawara),
				'other' => q(Dinari-ita Businiya-Eseguwinawara),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Marku yumuyerewa Businiya-Eseguwinawara),
				'one' => q(Marku yumuyerewa Businiya-Eseguwinawara),
				'other' => q(Marku yumuyerewa-ita Businiya-Eseguwinawara),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(Dinari Pisasuwa Businiya-Eseguwinawara \(1994–1997\)),
				'one' => q(Dinari Pisasuwa Businiya-Eseguwinawara),
				'other' => q(Dinari Pisasuwa-ita Businiya-Eseguwinawara),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Dóra barbaduwara),
				'one' => q(Dóra barbaduwara),
				'other' => q(Dóra-ita barbaduwara),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka Bẽgariwara),
				'one' => q(Taka Bẽgariwara),
				'other' => q(Taka-ita Bẽgariwara),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Farãku Beujikawara \(yumuyereuwa\)),
				'one' => q(Farãku Beujikawara \(yumuyereuwa\)),
				'other' => q(Farãku-ita Beujikawara \(yumuyereuwa-ita\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Farãku Beujikawara),
				'one' => q(Farãku Beujikawara),
				'other' => q(Farãku-ita Beujikawara),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Farãku Beujikawara \(finãseru\)),
				'one' => q(Farãku Beujikawara \(finãseru\)),
				'other' => q(Farãku-ita Beujikawara \(finãseru\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Revi Kirĩbawa Bugariyawara),
				'one' => q(Revi Kirĩbawa Bugariyawara),
				'other' => q(Revi-ita Kirĩbawa Bugariyawara),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(Revi Susiaritawa Bugariyawara),
				'one' => q(Revi Susiaritawa Bugariyawara),
				'other' => q(Revi-ita Susiaritawa Bugariyawara),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Revi Bugariyawara),
				'one' => q(Revi Bugariyawara),
				'other' => q(Revi-ita Bugariyawara),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(Revi Bugariyawara \(1879–1952\)),
				'one' => q(Revi Bugariyawara \(1879–1952\)),
				'other' => q(Revi-ita Bugariyawara \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinari Barẽiwara),
				'one' => q(Dinari Barẽiwara),
				'other' => q(Dinari-ita Barẽiwara),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Farãku Burũdiwara),
				'one' => q(Farãku Burũdiwara),
				'other' => q(Farãku-ita Burũdiwara),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Dóra Bemudawara),
				'one' => q(Dóra Bemudawara),
				'other' => q(Dóra-ita Bemudawara),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Dóra Buruneiwara),
				'one' => q(Dóra Buruneiwara),
				'other' => q(Dóra-ita Buruneiwara),
			},
		},
		'BOB' => {
			symbol => 'BUB',
			display_name => {
				'currency' => q(Buriwiyanu Buríwia suí),
				'one' => q(Buriwiyanu Buriwia suí),
				'other' => q(Buriwiyanu-ita Buríwia suí),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(Buriwiyanu \(1863–1963\)),
				'one' => q(Buriwiyanu \(1863–1963\)),
				'other' => q(Buriwiyanu-ita \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Pusewa buriwiyanu),
				'one' => q(Pusewa buriwiyanu),
				'other' => q(Pusewa-ita buriwiyanu),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Mvdol buriwiyanu),
				'one' => q(Mvdol buriwiyanu),
				'other' => q(Mvdol-ita buriwiyanu),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Kuruseru Pisasuwa Brasiuwara \(1967–1986\)),
				'one' => q(Kuruseru Pisasuwa Brasiuwara \(BRB\)),
				'other' => q(Kuruseru-ita Pisasuwa-ita Brasiuwara \(BRB\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Kurusadu Brasiuwara \(1986–1989\)),
				'one' => q(Kurusadu Brasiuwara),
				'other' => q(Kurusadu-ita Brasiuwara),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Kuruseru Brasiuwara \(1990–1993\)),
				'one' => q(Kuruseru Brasiuwara \(BRE\)),
				'other' => q(Kuruseru-ita Brasiuwara \(BRE\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Reau Brasiuwara),
				'one' => q(Reau Brasiuwara),
				'other' => q(Reau-ita Brasiuwara),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Kurusadu Pisasuwa Brasiuwara \(1989–1990\)),
				'one' => q(Kurusadu Pisasuwa Brasiuwara),
				'other' => q(Kurusadu-ita Pisasuwa-ita Brasiuwara),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Kuruseiru Brasiuwara \(1993–1994\)),
				'one' => q(Kuruseiru Brasiuwara),
				'other' => q(Kuruseiru-ita Brasiuwara),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(Kuruseiru Brasiuwara \(1942–1967\)),
				'one' => q(Kuruseiru Brasiuwara kuxiímawara),
				'other' => q(Kuruseiru-ita Brasiuwara kuxiímawara),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Dóra Bayamawara),
				'one' => q(Dóra Bayamawara),
				'other' => q(Dóra-ita Bayamawara),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ĩguturũ Butãwara),
				'one' => q(Ĩguturũ Butãwara),
				'other' => q(Ĩguturũ-ita Butãwara),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Kiati Bimãniyawara),
				'one' => q(Kiati Bimãniyawara),
				'other' => q(Kiati-ita Bimãniyawara),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pura Butisuwanawara),
				'one' => q(Pura Butisuwanawara),
				'other' => q(Pura-ita Butisuwanawara),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Ruburu Pisasuwa Bieru-rusiyawara \(1994–1999\)),
				'one' => q(Ruburu Pisasuwa Bieru-rusiyawara \(BYB\)),
				'other' => q(Ruburu Pisasuwaita Bieru-rusiyawara \(BYB\)),
			},
		},
		'BYN' => {
			symbol => 'p.',
			display_name => {
				'currency' => q(Ruburu bieruruso),
				'one' => q(Ruburu bieruruso),
				'other' => q(Ruburu bieruruso-ita),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Ruburu bieruruso \(2000–2016\)),
				'one' => q(Ruburu bieruruso \(2000–2016\)),
				'other' => q(Ruburu bieruruso-ita \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Dóra Belisiwara),
				'one' => q(Dóra Belisiwara),
				'other' => q(Dóra-ita Belisiwara),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dóra Kanadáwara),
				'one' => q(Dóra Kanadáwara),
				'other' => q(Dóra-ita Kanadáwara),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Farãku Kũguwara),
				'one' => q(Farãku Kũguwara),
				'other' => q(Farãku-ita Kũguwara),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(Euru WIR),
				'one' => q(Euru WIR),
				'other' => q(Euru WIR-ita),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Farãku Suwisawara),
				'one' => q(Farãku Suwisawara),
				'other' => q(Farãku-ita Suwisawara),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(Farãku WIR),
				'one' => q(Farãku WIR),
				'other' => q(Farãku-ita WIR),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(Warakapá Xiriwara),
				'one' => q(Warakapá Xiriwara),
				'other' => q(Warakapá-ita Xiriwara),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Yepesawa-ita Muapiresawa Xiriwara),
				'one' => q(Yepesawa Muapiresawa Xiriwara),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Pusewa Xiriwara),
				'one' => q(Pusewa Xiriwara),
				'other' => q(Pusewa-ita Xiriwara),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yuwã Xinawara \(offshore\)),
				'one' => q(Yuwã Xinawara \(offshore\)),
				'other' => q(Yuwã-ita Xinawara \(offshore\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(Dóra Bãku Pupulari Xinawara suí),
				'one' => q(Dóra Bãku Pupulari Xinawara suí),
				'other' => q(Dóra-ita Bãku Pupulari Xinawara suí),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuwã Xinawara),
				'one' => q(Yuwã Xinawara),
				'other' => q(Yuwã-ita Xinawara),
			},
		},
		'COP' => {
			symbol => '$',
			display_name => {
				'currency' => q(Peso Kurũbiyawara),
				'one' => q(Peso Kurũbiyawara),
				'other' => q(Pusewa-ita Kurũbiyawara),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(Yepesawa Sepisawa Reau suiwara),
				'one' => q(Yepesawa Sepisawa Reau suiwara),
				'other' => q(Yepesawa-ita Sepisawa Reau suiwara),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Kurũ Kupe-Rikawara),
				'one' => q(Kurũ Kupe-Rikawara),
				'other' => q(Kurũ-ita Kupe-Rikawara),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Dinari Sewiyawara \(2002–2006\)),
				'other' => q(Dinari Kuxiímawara Sewiyawara),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Kuruwa Kirĩbawa Xekusirowaka),
				'one' => q(Kuruwa Kirĩbawa Xekusirowaka),
				'other' => q(Kuruwa Kirĩbawa-ita Xekusirowaka),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Pusewa Kubawara Yumuyerewa),
				'one' => q(Pusewa Kubawara Yumuyerewa),
				'other' => q(Pusewa-ita Kubawara Yumuyerewa),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Pusewa Kubawara),
				'one' => q(Pusewa Kubawara),
				'other' => q(Pusewa-ita Kubawara),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Warakapá Kabu-Suikiriwara),
				'one' => q(Warakapá Kabu-Suikiriwara),
				'other' => q(Warakapá-ita Kabu-Suikiriwara),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Ribara Xipiriwara),
				'one' => q(Ribara Xipiriwara),
				'other' => q(Ribara-ita Xipiriwara),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Kuruwa Xekawara),
				'one' => q(Kuruwa Xekawara),
				'other' => q(Kuruwa-ita Xekawara),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Ostmark Aremãya Uriẽtawara),
				'one' => q(Marku Aremãya Uriẽtawara),
				'other' => q(Marku-ita Aremãya Uriẽtawara),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Marku Aremãyawara),
				'one' => q(Marku Aremãyawara),
				'other' => q(Marku-ita Aremãyawara),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Farãku Digibutiwara),
				'one' => q(Farãku Digibutiwara),
				'other' => q(Farãku-ita Digibutiwara),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Kuruwa Dinamakawara),
				'one' => q(Kuruwa Dinamakawara),
				'other' => q(Kuruwa-ita Dinamakawara),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Pusewa Dominikawara),
				'one' => q(Pusewa Dominikawara),
				'other' => q(Pusewa-ita Dominikawara),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinari Argeriyawra),
				'one' => q(Dinari Argeriyawra),
				'other' => q(Dinari-ita Argeriyawra),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Sukiri Ekuaduwara),
				'one' => q(Sukiri Ekuaduwara),
				'other' => q(Sukiri-ita Ekuaduwara),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Yepesawa Sepisawa Piá-sãtá \(UVS\) Ekuaduwara),
				'one' => q(Yepesawa Sepisawa Piá-sãtá \(UVS\) Ekuaduwara),
				'other' => q(Yepesawa-ita Sepisawa Piá-sãtá \(UVS\) Ekuaduwara),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Kuruwa Isituniyawara),
				'one' => q(Kuruwa Isituniyawara),
				'other' => q(Kuruwa-ita Isituniyawara),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Ribara Egituwara),
				'one' => q(Ribara Egituwara),
				'other' => q(Ribara-ita Egituwara),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakiwa Eritireyawara),
				'one' => q(Nakiwa Eritireyawara),
				'other' => q(Nakiwa-ita Eritireyawara),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(Peseta Isipãyawara \(kãta A\)),
				'one' => q(Peseta Isipãyawara \(kãta A\)),
				'other' => q(Peseta-ita Isipãyawara \(kãta A\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(Peseta Isipãyawara \(kãta yumuyerewa\)),
				'one' => q(Peseta Isipãyawara \(kãta yumuyerewa\)),
				'other' => q(Peseta-ita Isipãyawara \(kãta yumuyerewa\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Peseta Isipãyawara),
				'one' => q(Peseta Isipãyawara),
				'other' => q(Peseta-ita Isipãyawara),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Biri Etiupiyawara),
				'one' => q(Biri Etiupiyawara),
				'other' => q(Biri-ita Etiupiyawara),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euru),
				'one' => q(Euru),
				'other' => q(Euru-ita),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Marka Firãdiyawara),
				'one' => q(Marka Firãdiyawara),
				'other' => q(Marka-ita Firãdiyawara),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Dóra Fiyiwara),
				'one' => q(Dóra Fiyiwara),
				'other' => q(Dóra-ita Fiyiwara),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Ribara Mawinawara),
				'one' => q(Ribara Mawinawara),
				'other' => q(Ribara-ita Mawinawara),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Farãku Frãsawara),
				'one' => q(Farãku Frãsawara),
				'other' => q(Farãku-ita Frãsawara),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Ribara esiterina),
				'one' => q(Ribara esiterina),
				'other' => q(Ribara-ita esiterina),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Kupũ Rari Geugiyawara),
				'one' => q(Kupũ Rari Geugiyawara),
				'other' => q(Kupũ Rari-ita Geugiyawara),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Rari geugiyanu),
				'one' => q(Rari geugiyanu),
				'other' => q(Rari-ita geugiyanu),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Sedi Ganawara \(1979–2007\)),
				'one' => q(Sedi Ganawara \(1979–2007\)),
				'other' => q(Sedi-ita Ganawara \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Sedi ganei),
				'one' => q(Sedi ganei),
				'other' => q(Sedi ganei-ita),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Ribara Gibarautáwara),
				'one' => q(Ribara Gibarautáwara),
				'other' => q(Ribara-ita Gibarautáwara),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Darasi Gãbiyawara),
				'one' => q(Darasi Gãbiyawara),
				'other' => q(Darasi-ita Gãbiyawara),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Farãku Ginewara),
				'one' => q(Farãku Ginewara),
				'other' => q(Farãku-ita Ginewara),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Siri Ginewara),
				'one' => q(Siri Ginewara),
				'other' => q(Siri-ita Ginewara),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Ekiwere Giné Ekuatoriyawara),
				'one' => q(Ekiwere Giné Ekuatoriyawara),
				'other' => q(Ekiwere-ita Giné Ekuatoriyawara),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Darakima Geresiyawara),
				'one' => q(Darakima Geresiyawara),
				'other' => q(Darakima-ita Geresiyawara),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Ketisau Guatemawara),
				'one' => q(Ketisau Guatemawara),
				'other' => q(Ketisau-ita Guatemawara),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Warakapá Giné Purutugesawara),
				'one' => q(Warakapá Giné Purutugesawara),
				'other' => q(Warakapá-ita Giné Purutugesawara),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Pusewa Giné-Bisawara),
				'one' => q(Pusewa Giné-Bisawara),
				'other' => q(Pusewa-ita Giné-Bisawara),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Dóra Gianawara),
				'one' => q(Dóra Gianawara),
				'other' => q(Dóra-ita Gianawara),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Dóra Hũgi-Kũgiwara),
				'one' => q(Dóra Hũgi-Kũgiwara),
				'other' => q(Dóra-ita Hũgi-Kũgiwara),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Ribara Ũdurawara),
				'one' => q(Ribara Ũdurawara),
				'other' => q(Ribara-ita Ũdurawara),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Dinari Kuruwasiyawara),
				'one' => q(Dinari Kuruwasiyawara),
				'other' => q(Dinari-ita Kuruwasiyawara),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna Kuruata),
				'one' => q(Kuna Kuruata),
				'other' => q(Kuna-ita Kuruata),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gourde Aitiwara),
				'one' => q(Gourde Aitiwara),
				'other' => q(Gourde-ita Aitiwara),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Fulurĩ Ũgiriyawara),
				'one' => q(Fulurĩ Ũgiriyawara),
				'other' => q(Fulurĩ-ita Ũgiriyawara),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Rupiya Ĩdunesiyawara),
				'one' => q(Rupiya Ĩdunesiyawara),
				'other' => q(Rupiya-ita Ĩdunesiyawara),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Ribara Irãdawara),
				'one' => q(Ribara Irãdawara),
				'other' => q(Ribara-ita Irãdawara),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Ribara Isirayewara),
				'one' => q(Ribara Isirayewara),
				'other' => q(Ribara-ita Isirayewara),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(Xekeu Kuxiímawara Isirayerita),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Pisusawa Xekeu Isiraelẽsi),
				'one' => q(Pisusawa Xekeu Isiraelẽsi),
				'other' => q(Pisusawa Xekeu-ita Isiraelẽsi),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupiya Ĩdiawara),
				'one' => q(Rupiya Ĩdiawara),
				'other' => q(Rupiya-ita Ĩdiawara),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Dinari Irakiwara),
				'one' => q(Dinari Irakiwara),
				'other' => q(Dinari-ita Irakiwara),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Riau Irãwara),
				'one' => q(Riau Irãwara),
				'other' => q(Riau-ita Irãwara),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(Kuruwa Kuxiímawara Isirãdiawara),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Kuruwa Isirãdiawara),
				'one' => q(Kuruwa Isirãdiawara),
				'other' => q(Kuruwa-ita Isirãdiawara),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Rira Itariyawara),
				'one' => q(Rira Itariyawara),
				'other' => q(Rira-ita Itariyawara),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Dóra Yamaikawara),
				'one' => q(Dóra Yamaikawara),
				'other' => q(Dóra-ita Yamaikawara),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dinari Yudâniyawara),
				'one' => q(Dinari Yudâniyawara),
				'other' => q(Dinari-ita Yudâniyawara),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Iyene Nipõwara),
				'one' => q(Iyene Nipõwara),
				'other' => q(Iyene-ita Nipõwara),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Xirĩ Kẽniyawara),
				'one' => q(Xirĩ Kẽniyawara),
				'other' => q(Xirĩ-ita Kẽniyawara),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Sumu Kirigiretãmawara),
				'one' => q(Sumu Kirigiretãmawara),
				'other' => q(Sumu-ita Kirigiretãmawara),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Rieu Kãbuyawara),
				'one' => q(Rieu Kãbuyawara),
				'other' => q(Rieu-ita Kãbuyawara),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Farãku Kumurewara),
				'one' => q(Farãku Kumurewara),
				'other' => q(Farãku-ita Kumurewara),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Wõ nuti-kureyanu),
				'one' => q(Wõ nuti-kureyanu),
				'other' => q(Wõ-ita nuti-kureyanu),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(Huwã Kureya-Suwara),
				'one' => q(Huwã Kureya-Suwara),
				'other' => q(Huwã-ita Kureya-Suwara),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(Wõ Kureya-Suwara \(1945–1953\)),
				'one' => q(Wõ Kuxiímawara Kureya-Suwara),
				'other' => q(Wõ-ita Kuxiímawara Kureya-Suwara),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Wõ su-kureyanu),
				'one' => q(Wõ su-kureyanu),
				'other' => q(Wõ-ita su-kureyanu),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Dinari Kuwaitiwara),
				'one' => q(Dinari Kuwaitiwara),
				'other' => q(Dinari-ita Kuwaitiwara),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Dóra Kaimãwara),
				'one' => q(Dóra Kaimãwara),
				'other' => q(Dóra-ita Kaimãwara),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tẽge Kasakiwara),
				'one' => q(Tẽge Kasakiwara),
				'other' => q(Tẽge-ita Kasakiwara),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Kipi Rawosiwara),
				'one' => q(Kipi Rawosiwara),
				'other' => q(Kipi-ita Rawosiwara),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Ribara Ribanuwara),
				'one' => q(Ribara Ribanuwara),
				'other' => q(Ribara-ita Ribanuwara),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Rupiya Sirirãkawara),
				'one' => q(Rupiya Sirirãkawara),
				'other' => q(Rupiya-ita Sirirãkawara),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dóra Riberiyawara),
				'one' => q(Dóra Riberiyawara),
				'other' => q(Dóra-ita Riberiyawara),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Ruti Resutuwara),
				'one' => q(Ruti Resutuwara),
				'other' => q(Ruti-ita Resutuwara),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Rita Rituwãniwara),
				'one' => q(Rita Rituwãniwara),
				'other' => q(Rita-ita Rituwãniwara),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Taruna rituwãnu),
				'one' => q(Taruna rituwãnu),
				'other' => q(Taruna-ita rituwãnu),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Farãku yumuyerewa Ruxẽbuguwara),
				'one' => q(Farãku yumuyerewa Ruxẽbuguwara),
				'other' => q(Farãku-ita yumuyerewa Ruxẽbuguwara),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Farãku Ruxẽbuguwara),
				'one' => q(Farãku Ruxẽbuguwara),
				'other' => q(Farãku-ita Ruxẽbuguwara),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Farãku finãseru Ruxẽbuguwara),
				'one' => q(Farãku finãseru Ruxẽbuguwara),
				'other' => q(Farãku-ita finãseru Ruxẽbuguwara),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Rati Retuniyawara),
				'one' => q(Rati Retuniyawara),
				'other' => q(Rati-ita Retuniyawara),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Ruburu Retuniyawara),
				'one' => q(Ruburu Retuniyawara),
				'other' => q(Ruburu-ita Retuniyawara),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinari Ribiyawara),
				'one' => q(Dinari Ribiyawara),
				'other' => q(Dinari-ita Ribiyawara),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirhã Marukuwara),
				'one' => q(Dirhã Marukuwara),
				'other' => q(Dirhã-ita Marukuwara),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Farãku Marukuwara),
				'one' => q(Farãku Marukuwara),
				'other' => q(Farãku-ita Marukuwara),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(Farãku Mũnakuwara),
				'one' => q(Farãku Mũnakuwara),
				'other' => q(Farãku-ita Mũnakuwara),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(Kupũ Mũduwara),
				'one' => q(Kupũ Mũduwara),
				'other' => q(Kupũ-ita Mũduwara),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Leyu mudawiu),
				'one' => q(Leyu mudawiu),
				'other' => q(Leyu-ita mudawiu-ita),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariyari maugaxi),
				'one' => q(Ariyari maugaxi),
				'other' => q(Ariyari-ita maugaxi-ita),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Farãku Madagasikawara),
				'one' => q(Farãku Madagasikawara),
				'other' => q(Farãku-ita Madagasikawara),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Dinari Maseduniyawara),
				'one' => q(Dinari Maseduniyawara),
				'other' => q(Dinari-ita Maseduniyawara),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(Dinari Maseduniyawara \(1992–1993\)),
				'one' => q(Dinari Maseduniyawara \(1992–1993\)),
				'other' => q(Dinari-ita Maseduniyawara \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Farãku Mariwara),
				'one' => q(Farãku Mariwara),
				'other' => q(Farãku-ita Mariwara),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kiyati Miayamawara),
				'one' => q(Kiyati Miayamawara),
				'other' => q(Kiyati-ita Miayamawara),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Tugiriki Mũguriyawara),
				'one' => q(Tugiriki Mũguriyawara),
				'other' => q(Tugiriki-ita Mũguriyawara),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataka Makauwara),
				'one' => q(Pataka Makauwara),
				'other' => q(Pataka-ita Makauwara),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Wogiya Makauwara \(1973–2017\)),
				'one' => q(Wogiya Makauwara \(1973–2017\)),
				'other' => q(Wogiya-ita Makauwara \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Wogiya Mauritaniwara),
				'one' => q(Wogiya Mauritaniwara),
				'other' => q(Wogiya-ita Mauritaniwara),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Rira Mautawara),
				'one' => q(Rira Mautawara),
				'other' => q(Rira-ita Mautawara),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Ribara mautesa),
				'one' => q(Ribara mautesa),
				'other' => q(Ribara-ita mautesa-ita),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupiya Maurisiwara),
				'one' => q(Rupiya Maurisiwara),
				'other' => q(Rupiya-ita Maurisiwara),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rupiya Maudiwawara),
				'one' => q(Rupiya Maudiwawara),
				'other' => q(Rupiya-ita Maudiwawara),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kuaxa Marawiwara),
				'one' => q(Kuaxa Marawiwara),
				'other' => q(Kuaxa-ita Marawiwara),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Pusewa Mexikuwara),
				'one' => q(Pusewa Mexikuwara),
				'other' => q(Pesu-ita Mexikuwara),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Pusewa Parata suiwara mexikanu \(1861–1992\)),
				'one' => q(Pusewa Parata suiwara mexikanu \(1861–1992\)),
				'other' => q(Pusewa-ita Parata suiwara mexikanu-ita \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Yepesawa Mexikuwara Ĩwetiriarama \(UDI\)),
				'one' => q(Unidade Ĩwestiriarama Mexikuwara \(UDI\)),
				'other' => q(Unidade-ita Mexikuwara Ĩwestiriarama-ita \(UDI\)),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Rĩgiti malayu),
				'one' => q(Rĩgiti malayu),
				'other' => q(Rĩgiti-ita malayu-ita),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Warakapá Musãbikiwara),
				'one' => q(Warakapá Musãbikiwara),
				'other' => q(Warakapá-ita Musãbikiwara),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metikau Musãbikiwara \(1980–2006\)),
				'other' => q(Metikau Kuxiímawara Musãbikiwara),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Metikau Musãbikiwara),
				'one' => q(Metikau Musãbikiwara),
				'other' => q(Metikau-ita Musãbikiwara),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dóra Namibiyawara),
				'one' => q(Dóra Namibiyawara),
				'other' => q(Dóra-ita Namibiyawara),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira Nigeriyawara),
				'one' => q(Naira Nigeriyawara),
				'other' => q(Naira-ita Nigeriyawara),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Koduba Nikaraguwara \(1988–1991\)),
				'one' => q(Koduba Nikaraguwara \(1988–1991\)),
				'other' => q(Koduba-ita Nikaraguwara \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Koduba Nikaraguwara),
				'one' => q(Koduba Nikaraguwara),
				'other' => q(Koduba-ita Nikaraguwara),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Fulurĩ Hurãdawara),
				'one' => q(Fulurĩ Hurãdawara),
				'other' => q(Fulurĩ-ita Hurãdawara),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Kuruwa Nuruwegawara),
				'one' => q(Kuruwa Nuruwegawara),
				'other' => q(Kuruwa-ita Nuruwegawara),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rupiya Nepauwara),
				'one' => q(Rupiya nNpauwara),
				'other' => q(Rupiya-ita Nepauwara),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Dóra neuserãdewa),
				'one' => q(Dóra neuserãdewa),
				'other' => q(Dóra-ita neuserãdewa-ita),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Riyau Umãwara),
				'one' => q(Riyau Umãwara),
				'other' => q(Riyau-ita Umãwara),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Baubowa Panamawara),
				'one' => q(Baubowa Panamawara),
				'other' => q(Baubowa-ita Panamawara),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Ĩti Peruwara),
				'one' => q(Ĩti Peruwara),
				'other' => q(Ĩti-ita Peruwara),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Pisasuwa Kurasí Peruwara),
				'one' => q(Pisasuwa Kurasí Peruwara),
				'other' => q(Pisasuwa Kurasí-ita Peruwara),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Kurasí Peruwara \(1863–1965\)),
				'one' => q(Kurasí Peruwara \(1863–1965\)),
				'other' => q(Kurasí-ita Peruwara \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina Papuwara),
				'one' => q(Kina Papuwara),
				'other' => q(Kina-ita Papuwara),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Pusewa Firipinawara),
				'one' => q(Pusewa Firipinawara),
				'other' => q(Pusewa-ita Firipinawara),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rupiya Pakiretãwara),
				'one' => q(Rupiya Pakiretãwara),
				'other' => q(Rupiya-ita Pakiretãwara),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Ziroti Puruniyawara),
				'one' => q(Ziroti Puruniyawara),
				'other' => q(Ziroti-ita Puruniyawara),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Ziroti Puruniyawara \(1950–1995\)),
				'one' => q(Ziroti Puruniyawara \(1950–1995\)),
				'other' => q(Ziroti-ita Puruniyawara \(1950–1995\)),
			},
		},
		'PTE' => {
			symbol => 'Esc.',
			display_name => {
				'currency' => q(Warakapá Purutugawara),
				'one' => q(Warakapá Purutugawara),
				'other' => q(Warakapá-ita Purutugawara),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Guwarani Paraguwaiwara),
				'one' => q(Guwarani Paraguwaiwara),
				'other' => q(Guwarani-ita Paraguwaiwara),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Riyau Katawara),
				'one' => q(Riyau Katawara),
				'other' => q(Riyau-ita Katawara),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Dóra Rudesiyawara),
				'one' => q(Dóra Rudesiyawara),
				'other' => q(Dóra-ita Rudesiyawara),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Leu Rumeniyawara \(1952–2006\)),
				'one' => q(Leu Kuxiímawara Rumeniyawara),
				'other' => q(Leu Kuxiímawara-ita Rumeniyawara),
			},
		},
		'RON' => {
			symbol => 'L',
			display_name => {
				'currency' => q(Leu Rumeniyawara),
				'one' => q(Leu Rumeniyawara),
				'other' => q(Leu-ita Rumeniyawara),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dinari Sewiyawara),
				'one' => q(Dinari Sewiyawara),
				'other' => q(Dinari-ita Sewiyawara),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Ruburu Rusiyawara),
				'one' => q(Ruburu Rusiyawara),
				'other' => q(Ruburu-ita Rusiyawara),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Ruburu Rusiyawara \(1991–1998\)),
				'one' => q(Ruburu Rusiyawara \(1991–1998\)),
				'other' => q(Ruburu-ita Rusiyawara \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Farãku Ruãdawara),
				'one' => q(Farãku Ruãdawara),
				'other' => q(Farãku-ita Ruãdawara),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyau Sauditawara),
				'one' => q(Riyau Sauditawara),
				'other' => q(Riyau-ita Sauditawara),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Dóra Kapuãma-ita Sarumũ yara),
				'one' => q(Dóra Kapuãma-ita Sarumũ yara),
				'other' => q(Dóra-ita Kapuãma-ita Sarumũ yara),
			},
		},
		'SCR' => {
			symbol => 'SCRu',
			display_name => {
				'currency' => q(Rupiya Seixeriwara),
				'one' => q(Rupiya Seixeriwara),
				'other' => q(Rupiya-ita Seixeriwara),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Dinari Sudawara \(1992–2007\)),
				'other' => q(Dinari Kuxiímawara Sudawara),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Ribara Sudawara),
				'one' => q(Ribara Sudawara),
				'other' => q(Ribara-ita Sudawara),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Ribara Sudawara \(1957–1998\)),
				'one' => q(Ribara Kuxiímawara Sudaũwara),
				'other' => q(Ribara Kuxiímawara-ita Sudaũwara),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Kuruwa Suwésiyawara),
				'one' => q(Kuruwa Suwésiyawara),
				'other' => q(Kuruwa-ita Suwésiyawara),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Dóra Sĩgapurawara),
				'one' => q(Dóra Sĩgapurawara),
				'other' => q(Dóra-ita Sĩgapurawara),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Ribara Sãta Herena yara),
				'one' => q(Ribara Sãta Herena yara),
				'other' => q(Ribara-ita Sãta Herena yara),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Tora Katuwa Esiruweniyawara),
				'one' => q(Tora Esiruweniyawara),
				'other' => q(Tora-ita Esiruweniyawara),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Kuruwa Esirowaka),
				'one' => q(Kuruwa Esirowaka),
				'other' => q(Kuruwa-ita Esirowaka),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Rioni Iwitera Reuwa yara),
				'one' => q(Rioni Iwitera Reuwa yara),
				'other' => q(Rioni-ita Iwitera Reuwa yara),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Rioni Iwitera Reuwa yara \(1964—2022\)),
				'one' => q(Rioni Iwitera Reuwa yara \(1964—2022\)),
				'other' => q(Rioni-ita Iwitera Reuwa yara \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Xerĩ Sumariyawara),
				'one' => q(Xerĩ Sumariyawara),
				'other' => q(Xerĩ-ita Sumariyawara),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Dóra Surinãmiyawara),
				'one' => q(Dóra Surinãmiyawara),
				'other' => q(Dóra-ita Surinãmiyawara),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Fulurĩ Surinami yara),
				'one' => q(Fulurĩ Surinami yara),
				'other' => q(Fulurĩ-ita Surinami yara),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Ribara Su-Sudãniyawara),
				'one' => q(Ribara Su-Sudãniyawara),
				'other' => q(Ribara-ita Su-Sudãniyawara),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobara Sãtu Tumé asuí Pirĩsipi yara \(1977–2017\)),
				'one' => q(Dobara Sãtu Tumé asuí Pirĩsipi yara \(1977–2017\)),
				'other' => q(Dobara-ita Sãtu Tumé asuí Pirĩsipi yara \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobara Sãtu Tumé asuí Pirĩsipi yara),
				'one' => q(Dobara Sãtu Tumé asuí Pirĩsipi yara),
				'other' => q(Dobara-ita Sãtu Tumé asuí Pirĩsipi yara),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Ruburu Suwiyetikawara),
				'one' => q(Ruburu Suwiyetikawara),
				'other' => q(Ruburu-ita S),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Kurũ Sauwadú yara),
				'one' => q(Kurũ Sauwadú yara),
				'other' => q(Kurũ-ita Sauwadú yara),
			},
		},
		'SYP' => {
			symbol => 'S£',
			display_name => {
				'currency' => q(Ribara Síriya),
				'one' => q(Ribara Síriya),
				'other' => q(Ribara-ita Síriya),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Rirãgeni Suwasiretãmawara),
				'one' => q(Rirãgeni Suwasiretãmawara),
				'other' => q(Rirãgeni-ita Suwasiretãmawara),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Baht Tairetãmawara),
				'one' => q(Baht Tairetãmawara),
				'other' => q(Baht-ita Tairetãmawara),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Ruburu Tayikiretãmawara),
				'one' => q(Ruburu Tayikiretãmawara),
				'other' => q(Ruburu-ita Tayikiretãmawara),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Sumuni tayiki),
				'one' => q(Sumuni tayiki),
				'other' => q(Sumuni-ita tayiki-ita),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Manati Turkuranaretãma yara \(1993–2009\)),
				'one' => q(Manati Turkuranaretãma yara \(1993–2009\)),
				'other' => q(Manati-ita Turkuranaretãma yara \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Manati turkumenu),
				'one' => q(Manati turkumenu),
				'other' => q(Manati-ita turkumenu-ita),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinari Tunisiyawara),
				'one' => q(Dinari Tunisiyawara),
				'other' => q(Dinari-ita Tunisiyawara),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Pawãga Tũgawara),
				'one' => q(Pawãga Tũgawara),
				'other' => q(Pawãga-ita Tũgawara),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Warakapá Timuwara),
				'one' => q(Warakapá Timuwara),
				'other' => q(Warakapá-ita Timuwara),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Rira turka \(1922–2005\)),
				'one' => q(Rira turka kuxiímawara),
				'other' => q(Rira turka kuxiímawara-ita),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Rira turka),
				'one' => q(Rira turka),
				'other' => q(Rira-ita turka-ita),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dóra Tirinidadi asuí Tobagu yara),
				'one' => q(Dóra Tirinidadi asuí Tobagu yara),
				'other' => q(Dóra-ita Tirinidadi asuí Tobagu yara),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Pisasuwa Dóra Taiwãwara),
				'one' => q(Pisasuwa Dóra Taiwãwara),
				'other' => q(Pisasuwa-ita Dóra-ita Taiwãwara),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Xerĩ Tãsaniyawara),
				'one' => q(Xerĩ Tãsaniyawara),
				'other' => q(Xerĩ-ita Tãsaniyawara),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Hiryuwiniya Ukaraniyãwara),
				'one' => q(Hiryuwiniya Ukaraniyãwara),
				'other' => q(Hiryuwiniya-ita Ukaraniyãwara),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Kabuwaneti Ukaraniyãwara),
				'one' => q(Kabuwaneti Ukaraniyãwara),
				'other' => q(Kabuwaneti-ita Ukaraniyãwara),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Xerĩ Ugãdawara \(1966–1987\)),
				'one' => q(Xirĩga Ugãdawara \(1966–1987\)),
				'other' => q(Xirĩga-ita Ugãdawara \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Xerĩ Ugãdawara),
				'one' => q(Xerĩ Ugãdawara),
				'other' => q(Xerĩ-ita Ugãdawara),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dóra Mexikuwara),
				'one' => q(Dóra Mexikuwara),
				'other' => q(Dóra-ita Mexikuwara),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(Dóra nuti-amerikawa \(amũ ára\)),
				'one' => q(Dóra amerikawa \(amũ ára\)),
				'other' => q(Dóra-ita amerikawa-ira \(amũ ára\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(Dóra nuti-amerikawa \(aramẽ wára\)),
				'one' => q(Dóra amerikawa \(aramẽ wára\)),
				'other' => q(Dóra-ita amerikawa-ita \(aramẽ wára\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(Pusewa Uruguwaiwara yepesawa ĩdekisada-ita upé),
				'one' => q(Pusewa Uruguwaiwara yepesawa ĩdekisada-ita upé),
				'other' => q(Pusewa-ita Uruguwaiwara yepesawa ĩdekisada-ita upé),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Pusewa Uruguwaiwara \(1975–1993\)),
				'one' => q(Pusewa Uruguwaiwara \(1975–1993\)),
				'other' => q(Pusewa-ita Uruguwaiwara \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Pusewa Uruguwaiwara),
				'one' => q(Pusewa Uruguwaiwara),
				'other' => q(Pusewa-ita Uruguwaiwara),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Sumu Yũbuesara-retãmawara),
				'one' => q(Sumu Yũbuesara-retãmawara),
				'other' => q(Sumu-ita Yũbuesara-retãmawara),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Buriwari Wenesuerawara \(1871–2008\)),
				'one' => q(Buriwari Wenesuerawara \(1871–2008\)),
				'other' => q(Buriwari-ita Wenesuerawara \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Buriwari Wenesuerawara \(2008–2018\)),
				'one' => q(Buriwari Wenesuerawara \(2008–2018\)),
				'other' => q(Buriwari-ita Wenesuerawara \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'Bs.S',
			display_name => {
				'currency' => q(Buriwari Wenesuerawara),
				'one' => q(Buriwari Wenesuerawara),
				'other' => q(Buriwari-ita Wenesuerawara),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Dong wietinamita),
				'one' => q(Dong wietinamita),
				'other' => q(Dong-ita wietinamita-ita),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(Dong wietinamita \(1978–1985\)),
				'one' => q(Dong wietinamita \(1978–1985\)),
				'other' => q(Dong-ita wietinamita-ita \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Watu Wanuatu yara),
				'one' => q(Watu Wanuatu yara),
				'other' => q(Watu-ita Wanuatu yara-ita),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tara Samuwara),
				'one' => q(Tara Samuwara),
				'other' => q(Tara-ita Samuwara),
			},
		},
		'XAF' => {
			symbol => 'FCF',
			display_name => {
				'currency' => q(Farãku CFC BEAC yara),
				'one' => q(Farãku CFC BEAC yara),
				'other' => q(Farãku-ita CFC BEAC yara),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Parata),
				'one' => q(Parata),
				'other' => q(Parata-ita),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Ouru),
				'one' => q(Ouru),
				'other' => q(Ouru-ita),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Yepesawa siiyawita Eurupawara),
				'one' => q(Yepesawa siiyawita Eurupawara),
				'other' => q(Yepesawa-ita siiyawita Eurupawara),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Yepesawa munetariya Eurupawara),
				'one' => q(Yepesawa munetariya Eurupawara),
				'other' => q(Yepesawa-ita munetariya-ita Eurupawara),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Yepesawa kũta Eurupawara \(XBC\)),
				'one' => q(Yepesawa kũta Eurupawara \(XBC\)),
				'other' => q(Yepesawa-ita kũta Eurupawara \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Yepesawa kũta Eurupawara \(XBD\)),
				'one' => q(Yepesawa kũta Eurupawara \(XBD\)),
				'other' => q(Yepesawa-ita kũta Eurupawara \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Dóra Karibi Uriẽtawara yara),
				'one' => q(Dóra Karibi Uriẽtawara yara),
				'other' => q(Dóra-ita Karibi Uriẽtawara yara),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Yupitasukasa Yãkatuwa Musakasawa),
				'one' => q(Yupitasukasa Yãkatuwa Musakasawa),
				'other' => q(Yupitasukasa-ita Yãkatuwa Musakasawa),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Yepesawa Muweda Eurupawara),
				'one' => q(Yepesawa Muweda Eurupawara),
				'other' => q(Yepesawa-ita Muweda-ita Eurupawara),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Farãku-ouru Farãsawara),
				'one' => q(Farãku-ouru Farãsawara),
				'other' => q(Farãku-ouru-ita Farãsawara),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Farãku UIC Farãsawara),
				'one' => q(Farãku UIC Farãsawara),
				'other' => q(Farãku UIC-ita Farãsawara),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(Farãku CFA BCEAO yara),
				'one' => q(Farãku CFA BCEAO yara),
				'other' => q(Farãku CFA-ita BCEAO yara-ita),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Parádiyu),
				'one' => q(Parádiyu),
				'other' => q(Parádiyu-ita),
			},
		},
		'XPF' => {
			symbol => 'CFP',
			display_name => {
				'currency' => q(Farãku CFP),
				'one' => q(Farãku CFP),
				'other' => q(Farãku CFP-ita),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Paratina),
				'one' => q(Paratina),
				'other' => q(Paratina-ita),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(Fũdu RINET),
				'one' => q(Fũdu RINET),
				'other' => q(Fũdu-ita RINET),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(Kudigu Muweda Yusã yara),
				'one' => q(Kudigu Muweda Yusã yara),
				'other' => q(Kudigu-ita Muweda Yusã yara),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Moweda ũbawaukua awa),
				'one' => q(\(yepesawa munetariya ũbawaukua awa\)),
				'other' => q(\(moweda-ita ũbawaukua awa-ita\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Dinari Yemẽwara),
				'one' => q(Dinari Yemẽwara),
				'other' => q(Dinã-ita Yemẽwara),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Riyau yeminita),
				'one' => q(Riyau yeminita),
				'other' => q(Riyau-ita yeminita-ita),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Dinari kirĩbawa Yugusirawiawara \(1966–1990\)),
				'one' => q(Dinari kirĩbawa Yugusirawiawara),
				'other' => q(Dinari-ita kirĩbawa-ita Yugusirawiawara),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Dinari pisasuwa yugusirawia \(1994–2002\)),
				'one' => q(Dinari pisasuwa Yugusirawiawara),
				'other' => q(Dinari-ita pisasuwa-ita Yugusirawiawara),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Dinari yumuyerewa Yugusirawiawara \(1990–1992\)),
				'one' => q(Dinari yumuyerewa Yugusirawiawara),
				'other' => q(Dinari-ita yumuyerewa-ita Yugusirawiawara),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(Dinari yũpisasuwa Yugusirawiawara \(1992–1993\)),
				'one' => q(Dinari yũpisasuwa Yugusirawiawara),
				'other' => q(Dinari-ita yũpisasuwa-ita Yugusirawiawara),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Rãdi su-afirikanu \(finãseru\)),
				'one' => q(Rãdi Afirika Su kitiwara \(finãseru\)),
				'other' => q(Rãdi-ita Afirika Su kitiwara \(finãseru\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rãdi-ita Afirika Su kitiwara),
				'one' => q(Rãdi Su-Afirikawara),
				'other' => q(Rãdi-ita Su-Afirikawara),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kuwaxa sãbianu \(1968–2012\)),
				'one' => q(Kuwaxa Sãbiawara \(1968–2012\)),
				'other' => q(Kuwaxa-ita Sãbiawara \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'Zk',
			display_name => {
				'currency' => q(Kuwaxa sãbianu),
				'one' => q(Kuwaxa sãbianu),
				'other' => q(Kuwaxa-ita sãbianu-ita),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Saire Pisasuwa Sairewara \(1993–1998\)),
				'one' => q(Saire Pisasuwa Sairewara),
				'other' => q(Saire-ita Pisasuwa Sairewara),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Saire Sairewara \(1971–1993\)),
				'one' => q(Saire Sairewara),
				'other' => q(Saire-ita Sairewara),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dóra Sĩbabuwewara \(1980–2008\)),
				'one' => q(Dóra Sĩbabuwewara),
				'other' => q(Dóra-ita Sĩbabuwewara),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Dóra Sĩbabuwewara \(2009\)),
				'one' => q(Dóra Sĩbabuwewara \(2009\)),
				'other' => q(Dóra-ita Sĩbabuwewara \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Dóra Sĩbabuwewara \(2008\)),
				'one' => q(Dóra Sĩbabuwewara \(2008\)),
				'other' => q(Dóra-ita Sĩbabuwewara \(2008\)),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'chinese' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'YYE',
							'YMU',
							'YMS',
							'YID',
							'YPU',
							'YPY',
							'YPM',
							'YPS',
							'YPI',
							'YYP',
							'YYY',
							'YYM'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Yasí-Yepé',
							'Yasí-Mukũi',
							'Yasí-Musapíri',
							'Yasí-Irũdí',
							'Yasí-Pú',
							'Yasí-Pú-Yepé',
							'Yasí-Pú-Mukũi',
							'Yasí-Pú-Musapíri',
							'Yasí-Pú-Irũdí',
							'Yasí-Yepé-Putimaã',
							'Yasí-Yepé-Yepé',
							'Yasí-Yepé-Mukũi'
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
							'ye',
							'mk',
							'ms',
							'id',
							'pu',
							'py',
							'pm',
							'ps',
							'pi',
							'yp',
							'yy',
							'ym'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'yepé',
							'mukũi',
							'musapíri',
							'irũdí',
							'pú',
							'pú-yepé',
							'pú-mukũi',
							'pú-musapíri',
							'pú-irũdí',
							'yepé-putimaã',
							'yepé-yepé',
							'yepé-mukũi'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'Y',
							'M',
							'M',
							'I',
							'P',
							'P',
							'P',
							'P',
							'P',
							'Y',
							'Y',
							'Y'
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
						mon => 'mur',
						tue => 'mmk',
						wed => 'mms',
						thu => 'sup',
						fri => 'yuk',
						sat => 'sau',
						sun => 'mit'
					},
					wide => {
						mon => 'murakipí',
						tue => 'murakí-mukũi',
						wed => 'murakí-musapíri',
						thu => 'supapá',
						fri => 'yukuakú',
						sat => 'saurú',
						sun => 'mituú'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'M',
						tue => 'M',
						wed => 'M',
						thu => 'S',
						fri => 'Y',
						sat => 'S',
						sun => 'M'
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
					abbreviated => {0 => 'M1',
						1 => 'M2',
						2 => 'M3',
						3 => 'M4'
					},
					wide => {0 => 'yepésáwa musapíri-yasí',
						1 => 'mukũisawa musapíri-yasí',
						2 => 'musapírisawa musapíri-yasí',
						3 => 'irũdisawa musapíri-yasí'
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
			if ($_ eq 'buddhist') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'chinese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				last SWITCH;
				}
			if ($_ eq 'japanese') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2400;
					return 'morning1' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 0
						&& $time < 600;
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
					'afternoon1' => q{karuka ramẽ},
					'evening1' => q{pituna ramẽ},
					'midnight' => q{pituna pyterupé},
					'morning1' => q{kuêma ramẽ},
					'night1' => q{pitunaeté ramẽ},
					'noon' => q{iandé-ara-pyturepé},
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
			narrow => {
				'0' => 'EB'
			},
			wide => {
				'0' => 'EB'
			},
		},
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'K.s.',
				'1' => 'K.a.'
			},
			wide => {
				'0' => 'Kiristu senũdé',
				'1' => 'Kiristu ariré'
			},
		},
		'japanese' => {
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
		'chinese' => {
			'full' => q{EEEE, d MMMM U},
			'long' => q{d MMMM U},
			'medium' => q{dd/MM U},
			'short' => q{dd/MM/yy},
		},
		'generic' => {
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd/MM/y},
		},
		'japanese' => {
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{dd/MM/y G},
			'short' => q{dd/MM/yy GGGGG},
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
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
		},
		'japanese' => {
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
		'chinese' => {
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
		'japanese' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			MEd => q{E, dd/MM},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{MM/y GGGGG},
			yyyyMEd => q{E, dd/MM/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMMEd => q{E, d MMMM y G},
			yyyyMMMMd => q{d MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			MEd => q{E, dd/MM},
			MMMEd => q{E, d MMM},
			MMMMEd => q{E, d MMMM},
			MMMMW => q{W'ª' 'sẽmãna' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{MM/y},
			yMEd => q{E, dd/MM/y},
			yMM => q{MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMMEd => q{E, d MMMM y},
			yMMMMd => q{d MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd/MM/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{w'ª' 'sẽmãna' Y},
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
			Bhm => {
				h => q{h:mm – h:mm B},
			},
			H => {
				H => q{HH'h' - HH'h'},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			h => {
				a => q{h'h' a – h'h' a},
				h => q{h'h' - h'h' a},
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
				h => q{h – h a v},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{MM/y – MM/y G},
				y => q{MM/y – MM/y G},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y G},
				d => q{E, dd/MM/y – E, dd/MM/y G},
				y => q{E, dd/MM/y – E, dd/MM/y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y G},
				d => q{dd/MM/y – dd/MM/y G},
				y => q{dd/MM/y – dd/MM/y G},
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
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{G y – G y},
				y => q{G y – y},
			},
			GyM => {
				G => q{GGGGG MM/y – GGGGG MM/y},
				M => q{GGGGG MM/y – MM/y},
				y => q{GGGGG MM/y – MM/y},
			},
			GyMEd => {
				G => q{GGGGG E dd/MM/y – GGGGG E dd/MM/y},
				M => q{GGGGG E dd/MM/y – E dd/MM/y},
				d => q{GGGGG E dd/MM/y – dd/MM/y},
				y => q{GGGGG E dd/MM/y – E dd/MM/y},
			},
			GyMMM => {
				G => q{G MMM y – G MMM y},
				M => q{G MMM y – MMM},
				y => q{G MMM y – MMM y},
			},
			GyMMMEd => {
				G => q{G E, d MMM y – G E, d MMM y},
				M => q{G E, d MMM y – E, d MMM},
				d => q{G E, d MMM y – E, d MMM},
				y => q{G E, d MMM y – E, d MMM y},
			},
			GyMMMd => {
				G => q{G d MMM y – G d MMM y},
				M => q{G d MMM y – d MMM},
				d => q{G d – d MMM y},
				y => q{G d MMM y – d MMM y},
			},
			GyMd => {
				G => q{GGGGG dd/MM/y – GGGGG dd/MM/y},
				M => q{GGGGG dd/MM/y – dd/MM/y},
				d => q{GGGGG dd/MM/y – dd/MM/y},
				y => q{GGGGG dd/MM/y – dd/MM/y},
			},
			H => {
				H => q{HH'h' - HH'h'},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d – d},
			},
			h => {
				a => q{h a – h a},
				h => q{h – h a},
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
				h => q{h – h a v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(Hurariyu {0}),
		regionFormat => q(Kurasí Ara Hurariyu: {0}),
		regionFormat => q(Hurariyu Retewa: {0}),
		'Acre' => {
			long => {
				'daylight' => q#Hurariyu Kurasí Ara Acre yara#,
				'generic' => q#Hurariyu Acre yara#,
				'standard' => q#Hurariyu Retewa Acre yara#,
			},
			short => {
				'daylight' => q#ACST#,
				'generic' => q#ACT#,
				'standard' => q#ACT#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Afegãniretãma Hurariyu#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidiyã#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akara#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Adisi Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Ageu#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asimara#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamaku#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bãki#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Bãjú#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bisau#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Barãtire#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Barazawiri#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Buyũbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairu#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Uka Murutĩga#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Seuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Kunakiri#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Katuawa ruka#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Dijibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Duwala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Eu Ayũ#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Firetũ#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Gaburuni#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Juanesibugu#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Yuba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kãpara#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Katũ#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kigari#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kĩxasa#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Ipawaita#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Riberevili#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Rumé#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Ruãda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubũbaxi#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Malabu#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Maputu#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Ũbabani#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mugadisiku#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Mũruwiya#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairubi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#N’ Diyamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamei#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nowakixuti#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Uwagadugu#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Igarapawa Pisasú#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sã Tumé#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tiripuri#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tuni-ita#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Wĩdueki#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Afirika Piterawara Hurariyu#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Afirika Uriẽtawara Hurariyu#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Afirika Su suí Hurariyu#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Afirika Usidẽtawara Kurasí Ara Hurariyu#,
				'generic' => q#Afirikia Usidẽtawara Hurariyu#,
				'standard' => q#Afirika Usidẽtawara Hurariyu Retewa#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alasika Kurasí Ara Hurariyu#,
				'generic' => q#Alasika Hurariyu#,
				'standard' => q#Alasika Hurariyu Eté#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Aumati Kurasí Ara Hurariyu#,
				'generic' => q#Aumati Hurariyu#,
				'standard' => q#Aumati Hurariyu Eté#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amasuna Kurasí Ara Hurariyu#,
				'generic' => q#Amasuna Hurariyu#,
				'standard' => q#Amasuna Hurariyu Eté#,
			},
			short => {
				'daylight' => q#AMST#,
				'generic' => q#AMT#,
				'standard' => q#AMT#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adaki#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Ãkurage#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Ãgira#,
		},
		'America/Antigua' => {
			exemplarCity => q#Ãtiguwa#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguayina#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#Ra Rioya#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Paranã Garegu-ita#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Sauta#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#Sã Yuwã#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#Sã Rui#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tukumã#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Uxuwaya#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asũsiyõ#,
		},
		'America/Bahia' => {
			exemplarCity => q#Baíya#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bãdera-ita Kuara#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barabadu#,
		},
		'America/Belem' => {
			exemplarCity => q#Belẽ#,
		},
		'America/Belize' => {
			exemplarCity => q#Berise#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Iwikuí Murutĩga#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Buwa Vista#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bugutá#,
		},
		'America/Boise' => {
			exemplarCity => q#Buwisé#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buwenusairi#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Kẽbiriyi Kuara#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Kãpu Wasu#,
		},
		'America/Cancun' => {
			exemplarCity => q#Kãkũ#,
		},
		'America/Caracas' => {
			exemplarCity => q#Karaka#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Katamaka#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Kayena#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kaimã#,
		},
		'America/Chicago' => {
			exemplarCity => q#Xikagu#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Sivava#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikokã#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kóduba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kupé Rika#,
		},
		'America/Creston' => {
			exemplarCity => q#Kerestũ#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Kuyaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kurasau#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Dinamarakasãv#,
		},
		'America/Dawson' => {
			exemplarCity => q#Dausũ#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Dausũ Kiriki#,
		},
		'America/Denver' => {
			exemplarCity => q#Dẽwer#,
		},
		'America/Dominica' => {
			exemplarCity => q#Duminika#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edimũtũ#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepé#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Eu Sawadu#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Futi Neusũ#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Futaresa#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Yrusãgusu-atã Kuara#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuki#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Ipekawasu Kuara#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Wasú Turiku#,
		},
		'America/Grenada' => {
			exemplarCity => q#Garanada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadarupi#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatemara#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guayakiu#,
		},
		'America/Guyana' => {
			exemplarCity => q#Giyana#,
		},
		'America/Havana' => {
			exemplarCity => q#Hawana#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Hemusiru#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knox, Ĩdiana#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marẽgu, Ĩdiana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Pitirisibugi, Ĩdiana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell Tawa-wasú, Ĩdiana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Wewai, Ĩdiana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Wĩsene-ita, Ĩdiana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winãmaki, Ĩdiana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Ĩdianapuri#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuwiki#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Ikaruiti#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Yamaika#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Yuyui#,
		},
		'America/Juneau' => {
			exemplarCity => q#Yuneau#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Mũtiseru, Kẽtuki#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kararẽdiki#,
		},
		'America/Lima' => {
			exemplarCity => q#Rima#,
		},
		'America/Louisville' => {
			exemplarCity => q#Luwisiviri#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Pirĩsipi Quarter Uirpewara#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maseyó#,
		},
		'America/Managua' => {
			exemplarCity => q#Manáguwa#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manau#,
		},
		'America/Marigot' => {
			exemplarCity => q#Mariguti#,
		},
		'America/Martinique' => {
			exemplarCity => q#Matinika#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Moroitayuká#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Masatarã#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mẽdusa#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menomini#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metirakatira#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Ẽmã tỹ Mẽsiku#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Mikirũ#,
		},
		'America/Moncton' => {
			exemplarCity => q#Mũkitũ#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Mõterei#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Mũtiwidewu#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Mõtiserati#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nasau#,
		},
		'America/New_York' => {
			exemplarCity => q#Yurki Pisasú#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nipigũ#,
		},
		'America/Nome' => {
			exemplarCity => q#Réra#,
		},
		'America/Noronha' => {
			exemplarCity => q#Fenãdu Nuruyã#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beur, Dakota Nuti suí#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Sẽte, Dakota Nuti suí#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Pisasú Sarẽ, Dakota Nuti suí#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Oyinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#Panamã#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Pãginitũgi#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Paramaribu#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Puwenikisi#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Igarapawa Pirĩsipi#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Esipãya Igarapawa#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Igarapawa Kuximawara#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Igarapawa Riku#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Pũta Arena-ita#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Paranã Amanawera#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rãkĩ Uikesawa#,
		},
		'America/Recife' => {
			exemplarCity => q#Resifi#,
		},
		'America/Regina' => {
			exemplarCity => q#Rejĩnỹ#,
		},
		'America/Resolute' => {
			exemplarCity => q#Resoruti#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Paranã Murutĩga#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Sãta Isabeu#,
		},
		'America/Santarem' => {
			exemplarCity => q#Sãtarẽ#,
		},
		'America/Santiago' => {
			exemplarCity => q#Sãtiyagu#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Sãtu Dumĩgu#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Sã Pauru#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Itukutumiti#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitika#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Sã Batulumeu#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Sãti Juni#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Sã Kirituwãu#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Sãta Lusiya#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Sãti Tomá#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Sã Wisẽti#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Paranã Pirãtã#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegusigaupa#,
		},
		'America/Thule' => {
			exemplarCity => q#Tixuri#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Tupã Kuara#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tijuvỹnỹ#,
		},
		'America/Toronto' => {
			exemplarCity => q#Turũtu#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tutura#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vãkuweri#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Kawaru Murutĩga#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Winĩpegi#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Yakutati#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Kisé-tawá#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Hurariyu Kurasí Ara Piterawara#,
				'generic' => q#Óra Kuju#,
				'standard' => q#Hurariyu Retewa Piterawara#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Hurariyu Kurasí Ara Lesiti#,
				'generic' => q#Hurariyu Lesiti#,
				'standard' => q#Hurariyu Retewa Lesiti yara#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Rỹ kã Óra Krĩ-ag tá#,
				'generic' => q#Óra Krĩ-ag tá#,
				'standard' => q#Óra Pã Krĩ-ag tá#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Rỹ Kã Óra Pasifiku tá#,
				'generic' => q#Óra Pasifiku tá#,
				'standard' => q#Óra Pã Pasifiku tá#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadí Kurasí Ara Hurariyu#,
				'generic' => q#Anadí Hurariyu#,
				'standard' => q#Anadí Hurariyu Retewa#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Kasei#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Dawi#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Makikuari#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mausũ#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#MakiMudu#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Paumere#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rotera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Siyowa#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Wosituki#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Apiya Kurasí Ara Hurariyu#,
				'generic' => q#Apiya Hurariyu#,
				'standard' => q#Apiya Uraruiyu Retewa#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Akitau Kurasí Ara Hurariyu#,
				'generic' => q#Akitau Hurariyu#,
				'standard' => q#Akitau Hurariyu Retewa#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Akitubi Kurasí Ara Hurariyu#,
				'generic' => q#Akitubi Hurariyu#,
				'standard' => q#Akitubi Hurariyu Retewa#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabiya Kurasí Ara Hurariyu#,
				'generic' => q#Arábiya Hurariyu#,
				'standard' => q#Arábiya Hurariyu Retewa#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyear Tawa-wasú#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argẽtina Kurasí Ara Hurariyu#,
				'generic' => q#Argẽtina Hurariyu#,
				'standard' => q#Argẽtina Hurariyu Retewa#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Argẽtina Usidẽtawara Kurasí Ara Hurariyu#,
				'generic' => q#Argẽtina Usidẽtawara Hurariyu#,
				'standard' => q#Argẽtina Usidẽtawara Hurariyu Retewa#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Arimẽniya Kurasí Ara Hurariyu#,
				'generic' => q#Arimẽniya Hurariyu#,
				'standard' => q#Arimẽniya Hurariyu Retewa#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Adẽ#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Aumati#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amã#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadi#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Akitau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Akitubi#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Asigabati#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atirau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Magna#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Barẽi#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Mág-kóki#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Barnau#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beirute#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bisikeki#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Burunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kaukutá#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Xita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Xuibausã#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kurũbu#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasiku#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Daka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Diri#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Duxãbi#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famaguita#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gasa#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Heburũ#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hũg Kũg#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Howidi#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutisiki#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakata#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Yayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Yerusarẽi#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabú#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kãxatika#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karaxi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katimãdu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Kãdiga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Karasinoyarisiki#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuara Rũpuru#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuxĩgi#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuwaiti#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makau#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadã#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manira#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Masikati#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosiya#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Kusinetisiki Pisasú#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Sibirisiki Pisasú#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Omisiki#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Raure#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Pinõ Pẽi#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pũtianaka#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Piũgiãgi#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katari#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kositanai#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kisiroda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rãgũ#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riade#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sakarina#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samakãda#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seú#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Xãgai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Sĩgapura#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Xeredinekorimiziki#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tasikẽti#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tibilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teyerã#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Tĩpu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokiyu#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomisiki#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Urã Baturu#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urũki#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Usiti-Nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Viẽtiane#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Waradiwosituki#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yakutisiki#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Ekaterĩbugu#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yerewã#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atalãtku Kurasí Ara Hurariyu#,
				'generic' => q#Atalãtiku Hurariyu#,
				'standard' => q#Atalãtiku Hurariyu Retewa#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Asori-ita#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bemuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanariya-ita#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kabu Suikiri#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Kapuãma-ita Faruwe#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reikiyawiki#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Geugiya Su suí#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sãta Erẽna#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Isitãrei#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Aderaidi#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Biribani#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Iwitera Mupenaíra#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Kurie#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Dariwĩ#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Eukara#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hobati#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Rĩdemã#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lurudi Howe#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Meubúni#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Periti#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sidinei#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Ausitaraliya Piterawara Kurasí Ara Hurariyu#,
				'generic' => q#Ausitaraliya Piterawara Hurariyu#,
				'standard' => q#Ausitaraliya Piterawara Hurariyu Retewa#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Ausitaraliya Piterawara-Usidẽtawara Kurasí Ara Hurariyu#,
				'generic' => q#Ausitaraliya Piterawara-Usidẽtawara Hurariyu#,
				'standard' => q#Ausitaraliya Piterawara-Usidẽtawara Hurariyu Retewa#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Ausitaraliya Uriẽtawara Kurasí Ara Hurariyu#,
				'generic' => q#Ausitaraliya Uriẽtawara Hurariyu#,
				'standard' => q#Ausitaraliya Uriẽtawara Hurariyu Retewa#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Ausitaraliya Usidẽtawara Kurasí Ara Hurariyu#,
				'generic' => q#Ausitaraliya Usidẽtawara Hurariyu#,
				'standard' => q#Ausitaraliya Usidẽtawara Hurariyu Retewa#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Aseriretãma Kurasí Ara Hurariyu#,
				'generic' => q#Aseriretãma Hurariyu#,
				'standard' => q#Aseriretãma Hurariyu Retewa#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Asori-ita Kurasí Ara Hurariyu#,
				'generic' => q#Asori-ita Hurariyu#,
				'standard' => q#Asori-ita Hurariyu Retewa#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bãkaradexi Kurasí Ara Horariyu#,
				'generic' => q#Bãkaradexi Horariyu#,
				'standard' => q#Bãkaradexi Horariyu Retewa#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Butãu Hurariyu#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Buríwia Hurariyu#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Rỹ Kã Óra Brasília tá#,
				'generic' => q#Óra Brasília tá#,
				'standard' => q#Óra Pã Brasília tá#,
			},
			short => {
				'daylight' => q#BRST#,
				'generic' => q#BRT#,
				'standard' => q#BRT#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Burunei Darusaram Hurariyu#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kabu Suikiri Kurasí Ara Hurariyu#,
				'generic' => q#Kabu Suikiri Hurariyu#,
				'standard' => q#Kabu Suikiri Hurariyu Retewa#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Xamoro Hurariyu#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Xatham Kurasí Ara Hurariyu#,
				'generic' => q#Xatham Hurariyu#,
				'standard' => q#Xatham Hurariyu Retewa#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Xiri Kurasí Ara Hurariyu#,
				'generic' => q#Xiri Hurariyu#,
				'standard' => q#Xiri Hurariyu Retewa#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Xina Kurasí Ara Hurariyu#,
				'generic' => q#Xina Hurariyu#,
				'standard' => q#Xina Hurariyu Retewa#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Xoibasã Kurasí Ara Hurariyu#,
				'generic' => q#Xoibasã Hurariyu#,
				'standard' => q#Xoibasã Hurariyu Retewa#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#KapuãmaKiritima Hurariyu#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Kapuã-ita Kuku-ita Hurariyu#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kurũbia Kurasí Ara Hurariyu#,
				'generic' => q#Kurũbia Hurariyu#,
				'standard' => q#Kurũbia Hurariyu Retewa#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Kapuã-ita Kooki Kurasí Ara Pitera Hurariyu#,
				'generic' => q#Kapuã-ita Kooki Hurariyu#,
				'standard' => q#Kapuã-ita Kooki Hurariyu Retewa#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kuba Kurasí Ara Hurariyu#,
				'generic' => q#Kuba Hurariyu#,
				'standard' => q#Kuba Hurariyu Retewa#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Dawi Hurariyu#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont-d’Urville Hurariyu#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Timu-Semusawa Hurariyu#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Pasikuwa Kapuãma Kurasí Ara Hurariyu#,
				'generic' => q#Pasikuwa Kapuãma Hurariyu#,
				'standard' => q#Pasikuwa Kapuãma Hurariyu Retewa#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ekuadú Hurariyu#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Hurariyu Mũdi turususawa Kurdenadu#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Tawa-wasú Ũbawaukuamamẽ#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amiteridã#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Ãdura#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Asitarakã#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atena-ita#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Beugaradu#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlim#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Baratisilawa#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Buruxera#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukareti#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapeti#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busĩgeni#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Xisinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopẽyagi#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dubirĩ#,
			long => {
				'daylight' => q#Hurariyu Retewa Irãdei#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibarautá#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guwẽnisei#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Heusĩke#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Mã Kapuãma#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istambul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersei#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Karinĩgaradu#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiyewe#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirowi#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisboa#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Riubiriana#,
		},
		'Europe/London' => {
			exemplarCity => q#Londres#,
			long => {
				'daylight' => q#Hurariyu Kurasí Ara Biritãniku#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Ruxẽbugu#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madri#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Mauta#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariẽyã#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Mĩsiki#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Munaku#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskou#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Usiru#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Pudigurika#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#Sã Marinu#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarayewo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratuwo#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Sĩwerupu#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Isikupiye#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sufiya#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Estocolmo#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tarĩ#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulianuwiki#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Usigurudi#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vadusi#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Watikanu#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wiyena#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Viwiu-ita#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Wugogaradu#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warisówiya#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Sagarebi#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Saporisiya#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zuriki#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Eurupa Piterawara Kurasí Ara Hurariyu#,
				'generic' => q#Eurupa Piterawara Hurariyu#,
				'standard' => q#Eurupa Piterawara Hurariyu Retewa#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Eurupa Uriẽtawara Kurasí Ara Hurariyu#,
				'generic' => q#Eurupa Uriẽtawara Hurariyu#,
				'standard' => q#Eurupa Uriẽtawara Hurariyu Retewa#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Eurupa Lesiti-eté Hurariyu#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Eurupa Usidẽtawara Kurasí Ara Hurariyu#,
				'generic' => q#Eurupa Usidẽtawara Hurariyu#,
				'standard' => q#Eurupa Usidẽtawara Hurariyu Retewa#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Kapuã-ita Mawina Kurasí Ara Hurariyu#,
				'generic' => q#Kapuã-ita Mawina Hurariyu#,
				'standard' => q#Kapuã-ita Mawina Hurariyu Retewa#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fiyi Kurasí Ara Hurariyu#,
				'generic' => q#Fiyi Hurariyu#,
				'standard' => q#Fiyi Hurariyu Retewa#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Giyana Frãsa yara Hurariyu#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Tetãma Su suí Frãsa yara asuí Ãtartida Hurariyu#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich Miridiyanu yara Hurariyu#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Garapagu-ita Hurariyu#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gãbiere Hurariyu#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Geugiya Kurasí Ara Hurariyu#,
				'generic' => q#Geugiya Hurariyu#,
				'standard' => q#Geugiya Hurariyu Retewa#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Kapuã-ita Yubetu Hurariyu#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Guruẽrãdiya Uriẽtawara Kurasí Ara Hurariyu#,
				'generic' => q#Guruẽrãdiya Uriẽtawara Hurariyu#,
				'standard' => q#Guruẽrãdiya Uriẽtawara Hurariyu Retewa#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Guruẽrãdiya Usidẽtawara Kurasí Ara Hurariyu#,
				'generic' => q#Guruẽrãdiya Usidẽtawara Hurariyu#,
				'standard' => q#Guruẽrãdiya Usidẽtawara Hurariyu Retewa#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Guwã Hurariyu Retewa#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Golfo Hurariyu#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Giyana Hurariyu#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaí asuí Kapuã-ita Areuta-ita Kurasí Ara Hurariyu#,
				'generic' => q#Hawaí asuí Kapuã-ita Areuta-ita Hurariyu#,
				'standard' => q#Hawaí asuí Kapuã-ita Areuta-ita Hurariyu Retewa#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hũg Kũg Kurasí Ara Hurariyu#,
				'generic' => q#Hũg Kũg Hurariyu#,
				'standard' => q#Hũg Kũg Hurariyu Retewa#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Howidi Kurasí Ara Hurariyu#,
				'generic' => q#Howidi Hurariyu#,
				'standard' => q#Howidi Hurariyu Retewa#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Ĩdia Hurariyu Retewa#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Ãtananariu#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Xagu-ita#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Kiritima-ita#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kuku-ita#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Kumure-ita#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kergelẽ#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Maé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maudiwa-ita#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Maurisiyu#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayuti#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Yumuatirisawa#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Useyanu Ĩdiku Hurariyu#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Ĩdoxina Hurariyu#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Ĩdonesiya Piterawara Hurariyu#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Ĩdonesiya Uriẽtawara Hurariyu#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Ĩdonesiya Usidẽtawara Hurariyu#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Irã Kurasí Ara Hurariyu#,
				'generic' => q#Irã Hurariyu#,
				'standard' => q#Irã Hurariyu Retewa#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutisiki Kurasí Ara Hurariyu#,
				'generic' => q#Irkutisiki Hurariyu#,
				'standard' => q#Irkutisiki Hurariyu Retewa#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Isirayeu Kurasí Ara Hurariyu#,
				'generic' => q#Isirayeu Hurariyu#,
				'standard' => q#Isirayeu Hurariyu Retewa#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Nipõ Kurasí Ara Hurariyu#,
				'generic' => q#Nipõ Hurariyu#,
				'standard' => q#Nipõ Hurariyu Retewa#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Petropavlovsk-Kamchatski Kurasí Ara Hurariyu#,
				'generic' => q#Petropavlovsk-Kamchatski Hurariyu#,
				'standard' => q#Petropavlovsk-Kamchatski Hurariyu Retewa#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Kasakiretãma Uriẽtawara Hurariyu#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Kasakiretãma Usidẽtawara Hurariyu#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Kureya Kurasí Ara Hurariyu#,
				'generic' => q#Kureya Hurariyu#,
				'standard' => q#Kureya Hurariyu Retewa#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kusirai Hurariyu#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Karasinoyarisiki Kurasí Ara Hurariyu#,
				'generic' => q#Karasinoyarisiki Hurariyu#,
				'standard' => q#Karasinoyarisiki Hurariyu Retewa#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirigiretãma Hurariyu#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Rãka Hurariyu#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Kapuã-ita Inĩbu Hurariyu#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lurudi Howe Kurasí Ara Hurariyu#,
				'generic' => q#Lurudi Howe Hurariyu#,
				'standard' => q#Lurudi Howe Hurariyu Retewa#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Makau Kurasí Ara Hurariyu#,
				'generic' => q#Makau Hurariyu#,
				'standard' => q#Makau Hurariyu Retewa#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Kapuãma Makikuari Hurariyu#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadã Kurasí Ara Hurariyu#,
				'generic' => q#Magadã Hurariyu#,
				'standard' => q#Magadã Hurariyu Retewa#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malasiya Hurariyu#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Kapuã-ita Maudiwa-ita Hurariyu#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Makesa-ita Hurariyu#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Kapuã-ita Marshall Hurariyu#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Maurisiyu Kurasí Ara Hurariyu#,
				'generic' => q#Maurisiyu Hurariyu#,
				'standard' => q#Maurisiyu Hurariyu Retewa#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mausũ Hurariyu#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Mẽsiku Nutiwesiti Kurasí Ara Hurariyu#,
				'generic' => q#Mẽsiku Nutiwesiti Hurariyu#,
				'standard' => q#Mẽsiku Nutiwesiti Hurariyu Retewa#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Pasifiku Mexikanu Kurasí Ara Hurariyu#,
				'generic' => q#Pasifiku Mexikanu Hurariyu#,
				'standard' => q#Pasifiku Mexikanu Hurariyu Retewa#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Urã Baturu Kurasí Ara Hurariyu#,
				'generic' => q#Urã Baturu Hurariyu#,
				'standard' => q#Urã Baturu Hurariyu Retewa#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskou Kurasí Ara Hurariyu#,
				'generic' => q#Moskou Hurariyu#,
				'standard' => q#Moskou Hurariyu Retewa#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Miyamá Hurariyu#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru Hurariyu#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepau Hurariyu#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Karedũniya Pisasú Kurasí Ara Hurariyu#,
				'generic' => q#Karedũniya Pisasú Hurariyu#,
				'standard' => q#Karedũniya Pisasú Hurariyu Retewa#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Serãdiya Pisasú Kurasí Ara Hurariyu#,
				'generic' => q#Serãdiya Pisasú Hurariyu#,
				'standard' => q#Serãdiya Pisasú Hurariyu Retewa#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Iwí Pisasú Kurasí Ara Hurariyu#,
				'generic' => q#Iwí Pisasú Hurariyu#,
				'standard' => q#Iwí Pisasú Hurariyu Retewa#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niwe Hurariyu#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Kapuãma Norfolk Kurasí Ara Hurariyu#,
				'generic' => q#Kapuãma Norfolk Hurariyu#,
				'standard' => q#Kapuãma Norfolk Hurariyu Retewa#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fenãdu Nuruyã Kurasí Ara Hurariyu#,
				'generic' => q#Fenãdu Nuruyã Hurariyu#,
				'standard' => q#Fenãdu Nuruyã Hurariyu Retewa#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Kapuã-ita Mariyãna Nuti suí Hurariyu#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Sibirisiki Pisasú Kurasí Ara Hurariyu#,
				'generic' => q#Sibirisiki Pisasú Hurariyu#,
				'standard' => q#Sibirisiki Pisasú Hurariyu Retewa#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omisiki Kurasí Ara Hurariyu#,
				'generic' => q#Omisiki Hurariyu#,
				'standard' => q#Omisiki Hurariyu Retewa#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Apiya#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Ókirãdi#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Bugaĩwiri#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Xatinã#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Pasikuwa Kapuãma#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Efaté#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Ẽdeburi#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Fakaufu#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fiyi#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Garapagu-ita#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gãbiere#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guadaukanau#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guwã#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Hunururu#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Jũsitũ#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kusirai#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kuayarẽi#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Mayuru#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Makesa-ita#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midiwei#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Niwe#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Nurufuki#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Numeya#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pagu Pagu#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Parau#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Igarapawa Moresby#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarutũga#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saipã#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Taiti#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tũgatapu#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Wari-ita#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakiretãma Kurasí Ara Hurariyu#,
				'generic' => q#Pakiretãma Hurariyu#,
				'standard' => q#Pakiretãma Hurariyu Retewa#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Parau Hurariyu#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papuwa-Giné Pisasú Hurariyu#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#ParaguwaiKurasí Ara Hurariyu#,
				'generic' => q#Paraguwai Hurariyu#,
				'standard' => q#Paraguwai Hurariyu Retewa#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peru Kurasí Ara Hurariyu#,
				'generic' => q#Peru Hurariyu#,
				'standard' => q#Peru Hurariyu Retewa#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Firipina Kurasí Ara Hurariyu#,
				'generic' => q#Firipina Hurariyu#,
				'standard' => q#Firipina Hurariyu Retewa#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Kapuã-ita Fẽnix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Sã Peduru asuí Mikirãu Kurasí Ara Hurariyu#,
				'generic' => q#Sã Peduru asuí Mikirãu Hurariyu#,
				'standard' => q#Sã Peduru asuí Mikirãu Hurariyu Retewa#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairn Hurariyu#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponape Hurariyu#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Piúgiãgi Hurariyu#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Kisiroda Kurasí Ara Hurariyu#,
				'generic' => q#Kisiroda Hurariyu#,
				'standard' => q#Kisiroda Hurariyu Retewa#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Yumuatirisawa Hurariyu#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rotera Hurariyu#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sakarina Kurasí Ara Hurariyu#,
				'generic' => q#Sakarina Hurariyu#,
				'standard' => q#Sakarina Hurariyu Retewa#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samara Kurasí Ara Hurariyu#,
				'generic' => q#Samara Hurariyu#,
				'standard' => q#Samara Hurariyu Retewa#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samowa Kurasí Ara Hurariyu#,
				'generic' => q#Samowa Hurariyu#,
				'standard' => q#Samowa Hurariyu Retewa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seixeri Hurariyu#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Sĩgapura Hurariyu Retewa#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Kapuãma-ita Sarumũ Hurariyu#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Geugiya Su suí Hurariyu#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Suriname Hurariyu#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Siyowa Hurariyu#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Taiti Hurariyu#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipei Kurasí Ara Hurariyu#,
				'generic' => q#Taipei Hurariyu#,
				'standard' => q#Taipei Hurariyu Retewa#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tayikiretãma Hurariyu#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokerau Hurariyu#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tõga Kurasí Ara Hurariyu#,
				'generic' => q#Tõga Hurariyu#,
				'standard' => q#Tõga Hurariyu Retewa#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuuk Hurariyu#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkuranaretãma Kurasí Ara Hurariyu#,
				'generic' => q#Turkuranaretãma Hurariyu#,
				'standard' => q#Turkuranaretãma Hurariyu Retewa#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvaru Hurariyu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguwai Kurasí Ara Hurariyu#,
				'generic' => q#Uruguwai Hurariyu#,
				'standard' => q#Uruguwai Hurariyu Retewa#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Yũbuesara-retãma Kurasí Ara Hurariyu#,
				'generic' => q#Yũbuesara-retãma Hurariyu#,
				'standard' => q#Yũbuesara-retãma Hurariyu Retewa#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Wanuatu Kurasí Ara Hurariyu#,
				'generic' => q#Wanuatu Hurariyu#,
				'standard' => q#Wanuatu Hurariyu Retewa#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Wenẽsuera Hurariyu#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Waradiwosituki Kurasí Ara Hurariyu#,
				'generic' => q#Waradiwosituki Hurariyu#,
				'standard' => q#Waradiwosituki Hurariyu Retewa#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Worwogaradu Kurasí Ara Hurariyu#,
				'generic' => q#Worwogaradu Hurariyu#,
				'standard' => q#Worwogaradu Hurariyu Retewa#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Wosituki Hurariyu#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Kapuã-ita Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wari asuí Futuna Hurariyu#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Yakutisiki Kurasí Ara Hurariyu#,
				'generic' => q#Yakutisiki Hurariyu#,
				'standard' => q#Yakutisiki Hurariyu Retewa#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Ekaterĩbugu Kurasí Ara Hurariyu#,
				'generic' => q#Ekaterĩbugu Hurariyu#,
				'standard' => q#Ekaterĩbugu Hurariyu Retewa#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
