=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Br - Package for language Breton

=cut

package Locale::CLDR::Locales::Br;
# This file auto generated from Data\common\main\br.xml
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
				'aa' => 'afar',
 				'ab' => 'abkhazeg',
 				'ace' => 'achineg',
 				'ach' => 'acoli',
 				'ada' => 'adangme',
 				'ady' => 'adygeieg',
 				'ae' => 'avesteg',
 				'aeb' => 'arabeg Tunizia',
 				'af' => 'afrikaans',
 				'afh' => 'afrihili',
 				'agq' => 'aghem',
 				'ain' => 'ainoueg',
 				'ak' => 'akan',
 				'akk' => 'akadeg',
 				'akz' => 'alabamaeg',
 				'ale' => 'aleouteg',
 				'aln' => 'gegeg',
 				'alt' => 'altaieg ar Su',
 				'am' => 'amhareg',
 				'an' => 'aragoneg',
 				'ang' => 'hensaozneg',
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'ar' => 'arabeg',
 				'ar_001' => 'arabeg modern',
 				'arc' => 'arameeg',
 				'arn' => 'araoukaneg',
 				'aro' => 'araona',
 				'arp' => 'arapaho',
 				'arq' => 'arabeg Aljeria',
 				'ars' => 'arabeg nadjiek',
 				'arw' => 'arawakeg',
 				'ary' => 'arabeg Maroko',
 				'arz' => 'arabeg Egipt',
 				'as' => 'asameg',
 				'asa' => 'asu',
 				'ase' => 'yezh sinoù Amerika',
 				'ast' => 'asturianeg',
 				'atj' => 'atikamekweg',
 				'av' => 'avar',
 				'awa' => 'awadhi',
 				'ay' => 'aymara',
 				'az' => 'azerbaidjaneg',
 				'az@alt=short' => 'azeri',
 				'ba' => 'bachkir',
 				'bal' => 'baloutchi',
 				'ban' => 'balineg',
 				'bar' => 'bavarieg',
 				'bas' => 'basaa',
 				'be' => 'belaruseg',
 				'bej' => 'bedawieg',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bg' => 'bulgareg',
 				'bgn' => 'baloutchi ar Cʼhornôg',
 				'bho' => 'bhojpuri',
 				'bi' => 'bislama',
 				'bik' => 'bikol',
 				'bin' => 'bini',
 				'bla' => 'siksika',
 				'bm' => 'bambara',
 				'bn' => 'bengali',
 				'bo' => 'tibetaneg',
 				'br' => 'brezhoneg',
 				'bra' => 'braj',
 				'brh' => 'brahweg',
 				'brx' => 'bodo',
 				'bs' => 'bosneg',
 				'bss' => 'akoose',
 				'bua' => 'bouriat',
 				'bug' => 'bugi',
 				'byn' => 'blin',
 				'ca' => 'katalaneg',
 				'cad' => 'caddo',
 				'car' => 'karibeg',
 				'cay' => 'kayougeg',
 				'cch' => 'atsam',
 				'ccp' => 'chakmaeg',
 				'ce' => 'tchetcheneg',
 				'ceb' => 'cebuano',
 				'cgg' => 'chigaeg',
 				'ch' => 'chamorru',
 				'chb' => 'chibcha',
 				'chk' => 'chuuk',
 				'chm' => 'marieg',
 				'cho' => 'choktaw',
 				'chp' => 'chipewyan',
 				'chr' => 'cherokee',
 				'chy' => 'cheyenne',
 				'ckb' => 'kurdeg sorani',
 				'ckb@alt=menu' => 'kurdeg kreiz',
 				'clc' => 'chilkotineg',
 				'co' => 'korseg',
 				'cop' => 'kopteg',
 				'cr' => 'kri',
 				'crg' => 'michifeg',
 				'crh' => 'turkeg Krimea',
 				'crj' => 'krieg ar Gevred',
 				'crk' => 'krieg ar cʼhompezennoù',
 				'crl' => 'krieg ar Biz',
 				'crm' => 'krieg ar cʼhornôg',
 				'crr' => 'algonkeg Carolina',
 				'crs' => 'kreoleg Sechelez',
 				'cs' => 'tchekeg',
 				'csb' => 'kachoubeg',
 				'csw' => 'krieg ar gwernioù',
 				'cu' => 'slavoneg iliz',
 				'cv' => 'tchouvatch',
 				'cy' => 'kembraeg',
 				'da' => 'daneg',
 				'dak' => 'dakota',
 				'dar' => 'dargwa',
 				'dav' => 'taita',
 				'de' => 'alamaneg',
 				'de_AT' => 'alamaneg Aostria',
 				'de_CH' => 'alamaneg uhel Suis',
 				'del' => 'delaware',
 				'dgr' => 'dogrib',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'dogri',
 				'dsb' => 'izelsorabeg',
 				'dua' => 'douala',
 				'dum' => 'nederlandeg krenn',
 				'dv' => 'divehi',
 				'dyo' => 'diola',
 				'dyu' => 'dyula',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazagaeg',
 				'ebu' => 'embu',
 				'ee' => 'ewe',
 				'efi' => 'efik',
 				'egy' => 'henegipteg',
 				'eka' => 'ekajuk',
 				'el' => 'gresianeg',
 				'elx' => 'elameg',
 				'en' => 'saozneg',
 				'en_AU' => 'saozneg Aostralia',
 				'en_CA' => 'saozneg Kanada',
 				'en_GB' => 'saozneg Breizh-Veur',
 				'en_GB@alt=short' => 'saozneg RU',
 				'en_US' => 'saozneg Amerika',
 				'en_US@alt=short' => 'saozneg SU',
 				'enm' => 'krennsaozneg',
 				'eo' => 'esperanteg',
 				'es' => 'spagnoleg',
 				'es_419' => 'spagnoleg Amerika latin',
 				'es_ES' => 'spagnoleg Europa',
 				'es_MX' => 'spagnoleg Mecʼhiko',
 				'et' => 'estoneg',
 				'eu' => 'euskareg',
 				'ewo' => 'ewondo',
 				'fa' => 'perseg',
 				'fa_AF' => 'dareg',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fula',
 				'fi' => 'finneg',
 				'fil' => 'filipineg',
 				'fit' => 'finneg traoñienn an Torne',
 				'fj' => 'fidjieg',
 				'fo' => 'faeroeg',
 				'fon' => 'fon',
 				'fr' => 'galleg',
 				'fr_CA' => 'galleg Kanada',
 				'fr_CH' => 'galleg Suis',
 				'frc' => 'galleg cajun',
 				'frm' => 'krenncʼhalleg',
 				'fro' => 'hencʼhalleg',
 				'frp' => 'arpitaneg',
 				'frr' => 'frizeg an Norzh',
 				'frs' => 'frizeg ar Reter',
 				'fur' => 'frioulaneg',
 				'fy' => 'frizeg ar Cʼhornôg',
 				'ga' => 'iwerzhoneg',
 				'gaa' => 'ga',
 				'gag' => 'gagaouzeg',
 				'gan' => 'sinaeg Gan',
 				'gay' => 'gayo',
 				'gba' => 'gbaya',
 				'gd' => 'skoseg',
 				'gez' => 'gezeg',
 				'gil' => 'gilberteg',
 				'gl' => 'galizeg',
 				'gmh' => 'krennalamaneg uhel',
 				'gn' => 'guarani',
 				'goh' => 'henalamaneg uhel',
 				'gor' => 'gorontalo',
 				'got' => 'goteg',
 				'grb' => 'grebo',
 				'grc' => 'hencʼhresianeg',
 				'gsw' => 'alamaneg Suis',
 				'gu' => 'gujarati',
 				'guz' => 'gusiieg',
 				'gv' => 'manaveg',
 				'gwi' => 'gwich’in',
 				'ha' => 'haousa',
 				'hai' => 'haideg',
 				'hak' => 'sinaeg Hakka',
 				'haw' => 'hawaieg',
 				'hax' => 'haideg ar Su',
 				'he' => 'hebraeg',
 				'hi' => 'hindi',
 				'hil' => 'hiligaynon',
 				'hmn' => 'hmong',
 				'ho' => 'hiri motu',
 				'hr' => 'kroateg',
 				'hsb' => 'uhelsorabeg',
 				'hsn' => 'sinaeg Xian',
 				'ht' => 'haitieg',
 				'hu' => 'hungareg',
 				'hup' => 'hupa',
 				'hur' => 'halkomelemeg',
 				'hy' => 'armenianeg',
 				'hz' => 'herero',
 				'ia' => 'interlingua',
 				'iba' => 'iban',
 				'ibb' => 'ibibio',
 				'id' => 'indonezeg',
 				'ie' => 'interlingue',
 				'ig' => 'igbo',
 				'ii' => 'yieg Sichuan',
 				'ik' => 'inupiaq',
 				'ikt' => 'inuktitut Kanada ar Cʼhornôg',
 				'ilo' => 'ilokanoeg',
 				'inh' => 'ingoucheg',
 				'io' => 'ido',
 				'is' => 'islandeg',
 				'it' => 'italianeg',
 				'iu' => 'inuktitut',
 				'ja' => 'japaneg',
 				'jam' => 'kreoleg Jamaika',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jpr' => 'yuzev-perseg',
 				'jrb' => 'yuzev-arabeg',
 				'jv' => 'javaneg',
 				'ka' => 'jorjianeg',
 				'kaa' => 'karakalpak',
 				'kab' => 'kabileg',
 				'kac' => 'kachin',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kbd' => 'kabardeg',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'kabuverdianu',
 				'kfo' => 'koroeg',
 				'kg' => 'kongo',
 				'kgp' => 'kaingangeg',
 				'kha' => 'khasi',
 				'kho' => 'khotaneg',
 				'khq' => 'koyra chiini',
 				'ki' => 'kikuyu',
 				'kj' => 'kwanyama',
 				'kk' => 'kazak',
 				'kkj' => 'kakoeg',
 				'kl' => 'greunlandeg',
 				'kln' => 'kalendjineg',
 				'km' => 'khmer',
 				'kmb' => 'kimbundu',
 				'kn' => 'kanareg',
 				'ko' => 'koreaneg',
 				'kok' => 'konkani',
 				'kos' => 'kosrae',
 				'kpe' => 'kpelle',
 				'kr' => 'kanouri',
 				'krc' => 'karatchay-balkar',
 				'kri' => 'krio',
 				'krl' => 'karelieg',
 				'kru' => 'kurukh',
 				'ks' => 'kashmiri',
 				'ksb' => 'shambala',
 				'ksf' => 'bafiaeg',
 				'ksh' => 'koluneg',
 				'ku' => 'kurdeg',
 				'kum' => 'koumikeg',
 				'kut' => 'kutenai',
 				'kv' => 'komieg',
 				'kw' => 'kerneveureg',
 				'kwk' => 'kwakwaleg',
 				'ky' => 'kirgiz',
 				'la' => 'latin',
 				'lad' => 'ladino',
 				'lag' => 'langi',
 				'lah' => 'lahnda',
 				'lam' => 'lamba',
 				'lb' => 'luksembourgeg',
 				'lez' => 'lezgi',
 				'lfn' => 'lingua franca nova',
 				'lg' => 'ganda',
 				'li' => 'limbourgeg',
 				'lij' => 'ligurieg',
 				'lil' => 'lillooet',
 				'lkt' => 'lakota',
 				'ln' => 'lingala',
 				'lo' => 'laoseg',
 				'lol' => 'mongo',
 				'lou' => 'kreoleg Louiziana',
 				'loz' => 'lozi',
 				'lrc' => 'loureg an Norzh',
 				'lt' => 'lituaneg',
 				'lu' => 'luba-katanga',
 				'lua' => 'luba-lulua',
 				'lui' => 'luiseno',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'lushai',
 				'luy' => 'luyia',
 				'lv' => 'latvieg',
 				'lzh' => 'sinaeg lennegel',
 				'mad' => 'madoureg',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'makasar',
 				'mas' => 'masai',
 				'mdf' => 'moksha',
 				'mdr' => 'mandar',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'moriseg',
 				'mg' => 'malgacheg',
 				'mga' => 'krenniwerzhoneg',
 				'mgh' => 'makhuwa-meetto',
 				'mgo' => 'metaʼ',
 				'mh' => 'marshall',
 				'mi' => 'maori',
 				'mic' => 'mikmakeg',
 				'min' => 'minangkabau',
 				'mk' => 'makedoneg',
 				'ml' => 'malayalam',
 				'mn' => 'mongoleg',
 				'mnc' => 'manchou',
 				'mni' => 'manipuri',
 				'moe' => 'montagneg',
 				'moh' => 'mohawk',
 				'mos' => 'more',
 				'mr' => 'marathi',
 				'mrj' => 'marieg ar Cʼhornôg',
 				'ms' => 'malayseg',
 				'mt' => 'malteg',
 				'mua' => 'moundangeg',
 				'mul' => 'yezhoù lies',
 				'mus' => 'muskogi',
 				'mwl' => 'mirandeg',
 				'my' => 'birmaneg',
 				'myv' => 'erza',
 				'mzn' => 'mazanderaneg',
 				'na' => 'naurueg',
 				'nan' => 'sinaeg Min Nan',
 				'nap' => 'napolitaneg',
 				'naq' => 'nama',
 				'nb' => 'norvegeg bokmål',
 				'nd' => 'ndebele an Norzh',
 				'nds' => 'alamaneg izel',
 				'nds_NL' => 'saksoneg izel',
 				'ne' => 'nepaleg',
 				'new' => 'newari',
 				'ng' => 'ndonga',
 				'nia' => 'nias',
 				'niu' => 'niue',
 				'njo' => 'aoeg',
 				'nl' => 'nederlandeg',
 				'nl_BE' => 'flandrezeg',
 				'nmg' => 'ngoumbeg',
 				'nn' => 'norvegeg nynorsk',
 				'nnh' => 'ngiemboon',
 				'no' => 'norvegeg',
 				'nog' => 'nogay',
 				'non' => 'hennorseg',
 				'nov' => 'novial',
 				'nqo' => 'nkoeg',
 				'nr' => 'ndebele ar Su',
 				'nso' => 'sotho an Norzh',
 				'nus' => 'nouereg',
 				'nv' => 'navacʼho',
 				'nwc' => 'newari klasel',
 				'ny' => 'nyanja',
 				'nym' => 'nyamwezi',
 				'nyn' => 'nyankole',
 				'nyo' => 'nyoro',
 				'oc' => 'okitaneg',
 				'oj' => 'ojibweg',
 				'ojb' => 'ojibweg ar Gwalarn',
 				'ojc' => 'ojibweg ar cʼhreiz',
 				'ojs' => 'ojibweg Severn',
 				'ojw' => 'ojibweg ar Cʼhornôg',
 				'oka' => 'okanaganeg',
 				'om' => 'oromoeg',
 				'or' => 'oriya',
 				'os' => 'oseteg',
 				'osa' => 'osage',
 				'ota' => 'turkeg otoman',
 				'pa' => 'punjabi',
 				'pag' => 'pangasinan',
 				'pal' => 'pahlavi',
 				'pam' => 'pampanga',
 				'pap' => 'papiamento',
 				'pau' => 'palau',
 				'pcd' => 'pikardeg',
 				'pcm' => 'pidjin Nigeria',
 				'pdc' => 'alamaneg Pennsylvania',
 				'peo' => 'henberseg',
 				'phn' => 'fenikianeg',
 				'pi' => 'pali',
 				'pis' => 'pidjin',
 				'pl' => 'poloneg',
 				'pms' => 'piemonteg',
 				'pnt' => 'ponteg',
 				'pon' => 'pohnpei',
 				'pqm' => 'malisiteg-pasamawkodieg',
 				'prg' => 'henbruseg',
 				'pro' => 'henbrovañseg',
 				'ps' => 'pachto',
 				'pt' => 'portugaleg',
 				'pt_BR' => 'portugaleg Brazil',
 				'pt_PT' => 'portugaleg Europa',
 				'qu' => 'kechuaeg',
 				'quc' => 'kʼicheʼ',
 				'qug' => 'kichuaeg Chimborazo',
 				'raj' => 'rajasthani',
 				'rap' => 'rapanui',
 				'rar' => 'rarotonga',
 				'rgn' => 'romagnoleg',
 				'rhg' => 'rohingya',
 				'rm' => 'romañcheg',
 				'rn' => 'rundi',
 				'ro' => 'roumaneg',
 				'ro_MD' => 'moldoveg',
 				'rof' => 'rombo',
 				'rom' => 'romanieg',
 				'ru' => 'rusianeg',
 				'rup' => 'aroumaneg',
 				'rw' => 'kinyarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanskriteg',
 				'sad' => 'sandawe',
 				'sah' => 'yakouteg',
 				'sam' => 'arameeg ar Samaritaned',
 				'saq' => 'samburu',
 				'sas' => 'sasak',
 				'sat' => 'santali',
 				'sba' => 'ngambayeg',
 				'sbp' => 'sangu',
 				'sc' => 'sardeg',
 				'scn' => 'sikilieg',
 				'sco' => 'skoteg',
 				'sd' => 'sindhi',
 				'sdc' => 'sasareseg',
 				'se' => 'sámi an Norzh',
 				'seh' => 'sena',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'sga' => 'heniwerzhoneg',
 				'sh' => 'serb-kroateg',
 				'shi' => 'tacheliteg',
 				'shn' => 'shan',
 				'shu' => 'arabeg Tchad',
 				'si' => 'singhaleg',
 				'sid' => 'sidamo',
 				'sk' => 'slovakeg',
 				'sl' => 'sloveneg',
 				'slh' => 'luchoutsideg ar Su',
 				'sm' => 'samoan',
 				'sma' => 'sámi ar Su',
 				'smj' => 'sámi Luleå',
 				'smn' => 'sámi Inari',
 				'sms' => 'sámi Skolt',
 				'sn' => 'shona',
 				'snk' => 'soninke',
 				'so' => 'somali',
 				'sog' => 'sogdieg',
 				'sq' => 'albaneg',
 				'sr' => 'serbeg',
 				'srn' => 'sranan tongo',
 				'srr' => 'serer',
 				'ss' => 'swati',
 				'ssy' => 'sahoeg',
 				'st' => 'sotho ar Su',
 				'su' => 'sundaneg',
 				'suk' => 'sukuma',
 				'sux' => 'sumereg',
 				'sv' => 'svedeg',
 				'sw' => 'swahili',
 				'sw_CD' => 'swahili Kongo',
 				'swb' => 'komoreg',
 				'syc' => 'sirieg klasel',
 				'syr' => 'sirieg',
 				'szl' => 'silezieg',
 				'ta' => 'tamileg',
 				'tce' => 'tutchoneg ar Su',
 				'tcy' => 'touloueg',
 				'te' => 'telougou',
 				'tem' => 'temne',
 				'teo' => 'tesoeg',
 				'ter' => 'tereno',
 				'tet' => 'tetum',
 				'tg' => 'tadjik',
 				'th' => 'thai',
 				'ti' => 'tigrigna',
 				'tig' => 'tigreaneg',
 				'tiv' => 'tiv',
 				'tk' => 'turkmeneg',
 				'tkl' => 'tokelau',
 				'tl' => 'tagalog',
 				'tlh' => 'klingon',
 				'tli' => 'tinglit',
 				'tmh' => 'tamacheg',
 				'tn' => 'tswana',
 				'to' => 'tonga',
 				'tog' => 'nyasa tonga',
 				'tok' => 'toki pona',
 				'tpi' => 'tok pisin',
 				'tr' => 'turkeg',
 				'tru' => 'turoyoeg',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsi' => 'tsimshian',
 				'tt' => 'tatar',
 				'ttm' => 'tutchoneg an Norzh',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalu',
 				'tw' => 'twi',
 				'twq' => 'tasawakeg',
 				'ty' => 'tahitianeg',
 				'tyv' => 'touva',
 				'tzm' => 'tamazigteg Kreizatlas',
 				'udm' => 'oudmourteg',
 				'ug' => 'ouigoureg',
 				'uga' => 'ougariteg',
 				'uk' => 'ukraineg',
 				'umb' => 'umbundu',
 				'und' => 'yezh dianav',
 				'ur' => 'ourdou',
 				'uz' => 'ouzbekeg',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vec' => 'venezieg',
 				'vep' => 'vepseg',
 				'vi' => 'vietnameg',
 				'vls' => 'flandrezeg ar c’hornôg',
 				'vo' => 'volapük',
 				'vot' => 'votyakeg',
 				'vro' => 'voroeg',
 				'vun' => 'vunjo',
 				'wa' => 'walloneg',
 				'wae' => 'walser',
 				'wal' => 'walamo',
 				'war' => 'waray',
 				'was' => 'washo',
 				'wo' => 'wolof',
 				'wuu' => 'sinaeg Wu',
 				'xal' => 'kalmouk',
 				'xh' => 'xhosa',
 				'xmf' => 'megreleg',
 				'xog' => 'sogaeg',
 				'yao' => 'yao',
 				'yap' => 'yapeg',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'yiddish',
 				'yo' => 'yorouba',
 				'yrl' => 'nengatoueg',
 				'yue' => 'kantoneg',
 				'yue@alt=menu' => 'sinaeg, kantoneg',
 				'za' => 'zhuang',
 				'zap' => 'zapoteg',
 				'zbl' => 'arouezioù Bliss',
 				'zea' => 'zelandeg',
 				'zen' => 'zenaga',
 				'zgh' => 'tamacheg Maroko standart',
 				'zh' => 'sinaeg',
 				'zh@alt=menu' => 'sinaeg, mandarineg',
 				'zh_Hans' => 'sinaeg eeunaet',
 				'zh_Hans@alt=long' => 'sinaeg mandarinek eeunaet',
 				'zh_Hant' => 'sinaeg hengounel',
 				'zh_Hant@alt=long' => 'sinaeg mandarinek hengounel',
 				'zu' => 'zouloueg',
 				'zun' => 'zuni',
 				'zxx' => 'diyezh',
 				'zza' => 'zazakeg',

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
 			'Arab' => 'arabek',
 			'Armi' => 'arameek impalaerel',
 			'Armn' => 'armenianek',
 			'Avst' => 'avestek',
 			'Bali' => 'balinek',
 			'Bamu' => 'bamounek',
 			'Batk' => 'batak',
 			'Beng' => 'bengali',
 			'Bopo' => 'bopomofo',
 			'Brai' => 'Braille',
 			'Bugi' => 'bougiek',
 			'Cakm' => 'chakmaek',
 			'Cans' => 'silabennaoueg engenidik unvan Kanada',
 			'Cham' => 'cham',
 			'Cher' => 'cherokee',
 			'Copt' => 'koptek',
 			'Cprt' => 'silabennaoueg kipriek',
 			'Cyrl' => 'kirillek',
 			'Cyrs' => 'kirillek henslavonek',
 			'Deva' => 'devanagari',
 			'Dupl' => 'berrskriverezh Duployé',
 			'Egyp' => 'hieroglifoù egiptek',
 			'Ethi' => 'etiopek',
 			'Geor' => 'jorjianek',
 			'Glag' => 'glagolitek',
 			'Goth' => 'gotek',
 			'Grek' => 'gresianek',
 			'Gujr' => 'gujarati',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'han gant bopomofo',
 			'Hang' => 'hangeul',
 			'Hani' => 'sinalunioù (han)',
 			'Hans' => 'eeunaet',
 			'Hans@alt=stand-alone' => 'sinalunioù (han) eeunaet',
 			'Hant' => 'hengounel',
 			'Hant@alt=stand-alone' => 'sinalunioù (han) hengounel',
 			'Hebr' => 'hebraek',
 			'Hira' => 'hiragana',
 			'Hluw' => 'hieroglifoù Anatolia',
 			'Hrkt' => 'silabennaouegoù japanek',
 			'Hung' => 'henhungarek',
 			'Ital' => 'henitalek',
 			'Jamo' => 'jamo',
 			'Java' => 'javanek',
 			'Jpan' => 'japanek',
 			'Kana' => 'katakana',
 			'Khmr' => 'khmer',
 			'Knda' => 'kannada',
 			'Kore' => 'koreanek',
 			'Laoo' => 'laosek',
 			'Latg' => 'latin gouezelek',
 			'Latn' => 'latin',
 			'Lyci' => 'likiek',
 			'Lydi' => 'lidiek',
 			'Mani' => 'manikeek',
 			'Maya' => 'hieroglifoù mayaek',
 			'Mlym' => 'malayalam',
 			'Mong' => 'mongolek',
 			'Mymr' => 'myanmar',
 			'Narb' => 'henarabek an Norzh',
 			'Ogam' => 'ogam',
 			'Orya' => 'oriya',
 			'Phnx' => 'fenikianek',
 			'Runr' => 'runek',
 			'Samr' => 'samaritek',
 			'Sarb' => 'henarabek ar Su',
 			'Sinh' => 'singhalek',
 			'Sund' => 'sundanek',
 			'Syrc' => 'siriek',
 			'Syre' => 'siriek Estrangelā',
 			'Syrj' => 'siriek ar C’hornôg',
 			'Syrn' => 'siriek ar Reter',
 			'Taml' => 'tamilek',
 			'Telu' => 'telougou',
 			'Tglg' => 'tagalog',
 			'Thaa' => 'thaana',
 			'Thai' => 'thai',
 			'Tibt' => 'tibetanek',
 			'Ugar' => 'ougaritek',
 			'Vaii' => 'vai',
 			'Xpeo' => 'persek kozh',
 			'Xsux' => 'gennheñvel',
 			'Zinh' => 'hêrezh',
 			'Zmth' => 'notadur jedoniel',
 			'Zsye' => 'fromlunioù',
 			'Zsym' => 'arouezioù',
 			'Zxxx' => 'anskrivet',
 			'Zyyy' => 'boutin',
 			'Zzzz' => 'skritur dianav',

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
			'001' => 'Bed',
 			'002' => 'Afrika',
 			'003' => 'Norzhamerika',
 			'005' => 'Suamerika',
 			'009' => 'Oseania',
 			'011' => 'Afrika ar Cʼhornôg',
 			'013' => 'Kreizamerika',
 			'014' => 'Afrika ar Reter',
 			'015' => 'Afrika an Norzh',
 			'017' => 'Afrika ar Cʼhreiz',
 			'018' => 'Afrika ar Su',
 			'019' => 'Amerikaoù',
 			'021' => 'Amerika an Norzh',
 			'029' => 'Karib',
 			'030' => 'Azia ar Reter',
 			'034' => 'Azia ar Su',
 			'035' => 'Azia ar Gevred',
 			'039' => 'Europa ar Su',
 			'053' => 'Aostralazia',
 			'054' => 'Melanezia',
 			'057' => 'Rannved Mikronezia',
 			'061' => 'Polinezia',
 			'142' => 'Azia',
 			'143' => 'Azia ar Cʼhreiz',
 			'145' => 'Azia ar Cʼhornôg',
 			'150' => 'Europa',
 			'151' => 'Europa ar Reter',
 			'154' => 'Europa an Norzh',
 			'155' => 'Europa ar Cʼhornôg',
 			'202' => 'Afrika issaharat',
 			'419' => 'Amerika Latin',
 			'AC' => 'Enez Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Emirelezhioù Arab Unanet',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua ha Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktika',
 			'AR' => 'Arcʼhantina',
 			'AS' => 'Samoa Amerikan',
 			'AT' => 'Aostria',
 			'AU' => 'Aostralia',
 			'AW' => 'Aruba',
 			'AX' => 'Inizi Åland',
 			'AZ' => 'Azerbaidjan',
 			'BA' => 'Bosnia ha Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgia',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrein',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Saint Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Karib Nederlandat',
 			'BR' => 'Brazil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhoutan',
 			'BV' => 'Enez Bouvet',
 			'BW' => 'Botswana',
 			'BY' => 'Belarus',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Inizi Kokoz',
 			'CD' => 'Kongo - Kinshasa',
 			'CD@alt=variant' => 'Kongo (RDK)',
 			'CF' => 'Republik Kreizafrikan',
 			'CG' => 'Kongo - Brazzaville',
 			'CG@alt=variant' => 'Kongo (Republik)',
 			'CH' => 'Suis',
 			'CI' => 'Aod an Olifant',
 			'CI@alt=variant' => 'Aod Olifant',
 			'CK' => 'Inizi Cook',
 			'CL' => 'Chile',
 			'CM' => 'Kameroun',
 			'CN' => 'Sina',
 			'CO' => 'Kolombia',
 			'CP' => 'Enez Clipperton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Kuba',
 			'CV' => 'Kab-Glas',
 			'CW' => 'Curaçao',
 			'CX' => 'Enez Christmas',
 			'CY' => 'Kiprenez',
 			'CZ' => 'Tchekia',
 			'CZ@alt=variant' => 'Republik Tchek',
 			'DE' => 'Alamagn',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Danmark',
 			'DM' => 'Dominica',
 			'DO' => 'Republik Dominikan',
 			'DZ' => 'Aljeria',
 			'EA' => 'Ceuta ha Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Egipt',
 			'EH' => 'Sahara ar Cʼhornôg',
 			'ER' => 'Eritrea',
 			'ES' => 'Spagn',
 			'ET' => 'Etiopia',
 			'EU' => 'Unaniezh Europa',
 			'EZ' => 'takad an euro',
 			'FI' => 'Finland',
 			'FJ' => 'Fidji',
 			'FK' => 'Inizi Falkland',
 			'FK@alt=variant' => 'Inizi Falkland (Inizi Maloù)',
 			'FM' => 'Mikronezia',
 			'FO' => 'Inizi Faero',
 			'FR' => 'Frañs',
 			'GA' => 'Gabon',
 			'GB' => 'Rouantelezh-Unanet',
 			'GB@alt=short' => 'RU',
 			'GD' => 'Grenada',
 			'GE' => 'Jorjia',
 			'GF' => 'Gwiana cʼhall',
 			'GG' => 'Gwernenez',
 			'GH' => 'Ghana',
 			'GI' => 'Jibraltar',
 			'GL' => 'Greunland',
 			'GM' => 'Gambia',
 			'GN' => 'Ginea',
 			'GP' => 'Gwadeloup',
 			'GQ' => 'Ginea ar Cʼheheder',
 			'GR' => 'Gres',
 			'GS' => 'Inizi Georgia ar Su hag Inizi Sandwich ar Su',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Ginea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hong Kong RMD Sina',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Inizi Heard ha McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Kroatia',
 			'HT' => 'Haiti',
 			'HU' => 'Hungaria',
 			'IC' => 'Inizi Kanariez',
 			'ID' => 'Indonezia',
 			'IE' => 'Iwerzhon',
 			'IL' => 'Israel',
 			'IM' => 'Enez Vanav',
 			'IN' => 'India',
 			'IO' => 'Tiriad breizhveurat Meurvor Indez',
 			'IQ' => 'Iraq',
 			'IR' => 'Iran',
 			'IS' => 'Island',
 			'IT' => 'Italia',
 			'JE' => 'Jerzenez',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordania',
 			'JP' => 'Japan',
 			'KE' => 'Kenya',
 			'KG' => 'Kyrgyzstan',
 			'KH' => 'Kambodja',
 			'KI' => 'Kiribati',
 			'KM' => 'Komorez',
 			'KN' => 'Saint Kitts ha Nevis',
 			'KP' => 'Korea an Norzh',
 			'KR' => 'Korea ar Su',
 			'KW' => 'Koweit',
 			'KY' => 'Inizi Cayman',
 			'KZ' => 'Kazakstan',
 			'LA' => 'Laos',
 			'LB' => 'Liban',
 			'LC' => 'Saint Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lituania',
 			'LU' => 'Luksembourg',
 			'LV' => 'Latvia',
 			'LY' => 'Libia',
 			'MA' => 'Maroko',
 			'MC' => 'Monaco',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'Saint Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Inizi Marshall',
 			'MK' => 'Makedonia an Norzh',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Birmania)',
 			'MN' => 'Mongolia',
 			'MO' => 'Macau RMD Sina',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Inizi Mariana an Norzh',
 			'MQ' => 'Martinik',
 			'MR' => 'Maouritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Moris',
 			'MV' => 'Maldivez',
 			'MW' => 'Malawi',
 			'MX' => 'Mecʼhiko',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mozambik',
 			'NA' => 'Namibia',
 			'NC' => 'Kaledonia Nevez',
 			'NE' => 'Niger',
 			'NF' => 'Enez Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Izelvroioù',
 			'NO' => 'Norvegia',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Zeland-Nevez',
 			'NZ@alt=variant' => 'Aotearoa Zeland-Nevez',
 			'OM' => 'Oman',
 			'PA' => 'Panamá',
 			'PE' => 'Perou',
 			'PF' => 'Polinezia Cʼhall',
 			'PG' => 'Papoua Ginea-Nevez',
 			'PH' => 'Filipinez',
 			'PK' => 'Pakistan',
 			'PL' => 'Polonia',
 			'PM' => 'Sant-Pêr-ha-Mikelon',
 			'PN' => 'Enez Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Tiriadoù Palestina',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Oseania diabell',
 			'RE' => 'Ar Reünion',
 			'RO' => 'Roumania',
 			'RS' => 'Serbia',
 			'RU' => 'Rusia',
 			'RW' => 'Rwanda',
 			'SA' => 'Arabia Saoudat',
 			'SB' => 'Inizi Salomon',
 			'SC' => 'Sechelez',
 			'SD' => 'Soudan',
 			'SE' => 'Sveden',
 			'SG' => 'Singapour',
 			'SH' => 'Saint-Helena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Svalbard',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinam',
 			'SS' => 'Susoudan',
 			'ST' => 'São Tomé ha Príncipe',
 			'SV' => 'Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Siria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Swaziland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Inizi Turks ha Caicos',
 			'TD' => 'Tchad',
 			'TF' => 'Douaroù aostral Frañs',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tadjikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Timor ar Reter',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunizia',
 			'TO' => 'Tonga',
 			'TR' => 'Turkia',
 			'TT' => 'Trinidad ha Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraina',
 			'UG' => 'Ouganda',
 			'UM' => 'Inizi diabell ar Stadoù-Unanet',
 			'UN' => 'Broadoù unanet',
 			'US' => 'Stadoù-Unanet',
 			'US@alt=short' => 'SU',
 			'UY' => 'Uruguay',
 			'UZ' => 'Ouzbekistan',
 			'VA' => 'Vatikan',
 			'VC' => 'Sant Visant hag ar Grenadinez',
 			'VE' => 'Venezuela',
 			'VG' => 'Inizi Gwercʼh Breizh-Veur',
 			'VI' => 'Inizi Gwercʼh ar Stadoù-Unanet',
 			'VN' => 'Viêt Nam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis ha Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'pouez-mouezh gaou',
 			'XB' => 'BiDi gaou',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Suafrika',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Rannved dianav',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'reizhskrivadur alamanek hengounel',
 			'1994' => 'reizhskrivadur resianek skoueriekaet',
 			'1996' => 'reizhskrivadur alamanek 1996',
 			'1606NICT' => 'krenncʼhalleg diwezhañ',
 			'1694ACAD' => 'galleg rakvodern',
 			'1959ACAD' => 'belaruseg akademek',
 			'ABL1943' => 'doare reizhskrivañ 1943',
 			'AKUAPEM' => 'akuapem',
 			'ALALC97' => 'romanekadur ALA-LC 1997',
 			'ALUKU' => 'rannyezh aloukou',
 			'AO1990' => 'emglev 1990 war ar reizhskrivadur portugalek',
 			'ARANES' => 'araneg',
 			'AREVELA' => 'armenianeg ar Reter',
 			'AREVMDA' => 'armenianeg ar Cʼhornôg',
 			'ARKAIKA' => 'henesperanteg',
 			'ASANTE' => 'achanti',
 			'AUVERN' => 'arverneg',
 			'BAKU1926' => 'lizherenneg latin turkek unvan',
 			'BALANKA' => 'rannyezh aniiek Balanka',
 			'BARLA' => 'rannyezhoù Barlavento kreoleg ar Cʼhab-Glas',
 			'BASICENG' => 'saozneg diazez',
 			'BAUDDHA' => 'sanskriteg hiron boudaat',
 			'BISCAYAN' => 'rannyezh euskarek Bizkaia',
 			'BISKE' => 'rannyezh San Giorgio/Bila',
 			'BOHORIC' => 'lizherenneg Bohorič',
 			'BOONT' => 'boontling',
 			'BORNHOLM' => 'rannyezh Bornholm',
 			'CISAUP' => 'kizalpeg',
 			'COLB1945' => 'emglev 1945 war reizhskrivadur portugaleg Brazil',
 			'CORNU' => 'saozneg Kerne-Veur',
 			'CREISS' => 'rannyezhoù Creissent',
 			'DAJNKO' => 'lizherenneg Dajnko',
 			'EKAVSK' => 'serbeg gant distagadur ekavian',
 			'EMODENG' => 'saozneg rakvodern',
 			'FONIPA' => 'lizherenneg fonetek etrebroadel',
 			'FONKIRSH' => 'lizherenneg fonetek Kirshenbaum',
 			'FONNAPA' => 'lizherenneg fonetek Norzh Amerika',
 			'FONUPA' => 'lizherenneg fonetek ouralek',
 			'FONXSAMP' => 'treuzskrivadur X-SAMPA',
 			'GALLO' => 'gallaoueg',
 			'GASCON' => 'gwaskoneg',
 			'GRCLASS' => 'skritur okitanek klasel',
 			'GRITAL' => 'skritur okitanek Italia',
 			'GRMISTR' => 'skritur okitanek mistralek',
 			'HEPBURN' => 'romanekadur Hepburn',
 			'HOGNORSK' => 'uhelnorvegeg',
 			'HSISTEMO' => 'esperanteg sistem H',
 			'IJEKAVSK' => 'serbeg gant distagadur ijekavian',
 			'ITIHASA' => 'sanskriteg itihâsa',
 			'IVANCHOV' => 'reizhskrivadur bulgarek Ivanchov',
 			'JAUER' => 'rannyezh romañchek Jauer',
 			'JYUTPING' => 'romanekadur kantonek Jyutping',
 			'KKCOR' => 'kerneveureg kumun',
 			'KOCIEWIE' => 'rannyezh polonek Kociewie',
 			'KSCOR' => 'kerneveureg standart',
 			'LAUKIKA' => 'sanskriteg klasel',
 			'LEMOSIN' => 'rannyezh Limousin',
 			'LENGADOC' => 'lengadokeg',
 			'LIPAW' => 'rannyezh resianek Lipovaz',
 			'LUNA1918' => 'reizhskrivadur rusianek goude 1917',
 			'METELKO' => 'lizherenneg Metelko',
 			'MONOTON' => 'gresianeg untonel',
 			'NDYUKA' => 'rannyezh Ndyuka',
 			'NEDIS' => 'rannyezh Natisone',
 			'NEWFOUND' => 'saozneg an Douar-Nevez',
 			'NICARD' => 'nisardeg',
 			'NJIVA' => 'rannyezh Gniva/Njiva',
 			'NULIK' => 'volapük modern',
 			'OSOJS' => 'rannyezh Oseacco/Osojane',
 			'OXENDICT' => 'skritur Oxford English Dictionary',
 			'PAHAWH2' => 'reizhskrivadur pahawh hmong lankad 2',
 			'PAHAWH3' => 'reizhskrivadur pahawh hmong lankad 3',
 			'PAHAWH4' => 'reizhskrivadur pahawh hmong doare diwezhañ',
 			'PAMAKA' => 'rannyezh Pamaka',
 			'PEANO' => 'Peano',
 			'PETR1708' => 'reizhskrivadur rusianek 1708 Pêr I',
 			'PINYIN' => 'romanekadur pinyin',
 			'POLYTON' => 'gresianeg liestonel',
 			'POSIX' => 'stlenneg',
 			'PROVENC' => 'provañseg',
 			'PUTER' => 'rannyezh romañchek Puter',
 			'REVISED' => 'reizhskrivadur reizhet',
 			'RIGIK' => 'volapük klasel',
 			'ROZAJ' => 'resianeg',
 			'RUMGR' => 'romañcheg Grischun',
 			'SAAHO' => 'saho',
 			'SCOTLAND' => 'saozneg standart Skos',
 			'SCOUSE' => 'saozneg Liverpool (scouse)',
 			'SIMPLE' => 'eeunaet',
 			'SOLBA' => 'rannyezh Stolvizza/Solbica',
 			'SOTAV' => 'rannyezhoù Sotavento kreoleg ar Cʼhab-Glas',
 			'SPANGLIS' => 'spanglish',
 			'SURMIRAN' => 'rannyezh romañchek surmiran',
 			'SURSILV' => 'rannyezh romañchek sursilvan',
 			'SUTSILV' => 'rannyezh romañchek sutsilvan',
 			'SYNNEJYL' => 'rannyezh Jutland ar Su',
 			'TARASK' => 'belaruseg Taraskievica',
 			'TONGYONG' => 'Tongyong Pinyin',
 			'TUNUMIIT' => 'tunumiit',
 			'UCCOR' => 'kerneveureg unvan',
 			'UCRCOR' => 'kerneveureg unvan reizhet',
 			'ULSTER' => 'rannyezh skotek Ulad',
 			'UNIFON' => 'lizherenneg fonetek Unifon',
 			'VAIDIKA' => 'sanskriteg vedek',
 			'VALENCIA' => 'valensianeg',
 			'VALLADER' => 'rannyezh romañchek Vallader',
 			'VECDRUKA' => 'vecā druka',
 			'VIVARAUP' => 'vivaroalpeg',
 			'WADEGILE' => 'romanekadur Wade-Giles',
 			'XSISTEMO' => 'esperanteg sistem X',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'deiziadur',
 			'cf' => 'furmad moneiz',
 			'collation' => 'doare rummañ',
 			'currency' => 'moneiz',
 			'hc' => 'kelcʼhiad eurioù',
 			'lb' => 'stil torr linenn',
 			'ms' => 'reizhiad vuzuliañ',
 			'numbers' => 'niveroù',

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
 				'buddhist' => q{deiziadur boudaat},
 				'chinese' => q{deiziadur sinaat},
 				'coptic' => q{deiziadur kopt},
 				'dangi' => q{deiziadur dangi},
 				'ethiopic' => q{deiziadur etiopiat},
 				'ethiopic-amete-alem' => q{deiziadur etiopiat Amete Alem},
 				'gregorian' => q{deiziadur gregorian},
 				'hebrew' => q{deiziadur hebraek},
 				'indian' => q{deiziadur indian},
 				'islamic' => q{deiziadur islamek},
 				'islamic-civil' => q{deiziadur islamek keodedel},
 				'islamic-rgsa' => q{deiziadur islamek (Arabia Saoudat)},
 				'islamic-tbla' => q{deiziadur islamek steredoniel},
 				'islamic-umalqura' => q{deiziadur islamek (Umm al-Qura)},
 				'iso8601' => q{deiziadur ISO-8601},
 				'japanese' => q{deiziadur japanat},
 				'persian' => q{deiziadur persek},
 				'roc' => q{deiziadur Republik Sina},
 			},
 			'cf' => {
 				'account' => q{furmad unanenn jediñ},
 				'standard' => q{furmad moneiz standart},
 			},
 			'collation' => {
 				'big5han' => q{urzh rummañ sinaek hengounel - Big5},
 				'dictionary' => q{urzh rummañ ar geriadur},
 				'ducet' => q{urzh rummañ Unicode dre ziouer},
 				'emoji' => q{urzh rummañ ar fromlunioù},
 				'eor' => q{reolennoù urzhiañ europat},
 				'gb2312han' => q{urzh rummañ sinaek eeunaet - GB2312},
 				'phonebook' => q{urzh rummañ al levr-pellgomz},
 				'pinyin' => q{urzh rummañ pinyin},
 				'reformed' => q{urzh rummañ adreizhet},
 				'search' => q{enklask hollek},
 				'standard' => q{urzh rummañ standart},
 				'stroke' => q{urzh rummañ an tresoù},
 				'traditional' => q{urzh rummañ hengounel},
 				'unihan' => q{urzh rummañ UniHan},
 				'zhuyin' => q{urzh rummañ Zhuyin},
 			},
 			'hc' => {
 				'h11' => q{reizhiad 12 eurvezh (0–11)},
 				'h12' => q{reizhiad 12 eurvezh (1–12)},
 				'h23' => q{reizhiad 24 eurvezh (0–23)},
 				'h24' => q{reizhiad 24 eurvezh (1–24)},
 			},
 			'lb' => {
 				'loose' => q{stil torr linenn lezober},
 				'normal' => q{stil torr linenn boas},
 				'strict' => q{stil torr linenn strizh},
 			},
 			'ms' => {
 				'metric' => q{reizhiad vetrek},
 				'uksystem' => q{reizhiad vuzuliañ RU},
 				'ussystem' => q{reizhiad vuzuliañ SU},
 			},
 			'numbers' => {
 				'ahom' => q{sifroù ahomek},
 				'arab' => q{sifroù arabek indian},
 				'arabext' => q{sifroù arabek indian astennet},
 				'armn' => q{niveroù armenianek},
 				'armnlow' => q{niveroù armenianek bihan},
 				'bali' => q{sifroù balinek},
 				'beng' => q{sifroù bengali},
 				'brah' => q{sifroù brahmi},
 				'cakm' => q{sifroù chakma},
 				'cham' => q{sifroù cham},
 				'cyrl' => q{niveroù kirillek},
 				'deva' => q{sifroù devanagari},
 				'diak' => q{sifroù Divehi Akuru},
 				'ethi' => q{niveroù etiopiat},
 				'fullwide' => q{sifroù led plaen},
 				'geor' => q{niveroù jorjianek},
 				'gong' => q{sifroù gondi Gunjala},
 				'gonm' => q{sifroù gondi Masaram},
 				'grek' => q{niveroù gresianek},
 				'greklow' => q{niveroù gresianek bihan},
 				'gujr' => q{sifroù gujarati},
 				'guru' => q{sifroù gurmukhi},
 				'hanidec' => q{niveroù sinaek dekvedennek},
 				'hans' => q{niveroù sinaek eeunaet},
 				'hansfin' => q{niveroù sinaek eeunaet an arcʼhant},
 				'hant' => q{niveroù sinaek hengounel},
 				'hantfin' => q{niveroù sinaek hengounel an arcʼhant},
 				'hebr' => q{niveroù hebraek},
 				'hmng' => q{sifroù Pahawh Hmong},
 				'hmnp' => q{sifroù Nyiakeng Puachue Hmong},
 				'java' => q{sifroù javanek},
 				'jpan' => q{niveroù japanek},
 				'jpanfin' => q{niveroù japanek an arcʼhant},
 				'kali' => q{sifroù Kayah Li},
 				'kawi' => q{sifroù kawi},
 				'khmr' => q{sifroù khmer},
 				'knda' => q{sifroù kanarek},
 				'lana' => q{sifroù Tai Tham Hora},
 				'lanatham' => q{sifroù Tai Tham Tham},
 				'laoo' => q{sifroù laosek},
 				'latn' => q{sifroù arabek ar Cʼhornôg},
 				'lepc' => q{sifroù lepcha},
 				'limb' => q{sifroù limbu},
 				'mathbold' => q{sifroù tev matematikoù},
 				'mlym' => q{sifroù malayalam},
 				'mong' => q{sifroù mongolek},
 				'mtei' => q{sifroù meitei mayek},
 				'mymr' => q{sifroù myanmar},
 				'mymrshan' => q{sifroù shan Myanmar},
 				'mymrtlng' => q{sifroù tai laing Myanmar},
 				'nkoo' => q{sifroù nʼko},
 				'olck' => q{sifroù ol chiki},
 				'orya' => q{sifroù oriya},
 				'osma' => q{sifroù osmanya},
 				'roman' => q{niveroù roman},
 				'romanlow' => q{niveroù roman bihan},
 				'shrd' => q{sifroù sharada},
 				'sind' => q{sifroù khudawadi},
 				'sinh' => q{sifroù singhalek lith},
 				'sora' => q{sifroù Sora Sompeng},
 				'sund' => q{sifroù sundanek},
 				'takr' => q{sifroù takri},
 				'talu' => q{sifroù tai lu nevez},
 				'taml' => q{niveroù tamilek hengounel},
 				'tamldec' => q{sifroù tamilek},
 				'telu' => q{sifroù telougou},
 				'thai' => q{sifroù thai},
 				'tibt' => q{sifroù tibetan},
 				'tirh' => q{sifroù tirhuta},
 				'tnsa' => q{sifroù tasek},
 				'vaii' => q{sifroù vai},
 				'wara' => q{sifroù warang},
 				'wcho' => q{sifroù wantcho},
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
			'metric' => q{metrek},
 			'UK' => q{RU},
 			'US' => q{SU},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'yezh : {0}',
 			'script' => 'skritur : {0}',
 			'region' => 'rannved : {0}',

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
			auxiliary => qr{[áàăâåäãā æ cç éèĕëē íìĭîïī óòŏôöøō œ q úŭûüū ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b {cʼh} {ch} d eê f g h i j k l m nñ o p r s t uù v w x y z]},
			numbers => qr{[  \- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
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
						'1' => q(yobe{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yobe{0}),
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
						'1' => q(ato{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(ato{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(santi{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(santi{0}),
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
					'10p-3' => {
						'1' => q(mili{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(mili{0}),
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
						'1' => q(yota{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(yota{0}),
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
						'few' => q({0} buanadur g),
						'many' => q({0} a vuanadurioù g),
						'name' => q(buanadur g),
						'one' => q({0} buanadur g),
						'other' => q({0} buanadur g),
						'two' => q({0} vuanadur g),
					},
					# Core Unit Identifier
					'g-force' => {
						'few' => q({0} buanadur g),
						'many' => q({0} a vuanadurioù g),
						'name' => q(buanadur g),
						'one' => q({0} buanadur g),
						'other' => q({0} buanadur g),
						'two' => q({0} vuanadur g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'few' => q({0} metr dre eilenn garrez),
						'many' => q({0} a vetroù dre eilenn garrez),
						'name' => q(metroù dre eilenn garrez),
						'one' => q({0} metr dre eilenn garrez),
						'other' => q({0} metr dre eilenn garrez),
						'two' => q({0} vetr dre eilenn garrez),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'few' => q({0} metr dre eilenn garrez),
						'many' => q({0} a vetroù dre eilenn garrez),
						'name' => q(metroù dre eilenn garrez),
						'one' => q({0} metr dre eilenn garrez),
						'other' => q({0} metr dre eilenn garrez),
						'two' => q({0} vetr dre eilenn garrez),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'few' => q({0} derez),
						'many' => q({0} a zerezioù),
						'name' => q(derezioù),
						'one' => q({0} derez),
						'other' => q({0} derez),
						'two' => q({0} zerez),
					},
					# Core Unit Identifier
					'degree' => {
						'few' => q({0} derez),
						'many' => q({0} a zerezioù),
						'name' => q(derezioù),
						'one' => q({0} derez),
						'other' => q({0} derez),
						'two' => q({0} zerez),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'few' => q({0} radian),
						'many' => q({0} a radianoù),
						'name' => q(radianoù),
						'one' => q({0} radian),
						'other' => q({0} radian),
						'two' => q({0} radian),
					},
					# Core Unit Identifier
					'radian' => {
						'few' => q({0} radian),
						'many' => q({0} a radianoù),
						'name' => q(radianoù),
						'one' => q({0} radian),
						'other' => q({0} radian),
						'two' => q({0} radian),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0} zro),
						'many' => q({0} a droioù),
						'name' => q(tro),
						'one' => q({0} dro),
						'other' => q({0} tro),
						'two' => q({0} dro),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0} zro),
						'many' => q({0} a droioù),
						'name' => q(tro),
						'one' => q({0} dro),
						'other' => q({0} tro),
						'two' => q({0} dro),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0} akr),
						'many' => q({0} a akroù),
						'name' => q(akroù),
						'one' => q({0} akr),
						'other' => q({0} akr),
						'two' => q({0} akr),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0} akr),
						'many' => q({0} a akroù),
						'name' => q(akroù),
						'one' => q({0} akr),
						'other' => q({0} akr),
						'two' => q({0} akr),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0} dounam),
						'many' => q({0} a zounamoù),
						'name' => q(dounamoù),
						'one' => q({0} dounam),
						'other' => q({0} dounam),
						'two' => q({0} zounam),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0} dounam),
						'many' => q({0} a zounamoù),
						'name' => q(dounamoù),
						'one' => q({0} dounam),
						'other' => q({0} dounam),
						'two' => q({0} zounam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'few' => q({0} hektar),
						'many' => q({0} a hektaroù),
						'name' => q(hektaroù),
						'one' => q({0} hektar),
						'other' => q({0} hektar),
						'two' => q({0} hektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'few' => q({0} hektar),
						'many' => q({0} a hektaroù),
						'name' => q(hektaroù),
						'one' => q({0} hektar),
						'other' => q({0} hektar),
						'two' => q({0} hektar),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'few' => q({0} santimetr karrez),
						'many' => q({0} a santimetroù karrez),
						'name' => q(santimetroù karrez),
						'one' => q({0} santimetr karrez),
						'other' => q({0} santimetr karrez),
						'per' => q({0} dre santimetr karrez),
						'two' => q({0} santimetr karrez),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'few' => q({0} santimetr karrez),
						'many' => q({0} a santimetroù karrez),
						'name' => q(santimetroù karrez),
						'one' => q({0} santimetr karrez),
						'other' => q({0} santimetr karrez),
						'per' => q({0} dre santimetr karrez),
						'two' => q({0} santimetr karrez),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0} zroatad karrez),
						'many' => q({0} a droatadoù karrez),
						'name' => q(troatadoù karrez),
						'one' => q({0} troatad karrez),
						'other' => q({0} troatad karrez),
						'two' => q({0} droatad karrez),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0} zroatad karrez),
						'many' => q({0} a droatadoù karrez),
						'name' => q(troatadoù karrez),
						'one' => q({0} troatad karrez),
						'other' => q({0} troatad karrez),
						'two' => q({0} droatad karrez),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0} meutad karrez),
						'many' => q({0} a veutadoù karrez),
						'name' => q(meutadoù karrez),
						'one' => q({0} meutad karrez),
						'other' => q({0} meutad karrez),
						'per' => q({0} dre veutad karrez),
						'two' => q({0} veutad karrez),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0} meutad karrez),
						'many' => q({0} a veutadoù karrez),
						'name' => q(meutadoù karrez),
						'one' => q({0} meutad karrez),
						'other' => q({0} meutad karrez),
						'per' => q({0} dre veutad karrez),
						'two' => q({0} veutad karrez),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'few' => q({0} c'hilometr karrez),
						'many' => q({0} a gilometroù karrez),
						'name' => q(kilometroù karrez),
						'one' => q({0} c'hilometr karrez),
						'other' => q({0} kilometr karrez),
						'per' => q({0} dre gilometr karrez),
						'two' => q({0} gilometr karrez),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'few' => q({0} c'hilometr karrez),
						'many' => q({0} a gilometroù karrez),
						'name' => q(kilometroù karrez),
						'one' => q({0} c'hilometr karrez),
						'other' => q({0} kilometr karrez),
						'per' => q({0} dre gilometr karrez),
						'two' => q({0} gilometr karrez),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'few' => q({0} metr karrez),
						'many' => q({0} a vetroù garrez),
						'name' => q(metroù karrez),
						'one' => q({0} metr karrez),
						'other' => q({0} metr karrez),
						'per' => q({0} dre vetr karrez),
						'two' => q({0} vetr karrez),
					},
					# Core Unit Identifier
					'square-meter' => {
						'few' => q({0} metr karrez),
						'many' => q({0} a vetroù garrez),
						'name' => q(metroù karrez),
						'one' => q({0} metr karrez),
						'other' => q({0} metr karrez),
						'per' => q({0} dre vetr karrez),
						'two' => q({0} vetr karrez),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0} miltir karrez),
						'many' => q({0} a viltirioù karrez),
						'name' => q(miltirioù karrez),
						'one' => q({0} miltir karrez),
						'other' => q({0} miltir karrez),
						'per' => q({0} dre viltir karrez),
						'two' => q({0} viltir karrez),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0} miltir karrez),
						'many' => q({0} a viltirioù karrez),
						'name' => q(miltirioù karrez),
						'one' => q({0} miltir karrez),
						'other' => q({0} miltir karrez),
						'per' => q({0} dre viltir karrez),
						'two' => q({0} viltir karrez),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0} yard karrez),
						'many' => q({0} a yardoù karrez),
						'name' => q(yardoù karrez),
						'one' => q({0} yard karrez),
						'other' => q({0} yard karrez),
						'two' => q({0} yard karrez),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0} yard karrez),
						'many' => q({0} a yardoù karrez),
						'name' => q(yardoù karrez),
						'one' => q({0} yard karrez),
						'other' => q({0} yard karrez),
						'two' => q({0} yard karrez),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'few' => q({0} c'harat),
						'many' => q({0} a garatoù),
						'name' => q(karatoù),
						'one' => q({0} c'harat),
						'other' => q({0} karat),
						'two' => q({0} garat),
					},
					# Core Unit Identifier
					'karat' => {
						'few' => q({0} c'harat),
						'many' => q({0} a garatoù),
						'name' => q(karatoù),
						'one' => q({0} c'harat),
						'other' => q({0} karat),
						'two' => q({0} garat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} milligramm dre zesilitr),
						'many' => q({0} a villigrammoù dre zesilitr),
						'name' => q(milligramm dre zesilitr),
						'one' => q({0} milligramm dre zesilitr),
						'other' => q({0} milligramm dre zesilitr),
						'two' => q({0} villigramm dre zesilitr),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} milligramm dre zesilitr),
						'many' => q({0} a villigrammoù dre zesilitr),
						'name' => q(milligramm dre zesilitr),
						'one' => q({0} milligramm dre zesilitr),
						'other' => q({0} milligramm dre zesilitr),
						'two' => q({0} villigramm dre zesilitr),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'few' => q({0} millimol dre litr),
						'many' => q({0} a villimoloù dre litr),
						'name' => q(millimoloù dre litr),
						'one' => q({0} millimol dre litr),
						'other' => q({0} millimol dre litr),
						'two' => q({0} villimol dre litr),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'few' => q({0} millimol dre litr),
						'many' => q({0} a villimoloù dre litr),
						'name' => q(millimoloù dre litr),
						'one' => q({0} millimol dre litr),
						'other' => q({0} millimol dre litr),
						'two' => q({0} villimol dre litr),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'few' => q({0} mol),
						'many' => q({0} a voloù),
						'name' => q(moloù),
						'one' => q({0} mol),
						'other' => q({0} mol),
						'two' => q({0} vol),
					},
					# Core Unit Identifier
					'mole' => {
						'few' => q({0} mol),
						'many' => q({0} a voloù),
						'name' => q(moloù),
						'one' => q({0} mol),
						'other' => q({0} mol),
						'two' => q({0} vol),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'few' => q({0} dre gant),
						'many' => q({0} dre gant),
						'name' => q(dre gant),
						'one' => q({0} dre gant),
						'other' => q({0} dre gant),
						'two' => q({0} dre gant),
					},
					# Core Unit Identifier
					'percent' => {
						'few' => q({0} dre gant),
						'many' => q({0} dre gant),
						'name' => q(dre gant),
						'one' => q({0} dre gant),
						'other' => q({0} dre gant),
						'two' => q({0} dre gant),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'few' => q({0} dre vil),
						'many' => q({0} dre vil),
						'name' => q(dre vil),
						'one' => q({0} dre vil),
						'other' => q({0} dre vil),
						'two' => q({0} dre vil),
					},
					# Core Unit Identifier
					'permille' => {
						'few' => q({0} dre vil),
						'many' => q({0} dre vil),
						'name' => q(dre vil),
						'one' => q({0} dre vil),
						'other' => q({0} dre vil),
						'two' => q({0} dre vil),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'few' => q({0} dre zek mil),
						'many' => q({0} dre zek mil),
						'name' => q(dre zek mil),
						'one' => q({0} dre zek mil),
						'other' => q({0} dre zek mil),
						'two' => q({0} dre zek mil),
					},
					# Core Unit Identifier
					'permyriad' => {
						'few' => q({0} dre zek mil),
						'many' => q({0} dre zek mil),
						'name' => q(dre zek mil),
						'one' => q({0} dre zek mil),
						'other' => q({0} dre zek mil),
						'two' => q({0} dre zek mil),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} litr dre 100 kilometr),
						'many' => q({0} a litroù dre 100 kilometr),
						'name' => q(litroù dre 100 kilometr),
						'one' => q({0} litr dre 100 kilometr),
						'other' => q({0} litr dre 100 kilometr),
						'two' => q({0} litr dre 100 kilometr),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} litr dre 100 kilometr),
						'many' => q({0} a litroù dre 100 kilometr),
						'name' => q(litroù dre 100 kilometr),
						'one' => q({0} litr dre 100 kilometr),
						'other' => q({0} litr dre 100 kilometr),
						'two' => q({0} litr dre 100 kilometr),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} litr dre gilometr),
						'many' => q({0} a litroù dre gilometr),
						'name' => q(litroù dre gilometr),
						'one' => q({0} litr dre gilometr),
						'other' => q({0} litr dre gilometr),
						'two' => q({0} litr dre gilometr),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} litr dre gilometr),
						'many' => q({0} a litroù dre gilometr),
						'name' => q(litroù dre gilometr),
						'one' => q({0} litr dre gilometr),
						'other' => q({0} litr dre gilometr),
						'two' => q({0} litr dre gilometr),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} miltir dre c'hallon),
						'many' => q({0} a viltirioù dre c'hallon),
						'name' => q(miltirioù dre cʼhallon),
						'one' => q({0} miltir dre c'hallon),
						'other' => q({0} miltir dre c'hallon),
						'two' => q({0} viltir dre c'hallon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} miltir dre c'hallon),
						'many' => q({0} a viltirioù dre c'hallon),
						'name' => q(miltirioù dre cʼhallon),
						'one' => q({0} miltir dre c'hallon),
						'other' => q({0} miltir dre c'hallon),
						'two' => q({0} viltir dre c'hallon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} miltir dre cʼhallon impalaerel),
						'many' => q({0} a viltirioù dre cʼhallon impalaerel),
						'name' => q(miltirioù dre cʼhallon impalaerel),
						'one' => q({0} miltir dre cʼhallon impalaerel),
						'other' => q({0} miltir dre cʼhallon impalaerel),
						'two' => q({0} viltir dre cʼhallon impalaerel),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} miltir dre cʼhallon impalaerel),
						'many' => q({0} a viltirioù dre cʼhallon impalaerel),
						'name' => q(miltirioù dre cʼhallon impalaerel),
						'one' => q({0} miltir dre cʼhallon impalaerel),
						'other' => q({0} miltir dre cʼhallon impalaerel),
						'two' => q({0} viltir dre cʼhallon impalaerel),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} Reter),
						'north' => q({0} Norzh),
						'south' => q({0} Su),
						'west' => q({0} Kornôg),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} Reter),
						'north' => q({0} Norzh),
						'south' => q({0} Su),
						'west' => q({0} Kornôg),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'few' => q({0} bit),
						'many' => q({0} a vitoù),
						'name' => q(bitoù),
						'one' => q({0} bit),
						'other' => q({0} bit),
						'two' => q({0} vit),
					},
					# Core Unit Identifier
					'bit' => {
						'few' => q({0} bit),
						'many' => q({0} a vitoù),
						'name' => q(bitoù),
						'one' => q({0} bit),
						'other' => q({0} bit),
						'two' => q({0} vit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0} okted),
						'many' => q({0} a oktedoù),
						'name' => q(oktedoù),
						'one' => q({0} okted),
						'other' => q({0} okted),
						'two' => q({0} okted),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} okted),
						'many' => q({0} a oktedoù),
						'name' => q(oktedoù),
						'one' => q({0} okted),
						'other' => q({0} okted),
						'two' => q({0} okted),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'few' => q({0} gigabit),
						'many' => q({0} a c'higabitoù),
						'name' => q(gigabitoù),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
						'two' => q({0} c'higabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'few' => q({0} gigabit),
						'many' => q({0} a c'higabitoù),
						'name' => q(gigabitoù),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
						'two' => q({0} c'higabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'few' => q({0} gigaokted),
						'many' => q({0} a c'higaoktedoù),
						'name' => q(gigaoktedoù),
						'one' => q({0} gigaokted),
						'other' => q({0} gigaokted),
						'two' => q({0} c'higaokted),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'few' => q({0} gigaokted),
						'many' => q({0} a c'higaoktedoù),
						'name' => q(gigaoktedoù),
						'one' => q({0} gigaokted),
						'other' => q({0} gigaokted),
						'two' => q({0} c'higaokted),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'few' => q({0} c'hilobit),
						'many' => q({0} a gilobitoù),
						'name' => q(kilobitoù),
						'one' => q({0} c'hilobit),
						'other' => q({0} kilobit),
						'two' => q({0} gilobit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'few' => q({0} c'hilobit),
						'many' => q({0} a gilobitoù),
						'name' => q(kilobitoù),
						'one' => q({0} c'hilobit),
						'other' => q({0} kilobit),
						'two' => q({0} gilobit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'few' => q({0} c'hilookted),
						'many' => q({0} a gilooktedoù),
						'name' => q(kilooktedoù),
						'one' => q({0} c'hilookted),
						'other' => q({0} kilookted),
						'two' => q({0} gilookted),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'few' => q({0} c'hilookted),
						'many' => q({0} a gilooktedoù),
						'name' => q(kilooktedoù),
						'one' => q({0} c'hilookted),
						'other' => q({0} kilookted),
						'two' => q({0} gilookted),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'few' => q({0} megabit),
						'many' => q({0} a vegabitoù),
						'name' => q(megabitoù),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
						'two' => q({0} vegabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'few' => q({0} megabit),
						'many' => q({0} a vegabitoù),
						'name' => q(megabitoù),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
						'two' => q({0} vegabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'few' => q({0} megaokted),
						'many' => q({0} a vegaoktedoù),
						'name' => q(megaoktedoù),
						'one' => q({0} megaokted),
						'other' => q({0} megaokted),
						'two' => q({0} vegaokted),
					},
					# Core Unit Identifier
					'megabyte' => {
						'few' => q({0} megaokted),
						'many' => q({0} a vegaoktedoù),
						'name' => q(megaoktedoù),
						'one' => q({0} megaokted),
						'other' => q({0} megaokted),
						'two' => q({0} vegaokted),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'few' => q({0} fetaokted),
						'many' => q({0} a betaoktedoù),
						'name' => q(petaoktedoù),
						'one' => q({0} petaokted),
						'other' => q({0} petaokted),
						'two' => q({0} betaokted),
					},
					# Core Unit Identifier
					'petabyte' => {
						'few' => q({0} fetaokted),
						'many' => q({0} a betaoktedoù),
						'name' => q(petaoktedoù),
						'one' => q({0} petaokted),
						'other' => q({0} petaokted),
						'two' => q({0} betaokted),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'few' => q({0} zerabit),
						'many' => q({0} a derabitoù),
						'name' => q(terabitoù),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
						'two' => q({0} derabit),
					},
					# Core Unit Identifier
					'terabit' => {
						'few' => q({0} zerabit),
						'many' => q({0} a derabitoù),
						'name' => q(terabitoù),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
						'two' => q({0} derabit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'few' => q({0} zeraokted),
						'many' => q({0} a deraoktedoù),
						'name' => q(teraoktedoù),
						'one' => q({0} teraokted),
						'other' => q({0} teraokted),
						'two' => q({0} deraokted),
					},
					# Core Unit Identifier
					'terabyte' => {
						'few' => q({0} zeraokted),
						'many' => q({0} a deraoktedoù),
						'name' => q(teraoktedoù),
						'one' => q({0} teraokted),
						'other' => q({0} teraokted),
						'two' => q({0} deraokted),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} c'hantved),
						'many' => q({0} a gantvedoù),
						'name' => q(kantvedoù),
						'one' => q({0} c'hantved),
						'other' => q({0} kantved),
						'two' => q({0} gantved),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} c'hantved),
						'many' => q({0} a gantvedoù),
						'name' => q(kantvedoù),
						'one' => q({0} c'hantved),
						'other' => q({0} kantved),
						'two' => q({0} gantved),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} deiz),
						'many' => q({0} a zeizioù),
						'name' => q(deizioù),
						'one' => q({0} deiz),
						'other' => q({0} deiz),
						'per' => q({0} dre zeiz),
						'two' => q({0} zeiz),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} deiz),
						'many' => q({0} a zeizioù),
						'name' => q(deizioù),
						'one' => q({0} deiz),
						'other' => q({0} deiz),
						'per' => q({0} dre zeiz),
						'two' => q({0} zeiz),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0} dekvloavezhiad),
						'many' => q({0} a zekvloavezhiadoù),
						'name' => q(dekvloavezhiadoù),
						'one' => q({0} dekvloavezhiad),
						'other' => q({0} dekvloavezhiad),
						'two' => q({0} zekvloavezhiad),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0} dekvloavezhiad),
						'many' => q({0} a zekvloavezhiadoù),
						'name' => q(dekvloavezhiadoù),
						'one' => q({0} dekvloavezhiad),
						'other' => q({0} dekvloavezhiad),
						'two' => q({0} zekvloavezhiad),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'few' => q({0} eur),
						'many' => q({0} a eurioù),
						'name' => q(eurioù),
						'one' => q({0} eur),
						'other' => q({0} eur),
						'per' => q({0} dre eur),
						'two' => q({0} eur),
					},
					# Core Unit Identifier
					'hour' => {
						'few' => q({0} eur),
						'many' => q({0} a eurioù),
						'name' => q(eurioù),
						'one' => q({0} eur),
						'other' => q({0} eur),
						'per' => q({0} dre eur),
						'two' => q({0} eur),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'few' => q({0} mikroeilenn),
						'many' => q({0} a vikroeilennoù),
						'name' => q(mikroeilennoù),
						'one' => q({0} mikroeilenn),
						'other' => q({0} mikroeilenn),
						'two' => q({0} vikroeilenn),
					},
					# Core Unit Identifier
					'microsecond' => {
						'few' => q({0} mikroeilenn),
						'many' => q({0} a vikroeilennoù),
						'name' => q(mikroeilennoù),
						'one' => q({0} mikroeilenn),
						'other' => q({0} mikroeilenn),
						'two' => q({0} vikroeilenn),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'few' => q({0} milieilenn),
						'many' => q({0} a vilieilennoù),
						'name' => q(milieilennoù),
						'one' => q({0} milieilenn),
						'other' => q({0} milieilenn),
						'two' => q({0} vilieilenn),
					},
					# Core Unit Identifier
					'millisecond' => {
						'few' => q({0} milieilenn),
						'many' => q({0} a vilieilennoù),
						'name' => q(milieilennoù),
						'one' => q({0} milieilenn),
						'other' => q({0} milieilenn),
						'two' => q({0} vilieilenn),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} munut),
						'many' => q({0} a vunutoù),
						'name' => q(munutoù),
						'one' => q({0} munut),
						'other' => q({0} munut),
						'per' => q({0} dre vunut),
						'two' => q({0} vunut),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} munut),
						'many' => q({0} a vunutoù),
						'name' => q(munutoù),
						'one' => q({0} munut),
						'other' => q({0} munut),
						'per' => q({0} dre vunut),
						'two' => q({0} vunut),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} miz),
						'many' => q({0} a vizioù),
						'name' => q(mizioù),
						'one' => q({0} miz),
						'other' => q({0} miz),
						'per' => q({0} dre viz),
						'two' => q({0} viz),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} miz),
						'many' => q({0} a vizioù),
						'name' => q(mizioù),
						'one' => q({0} miz),
						'other' => q({0} miz),
						'per' => q({0} dre viz),
						'two' => q({0} viz),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'few' => q({0} nanoeilenn),
						'many' => q({0} a nanoeilennoù),
						'name' => q(nanoeilennoù),
						'one' => q({0} nanoeilenn),
						'other' => q({0} nanoeilenn),
						'two' => q({0} nanoeilenn),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'few' => q({0} nanoeilenn),
						'many' => q({0} a nanoeilennoù),
						'name' => q(nanoeilennoù),
						'one' => q({0} nanoeilenn),
						'other' => q({0} nanoeilenn),
						'two' => q({0} nanoeilenn),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} zrimiziad),
						'many' => q({0} a drimiziadoù),
						'name' => q(trimiziadoù),
						'one' => q({0} trimiziad),
						'other' => q({0} trimiziad),
						'per' => q({0} dre drimiziad),
						'two' => q({0} drimiziad),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} zrimiziad),
						'many' => q({0} a drimiziadoù),
						'name' => q(trimiziadoù),
						'one' => q({0} trimiziad),
						'other' => q({0} trimiziad),
						'per' => q({0} dre drimiziad),
						'two' => q({0} drimiziad),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} eilenn),
						'many' => q({0} a eilennoù),
						'name' => q(eilennoù),
						'one' => q({0} eilenn),
						'other' => q({0} eilenn),
						'per' => q({0} dre eilenn),
						'two' => q({0} eilenn),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} eilenn),
						'many' => q({0} a eilennoù),
						'name' => q(eilennoù),
						'one' => q({0} eilenn),
						'other' => q({0} eilenn),
						'per' => q({0} dre eilenn),
						'two' => q({0} eilenn),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} sizhun),
						'many' => q({0} a sizhunioù),
						'name' => q(sizhunioù),
						'one' => q({0} sizhun),
						'other' => q({0} sizhun),
						'per' => q({0} dre sizhun),
						'two' => q({0} sizhun),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} sizhun),
						'many' => q({0} a sizhunioù),
						'name' => q(sizhunioù),
						'one' => q({0} sizhun),
						'other' => q({0} sizhun),
						'per' => q({0} dre sizhun),
						'two' => q({0} sizhun),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} bloaz),
						'many' => q({0} a vloazioù),
						'name' => q(bloazioù),
						'one' => q({0} bloaz),
						'other' => q({0} vloaz),
						'per' => q({0} dre vloaz),
						'two' => q({0} vloaz),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} bloaz),
						'many' => q({0} a vloazioù),
						'name' => q(bloazioù),
						'one' => q({0} bloaz),
						'other' => q({0} vloaz),
						'per' => q({0} dre vloaz),
						'two' => q({0} vloaz),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'few' => q({0} amper),
						'many' => q({0} a amperoù),
						'name' => q(amperoù),
						'one' => q({0} amper),
						'other' => q({0} amper),
						'two' => q({0} amper),
					},
					# Core Unit Identifier
					'ampere' => {
						'few' => q({0} amper),
						'many' => q({0} a amperoù),
						'name' => q(amperoù),
						'one' => q({0} amper),
						'other' => q({0} amper),
						'two' => q({0} amper),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'few' => q({0} miliamper),
						'many' => q({0} a viliamperoù),
						'name' => q(miliamperoù),
						'one' => q({0} miliamper),
						'other' => q({0} miliamper),
						'two' => q({0} viliamper),
					},
					# Core Unit Identifier
					'milliampere' => {
						'few' => q({0} miliamper),
						'many' => q({0} a viliamperoù),
						'name' => q(miliamperoù),
						'one' => q({0} miliamper),
						'other' => q({0} miliamper),
						'two' => q({0} viliamper),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'few' => q({0} ohm),
						'many' => q({0} a ohmoù),
						'name' => q(ohmoù),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
						'two' => q({0} ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'few' => q({0} ohm),
						'many' => q({0} a ohmoù),
						'name' => q(ohmoù),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
						'two' => q({0} ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'few' => q({0} volt),
						'many' => q({0} a voltoù),
						'name' => q(voltoù),
						'one' => q({0} volt),
						'other' => q({0} volt),
						'two' => q({0} volt),
					},
					# Core Unit Identifier
					'volt' => {
						'few' => q({0} volt),
						'many' => q({0} a voltoù),
						'name' => q(voltoù),
						'one' => q({0} volt),
						'other' => q({0} volt),
						'two' => q({0} volt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'few' => q({0} British thermal unit),
						'many' => q({0} British thermal unit),
						'name' => q(British thermal units),
						'one' => q({0} British thermal unit),
						'other' => q({0} British thermal unit),
						'two' => q({0} vBritish thermal unit),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'few' => q({0} British thermal unit),
						'many' => q({0} British thermal unit),
						'name' => q(British thermal units),
						'one' => q({0} British thermal unit),
						'other' => q({0} British thermal unit),
						'two' => q({0} vBritish thermal unit),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'few' => q({0} c'halorienn),
						'many' => q({0} a galoriennoù),
						'name' => q(kaloriennoù),
						'one' => q({0} galorienn),
						'other' => q({0} kalorienn),
						'two' => q({0} galorienn),
					},
					# Core Unit Identifier
					'calorie' => {
						'few' => q({0} c'halorienn),
						'many' => q({0} a galoriennoù),
						'name' => q(kaloriennoù),
						'one' => q({0} galorienn),
						'other' => q({0} kalorienn),
						'two' => q({0} galorienn),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'few' => q({0} elektronvolt),
						'many' => q({0} a elektronvoltoù),
						'name' => q(elektronvoltoù),
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvolt),
						'two' => q({0} elektronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'few' => q({0} elektronvolt),
						'many' => q({0} a elektronvoltoù),
						'name' => q(elektronvoltoù),
						'one' => q({0} elektronvolt),
						'other' => q({0} elektronvolt),
						'two' => q({0} elektronvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} c'halorienn vras),
						'many' => q({0} a galoriennoù bras),
						'name' => q(kaloriennoù bras),
						'one' => q({0} galorienn vras),
						'other' => q({0} kalorienn vras),
						'two' => q({0} galorienn vras),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} c'halorienn vras),
						'many' => q({0} a galoriennoù bras),
						'name' => q(kaloriennoù bras),
						'one' => q({0} galorienn vras),
						'other' => q({0} kalorienn vras),
						'two' => q({0} galorienn vras),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'few' => q({0} joul),
						'many' => q({0} a jouloù),
						'name' => q(jouloù),
						'one' => q({0} joul),
						'other' => q({0} joul),
						'two' => q({0} joul),
					},
					# Core Unit Identifier
					'joule' => {
						'few' => q({0} joul),
						'many' => q({0} a jouloù),
						'name' => q(jouloù),
						'one' => q({0} joul),
						'other' => q({0} joul),
						'two' => q({0} joul),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'few' => q({0} c'hilokalorienn),
						'many' => q({0} a gilokaloriennoù),
						'name' => q(kilokaloriennoù),
						'one' => q({0} gilokalorienn),
						'other' => q({0} kilokalorienn),
						'two' => q({0} gilokalorienn),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'few' => q({0} c'hilokalorienn),
						'many' => q({0} a gilokaloriennoù),
						'name' => q(kilokaloriennoù),
						'one' => q({0} gilokalorienn),
						'other' => q({0} kilokalorienn),
						'two' => q({0} gilokalorienn),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'few' => q({0} c'hilojoul),
						'many' => q({0} a gilojouloù),
						'name' => q(kilojouloù),
						'one' => q({0} c'hilojoul),
						'other' => q({0} kilojoul),
						'two' => q({0} gilojoul),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'few' => q({0} c'hilojoul),
						'many' => q({0} a gilojouloù),
						'name' => q(kilojouloù),
						'one' => q({0} c'hilojoul),
						'other' => q({0} kilojoul),
						'two' => q({0} gilojoul),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'few' => q({0} c'hilowatt-eur),
						'many' => q({0} a gilowattoù-eurioù),
						'name' => q(kilowattoù-eurioù),
						'one' => q({0} c'hilowatt-eur),
						'other' => q({0} kilowatt-eur),
						'two' => q({0} gilowatt-eur),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'few' => q({0} c'hilowatt-eur),
						'many' => q({0} a gilowattoù-eurioù),
						'name' => q(kilowattoù-eurioù),
						'one' => q({0} c'hilowatt-eur),
						'other' => q({0} kilowatt-eur),
						'two' => q({0} gilowatt-eur),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'few' => q({0} zermienn),
						'many' => q({0} a dermiennoù),
						'name' => q(termiennoù SU),
						'one' => q({0} dermienn),
						'other' => q({0} termienn),
						'two' => q({0} dermienn),
					},
					# Core Unit Identifier
					'therm-us' => {
						'few' => q({0} zermienn),
						'many' => q({0} a dermiennoù),
						'name' => q(termiennoù SU),
						'one' => q({0} dermienn),
						'other' => q({0} termienn),
						'two' => q({0} dermienn),
					},
					# Long Unit Identifier
					'force-newton' => {
						'few' => q({0} newton),
						'many' => q({0} a newtonoù),
						'name' => q(newtonoù),
						'one' => q({0} newton),
						'other' => q({0} newton),
						'two' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'few' => q({0} newton),
						'many' => q({0} a newtonoù),
						'name' => q(newtonoù),
						'one' => q({0} newton),
						'other' => q({0} newton),
						'two' => q({0} newton),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'few' => q({0} gigahertz),
						'many' => q({0} a c'higahertzoù),
						'name' => q(gigahertzoù),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
						'two' => q({0} c'higahertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'few' => q({0} gigahertz),
						'many' => q({0} a c'higahertzoù),
						'name' => q(gigahertzoù),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
						'two' => q({0} c'higahertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'few' => q({0} hertz),
						'many' => q({0} a hertzoù),
						'name' => q(hertzoù),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
						'two' => q({0} hertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'few' => q({0} hertz),
						'many' => q({0} a hertzoù),
						'name' => q(hertzoù),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
						'two' => q({0} hertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'few' => q({0} c'hilohertz),
						'many' => q({0} a gilohertzoù),
						'name' => q(kilohertzoù),
						'one' => q({0} c'hilohertz),
						'other' => q({0} kilohertz),
						'two' => q({0} gilohertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'few' => q({0} c'hilohertz),
						'many' => q({0} a gilohertzoù),
						'name' => q(kilohertzoù),
						'one' => q({0} c'hilohertz),
						'other' => q({0} kilohertz),
						'two' => q({0} gilohertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'few' => q({0} megahertz),
						'many' => q({0} a vegahertzoù),
						'name' => q(megahertzoù),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
						'two' => q({0} vegahertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'few' => q({0} megahertz),
						'many' => q({0} a vegahertzoù),
						'name' => q(megahertzoù),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
						'two' => q({0} vegahertz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'few' => q({0} fik),
						'many' => q({0} a bikoù),
						'one' => q({0} pik),
						'other' => q({0} pik),
						'two' => q({0} bik),
					},
					# Core Unit Identifier
					'dot' => {
						'few' => q({0} fik),
						'many' => q({0} a bikoù),
						'one' => q({0} pik),
						'other' => q({0} pik),
						'two' => q({0} bik),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} fik dre santimetr),
						'many' => q({0} a bikoù dre santimetr),
						'name' => q(pikoù dre santimetr),
						'one' => q({0} pik dre santimetr),
						'other' => q({0} pik dre santimetr),
						'two' => q({0} bik dre santimetr),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} fik dre santimetr),
						'many' => q({0} a bikoù dre santimetr),
						'name' => q(pikoù dre santimetr),
						'one' => q({0} pik dre santimetr),
						'other' => q({0} pik dre santimetr),
						'two' => q({0} bik dre santimetr),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} fik dre veutad),
						'many' => q({0} a bikoù dre veutad),
						'name' => q(pikoù dre veutad),
						'one' => q({0} pik dre veutad),
						'other' => q({0} pik dre veutad),
						'two' => q({0} bik dre veutad),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} fik dre veutad),
						'many' => q({0} a bikoù dre veutad),
						'name' => q(pikoù dre veutad),
						'one' => q({0} pik dre veutad),
						'other' => q({0} pik dre veutad),
						'two' => q({0} bik dre veutad),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'few' => q({0} esaouenn em),
						'many' => q({0} a esaouennoù em),
						'name' => q(esaouenn em),
						'one' => q({0} esaouenn em),
						'other' => q({0} esaouenn em),
						'two' => q({0} esaouenn em),
					},
					# Core Unit Identifier
					'em' => {
						'few' => q({0} esaouenn em),
						'many' => q({0} a esaouennoù em),
						'name' => q(esaouenn em),
						'one' => q({0} esaouenn em),
						'other' => q({0} esaouenn em),
						'two' => q({0} esaouenn em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'few' => q({0} megapiksel),
						'many' => q({0} a vegapikselioù),
						'name' => q(megapikselioù),
						'one' => q({0} megapiksel),
						'other' => q({0} megapiksel),
						'two' => q({0} vegapiksel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'few' => q({0} megapiksel),
						'many' => q({0} a vegapikselioù),
						'name' => q(megapikselioù),
						'one' => q({0} megapiksel),
						'other' => q({0} megapiksel),
						'two' => q({0} vegapiksel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'few' => q({0} fiksel),
						'many' => q({0} a bikselioù),
						'name' => q(pikselioù),
						'one' => q({0} piksel),
						'other' => q({0} piksel),
						'two' => q({0} biksel),
					},
					# Core Unit Identifier
					'pixel' => {
						'few' => q({0} fiksel),
						'many' => q({0} a bikselioù),
						'name' => q(pikselioù),
						'one' => q({0} piksel),
						'other' => q({0} piksel),
						'two' => q({0} biksel),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'few' => q({0} fiksel dre santimetr),
						'many' => q({0} a bikselioù dre santimetr),
						'name' => q(pikselioù dre santimetr),
						'one' => q({0} piksel dre santimetr),
						'other' => q({0} piksel dre santimetr),
						'two' => q({0} biksel dre santimetr),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'few' => q({0} fiksel dre santimetr),
						'many' => q({0} a bikselioù dre santimetr),
						'name' => q(pikselioù dre santimetr),
						'one' => q({0} piksel dre santimetr),
						'other' => q({0} piksel dre santimetr),
						'two' => q({0} biksel dre santimetr),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'few' => q({0} fiksel dre veutad),
						'many' => q({0} a pikselioù dre veutad),
						'name' => q(pikselioù dre veutad),
						'one' => q({0} piksel dre veutad),
						'other' => q({0} piksel dre veutad),
						'two' => q({0} biksel dre veutad),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'few' => q({0} fiksel dre veutad),
						'many' => q({0} a pikselioù dre veutad),
						'name' => q(pikselioù dre veutad),
						'one' => q({0} piksel dre veutad),
						'other' => q({0} piksel dre veutad),
						'two' => q({0} biksel dre veutad),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} unanenn steredoniel),
						'many' => q({0} a unanennoù steredoniel),
						'name' => q(unanennoù steredoniel),
						'one' => q({0} unanenn steredoniel),
						'other' => q({0} unanenn steredoniel),
						'two' => q({0} unanenn steredoniel),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} unanenn steredoniel),
						'many' => q({0} a unanennoù steredoniel),
						'name' => q(unanennoù steredoniel),
						'one' => q({0} unanenn steredoniel),
						'other' => q({0} unanenn steredoniel),
						'two' => q({0} unanenn steredoniel),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'few' => q({0} santimetr),
						'many' => q({0} a santimetroù),
						'name' => q(santimetroù),
						'one' => q({0} santimetr),
						'other' => q({0} santimetr),
						'per' => q({0} dre santimetr),
						'two' => q({0} santimetr),
					},
					# Core Unit Identifier
					'centimeter' => {
						'few' => q({0} santimetr),
						'many' => q({0} a santimetroù),
						'name' => q(santimetroù),
						'one' => q({0} santimetr),
						'other' => q({0} santimetr),
						'per' => q({0} dre santimetr),
						'two' => q({0} santimetr),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'few' => q({0} desimetr),
						'many' => q({0} a zesimetroù),
						'name' => q(desimetroù),
						'one' => q({0} desimetr),
						'other' => q({0} desimetr),
						'two' => q({0} zesimetr),
					},
					# Core Unit Identifier
					'decimeter' => {
						'few' => q({0} desimetr),
						'many' => q({0} a zesimetroù),
						'name' => q(desimetroù),
						'one' => q({0} desimetr),
						'other' => q({0} desimetr),
						'two' => q({0} zesimetr),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'few' => q({0} skin douar),
						'many' => q({0} a skinoù douar),
						'name' => q(skin douar),
						'one' => q({0} skin douar),
						'other' => q({0} skin douar),
						'two' => q({0} skin douar),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'few' => q({0} skin douar),
						'many' => q({0} a skinoù douar),
						'name' => q(skin douar),
						'one' => q({0} skin douar),
						'other' => q({0} skin douar),
						'two' => q({0} skin douar),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'few' => q({0} gourhedad),
						'many' => q({0} a c'hourhedadoù),
						'name' => q(gourhedadoù),
						'one' => q({0} gourhedad),
						'other' => q({0} gourhedad),
						'two' => q({0} c'hourhedad),
					},
					# Core Unit Identifier
					'fathom' => {
						'few' => q({0} gourhedad),
						'many' => q({0} a c'hourhedadoù),
						'name' => q(gourhedadoù),
						'one' => q({0} gourhedad),
						'other' => q({0} gourhedad),
						'two' => q({0} c'hourhedad),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0} zroatad),
						'many' => q({0} a droatadoù),
						'name' => q(troatadoù),
						'one' => q({0} troatad),
						'other' => q({0} troatad),
						'per' => q({0} dre droatad),
						'two' => q({0} droatad),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0} zroatad),
						'many' => q({0} a droatadoù),
						'name' => q(troatadoù),
						'one' => q({0} troatad),
						'other' => q({0} troatad),
						'per' => q({0} dre droatad),
						'two' => q({0} droatad),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'few' => q({0} furlong),
						'many' => q({0} a furlongoù),
						'name' => q(furlongoù),
						'one' => q({0} furlong),
						'other' => q({0} furlong),
						'two' => q({0} furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'few' => q({0} furlong),
						'many' => q({0} a furlongoù),
						'name' => q(furlongoù),
						'one' => q({0} furlong),
						'other' => q({0} furlong),
						'two' => q({0} furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0} meutad),
						'many' => q({0} a veutadoù),
						'name' => q(meutadoù),
						'one' => q({0} meutad),
						'other' => q({0} meutad),
						'per' => q({0} dre veutad),
						'two' => q({0} veutad),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0} meutad),
						'many' => q({0} a veutadoù),
						'name' => q(meutadoù),
						'one' => q({0} meutad),
						'other' => q({0} meutad),
						'per' => q({0} dre veutad),
						'two' => q({0} veutad),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'few' => q({0} c'hilometr),
						'many' => q({0} a gilometroù),
						'name' => q(kilometroù),
						'one' => q({0} c'hilometr),
						'other' => q({0} kilometr),
						'per' => q({0} dre gilometr),
						'two' => q({0} gilometr),
					},
					# Core Unit Identifier
					'kilometer' => {
						'few' => q({0} c'hilometr),
						'many' => q({0} a gilometroù),
						'name' => q(kilometroù),
						'one' => q({0} c'hilometr),
						'other' => q({0} kilometr),
						'per' => q({0} dre gilometr),
						'two' => q({0} gilometr),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} bloavezh-gouloù),
						'many' => q({0} a vloavezhioù-gouloù),
						'name' => q(bloavezhioù-gouloù),
						'one' => q({0} bloavezh-gouloù),
						'other' => q({0} bloavezh-gouloù),
						'two' => q({0} vloavezh-gouloù),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} bloavezh-gouloù),
						'many' => q({0} a vloavezhioù-gouloù),
						'name' => q(bloavezhioù-gouloù),
						'one' => q({0} bloavezh-gouloù),
						'other' => q({0} bloavezh-gouloù),
						'two' => q({0} vloavezh-gouloù),
					},
					# Long Unit Identifier
					'length-meter' => {
						'few' => q({0} metr),
						'many' => q({0} a vetroù),
						'name' => q(metroù),
						'one' => q({0} metr),
						'other' => q({0} metr),
						'per' => q({0} dre vetr),
						'two' => q({0} vetr),
					},
					# Core Unit Identifier
					'meter' => {
						'few' => q({0} metr),
						'many' => q({0} a vetroù),
						'name' => q(metroù),
						'one' => q({0} metr),
						'other' => q({0} metr),
						'per' => q({0} dre vetr),
						'two' => q({0} vetr),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'few' => q({0} mikrometr),
						'many' => q({0} a vikrometroù),
						'name' => q(mikrometroù),
						'one' => q({0} mikrometr),
						'other' => q({0} mikrometr),
						'two' => q({0} vikrometr),
					},
					# Core Unit Identifier
					'micrometer' => {
						'few' => q({0} mikrometr),
						'many' => q({0} a vikrometroù),
						'name' => q(mikrometroù),
						'one' => q({0} mikrometr),
						'other' => q({0} mikrometr),
						'two' => q({0} vikrometr),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} miltir),
						'many' => q({0} a viltirioù),
						'name' => q(miltirioù),
						'one' => q({0} miltir),
						'other' => q({0} miltir),
						'two' => q({0} viltir),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} miltir),
						'many' => q({0} a viltirioù),
						'name' => q(miltirioù),
						'one' => q({0} miltir),
						'other' => q({0} miltir),
						'two' => q({0} viltir),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'few' => q({0} miltir skandinaviat),
						'many' => q({0} a viltirioù skandinaviat),
						'name' => q(miltirioù skandinaviat),
						'one' => q({0} miltir skandinaviat),
						'other' => q({0} miltir skandinaviat),
						'two' => q({0} miltir skandinaviat),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'few' => q({0} miltir skandinaviat),
						'many' => q({0} a viltirioù skandinaviat),
						'name' => q(miltirioù skandinaviat),
						'one' => q({0} miltir skandinaviat),
						'other' => q({0} miltir skandinaviat),
						'two' => q({0} miltir skandinaviat),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'few' => q({0} milimetr),
						'many' => q({0} a vilimetroù),
						'name' => q(milimetroù),
						'one' => q({0} milimetr),
						'other' => q({0} milimetr),
						'two' => q({0} vilimetr),
					},
					# Core Unit Identifier
					'millimeter' => {
						'few' => q({0} milimetr),
						'many' => q({0} a vilimetroù),
						'name' => q(milimetroù),
						'one' => q({0} milimetr),
						'other' => q({0} milimetr),
						'two' => q({0} vilimetr),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'few' => q({0} nanometr),
						'many' => q({0} a nanometroù),
						'name' => q(nanometroù),
						'one' => q({0} nanometr),
						'other' => q({0} nanometr),
						'two' => q({0} nanometr),
					},
					# Core Unit Identifier
					'nanometer' => {
						'few' => q({0} nanometr),
						'many' => q({0} a nanometroù),
						'name' => q(nanometroù),
						'one' => q({0} nanometr),
						'other' => q({0} nanometr),
						'two' => q({0} nanometr),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0} milmor),
						'many' => q({0} a vilmorioù),
						'name' => q(milmorioù),
						'one' => q({0} milmor),
						'other' => q({0} milmor),
						'two' => q({0} vilmor),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} milmor),
						'many' => q({0} a vilmorioù),
						'name' => q(milmorioù),
						'one' => q({0} milmor),
						'other' => q({0} milmor),
						'two' => q({0} vilmor),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'few' => q({0} farsek),
						'many' => q({0} a barsekoù),
						'name' => q(parsekoù),
						'one' => q({0} parsek),
						'other' => q({0} parsek),
						'two' => q({0} barsek),
					},
					# Core Unit Identifier
					'parsec' => {
						'few' => q({0} farsek),
						'many' => q({0} a barsekoù),
						'name' => q(parsekoù),
						'one' => q({0} parsek),
						'other' => q({0} parsek),
						'two' => q({0} barsek),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'few' => q({0} fikometr),
						'many' => q({0} a bikometroù),
						'name' => q(pikometroù),
						'one' => q({0} pikometr),
						'other' => q({0} pikometr),
						'two' => q({0} bikometr),
					},
					# Core Unit Identifier
					'picometer' => {
						'few' => q({0} fikometr),
						'many' => q({0} a bikometroù),
						'name' => q(pikometroù),
						'one' => q({0} pikometr),
						'other' => q({0} pikometr),
						'two' => q({0} bikometr),
					},
					# Long Unit Identifier
					'length-point' => {
						'few' => q({0} foent),
						'many' => q({0} a boentoù),
						'name' => q(poentoù),
						'one' => q({0} poent),
						'other' => q({0} poent),
						'two' => q({0} boent),
					},
					# Core Unit Identifier
					'point' => {
						'few' => q({0} foent),
						'many' => q({0} a boentoù),
						'name' => q(poentoù),
						'one' => q({0} poent),
						'other' => q({0} poent),
						'two' => q({0} boent),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'few' => q({0} skin heol),
						'many' => q({0} skin heol),
						'name' => q(skinoù heol),
						'one' => q({0} skin heol),
						'other' => q({0} R☉),
						'two' => q({0} skin heol),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'few' => q({0} skin heol),
						'many' => q({0} skin heol),
						'name' => q(skinoù heol),
						'one' => q({0} skin heol),
						'other' => q({0} R☉),
						'two' => q({0} skin heol),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} yard),
						'many' => q({0} a yardoù),
						'name' => q(yardoù),
						'one' => q({0} yard),
						'other' => q({0} yard),
						'two' => q({0} yard),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} yard),
						'many' => q({0} a yardoù),
						'name' => q(yardoù),
						'one' => q({0} yard),
						'other' => q({0} yard),
						'two' => q({0} yard),
					},
					# Long Unit Identifier
					'light-candela' => {
						'few' => q({0} c'handela),
						'many' => q({0} a gandelaoù),
						'name' => q(kandelaoù),
						'one' => q({0} c'handela),
						'other' => q({0} kandela),
						'two' => q({0} gandela),
					},
					# Core Unit Identifier
					'candela' => {
						'few' => q({0} c'handela),
						'many' => q({0} a gandelaoù),
						'name' => q(kandelaoù),
						'one' => q({0} c'handela),
						'other' => q({0} kandela),
						'two' => q({0} gandela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'few' => q({0} lumen),
						'many' => q({0} a lumenoù),
						'name' => q(lumenoù),
						'one' => q({0} lumen),
						'other' => q({0} lumen),
						'two' => q({0} lumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'few' => q({0} lumen),
						'many' => q({0} a lumenoù),
						'name' => q(lumenoù),
						'one' => q({0} lumen),
						'other' => q({0} lumen),
						'two' => q({0} lumen),
					},
					# Long Unit Identifier
					'light-lux' => {
						'few' => q({0} luks),
						'many' => q({0} a luksoù),
						'name' => q(luksoù),
						'one' => q({0} luks),
						'other' => q({0} luks),
						'two' => q({0} luks),
					},
					# Core Unit Identifier
					'lux' => {
						'few' => q({0} luks),
						'many' => q({0} a luksoù),
						'name' => q(luksoù),
						'one' => q({0} luks),
						'other' => q({0} luks),
						'two' => q({0} luks),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'few' => q({0} c'harat),
						'many' => q({0} a garatoù),
						'name' => q(karatoù),
						'one' => q({0} c'harat),
						'other' => q({0} karat),
						'two' => q({0} garat),
					},
					# Core Unit Identifier
					'carat' => {
						'few' => q({0} c'harat),
						'many' => q({0} a garatoù),
						'name' => q(karatoù),
						'one' => q({0} c'harat),
						'other' => q({0} karat),
						'two' => q({0} garat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'few' => q({0} dalton),
						'many' => q({0} a zaltonoù),
						'name' => q(daltonoù),
						'one' => q({0} dalton),
						'other' => q({0} dalton),
						'two' => q({0} zalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'few' => q({0} dalton),
						'many' => q({0} a zaltonoù),
						'name' => q(daltonoù),
						'one' => q({0} dalton),
						'other' => q({0} dalton),
						'two' => q({0} zalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'few' => q({0} zolzad douar),
						'many' => q({0} a dolzadoù douar),
						'name' => q(tolzadoù douar),
						'one' => q({0} tolzad douar),
						'other' => q({0} tolzad douar),
						'two' => q({0} dolzad douar),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'few' => q({0} zolzad douar),
						'many' => q({0} a dolzadoù douar),
						'name' => q(tolzadoù douar),
						'one' => q({0} tolzad douar),
						'other' => q({0} tolzad douar),
						'two' => q({0} dolzad douar),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} greunad),
						'many' => q({0} a c'hreunadoù),
						'one' => q({0} greunad),
						'other' => q({0} greunad),
						'two' => q({0} c'hreunad),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} greunad),
						'many' => q({0} a c'hreunadoù),
						'one' => q({0} greunad),
						'other' => q({0} greunad),
						'two' => q({0} c'hreunad),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'few' => q({0} gramm),
						'many' => q({0} a c'hrammoù),
						'name' => q(grammoù),
						'one' => q({0} gramm),
						'other' => q({0} gramm),
						'per' => q({0} dre cʼhramm),
						'two' => q({0} c'hramm),
					},
					# Core Unit Identifier
					'gram' => {
						'few' => q({0} gramm),
						'many' => q({0} a c'hrammoù),
						'name' => q(grammoù),
						'one' => q({0} gramm),
						'other' => q({0} gramm),
						'per' => q({0} dre cʼhramm),
						'two' => q({0} c'hramm),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'few' => q({0} c'hilogramm),
						'many' => q({0} a gilogrammoù),
						'name' => q(kilogrammoù),
						'one' => q({0} c'hilogramm),
						'other' => q({0} kilogramm),
						'per' => q({0} dre gilogramm),
						'two' => q({0} gilogramm),
					},
					# Core Unit Identifier
					'kilogram' => {
						'few' => q({0} c'hilogramm),
						'many' => q({0} a gilogrammoù),
						'name' => q(kilogrammoù),
						'one' => q({0} c'hilogramm),
						'other' => q({0} kilogramm),
						'per' => q({0} dre gilogramm),
						'two' => q({0} gilogramm),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'few' => q({0} mikrogramm),
						'many' => q({0} a vikrogrammoù),
						'name' => q(mikrogrammoù),
						'one' => q({0} mikrogramm),
						'other' => q({0} mikrogramm),
						'two' => q({0} vikrogramm),
					},
					# Core Unit Identifier
					'microgram' => {
						'few' => q({0} mikrogramm),
						'many' => q({0} a vikrogrammoù),
						'name' => q(mikrogrammoù),
						'one' => q({0} mikrogramm),
						'other' => q({0} mikrogramm),
						'two' => q({0} vikrogramm),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'few' => q({0} miligramm),
						'many' => q({0} a viligrammoù),
						'name' => q(miligrammoù),
						'one' => q({0} miligramm),
						'other' => q({0} miligramm),
						'two' => q({0} viligramm),
					},
					# Core Unit Identifier
					'milligram' => {
						'few' => q({0} miligramm),
						'many' => q({0} a viligrammoù),
						'name' => q(miligrammoù),
						'one' => q({0} miligramm),
						'other' => q({0} miligramm),
						'two' => q({0} viligramm),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'few' => q({0} oñs),
						'many' => q({0} a oñsoù),
						'name' => q(oñsoù),
						'one' => q({0} oñs),
						'other' => q({0} oñs),
						'per' => q({0} dre oñs),
						'two' => q({0} oñs),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0} oñs),
						'many' => q({0} a oñsoù),
						'name' => q(oñsoù),
						'one' => q({0} oñs),
						'other' => q({0} oñs),
						'per' => q({0} dre oñs),
						'two' => q({0} oñs),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'few' => q({0} oñs troy),
						'many' => q({0} oñs troy),
						'name' => q(oñsoù troy),
						'one' => q({0} oñs troy),
						'other' => q({0} oñs troy),
						'two' => q({0} oñs troy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'few' => q({0} oñs troy),
						'many' => q({0} oñs troy),
						'name' => q(oñsoù troy),
						'one' => q({0} oñs troy),
						'other' => q({0} oñs troy),
						'two' => q({0} oñs troy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0} lur),
						'many' => q({0} a lurioù),
						'name' => q(lurioù),
						'one' => q({0} lur),
						'other' => q({0} lur),
						'per' => q({0} dre lur),
						'two' => q({0} lur),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0} lur),
						'many' => q({0} a lurioù),
						'name' => q(lurioù),
						'one' => q({0} lur),
						'other' => q({0} lur),
						'per' => q({0} dre lur),
						'two' => q({0} lur),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'few' => q({0} zolzad heol),
						'many' => q({0} a dolzadoù heol),
						'name' => q(tolzadoù heol),
						'one' => q({0} tolzad heol),
						'other' => q({0} tolzad heol),
						'two' => q({0} dolzad heol),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'few' => q({0} zolzad heol),
						'many' => q({0} a dolzadoù heol),
						'name' => q(tolzadoù heol),
						'one' => q({0} tolzad heol),
						'other' => q({0} tolzad heol),
						'two' => q({0} dolzad heol),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'few' => q({0} ston),
						'many' => q({0} ston),
						'name' => q(stonoù),
						'one' => q({0} ston),
						'other' => q({0} ston),
						'two' => q({0} ston),
					},
					# Core Unit Identifier
					'stone' => {
						'few' => q({0} ston),
						'many' => q({0} ston),
						'name' => q(stonoù),
						'one' => q({0} ston),
						'other' => q({0} ston),
						'two' => q({0} ston),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0} zonenn),
						'many' => q({0} a donennoù),
						'name' => q(tonennoù),
						'one' => q({0} donenn),
						'other' => q({0} tonenn),
						'two' => q({0} donenn),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} zonenn),
						'many' => q({0} a donennoù),
						'name' => q(tonennoù),
						'one' => q({0} donenn),
						'other' => q({0} tonenn),
						'two' => q({0} donenn),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'few' => q({0} zonenn metrek),
						'many' => q({0} a donennoù metrek),
						'name' => q(tonennoù metrek),
						'one' => q({0} donenn vetrek),
						'other' => q({0} tonenn vetrek),
						'two' => q({0} donenn vetrek),
					},
					# Core Unit Identifier
					'tonne' => {
						'few' => q({0} zonenn metrek),
						'many' => q({0} a donennoù metrek),
						'name' => q(tonennoù metrek),
						'one' => q({0} donenn vetrek),
						'other' => q({0} tonenn vetrek),
						'two' => q({0} donenn vetrek),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} dre {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} dre {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'few' => q({0} gigawatt),
						'many' => q({0} a c'higawattoù),
						'name' => q(gigawattoù),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
						'two' => q({0} c'higawatt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'few' => q({0} gigawatt),
						'many' => q({0} a c'higawattoù),
						'name' => q(gigawattoù),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
						'two' => q({0} c'higawatt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} marc'had nerzh),
						'many' => q({0} a varc'hadoù nerzh),
						'name' => q(marcʼhadoù nerzh),
						'one' => q({0} marc'had nerzh),
						'other' => q({0} marc'had nerzh),
						'two' => q({0} varc'had nerzh),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} marc'had nerzh),
						'many' => q({0} a varc'hadoù nerzh),
						'name' => q(marcʼhadoù nerzh),
						'one' => q({0} marc'had nerzh),
						'other' => q({0} marc'had nerzh),
						'two' => q({0} varc'had nerzh),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'few' => q({0} c'hilowatt),
						'many' => q({0} a gilowattoù),
						'name' => q(kilowattoù),
						'one' => q({0} c'hilowatt),
						'other' => q({0} kilowatt),
						'two' => q({0} gilowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'few' => q({0} c'hilowatt),
						'many' => q({0} a gilowattoù),
						'name' => q(kilowattoù),
						'one' => q({0} c'hilowatt),
						'other' => q({0} kilowatt),
						'two' => q({0} gilowatt),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'few' => q({0} megawatt),
						'many' => q({0} a vegawattoù),
						'name' => q(megawattoù),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
						'two' => q({0} vegawatt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'few' => q({0} megawatt),
						'many' => q({0} a vegawattoù),
						'name' => q(megawattoù),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
						'two' => q({0} vegawatt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'few' => q({0} miliwatt),
						'many' => q({0} a viliwattoù),
						'name' => q(miliwattoù),
						'one' => q({0} miliwatt),
						'other' => q({0} miliwatt),
						'two' => q({0} viliwatt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'few' => q({0} miliwatt),
						'many' => q({0} a viliwattoù),
						'name' => q(miliwattoù),
						'one' => q({0} miliwatt),
						'other' => q({0} miliwatt),
						'two' => q({0} viliwatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'few' => q({0} watt),
						'many' => q({0} a wattoù),
						'name' => q(wattoù),
						'one' => q({0} watt),
						'other' => q({0} watt),
						'two' => q({0} watt),
					},
					# Core Unit Identifier
					'watt' => {
						'few' => q({0} watt),
						'many' => q({0} a wattoù),
						'name' => q(wattoù),
						'one' => q({0} watt),
						'other' => q({0} watt),
						'two' => q({0} watt),
					},
					# Long Unit Identifier
					'power2' => {
						'few' => q({0} karrez),
						'many' => q({0} karrez),
						'one' => q({0} karrez),
						'other' => q({0} karrez),
						'two' => q({0} karrez),
					},
					# Core Unit Identifier
					'power2' => {
						'few' => q({0} karrez),
						'many' => q({0} karrez),
						'one' => q({0} karrez),
						'other' => q({0} karrez),
						'two' => q({0} karrez),
					},
					# Long Unit Identifier
					'power3' => {
						'few' => q({0} diñs),
						'many' => q({0} diñs),
						'one' => q({0} diñs),
						'other' => q({0} diñs),
						'two' => q({0} diñs),
					},
					# Core Unit Identifier
					'power3' => {
						'few' => q({0} diñs),
						'many' => q({0} diñs),
						'one' => q({0} diñs),
						'other' => q({0} diñs),
						'two' => q({0} diñs),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'few' => q({0} atmosfer),
						'many' => q({0} a atmosferoù),
						'name' => q(atmosfer),
						'one' => q({0} atmosfer),
						'other' => q({0} atmosfer),
						'two' => q({0} atmosfer),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'few' => q({0} atmosfer),
						'many' => q({0} a atmosferoù),
						'name' => q(atmosfer),
						'one' => q({0} atmosfer),
						'other' => q({0} atmosfer),
						'two' => q({0} atmosfer),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'few' => q({0} bar),
						'many' => q({0} a varoù),
						'name' => q(baroù),
						'one' => q({0} bar),
						'other' => q({0} bar),
						'two' => q({0} var),
					},
					# Core Unit Identifier
					'bar' => {
						'few' => q({0} bar),
						'many' => q({0} a varoù),
						'name' => q(baroù),
						'one' => q({0} bar),
						'other' => q({0} bar),
						'two' => q({0} var),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'few' => q({0} hektopaskal),
						'many' => q({0} a hektopaskaloù),
						'name' => q(hektopaskaloù),
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskal),
						'two' => q({0} hektopaskal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'few' => q({0} hektopaskal),
						'many' => q({0} a hektopaskaloù),
						'name' => q(hektopaskaloù),
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskal),
						'two' => q({0} hektopaskal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0} meutad merkur),
						'many' => q({0} a veutadoù merkur),
						'name' => q(meutadoù merkur),
						'one' => q({0} meutad merkur),
						'other' => q({0} meutad merkur),
						'two' => q({0} veutad merkur),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} meutad merkur),
						'many' => q({0} a veutadoù merkur),
						'name' => q(meutadoù merkur),
						'one' => q({0} meutad merkur),
						'other' => q({0} meutad merkur),
						'two' => q({0} veutad merkur),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'few' => q({0} c'hilopaskal),
						'many' => q({0} a gilopaskaloù),
						'name' => q(kilopaskaloù),
						'one' => q({0} c'hilopaskal),
						'other' => q({0} kilopaskal),
						'two' => q({0} gilopaskal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'few' => q({0} c'hilopaskal),
						'many' => q({0} a gilopaskaloù),
						'name' => q(kilopaskaloù),
						'one' => q({0} c'hilopaskal),
						'other' => q({0} kilopaskal),
						'two' => q({0} gilopaskal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'few' => q({0} megapaskal),
						'many' => q({0} a vegapaskaloù),
						'name' => q(megapaskaloù),
						'one' => q({0} megapaskal),
						'other' => q({0} megapaskal),
						'two' => q({0} vegapaskal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'few' => q({0} megapaskal),
						'many' => q({0} a vegapaskaloù),
						'name' => q(megapaskaloù),
						'one' => q({0} megapaskal),
						'other' => q({0} megapaskal),
						'two' => q({0} vegapaskal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0} milibar),
						'many' => q({0} a vilibaroù),
						'name' => q(milibaroù),
						'one' => q({0} milibar),
						'other' => q({0} milibar),
						'two' => q({0} vilibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0} milibar),
						'many' => q({0} a vilibaroù),
						'name' => q(milibaroù),
						'one' => q({0} milibar),
						'other' => q({0} milibar),
						'two' => q({0} vilibar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0} milimetrad merkur),
						'many' => q({0} a vilimetradoù merkur),
						'name' => q(milimetradoù merkur),
						'one' => q({0} milimetrad merkur),
						'other' => q({0} milimetrad merkur),
						'two' => q({0} vilimetrad merkur),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0} milimetrad merkur),
						'many' => q({0} a vilimetradoù merkur),
						'name' => q(milimetradoù merkur),
						'one' => q({0} milimetrad merkur),
						'other' => q({0} milimetrad merkur),
						'two' => q({0} vilimetrad merkur),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'few' => q({0} faskal),
						'many' => q({0} a baskaloù),
						'name' => q(paskaloù),
						'one' => q({0} paskal),
						'other' => q({0} paskal),
						'two' => q({0} baskal),
					},
					# Core Unit Identifier
					'pascal' => {
						'few' => q({0} faskal),
						'many' => q({0} a baskaloù),
						'name' => q(paskaloù),
						'one' => q({0} paskal),
						'other' => q({0} paskal),
						'two' => q({0} baskal),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0} lur dre veutad karrez),
						'many' => q({0} a lurioù dre veutad karrez),
						'name' => q(lurioù dre veutad karrez),
						'one' => q({0} lur dre veutad karrez),
						'other' => q({0} lur dre veutad karrez),
						'two' => q({0} lur dre veutad karrez),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0} lur dre veutad karrez),
						'many' => q({0} a lurioù dre veutad karrez),
						'name' => q(lurioù dre veutad karrez),
						'one' => q({0} lur dre veutad karrez),
						'other' => q({0} lur dre veutad karrez),
						'two' => q({0} lur dre veutad karrez),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'few' => q({0} c'hilometr dre eur),
						'many' => q({0} a gilometroù dre eur),
						'name' => q(kilometroù dre eur),
						'one' => q({0} c'hilometr dre eur),
						'other' => q({0} kilometr dre eur),
						'two' => q({0} gilometr dre eur),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'few' => q({0} c'hilometr dre eur),
						'many' => q({0} a gilometroù dre eur),
						'name' => q(kilometroù dre eur),
						'one' => q({0} c'hilometr dre eur),
						'other' => q({0} kilometr dre eur),
						'two' => q({0} gilometr dre eur),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0} skoulm),
						'many' => q({0} a skoulmoù),
						'name' => q(skoulmoù),
						'one' => q({0} skoulm),
						'other' => q({0} skoulm),
						'two' => q({0} skoulm),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0} skoulm),
						'many' => q({0} a skoulmoù),
						'name' => q(skoulmoù),
						'one' => q({0} skoulm),
						'other' => q({0} skoulm),
						'two' => q({0} skoulm),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'few' => q({0} metr dre eilenn),
						'many' => q({0} a vetroù dre eilenn),
						'name' => q(metroù dre eilenn),
						'one' => q({0} metr dre eilenn),
						'other' => q({0} metr dre eilenn),
						'two' => q({0} vetr dre eilenn),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'few' => q({0} metr dre eilenn),
						'many' => q({0} a vetroù dre eilenn),
						'name' => q(metroù dre eilenn),
						'one' => q({0} metr dre eilenn),
						'other' => q({0} metr dre eilenn),
						'two' => q({0} vetr dre eilenn),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} miltir dre eur),
						'many' => q({0} a viltirioù dre eur),
						'name' => q(miltirioù dre eur),
						'one' => q({0} miltir dre eur),
						'other' => q({0} miltir dre eur),
						'two' => q({0} viltir dre eur),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} miltir dre eur),
						'many' => q({0} a viltirioù dre eur),
						'name' => q(miltirioù dre eur),
						'one' => q({0} miltir dre eur),
						'other' => q({0} miltir dre eur),
						'two' => q({0} viltir dre eur),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'few' => q({0} derez Celsius),
						'many' => q({0} a zerezioù Celsius),
						'name' => q(derezioù Celsius),
						'one' => q({0} derez Celsius),
						'other' => q({0} derez Celsius),
						'two' => q({0} zerez Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'few' => q({0} derez Celsius),
						'many' => q({0} a zerezioù Celsius),
						'name' => q(derezioù Celsius),
						'one' => q({0} derez Celsius),
						'other' => q({0} derez Celsius),
						'two' => q({0} zerez Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0} derez Fahrenheit),
						'many' => q({0} a zerezioù Fahrenheit),
						'name' => q(derezioù Fahrenheit),
						'one' => q({0} derez Fahrenheit),
						'other' => q({0} derez Fahrenheit),
						'two' => q({0} zerez Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0} derez Fahrenheit),
						'many' => q({0} a zerezioù Fahrenheit),
						'name' => q(derezioù Fahrenheit),
						'one' => q({0} derez Fahrenheit),
						'other' => q({0} derez Fahrenheit),
						'two' => q({0} zerez Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'few' => q({0} derez),
						'many' => q({0} a zerezioù),
						'name' => q(derezioù),
						'one' => q({0} derez),
						'other' => q({0} derez),
						'two' => q({0} zerez),
					},
					# Core Unit Identifier
					'generic' => {
						'few' => q({0} derez),
						'many' => q({0} a zerezioù),
						'name' => q(derezioù),
						'one' => q({0} derez),
						'other' => q({0} derez),
						'two' => q({0} zerez),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'few' => q({0} c'helvin),
						'many' => q({0} a gelvinoù),
						'name' => q(kelvinoù),
						'one' => q({0} c'helvin),
						'other' => q({0} kelvin),
						'two' => q({0} gelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'few' => q({0} c'helvin),
						'many' => q({0} a gelvinoù),
						'name' => q(kelvinoù),
						'one' => q({0} c'helvin),
						'other' => q({0} kelvin),
						'two' => q({0} gelvin),
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
						'few' => q({0} newton-metr),
						'many' => q({0} a newton-metroù),
						'name' => q(newton-metroù),
						'one' => q({0} newton-metr),
						'other' => q({0} newton-metr),
						'two' => q({0} newton-metr),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'few' => q({0} newton-metr),
						'many' => q({0} a newton-metroù),
						'name' => q(newton-metroù),
						'one' => q({0} newton-metr),
						'other' => q({0} newton-metr),
						'two' => q({0} newton-metr),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'few' => q({0} akr-troatad),
						'many' => q({0} akr-troatad),
						'name' => q(akroù-troatadoù),
						'one' => q({0} akr-troatad),
						'other' => q({0} akr-troatad),
						'two' => q({0} akr-troatad),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'few' => q({0} akr-troatad),
						'many' => q({0} akr-troatad),
						'name' => q(akroù-troatadoù),
						'one' => q({0} akr-troatad),
						'other' => q({0} akr-troatad),
						'two' => q({0} akr-troatad),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'few' => q({0} barilh),
						'many' => q({0} a varilhoù),
						'name' => q(barilhoù),
						'one' => q({0} barilh),
						'other' => q({0} barilh),
						'two' => q({0} varilh),
					},
					# Core Unit Identifier
					'barrel' => {
						'few' => q({0} barilh),
						'many' => q({0} a varilhoù),
						'name' => q(barilhoù),
						'one' => q({0} barilh),
						'other' => q({0} barilh),
						'two' => q({0} varilh),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'few' => q({0} foezellad),
						'many' => q({0} a boezelladoù),
						'name' => q(poezelladoù),
						'one' => q({0} poezellad),
						'other' => q({0} poezellad),
						'two' => q({0} boezellad),
					},
					# Core Unit Identifier
					'bushel' => {
						'few' => q({0} foezellad),
						'many' => q({0} a boezelladoù),
						'name' => q(poezelladoù),
						'one' => q({0} poezellad),
						'other' => q({0} poezellad),
						'two' => q({0} boezellad),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'few' => q({0} santilitr),
						'many' => q({0} a santilitroù),
						'name' => q(santilitroù),
						'one' => q({0} santilitr),
						'other' => q({0} santilitr),
						'two' => q({0} santilitr),
					},
					# Core Unit Identifier
					'centiliter' => {
						'few' => q({0} santilitr),
						'many' => q({0} a santilitroù),
						'name' => q(santilitroù),
						'one' => q({0} santilitr),
						'other' => q({0} santilitr),
						'two' => q({0} santilitr),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'few' => q({0} santimetr diñs),
						'many' => q({0} a santimetroù diñs),
						'name' => q(santimetroù diñs),
						'one' => q({0} santimetr diñs),
						'other' => q({0} santimetr diñs),
						'per' => q({0} dre santimetr diñs),
						'two' => q({0} santimetr diñs),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'few' => q({0} santimetr diñs),
						'many' => q({0} a santimetroù diñs),
						'name' => q(santimetroù diñs),
						'one' => q({0} santimetr diñs),
						'other' => q({0} santimetr diñs),
						'per' => q({0} dre santimetr diñs),
						'two' => q({0} santimetr diñs),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0} zroatad diñs),
						'many' => q({0} a droatadoù diñs),
						'name' => q(troatadoù diñs),
						'one' => q({0} troatad diñs),
						'other' => q({0} troatad diñs),
						'two' => q({0} droatad diñs),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0} zroatad diñs),
						'many' => q({0} a droatadoù diñs),
						'name' => q(troatadoù diñs),
						'one' => q({0} troatad diñs),
						'other' => q({0} troatad diñs),
						'two' => q({0} droatad diñs),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0} meutad diñs),
						'many' => q({0} a veutadoù diñs),
						'name' => q(meutadoù diñs),
						'one' => q({0} meutad diñs),
						'other' => q({0} meutad diñs),
						'two' => q({0} veutad diñs),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0} meutad diñs),
						'many' => q({0} a veutadoù diñs),
						'name' => q(meutadoù diñs),
						'one' => q({0} meutad diñs),
						'other' => q({0} meutad diñs),
						'two' => q({0} veutad diñs),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'few' => q({0} c'hilometr diñs),
						'many' => q({0} a gilometroù diñs),
						'name' => q(kilometroù diñs),
						'one' => q({0} c'hilometr diñs),
						'other' => q({0} kilometr diñs),
						'two' => q({0} gilometr diñs),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'few' => q({0} c'hilometr diñs),
						'many' => q({0} a gilometroù diñs),
						'name' => q(kilometroù diñs),
						'one' => q({0} c'hilometr diñs),
						'other' => q({0} kilometr diñs),
						'two' => q({0} gilometr diñs),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'few' => q({0} metr diñs),
						'many' => q({0} a vetroù diñs),
						'name' => q(metroù diñs),
						'one' => q({0} metr diñs),
						'other' => q({0} metr diñs),
						'per' => q({0} dre vetr diñs),
						'two' => q({0} vetr diñs),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'few' => q({0} metr diñs),
						'many' => q({0} a vetroù diñs),
						'name' => q(metroù diñs),
						'one' => q({0} metr diñs),
						'other' => q({0} metr diñs),
						'per' => q({0} dre vetr diñs),
						'two' => q({0} vetr diñs),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0} miltir diñs),
						'many' => q({0} a viltirioù diñs),
						'name' => q(miltirioù diñs),
						'one' => q({0} miltir diñs),
						'other' => q({0} miltir diñs),
						'two' => q({0} viltir diñs),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0} miltir diñs),
						'many' => q({0} a viltirioù diñs),
						'name' => q(miltirioù diñs),
						'one' => q({0} miltir diñs),
						'other' => q({0} miltir diñs),
						'two' => q({0} viltir diñs),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0} yard diñs),
						'many' => q({0} a yardoù diñs),
						'name' => q(yardoù diñs),
						'one' => q({0} yard diñs),
						'other' => q({0} yard diñs),
						'two' => q({0} yard diñs),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0} yard diñs),
						'many' => q({0} a yardoù diñs),
						'name' => q(yardoù diñs),
						'one' => q({0} yard diñs),
						'other' => q({0} yard diñs),
						'two' => q({0} yard diñs),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0} zasad),
						'many' => q({0} a dasadoù),
						'name' => q(tasadoù),
						'one' => q({0} tasad),
						'other' => q({0} tasad),
						'two' => q({0} tasad),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0} zasad),
						'many' => q({0} a dasadoù),
						'name' => q(tasadoù),
						'one' => q({0} tasad),
						'other' => q({0} tasad),
						'two' => q({0} tasad),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'few' => q({0} zasad metrek),
						'many' => q({0} a dasadoù metrek),
						'name' => q(tasadoù metrek),
						'one' => q({0} tasad metrek),
						'other' => q({0} tasad metrek),
						'two' => q({0} dasad vetrek),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'few' => q({0} zasad metrek),
						'many' => q({0} a dasadoù metrek),
						'name' => q(tasadoù metrek),
						'one' => q({0} tasad metrek),
						'other' => q({0} tasad metrek),
						'two' => q({0} dasad vetrek),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'few' => q({0} desilitr),
						'many' => q({0} a zesilitroù),
						'name' => q(desilitroù),
						'one' => q({0} desilitr),
						'other' => q({0} desilitr),
						'two' => q({0} zesilitr),
					},
					# Core Unit Identifier
					'deciliter' => {
						'few' => q({0} desilitr),
						'many' => q({0} a zesilitroù),
						'name' => q(desilitroù),
						'one' => q({0} desilitr),
						'other' => q({0} desilitr),
						'two' => q({0} zesilitr),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} loaiad dibenn-pred),
						'many' => q({0} a loaiadoù dibenn-pred),
						'name' => q(loaiad dibenn-pred),
						'one' => q({0} loaiad dibenn-pred),
						'other' => q({0} loaiad dibenn-pred),
						'two' => q({0} loaiad dibenn-pred),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} loaiad dibenn-pred),
						'many' => q({0} a loaiadoù dibenn-pred),
						'name' => q(loaiad dibenn-pred),
						'one' => q({0} loaiad dibenn-pred),
						'other' => q({0} loaiad dibenn-pred),
						'two' => q({0} loaiad dibenn-pred),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} loaiad dibenn-pred impalaerel),
						'many' => q({0} a loaiadoù dibenn-pred impalaerel),
						'name' => q(loaiad dibenn-pred impalaerel),
						'one' => q({0} loaiad dibenn-pred impalaerel),
						'other' => q({0} loaiad dibenn-pred impalaerel),
						'two' => q({0} loaiad dibenn-pred impalaerel),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} loaiad dibenn-pred impalaerel),
						'many' => q({0} a loaiadoù dibenn-pred impalaerel),
						'name' => q(loaiad dibenn-pred impalaerel),
						'one' => q({0} loaiad dibenn-pred impalaerel),
						'other' => q({0} loaiad dibenn-pred impalaerel),
						'two' => q({0} loaiad dibenn-pred impalaerel),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} drakm liñvel),
						'many' => q({0} a zrakmoù liñvel),
						'name' => q(drakm liñvel),
						'one' => q({0} drakm liñvel),
						'other' => q({0} drakm liñvel),
						'two' => q({0} zrakm liñvel),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} drakm liñvel),
						'many' => q({0} a zrakmoù liñvel),
						'name' => q(drakm liñvel),
						'one' => q({0} drakm liñvel),
						'other' => q({0} drakm liñvel),
						'two' => q({0} zrakm liñvel),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0} zakenn),
						'many' => q({0} a dakennoù),
						'name' => q(takenn),
						'one' => q({0} dakenn),
						'other' => q({0} takenn),
						'two' => q({0} dakenn),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0} zakenn),
						'many' => q({0} a dakennoù),
						'name' => q(takenn),
						'one' => q({0} dakenn),
						'other' => q({0} takenn),
						'two' => q({0} dakenn),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} oñs liñvel),
						'many' => q({0} a oñsoù liñvel),
						'name' => q(oñsoù liñvel),
						'one' => q({0} oñs liñvel),
						'other' => q({0} oñs liñvel),
						'two' => q({0} oñs liñvel),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} oñs liñvel),
						'many' => q({0} a oñsoù liñvel),
						'name' => q(oñsoù liñvel),
						'one' => q({0} oñs liñvel),
						'other' => q({0} oñs liñvel),
						'two' => q({0} oñs liñvel),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} oñs liñvel impalaerel),
						'many' => q({0} a oñsoù liñvel impalaerel),
						'name' => q(oñsoù liñvel impalaerel),
						'one' => q({0} oñs liñvel impalaerel),
						'other' => q({0} oñs liñvel impalaerel),
						'two' => q({0} oñs liñvel impalaerel),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} oñs liñvel impalaerel),
						'many' => q({0} a oñsoù liñvel impalaerel),
						'name' => q(oñsoù liñvel impalaerel),
						'one' => q({0} oñs liñvel impalaerel),
						'other' => q({0} oñs liñvel impalaerel),
						'two' => q({0} oñs liñvel impalaerel),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} gallon),
						'many' => q({0} a c'hallonoù),
						'name' => q(gallonoù),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0} dre cʼhallon),
						'two' => q({0} c'hallon),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} gallon),
						'many' => q({0} a c'hallonoù),
						'name' => q(gallonoù),
						'one' => q({0} gallon),
						'other' => q({0} gallon),
						'per' => q({0} dre cʼhallon),
						'two' => q({0} c'hallon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} gallon impalaerel),
						'many' => q({0} a c'hallonoù impalaerel),
						'name' => q(gallonoù impalaerel),
						'one' => q({0} gallon impalaerel),
						'other' => q({0} gallon impalaerel),
						'per' => q({0} dre cʼhallon impalaerel),
						'two' => q({0} c'hallon impalaerel),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} gallon impalaerel),
						'many' => q({0} a c'hallonoù impalaerel),
						'name' => q(gallonoù impalaerel),
						'one' => q({0} gallon impalaerel),
						'other' => q({0} gallon impalaerel),
						'per' => q({0} dre cʼhallon impalaerel),
						'two' => q({0} c'hallon impalaerel),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'few' => q({0} hektolitr),
						'many' => q({0} a hektolitroù),
						'name' => q(hektolitroù),
						'one' => q({0} hektolitr),
						'other' => q({0} hektolitr),
						'two' => q({0} hektolitr),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'few' => q({0} hektolitr),
						'many' => q({0} a hektolitroù),
						'name' => q(hektolitroù),
						'one' => q({0} hektolitr),
						'other' => q({0} hektolitr),
						'two' => q({0} hektolitr),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} shot),
						'many' => q({0} a shotoù),
						'one' => q({0} shot),
						'other' => q({0} shot),
						'two' => q({0} shot),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} shot),
						'many' => q({0} a shotoù),
						'one' => q({0} shot),
						'other' => q({0} shot),
						'two' => q({0} shot),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'few' => q({0} litr),
						'many' => q({0} a litroù),
						'name' => q(litroù),
						'one' => q({0} litr),
						'other' => q({0} litr),
						'per' => q({0} dre litr),
						'two' => q({0} litr),
					},
					# Core Unit Identifier
					'liter' => {
						'few' => q({0} litr),
						'many' => q({0} a litroù),
						'name' => q(litroù),
						'one' => q({0} litr),
						'other' => q({0} litr),
						'per' => q({0} dre litr),
						'two' => q({0} litr),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'few' => q({0} megalitr),
						'many' => q({0} a vegalitroù),
						'name' => q(megalitroù),
						'one' => q({0} megalitr),
						'other' => q({0} megalitr),
						'two' => q({0} vegalitr),
					},
					# Core Unit Identifier
					'megaliter' => {
						'few' => q({0} megalitr),
						'many' => q({0} a vegalitroù),
						'name' => q(megalitroù),
						'one' => q({0} megalitr),
						'other' => q({0} megalitr),
						'two' => q({0} vegalitr),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'few' => q({0} mililitr),
						'many' => q({0} a vililitroù),
						'name' => q(mililitroù),
						'one' => q({0} mililitr),
						'other' => q({0} mililitr),
						'two' => q({0} vililitr),
					},
					# Core Unit Identifier
					'milliliter' => {
						'few' => q({0} mililitr),
						'many' => q({0} a vililitroù),
						'name' => q(mililitroù),
						'one' => q({0} mililitr),
						'other' => q({0} mililitr),
						'two' => q({0} vililitr),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} fiñsad),
						'many' => q({0} a biñsadoù),
						'name' => q(piñsad),
						'one' => q({0} piñsad),
						'other' => q({0} piñsad),
						'two' => q({0} biñsad),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} fiñsad),
						'many' => q({0} a biñsadoù),
						'name' => q(piñsad),
						'one' => q({0} piñsad),
						'other' => q({0} piñsad),
						'two' => q({0} biñsad),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'few' => q({0} fint),
						'many' => q({0} a bintoù),
						'name' => q(pintoù),
						'one' => q({0} pint),
						'other' => q({0} pint),
						'two' => q({0} bint),
					},
					# Core Unit Identifier
					'pint' => {
						'few' => q({0} fint),
						'many' => q({0} a bintoù),
						'name' => q(pintoù),
						'one' => q({0} pint),
						'other' => q({0} pint),
						'two' => q({0} bint),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'few' => q({0} fint metrek),
						'many' => q({0} a bintoù metrek),
						'name' => q(pintoù metrek),
						'one' => q({0} pint metrek),
						'other' => q({0} pint metrek),
						'two' => q({0} bint metrek),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'few' => q({0} fint metrek),
						'many' => q({0} a bintoù metrek),
						'name' => q(pintoù metrek),
						'one' => q({0} pint metrek),
						'other' => q({0} pint metrek),
						'two' => q({0} bint metrek),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'few' => q({0} c'hard),
						'many' => q({0} a gardoù),
						'name' => q(kardoù),
						'one' => q({0} c'hard),
						'other' => q({0} kard),
						'two' => q({0} gard),
					},
					# Core Unit Identifier
					'quart' => {
						'few' => q({0} c'hard),
						'many' => q({0} a gardoù),
						'name' => q(kardoù),
						'one' => q({0} c'hard),
						'other' => q({0} kard),
						'two' => q({0} gard),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} c'hard impalaerel),
						'many' => q({0} a gardoù impalaerel),
						'name' => q(kardoù impalaerel),
						'one' => q({0} c'hard impalaerel),
						'other' => q({0} kard impalaerel),
						'two' => q({0} gard impalaerel),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} c'hard impalaerel),
						'many' => q({0} a gardoù impalaerel),
						'name' => q(kardoù impalaerel),
						'one' => q({0} c'hard impalaerel),
						'other' => q({0} kard impalaerel),
						'two' => q({0} gard impalaerel),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} loaiad-voued),
						'many' => q({0} a loaiadoù-boued),
						'name' => q(loaiadoù-boued),
						'one' => q({0} loaiad-voued),
						'other' => q({0} loaiad-voued),
						'two' => q({0} loaiad-voued),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} loaiad-voued),
						'many' => q({0} a loaiadoù-boued),
						'name' => q(loaiadoù-boued),
						'one' => q({0} loaiad-voued),
						'other' => q({0} loaiad-voued),
						'two' => q({0} loaiad-voued),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} loaiad-gafe),
						'many' => q({0} a loaiadoù-kafe),
						'name' => q(loaiadoù-kafe),
						'one' => q({0} loaiad-gafe),
						'other' => q({0} loaiad-gafe),
						'two' => q({0} loaiad-gafe),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} loaiad-gafe),
						'many' => q({0} a loaiadoù-kafe),
						'name' => q(loaiadoù-kafe),
						'one' => q({0} loaiad-gafe),
						'other' => q({0} loaiad-gafe),
						'two' => q({0} loaiad-gafe),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'few' => q({0}G),
						'many' => q({0}G),
						'one' => q({0}G),
						'other' => q({0}G),
						'two' => q({0}G),
					},
					# Core Unit Identifier
					'g-force' => {
						'few' => q({0}G),
						'many' => q({0}G),
						'one' => q({0}G),
						'other' => q({0}G),
						'two' => q({0}G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'few' => q({0}m/s²),
						'many' => q({0}m/s²),
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
						'two' => q({0}m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'few' => q({0}m/s²),
						'many' => q({0}m/s²),
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
						'two' => q({0}m/s²),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'few' => q({0}°),
						'many' => q({0}°),
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
						'two' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'few' => q({0}°),
						'many' => q({0}°),
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
						'two' => q({0}°),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'few' => q({0}rad),
						'many' => q({0}rad),
						'one' => q({0}rad),
						'other' => q({0}rad),
						'two' => q({0}rad),
					},
					# Core Unit Identifier
					'radian' => {
						'few' => q({0}rad),
						'many' => q({0}rad),
						'one' => q({0}rad),
						'other' => q({0}rad),
						'two' => q({0}rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0}tr),
						'many' => q({0}tr),
						'one' => q({0}tr),
						'other' => q({0}tr),
						'two' => q({0}tr),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0}tr),
						'many' => q({0}tr),
						'one' => q({0}tr),
						'other' => q({0}tr),
						'two' => q({0}tr),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0}ac),
						'many' => q({0}ac),
						'one' => q({0}ac),
						'other' => q({0}ac),
						'two' => q({0}ac),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0}ac),
						'many' => q({0}ac),
						'one' => q({0}ac),
						'other' => q({0}ac),
						'two' => q({0}ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0}dounam),
						'many' => q({0}dounam),
						'one' => q({0}dounam),
						'other' => q({0}dounam),
						'two' => q({0}dounam),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0}dounam),
						'many' => q({0}dounam),
						'one' => q({0}dounam),
						'other' => q({0}dounam),
						'two' => q({0}dounam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'few' => q({0}ha),
						'many' => q({0}ha),
						'one' => q({0}ha),
						'other' => q({0}ha),
						'two' => q({0}ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'few' => q({0}ha),
						'many' => q({0}ha),
						'one' => q({0}ha),
						'other' => q({0}ha),
						'two' => q({0}ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'few' => q({0}cm²),
						'many' => q({0}cm²),
						'one' => q({0}cm²),
						'other' => q({0}cm²),
						'two' => q({0}cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'few' => q({0}cm²),
						'many' => q({0}cm²),
						'one' => q({0}cm²),
						'other' => q({0}cm²),
						'two' => q({0}cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0}ft²),
						'many' => q({0}ft²),
						'one' => q({0}ft²),
						'other' => q({0}ft²),
						'two' => q({0}ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0}ft²),
						'many' => q({0}ft²),
						'one' => q({0}ft²),
						'other' => q({0}ft²),
						'two' => q({0}ft²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0}in²),
						'many' => q({0}in²),
						'one' => q({0}in²),
						'other' => q({0}in²),
						'two' => q({0}in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0}in²),
						'many' => q({0}in²),
						'one' => q({0}in²),
						'other' => q({0}in²),
						'two' => q({0}in²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'few' => q({0}km²),
						'many' => q({0}km²),
						'one' => q({0}km²),
						'other' => q({0}km²),
						'two' => q({0}km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'few' => q({0}km²),
						'many' => q({0}km²),
						'one' => q({0}km²),
						'other' => q({0}km²),
						'two' => q({0}km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'few' => q({0}m²),
						'many' => q({0}m²),
						'one' => q({0}m²),
						'other' => q({0}m²),
						'two' => q({0}m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'few' => q({0}m²),
						'many' => q({0}m²),
						'one' => q({0}m²),
						'other' => q({0}m²),
						'two' => q({0}m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0}mi²),
						'many' => q({0}mi²),
						'one' => q({0}mi²),
						'other' => q({0}mi²),
						'two' => q({0}mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0}mi²),
						'many' => q({0}mi²),
						'one' => q({0}mi²),
						'other' => q({0}mi²),
						'two' => q({0}mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0}yd²),
						'many' => q({0}yd²),
						'one' => q({0}yd²),
						'other' => q({0}yd²),
						'two' => q({0}yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0}yd²),
						'many' => q({0}yd²),
						'one' => q({0}yd²),
						'other' => q({0}yd²),
						'two' => q({0}yd²),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'few' => q({0}kt),
						'many' => q({0}kt),
						'one' => q({0}kt),
						'other' => q({0}kt),
						'two' => q({0}kt),
					},
					# Core Unit Identifier
					'karat' => {
						'few' => q({0}kt),
						'many' => q({0}kt),
						'one' => q({0}kt),
						'other' => q({0}kt),
						'two' => q({0}kt),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0}mg/dl),
						'many' => q({0}mg/dl),
						'one' => q({0}mg/dl),
						'other' => q({0}mg/dl),
						'two' => q({0}mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0}mg/dl),
						'many' => q({0}mg/dl),
						'one' => q({0}mg/dl),
						'other' => q({0}mg/dl),
						'two' => q({0}mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'few' => q({0}mmol/l),
						'many' => q({0}mmol/l),
						'name' => q(mmol/l),
						'one' => q({0}mmol/l),
						'other' => q({0}mmol/l),
						'two' => q({0}mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'few' => q({0}mmol/l),
						'many' => q({0}mmol/l),
						'name' => q(mmol/l),
						'one' => q({0}mmol/l),
						'other' => q({0}mmol/l),
						'two' => q({0}mmol/l),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'few' => q({0}mol),
						'many' => q({0}mol),
						'one' => q({0}mol),
						'other' => q({0}mol),
						'two' => q({0}mol),
					},
					# Core Unit Identifier
					'mole' => {
						'few' => q({0}mol),
						'many' => q({0}mol),
						'one' => q({0}mol),
						'other' => q({0}mol),
						'two' => q({0}mol),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'few' => q({0}%),
						'many' => q({0}%),
						'one' => q({0}%),
						'other' => q({0}%),
						'two' => q({0}%),
					},
					# Core Unit Identifier
					'percent' => {
						'few' => q({0}%),
						'many' => q({0}%),
						'one' => q({0}%),
						'other' => q({0}%),
						'two' => q({0}%),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'few' => q({0}‰),
						'many' => q({0}‰),
						'one' => q({0}‰),
						'other' => q({0}‰),
						'two' => q({0}‰),
					},
					# Core Unit Identifier
					'permille' => {
						'few' => q({0}‰),
						'many' => q({0}‰),
						'one' => q({0}‰),
						'other' => q({0}‰),
						'two' => q({0}‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'few' => q({0}ppm),
						'many' => q({0}ppm),
						'one' => q({0}ppm),
						'other' => q({0}ppm),
						'two' => q({0}ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'few' => q({0}ppm),
						'many' => q({0}ppm),
						'one' => q({0}ppm),
						'other' => q({0}ppm),
						'two' => q({0}ppm),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'few' => q({0}‱),
						'many' => q({0}‱),
						'one' => q({0}‱),
						'other' => q({0}‱),
						'two' => q({0}‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'few' => q({0}‱),
						'many' => q({0}‱),
						'one' => q({0}‱),
						'other' => q({0}‱),
						'two' => q({0}‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0}l/100km),
						'many' => q({0}l/100km),
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
						'two' => q({0}l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0}l/100km),
						'many' => q({0}l/100km),
						'one' => q({0}l/100km),
						'other' => q({0}l/100km),
						'two' => q({0}l/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0}l/km),
						'many' => q({0}l/km),
						'one' => q({0}l/km),
						'other' => q({0}l/km),
						'two' => q({0}l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0}l/km),
						'many' => q({0}l/km),
						'one' => q({0}l/km),
						'other' => q({0}l/km),
						'two' => q({0}l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0}mi/gal),
						'many' => q({0}mi/gal),
						'one' => q({0}mi/gal),
						'other' => q({0}mi/gal),
						'two' => q({0}mi/gal),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0}mi/gal),
						'many' => q({0}mi/gal),
						'one' => q({0}mi/gal),
						'other' => q({0}mi/gal),
						'two' => q({0}mi/gal),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0}mi/gIm),
						'many' => q({0}mi/gIm),
						'name' => q(mi/gIm),
						'one' => q({0}mi/gIm),
						'other' => q({0}mi/gIm),
						'two' => q({0}mi/gIm),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0}mi/gIm),
						'many' => q({0}mi/gIm),
						'name' => q(mi/gIm),
						'one' => q({0}mi/gIm),
						'other' => q({0}mi/gIm),
						'two' => q({0}mi/gIm),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}R),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}K),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}R),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}K),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'few' => q({0}bit),
						'many' => q({0}bit),
						'one' => q({0}bit),
						'other' => q({0}bit),
						'two' => q({0}bit),
					},
					# Core Unit Identifier
					'bit' => {
						'few' => q({0}bit),
						'many' => q({0}bit),
						'one' => q({0}bit),
						'other' => q({0}bit),
						'two' => q({0}bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0}o),
						'many' => q({0}o),
						'one' => q({0}o),
						'other' => q({0} o),
						'two' => q({0}o),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0}o),
						'many' => q({0}o),
						'one' => q({0}o),
						'other' => q({0} o),
						'two' => q({0}o),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'few' => q({0}Gbit),
						'many' => q({0}Gbit),
						'one' => q({0}Gbit),
						'other' => q({0}Gbit),
						'two' => q({0}Gbit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'few' => q({0}Gbit),
						'many' => q({0}Gbit),
						'one' => q({0}Gbit),
						'other' => q({0}Gbit),
						'two' => q({0}Gbit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'few' => q({0}Go),
						'many' => q({0}Go),
						'one' => q({0}Go),
						'other' => q({0}Go),
						'two' => q({0}Go),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'few' => q({0}Go),
						'many' => q({0}Go),
						'one' => q({0}Go),
						'other' => q({0}Go),
						'two' => q({0}Go),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'few' => q({0}kbit),
						'many' => q({0}kbit),
						'one' => q({0}kbit),
						'other' => q({0}kbit),
						'two' => q({0}kbit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'few' => q({0}kbit),
						'many' => q({0}kbit),
						'one' => q({0}kbit),
						'other' => q({0}kbit),
						'two' => q({0}kbit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'few' => q({0}ko),
						'many' => q({0}ko),
						'one' => q({0}ko),
						'other' => q({0}ko),
						'two' => q({0}ko),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'few' => q({0}ko),
						'many' => q({0}ko),
						'one' => q({0}ko),
						'other' => q({0}ko),
						'two' => q({0}ko),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'few' => q({0}Mbit),
						'many' => q({0}Mbit),
						'one' => q({0}Mbit),
						'other' => q({0}Mbit),
						'two' => q({0}Mbit),
					},
					# Core Unit Identifier
					'megabit' => {
						'few' => q({0}Mbit),
						'many' => q({0}Mbit),
						'one' => q({0}Mbit),
						'other' => q({0}Mbit),
						'two' => q({0}Mbit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'few' => q({0}Mo),
						'many' => q({0}Mo),
						'one' => q({0}Mo),
						'other' => q({0}Mo),
						'two' => q({0}Mo),
					},
					# Core Unit Identifier
					'megabyte' => {
						'few' => q({0}Mo),
						'many' => q({0}Mo),
						'one' => q({0}Mo),
						'other' => q({0}Mo),
						'two' => q({0}Mo),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'few' => q({0}Po),
						'many' => q({0}Po),
						'one' => q({0}Po),
						'other' => q({0}Po),
						'two' => q({0}Po),
					},
					# Core Unit Identifier
					'petabyte' => {
						'few' => q({0}Po),
						'many' => q({0}Po),
						'one' => q({0}Po),
						'other' => q({0}Po),
						'two' => q({0}Po),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'few' => q({0}Tbit),
						'many' => q({0}Tbit),
						'one' => q({0}Tbit),
						'other' => q({0}Tbit),
						'two' => q({0}Tbit),
					},
					# Core Unit Identifier
					'terabit' => {
						'few' => q({0}Tbit),
						'many' => q({0}Tbit),
						'one' => q({0}Tbit),
						'other' => q({0}Tbit),
						'two' => q({0}Tbit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'few' => q({0}To),
						'many' => q({0}To),
						'one' => q({0}To),
						'other' => q({0}To),
						'two' => q({0}To),
					},
					# Core Unit Identifier
					'terabyte' => {
						'few' => q({0}To),
						'many' => q({0}To),
						'one' => q({0}To),
						'other' => q({0}To),
						'two' => q({0}To),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0}kved),
						'many' => q({0}kved),
						'one' => q({0}kved),
						'other' => q({0}kved),
						'two' => q({0}kved),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0}kved),
						'many' => q({0}kved),
						'one' => q({0}kved),
						'other' => q({0}kved),
						'two' => q({0}kved),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0}d),
						'many' => q({0}d),
						'one' => q({0}d),
						'other' => q({0}d),
						'two' => q({0}d),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0}d),
						'many' => q({0}d),
						'one' => q({0}d),
						'other' => q({0}d),
						'two' => q({0}d),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0}dek),
						'many' => q({0}dek),
						'one' => q({0}dek),
						'other' => q({0}dek),
						'two' => q({0}dek),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0}dek),
						'many' => q({0}dek),
						'one' => q({0}dek),
						'other' => q({0}dek),
						'two' => q({0}dek),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'few' => q({0}h),
						'many' => q({0}h),
						'one' => q({0}h),
						'other' => q({0}h),
						'two' => q({0}h),
					},
					# Core Unit Identifier
					'hour' => {
						'few' => q({0}h),
						'many' => q({0}h),
						'one' => q({0}h),
						'other' => q({0}h),
						'two' => q({0}h),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'few' => q({0}μs),
						'many' => q({0}μs),
						'one' => q({0}μs),
						'other' => q({0}μs),
						'two' => q({0}μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'few' => q({0}μs),
						'many' => q({0}μs),
						'one' => q({0}μs),
						'other' => q({0}μs),
						'two' => q({0}μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'few' => q({0}ms),
						'many' => q({0}ms),
						'one' => q({0}ms),
						'other' => q({0}ms),
						'two' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'few' => q({0}ms),
						'many' => q({0}ms),
						'one' => q({0}ms),
						'other' => q({0}ms),
						'two' => q({0}ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0}min),
						'many' => q({0}min),
						'one' => q({0}min),
						'other' => q({0}min),
						'two' => q({0}min),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0}min),
						'many' => q({0}min),
						'one' => q({0}min),
						'other' => q({0}min),
						'two' => q({0}min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0}m),
						'many' => q({0}m),
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
						'two' => q({0}m),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0}m),
						'many' => q({0}m),
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
						'per' => q({0}/m),
						'two' => q({0}m),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'few' => q({0}ns),
						'many' => q({0}ns),
						'one' => q({0}ns),
						'other' => q({0}ns),
						'two' => q({0}ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'few' => q({0}ns),
						'many' => q({0}ns),
						'one' => q({0}ns),
						'other' => q({0}ns),
						'two' => q({0}ns),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0}t),
						'many' => q({0}t),
						'name' => q(t),
						'one' => q({0}t),
						'other' => q({0}t),
						'per' => q({0}/t),
						'two' => q({0}t),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0}t),
						'many' => q({0}t),
						'name' => q(t),
						'one' => q({0}t),
						'other' => q({0}t),
						'per' => q({0}/t),
						'two' => q({0}t),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0}s),
						'many' => q({0}s),
						'one' => q({0}s),
						'other' => q({0}s),
						'two' => q({0}s),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0}s),
						'many' => q({0}s),
						'one' => q({0}s),
						'other' => q({0}s),
						'two' => q({0}s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0}sizh.),
						'many' => q({0}sizh.),
						'one' => q({0}sizh.),
						'other' => q({0}sizh.),
						'two' => q({0}sizh.),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0}sizh.),
						'many' => q({0}sizh.),
						'one' => q({0}sizh.),
						'other' => q({0}sizh.),
						'two' => q({0}sizh.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0}b),
						'many' => q({0}b),
						'name' => q(b),
						'one' => q({0}b),
						'other' => q({0}b),
						'per' => q({0}/b),
						'two' => q({0}b),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0}b),
						'many' => q({0}b),
						'name' => q(b),
						'one' => q({0}b),
						'other' => q({0}b),
						'per' => q({0}/b),
						'two' => q({0}b),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'few' => q({0}A),
						'many' => q({0}A),
						'one' => q({0}A),
						'other' => q({0}A),
						'two' => q({0}A),
					},
					# Core Unit Identifier
					'ampere' => {
						'few' => q({0}A),
						'many' => q({0}A),
						'one' => q({0}A),
						'other' => q({0}A),
						'two' => q({0}A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'few' => q({0}mA),
						'many' => q({0}mA),
						'one' => q({0}mA),
						'other' => q({0}mA),
						'two' => q({0} mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'few' => q({0}mA),
						'many' => q({0}mA),
						'one' => q({0}mA),
						'other' => q({0}mA),
						'two' => q({0} mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'few' => q({0}Ω),
						'many' => q({0}Ω),
						'one' => q({0}Ω),
						'other' => q({0}Ω),
						'two' => q({0}Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'few' => q({0}Ω),
						'many' => q({0}Ω),
						'one' => q({0}Ω),
						'other' => q({0}Ω),
						'two' => q({0}Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'few' => q({0}V),
						'many' => q({0}V),
						'one' => q({0}V),
						'other' => q({0}V),
						'two' => q({0}V),
					},
					# Core Unit Identifier
					'volt' => {
						'few' => q({0}V),
						'many' => q({0}V),
						'one' => q({0}V),
						'other' => q({0}V),
						'two' => q({0}V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'few' => q({0}Btu),
						'many' => q({0}Btu),
						'one' => q({0}Btu),
						'other' => q({0}Btu),
						'two' => q({0}Btu),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'few' => q({0}Btu),
						'many' => q({0}Btu),
						'one' => q({0}Btu),
						'other' => q({0}Btu),
						'two' => q({0}Btu),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'few' => q({0}cal),
						'many' => q({0}cal),
						'one' => q({0}cal),
						'other' => q({0}cal),
						'two' => q({0}cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'few' => q({0}cal),
						'many' => q({0}cal),
						'one' => q({0}cal),
						'other' => q({0}cal),
						'two' => q({0}cal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'few' => q({0}eV),
						'many' => q({0}eV),
						'one' => q({0}eV),
						'other' => q({0}eV),
						'two' => q({0}eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'few' => q({0}eV),
						'many' => q({0}eV),
						'one' => q({0}eV),
						'other' => q({0}eV),
						'two' => q({0}eV),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0}Cal),
						'many' => q({0}Cal),
						'one' => q({0}Cal),
						'other' => q({0}Cal),
						'two' => q({0}Cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0}Cal),
						'many' => q({0}Cal),
						'one' => q({0}Cal),
						'other' => q({0}Cal),
						'two' => q({0}Cal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'few' => q({0}J),
						'many' => q({0}J),
						'one' => q({0}J),
						'other' => q({0}J),
						'two' => q({0}J),
					},
					# Core Unit Identifier
					'joule' => {
						'few' => q({0}J),
						'many' => q({0}J),
						'one' => q({0}J),
						'other' => q({0}J),
						'two' => q({0}J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'few' => q({0}kcal),
						'many' => q({0}kcal),
						'one' => q({0}kcal),
						'other' => q({0}kcal),
						'two' => q({0}kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'few' => q({0}kcal),
						'many' => q({0}kcal),
						'one' => q({0}kcal),
						'other' => q({0}kcal),
						'two' => q({0}kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'few' => q({0}kJ),
						'many' => q({0}kJ),
						'one' => q({0}kJ),
						'other' => q({0}kJ),
						'two' => q({0}kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'few' => q({0}kJ),
						'many' => q({0}kJ),
						'one' => q({0}kJ),
						'other' => q({0}kJ),
						'two' => q({0}kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'few' => q({0}kWh),
						'many' => q({0}kWh),
						'one' => q({0}kWh),
						'other' => q({0}kWh),
						'two' => q({0}kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'few' => q({0}kWh),
						'many' => q({0}kWh),
						'one' => q({0}kWh),
						'other' => q({0}kWh),
						'two' => q({0}kWh),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'few' => q({0}thm),
						'many' => q({0}thm),
						'name' => q(thm),
						'one' => q({0}thm),
						'other' => q({0}thm),
						'two' => q({0}thm),
					},
					# Core Unit Identifier
					'therm-us' => {
						'few' => q({0}thm),
						'many' => q({0}thm),
						'name' => q(thm),
						'one' => q({0}thm),
						'other' => q({0}thm),
						'two' => q({0}thm),
					},
					# Long Unit Identifier
					'force-newton' => {
						'few' => q({0}N),
						'many' => q({0}N),
						'one' => q({0}N),
						'other' => q({0}N),
						'two' => q({0}N),
					},
					# Core Unit Identifier
					'newton' => {
						'few' => q({0}N),
						'many' => q({0}N),
						'one' => q({0}N),
						'other' => q({0}N),
						'two' => q({0}N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'few' => q({0}lbf),
						'many' => q({0}lbf),
						'one' => q({0}lbf),
						'other' => q({0}lbf),
						'two' => q({0}lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'few' => q({0}lbf),
						'many' => q({0}lbf),
						'one' => q({0}lbf),
						'other' => q({0}lbf),
						'two' => q({0}lbf),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'few' => q({0}GHz),
						'many' => q({0}GHz),
						'one' => q({0}GHz),
						'other' => q({0}GHz),
						'two' => q({0}GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'few' => q({0}GHz),
						'many' => q({0}GHz),
						'one' => q({0}GHz),
						'other' => q({0}GHz),
						'two' => q({0}GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'few' => q({0}Hz),
						'many' => q({0}Hz),
						'one' => q({0}Hz),
						'other' => q({0}Hz),
						'two' => q({0}Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'few' => q({0}Hz),
						'many' => q({0}Hz),
						'one' => q({0}Hz),
						'other' => q({0}Hz),
						'two' => q({0}Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'few' => q({0}kHz),
						'many' => q({0}kHz),
						'one' => q({0}kHz),
						'other' => q({0}kHz),
						'two' => q({0}kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'few' => q({0}kHz),
						'many' => q({0}kHz),
						'one' => q({0}kHz),
						'other' => q({0}kHz),
						'two' => q({0}kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'few' => q({0}MHz),
						'many' => q({0}MHz),
						'one' => q({0}MHz),
						'other' => q({0}MHz),
						'two' => q({0}MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'few' => q({0}MHz),
						'many' => q({0}MHz),
						'one' => q({0}MHz),
						'other' => q({0}MHz),
						'two' => q({0}MHz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'few' => q({0}pik),
						'many' => q({0}pik),
						'one' => q({0}pik),
						'other' => q({0}pik),
						'two' => q({0}pik),
					},
					# Core Unit Identifier
					'dot' => {
						'few' => q({0}pik),
						'many' => q({0}pik),
						'one' => q({0}pik),
						'other' => q({0}pik),
						'two' => q({0}pik),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0}pdcm),
						'many' => q({0}pdcm),
						'one' => q({0}pdcm),
						'other' => q({0}pdcm),
						'two' => q({0}pdcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0}pdcm),
						'many' => q({0}pdcm),
						'one' => q({0}pdcm),
						'other' => q({0}pdcm),
						'two' => q({0}pdcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0}pdm),
						'many' => q({0}pdm),
						'one' => q({0}pdm),
						'other' => q({0}pdm),
						'two' => q({0}pdm),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0}pdm),
						'many' => q({0}pdm),
						'one' => q({0}pdm),
						'other' => q({0}pdm),
						'two' => q({0}pdm),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'few' => q({0}em),
						'many' => q({0}em),
						'one' => q({0}em),
						'other' => q({0}em),
						'two' => q({0}em),
					},
					# Core Unit Identifier
					'em' => {
						'few' => q({0}em),
						'many' => q({0}em),
						'one' => q({0}em),
						'other' => q({0}em),
						'two' => q({0}em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'few' => q({0}Mpx),
						'many' => q({0}Mpx),
						'one' => q({0}Mpx),
						'other' => q({0}Mpx),
						'two' => q({0}Mpx),
					},
					# Core Unit Identifier
					'megapixel' => {
						'few' => q({0}Mpx),
						'many' => q({0}Mpx),
						'one' => q({0}Mpx),
						'other' => q({0}Mpx),
						'two' => q({0}Mpx),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'few' => q({0}px),
						'many' => q({0}px),
						'one' => q({0}px),
						'other' => q({0}px),
						'two' => q({0}px),
					},
					# Core Unit Identifier
					'pixel' => {
						'few' => q({0}px),
						'many' => q({0}px),
						'one' => q({0}px),
						'other' => q({0}px),
						'two' => q({0}px),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'few' => q({0}px/cm),
						'many' => q({0}px/cm),
						'one' => q({0}px/cm),
						'other' => q({0}px/cm),
						'two' => q({0}px/cm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'few' => q({0}px/cm),
						'many' => q({0}px/cm),
						'one' => q({0}px/cm),
						'other' => q({0}px/cm),
						'two' => q({0}px/cm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'few' => q({0}px/in),
						'many' => q({0}px/in),
						'one' => q({0}px/in),
						'other' => q({0}px/in),
						'two' => q({0}px/in),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'few' => q({0}px/in),
						'many' => q({0}px/in),
						'one' => q({0}px/in),
						'other' => q({0}px/in),
						'two' => q({0}px/in),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0}au),
						'many' => q({0}au),
						'one' => q({0}au),
						'other' => q({0}au),
						'two' => q({0}au),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0}au),
						'many' => q({0}au),
						'one' => q({0}au),
						'other' => q({0}au),
						'two' => q({0}au),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'few' => q({0}cm),
						'many' => q({0}cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
						'two' => q({0}cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'few' => q({0}cm),
						'many' => q({0}cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
						'two' => q({0}cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'few' => q({0}dm),
						'many' => q({0}dm),
						'one' => q({0}dm),
						'other' => q({0}dm),
						'two' => q({0}dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'few' => q({0}dm),
						'many' => q({0}dm),
						'one' => q({0}dm),
						'other' => q({0}dm),
						'two' => q({0}dm),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'few' => q({0}R⊕),
						'many' => q({0}R⊕),
						'one' => q({0}R⊕),
						'other' => q({0}R⊕),
						'two' => q({0}R⊕),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'few' => q({0}R⊕),
						'many' => q({0}R⊕),
						'one' => q({0}R⊕),
						'other' => q({0}R⊕),
						'two' => q({0}R⊕),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'few' => q({0}fth),
						'many' => q({0}fth),
						'one' => q({0}fth),
						'other' => q({0}fth),
						'two' => q({0}fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'few' => q({0}fth),
						'many' => q({0}fth),
						'one' => q({0}fth),
						'other' => q({0}fth),
						'two' => q({0}fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0}′),
						'many' => q({0}′),
						'name' => q(′),
						'one' => q({0}′),
						'other' => q({0}′),
						'per' => q({0}/′),
						'two' => q({0}′),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0}′),
						'many' => q({0}′),
						'name' => q(′),
						'one' => q({0}′),
						'other' => q({0}′),
						'per' => q({0}/′),
						'two' => q({0}′),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'few' => q({0}fur),
						'many' => q({0}fur),
						'one' => q({0}fur),
						'other' => q({0}fur),
						'two' => q({0}fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'few' => q({0}fur),
						'many' => q({0}fur),
						'one' => q({0}fur),
						'other' => q({0}fur),
						'two' => q({0}fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0}″),
						'many' => q({0}″),
						'name' => q(″),
						'one' => q({0}″),
						'other' => q({0}″),
						'per' => q({0}/″),
						'two' => q({0}″),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0}″),
						'many' => q({0}″),
						'name' => q(″),
						'one' => q({0}″),
						'other' => q({0}″),
						'per' => q({0}/″),
						'two' => q({0}″),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'few' => q({0}km),
						'many' => q({0}km),
						'one' => q({0}km),
						'other' => q({0}km),
						'two' => q({0}km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'few' => q({0}km),
						'many' => q({0}km),
						'one' => q({0}km),
						'other' => q({0}km),
						'two' => q({0}km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0}b.g.),
						'many' => q({0}b.g.),
						'one' => q({0}b.g.),
						'other' => q({0}b.g.),
						'two' => q({0}b.g.),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0}b.g.),
						'many' => q({0}b.g.),
						'one' => q({0}b.g.),
						'other' => q({0}b.g.),
						'two' => q({0}b.g.),
					},
					# Long Unit Identifier
					'length-meter' => {
						'few' => q({0}m),
						'many' => q({0}m),
						'one' => q({0}m),
						'other' => q({0}m),
						'two' => q({0}m),
					},
					# Core Unit Identifier
					'meter' => {
						'few' => q({0}m),
						'many' => q({0}m),
						'one' => q({0}m),
						'other' => q({0}m),
						'two' => q({0}m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'few' => q({0}μm),
						'many' => q({0}μm),
						'one' => q({0}μm),
						'other' => q({0}μm),
						'two' => q({0}μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'few' => q({0}μm),
						'many' => q({0}μm),
						'one' => q({0}μm),
						'other' => q({0}μm),
						'two' => q({0}μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0}mi),
						'many' => q({0}mi),
						'one' => q({0}mi),
						'other' => q({0}mi),
						'two' => q({0}mi),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0}mi),
						'many' => q({0}mi),
						'one' => q({0}mi),
						'other' => q({0}mi),
						'two' => q({0}mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'few' => q({0}smi),
						'many' => q({0}smi),
						'one' => q({0}smi),
						'other' => q({0}smi),
						'two' => q({0}smi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'few' => q({0}smi),
						'many' => q({0}smi),
						'one' => q({0}smi),
						'other' => q({0}smi),
						'two' => q({0}smi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'few' => q({0}mm),
						'many' => q({0}mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
						'two' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'few' => q({0}mm),
						'many' => q({0}mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
						'two' => q({0}mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'few' => q({0}nm),
						'many' => q({0}nm),
						'one' => q({0}nm),
						'other' => q({0}nm),
						'two' => q({0}nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'few' => q({0}nm),
						'many' => q({0}nm),
						'one' => q({0}nm),
						'other' => q({0}nm),
						'two' => q({0}nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0}nmi),
						'many' => q({0}nmi),
						'one' => q({0}nmi),
						'other' => q({0}nmi),
						'two' => q({0}nmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0}nmi),
						'many' => q({0}nmi),
						'one' => q({0}nmi),
						'other' => q({0}nmi),
						'two' => q({0}nmi),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'few' => q({0}pc),
						'many' => q({0}pc),
						'one' => q({0}pc),
						'other' => q({0}pc),
						'two' => q({0}pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'few' => q({0}pc),
						'many' => q({0}pc),
						'one' => q({0}pc),
						'other' => q({0}pc),
						'two' => q({0}pc),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'few' => q({0}pm),
						'many' => q({0}pm),
						'one' => q({0}pm),
						'other' => q({0}pm),
						'two' => q({0}pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'few' => q({0}pm),
						'many' => q({0}pm),
						'one' => q({0}pm),
						'other' => q({0}pm),
						'two' => q({0}pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'few' => q({0}pt),
						'many' => q({0}pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
						'two' => q({0}pt),
					},
					# Core Unit Identifier
					'point' => {
						'few' => q({0}pt),
						'many' => q({0}pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
						'two' => q({0}pt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'few' => q({0}R☉),
						'many' => q({0}R☉),
						'one' => q({0}R☉),
						'other' => q({0}R☉),
						'two' => q({0}R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'few' => q({0}R☉),
						'many' => q({0}R☉),
						'one' => q({0}R☉),
						'other' => q({0}R☉),
						'two' => q({0}R☉),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0}yd),
						'many' => q({0}yd),
						'one' => q({0}yd),
						'other' => q({0}yd),
						'two' => q({0}yd),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0}yd),
						'many' => q({0}yd),
						'one' => q({0}yd),
						'other' => q({0}yd),
						'two' => q({0}yd),
					},
					# Long Unit Identifier
					'light-candela' => {
						'few' => q({0}cd),
						'many' => q({0}cd),
						'one' => q({0}cd),
						'other' => q({0}cd),
						'two' => q({0}cd),
					},
					# Core Unit Identifier
					'candela' => {
						'few' => q({0}cd),
						'many' => q({0}cd),
						'one' => q({0}cd),
						'other' => q({0}cd),
						'two' => q({0}cd),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'few' => q({0}lm),
						'many' => q({0}lm),
						'one' => q({0}lm),
						'other' => q({0}lm),
						'two' => q({0}lm),
					},
					# Core Unit Identifier
					'lumen' => {
						'few' => q({0}lm),
						'many' => q({0}lm),
						'one' => q({0}lm),
						'other' => q({0}lm),
						'two' => q({0}lm),
					},
					# Long Unit Identifier
					'light-lux' => {
						'few' => q({0}lx),
						'many' => q({0}lx),
						'one' => q({0}lx),
						'other' => q({0}lx),
						'two' => q({0}lx),
					},
					# Core Unit Identifier
					'lux' => {
						'few' => q({0}lx),
						'many' => q({0}lx),
						'one' => q({0}lx),
						'other' => q({0}lx),
						'two' => q({0}lx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'few' => q({0}L☉),
						'many' => q({0}L☉),
						'one' => q({0}L☉),
						'other' => q({0}L☉),
						'two' => q({0}L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'few' => q({0}L☉),
						'many' => q({0}L☉),
						'one' => q({0}L☉),
						'other' => q({0}L☉),
						'two' => q({0}L☉),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'few' => q({0}CD),
						'many' => q({0}CD),
						'one' => q({0}CD),
						'other' => q({0}CD),
						'two' => q({0}CD),
					},
					# Core Unit Identifier
					'carat' => {
						'few' => q({0}CD),
						'many' => q({0}CD),
						'one' => q({0}CD),
						'other' => q({0}CD),
						'two' => q({0}CD),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'few' => q({0}Da),
						'many' => q({0} Da),
						'one' => q({0}Da),
						'other' => q({0}Da),
						'two' => q({0}Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'few' => q({0}Da),
						'many' => q({0} Da),
						'one' => q({0}Da),
						'other' => q({0}Da),
						'two' => q({0}Da),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'few' => q({0}M⊕),
						'many' => q({0}M⊕),
						'one' => q({0}M⊕),
						'other' => q({0}M⊕),
						'two' => q({0}M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'few' => q({0}M⊕),
						'many' => q({0}M⊕),
						'one' => q({0}M⊕),
						'other' => q({0}M⊕),
						'two' => q({0}M⊕),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0}gr),
						'many' => q({0}gr),
						'one' => q({0}gr),
						'other' => q({0}gr),
						'two' => q({0}gr),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0}gr),
						'many' => q({0}gr),
						'one' => q({0}gr),
						'other' => q({0}gr),
						'two' => q({0}gr),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'few' => q({0}g),
						'many' => q({0}g),
						'one' => q({0}g),
						'other' => q({0}g),
						'two' => q({0}g),
					},
					# Core Unit Identifier
					'gram' => {
						'few' => q({0}g),
						'many' => q({0}g),
						'one' => q({0}g),
						'other' => q({0}g),
						'two' => q({0}g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'few' => q({0}kg),
						'many' => q({0}kg),
						'one' => q({0}kg),
						'other' => q({0}kg),
						'two' => q({0}kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'few' => q({0}kg),
						'many' => q({0}kg),
						'one' => q({0}kg),
						'other' => q({0}kg),
						'two' => q({0}kg),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'few' => q({0}μg),
						'many' => q({0}μg),
						'one' => q({0}μg),
						'other' => q({0}μg),
						'two' => q({0}μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'few' => q({0}μg),
						'many' => q({0}μg),
						'one' => q({0}μg),
						'other' => q({0}μg),
						'two' => q({0}μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'few' => q({0}mg),
						'many' => q({0}mg),
						'one' => q({0}mg),
						'other' => q({0}mg),
						'two' => q({0}mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'few' => q({0}mg),
						'many' => q({0}mg),
						'one' => q({0}mg),
						'other' => q({0}mg),
						'two' => q({0}mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'few' => q({0}oz),
						'many' => q({0}oz),
						'one' => q({0}oz),
						'other' => q({0}oz),
						'two' => q({0}oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0}oz),
						'many' => q({0}oz),
						'one' => q({0}oz),
						'other' => q({0}oz),
						'two' => q({0}oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'few' => q({0}ozt),
						'many' => q({0}ozt),
						'name' => q(ozt),
						'one' => q({0}ozt),
						'other' => q({0}ozt),
						'two' => q({0}ozt),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'few' => q({0}ozt),
						'many' => q({0}ozt),
						'name' => q(ozt),
						'one' => q({0}ozt),
						'other' => q({0}ozt),
						'two' => q({0}ozt),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0}lb),
						'many' => q({0}lb),
						'one' => q({0}lb),
						'other' => q({0}lb),
						'two' => q({0}lb),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0}lb),
						'many' => q({0}lb),
						'one' => q({0}lb),
						'other' => q({0}lb),
						'two' => q({0}lb),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'few' => q({0}M☉),
						'many' => q({0}M☉),
						'one' => q({0}M☉),
						'other' => q({0}M☉),
						'two' => q({0}M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'few' => q({0}M☉),
						'many' => q({0}M☉),
						'one' => q({0}M☉),
						'other' => q({0}M☉),
						'two' => q({0}M☉),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'few' => q({0}st),
						'many' => q({0}st),
						'one' => q({0}st),
						'other' => q({0}st),
						'two' => q({0}st),
					},
					# Core Unit Identifier
					'stone' => {
						'few' => q({0}st),
						'many' => q({0}st),
						'one' => q({0}st),
						'other' => q({0}st),
						'two' => q({0}st),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0}tn),
						'many' => q({0}tn),
						'one' => q({0}tn),
						'other' => q({0}tn),
						'two' => q({0}tn),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0}tn),
						'many' => q({0}tn),
						'one' => q({0}tn),
						'other' => q({0}tn),
						'two' => q({0}tn),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'few' => q({0}t),
						'many' => q({0}t),
						'one' => q({0}t),
						'other' => q({0}t),
						'two' => q({0}t),
					},
					# Core Unit Identifier
					'tonne' => {
						'few' => q({0}t),
						'many' => q({0}t),
						'one' => q({0}t),
						'other' => q({0}t),
						'two' => q({0}t),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'few' => q({0}GW),
						'many' => q({0}GW),
						'one' => q({0}GW),
						'other' => q({0}GW),
						'two' => q({0}GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'few' => q({0}GW),
						'many' => q({0}GW),
						'one' => q({0}GW),
						'other' => q({0}GW),
						'two' => q({0}GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0}hp),
						'many' => q({0}hp),
						'one' => q({0}hp),
						'other' => q({0}hp),
						'two' => q({0}hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0}hp),
						'many' => q({0}hp),
						'one' => q({0}hp),
						'other' => q({0}hp),
						'two' => q({0}hp),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'few' => q({0}kW),
						'many' => q({0}kW),
						'one' => q({0}kW),
						'other' => q({0}kW),
						'two' => q({0}kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'few' => q({0}kW),
						'many' => q({0}kW),
						'one' => q({0}kW),
						'other' => q({0}kW),
						'two' => q({0}kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'few' => q({0}MW),
						'many' => q({0}MW),
						'one' => q({0}MW),
						'other' => q({0}MW),
						'two' => q({0}MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'few' => q({0}MW),
						'many' => q({0}MW),
						'one' => q({0}MW),
						'other' => q({0}MW),
						'two' => q({0}MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'few' => q({0}mW),
						'many' => q({0}mW),
						'one' => q({0}mW),
						'other' => q({0}mW),
						'two' => q({0}mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'few' => q({0}mW),
						'many' => q({0}mW),
						'one' => q({0}mW),
						'other' => q({0}mW),
						'two' => q({0}mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'few' => q({0}W),
						'many' => q({0}W),
						'one' => q({0}W),
						'other' => q({0}W),
						'two' => q({0}W),
					},
					# Core Unit Identifier
					'watt' => {
						'few' => q({0}W),
						'many' => q({0}W),
						'one' => q({0}W),
						'other' => q({0}W),
						'two' => q({0}W),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'few' => q({0}atm),
						'many' => q({0}atm),
						'one' => q({0}atm),
						'other' => q({0}atm),
						'two' => q({0}atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'few' => q({0}atm),
						'many' => q({0}atm),
						'one' => q({0}atm),
						'other' => q({0}atm),
						'two' => q({0}atm),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'few' => q({0}bar),
						'many' => q({0}bar),
						'one' => q({0}bar),
						'other' => q({0}bar),
						'two' => q({0}bar),
					},
					# Core Unit Identifier
					'bar' => {
						'few' => q({0}bar),
						'many' => q({0}bar),
						'one' => q({0}bar),
						'other' => q({0}bar),
						'two' => q({0}bar),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'few' => q({0}hPa),
						'many' => q({0}hPa),
						'one' => q({0}hPa),
						'other' => q({0}hPa),
						'two' => q({0}hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'few' => q({0}hPa),
						'many' => q({0}hPa),
						'one' => q({0}hPa),
						'other' => q({0}hPa),
						'two' => q({0}hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0}″Hg),
						'many' => q({0}″Hg),
						'name' => q(″Hg),
						'one' => q({0}″Hg),
						'other' => q({0}″Hg),
						'two' => q({0}″Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0}″Hg),
						'many' => q({0}″Hg),
						'name' => q(″Hg),
						'one' => q({0}″Hg),
						'other' => q({0}″Hg),
						'two' => q({0}″Hg),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'few' => q({0}kPa),
						'many' => q({0}kPa),
						'one' => q({0}kPa),
						'other' => q({0}kPa),
						'two' => q({0}kPa),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'few' => q({0}kPa),
						'many' => q({0}kPa),
						'one' => q({0}kPa),
						'other' => q({0}kPa),
						'two' => q({0}kPa),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'few' => q({0}MPa),
						'many' => q({0}MPa),
						'one' => q({0}MPa),
						'other' => q({0}MPa),
						'two' => q({0}MPa),
					},
					# Core Unit Identifier
					'megapascal' => {
						'few' => q({0}MPa),
						'many' => q({0}MPa),
						'one' => q({0}MPa),
						'other' => q({0}MPa),
						'two' => q({0}MPa),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0}mbar),
						'many' => q({0}mbar),
						'one' => q({0}mbar),
						'other' => q({0}mbar),
						'two' => q({0}mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0}mbar),
						'many' => q({0}mbar),
						'one' => q({0}mbar),
						'other' => q({0}mbar),
						'two' => q({0}mbar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0}mmHg),
						'many' => q({0}mmHg),
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
						'two' => q({0}mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0}mmHg),
						'many' => q({0}mmHg),
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
						'two' => q({0}mmHg),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'few' => q({0}Pa),
						'many' => q({0}Pa),
						'one' => q({0}Pa),
						'other' => q({0}Pa),
						'two' => q({0}Pa),
					},
					# Core Unit Identifier
					'pascal' => {
						'few' => q({0}Pa),
						'many' => q({0}Pa),
						'one' => q({0}Pa),
						'other' => q({0}Pa),
						'two' => q({0}Pa),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0}lb/in²),
						'many' => q({0}lb/in²),
						'one' => q({0}lb/in²),
						'other' => q({0}lb/in²),
						'two' => q({0}lb/in²),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0}lb/in²),
						'many' => q({0}lb/in²),
						'one' => q({0}lb/in²),
						'other' => q({0}lb/in²),
						'two' => q({0}lb/in²),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'few' => q({0}km/h),
						'many' => q({0}km/h),
						'one' => q({0}km/h),
						'other' => q({0}km/h),
						'two' => q({0}km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'few' => q({0}km/h),
						'many' => q({0}km/h),
						'one' => q({0}km/h),
						'other' => q({0}km/h),
						'two' => q({0}km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0}nd),
						'many' => q({0}nd),
						'one' => q({0}nd),
						'other' => q({0}nd),
						'two' => q({0}nd),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0}nd),
						'many' => q({0}nd),
						'one' => q({0}nd),
						'other' => q({0}nd),
						'two' => q({0}nd),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'few' => q({0}m/s),
						'many' => q({0}m/s),
						'one' => q({0}m/s),
						'other' => q({0}m/s),
						'two' => q({0}m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'few' => q({0}m/s),
						'many' => q({0}m/s),
						'one' => q({0}m/s),
						'other' => q({0}m/s),
						'two' => q({0}m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0}mi/h),
						'many' => q({0}mi/h),
						'one' => q({0}mi/h),
						'other' => q({0}mi/h),
						'two' => q({0}mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0}mi/h),
						'many' => q({0}mi/h),
						'one' => q({0}mi/h),
						'other' => q({0}mi/h),
						'two' => q({0}mi/h),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'few' => q({0}K),
						'many' => q({0}K),
						'one' => q({0}K),
						'other' => q({0}K),
						'two' => q({0}K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'few' => q({0}K),
						'many' => q({0}K),
						'one' => q({0}K),
						'other' => q({0}K),
						'two' => q({0}K),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'few' => q({0}N⋅m),
						'many' => q({0}N⋅m),
						'one' => q({0}N⋅m),
						'other' => q({0}N⋅m),
						'two' => q({0}N⋅m),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'few' => q({0}N⋅m),
						'many' => q({0}N⋅m),
						'one' => q({0}N⋅m),
						'other' => q({0}N⋅m),
						'two' => q({0}N⋅m),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'few' => q({0}lbf⋅ft),
						'many' => q({0}lbf⋅ft),
						'one' => q({0}lbf⋅ft),
						'other' => q({0}lbf⋅ft),
						'two' => q({0}lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'few' => q({0}lbf⋅ft),
						'many' => q({0}lbf⋅ft),
						'one' => q({0}lbf⋅ft),
						'other' => q({0}lbf⋅ft),
						'two' => q({0}lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'few' => q({0}acft),
						'many' => q({0}acft),
						'name' => q(acft),
						'one' => q({0}acft),
						'other' => q({0}acft),
						'two' => q({0}acft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'few' => q({0}acft),
						'many' => q({0}acft),
						'name' => q(acft),
						'one' => q({0}acft),
						'other' => q({0}acft),
						'two' => q({0}acft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'few' => q({0}bbl),
						'many' => q({0}bbl),
						'one' => q({0}bbl),
						'other' => q({0}bbl),
						'two' => q({0}bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'few' => q({0}bbl),
						'many' => q({0}bbl),
						'one' => q({0}bbl),
						'other' => q({0}bbl),
						'two' => q({0}bbl),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'few' => q({0}bu),
						'many' => q({0}bu),
						'one' => q({0}bu),
						'other' => q({0}bu),
						'two' => q({0}bu),
					},
					# Core Unit Identifier
					'bushel' => {
						'few' => q({0}bu),
						'many' => q({0}bu),
						'one' => q({0}bu),
						'other' => q({0}bu),
						'two' => q({0}bu),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'few' => q({0}cl),
						'many' => q({0}cl),
						'one' => q({0}cl),
						'other' => q({0}cl),
						'two' => q({0}cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'few' => q({0}cl),
						'many' => q({0}cl),
						'one' => q({0}cl),
						'other' => q({0}cl),
						'two' => q({0}cl),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'few' => q({0}cm³),
						'many' => q({0}cm³),
						'one' => q({0}cm³),
						'other' => q({0}cm³),
						'two' => q({0}cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'few' => q({0}cm³),
						'many' => q({0}cm³),
						'one' => q({0}cm³),
						'other' => q({0}cm³),
						'two' => q({0}cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0}ft³),
						'many' => q({0}ft³),
						'one' => q({0}ft³),
						'other' => q({0}ft³),
						'two' => q({0}ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0}ft³),
						'many' => q({0}ft³),
						'one' => q({0}ft³),
						'other' => q({0}ft³),
						'two' => q({0}ft³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0}in³),
						'many' => q({0}in³),
						'one' => q({0}in³),
						'other' => q({0}in³),
						'two' => q({0}in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0}in³),
						'many' => q({0}in³),
						'one' => q({0}in³),
						'other' => q({0}in³),
						'two' => q({0}in³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'few' => q({0}km³),
						'many' => q({0}km³),
						'one' => q({0}km³),
						'other' => q({0}km³),
						'two' => q({0}km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'few' => q({0}km³),
						'many' => q({0}km³),
						'one' => q({0}km³),
						'other' => q({0}km³),
						'two' => q({0}km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'few' => q({0}m³),
						'many' => q({0}m³),
						'one' => q({0}m³),
						'other' => q({0}m³),
						'two' => q({0}m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'few' => q({0}m³),
						'many' => q({0}m³),
						'one' => q({0}m³),
						'other' => q({0}m³),
						'two' => q({0}m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0}mi³),
						'many' => q({0}mi³),
						'one' => q({0}mi³),
						'other' => q({0}mi³),
						'two' => q({0}mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0}mi³),
						'many' => q({0}mi³),
						'one' => q({0}mi³),
						'other' => q({0}mi³),
						'two' => q({0}mi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0}yd³),
						'many' => q({0}yd³),
						'one' => q({0}yd³),
						'other' => q({0}yd³),
						'two' => q({0}yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0}yd³),
						'many' => q({0}yd³),
						'one' => q({0}yd³),
						'other' => q({0}yd³),
						'two' => q({0}yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0}tas.),
						'many' => q({0}tas.),
						'one' => q({0}tas.),
						'other' => q({0}tas.),
						'two' => q({0}tas.),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0}tas.),
						'many' => q({0}tas.),
						'one' => q({0}tas.),
						'other' => q({0}tas.),
						'two' => q({0}tas.),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'few' => q({0}tm),
						'many' => q({0}tm),
						'one' => q({0}tm),
						'other' => q({0}tm),
						'two' => q({0}tm),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'few' => q({0}tm),
						'many' => q({0}tm),
						'one' => q({0}tm),
						'other' => q({0}tm),
						'two' => q({0}tm),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'few' => q({0}dl),
						'many' => q({0}dl),
						'one' => q({0}dl),
						'other' => q({0}dl),
						'two' => q({0}dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'few' => q({0}dl),
						'many' => q({0}dl),
						'one' => q({0}dl),
						'other' => q({0}dl),
						'two' => q({0}dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0}l.d.-b.),
						'many' => q({0}l.d.-b.),
						'one' => q({0}l.d.-b.),
						'other' => q({0}l.d.-b.),
						'two' => q({0}l.d.-b.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0}l.d.-b.),
						'many' => q({0}l.d.-b.),
						'one' => q({0}l.d.-b.),
						'other' => q({0}l.d.-b.),
						'two' => q({0}l.d.-b.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0}ldb Imp),
						'many' => q({0}ldb Imp),
						'name' => q(ldb Imp),
						'one' => q({0}ldb Imp),
						'other' => q({0}ldb Imp),
						'two' => q({0}ldb Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0}ldb Imp),
						'many' => q({0}ldb Imp),
						'name' => q(ldb Imp),
						'one' => q({0}ldb Imp),
						'other' => q({0}ldb Imp),
						'two' => q({0}ldb Imp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0}fl dr),
						'many' => q({0}fl dr),
						'one' => q({0}fl dr),
						'other' => q({0}fl dr),
						'two' => q({0}fl dr),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0}fl dr),
						'many' => q({0}fl dr),
						'one' => q({0}fl dr),
						'other' => q({0}fl dr),
						'two' => q({0}fl dr),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0}gt),
						'many' => q({0}gt),
						'one' => q({0}gt),
						'other' => q({0}gt),
						'two' => q({0}gt),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0}gt),
						'many' => q({0}gt),
						'one' => q({0}gt),
						'other' => q({0}gt),
						'two' => q({0}gt),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0}fl oz),
						'many' => q({0}fl oz),
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
						'two' => q({0}fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0}fl oz),
						'many' => q({0}fl oz),
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
						'two' => q({0}fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0}fl oz Im),
						'many' => q({0}fl oz Im),
						'name' => q(fl oz Im),
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
						'two' => q({0}fl oz Im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0}fl oz Im),
						'many' => q({0}fl oz Im),
						'name' => q(fl oz Im),
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
						'two' => q({0}fl oz Im),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0}gal),
						'many' => q({0}gal),
						'one' => q({0}gal),
						'other' => q({0}gal),
						'two' => q({0}gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0}gal),
						'many' => q({0}gal),
						'one' => q({0}gal),
						'other' => q({0}gal),
						'two' => q({0}gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0}galIm),
						'many' => q({0}galIm),
						'name' => q(galIm),
						'one' => q({0}galIm),
						'other' => q({0}galIm),
						'per' => q({0}/galIm),
						'two' => q({0}galIm),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0}galIm),
						'many' => q({0}galIm),
						'name' => q(galIm),
						'one' => q({0}galIm),
						'other' => q({0}galIm),
						'per' => q({0}/galIm),
						'two' => q({0}galIm),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'few' => q({0}hl),
						'many' => q({0}hl),
						'one' => q({0}hl),
						'other' => q({0}hl),
						'two' => q({0}hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'few' => q({0}hl),
						'many' => q({0}hl),
						'one' => q({0}hl),
						'other' => q({0}hl),
						'two' => q({0}hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0}shot),
						'many' => q({0}shot),
						'one' => q({0}shot),
						'other' => q({0}shot),
						'two' => q({0}shot),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0}shot),
						'many' => q({0}shot),
						'one' => q({0}shot),
						'other' => q({0}shot),
						'two' => q({0}shot),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'few' => q({0}l),
						'many' => q({0}l),
						'one' => q({0}l),
						'other' => q({0}l),
						'two' => q({0}l),
					},
					# Core Unit Identifier
					'liter' => {
						'few' => q({0}l),
						'many' => q({0}l),
						'one' => q({0}l),
						'other' => q({0}l),
						'two' => q({0}l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'few' => q({0}Ml),
						'many' => q({0}Ml),
						'one' => q({0}Ml),
						'other' => q({0}Ml),
						'two' => q({0}Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'few' => q({0}Ml),
						'many' => q({0}Ml),
						'one' => q({0}Ml),
						'other' => q({0}Ml),
						'two' => q({0}Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'few' => q({0}ml),
						'many' => q({0}ml),
						'one' => q({0}ml),
						'other' => q({0}ml),
						'two' => q({0}ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'few' => q({0}ml),
						'many' => q({0}ml),
						'one' => q({0}ml),
						'other' => q({0}ml),
						'two' => q({0}ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0}piñs),
						'many' => q({0}piñs),
						'one' => q({0}piñs),
						'other' => q({0}piñs),
						'two' => q({0}piñs),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0}piñs),
						'many' => q({0}piñs),
						'one' => q({0}piñs),
						'other' => q({0}piñs),
						'two' => q({0}piñs),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'few' => q({0}pt),
						'many' => q({0}pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
						'two' => q({0}pt),
					},
					# Core Unit Identifier
					'pint' => {
						'few' => q({0}pt),
						'many' => q({0}pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
						'two' => q({0}pt),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'few' => q({0}mpt),
						'many' => q({0}mpt),
						'one' => q({0}mpt),
						'other' => q({0}mpt),
						'two' => q({0}mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'few' => q({0}mpt),
						'many' => q({0}mpt),
						'one' => q({0}mpt),
						'other' => q({0}mpt),
						'two' => q({0}mpt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'few' => q({0}qt),
						'many' => q({0}qt),
						'one' => q({0}qt),
						'other' => q({0}qt),
						'two' => q({0}qt),
					},
					# Core Unit Identifier
					'quart' => {
						'few' => q({0}qt),
						'many' => q({0}qt),
						'one' => q({0}qt),
						'other' => q({0}qt),
						'two' => q({0}qt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0}qt Imp.),
						'many' => q({0}qt Imp.),
						'one' => q({0}qt Imp.),
						'other' => q({0}qt Imp.),
						'two' => q({0}qt Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0}qt Imp.),
						'many' => q({0}qt Imp.),
						'one' => q({0}qt Imp.),
						'other' => q({0}qt Imp.),
						'two' => q({0}qt Imp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0}l.-v.),
						'many' => q({0}l.-v.),
						'one' => q({0}l.-v.),
						'other' => q({0}l.-v.),
						'two' => q({0}l.-v.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0}l.-v.),
						'many' => q({0}l.-v.),
						'one' => q({0}l.-v.),
						'other' => q({0}l.-v.),
						'two' => q({0}l.-v.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0}l.-g.),
						'many' => q({0}l.-g.),
						'one' => q({0}l.-g.),
						'other' => q({0}l.-g.),
						'two' => q({0}l.-g.),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0}l.-g.),
						'many' => q({0}l.-g.),
						'one' => q({0}l.-g.),
						'other' => q({0}l.-g.),
						'two' => q({0}l.-g.),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(durcʼhadur),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(durcʼhadur),
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
						'name' => q(′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'few' => q({0} deg),
						'many' => q({0} deg),
						'one' => q({0} deg),
						'other' => q({0} deg),
						'two' => q({0} deg),
					},
					# Core Unit Identifier
					'degree' => {
						'few' => q({0} deg),
						'many' => q({0} deg),
						'one' => q({0} deg),
						'other' => q({0} deg),
						'two' => q({0} deg),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0} tr),
						'many' => q({0} tr),
						'name' => q(tr),
						'one' => q({0} tr),
						'other' => q({0} tr),
						'two' => q({0} tr),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0} tr),
						'many' => q({0} tr),
						'name' => q(tr),
						'one' => q({0} tr),
						'other' => q({0} tr),
						'two' => q({0} tr),
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
						'few' => q({0} dounam),
						'many' => q({0} dounam),
						'name' => q(dounam),
						'one' => q({0} dounam),
						'other' => q({0} dounam),
						'two' => q({0} dounam),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0} dounam),
						'many' => q({0} dounam),
						'name' => q(dounam),
						'one' => q({0} dounam),
						'other' => q({0} dounam),
						'two' => q({0} dounam),
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
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} mg/dl),
						'many' => q({0} mg/dl),
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
						'two' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} mg/dl),
						'many' => q({0} mg/dl),
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
						'two' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'few' => q({0} mmol/l),
						'many' => q({0} mmol/l),
						'name' => q(millimol/litr),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
						'two' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'few' => q({0} mmol/l),
						'many' => q({0} mmol/l),
						'name' => q(millimol/litr),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
						'two' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'few' => q({0} %),
						'many' => q({0} %),
						'one' => q({0} %),
						'other' => q({0} %),
						'two' => q({0} %),
					},
					# Core Unit Identifier
					'percent' => {
						'few' => q({0} %),
						'many' => q({0} %),
						'one' => q({0} %),
						'other' => q({0} %),
						'two' => q({0} %),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'few' => q({0} ‰),
						'many' => q({0} ‰),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
						'two' => q({0} ‰),
					},
					# Core Unit Identifier
					'permille' => {
						'few' => q({0} ‰),
						'many' => q({0} ‰),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
						'two' => q({0} ‰),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'few' => q({0} ‱),
						'many' => q({0} ‱),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
						'two' => q({0} ‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'few' => q({0} ‱),
						'many' => q({0} ‱),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
						'two' => q({0} ‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} l/100km),
						'many' => q({0} l/100km),
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
						'two' => q({0} l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} l/100km),
						'many' => q({0} l/100km),
						'name' => q(l/100km),
						'one' => q({0} l/100km),
						'other' => q({0} l/100km),
						'two' => q({0} l/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} l/km),
						'many' => q({0} l/km),
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
						'two' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} l/km),
						'many' => q({0} l/km),
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
						'two' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} mi/gal),
						'many' => q({0} mi/gal),
						'name' => q(mi/gal),
						'one' => q({0} mi/gal),
						'other' => q({0} mi/gal),
						'two' => q({0} mi/gal),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} mi/gal),
						'many' => q({0} mi/gal),
						'name' => q(mi/gal),
						'one' => q({0} mi/gal),
						'other' => q({0} mi/gal),
						'two' => q({0} mi/gal),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} mi/gal imp.),
						'many' => q({0} mi/gal imp.),
						'name' => q(mi/gal imp.),
						'one' => q({0} mi/gal imp.),
						'other' => q({0} mi/gal imp.),
						'two' => q({0} mi/gal imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} mi/gal imp.),
						'many' => q({0} mi/gal imp.),
						'name' => q(mi/gal imp.),
						'one' => q({0} mi/gal imp.),
						'other' => q({0} mi/gal imp.),
						'two' => q({0} mi/gal imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} R),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} K),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} R),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} K),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0} o),
						'many' => q({0} o),
						'name' => q(o),
						'one' => q({0} o),
						'other' => q({0} o),
						'two' => q({0} o),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} o),
						'many' => q({0} o),
						'name' => q(o),
						'one' => q({0} o),
						'other' => q({0} o),
						'two' => q({0} o),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'few' => q({0} Gbit),
						'many' => q({0} Gbit),
						'name' => q(Gbit),
						'one' => q({0} Gbit),
						'other' => q({0} Gbit),
						'two' => q({0} Gbit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'few' => q({0} Gbit),
						'many' => q({0} Gbit),
						'name' => q(Gbit),
						'one' => q({0} Gbit),
						'other' => q({0} Gbit),
						'two' => q({0} Gbit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'few' => q({0} Go),
						'many' => q({0} Go),
						'name' => q(Go),
						'one' => q({0} Go),
						'other' => q({0} Go),
						'two' => q({0} Go),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'few' => q({0} Go),
						'many' => q({0} Go),
						'name' => q(Go),
						'one' => q({0} Go),
						'other' => q({0} Go),
						'two' => q({0} Go),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'few' => q({0} kbit),
						'many' => q({0} kbit),
						'name' => q(kbit),
						'one' => q({0} kbit),
						'other' => q({0} kbit),
						'two' => q({0} kbit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'few' => q({0} kbit),
						'many' => q({0} kbit),
						'name' => q(kbit),
						'one' => q({0} kbit),
						'other' => q({0} kbit),
						'two' => q({0} kbit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'few' => q({0} ko),
						'many' => q({0} ko),
						'name' => q(ko),
						'one' => q({0} ko),
						'other' => q({0} ko),
						'two' => q({0} ko),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'few' => q({0} ko),
						'many' => q({0} ko),
						'name' => q(ko),
						'one' => q({0} ko),
						'other' => q({0} ko),
						'two' => q({0} ko),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'few' => q({0} Mbit),
						'many' => q({0} Mbit),
						'name' => q(Mbit),
						'one' => q({0} Mbit),
						'other' => q({0} Mbit),
						'two' => q({0} Mbit),
					},
					# Core Unit Identifier
					'megabit' => {
						'few' => q({0} Mbit),
						'many' => q({0} Mbit),
						'name' => q(Mbit),
						'one' => q({0} Mbit),
						'other' => q({0} Mbit),
						'two' => q({0} Mbit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'few' => q({0} Mo),
						'many' => q({0} Mo),
						'name' => q(Mo),
						'one' => q({0} Mo),
						'other' => q({0} Mo),
						'two' => q({0} Mo),
					},
					# Core Unit Identifier
					'megabyte' => {
						'few' => q({0} Mo),
						'many' => q({0} Mo),
						'name' => q(Mo),
						'one' => q({0} Mo),
						'other' => q({0} Mo),
						'two' => q({0} Mo),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'few' => q({0} Po),
						'many' => q({0} Po),
						'name' => q(Po),
						'one' => q({0} Po),
						'other' => q({0} Po),
						'two' => q({0} Po),
					},
					# Core Unit Identifier
					'petabyte' => {
						'few' => q({0} Po),
						'many' => q({0} Po),
						'name' => q(Po),
						'one' => q({0} Po),
						'other' => q({0} Po),
						'two' => q({0} Po),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'few' => q({0} Tbit),
						'many' => q({0} Tbit),
						'name' => q(Tbit),
						'one' => q({0} Tbit),
						'other' => q({0} Tbit),
						'two' => q({0} Tbit),
					},
					# Core Unit Identifier
					'terabit' => {
						'few' => q({0} Tbit),
						'many' => q({0} Tbit),
						'name' => q(Tbit),
						'one' => q({0} Tbit),
						'other' => q({0} Tbit),
						'two' => q({0} Tbit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'few' => q({0} To),
						'many' => q({0} To),
						'name' => q(To),
						'one' => q({0} To),
						'other' => q({0} To),
						'two' => q({0} To),
					},
					# Core Unit Identifier
					'terabyte' => {
						'few' => q({0} To),
						'many' => q({0} To),
						'name' => q(To),
						'one' => q({0} To),
						'other' => q({0} To),
						'two' => q({0} To),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} kved),
						'many' => q({0} kved),
						'name' => q(kved),
						'one' => q({0} kved),
						'other' => q({0} kved),
						'two' => q({0} kved),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} kved),
						'many' => q({0} kved),
						'name' => q(kved),
						'one' => q({0} kved),
						'other' => q({0} kved),
						'two' => q({0} kved),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(d),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0} dek),
						'many' => q({0} dek),
						'name' => q(dek),
						'one' => q({0} dek),
						'other' => q({0} dek),
						'two' => q({0} dek),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0} dek),
						'many' => q({0} dek),
						'name' => q(dek),
						'one' => q({0} dek),
						'other' => q({0} dek),
						'two' => q({0} dek),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(h),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} m.),
						'many' => q({0} m.),
						'name' => q(m.),
						'one' => q({0} m.),
						'other' => q({0} m.),
						'per' => q({0}/m.),
						'two' => q({0} m.),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} m.),
						'many' => q({0} m.),
						'name' => q(m.),
						'one' => q({0} m.),
						'other' => q({0} m.),
						'per' => q({0}/m.),
						'two' => q({0} m.),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} trim.),
						'many' => q({0} trim.),
						'name' => q(trim.),
						'one' => q({0} trim.),
						'other' => q({0} trim.),
						'per' => q({0}/trim.),
						'two' => q({0} trim.),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} trim.),
						'many' => q({0} trim.),
						'name' => q(trim.),
						'one' => q({0} trim.),
						'other' => q({0} trim.),
						'per' => q({0}/trim.),
						'two' => q({0} trim.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} sizh.),
						'many' => q({0} sizh.),
						'name' => q(sizh.),
						'one' => q({0} sizh.),
						'other' => q({0} sizh.),
						'per' => q({0}/sizh.),
						'two' => q({0} sizh.),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} sizh.),
						'many' => q({0} sizh.),
						'name' => q(sizh.),
						'one' => q({0} sizh.),
						'other' => q({0} sizh.),
						'per' => q({0}/sizh.),
						'two' => q({0} sizh.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} bl.),
						'many' => q({0} bl.),
						'name' => q(bl.),
						'one' => q({0} bl.),
						'other' => q({0} bl.),
						'per' => q({0}/bl.),
						'two' => q({0} bl.),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} bl.),
						'many' => q({0} bl.),
						'name' => q(bl.),
						'one' => q({0} bl.),
						'other' => q({0} bl.),
						'per' => q({0}/bl.),
						'two' => q({0} bl.),
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
					'energy-foodcalorie' => {
						'few' => q({0} Cal),
						'many' => q({0} Cal),
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
						'two' => q({0} Cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} Cal),
						'many' => q({0} Cal),
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
						'two' => q({0} Cal),
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
						'few' => q({0} thm SU),
						'many' => q({0} thm SU),
						'name' => q(thm SU),
						'one' => q({0} thm SU),
						'other' => q({0} thm SU),
						'two' => q({0} thm SU),
					},
					# Core Unit Identifier
					'therm-us' => {
						'few' => q({0} thm SU),
						'many' => q({0} thm SU),
						'name' => q(thm SU),
						'one' => q({0} thm SU),
						'other' => q({0} thm SU),
						'two' => q({0} thm SU),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'few' => q({0} pik),
						'many' => q({0} pik),
						'name' => q(pik),
						'one' => q({0} pik),
						'other' => q({0} pik),
						'two' => q({0} pik),
					},
					# Core Unit Identifier
					'dot' => {
						'few' => q({0} pik),
						'many' => q({0} pik),
						'name' => q(pik),
						'one' => q({0} pik),
						'other' => q({0} pik),
						'two' => q({0} pik),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} pdcm),
						'many' => q({0} pdcm),
						'name' => q(pdcm),
						'one' => q({0} pdcm),
						'other' => q({0} pdcm),
						'two' => q({0} pdcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} pdcm),
						'many' => q({0} pdcm),
						'name' => q(pdcm),
						'one' => q({0} pdcm),
						'other' => q({0} pdcm),
						'two' => q({0} pdcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} pdm),
						'many' => q({0} pdm),
						'name' => q(pdm),
						'one' => q({0} pdm),
						'other' => q({0} pdm),
						'two' => q({0} pdm),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} pdm),
						'many' => q({0} pdm),
						'name' => q(pdm),
						'one' => q({0} pdm),
						'other' => q({0} pdm),
						'two' => q({0} pdm),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'few' => q({0} Mpx),
						'many' => q({0} Mpx),
						'name' => q(Mpx),
						'one' => q({0} Mpx),
						'other' => q({0} Mpx),
						'two' => q({0} Mpx),
					},
					# Core Unit Identifier
					'megapixel' => {
						'few' => q({0} Mpx),
						'many' => q({0} Mpx),
						'name' => q(Mpx),
						'one' => q({0} Mpx),
						'other' => q({0} Mpx),
						'two' => q({0} Mpx),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'few' => q({0} px/cm),
						'many' => q({0} px/cm),
						'name' => q(px/cm),
						'one' => q({0} px/cm),
						'other' => q({0} px/cm),
						'two' => q({0} px/cm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'few' => q({0} px/cm),
						'many' => q({0} px/cm),
						'name' => q(px/cm),
						'one' => q({0} px/cm),
						'other' => q({0} px/cm),
						'two' => q({0} px/cm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'few' => q({0} px/in),
						'many' => q({0} px/in),
						'name' => q(px/in),
						'one' => q({0} px/in),
						'other' => q({0} px/in),
						'two' => q({0} px/in),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'few' => q({0} px/in),
						'many' => q({0} px/in),
						'name' => q(px/in),
						'one' => q({0} px/in),
						'other' => q({0} px/in),
						'two' => q({0} px/in),
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
					'length-light-year' => {
						'few' => q({0} b.g.),
						'many' => q({0} b.g.),
						'name' => q(b.g.),
						'one' => q({0} b.g.),
						'other' => q({0} b.g.),
						'two' => q({0} b.g.),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} b.g.),
						'many' => q({0} b.g.),
						'name' => q(b.g.),
						'one' => q({0} b.g.),
						'other' => q({0} b.g.),
						'two' => q({0} b.g.),
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
					'mass-grain' => {
						'few' => q({0} gr),
						'many' => q({0} gr),
						'name' => q(gr),
						'one' => q({0} gr),
						'other' => q({0} gr),
						'two' => q({0} gr),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} gr),
						'many' => q({0} gr),
						'name' => q(gr),
						'one' => q({0} gr),
						'other' => q({0} gr),
						'two' => q({0} gr),
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
					'power-watt' => {
						'name' => q(W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(W),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0} mmHg),
						'many' => q({0} mmHg),
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
						'two' => q({0} mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0} mmHg),
						'many' => q({0} mmHg),
						'name' => q(mmHg),
						'one' => q({0} mmHg),
						'other' => q({0} mmHg),
						'two' => q({0} mmHg),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0} lb/in²),
						'many' => q({0} lb/in²),
						'name' => q(lb/in²),
						'one' => q({0} lb/in²),
						'other' => q({0} lb/in²),
						'two' => q({0} lb/in²),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0} lb/in²),
						'many' => q({0} lb/in²),
						'name' => q(lb/in²),
						'one' => q({0} lb/in²),
						'other' => q({0} lb/in²),
						'two' => q({0} lb/in²),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0} nd),
						'many' => q({0} nd),
						'name' => q(nd),
						'one' => q({0} nd),
						'other' => q({0} nd),
						'two' => q({0} nd),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0} nd),
						'many' => q({0} nd),
						'name' => q(nd),
						'one' => q({0} nd),
						'other' => q({0} nd),
						'two' => q({0} nd),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'few' => q({0} cl),
						'many' => q({0} cl),
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
						'two' => q({0} cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'few' => q({0} cl),
						'many' => q({0} cl),
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
						'two' => q({0} cl),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0} tas.),
						'many' => q({0} tas.),
						'name' => q(tas.),
						'one' => q({0} tas.),
						'other' => q({0} tas.),
						'two' => q({0} tas.),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0} tas.),
						'many' => q({0} tas.),
						'name' => q(tas.),
						'one' => q({0} tas.),
						'other' => q({0} tas.),
						'two' => q({0} tas.),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'few' => q({0} tm),
						'many' => q({0} tm),
						'name' => q(tm),
						'one' => q({0} tm),
						'other' => q({0} tm),
						'two' => q({0} tm),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'few' => q({0} tm),
						'many' => q({0} tm),
						'name' => q(tm),
						'one' => q({0} tm),
						'other' => q({0} tm),
						'two' => q({0} tm),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'few' => q({0} dl),
						'many' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
						'two' => q({0} dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'few' => q({0} dl),
						'many' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
						'two' => q({0} dl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} l.d.-b.),
						'many' => q({0} l.d.-b.),
						'name' => q(l.d.-b.),
						'one' => q({0} l.d.-b.),
						'other' => q({0} l.d.-b.),
						'two' => q({0} l.d.-b.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} l.d.-b.),
						'many' => q({0} l.d.-b.),
						'name' => q(l.d.-b.),
						'one' => q({0} l.d.-b.),
						'other' => q({0} l.d.-b.),
						'two' => q({0} l.d.-b.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} l.d.-b. imp.),
						'many' => q({0} l.d.-b. imp.),
						'name' => q(l.d.-b. imp.),
						'one' => q({0} l.d.-b. imp.),
						'other' => q({0} l.d.-b. imp.),
						'two' => q({0} l.d.-b. imp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} l.d.-b. imp.),
						'many' => q({0} l.d.-b. imp.),
						'name' => q(l.d.-b. imp.),
						'one' => q({0} l.d.-b. imp.),
						'other' => q({0} l.d.-b. imp.),
						'two' => q({0} l.d.-b. imp.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} fl dr),
						'many' => q({0} fl dr),
						'name' => q(fl dr),
						'one' => q({0} fl dr),
						'other' => q({0} fl dr),
						'two' => q({0} fl dr),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} fl dr),
						'many' => q({0} fl dr),
						'name' => q(fl dr),
						'one' => q({0} fl dr),
						'other' => q({0} fl dr),
						'two' => q({0} fl dr),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0} gt),
						'many' => q({0} gt),
						'name' => q(gt),
						'one' => q({0} gt),
						'other' => q({0} gt),
						'two' => q({0} gt),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0} gt),
						'many' => q({0} gt),
						'name' => q(gt),
						'one' => q({0} gt),
						'other' => q({0} gt),
						'two' => q({0} gt),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} fl oz),
						'many' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
						'two' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} fl oz),
						'many' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
						'two' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} fl oz imp.),
						'many' => q({0} fl oz imp.),
						'name' => q(fl oz imp.),
						'one' => q({0} fl oz imp.),
						'other' => q({0} fl oz imp.),
						'two' => q({0} fl oz imp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} fl oz imp.),
						'many' => q({0} fl oz imp.),
						'name' => q(fl oz imp.),
						'one' => q({0} fl oz imp.),
						'other' => q({0} fl oz imp.),
						'two' => q({0} fl oz imp.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} gal),
						'many' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
						'two' => q({0} gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} gal),
						'many' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
						'two' => q({0} gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} gal imp.),
						'many' => q({0} gal imp.),
						'name' => q(gal imp.),
						'one' => q({0} gal imp.),
						'other' => q({0} gal imp.),
						'per' => q({0}/gal imp.),
						'two' => q({0} gal imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} gal imp.),
						'many' => q({0} gal imp.),
						'name' => q(gal imp.),
						'one' => q({0} gal imp.),
						'other' => q({0} gal imp.),
						'per' => q({0}/gal imp.),
						'two' => q({0} gal imp.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'few' => q({0} hl),
						'many' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
						'two' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'few' => q({0} hl),
						'many' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
						'two' => q({0} hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} shot),
						'many' => q({0} shot),
						'name' => q(shot),
						'one' => q({0} shot),
						'other' => q({0} shot),
						'two' => q({0} shot),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} shot),
						'many' => q({0} shot),
						'name' => q(shot),
						'one' => q({0} shot),
						'other' => q({0} shot),
						'two' => q({0} shot),
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
						'many' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
						'two' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'few' => q({0} Ml),
						'many' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
						'two' => q({0} Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'few' => q({0} ml),
						'many' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
						'two' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'few' => q({0} ml),
						'many' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
						'two' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} piñs),
						'many' => q({0} piñs),
						'name' => q(piñs),
						'one' => q({0} piñs),
						'other' => q({0} piñs),
						'two' => q({0} piñs),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} piñs),
						'many' => q({0} piñs),
						'name' => q(piñs),
						'one' => q({0} piñs),
						'other' => q({0} piñs),
						'two' => q({0} piñs),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(qt Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(qt Imp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} l.-v.),
						'many' => q({0} l.-v.),
						'name' => q(l.-v.),
						'one' => q({0} l.-v.),
						'other' => q({0} l.-v.),
						'two' => q({0} l.-v.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} l.-v.),
						'many' => q({0} l.-v.),
						'name' => q(l.-v.),
						'one' => q({0} l.-v.),
						'other' => q({0} l.-v.),
						'two' => q({0} l.-v.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} l.-g.),
						'many' => q({0} l.-g.),
						'name' => q(l.-g.),
						'one' => q({0} l.-g.),
						'other' => q({0} l.-g.),
						'two' => q({0} l.-g.),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} l.-g.),
						'many' => q({0} l.-g.),
						'name' => q(l.-g.),
						'one' => q({0} l.-g.),
						'other' => q({0} l.-g.),
						'two' => q({0} l.-g.),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ya|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ket|k|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} ha {1}),
				2 => q({0} ha {1}),
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
					'few' => '0 miliad',
					'many' => '0 a viliadoù',
					'one' => '0 miliad',
					'other' => '0 miliad',
					'two' => '0 viliad',
				},
				'10000' => {
					'few' => '00 miliad',
					'many' => '00 a viliadoù',
					'one' => '00 miliad',
					'other' => '00 miliad',
					'two' => '00 viliad',
				},
				'100000' => {
					'few' => '000 miliad',
					'many' => '000 a viliadoù',
					'one' => '000 miliad',
					'other' => '000 miliad',
					'two' => '000 viliad',
				},
				'1000000' => {
					'few' => '0 milion',
					'many' => '0 a v/milionoù',
					'one' => '0 milion',
					'other' => '0 milion',
					'two' => '0 v/milion',
				},
				'10000000' => {
					'few' => '00 milion',
					'many' => '00 a v/milionoù',
					'one' => '00 milion',
					'other' => '00 milion',
					'two' => '00 v/milion',
				},
				'100000000' => {
					'few' => '000 milion',
					'many' => '000 a v/milionoù',
					'one' => '000 milion',
					'other' => '000 milion',
					'two' => '000 v/milion',
				},
				'1000000000' => {
					'few' => '0 miliard',
					'many' => '0 a viliardoù',
					'one' => '0 miliard',
					'other' => '0 miliard',
					'two' => '0 viliard',
				},
				'10000000000' => {
					'few' => '00 miliard',
					'many' => '00 a viliardoù',
					'one' => '00 miliard',
					'other' => '00 miliard',
					'two' => '00 viliard',
				},
				'100000000000' => {
					'few' => '000 miliard',
					'many' => '000 a viliardoù',
					'one' => '000 miliard',
					'other' => '000 miliard',
					'two' => '000 viliard',
				},
				'1000000000000' => {
					'few' => '0 bilion',
					'many' => '0 a v/bilionoù',
					'one' => '0 bilion',
					'other' => '0 bilion',
					'two' => '0 v/bilion',
				},
				'10000000000000' => {
					'few' => '00 bilion',
					'many' => '00 a v/bilionoù',
					'one' => '00 bilion',
					'other' => '00 bilion',
					'two' => '00 v/bilion',
				},
				'100000000000000' => {
					'few' => '000 bilion',
					'many' => '000 a v/bilionoù',
					'one' => '000 bilion',
					'other' => '000 bilion',
					'two' => '000 v/bilion',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0k',
					'other' => '0k',
				},
				'10000' => {
					'one' => '00k',
					'other' => '00k',
				},
				'100000' => {
					'one' => '000k',
					'other' => '000k',
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
				'currency' => q(peseta Andorra),
				'few' => q(feseta Andorra),
				'many' => q(a besetaoù Andorra),
				'one' => q(beseta Andorra),
				'other' => q(peseta Andorra),
				'two' => q(beseta Andorra),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(dirham EAU),
				'few' => q(dirham EAU),
				'many' => q(a zirhamoù EAU),
				'one' => q(dirham EAU),
				'other' => q(dirham EAU),
				'two' => q(zirham EAU),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afghani Afghanistan \(1927–2002\)),
				'few' => q(afghani Afghanistan \(1927–2002\)),
				'many' => q(a afghanioù Afghanistan \(1927–2002\)),
				'one' => q(afghani Afghanistan \(1927–2002\)),
				'other' => q(afghani Afghanistan \(1927–2002\)),
				'two' => q(afghani Afghanistan \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afghani Afghanistan),
				'few' => q(afghani Afghanistan),
				'many' => q(a afghanioù Afghanistan),
				'one' => q(afghani Afghanistan),
				'other' => q(afghani Afghanistan),
				'two' => q(afghani Afghanistan),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(lek Albania \(1946–1965\)),
				'few' => q(lek Albania \(1946–1965\)),
				'many' => q(a lekoù Albania \(1946–1965\)),
				'one' => q(lek Albania \(1946–1965\)),
				'other' => q(lek Albania \(1946–1965\)),
				'two' => q(lek Albania \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(lek Albania),
				'few' => q(lek Albania),
				'many' => q(a lekoù Albania),
				'one' => q(lek Albania),
				'other' => q(lek Albania),
				'two' => q(lek Albania),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(dram Armenia),
				'few' => q(dram Armenia),
				'many' => q(a zramoù Armenia),
				'one' => q(dram Armenia),
				'other' => q(dram Armenia),
				'two' => q(zram Armenia),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(florin Antilhez nederlandat),
				'few' => q(florin Antilhez nederlandat),
				'many' => q(a florinoù Antilhez),
				'one' => q(florin Antilhez nederlandat),
				'other' => q(florin Antilhez nederlandat),
				'two' => q(florin Antilhez nederlandat),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(kwanza Angola),
				'few' => q(cʼhwanza Angola),
				'many' => q(a gwanzaoù Angola),
				'one' => q(cʼhwanza Angola),
				'other' => q(kwanza Angola),
				'two' => q(gwanza Angola),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(kwanza Angola \(1977–1991\)),
				'few' => q(cʼhwanza Angola \(1977–1991\)),
				'many' => q(a gwanzaoù Angola \(1977–1991\)),
				'one' => q(cʼhwanza Angola \(1977–1991\)),
				'other' => q(kwanza Angola \(1977–1991\)),
				'two' => q(gwanza Angola \(1977–1991\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(kwanza nevez Angola \(1990–2000\)),
				'few' => q(cʼhwanza nevez Angola \(1990–2000\)),
				'many' => q(a gwanzaoù nevez Angola \(1990–2000\)),
				'one' => q(cʼhwanza nevez Angola \(1990–2000\)),
				'other' => q(kwanza nevez Angola \(1990–2000\)),
				'two' => q(gwanza nevez Angola \(1990–2000\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(peso Arcʼhantina \(1881–1970\)),
				'few' => q(feso Arcʼhantina \(1881–1970\)),
				'many' => q(a besoioù Arcʼhantina \(1881–1970\)),
				'one' => q(peso Arcʼhantina \(1881–1970\)),
				'other' => q(peso Arcʼhantina \(1881–1970\)),
				'two' => q(beso Arcʼhantina \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(peso Arcʼhantina \(1983–1985\)),
				'few' => q(feso Arcʼhantina \(1983–1985\)),
				'many' => q(a besoioù Arcʼhantina \(1983–1985\)),
				'one' => q(peso Arcʼhantina \(1983–1985\)),
				'other' => q(peso Arcʼhantina \(1983–1985\)),
				'two' => q(beso Arcʼhantina \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(peso Arcʼhantina),
				'few' => q(feso Arcʼhantina),
				'many' => q(a pesoioù Arcʼhantina),
				'one' => q(peso Arcʼhantina),
				'other' => q(peso Arcʼhantina),
				'two' => q(beso Arcʼhantina),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(schilling Aostria),
				'few' => q(schilling Aostria),
				'many' => q(a schillingoù Aostria),
				'one' => q(schilling Aostria),
				'other' => q(schilling Aostria),
				'two' => q(schilling Aostria),
			},
		},
		'AUD' => {
			symbol => '$A',
			display_name => {
				'currency' => q(dollar Aostralia),
				'few' => q(dollar Aostralia),
				'many' => q(a zollaroù Aostralia),
				'one' => q(dollar Aostralia),
				'other' => q(dollar Aostralia),
				'two' => q(zollar Aostralia),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(florin Aruba),
				'few' => q(florin Aruba),
				'many' => q(a florinoù Aruba),
				'one' => q(florin Aruba),
				'other' => q(florin Aruba),
				'two' => q(florin Aruba),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(manat Azerbaidjan \(1993–2006\)),
				'few' => q(manat Azerbaidjan \(1993–2006\)),
				'many' => q(a vanatoù Azerbaidjan \(1993–2006\)),
				'one' => q(manat Azerbaidjan \(1993–2006\)),
				'other' => q(manat Azerbaidjan \(1993–2006\)),
				'two' => q(vanat Azerbaidjan \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(manat Azerbaidjan),
				'few' => q(manat Azerbaidjan),
				'many' => q(a vanatoù Azerbaidjan),
				'one' => q(manat Azerbaidjan),
				'other' => q(manat Azerbaidjan),
				'two' => q(vanat Azerbaidjan),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(dinar Bosnia ha Herzegovina \(1992–1994\)),
				'few' => q(dinar Bosnia ha Herzegovina \(1992–1994\)),
				'many' => q(a zinaroù Bosnia ha Herzegovina \(1992–1994\)),
				'one' => q(dinar Bosnia ha Herzegovina \(1992–1994\)),
				'other' => q(dinar Bosnia ha Herzegovina \(1992–1994\)),
				'two' => q(zinar Bosnia ha Herzegovina \(1992–1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(mark kemmadus Bosnia ha Herzegovina),
				'few' => q(mark kemmadus Bosnia ha Herzegovina),
				'many' => q(a varkoù kemmadus Bosnia ha Herzegovina),
				'one' => q(mark kemmadus Bosnia ha Herzegovina),
				'other' => q(mark kemmadus Bosnia ha Herzegovina),
				'two' => q(vark kemmadus Bosnia ha Herzegovina),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(dinar nevez Bosnia ha Herzegovina \(1994–1997\)),
				'few' => q(dinar nevez Bosnia ha Herzegovina \(1994–1997\)),
				'many' => q(a zinaroù nevez Bosnia ha Herzegovina \(1994–1997\)),
				'one' => q(dinar nevez Bosnia ha Herzegovina \(1994–1997\)),
				'other' => q(dinar nevez Bosnia ha Herzegovina \(1994–1997\)),
				'two' => q(zinar nevez Bosnia ha Herzegovina \(1994–1997\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(dollar Barbados),
				'few' => q(dollar Barbados),
				'many' => q(a zollaroù Barbados),
				'one' => q(dollar Barbados),
				'other' => q(dollar Barbados),
				'two' => q(zollar Barbados),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(taka Bangladesh),
				'few' => q(zaka Bangladesh),
				'many' => q(a dakaoù Bangladesh),
				'one' => q(taka Bangladesh),
				'other' => q(taka Bangladesh),
				'two' => q(daka Bangladesh),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(lur Belgia \(kemmadus\)),
				'few' => q(lur Belgia \(kemmadus\)),
				'many' => q(a lurioù Belgia \(kemmadus\)),
				'one' => q(lur Belgia \(kemmadus\)),
				'other' => q(lur Belgia \(kemmadus\)),
				'two' => q(lur Belgia \(kemmadus\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(lur Belgia),
				'few' => q(lur Belgia),
				'many' => q(a lurioù Belgia),
				'one' => q(lur Belgia),
				'other' => q(lur Belgia),
				'two' => q(lur Belgia),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(lev sokialour Bulgaria),
				'few' => q(lev sokialour Bulgaria),
				'many' => q(a levoù sokialour Bulgaria),
				'one' => q(lev sokialour Bulgaria),
				'other' => q(lev sokialour Bulgaria),
				'two' => q(lev sokialour Bulgaria),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(lev Bulgaria),
				'few' => q(lev Bulgaria),
				'many' => q(a levoù Bulgaria),
				'one' => q(lev Bulgaria),
				'other' => q(lev Bulgaria),
				'two' => q(lev Bulgaria),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(lev Bulgaria \(1879–1952\)),
				'few' => q(lev Bulgaria \(1879–1952\)),
				'many' => q(a levoù Bulgaria \(1879–1952\)),
				'one' => q(lev Bulgaria \(1879–1952\)),
				'other' => q(lev Bulgaria \(1879–1952\)),
				'two' => q(lev Bulgaria \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(dinar Bahrein),
				'few' => q(dinar Bahrein),
				'many' => q(a zinaroù Bahrein),
				'one' => q(dinar Bahrein),
				'other' => q(dinar Bahrein),
				'two' => q(zinar Bahrein),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(lur Burundi),
				'few' => q(lur Burundi),
				'many' => q(a lurioù Burundi),
				'one' => q(lur Burundi),
				'other' => q(lur Burundi),
				'two' => q(lur Burundi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(dollar Bermuda),
				'few' => q(dollar Bermuda),
				'many' => q(a zollaroù Bermuda),
				'one' => q(dollar Bermuda),
				'other' => q(dollar Bermuda),
				'two' => q(zollar Bermuda),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(dollar Brunei),
				'few' => q(dollar Brunei),
				'many' => q(a zollaroù Brunei),
				'one' => q(dollar Brunei),
				'other' => q(dollar Brunei),
				'two' => q(zollar Brunei),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(boliviano Bolivia),
				'few' => q(boliviano Bolivia),
				'many' => q(a volivianoioù Bolivia),
				'one' => q(boliviano Bolivia),
				'other' => q(boliviano Bolivia),
				'two' => q(voliviano Bolivia),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(boliviano Bolivia \(1863–1963\)),
				'few' => q(boliviano Bolivia \(1863–1963\)),
				'many' => q(a volivianoioù Bolivia \(1863–1963\)),
				'one' => q(boliviano Bolivia \(1863–1963\)),
				'other' => q(boliviano Bolivia \(1863–1963\)),
				'two' => q(voliviano Bolivia \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(peso Bolivia),
				'few' => q(feso Bolivia),
				'many' => q(a besoioù Bolivia),
				'one' => q(peso Bolivia),
				'other' => q(peso Bolivia),
				'two' => q(beso Bolivia),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(real Brazil),
				'few' => q(real Brazil),
				'many' => q(a realioù Brazil),
				'one' => q(real Brazil),
				'other' => q(real Brazil),
				'two' => q(real Brazil),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(dollar Bahamas),
				'few' => q(dollar Bahamas),
				'many' => q(a zollaroù Bahamas),
				'one' => q(dollar Bahamas),
				'other' => q(dollar Bahamas),
				'two' => q(zollar Bahamas),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(ngultrum Bhoutan),
				'few' => q(ngultrum Bhoutan),
				'many' => q(a ngultrumoù Bhoutan),
				'one' => q(ngultrum Bhoutan),
				'other' => q(ngultrum Bhoutan),
				'two' => q(ngultrum Bhoutan),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(kyat Birmania),
				'few' => q(cʼhyat Birmania),
				'many' => q(a gyatoù Birmania),
				'one' => q(cʼhyat Birmania),
				'other' => q(kyat Birmania),
				'two' => q(gyat Birmania),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(pula Botswana),
				'few' => q(fula Botswana),
				'many' => q(a bulaoù Botswana),
				'one' => q(pula Botswana),
				'other' => q(pula Botswana),
				'two' => q(bula Botswana),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(roubl nevez Belarus \(1994–1999\)),
				'few' => q(roubl nevez Belarus \(1994–1999\)),
				'many' => q(a roubloù nevez Belarus \(1994–1999\)),
				'one' => q(roubl nevez Belarus \(1994–1999\)),
				'other' => q(roubl nevez Belarus \(1994–1999\)),
				'two' => q(roubl nevez Belarus \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(roubl Belarus),
				'few' => q(roubl Belarus),
				'many' => q(a roubloù Belarus),
				'one' => q(roubl Belarus),
				'other' => q(roubl Belarus),
				'two' => q(roubl Belarus),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(roubl Belarus \(2000–2016\)),
				'few' => q(roubl Belarus \(2000–2016\)),
				'many' => q(a roubloù Belarus \(2000–2016\)),
				'one' => q(roubl Belarus \(2000–2016\)),
				'other' => q(roubl Belarus \(2000–2016\)),
				'two' => q(roubl Belarus \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(dollar Belize),
				'few' => q(dollar Belize),
				'many' => q(a zollaroù Belize),
				'one' => q(dollar Belize),
				'other' => q(dollar Belize),
				'two' => q(zollar Belize),
			},
		},
		'CAD' => {
			symbol => '$CA',
			display_name => {
				'currency' => q(dollar Kanada),
				'few' => q(dollar Kanada),
				'many' => q(a zollaroù Kanada),
				'one' => q(dollar Kanada),
				'other' => q(dollar Kanada),
				'two' => q(zollar Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(lur Kongo),
				'few' => q(lur Kongo),
				'many' => q(a lurioù Kongo),
				'one' => q(lur Kongo),
				'other' => q(lur Kongo),
				'two' => q(lur Kongo),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(euro WIR),
				'few' => q(euro WIR),
				'many' => q(a euroioù WIR),
				'one' => q(euro WIR),
				'other' => q(euro WIR),
				'two' => q(euro WIR),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(lur Suis),
				'few' => q(lur Suis),
				'many' => q(a lurioù Suis),
				'one' => q(lur Suis),
				'other' => q(lur Suis),
				'two' => q(lur Suis),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(lur WIR),
				'few' => q(lur WIR),
				'many' => q(a lurioù WIR),
				'one' => q(lur WIR),
				'other' => q(lur WIR),
				'two' => q(lur WIR),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(escudo Chile),
				'few' => q(escudo Chile),
				'many' => q(a escudoioù Chile),
				'one' => q(escudo Chile),
				'other' => q(escudo Chile),
				'two' => q(escudo Chile),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(unanenn jediñ Chile),
				'few' => q(unanenn jediñ Chile),
				'many' => q(a unanennoù jediñ Chile),
				'one' => q(unanenn jediñ Chile),
				'other' => q(unanenn jediñ Chile),
				'two' => q(unanenn jediñ Chile),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(peso Chile),
				'few' => q(feso Chile),
				'many' => q(a besoioù Chile),
				'one' => q(peso Chile),
				'other' => q(peso Chile),
				'two' => q(beso Chile),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(yuan Sina \(diavaez\)),
				'few' => q(yuan Sina \(diavaez\)),
				'many' => q(a yuanoù Sina \(diavaez\)),
				'one' => q(yuan Sina \(diavaez\)),
				'other' => q(yuan Sina \(diavaez\)),
				'two' => q(yuan Sina \(diavaez\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(dollar Bank poblel Sina),
				'few' => q(dollar Bank poblel Sina),
				'many' => q(a zollaroù Bank poblel Sina),
				'one' => q(dollar Bank poblel Sina),
				'other' => q(dollar Bank poblel Sina),
				'two' => q(zollar Bank poblel Sina),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(yuan Sina),
				'few' => q(yuan Sina),
				'many' => q(a yuanoù Sina),
				'one' => q(yuan Sina),
				'other' => q(yuan Sina),
				'two' => q(yuan Sina),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(peso Kolombia),
				'few' => q(feso Kolombia),
				'many' => q(a besoioù Kolombia),
				'one' => q(peso Kolombia),
				'other' => q(peso Kolombia),
				'two' => q(beso Kolombia),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(colón Costa Rica),
				'few' => q(cʼholón Costa Rica),
				'many' => q(a golónoù Costa Rica),
				'one' => q(cʼholón Costa Rica),
				'other' => q(colón Costa Rica),
				'two' => q(golón Costa Rica),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(dinar Serbia \(2002–2006\)),
				'few' => q(dinar Serbia \(2002–2006\)),
				'many' => q(a zinaroù Serbia \(2002–2006\)),
				'one' => q(dinar Serbia \(2002–2006\)),
				'other' => q(dinar Serbia \(2002–2006\)),
				'two' => q(zinar Serbia \(2002–2006\)),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(peso kemmadus Kuba),
				'few' => q(feso kemmadus Kuba),
				'many' => q(a besoioù kemmadus Kuba),
				'one' => q(peso kemmadus Kuba),
				'other' => q(peso kemmadus Kuba),
				'two' => q(beso gemmadus Kuba),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(peso Kuba),
				'few' => q(feso Kuba),
				'many' => q(a besoioù Kuba),
				'one' => q(peso Kuba),
				'other' => q(peso Kuba),
				'two' => q(beso Kuba),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(escudo Kab Glas),
				'few' => q(escudo Kab Glas),
				'many' => q(a escudoioù Kab Glas),
				'one' => q(escudo Kab Glas),
				'other' => q(escudo Kab Glas),
				'two' => q(escudo Kab Glas),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(lur Kiprenez),
				'few' => q(lur Kiprenez),
				'many' => q(a lurioù Kiprenez),
				'one' => q(lur Kiprenez),
				'other' => q(lur Kiprenez),
				'two' => q(lur Kiprenez),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(kurunenn Tchek),
				'few' => q(cʼhurunenn Tchek),
				'many' => q(a gurunennoù Tchek),
				'one' => q(gurunenn Tchek),
				'other' => q(kurunenn Tchek),
				'two' => q(gurunenn Tchek),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(mark Alamagn ar Reter),
				'few' => q(mark Alamagn ar Reter),
				'many' => q(a varkoù Alamagn ar Reter),
				'one' => q(mark Alamagn ar Reter),
				'other' => q(mark Alamagn ar Reter),
				'two' => q(mark Alamagn ar Reter),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(mark Alamagn),
				'few' => q(mark Alamagn),
				'many' => q(a varkoù Alamagn),
				'one' => q(mark Alamagn),
				'other' => q(mark Alamagn),
				'two' => q(vark Alamagn),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(lur Djibouti),
				'few' => q(lur Djibouti),
				'many' => q(a lurioù Djibouti),
				'one' => q(lur Djibouti),
				'other' => q(lur Djibouti),
				'two' => q(lur Djibouti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(kurunenn Danmark),
				'few' => q(cʼhurunenn Danmark),
				'many' => q(a gurunennoù Danmark),
				'one' => q(gurunenn Danmark),
				'other' => q(kurunenn Danmark),
				'two' => q(gurunenn Danmark),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(peso Dominikan),
				'few' => q(feso Dominikan),
				'many' => q(a besoioù Dominikan),
				'one' => q(peso Dominikan),
				'other' => q(peso Dominikan),
				'two' => q(beso Dominikan),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(dinar Aljeria),
				'few' => q(dinar Aljeria),
				'many' => q(a zinaroù Aljeria),
				'one' => q(dinar Aljeria),
				'other' => q(dinar Aljeria),
				'two' => q(zinar Aljeria),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(kurunenn Estonia),
				'few' => q(cʼhurunenn Estonia),
				'many' => q(a gurunennoù Estonia),
				'one' => q(gurunenn Estonia),
				'other' => q(kurunenn Estonia),
				'two' => q(gurunenn Estonia),
			},
		},
		'EGP' => {
			symbol => '£ E',
			display_name => {
				'currency' => q(lur Egipt),
				'few' => q(lur Egipt),
				'many' => q(a lurioù Egipt),
				'one' => q(lur Egipt),
				'other' => q(lur Egipt),
				'two' => q(lur Egipt),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(nakfa Eritrea),
				'few' => q(nakfa Eritrea),
				'many' => q(a nakfaoù Eritrea),
				'one' => q(nakfa Eritrea),
				'other' => q(nakfa Eritrea),
				'two' => q(nakfa Eritrea),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(peseta gemmadus Spagn),
				'few' => q(feseta gemmadus Spagn),
				'many' => q(a besetaoù kemmadus Spagn),
				'one' => q(beseta gemmadus Spagn),
				'other' => q(peseta gemmadus Spagn),
				'two' => q(beseta gemmadus Spagn),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(peseta Spagn),
				'few' => q(feseta Spagn),
				'many' => q(a besetaoù Spagn),
				'one' => q(beseta Spagn),
				'other' => q(peseta Spagn),
				'two' => q(beseta Spagn),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(birr Etiopia),
				'few' => q(birr Etiopia),
				'many' => q(a virroù Etiopia),
				'one' => q(birr Etiopia),
				'other' => q(birr Etiopia),
				'two' => q(virr Etiopia),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
				'few' => q(euro),
				'many' => q(a euroioù),
				'one' => q(euro),
				'other' => q(euro),
				'two' => q(euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(mark Finland),
				'few' => q(mark Finland),
				'many' => q(a varkoù Finland),
				'one' => q(mark Finland),
				'other' => q(mark Finland),
				'two' => q(vark Finland),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(dollar Fidji),
				'few' => q(dollar Fidji),
				'many' => q(a zollaroù Fidji),
				'one' => q(dollar Fidji),
				'other' => q(dollar Fidji),
				'two' => q(zollar Fidji),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(lur Inizi Falkland),
				'few' => q(lur Inizi Falkland),
				'many' => q(a lurioù Inizi Falkland),
				'one' => q(lur Inizi Falkland),
				'other' => q(lur Inizi Falkland),
				'two' => q(lur Inizi Falkland),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(lur gall),
				'few' => q(lur gall),
				'many' => q(a lurioù gall),
				'one' => q(lur gall),
				'other' => q(lur gall),
				'two' => q(lur gall),
			},
		},
		'GBP' => {
			symbol => '£ RU',
			display_name => {
				'currency' => q(lur Breizh-Veur),
				'few' => q(lur Breizh-Veur),
				'many' => q(a lurioù Breizh-Veur),
				'one' => q(lur Breizh-Veur),
				'other' => q(lur Breizh-Veur),
				'two' => q(lur Breizh-Veur),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(lari Jorjia),
				'few' => q(lari Jorjia),
				'many' => q(a larioù Jorjia),
				'one' => q(lari Jorjia),
				'other' => q(lari Jorjia),
				'two' => q(lari Jorjia),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(cedi Ghana),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(lur Jibraltar),
				'few' => q(lur Jibraltar),
				'many' => q(a lurioù Jibraltar),
				'one' => q(lur Jibraltar),
				'other' => q(lur Jibraltar),
				'two' => q(lur Jibraltar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(dalasi Gambia),
				'few' => q(dalasi Gambia),
				'many' => q(a zalasioù Gambia),
				'one' => q(dalasi Gambia),
				'other' => q(dalasi Gambia),
				'two' => q(zalasi Gambia),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(lur Ginea),
				'few' => q(lur Ginea),
				'many' => q(a lurioù Ginea),
				'one' => q(lur Ginea),
				'other' => q(lur Ginea),
				'two' => q(lur Ginea),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(syli Ginea),
				'few' => q(syli Ginea),
				'many' => q(a sylioù Ginea),
				'one' => q(syli Ginea),
				'other' => q(syli Ginea),
				'two' => q(syli Ginea),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(ekwele Ginea ar Cʼheheder),
				'few' => q(ekwele Ginea ar Cʼheheder),
				'many' => q(a ekweleoù Ginea ar Cʼheheder),
				'one' => q(ekwele Ginea ar Cʼheheder),
				'other' => q(ekwele Ginea ar Cʼheheder),
				'two' => q(ekwele Ginea ar Cʼheheder),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(drakm Gres),
				'few' => q(drakm Gres),
				'many' => q(a zrakmoù Gres),
				'one' => q(drakm Gres),
				'other' => q(drakm Gres),
				'two' => q(zrakm Gres),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(quetzal Guatemala),
				'few' => q(cʼhuetzal Guatemala),
				'many' => q(a guetzaloù Guatemala),
				'one' => q(cʼhuetzal Guatemala),
				'other' => q(quetzal Guatemala),
				'two' => q(guetzal Guatemala),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(peso Ginea-Bissau),
				'few' => q(feso Ginea-Bissau),
				'many' => q(a besoioù Ginea-Bissau),
				'one' => q(peso Ginea-Bissau),
				'other' => q(peso Ginea-Bissau),
				'two' => q(beso Ginea-Bissau),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(dollar Guyana),
				'few' => q(dollar Guyana),
				'many' => q(a zollaroù Guyana),
				'one' => q(dollar Guyana),
				'other' => q(dollar Guyana),
				'two' => q(zollar Guyana),
			},
		},
		'HKD' => {
			symbol => '$ HK',
			display_name => {
				'currency' => q(dollar Hong Kong),
				'few' => q(dollar Hong Kong),
				'many' => q(a zollaroù Hong Kong),
				'one' => q(dollar Hong Kong),
				'other' => q(dollar Hong Kong),
				'two' => q(zollar Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(lempira Honduras),
				'few' => q(lempira Honduras),
				'many' => q(a lempiraoù Honduras),
				'one' => q(lempira Honduras),
				'other' => q(lempira Honduras),
				'two' => q(lempira Honduras),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(dinar Kroatia),
				'few' => q(dinar Kroatia),
				'many' => q(a zinaroù Kroatia),
				'one' => q(dinar Kroatia),
				'other' => q(dinar Kroatia),
				'two' => q(zinar Kroatia),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(kuna Kroatia),
				'few' => q(cʼhuna Kroatia),
				'many' => q(a gunaoù Kroatia),
				'one' => q(cʼhuna Kroatia),
				'other' => q(kuna Kroatia),
				'two' => q(guna Kroatia),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(gourde Haiti),
				'few' => q(gourde Haiti),
				'many' => q(a cʼhourdeoù Haiti),
				'one' => q(gourde Haiti),
				'other' => q(gourde Haiti),
				'two' => q(cʼhourde Haiti),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(forint Hungaria),
				'few' => q(forint Hungaria),
				'many' => q(a forintoù Hungaria),
				'one' => q(forint Hungaria),
				'other' => q(forint Hungaria),
				'two' => q(forint Hungaria),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(roupi Indonezia),
				'few' => q(roupi Indonezia),
				'many' => q(a roupioù Indonezia),
				'one' => q(roupi Indonezia),
				'other' => q(roupi Indonezia),
				'two' => q(roupi Indonezia),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(lur Iwerzhon),
				'few' => q(lur Iwerzhon),
				'many' => q(a lurioù Iwerzhon),
				'one' => q(lur Iwerzhon),
				'other' => q(lur Iwerzhon),
				'two' => q(lur Iwerzhon),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(lur Israel),
				'few' => q(lur Israel),
				'many' => q(a lurioù Israel),
				'one' => q(lur Israel),
				'other' => q(lur Israel),
				'two' => q(lur Israel),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(shekel Israel \(1980–1985\)),
			},
		},
		'ILS' => {
			symbol => 'ILS',
			display_name => {
				'currency' => q(shekel nevez Israel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(roupi India),
				'few' => q(roupi India),
				'many' => q(a roupioù India),
				'one' => q(roupi India),
				'other' => q(roupi India),
				'two' => q(roupi India),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(dinar Iraq),
				'few' => q(dinar Iraq),
				'many' => q(a zinaroù Iraq),
				'one' => q(dinar Iraq),
				'other' => q(dinar Iraq),
				'two' => q(zinar Iraq),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(rial Iran),
				'few' => q(rial Iran),
				'many' => q(a rialoù Iran),
				'one' => q(rial Iran),
				'other' => q(rial Iran),
				'two' => q(rial Iran),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(kurunenn Island \(1918–1981\)),
				'few' => q(cʼhurunenn Island \(1918–1981\)),
				'many' => q(a gurunennoù Island \(1918–1981\)),
				'one' => q(gurunenn Island \(1918–1981\)),
				'other' => q(kurunenn Island \(1918–1981\)),
				'two' => q(gurunenn Island \(1918–1981\)),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(kurunenn Island),
				'few' => q(cʼhurunenn Island),
				'many' => q(a gurunennoù Island),
				'one' => q(gurunenn Island),
				'other' => q(kurunenn Island),
				'two' => q(gurunenn Island),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(lur Italia),
				'few' => q(lur Italia),
				'many' => q(a lurioù Italia),
				'one' => q(lur Italia),
				'other' => q(lur Italia),
				'two' => q(lur Italia),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(dollar Jamaika),
				'few' => q(dollar Jamaika),
				'many' => q(a zollaroù Jamaika),
				'one' => q(dollar Jamaika),
				'other' => q(dollar Jamaika),
				'two' => q(zollar Jamaika),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(dinar Jordania),
				'few' => q(dinar Jordania),
				'many' => q(a zinaroù Jordania),
				'one' => q(dinar Jordania),
				'other' => q(dinar Jordania),
				'two' => q(zinar Jordania),
			},
		},
		'JPY' => {
			symbol => 'JPY',
			display_name => {
				'currency' => q(yen Japan),
				'few' => q(yen Japan),
				'many' => q(a yenoù Japan),
				'one' => q(yen Japan),
				'other' => q(yen Japan),
				'two' => q(yen Japan),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(shilling Kenya),
				'few' => q(shilling Kenya),
				'many' => q(a shillingoù Kenya),
				'one' => q(shilling Kenya),
				'other' => q(shilling Kenya),
				'two' => q(shilling Kenya),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(som Kyrgyzstan),
				'few' => q(som Kyrgyzstan),
				'many' => q(a somoù Kyrgyzstan),
				'one' => q(som Kyrgyzstan),
				'other' => q(som Kyrgyzstan),
				'two' => q(som Kyrgyzstan),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(riel Kambodja),
				'few' => q(riel Kambodja),
				'many' => q(a rieloù Kambodja),
				'one' => q(riel Kambodja),
				'other' => q(riel Kambodja),
				'two' => q(riel Kambodja),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(lur Komorez),
				'few' => q(lur Komorez),
				'many' => q(a lurioù Komorez),
				'one' => q(lur Komorez),
				'other' => q(lur Komorez),
				'two' => q(lur Komorez),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(won Korea an Norzh),
				'few' => q(won Korea an Norzh),
				'many' => q(a wonoù Korea an Norzh),
				'one' => q(won Korea an Norzh),
				'other' => q(won Korea an Norzh),
				'two' => q(won Korea an Norzh),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(hwan Korea ar Su \(1953–1962\)),
				'few' => q(hwan Korea ar Su \(1953–1962\)),
				'many' => q(a hwanoù Korea ar Su \(1953–1962\)),
				'one' => q(hwan Korea ar Su \(1953–1962\)),
				'other' => q(hwan Korea ar Su \(1953–1962\)),
				'two' => q(hwan Korea ar Su \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(won Korea ar Su \(1945–1953\)),
				'few' => q(won Korea ar Su \(1945–1953\)),
				'many' => q(a wonoù Korea ar Su \(1945–1953\)),
				'one' => q(won Korea ar Su \(1945–1953\)),
				'other' => q(won Korea ar Su \(1945–1953\)),
				'two' => q(won Korea ar Su \(1945–1953\)),
			},
		},
		'KRW' => {
			symbol => 'KRW',
			display_name => {
				'currency' => q(won Korea ar Su),
				'few' => q(won Korea ar Su),
				'many' => q(a wonoù Korea ar Su),
				'one' => q(won Korea ar Su),
				'other' => q(won Korea ar Su),
				'two' => q(won Korea ar Su),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(dinar Koweit),
				'few' => q(dinar Koweit),
				'many' => q(a zinaroù Koweit),
				'one' => q(dinar Koweit),
				'other' => q(dinar Koweit),
				'two' => q(zinar Koweit),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(dollar Inizi Cayman),
				'few' => q(dollar Inizi Cayman),
				'many' => q(a zollaroù Inizi Cayman),
				'one' => q(dollar Inizi Cayman),
				'other' => q(dollar Inizi Cayman),
				'two' => q(zollar Inizi Cayman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(tenge Kazakstan),
				'few' => q(zenge Kazakstan),
				'many' => q(a dengeoù Kazakstan),
				'one' => q(tenge Kazakstan),
				'other' => q(tenge Kazakstan),
				'two' => q(denge Kazakstan),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(kip Laos),
				'few' => q(cʼhip Laos),
				'many' => q(a gipoù Laos),
				'one' => q(cʼhip Laos),
				'other' => q(kip Laos),
				'two' => q(gip Laos),
			},
		},
		'LBP' => {
			symbol => '£L',
			display_name => {
				'currency' => q(lur Liban),
				'few' => q(lur Liban),
				'many' => q(a lurioù Liban),
				'one' => q(lur Liban),
				'other' => q(lur Liban),
				'two' => q(lur Liban),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(roupi Sri Lanka),
				'few' => q(roupi Sri Lanka),
				'many' => q(a roupioù Sri Lanka),
				'one' => q(roupi Sri Lanka),
				'other' => q(roupi Sri Lanka),
				'two' => q(roupi Sri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(dollar Liberia),
				'few' => q(dollar Liberia),
				'many' => q(a zollaroù Liberia),
				'one' => q(dollar Liberia),
				'other' => q(dollar Liberia),
				'two' => q(zollar Liberia),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(loti Lesotho),
				'few' => q(loti Lesotho),
				'many' => q(a lotioù Lesotho),
				'one' => q(loti Lesotho),
				'other' => q(loti Lesotho),
				'two' => q(loti Lesotho),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(litas Lituania),
				'few' => q(litas Lituania),
				'many' => q(a litasoù Lituania),
				'one' => q(litas Lituania),
				'other' => q(litas Lituania),
				'two' => q(litas Lituania),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(talonas Lituania),
				'few' => q(zalonas Lituania),
				'many' => q(a dalonasoù Lituania),
				'one' => q(talonas Lituania),
				'other' => q(talonas Lituania),
				'two' => q(dalonas Lituania),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(lur kemmadus Luksembourg),
				'few' => q(lur kemmadus Luksembourg),
				'many' => q(a lurioù kemmadus Luksembourg),
				'one' => q(lur kemmadus Luksembourg),
				'other' => q(lur kemmadus Luksembourg),
				'two' => q(lur kemmadus Luksembourg),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(lur Luksembourg),
				'few' => q(lur Luksembourg),
				'many' => q(a lurioù Luksembourg),
				'one' => q(lur Luksembourg),
				'other' => q(lur Luksembourg),
				'two' => q(lur Luksembourg),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(lats Latvia),
				'few' => q(lats Latvia),
				'many' => q(a latsoù Latvia),
				'one' => q(lats Latvia),
				'other' => q(lats Latvia),
				'two' => q(lats Latvia),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(roubl Latvia),
				'few' => q(roubl Latvia),
				'many' => q(a roubloù Latvia),
				'one' => q(roubl Latvia),
				'other' => q(roubl Latvia),
				'two' => q(roubl Latvia),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(dinar Libia),
				'few' => q(dinar Libia),
				'many' => q(a zinaroù Libia),
				'one' => q(dinar Libia),
				'other' => q(dinar Libia),
				'two' => q(zinar Libia),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(dirham Maroko),
				'few' => q(dirham Maroko),
				'many' => q(a zirhamoù Maroko),
				'one' => q(dirham Maroko),
				'other' => q(dirham Maroko),
				'two' => q(zirham Maroko),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(lur Maroko),
				'few' => q(lur Maroko),
				'many' => q(a lurioù Maroko),
				'one' => q(lur Maroko),
				'other' => q(lur Maroko),
				'two' => q(lur Maroko),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(lur Monaco),
				'few' => q(lur Monaco),
				'many' => q(a lurioù Monaco),
				'one' => q(lur Monaco),
				'other' => q(lur Monaco),
				'two' => q(lur Monaco),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(leu Moldova),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(ariary Madagaskar),
				'few' => q(ariary Madagaskar),
				'many' => q(a ariaryoù Madagaska),
				'one' => q(ariary Madagaskar),
				'other' => q(ariary Madagaskar),
				'two' => q(ariary Madagaskar),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(lur Madagaskar),
				'few' => q(lur Madagaskar),
				'many' => q(a lurioù Madagaskar),
				'one' => q(lur Madagaskar),
				'other' => q(lur Madagaskar),
				'two' => q(lur Madagaskar),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(denar Makedonia),
				'few' => q(denar Makedonia),
				'many' => q(a zenaroù Makedonia),
				'one' => q(denar Makedonia),
				'other' => q(denar Makedonia),
				'two' => q(zenar Makedonia),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(denar Makedonia \(1992–1993\)),
				'few' => q(denar Makedonia \(1992–1993\)),
				'many' => q(a zenaroù Makedonia \(1992–1993\)),
				'one' => q(denar Makedonia \(1992–1993\)),
				'other' => q(denar Makedonia \(1992–1993\)),
				'two' => q(zenar Makedonia \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(lur Mali),
				'few' => q(lur Mali),
				'many' => q(a lurioù Mali),
				'one' => q(lur Mali),
				'other' => q(lur Mali),
				'two' => q(lur Mali),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(kyat Myanmar),
				'few' => q(cʼhyat Myanmar),
				'many' => q(a gyatoù Myanmar),
				'one' => q(cʼhyat Myanmar),
				'other' => q(kyat Myanmar),
				'two' => q(gyat Myanmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(tugrik Mongolia),
				'few' => q(zugrik Mongolia),
				'many' => q(a dugrikoù Mongolia),
				'one' => q(tugrik Mongolia),
				'other' => q(tugrik Mongolia),
				'two' => q(dugrik Mongolia),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(pataca Macau),
				'few' => q(fataca Macau),
				'many' => q(a batacaoù Macau),
				'one' => q(pataca Macau),
				'other' => q(pataca Macau),
				'two' => q(bataca Macau),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(ouguiya Maouritania \(1973–2017\)),
				'few' => q(ouguiya Maouritania \(1973–2017\)),
				'many' => q(a ouguiyaoù Maouritania \(1973–2017\)),
				'one' => q(ouguiya Maouritania \(1973–2017\)),
				'other' => q(ouguiya Maouritania \(1973–2017\)),
				'two' => q(ouguiya Maouritania \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(ouguiya Maouritania),
				'few' => q(ouguiya Maouritania),
				'many' => q(a ouguiyaoù Maouritania),
				'one' => q(ouguiya Maouritania),
				'other' => q(ouguiya Maouritania),
				'two' => q(ouguiya Maouritania),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(lira Malta),
				'few' => q(lira Malta),
				'many' => q(a liraoù Malta),
				'one' => q(lira Malta),
				'other' => q(lira Malta),
				'two' => q(lira Malta),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(lur Malta),
				'few' => q(lur Malta),
				'many' => q(a lurioù Malta),
				'one' => q(lur Malta),
				'other' => q(lur Malta),
				'two' => q(lur Malta),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(roupi Moris),
				'few' => q(roupi Moris),
				'many' => q(a roupioù Moris),
				'one' => q(roupi Moris),
				'other' => q(roupi Moris),
				'two' => q(roupi Moris),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(roupi Maldivez),
				'few' => q(roupi Maldivez),
				'many' => q(a roupioù Maldivez),
				'one' => q(roupi Maldivez),
				'other' => q(roupi Maldivez),
				'two' => q(roupi Maldivez),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(rufiyaa Maldivez),
				'few' => q(rufiyaa Maldivez),
				'many' => q(a rufiyaaoù Maldivez),
				'one' => q(rufiyaa Maldivez),
				'other' => q(rufiyaa Maldivez),
				'two' => q(rufiyaa Maldivez),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwacha Malawi),
				'few' => q(kwacha Malawi),
				'many' => q(a gwachaoù Malawi),
				'one' => q(cʼhwacha Malawi),
				'other' => q(kwacha Malawi),
				'two' => q(gwacha Malawi),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(peso Mecʼhiko),
				'few' => q(feso Mecʼhiko),
				'many' => q(a besoioù Mecʼhiko),
				'one' => q(peso Mecʼhiko),
				'other' => q(peso Mecʼhiko),
				'two' => q(beso Mecʼhiko),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(peso arcʼhant Mecʼhiko \(1861–1992\)),
				'few' => q(feso arcʼhant Mecʼhiko \(1861–1992\)),
				'many' => q(a besoioù arcʼhant Mecʼhiko \(1861–1992\)),
				'one' => q(peso arcʼhant Mecʼhiko \(1861–1992\)),
				'other' => q(peso arcʼhant Mecʼhiko \(1861–1992\)),
				'two' => q(beso arcʼhant Mecʼhiko \(1861–1992\)),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(ringgit Malaysia),
				'few' => q(ringgit Malaysia),
				'many' => q(a ringgitoù Malaysia),
				'one' => q(ringgit Malaysia),
				'other' => q(ringgit Malaysia),
				'two' => q(ringgit Malaysia),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(escudo Mozambik),
				'few' => q(escudo Mozambik),
				'many' => q(a escudoioù Mozambik),
				'one' => q(escudo Mozambik),
				'other' => q(escudo Mozambik),
				'two' => q(escudo Mozambik),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(metical Mozambik \(1980–2006\)),
				'few' => q(metical Mozambik \(1980–2006\)),
				'many' => q(a veticaloù Mozambik \(1980–2006\)),
				'one' => q(metical Mozambik \(1980–2006\)),
				'other' => q(metical Mozambik \(1980–2006\)),
				'two' => q(vetical Mozambik \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(metical Mozambik),
				'few' => q(metical Mozambik),
				'many' => q(a veticaloù Mozambik),
				'one' => q(metical Mozambik),
				'other' => q(metical Mozambik),
				'two' => q(vetical Mozambik),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(dollar Namibia),
				'few' => q(dollar Namibia),
				'many' => q(a zollaroù Namibia),
				'one' => q(dollar Namibia),
				'other' => q(dollar Namibia),
				'two' => q(zollar Namibia),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(naira Nigeria),
				'few' => q(naira Nigeria),
				'many' => q(a nairaoù Nigeria),
				'one' => q(naira Nigeria),
				'other' => q(naira Nigeria),
				'two' => q(naira Nigeria),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(cordoba Nicaragua \(1988–1991\)),
				'few' => q(cʼhordoba Nicaragua \(1988–1991\)),
				'many' => q(a gordobaoù Nicaragua \(1988–1991\)),
				'one' => q(cʼhordoba Nicaragua \(1988–1991\)),
				'other' => q(cordoba Nicaragua \(1988–1991\)),
				'two' => q(gordoba Nicaragua \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(cordoba Nicaragua),
				'few' => q(cʼhordoba Nicaragua),
				'many' => q(a gordobaoù Nicaragua),
				'one' => q(cʼhordoba Nicaragua),
				'other' => q(cordoba Nicaragua),
				'two' => q(gordoba Nicaragua),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(florin an Izelvroioù),
				'few' => q(florin an Izelvroioù),
				'many' => q(a florinoù an Izelvroioù),
				'one' => q(florin an Izelvroioù),
				'other' => q(florin an Izelvroioù),
				'two' => q(florin an Izelvroioù),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(kurunenn Norvegia),
				'few' => q(cʼhurunenn Norvegia),
				'many' => q(a gurunennoù Norvegia),
				'one' => q(gurunenn Norvegia),
				'other' => q(kurunenn Norvegia),
				'two' => q(gurunenn Norvegia),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(roupi Nepal),
				'few' => q(roupi Nepal),
				'many' => q(a roupioù Nepal),
				'one' => q(roupi Nepal),
				'other' => q(roupi Nepal),
				'two' => q(roupi Nepal),
			},
		},
		'NZD' => {
			symbol => '$ ZN',
			display_name => {
				'currency' => q(dollar Zeland-Nevez),
				'few' => q(dollar Zeland-Nevez),
				'many' => q(a zollaroù Zeland-Nevez),
				'one' => q(dollar Zeland-Nevez),
				'other' => q(dollar Zeland-Nevez),
				'two' => q(zollar Zeland-Nevez),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(rial Oman),
				'few' => q(rial Oman),
				'many' => q(a rialoù Oman),
				'one' => q(rial Oman),
				'other' => q(rial Oman),
				'two' => q(rial Oman),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(balboa Panamá),
				'few' => q(balboa Panamá),
				'many' => q(a valboaoù Panamá),
				'one' => q(balboa Panamá),
				'other' => q(balboa Panamá),
				'two' => q(valboa Panamá),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(sol Perou),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(sol Perou \(1863–1965\)),
				'few' => q(sol Perou \(1863–1965\)),
				'many' => q(a solioù Perou \(1863–1965\)),
				'one' => q(sol Perou \(1863–1965\)),
				'other' => q(sol Perou \(1863–1965\)),
				'two' => q(sol Perou \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(kina Papoua Ginea-Nevez),
				'few' => q(cʼhina Papoua Ginea-Nevez),
				'many' => q(a ginaoù Papoua Ginea-Nevez),
				'one' => q(cʼhina Papoua Ginea-Nevez),
				'other' => q(kina Papoua Ginea-Nevez),
				'two' => q(gina Papoua Ginea-Nevez),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(peso Filipinez),
				'few' => q(feso Filipinez),
				'many' => q(a besoioù Filipinez),
				'one' => q(peso Filipinez),
				'other' => q(peso Filipinez),
				'two' => q(beso Filipinez),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(roupi Pakistan),
				'few' => q(roupi Pakistan),
				'many' => q(a roupioù Pakistan),
				'one' => q(roupi Pakistan),
				'other' => q(roupi Pakistan),
				'two' => q(roupi Pakistan),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(zloty Polonia),
				'few' => q(zloty Polonia),
				'many' => q(a zlotyoù Polonia),
				'one' => q(zloty Polonia),
				'other' => q(zloty Polonia),
				'two' => q(zloty Polonia),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(zloty Polonia \(1950–1995\)),
				'few' => q(zloty Polonia \(1950–1995\)),
				'many' => q(a zlotyoù Polonia \(1950–1995\)),
				'one' => q(zloty Polonia \(1950–1995\)),
				'other' => q(zloty Polonia \(1950–1995\)),
				'two' => q(zloty Polonia \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(escudo Portugal),
				'few' => q(escudo Portugal),
				'many' => q(a escudoioù Portugal),
				'one' => q(escudo Portugal),
				'other' => q(escudo Portugal),
				'two' => q(escudo Portugal),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(guarani Paraguay),
				'few' => q(guarani Paraguay),
				'many' => q(a uaranioù Paraguay),
				'one' => q(guarani Paraguay),
				'other' => q(guarani Paraguay),
				'two' => q(uarani Paraguay),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(rial Qatar),
				'few' => q(rial Qatar),
				'many' => q(a rialoù Qatar),
				'one' => q(rial Qatar),
				'other' => q(rial Qatar),
				'two' => q(rial Qatar),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(dollar Rodezia),
				'few' => q(dollar Rodezia),
				'many' => q(a zollaroù Rodezia),
				'one' => q(dollar Rodezia),
				'other' => q(dollar Rodezia),
				'two' => q(zollar Rodezia),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(leu Roumania \(1952–2006\)),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(leu Roumania),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(dinar Serbia),
				'few' => q(dinar Serbia),
				'many' => q(a zinaroù Serbia),
				'one' => q(dinar Serbia),
				'other' => q(dinar Serbia),
				'two' => q(zinar Serbia),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(roubl Rusia),
				'few' => q(roubl Rusia),
				'many' => q(a roubloù Rusia),
				'one' => q(roubl Rusia),
				'other' => q(roubl Rusia),
				'two' => q(roubl Rusia),
			},
		},
		'RUR' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(roubl Rusia \(1991–1998\)),
				'few' => q(roubl Rusia \(1991–1998\)),
				'many' => q(a roubloù Rusia \(1991–1998\)),
				'one' => q(roubl Rusia \(1991–1998\)),
				'other' => q(roubl Rusia \(1991–1998\)),
				'two' => q(roubl Rusia \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(lur Rwanda),
				'few' => q(lur Rwanda),
				'many' => q(a lurioù Rwanda),
				'one' => q(lur Rwanda),
				'other' => q(lur Rwanda),
				'two' => q(lur Rwanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(riyal Arabia Saoudat),
				'few' => q(riyal Arabia Saoudat),
				'many' => q(a riyaloù Arabia Saoudat),
				'one' => q(riyal Arabia Saoudat),
				'other' => q(riyal Arabia Saoudat),
				'two' => q(riyal Arabia Saoudat),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(dollar Inizi Salomon),
				'few' => q(dollar Inizi Salomon),
				'many' => q(a zollaroù Inizi Salomon),
				'one' => q(dollar Inizi Salomon),
				'other' => q(dollar Inizi Salomon),
				'two' => q(zollar Inizi Salomon),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(roupi Sechelez),
				'few' => q(roupi Sechelez),
				'many' => q(a roupioù Sechelez),
				'one' => q(roupi Sechelez),
				'other' => q(roupi Sechelez),
				'two' => q(roupi Sechelez),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(dinar Soudan \(1992–2007\)),
				'few' => q(dinar Soudan \(1992–2007\)),
				'many' => q(a zinaroù Soudan \(1992–2007\)),
				'one' => q(dinar Soudan \(1992–2007\)),
				'other' => q(dinar Soudan \(1992–2007\)),
				'two' => q(zinar Soudan \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(lur Soudan),
				'few' => q(lur Soudan),
				'many' => q(a lurioù Soudan),
				'one' => q(lur Soudan),
				'other' => q(lur Soudan),
				'two' => q(lur Soudan),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(lur Soudan \(1957–1998\)),
				'few' => q(lur Soudan \(1957–1998\)),
				'many' => q(a lurioù Soudan \(1957–1998\)),
				'one' => q(lur Soudan \(1957–1998\)),
				'other' => q(lur Soudan \(1957–1998\)),
				'two' => q(lur Soudan \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(kurunenn Sveden),
				'few' => q(cʼhurunenn Sveden),
				'many' => q(a gurunennoù Sveden),
				'one' => q(gurunenn Sveden),
				'other' => q(kurunenn Sveden),
				'two' => q(gurunenn Sveden),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(dollar Singapour),
				'few' => q(dollar Singapour),
				'many' => q(a zollaroù Singapour),
				'one' => q(dollar Singapour),
				'other' => q(dollar Singapour),
				'two' => q(zollar Singapour),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(lur Saint-Helena),
				'few' => q(lur Saint-Helena),
				'many' => q(a lurioù Saint-Helena),
				'one' => q(lur Saint-Helena),
				'other' => q(lur Saint-Helena),
				'two' => q(lur Saint-Helena),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(tolar Slovenia),
				'few' => q(zolar Slovenia),
				'many' => q(a dolaroù Slovenia),
				'one' => q(tolar Slovenia),
				'other' => q(tolar Slovenia),
				'two' => q(dolar Slovenia),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(kurunenn Slovakia),
				'few' => q(cʼhurunenn Slovakia),
				'many' => q(a gurunennoù Slovakia),
				'one' => q(gurunenn Slovakia),
				'other' => q(kurunenn Slovakia),
				'two' => q(gurunenn Slovakia),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(leone Sierra Leone),
				'few' => q(leone Sierra Leone),
				'many' => q(a leoneoù Sierra Leone),
				'one' => q(leone Sierra Leone),
				'other' => q(leone Sierra Leone),
				'two' => q(leone Sierra Leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(leone Sierra Leone \(1964—2022\)),
				'few' => q(leone Sierra Leone \(1964—2022\)),
				'many' => q(a leoneoù Sierra Leone \(1964—2022\)),
				'one' => q(leone Sierra Leone \(1964—2022\)),
				'other' => q(leone Sierra Leone \(1964—2022\)),
				'two' => q(leone Sierra Leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(shilling Somalia),
				'few' => q(shilling Somalia),
				'many' => q(a shillingoù Somalia),
				'one' => q(shilling Somalia),
				'other' => q(shilling Somalia),
				'two' => q(shilling Somalia),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(dollar Surinam),
				'few' => q(dollar Surinam),
				'many' => q(a zollaroù Surinam),
				'one' => q(dollar Surinam),
				'other' => q(dollar Surinam),
				'two' => q(zollar Surinam),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(florin Surinam),
				'few' => q(florin Surinam),
				'many' => q(a florinoù Surinam),
				'one' => q(florin Surinam),
				'other' => q(florin Surinam),
				'two' => q(florin Surinam),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(lur Susoudan),
				'few' => q(lur Susoudan),
				'many' => q(a lurioù Susoudan),
				'one' => q(lur Susoudan),
				'other' => q(lur Susoudan),
				'two' => q(lur Susoudan),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(dobra São Tomé ha Príncipe \(1977–2017\)),
				'few' => q(dobra São Tomé ha Príncipe \(1977–2017\)),
				'many' => q(a zobraoù São Tomé ha Príncipe \(1977–2017\)),
				'one' => q(dobra São Tomé ha Príncipe \(1977–2017\)),
				'other' => q(dobra São Tomé ha Príncipe \(1977–2017\)),
				'two' => q(zobra São Tomé ha Príncipe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(dobra São Tomé ha Príncipe),
				'few' => q(dobra São Tomé ha Príncipe),
				'many' => q(a zobraoù São Tomé ha Príncipe),
				'one' => q(dobra São Tomé ha Príncipe),
				'other' => q(dobra São Tomé ha Príncipe),
				'two' => q(zobra São Tomé ha Príncipe),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(roubl soviedel),
				'few' => q(roubl soviedel),
				'many' => q(a roubloù soviedel),
				'one' => q(roubl soviedel),
				'other' => q(roubl soviedel),
				'two' => q(roubl soviedel),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(colón Salvador),
				'few' => q(cʼholón Salvador),
				'many' => q(a golónoù Salvador),
				'one' => q(cʼholón Salvador),
				'other' => q(colón Salvador),
				'two' => q(golón Salvador),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(lur Siria),
				'few' => q(lur Siria),
				'many' => q(a lurioù Siria),
				'one' => q(lur Siria),
				'other' => q(lur Siria),
				'two' => q(lur Siria),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(lilangeni Swaziland),
				'few' => q(lilangeni Swaziland),
				'many' => q(a lilangenioù Swaziland),
				'one' => q(lilangeni Swaziland),
				'other' => q(lilangeni Swaziland),
				'two' => q(lilangeni Swaziland),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(baht Thailand),
				'few' => q(baht Thailand),
				'many' => q(a vahtoù Thailand),
				'one' => q(baht Thailand),
				'other' => q(baht Thailand),
				'two' => q(vaht Thailand),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(roubl Tadjikistan),
				'few' => q(roubl Tadjikistan),
				'many' => q(a roubloù Tadjikistan),
				'one' => q(roubl Tadjikistan),
				'other' => q(roubl Tadjikistan),
				'two' => q(roubl Tadjikistan),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(somoni Tadjikistan),
				'few' => q(somoni Tadjikistan),
				'many' => q(a somonioù Tadjikistan),
				'one' => q(somoni Tadjikistan),
				'other' => q(somoni Tadjikistan),
				'two' => q(somoni Tadjikistan),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(manat Turkmenistan \(1993–2009\)),
				'few' => q(manat Turkmenistan \(1993–2009\)),
				'many' => q(a vanatoù Turkmenistan \(1993–2009\)),
				'one' => q(manat Turkmenistan \(1993–2009\)),
				'other' => q(manat Turkmenistan \(1993–2009\)),
				'two' => q(vanat Turkmenistan \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(manat Turkmenistan),
				'few' => q(manat Turkmenistan),
				'many' => q(a vanatoù Turkmenistan),
				'one' => q(manat Turkmenistan),
				'other' => q(manat Turkmenistan),
				'two' => q(vanat Turkmenistan),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(dinar Tunizia),
				'few' => q(dinar Tunizia),
				'many' => q(a zinaroù Tunizia),
				'one' => q(dinar Tunizia),
				'other' => q(dinar Tunizia),
				'two' => q(zinar Tunizia),
			},
		},
		'TOP' => {
			symbol => '$ T',
			display_name => {
				'currency' => q(paʻanga Tonga),
				'few' => q(faʻanga Tonga),
				'many' => q(a baʻangaoù Tonga),
				'one' => q(paʻanga Tonga),
				'other' => q(paʻanga Tonga),
				'two' => q(baʻanga Tonga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(escudo Timor),
				'few' => q(escudo Timor),
				'many' => q(a escudoioù Timor),
				'one' => q(escudo Timor),
				'other' => q(escudo Timor),
				'two' => q(escudo Timor),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(lur Turkia \(1922–2005\)),
				'few' => q(lur Turkia \(1922–2005\)),
				'many' => q(a lurioù Turkia \(1922–2005\)),
				'one' => q(lur Turkia \(1922–2005\)),
				'other' => q(lur Turkia \(1922–2005\)),
				'two' => q(lur Turkia \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(lur Turkia),
				'few' => q(lur Turkia),
				'many' => q(a lurioù Turkia),
				'one' => q(lur Turkia),
				'other' => q(lur Turkia),
				'two' => q(lur Turkia),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(dollar Trinidad ha Tobago),
				'few' => q(dollar Trinidad ha Tobago),
				'many' => q(a zollaroù Trinidad ha Tobago),
				'one' => q(dollar Trinidad ha Tobago),
				'other' => q(dollar Trinidad ha Tobago),
				'two' => q(zollar Trinidad ha Tobago),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(dollar nevez Taiwan),
				'few' => q(dollar nevez Taiwan),
				'many' => q(a zollaroù nevez Taiwan),
				'one' => q(dollar nevez Taiwan),
				'other' => q(dollar nevez Taiwan),
				'two' => q(zollar nevez Taiwan),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(shilling Tanzania),
				'few' => q(shilling Tanzania),
				'many' => q(a shillingoù Tanzania),
				'one' => q(shilling Tanzania),
				'other' => q(shilling Tanzania),
				'two' => q(shilling Tanzania),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(hryvnia Ukraina),
				'few' => q(hryvnia Ukraina),
				'many' => q(a hryvniaoù Ukraina),
				'one' => q(hryvnia Ukraina),
				'other' => q(hryvnia Ukraina),
				'two' => q(hryvnia Ukraina),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(shilling Ouganda \(1966–1987\)),
				'few' => q(shilling Ouganda \(1966–1987\)),
				'many' => q(a shillingoù Ouganda \(1966–1987\)),
				'one' => q(shilling Ouganda \(1966–1987\)),
				'other' => q(shilling Ouganda \(1966–1987\)),
				'two' => q(shilling Ouganda \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(shilling Ouganda),
				'few' => q(shilling Ouganda),
				'many' => q(a shillingoù Ouganda),
				'one' => q(shilling Ouganda),
				'other' => q(shilling Ouganda),
				'two' => q(shilling Ouganda),
			},
		},
		'USD' => {
			symbol => '$ SU',
			display_name => {
				'currency' => q(dollar SU),
				'few' => q(dollar SU),
				'many' => q(a zollaroù SU),
				'one' => q(dollar SU),
				'other' => q(dollar SU),
				'two' => q(zollar SU),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(peso Uruguay \(1975–1993\)),
				'few' => q(feso Uruguay \(1975–1993\)),
				'many' => q(a besoioù Uruguay \(1975–1993\)),
				'one' => q(peso Uruguay \(1975–1993\)),
				'other' => q(peso Uruguay \(1975–1993\)),
				'two' => q(beso Uruguay \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(peso Uruguay),
				'few' => q(feso Uruguay),
				'many' => q(a besoioù Uruguay),
				'one' => q(peso Uruguay),
				'other' => q(peso Uruguay),
				'two' => q(beso Uruguay),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(som Ouzbekistan),
				'few' => q(som Ouzbekistan),
				'many' => q(a somoù Ouzbekistan),
				'one' => q(som Ouzbekistan),
				'other' => q(som Ouzbekistan),
				'two' => q(som Ouzbekistan),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(bolivar Venezuela \(1871–2008\)),
				'few' => q(bolivar Venezuela \(1871–2008\)),
				'many' => q(a volivaroù Venezuela \(1871–2008\)),
				'one' => q(bolivar Venezuela \(1871–2008\)),
				'other' => q(bolivar Venezuela \(1871–2008\)),
				'two' => q(volivar Venezuela \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(bolivar Venezuela \(2008–2018\)),
				'few' => q(bolivar Venezuela \(2008–2018\)),
				'many' => q(a volivaroù Venezuela \(2008–2018\)),
				'one' => q(bolivar Venezuela \(2008–2018\)),
				'other' => q(bolivar Venezuela \(2008–2018\)),
				'two' => q(volivar Venezuela \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(bolivar Venezuela),
				'few' => q(bolivar Venezuela),
				'many' => q(a volivaroù Venezuela),
				'one' => q(bolivar Venezuela),
				'other' => q(bolivar Venezuela),
				'two' => q(volivar Venezuela),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'currency' => q(dong Viêt Nam),
				'few' => q(dong Viêt Nam),
				'many' => q(a zongoù Viêt Nam),
				'one' => q(dong Viêt Nam),
				'other' => q(dong Viêt Nam),
				'two' => q(zong Viêt Nam),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(dong Viêt Nam \(1978–1985\)),
				'few' => q(dong Viêt Nam \(1978–1985\)),
				'many' => q(a zongoù Viêt Nam \(1978–1985\)),
				'one' => q(dong Viêt Nam \(1978–1985\)),
				'other' => q(dong Viêt Nam \(1978–1985\)),
				'two' => q(zong Viêt Nam \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vatu Vanuatu),
				'few' => q(vatu Vanuatu),
				'many' => q(a vatuoù Vanuatu),
				'one' => q(vatu Vanuatu),
				'other' => q(vatu Vanuatu),
				'two' => q(vatu Vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(tala Samoa),
				'few' => q(zala Samoa),
				'many' => q(a dalaoù Samoa),
				'one' => q(tala Samoa),
				'other' => q(tala Samoa),
				'two' => q(dala Samoa),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(lur CFA Kreizafrika),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(arcʼhant),
				'few' => q(oñs troy arcʼhant),
				'many' => q(oñs troy arcʼhant),
				'one' => q(oñs troy arcʼhant),
				'other' => q(oñs troy arcʼhant),
				'two' => q(oñs troy arcʼhant),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(aour),
				'few' => q(oñs troy aour),
				'many' => q(oñs troy aour),
				'one' => q(oñs troy aour),
				'other' => q(oñs troy aour),
				'two' => q(oñs troy aour),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(unanenn genaoz europat),
				'few' => q(unanenn genaoz europat),
				'many' => q(a unanennoù kenaoz europat),
				'one' => q(unanenn genaoz europat),
				'other' => q(unanenn genaoz europat),
				'two' => q(unanenn genaoz europat),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(unanenn voneiz europat),
				'few' => q(unanenn voneiz europat),
				'many' => q(a unanennoù moneiz europat),
				'one' => q(unanenn voneiz europat),
				'other' => q(unanenn voneiz europat),
				'two' => q(unanenn voneiz europat),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(unanenn jediñ europat \(XBC\)),
				'few' => q(unanenn jediñ europat \(XBC\)),
				'many' => q(a unanennoù jediñ europat \(XBC\)),
				'one' => q(unanenn jediñ europat \(XBC\)),
				'other' => q(unanenn jediñ europat \(XBC\)),
				'two' => q(unanenn jediñ europat \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(unanenn jediñ europat \(XBD\)),
				'few' => q(unanenn jediñ europat \(XBD\)),
				'many' => q(a unanennoù jediñ europat \(XBD\)),
				'one' => q(unanenn jediñ europat \(XBD\)),
				'other' => q(unanenn jediñ europat \(XBD\)),
				'two' => q(unanenn jediñ europat \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'XCD',
			display_name => {
				'currency' => q(dollar Karib ar reter),
				'few' => q(dollar Karib ar reter),
				'many' => q(a zollaroù Karib ar reter),
				'one' => q(dollar Karib ar reter),
				'other' => q(dollar Karib ar reter),
				'two' => q(zollar Karib ar reter),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(gwirioù tennañ arbennik),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(unanenn jediñ europat),
				'few' => q(unanenn jediñ europat),
				'many' => q(a unanennoù jediñ europat),
				'one' => q(unanenn jediñ europat),
				'other' => q(unanenn jediñ europat),
				'two' => q(unanenn jediñ europat),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(lur aour Frañs),
				'few' => q(lur aour Frañs),
				'many' => q(a lurioù aour Frañs),
				'one' => q(lur aour Frañs),
				'other' => q(lur aour Frañs),
				'two' => q(lur aour Frañs),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(lur Unaniezh etrebroadel an hentoù-houarn),
				'few' => q(lur Unaniezh etrebroadel an hentoù-houarn),
				'many' => q(a lurioù Unaniezh etrebroadel an hentoù-houarn),
				'one' => q(lur Unaniezh etrebroadel an hentoù-houarn),
				'other' => q(lur Unaniezh etrebroadel an hentoù-houarn),
				'two' => q(lur Unaniezh etrebroadel an hentoù-houarn),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(lur CFA Afrika ar Cʼhornôg),
				'few' => q(lur CFA BCEAO),
				'many' => q(a lurioù CFA BCEAO),
				'one' => q(lur CFA Afrika ar Cʼhornôg),
				'other' => q(lur CFA Afrika ar Cʼhornôg),
				'two' => q(lur CFA BCEAO),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(palladiom),
				'few' => q(oñs troy palladiom),
				'many' => q(oñs troy palladiom),
				'one' => q(oñs troy palladiom),
				'other' => q(oñs troy palladiom),
				'two' => q(oñs troy palladiom),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(lur CFP),
				'few' => q(lur CFP),
				'many' => q(a lurioù CFP),
				'one' => q(lur CFP),
				'other' => q(lur CFP),
				'two' => q(lur CFP),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platin),
				'few' => q(oñs troy platin),
				'many' => q(oñs troy platin),
				'one' => q(oñs troy platin),
				'other' => q(oñs troy platin),
				'two' => q(oñs troy platin),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(kod moneiz amprouiñ),
				'few' => q(unanenn voneiz amprouiñ),
				'many' => q(a unanennoù voneiz amprouiñ),
				'one' => q(unanenn voneiz amprouiñ),
				'other' => q(unanenn voneiz amprouiñ),
				'two' => q(unanenn voneiz amprouiñ),
			},
		},
		'XUA' => {
			display_name => {
				'currency' => q(unanenn jediñ BAD),
				'few' => q(unanenn jediñ BAD),
				'many' => q(a unanennoù jediñ BAD),
				'one' => q(unanenn jediñ BAD),
				'other' => q(unanenn jediñ BAD),
				'two' => q(unanenn jediñ BAD),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(moneiz dianav),
				'few' => q(\(moneiz dianav\)),
				'many' => q(\(moneiz dianav\)),
				'one' => q(\(moneiz dianav\)),
				'other' => q(\(moneiz dianav\)),
				'two' => q(\(moneiz dianav\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(dinar Yemen),
				'few' => q(dinar Yemen),
				'many' => q(a zinaroù Yemen),
				'one' => q(dinar Yemen),
				'other' => q(dinar Yemen),
				'two' => q(zinar Yemen),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(rial Yemen),
				'few' => q(rial Yemen),
				'many' => q(a rialoù Yemen),
				'one' => q(rial Yemen),
				'other' => q(rial Yemen),
				'two' => q(rial Yemen),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(dinar nevez Yougoslavia \(1994–2002\)),
				'few' => q(dinar nevez Yougoslavia \(1994–2002\)),
				'many' => q(a zinaroù nevez Yougoslavia \(1994–2002\)),
				'one' => q(dinar nevez Yougoslavia \(1994–2002\)),
				'other' => q(dinar nevez Yougoslavia \(1994–2002\)),
				'two' => q(zinar nevez Yougoslavia \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(dinar kemmadus Yougoslavia \(1990–1992\)),
				'few' => q(dinar kemmadus Yougoslavia \(1990–1992\)),
				'many' => q(a zinaroù kemmadus Yougoslavia \(1990–1992\)),
				'one' => q(dinar kemmadus Yougoslavia \(1990–1992\)),
				'other' => q(dinar kemmadus Yougoslavia \(1990–1992\)),
				'two' => q(zinar kemmadus Yougoslavia \(1990–1992\)),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(dinar adreizhet Yougoslavia \(1992–1993\)),
				'few' => q(dinar adreizhet Yougoslavia \(1992–1993\)),
				'many' => q(a zinaroù adreizhet Yougoslavia \(1992–1993\)),
				'one' => q(dinar adreizhet Yougoslavia \(1992–1993\)),
				'other' => q(dinar adreizhet Yougoslavia \(1992–1993\)),
				'two' => q(zinar adreizhet Yougoslavia \(1992–1993\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(rand Suafrika),
				'few' => q(rand Suafrika),
				'many' => q(a randoù Suafrika),
				'one' => q(rand Suafrika),
				'other' => q(rand Suafrika),
				'two' => q(rand Suafrika),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(kwacha Zambia \(1968–2012\)),
				'few' => q(kwacha Zambia \(1968–2012\)),
				'many' => q(a gwachaoù Zambia \(1968–2012\)),
				'one' => q(cʼhwacha Zambia \(1968–2012\)),
				'other' => q(kwacha Zambia \(1968–2012\)),
				'two' => q(gwacha Zambia \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(kwacha Zambia),
				'few' => q(kwacha Zambia),
				'many' => q(a gwachaoù Zambia),
				'one' => q(cʼhwacha Zambia),
				'other' => q(kwacha Zambia),
				'two' => q(gwacha Zambia),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(dollar Zimbabwe \(1980–2008\)),
				'few' => q(dollar Zimbabwe \(1980–2008\)),
				'many' => q(a zollaroù Zimbabwe \(1980–2008\)),
				'one' => q(dollar Zimbabwe \(1980–2008\)),
				'other' => q(dollar Zimbabwe \(1980–2008\)),
				'two' => q(zollar Zimbabwe \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(dollar Zimbabwe \(2009\)),
				'few' => q(dollar Zimbabwe \(2009\)),
				'many' => q(a zollaroù Zimbabwe \(2009\)),
				'one' => q(dollar Zimbabwe \(2009\)),
				'other' => q(dollar Zimbabwe \(2009\)),
				'two' => q(zollar Zimbabwe \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(dollar Zimbabwe \(2008\)),
				'few' => q(dollar Zimbabwe \(2008\)),
				'many' => q(a zollaroù Zimbabwe \(2008\)),
				'one' => q(dollar Zimbabwe \(2008\)),
				'other' => q(dollar Zimbabwe \(2008\)),
				'two' => q(zollar Zimbabwe \(2008\)),
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
							'miz 1',
							'miz 2',
							'miz 3',
							'miz 4',
							'miz 5',
							'miz 6',
							'miz 7',
							'miz 8',
							'miz 9',
							'miz 10',
							'miz 11',
							'miz 12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'kentañ miz',
							'eil miz',
							'trede miz',
							'pevare miz',
							'pempvet miz',
							'cʼhwecʼhvet miz',
							'seizhvet miz',
							'eizhvet miz',
							'navet miz',
							'dekvet miz',
							'unnekvet miz',
							'daouzekvet miz'
						],
						leap => [
							
						],
					},
				},
			},
			'dangi' => {
				'format' => {
					abbreviated => {
						nonleap => [
							'kentañ miz',
							'eil miz',
							'trede miz',
							'pevare miz',
							'pempvet miz',
							'cʼhwecʼhvet miz',
							'seizhvet miz',
							'eizhvet miz',
							'navet miz',
							'dekvet miz',
							'unnekvet miz',
							'daouzekvet miz'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'kentañ miz',
							'eil miz',
							'trede miz',
							'pevare miz',
							'pempvet miz',
							'cʼhwecʼhvet miz',
							'seizhvet miz',
							'eizhvet miz',
							'navet miz',
							'dekvet miz',
							'unnekvet miz',
							'daouzekvet miz'
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
							'Gen.',
							'Cʼhwe.',
							'Meur.',
							'Ebr.',
							'Mae',
							'Mezh.',
							'Goue.',
							'Eost',
							'Gwen.',
							'Here',
							'Du',
							'Kzu.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Genver',
							'Cʼhwevrer',
							'Meurzh',
							'Ebrel',
							'Mae',
							'Mezheven',
							'Gouere',
							'Eost',
							'Gwengolo',
							'Here',
							'Du',
							'Kerzu'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'01',
							'02',
							'03',
							'04',
							'05',
							'06',
							'07',
							'08',
							'09',
							'10',
							'11',
							'12'
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
						mon => 'Lun',
						tue => 'Meu.',
						wed => 'Mer.',
						thu => 'Yaou',
						fri => 'Gwe.',
						sat => 'Sad.',
						sun => 'Sul'
					},
					wide => {
						mon => 'Lun',
						tue => 'Meurzh',
						wed => 'Mercʼher',
						thu => 'Yaou',
						fri => 'Gwener',
						sat => 'Sadorn',
						sun => 'Sul'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'L',
						tue => 'Mz',
						wed => 'Mc',
						thu => 'Y',
						fri => 'G',
						sat => 'Sa',
						sun => 'Su'
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
					abbreviated => {0 => '1añ trim.',
						1 => '2l trim.',
						2 => '3e trim.',
						3 => '4e trim.'
					},
					wide => {0 => '1añ trimiziad',
						1 => '2l trimiziad',
						2 => '3e trimiziad',
						3 => '4e trimiziad'
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
					'am' => q{A.M.},
					'pm' => q{G.M.},
				},
				'narrow' => {
					'am' => q{am},
					'pm' => q{gm},
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
				'0' => 'A.B.'
			},
			narrow => {
				'0' => 'AB'
			},
			wide => {
				'0' => 'amzervezh voudaek'
			},
		},
		'chinese' => {
		},
		'dangi' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'a-raok J.K.',
				'1' => 'goude J.K.'
			},
			wide => {
				'0' => 'a-raok Jezuz-Krist',
				'1' => 'goude Jezuz-Krist'
			},
		},
		'hebrew' => {
		},
		'roc' => {
			abbreviated => {
				'0' => 'a-raok R.S.',
				'1' => 'R.S.'
			},
			wide => {
				'0' => 'a-raok Republik Sina',
				'1' => 'Republik Sina'
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
		'chinese' => {
			'full' => q{EEEE d MMMM r (U)},
			'long' => q{d MMMM r (U)},
			'medium' => q{d MMM r},
			'short' => q{dd/MM/r},
		},
		'dangi' => {
		},
		'generic' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{dd/MM/y GGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd/MM/y},
		},
		'hebrew' => {
		},
		'roc' => {
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
		},
		'chinese' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1} {0}},
		},
		'dangi' => {
		},
		'generic' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1} {0}},
		},
		'hebrew' => {
		},
		'roc' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			Ed => q{E d},
			Gy => q{r (U)},
			GyMMM => q{MMM r (U)},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
		},
		'dangi' => {
			GyMMMEd => q{E d MMM r (U)},
			GyMMMd => q{d MMM r},
			MEd => q{E, d/M},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			UM => q{M/U},
			UMMM => q{MMM U},
			UMMMd => q{d MMM, U},
			UMd => q{d/M/U},
			y => q{r (U)},
			yMd => q{d/M/r},
			yyyy => q{r (U)},
			yyyyM => q{M/r},
			yyyyMEd => q{E, M/d/r},
			yyyyMMM => q{MMM r (U)},
			yyyyMMMEd => q{E d MMM r (U)},
			yyyyMMMM => q{MMMM r (U)},
			yyyyMMMd => q{d MMM r},
			yyyyMd => q{d/M/r},
			yyyyQQQ => q{QQQ r (U)},
			yyyyQQQQ => q{QQQQ r (U)},
		},
		'generic' => {
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			MEd => q{E dd/MM},
			MMMEd => q{E d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{MM/y GGGGG},
			yyyyMEd => q{E dd/MM/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{dd/MM/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			M => q{MM},
			MEd => q{E dd/MM},
			MMMEd => q{E d MMM},
			MMMMW => q{'sizhun' W 'miz' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd/MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{MM/y},
			yMEd => q{E dd/MM/y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd/MM/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'sizhun' w Y},
		},
		'hebrew' => {
			MEd => q{E d MMM},
			Md => q{d MMM},
			y => q{y},
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
		'buddhist' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
		},
		'chinese' => {
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
		},
		'dangi' => {
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d MMM – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			yM => {
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
		},
		'generic' => {
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{MM/y GGGGG – MM/y GGGGG},
				M => q{MM/y – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			GyMEd => {
				G => q{E dd/MM/y GGGGG – E dd/MM/y GGGGG},
				M => q{E dd/MM/y – E dd/MM/y GGGGG},
				d => q{E dd/MM/y – E dd/MM/y GGGGG},
				y => q{E dd/MM/y – E dd/MM/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E d MMM y G – E d MMM y G},
				M => q{E d MMM – E d MMM y G},
				d => q{E d MMM y – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{dd/MM/y GGGGG – dd/MM/y GGGGG},
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{dd/MM/y – dd/MM/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
			},
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d MMM – E d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd/MM–dd/MM},
				d => q{dd/MM–dd/MM},
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
				y => q{y–y G},
			},
			yM => {
				M => q{MM/y–MM/y GGGGG},
				y => q{MM/y–MM/y GGGGG},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y GGGGG},
				d => q{E dd/MM/y – E dd/MM/y GGGGG},
				y => q{E dd/MM/y – E dd/MM/y GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y G},
				d => q{E d MMM – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{dd/MM/y–dd/MM/y GGGGG},
				d => q{dd/MM/y–dd/MM/y GGGGG},
				y => q{dd/MM/y–dd/MM/y GGGGG},
			},
		},
		'gregorian' => {
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{MM/y GGGGG – MM/y GGGGG},
				M => q{MM/y – MM/y GGGGG},
				y => q{MM/y – MM/y GGGGG},
			},
			GyMEd => {
				G => q{E dd/MM/y GGGGG – E dd/MM/y GGGGG},
				M => q{E dd/MM/y – E dd/MM/y GGGGG},
				d => q{E dd/MM/y – E dd/MM/y GGGGG},
				y => q{E dd/MM/y – E dd/MM/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E d MMM y G – E d MMM y G},
				M => q{E d MMM – E d MMM y G},
				d => q{E d MMM – E d MMM y G},
				y => q{E d MMM y – E d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{dd/MM/y GGGGG – dd/MM/y GGGGG},
				M => q{dd/MM/y – dd/MM/y GGGGG},
				d => q{dd/MM/y – dd/MM/y GGGGG},
				y => q{dd/MM/y – dd/MM/y GGGGG},
			},
			MEd => {
				M => q{E dd/MM – E dd/MM},
				d => q{E dd/MM – E dd/MM},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d MMM – E d MMM},
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
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E dd/MM/y – E dd/MM/y},
				d => q{E dd/MM/y – E dd/MM/y},
				y => q{E dd/MM/y – E dd/MM/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E d MMM – E d MMM y},
				d => q{E d MMM – E d MMM y},
				y => q{E d MMM y – E d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
			},
		},
		'hebrew' => {
			MEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d MMM – E d MMM},
			},
			Md => {
				M => q{d MMM – d MMM},
			},
			yM => {
				M => q{MMM y – MMM y GGGGG},
				y => q{MMM y – MMM y GGGGG},
			},
			yMEd => {
				M => q{E d MMM – E d MMM y GGGGG},
				d => q{E d MMM – E d MMM y GGGGG},
				y => q{E d MMM y – E d MMM y GGGGG},
			},
			yMMM => {
				M => q{MMM y – MMM y G},
			},
			yMd => {
				M => q{d MMM y – d MMM y GGGGG},
				d => q{d–d MMM y GGGGG},
				y => q{d MMM y – d MMM y GGGGG},
			},
		},
	} },
);

has 'cyclic_name_sets' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'dangi' => {
			'solarTerms' => {
				'format' => {
					'abbreviated' => {
						3 => q(kedez-Veurzh),
						9 => q(goursav-heol an hañv),
					},
					'wide' => {
						3 => q(kedez-Veurzh),
						9 => q(goursav-heol an hañv),
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
		regionFormat => q(eur {0}),
		regionFormat => q(eur hañv {0}),
		regionFormat => q(eur cʼhoañv {0}),
		'Afghanistan' => {
			long => {
				'standard' => q#eur Afghanistan#,
			},
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Adis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Aljer#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kaero#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Dar el Beida (Casablanca)#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#LaʼYoun#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Muqdisho#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#NʼDjamena#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tarabulus (Tripoli)#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tuniz#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#eur Kreizafrika#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#eur Afrika ar Reter#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#eur cʼhoañv Suafrika#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#eur hañv Afrika ar Cʼhornôg#,
				'generic' => q#eur Afrika ar Cʼhornôg#,
				'standard' => q#eur cʼhoañv Afrika ar Cʼhornôg#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#eur hañv Alaska#,
				'generic' => q#eur Alaska#,
				'standard' => q#eur cʼhoañv Alaska#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#eur hañv Almaty#,
				'generic' => q#eur Almaty#,
				'standard' => q#eur cʼhoañv Almaty#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#eur hañv an Amazon#,
				'generic' => q#eur an Amazon#,
				'standard' => q#eur cʼhoañv an Amazon#,
			},
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvador#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuuk (Godthåb)#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Gwadeloup#,
		},
		'America/Havana' => {
			exemplarCity => q#La Habana#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaika#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinik#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Kêr Vecʼhiko#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Mikelon#,
		},
		'America/Panama' => {
			exemplarCity => q#Panamá#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint Barthélemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Saint Johnʼs#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Saint Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Saint Lucia#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Sant Visant#,
		},
		'America/Thule' => {
			exemplarCity => q#Qânâq#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#eur hañv ar Cʼhreiz#,
				'generic' => q#eur ar Cʼhreiz#,
				'standard' => q#eur cʼhoañv ar Cʼhreiz#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#eur hañv ar Reter#,
				'generic' => q#eur ar Reter#,
				'standard' => q#eur cʼhoañv ar Reter#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#eur hañv ar Menezioù#,
				'generic' => q#eur ar Menezioù#,
				'standard' => q#eur cʼhoañv ar Menezioù#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#eur hañv an Habask#,
				'generic' => q#eur an Habask#,
				'standard' => q#eur cʼhoañv an Habask#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#eur hañv Anadyrʼ#,
				'generic' => q#eur Anadyrʼ#,
				'standard' => q#eur cʼhoañv Anadyrʼ#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#eur hañv Apia#,
				'generic' => q#eur Apia#,
				'standard' => q#eur cʼhoañv Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#eur hañv Arabia#,
				'generic' => q#eur Arabia#,
				'standard' => q#eur cʼhoañv Arabia#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#eur hañv Arcʼhantina#,
				'generic' => q#eur Arcʼhantina#,
				'standard' => q#eur cʼhoañv Arcʼhantina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#eur hañv Arcʼhantina ar Cʼhornôg#,
				'generic' => q#eur Arcʼhantina ar Cʼhornôg#,
				'standard' => q#eur cʼhoañv Arcʼhantina ar Cʼhornôg#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#eur hañv Armenia#,
				'generic' => q#eur Armenia#,
				'standard' => q#eur cʼhoañv Armenia#,
			},
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadyrʼ#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrein#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Bakou#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Bayrut#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Calcutta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Tchita#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolamba#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damask#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jeruzalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kaboul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtchatka#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Koweit#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Masqat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Levkosía#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Phnum Pénh#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pʼyongyang#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Kêr Hô-Chi-Minh#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapour#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Toshkent#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Ürümqi#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Viangchan#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Yekaterinbourg#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#eur hañv an Atlantel#,
				'generic' => q#eur an Atlantel#,
				'standard' => q#eur cʼhoañv an Atlantel#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azorez#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermudez#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanariez#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kab Glas#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faero#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Georgia ar Su#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Saint Helena#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#eur hañv Kreizaostralia#,
				'generic' => q#eur Kreizaostralia#,
				'standard' => q#eur cʼhoañv Kreizaostralia#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#eur hañv Kreizaostralia ar Cʼhornôg#,
				'generic' => q#eur Kreizaostralia ar Cʼhornôg#,
				'standard' => q#eur cʼhoañv Kreizaostralia ar Cʼhornôg#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#eur hañv Aostralia ar Reter#,
				'generic' => q#eur Aostralia ar Reter#,
				'standard' => q#eur cʼhoañv Aostralia ar Reter#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#eur hañv Aostralia ar Cʼhornôg#,
				'generic' => q#eur Aostralia ar Cʼhornôg#,
				'standard' => q#eur cʼhoañv Aostralia ar Cʼhornôg#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#eur hañv Azerbaidjan#,
				'generic' => q#eur Azerbaidjan#,
				'standard' => q#eur cʼhoañv Azerbaidjan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#eur hañv an Azorez#,
				'generic' => q#eur an Azorez#,
				'standard' => q#eur cʼhoañv an Azorez#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#eur hañv Bangladesh#,
				'generic' => q#eur Bangladesh#,
				'standard' => q#eur cʼhoañv Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#eur Bhoutan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#eur Bolivia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#eur hañv Brasília#,
				'generic' => q#eur Brasília#,
				'standard' => q#eur cʼhoañv Brasília#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#eur Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#eur hañv ar Cʼhab-Glas#,
				'generic' => q#eur ar Cʼhab-Glas#,
				'standard' => q#eur cʼhoañv ar Cʼhab-Glas#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#eur Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#eur hañv Chatham#,
				'generic' => q#eur Chatham#,
				'standard' => q#eur cʼhoañv Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#eur hañv Chile#,
				'generic' => q#eur Chile#,
				'standard' => q#eur cʼhoañv Chile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#eur hañv Sina#,
				'generic' => q#eur Sina#,
				'standard' => q#eur cʼhoañv Sina#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#eur hañv Choibalsan#,
				'generic' => q#eur Choibalsan#,
				'standard' => q#eur cʼhoañv Choibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#eur Enez Christmas#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#eur Inizi Kokoz#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#eur hañv Kolombia#,
				'generic' => q#eur Kolombia#,
				'standard' => q#eur cʼhoañv Kolombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#eur hañv Inizi Cook#,
				'generic' => q#eur Inizi Cook#,
				'standard' => q#eur cʼhoañv Inizi Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#eur hañv Kuba#,
				'generic' => q#eur Kuba#,
				'standard' => q#eur cʼhoañv Kuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#eur Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#eur Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#eur Timor ar Reter#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#eur hañv Enez Pask#,
				'generic' => q#eur Enez Pask#,
				'standard' => q#eur cʼhoañv Enez Pask#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#eur Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#amzer hollvedel kenurzhiet#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#kêr dianav#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Aten#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Beograd#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brusel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dulenn#,
			long => {
				'daylight' => q#eur cʼhoañv Iwerzhon#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Jibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Gwernenez#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Manav#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jerzenez#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisboa#,
		},
		'Europe/London' => {
			exemplarCity => q#Londrez#,
			long => {
				'daylight' => q#eur hañv Breizh-Veur#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luksembourg#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Marjehamn#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Mensk#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskov#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Pariz#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praha#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tiranë#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsovia#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#eur hañv Kreizeuropa#,
				'generic' => q#eur Kreizeuropa#,
				'standard' => q#eur cʼhoañv Kreizeuropa#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#eur hañv Europa ar Reter#,
				'generic' => q#eur Europa ar Reter#,
				'standard' => q#eur cʼhoañv Europa ar Reter#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#eur Kaliningrad#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#eur hañv Europa ar Cʼhornôg#,
				'generic' => q#eur Europa ar Cʼhornôg#,
				'standard' => q#eur cʼhoañv Europa ar Cʼhornôg#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#eur hañv Inizi Falkland#,
				'generic' => q#eur Inizi Falkland#,
				'standard' => q#eur cʼhoañv Inizi Falkland#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#eur hañv Fidji#,
				'generic' => q#eur Fidji#,
				'standard' => q#eur cʼhoañv Fidji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#eur Gwiana cʼhall#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#eur Douaroù aostral Frañs hag Antarktika#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Amzer keitat Greenwich (AKG)#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#eur Inizi Galápagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#eur Inizi Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#eur hañv Jorjia#,
				'generic' => q#eur Jorjia#,
				'standard' => q#eur cʼhoañv Jorjia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#eur Inizi Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#eur hañv Greunland ar Reter#,
				'generic' => q#eur Greunland ar Reter#,
				'standard' => q#eur cʼhoañv Greunland ar Reter#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#eur hañv Greunland ar Cʼhornôg#,
				'generic' => q#eur Greunland ar Cʼhornôg#,
				'standard' => q#eur cʼhoañv Greunland ar Cʼhornôg#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#eur cʼhoañv Guam#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#eur cʼhoañv ar Pleg-mor Arab-ha-Pers#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#eur Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#eur hañv Hawaii hag an Aleouted#,
				'generic' => q#eur Hawaii hag an Aleouted#,
				'standard' => q#eur cʼhoañv Hawaii hag an Aleouted#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#eur hañv Hong Kong#,
				'generic' => q#eur Hong Kong#,
				'standard' => q#eur cʼhoañv Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#eur hañv Hovd#,
				'generic' => q#eur Hovd#,
				'standard' => q#eur cʼhoañv Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#eur cʼhoañv India#,
			},
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokoz#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komorez#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kergelenn#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivez#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Moris#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reünion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#eur Meurvor Indez#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#eur Indez-Sina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#eur Kreiz Indonezia#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#eur Indonezia ar Reter#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#eur Indonezia ar Cʼhornôg#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#eur hañv Iran#,
				'generic' => q#eur Iran#,
				'standard' => q#eur cʼhoañv Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#eur hañv Irkutsk#,
				'generic' => q#eur Irkutsk#,
				'standard' => q#eur cʼhoañv Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#eur hañv Israel#,
				'generic' => q#eur Israel#,
				'standard' => q#eur cʼhoañv Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#eur hañv Japan#,
				'generic' => q#eur Japan#,
				'standard' => q#eur cʼhoañv Japan#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#eur Kazakstan ar Reter#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#eur Kazakstan ar Cʼhornôg#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#eur hañv Korea#,
				'generic' => q#eur Korea#,
				'standard' => q#eur cʼhoañv Korea#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#eur Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#eur hañv Krasnoyarsk#,
				'generic' => q#eur Krasnoyarsk#,
				'standard' => q#eur cʼhoañv Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#eur Kyrgyzstan#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#eur Sri Lanka#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#eur Line Islands#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#eur hañv Lord Howe#,
				'generic' => q#eur Lord Howe#,
				'standard' => q#eur cʼhoañv Lord Howe#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#eur hañv Macau#,
				'generic' => q#eur Macau#,
				'standard' => q#eur cʼhoañv Macau#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#eur Enez Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#eur hañv Magadan#,
				'generic' => q#eur Magadan#,
				'standard' => q#eur cʼhoañv Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#eur Malaysia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#eur ar Maldivez#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#eur Inizi Markiz#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#eur Inizi Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#eur hañv Moris#,
				'generic' => q#eur Moris#,
				'standard' => q#eur cʼhoañv Moris#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#eur Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#eur hañv Gwalarn Mecʼhiko#,
				'generic' => q#eur Gwalarn Mecʼhiko#,
				'standard' => q#eur cʼhoañv Gwalarn Mecʼhiko#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#eur hañv an Habask mecʼhikan#,
				'generic' => q#eur an Habask mecʼhikan#,
				'standard' => q#eur cʼhoañv an Habask mecʼhikan#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#eur hañv Ulaanbaatar#,
				'generic' => q#eur Ulaanbaatar#,
				'standard' => q#eur cʼhoañv Ulaanbaatar#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#eur hañv Moskov#,
				'generic' => q#eur Moskov#,
				'standard' => q#eur cʼhoañv Moskov#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#eur Myanmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#eur Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#eur Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#eur hañv Kaledonia Nevez#,
				'generic' => q#eur Kaledonia Nevez#,
				'standard' => q#eur cʼhoañv Kaledonia Nevez#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#eur hañv Zeland-Nevez#,
				'generic' => q#eur Zeland-Nevez#,
				'standard' => q#eur cʼhoañv Zeland-Nevez#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#eur hañv Newfoundland#,
				'generic' => q#eur Newfoundland#,
				'standard' => q#eur cʼhoañv Newfoundland#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#eur Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#eur hañv Enez Norfolk#,
				'generic' => q#eur Enez Norfolk#,
				'standard' => q#eur cʼhoañv Enez Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#eur hañv Fernando de Noronha#,
				'generic' => q#eur Fernando de Noronha#,
				'standard' => q#eur cʼhoañv Fernando de Noronha#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#eur Mariana an Norzh#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#eur hañv Novosibirsk#,
				'generic' => q#eur Novosibirsk#,
				'standard' => q#eur cʼhoañv Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#eur hañv Omsk#,
				'generic' => q#eur Omsk#,
				'standard' => q#eur cʼhoañv Omsk#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Enez Pask#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidji#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galápagos#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markiz#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#eur hañv Pakistan#,
				'generic' => q#eur Pakistan#,
				'standard' => q#eur cʼhoañv Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#eur Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#eur Papoua-Ginea-Nevez#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#eur hañv Paraguay#,
				'generic' => q#eur Paraguay#,
				'standard' => q#eur cʼhoañv Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#eur hañv Perou#,
				'generic' => q#eur Perou#,
				'standard' => q#eur cʼhoañv Perou#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#eur hañv ar Filipinez#,
				'generic' => q#eur ar Filipinez#,
				'standard' => q#eur cʼhoañv ar Filipinez#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#eur Inizi Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#eur hañv Sant-Pêr-ha-Mikelon#,
				'generic' => q#eur Sant-Pêr-ha-Mikelon#,
				'standard' => q#eur cʼhoañv Sant-Pêr-ha-Mikelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#eur Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#eur Pohnpei#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#eur Pʼyongyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#eur ar Reünion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#eur Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#eur hañv Sakhalin#,
				'generic' => q#eur Sakhalin#,
				'standard' => q#eur cʼhoañv Sakhalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#eur hañv Samoa#,
				'generic' => q#eur Samoa#,
				'standard' => q#eur cʼhoañv Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#eur Sechelez#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#eur cʼhoañv Singapour#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#eur Inizi Salomon#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#eur Georgia ar Su#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#eur Surinam#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#eur Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#eur Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#eur hañv Taipei#,
				'generic' => q#eur Taipei#,
				'standard' => q#eur cʼhoañv Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#eur Tadjikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#eur Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#eur hañv Tonga#,
				'generic' => q#eur Tonga#,
				'standard' => q#eur cʼhoañv Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#eur Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#eur hañv Turkmenistan#,
				'generic' => q#eur Turkmenistan#,
				'standard' => q#eur cʼhoañv Turkmenistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#eur Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#eur hañv Uruguay#,
				'generic' => q#eur Uruguay#,
				'standard' => q#eur cʼhoañv Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#eur hañv Ouzbekistan#,
				'generic' => q#eur Ouzbekistan#,
				'standard' => q#eur cʼhoañv Ouzbekistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#eur hañv Vanuatu#,
				'generic' => q#eur Vanuatu#,
				'standard' => q#eur cʼhoañv Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#eur Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#eur hañv Vladivostok#,
				'generic' => q#eur Vladivostok#,
				'standard' => q#eur cʼhoañv Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#eur hañv Volgograd#,
				'generic' => q#eur Volgograd#,
				'standard' => q#eur cʼhoañv Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#eur Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#eur Wake Island#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#eur Wallis ha Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#eur hañv Yakutsk#,
				'generic' => q#eur Yakutsk#,
				'standard' => q#eur cʼhoañv Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#eur hañv Yekaterinbourg#,
				'generic' => q#eur Yekaterinbourg#,
				'standard' => q#eur cʼhoañv Yekaterinbourg#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
