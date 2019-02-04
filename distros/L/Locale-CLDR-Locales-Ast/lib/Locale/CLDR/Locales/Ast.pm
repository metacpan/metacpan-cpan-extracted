=encoding utf8

=head1

Locale::CLDR::Locales::Ast - Package for language Asturian

=cut

package Locale::CLDR::Locales::Ast;
# This file auto generated from Data\common\main\ast.xml
#	on Sun  3 Feb  1:39:17 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.0');

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
				'aa' => 'afar',
 				'ab' => 'abkhazianu',
 				'ace' => 'achinés',
 				'ach' => 'acoli',
 				'ada' => 'adangme',
 				'ady' => 'adyghe',
 				'ae' => 'avestanín',
 				'aeb' => 'árabe de Túnez',
 				'af' => 'afrikaans',
 				'afh' => 'afrihili',
 				'agq' => 'aghem',
 				'ain' => 'ainu',
 				'ak' => 'akan',
 				'akk' => 'acadianu',
 				'akz' => 'alabama',
 				'ale' => 'aleut',
 				'aln' => 'gheg d’Albania',
 				'alt' => 'altai del sur',
 				'am' => 'amháricu',
 				'an' => 'aragonés',
 				'ang' => 'inglés antiguu',
 				'anp' => 'angika',
 				'ar' => 'árabe',
 				'ar_001' => 'árabe estándar modernu',
 				'arc' => 'araméu',
 				'arn' => 'mapuche',
 				'aro' => 'araona',
 				'arp' => 'arapaho',
 				'arq' => 'árabe d’Arxelia',
 				'arw' => 'arawak',
 				'ary' => 'árabe de Marruecos',
 				'arz' => 'árabe d’Exiptu',
 				'as' => 'asamés',
 				'asa' => 'asu',
 				'ase' => 'llingua de signos americana',
 				'ast' => 'asturianu',
 				'av' => 'aváricu',
 				'avk' => 'kotava',
 				'awa' => 'awadhi',
 				'ay' => 'aymara',
 				'az' => 'azerbaixanu',
 				'az@alt=short' => 'azerí',
 				'ba' => 'bashkir',
 				'bal' => 'baluchi',
 				'ban' => 'balinés',
 				'bar' => 'bávaru',
 				'bas' => 'basaa',
 				'bax' => 'bamun',
 				'bbc' => 'batak toba',
 				'bbj' => 'ghomala',
 				'be' => 'bielorrusu',
 				'bej' => 'beja',
 				'bem' => 'bemba',
 				'bew' => 'betawi',
 				'bez' => 'bena',
 				'bfd' => 'bafut',
 				'bfq' => 'badaga',
 				'bg' => 'búlgaru',
 				'bgn' => 'balochi occidental',
 				'bho' => 'bhojpuri',
 				'bi' => 'bislama',
 				'bik' => 'bikol',
 				'bin' => 'bini',
 				'bjn' => 'banjar',
 				'bkm' => 'kom',
 				'bla' => 'siksika',
 				'bm' => 'bambara',
 				'bn' => 'bengalín',
 				'bo' => 'tibetanu',
 				'bpy' => 'bishnupriya',
 				'bqi' => 'bakhtiari',
 				'br' => 'bretón',
 				'bra' => 'braj',
 				'brh' => 'brahui',
 				'brx' => 'bodo',
 				'bs' => 'bosniu',
 				'bss' => 'akoose',
 				'bua' => 'buriat',
 				'bug' => 'buginés',
 				'bum' => 'bulu',
 				'byn' => 'blin',
 				'byv' => 'medumba',
 				'ca' => 'catalán',
 				'cad' => 'caddo',
 				'car' => 'caribe',
 				'cay' => 'cayuga',
 				'cch' => 'atsam',
 				'ce' => 'chechenu',
 				'ceb' => 'cebuanu',
 				'cgg' => 'chiga',
 				'ch' => 'chamorro',
 				'chb' => 'chibcha',
 				'chg' => 'chagatai',
 				'chk' => 'chuukés',
 				'chm' => 'mari',
 				'chn' => 'xíriga chinook',
 				'cho' => 'choctaw',
 				'chp' => 'chipewyanu',
 				'chr' => 'cheroqui',
 				'chy' => 'cheyenne',
 				'ckb' => 'kurdu central',
 				'co' => 'corsu',
 				'cop' => 'cópticu',
 				'cps' => 'capiznon',
 				'cr' => 'cree',
 				'crh' => 'turcu de Crimea',
 				'crs' => 'francés criollu seselwa',
 				'cs' => 'checu',
 				'csb' => 'kashubianu',
 				'cu' => 'eslávicu eclesiásticu',
 				'cv' => 'chuvash',
 				'cy' => 'galés',
 				'da' => 'danés',
 				'dak' => 'dakota',
 				'dar' => 'dargwa',
 				'dav' => 'taita',
 				'de' => 'alemán',
 				'de_AT' => 'alemán d’Austria',
 				'de_CH' => 'altualemán de Suiza',
 				'del' => 'delaware',
 				'den' => 'slave',
 				'dgr' => 'dogrib',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'baxu sorbiu',
 				'dtp' => 'dusun central',
 				'dua' => 'duala',
 				'dum' => 'neerlandés mediu',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dyu' => 'dyula',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazaga',
 				'ebu' => 'embú',
 				'ee' => 'ewe',
 				'efi' => 'efik',
 				'egl' => 'emilianu',
 				'egy' => 'exipciu antiguu',
 				'eka' => 'ekajuk',
 				'el' => 'griegu',
 				'elx' => 'elamita',
 				'en' => 'inglés',
 				'en_AU' => 'inglés d’Australia',
 				'en_CA' => 'inglés de Canadá',
 				'en_GB' => 'inglés de Gran Bretaña',
 				'en_GB@alt=short' => 'inglés del R.X.',
 				'en_US' => 'inglés d’Estaos Xuníos',
 				'en_US@alt=short' => 'inglés d’EE.XX.',
 				'enm' => 'inglés mediu',
 				'eo' => 'esperanto',
 				'es' => 'español',
 				'es_419' => 'español d’América Llatina',
 				'es_ES' => 'español européu',
 				'es_MX' => 'español de Méxicu',
 				'esu' => 'yupik central',
 				'et' => 'estoniu',
 				'eu' => 'vascu',
 				'ewo' => 'ewondo',
 				'ext' => 'estremeñu',
 				'fa' => 'persa',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fulah',
 				'fi' => 'finlandés',
 				'fil' => 'filipín',
 				'fit' => 'finlandés de Tornedalen',
 				'fj' => 'fixanu',
 				'fo' => 'feroés',
 				'fon' => 'fon',
 				'fr' => 'francés',
 				'fr_CA' => 'francés de Canadá',
 				'fr_CH' => 'francés de Suiza',
 				'frc' => 'francés cajun',
 				'frm' => 'francés mediu',
 				'fro' => 'francés antiguu',
 				'frp' => 'arpitanu',
 				'frr' => 'frisón del norte',
 				'frs' => 'frisón oriental',
 				'fur' => 'friulianu',
 				'fy' => 'frisón occidental',
 				'ga' => 'irlandés',
 				'gaa' => 'ga',
 				'gag' => 'gagauz',
 				'gan' => 'chinu gan',
 				'gay' => 'gayo',
 				'gba' => 'gbaya',
 				'gbz' => 'dari zoroastrianu',
 				'gd' => 'gaélicu escocés',
 				'gez' => 'geez',
 				'gil' => 'gilbertés',
 				'gl' => 'gallegu',
 				'glk' => 'gilaki',
 				'gmh' => 'altualemán mediu',
 				'gn' => 'guaraní',
 				'goh' => 'altualemán antiguu',
 				'gom' => 'goan konkani',
 				'gon' => 'gondi',
 				'gor' => 'gorontalo',
 				'got' => 'góticu',
 				'grb' => 'grebo',
 				'grc' => 'griegu antiguu',
 				'gsw' => 'alemán de Suiza',
 				'gu' => 'guyaratí',
 				'guc' => 'wayuu',
 				'gur' => 'frafra',
 				'guz' => 'gusii',
 				'gv' => 'manés',
 				'gwi' => 'gwichʼin',
 				'ha' => 'ḥausa',
 				'hai' => 'haida',
 				'hak' => 'chinu hakka',
 				'haw' => 'hawaianu',
 				'he' => 'hebréu',
 				'hi' => 'hindi',
 				'hif' => 'hindi de Fiji',
 				'hil' => 'hiligaynon',
 				'hit' => 'hitita',
 				'hmn' => 'hmong',
 				'ho' => 'hiri motu',
 				'hr' => 'croata',
 				'hsb' => 'altu sorbiu',
 				'hsn' => 'chinu xiang',
 				'ht' => 'haitianu',
 				'hu' => 'húngaru',
 				'hup' => 'hupa',
 				'hy' => 'armeniu',
 				'hz' => 'herero',
 				'ia' => 'interlingua',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonesiu',
 				'ie' => 'interlingue',
 				'ig' => 'igbo',
 				'ii' => 'yi de Sichuán',
 				'ik' => 'inupiaq',
 				'ilo' => 'iloko',
 				'inh' => 'ingush',
 				'io' => 'ido',
 				'is' => 'islandés',
 				'it' => 'italianu',
 				'iu' => 'inuktitut',
 				'izh' => 'ingrianu',
 				'ja' => 'xaponés',
 				'jam' => 'inglés criollu xamaicanu',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jpr' => 'xudeo-persa',
 				'jrb' => 'xudeo-árabe',
 				'jut' => 'jutlandés',
 				'jv' => 'xavanés',
 				'ka' => 'xeorxanu',
 				'kaa' => 'kara-kalpak',
 				'kab' => 'kabileñu',
 				'kac' => 'kachin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kaw' => 'kawi',
 				'kbd' => 'kabardianu',
 				'kbl' => 'kanembu',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'cabuverdianu',
 				'ken' => 'kenyang',
 				'kfo' => 'koro',
 				'kg' => 'kongo',
 				'kgp' => 'kaingang',
 				'kha' => 'khasi',
 				'kho' => 'khotanés',
 				'khq' => 'koyra chiini',
 				'khw' => 'khowar',
 				'ki' => 'kikuyu',
 				'kiu' => 'kirmanjki',
 				'kj' => 'kuanyama',
 				'kk' => 'kazaquistanín',
 				'kkj' => 'kako',
 				'kl' => 'kalaallisut',
 				'kln' => 'kalenjin',
 				'km' => 'ḥemer',
 				'kmb' => 'kimbundu',
 				'kn' => 'canarés',
 				'ko' => 'coreanu',
 				'koi' => 'komi-permyak',
 				'kok' => 'konkani',
 				'kos' => 'kosraeanu',
 				'kpe' => 'kpelle',
 				'kr' => 'kanuri',
 				'krc' => 'karachay-balkar',
 				'kri' => 'krio',
 				'krj' => 'kinaray-a',
 				'krl' => 'karelianu',
 				'kru' => 'kurukh',
 				'ks' => 'cachemirés',
 				'ksb' => 'shambala',
 				'ksf' => 'bafia',
 				'ksh' => 'colonianu',
 				'ku' => 'curdu',
 				'kum' => 'kumyk',
 				'kut' => 'kutenai',
 				'kv' => 'komi',
 				'kw' => 'córnicu',
 				'ky' => 'kirguistanín',
 				'la' => 'llatín',
 				'lad' => 'ladino',
 				'lag' => 'langi',
 				'lah' => 'lahnda',
 				'lam' => 'lamba',
 				'lb' => 'luxemburgués',
 				'lez' => 'lezghianu',
 				'lfn' => 'lingua franca nova',
 				'lg' => 'ganda',
 				'li' => 'limburgués',
 				'lij' => 'ligurianu',
 				'liv' => 'livonianu',
 				'lkt' => 'lakota',
 				'lmo' => 'lombardu',
 				'ln' => 'lingala',
 				'lo' => 'laosianu',
 				'lol' => 'mongo',
 				'loz' => 'lozi',
 				'lrc' => 'luri del norte',
 				'lt' => 'lituanu',
 				'ltg' => 'latgalianu',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lui' => 'luiseno',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'mizo',
 				'luy' => 'luyia',
 				'lv' => 'letón',
 				'lzh' => 'chinu lliterariu',
 				'lzz' => 'laz',
 				'mad' => 'madurés',
 				'maf' => 'mafa',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'makasar',
 				'man' => 'mandingo',
 				'mas' => 'masái',
 				'mde' => 'maba',
 				'mdf' => 'moksha',
 				'mdr' => 'mandar',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'morisyen',
 				'mg' => 'malgaxe',
 				'mga' => 'írlandés mediu',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'marshallés',
 				'mi' => 'maorí',
 				'mic' => 'micmac',
 				'min' => 'minangkabau',
 				'mk' => 'macedoniu',
 				'ml' => 'malayalam',
 				'mn' => 'mongol',
 				'mnc' => 'manchú',
 				'mni' => 'manipuri',
 				'moh' => 'mohawk',
 				'mos' => 'mossi',
 				'mr' => 'marathi',
 				'mrj' => 'mari occidental',
 				'ms' => 'malayu',
 				'mt' => 'maltés',
 				'mua' => 'mundang',
 				'mul' => 'múltiples llingües',
 				'mus' => 'creek',
 				'mwl' => 'mirandés',
 				'mwr' => 'marwari',
 				'mwv' => 'mentawai',
 				'my' => 'birmanu',
 				'mye' => 'myene',
 				'myv' => 'erzya',
 				'mzn' => 'mazanderani',
 				'na' => 'nauru',
 				'nan' => 'chinu min nan',
 				'nap' => 'napolitanu',
 				'naq' => 'nama',
 				'nb' => 'noruegu Bokmål',
 				'nd' => 'ndebele del norte',
 				'nds' => 'baxu alemán',
 				'nds_NL' => 'baxu saxón',
 				'ne' => 'nepalés',
 				'new' => 'newari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niueanu',
 				'njo' => 'ao naga',
 				'nl' => 'neerlandés',
 				'nl_BE' => 'flamencu',
 				'nmg' => 'kwasio',
 				'nn' => 'noruegu Nynorsk',
 				'nnh' => 'ngiemboon',
 				'no' => 'noruegu',
 				'nog' => 'nogai',
 				'non' => 'noruegu antiguu',
 				'nov' => 'novial',
 				'nqo' => 'n’ko',
 				'nr' => 'ndebele del sur',
 				'nso' => 'sotho del norte',
 				'nus' => 'nuer',
 				'nv' => 'navajo',
 				'nwc' => 'newari clásicu',
 				'ny' => 'nyanja',
 				'nym' => 'nyamwezi',
 				'nyn' => 'nyankole',
 				'nyo' => 'nyoro',
 				'nzi' => 'nzima',
 				'oc' => 'occitanu',
 				'oj' => 'ojibwa',
 				'om' => 'oromo',
 				'or' => 'oriya',
 				'os' => 'oséticu',
 				'osa' => 'osage',
 				'ota' => 'turcu otomanu',
 				'pa' => 'punyabí',
 				'pag' => 'pangasinan',
 				'pal' => 'pahlavi',
 				'pam' => 'pampanga',
 				'pap' => 'papiamento',
 				'pau' => 'palauanu',
 				'pcd' => 'pícaru',
 				'pcm' => 'nixerianu simplificáu',
 				'pdc' => 'alemán de Pennsylvania',
 				'pdt' => 'plautdietsch',
 				'peo' => 'persa antiguu',
 				'pfl' => 'alemán palatinu',
 				'phn' => 'feniciu',
 				'pi' => 'pali',
 				'pl' => 'polacu',
 				'pms' => 'piamontés',
 				'pnt' => 'pónticu',
 				'pon' => 'pohnpeianu',
 				'prg' => 'prusianu',
 				'pro' => 'provenzal antiguu',
 				'ps' => 'pashtu',
 				'pt' => 'portugués',
 				'pt_BR' => 'portugués del Brasil',
 				'pt_PT' => 'portugués européu',
 				'qu' => 'quechua',
 				'quc' => 'kʼicheʼ',
 				'qug' => 'quichua del altiplanu de Chimborazo',
 				'raj' => 'rajasthanín',
 				'rap' => 'rapanui',
 				'rar' => 'rarotonganu',
 				'rgn' => 'romañol',
 				'rif' => 'rifianu',
 				'rm' => 'romanche',
 				'rn' => 'rundi',
 				'ro' => 'rumanu',
 				'ro_MD' => 'moldavu',
 				'rof' => 'rombo',
 				'rom' => 'romaní',
 				'root' => 'root',
 				'rtm' => 'rotumanu',
 				'ru' => 'rusu',
 				'rue' => 'rusyn',
 				'rug' => 'roviana',
 				'rup' => 'aromanianu',
 				'rw' => 'kinyarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sánscritu',
 				'sad' => 'sandavés',
 				'sah' => 'sakha',
 				'sam' => 'araméu samaritanu',
 				'saq' => 'samburu',
 				'sas' => 'sasak',
 				'sat' => 'santali',
 				'saz' => 'saurashtra',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sardu',
 				'scn' => 'sicilianu',
 				'sco' => 'scots',
 				'sd' => 'sindhi',
 				'sdc' => 'sardu sassarés',
 				'sdh' => 'kurdu del sur',
 				'se' => 'sami del norte',
 				'see' => 'séneca',
 				'seh' => 'sena',
 				'sei' => 'seri',
 				'sel' => 'selkup',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'sga' => 'irlandés antiguu',
 				'sgs' => 'samogitianu',
 				'sh' => 'serbo-croata',
 				'shi' => 'tachelhit',
 				'shn' => 'shan',
 				'shu' => 'árabe chadianu',
 				'si' => 'cingalés',
 				'sid' => 'sidamo',
 				'sk' => 'eslovacu',
 				'sl' => 'eslovenu',
 				'sli' => 'baxu silesianu',
 				'sly' => 'selayarés',
 				'sm' => 'samoanu',
 				'sma' => 'sami del sur',
 				'smj' => 'lule sami',
 				'smn' => 'inari sami',
 				'sms' => 'skolt sami',
 				'sn' => 'shona',
 				'snk' => 'soninke',
 				'so' => 'somalín',
 				'sog' => 'sogdianu',
 				'sq' => 'albanu',
 				'sr' => 'serbiu',
 				'srn' => 'sranan tongo',
 				'srr' => 'serer',
 				'ss' => 'swati',
 				'ssy' => 'saho',
 				'st' => 'sotho del sur',
 				'stq' => 'frisón de Saterland',
 				'su' => 'sondanés',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumeriu',
 				'sv' => 'suecu',
 				'sw' => 'suaḥili',
 				'sw_CD' => 'suaḥili del Congu',
 				'swb' => 'comorianu',
 				'syc' => 'siriacu clásicu',
 				'syr' => 'siriacu',
 				'szl' => 'silesianu',
 				'ta' => 'tamil',
 				'tcy' => 'tulu',
 				'te' => 'telugu',
 				'tem' => 'timne',
 				'teo' => 'teso',
 				'ter' => 'terena',
 				'tet' => 'tetum',
 				'tg' => 'taxiquistanín',
 				'th' => 'tailandés',
 				'ti' => 'tigrinya',
 				'tig' => 'tigre',
 				'tiv' => 'tiv',
 				'tk' => 'turcomanu',
 				'tkl' => 'tokelau',
 				'tkr' => 'tsakhur',
 				'tl' => 'tagalog',
 				'tlh' => 'klingon',
 				'tli' => 'tlingit',
 				'tly' => 'talixín',
 				'tmh' => 'tamashek',
 				'tn' => 'tswana',
 				'to' => 'tonganu',
 				'tog' => 'tonga nyasa',
 				'tpi' => 'tok pisin',
 				'tr' => 'turcu',
 				'tru' => 'turoyo',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsd' => 'tsakoniu',
 				'tsi' => 'tsimshian',
 				'tt' => 'tártaru',
 				'ttt' => 'tati musulmán',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalu',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitianu',
 				'tyv' => 'tuvinianu',
 				'tzm' => 'tamazight del Atles central',
 				'udm' => 'udmurt',
 				'ug' => 'uigur',
 				'uga' => 'ugaríticu',
 				'uk' => 'ucraín',
 				'umb' => 'umbundu',
 				'und' => 'llingua desconocida',
 				'ur' => 'urdu',
 				'uz' => 'uzbequistanín',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vec' => 'venecianu',
 				'vep' => 'vepsiu',
 				'vi' => 'vietnamín',
 				'vls' => 'flamencu occidental',
 				'vmf' => 'franconianu del Main',
 				'vo' => 'volapük',
 				'vot' => 'vóticu',
 				'vro' => 'voro',
 				'vun' => 'vunjo',
 				'wa' => 'valón',
 				'wae' => 'walser',
 				'wal' => 'wolaytta',
 				'war' => 'waray',
 				'was' => 'washo',
 				'wbp' => 'warlpiri',
 				'wo' => 'wolof',
 				'wuu' => 'chinu wu',
 				'xal' => 'calmuco',
 				'xh' => 'xhosa',
 				'xmf' => 'mingrelianu',
 				'xog' => 'soga',
 				'yao' => 'yao',
 				'yap' => 'yapés',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'yiddish',
 				'yo' => 'yoruba',
 				'yrl' => 'nheengatu',
 				'yue' => 'cantonés',
 				'za' => 'zhuang',
 				'zap' => 'zapoteca',
 				'zbl' => 'simbólicu Bliss',
 				'zea' => 'zeelandés',
 				'zen' => 'zenaga',
 				'zgh' => 'tamazight estándar de Marruecos',
 				'zh' => 'chinu',
 				'zh_Hans' => 'chinu simplificáu',
 				'zh_Hant' => 'chinu tradicional',
 				'zu' => 'zulú',
 				'zun' => 'zuni',
 				'zxx' => 'ensin conteníu llingüísticu',
 				'zza' => 'zaza',

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
			'Adlm' => 'adlm',
 			'Afak' => 'afaka',
 			'Aghb' => 'cáucaso-albanés',
 			'Ahom' => 'ahom',
 			'Arab' => 'árabe',
 			'Armi' => 'aramaicu imperial',
 			'Armn' => 'armeniu',
 			'Avst' => 'avésticu',
 			'Bali' => 'balinés',
 			'Bamu' => 'bamum',
 			'Bass' => 'bassa vah',
 			'Batk' => 'batak',
 			'Beng' => 'bengalín',
 			'Bhks' => 'bhks',
 			'Blis' => 'símbolos de Bliss',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'brahmi',
 			'Brai' => 'braille',
 			'Bugi' => 'lontara',
 			'Buhd' => 'buhid',
 			'Cakm' => 'chakma',
 			'Cans' => 'silábicu unificáu de los nativos canadienses',
 			'Cari' => 'cariu',
 			'Cham' => 'cham',
 			'Cher' => 'cheroki',
 			'Cirt' => 'cirth',
 			'Copt' => 'coptu',
 			'Cprt' => 'xipriota',
 			'Cyrl' => 'cirílicu',
 			'Cyrs' => 'eslavónicu cirílicu eclesiásticu antiguu',
 			'Deva' => 'devanagari',
 			'Dsrt' => 'alfabetu Deseret',
 			'Dupl' => 'taquigrafía Duployé',
 			'Egyd' => 'demóticu exipcianu',
 			'Egyh' => 'hieráticu exipcianu',
 			'Egyp' => 'xeroglíficos exipcianos',
 			'Elba' => 'elbasan',
 			'Ethi' => 'etíope',
 			'Geok' => 'khutsuri xeorxanu',
 			'Geor' => 'xeorxanu',
 			'Glag' => 'glagolíticu',
 			'Goth' => 'góticu',
 			'Gran' => 'grantha',
 			'Grek' => 'griegu',
 			'Gujr' => 'guyarati',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'hanb',
 			'Hang' => 'hangul',
 			'Hani' => 'han',
 			'Hano' => 'hanunó’o',
 			'Hans' => 'simplificáu',
 			'Hans@alt=stand-alone' => 'han simplificáu',
 			'Hant' => 'tradicional',
 			'Hant@alt=stand-alone' => 'han tradicional',
 			'Hatr' => 'hatranu',
 			'Hebr' => 'hebréu',
 			'Hira' => 'ḥiragana',
 			'Hluw' => 'xeroglíficos anatolios',
 			'Hmng' => 'pahawh hmong',
 			'Hrkt' => 'silabarios xaponeses',
 			'Hung' => 'húngaru antiguu',
 			'Inds' => 'indus',
 			'Ital' => 'itálicu antiguu',
 			'Jamo' => 'jamo',
 			'Java' => 'xavanés',
 			'Jpan' => 'xaponés',
 			'Jurc' => 'jurchen',
 			'Kali' => 'kayah li',
 			'Kana' => 'katakana',
 			'Khar' => 'kharoshthi',
 			'Khmr' => 'ḥemer',
 			'Khoj' => 'khojki',
 			'Knda' => 'canarés',
 			'Kore' => 'coreanu',
 			'Kpel' => 'kpelle',
 			'Kthi' => 'kaithi',
 			'Lana' => 'lanna',
 			'Laoo' => 'laosianu',
 			'Latf' => 'fraktur llatín',
 			'Latg' => 'gaélicu llatín',
 			'Latn' => 'llatín',
 			'Lepc' => 'lepcha',
 			'Limb' => 'limbu',
 			'Lina' => 'llinial A',
 			'Linb' => 'llinial B',
 			'Lisu' => 'alfabetu de Fraser',
 			'Loma' => 'loma',
 			'Lyci' => 'liciu',
 			'Lydi' => 'lidiu',
 			'Mahj' => 'mahajani',
 			'Mand' => 'mandéu',
 			'Mani' => 'maniquéu',
 			'Marc' => 'marc',
 			'Maya' => 'xeroglíficos mayes',
 			'Mend' => 'mende',
 			'Merc' => 'meroíticu en cursiva',
 			'Mero' => 'meroíticu',
 			'Mlym' => 'malayalam',
 			'Modi' => 'modi',
 			'Mong' => 'mongol',
 			'Moon' => 'tipos Moon',
 			'Mroo' => 'mro',
 			'Mtei' => 'meitei mayek',
 			'Mult' => 'multani',
 			'Mymr' => 'birmanu',
 			'Narb' => 'árabe del norte antiguu',
 			'Nbat' => 'nabatéu',
 			'Newa' => 'newa',
 			'Nkgb' => 'geba del naxi',
 			'Nkoo' => 'n’ko',
 			'Nshu' => 'nüshu',
 			'Ogam' => 'ogham',
 			'Olck' => 'ol chiki',
 			'Orkh' => 'orkhon',
 			'Orya' => 'oriya',
 			'Osge' => 'osge',
 			'Osma' => 'osmanya',
 			'Palm' => 'palmirenu',
 			'Pauc' => 'pau cin hau',
 			'Perm' => 'pérmicu antiguu',
 			'Phag' => 'escritura ‘Phags-pa',
 			'Phli' => 'pahlavi d’inscripciones',
 			'Phlp' => 'pahlavi de salteriu',
 			'Phlv' => 'pahlavi de llibros',
 			'Phnx' => 'feniciu',
 			'Plrd' => 'fonéticu de Pollard',
 			'Prti' => 'partu d’inscripciones',
 			'Rjng' => 'rejang',
 			'Roro' => 'rongorongo',
 			'Runr' => 'runes',
 			'Samr' => 'samaritanu',
 			'Sara' => 'sarati',
 			'Sarb' => 'árabe del sur antiguu',
 			'Saur' => 'saurashtra',
 			'Sgnw' => 'escritura de signos',
 			'Shaw' => 'shavianu',
 			'Shrd' => 'sharada',
 			'Sidd' => 'siddham',
 			'Sind' => 'khudabadi',
 			'Sinh' => 'cingalés',
 			'Sora' => 'sora sompeng',
 			'Sund' => 'sondanés',
 			'Sylo' => 'syloti nagri',
 			'Syrc' => 'siriacu',
 			'Syre' => 'siriacu estrangelo',
 			'Syrj' => 'siriacu occidental',
 			'Syrn' => 'siriacu oriental',
 			'Tagb' => 'tagbanwa',
 			'Takr' => 'takri',
 			'Tale' => 'tai le',
 			'Talu' => 'tai lue nuevu',
 			'Taml' => 'tamil',
 			'Tang' => 'tangut',
 			'Tavt' => 'tai viet',
 			'Telu' => 'telugu',
 			'Teng' => 'tengwar',
 			'Tfng' => 'tifinagh',
 			'Tglg' => 'tagalog',
 			'Thaa' => 'thaana',
 			'Thai' => 'tailandés',
 			'Tibt' => 'tibetanu',
 			'Tirh' => 'tirhuta',
 			'Ugar' => 'ugaríticu',
 			'Vaii' => 'vai',
 			'Visp' => 'fala visible',
 			'Wara' => 'varang kshiti',
 			'Wole' => 'woleai',
 			'Xpeo' => 'persa antiguu',
 			'Xsux' => 'cuneiforme sumeriu acadiu',
 			'Yiii' => 'yi',
 			'Zinh' => 'heredáu',
 			'Zmth' => 'escritura matemática',
 			'Zsye' => 'emoji',
 			'Zsym' => 'símbolos',
 			'Zxxx' => 'non escritu',
 			'Zyyy' => 'común',
 			'Zzzz' => 'escritura desconocida',

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
			'001' => 'Mundu',
 			'002' => 'África',
 			'003' => 'Norteamérica',
 			'005' => 'América del Sur',
 			'009' => 'Oceanía',
 			'011' => 'África Occidental',
 			'013' => 'América Central',
 			'014' => 'África Oriental',
 			'015' => 'África del Norte',
 			'017' => 'África Central',
 			'018' => 'África del Sur',
 			'019' => 'América',
 			'021' => 'América del Norte',
 			'029' => 'Caribe',
 			'030' => 'Asia Oriental',
 			'034' => 'Asia del Sur',
 			'035' => 'Sureste Asiáticu',
 			'039' => 'Europa del Sur',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Rexón de Micronesia',
 			'061' => 'Polinesia',
 			'142' => 'Asia',
 			'143' => 'Asia Central',
 			'145' => 'Asia Occidental',
 			'150' => 'Europa',
 			'151' => 'Europa Oriental',
 			'154' => 'Europa del Norte',
 			'155' => 'Europa Occidental',
 			'419' => 'América Llatina',
 			'AC' => 'Islla Ascensión',
 			'AD' => 'Andorra',
 			'AE' => 'Emiratos Árabes Xuníos',
 			'AF' => 'Afganistán',
 			'AG' => 'Antigua y Barbuda',
 			'AI' => 'Anguila',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'L’Antártida',
 			'AR' => 'Arxentina',
 			'AS' => 'Samoa Americana',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Islles Aland',
 			'AZ' => 'Azerbaixán',
 			'BA' => 'Bosnia y Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladex',
 			'BE' => 'Bélxica',
 			'BF' => 'Burkina Fasu',
 			'BG' => 'Bulgaria',
 			'BH' => 'Baḥréin',
 			'BI' => 'Burundi',
 			'BJ' => 'Benín',
 			'BL' => 'San Bartolomé',
 			'BM' => 'Les Bermudes',
 			'BN' => 'Brunéi',
 			'BO' => 'Bolivia',
 			'BQ' => 'Caribe neerlandés',
 			'BR' => 'Brasil',
 			'BS' => 'Les Bahames',
 			'BT' => 'Bután',
 			'BV' => 'Islla Bouvet',
 			'BW' => 'Botsuana',
 			'BY' => 'Bielorrusia',
 			'BZ' => 'Belize',
 			'CA' => 'Canadá',
 			'CC' => 'Islles Cocos (Keeling)',
 			'CD' => 'Congu - Kinxasa',
 			'CD@alt=variant' => 'Congu (RDC)',
 			'CF' => 'República Centroafricana',
 			'CG' => 'Congu - Brazzaville',
 			'CG@alt=variant' => 'Congu (República del)',
 			'CH' => 'Suiza',
 			'CI' => 'Costa de Marfil',
 			'CI@alt=variant' => 'Costa del Marfil',
 			'CK' => 'Islles Cook',
 			'CL' => 'Chile',
 			'CM' => 'Camerún',
 			'CN' => 'China',
 			'CO' => 'Colombia',
 			'CP' => 'Islla Clipperton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cabu Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Islla Christmas',
 			'CY' => 'Xipre',
 			'CZ' => 'Chequia',
 			'CZ@alt=variant' => 'República Checa',
 			'DE' => 'Alemaña',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Xibuti',
 			'DK' => 'Dinamarca',
 			'DM' => 'Dominica',
 			'DO' => 'República Dominicana',
 			'DZ' => 'Arxelia',
 			'EA' => 'Ceuta y Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Exiptu',
 			'EH' => 'Sáḥara Occidental',
 			'ER' => 'Eritrea',
 			'ES' => 'España',
 			'ET' => 'Etiopía',
 			'EU' => 'Xunión Europea',
 			'EZ' => 'Eurozona',
 			'FI' => 'Finlandia',
 			'FJ' => 'Islles Fixi',
 			'FK' => 'Falkland Islands',
 			'FK@alt=variant' => 'Islles Malvines (Falkland Islands)',
 			'FM' => 'Micronesia',
 			'FO' => 'Islles Feroe',
 			'FR' => 'Francia',
 			'GA' => 'Gabón',
 			'GB' => 'Reinu Xuníu',
 			'GB@alt=short' => 'RX',
 			'GD' => 'Granada',
 			'GE' => 'Xeorxa',
 			'GF' => 'Guyana Francesa',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Xibraltar',
 			'GL' => 'Groenlandia',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadalupe',
 			'GQ' => 'Guinea Ecuatorial',
 			'GR' => 'Grecia',
 			'GS' => 'Islles Xeorxa del Sur y Sandwich del Sur',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bisáu',
 			'GY' => 'Guyana',
 			'HK' => 'ARE China de Ḥong Kong',
 			'HK@alt=short' => 'Ḥong Kong',
 			'HM' => 'Islles Heard y McDonald',
 			'HN' => 'Hondures',
 			'HR' => 'Croacia',
 			'HT' => 'Haití',
 			'HU' => 'Hungría',
 			'IC' => 'Islles Canaries',
 			'ID' => 'Indonesia',
 			'IE' => 'Irlanda',
 			'IL' => 'Israel',
 			'IM' => 'Islla de Man',
 			'IN' => 'India',
 			'IO' => 'Territoriu Británicu del Océanu Índicu',
 			'IQ' => 'Iraq',
 			'IR' => 'Irán',
 			'IS' => 'Islandia',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Xamaica',
 			'JO' => 'Xordania',
 			'JP' => 'Xapón',
 			'KE' => 'Kenia',
 			'KG' => 'Kirguistán',
 			'KH' => 'Camboya',
 			'KI' => 'Kiribati',
 			'KM' => 'Les Comores',
 			'KN' => 'Saint Kitts y Nevis',
 			'KP' => 'Corea del Norte',
 			'KR' => 'Corea del Sur',
 			'KW' => 'Kuwait',
 			'KY' => 'Islles Caimán',
 			'KZ' => 'Kazakstán',
 			'LA' => 'Laos',
 			'LB' => 'Líbanu',
 			'LC' => 'Santa Llucía',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesothu',
 			'LT' => 'Lituania',
 			'LU' => 'Luxemburgu',
 			'LV' => 'Letonia',
 			'LY' => 'Libia',
 			'MA' => 'Marruecos',
 			'MC' => 'Mónacu',
 			'MD' => 'Moldavia',
 			'ME' => 'Montenegru',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagascar',
 			'MH' => 'Islles Marshall',
 			'MK' => 'Macedonia',
 			'MK@alt=variant' => 'Macedonia (ARYDM)',
 			'ML' => 'Malí',
 			'MM' => 'Myanmar (Birmania)',
 			'MN' => 'Mongolia',
 			'MO' => 'ARE China de Macáu',
 			'MO@alt=short' => 'Macáu',
 			'MP' => 'Islles Marianes del Norte',
 			'MQ' => 'La Martinica',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauriciu',
 			'MV' => 'Les Maldives',
 			'MW' => 'Malaui',
 			'MX' => 'Méxicu',
 			'MY' => 'Malasia',
 			'MZ' => 'Mozambique',
 			'NA' => 'Namibia',
 			'NC' => 'Nueva Caledonia',
 			'NE' => 'El Níxer',
 			'NF' => 'Islla Norfolk',
 			'NG' => 'Nixeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Países Baxos',
 			'NO' => 'Noruega',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nueva Zelanda',
 			'OM' => 'Omán',
 			'PA' => 'Panamá',
 			'PE' => 'Perú',
 			'PF' => 'Polinesia Francesa',
 			'PG' => 'Papúa Nueva Guinea',
 			'PH' => 'Filipines',
 			'PK' => 'Paquistán',
 			'PL' => 'Polonia',
 			'PM' => 'Saint Pierre y Miquelon',
 			'PN' => 'Islles Pitcairn',
 			'PR' => 'Puertu Ricu',
 			'PS' => 'Territorios Palestinos',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Paláu',
 			'PY' => 'Paraguái',
 			'QA' => 'Qatar',
 			'QO' => 'Oceanía esterior',
 			'RE' => 'Reunión',
 			'RO' => 'Rumanía',
 			'RS' => 'Serbia',
 			'RU' => 'Rusia',
 			'RW' => 'Ruanda',
 			'SA' => 'Arabia Saudita',
 			'SB' => 'Islles Salomón',
 			'SC' => 'Les Seixeles',
 			'SD' => 'Sudán',
 			'SE' => 'Suecia',
 			'SG' => 'Singapur',
 			'SH' => 'Santa Helena',
 			'SI' => 'Eslovenia',
 			'SJ' => 'Svalbard ya Islla Jan Mayen',
 			'SK' => 'Eslovaquia',
 			'SL' => 'Sierra Lleona',
 			'SM' => 'San Marín',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinam',
 			'SS' => 'Sudán del Sur',
 			'ST' => 'Santu Tomé y Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Siria',
 			'SZ' => 'Suazilandia',
 			'TA' => 'Tristán da Cunha',
 			'TC' => 'Islles Turques y Caicos',
 			'TD' => 'Chad',
 			'TF' => 'Tierres Australes Franceses',
 			'TG' => 'Togu',
 			'TH' => 'Tailandia',
 			'TJ' => 'Taxiquistán',
 			'TK' => 'Tokeláu',
 			'TL' => 'Timor Oriental',
 			'TL@alt=variant' => 'Timor Este',
 			'TM' => 'Turkmenistán',
 			'TN' => 'Tunicia',
 			'TO' => 'Tonga',
 			'TR' => 'Turquía',
 			'TT' => 'Trinidá y Tobagu',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwán',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ucraína',
 			'UG' => 'Uganda',
 			'UM' => 'Islles Perifériques Menores de los EE.XX.',
 			'UN' => 'Naciones Xuníes',
 			'US' => 'Estaos Xuníos',
 			'US@alt=short' => 'EE.XX.',
 			'UY' => 'Uruguái',
 			'UZ' => 'Uzbequistán',
 			'VA' => 'Ciudá del Vaticanu',
 			'VC' => 'San Vicente y Granadines',
 			'VE' => 'Venezuela',
 			'VG' => 'Islles Vírxenes Britániques',
 			'VI' => 'Islles Vírxenes Americanes',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis y Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovu',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Sudáfrica',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabue',
 			'ZZ' => 'Rexón desconocida',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'1901' => 'ortografía alemana tradicional',
 			'1994' => 'ortografía resiana estandarizada',
 			'1996' => 'ortografía alemana de 1996',
 			'1606NICT' => 'últimu francés mediu fasta 1606',
 			'1694ACAD' => 'francés modernu primitivu',
 			'1959ACAD' => 'académicu',
 			'ABL1943' => 'formulación ortográfica de 1943',
 			'ALALC97' => 'romanizacion ALA-LC, edicion de 1997',
 			'ALUKU' => 'dialectu aluku',
 			'AO1990' => 'alcuerdu ortográficu de 1990 pa la llingua portuguesa',
 			'AREVELA' => 'armeniu oriental',
 			'AREVMDA' => 'armeniu occidental',
 			'BAKU1926' => 'alfabetu turcu llatino unificáu',
 			'BALANKA' => 'dialectu balanka del anii',
 			'BARLA' => 'grupu dialectal barlavento del cabuverdianu',
 			'BASICENG' => 'BASICENG',
 			'BAUDDHA' => 'BAUDDHA',
 			'BISCAYAN' => 'BISCAYAN',
 			'BISKE' => 'dialectu San Giorgio/Bila',
 			'BOHORIC' => 'alfabetu bohorič',
 			'BOONT' => 'boontling',
 			'COLB1945' => 'convención ortográfica brasilanu-portuguesa de 1945',
 			'CORNU' => 'CORNU',
 			'DAJNKO' => 'alfabetu dajnko',
 			'EKAVSK' => 'serbiu con pronunciación ekaviana',
 			'EMODENG' => 'inglés modernu primitivu',
 			'FONIPA' => 'fonética IPA',
 			'FONUPA' => 'fonética UPA',
 			'FONXSAMP' => 'FONXSAMP',
 			'HEPBURN' => 'romanización de Hepburn',
 			'HOGNORSK' => 'HOGNORSK',
 			'IJEKAVSK' => 'serbiu con pronunciación Ijekaviana',
 			'ITIHASA' => 'ITIHASA',
 			'JAUER' => 'JAUER',
 			'JYUTPING' => 'JYUTPING',
 			'KKCOR' => 'ortografía común',
 			'KOCIEWIE' => 'KOCIEWIE',
 			'KSCOR' => 'ortografía estándar',
 			'LAUKIKA' => 'LAUKIKA',
 			'LIPAW' => 'el dialectu lipovaz del resianu',
 			'LUNA1918' => 'LUNA1918',
 			'METELKO' => 'alfabetu metelko',
 			'MONOTON' => 'monotónicu',
 			'NDYUKA' => 'dialectu ndyuka',
 			'NEDIS' => 'dialectu natisone',
 			'NEWFOUND' => 'NEWFOUND',
 			'NJIVA' => 'dialectu gniva/njiva',
 			'NULIK' => 'volapük modernu',
 			'OSOJS' => 'dialectu oseacco/osojane',
 			'OXENDICT' => 'ortografía del diccionariu d’inglés d’Oxford',
 			'PAMAKA' => 'dialectu pamaka',
 			'PETR1708' => 'PETR1708',
 			'PINYIN' => 'romanización pinyin',
 			'POLYTON' => 'politónicu',
 			'POSIX' => 'ordenador',
 			'PUTER' => 'PUTER',
 			'REVISED' => 'ortografía revisada',
 			'RIGIK' => 'volapük clásicu',
 			'ROZAJ' => 'resianu',
 			'RUMGR' => 'RUMGR',
 			'SAAHO' => 'saho',
 			'SCOTLAND' => 'inglés estándar escocés',
 			'SCOUSE' => 'scouse',
 			'SIMPLE' => 'SIMPLE',
 			'SOLBA' => 'dialectu stolvizza/solbica',
 			'SOTAV' => 'grupu dialectal sotavento del cabuverdianu',
 			'SURMIRAN' => 'SURMIRAN',
 			'SURSILV' => 'SURSILV',
 			'SUTSILV' => 'SUTSILV',
 			'TARASK' => 'ortografía taraskievica',
 			'UCCOR' => 'ortografía unificada',
 			'UCRCOR' => 'ortografía unificada revisada',
 			'ULSTER' => 'ULSTER',
 			'UNIFON' => 'alfabetu fonéticu Unifon',
 			'VAIDIKA' => 'VAIDIKA',
 			'VALENCIA' => 'valencianu',
 			'VALLADER' => 'VALLADER',
 			'WADEGILE' => 'romanización de Wade-Giles',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'calendariu',
 			'cf' => 'formatu monetariu',
 			'collation' => 'orde de clasificación',
 			'currency' => 'moneda',
 			'hc' => 'ciclu horariu (12 o 24)',
 			'lb' => 'estilu de saltu de llinia',
 			'ms' => 'sistema de midida',
 			'numbers' => 'númberos',

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
 				'buddhist' => q{calendariu budista},
 				'chinese' => q{calendariu chinu},
 				'coptic' => q{calendariu coptu},
 				'dangi' => q{calendariu dangi},
 				'ethiopic' => q{calendariu etíope},
 				'ethiopic-amete-alem' => q{calendariu etíope Amete Alem},
 				'gregorian' => q{calendariu gregorianu},
 				'hebrew' => q{calendariu hebréu},
 				'indian' => q{calendariu nacional indiu},
 				'islamic' => q{calendariu islámicu},
 				'islamic-civil' => q{calendariu islámicu (tabular, época civil)},
 				'islamic-rgsa' => q{calendariu islámicu (Arabia Saudita, visual)},
 				'islamic-tbla' => q{calendariu islámicu (tabular, época astronómica)},
 				'islamic-umalqura' => q{calendariu islámicu (Umm al-Qura)},
 				'iso8601' => q{calendariu ISO-8601},
 				'japanese' => q{calendariu xaponés},
 				'persian' => q{calendariu persa},
 				'roc' => q{calendariu de la República de China},
 			},
 			'cf' => {
 				'account' => q{formatu monetariu contable},
 				'standard' => q{formatu monetariu estándar},
 			},
 			'collation' => {
 				'big5han' => q{orde de clasificación chinu tradicional - Big5},
 				'compat' => q{orde de clasificación anterior, por compatibilidá},
 				'dictionary' => q{orde de clasificación de diccionariu},
 				'ducet' => q{orde de clasificación Unicode predetermináu},
 				'emoji' => q{orde de clasificación Emoji},
 				'eor' => q{regles d’ordenamientu europees},
 				'gb2312han' => q{orde de clasificación chinu simplificáu - GB2312},
 				'phonebook' => q{orde de clasificación de llista telefónica},
 				'pinyin' => q{orde de clasificación pinyin},
 				'reformed' => q{orde de clasificación reformáu},
 				'search' => q{gueta xeneral},
 				'searchjl' => q{gueta por consonante Hangul d’aniciu},
 				'standard' => q{orde de clasificación estándar},
 				'stroke' => q{orde de clasificación pol trazu},
 				'traditional' => q{orde de clasificación tradicional},
 				'unihan' => q{orde de clasificación por radical y trazu},
 				'zhuyin' => q{orde de clasificación zhuyin},
 			},
 			'hc' => {
 				'h11' => q{sistema de 12 hores (0–11)},
 				'h12' => q{sistema de 12 hores (1–12)},
 				'h23' => q{sistema de 24 hores (0–23)},
 				'h24' => q{sistema de 24 hores (1–24)},
 			},
 			'lb' => {
 				'loose' => q{saltu de llinia relaxáu},
 				'normal' => q{saltu de llinia normal},
 				'strict' => q{saltu de llinia estrictu},
 			},
 			'ms' => {
 				'metric' => q{sistema métricu},
 				'uksystem' => q{sistema de midida imperial},
 				'ussystem' => q{sistema de midida d’EE.XX.},
 			},
 			'numbers' => {
 				'ahom' => q{númberos ahom},
 				'arab' => q{númberos arábico-índicos},
 				'arabext' => q{númberos arábico-índicos estendíos},
 				'armn' => q{númberos armenios},
 				'armnlow' => q{númberos armenios en minúscules},
 				'bali' => q{númberos balineses},
 				'beng' => q{númberos bengalinos},
 				'brah' => q{númberos brahmi},
 				'cakm' => q{númberos chakma},
 				'cham' => q{númberos cham},
 				'cyrl' => q{númberos cirílicos},
 				'deva' => q{númberos devanagari},
 				'ethi' => q{númberos etíopes},
 				'fullwide' => q{númberos n’anchu completu},
 				'geor' => q{númberos xeorxanos},
 				'grek' => q{númberos griegos},
 				'greklow' => q{númberos griegos en minúscules},
 				'gujr' => q{númberos gujarati},
 				'guru' => q{númberos gurmukhi},
 				'hanidec' => q{númberos decimales chinos},
 				'hans' => q{númberos chinos simplificaos},
 				'hansfin' => q{númberos chinos financieros simplificaos},
 				'hant' => q{númberos chinos tradicionales},
 				'hantfin' => q{númberos chinos financieros tradicionales},
 				'hebr' => q{númberos hebreos},
 				'hmng' => q{númberos Pahawh Hmong},
 				'java' => q{númberos xavanesos},
 				'jpan' => q{númberos xaponeses},
 				'jpanfin' => q{númberos financieros xaponeses},
 				'kali' => q{númberos Kayah Li},
 				'khmr' => q{numberación khmer},
 				'knda' => q{numberación kannada},
 				'lana' => q{numberación Tai Tham Hora},
 				'lanatham' => q{numberación Tai Tham Tham},
 				'laoo' => q{númberos laosianos},
 				'latn' => q{númberos occidentales},
 				'lepc' => q{númberos lepcha},
 				'limb' => q{númberos limbu},
 				'mathbold' => q{númberos matemáticos en negrina},
 				'mathdbl' => q{númberos matemáticos con trazu doble},
 				'mathmono' => q{númberos matemáticos monoespaciaos},
 				'mathsanb' => q{númberos matemáticos Sans-Serif en negrina},
 				'mathsans' => q{númberos matemáticos Sans-Serif},
 				'mlym' => q{númberos malayalam},
 				'modi' => q{númberos modi},
 				'mong' => q{númberos mongoles},
 				'mroo' => q{númberos mro},
 				'mtei' => q{númberos Meetei Mayek},
 				'mymr' => q{númberos de Myanmar},
 				'mymrshan' => q{númberos Shan de Myanmar},
 				'mymrtlng' => q{númberos Tai Laing de Myanmar},
 				'nkoo' => q{númberos N’Ko},
 				'olck' => q{númberos Ol Chiki},
 				'orya' => q{númberos odia},
 				'osma' => q{númberos osmanya},
 				'roman' => q{númberos romanos},
 				'romanlow' => q{númberos romanos en minúscules},
 				'saur' => q{númberos saurashtra},
 				'shrd' => q{númberos sharada},
 				'sind' => q{númberos Khudawadi},
 				'sinh' => q{númberos Lith cingaleses},
 				'sora' => q{númberos Sora Sompeng},
 				'sund' => q{númberos sondaneses},
 				'takr' => q{númberos takri},
 				'talu' => q{numberación Tai Lue nueva},
 				'taml' => q{númberos tamil tradicionales},
 				'tamldec' => q{númberos tamil},
 				'telu' => q{númberos telugu},
 				'thai' => q{númberos tailandeses},
 				'tibt' => q{númberos tibetanos},
 				'tirh' => q{númberos tirhuta},
 				'vaii' => q{númberos vai},
 				'wara' => q{númberos Warang Citi},
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
			'metric' => q{Métricu},
 			'UK' => q{R.X.},
 			'US' => q{EE.XX.},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Llingua: {0}',
 			'script' => 'Alfabetu: {0}',
 			'region' => 'Rexón: {0}',

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
			auxiliary => qr{[ª à ă â å ä ã ā æ ç è ĕ ê ë ē ì ĭ î ï ī j k º ò ŏ ô ö ø ō œ ù ŭ û ū w ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'L', 'M', 'N', 'Ñ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'X', 'Y', 'Z'],
			main => qr{[a á b c d e é f g h ḥ i í l ḷ m n ñ o ó p q r s t u ú ü v x y z]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ¡ ? ¿ . … ' ‘ ’ " “ ” « » ( ) \[ \] § @ * / \\ \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'L', 'M', 'N', 'Ñ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'X', 'Y', 'Z'], };
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
			'medial' => '{0}… {1}',
			'word-final' => '{0} …',
			'word-initial' => '… {0}',
			'word-medial' => '{0}… {1}',
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
					'acre' => {
						'name' => q(acres),
						'one' => q({0} acre),
						'other' => q({0} acres),
					},
					'acre-foot' => {
						'name' => q(acre-pies),
						'one' => q({0} acre-pie),
						'other' => q({0} acre-pies),
					},
					'ampere' => {
						'name' => q(amperios),
						'one' => q({0} amperiu),
						'other' => q({0} amperios),
					},
					'arc-minute' => {
						'name' => q(minutos d’arcu),
						'one' => q({0} minutu d'arcu),
						'other' => q({0} minutos d'arcu),
					},
					'arc-second' => {
						'name' => q(segundos d’arcu),
						'one' => q({0} segundu d'arcu),
						'other' => q({0} segundos d'arcu),
					},
					'astronomical-unit' => {
						'name' => q(unidaes astronómiques),
						'one' => q({0} unidá astronómica),
						'other' => q({0} unidaes astronómiques),
					},
					'bit' => {
						'name' => q(bits),
						'one' => q({0} bit),
						'other' => q({0} bits),
					},
					'bushel' => {
						'name' => q(bushels),
						'one' => q({0} bushel),
						'other' => q({0} bushels),
					},
					'byte' => {
						'name' => q(bytes),
						'one' => q({0} byte),
						'other' => q({0} bytes),
					},
					'calorie' => {
						'name' => q(caloríes),
						'one' => q({0} caloría),
						'other' => q({0} caloríes),
					},
					'carat' => {
						'name' => q(quilates),
						'one' => q({0} quilate),
						'other' => q({0} quilates),
					},
					'celsius' => {
						'name' => q(graos Celsius),
						'one' => q({0} grau Celsius),
						'other' => q({0} graos Celsius),
					},
					'centiliter' => {
						'name' => q(centillitros),
						'one' => q({0} centillitru),
						'other' => q({0} centillitros),
					},
					'centimeter' => {
						'name' => q(centímetros),
						'one' => q({0} centímetru),
						'other' => q({0} centímetros),
						'per' => q({0} por centímetru),
					},
					'century' => {
						'name' => q(sieglos),
						'one' => q({0} sieglu),
						'other' => q({0} sieglos),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}O),
					},
					'cubic-centimeter' => {
						'name' => q(centímetros cúbicos),
						'one' => q({0} centímetru cúbicu),
						'other' => q({0} centímetros cúbicos),
						'per' => q({0} per centímetru cúbicu),
					},
					'cubic-foot' => {
						'name' => q(pies cúbicos),
						'one' => q({0} pie cúbicu),
						'other' => q({0} pies cúbicos),
					},
					'cubic-inch' => {
						'name' => q(pulgaes cúbiques),
						'one' => q({0} pulgada cúbica),
						'other' => q({0} pulgaes cúbiques),
					},
					'cubic-kilometer' => {
						'name' => q(quilómetros cúbicos),
						'one' => q({0} quilómetru cúbicu),
						'other' => q({0} quilómetros cúbicos),
					},
					'cubic-meter' => {
						'name' => q(metros cúbicos),
						'one' => q({0} metru cúbicu),
						'other' => q({0} metros cúbicos),
						'per' => q({0} per metru cúbicu),
					},
					'cubic-mile' => {
						'name' => q(milles cúbiques),
						'one' => q({0} milla cúbica),
						'other' => q({0} milles cúbiques),
					},
					'cubic-yard' => {
						'name' => q(yardes cúbiques),
						'one' => q({0} yarda cúbica),
						'other' => q({0} yardes cúbiques),
					},
					'cup' => {
						'name' => q(taces),
						'one' => q({0} taza),
						'other' => q({0} taces),
					},
					'cup-metric' => {
						'name' => q(taces métriques),
						'one' => q({0} taza métrica),
						'other' => q({0} taces métriques),
					},
					'day' => {
						'name' => q(díes),
						'one' => q({0} día),
						'other' => q({0} díes),
						'per' => q({0} per día),
					},
					'deciliter' => {
						'name' => q(decillitros),
						'one' => q({0} decillitru),
						'other' => q({0} decillitros),
					},
					'decimeter' => {
						'name' => q(decímetros),
						'one' => q({0} decímetru),
						'other' => q({0} decímetros),
					},
					'degree' => {
						'name' => q(graos),
						'one' => q({0} grau),
						'other' => q({0} graos),
					},
					'fahrenheit' => {
						'name' => q(graos Fahrenheit),
						'one' => q({0} grau Fahrenheit),
						'other' => q({0} graos Fahrenheit),
					},
					'fathom' => {
						'name' => q(fathoms),
						'one' => q({0} fathom),
						'other' => q({0} fathoms),
					},
					'fluid-ounce' => {
						'name' => q(onces de fluidos),
						'one' => q({0} onza de fluidos),
						'other' => q({0} onces de fluidos),
					},
					'foodcalorie' => {
						'name' => q(Caloríes),
						'one' => q({0} Caloría),
						'other' => q({0} Caloríes),
					},
					'foot' => {
						'name' => q(pies),
						'one' => q({0} pie),
						'other' => q({0} pies),
						'per' => q({0} per pie),
					},
					'furlong' => {
						'name' => q(furlongs),
						'one' => q({0} furlong),
						'other' => q({0} furlongs),
					},
					'g-force' => {
						'name' => q(fuercia g),
						'one' => q({0} fuercia g),
						'other' => q({0} fuercies gues),
					},
					'gallon' => {
						'name' => q(galones),
						'one' => q({0} galón),
						'other' => q({0} galones),
						'per' => q({0} per galón),
					},
					'gallon-imperial' => {
						'name' => q(galones imperiales),
						'one' => q({0} galón imperial),
						'other' => q({0} galones imperiales),
						'per' => q({0} per galón imperial),
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
						'name' => q(gigahercios),
						'one' => q({0} gigaherciu),
						'other' => q({0} gigahercios),
					},
					'gigawatt' => {
						'name' => q(gigavatios),
						'one' => q({0} gigavatiu),
						'other' => q({0} gigavatios),
					},
					'gram' => {
						'name' => q(gramos),
						'one' => q({0} gramu),
						'other' => q({0} gramos),
						'per' => q({0} per gramu),
					},
					'hectare' => {
						'name' => q(hectárees),
						'one' => q({0} hectárea),
						'other' => q({0} hectárees),
					},
					'hectoliter' => {
						'name' => q(hectollitros),
						'one' => q({0} hectollitru),
						'other' => q({0} hectollitros),
					},
					'hectopascal' => {
						'name' => q(hectopascales),
						'one' => q({0} hectopascal),
						'other' => q({0} hectopascales),
					},
					'hertz' => {
						'name' => q(hercios),
						'one' => q({0} herciu),
						'other' => q({0} hercios),
					},
					'horsepower' => {
						'name' => q(caballos),
						'one' => q({0} caballu de fuerza),
						'other' => q({0} caballos de fuerza),
					},
					'hour' => {
						'name' => q(hores),
						'one' => q({0} hora),
						'other' => q({0} hores),
						'per' => q({0} per hora),
					},
					'inch' => {
						'name' => q(pulgaes),
						'one' => q({0} pulgada),
						'other' => q({0} pulgaes),
						'per' => q({0} per pulgada),
					},
					'inch-hg' => {
						'name' => q(pulgaes de mercuriu),
						'one' => q({0} pulgada de mercuriu),
						'other' => q({0} pulgaes de mercuriu),
					},
					'joule' => {
						'name' => q(xulios),
						'one' => q({0} xuliu),
						'other' => q({0} xulios),
					},
					'karat' => {
						'name' => q(quilates),
						'one' => q({0} quilate),
						'other' => q({0} quilates),
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
						'name' => q(quilocaloríes),
						'one' => q({0} quilocaloría),
						'other' => q({0} quilocaloríes),
					},
					'kilogram' => {
						'name' => q(quilogramos),
						'one' => q({0} quilogramu),
						'other' => q({0} quilogramos),
						'per' => q({0} per quilogramu),
					},
					'kilohertz' => {
						'name' => q(quilohercios),
						'one' => q({0} quiloherciu),
						'other' => q({0} kilohercios),
					},
					'kilojoule' => {
						'name' => q(quiloxulios),
						'one' => q({0} quiloxuliu),
						'other' => q({0} quiloxulios),
					},
					'kilometer' => {
						'name' => q(quilómetros),
						'one' => q({0} quilómetru),
						'other' => q({0} quilómetros),
						'per' => q({0} per quilómetru),
					},
					'kilometer-per-hour' => {
						'name' => q(quilómetros per hora),
						'one' => q({0} quilómetru per hora),
						'other' => q({0} quilómetros per hora),
					},
					'kilowatt' => {
						'name' => q(quilovatios),
						'one' => q({0} quilovatiu),
						'other' => q({0} quilovatios),
					},
					'kilowatt-hour' => {
						'name' => q(quilovatios hora),
						'one' => q({0} quilovatiu hora),
						'other' => q({0} quilovatios hora),
					},
					'knot' => {
						'name' => q(nuedu),
						'one' => q({0} nuedu),
						'other' => q({0} nuedos),
					},
					'light-year' => {
						'name' => q(años lluz),
						'one' => q({0} añu lluz),
						'other' => q({0} años lluz),
					},
					'liter' => {
						'name' => q(llitros),
						'one' => q({0} llitru),
						'other' => q({0} llitros),
						'per' => q({0} per llitru),
					},
					'liter-per-100kilometers' => {
						'name' => q(llitros per 100 quilómetros),
						'one' => q({0} llitru per 100 quilómetros),
						'other' => q({0} llitros per 100 quilómetros),
					},
					'liter-per-kilometer' => {
						'name' => q(llitros per quilómetru),
						'one' => q({0} llitru per quilómetru),
						'other' => q({0} llitros per quilómetru),
					},
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
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
						'name' => q(megahercios),
						'one' => q({0} megaherciu),
						'other' => q({0} megahercios),
					},
					'megaliter' => {
						'name' => q(megallitros),
						'one' => q({0} megallitru),
						'other' => q({0} megallitros),
					},
					'megawatt' => {
						'name' => q(megavatios),
						'one' => q({0} megavatiu),
						'other' => q({0} megavatios),
					},
					'meter' => {
						'name' => q(metros),
						'one' => q({0} metru),
						'other' => q({0} metros),
						'per' => q({0} per metru),
					},
					'meter-per-second' => {
						'name' => q(metros per segundu),
						'one' => q({0} metru per segundu),
						'other' => q({0} metros per segundu),
					},
					'meter-per-second-squared' => {
						'name' => q(metros per segundu al cuadráu),
						'one' => q({0} metru per segundu al cuadráu),
						'other' => q({0} metros por segundu al cuadráu),
					},
					'metric-ton' => {
						'name' => q(tonelaes métriques),
						'one' => q({0} tonelada métrica),
						'other' => q({0} tonelaes métriques),
					},
					'microgram' => {
						'name' => q(microgramos),
						'one' => q({0} microgramu),
						'other' => q({0} microgramos),
					},
					'micrometer' => {
						'name' => q(micrómetros),
						'one' => q({0} micrómetru),
						'other' => q({0} micrómetros),
					},
					'microsecond' => {
						'name' => q(microsegundos),
						'one' => q({0} microsegundu),
						'other' => q({0} microsegundos),
					},
					'mile' => {
						'name' => q(milles),
						'one' => q({0} milla),
						'other' => q({0} milles),
					},
					'mile-per-gallon' => {
						'name' => q(milles per galón),
						'one' => q({0} milla per galón),
						'other' => q({0} milles per galón),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(milles per galón imperial),
						'one' => q({0} milla per galón imperial),
						'other' => q({0} milles per galón imperial),
					},
					'mile-per-hour' => {
						'name' => q(milles per hora),
						'one' => q({0} milla per hora),
						'other' => q({0} milles per hora),
					},
					'mile-scandinavian' => {
						'name' => q(milla escandinava),
						'one' => q({0} milla escandinava),
						'other' => q({0} milles escandinaves),
					},
					'milliampere' => {
						'name' => q(miliamperios),
						'one' => q({0} milliamperiu),
						'other' => q({0} milliamperios),
					},
					'millibar' => {
						'name' => q(milibares),
						'one' => q({0} milibar),
						'other' => q({0} milibares),
					},
					'milligram' => {
						'name' => q(miligramos),
						'one' => q({0} miligramu),
						'other' => q({0} miligramos),
					},
					'milligram-per-deciliter' => {
						'name' => q(miligramos per decillitru),
						'one' => q({0} miligramu per decillitru),
						'other' => q({0} miligramos per decillitru),
					},
					'milliliter' => {
						'name' => q(milillitros),
						'one' => q({0} milillitru),
						'other' => q({0} milillitros),
					},
					'millimeter' => {
						'name' => q(milímetros),
						'one' => q({0} milímetru),
						'other' => q({0} milímetros),
					},
					'millimeter-of-mercury' => {
						'name' => q(milímetros de mercuriu),
						'one' => q({0} milímetru de mercuriu),
						'other' => q({0} milímetros de mercuriu),
					},
					'millimole-per-liter' => {
						'name' => q(milimoles per llitru),
						'one' => q({0} milimol per llitru),
						'other' => q({0} milimoles per llitru),
					},
					'millisecond' => {
						'name' => q(milisegundos),
						'one' => q({0} milisegundu),
						'other' => q({0} milisegundos),
					},
					'milliwatt' => {
						'name' => q(millivatios),
						'one' => q({0} millivatiu),
						'other' => q({0} millivatios),
					},
					'minute' => {
						'name' => q(minutos),
						'one' => q({0} minutu),
						'other' => q({0} minutos),
						'per' => q({0} per minutu),
					},
					'month' => {
						'name' => q(meses),
						'one' => q({0} mes),
						'other' => q({0} meses),
						'per' => q({0} per mes),
					},
					'nanometer' => {
						'name' => q(nanómetros),
						'one' => q({0} nanómetru),
						'other' => q({0} nanómetros),
					},
					'nanosecond' => {
						'name' => q(nanosegundos),
						'one' => q({0} nanosegundu),
						'other' => q({0} nanosegundos),
					},
					'nautical-mile' => {
						'name' => q(milles náutiques),
						'one' => q({0} milla náutica),
						'other' => q({0} milles náutiques),
					},
					'ohm' => {
						'name' => q(ohmnios),
						'one' => q({0} ohmiu),
						'other' => q({0} ohmios),
					},
					'ounce' => {
						'name' => q(onces),
						'one' => q({0} onza),
						'other' => q({0} onces),
						'per' => q({0} per onza),
					},
					'ounce-troy' => {
						'name' => q(onces troy),
						'one' => q({0} onza troy),
						'other' => q({0} onces troy),
					},
					'parsec' => {
						'name' => q(parsecs),
						'one' => q({0} parsec),
						'other' => q({0} parsecs),
					},
					'part-per-million' => {
						'name' => q(partes per millón),
						'one' => q({0} parte per millón),
						'other' => q({0} partes per millón),
					},
					'per' => {
						'1' => q({0} per {1}),
					},
					'picometer' => {
						'name' => q(picómetros),
						'one' => q({0} picómetru),
						'other' => q({0} picómetros),
					},
					'pint' => {
						'name' => q(pintes),
						'one' => q({0} pinta),
						'other' => q({0} pintes),
					},
					'pint-metric' => {
						'name' => q(pintes métriques),
						'one' => q({0} pinta métrica),
						'other' => q({0} pintes métriques),
					},
					'point' => {
						'name' => q(Puntos),
						'one' => q({0} puntu),
						'other' => q({0} puntos),
					},
					'pound' => {
						'name' => q(llibres),
						'one' => q({0} llibra),
						'other' => q({0} llibres),
						'per' => q({0} per llibra),
					},
					'pound-per-square-inch' => {
						'name' => q(llibres per pulgada cuadrada),
						'one' => q({0} llibra per pulgada cuadrada),
						'other' => q({0} llibres per pulgada cuadrada),
					},
					'quart' => {
						'name' => q(cuartos),
						'one' => q({0} cuartu),
						'other' => q({0} cuartos),
					},
					'radian' => {
						'name' => q(radianes),
						'one' => q({0} radián),
						'other' => q({0} radianes),
					},
					'revolution' => {
						'name' => q(revolución),
						'one' => q({0} revolución),
						'other' => q({0} revoluciones),
					},
					'second' => {
						'name' => q(segundos),
						'one' => q({0} segundu),
						'other' => q({0} segundos),
						'per' => q({0} per segundu),
					},
					'square-centimeter' => {
						'name' => q(centímetros cuadraos),
						'one' => q({0} centímetru cuadráu),
						'other' => q({0} centímetros cuadraos),
						'per' => q({0} per centímetru cuadráu),
					},
					'square-foot' => {
						'name' => q(pies cuadraos),
						'one' => q({0} pie cuadráu),
						'other' => q({0} pies cuadraos),
					},
					'square-inch' => {
						'name' => q(pulgaes cuadraes),
						'one' => q({0} pulgada cuadrada),
						'other' => q({0} pulgaes cuadraes),
						'per' => q({0} per pulgada cuadrada),
					},
					'square-kilometer' => {
						'name' => q(kilómetros cuadraos),
						'one' => q({0} kilómetru cuadráu),
						'other' => q({0} kilómetros cuadraos),
						'per' => q({0} per quilómetru cuadráu),
					},
					'square-meter' => {
						'name' => q(metros cuadraos),
						'one' => q({0} metru cuadráu),
						'other' => q({0} metros cuadraos),
						'per' => q({0} per metru cuadráu),
					},
					'square-mile' => {
						'name' => q(milles cuadraes),
						'one' => q({0} milla cuadrada),
						'other' => q({0} milles cuadraes),
						'per' => q({0} per milla cuadrada),
					},
					'square-yard' => {
						'name' => q(yardes cuadraes),
						'one' => q({0} yarda cuadrada),
						'other' => q({0} yardes cuadraes),
					},
					'stone' => {
						'name' => q(piedres),
						'one' => q({0} piedra),
						'other' => q({0} piedres),
					},
					'tablespoon' => {
						'name' => q(cuyares),
						'one' => q({0} cuyar),
						'other' => q({0} cuyares),
					},
					'teaspoon' => {
						'name' => q(cuyarines),
						'one' => q({0} cuyarina),
						'other' => q({0} cuyarines),
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
						'name' => q(tonelaes),
						'one' => q({0} tonelada),
						'other' => q({0} tonelaes),
					},
					'volt' => {
						'name' => q(voltios),
						'one' => q({0} voltiu),
						'other' => q({0} voltios),
					},
					'watt' => {
						'name' => q(vatios),
						'one' => q({0} vatiu),
						'other' => q({0} vatios),
					},
					'week' => {
						'name' => q(selmanes),
						'one' => q({0} selmana),
						'other' => q({0} selmanes),
						'per' => q({0} per selmana),
					},
					'yard' => {
						'name' => q(yardes),
						'one' => q({0} yarda),
						'other' => q({0} yardes),
					},
					'year' => {
						'name' => q(años),
						'one' => q({0} añu),
						'other' => q({0} años),
						'per' => q({0} per añu),
					},
				},
				'narrow' => {
					'acre' => {
						'name' => q(acre),
						'one' => q({0}ac),
						'other' => q({0}ac),
					},
					'acre-foot' => {
						'name' => q(acre ft),
						'one' => q({0}ac ft),
						'other' => q({0}ac ft),
					},
					'ampere' => {
						'name' => q(amp),
						'one' => q({0}A),
						'other' => q({0}A),
					},
					'arc-minute' => {
						'name' => q(arcmin),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(arcsecs),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(ua),
						'one' => q({0}ua),
						'other' => q({0}ua),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0}bit),
						'other' => q({0}bits),
					},
					'bushel' => {
						'name' => q(bushel),
						'one' => q({0}bu),
						'other' => q({0}bu),
					},
					'byte' => {
						'name' => q(byte),
						'one' => q({0}byte),
						'other' => q({0}byte),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0}cal),
						'other' => q({0}cal),
					},
					'carat' => {
						'name' => q(quilates),
						'one' => q({0}CD),
						'other' => q({0}CD),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0}cL),
						'other' => q({0}cL),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'name' => q(sgl),
						'one' => q({0} sgl),
						'other' => q({0} sgls),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}O),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0}cm³),
						'other' => q({0}cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0}ft³),
						'other' => q({0}ft³),
					},
					'cubic-inch' => {
						'name' => q(in³),
						'one' => q({0}in³),
						'other' => q({0}in³),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0}m³),
						'other' => q({0}m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0}mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0}yd³),
						'other' => q({0}yd³),
					},
					'cup' => {
						'name' => q(taces),
						'one' => q({0}tz),
						'other' => q({0}tz),
					},
					'cup-metric' => {
						'name' => q(taces mét.),
						'one' => q({0}mc),
						'other' => q({0}mc),
					},
					'day' => {
						'name' => q(día),
						'one' => q({0}día),
						'other' => q({0}díes),
						'per' => q({0}/día),
					},
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0}dL),
						'other' => q({0}dL),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0}dm),
						'other' => q({0}dm),
					},
					'degree' => {
						'name' => q(graos),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(fathom),
						'one' => q({0}fth),
						'other' => q({0}fth),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
					},
					'foodcalorie' => {
						'name' => q(Cal),
						'one' => q({0}Cal),
						'other' => q({0}Cal),
					},
					'foot' => {
						'name' => q(ft),
						'one' => q({0}′),
						'other' => q({0}′),
						'per' => q({0}/ft),
					},
					'furlong' => {
						'name' => q(furlongs),
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					'g-force' => {
						'name' => q(fuercia g),
						'one' => q({0}G),
						'other' => q({0}Gs),
					},
					'gallon' => {
						'name' => q(gal),
						'one' => q({0}gal),
						'other' => q({0}gal),
						'per' => q({0}/gal),
					},
					'gallon-imperial' => {
						'name' => q(gal. imp.),
						'one' => q({0} gal imp),
						'other' => q({0} gal imp),
						'per' => q({0}/gal imp),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gbit),
						'one' => q({0}Gb),
						'other' => q({0}Gb),
					},
					'gigabyte' => {
						'name' => q(GByte),
						'one' => q({0}GB),
						'other' => q({0}GB),
					},
					'gigahertz' => {
						'name' => q(GHz),
						'one' => q({0}GHz),
						'other' => q({0}GHz),
					},
					'gigawatt' => {
						'name' => q(GW),
						'one' => q({0}GW),
						'other' => q({0}GW),
					},
					'gram' => {
						'name' => q(gramos),
						'one' => q({0}g),
						'other' => q({0}g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(hectárea),
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0}hL),
						'other' => q({0}hL),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0}Hz),
						'other' => q({0}Hz),
					},
					'horsepower' => {
						'name' => q(hp),
						'one' => q({0}hp),
						'other' => q({0}hp),
					},
					'hour' => {
						'name' => q(hora),
						'one' => q({0}hr),
						'other' => q({0}hrs),
						'per' => q({0}/hr),
					},
					'inch' => {
						'name' => q(in),
						'one' => q({0}″),
						'other' => q({0}″),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(″ Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					'joule' => {
						'name' => q(xulios),
						'one' => q({0}J),
						'other' => q({0}J),
					},
					'karat' => {
						'name' => q(quilate),
						'one' => q({0}kt),
						'other' => q({0}kt),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0}K),
						'other' => q({0}K),
					},
					'kilobit' => {
						'name' => q(kbit),
						'one' => q({0}kb),
						'other' => q({0}kb),
					},
					'kilobyte' => {
						'name' => q(kByte),
						'one' => q({0}kB),
						'other' => q({0}kB),
					},
					'kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0}kcal),
						'other' => q({0}kcal),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0}kg),
						'other' => q({0}kg),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'name' => q(kHz),
						'one' => q({0}kHz),
						'other' => q({0}kHz),
					},
					'kilojoule' => {
						'name' => q(kJ),
						'one' => q({0}kJ),
						'other' => q({0}kJ),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0}km),
						'other' => q({0}km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0}kWh),
						'other' => q({0}kWh),
					},
					'knot' => {
						'name' => q(kn),
						'one' => q({0}kn),
						'other' => q({0}kn),
					},
					'light-year' => {
						'name' => q(añ. lluz),
						'one' => q({0}ly),
						'other' => q({0}ly),
					},
					'liter' => {
						'name' => q(llitru),
						'one' => q({0}l),
						'other' => q({0}l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
					},
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q({0}L/km),
						'other' => q({0}L/km),
					},
					'lux' => {
						'name' => q(lux),
						'one' => q({0}lx),
						'other' => q({0}lx),
					},
					'megabit' => {
						'name' => q(Mbit),
						'one' => q({0}Mb),
						'other' => q({0}Mb),
					},
					'megabyte' => {
						'name' => q(MByte),
						'one' => q({0}MB),
						'other' => q({0}MB),
					},
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0}MHz),
						'other' => q({0}MHz),
					},
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0}ML),
						'other' => q({0}ML),
					},
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0}MW),
						'other' => q({0}MW),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0}t),
						'other' => q({0}t),
					},
					'microgram' => {
						'name' => q(µg),
						'one' => q({0}µg),
						'other' => q({0}µg),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0}µm),
						'other' => q({0}µm),
					},
					'microsecond' => {
						'name' => q(μseg),
						'one' => q({0}μs),
						'other' => q({0}μs),
					},
					'mile' => {
						'name' => q(mi),
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					'mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0}mpg),
						'other' => q({0}mpg),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(mpg imp),
						'one' => q({0}mpg im),
						'other' => q({0}mpg im),
					},
					'mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0}mph),
						'other' => q({0}mph),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0}smi),
						'other' => q({0}smi),
					},
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0}mA),
						'other' => q({0}mA),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0}mb),
						'other' => q({0}mb),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0}mg),
						'other' => q({0}mg),
					},
					'milligram-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
					},
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0}mL),
						'other' => q({0}mL),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'one' => q({0}mm Hg),
						'other' => q({0}mm Hg),
					},
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0}mmol/L),
						'other' => q({0}mmol/L),
					},
					'millisecond' => {
						'name' => q(mseg),
						'one' => q({0}ms),
						'other' => q({0}ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0}mW),
						'other' => q({0}mW),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0}min),
						'other' => q({0}mins),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(mes),
						'one' => q({0}mes),
						'other' => q({0}meses),
						'per' => q({0}/mes),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0}ns),
						'other' => q({0}ns),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0}nmi),
						'other' => q({0}nmi),
					},
					'ohm' => {
						'name' => q(ohmnios),
						'one' => q({0}Ω),
						'other' => q({0}Ω),
					},
					'ounce' => {
						'name' => q(oz),
						'one' => q({0}oz),
						'other' => q({0}oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0}oz t),
						'other' => q({0}oz t),
					},
					'parsec' => {
						'name' => q(parsec),
						'one' => q({0}pc),
						'other' => q({0}pc),
					},
					'part-per-million' => {
						'name' => q(ppm),
						'one' => q({0}ppm),
						'other' => q({0}ppm),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					'pint' => {
						'name' => q(pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0}mpt),
						'other' => q({0}mpt),
					},
					'pound' => {
						'name' => q(lb),
						'one' => q({0}#),
						'other' => q({0}#),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0}psi),
						'other' => q({0}psi),
					},
					'quart' => {
						'name' => q(qt),
						'one' => q({0}qt),
						'other' => q({0}qt),
					},
					'radian' => {
						'name' => q(rad),
						'one' => q({0}rad),
						'other' => q({0}rad),
					},
					'revolution' => {
						'name' => q(rev),
						'one' => q({0}rev),
						'other' => q({0}rev),
					},
					'second' => {
						'name' => q(seg),
						'one' => q({0}seg),
						'other' => q({0}segs),
						'per' => q({0}/seg),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0}cm²),
						'other' => q({0}cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'name' => q(ft²),
						'one' => q({0}ft²),
						'other' => q({0}ft²),
					},
					'square-inch' => {
						'name' => q(in²),
						'one' => q({0}in²),
						'other' => q({0}in²),
						'per' => q({0}/in²),
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
						'per' => q({0} per m²),
					},
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0}mi²),
						'other' => q({0}mi²),
						'per' => q({0}/mi²),
					},
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0}yd²),
						'other' => q({0}yd²),
					},
					'stone' => {
						'name' => q(piedres),
						'one' => q({0}st),
						'other' => q({0}st),
					},
					'tablespoon' => {
						'name' => q(tbsp),
						'one' => q({0}tbsp),
						'other' => q({0}tbsp),
					},
					'teaspoon' => {
						'name' => q(tsp),
						'one' => q({0}tsp),
						'other' => q({0}tsp),
					},
					'terabit' => {
						'name' => q(Tbit),
						'one' => q({0}Tb),
						'other' => q({0}Tb),
					},
					'terabyte' => {
						'name' => q(TByte),
						'one' => q({0}TB),
						'other' => q({0}TB),
					},
					'ton' => {
						'name' => q(ton),
						'one' => q({0}tn),
						'other' => q({0}tn),
					},
					'volt' => {
						'name' => q(voltios),
						'one' => q({0}V),
						'other' => q({0}V),
					},
					'watt' => {
						'name' => q(vatios),
						'one' => q({0}W),
						'other' => q({0}W),
					},
					'week' => {
						'name' => q(sel),
						'one' => q({0}sel),
						'other' => q({0}sels),
						'per' => q({0}/sel),
					},
					'yard' => {
						'name' => q(yd),
						'one' => q({0}yd),
						'other' => q({0}yd),
					},
					'year' => {
						'name' => q(añ),
						'one' => q({0}añ),
						'other' => q({0}añs),
						'per' => q({0}/añ),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(acre),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'name' => q(ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'name' => q(amps),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(arcmins),
						'one' => q({0} arcmin),
						'other' => q({0} arcmins),
					},
					'arc-second' => {
						'name' => q(arcsecs),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'bushel' => {
						'name' => q(bushels),
						'one' => q({0} bu),
						'other' => q({0} bu),
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
						'name' => q(quilates),
						'one' => q({0} CD),
						'other' => q({0} CD),
					},
					'celsius' => {
						'name' => q(°C),
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
						'name' => q(sgl),
						'one' => q({0} sgl),
						'other' => q({0} sgls),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}O),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'name' => q(pulgaes³),
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
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(taces),
						'one' => q({0} tz),
						'other' => q({0} tz),
					},
					'cup-metric' => {
						'name' => q(taces mét.),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					'day' => {
						'name' => q(díes),
						'one' => q({0} día),
						'other' => q({0} díes),
						'per' => q({0}/día),
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
						'name' => q(graos),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(fathoms),
						'one' => q({0} fth),
						'other' => q({0} fth),
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
						'name' => q(pies),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'furlong' => {
						'name' => q(furlongs),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					'g-force' => {
						'name' => q(fuercia g),
						'one' => q({0} G),
						'other' => q({0} Gs),
					},
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					'gallon-imperial' => {
						'name' => q(gal. imp.),
						'one' => q({0} gal. imp.),
						'other' => q({0} gal. imp.),
						'per' => q({0}/gal. imp.),
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
						'name' => q(gramos),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'name' => q(hectárees),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hectollitros),
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
						'name' => q(hores),
						'one' => q({0} hr),
						'other' => q({0} hrs),
						'per' => q({0}/hr),
					},
					'inch' => {
						'name' => q(pulgaes),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(in Hg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'name' => q(xulios),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'name' => q(quilates),
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
						'name' => q(quiloxuliu),
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
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(kW-hora),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'name' => q(añ. lluz),
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					'liter' => {
						'name' => q(llitros),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					'liter-per-kilometer' => {
						'name' => q(llitros/km),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					'lux' => {
						'name' => q(lux),
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
						'other' => q({0} Ml),
					},
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'name' => q(metros),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(metros/seg),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
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
						'name' => q(µmetros),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μsegs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(milles),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'name' => q(milles/gal),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-gallon-imperial' => {
						'name' => q(milles/gal imp.),
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					'mile-per-hour' => {
						'name' => q(milles/hora),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(miliamps),
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
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millimole-per-liter' => {
						'name' => q(milimol/llitru),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					'millisecond' => {
						'name' => q(milisegs),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(mins),
						'one' => q({0} min),
						'other' => q({0} mins),
						'per' => q({0}/min),
					},
					'month' => {
						'name' => q(meses),
						'one' => q({0} mes),
						'other' => q({0} meses),
						'per' => q({0}/mes),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(nanosegs),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'name' => q(ohmnios),
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
						'name' => q(pc),
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
						'name' => q(pintes),
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
						'name' => q(llibres),
						'one' => q({0} lb),
						'other' => q({0} lbs),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(cuartos),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(radianes),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(rev),
						'one' => q({0} rev),
						'other' => q({0} rev),
					},
					'second' => {
						'name' => q(segs),
						'one' => q({0} seg),
						'other' => q({0} segs),
						'per' => q({0}/seg),
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
						'name' => q(in²),
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
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'stone' => {
						'name' => q(piedres),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'name' => q(cuyar),
						'one' => q({0} cuyar),
						'other' => q({0} cuyar),
					},
					'teaspoon' => {
						'name' => q(cuyrn),
						'one' => q({0} cuyrn),
						'other' => q({0} cuyrn),
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
						'name' => q(tonelaes),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					'volt' => {
						'name' => q(voltios),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(vatios),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(selmanes),
						'one' => q({0} sel),
						'other' => q({0} sels),
						'per' => q({0}/sel),
					},
					'yard' => {
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(años),
						'one' => q({0} añ),
						'other' => q({0} añs),
						'per' => q({0}/añ),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:sí|s|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:non|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0} y {1}),
				2 => q({0} y {1}),
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
		'arab' => {
			'decimal' => q(٫),
			'group' => q(٬),
			'minusSign' => q(‏-),
			'perMille' => q(؉),
			'percentSign' => q(٪),
			'plusSign' => q(‏+),
			'timeSeparator' => q(:),
		},
		'arabext' => {
			'minusSign' => q(‎-‎),
			'plusSign' => q(‎+‎),
		},
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(E),
			'group' => q(.),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(-),
			'nan' => q(ND),
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
					'one' => '0 millar',
					'other' => '0 millares',
				},
				'10000' => {
					'one' => '00 millares',
					'other' => '00 millares',
				},
				'100000' => {
					'one' => '000 millares',
					'other' => '000 millares',
				},
				'1000000' => {
					'one' => '0 millón',
					'other' => '0 millones',
				},
				'10000000' => {
					'one' => '00 millones',
					'other' => '00 millones',
				},
				'100000000' => {
					'one' => '000 millones',
					'other' => '000 millones',
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
		'arab' => {
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
		'ADP' => {
			symbol => 'ADP',
			display_name => {
				'currency' => q(Peseta andorrana),
				'one' => q(peseta andorrana),
				'other' => q(pesetes andorranes),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(Dirḥam de los Emiratos Árabes Xuníos),
				'one' => q(dirḥam EAX),
				'other' => q(dirḥams EAX),
			},
		},
		'AFA' => {
			symbol => 'AFA',
			display_name => {
				'currency' => q(Afganí afganistanu \(1927–2002\)),
				'one' => q(afganí afganistanu \(1927–2002\)),
				'other' => q(afganís afganistanos \(1927–2002\)),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Afganí afganistanu),
				'one' => q(afganí afganistanu),
				'other' => q(afganís afganistanos),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(Lek albanés \(1946–1965\)),
				'one' => q(lek albanés \(1946–1965\)),
				'other' => q(lekë albaneses \(1946–1965\)),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(Lek albanés),
				'one' => q(lek albanés),
				'other' => q(lekë albaneses),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Dram armeniu),
				'one' => q(dram armeniu),
				'other' => q(drams armenios),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Guílder de les Antilles Neerlandeses),
				'one' => q(guílder de les Antilles Neerlandeses),
				'other' => q(guílders de les Antilles Neerlandeses),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Kwanza angolanu),
				'one' => q(kwanza angolanu),
				'other' => q(kwanzas angolanos),
			},
		},
		'AOK' => {
			symbol => 'AOK',
			display_name => {
				'currency' => q(Kwanza angolanu \(1977–1991\)),
				'one' => q(kwanza angolanu \(1977–1991\)),
				'other' => q(kwanzas angolanos \(1977–1991\)),
			},
		},
		'AON' => {
			symbol => 'AON',
			display_name => {
				'currency' => q(Kwanza nuevu angolanu \(1990–2000\)),
				'one' => q(kwanza nuevu angolanu \(1990–2000\)),
				'other' => q(kwanzas nuevos angolanos \(1990–2000\)),
			},
		},
		'AOR' => {
			symbol => 'AOR',
			display_name => {
				'currency' => q(Kwanza angolanu reaxustáu \(1995–1999\)),
				'one' => q(kwanza angolanu reaxustáu \(1995–1999\)),
				'other' => q(kwanzas angolanos reaxustaos \(1995–1999\)),
			},
		},
		'ARA' => {
			symbol => 'ARA',
			display_name => {
				'currency' => q(Austral arxentín),
				'one' => q(austral arxentín),
				'other' => q(australes arxentinos),
			},
		},
		'ARL' => {
			symbol => 'ARL',
			display_name => {
				'currency' => q(Pesu Ley arxentín \(1970–1983\)),
				'one' => q(pesu ley arxentín \(1970–1983\)),
				'other' => q(pesos ley arxentinos \(1970–1983\)),
			},
		},
		'ARM' => {
			symbol => 'ARM',
			display_name => {
				'currency' => q(Pesu arxentín \(1881–1970\)),
				'one' => q(pesu arxentín \(1881–1970\)),
				'other' => q(pesos arxentinos \(1881–1970\)),
			},
		},
		'ARP' => {
			symbol => 'ARP',
			display_name => {
				'currency' => q(Pesu arxentín \(1983–1985\)),
				'one' => q(pesu arxentín \(1983–1985\)),
				'other' => q(pesos arxentinos \(1983–1985\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(pesu arxentín),
				'one' => q(pesu arxentín),
				'other' => q(pesos arxentinos),
			},
		},
		'ATS' => {
			symbol => 'ATS',
			display_name => {
				'currency' => q(Chelín austriacu),
				'one' => q(chelín austriacu),
				'other' => q(chelinos austriacos),
			},
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(Dólar australianu),
				'one' => q(dólar australianu),
				'other' => q(dólares australianos),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Florín arubanu),
				'one' => q(florín arubanu),
				'other' => q(florines arubanos),
			},
		},
		'AZM' => {
			symbol => 'AZM',
			display_name => {
				'currency' => q(Manat azerbaixanu \(1993–2006\)),
				'one' => q(manat azerbaixanu \(1993–2006\)),
				'other' => q(manats azerbaixanos \(1993–2006\)),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Manat azerbaixanu),
				'one' => q(manat azerbaixanu),
				'other' => q(manats azerbaixanos),
			},
		},
		'BAD' => {
			symbol => 'BAD',
			display_name => {
				'currency' => q(Dinar de Bosnia-Herzegovina \(1992–1994\)),
				'one' => q(dinar de Bosnia-Herzegovina \(1992–1994\)),
				'other' => q(dinares de Bosnia-Herzegovina \(1992–1994\)),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(marcu convertible de Bosnia-Herzegovina),
				'one' => q(marcu convertible de Bosnia-Herzegovina),
				'other' => q(marcos convertibles de Bosnia-Herzegovina),
			},
		},
		'BAN' => {
			symbol => 'BAN',
			display_name => {
				'currency' => q(Dinar nuevu de Bosnia-Herzegovina \(1994–1997\)),
				'one' => q(dinar nuevu de Bosnia-Herzegovina \(1994–1997\)),
				'other' => q(dinares nuevos de Bosnia-Herzegovina \(1994–1997\)),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Dólar barbadianu),
				'one' => q(dólar barbadianu),
				'other' => q(dólares barbadianos),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Taka bangladexí),
				'one' => q(taka bangladexí),
				'other' => q(takas bangladexinos),
			},
		},
		'BEC' => {
			symbol => 'BEC',
			display_name => {
				'currency' => q(Francu belga \(convertible\)),
				'one' => q(francu belga \(convertible\)),
				'other' => q(francos belgas \(convertibles\)),
			},
		},
		'BEF' => {
			symbol => 'BEF',
			display_name => {
				'currency' => q(Francu belga),
				'one' => q(francu belga),
				'other' => q(francos belgues),
			},
		},
		'BEL' => {
			symbol => 'BEL',
			display_name => {
				'currency' => q(Francu belga \(financieru\)),
				'one' => q(francu belga \(financieru\)),
				'other' => q(francos belgues \(financieros\)),
			},
		},
		'BGL' => {
			symbol => 'BGL',
			display_name => {
				'currency' => q(Lev fuerte búlgaru),
				'one' => q(lev fuerte búlgaru),
				'other' => q(leva fuertes búlgaros),
			},
		},
		'BGM' => {
			symbol => 'BGM',
			display_name => {
				'currency' => q(Lev socialista búlgaru),
				'one' => q(lev socialista búlgaru),
				'other' => q(leva socialistes búlgaros),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Lev búlgaru),
				'one' => q(lev búlgaru),
				'other' => q(leva búlgaros),
			},
		},
		'BGO' => {
			symbol => 'BGO',
			display_name => {
				'currency' => q(Lev búlgaru \(1879–1952\)),
				'one' => q(lev búlgaru \(1879–1952\)),
				'other' => q(leva búlgaros \(1879–1952\)),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Dinar baḥreiní),
				'one' => q(dinar baḥreiní),
				'other' => q(dinares baḥreininos),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Francu burundianu),
				'one' => q(francu burundianu),
				'other' => q(francos burundianos),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Dólar bermudianu),
				'one' => q(dólar bermudianu),
				'other' => q(dólares bermudianos),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(dólar bruneyanu),
				'one' => q(dólar bruneyanu),
				'other' => q(dólares bruneyanos),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Bolivianu de Bolivia),
				'one' => q(bolivianu de Bolivia),
				'other' => q(bolivianos de Bolivia),
			},
		},
		'BOL' => {
			symbol => 'BOL',
			display_name => {
				'currency' => q(Boliviano de Bolivia \(1863–1963\)),
				'one' => q(boliviano de Bolivia \(1863–1963\)),
				'other' => q(bolivianos de Bolivia \(1863–1963\)),
			},
		},
		'BOP' => {
			symbol => 'BOP',
			display_name => {
				'currency' => q(Pesu bolivianu),
				'one' => q(pesu bolivianu),
				'other' => q(pesos bolivianos),
			},
		},
		'BOV' => {
			symbol => 'BOV',
			display_name => {
				'currency' => q(Bolivianos mvdol),
				'one' => q(bolivianu mvdol),
				'other' => q(bolivianos mvdol),
			},
		},
		'BRB' => {
			symbol => 'BRB',
			display_name => {
				'currency' => q(Cruzeiro nuevu brasilanu \(1967–1986\)),
				'one' => q(cruzeiro nuevu brasilanu \(1967–1986\)),
				'other' => q(cruzeiros nuevos brasilanos \(1967–1986\)),
			},
		},
		'BRC' => {
			symbol => 'BRC',
			display_name => {
				'currency' => q(Cruzado brasilanu \(1986–1989\)),
				'one' => q(cruzado brasilanu \(1986–1989\)),
				'other' => q(cruzados brasilanos \(1986–1989\)),
			},
		},
		'BRE' => {
			symbol => 'BRE',
			display_name => {
				'currency' => q(Cruzeiro brasilanu \(1990–1993\)),
				'one' => q(cruzeiro brasilanu \(1990–1993\)),
				'other' => q(cruzeiros brasilanos \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(real brasilanu),
				'one' => q(real brasilanu),
				'other' => q(reales brasilanos),
			},
		},
		'BRN' => {
			symbol => 'BRN',
			display_name => {
				'currency' => q(Cruzado nuevu brasilanu \(1989–1990\)),
				'one' => q(cruzado nuevu brasilanu \(1989–1990\)),
				'other' => q(cruzados nuevos brasilanos \(1989–1990\)),
			},
		},
		'BRR' => {
			symbol => 'BRR',
			display_name => {
				'currency' => q(Cruzeiro brasilanu \(1993–1994\)),
				'one' => q(cruzeiro brasilanu \(1993–1994\)),
				'other' => q(cruzeiros brasilanos \(1993–1994\)),
			},
		},
		'BRZ' => {
			symbol => 'BRZ',
			display_name => {
				'currency' => q(Cruzeiru brasilanu \(1942–1967\)),
				'one' => q(cruzeiru brasilanu \(1942–1967\)),
				'other' => q(cruzeiros brasilanos \(1942–1967\)),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Dólar bahamés),
				'one' => q(dólar bahamés),
				'other' => q(dólares bahameses),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Ngultrum butanés),
				'one' => q(ngultrum butanés),
				'other' => q(ngultrums butaneses),
			},
		},
		'BUK' => {
			symbol => 'BUK',
			display_name => {
				'currency' => q(Kyat birmanu),
				'one' => q(kyat birmanu),
				'other' => q(kyats birmanos),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Pula botsuaniana),
				'one' => q(pula botsuaniana),
				'other' => q(pulas botsuanianes),
			},
		},
		'BYB' => {
			symbol => 'BYB',
			display_name => {
				'currency' => q(Rublu nuevu bielorrusu \(1994–1999\)),
				'one' => q(rublu nuevu bielorrusu \(1994–1999\)),
				'other' => q(rublos nuevos bielorrusos \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(Rublu bielorrusu),
				'one' => q(rublu bielorrusu),
				'other' => q(rublos bielorrusos),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Rublu bielorrusu \(2000–2016\)),
				'one' => q(rublu bielorrusu \(2000–2016\)),
				'other' => q(rublos bielorrusos \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Dólar belizianu),
				'one' => q(dólar belizianu),
				'other' => q(dólares belizianos),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Dólar canadiense),
				'one' => q(dólar canadiense),
				'other' => q(dólares canadienses),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(francu congolés),
				'one' => q(francu congolés),
				'other' => q(francos congoleses),
			},
		},
		'CHE' => {
			symbol => 'CHE',
			display_name => {
				'currency' => q(Euru WIR),
				'one' => q(euru WIR),
				'other' => q(euros WIR),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(francu suizu),
				'one' => q(francu suizu),
				'other' => q(francos suizos),
			},
		},
		'CHW' => {
			symbol => 'CHW',
			display_name => {
				'currency' => q(Francu WIR),
				'one' => q(francu WIR),
				'other' => q(francos WIR),
			},
		},
		'CLE' => {
			symbol => 'CLE',
			display_name => {
				'currency' => q(Escudu chilenu),
				'one' => q(escudu chilenu),
				'other' => q(escudos chilenos),
			},
		},
		'CLF' => {
			symbol => 'CLF',
			display_name => {
				'currency' => q(Unidá de cuenta chilena \(UF\)),
				'one' => q(unidá de cuenta chilena \(UF\)),
				'other' => q(unidaes de cuenta chilenes \(UF\)),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(pesu chilenu),
				'one' => q(pesu chilenu),
				'other' => q(pesos chilenos),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(Dólar del Bancu Popular Chinu),
				'one' => q(dólar del Bancu Popular Chinu),
				'other' => q(dólares del Bancu Popular Chinu),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Yuan chinu),
				'one' => q(yuan chinu),
				'other' => q(yuanes chinos),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(pesu colombianu),
				'one' => q(pesu colombianu),
				'other' => q(pesos colombianos),
			},
		},
		'COU' => {
			symbol => 'COU',
			display_name => {
				'currency' => q(Unidá de valor real colombiana),
				'one' => q(unidá de valor real colombiana),
				'other' => q(unidaes de valor real colombianes),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Colón costarricanu),
				'one' => q(colón costarricanu),
				'other' => q(colones costarricanos),
			},
		},
		'CSD' => {
			symbol => 'CSD',
			display_name => {
				'currency' => q(Dinar serbiu \(2002–2006\)),
				'one' => q(dinar serbiu \(2002–2006\)),
				'other' => q(dinares serbios \(2002–2006\)),
			},
		},
		'CSK' => {
			symbol => 'CSK',
			display_name => {
				'currency' => q(Corona fuerte checoslovaca),
				'one' => q(corona fuerte checoslovaca),
				'other' => q(corones fuertes checoslovaques),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Pesu cubanu convertible),
				'one' => q(pesu cubanu convertible),
				'other' => q(pesos cubanos convertibles),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Pesu cubanu),
				'one' => q(pesu cubanu),
				'other' => q(pesos cubanos),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(escudu cabuverdianu),
				'one' => q(escudu cabuverdianu),
				'other' => q(escudos cabuverdianos),
			},
		},
		'CYP' => {
			symbol => 'CYP',
			display_name => {
				'currency' => q(Llibra xipriota),
				'one' => q(llibra xipriota),
				'other' => q(llibres xipriotes),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Corona checa),
				'one' => q(corona checa),
				'other' => q(corones cheques),
			},
		},
		'DDM' => {
			symbol => 'DDM',
			display_name => {
				'currency' => q(Marcu d’Alemaña Oriental),
				'one' => q(marcu d’Alemaña Oriental),
				'other' => q(marcos d’Alemaña Oriental),
			},
		},
		'DEM' => {
			symbol => 'DEM',
			display_name => {
				'currency' => q(Marcu alemán),
				'one' => q(marcu alemán),
				'other' => q(marcos alemanes),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Francu xibutianu),
				'one' => q(francu xibutianu),
				'other' => q(francos xibutianos),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(corona danesa),
				'one' => q(corona danesa),
				'other' => q(corones daneses),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Pesu dominicanu),
				'one' => q(pesu dominicanu),
				'other' => q(pesos dominicanos),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(dinar arxelín),
				'one' => q(dinar arxelín),
				'other' => q(dinares arxelinos),
			},
		},
		'ECS' => {
			symbol => 'ECS',
			display_name => {
				'currency' => q(Sucre ecuatorianu),
				'one' => q(sucre ecuatorianu),
				'other' => q(sucres ecuatorianos),
			},
		},
		'ECV' => {
			symbol => 'ECV',
			display_name => {
				'currency' => q(Unidá ecuatoriana de valor constante),
				'one' => q(unidá ecuatoriana de valor constante),
				'other' => q(unidaes ecuatorianes de valor constante),
			},
		},
		'EEK' => {
			symbol => 'EEK',
			display_name => {
				'currency' => q(Corona estonia),
				'one' => q(corona estoniana),
				'other' => q(corones estonianes),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(llibra exipciana),
				'one' => q(llibra exipciana),
				'other' => q(llibres exipcianes),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Nakfa eritréu),
				'one' => q(nakfa eritréu),
				'other' => q(nafkas eritreos),
			},
		},
		'ESA' => {
			symbol => 'ESA',
			display_name => {
				'currency' => q(Peseta española \(cuenta A\)),
				'one' => q(peseta española \(cuenta A\)),
				'other' => q(pesetes españoles \(cuenta A\)),
			},
		},
		'ESB' => {
			symbol => 'ESB',
			display_name => {
				'currency' => q(Peseta española \(cuenta convertible\)),
				'one' => q(peseta española \(cuenta convertible\)),
				'other' => q(pesetes españoles \(cuenta convertible\)),
			},
		},
		'ESP' => {
			symbol => 'ESP',
			display_name => {
				'currency' => q(Peseta española),
				'one' => q(peseta española),
				'other' => q(pesetes españoles),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Birr etíope),
				'one' => q(birr etíope),
				'other' => q(birrs etíopes),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(euro),
				'one' => q(euro),
				'other' => q(euros),
			},
		},
		'FIM' => {
			symbol => 'FIM',
			display_name => {
				'currency' => q(Marcu finlandés),
				'one' => q(marcu finlandés),
				'other' => q(marcos finlandeses),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(dólar fixanu),
				'one' => q(dólar fixanu),
				'other' => q(dólares fixanos),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(llibra malviniana),
				'one' => q(llibra malviniana),
				'other' => q(llibres malvinianes),
			},
		},
		'FRF' => {
			symbol => 'FRF',
			display_name => {
				'currency' => q(Francu francés),
				'one' => q(francu francés),
				'other' => q(francos franceses),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(llibra esterlina),
				'one' => q(llibra esterlina),
				'other' => q(llibres esterlines),
			},
		},
		'GEK' => {
			symbol => 'GEK',
			display_name => {
				'currency' => q(Kupon larit xeorxanu),
				'one' => q(kupon larit xeorxanu),
				'other' => q(kupon larits xeorxanos),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Lari xeorxanu),
				'one' => q(lari xeorxanu),
				'other' => q(laris xeorxanos),
			},
		},
		'GHC' => {
			symbol => 'GHC',
			display_name => {
				'currency' => q(Cedi ghanianu \(1979–2007\)),
				'one' => q(cedi ghanianu \(1979–2007\)),
				'other' => q(cedis ghanianos \(1979–2007\)),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(cedi ghanianu),
				'one' => q(cedi ghanianu),
				'other' => q(cedis ghanianos),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(llibra de Xibraltar),
				'one' => q(llibra de Xibraltar),
				'other' => q(llibres de Xibraltar),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(dalasi gambianu),
				'one' => q(dalasi gambianu),
				'other' => q(dalasis gambianos),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(francu guineanu),
				'one' => q(francu guineanu),
				'other' => q(francos guineanos),
			},
		},
		'GNS' => {
			symbol => 'GNS',
			display_name => {
				'currency' => q(syli guineanu),
				'one' => q(syli guineanu),
				'other' => q(sylis guineanos),
			},
		},
		'GQE' => {
			symbol => 'GQE',
			display_name => {
				'currency' => q(Ekwele de Guinea Ecuatorial),
				'one' => q(ekwele de Guinea Ecuatorial),
				'other' => q(ekweles de Guinea Ecuatorial),
			},
		},
		'GRD' => {
			symbol => 'GRD',
			display_name => {
				'currency' => q(Dracma griegu),
				'one' => q(dracma griegu),
				'other' => q(dracmes griegos),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Quetzal guatemalianu),
				'one' => q(quetzal guatemalianu),
				'other' => q(quetzales guatemalianos),
			},
		},
		'GWE' => {
			symbol => 'GWE',
			display_name => {
				'currency' => q(Escudo de Guinea portuguesa),
				'one' => q(escudo de Guinea portuguesa),
				'other' => q(escudos de Guinea portuguesa),
			},
		},
		'GWP' => {
			symbol => 'GWP',
			display_name => {
				'currency' => q(Pesu de Guinea-Bisáu),
				'one' => q(pesu de Guinea-Bisáu),
				'other' => q(pesos de Guinea-Bisáu),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(dólar guyanés),
				'one' => q(dólar guyanés),
				'other' => q(dólares guyaneses),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Dólar hongkonés),
				'one' => q(dólar hongkonés),
				'other' => q(dólares ḥongkoneses),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Lempira hondurana),
				'one' => q(lempira hondurana),
				'other' => q(lempires honduranes),
			},
		},
		'HRD' => {
			symbol => 'HRD',
			display_name => {
				'currency' => q(Dinar croata),
				'one' => q(dinar croata),
				'other' => q(dinares croates),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Kuna croata),
				'one' => q(kuna croata),
				'other' => q(kunes croates),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Gourde haitianu),
				'one' => q(gourde haitianu),
				'other' => q(gourde haitianos),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Forint húngaru),
				'one' => q(forint húngaru),
				'other' => q(forints húngaros),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(rupiah indonesia),
				'one' => q(rupiah indonesia),
				'other' => q(rupiahs indonesies),
			},
		},
		'IEP' => {
			symbol => 'IEP',
			display_name => {
				'currency' => q(Llibra irlandesa),
				'one' => q(llibra irlandesa),
				'other' => q(llibres irlandeses),
			},
		},
		'ILP' => {
			symbol => 'ILP',
			display_name => {
				'currency' => q(Llibra israelina),
				'one' => q(llibra israelina),
				'other' => q(llibres israelines),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(Xequel israelín \(1980–1985\)),
				'one' => q(xequel israelín \(1980–1985\)),
				'other' => q(xequels israelinos \(1980–1985\)),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(Xequel nuevu israelín),
				'one' => q(xequel nuevu israelín),
				'other' => q(xequels nuevos israelinos),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Rupia india),
				'one' => q(rupia india),
				'other' => q(rupies indies),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Dinar iraquín),
				'one' => q(dinar iraquín),
				'other' => q(dinares iraquinos),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Rial iranín),
				'one' => q(rial iranín),
				'other' => q(riales iraninos),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(Corona islandesa \(1918–1981\)),
				'one' => q(corona islandesa \(1918–1981\)),
				'other' => q(corones islandeses \(1918–1981\)),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(corona islandesa),
				'one' => q(corona islandesa),
				'other' => q(corones islandeses),
			},
		},
		'ITL' => {
			symbol => 'ITL',
			display_name => {
				'currency' => q(Llira italiana),
				'one' => q(llira italiana),
				'other' => q(llires italianes),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Dólar xamaicanu),
				'one' => q(dólar xamaicanu),
				'other' => q(dólares xamaicanos),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Dinar xordanu),
				'one' => q(dinar xordanu),
				'other' => q(dinares xordanos),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Yen xaponés),
				'one' => q(yen xaponés),
				'other' => q(yenes xaponeses),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Shilling kenianu),
				'one' => q(shilling kenianu),
				'other' => q(shillings kenianos),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Som kirguistanín),
				'one' => q(som kirguistanín),
				'other' => q(soms kirguistaninos),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(riel camboyanu),
				'one' => q(riel camboyanu),
				'other' => q(riels camboyanos),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Francu comoranu),
				'one' => q(francu comoranu),
				'other' => q(francos comoranos),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Won norcoreanu),
				'one' => q(won norcoreanu),
				'other' => q(wons norcoreanos),
			},
		},
		'KRH' => {
			symbol => 'KRH',
			display_name => {
				'currency' => q(Hwan surcoreanu \(1953–1962\)),
				'one' => q(hwan surcoreanu \(1953–1962\)),
				'other' => q(hwans surcoreanos \(1953–1962\)),
			},
		},
		'KRO' => {
			symbol => 'KRO',
			display_name => {
				'currency' => q(Won surcoreanu \(1945–1953\)),
				'one' => q(won surcoreanu \(1945–1953\)),
				'other' => q(won surcoreanos \(1945–1953\)),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Won surcoreanu),
				'one' => q(won surcoreanu),
				'other' => q(wons surcoreanos),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Dinar kuwaitianu),
				'one' => q(dinar kuwaitianu),
				'other' => q(dinares kuwaitianos),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(dólar caimanés),
				'one' => q(dólar caimanés),
				'other' => q(dólares caimaneses),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Tenge kazaquistanín),
				'one' => q(tenge kazaquistanín),
				'other' => q(tenges kazaquistaninos),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(kip laosianu),
				'one' => q(kip laosianu),
				'other' => q(kips laosianos),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Llibra libanesa),
				'one' => q(llibra libanesa),
				'other' => q(llibres libaneses),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Rupia de Sri Lanka),
				'one' => q(rupia de Sri Lanka),
				'other' => q(rupies de Sri Lanka),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(dólar liberianu),
				'one' => q(dólar liberianu),
				'other' => q(dólares liberianos),
			},
		},
		'LSL' => {
			symbol => 'LSL',
			display_name => {
				'currency' => q(Loti de Lesothu),
				'one' => q(loti de Lesothu),
				'other' => q(lotis de Lesothu),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(Litas lituanu),
				'one' => q(litas lituanu),
				'other' => q(litas lituanos),
			},
		},
		'LTT' => {
			symbol => 'LTT',
			display_name => {
				'currency' => q(Talonas lituanu),
				'one' => q(talonas lituanu),
				'other' => q(talonas lituanos),
			},
		},
		'LUC' => {
			symbol => 'LUC',
			display_name => {
				'currency' => q(Francu convertible luxemburgués),
				'one' => q(francu convertible luxemburgués),
				'other' => q(francos convertibles luxemburgueses),
			},
		},
		'LUF' => {
			symbol => 'LUF',
			display_name => {
				'currency' => q(Francu luxemburgués),
				'one' => q(francu luxemburgués),
				'other' => q(francos luxemburgueses),
			},
		},
		'LUL' => {
			symbol => 'LUL',
			display_name => {
				'currency' => q(Francu financieru luxemburgués),
				'one' => q(francu financieru luxemburgués),
				'other' => q(francos financieros luxemburgueses),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(Lats letón),
				'one' => q(lats letón),
				'other' => q(lats letones),
			},
		},
		'LVR' => {
			symbol => 'LVR',
			display_name => {
				'currency' => q(Rublu letón),
				'one' => q(rublu letón),
				'other' => q(rublos letones),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(dinar libiu),
				'one' => q(dinar libiu),
				'other' => q(dinares libios),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(dirḥam marroquín),
				'one' => q(dirḥam marroquín),
				'other' => q(dirḥams marroquinos),
			},
		},
		'MAF' => {
			symbol => 'MAF',
			display_name => {
				'currency' => q(francu marroquín),
				'one' => q(francu marroquín),
				'other' => q(francos marroquinos),
			},
		},
		'MCF' => {
			symbol => 'MCF',
			display_name => {
				'currency' => q(Francu monegascu),
				'one' => q(francu monegascu),
				'other' => q(francos monegascos),
			},
		},
		'MDC' => {
			symbol => 'MDC',
			display_name => {
				'currency' => q(Cupón moldavu),
				'one' => q(cupón moldavu),
				'other' => q(cupones moldavos),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Leu moldavu),
				'one' => q(leu moldavu),
				'other' => q(leus moldavos),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Ariary malgaxe),
				'one' => q(ariary malgaxe),
				'other' => q(ariarys malgaxes),
			},
		},
		'MGF' => {
			symbol => 'MGF',
			display_name => {
				'currency' => q(Francu malgaxe),
				'one' => q(francu malgaxe),
				'other' => q(francos malgaxes),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Denar macedoniu),
				'one' => q(denar macedoniu),
				'other' => q(denares macedonios),
			},
		},
		'MKN' => {
			symbol => 'MKN',
			display_name => {
				'currency' => q(Denar macedoniu \(1992–1993\)),
				'one' => q(denar macedoniu \(1992–1993\)),
				'other' => q(denares macedonios \(1992–1993\)),
			},
		},
		'MLF' => {
			symbol => 'MLF',
			display_name => {
				'currency' => q(Francu malianu),
				'one' => q(francu malianu),
				'other' => q(francos malianos),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(kyat de Myanmar),
				'one' => q(kyat de Myanmar),
				'other' => q(kyats de Myanmar),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Tugrik mongol),
				'one' => q(tugrik mongol),
				'other' => q(tugriks mongoles),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Pataca de Macáu),
				'one' => q(pataca de Macáu),
				'other' => q(pataques de Macáu),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(ouguiya mauritanu \(1973–2017\)),
				'one' => q(ouguiya mauritanu \(1973–2017\)),
				'other' => q(ouguiyas mauritanos \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(ouguiya mauritanu),
				'one' => q(ouguiya mauritanu),
				'other' => q(ouguiyas mauritanos),
			},
		},
		'MTL' => {
			symbol => 'MTL',
			display_name => {
				'currency' => q(Llira maltesa),
				'one' => q(llira maltesa),
				'other' => q(llires malteses),
			},
		},
		'MTP' => {
			symbol => 'MTP',
			display_name => {
				'currency' => q(Llibra maltesa),
				'one' => q(llibra maltesa),
				'other' => q(llibres malteses),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Rupia mauriciana),
				'one' => q(rupia mauriciana),
				'other' => q(rupies mauricianes),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(Rupia maldiviana \(1947–1981\)),
				'one' => q(rupia maldiviana \(1947–1981\)),
				'other' => q(rupies maldivianes \(1947–1981\)),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Rufiyaa maldiviana),
				'one' => q(rufiyaa maldiviana),
				'other' => q(rufiyaas maldivianas),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Kwacha malauianu),
				'one' => q(kwacha malauianu),
				'other' => q(kwachas malauianos),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(Pesu mexicanu),
				'one' => q(pesu mexicanu),
				'other' => q(pesos mexicanos),
			},
		},
		'MXP' => {
			symbol => 'MXP',
			display_name => {
				'currency' => q(Pesu de plata mexicanu \(1861–1992\)),
				'one' => q(pesu de plata mexicanu \(1861–1992\)),
				'other' => q(pesos de plata mexicanos \(1861–1992\)),
			},
		},
		'MXV' => {
			symbol => 'MXV',
			display_name => {
				'currency' => q(Unidá d’inversión mexicana),
				'one' => q(unidá d’inversión mexicana),
				'other' => q(unidaes d’inversión mexicanes),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(ringgit malasiu),
				'one' => q(ringgit malasiu),
				'other' => q(ringgits malasios),
			},
		},
		'MZE' => {
			symbol => 'MZE',
			display_name => {
				'currency' => q(Escudu mozambicanu),
				'one' => q(escudu mozambicanu),
				'other' => q(escudos mozambicanos),
			},
		},
		'MZM' => {
			symbol => 'MZM',
			display_name => {
				'currency' => q(Metical mozambicanu \(1980–2006\)),
				'one' => q(metical mozambicanu \(1980–2006\)),
				'other' => q(meticales mozambicanos \(1980–2006\)),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Metical mozambicanu),
				'one' => q(metical mozambicanu),
				'other' => q(meticales mozambicanos),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Dólar namibianu),
				'one' => q(dólar namibianu),
				'other' => q(dólares namibianos),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(naira nixeriana),
				'one' => q(naira nixeriana),
				'other' => q(nairas nixerianes),
			},
		},
		'NIC' => {
			symbol => 'NIC',
			display_name => {
				'currency' => q(Córdoba nicaraguanu \(1988–1991\)),
				'one' => q(córdoba nicaraguanu \(1988–1991\)),
				'other' => q(córdobes nicaraguanes \(1988–1991\)),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Córdoba nicaraguanu),
				'one' => q(córdoba nicaraguanu),
				'other' => q(córdobes nicaraguanos),
			},
		},
		'NLG' => {
			symbol => 'NLG',
			display_name => {
				'currency' => q(Florín neerlandés),
				'one' => q(florín neerlandés),
				'other' => q(florines neerlandeses),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(corona noruega),
				'one' => q(corona noruega),
				'other' => q(corones noruegues),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Rupia nepalesa),
				'one' => q(rupia nepalesa),
				'other' => q(rupies nepaleses),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(dólar neozelandés),
				'one' => q(dólar neozelandés),
				'other' => q(dólares neozelandeses),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Rial omanianu),
				'one' => q(rial omanianu),
				'other' => q(riales omanianos),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Balboa panamiegu),
				'one' => q(balboa panamiegu),
				'other' => q(balboes panamiegos),
			},
		},
		'PEI' => {
			symbol => 'PEI',
			display_name => {
				'currency' => q(Inti peruanu),
				'one' => q(inti peruanu),
				'other' => q(intis peruanos),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Sol peruanu),
				'one' => q(sol peruanu),
				'other' => q(soles peruanos),
			},
		},
		'PES' => {
			symbol => 'PES',
			display_name => {
				'currency' => q(Sol peruanu \(1863–1965\)),
				'one' => q(sol peruanu \(1863–1965\)),
				'other' => q(soles peruanos \(1863–1965\)),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(kina papuana),
				'one' => q(kina papuana),
				'other' => q(kines papuanes),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(pesu filipín),
				'one' => q(pesu filipín),
				'other' => q(pesos filipinos),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Rupia paquistanina),
				'one' => q(rupia paquistanina),
				'other' => q(rupies paquistanines),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Zloty polacu),
				'one' => q(zloty polacu),
				'other' => q(zlotys polacos),
			},
		},
		'PLZ' => {
			symbol => 'PLZ',
			display_name => {
				'currency' => q(Zloty polacu \(1950–1995\)),
				'one' => q(zloty polacu \(1950–1995\)),
				'other' => q(zloty polacos \(1950–1995\)),
			},
		},
		'PTE' => {
			symbol => 'PTE',
			display_name => {
				'currency' => q(Escudu portugués),
				'one' => q(escudu portugués),
				'other' => q(escudos portugueses),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(guaraní paraguayu),
				'one' => q(guaraní paraguayu),
				'other' => q(guaranís paraguayos),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Rial qatarín),
				'one' => q(rial qatarín),
				'other' => q(riales qatarinos),
			},
		},
		'RHD' => {
			symbol => 'RHD',
			display_name => {
				'currency' => q(Dólar rodesianu),
				'one' => q(dólar rodesianu),
				'other' => q(dólares rodesianos),
			},
		},
		'ROL' => {
			symbol => 'ROL',
			display_name => {
				'currency' => q(Leu rumanu \(1952–2006\)),
				'one' => q(leu rumanu \(1952–2006\)),
				'other' => q(leus rumanos \(1952–2006\)),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Leu rumanu),
				'one' => q(leu rumanu),
				'other' => q(leus rumanos),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(dinar serbiu),
				'one' => q(dinar serbiu),
				'other' => q(dinares serbios),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Rublu rusu),
				'one' => q(rublu rusu),
				'other' => q(rublos rusos),
			},
		},
		'RUR' => {
			symbol => 'RUR',
			display_name => {
				'currency' => q(Rublu rusu \(1991–1998\)),
				'one' => q(rublu rusu \(1991–1998\)),
				'other' => q(rublos rusos \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Francu ruandés),
				'one' => q(francu ruandés),
				'other' => q(francos ruandeses),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Riyal saudita),
				'one' => q(riyal saudita),
				'other' => q(riyales saudites),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(dólar salomonés),
				'one' => q(dólar salomonés),
				'other' => q(dólares salomoneses),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Rupia seixelesa),
				'one' => q(rupia seixelesa),
				'other' => q(rupies seixeleses),
			},
		},
		'SDD' => {
			symbol => 'SDD',
			display_name => {
				'currency' => q(dinar sudanés \(1992–2007\)),
				'one' => q(dinar sudanés \(1992–2007\)),
				'other' => q(dinares sudaneses \(1992–2007\)),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(llibra sudanesa),
				'one' => q(llibra sudanesa),
				'other' => q(llibres sudaneses),
			},
		},
		'SDP' => {
			symbol => 'SDP',
			display_name => {
				'currency' => q(llibra sudanesa \(1957–1998\)),
				'one' => q(llibra sudanesa \(1957–1998\)),
				'other' => q(llibres sudaneses \(1957–1998\)),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(corona sueca),
				'one' => q(corona sueca),
				'other' => q(corones sueques),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(dólar singapuranu),
				'one' => q(dólar singapuranu),
				'other' => q(dólares singapuranos),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(llibra de Santa Lena),
				'one' => q(llibra de Santa Lena),
				'other' => q(llibres de Santa Lena),
			},
		},
		'SIT' => {
			symbol => 'SIT',
			display_name => {
				'currency' => q(Tolar eslovenu),
				'one' => q(tolar eslovenu),
				'other' => q(tolares eslovenos),
			},
		},
		'SKK' => {
			symbol => 'SKK',
			display_name => {
				'currency' => q(Corona eslovaca),
				'one' => q(corona eslovaca),
				'other' => q(corones eslovaques),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(leone sierralleonés),
				'one' => q(leone sierralleonés),
				'other' => q(leones sierralleoneses),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Shilling somalín),
				'one' => q(shilling somalín),
				'other' => q(shillings somalinos),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(dólar surinamés),
				'one' => q(dólar surinamés),
				'other' => q(dólares surinameses),
			},
		},
		'SRG' => {
			symbol => 'SRG',
			display_name => {
				'currency' => q(Florín surinamés),
				'one' => q(florín surinamés),
				'other' => q(florinos surinameses),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(llibra sursudanesa),
				'one' => q(llibra sursudanesa),
				'other' => q(llibres sursudaneses),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(dobra de Santu Tomé y Príncipe \(1977–2017\)),
				'one' => q(dobra de Santu Tomé y Príncipe \(1977–2017\)),
				'other' => q(dobras de Santu Tomé y Príncipe \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'Db',
			display_name => {
				'currency' => q(dobra de Santu Tomé y Príncipe),
				'one' => q(dobra de Santu Tomé y Príncipe),
				'other' => q(dobras de Santu Tomé y Príncipe),
			},
		},
		'SUR' => {
			symbol => 'SUR',
			display_name => {
				'currency' => q(Rublu soviéticu),
				'one' => q(rublu soviéticu),
				'other' => q(rublos soviéticos),
			},
		},
		'SVC' => {
			symbol => 'SVC',
			display_name => {
				'currency' => q(Colón salvadorianu),
				'one' => q(colón salvadorianu),
				'other' => q(colones salvadorianos),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Llibra siria),
				'one' => q(llibra siria),
				'other' => q(llibres siries),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Lilangeni suazilandés),
				'one' => q(lilangeni suazilandés),
				'other' => q(lilangenis suazilandeses),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(baht tailandés),
				'one' => q(baht tailandés),
				'other' => q(bahts tailandeses),
			},
		},
		'TJR' => {
			symbol => 'TJR',
			display_name => {
				'currency' => q(Rublu taxiquistanín),
				'one' => q(rublu taxiquistanín),
				'other' => q(rublos taxiquistaninos),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Somoni taxiquistanín),
				'one' => q(somoni taxiquistanín),
				'other' => q(somonis taxiquistaninos),
			},
		},
		'TMM' => {
			symbol => 'TMM',
			display_name => {
				'currency' => q(Manat turcomanu \(1993–2009\)),
				'one' => q(manat turcomanu \(1993–2009\)),
				'other' => q(manats turcomanos \(1993–2009\)),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Manat turcomanu),
				'one' => q(manat turcomanu),
				'other' => q(manats turcomanos),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(dinar tunecín),
				'one' => q(dinar tunecín),
				'other' => q(dinares tunecinos),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(paʻanga tonganu),
				'one' => q(paʻanga tonganu),
				'other' => q(paʻangas tonganos),
			},
		},
		'TPE' => {
			symbol => 'TPE',
			display_name => {
				'currency' => q(Escudu timorés),
				'one' => q(escudu timorés),
				'other' => q(escudos timoreses),
			},
		},
		'TRL' => {
			symbol => 'TRL',
			display_name => {
				'currency' => q(Llira turca \(1922–2005\)),
				'one' => q(llira turca \(1922–2005\)),
				'other' => q(llires turques \(1922–2005\)),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Llira turca),
				'one' => q(llira turca),
				'other' => q(llires turques),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(dólar de Trinidá y Tobagu),
				'one' => q(dólar de Trinidá y Tobagu),
				'other' => q(dólares de Trinidá y Tobagu),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Dólar nuevu taiwanés),
				'one' => q(dólar nuevu taiwanés),
				'other' => q(dólares nuevos taiwaneses),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Shilling tanzanianu),
				'one' => q(shilling tanzanianu),
				'other' => q(shillings tanzanianos),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Grivna ucraína),
				'one' => q(grivna ucraína),
				'other' => q(grivnas ucraínes),
			},
		},
		'UAK' => {
			symbol => 'UAK',
			display_name => {
				'currency' => q(Karbovanets ucraína),
				'one' => q(karbovanets ucraína),
				'other' => q(karbovanets ucraínes),
			},
		},
		'UGS' => {
			symbol => 'UGS',
			display_name => {
				'currency' => q(Shilling ugandés \(1966–1987\)),
				'one' => q(shilling ugandés \(1966–1987\)),
				'other' => q(shillings ugandeses \(1966–1987\)),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Shilling ugandés),
				'one' => q(shilling ugandés),
				'other' => q(shillings ugandeses),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Dólar estaunidense),
				'one' => q(dólar estaunidense),
				'other' => q(dólares estaunidenses),
			},
		},
		'USN' => {
			symbol => 'USN',
			display_name => {
				'currency' => q(Dólar d’EE.XX. \(día siguiente\)),
				'one' => q(dólar d’EE.XX. \(día siguiente\)),
				'other' => q(dólares d’EE.XX. \(día siguiente\)),
			},
		},
		'USS' => {
			symbol => 'USS',
			display_name => {
				'currency' => q(Dólar d’EE.XX. \(mesmu día\)),
				'one' => q(dólar d’EE.XX. \(mesmu día\)),
				'other' => q(dólares d’EE.XX. \(mesmu día\)),
			},
		},
		'UYI' => {
			symbol => 'UYI',
			display_name => {
				'currency' => q(Pesu uruguayu \(Unidaes indexaes\)),
				'one' => q(pesu uruguayu \(unidaes indexaes\)),
				'other' => q(pesos uruguayos \(unidaes indexaes\)),
			},
		},
		'UYP' => {
			symbol => 'UYP',
			display_name => {
				'currency' => q(Pesu uruguayu \(1975–1993\)),
				'one' => q(pesu uruguayu \(1975–1993\)),
				'other' => q(pesos uruguayos \(1975–1993\)),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(pesu uruguayu),
				'one' => q(pesu uruguayu),
				'other' => q(pesos uruguayos),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(Som uzbequistanín),
				'one' => q(som uzbequistanín),
				'other' => q(soms uzbequistaninos),
			},
		},
		'VEB' => {
			symbol => 'VEB',
			display_name => {
				'currency' => q(Bolívar venezolanu \(1871–2008\)),
				'one' => q(bolívar venezolanu \(1871–2008\)),
				'other' => q(bolívares venezolanos \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(bolívar venezolanu \(2008–2018\)),
				'one' => q(bolívar venezolanu \(2008–2018\)),
				'other' => q(bolívares venezolanos \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(bolívar venezolanu),
				'one' => q(bolívar venezolanu),
				'other' => q(bolívares venezolanos),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(dong vietnamín),
				'one' => q(dong vietnamín),
				'other' => q(dongs vietnaminos),
			},
		},
		'VNN' => {
			symbol => 'VNN',
			display_name => {
				'currency' => q(Dong vietnamín \(1978–1985\)),
				'one' => q(dong vietnamín \(1978–1985\)),
				'other' => q(dongs vietnaminos \(1978–1985\)),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(vatu vanuatuanu),
				'one' => q(vatu vanuatuanu),
				'other' => q(vatus vanuatuanos),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(tala samoanu),
				'one' => q(tala samoanu),
				'other' => q(talas samoanos),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(Francu CFA centroafricanu),
				'one' => q(francu CFA centroafricanu),
				'other' => q(francos CFA centroafricanos),
			},
		},
		'XAG' => {
			symbol => 'XAG',
			display_name => {
				'currency' => q(Plata),
				'one' => q(onza troy de plata),
				'other' => q(onces troy de plata),
			},
		},
		'XAU' => {
			symbol => 'XAU',
			display_name => {
				'currency' => q(Oru),
				'one' => q(onza troy d’oru),
				'other' => q(onces troy d’oru),
			},
		},
		'XBA' => {
			symbol => 'XBA',
			display_name => {
				'currency' => q(Unidá Compuesta Europea),
				'one' => q(unidá compuesta europea),
				'other' => q(unidaes compuestes europées),
			},
		},
		'XBB' => {
			symbol => 'XBB',
			display_name => {
				'currency' => q(Unidá monetaria europea),
				'one' => q(unidá monetaria europea),
				'other' => q(unidaes monetaries europées),
			},
		},
		'XBC' => {
			symbol => 'XBC',
			display_name => {
				'currency' => q(Unidá de cuenta europea \(XBC\)),
				'one' => q(unidá de cuenta europea \(XBC\)),
				'other' => q(unidaes de cuenta europées \(XBC\)),
			},
		},
		'XBD' => {
			symbol => 'XBD',
			display_name => {
				'currency' => q(Unidá de cuenta europea \(XBD\)),
				'one' => q(unidá de cuenta europea \(XBD\)),
				'other' => q(unidaes de cuenta europées \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(dólar del Caribe Oriental),
				'one' => q(dólar del Caribe Oriental),
				'other' => q(dólares del Caribe Oriental),
			},
		},
		'XDR' => {
			symbol => 'XDR',
			display_name => {
				'currency' => q(Drechos especiales de xiru),
				'one' => q(drechos especiales de xiru),
				'other' => q(drechos especiales de xiru),
			},
		},
		'XEU' => {
			symbol => 'XEU',
			display_name => {
				'currency' => q(Unidá de divisa europea),
				'one' => q(unidá de divisa europea),
				'other' => q(unidaes de divisa europees),
			},
		},
		'XFO' => {
			symbol => 'XFO',
			display_name => {
				'currency' => q(Francu oru francés),
				'one' => q(francu oru francés),
				'other' => q(francos oru franceses),
			},
		},
		'XFU' => {
			symbol => 'XFU',
			display_name => {
				'currency' => q(Francu UIC francés),
				'one' => q(francu UIC francés),
				'other' => q(francos UIC franceses),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(francu CFA BCEAO),
				'one' => q(francu CFA BCEAO),
				'other' => q(francos CFA BCEAO),
			},
		},
		'XPD' => {
			symbol => 'XPD',
			display_name => {
				'currency' => q(Paladiu),
				'one' => q(onza troy de paladiu),
				'other' => q(onces troy de paladiu),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(francu CFP),
				'one' => q(francu CFP),
				'other' => q(francos CFP),
			},
		},
		'XPT' => {
			symbol => 'XPT',
			display_name => {
				'currency' => q(Platín),
				'one' => q(onza troy de platín),
				'other' => q(onces troy de platín),
			},
		},
		'XRE' => {
			symbol => 'XRE',
			display_name => {
				'currency' => q(Fondos RINET),
				'one' => q(unidá de fondos RINET),
				'other' => q(unidaes de fondos RINET),
			},
		},
		'XSU' => {
			symbol => 'XSU',
			display_name => {
				'currency' => q(Sucre),
				'one' => q(sucre),
				'other' => q(sucres),
			},
		},
		'XTS' => {
			symbol => 'XTS',
			display_name => {
				'currency' => q(Códigu monetariu de prueba),
				'one' => q(códigu monetariu de prueba),
				'other' => q(códigos monetarios de prueba),
			},
		},
		'XUA' => {
			symbol => 'XUA',
			display_name => {
				'currency' => q(unidá de cuenta ADB),
				'one' => q(unidá de cuenta ADB),
				'other' => q(unidaes de cuenta ADB),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(Divisa desconocida),
				'one' => q(\(unidá desconocida de divisa\)),
				'other' => q(\(divises desconocíes\)),
			},
		},
		'YDD' => {
			symbol => 'YDD',
			display_name => {
				'currency' => q(Dinar yemenín),
				'one' => q(dinar yemenín),
				'other' => q(dinares yemeninos),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Rial yemenín),
				'one' => q(rial yemenín),
				'other' => q(riales yemeninos),
			},
		},
		'YUD' => {
			symbol => 'YUD',
			display_name => {
				'currency' => q(Dinar fuerte yugoslavu \(1966–1990\)),
				'one' => q(dinar fuerte yugoslavu \(1966–1990\)),
				'other' => q(dinares fuertes yugoslavos \(1966–1990\)),
			},
		},
		'YUM' => {
			symbol => 'YUM',
			display_name => {
				'currency' => q(Dinar nuevu yugoslavu \(1994–2002\)),
				'one' => q(dinar nuevu yugoslavu \(1994–2002\)),
				'other' => q(dinares nuevos yugoslavos \(1994–2002\)),
			},
		},
		'YUN' => {
			symbol => 'YUN',
			display_name => {
				'currency' => q(Dinar convertible yugoslavu \(1990–1992\)),
				'one' => q(dinar convertible yugoslavu \(1990–1992\)),
				'other' => q(dinares convertibles yugoslavos \(1990–1992\)),
			},
		},
		'YUR' => {
			symbol => 'YUR',
			display_name => {
				'currency' => q(Dinar reformáu yugoslavu \(1992–1993\)),
				'one' => q(dinar reformáu yugoslavu \(1992–1993\)),
				'other' => q(dinares reformaos yugoslavos \(1992–1993\)),
			},
		},
		'ZAL' => {
			symbol => 'ZAL',
			display_name => {
				'currency' => q(Rand sudafricanu \(financieru\)),
				'one' => q(rand sudafricanu \(financieru\)),
				'other' => q(rands sudafricanos \(financieros\)),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Rand sudafricanu),
				'one' => q(rand sudafricanu),
				'other' => q(rands sudafricanos),
			},
		},
		'ZMK' => {
			symbol => 'ZMK',
			display_name => {
				'currency' => q(Kwacha zambianu \(1968–2012\)),
				'one' => q(kwacha zambianu \(1968–2012\)),
				'other' => q(kwachas zambianos \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Kwacha zambianu),
				'one' => q(kwacha zambianu),
				'other' => q(kwachas zambianos),
			},
		},
		'ZRN' => {
			symbol => 'ZRN',
			display_name => {
				'currency' => q(Zaire nuevu zairiegu \(1993–1998\)),
				'one' => q(zaire nuevu zairiegu \(1993–1998\)),
				'other' => q(zaires nuevos zairiegos \(1993–1998\)),
			},
		},
		'ZRZ' => {
			symbol => 'ZRZ',
			display_name => {
				'currency' => q(Zaire zairiegu \(1971–1993\)),
				'one' => q(zaire zairiegu \(1971–1993\)),
				'other' => q(zaires zairiegos \(1971–1993\)),
			},
		},
		'ZWD' => {
			symbol => 'ZWD',
			display_name => {
				'currency' => q(Dólar zimbabuanu \(1980–2008\)),
				'one' => q(dólar zimbabuanu \(1980–2008\)),
				'other' => q(dólares zimbabuanos \(1980–2008\)),
			},
		},
		'ZWL' => {
			symbol => 'ZWL',
			display_name => {
				'currency' => q(Dólar zimbabuanu \(2009\)),
				'one' => q(dólar zimbabuanu \(2009\)),
				'other' => q(dólares zimbabuanos \(2009\)),
			},
		},
		'ZWR' => {
			symbol => 'ZWR',
			display_name => {
				'currency' => q(Dólar zimbabuanu \(2008\)),
				'one' => q(dólar zimbabuanu \(2008\)),
				'other' => q(dólares zimbabuanos \(2008\)),
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
							'mes 1',
							'mes 2',
							'mes 3',
							'mes 4',
							'mes 5',
							'mes 6',
							'mes 7',
							'mes 8',
							'mes 9',
							'mes 10',
							'mes 11',
							'mes 12'
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
							'mes 1',
							'mes 2',
							'mes 3',
							'mes 4',
							'mes 5',
							'mes 6',
							'mes 7',
							'mes 8',
							'mes 9',
							'mes 10',
							'mes 11',
							'mes 12'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
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
							'Mes 1',
							'Mes 2',
							'Mes 3',
							'Mes 4',
							'Mes 5',
							'Mes 6',
							'Mes 7',
							'Mes 8',
							'Mes 9',
							'Mes 10',
							'Mes 11',
							'Mes 12'
						],
						leap => [
							
						],
					},
				},
			},
			'ethiopic' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'mes',
							'tek',
							'hed',
							'tah',
							'ter',
							'yek',
							'meg',
							'mia',
							'gen',
							'sen',
							'ham',
							'neh',
							'pag'
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
							'12',
							'13'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'de meskerem',
							'de tekemt',
							'd’hedar',
							'de tahsas',
							'de ter',
							'de yekatit',
							'de megabit',
							'de miazia',
							'de genbot',
							'de sene',
							'd’hamle',
							'de nehasse',
							'de pagumen'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'mes',
							'tek',
							'hed',
							'tah',
							'ter',
							'yek',
							'meg',
							'mia',
							'gen',
							'sen',
							'ham',
							'neh',
							'pag'
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
							'12',
							'13'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Meskerem',
							'Tekemt',
							'Hedar',
							'Tahsas',
							'Ter',
							'Yekatit',
							'Megabit',
							'Miazia',
							'Genbot',
							'Sene',
							'Hamle',
							'Nehasse',
							'Pagumen'
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
							'xin',
							'feb',
							'mar',
							'abr',
							'may',
							'xun',
							'xnt',
							'ago',
							'set',
							'och',
							'pay',
							'avi'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'X',
							'F',
							'M',
							'A',
							'M',
							'X',
							'X',
							'A',
							'S',
							'O',
							'P',
							'A'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'de xineru',
							'de febreru',
							'de marzu',
							'd’abril',
							'de mayu',
							'de xunu',
							'de xunetu',
							'd’agostu',
							'de setiembre',
							'd’ochobre',
							'de payares',
							'd’avientu'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Xin',
							'Feb',
							'Mar',
							'Abr',
							'May',
							'Xun',
							'Xnt',
							'Ago',
							'Set',
							'Och',
							'Pay',
							'Avi'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'X',
							'F',
							'M',
							'A',
							'M',
							'X',
							'X',
							'A',
							'S',
							'O',
							'P',
							'A'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'xineru',
							'febreru',
							'marzu',
							'abril',
							'mayu',
							'xunu',
							'xunetu',
							'agostu',
							'setiembre',
							'ochobre',
							'payares',
							'avientu'
						],
						leap => [
							
						],
					},
				},
			},
			'hebrew' => {
				'format' => {
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
							'12',
							'13'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'7b'
						],
					},
				},
				'stand-alone' => {
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
							'12',
							'13'
						],
						leap => [
							'',
							'',
							'',
							'',
							'',
							'',
							'7bis'
						],
					},
				},
			},
			'indian' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'Chaitra',
							'Vaisakha',
							'Jyaistha',
							'Asadha',
							'Sravana',
							'Bhadra',
							'Asvina',
							'Kartika',
							'Agrahayana',
							'Pausa',
							'Magha',
							'Phalguna'
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
							'de Chaitra',
							'de Vaisakha',
							'de Jyaistha',
							'd’Asadha',
							'de Sravana',
							'de Bhadra',
							'd’Asvina',
							'de Kartika',
							'd’Agrahayana',
							'de Pausa',
							'de Magha',
							'de Phalguna'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Chaitra',
							'Vaisakha',
							'Jyaistha',
							'Asadha',
							'Sravana',
							'Bhadra',
							'Asvina',
							'Kartika',
							'Agrahayana',
							'Pausa',
							'Magha',
							'Phalguna'
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
							'Chaitra',
							'Vaisakha',
							'Jyaistha',
							'Asadha',
							'Sravana',
							'Bhadra',
							'Asvina',
							'Kartika',
							'Agrahayana',
							'Pausa',
							'Magha',
							'Phalguna'
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
							'Muh.',
							'Saf.',
							'Rab. I',
							'Rab. II',
							'Jum. I',
							'Jum. II',
							'Raj.',
							'Sha.',
							'Ram.',
							'Shaw.',
							'Dhuʻl-Q.',
							'Dhuʻl-H.'
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
							'de Muharram',
							'de Safar',
							'de Rabiʻ I',
							'de Rabiʻ II',
							'de Jumada I',
							'de Jumada II',
							'de Rajab',
							'de Shaʻban',
							'de Ramadan',
							'de Shawwal',
							'de Dhuʻl-Qiʻdah',
							'de Dhuʻl-Hijjah'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Muh.',
							'Saf.',
							'Rab. I',
							'Rab. II',
							'Jum. I',
							'Jum. II',
							'Raj.',
							'Sha.',
							'Ram.',
							'Shaw.',
							'Dhuʻl-Q.',
							'Dhuʻl-H.'
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
							'Muharram',
							'Safar',
							'Rabiʻ I',
							'Rabiʻ II',
							'Jumada I',
							'Jumada II',
							'Rajab',
							'Shaʻban',
							'Ramadan',
							'Shawwal',
							'Dhuʻl-Qiʻdah',
							'Dhuʻl-Hijjah'
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
						mon => 'llu',
						tue => 'mar',
						wed => 'mié',
						thu => 'xue',
						fri => 'vie',
						sat => 'sáb',
						sun => 'dom'
					},
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'X',
						fri => 'V',
						sat => 'S',
						sun => 'D'
					},
					short => {
						mon => 'll',
						tue => 'ma',
						wed => 'mi',
						thu => 'xu',
						fri => 'vi',
						sat => 'sá',
						sun => 'do'
					},
					wide => {
						mon => 'llunes',
						tue => 'martes',
						wed => 'miércoles',
						thu => 'xueves',
						fri => 'vienres',
						sat => 'sábadu',
						sun => 'domingu'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'llu',
						tue => 'mar',
						wed => 'mié',
						thu => 'xue',
						fri => 'vie',
						sat => 'sáb',
						sun => 'dom'
					},
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'M',
						thu => 'X',
						fri => 'V',
						sat => 'S',
						sun => 'D'
					},
					short => {
						mon => 'll',
						tue => 'ma',
						wed => 'mi',
						thu => 'xu',
						fri => 'vi',
						sat => 'sá',
						sun => 'do'
					},
					wide => {
						mon => 'llunes',
						tue => 'martes',
						wed => 'miércoles',
						thu => 'xueves',
						fri => 'vienres',
						sat => 'sábadu',
						sun => 'domingu'
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
					abbreviated => {0 => '1T',
						1 => '2T',
						2 => '3T',
						3 => '4T'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1er trimestre',
						1 => '2u trimestre',
						2 => '3er trimestre',
						3 => '4u trimestre'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1T',
						1 => '2T',
						2 => '3T',
						3 => '4T'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1er trimestre',
						1 => '2u trimestre',
						2 => '3er trimestre',
						3 => '4u trimestre'
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
					'am' => q{a},
					'pm' => q{p},
				},
				'wide' => {
					'pm' => q{de la tarde},
					'am' => q{de la mañana},
				},
				'abbreviated' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'pm' => q{PM},
					'am' => q{AM},
				},
				'wide' => {
					'pm' => q{tarde},
					'am' => q{mañana},
				},
				'narrow' => {
					'am' => q{a},
					'pm' => q{p},
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
				'0' => 'EB'
			},
			narrow => {
				'0' => 'EB'
			},
			wide => {
				'0' => 'era budista'
			},
		},
		'chinese' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
			abbreviated => {
				'0' => 'a. E.',
				'1' => 'd. E.'
			},
			narrow => {
				'0' => 'aE',
				'1' => 'dE'
			},
			wide => {
				'0' => 'antes de la Encarnación',
				'1' => 'después de la Encarnación'
			},
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'e.C.',
				'1' => 'd.C.'
			},
			wide => {
				'0' => 'enantes de Cristu',
				'1' => 'después de Cristu'
			},
		},
		'hebrew' => {
		},
		'indian' => {
			abbreviated => {
				'0' => 'Saka'
			},
			narrow => {
				'0' => 'Saka'
			},
			wide => {
				'0' => 'Saka'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'AH'
			},
			narrow => {
				'0' => 'AH'
			},
			wide => {
				'0' => 'AH'
			},
		},
		'japanese' => {
			abbreviated => {
				'0' => 'Taika',
				'1' => 'Hakuchi',
				'2' => 'Hakuhō',
				'3' => 'Shuchō',
				'4' => 'Taihō',
				'5' => 'Keiun',
				'6' => 'Wadō',
				'7' => 'Reiki',
				'8' => 'Yōrō',
				'9' => 'Jinki',
				'10' => 'Tenpyō',
				'11' => 'T.-kampō',
				'12' => 'T.-shōhō',
				'13' => 'T.-hōji',
				'14' => 'T.-jingo',
				'15' => 'J.-keiun',
				'16' => 'Hōki',
				'17' => 'Ten-ō',
				'18' => 'Enryaku',
				'19' => 'Daidō',
				'20' => 'Kōnin',
				'21' => 'Tenchō',
				'22' => 'Jōwa',
				'23' => 'Kajō',
				'24' => 'Ninju',
				'25' => 'Saikō',
				'26' => 'Ten-an',
				'27' => 'Jōgan',
				'28' => 'Gangyō',
				'29' => 'Ninna',
				'30' => 'Kanpyō',
				'31' => 'Shōtai',
				'32' => 'Engi',
				'33' => 'Enchō',
				'34' => 'Jōhei',
				'35' => 'Tengyō',
				'36' => 'Tenryaku',
				'37' => 'Tentoku',
				'38' => 'Ōwa',
				'39' => 'Kōhō',
				'40' => 'Anna',
				'41' => 'Tenroku',
				'42' => 'Ten’en',
				'43' => 'Jōgen',
				'44' => 'Tengen',
				'45' => 'Eikan',
				'46' => 'Kanna',
				'47' => 'Eien',
				'48' => 'Eiso',
				'49' => 'Shōryaku',
				'50' => 'Chōtoku',
				'51' => 'Chōhō',
				'52' => 'Kankō',
				'53' => 'Chōwa',
				'54' => 'Kannin',
				'55' => 'Jian',
				'56' => 'Manju',
				'57' => 'Chōgen',
				'58' => 'Chōryaku',
				'59' => 'Chōkyū',
				'60' => 'Kantoku',
				'61' => 'Eishō',
				'62' => 'Tengi',
				'63' => 'Kōhei',
				'64' => 'Jiryaku',
				'65' => 'Enkyū',
				'66' => 'Shōho',
				'67' => 'Shōryaku II',
				'68' => 'Eihō',
				'69' => 'Ōtoku',
				'70' => 'Kanji',
				'71' => 'Kahō',
				'72' => 'Eichō',
				'73' => 'Jōtoku',
				'74' => 'Kōwa',
				'75' => 'Chōji',
				'76' => 'Kashō',
				'77' => 'Tennin',
				'78' => 'Ten-ei',
				'79' => 'Eikyū',
				'80' => 'Gen’ei',
				'81' => 'Hōan',
				'82' => 'Tenji',
				'83' => 'Daiji',
				'84' => 'Tenshō',
				'85' => 'Chōshō',
				'86' => 'Hōen',
				'87' => 'Eiji',
				'88' => 'Kōji',
				'89' => 'Ten’yō',
				'90' => 'Kyūan',
				'91' => 'Ninpei',
				'92' => 'Kyūju',
				'93' => 'Hōgen',
				'94' => 'Heiji',
				'95' => 'Eiryaku',
				'96' => 'Ōho',
				'97' => 'Chōkan',
				'98' => 'Eiman',
				'99' => 'Nin’an',
				'100' => 'Kaō',
				'101' => 'Shōan',
				'102' => 'Angen',
				'103' => 'Jishō',
				'104' => 'Yōwa',
				'105' => 'Juei',
				'106' => 'Genryaku',
				'107' => 'Bunji',
				'108' => 'Kenkyū',
				'109' => 'Shōji',
				'110' => 'Kennin',
				'111' => 'Genkyū',
				'112' => 'Ken’ei',
				'113' => 'Jōgen II',
				'114' => 'Kenryaku',
				'115' => 'Kenpō',
				'116' => 'Jōkyū',
				'117' => 'Jōō',
				'118' => 'Gennin',
				'119' => 'Karoku',
				'120' => 'Antei',
				'121' => 'Kanki',
				'122' => 'Jōei',
				'123' => 'Tenpuku',
				'124' => 'Bunryaku',
				'125' => 'Katei',
				'126' => 'Ryakunin',
				'127' => 'En’ō',
				'128' => 'Ninji',
				'129' => 'Kangen',
				'130' => 'Hōji',
				'131' => 'Kenchō',
				'132' => 'Kōgen',
				'133' => 'Shōka',
				'134' => 'Shōgen',
				'135' => 'Bun’ō',
				'136' => 'Kōchō',
				'137' => 'Bun’ei',
				'138' => 'Kenji',
				'139' => 'Kōan',
				'140' => 'Shōō',
				'141' => 'Einin',
				'142' => 'Shōan II',
				'143' => 'Kengen',
				'144' => 'Kagen',
				'145' => 'Tokuji',
				'146' => 'Enkyō',
				'147' => 'Ōchō',
				'148' => 'Shōwa',
				'149' => 'Bunpō',
				'150' => 'Genō',
				'151' => 'Genkō',
				'152' => 'Shōchū',
				'153' => 'Karyaku',
				'154' => 'Gentoku',
				'155' => 'Genkō II',
				'156' => 'Kenmu',
				'157' => 'Engen',
				'158' => 'Kōkoku',
				'159' => 'Shōhei',
				'160' => 'Kentoku',
				'161' => 'Bunchū',
				'162' => 'Tenju',
				'163' => 'Kōryaku',
				'164' => 'Kōwa II',
				'165' => 'Genchū',
				'166' => 'Meitoku',
				'167' => 'Kakei',
				'168' => 'Kōō',
				'169' => 'Meitoku II',
				'170' => 'Ōei',
				'171' => 'Shōchō',
				'172' => 'Eikyō',
				'173' => 'Kakitsu',
				'174' => 'Bun’an',
				'175' => 'Hōtoku',
				'176' => 'Kyōtoku',
				'177' => 'Kōshō',
				'178' => 'Chōroku',
				'179' => 'Kanshō',
				'180' => 'Bunshō',
				'181' => 'Ōnin',
				'182' => 'Bunmei',
				'183' => 'Chōkyō',
				'184' => 'Entoku',
				'185' => 'Meiō',
				'186' => 'Bunki',
				'187' => 'Eishō II',
				'188' => 'Taiei',
				'189' => 'Kyōroku',
				'190' => 'Tenbun',
				'191' => 'Kōji II',
				'192' => 'Eiroku',
				'193' => 'Genki',
				'194' => 'Tenshō II',
				'195' => 'Bunroku',
				'196' => 'Keichō',
				'197' => 'Genna',
				'198' => 'Kan’ei',
				'199' => 'Shōho II',
				'200' => 'Keian',
				'201' => 'Jōō II',
				'202' => 'Meireki',
				'203' => 'Manji',
				'204' => 'Kanbun',
				'205' => 'Enpō',
				'206' => 'Tenna',
				'207' => 'Jōkyō',
				'208' => 'Genroku',
				'209' => 'Hōei',
				'210' => 'Shōtoku',
				'211' => 'Kyōhō',
				'212' => 'Genbun',
				'213' => 'Kanpō',
				'214' => 'Enkyō II',
				'215' => 'Kan’en',
				'216' => 'Hōreki',
				'217' => 'Meiwa',
				'218' => 'An’ei',
				'219' => 'Tenmei',
				'220' => 'Kansei',
				'221' => 'Kyōwa',
				'222' => 'Bunka',
				'223' => 'Bunsei',
				'224' => 'Tenpō',
				'225' => 'Kōka',
				'226' => 'Kaei',
				'227' => 'Ansei',
				'228' => 'Man’en',
				'229' => 'Bunkyū',
				'230' => 'Genji',
				'231' => 'Keiō',
				'232' => 'Meiji',
				'233' => 'Taishō',
				'234' => 'e. Shōwa',
				'235' => 'Heisei'
			},
			narrow => {
				'0' => 'Taika',
				'10' => 'Tenpyō',
				'11' => 'T. kampō',
				'12' => 'T. shōhō',
				'13' => 'T. hōji',
				'14' => 'T. jingo',
				'25' => 'Saikō',
				'26' => 'Ten-an',
				'27' => 'Jōgan',
				'28' => 'Gangyō',
				'30' => 'Kanpyō',
				'34' => 'Jōhei',
				'36' => 'Tenryaku',
				'47' => 'Eien',
				'68' => 'Eihō'
			},
			wide => {
				'0' => 'Taika (645–650)',
				'1' => 'Hakuchi (650–671)',
				'2' => 'Hakuhō (672–686)',
				'3' => 'Shuchō (686–701)',
				'4' => 'Taihō (701–704)',
				'5' => 'Keiun (704–708)',
				'6' => 'Wadō (708–715)',
				'7' => 'Reiki (715–717)',
				'8' => 'Yōrō (717–724)',
				'9' => 'Jinki (724–729)',
				'10' => 'Tenpyō (729–749)',
				'11' => 'Tenpyō-kampō (749-749)',
				'12' => 'Tenpyō-shōhō (749-757)',
				'13' => 'Tenpyō-hōji (757-765)',
				'14' => 'Tenpyō-jingo (765-767)',
				'15' => 'Jingo-keiun (767-770)',
				'16' => 'Hōki (770–780)',
				'17' => 'Ten-ō (781-782)',
				'18' => 'Enryaku (782–806)',
				'19' => 'Daidō (806–810)',
				'20' => 'Kōnin (810–824)',
				'21' => 'Tenchō (824–834)',
				'22' => 'Jōwa (834–848)',
				'23' => 'Kajō (848–851)',
				'24' => 'Ninju (851–854)',
				'25' => 'Saikō (854–857)',
				'26' => 'Ten-an (857-859)',
				'27' => 'Jōgan (859–877)',
				'28' => 'Gangyō (877–885)',
				'29' => 'Ninna (885–889)',
				'30' => 'Kanpyō (889–898)',
				'31' => 'Shōtai (898–901)',
				'32' => 'Engi (901–923)',
				'33' => 'Enchō (923–931)',
				'34' => 'Jōhei (931–938)',
				'35' => 'Tengyō (938–947)',
				'36' => 'Tenryaku (947–957)',
				'37' => 'Tentoku (957–961)',
				'38' => 'Ōwa (961–964)',
				'39' => 'Kōhō (964–968)',
				'40' => 'Anna (968–970)',
				'41' => 'Tenroku (970–973)',
				'42' => 'Ten’en (973–976)',
				'43' => 'Jōgen (976–978)',
				'44' => 'Tengen (978–983)',
				'45' => 'Eikan (983–985)',
				'46' => 'Kanna (985–987)',
				'47' => 'Eien (987–989)',
				'48' => 'Eiso (989–990)',
				'49' => 'Shōryaku (990–995)',
				'50' => 'Chōtoku (995–999)',
				'51' => 'Chōhō (999–1004)',
				'52' => 'Kankō (1004–1012)',
				'53' => 'Chōwa (1012–1017)',
				'54' => 'Kannin (1017–1021)',
				'55' => 'Jian (1021–1024)',
				'56' => 'Manju (1024–1028)',
				'57' => 'Chōgen (1028–1037)',
				'58' => 'Chōryaku (1037–1040)',
				'59' => 'Chōkyū (1040–1044)',
				'60' => 'Kantoku (1044–1046)',
				'61' => 'Eishō (1046–1053)',
				'62' => 'Tengi (1053–1058)',
				'63' => 'Kōhei (1058–1065)',
				'64' => 'Jiryaku (1065–1069)',
				'65' => 'Enkyū (1069–1074)',
				'66' => 'Shōho (1074–1077)',
				'67' => 'Shōryaku (1077–1081)',
				'68' => 'Eihō (1081–1084)',
				'69' => 'Ōtoku (1084–1087)',
				'70' => 'Kanji (1087–1094)',
				'71' => 'Kahō (1094–1096)',
				'72' => 'Eichō (1096–1097)',
				'73' => 'Jōtoku (1097–1099)',
				'74' => 'Kōwa (1099–1104)',
				'75' => 'Chōji (1104–1106)',
				'76' => 'Kashō (1106–1108)',
				'77' => 'Tennin (1108–1110)',
				'78' => 'Ten-ei (1110-1113)',
				'79' => 'Eikyū (1113–1118)',
				'80' => 'Gen’ei (1118–1120)',
				'81' => 'Hōan (1120–1124)',
				'82' => 'Tenji (1124–1126)',
				'83' => 'Daiji (1126–1131)',
				'84' => 'Tenshō (1131–1132)',
				'85' => 'Chōshō (1132–1135)',
				'86' => 'Hōen (1135–1141)',
				'87' => 'Eiji (1141–1142)',
				'88' => 'Kōji (1142–1144)',
				'89' => 'Ten’yō (1144–1145)',
				'90' => 'Kyūan (1145–1151)',
				'91' => 'Ninpei (1151–1154)',
				'92' => 'Kyūju (1154–1156)',
				'93' => 'Hōgen (1156–1159)',
				'94' => 'Heiji (1159–1160)',
				'95' => 'Eiryaku (1160–1161)',
				'96' => 'Ōho (1161–1163)',
				'97' => 'Chōkan (1163–1165)',
				'98' => 'Eiman (1165–1166)',
				'99' => 'Nin’an (1166–1169)',
				'100' => 'Kaō (1169–1171)',
				'101' => 'Shōan (1171–1175)',
				'102' => 'Angen (1175–1177)',
				'103' => 'Jishō (1177–1181)',
				'104' => 'Yōwa (1181–1182)',
				'105' => 'Juei (1182–1184)',
				'106' => 'Genryaku (1184–1185)',
				'107' => 'Bunji (1185–1190)',
				'108' => 'Kenkyū (1190–1199)',
				'109' => 'Shōji (1199–1201)',
				'110' => 'Kennin (1201–1204)',
				'111' => 'Genkyū (1204–1206)',
				'112' => 'Ken’ei (1206–1207)',
				'113' => 'Jōgen (1207–1211)',
				'114' => 'Kenryaku (1211–1213)',
				'115' => 'Kenpō (1213–1219)',
				'116' => 'Jōkyū (1219–1222)',
				'117' => 'Jōō (1222–1224)',
				'118' => 'Gennin (1224–1225)',
				'119' => 'Karoku (1225–1227)',
				'120' => 'Antei (1227–1229)',
				'121' => 'Kanki (1229–1232)',
				'122' => 'Jōei (1232–1233)',
				'123' => 'Tenpuku (1233–1234)',
				'124' => 'Bunryaku (1234–1235)',
				'125' => 'Katei (1235–1238)',
				'126' => 'Ryakunin (1238–1239)',
				'127' => 'En-ō (1239-1240)',
				'128' => 'Ninji (1240–1243)',
				'129' => 'Kangen (1243–1247)',
				'130' => 'Hōji (1247–1249)',
				'131' => 'Kenchō (1249–1256)',
				'132' => 'Kōgen (1256–1257)',
				'133' => 'Shōka (1257–1259)',
				'134' => 'Shōgen (1259–1260)',
				'135' => 'Bun’ō (1260–1261)',
				'136' => 'Kōchō (1261–1264)',
				'137' => 'Bun’ei (1264–1275)',
				'138' => 'Kenji (1275–1278)',
				'139' => 'Kōan (1278–1288)',
				'140' => 'Shōō (1288–1293)',
				'141' => 'Einin (1293–1299)',
				'142' => 'Shōan (1299–1302)',
				'143' => 'Kengen (1302–1303)',
				'144' => 'Kagen (1303–1306)',
				'145' => 'Tokuji (1306–1308)',
				'146' => 'Enkyō (1308–1311)',
				'147' => 'Ōchō (1311–1312)',
				'148' => 'Shōwa (1312–1317)',
				'149' => 'Bunpō (1317–1319)',
				'150' => 'Genō (1319–1321)',
				'151' => 'Genkō (1321–1324)',
				'152' => 'Shōchū (1324–1326)',
				'153' => 'Karyaku (1326–1329)',
				'154' => 'Gentoku (1329–1331)',
				'155' => 'Genkō (1331–1334)',
				'156' => 'Kenmu (1334–1336)',
				'157' => 'Engen (1336–1340)',
				'158' => 'Kōkoku (1340–1346)',
				'159' => 'Shōhei (1346–1370)',
				'160' => 'Kentoku (1370–1372)',
				'161' => 'Bunchū (1372–1375)',
				'162' => 'Tenju (1375–1379)',
				'163' => 'Kōryaku (1379–1381)',
				'164' => 'Kōwa (1381–1384)',
				'165' => 'Genchū (1384–1392)',
				'166' => 'Meitoku (1384–1387)',
				'167' => 'Kakei (1387–1389)',
				'168' => 'Kōō (1389–1390)',
				'169' => 'Meitoku (1390–1394)',
				'170' => 'Ōei (1394–1428)',
				'171' => 'Shōchō (1428–1429)',
				'172' => 'Eikyō (1429–1441)',
				'173' => 'Kakitsu (1441–1444)',
				'174' => 'Bun’an (1444–1449)',
				'175' => 'Hōtoku (1449–1452)',
				'176' => 'Kyōtoku (1452–1455)',
				'177' => 'Kōshō (1455–1457)',
				'178' => 'Chōroku (1457–1460)',
				'179' => 'Kanshō (1460–1466)',
				'180' => 'Bunshō (1466–1467)',
				'181' => 'Ōnin (1467–1469)',
				'182' => 'Bunmei (1469–1487)',
				'183' => 'Chōkyō (1487–1489)',
				'184' => 'Entoku (1489–1492)',
				'185' => 'Meiō (1492–1501)',
				'186' => 'Bunki (1501–1504)',
				'187' => 'Eishō (1504–1521)',
				'188' => 'Taiei (1521–1528)',
				'189' => 'Kyōroku (1528–1532)',
				'190' => 'Tenbun (1532–1555)',
				'191' => 'Kōji (1555–1558)',
				'192' => 'Eiroku (1558–1570)',
				'193' => 'Genki (1570–1573)',
				'194' => 'Tenshō (1573–1592)',
				'195' => 'Bunroku (1592–1596)',
				'196' => 'Keichō (1596–1615)',
				'197' => 'Genna (1615–1624)',
				'198' => 'Kan’ei (1624–1644)',
				'199' => 'Shōho (1644–1648)',
				'200' => 'Keian (1648–1652)',
				'201' => 'Jōō (1652–1655)',
				'202' => 'Meireki (1655–1658)',
				'203' => 'Manji (1658–1661)',
				'204' => 'Kanbun (1661–1673)',
				'205' => 'Enpō (1673–1681)',
				'206' => 'Tenna (1681–1684)',
				'207' => 'Jōkyō (1684–1688)',
				'208' => 'Genroku (1688–1704)',
				'209' => 'Hōei (1704–1711)',
				'210' => 'Shōtoku (1711–1716)',
				'211' => 'Kyōhō (1716–1736)',
				'212' => 'Genbun (1736–1741)',
				'213' => 'Kanpō (1741–1744)',
				'214' => 'Enkyō (1744–1748)',
				'215' => 'Kan’en (1748–1751)',
				'216' => 'Hōreki (1751–1764)',
				'217' => 'Meiwa (1764–1772)',
				'218' => 'An’ei (1772–1781)',
				'219' => 'Tenmei (1781–1789)',
				'220' => 'Kansei (1789–1801)',
				'221' => 'Kyōwa (1801–1804)',
				'222' => 'Bunka (1804–1818)',
				'223' => 'Bunsei (1818–1830)',
				'224' => 'Tenpō (1830–1844)',
				'225' => 'Kōka (1844–1848)',
				'226' => 'Kaei (1848–1854)',
				'227' => 'Ansei (1854–1860)',
				'228' => 'Man’en (1860–1861)',
				'229' => 'Bunkyū (1861–1864)',
				'230' => 'Genji (1864–1865)',
				'231' => 'Keiō (1865–1868)',
				'232' => 'Meiji',
				'233' => 'Taishō',
				'234' => 'era Shōwa',
				'235' => 'Heisei'
			},
		},
		'persian' => {
		},
		'roc' => {
			abbreviated => {
				'0' => 'A.R.D.C.',
				'1' => 'Minguo'
			},
			narrow => {
				'0' => 'A.R.D.C.',
				'1' => 'Minguo'
			},
			wide => {
				'0' => 'antes de la R.D.C.',
				'1' => 'Minguo'
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
			'full' => q{EEEE, dd MMMM 'de' y G},
			'long' => q{d MMMM 'de' y G},
			'medium' => q{d MMM y G},
			'short' => q{d/M/yy GGGGG},
		},
		'chinese' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE, dd MMMM 'de' y G},
			'long' => q{d MMMM 'de' y G},
			'medium' => q{d MMM y G},
			'short' => q{d/M/yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM 'de' y},
			'long' => q{d MMMM 'de' y},
			'medium' => q{d MMM y},
			'short' => q{d/M/yy},
		},
		'hebrew' => {
		},
		'indian' => {
			'full' => q{EEEE, dd MMMM 'de' y G},
			'long' => q{d MMMM 'de' y G},
			'medium' => q{d MMM y G},
			'short' => q{d/M/yy GGGGG},
		},
		'islamic' => {
			'full' => q{EEEE, dd MMMM 'de' y G},
			'long' => q{d MMMM 'de' y G},
			'medium' => q{d MMM y G},
			'short' => q{d/M/yy GGGGG},
		},
		'japanese' => {
		},
		'persian' => {
		},
		'roc' => {
			'full' => q{EEEE, dd MMMM 'de' y G},
			'long' => q{d MMMM 'de' y G},
			'medium' => q{d MMM y G},
			'short' => q{d/M/yy GGGGG},
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
		'dangi' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
		},
		'japanese' => {
		},
		'persian' => {
		},
		'roc' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
			'full' => q{{1} 'a' 'les' {0}},
			'long' => q{{1} 'a' 'les' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'chinese' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{{1} 'a' 'les' {0}},
			'long' => q{{1} 'a' 'les' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'a' 'les' {0}},
			'long' => q{{1} 'a' 'les' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1} {0}},
		},
		'hebrew' => {
		},
		'indian' => {
			'full' => q{{1} 'a' 'les' {0}},
			'long' => q{{1} 'a' 'les' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1} {0}},
		},
		'islamic' => {
			'full' => q{{1} 'a' 'les' {0}},
			'long' => q{{1} 'a' 'les' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1} {0}},
		},
		'japanese' => {
			'full' => q{{1} 'a' 'les' {0}},
			'long' => q{{1} 'a' 'les' {0}},
			'medium' => q{{1}, {0}},
		},
		'persian' => {
		},
		'roc' => {
			'full' => q{{1} 'a' 'les' {0}},
			'long' => q{{1} 'a' 'les' {0}},
			'medium' => q{{1}, {0}},
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
			E => q{ccc},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM 'de' y G},
			GyMMMd => q{d MMM 'de' y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMd => q{d 'de' MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y G},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM 'de' y G},
			yyyyMMMM => q{MMMM 'de' y G},
			yyyyMMMd => q{d MMM 'de' y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			E => q{ccc},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMW => q{'selmana' W 'de' MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
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
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{LLLL 'de' y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ 'de' y},
			yw => q{'selmana' w 'de' Y},
		},
		'buddhist' => {
			E => q{ccc},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM 'de' y G},
			GyMMMd => q{d MMM 'de' y G},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMd => q{d 'de' MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			y => q{y G},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yyyy => q{y G},
			yyyyM => q{M/y GGGG},
			yyyyMEd => q{E, d/M/y GGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM 'de' y G},
			yyyyMMMM => q{MMMM 'de' y G},
			yyyyMMMd => q{d MMM 'de' y G},
			yyyyMd => q{d/M/y GGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ 'de' y G},
		},
		'japanese' => {
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM 'de' y G},
			GyMMMd => q{d MMM 'de' y G},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{y-MM GGGGG},
			yyyyMEd => q{E, d-M-y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM 'de' y G},
			yyyyMMMd => q{d MMM 'de' y G},
			yyyyMd => q{dd-MM-y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'roc' => {
			E => q{ccc},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM 'de' y G},
			GyMMMd => q{d MMM 'de' y G},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMd => q{d 'de' MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			y => q{y G},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM 'de' y G},
			yyyyMMMM => q{MMMM 'de' y G},
			yyyyMMMd => q{d MMM 'de' y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'islamic' => {
			E => q{ccc},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM 'de' y G},
			GyMMMd => q{d MMM 'de' y G},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMd => q{d 'de' MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			y => q{y G},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM 'de' y G},
			yyyyMMMM => q{MMMM 'de' y G},
			yyyyMMMd => q{d MMM 'de' y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'indian' => {
			E => q{ccc},
			Ed => q{E d},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM 'de' y G},
			GyMMMd => q{d MMM 'de' y G},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMd => q{d 'de' MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			d => q{d},
			y => q{y G},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM 'de' y G},
			yyyyMMMM => q{MMMM 'de' y G},
			yyyyMMMd => q{d MMM 'de' y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
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
				M => q{M – M},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd – E, dd/MM},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d/MM – d/MM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd – dd/MM},
			},
			d => {
				d => q{d – d},
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
				y => q{y – y G},
			},
			yM => {
				M => q{MM – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			yMMM => {
				M => q{LLL – LLL y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{LLLL – LLLL 'de' y G},
				y => q{LLLL y – LLLL y},
			},
			yMMMd => {
				M => q{d MMM – d MMM 'de' y G},
				d => q{d – d MMM 'de' y G},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'gregorian' => {
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd – E, dd/MM},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d/MM – d/MM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd – dd/MM},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{MM – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM 'de' y},
				d => q{E, d MMM – E, d MMM 'de' y},
				y => q{E, d MMM 'de' y – E, d MMM 'de' y},
			},
			yMMMM => {
				M => q{LLLL – LLLL 'de' y},
				y => q{LLLL 'de' y – LLLL 'de' y},
			},
			yMMMd => {
				M => q{d MMM – d MMM 'de' y},
				d => q{d – d MMM 'de' y},
				y => q{d MMM 'de' y – d MMM 'de' y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
		'ethiopic' => {
			M => {
				M => q{M – M},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			d => {
				d => q{d – d},
			},
			y => {
				y => q{y – y G},
			},
			yMMM => {
				M => q{LLL – LLL y G},
			},
			yMMMM => {
				M => q{LLLL – LLLL y G},
			},
			yMMMd => {
				d => q{d – d MMM 'de' y},
			},
		},
		'buddhist' => {
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd – E, dd/MM},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd – dd/MM},
			},
			d => {
				d => q{d – d},
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
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{M/y – M/y GGGG},
				y => q{M/y – M/y GGGG},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y GGGG},
				d => q{E, d/M/y – E, d/M/y GGGG},
				y => q{E, d/M/y – E, d/M/y GGGG},
			},
			yMMM => {
				M => q{LLL – LLL y G},
				y => q{LLL y – LLL y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{LLLL – LLLL 'de' y G},
				y => q{LLLL 'de' y – LLLL 'de' y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM 'de' y G},
				d => q{d – d MMM 'de' y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGG},
				d => q{d/M/y – d/M/y GGGG},
				y => q{d/M/y – d/M/y GGGG},
			},
		},
		'japanese' => {
			M => {
				M => q{M – M},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			d => {
				d => q{d – d},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{MM – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			yMMM => {
				M => q{LLL – LLL y G},
				y => q{MMM y – MMM y G},
			},
			yMMMM => {
				M => q{LLLL – LLLL y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM 'de' y G},
				d => q{d – d MMM 'de' y},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'roc' => {
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
				M => q{M – M},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd – E, dd/MM},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d/MM – d/MM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd – dd/MM},
			},
			d => {
				d => q{d – d},
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
				y => q{y – y G},
			},
			yM => {
				M => q{MM – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			yMMM => {
				M => q{LLL – LLL y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{LLLL – LLLL 'de' y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM 'de' y G},
				d => q{d – d MMM 'de' y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'persian' => {
			M => {
				M => q{M – M},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			d => {
				d => q{d – d},
			},
			y => {
				y => q{y – y G},
			},
			yMMM => {
				M => q{LLL – LLL y G},
			},
			yMMMd => {
				d => q{d – d MMM 'de' y},
			},
		},
		'islamic' => {
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
				M => q{M – M},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd – E, dd/MM},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d/MM – d/MM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd – dd/MM},
			},
			d => {
				d => q{d – d},
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
				y => q{y – y G},
			},
			yM => {
				M => q{MM – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			yMMM => {
				M => q{LLL – LLL y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{LLLL – LLLL 'de' y G},
				y => q{LLLL y – LLLL y},
			},
			yMMMd => {
				M => q{d MMM – d MMM 'de' y G},
				d => q{d – d MMM 'de' y G},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'indian' => {
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
				M => q{M – M},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd – E, dd/MM},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d/MM – d/MM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd – dd/MM},
			},
			d => {
				d => q{d – d},
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
				y => q{y – y G},
			},
			yM => {
				M => q{MM – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			yMMM => {
				M => q{LLL – LLL y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{LLLL – LLLL 'de' y G},
				y => q{LLLL y – LLLL y},
			},
			yMMMd => {
				M => q{d MMM – d MMM 'de' y G},
				d => q{d – d MMM 'de' y G},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
	} },
);

has 'month_patterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			'format' => {
				'abbreviated' => {
					'leap' => q{{0}bis},
				},
				'narrow' => {
					'leap' => q{{0}b},
				},
				'wide' => {
					'leap' => q{{0} bisiestu},
				},
			},
			'numeric' => {
				'all' => {
					'leap' => q{{0} bis},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'leap' => q{{0}bis},
				},
				'narrow' => {
					'leap' => q{{0}b},
				},
				'wide' => {
					'leap' => q{{0} bisiestu},
				},
			},
		},
	} },
);

has 'cyclic_name_sets' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			'dayParts' => {
				'format' => {
					'abbreviated' => {
						0 => q(ratu),
						1 => q(güe),
						2 => q(tigre),
						3 => q(conexu),
						4 => q(dragón),
						5 => q(culebra),
						6 => q(caballu),
						7 => q(cabra),
						8 => q(monu),
						9 => q(gallu),
						10 => q(perru),
						11 => q(gochu),
					},
					'narrow' => {
						0 => q(ratu),
						1 => q(güe),
						2 => q(tigre),
						3 => q(conexu),
						4 => q(dragón),
						5 => q(culebra),
						6 => q(caballu),
						7 => q(cabra),
						8 => q(monu),
						9 => q(gallu),
						10 => q(perru),
						11 => q(gochu),
					},
					'wide' => {
						0 => q(ratu),
						1 => q(güe),
						2 => q(tigre),
						3 => q(conexu),
						4 => q(dragón),
						5 => q(culebra),
						6 => q(caballu),
						7 => q(cabra),
						8 => q(monu),
						9 => q(gallu),
						10 => q(perru),
						11 => q(gochu),
					},
				},
			},
			'days' => {
				'format' => {
					'wide' => {
						0 => q(ratu de madera yang),
						1 => q(güe de madera yin),
						2 => q(tigre de fueu yang),
						3 => q(conexu de fueu yin),
						4 => q(dragón de tierra yang),
						5 => q(culebra de tierra yin),
						6 => q(caballu de metal yang),
						7 => q(cabra de metal yin),
						8 => q(monu d’agua yang),
						9 => q(gallu d’agua yin),
						10 => q(perru de madera yang),
						11 => q(gochu de madera yin),
						12 => q(ratu de fueu yang),
						13 => q(güe de fueu yin),
						14 => q(tigre de tierra yang),
						15 => q(conexu de tierra yin),
						16 => q(dragón de metal yang),
						17 => q(culebra de metal yin),
						18 => q(caballu d’agua yang),
						19 => q(cabra d’agua yin),
						20 => q(monu de madera yang),
						21 => q(gallu de madera yin),
						22 => q(perru de fueu yang),
						23 => q(gochu de fueu yin),
						24 => q(ratu de tierra yang),
						25 => q(güe de tierra yin),
						26 => q(tigre de metal yang),
						27 => q(conexu de metal yin),
						28 => q(dragón d’agua yang),
						29 => q(culebra d’agua yin),
						30 => q(caballu de madera yang),
						31 => q(cabra de madera yin),
						32 => q(monu de fueu yang),
						33 => q(gallu de fueu yin),
						34 => q(perru de tierra yang),
						35 => q(gochu de tierra yin),
						36 => q(ratu de metal yang),
						37 => q(güe de metal yin),
						38 => q(tigre d’agua yang),
						39 => q(conexu d’agua yin),
						40 => q(dragón de madera yang),
						41 => q(culebra de madera yin),
						42 => q(caballu de fueu yang),
						43 => q(cabra de fueu yin),
						44 => q(monu de tierra yang),
						45 => q(gallu de tierra yin),
						46 => q(perru de metal yang),
						47 => q(gochu de metal yin),
						48 => q(rata d’agua yang),
						49 => q(güe d’agua yin),
						50 => q(tigre de madera yang),
						51 => q(conexu de madera yin),
						52 => q(dragón de fueu yang),
						53 => q(culebra de fueu yin),
						54 => q(caballu de tierra yang),
						55 => q(cabra de tierra yin),
						56 => q(monu de metal yang),
						57 => q(gallu de metal yin),
						58 => q(perru d’agua yang),
						59 => q(gochu d’agua yin),
					},
				},
			},
			'solarTerms' => {
				'format' => {
					'wide' => {
						0 => q(principia la primavera),
						1 => q(agua de lluvia),
						2 => q(esconsoñen los inseutos),
						3 => q(equinocciu de primavera),
						4 => q(brillante y claro),
						5 => q(lluvia del granu),
						6 => q(principia’l branu),
						7 => q(granu completu),
						8 => q(granu n’espiga),
						9 => q(solsticiu braniegu),
						10 => q(pequeña calor),
						11 => q(gran calor),
						12 => q(principia la seronda),
						13 => q(fin de la calor),
						14 => q(rosada blanca),
						15 => q(equinocciu serondiegu),
						16 => q(rosada fría),
						17 => q(descende’l xelu),
						18 => q(principia l’iviernu),
						19 => q(pequeña ñeve),
						20 => q(gran ñeve),
						21 => q(solsticiu d’iviernu),
						22 => q(pequeñu fríu),
						23 => q(gran fríu),
					},
				},
			},
			'years' => {
				'format' => {
					'wide' => {
						0 => q(ratu de madera yang),
						1 => q(güe de madera yin),
						2 => q(tigre de fueu yang),
						3 => q(conexu de fueu yin),
						4 => q(dragón de tierra yang),
						5 => q(culebra de tierra yin),
						6 => q(caballu de metal yang),
						7 => q(cabra de metal yin),
						8 => q(monu d’agua yang),
						9 => q(gallu d’agua yin),
						10 => q(perru de madera yang),
						11 => q(gochu de madera yin),
						12 => q(ratu de fueu yang),
						13 => q(güe de fueu yin),
						14 => q(tigre de tierra yang),
						15 => q(conexu de tierra yin),
						16 => q(dragón de metal yang),
						17 => q(culebra de metal yin),
						18 => q(caballu d’agua yang),
						19 => q(cabra d’agua yin),
						20 => q(monu de madera yang),
						21 => q(gallu de madera yin),
						22 => q(perru de fueu yang),
						23 => q(gochu de fueu yin),
						24 => q(ratu de tierra yang),
						25 => q(güe de tierra yin),
						26 => q(tigre de metal yang),
						27 => q(conexu de metal yin),
						28 => q(dragón d’agua yang),
						29 => q(culebra d’agua yin),
						30 => q(caballu de madera yang),
						31 => q(cabra de madera yin),
						32 => q(monu de fueu yang),
						33 => q(gallu de fueu yin),
						34 => q(perru de tierra yang),
						35 => q(gochu de tierra yin),
						36 => q(ratu de metal yang),
						37 => q(güe de metal yin),
						38 => q(tigre d’agua yang),
						39 => q(conexu d’agua yin),
						40 => q(dragón de madera yang),
						41 => q(culebra de madera yin),
						42 => q(caballu de fueu yang),
						43 => q(cabra de fueu yin),
						44 => q(monu de tierra yang),
						45 => q(gallu de tierra yin),
						46 => q(perru de metal yang),
						47 => q(gochu de metal yin),
						48 => q(rata d’agua yang),
						49 => q(güe d’agua yin),
						50 => q(tigre de madera yang),
						51 => q(conexu de madera yin),
						52 => q(dragón de fueu yang),
						53 => q(culebra de fueu yin),
						54 => q(caballu de tierra yang),
						55 => q(cabra de tierra yin),
						56 => q(monu de metal yang),
						57 => q(gallu de metal yin),
						58 => q(perru d’agua yang),
						59 => q(gochu d’agua yin),
					},
				},
			},
			'zodiacs' => {
				'format' => {
					'abbreviated' => {
						0 => q(ratu),
						1 => q(güe),
						2 => q(tigre),
						3 => q(conexu),
						4 => q(dragón),
						5 => q(culebra),
						6 => q(caballu),
						7 => q(cabra),
						8 => q(monu),
						9 => q(gallu),
						10 => q(perru),
						11 => q(gochu),
					},
					'narrow' => {
						0 => q(rat),
						1 => q(güe),
						2 => q(tig),
						3 => q(con),
						4 => q(dra),
						5 => q(cul),
						6 => q(cbl),
						7 => q(cbr),
						8 => q(mon),
						9 => q(gal),
						10 => q(per),
						11 => q(gch),
					},
					'wide' => {
						0 => q(Ratu),
						1 => q(Güe),
						2 => q(Tigre),
						3 => q(Conexu),
						4 => q(Dragón),
						5 => q(Culebra),
						6 => q(Caballu),
						7 => q(Cabra),
						8 => q(Monu),
						9 => q(Gallu),
						10 => q(Perru),
						11 => q(Gochu),
					},
				},
			},
		},
		'dangi' => {
			'dayParts' => {
				'format' => {
					'abbreviated' => {
						0 => q(ratu),
						1 => q(güe),
						2 => q(tigre),
						3 => q(conexu),
						4 => q(dragón),
						5 => q(culebra),
						6 => q(caballu),
						7 => q(cabra),
						8 => q(monu),
						9 => q(gallu),
						10 => q(perru),
						11 => q(gochu),
					},
					'wide' => {
						0 => q(ratu),
						1 => q(güe),
						2 => q(tigre),
						3 => q(conexu),
						4 => q(dragón),
						5 => q(culebra),
						6 => q(caballu),
						7 => q(cabra),
						8 => q(monu),
						9 => q(gallu),
						10 => q(perru),
						11 => q(gochu),
					},
				},
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
		regionFormat => q(Hora de {0}),
		regionFormat => q(Hora braniega de {0}),
		regionFormat => q(Hora estándar de {0}),
		fallbackFormat => q({1} ({0})),
		'Acre' => {
			long => {
				'daylight' => q#hora braniega d’Acre#,
				'generic' => q#hora d’Acre#,
				'standard' => q#hora estándar d’Acre#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Hora d’Afganistán#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Accra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Adís Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Arxel#,
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
			exemplarCity => q#El Cairu#,
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
			exemplarCity => q#Xibuti#,
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
			exemplarCity => q#Johannesburgu#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Ḥartum#,
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
			exemplarCity => q#Lomé#,
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
			exemplarCity => q#Mogadixu#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovia#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Xamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niaméi#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nuakxot#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Uagadugú#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto-Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Santu Tomé#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Trípoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Túnez#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Hora d’África central#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Hora d’África del este#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Hora de Sudáfrica#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Hora braniega d’África del oeste#,
				'generic' => q#Hora d’África del oeste#,
				'standard' => q#Hora estándar d’África del oeste#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Hora braniega d’Alaska#,
				'generic' => q#Hora d’Alaska#,
				'standard' => q#Hora estándar d’Alaska#,
			},
			short => {
				'daylight' => q#AKDT#,
				'generic' => q#AKT#,
				'standard' => q#AKST#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#hora braniega d’Almaty#,
				'generic' => q#Hora d’Almaty#,
				'standard' => q#hora estándar d’Almaty#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Hora braniega del Amazonas#,
				'generic' => q#Hora del Amazonas#,
				'standard' => q#Hora estándar del Amazonas#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Anchorage#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguila#,
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
			exemplarCity => q#Tucumán#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaia#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahía#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahía Banderas#,
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
			exemplarCity => q#Bogotá#,
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
			exemplarCity => q#Cancún#,
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
			exemplarCity => q#Caimán#,
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
			exemplarCity => q#Córdoba#,
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
			exemplarCity => q#Curaçao#,
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
			exemplarCity => q#Granada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadalupe#,
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
			exemplarCity => q#La Habana#,
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
			exemplarCity => q#Xamaica#,
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
			exemplarCity => q#La Martinica#,
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
			exemplarCity => q#Mérida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Ciudá de Méxicu#,
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
			exemplarCity => q#Nueva York#,
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
			exemplarCity => q#Beulah, Dakota del Norte#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Dakota del Norte#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Nueva Salem, Dakota del Norte#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ojinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#Panamá#,
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
			exemplarCity => q#Puertu Príncipe#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Puertu España#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Porto Velho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puertu Ricu#,
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
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarem#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santu Domingu#,
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
			exemplarCity => q#Tórtola#,
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
		'America_Central' => {
			long => {
				'daylight' => q#Hora braniega central norteamericana#,
				'generic' => q#Hora central norteamericana#,
				'standard' => q#Hora estándar central norteamericana#,
			},
			short => {
				'daylight' => q#CDT#,
				'generic' => q#CT#,
				'standard' => q#CST#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Hora braniega del este norteamericanu#,
				'generic' => q#Hora del este norteamericanu#,
				'standard' => q#Hora estándar del este norteamericanu#,
			},
			short => {
				'daylight' => q#EDT#,
				'generic' => q#ET#,
				'standard' => q#EST#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Hora braniega de les montañes norteamericanes#,
				'generic' => q#Hora de les montañes norteamericanes#,
				'standard' => q#Hora estándar de les montañes norteamericanes#,
			},
			short => {
				'daylight' => q#MDT#,
				'generic' => q#MT#,
				'standard' => q#MST#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Hora braniega del Pacíficu norteamericanu#,
				'generic' => q#Hora del Pacíficu norteamericanu#,
				'standard' => q#Hora estándar del Pacíficu norteamericanu#,
			},
			short => {
				'daylight' => q#PDT#,
				'generic' => q#PT#,
				'standard' => q#PST#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#hora braniega d’Anadyr#,
				'generic' => q#hora d’Anadyr#,
				'standard' => q#hora estándar d’Anadyr#,
			},
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
		'Apia' => {
			long => {
				'daylight' => q#Hora braniega d’Apia#,
				'generic' => q#Hora d’Apia#,
				'standard' => q#Hora estándar d’Apia#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Hora braniega d’Aqtau#,
				'generic' => q#Hora d’Aqtau#,
				'standard' => q#Hora estándar d’Aqtau#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Hora braniega d’Aqtobe#,
				'generic' => q#Hora d’Aqtobe#,
				'standard' => q#Hora estándar d’Aqtobe#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Hora braniega d’Arabia#,
				'generic' => q#Hora d’Arabia#,
				'standard' => q#Hora estándar d’Arabia#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Hora braniega d’Arxentina#,
				'generic' => q#Hora d’Arxentina#,
				'standard' => q#Hora estándar d’Arxentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Hora braniega occidental d’Arxentina#,
				'generic' => q#Hora occidental d’Arxentina#,
				'standard' => q#Hora estándar occidental d’Arxentina#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Hora braniega d’Armenia#,
				'generic' => q#Hora d’Armenia#,
				'standard' => q#Hora estándar d’Armenia#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Aden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almaty#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amán#,
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
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdag#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Baḥréin#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Bakú#,
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
			exemplarCity => q#Brunéi#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Calcuta#,
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
			exemplarCity => q#Damascu#,
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
			exemplarCity => q#Duxanbé#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gaza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebrón#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Ḥong Kong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Xakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Xayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Xerusalén#,
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
			exemplarCity => q#Katmandú#,
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
			exemplarCity => q#Macáu#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadán#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makassar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manila#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Mascate#,
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
			exemplarCity => q#Pyong Yang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Qatar#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Qyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangún#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ciudá de Ho Chi Minh#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Saxalín#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarcanda#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seúl#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shanghai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
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
			exemplarCity => q#Teḥrán#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokiu#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulán Bátor#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumqi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vientián#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Yekaterimburgu#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yerevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Hora braniega del Atlánticu#,
				'generic' => q#Hora del Atlánticu#,
				'standard' => q#Hora estándar del Atlánticu#,
			},
			short => {
				'daylight' => q#ADT#,
				'generic' => q#AT#,
				'standard' => q#AST#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Les Azores#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canaries#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cabu Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Islles Feroe#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reikiavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Xeorxa del Sur#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Santa Lena#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stanley#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaida#,
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
		'Australia_Central' => {
			long => {
				'daylight' => q#Hora braniega d’Australia central#,
				'generic' => q#Hora d’Australia central#,
				'standard' => q#Hora estándar d’Australia central#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Hora braniega d’Australia central del oeste#,
				'generic' => q#Hora d’Australia central del oeste#,
				'standard' => q#Hora estándar d’Australia central del oeste#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Hora braniega d’Australia del este#,
				'generic' => q#Hora d’Australia del este#,
				'standard' => q#Hora estándar d’Australia del este#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Hora braniega d’Australia del oeste#,
				'generic' => q#Hora d’Australia del oeste#,
				'standard' => q#Hora estándar d’Australia del oeste#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Hora braniega d’Azerbaixán#,
				'generic' => q#Hora d’Azerbaixán#,
				'standard' => q#Hora estándar d’Azerbaixán#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Hora braniega de Les Azores#,
				'generic' => q#Hora de les Azores#,
				'standard' => q#Hora estándar de les Azores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Hora braniega de Bangladex#,
				'generic' => q#Hora de Bangladex#,
				'standard' => q#Hora estándar de Bangladex#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Hora de Bután#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Hora de Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Hora braniega de Brasilia#,
				'generic' => q#Hora de Brasilia#,
				'standard' => q#Hora estándar de Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Hora de Brunéi Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Hora braniega de Cabu Verde#,
				'generic' => q#Hora de Cabu Verde#,
				'standard' => q#Hora estándar de Cabu Verde#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#Hora de Casey#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Hora estándar de Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Hora braniega de Chatham#,
				'generic' => q#Hora de Chatham#,
				'standard' => q#Hora estándar de Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Hora braniega de Chile#,
				'generic' => q#Hora de Chile#,
				'standard' => q#Hora estándar de Chile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Hora braniega de China#,
				'generic' => q#Hora de China#,
				'standard' => q#Hora estándar de China#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Hora braniega de Choibalsan#,
				'generic' => q#Hora de Choibalsan#,
				'standard' => q#Hora estándar de Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Hora estándar de la Islla Christmas#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Hora de les Islles Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Hora braniega de Colombia#,
				'generic' => q#Hora de Colombia#,
				'standard' => q#Hora estándar de Colombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Hora media braniega de les Islles Cook#,
				'generic' => q#Hora de les Islles Cook#,
				'standard' => q#Hora estándar de les Islles Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Hora braniega de Cuba#,
				'generic' => q#Hora de Cuba#,
				'standard' => q#Hora estándar de Cuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Hora de Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Hora de Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Hora de Timor Oriental#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Hora braniega de la Islla de Pascua#,
				'generic' => q#Hora de la Islla de Pascua#,
				'standard' => q#Hora estándar de la Islla de Pascua#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Hora d’Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Hora coordinada universal#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Ciudá desconocida#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astracán#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atenes#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgráu#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlín#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruxeles#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucarest#,
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
			exemplarCity => q#Copenhague#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublín#,
			long => {
				'daylight' => q#Hora estándar irlandesa#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Xibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernsey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Ḥélsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Islla de Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersey#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningráu#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirov#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisboa#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Liubliana#,
		},
		'Europe/London' => {
			exemplarCity => q#Londres#,
			long => {
				'daylight' => q#Hora braniega británica#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburgu#,
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
			exemplarCity => q#Mónacu#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moscú#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#París#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorica#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marín#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarajevo#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferopol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofía#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Estocolmu#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallinn#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
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
			exemplarCity => q#El Vaticanu#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viena#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgográu#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsovia#,
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
		'Europe_Central' => {
			long => {
				'daylight' => q#Hora braniega d’Europa Central#,
				'generic' => q#Hora d’Europa Central#,
				'standard' => q#Hora estándar d’Europa Central#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Hora braniega d’Europa del Este#,
				'generic' => q#Hora d’Europa del Este#,
				'standard' => q#Hora estándar d’Europa del Este#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Hora d’Europa del estremu este#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Hora braniega d’Europa Occidental#,
				'generic' => q#Hora d’Europa Occidental#,
				'standard' => q#Hora estándar d’Europa Occidental#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Hora braniega de les Islles Falkland#,
				'generic' => q#Hora de les Islles Falkland#,
				'standard' => q#Hora estándar de les Islles Falkland#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Hora braniega de Fixi#,
				'generic' => q#Hora de Fixi#,
				'standard' => q#Hora estándar de Fixi#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Hora de La Guyana Francesa#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Hora del sur y l’antárticu francés#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Hora media de Greenwich#,
			},
			short => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Hora de Galápagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Hora de Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Hora braniega de Xeorxa#,
				'generic' => q#Hora de Xeorxa#,
				'standard' => q#Hora estándar de Xeorxa#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Hora de les Islles Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Hora braniega de Groenlandia oriental#,
				'generic' => q#Hora de Groenlandia oriental#,
				'standard' => q#Hora estándar de Groenlandia oriental#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Hora braniega de Groenlandia occidental#,
				'generic' => q#Hora de Groenlandia occidental#,
				'standard' => q#Hora estándar de Groenlandia occidental#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Hora estándar de Guam#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Hora estándar del Golfu#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Hora de La Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hora braniega de Hawaii-Aleutianes#,
				'generic' => q#Hora de Hawaii-Aleutianes#,
				'standard' => q#Hora estándar de Hawaii-Aleutianes#,
			},
			short => {
				'daylight' => q#HADT#,
				'generic' => q#HAT#,
				'standard' => q#HAST#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hora braniega de Ḥong Kong#,
				'generic' => q#Hora de Ḥong Kong#,
				'standard' => q#Hora estándar de Ḥong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hora braniega de Hovd#,
				'generic' => q#Hora de Hovd#,
				'standard' => q#Hora estándar de Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Hora estándar de la India#,
			},
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
			exemplarCity => q#Mauriciu#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunión#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Hora del Océanu Índicu#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Hora d’Indochina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Hora d’Indonesia central#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Hora d’Indonesia del este#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Hora d’Indonesia del oeste#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Hora braniega d’Irán#,
				'generic' => q#Hora d’Irán#,
				'standard' => q#Hora estándar d’Irán#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Hora braniega d’Irkutsk#,
				'generic' => q#Hora d’Irkutsk#,
				'standard' => q#Hora estándar d’Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Hora braniega d’Israel#,
				'generic' => q#Hora d’Israel#,
				'standard' => q#Hora estándar d’Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Hora braniega de Xapón#,
				'generic' => q#Hora de Xapón#,
				'standard' => q#Hora estándar de Xapón#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#hora braniega de Petropavlovsk-Kamchatski#,
				'generic' => q#hora de Petropavlovsk-Kamchatski#,
				'standard' => q#hora estandar de Petropavlovsk-Kamchatski#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Hora del Kazakstán oriental#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Hora del Kazakstán occidental#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Hora braniega de Corea#,
				'generic' => q#Hora de Corea#,
				'standard' => q#Hora estándar de Corea#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Hora de Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Hora braniega de Krasnoyarsk#,
				'generic' => q#Hora de Krasnoyarsk#,
				'standard' => q#Hora estándar de Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Hora del Kirguistán#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Hora de Lanka#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Hora de les Islles Line#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Hora braniega de Lord Howe#,
				'generic' => q#Hora de Lord Howe#,
				'standard' => q#Hora estándar de Lord Howe#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Hora braniega de Macáu#,
				'generic' => q#Hora de Macáu#,
				'standard' => q#Hora estándar de Macáu#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Hora de la Islla Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Hora braniega de Magadán#,
				'generic' => q#Hora de Magadán#,
				'standard' => q#Hora estándar de Magadán#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Hora de Malasia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Hora de Les Maldives#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Hora de les Marqueses#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Hora de les Islles Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Hora braniega de Mauriciu#,
				'generic' => q#Hora de Mauriciu#,
				'standard' => q#Hora estándar de Mauriciu#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Hora de Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Hora braniega del noroeste de Méxicu#,
				'generic' => q#Hora del noroeste de Méxicu#,
				'standard' => q#Hora estándar del noroeste de Méxicu#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Hora braniega del Pacíficu de Méxicu#,
				'generic' => q#Hora del Pacíficu de Méxicu#,
				'standard' => q#Hora estándar del Pacíficu de Méxicu#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Hora braniega d’Ulán Bátor#,
				'generic' => q#Hora d’Ulán Bátor#,
				'standard' => q#Hora estándar d’Ulán Bátor#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Hora braniega de Moscú#,
				'generic' => q#Hora de Moscú#,
				'standard' => q#Hora estándar de Moscú#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Hora de Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Hora de Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Hora del Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Hora braniega de Nueva Caledonia#,
				'generic' => q#Hora de Nueva Caledonia#,
				'standard' => q#Hora estándar de Nueva Caledonia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Hora braniega de Nueva Zelanda#,
				'generic' => q#Hora de Nueva Zelanda#,
				'standard' => q#Hora estándar de Nueva Zelanda#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Hora braniega de Newfoundland#,
				'generic' => q#Hora de Newfoundland#,
				'standard' => q#Hora estándar de Newfoundland#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Hora de Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#Hora de la Islla Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Hora braniega de Fernando de Noronha#,
				'generic' => q#Hora de Fernando de Noronha#,
				'standard' => q#Hora estándar de Fernando de Noronha#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Hora de les Islles Marianes del Norte#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Hora braniega de Novosibirsk#,
				'generic' => q#Hora de Novosibirsk#,
				'standard' => q#Hora estándar de Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Hora braniega d’Omsk#,
				'generic' => q#Hora d’Omsk#,
				'standard' => q#Hora estándar d’Omsk#,
			},
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
			exemplarCity => q#Pascua#,
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
			exemplarCity => q#Fixi#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galápagos#,
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
			short => {
				'daylight' => q#HDT#,
				'generic' => q#HST#,
				'standard' => q#HST#,
			},
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Johnston#,
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
		'Pakistan' => {
			long => {
				'daylight' => q#Hora braniega del Paquistán#,
				'generic' => q#Hora del Paquistán#,
				'standard' => q#Hora estándar del Paquistán#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Hora de Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Hora de Papúa Nueva Guinea#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Hora braniega del Paraguái#,
				'generic' => q#Hora del Paraguái#,
				'standard' => q#Hora estándar del Paraguái#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Hora braniega del Perú#,
				'generic' => q#Hora del Perú#,
				'standard' => q#Hora estándar del Perú#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Hora de branu de Filipines#,
				'generic' => q#Hora de Filipines#,
				'standard' => q#Hora estándar de Filipines#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Hora de les Islles Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Hora braniega de Saint Pierre y Miquelon#,
				'generic' => q#Hora de Saint Pierre y Miquelon#,
				'standard' => q#Hora estándar de Saint Pierre y Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Hora de Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Hora de Ponape#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#hora de Pyongyang#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Hora braniega de Qyzylorda#,
				'generic' => q#Hora de Qyzylorda#,
				'standard' => q#Hora estándar de Qyzylorda#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Hora de Reunión#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Hora de Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Hora braniega de Saxalín#,
				'generic' => q#Hora de Saxalín#,
				'standard' => q#Hora estándar de Saxalín#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Hora braniega de Samara#,
				'generic' => q#Hora de Samara#,
				'standard' => q#Hora estándar de Samara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Hora braniega de Samoa#,
				'generic' => q#Hora de Samoa#,
				'standard' => q#Hora estándar de Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Hora de Les Seixeles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Hora estándar de Singapur#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Hora de les Islles Salomón#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Hora de Xeorxa del Sur#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Hora del Surinam#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Hora de Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Hora de Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Hora braniega de Taipéi#,
				'generic' => q#Hora de Taipéi#,
				'standard' => q#Hora estándar de Taipéi#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Hora del Taxiquistán#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Hora de Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Hora braniega de Tonga#,
				'generic' => q#Hora de Tonga#,
				'standard' => q#Hora estándar de Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Hora de Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Hora braniega del Turkmenistán#,
				'generic' => q#Hora del Turkmenistán#,
				'standard' => q#Hora estándar del Turkmenistán#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Hora de Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Hora braniega del Uruguái#,
				'generic' => q#Hora del Uruguái#,
				'standard' => q#Hora estándar del Uruguái#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Hora braniega del Uzbequistán#,
				'generic' => q#Hora del Uzbequistán#,
				'standard' => q#Hora estándar del Uzbequistán#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Hora braniega de Vanuatu#,
				'generic' => q#Hora de Vanuatu#,
				'standard' => q#Hora estándar de Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Hora de Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Hora braniega de Vladivostok#,
				'generic' => q#Hora de Vladivostok#,
				'standard' => q#Hora estándar de Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Hora braniega de Volgográu#,
				'generic' => q#Hora de Volgográu#,
				'standard' => q#Hora estándar de Volgográu#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Hora de Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Hora de la Islla Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Hora de Wallis y Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Hora braniega de Yakutsk#,
				'generic' => q#Hora de Yakutsk#,
				'standard' => q#Hora estándar de Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Hora braniega de Yekaterimburgu#,
				'generic' => q#Hora de Yekaterimburgu#,
				'standard' => q#Hora estándar de Yekaterimburgu#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
