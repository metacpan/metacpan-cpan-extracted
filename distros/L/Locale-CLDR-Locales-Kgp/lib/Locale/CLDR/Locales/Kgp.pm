=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Kgp - Package for language Kaingang

=cut

package Locale::CLDR::Locales::Kgp;
# This file auto generated from Data\common\main\kgp.xml
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
 				'ab' => 'amekaso',
 				'ace' => 'agsẽm',
 				'ach' => 'akori',
 				'ada' => 'anágme',
 				'ady' => 'anhige',
 				'ae' => 'avétiko',
 				'af' => 'afrikỹnẽ',
 				'afh' => 'afrihiri',
 				'agq' => 'aghẽm',
 				'ain' => 'ajinũ',
 				'ak' => 'akỹn',
 				'akk' => 'akajỹnũ',
 				'ale' => 'arevute',
 				'alt' => 'artaj sur',
 				'am' => 'amỹriko',
 				'an' => 'aragonẽ',
 				'ang' => 'ĩnhgrej arkajiku',
 				'anp' => 'ỹgika',
 				'ar' => 'arame',
 				'ar_001' => 'arame ta’ũn',
 				'arc' => 'aramajiko',
 				'arn' => 'mỹpunugũn',
 				'arp' => 'arapaho',
 				'ars' => 'arame nẽgene',
 				'arw' => 'aruvaki',
 				'as' => 'ajamẽ',
 				'asa' => 'asu',
 				'ast' => 'anhturijỹnũ',
 				'av' => 'avariko',
 				'awa' => 'avanhi',
 				'ay' => 'ajimỹra',
 				'az' => 'ajermajỹnũ',
 				'az_Arab' => 'aseri sur',
 				'ba' => 'majkir',
 				'bal' => 'marusi',
 				'ban' => 'marinẽj',
 				'bas' => 'masa',
 				'bax' => 'mamũm',
 				'bbj' => 'gumỹra',
 				'be' => 'huso-kupri',
 				'bej' => 'meja',
 				'bem' => 'mema',
 				'bez' => 'menỹ',
 				'bfd' => 'mafun',
 				'bg' => 'mugaru',
 				'bgn' => 'marusi-rãpurja',
 				'bho' => 'mojpuri',
 				'bi' => 'miramá',
 				'bik' => 'mikor',
 				'bin' => 'minĩ',
 				'bkm' => 'kãm',
 				'bla' => 'sigsika',
 				'bm' => 'mámara',
 				'bn' => 'megari',
 				'bo' => 'timetỹnũ',
 				'br' => 'mretỹ',
 				'bra' => 'mraj',
 				'brx' => 'mono',
 				'bs' => 'mojnia',
 				'bss' => 'akuse',
 				'bua' => 'murijato',
 				'bug' => 'muginẽj',
 				'bum' => 'muru',
 				'byn' => 'mrĩn',
 				'byv' => 'menuma',
 				'ca' => 'katarũg',
 				'cad' => 'kano',
 				'car' => 'karime',
 				'cay' => 'kajuga',
 				'cch' => 'ansỹm',
 				'ccp' => 'sakimỹ',
 				'ce' => 'sesẽnũ',
 				'ceb' => 'semujỹnũ',
 				'cgg' => 'siga',
 				'ch' => 'samãhu',
 				'chb' => 'simsa',
 				'chg' => 'sagataj',
 				'chk' => 'sukese',
 				'chm' => 'mỹri',
 				'chn' => 'jargỹ sinũki',
 				'cho' => 'sogtavo',
 				'chp' => 'sipevyjỹ',
 				'chr' => 'seroki',
 				'chy' => 'sejẽnẽ',
 				'ckb' => 'kurno kuju',
 				'co' => 'korso',
 				'cop' => 'komta',
 				'cr' => 'kri',
 				'crh' => 'krimẽja tá turko',
 				'crs' => 'sejséri krijoro-frỹsej',
 				'cs' => 'séko',
 				'csb' => 'kasumijỹ',
 				'cu' => 'eravu ekresijatiko',
 				'cv' => 'suvase',
 				'cy' => 'garej',
 				'da' => 'nhinỹmỹrkej',
 				'dak' => 'nakota',
 				'dar' => 'narguva',
 				'dav' => 'tajta',
 				'de' => 'arimỹv',
 				'de_CH' => 'suvisa arimỹv-téj',
 				'del' => 'neravare',
 				'den' => 'sirave',
 				'dgr' => 'nogrim',
 				'din' => 'ninka',
 				'dje' => 'jarma',
 				'doi' => 'nogri',
 				'dsb' => 'soramiv rur',
 				'dua' => 'nuvara',
 				'dum' => 'orỹnej kuju',
 				'dv' => 'nivehi',
 				'dyo' => 'jora-fonyj',
 				'dyu' => 'nhivura',
 				'dz' => 'jãnga',
 				'dzg' => 'najaga',
 				'ebu' => 'ẽmu',
 				'ee' => 'eve',
 				'efi' => 'efike',
 				'egy' => 'ejimso arkajku',
 				'eka' => 'ekajuki',
 				'el' => 'gregu',
 				'elx' => 'eramĩte',
 				'en' => 'ĩnhgrej',
 				'enm' => 'ĩnhgrej kuju',
 				'eo' => 'enhperỹtu',
 				'es' => 'enhpỹjór',
 				'et' => 'enhtonĩjỹnũ',
 				'eu' => 'manhku',
 				'ewo' => 'evãnu',
 				'fa' => 'pérsa',
 				'fan' => 'fỹnge',
 				'fat' => 'fỹti',
 				'ff' => 'fura',
 				'fi' => 'fĩranẽj',
 				'fil' => 'firipĩnũ',
 				'fj' => 'fijỹnũ',
 				'fo' => 'fervej',
 				'fon' => 'fãm',
 				'fr' => 'frỹsej',
 				'frc' => 'frỹsej kajũn',
 				'frm' => 'frỹsej kuju',
 				'fro' => 'frỹsej arkajku',
 				'frr' => 'friso tỹ nãrti',
 				'frs' => 'frisỹ rãjur',
 				'fur' => 'frijurỹnũ',
 				'fy' => 'friso rãpur',
 				'ga' => 'irỹnej',
 				'gaa' => 'ga',
 				'gag' => 'gagavuj',
 				'gan' => 'gỹn',
 				'gay' => 'gajo',
 				'gba' => 'gemaja',
 				'gd' => 'gajériko enhkosej',
 				'gez' => 'gij',
 				'gil' => 'gimertej',
 				'gl' => 'garego',
 				'gmh' => 'arimỹv-téj kuju',
 				'gn' => 'góranĩ',
 				'goh' => 'arimỹv-téj arkajku',
 				'gon' => 'gãnni',
 				'gor' => 'gorãntar',
 				'got' => 'gótiko',
 				'grb' => 'gremo',
 				'grc' => 'gregu arkajku',
 				'gsw' => 'arimỹv (Suvisa)',
 				'gu' => 'gujerati',
 				'guz' => 'gusij',
 				'gv' => 'mỹnsi',
 				'gwi' => 'guvisĩn',
 				'ha' => 'havusa',
 				'hai' => 'hajna',
 				'hak' => 'haka',
 				'haw' => 'havajỹnũ',
 				'he' => 'emrajko',
 				'hi' => 'hĩni',
 				'hil' => 'hirigajnãn',
 				'hit' => 'hitita',
 				'hmn' => 'hymãg',
 				'ho' => 'hiri motu',
 				'hr' => 'krovata',
 				'hsb' => 'soramiv téj',
 				'hsn' => 'sijỹg',
 				'ht' => 'hajtijỹnũ',
 				'hu' => 'ũgaru',
 				'hup' => 'hupa',
 				'hy' => 'armẽnĩju',
 				'hz' => 'herero',
 				'ia' => 'vĩ-jãgja',
 				'iba' => 'iman',
 				'ibb' => 'imimijo',
 				'id' => 'ĩnonẽsijo',
 				'ie' => 'vĩ-ag kuju ki',
 				'ig' => 'igmo',
 				'ii' => 'sisuvỹ ji',
 				'ik' => 'ĩnũpijake',
 				'ilo' => 'irukỹnũ',
 				'inh' => 'ĩnguse',
 				'io' => 'ino',
 				'is' => 'kukryr',
 				'it' => 'itarijỹnũ',
 				'iu' => 'inugtituti',
 				'ja' => 'japonẽj',
 				'jbo' => 'rojmán',
 				'jgo' => 'gẽma',
 				'jmc' => 'mỹsame',
 				'jpr' => 'junajko-pérsa',
 				'jrb' => 'junajko-aramiko',
 				'jv' => 'javanẽj',
 				'ka' => 'jiórjijỹnũ',
 				'kaa' => 'kara-karkag',
 				'kab' => 'kamyre',
 				'kac' => 'kasĩn',
 				'kaj' => 'ju',
 				'kam' => 'kỹma',
 				'kaw' => 'kavi',
 				'kbd' => 'kamarnhijỹnũ',
 				'kbl' => 'kanẽnmu',
 				'kcg' => 'tyjam',
 				'kde' => 'mỹkãne',
 				'kea' => 'pu-tánh-vĩ',
 				'kfo' => 'koro',
 				'kg' => 'kãgorej',
 				'kgp' => 'kanhgág',
 				'kha' => 'kasi',
 				'kho' => 'kotanẽj',
 				'khq' => 'kujra sĩnĩ',
 				'ki' => 'kikuju',
 				'kj' => 'kuvanhỹmỹ',
 				'kk' => 'kajake',
 				'kkj' => 'kako',
 				'kl' => 'grohẽrỹnej',
 				'kln' => 'karẽnjĩn',
 				'km' => 'kymẽr',
 				'kmb' => 'kĩmuno',
 				'kn' => 'kanỹrim',
 				'ko' => 'korejỹnũ',
 				'koi' => 'komĩ-permyjag',
 				'kok' => 'kãkani',
 				'kos' => 'kosirajỹn',
 				'kpe' => 'kepere',
 				'kr' => 'kanũri',
 				'krc' => 'karasaj-markar',
 				'krl' => 'karérijo',
 				'kru' => 'kurug',
 				'ks' => 'kasemĩra',
 				'ksb' => 'sỹmara',
 				'ksf' => 'mafija',
 				'ksh' => 'kárysi',
 				'ku' => 'kurno',
 				'kum' => 'kumyg',
 				'kut' => 'kutenaj',
 				'kv' => 'komĩ',
 				'kw' => 'kórnĩko',
 				'ky' => 'kirginh',
 				'la' => 'ratĩnh',
 				'lad' => 'raninũ',
 				'lag' => 'rỹngi',
 				'lah' => 'rahina',
 				'lam' => 'rỹma',
 				'lb' => 'rusẽmurgej',
 				'lez' => 'resgi',
 				'lg' => 'rugỹna',
 				'li' => 'rĩmurgej',
 				'lkt' => 'rakóta',
 				'ln' => 'rĩgara',
 				'lo' => 'raosijỹnũ',
 				'lol' => 'mãgo',
 				'lou' => 'rovusijỹnỹ tá ke pẽ',
 				'loz' => 'roji',
 				'lrc' => 'ruri nãrti',
 				'lt' => 'rituvỹnũ',
 				'lu' => 'ruma-katỹga',
 				'lua' => 'ruma-ruruva',
 				'lui' => 'rujsẽnũ',
 				'lun' => 'rũna',
 				'luo' => 'ruvo',
 				'lus' => 'rusaj',
 				'luy' => 'ruja',
 				'lv' => 'retỹv',
 				'mad' => 'mỹnurej',
 				'maf' => 'mafa',
 				'mag' => 'mỹgahi',
 				'mai' => 'mỹjtiri',
 				'mak' => 'mỹkasar',
 				'man' => 'mỹnhĩga',
 				'mas' => 'mỹsaj',
 				'mde' => 'mama',
 				'mdf' => 'mogsa',
 				'mdr' => 'mỹnar',
 				'men' => 'mẽne',
 				'mer' => 'mẽru',
 				'mfe' => 'mãrisijẽn',
 				'mg' => 'mỹrgase',
 				'mga' => 'irỹnej kuju',
 				'mgh' => 'mỹkuva',
 				'mgo' => 'mẽta',
 				'mh' => 'mỹrsarej',
 				'mi' => 'mỹvóri',
 				'mic' => 'mĩkemỹke',
 				'min' => 'mĩnỹgkamavu',
 				'mk' => 'mỹsenojũ',
 				'ml' => 'mỹrajara',
 				'mn' => 'mãgór',
 				'mnc' => 'mỹsu',
 				'mni' => 'mỹnĩpuri',
 				'moh' => 'mãjkỹnũ',
 				'mos' => 'mosi',
 				'mr' => 'marati',
 				'ms' => 'mỹrajo',
 				'mt' => 'mỹrtej',
 				'mua' => 'mũnág',
 				'mul' => 'vẽnhvĩ’e',
 				'mus' => 'krig',
 				'mwl' => 'mĩrỹnej',
 				'mwr' => 'mỹrvari',
 				'my' => 'mirmỹnẽj',
 				'mye' => 'myene',
 				'myv' => 'érsija',
 				'mzn' => 'mỹsánarỹni',
 				'na' => 'nỹvuruvánũ',
 				'nan' => 'mĩn nỹn',
 				'nap' => 'nỹporitỹnũ',
 				'naq' => 'nỹmỹ',
 				'nb' => 'mógmỹr nãrovegej',
 				'nd' => 'nemere nãrti',
 				'nds' => 'arimỹv rur',
 				'nds_NL' => 'sagsỹv rur',
 				'ne' => 'nẽparej',
 				'new' => 'nẽvari',
 				'ng' => 'nogã',
 				'nia' => 'nĩja',
 				'niu' => 'nivuvejỹnũ',
 				'nl' => 'orỹnej',
 				'nl_BE' => 'framẽgo',
 				'nmg' => 'kivasijo',
 				'nn' => 'nĩnãrsig nãrovegej',
 				'nnh' => 'gijẽmun',
 				'no' => 'nãrovegej',
 				'nog' => 'nãgaj',
 				'non' => 'nãrniko arkajku',
 				'nqo' => 'nyko',
 				'nr' => 'nemere sur',
 				'nso' => 'soto nãrti',
 				'nus' => 'nũver',
 				'nv' => 'nỹvaho',
 				'nwc' => 'nẽvari há tỹvĩ',
 				'ny' => 'nĩjỹnja',
 				'nym' => 'nyjỹm-vesi',
 				'nyn' => 'nyjỹmkore',
 				'nyo' => 'nyjor',
 				'nzi' => 'nĩsimỹ',
 				'oc' => 'ogsitỹnũ',
 				'oj' => 'ojimva',
 				'om' => 'orãmũ',
 				'or' => 'orija',
 				'os' => 'oseto',
 				'osa' => 'osage',
 				'ota' => 'turko otomỹnũ',
 				'pa' => 'pỹjami',
 				'pag' => 'pangasinỹ',
 				'pal' => 'paravi',
 				'pam' => 'pampỹga',
 				'pap' => 'papijamẽto',
 				'pau' => 'paravỹnũ',
 				'pcm' => 'pingĩn nĩjerijỹnũ',
 				'peo' => 'pérsa arkajku',
 				'phn' => 'fenĩso',
 				'pi' => 'pari',
 				'pl' => 'poronẽj',
 				'pon' => 'pãnhpejỹnũ',
 				'prg' => 'prusijỹnũ',
 				'pro' => 'provẽsar arkajku',
 				'ps' => 'pasito',
 				'ps@alt=variant' => 'pusito',
 				'pt' => 'fóg-vĩ',
 				'qu' => 'kinsuva',
 				'quc' => 'kisé',
 				'raj' => 'hajanhtỹnĩ',
 				'rap' => 'hapanũj',
 				'rar' => 'harotãganũ',
 				'rm' => 'homỹse',
 				'rn' => 'hũni',
 				'ro' => 'homẽnũ',
 				'ro_MD' => 'mãrnavijo',
 				'rof' => 'hãmo',
 				'rom' => 'homỹnĩ',
 				'root' => 'haji',
 				'ru' => 'huso',
 				'rup' => 'aromẽnũ',
 				'rw' => 'kinĩjarvỹna',
 				'rwk' => 'hywa',
 				'sa' => 'sỹnhkrito',
 				'sad' => 'sỹnave',
 				'sah' => 'saka',
 				'sam' => 'aramỹjko samaritỹnũ',
 				'saq' => 'sỹmuru',
 				'sas' => 'sasag',
 				'sat' => 'sỹtari',
 				'sba' => 'gỹmaji',
 				'sbp' => 'sỹgu',
 				'sc' => 'sarno',
 				'scn' => 'sisirijỹnũ',
 				'sco' => 'isikoti',
 				'sd' => 'sĩni',
 				'sdh' => 'kurno sur',
 				'se' => 'samĩ nãrti',
 				'see' => 'senẽka',
 				'seh' => 'senỹ',
 				'sel' => 'serkum',
 				'ses' => 'kojyramoro senĩ',
 				'sg' => 'sỹgo',
 				'sga' => 'irỹnej arkajku',
 				'sh' => 'servo-krovata',
 				'shi' => 'tasehiti',
 				'shn' => 'sỹn',
 				'shu' => 'arame sanijỹnũ',
 				'si' => 'sĩgarej',
 				'sid' => 'sinamũ',
 				'sk' => 'erovako',
 				'sl' => 'erovenũ',
 				'sm' => 'samovỹnũ',
 				'sma' => 'samĩ sur',
 				'smj' => 'samĩ Rure tá',
 				'smn' => 'samĩ Inari tá',
 				'sms' => 'samĩ Isikórti tá',
 				'sn' => 'sãnỹ',
 				'snk' => 'sãnĩke',
 				'so' => 'somỹri',
 				'sog' => 'sognijỹnũ',
 				'sq' => 'armánẽj',
 				'sr' => 'sérvijo',
 				'srn' => 'surinỹmẽj',
 				'srr' => 'serere',
 				'ss' => 'suvaji',
 				'ssy' => 'saho',
 				'st' => 'soto sur',
 				'su' => 'sunanẽj',
 				'suk' => 'sukumỹ',
 				'sus' => 'susu',
 				'sux' => 'sumẽrijo',
 				'sv' => 'suvéko',
 				'sw' => 'suvahiri',
 				'sw_CD' => 'suvahiri Kãgo tá',
 				'swb' => 'komorijỹnũ',
 				'syc' => 'sirijako há tỹvĩ',
 				'syr' => 'sirijako',
 				'ta' => 'támĩr',
 				'te' => 'térugo',
 				'tem' => 'timnẽ',
 				'teo' => 'teso',
 				'ter' => 'terẽnũ',
 				'tet' => 'tétũm',
 				'tg' => 'tanhike',
 				'th' => 'tajrỹnej',
 				'ti' => 'tigrinĩja',
 				'tig' => 'tigré',
 				'tiv' => 'tivi',
 				'tk' => 'turkomẽnũ',
 				'tkl' => 'tokeravánũ',
 				'tl' => 'tagaro',
 				'tlh' => 'krĩngãg',
 				'tli' => 'tiringite',
 				'tmh' => 'tamỹséke',
 				'tn' => 'tisuvanỹ',
 				'to' => 'tãnganẽj',
 				'tog' => 'tãnganẽj Nyjasa tá',
 				'tpi' => 'tóg-pisĩn',
 				'tr' => 'turko',
 				'trv' => 'taroko',
 				'ts' => 'tesãga',
 				'tsi' => 'simsijỹnũ',
 				'tt' => 'tartaru',
 				'tum' => 'tũmuka',
 				'tvl' => 'tuvaruvỹnũ',
 				'tw' => 'tuvi',
 				'twq' => 'tasavag',
 				'ty' => 'tajtijỹnũ',
 				'tyv' => 'tuvinijỹnũ',
 				'tzm' => 'tamỹjirte Atara Kuju tá',
 				'udm' => 'unmũrte',
 				'ug' => 'ujgur',
 				'uga' => 'ugaritiko',
 				'uk' => 'ukranĩjỹnũ',
 				'umb' => 'ũmunu',
 				'und' => 'vẽnhvĩ ki kagtĩg',
 				'ur' => 'urnu',
 				'uz' => 'unhmeke',
 				'vai' => 'vaj',
 				've' => 'vẽna',
 				'vi' => 'vijétinỹmũ',
 				'vo' => 'vorapuke',
 				'vot' => 'vótiko',
 				'vun' => 'vũjo',
 				'wa' => 'varỹv',
 				'wae' => 'varser',
 				'wal' => 'vorajta',
 				'war' => 'varaj',
 				'was' => 'vaso',
 				'wbp' => 'varpiri',
 				'wo' => 'vorofe',
 				'wuu' => 'vu',
 				'xal' => 'karmĩg',
 				'xh' => 'sosa',
 				'xog' => 'rusoga',
 				'yao' => 'javo',
 				'yap' => 'japese',
 				'yav' => 'jỹgmen',
 				'ybb' => 'jẽma',
 				'yi' => 'jinhise',
 				'yo' => 'joruma',
 				'yrl' => 'nhẽgatu',
 				'yue' => 'kỹtonẽj',
 				'yue@alt=menu' => 'kỹtonẽj (pẽ)',
 				'za' => 'juvỹg',
 				'zap' => 'japoteko',
 				'zbl' => 'sĩmoru mrij',
 				'zen' => 'senỹga',
 				'zgh' => 'tamỹjirte mỹhókinũ pã',
 				'zh' => 'sĩnẽj',
 				'zh@alt=menu' => 'sĩnẽj mỹnarĩj',
 				'zh_Hans' => 'sĩnẽj mẽ',
 				'zh_Hans@alt=long' => 'sĩnẽj mỹnarĩj (mẽ)',
 				'zh_Hant' => 'sĩnẽj pẽ',
 				'zh_Hant@alt=long' => 'sĩnẽj mỹnarĩj (pẽ)',
 				'zu' => 'suru',
 				'zun' => 'sunhi',
 				'zxx' => 'nén ũ vẽnhvĩ ki tũ',
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
			'Arab' => 'arame',
 			'Arab@alt=variant' => 'pérso-arame',
 			'Armi' => 'armĩ',
 			'Armn' => 'armẽnjo',
 			'Avst' => 'avénhko',
 			'Bali' => 'marinẽj',
 			'Bamu' => 'mamũm',
 			'Batk' => 'mataki',
 			'Beng' => 'megari',
 			'Blis' => 'sĩmuru mrij',
 			'Bopo' => 'mopomãfo',
 			'Brah' => 'mramĩ',
 			'Brai' => 'mrajiri',
 			'Bugi' => 'mugnẽj',
 			'Buhd' => 'muhin',
 			'Cakm' => 'kagme',
 			'Cans' => 'sirama-vẽnhrá pir kanỹna tá kanhgág',
 			'Cari' => 'karijỹnũ',
 			'Cham' => 'sỹm',
 			'Cher' => 'seroki',
 			'Cirt' => 'sirti',
 			'Copt' => 'kómtiko',
 			'Cprt' => 'siprijota',
 			'Cyrl' => 'siririko',
 			'Cyrs' => 'siririko esiravo ekresijatiko',
 			'Deva' => 'nevanỹgari',
 			'Dsrt' => 'nesereti',
 			'Egyd' => 'nemãtiko ejimso',
 			'Egyh' => 'jeratiko ejimso',
 			'Egyp' => 'jerógrifo ejimso',
 			'Ethi' => 'etijópiko',
 			'Geok' => 'kehunsuri geórgijỹnũ',
 			'Geor' => 'geórgijỹnũ',
 			'Glag' => 'gragoritiko',
 			'Goth' => 'gótiko',
 			'Grek' => 'gregu',
 			'Gujr' => 'guserate',
 			'Guru' => 'gurmũki',
 			'Hanb' => 'hỹnme',
 			'Hang' => 'hỹngur',
 			'Hani' => 'hỹn',
 			'Hano' => 'hỹnũnũ',
 			'Hans' => 'sĩpri-há',
 			'Hans@alt=stand-alone' => 'hỹn sĩpri-há',
 			'Hant' => 'si-pẽ',
 			'Hant@alt=stand-alone' => 'hỹn si-pẽ',
 			'Hebr' => 'hemraiko',
 			'Hira' => 'hiragỹnỹ',
 			'Hmng' => 'pahav homãg',
 			'Hrkt' => 'sirama-vẽnhrá japunẽj',
 			'Hung' => 'hũgaru si',
 			'Inds' => 'ĩnu',
 			'Ital' => 'itariko si',
 			'Jamo' => 'jỹmo',
 			'Java' => 'javanẽj',
 			'Jpan' => 'japunẽj',
 			'Kali' => 'kaja-ri',
 			'Kana' => 'katakỹnỹ',
 			'Khar' => 'karositi',
 			'Khmr' => 'kymẽr',
 			'Knda' => 'kan-nỹna',
 			'Kore' => 'korejỹnũ',
 			'Kthi' => 'kanhi',
 			'Lana' => 'rỹnỹ',
 			'Laoo' => 'ra’o',
 			'Latf' => 'ratĩnh fragtur',
 			'Latg' => 'ratĩnh gajériko',
 			'Latn' => 'ratĩnh',
 			'Lepc' => 'rémsa',
 			'Limb' => 'rĩmu',
 			'Lina' => 'rĩnẽjar A',
 			'Linb' => 'rĩnẽjar B',
 			'Lisu' => 'risu',
 			'Lyci' => 'risijo',
 			'Lydi' => 'rinh-jo',
 			'Mand' => 'mỹnajku',
 			'Mani' => 'mỹnĩkejỹnũ',
 			'Maya' => 'hijerógrifu maja',
 			'Merc' => 'mẽrojitiku nĩgé-tỹ',
 			'Mero' => 'mẽrojitiku',
 			'Mlym' => 'marajara',
 			'Mong' => 'mãgór',
 			'Moon' => 'mũn',
 			'Mtei' => 'mẽjtej mỹjéki',
 			'Mymr' => 'mirmỹnẽj',
 			'Nkoo' => 'nyko',
 			'Ogam' => 'ogỹmiku',
 			'Olck' => 'or siki',
 			'Orkh' => 'orkihãn',
 			'Orya' => 'orija',
 			'Osma' => 'ojmỹnja',
 			'Perm' => 'pérmĩku si',
 			'Phag' => 'fagpa',
 			'Phli' => 'pahir',
 			'Phlp' => 'pahin',
 			'Phlv' => 'pahiravi si',
 			'Phnx' => 'fenĩso',
 			'Plrd' => 'fonẽtiko porarne',
 			'Prti' => 'priti',
 			'Rjng' => 'rejỹg',
 			'Roro' => 'rãgorãgo',
 			'Runr' => 'runĩku',
 			'Samr' => 'samỹritỹnũ',
 			'Sara' => 'sarati',
 			'Saur' => 'savurajtera',
 			'Sgnw' => 'vẽnh-mu vẽnhrád',
 			'Shaw' => 'savijỹnũ',
 			'Sinh' => 'sĩgarẽj',
 			'Sund' => 'sũnanẽj',
 			'Sylo' => 'syroti nỹgri',
 			'Syrc' => 'sirijaku',
 			'Syre' => 'sirijaku esitarageru',
 			'Syrj' => 'sirijaku rãpur',
 			'Syrn' => 'sirijaku rãjur',
 			'Tagb' => 'tagmánva',
 			'Tale' => 'taj-re',
 			'Talu' => 'taj-re tãg',
 			'Taml' => 'tỹmĩr',
 			'Tavt' => 'tavuti',
 			'Telu' => 'térugu',
 			'Teng' => 'tẽgvar',
 			'Tfng' => 'tifinỹg',
 			'Tglg' => 'tagaru',
 			'Thaa' => 'ta’anỹ',
 			'Thai' => 'tajrỹnej',
 			'Tibt' => 'timetỹnũ',
 			'Ugar' => 'ugaritiku',
 			'Vaii' => 'vaj',
 			'Visp' => 'vĩ-ve-há',
 			'Xpeo' => 'pérsa si',
 			'Xsux' => 'sumẽrijo-akanhỹnũ kafén ja',
 			'Yiii' => 'yji',
 			'Zinh' => 'ernanu',
 			'Zmth' => 'vẽnhnĩkrén rá',
 			'Zsye' => 'Emãji',
 			'Zsym' => 'zsym',
 			'Zxxx' => 'vẽnhrá-tũ',
 			'Zyyy' => 'kãmũ',
 			'Zzzz' => 'vẽnhrá ki kagtĩg',

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
			'001' => 'Tã mĩ ke kar',
 			'002' => 'Afrika',
 			'003' => 'Nãrti-Amẽrika',
 			'005' => 'Sur-Amẽrika',
 			'009' => 'Oseanĩja',
 			'011' => 'Afrika Rãpur',
 			'013' => 'Amẽrika-Kuju',
 			'014' => 'Afrika Rãjur',
 			'015' => 'Nãrti-Afrika',
 			'017' => 'Afrika-Kuju',
 			'018' => 'Afrika Mẽrinhonỹr',
 			'019' => 'Amẽrika ag',
 			'021' => 'Amẽrika Setẽntrionỹr',
 			'029' => 'Karime',
 			'030' => 'Ajia Rãjur',
 			'034' => 'Ajia Mẽrinhonỹr',
 			'035' => 'Ajia Sur-Rãjur',
 			'039' => 'Orópa Mẽrinhonỹr',
 			'053' => 'Ausitrarajia',
 			'054' => 'Mẽranẽjia',
 			'057' => 'Mĩkronẽjia Pénĩn',
 			'061' => 'Porinẽjia',
 			'142' => 'Ajia',
 			'143' => 'Ajia-Kuju',
 			'145' => 'Ajia-Rãpur',
 			'150' => 'Orópa',
 			'151' => 'Orópa-Rãjur',
 			'154' => 'Orópa Setẽntrionỹr',
 			'155' => 'Orópa Rãpur',
 			'202' => 'Afrika Sahara-Jẽgu',
 			'419' => 'Amẽrika Ratinỹ',
 			'AC' => 'Asẽnsỹv Goj-vẽso',
 			'AD' => 'Ỹnora',
 			'AE' => 'Emĩrano Arame Unĩno',
 			'AF' => 'Afeganĩtã',
 			'AG' => 'Ỹntiguva kar Marmuna',
 			'AI' => 'Ỹngira',
 			'AL' => 'Armánĩja',
 			'AM' => 'Armẽnĩja',
 			'AO' => 'Ỹgóra',
 			'AQ' => 'Ỹntartina',
 			'AR' => 'Arjẽtinỹ',
 			'AS' => 'Samãva Amẽrikynỹ',
 			'AT' => 'Agtirija',
 			'AU' => 'Avotyraria',
 			'AW' => 'Aruma',
 			'AX' => 'Gojga Goj-vẽso',
 			'AZ' => 'Ajermajjáv',
 			'BA' => 'Mósinĩja',
 			'BB' => 'Juvã-mág',
 			'BD' => 'Mágranési',
 			'BE' => 'Mérjika',
 			'BF' => 'Murkinỹ Faso',
 			'BG' => 'Murgarjia',
 			'BH' => 'Marẽj',
 			'BI' => 'Murũni',
 			'BJ' => 'Menĩnh',
 			'BL' => 'Sỹ Martoromeu',
 			'BM' => 'Mermũna',
 			'BN' => 'Mrunẽj',
 			'BO' => 'Morivija',
 			'BQ' => 'Pajisi Rur Karimejã',
 			'BR' => 'Mrasir',
 			'BS' => 'Mahámỹ',
 			'BT' => 'Mutỹv',
 			'BV' => 'Muve Goj-vẽso',
 			'BW' => 'Monsuvỹnỹ',
 			'BY' => 'Miero-Husija',
 			'BZ' => 'Merije',
 			'CA' => 'Kanỹna',
 			'CC' => 'Kokonh Goj-vẽso (Killing)',
 			'CD' => 'Kãgo - Kĩsaja',
 			'CD@alt=variant' => 'Kãgo Repumrika Nemokratika',
 			'CF' => 'Afrikanỹ-kuju Repumrika',
 			'CG' => 'Kãgo Repumrika',
 			'CG@alt=variant' => 'Kãgo',
 			'CH' => 'Suvisa',
 			'CI' => 'Jãn-mág-kupri Fyr',
 			'CI@alt=variant' => 'Kote Nhivuva',
 			'CK' => 'Kuki Goj-vẽso',
 			'CL' => 'Sire',
 			'CM' => 'Kamỹrãj',
 			'CN' => 'Sĩnỹ',
 			'CO' => 'Korãmija',
 			'CP' => 'Kripertãn Goj-vẽso',
 			'CR' => 'Konhta Rika',
 			'CU' => 'Kuma',
 			'CV' => 'Pu Tánh',
 			'CW' => 'Kurasavo',
 			'CX' => 'Krĩtimỹnh Goj-vẽso',
 			'CY' => 'Sipre',
 			'CZ' => 'Sékija',
 			'CZ@alt=variant' => 'Repumrika Séka',
 			'DE' => 'Aremỹija',
 			'DG' => 'Niego Garsija',
 			'DJ' => 'Nhimuti',
 			'DK' => 'Ninỹmỹrka',
 			'DM' => 'Nomĩnĩka',
 			'DO' => 'Repumrika Nomĩnĩkỹnỹ',
 			'DZ' => 'Arjérija',
 			'EA' => 'Sevuta kar Mẽrira',
 			'EC' => 'Ekuvanor',
 			'EE' => 'Enhtonĩja',
 			'EG' => 'Ejito',
 			'EH' => 'Sahara Rãpur',
 			'ER' => 'Erytiréja',
 			'ES' => 'Enhpỹnija',
 			'ET' => 'Etiópija',
 			'EU' => 'Unĩjáv Oropéja',
 			'EZ' => 'Evoro Ga',
 			'FI' => 'Fĩrỹnija',
 			'FJ' => 'Fiji',
 			'FK' => 'Mỹrvĩnỹ Goj-vẽso',
 			'FK@alt=variant' => 'Mỹrvĩnỹ Goj-vẽso (Farkrỹn)',
 			'FM' => 'Goj-vẽso-sĩ Kẽsir',
 			'FO' => 'Faróve Goj-vẽso',
 			'FR' => 'Frỹsa',
 			'GA' => 'Gabã',
 			'GB' => 'Rejnũ Unĩnu',
 			'GD' => 'Granỹna',
 			'GE' => 'Jiórja',
 			'GF' => 'Frỹsa Gijanỹ',
 			'GG' => 'Gérnesej',
 			'GH' => 'Ganỹ',
 			'GI' => 'Gimrar-tar',
 			'GL' => 'Groẽrỹnija',
 			'GM' => 'Gỹmija',
 			'GN' => 'Ginẽ',
 			'GP' => 'Guvanarupe',
 			'GQ' => 'Ginẽ Ekuvatoriar',
 			'GR' => 'Grésa',
 			'GS' => 'Jiórja-Sur kar Sỹnvisi-Sur Goj-vẽso Ag',
 			'GT' => 'Guvatimỹra',
 			'GU' => 'Guvỹm',
 			'GW' => 'Ginẽ-Misav',
 			'GY' => 'Gijỹnỹ',
 			'HK' => 'Hãg Kãg, Sinỹ ERA',
 			'HK@alt=short' => 'Hãg Kãg',
 			'HM' => 'Hárni kar Magtonarni Goj-vẽso Ag',
 			'HN' => 'Hãnura',
 			'HR' => 'Kroasa',
 			'HT' => 'Ajti',
 			'HU' => 'Ũgrija',
 			'IC' => 'Kanỹrija Goj-vẽso',
 			'ID' => 'Ĩnonẽja',
 			'IE' => 'Irỹna',
 			'IL' => 'Isihaé',
 			'IM' => 'Mỹn Goj-vẽso',
 			'IN' => 'Ĩnija',
 			'IO' => 'Osiỹno Ĩniko tỹ Tehitórijo Mritỹnĩku',
 			'IQ' => 'Iraki',
 			'IR' => 'Irỹ',
 			'IS' => 'Inhrỹnija',
 			'IT' => 'Itarija',
 			'JE' => 'Jérsej',
 			'JM' => 'Jamỹjka',
 			'JO' => 'Jornánĩja',
 			'JP' => 'Japã',
 			'KE' => 'Kenĩja',
 			'KG' => 'Kirginhtỹv',
 			'KH' => 'Kỹmója',
 			'KI' => 'Kirimati',
 			'KM' => 'Komãre',
 			'KN' => 'Sỹ Krinhtóvỹv kar Nẽvinh',
 			'KP' => 'Nãrti-Koréja',
 			'KR' => 'Sur-Koréja',
 			'KW' => 'Kuvajti',
 			'KY' => 'Kajmỹm Goj-vẽso',
 			'KZ' => 'Kajakinhtỹv',
 			'LA' => 'Raosi',
 			'LB' => 'Rimanã',
 			'LC' => 'Sỹta Rusija',
 			'LI' => 'Rinhsiténh-tajin',
 			'LK' => 'Siri Rỹnka',
 			'LR' => 'Rimérija',
 			'LS' => 'Resotu',
 			'LT' => 'Rituỹnĩja',
 			'LU' => 'Rusẽmurgu',
 			'LV' => 'Retãnĩja',
 			'LY' => 'Rimija',
 			'MA' => 'Mỹhókonh',
 			'MC' => 'Mãnỹko',
 			'MD' => 'Mãrnova',
 			'ME' => 'Krĩsá',
 			'MF' => 'Sỹ Mỹrtĩjũ',
 			'MG' => 'Mỹnaganhtar',
 			'MH' => 'MỹrSar Goj-vẽso',
 			'MK' => 'Nãrti-Mỹsenonĩja',
 			'ML' => 'Mỹri',
 			'MM' => 'Mĩjỹmỹr',
 			'MN' => 'Mãngórija',
 			'MO' => 'Mỹkav, Sĩnỹ ERA',
 			'MO@alt=short' => 'Mỹkav',
 			'MP' => 'Nãrti-Mỹrijỹnỹ Goj-vẽso',
 			'MQ' => 'Mỹrtinĩka',
 			'MR' => 'Mãritỹnĩja',
 			'MS' => 'Mãtisehati',
 			'MT' => 'Mỹrta',
 			'MU' => 'Mãriso',
 			'MV' => 'Mỹrniva',
 			'MW' => 'Mỹravi',
 			'MX' => 'Mẽsiku',
 			'MY' => 'Mỹraja',
 			'MZ' => 'Mãsỹmiki',
 			'NA' => 'Nỹmĩmija',
 			'NC' => 'Karenonĩja Tãg',
 			'NE' => 'Nĩjer',
 			'NF' => 'Nãrforki Goj-vẽso',
 			'NG' => 'Nĩjérija',
 			'NI' => 'Nĩkaragva',
 			'NL' => 'Pajisi Rur',
 			'NO' => 'Nãrovéga',
 			'NP' => 'Nẽpar',
 			'NR' => 'Nỹuru',
 			'NU' => 'Nĩvue',
 			'NZ' => 'Jerỹnija Tãg',
 			'OM' => 'Omỹ',
 			'PA' => 'Panỹmỹ',
 			'PE' => 'Piru',
 			'PF' => 'Frỹsa Porinẽja',
 			'PG' => 'Papuva-Ginẽ Tãg',
 			'PH' => 'Firipinỹ',
 			'PK' => 'Pakinhtỹv',
 			'PL' => 'Porãnija',
 			'PM' => 'Sỹ Penru kar Mĩkerỹv',
 			'PN' => 'Pinkajir Goj-vẽso',
 			'PR' => 'Portu Hiku',
 			'PS' => 'Tehitórijo Parenhtinũ',
 			'PS@alt=short' => 'Parenhtinỹ',
 			'PT' => 'Portugar',
 			'PW' => 'Paravu',
 			'PY' => 'Paraguvaj',
 			'QA' => 'Katar',
 			'QO' => 'Osiỹnĩja Kuvar-gy',
 			'RE' => 'Hujáv',
 			'RO' => 'Homẽnĩja',
 			'RS' => 'Sérvija',
 			'RU' => 'Husija',
 			'RW' => 'Huỹna',
 			'SA' => 'Aramija Savnita',
 			'SB' => 'Saromỹv Goj-vẽso',
 			'SC' => 'Sejserenh',
 			'SD' => 'Suná',
 			'SE' => 'Suésa',
 			'SG' => 'Sĩgapura',
 			'SH' => 'Sỹnta Erenỹ',
 			'SI' => 'Enhrovenĩja',
 			'SJ' => 'Inhvarmarni kar Jan Mỹjẽn',
 			'SK' => 'Enhrovakija',
 			'SL' => 'Krĩ Mĩgkusũg-fi',
 			'SM' => 'Sỹ Mỹrĩnũ',
 			'SN' => 'Senẽgar',
 			'SO' => 'Somỹrija',
 			'SR' => 'Surinỹmĩ',
 			'SS' => 'Sur-Sunáv',
 			'ST' => 'Sỹ Tomẽ kar Prĩsipi',
 			'SV' => 'Er Sarvanor',
 			'SX' => 'Sĩti Mỹ’artẽn',
 			'SY' => 'Sirija',
 			'SZ' => 'Esuatinĩ',
 			'SZ@alt=variant' => 'Suvasi-Ga',
 			'TA' => 'Trinhtỹv Nakũja',
 			'TC' => 'Turka kar Kajko Goj-vẽso Ag',
 			'TD' => 'Sane',
 			'TF' => 'Sur Frỹsa Tehitórijo',
 			'TG' => 'Togo',
 			'TH' => 'Taj-Ga',
 			'TJ' => 'Tanijikinhtỹv',
 			'TK' => 'Tokeravu',
 			'TL' => 'Timãr-Rãjur',
 			'TL@alt=variant' => 'Timãr-Rãjur Repumrika Nemãkratika',
 			'TM' => 'Turkomẽnĩnhtỹv',
 			'TN' => 'Tunĩja',
 			'TO' => 'Tãga',
 			'TR' => 'Turkija',
 			'TT' => 'Trĩnane kar Tomagu',
 			'TV' => 'Tuvaru',
 			'TW' => 'Tajuvỹ',
 			'TZ' => 'Tỹnjỹnĩja',
 			'UA' => 'Ukrỹnĩja',
 			'UG' => 'Ugỹna',
 			'UM' => 'EUA Goj-vẽso Kãsir',
 			'UN' => 'Nỹsãn Unĩna',
 			'UN@alt=short' => 'ONU',
 			'US' => 'Enhtano Unĩno',
 			'US@alt=short' => 'EUA',
 			'UY' => 'Urugvaj',
 			'UZ' => 'Unhmekinhtỹv',
 			'VA' => 'Vatikỹnũ Emã-mág',
 			'VC' => 'Sỹ Visenti kar Granỹninỹ',
 			'VE' => 'Venẽjuvéra',
 			'VG' => 'Mritỹnĩja Goj-vẽso',
 			'VI' => 'Virjĩg Goj-vẽso tỹ Amẽrikỹnỹ',
 			'VN' => 'Vijétinỹ',
 			'VU' => 'Vanũvatu',
 			'WF' => 'Varinh kar Futunỹ',
 			'WS' => 'Samãva',
 			'XA' => 'Ón vĩ ag',
 			'XB' => 'Ón régre mĩ.',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemẽn',
 			'YT' => 'Mỹjóte',
 			'ZA' => 'Sur-Afrika',
 			'ZM' => 'Jỹmija',
 			'ZW' => 'Jĩmamuje',
 			'ZZ' => 'Reji’ỹv Veja tũ',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'arimỹv vẽnhrá si-pẽ',
 			'1994' => 'resijỹnỹ vẽnhrá hár-pẽ',
 			'1996' => 'prỹg tỹ 1996 kã vẽnhrá arimỹ',
 			'1606NICT' => '1606 kã frỹsej si',
 			'1694ACAD' => 'frỹsej tỹ uri',
 			'1959ACAD' => 'kanẽmĩku',
 			'ABL1943' => '1943 kã Fóg Vĩ Vẽnhrán Formũrariv jé hár',
 			'AO1990' => '1990 Fóg Vĩ vẽnhrá to Vẽnhkrén ja',
 			'AREVELA' => 'armẽnĩju rãjur',
 			'AREVMDA' => 'armẽnĩju rãpur',
 			'BAKU1926' => 'arfaméto turko ratinũ tỹ ũn pir',
 			'BISCAYAN' => 'misikajo',
 			'BISKE' => 'sỹn jórjo/ mira vĩ pẽ',
 			'BOONT' => 'mutrĩg - jamã vĩ pẽ',
 			'COLB1945' => 'Ruso-Mrasirera ki vẽnhrá to 1945 Vẽnhkrén ja',
 			'FONIPA' => 'Arfaméto Fonẽtiku Ĩnhternỹsonỹv to Fonẽtika',
 			'FONUPA' => 'Arfaméto Fonẽtiku Urariko',
 			'HEPBURN' => 'japonej vẽnhrá ratinũ to hépymur',
 			'HOGNORSK' => 'nãrovegej kynhmỹ',
 			'KKCOR' => 'vẽnhrá to ke vẽnhmỹ ke kar',
 			'LIPAW' => 'Resijỹn tỹ ripovasi vĩ pẽ',
 			'MONOTON' => 'kyr mág ve',
 			'NDYUKA' => 'nyjuka vĩ pẽ',
 			'NEDIS' => 'natisonẽ vĩ pẽ',
 			'NJIVA' => 'giva/niva vĩ pẽ',
 			'OSOJS' => 'osejako/osojỹnẽ vĩ pẽ',
 			'PAMAKA' => 'pamỹka vĩ pẽ',
 			'PINYIN' => 'Piny’in vẽnhrá ratinũ to',
 			'POLYTON' => 'ũ ag téj',
 			'POSIX' => 'kãputanor',
 			'REVISED' => 'vẽnhrá jãfĩ',
 			'ROZAJ' => 'resijỹnũ',
 			'SAAHO' => 'saho',
 			'SCOTLAND' => 'ĩnhgrej Enhkósija tá',
 			'SCOUSE' => 'enhkose vĩ pẽ',
 			'SOLBA' => 'setorvisa/ sormika vĩ pẽ',
 			'TARASK' => 'tarasikevika vẽnhrá-pẽ',
 			'UCCOR' => 'vẽnhrá to ke pir',
 			'UCRCOR' => 'vẽnhrá jẽnfĩn tỹ pir ke',
 			'VALENCIA' => 'varensijanũ',
 			'WADEGILE' => 'Wade-Giles vẽnhrá ratinũ to',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Kurã-kar',
 			'cf' => 'tỹ nĩkri ve',
 			'colalternate' => 'vẽnhrá gãgrá kuprãg já kãjatun ge',
 			'colbackwards' => 'rá-krivinja kãka to kajã kuprãg ra',
 			'colcasefirst' => 'jag nã nón vin vẽnhrá mág/kãsir',
 			'colcaselevel' => 'vẽnhrá kuprãg ta ũn-ũn ka ũn mág/ũn kãsir',
 			'collation' => 'jagnẽ nón fẽgfẽg há han',
 			'colnormalization' => 'kuprẽg hár',
 			'colnumeric' => 'vẽnh nĩkrer kuprãg ra',
 			'colstrength' => 'kuprãg ge juke pẽ',
 			'currency' => 'Jẽnkamu',
 			'hc' => 'Óra tĩg tỹ (12 vs. 24)',
 			'lb' => 'vẽfe mranh to ke',
 			'ms' => 'vẽnhkãmun to ke',
 			'numbers' => 'Vẽnh nĩkrer',
 			'timezone' => 'Óra tỹ’ũn',
 			'va' => 'vẽnhmỹ tá nĩnĩ ke',
 			'x' => 'Isa ĩn ta vóg ge',

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
 				'buddhist' => q{Munisita Prỹg-kurã-kar},
 				'chinese' => q{Sĩnẽj Prỹg-kurã-kar},
 				'coptic' => q{Komtike Prỹg-kurã-kar},
 				'dangi' => q{Nági Prỹg-kurã-kar},
 				'ethiopic' => q{Etijópi Prỹg-kurã-kar},
 				'ethiopic-amete-alem' => q{Amete Alem Etijópi Prỹg-kurã-kar},
 				'gregorian' => q{Papa Gregorju Prỹg-kurã-kar},
 				'hebrew' => q{Emrajko Prỹg-kurã-kar},
 				'indian' => q{Ĩnija Prỹg-kurã-kar pẽ},
 				'islamic' => q{Isirỹ Prỹg-kurã-kar},
 				'islamic-civil' => q{Isirỹ Prỹg-kurã-kar Siviv},
 				'islamic-umalqura' => q{Isirỹ Prỹg-kurã-kar (Umm al-Qura)},
 				'iso8601' => q{Prỹg-kurã-kar ISO-8601},
 				'japanese' => q{Japonẽj Prỹg-kurã-kar},
 				'persian' => q{Pérsa Prỹg-kurã-kar},
 				'roc' => q{Sĩnỹ Kar-mỹ Prỹg-kurã-kar},
 			},
 			'cf' => {
 				'account' => q{Kajẽm jé nĩkri hár},
 				'standard' => q{Nĩkri han ka nĩ pẽ},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Vẽnhrá kãgrár vin han},
 				'shifted' => q{Vẽnrá kãgrá kãjatun kỹ kuprẽg},
 			},
 			'colbackwards' => {
 				'no' => q{Jatun mỹ ti kri vir kuprãg},
 				'yes' => q{Kato kri vir kuprãg},
 			},
 			'colcasefirst' => {
 				'lower' => q{Vẽnhrá kẽsir to kuprẽg},
 				'no' => q{Jatun mỹ vẽnhrá mág mré ũn kẽsir kuprãg},
 				'upper' => q{Vẽnhrá mág to kuprãg},
 			},
 			'colcaselevel' => {
 				'no' => q{Vẽnhrá mág mré ũn kẽsir tỹ ũn’ũn mỹ kuprẽg},
 				'yes' => q{Vẽnhrá mág mré ũn kẽsir tỹ ũn’ũn kỹ kuprẽg},
 			},
 			'collation' => {
 				'big5han' => q{Sĩnẽj Vỹsa ke to ke pẽ - Big5},
 				'compat' => q{Ẽgno tá jẽnẽ já kỹ ta ki já},
 				'dictionary' => q{Vẽnhrá Nỹtĩj-fẽ nỹtĩ há},
 				'ducet' => q{Unicode to ke pẽ},
 				'eor' => q{Orópa tá vẽnhvin han to ke},
 				'gb2312han' => q{Sĩnẽj ke to ke (sĩmpri há) - GB2312},
 				'phonebook' => q{Terefonĩ Risita to ke},
 				'phonetic' => q{Fonẽtika to ke kuprãg},
 				'pinyin' => q{Pin-yin to nỹtĩ},
 				'reformed' => q{Hár tãg nỹtĩ},
 				'search' => q{Jẽnfĩn to ke Kar},
 				'searchjl' => q{Hangul kãsonỹte ve jãnfĩn},
 				'standard' => q{to ke pẽ},
 				'stroke' => q{Junhjoj to ke},
 				'traditional' => q{To ke nỹtĩ pẽ},
 				'unihan' => q{Ranikar-jonhjoj to nỹtĩ pẽ},
 			},
 			'colnormalization' => {
 				'no' => q{Ũn há to kuprãg ge tũ},
 				'yes' => q{Unicode ki han nĩ kuprãg},
 			},
 			'colnumeric' => {
 				'no' => q{Nĩkrén pipin kuprãg},
 				'yes' => q{Nĩkrén pipin hár},
 			},
 			'colstrength' => {
 				'identical' => q{Kuprãg kãn},
 				'primary' => q{Vẽnhrá tỹ jo nỹ hã to kuprẽg},
 				'quaternary' => q{Ti kri vir/vẽnhrá mág mré vẽnhrá kẽsir/tãpér/kana to kuprẽg},
 				'secondary' => q{Ti kri vir kuprẽg},
 				'tertiary' => q{Ti kri vir/vẽnhrá mág mré vẽnhrá kẽsir/tãpér to kuprẽg},
 			},
 			'd0' => {
 				'fwidth' => q{Tãpér kar},
 				'hwidth' => q{Tãpér kuju},
 				'npinyin' => q{Nĩkrer},
 			},
 			'hc' => {
 				'h11' => q{12 óra tuke (0–11)},
 				'h12' => q{12 óra tuke (1–12)},
 				'h23' => q{24 óra tuke (0–23)},
 				'h24' => q{24 óra tuke (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Vẽfe mranh han fã pã tovan ka},
 				'normal' => q{Vẽfe mranh han fã pẽ ki},
 				'strict' => q{Vẽfe mranh han fã rá ki},
 			},
 			'm0' => {
 				'bgn' => q{Vẽnhrá ũ ra tĩn BGN EUA (Vẽnhvĩ ũra tĩn)},
 				'ungegn' => q{Vẽnhrá ũ ra tĩn UN GEGN},
 			},
 			'ms' => {
 				'metric' => q{Kãmur to ke pẽ},
 				'uksystem' => q{Vẽnhkãmur ĩperijar ki},
 				'ussystem' => q{Amẽrikỹnũ vẽnhkãmur to hár},
 			},
 			'numbers' => {
 				'arab' => q{Ĩno-aramiko rá pipir},
 				'arabext' => q{Ĩno-aramiko kugjer rá pipir},
 				'armn' => q{Armẽnĩjo rá pipir},
 				'armnlow' => q{Armẽnĩjo rá pipir kẽsir},
 				'beng' => q{Meggari rá pipir},
 				'deva' => q{Nevanỹgari rá pipir},
 				'ethi' => q{Etijópijánũ rá pipir},
 				'finance' => q{Jãnkamu vin hár nĩkrer},
 				'fullwide' => q{ti téj kar rá pipir},
 				'geor' => q{Jejorjỹnũ rá pipir},
 				'grek' => q{Grego rá pipir},
 				'greklow' => q{Grego kẽsir rá pipir},
 				'gujr' => q{Guserate rá pipir},
 				'guru' => q{Gurmũrá pipir rá pipir},
 				'hanidec' => q{Sĩnẽj néj ki rá pipir},
 				'hans' => q{Sĩnẽj rá pipir sĩmpri há},
 				'hansfin' => q{Sĩnẽj rá pipir jẽnkamu sĩmpri há},
 				'hant' => q{Sĩnẽj rá pipir pẽ},
 				'hantfin' => q{Sĩnẽj rá pipir jẽnkamu pẽ},
 				'hebr' => q{Emrajko rá pipir},
 				'jpan' => q{Japonẽj rá pipir},
 				'jpanfin' => q{Japonẽj vin hár},
 				'khmr' => q{Khmẽr rá pipir},
 				'knda' => q{Kanỹrẽse rá pipir},
 				'laoo' => q{Ravosijỹnũ rá pipir},
 				'latn' => q{Rãpur rá pipir},
 				'mlym' => q{Marajaro rá pipir},
 				'mong' => q{Mãgór rá pipir},
 				'mymr' => q{Mỹjỹmỹr rá pipir},
 				'native' => q{Nĩkrer ũ vepã rá pipir},
 				'orya' => q{Orija rá pipir},
 				'roman' => q{Romỹnũ rá pipir},
 				'romanlow' => q{Romỹnũ rá kẽsir rá pipir},
 				'taml' => q{Tỹmĩr pẽ rá pipir},
 				'tamldec' => q{Tỹmĩr rá pipir},
 				'telu' => q{Terugo rá pipir},
 				'thai' => q{Tajrỹnej rá pipir},
 				'tibt' => q{Timetỹnũ rá pipir},
 				'traditional' => q{Nĩkrer pẽ},
 				'vaii' => q{Vaj nĩkrén pipir},
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
			'metric' => q{kãmur to ke},
 			'UK' => q{Rejnũ Jagmré-ke},
 			'US' => q{Enhtano Unĩno Jagmré-ke ag},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Vĩpẽ: {0}',
 			'script' => 'Arfaméto: {0}',
 			'region' => 'Kãtá: {0}',

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
			auxiliary => qr{[ª à ă â å ä ā æ b c ç d ᵉ è ĕ ê ë ē ᵍ ʰ í ì ĭ î ï ī l ⁿ ñ º ò ŏ ô ö õ ø ō œ q ú ù ŭ û ü ū w x ÿ z]},
			index => ['A', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'Y'],
			main => qr{[a á ã e é ẽ f g h i ĩ j k m n o ó p r s t u ũ v y ỹ]},
			numbers => qr{[\- ‑ , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ ‑ – — , ; \: ! ? . … ' ‘ ’ " “ ” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'Y'], };
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
					'' => {
						'name' => q(kãka ũ kãtá),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(kãka ũ kãtá),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(tar g),
						'one' => q(tar g {0}),
						'other' => q(tar g {0}),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(tar g),
						'one' => q(tar g {0}),
						'other' => q(tar g {0}),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(sigũnu pénogno ki mẽturo ag),
						'one' => q(sigũnu pénogno ki mẽturo {0}),
						'other' => q({0} mẽturo ag sigũnu pénogno ki),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(sigũnu pénogno ki mẽturo ag),
						'one' => q(sigũnu pénogno ki mẽturo {0}),
						'other' => q({0} mẽturo ag sigũnu pénogno ki),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(mĩnũtu tỹ nỹj ag),
						'one' => q({0} mĩnũtu tỹ nỹj),
						'other' => q({0} mĩnũtu tỹ nỹj),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(mĩnũtu tỹ nỹj ag),
						'one' => q({0} mĩnũtu tỹ nỹj),
						'other' => q({0} mĩnũtu tỹ nỹj),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(sigũnu tỹ nỹj ag),
						'one' => q({0} sigũnu tỹ nỹj),
						'other' => q({0} sigũnu tỹ nỹj),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(sigũnu tỹ nỹj ag),
						'one' => q({0} sigũnu tỹ nỹj),
						'other' => q({0} sigũnu tỹ nỹj),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(grav ag),
						'one' => q({0} grav),
						'other' => q({0} grav),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(grav ag),
						'one' => q({0} grav),
						'other' => q({0} grav),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radiano ag),
						'one' => q({0} radiano),
						'other' => q({0} radiano),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radiano ag),
						'one' => q({0} radiano),
						'other' => q({0} radiano),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(tĩn),
						'one' => q({0} tĩn),
						'other' => q({0} tĩn 'e),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(tĩn),
						'one' => q({0} tĩn),
						'other' => q({0} tĩn 'e),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(akre ag),
						'one' => q({0} akre),
						'other' => q({0} akre ag),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(akre ag),
						'one' => q({0} akre),
						'other' => q({0} akre ag),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunam ag),
						'other' => q(dunam {0}),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunam ag),
						'other' => q(dunam {0}),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hegtar ag),
						'one' => q({0} hegtar),
						'other' => q({0} hegtar),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hegtar ag),
						'one' => q({0} hegtar),
						'other' => q({0} hegtar),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(sẽntimẽturo pénogno ag),
						'one' => q({0} sẽntimẽturo pénogno),
						'other' => q({0} sẽntimẽturo pénogno ag),
						'per' => q({0} sẽntimẽturo pénogno ki),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(sẽntimẽturo pénogno ag),
						'one' => q({0} sẽntimẽturo pénogno),
						'other' => q({0} sẽntimẽturo pénogno ag),
						'per' => q({0} sẽntimẽturo pénogno ki),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(tipẽn pénogno ag),
						'one' => q({0} tipẽn pénogno),
						'other' => q({0} tipẽn pénogno ag),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(tipẽn pénogno ag),
						'one' => q({0} tipẽn pénogno),
						'other' => q({0} tipẽn pénogno ag),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(poregana pénogno ag),
						'one' => q({0} poregana pénogno),
						'other' => q({0} poregana pénogno ag),
						'per' => q({0} poregana pénogno ki),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(poregana pénogno ag),
						'one' => q({0} poregana pénogno),
						'other' => q({0} poregana pénogno ag),
						'per' => q({0} poregana pénogno ki),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kiromẽturo pénogno ag),
						'one' => q({0} kiromẽturo pénogno),
						'other' => q({0} kiromẽturo pénogno),
						'per' => q({0} kiromẽturo pénogno ki),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kiromẽturo pénogno ag),
						'one' => q({0} kiromẽturo pénogno),
						'other' => q({0} kiromẽturo pénogno),
						'per' => q({0} kiromẽturo pénogno ki),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(mẽturo pénogno ag),
						'one' => q({0} mẽturo pénogno),
						'other' => q({0} mẽturo pénogno ag),
						'per' => q({0} mẽturo pénogno ki),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(mẽturo pénogno ag),
						'one' => q({0} mẽturo pénogno),
						'other' => q({0} mẽturo pénogno ag),
						'per' => q({0} mẽturo pénogno ki),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(milha pénogno ag),
						'one' => q({0} milha pénogno),
						'other' => q({0} milha pénogno ag),
						'per' => q({0} milha pénogno ki),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(milha pénogno ag),
						'one' => q({0} milha pénogno),
						'other' => q({0} milha pénogno ag),
						'per' => q({0} milha pénogno ki),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(jarda pénogno ag),
						'one' => q({0} jarda pénogno),
						'other' => q({0} jarda pénogno ag),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(jarda pénogno ag),
						'one' => q({0} jarda pénogno),
						'other' => q({0} jarda pénogno ag),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(kirate ag),
						'one' => q({0} kirate),
						'other' => q({0} kirate ag),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(kirate ag),
						'one' => q({0} kirate),
						'other' => q({0} kirate ag),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mĩrigrỹmỹ ag nesiritru ki),
						'one' => q({0} mĩrigrỹmỹ nesiritru ki),
						'other' => q({0} mĩrigrỹmỹ ag nesiritru ki),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mĩrigrỹmỹ ag nesiritru ki),
						'one' => q({0} mĩrigrỹmỹ nesiritru ki),
						'other' => q({0} mĩrigrỹmỹ ag nesiritru ki),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mĩrimol ag ritru ki),
						'one' => q({0} mĩrimol ritru ki),
						'other' => q({0} mĩrimol ag ritru ki),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mĩrimol ag ritru ki),
						'one' => q({0} mĩrimol ritru ki),
						'other' => q({0} mĩrimol ag ritru ki),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(mol ag),
						'other' => q({0} mol),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mol ag),
						'other' => q({0} mol),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(sẽnto ki),
						'one' => q({0} sẽnto ki),
						'other' => q({0} sẽnto ki),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(sẽnto ki),
						'one' => q({0} sẽnto ki),
						'other' => q({0} sẽnto ki),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(mil ki),
						'one' => q({0} mil ki),
						'other' => q({0} mil ki),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(mil ki),
						'one' => q({0} mil ki),
						'other' => q({0} mil ki),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(milhão ki kupar ‘e),
						'one' => q({0} kupar milhão ki),
						'other' => q({0} kupar 'e milhão ki),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(milhão ki kupar ‘e),
						'one' => q({0} kupar milhão ki),
						'other' => q({0} kupar 'e milhão ki),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q({0} pãntu mase),
						'other' => q({0} pãntu mase ag),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0} pãntu mase),
						'other' => q({0} pãntu mase ag),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(ritru ag kiromẽturo tỹ 100 ki),
						'one' => q({0} ritru kiromẽturo tỹ 100 ki),
						'other' => q({0} ritru ag kiromẽturo tỹ 100 ki),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(ritru ag kiromẽturo tỹ 100 ki),
						'one' => q({0} ritru kiromẽturo tỹ 100 ki),
						'other' => q({0} ritru ag kiromẽturo tỹ 100 ki),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(ritru ag kiromẽturo ki),
						'one' => q({0} ritru kiromẽturo ki),
						'other' => q({0} ritru ag kiromẽturo ki),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(ritru ag kiromẽturo ki),
						'one' => q({0} ritru kiromẽturo ki),
						'other' => q({0} ritru ag kiromẽturo ki),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(garỹv ki milha ag),
						'one' => q({0} milha garỹv ki),
						'other' => q({0} milha ag garỹv ki),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(garỹv ki milha ag),
						'one' => q({0} milha garỹv ki),
						'other' => q({0} milha ag garỹv ki),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(garỹv ĩmperijav ki milha ag),
						'one' => q({0} milha garỹv ĩmperijav ki),
						'other' => q({0} milha ag garỹv ĩmperijav ki),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(garỹv ĩmperijav ki milha ag),
						'one' => q({0} milha garỹv ĩmperijav ki),
						'other' => q({0} milha ag garỹv ĩmperijav ki),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} rã jur),
						'north' => q({0} nãrti),
						'south' => q({0} sur),
						'west' => q({0} rã pur),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} rã jur),
						'north' => q({0} nãrti),
						'south' => q({0} sur),
						'west' => q({0} rã pur),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bit ag),
						'other' => q({0} bit ag),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bit ag),
						'other' => q({0} bit ag),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(byte ag),
						'other' => q({0} byte),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(byte ag),
						'other' => q({0} byte),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabit ag),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit ag),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabit ag),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit ag),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabyte ag),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyte ag),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabyte ag),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyte ag),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobit ag),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit ag),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobit ag),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit ag),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobyte ag),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyte ag),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobyte ag),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyte ag),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(mẽgabit ag),
						'one' => q({0} mẽgabit),
						'other' => q({0} mẽgabit ag),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(mẽgabit ag),
						'one' => q({0} mẽgabit),
						'other' => q({0} mẽgabit ag),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(mẽgabyte ag),
						'one' => q({0} mẽgabyte),
						'other' => q({0} mẽgabyte ag),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(mẽgabyte ag),
						'one' => q({0} mẽgabyte),
						'other' => q({0} mẽgabyte ag),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabyte ag),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte ag),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabyte ag),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte ag),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabit ag),
						'one' => q({0} terabit),
						'other' => q({0} terabit ag),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabit ag),
						'one' => q({0} terabit),
						'other' => q({0} terabit ag),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabyte ag),
						'one' => q({0} terabyte),
						'other' => q({0} terabyte ag),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabyte ag),
						'one' => q({0} terabyte),
						'other' => q({0} terabyte ag),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(sékuru ag),
						'one' => q({0} sékuru),
						'other' => q({0} sékuru ag),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(sékuru ag),
						'one' => q({0} sékuru),
						'other' => q({0} sékuru ag),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(kurã ag),
						'one' => q(kurã {0}),
						'other' => q(kurã {0}),
						'per' => q(kurã {0} ki),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(kurã ag),
						'one' => q(kurã {0}),
						'other' => q(kurã {0}),
						'per' => q(kurã {0} ki),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(nékana ag),
						'one' => q({0} nékana),
						'other' => q({0} nékana ag),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(nékana ag),
						'one' => q({0} nékana),
						'other' => q({0} nékana ag),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(óra ag),
						'one' => q(óra {0}),
						'other' => q(óra ag {0}),
						'per' => q(óra {0} ki),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(óra ag),
						'one' => q(óra {0}),
						'other' => q(óra ag {0}),
						'per' => q(óra {0} ki),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mĩkrusigũnu ag),
						'one' => q(mĩkrusigũnu {0}),
						'other' => q(mĩkrusigũnu {0}),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mĩkrusigũnu ag),
						'one' => q(mĩkrusigũnu {0}),
						'other' => q(mĩkrusigũnu {0}),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(mĩrisigũnu ag),
						'one' => q(mĩrisigũnu {0}),
						'other' => q(mĩrisigũnu {0}),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(mĩrisigũnu ag),
						'one' => q(mĩrisigũnu {0}),
						'other' => q(mĩrisigũnu {0}),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(mĩnũtu ag),
						'one' => q(mĩnũtu {0}),
						'other' => q(mĩnũtu {0}),
						'per' => q(mĩnũtu {0} ki),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(mĩnũtu ag),
						'one' => q(mĩnũtu {0}),
						'other' => q(mĩnũtu {0}),
						'per' => q(mĩnũtu {0} ki),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(kysã ag),
						'one' => q(kysã {0}),
						'other' => q(kysã ag {0}),
						'per' => q(kysã {0} ki),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(kysã ag),
						'one' => q(kysã {0}),
						'other' => q(kysã ag {0}),
						'per' => q(kysã {0} ki),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nỹnãsigũnu ag),
						'one' => q(nỹnãsigũnu {0}),
						'other' => q(nỹnãsigũnu {0}),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nỹnãsigũnu ag),
						'one' => q(nỹnãsigũnu {0}),
						'other' => q(nỹnãsigũnu {0}),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sigũnu ag),
						'one' => q(sigũnu {0}),
						'other' => q(sigũnu {0}),
						'per' => q(sigũnu {0} ki),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sigũnu ag),
						'one' => q(sigũnu {0}),
						'other' => q(sigũnu {0}),
						'per' => q(sigũnu {0} ki),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(simỹnỹ ag),
						'one' => q({0} simỹnỹ),
						'other' => q({0} simỹnỹ ag),
						'per' => q({0} simỹnỹ ki),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(simỹnỹ ag),
						'one' => q({0} simỹnỹ),
						'other' => q({0} simỹnỹ ag),
						'per' => q({0} simỹnỹ ki),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(prỹg ag),
						'one' => q({0} prỹg),
						'other' => q({0} prỹg ag),
						'per' => q({0} prỹg ki),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(prỹg ag),
						'one' => q({0} prỹg),
						'other' => q({0} prỹg ag),
						'per' => q({0} prỹg ki),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ampere ag),
						'one' => q({0} ampere),
						'other' => q({0} ampere ag),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ampere ag),
						'one' => q({0} ampere),
						'other' => q({0} ampere ag),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(mĩriampere),
						'one' => q({0} mĩriampere),
						'other' => q({0} mĩriampere ag),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(mĩriampere),
						'one' => q({0} mĩriampere),
						'other' => q({0} mĩriampere ag),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohm ag),
						'one' => q({0} ohm),
						'other' => q({0} ohm ag),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohm ag),
						'one' => q({0} ohm),
						'other' => q({0} ohm ag),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(volt ag),
						'one' => q({0} volt),
						'other' => q({0} volt ag),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(volt ag),
						'one' => q({0} volt),
						'other' => q({0} volt ag),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(ũnĩnane térmĩka mritỹnĩka),
						'one' => q({0} ũnĩnane térmĩka mritỹnĩka),
						'other' => q({0} ũnĩnane térmĩka mritỹnĩka ag),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(ũnĩnane térmĩka mritỹnĩka),
						'one' => q({0} ũnĩnane térmĩka mritỹnĩka),
						'other' => q({0} ũnĩnane térmĩka mritỹnĩka ag),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(karorija ag),
						'one' => q({0} karorija),
						'other' => q({0} karorija ag),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(karorija ag),
						'one' => q({0} karorija),
						'other' => q({0} karorija ag),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(elétron-volt ag),
						'one' => q({0} elétron-volt),
						'other' => q({0} elétron-volt ag),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(elétron-volt ag),
						'one' => q({0} elétron-volt),
						'other' => q({0} elétron-volt ag),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Karoria ag),
						'one' => q({0} Karorija),
						'other' => q({0} Karorija ag),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Karoria ag),
						'one' => q({0} Karorija),
						'other' => q({0} Karorija ag),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(joule ag),
						'one' => q({0} joule),
						'other' => q({0} joule ag),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(joule ag),
						'one' => q({0} joule),
						'other' => q({0} joule ag),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kirokarorija ag),
						'one' => q({0} kirokarorija),
						'other' => q({0} kirokarorija ag),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kirokarorija ag),
						'one' => q({0} kirokarorija),
						'other' => q({0} kirokarorija ag),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kirojoule ag),
						'one' => q({0} kirojoule),
						'other' => q({0} kirojoule ag),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kirojoule ag),
						'one' => q({0} kirojoule),
						'other' => q({0} kirojoule ag),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kirowatt-óra ag),
						'one' => q({0} kirowatt-óra),
						'other' => q({0} kirowatt-óra ag),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kirowatt-óra ag),
						'one' => q({0} kirowatt-óra),
						'other' => q({0} kirowatt-óra ag),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(ũnĩnane térmĩka nãrte-ỹmẽrikỹnũ ag),
						'one' => q({0} ũnĩnane térmĩka nãrte-ỹmẽrikỹnũ),
						'other' => q({0} ũnĩnane térmĩka nãrte-ỹmẽrikỹnũ ag),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(ũnĩnane térmĩka nãrte-ỹmẽrikỹnũ ag),
						'one' => q({0} ũnĩnane térmĩka nãrte-ỹmẽrikỹnũ),
						'other' => q({0} ũnĩnane térmĩka nãrte-ỹmẽrikỹnũ ag),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newton ag),
						'one' => q({0} newton),
						'other' => q({0} newton ag),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newton ag),
						'one' => q({0} newton),
						'other' => q({0} newton ag),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(ti tar rimra ag),
						'one' => q({0} ti tar rimra),
						'other' => q({0} ti tar rimra ag),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(ti tar rimra ag),
						'one' => q({0} ti tar rimra),
						'other' => q({0} ti tar rimra ag),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigahertz ag),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz ag),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigahertz ag),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz ag),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(hertz ag),
						'one' => q({0} hertz),
						'other' => q({0} hertz ag),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(hertz ag),
						'one' => q({0} hertz),
						'other' => q({0} hertz ag),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kilohertz ag),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz ag),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kilohertz ag),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz ag),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(mẽgahertz ag),
						'one' => q({0} mẽgahertz),
						'other' => q({0} mẽgahertz ag),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(mẽgahertz ag),
						'one' => q({0} mẽgahertz),
						'other' => q({0} mẽgahertz ag),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(sẽntimẽturo ki pãntu ag),
						'one' => q({0} pãntu sẽntimẽturo ki),
						'other' => q({0} pãntu ag sẽntimẽturo ki),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(sẽntimẽturo ki pãntu ag),
						'one' => q({0} pãntu sẽntimẽturo ki),
						'other' => q({0} pãntu ag sẽntimẽturo ki),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(poregana ki pãntu ag),
						'one' => q({0} pãntu poregana ki),
						'other' => q({0} pãntu ag poregana ki),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(poregana ki pãntu ag),
						'one' => q({0} pãntu poregana ki),
						'other' => q({0} pãntu ag poregana ki),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(tipografiko em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(tipografiko em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(mẽgapixel ag),
						'one' => q({0} mẽgapixel),
						'other' => q({0} mẽgapixel ag),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(mẽgapixel ag),
						'one' => q({0} mẽgapixel),
						'other' => q({0} mẽgapixel ag),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pixel ag),
						'one' => q({0} pixel),
						'other' => q({0} pixel ag),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pixel ag),
						'one' => q({0} pixel),
						'other' => q({0} pixel ag),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(sẽntimẽturo ki pixel ag),
						'one' => q({0} pixel sẽntimẽturo ki),
						'other' => q({0} pixel ag sẽntimẽturo ki),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(sẽntimẽturo ki pixel ag),
						'one' => q({0} pixel sẽntimẽturo ki),
						'other' => q({0} pixel ag sẽntimẽturo ki),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(poregana ki pixel ag),
						'one' => q({0} pixel poregana ki),
						'other' => q({0} pixel ag poregana ki),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(poregana ki pixel ag),
						'one' => q({0} pixel poregana ki),
						'other' => q({0} pixel ag poregana ki),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(kanhkã vẽnhkãmur ag),
						'one' => q({0} kanhkã vẽnhkãmur),
						'other' => q({0} kanhkã vẽnhkãmur ag),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(kanhkã vẽnhkãmur ag),
						'one' => q({0} kanhkã vẽnhkãmur),
						'other' => q({0} kanhkã vẽnhkãmur ag),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sẽntimẽturo ag),
						'one' => q({0} sẽntimẽturo),
						'other' => q({0} sẽntimẽturo ag),
						'per' => q({0} sẽntimẽturo ki),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sẽntimẽturo ag),
						'one' => q({0} sẽntimẽturo),
						'other' => q({0} sẽntimẽturo ag),
						'per' => q({0} sẽntimẽturo ki),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(nesimẽturo ag),
						'one' => q({0} nesimẽturo),
						'other' => q({0} nesimẽturo ag),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(nesimẽturo ag),
						'one' => q({0} nesimẽturo),
						'other' => q({0} nesimẽturo ag),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(mrasa ag),
						'one' => q({0} mrasa),
						'other' => q({0} mrasa ag),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(mrasa ag),
						'one' => q({0} mrasa),
						'other' => q({0} mrasa ag),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(tipẽn ag),
						'one' => q({0} tipẽn),
						'other' => q({0} tipẽn ag),
						'per' => q({0} tipẽn ki),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(tipẽn ag),
						'one' => q({0} tipẽn),
						'other' => q({0} tipẽn ag),
						'per' => q({0} tipẽn ki),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlong ag),
						'one' => q({0} furlong),
						'other' => q({0} furlong ag),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong ag),
						'one' => q({0} furlong),
						'other' => q({0} furlong ag),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(poregana ag),
						'one' => q({0} poregana),
						'other' => q({0} poregana ag),
						'per' => q({0} poregana ki),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(poregana ag),
						'one' => q({0} poregana),
						'other' => q({0} poregana ag),
						'per' => q({0} poregana ki),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kiromẽturo ag),
						'one' => q({0} kiromẽturo),
						'other' => q({0} kiromẽturo ag),
						'per' => q({0} kiromẽturo ki),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kiromẽturo ag),
						'one' => q({0} kiromẽturo),
						'other' => q({0} kiromẽturo ag),
						'per' => q({0} kiromẽturo ki),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(prỹg-jẽngrẽ ag),
						'one' => q({0} prỹg-jẽngrẽ),
						'other' => q({0} prỹg-jẽngrẽ ag),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(prỹg-jẽngrẽ ag),
						'one' => q({0} prỹg-jẽngrẽ),
						'other' => q({0} prỹg-jẽngrẽ ag),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(mẽturo ag),
						'one' => q({0} mẽturo),
						'other' => q({0} mẽturo ag),
						'per' => q({0} mẽturo ki),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(mẽturo ag),
						'one' => q({0} mẽturo),
						'other' => q({0} mẽturo ag),
						'per' => q({0} mẽturo ki),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mĩkromẽturo ag),
						'one' => q({0} mĩkromẽturo),
						'other' => q({0} mĩkromẽturo ag),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mĩkromẽturo ag),
						'one' => q({0} mĩkromẽturo),
						'other' => q({0} mĩkromẽturo ag),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(milha ag),
						'one' => q({0} milha),
						'other' => q({0} milha ag),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milha ag),
						'one' => q({0} milha),
						'other' => q({0} milha ag),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(milha enhkỹninỹva ag),
						'one' => q({0} milha enhkỹninỹva),
						'other' => q({0} milha enhkỹninỹva ag),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(milha enhkỹninỹva ag),
						'one' => q({0} milha enhkỹninỹva),
						'other' => q({0} milha enhkỹninỹva ag),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(mĩrimẽturo ag),
						'one' => q({0} mĩrimẽturo),
						'other' => q({0} mĩrimẽturo ag),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(mĩrimẽturo ag),
						'one' => q({0} mĩrimẽturo),
						'other' => q({0} mĩrimẽturo ag),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nỹnãmẽturo ag),
						'one' => q({0} nỹnãmẽturo),
						'other' => q({0} nỹnãmẽturo ag),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nỹnãmẽturo ag),
						'one' => q({0} nỹnãmẽturo),
						'other' => q({0} nỹnãmẽturo ag),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(milha mỹritimỹ ag),
						'one' => q({0} milha mỹritimỹ),
						'other' => q({0} milha mỹritimỹ ag),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(milha mỹritimỹ ag),
						'one' => q({0} milha mỹritimỹ),
						'other' => q({0} milha mỹritimỹ ag),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsec ag),
						'one' => q({0} parsec),
						'other' => q({0} parsec ag),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsec ag),
						'one' => q({0} parsec),
						'other' => q({0} parsec ag),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikomẽturo ag),
						'one' => q({0} pikomẽturo),
						'other' => q({0} pikomẽturo ag),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikomẽturo ag),
						'one' => q({0} pikomẽturo),
						'other' => q({0} pikomẽturo ag),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pãntu ag),
						'one' => q({0} pãntu),
						'other' => q({0} pãntu ag),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pãntu ag),
						'one' => q({0} pãntu),
						'other' => q({0} pãntu ag),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(rã nogno),
						'one' => q({0} rã no),
						'other' => q({0} rã no ag),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(rã nogno),
						'one' => q({0} rã no),
						'other' => q({0} rã no ag),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(jarda ag),
						'one' => q({0} jarda),
						'other' => q({0} jarda ag),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(jarda ag),
						'one' => q({0} jarda),
						'other' => q({0} jarda ag),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(jẽngrẽ ag),
						'one' => q({0} jẽngrẽ),
						'other' => q({0} jẽngrẽ ag),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(jẽngrẽ ag),
						'one' => q({0} jẽngrẽ),
						'other' => q({0} jẽngrẽ ag),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(rã jẽngrẽ ag),
						'one' => q({0} rã jẽngrẽ),
						'other' => q({0} rã jẽngrẽ ag),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(rã jẽngrẽ ag),
						'one' => q({0} rã jẽngrẽ),
						'other' => q({0} rã jẽngrẽ ag),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(kirate ag),
						'one' => q({0} kirate),
						'other' => q({0} kirate ag),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(kirate ag),
						'one' => q({0} kirate),
						'other' => q({0} kirate ag),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(dalton ag),
						'one' => q({0} dalton),
						'other' => q({0} dalton ag),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(dalton ag),
						'one' => q({0} dalton),
						'other' => q({0} dalton ag),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(ga-pãgoj ag),
						'one' => q({0} ga-pãgoj),
						'other' => q({0} ga-pãgoj),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(ga-pãgoj ag),
						'one' => q({0} ga-pãgoj),
						'other' => q({0} ga-pãgoj),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grỹmỹ ag),
						'one' => q({0} grỹmỹ),
						'other' => q({0} grỹmỹ ag),
						'per' => q({0} grỹmỹ ki),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grỹmỹ ag),
						'one' => q({0} grỹmỹ),
						'other' => q({0} grỹmỹ ag),
						'per' => q({0} grỹmỹ ki),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kirogrỹmỹ ag),
						'one' => q({0} kirogrỹmỹ),
						'other' => q({0} kirogrỹmỹ ag),
						'per' => q({0} kirogrỹmỹ ki),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kirogrỹmỹ ag),
						'one' => q({0} kirogrỹmỹ),
						'other' => q({0} kirogrỹmỹ ag),
						'per' => q({0} kirogrỹmỹ ki),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'name' => q(tãnẽrada mẽtirika ag),
						'one' => q({0} tãnẽrada mẽtirika),
						'other' => q({0} tãnẽrada mẽtirika ag),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'name' => q(tãnẽrada mẽtirika ag),
						'one' => q({0} tãnẽrada mẽtirika),
						'other' => q({0} tãnẽrada mẽtirika ag),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mĩkrugrỹmỹ ag),
						'one' => q({0} mĩkrugrỹmỹ),
						'other' => q({0} mĩkrugrỹmỹ ag),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mĩkrugrỹmỹ ag),
						'one' => q({0} mĩkrugrỹmỹ),
						'other' => q({0} mĩkrugrỹmỹ ag),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(mĩrigrỹmỹ ag),
						'one' => q({0} mĩrigrỹmỹ),
						'other' => q({0} mĩrigrỹmỹ ag),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(mĩrigrỹmỹ ag),
						'one' => q({0} mĩrigrỹmỹ),
						'other' => q({0} mĩrigrỹmỹ ag),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(mĩgfi ag),
						'one' => q({0} mĩgfi),
						'other' => q({0} mĩgfi ag),
						'per' => q({0} mĩgfi ki),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(mĩgfi ag),
						'one' => q({0} mĩgfi),
						'other' => q({0} mĩgfi ag),
						'per' => q({0} mĩgfi ki),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(mĩgfi troy ag),
						'one' => q({0} mĩgfi troy),
						'other' => q({0} mĩgfi troy ag),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(mĩgfi troy ag),
						'one' => q({0} mĩgfi troy),
						'other' => q({0} mĩgfi troy ag),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(rimra ag),
						'one' => q({0} rimra),
						'other' => q({0} rimra ag),
						'per' => q({0} rimra ki),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(rimra ag),
						'one' => q({0} rimra),
						'other' => q({0} rimra ag),
						'per' => q({0} rimra ki),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(rã-pãgoj ag),
						'one' => q({0} rã-pãgoj),
						'other' => q({0} rã-pãgoj),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(rã-pãgoj ag),
						'one' => q({0} rã-pãgoj),
						'other' => q({0} rã-pãgoj),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(pó ag),
						'one' => q({0} pó),
						'other' => q({0} pó ag),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(pó ag),
						'one' => q({0} pó),
						'other' => q({0} pó ag),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tãnẽrada ag),
						'one' => q({0} tãnẽrada),
						'other' => q({0} tãnẽrada ag),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tãnẽrada ag),
						'one' => q({0} tãnẽrada),
						'other' => q({0} tãnẽrada ag),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} por {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} por {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigawatt ag),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt ag),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigawatt ag),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt ag),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(kãvãru-jẽnger ag),
						'one' => q({0} kãvãru-jẽnger),
						'other' => q({0} kãvãru-jẽnger ag),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(kãvãru-jẽnger ag),
						'one' => q({0} kãvãru-jẽnger),
						'other' => q({0} kãvãru-jẽnger ag),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kirowatt ag),
						'one' => q({0} kirowatt),
						'other' => q({0} kirowatt ag),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kirowatt ag),
						'one' => q({0} kirowatt),
						'other' => q({0} kirowatt ag),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(mẽgawatt ag),
						'one' => q({0} mẽgawatt),
						'other' => q({0} mẽgawatt ag),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(mẽgawatt ag),
						'one' => q({0} mẽgawatt),
						'other' => q({0} mẽgawatt ag),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(mĩriwatt ag),
						'one' => q({0} mĩriwatt),
						'other' => q({0} mĩriwatt ag),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(mĩriwatt ag),
						'one' => q({0} mĩriwatt),
						'other' => q({0} mĩriwatt ag),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(watt ag),
						'one' => q({0} watt),
						'other' => q({0} watt ag),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watt ag),
						'one' => q({0} watt),
						'other' => q({0} watt ag),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmosfera ag),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfera ag),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmosfera ag),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfera ag),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(bar ag),
						'other' => q({0} bar ag),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(bar ag),
						'other' => q({0} bar ag),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hegtopascal ag),
						'one' => q({0} hegtopascal),
						'other' => q({0} hegtopascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hegtopascal ag),
						'one' => q({0} hegtopascal),
						'other' => q({0} hegtopascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(poregana tỹ mẽrkuriju ag),
						'one' => q({0} poregana tỹ mẽrkuriju),
						'other' => q({0} poregana ag tỹ mẽrkuriju),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(poregana tỹ mẽrkuriju ag),
						'one' => q({0} poregana tỹ mẽrkuriju),
						'other' => q({0} poregana ag tỹ mẽrkuriju),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kiropascal ag),
						'one' => q({0} kiropascal),
						'other' => q({0} kiropascal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kiropascal ag),
						'one' => q({0} kiropascal),
						'other' => q({0} kiropascal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(mẽgapascal ag),
						'one' => q({0} mẽgapascal),
						'other' => q({0} mẽgapascal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(mẽgapascal ag),
						'one' => q({0} mẽgapascal),
						'other' => q({0} mẽgapascal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(mĩribar ag),
						'one' => q({0} mĩribar),
						'other' => q({0} mĩribar ag),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(mĩribar ag),
						'one' => q({0} mĩribar),
						'other' => q({0} mĩribar ag),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mĩrimẽturo tỹ mẽrkuriju ag),
						'one' => q({0} mĩrimẽturo tỹ mẽrkuriju),
						'other' => q({0} mĩrimẽturo ag tỹ mẽrkuriju),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mĩrimẽturo tỹ mẽrkuriju ag),
						'one' => q({0} mĩrimẽturo tỹ mẽrkuriju),
						'other' => q({0} mĩrimẽturo ag tỹ mẽrkuriju),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(pascal ag),
						'one' => q({0} pascal),
						'other' => q({0} pascal ag),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(pascal ag),
						'one' => q({0} pascal),
						'other' => q({0} pascal ag),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(rimra ag poregana pénogno ki),
						'one' => q({0} rimra poregana pénogno ki),
						'other' => q({0} rimra ag poregana pénogno ki),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(rimra ag poregana pénogno ki),
						'one' => q({0} rimra poregana pénogno ki),
						'other' => q({0} rimra ag poregana pénogno ki),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kiromẽturo ag óra ki),
						'one' => q({0} kiromẽturo óra ki),
						'other' => q({0} kiromẽturo ag óra ki),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kiromẽturo ag óra ki),
						'one' => q({0} kiromẽturo óra ki),
						'other' => q({0} kiromẽturo ag óra ki),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(kagje ag),
						'one' => q({0} kagje),
						'other' => q({0} kagje ag),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(kagje ag),
						'one' => q({0} kagje),
						'other' => q({0} kagje ag),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(mẽturo ag sigũnu ki),
						'one' => q({0} mẽturo sigũnu ki),
						'other' => q({0} mẽturo ag sigũnu ki),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(mẽturo ag sigũnu ki),
						'one' => q({0} mẽturo sigũnu ki),
						'other' => q({0} mẽturo ag sigũnu ki),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(milha ag óra ki),
						'one' => q({0} milha óra ki),
						'other' => q({0} milha ag óra ki),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(milha ag óra ki),
						'one' => q({0} milha óra ki),
						'other' => q({0} milha ag óra ki),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(grav Celsius ag),
						'one' => q({0} grav Celsius),
						'other' => q({0} grav Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(grav Celsius ag),
						'one' => q({0} grav Celsius),
						'other' => q({0} grav Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(grav Fahrenheit ag),
						'one' => q({0} grav Fahrenheit),
						'other' => q({0} grav Fahrenheit ag),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(grav Fahrenheit ag),
						'one' => q({0} grav Fahrenheit),
						'other' => q({0} grav Fahrenheit ag),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvin ag),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin ag),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvin ag),
						'one' => q({0} kelvin),
						'other' => q({0} kelvin ag),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(newton-mẽturo ag),
						'one' => q({0} newton-mẽturo),
						'other' => q({0} newton-mẽturo ag),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newton-mẽturo ag),
						'one' => q({0} newton-mẽturo),
						'other' => q({0} newton-mẽturo ag),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(tipẽn-ag-rimra),
						'one' => q({0} tipẽn-rimra),
						'other' => q({0} tipẽn-ag-rimra),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(tipẽn-ag-rimra),
						'one' => q({0} tipẽn-rimra),
						'other' => q({0} tipẽn-ag-rimra),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(akre-pẽn ag),
						'one' => q({0} akre-pẽn),
						'other' => q({0} akre-pẽn ag),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(akre-pẽn ag),
						'one' => q({0} akre-pẽn),
						'other' => q({0} akre-pẽn ag),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(marir ag),
						'one' => q({0} marir),
						'other' => q({0} marir ag),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(marir ag),
						'one' => q({0} marir),
						'other' => q({0} marir ag),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sẽntiritru ag),
						'one' => q({0} sẽntiritru),
						'other' => q({0} sẽntiritru ag),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sẽntiritru ag),
						'one' => q({0} sẽntiritru),
						'other' => q({0} sẽntiritru ag),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(sẽntimẽturo kumiko ag),
						'one' => q({0} sẽntimẽturo kumiko),
						'other' => q({0} sẽntimẽturo kumiko ag),
						'per' => q({0} sẽntimẽturo kumiko ki),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(sẽntimẽturo kumiko ag),
						'one' => q({0} sẽntimẽturo kumiko),
						'other' => q({0} sẽntimẽturo kumiko ag),
						'per' => q({0} sẽntimẽturo kumiko ki),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(tipẽn kumiko ag),
						'one' => q({0} tipẽn kumiko),
						'other' => q({0} tipẽn kumiko ag),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(tipẽn kumiko ag),
						'one' => q({0} tipẽn kumiko),
						'other' => q({0} tipẽn kumiko ag),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(poregana kumika ag),
						'one' => q({0} poregana kumika),
						'other' => q({0} poregana kumika),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(poregana kumika ag),
						'one' => q({0} poregana kumika),
						'other' => q({0} poregana kumika),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kiromẽturo kumiko ag),
						'one' => q({0} kiromẽturo kumiko ag),
						'other' => q(kiromẽturo kumiko {0}),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kiromẽturo kumiko ag),
						'one' => q({0} kiromẽturo kumiko ag),
						'other' => q(kiromẽturo kumiko {0}),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(mẽturo kumiko ag),
						'one' => q({0} mẽturo kumiko),
						'other' => q({0} mẽturo kumiko ag),
						'per' => q({0} mẽturo kumiko ki),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(mẽturo kumiko ag),
						'one' => q({0} mẽturo kumiko),
						'other' => q({0} mẽturo kumiko ag),
						'per' => q({0} mẽturo kumiko ki),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(milha kumika ag),
						'one' => q({0} milha kumika),
						'other' => q({0} milha kumika ag),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(milha kumika ag),
						'one' => q({0} milha kumika),
						'other' => q({0} milha kumika ag),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(jarda kumika ag),
						'one' => q({0} jarda kumika),
						'other' => q({0} jarda kumika ag),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(jarda kumika ag),
						'one' => q({0} jarda kumika),
						'other' => q({0} jarda kumika ag),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(sikara ag),
						'one' => q({0} sikara),
						'other' => q({0} sikara ag),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(sikara ag),
						'one' => q({0} sikara),
						'other' => q({0} sikara ag),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(sikara mẽtrika ag),
						'one' => q({0} sikara mẽtrika),
						'other' => q({0} sikara mẽtrika ag),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(sikara mẽtrika ag),
						'one' => q({0} sikara mẽtrika),
						'other' => q({0} sikara mẽtrika ag),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(nesirituru ag),
						'one' => q({0} nesirituru),
						'other' => q({0} nesirituru ag),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(nesirituru ag),
						'one' => q({0} nesirituru),
						'other' => q({0} nesirituru ag),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(mĩgfi gungón ag),
						'one' => q({0} mĩgfi gungón),
						'other' => q({0} mĩgfi gungón ag),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(mĩgfi gungón ag),
						'one' => q({0} mĩgfi gungón),
						'other' => q({0} mĩgfi gungón ag),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(mĩgfi gungón ĩmperijav ag),
						'one' => q({0} mĩgfi gungón ĩmperijav),
						'other' => q({0} mĩgfi gungón ĩmperijav ag),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(mĩgfi gungón ĩmperijav ag),
						'one' => q({0} mĩgfi gungón ĩmperijav),
						'other' => q({0} mĩgfi gungón ĩmperijav ag),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(garỹv ag),
						'one' => q({0} garỹv),
						'other' => q({0} garỹv ag),
						'per' => q({0} garỹv ki),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(garỹv ag),
						'one' => q({0} garỹv),
						'other' => q({0} garỹv ag),
						'per' => q({0} garỹv ki),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(garỹv ĩmperijav ag),
						'one' => q({0} garỹv ĩmperijav),
						'other' => q({0} garỹv ĩmperijav ag),
						'per' => q({0} garỹv ĩmperijav ki),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(garỹv ĩmperijav ag),
						'one' => q({0} garỹv ĩmperijav),
						'other' => q({0} garỹv ĩmperijav ag),
						'per' => q({0} garỹv ĩmperijav ki),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hegtoritru ag),
						'one' => q({0} hegtoritru),
						'other' => q({0} hegtoritru ag),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hegtoritru ag),
						'one' => q({0} hegtoritru),
						'other' => q({0} hegtoritru ag),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(ritru ag),
						'one' => q({0} ritru),
						'other' => q({0} ritru ag),
						'per' => q({0} ritru ki),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(ritru ag),
						'one' => q({0} ritru),
						'other' => q({0} ritru ag),
						'per' => q({0} ritru ki),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(mẽgaritru ag),
						'one' => q({0} mẽgaritru),
						'other' => q({0} mẽgaritru),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(mẽgaritru ag),
						'one' => q({0} mẽgaritru),
						'other' => q({0} mẽgaritru),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mĩriritru ag),
						'one' => q({0} mĩriritru),
						'other' => q({0} mĩriritru ag),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mĩriritru ag),
						'one' => q({0} mĩriritru),
						'other' => q({0} mĩriritru ag),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pint ag),
						'one' => q({0} pint),
						'other' => q({0} pint ag),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pint ag),
						'one' => q({0} pint),
						'other' => q({0} pint ag),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(pint mẽtriko ag),
						'one' => q({0} pint mẽtriko),
						'other' => q({0} pint mẽtriko ag),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pint mẽtriko ag),
						'one' => q({0} pint mẽtriko),
						'other' => q({0} pint mẽtriko ag),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kãgrán ag),
						'one' => q({0} kãgrán),
						'other' => q({0} kãgrán ag),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kãgrán ag),
						'one' => q({0} kãgrán),
						'other' => q({0} kãgrán ag),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(kume kujé ag),
						'one' => q({0} kume kujé),
						'other' => q({0} kume kujé),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(kume kujé ag),
						'one' => q({0} kume kujé),
						'other' => q({0} kume kujé),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(sa kujé ag),
						'one' => q({0} kujé),
						'other' => q({0} kujé ag),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(sa kujé ag),
						'one' => q({0} kujé),
						'other' => q({0} kujé ag),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'' => {
						'name' => q(kãtá),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(kãtá),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(tar g),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(tar g),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0}'),
						'other' => q({0}'),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0}'),
						'other' => q({0}'),
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
						'one' => q({0} akre),
						'other' => q({0} akre ag),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} akre),
						'other' => q({0} akre ag),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100 km ki),
						'one' => q({0} l/100 km ki),
						'other' => q({0} l/100 km ki),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100 km ki),
						'one' => q({0} l/100 km ki),
						'other' => q({0} l/100 km ki),
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
					'digital-bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
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
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PB),
						'one' => q({0} PB),
						'other' => q({0} PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PB),
						'one' => q({0} PB),
						'other' => q({0} PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(sék.),
						'one' => q({0} sék.),
						'other' => q({0} sék. ag),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(sék.),
						'one' => q({0} sék.),
						'other' => q({0} sék. ag),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(kurã),
						'one' => q({0} kurã),
						'other' => q({0} kurã ag),
						'per' => q({0}/kurã),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(kurã),
						'one' => q({0} kurã),
						'other' => q({0} kurã ag),
						'per' => q({0}/kurã),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(óra),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(óra),
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
					'duration-month' => {
						'name' => q(kysã),
						'one' => q({0} kysã),
						'other' => q({0} kysã ag),
						'per' => q({0}/kysã),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(kysã),
						'one' => q({0} kysã),
						'other' => q({0} kysã ag),
						'per' => q({0}/kysã),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sig),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/sig),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sig),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/sig),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(sim.),
						'one' => q({0} sim.),
						'other' => q({0} sim. Ag),
						'per' => q({0}/sim.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(sim.),
						'one' => q({0} sim.),
						'other' => q({0} sim. Ag),
						'per' => q({0}/sim.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(prỹg),
						'one' => q({0} prỹg),
						'other' => q({0} prỹg ag),
						'per' => q({0}/prỹg ki),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(prỹg),
						'one' => q({0} prỹg),
						'other' => q({0} prỹg ag),
						'per' => q({0}/prỹg ki),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(ua k.v.),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ua k.v.),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(mrasa),
						'one' => q({0} bça. mrs),
						'other' => q({0} bça. mrs),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(mrasa),
						'one' => q({0} bça. mrs),
						'other' => q({0} bça. mrs),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(tipẽn ag),
						'one' => q({0} tipẽn),
						'other' => q({0} tipẽn ag),
						'per' => q({0}/tipẽn),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(tipẽn ag),
						'one' => q({0} tipẽn),
						'other' => q({0} tipẽn ag),
						'per' => q({0}/tipẽn),
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
						'name' => q(por.),
						'one' => q({0}″),
						'other' => q({0}″),
						'per' => q({0}/por.),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(por.),
						'one' => q({0}″),
						'other' => q({0}″),
						'per' => q({0}/por.),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(prỹg-jẽngrẽ ag),
						'one' => q(prỹg-jẽngrẽ {0}),
						'other' => q(prỹg-jẽngrẽ {0}),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(prỹg-jẽngrẽ ag),
						'one' => q(prỹg-jẽngrẽ {0}),
						'other' => q(prỹg-jẽngrẽ {0}),
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
						'name' => q(mil),
						'one' => q({0} milha),
						'other' => q({0} milha ag),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mil),
						'one' => q({0} milha),
						'other' => q({0} milha ag),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(mn),
						'one' => q({0} mn),
						'other' => q({0} mn),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(mn),
						'one' => q({0} mn),
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
					'mass-carat' => {
						'name' => q(kirate),
						'one' => q({0} ql),
						'other' => q({0} ql),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(kirate),
						'one' => q({0} ql),
						'other' => q({0} ql),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grỹmỹ),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grỹmỹ),
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
						'name' => q(pó),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(pó),
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
					'power-horsepower' => {
						'one' => q({0} cv),
						'other' => q({0} cv),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0} cv),
						'other' => q({0} cv),
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
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(kagje),
						'one' => q({0} kagje),
						'other' => q({0} kagje),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(kagje),
						'one' => q({0} kagje),
						'other' => q({0} kagje),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
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
						'name' => q(ritru),
						'one' => q({0}r),
						'other' => q({0}r),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(ritru),
						'one' => q({0}r),
						'other' => q({0}r),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(kãtá),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(kãtá),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(tar g),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(tar g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(mẽturo/seg²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(mẽturo/seg²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(arcmin ag),
						'one' => q(arcmin {0}),
						'other' => q(arcmin {0}),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arcmin ag),
						'one' => q(arcmin {0}),
						'other' => q(arcmin {0}),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arcseg ag),
						'one' => q({0} arcseg),
						'other' => q({0} arcseg),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arcseg ag),
						'one' => q({0} arcseg),
						'other' => q({0} arcseg),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(grav ag),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(grav ag),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radiano ag),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radiano ag),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(akre ag),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(akre ag),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(dunam ag),
						'one' => q({0} dunam),
						'other' => q({0} dunam),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(dunam ag),
						'one' => q({0} dunam),
						'other' => q({0} dunam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hegtar ag),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hegtar ag),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(tipẽn² ag),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(tipẽn² ag),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(poregana² ag),
						'one' => q({0} pol²),
						'other' => q({0} pol²),
						'per' => q(pol² ki {0}),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(poregana² ag),
						'one' => q({0} pol²),
						'other' => q({0} pol²),
						'per' => q(pol² ki {0}),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(mẽturo² ag),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(mẽturo² ag),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(milha² ag),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(milha² ag),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(jarda² ag),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(jarda² ag),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(kirate ag),
						'one' => q({0} k),
						'other' => q({0} k),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(kirate ag),
						'one' => q({0} k),
						'other' => q({0} k),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mĩrimol/ritru),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mĩrimol/ritru),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(sẽnto ki),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(sẽnto ki),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(mil ki),
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(mil ki),
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(kupar ‘e/milhão ki),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(kupar ‘e/milhão ki),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(pãntu mase),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(pãntu mase),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100 km ki),
						'one' => q({0} l/100 km ki),
						'other' => q({0} l/100 km ki),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100 km ki),
						'one' => q({0} l/100 km ki),
						'other' => q({0} l/100 km ki),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(ritru ag/km ki),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(ritru ag/km ki),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(milha ag/garỹv ki),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(milha ag/garỹv ki),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(milha ag/gar. ĩmp. ki),
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(milha ag/gar. ĩmp. ki),
						'one' => q({0} mpg imp.),
						'other' => q({0} mpg imp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} L Rj),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O Rp),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} L Rj),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} O Rp),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(byte),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gbit),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gbit),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GByte),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GByte),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kbit),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kbit),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kByte),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kByte),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mbit),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MByte),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MByte),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PByte),
						'one' => q({0} PB),
						'other' => q({0} PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PByte),
						'one' => q({0} PB),
						'other' => q({0} PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tbit),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tbit),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TByte),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TByte),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(sék.),
						'one' => q({0} sék.),
						'other' => q({0} sék. ag),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(sék.),
						'one' => q({0} sék.),
						'other' => q({0} sék. ag),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(kurã ag),
						'one' => q({0} kurã),
						'other' => q({0} kurã ag),
						'per' => q({0}/kurã ki),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(kurã ag),
						'one' => q({0} kurã),
						'other' => q({0} kurã ag),
						'per' => q({0}/kurã ki),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(nék.),
						'one' => q({0} nék.),
						'other' => q({0} nék.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(nék.),
						'one' => q({0} nék.),
						'other' => q({0} nék.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(óra ag),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(óra ag),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(mĩrisigũnu ag),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(mĩrisigũnu ag),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(mĩn),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(mĩn),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(kysã ag),
						'one' => q({0} kysã),
						'other' => q({0} kysã ag),
						'per' => q({0}/kysã ki),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(kysã ag),
						'one' => q({0} kysã),
						'other' => q({0} kysã ag),
						'per' => q({0}/kysã ki),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sig),
						'one' => q({0} sig),
						'other' => q({0} sig),
						'per' => q({0}/s ki),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sig),
						'one' => q({0} sig),
						'other' => q({0} sig),
						'per' => q({0}/s ki),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(simỹnỹ ag),
						'one' => q({0} sim.),
						'other' => q({0} sim.),
						'per' => q({0}/sim. Ki),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(simỹnỹ ag),
						'one' => q({0} sim.),
						'other' => q({0} sim.),
						'per' => q({0}/sim. Ki),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(prỹg ag),
						'one' => q({0} prỹg),
						'other' => q({0} prỹg ag),
						'per' => q({0}/prỹg ki),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(prỹg ag),
						'one' => q({0} prỹg),
						'other' => q({0} prỹg ag),
						'per' => q({0}/prỹg ki),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amps),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amps),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(mĩriamps),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(mĩriamps),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohms),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohms),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(volts),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(volts),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(BTU),
						'one' => q({0} BTU),
						'other' => q({0} BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTU),
						'one' => q({0} BTU),
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
					'energy-joule' => {
						'name' => q(joule ag),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(joule ag),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kirojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kirojoule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kW-óra),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kW-óra),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(thm EUA),
						'one' => q({0} thm EUA),
						'other' => q({0} thm EUA),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(thm EUA),
						'one' => q({0} thm EUA),
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
						'name' => q(rimra-tar),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(rimra-tar),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapixel ag),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapixel ag),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pixel ag),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pixel ag),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(ua k.v.),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ua k.v.),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(mrasa ag),
						'one' => q({0} bça. mrs),
						'other' => q({0} bça. mrs),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(mrasa ag),
						'one' => q({0} bça. mrs),
						'other' => q({0} bça. mrs),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(tipẽn ag),
						'one' => q({0} tipẽn),
						'other' => q({0} tipẽn ag),
						'per' => q({0}/tipẽn ki),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(tipẽn ag),
						'one' => q({0} tipẽn),
						'other' => q({0} tipẽn ag),
						'per' => q({0}/tipẽn ki),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlong ag),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong ag),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(pol.),
						'one' => q({0} pol.),
						'other' => q({0} pol.),
						'per' => q({0}/pol. ki),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(pol.),
						'one' => q({0} pol.),
						'other' => q({0} pol.),
						'per' => q({0}/pol. ki),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(prỹg-jẽngrẽ ag),
						'one' => q({0} prỹg-jẽngrẽ),
						'other' => q({0} prỹg-jẽngrẽ),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(prỹg-jẽngrẽ ag),
						'one' => q({0} prỹg-jẽngrẽ),
						'other' => q({0} prỹg-jẽngrẽ),
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
						'name' => q(milha ag),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milha ag),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(mn),
						'one' => q({0} mn),
						'other' => q({0} mn),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(mn),
						'one' => q({0} mn),
						'other' => q({0} mn),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsec ag),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsec ag),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pãntu ag),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pãntu ag),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(rã nogno),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(rã nogno),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(jarda ag),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(jarda ag),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(jẽngrẽ ag),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(jẽngrẽ ag),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(rã jẽngrẽ ag),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(rã jẽngrẽ ag),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(kirate ag),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(kirate ag),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(dalton ag),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(dalton ag),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(ga-pãgoj ag),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(ga-pãgoj ag),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(grỹmỹ ag),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(grỹmỹ ag),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
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
						'name' => q(rimra ag),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(rimra ag),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(rã-pãgoj ag),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(rã-pãgoj ag),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(pó ag),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(pó ag),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tãnẽrana),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tãnẽrana),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(cv),
						'one' => q({0} cv),
						'other' => q({0} cv),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(cv),
						'one' => q({0} cv),
						'other' => q({0} cv),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(watt ag),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watt ag),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atm),
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atm),
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'one' => q({0} bar),
						'other' => q({0} bar ag),
					},
					# Core Unit Identifier
					'bar' => {
						'one' => q({0} bar),
						'other' => q({0} bar ag),
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
					'speed-knot' => {
						'name' => q(kagje),
						'one' => q({0} kagje),
						'other' => q({0} kagje ag),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(kagje),
						'one' => q({0} kagje),
						'other' => q({0} kagje ag),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(mẽturo ag/seg),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(mẽturo ag/seg),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(milha ag/óra),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(milha ag/óra),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(grav C ag),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(grav C ag),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(grav F ag),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(grav F ag),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(akre-tipẽn ag),
						'one' => q({0} akre-tipẽn),
						'other' => q({0} akre-tipẽn ag),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(akre-tipẽn ag),
						'one' => q({0} akre-tipẽn),
						'other' => q({0} akre-tipẽn ag),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(marir),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(marir),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(tipẽn3 ag),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(tipẽn3 ag),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(poregana³ ag),
						'one' => q({0} pol³),
						'other' => q({0} pol³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(poregana³ ag),
						'one' => q({0} pol³),
						'other' => q({0} pol³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(jarda³ ag),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(jarda³ ag),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(sikara ag),
						'one' => q({0} sik.),
						'other' => q({0} sik.),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(sikara ag),
						'one' => q({0} sik.),
						'other' => q({0} sik.),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(xícm),
						'one' => q({0} xícm),
						'other' => q({0} xícm),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(xícm),
						'one' => q({0} xícm),
						'other' => q({0} xícm),
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
					'volume-fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gar),
						'one' => q({0} gar),
						'other' => q({0} gar),
						'per' => q({0}/gar),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gar),
						'one' => q({0} gar),
						'other' => q({0} gar),
						'per' => q({0}/gar),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gar. imp.),
						'one' => q({0} gar. imp.),
						'other' => q({0} gar. imp.),
						'per' => q({0}/gar. imp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gar. imp.),
						'one' => q({0} gar. imp.),
						'other' => q({0} gar. imp.),
						'per' => q({0}/gar. imp.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(ritru ag),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(ritru ag),
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
					'volume-pint' => {
						'name' => q(pint ag),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pint ag),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(ptm),
						'one' => q({0} ptm),
						'other' => q({0} ptm),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(ptm),
						'one' => q({0} ptm),
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
						'name' => q(kume k.),
						'one' => q({0} kume k.),
						'other' => q({0} kume k.),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(kume k.),
						'one' => q({0} kume k.),
						'other' => q({0} kume k.),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(sa k.),
						'one' => q({0} sa k.),
						'other' => q({0} sa k.),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(sa k.),
						'one' => q({0} sa k.),
						'other' => q({0} sa k.),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:hỹ|h|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:tũ|t|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0} {1}),
				middle => q({0} {1}),
				end => q({0} kar {1}),
				2 => q({0} kar {1}),
		} }
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
			'group' => q(.),
			'infinity' => q(∞),
			'list' => q(;),
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
					'one' => '0 mil',
					'other' => '0 mil',
				},
				'10000' => {
					'one' => '00 mil',
					'other' => '00 mil',
				},
				'100000' => {
					'one' => '000 mil',
					'other' => '000 mil',
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
					'one' => '0 tri',
					'other' => '0 tri',
				},
				'10000000000000' => {
					'one' => '00 tri',
					'other' => '00 tri',
				},
				'100000000000000' => {
					'one' => '000 tri',
					'other' => '000 tri',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 mil',
					'other' => '0 mil',
				},
				'10000' => {
					'one' => '00 mil',
					'other' => '00 mil',
				},
				'100000' => {
					'one' => '000 mil',
					'other' => '000 mil',
				},
				'1000000' => {
					'one' => '0 milhão',
					'other' => '0 milhão ag',
				},
				'10000000' => {
					'one' => '00 milhão',
					'other' => '00 milhão ag',
				},
				'100000000' => {
					'one' => '000 milhão',
					'other' => '000 milhão ag',
				},
				'1000000000' => {
					'one' => '0 bilhão',
					'other' => '0 bilhão ag',
				},
				'10000000000' => {
					'one' => '00 bilhão',
					'other' => '00 bilhão ag',
				},
				'100000000000' => {
					'one' => '000 bilhão',
					'other' => '000 bilhão ag',
				},
				'1000000000000' => {
					'one' => '0 trilhão',
					'other' => '0 trilhão ag',
				},
				'10000000000000' => {
					'one' => '00 trilhão',
					'other' => '00 trilhão ag',
				},
				'100000000000000' => {
					'one' => '000 trilhão',
					'other' => '000 trilhão ag',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 mil',
					'other' => '0 mil',
				},
				'10000' => {
					'one' => '00 mil',
					'other' => '00 mil',
				},
				'100000' => {
					'one' => '000 mil',
					'other' => '000 mil',
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
					'one' => '0 tri',
					'other' => '0 tri',
				},
				'10000000000000' => {
					'one' => '00 tri',
					'other' => '00 tri',
				},
				'100000000000000' => {
					'one' => '000 tri',
					'other' => '000 tri',
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
		'ADP' => {
			display_name => {
				'currency' => q(Ỹnoha Kufy-sĩ),
				'one' => q(Ỹnoha Kufy-sĩ),
				'other' => q(Ỹnoha Kufy-sĩ ag),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(Ẽmĩrano Arame Jãnkamu),
				'one' => q(EAU Jãnkamu),
				'other' => q(EAU Jãnkamu ag),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Afeganĩ \(1927–2002\)),
				'one' => q(Afeganĩtã Afeganĩ \(AFA\)),
				'other' => q(Afeganĩtã Afeganĩ ag \(AFA\)),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Afeganĩ afegỹv),
				'one' => q(Afeganĩ afegỹv),
				'other' => q(Afeganĩ ag afegỹv),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(Arámánja Rég \(1946–1965\)),
				'one' => q(Arámánja Rég \(1946–1965\)),
				'other' => q(Arámánja Rég ag \(1946–1965\)),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(Arámánja Rég),
				'one' => q(Arámánja Rég),
				'other' => q(Arámánja Rég ag),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Arámẽnja Daram),
				'one' => q(Arámẽnja Daram),
				'other' => q(Arámẽnja Daram ag),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Ỹtiria Orỹnesa Kafejsĩ),
				'one' => q(Ỹtiria Orỹnesa Kafejsĩ),
				'other' => q(Ỹtiria Orỹnesa Kafejsĩ ag),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Ỹgora Kwanza),
				'one' => q(Ỹgora Kwanza),
				'other' => q(Ỹgora Kwanza ag),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Ỹgora Cuanza \(1977–1990\)),
				'one' => q(Ỹgora Kwanza \(AOK\)),
				'other' => q(Ỹgora Kwanza ag \(AOK\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Ỹgora cuanza tãg \(1990–2000\)),
				'one' => q(Ỹgora kwanza tãg \(AON\)),
				'other' => q(Ỹgora kwanza tãg ag \(AON\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Ỹgora cuanza ki hynhan ka nĩ \(1990–2000\)),
				'one' => q(Ỹgora kwanza ki hynhan ka nĩ \(AOR\)),
				'other' => q(Ỹgora kwanza ag ki hynhan ka nĩ \(AOR\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Arjẽtinỹ Asufraw),
				'one' => q(Arjẽtinỹ Asufraw),
				'other' => q(Arjẽtinỹ Asufraw ag),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(Arjẽtinỹ Kufy Rej \(1970–1983\)),
				'one' => q(Arjẽtinỹ Kufy Rej \(1970–1983\)),
				'other' => q(Arjẽtinỹ Kufy Rej ag \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(Arjẽtinỹ Kufy \(1881–1970\)),
				'one' => q(Arjẽtinỹ Kufy \(1881–1970\)),
				'other' => q(Arjẽtinỹ Kufy ag \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Arjẽtinỹ Kufy \(1983–1985\)),
				'one' => q(Arjẽtinỹ Kufy \(1983–1985\)),
				'other' => q(Arjẽtinỹ Kufy ag \(1983–1985\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Arjẽtinỹ Kufy // Arjẽntĩnỹ Kufy),
				'one' => q(Arjẽtinỹ Kufy),
				'other' => q(Arjẽtinỹ Kufy ag),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Agtirija Serĩm),
				'one' => q(Agtirija Serĩm),
				'other' => q(Agtirija Serĩm ag),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(Awotyraria Nórar Si),
				'one' => q(Awotyraria Nórar Si),
				'other' => q(Awotyraria Nórar Si ag),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Aruma Kafejsĩ),
				'one' => q(Aruma Kafejsĩ),
				'other' => q(Aruma Kafejsĩ ag),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Ajermajjáv Manati \(1993–2006\)),
				'one' => q(Ajermajjáv Manati \(1993–2006\)),
				'other' => q(Ajermajjáv Manati ag \(1993–2006\)),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Manati aseri),
				'one' => q(Manati aseri),
				'other' => q(Manati aseri ag),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Mósinĩja-Hersegovĩna Ninỹ \(1992–1994\)),
				'one' => q(Mósinĩja-Hersegovĩna Ninỹ),
				'other' => q(Mósinĩja-Hersegovĩna Ninỹ ag),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Mósinĩja Hersegovĩna-mré Mỹrko ta ũn há),
				'one' => q(Mósinĩja Hersegovĩna-mré Mỹrko ta ũn há),
				'other' => q(Mósinĩja Hersegovĩna-mré Mỹrko ag ta ũn há),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(Mósinĩja-Hersegovĩna Ninỹ Tãg \(1994–1997\)),
				'one' => q(Mósinĩja-Hersegovĩna Ninỹ Tãg),
				'other' => q(Mósinĩja-Hersegovĩna Ninỹ Tãg ag),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Juvã-mág Nórar),
				'one' => q(Juvã-mág Nórar),
				'other' => q(Juvã-mág Nórar ag),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Mágranési Taka),
				'one' => q(Mágranési Taka),
				'other' => q(Mágranési Taka ag),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Mérjika Vĩpir \(conv\)),
				'one' => q(Mérjika Vĩpir \(conv\)),
				'other' => q(Mérjika Vĩpir ag \(conv\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Mérjika Vĩpir),
				'one' => q(Mérjika Vĩpir),
				'other' => q(Mérjika Vĩpir ag),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Mérjika Vĩpir \(financ\)),
				'one' => q(Mérjika Vĩpir \(financ\)),
				'other' => q(Mérjika Vĩpir ag \(financ\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Mugarja Rev Tar),
				'one' => q(Mugarja Rev Tar),
				'other' => q(Mugarja Rev Tar ag),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(Mugarja Ver kynkar),
				'one' => q(Mugarja Ver kynkar),
				'other' => q(Mugarja Ver kynkar ag),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Mugarja Rev),
				'one' => q(Mugarja Rev),
				'other' => q(Mugarja Rev ag),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(Mugarja Rev \(1879–1952\)),
				'one' => q(Mugarja Rev \(1879–1952\)),
				'other' => q(Mugarja Rev ag \(1879–1952\)),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Marẽnh Ninỹ),
				'one' => q(Marẽnh Ninỹ),
				'other' => q(Marẽnh Ninỹ ag),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Murũni Vĩpir),
				'one' => q(Murũni Vĩpir),
				'other' => q(Murũni Vĩpir ag),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Karsa-ror-ag Nórar),
				'one' => q(Karsa-ror-ag Nórar),
				'other' => q(Karsa-ror-ag Nórar ag),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Mrunẽj Nórar),
				'one' => q(Mrunẽj Nórar),
				'other' => q(Mrunẽj Nórar ag),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Morivija Jãnkamu),
				'one' => q(Morivija Jãnkamu),
				'other' => q(Morivija Jãnkamu ag),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(Morivijanũ \(1863–1963\)),
				'one' => q(Morivijanũ \(1863–1963\)),
				'other' => q(Morivijanũ ag \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Morivija Kufy),
				'one' => q(Morivija Kufy),
				'other' => q(Morivija Kufy ag),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Morivija Munór),
				'one' => q(Morivija Munór),
				'other' => q(Morivija Munór ag),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Mrasir Krujeru Tãg \(1967–1986\)),
				'one' => q(Mrasir Krujeru Tãg \(BRB\)),
				'other' => q(Mrasir Krujeru Tãg ag \(BRB\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Mrasir Krusanu \(1986–1989\)),
				'one' => q(Mrasir Krusanu),
				'other' => q(Mrasir Krusanu ag),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Mrasir Krujeru \(1990–1993\)),
				'one' => q(Mrasir Krujeru \(BRE\)),
				'other' => q(Mrasir Krujeru ag \(BRE\)),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Mrasir Rejar),
				'one' => q(Mrasir Rejar),
				'other' => q(Mrasir Rejar ag),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Mrasir Krusanu Tãg \(1989–1990\)),
				'one' => q(Mrasir Krusanu Tãg),
				'other' => q(Mrasir Krusanu Tãg ag),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Mrasir Krujeru \(1993–1994\)),
				'one' => q(Mrasir Krujeru),
				'other' => q(Mrasir Krujeru ag),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(Mrasir Krujeru \(1942–1967\)),
				'one' => q(Mrasir Krujeru Si),
				'other' => q(Mrasir Krujeru Si ag),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Mahamỹ Nórar),
				'one' => q(Mahamỹ Nórar),
				'other' => q(Mahamỹ Nórar ag),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Butỹ Guturũm),
				'one' => q(Butỹ Guturũm),
				'other' => q(Butỹ Guturũm ag),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Mirmỹnja Kyate),
				'one' => q(Mirmỹnja Kyate),
				'other' => q(Mirmỹnja Kyate ag),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Monsuvỹnỹ Pura),
				'one' => q(Monsuvỹnỹ Pura),
				'other' => q(Monsuvỹnỹ Pura ag),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Miero-Husija Humro Tãg \(1994–1999\)),
				'one' => q(Miero-Husija Humro Tãg \(BYB\)),
				'other' => q(Miero-Husija Humro Tãg ag \(BYB\)),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(Miero-Husija Humro),
				'one' => q(Miero-Husija Humro),
				'other' => q(Miero-Husija Humro ag),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Miero-Husija Humro \(2000–2016\)),
				'one' => q(Miero-Husija Humro \(2000–2016\)),
				'other' => q(Miero-Husija Humro ag \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Merise Nórar),
				'one' => q(Merise Nórar),
				'other' => q(Merise Nórar ag),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Kanỹna Nórar),
				'one' => q(Kanỹna Nórar),
				'other' => q(Kanỹna Nórar ag),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Kãgu Vĩpir),
				'one' => q(Kãgu Vĩpir),
				'other' => q(Kãgu Vĩpir ag),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR Evoro),
				'one' => q(WIR Evoro),
				'other' => q(WIR Evoro ag),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Suvisa Vĩpir),
				'one' => q(Suvisa Vĩpir),
				'other' => q(Suvisa Vĩpir ag),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR Vĩpir),
				'one' => q(WIR Vĩpir),
				'other' => q(WIR Vĩpir ag),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(Sire Vẽjuven),
				'one' => q(Sire Vẽjuven),
				'other' => q(Sire Vẽjuven ag),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Sirenũ ag vẽnhkãmur ũ),
				'one' => q(Sirenũ vẽnhkãmur ũ),
				'other' => q(Sirenũ ag vẽnhkãmur ũ ag),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Sire Kufy),
				'one' => q(Sire Kufy),
				'other' => q(Sire Kufy ag),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(Sĩnỹ Yvỹn \(offshore\)),
				'one' => q(Sĩnỹ Yuãn \(offshore\)),
				'other' => q(Sĩnỹ Yuãn ag \(offshore\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(Nórar vẽnhkar mỹ máko mĩ Sĩnỹ tá),
				'one' => q(Nórar vẽnhkar mỹ máko mĩ Sĩnỹ tá),
				'other' => q(Nórar vẽnhkar mỹ máko mĩ Sĩnỹ tá ag),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Sĩnỹ Yvỹn),
				'one' => q(Sĩnỹ Yvỹn),
				'other' => q(Sĩnỹ Yvỹn ag),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Kolãmja Kufy),
				'one' => q(Kolãmja Kufy),
				'other' => q(Kolãmja Kufy ag),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(Vẽnhkãmun ũ kaja uri),
				'one' => q(Vẽnhkãmun ũ kaja uri),
				'other' => q(Vẽnhkãmun-mun ũ kaja uri ag),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Kotahika Korãn),
				'one' => q(Kotahika Korãn),
				'other' => q(Kotahika Korãn ag),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Sérvija Ninỹ \(2002–2006\)),
				'one' => q(Sérvija Ninỹ Si),
				'other' => q(Sérvija Ninỹ Si ag),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Sékorovaka Rãgre Tar),
				'one' => q(Coroa forte tchecoslovaca),
				'other' => q(Sékorovaka Rãgre Tar ag),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Kuma Kufy conv),
				'one' => q(Kuma Kufy conv),
				'other' => q(Kuma Kufy ag conv),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Kuma Kufy),
				'one' => q(Kuma Kufy),
				'other' => q(Kuma Kufy ag),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Pu-Tánh Vẽjuven),
				'one' => q(Pu-Tánh Vẽjuven),
				'other' => q(Pu-Tánh Vẽjuven ag),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Sipre Rimra),
				'one' => q(Sipre Rimra),
				'other' => q(Sipre Rimra ag),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Séka Rãgre),
				'one' => q(Séka Rãgre),
				'other' => q(Séka Rãgre ag),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Aremỹja Rãjur tá Jãnkamu),
				'one' => q(Aremỹja Rãjur tá Jãnkamu),
				'other' => q(Aremỹja Rãjur tá Jãnkamu ag),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Aremỹnhỹ Mỹrko),
				'one' => q(Aremỹnhỹ Mỹrko),
				'other' => q(Aremỹnhỹ Mỹrko ag),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Nhimuti Vĩpir),
				'one' => q(Nhimuti Vĩpir),
				'other' => q(Nhimuti Vĩpir ag),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Ninỹmỹrka Rãgre),
				'one' => q(Ninỹmỹrka Rãgre),
				'other' => q(Ninỹmỹrka Rãgre ag),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Nomĩnĩka Kufy),
				'one' => q(Nomĩnĩka Kufy),
				'other' => q(Nomĩnĩka Kufy ag),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Argerija Ninỹ),
				'one' => q(Argerija Ninỹ),
				'other' => q(Argerija Ninỹ ag),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Ekuvanor Sukri),
				'one' => q(Ekuvanor Sukri),
				'other' => q(Ekuvanor Sukri ag),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Ekuvanor UVC),
				'one' => q(UVC tỹ Ekuvanor),
				'other' => q(UVC ag tỹ Ekuvanor),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Enhtonĩja Rãgre),
				'one' => q(Enhtonĩja Rãgre),
				'other' => q(Enhtonĩja Rãgre ag),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Ejimto Rimra),
				'one' => q(Ejimto Rimra),
				'other' => q(Ejimto Rimra ag),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Eriteréja Nagfa),
				'one' => q(Eriteréja Nagfa),
				'other' => q(Eriteréja Nagfa ag),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(Esipỹnja Kufy-sĩ \(kãtá A\)),
				'one' => q(Esipỹnja Kufy-sĩ \(kãtá A\)),
				'other' => q(Esipỹnja Kufy-sĩ ag \(kãtá A\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(Esipỹnja Kufy-sĩ \(kãtá conv\)),
				'one' => q(Esipỹnja Kufy-sĩ \(kãtá conv\)),
				'other' => q(Esipỹnja Kufy-sĩ ag \(kãtá conv\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Esipỹnja Kufy-sĩ),
				'one' => q(Esipỹnja Kufy-sĩ),
				'other' => q(Esipỹnja Kufy-sĩ ag),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Etiópija Mir),
				'one' => q(Etiópija Mir),
				'other' => q(Etiópija Mir ag),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Evoro),
				'one' => q(Evoro),
				'other' => q(Evoro ag),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Fĩrỹnija Mỹrka),
				'one' => q(Fĩrỹnija Mỹrka),
				'other' => q(Fĩrỹnija Mỹrka’a),
			},
		},
		'FJD' => {
			symbol => 'FJC',
			display_name => {
				'currency' => q(Fiji Nórar),
				'one' => q(Fiji Nórar),
				'other' => q(Fiji Nórar ag),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Mỹrvinỹ Rimra),
				'one' => q(Mỹrvinỹ Rimra),
				'other' => q(Mỹrvinỹ Rimra ag),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Frỹsa Vĩpir),
				'one' => q(Frỹsa Vĩpir),
				'other' => q(Frỹsa Vĩpir ag),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Rimra Eterĩnỹ),
				'one' => q(Rimra Eterĩnỹ),
				'other' => q(Rimra Eterĩnỹ asg),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Jiórja Kupãni Rari),
				'one' => q(Jiórja Kupãni Rari),
				'other' => q(Jiórja Kupãni Rari ag),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Jiórja Rari),
				'one' => q(Jiórja Rari),
				'other' => q(Jiórja Rari ag),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Gỹnỹ Senhi \(1979–2007\)),
				'one' => q(Gỹnỹ Senhi \(1979–2007\)),
				'other' => q(Gỹnỹ Senhi ag \(1979–2007\)),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Gỹnỹ Senhi),
				'one' => q(Gỹnỹ Senhi),
				'other' => q(Gỹnỹ Senhi ag),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Nhimratar Rimra),
				'one' => q(Nhimratar Rimra),
				'other' => q(Nhimratar Rimra ag),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Gỹmija Narasi),
				'one' => q(Gỹmija Narasi),
				'other' => q(Gỹmija Narasi ag),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(Ginẽ Vĩpir),
				'one' => q(Ginẽ Vĩpir),
				'other' => q(Ginẽ Vĩpir ag),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Ginẽ Syri),
				'one' => q(Ginẽ Syri),
				'other' => q(Ginẽ Syri ag),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Ginẽ Ekuvanor Ekuvele),
				'one' => q(Ginẽ Ekuvanor Ekuvele),
				'other' => q(Ginẽ Ekuvanor Ekuvele ag),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Grésija Narakymỹ),
				'one' => q(Grésija Narakymỹ),
				'other' => q(Grésija Narakymỹ ag),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Guvỹtemỹra Kensav),
				'one' => q(Guvỹtemỹra Kensav),
				'other' => q(Guvỹtemỹra Kensav ag),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Fóg tỹ Ginẽ Vẽjuven),
				'one' => q(Fóg tỹ Ginẽ Vẽjuven),
				'other' => q(Fóg tỹ Ginẽ Vẽjuven ag),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Ginẽ-Misav Kufy),
				'one' => q(Ginẽ-Misav Kufy),
				'other' => q(Ginẽ-Misav Kufy ag),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Gijỹnỹ Nórar),
				'one' => q(Gijỹnỹ Nórar),
				'other' => q(Gijỹnỹ Nórar ag),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Hãg-Kãg Nórar),
				'one' => q(Hãg-Kãg Nórar),
				'other' => q(Hãg-Kãg Nórar ag),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Ãnura Rẽpirá),
				'one' => q(Ãnura Rẽpirá),
				'other' => q(Ãnura Rẽpirá ag),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Krovasija Ninỹ),
				'one' => q(Krovasija Ninỹ),
				'other' => q(Krovasija Ninỹ ag),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Krovasija Kuna),
				'one' => q(Krovasija Kuna),
				'other' => q(Krovasija Kuna ag),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Ajti Runja),
				'one' => q(Ajti Runja),
				'other' => q(Ajti Runja ag),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Ũgrija Kafejsĩ),
				'one' => q(Ũgrija Kafejsĩ),
				'other' => q(Ũgrija Kafejsĩ ag),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Ĩnonẽsija Rupija),
				'one' => q(Ĩnonẽsija Rupija),
				'other' => q(Ĩnonẽsija Rupija ag),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Irỹna Rimra),
				'one' => q(Irỹna Rimra),
				'other' => q(Irỹna Rimra ag),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Isihaé Rimra),
				'one' => q(Isihaé Rimra),
				'other' => q(Isihaé Rimra ag),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(Isihaé Sekév Si),
				'one' => q(Isihaé Sekév Si),
				'other' => q(Isihaé Sekév Si ag),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(Isihaé Sekév Tãg),
				'one' => q(Isihaé Sekév Tãg),
				'other' => q(Isihaé Sekév Tãg ag),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Ĩnija Rupija),
				'one' => q(Ĩnija Rupija),
				'other' => q(Ĩnija Rupija ag),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Iraki Ninỹ),
				'one' => q(Iraki Ninỹ),
				'other' => q(Iraki Ninỹ ag),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Irỹ Hi’av),
				'one' => q(Irỹ Hi’av),
				'other' => q(Irỹ Hi’av ag),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(Kukryr-ga Rãgre Si),
				'one' => q(Kukryr-ga Rãgre Si),
				'other' => q(Kukryr-ga Rãgre Si ag),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(Kukryr-ga Rãgre),
				'one' => q(Kukryr-ga Rãgre),
				'other' => q(Kukryr-ga Rãgre ag),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Itarija Rira),
				'one' => q(Itarija Rira),
				'other' => q(Itarija Rira ag),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Jamỹjka Nórar),
				'one' => q(Jamỹjka Nórar),
				'other' => q(Jamỹjka Nórar ag),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Jornánĩja Ninỹ),
				'one' => q(Jornánĩja Ninỹ),
				'other' => q(Jornánĩja Ninỹ ag),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Japã Jenẽ),
				'one' => q(Japã Jenẽ),
				'other' => q(Japã Jenẽ ag),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Kẽnja Serĩm),
				'one' => q(Kẽnja Serĩm),
				'other' => q(Kẽnja Serĩm ag),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Kirgi-Ga Kyr),
				'one' => q(Kirgi-Ga Kyr),
				'other' => q(Kirgi-Ga Kyr ag),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Kỹmósa Hijév),
				'one' => q(Kỹmósa Hijév),
				'other' => q(Kỹmósa Hijév ag),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Komor Vĩpir),
				'one' => q(Komor Vĩpir),
				'other' => q(Komor Vĩpir ag),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Nãrti-Koréja Vãn),
				'one' => q(Nãrti-Koréja Vãn),
				'other' => q(Nãrti-Koréja Vãn sag),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(Koréja Sur Huvỹ \(1953–1962\)),
				'one' => q(Koréja Sur Huvỹ),
				'other' => q(Koréja Sur Huvỹ ag),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(Koréja Sur Vãn \(1945–1953\)),
				'one' => q(Koréja Sur Vãn Si),
				'other' => q(Koréja Sur Vãn Si ag),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Koréja Sur Vãn),
				'one' => q(Koréja Sur Vãn),
				'other' => q(Koréja Sur Vãn ag),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Kuvajti Ninỹ),
				'one' => q(Kuvajti Ninỹ),
				'other' => q(Kuvajti Ninỹ ag),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Kanhmỹ Vãsogso Nórar),
				'one' => q(Kanhmỹ Vãsogso Nórar),
				'other' => q(Kanhmỹ Vãsogso Nórar ag),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Kajakinhtỹv Tẽge),
				'one' => q(Kajakinhtỹv Tẽge),
				'other' => q(Kajakinhtỹv Tẽge ag),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Ravusi Kim),
				'one' => q(Ravusi Kim),
				'other' => q(Ravusi Kim ag),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Rimanũ Rimra),
				'one' => q(Rimanũ Rimra),
				'other' => q(Rimanũ Rimra ag),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Sirijỹká Rupija),
				'one' => q(Sirijỹká Rupija),
				'other' => q(Sirijỹká Rupija ag),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Rimérijỹ Nórar),
				'one' => q(Rimérijỹ Nórar),
				'other' => q(Rimérijỹ Nórar ag),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Resotu Roti),
				'one' => q(Resotu Roti),
				'other' => q(Resotu Roti ag),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Rituvỹnja Ritasi),
				'one' => q(Rituvỹnja Ritasi),
				'other' => q(Rituvỹnja Ritasi ag),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Rituvỹnja Taronỹ),
				'one' => q(Rituvỹnja Taronỹ),
				'other' => q(Rituvỹnja Taronỹ ag),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Rusẽmurgo Vĩpir conv.),
				'one' => q(Rusẽmurgo Vĩpir conv.),
				'other' => q(Rusẽmurgo Vĩpir ag conv.),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Rusẽmurgo Vĩpir),
				'one' => q(Rusẽmurgo Vĩpir),
				'other' => q(Rusẽmurgo Vĩpir ag),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Rusẽmurgo Vĩpir Jãnkamu),
				'one' => q(Rusẽmurgo Vĩpir Jãnkamu),
				'other' => q(Rusẽmurgo Vĩpir Jãnkamu ag),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Rativija Rati),
				'one' => q(Rativija Rati),
				'other' => q(Rativija Rati ag),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Rativija Humro),
				'one' => q(Rativija Humro),
				'other' => q(Rativija Humro ag),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Rimija Ninỹ),
				'one' => q(Rimija Ninỹ),
				'other' => q(Rimija Ninỹ ag),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Ar-Magrim Nirham),
				'one' => q(Ar-Magrim Nirham),
				'other' => q(Ar-Magrim Nirham ag),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Ar-Magrim Vĩpir),
				'one' => q(Ar-Magrim Vĩpir),
				'other' => q(Ar-Magrim Vĩpir ag),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(Mõnỹku Vĩpir),
				'one' => q(Mõnỹku Vĩpir),
				'other' => q(Mõnỹku Vĩpir ag),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(Mãrnova Kopã),
				'one' => q(Mãrnova Kopã),
				'other' => q(Mãrnova Kopã ag),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Mãrnova Revu),
				'one' => q(Mãrnova Revu),
				'other' => q(Mãrnova Revu ag),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Mỹna-Gasikar Ari-ary),
				'one' => q(Mỹna-Gasikar Ari-ary),
				'other' => q(Mỹna-Gasikar Ari-ary ag),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Mỹna-Gasikar Vĩpir),
				'one' => q(Mỹna-Gasikar Vĩpir),
				'other' => q(Mỹna-Gasikar Vĩpir ag),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Mỹsenonĩja Ninỹ),
				'one' => q(Mỹsenonĩja Ninỹ),
				'other' => q(Mỹsenonĩja Ninỹ ag),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(Mỹsenonĩja Ninỹ \(1992–1993\)),
				'one' => q(Mỹsenonĩja Ninỹ \(1992–1993\)),
				'other' => q(Mỹsenonĩja Ninỹ ag \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Mỹri Vĩpir),
				'one' => q(Mỹri Vĩpir),
				'other' => q(Mỹri Vĩpir ag),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Mijẽn-Mỹ Kijate),
				'one' => q(Mijẽn-Mỹ Kijate),
				'other' => q(Mijẽn-Mỹ Kijate ag),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Mãgórija Tugrig),
				'one' => q(Mãgórija Tugrig),
				'other' => q(Mãgórija Tugrig ag),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Mỹkav Pataka),
				'one' => q(Mỹkav Pataka),
				'other' => q(Mỹkav Pataka ag),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(Mũritỹni Ov-Gija \(1973–2017\)),
				'one' => q(Mũritỹni Ov-Gija \(1973–2017\)),
				'other' => q(Mũritỹni Ov-Gija ag \(1973–2017\)),
			},
		},
		'MRU' => {
			symbol => 'MRU',
			display_name => {
				'currency' => q(Mũritỹni Ov-Gija),
				'one' => q(Mũritỹni Ov-Gija),
				'other' => q(Mũritỹni Ov-Gija ag),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Mỹrta Rirá),
				'one' => q(Mỹrta Rirá),
				'other' => q(Mỹrta Rirá ag),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Mỹrta Rimra),
				'one' => q(Mỹrta Rimra),
				'other' => q(Mỹrta Rimra ag),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Mãriso Rupija),
				'one' => q(Mãriso Rupija),
				'other' => q(Mãriso Rupija ag),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Mỹrniva Rupija),
				'one' => q(Mỹrniva Rupija),
				'other' => q(Mỹrniva Rupija ag),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Mỹravi Kuvasa),
				'one' => q(Mỹravi Kuvasa),
				'other' => q(Mỹravi Kuvasa ag),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(Mẽsiku Kufy),
				'one' => q(Mẽsiku Kufy),
				'other' => q(Mẽsiku Kufy ag),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Mẽsiku Kufy Kupri \(1861–1992\)),
				'one' => q(Mẽsiku Kufy Kupri \(1861–1992\)),
				'other' => q(Mẽsiku Kufy Kupri ag \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Mẽsiku Pir Rãg \(UDI\)),
				'one' => q(Mẽsiku Pir Rãg \(UDI\)),
				'other' => q(Mẽsiku Pir Rãg ag \(UDI\)),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Mỹraja Rĩggin),
				'one' => q(Mỹraja Rĩggin),
				'other' => q(Mỹraja Rĩggin ag),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Mãsỹmiki Vẽjuven),
				'one' => q(Mãsỹmiki Vẽjuven),
				'other' => q(Mãsỹmiki Vẽjuven ag),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mãsỹmiki Mẽtikar \(1980–2006\)),
				'one' => q(Mãsỹmiki Mẽtikar Si),
				'other' => q(Mãsỹmiki Mẽtikar Si ag),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Mãsỹmiki Mẽtikar),
				'one' => q(Mãsỹmiki Mẽtikar),
				'other' => q(Mãsỹmiki Mẽtikar ag),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Nỹmĩmija Nórar),
				'one' => q(Nỹmĩmija Nórar),
				'other' => q(Nỹmĩmija Nórar ag),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Nĩjérija Nỹjra),
				'one' => q(Nĩjérija Nỹjra),
				'other' => q(Nĩjérija Nỹjra ag),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Nĩkaraguva Kórnoma \(1988–1991\)),
				'one' => q(Nĩkaraguva Kórnoma \(1988–1991\)),
				'other' => q(Nĩkaraguva Kórnoma ag \(1988–1991\)),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Nĩkaraguva Kórnoma),
				'one' => q(Nĩkaraguva Kórnoma),
				'other' => q(Nĩkaraguva Kórnoma ag),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Orỹna Kafejsĩ),
				'one' => q(Orỹna Kafejsĩ),
				'other' => q(Orỹna Kafejsĩ ag),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Nãrovéga Rãgre),
				'one' => q(Nãrovéga Rãgre),
				'other' => q(Nãrovéga Rãgre ag),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Nẽpar Rupija),
				'one' => q(Nẽpar Rupija),
				'other' => q(Nẽpar Rupija ag),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Zirỹnija Tãg Nórar),
				'one' => q(Zirỹnija Tãg Nórar),
				'other' => q(Zirỹnija Tãg Nórar ag),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Omỹ Hijar),
				'one' => q(Omỹ Hijar),
				'other' => q(Omỹ Hijar ag),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Panỹmỹ Mavo-Mova),
				'one' => q(Panỹmỹ Mavo-Mova),
				'other' => q(Panỹmỹ Mavo-Mova ag),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Peru Ĩnti),
				'one' => q(Peru Ĩnti),
				'other' => q(Peru Ĩnti ag),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Peru Rã Tãg),
				'one' => q(Peru Rã Tãg),
				'other' => q(Peru Rã Tãg ag),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Peru Rã \(1863–1965\)),
				'one' => q(Peru Rã \(1863–1965\)),
				'other' => q(Peru Rã ag \(1863–1965\)),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Papuva Kinỹ),
				'one' => q(Papuva Kinỹ),
				'other' => q(Papuva Kinỹ ag),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Firipinỹ Kufy),
				'one' => q(Firipinỹ Kufy),
				'other' => q(Firipinỹ Kufy ag),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Pakinhtỹv Rupiya),
				'one' => q(Pakinhtỹv Rupiya),
				'other' => q(Pakinhtỹv Rupiya ag),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Poronĩja Rẽrĩr),
				'one' => q(Poronĩja Rẽrĩr),
				'other' => q(Poronĩja Rẽrĩr ag),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Poronĩja Rẽrĩr \(1950–1995\)),
				'one' => q(Poronĩja Rẽrĩr \(1950–1995\)),
				'other' => q(Poronĩja Rẽrĩr ag \(1950–1995\)),
			},
		},
		'PTE' => {
			symbol => 'Vẽj.',
			display_name => {
				'currency' => q(Purutuga Vẽjuven),
				'one' => q(Purutuga Vẽjuven),
				'other' => q(Purutuga Vẽjuven ag),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Paraguvaj Garnĩ),
				'one' => q(Paraguvaj Garnĩ),
				'other' => q(Paraguvaj Garnĩ ag),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Katar Hijar),
				'one' => q(Katar Hijar),
				'other' => q(Katar Hijar ag),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Ronésija Nórar),
				'one' => q(Ronésija Nórar),
				'other' => q(Ronésija Nórar ag),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Romẽnija Rev \(1952–2006\)),
				'one' => q(Romẽnija Rev Si),
				'other' => q(Romẽnija Rev Si ag),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Romẽnija Rev),
				'one' => q(Romẽnija Rev),
				'other' => q(Romẽnija Rev ag),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Séruvija Ninỹ),
				'one' => q(Séruvija Ninỹ),
				'other' => q(Séruvija Ninỹ ag),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Husija Humro),
				'one' => q(Husija Humro),
				'other' => q(Husija Humro ag),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Husija Humro \(1991–1998\)),
				'one' => q(Husija Humro \(1991–1998\)),
				'other' => q(Husija Humro ag \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Huvỹna Vĩpir),
				'one' => q(Huvỹna Vĩpir),
				'other' => q(Huvỹna Vĩpir ag),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Aramija Savnita Hijar),
				'one' => q(Aramija Savnita Hijar),
				'other' => q(Aramija Savnita Hijar ag),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Saromỹ Vẽsogso Nórar),
				'one' => q(Saromỹ Vẽsogso Nórar),
				'other' => q(Saromỹ Vẽsogso Nórar ag),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Sejséri Rupija),
				'one' => q(Sejséri Rupija),
				'other' => q(Sejséri Rupija ag),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Suná Ninỹ \(1992–2007\)),
				'one' => q(Suná Ninỹ Si),
				'other' => q(Suná Ninỹ Si ag),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Suná Rimbra),
				'one' => q(Suná Rimbra),
				'other' => q(Suná Rimbra ag),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Suná Rimbra \(1957–1998\)),
				'one' => q(Suná Rimbra Si),
				'other' => q(Suná Rimbra Si ag),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Suvésija Rãgre),
				'one' => q(Suvésija Rãgre),
				'other' => q(Suvésija Rãgre ag),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Sĩgapur Nórar),
				'one' => q(Sĩgapur Nórar),
				'other' => q(Sĩgapur Nórar ag),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Sỹta Herenỹ Rimra),
				'one' => q(Sỹta Herenỹ Rimra),
				'other' => q(Sỹta Herenỹ Rimra ag),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Enhrovenĩja Torar Há),
				'one' => q(Enhrovenĩja Torar),
				'other' => q(Enhrovenĩja Tora ag),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Enhrovakija Rãgre),
				'one' => q(Enhrovakija Rãgre),
				'other' => q(Enhrovakija Rãgre ag),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Krĩ Mĩgkusũg-fi Re’onĩ),
				'one' => q(Krĩ Mĩgkusũg-fi Re’onĩ),
				'other' => q(Krĩ Mĩgkusũg-fi Re’onĩ ag),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Somỹrija Serĩm),
				'one' => q(Somỹrija Serĩm),
				'other' => q(Somỹrija Serĩm ag),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Surinỹm Nórar),
				'one' => q(Surinỹm Nórar),
				'other' => q(Surinỹm Nórar ag),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Surinỹm Kafejsĩ),
				'one' => q(Surinỹm Kafejsĩ),
				'other' => q(Surinỹm Kafejsĩ ag),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Suná-Sur Rimra),
				'one' => q(Suná-Sur Rimra),
				'other' => q(Suná-Sur Rimra ag),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(Sỹtomẽ Prĩsipi-mré Nómra \(1977–2017\)),
				'one' => q(Sỹtomẽ Prĩsipi-mré Nómra \(1977–2017\)),
				'other' => q(Sỹtomẽ Prĩsipi-mré Nómra ag \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(Sỹtomẽ Prĩsipi-mré Nómra),
				'one' => q(Sỹtomẽ Prĩsipi-mré Nómra),
				'other' => q(Sỹtomẽ Prĩsipi-mré Nómra ag),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Sovijéti Humro),
				'one' => q(Sovijéti Humro),
				'other' => q(Sovijéti Humro ag),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Er Sarvanor Korãn),
				'one' => q(Er Sarvanor Korãn),
				'other' => q(Er Sarvanor Korãn ag),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Sirija Rimra),
				'one' => q(Sirija Rimra),
				'other' => q(Sirija Rimra ag),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Suvasi-Ga Rirỹgenĩ),
				'one' => q(Suvasi-Ga Rirỹgenĩ),
				'other' => q(Suvasi-Ga Rirỹgenĩ ag),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Taj-Ga Mati),
				'one' => q(Taj-Ga Mati),
				'other' => q(Taj-Ga Mati ag),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tanijikinhtỹv Humro),
				'one' => q(Tanijikinhtỹv Humro),
				'other' => q(Tanijikinhtỹv Humro ag),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Tanijikinhtỹv Somãnĩ),
				'one' => q(Tanijikinhtỹv Somãnĩ),
				'other' => q(Tanijikinhtỹv Somãnĩ ag),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Turkomẽnisitỹ Manati \(1993–2009\)),
				'one' => q(Turkomẽnisitỹ Manati \(1993–2009\)),
				'other' => q(Turkomẽnisitỹ Manati ag \(1993–2009\)),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Tukomẽnũ Manati),
				'one' => q(Tukomẽnũ Manati),
				'other' => q(Tukomẽnũ Manati ag),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Tunĩsija Ninỹ),
				'one' => q(Tunĩsija Ninỹ),
				'other' => q(Tunĩsija Ninỹ ag),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Tãga Pa’ỹga),
				'one' => q(Tãga Pa’ỹga),
				'other' => q(Tãga Pa’ỹga ag),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Timor Vẽjuven),
				'one' => q(Timor Vẽjuven),
				'other' => q(Timor Vẽjuven ag),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Turkija Rira \(1922–2005\)),
				'one' => q(Turkija Rira Si),
				'other' => q(Turkija Rira Si ag),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Turkija Rira),
				'one' => q(Turkija Rira),
				'other' => q(Turkija Rira ag),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Tirinĩna Tomago-mré Nórar),
				'one' => q(Tirinĩna Tomago-mré Nórar),
				'other' => q(Tirinĩna Tomago-mré Nórar ag),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Tajvỹ Nórar Tãg),
				'one' => q(Tajvỹ Nórar Tãg),
				'other' => q(Tajvỹ Nórar Tãg ag),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Tỹnjỹnĩja Serĩm),
				'one' => q(Tỹnjỹnĩja Serĩm),
				'other' => q(Tỹnjỹnĩja Serĩm ag),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Ukrỹnĩja Hyryvinja),
				'one' => q(Ukrỹnĩja Hyryvinja),
				'other' => q(Ukrỹnĩja Hyryvinja ag),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Ukrỹnĩja Karbovanẽ),
				'one' => q(Ukrỹnĩja Karbovanẽ),
				'other' => q(Ukrỹnĩja Karbovanẽ ag),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Ugỹna Serĩm \(1966–1987\)),
				'one' => q(Serĩm tỹ Ugỹna \(1966–1987\)),
				'other' => q(Serĩm tỹ Ugỹna ag \(1966–1987\)),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Ugỹna Serĩm),
				'one' => q(Ugỹna Serĩm),
				'other' => q(Ugỹna Serĩm ag),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(Nãrti-Amẽrikỹ Nórar),
				'one' => q(Nãrti-Amẽrikỹ Nórar),
				'other' => q(Nãrti-Amẽrikỹ Nórar ag),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(Nãrti-Amẽrikỹ Nórar \(kurã ũ kã\)),
				'one' => q(Nórar Amẽrikỹn \(kurã ũ kã\)),
				'other' => q(Nórar Amẽrikỹn ag \(kurã ũ kã\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(Nãrti-Amẽrikỹ Nórar \(kurã hã\)),
				'one' => q(Nórar Amẽrikỹn \(kurã hã\)),
				'other' => q(Nórar Amẽrikỹn ag \(kurã hã\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(Uruguvaj Kufy vẽkãmur ũ),
				'one' => q(Uruguvaj Kufy vẽkãmur ũ),
				'other' => q(Uruguvaj Kufy vẽkãmur ũ ag),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Uruguvaj Kufy \(1975–1993\)),
				'one' => q(Uruguvaj Kufy \(1975–1993\)),
				'other' => q(Uruguvaj Kufy ag \(1975–1993\)),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Uruguvaj Kufy),
				'one' => q(Uruguvaj Kufy),
				'other' => q(Uruguvaj Kufy ag),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(Unhmekinhtỹv Kyr),
				'one' => q(Unhmekinhtỹv Kyr),
				'other' => q(Unhmekinhtỹv Kyr ag),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Venẽjuvéra Morivar \(1871–2008\)),
				'one' => q(Venẽjuvéra Morivar \(1871–2008\)),
				'other' => q(Venẽjuvéra Morivar ag \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(Venẽjuvéra Morivar \(2008–2018\)),
				'one' => q(Venẽjuvéra Morivar \(2008–2018\)),
				'other' => q(Venẽjuvéra Morivar ag \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(Venẽjuvéra Morivar),
				'one' => q(Venẽjuvéra Morivar),
				'other' => q(Venẽjuvéra Morivar ag),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Vijétinỹm Nãg),
				'one' => q(Vijétinỹm Nãg),
				'other' => q(Vijétinỹm Nãg ag),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(Vijétinỹm Nãg \(1978–1985\)),
				'one' => q(Vijétinỹm Nãg \(1978–1985\)),
				'other' => q(Vijétinỹm Nãg ag \(1978–1985\)),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Vanũvatu Vatu),
				'one' => q(Vanũvatu Vatu),
				'other' => q(Vanũvatu Vatu ag),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Samãva Tara),
				'one' => q(Samãva Tara),
				'other' => q(Samãva Tara ag),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(Vĩpir CFA tỹ BEAC),
				'one' => q(Vĩpir CFA tỹ BEAC),
				'other' => q(Vĩpir CFA tỹ BEAC ag),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Kyfé Kupri),
				'one' => q(Kyfé Kupri),
				'other' => q(Kyfé Kupri),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Kyfé Mỹrér),
				'one' => q(Kyfé Mỹrér),
				'other' => q(Kyfé Mỹrér),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Orópa Vẽnhkãmur ũ ‘e),
				'one' => q(Orópa tá Vẽnhkãmur ũ vẽnkikro),
				'other' => q(Orópa tá Vẽnhkãmur ũ vẽnkikro ag),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Orópa Jãnkamu ũ-pir \(XBB\)),
				'one' => q(Orópa Jãnkamu ũ-pir \(XBB\)),
				'other' => q(Orópa Jãnkamu ũ-pir ag \(XBB\)),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Orópa Nĩkrén-ja ũ-pir \(XBC\)),
				'one' => q(Orópa Nĩkrén-ja ũ-pir \(XBC\)),
				'other' => q(Orópa Nĩkrén-ja ũ-pir ag \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Orópa Nĩkrén-ja ũ-pir),
				'one' => q(Orópa Nĩkrén-ja ũ-pir),
				'other' => q(Orópa Nĩkrén-ja ũ-pir ag),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(Karime Rãjur Nórar),
				'one' => q(Karime Rãjur Nórar),
				'other' => q(Karime Rãjur Nórar ag),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Kuryj há ty Jiro),
				'one' => q(Kuryj ty Vẽnhkãgán há),
				'other' => q(Kuryj ty Vẽnhkãgán há),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Orópa Nĩkri ũ-pir),
				'one' => q(Orópa Nĩkri ũ-pir),
				'other' => q(Orópa Nĩkri ũ-pir ag),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Frỹsa Vĩpir-Oro),
				'one' => q(Frỹsa Vĩpir-Oro),
				'other' => q(Frỹsa Vĩpir-Oro ag),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Frỹsa UIC Vĩpir),
				'one' => q(Frỹsa UIC Vĩpir),
				'other' => q(Frỹsa UIC Vĩpir ag),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(Vĩpir CFA tỹ BCEAO),
				'one' => q(Vĩpir CFA tỹ BCEAO),
				'other' => q(Vĩpir CFA tỹ BCEAO ag),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Paranho),
				'one' => q(Paranho),
				'other' => q(Paranho ag),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(Vĩpir CFP),
				'one' => q(Vĩpir CFP),
				'other' => q(Vĩpir CFP ag),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Pratinỹ),
				'one' => q(Pratinỹ),
				'other' => q(Pratinỹ ag),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET Kãryjgy),
				'one' => q(RINET Kãryjgy),
				'other' => q(RINET Kãryjgy ag),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(Rá tỹ Nĩkri Vẽnh-kãgran-ja),
				'one' => q(Rá tỹ Nĩkri Vẽnh-kãgran-ja),
				'other' => q(Rá kar tỹ Nĩkri Vẽnh-kãgran-ja),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Nĩkri veja tũ),
				'one' => q(\(jãnkamu veja tũ\)),
				'other' => q(\(nĩkri ag veja tũ\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Jemẽn Ninỹ),
				'one' => q(Jemẽn Ninỹ),
				'other' => q(Jemẽn Ninỹ ag),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Jemẽn Hijar),
				'one' => q(Jemẽn Hijar),
				'other' => q(Jemẽn Hijar ag),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Jugusiravija Ninỹ Tar \(1966–1990\)),
				'one' => q(Jugusiravija Ninỹ Tar),
				'other' => q(Jugusiravija Ninỹ Tar ag),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Jugusiravija Ninỹ Tãg \(1994–2002\)),
				'one' => q(Jugusiravija Ninỹ Tãg),
				'other' => q(Jugusiravija Ninỹ Tãg ag),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Jugusiravija Ninỹ ta ũn há \(1990–1992\)),
				'one' => q(Jugusiravija Ninỹ ta ũn há),
				'other' => q(Jugusiravija Ninỹ ta ũn há ag),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(Jugusiravija Ninỹ han mãn tãg \(1992–1993\)),
				'one' => q(Jugusiravija Ninỹ han mãn tãg),
				'other' => q(Jugusiravija Ninỹ han mãn tãg ag),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Ran surafrikỹnũ \(virhár\)),
				'one' => q(Sur-Afrika Ran \(virhár\)),
				'other' => q(Sur-Afrika Ran ag \(virhár\)),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Ran surafrikỹnũ),
				'one' => q(Ran surafrikỹnũ),
				'other' => q(Ran surafrikỹnũ ag),
			},
		},
		'ZMK' => {
			symbol => 'SMK',
			display_name => {
				'currency' => q(Kuvasa Jỹmijanũ \(1968–2012\)),
				'one' => q(Jỹmija Kuvasa \(1968–2012\)),
				'other' => q(Jỹmija Kuvasa ag \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Kuvasa jỹmijanũ),
				'one' => q(Kuvasa jỹmijanũ),
				'other' => q(Kuvasa jỹmijanũ ag),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Jajre Tãg Sajrẽse),
				'one' => q(Jajre tá Jajre Tãg),
				'other' => q(Jajre tá Jajre Tãg ag),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Jajre Sajrẽse \(1971–1993\)),
				'one' => q(Jajre tá Jajre),
				'other' => q(Jajre tá Jajre),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Jimamuvé Nórar \(1980– 2008\)),
				'one' => q(Jimamuvé Nórar),
				'other' => q(Jimamuvé Nórar ag),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Jimamuvé Nórar \(2009\)),
				'one' => q(Jimamuvé Nórar \(2009\)),
				'other' => q(Jimamuvé Nórar ag \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Jimamuvé Nórar \(2008\)),
				'one' => q(Jimamuvé Nórar \(2008\)),
				'other' => q(Jimamuvé Nórar ag \(2008\)),
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
							'1Ky.',
							'2Ky.',
							'3Ky.',
							'4Ky.',
							'5Ky.',
							'6Ky.',
							'7Ky.',
							'8Ky.',
							'9Ky.',
							'10Ky.',
							'11Ky.',
							'12Ky.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1K',
							'2K',
							'3K',
							'4K',
							'5K',
							'6K',
							'7K',
							'8K',
							'9K',
							'10K',
							'11K',
							'12K'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'1-Kysã',
							'2-Kysã',
							'3-Kysã',
							'4-Kysã',
							'5-Kysã',
							'6-Kysã',
							'7-Kysã',
							'8-Kysã',
							'9-Kysã',
							'10-Kysã',
							'11-Kysã',
							'12-Kysã'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'1Ky.',
							'2Ky.',
							'3Ky.',
							'4Ky.',
							'5Ky.',
							'6Ky.',
							'7Ky.',
							'8Ky.',
							'9Ky.',
							'10Ky.',
							'11Ky.',
							'12Ky.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1K',
							'2K',
							'3K',
							'4K',
							'5K',
							'6K',
							'7K',
							'8K',
							'9K',
							'10K',
							'11K',
							'12K'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'1-Kysã',
							'2-Kysã',
							'3-Kysã',
							'4-Kysã',
							'5-Kysã',
							'6-Kysã',
							'7-Kysã',
							'8-Kysã',
							'9-Kysã',
							'10-Kysã',
							'11-Kysã',
							'12-Kysã'
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
							'1Ky.',
							'2Ky.',
							'3Ky.',
							'4Ky.',
							'5Ky.',
							'6Ky.',
							'7Ky.',
							'8Ky.',
							'9Ky.',
							'10Ky.',
							'11Ky.',
							'12Ky.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1K',
							'2K',
							'3K',
							'4K',
							'5K',
							'6K',
							'7K',
							'8K',
							'9K',
							'10K',
							'11K',
							'12K'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'1-Kysã',
							'2-Kysã',
							'3-Kysã',
							'4-Kysã',
							'5-Kysã',
							'6-Kysã',
							'7-Kysã',
							'8-Kysã',
							'9-Kysã',
							'10-Kysã',
							'11-Kysã',
							'12-Kysã'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'1Ky.',
							'2Ky.',
							'3Ky.',
							'4Ky.',
							'5Ky.',
							'6Ky.',
							'7Ky.',
							'8Ky.',
							'9Ky.',
							'10Ky.',
							'11Ky.',
							'12Ky.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1K',
							'2K',
							'3K',
							'4K',
							'5K',
							'6K',
							'7K',
							'8K',
							'9K',
							'10K',
							'11K',
							'12K'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'1-Kysã',
							'2-Kysã',
							'3-Kysã',
							'4-Kysã',
							'5-Kysã',
							'6-Kysã',
							'7-Kysã',
							'8-Kysã',
							'9-Kysã',
							'10-Kysã',
							'11-Kysã',
							'12-Kysã'
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
						mon => 'pir.',
						tue => 'rég.',
						wed => 'tẽg.',
						thu => 'vẽn.',
						fri => 'pén.',
						sat => 'sav.',
						sun => 'num.'
					},
					narrow => {
						mon => 'P.',
						tue => 'R.',
						wed => 'T.',
						thu => 'V.',
						fri => 'P.',
						sat => 'S.',
						sun => 'N.'
					},
					short => {
						mon => '1kh.',
						tue => '2kh.',
						wed => '3kh.',
						thu => '4kh.',
						fri => '5kh.',
						sat => 'S.',
						sun => 'N.'
					},
					wide => {
						mon => 'pir-kurã-há',
						tue => 'régre-kurã-há',
						wed => 'tẽgtũ-kurã-há',
						thu => 'vẽnhkãgra-kurã-há',
						fri => 'pénkar-kurã-há',
						sat => 'savnu',
						sun => 'numĩggu'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'pir.',
						tue => 'rég.',
						wed => 'tẽg.',
						thu => 'vẽn.',
						fri => 'pén.',
						sat => 'sav.',
						sun => 'num.'
					},
					narrow => {
						mon => 'P.',
						tue => 'R.',
						wed => 'T.',
						thu => 'V.',
						fri => 'P.',
						sat => 'S.',
						sun => 'N.'
					},
					short => {
						mon => '1kh.',
						tue => '2kh.',
						wed => '3kh.',
						thu => '4kh.',
						fri => '5kh.',
						sat => 'S.',
						sun => 'N.'
					},
					wide => {
						mon => 'pir-kurã-há',
						tue => 'régre-kurã-há',
						wed => 'tẽgtũ-kurã-há',
						thu => 'vẽnhkãgra-kurã-há',
						fri => 'pénkar-kurã-há',
						sat => 'savnu',
						sun => 'numĩggu'
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
					abbreviated => {0 => 'T1',
						1 => 'T2',
						2 => 'T3',
						3 => 'T4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1ⁿ kysã-tẽgtũ',
						1 => '2ᵍᵉ kysã-tẽgtũ',
						2 => '3ⁿʰ kysã-tẽgtũ',
						3 => '4ⁿ kysã-tẽgtũ'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'T1',
						1 => 'T2',
						2 => 'T3',
						3 => 'T4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1ⁿ kysã-tẽgtũ',
						1 => '2ᵍᵉ kysã-tẽgtũ',
						2 => '3ⁿʰ kysã-tẽgtũ',
						3 => '4ⁿ kysã-tẽgtũ'
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
					'afternoon1' => q{rãkãnh kỹ},
					'am' => q{AM},
					'evening1' => q{kuty kỹ},
					'midnight' => q{kuty-si},
					'morning1' => q{kusãg ki},
					'night1' => q{kurã ge},
					'noon' => q{kurã-kuju},
					'pm' => q{PM},
				},
				'narrow' => {
					'afternoon1' => q{rãkãnh kỹ},
					'am' => q{AM},
					'evening1' => q{kuty kỹ},
					'midnight' => q{kuty-si},
					'morning1' => q{kusãg ki},
					'night1' => q{kurã ge},
					'noon' => q{kurã-kuju},
					'pm' => q{PM},
				},
				'wide' => {
					'afternoon1' => q{rãkãnh kỹ},
					'am' => q{AM},
					'evening1' => q{kuty kỹ},
					'midnight' => q{kuty-si},
					'morning1' => q{kusãg ki},
					'night1' => q{kurã ge},
					'noon' => q{kurã-kuju},
					'pm' => q{PM},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{rãkãnh kỹ},
					'am' => q{AM},
					'evening1' => q{kuty kỹ},
					'midnight' => q{kuty-si},
					'morning1' => q{kusãg ki},
					'night1' => q{kurã ge},
					'noon' => q{kurã-kuju},
					'pm' => q{PM},
				},
				'narrow' => {
					'afternoon1' => q{rãkãnh kỹ},
					'am' => q{AM},
					'evening1' => q{kuty kỹ},
					'midnight' => q{kuty-si},
					'morning1' => q{kusãg ki},
					'night1' => q{kurã ge},
					'noon' => q{kurã-kuju},
					'pm' => q{PM},
				},
				'wide' => {
					'afternoon1' => q{rãkãnh kỹ},
					'am' => q{AM},
					'evening1' => q{kuty kỹ},
					'midnight' => q{kuty-si},
					'morning1' => q{kusãg ki},
					'night1' => q{kurã ge},
					'noon' => q{kurã-kuju},
					'pm' => q{PM},
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
				'0' => 'C.j.',
				'1' => 'C.kk.'
			},
			wide => {
				'0' => 'Cristo jo',
				'1' => 'Cristo kar kỹ'
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
			'full' => q{EEEE, d 'ne' MMMM, U},
			'long' => q{d 'ne' MMMM, U},
			'medium' => q{dd/MM U},
			'short' => q{dd/MM/yy},
		},
		'generic' => {
			'full' => q{EEEE, d 'ne' MMMM, y G},
			'long' => q{d 'ne' MMMM, y G},
			'medium' => q{d MMM, y G},
			'short' => q{dd/MM/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d 'ne' MMMM, y},
			'long' => q{d 'ne' MMMM, y},
			'medium' => q{d 'ne' MMM, y},
			'short' => q{dd/MM/y},
		},
		'japanese' => {
			'full' => q{EEEE, d 'ne' MMMM, y G},
			'long' => q{d 'ne' MMMM, y G},
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
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM, y G},
			GyMMMEd => q{E, d 'ne' MMM, y G},
			GyMMMd => q{d 'ne' MMM, y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, dd/MM},
			MMM => q{LLL},
			MMMEd => q{E, d 'ne' MMM},
			MMMMEd => q{E, d 'ne' MMMM},
			MMMMd => q{d 'ne' MMMM},
			MMMd => q{d 'ne' MMM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{MM/y GGGGG},
			yyyyMEd => q{E, dd/MM/y GGGGG},
			yyyyMMM => q{MMM, y G},
			yyyyMMMEd => q{E, d 'ne' MMM, y G},
			yyyyMMMM => q{MMMM, y G},
			yyyyMMMMEd => q{E, d 'ne' MMMM, y G},
			yyyyMMMMd => q{d 'ne' MMMM, y G},
			yyyyMMMd => q{d 'ne' MMM, y G},
			yyyyMd => q{dd/MM/y GGGGG},
			yyyyQQQ => q{G, y QQQ},
			yyyyQQQQ => q{G, y QQQQ},
		},
		'gregorian' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM, y G},
			GyMMMEd => q{E, d 'ne' MMM, y G},
			GyMMMd => q{d 'ne' MMM, y G},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, dd/MM},
			MMM => q{LLL},
			MMMEd => q{E, d 'ne' MMM},
			MMMMEd => q{E, d 'ne' MMMM},
			MMMMW => q{'simỹnỹ' W 'ne' MMMM},
			MMMMd => q{d 'ne' MMMM},
			MMMd => q{d 'ne' MMM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{MM/y},
			yMEd => q{E, dd/MM/y},
			yMM => q{MM/y},
			yMMM => q{MMM, y},
			yMMMEd => q{E, d 'ne' MMM, y},
			yMMMM => q{MMMM, y},
			yMMMMEd => q{E, d 'ne' MMMM, y},
			yMMMMd => q{d 'ne' MMMM, y},
			yMMMd => q{d 'ne' MMM, y},
			yMd => q{dd/MM/y},
			yQQQ => q{QQQ, y},
			yQQQQ => q{QQQQ, y},
			yw => q{'simỹnỹ' w, Y},
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
			Bh => {
				B => q{h B – h B},
				h => q{h – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{G, y – G, y},
				y => q{G, y – y},
			},
			GyM => {
				G => q{GGGGG MM/y – GGGGG MM/y},
				M => q{GGGGG MM/y – MM/y},
				y => q{GGGGG MM/y – MM/y},
			},
			GyMEd => {
				G => q{GGGGG E dd/MM/y – GGGGG E dd/MM/y},
				M => q{GGGGG E dd/MM/y – E dd/MM/y},
				d => q{GGGGG E dd/MM/y – dd/MM/y},
				y => q{GGGGG E dd/MM/y – E dd/MM/y},
			},
			GyMMM => {
				G => q{G MMM y – G MMM y},
				M => q{G MMM y – MMM},
				y => q{G MMM y – MMM y},
			},
			GyMMMEd => {
				G => q{G E, d 'ne' MMM, y – G E, d 'ne' MMM, y},
				M => q{G E, d 'ne' MMM, y – E, d 'ne' MMM},
				d => q{G E, d 'ne' MMM, y – E, d 'ne' MMM},
				y => q{G E, d 'ne' MMM, y – E, d 'ne' MMM, y},
			},
			GyMMMd => {
				G => q{G d 'ne' MMM, y – G d 'ne' MMM, y},
				M => q{G d 'ne' MMM, y – d 'ne' MMM},
				d => q{G d – d 'ne' MMM, y},
				y => q{G d 'ne' MMM, y – d 'ne' MMM, y},
			},
			GyMd => {
				G => q{GGGGG dd/MM/y – GGGGG dd/MM/y},
				M => q{GGGGG dd/MM/y – dd/MM/y},
				d => q{GGGGG dd/MM/y – dd/MM/y},
				y => q{GGGGG dd/MM/y – dd/MM/y},
			},
			H => {
				H => q{HH'h' - HH'h'},
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
				H => q{HH – HH v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, dd/MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d 'ne' MMM – E, d 'ne' MMM},
				d => q{E, d 'ne' MMM – E, d 'ne' MMM},
			},
			MMMd => {
				M => q{d 'ne' MMM – d 'ne' MMM},
				d => q{d–d 'ne' MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} - {1}',
			h => {
				a => q{h'h' a – h'h' a},
				h => q{h'h' - h'h' a},
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
				h => q{h – h a v},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{MM/y – MM/y G},
				y => q{MM/y – MM/y G},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y G},
				d => q{E, dd/MM/y – E, dd/MM/y G},
				y => q{E, dd/MM/y – E, dd/MM/y G},
			},
			yMMM => {
				M => q{MMM–MMM, y G},
				y => q{MMM, y – MMM, y G},
			},
			yMMMEd => {
				M => q{E, d 'ne' MMM – E, d 'ne' MMM, y G},
				d => q{E, d 'ne' MMM – E, d 'ne' MMM, y G},
				y => q{E, d 'ne' MMM, y – E, d 'ne' MMM, y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM, y G},
				y => q{MMMM, y – MMMM, y G},
			},
			yMMMd => {
				M => q{d 'ne' MMM – d 'ne' MMM, y G},
				d => q{d–d 'ne' MMM, y},
				y => q{d 'ne' MMM, y – d 'ne' MMM, y G},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y G},
				d => q{dd/MM/y – dd/MM/y G},
				y => q{dd/MM/y – dd/MM/y G},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h B – h B},
				h => q{h – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{G, y – G, y},
				y => q{G, y – y},
			},
			GyM => {
				G => q{GGGGG MM/y – GGGGG MM/y},
				M => q{GGGGG MM/y – MM/y},
				y => q{GGGGG MM/y – MM/y},
			},
			GyMEd => {
				G => q{GGGGG E dd/MM/y – GGGGG E dd/MM/y},
				M => q{GGGGG E dd/MM/y – E dd/MM/y},
				d => q{GGGGG E dd/MM/y – dd/MM/y},
				y => q{GGGGG E dd/MM/y – E dd/MM/y},
			},
			GyMMM => {
				G => q{G MMM y – G MMM y},
				M => q{G MMM y – MMM},
				y => q{G MMM y – MMM y},
			},
			GyMMMEd => {
				G => q{G E, d 'ne' MMM, y – G E, d 'ne' MMM, y},
				M => q{G E, d 'ne' MMM, y – E, d 'ne' MMM},
				d => q{G E, d 'ne' MMM, y – E, d 'ne' MMM},
				y => q{G E, d 'ne' MMM, y – E, d 'ne' MMM, y},
			},
			GyMMMd => {
				G => q{G d 'ne' MMM, y – G d 'ne' MMM, y},
				M => q{G d 'ne' MMM, y – d 'ne' MMM},
				d => q{G d – d 'ne' MMM, y},
				y => q{G d 'ne' MMM, y – d 'ne' MMM, y},
			},
			GyMd => {
				G => q{GGGGG dd/MM/y – GGGGG dd/MM/y},
				M => q{GGGGG dd/MM/y – dd/MM/y},
				d => q{GGGGG dd/MM/y – dd/MM/y},
				y => q{GGGGG dd/MM/y – dd/MM/y},
			},
			H => {
				H => q{HH'h' - HH'h'},
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
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, d 'ne' MMM – E, d 'ne' MMM},
				d => q{E, d – E, d 'ne' MMM},
			},
			MMMd => {
				M => q{d 'ne' MMM – d 'ne' MMM},
				d => q{d – d 'ne' MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} - {1}',
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
				M => q{MM/y – MM/y},
				y => q{MM/y – MM/y},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMM => {
				M => q{MMM – MMM, y},
				y => q{MMM, y – MMM, y},
			},
			yMMMEd => {
				M => q{E, d 'ne' MMM – E, d 'ne' MMM, y},
				d => q{E, d – E, d 'ne' MMM, y},
				y => q{E, d 'ne' MMM, y – E, d 'ne' MMM, y},
			},
			yMMMM => {
				M => q{MMMM – MMMM, y},
				y => q{MMMM, y – MMMM, y},
			},
			yMMMd => {
				M => q{d 'ne' MMM – d 'ne' MMM, y},
				d => q{d – d 'ne' MMM, y},
				y => q{d 'ne' MMM, y – d 'ne' MMM, y},
			},
			yMd => {
				M => q{dd/MM/y – dd/MM/y},
				d => q{dd/MM/y – dd/MM/y},
				y => q{dd/MM/y – dd/MM/y},
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
		regionFormat => q(Óra kar {0}),
		regionFormat => q(Prỹg kã óra kar {0}),
		regionFormat => q(Óra pẽ {0}),
		fallbackFormat => q({1} ({0})),
		'Acre' => {
			long => {
				'daylight' => q#Rỹ Kã óra Akre tá#,
				'generic' => q#Akre tá óra#,
				'standard' => q#Óra Pã Akre tá#,
			},
			short => {
				'daylight' => q#ACST#,
				'generic' => q#ACT#,
				'standard' => q#ACT#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Afeganĩtã tá óra#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Aminjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Anisi Amema#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Arjér#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asimỹra#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Mamỹko#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Magi#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Manjur#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Misav#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Mrantyre#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Mrajavire#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Mujũmura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kajro#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Ĩnkupri#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Sevuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Konỹkri#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Nakar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Nar Enh Sarỹm#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Nhimuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Novara#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Er A’ajun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Ẽmã-fri#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Gamoronĩ#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Harari#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Juvỹnẽnhmurgu#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Juma#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kãmpara#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Kartũm#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kigari#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kĩsaja#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Rago#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Rimreviri#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Rómẽ#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Ruvỹna#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Rumumasi#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Rusaka#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Mỹramo#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Mỹputu#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Mỹseru#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Mĩmamanẽ#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mũganinhsu#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Mãnróvija#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nỹjrómi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Ni’nijamẽnỹ#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Nĩamẽj#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nãvagsóti#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Ovaganogov#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto Tãg#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sỹ Tumẽ#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripori#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunĩnh#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Vĩnnoéki#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Afrika-Kuju tá óra#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Afrika Rãjur tá óra#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Sur-Afrika tá óra#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Rỹ Kã óra Afrika Rãpur tá#,
				'generic' => q#Afrika Rãpur tá óra#,
				'standard' => q#Óra Pã Afrika Rãpur tá#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Rỹ Kã óra Aranhka tá#,
				'generic' => q#Aranhka tá óra#,
				'standard' => q#Óra Pã Aranhka tá#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Rỹ Kã óra Armaty tá#,
				'generic' => q#Armaty tá óra#,
				'standard' => q#Óra Pã Armaty tá#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Rỹ Kã óra Amỹjonỹ tá#,
				'generic' => q#Amỹjonỹ tá óra#,
				'standard' => q#Óra Pã Amỹjonỹ tá#,
			},
			short => {
				'daylight' => q#AMST#,
				'generic' => q#AMT#,
				'standard' => q#AMT#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Anaki#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Ỹkoragi#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Ỹgira#,
		},
		'America/Antigua' => {
			exemplarCity => q#Ỹtiguva#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguainỹ#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#Ra Rioha#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Garego Goj#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Sarta#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#Sỹ Juvỹ#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#Sỹ Ruj#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tukumỹ#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Usuaja#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruma#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asũgsỹ#,
		},
		'America/Bahia' => {
			exemplarCity => q#Majia#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Majia Mánnera Ag#,
		},
		'America/Barbados' => {
			exemplarCity => q#Marmanu#,
		},
		'America/Belem' => {
			exemplarCity => q#Merẽj#,
		},
		'America/Belize' => {
			exemplarCity => q#Merise#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Samrãn Kupri#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Veja Há#,
		},
		'America/Bogota' => {
			exemplarCity => q#Mogota#,
		},
		'America/Boise' => {
			exemplarCity => q#Mojse#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Muenũsairi#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Kẽmrinje Mej#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Re Mág#,
		},
		'America/Cancun' => {
			exemplarCity => q#Kỹkũn#,
		},
		'America/Caracas' => {
			exemplarCity => q#Karakanh#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Katamỹrka#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Kajenỹ#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kajmỹn#,
		},
		'America/Chicago' => {
			exemplarCity => q#Sikagu#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Sihuvahuva#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikokỹn#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kórnoma#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Pãnĩ Tũ Mág#,
		},
		'America/Creston' => {
			exemplarCity => q#Krésitãn#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Kujama#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kurasavo#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Nánmỹrkisavyn#,
		},
		'America/Dawson' => {
			exemplarCity => q#Navsãn#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Nausãn Kriki#,
		},
		'America/Denver' => {
			exemplarCity => q#Nenver#,
		},
		'America/Detroit' => {
			exemplarCity => q#Netorójti#,
		},
		'America/Dominica' => {
			exemplarCity => q#Nomĩnĩka#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Enimãntã#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Ejrunẽpé#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Ér Sarvanor#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fórti Nẽrsu#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fortareja#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Grase Mej#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nũg#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Gỹso Mej#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Turki Mág#,
		},
		'America/Grenada' => {
			exemplarCity => q#Granỹna#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guvanarupe#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guratemỹra#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guvajakir#,
		},
		'America/Guyana' => {
			exemplarCity => q#Gujánỹ#,
		},
		'America/Halifax' => {
			exemplarCity => q#Harifag#,
		},
		'America/Havana' => {
			exemplarCity => q#Havánỹ#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Hérmosiro#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Kinãg, Ĩnijỹnỹ#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Mỹrẽggu, Ĩnijỹnỹ#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Pétermurgi, Ĩnijỹnỹ#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Ter siti, Ĩnijỹnỹ#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vevaj, Ĩnijỹnỹ#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vĩsenẽnh, Ĩnijỹnỹ#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Vinỹmỹki, Ĩnijỹnỹ#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Ĩnijanỹporinh#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inũviki#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Ikarujin#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamỹjkỹ#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Jujuj#,
		},
		'America/Juneau' => {
			exemplarCity => q#Junỹvo#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Mãntiséru, Kẽtáki#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Krarẽnike#,
		},
		'America/La_Paz' => {
			exemplarCity => q#Ra Pasi#,
		},
		'America/Lima' => {
			exemplarCity => q#Rimỹ#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Ronh Ỹnjiri#,
		},
		'America/Louisville' => {
			exemplarCity => q#Ruinhviri#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Rover Prĩnsi Kuvartér#,
		},
		'America/Maceio' => {
			exemplarCity => q#Mỹsejó#,
		},
		'America/Managua' => {
			exemplarCity => q#Mỹnỹguva#,
		},
		'America/Manaus' => {
			exemplarCity => q#Mỹnỹvo#,
		},
		'America/Marigot' => {
			exemplarCity => q#Mỹrigóti#,
		},
		'America/Martinique' => {
			exemplarCity => q#Mỹrtinĩka#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Mãro-ag Tãnh#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mỹjatrỹn#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mẽnosa#,
		},
		'America/Menominee' => {
			exemplarCity => q#Mẽnãmĩnĩ#,
		},
		'America/Merida' => {
			exemplarCity => q#Mẽrina#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Mẽtarakatara#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Ẽmã tỹ Mẽsiko#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Mĩkeron#,
		},
		'America/Moncton' => {
			exemplarCity => q#Mãgtãn#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Mãtehej#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Mãtivinév#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Mãnseráti#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nỹsav#,
		},
		'America/New_York' => {
			exemplarCity => q#Yjórki Tãg#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nĩpigãn#,
		},
		'America/Nome' => {
			exemplarCity => q#Jyjy#,
		},
		'America/Noronha' => {
			exemplarCity => q#Fernỹnu Nãrãja-tá#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Meura, Nakota Nãrti#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Sẽnter, Dakota Nãrti#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Nĩu Saren, Nakota Nãrti#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ojinỹga#,
		},
		'America/Panama' => {
			exemplarCity => q#Panỹmỹ#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Pỹgnĩrtũg#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Paramỹrimu#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Fuenĩnh#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Portu Prĩsipi#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Pórtofi Inhpajin#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Porto Kófa#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Porto Riko#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Pũta Arenỹ#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Tamumã Goj#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rỹgkĩg Ĩrén#,
		},
		'America/Recife' => {
			exemplarCity => q#Risifi#,
		},
		'America/Regina' => {
			exemplarCity => q#Rijinỹ#,
		},
		'America/Resolute' => {
			exemplarCity => q#Rijorute#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Goj Kupri#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Sỹta Isamé#,
		},
		'America/Santarem' => {
			exemplarCity => q#Sỹtarẽj#,
		},
		'America/Santiago' => {
			exemplarCity => q#Sỹtijagu#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Sỹtu Numĩggu#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Sỹ Pavoru#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Itogkorturmĩnti#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sinka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Sỹ Martoromẽ#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Sỹn Jonh#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Sỹ Kritóvỹ#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Sỹta Rusa#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Sỹ Tomaj#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Sỹ Visẽti#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Suvifiti Kurẽti#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegusigarpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Ture#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Tũnner Mej#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tivỹnỹ#,
		},
		'America/Toronto' => {
			exemplarCity => q#Torãto#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tortora#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vỹgkuver#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Kãvãru Kupri#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Vĩnĩpég#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Yjakutati#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Rógro Mỹrér#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Rỹ Kã óra Kuju tá#,
				'generic' => q#Kuju tá óra#,
				'standard' => q#Óra Pã Kuju tá#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Rỹ Kã óra Rãjur tá#,
				'generic' => q#Óra Rãjur tá#,
				'standard' => q#Óra Pã Rãjur tá#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Rỹ Kã óra Krĩ tá#,
				'generic' => q#Óra Krĩ tá#,
				'standard' => q#Óra Pã Krĩ tá#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Rỹ Kã óra Rãpur tá#,
				'generic' => q#Óra Rãpur tá#,
				'standard' => q#Óra Pã Rãpur tá#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Rỹ Kã óra Anỹnhyr tá#,
				'generic' => q#Óra Anỹnnyr tá#,
				'standard' => q#Óra Pã Anỹnhyr tá#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Kasej#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Navisi#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Mỹkikuari#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mỹusãn#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#Még-Mũrno#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Parmẽr#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rotera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Siova#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Torór#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Vonhtóki#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Rỹ Kã óra Apija tá#,
				'generic' => q#Óra Apija tá#,
				'standard' => q#Óra Pã Apija tá#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Rỹ Kã óra Agtav tá#,
				'generic' => q#Óra Agtav tá#,
				'standard' => q#Óra Pã Agtav tá#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Rỹ Kã óra Agtóme tá#,
				'generic' => q#Óra Agtóme tá#,
				'standard' => q#Óra Pã Agtóme tá#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Rỹ Kã óra Aramija tá#,
				'generic' => q#Óra Aramija tá#,
				'standard' => q#Óra Pã Aramija tá#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Rũgijé Armyjẽn#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Rỹ Kã óra Arjẽtĩnỹ tá#,
				'generic' => q#Óra Arjẽtĩnỹ tá#,
				'standard' => q#Óra Opã Arjẽtĩnỹ tá#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Rỹ Kã óra Arjẽtĩnỹ Rãpurtá#,
				'generic' => q#Óra Arjẽtĩnỹ Rãpur tá#,
				'standard' => q#Óra Pã Arjẽtĩnỹ Rãpur tá#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Rỹ Kã óra Armẽnĩja tá#,
				'generic' => q#Óra Armẽnĩja tá#,
				'standard' => q#Óra Pã Armẽnĩja tá#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Anen#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Armỹti#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amỹ#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anỹnhir#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Akitau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Akitome#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Anhgamati#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atirav#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Magina#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Marẽj#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Maku#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Mygkóki#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Marnỹur#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Mejruti#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Misikéki#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Mrunẽj#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Karkuta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Sita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Sojmarsỹ#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Korãmmu#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Namỹnhko#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Naka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Niri#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Numaj#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Nuságme#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famỹgujta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gaja#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hemron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hãg Kãg#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hovin#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutinhki#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jaiapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerujarẽj#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kamur#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kỹmsanka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karasi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katimỹnnu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Kỹnyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Kranhnãjarki#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuvara Rũpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kusĩg#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuvajti#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Mỹkau#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Mỹganan#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Mỹnĩra#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nĩkójia#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Kunhnẽtinhki Tãg#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Simirsiki Tãg#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Omĩnhki#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Orar#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Fynãg Pẽj#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pãntiỹnỹki#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Piãg-jỹg#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kojtanỹj#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kyjyrorna#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangũm#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Rijane#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sakarĩnỹ#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samỹrkỹnna#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Se’ur#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Sỹggaj#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Sĩgapura#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Sirenẽkorymsiki#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Tajpej#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Tanhkẽnti#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Timiriji#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Te’erỹ#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Tĩmfu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tókijo#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomĩnhki#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Uran Mator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urũmki#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Unhti-Nẽra#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vijẽtijỹnĩ#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Uranivónhtóki#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yjakutinhki#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Ekaterĩnmurgu#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Jerevỹ#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Rỹ Kã óra Atrỹtiku tá#,
				'generic' => q#Óra Atrỹtiku tá#,
				'standard' => q#Óra Pã Atrỹtiku tá#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Asorenh#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Mermũna#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanỹrija Ag#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Pu Tánh#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Ka#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Rejkijaviki#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Jiórja tỹ Sur#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sỹta Erenỹ#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Sitỹrej#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Anerajni#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Mrinhmanẽ#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Mruken Hir#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Kurije#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Narvĩn#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Eukra#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Homarti#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Rĩnermỹn#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Rórni Hove#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Mẽrmurnĩ#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Pérti#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sininej#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Rỹ Kã óra Avotyraria Kuju tá#,
				'generic' => q#Óra Avotyraria Kuju tá#,
				'standard' => q#Óra Pã Avotyraria Kuju tá#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Rỹ Kã óra Avotyraria Kuju-Rãpur tá#,
				'generic' => q#Óra Avotyaria Kuju-Rãpur tá#,
				'standard' => q#Óra Pã Avotyraria Kuju-Rãpur tá#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Rỹ Kã óra Avotyraria Rãjur tá#,
				'generic' => q#Óra Avotyraria Rãjur tá#,
				'standard' => q#Óra Pã Avotyraria Rãjur tá#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Rỹ Kã óra Avotyraria Rãpur tá#,
				'generic' => q#Óra Avotyraria Rãpur tá#,
				'standard' => q#Óra Pã Avotyraria Rãpur tá#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Rỹ Kã óra Ajermajjáv tá#,
				'generic' => q#Óra Ajermajjáv tá#,
				'standard' => q#Óra Pã Ajermajjáv tá#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Rỹ Kã óra Aso-ag tá#,
				'generic' => q#Óra Asor-ag tá#,
				'standard' => q#Óra Pã Asor-ag tá#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Rỹ Kã óra Mỹngranési tá#,
				'generic' => q#Óra Mỹngranési tá#,
				'standard' => q#Óra Pã Mỹngranési tá#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Óra Mutỹv tá#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Óra Morivia tá#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Rỹ Kã óra Mrasirja tá#,
				'generic' => q#Óra Mrasirja tá#,
				'standard' => q#Óra Pã Mrasirja tá#,
			},
			short => {
				'daylight' => q#BRST#,
				'generic' => q#BRT#,
				'standard' => q#BRT#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Óra Mrunẽj Narusarỹ tá#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Rỹ Kã óra Pu tánh tá#,
				'generic' => q#Óra Pu Tánh tá#,
				'standard' => q#Óra Pã Pu Tánh tá#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Óra Samãho tá#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Rỹ Kã óra San-hỹm tá#,
				'generic' => q#Óra San-hỹm tá#,
				'standard' => q#Óra Pã San-hỹm tá#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Rỹ Kã óra Sire tá#,
				'generic' => q#Óra Sire tá#,
				'standard' => q#Óra Pã Sire tá#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Rỹ Kã óra Sĩnỹ tá#,
				'generic' => q#Óra Sĩnỹ tá#,
				'standard' => q#Óra Pã Sĩnỹ tá#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Rỹ Kã óra Sojmarsỹ tá#,
				'generic' => q#Óra Sojmarsỹ tá#,
				'standard' => q#Óra Pã Sojmarsỹ tá#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Óra Krĩtimỹnh Goj-vẽso tá#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Óra Kokonh Goj-vẽso tá#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Rỹ Kã óra Korãmija tá#,
				'generic' => q#Óra Korãmija tá#,
				'standard' => q#Óra Pã Korãmija tá#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Rỹ Kã óra Kuki Goj-vẽso tá#,
				'generic' => q#Óra Kuki Goj-vẽso tá#,
				'standard' => q#Óra Pã Kuki Goj-vẽso tá#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Rỹ Kã óra Kuma tá#,
				'generic' => q#Óra Kuma tá#,
				'standard' => q#Óra Pã Kuma tá#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Óra Navinh tá#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Óra Numã-Nurviri tá#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Óra Tĩmãr-Rãjur tá#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Rỹ Kã óra Panhkuva Goj-vẽso tá#,
				'generic' => q#Óra Panhkuva Goj-vẽso tá#,
				'standard' => q#Óra Pã Panhkuva Goj-vẽso tá#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Óra Ekuvanor tá#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Ga-kar Óra Vẽnh-krén-ja#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Jamã Vejatũ#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amĩnhterná#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Ỹnoha#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Anhtakỹ#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atenỹ#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Mergrano#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Mer-rĩg#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Mratinhrava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Mruséra#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Mukarénhti#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Munapenhte#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Myjingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Sijinỹvo#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopẽnhỹge#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Numrin#,
			long => {
				'daylight' => q#Óra Pã Irỹna#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Jimratar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Gérnĩsej#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Hérsĩgke#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Ũn-gré Goj-vẽso#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Inhtamur#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jérsej#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Karinĩngrano#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kijévi#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kiróvi#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Rinhmova#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Rimriỹnỹ#,
		},
		'Europe/London' => {
			exemplarCity => q#Rãnere#,
			long => {
				'daylight' => q#Óra Mritỹnĩku Rỹ Kã#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Rusẽgmurgo#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Mỹniri#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Marta#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mỹriehỹm#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Mĩgsiki#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Mãnỹko#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Mãnhkov#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Ósiro#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Parinh#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Pongórika#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Romỹ#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samỹra#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#Sỹ Mỹrĩnũ#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarajevo/Sarajevu#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratóvi#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Sĩgfiripor#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Sikopije#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sófija#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Enhtukormũ#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tarĩn#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirỹnỹ#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Urijanãvinhki#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Ungoron#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vanuj#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikỹnũ#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vienỹ#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Virnĩjusi#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Vorgugrano#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsóvija#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Jagréme#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Japorisija#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Jurike#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Rỹ Kã óra Orópa Kuju tá#,
				'generic' => q#Óra Orópa Kuju tá#,
				'standard' => q#Óra Pã Orópa Kuju tá#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Rỹ Kã óra Orópa Rãjur tá#,
				'generic' => q#Óra Orópa Rãjur tá#,
				'standard' => q#Óra Pã Orópa Rãjur tá#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Rãjur tỹ Orópa jã há tá óra#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Rỹ Kã óra Orópa Rãpur tá#,
				'generic' => q#Óra Orópa Rãpur tá#,
				'standard' => q#Óra Pã Orópa Rãpur tá#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Rỹ Kã óra Mỹrvĩnỹ Goj-vẽso tá#,
				'generic' => q#Óra Mỹrvĩnỹ Goj-vẽso tá#,
				'standard' => q#Ór Pã Mỹrvĩnỹ Goj-vẽso tá#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Rỹ Kã óra Fiji tá#,
				'generic' => q#Óra Fiji tá#,
				'standard' => q#Óra Pã Fiji tá#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Óra Frỹsa Gijanỹ tá#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Óra Frỹsa Ga Sur kar Ỹtartina tá#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Óra Mirinjỹnũ Grinũvisi tá#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Óra Gara Pago tá#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Óra Gỹmmijer#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Rỹ Kã óra Jeórja tá#,
				'generic' => q#Óra Jeórja tá#,
				'standard' => q#Óra Pã Jeórja tá#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Óra Jirmértu Goj-vẽso tá#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Rỹ Kã óra Groẽrỹnija Rãjur tá#,
				'generic' => q#Óra Groẽrỹnija Rãjur tá#,
				'standard' => q#Óra Pã Groẽrỹnija Rãjur tá#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Rỹ Kã óra Groẽrỹnija Rãpur tá#,
				'generic' => q#Óra Groẽrỹnija Rãpur tá#,
				'standard' => q#Óra Pã Groẽrỹnija Rãpur tá#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Óra Pã Guvỹm tá#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Óra Gorfu tá#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Óra Gijỹnỹ tá#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Rỹ kã óra Hava’i kar Arevta Goj-vẽso tá#,
				'generic' => q#Óra Hava’i kar Arevta Goj-vẽso tá#,
				'standard' => q#Óra Pã Hava’i kar Arevta Goj-vẽso tá#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Rỹ Kã óra Hãg Kãg tá#,
				'generic' => q#Óra Hãg Kãg tá#,
				'standard' => q#Óra Pã Hãg Kãg tá#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Rỹ kã óra Hóvin tá#,
				'generic' => q#Óra Hóvin tá#,
				'standard' => q#Óra Pã Hóvin tá#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Óra Pã Ĩnija tá#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Ỹtanỹnỹrivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Sago#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Krinhtimỹ#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kóko Ag#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komãre#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kirgéren#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mỹhé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Mỹrniva#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mãrisiv#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mỹjóti#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Rũnjũv#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Óra Osiỹno Ĩniko tá#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Óra Ĩnosĩnỹ tá#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Óra Ĩnonẽja Kuju tá#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Óra Ĩnonẽja Rãjur tá#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Óra Ĩnonẽja Rãpur tá#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Rỹ Kã óra Irỹ tá#,
				'generic' => q#Óra Irỹ tá#,
				'standard' => q#Óra Pã Irỹ tá#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Rỹ Kã óra Irkutinhki tá#,
				'generic' => q#Óra Irkutinhki tá#,
				'standard' => q#Óra Pã Irkutinhki tá#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Rỹ Kã óra Isihaé tá#,
				'generic' => q#Óra Isihaé tá#,
				'standard' => q#Óra Pã Isihaé tá#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Rỹ Kã óra Japã tá#,
				'generic' => q#Óra Japã tá#,
				'standard' => q#Óra Pã Japã tá#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Rỹ Kã óra Petrupaviróvinhki-Kỹmsatinhki#,
				'generic' => q#Óra Petrupaviróvinhki-Kỹmsatinhki#,
				'standard' => q#Óra Pã Petrupaviróvinhki-Kỹmsatinhki#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Óra Kajakinhtỹv Rãjur tá#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Óra Kajakinhtỹv Rãpur tá#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Rỹ Kã óra Koréja tá#,
				'generic' => q#Óra Koréja tá#,
				'standard' => q#Óra Pã Koréja tá#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Óra de Kosiraje tá#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Rỹ Kã óra Kranhnãjarki tá#,
				'generic' => q#Óra Kranhnãjarki tá#,
				'standard' => q#Óra Pã Kranhnãjarki tá#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Óra Kirginhtỹv tá#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Óra Rỹnka tá#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Óra Vãfe Goj-vẽso tỹ tá#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Rỹ Kã óra Rórni Hove tá#,
				'generic' => q#Óra Rórni Hove tá#,
				'standard' => q#Óra Pã Rórni Hove tá#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Rỹ kã óra Mỹkav tá#,
				'generic' => q#Óra Mỹkav tá#,
				'standard' => q#Óra Pã Mỹkav tá#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Óra Mỹkikuari Goj-vẽso tá#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Rỹ Kã óra Mỹganan tá#,
				'generic' => q#Óra Mỹganan tá#,
				'standard' => q#Óra Pã Mỹganan tá#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Óra Mỹraja tá#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Óra Goj Vẽso Mỹrniva tá#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Óra Mỹrkeja Fag tá#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Óra MỹrSar Goj-vẽso tá#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Rỹ Kã óra Mãriso tá#,
				'generic' => q#Óra Mãriso tá#,
				'standard' => q#Óra Pã Mãriso tá#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Óra Mỹusãn tá#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Rỹ Kã óra Mẽsiku Nãrti-Rãpur tá#,
				'generic' => q#Óra Mẽsiku Nãrti-Rãpur tá#,
				'standard' => q#Óra Pã Mẽsiku Nãrti-Rãpur tá#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Rỹ Kã óra Mẽsiku Pasifiku tá#,
				'generic' => q#Óra Mẽsiku Pasifiku tá#,
				'standard' => q#Óra Pã Mẽsiku Pasifiku tá#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Rỹ Kã óra Uran Mator tá#,
				'generic' => q#Óra Uran Mator tá#,
				'standard' => q#Óra Pã Uran Mator tá#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Rỹ Kã óra Mãnhkov tá#,
				'generic' => q#Óra Mãnhkov tá#,
				'standard' => q#Óra Pã Mãnhkov tá#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Óra Mĩjỹmỹr tá#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Óra Nỹvuru tá#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Óra Nẽpar tá#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Rỹ Kã óra Karenonĩja Tãg tá#,
				'generic' => q#Óra Karenonĩja Tãg tá#,
				'standard' => q#Óra Pã Karenonĩja Tãg tá#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Rỹ Kã óra Jerỹnija Tãg tá#,
				'generic' => q#Óra Jerỹnija Tãg tá#,
				'standard' => q#Óra Pã Jerỹnija Tãg tá#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Rỹ Kã óra Ga Tãg tá#,
				'generic' => q#Óra Ga tãg tá#,
				'standard' => q#Óra Pã Ga Tãg tá#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Óra Nĩve tá#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Rỹ Kã óra Nãrforki Goj-vẽso tá#,
				'generic' => q#Óra Nãrforki Goj-vẽso tá#,
				'standard' => q#Óra Pã Nãrforki Goj-vẽso tá#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Rỹ Kã óra Fernỹnu Nãrãja-tá tá#,
				'generic' => q#Óra Fernỹnu Nãrãja-tá tá#,
				'standard' => q#Óra Pã Fernỹnu Nãrãja-tá tá#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Óra Nãrti-Mỹrijỹnỹ Goj-vẽso tá#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Rỹ Kã óra Pã Simirsiki Tãg tá#,
				'generic' => q#Óra Simirsiki Tãg tá#,
				'standard' => q#Óra Pã Simirsiki Tãg tá#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Rỹ Kã óra Omĩnhki tá#,
				'generic' => q#Óra Omĩnhki tá#,
				'standard' => q#Óra Pã Omĩnhki tá#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Apija#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Óg-rỹn#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Mugỹnvire#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Satinỹm#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Pasikuva Goj-vẽso#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Éfaté#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Ẽnnermuri#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Fakaofu#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fiji#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funỹfuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Gara Pago#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gỹmmiér#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guvanarkanỹr#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guvỹm#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honãruru#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Nhionhtãn#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kiritimỹti#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosiraje#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kuvajarẽj#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Mỹjuro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Mỹrkeja Fag#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Mĩnnuvej#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Nỹvuru#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Nĩve#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Nãrfoki#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Nãumẽa#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago Pago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Parav#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitikair#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Pór Mãrenhmi#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarãtãga#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Sajpỹ#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tajti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarauva#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tãngatapu#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Vaki#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Varinh#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Rỹ Kã óra Pakinhtỹv tá#,
				'generic' => q#Óra Pakinhtỹv tá#,
				'standard' => q#Óra Pã Pakinhtỹv tá#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Óra Paravu tá#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Óra Papuva-Ginẽ Tãg tá#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Rỹ Kã óra Paraguvaj tá#,
				'generic' => q#Óra Paraguvaj tá#,
				'standard' => q#Óra Pã Paraguvaj tá#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Rỹ Kã óra Piru tá#,
				'generic' => q#Óra Piru tá#,
				'standard' => q#Óra Pã Piru tá#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Rỹ Kã Firipinỹ tá#,
				'generic' => q#Óra Firipinỹ tá#,
				'standard' => q#Óra Pã Firipinỹ tá#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Óra Fẽnĩg Goj-vẽso tá#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Rỹ Kã óra Sỹ Pedro kar Mĩkerỹv tá#,
				'generic' => q#Óra Sỹ Penru kar Mĩkerỹv tá#,
				'standard' => q#Óra Pã Sỹ Pedro kar Mĩkerỹv tá#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Óra Pinkajir Goj-vẽso tá#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Óra Ponỹpe tá#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Óra Piãgiỹng tá#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Rỹ Kã óra Kysyrorna tá#,
				'generic' => q#Óra Kysyrorna tá#,
				'standard' => q#Óra Pã Kysyrorna tá#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Óra Hujáv tá#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Óra Rotera tá#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Rỹ Kã óra Sakarinỹ tá#,
				'generic' => q#Óra Sakarinỹ tá#,
				'standard' => q#Óra Pã Sakarinỹ tá#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Rỹ Kã óra Samỹra tá#,
				'generic' => q#Óra Samỹra tá#,
				'standard' => q#Óra Pã Samỹra tá#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Rỹ Kã óra Samãva tá#,
				'generic' => q#Óra Samãva tá#,
				'standard' => q#Óra Pã Samãva tá#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Óra Sejserenh tá#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Óra Pã Sĩgapura tá#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Óra Saromỹv Goj-vẽso tá#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Óra Jiórja tỹ Sur tá#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Óra Surinỹmĩ tá#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Óra Siova tá#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Óra Tajti tá#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Rỹ Kã óra Tajpej tá#,
				'generic' => q#Óra Tajpej tá#,
				'standard' => q#Óra Pã Tajpej tá#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Óra Tajikinhtỹv tá#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Óra Tokeravu tá#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Rỹ Kã óra Tãga tá#,
				'generic' => q#Óra Tãga tá#,
				'standard' => q#Óra Pã Tãga tá#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Óra Suuki tá#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Rỹ Kã óra Turkomẽnĩnhtỹv tá#,
				'generic' => q#Óra Turkomẽnĩnhtỹv tá#,
				'standard' => q#Óra Pã Turkomẽnĩnhtỹv tá#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Óra Tuvaru tá#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Rỹ Kã óra Uruguvaj tá#,
				'generic' => q#Óra Uruguvaj tá#,
				'standard' => q#Óra Pã Uruguvaj tá#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Rỹ Kã óra Unhmekinhtỹv tá#,
				'generic' => q#Óra Unhmekinhtỹv tá#,
				'standard' => q#Óra Pã Unnmekinhtỹv tá#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Rỹ Kã óra Vanũvatu tá#,
				'generic' => q#Óra Vanũvatu tá#,
				'standard' => q#Óra Pã Vanũvatu tá#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Óra Venẽjuvéra tá#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Rỹ Kã óra Uranivónhtóki tá#,
				'generic' => q#Óra Uranivónhtókii tá#,
				'standard' => q#Óra Pã Uranivónhtóki tá#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Rỹ Kã óra Vorgugrano tá#,
				'generic' => q#Óra Vorgugrano tá#,
				'standard' => q#Óra Pã Vorgugrano tá#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Óra Vonhtóki tá#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Óra Vejki Goj-vẽso tá#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Óra Varinh kar Futunỹ tá#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Rỹ Kã óra Yjakutinhki tá#,
				'generic' => q#Óra Yjakutinhki tá#,
				'standard' => q#Óra Pã Yjakutinhkii tá#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Rỹ Kã óra Ekaterĩnmurgu tá#,
				'generic' => q#Óra Ekaterĩnmurgu tá#,
				'standard' => q#Óra Pã Ekaterĩnmurgu tá#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
