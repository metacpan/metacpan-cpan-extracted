=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Smn - Package for language Inari Sami

=cut

package Locale::CLDR::Locales::Smn;
# This file auto generated from Data\common\main\smn.xml
#	on Sat  4 Nov  6:23:35 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.34.3');

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
 				'ab' => 'abhasiakielâ',
 				'ace' => 'atšehkielâ',
 				'ada' => 'adangme',
 				'ady' => 'adyge',
 				'af' => 'afrikaans',
 				'agq' => 'aghem',
 				'ain' => 'ainukielâ',
 				'ak' => 'akankielâ',
 				'ale' => 'aleutkielâ',
 				'alt' => 'maadâaltaikielâ',
 				'am' => 'amharakielâ',
 				'an' => 'aragoniakielâ',
 				'anp' => 'angika',
 				'ar' => 'arabiakielâ',
 				'ar_001' => 'standard arabiakielâ',
 				'arn' => 'mapudungun',
 				'arp' => 'arapahokielâ',
 				'as' => 'assamkielâ',
 				'asa' => 'asukielâ',
 				'ast' => 'asturiakielâ',
 				'av' => 'avarkielâ',
 				'awa' => 'awadhikielâ',
 				'ay' => 'aymarakielâ',
 				'az' => 'azerbaidžankielâ',
 				'ba' => 'baškirkielâ',
 				'ban' => 'balikielâ',
 				'bas' => 'basaakielâ',
 				'be' => 'vielgisruošâkielâ',
 				'bem' => 'bembakielâ',
 				'bez' => 'benakielâ',
 				'bg' => 'bulgariakielâ',
 				'bho' => 'bhožpurikielâ',
 				'bi' => 'bislama',
 				'bin' => 'binikielâ',
 				'bla' => 'siksikakielâ',
 				'bm' => 'bambarakielâ',
 				'bn' => 'banglakielâ',
 				'bo' => 'tiibetkielâ',
 				'br' => 'bretonkielâ',
 				'brx' => 'bodokielâ',
 				'bs' => 'bosniakielâ',
 				'bug' => 'bugikielâ',
 				'byn' => 'blinkielâ',
 				'ca' => 'katalankielâ',
 				'ce' => 'tšetšenkielâ',
 				'ceb' => 'cebuanokielâ',
 				'cgg' => 'kigakielâ',
 				'ch' => 'chamorrokielâ',
 				'chk' => 'chuukkielâ',
 				'chm' => 'marikielâ',
 				'cho' => 'choctawkielâ',
 				'chr' => 'cherokeekielâ',
 				'chy' => 'cheyennekielâ',
 				'ckb' => 'sorani kurdikielâ',
 				'co' => 'korsikakielâ',
 				'crs' => 'Seychellij kreoliranska',
 				'cs' => 'tšeekikielâ',
 				'cu' => 'kirkkoslaavi',
 				'cv' => 'tšuvaskielâ',
 				'cy' => 'kymrikielâ',
 				'da' => 'tanskakielâ',
 				'dak' => 'dakotakielâ',
 				'dar' => 'dargikielâ',
 				'dav' => 'taitakielâ',
 				'de' => 'saksakielâ',
 				'de_AT' => 'Nuorttâriijkâ saksakielâ',
 				'de_CH' => 'Sveitsi pajesaksakielâ',
 				'dgr' => 'dogribkielâ',
 				'dje' => 'zarmakielâ',
 				'dsb' => 'vyelisorbi',
 				'dua' => 'dualakielâ',
 				'dv' => 'divehikielâ',
 				'dyo' => 'jola-fonyi',
 				'dz' => 'Dzongkha',
 				'dzg' => 'dazakielâ',
 				'ebu' => 'embukielâ',
 				'ee' => 'ewekielâ',
 				'efi' => 'efikkielâ',
 				'eka' => 'ekajuk',
 				'el' => 'kreikakielâ',
 				'en' => 'eŋgâlâskielâ',
 				'en_AU' => 'Australia eŋgâlâskielâ',
 				'en_CA' => 'Kanada eŋgâlâskielâ',
 				'en_GB' => 'Britannia eŋgâlâskielâ',
 				'en_GB@alt=short' => 'eŋgâlâskielâ (OK)',
 				'en_US' => 'Amerika eŋgâlâskielâ',
 				'en_US@alt=short' => 'eŋgâlâskielâ (USA)',
 				'eo' => 'esperantokielâ',
 				'es' => 'espanjakielâ',
 				'es_419' => 'Läättin-Amerika espanjakielâ',
 				'es_ES' => 'Espanja espanjakielâ',
 				'es_MX' => 'Meksiko espanjakielâ',
 				'et' => 'eestikielâ',
 				'eu' => 'baskikielâ',
 				'ewo' => 'ewondokielâ',
 				'fa' => 'persiakielâ',
 				'ff' => 'fulakielâ',
 				'fi' => 'suomâkielâ',
 				'fil' => 'filipinokielâ',
 				'fj' => 'fidžikielâ',
 				'fo' => 'fäärikielâ',
 				'fon' => 'fonkielâ',
 				'fr' => 'ranskakielâ',
 				'fr_CA' => 'Kanada ranskakielâ',
 				'fr_CH' => 'Sveitsi ranskakielâ',
 				'fur' => 'friulikielâ',
 				'fy' => 'viestârfriisi',
 				'ga' => 'iirikielâ',
 				'gaa' => 'gakielâ',
 				'gd' => 'skottilâš gaelikielâ',
 				'gez' => 'ge’ez',
 				'gil' => 'kiribatikielâ',
 				'gl' => 'galiciakielâ',
 				'gn' => 'guaranikielâ',
 				'gor' => 'gorontalokielâ',
 				'grc' => 'toovláš kreikakielâ',
 				'gsw' => 'Sveitsi saksakielâ',
 				'gu' => 'gudžaratikielâ',
 				'guz' => 'gusiikielâ',
 				'gv' => 'manks',
 				'gwi' => 'gwich’inkielâ',
 				'ha' => 'hausakielâ',
 				'haw' => 'hawaijikielâ',
 				'he' => 'hepreakielâ',
 				'hi' => 'hindikielâ',
 				'hil' => 'hiligainokielâ',
 				'hmn' => 'hmongkielâ',
 				'hr' => 'kroatiakielâ',
 				'hsb' => 'pajesorbi',
 				'ht' => 'Haiti kreoli',
 				'hu' => 'uŋgarkielâ',
 				'hup' => 'hupakielâ',
 				'hy' => 'armeniakielâ',
 				'hz' => 'hererokielâ',
 				'ia' => 'interlingua',
 				'iba' => 'ibankielâ',
 				'ibb' => 'ibibiokielâ',
 				'id' => 'indonesiakielâ',
 				'ig' => 'igbokielâ',
 				'ilo' => 'ilocano',
 				'inh' => 'inguškielâ',
 				'io' => 'ido',
 				'is' => 'islandkielâ',
 				'it' => 'italiakielâ',
 				'iu' => 'inuktitut',
 				'ja' => 'jaapaankielâ',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'machame',
 				'jv' => 'jaavakielâ',
 				'ka' => 'georgiakielâ',
 				'kab' => 'kabylkielâ',
 				'kac' => 'kachin',
 				'kaj' => 'jju',
 				'kam' => 'kambakielâ',
 				'kbd' => 'kabardikielâ',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'Kap Verde kreoli',
 				'kfo' => 'koro',
 				'kha' => 'khasi',
 				'khq' => 'koyra chiini',
 				'ki' => 'kikujukielâ',
 				'kj' => 'kuanjama',
 				'kk' => 'kazakkielâ',
 				'kkj' => 'kako',
 				'kl' => 'kalaallisut',
 				'kln' => 'kalenjikielâ',
 				'km' => 'khmerkielâ',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannada',
 				'ko' => 'koreakielâ',
 				'kok' => 'konkani',
 				'kpe' => 'kpellekielâ',
 				'kr' => 'kanurikielâ',
 				'krc' => 'karachai-balkarkielâ',
 				'krl' => 'kärjilkielâ',
 				'kru' => 'kurukhkielâ',
 				'ks' => 'kashmirkielâ',
 				'ksb' => 'shambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kölnkielâ',
 				'ku' => 'kurdikielâ',
 				'kum' => 'kumykkielâ',
 				'kv' => 'komikielâ',
 				'kw' => 'kornikielâ',
 				'ky' => 'kirgiskielâ',
 				'la' => 'läättinkielâ',
 				'lad' => 'ladinokielâ',
 				'lag' => 'langokielâ',
 				'lb' => 'luxemburgkielâ',
 				'lez' => 'lezgikielâ',
 				'lg' => 'luganda',
 				'li' => 'limburgkielâ',
 				'lkt' => 'lakotakielâ',
 				'ln' => 'lingala',
 				'lo' => 'laokielâ',
 				'loz' => 'lozi',
 				'lrc' => 'taveluri',
 				'lt' => 'liettuakielâ',
 				'lu' => 'katangaluba',
 				'lua' => 'lulualuba',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'lusai',
 				'luy' => 'luhya',
 				'lv' => 'latviakielâ',
 				'mad' => 'madurakielâ',
 				'mag' => 'magahi',
 				'mai' => 'maithili',
 				'mak' => 'makasar',
 				'mas' => 'masaikielâ',
 				'mdf' => 'mokšakielâ',
 				'men' => 'mendekielâ',
 				'mer' => 'merukielâ',
 				'mfe' => 'morisyen',
 				'mg' => 'malagaskielâ',
 				'mgh' => 'makua-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'marshallkielâ',
 				'mi' => 'maorikielâ',
 				'mic' => 'micmac',
 				'min' => 'minangkabau',
 				'mk' => 'makedoniakielâ',
 				'ml' => 'malajam',
 				'mn' => 'mongoliakielâ',
 				'mni' => 'manipuri',
 				'moh' => 'mohawkkielâ',
 				'mos' => 'moore',
 				'mr' => 'marathikielâ',
 				'mrj' => 'viestârmari',
 				'ms' => 'malaiji',
 				'mt' => 'maltakielâ',
 				'mua' => 'mundang',
 				'mul' => 'maŋgâ kielâ',
 				'mus' => 'muskogeekielâ',
 				'mwl' => 'mirandeskielâ',
 				'my' => 'burmakielâ',
 				'myv' => 'ersäkielâ',
 				'mzn' => 'mazandarani',
 				'na' => 'naurukielâ',
 				'nap' => 'napolikielâ',
 				'naq' => 'nama',
 				'nb' => 'tárukielâ bokmål',
 				'nd' => 'tave-nbedele',
 				'nds_NL' => 'Vuáládâhenâmij saksakielâ',
 				'ne' => 'nepalkielâ',
 				'new' => 'newari',
 				'ng' => 'ndonga',
 				'nia' => 'niaskielâ',
 				'niu' => 'niuekielâ',
 				'nl' => 'hollandkielâ',
 				'nl_BE' => 'hollandkielâ (flaami)',
 				'nmg' => 'kwasio',
 				'nn' => 'tárukielâ nynorsk',
 				'nnh' => 'ngiemboon',
 				'no' => 'tárukielâ',
 				'nog' => 'nogaikielâ',
 				'non' => 'toovláš tárukielâ',
 				'nqo' => 'n’ko',
 				'nr' => 'maadâ-nbedele',
 				'nso' => 'tavesotho',
 				'nus' => 'nuer',
 				'nv' => 'navajokielâ',
 				'ny' => 'njanža',
 				'nyn' => 'nyankolekielâ',
 				'oc' => 'oksitan',
 				'om' => 'oromokielâ',
 				'or' => 'orija',
 				'os' => 'ossetkielâ',
 				'pa' => 'pandžabi',
 				'pag' => 'pangasinankielâ',
 				'pam' => 'pampangakielâ',
 				'pap' => 'papiamentu',
 				'pau' => 'palaukielâ',
 				'pcm' => 'Nigeria pidgin',
 				'pl' => 'puolakielâ',
 				'prg' => 'toovláš preussikielâ',
 				'ps' => 'paštu',
 				'pt' => 'portugalkielâ',
 				'pt_BR' => 'Brasilia portugalkielâ',
 				'pt_PT' => 'Portugal portugalkielâ',
 				'qu' => 'quechua',
 				'quc' => 'ki’che’',
 				'rap' => 'rapanui',
 				'rar' => 'rarotonga',
 				'rm' => 'retoroomaankielâ',
 				'rn' => 'rundi',
 				'ro' => 'romaniakielâ',
 				'rof' => 'rombo',
 				'rom' => 'roomaankielâ',
 				'root' => 'ruotâs',
 				'ru' => 'ruošâkielâ',
 				'rup' => 'aromaniakielâ',
 				'rw' => 'ruandakielâ',
 				'rwk' => 'rwa',
 				'sa' => 'sanskrit',
 				'sad' => 'sandawe',
 				'sah' => 'jakutkielâ',
 				'saq' => 'samburukielâ',
 				'sat' => 'santalikielâ',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sardiniakielâ',
 				'scn' => 'sisiliakielâ',
 				'sco' => 'skootikielâ',
 				'sd' => 'sindhi',
 				'se' => 'tavekielâ',
 				'seh' => 'sena',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'shi' => 'tašelhit',
 				'shn' => 'shankielâ',
 				'si' => 'sinhala',
 				'sk' => 'slovakiakielâ',
 				'sl' => 'sloveniakielâ',
 				'sm' => 'samoakielâ',
 				'sma' => 'maadâsämikielâ',
 				'smj' => 'juulevsämikielâ',
 				'smn' => 'anarâškielâ',
 				'sms' => 'nuorttâlâškielâ',
 				'sn' => 'shona',
 				'snk' => 'soninke',
 				'so' => 'somalikielâ',
 				'sq' => 'albaniakielâ',
 				'sr' => 'serbiakielâ',
 				'srn' => 'sranantongo',
 				'ss' => 'swazikielâ',
 				'ssy' => 'saho',
 				'st' => 'maadâsotho',
 				'su' => 'sundakielâ',
 				'suk' => 'sukumakielâ',
 				'sv' => 'ruotâkielâ',
 				'sw' => 'swahilikielâ',
 				'sw_CD' => 'Kongo swahilikielâ',
 				'swb' => 'komorikielâ',
 				'syr' => 'syyriakielâ',
 				'ta' => 'tamilkielâ',
 				'te' => 'telugu',
 				'tem' => 'temnekielâ',
 				'teo' => 'ateso',
 				'tet' => 'tetum',
 				'tg' => 'tadžikkielâ',
 				'th' => 'thaikielâ',
 				'ti' => 'tigrinyakielâ',
 				'tig' => 'tigrekielâ',
 				'tk' => 'turkmenkielâ',
 				'tlh' => 'klingonkielâ',
 				'tn' => 'tswanakielâ',
 				'to' => 'tongakielâ',
 				'tpi' => 'tok pisin',
 				'tr' => 'tuurkikielâ',
 				'trv' => 'taroko',
 				'ts' => 'tsongakielâ',
 				'tt' => 'tatarkielâ',
 				'tum' => 'tumbukakielâ',
 				'tvl' => 'tuvalukielâ',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitikielâ',
 				'tyv' => 'tuvakielâ',
 				'tzm' => 'Koskâatlas tamazight',
 				'udm' => 'udmurtkielâ',
 				'ug' => 'uigurkielâ',
 				'uk' => 'ukrainakielâ',
 				'umb' => 'umbundu',
 				'und' => 'tubdâmettumis kielâ',
 				'ur' => 'urdu',
 				'uz' => 'uzbekkielâ',
 				'vai' => 'vaikielâ',
 				've' => 'vendakielâ',
 				'vep' => 'vepsäkielâ',
 				'vi' => 'vietnamkielâ',
 				'vo' => 'volapük',
 				'vun' => 'vunjo',
 				'wa' => 'walloonkielâ',
 				'wae' => 'walliskielâ',
 				'wal' => 'wolaitakielâ',
 				'war' => 'waraykielâ',
 				'wo' => 'wolofkielâ',
 				'xal' => 'kalmukkielâ',
 				'xh' => 'xhosakielâ',
 				'xog' => 'soga',
 				'yav' => 'yangben',
 				'ybb' => 'yemba',
 				'yi' => 'jiddish',
 				'yo' => 'yorubakielâ',
 				'yue' => 'kantonkielâ',
 				'zgh' => 'standard tamazight',
 				'zh' => 'mandarinkiinakielâ',
 				'zh_Hans' => 'oovtâkiärdánis kiinakielâ',
 				'zh_Hant' => 'ärbivuáválâš kiinakielâ',
 				'zu' => 'zulukielâ',
 				'zun' => 'zunikielâ',
 				'zxx' => 'ij kielâlâš siskáldâs',
 				'zza' => 'zazakielâ',

			);
			if (@_) {
				return $languages{$_[0]};
			}
			return \%languages;
		}
	},
);

has 'display_name_region' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'AC' => 'Ascension-suálui',
 			'AD' => 'Andorra',
 			'AE' => 'Arabiemirkodeh',
 			'AF' => 'Afganistan',
 			'AG' => 'Antigua já Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktis',
 			'AR' => 'Argentina',
 			'AS' => 'Amerika Samoa',
 			'AT' => 'Nuorttâriijkâ',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Vuáskueennâm',
 			'AZ' => 'Azerbaidžan',
 			'BA' => 'Bosnia já Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Belgia',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'St. Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivia',
 			'BR' => 'Brasilia',
 			'BS' => 'Bahama',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouvetsuálui',
 			'BW' => 'Botswana',
 			'BY' => 'Vielgis-Ruoššâ',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kookossuolluuh (Keelingsuolluuh)',
 			'CD@alt=variant' => 'Kongo demokraattisâš täsiväldi',
 			'CF' => 'Koskâ-Afrika täsiväldi',
 			'CG@alt=variant' => 'Kongo täsiväldi',
 			'CH' => 'Sveitsi',
 			'CI' => 'Côte d’Ivoire',
 			'CK' => 'Cooksuolluuh',
 			'CL' => 'Chile',
 			'CM' => 'Kamerun',
 			'CN' => 'Kiina',
 			'CO' => 'Kolumbia',
 			'CP' => 'Clippertonsuálui',
 			'CR' => 'Costa Rica',
 			'CU' => 'Kuuba',
 			'CV' => 'Cape Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Juovlâsuálui',
 			'CY' => 'Kypros',
 			'CZ' => 'Tšekki',
 			'DE' => 'Saksa',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Djibouti',
 			'DK' => 'Tanska',
 			'DM' => 'Dominica',
 			'DO' => 'Dominikaanisâš täsiväldi',
 			'DZ' => 'Algeria',
 			'EA' => 'Ceuta já Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Eestieennâm',
 			'EG' => 'Egypti',
 			'ER' => 'Eritrea',
 			'ES' => 'Espanja',
 			'ET' => 'Etiopia',
 			'FI' => 'Suomâ',
 			'FJ' => 'Fidži',
 			'FK' => 'Falklandsuolluuh',
 			'FK@alt=variant' => 'Falklandsuolluuh (Malvinassuolluuh)',
 			'FM' => 'Mikronesia littoväldi',
 			'FO' => 'Färsuolluuh',
 			'FR' => 'Ranska',
 			'GA' => 'Gabon',
 			'GB' => 'Ovtâstum Kunâgâskodde',
 			'GB@alt=short' => 'OK',
 			'GD' => 'Grenada',
 			'GE' => 'Georgia',
 			'GF' => 'Ranska Guyana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grönland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Peeivitäsideijee Guinea',
 			'GR' => 'Kreikka',
 			'GS' => 'Maadâ-Georgia já Máddááh Sandwichsuolluuh',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hongkong – Kiina e.h.k.',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Heard já McDonaldsuolluuh',
 			'HN' => 'Honduras',
 			'HR' => 'Kroatia',
 			'HT' => 'Haiti',
 			'HU' => 'Uŋgar',
 			'IC' => 'Kanariasuolluuh',
 			'ID' => 'Indonesia',
 			'IE' => 'Irland',
 			'IL' => 'Israel',
 			'IM' => 'Mansuálui',
 			'IN' => 'India',
 			'IO' => 'Brittilâš India väldimeerâ kuávlu',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Island',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordan',
 			'JP' => 'Jaapaan',
 			'KE' => 'Kenia',
 			'KG' => 'Kirgisia',
 			'KH' => 'Kambodža',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoreh',
 			'KN' => 'St. Kitts já Nevis',
 			'KP' => 'Tave-Korea',
 			'KR' => 'Maadâ-Korea',
 			'KW' => 'Kuwait',
 			'KY' => 'Caymansuolluuh',
 			'KZ' => 'Kazakstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'St. Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Liettua',
 			'LU' => 'Luxemburg',
 			'LV' => 'Latvia',
 			'LY' => 'Libya',
 			'MA' => 'Marokko',
 			'MC' => 'Monaco',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'St. Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshallsuolluuh',
 			'MK@alt=variant' => 'OJT Makedonia',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar (Burma)',
 			'MN' => 'Mongolia',
 			'MO' => 'Macao - – Kiina e.h.k.',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Tave-Marianeh',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Malediveh',
 			'MW' => 'Malawi',
 			'MX' => 'Meksiko',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mosambik',
 			'NA' => 'Namibia',
 			'NC' => 'Uđđâ-Kaledonia',
 			'NE' => 'Niger',
 			'NF' => 'Norfolksuálui',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Vuáládâhenâmeh',
 			'NO' => 'Taažâ',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Uđđâ-Seeland',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Ranska Polynesia',
 			'PG' => 'Papua-Uđđâ-Guinea',
 			'PH' => 'Filipineh',
 			'PK' => 'Pakistan',
 			'PL' => 'Puola',
 			'PM' => 'St. Pierre já Miquelon',
 			'PN' => 'Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'RE' => 'Réunion',
 			'RO' => 'Romania',
 			'RS' => 'Serbia',
 			'RU' => 'Ruoššâ',
 			'RW' => 'Ruanda',
 			'SA' => 'Saudi Arabia',
 			'SB' => 'Salomosuolluuh',
 			'SC' => 'Seychelleh',
 			'SD' => 'Sudan',
 			'SE' => 'Ruotâ',
 			'SG' => 'Singapore',
 			'SH' => 'Saint Helena',
 			'SI' => 'Slovenia',
 			'SJ' => 'Čokkeväärih já Jan Mayen',
 			'SK' => 'Slovakia',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinam',
 			'SS' => 'Maadâ-Sudan',
 			'ST' => 'São Tomé já Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syria',
 			'SZ' => 'Swazieennâm',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks- já Caicossuolluuh',
 			'TD' => 'Tšad',
 			'TF' => 'Ranska máddááh kuávluh',
 			'TG' => 'Togo',
 			'TH' => 'Thaieennâm',
 			'TJ' => 'Tadžikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunisia',
 			'TO' => 'Tonga',
 			'TR' => 'Turkki',
 			'TT' => 'Trinidad já Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tansania',
 			'UA' => 'Ukraina',
 			'UG' => 'Uganda',
 			'UM' => 'Ovtâstum Staatâi sierânâssuolluuh',
 			'US' => 'Ovtâstum Staatah',
 			'US@alt=short' => 'USA',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatikan',
 			'VC' => 'St. Vincent já Grenadines',
 			'VE' => 'Venezuela',
 			'VG' => 'Brittiliih Nieidâsuolluuh',
 			'VI' => 'Ovtâstum Staatâi Nieidâsuolluuh',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis já Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Maadâ-Afrikka',
 			'ZM' => 'Sambia',
 			'ZW' => 'Zimbabwe',

		}
	},
);

has 'display_name_measurement_system' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'metric' => q{metrisâš},
 			'UK' => q{brittilâš},
 			'US' => q{ameriklâš},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'kielâ: {0}',
 			'script' => 'čäällimvuáhádâh: {0}',
 			'region' => 'kuávlu: {0}',

		}
	},
);

has 'text_orientation' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { return {
			lines => 'top-to-bottom',
			characters => 'left-to-right',
		}}
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
			auxiliary => qr{[à ç é è í ñ ń ó ò q ú ü w x æ ø å ã ö]},
			index => ['A', 'Â', 'B', 'C', 'Č', 'D', 'Đ', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'P', 'R', 'S', 'Š', 'T', 'U', 'V', 'Y', 'Z', 'Ž', 'Ä', 'Á'],
			main => qr{[a â b c č d đ e f g h i j k l m n ŋ o p r s š t u v y z ž ä á]},
			numbers => qr{[  \- , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
		};
	},
EOT
: sub {
		return { index => ['A', 'Â', 'B', 'C', 'Č', 'D', 'Đ', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ŋ', 'O', 'P', 'R', 'S', 'Š', 'T', 'U', 'V', 'Y', 'Z', 'Ž', 'Ä', 'Á'], };
},
);


has 'units' => (
	is			=> 'ro',
	isa			=> HashRef[HashRef[HashRef[Str]]],
	init_arg	=> undef,
	default		=> sub { {
				'long' => {
					'day' => {
						'name' => q(peeivih),
					},
					'hour' => {
						'name' => q(tiijmeh),
					},
					'microsecond' => {
						'name' => q(mikrosekunteh),
						'one' => q({0} μs),
						'other' => q({0} μs),
						'two' => q({0} μs),
					},
					'millisecond' => {
						'name' => q(millisekunteh),
					},
					'minute' => {
						'name' => q(minutteh),
					},
					'month' => {
						'name' => q(mánuppajeh),
					},
					'nanosecond' => {
						'name' => q(nanosekunteh),
					},
					'second' => {
						'name' => q(sekunteh),
					},
					'week' => {
						'name' => q(ohoh),
					},
					'year' => {
						'name' => q(iveh),
					},
				},
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
			'group' => q( ),
			'infinity' => q(∞),
			'minusSign' => q(-),
			'nan' => q(epiloho),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
			'superscriptingExponent' => q(×),
			'timeSeparator' => q(.),
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
					'one' => '0 tuhháát',
					'other' => '0 tuhháát',
					'two' => '0 tuhháát',
				},
				'10000' => {
					'one' => '00 tuhháát',
					'other' => '00 tuhháát',
					'two' => '00 tuhháát',
				},
				'100000' => {
					'one' => '000 tuhháát',
					'other' => '000 tuhháát',
					'two' => '000 tuhháát',
				},
				'1000000' => {
					'one' => '0 miljovn',
					'other' => '0 miljovn',
					'two' => '0 miljovn',
				},
				'10000000' => {
					'one' => '00 miljovn',
					'other' => '00 miljovn',
					'two' => '00 miljovn',
				},
				'100000000' => {
					'one' => '000 miljovn',
					'other' => '000 miljovn',
					'two' => '000 miljovn',
				},
				'1000000000' => {
					'one' => '0 miljard',
					'other' => '0 miljard',
					'two' => '0 miljard',
				},
				'10000000000' => {
					'one' => '00 miljard',
					'other' => '00 miljard',
					'two' => '00 miljard',
				},
				'100000000000' => {
					'one' => '000 miljard',
					'other' => '000 miljard',
					'two' => '000 miljard',
				},
				'1000000000000' => {
					'one' => '0 biljovn',
					'other' => '0 biljovn',
					'two' => '0 biljovn',
				},
				'10000000000000' => {
					'one' => '00 biljovn',
					'other' => '00 biljovn',
					'two' => '00 biljovn',
				},
				'100000000000000' => {
					'one' => '000 biljovn',
					'other' => '000 biljovn',
					'two' => '000 biljovn',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 tuhháát',
					'other' => '0 tuhháát',
					'two' => '0 tuhháát',
				},
				'10000' => {
					'one' => '00 tuhháát',
					'other' => '00 tuhháát',
					'two' => '00 tuhháát',
				},
				'100000' => {
					'one' => '000 tuhháát',
					'other' => '000 tuhháát',
					'two' => '000 tuhháát',
				},
				'1000000' => {
					'one' => '0 miljovn',
					'other' => '0 miljovn',
					'two' => '0 miljovn',
				},
				'10000000' => {
					'one' => '00 miljovn',
					'other' => '00 miljovn',
					'two' => '00 miljovn',
				},
				'100000000' => {
					'one' => '000 miljovn',
					'other' => '000 miljovn',
					'two' => '000 miljovn',
				},
				'1000000000' => {
					'one' => '0 miljard',
					'other' => '0 miljard',
					'two' => '0 miljard',
				},
				'10000000000' => {
					'one' => '00 miljard',
					'other' => '00 miljard',
					'two' => '00 miljard',
				},
				'100000000000' => {
					'one' => '000 miljard',
					'other' => '000 miljard',
					'two' => '000 miljard',
				},
				'1000000000000' => {
					'one' => '0 biljovn',
					'other' => '0 biljovn',
					'two' => '0 biljovn',
				},
				'10000000000000' => {
					'one' => '00 biljovn',
					'other' => '00 biljovn',
					'two' => '00 biljovn',
				},
				'100000000000000' => {
					'one' => '000 biljovn',
					'other' => '000 biljovn',
					'two' => '000 biljovn',
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
		'DKK' => {
			display_name => {
				'currency' => q(Tanska ruvnâ),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Eesti ruvnâ),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Suomâ märkki),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Island ruvnâ),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Latvia ruble),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Taažâ ruvnâ),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Ruotâ ruvnâ),
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
							'uđiv',
							'kuovâ',
							'njuhčâ',
							'cuáŋui',
							'vyesi',
							'kesi',
							'syeini',
							'porge',
							'čohčâ',
							'roovvâd',
							'skammâ',
							'juovlâ'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'U',
							'K',
							'NJ',
							'C',
							'V',
							'K',
							'S',
							'P',
							'Č',
							'R',
							'S',
							'J'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'uđđâivemáánu',
							'kuovâmáánu',
							'njuhčâmáánu',
							'cuáŋuimáánu',
							'vyesimáánu',
							'kesimáánu',
							'syeinimáánu',
							'porgemáánu',
							'čohčâmáánu',
							'roovvâdmáánu',
							'skammâmáánu',
							'juovlâmáánu'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'uđiv',
							'kuovâ',
							'njuhčâ',
							'cuáŋui',
							'vyesi',
							'kesi',
							'syeini',
							'porge',
							'čohčâ',
							'roovvâd',
							'skammâ',
							'juovlâ'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'U',
							'K',
							'NJ',
							'C',
							'V',
							'K',
							'S',
							'P',
							'Č',
							'R',
							'S',
							'J'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'uđđâivemáánu',
							'kuovâmáánu',
							'njuhčâmáánu',
							'cuáŋuimáánu',
							'vyesimáánu',
							'kesimáánu',
							'syeinimáánu',
							'porgemáánu',
							'čohčâmáánu',
							'roovvâdmáánu',
							'skammâmáánu',
							'juovlâmáánu'
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
						mon => 'vuo',
						tue => 'maj',
						wed => 'kos',
						thu => 'tuo',
						fri => 'vás',
						sat => 'láv',
						sun => 'pas'
					},
					narrow => {
						mon => 'V',
						tue => 'M',
						wed => 'K',
						thu => 'T',
						fri => 'V',
						sat => 'L',
						sun => 'p'
					},
					short => {
						mon => 'vu',
						tue => 'ma',
						wed => 'ko',
						thu => 'tu',
						fri => 'vá',
						sat => 'lá',
						sun => 'pa'
					},
					wide => {
						mon => 'vuossaargâ',
						tue => 'majebaargâ',
						wed => 'koskoho',
						thu => 'tuorâstuv',
						fri => 'vástuppeeivi',
						sat => 'lávurduv',
						sun => 'pasepeeivi'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'vuo',
						tue => 'maj',
						wed => 'kos',
						thu => 'tuo',
						fri => 'vás',
						sat => 'láv',
						sun => 'pas'
					},
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'W',
						thu => 'T',
						fri => 'F',
						sat => 'S',
						sun => 'S'
					},
					short => {
						mon => 'vu',
						tue => 'ma',
						wed => 'ko',
						thu => 'tu',
						fri => 'vá',
						sat => 'lá',
						sun => 'pa'
					},
					wide => {
						mon => 'vuossargâ',
						tue => 'majebargâ',
						wed => 'koskokko',
						thu => 'tuorâstâh',
						fri => 'vástuppeivi',
						sat => 'lávurdâh',
						sun => 'pasepeivi'
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
					abbreviated => {0 => '1. niälj.',
						1 => '2. niälj.',
						2 => '3. niälj.',
						3 => '4. niälj.'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1. niäljádâs',
						1 => '2. niäljádâs',
						2 => '3. niäljádâs',
						3 => '4. niäljádâs'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1. niälj.',
						1 => '2. niälj.',
						2 => '3. niälj.',
						3 => '4. niälj.'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1. niäljádâs',
						1 => '2. niäljádâs',
						2 => '3. niäljádâs',
						3 => '4. niäljádâs'
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
					'am' => q{ip.},
					'pm' => q{ep.},
				},
				'narrow' => {
					'am' => q{ip.},
					'pm' => q{ep.},
				},
				'wide' => {
					'am' => q{ip.},
					'pm' => q{ep.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{ip.},
					'pm' => q{ep.},
				},
				'narrow' => {
					'am' => q{ip.},
					'pm' => q{ep.},
				},
				'wide' => {
					'am' => q{ip.},
					'pm' => q{ep.},
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
				'0' => 'oKr.',
				'1' => 'mKr.'
			},
			wide => {
				'0' => 'Ovdil Kristus šoddâm',
				'1' => 'maŋa Kristus šoddâm'
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
			'full' => q{cccc MMMM d. y G},
			'long' => q{MMMM d. y G},
			'medium' => q{d.M.y G},
			'short' => q{d.M.y GGGGG},
		},
		'gregorian' => {
			'full' => q{cccc, MMMM d. y},
			'long' => q{MMMM d. y},
			'medium' => q{MMM d. y},
			'short' => q{d.M.y},
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
			'full' => q{H.mm.ss zzzz},
			'long' => q{H.mm.ss z},
			'medium' => q{H.mm.ss},
			'short' => q{H.mm},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{{1} 'tme' {0}},
			'long' => q{{1} 'tme' {0}},
			'medium' => q{{1} 'tme' {0}},
			'short' => q{{1} {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'tme' {0}},
			'long' => q{{1} 'tme' {0}},
			'medium' => q{{1} 'tme' {0}},
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
			Ed => q{E d.},
			Gy => q{y G},
			GyMMM => q{LLL y G},
			GyMMMEd => q{E MMM d. y G},
			GyMMMd => q{MMM d. y G},
			M => q{L},
			MEd => q{E d.M.},
			MMM => q{LLL},
			MMMEd => q{ccc MMM d.},
			MMMMd => q{d. MMMM},
			MMMd => q{MMM d.},
			Md => q{d.M.},
			d => q{d},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{L.y G},
			yyyyMEd => q{E d.M.y G},
			yyyyMMM => q{LLL y G},
			yyyyMMMEd => q{E MMM d. y G},
			yyyyMMMM => q{LLLL y G},
			yyyyMMMd => q{MMM d. y G},
			yyyyMd => q{d.M.y G},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			E => q{ccc},
			EHm => q{E H.mm},
			EHms => q{E H.mm.ss},
			Ed => q{E d.},
			Ehm => q{E h.mm a},
			Ehms => q{E h.mm.ss a},
			Gy => q{y G},
			GyMMM => q{LLL y G},
			GyMMMEd => q{E, MMM d. y G},
			GyMMMd => q{MMM d. y G},
			H => q{H},
			Hm => q{H.mm},
			Hms => q{H.mm.ss},
			Hmsv => q{H.mm.ss v},
			Hmv => q{H.mm v},
			M => q{L},
			MEd => q{E d.M.},
			MMM => q{LLL},
			MMMEd => q{E, MMM d.},
			MMMMW => q{'okko' W, MMM},
			MMMMd => q{MMMM d.},
			MMMd => q{MMM d.},
			Md => q{d.M.},
			d => q{d},
			h => q{h a},
			hm => q{h.mm a},
			hms => q{h.mm.ss a},
			hmsv => q{h.mm.ss a v},
			hmv => q{h.mm a v},
			ms => q{m.ss.},
			y => q{y},
			yM => q{L.y},
			yMEd => q{E d.M.y},
			yMMM => q{LLL y},
			yMMMEd => q{ccc, MMM d. y},
			yMMMM => q{LLLL y},
			yMMMd => q{MMM d. y},
			yMd => q{d.M.y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'okko' w, Y},
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
			M => {
				M => q{L.–L.},
			},
			MEd => {
				M => q{E d.M. – E d.M.},
				d => q{E d. – E d.M.},
			},
			MMM => {
				M => q{LLL–LLLL},
			},
			MMMEd => {
				M => q{MMMM E d. – MMMM E d.},
				d => q{MMMM E d. – E d.},
			},
			MMMd => {
				M => q{MMMM d. – MMMM d.},
				d => q{MMMM d.–d.},
			},
			Md => {
				M => q{d.M.–d.M.},
				d => q{d.–d.M.},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0} – {1}',
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{LLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMEd => {
				M => q{E d.M.y – E d.M.y G},
				d => q{E d.M.y – E d.M.y G},
				y => q{E d.M.y – E d.M.y G},
			},
			yMMM => {
				M => q{LLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMEd => {
				M => q{MMMM E d. – MMMM E d. y G},
				d => q{MMMM E d. – E d. y G},
				y => q{MMMM E d. y – MMMM E d. y G},
			},
			yMMMM => {
				M => q{LLL–LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{MMMM d. – MMMM d. y G},
				d => q{MMMM d.–d. y G},
				y => q{MMMM d. y – MMMM d. y G},
			},
			yMd => {
				M => q{d.M.–d.M.y G},
				d => q{d.–d.M.y G},
				y => q{d.M.y–d.M.y G},
			},
		},
		'gregorian' => {
			H => {
				H => q{H–H},
			},
			Hm => {
				H => q{H.mm–H.mm},
				m => q{H.mm–H.mm},
			},
			Hmv => {
				H => q{H.mm–H.mm v},
				m => q{H.mm–H.mm v},
			},
			Hv => {
				H => q{H–H v},
			},
			M => {
				M => q{L.–L.},
			},
			MEd => {
				M => q{E d.M. – E d.M.},
				d => q{E d. – E d.M.},
			},
			MMM => {
				M => q{LLL–LLLL},
			},
			MMMEd => {
				M => q{MMMM E d. – MMMM E d.},
				d => q{MMMM E d. – E d.},
			},
			MMMd => {
				M => q{MMM d. – MMM d.},
				d => q{MMM d.–d.},
			},
			Md => {
				M => q{d.M.–d.M.},
				d => q{d.–d.M.},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0}–{1}',
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h.mm a – h.mm a},
				h => q{h.mm–h.mm a},
				m => q{h.mm–h.mm a},
			},
			hmv => {
				a => q{h.mm a – h.mm a v},
				h => q{h.mm–h.mm a v},
				m => q{h.mm–h.mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			y => {
				y => q{y–y},
			},
			yM => {
				M => q{LLL–LLLL y},
				y => q{LLLL y – LLLL y},
			},
			yMEd => {
				M => q{E d.M.y – E d.M.y},
				d => q{E d.M.y – E d.M.y},
				y => q{E d.M.y – E d.M.y},
			},
			yMMM => {
				M => q{LLL–LLLL y},
				y => q{LLLL y – LLLL y},
			},
			yMMMEd => {
				M => q{MMMM E d. – MMMM E d. y},
				d => q{MMMM E d. – E d. y},
				y => q{MMMM E d. y – MMMM E d. y},
			},
			yMMMM => {
				M => q{LLL–LLLL y},
				y => q{LLLL y – LLLL y},
			},
			yMMMd => {
				M => q{MMMM d. – MMMM d. y},
				d => q{MMMM d.–d. y},
				y => q{MMMM d. y – MMMM d. y},
			},
			yMd => {
				M => q{d.M.–d.M.y},
				d => q{d. – d.M.y},
				y => q{d.M.y–d.M.y},
			},
		},
	} },
);

no Moo;

1;

# vim: tabstop=4
