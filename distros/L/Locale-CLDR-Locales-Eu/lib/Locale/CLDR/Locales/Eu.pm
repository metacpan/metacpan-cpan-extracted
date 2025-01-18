=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Eu - Package for language Basque

=cut

package Locale::CLDR::Locales::Eu;
# This file auto generated from Data\common\main\eu.xml
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
				'aa' => 'afarera',
 				'ab' => 'abkhaziera',
 				'ace' => 'acehnera',
 				'ach' => 'acholiera',
 				'ada' => 'adangmera',
 				'ady' => 'adigera',
 				'af' => 'afrikaansa',
 				'agq' => 'aghemera',
 				'ain' => 'ainuera',
 				'ak' => 'akanera',
 				'ale' => 'aleutera',
 				'alt' => 'hegoaldeko altaiera',
 				'am' => 'amharera',
 				'an' => 'aragoiera',
 				'ann' => 'oboloera',
 				'anp' => 'angikera',
 				'ar' => 'arabiera',
 				'ar_001' => 'arabiera moderno estandarra',
 				'arn' => 'mapudunguna',
 				'arp' => 'arapahoera',
 				'ars' => 'Najdeko arabiera',
 				'as' => 'assamera',
 				'asa' => 'asua',
 				'ast' => 'asturiera',
 				'atj' => 'atikamekwera',
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
 				'bgc' => 'haryanera',
 				'bho' => 'bhojpurera',
 				'bi' => 'bislama',
 				'bin' => 'edoera',
 				'bla' => 'siksikera',
 				'blo' => 'aniiera',
 				'bm' => 'bambarera',
 				'bn' => 'bengalera',
 				'bo' => 'tibetera',
 				'br' => 'bretoiera',
 				'brx' => 'bodoera',
 				'bs' => 'bosniera',
 				'bug' => 'buginera',
 				'byn' => 'bilenera',
 				'ca' => 'katalana',
 				'cay' => 'cayugera',
 				'ccp' => 'chakmera',
 				'ce' => 'txetxenera',
 				'ceb' => 'cebuanoera',
 				'cgg' => 'chiga',
 				'ch' => 'txamorroera',
 				'chk' => 'chuukera',
 				'chm' => 'mariera',
 				'cho' => 'txoktawera',
 				'chp' => 'chipewyera',
 				'chr' => 'txerokiera',
 				'chy' => 'txeieneera',
 				'ckb' => 'erdialdeko kurduera',
 				'clc' => 'chilcotinera',
 				'co' => 'korsikera',
 				'crg' => 'metisera',
 				'crj' => 'hego-ekialdeko creera',
 				'crk' => 'lautadetako creera',
 				'crl' => 'ipar-ekialdeko creera',
 				'crm' => 'Mooseko creera',
 				'crr' => 'Carolinako algonkinera',
 				'crs' => 'Seychelleetako kreolera',
 				'cs' => 'txekiera',
 				'csw' => 'zingiretako creera',
 				'cu' => 'elizako eslaviera',
 				'cv' => 'txuvaxera',
 				'cy' => 'galesa',
 				'da' => 'daniera',
 				'dak' => 'dakotera',
 				'dar' => 'darginera',
 				'dav' => 'taitera',
 				'de' => 'alemana',
 				'de_AT' => 'Austriako alemana',
 				'de_CH' => 'Suitzako aleman garaia',
 				'dgr' => 'dogribera',
 				'dje' => 'zarma',
 				'doi' => 'dogria',
 				'dsb' => 'behe-sorabiera',
 				'dua' => 'dualera',
 				'dv' => 'dhivehia',
 				'dyo' => 'fonyi jolera',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazaera',
 				'ebu' => 'embuera',
 				'ee' => 'eweera',
 				'efi' => 'efikera',
 				'eka' => 'ekajuka',
 				'el' => 'greziera',
 				'en' => 'ingelesa',
 				'en_AU' => 'Australiako ingelesa',
 				'en_CA' => 'Kanadako ingelesa',
 				'en_GB' => 'Britainia Handiko ingelesa',
 				'en_GB@alt=short' => 'Erresuma Batuko ingelesa',
 				'en_US' => 'ingeles amerikarra',
 				'en_US@alt=short' => 'AEBko ingelesa',
 				'eo' => 'esperantoa',
 				'es' => 'gaztelania',
 				'es_419' => 'Latinoamerikako gaztelania',
 				'es_ES' => 'Europako gaztelania',
 				'es_MX' => 'Mexikoko gaztelania',
 				'et' => 'estoniera',
 				'eu' => 'euskara',
 				'ewo' => 'ewondoa',
 				'fa' => 'persiera',
 				'fa_AF' => 'daria',
 				'ff' => 'fula',
 				'fi' => 'finlandiera',
 				'fil' => 'filipinera',
 				'fj' => 'fijiera',
 				'fo' => 'faroera',
 				'fon' => 'fonera',
 				'fr' => 'frantsesa',
 				'fr_CA' => 'Kanadako frantsesa',
 				'fr_CH' => 'Suitzako frantsesa',
 				'frc' => 'cajun frantsesa',
 				'frr' => 'iparraldeko frisiera',
 				'fur' => 'friulera',
 				'fy' => 'mendebaldeko frisiera',
 				'ga' => 'irlandera',
 				'gaa' => 'gaera',
 				'gag' => 'gagauzera',
 				'gd' => 'Eskoziako gaelikoa',
 				'gez' => 'ge’eza',
 				'gil' => 'kiribatiera',
 				'gl' => 'galiziera',
 				'gn' => 'guaraniera',
 				'gor' => 'gorontaloera',
 				'gsw' => 'Suitzako alemana',
 				'gu' => 'gujaratera',
 				'guz' => 'gusiiera',
 				'gv' => 'manxera',
 				'gwi' => 'gwich’inera',
 				'ha' => 'hausa',
 				'hai' => 'haidera',
 				'haw' => 'hawaiiera',
 				'hax' => 'hegoaldeko haidera',
 				'he' => 'hebreera',
 				'hi' => 'hindia',
 				'hi_Latn' => 'hindia (latindarra)',
 				'hi_Latn@alt=variant' => 'hinglisha',
 				'hil' => 'hiligaynonera',
 				'hmn' => 'hmonga',
 				'hr' => 'kroaziera',
 				'hsb' => 'goi-sorabiera',
 				'ht' => 'Haitiko kreolera',
 				'hu' => 'hungariera',
 				'hup' => 'hupera',
 				'hur' => 'halkomelema',
 				'hy' => 'armeniera',
 				'hz' => 'hereroera',
 				'ia' => 'interlingua',
 				'iba' => 'ibanera',
 				'ibb' => 'ibibioera',
 				'id' => 'indonesiera',
 				'ie' => 'interlinguea',
 				'ig' => 'igboera',
 				'ii' => 'Sichuango yiera',
 				'ikt' => 'Kanada mendebaldeko inuitera',
 				'ilo' => 'ilocanoera',
 				'inh' => 'ingushera',
 				'io' => 'idoa',
 				'is' => 'islandiera',
 				'it' => 'italiera',
 				'iu' => 'inuitera',
 				'ja' => 'japoniera',
 				'jbo' => 'lojbana',
 				'jgo' => 'ngomba',
 				'jmc' => 'machamea',
 				'jv' => 'javera',
 				'ka' => 'georgiera',
 				'kab' => 'kabiliera',
 				'kac' => 'jingphoera',
 				'kaj' => 'jjua',
 				'kam' => 'kambera',
 				'kbd' => 'kabardiera',
 				'kcg' => 'tyapa',
 				'kde' => 'makondeera',
 				'kea' => 'Cabo Verdeko kreolera',
 				'kfo' => 'koroa',
 				'kg' => 'kikongoa',
 				'kgp' => 'kaingangera',
 				'kha' => 'khasiera',
 				'khq' => 'koyra chiinia',
 				'ki' => 'kikuyuera',
 				'kj' => 'kuanyama',
 				'kk' => 'kazakhera',
 				'kkj' => 'kakoa',
 				'kl' => 'groenlandiera',
 				'kln' => 'kalenjinera',
 				'km' => 'khemerera',
 				'kmb' => 'kimbundua',
 				'kn' => 'kannada',
 				'ko' => 'koreera',
 				'koi' => 'komi-permyakera',
 				'kok' => 'konkanera',
 				'kpe' => 'kpelleera',
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
 				'kwk' => 'kwakwala',
 				'kxv' => 'kuvia',
 				'ky' => 'kirgizera',
 				'la' => 'latina',
 				'lad' => 'ladinoa',
 				'lag' => 'langiera',
 				'lb' => 'luxenburgera',
 				'lez' => 'lezginera',
 				'lg' => 'luganda',
 				'li' => 'limburgera',
 				'lij' => 'liguriera',
 				'lil' => 'lillooetera',
 				'lkt' => 'lakotera',
 				'lmo' => 'lombardiera',
 				'ln' => 'lingala',
 				'lo' => 'laosera',
 				'lou' => 'Louisianako kreolera',
 				'loz' => 'loziera',
 				'lrc' => 'iparraldeko lurera',
 				'lsm' => 'saamia',
 				'lt' => 'lituaniera',
 				'lu' => 'Katangako lubera',
 				'lua' => 'Kasai mendebaldeko lubera',
 				'lun' => 'lundera',
 				'luo' => 'luoera',
 				'lus' => 'mizoera',
 				'luy' => 'luhyera',
 				'lv' => 'letoniera',
 				'mad' => 'madurera',
 				'mag' => 'magadhera',
 				'mai' => 'maithilia',
 				'mak' => 'makassarera',
 				'mas' => 'masaiera',
 				'mdf' => 'mokxera',
 				'men' => 'mendeera',
 				'mer' => 'meruera',
 				'mfe' => 'Mauritaniako kreolera',
 				'mg' => 'malgaxea',
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
 				'moe' => 'innuera',
 				'moh' => 'mohawkera',
 				'mos' => 'mossiera',
 				'mr' => 'marathera',
 				'ms' => 'malaysiera',
 				'mt' => 'maltera',
 				'mua' => 'mudangera',
 				'mul' => 'zenbait hizkuntza',
 				'mus' => 'muscogeera',
 				'mwl' => 'mirandesa',
 				'my' => 'birmaniera',
 				'myv' => 'erziera',
 				'mzn' => 'mazandarandera',
 				'na' => 'nauruera',
 				'nap' => 'napoliera',
 				'naq' => 'namera',
 				'nb' => 'bokmål (norvegiera)',
 				'nd' => 'iparraldeko ndebeleera',
 				'nds' => 'behe-alemana',
 				'nds_NL' => 'behe-saxoiera',
 				'ne' => 'nepalera',
 				'new' => 'newarera',
 				'ng' => 'ndonga',
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
 				'nr' => 'hegoaldeko ndebeleera',
 				'nso' => 'pediera',
 				'nus' => 'nuerera',
 				'nv' => 'navajoera',
 				'ny' => 'chewera',
 				'nyn' => 'nkoreera',
 				'oc' => 'okzitaniera',
 				'ojb' => 'ipar-mendebaldeko ojibwa',
 				'ojc' => 'erdialdeko ojibwa',
 				'ojs' => 'oji-creera',
 				'ojw' => 'mendebaldeko ojibwa',
 				'oka' => 'okanaganera',
 				'om' => 'oromoera',
 				'or' => 'oriya',
 				'os' => 'osetiera',
 				'pa' => 'punjabera',
 				'pag' => 'pangasinanera',
 				'pam' => 'pampangera',
 				'pap' => 'papiamentoa',
 				'pau' => 'palauera',
 				'pcm' => 'Nigeriako pidgina',
 				'pis' => 'pijina',
 				'pl' => 'poloniera',
 				'pqm' => 'maliseet-passamaquoddyera',
 				'prg' => 'prusiera',
 				'ps' => 'paxtunera',
 				'pt' => 'portugesa',
 				'pt_BR' => 'Brasilgo portugesa',
 				'pt_PT' => 'Europako portugesa',
 				'qu' => 'kitxua',
 				'quc' => 'quicheera',
 				'raj' => 'rajastanera',
 				'rap' => 'rapanuia',
 				'rar' => 'rarotongera',
 				'rhg' => 'rohingyera',
 				'rm' => 'erretorromaniera',
 				'rn' => 'rundiera',
 				'ro' => 'errumaniera',
 				'ro_MD' => 'moldaviera',
 				'rof' => 'romboa',
 				'ru' => 'errusiera',
 				'rup' => 'aromaniera',
 				'rw' => 'kinyaruanda',
 				'rwk' => 'rwera',
 				'sa' => 'sanskritoa',
 				'sad' => 'sandaweera',
 				'sah' => 'sakhera',
 				'saq' => 'samburuera',
 				'sat' => 'santalera',
 				'sba' => 'ngambayera',
 				'sbp' => 'sanguera',
 				'sc' => 'sardiniera',
 				'scn' => 'siziliera',
 				'sco' => 'eskoziera',
 				'sd' => 'sindhia',
 				'se' => 'iparraldeko samiera',
 				'seh' => 'senera',
 				'ses' => 'koyraboro sennia',
 				'sg' => 'sangoa',
 				'sh' => 'serbokroaziera',
 				'shi' => 'tachelhita',
 				'shn' => 'shanera',
 				'si' => 'sinhala',
 				'sk' => 'eslovakiera',
 				'sl' => 'esloveniera',
 				'slh' => 'lushootseeda',
 				'sm' => 'samoera',
 				'sma' => 'hegoaldeko samiera',
 				'smj' => 'Luleko samiera',
 				'smn' => 'Inariko samiera',
 				'sms' => 'skolten samiera',
 				'sn' => 'shonera',
 				'snk' => 'soninkeera',
 				'so' => 'somaliera',
 				'sq' => 'albaniera',
 				'sr' => 'serbiera',
 				'srn' => 'sranan tongoa',
 				'ss' => 'swatiera',
 				'ssy' => 'sahoa',
 				'st' => 'hegoaldeko sothoera',
 				'str' => 'itsasarteetako salishera',
 				'su' => 'sundanera',
 				'suk' => 'sukumera',
 				'sv' => 'suediera',
 				'sw' => 'swahilia',
 				'sw_CD' => 'Kongoko swahilia',
 				'swb' => 'komoreera',
 				'syr' => 'asiriera',
 				'szl' => 'silesiera',
 				'ta' => 'tamilera',
 				'tce' => 'hegoaldeko tutchoneera',
 				'te' => 'telugua',
 				'tem' => 'temneera',
 				'teo' => 'tesoera',
 				'tet' => 'tetuma',
 				'tg' => 'tajikera',
 				'tgx' => 'tagishera',
 				'th' => 'thailandiera',
 				'tht' => 'tahltanera',
 				'ti' => 'tigrinyera',
 				'tig' => 'tigreera',
 				'tk' => 'turkmenera',
 				'tl' => 'tagaloa',
 				'tlh' => 'klingonera',
 				'tli' => 'tlingitera',
 				'tn' => 'tswanera',
 				'to' => 'tongera',
 				'tok' => 'toki pona',
 				'tpi' => 'tok pisin',
 				'tr' => 'turkiera',
 				'trv' => 'tarokoera',
 				'ts' => 'tsongera',
 				'tt' => 'tatarera',
 				'ttm' => 'iparraldeko tutchoneera',
 				'tum' => 'tumbukera',
 				'tvl' => 'tuvaluera',
 				'tw' => 'twia',
 				'twq' => 'tasawaqa',
 				'ty' => 'tahitiera',
 				'tyv' => 'tuvera',
 				'tzm' => 'Erdialdeko Atlaseko amazigera',
 				'udm' => 'udmurtera',
 				'ug' => 'uigurrera',
 				'uk' => 'ukrainera',
 				'umb' => 'umbundua',
 				'und' => 'hizkuntza ezezaguna',
 				'ur' => 'urdua',
 				'uz' => 'uzbekera',
 				'vai' => 'vaiera',
 				've' => 'vendera',
 				'vec' => 'veneziera',
 				'vi' => 'vietnamera',
 				'vmw' => 'makhuwera',
 				'vo' => 'volapük',
 				'vun' => 'vunjoa',
 				'wa' => 'valoniera',
 				'wae' => 'walserera',
 				'wal' => 'wolayttera',
 				'war' => 'warayera',
 				'wo' => 'wolofera',
 				'wuu' => 'wu txinera',
 				'xal' => 'kalmykera',
 				'xh' => 'xhosera',
 				'xnr' => 'kangrera',
 				'xog' => 'sogera',
 				'yav' => 'yangbenera',
 				'ybb' => 'yemba',
 				'yi' => 'yiddisha',
 				'yo' => 'jorubera',
 				'yrl' => 'nheengatua',
 				'yue' => 'kantonera',
 				'yue@alt=menu' => 'Kantongo txinera',
 				'za' => 'zhuangera',
 				'zgh' => 'amazigera estandarra',
 				'zh' => 'txinera',
 				'zh@alt=menu' => 'mandarina',
 				'zh_Hans' => 'txinera sinplifikatua',
 				'zh_Hans@alt=long' => 'mandarin sinplifikatua',
 				'zh_Hant' => 'txinera tradizionala',
 				'zh_Hant@alt=long' => 'mandarin tradizionala',
 				'zu' => 'zuluera',
 				'zun' => 'zuñiera',
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
			'Adlm' => 'adlama',
 			'Aghb' => 'Kaukasoko albaniera',
 			'Ahom' => 'ahomera',
 			'Arab' => 'arabiarra',
 			'Arab@alt=variant' => 'persiar-arabiarra',
 			'Aran' => 'nastaliqa',
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
 			'Cans' => 'Kanadako aborigenen silabario bateratua',
 			'Cari' => 'kariera',
 			'Cham' => 'txamera',
 			'Cher' => 'txerokiarra',
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
 			'Hanb' => 'idazkera txinatarra bopomofoarekin',
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
 			'Jamo' => 'jamoa',
 			'Java' => 'javaniera',
 			'Jpan' => 'japoniarra',
 			'Kali' => 'kayah li',
 			'Kana' => 'katakana',
 			'Kawi' => 'kawi',
 			'Khar' => 'kharoshthi',
 			'Khmr' => 'khmertarra',
 			'Khoj' => 'khojkiera',
 			'Kits' => 'khitanerako script txikiak',
 			'Knda' => 'kanadarra',
 			'Kore' => 'korearra',
 			'Kthi' => 'kaithiera',
 			'Lana' => 'lannera',
 			'Laoo' => 'laostarra',
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
 			'Mlym' => 'malabartarra',
 			'Modi' => 'modiera',
 			'Mong' => 'mongoliarra',
 			'Mroo' => 'mroera',
 			'Mtei' => 'meiteiarra',
 			'Mult' => 'multaniera',
 			'Mymr' => 'birmaniarra',
 			'Nagm' => 'nag mundariera',
 			'Nand' => 'nandinagariera',
 			'Narb' => 'iparraldeko arabiera zaharra',
 			'Nbat' => 'nabatera',
 			'Newa' => 'newaera',
 			'Nkoo' => 'n’koa',
 			'Nshu' => 'nushuera',
 			'Ogam' => 'oghamera',
 			'Olck' => 'ol chikia',
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
 			'Rohg' => 'hanifia',
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
 			'Sund' => 'sudandarra',
 			'Sylo' => 'syloti nagriera',
 			'Syrc' => 'asiriarra',
 			'Tagb' => 'tagbanwa',
 			'Takr' => 'takriera',
 			'Tale' => 'tai le',
 			'Talu' => 'tai lue berria',
 			'Taml' => 'tamildarra',
 			'Tang' => 'tangutera',
 			'Tavt' => 'tai viet',
 			'Telu' => 'teluguarra',
 			'Tfng' => 'tifinagha',
 			'Tglg' => 'tagaloa',
 			'Thaa' => 'thaana',
 			'Thai' => 'thailandiarra',
 			'Tibt' => 'tibetarra',
 			'Tirh' => 'tirhuta',
 			'Tnsa' => 'tangsa',
 			'Toto' => 'totoera',
 			'Ugar' => 'ugaritiera',
 			'Vaii' => 'vaiarra',
 			'Vith' => 'vithkuqi',
 			'Wara' => 'varang kshiti',
 			'Wcho' => 'wanchoera',
 			'Xpeo' => 'pertsiera zaharra',
 			'Xsux' => 'sumero-akadiera kuneiformea',
 			'Yezi' => 'yezidiera',
 			'Yiii' => 'yiarra',
 			'Zanb' => 'zanabazar koadroa',
 			'Zinh' => 'heredatua',
 			'Zmth' => 'matematikako notazioa',
 			'Zsye' => 'emojiak',
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
 			'011' => 'Mendebaldeko Afrika',
 			'013' => 'Erdialdeko Amerika',
 			'014' => 'Ekialdeko Afrika',
 			'015' => 'Ipar Afrika',
 			'017' => 'Erdialdeko Afrika',
 			'018' => 'Hegoaldeko Afrika',
 			'019' => 'Amerika',
 			'021' => 'Amerikako iparraldea',
 			'029' => 'Karibea',
 			'030' => 'Ekialdeko Asia',
 			'034' => 'Hego Asia',
 			'035' => 'Hego-ekialdeko Asia',
 			'039' => 'Hego Europa',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Mikronesia eskualdea',
 			'061' => 'Polinesia',
 			'142' => 'Asia',
 			'143' => 'Erdialdeko Asia',
 			'145' => 'Mendebaldeko Asia',
 			'150' => 'Europa',
 			'151' => 'Ekialdeko Europa',
 			'154' => 'Ipar Europa',
 			'155' => 'Mendebaldeko Europa',
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
 			'IO@alt=chagos' => 'Txagos uhartedia',
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
 			'NZ@alt=variant' => 'Aotearoa / Zeelanda Berria',
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
 			'ARANES' => 'Aranera',
 			'ARKAIKA' => 'Esperanto arkaikoa',
 			'ASANTE' => 'ASANTEERA',
 			'AUVERN' => 'Auverniako okzitaniera',
 			'BAKU1926' => 'Turkieraren latindar alfabeto bateratua',
 			'BALANKA' => 'Aniieraren balanka dialektoa',
 			'BARLA' => 'Caboverdeeraren barlavento dialekto taldea',
 			'BASICENG' => 'Oinarrizko ingelesa',
 			'BAUDDHA' => 'Bauddha',
 			'BISCAYAN' => 'Mendebaldeko euskara',
 			'BISKE' => 'San Giorgio / Bila dialektoa',
 			'BOHORIC' => 'Bohoric alfabetoa',
 			'BOONT' => 'Boontling',
 			'BORNHOLM' => 'Bornholmera',
 			'CISAUP' => 'galiar-italiarra',
 			'COLB1945' => '1945eko Portugal eta Barasilgo ortografia-hitzarmena',
 			'CORNU' => 'cornishera',
 			'CREISS' => 'Languedocera',
 			'DAJNKO' => 'Dajnko alfabetoa',
 			'EKAVSK' => 'Serbiera ekavierako ahoskerarekin',
 			'EMODENG' => 'Ingeles moderno goiztiarra',
 			'FONIPA' => 'IPA ahoskera',
 			'FONKIRSH' => 'Fonkirsh',
 			'FONNAPA' => 'Fonnapa',
 			'FONUPA' => 'UPa ahoskera',
 			'FONXSAMP' => 'Fonxsamp',
 			'GALLO' => 'Galiera',
 			'GASCON' => 'GASKOI',
 			'GRCLASS' => 'Okzitaniera klasikoa',
 			'GRITAL' => 'Grital',
 			'GRMISTR' => 'Grmistr',
 			'HEPBURN' => 'Hepburn erromanizazioa',
 			'HOGNORSK' => 'Hognorsk',
 			'HSISTEMO' => 'Hsistemo',
 			'IJEKAVSK' => 'Serbiera ijekavieraren ahoskerarekin',
 			'ITIHASA' => 'Itihasa',
 			'IVANCHOV' => 'Ivantxov',
 			'JAUER' => 'Jauer',
 			'JYUTPING' => 'Jyutping',
 			'KKCOR' => 'Ortografia arrunta',
 			'KOCIEWIE' => 'Kociewie',
 			'KSCOR' => 'Ortografia estandarra',
 			'LAUKIKA' => 'Laukika',
 			'LEMOSIN' => 'Limousinera',
 			'LENGADOC' => 'Lengadocera',
 			'LIPAW' => 'Resiako lipovaz dialektoa',
 			'LUNA1918' => 'Luna1918',
 			'METELKO' => 'Metelko alfabetoa',
 			'MONOTON' => 'Tonu bakarra',
 			'NDYUKA' => 'Ndyuka dialektoa',
 			'NEDIS' => 'Natisoneko dialektoa',
 			'NEWFOUND' => 'TERNUA',
 			'NICARD' => 'Nicard',
 			'NJIVA' => 'Gniva/Njiva dialektoa',
 			'NULIK' => 'Volapuk modernoa',
 			'OSOJS' => 'Oseacco/Osojane dialektoa',
 			'OXENDICT' => 'Oxfordeko ingeles-hiztegiko ortografia',
 			'PAHAWH2' => 'Pahawh2',
 			'PAHAWH3' => 'Pahawh3',
 			'PAHAWH4' => 'Pahawh4',
 			'PAMAKA' => 'Pamaka dialektoa',
 			'PEANO' => 'Peano',
 			'PETR1708' => 'Petr1708',
 			'PINYIN' => 'Pinyin erromanizazioa',
 			'POLYTON' => 'Tonu anitza',
 			'POSIX' => 'Ordenagailua',
 			'PROVENC' => 'Proventzera',
 			'PUTER' => 'Puterera',
 			'REVISED' => 'Ortografia berrikusia',
 			'RIGIK' => 'Volapuk klasikoa',
 			'ROZAJ' => 'Resiera',
 			'RUMGR' => 'Rumgr',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Eskoziar ingeles estandarra',
 			'SCOUSE' => 'Scouse',
 			'SIMPLE' => 'SOILA',
 			'SOLBA' => 'Stolvizza/Solbica dialektoa',
 			'SOTAV' => 'Caboverdeerako sotavento dialekto taldea',
 			'SPANGLIS' => 'SPANGLISH',
 			'SURMIRAN' => 'Surmiran',
 			'SURSILV' => 'Sursilv',
 			'SUTSILV' => 'Sutsilv',
 			'SYNNEJYL' => 'Synnejyl',
 			'TARASK' => 'Taraskievica ortografia',
 			'TONGYONG' => 'Tongyong',
 			'TUNUMIIT' => 'Tunumiit',
 			'UCCOR' => 'Ortografia bateratua',
 			'UCRCOR' => 'Ortografia berrikusi bateratua',
 			'ULSTER' => 'Ulster',
 			'UNIFON' => 'Alfabeto fonetiko unifonoa',
 			'VAIDIKA' => 'Vaidika',
 			'VALENCIA' => 'Valentziera',
 			'VALLADER' => 'Vallader',
 			'VECDRUKA' => 'Vecdruka',
 			'VIVARAUP' => 'Vivaraup',
 			'WADEGILE' => 'Wade-Giles erromanizazioa',
 			'XSISTEMO' => 'Xsistemo',

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
 				'coptic' => q{Egutegi koptoa},
 				'dangi' => q{Dangi egutegia},
 				'ethiopic' => q{Egutegi etiopiarra},
 				'ethiopic-amete-alem' => q{Amete Alem egutegi etiopiarra},
 				'gregorian' => q{Egutegi gregoriarra},
 				'hebrew' => q{Hebrear egutegia},
 				'indian' => q{Indiar egutegia},
 				'islamic' => q{Egutegi islamiarra},
 				'islamic-civil' => q{Egutegi islamiarra (taula-formakoa, garai zibilekoa)},
 				'islamic-rgsa' => q{Islamiar egutegia (Saudi Arabia, ikuspegiak)},
 				'islamic-tbla' => q{Islamiar egutegia (taula-formakoa, gai astronomikokoa)},
 				'islamic-umalqura' => q{Egutegi islamiarra (Umm al-Qura)},
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
 				'kawi' => q{kawi digituak},
 				'khmr' => q{Digitu khmertarrak},
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
 				'mlym' => q{Digitu malabartarrak},
 				'modi' => q{Modi digituak},
 				'mong' => q{Digitu mongoliarrak},
 				'mroo' => q{Mro digituak},
 				'mtei' => q{Meetei Mayek digituak},
 				'mymr' => q{Digitu birmaniarrak},
 				'mymrshan' => q{Shan digitu birmaniarrak},
 				'mymrtlng' => q{Tai Laing digitu birmaniarrak},
 				'nagm' => q{nag mundari digituak},
 				'native' => q{Digitu natiboak},
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
 				'taml' => q{Zenbaki tamildar tradizionalak},
 				'tamldec' => q{Digitu tamildarrak},
 				'telu' => q{Digitu teluguarrak},
 				'thai' => q{Digitu thailandiarrak},
 				'tibt' => q{Digitu tibetarrak},
 				'tirh' => q{Tirhuta digituak},
 				'tnsa' => q{tangsar digituak},
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

has 'characters' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> $^V ge v5.18.0
	? eval <<'EOT'
	sub {
		no warnings 'experimental::regex_sets';
		return {
			auxiliary => qr{[áàăâåäãā æ éèĕêëē íìĭîïī óòŏôöøō œ úùŭûüū ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a b cç d e f g h i j k l m nñ o p q r s t u v w x y z]},
			numbers => qr{[, . % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
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
			'word-final' => '{0}…',
		};
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
						'1' => q(kekto{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(kekto{0}),
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
						'name' => q(birak),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(birak),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0} hektarea),
						'other' => q({0} hektarea),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0} hektarea),
						'other' => q({0} hektarea),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'one' => q({0} zentimetro karratu),
						'other' => q({0} zentimetro karratu),
						'per' => q({0} zentimetro karratu bakoitzeko),
					},
					# Core Unit Identifier
					'square-centimeter' => {
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
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(hazbete karratu),
						'one' => q({0} hazbete karratu),
						'other' => q({0} hazbete karratu),
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
						'one' => q({0} milia karratu),
						'other' => q({0} milia karratu),
						'per' => q({0} milia karratu bakoitzeko),
					},
					# Core Unit Identifier
					'square-mile' => {
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
						'name' => q(elementuak),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(elementuak),
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
					'concentr-mole' => {
						'name' => q(molak),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(molak),
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
					'concentr-portion-per-1e9' => {
						'name' => q(zati mila milioiko),
						'one' => q({0} zati mila milioiko),
						'other' => q({0} zati mila milioiko),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(zati mila milioiko),
						'one' => q({0} zati mila milioiko),
						'other' => q({0} zati mila milioiko),
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
					'digital-bit' => {
						'name' => q(bit-ak),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(bit-ak),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(byte-ak),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(byte-ak),
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
						'per' => q({0} egun bakoitzeko),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(egunak),
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
						'per' => q({0} hilabete bakoitzeko),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(hilabeteak),
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
					'duration-night' => {
						'name' => q(gauak),
						'one' => q({0} gau),
						'other' => q({0} gau),
						'per' => q({0} gau bakoitzeko),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(gauak),
						'one' => q({0} gau),
						'other' => q({0} gau),
						'per' => q({0} gau bakoitzeko),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(laurdenak),
						'one' => q({0} laurden),
						'other' => q({0} laurden),
						'per' => q({0} laurden bakoitzeko),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(laurdenak),
						'one' => q({0} laurden),
						'other' => q({0} laurden),
						'per' => q({0} laurden bakoitzeko),
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
						'per' => q({0} aste bakoitzeko),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(asteak),
						'per' => q({0} aste bakoitzeko),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(urteak),
						'per' => q({0} urte bakoitzeko),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(urteak),
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
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(AEBko termiak),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-ordu 100 kilometroko),
						'one' => q({0} kilowatt-ordu 100 kilometroko),
						'other' => q({0} kilowatt-ordu 100 kilometroko),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-ordu 100 kilometroko),
						'one' => q({0} kilowatt-ordu 100 kilometroko),
						'other' => q({0} kilowatt-ordu 100 kilometroko),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newtonak),
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newtonak),
						'one' => q({0} newton),
						'other' => q({0} newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'one' => q({0} libra indar),
						'other' => q({0} libra indar),
					},
					# Core Unit Identifier
					'pound-force' => {
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
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(em tipografikoa),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'one' => q({0} megapixel),
						'other' => q({0} megapixel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q({0} megapixel),
						'other' => q({0} megapixel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q({0} pixel),
						'other' => q({0} pixel),
					},
					# Core Unit Identifier
					'pixel' => {
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
						'one' => q({0} oin),
						'other' => q({0} oin),
						'per' => q({0} oin bakoitzeko),
					},
					# Core Unit Identifier
					'foot' => {
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
						'one' => q({0} hazbete),
						'other' => q({0} hazbete),
						'per' => q({0} hazbete bakoitzeko),
					},
					# Core Unit Identifier
					'inch' => {
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
						'one' => q({0} argi-urte),
						'other' => q({0} argi-urte),
					},
					# Core Unit Identifier
					'light-year' => {
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
						'one' => q({0} milia),
						'other' => q({0} milia),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} milia),
						'other' => q({0} milia),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(milia eskandinaviarrak),
						'one' => q({0} milia eskandinaviar),
						'other' => q({0} milia eskandinaviar),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(milia eskandinaviarrak),
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
						'one' => q({0} puntu tipografiko),
						'other' => q({0} puntu tipografiko),
					},
					# Core Unit Identifier
					'point' => {
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
					'light-solar-luminosity' => {
						'one' => q({0} eguzki-argitasun),
						'other' => q({0} eguzki-argitasun),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0} eguzki-argitasun),
						'other' => q({0} eguzki-argitasun),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(kilateak),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(kilateak),
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
						'per' => q({0} ontza bakoitzeko),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(ontzak),
						'per' => q({0} ontza bakoitzeko),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(troy ontzak),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(troy ontzak),
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
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(AEBko tonak),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(tona metrikoak),
						'one' => q({0} tona metriko),
						'other' => q({0} tona metriko),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(tona metrikoak),
						'one' => q({0} tona metriko),
						'other' => q({0} tona metriko),
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
					'speed-beaufort' => {
						'name' => q(Beaufort),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Beaufort),
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
					'speed-light-speed' => {
						'name' => q(argia),
						'one' => q({0} argi),
						'other' => q({0} argi),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(argia),
						'one' => q({0} argi),
						'other' => q({0} argi),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q({0} metro segundoko),
						'other' => q({0} metro segundoko),
					},
					# Core Unit Identifier
					'meter-per-second' => {
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
						'one' => q({0} °),
						'other' => q({0} °),
					},
					# Core Unit Identifier
					'generic' => {
						'one' => q({0} °),
						'other' => q({0} °),
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
						'name' => q(oin-librak),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(oin-librak),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0} bushel),
						'other' => q({0} bushel),
					},
					# Core Unit Identifier
					'bushel' => {
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
					'volume-cup-metric' => {
						'name' => q(katilu metrikoak),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(katilu metrikoak),
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
						'name' => q(postre-koilarakadak),
						'one' => q({0} postre-koilarakada),
						'other' => q({0} postre-koilarakada),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(postre-koilarakadak),
						'one' => q({0} postre-koilarakada),
						'other' => q({0} postre-koilarakada),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Postre-koilarakada inperialak),
						'one' => q({0} postre-koilarakada inperial),
						'other' => q({0} postre-koilarakada inperial),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Postre-koilarakada inperialak),
						'one' => q({0} postre-koilarakada inperial),
						'other' => q({0} postre-koilarakada inperial),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dram fluidoak),
						'one' => q({0} dram fluido),
						'other' => q({0} dram fluido),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram fluidoak),
						'one' => q({0} dram fluido),
						'other' => q({0} dram fluido),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(tantak),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(tantak),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(ontza likido),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(ontza likido),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'per' => q({0} galoi bakoitzeko),
					},
					# Core Unit Identifier
					'gallon' => {
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
						'name' => q(txupitoak),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(txupitoak),
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
						'name' => q(pinch-ak),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pinch-ak),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(pinta metrikoak),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pinta metrikoak),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(laurden inperialak),
						'one' => q({0} laurden inperial),
						'other' => q({0} laurden inperial),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(laurden inperialak),
						'one' => q({0} laurden inperial),
						'other' => q({0} laurden inperial),
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
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/l),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(zati / m. m.),
						'one' => q({0} zati / m. m.),
						'other' => q({0} zati / m. m.),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(zati / m. m.),
						'one' => q({0} zati / m. m.),
						'other' => q({0} zati / m. m.),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'one' => q({0} m/g brit.),
						'other' => q({0} m/g brit.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'one' => q({0} m/g brit.),
						'other' => q({0} m/g brit.),
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
						'one' => q({0} e.),
						'other' => q({0} e.),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0} e.),
						'other' => q({0} e.),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(hamark.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(hamark.),
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
						'one' => q({0} hil),
						'other' => q({0} hil),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} hil),
						'other' => q({0} hil),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(gau),
						'one' => q({0} g.),
						'other' => q({0} g.),
						'per' => q({0}/gau),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(gau),
						'one' => q({0} g.),
						'other' => q({0} g.),
						'per' => q({0}/gau),
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
					'duration-year' => {
						'one' => q({0} u.),
						'other' => q({0} u.),
					},
					# Core Unit Identifier
					'year' => {
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
					'graphics-dot' => {
						'name' => q(puntua),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(puntua),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'one' => q({0}dpcm),
						'other' => q({0}dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'one' => q({0}dpcm),
						'other' => q({0}dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'one' => q({0}dpi),
						'other' => q({0}dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'one' => q({0}dpi),
						'other' => q({0}dpi),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'one' => q({0}em),
						'other' => q({0}em),
					},
					# Core Unit Identifier
					'em' => {
						'one' => q({0}em),
						'other' => q({0}em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(MP),
						'one' => q({0}MP),
						'other' => q({0}MP),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(MP),
						'one' => q({0}MP),
						'other' => q({0}MP),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(px),
						'one' => q({0}px),
						'other' => q({0}px),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(px),
						'one' => q({0}px),
						'other' => q({0}px),
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
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(gramo),
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
					'speed-beaufort' => {
						'one' => q(B{0}),
						'other' => q(B{0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'one' => q(B{0}),
						'other' => q(B{0}),
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
					'speed-light-speed' => {
						'name' => q(argia),
						'one' => q({0} a.),
						'other' => q({0} a.),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(argia),
						'one' => q({0} a.),
						'other' => q({0} a.),
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
					'torque-newton-meter' => {
						'name' => q(N·m),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(N·m),
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
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litro),
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
					'acceleration-g-force' => {
						'name' => q(G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(G),
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
						'name' => q(arku-seg.),
						'one' => q({0} arku-seg.),
						'other' => q({0} arku-seg.),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arku-seg.),
						'one' => q({0} arku-seg.),
						'other' => q({0} arku-seg.),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(gradu),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(gradu),
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
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektarea),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(milia karratu),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(milia karratu),
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
					'concentr-mole' => {
						'name' => q(mola),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mola),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'one' => q(% {0}),
						'other' => q(% {0}),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q(% {0}),
						'other' => q(% {0}),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q(‰ {0}),
						'other' => q(‰ {0}),
					},
					# Core Unit Identifier
					'permille' => {
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
					'concentr-portion-per-1e9' => {
						'name' => q(zati / mila milioi),
						'one' => q({0} zati / m. m.),
						'other' => q({0} zati / m. m.),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(zati / mila milioi),
						'one' => q({0} zati / m. m.),
						'other' => q({0} zati / m. m.),
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
						'one' => q({0} hamark.),
						'other' => q({0} hamark.),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(hamarkada),
						'one' => q({0} hamark.),
						'other' => q({0} hamark.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ordu),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ordu),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisegundo),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisegundo),
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
					'duration-night' => {
						'name' => q(gau),
						'one' => q({0} gau),
						'other' => q({0} gau),
						'per' => q({0}/gau),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(gau),
						'one' => q({0} gau),
						'other' => q({0} gau),
						'per' => q({0}/gau),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(laurden),
						'one' => q({0} laur.),
						'other' => q({0} laur.),
						'per' => q({0}/laurden),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(laurden),
						'one' => q({0} laur.),
						'other' => q({0} laur.),
						'per' => q({0}/laurden),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(segundo),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(segundo),
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
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh / 100 km),
						'one' => q({0} kWh / 100 km),
						'other' => q({0} kWh / 100 km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kWh / 100 km),
						'one' => q({0} kWh / 100 km),
						'other' => q({0} kWh / 100 km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(newtona),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(newtona),
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
					'graphics-dot' => {
						'name' => q(puntuak),
						'one' => q({0} puntu),
						'other' => q({0} puntu),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(puntuak),
						'one' => q({0} puntu),
						'other' => q({0} puntu),
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
					'graphics-pixel-per-centimeter' => {
						'name' => q(px/cm),
						'one' => q({0} px/cm),
						'other' => q({0} px/cm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(px/cm),
						'one' => q({0} px/cm),
						'other' => q({0} px/cm),
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
					'length-fathom' => {
						'one' => q({0} fm),
						'other' => q({0} fm),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0} fm),
						'other' => q({0} fm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(oin),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(oin),
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
						'name' => q(hazbete),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(hazbete),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(argi-urte),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(argi-urte),
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
						'name' => q(milia),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milia),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(milia eskandinaviar),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(milia eskandinaviar),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(puntu),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(puntu),
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
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(g),
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
					'power-watt' => {
						'name' => q(W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(W),
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
					'speed-beaufort' => {
						'name' => q(BFT),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(BFT),
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
					'speed-light-speed' => {
						'name' => q(argia),
						'one' => q({0} argi),
						'other' => q({0} argi),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(argia),
						'one' => q({0} argi),
						'other' => q({0} argi),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(metro segundoko),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(metro segundoko),
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
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'one' => q({0} °),
						'other' => q({0} °),
					},
					# Core Unit Identifier
					'generic' => {
						'one' => q({0} °),
						'other' => q({0} °),
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
						'one' => q({0} N·m),
						'other' => q({0} N·m),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'one' => q({0} N·m),
						'other' => q({0} N·m),
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
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bushelak),
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
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dram fluidoa),
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
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(l),
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
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pinch-a),
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
			'plusSign' => q(+),
		},
		'latn' => {
			'decimal' => q(,),
			'group' => q(.),
			'minusSign' => q(−),
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
			display_name => {
				'currency' => q(lek albaniarra),
				'one' => q(lek albaniar),
				'other' => q(lek albaniar),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(dram armeniarra),
				'one' => q(dram armeniar),
				'other' => q(dram armeniar),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(florin antillarra),
				'one' => q(florin antillar),
				'other' => q(florin antillar),
			},
		},
		'AOA' => {
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
			display_name => {
				'currency' => q(austral argentinarra),
				'one' => q(austral argentinar),
				'other' => q(austral argentinar),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(peso ley argentinarra \(1970–1983\)),
				'one' => q(peso ley argentinar \(1970–1983\)),
				'other' => q(peso ley argentinar \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(peso argentinarra \(1981–1970\)),
				'one' => q(peso argentinar \(1981–1970\)),
				'other' => q(peso argentinar \(1981–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(peso argentinarra \(1983–1985\)),
				'one' => q(peso argentinar \(1983–1985\)),
				'other' => q(peso argentinar \(1983–1985\)),
			},
		},
		'ARS' => {
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
			display_name => {
				'currency' => q(dolar australiarra),
				'one' => q(dolar australiar),
				'other' => q(dolar australiar),
			},
		},
		'AWG' => {
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
			display_name => {
				'currency' => q(dolar barbadostarra),
				'one' => q(dolar barbadostar),
				'other' => q(dolar barbadostar),
			},
		},
		'BDT' => {
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
			},
		},
		'BGN' => {
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
			display_name => {
				'currency' => q(dinar bahraindarra),
				'one' => q(dinar bahraindar),
				'other' => q(dinar bahraindar),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(franko burundiarra),
				'one' => q(franko burundiar),
				'other' => q(franko burundiar),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(dolar bermudarra),
				'one' => q(dolar bermudar),
				'other' => q(dolar bermudar),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(dolar bruneitarra),
				'one' => q(dolar bruneitar),
				'other' => q(dolar bruneitar),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(boliviano boliviarra),
				'one' => q(boliviano boliviar),
				'other' => q(boliviano boliviar),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(boliviano boliviarra \(1863–1963\)),
				'one' => q(boliviano boliviar \(1863–1963\)),
				'other' => q(boliviano boliviar \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(peso boliviarra),
				'one' => q(peso boliviar),
				'other' => q(peso boliviar),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(mvdol boliviarra),
				'one' => q(mvdol boliviar),
				'other' => q(mvdol boliviar),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(cruzeiro brasildar berria \(1967–1986\)),
				'one' => q(cruzeiro brasildar berri \(1967–1986\)),
				'other' => q(cruzeiro brasildar berri \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(cruzado brasildarra \(1986–1989\)),
				'one' => q(cruzado brasildar \(1986–1989\)),
				'other' => q(cruzado brasildar \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(cruzeiro brasildarra \(1990–1993\)),
				'one' => q(cruzeiro brasildar \(1990–1993\)),
				'other' => q(cruzeiro brasildar \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(erreal brasildarra),
				'one' => q(erreal brasildar),
				'other' => q(erreal brasildar),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(cruzado brasildar berria \(1989–1990\)),
				'one' => q(cruzado brasildar berri \(1989–1990\)),
				'other' => q(cruzado brasildar berri \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(cruzeiro brasildar berria \(1993–1994\)),
				'one' => q(cruzeiro brasildar berri \(1993–1994\)),
				'other' => q(cruzeiro brasildar berri \(1993–1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(cruzeiro brasildarra \(1942–1967\)),
				'one' => q(cruzeiro brasildar \(1942–1967\)),
				'other' => q(cruzeiro brasildar \(1942–1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(dolar bahamarra),
				'one' => q(dolar bahamar),
				'other' => q(dolar bahamar),
			},
		},
		'BTN' => {
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
			symbol => 'р.',
			display_name => {
				'currency' => q(errublo bielorrusiarra),
				'one' => q(errublo bielorrusiar),
				'other' => q(errublo bielorrusiar),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Bielorrusiako errubloa \(2000–2016\)),
				'one' => q(Bielorrusiako errublo \(2000–2016\)),
				'other' => q(Bielorrusiako errublo \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(dolar belizetarra),
				'one' => q(dolar belizetar),
				'other' => q(dolar belizetar),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(dolar kanadarra),
				'one' => q(dolar kanadar),
				'other' => q(dolar kanadar),
			},
		},
		'CDF' => {
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
			display_name => {
				'currency' => q(ezkutu txiletarra),
				'one' => q(ezkutu txiletar),
				'other' => q(ezkutu txiletar),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(kontu-unitate txiletarra \(UF\)),
				'one' => q(kontu-unitate txiletar \(UF\)),
				'other' => q(kontu-unitate txiletar \(UF\)),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(peso txiletarra),
				'one' => q(peso txiletar),
				'other' => q(peso txiletar),
			},
		},
		'CNH' => {
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
			display_name => {
				'currency' => q(yuan txinatarra),
				'one' => q(yuan txinatar),
				'other' => q(yuan txinatar),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(peso kolonbiarra),
				'one' => q(peso kolonbiar),
				'other' => q(peso kolonbiar),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(erreal kolonbiarraren balio-unitatea),
				'one' => q(erreal kolonbiarraren balio-unitate),
				'other' => q(erreal kolonbiarraren balio-unitate),
			},
		},
		'CRC' => {
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
			display_name => {
				'currency' => q(peso bihurgarri kubatarra),
				'one' => q(peso bihurgarri kubatar),
				'other' => q(peso bihurgarri kubatar),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(peso kubatarra),
				'one' => q(peso kubatar),
				'other' => q(peso kubatar),
			},
		},
		'CVE' => {
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
			display_name => {
				'currency' => q(franko djibutiarra),
				'one' => q(franko djibutiar),
				'other' => q(franko djibutiar),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(koroa danimarkarra),
				'one' => q(koroa danimarkar),
				'other' => q(koroa danimarkar),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(peso dominikarra),
				'one' => q(peso dominikar),
				'other' => q(peso dominikar),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(dinar aljeriarra),
				'one' => q(dinar aljeriar),
				'other' => q(dinar aljeriar),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(sukre ekuadortarra),
				'one' => q(sukre ekuadortar),
				'other' => q(sukre ekuadortar),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(balio-unitate konstante ekuadortarra),
				'one' => q(balio-unitate konstante ekuadortar),
				'other' => q(balio-unitate konstante ekuadortar),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(kroon estoniarra),
				'one' => q(kroon estoniar),
				'other' => q(kroon estoniar),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(libera egiptoarra),
				'one' => q(libera egiptoar),
				'other' => q(libera egiptoar),
			},
		},
		'ERN' => {
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
			display_name => {
				'currency' => q(birr etiopiarra),
				'one' => q(birr etiopiar),
				'other' => q(birr etiopiar),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euroa),
				'one' => q(euro),
				'other' => q(euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(markka finlandiarra),
				'one' => q(markka finlandiar),
				'other' => q(markka finlandiar),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(dolar fijiarra),
				'one' => q(dolar fijiar),
				'other' => q(dolar fijiar),
			},
		},
		'FKP' => {
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
			display_name => {
				'currency' => q(libera esterlina),
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
			display_name => {
				'currency' => q(cedi ghanatarra),
				'one' => q(cedi ghanatar),
				'other' => q(cedi ghanatar),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(libera gibraltartarra),
				'one' => q(libera gibraltartar),
				'other' => q(libera gibraltartar),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(dalasi gambiarra),
				'one' => q(dalasi gambiar),
				'other' => q(dalasi gambiar),
			},
		},
		'GNF' => {
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
			display_name => {
				'currency' => q(dolar guyanarra),
				'one' => q(dolar guyanar),
				'other' => q(dolar guyanar),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(dolar hongkongtarra),
				'one' => q(dolar hongkongtar),
				'other' => q(dolar hongkongtar),
			},
		},
		'HNL' => {
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
			display_name => {
				'currency' => q(kuna kroaziarra),
				'one' => q(kuna kroaziar),
				'other' => q(kuna kroaziar),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(gourde haitiarra),
				'one' => q(gourde haitiar),
				'other' => q(gourde haitiar),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(forint hungariarra),
				'one' => q(forint hungariar),
				'other' => q(forint hungariar),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(errupia indonesiarra),
				'one' => q(errupia indonesiar),
				'other' => q(errupia indonesiar),
			},
		},
		'IEP' => {
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
			display_name => {
				'currency' => q(shekel israeldar berria),
				'one' => q(shekel israeldar berri),
				'other' => q(shekel israeldar berri),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(errupia indiarra),
				'one' => q(errupia indiar),
				'other' => q(errupia indiar),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(dinar irakiarra),
				'one' => q(dinar irakiar),
				'other' => q(dinar irakiar),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(rial irandarra),
				'one' => q(rial irandar),
				'other' => q(rial irandar),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(koroa islandiarra \(1918–1981\)),
				'one' => q(koroa islandiar \(1918–1981\)),
				'other' => q(koroa islandiar \(1918–1981\)),
			},
		},
		'ISK' => {
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
			display_name => {
				'currency' => q(dolar jamaikarra),
				'one' => q(dolar jamaikar),
				'other' => q(dolar jamaikar),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(dinar jordaniarra),
				'one' => q(dinar jordaniar),
				'other' => q(dinar jordaniar),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(yen japoniarra),
				'one' => q(yen japoniar),
				'other' => q(yen japoniar),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(txelin kenyarra),
				'one' => q(txelin kenyar),
				'other' => q(txelin kenyar),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(som kirgizistandarra),
				'one' => q(som kirgizistandar),
				'other' => q(som kirgizistandar),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(riel kanbodiarra),
				'one' => q(riel kanbodiar),
				'other' => q(riel kanbodiar),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(franko komoretarra),
				'one' => q(franko komoretar),
				'other' => q(franko komoretar),
			},
		},
		'KPW' => {
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
			display_name => {
				'currency' => q(won hegokorearra),
				'one' => q(won hegokorear),
				'other' => q(won hegokorear),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(dinar kuwaitarra),
				'one' => q(dinar kuwaitar),
				'other' => q(dinar kuwaitar),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(dolar kaimandarra),
				'one' => q(dolar kaimandar),
				'other' => q(dolar kaimandar),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(tenge kazakhstandarra),
				'one' => q(tenge kazakhstandar),
				'other' => q(tenge kazakhstandar),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(kip laostarra),
				'one' => q(kip laostar),
				'other' => q(kip laostar),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(libera libanoarra),
				'one' => q(libera libanoar),
				'other' => q(libera libanoar),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(errupia srilankarra),
				'one' => q(errupia srilankar),
				'other' => q(errupia srilankar),
			},
		},
		'LRD' => {
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
			display_name => {
				'currency' => q(Lituaniako litasa),
				'one' => q(Lituaniako litas),
				'other' => q(Lituaniako litas),
			},
		},
		'LTT' => {
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
			display_name => {
				'currency' => q(dinar libiarra),
				'one' => q(dinar libiar),
				'other' => q(dinar libiar),
			},
		},
		'MAD' => {
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
			display_name => {
				'currency' => q(leu moldaviarra),
				'one' => q(leu moldaviar),
				'other' => q(leu moldaviar),
			},
		},
		'MGA' => {
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
			display_name => {
				'currency' => q(kyat myanmartarra),
				'one' => q(kyat myanmartar),
				'other' => q(kyat myanmartar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(tugrik mongoliarra),
				'one' => q(tugrik mongoliar),
				'other' => q(tugrik mongoliar),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(pataca macauarra),
				'one' => q(pataca macauar),
				'other' => q(pataca macauar),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Mauritaniako ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
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
			},
		},
		'MUR' => {
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
			display_name => {
				'currency' => q(rufiyaa maldivarra),
				'one' => q(rufiyaa maldivar),
				'other' => q(rufiyaa maldivar),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(kwacha malawiarra),
				'one' => q(kwacha malawiar),
				'other' => q(kwacha malawiar),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(peso mexikarra),
				'one' => q(peso mexikar),
				'other' => q(peso mexikar),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Zilar-peso amerikarra \(1861–1992\)),
				'one' => q(Zilar-peso amerikar \(1861–1992\)),
				'other' => q(Zilar-peso amerikar \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Inbertsio-unitate mexikarra),
				'one' => q(Inbertsio-unitate mexikar),
				'other' => q(Inbertsio-unitate mexikar),
			},
		},
		'MYR' => {
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
			display_name => {
				'currency' => q(metical mozambiketarra),
				'one' => q(metical mozambiketar),
				'other' => q(metical mozambiketar),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(dolar namibiarra),
				'one' => q(dolar namibiar),
				'other' => q(dolar namibiar),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(naira nigeriarra),
				'one' => q(naira nigeriar),
				'other' => q(naira nigeriar),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(kordoba nikaraguar \(1988–1991\)),
			},
		},
		'NIO' => {
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
			display_name => {
				'currency' => q(koroa norvegiarra),
				'one' => q(koroa norvegiar),
				'other' => q(koroa norvegiar),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(errupia nepaldarra),
				'one' => q(errupia nepaldar),
				'other' => q(errupia nepaldar),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(dolar zeelandaberritarra),
				'one' => q(dolar zeelandaberritar),
				'other' => q(dolar zeelandaberritar),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(rial omandarra),
				'one' => q(rial omandar),
				'other' => q(rial omandar),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(balboa panamarra),
				'one' => q(balboa panamar),
				'other' => q(balboa panamar),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(inti perutarra),
				'one' => q(inti perutar),
				'other' => q(inti perutar),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(sol perutarra),
				'one' => q(sol perutar),
				'other' => q(sol perutar),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(sol perutarra \(1863–1965\)),
				'one' => q(sol perutar \(1863–1965\)),
				'other' => q(sol perutar \(1863–1965\)),
			},
		},
		'PGK' => {
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
			display_name => {
				'currency' => q(errupia pakistandarra),
				'one' => q(errupia pakistandar),
				'other' => q(errupia pakistandar),
			},
		},
		'PLN' => {
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
			display_name => {
				'currency' => q(guarani paraguaitarra),
				'one' => q(guarani paraguaitar),
				'other' => q(guarani paraguaitar),
			},
		},
		'QAR' => {
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
			display_name => {
				'currency' => q(leu errumaniarra),
				'one' => q(leu errumaniar),
				'other' => q(leu errumaniar),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(dinar serbiarra),
				'one' => q(dinar serbiar),
				'other' => q(dinar serbiar),
			},
		},
		'RUB' => {
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
			display_name => {
				'currency' => q(franko ruandarra),
				'one' => q(franko ruandar),
				'other' => q(franko ruandar),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(riyal saudiarabiarra),
				'one' => q(riyal saudiarabiar),
				'other' => q(riyal saudiarabiar),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(dolar salomondarra),
				'one' => q(dolar salomondar),
				'other' => q(dolar salomondar),
			},
		},
		'SCR' => {
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
			display_name => {
				'currency' => q(koroa suediarra),
				'one' => q(koroa suediar),
				'other' => q(koroa suediar),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(dolar singapurtarra),
				'one' => q(dolar singapurtar),
				'other' => q(dolar singapurtar),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Santa Helenako libera),
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
		'SLE' => {
			display_name => {
				'currency' => q(leone sierraleonar berria),
				'one' => q(leone sierraleonar berri),
				'other' => q(leone sierraleonar berri),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(leone sierraleonarra),
				'one' => q(leone sierraleonar),
				'other' => q(leone sierraleonar),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(txelin somaliarra),
				'one' => q(txelin somaliar),
				'other' => q(txelin somaliar),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(dolar surinamdarra),
				'one' => q(dolar surinamdar),
				'other' => q(dolar surinamdar),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(gilder surinamdarra),
				'one' => q(gilder surinamdar),
				'other' => q(gilder surinamdar),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(libera hegosudandarra),
				'one' => q(libera hegosudandar),
				'other' => q(libera hegosudandar),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Sao Tomeko eta Principeko dobra \(1977–2017\)),
			},
		},
		'STN' => {
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
			display_name => {
				'currency' => q(kolon salvadortarra),
				'one' => q(kolon salvadortar),
				'other' => q(kolon salvadortar),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(libera siriarra),
				'one' => q(libera siriar),
				'other' => q(libera siriar),
			},
		},
		'SZL' => {
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
			display_name => {
				'currency' => q(manat turkmenistandarra),
				'one' => q(manat turkmenistandar),
				'other' => q(manat turkmenistandar),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(dinar tunisiarra),
				'one' => q(dinar tunisiar),
				'other' => q(dinar tunisiar),
			},
		},
		'TOP' => {
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
			display_name => {
				'currency' => q(lira turkiarra),
				'one' => q(lira turkiar),
				'other' => q(lira turkiar),
			},
		},
		'TTD' => {
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
			display_name => {
				'currency' => q(txelin tanzaniarra),
				'one' => q(txelin tanzaniar),
				'other' => q(txelin tanzaniar),
			},
		},
		'UAH' => {
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
			display_name => {
				'currency' => q(txelin ugandarra),
				'one' => q(txelin ugandar),
				'other' => q(txelin ugandar),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(dolar estatubatuarra),
				'one' => q(dolar estatubatuar),
				'other' => q(dolar estatubatuar),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(dolar estatubatuar \(Hurrengo eguna\)),
				'one' => q(dolar estatubatuar \(hurrengo eguna\)),
				'other' => q(dolar estatubatuar \(hurrengo eguna\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(dolar estatubatuar \(Egun berean\)),
				'one' => q(dolar estatubatuar \(egun berean\)),
				'other' => q(dolar estatubatuar \(egun berean\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(peso uruguaitarra \(unitate indexatuak\)),
				'one' => q(peso uruguaitar \(unitate indexatuak\)),
				'other' => q(peso uruguaitar \(unitate indexatuak\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(peso uruguaitarra \(1975–1993\)),
				'one' => q(peso uruguaitar \(1975–1993\)),
				'other' => q(peso uruguaitar \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(peso uruguaitarra),
				'one' => q(peso uruguaitar),
				'other' => q(peso uruguaitar),
			},
		},
		'UYW' => {
			display_name => {
				'currency' => q(soldata nominalaren indize-unitate uruguaitarra),
				'one' => q(soldata nominalaren indize-unitate uruguaitar),
				'other' => q(soldata nominalaren indize-unitate uruguaitar),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(sum uzbekistandarra),
				'one' => q(sum uzbekistandar),
				'other' => q(sum uzbekistandar),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Venezuelako bolivarra \(1871–2008\)),
				'one' => q(Venezuelako bolivar \(1871–2008\)),
				'other' => q(Venezuelako bolivar \(1871–2008\)),
			},
		},
		'VED' => {
			display_name => {
				'currency' => q(bolivar subiraua),
				'one' => q(bolivar subirau),
				'other' => q(bolivar subirau),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Venezuelako bolivarra \(2008–2018\)),
				'one' => q(Venezuelako bolivar \(2008–2018\)),
				'other' => q(Venezuelako bolivar \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(bolivar venezuelarra),
				'one' => q(bolivar venezuelar),
				'other' => q(bolivar venezuelar),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(dong vietnamdarra),
				'one' => q(dong vietnamdar),
				'other' => q(dong vietnamdar),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(dong vietnamdar \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vatu vanuatuarra),
				'one' => q(vatu vanuatuar),
				'other' => q(vatu vanuatuar),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(tala samoarra),
				'one' => q(tala samoar),
				'other' => q(tala samoar),
			},
		},
		'XAF' => {
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
			display_name => {
				'currency' => q(CFP frankoa),
				'one' => q(CFP franko),
				'other' => q(CFP franko),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platinozko troy ontza),
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
				'stand-alone' => {
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
					narrow => {
						mon => 'A',
						tue => 'A',
						wed => 'A',
						thu => 'O',
						fri => 'O',
						sat => 'L',
						sun => 'I'
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
			if ($_ eq 'coptic') {
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
			if ($_ eq 'dangi') {
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
			if ($_ eq 'ethiopic') {
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
			if ($_ eq 'hebrew') {
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
			if ($_ eq 'indian') {
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
			if ($_ eq 'islamic') {
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
			if ($_ eq 'japanese') {
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
			if ($_ eq 'persian') {
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
					'evening1' => q{iluntz.},
					'midnight' => q{gauerdia},
					'morning1' => q{goizald.},
					'morning2' => q{goizeko},
					'night1' => q{gaueko},
				},
				'narrow' => {
					'afternoon1' => q{eguerd.},
					'afternoon2' => q{arrats.},
					'am' => q{g},
					'evening1' => q{iluntz.},
					'midnight' => q{gauerd.},
					'morning1' => q{goizald.},
					'morning2' => q{goizeko},
					'night1' => q{gaueko},
					'pm' => q{a},
				},
				'wide' => {
					'afternoon1' => q{eguerdiko},
					'afternoon2' => q{arratsaldeko},
					'evening1' => q{iluntzeko},
					'midnight' => q{gauerdia},
					'morning1' => q{goizaldeko},
					'morning2' => q{goizeko},
					'night1' => q{gaueko},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{eguerd.},
					'afternoon2' => q{arrats.},
					'evening1' => q{iluntz.},
					'morning1' => q{goiz.},
					'morning2' => q{goiza},
					'night1' => q{gaua},
				},
				'narrow' => {
					'afternoon1' => q{eguerd.},
					'afternoon2' => q{arrats.},
					'evening1' => q{iluntz.},
					'morning1' => q{goizald.},
					'morning2' => q{goiza},
					'night1' => q{gaua},
				},
				'wide' => {
					'afternoon1' => q{eguerdia},
					'afternoon2' => q{arratsaldea},
					'evening1' => q{iluntzea},
					'morning1' => q{goizaldea},
					'morning2' => q{goiza},
					'night1' => q{gaua},
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
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
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
				'0' => 'Kristo aurretik',
				'1' => 'Kristo ondoren'
			},
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
			abbreviated => {
				'0' => 'R.O.C. aurretik'
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
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
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

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'buddhist' => {
		},
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH:mm:ss (zzzz)},
			'long' => q{HH:mm:ss (z)},
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
		},
		'coptic' => {
		},
		'dangi' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} ({0})},
			'long' => q{{1} ({0})},
			'medium' => q{{1} ({0})},
			'short' => q{{1} ({0})},
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

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Bh => q{B h('r')('a')'k'},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:s},
			EBhm => q{E B h:mm},
			EBhms => q{E B h:mm:ss},
			Ed => q{d, EEEE},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G. 'aroko' y. 'urtea'},
			GyMMM => q{G. 'aroko' y('e')'ko' MMMM},
			GyMMMEd => q{G. 'aroko' y('e')'ko' MMMM d, EEEE},
			GyMMMd => q{G. 'aroko' y('e')'ko' MMMM d},
			GyMd => q{y-MM-dd (GGGGG)},
			MEd => q{MM/dd, EEEE},
			MMMEd => q{MMM'k' d, EEEE},
			MMMMd => q{MMMM'k' d},
			MMMd => q{MMM'k' d},
			Md => q{MM/dd},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y},
			yM => q{y/MM},
			yMEd => q{y/MM/dd, EEEE},
			yMMM => q{y('e')'ko' MMMM},
			yMMMEd => q{y('e')'ko' MMMM'k' d, EEEE},
			yMMMd => q{y('e')'ko' MMMM'k' d},
			yMd => q{y/MM/dd},
			yQQQ => q{y('e')'ko' QQQ},
			yQQQQ => q{y('e')'ko' QQQQ},
			yyyyM => q{G y/MM},
			yyyyMEd => q{G('e')'ko' y/MM/dd, EEEE},
			yyyyMMM => q{G, y('e')'ko' MMM},
			yyyyMMMEd => q{G y MMM d, EEEE},
			yyyyMMMM => q{G y('e')'ko' MMMM},
			yyyyMMMMEd => q{G y('e')'ko' MMMM d, EEEE},
			yyyyMMMMd => q{G y('e')'ko' MMMM d},
			yyyyMd => q{G('e')'ko' y/MM/dd},
			yyyyQQQQ => q{G y('e')'ko' QQQQ},
		},
		'gregorian' => {
			Bh => q{B h},
			Bhm => q{B h:mm},
			Bhms => q{B h:mm:ss},
			EBhm => q{E B h:mm},
			EBhms => q{E B h:mm:ss},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			GyMMM => q{G y. 'urteko' MMM},
			GyMMMEd => q{G y. 'urteko' MMM d('a'), E},
			GyMMMd => q{G y. 'urteko' MMM d('a')},
			MEd => q{M/d, E},
			MMMEd => q{MMM d('a'), E},
			MMMMW => q{MMMM'ren' W. 'astea'},
			MMMMd => q{MMMM'ren' d('a')},
			MMMd => q{MMM d('a')},
			Md => q{M/d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{y/M},
			yMEd => q{y/M/d, E},
			yMMMEd => q{y MMM d('a'), E},
			yMMMM => q{y('e')'ko' MMMM},
			yMMMMEd => q{y('e')'ko' MMMM'ren' d('a'), E},
			yMMMMd => q{y('e')'ko' MMMM'ren' d('a')},
			yMMMd => q{y MMM d('a')},
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
		'buddhist' => {
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
			GyMd => {
				G => q{GGGGG y-MM-dd – GGGGG y-MM-dd},
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
		},
		'coptic' => {
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
			GyMd => {
				G => q{GGGGG y-MM-dd – GGGGG y-MM-dd},
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
		},
		'dangi' => {
			Bh => {
				B => q{h B – h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMMEd => {
				M => q{MMM d, E – MMM d, E},
				d => q{MMM d, E – MMM d, E},
			},
			MMMd => {
				M => q{MMM d – MMM d},
			},
			Md => {
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
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
				M => q{y-MM – y-MM},
				y => q{y-MM – y-MM},
			},
			yMEd => {
				M => q{y-MM-dd, E – y-MM-dd, E},
				d => q{y-MM-dd, E – y-MM-dd, E},
				y => q{y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				y => q{U MMM – U MMM},
			},
			yMMMEd => {
				M => q{U MMM d, E – MMM d, E},
				d => q{U MMM d, E – MMM d, E},
				y => q{U MMM d, E – U MMM d, E},
			},
			yMMMM => {
				y => q{U MMMM – U MMMM},
			},
			yMMMd => {
				M => q{U MMM d – MMM d},
				y => q{U MMM d – U MMM d},
			},
			yMd => {
				M => q{y-MM-dd – y-MM-dd},
				d => q{y-MM-dd – y-MM-dd},
				y => q{y-MM-dd – y-MM-dd},
			},
		},
		'ethiopic' => {
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
			GyMd => {
				G => q{GGGGG y-MM-dd – GGGGG y-MM-dd},
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
		},
		'generic' => {
			Bh => {
				B => q{B h – B h},
				h => q{B h–h},
			},
			Bhm => {
				B => q{B h:mm – B h:mm},
				h => q{B h:mm–h:mm},
				m => q{B h:mm–h:mm},
			},
			GyMMM => {
				G => q{G y, MMM – G y, MMM},
				M => q{G y, MMM–MMM},
				y => q{G y, MMM – G y, MMM},
			},
			GyMMMEd => {
				G => q{G y, MMM d, E – G y, MMM d, E},
				M => q{G y, MMM d, E – MMM d, E},
				d => q{G y, MMM d, E – MMM d, E},
				y => q{G y, MMM d, E – G y, MMM d, E},
			},
			GyMMMd => {
				G => q{G y, MMM d – G y, MMM d},
				M => q{G y, MMM d – MMM d},
				d => q{G y, MMM d–d},
				y => q{G y, MMM d – G y, MMM d},
			},
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			MEd => {
				M => q{MM/dd, EEEE – MM/dd, EEEE},
				d => q{MM/dd, EEEE – MM/dd, EEEE},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{MMM'k' d, EEEE – MMM'k' d, EEEE},
				d => q{MMM'k' d, EEEE – MMM'k' d, EEEE},
			},
			MMMd => {
				M => q{MMM'k' d – MMMM'k' d},
				d => q{MMMM d–d},
			},
			Md => {
				M => q{MM/dd – MM/dd},
				d => q{MM/dd – MM/dd},
			},
			d => {
				d => q{dd–dd},
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
				m => q{h:mm–h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			yM => {
				M => q{G y/MM – y/MM},
				y => q{G y/MM – y/MM},
			},
			yMEd => {
				M => q{G y/MM/dd, EEEE – y/MM/dd, EEEE},
				d => q{G y/MM/dd, EEEE – y/MM/dd, EEEE},
				y => q{G y/MM/dd, EEEE – y/MM/dd, EEEE},
			},
			yMMM => {
				M => q{G y('e')'ko' MMMM–MMMM},
				y => q{G y('e')'ko' MMMM – y('e')'ko' MMMM},
			},
			yMMMEd => {
				M => q{G y('e')'ko' MMMM dd, EEEE – MMMM dd, EEEE},
				d => q{G y('e')'ko' MMMM dd, EEEE – MMMM dd, EEEE},
				y => q{G y('e')'ko' MMMM dd, EEEE – y('e')'ko' MMMM dd, EEEE},
			},
			yMMMM => {
				M => q{G y('e')'ko' MMMM – MMMM},
				y => q{G y('e')'ko' MMMM – y('e')'ko' MMMM},
			},
			yMMMd => {
				M => q{G y('e')'ko' MMMM dd – MMMM dd},
				d => q{G y('e')'ko' MMMM dd–dd},
				y => q{G y('e')'ko' MMMM dd – y('e')'ko' MMMM dd},
			},
			yMd => {
				M => q{G y/MM/dd – y/MM/dd},
				d => q{G y/MM/dd – y/MM/dd},
				y => q{G y/MM/dd – y/MM/dd},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{B h – B h},
				h => q{B h–h},
			},
			Bhm => {
				B => q{B h:mm – B h:mm},
				h => q{B h:mm–h:mm},
				m => q{B h:mm–h:mm},
			},
			GyMMM => {
				G => q{G y, MMM – G y, MMM},
				M => q{G y, MMM–MMM},
				y => q{G y, MMM – G y, MMM},
			},
			GyMMMEd => {
				G => q{G y, MMM d('a'), E – G y, MMM d('a'), E},
				M => q{G y, MMM d('a'), E – MMM d('a'), E},
				d => q{G y, MMM d('a'), E – MMM d('a'), E},
				y => q{G y, MMM d('a'), E – G y, MMM d('a'), E},
			},
			GyMMMd => {
				G => q{G y, MMM d('a') – G y, MMM d('a')},
				M => q{G y, MMM d('a') – MMM d('a')},
				d => q{G y, MMM d–d},
				y => q{G y, MMM d('a') – G y, MMM d('a')},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{M/d, E – M/d, E},
				d => q{M/d, E – M/d, E},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{MMM d('a'), E – MMM d('a'), E},
				d => q{MMM d('a'), E – MMM d('a'), E},
			},
			MMMd => {
				M => q{MMM d('a') – MMM d('a')},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
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
				M => q{y/M – y/M},
				y => q{y/M – y/M},
			},
			yMEd => {
				M => q{y/M/d, E – y/M/d, E},
				d => q{y/M/d, E – y/M/d, E},
				y => q{y/M/d, E – y/M/d, E},
			},
			yMMM => {
				M => q{y('e')'ko' MMM–MMM},
				y => q{y('e')'ko' MMM – y('e')'ko' MMM},
			},
			yMMMEd => {
				M => q{y('e')'ko' MMM d('a'), E – MMM d('a'), E},
				d => q{y('e')'ko' MMM d('a'), E – y('e')'ko' MMM d('a'), E},
				y => q{y('e')'ko' MMM d('a'), E – y('e')'ko' MMM d('a'), E},
			},
			yMMMM => {
				M => q{y('e')'ko' MMMM–MMMM},
				y => q{y('e')'ko' MMMM – y('e')'ko' MMMM},
			},
			yMMMd => {
				M => q{y('e')'ko' MMM d('a') – MMM d('a')},
				d => q{y('e')'ko' MMM d–d},
				y => q{y('e')'ko' MMM d('a') – y('e')'ko' MMM d('a')},
			},
			yMd => {
				M => q{y/M/d – y/M/d},
				d => q{y/M/d – y/M/d},
				y => q{y/M/d – y/M/d},
			},
		},
		'hebrew' => {
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
			GyMd => {
				G => q{GGGGG y-MM-dd – GGGGG y-MM-dd},
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
		},
		'indian' => {
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
			GyMd => {
				G => q{GGGGG y-MM-dd – GGGGG y-MM-dd},
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
		},
		'islamic' => {
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
			GyMd => {
				G => q{GGGGG y-MM-dd – GGGGG y-MM-dd},
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
		},
		'japanese' => {
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
			GyMd => {
				G => q{GGGGG y-MM-dd – GGGGG y-MM-dd},
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
		},
		'persian' => {
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
			GyMd => {
				G => q{GGGGG y-MM-dd – GGGGG y-MM-dd},
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
		},
		'roc' => {
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
			GyMd => {
				G => q{GGGGG y-MM-dd – GGGGG y-MM-dd},
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		hourFormat => q(+HH:mm;–HH:mm),
		regionFormat => q({0} aldeko ordua),
		regionFormat => q({0} (udako ordua)),
		regionFormat => q({0} aldeko ordu estandarra),
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
		'Africa/Accra' => {
			exemplarCity => q#Akkra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Aljer#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bangi#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Konakry#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Djibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Duala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Aaiun#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartum#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Muqdisho#,
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
		'America/Anguilla' => {
			exemplarCity => q#Aingira#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaína#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucumán#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kaiman#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Córdoba#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepé#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadalupe#,
		},
		'America/Havana' => {
			exemplarCity => q#Habana#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaika#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinika#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexiko Hiria#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Mikelune#,
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
		'America/Port_of_Spain' => {
			exemplarCity => q#Port-of-Spain#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarém#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
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
		'America/Thule' => {
			exemplarCity => q#Qaanaaq#,
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
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Asgabat#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bixkek#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkuta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Txita#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasko#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Duxanbe#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Khovd#,
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
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Maskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosia#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Piongiang#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanay#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kyzylorda#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riad#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkanda#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seul#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolimsk#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taxkent#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Ürümqi#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vientian#,
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
		'Atlantic/Canary' => {
			exemplarCity => q#Kanariak#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cabo Verde#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Hegoaldeko Georgiak#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Santa Helena#,
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
		'Europe/Athens' => {
			exemplarCity => q#Atenas#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brusela#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhage#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Irlandako ordu estandarra#,
			},
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernesey#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Man uhartea#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisboa#,
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
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Mosku#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Erroma#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulianovsk#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikano Hiria#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viena#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsovia#,
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
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivak#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Maurizio#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indiako ozeanoko ordua#,
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
		'Kazakhstan' => {
			long => {
				'standard' => q#Kazakhstango ordua#,
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
		'Lanka' => {
			long => {
				'standard' => q#Lankako ordua#,
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
		'Macau' => {
			long => {
				'daylight' => q#Macaoko udako ordua#,
				'generic' => q#Macaoko ordua#,
				'standard' => q#Macaoko ordu estandarra#,
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
		'Pacific/Easter' => {
			exemplarCity => q#Pazko uhartea#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Éfaté#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapagoak#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
			short => {
				'daylight' => q#HDT#,
				'generic' => q#HST#,
				'standard' => q#HST#,
			},
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markesak#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Nouméa#,
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
