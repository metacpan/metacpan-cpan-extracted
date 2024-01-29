=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Eu - Package for language Basque

=cut

package Locale::CLDR::Locales::Eu;
# This file auto generated from Data\common\main\eu.xml
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
				'aa' => 'afarera',
 				'ab' => 'abkhaziera',
 				'ace' => 'acehnera',
 				'ach' => 'acholiera',
 				'ada' => 'adangmera',
 				'ady' => 'adigera',
 				'af' => 'afrikaans',
 				'agq' => 'aghemera',
 				'ain' => 'ainuera',
 				'ak' => 'akanera',
 				'ale' => 'aleutera',
 				'alt' => 'hegoaldeko altaiera',
 				'am' => 'amharera',
 				'an' => 'aragoiera',
 				'anp' => 'angikera',
 				'ar' => 'arabiera',
 				'ar_001' => 'arabiera moderno estandarra',
 				'arn' => 'maputxe',
 				'arp' => 'arapaho',
 				'as' => 'assamera',
 				'asa' => 'asu',
 				'ast' => 'asturiera',
 				'av' => 'avarera',
 				'awa' => 'awadhiera',
 				'ay' => 'aimara',
 				'az' => 'azerbaijanera',
 				'ba' => 'baxkirera',
 				'ban' => 'baliera',
 				'bas' => 'basaa',
 				'be' => 'bielorrusiera',
 				'bem' => 'bembera',
 				'bez' => 'benera',
 				'bg' => 'bulgariera',
 				'bho' => 'bhojpurera',
 				'bi' => 'bislama',
 				'bin' => 'edoera',
 				'bla' => 'siksikera',
 				'bm' => 'bambarera',
 				'bn' => 'bengalera',
 				'bo' => 'tibetera',
 				'br' => 'bretoiera',
 				'brx' => 'bodoera',
 				'bs' => 'bosniera',
 				'bug' => 'buginera',
 				'byn' => 'bilena',
 				'ca' => 'katalan',
 				'ccp' => 'chakmera',
 				'ce' => 'txetxenera',
 				'ceb' => 'cebuanoera',
 				'cgg' => 'chiga',
 				'ch' => 'chamorrera',
 				'chk' => 'chuukera',
 				'chm' => 'mariera',
 				'cho' => 'choctaw',
 				'chr' => 'txerokiera',
 				'chy' => 'cheyennera',
 				'ckb' => 'erdialdeko kurduera',
 				'co' => 'korsikera',
 				'crs' => 'Seychelleetako kreolera',
 				'cs' => 'txekiera',
 				'cu' => 'elizako eslaviera',
 				'cv' => 'txuvaxera',
 				'cy' => 'gales',
 				'da' => 'daniera',
 				'dak' => 'dakotera',
 				'dar' => 'dargvera',
 				'dav' => 'taitera',
 				'de' => 'aleman',
 				'de_AT' => 'Austriako aleman',
 				'de_CH' => 'Suitzako aleman garai',
 				'dgr' => 'dogribera',
 				'dje' => 'zarma',
 				'doi' => 'dogria',
 				'dsb' => 'behe-sorabiera',
 				'dua' => 'dualera',
 				'dv' => 'divehiera',
 				'dyo' => 'fonyi jolera',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazaga',
 				'ebu' => 'embuera',
 				'ee' => 'eweera',
 				'efi' => 'efikera',
 				'eka' => 'akajuka',
 				'el' => 'greziera',
 				'en' => 'ingeles',
 				'en_AU' => 'Australiako ingeles',
 				'en_CA' => 'Kanadako ingeles',
 				'en_GB' => 'Britania Handiko ingeles',
 				'en_GB@alt=short' => 'Erresuma Batuko ingeles',
 				'en_US' => 'AEBko ingeles',
 				'en_US@alt=short' => 'AEBko ingelesa',
 				'eo' => 'esperanto',
 				'es' => 'espainiera',
 				'es_419' => 'Latinoamerikako espainiera',
 				'es_ES' => 'espainiera (Europa)',
 				'es_MX' => 'Mexikoko espainiera',
 				'et' => 'estoniera',
 				'eu' => 'euskara',
 				'ewo' => 'ewondera',
 				'fa' => 'persiera',
 				'fa_AF' => 'daria',
 				'ff' => 'fula',
 				'fi' => 'finlandiera',
 				'fil' => 'filipinera',
 				'fj' => 'fijiera',
 				'fo' => 'faroera',
 				'fon' => 'fona',
 				'fr' => 'frantses',
 				'fr_CA' => 'Kanadako frantses',
 				'fr_CH' => 'Suitzako frantses',
 				'frc' => 'cajun frantsesa',
 				'fur' => 'fruilera',
 				'fy' => 'frisiera',
 				'ga' => 'irlandera',
 				'gaa' => 'ga',
 				'gag' => 'gagauzera',
 				'gd' => 'Eskoziako gaeliko',
 				'gez' => 'ge’ez',
 				'gil' => 'gilbertera',
 				'gl' => 'galiziera',
 				'gn' => 'guaraniera',
 				'gor' => 'gorontaloa',
 				'gsw' => 'Suitzako aleman',
 				'gu' => 'gujaratera',
 				'guz' => 'gusiiera',
 				'gv' => 'manxera',
 				'gwi' => 'gwichʼin',
 				'ha' => 'hausa',
 				'haw' => 'hawaiiera',
 				'he' => 'hebreera',
 				'hi' => 'hindi',
 				'hil' => 'hiligainon',
 				'hmn' => 'hmong',
 				'hr' => 'kroaziera',
 				'hsb' => 'goi-sorabiera',
 				'ht' => 'Haitiko kreolera',
 				'hu' => 'hungariera',
 				'hup' => 'hupera',
 				'hy' => 'armeniera',
 				'hz' => 'hereroera',
 				'ia' => 'interlingua',
 				'iba' => 'ibanera',
 				'ibb' => 'ibibioera',
 				'id' => 'indonesiera',
 				'ie' => 'interlingue',
 				'ig' => 'igboera',
 				'ii' => 'Sichuango yiera',
 				'ilo' => 'ilokanera',
 				'inh' => 'ingushera',
 				'io' => 'ido',
 				'is' => 'islandiera',
 				'it' => 'italiera',
 				'iu' => 'inuktitut',
 				'ja' => 'japoniera',
 				'jbo' => 'lojbanera',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jv' => 'javera',
 				'ka' => 'georgiera',
 				'kab' => 'kabilera',
 				'kac' => 'jingpoera',
 				'kaj' => 'kaiji',
 				'kam' => 'kambera',
 				'kbd' => 'kabardiera',
 				'kcg' => 'kataba',
 				'kde' => 'makondeera',
 				'kea' => 'Cabo Verdeko kreolera',
 				'kfo' => 'koroa',
 				'kg' => 'kikongoa',
 				'kgp' => 'kaingang',
 				'kha' => 'kashia',
 				'khq' => 'koyra chiini',
 				'ki' => 'kikuyuera',
 				'kj' => 'kuanyama',
 				'kk' => 'kazakhera',
 				'kkj' => 'kako',
 				'kl' => 'groenlandiera',
 				'kln' => 'kalenjinera',
 				'km' => 'khemerera',
 				'kmb' => 'kimbundua',
 				'kn' => 'kannada',
 				'ko' => 'koreera',
 				'koi' => 'komi-permyakera',
 				'kok' => 'konkanera',
 				'kpe' => 'kpellea',
 				'kr' => 'kanuriera',
 				'krc' => 'karachayera-balkarera',
 				'krl' => 'kareliera',
 				'kru' => 'kurukhera',
 				'ks' => 'kaxmirera',
 				'ksb' => 'shambalera',
 				'ksf' => 'bafiera',
 				'ksh' => 'koloniera',
 				'ku' => 'kurduera',
 				'kum' => 'kumykera',
 				'kv' => 'komiera',
 				'kw' => 'kornubiera',
 				'ky' => 'kirgizera',
 				'la' => 'latin',
 				'lad' => 'ladino',
 				'lag' => 'langiera',
 				'lb' => 'luxenburgera',
 				'lez' => 'lezgiera',
 				'lg' => 'luganda',
 				'li' => 'limburgera',
 				'lij' => 'liguriera',
 				'lkt' => 'lakotera',
 				'ln' => 'lingala',
 				'lo' => 'laosera',
 				'lou' => 'Louisianako kreolera',
 				'loz' => 'loziera',
 				'lrc' => 'iparraldeko lurera',
 				'lt' => 'lituaniera',
 				'lu' => 'Katangako lubera',
 				'lua' => 'txilubera',
 				'lun' => 'lundera',
 				'luo' => 'luoera',
 				'lus' => 'mizoa',
 				'luy' => 'luhyera',
 				'lv' => 'letoniera',
 				'mad' => 'madurera',
 				'mag' => 'magahiera',
 				'mai' => 'maithilera',
 				'mak' => 'makasarera',
 				'mas' => 'masaiera',
 				'mdf' => 'mokxera',
 				'men' => 'mendeera',
 				'mer' => 'meruera',
 				'mfe' => 'Mauritaniako kreolera',
 				'mg' => 'malgaxe',
 				'mgh' => 'makhuwa-meettoera',
 				'mgo' => 'metaʼera',
 				'mh' => 'marshallera',
 				'mi' => 'maoriera',
 				'mic' => 'mikmakera',
 				'min' => 'minangkabauera',
 				'mk' => 'mazedoniera',
 				'ml' => 'malabarera',
 				'mn' => 'mongoliera',
 				'mni' => 'manipurera',
 				'moh' => 'mohawkera',
 				'mos' => 'moreera',
 				'mr' => 'marathera',
 				'ms' => 'malaysiera',
 				'mt' => 'maltera',
 				'mua' => 'mudangera',
 				'mul' => 'zenbait hizkuntza',
 				'mus' => 'creera',
 				'mwl' => 'mirandera',
 				'my' => 'birmaniera',
 				'myv' => 'erziera',
 				'mzn' => 'mazandarandera',
 				'na' => 'nauruera',
 				'nap' => 'napoliera',
 				'naq' => 'namera',
 				'nb' => 'bokmål (norvegiera)',
 				'nd' => 'iparraldeko ndebeleera',
 				'nds' => 'behe-aleman',
 				'nds_NL' => 'behe-saxoiera',
 				'ne' => 'nepalera',
 				'new' => 'newarera',
 				'ng' => 'ndongera',
 				'nia' => 'niasera',
 				'niu' => 'niueera',
 				'nl' => 'nederlandera',
 				'nl_BE' => 'flandriera',
 				'nmg' => 'kwasiera',
 				'nn' => 'nynorsk (norvegiera)',
 				'nnh' => 'ngiemboonera',
 				'no' => 'norvegiera',
 				'nog' => 'nogaiera',
 				'nqo' => 'n’koera',
 				'nr' => 'hegoaldeko ndebelera',
 				'nso' => 'pediera',
 				'nus' => 'nuerera',
 				'nv' => 'navajoera',
 				'ny' => 'chewera',
 				'nyn' => 'ankolera',
 				'oc' => 'okzitaniera',
 				'om' => 'oromoera',
 				'or' => 'oriya',
 				'os' => 'osetiera',
 				'pa' => 'punjabera',
 				'pag' => 'pangasinanera',
 				'pam' => 'pampangera',
 				'pap' => 'papiamento',
 				'pau' => 'palauera',
 				'pcm' => 'Nigeriako pidgina',
 				'pl' => 'poloniera',
 				'prg' => 'prusiera',
 				'ps' => 'paxtuera',
 				'pt' => 'portuges',
 				'pt_BR' => 'Brasilgo portuges',
 				'pt_PT' => 'Europako portuges',
 				'qu' => 'kitxua',
 				'quc' => 'quicheera',
 				'rap' => 'rapa nui',
 				'rar' => 'rarotongera',
 				'rhg' => 'rohingyera',
 				'rm' => 'erretorromaniera',
 				'rn' => 'rundiera',
 				'ro' => 'errumaniera',
 				'ro_MD' => 'moldaviera',
 				'rof' => 'rombo',
 				'ru' => 'errusiera',
 				'rup' => 'aromaniera',
 				'rw' => 'kinyaruanda',
 				'rwk' => 'rwera',
 				'sa' => 'sanskrito',
 				'sad' => 'sandaweera',
 				'sah' => 'sakhera',
 				'saq' => 'samburuera',
 				'sat' => 'santalera',
 				'sba' => 'ngambayera',
 				'sbp' => 'sanguera',
 				'sc' => 'sardiniera',
 				'scn' => 'siziliera',
 				'sco' => 'eskoziera',
 				'sd' => 'sindhi',
 				'se' => 'iparraldeko samiera',
 				'seh' => 'senera',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'sh' => 'serbokroaziera',
 				'shi' => 'tachelhit',
 				'shn' => 'shanera',
 				'si' => 'sinhala',
 				'sk' => 'eslovakiera',
 				'sl' => 'esloveniera',
 				'sm' => 'samoera',
 				'sma' => 'hegoaldeko samiera',
 				'smj' => 'Luleko samiera',
 				'smn' => 'Inariko samiera',
 				'sms' => 'skolten samiera',
 				'sn' => 'shonera',
 				'snk' => 'soninkera',
 				'so' => 'somaliera',
 				'sq' => 'albaniera',
 				'sr' => 'serbiera',
 				'srn' => 'srananera',
 				'ss' => 'swatiera',
 				'ssy' => 'sahoa',
 				'st' => 'hegoaldeko sothoera',
 				'su' => 'sundanera',
 				'suk' => 'sukumera',
 				'sv' => 'suediera',
 				'sw' => 'swahilia',
 				'sw_CD' => 'Kongoko swahilia',
 				'swb' => 'komoreera',
 				'syr' => 'asiriera',
 				'ta' => 'tamilera',
 				'te' => 'telugu',
 				'tem' => 'temnea',
 				'teo' => 'tesoera',
 				'tet' => 'tetum',
 				'tg' => 'tajikera',
 				'th' => 'thailandiera',
 				'ti' => 'tigrinyera',
 				'tig' => 'tigrea',
 				'tk' => 'turkmenera',
 				'tl' => 'tagaloa',
 				'tlh' => 'klingonera',
 				'tn' => 'tswanera',
 				'to' => 'tongera',
 				'tpi' => 'tok pisin',
 				'tr' => 'turkiera',
 				'trv' => 'tarokoa',
 				'ts' => 'tsongera',
 				'tt' => 'tatarera',
 				'tum' => 'tumbukera',
 				'tvl' => 'tuvaluera',
 				'tw' => 'twia',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitiera',
 				'tyv' => 'tuvera',
 				'tzm' => 'Erdialdeko Atlaseko amazigera',
 				'udm' => 'udmurtera',
 				'ug' => 'uigurrera',
 				'uk' => 'ukrainera',
 				'umb' => 'umbundu',
 				'und' => 'hizkuntza ezezaguna',
 				'ur' => 'urdu',
 				'uz' => 'uzbekera',
 				'vai' => 'vaiera',
 				've' => 'vendera',
 				'vi' => 'vietnamera',
 				'vo' => 'volapük',
 				'vun' => 'vunjo',
 				'wa' => 'waloiera',
 				'wae' => 'walserera',
 				'wal' => 'welayta',
 				'war' => 'samerera',
 				'wo' => 'wolofera',
 				'xal' => 'kalmykera',
 				'xh' => 'xhosera',
 				'xog' => 'sogera',
 				'yav' => 'yangbenera',
 				'ybb' => 'yemba',
 				'yi' => 'yiddish',
 				'yo' => 'jorubera',
 				'yue' => 'kantonera',
 				'yue@alt=menu' => 'Kantongo txinera',
 				'zgh' => 'amazigera estandarra',
 				'zh' => 'txinera',
 				'zh@alt=menu' => 'mandarin',
 				'zh_Hans' => 'txinera sinplifikatu',
 				'zh_Hans@alt=long' => 'mandarin sinplifikatu',
 				'zh_Hant' => 'txinera tradizionala',
 				'zh_Hant@alt=long' => 'mandarin tradizional',
 				'zu' => 'zuluera',
 				'zun' => 'zuñia',
 				'zxx' => 'ez dago eduki linguistikorik',
 				'zza' => 'zazera',

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
 			'Aghb' => 'Kaukasoko albaniera',
 			'Ahom' => 'ahomera',
 			'Arab' => 'arabiarra',
 			'Arab@alt=variant' => 'persiar-arabiarra',
 			'Aran' => 'nastaliq',
 			'Armi' => 'aramiera inperiarra',
 			'Armn' => 'armeniarra',
 			'Avst' => 'avestera',
 			'Bali' => 'baliera',
 			'Bamu' => 'bamum',
 			'Bass' => 'bassa vah',
 			'Batk' => 'batak',
 			'Beng' => 'bengalarra',
 			'Bhks' => 'bhaiksuki',
 			'Bopo' => 'bopomofoa',
 			'Brah' => 'brahmiera',
 			'Brai' => 'braillea',
 			'Bugi' => 'buginera',
 			'Buhd' => 'buhid',
 			'Cakm' => 'txakma',
 			'Cans' => 'Kanadiako aborigenen silabiko bateratua',
 			'Cari' => 'kariera',
 			'Cham' => 'txamera',
 			'Cher' => 'txerokiera',
 			'Chrs' => 'korasmiera',
 			'Copt' => 'koptikera',
 			'Cpmn' => 'zipro-minoera',
 			'Cprt' => 'ziprera',
 			'Cyrl' => 'zirilikoa',
 			'Deva' => 'devanagaria',
 			'Diak' => 'dives akuru',
 			'Dogr' => 'dogrera',
 			'Dsrt' => 'deseret',
 			'Dupl' => 'duployiar takigrafia',
 			'Egyp' => 'egiptoar hieroglifikoak',
 			'Elba' => 'elbasanera',
 			'Elym' => 'elimaikera',
 			'Ethi' => 'etiopiarra',
 			'Geor' => 'georgiarra',
 			'Glag' => 'glagolitikera',
 			'Gong' => 'gunjala gondi',
 			'Gonm' => 'masaram gondiera',
 			'Goth' => 'gotikoa',
 			'Gran' => 'grantha',
 			'Grek' => 'grekoa',
 			'Gujr' => 'gujaratarra',
 			'Guru' => 'gurmukhia',
 			'Hanb' => 'hänera',
 			'Hang' => 'hangula',
 			'Hani' => 'idazkera txinatarra',
 			'Hano' => 'hanunuera',
 			'Hans' => 'sinplifikatua',
 			'Hans@alt=stand-alone' => 'idazkera txinatar sinplifikatua',
 			'Hant' => 'tradizionala',
 			'Hant@alt=stand-alone' => 'idazkera txinatar tradizionala',
 			'Hatr' => 'hatreoera',
 			'Hebr' => 'hebrearra',
 			'Hira' => 'hiragana',
 			'Hluw' => 'hieroglifiko anatoliarrak',
 			'Hmng' => 'pahawh hmongera',
 			'Hmnp' => 'nyiakeng puachue hmong',
 			'Hrkt' => 'silabario japoniarrak',
 			'Hung' => 'hungariera zaharra',
 			'Ital' => 'italiera zaharra',
 			'Jamo' => 'jamo-bihurketa',
 			'Java' => 'javaniera',
 			'Jpan' => 'japoniarra',
 			'Kali' => 'kayah li',
 			'Kana' => 'katakana',
 			'Khar' => 'kharoshthi',
 			'Khmr' => 'khemerarra',
 			'Khoj' => 'khojkiera',
 			'Kits' => 'khitanerako script txikiak',
 			'Knda' => 'kanadarra',
 			'Kore' => 'korearra',
 			'Kthi' => 'kaithiera',
 			'Lana' => 'lannera',
 			'Laoo' => 'laosarra',
 			'Latn' => 'latinoa',
 			'Lepc' => 'leptxa',
 			'Limb' => 'linbuera',
 			'Lina' => 'A linearra',
 			'Linb' => 'B linearra',
 			'Lisu' => 'fraserera',
 			'Lyci' => 'liziera',
 			'Lydi' => 'lidiera',
 			'Mahj' => 'mahajaniera',
 			'Maka' => 'makasarrera',
 			'Mand' => 'mandaera',
 			'Mani' => 'manikeoa',
 			'Marc' => 'martxenera',
 			'Medf' => 'medefaidrinera',
 			'Mend' => 'mende',
 			'Merc' => 'meroitiar etzana',
 			'Mero' => 'meroitirra',
 			'Mlym' => 'malayalamarra',
 			'Modi' => 'modiera',
 			'Mong' => 'mongoliarra',
 			'Mroo' => 'mroera',
 			'Mtei' => 'meitei mayekera',
 			'Mult' => 'multaniera',
 			'Mymr' => 'birmaniarra',
 			'Nand' => 'nandinagariera',
 			'Narb' => 'iparraldeko arabiera zaharra',
 			'Nbat' => 'nabatera',
 			'Newa' => 'newaera',
 			'Nkoo' => 'n’ko',
 			'Nshu' => 'nushuera',
 			'Ogam' => 'oghamera',
 			'Olck' => 'ol txikiera',
 			'Orkh' => 'orkhonera',
 			'Orya' => 'oriyarra',
 			'Osge' => 'osagera',
 			'Osma' => 'osmaiera',
 			'Ougr' => 'uigurrera zaharra',
 			'Palm' => 'palmiera',
 			'Pauc' => 'pau cin hau',
 			'Perm' => 'permiera zaharra',
 			'Phag' => 'phags-pa',
 			'Phli' => 'pahlavi inskripzioak',
 			'Phlp' => 'Pahlavi salmo-liburua',
 			'Phnx' => 'feniziera',
 			'Plrd' => 'polardera fonetikoa',
 			'Prti' => 'Partiera inskripzioak',
 			'Qaag' => 'zauagiera',
 			'Rjng' => 'Rejang',
 			'Rohg' => 'hanifiera',
 			'Runr' => 'errunikoa',
 			'Samr' => 'samariera',
 			'Sarb' => 'hegoaldeko arabiera zaharra',
 			'Saur' => 'saurashtra',
 			'Sgnw' => 'zeinu-idazketa',
 			'Shaw' => 'shaviera',
 			'Shrd' => 'sharada',
 			'Sidd' => 'siddham',
 			'Sind' => 'khudawadi',
 			'Sinh' => 'sinhala',
 			'Sogd' => 'sogdiera',
 			'Sogo' => 'sogdiera zaharra',
 			'Sora' => 'sora sompeng',
 			'Soyo' => 'soyomboera',
 			'Sund' => 'sudanera',
 			'Sylo' => 'syloti nagriera',
 			'Syrc' => 'siriera',
 			'Tagb' => 'tagbanwa',
 			'Takr' => 'takriera',
 			'Tale' => 'tai le',
 			'Talu' => 'tai lue berria',
 			'Taml' => 'tamilarra',
 			'Tang' => 'tangutera',
 			'Tavt' => 'tai viet',
 			'Telu' => 'teluguarra',
 			'Tfng' => 'tifinagera',
 			'Tglg' => 'tagaloa',
 			'Thaa' => 'thaana',
 			'Thai' => 'thailandiarra',
 			'Tibt' => 'tibetarra',
 			'Tirh' => 'tirhuta',
 			'Tnsa' => 'tangsa',
 			'Toto' => 'totoera',
 			'Ugar' => 'ugaritiera',
 			'Vaii' => 'vaiera',
 			'Vith' => 'vithkuqi',
 			'Wara' => 'varang kshiti',
 			'Wcho' => 'wanchoera',
 			'Xpeo' => 'pertsiera zaharra',
 			'Xsux' => 'sumero-akadiera kuneiformea',
 			'Yezi' => 'yezidiera',
 			'Yiii' => 'yiera',
 			'Zanb' => 'zanabazar koadroa',
 			'Zinh' => 'heredatua',
 			'Zmth' => 'matematikako notazioa',
 			'Zsye' => 'emotikonoa',
 			'Zsym' => 'ikurrak',
 			'Zxxx' => 'idatzi gabea',
 			'Zyyy' => 'ohikoa',
 			'Zzzz' => 'idazkera ezezaguna',

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
			'001' => 'Mundua',
 			'002' => 'Afrika',
 			'003' => 'Ipar Amerika',
 			'005' => 'Hego Amerika',
 			'009' => 'Ozeania',
 			'011' => 'Afrika mendebaldea',
 			'013' => 'Erdialdeko Amerika',
 			'014' => 'Afrika ekialdea',
 			'015' => 'Afrika iparraldea',
 			'017' => 'Erdialdeko Afrika',
 			'018' => 'Afrika hegoaldea',
 			'019' => 'Amerika',
 			'021' => 'Amerikako iparraldea',
 			'029' => 'Karibea',
 			'030' => 'Asia ekialdea',
 			'034' => 'Asia hegoaldea',
 			'035' => 'Asiako hego-ekialdea',
 			'039' => 'Europa hegoaldea',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Mikronesia eskualdea',
 			'061' => 'Polinesia',
 			'142' => 'Asia',
 			'143' => 'Asia erdialdea',
 			'145' => 'Asia mendebaldea',
 			'150' => 'Europa',
 			'151' => 'Europa ekialdea',
 			'154' => 'Europa iparraldea',
 			'155' => 'Europa mendebaldea',
 			'202' => 'Saharaz hegoaldeko Afrika',
 			'419' => 'Latinoamerika',
 			'AC' => 'Ascension uhartea',
 			'AD' => 'Andorra',
 			'AE' => 'Arabiar Emirerri Batuak',
 			'AF' => 'Afganistan',
 			'AG' => 'Antigua eta Barbuda',
 			'AI' => 'Aingira',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antartika',
 			'AR' => 'Argentina',
 			'AS' => 'Samoa Estatubatuarra',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Åland',
 			'AZ' => 'Azerbaijan',
 			'BA' => 'Bosnia-Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgika',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Saint Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BQ' => 'Karibeko Herbehereak',
 			'BR' => 'Brasil',
 			'BS' => 'Bahamak',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouvet uhartea',
 			'BW' => 'Botswana',
 			'BY' => 'Bielorrusia',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Cocos (Keeling) uharteak',
 			'CD' => 'Kongoko Errepublika Demokratikoa',
 			'CD@alt=variant' => 'Kongo (DR)',
 			'CF' => 'Afrika Erdiko Errepublika',
 			'CG' => 'Kongo',
 			'CG@alt=variant' => 'Kongoko Errepublika',
 			'CH' => 'Suitza',
 			'CI' => 'Boli Kosta',
 			'CI@alt=variant' => 'C¨ôte d’Ivore',
 			'CK' => 'Cook uharteak',
 			'CL' => 'Txile',
 			'CM' => 'Kamerun',
 			'CN' => 'Txina',
 			'CO' => 'Kolonbia',
 			'CP' => 'Clipperton uhartea',
 			'CR' => 'Costa Rica',
 			'CU' => 'Kuba',
 			'CV' => 'Cabo Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Christmas uhartea',
 			'CY' => 'Zipre',
 			'CZ' => 'Txekia',
 			'CZ@alt=variant' => 'Txekiar Errepublika',
 			'DE' => 'Alemania',
 			'DG' => 'Diego García',
 			'DJ' => 'Djibuti',
 			'DK' => 'Danimarka',
 			'DM' => 'Dominika',
 			'DO' => 'Dominikar Errepublika',
 			'DZ' => 'Aljeria',
 			'EA' => 'Ceuta eta Melilla',
 			'EC' => 'Ekuador',
 			'EE' => 'Estonia',
 			'EG' => 'Egipto',
 			'EH' => 'Mendebaldeko Sahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Espainia',
 			'ET' => 'Etiopia',
 			'EU' => 'Europar Batasuna',
 			'EZ' => 'Eurogunea',
 			'FI' => 'Finlandia',
 			'FJ' => 'Fiji',
 			'FK' => 'Falklandak',
 			'FK@alt=variant' => 'Falklandak (Malvinak)',
 			'FM' => 'Mikronesia',
 			'FO' => 'Faroe uharteak',
 			'FR' => 'Frantzia',
 			'GA' => 'Gabon',
 			'GB' => 'Erresuma Batua',
 			'GB@alt=short' => 'EB',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'Guyana Frantsesa',
 			'GG' => 'Guernesey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Groenlandia',
 			'GM' => 'Gambia',
 			'GN' => 'Ginea',
 			'GP' => 'Guadalupe',
 			'GQ' => 'Ekuatore Ginea',
 			'GR' => 'Grezia',
 			'GS' => 'Hegoaldeko Georgia eta Hegoaldeko Sandwich uharteak',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Ginea Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hong Kong Txinako AEB',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Heard eta McDonald uharteak',
 			'HN' => 'Honduras',
 			'HR' => 'Kroazia',
 			'HT' => 'Haiti',
 			'HU' => 'Hungaria',
 			'IC' => 'Kanariak',
 			'ID' => 'Indonesia',
 			'IE' => 'Irlanda',
 			'IL' => 'Israel',
 			'IM' => 'Man uhartea',
 			'IN' => 'India',
 			'IO' => 'Indiako Ozeanoko lurralde britainiarra',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Islandia',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordania',
 			'JP' => 'Japonia',
 			'KE' => 'Kenya',
 			'KG' => 'Kirgizistan',
 			'KH' => 'Kanbodia',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoreak',
 			'KN' => 'Saint Kitts eta Nevis',
 			'KP' => 'Ipar Korea',
 			'KR' => 'Hego Korea',
 			'KW' => 'Kuwait',
 			'KY' => 'Kaiman uharteak',
 			'KZ' => 'Kazakhstan',
 			'LA' => 'Laos',
 			'LB' => 'Libano',
 			'LC' => 'Santa Luzia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Lituania',
 			'LU' => 'Luxenburgo',
 			'LV' => 'Letonia',
 			'LY' => 'Libia',
 			'MA' => 'Maroko',
 			'MC' => 'Monako',
 			'MD' => 'Moldavia',
 			'ME' => 'Montenegro',
 			'MF' => 'San Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshall Uharteak',
 			'MK' => 'Ipar Mazedonia',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Birmania)',
 			'MN' => 'Mongolia',
 			'MO' => 'Macau Txinako AEB',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Ipar Mariana uharteak',
 			'MQ' => 'Martinika',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Maurizio',
 			'MV' => 'Maldivak',
 			'MW' => 'Malawi',
 			'MX' => 'Mexiko',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mozambike',
 			'NA' => 'Namibia',
 			'NC' => 'Kaledonia Berria',
 			'NE' => 'Niger',
 			'NF' => 'Norfolk uhartea',
 			'NG' => 'Nigeria',
 			'NI' => 'Nikaragua',
 			'NL' => 'Herbehereak',
 			'NO' => 'Norvegia',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Zeelanda Berria',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Polinesia Frantsesa',
 			'PG' => 'Papua Ginea Berria',
 			'PH' => 'Filipinak',
 			'PK' => 'Pakistan',
 			'PL' => 'Polonia',
 			'PM' => 'Saint-Pierre eta Mikelune',
 			'PN' => 'Pitcairn uharteak',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestinar Lurralde Okupatuak',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguai',
 			'QA' => 'Qatar',
 			'QO' => 'Mugaz kanpoko Ozeania',
 			'RE' => 'Reunion',
 			'RO' => 'Errumania',
 			'RS' => 'Serbia',
 			'RU' => 'Errusia',
 			'RW' => 'Ruanda',
 			'SA' => 'Saudi Arabia',
 			'SB' => 'Salomon Uharteak',
 			'SC' => 'Seychelleak',
 			'SD' => 'Sudan',
 			'SE' => 'Suedia',
 			'SG' => 'Singapur',
 			'SH' => 'Santa Helena',
 			'SI' => 'Eslovenia',
 			'SJ' => 'Svalbard eta Jan Mayen uharteak',
 			'SK' => 'Eslovakia',
 			'SL' => 'Sierra Leona',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinam',
 			'SS' => 'Hego Sudan',
 			'ST' => 'Sao Tome eta Principe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Siria',
 			'SZ' => 'Swazilandia',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turk eta Caico uharteak',
 			'TD' => 'Txad',
 			'TF' => 'Hegoaldeko lurralde frantsesak',
 			'TG' => 'Togo',
 			'TH' => 'Thailandia',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Ekialdeko Timor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Turkia',
 			'TT' => 'Trinidad eta Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'UM' => 'Ameriketako Estatu Batuetako Kanpoaldeko Uharte Txikiak',
 			'UN' => 'Nazio Batuak',
 			'US' => 'Ameriketako Estatu Batuak',
 			'US@alt=short' => 'AEB',
 			'UY' => 'Uruguai',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatikano Hiria',
 			'VC' => 'Saint Vincent eta Grenadinak',
 			'VE' => 'Venezuela',
 			'VG' => 'Birjina uharte britainiarrak',
 			'VI' => 'Birjina uharte amerikarrak',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis eta Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Sasiazentuak',
 			'XB' => 'Pseudobidia',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Hegoafrika',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'Eskualde ezezaguna',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'ortografia aleman tradizionala',
 			'1994' => 'Resiako ortografia estandarizatua',
 			'1996' => '1996ko ortografia alemana',
 			'1606NICT' => 'frantses ertain amaieratik 1606ra',
 			'1694ACAD' => 'frantses moderno goiztiarra',
 			'1959ACAD' => 'akademikoa',
 			'ABL1943' => '1943ko ortografia-formulazioa',
 			'AKUAPEM' => 'AKUAPIMERA',
 			'ALALC97' => 'ALA-LC erromanizazioa, 1997ko edizioa',
 			'ALUKU' => 'Aluku dialektoa',
 			'AO1990' => '1990eko portugesaren ortografia-hitzarmena',
 			'ARANES' => 'ARANERA',
 			'ASANTE' => 'ASANTEERA',
 			'BAKU1926' => 'Turkieraren latindar alfabeto bateratua',
 			'BALANKA' => 'Aniieraren balanka dialektoa',
 			'BARLA' => 'Caboverdeeraren barlavento dialekto taldea',
 			'BISCAYAN' => 'Mendebaldeko euskara',
 			'BISKE' => 'San Giorgio / Bila dialektoa',
 			'BOHORIC' => 'Bohoric alfabetoa',
 			'BOONT' => 'Boontling',
 			'COLB1945' => '1945eko Portugal eta Barasilgo ortografia-hitzarmena',
 			'DAJNKO' => 'Dajnko alfabetoa',
 			'EKAVSK' => 'Serbiera ekavierako ahoskerarekin',
 			'EMODENG' => 'Ingeles moderno goiztiarra',
 			'FONIPA' => 'IPA ahoskera',
 			'FONUPA' => 'UPa ahoskera',
 			'GASCON' => 'GASKOI',
 			'HEPBURN' => 'Hepburn erromanizazioa',
 			'IJEKAVSK' => 'Serbiera ijekavieraren ahoskerarekin',
 			'KKCOR' => 'Ortografia arrunta',
 			'KSCOR' => 'Ortografia estandarra',
 			'LIPAW' => 'Resiako lipovaz dialektoa',
 			'METELKO' => 'Metelko alfabetoa',
 			'MONOTON' => 'Tonu bakarra',
 			'NDYUKA' => 'Ndyuka dialektoa',
 			'NEDIS' => 'Natisoneko dialektoa',
 			'NEWFOUND' => 'TERNUA',
 			'NJIVA' => 'Gniva/Njiva dialektoa',
 			'NULIK' => 'Volapuk modernoa',
 			'OSOJS' => 'Oseacco/Osojane dialektoa',
 			'OXENDICT' => 'Oxfordeko ingeles-hiztegiko ortografia',
 			'PAMAKA' => 'Pamaka dialektoa',
 			'PINYIN' => 'Pinyin erromanizazioa',
 			'POLYTON' => 'Tonu anitza',
 			'POSIX' => 'Ordenagailua',
 			'REVISED' => 'Ortografia berrikusia',
 			'RIGIK' => 'Volapuk klasikoa',
 			'ROZAJ' => 'Resiera',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Eskoziar ingeles estandarra',
 			'SCOUSE' => 'Scouse',
 			'SIMPLE' => 'SOILA',
 			'SOLBA' => 'Stolvizza/Solbica dialektoa',
 			'SOTAV' => 'Caboverdeerako sotavento dialekto taldea',
 			'SPANGLIS' => 'SPANGLISH',
 			'TARASK' => 'Taraskievica ortografia',
 			'UCCOR' => 'Ortografia bateratua',
 			'UCRCOR' => 'Ortografia berrikusi bateratua',
 			'UNIFON' => 'Alfabeto fonetiko unifonoa',
 			'VALENCIA' => 'Valentziera',
 			'WADEGILE' => 'Wade-Giles erromanizazioa',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Egutegia',
 			'cf' => 'Moneta-formatua',
 			'colalternate' => 'Egin ez ikusi ikurren ordenari',
 			'colbackwards' => 'Azentuen alderantzizko ordena',
 			'colcasefirst' => 'Maiuskula/Minuskula ordena',
 			'colcaselevel' => 'Maiuskulak eta minuskulak bereizten dituen ordena',
 			'collation' => 'Ordenatzeko irizpidea',
 			'colnormalization' => 'Araututako ordena',
 			'colnumeric' => 'Zenbakizko ordena',
 			'colstrength' => 'Ordenaren sendotasuna',
 			'currency' => 'Moneta',
 			'hc' => 'Ordu-zikloa (12 vs 24)',
 			'lb' => 'Lerro-jauziaren estiloa',
 			'ms' => 'Neurketa-sistema',
 			'numbers' => 'Zenbakiak',
 			'timezone' => 'Ordu-zona',
 			'va' => 'Eskualdeko ezarpenen aldaera',
 			'x' => 'Erabilera pribatua',

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
 				'buddhist' => q{Egutegi budista},
 				'chinese' => q{Txinatar egutegia},
 				'coptic' => q{Egutegi coptiarra},
 				'dangi' => q{Dangi egutegia},
 				'ethiopic' => q{Egutegi etiopiarra},
 				'ethiopic-amete-alem' => q{Amete Alem egutegi etiopiarra},
 				'gregorian' => q{Egutegi gregoriarra},
 				'hebrew' => q{Hebrear egutegia},
 				'indian' => q{Indiar egutegia},
 				'islamic' => q{Islamiar egutegia},
 				'islamic-civil' => q{Islamiar egutegia (taula-formakoa, garai zibilekoa)},
 				'islamic-rgsa' => q{Islamiar egutegia (Saudi Arabia, ikuspegiak)},
 				'islamic-tbla' => q{Islamiar egutegia (taula-formakoa, gai astronomikokoa)},
 				'islamic-umalqura' => q{Islamiar egutegia (Umm al-Qura)},
 				'iso8601' => q{ISO-8601 egutegia},
 				'japanese' => q{Japoniar egutegia},
 				'persian' => q{Egutegi persiarra},
 				'roc' => q{Minguo egutegia},
 			},
 			'cf' => {
 				'account' => q{Kontabilitateko moneta-formatua},
 				'standard' => q{Moneta-formatu estandarra},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Ordenatu ikurrak},
 				'shifted' => q{Ordenatu ikurrei ez ikusi eginda},
 			},
 			'colbackwards' => {
 				'no' => q{Ordenatu azentuak modu normalean},
 				'yes' => q{Ordenatu azentuak alderantziz},
 			},
 			'colcasefirst' => {
 				'lower' => q{Ordenatu minuskulak lehenik},
 				'no' => q{Ordenatu maiuskulak modu normalean},
 				'upper' => q{Ordenatu maiuskulak lehenik},
 			},
 			'colcaselevel' => {
 				'no' => q{Ordenatu maiuskulak eta minuskulak bereizi gabe},
 				'yes' => q{Ordenatu maiuskulak eta minuskulak bereizita},
 			},
 			'collation' => {
 				'big5han' => q{Txinera tradizionalaren alfabetoa-Big5},
 				'compat' => q{Aurreko hurrenkera, bateragarria izateko},
 				'dictionary' => q{Hurrenkera alfabetikoa},
 				'ducet' => q{Unicode hurrenkera lehenetsia},
 				'emoji' => q{Emojien hurrenkera},
 				'eor' => q{Europako ordenatzeko arauak},
 				'gb2312han' => q{Txinera sinplifikatuaren alfabetoa -GB2312},
 				'phonebook' => q{Telefonoen zerrenda},
 				'phonetic' => q{Ordenatzeko irizpide fonetikoa},
 				'pinyin' => q{Pinyin hurrenkera},
 				'reformed' => q{Erreformaren araberako hurrenkera},
 				'search' => q{Bilaketa orokorra},
 				'searchjl' => q{Bilatu hangularen lehen kontsonantearen arabera},
 				'standard' => q{Ordenatzeko irizpide estandarra},
 				'stroke' => q{Tarteen araberako hurrenkera},
 				'traditional' => q{Tradizionala},
 				'unihan' => q{Radical trazuen hurrenkera},
 				'zhuyin' => q{Zhuyin hurrenkera},
 			},
 			'colnormalization' => {
 				'no' => q{Ordenatu arauak kontuan hartu gabe},
 				'yes' => q{Ordenatu Unicode arauen arabera},
 			},
 			'colnumeric' => {
 				'no' => q{Ordenatu digituak banaka},
 				'yes' => q{Ordenatu digituak zenbakien arabera},
 			},
 			'colstrength' => {
 				'identical' => q{Ordenatu guztiak},
 				'primary' => q{Ordenatu oinarrizko hizkiak soilik},
 				'quaternary' => q{Ordenatu azentuak / maiuskula eta minuskulak / zabalera / kanak},
 				'secondary' => q{Ordenatu azentuak},
 				'tertiary' => q{Ordenatu azentuak / maiuskula eta minuskulak / zabalera},
 			},
 			'd0' => {
 				'fwidth' => q{Zabalera osoko karaktere-bihurketa},
 				'hwidth' => q{Zabalera erdiko karaktere-bihurketa},
 				'npinyin' => q{Zenbakizko bihurketa},
 			},
 			'hc' => {
 				'h11' => q{12 orduko sistema (0–11)},
 				'h12' => q{12 orduko sistema (1–12)},
 				'h23' => q{24 orduko sistema (0–23)},
 				'h24' => q{24 orduko sistema (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Lerro-jauziaren estilo malgua},
 				'normal' => q{Lerro-jauziaren estilo arrunta},
 				'strict' => q{Lerro-jauziaren estilo zorrotza},
 			},
 			'm0' => {
 				'bgn' => q{US BGN transliterazioa},
 				'ungegn' => q{UN GEGN transliterazioa},
 			},
 			'ms' => {
 				'metric' => q{Sistema metrikoa},
 				'uksystem' => q{Neurketa-sistema inperiala},
 				'ussystem' => q{Neurketa-sistema anglosaxoia},
 			},
 			'numbers' => {
 				'ahom' => q{Ahom digituak},
 				'arab' => q{Digitu arabiar-hindikoak},
 				'arabext' => q{Digitu arabiar-hindiko hedatuak},
 				'armn' => q{Zenbaki armeniarrak},
 				'armnlow' => q{Zenbaki armeniarrak minuskulaz},
 				'bali' => q{Digitu balitarrak},
 				'beng' => q{Digitu bengalarrak},
 				'brah' => q{Brahmi digituak},
 				'cakm' => q{Txakma digituak},
 				'cham' => q{Txam digituak},
 				'cyrl' => q{Zenbaki zirilikoak},
 				'deva' => q{Digitu devanagariak},
 				'diak' => q{Dives Akuru digituak},
 				'ethi' => q{Zenbaki etiopiarrak},
 				'finance' => q{Finantza-zenbakiak},
 				'fullwide' => q{Zabalera osoko digituak},
 				'geor' => q{Zenbaki georgiarrak},
 				'gong' => q{Gunjala Gondi digituak},
 				'gonm' => q{Masaram Gondi digituak},
 				'grek' => q{Zenbaki grekoak},
 				'greklow' => q{Zenbaki grekoak minuskulaz},
 				'gujr' => q{Digitu gujaratarrak},
 				'guru' => q{Digitu gurmukhiak},
 				'hanidec' => q{Zenbaki hamartar txinatarrak},
 				'hans' => q{Zenbaki txinatar sinplifikatuak},
 				'hansfin' => q{Finantzetarako zenbaki txinatar sinplifikatuak},
 				'hant' => q{Zenbaki txinatar tradizionalak},
 				'hantfin' => q{Finantzetarako zenbaki txinatar tradizionalak},
 				'hebr' => q{Zenbaki hebrearrak},
 				'hmng' => q{Pahawh Hmong digituak},
 				'hmnp' => q{Nyiakeng Puachue Hmong digituak},
 				'java' => q{Digitu javatarrak},
 				'jpan' => q{Zenbaki japoniarrak},
 				'jpanfin' => q{Finantzetarako zenbaki japoniarrak},
 				'kali' => q{Kayah Li digituak},
 				'khmr' => q{Digitu khemerarrak},
 				'knda' => q{Digitu kannadarrak},
 				'lana' => q{Tai Tham Hora digituak},
 				'lanatham' => q{Tai Tham Tham digituak},
 				'laoo' => q{Digitu laostarrak},
 				'latn' => q{Digitu mendebaldarrak},
 				'lepc' => q{Digitu leptxatarrak},
 				'limb' => q{Digitu limbutarrak},
 				'mathbold' => q{Digitu matematiko lodiak},
 				'mathdbl' => q{Marra bikoitzeko digitu matematikoak},
 				'mathmono' => q{Zuriune bakarreko digitu matematikoak},
 				'mathsanb' => q{Sans-Serif Bold digitu matematikoak},
 				'mathsans' => q{Sans-Serif digitu matematikoak},
 				'mlym' => q{Digitu malayalamarrak},
 				'modi' => q{Modi digituak},
 				'mong' => q{Digitu mongoliarrak},
 				'mroo' => q{Mro digituak},
 				'mtei' => q{Meetei Mayek digituak},
 				'mymr' => q{Digitu birmaniarrak},
 				'mymrshan' => q{Shan digitu birmaniarrak},
 				'mymrtlng' => q{Tai Laing digitu birmaniarrak},
 				'native' => q{Zenbaki-sistema},
 				'nkoo' => q{N’Ko digituak},
 				'olck' => q{Ol Chiki digituak},
 				'orya' => q{Digitu oriyarrak},
 				'osma' => q{Digitu osmanyarrak},
 				'rohg' => q{Hanifi digitu rohingyak},
 				'roman' => q{Zenbaki erromatarrak},
 				'romanlow' => q{Zenbaki erromatarrak minuskulaz},
 				'saur' => q{Digitu saurashtrarrak},
 				'shrd' => q{Digitu sharadarrak},
 				'sind' => q{Digitu khudawadiarrak},
 				'sinh' => q{Sinhala Lith digituak},
 				'sora' => q{Sora Sompeng digituak},
 				'sund' => q{Digitu sundadarrak},
 				'takr' => q{Digitu takriarrak},
 				'talu' => q{Digitu tai lue berriak},
 				'taml' => q{Zenbaki tamilar tradizionalak},
 				'tamldec' => q{Digitu tamilarrak},
 				'telu' => q{Digitu teluguarrak},
 				'thai' => q{Digitu thailandiarrak},
 				'tibt' => q{Digitu tibetarrak},
 				'tirh' => q{Tirhuta digituak},
 				'traditional' => q{Zenbaki tradizionalak},
 				'vaii' => q{Vai digituak},
 				'wara' => q{Warang Citi digituak},
 				'wcho' => q{Wancho digituak},
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
			'metric' => q{Sistema metrikoa},
 			'UK' => q{Erresuma Batuko sistema},
 			'US' => q{AEBetako sistema},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => '{0}',
 			'script' => '{0}',
 			'region' => '{0}',

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
			auxiliary => qr{[á à ă â å ä ã ā æ é è ĕ ê ë ē í ì ĭ î ï ī ó ò ŏ ô ö ø ō œ ú ù ŭ û ü ū ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b c ç d e f g h i j k l m n ñ o p q r s t u v w x y z]},
			numbers => qr{[, . % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ ‑ – — , ; \: ! ? . … ' ‘ ’ " “ ” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
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
			'word-final' => '{0}…',
			'word-initial' => '…{0}',
			'word-medial' => '{0}…{1}',
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
						'name' => q(puntu kardinala),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(puntu kardinala),
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
						'1' => q(yobe{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yobe{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(dezi{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(dezi{0}),
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
						'1' => q(zenti{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(zenti{0}),
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
						'1' => q(jokto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(jokto{0}),
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
						'1' => q(exa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(exa{0}),
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
						'1' => q(zetta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zetta{0}),
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
						'name' => q(grabitate-indar),
						'one' => q({0} grabitate-indar),
						'other' => q({0} grabitate-indar),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(grabitate-indar),
						'one' => q({0} grabitate-indar),
						'other' => q({0} grabitate-indar),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metroak segundo karratu bakoitzeko),
						'one' => q({0} metro segundo karratu bakoitzeko),
						'other' => q({0} metro segundo karratu bakoitzeko),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metroak segundo karratu bakoitzeko),
						'one' => q({0} metro segundo karratu bakoitzeko),
						'other' => q({0} metro segundo karratu bakoitzeko),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(arku-minutuak),
						'one' => q({0} arku-minutu),
						'other' => q({0} arku-minutu),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arku-minutuak),
						'one' => q({0} arku-minutu),
						'other' => q({0} arku-minutu),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arku-segundoak),
						'one' => q({0} arku-segundo),
						'other' => q({0} arku-segundo),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arku-segundoak),
						'one' => q({0} arku-segundo),
						'other' => q({0} arku-segundo),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(graduak),
						'one' => q({0} gradu),
						'other' => q({0} gradu),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(graduak),
						'one' => q({0} gradu),
						'other' => q({0} gradu),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radianak),
						'one' => q({0} radian),
						'other' => q({0} radian),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radianak),
						'one' => q({0} radian),
						'other' => q({0} radian),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(bira),
						'one' => q({0} bira),
						'other' => q({0} bira),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(bira),
						'one' => q({0} bira),
						'other' => q({0} bira),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(akre),
						'one' => q({0} akre),
						'other' => q({0} akre),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(akre),
						'one' => q({0} akre),
						'other' => q({0} akre),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektarea),
						'one' => q({0} hektarea),
						'other' => q({0} hektarea),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektarea),
						'one' => q({0} hektarea),
						'other' => q({0} hektarea),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} zentimetro karratu),
						'other' => q({0} zentimetro karratu),
						'per' => q({0} zentimetro karratu bakoitzeko),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} zentimetro karratu),
						'other' => q({0} zentimetro karratu),
						'per' => q({0} zentimetro karratu bakoitzeko),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(oin karratu),
						'one' => q({0} oin karratu),
						'other' => q({0} oin karratu),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(oin karratu),
						'one' => q({0} oin karratu),
						'other' => q({0} oin karratu),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(hazbete karratu),
						'one' => q({0} hazbete karratu),
						'other' => q({0} hazbete karratu),
						'per' => q({0}/in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(hazbete karratu),
						'one' => q({0} hazbete karratu),
						'other' => q({0} hazbete karratu),
						'per' => q({0}/in²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kilometro karratu),
						'one' => q({0} kilometro karratu),
						'other' => q({0} kilometro karratu),
						'per' => q({0} kilometro karratu bakoitzeko),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kilometro karratu),
						'one' => q({0} kilometro karratu),
						'other' => q({0} kilometro karratu),
						'per' => q({0} kilometro karratu bakoitzeko),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metro karratu),
						'one' => q({0} metro karratu),
						'other' => q({0} metro karratu),
						'per' => q({0} metro karratu bakoitzeko),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metro karratu),
						'one' => q({0} metro karratu),
						'other' => q({0} metro karratu),
						'per' => q({0} metro karratu bakoitzeko),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(milia karratu),
						'one' => q({0} milia karratu),
						'other' => q({0} milia karratu),
						'per' => q({0} milia karratu bakoitzeko),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(milia karratu),
						'one' => q({0} milia karratu),
						'other' => q({0} milia karratu),
						'per' => q({0} milia karratu bakoitzeko),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yarda karratu),
						'one' => q({0} yarda karratu),
						'other' => q({0} yarda karratu),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yarda karratu),
						'one' => q({0} yarda karratu),
						'other' => q({0} yarda karratu),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(elementua),
						'one' => q({0} elementu),
						'other' => q({0} elementu),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(elementua),
						'one' => q({0} elementu),
						'other' => q({0} elementu),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(kilateak),
						'one' => q({0} kilate),
						'other' => q({0} kilate),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(kilateak),
						'one' => q({0} kilate),
						'other' => q({0} kilate),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(miligramo dezilitro bakoitzeko),
						'one' => q({0} miligramo dezilitro bakoitzeko),
						'other' => q({0} miligramo dezilitro bakoitzeko),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(miligramo dezilitro bakoitzeko),
						'one' => q({0} miligramo dezilitro bakoitzeko),
						'other' => q({0} miligramo dezilitro bakoitzeko),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimole litro bakoitzeko),
						'one' => q({0} milimole litro bakoitzeko),
						'other' => q({0} milimole litro bakoitzeko),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimole litro bakoitzeko),
						'one' => q({0} milimole litro bakoitzeko),
						'other' => q({0} milimole litro bakoitzeko),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(ehuneko),
						'one' => q(ehuneko {0}),
						'other' => q(ehuneko {0}),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(ehuneko),
						'one' => q(ehuneko {0}),
						'other' => q(ehuneko {0}),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(milako),
						'one' => q(milako {0}),
						'other' => q(milako {0}),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(milako),
						'one' => q(milako {0}),
						'other' => q(milako {0}),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(zati milioi bakoitzeko),
						'one' => q({0} zati milioi bakoitzeko),
						'other' => q({0} zati milioi bakoitzeko),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(zati milioi bakoitzeko),
						'one' => q({0} zati milioi bakoitzeko),
						'other' => q({0} zati milioi bakoitzeko),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q(‱ {0}),
						'other' => q(‱ {0}),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q(‱ {0}),
						'other' => q(‱ {0}),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litro 100 kilometro bakoitzeko),
						'one' => q({0} litro 100 kilometro bakoitzeko),
						'other' => q({0} litro 100 kilometro bakoitzeko),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litro 100 kilometro bakoitzeko),
						'one' => q({0} litro 100 kilometro bakoitzeko),
						'other' => q({0} litro 100 kilometro bakoitzeko),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(litro kilometro bakoitzeko),
						'one' => q({0} litro kilometro bakoitzeko),
						'other' => q({0} litro kilometro bakoitzeko),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(litro kilometro bakoitzeko),
						'one' => q({0} litro kilometro bakoitzeko),
						'other' => q({0} litro kilometro bakoitzeko),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(milia galoi bakoitzeko),
						'one' => q({0} milia galoi bakoitzeko),
						'other' => q({0} milia galoi bakoitzeko),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(milia galoi bakoitzeko),
						'one' => q({0} milia galoi bakoitzeko),
						'other' => q({0} milia galoi bakoitzeko),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(milia galoi britainiar bakoitzeko),
						'one' => q({0} milia galoi britainiar bakoitzeko),
						'other' => q({0} milia galoi britainiar bakoitzeko),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(milia galoi britainiar bakoitzeko),
						'one' => q({0} milia galoi britainiar bakoitzeko),
						'other' => q({0} milia galoi britainiar bakoitzeko),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} I),
						'south' => q({0} H),
						'west' => q({0} M),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} I),
						'south' => q({0} H),
						'west' => q({0} M),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(bit-ak),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bit-ak),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(byte-ak),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(byte-ak),
						'one' => q({0} byte),
						'other' => q({0} byte),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabit-ak),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabit-ak),
						'one' => q({0} gigabit),
						'other' => q({0} gigabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabyte-ak),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyte),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabyte-ak),
						'one' => q({0} gigabyte),
						'other' => q({0} gigabyte),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobit-ak),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobit-ak),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobyte-ak),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyte),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobyte-ak),
						'one' => q({0} kilobyte),
						'other' => q({0} kilobyte),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(megabit-ak),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(megabit-ak),
						'one' => q({0} megabit),
						'other' => q({0} megabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(megabyte-ak),
						'one' => q({0} megabyte),
						'other' => q({0} megabyte),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(megabyte-ak),
						'one' => q({0} megabyte),
						'other' => q({0} megabyte),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petabyte),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petabyte),
						'one' => q({0} petabyte),
						'other' => q({0} petabyte),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(terabit-ak),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(terabit-ak),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(terabyte-ak),
						'one' => q({0} terabyte),
						'other' => q({0} terabyte),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(terabyte-ak),
						'one' => q({0} terabyte),
						'other' => q({0} terabyte),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(mendeak),
						'one' => q({0} mende),
						'other' => q({0} mende),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(mendeak),
						'one' => q({0} mende),
						'other' => q({0} mende),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(egunak),
						'one' => q({0} egun),
						'other' => q({0} egun),
						'per' => q({0} egun bakoitzeko),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(egunak),
						'one' => q({0} egun),
						'other' => q({0} egun),
						'per' => q({0} egun bakoitzeko),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(hamarkadak),
						'one' => q({0} hamarkada),
						'other' => q({0} hamarkada),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(hamarkadak),
						'one' => q({0} hamarkada),
						'other' => q({0} hamarkada),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(orduak),
						'one' => q({0} ordu),
						'other' => q({0} ordu),
						'per' => q({0} ordu bakoitzeko),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(orduak),
						'one' => q({0} ordu),
						'other' => q({0} ordu),
						'per' => q({0} ordu bakoitzeko),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosegundoak),
						'one' => q({0} mikrosegundo),
						'other' => q({0} mikrosegundo),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosegundoak),
						'one' => q({0} mikrosegundo),
						'other' => q({0} mikrosegundo),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisegundoak),
						'one' => q({0} milisegundo),
						'other' => q({0} milisegundo),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisegundoak),
						'one' => q({0} milisegundo),
						'other' => q({0} milisegundo),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minutuak),
						'one' => q({0} minutu),
						'other' => q({0} minutu),
						'per' => q({0} minutu bakoitzeko),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minutuak),
						'one' => q({0} minutu),
						'other' => q({0} minutu),
						'per' => q({0} minutu bakoitzeko),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(hilabeteak),
						'one' => q({0} hilabete),
						'other' => q({0} hilabete),
						'per' => q({0} hilabete bakoitzeko),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(hilabeteak),
						'one' => q({0} hilabete),
						'other' => q({0} hilabete),
						'per' => q({0} hilabete bakoitzeko),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosegundoak),
						'one' => q({0} nanosegundo),
						'other' => q({0} nanosegundo),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosegundoak),
						'one' => q({0} nanosegundo),
						'other' => q({0} nanosegundo),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(segundoak),
						'one' => q({0} segundo),
						'other' => q({0} segundo),
						'per' => q({0} segundo bakoitzeko),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(segundoak),
						'one' => q({0} segundo),
						'other' => q({0} segundo),
						'per' => q({0} segundo bakoitzeko),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(asteak),
						'one' => q({0} aste),
						'other' => q({0} aste),
						'per' => q({0} aste bakoitzeko),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(asteak),
						'one' => q({0} aste),
						'other' => q({0} aste),
						'per' => q({0} aste bakoitzeko),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(urteak),
						'one' => q({0} urte),
						'other' => q({0} urte),
						'per' => q({0} urte bakoitzeko),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(urteak),
						'one' => q({0} urte),
						'other' => q({0} urte),
						'per' => q({0} urte bakoitzeko),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ampereak),
						'one' => q({0} ampere),
						'other' => q({0} ampere),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ampereak),
						'one' => q({0} ampere),
						'other' => q({0} ampere),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliampereak),
						'one' => q({0} miliampere),
						'other' => q({0} miliampere),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliampereak),
						'one' => q({0} miliampere),
						'other' => q({0} miliampere),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ohm-ak),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ohm-ak),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(voltak),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(voltak),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kaloriak),
						'one' => q({0} kaloria),
						'other' => q({0} kaloria),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kaloriak),
						'one' => q({0} kaloria),
						'other' => q({0} kaloria),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(kaloriak),
						'one' => q({0} kaloria),
						'other' => q({0} kaloria),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(kaloriak),
						'one' => q({0} kaloria),
						'other' => q({0} kaloria),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(joule-ak),
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(joule-ak),
						'one' => q({0} joule),
						'other' => q({0} joule),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokaloriak),
						'one' => q({0} kilokaloria),
						'other' => q({0} kilokaloria),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokaloriak),
						'one' => q({0} kilokaloria),
						'other' => q({0} kilokaloria),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojoule-ak),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojoule-ak),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilowatt-ordu),
						'one' => q({0} kilowatt-ordu),
						'other' => q({0} kilowatt-ordu),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowatt-ordu),
						'one' => q({0} kilowatt-ordu),
						'other' => q({0} kilowatt-ordu),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(AEBko termiak),
						'one' => q({0} AEBko termia),
						'other' => q({0} AEBko termia),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(AEBko termiak),
						'one' => q({0} AEBko termia),
						'other' => q({0} AEBko termia),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newton),
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newton),
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(libra indar),
						'one' => q({0} libra indar),
						'other' => q({0} libra indar),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(libra indar),
						'one' => q({0} libra indar),
						'other' => q({0} libra indar),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigahertz),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kilohertz),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megahertz),
						'one' => q({0} megahertz),
						'other' => q({0} megahertz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(puntua),
						'one' => q({0} puntu),
						'other' => q({0} puntu),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(puntua),
						'one' => q({0} puntu),
						'other' => q({0} puntu),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(puntu zentimetroko),
						'one' => q({0} puntu zentimetroko),
						'other' => q({0} puntu zentimetroko),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(puntu zentimetroko),
						'one' => q({0} puntu zentimetroko),
						'other' => q({0} puntu zentimetroko),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(puntu hazbeteko),
						'one' => q({0} puntu hazbeteko),
						'other' => q({0} puntu hazbeteko),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(puntu hazbeteko),
						'one' => q({0} puntu hazbeteko),
						'other' => q({0} puntu hazbeteko),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(em tipografikoa),
						'one' => q({0} em),
						'other' => q({0} em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(em tipografikoa),
						'one' => q({0} em),
						'other' => q({0} em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapixel),
						'one' => q({0} megapixel),
						'other' => q({0} megapixel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapixel),
						'one' => q({0} megapixel),
						'other' => q({0} megapixel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pixel),
						'one' => q({0} pixel),
						'other' => q({0} pixel),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pixel),
						'one' => q({0} pixel),
						'other' => q({0} pixel),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(pixel zentimetroko),
						'one' => q({0} pixel zentimetroko),
						'other' => q({0} pixel zentimetroko),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(pixel zentimetroko),
						'one' => q({0} pixel zentimetroko),
						'other' => q({0} pixel zentimetroko),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pixel hazbeteko),
						'one' => q({0} pixel hazbeteko),
						'other' => q({0} pixel hazbeteko),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pixel hazbeteko),
						'one' => q({0} pixel hazbeteko),
						'other' => q({0} pixel hazbeteko),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(unitate astronomiko),
						'one' => q({0} unitate astronomiko),
						'other' => q({0} unitate astronomiko),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(unitate astronomiko),
						'one' => q({0} unitate astronomiko),
						'other' => q({0} unitate astronomiko),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(zentimetro),
						'one' => q({0} zentimetro),
						'other' => q({0} zentimetro),
						'per' => q({0} zentimetro bakoitzeko),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(zentimetro),
						'one' => q({0} zentimetro),
						'other' => q({0} zentimetro),
						'per' => q({0} zentimetro bakoitzeko),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(dezimetro),
						'one' => q({0} dezimetro),
						'other' => q({0} dezimetro),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(dezimetro),
						'one' => q({0} dezimetro),
						'other' => q({0} dezimetro),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(Lurraren erradio),
						'one' => q({0} Lurraren erradio),
						'other' => q({0} Lurraren erradio),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(Lurraren erradio),
						'one' => q({0} Lurraren erradio),
						'other' => q({0} Lurraren erradio),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(besoa),
						'one' => q({0} beso),
						'other' => q({0} beso),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(besoa),
						'one' => q({0} beso),
						'other' => q({0} beso),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(oin),
						'one' => q({0} oin),
						'other' => q({0} oin),
						'per' => q({0} oin bakoitzeko),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(oin),
						'one' => q({0} oin),
						'other' => q({0} oin),
						'per' => q({0} oin bakoitzeko),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(fulong),
						'one' => q({0} furlong),
						'other' => q({0} furlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(fulong),
						'one' => q({0} furlong),
						'other' => q({0} furlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(hazbete),
						'one' => q({0} hazbete),
						'other' => q({0} hazbete),
						'per' => q({0} hazbete bakoitzeko),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(hazbete),
						'one' => q({0} hazbete),
						'other' => q({0} hazbete),
						'per' => q({0} hazbete bakoitzeko),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilometro),
						'one' => q({0} kilometro),
						'other' => q({0} kilometro),
						'per' => q({0} kilometro bakoitzeko),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilometro),
						'one' => q({0} kilometro),
						'other' => q({0} kilometro),
						'per' => q({0} kilometro bakoitzeko),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(argi-urte),
						'one' => q({0} argi-urte),
						'other' => q({0} argi-urte),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(argi-urte),
						'one' => q({0} argi-urte),
						'other' => q({0} argi-urte),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metro),
						'one' => q({0} metro),
						'other' => q({0} metro),
						'per' => q({0} metro bakoitzeko),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metro),
						'one' => q({0} metro),
						'other' => q({0} metro),
						'per' => q({0} metro bakoitzeko),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikrometro),
						'one' => q({0} mikrometro),
						'other' => q({0} mikrometro),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikrometro),
						'one' => q({0} mikrometro),
						'other' => q({0} mikrometro),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(milia),
						'one' => q({0} milia),
						'other' => q({0} milia),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milia),
						'one' => q({0} milia),
						'other' => q({0} milia),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(milia eskandinaviar),
						'one' => q({0} milia eskandinaviar),
						'other' => q({0} milia eskandinaviar),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(milia eskandinaviar),
						'one' => q({0} milia eskandinaviar),
						'other' => q({0} milia eskandinaviar),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milimetro),
						'one' => q({0} milimetro),
						'other' => q({0} milimetro),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milimetro),
						'one' => q({0} milimetro),
						'other' => q({0} milimetro),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanometro),
						'one' => q({0} nanometro),
						'other' => q({0} nanometro),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanometro),
						'one' => q({0} nanometro),
						'other' => q({0} nanometro),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(milia nautiko),
						'one' => q({0} milia nautiko),
						'other' => q({0} milia nautiko),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(milia nautiko),
						'one' => q({0} milia nautiko),
						'other' => q({0} milia nautiko),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsec),
						'one' => q({0} parsec),
						'other' => q({0} parsec),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikometro),
						'one' => q({0} pikometro),
						'other' => q({0} pikometro),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikometro),
						'one' => q({0} pikometro),
						'other' => q({0} pikometro),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(puntu),
						'one' => q({0} puntu tipografiko),
						'other' => q({0} puntu tipografiko),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(puntu),
						'one' => q({0} puntu tipografiko),
						'other' => q({0} puntu tipografiko),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0} eguzki-erradio),
						'other' => q({0} eguzki-erradio),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0} eguzki-erradio),
						'other' => q({0} eguzki-erradio),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yarda),
						'one' => q({0} yarda),
						'other' => q({0} yarda),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yarda),
						'one' => q({0} yarda),
						'other' => q({0} yarda),
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
						'name' => q(lumena),
						'one' => q({0} lumen),
						'other' => q({0} lumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumena),
						'one' => q({0} lumen),
						'other' => q({0} lumen),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(eguzki-argitasun),
						'one' => q({0} eguzki-argitasun),
						'other' => q({0} eguzki-argitasun),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(eguzki-argitasun),
						'one' => q({0} eguzki-argitasun),
						'other' => q({0} eguzki-argitasun),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(kilateak),
						'one' => q({0} kilate),
						'other' => q({0} kilate),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(kilateak),
						'one' => q({0} kilate),
						'other' => q({0} kilate),
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
						'one' => q({0} lur-masa),
						'other' => q({0} lur-masa),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q({0} lur-masa),
						'other' => q({0} lur-masa),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(alea),
						'one' => q({0} ale),
						'other' => q({0} ale),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(alea),
						'one' => q({0} ale),
						'other' => q({0} ale),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gramoak),
						'one' => q({0} gramo),
						'other' => q({0} gramo),
						'per' => q({0} gramo bakoitzeko),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gramoak),
						'one' => q({0} gramo),
						'other' => q({0} gramo),
						'per' => q({0} gramo bakoitzeko),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogramoak),
						'one' => q({0} kilogramo),
						'other' => q({0} kilogramo),
						'per' => q({0} kilogramo bakoitzeko),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogramoak),
						'one' => q({0} kilogramo),
						'other' => q({0} kilogramo),
						'per' => q({0} kilogramo bakoitzeko),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'name' => q(tona metrikoak),
						'one' => q({0} tona metriko),
						'other' => q({0} tona metriko),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'name' => q(tona metrikoak),
						'one' => q({0} tona metriko),
						'other' => q({0} tona metriko),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mikrogramoak),
						'one' => q({0} mikrogramo),
						'other' => q({0} mikrogramo),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mikrogramoak),
						'one' => q({0} mikrogramo),
						'other' => q({0} mikrogramo),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(miligramoak),
						'one' => q({0} miligramo),
						'other' => q({0} miligramo),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(miligramoak),
						'one' => q({0} miligramo),
						'other' => q({0} miligramo),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(ontzak),
						'one' => q({0} ontza),
						'other' => q({0} ontza),
						'per' => q({0} ontza bakoitzeko),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(ontzak),
						'one' => q({0} ontza),
						'other' => q({0} ontza),
						'per' => q({0} ontza bakoitzeko),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troy ontzak),
						'one' => q({0} troy ontza),
						'other' => q({0} troy ontza),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troy ontzak),
						'one' => q({0} troy ontza),
						'other' => q({0} troy ontza),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(librak),
						'one' => q({0} libra),
						'other' => q({0} libra),
						'per' => q({0} libra bakoitzeko),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(librak),
						'one' => q({0} libra),
						'other' => q({0} libra),
						'per' => q({0} libra bakoitzeko),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0} eguzki-masa),
						'other' => q({0} eguzki-masa),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0} eguzki-masa),
						'other' => q({0} eguzki-masa),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(stone-a),
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(stone-a),
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(AEBko tonak),
						'one' => q({0} AEBko tona),
						'other' => q({0} AEBko tona),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(AEBko tonak),
						'one' => q({0} AEBko tona),
						'other' => q({0} AEBko tona),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigawatt-ak),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigawatt-ak),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawatt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(zaldi-potentzia),
						'one' => q({0} zaldi-potentzia),
						'other' => q({0} zaldi-potentzia),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(zaldi-potentzia),
						'one' => q({0} zaldi-potentzia),
						'other' => q({0} zaldi-potentzia),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilowatt-ak),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilowatt-ak),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowatt),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(megawatt-ak),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(megawatt-ak),
						'one' => q({0} megawatt),
						'other' => q({0} megawatt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(miliwatt-ak),
						'one' => q({0} miliwatt),
						'other' => q({0} miliwatt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(miliwatt-ak),
						'one' => q({0} miliwatt),
						'other' => q({0} miliwatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(watt-ak),
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(watt-ak),
						'one' => q({0} watt),
						'other' => q({0} watt),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q({0} karratu),
						'one' => q({0} karratu),
						'other' => q({0} karratu),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q({0} karratu),
						'one' => q({0} karratu),
						'other' => q({0} karratu),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q({0} kubiko),
						'one' => q({0} kubiko),
						'other' => q({0} kubiko),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q({0} kubiko),
						'one' => q({0} kubiko),
						'other' => q({0} kubiko),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmosfera),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfera),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmosfera),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfera),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'one' => q({0} bar),
						'other' => q({0} bar),
					},
					# Core Unit Identifier
					'bar' => {
						'one' => q({0} bar),
						'other' => q({0} bar),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hektopascalak),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hektopascalak),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(merkurio-hazbeteak),
						'one' => q({0} merkurio-hazbete),
						'other' => q({0} merkurio-hazbete),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(merkurio-hazbeteak),
						'one' => q({0} merkurio-hazbete),
						'other' => q({0} merkurio-hazbete),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kilopascal),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilopascal),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(megapascal),
						'one' => q({0} megapascal),
						'other' => q({0} megapascal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(megapascal),
						'one' => q({0} megapascal),
						'other' => q({0} megapascal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(milibarrak),
						'one' => q({0} milibar),
						'other' => q({0} milibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(milibarrak),
						'one' => q({0} milibar),
						'other' => q({0} milibar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(merkurio-milimetroak),
						'one' => q({0} merkurio-milimetro),
						'other' => q({0} merkurio-milimetro),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(merkurio-milimetroak),
						'one' => q({0} merkurio-milimetro),
						'other' => q({0} merkurio-milimetro),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(pascal),
						'one' => q({0} pascal),
						'other' => q({0} pascal),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(pascal),
						'one' => q({0} pascal),
						'other' => q({0} pascal),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(libra hazbete karratuko),
						'one' => q({0} libra hazbete karratuko),
						'other' => q({0} libra hazbete karratuko),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(libra hazbete karratuko),
						'one' => q({0} libra hazbete karratuko),
						'other' => q({0} libra hazbete karratuko),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilometro orduko),
						'one' => q({0} kilometro orduko),
						'other' => q({0} kilometro orduko),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilometro orduko),
						'one' => q({0} kilometro orduko),
						'other' => q({0} kilometro orduko),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(korapilo),
						'one' => q({0} korapilo),
						'other' => q({0} korapilo),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(korapilo),
						'one' => q({0} korapilo),
						'other' => q({0} korapilo),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metro segundoko),
						'one' => q({0} metro segundoko),
						'other' => q({0} metro segundoko),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metro segundoko),
						'one' => q({0} metro segundoko),
						'other' => q({0} metro segundoko),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(milia orduko),
						'one' => q({0} milia orduko),
						'other' => q({0} milia orduko),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(milia orduko),
						'one' => q({0} milia orduko),
						'other' => q({0} milia orduko),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(Celsius graduak),
						'one' => q({0} Celsius gradu),
						'other' => q({0} Celsius gradu),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(Celsius graduak),
						'one' => q({0} Celsius gradu),
						'other' => q({0} Celsius gradu),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(Fahrenheit graduak),
						'one' => q({0} Fahrenheit gradu),
						'other' => q({0} Fahrenheit gradu),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(Fahrenheit graduak),
						'one' => q({0} Fahrenheit gradu),
						'other' => q({0} Fahrenheit gradu),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvin graduak),
						'one' => q({0} kelvin gradu),
						'other' => q({0} kelvin gradu),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvin graduak),
						'one' => q({0} kelvin gradu),
						'other' => q({0} kelvin gradu),
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
						'name' => q(newton-metro),
						'one' => q({0} newton-metro),
						'other' => q({0} newton-metro),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newton-metro),
						'one' => q({0} newton-metro),
						'other' => q({0} newton-metro),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(oin-libra),
						'one' => q({0} oin-libra),
						'other' => q({0} oin-libra),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(oin-libra),
						'one' => q({0} oin-libra),
						'other' => q({0} oin-libra),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(akre-oin),
						'one' => q({0} akre-oin),
						'other' => q({0} akre-oin),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(akre-oin),
						'one' => q({0} akre-oin),
						'other' => q({0} akre-oin),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'one' => q({0} upel),
						'other' => q({0} upel),
					},
					# Core Unit Identifier
					'barrel' => {
						'one' => q({0} upel),
						'other' => q({0} upel),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bushelak),
						'one' => q({0} bushel),
						'other' => q({0} bushel),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bushelak),
						'one' => q({0} bushel),
						'other' => q({0} bushel),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(zentilitro),
						'one' => q({0} zentilitro),
						'other' => q({0} zentilitro),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(zentilitro),
						'one' => q({0} zentilitro),
						'other' => q({0} zentilitro),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(zentimetro kubiko),
						'one' => q({0} zentimetro kubiko),
						'other' => q({0} zentimetro kubiko),
						'per' => q({0} zentimetro kubiko bakoitzeko),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(zentimetro kubiko),
						'one' => q({0} zentimetro kubiko),
						'other' => q({0} zentimetro kubiko),
						'per' => q({0} zentimetro kubiko bakoitzeko),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(oin kubiko),
						'one' => q({0} oin kubiko),
						'other' => q({0} oin kubiko),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(oin kubiko),
						'one' => q({0} oin kubiko),
						'other' => q({0} oin kubiko),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(hazbete kubiko),
						'one' => q({0} hazbete kubiko),
						'other' => q({0} hazbete kubiko),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(hazbete kubiko),
						'one' => q({0} hazbete kubiko),
						'other' => q({0} hazbete kubiko),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kilometro kubiko),
						'one' => q({0} kilometro kubiko),
						'other' => q({0} kilometro kubiko),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kilometro kubiko),
						'one' => q({0} kilometro kubiko),
						'other' => q({0} kilometro kubiko),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(metro kubiko),
						'one' => q({0} metro kubiko),
						'other' => q({0} metro kubiko),
						'per' => q({0} metro kubiko bakoitzeko),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(metro kubiko),
						'one' => q({0} metro kubiko),
						'other' => q({0} metro kubiko),
						'per' => q({0} metro kubiko bakoitzeko),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(milia kubiko),
						'one' => q({0} milia kubiko),
						'other' => q({0} milia kubiko),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(milia kubiko),
						'one' => q({0} milia kubiko),
						'other' => q({0} milia kubiko),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yarda kubiko),
						'one' => q({0} yarda kubiko),
						'other' => q({0} yarda kubiko),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yarda kubiko),
						'one' => q({0} yarda kubiko),
						'other' => q({0} yarda kubiko),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(katilukada),
						'one' => q({0} katilukada),
						'other' => q({0} katilukada),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(katilukada),
						'one' => q({0} katilukada),
						'other' => q({0} katilukada),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(katilu metrikoak),
						'one' => q({0} katilukada metriko),
						'other' => q({0} katilukada metriko),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(katilu metrikoak),
						'one' => q({0} katilukada metriko),
						'other' => q({0} katilukada metriko),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dezilitro),
						'one' => q({0} dezilitro),
						'other' => q({0} dezilitro),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dezilitro),
						'one' => q({0} dezilitro),
						'other' => q({0} dezilitro),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(postre-koilarakada),
						'one' => q({0} postre-koilarakada),
						'other' => q({0} postre-koilarakada),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(postre-koilarakada),
						'one' => q({0} postre-koilarakada),
						'other' => q({0} postre-koilarakada),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Postre-koilarakada inperiala),
						'one' => q({0} postre-koilarakada inperial),
						'other' => q({0} postre-koilarakada inperial),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Postre-koilarakada inperiala),
						'one' => q({0} postre-koilarakada inperial),
						'other' => q({0} postre-koilarakada inperial),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram fluidoa),
						'one' => q({0} dram fluido),
						'other' => q({0} dram fluido),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram fluidoa),
						'one' => q({0} dram fluido),
						'other' => q({0} dram fluido),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(tanta),
						'one' => q({0} tanta),
						'other' => q({0} tanta),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(tanta),
						'one' => q({0} tanta),
						'other' => q({0} tanta),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(ontza likido),
						'one' => q({0} likido-ontza),
						'other' => q({0} likido-ontza),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(ontza likido),
						'one' => q({0} likido-ontza),
						'other' => q({0} likido-ontza),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'one' => q({0} likido-ontza inperial),
						'other' => q({0} likido-ontza inperial),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q({0} likido-ontza inperial),
						'other' => q({0} likido-ontza inperial),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(galoi),
						'one' => q({0} galoi),
						'other' => q({0} galoi),
						'per' => q({0} galoi bakoitzeko),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(galoi),
						'one' => q({0} galoi),
						'other' => q({0} galoi),
						'per' => q({0} galoi bakoitzeko),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(galoi brit.),
						'one' => q({0} galoi brit.),
						'other' => q({0} galoi brit.),
						'per' => q({0} galoi brit. bakoitzeko),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(galoi brit.),
						'one' => q({0} galoi brit.),
						'other' => q({0} galoi brit.),
						'per' => q({0} galoi brit. bakoitzeko),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hektolitro),
						'one' => q({0} hektolitro),
						'other' => q({0} hektolitro),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hektolitro),
						'one' => q({0} hektolitro),
						'other' => q({0} hektolitro),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(txupitoa),
						'one' => q({0} txupito),
						'other' => q({0} txupito),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(txupitoa),
						'one' => q({0} txupito),
						'other' => q({0} txupito),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litro),
						'one' => q({0} litro),
						'other' => q({0} litro),
						'per' => q({0} litro bakoitzeko),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litro),
						'one' => q({0} litro),
						'other' => q({0} litro),
						'per' => q({0} litro bakoitzeko),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megalitro),
						'one' => q({0} megalitro),
						'other' => q({0} megalitro),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megalitro),
						'one' => q({0} megalitro),
						'other' => q({0} megalitro),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mililitro),
						'one' => q({0} mililitro),
						'other' => q({0} mililitro),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mililitro),
						'one' => q({0} mililitro),
						'other' => q({0} mililitro),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(pinch-a),
						'one' => q({0} pinch),
						'other' => q({0} pinch),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pinch-a),
						'one' => q({0} pinch),
						'other' => q({0} pinch),
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
						'name' => q(pinta metrikoak),
						'one' => q({0} pinta metriko),
						'other' => q({0} pinta metriko),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pinta metrikoak),
						'one' => q({0} pinta metriko),
						'other' => q({0} pinta metriko),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(galoi-laurden),
						'one' => q({0} galoi-laurden),
						'other' => q({0} galoi-laurden),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(galoi-laurden),
						'one' => q({0} galoi-laurden),
						'other' => q({0} galoi-laurden),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(laurden inperiala),
						'one' => q({0} laurden inperial),
						'other' => q({0} laurden inperial),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(laurden inperiala),
						'one' => q({0} laurden inperial),
						'other' => q({0} laurden inperial),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(koilarakada),
						'one' => q({0} koilarakada),
						'other' => q({0} koilarakada),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(koilarakada),
						'one' => q({0} koilarakada),
						'other' => q({0} koilarakada),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(koilaratxokada),
						'one' => q({0} koilaratxokada),
						'other' => q({0} koilaratxokada),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(koilaratxokada),
						'one' => q({0} koilaratxokada),
						'other' => q({0} koilaratxokada),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'' => {
						'name' => q(norabidea),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(norabidea),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(Ki{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(Ki{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(Mi{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(Mi{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(Gi{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(Gi{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(Ti{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(Ti{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(Pi{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(Pi{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(Ei{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(Ei{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(Zi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(Zi{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(Yi{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(Yi{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0} G),
						'other' => q({0} G),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0} G),
						'other' => q({0} G),
					},
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
					'angle-degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
						'one' => q(% {0}),
						'other' => q(% {0}),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
						'one' => q(% {0}),
						'other' => q(% {0}),
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
					'consumption-mile-per-gallon-imperial' => {
						'one' => q({0} m/gUK),
						'other' => q({0} m/gUK),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q({0} m/gUK),
						'other' => q({0} m/gUK),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} I),
						'south' => q({0} H),
						'west' => q({0} M),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} I),
						'south' => q({0} H),
						'west' => q({0} M),
					},
					# Long Unit Identifier
					'duration-century' => {
						'one' => q({0}m.),
						'other' => q({0}m.),
					},
					# Core Unit Identifier
					'century' => {
						'one' => q({0}m.),
						'other' => q({0}m.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(egun),
						'one' => q({0} e.),
						'other' => q({0} e.),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(egun),
						'one' => q({0} e.),
						'other' => q({0} e.),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(hamark.),
						'one' => q({0} hamark.),
						'other' => q({0} hamark.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(hamark.),
						'one' => q({0} hamark.),
						'other' => q({0} hamark.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ordu),
						'one' => q({0} h),
						'other' => q({0} h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ordu),
						'one' => q({0} h),
						'other' => q({0} h),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(hilabete),
						'one' => q({0} hil),
						'other' => q({0} hil),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(hilabete),
						'one' => q({0} hil),
						'other' => q({0} hil),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(aste),
						'one' => q({0} aste),
						'other' => q({0} aste),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(aste),
						'one' => q({0} aste),
						'other' => q({0} aste),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(urte),
						'one' => q({0} u.),
						'other' => q({0} u.),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(urte),
						'one' => q({0} u.),
						'other' => q({0} u.),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'one' => q({0} US therm),
						'other' => q({0} US therms),
					},
					# Core Unit Identifier
					'therm-us' => {
						'one' => q({0} US therm),
						'other' => q({0} US therms),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q({0} kWh/100 km),
						'other' => q({0} kWh/100 km),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0} ft),
						'other' => q({0} ft),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0} ft),
						'other' => q({0} ft),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0} in),
						'other' => q({0} in),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0} in),
						'other' => q({0} in),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'one' => q({0} M⊕),
						'other' => q({0} M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q({0} M⊕),
						'other' => q({0} M⊕),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(gramo),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gramo),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q({0} oz),
						'other' => q({0} oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0} oz),
						'other' => q({0} oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} lb),
						'other' => q({0} lb),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} lb),
						'other' => q({0} lb),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0} M☉),
						'other' => q({0} M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0} M☉),
						'other' => q({0} M☉),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0}tn),
						'other' => q({0}tn),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0}tn),
						'other' => q({0}tn),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'one' => q({0} atm),
						'other' => q({0} atm),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
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
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'one' => q({0}kn),
						'other' => q({0}kn),
					},
					# Core Unit Identifier
					'knot' => {
						'one' => q({0}kn),
						'other' => q({0}kn),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q({0} mph),
						'other' => q({0} mph),
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
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
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
					'torque-pound-force-foot' => {
						'one' => q({0} lbf⋅ft),
						'other' => q({0} lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'one' => q({0} lbf⋅ft),
						'other' => q({0} lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'one' => q({0}ac ft),
						'other' => q({0}ac ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'one' => q({0}ac ft),
						'other' => q({0}ac ft),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'one' => q({0}c),
						'other' => q({0}c),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q({0}c),
						'other' => q({0}c),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'one' => q({0}mc),
						'other' => q({0}mc),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'one' => q({0}mc),
						'other' => q({0}mc),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'one' => q({0}dsp),
						'other' => q({0}dsp),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'one' => q({0}dsp),
						'other' => q({0}dsp),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litro),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litro),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'one' => q({0}mpt),
						'other' => q({0}mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'one' => q({0}mpt),
						'other' => q({0}mpt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'one' => q({0}qt),
						'other' => q({0}qt),
					},
					# Core Unit Identifier
					'quart' => {
						'one' => q({0}qt),
						'other' => q({0}qt),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'one' => q({0}tbsp),
						'other' => q({0}tbsp),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'one' => q({0}tbsp),
						'other' => q({0}tbsp),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'one' => q({0}tsp),
						'other' => q({0}tsp),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'one' => q({0}tsp),
						'other' => q({0}tsp),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(norabidea),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(norabidea),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(Ki{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(Ki{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(Mi{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(Mi{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(Gi{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(Gi{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(Ti{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(Ti{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(Pi{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(Pi{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(Ei{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(Ei{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(Zi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(Zi{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(Yi{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(Yi{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(arku-min),
						'one' => q({0} arku-min),
						'other' => q({0} arku-min),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arku-min),
						'one' => q({0} arku-min),
						'other' => q({0} arku-min),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arku-seg),
						'one' => q({0} arku-seg),
						'other' => q({0} arku-seg),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arku-seg),
						'one' => q({0} arku-seg),
						'other' => q({0} arku-seg),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(gradu),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(gradu),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(bira),
						'one' => q({0} bira),
						'other' => q({0} bira),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(bira),
						'one' => q({0} bira),
						'other' => q({0} bira),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(akre),
						'one' => q({0} akre),
						'other' => q({0} akre),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(akre),
						'one' => q({0} akre),
						'other' => q({0} akre),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektarea),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektarea),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'per' => q({0}/km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(milia karratu),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(milia karratu),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'per' => q({0}/mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(elementua),
						'one' => q({0} elementu),
						'other' => q({0} elementu),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(elementua),
						'one' => q({0} elementu),
						'other' => q({0} elementu),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
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
						'name' => q(milimole/litro),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimole/litro),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(%),
						'one' => q(% {0}),
						'other' => q(% {0}),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(%),
						'one' => q(% {0}),
						'other' => q(% {0}),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(‰),
						'one' => q(‰ {0}),
						'other' => q(‰ {0}),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(‰),
						'one' => q(‰ {0}),
						'other' => q(‰ {0}),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(zati/milioi),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(zati/milioi),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q(‱ {0}),
						'other' => q(‱ {0}),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q(‱ {0}),
						'other' => q(‱ {0}),
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
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mi/gal),
						'one' => q(mi/gal),
						'other' => q({0} mi/gal),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mi/gal),
						'one' => q(mi/gal),
						'other' => q({0} mi/gal),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(milia/galoi britainiar),
						'one' => q({0} mi gal brit.),
						'other' => q({0} mi gal brit.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(milia/galoi britainiar),
						'one' => q({0} mi gal brit.),
						'other' => q({0} mi gal brit.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} I),
						'south' => q({0} H),
						'west' => q({0} M),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} I),
						'south' => q({0} H),
						'west' => q({0} M),
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
						'name' => q(m.),
						'one' => q({0} m.),
						'other' => q({0} m.),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(m.),
						'one' => q({0} m.),
						'other' => q({0} m.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(egun),
						'one' => q({0} egun),
						'other' => q({0} egun),
						'per' => q({0}/e.),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(egun),
						'one' => q({0} egun),
						'other' => q({0} egun),
						'per' => q({0}/e.),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(hamarkada),
						'one' => q({0} hamarkada),
						'other' => q({0} hamarkada),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(hamarkada),
						'one' => q({0} hamarkada),
						'other' => q({0} hamarkada),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ordu),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ordu),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisegundo),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisegundo),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(hilabete),
						'one' => q({0} hilabete),
						'other' => q({0} hilabete),
						'per' => q({0}/hil),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(hilabete),
						'one' => q({0} hilabete),
						'other' => q({0} hilabete),
						'per' => q({0}/hil),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(segundo),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(segundo),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(aste),
						'one' => q({0} aste),
						'other' => q({0} aste),
						'per' => q({0}/a.),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(aste),
						'one' => q({0} aste),
						'other' => q({0} aste),
						'per' => q({0}/a.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(urte),
						'one' => q({0} urte),
						'other' => q({0} urte),
						'per' => q({0}/u.),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(urte),
						'one' => q({0} urte),
						'other' => q({0} urte),
						'per' => q({0}/u.),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
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
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(AEBko termia),
						'one' => q({0} AEBko termia),
						'other' => q({0} AEBko termia),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(AEBko termia),
						'one' => q({0} AEBko termia),
						'other' => q({0} AEBko termia),
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
						'name' => q(libra indar),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(libra indar),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(puntua),
						'one' => q({0} puntu),
						'other' => q({0} ptu),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(puntua),
						'one' => q({0} puntu),
						'other' => q({0} ptu),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(em),
						'one' => q({0} em),
						'other' => q({0} em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(em),
						'one' => q({0} em),
						'other' => q({0} em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapixel),
						'one' => q({0} Mp),
						'other' => q({0} Mp),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapixel),
						'one' => q({0} Mp),
						'other' => q({0} Mp),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pixel),
						'one' => q({0} p),
						'other' => q({0} p),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pixel),
						'one' => q({0} p),
						'other' => q({0} p),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(ppcm),
						'one' => q({0} ppcm),
						'other' => q({0} ppcm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(ppcm),
						'one' => q({0} ppcm),
						'other' => q({0} ppcm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(ppi),
						'one' => q({0} ppi),
						'other' => q({0} ppi),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(ppi),
						'one' => q({0} ppi),
						'other' => q({0} ppi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ua),
						'one' => q({0} ua),
						'other' => q({0} ua),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fm),
						'one' => q({0} fm),
						'other' => q({0} fm),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fm),
						'one' => q({0} fm),
						'other' => q({0} fm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(oin),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(oin),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlong),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlong),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(hazbete),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(hazbete),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(argi-urte),
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(argi-urte),
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(μm),
						'one' => q({0} μm),
						'other' => q({0} μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μm),
						'one' => q({0} μm),
						'other' => q({0} μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(milia),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milia),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(milia eskandinaviar),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(milia eskandinaviar),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(puntu),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(puntu),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(eguzki-erradio),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(eguzki-erradio),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(cd),
						'one' => q({0} cd),
						'other' => q({0} cd),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(cd),
						'one' => q({0} cd),
						'other' => q({0} cd),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lm),
						'one' => q({0} lm),
						'other' => q({0} lm),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lm),
						'one' => q({0} lm),
						'other' => q({0} lm),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(eguzki-argitasun),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(eguzki-argitasun),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(kilate),
						'one' => q({0} kilate),
						'other' => q({0} kilate),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(kilate),
						'one' => q({0} kilate),
						'other' => q({0} kilate),
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
						'name' => q(lur-masa),
						'one' => q({0} lur-masa),
						'other' => q({0} lur-masa),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(lur-masa),
						'one' => q({0} lur-masa),
						'other' => q({0} lur-masa),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(alea),
						'one' => q({0} ale),
						'other' => q({0} ale),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(alea),
						'one' => q({0} ale),
						'other' => q({0} ale),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
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
					'mass-microgram' => {
						'name' => q(μg),
						'one' => q({0} μg),
						'other' => q({0} μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(μg),
						'one' => q({0} μg),
						'other' => q({0} μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(ontza),
						'one' => q({0} ontza),
						'other' => q({0} ontza),
						'per' => q({0}/ontza),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(ontza),
						'one' => q({0} ontza),
						'other' => q({0} ontza),
						'per' => q({0}/ontza),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troy ontza),
						'one' => q({0} troy ontza),
						'other' => q({0} troy ontza),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troy ontza),
						'one' => q({0} troy ontza),
						'other' => q({0} troy ontza),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(eguzki-masa),
						'one' => q({0} eguzki-masa),
						'other' => q({0} eguzki-masa),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(eguzki-masa),
						'one' => q({0} eguzki-masa),
						'other' => q({0} eguzki-masa),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q({0} st),
						'other' => q({0} st),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q({0} st),
						'other' => q({0} st),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(AEBko tona),
						'one' => q({0} AEBko tona),
						'other' => q({0} AEBko tona),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(AEBko tona),
						'one' => q({0} AEBko tona),
						'other' => q({0} AEBko tona),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0}/{1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hp),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hp),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmosfera),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfera),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmosfera),
						'one' => q({0} atmosfera),
						'other' => q({0} atmosfera),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(bar),
						'one' => q({0} bar),
						'other' => q({0} bar),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(bar),
						'one' => q({0} bar),
						'other' => q({0} bar),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kPa),
						'one' => q({0} kPa),
						'other' => q({0} kPa),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kPa),
						'one' => q({0} kPa),
						'other' => q({0} kPa),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(MPa),
						'one' => q({0} MPa),
						'other' => q({0} MPa),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(MPa),
						'one' => q({0} MPa),
						'other' => q({0} MPa),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(mb),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(mb),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(Pa),
						'one' => q({0} Pa),
						'other' => q({0} Pa),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(Pa),
						'one' => q({0} Pa),
						'other' => q({0} Pa),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(korapilo),
						'one' => q({0} korapilo),
						'other' => q({0} korapilo),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(korapilo),
						'one' => q({0} korapilo),
						'other' => q({0} korapilo),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metro segundoko),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metro segundoko),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0} mph),
						'other' => q({0} mph),
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
					'temperature-generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
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
						'name' => q(newton-metro),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newton-metro),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(oin-libra),
						'one' => q({0} oin-libra),
						'other' => q({0} oin-libra),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(oin-libra),
						'one' => q({0} oin-libra),
						'other' => q({0} oin-libra),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(akre-oin),
						'one' => q({0} akre-oin),
						'other' => q({0} akre-oin),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(akre-oin),
						'one' => q({0} akre-oin),
						'other' => q({0} akre-oin),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(upel),
						'one' => q({0} upel),
						'other' => q({0} upel),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(upel),
						'one' => q({0} upel),
						'other' => q({0} upel),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bushelak),
						'one' => q({0} bu),
						'other' => q({0} bu),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bushelak),
						'one' => q({0} bu),
						'other' => q({0} bu),
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
					'volume-cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(katilukada),
						'one' => q({0} katilukada),
						'other' => q({0} katilukada),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(katilukada),
						'one' => q({0} katilukada),
						'other' => q({0} katilukada),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(katilukada metriko),
						'one' => q({0} katilukada metriko),
						'other' => q({0} katilukada metriko),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(katilukada metriko),
						'one' => q({0} katilukada metriko),
						'other' => q({0} katilukada metriko),
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
					'volume-dessert-spoon' => {
						'name' => q(postre-koilar.),
						'one' => q({0} postre-koilar.),
						'other' => q({0} postre-koilar.),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(postre-koilar.),
						'one' => q({0} postre-koilar.),
						'other' => q({0} postre-koilar.),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(postre-koilar. inp.),
						'one' => q({0} postre-koilar. inp.),
						'other' => q({0} postre-koilar. inp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(postre-koilar. inp.),
						'one' => q({0} postre-koilar. inp.),
						'other' => q({0} postre-koilar. inp.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram fluidoa),
						'one' => q({0} dram fl),
						'other' => q({0} dram fl),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram fluidoa),
						'one' => q({0} dram fl),
						'other' => q({0} dram fl),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(tanta),
						'one' => q({0} tanta),
						'other' => q({0} tanta),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(tanta),
						'one' => q({0} tanta),
						'other' => q({0} tanta),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(likido-ontza),
						'one' => q({0} likido-ontza),
						'other' => q({0} likido-ontza),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(likido-ontza),
						'one' => q({0} likido-ontza),
						'other' => q({0} likido-ontza),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(likido-ontza inperial),
						'one' => q({0} likido-ontza inperial),
						'other' => q({0} likido-ontza inperial),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(likido-ontza inperial),
						'one' => q({0} likido-ontza inperial),
						'other' => q({0} likido-ontza inperial),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(galoi),
						'one' => q({0} galoi),
						'other' => q({0} galoi),
						'per' => q({0}/galoi estatubatuar),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(galoi),
						'one' => q({0} galoi),
						'other' => q({0} galoi),
						'per' => q({0}/galoi estatubatuar),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(gal brit.),
						'one' => q({0} gal brit.),
						'other' => q({0} gal brit.),
						'per' => q({0}/gal brit.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal brit.),
						'one' => q({0} gal brit.),
						'other' => q({0} gal brit.),
						'per' => q({0}/gal brit.),
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
					'volume-jigger' => {
						'name' => q(txupitoa),
						'one' => q({0} txupito),
						'other' => q({0} txupito),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(txupitoa),
						'one' => q({0} txupito),
						'other' => q({0} txupito),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
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
						'name' => q(pinch-a),
						'one' => q({0} pinch),
						'other' => q({0} pinch),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pinch-a),
						'one' => q({0} pinch),
						'other' => q({0} pinch),
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
						'name' => q(pinta metriko),
						'one' => q({0} pinta metriko),
						'other' => q({0} pinta metriko),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pinta metriko),
						'one' => q({0} pinta metriko),
						'other' => q({0} pinta metriko),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(galoi-laurden),
						'one' => q({0} galoi-laurden),
						'other' => q({0} galoi-laurden),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(galoi-laurden),
						'one' => q({0} galoi-laurden),
						'other' => q({0} galoi-laurden),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(qt Imp),
						'one' => q({0} qt Imp.),
						'other' => q({0} qt Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(qt Imp),
						'one' => q({0} qt Imp.),
						'other' => q({0} qt Imp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(koilarakada),
						'one' => q({0} koilarakada),
						'other' => q({0} koilarakada),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(koilarakada),
						'one' => q({0} koilarakada),
						'other' => q({0} koilarakada),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(koilaratxokada),
						'one' => q({0} koilaratxokada),
						'other' => q({0} koilaratxokada),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(koilaratxokada),
						'one' => q({0} koilaratxokada),
						'other' => q({0} koilaratxokada),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:bai|b|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ez|e|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0} eta {1}),
				2 => q({0} eta {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'arab' => {
			'minusSign' => q(-),
			'percentSign' => q(٪؜),
			'plusSign' => q(+),
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
			'minusSign' => q(−),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
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
					'one' => '0',
					'other' => '0',
				},
				'10000' => {
					'one' => '0',
					'other' => '0',
				},
				'100000' => {
					'one' => '0',
					'other' => '0',
				},
				'1000000' => {
					'one' => '0 M',
					'other' => '0 M',
				},
				'10000000' => {
					'one' => '00 M',
					'other' => '00 M',
				},
				'100000000' => {
					'one' => '000 M',
					'other' => '000 M',
				},
				'1000000000' => {
					'one' => '0000 M',
					'other' => '0000 M',
				},
				'10000000000' => {
					'one' => '00000 M',
					'other' => '00000 M',
				},
				'100000000000' => {
					'one' => '000000 M',
					'other' => '000000 M',
				},
				'1000000000000' => {
					'one' => '0 B',
					'other' => '0 B',
				},
				'10000000000000' => {
					'one' => '00 B',
					'other' => '00 B',
				},
				'100000000000000' => {
					'one' => '000 B',
					'other' => '000 B',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0',
					'other' => '0',
				},
				'10000' => {
					'one' => '0',
					'other' => '0',
				},
				'100000' => {
					'one' => '0',
					'other' => '0',
				},
				'1000000' => {
					'one' => '0 milioi',
					'other' => '0 milioi',
				},
				'10000000' => {
					'one' => '00 milioi',
					'other' => '00 milioi',
				},
				'100000000' => {
					'one' => '000 milioi',
					'other' => '000 milioi',
				},
				'1000000000' => {
					'one' => '0000 milioi',
					'other' => '0000 milioi',
				},
				'10000000000' => {
					'one' => '00000 milioi',
					'other' => '00000 milioi',
				},
				'100000000000' => {
					'one' => '000000 milioi',
					'other' => '000000 milioi',
				},
				'1000000000000' => {
					'one' => '0 bilioi',
					'other' => '0 bilioi',
				},
				'10000000000000' => {
					'one' => '00 bilioi',
					'other' => '00 bilioi',
				},
				'100000000000000' => {
					'one' => '000 bilioi',
					'other' => '000 bilioi',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0',
					'other' => '0',
				},
				'10000' => {
					'one' => '0',
					'other' => '0',
				},
				'100000' => {
					'one' => '0',
					'other' => '0',
				},
				'1000000' => {
					'one' => '0 M',
					'other' => '0 M',
				},
				'10000000' => {
					'one' => '00 M',
					'other' => '00 M',
				},
				'100000000' => {
					'one' => '000 M',
					'other' => '000 M',
				},
				'1000000000' => {
					'one' => '0000 M',
					'other' => '0000 M',
				},
				'10000000000' => {
					'one' => '00000 M',
					'other' => '00000 M',
				},
				'100000000000' => {
					'one' => '000000 M',
					'other' => '000000 M',
				},
				'1000000000000' => {
					'one' => '0 B',
					'other' => '0 B',
				},
				'10000000000000' => {
					'one' => '00 B',
					'other' => '00 B',
				},
				'100000000000000' => {
					'one' => '000 B',
					'other' => '000 B',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'default' => '% #,##0',
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
						'negative' => '(#,##0.00 ¤)',
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
			display_name => {
				'currency' => q(pezeta andorratarra),
				'one' => q(pezeta andorratar),
				'other' => q(pezeta andorratar),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(Arabiar Emirerri Batuetako dirhama),
				'one' => q(Arabiar Emirerri Batuetako dirham),
				'other' => q(Arabiar Emirerri Batuetako dirham),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afghani afgandarra \(1927–2002\)),
				'one' => q(afghani afgandar \(1927–2002\)),
				'other' => q(afghani afgandar \(1927–2002\)),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(afgani afganiarra),
				'one' => q(afgani afganiar),
				'other' => q(afgani afganiar),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(lek albaniarra \(1946–1965\)),
				'one' => q(lek albaniar \(1946–1965\)),
				'other' => q(lek albaniar \(1946–1965\)),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(lek albaniarra),
				'one' => q(lek albaniar),
				'other' => q(lek albaniar),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(dram armeniarra),
				'one' => q(dram armeniar),
				'other' => q(dram armeniar),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(florin antillarra),
				'one' => q(florin antillar),
				'other' => q(florin antillar),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(kwanza angolarra),
				'one' => q(kwanza angolar),
				'other' => q(kwanza angolar),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(kwanza angolarra \(1977–1991\)),
				'one' => q(kwanza angolar \(1977–1991\)),
				'other' => q(kwanza angolar \(1977–1991\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(kwanza angolar berria \(1990–2000\)),
				'one' => q(kwanza angolar berri \(1990–2000\)),
				'other' => q(kwanza angolar berri \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(kwanza angolar birdoitua \(1995–1999\)),
				'one' => q(kwanza angolar birdoitu \(1995–1999\)),
				'other' => q(kwanza angolar birdoitu \(1995–1999\)),
			},
		},
		'ARA' => {
			symbol => 'ARA',
			display_name => {
				'currency' => q(austral argentinarra),
				'one' => q(austral argentinar),
				'other' => q(austral argentinar),
			},
		},
		'ARL' => {
			symbol => 'ARL',
			display_name => {
				'currency' => q(peso ley argentinarra \(1970–1983\)),
				'one' => q(peso ley argentinar \(1970–1983\)),
				'other' => q(peso ley argentinar \(1970–1983\)),
			},
		},
		'ARM' => {
			symbol => 'ARM',
			display_name => {
				'currency' => q(peso argentinarra \(1981–1970\)),
				'one' => q(peso argentinar \(1981–1970\)),
				'other' => q(peso argentinar \(1981–1970\)),
			},
		},
		'ARP' => {
			symbol => 'ARP',
			display_name => {
				'currency' => q(peso argentinarra \(1983–1985\)),
				'one' => q(peso argentinar \(1983–1985\)),
				'other' => q(peso argentinar \(1983–1985\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(peso argentinarra),
				'one' => q(peso argentinar),
				'other' => q(peso argentinar),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(txelin austriarra),
				'one' => q(txelin austriar),
				'other' => q(txelin austriar),
			},
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(dolar australiarra),
				'one' => q(dolar australiar),
				'other' => q(dolar australiar),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(florin arubarra),
				'one' => q(florin arubar),
				'other' => q(florin arubar),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(manat azerbaijandarra \(1993–2006\)),
				'one' => q(manat azerbaijandar \(1993–2006\)),
				'other' => q(manat azerbaijandar \(1993–2006\)),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(manat azerbaijandarra),
				'one' => q(manat azerbaijandar),
				'other' => q(manat azerbaijandar),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(dinar bosnia-herzegovinarra \(1992–1994\)),
				'one' => q(dinar bosnia-herzegovinar \(1992–1994\)),
				'other' => q(dinar bosnia-herzegovinar \(1992–1994\)),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(marko bihurgarri bosniarra),
				'one' => q(marko bihurgarri bosniar),
				'other' => q(marko bihurgarri bosniar),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(dinar bosnia-herzegovinar berria \(1994–1997\)),
				'one' => q(dinar bosnia-herzegovinar berri \(1994–1997\)),
				'other' => q(dinar bosnia-herzegovinar berri \(1994–1997\)),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(dolar barbadostarra),
				'one' => q(dolar barbadostar),
				'other' => q(dolar barbadostar),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(taka bangladeshtarra),
				'one' => q(taka bangladeshtar),
				'other' => q(taka bangladeshtar),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(franko belgikarra \(bihurgarria\)),
				'one' => q(franko belgikar \(bihurgarria\)),
				'other' => q(franko belgikar \(bihurgarria\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(franko belgikarra),
				'one' => q(franko belgikar),
				'other' => q(franko belgikar),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(franko belgikarra \(finantzarioa\)),
				'one' => q(franko belgikar \(finantzarioa\)),
				'other' => q(franko belgikar \(finantzarioa\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Lev bulgariar indartsua),
				'one' => q(Lev bulgariar indartsu),
				'other' => q(Lev bulgariar indartsu),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(Lev bulgariar sozialista),
				'one' => q(Lev bulgariar sozialista),
				'other' => q(Lev bulgariar sozialista),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(lev bulgariarra),
				'one' => q(lev bulgariar),
				'other' => q(lev bulgariar),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(Lev bulgariarra \(1879–1952\)),
				'one' => q(Lev bulgariar \(1879–1952\)),
				'other' => q(Lev bulgariar \(1879–1952\)),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(dinar bahraindarra),
				'one' => q(dinar bahraindar),
				'other' => q(dinar bahraindar),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(franko burundiarra),
				'one' => q(franko burundiar),
				'other' => q(franko burundiar),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(dolar bermudarra),
				'one' => q(dolar bermudar),
				'other' => q(dolar bermudar),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(dolar bruneitarra),
				'one' => q(dolar bruneitar),
				'other' => q(dolar bruneitar),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(boliviano boliviarra),
				'one' => q(boliviano boliviar),
				'other' => q(boliviano boliviar),
			},
		},
		'BOL' => {
			symbol => 'BOL',
			display_name => {
				'currency' => q(boliviano boliviarra \(1863–1963\)),
				'one' => q(boliviano boliviar \(1863–1963\)),
				'other' => q(boliviano boliviar \(1863–1963\)),
			},
		},
		'BOP' => {
			symbol => 'BOP',
			display_name => {
				'currency' => q(peso boliviarra),
				'one' => q(peso boliviar),
				'other' => q(peso boliviar),
			},
		},
		'BOV' => {
			symbol => 'BOV',
			display_name => {
				'currency' => q(mvdol boliviarra),
				'one' => q(mvdol boliviar),
				'other' => q(mvdol boliviar),
			},
		},
		'BRB' => {
			symbol => 'BRB',
			display_name => {
				'currency' => q(cruzeiro brasildar berria \(1967–1986\)),
				'one' => q(cruzeiro brasildar berri \(1967–1986\)),
				'other' => q(cruzeiro brasildar berri \(1967–1986\)),
			},
		},
		'BRC' => {
			symbol => 'BRC',
			display_name => {
				'currency' => q(cruzado brasildarra \(1986–1989\)),
				'one' => q(cruzado brasildar \(1986–1989\)),
				'other' => q(cruzado brasildar \(1986–1989\)),
			},
		},
		'BRE' => {
			symbol => 'BRE',
			display_name => {
				'currency' => q(cruzeiro brasildarra \(1990–1993\)),
				'one' => q(cruzeiro brasildar \(1990–1993\)),
				'other' => q(cruzeiro brasildar \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(erreal brasildarra),
				'one' => q(erreal brasildar),
				'other' => q(erreal brasildar),
			},
		},
		'BRN' => {
			symbol => 'BRN',
			display_name => {
				'currency' => q(cruzado brasildar berria \(1989–1990\)),
				'one' => q(cruzado brasildar berri \(1989–1990\)),
				'other' => q(cruzado brasildar berri \(1989–1990\)),
			},
		},
		'BRR' => {
			symbol => 'BRR',
			display_name => {
				'currency' => q(cruzeiro brasildar berria \(1993–1994\)),
				'one' => q(cruzeiro brasildar berri \(1993–1994\)),
				'other' => q(cruzeiro brasildar berri \(1993–1994\)),
			},
		},
		'BRZ' => {
			symbol => 'BRZ',
			display_name => {
				'currency' => q(cruzeiro brasildarra \(1942–1967\)),
				'one' => q(cruzeiro brasildar \(1942–1967\)),
				'other' => q(cruzeiro brasildar \(1942–1967\)),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(dolar bahamarra),
				'one' => q(dolar bahamar),
				'other' => q(dolar bahamar),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(ngultrum bhutandarra),
				'one' => q(ngultrum bhutandar),
				'other' => q(ngultrum bhutandar),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(kyat birmaniarra),
				'one' => q(kyat birmaniar),
				'other' => q(kyat birmaniar),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(pula botswanarra),
				'one' => q(pula botswanar),
				'other' => q(pula botswanar),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(errublo bielorrusiarra \(1994–1999\)),
				'one' => q(errublo bielorrusiar \(1994–1999\)),
				'other' => q(errublo bielorrusiar \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(errublo bielorrusiarra),
				'one' => q(errublo bielorrusiar),
				'other' => q(errublo bielorrusiar),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Bielorrusiako errubloa \(2000–2016\)),
				'one' => q(Bielorrusiako errublo \(2000–2016\)),
				'other' => q(Bielorrusiako errublo \(2000–2016\)),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(dolar belizetarra),
				'one' => q(dolar belizetar),
				'other' => q(dolar belizetar),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(dolar kanadarra),
				'one' => q(dolar kanadar),
				'other' => q(dolar kanadar),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(franko kongoarra),
				'one' => q(franko kongoar),
				'other' => q(franko kongoar),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR euroa),
				'one' => q(WIR euro),
				'other' => q(WIR euro),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(franko suitzarra),
				'one' => q(franko suitzar),
				'other' => q(franko suitzar),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR frankoa),
				'one' => q(WIR franko),
				'other' => q(WIR franko),
			},
		},
		'CLE' => {
			symbol => 'CLE',
			display_name => {
				'currency' => q(ezkutu txiletarra),
				'one' => q(ezkutu txiletar),
				'other' => q(ezkutu txiletar),
			},
		},
		'CLF' => {
			symbol => 'CLF',
			display_name => {
				'currency' => q(kontu-unitate txiletarra \(UF\)),
				'one' => q(kontu-unitate txiletar \(UF\)),
				'other' => q(kontu-unitate txiletar \(UF\)),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(peso txiletarra),
				'one' => q(peso txiletar),
				'other' => q(peso txiletar),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(yuan txinatarra \(itsasoz haraindikoa\)),
				'one' => q(yuan txinatar \(itsasoz haraindikoa\)),
				'other' => q(yuan txinatar \(itsasoz haraindikoa\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(Txinako Herri Bankuaren dolarra),
				'one' => q(Txinako Herri Bankuaren dolar),
				'other' => q(Txinako Herri Bankuaren dolar),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(yuan txinatarra),
				'one' => q(yuan txinatar),
				'other' => q(yuan txinatar),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(peso kolonbiarra),
				'one' => q(peso kolonbiar),
				'other' => q(peso kolonbiar),
			},
		},
		'COU' => {
			symbol => 'COU',
			display_name => {
				'currency' => q(erreal kolonbiarraren balio-unitatea),
				'one' => q(erreal kolonbiarraren balio-unitate),
				'other' => q(erreal kolonbiarraren balio-unitate),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(colon costarricarra),
				'one' => q(colon costarricar),
				'other' => q(colon costarricar),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(dinar serbiarra \(2002–2006\)),
				'one' => q(dinar serbiar \(2002–2006\)),
				'other' => q(dinar serbiar \(2002–2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Txekoslovakiako koroa indartsua),
				'one' => q(Txekoslovakiako koroa indartsu),
				'other' => q(Txekoslovakiako koroa indartsu),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(peso bihurgarri kubatarra),
				'one' => q(peso bihurgarri kubatar),
				'other' => q(peso bihurgarri kubatar),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(peso kubatarra),
				'one' => q(peso kubatar),
				'other' => q(peso kubatar),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(ezkutu caboverdetarra),
				'one' => q(ezkutu caboverdetar),
				'other' => q(ezkutu caboverdetar),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(libera zipretarra),
				'one' => q(libera zipretar),
				'other' => q(libera zipretar),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(koroa txekiarra),
				'one' => q(koroa txekiar),
				'other' => q(koroa txekiar),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Ekialdeko Alemaniako markoa),
				'one' => q(Ekialdeko Alemaniako marko),
				'other' => q(Ekialdeko Alemaniako marko),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(marko alemana),
				'one' => q(marko aleman),
				'other' => q(marko aleman),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(franko djibutiarra),
				'one' => q(franko djibutiar),
				'other' => q(franko djibutiar),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(koroa danimarkarra),
				'one' => q(koroa danimarkar),
				'other' => q(koroa danimarkar),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(peso dominikarra),
				'one' => q(peso dominikar),
				'other' => q(peso dominikar),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(dinar aljeriarra),
				'one' => q(dinar aljeriar),
				'other' => q(dinar aljeriar),
			},
		},
		'ECS' => {
			symbol => 'ECS',
			display_name => {
				'currency' => q(sukre ekuadortarra),
				'one' => q(sukre ekuadortar),
				'other' => q(sukre ekuadortar),
			},
		},
		'ECV' => {
			symbol => 'ECV',
			display_name => {
				'currency' => q(balio-unitate konstante ekuadortarra),
				'one' => q(balio-unitate konstante ekuadortar),
				'other' => q(balio-unitate konstante ekuadortar),
			},
		},
		'EEK' => {
			symbol => 'EEK',
			display_name => {
				'currency' => q(kroon estoniarra),
				'one' => q(kroon estoniar),
				'other' => q(kroon estoniar),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(libera egiptoarra),
				'one' => q(libera egiptoar),
				'other' => q(libera egiptoar),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(nakfa eritrearra),
				'one' => q(nakfa eritrear),
				'other' => q(nakfa eritrear),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(pezeta espainiarra \(A kontua\)),
				'one' => q(pezeta espainiar \(A kontua\)),
				'other' => q(pezeta espainiar \(A kontua\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(pezeta espainiarra \(kontu bihurgarria\)),
				'one' => q(pezeta espainiar \(kontu bihurgarria\)),
				'other' => q(pezeta espainiar \(kontu bihurgarria\)),
			},
		},
		'ESP' => {
			symbol => '₧',
			display_name => {
				'currency' => q(pezeta espainiarra),
				'one' => q(pezeta espainiar),
				'other' => q(pezeta espainiar),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(birr etiopiarra),
				'one' => q(birr etiopiar),
				'other' => q(birr etiopiar),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(euroa),
				'one' => q(euro),
				'other' => q(euro),
			},
		},
		'FIM' => {
			symbol => 'FIM',
			display_name => {
				'currency' => q(markka finlandiarra),
				'one' => q(markka finlandiar),
				'other' => q(markka finlandiar),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(dolar fijiarra),
				'one' => q(dolar fijiar),
				'other' => q(dolar fijiar),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(libera falklandarra),
				'one' => q(libera falklandar),
				'other' => q(libera falklandar),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(libera frantsesa),
				'one' => q(libera frantses),
				'other' => q(libera frantses),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(libera esterlina),
				'one' => q(libera esterlina),
				'other' => q(libera esterlina),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(kupon larit georgiarra),
				'one' => q(kupon larit georgiar),
				'other' => q(kupon larit georgiar),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(lari georgiarra),
				'one' => q(lari georgiar),
				'other' => q(lari georgiar),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(cedi ghanatarra \(1979–2007\)),
				'one' => q(cedi ghanatar \(1979–2007\)),
				'other' => q(cedi ghanatar \(1979–2007\)),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(cedi ghanatarra),
				'one' => q(cedi ghanatar),
				'other' => q(cedi ghanatar),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(libera gibraltartarra),
				'one' => q(libera gibraltartar),
				'other' => q(libera gibraltartar),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(dalasi gambiarra),
				'one' => q(dalasi gambiar),
				'other' => q(dalasi gambiar),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(franko ginearra),
				'one' => q(franko ginear),
				'other' => q(franko ginear),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(syli ginearra),
				'one' => q(syli ginear),
				'other' => q(syli ginear),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(ekwele ekuatoreginearra),
				'one' => q(ekwele ekuatoreginear),
				'other' => q(ekwele ekuatoreginear),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(drakma greziarra),
				'one' => q(drakma greziar),
				'other' => q(drakma greziar),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(ketzal guatemalarra),
				'one' => q(ketzal guatemalar),
				'other' => q(ketzal guatemalar),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Gineako ezkutu portugesa),
				'one' => q(Gineako ezkutu portuges),
				'other' => q(Gineako ezkutu portuges),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(peso gineabissautarra),
				'one' => q(peso gineabissautar),
				'other' => q(peso gineabissautar),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(dolar guyanarra),
				'one' => q(dolar guyanar),
				'other' => q(dolar guyanar),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(dolar hongkongtarra),
				'one' => q(dolar hongkongtar),
				'other' => q(dolar hongkongtar),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(lempira hodurastarra),
				'one' => q(lempira hodurastar),
				'other' => q(lempira hodurastar),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(dinar kroaziarra),
				'one' => q(dinar kroaziar),
				'other' => q(dinar kroaziar),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(kuna kroaziarra),
				'one' => q(kuna kroaziar),
				'other' => q(kuna kroaziar),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(gourde haitiarra),
				'one' => q(gourde haitiar),
				'other' => q(gourde haitiar),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(forint hungariarra),
				'one' => q(forint hungariar),
				'other' => q(forint hungariar),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(errupia indonesiarra),
				'one' => q(errupia indonesiar),
				'other' => q(errupia indonesiar),
			},
		},
		'IEP' => {
			symbol => 'IEP',
			display_name => {
				'currency' => q(libera irlandarra),
				'one' => q(libera irlandar),
				'other' => q(libera irlandar),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(libera israeldarra),
				'one' => q(libera israeldar),
				'other' => q(libera israeldar),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(shekel israeldarra \(1980–1985\)),
				'one' => q(shekel israeldar \(1980–1985\)),
				'other' => q(shekel israeldar \(1980–1985\)),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(shekel israeldar berria),
				'one' => q(shekel israeldar berri),
				'other' => q(shekel israeldar berri),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(errupia indiarra),
				'one' => q(errupia indiar),
				'other' => q(errupia indiar),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(dinar irakiarra),
				'one' => q(dinar irakiar),
				'other' => q(dinar irakiar),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(rial irandarra),
				'one' => q(rial irandar),
				'other' => q(rial irandar),
			},
		},
		'ISJ' => {
			symbol => 'ISJ',
			display_name => {
				'currency' => q(koroa islandiarra \(1918–1981\)),
				'one' => q(koroa islandiar \(1918–1981\)),
				'other' => q(koroa islandiar \(1918–1981\)),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(koroa islandiarra),
				'one' => q(koroa islandiar),
				'other' => q(koroa islandiar),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(lira italiarra),
				'one' => q(lira italiar),
				'other' => q(lira italiar),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(dolar jamaikarra),
				'one' => q(dolar jamaikar),
				'other' => q(dolar jamaikar),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(dinar jordaniarra),
				'one' => q(dinar jordaniar),
				'other' => q(dinar jordaniar),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(yen japoniarra),
				'one' => q(yen japoniar),
				'other' => q(yen japoniar),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(txelin kenyarra),
				'one' => q(txelin kenyar),
				'other' => q(txelin kenyar),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(som kirgizistandarra),
				'one' => q(som kirgizistandar),
				'other' => q(som kirgizistandar),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(riel kanbodiarra),
				'one' => q(riel kanbodiar),
				'other' => q(riel kanbodiar),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(franko komoretarra),
				'one' => q(franko komoretar),
				'other' => q(franko komoretar),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(won iparkorearra),
				'one' => q(won iparkorear),
				'other' => q(won iparkorear),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(hwan hegokorearra \(1953–1962\)),
				'one' => q(hwan hegokorear \(1953–1962\)),
				'other' => q(hwan hegokorear \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(won hegokorearra \(1945–1953\)),
				'one' => q(won hegokorear \(1945–1953\)),
				'other' => q(won hegokorear \(1945–1953\)),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(won hegokorearra),
				'one' => q(won hegokorear),
				'other' => q(won hegokorear),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(dinar kuwaitarra),
				'one' => q(dinar kuwaitar),
				'other' => q(dinar kuwaitar),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(dolar kaimandarra),
				'one' => q(dolar kaimandar),
				'other' => q(dolar kaimandar),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(tenge kazakhstandarra),
				'one' => q(tenge kazakhstandar),
				'other' => q(tenge kazakhstandar),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(kip laostarra),
				'one' => q(kip laostar),
				'other' => q(kip laostar),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(libera libanoarra),
				'one' => q(libera libanoar),
				'other' => q(libera libanoar),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(errupia srilankarra),
				'one' => q(errupia srilankar),
				'other' => q(errupia srilankar),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(dolar liberiarra),
				'one' => q(dolar liberiar),
				'other' => q(dolar liberiar),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(loti lesothoarra),
				'one' => q(loti lesothoar),
				'other' => q(loti lesothoar),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(Lituaniako litasa),
				'one' => q(Lituaniako litas),
				'other' => q(Lituaniako litas),
			},
		},
		'LTT' => {
			symbol => 'LTT',
			display_name => {
				'currency' => q(Lituaniako talonasa),
				'one' => q(Lituaniako talonas),
				'other' => q(Lituaniako talonas),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Luxenburgoko franko bihurgarria),
				'one' => q(Luxenburgoko franko bihurgarri),
				'other' => q(Luxenburgoko franko bihurgarri),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Luxenburgoko frankoa),
				'one' => q(Luxenburgoko franko),
				'other' => q(Luxenburgoko franko),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Luxenburgoko finantza-frankoa),
				'one' => q(Luxenburgoko finantza-franko),
				'other' => q(Luxenburgoko finantza-franko),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(Letoniako latsa),
				'one' => q(Letoniako lats),
				'other' => q(Letoniako lats),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Letoniako errubloa),
				'one' => q(Letoniako errublo),
				'other' => q(Letoniako errublo),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(dinar libiarra),
				'one' => q(dinar libiar),
				'other' => q(dinar libiar),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(dirham marokoarra),
				'one' => q(dirham marokoar),
				'other' => q(dirham marokoar),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(franko marokoarra),
				'one' => q(franko marokoar),
				'other' => q(franko marokoar),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(Monakoko frankoa),
				'one' => q(Monakoko franko),
				'other' => q(Monakoko franko),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(kupoi moldaviarra),
				'one' => q(kupoi moldaviar),
				'other' => q(kupoi moldaviar),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(leu moldaviarra),
				'one' => q(leu moldaviar),
				'other' => q(leu moldaviar),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(ariary madagaskartarra),
				'one' => q(ariary madagaskartar),
				'other' => q(ariary madagaskartar),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(franko malagasiarra),
				'one' => q(franko malagasiar),
				'other' => q(franko malagasiar),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(dinar mazedoniarra),
				'one' => q(dinar mazedoniar),
				'other' => q(dinar mazedoniar),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(dinar mazedoniarra \(1992–1993\)),
				'one' => q(dinar mazedoniar \(1992–1993\)),
				'other' => q(dinar mazedoniar \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(franko maliarra),
				'one' => q(franko maliar),
				'other' => q(franko maliar),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(kyat myanmartarra),
				'one' => q(kyat myanmartar),
				'other' => q(kyat myanmartar),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(tugrik mongoliarra),
				'one' => q(tugrik mongoliar),
				'other' => q(tugrik mongoliar),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(pataca macauarra),
				'one' => q(pataca macauar),
				'other' => q(pataca macauar),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(Mauritaniako ouguiya \(1973–2017\)),
				'one' => q(Mauritaniako ouguiya \(1973–2017\)),
				'other' => q(Mauritaniako ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			symbol => 'MRU',
			display_name => {
				'currency' => q(uguiya mauritaniarra),
				'one' => q(uguiya mauritaniar),
				'other' => q(uguiya mauritaniar),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(lira maltarra),
				'one' => q(lira maltar),
				'other' => q(lira maltar),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(libera maltar),
				'one' => q(libera maltar),
				'other' => q(libera maltar),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(errupia mauriziarra),
				'one' => q(errupia mauriziar),
				'other' => q(errupia mauriziar),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(errupia maldivarra \(1947–1981\)),
				'one' => q(errupia maldivar \(1947–1981\)),
				'other' => q(errupia maldivar \(1947–1981\)),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(rufiyaa maldivarra),
				'one' => q(rufiyaa maldivar),
				'other' => q(rufiyaa maldivar),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(kwacha malawiarra),
				'one' => q(kwacha malawiar),
				'other' => q(kwacha malawiar),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(peso mexikarra),
				'one' => q(peso mexikar),
				'other' => q(peso mexikar),
			},
		},
		'MXP' => {
			symbol => 'MXP',
			display_name => {
				'currency' => q(Zilar-peso amerikarra \(1861–1992\)),
				'one' => q(Zilar-peso amerikar \(1861–1992\)),
				'other' => q(Zilar-peso amerikar \(1861–1992\)),
			},
		},
		'MXV' => {
			symbol => 'MXV',
			display_name => {
				'currency' => q(Inbertsio-unitate mexikarra),
				'one' => q(Inbertsio-unitate mexikar),
				'other' => q(Inbertsio-unitate mexikar),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(ringgit malaysiarra),
				'one' => q(ringgit malaysiar),
				'other' => q(ringgit malaysiar),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(ezkutu mozambiketarra),
				'one' => q(ezkutu mozambiketar),
				'other' => q(ezkutu mozambiketar),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(metikal mozambiketarra),
				'one' => q(metikal mozambiketar),
				'other' => q(metikal mozambiketar),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(metical mozambiketarra),
				'one' => q(metical mozambiketar),
				'other' => q(metical mozambiketar),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(dolar namibiarra),
				'one' => q(dolar namibiar),
				'other' => q(dolar namibiar),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(naira nigeriarra),
				'one' => q(naira nigeriar),
				'other' => q(naira nigeriar),
			},
		},
		'NIC' => {
			symbol => 'NIC',
			display_name => {
				'currency' => q(kordoba nikaraguar \(1988–1991\)),
				'one' => q(kordoba nikaraguar \(1988–1991\)),
				'other' => q(kordoba nikaraguar \(1988–1991\)),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(cordoba nikaraguarra),
				'one' => q(cordoba nikaraguar),
				'other' => q(cordoba nikaraguar),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(gilder herbeheretarra),
				'one' => q(gilder herbeheretar),
				'other' => q(gilder herbeheretar),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(koroa norvegiarra),
				'one' => q(koroa norvegiar),
				'other' => q(koroa norvegiar),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(errupia nepaldarra),
				'one' => q(errupia nepaldar),
				'other' => q(errupia nepaldar),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(dolar zeelandaberritarra),
				'one' => q(dolar zeelandaberritar),
				'other' => q(dolar zeelandaberritar),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(rial omandarra),
				'one' => q(rial omandar),
				'other' => q(rial omandar),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(balboa panamarra),
				'one' => q(balboa panamar),
				'other' => q(balboa panamar),
			},
		},
		'PEI' => {
			symbol => 'PEI',
			display_name => {
				'currency' => q(inti perutarra),
				'one' => q(inti perutar),
				'other' => q(inti perutar),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(sol perutarra),
				'one' => q(sol perutar),
				'other' => q(sol perutar),
			},
		},
		'PES' => {
			symbol => 'PES',
			display_name => {
				'currency' => q(sol perutarra \(1863–1965\)),
				'one' => q(sol perutar \(1863–1965\)),
				'other' => q(sol perutar \(1863–1965\)),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(kina gineaberriarra),
				'one' => q(kina gineaberriar),
				'other' => q(kina gineaberriar),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(peso filipinarra),
				'one' => q(peso filipinar),
				'other' => q(peso filipinar),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(errupia pakistandarra),
				'one' => q(errupia pakistandar),
				'other' => q(errupia pakistandar),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(zloty poloniarra),
				'one' => q(zloty poloniar),
				'other' => q(zloty poloniar),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(zloty poloniarra \(1950–1995\)),
				'one' => q(zloty poloniar \(PLZ\)),
				'other' => q(zloty poloniar \(PLZ\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(ezkutu portugesa),
				'one' => q(ezkutu portuges),
				'other' => q(ezkutu portuges),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(guarani paraguaitarra),
				'one' => q(guarani paraguaitar),
				'other' => q(guarani paraguaitar),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(riyal qatartarra),
				'one' => q(riyal qatartar),
				'other' => q(riyal qatartar),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(dolar rhodesiarra),
				'one' => q(dolar rhodesiar),
				'other' => q(dolar rhodesiar),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(leu errumaniarra \(1952–2006\)),
				'one' => q(leu errumaniar \(1952–2006\)),
				'other' => q(leu errumaniar \(1952–2006\)),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(leu errumaniarra),
				'one' => q(leu errumaniar),
				'other' => q(leu errumaniar),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(dinar serbiarra),
				'one' => q(dinar serbiar),
				'other' => q(dinar serbiar),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(errublo errusiarra),
				'one' => q(errublo errusiar),
				'other' => q(errublo errusiar),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(errublo errusiarra \(1991–1998\)),
				'one' => q(errublo errusiar \(1991–1998\)),
				'other' => q(errublo errusiar \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(franko ruandarra),
				'one' => q(franko ruandar),
				'other' => q(franko ruandar),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(riyal saudiarabiarra),
				'one' => q(riyal saudiarabiar),
				'other' => q(riyal saudiarabiar),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(dolar salomondarra),
				'one' => q(dolar salomondar),
				'other' => q(dolar salomondar),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(errupia seychelletarra),
				'one' => q(errupia seychelletar),
				'other' => q(errupia seychelletar),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(dinar sudandarra \(1992–2007\)),
				'one' => q(dinar sudandar \(1992–2007\)),
				'other' => q(dinar sudandar \(1992–2007\)),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(libera sudandarra),
				'one' => q(libera sudandar),
				'other' => q(libera sudandar),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(libera sudandarra \(1957–1998\)),
				'one' => q(libera sudandar \(1957–1998\)),
				'other' => q(libera sudandar \(1957–1998\)),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(koroa suediarra),
				'one' => q(koroa suediar),
				'other' => q(koroa suediar),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(dolar singapurtarra),
				'one' => q(dolar singapurtar),
				'other' => q(dolar singapurtar),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Santa Helenako libera),
				'one' => q(Santa Helenako libera),
				'other' => q(Santa Helenako libera),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(tolar esloveniarra),
				'one' => q(tolar esloveniar),
				'other' => q(tolar esloveniar),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(koroa eslovakiarra),
				'one' => q(koroa eslovakiar),
				'other' => q(koroa eslovakiar),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(leone sierraleonarra),
				'one' => q(leone sierraleonar),
				'other' => q(leone sierraleonar),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(txelin somaliarra),
				'one' => q(txelin somaliar),
				'other' => q(txelin somaliar),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(dolar surinamdarra),
				'one' => q(dolar surinamdar),
				'other' => q(dolar surinamdar),
			},
		},
		'SRG' => {
			symbol => 'SRG',
			display_name => {
				'currency' => q(gilder surinamdarra),
				'one' => q(gilder surinamdar),
				'other' => q(gilder surinamdar),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(libera hegosudandarra),
				'one' => q(libera hegosudandar),
				'other' => q(libera hegosudandar),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(Sao Tomeko eta Principeko dobra \(1977–2017\)),
				'one' => q(Sao Tomeko eta Principeko dobra \(1977–2017\)),
				'other' => q(Sao Tomeko eta Principeko dobra \(1977–2017\)),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(dobra saotometarra),
				'one' => q(dobra saotometar),
				'other' => q(dobra saotometar),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(errublo sovietarra),
				'one' => q(errublo sovietar),
				'other' => q(errublo sovietar),
			},
		},
		'SVC' => {
			symbol => 'SVC',
			display_name => {
				'currency' => q(kolon salvadortarra),
				'one' => q(kolon salvadortar),
				'other' => q(kolon salvadortar),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(libera siriarra),
				'one' => q(libera siriar),
				'other' => q(libera siriar),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(lilangeni swazilandiarra),
				'one' => q(lilangeni swazilandiar),
				'other' => q(lilangeni swazilandiar),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(baht thailandiarra),
				'one' => q(baht thailandiar),
				'other' => q(baht thailandiar),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(errublo tajikistandarra),
				'one' => q(errublo tajikistandar),
				'other' => q(errublo tajikistandar),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(somoni tajikistandarra),
				'one' => q(somoni tajikistandar),
				'other' => q(somoni tajikistandar),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(manat turkmenistandarra \(1993–2009\)),
				'one' => q(manat turkmenistandar \(1993–2009\)),
				'other' => q(manat turkmenistandar \(1993–2009\)),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(manat turkmenistandarra),
				'one' => q(manat turkmenistandar),
				'other' => q(manat turkmenistandar),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(dinar tunisiarra),
				'one' => q(dinar tunisiar),
				'other' => q(dinar tunisiar),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(paʻanga tongatarra),
				'one' => q(paʻanga tongatar),
				'other' => q(paʻanga tongatar),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(ezkutu timortarra),
				'one' => q(ezkutu timortar),
				'other' => q(ezkutu timortar),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(lira turkiarra \(1922–2005\)),
				'one' => q(lira turkiar \(1922–2005\)),
				'other' => q(lira turkiar \(1922–2005\)),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(lira turkiarra),
				'one' => q(lira turkiar),
				'other' => q(lira turkiar),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(dolar trinitatearra),
				'one' => q(dolar trinitatear),
				'other' => q(dolar trinitatear),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(dolar taiwandar berria),
				'one' => q(dolar taiwandar berri),
				'other' => q(dolar taiwandar berri),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(txelin tanzaniarra),
				'one' => q(txelin tanzaniar),
				'other' => q(txelin tanzaniar),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(hryvnia ukrainarra),
				'one' => q(hryvnia ukrainar),
				'other' => q(hryvnia ukrainar),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(karbovanets ukrainarra),
				'one' => q(karbovanets ukrainar),
				'other' => q(karbovanets ukrainar),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(txelin ugandarra \(1966–1987\)),
				'one' => q(txelin ugandar \(1966–1987\)),
				'other' => q(txelin ugandar \(1966–1987\)),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(txelin ugandarra),
				'one' => q(txelin ugandar),
				'other' => q(txelin ugandar),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(dolar estatubatuarra),
				'one' => q(dolar estatubatuar),
				'other' => q(dolar estatubatuar),
			},
		},
		'USN' => {
			symbol => 'USN',
			display_name => {
				'currency' => q(dolar estatubatuar \(Hurrengo eguna\)),
				'one' => q(dolar estatubatuar \(hurrengo eguna\)),
				'other' => q(dolar estatubatuar \(hurrengo eguna\)),
			},
		},
		'USS' => {
			symbol => 'USS',
			display_name => {
				'currency' => q(dolar estatubatuar \(Egun berean\)),
				'one' => q(dolar estatubatuar \(egun berean\)),
				'other' => q(dolar estatubatuar \(egun berean\)),
			},
		},
		'UYI' => {
			symbol => 'UYI',
			display_name => {
				'currency' => q(peso uruguaitarra \(unitate indexatuak\)),
				'one' => q(peso uruguaitar \(unitate indexatuak\)),
				'other' => q(peso uruguaitar \(unitate indexatuak\)),
			},
		},
		'UYP' => {
			symbol => 'UYP',
			display_name => {
				'currency' => q(peso uruguaitarra \(1975–1993\)),
				'one' => q(peso uruguaitar \(1975–1993\)),
				'other' => q(peso uruguaitar \(1975–1993\)),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(peso uruguaitarra),
				'one' => q(peso uruguaitar),
				'other' => q(peso uruguaitar),
			},
		},
		'UYW' => {
			symbol => 'UYW',
			display_name => {
				'currency' => q(soldata nominalaren indize-unitate uruguaitarra),
				'one' => q(soldata nominalaren indize-unitate uruguaitar),
				'other' => q(soldata nominalaren indize-unitate uruguaitar),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(sum uzbekistandarra),
				'one' => q(sum uzbekistandar),
				'other' => q(sum uzbekistandar),
			},
		},
		'VEB' => {
			symbol => 'VEB',
			display_name => {
				'currency' => q(Venezuelako bolivarra \(1871–2008\)),
				'one' => q(Venezuelako bolivar \(1871–2008\)),
				'other' => q(Venezuelako bolivar \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(Venezuelako bolivarra \(2008–2018\)),
				'one' => q(Venezuelako bolivar \(2008–2018\)),
				'other' => q(Venezuelako bolivar \(2008–2018\)),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(bolivar venezuelarra),
				'one' => q(bolivar venezuelar),
				'other' => q(bolivar venezuelar),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(dong vietnamdarra),
				'one' => q(dong vietnamdar),
				'other' => q(dong vietnamdar),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(dong vietnamdar \(1978–1985\)),
				'one' => q(dong vietnamdar \(1978–1985\)),
				'other' => q(dong vietnamdar \(1978–1985\)),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(vatu vanuatuarra),
				'one' => q(vatu vanuatuar),
				'other' => q(vatu vanuatuar),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(tala samoarra),
				'one' => q(tala samoar),
				'other' => q(tala samoar),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(Afrika erdialdeko CFA frankoa),
				'one' => q(Afrika erdialdeko CFA franko),
				'other' => q(Afrika erdialdeko CFA franko),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(zilarra),
				'one' => q(zilarrezko troy ontza),
				'other' => q(zilarrezko troy ontza),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(urrea),
				'one' => q(urrezko troy ontza),
				'other' => q(urrezko troy ontza),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Europako unitate konposatua),
				'one' => q(Europako unitate konposatu),
				'other' => q(Europako unitate konposatu),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Europako moneta-unitatea),
				'one' => q(Europako moneta-unitate),
				'other' => q(Europako moneta-unitate),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Europako kontu-unitatea \(XBC\)),
				'one' => q(Europako kontu-unitate \(XBC\)),
				'other' => q(Europako kontu-unitate \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Europako kontu-unitatea \(XBD\)),
				'one' => q(Europako kontu-unitate \(XBD\)),
				'other' => q(Europako kontu-unitate \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(dolar ekikaribearra),
				'one' => q(dolar ekikaribear),
				'other' => q(dolar ekikaribear),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(igorpen-eskubide berezia),
				'one' => q(igorpen-eskubide berezi),
				'other' => q(igorpen-eskubide berezi),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Europako dibisa-unitatea),
				'one' => q(Europako dibisa-unitate),
				'other' => q(Europako dibisa-unitate),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(urrezko libera frantsesa),
				'one' => q(urrezko libera frantses),
				'other' => q(urrezko libera frantses),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(UIC libera frantsesa),
				'one' => q(UIC libera frantses),
				'other' => q(UIC libera frantses),
			},
		},
		'XOF' => {
			symbol => 'F CFA',
			display_name => {
				'currency' => q(Afrika mendebaldeko CFA frankoa),
				'one' => q(Afrika mendebaldeko CFA franko),
				'other' => q(Afrika mendebaldeko CFA franko),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(paladioa),
				'one' => q(paladiozko troy ontza),
				'other' => q(paladiozko troy ontza),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(CFP frankoa),
				'one' => q(CFP franko),
				'other' => q(CFP franko),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platinozko troy ontza),
				'one' => q(platinozko troy ontza),
				'other' => q(platinozko troy ontza),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET funtsak),
				'one' => q(RINET funtsen unitate),
				'other' => q(RINET funtsen unitate),
			},
		},
		'XSU' => {
			display_name => {
				'currency' => q(sucrea),
				'one' => q(sucre),
				'other' => q(sucre),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(aztertzeko dibisa-unitatea),
				'one' => q(aztertzeko dibisa-unitate),
				'other' => q(aztertzeko dibisa-unitate),
			},
		},
		'XUA' => {
			display_name => {
				'currency' => q(ADB kontu-unitatea),
				'one' => q(ADB kontu-unitate),
				'other' => q(ADB kontu-unitate),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(moneta ezezaguna),
				'one' => q(\(moneta ezezaguna\)),
				'other' => q(\(moneta ezezaguna\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(dinar yemendarra),
				'one' => q(dinar yemendar),
				'other' => q(dinar yemendar),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(rial yemendarra),
				'one' => q(rial yemendar),
				'other' => q(rial yemendar),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(dinar yugoslaviar indartsua \(1966–1990\)),
				'one' => q(dinar yugoslaviar indartsu \(1966–1990\)),
				'other' => q(dinar yugoslaviar indartsu \(1966–1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(dinar yugoslaviar berria \(1994–2002\)),
				'one' => q(dinar yugoslaviar berri \(1994–2002\)),
				'other' => q(dinar yugoslaviar berri \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(dinar yugoslaviar bihurgarria \(1990–1992\)),
				'one' => q(dinar yugoslaviar bihurgarri \(1990–1992\)),
				'other' => q(dinar yugoslaviar bihurgarri \(1990–1992\)),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(dinar yugoslaviar erreformatua \(1992–1993\)),
				'one' => q(dinar yugoslaviar erreformatu \(1992–1993\)),
				'other' => q(dinar yugoslaviar erreformatu \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(rand hegoafrikarra \(finantzarioa\)),
				'one' => q(rand hegoafrikar \(finantzarioa\)),
				'other' => q(rand hegoafrikar \(finantzarioa\)),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(rand hegoafrikarra),
				'one' => q(rand hegoafrikar),
				'other' => q(rand hegoafrikar),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Zambiako kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(kwacha zambiarra),
				'one' => q(kwacha zambiar),
				'other' => q(kwacha zambiar),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(zaire berri zairetarra \(1993–1998\)),
				'one' => q(zaire berri zairetar \(1993–1998\)),
				'other' => q(zaire berri zairetar \(1993–1998\)),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(zaire zairetarra \(1971–1993\)),
				'one' => q(zaire zairetar \(1971–1993\)),
				'other' => q(zaire zairetar \(1971–1993\)),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(dolar zimbabwetarra \(1980–2008\)),
				'one' => q(dolar zimbabwetar \(1980–2008\)),
				'other' => q(dolar zimbabwetar \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(dolar zimbabwetarra \(2009\)),
				'one' => q(dolar zimbabwetar \(2009\)),
				'other' => q(dolar zimbabwetar \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(dolar zimbabwetarra \(2008\)),
				'one' => q(dolar zimbabwetar \(2008\)),
				'other' => q(dolar zimbabwetar \(2008\)),
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
							'urt.',
							'ots.',
							'mar.',
							'api.',
							'mai.',
							'eka.',
							'uzt.',
							'abu.',
							'ira.',
							'urr.',
							'aza.',
							'abe.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'U',
							'O',
							'M',
							'A',
							'M',
							'E',
							'U',
							'A',
							'I',
							'U',
							'A',
							'A'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'urtarrilak',
							'otsailak',
							'martxoak',
							'apirilak',
							'maiatzak',
							'ekainak',
							'uztailak',
							'abuztuak',
							'irailak',
							'urriak',
							'azaroak',
							'abenduak'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'urt.',
							'ots.',
							'mar.',
							'api.',
							'mai.',
							'eka.',
							'uzt.',
							'abu.',
							'ira.',
							'urr.',
							'aza.',
							'abe.'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'U',
							'O',
							'M',
							'A',
							'M',
							'E',
							'U',
							'A',
							'I',
							'U',
							'A',
							'A'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'urtarrila',
							'otsaila',
							'martxoa',
							'apirila',
							'maiatza',
							'ekaina',
							'uztaila',
							'abuztua',
							'iraila',
							'urria',
							'azaroa',
							'abendua'
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
						mon => 'al.',
						tue => 'ar.',
						wed => 'az.',
						thu => 'og.',
						fri => 'or.',
						sat => 'lr.',
						sun => 'ig.'
					},
					narrow => {
						mon => 'A',
						tue => 'A',
						wed => 'A',
						thu => 'O',
						fri => 'O',
						sat => 'L',
						sun => 'I'
					},
					short => {
						mon => 'al.',
						tue => 'ar.',
						wed => 'az.',
						thu => 'og.',
						fri => 'or.',
						sat => 'lr.',
						sun => 'ig.'
					},
					wide => {
						mon => 'astelehena',
						tue => 'asteartea',
						wed => 'asteazkena',
						thu => 'osteguna',
						fri => 'ostirala',
						sat => 'larunbata',
						sun => 'igandea'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'al.',
						tue => 'ar.',
						wed => 'az.',
						thu => 'og.',
						fri => 'or.',
						sat => 'lr.',
						sun => 'ig.'
					},
					narrow => {
						mon => 'A',
						tue => 'A',
						wed => 'A',
						thu => 'O',
						fri => 'O',
						sat => 'L',
						sun => 'I'
					},
					short => {
						mon => 'al.',
						tue => 'ar.',
						wed => 'az.',
						thu => 'og.',
						fri => 'or.',
						sat => 'lr.',
						sun => 'ig.'
					},
					wide => {
						mon => 'astelehena',
						tue => 'asteartea',
						wed => 'asteazkena',
						thu => 'osteguna',
						fri => 'ostirala',
						sat => 'larunbata',
						sun => 'igandea'
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
					abbreviated => {0 => '1Hh',
						1 => '2Hh',
						2 => '3Hh',
						3 => '4Hh'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1. hiruhilekoa',
						1 => '2. hiruhilekoa',
						2 => '3. hiruhilekoa',
						3 => '4. hiruhilekoa'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1Hh',
						1 => '2Hh',
						2 => '3Hh',
						3 => '4Hh'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1. hiruhilekoa',
						1 => '2. hiruhilekoa',
						2 => '3. hiruhilekoa',
						3 => '4. hiruhilekoa'
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
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1400;
					return 'afternoon2' if $time >= 1400
						&& $time < 1900;
					return 'evening1' if $time >= 1900
						&& $time < 2100;
					return 'morning1' if $time >= 0
						&& $time < 600;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night1' if $time >= 2100
						&& $time < 2400;
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
					'afternoon1' => q{eguerd.},
					'afternoon2' => q{arrats.},
					'am' => q{AM},
					'evening1' => q{iluntz.},
					'midnight' => q{gauerdia},
					'morning1' => q{goizald.},
					'morning2' => q{goizeko},
					'night1' => q{gaueko},
					'pm' => q{PM},
				},
				'narrow' => {
					'afternoon1' => q{eguerd.},
					'afternoon2' => q{arrats.},
					'am' => q{g},
					'evening1' => q{iluntz.},
					'midnight' => q{gauerdia},
					'morning1' => q{goizald.},
					'morning2' => q{goizeko},
					'night1' => q{gaueko},
					'pm' => q{a},
				},
				'wide' => {
					'afternoon1' => q{eguerdiko},
					'afternoon2' => q{arratsaldeko},
					'am' => q{AM},
					'evening1' => q{iluntzeko},
					'midnight' => q{gauerdia},
					'morning1' => q{goizaldeko},
					'morning2' => q{goizeko},
					'night1' => q{gaueko},
					'pm' => q{PM},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{eguerd.},
					'afternoon2' => q{arrats.},
					'am' => q{AM},
					'evening1' => q{iluntz.},
					'midnight' => q{gauerdia},
					'morning1' => q{goiz.},
					'morning2' => q{goiza},
					'night1' => q{gaua},
					'pm' => q{PM},
				},
				'narrow' => {
					'afternoon1' => q{eguerd.},
					'afternoon2' => q{arrats.},
					'am' => q{AM},
					'evening1' => q{iluntz.},
					'midnight' => q{gauerdia},
					'morning1' => q{goizald.},
					'morning2' => q{goiza},
					'night1' => q{gaua},
					'pm' => q{PM},
				},
				'wide' => {
					'afternoon1' => q{eguerdia},
					'afternoon2' => q{arratsaldea},
					'am' => q{AM},
					'evening1' => q{iluntzea},
					'midnight' => q{gauerdia},
					'morning1' => q{goizaldea},
					'morning2' => q{goiza},
					'night1' => q{gaua},
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
				'0' => 'BG'
			},
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'K.a.',
				'1' => 'K.o.'
			},
			narrow => {
				'0' => 'a',
				'1' => 'o'
			},
			wide => {
				'0' => 'K.a.',
				'1' => 'Kristo ondoren'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => 'R.O.C. aurretik',
				'1' => 'R.O.C.'
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
		'generic' => {
			'full' => q{G. 'aroko' y. 'urteko' MMMM d, EEEE},
			'long' => q{G. 'aroko' y. 'urteko' MMMM d},
			'medium' => q{G. 'aroko' y('e')'ko' MMM d},
			'short' => q{GGGGG y-MM-dd},
		},
		'gregorian' => {
			'full' => q{y('e')'ko' MMMM'ren' d('a'), EEEE},
			'long' => q{y('e')'ko' MMMM'ren' d('a')},
			'medium' => q{y('e')'ko' MMM d('a')},
			'short' => q{yy/M/d},
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
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH:mm:ss (zzzz)},
			'long' => q{HH:mm:ss (z)},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
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
		'generic' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
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
		'generic' => {
			Bh => q{B h('r')('a')'k'},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:s},
			E => q{ccc},
			EBhm => q{E B h:mm},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d, EEEE},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G. 'aroko' y. 'urtea'},
			GyMMM => q{G. 'aroko' y('e')'ko' MMMM},
			GyMMMEd => q{G. 'aroko' y('e')'ko' MMMM d, EEEE},
			GyMMMd => q{G. 'aroko' y('e')'ko' MMMM d},
			GyMd => q{y-MM-dd (GGGGG)},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{MM/dd, EEEE},
			MMM => q{LLL},
			MMMEd => q{MMM'k' d, EEEE},
			MMMMd => q{MMMM'k' d},
			MMMd => q{MMM'k' d},
			Md => q{MM/dd},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y},
			yM => q{y/MM},
			yMEd => q{y/MM/dd, EEEE},
			yMMM => q{y('e')'ko' MMMM},
			yMMMEd => q{y('e')'ko' MMMM'k' d, EEEE},
			yMMMd => q{y('e')'ko' MMMM'k' d},
			yMd => q{y/MM/dd},
			yQQQ => q{y('e')'ko' QQQ},
			yQQQQ => q{y('e')'ko' QQQQ},
			yyyy => q{G y},
			yyyyM => q{G y/MM},
			yyyyMEd => q{G('e')'ko' y/MM/dd, EEEE},
			yyyyMMM => q{G, y('e')'ko' MMM},
			yyyyMMMEd => q{G y MMM d, EEEE},
			yyyyMMMM => q{G y('e')'ko' MMMM},
			yyyyMMMMEd => q{G y('e')'ko' MMMM d, EEEE},
			yyyyMMMMd => q{G y('e')'ko' MMMM d},
			yyyyMMMd => q{G y MMM d},
			yyyyMd => q{G('e')'ko' y/MM/dd},
			yyyyQQQ => q{G y QQQ},
			yyyyQQQQ => q{G y('e')'ko' QQQQ},
		},
		'gregorian' => {
			Bh => q{B h},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			E => q{ccc},
			EBhm => q{E B h:mm},
			EBhms => q{E B h:mm:ss},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d, E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{G y. 'urteko' MMM},
			GyMMMEd => q{G y. 'urteko' MMM d, E},
			GyMMMd => q{G y. 'urteko' MMM d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{M/d, E},
			MMM => q{LLL},
			MMMEd => q{MMM d, E},
			MMMMW => q{MMMM W. 'astea'},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{M/d},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{y/M},
			yMEd => q{y/M/d, E},
			yMMM => q{y MMM},
			yMMMEd => q{y MMM d, E},
			yMMMM => q{y('e')'ko' MMMM},
			yMMMMEd => q{y('e')'ko' MMMM'k' d, E},
			yMMMMd => q{y('e')'ko' MMMM'ren' d},
			yMMMd => q{y MMM d},
			yMd => q{y/M/d},
			yQQQ => q{y('e')'ko' QQQ},
			yQQQQ => q{y('e')'ko' QQQQ},
			yw => q{Y. 'urteko' w. 'astea'},
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
			Bh => {
				B => q{B h – B h},
				h => q{B h–h},
			},
			Bhm => {
				B => q{B h:mm – B h:mm},
				h => q{B h:mm–h:mm},
				m => q{B h:mm–h:mm},
			},
			GyMMM => {
				G => q{G y, MMM – G y, MMM},
				M => q{G y, MMM–MMM},
				y => q{G y, MMM – G y, MMM},
			},
			GyMMMEd => {
				G => q{G y, MMM d, E – G y, MMM d, E},
				M => q{G y, MMM d, E – MMM d, E},
				d => q{G y, MMM d, E – MMM d, E},
				y => q{G y, MMM d, E – G y, MMM d, E},
			},
			GyMMMd => {
				G => q{G y, MMM d – G y, MMM d},
				M => q{G y, MMM d – MMM d},
				d => q{G y, MMM d–d},
				y => q{G y, MMM d – G y, MMM d},
			},
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
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
				M => q{MM/dd, EEEE – MM/dd, EEEE},
				d => q{MM/dd, EEEE – MM/dd, EEEE},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{MMM'k' d, EEEE – MMM'k' d, EEEE},
				d => q{MMM'k' d, EEEE – MMM'k' d, EEEE},
			},
			MMMd => {
				M => q{MMM'k' d – MMMM'k' d},
				d => q{MMMM d–d},
			},
			Md => {
				M => q{MM/dd – MM/dd},
				d => q{MM/dd – MM/dd},
			},
			d => {
				d => q{dd–dd},
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
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{G y–y},
			},
			yM => {
				M => q{G y/MM – y/MM},
				y => q{G y/MM – y/MM},
			},
			yMEd => {
				M => q{G y/MM/dd, EEEE – y/MM/dd, EEEE},
				d => q{G y/MM/dd, EEEE – y/MM/dd, EEEE},
				y => q{G y/MM/dd, EEEE – y/MM/dd, EEEE},
			},
			yMMM => {
				M => q{G y('e')'ko' MMMM–MMMM},
				y => q{G y('e')'ko' MMMM – y('e')'ko' MMMM},
			},
			yMMMEd => {
				M => q{G y('e')'ko' MMMM dd, EEEE – MMMM dd, EEEE},
				d => q{G y('e')'ko' MMMM dd, EEEE – MMMM dd, EEEE},
				y => q{G y('e')'ko' MMMM dd, EEEE – y('e')'ko' MMMM dd, EEEE},
			},
			yMMMM => {
				M => q{G y('e')'ko' MMMM – MMMM},
				y => q{G y('e')'ko' MMMM – y('e')'ko' MMMM},
			},
			yMMMd => {
				M => q{G y('e')'ko' MMMM dd – MMMM dd},
				d => q{G y('e')'ko' MMMM dd–dd},
				y => q{G y('e')'ko' MMMM dd – y('e')'ko' MMMM dd},
			},
			yMd => {
				M => q{G y/MM/dd – y/MM/dd},
				d => q{G y/MM/dd – y/MM/dd},
				y => q{G y/MM/dd – y/MM/dd},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{B h – B h},
				h => q{B h–h},
			},
			Bhm => {
				B => q{B h:mm – B h:mm},
				h => q{B h:mm–h:mm},
				m => q{B h:mm–h:mm},
			},
			GyMMM => {
				G => q{G y, MMM – G y, MMM},
				M => q{G y, MMM–MMM},
				y => q{G y, MMM – G y, MMM},
			},
			GyMMMEd => {
				G => q{G y, MMM d, E – G y, MMM d, E},
				M => q{G y, MMM d, E – MMM d, E},
				d => q{G y, MMM d, E – MMM d, E},
				y => q{G y, MMM d, E – G y, MMM d, E},
			},
			GyMMMd => {
				G => q{G y, MMM d – G y, MMM d},
				M => q{G y, MMM d – MMM d},
				d => q{G y, MMM d–d},
				y => q{G y, MMM d – G y, MMM d},
			},
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
				M => q{M–M},
			},
			MEd => {
				M => q{M/d, E – M/d, E},
				d => q{M/d, E – M/d, E},
			},
			MMM => {
				M => q{MMM–MMM},
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
				M => q{M/d – M/d},
				d => q{M/d – M/d},
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
				M => q{y/M – y/M},
				y => q{y/M – y/M},
			},
			yMEd => {
				M => q{y/M/d, E – y/M/d, E},
				d => q{y/M/d, E – y/M/d, E},
				y => q{y/M/d, E – y/M/d, E},
			},
			yMMM => {
				M => q{y('e')'ko' MMM–MMM},
				y => q{y('e')'ko' MMM – y('e')'ko' MMM},
			},
			yMMMEd => {
				M => q{y('e')'ko' MMM d, E – MMM d, E},
				d => q{y('e')'ko' MMM d, E – y('e')'ko' MMM d, E},
				y => q{y('e')'ko' MMM d, E – y('e')'ko' MMM d, E},
			},
			yMMMM => {
				M => q{y('e')'ko' MMMM–MMMM},
				y => q{y('e')'ko' MMMM – y('e')'ko' MMMM},
			},
			yMMMd => {
				M => q{y('e')'ko' MMM d – MMM d},
				d => q{y('e')'ko' MMM d–d},
				y => q{y('e')'ko' MMM d – y('e')'ko' MMM d},
			},
			yMd => {
				M => q{y/M/d – y/M/d},
				d => q{y/M/d – y/M/d},
				y => q{y/M/d – y/M/d},
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
		regionFormat => q({0} aldeko ordua),
		regionFormat => q({0} (udako ordua)),
		regionFormat => q({0} aldeko ordu estandarra),
		fallbackFormat => q({1} ({0})),
		'Acre' => {
			long => {
				'daylight' => q#Acreko udako ordua#,
				'generic' => q#Acreko ordua#,
				'standard' => q#Acreko ordu estandarra#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Afganistango ordua#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akkra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Aljer#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmara#,
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
			exemplarCity => q#Kairo#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Casablanca#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Ceuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Konakry#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar es Salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Djibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Douala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Aaiun#,
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
			exemplarCity => q#Johannesburgo#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartoum#,
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
			exemplarCity => q#Lome#,
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
			exemplarCity => q#Muqdisho#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovia#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#N’djamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamei#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nuakxot#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Uagadugu#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sao Tome#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunis#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Afrikako erdialdeko ordua#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Afrikako ekialdeko ordua#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Afrikako hegoaldeko ordua#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Afrikako mendebaldeko udako ordua#,
				'generic' => q#Afrikako mendebaldeko ordua#,
				'standard' => q#Afrikako mendebaldeko ordu estandarra#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaskako udako ordua#,
				'generic' => q#Alaskako ordua#,
				'standard' => q#Alaskako ordu estandarra#,
			},
			short => {
				'daylight' => q#AKDT#,
				'generic' => q#AKT#,
				'standard' => q#AKST#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Almatyko udako ordua#,
				'generic' => q#Almatyko ordua#,
				'standard' => q#Almatyko ordu estandarra#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazoniako udako ordua#,
				'generic' => q#Amazoniako ordua#,
				'standard' => q#Amazoniako ordu estandarra#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Anchorage#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Aingira#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antigua#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaína#,
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
			exemplarCity => q#Asuncion#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahia#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahía de Banderas#,
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
			exemplarCity => q#Bogota#,
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
			exemplarCity => q#Kaiman#,
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
			exemplarCity => q#Cuiabá#,
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
			exemplarCity => q#Dominika#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmonton#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepé#,
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
			exemplarCity => q#Grenada#,
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
			exemplarCity => q#Habana#,
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
			exemplarCity => q#Jamaika#,
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
			exemplarCity => q#Maceió#,
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
			exemplarCity => q#Martinika#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
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
			exemplarCity => q#Mexiko Hiria#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Mikelune#,
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
			exemplarCity => q#New York#,
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
			exemplarCity => q#Beulah, Ipar Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Ipar Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Ipar Dakota#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ojinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#Panama#,
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
			exemplarCity => q#Port-au-Prince#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port-of-Spain#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Porto Velho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puerto Rico#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Punta Arenas#,
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
			exemplarCity => q#Santarém#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint-Barthélemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Saint John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Saint Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Santa Luzia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Saint-Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Saint Vincent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Swift Current#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegucigalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Qaanaac#,
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
			exemplarCity => q#Tortola#,
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
				'daylight' => q#Ipar Amerikako erdialdeko udako ordua#,
				'generic' => q#Ipar Amerikako erdialdeko ordua#,
				'standard' => q#Ipar Amerikako erdialdeko ordu estandarra#,
			},
			short => {
				'daylight' => q#CDT#,
				'generic' => q#CT#,
				'standard' => q#CST#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Ipar Amerikako ekialdeko udako ordua#,
				'generic' => q#Ipar Amerikako ekialdeko ordua#,
				'standard' => q#Ipar Amerikako ekialdeko ordu estandarra#,
			},
			short => {
				'daylight' => q#EDT#,
				'generic' => q#ET#,
				'standard' => q#EST#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Ipar Amerikako mendialdeko udako ordua#,
				'generic' => q#Ipar Amerikako mendialdeko ordua#,
				'standard' => q#Ipar Amerikako mendialdeko ordu estandarra#,
			},
			short => {
				'daylight' => q#MDT#,
				'generic' => q#MT#,
				'standard' => q#MST#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Ipar Amerikako Pazifikoko udako ordua#,
				'generic' => q#Ipar Amerikako Pazifikoko ordua#,
				'standard' => q#Ipar Amerikako Pazifikoko ordu estandarra#,
			},
			short => {
				'daylight' => q#PDT#,
				'generic' => q#PT#,
				'standard' => q#PST#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadyrreko udako ordua#,
				'generic' => q#Anadyrreko ordua#,
				'standard' => q#Anadyrreko ordu estandarra#,
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
				'daylight' => q#Apiako udako ordua#,
				'generic' => q#Apiako ordua#,
				'standard' => q#Apiako ordu estandarra#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Aktauko udako ordua#,
				'generic' => q#Aktauko ordua#,
				'standard' => q#Aktauko ordu estandarra#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Aktobeko udako ordua#,
				'generic' => q#Aktobeko ordua#,
				'standard' => q#Aktobeko ordu estandarra#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabiako udako ordua#,
				'generic' => q#Arabiako ordua#,
				'standard' => q#Arabiako ordu estandarra#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentinako udako ordua#,
				'generic' => q#Argentinako ordua#,
				'standard' => q#Argentinako ordu estandarra#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Argentina mendebaldeko udako ordua#,
				'generic' => q#Argentina mendebaldeko ordua#,
				'standard' => q#Argentina mendebaldeko ordu estandarra#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armeniako udako ordua#,
				'generic' => q#Armeniako ordua#,
				'standard' => q#Armeniako ordu estandarra#,
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
			exemplarCity => q#Asgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atyrau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrain#,
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
			exemplarCity => q#Beirut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bixkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkuta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Chita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Txoibalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasko#,
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
			exemplarCity => q#Duxanbe#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Famagusta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gaza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hong Kong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Khovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jerusalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtxatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karatxi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Khandiga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoiarsk#,
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
			exemplarCity => q#Macau#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makassar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manila#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Maskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosia#,
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
			exemplarCity => q#Piongiang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Qatar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Yangon#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Chi Minh#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sakhalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkanda#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shanghai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolimsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipei#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taxkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Ürümqi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vientian#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Erevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Ipar Amerikako Atlantikoko udako ordua#,
				'generic' => q#Ipar Amerikako Atlantikoko ordua#,
				'standard' => q#Ipar Amerikako Atlantikoko ordu estandarra#,
			},
			short => {
				'daylight' => q#ADT#,
				'generic' => q#AT#,
				'standard' => q#AST#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azoreak#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanariak#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cabo Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faroe#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#South Georgia#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Santa Helena#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stanley#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaide#,
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
				'daylight' => q#Australiako erdialdeko udako ordua#,
				'generic' => q#Australiako erdialdeko ordua#,
				'standard' => q#Australiako erdialdeko ordu estandarra#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Australiako erdi-mendebaldeko udako ordua#,
				'generic' => q#Australiako erdi-mendebaldeko ordua#,
				'standard' => q#Australiako erdi-mendebaldeko ordu estandarra#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Australiako ekialdeko udako ordua#,
				'generic' => q#Australiako ekialdeko ordua#,
				'standard' => q#Australiako ekialdeko ordu estandarra#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Australiako mendebaldeko udako ordua#,
				'generic' => q#Australiako mendebaldeko ordua#,
				'standard' => q#Australiako mendebaldeko ordu estandarra#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Azerbaijango udako ordua#,
				'generic' => q#Azerbaijango ordua#,
				'standard' => q#Azerbaijango ordu estandarra#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azoreetako udako ordua#,
				'generic' => q#Azoreetako ordua#,
				'standard' => q#Azoreetako ordu estandarra#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladesheko udako ordua#,
				'generic' => q#Bangladesheko ordua#,
				'standard' => q#Bangladesheko ordu estandarra#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Bhutango ordua#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Boliviako ordua#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasiliako udako ordua#,
				'generic' => q#Brasiliako ordua#,
				'standard' => q#Brasiliako ordu estandarra#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunei Darussalamgo ordua#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Cabo Verdeko udako ordua#,
				'generic' => q#Cabo Verdeko ordua#,
				'standard' => q#Cabo Verdeko ordu estandarra#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#Caseyko ordua#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorroko ordu estandarra#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chathamgo udako ordua#,
				'generic' => q#Chathamgo ordua#,
				'standard' => q#Chathamgo ordu estandarra#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Txileko udako ordua#,
				'generic' => q#Txileko ordua#,
				'standard' => q#Txileko ordu estandarra#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Txinako udako ordua#,
				'generic' => q#Txinako ordua#,
				'standard' => q#Txinako ordu estandarra#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Txoibalsango udako ordua#,
				'generic' => q#Txoibalsango ordua#,
				'standard' => q#Txoibalsango ordu estandarra#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Christmas uharteko ordua#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Cocos uharteetako ordua#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolonbiako udako ordua#,
				'generic' => q#Kolonbiako ordua#,
				'standard' => q#Kolonbiako ordu estandarra#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cook uharteetako uda erdialdeko ordua#,
				'generic' => q#Cook uharteetako ordua#,
				'standard' => q#Cook uharteetako ordu estandarra#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kubako udako ordua#,
				'generic' => q#Kubako ordua#,
				'standard' => q#Kubako ordu estandarra#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Daviseko ordua#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont-d’Urvilleko ordua#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Ekialdeko Timorreko ordua#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Pazko uharteko udako ordua#,
				'generic' => q#Pazko uharteko ordua#,
				'standard' => q#Pazko uharteko ordu estandarra#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ekuadorreko ordua#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#ordu unibertsal koordinatua#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Hiri ezezaguna#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrakhan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atenas#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brusela#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chisinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhage#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q#Irlandako ordu estandarra#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernesey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Man uhartea#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersey#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrad#,
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
			exemplarCity => q#Ljubljana#,
		},
		'Europe/London' => {
			exemplarCity => q#Londres#,
			long => {
				'daylight' => q#Londresko udako ordua#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxenburgo#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madril#,
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
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Mosku#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Paris#,
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
			exemplarCity => q#Erroma#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marino#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarajevo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratov#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferopol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofia#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stockholm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallinn#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulianovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uzhhorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikano Hiria#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viena#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
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
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Europako erdialdeko udako ordua#,
				'generic' => q#Europako erdialdeko ordua#,
				'standard' => q#Europako erdialdeko ordu estandarra#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Europako ekialdeko udako ordua#,
				'generic' => q#Europako ekialdeko ordua#,
				'standard' => q#Europako ekialdeko ordu estandarra#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Europako ekialde urruneko ordua#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Europako mendebaldeko udako ordua#,
				'generic' => q#Europako mendebaldeko ordua#,
				'standard' => q#Europako mendebaldeko ordu estandarra#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falkland uharteetako udako ordua#,
				'generic' => q#Falkland uharteetako ordua#,
				'standard' => q#Falkland uharteetako ordu estandarra#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fijiko udako ordua#,
				'generic' => q#Fijiko ordua#,
				'standard' => q#Fijiko ordu estandarra#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Guyana Frantseseko ordua#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Frantziaren lurralde austral eta antartikoetako ordutegia#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwichko meridianoaren ordua#,
			},
			short => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagoetako ordua#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambierretako ordua#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Georgiako udako ordua#,
				'generic' => q#Georgiako ordua#,
				'standard' => q#Georgiako ordu estandarra#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilbert uharteetako ordua#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Groenlandiako ekialdeko udako ordua#,
				'generic' => q#Groenlandiako ekialdeko ordua#,
				'standard' => q#Groenlandiako ekialdeko ordu estandarra#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Groenlandiako mendebaldeko udako ordua#,
				'generic' => q#Groenlandiako mendebaldeko ordua#,
				'standard' => q#Groenlandiako mendebaldeko ordu estandarra#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Guameko ordu estandarra#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Golkoko ordu estandarra#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyanako ordua#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaii-Aleutiar uharteetako udako ordua#,
				'generic' => q#Hawaii-Aleutiar uharteetako ordua#,
				'standard' => q#Hawaii-Aleutiar uharteetako ordu estandarra#,
			},
			short => {
				'daylight' => q#HADT#,
				'generic' => q#HAT#,
				'standard' => q#HAST#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hong Kongo udako ordua#,
				'generic' => q#Hong Kongo ordua#,
				'standard' => q#Hong Kongo ordu estandarra#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Khovdeko udako ordua#,
				'generic' => q#Khovdeko ordua#,
				'standard' => q#Khovdeko ordu estandarra#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Indiako ordua#,
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
			exemplarCity => q#Mahé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivak#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Maurizio#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indiako Ozeanoko ordua#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indotxinako ordua#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Indonesiako erdialdeko ordua#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Indonesiako ekialdeko ordua#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Indonesiako mendebaldeko ordua#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Irango udako ordua#,
				'generic' => q#Irango ordua#,
				'standard' => q#Irango ordu estandarra#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutskeko udako ordua#,
				'generic' => q#Irkutskeko ordua#,
				'standard' => q#Irkutskeko ordu estandarra#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israelgo udako ordua#,
				'generic' => q#Israelgo ordua#,
				'standard' => q#Israelgo ordu estandarra#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japoniako udako ordua#,
				'generic' => q#Japoniako ordua#,
				'standard' => q#Japoniako ordu estandarra#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Petropavlovsk-Kamchatskiko udako ordua#,
				'generic' => q#Petropavlovsk-Kamchatskiko ordua#,
				'standard' => q#Petropavlovsk-Kamchatskiko ordu estandarra#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Kazakhstango ekialdeko ordua#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Kazakhstango mendebaldeko ordua#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Koreako udako ordua#,
				'generic' => q#Koreako ordua#,
				'standard' => q#Koreako ordu estandarra#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosraeko ordua#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnoiarskeko udako ordua#,
				'generic' => q#Krasnoiarskeko ordua#,
				'standard' => q#Krasnoiarskeko ordu estandarra#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgizistango ordua#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Line uharteetako ordua#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord Howeko udako ordua#,
				'generic' => q#Lord Howeko ordua#,
				'standard' => q#Lord Howeko ordu estandarra#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Macquarie uharteko ordua#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadango udako ordua#,
				'generic' => q#Magadango ordua#,
				'standard' => q#Magadango ordu estandarra#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malaysiako ordua#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldivetako ordua#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Markesetako ordua#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marshall Uharteetako ordua#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Maurizioko udako ordua#,
				'generic' => q#Maurizioko ordua#,
				'standard' => q#Maurizioko ordu estandarra#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawsoneko ordua#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Mexikoko ipar-ekialdeko udako ordua#,
				'generic' => q#Mexikoko ipar-ekialdeko ordua#,
				'standard' => q#Mexikoko ipar-ekialdeko ordu estandarra#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Mexikoko Pazifikoko udako ordua#,
				'generic' => q#Mexikoko Pazifikoko ordua#,
				'standard' => q#Mexikoko Pazifikoko ordu estandarra#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulan Batorreko udako ordua#,
				'generic' => q#Ulan Batorreko ordua#,
				'standard' => q#Ulan Batorreko ordu estandarra#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskuko udako ordua#,
				'generic' => q#Moskuko ordua#,
				'standard' => q#Moskuko ordu estandarra#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Myanmarreko ordua#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauruko ordua#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepalgo ordua#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Kaledonia Berriko udako ordua#,
				'generic' => q#Kaledonia Berriko ordua#,
				'standard' => q#Kaledonia Berriko ordu estandarra#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Zeelanda Berriko udako ordua#,
				'generic' => q#Zeelanda Berriko ordua#,
				'standard' => q#Zeelanda Berriko ordu estandarra#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Ternuako udako ordua#,
				'generic' => q#Ternuako ordua#,
				'standard' => q#Ternuako ordu estandarra#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niueko ordua#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Norfolk uharteetako udako ordua#,
				'generic' => q#Norfolk uharteetako ordua#,
				'standard' => q#Norfolk uharteetako ordu estandarra#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando de Noronhako udako ordua#,
				'generic' => q#Fernando de Noronhako ordua#,
				'standard' => q#Fernando de Noronhako ordu estandarra#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Ipar Mariana uharteetako ordua#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibirskeko udako ordua#,
				'generic' => q#Novosibirskeko ordua#,
				'standard' => q#Novosibirskeko ordu estandarra#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omskeko udako ordua#,
				'generic' => q#Omskeko ordua#,
				'standard' => q#Omskeko ordu estandarra#,
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
			exemplarCity => q#Pazko uhartea#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Éfaté#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
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
			exemplarCity => q#Galapagoak#,
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
			exemplarCity => q#Markesak#,
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
			exemplarCity => q#Nouméa#,
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
				'daylight' => q#Pakistango udako ordua#,
				'generic' => q#Pakistango ordua#,
				'standard' => q#Pakistango ordu estandarra#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palauko ordua#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua Ginea Berriko ordua#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguaiko udako ordua#,
				'generic' => q#Paraguaiko ordua#,
				'standard' => q#Paraguaiko ordu estandarra#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peruko udako ordua#,
				'generic' => q#Peruko ordua#,
				'standard' => q#Peruko ordu estandarra#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Filipinetako udako ordua#,
				'generic' => q#Filipinetako ordua#,
				'standard' => q#Filipinetako ordu estandarra#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Phoenix uharteetako ordua#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Saint-Pierre eta Mikeluneko udako ordua#,
				'generic' => q#Saint-Pierre eta Mikeluneko ordua#,
				'standard' => q#Saint-Pierre eta Mikeluneko ordu estandarra#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairneko ordua#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponapeko ordua#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Piongiangeko ordua#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Kyzylordako udako ordua#,
				'generic' => q#Kyzylordako ordua#,
				'standard' => q#Kyzylordako ordu estandarra#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Reunioneko ordua#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rotherako ordua#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sakhalingo udako ordua#,
				'generic' => q#Sakhalingo ordua#,
				'standard' => q#Sakhalingo ordu estandarra#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samarako udako ordua#,
				'generic' => q#Samarako ordua#,
				'standard' => q#Samarako ordu estandarra#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoako udako ordua#,
				'generic' => q#Samoako ordua#,
				'standard' => q#Samoako ordu estandarra#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seychelle uharteetako ordua#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapurreko ordu estandarra#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Salomon Uharteetako ordua#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Hegoaldeko Georgietako ordua#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Surinamgo ordua#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowako ordua#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahitiko ordua#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipeiko udako ordua#,
				'generic' => q#Taipeiko ordua#,
				'standard' => q#Taipeiko ordu estandarra#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadjikistango ordua#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelauko ordua#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tongako udako ordua#,
				'generic' => q#Tongako ordua#,
				'standard' => q#Tongako ordu estandarra#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuukeko ordua#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmenistango udako ordua#,
				'generic' => q#Turkmenistango ordua#,
				'standard' => q#Turkmenistango ordu estandarra#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvaluko ordua#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguaiko udako ordua#,
				'generic' => q#Uruguaiko ordua#,
				'standard' => q#Uruguaiko ordu estandarra#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Uzbekistango udako ordua#,
				'generic' => q#Uzbekistango ordua#,
				'standard' => q#Uzbekistango ordu estandarra#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatuko udako ordua#,
				'generic' => q#Vanuatuko ordua#,
				'standard' => q#Vanuatuko ordu estandarra#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venezuelako ordua#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostokeko udako ordua#,
				'generic' => q#Vladivostokeko ordua#,
				'standard' => q#Vladivostokeko ordu estandarra#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volgogradeko udako ordua#,
				'generic' => q#Volgogradeko ordua#,
				'standard' => q#Volgogradeko ordu estandarra#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vostokeko ordua#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wake uharteko ordua#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis eta Futunako ordutegia#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakutskeko udako ordua#,
				'generic' => q#Jakutskeko ordua#,
				'standard' => q#Jakutskeko ordu estandarra#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinburgeko udako ordua#,
				'generic' => q#Jekaterinburgeko ordua#,
				'standard' => q#Jekaterinburgeko ordu estandarra#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Yukongo ordua#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
