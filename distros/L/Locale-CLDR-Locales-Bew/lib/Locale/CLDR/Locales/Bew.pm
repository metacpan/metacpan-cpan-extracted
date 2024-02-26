=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Bew - Package for language Betawi

=cut

package Locale::CLDR::Locales::Bew;
# This file auto generated from Data\common\main\bew.xml
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
				'aa' => 'Apar',
 				'ab' => 'Abhasi',
 				'ace' => 'Acéh',
 				'ada' => 'Adangmé',
 				'ady' => 'Adigé',
 				'af' => 'Aprikan',
 				'agq' => 'Agèm',
 				'ain' => 'Ainu',
 				'ak' => 'Akan',
 				'ale' => 'Aléut',
 				'alt' => 'Altay Kidul',
 				'am' => 'Amhar',
 				'an' => 'Aragon',
 				'ann' => 'Obolo',
 				'anp' => 'Anggika',
 				'apc' => 'Arab Sam',
 				'ar' => 'Arab',
 				'ar_001' => 'Arab Pusha Modèren',
 				'arn' => 'Mapucé',
 				'arp' => 'Arapaho',
 				'ars' => 'Arab Nèjed',
 				'as' => 'Asam',
 				'asa' => 'Asu',
 				'ast' => 'Asturi',
 				'atj' => 'Atikamèk',
 				'av' => 'Awar',
 				'awa' => 'Awad',
 				'ay' => 'Aymara',
 				'az' => 'Asèrbaijan',
 				'az@alt=short' => 'Asèri',
 				'ba' => 'Baskir',
 				'bal' => 'Beluci',
 				'ban' => 'Bali',
 				'bas' => 'Mbéné',
 				'be' => 'Rus Puti',
 				'bem' => 'Bèmba',
 				'bew' => 'Betawi',
 				'bez' => 'Béna',
 				'bg' => 'Bulgari',
 				'bgc' => 'Haryanwi',
 				'bgn' => 'Beluci Kulon',
 				'bho' => 'Bojapur',
 				'bi' => 'Bislama',
 				'bin' => 'Bini',
 				'bla' => 'Siksika',
 				'blo' => 'Ani',
 				'blt' => 'Tay Item',
 				'bm' => 'Bambara',
 				'bn' => 'Benggala',
 				'bo' => 'Tibèt',
 				'br' => 'Brèton',
 				'brx' => 'Boro',
 				'bs' => 'Bosni',
 				'bss' => 'Akosé',
 				'bug' => 'Bugis',
 				'byn' => 'Belin',
 				'ca' => 'Katalan',
 				'cad' => 'Kado',
 				'cay' => 'Kayuga',
 				'cch' => 'Atsam',
 				'ccp' => 'Cakma',
 				'ce' => 'Cècèn',
 				'ceb' => 'Sébu',
 				'cgg' => 'Kiga',
 				'ch' => 'Camoro',
 				'chk' => 'Cuk',
 				'chm' => 'Mari',
 				'cho' => 'Cokto',
 				'chp' => 'Cipewéan',
 				'chr' => 'Cèroki',
 				'chy' => 'Sèyèn',
 				'cic' => 'Cikaso',
 				'ckb' => 'Kurdi Sorani',
 				'ckb@alt=menu' => 'Kurdi, Sorani',
 				'ckb@alt=variant' => 'Kurdi, Tenga',
 				'clc' => 'Cilkotin',
 				'co' => 'Korsikan',
 				'crg' => 'Micip',
 				'crj' => 'Kri Wètan Kidul',
 				'crk' => 'Kri Dataran',
 				'crl' => 'Kri Wètan Lor',
 				'crm' => 'Kri Musoni',
 				'crr' => 'Algonkin Karolina',
 				'cs' => 'Cèk',
 				'csw' => 'Kri Rawa',
 				'cu' => 'Slawen Gerèja',
 				'cv' => 'Cuwas',
 				'cy' => 'Walès',
 				'da' => 'Dèn',
 				'dak' => 'Dakota',
 				'dar' => 'Dargin',
 				'dav' => 'Taita',
 				'de' => 'Dèt',
 				'de_CH' => 'Dèt Atas (Switserlan)',
 				'dgr' => 'Dogrib',
 				'dje' => 'Jarma',
 				'doi' => 'Dograb',
 				'dsb' => 'Sorben Bawa',
 				'dua' => 'Duala',
 				'dv' => 'Diwéhi',
 				'dyo' => 'Jola-Poni',
 				'dz' => 'Jongka',
 				'dzg' => 'Daja',
 				'ebu' => 'Èmbu',
 				'ee' => 'Éwé',
 				'efi' => 'Èpik',
 				'eka' => 'Èkajuk',
 				'el' => 'Yunani',
 				'en' => 'Inggris',
 				'en_GB' => 'Inggris (Britani)',
 				'en_GB@alt=short' => 'Inggris (Kerajaan Rempug)',
 				'eo' => 'Èspèranto',
 				'es' => 'Spanyol',
 				'es_ES' => 'Spanyol (Èropa)',
 				'et' => 'Èst',
 				'eu' => 'Basken',
 				'ewo' => 'Èwondo',
 				'fa' => 'Parsi',
 				'fa_AF' => 'Parsi Dari',
 				'ff' => 'Pula',
 				'fi' => 'Pin',
 				'fil' => 'Pilipèn',
 				'fj' => 'Piji',
 				'fo' => 'Perower',
 				'fon' => 'Pon',
 				'fr' => 'Prasman',
 				'frc' => 'Prasman Kajen',
 				'frr' => 'Pris Lor',
 				'fur' => 'Priuli',
 				'fy' => 'Pris Kulon',
 				'ga' => 'Ir',
 				'gaa' => 'Gang',
 				'gd' => 'Gaèlik Skot',
 				'gez' => 'Gé’ès',
 				'gil' => 'Gilbet',
 				'gl' => 'Galisi',
 				'gn' => 'Guarani',
 				'gor' => 'Gorontalo',
 				'gsw' => 'Dèt Switserlan',
 				'gu' => 'Gujarat',
 				'guz' => 'Gusi',
 				'gv' => 'Man',
 				'gwi' => 'Kucin',
 				'ha' => 'Hausa',
 				'hai' => 'Héda',
 				'haw' => 'Hawai',
 				'hax' => 'Héda Kidul',
 				'he' => 'Ibrani',
 				'hi' => 'Hindi',
 				'hi_Latn@alt=variant' => 'Hindi-Inggris',
 				'hil' => 'Ilonggo',
 				'hmn' => 'Mong',
 				'hnj' => 'Mong Njua',
 				'hr' => 'Kroat',
 				'hsb' => 'Sorben Atas',
 				'ht' => 'Kréol Haiti',
 				'hu' => 'Honggari',
 				'hup' => 'Hupa',
 				'hur' => 'Halkomélem',
 				'hy' => 'Lemènder',
 				'hz' => 'Hèrèro',
 				'ia' => 'Interlingua',
 				'iba' => 'Iban',
 				'ibb' => 'Ibibio',
 				'id' => 'Indonésia',
 				'ie' => 'Anterkulonan',
 				'ig' => 'Ibo',
 				'ii' => 'I Sucoan',
 				'ikt' => 'Inuktitut Kanada Kulon',
 				'ilo' => 'Iloko',
 				'inh' => 'Inggusèti',
 				'io' => 'Ido',
 				'is' => 'Èslan',
 				'it' => 'Itali',
 				'iu' => 'Inuktitut',
 				'ja' => 'Jepang',
 				'jbo' => 'Lojeban',
 				'jgo' => 'Nggomba',
 				'jmc' => 'Masamé',
 				'jv' => 'Jawa',
 				'ka' => 'Géorgi',
 				'kab' => 'Kabili',
 				'kac' => 'Kacin',
 				'kaj' => 'Kajé',
 				'kam' => 'Kamba',
 				'kbd' => 'Kabardèn',
 				'kcg' => 'Tiap',
 				'kde' => 'Makondé',
 				'kea' => 'Tanjung Ijo',
 				'ken' => 'Kènyang',
 				'kfo' => 'Koro',
 				'kgp' => 'Kaingang',
 				'kha' => 'Kasi',
 				'khq' => 'Koyra Cini',
 				'ki' => 'Gikuyu',
 				'kj' => 'Kuanyama',
 				'kk' => 'Kasak',
 				'kkj' => 'Kako',
 				'kl' => 'Grunlan',
 				'kln' => 'Kalenjin',
 				'km' => 'Kemboja',
 				'kmb' => 'Mbundu',
 				'kn' => 'Kenada',
 				'ko' => 'Koréa',
 				'kok' => 'Kongkani',
 				'kpe' => 'Kepèle',
 				'kr' => 'Kenuri',
 				'krc' => 'Karacé-Balkar',
 				'krl' => 'Karèli',
 				'kru' => 'Kuruk',
 				'ks' => 'Kasmir',
 				'ksb' => 'Sambala',
 				'ksf' => 'Bapia',
 				'ksh' => 'Kèl',
 				'ku' => 'Kurdi',
 				'kum' => 'Kumuk',
 				'kv' => 'Komi',
 				'kw' => 'Kornis',
 				'kwk' => 'Kuakuala',
 				'kxv' => 'Kuwi',
 				'ky' => 'Kirgis',
 				'la' => 'Latin',
 				'lad' => 'Spanyol Yahudi',
 				'lag' => 'Langgi',
 				'lb' => 'Leksembereh',
 				'lez' => 'Lèsgi',
 				'lg' => 'Uganda',
 				'li' => 'Limbereh',
 				'lij' => 'Liguri',
 				'lil' => 'Lilowèt',
 				'lkt' => 'Lakota',
 				'lmo' => 'Lombardi',
 				'ln' => 'Linggala',
 				'lo' => 'Laos',
 				'lou' => 'Kréol Luisiana',
 				'loz' => 'Losi',
 				'lrc' => 'Lur Lor',
 				'lsm' => 'Samia',
 				'lt' => 'Litowen',
 				'lu' => 'Luba-Katangga',
 				'lua' => 'Luba-Lulua',
 				'lun' => 'Lunda',
 				'luo' => 'Luo',
 				'lus' => 'Miso',
 				'luy' => 'Luhia',
 				'lv' => 'Lèt',
 				'mad' => 'Medura',
 				'mag' => 'Magahi',
 				'mai' => 'Métili',
 				'mak' => 'Makasar',
 				'mas' => 'Masé',
 				'mdf' => 'Moksa',
 				'men' => 'Mèndé',
 				'mer' => 'Mèru',
 				'mfe' => 'Kréol Moritius',
 				'mg' => 'Madagaskar',
 				'mgh' => 'Makhuwa-Mèto',
 				'mgo' => 'Mèta’',
 				'mh' => 'Marsal',
 				'mi' => 'Maori',
 				'mic' => 'Mikmak',
 				'min' => 'Minangkabo',
 				'mk' => 'Makèdoni',
 				'ml' => 'Malayalam',
 				'mn' => 'Monggol',
 				'mni' => 'Manipur',
 				'moe' => 'Inu-aimun',
 				'moh' => 'Mohak',
 				'mos' => 'Moré',
 				'mr' => 'Marati',
 				'ms' => 'Melayu',
 				'mt' => 'Malta',
 				'mua' => 'Mundang',
 				'mul' => 'Beberapa basa',
 				'mus' => 'Muskogi',
 				'mwl' => 'Miranda',
 				'my' => 'Birma',
 				'myv' => 'Èrsia',
 				'mzn' => 'Majandaran (Tabari)',
 				'na' => 'Nauru',
 				'nap' => 'Néapolitan',
 				'naq' => 'Nama',
 				'nb' => 'Nor Buku',
 				'nd' => 'Ndebélé Lor',
 				'nds' => 'Dèt Bawa',
 				'nds_NL' => 'Saksen Bawa',
 				'ne' => 'Népal',
 				'new' => 'Néwar',
 				'ng' => 'Ndongga',
 				'nia' => 'Nias',
 				'niu' => 'Niué',
 				'nl' => 'Belanda',
 				'nl_BE' => 'Plam',
 				'nmg' => 'Ngumba',
 				'nn' => 'Nor Baru',
 				'nnh' => 'Nggièmbong',
 				'no' => 'Nor',
 				'nog' => 'Nogay',
 				'nqo' => 'Ngko',
 				'nr' => 'Ndebélé Kidul',
 				'nso' => 'Soto Lor',
 				'nus' => 'Nuwer',
 				'nv' => 'Nabaho',
 				'ny' => 'Cicèwa',
 				'nyn' => 'Nyangkolé',
 				'oc' => 'Oksitan',
 				'ojb' => 'Ojibwé Lor-kulon',
 				'ojc' => 'Ojibwé Tenga',
 				'ojs' => 'Ojibwé Lor',
 				'ojw' => 'Ojibwé Kulon',
 				'oka' => 'Okanagan',
 				'om' => 'Oromo',
 				'or' => 'Oria',
 				'os' => 'Osèti',
 				'osa' => 'Osèt',
 				'pa' => 'Panjab',
 				'pag' => 'Pangasinan',
 				'pam' => 'Kapampangan',
 				'pap' => 'Papiamèn',
 				'pau' => 'Palau',
 				'pcm' => 'Pijin Nigéria',
 				'pis' => 'Pijin',
 				'pl' => 'Pol',
 				'pqm' => 'Malisèt-Pasamakuodi',
 				'prg' => 'Près',
 				'ps' => 'Pastun',
 				'pt' => 'Portugis',
 				'pt_PT' => 'Portugis (Èropa)',
 				'qu' => 'Kécua',
 				'quc' => 'Kicé’',
 				'raj' => 'Rajastan',
 				'rap' => 'Rapanui',
 				'rar' => 'Rarotongan',
 				'rhg' => 'Rohingya',
 				'rif' => 'Ripèn',
 				'rm' => 'Réto-Roman',
 				'rn' => 'Burundi',
 				'ro' => 'Rumèn',
 				'rof' => 'Rombo',
 				'ru' => 'Rus',
 				'rup' => 'Arumèn',
 				'rw' => 'Ruanda',
 				'rwk' => 'Rua',
 				'sa' => 'Sangsekerta',
 				'sad' => 'Sandawé',
 				'sah' => 'Yakut',
 				'saq' => 'Samburu',
 				'sat' => 'Santal',
 				'sba' => 'Ngambay',
 				'sbp' => 'Sanggu',
 				'sc' => 'Sardèn',
 				'scn' => 'Sisilian',
 				'sco' => 'Skot',
 				'sd' => 'Sind',
 				'sdh' => 'Kurdi Kidul',
 				'se' => 'Samen Lor',
 				'seh' => 'Séna',
 				'ses' => 'Koyra Sèni',
 				'sg' => 'Sanggo',
 				'shi' => 'Salha',
 				'shn' => 'San',
 				'si' => 'Singala',
 				'sid' => 'Sidama',
 				'sk' => 'Slowak',
 				'skr' => 'Saraiki',
 				'sl' => 'Slowèn',
 				'slh' => 'Lusutsid Kidul',
 				'sm' => 'Samoa',
 				'sma' => 'Sami Kidul',
 				'smj' => 'Sami Lule',
 				'smn' => 'Samen Inari',
 				'sms' => 'Sami Skolet',
 				'sn' => 'Sona',
 				'snk' => 'Soningké',
 				'so' => 'Somali',
 				'sq' => 'Albani',
 				'sr' => 'Sèrwi',
 				'srn' => 'Suriname',
 				'ss' => 'Swasi',
 				'ssy' => 'Saho',
 				'st' => 'Soto Kidul',
 				'str' => 'Sélis Selat',
 				'su' => 'Sunda',
 				'suk' => 'Sukuma',
 				'sv' => 'Swèd',
 				'sw' => 'Swahili',
 				'swb' => 'Komori',
 				'syr' => 'Suryani',
 				'szl' => 'Silési',
 				'ta' => 'Tamil',
 				'tce' => 'Tuconé Kidul',
 				'te' => 'Telugu',
 				'tem' => 'Tèmné',
 				'teo' => 'Téso',
 				'tet' => 'Tétun',
 				'tg' => 'Tajik',
 				'tgx' => 'Tagis',
 				'th' => 'Siam',
 				'tht' => 'Taltan',
 				'ti' => 'Tigrinya',
 				'tig' => 'Tigré',
 				'tk' => 'Turkmèn',
 				'tlh' => 'Klingon',
 				'tli' => 'Klingkit',
 				'tn' => 'Swana',
 				'to' => 'Tonga',
 				'tok' => 'Toki Pona',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Turki',
 				'trv' => 'Taroko',
 				'trw' => 'Torwali',
 				'ts' => 'Songga',
 				'tt' => 'Tatar',
 				'ttm' => 'Tuconé Lor',
 				'tum' => 'Tumbuka',
 				'tvl' => 'Tuwalu',
 				'twq' => 'Tasawak',
 				'ty' => 'Tahiti',
 				'tyv' => 'Tuwin',
 				'tzm' => 'Bèrbèr Atlas Tenga',
 				'udm' => 'Udmut',
 				'ug' => 'Uigur',
 				'uk' => 'Ukrain',
 				'umb' => 'Umbundu',
 				'und' => 'Basa Kaga’ Ditauin',
 				'ur' => 'Urdu',
 				'uz' => 'Usbèk',
 				'vai' => 'Wai',
 				've' => 'Wènda',
 				'vec' => 'Wènèsi',
 				'vi' => 'Piètnam',
 				'vmw' => 'Makua',
 				'vo' => 'Wolapik',
 				'vun' => 'Wunjo',
 				'wa' => 'Wal',
 				'wae' => 'Walser',
 				'wal' => 'Wolaita',
 				'war' => 'Waray',
 				'wbp' => 'Warelpiri',
 				'wo' => 'Wolop',
 				'wuu' => 'Wu',
 				'xal' => 'Kalmuk',
 				'xh' => 'Kosa',
 				'xnr' => 'Kanggri',
 				'xog' => 'Soga',
 				'yav' => 'Yangbèn',
 				'ybb' => 'Yémba',
 				'yi' => 'Dèt Yahudi',
 				'yo' => 'Yoruba',
 				'yrl' => 'Nyè’èngatu',
 				'yue' => 'Kanton',
 				'yue@alt=menu' => 'Tionghoa, Kanton',
 				'zgh' => 'Bèrbèr Maroko Pakem',
 				'zh' => 'Tionghoa',
 				'zh@alt=menu' => 'Tionghoa, Mandarin',
 				'zh_Hans@alt=long' => 'Mandarin (Ringkes)',
 				'zh_Hant@alt=long' => 'Mandarin (Terdisionil)',
 				'zu' => 'Julu',
 				'zun' => 'Suni',
 				'zxx' => 'Kaga’ ada isi kebasaan',
 				'zza' => 'Jajaki',

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
			'Adlm' => 'Adlam',
 			'Aghb' => 'Albani Kaukasus',
 			'Ahom' => 'Ahom',
 			'Arab' => 'Arab',
 			'Aran' => 'Nasta’lik',
 			'Armi' => 'Aram Kekaèsaran',
 			'Armn' => 'Lemènder',
 			'Avst' => 'Awèstan',
 			'Bali' => 'Bali',
 			'Bamu' => 'Bamum',
 			'Bass' => 'Wah',
 			'Batk' => 'Batak',
 			'Beng' => 'Benggala',
 			'Bhks' => 'Béksuki',
 			'Bopo' => 'Cuim-huho',
 			'Brah' => 'Brahmi',
 			'Brai' => 'Brél',
 			'Bugi' => 'Bugis',
 			'Buhd' => 'Buhid',
 			'Cakm' => 'Cakma',
 			'Cans' => 'Hurup Ucap Pribumi Kanada',
 			'Cari' => 'Kari',
 			'Cham' => 'Campa',
 			'Cher' => 'Cèroki',
 			'Chrs' => 'Hawarismi',
 			'Copt' => 'Kibti',
 			'Cpmn' => 'Sipro-Minois',
 			'Cprt' => 'Sipres',
 			'Cyrl' => 'Sirilik',
 			'Deva' => 'Déwanagari',
 			'Diak' => 'Diwéhi Akuru',
 			'Dogr' => 'Dogra',
 			'Dsrt' => 'Dèserèt',
 			'Dupl' => 'Tulisan Duployé',
 			'Egyp' => 'Mesir Kuna',
 			'Elba' => 'Èlbasan',
 			'Elym' => 'Èlimais',
 			'Ethi' => 'Gé’ès',
 			'Geor' => 'Géorgi',
 			'Glag' => 'Glagolitis',
 			'Gong' => 'Gunjala Gondi',
 			'Gonm' => 'Masaram Gondi',
 			'Goth' => 'Gotis',
 			'Gran' => 'Granta',
 			'Grek' => 'Yunani',
 			'Gujr' => 'Gujarat',
 			'Guru' => 'Gurmuk',
 			'Hanb' => 'Tionghoa paké Cuim-huho',
 			'Hang' => 'Hanggel',
 			'Hani' => 'Tionghoa',
 			'Hano' => 'Hanunu’o',
 			'Hans' => 'Ringkes',
 			'Hans@alt=stand-alone' => 'Tionghoa Ringkes',
 			'Hant' => 'Terdisionil',
 			'Hant@alt=stand-alone' => 'Tionghoa Terdisional',
 			'Hatr' => 'Hatra',
 			'Hebr' => 'Ibrani',
 			'Hira' => 'Hiragana',
 			'Hluw' => 'Anatoli Kuna',
 			'Hmng' => 'Pahaw Mong',
 			'Hmnp' => 'Mong Alkitab',
 			'Hrkt' => 'hurup ucap Jepang',
 			'Hung' => 'Honggari Kuna',
 			'Ital' => 'Itali Kuna',
 			'Jamo' => 'Hanggel Camo',
 			'Java' => 'Jawa',
 			'Jpan' => 'Jepang',
 			'Kali' => 'Kayah Li',
 			'Kana' => 'Katagana',
 			'Kawi' => 'Jawa Kuna',
 			'Khar' => 'Karosti',
 			'Khmr' => 'Kemboja',
 			'Khoj' => 'Koja',
 			'Kits' => 'hurup kecit Kitan',
 			'Knda' => 'Kenada',
 			'Kore' => 'Koréa',
 			'Kthi' => 'Kaiti',
 			'Lana' => 'Lanna',
 			'Laoo' => 'Laos',
 			'Latn' => 'Latin',
 			'Lepc' => 'Rong',
 			'Limb' => 'Limbu',
 			'Lina' => 'Linièr A',
 			'Linb' => 'Linièr B',
 			'Lisu' => 'Prèser',
 			'Lyci' => 'Lisi',
 			'Lydi' => 'Lidi',
 			'Mahj' => 'Mahajani',
 			'Maka' => 'Makasar',
 			'Mand' => 'Mandaiah',
 			'Mani' => 'Manawi',
 			'Marc' => 'Marcèn',
 			'Medf' => 'Médépaidrin',
 			'Mend' => 'Mèndé',
 			'Merc' => 'Merowé Doyong',
 			'Mero' => 'Merowé',
 			'Mlym' => 'Malayalam',
 			'Modi' => 'Modi',
 			'Mong' => 'Monggoli',
 			'Mroo' => 'Meru',
 			'Mtei' => 'Manipur',
 			'Mult' => 'Multani',
 			'Mymr' => 'Birma',
 			'Nagm' => 'Nag Mundari',
 			'Nand' => 'Nandinagari',
 			'Narb' => 'Arab Lor Kuna',
 			'Nbat' => 'Nabat',
 			'Newa' => 'Néwa',
 			'Nkoo' => 'Ngko',
 			'Nshu' => 'Lusu',
 			'Ogam' => 'Ogham',
 			'Olck' => 'Santali',
 			'Orkh' => 'Turki Kuna',
 			'Orya' => 'Oria',
 			'Osge' => 'Osagé',
 			'Osma' => 'Osmania',
 			'Ougr' => 'Uigur Kuna',
 			'Palm' => 'Tadmur',
 			'Pauc' => 'Pau Cin Hau',
 			'Perm' => 'Pèrem Kuna',
 			'Phag' => 'Hurup Kotak Monggoli',
 			'Phli' => 'Pahlawi Prasasti',
 			'Phlp' => 'Pahlawi Jabur',
 			'Phnx' => 'Pinikiah',
 			'Plrd' => 'Miao',
 			'Prti' => 'Partia Prasasti',
 			'Qaag' => 'Zawgyi',
 			'Rjng' => 'Rejang',
 			'Rohg' => 'Hanipi',
 			'Runr' => 'Runen',
 			'Samr' => 'Samiri',
 			'Sarb' => 'Arab Kidul Kuna',
 			'Saur' => 'Sorastra',
 			'Sgnw' => 'Tulisan Isarat',
 			'Shaw' => 'Sawi',
 			'Shrd' => 'Sarada',
 			'Sidd' => 'Sidam',
 			'Sind' => 'Hudabadi',
 			'Sinh' => 'Singala',
 			'Sogd' => 'Sogdi',
 			'Sogo' => 'Sogdi Kuna',
 			'Sora' => 'Sora Sompèng',
 			'Soyo' => 'Soyombo',
 			'Sund' => 'Sunda',
 			'Sylo' => 'Silètnagari',
 			'Syrc' => 'Suryani',
 			'Tagb' => 'Tagbanwa',
 			'Takr' => 'Takri',
 			'Tale' => 'Taile',
 			'Talu' => 'Taileu Baru',
 			'Taml' => 'Tamil',
 			'Tang' => 'Tangut',
 			'Tavt' => 'Taidam',
 			'Telu' => 'Telugu',
 			'Tfng' => 'Bèrbèr',
 			'Tglg' => 'Tagalog',
 			'Thaa' => 'Maladéwa',
 			'Thai' => 'Siam',
 			'Tibt' => 'Tibèt',
 			'Tirh' => 'Tirhuta',
 			'Tnsa' => 'Tangsa',
 			'Toto' => 'Toto',
 			'Ugar' => 'Ugarit',
 			'Vaii' => 'Wai',
 			'Vith' => 'Witkut',
 			'Wara' => 'Warang Citi',
 			'Wcho' => 'Wanco',
 			'Xpeo' => 'Parsi Kuna',
 			'Xsux' => 'Hurup Akadi-Suméri',
 			'Yezi' => 'Yajidi',
 			'Yiii' => 'I',
 			'Zanb' => 'Hurup Kotak Janabajar',
 			'Zinh' => 'Warisan',
 			'Zmth' => 'Notasi Matimatika',
 			'Zsye' => 'Émoji',
 			'Zsym' => 'Simbol',
 			'Zxxx' => 'Kaga’ Ketulis',
 			'Zyyy' => 'Umum',
 			'Zzzz' => 'Hurup Kaga’ Ditauin',

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
			'001' => 'Dunia',
 			'002' => 'Aprika',
 			'003' => 'Amrik Lor',
 			'005' => 'Amrik Kidul',
 			'009' => 'Oséani',
 			'011' => 'Aprika Bekulon',
 			'013' => 'Amrik Tenga',
 			'014' => 'Aprika Belètan',
 			'015' => 'Aprika Belèlir',
 			'017' => 'Aprika Bela Tenga',
 			'018' => 'Aprika Bekidul',
 			'019' => 'Amrik',
 			'021' => 'Amrik Belèlir',
 			'029' => 'Karaiben',
 			'030' => 'Asia Belètan',
 			'034' => 'Asia Bekidul',
 			'035' => 'Asia Kidul-wètan',
 			'039' => 'Èropa Bekidul',
 			'053' => 'Ostralasia',
 			'054' => 'Melanésia',
 			'057' => 'Daèrah Mikronésia',
 			'061' => 'Polinésia',
 			'142' => 'Asia',
 			'143' => 'Asia Tenga',
 			'145' => 'Asia Bekulon',
 			'150' => 'Èropa',
 			'151' => 'Èropa Belètan',
 			'154' => 'Èropa Belèlir',
 			'155' => 'Èropa Bekulon',
 			'202' => 'Aprika Kidulnya Sahara',
 			'419' => 'Amrik Latin',
 			'AC' => 'Pulo Kenaèkan',
 			'AD' => 'Andora',
 			'AE' => 'Imarat Arab Rempug',
 			'AF' => 'Apganistan',
 			'AG' => 'Antigua èn Barbuda',
 			'AI' => 'Angguila',
 			'AL' => 'Albani',
 			'AM' => 'Lemènder',
 			'AO' => 'Anggola',
 			'AQ' => 'Kutub Kidul',
 			'AR' => 'Argèntina',
 			'AS' => 'Samoa Amrik',
 			'AT' => 'Ostenrèk',
 			'AU' => 'Ostrali',
 			'AW' => 'Aruba',
 			'AX' => 'Pulo Olan',
 			'AZ' => 'Asèrbaijan',
 			'BA' => 'Bosni èn Hèrségowina',
 			'BB' => 'Barbados',
 			'BD' => 'Benggaladésa',
 			'BE' => 'Bèlgi',
 			'BF' => 'Burkina Paso',
 			'BG' => 'Bulgari',
 			'BH' => 'Bahrén',
 			'BI' => 'Burundi',
 			'BJ' => 'Bénin',
 			'BL' => 'Sint-Bartoloméus',
 			'BM' => 'Bermuda',
 			'BN' => 'Bruné',
 			'BO' => 'Boliwi',
 			'BQ' => 'Belanda Karaiben',
 			'BR' => 'Brasil',
 			'BS' => 'Bahama',
 			'BT' => 'Butan',
 			'BV' => 'Pulo Buwèt',
 			'BW' => 'Boswana',
 			'BY' => 'Ruslan Puti',
 			'BZ' => 'Bélis',
 			'CA' => 'Kanada',
 			'CC' => 'Pulo Kokos (Keeling)',
 			'CD' => 'Kongo - Kinsasa',
 			'CD@alt=variant' => 'Kongo (KDK)',
 			'CF' => 'Kiblik Aprika Tenga',
 			'CG' => 'Kongo - Brasawil',
 			'CG@alt=variant' => 'Kongo (Kiblik)',
 			'CH' => 'Switserlan',
 			'CI' => 'Panté Gading',
 			'CK' => 'Pulo Cook',
 			'CL' => 'Cili',
 			'CM' => 'Kamérun',
 			'CN' => 'Tiongkok',
 			'CO' => 'Kolombia',
 			'CP' => 'Pulo Kliperten',
 			'CQ' => 'Sarek',
 			'CR' => 'Kosta Rika',
 			'CU' => 'Kuba',
 			'CV' => 'Tanjung Ijo',
 			'CW' => 'Kurasao',
 			'CX' => 'Pulo Natal',
 			'CY' => 'Sipres',
 			'CZ' => 'Cèki',
 			'CZ@alt=variant' => 'Kiblik Cèk',
 			'DE' => 'Dètslan',
 			'DG' => 'Diégo Garsia',
 			'DJ' => 'Jibuti',
 			'DK' => 'Dènemarken',
 			'DM' => 'Dominika',
 			'DO' => 'Kiblik Dominika',
 			'DZ' => 'Aljajaèr',
 			'EA' => 'Sabtah èn Mélila',
 			'EC' => 'Èkuador',
 			'EE' => 'Èstlan',
 			'EG' => 'Mesir',
 			'EH' => 'Sahara Kulon',
 			'ER' => 'Èritréa',
 			'ES' => 'Spanyol',
 			'ET' => 'Habsi (Ètiopi)',
 			'EU' => 'Uni Èropa',
 			'EZ' => 'Kawasan Èuro',
 			'FI' => 'Pinlan',
 			'FJ' => 'Piji',
 			'FK' => 'Pulo Paklan',
 			'FK@alt=variant' => 'Pulo Paklan (Malbinas)',
 			'FM' => 'Mikronésia',
 			'FO' => 'Pulo Perower',
 			'FR' => 'Prasman',
 			'GA' => 'Gabon',
 			'GB' => 'Kerajaan Rempug',
 			'GB@alt=short' => 'KR',
 			'GD' => 'Grénada',
 			'GE' => 'Géorgi',
 			'GF' => 'Guyana Prasman',
 			'GG' => 'Gèrensi',
 			'GH' => 'Gana',
 			'GI' => 'Jabal Tarik',
 			'GL' => 'Grunlan',
 			'GM' => 'Gambia',
 			'GN' => 'Giné',
 			'GP' => 'Guadelup',
 			'GQ' => 'Giné Katulistiwa',
 			'GR' => 'Yunani',
 			'GS' => 'Géorgi Kidul èn Pulo Sènwit Kidul',
 			'GT' => 'Guatémala',
 			'GU' => 'Guam',
 			'GW' => 'Giné-Biso',
 			'GY' => 'Guyana',
 			'HK' => 'Daèrah Bestir Istimèwa Hongkong',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Pulo Heard èn McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Kroasi',
 			'HT' => 'Haiti',
 			'HU' => 'Honggari',
 			'IC' => 'Pulo Kenari',
 			'ID' => 'Indonésia',
 			'IE' => 'Irlan',
 			'IL' => 'Israèl',
 			'IM' => 'Pulo Man',
 			'IN' => 'Hindi',
 			'IO' => 'Wilayah Britani di Laotan Hindi',
 			'IO@alt=chagos' => 'Kepuloan Cagos',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Èslan',
 			'IT' => 'Itali',
 			'JE' => 'Jèrsi',
 			'JM' => 'Jamaika',
 			'JO' => 'Urdun',
 			'JP' => 'Jepang',
 			'KE' => 'Kénia',
 			'KG' => 'Kirgistan',
 			'KH' => 'Kemboja',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoro',
 			'KN' => 'Sint-Kristoper èn Nèwis',
 			'KP' => 'Koréa Lor',
 			'KR' => 'Koréa Kidul',
 			'KW' => 'Kuwét',
 			'KY' => 'Pulo Kaèman',
 			'KZ' => 'Kasakstan',
 			'LA' => 'Laos',
 			'LB' => 'Lèbanon',
 			'LC' => 'Sint Lusia',
 			'LI' => 'Lihtenstèn',
 			'LK' => 'Sri Langka',
 			'LR' => 'Libéria',
 			'LS' => 'Lésoto',
 			'LT' => 'Litowen',
 			'LU' => 'Leksembereh',
 			'LV' => 'Lètlan',
 			'LY' => 'Libi',
 			'MA' => 'Maroko',
 			'MC' => 'Monako',
 			'MD' => 'Moldawi',
 			'ME' => 'Gunung Item (Montenègro)',
 			'MF' => 'Sint-Martèn (Prasman)',
 			'MG' => 'Madagaskar',
 			'MH' => 'Pulo Marsal',
 			'MK' => 'Makèdoni Lor',
 			'ML' => 'Mali',
 			'MM' => 'Mianmar (Birma)',
 			'MN' => 'Monggoli',
 			'MO' => 'Daèrah Bestir Istimèwa Makao',
 			'MO@alt=short' => 'Makao',
 			'MP' => 'Pulo Mariana Lor',
 			'MQ' => 'Martinik',
 			'MR' => 'Moritani',
 			'MS' => 'Monsérat',
 			'MT' => 'Malta',
 			'MU' => 'Moritius',
 			'MV' => 'Maladéwa',
 			'MW' => 'Malawi',
 			'MX' => 'Mèksiko',
 			'MY' => 'Malésia',
 			'MZ' => 'Mosambik',
 			'NA' => 'Namibi',
 			'NC' => 'Kalédoni Baru',
 			'NE' => 'Nigèr',
 			'NF' => 'Pulo Norpok',
 			'NG' => 'Nigéria',
 			'NI' => 'Nikaragua',
 			'NL' => 'Belanda',
 			'NO' => 'Norwèhen',
 			'NP' => 'Népal',
 			'NR' => 'Nauru',
 			'NU' => 'Niué',
 			'NZ' => 'Sélan Baru',
 			'NZ@alt=variant' => 'Sélanda Anyar',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Péru',
 			'PF' => 'Polinésia Prasman',
 			'PG' => 'Papua Giné Baru (Papua Nugini)',
 			'PH' => 'Pilipénen (Pilipina)',
 			'PK' => 'Pakistan',
 			'PL' => 'Polen',
 			'PM' => 'Sint-Pièr èn Mikélon',
 			'PN' => 'Pulo Pitkèren',
 			'PR' => 'Porto Riko',
 			'PS' => 'Wilayah Palestèn',
 			'PS@alt=short' => 'Palèstina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paragué',
 			'QA' => 'Katar',
 			'QO' => 'Oséania Paling Luar',
 			'RE' => 'Réunion',
 			'RO' => 'Ruméni',
 			'RS' => 'Sèrwi',
 			'RU' => 'Ruslan',
 			'RW' => 'Ruanda',
 			'SA' => 'Arab Saudi',
 			'SB' => 'Pulo Suléman',
 			'SC' => 'Sésèl',
 			'SD' => 'Sudan',
 			'SE' => 'Swèden',
 			'SG' => 'Singapur',
 			'SH' => 'Sint-Héléna',
 			'SI' => 'Slowéni',
 			'SJ' => 'Spitbèrhen',
 			'SK' => 'Slowaki',
 			'SL' => 'Gunung Singa (Sièra Léon)',
 			'SM' => 'San Marino',
 			'SN' => 'Sénégal',
 			'SO' => 'Somali',
 			'SR' => 'Suriname',
 			'SS' => 'Sudan Kidul',
 			'ST' => 'Sint-Tomas èn Prins',
 			'SV' => 'Salbador',
 			'SX' => 'Sint-Martèn (Welanda)',
 			'SY' => 'Suriah',
 			'SZ' => 'Èswatini',
 			'SZ@alt=variant' => 'Swasilan',
 			'TA' => 'Tristang da Kunya',
 			'TC' => 'Pulo Turks èn Kaikos',
 			'TD' => 'Cad',
 			'TF' => 'Wilayah Kulon Prasman',
 			'TG' => 'Togo',
 			'TH' => 'Muang-Tay',
 			'TJ' => 'Tajikistan',
 			'TK' => 'Tokélau',
 			'TL' => 'Timor Wètan',
 			'TM' => 'Turkmènistan',
 			'TN' => 'Tunis',
 			'TO' => 'Tonga',
 			'TR' => 'Turki',
 			'TT' => 'Trinidad èn Tobago',
 			'TV' => 'Tuwalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tansania',
 			'UA' => 'Ukrain',
 			'UG' => 'Uganda',
 			'UM' => 'Kepuloan AS Paling Luar',
 			'UN' => 'Perserèkatan Bangsa-Bangsa',
 			'US' => 'Amrik Serèkat',
 			'US@alt=short' => 'AS',
 			'UY' => 'Urugué',
 			'UZ' => 'Usbèkistan',
 			'VA' => 'Kota Watikan',
 			'VC' => 'Sint-Winsèn èn Grénadin',
 			'VE' => 'Bénésuèla',
 			'VG' => 'Pulo Perawan Britani',
 			'VI' => 'Pulo Perawan Amrik',
 			'VN' => 'Piètnam',
 			'VU' => 'Wanuatu',
 			'WF' => 'Walis èn Putuna',
 			'WS' => 'Samoa',
 			'XA' => 'Logat Asing',
 			'XB' => 'Dua Arah Palsu',
 			'XK' => 'Kosowa',
 			'YE' => 'Yaman',
 			'YT' => 'Méot',
 			'ZA' => 'Aprika Kidul',
 			'ZM' => 'Sambia',
 			'ZW' => 'Jimbabwé',
 			'ZZ' => 'Daèrah Kaga’ Ditauin',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'èjaan Dèt Terdisionil',
 			'1994' => 'èjaan Résia Pakem',
 			'1996' => 'èjaan Dèt tahon 1996',
 			'1606NICT' => 'Prasman Pertengahan Akir ampé 1606',
 			'1694ACAD' => 'Prasman Modèren Awal',
 			'1959ACAD' => 'Akadémis',
 			'ABL1943' => 'Rancangan èjaan tahon 1943',
 			'AKUAPEM' => 'Akuapèm',
 			'ALALC97' => 'Penglatinan ALA-LC tahon 1997',
 			'ALUKU' => 'logat Aluku',
 			'AO1990' => 'Mupakat Èjaan Basa Portugis tahon 1990',
 			'ARANES' => 'Aranis',
 			'ASANTE' => 'Asanti',
 			'AUVERN' => 'Owernyat',
 			'BAKU1926' => 'Hurup Latin Turkik Rempug',
 			'BALANKA' => 'logat Balangka basa Ani',
 			'BARLA' => 'kelompok logat Barlawèntu basa Tanjung Ijo',
 			'BASICENG' => 'Inggris Dasar',
 			'BAUDDHA' => 'Ragem Buddha',
 			'BISCAYAN' => 'Biskaye',
 			'BISKE' => 'logat San Giorgio/Bila',
 			'BOHORIC' => 'hurup Bohorič',
 			'BOONT' => 'Boontling',
 			'COLB1945' => 'Mupakat Èjaan Portugis-Brasil tahon 1945',
 			'CORNU' => 'Kornis',
 			'CREISS' => 'lisan Croissant',
 			'DAJNKO' => 'hurup Dajnko',
 			'EKAVSK' => 'Sèrwi paké lapal Èkawia',
 			'EMODENG' => 'Inggris Modèren Awal',
 			'FONIPA' => 'Hurup Ponètis Antèrobangsa',
 			'FONKIRSH' => 'Hurup Ponètis Kirshenbaum',
 			'FONNAPA' => 'Hurup Ponètis Amrik Lor',
 			'FONUPA' => 'Hurup Ponètis Ural',
 			'FONXSAMP' => 'Hurup Ponètis X-SAMPA',
 			'GASCON' => 'Gaskon',
 			'GRCLASS' => 'Èjaan Oksitan Klasik',
 			'GRITAL' => 'Èjaan Oksitan Keitalian',
 			'GRMISTR' => 'Èjaan Oksitan Mistral',
 			'HEPBURN' => 'penglatinan Hepburn',
 			'HOGNORSK' => 'Nor Tinggi',
 			'HSISTEMO' => 'Sistim Èjaan H Èspèranto',
 			'IJEKAVSK' => 'Sèrwi paké lapal Iyèkawia',
 			'IVANCHOV' => 'Èjaan Bulgari tahon 1899',
 			'JAUER' => 'Jawer',
 			'JYUTPING' => 'Penglatinan Jyutping',
 			'KKCOR' => 'Èjaan Umum',
 			'KOCIEWIE' => 'Kociéwié',
 			'KSCOR' => 'Èjaan Pakem',
 			'LEMOSIN' => 'Limosin',
 			'LENGADOC' => 'Langgedok',
 			'LIPAW' => 'logat Lipowas basa Résia',
 			'LUNA1918' => 'Èjaan Rus Perobahan tahon 1918',
 			'METELKO' => 'hurup Metelko',
 			'MONOTON' => 'Nada Tunggal',
 			'NDYUKA' => 'logat Ndyuka',
 			'NEDIS' => 'logat Natison',
 			'NEWFOUND' => 'Inggris Niuponlan',
 			'NICARD' => 'Nis',
 			'NJIVA' => 'logat Nyiwa',
 			'NULIK' => 'Wolapik Modèren',
 			'OSOJS' => 'logat Osoyané',
 			'OXENDICT' => 'èjaan Kamus Inggris Okspot',
 			'PAHAWH2' => 'èjaan ringkes Pahaw Mong tahap 2',
 			'PAHAWH3' => 'èjaan ringkes Pahaw Mong tahap 3',
 			'PAHAWH4' => 'èjaan Pahaw Mong rampung',
 			'PAMAKA' => 'logat Pamaka',
 			'PETR1708' => 'Èjaan Pèter Agung tahun 1708',
 			'PINYIN' => 'Penglatinan Pin-in',
 			'POLYTON' => 'Nada Banyak',
 			'POSIX' => 'Kumpiuter',
 			'PROVENC' => 'Prowangsal',
 			'PUTER' => 'Putèr',
 			'REVISED' => 'Èjaan Perbaèkan',
 			'RIGIK' => 'Wolapik Klasik',
 			'ROZAJ' => 'Résia',
 			'RUMGR' => 'Graubenderlan',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Inggris Pakem Skot',
 			'SCOUSE' => 'Skos',
 			'SIMPLE' => 'Ringkes',
 			'SOLBA' => 'logat Stolwitsa/Solbitsa',
 			'SOTAV' => 'kelompok logat Sotawèntu basa Tanjung Ijo',
 			'SPANGLIS' => 'Inggris-Spanyol',
 			'SURMIRAN' => 'Surmèr',
 			'SURSILV' => 'Sursèlwi',
 			'SUTSILV' => 'Sutsèlwi',
 			'TARASK' => 'Èjaan Taraskiéwitsa',
 			'UCCOR' => 'Èjaan Kegabreg',
 			'UCRCOR' => 'Èjaan Kegabreg Perbaèkan',
 			'ULSTER' => 'Èjaan Ulster',
 			'UNIFON' => 'Hurup Ponètis Unifon',
 			'VAIDIKA' => 'Ragem Wèda',
 			'VALENCIA' => 'Balènsi',
 			'VALLADER' => 'Waladèr',
 			'VIVARAUP' => 'Wiwaro-Alpen',
 			'WADEGILE' => 'Penglatinan Wade-Giles',
 			'XSISTEMO' => 'Sistim Èjaan X Èspèranto',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Almenak',
 			'cf' => 'Pormat Mata Uang',
 			'collation' => 'Rèntètan Sortir',
 			'currency' => 'Mata Uang',
 			'hc' => 'Puteran Jem (12 vs 24)',
 			'lb' => 'Setil Pembelèk Baris',
 			'ms' => 'Sistim Pengukuran',
 			'numbers' => 'Angka',

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
 				'buddhist' => q{Almenak Buda},
 				'chinese' => q{Almenak Tionghoa},
 				'coptic' => q{Almenak Kibti},
 				'dangi' => q{Almenak Koréa},
 				'ethiopic' => q{Almenak Habsi},
 				'ethiopic-amete-alem' => q{Almenak Habsi Awal Alam},
 				'gregorian' => q{Almenak Grégorian},
 				'hebrew' => q{Almenak Ibrani},
 				'indian' => q{Almenak Negara Hindi},
 				'islamic' => q{Almenak Selam},
 				'islamic-civil' => q{Almenak Selam (hisab, sipil)},
 				'islamic-rgsa' => q{Almenak Selam (Arab saudi, ru’yat)},
 				'islamic-tbla' => q{Almenak Selam (hisab, palakiah)},
 				'islamic-umalqura' => q{Almenak Selam (Umulkura)},
 				'iso8601' => q{Almenak ISO-8601},
 				'japanese' => q{Almenak Jepang},
 				'persian' => q{Almenak Parsi},
 				'roc' => q{Almenak Bingkok},
 			},
 			'cf' => {
 				'account' => q{Pormat Mata Uang Pembukuan},
 				'standard' => q{Pormat Mata Uang Pakem},
 			},
 			'collation' => {
 				'big5han' => q{Rèntètan Sortir Tionghoa Terdisionil - Big5},
 				'compat' => q{Rèntètan Sortir Sebelonnya, bakal kecocokan},
 				'dictionary' => q{Rèntètan Sortir Kamus},
 				'ducet' => q{Rèntètan Sortir Bawaan Unicode},
 				'emoji' => q{Rèntètan Sortir Émoji},
 				'eor' => q{Aturan Pengrèntètan Èropa},
 				'gb2312han' => q{Rèntètan Sortir Tionghoa Ringkes - GB2312},
 				'phonebook' => q{Rèntètan Sortir Buku Telepon},
 				'pinyin' => q{Rèntètan Sortir Pin-in},
 				'reformed' => q{Rèntètan Sortir Kerobah},
 				'search' => q{Penyarian Tujuan Umum},
 				'searchjl' => q{Penyarian berales Hurup Mati Depan Hanggel},
 				'standard' => q{Rèntètan Sortiran Pakem},
 				'stroke' => q{Rèntètan Gorètan},
 				'traditional' => q{Rèntètan Gorètan Terdisionil},
 				'unihan' => q{Rèntètan Sortir Gorètan Oyod},
 				'zhuyin' => q{Rèntètan Sortir Cuim},
 			},
 			'hc' => {
 				'h11' => q{Sistim 12 Jem (0–11)},
 				'h12' => q{Sistim 12 Jem (1–12)},
 				'h23' => q{Sistim 24 Jem (0–23)},
 				'h24' => q{Sistim 24 Jem (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Setil Pembelèk Baris Longgar},
 				'normal' => q{Setil Pembelèk Baris Normal},
 				'strict' => q{Setil Pembelèk Baris Rapet},
 			},
 			'ms' => {
 				'metric' => q{Sistim Mètrik},
 				'uksystem' => q{Sistim Pengukuran Kekaèsaran},
 				'ussystem' => q{Sistim Pengukuran AS},
 			},
 			'numbers' => {
 				'ahom' => q{Angka Ahom},
 				'arab' => q{Angka Arab-Hindi},
 				'arabext' => q{Angka Arab-Hindi Perluasan},
 				'armn' => q{Angka Lemènder},
 				'armnlow' => q{Angka Lemènder Kecil},
 				'bali' => q{Angka Bali},
 				'beng' => q{Angka Benggala},
 				'brah' => q{Angka Brahmi},
 				'cakm' => q{Angka Cakma},
 				'cham' => q{Angka Campa},
 				'cyrl' => q{Angka Sirilik},
 				'deva' => q{Angka Déwanagari},
 				'diak' => q{Angka Diwéhi Akuru},
 				'ethi' => q{Angka Habsi},
 				'fullwide' => q{Angka Lèbar-Pol},
 				'geor' => q{Angka Géorgi},
 				'gong' => q{Angka Gunjala Gondi},
 				'gonm' => q{Angka Masaram Gondi},
 				'grek' => q{Angka Yunani},
 				'greklow' => q{Angka Yunani Kecil},
 				'gujr' => q{Angka Gujarat},
 				'guru' => q{Angka Gurmuk},
 				'hanidec' => q{Angka Persepuluan Tionghoa},
 				'hans' => q{Angka Tionghoa Ringkes},
 				'hansfin' => q{Angka Duit Tionghoa Ringkes},
 				'hant' => q{Angka Tionghoa Terdisionil},
 				'hantfin' => q{Angka Duit Tionghoa Terdisionil},
 				'hebr' => q{Angka Ibrani},
 				'hmng' => q{Angka Pahaw Mong},
 				'hmnp' => q{Angka Mong Alkitab},
 				'java' => q{Angka Jawa},
 				'jpan' => q{Angka Jepang},
 				'jpanfin' => q{Angka Duit Jepang},
 				'kali' => q{Angka Kayah Li},
 				'kawi' => q{Angka Jawa Kuna},
 				'khmr' => q{Angka Kemboja},
 				'knda' => q{Angka Kenada},
 				'lana' => q{Angka Lanna Hora},
 				'lanatham' => q{Angka Lanna Tam},
 				'laoo' => q{Angka Laos},
 				'latn' => q{Angka Latin},
 				'lepc' => q{Angka Rong},
 				'limb' => q{Angka Limbu},
 				'mathbold' => q{Angka Tebel Matimatika},
 				'mathdbl' => q{Angka Corèt Dua Matimatika},
 				'mathmono' => q{Angka Apstan Tunggal Matimatika},
 				'mathsanb' => q{Angka Sonderkail Tebel Matimatika},
 				'mathsans' => q{Angka Bekail Matimatika},
 				'mlym' => q{Angka Malayalam},
 				'modi' => q{Angka Modi},
 				'mong' => q{Angka Monggoli},
 				'mroo' => q{Angka Meru},
 				'mtei' => q{Angka Manipur},
 				'mymr' => q{Angka Birma},
 				'mymrshan' => q{Angka San Birma},
 				'mymrtlng' => q{Angka Tailaing Birma},
 				'nagm' => q{Angka Nag Mundari},
 				'nkoo' => q{Angka Ngko},
 				'olck' => q{Angka Ol Ciki},
 				'orya' => q{Angka Oria},
 				'osma' => q{Angka Osmania},
 				'rohg' => q{Angka Rohingya Hanipi},
 				'roman' => q{Angka Romèn},
 				'romanlow' => q{Angka Romèn Kecil},
 				'saur' => q{Angka Sorastra},
 				'shrd' => q{Angka Sarada},
 				'sind' => q{Angka Hudabadi},
 				'sinh' => q{Angka Singala},
 				'sora' => q{Angka Sora Sompèng},
 				'sund' => q{Angka Sunda},
 				'takr' => q{Angka Takri},
 				'talu' => q{Angka Taileu Baru},
 				'taml' => q{Angka Tamil Terdisionil},
 				'tamldec' => q{Angka Tamil},
 				'telu' => q{Angka Telugu},
 				'thai' => q{Angka Siam},
 				'tibt' => q{Angka Tibèt},
 				'tirh' => q{Angka Tirhuta},
 				'tnsa' => q{Angka Tangsa},
 				'vaii' => q{Angka Wai},
 				'wara' => q{Angka Warang Citi},
 				'wcho' => q{Angka Wanco},
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
			'metric' => q{Mètrik},
 			'UK' => q{Inggris},
 			'US' => q{AS},

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
			auxiliary => qr{[áàăâåäãā æ čç ḍ êëē ğġ ḥḫ íìĭîïī ḷḹ ṁṃ ñṅṇ óòŏôöøō œ ṛṝ śšşṣ ṭ úùŭûüū ÿ żẓ ʾ ʿ]},
			main => qr{[a b c d eéèĕ f g h i j k l m n o p q r s t u v w x y z]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return {};
},
);


has 'duration_units' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { {
				hm => 'h.mm',
				hms => 'h.mm.ss',
				ms => 'm.ss',
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
						'name' => q(arah mata angin),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(arah mata angin),
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
						'1' => q(mèbi{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(mèbi{0}),
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
						'1' => q(tèbi{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(tèbi{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(pèbi{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(pèbi{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(èksbi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(èksbi{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(sèbi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(sèbi{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(jobi{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(jobi{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(dèsi{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(dèsi{0}),
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
						'1' => q(pèmto{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(pèmto{0}),
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
						'1' => q(sènti{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(sènti{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(sèpto{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(sèpto{0}),
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
						'1' => q(kuèkto{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(kuèkto{0}),
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
						'1' => q(dèka{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(dèka{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(tèra{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(tèra{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(pèta{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(pèta{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(èksa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(èksa{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(hèkto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hèkto{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(sèta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(sèta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(jota{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(jota{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(rona{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(rona{0}),
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
						'1' => q(kuèta{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(kuèta{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(mèga{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(mèga{0}),
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
						'other' => q({0} g-force),
					},
					# Core Unit Identifier
					'g-force' => {
						'other' => q({0} g-force),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(mèter per sekon pesegi),
						'other' => q({0} mèter per sekon pesegi),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(mèter per sekon pesegi),
						'other' => q({0} mèter per sekon pesegi),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(menit busur),
						'other' => q({0} menit busur),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(menit busur),
						'other' => q({0} menit busur),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(sekon busur),
						'other' => q({0} sekon busur),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(sekon busur),
						'other' => q({0} sekon busur),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'other' => q({0} derajat),
					},
					# Core Unit Identifier
					'degree' => {
						'other' => q({0} derajat),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'other' => q({0} radial),
					},
					# Core Unit Identifier
					'radian' => {
						'other' => q({0} radial),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(kiteran),
						'other' => q({0} kiteran),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(kiteran),
						'other' => q({0} kiteran),
					},
					# Long Unit Identifier
					'area-acre' => {
						'other' => q({0} aker),
					},
					# Core Unit Identifier
					'acre' => {
						'other' => q({0} aker),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'other' => q({0} hèktar),
					},
					# Core Unit Identifier
					'hectare' => {
						'other' => q({0} hèktar),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(sèntimèter pesegi),
						'other' => q({0} sèntimèter pesegi),
						'per' => q({0} per sèntimèter pesegi),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(sèntimèter pesegi),
						'other' => q({0} sèntimèter pesegi),
						'per' => q({0} per sèntimèter pesegi),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(kaki pesegi),
						'other' => q({0} kaki pesegi),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(kaki pesegi),
						'other' => q({0} kaki pesegi),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(inci pesegi),
						'other' => q({0} inci pesegi),
						'per' => q({0} per inci pesegi),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(inci pesegi),
						'other' => q({0} inci pesegi),
						'per' => q({0} per inci pesegi),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kilomèter pesegi),
						'other' => q({0} kilomèter pesegi),
						'per' => q({0} per kilomèter pesegi),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kilomèter pesegi),
						'other' => q({0} kilomèter pesegi),
						'per' => q({0} per kilomèter pesegi),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(mèter pesegi),
						'other' => q({0} mèter pesegi),
						'per' => q({0} per mèter pesegi),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(mèter pesegi),
						'other' => q({0} mèter pesegi),
						'per' => q({0} per mèter pesegi),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mil pesegi),
						'other' => q({0} mil pesegi),
						'per' => q({0} per mil pesegi),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mil pesegi),
						'other' => q({0} mil pesegi),
						'per' => q({0} per mil pesegi),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yard pesegi),
						'other' => q({0} yard pesegi),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yard pesegi),
						'other' => q({0} yard pesegi),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'karat' => {
						'other' => q({0} karat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(miligram per dèsilèter),
						'other' => q({0} miligram per dèsilèter),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(miligram per dèsilèter),
						'other' => q({0} miligram per dèsilèter),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimol per lèter),
						'other' => q({0} milimol per lèter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimol per lèter),
						'other' => q({0} milimol per lèter),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'other' => q({0} prosèn),
					},
					# Core Unit Identifier
					'percent' => {
						'other' => q({0} prosèn),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'other' => q({0} perèbu),
					},
					# Core Unit Identifier
					'permille' => {
						'other' => q({0} perèbu),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(bagèan per juta),
						'other' => q({0} bagèan per juta),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(bagèan per juta),
						'other' => q({0} bagèan per juta),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'other' => q({0} perceban),
					},
					# Core Unit Identifier
					'permyriad' => {
						'other' => q({0} perceban),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(lèter per 100 kilomèter),
						'other' => q({0} lèter per 100 kilomèter),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(lèter per 100 kilomèter),
						'other' => q({0} lèter per 100 kilomèter),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(lèter per kilomèter),
						'other' => q({0} lèter per kilomèter),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(lèter per kilomèter),
						'other' => q({0} lèter per kilomèter),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mil per galon),
						'other' => q({0} mil per galon),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mil per galon),
						'other' => q({0} mil per galon),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mil per galon Kaès.),
						'other' => q({0} mil per galon Kaès.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mil per galon Kaès.),
						'other' => q({0} mil per galon Kaès.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} wètan),
						'north' => q({0} lor),
						'south' => q({0} kidul),
						'west' => q({0} kulon),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} wètan),
						'north' => q({0} lor),
						'south' => q({0} kidul),
						'west' => q({0} kulon),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(gigabit),
						'other' => q({0} gigabit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(gigabit),
						'other' => q({0} gigabit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(gigabèt),
						'other' => q({0} gigabèt),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(gigabèt),
						'other' => q({0} gigabèt),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilobit),
						'other' => q({0} kilobit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilobit),
						'other' => q({0} kilobit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilobèt),
						'other' => q({0} kilobèt),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilobèt),
						'other' => q({0} kilobèt),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(mègabit),
						'other' => q({0} mègabit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(mègabit),
						'other' => q({0} mègabit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(mègabèt),
						'other' => q({0} mègabèt),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(mègabèt),
						'other' => q({0} mègabèt),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(pètabèt),
						'other' => q({0} pètabèt),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(pètabèt),
						'other' => q({0} pètabèt),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(tèrabit),
						'other' => q({0} tèrabit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(tèrabit),
						'other' => q({0} tèrabit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(tèrabèt),
						'other' => q({0} tèrabèt),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(tèrabèt),
						'other' => q({0} tèrabèt),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(abad),
						'other' => q({0} abad),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(abad),
						'other' => q({0} abad),
					},
					# Long Unit Identifier
					'duration-day' => {
						'per' => q({0} per ari),
					},
					# Core Unit Identifier
					'day' => {
						'per' => q({0} per ari),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dékade),
						'other' => q({0} dékade),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dékade),
						'other' => q({0} dékade),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'per' => q({0} per jem),
					},
					# Core Unit Identifier
					'hour' => {
						'per' => q({0} per jem),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikrosekon),
						'other' => q({0} mikrosekon),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikrosekon),
						'other' => q({0} mikrosekon),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisekon),
						'other' => q({0} milisekon),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisekon),
						'other' => q({0} milisekon),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(menit),
						'other' => q({0} menit),
						'per' => q({0} per menit),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(menit),
						'other' => q({0} menit),
						'per' => q({0} per menit),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(bulan),
						'other' => q({0} bulan),
						'per' => q({0} per bulan),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(bulan),
						'other' => q({0} bulan),
						'per' => q({0} per bulan),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosekon),
						'other' => q({0} nanosek),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosekon),
						'other' => q({0} nanosek),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(kuartal),
						'other' => q({0} kuartal),
						'per' => q({0} per kuartal),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(kuartal),
						'other' => q({0} kuartal),
						'per' => q({0} per kuartal),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekon),
						'other' => q({0} sekon),
						'per' => q({0} per sekon),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekon),
						'other' => q({0} sekon),
						'per' => q({0} per sekon),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(minggu),
						'other' => q({0} minggu),
						'per' => q({0} per minggu),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(minggu),
						'other' => q({0} minggu),
						'per' => q({0} per minggu),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(tahon),
						'other' => q({0} tahon),
						'per' => q({0} per tahon),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(tahon),
						'other' => q({0} tahon),
						'per' => q({0} per tahon),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ampere),
						'other' => q({0} ampere),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ampere),
						'other' => q({0} ampere),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliampere),
						'other' => q({0} miliampere),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliampere),
						'other' => q({0} miliampere),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'other' => q({0} ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'other' => q({0} ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'other' => q({0} volt),
					},
					# Core Unit Identifier
					'volt' => {
						'other' => q({0} volt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(satuan panas Britani),
						'other' => q({0} satuan panas Britani),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(satuan panas Britani),
						'other' => q({0} satuan panas Britani),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kalori),
						'other' => q({0} kalori),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kalori),
						'other' => q({0} kalori),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'other' => q({0} èlèktronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'other' => q({0} èlèktronvolt),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'other' => q({0} joule),
					},
					# Core Unit Identifier
					'joule' => {
						'other' => q({0} joule),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokalori),
						'other' => q({0} kilokalori),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokalori),
						'other' => q({0} kilokalori),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'other' => q({0} kilojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'other' => q({0} kilojoule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilowatt-jem),
						'other' => q({0} kilowatt-jem),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilowatt-jem),
						'other' => q({0} kilowatt-jem),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-jem per 100 kilomèter),
						'other' => q({0} kilowatt-jem per 100 kilomèter),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-jem per 100 kilomèter),
						'other' => q({0} kilowatt-jem per 100 kilomèter),
					},
					# Long Unit Identifier
					'force-newton' => {
						'other' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'other' => q({0} newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'other' => q({0} pon gaya),
					},
					# Core Unit Identifier
					'pound-force' => {
						'other' => q({0} pon gaya),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(gigahertz),
						'other' => q({0} gigahertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(gigahertz),
						'other' => q({0} gigahertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(hertz),
						'other' => q({0} hertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(hertz),
						'other' => q({0} hertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kilohertz),
						'other' => q({0} kilohertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kilohertz),
						'other' => q({0} kilohertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(mègahertz),
						'other' => q({0} mègahertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(mègahertz),
						'other' => q({0} mègahertz),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(em tipograpis),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(em tipograpis),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(mègapiksel),
						'other' => q({0} mègapiksel),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(mègapiksel),
						'other' => q({0} mègapiksel),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(piksel),
						'other' => q({0} piksel),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(piksel),
						'other' => q({0} piksel),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(piksel per sèntimèter),
						'other' => q({0} piksel per sèntimèter),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(piksel per sèntimèter),
						'other' => q({0} piksel per sèntimèter),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(piksel per inci),
						'other' => q({0} piksel per inci),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(piksel per inci),
						'other' => q({0} piksel per inci),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(satuan palak),
						'other' => q({0} satuan palak),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(satuan palak),
						'other' => q({0} satuan palak),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sèntimèter),
						'other' => q({0} sèntimèter),
						'per' => q({0} per sèntimèter),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sèntimèter),
						'other' => q({0} sèntimèter),
						'per' => q({0} per sèntimèter),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(dèsimèter),
						'other' => q({0} dèsimèter),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(dèsimèter),
						'other' => q({0} dèsimèter),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(jari-jari Bumi),
						'other' => q({0} jari-jari Bumi),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(jari-jari Bumi),
						'other' => q({0} jari-jari Bumi),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(padem),
						'other' => q({0} padem),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(padem),
						'other' => q({0} padem),
					},
					# Long Unit Identifier
					'length-foot' => {
						'per' => q({0} per kaki),
					},
					# Core Unit Identifier
					'foot' => {
						'per' => q({0} per kaki),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(purlong),
						'other' => q({0} purlong),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(purlong),
						'other' => q({0} purlong),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(inci),
						'other' => q({0} inci),
						'per' => q({0} per inci),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(inci),
						'other' => q({0} inci),
						'per' => q({0} per inci),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilomèter),
						'other' => q({0} kilomèter),
						'per' => q({0} per kilomèter),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilomèter),
						'other' => q({0} kilomèter),
						'per' => q({0} per kilomèter),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(tahon cahaya),
						'other' => q({0} tahon cahaya),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(tahon cahaya),
						'other' => q({0} tahon cahaya),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(mèter),
						'other' => q({0} mèter),
						'per' => q({0} per mèter),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(mèter),
						'other' => q({0} mèter),
						'per' => q({0} per mèter),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(mikromèter),
						'other' => q({0} mikromèter),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(mikromèter),
						'other' => q({0} mikromèter),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mil),
						'other' => q({0} mil),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mil),
						'other' => q({0} mil),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(mil skandinawi),
						'other' => q({0} mil skandinawi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(mil skandinawi),
						'other' => q({0} mil skandinawi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milimèter),
						'other' => q({0} milimèter),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milimèter),
						'other' => q({0} milimèter),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanomèter),
						'other' => q({0} nanomèter),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanomèter),
						'other' => q({0} nanomèter),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(mil laot),
						'other' => q({0} mil laot),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(mil laot),
						'other' => q({0} mil laot),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsek),
						'other' => q({0} parsek),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsek),
						'other' => q({0} parsek),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikomèter),
						'other' => q({0} pikomèter),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikomèter),
						'other' => q({0} pikomèter),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(poin),
						'other' => q({0} poin),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(poin),
						'other' => q({0} poin),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(jari-jari Mataari),
						'other' => q({0} jari-jari Mataari),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(jari-jari Mataari),
						'other' => q({0} jari-jari Mataari),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yard),
						'other' => q({0} yard),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yard),
						'other' => q({0} yard),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kandèla),
						'other' => q({0} kandèla),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kandèla),
						'other' => q({0} kandèla),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumèn),
						'other' => q({0} lumèn),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumèn),
						'other' => q({0} lumèn),
					},
					# Long Unit Identifier
					'light-lux' => {
						'other' => q({0} luk),
					},
					# Core Unit Identifier
					'lux' => {
						'other' => q({0} luk),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'other' => q({0} pentèran Mataari),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'other' => q({0} pentèran Mataari),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'other' => q({0} dalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'other' => q({0} dalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(masa Bumi),
						'other' => q({0} masa Bumi),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(masa Bumi),
						'other' => q({0} masa Bumi),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'other' => q({0} gram),
						'per' => q({0} per gram),
					},
					# Core Unit Identifier
					'gram' => {
						'other' => q({0} gram),
						'per' => q({0} per gram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} per kilogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilogram),
						'other' => q({0} kilogram),
						'per' => q({0} per kilogram),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(mikrogram),
						'other' => q({0} mikrogram),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(mikrogram),
						'other' => q({0} mikrogram),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(miligram),
						'other' => q({0} miligram),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(miligram),
						'other' => q({0} miligram),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'per' => q({0} per on),
					},
					# Core Unit Identifier
					'ounce' => {
						'per' => q({0} per on),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'per' => q({0} per pon),
					},
					# Core Unit Identifier
					'pound' => {
						'per' => q({0} per pon),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(masa Mataari),
						'other' => q({0} masa Mataari),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(masa Mataari),
						'other' => q({0} masa Mataari),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'other' => q({0} batu),
					},
					# Core Unit Identifier
					'stone' => {
						'other' => q({0} batu),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(ton Amrik Serèkat),
						'other' => q({0} ton Amrik Serèkat),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(ton Amrik Serèkat),
						'other' => q({0} ton Amrik Serèkat),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(ton mètrik),
						'other' => q({0} ton mètrik),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(ton mètrik),
						'other' => q({0} ton mètrik),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} per {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} per {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(gigawatt),
						'other' => q({0} gigawatt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(gigawatt),
						'other' => q({0} gigawatt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(tenaga kuda),
						'other' => q({0} tenaga kuda),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(tenaga kuda),
						'other' => q({0} tenaga kuda),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilowatt),
						'other' => q({0} kilowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilowatt),
						'other' => q({0} kilowatt),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(mègawatt),
						'other' => q({0} mègawatt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(mègawatt),
						'other' => q({0} mègawatt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(miliwatt),
						'other' => q({0} miliwatt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(miliwatt),
						'other' => q({0} miliwatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'other' => q({0} watt),
					},
					# Core Unit Identifier
					'watt' => {
						'other' => q({0} watt),
					},
					# Long Unit Identifier
					'power2' => {
						'other' => q({0} pesegi),
					},
					# Core Unit Identifier
					'power2' => {
						'other' => q({0} pesegi),
					},
					# Long Unit Identifier
					'power3' => {
						'other' => q({0} kubik),
					},
					# Core Unit Identifier
					'power3' => {
						'other' => q({0} kubik),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(atmospir),
						'other' => q({0} atmospir),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(atmospir),
						'other' => q({0} atmospir),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hèktopascal),
						'other' => q({0} hèktopascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hèktopascal),
						'other' => q({0} hèktopascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(inci raksa),
						'other' => q({0} inci raksa),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(inci raksa),
						'other' => q({0} inci raksa),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kilopascal),
						'other' => q({0} kilopascal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilopascal),
						'other' => q({0} kilopascal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(mègapascal),
						'other' => q({0} mègapascal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(mègapascal),
						'other' => q({0} mègapascal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(milibar),
						'other' => q({0} milibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(milibar),
						'other' => q({0} milibar),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(milimèter raksa),
						'other' => q({0} milimèter raksa),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(milimèter raksa),
						'other' => q({0} milimèter raksa),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(pascal),
						'other' => q({0} pascal),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(pascal),
						'other' => q({0} pascal),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(pon per inci pesegi),
						'other' => q({0} pon per inci pesegi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(pon per inci pesegi),
						'other' => q({0} pon per inci pesegi),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Beaufort),
						'other' => q(Beaufort {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Beaufort),
						'other' => q(Beaufort {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilomèter per jem),
						'other' => q({0} kilomèter per jem),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilomèter per jem),
						'other' => q({0} kilomèter per jem),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(kenop),
						'other' => q({0} kenop),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(kenop),
						'other' => q({0} kenop),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(mèter per sekon),
						'other' => q({0} mèter per sekon),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(mèter per sekon),
						'other' => q({0} mèter per sekon),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mil per jem),
						'other' => q({0} mil per jem),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mil per jem),
						'other' => q({0} mil per jem),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(derajat Celsius),
						'other' => q({0} derajat Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(derajat Celsius),
						'other' => q({0} derajat Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(deraja Fahrenheit),
						'other' => q({0} derajat Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(deraja Fahrenheit),
						'other' => q({0} derajat Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelvin),
						'other' => q({0} kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelvin),
						'other' => q({0} kelvin),
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
						'name' => q(newton mèter),
						'other' => q({0} newton mèter),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(newton mèter),
						'other' => q({0} newton mèter),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pon kaki),
						'other' => q({0} pon kaki),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pon kaki),
						'other' => q({0} pon kaki),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(aker kaki),
						'other' => q({0} aker kaki),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(aker kaki),
						'other' => q({0} aker kaki),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'other' => q({0} barèl),
					},
					# Core Unit Identifier
					'barrel' => {
						'other' => q({0} barèl),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'other' => q({0} gantang),
					},
					# Core Unit Identifier
					'bushel' => {
						'other' => q({0} gantang),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sèntilèter),
						'other' => q({0} sèntilèter),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sèntilèter),
						'other' => q({0} sèntilèter),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(sèntimèter kibik),
						'other' => q({0} sèntimèter kibik),
						'per' => q({0} per sèntimèter kibik),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(sèntimèter kibik),
						'other' => q({0} sèntimèter kibik),
						'per' => q({0} per sèntimèter kibik),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(kaki kibik),
						'other' => q({0} kaki kibik),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(kaki kibik),
						'other' => q({0} kaki kibik),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(inci kibik),
						'other' => q({0} inci kibik),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(inci kibik),
						'other' => q({0} inci kibik),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kilomèter kibik),
						'other' => q({0} kilomèter kibik),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kilomèter kibik),
						'other' => q({0} kilomèter kibik),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(mèter kibik),
						'other' => q({0} mèter kibik),
						'per' => q({0} per mèter kibik),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(mèter kibik),
						'other' => q({0} mèter kibik),
						'per' => q({0} per mèter kibik),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(mil kibik),
						'other' => q({0} mil kibik),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(mil kibik),
						'other' => q({0} mil kibik),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yard kibik),
						'other' => q({0} yard kibik),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yard kibik),
						'other' => q({0} yard kibik),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'other' => q({0} cangkir),
					},
					# Core Unit Identifier
					'cup' => {
						'other' => q({0} cangkir),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(cangkir mètrik),
						'other' => q({0} cangkir mètrik),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(cangkir mètrik),
						'other' => q({0} cangkir mètrik),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(dèsilèter),
						'other' => q({0} dèsilèter),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(dèsilèter),
						'other' => q({0} dèsilèter),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(tèsi kué),
						'other' => q({0} tèsi kué),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(tèsi kué),
						'other' => q({0} tèsi kué),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(tèsi kué Kaès.),
						'other' => q({0} tèsi kué Kaès.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(tèsi kué Kaès.),
						'other' => q({0} tèsi kué Kaès.),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(on caèr),
						'other' => q({0} on caèr),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(on caèr),
						'other' => q({0} on caèr),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(on caèr Kaès.),
						'other' => q({0} on caèr Kaès.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(on caèr Kaès.),
						'other' => q({0} on caèr Kaès.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(galon),
						'other' => q({0} galon),
						'per' => q({0} per galon),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(galon),
						'other' => q({0} galon),
						'per' => q({0} per galon),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(galon Kaès.),
						'other' => q({0} galon Kaès.),
						'per' => q({0} per galon Kaès.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(galon Kaès.),
						'other' => q({0} galon Kaès.),
						'per' => q({0} per galon Kaès.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hèktolèter),
						'other' => q({0} hèktolèter),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hèktolèter),
						'other' => q({0} hèktolèter),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'other' => q({0} lèter),
						'per' => q({0} per lèter),
					},
					# Core Unit Identifier
					'liter' => {
						'other' => q({0} lèter),
						'per' => q({0} per lèter),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(mègalèter),
						'other' => q({0} mègalèter),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(mègalèter),
						'other' => q({0} mègalèter),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mililèter),
						'other' => q({0} mililèter),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mililèter),
						'other' => q({0} mililèter),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'other' => q({0} pint),
					},
					# Core Unit Identifier
					'pint' => {
						'other' => q({0} pint),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(pint mètrik),
						'other' => q({0} pint mètrik),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pint mètrik),
						'other' => q({0} pint mètrik),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kuart),
						'other' => q({0} kuart),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kuart),
						'other' => q({0} kuart),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(kuart Kaès.),
						'other' => q({0} kuart Kaès.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(kuart Kaès.),
						'other' => q({0} kuart Kaès.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(tèsi makan),
						'other' => q({0} tèsi makan),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(tèsi makan),
						'other' => q({0} tèsi makan),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(tèsi té),
						'other' => q({0} tèsi té),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(tèsi té),
						'other' => q({0} tèsi té),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(m busur),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(m busur),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(s busur),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(s busur),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(drj),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(drj),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'other' => q({0}rad),
					},
					# Core Unit Identifier
					'radian' => {
						'other' => q({0}rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'other' => q({0}kit),
					},
					# Core Unit Identifier
					'revolution' => {
						'other' => q({0}kit),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'other' => q({0} inci²),
						'per' => q({0}/inci²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'other' => q({0} inci²),
						'per' => q({0}/inci²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yd²),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mpg Kaès.),
						'other' => q({0} m/g Kaès.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mpg Kaès.),
						'other' => q({0} m/g Kaès.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}w),
						'north' => q({0}l),
						'south' => q({0}kdl),
						'west' => q({0}kln),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}w),
						'north' => q({0}l),
						'south' => q({0}kdl),
						'west' => q({0}kln),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(B),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(B),
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
					'digital-megabit' => {
						'name' => q(Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mb),
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
					'duration-hour' => {
						'name' => q(j),
						'other' => q({0} j),
						'per' => q({0}/j),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(j),
						'other' => q({0} j),
						'per' => q({0}/j),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μs),
						'other' => q({0} μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μs),
						'other' => q({0} μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ms),
						'other' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ms),
						'other' => q({0} ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(ns),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kWh),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(N),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(N),
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
					'graphics-megapixel' => {
						'name' => q(MP),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(MP),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(px),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(px),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'other' => q({0} au),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'other' => q({0} au),
					},
					# Long Unit Identifier
					'length-inch' => {
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'inch' => {
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(tc),
						'other' => q({0} tc),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(tc),
						'other' => q({0} tc),
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
					'mass-grain' => {
						'name' => q(gr),
						'other' => q({0} gr),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gr),
						'other' => q({0} gr),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(oz),
						'per' => q({0}/oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(oz),
						'per' => q({0}/oz),
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
						'name' => q(″ Hg),
						'other' => q({0}″ Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(″ Hg),
						'other' => q({0}″ Hg),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/j),
						'other' => q({0} km/j),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/j),
						'other' => q({0} km/j),
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
					'speed-mile-per-hour' => {
						'name' => q(mil/j),
						'other' => q({0} mil/j),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mil/j),
						'other' => q({0} mil/j),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fl.dr.),
						'other' => q({0} fl.dr.),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fl.dr.),
						'other' => q({0} fl.dr.),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'other' => q({0} galIm),
						'per' => q({0}/galIm),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'other' => q({0} galIm),
						'per' => q({0}/galIm),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'other' => q({0}),
					},
					# Core Unit Identifier
					'pinch' => {
						'other' => q({0}),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(arah),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(arah),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/sek²),
						'other' => q({0} m/sek²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/sek²),
						'other' => q({0} m/sek²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(mnt busur),
						'other' => q({0} mnt busur),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(mnt busur),
						'other' => q({0} mnt busur),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(sek busur),
						'other' => q({0} sek busur),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(sek busur),
						'other' => q({0} sek busur),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(derajat),
						'other' => q({0} drj),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(derajat),
						'other' => q({0} drj),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(radial),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(radial),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(kit),
						'other' => q({0} kit),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(kit),
						'other' => q({0} kit),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(aker),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(aker),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hèktar),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hèktar),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(inci²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(inci²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yard²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yard²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(biji),
						'other' => q({0} biji),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(biji),
						'other' => q({0} biji),
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
						'name' => q(milimol/lèter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimol/lèter),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(prosèn),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(prosèn),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(perèbu),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(perèbu),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(bagèan/juta),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(bagèan/juta),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(perceban),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(perceban),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(lèter/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(lèter/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mil/gal),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mil/gal),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mil/gal Kaès.),
						'other' => q({0} mpg Kaès.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mil/gal Kaès.),
						'other' => q({0} mpg Kaès.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} w),
						'north' => q({0} l),
						'south' => q({0} kdl),
						'west' => q({0} kln),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} w),
						'north' => q({0} l),
						'south' => q({0} kdl),
						'west' => q({0} kln),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(bèt),
						'other' => q({0} bèt),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(bèt),
						'other' => q({0} bèt),
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
						'name' => q(GBèt),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GBèt),
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
						'name' => q(kBèt),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kBèt),
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
						'name' => q(MBèt),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MBèt),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PBèt),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PBèt),
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
						'name' => q(TBèt),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TBèt),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(abd),
						'other' => q({0} abd),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(abd),
						'other' => q({0} abd),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ari),
						'other' => q({0} ari),
						'per' => q({0}/ari),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ari),
						'other' => q({0} ari),
						'per' => q({0}/ari),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(dék),
						'other' => q({0} dék),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(dék),
						'other' => q({0} dék),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(jem),
						'other' => q({0} jem),
						'per' => q({0}/jem),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(jem),
						'other' => q({0} jem),
						'per' => q({0}/jem),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μsek),
						'other' => q({0} μsek),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μsek),
						'other' => q({0} μsek),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisek),
						'other' => q({0} msek),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisek),
						'other' => q({0} msek),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(mnt),
						'other' => q({0} mnt),
						'per' => q({0}/mnt),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(mnt),
						'other' => q({0} mnt),
						'per' => q({0}/mnt),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(bln),
						'other' => q({0} bln),
						'per' => q({0}/bln),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(bln),
						'other' => q({0} bln),
						'per' => q({0}/bln),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nsek),
						'other' => q({0} nsek),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nsek),
						'other' => q({0} nsek),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(krtl),
						'other' => q({0} krtl),
						'per' => q({0}/krtl),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(krtl),
						'other' => q({0} krtl),
						'per' => q({0}/krtl),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sek),
						'other' => q({0} sek),
						'per' => q({0}/sek),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sek),
						'other' => q({0} sek),
						'per' => q({0}/sek),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(mgg),
						'other' => q({0} mgg),
						'per' => q({0}/mgg),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(mgg),
						'other' => q({0} mgg),
						'per' => q({0}/mgg),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(thn),
						'other' => q({0} thn),
						'per' => q({0}/thn),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(thn),
						'other' => q({0} thn),
						'per' => q({0}/thn),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliamp),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliamp),
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
						'other' => q({0} kal),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kal),
						'other' => q({0} kal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(èlèktronvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(èlèktronvolt),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kkal),
						'other' => q({0} kkal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kkal),
						'other' => q({0} kkal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilojoule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilojoule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kW-jem),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kW-jem),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(tèrem AS),
						'other' => q({0} tèrem AS),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(tèrem AS),
						'other' => q({0} tèrem AS),
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
						'name' => q(pon gaya),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pon gaya),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(Mpiks),
						'other' => q({0} Mpiks),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(Mpiks),
						'other' => q({0} Mpiks),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(piks),
						'other' => q({0} piks),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(piks),
						'other' => q({0} piks),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(sa),
						'other' => q({0} sa),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(sa),
						'other' => q({0} sa),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(pdm),
						'other' => q({0} pdm),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(pdm),
						'other' => q({0} pdm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(kaki),
						'other' => q({0} kaki),
						'per' => q({0}/kaki),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(kaki),
						'other' => q({0} kaki),
						'per' => q({0}/kaki),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(thn cah),
						'other' => q({0} thn cah),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(thn cah),
						'other' => q({0} thn cah),
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
					'light-lux' => {
						'name' => q(luk),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(luk),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(pentèran Mataari),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(pentèran Mataari),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(karat),
						'other' => q({0} karat),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(karat),
						'other' => q({0} karat),
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
					'mass-grain' => {
						'name' => q(grèn),
						'other' => q({0} grèn),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(grèn),
						'other' => q({0} grèn),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(on),
						'other' => q({0} on),
						'per' => q({0}/on),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(on),
						'other' => q({0} on),
						'per' => q({0}/on),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(on troy),
						'other' => q({0} on troy),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(on troy),
						'other' => q({0} on troy),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(pon),
						'other' => q({0} pon),
						'per' => q({0}/pon),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(pon),
						'other' => q({0} pon),
						'per' => q({0}/pon),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(batu),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(batu),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(ton AS),
						'other' => q({0} tn AS),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(ton AS),
						'other' => q({0} tn AS),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(tk),
						'other' => q({0} tk),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(tk),
						'other' => q({0} tk),
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
					'speed-kilometer-per-hour' => {
						'name' => q(km/jem),
						'other' => q({0} km/jem),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/jem),
						'other' => q({0} km/jem),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(m/sek),
						'other' => q({0} m/sek),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(m/sek),
						'other' => q({0} m/sek),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mil/jem),
						'other' => q({0} mil/jem),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mil/jem),
						'other' => q({0} mil/jem),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barèl),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barèl),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(gantang),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(gantang),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(inci³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(inci³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yard³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yard³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(cangkir),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(cangkir),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(tsk),
						'other' => q({0} tsk),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(tsk),
						'other' => q({0} tsk),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(tsk Kaès.),
						'other' => q({0} tsk Kaès.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(tsk Kaès.),
						'other' => q({0} tsk Kaès.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(dirham caèr),
						'other' => q({0} dirham caèr),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(dirham caèr),
						'other' => q({0} dirham caèr),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(tètès),
						'other' => q({0} tètès),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(tètès),
						'other' => q({0} tètès),
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
					'volume-fluid-ounce-imperial' => {
						'name' => q(fl oz Kaès.),
						'other' => q({0} fl oz Kaès.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(fl oz Kaès.),
						'other' => q({0} fl oz Kaès.),
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
						'name' => q(gal Kaès.),
						'other' => q({0} gal Kaès.),
						'per' => q({0}/gal Kaès.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(gal Kaès.),
						'other' => q({0} gal Kaès.),
						'per' => q({0}/gal Kaès.),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(takeran gula),
						'other' => q({0} takeran gula),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(takeran gula),
						'other' => q({0} takeran gula),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(lèter),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(lèter),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(jumput),
						'other' => q({0} jumput),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(jumput),
						'other' => q({0} jumput),
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
					'volume-quart-imperial' => {
						'name' => q(qt Kaès.),
						'other' => q({0} qt Kaès.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(qt Kaès.),
						'other' => q({0} qt Kaès.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(tsm),
						'other' => q({0} tsm),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(tsm),
						'other' => q({0} tsm),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(tst),
						'other' => q({0} tst),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(tst),
						'other' => q({0} tst),
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
	default		=> sub { qr'^(?i:kaga’|k|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, èn {1}),
				2 => q({0} èn {1}),
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
			'long' => {
				'1000' => {
					'other' => '0 rèbu',
				},
				'10000' => {
					'other' => '00 rèbu',
				},
				'100000' => {
					'other' => '000 rèbu',
				},
				'1000000' => {
					'other' => '0 juta',
				},
				'10000000' => {
					'other' => '00 juta',
				},
				'100000000' => {
					'other' => '000 juta',
				},
				'1000000000' => {
					'other' => '0 miliar',
				},
				'10000000000' => {
					'other' => '00 miliar',
				},
				'100000000000' => {
					'other' => '000 miliar',
				},
				'1000000000000' => {
					'other' => '0 triliun',
				},
				'10000000000000' => {
					'other' => '00 triliun',
				},
				'100000000000000' => {
					'other' => '000 triliun',
				},
			},
			'short' => {
				'1000' => {
					'other' => '0 rb',
				},
				'10000' => {
					'other' => '00 rb',
				},
				'100000' => {
					'other' => '000 rb',
				},
				'1000000' => {
					'other' => '0 jt',
				},
				'10000000' => {
					'other' => '00 jt',
				},
				'100000000' => {
					'other' => '000 jt',
				},
				'1000000000' => {
					'other' => '0 M',
				},
				'10000000000' => {
					'other' => '00 M',
				},
				'100000000000' => {
					'other' => '000 M',
				},
				'1000000000000' => {
					'other' => '0 T',
				},
				'10000000000000' => {
					'other' => '00 T',
				},
				'100000000000000' => {
					'other' => '000 T',
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
						'positive' => '¤#,##0.00',
					},
					'standard' => {
						'positive' => '¤ 0 rb',
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
				'currency' => q(Dirham Imarat Arab Rempug),
				'other' => q(dirham Imarat Arab Rempug),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Apgani Apganistan),
				'other' => q(apgani Apganistan),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Lèk Albani),
				'other' => q(lèk Albani),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Dirham Lemènder),
				'other' => q(dirham Lemènder),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Gulden Antilen Belanda),
				'other' => q(gulden Antilen Belanda),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kuansa Anggola),
				'other' => q(kuansa Anggola),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Pèso Argèntina),
				'other' => q(pèso Argèntina),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dolar Ostrali),
				'other' => q(dolar Ostrali),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Plorèn Aruba),
				'other' => q(plorèn Aruba),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Manat Asèrbaijan),
				'other' => q(manat Asèrbaijan),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Marek Tukeran Bosni-Hèrségowina),
				'other' => q(marek tukeran Bosni-Hèrségowina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Dolar Barbados),
				'other' => q(dolar Barbados),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka Benggaladésa),
				'other' => q(taka Benggaladésa),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Lèp Bulgari),
				'other' => q(lèp Bulgari),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinar Bahrén),
				'other' => q(dinar Bahrén),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Prang Burundi),
				'other' => q(prang Burundi),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Dolar Bermuda),
				'other' => q(dolar Bermuda),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Ringgit Bruné),
				'other' => q(ringgit Bruné),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliwiano Boliwi),
				'other' => q(boliwiano Boliwi),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Rèal Brasil),
				'other' => q(rèal Brasil),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Dolar Bahama),
				'other' => q(dolar Bahama),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ngultrum Butan),
				'other' => q(ngultrum Butan),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula Boswana),
				'other' => q(pula Boswana),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Rubel Ruslan Puti),
				'other' => q(rubel Ruslan Puti),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Dolar Bélis),
				'other' => q(dolar Bélis),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dolar Kanada),
				'other' => q(dolar Kanada),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Prang Kongo),
				'other' => q(prang Kongo),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Prang Switserlan),
				'other' => q(prang Switserlan),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Pèso Cili),
				'other' => q(pèso Cili),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yuèn Tiongkok \(luar negeri\)),
				'other' => q(yuèn Tiongkok \(luar negeri\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuèn Tiongkok),
				'other' => q(yuèn Tiongkok),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Pèso Kolombia),
				'other' => q(pèso Kolombia),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Kolon Kosta Rika),
				'other' => q(kolon Kosta Rika),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Pèso Tukeran Kuba),
				'other' => q(pèso tukeran Kuba),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Pèso Kuba),
				'other' => q(pèso Kuba),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Èskudo Tanjung Ijo),
				'other' => q(èskudo Tanjung Ijo),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Kron Cèko),
				'other' => q(kron Cèko),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Prang Jibuti),
				'other' => q(prang Jibuti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Kron Dènemarken),
				'other' => q(kron Dènemarken),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Pèso Dominika),
				'other' => q(pèso Dominika),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinar Aljajaèr),
				'other' => q(dinar Aljajaèr),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Pon Mesir),
				'other' => q(pon Mesir),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(nakpa Èritréa),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Bir Habsi),
				'other' => q(bir Habsi),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Èuro),
				'other' => q(èuro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Dolar Piji),
				'other' => q(dolar Piji),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Pon Pulo Paklan),
				'other' => q(pon Pulo Paklan),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Pon Britani),
				'other' => q(pon Britani),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Lari Géorgi),
				'other' => q(lari Géorgi),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Sédi Gana),
				'other' => q(sédi Gana),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Pon Jabal Tarik),
				'other' => q(pon Jabal Tarik),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi Gana),
				'other' => q(dalasi Gambia),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Prang Giné),
				'other' => q(prang Giné),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Kètsal Guatémala),
				'other' => q(kètsal Guatémala),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Dolar Guyana),
				'other' => q(dolar Guyana),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Dolar Hongkong),
				'other' => q(dolar Hongkong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lèmpira Honduras),
				'other' => q(lèmpira Honduras),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna Kroasi),
				'other' => q(kuna Kroasi),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gurda Haiti),
				'other' => q(gurda Haiti),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Porin Honggari),
				'other' => q(porin Honggari),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Rupiah Indonésia),
				'other' => q(rupiah Indonésia),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Sèkèl Baru Israèl),
				'other' => q(sèkèl baru Israèl),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupiah Hindi),
				'other' => q(rupiah Hindi),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Dinar Irak),
				'other' => q(dinar Irak),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Rèal Iran),
				'other' => q(rèal Iran),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Kron Èslan),
				'other' => q(kron Èslan),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Dolar Jamaika),
				'other' => q(dolar Jamaika),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dinar Urdun),
				'other' => q(dinar Urdun),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yèn Jepang),
				'other' => q(yèn Jepang),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Siling Kénia),
				'other' => q(siling Kénia),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Sum Kirgistan),
				'other' => q(sum Kirgistan),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Rèal Kemboja),
				'other' => q(rèal Kemboja),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Prang Komoro),
				'other' => q(prang Komoro),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Won Koréa Lor),
				'other' => q(won Koréa Lor),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Won Koréa Kidul),
				'other' => q(won Koréa Kidul),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Dinar Kuwaèt),
				'other' => q(dinar Kuwaèt),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Dolar Pulo Kaèman),
				'other' => q(dolar Pulo Kaèman),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tènggé Kasakstan),
				'other' => q(tènggé Kasakstan),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Kip Laos),
				'other' => q(kip Laos),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Pon Lèbanon),
				'other' => q(pon Lèbanon),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Rupiah Sri Langka),
				'other' => q(rupiah Sri Langka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dolar Libéria),
				'other' => q(dolar Libéria),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti Lésoto),
				'other' => q(loti Lésoto),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinar Libi),
				'other' => q(dinar Libi),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirham Maroko),
				'other' => q(dirham Maroko),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Léu Moldawi),
				'other' => q(léu Moldawi),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Rèal Madagaskar),
				'other' => q(rèal Madagaskar),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Dinar Makèdoni),
				'other' => q(dinar Makèdoni),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kiat Mianmar),
				'other' => q(kiat Mianmar),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Tugrik Monggoli),
				'other' => q(tugrik Monggoli),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataka Makao),
				'other' => q(pataka Makao),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ukiah Moritani),
				'other' => q(ukiah Moritani),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupiah Moritius),
				'other' => q(rupiah Moritius),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rupiah Maladéwa),
				'other' => q(rupiah Maladéwa),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kuaca Malawi),
				'other' => q(kuaca Malawi),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Pèso Mèksiko),
				'other' => q(pèso Mèksiko),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Pèso Pèrak Mèksiko \(1861–1992\)),
				'other' => q(pèso pèrak Mèksiko \(1861–1992\)),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ringgit Malésia),
				'other' => q(ringgit Malésia),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Miskal Mosambik),
				'other' => q(miskal Mosambik),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dolar Namibi),
				'other' => q(dolar Namibi),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira Nigéria),
				'other' => q(naira Nigéria),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Kordoba Nikaragua \(1988–1991\)),
				'other' => q(kordoba Nikaragua \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Kordoba Nikaragua),
				'other' => q(kordoba Nikaragua),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Kron Norwèhen),
				'other' => q(kron Norwèhen),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rupiah Népal),
				'other' => q(rupiah Népal),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Dolar Sélan Baru),
				'other' => q(dolar Sélan Baru),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Rèal Oman),
				'other' => q(rèal Oman),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Balboa Panama),
				'other' => q(balboa Panama),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Sol Péru),
				'other' => q(sol Péru),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina Papua Giné Baru),
				'other' => q(kina Papua Giné Baru),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(Pèso Pilipénen),
				'other' => q(pèso Pilipénen),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rupiah Pakistan),
				'other' => q(rupiah Pakistan),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Złoty Polen),
				'other' => q(złoty Polen),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Guarani Paragué),
				'other' => q(guarani Paragué),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Rèal Katar),
				'other' => q(rèal Katar),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Léu Ruméni),
				'other' => q(léu Ruméni),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dinar Sèrwi),
				'other' => q(dinar Sèrwi),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rubel Ruslan),
				'other' => q(rubel Ruslan),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Prang Ruanda),
				'other' => q(prang Ruanda),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Rèal Saudi),
				'other' => q(rèal Saudi),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Dolar Pulo Suléman),
				'other' => q(dolar Pulo Suléman),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupiah Sésèl),
				'other' => q(rupiah Sésèl),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Pon Sudan),
				'other' => q(pon Sudan),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Kron Swèden),
				'other' => q(kron Swèden),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Dolar Singapur),
				'other' => q(dolar Singapur),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Pon Sint Héléna),
				'other' => q(pon Sint Héléna),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Léon Gunung Singa),
				'other' => q(léon Gunung Singa),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Léon Gunung Singa \(1964—2022\)),
				'other' => q(léon Gunung Singa \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Siling Somali),
				'other' => q(siling Somali),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Dolar Suriname),
				'other' => q(dolar Suriname),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Pon Sudan Kidul),
				'other' => q(pon Sudan Kidul),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra Sint Tomas èn Prins),
				'other' => q(dobra Sint Tomas èn Prins),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Kolon Salbador),
				'other' => q(kolon Salbador),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Pon Suriah),
				'other' => q(pon Suriah),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilanggéni Swasilan),
				'other' => q(lilanggéni Swasilan),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Bat Muang-Tay),
				'other' => q(bat Muang-Tay),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Samani Tajikistan),
				'other' => q(samani Tajikistan),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Manat Turkmènistan),
				'other' => q(manat Turkmènistan),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinar Tunis),
				'other' => q(dinar Tunis),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Pa’anga Tonga),
				'other' => q(pa’anga Tonga),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Lira Turki),
				'other' => q(lira Turki),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dolar Trinidad èn Tobago),
				'other' => q(dolar Trinidad èn Tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Yuèn Baru Taiwan),
				'other' => q(yuèn baru Taiwan),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Siling Tansania),
				'other' => q(siling Tansania),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Heriwnia Ukrain),
				'other' => q(heriwnia Ukrain),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Siling Uganda),
				'other' => q(siling Uganda),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(Dolar Amrik Serèkat),
				'other' => q(dolar Amrik Serèkat),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(Dolar AS \(Bèsokannya\)),
				'other' => q(dolar AS \(bèsokannya\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(Dolar AS \(Ari nyang sama\)),
				'other' => q(dolar AS \(ari nyang sama\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Pèso Urugué),
				'other' => q(pèso Urugué),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Sum Usbèkistan),
				'other' => q(sum Usbèkistan),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Boliwar Bénésuèla),
				'other' => q(boliwar Bénésuèla),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Dong Piètnam),
				'other' => q(dong Piètnam),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Watu Wanuatu),
				'other' => q(watu Wanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Dolar Samoa),
				'other' => q(dolar Samoa),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Prang CFA Aprika Tenga),
				'other' => q(prang CFA Aprika Tenga),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Dolar Karaiben Wètan),
				'other' => q(dolar Karaiben Wètan),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Prang CFA Aprika Kulon),
				'other' => q(prang CFA Aprika Kulon),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Prang CFP),
				'other' => q(prang CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Mata Uang Kaga’ Ditauin),
				'other' => q(\(mata uang kaga’ ditauin\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Rèal Yaman),
				'other' => q(rèal Yaman),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Ran Aprika Kidul),
				'other' => q(ran Aprika Kidul),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kuaca Sambia),
				'other' => q(kuaca Sambia),
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
							'Jan',
							'Pèb',
							'Mar',
							'Apr',
							'Méi',
							'Jun',
							'Jul',
							'Ags',
							'Sèp',
							'Okt',
							'Nop',
							'Dés'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Januari',
							'Pèbruari',
							'Maret',
							'April',
							'Méi',
							'Juni',
							'Juli',
							'Agustus',
							'Sèptèmber',
							'Oktober',
							'Nopèmber',
							'Désèmber'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'J',
							'P',
							'M',
							'A',
							'M',
							'J',
							'J',
							'A',
							'S',
							'O',
							'N',
							'D'
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
							'Sur.',
							'Sap.',
							'Mul.',
							'S. Mul.',
							'Jum. I',
							'Jum. II',
							'Rej.',
							'Roa.',
							'Psa.',
							'Saw.',
							'Hap.',
							'Haj.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Sura',
							'Sapar',
							'Mulud',
							'Seri Mulud',
							'Jumadilawal',
							'Jumadilakir',
							'Rejeb',
							'Roah',
							'Puasa',
							'Sawal',
							'Hapit',
							'Haji'
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
						mon => 'Sen',
						tue => 'Sel',
						wed => 'Reb',
						thu => 'Kem',
						fri => 'Jum',
						sat => 'Sap',
						sun => 'Min'
					},
					wide => {
						mon => 'Senèn',
						tue => 'Selasa',
						wed => 'Rebo',
						thu => 'Kemis',
						fri => 'Juma’at',
						sat => 'Saptu',
						sun => 'Minggu'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'S',
						tue => 'S',
						wed => 'R',
						thu => 'K',
						fri => 'J',
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
					abbreviated => {0 => 'K1',
						1 => 'K2',
						2 => 'K3',
						3 => 'K4'
					},
					wide => {0 => 'kuartal ke-1',
						1 => 'kuartal ke-2',
						2 => 'kuartal ke-3',
						3 => 'kuartal ke-4'
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
					'am' => q{pg/sg},
					'pm' => q{sr/mlm},
				},
				'wide' => {
					'am' => q{pagi/siang},
					'pm' => q{soré/malem},
				},
			},
			'stand-alone' => {
				'wide' => {
					'am' => q{pagi/siang},
					'pm' => q{soré/malem},
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
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'SM',
				'1' => 'M'
			},
			wide => {
				'0' => 'Jaman Kita',
				'1' => 'Masèhi'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'H'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
		},
		'generic' => {
			'full' => q{EEEE, d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd/MM/yy},
		},
		'islamic' => {
		},
	} },
);

has 'time_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH.mm.ss zzzz},
			'long' => q{HH.mm.ss z},
			'medium' => q{HH.mm.ss},
			'short' => q{HH.mm},
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
		'chinese' => {
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
			Bhm => q{h.mm B},
			Bhms => q{h.mm.ss B},
			EBhm => q{E h.mm B},
			EBhms => q{E h.mm.ss B},
			EHm => q{E HH.mm},
			EHms => q{E HH.mm.ss},
			Ed => q{E, d},
			Ehm => q{E h.mm a},
			Ehms => q{E h.mm.ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d/M/y GGGGG},
			Hm => q{HH.mm},
			Hms => q{HH.mm.ss},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h.mm a},
			hms => q{h.mm.ss a},
			ms => q{mm.ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Bhm => q{h.mm B},
			Bhms => q{h.mm.ss B},
			EBhm => q{E h.mm B},
			EBhms => q{E h.mm.ss B},
			EHm => q{E HH.mm},
			EHms => q{E HH.mm.ss},
			Ed => q{E, d},
			Ehm => q{E h.mm a},
			Ehms => q{E h.mm.s a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{d/M/y GGGGG},
			Hm => q{HH.mm},
			Hms => q{HH.mm.ss},
			Hmsv => q{HH.mm.ss v},
			Hmv => q{HH.mm v},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMW => q{'minggu' 'ke'-W MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h.mm a},
			hms => q{h.mm.ss a},
			hmsv => q{h.mm.ss. a v},
			hmv => q{h.mm a v},
			ms => q{mm.ss},
			yM => q{M/y},
			yMEd => q{E, d/M/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'minggu' 'ke'-w Y},
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
				B => q{h.mm B – h.mm B},
				h => q{h.mm–h.mm B},
				m => q{h.mm–h.mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y–y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, d/M/y GGGGG – E, d/M/y GGGGG},
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
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
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
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
				d => q{d–d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
		},
		'gregorian' => {
			Bhm => {
				B => q{h.mm B – h.mm B},
				h => q{h.mm–h.mm B},
				m => q{h.mm–h.mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGG – M/y GGGG},
				M => q{M/y – M/y GGGG},
				y => q{M/y – M/y GGGG},
			},
			GyMEd => {
				G => q{E, d/M/y GGGG – E, d/M/y GGGG},
				M => q{E, d/M/y – E, d/M/y GGGG},
				d => q{E, d/M/y – E, d/M/y GGGG},
				y => q{E, d/M/y – E, d/M/y GGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y – E, d MMM y G},
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d MMM y G – d MMM y G},
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			GyMd => {
				G => q{d/M/y GGGG – d/M/y GGGG},
				M => q{d/M/y – d/M/y GGGG},
				d => q{d/M/y – d/My GGGG},
				y => q{d/M/y – d/M/y GGGG},
			},
			Hm => {
				H => q{HH.mm–HH.mm},
				m => q{HH.mm–HH.mm},
			},
			Hmv => {
				H => q{HH.mm–HH.mm v},
				m => q{HH.mm–HH.mm v},
			},
			M => {
				M => q{M–M},
			},
			MEd => {
				M => q{E, d/M – E, d/M},
				d => q{E, d/M – E, d/M},
			},
			MMM => {
				M => q{LLL – LLL},
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
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			h => {
				a => q{h a – h a},
				h => q{h–h a},
			},
			hm => {
				a => q{h.mm a – h.mm a},
				h => q{h.mm–h.mm a},
				m => q{h.mm–h.mm a},
			},
			hmv => {
				a => q{h.mm a – h.mm a v},
				h => q{h.mm–h.mm a v},
				m => q{h.mm–h.mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h–h a v},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d–d MMM y},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
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
						0 => q(Capit),
						1 => q(Capji),
						2 => q(Cia),
						3 => q(Ji),
						4 => q(Sa),
						5 => q(Si),
						6 => q(Go),
						7 => q(Lak),
						8 => q(Cit),
						9 => q(Pé’),
						10 => q(Kao),
						11 => q(Cap),
					},
					'wide' => {
						0 => q(Capitgwé),
						1 => q(Capjigwé),
						2 => q(Ciagwé),
						3 => q(Jigwé),
						4 => q(Sagwé),
						5 => q(Sigwé),
						6 => q(Gogwé),
						7 => q(Lakgwé),
						8 => q(Citgwé),
						9 => q(Pé’gwé),
						10 => q(Kaogwé),
						11 => q(Capgwé),
					},
				},
			},
			'days' => {
				'format' => {
					'wide' => {
						0 => q(Tikus Kayu Ganjil),
						1 => q(Kebo Kayu Genep),
						2 => q(Macan Api Ganjil),
						3 => q(Kelinci Api Genep),
						4 => q(Liong Tana Ganjil),
						5 => q(Ula Tana Genep),
						6 => q(Kuda Logem Ganjil),
						7 => q(Kambing Logem Genep),
						8 => q(Kunyuk Aèr Ganjil),
						9 => q(Ayam Aèr Genep),
						10 => q(Anjing Kayu Ganjil),
						11 => q(Cèlèng Kayu Genep),
						12 => q(Tikus Api Ganjil),
						13 => q(Kebo Api Genep),
						14 => q(Macan Tana Ganjil),
						15 => q(Kelinci Tana Genep),
						16 => q(Liong Logem Ganjil),
						17 => q(Ula Logem Genep),
						18 => q(Kuda Aèr Ganjil),
						19 => q(Kambing Aèr Genep),
						20 => q(Kunyuk Kayu Ganjil),
						21 => q(Ayam Kayu Genep),
						22 => q(Anjing Api Ganjil),
						23 => q(Cèlèng Api Genep),
						24 => q(Tikus Tana Ganjil),
						25 => q(Kebo Tana Genep),
						26 => q(Macan Logem Ganjil),
						27 => q(Kelinci Logem Genep),
						28 => q(Liong Aèr Ganjil),
						29 => q(Ula Aèr Genep),
						30 => q(Kuda Kayu Ganjil),
						31 => q(Kambing Kayu Genep),
						32 => q(Kunyuk Api Ganjil),
						33 => q(Ayam Api Genep),
						34 => q(Anjing Tana Ganjil),
						35 => q(Cèlèng Tana Genep),
						36 => q(Tikus Logem Ganjil),
						37 => q(Kebo Logem Genep),
						38 => q(Macan Aèr Ganjil),
						39 => q(Kelinci Aèr Genep),
						40 => q(Liong Kayu Ganjil),
						41 => q(Ula Kayu Genep),
						42 => q(Kuda Api Ganjil),
						43 => q(Kambing Api Genep),
						44 => q(Kunyuk Tana Ganjil),
						45 => q(Ayam Tana Genep),
						46 => q(Anjing Logem Ganjil),
						47 => q(Cèlèng Logem Genep),
						48 => q(Tikus Aèr Ganjil),
						49 => q(Kebo Aèr Genep),
						50 => q(Macan Kayu Ganjil),
						51 => q(Kelinci Kayu Genep),
						52 => q(Liong Api Ganjil),
						53 => q(Ula Api Genep),
						54 => q(Kuda Tana Ganjil),
						55 => q(Kambing Tana Genep),
						56 => q(Kunyuk Logem Ganjil),
						57 => q(Ayam Logem Genep),
						58 => q(Anjing Aèr Ganjil),
						59 => q(Cèlèng Aèr Genep),
					},
				},
			},
			'months' => {
				'format' => {
					'wide' => {
						0 => q(Tikus Kayu Ganjil),
						1 => q(Kebo Kayu Genep),
						2 => q(Macan Api Ganjil),
						3 => q(Kelinci Api Genep),
						4 => q(Liong Tana Ganjil),
						5 => q(Ula Tana Genep),
						6 => q(Kuda Logem Ganjil),
						7 => q(Kambing Logem Genep),
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
		hourFormat => q(+HH.mm;-HH.mm),
		regionFormat => q(Waktu {0}),
		regionFormat => q(Waktu Musim Pentèr {0}),
		regionFormat => q(Waktu Pakem {0}),
		'Acre' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Akre#,
				'generic' => q#Waktu Akre#,
				'standard' => q#Waktu Pakem Akre#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Waktu Apganistan#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abijan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Adis Ababa#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Aljajaèr#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Biso#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brasawil#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kasablangka#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Sabtah#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Konakri#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Darussalam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Jibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Duala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Aluyun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Priton#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Gaboroné#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Hararé#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Yohanesbereh#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Hartum#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinsasa#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Maséru#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadisu#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrowia#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Njamèna#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamé#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nuaksot#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Wagadugu#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sint-Tomas#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Winhuk#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Waktu Aprika Tenga#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Waktu Aprika Wètan#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Waktu Pakem Aprika Kidul#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Aprika Kulon#,
				'generic' => q#Waktu Aprika Kulon#,
				'standard' => q#Waktu Pakem Aprika Kulon#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Alaska#,
				'generic' => q#Waktu Alaska#,
				'standard' => q#Waktu Pakem Alaska#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Almati#,
				'generic' => q#Waktu Almati#,
				'standard' => q#Waktu Pakem Almati#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Amason#,
				'generic' => q#Waktu Amason#,
				'standard' => q#Waktu Pakem Amason#,
			},
		},
		'America/Anchorage' => {
			exemplarCity => q#Angkorèt#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Angguila#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunsion#,
		},
		'America/Belize' => {
			exemplarCity => q#Bélis#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buénos Airès#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Telok Kèmbrit#,
		},
		'America/Caracas' => {
			exemplarCity => q#Karakas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Katamarka#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Kéyèn#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kaèman#,
		},
		'America/Chicago' => {
			exemplarCity => q#Cikago#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Cihuahua#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kordoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kosta Rika#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kurasao#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salbador#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuk#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grénada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadelup#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatémala#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halipak#,
		},
		'America/Havana' => {
			exemplarCity => q#Hawana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Piterbereh, Indiana#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaika#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La Pas#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Losènjeles#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinik#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Kota Mèksiko#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Mikélon#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Montébidéo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Monsérat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Naso#,
		},
		'America/New_York' => {
			exemplarCity => q#Niu-Yorek#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Pènik#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Portu Béliu#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Porto Riko#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Sang Paulu#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Sint-Bartoloméus#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Sint-Kristoper#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Sint-Lusia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Sint-Tomas (Karaiben)#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Sint-Winsèn#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Wangkuber#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Tenga#,
				'generic' => q#Waktu Tenga#,
				'standard' => q#Waktu Pakem Tenga#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Wètan#,
				'generic' => q#Waktu Wètan#,
				'standard' => q#Waktu Pakem Wètan#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Gunung#,
				'generic' => q#Waktu Gunung#,
				'standard' => q#Waktu Pakem Gunung#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Teduh#,
				'generic' => q#Waktu Teduh#,
				'standard' => q#Waktu Pakem Teduh#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Anadir#,
				'generic' => q#Waktu Anadir#,
				'standard' => q#Waktu Pakem Anadir#,
			},
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont-d’Urville#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Wostok#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Apia#,
				'generic' => q#Waktu Apia#,
				'standard' => q#Waktu Pakem Apia#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Akto#,
				'generic' => q#Waktu Akto#,
				'standard' => q#Waktu Pakem Akto#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Aktobé#,
				'generic' => q#Waktu Aktobé#,
				'standard' => q#Waktu Pakem Aktobé#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Arab#,
				'generic' => q#Waktu Arab#,
				'standard' => q#Waktu Pakem Arab#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyear Kota#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Argèntina#,
				'generic' => q#Waktu Argèntina#,
				'standard' => q#Waktu Pakem Argèntina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Argèntina Kulon#,
				'generic' => q#Waktu Argèntina Kulon#,
				'standard' => q#Waktu Pakem Argèntina Kulon#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Lemènder#,
				'generic' => q#Waktu Lemènder#,
				'standard' => q#Waktu Pakem Lemènder#,
			},
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almati#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Aman#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadir#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Akto#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobé#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Askabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Atiro#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrén#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Bérut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Biskèk#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Bruné#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkuta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Cita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Coibalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damsik#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Daka#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubé#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dusambé#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Pamagusta#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gaja#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hèbron/Halil#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Houd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkut#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Bétulmegedis#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamcatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karaci#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Handiga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoyar#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kucing#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuwét#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makao#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasar#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosia#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Nowokusnèt#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Nowosibir#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Om#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Penom Pèn#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Piongyang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostané#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kisilorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Yanggon#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Hociming#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sahalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkan#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Séul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Sanghay#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srèdnèkolim#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipé#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taskèn#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tiplis#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Tèhèran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Timpu#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tom#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulanbator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumci#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Néra#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Wiang Cendana#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Weladiwostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yakut#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Yékatèrinbereh#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yéréwan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Atlantik#,
				'generic' => q#Waktu Atlantik#,
				'standard' => q#Waktu Pakem Atlantik#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Asoren#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kenari#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Tanjung Ijo#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Perower#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madéra#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Rékiawik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Géorgi Kidul#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sint-Héléna#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stènli#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adeléd#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brisbèn#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Pert#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sidni#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Ostrali Tena#,
				'generic' => q#Waktu Ostrali Tenga#,
				'standard' => q#Waktu Pakem Ostrali Tenga#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Ostrali Kulon-tenga#,
				'generic' => q#Waktu Ostrali Kulon-tenga#,
				'standard' => q#Waktu Pakem Ostrali Kulon-tenga#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Ostrali Wètan#,
				'generic' => q#Waktu Ostrali Wètan#,
				'standard' => q#Waktu Pakem Ostrali Wètan#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Ostrali Kulon#,
				'generic' => q#Waktu Ostrali Kulon#,
				'standard' => q#Waktu Pakem Ostrali Kulon#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Asèrbaijan#,
				'generic' => q#Waktu Asèrbaijan#,
				'standard' => q#Waktu Pakem Asèrbaijan#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Asoren#,
				'generic' => q#Waktu Asoren#,
				'standard' => q#Waktu Pakem Asoren#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Benggaladésa#,
				'generic' => q#Waktu Benggaladésa#,
				'standard' => q#Waktu Pakem Benggaladésa#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Waktu Butan#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Waktu Boliwi#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Brasilia#,
				'generic' => q#Waktu Brasilia#,
				'standard' => q#Waktu Pakem Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Waktu Bruné Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Tanjung Ijo#,
				'generic' => q#Waktu Tanjung Ijo#,
				'standard' => q#Waktu Pakem Tanjung Ijo#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#Waktu Casey#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Waktu Pakem Camoro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Catham#,
				'generic' => q#Waktu Catham#,
				'standard' => q#Waktu Pakem Catham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Cili#,
				'generic' => q#Waktu Cili#,
				'standard' => q#Waktu Pakem Cili#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Tiongkok#,
				'generic' => q#Waktu Tiongkok#,
				'standard' => q#Waktu Pakem Tiongkok#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Coibalsan#,
				'generic' => q#Waktu Coibalsan#,
				'standard' => q#Waktu Pakem Coibalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Waktu Pulo Natal#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Waktu Pulo Kokos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Kolombia#,
				'generic' => q#Waktu Kolombia#,
				'standard' => q#Waktu Pakem Kolombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Pulo Cook#,
				'generic' => q#Waktu Pulo Cook#,
				'standard' => q#Waktu Pakem Pulo Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Kuba#,
				'generic' => q#Waktu Kuba#,
				'standard' => q#Waktu Pakem Kuba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Waktu Davis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Waktu Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Waktu Timor Wètan#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Pulo Paskah#,
				'generic' => q#Waktu Pulo Paskah#,
				'standard' => q#Waktu Pakem Pulo Paskah#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Waktu Èkuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Waktu Dunia Kekordinir#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Kota Kaga’ Ditauin#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsteredam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andora#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrahan#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atène#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Bèlgrado#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlèn#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislawa#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bresèl#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarès#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapès#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kisinèp#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Waktu Pakem Irlan#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Jabal Tarik#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Gèrensi#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Hèlsingki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Pulo Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Stambul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jèrsi#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiip#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirop#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisabon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Lubliana#,
		},
		'Europe/London' => {
			exemplarCity => q#Londen#,
			long => {
				'daylight' => q#Waktu Musim Pentèr Britani#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Leksembereh Kota#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrit#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Marihamen#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Min#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Mosko#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Parès#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgoritsa#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prah#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarayéwo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Saratop#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Akmesjid#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopi#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sopia#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stokholem#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Talin#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Ulyanop#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Usgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Padus#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Watikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wènen#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Wilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Wolgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warso#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Sagrèp#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Saporijiah#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Sirik#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Èropa Tenga#,
				'generic' => q#Waktu Èropa Tenga#,
				'standard' => q#Waktu Pakem Èropa Tenga#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Èropa Wètan#,
				'generic' => q#Waktu Èropa Wètan#,
				'standard' => q#Waktu Pakem Èropa Wètan#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Waktu Èropa Wètan-jau#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Èropa Kulon#,
				'generic' => q#Waktu Èropa Kulon#,
				'standard' => q#Waktu Pakem Èropa Kulon#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Pulo Paklan#,
				'generic' => q#Waktu Pulo Paklan#,
				'standard' => q#Waktu Pakem Pulo Paklan#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Piji#,
				'generic' => q#Waktu Piji#,
				'standard' => q#Waktu Pakem Piji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Waktu Guyana Prasman#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Waktu Wilayah Kulon èn Kutub Kidul Prasman#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Waktu Rerata Greenwich#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Waktu Galapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Waktu Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Géorgi#,
				'generic' => q#Waktu Géorgi#,
				'standard' => q#Waktu Pakem Géorgi#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Waktu Pulo Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Grunlan Wètan#,
				'generic' => q#Waktu Grunlan Wètan#,
				'standard' => q#Waktu Pakem Grunlan Wètan#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Grunlan Kulon#,
				'generic' => q#Waktu Grunlan Kulon#,
				'standard' => q#Waktu Pakem Grunlan Kulon#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Waktu Pakem Telok#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Waktu Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Hawai-Aléut#,
				'generic' => q#Waktu Hawai-Aléut#,
				'standard' => q#Waktu Pakem Hawai-Aléut#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Hongkong#,
				'generic' => q#Waktu Hongkong#,
				'standard' => q#Waktu Pakem Hongkong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Houd#,
				'generic' => q#Waktu Houd#,
				'standard' => q#Waktu Pakem Houd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Waktu Hindi Pakem#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananariwo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Cagos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Pulo Natal#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Pulo Kokos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komoro#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kèrgélèn#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maladéwa#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Moritius#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Méot#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Waktu Laotan Hindi#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Waktu Indocina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Waktu Indonésia Tenga#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Waktu Indonésia Wètan#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Waktu Indonésia Kulon#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Iran#,
				'generic' => q#Waktu Iran#,
				'standard' => q#Waktu Pakem Iran#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Irkut#,
				'generic' => q#Waktu Irkut#,
				'standard' => q#Waktu Pakem Irkut#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Israèl#,
				'generic' => q#Waktu Israèl#,
				'standard' => q#Waktu Pakem Israèl#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Jepang#,
				'generic' => q#Waktu Jepang#,
				'standard' => q#Waktu Pakem Jepang#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Pètropaulop-Kamcatka#,
				'generic' => q#Waktu Pètropaulop-Kamcatka#,
				'standard' => q#Waktu Pakem Pètropaulop-Kamcatka#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Waktu Kasakstan Wètan#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Waktu Kasakstan Kulon#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Koréa#,
				'generic' => q#Waktu Koréa#,
				'standard' => q#Waktu Pakem Koréa#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Waktu Kosaé#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Krasnoyar#,
				'generic' => q#Waktu Krasnoyar#,
				'standard' => q#Waktu Pakem Krasnoyar#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Waktu Kirgistan#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Waktu Sri Langka#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Waktu Pulo Line#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Lord Howe#,
				'generic' => q#Waktu Lord Howe#,
				'standard' => q#Waktu Pakem Lord Howe#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Makao#,
				'generic' => q#Waktu Makao#,
				'standard' => q#Waktu Pakem Makao#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Waktu Pulo Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Magadan#,
				'generic' => q#Waktu Magadan#,
				'standard' => q#Waktu Pakem Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Waktu Malésia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Waktu Maladéwa#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Waktu Markésas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Waktu Pulo Marsal#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Moritius#,
				'generic' => q#Waktu Moritius#,
				'standard' => q#Waktu Pakem Moritius#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Waktu Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Mèksiko Lor-kulon#,
				'generic' => q#Waktu Mèksiko Lor-kulon#,
				'standard' => q#Waktu Pakem Mèksiko Lor-kulon#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Mèksiko Teduh#,
				'generic' => q#Waktu Mèksiko Teduh#,
				'standard' => q#Waktu Pakem Mèksiko Teduh#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Ulanbator#,
				'generic' => q#Waktu Ulanbator#,
				'standard' => q#Waktu Pakem Ulanbator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Mosko#,
				'generic' => q#Waktu Mosko#,
				'standard' => q#Waktu Pakem Mosko#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Waktu Mianmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Waktu Nauru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Waktu Népal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Kalédoni Baru#,
				'generic' => q#Waktu Kalédoni Baru#,
				'standard' => q#Waktu Pakem Kalédoni Baru#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Sélan Baru#,
				'generic' => q#Waktu Sélan Baru#,
				'standard' => q#Waktu Pakem Sélan Baru#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Niuponlan#,
				'generic' => q#Waktu Niuponlan#,
				'standard' => q#Waktu Pakem Niuponlan#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Waktu Niué#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Pulo Norpok#,
				'generic' => q#Waktu Pulo Norpok#,
				'standard' => q#Waktu Pakem Pulo Norpok#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Fernando de Noronha#,
				'generic' => q#Waktu Fernando de Noronha#,
				'standard' => q#Waktu Pakem Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Nowosibir#,
				'generic' => q#Waktu Nowosibir#,
				'standard' => q#Waktu Pakem Nowosibir#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Om#,
				'generic' => q#Waktu Om#,
				'standard' => q#Waktu Pakem Om#,
			},
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Oklan#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Bugènpil#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Catham#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Paskah#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Épaté#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Pakaopo#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Piji#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Punaputi#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guadalkanal#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Jonsten#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosaé#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kuajelin#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Majero#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markésas#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midwé#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Niué#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Norpok#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Numéa#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitkèren#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Pompé#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Pot Morèsbi#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Cuk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Wék#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Walis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Pakistan#,
				'generic' => q#Waktu Pakistan#,
				'standard' => q#Waktu Pakem Pakistan#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Waktu Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Waktu Papua Giné Baru#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Paragué#,
				'generic' => q#Waktu Paragué#,
				'standard' => q#Waktu Pakem Paragué#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Péru#,
				'generic' => q#Waktu Péru#,
				'standard' => q#Waktu Pakem Péru#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Pilipénen#,
				'generic' => q#Waktu Pilipénen#,
				'standard' => q#Waktu Pakem Pilipénen#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Waktu Pulo Pènik#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Sint-Pièr èn Mikélon#,
				'generic' => q#Waktu Sint-Pièr èn Mikélon#,
				'standard' => q#Waktu Pakem Sint-Pièr èn Mikélon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Waktu Pitkèren#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Waktu Ponapé#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Waktu Piongyang#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Kisilorda#,
				'generic' => q#Waktu Kisilorda#,
				'standard' => q#Waktu Pakem Kisilorda#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Waktu Réunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Waktu Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Sahalin#,
				'generic' => q#Waktu Sahalin#,
				'standard' => q#Waktu Pakem Sahalin#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Samara#,
				'generic' => q#Waktu Samara#,
				'standard' => q#Waktu Pakem Samara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Samoa#,
				'generic' => q#Waktu Samoa#,
				'standard' => q#Waktu Pakem Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Waktu Sésèl#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Waktu Pakem Singapur#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Waktu Pulo Suléman#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Waktu Géorgi Kidul#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Waktu Suriname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Waktu Syowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Waktu Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Taipé#,
				'generic' => q#Waktu Taipé#,
				'standard' => q#Waktu Pakem Taipé#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Waktu Tajikistan#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Waktu Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Tonga#,
				'generic' => q#Waktu Tonga#,
				'standard' => q#Waktu Pakem Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Waktu Cuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Turkmènistan#,
				'generic' => q#Waktu Turkmènistan#,
				'standard' => q#Waktu Pakem Turkmènistan#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Waktu Tuwalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Urugué#,
				'generic' => q#Waktu Urugué#,
				'standard' => q#Waktu Pakem Urugué#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Usbèkistan#,
				'generic' => q#Waktu Usbèkistan#,
				'standard' => q#Waktu Pakem Usbèkistan#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Wanuatu#,
				'generic' => q#Waktu Wanuatu#,
				'standard' => q#Waktu Pakem Wanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Waktu Bénésuèla#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Weladiwostok#,
				'generic' => q#Waktu Weladiwostok#,
				'standard' => q#Waktu Pakem Weladiwostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Wolgograd#,
				'generic' => q#Waktu Wolgograd#,
				'standard' => q#Waktu Pake Wolgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Waktu Wostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Waktu Pulo Wék#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Waktu Walis èn Putuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Yakut#,
				'generic' => q#Waktu Yakut#,
				'standard' => q#Waktu Pakem Yakut#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Waktu Musim Pentèr Yékatèrinenbereh#,
				'generic' => q#Waktu Yékatèrinenbereh#,
				'standard' => q#Waktu Pakem Yékatèrinenbereh#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Waktu Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
