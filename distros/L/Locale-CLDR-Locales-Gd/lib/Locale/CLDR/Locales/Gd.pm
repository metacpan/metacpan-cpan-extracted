=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Gd - Package for language Scottish Gaelic

=cut

package Locale::CLDR::Locales::Gd;
# This file auto generated from Data\common\main\gd.xml
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
				'aa' => 'Afar',
 				'ab' => 'Abchasais',
 				'ace' => 'Basa Acèh',
 				'ach' => 'Acoli',
 				'ada' => 'Adangme',
 				'ady' => 'Adyghe',
 				'ae' => 'Avestanais',
 				'aeb' => 'Arabais Thuiniseach',
 				'af' => 'Afraganais',
 				'afh' => 'Afrihili',
 				'agq' => 'Aghem',
 				'ain' => 'Ainu',
 				'ak' => 'Akan',
 				'akk' => 'Acadais',
 				'akz' => 'Alabama',
 				'ale' => 'Aleutais',
 				'aln' => 'Albàinis Ghegeach',
 				'alt' => 'Altais Dheasach',
 				'am' => 'Amtharais',
 				'an' => 'Aragonais',
 				'ang' => 'Seann-Bheurla',
 				'ann' => 'Obolo',
 				'anp' => 'Angika',
 				'apc' => 'Arabais Levantach',
 				'ar' => 'Arabais',
 				'ar_001' => 'Nuadh-Arabais Stannardach',
 				'arc' => 'Aramais',
 				'arn' => 'Mapudungun',
 				'aro' => 'Araona',
 				'arp' => 'Arapaho',
 				'arq' => 'Arabais Aildireach',
 				'ars' => 'Arabais Najdi',
 				'arw' => 'Arawak',
 				'ary' => 'Arabais Mhorocach',
 				'arz' => 'Arabais Èipheiteach',
 				'as' => 'Asamais',
 				'asa' => 'Asu',
 				'ase' => 'Cainnt-shanais na h-Aimeireaga',
 				'ast' => 'Astùrais',
 				'atj' => 'Atikamekw',
 				'av' => 'Avarais',
 				'avk' => 'Kotava',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymara',
 				'az' => 'Asarbaideànais',
 				'az@alt=short' => 'Azeri',
 				'ba' => 'Bashkir',
 				'bal' => 'Baluchì',
 				'ban' => 'Cànan Bali',
 				'bas' => 'Basaa',
 				'bax' => 'Bamun',
 				'bbc' => 'Batak Toba',
 				'bbj' => 'Ghomala',
 				'be' => 'Bealaruisis',
 				'bej' => 'Beja',
 				'bem' => 'Bemba',
 				'bew' => 'Betawi',
 				'bez' => 'Bena',
 				'bfd' => 'Bafut',
 				'bfq' => 'Badaga',
 				'bg' => 'Bulgarais',
 				'bgc' => 'Haryanvi',
 				'bgn' => 'Balochi Shiarach',
 				'bho' => 'Bhojpuri',
 				'bi' => 'Bislama',
 				'bik' => 'Bikol',
 				'bin' => 'Edo',
 				'bjn' => 'Banjar',
 				'bkm' => 'Kom',
 				'bla' => 'Siksika',
 				'blo' => 'Anii',
 				'blt' => 'Tai Dam',
 				'bm' => 'Bambara',
 				'bn' => 'Bangla',
 				'bo' => 'Tibeitis',
 				'bpy' => 'Bishnupriya',
 				'bqi' => 'Bakhtiari',
 				'br' => 'Breatnais',
 				'bra' => 'Braj',
 				'brh' => 'Brahui',
 				'brx' => 'Bodo',
 				'bs' => 'Bosnais',
 				'bss' => 'Akoose',
 				'bua' => 'Buriat',
 				'bug' => 'Cànan nam Bugis',
 				'bum' => 'Bulu',
 				'byn' => 'Blin',
 				'byv' => 'Medumba',
 				'ca' => 'Catalanais',
 				'cad' => 'Caddo',
 				'car' => 'Carib',
 				'cay' => 'Cayuga',
 				'cch' => 'Atsam',
 				'ccp' => 'Chakma',
 				'ce' => 'Deideanais',
 				'ceb' => 'Cebuano',
 				'cgg' => 'Chiga',
 				'ch' => 'Chamorro',
 				'chb' => 'Chibcha',
 				'chg' => 'Chagatai',
 				'chk' => 'Cànan Chuuk',
 				'chm' => 'Mari',
 				'chn' => 'Chinuk Wawa',
 				'cho' => 'Choctaw',
 				'chp' => 'Chipewyan',
 				'chr' => 'Cherokee',
 				'chy' => 'Cheyenne',
 				'cic' => 'Chickasaw',
 				'ckb' => 'Cùrdais Mheadhanach',
 				'ckb@alt=variant' => 'Cùrdais Sorani',
 				'clc' => 'Chilcotin',
 				'co' => 'Corsais',
 				'cop' => 'Coptais',
 				'cps' => 'Capiznon',
 				'cr' => 'Cree',
 				'crg' => 'Michif',
 				'crh' => 'Turcais Chriomach',
 				'crj' => 'Cree Ear-dheasach',
 				'crk' => 'Cree nam Machair',
 				'crl' => 'Cree Ear-thuathach',
 				'crm' => 'Moose Cree',
 				'crr' => 'Algonquianais Charolina',
 				'crs' => 'Seiseallais',
 				'cs' => 'Seicis',
 				'csb' => 'Caisiubais',
 				'csw' => 'Omushkego',
 				'cu' => 'Slàbhais na h-Eaglaise',
 				'cv' => 'Chuvash',
 				'cy' => 'Cuimris',
 				'da' => 'Danmhairgis',
 				'dak' => 'Dakota',
 				'dar' => 'Dargwa',
 				'dav' => 'Taita',
 				'de' => 'Gearmailtis',
 				'de_AT' => 'Gearmailtis na h-Ostaire',
 				'de_CH' => 'Àrd-Ghearmailtis na h-Eilbheise',
 				'del' => 'Delaware',
 				'den' => 'Slavey',
 				'dgr' => 'Dogrib',
 				'din' => 'Dinka',
 				'dje' => 'Zarma',
 				'doi' => 'Dogri',
 				'dsb' => 'Sòrbais Ìochdarach',
 				'dtp' => 'Dusun Mheadhanach',
 				'dua' => 'Duala',
 				'dum' => 'Meadhan-Dhuitsis',
 				'dv' => 'Divehi',
 				'dyo' => 'Jola-Fonyi',
 				'dyu' => 'Dyula',
 				'dz' => 'Dzongkha',
 				'dzg' => 'Dazaga',
 				'ebu' => 'Embu',
 				'ee' => 'Ewe',
 				'efi' => 'Efik',
 				'egy' => 'Èipheitis Àrsaidh',
 				'eka' => 'Ekajuk',
 				'el' => 'Greugais',
 				'elx' => 'Elamais',
 				'en' => 'Beurla',
 				'en_AU' => 'Beurla Astràilia',
 				'en_CA' => 'Beurla Chanada',
 				'en_GB' => 'Beurla Bhreatainn',
 				'en_GB@alt=short' => 'Beurla na RA',
 				'en_US' => 'Beurla na h-Aimeireaga',
 				'en_US@alt=short' => 'Beurla nan SA',
 				'enm' => 'Meadhan-Bheurla',
 				'eo' => 'Esperanto',
 				'es' => 'Spàinntis',
 				'es_419' => 'Spàinntis na h-Aimeireaga Laidinneach',
 				'es_ES' => 'Spàinntis Eòrpach',
 				'es_MX' => 'Spàinntis Mheagsagach',
 				'esu' => 'Yupik Mheadhanach',
 				'et' => 'Eastoinis',
 				'eu' => 'Basgais',
 				'ewo' => 'Ewondo',
 				'ext' => 'Cànan na h-Extremadura',
 				'fa' => 'Peirsis',
 				'fa_AF' => 'Dari',
 				'fan' => 'Fang',
 				'fat' => 'Fanti',
 				'ff' => 'Fulah',
 				'fi' => 'Fionnlannais',
 				'fil' => 'Filipinis',
 				'fit' => 'Meänkieli',
 				'fj' => 'Fìdis',
 				'fo' => 'Fàrothais',
 				'fon' => 'Fon',
 				'fr' => 'Fraingis',
 				'fr_CA' => 'Fraingis Chanada',
 				'fr_CH' => 'Fraingis Eilbheiseach',
 				'frc' => 'Fraingis nan Cajun',
 				'frm' => 'Meadhan-Fhraingis',
 				'fro' => 'Seann-Fhraingis',
 				'frp' => 'Arpitan',
 				'frr' => 'Frìoslannais Thuathach',
 				'frs' => 'Frìoslannais Earach',
 				'fur' => 'Friùilis',
 				'fy' => 'Frìoslannais Shiarach',
 				'ga' => 'Gaeilge',
 				'gaa' => 'Ga',
 				'gag' => 'Gagauz',
 				'gan' => 'Gan',
 				'gay' => 'Gayo',
 				'gba' => 'Gbaya',
 				'gbz' => 'Dari Zoroastrach',
 				'gd' => 'Gàidhlig',
 				'gez' => 'Ge’ez',
 				'gil' => 'Ciribeasais',
 				'gl' => 'Gailìsis',
 				'glk' => 'Gilaki',
 				'gmh' => 'Meadhan-Àrd-Gearmailtis',
 				'gn' => 'Guaraní',
 				'goh' => 'Seann-Àrd-Gearmailtis',
 				'gon' => 'Gondi',
 				'gor' => 'Gorontalo',
 				'got' => 'Gotais',
 				'grb' => 'Grebo',
 				'grc' => 'Greugais Àrsaidh',
 				'gsw' => 'Gearmailtis Eilbheiseach',
 				'gu' => 'Gujarati',
 				'guc' => 'Wayuu',
 				'gur' => 'Frafra',
 				'guz' => 'Gusii',
 				'gv' => 'Gaelg',
 				'gwi' => 'Gwichʼin',
 				'ha' => 'Hausa',
 				'hai' => 'Haida',
 				'hak' => 'Hakka',
 				'haw' => 'Cànan Hawai’i',
 				'hax' => 'Haida Dheasach',
 				'he' => 'Eabhra',
 				'hi' => 'Hindis',
 				'hi_Latn@alt=variant' => 'Hinglish',
 				'hif' => 'Hindis Fhìditheach',
 				'hil' => 'Hiligaynon',
 				'hit' => 'Cànan Het',
 				'hmn' => 'Hmong',
 				'hnj' => 'Hmong Njua',
 				'ho' => 'Hiri Motu',
 				'hr' => 'Cròthaisis',
 				'hsb' => 'Sòrbais Uachdarach',
 				'hsn' => 'Xiang',
 				'ht' => 'Crìtheol Haidhti',
 				'hu' => 'Ungairis',
 				'hup' => 'Hupa',
 				'hur' => 'Halkomelem',
 				'hy' => 'Airmeinis',
 				'hz' => 'Herero',
 				'ia' => 'Interlingua',
 				'iba' => 'Iban',
 				'ibb' => 'Ibibio',
 				'id' => 'Innd-Innsis',
 				'ie' => 'Interlingue',
 				'ig' => 'Igbo',
 				'ii' => 'Yi Sichuan',
 				'ik' => 'Inupiaq',
 				'ikt' => 'Inuktitut Shiarach Chanada',
 				'ilo' => 'Iloko',
 				'inh' => 'Ingush',
 				'io' => 'Ido',
 				'is' => 'Innis Tìlis',
 				'it' => 'Eadailtis',
 				'iu' => 'Inuktitut',
 				'ja' => 'Seapanais',
 				'jam' => 'Beurla Crìtheolach Diameuga',
 				'jbo' => 'Lojban',
 				'jgo' => 'Ngomba',
 				'jmc' => 'Machame',
 				'jpr' => 'Peirsis Iùdhach',
 				'jrb' => 'Arabais Iùdhach',
 				'jv' => 'Deàbhanais',
 				'ka' => 'Cairtbheilis',
 				'kaa' => 'Kara-Kalpak',
 				'kab' => 'Kabyle',
 				'kac' => 'Kachin',
 				'kaj' => 'Jju',
 				'kam' => 'Kamba',
 				'kaw' => 'Kawi',
 				'kbd' => 'Cabardais',
 				'kbl' => 'Kanembu',
 				'kcg' => 'Tyap',
 				'kde' => 'Makonde',
 				'kea' => 'Kabuverdianu',
 				'ken' => 'Kenyang',
 				'kfo' => 'Koro',
 				'kg' => 'Kongo',
 				'kgp' => 'Kaingang',
 				'kha' => 'Khasi',
 				'kho' => 'Cànan Khotan',
 				'khq' => 'Koyra Chiini',
 				'khw' => 'Khowar',
 				'ki' => 'Kikuyu',
 				'kiu' => 'Kirmanjki',
 				'kj' => 'Kuanyama',
 				'kk' => 'Casachais',
 				'kkj' => 'Kako',
 				'kl' => 'Kalaallisut',
 				'kln' => 'Kalenjin',
 				'km' => 'Cmèar',
 				'kmb' => 'Kimbundu',
 				'kn' => 'Kannada',
 				'ko' => 'Coirèanais',
 				'koi' => 'Komi-Permyak',
 				'kok' => 'Konkani',
 				'kpe' => 'Kpelle',
 				'kr' => 'Kanuri',
 				'krc' => 'Karachay-Balkar',
 				'kri' => 'Krio',
 				'krj' => 'Kinaray-a',
 				'krl' => 'Cairealais',
 				'kru' => 'Kurukh',
 				'ks' => 'Caismiris',
 				'ksb' => 'Shambala',
 				'ksf' => 'Bafia',
 				'ksh' => 'Gearmailtis Chologne',
 				'ku' => 'Cùrdais',
 				'kum' => 'Kumyk',
 				'kut' => 'Kutenai',
 				'kv' => 'Komi',
 				'kw' => 'Còrnais',
 				'kwk' => 'Kwakʼwala',
 				'kxv' => 'Kuvi',
 				'ky' => 'Cìorgasais',
 				'la' => 'Laideann',
 				'lad' => 'Ladino',
 				'lag' => 'Langi',
 				'lah' => 'Lahnda',
 				'lam' => 'Lamba',
 				'lb' => 'Lugsamburgais',
 				'lez' => 'Leasgais',
 				'lfn' => 'Lingua Franca Nova',
 				'lg' => 'Ganda',
 				'li' => 'Cànan Limburg',
 				'lij' => 'Liogùrais',
 				'lil' => 'Lillooet',
 				'lkt' => 'Lakhóta',
 				'lld' => 'Ladainis',
 				'lmo' => 'Lombardais',
 				'ln' => 'Lingala',
 				'lo' => 'Làtho',
 				'lol' => 'Mongo',
 				'lou' => 'Crìtheol Louisiana',
 				'loz' => 'Lozi',
 				'lrc' => 'Luri Thuathach',
 				'lsm' => 'Saamia',
 				'lt' => 'Liotuainis',
 				'ltg' => 'Latgailis',
 				'lu' => 'Luba-Katanga',
 				'lua' => 'Luba-Lulua',
 				'lui' => 'Luiseño',
 				'lun' => 'Lunda',
 				'luo' => 'Luo',
 				'lus' => 'Mizo',
 				'luy' => 'Luyia',
 				'lv' => 'Laitbheis',
 				'lzh' => 'Sìnis an Litreachais',
 				'lzz' => 'Laz',
 				'mad' => 'Cànan Madhura',
 				'maf' => 'Mafa',
 				'mag' => 'Magahi',
 				'mai' => 'Maithili',
 				'mak' => 'Makasar',
 				'man' => 'Mandingo',
 				'mas' => 'Maasai',
 				'mde' => 'Maba',
 				'mdf' => 'Moksha',
 				'mdr' => 'Mandar',
 				'men' => 'Mende',
 				'mer' => 'Meru',
 				'mfe' => 'Morisyen',
 				'mg' => 'Malagasais',
 				'mga' => 'Meadhan-Ghaeilge',
 				'mgh' => 'Makhuwa-Meetto',
 				'mgo' => 'Meta’',
 				'mh' => 'Marshallais',
 				'mhn' => 'Mócheno',
 				'mi' => 'Māori',
 				'mic' => 'Mi’kmaq',
 				'min' => 'Minangkabau',
 				'mk' => 'Masadonais',
 				'ml' => 'Malayalam',
 				'mn' => 'Mongolais',
 				'mnc' => 'Manchu',
 				'mni' => 'Manipuri',
 				'moe' => 'Innu-aimun',
 				'moh' => 'Mohawk',
 				'mos' => 'Mossi',
 				'mr' => 'Marathi',
 				'mrj' => 'Mari Shiarach',
 				'ms' => 'Malaidhis',
 				'mt' => 'Maltais',
 				'mua' => 'Mundang',
 				'mul' => 'Iomadh cànan',
 				'mus' => 'Creek',
 				'mwl' => 'Miorandais',
 				'mwr' => 'Marwari',
 				'mwv' => 'Mentawai',
 				'my' => 'Burmais',
 				'mye' => 'Myene',
 				'myv' => 'Erzya',
 				'mzn' => 'Mazanderani',
 				'na' => 'Nabhru',
 				'nan' => 'Min Nan',
 				'nap' => 'Eadailtis Napoli',
 				'naq' => 'Nama',
 				'nb' => 'Bokmål na Nirribhidh',
 				'nd' => 'Ndebele Thuathach',
 				'nds' => 'Gearmailtis Ìochdarach',
 				'nds_NL' => 'Sagsannais Ìochdarach',
 				'ne' => 'Neapàlais',
 				'new' => 'Newari',
 				'ng' => 'Ndonga',
 				'nia' => 'Nias',
 				'niu' => 'Cànan Niue',
 				'njo' => 'Ao Naga',
 				'nl' => 'Duitsis',
 				'nl_BE' => 'Flànrais',
 				'nmg' => 'Kwasio',
 				'nn' => 'Nynorsk na Nirribhidh',
 				'nnh' => 'Ngiemboon',
 				'no' => 'Nirribhis',
 				'nog' => 'Nogai',
 				'non' => 'Seann-Lochlannais',
 				'nov' => 'Novial',
 				'nqo' => 'N’Ko',
 				'nr' => 'Ndebele Dheasach',
 				'nso' => 'Sesotho sa Leboa',
 				'nus' => 'Nuer',
 				'nv' => 'Navajo',
 				'nwc' => 'Newari Chlasaigeach',
 				'ny' => 'Nyanja',
 				'nym' => 'Nyamwezi',
 				'nyn' => 'Nyankole',
 				'nyo' => 'Nyoro',
 				'nzi' => 'Nzima',
 				'oc' => 'Ogsatanais',
 				'oj' => 'Ojibwa',
 				'ojb' => 'Ojibwa Iar-thuathach',
 				'ojc' => 'Ojibwa Mheadhanach',
 				'ojs' => 'Oji-Cree',
 				'ojw' => 'Ojibwa Shiarach',
 				'oka' => 'Okanagan',
 				'om' => 'Oromo',
 				'or' => 'Odia',
 				'os' => 'Ossetic',
 				'osa' => 'Osage',
 				'ota' => 'Turcais Otomanach',
 				'pa' => 'Panjabi',
 				'pag' => 'Pangasinan',
 				'pal' => 'Pahlavi',
 				'pam' => 'Pampanga',
 				'pap' => 'Papiamentu',
 				'pau' => 'Palabhais',
 				'pcd' => 'Picard',
 				'pcm' => 'Beurla Nigèiriach',
 				'pdc' => 'Gearmailtis Phennsylvania',
 				'pdt' => 'Plautdietsch',
 				'peo' => 'Seann-Pheirsis',
 				'phn' => 'Phenicis',
 				'pi' => 'Pali',
 				'pis' => 'Pijin',
 				'pl' => 'Pòlainnis',
 				'pms' => 'Piedmontese',
 				'pon' => 'Cànan Pohnpei',
 				'pqm' => 'Maliseet-Passamaquoddy',
 				'prg' => 'Pruisis',
 				'pro' => 'Seann-Phrovençal',
 				'ps' => 'Pashto',
 				'pt' => 'Portagailis',
 				'pt_BR' => 'Portagailis Bhraisileach',
 				'pt_PT' => 'Portagailis Eòrpach',
 				'qu' => 'Quechua',
 				'quc' => 'K’iche’',
 				'qug' => 'Quichua Àrd-tìr Chimborazo',
 				'raj' => 'Rajasthani',
 				'rap' => 'Rapa Nui',
 				'rar' => 'Cànan Rarotonga',
 				'rgn' => 'Romagnol',
 				'rhg' => 'Rohingya',
 				'rif' => 'Tamaisich an Rif',
 				'rm' => 'Rumains',
 				'rn' => 'Kirundi',
 				'ro' => 'Romàinis',
 				'ro_MD' => 'Moldobhais',
 				'rof' => 'Rombo',
 				'rom' => 'Romanais',
 				'ru' => 'Ruisis',
 				'rue' => 'Rusyn',
 				'rug' => 'Roviana',
 				'rup' => 'Aromanais',
 				'rw' => 'Kinyarwanda',
 				'rwk' => 'Rwa',
 				'sa' => 'Sanskrit',
 				'sad' => 'Sandawe',
 				'sah' => 'Sakha',
 				'sam' => 'Aramais Shamaritanach',
 				'saq' => 'Samburu',
 				'sas' => 'Sasak',
 				'sat' => 'Santali',
 				'saz' => 'Saurashtra',
 				'sba' => 'Ngambay',
 				'sbp' => 'Sangu',
 				'sc' => 'Sàrdais',
 				'scn' => 'Sisilis',
 				'sco' => 'Albais',
 				'sd' => 'Sindhi',
 				'sdc' => 'Sassarese',
 				'sdh' => 'Cùrdais Dheasach',
 				'se' => 'Sàmais Thuathach',
 				'see' => 'Seneca',
 				'seh' => 'Sena',
 				'sei' => 'Seri',
 				'sel' => 'Selkup',
 				'ses' => 'Koyraboro Senni',
 				'sg' => 'Sango',
 				'sga' => 'Seann-Ghaeilge',
 				'sh' => 'Sèirb-Chròthaisis',
 				'shi' => 'Tachelhit',
 				'shn' => 'Shan',
 				'shu' => 'Arabais Seàdach',
 				'si' => 'Sinhala',
 				'sid' => 'Sidamo',
 				'sk' => 'Slòbhacais',
 				'skr' => 'Saraiki',
 				'sl' => 'Slòbhainis',
 				'slh' => 'Lushootseed Dheasach',
 				'sly' => 'Selayar',
 				'sm' => 'Samothais',
 				'sma' => 'Sàmais Dheasach',
 				'smj' => 'Sàmais Lule',
 				'smn' => 'Sàmais Inari',
 				'sms' => 'Sàmais Skolt',
 				'sn' => 'Shona',
 				'snk' => 'Soninke',
 				'so' => 'Somàilis',
 				'sq' => 'Albàinis',
 				'sr' => 'Sèirbis',
 				'srn' => 'Sranan Tongo',
 				'srr' => 'Serer',
 				'ss' => 'Swati',
 				'ssy' => 'Saho',
 				'st' => 'Sesotho',
 				'str' => 'Salish a’ Chaolais',
 				'su' => 'Cànan Sunda',
 				'suk' => 'Sukuma',
 				'sus' => 'Susu',
 				'sux' => 'Cànan Sumer',
 				'sv' => 'Suainis',
 				'sw' => 'Kiswahili',
 				'sw_CD' => 'Kiswahili na Congo',
 				'swb' => 'Comorais',
 				'syc' => 'Suraidheac Chlasaigeach',
 				'syr' => 'Suraidheac',
 				'szl' => 'Sileisis',
 				'ta' => 'Taimilis',
 				'tce' => 'Tutchone Dheasach',
 				'tcy' => 'Tulu',
 				'te' => 'Telugu',
 				'tem' => 'Timne',
 				'teo' => 'Teso',
 				'ter' => 'Terêna',
 				'tet' => 'Tetum',
 				'tg' => 'Taidigis',
 				'tgx' => 'Tagish',
 				'th' => 'Cànan nan Tàidh',
 				'tht' => 'Tahltan',
 				'ti' => 'Tigrinya',
 				'tig' => 'Tigre',
 				'tiv' => 'Tiv',
 				'tk' => 'Turcmanais',
 				'tkl' => 'Tokelau',
 				'tkr' => 'Tsakhur',
 				'tl' => 'Tagalog',
 				'tlh' => 'Klingon',
 				'tli' => 'Tlingit',
 				'tly' => 'Talysh',
 				'tmh' => 'Tamashek',
 				'tn' => 'Tswana',
 				'to' => 'Tonga',
 				'tog' => 'Nyasa Tonga',
 				'tok' => 'Toki Pona',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Turcais',
 				'tru' => 'Turoyo',
 				'trv' => 'Taroko',
 				'trw' => 'Torwali',
 				'ts' => 'Tsonga',
 				'tsi' => 'Tsimshian',
 				'tt' => 'Tatarais',
 				'ttm' => 'Tutchone Thuathach',
 				'ttt' => 'Tati',
 				'tum' => 'Tumbuka',
 				'tvl' => 'Tubhalu',
 				'tw' => 'Twi',
 				'twq' => 'Tasawaq',
 				'ty' => 'Cànan Tahiti',
 				'tyv' => 'Cànan Tuva',
 				'tzm' => 'Tamaisich an Atlais Mheadhanaich',
 				'udm' => 'Udmurt',
 				'ug' => 'Ùigiurais',
 				'uk' => 'Ucràinis',
 				'umb' => 'Umbundu',
 				'und' => 'Cànan neo-aithnichte',
 				'ur' => 'Ùrdu',
 				'uz' => 'Usbagais',
 				'vai' => 'Vai',
 				've' => 'Venda',
 				'vec' => 'Bheinisis',
 				'vep' => 'Veps',
 				'vi' => 'Bhiet-Namais',
 				'vls' => 'Flànrais Shiarach',
 				'vmw' => 'Makhuwa',
 				'vo' => 'Volapük',
 				'vro' => 'Võro',
 				'vun' => 'Vunjo',
 				'wa' => 'Walloon',
 				'wae' => 'Gearmailtis Wallis',
 				'wal' => 'Wolaytta',
 				'war' => 'Waray',
 				'was' => 'Washo',
 				'wbp' => 'Warlpiri',
 				'wo' => 'Wolof',
 				'wuu' => 'Wu',
 				'xal' => 'Kalmyk',
 				'xh' => 'Xhosa',
 				'xnr' => 'Kangri',
 				'xog' => 'Soga',
 				'yao' => 'Yao',
 				'yap' => 'Cànan Yap',
 				'yav' => 'Yangben',
 				'ybb' => 'Yemba',
 				'yi' => 'Iùdhais',
 				'yo' => 'Yoruba',
 				'yrl' => 'Nheengatu',
 				'yue' => 'Cantonais',
 				'yue@alt=menu' => 'Sìnis, Cantonais',
 				'za' => 'Zhuang',
 				'zap' => 'Zapotec',
 				'zbl' => 'Comharran Bliss',
 				'zea' => 'Cànan Zeeland',
 				'zen' => 'Zenaga',
 				'zgh' => 'Tamaisich Stannardach Moroco',
 				'zh' => 'Sìnis',
 				'zh@alt=menu' => 'Sìnis, Mandairinis',
 				'zh_Hans' => 'Sìnis Shimplichte',
 				'zh_Hans@alt=long' => 'Mandairinis Shimplichte',
 				'zh_Hant' => 'Sìnis Thradaiseanta',
 				'zh_Hant@alt=long' => 'Mandairinis Thradaiseanta',
 				'zu' => 'Zulu',
 				'zun' => 'Zuñi',
 				'zxx' => 'Susbaint nach eil ’na chànan',
 				'zza' => 'Zazaki',

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
 			'Afak' => 'Afaka',
 			'Aghb' => 'Albàinis Chabhcasach',
 			'Arab' => 'Arabais',
 			'Aran' => 'Nastaliq',
 			'Armi' => 'Aramais impireil',
 			'Armn' => 'Airmeinis',
 			'Avst' => 'Avestanais',
 			'Bamu' => 'Bamum',
 			'Bass' => 'Bassa Vah',
 			'Batk' => 'Batak',
 			'Beng' => 'Beangailis',
 			'Bhks' => 'Bhaiksuki',
 			'Blis' => 'Comharran Bliss',
 			'Bopo' => 'Bopomofo',
 			'Brah' => 'Brahmi',
 			'Brai' => 'Braille',
 			'Bugi' => 'Lontara',
 			'Buhd' => 'Buhid',
 			'Cakm' => 'Chakma',
 			'Cans' => 'Sgrìobhadh Lideach Aonaichte nan Tùsanach Canadach',
 			'Cari' => 'Carian',
 			'Cher' => 'Cherokee',
 			'Chrs' => 'Khwarazm',
 			'Cirt' => 'Cirth',
 			'Copt' => 'Coptais',
 			'Cpmn' => 'Mìneothais Chìopras',
 			'Cprt' => 'Cìoprasais',
 			'Cyrl' => 'Cirilis',
 			'Cyrs' => 'Cirilis Seann-Slàbhais na h-Eaglaise',
 			'Deva' => 'Devanagari',
 			'Diak' => 'Dives Akuru',
 			'Dogr' => 'Dogra',
 			'Dsrt' => 'Deseret',
 			'Dupl' => 'Gearr-sgrìobhadh Duployé',
 			'Egyp' => 'Sealbh-sgrìobhadh Èipheiteach',
 			'Elba' => 'Elbasan',
 			'Elym' => 'Elymaidheach',
 			'Ethi' => 'Ge’ez',
 			'Gara' => 'Garay',
 			'Geor' => 'Cairtbheilis',
 			'Glag' => 'Glagoliticeach',
 			'Gong' => 'Gunjala Gondi',
 			'Gonm' => 'Masaram Gondi',
 			'Goth' => 'Gotais',
 			'Gran' => 'Grantha',
 			'Grek' => 'Greugais',
 			'Gujr' => 'Gujarati',
 			'Gukh' => 'Gurung Khema',
 			'Guru' => 'Gurmukhi',
 			'Hanb' => 'Han le Bopomofo',
 			'Hang' => 'Hangul',
 			'Hani' => 'Han',
 			'Hano' => 'Hanunoo',
 			'Hans' => 'Simplichte',
 			'Hans@alt=stand-alone' => 'Han simplichte',
 			'Hant' => 'Tradaiseanta',
 			'Hant@alt=stand-alone' => 'Han tradaiseanta',
 			'Hatr' => 'Hatran',
 			'Hebr' => 'Eabhra',
 			'Hira' => 'Hiragana',
 			'Hluw' => 'Dealbh-sgrìobhadh Anatolach',
 			'Hmng' => 'Pahawh Hmong',
 			'Hmnp' => 'Nyiakeng Puachue Hmong',
 			'Hrkt' => 'Katakana no Hiragana',
 			'Hung' => 'Seann-Ungarais',
 			'Ital' => 'Seann-Eadailtis',
 			'Java' => 'Deàbhanais',
 			'Jpan' => 'Seapanais',
 			'Jurc' => 'Jurchen',
 			'Kali' => 'Kayah Li',
 			'Kana' => 'Katakana',
 			'Kawi' => 'KAWI',
 			'Khar' => 'Kharoshthi',
 			'Khmr' => 'Cmèar',
 			'Khoj' => 'Khojki',
 			'Kits' => 'Litrichean beaga na Khitan',
 			'Knda' => 'Kannada',
 			'Kore' => 'Coirèanais',
 			'Kpel' => 'Kpelle',
 			'Krai' => 'Kirat Rai',
 			'Kthi' => 'Kaithi',
 			'Lana' => 'Lanna',
 			'Laoo' => 'Làtho',
 			'Latf' => 'Laideann fraktur',
 			'Latg' => 'Laideann Ghàidhealach',
 			'Latn' => 'Laideann',
 			'Lepc' => 'Lepcha',
 			'Limb' => 'Limbu',
 			'Lina' => 'Linear A',
 			'Linb' => 'Linear B',
 			'Lisu' => 'Fraser',
 			'Loma' => 'Loma',
 			'Lyci' => 'Lycian',
 			'Lydi' => 'Lydian',
 			'Mahj' => 'Mahajani',
 			'Maka' => 'Makasar',
 			'Mand' => 'Mandaean',
 			'Mani' => 'Manichaean',
 			'Marc' => 'Marchen',
 			'Maya' => 'Dealbh-sgrìobhadh Mayach',
 			'Medf' => 'Medefaidrin',
 			'Mend' => 'Mende',
 			'Merc' => 'Meroiticeach ceangailte',
 			'Mero' => 'Meroiticeach',
 			'Mlym' => 'Malayalam',
 			'Mong' => 'Mongolais',
 			'Mroo' => 'Mro',
 			'Mtei' => 'Meitei Mayek',
 			'Mult' => 'Multani',
 			'Mymr' => 'Miànmar',
 			'Nagm' => 'Nag Mundari',
 			'Nand' => 'Nandinagari',
 			'Narb' => 'Seann-Arabach Thuathach',
 			'Nbat' => 'Nabataean',
 			'Nkgb' => 'Naxi Geba',
 			'Nkoo' => 'N’ko',
 			'Nshu' => 'Nüshu',
 			'Ogam' => 'Ogham-chraobh',
 			'Olck' => 'Ol Chiki',
 			'Onao' => 'Ol Onal',
 			'Orkh' => 'Orkhon',
 			'Orya' => 'Oriya',
 			'Osge' => 'Osage',
 			'Osma' => 'Osmanya',
 			'Ougr' => 'Seann-Ùigiurais',
 			'Palm' => 'Palmyrene',
 			'Pauc' => 'Pau Cin Hau',
 			'Perm' => 'Seann-Phermic',
 			'Phag' => 'Phags-pa',
 			'Phli' => 'Pahlavi nan snaidh-sgrìobhaidhean',
 			'Phlp' => 'Pahlavi nan saltair',
 			'Phnx' => 'Pheniceach',
 			'Plrd' => 'Miao Phollard',
 			'Prti' => 'Partais snaidh-sgrìobhte',
 			'Qaag' => 'Zawgyi',
 			'Rjng' => 'Rejang',
 			'Rohg' => 'Hanifi Rohingya',
 			'Roro' => 'Rongorongo',
 			'Runr' => 'Rùn-sgrìobhadh',
 			'Samr' => 'Samaritanais',
 			'Sara' => 'Sarati',
 			'Sarb' => 'Seann-Arabais Dheasach',
 			'Saur' => 'Saurashtra',
 			'Sgnw' => 'Sgrìobhadh cainnte-sanais',
 			'Shaw' => 'Sgrìobhadh an t-Seathaich',
 			'Shrd' => 'Sharada',
 			'Sidd' => 'Siddham',
 			'Sind' => 'Khudawadi',
 			'Sinh' => 'Sinhala',
 			'Sogd' => 'Sogdianais',
 			'Sogo' => 'Seann-Sogdianais',
 			'Sora' => 'Sora Sompeng',
 			'Soyo' => 'Soyombo',
 			'Sund' => 'Sunda',
 			'Sunu' => 'Sunuwar',
 			'Sylo' => 'Syloti Nagri',
 			'Syrc' => 'Suraidheac',
 			'Syre' => 'Suraidheac Estrangela',
 			'Syrj' => 'Suraidheac Siarach',
 			'Syrn' => 'Suraidheac Earach',
 			'Tagb' => 'Tagbanwa',
 			'Takr' => 'Takri',
 			'Tale' => 'Tai Le',
 			'Talu' => 'Tai Lue Ùr',
 			'Taml' => 'Taimil',
 			'Tang' => 'Tangut',
 			'Tavt' => 'Tai Viet',
 			'Telu' => 'Telugu',
 			'Teng' => 'Tengwar',
 			'Tfng' => 'Tifinagh',
 			'Tglg' => 'Tagalog',
 			'Thaa' => 'Thaana',
 			'Thai' => 'Tàidh',
 			'Tibt' => 'Tibeitis',
 			'Tirh' => 'Tirhuta',
 			'Tnsa' => 'Tangsa',
 			'Todr' => 'Todhri',
 			'Tutg' => 'Tulu-Tigalari',
 			'Ugar' => 'Ugariticeach',
 			'Vaii' => 'Vai',
 			'Vith' => 'Vithkuqi',
 			'Wara' => 'Varang Kshiti',
 			'Wcho' => 'Wancho',
 			'Wole' => 'Woleai',
 			'Xpeo' => 'Seann-Pheirsis',
 			'Xsux' => 'Gèinn-sgrìobhadh Sumer is Akkad',
 			'Yezi' => 'Yezidis',
 			'Yiii' => 'Yi',
 			'Zanb' => 'Zanabazar ceàrnagach',
 			'Zinh' => 'Dìleab',
 			'Zmth' => 'Gnìomhairean matamataig',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Samhlaidhean',
 			'Zxxx' => 'Gun sgrìobhadh',
 			'Zyyy' => 'Coitcheann',
 			'Zzzz' => 'Litreadh neo-aithnichte',

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
			'001' => 'An Saoghal',
 			'002' => 'Afraga',
 			'003' => 'Aimeireaga a Tuath',
 			'005' => 'Aimeireaga a Deas',
 			'009' => 'Roinn a’ Chuain Sèimh',
 			'011' => 'Afraga an Iar',
 			'013' => 'Meadhan Aimeireaga',
 			'014' => 'Afraga an Ear',
 			'015' => 'Afraga a Tuath',
 			'017' => 'Meadhan Afraga',
 			'018' => 'Ceann a Deas Afraga',
 			'019' => 'An Dà Aimeireaga',
 			'021' => 'Ceann a Tuath Aimeireaga',
 			'029' => 'Am Muir Caraibeach',
 			'030' => 'Àisia an Ear',
 			'034' => 'Àisia a Deas',
 			'035' => 'Àisia an Ear-dheas',
 			'039' => 'An Roinn-Eòrpa a Deas',
 			'053' => 'Astràilia is Sealainn Nuadh',
 			'054' => 'Na h-Eileanan Dubha',
 			'057' => 'Roinn nam Meanbh-Eileanan',
 			'061' => 'Poilinèis',
 			'142' => 'Àisia',
 			'143' => 'Meadhan Àisia',
 			'145' => 'Àisia an Iar',
 			'150' => 'An Roinn-Eòrpa',
 			'151' => 'An Roinn-Eòrpa an Ear',
 			'154' => 'An Roinn-Eòrpa a Tuath',
 			'155' => 'An Roinn-Eòrpa an Iar',
 			'202' => 'Afraga Deas air an t-Sathara',
 			'419' => 'Aimeireaga Laidinneach',
 			'AC' => 'Eilean na Deasgabhalach',
 			'AD' => 'Andorra',
 			'AE' => 'Na h-Iomaratan Arabach Aonaichte',
 			'AF' => 'Afghanastàn',
 			'AG' => 'Aintìoga is Barbuda',
 			'AI' => 'Anguillia',
 			'AL' => 'Albàinia',
 			'AM' => 'Airmeinea',
 			'AO' => 'Angòla',
 			'AQ' => 'An Antartaig',
 			'AR' => 'An Argantain',
 			'AS' => 'Samotha na h-Aimeireaga',
 			'AT' => 'An Ostair',
 			'AU' => 'Astràilia',
 			'AW' => 'Arùba',
 			'AX' => 'Na h-Eileanan Åland',
 			'AZ' => 'Asarbaideàn',
 			'BA' => 'Bosna is Hearsagobhana',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladais',
 			'BE' => 'A’ Bheilg',
 			'BF' => 'Buirciona Faso',
 			'BG' => 'A’ Bhulgair',
 			'BH' => 'Bachrain',
 			'BI' => 'Burundaidh',
 			'BJ' => 'Beinin',
 			'BL' => 'Saint Barthélemy',
 			'BM' => 'Bearmùda',
 			'BN' => 'Brùnaigh',
 			'BO' => 'Boilibhia',
 			'BQ' => 'Na Tìrean Ìsle Caraibeach',
 			'BR' => 'Braisil',
 			'BS' => 'Na h-Eileanan Bhathama',
 			'BT' => 'Butàn',
 			'BV' => 'Eilean Bouvet',
 			'BW' => 'Botsuana',
 			'BY' => 'A’ Bhealaruis',
 			'BZ' => 'A’ Bheilìs',
 			'CA' => 'Canada',
 			'CC' => 'Na h-Eileanan Chocos (Keeling)',
 			'CD' => 'Congo - Kinshasa',
 			'CD@alt=variant' => 'A’ Chongo (PDC)',
 			'CF' => 'Poblachd Meadhan Afraga',
 			'CG' => 'A’ Chongo - Brazzaville',
 			'CG@alt=variant' => 'A’ Chongo',
 			'CH' => 'An Eilbheis',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'An Costa Ìbhri',
 			'CK' => 'Eileanan Cook',
 			'CL' => 'An t-Sile',
 			'CM' => 'Camarun',
 			'CN' => 'An t-Sìn',
 			'CO' => 'Coloimbia',
 			'CP' => 'Eilean Clipperton',
 			'CQ' => 'Sarc',
 			'CR' => 'Costa Rìcea',
 			'CU' => 'Cùba',
 			'CV' => 'An Ceap Uaine',
 			'CW' => 'Curaçao',
 			'CX' => 'Eilean na Nollaig',
 			'CY' => 'Cìopras',
 			'CZ' => 'An t-Seic',
 			'CZ@alt=variant' => 'Poblachd na Seice',
 			'DE' => 'A’ Ghearmailt',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Diobùtaidh',
 			'DK' => 'An Danmhairg',
 			'DM' => 'Doiminicea',
 			'DO' => 'A’ Phoblachd Dhoiminiceach',
 			'DZ' => 'Aildiria',
 			'EA' => 'Ceuta agus Melilla',
 			'EC' => 'Eacuador',
 			'EE' => 'An Eastoin',
 			'EG' => 'An Èipheit',
 			'EH' => 'Sathara an Iar',
 			'ER' => 'Eartra',
 			'ES' => 'An Spàinnt',
 			'ET' => 'An Itiop',
 			'EU' => 'An t-Aonadh Eòrpach',
 			'EZ' => 'Raon an Eòro',
 			'FI' => 'An Fhionnlann',
 			'FJ' => 'Fìdi',
 			'FK' => 'Na h-Eileanan Fàclannach',
 			'FK@alt=variant' => 'Na h-Eileanan Fàclannach (Islas Malvinas)',
 			'FM' => 'Na Meanbh-eileanan',
 			'FO' => 'Na h-Eileanan Fàro',
 			'FR' => 'An Fhraing',
 			'GA' => 'Gabon',
 			'GB' => 'An Rìoghachd Aonaichte',
 			'GB@alt=short' => 'RA',
 			'GD' => 'Greanàda',
 			'GE' => 'A’ Chairtbheil',
 			'GF' => 'Guidheàna na Frainge',
 			'GG' => 'Geàrnsaidh',
 			'GH' => 'Gàna',
 			'GI' => 'Diobraltar',
 			'GL' => 'A’ Ghraonlann',
 			'GM' => 'A’ Ghaimbia',
 			'GN' => 'Gini',
 			'GP' => 'Guadalup',
 			'GQ' => 'Gini Mheadhan-Chriosach',
 			'GR' => 'A’ Ghreug',
 			'GS' => 'Seòirsea a Deas is na h-Eileanan Sandwich a Deas',
 			'GT' => 'Guatamala',
 			'GU' => 'Guam',
 			'GW' => 'Gini-Bioso',
 			'GY' => 'Guidheàna',
 			'HK' => 'Hong Kong SAR na Sìne',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Eilean Heard is Eileanan MhicDhòmhnaill',
 			'HN' => 'Hondùras',
 			'HR' => 'A’ Chròthais',
 			'HT' => 'Haidhti',
 			'HU' => 'An Ungair',
 			'IC' => 'Na h-Eileanan Canàrach',
 			'ID' => 'Na h-Innd-innse',
 			'IE' => 'Èirinn',
 			'IL' => 'Iosrael',
 			'IM' => 'Eilean Mhanainn',
 			'IN' => 'Na h-Innseachan',
 			'IO' => 'Ranntair Breatannach Cuan nan Innseachan',
 			'IO@alt=chagos' => 'Innis-mhuir Chagos',
 			'IQ' => 'Ioràc',
 			'IR' => 'Ioràn',
 			'IS' => 'Innis Tìle',
 			'IT' => 'An Eadailt',
 			'JE' => 'Deàrsaidh',
 			'JM' => 'Diameuga',
 			'JO' => 'Iòrdan',
 			'JP' => 'An t-Seapan',
 			'KE' => 'Ceinia',
 			'KG' => 'Cìorgastan',
 			'KH' => 'Cambuidea',
 			'KI' => 'Ciribeas',
 			'KM' => 'Comoros',
 			'KN' => 'Naomh Crìstean is Nibheis',
 			'KP' => 'Coirèa a Tuath',
 			'KR' => 'Coirèa',
 			'KW' => 'Cuibhèit',
 			'KY' => 'Na h-Eileanan Caimean',
 			'KZ' => 'Casachstàn',
 			'LA' => 'Làthos',
 			'LB' => 'Leabanon',
 			'LC' => 'Naomh Lùisea',
 			'LI' => 'Lichtenstein',
 			'LK' => 'Sri Lanca',
 			'LR' => 'Libèir',
 			'LS' => 'Leasoto',
 			'LT' => 'An Liotuain',
 			'LU' => 'Lugsamburg',
 			'LV' => 'An Laitbhe',
 			'LY' => 'Libia',
 			'MA' => 'Moroco',
 			'MC' => 'Monaco',
 			'MD' => 'A’ Mholdobha',
 			'ME' => 'Am Monadh Neagrach',
 			'MF' => 'Naomh Màrtainn',
 			'MG' => 'Madagasgar',
 			'MH' => 'Eileanan Mharshall',
 			'MK' => 'A’ Mhasadon a Tuath',
 			'ML' => 'Màili',
 			'MM' => 'Miànmar',
 			'MN' => 'Dùthaich nam Mongol',
 			'MO' => 'Macàthu SAR na Sìne',
 			'MO@alt=short' => 'Macàthu',
 			'MP' => 'Na h-Eileanan Mairianach a Tuath',
 			'MQ' => 'Mairtinic',
 			'MR' => 'Moratàinea',
 			'MS' => 'Montsarat',
 			'MT' => 'Malta',
 			'MU' => 'Na h-Eileanan Mhoiriseas',
 			'MV' => 'Na h-Eileanan Mhaladaibh',
 			'MW' => 'Malabhaidh',
 			'MX' => 'Meagsago',
 			'MY' => 'Malaidhsea',
 			'MZ' => 'Mòsaimbic',
 			'NA' => 'An Namaib',
 			'NC' => 'Cailleann Nuadh',
 			'NE' => 'Nìgeir',
 			'NF' => 'Eilean Norfolk',
 			'NG' => 'Nigèiria',
 			'NI' => 'Niocaragua',
 			'NL' => 'Na Tìrean Ìsle',
 			'NO' => 'Nirribhidh',
 			'NP' => 'Neapàl',
 			'NR' => 'Nabhru',
 			'NU' => 'Niue',
 			'NZ' => 'Sealainn Nuadh',
 			'NZ@alt=variant' => 'Aotearoa Sealainn Nuadh',
 			'OM' => 'Omàn',
 			'PA' => 'Panama',
 			'PE' => 'Pearù',
 			'PF' => 'Poilinèis na Frainge',
 			'PG' => 'Gini Nuadh Phaputhach',
 			'PH' => 'Na h-Eileanan Filipineach',
 			'PK' => 'Pagastàn',
 			'PL' => 'A’ Phòlainn',
 			'PM' => 'Saint Pierre agus Miquelon',
 			'PN' => 'Eileanan Pheit a’ Chàirn',
 			'PR' => 'Porto Rìceo',
 			'PS' => 'Ùghdarras nam Palastaineach',
 			'PS@alt=short' => 'Palastain',
 			'PT' => 'A’ Phortagail',
 			'PW' => 'Palabh',
 			'PY' => 'Paraguaidh',
 			'QA' => 'Catar',
 			'QO' => 'Roinn Iomallach a’ Chuain Sèimh',
 			'RE' => 'Réunion',
 			'RO' => 'Romàinia',
 			'RS' => 'An t-Sèirb',
 			'RU' => 'An Ruis',
 			'RW' => 'Rubhanda',
 			'SA' => 'Aràibia nan Sabhd',
 			'SB' => 'Eileanan Sholaimh',
 			'SC' => 'Na h-Eileanan Sheiseall',
 			'SD' => 'Sudàn',
 			'SE' => 'An t-Suain',
 			'SG' => 'Singeapòr',
 			'SH' => 'Eilean Naomh Eilidh',
 			'SI' => 'An t-Slòbhain',
 			'SJ' => 'Svalbard is Jan Mayen',
 			'SK' => 'An t-Slòbhac',
 			'SL' => 'Siarra Leòmhann',
 			'SM' => 'San Marino',
 			'SN' => 'Seanagal',
 			'SO' => 'Somàilia',
 			'SR' => 'Suranam',
 			'SS' => 'Sudàn a Deas',
 			'ST' => 'São Tomé agus Príncipe',
 			'SV' => 'An Salbhador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Siridhea',
 			'SZ' => 'eSwatini',
 			'SZ@alt=variant' => 'Dùthaich nan Suasaidh',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Na h-Eileanan Turcach is Caiceo',
 			'TD' => 'An t-Seàd',
 			'TF' => 'Ranntairean a Deas na Frainge',
 			'TG' => 'Togo',
 			'TH' => 'Dùthaich nan Tàidh',
 			'TJ' => 'Taidigeastàn',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TL@alt=variant' => 'Tìomor an Ear',
 			'TM' => 'Turcmanastàn',
 			'TN' => 'Tuinisea',
 			'TO' => 'Tonga',
 			'TR' => 'An Tuirc',
 			'TT' => 'Trianaid agus Tobago',
 			'TV' => 'Tubhalu',
 			'TW' => 'Taidh-Bhàn',
 			'TZ' => 'An Tansan',
 			'UA' => 'An Ucràin',
 			'UG' => 'Uganda',
 			'UM' => 'Meanbh-Eileanan Iomallach nan SA',
 			'UN' => 'Na Dùthchannan Aonaichte',
 			'US' => 'Na Stàitean Aonaichte',
 			'US@alt=short' => 'SA',
 			'UY' => 'Uruguaidh',
 			'UZ' => 'Usbagastàn',
 			'VA' => 'Cathair na Bhatacain',
 			'VC' => 'Naomh Bhionsant agus Eileanan Greanadach',
 			'VE' => 'A’ Bheiniseala',
 			'VG' => 'Eileanan Breatannach na Maighdinn',
 			'VI' => 'Eileanan na Maighdinn aig na SA',
 			'VN' => 'Bhiet-Nam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Uallas agus Futuna',
 			'WS' => 'Samotha',
 			'XA' => 'Sràcan fuadain',
 			'XB' => 'Dà-chomhaireach fuadain',
 			'XK' => 'A’ Chosobho',
 			'YE' => 'An Eaman',
 			'YT' => 'Mayotte',
 			'ZA' => 'Afraga a Deas',
 			'ZM' => 'Sàimbia',
 			'ZW' => 'An t-Sìombab',
 			'ZZ' => 'Roinn-dùthcha neo-aithnichte',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'Litreachadh tradaiseanta na Gearmailtise',
 			'1994' => 'Litreachadh stannardach dual-chainnt Resia',
 			'1996' => 'Litreachadh na Gearmailtise 1996',
 			'1606NICT' => 'Meadhan-Fhraingis anmoch gu 1606',
 			'1694ACAD' => 'Nua-Fhraingis thràth',
 			'1959ACAD' => 'Bealaruisis Acadamaigeach',
 			'ABL1943' => 'Gnàthas-litreachaidh 1943',
 			'AKUAPEM' => 'Akuapem',
 			'ALALC97' => 'Ròmanachadh ALA-LC 1997',
 			'ALUKU' => 'Dual-chainnt Aluku',
 			'AO1990' => 'Aonta litreachadh na Portagailise 1990',
 			'ARANES' => 'Aranais',
 			'AREVELA' => 'Airmeinis an Ear',
 			'AREVMDA' => 'Airmeinis an Iar',
 			'ARKAIKA' => 'Arkaika',
 			'ASANTE' => 'Asante',
 			'AUVERN' => 'Auvernhat',
 			'BAKU1926' => 'Abidil Laideann aonaichte na Turcaise',
 			'BALANKA' => 'Dual-chainnt Balanka de Anii',
 			'BARLA' => 'Dual-chainntean Barlavento de Kabuverdianu',
 			'BASICENG' => 'Beurla bhunasach',
 			'BAUDDHA' => 'Bauddha',
 			'BISCAYAN' => 'Dual-chainnt Bizkaia',
 			'BISKE' => 'Dual-chainnt San Giorgio/Bila',
 			'BOHORIC' => 'Aibidil Bohorič',
 			'BOONT' => 'Boontling',
 			'BORNHOLM' => 'Bornholmsk',
 			'CISAUP' => 'Ogsatanais cios-Ailpeach',
 			'COLB1945' => 'Aonta litreachaidh eadar a’ Phortagail is Braisil 1945',
 			'CORNU' => 'Beurla na Còirne',
 			'CREISS' => 'Ogsatanais Chroissant',
 			'DAJNKO' => 'Aibidil Dajnko',
 			'EKAVSK' => 'Sèirbhis le fuaimneachadh iarach',
 			'EMODENG' => 'Nua-Bheurla thràth',
 			'FONIPA' => 'Comharran fuaim-eòlais an IPA',
 			'FONKIRSH' => 'Còdachadh Kirshenbaum na h-Aibidil Fuaim-eòlaiche',
 			'FONNAPA' => 'Aibidil Fhuaim-eòlach Aimeireaga a Tuath',
 			'FONUPA' => 'Comharran fuaim-eòlais an UPA',
 			'FONXSAMP' => 'Tar-sgrìobhadh X-SAMPA',
 			'GALLO' => 'Gallo',
 			'GASCON' => 'Ogsatanais Ghascogne',
 			'GRCLASS' => 'Nòs-sgrìobhaidh clasaigeach na h-Ogsatanaise',
 			'GRITAL' => 'Nòs-sgrìobhaidh Eadailteach na h-Ogsatanaise',
 			'GRMISTR' => 'Nòs-sgrìobhaidh Mhistral na h-Ogsatanaise',
 			'HEPBURN' => 'Ròmanachadh Hepburn',
 			'HOGNORSK' => 'Høgnorsk',
 			'HSISTEMO' => 'Roghainn-èiginn stannardach litreachadh na h-Esperanto le h',
 			'IJEKAVSK' => 'Sèirbis le fuaimneachadh Ijekavia',
 			'ITIHASA' => 'Itihasa',
 			'IVANCHOV' => 'Bulgarian in 1899 orthography = Bulgairis le litreachadh na bliadhna 1899',
 			'JAUER' => 'Jauer',
 			'JYUTPING' => 'Jyutping',
 			'KKCOR' => 'Litreachadh coitcheann',
 			'KOCIEWIE' => 'Kociewie',
 			'KSCOR' => 'Litreachadh stannardach',
 			'LAUKIKA' => 'Laukika',
 			'LEMOSIN' => 'Ogsatanais Lemosin',
 			'LENGADOC' => 'Ogsatanais Lengadoc',
 			'LIPAW' => 'Dual-chainnt Lipovaz Resia',
 			'LTG1929' => 'Litreachadh na Latgailise 1929',
 			'LTG2007' => 'Litreachadh na Latgailise 2007',
 			'LUNA1918' => 'Litreachadh na Ruisise às dèidh 1917',
 			'METELKO' => 'Aibidil Metelko',
 			'MONOTON' => 'Greugais mhonotonach',
 			'NDYUKA' => 'Dual-chainnt Ndyuka',
 			'NEDIS' => 'Dual-chainnt Natisone',
 			'NEWFOUND' => 'Beurla Talamh an Èisg',
 			'NICARD' => 'Ogsatanais Nice',
 			'NJIVA' => 'Dual-chainnt Gniva/Njiva',
 			'NULIK' => 'Nua-Volapük',
 			'OSOJS' => 'Dual-chainnt Oseacco/Osojane',
 			'OXENDICT' => 'Litreachadh faclair Oxford na Beurla',
 			'PAHAWH2' => 'Pahawh Hmong na 2na ìre',
 			'PAHAWH3' => 'Pahawh Hmong na 3s ìre',
 			'PAHAWH4' => 'Pahawh Hmong na 4mh ìre',
 			'PAMAKA' => 'Dual-chainnt Pamaka',
 			'PEANO' => 'Peano',
 			'PETR1708' => 'Litreachadh Pheadair 1708',
 			'PINYIN' => 'Ròmanachadh Pinyin',
 			'POLYTON' => 'Greugais phoiliotonach',
 			'POSIX' => 'Coimpiutair',
 			'PROVENC' => 'Ogsatanais Phrovence',
 			'PUTER' => 'Puter',
 			'REVISED' => 'Litreachadh lèirmheasaichte',
 			'RIGIK' => 'Volapük chlasaigeach',
 			'ROZAJ' => 'Dual-chainnt Resia',
 			'RUMGR' => 'Rumantsch Grischun',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Beurla Stannardach na h-Alba',
 			'SCOUSE' => 'Scouse',
 			'SIMPLE' => 'Samhlaidhean sìmplichte',
 			'SOLBA' => 'Dual-chainnt Stolvizza/Solbica',
 			'SOTAV' => 'Dual-chainntean Sotavento de Kabuverdianu',
 			'SPANGLIS' => 'Spanglish',
 			'SURMIRAN' => 'Surmiran',
 			'SURSILV' => 'Sursilvan',
 			'SUTSILV' => 'Sutsilvan',
 			'SYNNEJYL' => 'Diutlannais Dheasach',
 			'TARASK' => 'Litreachadh Taraškievica',
 			'TONGYONG' => 'Tongyong',
 			'TUNUMIIT' => 'Tunumiit',
 			'UCCOR' => 'Litreachadh aonaichte',
 			'UCRCOR' => 'Litreachadh aonaichte ’s lèirmheasaichte',
 			'ULSTER' => 'Albais Uladh',
 			'UNIFON' => 'Aibidil fuaim-eòlais Unifon',
 			'VAIDIKA' => 'Vaidika',
 			'VALENCIA' => 'Valencià',
 			'VALLADER' => 'Vallader',
 			'VECDRUKA' => 'Vecā Druka',
 			'VIVARAUP' => 'Ogsatanais Vivaro-Ailpeach',
 			'WADEGILE' => 'Ròmanachadh Wade-Giles',
 			'XSISTEMO' => 'Roghainn-èiginn stannardach litreachadh na h-Esperanto le x',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Mìosachan',
 			'cf' => 'Fòrmat an airgeadra',
 			'collation' => 'Òrdugh an t-seòrsachaidh',
 			'currency' => 'Airgeadra',
 			'hc' => 'Cearcall an ama (12 no 24 uair)',
 			'lb' => 'Stoidhle nam brisidhean-loidhe',
 			'ms' => 'Siostam tomhais',
 			'numbers' => 'Àireamhan',

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
 				'buddhist' => q{Am Mìosachan Budach},
 				'chinese' => q{Am Mìosachan Sìneach},
 				'coptic' => q{Am Mìosachan Coptach},
 				'dangi' => q{Mìosachan Dangi},
 				'ethiopic' => q{Mìosachan na h-Itioipe},
 				'ethiopic-amete-alem' => q{Mìosachan Itiopach Amete Alem},
 				'gregorian' => q{Am Mìosachan Griogarach},
 				'hebrew' => q{Am Mìosachan Eabhrach},
 				'indian' => q{Mìosachan Nàiseanta nan Innseachan},
 				'islamic' => q{Am Mìosachan Hijri},
 				'islamic-civil' => q{Am Mìosachan Hijri (clàrach, linn sìobhalta)},
 				'islamic-rgsa' => q{Am Mìosachan Hijri (Aràibia nan Sabhd, sealladh)},
 				'islamic-tbla' => q{Am Mìosachan Hijri (clàrach, linn reul-eòlach)},
 				'islamic-umalqura' => q{Am Mìosachan Hijri (Umm al-Qura)},
 				'iso8601' => q{Mìosachan ISO-8601},
 				'japanese' => q{Am Mìosachan Seapanach},
 				'persian' => q{Am Mìosachan Pearsach},
 				'roc' => q{Mìosachan Poblachd na Sìne},
 			},
 			'cf' => {
 				'account' => q{Fòrmat airgeadra na cunntasachd},
 				'standard' => q{Fòrmat stannardach an airgeadra},
 			},
 			'collation' => {
 				'big5han' => q{Òrdugh seòrsachaidh na Sìnise Tradaiseanta - Big5},
 				'compat' => q{Òrdugh seòrsachaidh roimhe a chum co-chòrdalachd},
 				'dictionary' => q{Òrdugh seòrsachaidh an fhaclair},
 				'ducet' => q{Òrdugh seòrsachaidh Unicode bunaiteach},
 				'emoji' => q{Òrdugh seòrsachaidh Emoji},
 				'eor' => q{Òrdugh seòrsachaidh Eòrpach},
 				'gb2312han' => q{Òrdugh seòrsachaidh na Sìnise Simplichte - GB2312},
 				'phonebook' => q{Òrdugh seòrsachaidh nan leabhraichean-fòn},
 				'pinyin' => q{Òrdugh seòrsachaidh Pinyin},
 				'search' => q{Lorg coitcheann},
 				'searchjl' => q{Lorg leis a’ chiad chonnrag Hangul},
 				'standard' => q{Òrdugh seòrsachaidh stannardach},
 				'stroke' => q{Òrdugh nan stràcan},
 				'traditional' => q{Òrdugh seòrsachaidh tradaiseanta},
 				'unihan' => q{Òrdugh an fhreumha ’s nan stràcan},
 				'zhuyin' => q{Òrdugh seòrsachaidh Zhuyin},
 			},
 			'd0' => {
 				'fwidth' => q{Làn-Leud},
 				'hwidth' => q{Leth-Leud},
 				'npinyin' => q{Àireamhach},
 			},
 			'hc' => {
 				'h11' => q{Cleoc 12 uair a thìde (0–11)},
 				'h12' => q{Cleoc 12 uair a thìde (1–12)},
 				'h23' => q{Cleoc 24 uair a thìde (0–23)},
 				'h24' => q{Cleoc 24 uair a thìde (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Brisidhean-loidhe fuasgailte},
 				'normal' => q{Brisidhean-loidhe àbhaisteach},
 				'strict' => q{Brisidhean-loidhe teanna},
 			},
 			'm0' => {
 				'bgn' => q{Tar-litreachadh BGN nan Stàitean Aonaichte},
 				'ungegn' => q{Tar-litreachadh GEGN nan Dùthchannan Aonaichte},
 			},
 			'ms' => {
 				'metric' => q{Tomhas meatrach},
 				'uksystem' => q{Tomhas impireil},
 				'ussystem' => q{Tomhas nan Stàitean Aonaichte},
 			},
 			'numbers' => {
 				'ahom' => q{Àireamhan Ahom},
 				'arab' => q{Àireamhan Arabach-Innseanach},
 				'arabext' => q{Àireamhan Arabach-Innseanach leudaichte},
 				'armn' => q{Àireamhan na h-Airmeinise},
 				'armnlow' => q{Àireamhan beaga na h-Airmeinise},
 				'bali' => q{Àireamhan Bali},
 				'beng' => q{Àireamhan na Beangailise},
 				'brah' => q{Àireamhan Brahmi},
 				'cakm' => q{Àireamhan Chakma},
 				'cham' => q{Àireamhan Cham},
 				'cyrl' => q{Àireamhan na Cirilise},
 				'deva' => q{Àireamhan Devanagari},
 				'diak' => q{Àireamhan Dives Akuru},
 				'ethi' => q{Àireamhan Itiopach},
 				'fullwide' => q{Àireamhan làn-leud},
 				'gara' => q{Àireamhan Garay},
 				'geor' => q{Àireamhan na Cairtbheilise},
 				'gong' => q{Àireamhan Gunjala Gondi},
 				'gonm' => q{Àireamhan Masaram Gondi},
 				'grek' => q{Àireamhan na Greugaise},
 				'greklow' => q{Àireamhan beaga na Greugaise},
 				'gujr' => q{Àireamhan Gujarati},
 				'gukh' => q{Àireamhan Gurung Khema},
 				'guru' => q{Àireamhan Gurmukhi},
 				'hanidec' => q{Àireamhan deicheach na Sìnise},
 				'hans' => q{Àireamhan na Sìnise Shimplichte},
 				'hansfin' => q{Àireamhan ionmhasail na Sìnise Shimplichte},
 				'hant' => q{Àireamhan na Sìnise Thradaiseanta},
 				'hantfin' => q{Àireamhan ionmhasail na Sìnise Thradaiseanta},
 				'hebr' => q{Àireamhan na h-Eabhra},
 				'hmng' => q{Àireamhan Pahawh Hmong},
 				'hmnp' => q{Àireamhan Nyiakeng Puachue},
 				'java' => q{Àireamhan na Deàbhanaise},
 				'jpan' => q{Àireamhan na Seapanaise},
 				'jpanfin' => q{Àireamhan ionmhasail na Seapanaise},
 				'kali' => q{Àireamhan Kayah Li},
 				'kawi' => q{Àireamhan Kawi},
 				'khmr' => q{Àireamhan Cmèar},
 				'knda' => q{Àireamhan Kannada},
 				'krai' => q{Àireamhan Kirat Rai},
 				'lana' => q{Àireamhan Tai Tham Hora},
 				'lanatham' => q{Àireamhan Tai Tham Tham},
 				'laoo' => q{Àireamhan Làtho},
 				'latn' => q{Àireamhan Siarach},
 				'lepc' => q{Àireamhan Lepcha},
 				'limb' => q{Àireamhan Limbu},
 				'mathbold' => q{Àireamhan matamataig troma},
 				'mathdbl' => q{Àireamhan matamataig le loidhne dhùbailte},
 				'mathmono' => q{Àireamhan matamataig aon-leud},
 				'mathsanb' => q{Àireamhan matamataig sans-serif troma},
 				'mathsans' => q{Àireamhan matamataig sans-serif},
 				'mlym' => q{Àireamhan Malayalam},
 				'modi' => q{Àireamhan Modi},
 				'mong' => q{Àireamhan na Mongolaise},
 				'mroo' => q{Àireamhan Mro},
 				'mtei' => q{Àireamhan Meetei Mayek},
 				'mymr' => q{Àireamhan Miànmar},
 				'mymrepka' => q{Àireamhan Pwo Karen Miànmar an Ear},
 				'mymrpao' => q{Àireamhan Pao Miànmar},
 				'mymrshan' => q{Àireamhan Shan Miànmar},
 				'mymrtlng' => q{Àireamhan Tai Laing Miànmar},
 				'nagm' => q{Àireamhan Nag Mundari},
 				'nkoo' => q{Àireamhan N’Ko},
 				'olck' => q{Àireamhan Ol Chiki},
 				'onao' => q{Àireamhan Ol Onal},
 				'orya' => q{Àireamhan Odia},
 				'osma' => q{Àireamhan Osmanya},
 				'outlined' => q{Àireamhan oir-loidhnichte},
 				'rohg' => q{Àireamhan Hanifi Rohingya},
 				'roman' => q{Àireamhan Ròmanach},
 				'romanlow' => q{Àireamhan beaga Ròmanach},
 				'saur' => q{Àireamhan Saurashtra},
 				'shrd' => q{Àireamhan Sharada},
 				'sind' => q{Àireamhan Khudawadi},
 				'sinh' => q{Àireamhan Lith na Sinhala},
 				'sora' => q{Àireamhan Sora Sompeng},
 				'sund' => q{Àireamhan Sunda},
 				'sunu' => q{Àireamhan Sunuwar},
 				'takr' => q{Àireamhan Takri},
 				'talu' => q{Àireamhan Tai Lue Ùr},
 				'taml' => q{Àireamhan na Taimilise Tradaiseanta},
 				'tamldec' => q{Àireamhan na Taimilise},
 				'telu' => q{Àireamhan Telugu},
 				'thai' => q{Àireamhan Tàidh},
 				'tibt' => q{Àireamhan na Tibeitise},
 				'tirh' => q{Àireamhan Tirhuta},
 				'tnsa' => q{Àireamhan Tangsa},
 				'vaii' => q{Àireamhan Vai},
 				'wara' => q{Àireamhan Warang Citi},
 				'wcho' => q{Àireamhan Wancho},
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
			'metric' => q{Meatrach},
 			'UK' => q{RA},
 			'US' => q{SA},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Cànan: {0}',
 			'script' => 'Litreadh: {0}',
 			'region' => 'Roinn-dùthcha: {0}',

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
			auxiliary => qr{[áăâåäãā æ ċç ḋ éĕêëē ḟ ġ íĭîïī ı j k ł ṁ ñ óŏôöøō œ ṗ q ṡşș ṫ úŭûüū v w x yÿ z]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U'],
			main => qr{[aà b c d eè f g h iì l m n oò p r s t uù]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ¡ ? . … · '‘’ "“” ( ) \[ \] \{ \} § ¶ @ * / \& ⁊ # % † ‡ ‧ ° © ® ™]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U'], };
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
						'name' => q(comhair combaist),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(comhair combaist),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(kibi-{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(kibi-{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(mebi-{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(mebi-{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(gibi-{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(gibi-{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(tebi-{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(tebi-{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(pebi-{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(pebi-{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(exbi-{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(exbi-{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(zebi-{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(zebi-{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(yobe-{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yobe-{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(deicheamh-{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(deicheamh-{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(piceo-{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(piceo-{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(femto-{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(femto-{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(atto-{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(atto-{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(ceuda{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(ceuda{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(zepto-{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(zepto-{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(yocto-{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yocto-{0}),
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
						'1' => q(micreo-{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(micreo-{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(nano-{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(nano-{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(deaca-{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(deaca-{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(tera-{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(tera-{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(peta-{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(peta-{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q(exa-{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(exa-{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(heacta-{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(heacta-{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(zetta-{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(zetta-{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(yotta-{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(yotta-{0}),
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
						'1' => q(cile{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(cile{0}),
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
						'1' => q(meaga-{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(meaga-{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(giga-{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(giga-{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'few' => q({0} forsan-g),
						'one' => q({0} fhorsa-g),
						'other' => q({0} forsa-g),
						'two' => q({0} fhorsa-g),
					},
					# Core Unit Identifier
					'g-force' => {
						'few' => q({0} forsan-g),
						'one' => q({0} fhorsa-g),
						'other' => q({0} forsa-g),
						'two' => q({0} fhorsa-g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'few' => q({0} meatairean san diog cheàrnagach),
						'name' => q(meatair san diog cheàrnagach),
						'one' => q({0} mheatair san diog cheàrnagach),
						'other' => q({0} meatair san diog cheàrnagach),
						'two' => q({0} mheatair san diog cheàrnagach),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'few' => q({0} meatairean san diog cheàrnagach),
						'name' => q(meatair san diog cheàrnagach),
						'one' => q({0} mheatair san diog cheàrnagach),
						'other' => q({0} meatair san diog cheàrnagach),
						'two' => q({0} mheatair san diog cheàrnagach),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'few' => q({0} àrc-mhionaidean),
						'name' => q(àrc-mhionaid),
						'one' => q({0} àrc-mhionaid),
						'other' => q({0} àrc-mhionaid),
						'two' => q({0} àrc-mhionaid),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'few' => q({0} àrc-mhionaidean),
						'name' => q(àrc-mhionaid),
						'one' => q({0} àrc-mhionaid),
						'other' => q({0} àrc-mhionaid),
						'two' => q({0} àrc-mhionaid),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'few' => q({0} àrc-dhiogan),
						'one' => q({0} àrc-dhiog),
						'other' => q({0} àrc-dhiog),
						'two' => q({0} àrc-dhiog),
					},
					# Core Unit Identifier
					'arc-second' => {
						'few' => q({0} àrc-dhiogan),
						'one' => q({0} àrc-dhiog),
						'other' => q({0} àrc-dhiog),
						'two' => q({0} àrc-dhiog),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'few' => q({0} ceuman),
						'one' => q({0} cheum),
						'other' => q({0} ceum),
						'two' => q({0} cheum),
					},
					# Core Unit Identifier
					'degree' => {
						'few' => q({0} ceuman),
						'one' => q({0} cheum),
						'other' => q({0} ceum),
						'two' => q({0} cheum),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'few' => q({0} rèideanan),
						'one' => q({0} rèidean),
						'other' => q({0} rèidean),
						'two' => q({0} rèidean),
					},
					# Core Unit Identifier
					'radian' => {
						'few' => q({0} rèideanan),
						'one' => q({0} rèidean),
						'other' => q({0} rèidean),
						'two' => q({0} rèidean),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0} acraichean),
						'one' => q({0} acair),
						'other' => q({0} acair),
						'two' => q({0} acair),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0} acraichean),
						'one' => q({0} acair),
						'other' => q({0} acair),
						'two' => q({0} acair),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'few' => q({0} heactairean),
						'one' => q({0} heactair),
						'other' => q({0} heactair),
						'two' => q({0} heactair),
					},
					# Core Unit Identifier
					'hectare' => {
						'few' => q({0} heactairean),
						'one' => q({0} heactair),
						'other' => q({0} heactair),
						'two' => q({0} heactair),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'few' => q({0} ceudameatairean ceàrnagach),
						'name' => q(ceudameatair ceàrnagach),
						'one' => q({0} cheudameatair ceàrnagach),
						'other' => q({0} ceudameatair ceàrnagach),
						'per' => q({0} sa cheudameatair cheàrnagach),
						'two' => q({0} cheudameatair ceàrnagach),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'few' => q({0} ceudameatairean ceàrnagach),
						'name' => q(ceudameatair ceàrnagach),
						'one' => q({0} cheudameatair ceàrnagach),
						'other' => q({0} ceudameatair ceàrnagach),
						'per' => q({0} sa cheudameatair cheàrnagach),
						'two' => q({0} cheudameatair ceàrnagach),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0} troighean ceàrnagach),
						'name' => q(troigh cheàrnagach),
						'one' => q({0} troigh cheàrnagach),
						'other' => q({0} troigh cheàrnagach),
						'two' => q({0} throigh cheàrnagach),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0} troighean ceàrnagach),
						'name' => q(troigh cheàrnagach),
						'one' => q({0} troigh cheàrnagach),
						'other' => q({0} troigh cheàrnagach),
						'two' => q({0} throigh cheàrnagach),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0} òirlich cheàrnagach),
						'name' => q(òirleach cheàrnagach),
						'one' => q({0} òirleach cheàrnagach),
						'other' => q({0} òirleach cheàrnagach),
						'per' => q({0} san òirleach cheàrnagach),
						'two' => q({0} òirleach cheàrnagach),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0} òirlich cheàrnagach),
						'name' => q(òirleach cheàrnagach),
						'one' => q({0} òirleach cheàrnagach),
						'other' => q({0} òirleach cheàrnagach),
						'per' => q({0} san òirleach cheàrnagach),
						'two' => q({0} òirleach cheàrnagach),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'few' => q({0} cilemeatairean ceàrnagach),
						'name' => q(cilemeatair ceàrnagach),
						'one' => q({0} chilemeatair ceàrnagach),
						'other' => q({0} cilemeatair ceàrnagach),
						'per' => q({0} sa chilemeatair cheàrnagach),
						'two' => q({0} chilemeatair ceàrnagach),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'few' => q({0} cilemeatairean ceàrnagach),
						'name' => q(cilemeatair ceàrnagach),
						'one' => q({0} chilemeatair ceàrnagach),
						'other' => q({0} cilemeatair ceàrnagach),
						'per' => q({0} sa chilemeatair cheàrnagach),
						'two' => q({0} chilemeatair ceàrnagach),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'few' => q({0} meatairean ceàrnagach),
						'name' => q(meatair ceàrnagach),
						'one' => q({0} mheatair ceàrnagach),
						'other' => q({0} meatair ceàrnagach),
						'per' => q({0} sa mheatair cheàrnagach),
						'two' => q({0} mheatair ceàrnagach),
					},
					# Core Unit Identifier
					'square-meter' => {
						'few' => q({0} meatairean ceàrnagach),
						'name' => q(meatair ceàrnagach),
						'one' => q({0} mheatair ceàrnagach),
						'other' => q({0} meatair ceàrnagach),
						'per' => q({0} sa mheatair cheàrnagach),
						'two' => q({0} mheatair ceàrnagach),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0} mìltean ceàrnagach),
						'name' => q(mìle cheàrnagach),
						'one' => q({0} mhìle cheàrnagach),
						'other' => q({0} mìle cheàrnagach),
						'per' => q({0} sa mhìle cheàrnagach),
						'two' => q({0} mhìle cheàrnagach),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0} mìltean ceàrnagach),
						'name' => q(mìle cheàrnagach),
						'one' => q({0} mhìle cheàrnagach),
						'other' => q({0} mìle cheàrnagach),
						'per' => q({0} sa mhìle cheàrnagach),
						'two' => q({0} mhìle cheàrnagach),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0} slatan ceàrnagach),
						'name' => q(slat cheàrnagach),
						'one' => q({0} shlat cheàrnagach),
						'other' => q({0} slat cheàrnagach),
						'two' => q({0} shlat cheàrnagach),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0} slatan ceàrnagach),
						'name' => q(slat cheàrnagach),
						'one' => q({0} shlat cheàrnagach),
						'other' => q({0} slat cheàrnagach),
						'two' => q({0} shlat cheàrnagach),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'few' => q({0} nithean),
						'one' => q({0} nì),
						'other' => q({0} nì),
						'two' => q({0} nì),
					},
					# Core Unit Identifier
					'item' => {
						'few' => q({0} nithean),
						'one' => q({0} nì),
						'other' => q({0} nì),
						'two' => q({0} nì),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'few' => q({0} karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
						'two' => q({0} karat),
					},
					# Core Unit Identifier
					'karat' => {
						'few' => q({0} karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
						'two' => q({0} karat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} miligramaichean san deicheamh-liotair),
						'name' => q(miligram san deicheamh-liotair),
						'one' => q({0} mhiligram san deicheamh-liotair),
						'other' => q({0} miligram san deicheamh-liotair),
						'two' => q({0} mhiligram san deicheamh-liotair),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} miligramaichean san deicheamh-liotair),
						'name' => q(miligram san deicheamh-liotair),
						'one' => q({0} mhiligram san deicheamh-liotair),
						'other' => q({0} miligram san deicheamh-liotair),
						'two' => q({0} mhiligram san deicheamh-liotair),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'few' => q({0} milimòlaichean san liotair),
						'name' => q(milimòl san liotair),
						'one' => q({0} mhilimòl san liotair),
						'other' => q({0} milimòl san liotair),
						'two' => q({0} mhilimòl san liotair),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'few' => q({0} milimòlaichean san liotair),
						'name' => q(milimòl san liotair),
						'one' => q({0} mhilimòl san liotair),
						'other' => q({0} milimòl san liotair),
						'two' => q({0} mhilimòl san liotair),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'few' => q({0} mòlaichean),
						'one' => q({0} mhòl),
						'other' => q({0} mòl),
						'two' => q({0} mhòl),
					},
					# Core Unit Identifier
					'mole' => {
						'few' => q({0} mòlaichean),
						'one' => q({0} mhòl),
						'other' => q({0} mòl),
						'two' => q({0} mhòl),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'few' => q({0} sa cheud),
						'one' => q({0} sa cheud),
						'other' => q({0} sa cheud),
						'two' => q({0} sa cheud),
					},
					# Core Unit Identifier
					'percent' => {
						'few' => q({0} sa cheud),
						'one' => q({0} sa cheud),
						'other' => q({0} sa cheud),
						'two' => q({0} sa cheud),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'few' => q({0} sa mhìle),
						'one' => q({0} sa mhìle),
						'other' => q({0} sa mhìle),
						'two' => q({0} sa mhìle),
					},
					# Core Unit Identifier
					'permille' => {
						'few' => q({0} sa mhìle),
						'one' => q({0} sa mhìle),
						'other' => q({0} sa mhìle),
						'two' => q({0} sa mhìle),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'few' => q({0} pàirtean sa mhillean),
						'name' => q(pàirt sa mhillean),
						'one' => q({0} phàirt sa mhillean),
						'other' => q({0} pàirt sa mhillean),
						'two' => q({0} phàirt sa mhillean),
					},
					# Core Unit Identifier
					'permillion' => {
						'few' => q({0} pàirtean sa mhillean),
						'name' => q(pàirt sa mhillean),
						'one' => q({0} phàirt sa mhillean),
						'other' => q({0} pàirt sa mhillean),
						'two' => q({0} phàirt sa mhillean),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'few' => q({0} sna deich mìltean),
						'one' => q({0} sna deich mìltean),
						'other' => q({0} sna deich mìltean),
						'two' => q({0} sna deich mìltean),
					},
					# Core Unit Identifier
					'permyriad' => {
						'few' => q({0} sna deich mìltean),
						'one' => q({0} sna deich mìltean),
						'other' => q({0} sna deich mìltean),
						'two' => q({0} sna deich mìltean),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'few' => q({0} pàirtean sa bhillean),
						'name' => q(pàirt sa bhillean),
						'one' => q({0} phàirt sa bhillean),
						'other' => q({0} pàirt sa bhillean),
						'two' => q({0} phàirt sa bhillean),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'few' => q({0} pàirtean sa bhillean),
						'name' => q(pàirt sa bhillean),
						'one' => q({0} phàirt sa bhillean),
						'other' => q({0} pàirt sa bhillean),
						'two' => q({0} phàirt sa bhillean),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} liotairean sa 100 chilemeatair),
						'name' => q(liotair sa 100 chilemeatair),
						'one' => q({0} liotair sa 100 chilemeatair),
						'other' => q({0} liotair sa 100 chilemeatair),
						'two' => q({0} liotair sa 100 chilemeatair),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} liotairean sa 100 chilemeatair),
						'name' => q(liotair sa 100 chilemeatair),
						'one' => q({0} liotair sa 100 chilemeatair),
						'other' => q({0} liotair sa 100 chilemeatair),
						'two' => q({0} liotair sa 100 chilemeatair),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} liotairean sa chilemeatair),
						'name' => q(liotair sa chilemeatair),
						'one' => q({0} liotair sa chilemeatair),
						'other' => q({0} liotair sa chilemeatair),
						'two' => q({0} liotair sa chilemeatair),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} liotairean sa chilemeatair),
						'name' => q(liotair sa chilemeatair),
						'one' => q({0} liotair sa chilemeatair),
						'other' => q({0} liotair sa chilemeatair),
						'two' => q({0} liotair sa chilemeatair),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} mìltean sa ghalan),
						'name' => q(mìle sa ghalan),
						'one' => q({0} mhìle sa ghalan),
						'other' => q({0} mìle sa ghalan),
						'two' => q({0} mhìle sa ghalan),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} mìltean sa ghalan),
						'name' => q(mìle sa ghalan),
						'one' => q({0} mhìle sa ghalan),
						'other' => q({0} mìle sa ghalan),
						'two' => q({0} mhìle sa ghalan),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} mìltean sa ghalan ìmpireil),
						'name' => q(mìle sa ghalan ìmpireil),
						'one' => q({0} mhìle sa ghalan ìmpireil),
						'other' => q({0} mìle sa ghalan ìmpireil),
						'two' => q({0} mhìle sa ghalan ìmpireil),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} mìltean sa ghalan ìmpireil),
						'name' => q(mìle sa ghalan ìmpireil),
						'one' => q({0} mhìle sa ghalan ìmpireil),
						'other' => q({0} mìle sa ghalan ìmpireil),
						'two' => q({0} mhìle sa ghalan ìmpireil),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'few' => q({0} biodan),
						'one' => q({0} bhiod),
						'other' => q({0} biod),
						'two' => q({0} bhiod),
					},
					# Core Unit Identifier
					'bit' => {
						'few' => q({0} biodan),
						'one' => q({0} bhiod),
						'other' => q({0} biod),
						'two' => q({0} bhiod),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0} baidhtean),
						'one' => q({0} bhaidht),
						'other' => q({0} baidht),
						'two' => q({0} bhaidht),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} baidhtean),
						'one' => q({0} bhaidht),
						'other' => q({0} baidht),
						'two' => q({0} bhaidht),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'few' => q({0} giga-biodan),
						'name' => q(giga-biod),
						'one' => q({0} ghiga-biod),
						'other' => q({0} giga-biod),
						'two' => q({0} ghiga-biod),
					},
					# Core Unit Identifier
					'gigabit' => {
						'few' => q({0} giga-biodan),
						'name' => q(giga-biod),
						'one' => q({0} ghiga-biod),
						'other' => q({0} giga-biod),
						'two' => q({0} ghiga-biod),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'few' => q({0} giga-baidhtean),
						'name' => q(giga-baidht),
						'one' => q({0} ghiga-baidht),
						'other' => q({0} giga-baidht),
						'two' => q({0} ghiga-baidht),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'few' => q({0} giga-baidhtean),
						'name' => q(giga-baidht),
						'one' => q({0} ghiga-baidht),
						'other' => q({0} giga-baidht),
						'two' => q({0} ghiga-baidht),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'few' => q({0} cilebiodan),
						'name' => q(cilebiod),
						'one' => q({0} chilebiod),
						'other' => q({0} cilebiod),
						'two' => q({0} chilebiod),
					},
					# Core Unit Identifier
					'kilobit' => {
						'few' => q({0} cilebiodan),
						'name' => q(cilebiod),
						'one' => q({0} chilebiod),
						'other' => q({0} cilebiod),
						'two' => q({0} chilebiod),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'few' => q({0} cileabaidhtean),
						'name' => q(cileabaidht),
						'one' => q({0} chileabaidht),
						'other' => q({0} cileabaidht),
						'two' => q({0} chileabaidht),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'few' => q({0} cileabaidhtean),
						'name' => q(cileabaidht),
						'one' => q({0} chileabaidht),
						'other' => q({0} cileabaidht),
						'two' => q({0} chileabaidht),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'few' => q({0} meaga-biodan),
						'name' => q(meaga-biod),
						'one' => q({0} mheaga-biod),
						'other' => q({0} meaga-biod),
						'two' => q({0} mheaga-biod),
					},
					# Core Unit Identifier
					'megabit' => {
						'few' => q({0} meaga-biodan),
						'name' => q(meaga-biod),
						'one' => q({0} mheaga-biod),
						'other' => q({0} meaga-biod),
						'two' => q({0} mheaga-biod),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'few' => q({0} meaga-baidhtean),
						'name' => q(meaga-baidht),
						'one' => q({0} mheaga-baidht),
						'other' => q({0} meaga-baidht),
						'two' => q({0} mheaga-baidht),
					},
					# Core Unit Identifier
					'megabyte' => {
						'few' => q({0} meaga-baidhtean),
						'name' => q(meaga-baidht),
						'one' => q({0} mheaga-baidht),
						'other' => q({0} meaga-baidht),
						'two' => q({0} mheaga-baidht),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'few' => q({0} peta-baidhtean),
						'name' => q(peta-baidht),
						'one' => q({0} pheta-baidht),
						'other' => q({0} peta-baidht),
						'two' => q({0} pheta-baidht),
					},
					# Core Unit Identifier
					'petabyte' => {
						'few' => q({0} peta-baidhtean),
						'name' => q(peta-baidht),
						'one' => q({0} pheta-baidht),
						'other' => q({0} peta-baidht),
						'two' => q({0} pheta-baidht),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'few' => q({0} tera-biodan),
						'name' => q(tera-biod),
						'one' => q({0} tera-biod),
						'other' => q({0} tera-biod),
						'two' => q({0} thera-biod),
					},
					# Core Unit Identifier
					'terabit' => {
						'few' => q({0} tera-biodan),
						'name' => q(tera-biod),
						'one' => q({0} tera-biod),
						'other' => q({0} tera-biod),
						'two' => q({0} thera-biod),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'few' => q({0} tera-baidhtean),
						'name' => q(tera-baidht),
						'one' => q({0} tera-baidht),
						'other' => q({0} tera-baidht),
						'two' => q({0} thera-baidht),
					},
					# Core Unit Identifier
					'terabyte' => {
						'few' => q({0} tera-baidhtean),
						'name' => q(tera-baidht),
						'one' => q({0} tera-baidht),
						'other' => q({0} tera-baidht),
						'two' => q({0} thera-baidht),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} linntean),
						'name' => q(linn),
						'one' => q({0} linn),
						'other' => q({0} linn),
						'two' => q({0} linn),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} linntean),
						'name' => q(linn),
						'one' => q({0} linn),
						'other' => q({0} linn),
						'two' => q({0} linn),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} làithean),
						'one' => q({0} latha),
						'other' => q({0} latha),
						'per' => q({0} san latha),
						'two' => q({0} latha),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} làithean),
						'one' => q({0} latha),
						'other' => q({0} latha),
						'per' => q({0} san latha),
						'two' => q({0} latha),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0} deicheadan),
						'name' => q(deichead),
						'one' => q({0} deichead),
						'other' => q({0} deichead),
						'two' => q({0} dheichead),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0} deicheadan),
						'name' => q(deichead),
						'one' => q({0} deichead),
						'other' => q({0} deichead),
						'two' => q({0} dheichead),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'few' => q({0} uairean a thìde),
						'name' => q(uair a thìde),
						'one' => q({0} uair a thìde),
						'other' => q({0} uair a thìde),
						'per' => q({0} san uair),
						'two' => q({0} uair a thìde),
					},
					# Core Unit Identifier
					'hour' => {
						'few' => q({0} uairean a thìde),
						'name' => q(uair a thìde),
						'one' => q({0} uair a thìde),
						'other' => q({0} uair a thìde),
						'per' => q({0} san uair),
						'two' => q({0} uair a thìde),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'few' => q({0} micreo-diogan),
						'name' => q(micreo-diog),
						'one' => q({0} mhicreo-diog),
						'other' => q({0} micreo-diog),
						'two' => q({0} mhicreo-diog),
					},
					# Core Unit Identifier
					'microsecond' => {
						'few' => q({0} micreo-diogan),
						'name' => q(micreo-diog),
						'one' => q({0} mhicreo-diog),
						'other' => q({0} micreo-diog),
						'two' => q({0} mhicreo-diog),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'few' => q({0} mili-diogan),
						'one' => q({0} mhili-diog),
						'other' => q({0} mili-diog),
						'two' => q({0} mhili-diog),
					},
					# Core Unit Identifier
					'millisecond' => {
						'few' => q({0} mili-diogan),
						'one' => q({0} mhili-diog),
						'other' => q({0} mili-diog),
						'two' => q({0} mhili-diog),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} mionaidean),
						'name' => q(mionaid),
						'one' => q({0} mhionaid),
						'other' => q({0} mionaid),
						'per' => q({0} sa mhionaid),
						'two' => q({0} mhionaid),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} mionaidean),
						'name' => q(mionaid),
						'one' => q({0} mhionaid),
						'other' => q({0} mionaid),
						'per' => q({0} sa mhionaid),
						'two' => q({0} mhionaid),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} mìosan),
						'one' => q({0} mhìos),
						'other' => q({0} mìos),
						'per' => q({0} sa mhìos),
						'two' => q({0} mhìos),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} mìosan),
						'one' => q({0} mhìos),
						'other' => q({0} mìos),
						'per' => q({0} sa mhìos),
						'two' => q({0} mhìos),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'few' => q({0} nano-diogan),
						'one' => q({0} nano-diog),
						'other' => q({0} nano-diog),
						'two' => q({0} nano-diog),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'few' => q({0} nano-diogan),
						'one' => q({0} nano-diog),
						'other' => q({0} nano-diog),
						'two' => q({0} nano-diog),
					},
					# Long Unit Identifier
					'duration-night' => {
						'few' => q({0} oidhcheannan),
						'name' => q(oidhche),
						'one' => q({0} oidhche),
						'other' => q({0} oidhche),
						'per' => q({0}/oidhche),
						'two' => q({0} oidhche),
					},
					# Core Unit Identifier
					'night' => {
						'few' => q({0} oidhcheannan),
						'name' => q(oidhche),
						'one' => q({0} oidhche),
						'other' => q({0} oidhche),
						'per' => q({0}/oidhche),
						'two' => q({0} oidhche),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} cairtealan),
						'name' => q(cairteal),
						'one' => q({0} chairteal),
						'other' => q({0} cairteal),
						'two' => q({0} chairteal),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} cairtealan),
						'name' => q(cairteal),
						'one' => q({0} chairteal),
						'other' => q({0} cairteal),
						'two' => q({0} chairteal),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} diogan),
						'one' => q({0} diog),
						'other' => q({0} diog),
						'per' => q({0} san diog),
						'two' => q({0} dhiog),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} diogan),
						'one' => q({0} diog),
						'other' => q({0} diog),
						'per' => q({0} san diog),
						'two' => q({0} dhiog),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} seachdainean),
						'name' => q(seachdain),
						'one' => q({0} seachdain),
						'other' => q({0} seachdain),
						'per' => q({0} san t-seachdain),
						'two' => q({0} sheachdain),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} seachdainean),
						'name' => q(seachdain),
						'one' => q({0} seachdain),
						'other' => q({0} seachdain),
						'per' => q({0} san t-seachdain),
						'two' => q({0} sheachdain),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} bliadhnaichean),
						'one' => q({0} bhliadhna),
						'other' => q({0} bliadhna),
						'per' => q({0} sa bhliadhna),
						'two' => q({0} bhliadhna),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} bliadhnaichean),
						'one' => q({0} bhliadhna),
						'other' => q({0} bliadhna),
						'per' => q({0} sa bhliadhna),
						'two' => q({0} bhliadhna),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'few' => q({0} ampère),
						'name' => q(ampère),
						'one' => q({0} ampère),
						'other' => q({0} ampère),
						'two' => q({0} ampère),
					},
					# Core Unit Identifier
					'ampere' => {
						'few' => q({0} ampère),
						'name' => q(ampère),
						'one' => q({0} ampère),
						'other' => q({0} ampère),
						'two' => q({0} ampère),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'few' => q({0} mille-ampère),
						'name' => q(mille-ampère),
						'one' => q({0} mhille-ampère),
						'other' => q({0} mille-ampère),
						'two' => q({0} mhille-ampère),
					},
					# Core Unit Identifier
					'milliampere' => {
						'few' => q({0} mille-ampère),
						'name' => q(mille-ampère),
						'one' => q({0} mhille-ampère),
						'other' => q({0} mille-ampère),
						'two' => q({0} mhille-ampère),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'few' => q({0} ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
						'two' => q({0} ohm),
					},
					# Core Unit Identifier
					'ohm' => {
						'few' => q({0} ohm),
						'one' => q({0} ohm),
						'other' => q({0} ohm),
						'two' => q({0} ohm),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'few' => q({0} volt),
						'one' => q({0} volt),
						'other' => q({0} volt),
						'two' => q({0} volt),
					},
					# Core Unit Identifier
					'volt' => {
						'few' => q({0} volt),
						'one' => q({0} volt),
						'other' => q({0} volt),
						'two' => q({0} volt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'few' => q({0} aonadan-teasa Breatannach),
						'one' => q({0} aonad-teasa Breatannach),
						'other' => q({0} aonad-teasa Breatannach),
						'two' => q({0} aonad-teasa Breatannach),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'few' => q({0} aonadan-teasa Breatannach),
						'one' => q({0} aonad-teasa Breatannach),
						'other' => q({0} aonad-teasa Breatannach),
						'two' => q({0} aonad-teasa Breatannach),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'few' => q({0} calaraidhean),
						'name' => q(calaraidh),
						'one' => q({0} chalaraidh),
						'other' => q({0} calaraidh),
						'two' => q({0} chalaraidh),
					},
					# Core Unit Identifier
					'calorie' => {
						'few' => q({0} calaraidhean),
						'name' => q(calaraidh),
						'one' => q({0} chalaraidh),
						'other' => q({0} calaraidh),
						'two' => q({0} chalaraidh),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'few' => q({0} voltaichean-eleactroin),
						'one' => q({0} volt-eleactroin),
						'other' => q({0} volt-eleactroin),
						'two' => q({0} volt-eleactroin),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'few' => q({0} voltaichean-eleactroin),
						'one' => q({0} volt-eleactroin),
						'other' => q({0} volt-eleactroin),
						'two' => q({0} volt-eleactroin),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} calaraidhean bidhe),
						'name' => q(calaraidh bidhe),
						'one' => q({0} chalaraidh bidhe),
						'other' => q({0} calaraidh bidhe),
						'two' => q({0} chalaraidh bidhe),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} calaraidhean bidhe),
						'name' => q(calaraidh bidhe),
						'one' => q({0} chalaraidh bidhe),
						'other' => q({0} calaraidh bidhe),
						'two' => q({0} chalaraidh bidhe),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'few' => q({0} joule),
						'one' => q({0} joule),
						'other' => q({0} joule),
						'two' => q({0} joule),
					},
					# Core Unit Identifier
					'joule' => {
						'few' => q({0} joule),
						'one' => q({0} joule),
						'other' => q({0} joule),
						'two' => q({0} joule),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'few' => q({0} cileacalaraidhean),
						'name' => q(cileacalaraidh),
						'one' => q({0} chileacalaraidh),
						'other' => q({0} cileacalaraidh),
						'two' => q({0} chileacalaraidh),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'few' => q({0} cileacalaraidhean),
						'name' => q(cileacalaraidh),
						'one' => q({0} chileacalaraidh),
						'other' => q({0} cileacalaraidh),
						'two' => q({0} chileacalaraidh),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'few' => q({0} cilea-joule),
						'one' => q({0} chilea-joule),
						'other' => q({0} cilea-joule),
						'two' => q({0} chilea-joule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'few' => q({0} cilea-joule),
						'one' => q({0} chilea-joule),
						'other' => q({0} cilea-joule),
						'two' => q({0} chilea-joule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'few' => q({0} cilea-watt-uair),
						'name' => q(cilea-watt-uair),
						'one' => q({0} chilea-watt-uair),
						'other' => q({0} cilea-watt-uair),
						'two' => q({0} chilea-watt-uair),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'few' => q({0} cilea-watt-uair),
						'name' => q(cilea-watt-uair),
						'one' => q({0} chilea-watt-uair),
						'other' => q({0} cilea-watt-uair),
						'two' => q({0} chilea-watt-uair),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'few' => q({0} aonadan-teasa nan SA),
						'one' => q({0} aonad-teasa nan SA),
						'other' => q({0} aonad-teasa nan SA),
						'two' => q({0} aonad-teasa nan SA),
					},
					# Core Unit Identifier
					'therm-us' => {
						'few' => q({0} aonadan-teasa nan SA),
						'one' => q({0} aonad-teasa nan SA),
						'other' => q({0} aonad-teasa nan SA),
						'two' => q({0} aonad-teasa nan SA),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} cilea-watt-uairean sa cheud chilemeatair),
						'name' => q(cilea-watt-uair sa cheud chilemeatair),
						'one' => q({0} chilea-watt-uair sa cheud chilemeatair),
						'other' => q({0} cilea-watt-uair sa cheud chilemeatair),
						'two' => q({0} chilea-watt-uair sa cheud chilemeatair),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'few' => q({0} cilea-watt-uairean sa cheud chilemeatair),
						'name' => q(cilea-watt-uair sa cheud chilemeatair),
						'one' => q({0} chilea-watt-uair sa cheud chilemeatair),
						'other' => q({0} cilea-watt-uair sa cheud chilemeatair),
						'two' => q({0} chilea-watt-uair sa cheud chilemeatair),
					},
					# Long Unit Identifier
					'force-newton' => {
						'few' => q({0} newtonaichean),
						'one' => q({0} newton),
						'other' => q({0} newton),
						'two' => q({0} newton),
					},
					# Core Unit Identifier
					'newton' => {
						'few' => q({0} newtonaichean),
						'one' => q({0} newton),
						'other' => q({0} newton),
						'two' => q({0} newton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'few' => q({0} puinnd de dh’fhorsa),
						'name' => q(punnd de dh’fhorsa),
						'one' => q({0} phunnd de dh’fhorsa),
						'other' => q({0} punnd de dh’fhorsa),
						'two' => q({0} phunnd de dh’fhorsa),
					},
					# Core Unit Identifier
					'pound-force' => {
						'few' => q({0} puinnd de dh’fhorsa),
						'name' => q(punnd de dh’fhorsa),
						'one' => q({0} phunnd de dh’fhorsa),
						'other' => q({0} punnd de dh’fhorsa),
						'two' => q({0} phunnd de dh’fhorsa),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'few' => q({0} giga-hertz),
						'name' => q(giga-hertz),
						'one' => q({0} ghiga-hertz),
						'other' => q({0} giga-hertz),
						'two' => q({0} ghiga-hertz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'few' => q({0} giga-hertz),
						'name' => q(giga-hertz),
						'one' => q({0} ghiga-hertz),
						'other' => q({0} giga-hertz),
						'two' => q({0} ghiga-hertz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'few' => q({0} hertz),
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
						'two' => q({0} hertz),
					},
					# Core Unit Identifier
					'hertz' => {
						'few' => q({0} hertz),
						'name' => q(hertz),
						'one' => q({0} hertz),
						'other' => q({0} hertz),
						'two' => q({0} hertz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'few' => q({0} cile-hertz),
						'name' => q(cile-hertz),
						'one' => q({0} chile-hertz),
						'other' => q({0} cile-hertz),
						'two' => q({0} chile-hertz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'few' => q({0} cile-hertz),
						'name' => q(cile-hertz),
						'one' => q({0} chile-hertz),
						'other' => q({0} cile-hertz),
						'two' => q({0} chile-hertz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'few' => q({0} meaga-hertz),
						'name' => q(meaga-hertz),
						'one' => q({0} mheaga-hertz),
						'other' => q({0} meaga-hertz),
						'two' => q({0} mheaga-hertz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'few' => q({0} meaga-hertz),
						'name' => q(meaga-hertz),
						'one' => q({0} mheaga-hertz),
						'other' => q({0} meaga-hertz),
						'two' => q({0} mheaga-hertz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'few' => q({0} dotagan),
						'one' => q({0} dotag),
						'other' => q({0} dotag),
						'two' => q({0} dhotag),
					},
					# Core Unit Identifier
					'dot' => {
						'few' => q({0} dotagan),
						'one' => q({0} dotag),
						'other' => q({0} dotag),
						'two' => q({0} dhotag),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} dotagan sa cheudameatair),
						'name' => q(dotag sa cheudameatair),
						'one' => q({0} dotag sa cheudameatair),
						'other' => q({0} dotag sa cheudameatair),
						'two' => q({0} dhotag sa cheudameatair),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} dotagan sa cheudameatair),
						'name' => q(dotag sa cheudameatair),
						'one' => q({0} dotag sa cheudameatair),
						'other' => q({0} dotag sa cheudameatair),
						'two' => q({0} dhotag sa cheudameatair),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} dotagan san òirleach),
						'name' => q(dotag san òirleach),
						'one' => q({0} dotag san òirleach),
						'other' => q({0} dotag san òirleach),
						'two' => q({0} dhotag san òirleach),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} dotagan san òirleach),
						'name' => q(dotag san òirleach),
						'one' => q({0} dotag san òirleach),
						'other' => q({0} dotag san òirleach),
						'two' => q({0} dhotag san òirleach),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(em chlò-ghrafach),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(em chlò-ghrafach),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'few' => q({0} meaga-piogsailean),
						'one' => q({0} mheaga-piogsail),
						'other' => q({0} meaga-piogsail),
						'two' => q({0} mheaga-piogsail),
					},
					# Core Unit Identifier
					'megapixel' => {
						'few' => q({0} meaga-piogsailean),
						'one' => q({0} mheaga-piogsail),
						'other' => q({0} meaga-piogsail),
						'two' => q({0} mheaga-piogsail),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'few' => q({0} piogsailean),
						'one' => q({0} phiogsail),
						'other' => q({0} piogsail),
						'two' => q({0} phiogsail),
					},
					# Core Unit Identifier
					'pixel' => {
						'few' => q({0} piogsailean),
						'one' => q({0} phiogsail),
						'other' => q({0} piogsail),
						'two' => q({0} phiogsail),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'few' => q({0} piogsailean sa cheudameatair),
						'name' => q(piogsail sa cheudameatair),
						'one' => q({0} phiogsail sa cheudameatair),
						'other' => q({0} piogsail sa cheudameatair),
						'two' => q({0} phiogsail sa cheudameatair),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'few' => q({0} piogsailean sa cheudameatair),
						'name' => q(piogsail sa cheudameatair),
						'one' => q({0} phiogsail sa cheudameatair),
						'other' => q({0} piogsail sa cheudameatair),
						'two' => q({0} phiogsail sa cheudameatair),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'few' => q({0} piogsailean san òirleach),
						'name' => q(piogsail san òirleach),
						'one' => q({0} phiogsail san òirleach),
						'other' => q({0} piogsail san òirleach),
						'two' => q({0} phiogsail san òirleach),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'few' => q({0} piogsailean san òirleach),
						'name' => q(piogsail san òirleach),
						'one' => q({0} phiogsail san òirleach),
						'other' => q({0} piogsail san òirleach),
						'two' => q({0} phiogsail san òirleach),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} aonadan reul-eòlach),
						'name' => q(aonad reul-eòlach),
						'one' => q({0} aonad reul-eòlach),
						'other' => q({0} aonad reul-eòlach),
						'two' => q({0} aonad reul-eòlach),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} aonadan reul-eòlach),
						'name' => q(aonad reul-eòlach),
						'one' => q({0} aonad reul-eòlach),
						'other' => q({0} aonad reul-eòlach),
						'two' => q({0} aonad reul-eòlach),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'few' => q({0} ceudameatairean),
						'name' => q(ceudameatair),
						'one' => q({0} cheudameatair),
						'other' => q({0} ceudameatair),
						'per' => q({0} sa cheudameatair),
						'two' => q({0} cheudameatair),
					},
					# Core Unit Identifier
					'centimeter' => {
						'few' => q({0} ceudameatairean),
						'name' => q(ceudameatair),
						'one' => q({0} cheudameatair),
						'other' => q({0} ceudameatair),
						'per' => q({0} sa cheudameatair),
						'two' => q({0} cheudameatair),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'few' => q({0} deicheamh-meatairean),
						'name' => q(deicheamh-meatair),
						'one' => q({0} deicheamh-meatair),
						'other' => q({0} deicheamh-meatair),
						'two' => q({0} dheicheamh-meatair),
					},
					# Core Unit Identifier
					'decimeter' => {
						'few' => q({0} deicheamh-meatairean),
						'name' => q(deicheamh-meatair),
						'one' => q({0} deicheamh-meatair),
						'other' => q({0} deicheamh-meatair),
						'two' => q({0} dheicheamh-meatair),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'few' => q({0} rèideasan-talmhainn),
						'name' => q(rèideas-talmhainn),
						'one' => q({0} rèideas-talmhainn),
						'other' => q({0} rèideas-talmhainn),
						'two' => q({0} rèideas-talmhainn),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'few' => q({0} rèideasan-talmhainn),
						'name' => q(rèideas-talmhainn),
						'one' => q({0} rèideas-talmhainn),
						'other' => q({0} rèideas-talmhainn),
						'two' => q({0} rèideas-talmhainn),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'few' => q({0} aitheamhan),
						'one' => q({0} aitheamh),
						'other' => q({0} aitheamh),
						'two' => q({0} aitheamh),
					},
					# Core Unit Identifier
					'fathom' => {
						'few' => q({0} aitheamhan),
						'one' => q({0} aitheamh),
						'other' => q({0} aitheamh),
						'two' => q({0} aitheamh),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0} troighean),
						'one' => q({0} troigh),
						'other' => q({0} troigh),
						'per' => q({0} san troigh),
						'two' => q({0} throigh),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0} troighean),
						'one' => q({0} troigh),
						'other' => q({0} troigh),
						'per' => q({0} san troigh),
						'two' => q({0} throigh),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'few' => q({0} stàidean Sasannach),
						'name' => q(stàid Shasannach),
						'one' => q({0} stàid Shasannach),
						'other' => q({0} stàid Shasannach),
						'two' => q({0} stàid Shasannach),
					},
					# Core Unit Identifier
					'furlong' => {
						'few' => q({0} stàidean Sasannach),
						'name' => q(stàid Shasannach),
						'one' => q({0} stàid Shasannach),
						'other' => q({0} stàid Shasannach),
						'two' => q({0} stàid Shasannach),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0} òirlich),
						'one' => q({0} òirleach),
						'other' => q({0} òirleach),
						'per' => q({0} san òirleach),
						'two' => q({0} òirleach),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0} òirlich),
						'one' => q({0} òirleach),
						'other' => q({0} òirleach),
						'per' => q({0} san òirleach),
						'two' => q({0} òirleach),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'few' => q({0} cilemeatairean),
						'name' => q(cilemeatair),
						'one' => q({0} chilemeatair),
						'other' => q({0} cilemeatair),
						'per' => q({0} sa chilemeatair),
						'two' => q({0} chilemeatair),
					},
					# Core Unit Identifier
					'kilometer' => {
						'few' => q({0} cilemeatairean),
						'name' => q(cilemeatair),
						'one' => q({0} chilemeatair),
						'other' => q({0} cilemeatair),
						'per' => q({0} sa chilemeatair),
						'two' => q({0} chilemeatair),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} bliadhnaichean solais),
						'name' => q(bliadhna solais),
						'one' => q({0} bhliadhna solais),
						'other' => q({0} bliadhna solais),
						'two' => q({0} bhliadhna solais),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} bliadhnaichean solais),
						'name' => q(bliadhna solais),
						'one' => q({0} bhliadhna solais),
						'other' => q({0} bliadhna solais),
						'two' => q({0} bhliadhna solais),
					},
					# Long Unit Identifier
					'length-meter' => {
						'few' => q({0} meatairean),
						'one' => q({0} mheatair),
						'other' => q({0} meatair),
						'per' => q({0} sa mheatair),
						'two' => q({0} mheatair),
					},
					# Core Unit Identifier
					'meter' => {
						'few' => q({0} meatairean),
						'one' => q({0} mheatair),
						'other' => q({0} meatair),
						'per' => q({0} sa mheatair),
						'two' => q({0} mheatair),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'few' => q({0} micreo-meatairean),
						'name' => q(micreo-meatair),
						'one' => q({0} mhicreo-meatair),
						'other' => q({0} micreo-meatair),
						'two' => q({0} mhicreo-meatair),
					},
					# Core Unit Identifier
					'micrometer' => {
						'few' => q({0} micreo-meatairean),
						'name' => q(micreo-meatair),
						'one' => q({0} mhicreo-meatair),
						'other' => q({0} micreo-meatair),
						'two' => q({0} mhicreo-meatair),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} mìltean),
						'one' => q({0} mhìle),
						'other' => q({0} mìle),
						'two' => q({0} mhìle),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} mìltean),
						'one' => q({0} mhìle),
						'other' => q({0} mìle),
						'two' => q({0} mhìle),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'few' => q({0} mìltean Lochlannach),
						'name' => q(mìle Lochlannach),
						'one' => q({0} mhìle Lochlannach),
						'other' => q({0} mìle Lochlannach),
						'two' => q({0} mhìle Lochlannach),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'few' => q({0} mìltean Lochlannach),
						'name' => q(mìle Lochlannach),
						'one' => q({0} mhìle Lochlannach),
						'other' => q({0} mìle Lochlannach),
						'two' => q({0} mhìle Lochlannach),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'few' => q({0} mili-meatairean),
						'name' => q(mili-meatair),
						'one' => q({0} mhili-meatair),
						'other' => q({0} mili-meatair),
						'two' => q({0} mhili-meatair),
					},
					# Core Unit Identifier
					'millimeter' => {
						'few' => q({0} mili-meatairean),
						'name' => q(mili-meatair),
						'one' => q({0} mhili-meatair),
						'other' => q({0} mili-meatair),
						'two' => q({0} mhili-meatair),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'few' => q({0} nano-meatairean),
						'name' => q(nano-meatair),
						'one' => q({0} nano-meatair),
						'other' => q({0} nano-meatair),
						'two' => q({0} nano-meatair),
					},
					# Core Unit Identifier
					'nanometer' => {
						'few' => q({0} nano-meatairean),
						'name' => q(nano-meatair),
						'one' => q({0} nano-meatair),
						'other' => q({0} nano-meatair),
						'two' => q({0} nano-meatair),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0} mìltean mara),
						'name' => q(mìle mara),
						'one' => q({0} mhìle mara),
						'other' => q({0} mìle mara),
						'two' => q({0} mhìle mara),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} mìltean mara),
						'name' => q(mìle mara),
						'one' => q({0} mhìle mara),
						'other' => q({0} mìle mara),
						'two' => q({0} mhìle mara),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'few' => q({0} parsec),
						'one' => q({0} pharsec),
						'other' => q({0} parsec),
						'two' => q({0} pharsec),
					},
					# Core Unit Identifier
					'parsec' => {
						'few' => q({0} parsec),
						'one' => q({0} pharsec),
						'other' => q({0} parsec),
						'two' => q({0} pharsec),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'few' => q({0} piceo-meatairean),
						'name' => q(piceo-meatair),
						'one' => q({0} phiceo-meatair),
						'other' => q({0} piceo-meatair),
						'two' => q({0} phiceo-meatair),
					},
					# Core Unit Identifier
					'picometer' => {
						'few' => q({0} piceo-meatairean),
						'name' => q(piceo-meatair),
						'one' => q({0} phiceo-meatair),
						'other' => q({0} piceo-meatair),
						'two' => q({0} phiceo-meatair),
					},
					# Long Unit Identifier
					'length-point' => {
						'few' => q({0} puingean),
						'one' => q({0} phuing),
						'other' => q({0} puing),
						'two' => q({0} phuing),
					},
					# Core Unit Identifier
					'point' => {
						'few' => q({0} puingean),
						'one' => q({0} phuing),
						'other' => q({0} puing),
						'two' => q({0} phuing),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'few' => q({0} rèideasan-grèine),
						'one' => q({0} rèideas-grèine),
						'other' => q({0} rèideas-grèine),
						'two' => q({0} rèideas-grèine),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'few' => q({0} rèideasan-grèine),
						'one' => q({0} rèideas-grèine),
						'other' => q({0} rèideas-grèine),
						'two' => q({0} rèideas-grèine),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} slatan),
						'one' => q({0} slat),
						'other' => q({0} slat),
						'two' => q({0} shlat),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} slatan),
						'one' => q({0} slat),
						'other' => q({0} slat),
						'two' => q({0} shlat),
					},
					# Long Unit Identifier
					'light-candela' => {
						'few' => q({0} candela),
						'one' => q({0} chandela),
						'other' => q({0} candela),
						'two' => q({0} chandela),
					},
					# Core Unit Identifier
					'candela' => {
						'few' => q({0} candela),
						'one' => q({0} chandela),
						'other' => q({0} candela),
						'two' => q({0} chandela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'few' => q({0} lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumen),
						'two' => q({0} lumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'few' => q({0} lumen),
						'one' => q({0} lumen),
						'other' => q({0} lumen),
						'two' => q({0} lumen),
					},
					# Long Unit Identifier
					'light-lux' => {
						'few' => q({0} lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
						'two' => q({0} lux),
					},
					# Core Unit Identifier
					'lux' => {
						'few' => q({0} lux),
						'one' => q({0} lux),
						'other' => q({0} lux),
						'two' => q({0} lux),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'few' => q({0} boillsgeachdan-grèine),
						'one' => q({0} bhoillsgeachd-ghrèine),
						'other' => q({0} boillsgeachd-ghrèine),
						'two' => q({0} bhoillsgeachd-ghrèine),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'few' => q({0} boillsgeachdan-grèine),
						'one' => q({0} bhoillsgeachd-ghrèine),
						'other' => q({0} boillsgeachd-ghrèine),
						'two' => q({0} bhoillsgeachd-ghrèine),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'few' => q({0} carataichean),
						'one' => q({0} charat),
						'other' => q({0} carat),
						'two' => q({0} charat),
					},
					# Core Unit Identifier
					'carat' => {
						'few' => q({0} carataichean),
						'one' => q({0} charat),
						'other' => q({0} carat),
						'two' => q({0} charat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'few' => q({0} daltonaichean),
						'one' => q({0} dalton),
						'other' => q({0} dalton),
						'two' => q({0} dhalton),
					},
					# Core Unit Identifier
					'dalton' => {
						'few' => q({0} daltonaichean),
						'one' => q({0} dalton),
						'other' => q({0} dalton),
						'two' => q({0} dhalton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'few' => q({0} tomadan-talmhainn),
						'one' => q({0} tomad-talmhainn),
						'other' => q({0} tomad-talmhainn),
						'two' => q({0} thomad-talmhainn),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'few' => q({0} tomadan-talmhainn),
						'one' => q({0} tomad-talmhainn),
						'other' => q({0} tomad-talmhainn),
						'two' => q({0} thomad-talmhainn),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} gràinnean),
						'one' => q({0} ghràinne),
						'other' => q({0} gràinne),
						'two' => q({0} gràinne),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} gràinnean),
						'one' => q({0} ghràinne),
						'other' => q({0} gràinne),
						'two' => q({0} gràinne),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'few' => q({0} gramaichean),
						'one' => q({0} ghram),
						'other' => q({0} gram),
						'per' => q({0} sa ghram),
						'two' => q({0} ghram),
					},
					# Core Unit Identifier
					'gram' => {
						'few' => q({0} gramaichean),
						'one' => q({0} ghram),
						'other' => q({0} gram),
						'per' => q({0} sa ghram),
						'two' => q({0} ghram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'few' => q({0} cileagramaichean),
						'name' => q(cileagram),
						'one' => q({0} chileagram),
						'other' => q({0} cileagram),
						'per' => q({0} sa chileagram),
						'two' => q({0} chileagram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'few' => q({0} cileagramaichean),
						'name' => q(cileagram),
						'one' => q({0} chileagram),
						'other' => q({0} cileagram),
						'per' => q({0} sa chileagram),
						'two' => q({0} chileagram),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'few' => q({0} micreo-gramaichean),
						'name' => q(micreo-gram),
						'one' => q({0} mhicreo-gram),
						'other' => q({0} micreo-gram),
						'two' => q({0} mhicreo-gram),
					},
					# Core Unit Identifier
					'microgram' => {
						'few' => q({0} micreo-gramaichean),
						'name' => q(micreo-gram),
						'one' => q({0} mhicreo-gram),
						'other' => q({0} micreo-gram),
						'two' => q({0} mhicreo-gram),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'few' => q({0} miligramaichean),
						'name' => q(miligram),
						'one' => q({0} mhiligram),
						'other' => q({0} miligram),
						'two' => q({0} mhiligram),
					},
					# Core Unit Identifier
					'milligram' => {
						'few' => q({0} miligramaichean),
						'name' => q(miligram),
						'one' => q({0} mhiligram),
						'other' => q({0} miligram),
						'two' => q({0} mhiligram),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'few' => q({0} unnsachan),
						'one' => q({0} unnsa),
						'other' => q({0} unnsa),
						'per' => q({0} san unnsa),
						'two' => q({0} unnsa),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0} unnsachan),
						'one' => q({0} unnsa),
						'other' => q({0} unnsa),
						'per' => q({0} san unnsa),
						'two' => q({0} unnsa),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'few' => q({0} unnsachan tròidh),
						'one' => q({0} unnsa tròidh),
						'other' => q({0} unnsa tròidh),
						'two' => q({0} unnsa tròidh),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'few' => q({0} unnsachan tròidh),
						'one' => q({0} unnsa tròidh),
						'other' => q({0} unnsa tròidh),
						'two' => q({0} unnsa tròidh),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0} puinnd),
						'one' => q({0} phunnd),
						'other' => q({0} punnd),
						'per' => q({0} sa phunnd),
						'two' => q({0} phunnd),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0} puinnd),
						'one' => q({0} phunnd),
						'other' => q({0} punnd),
						'per' => q({0} sa phunnd),
						'two' => q({0} phunnd),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'few' => q({0} tomadan-grèine),
						'one' => q({0} tomad-grèine),
						'other' => q({0} tomad-grèine),
						'two' => q({0} thomad-grèine),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'few' => q({0} tomadan-grèine),
						'one' => q({0} tomad-grèine),
						'other' => q({0} tomad-grèine),
						'two' => q({0} thomad-grèine),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'few' => q({0} clachan),
						'one' => q({0} chlach),
						'other' => q({0} clach),
						'two' => q({0} chlach),
					},
					# Core Unit Identifier
					'stone' => {
						'few' => q({0} clachan),
						'one' => q({0} chlach),
						'other' => q({0} clach),
						'two' => q({0} chlach),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0} tunnaichean),
						'one' => q({0} tunna),
						'other' => q({0} tunna),
						'two' => q({0} thunna),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} tunnaichean),
						'one' => q({0} tunna),
						'other' => q({0} tunna),
						'two' => q({0} thunna),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'few' => q({0} tunnaichean meatrach),
						'name' => q(tunna meatrach),
						'one' => q({0} tunna meatrach),
						'other' => q({0} tunna meatrach),
						'two' => q({0} thunna meatrach),
					},
					# Core Unit Identifier
					'tonne' => {
						'few' => q({0} tunnaichean meatrach),
						'name' => q(tunna meatrach),
						'one' => q({0} tunna meatrach),
						'other' => q({0} tunna meatrach),
						'two' => q({0} thunna meatrach),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} / {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} / {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'few' => q({0} giga-watt),
						'name' => q(giga-watt),
						'one' => q({0} ghiga-watt),
						'other' => q({0} giga-watt),
						'two' => q({0} ghiga-watt),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'few' => q({0} giga-watt),
						'name' => q(giga-watt),
						'one' => q({0} ghiga-watt),
						'other' => q({0} giga-watt),
						'two' => q({0} ghiga-watt),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} cumhachdan-eich),
						'name' => q(cumhachd-eich),
						'one' => q({0} chumhachd-eich),
						'other' => q({0} cumhachd-eich),
						'two' => q({0} chumhachd-eich),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} cumhachdan-eich),
						'name' => q(cumhachd-eich),
						'one' => q({0} chumhachd-eich),
						'other' => q({0} cumhachd-eich),
						'two' => q({0} chumhachd-eich),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'few' => q({0} cilea-watt),
						'name' => q(cilea-watt),
						'one' => q({0} chilea-watt),
						'other' => q({0} cilea-watt),
						'two' => q({0} chilea-watt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'few' => q({0} cilea-watt),
						'name' => q(cilea-watt),
						'one' => q({0} chilea-watt),
						'other' => q({0} cilea-watt),
						'two' => q({0} chilea-watt),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'few' => q({0} meaga-watt),
						'name' => q(meaga-watt),
						'one' => q({0} mheaga-watt),
						'other' => q({0} meaga-watt),
						'two' => q({0} mheaga-watt),
					},
					# Core Unit Identifier
					'megawatt' => {
						'few' => q({0} meaga-watt),
						'name' => q(meaga-watt),
						'one' => q({0} mheaga-watt),
						'other' => q({0} meaga-watt),
						'two' => q({0} mheaga-watt),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'few' => q({0} mili-watt),
						'name' => q(mili-watt),
						'one' => q({0} mhili-watt),
						'other' => q({0} mili-watt),
						'two' => q({0} mhili-watt),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'few' => q({0} mili-watt),
						'name' => q(mili-watt),
						'one' => q({0} mhili-watt),
						'other' => q({0} mili-watt),
						'two' => q({0} mhili-watt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'few' => q({0} watt),
						'one' => q({0} watt),
						'other' => q({0} watt),
						'two' => q({0} watt),
					},
					# Core Unit Identifier
					'watt' => {
						'few' => q({0} watt),
						'one' => q({0} watt),
						'other' => q({0} watt),
						'two' => q({0} watt),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q({0} ceàrnagach),
						'few' => q({0} ceàrnagach),
						'one' => q({0} ceàrnagach),
						'other' => q({0} ceàrnagach),
						'two' => q({0} ceàrnagach),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q({0} ceàrnagach),
						'few' => q({0} ceàrnagach),
						'one' => q({0} ceàrnagach),
						'other' => q({0} ceàrnagach),
						'two' => q({0} ceàrnagach),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q({0} ciùbach),
						'few' => q({0} ciùbach),
						'one' => q({0} ciùbach),
						'other' => q({0} ciùbach),
						'two' => q({0} ciùbach),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q({0} ciùbach),
						'few' => q({0} ciùbach),
						'one' => q({0} ciùbach),
						'other' => q({0} ciùbach),
						'two' => q({0} ciùbach),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'few' => q({0} brùthadh-àile),
						'name' => q(brùthadh-àile),
						'one' => q({0} bhrùthadh-àile),
						'other' => q({0} brùthadh-àile),
						'two' => q({0} bhrùthadh-àile),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'few' => q({0} brùthadh-àile),
						'name' => q(brùthadh-àile),
						'one' => q({0} bhrùthadh-àile),
						'other' => q({0} brùthadh-àile),
						'two' => q({0} bhrùthadh-àile),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'few' => q({0} bàraichean),
						'one' => q({0} bhar),
						'other' => q({0} bàr),
						'two' => q({0} bhàr),
					},
					# Core Unit Identifier
					'bar' => {
						'few' => q({0} bàraichean),
						'one' => q({0} bhar),
						'other' => q({0} bàr),
						'two' => q({0} bhàr),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'few' => q({0} heacta-pascal),
						'name' => q(heacta-pascal),
						'one' => q({0} heacta-pascal),
						'other' => q({0} heacta-pascal),
						'two' => q({0} heacta-pascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'few' => q({0} heacta-pascal),
						'name' => q(heacta-pascal),
						'one' => q({0} heacta-pascal),
						'other' => q({0} heacta-pascal),
						'two' => q({0} heacta-pascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0} òirlich de dh’airgead-beò),
						'name' => q(òirleach de dh’airgead-beò),
						'one' => q({0} òirleach de dh’airgead-beò),
						'other' => q({0} òirleach de dh’airgead-beò),
						'two' => q({0} òirleach de dh’airgead-beò),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} òirlich de dh’airgead-beò),
						'name' => q(òirleach de dh’airgead-beò),
						'one' => q({0} òirleach de dh’airgead-beò),
						'other' => q({0} òirleach de dh’airgead-beò),
						'two' => q({0} òirleach de dh’airgead-beò),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'few' => q({0} cileapascal),
						'name' => q(cileapascal),
						'one' => q({0} chileapascal),
						'other' => q({0} cileapascal),
						'two' => q({0} chileapascal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'few' => q({0} cileapascal),
						'name' => q(cileapascal),
						'one' => q({0} chileapascal),
						'other' => q({0} cileapascal),
						'two' => q({0} chileapascal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'few' => q({0} meaga-pascal),
						'name' => q(meaga-pascal),
						'one' => q({0} mheaga-pascal),
						'other' => q({0} meaga-pascal),
						'two' => q({0} mheaga-pascal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'few' => q({0} meaga-pascal),
						'name' => q(meaga-pascal),
						'one' => q({0} mheaga-pascal),
						'other' => q({0} meaga-pascal),
						'two' => q({0} mheaga-pascal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0} milibàraichean),
						'name' => q(milibàr),
						'one' => q({0} mhilibàr),
						'other' => q({0} milibàr),
						'two' => q({0} mhilibàr),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0} milibàraichean),
						'name' => q(milibàr),
						'one' => q({0} mhilibàr),
						'other' => q({0} milibàr),
						'two' => q({0} mhilibàr),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0} milimeatairean de dh’airgead-beò),
						'name' => q(milimeatair de dh’airgead-beò),
						'one' => q({0} mhilimeatair de dh’airgead-beò),
						'other' => q({0} milimeatair de dh’airgead-beò),
						'two' => q({0} mhilimeatair de dh’airgead-beò),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0} milimeatairean de dh’airgead-beò),
						'name' => q(milimeatair de dh’airgead-beò),
						'one' => q({0} mhilimeatair de dh’airgead-beò),
						'other' => q({0} milimeatair de dh’airgead-beò),
						'two' => q({0} mhilimeatair de dh’airgead-beò),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'few' => q({0} pascal),
						'name' => q(pascal),
						'one' => q({0} phascal),
						'other' => q({0} pascal),
						'two' => q({0} phascal),
					},
					# Core Unit Identifier
					'pascal' => {
						'few' => q({0} pascal),
						'name' => q(pascal),
						'one' => q({0} phascal),
						'other' => q({0} pascal),
						'two' => q({0} phascal),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0} puinnd san òirleach cheàrnagach),
						'name' => q(punnd san òirleach cheàrnagach),
						'one' => q({0} phunnd san òirleach cheàrnagach),
						'other' => q({0} punnd san òirleach cheàrnagach),
						'two' => q({0} phunnd san òirleach cheàrnagach),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0} puinnd san òirleach cheàrnagach),
						'name' => q(punnd san òirleach cheàrnagach),
						'one' => q({0} phunnd san òirleach cheàrnagach),
						'other' => q({0} punnd san òirleach cheàrnagach),
						'two' => q({0} phunnd san òirleach cheàrnagach),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q(Beaufort {0}),
						'name' => q(Beaufort),
						'one' => q(Beaufort {0}),
						'other' => q(Beaufort {0}),
						'two' => q(Beaufort {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q(Beaufort {0}),
						'name' => q(Beaufort),
						'one' => q(Beaufort {0}),
						'other' => q(Beaufort {0}),
						'two' => q(Beaufort {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'few' => q({0} cilemeatairean san uair),
						'name' => q(cilemeatair san uair),
						'one' => q({0} chilemeatair san uair),
						'other' => q({0} cilemeatair san uair),
						'two' => q({0} chilemeatair san uair),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'few' => q({0} cilemeatairean san uair),
						'name' => q(cilemeatair san uair),
						'one' => q({0} chilemeatair san uair),
						'other' => q({0} cilemeatair san uair),
						'two' => q({0} chilemeatair san uair),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0} mìltean mara san uair),
						'name' => q(mìle mara san uair),
						'one' => q({0} mhìle mara san uair),
						'other' => q({0} mìle mara san uair),
						'two' => q({0} mhìle mara san uair),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0} mìltean mara san uair),
						'name' => q(mìle mara san uair),
						'one' => q({0} mhìle mara san uair),
						'other' => q({0} mìle mara san uair),
						'two' => q({0} mhìle mara san uair),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'few' => q({0} solasan),
						'name' => q(solas),
						'one' => q({0} sholas),
						'other' => q({0} solas),
						'two' => q({0} sholas),
					},
					# Core Unit Identifier
					'light-speed' => {
						'few' => q({0} solasan),
						'name' => q(solas),
						'one' => q({0} sholas),
						'other' => q({0} solas),
						'two' => q({0} sholas),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'few' => q({0} meatairean san diog),
						'name' => q(meatair san diog),
						'one' => q({0} mheatair san diog),
						'other' => q({0} meatair san diog),
						'two' => q({0} mheatair san diog),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'few' => q({0} meatairean san diog),
						'name' => q(meatair san diog),
						'one' => q({0} mheatair san diog),
						'other' => q({0} meatair san diog),
						'two' => q({0} mheatair san diog),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} mìltean san uair),
						'name' => q(mìle san uair),
						'one' => q({0} mhìle san uair),
						'other' => q({0} mìle san uair),
						'two' => q({0} mhìle san uair),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} mìltean san uair),
						'name' => q(mìle san uair),
						'one' => q({0} mhìle san uair),
						'other' => q({0} mìle san uair),
						'two' => q({0} mhìle san uair),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'few' => q({0} ceuman Celsius),
						'name' => q(ceum Celsius),
						'one' => q({0} cheum Celsius),
						'other' => q({0} ceum Celsius),
						'two' => q({0} cheum Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'few' => q({0} ceuman Celsius),
						'name' => q(ceum Celsius),
						'one' => q({0} cheum Celsius),
						'other' => q({0} ceum Celsius),
						'two' => q({0} cheum Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0} ceuman Fahrenheit),
						'name' => q(ceum Fahrenheit),
						'one' => q({0} cheum Fahrenheit),
						'other' => q({0} ceum Fahrenheit),
						'two' => q({0} cheum Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0} ceuman Fahrenheit),
						'name' => q(ceum Fahrenheit),
						'one' => q({0} cheum Fahrenheit),
						'other' => q({0} ceum Fahrenheit),
						'two' => q({0} cheum Fahrenheit),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'few' => q({0} ceuman Kelvin),
						'name' => q(ceum Kelvin),
						'one' => q({0} cheum Kelvin),
						'other' => q({0} ceum Kelvin),
						'two' => q({0} cheum Kelvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'few' => q({0} ceuman Kelvin),
						'name' => q(ceum Kelvin),
						'one' => q({0} cheum Kelvin),
						'other' => q({0} ceum Kelvin),
						'two' => q({0} cheum Kelvin),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'few' => q({0} newton-mheatairean),
						'name' => q(newton-mheatair),
						'one' => q({0} newton-mheatair),
						'other' => q({0} newton-mheatair),
						'two' => q({0} newton-mheatair),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'few' => q({0} newton-mheatairean),
						'name' => q(newton-mheatair),
						'one' => q({0} newton-mheatair),
						'other' => q({0} newton-mheatair),
						'two' => q({0} newton-mheatair),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'few' => q({0} troighean-puinnd),
						'name' => q(troigh-phuinnd),
						'one' => q({0} troigh-phuinnd),
						'other' => q({0} troigh-phuinnd),
						'two' => q({0} throigh-phuinnd),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'few' => q({0} troighean-puinnd),
						'name' => q(troigh-phuinnd),
						'one' => q({0} troigh-phuinnd),
						'other' => q({0} troigh-phuinnd),
						'two' => q({0} throigh-phuinnd),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'few' => q({0} acair-throighean),
						'one' => q({0} acair-throigh),
						'other' => q({0} acair-throigh),
						'two' => q({0} acair-throigh),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'few' => q({0} acair-throighean),
						'one' => q({0} acair-throigh),
						'other' => q({0} acair-throigh),
						'two' => q({0} acair-throigh),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'few' => q({0} baraillean),
						'one' => q({0} bharaill),
						'other' => q({0} baraill),
						'two' => q({0} bharaill),
					},
					# Core Unit Identifier
					'barrel' => {
						'few' => q({0} baraillean),
						'one' => q({0} bharaill),
						'other' => q({0} baraill),
						'two' => q({0} bharaill),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'few' => q({0} buisealan),
						'one' => q({0} bhuiseal),
						'other' => q({0} buiseal),
						'two' => q({0} bhuiseal),
					},
					# Core Unit Identifier
					'bushel' => {
						'few' => q({0} buisealan),
						'one' => q({0} bhuiseal),
						'other' => q({0} buiseal),
						'two' => q({0} bhuiseal),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'few' => q({0} ceudailiotairean),
						'name' => q(ceudailiotair),
						'one' => q({0} cheudailiotair),
						'other' => q({0} ceudailiotair),
						'two' => q({0} cheudailiotair),
					},
					# Core Unit Identifier
					'centiliter' => {
						'few' => q({0} ceudailiotairean),
						'name' => q(ceudailiotair),
						'one' => q({0} cheudailiotair),
						'other' => q({0} ceudailiotair),
						'two' => q({0} cheudailiotair),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'few' => q({0} ceudameatairean ciùbach),
						'name' => q(ceudameatair ciùbach),
						'one' => q({0} cheudameatair ciùbach),
						'other' => q({0} ceudameatair ciùbach),
						'per' => q({0} sa cheudameatair chiùbach),
						'two' => q({0} cheudameatair ciùbach),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'few' => q({0} ceudameatairean ciùbach),
						'name' => q(ceudameatair ciùbach),
						'one' => q({0} cheudameatair ciùbach),
						'other' => q({0} ceudameatair ciùbach),
						'per' => q({0} sa cheudameatair chiùbach),
						'two' => q({0} cheudameatair ciùbach),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0} troighean ciùbach),
						'name' => q(troigh chiùbach),
						'one' => q({0} troigh chiùbach),
						'other' => q({0} troigh chiùbach),
						'two' => q({0} throigh chiùbach),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0} troighean ciùbach),
						'name' => q(troigh chiùbach),
						'one' => q({0} troigh chiùbach),
						'other' => q({0} troigh chiùbach),
						'two' => q({0} throigh chiùbach),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0} òirlich chiùbach),
						'name' => q(òirleach chiùbach),
						'one' => q({0} òirleach chiùbach),
						'other' => q({0} òirleach chiùbach),
						'two' => q({0} òirleach chiùbach),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0} òirlich chiùbach),
						'name' => q(òirleach chiùbach),
						'one' => q({0} òirleach chiùbach),
						'other' => q({0} òirleach chiùbach),
						'two' => q({0} òirleach chiùbach),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'few' => q({0} cilemeatairean ciùbach),
						'name' => q(cilemeatair ciùbach),
						'one' => q({0} chilemeatair ciùbach),
						'other' => q({0} cilemeatair ciùbach),
						'two' => q({0} chilemeatair ciùbach),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'few' => q({0} cilemeatairean ciùbach),
						'name' => q(cilemeatair ciùbach),
						'one' => q({0} chilemeatair ciùbach),
						'other' => q({0} cilemeatair ciùbach),
						'two' => q({0} chilemeatair ciùbach),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'few' => q({0} meatairean ciùbach),
						'name' => q(meatair ciùbach),
						'one' => q({0} mheatair ciùbach),
						'other' => q({0} meatair ciùbach),
						'per' => q({0} sa mheatair chiùbach),
						'two' => q({0} mheatair ciùbach),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'few' => q({0} meatairean ciùbach),
						'name' => q(meatair ciùbach),
						'one' => q({0} mheatair ciùbach),
						'other' => q({0} meatair ciùbach),
						'per' => q({0} sa mheatair chiùbach),
						'two' => q({0} mheatair ciùbach),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0} mìltean ciùbach),
						'name' => q(mìle chiùbach),
						'one' => q({0} mhìle chiùbach),
						'other' => q({0} mìle chiùbach),
						'two' => q({0} mhìle chiùbach),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0} mìltean ciùbach),
						'name' => q(mìle chiùbach),
						'one' => q({0} mhìle chiùbach),
						'other' => q({0} mìle chiùbach),
						'two' => q({0} mhìle chiùbach),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0} slatan ciùbach),
						'name' => q(slat chiùbach),
						'one' => q({0} slat chiùbach),
						'other' => q({0} slat chiùbach),
						'two' => q({0} shlat chiùbach),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0} slatan ciùbach),
						'name' => q(slat chiùbach),
						'one' => q({0} slat chiùbach),
						'other' => q({0} slat chiùbach),
						'two' => q({0} shlat chiùbach),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0} cupannan),
						'one' => q({0} chupa),
						'other' => q({0} cupa),
						'two' => q({0} chupa),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0} cupannan),
						'one' => q({0} chupa),
						'other' => q({0} cupa),
						'two' => q({0} chupa),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'few' => q({0} cupannan meatrach),
						'name' => q(cupa meatrach),
						'one' => q({0} chupa meatrach),
						'other' => q({0} cupa meatrach),
						'two' => q({0} chupa meatrach),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'few' => q({0} cupannan meatrach),
						'name' => q(cupa meatrach),
						'one' => q({0} chupa meatrach),
						'other' => q({0} cupa meatrach),
						'two' => q({0} chupa meatrach),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'few' => q({0} deicheamh-liotairean),
						'name' => q(deicheamh-liotair),
						'one' => q({0} deicheamh-liotair),
						'other' => q({0} deicheamh-liotair),
						'two' => q({0} dheicheamh-liotair),
					},
					# Core Unit Identifier
					'deciliter' => {
						'few' => q({0} deicheamh-liotairean),
						'name' => q(deicheamh-liotair),
						'one' => q({0} deicheamh-liotair),
						'other' => q({0} deicheamh-liotair),
						'two' => q({0} dheicheamh-liotair),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} spàinean-mìlsein),
						'name' => q(spàin-mhìlsein),
						'one' => q({0} spàin-mhìlsein),
						'other' => q({0} spàin-mhìlsein),
						'two' => q({0} spàin-mhìlsein),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} spàinean-mìlsein),
						'name' => q(spàin-mhìlsein),
						'one' => q({0} spàin-mhìlsein),
						'other' => q({0} spàin-mhìlsein),
						'two' => q({0} spàin-mhìlsein),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} spàinean-mìlsein ìmpireil),
						'name' => q(spàin-mhìlsein ìmpireil),
						'one' => q({0} spàin-mhìlsein ìmpireil),
						'other' => q({0} spàin-mhìlsein ìmpireil),
						'two' => q({0} spàin-mhìlsein ìmpireil),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} spàinean-mìlsein ìmpireil),
						'name' => q(spàin-mhìlsein ìmpireil),
						'one' => q({0} spàin-mhìlsein ìmpireil),
						'other' => q({0} spàin-mhìlsein ìmpireil),
						'two' => q({0} spàin-mhìlsein ìmpireil),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} dramaichean),
						'one' => q({0} drama),
						'other' => q({0} drama),
						'two' => q({0} dhrama),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} dramaichean),
						'one' => q({0} drama),
						'other' => q({0} drama),
						'two' => q({0} dhrama),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0} boinnean),
						'one' => q({0} bhoinne),
						'other' => q({0} boinne),
						'two' => q({0} bhoinne),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0} boinnean),
						'one' => q({0} bhoinne),
						'other' => q({0} boinne),
						'two' => q({0} bhoinne),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} unnsachan-dighe),
						'name' => q(unnsa-dighe),
						'one' => q({0} unnsa-dighe),
						'other' => q({0} unnsa-dighe),
						'two' => q({0} unnsa-dighe),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} unnsachan-dighe),
						'name' => q(unnsa-dighe),
						'one' => q({0} unnsa-dighe),
						'other' => q({0} unnsa-dighe),
						'two' => q({0} unnsa-dighe),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} unnsachan-dighe ìmpireil),
						'name' => q(unnsa-dighe ìmpireil),
						'one' => q({0} unnsa-dighe ìmpireil),
						'other' => q({0} unnsa-dighe ìmpireil),
						'two' => q({0} unnsa-dighe ìmpireil),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} unnsachan-dighe ìmpireil),
						'name' => q(unnsa-dighe ìmpireil),
						'one' => q({0} unnsa-dighe ìmpireil),
						'other' => q({0} unnsa-dighe ìmpireil),
						'two' => q({0} unnsa-dighe ìmpireil),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} galanan),
						'name' => q(galan),
						'one' => q({0} ghalan),
						'other' => q({0} galan),
						'per' => q({0} sa ghalan),
						'two' => q({0} ghalan),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} galanan),
						'name' => q(galan),
						'one' => q({0} ghalan),
						'other' => q({0} galan),
						'per' => q({0} sa ghalan),
						'two' => q({0} ghalan),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} galanan ìmpireil),
						'name' => q(galan ìmpireil),
						'one' => q({0} ghalan ìmpireil),
						'other' => q({0} galan ìmpireil),
						'per' => q({0} sa ghalan ìmpireil),
						'two' => q({0} ghalan ìmpireil),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} galanan ìmpireil),
						'name' => q(galan ìmpireil),
						'one' => q({0} ghalan ìmpireil),
						'other' => q({0} galan ìmpireil),
						'per' => q({0} sa ghalan ìmpireil),
						'two' => q({0} ghalan ìmpireil),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'few' => q({0} heacta-liotairean),
						'name' => q(heacta-liotair),
						'one' => q({0} heacta-liotair),
						'other' => q({0} heacta-liotair),
						'two' => q({0} heacta-liotair),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'few' => q({0} heacta-liotairean),
						'name' => q(heacta-liotair),
						'one' => q({0} heacta-liotair),
						'other' => q({0} heacta-liotair),
						'two' => q({0} heacta-liotair),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} sigirean),
						'one' => q({0} sigire),
						'other' => q({0} sigire),
						'two' => q({0} sigire),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} sigirean),
						'one' => q({0} sigire),
						'other' => q({0} sigire),
						'two' => q({0} sigire),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'few' => q({0} liotairean),
						'one' => q({0} liotair),
						'other' => q({0} liotair),
						'per' => q({0} san liotair),
						'two' => q({0} liotair),
					},
					# Core Unit Identifier
					'liter' => {
						'few' => q({0} liotairean),
						'one' => q({0} liotair),
						'other' => q({0} liotair),
						'per' => q({0} san liotair),
						'two' => q({0} liotair),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'few' => q({0} meaga-liotairean),
						'name' => q(meaga-liotair),
						'one' => q({0} mheaga-liotair),
						'other' => q({0} meaga-liotair),
						'two' => q({0} mheaga-liotair),
					},
					# Core Unit Identifier
					'megaliter' => {
						'few' => q({0} meaga-liotairean),
						'name' => q(meaga-liotair),
						'one' => q({0} mheaga-liotair),
						'other' => q({0} meaga-liotair),
						'two' => q({0} mheaga-liotair),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'few' => q({0} mililiotairean),
						'name' => q(mililiotair),
						'one' => q({0} mhililiotair),
						'other' => q({0} mililiotair),
						'two' => q({0} mhililiotair),
					},
					# Core Unit Identifier
					'milliliter' => {
						'few' => q({0} mililiotairean),
						'name' => q(mililiotair),
						'one' => q({0} mhililiotair),
						'other' => q({0} mililiotair),
						'two' => q({0} mhililiotair),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} crudhagain),
						'one' => q({0} chrudhagan),
						'other' => q({0} crudhagan),
						'two' => q({0} chrudhagan),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} crudhagain),
						'one' => q({0} chrudhagan),
						'other' => q({0} crudhagan),
						'two' => q({0} chrudhagan),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'few' => q({0} pinntean),
						'one' => q({0} phinnt),
						'other' => q({0} pinnt),
						'two' => q({0} phinnt),
					},
					# Core Unit Identifier
					'pint' => {
						'few' => q({0} pinntean),
						'one' => q({0} phinnt),
						'other' => q({0} pinnt),
						'two' => q({0} phinnt),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'few' => q({0} pinntean meatrach),
						'name' => q(pinnt meatrach),
						'one' => q({0} phinnt meatrach),
						'other' => q({0} pinnt meatrach),
						'two' => q({0} phinnt meatrach),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'few' => q({0} pinntean meatrach),
						'name' => q(pinnt meatrach),
						'one' => q({0} phinnt meatrach),
						'other' => q({0} pinnt meatrach),
						'two' => q({0} phinnt meatrach),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'few' => q({0} càrtan),
						'one' => q({0} chàrt),
						'other' => q({0} càrt),
						'two' => q({0} chàrt),
					},
					# Core Unit Identifier
					'quart' => {
						'few' => q({0} càrtan),
						'one' => q({0} chàrt),
						'other' => q({0} càrt),
						'two' => q({0} chàrt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} càrtan ìmpireil),
						'name' => q(càrt ìmpireil),
						'one' => q({0} chàrt ìmpireil),
						'other' => q({0} càrt ìmpireil),
						'two' => q({0} chàrt ìmpireil),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} càrtan ìmpireil),
						'name' => q(càrt ìmpireil),
						'one' => q({0} chàrt ìmpireil),
						'other' => q({0} càrt ìmpireil),
						'two' => q({0} chàrt ìmpireil),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} spàinean-bùird),
						'name' => q(spàin-bhùird),
						'one' => q({0} spàin-bhùird),
						'other' => q({0} spàin-bhùird),
						'two' => q({0} spàin-bhùird),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} spàinean-bùird),
						'name' => q(spàin-bhùird),
						'one' => q({0} spàin-bhùird),
						'other' => q({0} spàin-bhùird),
						'two' => q({0} spàin-bhùird),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} spàinean-teatha),
						'name' => q(spàin-teatha),
						'one' => q({0} spàin-teatha),
						'other' => q({0} spàin-teatha),
						'two' => q({0} spàin-teatha),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} spàinean-teatha),
						'name' => q(spàin-teatha),
						'one' => q({0} spàin-teatha),
						'other' => q({0} spàin-teatha),
						'two' => q({0} spàin-teatha),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'few' => q({0}G),
						'one' => q({0}G),
						'other' => q({0}G),
						'two' => q({0}G),
					},
					# Core Unit Identifier
					'g-force' => {
						'few' => q({0}G),
						'one' => q({0}G),
						'other' => q({0}G),
						'two' => q({0}G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'few' => q({0}m/s²),
						'name' => q(m/s²),
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
						'two' => q({0}m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'few' => q({0}m/s²),
						'name' => q(m/s²),
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
						'two' => q({0}m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(àrc-m),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(àrc-m),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(àrc-d),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(àrc-d),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'few' => q({0}rad),
						'name' => q(rad),
						'one' => q({0}rad),
						'other' => q({0}rad),
						'two' => q({0}rad),
					},
					# Core Unit Identifier
					'radian' => {
						'few' => q({0}rad),
						'name' => q(rad),
						'one' => q({0}rad),
						'other' => q({0}rad),
						'two' => q({0}rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0}cuairt),
						'one' => q({0}cuairt),
						'other' => q({0}cuairt),
						'two' => q({0}cuairt),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0}cuairt),
						'one' => q({0}cuairt),
						'other' => q({0}cuairt),
						'two' => q({0}cuairt),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0}ac),
						'one' => q({0}ac),
						'other' => q({0}ac),
						'two' => q({0}ac),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0}ac),
						'one' => q({0}ac),
						'other' => q({0}ac),
						'two' => q({0}ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0}dönüm),
						'one' => q({0}dönüm),
						'other' => q({0}dönüm),
						'two' => q({0}dhönüm),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0}dönüm),
						'one' => q({0}dönüm),
						'other' => q({0}dönüm),
						'two' => q({0}dhönüm),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'few' => q({0}ha),
						'one' => q({0}ha),
						'other' => q({0}ha),
						'two' => q({0}ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'few' => q({0}ha),
						'one' => q({0}ha),
						'other' => q({0}ha),
						'two' => q({0}ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'few' => q({0}cm²),
						'one' => q({0}cm²),
						'other' => q({0}cm²),
						'two' => q({0}cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'few' => q({0}cm²),
						'one' => q({0}cm²),
						'other' => q({0}cm²),
						'two' => q({0}cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0}ft²),
						'name' => q(ft²),
						'one' => q({0}ft²),
						'other' => q({0}ft²),
						'two' => q({0}ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0}ft²),
						'name' => q(ft²),
						'one' => q({0}ft²),
						'other' => q({0}ft²),
						'two' => q({0}ft²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0}in²),
						'name' => q(in²),
						'one' => q({0}in²),
						'other' => q({0}in²),
						'per' => q({0}/in²),
						'two' => q({0}in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0}in²),
						'name' => q(in²),
						'one' => q({0}in²),
						'other' => q({0}in²),
						'per' => q({0}/in²),
						'two' => q({0}in²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'few' => q({0}km²),
						'one' => q({0}km²),
						'other' => q({0}km²),
						'two' => q({0}km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'few' => q({0}km²),
						'one' => q({0}km²),
						'other' => q({0}km²),
						'two' => q({0}km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'few' => q({0}m²),
						'one' => q({0}m²),
						'other' => q({0}m²),
						'two' => q({0}m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'few' => q({0}m²),
						'one' => q({0}m²),
						'other' => q({0}m²),
						'two' => q({0}m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0}mì²),
						'name' => q(mì²),
						'one' => q({0}mì²),
						'other' => q({0}mì²),
						'two' => q({0}mì²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0}mì²),
						'name' => q(mì²),
						'one' => q({0}mì²),
						'other' => q({0}mì²),
						'two' => q({0}mì²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0}yd²),
						'one' => q({0}yd²),
						'other' => q({0}yd²),
						'two' => q({0}yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0}yd²),
						'one' => q({0}yd²),
						'other' => q({0}yd²),
						'two' => q({0}yd²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'few' => q({0}nith),
						'one' => q({0}nì),
						'other' => q({0}nì),
						'two' => q({0}nì),
					},
					# Core Unit Identifier
					'item' => {
						'few' => q({0}nith),
						'one' => q({0}nì),
						'other' => q({0}nì),
						'two' => q({0}nì),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'few' => q({0}kt),
						'one' => q({0}kt),
						'other' => q({0}kt),
						'two' => q({0}kt),
					},
					# Core Unit Identifier
					'karat' => {
						'few' => q({0}kt),
						'one' => q({0}kt),
						'other' => q({0}kt),
						'two' => q({0}kt),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0}mg/dL),
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
						'two' => q({0}mg/dL),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0}mg/dL),
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
						'two' => q({0}mg/dL),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'few' => q({0}mmòl/L),
						'one' => q({0}mmòl/L),
						'other' => q({0}mmòl/L),
						'two' => q({0}mmòl/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'few' => q({0}mmòl/L),
						'one' => q({0}mmòl/L),
						'other' => q({0}mmòl/L),
						'two' => q({0}mmòl/L),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'few' => q({0}mòl),
						'one' => q({0}mòl),
						'other' => q({0}mòl),
						'two' => q({0}mòl),
					},
					# Core Unit Identifier
					'mole' => {
						'few' => q({0}mòl),
						'one' => q({0}mòl),
						'other' => q({0}mòl),
						'two' => q({0}mòl),
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
					'concentr-permille' => {
						'name' => q(‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'few' => q({0}ppm),
						'one' => q({0}ppm),
						'other' => q({0}ppm),
						'two' => q({0}ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'few' => q({0}ppm),
						'one' => q({0}ppm),
						'other' => q({0}ppm),
						'two' => q({0}ppm),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(‱),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'few' => q({0}ppb),
						'one' => q({0}ppb),
						'other' => q({0}ppb),
						'two' => q({0}ppb),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'few' => q({0}ppb),
						'one' => q({0}ppb),
						'other' => q({0}ppb),
						'two' => q({0}ppb),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0}L/100km),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
						'two' => q({0}L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0}L/100km),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
						'two' => q({0}L/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0}L/km),
						'name' => q(L/km),
						'one' => q({0}L/km),
						'other' => q({0}L/km),
						'two' => q({0}L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0}L/km),
						'name' => q(L/km),
						'one' => q({0}L/km),
						'other' => q({0}L/km),
						'two' => q({0}L/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0}mì/g),
						'name' => q(mì/g),
						'one' => q({0}mì/g),
						'other' => q({0}mì/g),
						'two' => q({0}mì/g),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0}mì/g),
						'name' => q(mì/g),
						'one' => q({0}mì/g),
						'other' => q({0}mì/g),
						'two' => q({0}mì/g),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0}m/gRA),
						'name' => q(mìle/gal RA),
						'one' => q({0}m/gRA),
						'other' => q({0}m/gRA),
						'two' => q({0}m/gRA),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0}m/gRA),
						'name' => q(mìle/gal RA),
						'one' => q({0}m/gRA),
						'other' => q({0}m/gRA),
						'two' => q({0}m/gRA),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'few' => q({0}b),
						'one' => q({0}b),
						'other' => q({0}b),
						'two' => q({0}b),
					},
					# Core Unit Identifier
					'bit' => {
						'few' => q({0}b),
						'one' => q({0}b),
						'other' => q({0}b),
						'two' => q({0}b),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0}B),
						'one' => q({0}B),
						'other' => q({0}B),
						'two' => q({0}B),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0}B),
						'one' => q({0}B),
						'other' => q({0}B),
						'two' => q({0}B),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'few' => q({0}Gb),
						'one' => q({0}Gb),
						'other' => q({0}Gb),
						'two' => q({0}Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'few' => q({0}Gb),
						'one' => q({0}Gb),
						'other' => q({0}Gb),
						'two' => q({0}Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'few' => q({0}GB),
						'one' => q({0}GB),
						'other' => q({0}GB),
						'two' => q({0}GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'few' => q({0}GB),
						'one' => q({0}GB),
						'other' => q({0}GB),
						'two' => q({0}GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'few' => q({0}kb),
						'one' => q({0}kb),
						'other' => q({0}kb),
						'two' => q({0}kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'few' => q({0}kb),
						'one' => q({0}kb),
						'other' => q({0}kb),
						'two' => q({0}kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'few' => q({0}kB),
						'one' => q({0}kB),
						'other' => q({0}kB),
						'two' => q({0}kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'few' => q({0}kB),
						'one' => q({0}kB),
						'other' => q({0}kB),
						'two' => q({0}kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'few' => q({0}Mb),
						'one' => q({0}Mb),
						'other' => q({0}Mb),
						'two' => q({0}Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'few' => q({0}Mb),
						'one' => q({0}Mb),
						'other' => q({0}Mb),
						'two' => q({0}Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'few' => q({0}MB),
						'one' => q({0}MB),
						'other' => q({0}MB),
						'two' => q({0}MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'few' => q({0}MB),
						'one' => q({0}MB),
						'other' => q({0}MB),
						'two' => q({0}MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'few' => q({0}PB),
						'one' => q({0}PB),
						'other' => q({0}PB),
						'two' => q({0}PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'few' => q({0}PB),
						'one' => q({0}PB),
						'other' => q({0}PB),
						'two' => q({0}PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'few' => q({0}Tb),
						'one' => q({0}Tb),
						'other' => q({0}Tb),
						'two' => q({0}Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'few' => q({0}Tb),
						'one' => q({0}Tb),
						'other' => q({0}Tb),
						'two' => q({0}Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'few' => q({0}TB),
						'one' => q({0}TB),
						'other' => q({0}TB),
						'two' => q({0}TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'few' => q({0}TB),
						'one' => q({0}TB),
						'other' => q({0}TB),
						'two' => q({0}TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0}li),
						'one' => q({0}li),
						'other' => q({0}li),
						'two' => q({0}li),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0}li),
						'one' => q({0}li),
						'other' => q({0}li),
						'two' => q({0}li),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0}là),
						'name' => q(là),
						'one' => q({0}là),
						'other' => q({0}là),
						'two' => q({0}là),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0}là),
						'name' => q(là),
						'one' => q({0}là),
						'other' => q({0}là),
						'two' => q({0}là),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0}deich),
						'one' => q({0}deich),
						'other' => q({0}deich),
						'two' => q({0}dheich),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0}deich),
						'one' => q({0}deich),
						'other' => q({0}deich),
						'two' => q({0}dheich),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'few' => q({0}u),
						'one' => q({0}u),
						'other' => q({0}u),
						'per' => q({0}/u),
						'two' => q({0}u),
					},
					# Core Unit Identifier
					'hour' => {
						'few' => q({0}u),
						'one' => q({0}u),
						'other' => q({0}u),
						'per' => q({0}/u),
						'two' => q({0}u),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'few' => q({0}μs),
						'name' => q(μs),
						'one' => q({0}μs),
						'other' => q({0}μs),
						'two' => q({0}μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'few' => q({0}μs),
						'name' => q(μs),
						'one' => q({0}μs),
						'other' => q({0}μs),
						'two' => q({0}μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'few' => q({0}ms),
						'name' => q(ms),
						'one' => q({0}ms),
						'other' => q({0}ms),
						'two' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'few' => q({0}ms),
						'name' => q(ms),
						'one' => q({0}ms),
						'other' => q({0}ms),
						'two' => q({0}ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0}m),
						'one' => q({0}m),
						'other' => q({0}m),
						'two' => q({0}m),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0}m),
						'one' => q({0}m),
						'other' => q({0}m),
						'two' => q({0}m),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0}m),
						'one' => q({0}m),
						'other' => q({0}m),
						'two' => q({0}m),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0}m),
						'one' => q({0}m),
						'other' => q({0}m),
						'two' => q({0}m),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'few' => q({0}ns),
						'name' => q(ns),
						'one' => q({0}ns),
						'other' => q({0}ns),
						'two' => q({0}ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'few' => q({0}ns),
						'name' => q(ns),
						'one' => q({0}ns),
						'other' => q({0}ns),
						'two' => q({0}ns),
					},
					# Long Unit Identifier
					'duration-night' => {
						'few' => q({0}oidh.),
						'name' => q(oidhche),
						'one' => q({0}oidh.),
						'other' => q({0}oidh.),
						'per' => q({0}/oidh.),
						'two' => q({0}oidh.),
					},
					# Core Unit Identifier
					'night' => {
						'few' => q({0}oidh.),
						'name' => q(oidhche),
						'one' => q({0}oidh.),
						'other' => q({0}oidh.),
						'per' => q({0}/oidh.),
						'two' => q({0}oidh.),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0}c),
						'name' => q(c),
						'one' => q({0}c),
						'other' => q({0}c),
						'two' => q({0}c),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0}c),
						'name' => q(c),
						'one' => q({0}c),
						'other' => q({0}c),
						'two' => q({0}c),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0}d),
						'one' => q({0}d),
						'other' => q({0}d),
						'two' => q({0}d),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0}d),
						'one' => q({0}d),
						'other' => q({0}d),
						'two' => q({0}d),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0}s),
						'name' => q(s),
						'one' => q({0}s),
						'other' => q({0}s),
						'per' => q({0}/s),
						'two' => q({0}s),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0}s),
						'name' => q(s),
						'one' => q({0}s),
						'other' => q({0}s),
						'per' => q({0}/s),
						'two' => q({0}s),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0}bl),
						'name' => q(blia),
						'one' => q({0}bl),
						'other' => q({0}bl),
						'two' => q({0}bl),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0}bl),
						'name' => q(blia),
						'one' => q({0}bl),
						'other' => q({0}bl),
						'two' => q({0}bl),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'few' => q({0}A),
						'one' => q({0}A),
						'other' => q({0}A),
						'two' => q({0}A),
					},
					# Core Unit Identifier
					'ampere' => {
						'few' => q({0}A),
						'one' => q({0}A),
						'other' => q({0}A),
						'two' => q({0}A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'few' => q({0}mA),
						'name' => q(mA),
						'one' => q({0}mA),
						'other' => q({0}mA),
						'two' => q({0}mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'few' => q({0}mA),
						'name' => q(mA),
						'one' => q({0}mA),
						'other' => q({0}mA),
						'two' => q({0}mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'few' => q({0}Ω),
						'one' => q({0}Ω),
						'other' => q({0}Ω),
						'two' => q({0}Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'few' => q({0}Ω),
						'one' => q({0}Ω),
						'other' => q({0}Ω),
						'two' => q({0}Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'few' => q({0}V),
						'one' => q({0}V),
						'other' => q({0}V),
						'two' => q({0}V),
					},
					# Core Unit Identifier
					'volt' => {
						'few' => q({0}V),
						'one' => q({0}V),
						'other' => q({0}V),
						'two' => q({0}V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'few' => q({0}Btu),
						'name' => q(Btu),
						'one' => q({0}Btu),
						'other' => q({0}Btu),
						'two' => q({0}Btu),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'few' => q({0}Btu),
						'name' => q(Btu),
						'one' => q({0}Btu),
						'other' => q({0}Btu),
						'two' => q({0}Btu),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'few' => q({0}cal),
						'one' => q({0}cal),
						'other' => q({0}cal),
						'two' => q({0}cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'few' => q({0}cal),
						'one' => q({0}cal),
						'other' => q({0}cal),
						'two' => q({0}cal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'few' => q({0}eV),
						'name' => q(eV),
						'one' => q({0}eV),
						'other' => q({0}eV),
						'two' => q({0}eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'few' => q({0}eV),
						'name' => q(eV),
						'one' => q({0}eV),
						'other' => q({0}eV),
						'two' => q({0}eV),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0}Cal),
						'one' => q({0}Cal),
						'other' => q({0}Cal),
						'two' => q({0}Cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0}Cal),
						'one' => q({0}Cal),
						'other' => q({0}Cal),
						'two' => q({0}Cal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'few' => q({0}J),
						'one' => q({0}J),
						'other' => q({0}J),
						'two' => q({0}J),
					},
					# Core Unit Identifier
					'joule' => {
						'few' => q({0}J),
						'one' => q({0}J),
						'other' => q({0}J),
						'two' => q({0}J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'few' => q({0}kcal),
						'one' => q({0}kcal),
						'other' => q({0}kcal),
						'two' => q({0}kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'few' => q({0}kcal),
						'one' => q({0}kcal),
						'other' => q({0}kcal),
						'two' => q({0}kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'few' => q({0}kJ),
						'name' => q(kJ),
						'one' => q({0}kJ),
						'other' => q({0}kJ),
						'two' => q({0}kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'few' => q({0}kJ),
						'name' => q(kJ),
						'one' => q({0}kJ),
						'other' => q({0}kJ),
						'two' => q({0}kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'few' => q({0}kWh),
						'name' => q(kWh),
						'one' => q({0}kWh),
						'other' => q({0}kWh),
						'two' => q({0}kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'few' => q({0}kWh),
						'name' => q(kWh),
						'one' => q({0}kWh),
						'other' => q({0}kWh),
						'two' => q({0}kWh),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'few' => q({0}US therm),
						'name' => q(US therm),
						'one' => q({0}US therm),
						'other' => q({0}US therm),
						'two' => q({0}US therm),
					},
					# Core Unit Identifier
					'therm-us' => {
						'few' => q({0}US therm),
						'name' => q(US therm),
						'one' => q({0}US therm),
						'other' => q({0}US therm),
						'two' => q({0}US therm),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'few' => q({0}kWh/100km),
						'one' => q({0}kWh/100km),
						'other' => q({0}kWh/100km),
						'two' => q({0}kWh/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'few' => q({0}kWh/100km),
						'one' => q({0}kWh/100km),
						'other' => q({0}kWh/100km),
						'two' => q({0}kWh/100km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'few' => q({0}N),
						'name' => q(N),
						'one' => q({0}N),
						'other' => q({0}N),
						'two' => q({0}N),
					},
					# Core Unit Identifier
					'newton' => {
						'few' => q({0}N),
						'name' => q(N),
						'one' => q({0}N),
						'other' => q({0}N),
						'two' => q({0}N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'few' => q({0}lbf),
						'name' => q(lbf),
						'one' => q({0}lbf),
						'other' => q({0}lbf),
						'two' => q({0}lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'few' => q({0}lbf),
						'name' => q(lbf),
						'one' => q({0}lbf),
						'other' => q({0}lbf),
						'two' => q({0}lbf),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'few' => q({0}GHz),
						'one' => q({0}GHz),
						'other' => q({0}GHz),
						'two' => q({0}GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'few' => q({0}GHz),
						'one' => q({0}GHz),
						'other' => q({0}GHz),
						'two' => q({0}GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'few' => q({0}Hz),
						'one' => q({0}Hz),
						'other' => q({0}Hz),
						'two' => q({0}Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'few' => q({0}Hz),
						'one' => q({0}Hz),
						'other' => q({0}Hz),
						'two' => q({0}Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'few' => q({0}kHz),
						'one' => q({0}kHz),
						'other' => q({0}kHz),
						'two' => q({0}kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'few' => q({0}kHz),
						'one' => q({0}kHz),
						'other' => q({0}kHz),
						'two' => q({0}kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'few' => q({0}MHz),
						'one' => q({0}MHz),
						'other' => q({0}MHz),
						'two' => q({0}MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'few' => q({0}MHz),
						'one' => q({0}MHz),
						'other' => q({0}MHz),
						'two' => q({0}MHz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'few' => q({0}dot),
						'name' => q(dot),
						'one' => q({0}dot),
						'other' => q({0}dot),
						'two' => q({0}dhot),
					},
					# Core Unit Identifier
					'dot' => {
						'few' => q({0}dot),
						'name' => q(dot),
						'one' => q({0}dot),
						'other' => q({0}dot),
						'two' => q({0}dhot),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0}dpcm),
						'one' => q({0}dpcm),
						'other' => q({0}dpcm),
						'two' => q({0}dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0}dpcm),
						'one' => q({0}dpcm),
						'other' => q({0}dpcm),
						'two' => q({0}dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0}dpi),
						'one' => q({0}dpi),
						'other' => q({0}dpi),
						'two' => q({0}dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0}dpi),
						'one' => q({0}dpi),
						'other' => q({0}dpi),
						'two' => q({0}dpi),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'few' => q({0}em),
						'one' => q({0}em),
						'other' => q({0}em),
						'two' => q({0}em),
					},
					# Core Unit Identifier
					'em' => {
						'few' => q({0}em),
						'one' => q({0}em),
						'other' => q({0}em),
						'two' => q({0}em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'few' => q({0}MP),
						'name' => q(MP),
						'one' => q({0}MP),
						'other' => q({0}MP),
						'two' => q({0}MP),
					},
					# Core Unit Identifier
					'megapixel' => {
						'few' => q({0}MP),
						'name' => q(MP),
						'one' => q({0}MP),
						'other' => q({0}MP),
						'two' => q({0}MP),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'few' => q({0}px),
						'name' => q(px),
						'one' => q({0}px),
						'other' => q({0}px),
						'two' => q({0}px),
					},
					# Core Unit Identifier
					'pixel' => {
						'few' => q({0}px),
						'name' => q(px),
						'one' => q({0}px),
						'other' => q({0}px),
						'two' => q({0}px),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'few' => q({0}ppcm),
						'one' => q({0}ppcm),
						'other' => q({0}ppcm),
						'two' => q({0}ppcm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'few' => q({0}ppcm),
						'one' => q({0}ppcm),
						'other' => q({0}ppcm),
						'two' => q({0}ppcm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'few' => q({0}ppi),
						'one' => q({0}ppi),
						'other' => q({0}ppi),
						'two' => q({0}ppi),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'few' => q({0}ppi),
						'one' => q({0}ppi),
						'other' => q({0}ppi),
						'two' => q({0}ppi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0}au),
						'one' => q({0}au),
						'other' => q({0}au),
						'two' => q({0}au),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0}au),
						'one' => q({0}au),
						'other' => q({0}au),
						'two' => q({0}au),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'few' => q({0}cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
						'two' => q({0}cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'few' => q({0}cm),
						'one' => q({0}cm),
						'other' => q({0}cm),
						'two' => q({0}cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'few' => q({0}dm),
						'one' => q({0}dm),
						'other' => q({0}dm),
						'two' => q({0}dm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'few' => q({0}dm),
						'one' => q({0}dm),
						'other' => q({0}dm),
						'two' => q({0}dm),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'few' => q({0}R⊕),
						'one' => q({0}R⊕),
						'other' => q({0}R⊕),
						'two' => q({0}R⊕),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'few' => q({0}R⊕),
						'one' => q({0}R⊕),
						'other' => q({0}R⊕),
						'two' => q({0}R⊕),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'few' => q({0}aith),
						'one' => q({0}aith),
						'other' => q({0}aith),
						'two' => q({0}aith),
					},
					# Core Unit Identifier
					'fathom' => {
						'few' => q({0}aith),
						'one' => q({0}aith),
						'other' => q({0}aith),
						'two' => q({0}aith),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
						'two' => q({0}′),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
						'two' => q({0}′),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'few' => q({0}stàid),
						'one' => q({0}stàid),
						'other' => q({0}stàid),
						'two' => q({0}stàid),
					},
					# Core Unit Identifier
					'furlong' => {
						'few' => q({0}stàid),
						'one' => q({0}stàid),
						'other' => q({0}stàid),
						'two' => q({0}stàid),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0}″),
						'name' => q(òirl),
						'one' => q({0}″),
						'other' => q({0}″),
						'two' => q({0}″),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0}″),
						'name' => q(òirl),
						'one' => q({0}″),
						'other' => q({0}″),
						'two' => q({0}″),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'few' => q({0}km),
						'one' => q({0}km),
						'other' => q({0}km),
						'two' => q({0}km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'few' => q({0}km),
						'one' => q({0}km),
						'other' => q({0}km),
						'two' => q({0}km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0}ly),
						'one' => q({0}ly),
						'other' => q({0}ly),
						'two' => q({0}ly),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0}ly),
						'one' => q({0}ly),
						'other' => q({0}ly),
						'two' => q({0}ly),
					},
					# Long Unit Identifier
					'length-meter' => {
						'few' => q({0}m),
						'one' => q({0}m),
						'other' => q({0}m),
						'two' => q({0}m),
					},
					# Core Unit Identifier
					'meter' => {
						'few' => q({0}m),
						'one' => q({0}m),
						'other' => q({0}m),
						'two' => q({0}m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'few' => q({0}μm),
						'name' => q(μm),
						'one' => q({0}μm),
						'other' => q({0}μm),
						'two' => q({0}μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'few' => q({0}μm),
						'name' => q(μm),
						'one' => q({0}μm),
						'other' => q({0}μm),
						'two' => q({0}μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0}mì),
						'name' => q(mì),
						'one' => q({0}mì),
						'other' => q({0}mì),
						'two' => q({0}mì),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0}mì),
						'name' => q(mì),
						'one' => q({0}mì),
						'other' => q({0}mì),
						'two' => q({0}mì),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'few' => q({0}smi),
						'one' => q({0}smi),
						'other' => q({0}smi),
						'two' => q({0}smi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'few' => q({0}smi),
						'one' => q({0}smi),
						'other' => q({0}smi),
						'two' => q({0}smi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'few' => q({0}mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
						'two' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'few' => q({0}mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
						'two' => q({0}mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'few' => q({0}nm),
						'one' => q({0}nm),
						'other' => q({0}nm),
						'two' => q({0}nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'few' => q({0}nm),
						'one' => q({0}nm),
						'other' => q({0}nm),
						'two' => q({0}nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0}nmi),
						'one' => q({0}nmi),
						'other' => q({0}nmi),
						'two' => q({0}nmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0}nmi),
						'one' => q({0}nmi),
						'other' => q({0}nmi),
						'two' => q({0}nmi),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'few' => q({0}pc),
						'one' => q({0}pc),
						'other' => q({0}pc),
						'two' => q({0}pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'few' => q({0}pc),
						'one' => q({0}pc),
						'other' => q({0}pc),
						'two' => q({0}pc),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'few' => q({0}pm),
						'one' => q({0}pm),
						'other' => q({0}pm),
						'two' => q({0}pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'few' => q({0}pm),
						'one' => q({0}pm),
						'other' => q({0}pm),
						'two' => q({0}pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'few' => q({0}pt),
						'name' => q(pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
						'two' => q({0}pt),
					},
					# Core Unit Identifier
					'point' => {
						'few' => q({0}pt),
						'name' => q(pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
						'two' => q({0}pt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'few' => q({0}R☉),
						'name' => q(R☉),
						'one' => q({0}R☉),
						'other' => q({0}R☉),
						'two' => q({0}R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'few' => q({0}R☉),
						'name' => q(R☉),
						'one' => q({0}R☉),
						'other' => q({0}R☉),
						'two' => q({0}R☉),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0}yd),
						'one' => q({0}yd),
						'other' => q({0}yd),
						'two' => q({0}yd),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0}yd),
						'one' => q({0}yd),
						'other' => q({0}yd),
						'two' => q({0}yd),
					},
					# Long Unit Identifier
					'light-candela' => {
						'few' => q({0}cd),
						'name' => q(cd),
						'one' => q({0}cd),
						'other' => q({0}cd),
						'two' => q({0}cd),
					},
					# Core Unit Identifier
					'candela' => {
						'few' => q({0}cd),
						'name' => q(cd),
						'one' => q({0}cd),
						'other' => q({0}cd),
						'two' => q({0}cd),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'few' => q({0}lm),
						'name' => q(lm),
						'one' => q({0}lm),
						'other' => q({0}lm),
						'two' => q({0}lm),
					},
					# Core Unit Identifier
					'lumen' => {
						'few' => q({0}lm),
						'name' => q(lm),
						'one' => q({0}lm),
						'other' => q({0}lm),
						'two' => q({0}lm),
					},
					# Long Unit Identifier
					'light-lux' => {
						'few' => q({0}lx),
						'one' => q({0}lx),
						'other' => q({0}lx),
						'two' => q({0}lx),
					},
					# Core Unit Identifier
					'lux' => {
						'few' => q({0}lx),
						'one' => q({0}lx),
						'other' => q({0}lx),
						'two' => q({0}lx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'few' => q({0}L☉),
						'name' => q(L☉),
						'one' => q({0}L☉),
						'other' => q({0}L☉),
						'two' => q({0}L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'few' => q({0}L☉),
						'name' => q(L☉),
						'one' => q({0}L☉),
						'other' => q({0}L☉),
						'two' => q({0}L☉),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'few' => q({0}CD),
						'one' => q({0}CD),
						'other' => q({0}CD),
						'two' => q({0}CD),
					},
					# Core Unit Identifier
					'carat' => {
						'few' => q({0}CD),
						'one' => q({0}CD),
						'other' => q({0}CD),
						'two' => q({0}CD),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'few' => q({0}Da),
						'name' => q(Da),
						'one' => q({0}Da),
						'other' => q({0}Da),
						'two' => q({0}Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'few' => q({0}Da),
						'name' => q(Da),
						'one' => q({0}Da),
						'other' => q({0}Da),
						'two' => q({0}Da),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'few' => q({0}M⊕),
						'name' => q(M⊕),
						'one' => q({0}M⊕),
						'other' => q({0}M⊕),
						'two' => q({0}M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'few' => q({0}M⊕),
						'name' => q(M⊕),
						'one' => q({0}M⊕),
						'other' => q({0}M⊕),
						'two' => q({0}M⊕),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0}gr),
						'one' => q({0}ghr),
						'other' => q({0}gr),
						'two' => q({0}ghr),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0}gr),
						'one' => q({0}ghr),
						'other' => q({0}gr),
						'two' => q({0}ghr),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'few' => q({0}g),
						'one' => q({0}g),
						'other' => q({0}g),
						'two' => q({0}g),
					},
					# Core Unit Identifier
					'gram' => {
						'few' => q({0}g),
						'one' => q({0}g),
						'other' => q({0}g),
						'two' => q({0}g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'few' => q({0}kg),
						'one' => q({0}kg),
						'other' => q({0}kg),
						'two' => q({0}kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'few' => q({0}kg),
						'one' => q({0}kg),
						'other' => q({0}kg),
						'two' => q({0}kg),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'few' => q({0}μg),
						'one' => q({0}μg),
						'other' => q({0}μg),
						'two' => q({0}μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'few' => q({0}μg),
						'one' => q({0}μg),
						'other' => q({0}μg),
						'two' => q({0}μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'few' => q({0}mg),
						'one' => q({0}mg),
						'other' => q({0}mg),
						'two' => q({0}mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'few' => q({0}mg),
						'one' => q({0}mg),
						'other' => q({0}mg),
						'two' => q({0}mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'few' => q({0}oz),
						'name' => q(oz),
						'one' => q({0}oz),
						'other' => q({0}oz),
						'two' => q({0}oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0}oz),
						'name' => q(oz),
						'one' => q({0}oz),
						'other' => q({0}oz),
						'two' => q({0}oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'few' => q({0}oz t),
						'name' => q(oz t),
						'one' => q({0}oz t),
						'other' => q({0}oz t),
						'two' => q({0}oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'few' => q({0}oz t),
						'name' => q(oz t),
						'one' => q({0}oz t),
						'other' => q({0}oz t),
						'two' => q({0}oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0}lb),
						'name' => q(lb),
						'one' => q({0}lb),
						'other' => q({0}lb),
						'two' => q({0}lb),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0}lb),
						'name' => q(lb),
						'one' => q({0}lb),
						'other' => q({0}lb),
						'two' => q({0}lb),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'few' => q({0}M☉),
						'name' => q(M☉),
						'one' => q({0}M☉),
						'other' => q({0}M☉),
						'two' => q({0}M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'few' => q({0}M☉),
						'name' => q(M☉),
						'one' => q({0}M☉),
						'other' => q({0}M☉),
						'two' => q({0}M☉),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'few' => q({0}clach),
						'one' => q({0}clach),
						'other' => q({0}clach),
						'two' => q({0}clach),
					},
					# Core Unit Identifier
					'stone' => {
						'few' => q({0}clach),
						'one' => q({0}clach),
						'other' => q({0}clach),
						'two' => q({0}clach),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0}tn),
						'name' => q(tn),
						'one' => q({0}tn),
						'other' => q({0}tn),
						'two' => q({0}tn),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0}tn),
						'name' => q(tn),
						'one' => q({0}tn),
						'other' => q({0}tn),
						'two' => q({0}tn),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'few' => q({0}t),
						'one' => q({0}t),
						'other' => q({0}t),
						'two' => q({0}t),
					},
					# Core Unit Identifier
					'tonne' => {
						'few' => q({0}t),
						'one' => q({0}t),
						'other' => q({0}t),
						'two' => q({0}t),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'few' => q({0}GW),
						'one' => q({0}GW),
						'other' => q({0}GW),
						'two' => q({0}GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'few' => q({0}GW),
						'one' => q({0}GW),
						'other' => q({0}GW),
						'two' => q({0}GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0}hp),
						'one' => q({0}hp),
						'other' => q({0}hp),
						'two' => q({0}hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0}hp),
						'one' => q({0}hp),
						'other' => q({0}hp),
						'two' => q({0}hp),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'few' => q({0}kW),
						'one' => q({0}kW),
						'other' => q({0}kW),
						'two' => q({0}kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'few' => q({0}kW),
						'one' => q({0}kW),
						'other' => q({0}kW),
						'two' => q({0}kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'few' => q({0}MW),
						'one' => q({0}MW),
						'other' => q({0}MW),
						'two' => q({0}MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'few' => q({0}MW),
						'one' => q({0}MW),
						'other' => q({0}MW),
						'two' => q({0}MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'few' => q({0}mW),
						'one' => q({0}mW),
						'other' => q({0}mW),
						'two' => q({0}mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'few' => q({0}mW),
						'one' => q({0}mW),
						'other' => q({0}mW),
						'two' => q({0}mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'few' => q({0}W),
						'one' => q({0}W),
						'other' => q({0}W),
						'two' => q({0}W),
					},
					# Core Unit Identifier
					'watt' => {
						'few' => q({0}W),
						'one' => q({0}W),
						'other' => q({0}W),
						'two' => q({0}W),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'few' => q({0}atm),
						'name' => q(atm),
						'one' => q({0}atm),
						'other' => q({0}atm),
						'two' => q({0}atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'few' => q({0}atm),
						'name' => q(atm),
						'one' => q({0}atm),
						'other' => q({0}atm),
						'two' => q({0}atm),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'few' => q({0}bàr),
						'one' => q({0}bhàr),
						'other' => q({0}bàr),
						'two' => q({0}bhàr),
					},
					# Core Unit Identifier
					'bar' => {
						'few' => q({0}bàr),
						'one' => q({0}bhàr),
						'other' => q({0}bàr),
						'two' => q({0}bhàr),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'few' => q({0}hPa),
						'one' => q({0}hPa),
						'other' => q({0}hPa),
						'two' => q({0}hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'few' => q({0}hPa),
						'one' => q({0}hPa),
						'other' => q({0}hPa),
						'two' => q({0}hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0}″ Hg),
						'name' => q(″ Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
						'two' => q({0}″ Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0}″ Hg),
						'name' => q(″ Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
						'two' => q({0}″ Hg),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'few' => q({0}kPa),
						'one' => q({0}kPa),
						'other' => q({0}kPa),
						'two' => q({0}kPa),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'few' => q({0}kPa),
						'one' => q({0}kPa),
						'other' => q({0}kPa),
						'two' => q({0}kPa),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'few' => q({0}MPa),
						'one' => q({0}MPa),
						'other' => q({0}MPa),
						'two' => q({0}MPa),
					},
					# Core Unit Identifier
					'megapascal' => {
						'few' => q({0}MPa),
						'one' => q({0}MPa),
						'other' => q({0}MPa),
						'two' => q({0}MPa),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0}mb),
						'one' => q({0}mb),
						'other' => q({0}mb),
						'two' => q({0}mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0}mb),
						'one' => q({0}mb),
						'other' => q({0}mb),
						'two' => q({0}mb),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0}mm Hg),
						'one' => q({0}mm Hg),
						'other' => q({0}mm Hg),
						'two' => q({0}mm Hg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0}mm Hg),
						'one' => q({0}mm Hg),
						'other' => q({0}mm Hg),
						'two' => q({0}mm Hg),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'few' => q({0}Pa),
						'one' => q({0}Pa),
						'other' => q({0}Pa),
						'two' => q({0}Pa),
					},
					# Core Unit Identifier
					'pascal' => {
						'few' => q({0}Pa),
						'one' => q({0}Pa),
						'other' => q({0}Pa),
						'two' => q({0}Pa),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0}psi),
						'one' => q({0}psi),
						'other' => q({0}psi),
						'two' => q({0}psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0}psi),
						'one' => q({0}psi),
						'other' => q({0}psi),
						'two' => q({0}psi),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q(B{0}),
						'one' => q(B{0}),
						'other' => q(B{0}),
						'two' => q(B{0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q(B{0}),
						'one' => q(B{0}),
						'other' => q(B{0}),
						'two' => q(B{0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'few' => q({0}km/h),
						'name' => q(km/h),
						'one' => q({0}km/h),
						'other' => q({0}km/h),
						'two' => q({0}km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'few' => q({0}km/h),
						'name' => q(km/h),
						'one' => q({0}km/h),
						'other' => q({0}km/h),
						'two' => q({0}km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0}kn),
						'one' => q({0}kn),
						'other' => q({0}kn),
						'two' => q({0}kn),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0}kn),
						'one' => q({0}kn),
						'other' => q({0}kn),
						'two' => q({0}kn),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'few' => q({0}solas.),
						'name' => q(solas),
						'one' => q({0}sholas),
						'other' => q({0}solas),
						'two' => q({0}sholas),
					},
					# Core Unit Identifier
					'light-speed' => {
						'few' => q({0}solas.),
						'name' => q(solas),
						'one' => q({0}sholas),
						'other' => q({0}solas),
						'two' => q({0}sholas),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'few' => q({0}m/s),
						'name' => q(m/s),
						'one' => q({0}m/s),
						'other' => q({0}m/s),
						'two' => q({0}m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'few' => q({0}m/s),
						'name' => q(m/s),
						'one' => q({0}m/s),
						'other' => q({0}m/s),
						'two' => q({0}m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0}mì/h),
						'name' => q(mì/h),
						'one' => q({0}mì/h),
						'other' => q({0}mì/h),
						'two' => q({0}mì/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0}mì/h),
						'name' => q(mì/h),
						'one' => q({0}mì/h),
						'other' => q({0}mì/h),
						'two' => q({0}mì/h),
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
					'temperature-fahrenheit' => {
						'name' => q(°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(°F),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'few' => q({0}K),
						'one' => q({0}K),
						'other' => q({0}K),
						'two' => q({0}K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'few' => q({0}K),
						'one' => q({0}K),
						'other' => q({0}K),
						'two' => q({0}K),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'few' => q({0}N⋅m),
						'one' => q({0}N⋅m),
						'other' => q({0}N⋅m),
						'two' => q({0}N⋅m),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'few' => q({0}N⋅m),
						'one' => q({0}N⋅m),
						'other' => q({0}N⋅m),
						'two' => q({0}N⋅m),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'few' => q({0}lbf⋅ft),
						'one' => q({0}lbf⋅ft),
						'other' => q({0}lbf⋅ft),
						'two' => q({0}lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'few' => q({0}lbf⋅ft),
						'one' => q({0}lbf⋅ft),
						'other' => q({0}lbf⋅ft),
						'two' => q({0}lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'few' => q({0}ac ft),
						'name' => q(ac ft),
						'one' => q({0}ac ft),
						'other' => q({0}ac ft),
						'two' => q({0}ac ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'few' => q({0}ac ft),
						'name' => q(ac ft),
						'one' => q({0}ac ft),
						'other' => q({0}ac ft),
						'two' => q({0}ac ft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'few' => q({0}bbl),
						'name' => q(bbl),
						'one' => q({0}bbl),
						'other' => q({0}bbl),
						'two' => q({0}bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'few' => q({0}bbl),
						'name' => q(bbl),
						'one' => q({0}bbl),
						'other' => q({0}bbl),
						'two' => q({0}bbl),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'few' => q({0}bu),
						'one' => q({0}bu),
						'other' => q({0}bu),
						'two' => q({0}bu),
					},
					# Core Unit Identifier
					'bushel' => {
						'few' => q({0}bu),
						'one' => q({0}bu),
						'other' => q({0}bu),
						'two' => q({0}bu),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'few' => q({0}cL),
						'name' => q(cL),
						'one' => q({0}cL),
						'other' => q({0}cL),
						'two' => q({0}cL),
					},
					# Core Unit Identifier
					'centiliter' => {
						'few' => q({0}cL),
						'name' => q(cL),
						'one' => q({0}cL),
						'other' => q({0}cL),
						'two' => q({0}cL),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'few' => q({0}cm³),
						'one' => q({0}cm³),
						'other' => q({0}cm³),
						'two' => q({0}cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'few' => q({0}cm³),
						'one' => q({0}cm³),
						'other' => q({0}cm³),
						'two' => q({0}cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0}ft³),
						'name' => q(ft³),
						'one' => q({0}ft³),
						'other' => q({0}ft³),
						'two' => q({0}ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0}ft³),
						'name' => q(ft³),
						'one' => q({0}ft³),
						'other' => q({0}ft³),
						'two' => q({0}ft³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0}in³),
						'name' => q(in³),
						'one' => q({0}in³),
						'other' => q({0}in³),
						'two' => q({0}in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0}in³),
						'name' => q(in³),
						'one' => q({0}in³),
						'other' => q({0}in³),
						'two' => q({0}in³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'few' => q({0}km³),
						'one' => q({0}km³),
						'other' => q({0}km³),
						'two' => q({0}km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'few' => q({0}km³),
						'one' => q({0}km³),
						'other' => q({0}km³),
						'two' => q({0}km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'few' => q({0}m³),
						'one' => q({0}m³),
						'other' => q({0}m³),
						'two' => q({0}m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'few' => q({0}m³),
						'one' => q({0}m³),
						'other' => q({0}m³),
						'two' => q({0}m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0}mì³),
						'one' => q({0}mì³),
						'other' => q({0}mì³),
						'two' => q({0}mì³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0}mì³),
						'one' => q({0}mì³),
						'other' => q({0}mì³),
						'two' => q({0}mì³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0}yd³),
						'name' => q(yd³),
						'one' => q({0}yd³),
						'other' => q({0}yd³),
						'two' => q({0}yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0}yd³),
						'name' => q(yd³),
						'one' => q({0}yd³),
						'other' => q({0}yd³),
						'two' => q({0}yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0}c),
						'one' => q({0}c),
						'other' => q({0}c),
						'two' => q({0}c),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0}c),
						'one' => q({0}c),
						'other' => q({0}c),
						'two' => q({0}c),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'few' => q({0}mc),
						'one' => q({0}mc),
						'other' => q({0}mc),
						'two' => q({0}mc),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'few' => q({0}mc),
						'one' => q({0}mc),
						'other' => q({0}mc),
						'two' => q({0}mc),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'few' => q({0}dL),
						'one' => q({0}dL),
						'other' => q({0}dL),
						'two' => q({0}dL),
					},
					# Core Unit Identifier
					'deciliter' => {
						'few' => q({0}dL),
						'one' => q({0}dL),
						'other' => q({0}dL),
						'two' => q({0}dL),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0}sp-mìl),
						'name' => q(sp-mhìl),
						'one' => q({0}sp-mhìl),
						'other' => q({0}sp-mhìl),
						'two' => q({0}sp-mhìl),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0}sp-mìl),
						'name' => q(sp-mhìl),
						'one' => q({0}sp-mhìl),
						'other' => q({0}sp-mhìl),
						'two' => q({0}sp-mhìl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0}sp-mìl ì.),
						'name' => q(sp-mhìl ìmp.),
						'one' => q({0}sp-mìl ì.),
						'other' => q({0}sp-mìl ì.),
						'two' => q({0}sp-mìl ì.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0}sp-mìl ì.),
						'name' => q(sp-mhìl ìmp.),
						'one' => q({0}sp-mìl ì.),
						'other' => q({0}sp-mìl ì.),
						'two' => q({0}sp-mìl ì.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0}drama),
						'one' => q({0}drama),
						'other' => q({0}drama),
						'two' => q({0}dhrama),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0}drama),
						'one' => q({0}drama),
						'other' => q({0}drama),
						'two' => q({0}dhrama),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0}boinne),
						'one' => q({0}bhoinne),
						'other' => q({0}boinne),
						'two' => q({0}bhoinne),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0}boinne),
						'one' => q({0}bhoinne),
						'other' => q({0}boinne),
						'two' => q({0}bhoinne),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0}fl oz),
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
						'two' => q({0}fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0}fl oz),
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
						'two' => q({0}fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0}fl oz ì.),
						'one' => q({0}fl oz ì.),
						'other' => q({0}fl oz ì.),
						'two' => q({0}fl oz ì.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0}fl oz ì.),
						'one' => q({0}fl oz ì.),
						'other' => q({0}fl oz ì.),
						'two' => q({0}fl oz ì.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0}gal),
						'one' => q({0}gal),
						'other' => q({0}gal),
						'two' => q({0}gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0}gal),
						'one' => q({0}gal),
						'other' => q({0}gal),
						'two' => q({0}gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} gal ì.),
						'one' => q({0} ghal ì.),
						'other' => q({0} gal ì.),
						'per' => q({0}/gal ì.),
						'two' => q({0} ghal ì.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} gal ì.),
						'one' => q({0} ghal ì.),
						'other' => q({0} gal ì.),
						'per' => q({0}/gal ì.),
						'two' => q({0} ghal ì.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'few' => q({0}hL),
						'one' => q({0}hL),
						'other' => q({0}hL),
						'two' => q({0}hL),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'few' => q({0}hL),
						'one' => q({0}hL),
						'other' => q({0}hL),
						'two' => q({0}hL),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0}sigire),
						'one' => q({0}sigire),
						'other' => q({0}sigire),
						'two' => q({0}sigire),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0}sigire),
						'one' => q({0}sigire),
						'other' => q({0}sigire),
						'two' => q({0}sigire),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'few' => q({0}L),
						'one' => q({0}L),
						'other' => q({0}L),
						'two' => q({0}L),
					},
					# Core Unit Identifier
					'liter' => {
						'few' => q({0}L),
						'one' => q({0}L),
						'other' => q({0}L),
						'two' => q({0}L),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'few' => q({0}ML),
						'one' => q({0}ML),
						'other' => q({0}ML),
						'two' => q({0}ML),
					},
					# Core Unit Identifier
					'megaliter' => {
						'few' => q({0}ML),
						'one' => q({0}ML),
						'other' => q({0}ML),
						'two' => q({0}ML),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'few' => q({0}mL),
						'one' => q({0}mL),
						'other' => q({0}mL),
						'two' => q({0}mL),
					},
					# Core Unit Identifier
					'milliliter' => {
						'few' => q({0}mL),
						'one' => q({0}mL),
						'other' => q({0}mL),
						'two' => q({0}mL),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0}crg.),
						'name' => q(crudhag),
						'one' => q({0}chrg.),
						'other' => q({0}crg.),
						'two' => q({0}chrg.),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0}crg.),
						'name' => q(crudhag),
						'one' => q({0}chrg.),
						'other' => q({0}crg.),
						'two' => q({0}chrg.),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'few' => q({0}pt),
						'name' => q(pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
						'two' => q({0}pt),
					},
					# Core Unit Identifier
					'pint' => {
						'few' => q({0}pt),
						'name' => q(pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
						'two' => q({0}pt),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'few' => q({0}mpt),
						'name' => q(pt),
						'one' => q({0}mpt),
						'other' => q({0}mpt),
						'two' => q({0}mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'few' => q({0}mpt),
						'name' => q(pt),
						'one' => q({0}mpt),
						'other' => q({0}mpt),
						'two' => q({0}mpt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'few' => q({0}càrt),
						'one' => q({0}càrt),
						'other' => q({0}càrt),
						'two' => q({0}càrt),
					},
					# Core Unit Identifier
					'quart' => {
						'few' => q({0}càrt),
						'one' => q({0}càrt),
						'other' => q({0}càrt),
						'two' => q({0}càrt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0}càrt ì.),
						'one' => q({0}chàrt ì.),
						'other' => q({0}càrt ì.),
						'two' => q({0}chàrt ì.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0}càrt ì.),
						'one' => q({0}chàrt ì.),
						'other' => q({0}càrt ì.),
						'two' => q({0}chàrt ì.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0}sp),
						'name' => q(sp),
						'one' => q({0}sp),
						'other' => q({0}sp),
						'two' => q({0}sp),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0}sp),
						'name' => q(sp),
						'one' => q({0}sp),
						'other' => q({0}sp),
						'two' => q({0}sp),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0}sp-t),
						'name' => q(sp-t),
						'one' => q({0}sp-t),
						'other' => q({0}sp-t),
						'two' => q({0}sp-t),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0}sp-t),
						'name' => q(sp-t),
						'one' => q({0}sp-t),
						'other' => q({0}sp-t),
						'two' => q({0}sp-t),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(comhair),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(comhair),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(forsa-g),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(forsa-g),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(meatair/diog²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(meatair/diog²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(àrc-mhion.),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(àrc-mhion.),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(àrc-dhiog),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(àrc-dhiog),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(ceum),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(ceum),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(rèidean),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(rèidean),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0} cuairtean),
						'name' => q(cuairt),
						'one' => q({0} chuairt),
						'other' => q({0} cuairt),
						'two' => q({0} chuairt),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0} cuairtean),
						'name' => q(cuairt),
						'one' => q({0} chuairt),
						'other' => q({0} cuairt),
						'two' => q({0} chuairt),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(acair),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(acair),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0} dönüm),
						'name' => q(dönüm),
						'one' => q({0} dönüm),
						'other' => q({0} dönüm),
						'two' => q({0} dhönüm),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0} dönüm),
						'name' => q(dönüm),
						'one' => q({0} dönüm),
						'other' => q({0} dönüm),
						'two' => q({0} dhönüm),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(heactair),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(heactair),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0} troigh²),
						'name' => q(troigh²),
						'one' => q({0} troigh²),
						'other' => q({0} troigh²),
						'two' => q({0} throigh²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0} troigh²),
						'name' => q(troigh²),
						'one' => q({0} troigh²),
						'other' => q({0} troigh²),
						'two' => q({0} throigh²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0} òirl²),
						'name' => q(òirl²),
						'one' => q({0} òirl²),
						'other' => q({0} òirl²),
						'per' => q({0}/òirl²),
						'two' => q({0} òirl²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0} òirl²),
						'name' => q(òirl²),
						'one' => q({0} òirl²),
						'other' => q({0} òirl²),
						'per' => q({0}/òirl²),
						'two' => q({0} òirl²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(meatair²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(meatair²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0} mì²),
						'name' => q(mìle²),
						'one' => q({0} mì²),
						'other' => q({0} mì²),
						'per' => q({0}/mì²),
						'two' => q({0} mì²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0} mì²),
						'name' => q(mìle²),
						'one' => q({0} mì²),
						'other' => q({0} mì²),
						'per' => q({0}/mì²),
						'two' => q({0} mì²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0} slat²),
						'name' => q(slat²),
						'one' => q({0} shlat²),
						'other' => q({0} slat²),
						'two' => q({0} shlat²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0} slat²),
						'name' => q(slat²),
						'one' => q({0} shlat²),
						'other' => q({0} slat²),
						'two' => q({0} shlat²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'few' => q({0} nith),
						'name' => q(nì),
						'one' => q({0} nì),
						'other' => q({0} nì),
						'two' => q({0} nì),
					},
					# Core Unit Identifier
					'item' => {
						'few' => q({0} nith),
						'name' => q(nì),
						'one' => q({0} nì),
						'other' => q({0} nì),
						'two' => q({0} nì),
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
						'few' => q({0} mmòl/L),
						'name' => q(mmòl/L),
						'one' => q({0} mmòl/L),
						'other' => q({0} mmòl/L),
						'two' => q({0} mmòl/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'few' => q({0} mmòl/L),
						'name' => q(mmòl/L),
						'one' => q({0} mmòl/L),
						'other' => q({0} mmòl/L),
						'two' => q({0} mmòl/L),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'few' => q({0} mòl),
						'name' => q(mòl),
						'one' => q({0} mòl),
						'other' => q({0} mòl),
						'two' => q({0} mòl),
					},
					# Core Unit Identifier
					'mole' => {
						'few' => q({0} mòl),
						'name' => q(mòl),
						'one' => q({0} mòl),
						'other' => q({0} mòl),
						'two' => q({0} mòl),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(sa cheud),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(sa cheud),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(sa mhìle),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(sa mhìle),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(sna deich mìltean),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(sna deich mìltean),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(pàirt/billean),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(pàirt/billean),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(liotair/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(liotair/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} mì/g),
						'name' => q(mìle/gal),
						'one' => q({0} mì/g),
						'other' => q({0} mì/g),
						'two' => q({0} mì/g),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} mì/g),
						'name' => q(mìle/gal),
						'one' => q({0} mì/g),
						'other' => q({0} mì/g),
						'two' => q({0} mì/g),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} mì/gal ìmp.),
						'name' => q(mìle/gal ìmp.),
						'one' => q({0} mhì/gal ìmp.),
						'other' => q({0} mì/gal ìmp.),
						'two' => q({0} mhì/gal ìmp.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} mì/gal ìmp.),
						'name' => q(mìle/gal ìmp.),
						'one' => q({0} mhì/gal ìmp.),
						'other' => q({0} mì/gal ìmp.),
						'two' => q({0} mhì/gal ìmp.),
					},
					# Long Unit Identifier
					'coordinate' => {
						'north' => q({0}T),
						'south' => q({0}D),
						'west' => q({0}I),
					},
					# Core Unit Identifier
					'coordinate' => {
						'north' => q({0}T),
						'south' => q({0}D),
						'west' => q({0}I),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'few' => q({0} b),
						'name' => q(biod),
						'one' => q({0} b),
						'other' => q({0} b),
						'two' => q({0} b),
					},
					# Core Unit Identifier
					'bit' => {
						'few' => q({0} b),
						'name' => q(biod),
						'one' => q({0} b),
						'other' => q({0} b),
						'two' => q({0} b),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0} B),
						'name' => q(baidht),
						'one' => q({0} B),
						'other' => q({0} B),
						'two' => q({0} B),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} B),
						'name' => q(baidht),
						'one' => q({0} B),
						'other' => q({0} B),
						'two' => q({0} B),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} li),
						'name' => q(li),
						'one' => q({0} li),
						'other' => q({0} li),
						'two' => q({0} li),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} li),
						'name' => q(li),
						'one' => q({0} li),
						'other' => q({0} li),
						'two' => q({0} li),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} là),
						'name' => q(latha),
						'one' => q({0} là),
						'other' => q({0} là),
						'per' => q({0}/là),
						'two' => q({0} là),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} là),
						'name' => q(latha),
						'one' => q({0} là),
						'other' => q({0} là),
						'per' => q({0}/là),
						'two' => q({0} là),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0} deich),
						'name' => q(deich),
						'one' => q({0} deich),
						'other' => q({0} deich),
						'two' => q({0} dheich),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0} deich),
						'name' => q(deich),
						'one' => q({0} deich),
						'other' => q({0} deich),
						'two' => q({0} dheich),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'few' => q({0} uair),
						'name' => q(uair),
						'one' => q({0} uair),
						'other' => q({0} uair),
						'per' => q({0}/uair),
						'two' => q({0} uair),
					},
					# Core Unit Identifier
					'hour' => {
						'few' => q({0} uair),
						'name' => q(uair),
						'one' => q({0} uair),
						'other' => q({0} uair),
						'per' => q({0}/uair),
						'two' => q({0} uair),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μ-diog),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μ-diog),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(mili-diog),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(mili-diog),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'few' => q({0} mion),
						'name' => q(mion),
						'one' => q({0} mhion),
						'other' => q({0} mion),
						'per' => q({0}/mion),
						'two' => q({0} mhion),
					},
					# Core Unit Identifier
					'minute' => {
						'few' => q({0} mion),
						'name' => q(mion),
						'one' => q({0} mhion),
						'other' => q({0} mion),
						'per' => q({0}/mion),
						'two' => q({0} mhion),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} mìos),
						'name' => q(mìos),
						'one' => q({0} mhìos),
						'other' => q({0} mìos),
						'two' => q({0} mhìos),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} mìos),
						'name' => q(mìos),
						'one' => q({0} mhìos),
						'other' => q({0} mìos),
						'two' => q({0} mhìos),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nano-diog),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nano-diog),
					},
					# Long Unit Identifier
					'duration-night' => {
						'few' => q({0} oidhche.),
						'name' => q(oidhche),
						'one' => q({0} oidhche),
						'other' => q({0} oidhche),
						'per' => q({0}/oidhche),
						'two' => q({0} oidhche),
					},
					# Core Unit Identifier
					'night' => {
						'few' => q({0} oidhche.),
						'name' => q(oidhche),
						'one' => q({0} oidhche),
						'other' => q({0} oidhche),
						'per' => q({0}/oidhche),
						'two' => q({0} oidhche),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} cairt.),
						'name' => q(cairt.),
						'one' => q({0} chairt.),
						'other' => q({0} cairt.),
						'per' => q({0}/c),
						'two' => q({0} chairt.),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} cairt.),
						'name' => q(cairt.),
						'one' => q({0} chairt.),
						'other' => q({0} cairt.),
						'per' => q({0}/c),
						'two' => q({0} chairt.),
					},
					# Long Unit Identifier
					'duration-second' => {
						'few' => q({0} diog),
						'name' => q(diog),
						'one' => q({0} diog),
						'other' => q({0} diog),
						'per' => q({0}/d),
						'two' => q({0} dhiog),
					},
					# Core Unit Identifier
					'second' => {
						'few' => q({0} diog),
						'name' => q(diog),
						'one' => q({0} diog),
						'other' => q({0} diog),
						'per' => q({0}/d),
						'two' => q({0} dhiog),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} sn),
						'name' => q(seachd),
						'one' => q({0} shn),
						'other' => q({0} sn),
						'per' => q({0}/sn),
						'two' => q({0} shn),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} sn),
						'name' => q(seachd),
						'one' => q({0} shn),
						'other' => q({0} sn),
						'per' => q({0}/sn),
						'two' => q({0} shn),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} blia),
						'name' => q(bliadhna),
						'one' => q({0} bhlia),
						'other' => q({0} blia),
						'per' => q({0}/bl),
						'two' => q({0} bhlia),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} blia),
						'name' => q(bliadhna),
						'one' => q({0} bhlia),
						'other' => q({0} blia),
						'per' => q({0}/bl),
						'two' => q({0} bhlia),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(mille-amp),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(mille-amp),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(aonad-teasa Breatannach),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(aonad-teasa Breatannach),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(volt-eleactroin),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(volt-eleactroin),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} Cal),
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
						'two' => q({0} Cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} Cal),
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
						'two' => q({0} Cal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(cilea-joule),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(cilea-joule),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kW-uair),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kW-uair),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(aonad-teasa nan SA),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(aonad-teasa nan SA),
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
						'name' => q(punnd-fhorsa),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(punnd-fhorsa),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'few' => q({0} dot),
						'name' => q(dotag),
						'one' => q({0} dot),
						'other' => q({0} dot),
						'two' => q({0} dhot),
					},
					# Core Unit Identifier
					'dot' => {
						'few' => q({0} dot),
						'name' => q(dotag),
						'one' => q({0} dot),
						'other' => q({0} dot),
						'two' => q({0} dhot),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} dpcm),
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
						'two' => q({0} dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} dpcm),
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
						'two' => q({0} dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} dpi),
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
						'two' => q({0} dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} dpi),
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
						'two' => q({0} dpi),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(meaga-piogsail),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(meaga-piogsail),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(piogsail),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(piogsail),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'few' => q({0} aith),
						'name' => q(aitheamh),
						'one' => q({0} aith),
						'other' => q({0} aith),
						'two' => q({0} aith),
					},
					# Core Unit Identifier
					'fathom' => {
						'few' => q({0} aith),
						'name' => q(aitheamh),
						'one' => q({0} aith),
						'other' => q({0} aith),
						'two' => q({0} aith),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0} troigh),
						'name' => q(troigh),
						'one' => q({0} troigh),
						'other' => q({0} troigh),
						'per' => q({0}/troigh),
						'two' => q({0} throigh),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0} troigh),
						'name' => q(troigh),
						'one' => q({0} troigh),
						'other' => q({0} troigh),
						'per' => q({0}/troigh),
						'two' => q({0} throigh),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'few' => q({0} stàid),
						'name' => q(stàid),
						'one' => q({0} stàid),
						'other' => q({0} stàid),
						'two' => q({0} stàid),
					},
					# Core Unit Identifier
					'furlong' => {
						'few' => q({0} stàid),
						'name' => q(stàid),
						'one' => q({0} stàid),
						'other' => q({0} stàid),
						'two' => q({0} stàid),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0} òirl),
						'name' => q(òirleach),
						'one' => q({0} òirl),
						'other' => q({0} òirl),
						'per' => q({0}/òirl),
						'two' => q({0} òirl),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0} òirl),
						'name' => q(òirleach),
						'one' => q({0} òirl),
						'other' => q({0} òirl),
						'per' => q({0}/òirl),
						'two' => q({0} òirl),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(meatair),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(meatair),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(μ-meatair),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μ-meatair),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} mì),
						'name' => q(mìle),
						'one' => q({0} mì),
						'other' => q({0} mì),
						'two' => q({0} mì),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} mì),
						'name' => q(mìle),
						'one' => q({0} mì),
						'other' => q({0} mì),
						'two' => q({0} mì),
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
						'name' => q(puing),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(puing),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(rèideas-grèine),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(rèideas-grèine),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} slat),
						'name' => q(slat),
						'one' => q({0} slat),
						'other' => q({0} slat),
						'two' => q({0} shlat),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} slat),
						'name' => q(slat),
						'one' => q({0} slat),
						'other' => q({0} slat),
						'two' => q({0} shlat),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(candela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(candela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumen),
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
						'name' => q(boillsgeachd-ghrèine),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(boillsgeachd-ghrèine),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(carat),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(carat),
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
						'name' => q(tomad-talmhainn),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(tomad-talmhainn),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} gràinne),
						'name' => q(gràinne),
						'one' => q({0} ghràinne),
						'other' => q({0} gràinne),
						'two' => q({0} ghràinne),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} gràinne),
						'name' => q(gràinne),
						'one' => q({0} ghràinne),
						'other' => q({0} gràinne),
						'two' => q({0} ghràinne),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'few' => q({0} unnsa),
						'name' => q(unnsa),
						'one' => q({0} unnsa),
						'other' => q({0} unnsa),
						'two' => q({0} unnsa),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0} unnsa),
						'name' => q(unnsa),
						'one' => q({0} unnsa),
						'other' => q({0} unnsa),
						'two' => q({0} unnsa),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(unnsa tròidh),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(unnsa tròidh),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(punnd),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(punnd),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(tomad-grèine),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(tomad-grèine),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'few' => q({0} clach),
						'name' => q(clach),
						'one' => q({0} chlach),
						'other' => q({0} clach),
						'two' => q({0} chlach),
					},
					# Core Unit Identifier
					'stone' => {
						'few' => q({0} clach),
						'name' => q(clach),
						'one' => q({0} chlach),
						'other' => q({0} clach),
						'two' => q({0} chlach),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(tunna),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(tunna),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'few' => q({0} àile),
						'name' => q(àile),
						'one' => q({0} àile),
						'other' => q({0} àile),
						'two' => q({0} àile),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'few' => q({0} àile),
						'name' => q(àile),
						'one' => q({0} àile),
						'other' => q({0} àile),
						'two' => q({0} àile),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'few' => q({0} bàr),
						'name' => q(bàr),
						'one' => q({0} bhàr),
						'other' => q({0} bàr),
						'two' => q({0} bhàr),
					},
					# Core Unit Identifier
					'bar' => {
						'few' => q({0} bàr),
						'name' => q(bàr),
						'one' => q({0} bhàr),
						'other' => q({0} bàr),
						'two' => q({0} bhàr),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(in Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(in Hg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0} mbàr),
						'name' => q(mbàr),
						'one' => q({0} mbàr),
						'other' => q({0} mbàr),
						'two' => q({0} mbàr),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0} mbàr),
						'name' => q(mbàr),
						'one' => q({0} mbàr),
						'other' => q({0} mbàr),
						'two' => q({0} mbàr),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/uair),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/uair),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'few' => q({0} solasan),
						'name' => q(solas),
						'one' => q({0} sholas),
						'other' => q({0} solas),
						'two' => q({0} sholas),
					},
					# Core Unit Identifier
					'light-speed' => {
						'few' => q({0} solasan),
						'name' => q(solas),
						'one' => q({0} sholas),
						'other' => q({0} solas),
						'two' => q({0} sholas),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(meatair/diog),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(meatair/diog),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} mì/h),
						'name' => q(mìle/uair),
						'one' => q({0} mì/h),
						'other' => q({0} mì/h),
						'two' => q({0} mì/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} mì/h),
						'name' => q(mìle/uair),
						'one' => q({0} mì/h),
						'other' => q({0} mì/h),
						'two' => q({0} mì/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(ceum C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(ceum C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(ceum F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(ceum F),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acair-throigh),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acair-throigh),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(baraill),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(baraill),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(buiseal),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(buiseal),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(c-liotair),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(c-liotair),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0} troigh³),
						'name' => q(troigh³),
						'one' => q({0} troigh³),
						'other' => q({0} troigh³),
						'two' => q({0} throigh³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0} troigh³),
						'name' => q(troigh³),
						'one' => q({0} troigh³),
						'other' => q({0} troigh³),
						'two' => q({0} throigh³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0} òirl³),
						'name' => q(òirl³),
						'one' => q({0} òirl³),
						'other' => q({0} òirl³),
						'two' => q({0} òirl³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0} òirl³),
						'name' => q(òirl³),
						'one' => q({0} òirl³),
						'other' => q({0} òirl³),
						'two' => q({0} òirl³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0} mì³),
						'name' => q(mì³),
						'one' => q({0} mì³),
						'other' => q({0} mì³),
						'two' => q({0} mì³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0} mì³),
						'name' => q(mì³),
						'one' => q({0} mì³),
						'other' => q({0} mì³),
						'two' => q({0} mì³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0} slat³),
						'name' => q(slat³),
						'one' => q({0} slat³),
						'other' => q({0} slat³),
						'two' => q({0} shlat³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0} slat³),
						'name' => q(slat³),
						'one' => q({0} slat³),
						'other' => q({0} slat³),
						'two' => q({0} shlat³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(cupa),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(cupa),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} spàin-mìl),
						'name' => q(spàin-mhìl),
						'one' => q({0} spàin-mhìl),
						'other' => q({0} spàin-mhìl),
						'two' => q({0} spàin-mhìl),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} spàin-mìl),
						'name' => q(spàin-mhìl),
						'one' => q({0} spàin-mhìl),
						'other' => q({0} spàin-mhìl),
						'two' => q({0} spàin-mhìl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} spàin-mìl ìmp.),
						'name' => q(spàin-mhìl ìmp.),
						'one' => q({0} spàin-mhìl ìmp.),
						'other' => q({0} spàin-mhìl ìmp.),
						'two' => q({0} spàin-mhìl ìmp.),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} spàin-mìl ìmp.),
						'name' => q(spàin-mhìl ìmp.),
						'one' => q({0} spàin-mhìl ìmp.),
						'other' => q({0} spàin-mhìl ìmp.),
						'two' => q({0} spàin-mhìl ìmp.),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} drama),
						'name' => q(drama),
						'one' => q({0} drama),
						'other' => q({0} drama),
						'two' => q({0} dhrama),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} drama),
						'name' => q(drama),
						'one' => q({0} drama),
						'other' => q({0} drama),
						'two' => q({0} dhrama),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0} boinne),
						'name' => q(boinne),
						'one' => q({0} bhoinne),
						'other' => q({0} boinne),
						'two' => q({0} bhoinne),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0} boinne),
						'name' => q(boinne),
						'one' => q({0} bhoinne),
						'other' => q({0} boinne),
						'two' => q({0} bhoinne),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
						'two' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
						'two' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} fl oz ìmp.),
						'name' => q(fl oz ìmp.),
						'one' => q({0} fl oz ìmp.),
						'other' => q({0} fl oz ìmp.),
						'two' => q({0} fl oz ìmp.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} fl oz ìmp.),
						'name' => q(fl oz ìmp.),
						'one' => q({0} fl oz ìmp.),
						'other' => q({0} fl oz ìmp.),
						'two' => q({0} fl oz ìmp.),
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
						'few' => q({0} gal ìmp.),
						'name' => q(gal ìmp.),
						'one' => q({0} ghal ìmp.),
						'other' => q({0} gal ìmp.),
						'per' => q({0}/gal ìmp.),
						'two' => q({0} ghal ìmp.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} gal ìmp.),
						'name' => q(gal ìmp.),
						'one' => q({0} ghal ìmp.),
						'other' => q({0} gal ìmp.),
						'per' => q({0}/gal ìmp.),
						'two' => q({0} ghal ìmp.),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} sigire),
						'name' => q(sigire),
						'one' => q({0} sigire),
						'other' => q({0} sigire),
						'two' => q({0} sigire),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} sigire),
						'name' => q(sigire),
						'one' => q({0} sigire),
						'other' => q({0} sigire),
						'two' => q({0} sigire),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'few' => q({0} L),
						'name' => q(liotair),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
						'two' => q({0} L),
					},
					# Core Unit Identifier
					'liter' => {
						'few' => q({0} L),
						'name' => q(liotair),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
						'two' => q({0} L),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} crudhag),
						'name' => q(crudhagan),
						'one' => q({0} chrudhag),
						'other' => q({0} crudhag),
						'two' => q({0} chrudhag),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} crudhag),
						'name' => q(crudhagan),
						'one' => q({0} chrudhag),
						'other' => q({0} crudhag),
						'two' => q({0} chrudhag),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pinnt),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pinnt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'few' => q({0} càrt),
						'name' => q(càrt),
						'one' => q({0} chàrt),
						'other' => q({0} càrt),
						'two' => q({0} chàrt),
					},
					# Core Unit Identifier
					'quart' => {
						'few' => q({0} càrt),
						'name' => q(càrt),
						'one' => q({0} chàrt),
						'other' => q({0} càrt),
						'two' => q({0} chàrt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} càrt ìmp.),
						'name' => q(càrt ìmp.),
						'one' => q({0} chàrt ìmp.),
						'other' => q({0} càrt ìmp.),
						'two' => q({0} chàrt ìmp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} càrt ìmp.),
						'name' => q(càrt ìmp.),
						'one' => q({0} chàrt ìmp.),
						'other' => q({0} càrt ìmp.),
						'two' => q({0} chàrt ìmp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} spàin),
						'name' => q(spàin),
						'one' => q({0} spàin),
						'other' => q({0} spàin),
						'two' => q({0} spàin),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} spàin),
						'name' => q(spàin),
						'one' => q({0} spàin),
						'other' => q({0} spàin),
						'two' => q({0} spàin),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} sp-t),
						'name' => q(spàin-t),
						'one' => q({0} sp-t),
						'other' => q({0} sp-t),
						'two' => q({0} sp-t),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} sp-t),
						'name' => q(spàin-t),
						'one' => q({0} sp-t),
						'other' => q({0} sp-t),
						'two' => q({0} sp-t),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:tha|th|t|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:chan eil|ch|c|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} agus {1}),
				2 => q({0} agus {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'arab' => {
			'percentSign' => q(٪),
		},
		'arabext' => {
			'minusSign' => q(-),
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
					'few' => '0 mìltean',
					'one' => '0 mhìle',
					'other' => '0 mìle',
					'two' => '0 mhìle',
				},
				'10000' => {
					'few' => '00 mìltean',
					'one' => '00 mhìle',
					'other' => '00 mìle',
					'two' => '00 mhìle',
				},
				'100000' => {
					'few' => '000 mìltean',
					'one' => '000 mhìle',
					'other' => '000 mìle',
					'two' => '000 mhìle',
				},
				'1000000' => {
					'few' => '0 milleanan',
					'one' => '0 mhillean',
					'other' => '0 millean',
					'two' => '0 mhillean',
				},
				'10000000' => {
					'few' => '00 milleanan',
					'one' => '00 mhillean',
					'other' => '00 millean',
					'two' => '00 mhillean',
				},
				'100000000' => {
					'few' => '000 milleanan',
					'one' => '000 mhillean',
					'other' => '000 millean',
					'two' => '000 mhillean',
				},
				'1000000000' => {
					'few' => '0 billeanan',
					'one' => '0 bhillean',
					'other' => '0 billean',
					'two' => '0 bhillean',
				},
				'10000000000' => {
					'few' => '00 billeanan',
					'one' => '00 bhillean',
					'other' => '00 billean',
					'two' => '00 bhillean',
				},
				'100000000000' => {
					'few' => '000 billeanan',
					'one' => '000 bhillean',
					'other' => '000 billean',
					'two' => '000 bhillean',
				},
				'1000000000000' => {
					'few' => '0 trilleanan',
					'one' => '0 trillean',
					'other' => '0 trillean',
					'two' => '0 thrillean',
				},
				'10000000000000' => {
					'few' => '00 trilleanan',
					'one' => '00 trillean',
					'other' => '00 trillean',
					'two' => '00 thrillean',
				},
				'100000000000000' => {
					'few' => '000 trilleanan',
					'one' => '000 trillean',
					'other' => '000 trillean',
					'two' => '000 thrillean',
				},
			},
			'short' => {
				'1000000000' => {
					'one' => '0B',
					'other' => '0B',
				},
				'10000000000' => {
					'one' => '00B',
					'other' => '00B',
				},
				'100000000000' => {
					'one' => '000B',
					'other' => '000B',
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
						'negative' => '(¤#,##0.00)',
						'positive' => '¤#,##0.00',
					},
					'standard' => {
						'positive' => '¤#,##0.00',
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
				'currency' => q(Peseta Andorrach),
				'few' => q(peseta Andorrach),
				'one' => q(pheseta Andorrach),
				'other' => q(peseta Andorrach),
				'two' => q(pheseta Andorrach),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(Dirham nan Iomaratan Arabach Aonaichte),
				'few' => q(dirham nan IAA),
				'one' => q(dirham nan IAA),
				'other' => q(dirham nan IAA),
				'two' => q(dhirham nan IAA),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Afghani Afghanach \(1927–2002\)),
				'few' => q(afghani Afghanach \(1927–2002\)),
				'one' => q(afghani Afghanach \(1927–2002\)),
				'other' => q(afghani Afghanach \(1927–2002\)),
				'two' => q(afghani Afghanach \(1927–2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afghani Afghanach),
				'few' => q(afghani Afghanach),
				'one' => q(afghani Afghanach),
				'other' => q(afghani Afghanach),
				'two' => q(afghani Afghanach),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(Lek Albàineach \(1946–1965\)),
				'few' => q(lek Albàineach \(1946–1965\)),
				'one' => q(lek Albàineach \(1946–1965\)),
				'other' => q(lek Albàineach \(1946–1965\)),
				'two' => q(lek Albàineach \(1946–1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Lek Albàineach),
				'few' => q(lek Albàineach),
				'one' => q(lek Albàineach),
				'other' => q(lek Albàineach),
				'two' => q(lek Albàineach),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Dram Airmeineach),
				'few' => q(dram Airmeineach),
				'one' => q(dram Airmeineach),
				'other' => q(dram Airmeineach),
				'two' => q(dhram Airmeineach),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Gulden Eileanan Aintilia nan Tìrean Ìsle),
				'few' => q(gulden Eileanan Aintilia nan Tìrean Ìsle),
				'one' => q(ghulden Eileanan Aintilia nan Tìrean Ìsle),
				'other' => q(gulden Eileanan Aintilia nan Tìrean Ìsle),
				'two' => q(ghulden Eileanan Aintilia nan Tìrean Ìsle),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza Angòlach),
				'few' => q(kwanza Angòlach),
				'one' => q(kwanza Angòlach),
				'other' => q(kwanza Angòlach),
				'two' => q(kwanza Angòlach),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Kwanza Angòlach \(1977–1991\)),
				'few' => q(kwanza Angòlach \(1977–1991\)),
				'one' => q(kwanza Angòlach \(1977–1991\)),
				'other' => q(kwanza Angòlach \(1977–1991\)),
				'two' => q(kwanza Angòlach \(1977–1991\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Kwanza ùr Angòlach \(1990–2000\)),
				'few' => q(kwanza ùr Angòlach \(1990–2000\)),
				'one' => q(kwanza ùr Angòlach \(1990–2000\)),
				'other' => q(kwanza ùr Angòlach \(1990–2000\)),
				'two' => q(kwanza ùr Angòlach \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Kwanza ath-ghleusaichte Angòlach \(1995–1999\)),
				'few' => q(kwanza ath-ghleusaichte Angòlach \(1995–1999\)),
				'one' => q(kwanza ath-ghleusaichte Angòlach \(1995–1999\)),
				'other' => q(kwanza ath-ghleusaichte Angòlach \(1995–1999\)),
				'two' => q(kwanza ath-ghleusaichte Angòlach \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Austral Argantaineach),
				'few' => q(austral Argantaineach),
				'one' => q(austral Argantaineach),
				'other' => q(austral Argantaineach),
				'two' => q(austral Argantaineach),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(Peso ley Argantaineach \(1970–1983\)),
				'few' => q(pesothan ley Argantaineach \(1970–1983\)),
				'one' => q(pheso ley Argantaineach \(1970–1983\)),
				'other' => q(peso ley Argantaineach \(1970–1983\)),
				'two' => q(pheso ley Argantaineach \(1970–1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(Peso Argantaineach \(1881–1970\)),
				'few' => q(pesothan Argantaineach \(1881–1970\)),
				'one' => q(pheso Argantaineach \(1881–1970\)),
				'other' => q(peso Argantaineach \(1881–1970\)),
				'two' => q(pheso Argantaineach \(1881–1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Peso Argantaineach \(1983–1985\)),
				'few' => q(pesothan Argantaineach \(1983–1985\)),
				'one' => q(pheso Argantaineach \(1983–1985\)),
				'other' => q(peso Argantaineach \(1983–1985\)),
				'two' => q(pheso Argantaineach \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Peso Argantaineach),
				'few' => q(pesothan Argantaineach),
				'one' => q(pheso Argantaineach),
				'other' => q(peso Argantaineach),
				'two' => q(pheso Argantaineach),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Schilling Ostaireach),
				'few' => q(schilling Ostaireach),
				'one' => q(schilling Ostaireach),
				'other' => q(schilling Ostaireach),
				'two' => q(schilling Ostaireach),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dolar Astràilianach),
				'few' => q(dolaran Astràilianach),
				'one' => q(dolar Astràilianach),
				'other' => q(dolar Astràilianach),
				'two' => q(dholar Astràilianach),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Florin Arùbach),
				'few' => q(florin Arùbach),
				'one' => q(fhlorin Arùbach),
				'other' => q(florin Arùbach),
				'two' => q(fhlorin Arùbach),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Manat Asarbaideànach \(1993–2006\)),
				'few' => q(manat Asarbaideànach \(1993–2006\)),
				'one' => q(mhanat Asarbaideànach \(1993–2006\)),
				'other' => q(manat Asarbaideànach \(1993–2006\)),
				'two' => q(mhanat Asarbaideànach \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Manat Asarbaideànach),
				'few' => q(manat Asarbaideànach),
				'one' => q(mhanat Asarbaideànach),
				'other' => q(manat Asarbaideànach),
				'two' => q(mhanat Asarbaideànach),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Dinar Bhosna agus Hearsagobhana \(1992–1994\)),
				'few' => q(dinar Bhosna agus Hearsagobhana \(1992–1994\)),
				'one' => q(dinar Bhosna agus Hearsagobhana \(1992–1994\)),
				'other' => q(dinar Bhosna agus Hearsagobhana \(1992–1994\)),
				'two' => q(dhinar Bhosna agus Hearsagobhana \(1992–1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Mark iompachail Bhosna agus Hearsagobhana),
				'few' => q(mark iompachail Bhosna agus Hearsagobhana),
				'one' => q(mhark iompachail Bhosna agus Hearsagobhana),
				'other' => q(mark iompachail Bhosna agus Hearsagobhana),
				'two' => q(mhark iompachail Bhosna agus Hearsagobhana),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(Dinar ùr Bhosna agus Hearsagobhana \(1994–1997\)),
				'few' => q(dinar ùr Bhosna agus Hearsagobhana \(1994–1997\)),
				'one' => q(dinar ùr Bhosna agus Hearsagobhana \(1994–1997\)),
				'other' => q(dinar ùr Bhosna agus Hearsagobhana \(1994–1997\)),
				'two' => q(dhinar ùr Bhosna agus Hearsagobhana \(1994–1997\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Dolar Barbadach),
				'few' => q(dolaran Barbadach),
				'one' => q(dolar Barbadach),
				'other' => q(dolar Barbadach),
				'two' => q(dholar Barbadach),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka Bangladaiseach),
				'few' => q(taka Bangladaiseach),
				'one' => q(taka Bangladaiseach),
				'other' => q(taka Bangladaiseach),
				'two' => q(thaka Bangladaiseach),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Franc Beilgeach \(iompachail\)),
				'few' => q(franc Beilgeach \(iompachail\)),
				'one' => q(fhranc Beilgeach \(iompachail\)),
				'other' => q(franc Beilgeach \(iompachail\)),
				'two' => q(fhranc Beilgeach \(iompachail\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Franc Beilgeach),
				'few' => q(franc Beilgeach),
				'one' => q(fhranc Beilgeach),
				'other' => q(franc Beilgeach),
				'two' => q(fhranc Beilgeach),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Franc Beilgeach \(ionmhasail\)),
				'few' => q(franc Beilgeach \(ionmhasail\)),
				'one' => q(fhranc Beilgeach \(ionmhasail\)),
				'other' => q(franc Beilgeach \(ionmhasail\)),
				'two' => q(fhranc Beilgeach \(ionmhasail\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Lev cruaidh Bulgarach),
				'few' => q(lev cruaidh Bulgarach),
				'one' => q(lev cruaidh Bulgarach),
				'other' => q(lev cruaidh Bulgarach),
				'two' => q(lev cruaidh Bulgarach),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(Lev sòisealach Bulgarach),
				'few' => q(lev sòisealach Bulgarach),
				'one' => q(lev sòisealach Bulgarach),
				'other' => q(lev sòisealach Bulgarach),
				'two' => q(lev sòisealach Bulgarach),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Lev Bulgarach),
				'few' => q(lev Bulgarach),
				'one' => q(lev Bulgarach),
				'other' => q(lev Bulgarach),
				'two' => q(lev Bulgarach),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(Lev Bulgarach \(1879–1952\)),
				'few' => q(lev Bulgarach \(1879–1952\)),
				'one' => q(lev Bulgarach \(1879–1952\)),
				'other' => q(lev Bulgarach \(1879–1952\)),
				'two' => q(lev Bulgarach \(1879–1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinar Bachraineach),
				'few' => q(dinar Bachraineach),
				'one' => q(dinar Bachraineach),
				'other' => q(dinar Bachraineach),
				'two' => q(dhinar Bachraineach),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Franc Burundaidheach),
				'few' => q(franc Burundaidheach),
				'one' => q(fhranc Burundaidheach),
				'other' => q(franc Burundaidheach),
				'two' => q(fhranc Burundaidheach),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Dolar Bearmùdach),
				'few' => q(dolaran Bearmùdach),
				'one' => q(dolar Bearmùdach),
				'other' => q(dolar Bearmùdach),
				'two' => q(dholar Bearmùdach),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Dolar Brùnaigheach),
				'few' => q(dolaran Brùnaigheach),
				'one' => q(dolar Brùnaigheach),
				'other' => q(dolar Brùnaigheach),
				'two' => q(dholar Brùnaigheach),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviano Boilibhiach),
				'few' => q(boliviano Boilibhiach),
				'one' => q(bholiviano Boilibhiach),
				'other' => q(boliviano Boilibhiach),
				'two' => q(bholiviano Boilibhiach),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(Boliviano Boilibhiach \(1863–1963\)),
				'few' => q(boliviano Boilibhiach \(1863–1963\)),
				'one' => q(bholiviano Boilibhiach \(1863–1963\)),
				'other' => q(boliviano Boilibhiach \(1863–1963\)),
				'two' => q(bholiviano Boilibhiach \(1863–1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Peso Boilibhiach),
				'few' => q(pesothan Boilibhiach),
				'one' => q(pheso Boilibhiach),
				'other' => q(peso Boilibhiach),
				'two' => q(pheso Boilibhiach),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Mvdol Boilibhiach),
				'few' => q(mvdol Boilibhiach),
				'one' => q(mvdol Boilibhiach),
				'other' => q(mvdol Boilibhiach),
				'two' => q(mvdol Boilibhiach),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Cruzeiro ùr Braisileach \(1967–1986\)),
				'few' => q(cruzeiro ùr Braisileach \(1967–1986\)),
				'one' => q(chruzeiro ùr Braisileach \(1967–1986\)),
				'other' => q(cruzeiro ùr Braisileach \(1967–1986\)),
				'two' => q(chruzeiro ùr Braisileach \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Cruzado Braisileach \(1986–1989\)),
				'few' => q(cruzado Braisileach \(1986–1989\)),
				'one' => q(chruzado Braisileach \(1986–1989\)),
				'other' => q(cruzado Braisileach \(1986–1989\)),
				'two' => q(chruzado Braisileach \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Cruzeiro Braisileach \(1990–1993\)),
				'few' => q(cruzeiro Braisileach \(1990–1993\)),
				'one' => q(chruzeiro Braisileach \(1990–1993\)),
				'other' => q(cruzeiro Braisileach \(1990–1993\)),
				'two' => q(chruzeiro Braisileach \(1990–1993\)),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Real Braisileach),
				'few' => q(real Braisileach),
				'one' => q(real Braisileach),
				'other' => q(real Braisileach),
				'two' => q(real Braisileach),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Cruzado ùr Braisileach \(1989–1990\)),
				'few' => q(cruzado ùr Braisileach \(1989–1990\)),
				'one' => q(chruzado ùr Braisileach \(1989–1990\)),
				'other' => q(cruzado ùr Braisileach \(1989–1990\)),
				'two' => q(chruzado ùr Braisileach \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Cruzeiro Braisileach \(1993–1994\)),
				'few' => q(cruzeiro Braisileach \(1993–1994\)),
				'one' => q(chruzeiro Braisileach \(1993–1994\)),
				'other' => q(cruzeiro Braisileach \(1993–1994\)),
				'two' => q(chruzeiro Braisileach \(1993–1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(Cruzeiro Braisileach \(1942–1967\)),
				'few' => q(cruzeiro Braisileach \(1942–1967\)),
				'one' => q(chruzeiro Braisileach \(1942–1967\)),
				'other' => q(cruzeiro Braisileach \(1942–1967\)),
				'two' => q(chruzeiro Braisileach \(1942–1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Dolar Bathamach),
				'few' => q(dolaran Bathamach),
				'one' => q(dolar Bathamach),
				'other' => q(dolar Bathamach),
				'two' => q(dholar Bathamach),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ngultrum Butànach),
				'few' => q(ngultrum Butànach),
				'one' => q(ngultrum Butànach),
				'other' => q(ngultrum Butànach),
				'two' => q(ngultrum Butànach),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Kyat Burmach),
				'few' => q(kyat Burmach),
				'one' => q(kyat Burmach),
				'other' => q(kyat Burmach),
				'two' => q(kyat Burmach),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula Botsuanach),
				'few' => q(pula Botsuanach),
				'one' => q(phula Botsuanach),
				'other' => q(pula Botsuanach),
				'two' => q(phula Botsuanach),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Rùbal ùr Bealaruiseach \(1994–1999\)),
				'few' => q(rùbalan ùra Bealaruiseach \(1994–1999\)),
				'one' => q(rùbal ùr Bealaruiseach \(1994–1999\)),
				'other' => q(rùbal ùr Bealaruiseach \(1994–1999\)),
				'two' => q(rùbal ùr Bealaruiseach \(1994–1999\)),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Rùbal Bealaruiseach),
				'few' => q(rùbalan Bealaruiseach),
				'one' => q(rùbal Bealaruiseach),
				'other' => q(rùbal Bealaruiseach),
				'two' => q(rùbal Bealaruiseach),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Rùbal Bealaruiseach \(2000–2016\)),
				'few' => q(rùbalan Bealaruiseach \(2000–2016\)),
				'one' => q(rùbal Bealaruiseach \(2000–2016\)),
				'other' => q(rùbal Bealaruiseach \(2000–2016\)),
				'two' => q(rùbal Bealaruiseach \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Dolar Beilìseach),
				'few' => q(dolaran Beilìseach),
				'one' => q(dolar Beilìseach),
				'other' => q(dolar Beilìseach),
				'two' => q(dholar Beilìseach),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(Dolar Canadach),
				'few' => q(dolaran Canadach),
				'one' => q(dolar Canadach),
				'other' => q(dolar Canadach),
				'two' => q(dholar Canadach),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Franc Congothach),
				'few' => q(franc Congothach),
				'one' => q(fhranc Congothach),
				'other' => q(franc Congothach),
				'two' => q(fhranc Congothach),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(Eòro WIR),
				'few' => q(Eòrothan WIR),
				'one' => q(Eòro WIR),
				'other' => q(Eòro WIR),
				'two' => q(Eòro WIR),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Franc Eilbheiseach),
				'few' => q(franc Eilbheiseach),
				'one' => q(fhranc Eilbheiseach),
				'other' => q(franc Eilbheiseach),
				'two' => q(fhranc Eilbheiseach),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(Franc WIR),
				'few' => q(franc WIR),
				'one' => q(fhranc WIR),
				'other' => q(franc WIR),
				'two' => q(fhranc WIR),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(Escudo Sileach),
				'few' => q(escudo Sileach),
				'one' => q(escudo Sileach),
				'other' => q(escudo Sileach),
				'two' => q(escudo Sileach),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Aonad cunntasachd Sileach \(UF\)),
				'few' => q(aonadan cunntasachd Sileach \(UF\)),
				'one' => q(aonad cunntasachd Sileach \(UF\)),
				'other' => q(aonad cunntasachd Sileach \(UF\)),
				'two' => q(aonad cunntasachd Sileach \(UF\)),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Peso Sileach),
				'few' => q(pesothan Sileach),
				'one' => q(pheso Sileach),
				'other' => q(peso Sileach),
				'two' => q(pheso Sileach),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yuan Sìneach \(far-thìreach\)),
				'few' => q(yuan Sìneach \(far-thìreach\)),
				'one' => q(yuan Sìneach \(far-thìreach\)),
				'other' => q(yuan Sìneach \(far-thìreach\)),
				'two' => q(yuan Sìneach \(far-thìreach\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(Dolar an t-sluagh-bhanca Shìnich),
				'few' => q(dolaran an t-sluagh-bhanca Shìnich),
				'one' => q(dolar an t-sluagh-bhanca Shìnich),
				'other' => q(dolar an t-sluagh-bhanca Shìnich),
				'two' => q(dholar an t-sluagh-bhanca Shìnich),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan Sìneach),
				'few' => q(yuan Sìneach),
				'one' => q(yuan Sìneach),
				'other' => q(yuan Sìneach),
				'two' => q(yuan Sìneach),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Peso Coloimbeach),
				'few' => q(pesothan Coloimbeach),
				'one' => q(pheso Coloimbeach),
				'other' => q(peso Coloimbeach),
				'two' => q(pheso Coloimbeach),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(Aonad fìor-luach Coloimbeach),
				'few' => q(aonadan fìor-luach Coloimbeach),
				'one' => q(aonad fìor-luach Coloimbeach),
				'other' => q(aonad fìor-luach Coloimbeach),
				'two' => q(aonad fìor-luach Coloimbeach),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Colón Costa Rìceach),
				'few' => q(colón Costa Rìceach),
				'one' => q(cholón Chosta Rìcea),
				'other' => q(colón Costa Rìceach),
				'two' => q(cholón Costa Rìceach),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Dinar Sèirbeach \(2002–2006\)),
				'few' => q(dinar Sèirbeach \(2002–2006\)),
				'one' => q(dinar Sèirbeach \(2002–2006\)),
				'other' => q(dinar Sèirbeach \(2002–2006\)),
				'two' => q(dhinar Sèirbeach \(2002–2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Koruna cruaidh Seic-Slòbhacach),
				'few' => q(koruna cruaidh Seic-Slòbhacach),
				'one' => q(koruna cruaidh Seic-Slòbhacach),
				'other' => q(koruna cruaidh Seic-Slòbhacach),
				'two' => q(koruna cruaidh Seic-Slòbhacach),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Peso iompachail Cùbach),
				'few' => q(pesothan iompachail Cùbach),
				'one' => q(pheso iompachail Cùbach),
				'other' => q(peso iompachail Cùbach),
				'two' => q(pheso iompachail Cùbach),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Peso Cùbach),
				'few' => q(pesothan Cùbach),
				'one' => q(pheso Cùbach),
				'other' => q(peso Cùbach),
				'two' => q(pheso Cùbach),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Escudo a’ Chip Uaine),
				'few' => q(escudo a’ Chip Uaine),
				'one' => q(escudo a’ Chip Uaine),
				'other' => q(escudo a’ Chip Uaine),
				'two' => q(escudo a’ Chip Uaine),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Punnd Cìoprasach),
				'few' => q(puinnd Chìoprasach),
				'one' => q(phunnd Cìoprasach),
				'other' => q(punnd Cìoprasach),
				'two' => q(phunnd Cìoprasach),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Koruna Seiceach),
				'few' => q(koruna Seiceach),
				'one' => q(koruna Seiceach),
				'other' => q(koruna Seiceach),
				'two' => q(koruna Seiceach),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Mark na Gearmailte an Ear),
				'few' => q(mark na Gearmailte an Ear),
				'one' => q(mhark na Gearmailte an Ear),
				'other' => q(mark na Gearmailte an Ear),
				'two' => q(mhark na Gearmailte an Ear),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Mark Gearmailteach),
				'few' => q(mark Gearmailteach),
				'one' => q(mhark Gearmailteach),
				'other' => q(mark Gearmailteach),
				'two' => q(mhark Gearmailteach),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Franc Diobùtaidheach),
				'few' => q(franc Diobùtaidheach),
				'one' => q(fhranc Diobùtaidheach),
				'other' => q(franc Diobùtaidheach),
				'two' => q(fhranc Diobùtaidheach),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Krone Danmhairgeach),
				'few' => q(kroner Danmhairgeach),
				'one' => q(krone Danmhairgeach),
				'other' => q(krone Danmhairgeach),
				'two' => q(krone Danmhairgeach),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Peso Doiminiceach),
				'few' => q(pesothan Doiminiceach),
				'one' => q(pheso Doiminiceach),
				'other' => q(peso Doiminiceach),
				'two' => q(pheso Doiminiceach),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinar Aildireach),
				'few' => q(dinar Aildireach),
				'one' => q(dinar Aildireach),
				'other' => q(dinar Aildireach),
				'two' => q(dhinar Aildireach),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Sucre Eacuadorach),
				'few' => q(sucre Eacuadorach),
				'one' => q(sucre Eacuadorach),
				'other' => q(sucre Eacuadorach),
				'two' => q(shucre Eacuadorach),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Aonad luach chunbhalaich Eacuadorach),
				'few' => q(aonadan luach chunbhalaich Eacuadorach),
				'one' => q(aonad luach chunbhalaich Eacuadorach),
				'other' => q(aonad luach chunbhalaich Eacuadorach),
				'two' => q(aonad luach chunbhalaich Eacuadorach),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Kroon Eastoineach),
				'few' => q(kroon Eastoineach),
				'one' => q(kroon Eastoineach),
				'other' => q(kroon Eastoineach),
				'two' => q(kroon Eastoineach),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Punnd Èipheiteach),
				'few' => q(puinnd Èipheiteach),
				'one' => q(phunnd Èipheiteach),
				'other' => q(punnd Èipheiteach),
				'two' => q(phunnd Èipheiteach),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa Eartrach),
				'few' => q(nakfa Eartrach),
				'one' => q(nakfa Eartrach),
				'other' => q(nakfa Eartrach),
				'two' => q(nakfa Eartrach),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(Peseta Spàinnteach \(cunntas A\)),
				'few' => q(peseta Spàinnteach \(cunntas A\)),
				'one' => q(pheseta Spàinnteach \(cunntas A\)),
				'other' => q(peseta Spàinnteach \(cunntas A\)),
				'two' => q(pheseta Spàinnteach \(cunntas A\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(Peseta Spàinnteach \(cunntas iompachail\)),
				'few' => q(peseta Spàinnteach \(cunntas iompachail\)),
				'one' => q(pheseta Spàinnteach \(cunntas iompachail\)),
				'other' => q(peseta Spàinnteach \(cunntas iompachail\)),
				'two' => q(pheseta Spàinnteach \(cunntas iompachail\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Peseta Spàinnteach),
				'few' => q(peseta Spàinnteach),
				'one' => q(pheseta Spàinnteach),
				'other' => q(peseta Spàinnteach),
				'two' => q(pheseta Spàinnteach),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Birr Itiopach),
				'few' => q(birr Itiopach),
				'one' => q(bhirr Itiopach),
				'other' => q(birr Itiopach),
				'two' => q(bhirr Itiopach),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Eòro),
				'few' => q(Eòrothan),
				'one' => q(Eòro),
				'other' => q(Eòro),
				'two' => q(Eòro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Markka Fionnlannach),
				'few' => q(markka Fionnlannach),
				'one' => q(mharkka Fionnlannach),
				'other' => q(markka Fionnlannach),
				'two' => q(mharkka Fionnlannach),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Dolar Fìditheach),
				'few' => q(dolaran Fìditheach),
				'one' => q(dolar Fìditheach),
				'other' => q(dolar Fìditheach),
				'two' => q(dholar Fìditheach),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Punnd Fàclannach),
				'few' => q(puinnd Fhàclannach),
				'one' => q(phunnd Fàclannach),
				'other' => q(punnd Fàclannach),
				'two' => q(phunnd Fàclannach),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Franc Frangach),
				'few' => q(franc Frangach),
				'one' => q(fhranc Frangach),
				'other' => q(franc Frangach),
				'two' => q(fhranc Frangach),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Punnd Sasannach),
				'few' => q(puinnd Shasannach),
				'one' => q(phunnd Sasannach),
				'other' => q(punnd Sasannach),
				'two' => q(phunnd Sasannach),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Kupon larit Cairtbheileach),
				'few' => q(kupon larit Cairtbheileach),
				'one' => q(kupon larit Cairtbheileach),
				'other' => q(kupon larit Cairtbheileach),
				'two' => q(kupon larit Cairtbheileach),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Lari Cairtbheileach),
				'few' => q(lari Cairtbheileach),
				'one' => q(lari Cairtbheileach),
				'other' => q(lari Cairtbheileach),
				'two' => q(lari Cairtbheileach),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Cedi Gànach \(1979–2007\)),
				'few' => q(cedi Gànach \(1979–2007\)),
				'one' => q(chedi Gànach \(1979–2007\)),
				'other' => q(cedi Gànach \(1979–2007\)),
				'two' => q(chedi Gànach \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Cedi Gànach),
				'few' => q(cedi Gànach),
				'one' => q(chedi Gànach),
				'other' => q(cedi Gànach),
				'two' => q(chedi Gànach),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Punnd Diobraltarach),
				'few' => q(puinnd Dhiobraltarach),
				'one' => q(phunnd Diobraltarach),
				'other' => q(punnd Diobraltarach),
				'two' => q(phunnd Diobraltarach),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi Gaimbitheach),
				'few' => q(dalasi Gaimbitheach),
				'one' => q(dalasi Gaimbitheach),
				'other' => q(dalasi Gaimbitheach),
				'two' => q(dhalasi Gaimbitheach),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Franc Ginitheach),
				'few' => q(franc Ginitheach),
				'one' => q(fhranc Ginitheach),
				'other' => q(franc Ginitheach),
				'two' => q(fhranc Ginitheach),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Syli Ginitheach),
				'few' => q(syli Ginitheach),
				'one' => q(syli Ginitheach),
				'other' => q(syli Ginitheach),
				'two' => q(shyli Ginitheach),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Ekwele Gini Meadhan-Chriosaich),
				'few' => q(ekwele Gini Meadhan-Chriosaich),
				'one' => q(ekwele Gini Meadhan-Chriosaich),
				'other' => q(ekwele Gini Meadhan-Chriosaich),
				'two' => q(ekwele Gini Meadhan-Chriosaich),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Drachma Greugach),
				'few' => q(drachma Greugach),
				'one' => q(dhrachma Greugach),
				'other' => q(drachma Greugach),
				'two' => q(dhrachma Greugach),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Quetzal Guatamalach),
				'few' => q(quetzal Guatamalach),
				'one' => q(quetzal Guatamalach),
				'other' => q(quetzal Guatamalach),
				'two' => q(quetzal Guatamalach),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Escudo Gini na Portagaile),
				'few' => q(escudo Gini na Portagaile),
				'one' => q(escudo Gini na Portagaile),
				'other' => q(escudo Gini na Portagaile),
				'two' => q(escudo Gini na Portagaile),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Peso Gini-Biosothach),
				'few' => q(pesothan Gini-Biosothach),
				'one' => q(pheso Gini-Biosothach),
				'other' => q(peso Gini-Biosothach),
				'two' => q(pheso Gini-Biosothach),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Dolar Guidheànach),
				'few' => q(dolaran Guidheànach),
				'one' => q(dolar Guidheànach),
				'other' => q(dolar Guidheànach),
				'two' => q(dholar Guidheànach),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Dolar Hong Kong),
				'few' => q(dolaran Hong Kong),
				'one' => q(dolar Hong Kong),
				'other' => q(dolar Hong Kong),
				'two' => q(dholar Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lempira Hondùrach),
				'few' => q(lempira Hondùrach),
				'one' => q(lempira Hondùrach),
				'other' => q(lempira Hondùrach),
				'two' => q(lempira Hondùrach),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Dinar Cròthaiseach),
				'few' => q(dinar Cròthaiseach),
				'one' => q(dinar Cròthaiseach),
				'other' => q(dinar Cròthaiseach),
				'two' => q(dhinar Cròthaiseach),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna Cròthaiseach),
				'few' => q(kuna Cròthaiseach),
				'one' => q(kuna Cròthaiseach),
				'other' => q(kuna Cròthaiseach),
				'two' => q(kuna Cròthaiseach),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gourde Haidhteach),
				'few' => q(gourde Haidhteach),
				'one' => q(ghourde Haidhteach),
				'other' => q(gourde Haidhteach),
				'two' => q(ghourde Haidhteach),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Forint Ungaireach),
				'few' => q(forint Ungaireach),
				'one' => q(fhorint Ungaireach),
				'other' => q(forint Ungaireach),
				'two' => q(fhorint Ungaireach),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Rupiah Innd-Innseach),
				'few' => q(rupiah Innd-Innseach),
				'one' => q(rupiah Innd-Innseach),
				'other' => q(rupiah Innd-Innseach),
				'two' => q(rupiah Innd-Innseach),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Punnd Èireannach),
				'few' => q(puinnd Èireannach),
				'one' => q(phunnd Èireannach),
				'other' => q(punnd Èireannach),
				'two' => q(phunnd Èireannach),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Punnd Iosraeleach),
				'few' => q(puinnd Iosraeleach),
				'one' => q(phunnd Iosraeleach),
				'other' => q(punnd Iosraeleach),
				'two' => q(phunnd Iosraeleach),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(Secel Iosraeleach \(1980–1985\)),
				'few' => q(secelean Iosraeleach \(1980–1985\)),
				'one' => q(shecel Iosraeleach \(1980–1985\)),
				'other' => q(secel Iosraeleach \(1980–1985\)),
				'two' => q(shecel Iosraeleach \(1980–1985\)),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Secel ùr Iosraeleach),
				'few' => q(secelean ùra Iosraeleach),
				'one' => q(shecel ùr Iosraeleach),
				'other' => q(secel ùr Iosraeleach),
				'two' => q(shecel ùr Iosraeleach),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupee Innseanach),
				'few' => q(rupee Innseanach),
				'one' => q(rupee Innseanach),
				'other' => q(rupee Innseanach),
				'two' => q(rupee Innseanach),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Dinar Ioràcach),
				'few' => q(dinar Ioràcach),
				'one' => q(dinar Ioràcach),
				'other' => q(dinar Ioràcach),
				'two' => q(dhinar Ioràcach),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Rial Iorànach),
				'few' => q(rial Iorànach),
				'one' => q(rial Iorànach),
				'other' => q(rial Iorànach),
				'two' => q(rial Iorànach),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(Króna Innis Tìleach \(1918–1981\)),
				'few' => q(krónur Innis Tìleach \(1918–1981\)),
				'one' => q(króna Innis Tìleach \(1918–1981\)),
				'other' => q(króna Innis Tìleach \(1918–1981\)),
				'two' => q(króna Innis Tìleach \(1918–1981\)),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Króna Innis Tìleach),
				'few' => q(krónur Innis Tìleach),
				'one' => q(króna Innis Tìleach),
				'other' => q(króna Innis Tìleach),
				'two' => q(króna Innis Tìleach),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Lira Eadailteach),
				'few' => q(lira Eadailteach),
				'one' => q(lira Eadailteach),
				'other' => q(lira Eadailteach),
				'two' => q(lira Eadailteach),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Dolar Diameugach),
				'few' => q(dolaran Diameugach),
				'one' => q(dolar Diameugach),
				'other' => q(dolar Diameugach),
				'two' => q(dholar Diameugach),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dinar Iòrdanach),
				'few' => q(dinar Iòrdanach),
				'one' => q(dinar Iòrdanach),
				'other' => q(dinar Iòrdanach),
				'two' => q(dhinar Iòrdanach),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yen Seapanach),
				'few' => q(yen Seapanach),
				'one' => q(yen Seapanach),
				'other' => q(yen Seapanach),
				'two' => q(yen Seapanach),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Shilling Ceineach),
				'few' => q(shilling Ceineach),
				'one' => q(shilling Ceineach),
				'other' => q(shilling Ceineach),
				'two' => q(shilling Ceineach),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Som Cìorgasach),
				'few' => q(som Cìorgasach),
				'one' => q(som Cìorgasach),
				'other' => q(som Cìorgasach),
				'two' => q(shom Cìorgasach),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Riel Cambuideach),
				'few' => q(riel Cambuideach),
				'one' => q(riel Cambuideach),
				'other' => q(riel Cambuideach),
				'two' => q(riel Cambuideach),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Franc Comorosach),
				'few' => q(franc Comorosach),
				'one' => q(fhranc Comorosach),
				'other' => q(franc Comorosach),
				'two' => q(fhranc Comorosach),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Won Choirèa a Tuath),
				'few' => q(won Choirèa a Tuath),
				'one' => q(won Choirèa a Tuath),
				'other' => q(won Choirèa a Tuath),
				'two' => q(won Choirèa a Tuath),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(Hwan Choirèa a Deas \(1953–1962\)),
				'few' => q(hwan Choirèa a Deas \(1953–1962\)),
				'one' => q(hwan Choirèa a Deas \(1953–1962\)),
				'other' => q(hwan Choirèa a Deas \(1953–1962\)),
				'two' => q(hwan Choirèa a Deas \(1953–1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(Won Choirèa a Deas \(1945–1953\)),
				'few' => q(won Choirèa a Deas \(1945–1953\)),
				'one' => q(won Choirèa a Deas \(1945–1953\)),
				'other' => q(won Choirèa a Deas \(1945–1953\)),
				'two' => q(won Choirèa a Deas \(1945–1953\)),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Won Choirèa a Deas),
				'few' => q(won Choirèa a Deas),
				'one' => q(won Choirèa a Deas),
				'other' => q(won Choirèa a Deas),
				'two' => q(won Choirèa a Deas),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Dinar Cuibhèiteach),
				'few' => q(dinar Cuibhèiteach),
				'one' => q(dinar Cuibhèiteach),
				'other' => q(dinar Cuibhèiteach),
				'two' => q(dhinar Cuibhèiteach),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Dolar Caimeanach),
				'few' => q(dolaran Caimeanach),
				'one' => q(dolar Caimeanach),
				'other' => q(dolar Caimeanach),
				'two' => q(dholar Caimeanach),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tenge Casachach),
				'few' => q(tenge Casachach),
				'one' => q(tenge Casachach),
				'other' => q(tenge Casachach),
				'two' => q(thenge Casachach),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Kip Làthosach),
				'few' => q(kip Làthosach),
				'one' => q(kip Làthosach),
				'other' => q(kip Làthosach),
				'two' => q(kip Làthosach),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Punnd Leabanach),
				'few' => q(puinnd Leabanach),
				'one' => q(phunnd Leabanach),
				'other' => q(punnd Leabanach),
				'two' => q(phunnd Leabanach),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Rupee Sri Lancach),
				'few' => q(rupee Sri Lancach),
				'one' => q(rupee Sri Lancach),
				'other' => q(rupee Sri Lancach),
				'two' => q(rupee Sri Lancach),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dolar Libèireach),
				'few' => q(dolaran Libèireach),
				'one' => q(dolar Libèireach),
				'other' => q(dolar Libèireach),
				'two' => q(dholar Libèireach),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti Leasotach),
				'few' => q(loti Leasotach),
				'one' => q(loti Leasotach),
				'other' => q(loti Leasotach),
				'two' => q(loti Leasotach),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litas Liotuaineach),
				'few' => q(litas Liotuaineach),
				'one' => q(litas Liotuaineach),
				'other' => q(litas Liotuaineach),
				'two' => q(litas Liotuaineach),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Talonas Liotuaineach),
				'few' => q(talonas Liotuaineach),
				'one' => q(talonas Liotuaineach),
				'other' => q(talonas Liotuaineach),
				'two' => q(thalonas Liotuaineach),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Franc iompachail Lugsamburgach),
				'few' => q(franc iompachail Lugsamburgach),
				'one' => q(fhranc iompachail Lugsamburgach),
				'other' => q(franc iompachail Lugsamburgach),
				'two' => q(fhranc iompachail Lugsamburgach),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Franc Lugsamburgach),
				'few' => q(franc Lugsamburgach),
				'one' => q(fhranc Lugsamburgach),
				'other' => q(franc Lugsamburgach),
				'two' => q(fhranc Lugsamburgach),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Franc ionmhasail Lugsamburgach),
				'few' => q(franc ionmhasail Lugsamburgach),
				'one' => q(fhranc ionmhasail Lugsamburgach),
				'other' => q(franc ionmhasail Lugsamburgach),
				'two' => q(fhranc ionmhasail Lugsamburgach),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Lats Laitbheach),
				'few' => q(lats Laitbheach),
				'one' => q(lats Laitbheach),
				'other' => q(lats Laitbheach),
				'two' => q(lats Laitbheach),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Rùbal Laitbheach),
				'few' => q(rùbalan Laitbheach),
				'one' => q(rùbal Laitbheach),
				'other' => q(rùbal Laitbheach),
				'two' => q(rùbal Laitbheach),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinar Libitheach),
				'few' => q(dinar Libitheach),
				'one' => q(dinar Libitheach),
				'other' => q(dinar Libitheach),
				'two' => q(dhinar Libitheach),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dirham Morocach),
				'few' => q(dirham Morocach),
				'one' => q(dirham Morocach),
				'other' => q(dirham Morocach),
				'two' => q(dhirham Morocach),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Franc Morocach),
				'few' => q(franc Morocach),
				'one' => q(fhranc Morocach),
				'other' => q(franc Morocach),
				'two' => q(fhranc Morocach),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(Franc Monacach),
				'few' => q(franc Monacach),
				'one' => q(fhranc Monacach),
				'other' => q(franc Monacach),
				'two' => q(fhranc Monacach),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(Cupon Moldobhach),
				'few' => q(cupon Moldobhach),
				'one' => q(chupon Moldobhach),
				'other' => q(cupon Moldobhach),
				'two' => q(chupon Moldobhach),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Leu Moldobhach),
				'few' => q(leu Moldobhach),
				'one' => q(leu Moldobhach),
				'other' => q(leu Moldobhach),
				'two' => q(leu Moldobhach),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariary Madagasgarach),
				'few' => q(ariary Madagasgarach),
				'one' => q(ariary Madagasgarach),
				'other' => q(ariary Madagasgarach),
				'two' => q(ariary Madagasgarach),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Franc Madagasgarach),
				'few' => q(franc Madagasgarach),
				'one' => q(fhranc Madagasgarach),
				'other' => q(franc Madagasgarach),
				'two' => q(fhranc Madagasgarach),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Denar Masadonach),
				'few' => q(denar Masadonach),
				'one' => q(denar Masadonach),
				'other' => q(denar Masadonach),
				'two' => q(dhenar Masadonach),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(Denar Masadonach \(1992–1993\)),
				'few' => q(denar Masadonach \(1992–1993\)),
				'one' => q(denar Masadonach \(1992–1993\)),
				'other' => q(denar Masadonach \(1992–1993\)),
				'two' => q(dhenar Masadonach \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Franc Màilitheach),
				'few' => q(franc Màilitheach),
				'one' => q(fhranc Màilitheach),
				'other' => q(franc Màilitheach),
				'two' => q(fhranc Màilitheach),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kyat Miànmarach),
				'few' => q(kyat Miànmarach),
				'one' => q(kyat Miànmarach),
				'other' => q(kyat Miànmarach),
				'two' => q(kyat Miànmarach),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Tugrik Mongolach),
				'few' => q(tugrik Mongolach),
				'one' => q(tugrik Mongolach),
				'other' => q(tugrik Mongolach),
				'two' => q(thugrik Mongolach),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataca Macàthuach),
				'few' => q(pataca Macàthuach),
				'one' => q(phataca Macàthuach),
				'other' => q(pataca Macàthuach),
				'two' => q(phataca Macàthuach),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Ouguiya Moratàineach \(1973–2017\)),
				'few' => q(ouguiya Moratàineach \(1973–2017\)),
				'one' => q(ouguiya Moratàineach \(1973–2017\)),
				'other' => q(ouguiya Moratàineach \(1973–2017\)),
				'two' => q(ouguiya Moratàineach \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Ouguiya Moratàineach),
				'few' => q(ouguiya Moratàineach),
				'one' => q(ouguiya Moratàineach),
				'other' => q(ouguiya Moratàineach),
				'two' => q(ouguiya Moratàineach),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Lira Maltach),
				'few' => q(lira Maltach),
				'one' => q(lira Maltach),
				'other' => q(lira Maltach),
				'two' => q(lira Maltach),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Punnd Maltach),
				'few' => q(puinnd Mhaltach),
				'one' => q(phunnd Maltach),
				'other' => q(punnd Maltach),
				'two' => q(phunnd Maltach),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupee Moiriseasach),
				'few' => q(rupee Moiriseasach),
				'one' => q(rupee Moiriseasach),
				'other' => q(rupee Moiriseasach),
				'two' => q(rupee Moiriseasach),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(Rupee Maladaibheach),
				'few' => q(rupee Maladaibheach),
				'one' => q(rupee Maladaibheach),
				'other' => q(rupee Maladaibheach),
				'two' => q(rupee Maladaibheach),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rufiyaa Maladaibheach),
				'few' => q(rufiyaa Maladaibheach),
				'one' => q(rufiyaa Maladaibheach),
				'other' => q(rufiyaa Maladaibheach),
				'two' => q(rufiyaa Maladaibheach),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwacha Malabhaidheach),
				'few' => q(kwacha Malabhaidheach),
				'one' => q(kwacha Malabhaidheach),
				'other' => q(kwacha Malabhaidheach),
				'two' => q(kwacha Malabhaidheach),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Peso Meagsagach),
				'few' => q(pesothan Meagsagach),
				'one' => q(pheso Meagsagach),
				'other' => q(peso Meagsagach),
				'two' => q(pheso Meagsagach),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Peso airgid Meagsagach \(1861–1992\)),
				'few' => q(pesothan airgid Meagsagach \(1861–1992\)),
				'one' => q(pheso airgid Meagsagach \(1861–1992\)),
				'other' => q(peso airgid Meagsagach \(1861–1992\)),
				'two' => q(pheso airgid Meagsagach \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Aonad inbheistidh Meagsagach),
				'few' => q(aonadan inbheistidh Meagsagach),
				'one' => q(aonad inbheistidh Meagsagach),
				'other' => q(aonad inbheistidh Meagsagach),
				'two' => q(aonad inbheistidh Meagsagach),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ringgit Malaidheach),
				'few' => q(ringgit Malaidheach),
				'one' => q(ringgit Malaidheach),
				'other' => q(ringgit Malaidheach),
				'two' => q(ringgit Malaidheach),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Escudo Mòsaimbiceach),
				'few' => q(escudo Mòsaimbiceach),
				'one' => q(escudo Mòsaimbiceach),
				'other' => q(escudo Mòsaimbiceach),
				'two' => q(escudo Mòsaimbiceach),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Metical Mòsaimbiceach \(1980–2006\)),
				'few' => q(metical Mòsaimbiceach \(1980–2006\)),
				'one' => q(mhetical Mòsaimbiceach \(1980–2006\)),
				'other' => q(metical Mòsaimbiceach \(1980–2006\)),
				'two' => q(mhetical Mòsaimbiceach \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Metical Mòsaimbiceach),
				'few' => q(metical Mòsaimbiceach),
				'one' => q(mhetical Mòsaimbiceach),
				'other' => q(metical Mòsaimbiceach),
				'two' => q(mhetical Mòsaimbiceach),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dolar Naimibitheach),
				'few' => q(dolaran Naimibitheach),
				'one' => q(dolar Naimibitheach),
				'other' => q(dolar Naimibitheach),
				'two' => q(dholar Naimibitheach),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira Nigèiriach),
				'few' => q(naira Nigèiriach),
				'one' => q(naira Nigèiriach),
				'other' => q(naira Nigèiriach),
				'two' => q(naira Nigèiriach),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Córdoba Niocaragach \(1988–1991\)),
				'few' => q(córdoba Niocaragach \(1988–1991\)),
				'one' => q(chórdoba Niocaragach \(1988–1991\)),
				'other' => q(córdoba Niocaragach \(1988–1991\)),
				'two' => q(chórdoba Niocaragach \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Córdoba Niocaragach),
				'few' => q(córdoba Niocaragach),
				'one' => q(chórdoba Niocaragach),
				'other' => q(córdoba Niocaragach),
				'two' => q(chórdoba Niocaragach),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Gulden Duitseach),
				'few' => q(gulden Duitseach),
				'one' => q(ghulden Duitseach),
				'other' => q(gulden Duitseach),
				'two' => q(ghulden Duitseach),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Krone Nirribheach),
				'few' => q(kroner Nirribheach),
				'one' => q(krone Nirribheach),
				'other' => q(krone Nirribheach),
				'two' => q(krone Nirribheach),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rupee Neapàlach),
				'few' => q(rupee Neapàlach),
				'one' => q(rupee Neapàlach),
				'other' => q(rupee Neapàlach),
				'two' => q(rupee Neapàlach),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Dolar Shealainn Nuaidh),
				'few' => q(dolaran Shealainn Nuaidh),
				'one' => q(dolar Shealainn Nuaidh),
				'other' => q(dolar Shealainn Nuaidh),
				'two' => q(dholar Shealainn Nuaidh),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Rial Omànach),
				'few' => q(rial Omànach),
				'one' => q(rial Omànach),
				'other' => q(rial Omànach),
				'two' => q(rial Omànach),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Balboa Panamach),
				'few' => q(balboa Panamach),
				'one' => q(bhalboa Panamach),
				'other' => q(balboa Panamach),
				'two' => q(bhalboa Panamach),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Inti Pearùthach),
				'few' => q(inti Pearùthach),
				'one' => q(inti Pearùthach),
				'other' => q(inti Pearùthach),
				'two' => q(inti Pearùthach),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Sol Pearùthach),
				'few' => q(sol Pearùthach),
				'one' => q(sol Pearùthach),
				'other' => q(sol Pearùthach),
				'two' => q(shol Pearùthach),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Sol Pearùthach \(1863–1965\)),
				'few' => q(sol Pearùthach \(1863–1965\)),
				'one' => q(sol Pearùthach \(1863–1965\)),
				'other' => q(sol Pearùthach \(1863–1965\)),
				'two' => q(shol Pearùthach \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina Ghini Nuaidh Paputhaiche),
				'few' => q(kina Ghini Nuaidh Paputhaiche),
				'one' => q(kina Ghini Nuaidh Paputhaiche),
				'other' => q(kina Ghini Nuaidh Paputhaiche),
				'two' => q(kina Ghini Nuaidh Paputhaiche),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Peso Filipineach),
				'few' => q(pesothan Filipineach),
				'one' => q(pheso Filipineach),
				'other' => q(peso Filipineach),
				'two' => q(pheso Filipineach),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rupee Pagastànach),
				'few' => q(rupee Pagastànach),
				'one' => q(rupee Pagastànach),
				'other' => q(rupee Pagastànach),
				'two' => q(rupee Pagastànach),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Złoty Pòlainneach),
				'few' => q(złoty Pòlainneach),
				'one' => q(złoty Pòlainneach),
				'other' => q(złoty Pòlainneach),
				'two' => q(złoty Pòlainneach),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Złoty Pòlainneach \(1950–1995\)),
				'few' => q(złoty Pòlainneach \(1950–1995\)),
				'one' => q(złoty Pòlainneach \(1950–1995\)),
				'other' => q(złoty Pòlainneach \(1950–1995\)),
				'two' => q(złoty Pòlainneach \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Escudo Portagaileach),
				'few' => q(escudo Portagaileach),
				'one' => q(escudo Portagaileach),
				'other' => q(escudo Portagaileach),
				'two' => q(escudo Portagaileach),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Guaraní Paraguaidheach),
				'few' => q(guaraní Paraguaidheach),
				'one' => q(ghuaraní Paraguaidheach),
				'other' => q(guaraní Paraguaidheach),
				'two' => q(ghuaraní Paraguaidheach),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Rial Catarach),
				'few' => q(rial Catarach),
				'one' => q(rial Catarach),
				'other' => q(rial Catarach),
				'two' => q(rial Catarach),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Dolar Rhodesiach),
				'few' => q(dolaran Rhodesiach),
				'one' => q(dolar Rhodesiach),
				'other' => q(dolar Rhodesiach),
				'two' => q(dholar Rhodesiach),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Leu Romàineach \(1952–2006\)),
				'few' => q(leu Romàineach \(1952–2006\)),
				'one' => q(leu Romàineach \(1952–2006\)),
				'other' => q(leu Romàineach \(1952–2006\)),
				'two' => q(leu Romàineach \(1952–2006\)),
			},
		},
		'RON' => {
			symbol => 'leu',
			display_name => {
				'currency' => q(Leu Romàineach),
				'few' => q(leu Romàineach),
				'one' => q(leu Romàineach),
				'other' => q(leu Romàineach),
				'two' => q(leu Romàineach),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dinar Sèirbeach),
				'few' => q(dinar Sèirbeach),
				'one' => q(dinar Sèirbeach),
				'other' => q(dinar Sèirbeach),
				'two' => q(dhinar Sèirbeach),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rùbal Ruiseach),
				'few' => q(rùbalan Ruiseach),
				'one' => q(rùbal Ruiseach),
				'other' => q(rùbal Ruiseach),
				'two' => q(rùbal Ruiseach),
			},
		},
		'RUR' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(Rùbal Ruiseach \(1991–1998\)),
				'few' => q(rùbalan Ruiseach \(1991–1998\)),
				'one' => q(rùbal Ruiseach \(1991–1998\)),
				'other' => q(rùbal Ruiseach \(1991–1998\)),
				'two' => q(rùbal Ruiseach \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Franc Rubhandach),
				'few' => q(franc Rubhandach),
				'one' => q(fhranc Rubhandach),
				'other' => q(franc Rubhandach),
				'two' => q(fhranc Rubhandach),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyal Sabhdach),
				'few' => q(riyal Sabhdach),
				'one' => q(riyal Sabhdach),
				'other' => q(riyal Sabhdach),
				'two' => q(riyal Sabhdach),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Dolar Eileanan Sholaimh),
				'few' => q(dolaran Eileanan Sholaimh),
				'one' => q(dolar Eileanan Sholaimh),
				'other' => q(dolar Eileanan Sholaimh),
				'two' => q(dholar Eileanan Sholaimh),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupee Seiseallach),
				'few' => q(rupee Seiseallach),
				'one' => q(rupee Seiseallach),
				'other' => q(rupee Seiseallach),
				'two' => q(rupee Seiseallach),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Dinar Sudànach \(1992–2007\)),
				'few' => q(dinar Sudànach \(1992–2007\)),
				'one' => q(dinar Sudànach \(1992–2007\)),
				'other' => q(dinar Sudànach \(1992–2007\)),
				'two' => q(dhinar Sudànach \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Punnd Sudànach),
				'few' => q(puinnd Shudànach),
				'one' => q(phunnd Sudànach),
				'other' => q(punnd Sudànach),
				'two' => q(phunnd Sudànach),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Punnd Sudànach \(1957–1998\)),
				'few' => q(puinnd Shudànach \(1957–1998\)),
				'one' => q(phunnd Sudànach \(1957–1998\)),
				'other' => q(punnd Sudànach \(1957–1998\)),
				'two' => q(phunnd Sudànach \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Krona Suaineach),
				'few' => q(kronor Suaineach),
				'one' => q(krona Suaineach),
				'other' => q(krona Suaineach),
				'two' => q(krona Suaineach),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Dolar Singeapòrach),
				'few' => q(dolaran Singeapòrach),
				'one' => q(dolar Singeapòrach),
				'other' => q(dolar Singeapòrach),
				'two' => q(dholar Singeapòrach),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Punnd Eilean Naomh Eilidh),
				'few' => q(puinnd Eilean Naomh Eilidh),
				'one' => q(phunnd Eilean Naomh Eilidh),
				'other' => q(punnd Eilean Naomh Eilidh),
				'two' => q(phunnd Eilean Naomh Eilidh),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Tolar Slòbhaineach),
				'few' => q(tolar Slòbhaineach),
				'one' => q(tolar Slòbhaineach),
				'other' => q(tolar Slòbhaineach),
				'two' => q(tholar Slòbhaineach),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Koruna Slòbhacach),
				'few' => q(koruna Slòbhacach),
				'one' => q(koruna Slòbhacach),
				'other' => q(koruna Slòbhacach),
				'two' => q(koruna Slòbhacach),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Leone Siarra Leòmhannach ùr),
				'few' => q(leone Siarra Leòmhannach ùr),
				'one' => q(leone Siarra Leòmhannach ùr),
				'other' => q(leone Siarra Leòmhannach ùr),
				'two' => q(leone Siarra Leòmhannach ùr),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone Siarra Leòmhannach),
				'few' => q(leone Siarra Leòmhannach),
				'one' => q(leone Siarra Leòmhannach),
				'other' => q(leone Siarra Leòmhannach),
				'two' => q(leone Siarra Leòmhannach),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Shilling Somàilitheach),
				'few' => q(shilling Somàilitheach),
				'one' => q(shilling Somàilitheach),
				'other' => q(shilling Somàilitheach),
				'two' => q(shilling Somàilitheach),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Dolar Suranamach),
				'few' => q(dolaran Suranamach),
				'one' => q(dolar Suranamach),
				'other' => q(dolar Suranamach),
				'two' => q(dholar Suranamach),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Gulden Suranamach),
				'few' => q(gulden Suranamach),
				'one' => q(ghulden Suranamach),
				'other' => q(gulden Suranamach),
				'two' => q(ghulden Suranamach),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Punnd Sudàin a Deas),
				'few' => q(puinnd Shudàin a Deas),
				'one' => q(phunnd Sudàin a Deas),
				'other' => q(punnd Sudàin a Deas),
				'two' => q(phunnd Sudàin a Deas),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobra São Tomé agus Príncipe \(1977–2017\)),
				'few' => q(dobra São Tomé agus Príncipe \(1977–2017\)),
				'one' => q(dobra São Tomé agus Príncipe \(1977–2017\)),
				'other' => q(dobra São Tomé agus Príncipe \(1977–2017\)),
				'two' => q(dhobra São Tomé agus Príncipe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra São Tomé agus Príncipe),
				'few' => q(dobra São Tomé agus Príncipe),
				'one' => q(dobra São Tomé agus Príncipe),
				'other' => q(dobra São Tomé agus Príncipe),
				'two' => q(dhobra São Tomé agus Príncipe),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Rùbal Sovietach),
				'few' => q(rùbalan Sovietach),
				'one' => q(rùbal Sovietach),
				'other' => q(rùbal Sovietach),
				'two' => q(rùbal Sovietach),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(Colón Salbhadorach),
				'few' => q(colón Salbhadorach),
				'one' => q(cholón Salbhadorach),
				'other' => q(colón Salbhadorach),
				'two' => q(cholón Salbhadorach),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Punnd Siridheach),
				'few' => q(puinnd Shiridheach),
				'one' => q(phunnd Siridheach),
				'other' => q(punnd Siridheach),
				'two' => q(phunnd Siridheach),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni Suasaidheach),
				'few' => q(lilangeni Suasaidheach),
				'one' => q(lilangeni Suasaidheach),
				'other' => q(lilangeni Suasaidheach),
				'two' => q(lilangeni Suasaidheach),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Baht Tàidheach),
				'few' => q(baht Tàidheach),
				'one' => q(bhaht Tàidheach),
				'other' => q(baht Tàidheach),
				'two' => q(bhaht Tàidheach),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Rùbal Taidigeach),
				'few' => q(rùbalan Taidigeach),
				'one' => q(rùbal Taidigeach),
				'other' => q(rùbal Taidigeach),
				'two' => q(rùbal Taidigeach),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Somoni Taidigeach),
				'few' => q(somoni Taidigeach),
				'one' => q(somoni Taidigeach),
				'other' => q(somoni Taidigeach),
				'two' => q(shomoni Taidigeach),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Manat Turcmanach \(1993–2009\)),
				'few' => q(manat Turcmanach \(1993–2009\)),
				'one' => q(mhanat Turcmanach \(1993–2009\)),
				'other' => q(manat Turcmanach \(1993–2009\)),
				'two' => q(mhanat Turcmanach \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Manat Turcmanach),
				'few' => q(manat Turcmanach),
				'one' => q(mhanat Turcmanach),
				'other' => q(manat Turcmanach),
				'two' => q(mhanat Turcmanach),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinar Tuiniseach),
				'few' => q(dinar Tuiniseach),
				'one' => q(dinar Tuiniseach),
				'other' => q(dinar Tuiniseach),
				'two' => q(dhinar Tuiniseach),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Paʻanga Tongach),
				'few' => q(paʻanga Tongach),
				'one' => q(phaʻanga Tongach),
				'other' => q(paʻanga Tongach),
				'two' => q(phaʻanga Tongach),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Escudo Tìomorach),
				'few' => q(escudo Tìomorach),
				'one' => q(escudo Tìomorach),
				'other' => q(escudo Tìomorach),
				'two' => q(escudo Tìomorach),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Lira Turcach \(1922–2005\)),
				'few' => q(lira Turcach \(1922–2005\)),
				'one' => q(lira Turcach \(1922–2005\)),
				'other' => q(lira Turcach \(1922–2005\)),
				'two' => q(lira Turcach \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Lira Turcach),
				'few' => q(lira Turcach),
				'one' => q(lira Turcach),
				'other' => q(lira Turcach),
				'two' => q(lira Turcach),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dolar Thrianaid agus Thobago),
				'few' => q(dolaran Thrianaid agus Thobago),
				'one' => q(dolar Thrianaid agus Thobago),
				'other' => q(dolar Thrianaid agus Thobago),
				'two' => q(dholar Thrianaid agus Thobago),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Dolar ùr Taidh-Bhànach),
				'few' => q(dolaran ùra Taidh-Bhànach),
				'one' => q(dolar ùr Taidh-Bhànach),
				'other' => q(dolar ùr Taidh-Bhànach),
				'two' => q(dholar ùr Taidh-Bhànach),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Shilling Tansanaidheach),
				'few' => q(shilling Tansanaidheach),
				'one' => q(shilling Tansanaidheach),
				'other' => q(shilling Tansanaidheach),
				'two' => q(shilling Tansanaidheach),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Hryvnia Ucràineach),
				'few' => q(hryvnia Ucràineach),
				'one' => q(hryvnia Ucràineach),
				'other' => q(hryvnia Ucràineach),
				'two' => q(hryvnia Ucràineach),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Karbovanets Ucràineach),
				'few' => q(karbovanets Ucràineach),
				'one' => q(karbovanets Ucràineach),
				'other' => q(karbovanets Ucràineach),
				'two' => q(karbovanets Ucràineach),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Shilling Ugandach \(1966–1987\)),
				'few' => q(shilling Ugandach \(1966–1987\)),
				'one' => q(shilling Ugandach \(1966–1987\)),
				'other' => q(shilling Ugandach \(1966–1987\)),
				'two' => q(shilling Ugandach \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Shilling Ugandach),
				'few' => q(shilling Ugandach),
				'one' => q(shilling Ugandach),
				'other' => q(shilling Ugandach),
				'two' => q(shilling Ugandach),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(Dolar nan Stàitean Aonaichte),
				'few' => q(dolaran nan Stàitean Aonaichte),
				'one' => q(dolar nan Stàitean Aonaichte),
				'other' => q(dolar nan Stàitean Aonaichte),
				'two' => q(dholar nan Stàitean Aonaichte),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(Dolar nan SA \(an ath–latha\)),
				'few' => q(dolaran nan SA \(an ath–latha\)),
				'one' => q(dolar nan SA \(an ath–latha\)),
				'other' => q(dolar nan SA \(an ath–latha\)),
				'two' => q(dholar nan SA \(an ath–latha\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(Dolar nan SA \(an aon latha\)),
				'few' => q(dolaran nan SA \(an aon latha\)),
				'one' => q(dolar nan SA \(an aon latha\)),
				'other' => q(dolar nan SA \(an aon latha\)),
				'two' => q(dholar nan SA \(an aon latha\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(Peso Uruguaidheach \(aonadan inneacsaichte\)),
				'few' => q(pesothan Uruguaidheach \(aonadan inneacsaichte\)),
				'one' => q(pheso Uruguaidheach \(aonadan inneacsaichte\)),
				'other' => q(peso Uruguaidheach \(aonadan inneacsaichte\)),
				'two' => q(pheso Uruguaidheach \(aonadan inneacsaichte\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Peso Uruguaidheach \(1975–1993\)),
				'few' => q(pesothan Uruguaidheach \(1975–1993\)),
				'one' => q(pheso Uruguaidheach \(1975–1993\)),
				'other' => q(peso Uruguaidheach \(1975–1993\)),
				'two' => q(pheso Uruguaidheach \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Peso Uruguaidheach),
				'few' => q(pesothan Uruguaidheach),
				'one' => q(pheso Uruguaidheach),
				'other' => q(peso Uruguaidheach),
				'two' => q(pheso Uruguaidheach),
			},
		},
		'UYW' => {
			display_name => {
				'currency' => q(Aonad inneacs tuarastail ainmeach Uruguaidh),
				'few' => q(aonadan inneacs tuarastail ainmeach Uruguaidh),
				'one' => q(aonad inneacs tuarastail ainmeach Uruguaidh),
				'other' => q(aonad inneacs tuarastail ainmeach Uruguaidh),
				'two' => q(aonad inneacs tuarastail ainmeach Uruguaidh),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Som Usbagach),
				'few' => q(som Usbagach),
				'one' => q(som Usbagach),
				'other' => q(som Usbagach),
				'two' => q(shom Usbagach),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Bolívar Bheinisealach \(1871–2008\)),
				'few' => q(bolívar Bheinisealach \(1871–2008\)),
				'one' => q(bholívar Bheinisealach \(1871–2008\)),
				'other' => q(bolívar Bheinisealach \(1871–2008\)),
				'two' => q(bholívar Bheinisealach \(1871–2008\)),
			},
		},
		'VED' => {
			display_name => {
				'currency' => q(Bolívar Soberano),
				'few' => q(bolívar Soberano),
				'one' => q(bholívar Soberano),
				'other' => q(bolívar Soberano),
				'two' => q(bholívar Soberano),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Bolívar Bheinisealach \(2008–2018\)),
				'few' => q(bolívar Bheinisealach \(2008–2018\)),
				'one' => q(bholívar Bheinisealach \(2008–2018\)),
				'other' => q(bolívar Bheinisealach \(2008–2018\)),
				'two' => q(bholívar Bheinisealach \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Bolívar Bheinisealach),
				'few' => q(bolívar Bheinisealach),
				'one' => q(bholívar Bheinisealach),
				'other' => q(bolívar Bheinisealach),
				'two' => q(bholívar Bheinisealach),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Dong Bhiet-Namach),
				'few' => q(dong Bhiet-Namach),
				'one' => q(dong Bhiet-Namach),
				'other' => q(dong Bhiet-Namach),
				'two' => q(dhong Bhiet-Namach),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(Dong Bhiet-Namach \(1978–1985\)),
				'few' => q(dong Bhiet-Namach \(1978–1985\)),
				'one' => q(dong Bhiet-Namach \(1978–1985\)),
				'other' => q(dong Bhiet-Namach \(1978–1985\)),
				'two' => q(dhong Bhiet-Namach \(1978–1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vatu Vanuatuthach),
				'few' => q(vatu Vanuatuthach),
				'one' => q(vatu Vanuatuthach),
				'other' => q(vatu Vanuatuthach),
				'two' => q(vatu Vanuatuthach),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tala Samothach),
				'few' => q(tala Samothach),
				'one' => q(tala Samothach),
				'other' => q(tala Samothach),
				'two' => q(thala Samothach),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Franc CFA Meadhan-Afragach),
				'few' => q(franc CFA Meadhan-Afragach),
				'one' => q(fhranc CFA Meadhan-Afragach),
				'other' => q(franc CFA Meadhan-Afragach),
				'two' => q(fhranc CFA Meadhan-Afragach),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Airgead),
				'few' => q(unnsachan tròidh airgid),
				'one' => q(unnsa tròidh airgid),
				'other' => q(unnsa tròidh airgid),
				'two' => q(unnsa tròidh airgid),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Òr),
				'few' => q(unnsachan tròidh òir),
				'one' => q(unnsa tròidh òir),
				'other' => q(unnsa tròidh òir),
				'two' => q(unnsa tròidh òir),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Aonad co-dhèanta Eòrpach),
				'few' => q(aonadan co-dhèanta Eòrpach),
				'one' => q(aonad co-dhèanta Eòrpach),
				'other' => q(aonad co-dhèanta Eòrpach),
				'two' => q(aonad co-dhèanta Eòrpach),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Aonad airgid Eòrpach),
				'few' => q(aonadan airgid Eòrpach),
				'one' => q(aonad airgid Eòrpach),
				'other' => q(aonad airgid Eòrpach),
				'two' => q(aonad airgid Eòrpach),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Aonad cunntasachd Eòrpach \(XBC\)),
				'few' => q(aonadan cunntasachd Eòrpach \(XBC\)),
				'one' => q(aonad cunntasachd Eòrpach \(XBC\)),
				'other' => q(aonad cunntasachd Eòrpach \(XBC\)),
				'two' => q(aonad cunntasachd Eòrpach \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Aonad cunntasachd Eòrpach \(XBD\)),
				'few' => q(aonadan cunntasachd Eòrpach \(XBD\)),
				'one' => q(aonad cunntasachd Eòrpach \(XBD\)),
				'other' => q(aonad cunntasachd Eòrpach \(XBD\)),
				'two' => q(aonad cunntasachd Eòrpach \(XBD\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Dolar Caraibeach earach),
				'few' => q(dolaran Caraibeach earach),
				'one' => q(dolar Caraibeach earach),
				'other' => q(dolar Caraibeach earach),
				'two' => q(dholar Caraibeach earach),
			},
		},
		'XCG' => {
			display_name => {
				'currency' => q(Gulden Caraibeach),
				'few' => q(gulden Caraibeach),
				'one' => q(ghulden Caraibeach),
				'other' => q(gulden Caraibeach),
				'two' => q(ghulden Caraibeach),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Còir tarraing shònraichte),
				'few' => q(còirichean tarraing sònraichte),
				'one' => q(chòir tarraing shònraichte),
				'other' => q(còir tarraing shònraichte),
				'two' => q(chòir tarraing shònraichte),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Aonad airgeadra Eòrpach),
				'few' => q(aonadan airgeadra Eòrpach),
				'one' => q(aonad airgeadra Eòrpach),
				'other' => q(aonad airgeadra Eòrpach),
				'two' => q(aonad airgeadra Eòrpach),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Franc òir Frangach),
				'few' => q(franc òir Frangach),
				'one' => q(fhranc òir Frangach),
				'other' => q(franc òir Frangach),
				'two' => q(fhranc òir Frangach),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Franc UIC Frangach),
				'few' => q(franc UIC Frangach),
				'one' => q(fhranc UIC Frangach),
				'other' => q(franc UIC Frangach),
				'two' => q(fhranc UIC Frangach),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Franc CFA Afraga an Iar),
				'few' => q(franc CFA Afraga an Iar),
				'one' => q(fhranc CFA Afraga an Iar),
				'other' => q(franc CFA Afraga an Iar),
				'two' => q(fhranc CFA Afraga an Iar),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Pallaideam),
				'few' => q(unnsachan tròidh pallaideim),
				'one' => q(unnsa tròidh pallaideim),
				'other' => q(unnsa tròidh pallaideim),
				'two' => q(unnsa tròidh pallaideim),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Franc CFP),
				'few' => q(franc CFP),
				'one' => q(fhranc CFP),
				'other' => q(franc CFP),
				'two' => q(fhranc CFP),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Platanam),
				'few' => q(unnsachan tròidh platanaim),
				'one' => q(unnsa tròidh platanaim),
				'other' => q(unnsa tròidh platanaim),
				'two' => q(unnsa tròidh platanaim),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(Aonad maoine RINET),
				'few' => q(aonadan maoine RINET),
				'one' => q(aonad maoine RINET),
				'other' => q(aonad maoine RINET),
				'two' => q(aonad maoine RINET),
			},
		},
		'XSU' => {
			display_name => {
				'currency' => q(Sucre),
				'few' => q(sucre),
				'one' => q(sucre),
				'other' => q(sucre),
				'two' => q(sucre),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(Còd airgeadra fo dheuchainn),
				'few' => q(aonadan airgeadra fo dheuchainn),
				'one' => q(aonad airgeadra fo dheuchainn),
				'other' => q(aonad airgeadra fo dheuchainn),
				'two' => q(aonad airgeadra fo dheuchainn),
			},
		},
		'XUA' => {
			display_name => {
				'currency' => q(Aonad cunntasachd ADB),
				'few' => q(aonadan cunntasachd ADB),
				'one' => q(aonad cunntasachd ADB),
				'other' => q(aonad cunntasachd ADB),
				'two' => q(aonad cunntasachd ADB),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(Airgeadra neo-aithnichte),
				'few' => q(\(aonadan airgeadra neo–aithnichte\)),
				'one' => q(\(aonad airgeadra neo–aithnichte\)),
				'other' => q(\(aonad airgeadra neo–aithnichte\)),
				'two' => q(\(aonad airgeadra neo–aithnichte\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Dinar Eamanach),
				'few' => q(dinar Eamanach),
				'one' => q(dinar Eamanach),
				'other' => q(dinar Eamanach),
				'two' => q(dhinar Eamanach),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Rial Eamanach),
				'few' => q(rial Eamanach),
				'one' => q(rial Eamanach),
				'other' => q(rial Eamanach),
				'two' => q(rial Eamanach),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Dinar cruaidh Iùgoslabhach \(1966–1990\)),
				'few' => q(dinar cruaidh Iùgoslabhach \(1966–1990\)),
				'one' => q(dinar cruaidh Iùgoslabhach \(1966–1990\)),
				'other' => q(dinar cruaidh Iùgoslabhach \(1966–1990\)),
				'two' => q(dhinar cruaidh Iùgoslabhach \(1966–1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Dinar ùr Iùgoslabhach \(1994–2002\)),
				'few' => q(dinar ùr Iùgoslabhach \(1994–2002\)),
				'one' => q(dinar ùr Iùgoslabhach \(1994–2002\)),
				'other' => q(dinar ùr Iùgoslabhach \(1994–2002\)),
				'two' => q(dhinar ùr Iùgoslabhach \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Dinar iompachail Iùgoslabhach \(1990–1992\)),
				'few' => q(dinar iompachail Iùgoslabhach \(1990–1992\)),
				'one' => q(dinar iompachail Iùgoslabhach \(1990–1992\)),
				'other' => q(dinar iompachail Iùgoslabhach \(1990–1992\)),
				'two' => q(dhinar iompachail Iùgoslabhach \(1990–1992\)),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(Dinar ath-leasaichte Iùgoslabhach \(1992–1993\)),
				'few' => q(dinar ath-leasaichte Iùgoslabhach \(1992–1993\)),
				'one' => q(dinar ath-leasaichte Iùgoslabhach \(1992–1993\)),
				'other' => q(dinar ath-leasaichte Iùgoslabhach \(1992–1993\)),
				'two' => q(dhinar ath-leasaichte Iùgoslabhach \(1992–1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Rand Afraga a Deas \(ionmhasail\)),
				'few' => q(rand Afraga a Deas \(ionmhasail\)),
				'one' => q(rand Afraga a Deas \(ionmhasail\)),
				'other' => q(rand Afraga a Deas \(ionmhasail\)),
				'two' => q(rand Afraga a Deas \(ionmhasail\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rand Afraga a Deas),
				'few' => q(rand Afraga a Deas),
				'one' => q(rand Afraga a Deas),
				'other' => q(rand Afraga a Deas),
				'two' => q(rand Afraga a Deas),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwacha Sàimbitheach \(1968–2012\)),
				'few' => q(kwacha Sàimbitheach \(1968–2012\)),
				'one' => q(kwacha Sàimbitheach \(1968–2012\)),
				'other' => q(kwacha Sàimbitheach \(1968–2012\)),
				'two' => q(kwacha Sàimbitheach \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwacha Sàimbitheach),
				'few' => q(kwacha Sàimbitheach),
				'one' => q(kwacha Sàimbitheach),
				'other' => q(kwacha Sàimbitheach),
				'two' => q(kwacha Sàimbitheach),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Zaïre ùr Zaïreach \(1993–1998\)),
				'few' => q(zaïre ùr Zaïreach \(1993–1998\)),
				'one' => q(zaïre ùr Zaïreach \(1993–1998\)),
				'other' => q(zaïre ùr Zaïreach \(1993–1998\)),
				'two' => q(zaïre ùr Zaïreach \(1993–1998\)),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Zaïre Zaïreach \(1971–1993\)),
				'few' => q(zaïre Zaïreach \(1971–1993\)),
				'one' => q(zaïre Zaïreach \(1971–1993\)),
				'other' => q(zaïre Zaïreach \(1971–1993\)),
				'two' => q(zaïre Zaïreach \(1971–1993\)),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Dolar Sìombabuthach \(1980–2008\)),
				'few' => q(dolaran Sìombabuthach \(1980–2008\)),
				'one' => q(dolar Sìombabuthach \(1980–2008\)),
				'other' => q(dolar Sìombabuthach \(1980–2008\)),
				'two' => q(dholar Sìombabuthach \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Dolar Sìombabuthach \(2009\)),
				'few' => q(dolaran Sìombabuthach \(2009\)),
				'one' => q(dolar Sìombabuthach \(2009\)),
				'other' => q(dolar Sìombabuthach \(2009\)),
				'two' => q(dholar Sìombabuthach \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Dolar Sìombabuthach \(2008\)),
				'few' => q(dolaran Sìombabuthach \(2008\)),
				'one' => q(dolar Sìombabuthach \(2008\)),
				'other' => q(dolar Sìombabuthach \(2008\)),
				'two' => q(dholar Sìombabuthach \(2008\)),
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
							'Chiad',
							'Dàrna',
							'Treas',
							'Ceathr',
							'Còig',
							'Sia',
							'Seachd',
							'Ochd',
							'Naoidh',
							'Deich',
							'Aon Deug',
							'Dàrna Deug'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dhen Chiad Mhìos',
							'dhen Dàrna Mhìos',
							'dhen Treas Mhìos',
							'dhen Cheathramh Mhìos',
							'dhen Chòigeamh Mhìos',
							'dhen t-Siathamh Mhìos',
							'dhen t-Seachdamh Mhìos',
							'dhen Ochdamh Mhìos',
							'dhen Naoidheamh Mhìos',
							'dhen Deicheamh Mhìos',
							'dhen Aonamh Mhìos Deug',
							'dhen Dàrna Mhìos Deug'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					wide => {
						nonleap => [
							'A’ Chiad Mhìos',
							'An Dàrna Mìos',
							'An Treas Mìos',
							'An Ceathramh Mìos',
							'An Còigeamh Mìos',
							'An Siathamh Mìos',
							'An Seachdamh Mìos',
							'An t-Ochdamh Mìos',
							'An Naoidheamh Mìos',
							'An Deicheamh Mìos',
							'An t-Aonamh Mìos Deug',
							'An Dàrna Mìos Deug'
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
							'Faoi',
							'Gearr',
							'Màrt',
							'Gibl',
							'Cèit',
							'Ògmh',
							'Iuch',
							'Lùna',
							'Sult',
							'Dàmh',
							'Samh',
							'Dùbh'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'dhen Fhaoilleach',
							'dhen Ghearran',
							'dhen Mhàrt',
							'dhen Ghiblean',
							'dhen Chèitean',
							'dhen Ògmhios',
							'dhen Iuchar',
							'dhen Lùnastal',
							'dhen t-Sultain',
							'dhen Dàmhair',
							'dhen t-Samhain',
							'dhen Dùbhlachd'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'F',
							'G',
							'M',
							'G',
							'C',
							'Ò',
							'I',
							'L',
							'S',
							'D',
							'S',
							'D'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Am Faoilleach',
							'An Gearran',
							'Am Màrt',
							'An Giblean',
							'An Cèitean',
							'An t-Ògmhios',
							'An t-Iuchar',
							'An Lùnastal',
							'An t-Sultain',
							'An Dàmhair',
							'An t-Samhain',
							'An Dùbhlachd'
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
						mon => 'DiL',
						tue => 'DiM',
						wed => 'DiC',
						thu => 'Dia',
						fri => 'Dih',
						sat => 'DiS',
						sun => 'DiD'
					},
					short => {
						mon => 'Lu',
						tue => 'Mà',
						wed => 'Ci',
						thu => 'Da',
						fri => 'hA',
						sat => 'Sa',
						sun => 'Dò'
					},
					wide => {
						mon => 'DiLuain',
						tue => 'DiMàirt',
						wed => 'DiCiadain',
						thu => 'DiarDaoin',
						fri => 'DihAoine',
						sat => 'DiSathairne',
						sun => 'DiDòmhnaich'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'C',
						thu => 'A',
						fri => 'H',
						sat => 'S',
						sun => 'D'
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
					abbreviated => {0 => 'C1',
						1 => 'C2',
						2 => 'C3',
						3 => 'C4'
					},
					wide => {0 => '1d chairteal',
						1 => '2na cairteal',
						2 => '3s cairteal',
						3 => '4mh cairteal'
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
					'am' => q{m},
					'pm' => q{f},
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
				'0' => 'RC',
				'1' => 'AD'
			},
			narrow => {
				'0' => 'R',
				'1' => 'A'
			},
			wide => {
				'0' => 'Ro Chrìosta',
				'1' => 'An dèidh Chrìosta'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => 'Ro PnS',
				'1' => 'Mínguó'
			},
			wide => {
				'0' => 'Ro Ph. na Sìne'
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
			'full' => q{EEEE, d'mh' MMMM r(U)},
			'long' => q{d'mh' MMMM r(U)},
			'medium' => q{d MMM r},
			'short' => q{d/M/r},
		},
		'generic' => {
			'full' => q{EEEE, d'mh' MMMM y G},
			'long' => q{d'mh' MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d'mh' MMMM y},
			'long' => q{d'mh' MMMM y},
			'medium' => q{d'mh' MMM y},
			'short' => q{dd/MM/y},
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
		'roc' => {
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'chinese' => {
			'full' => q{{1} {0}},
			'long' => q{{1} {0}},
			'medium' => q{{1} {0}},
			'short' => q{{1} {0}},
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
			Bh => q{hB},
			Bhm => q{h:mmB},
			Bhms => q{h:mm:ssB},
			EBhm => q{E h:mmB},
			EBhms => q{E h:mm:ssB},
			Ed => q{E d},
			Gy => q{r(U)},
			GyMMM => q{LLL r(U)},
			GyMMMEd => q{E, d'mh' MMM r(U)},
			GyMMMd => q{d'mh' MMM r},
			MEd => q{E, d/M},
			MMMEd => q{E, d'mh' MMM},
			MMMMd => q{d'mh' MMMM},
			MMMd => q{d'mh' MMM},
			Md => q{d/M},
			UM => q{L/U},
			UMMM => q{LLL U},
			UMMMd => q{d'mh' MMM U},
			UMd => q{d/M/U},
			h => q{ha},
			hm => q{h:mma},
			hms => q{h:mm:ssa},
			yMd => q{d/M/r},
			yyyyM => q{L/r},
			yyyyMEd => q{E, d/M/r},
			yyyyMMM => q{LLL r(U)},
			yyyyMMMEd => q{E, d'mh' MMM r(U)},
			yyyyMMMM => q{LLLL r(U)},
			yyyyMMMd => q{d'mh' MMM r},
			yyyyMd => q{d/M/r},
			yyyyQQQ => q{QQQ r(U)},
			yyyyQQQQ => q{QQQQ r(U)},
		},
		'generic' => {
			Bh => q{hB},
			Bhm => q{h:mmB},
			Bhms => q{h:mm:ssB},
			EBhm => q{E h:mmB},
			EBhms => q{E h:mm:ssB},
			Ed => q{E, d},
			Ehm => q{E h:mma},
			Ehms => q{E h:mm:ssa},
			Gy => q{y G},
			GyMMM => q{LLL y G},
			GyMMMEd => q{E, d'mh' MMM y G},
			GyMMMd => q{d'mh' MMM y G},
			GyMd => q{d/M/y GGGGG},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMd => q{d'mh' MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			h => q{ha},
			hm => q{h:mma},
			hms => q{h:mm:ssa},
			y => q{y G},
			yMEd => q{E, d/M/y},
			yMM => q{LL/y},
			yMMM => q{LLL y},
			yMMMM => q{LLLL y},
			yyyy => q{y G},
			yyyyM => q{L/y GGGGG},
			yyyyMEd => q{E, d/M/y GGGGG},
			yyyyMMM => q{LLL y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{LLLL y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{d/M/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Bh => q{hB},
			Bhm => q{h:mmB},
			Bhms => q{h:mm:ssB},
			EBhm => q{E h:mmB},
			EBhms => q{E h:mm:ssB},
			Ed => q{E, d},
			Ehm => q{E h:mma},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{LLL y G},
			GyMMMEd => q{E, d'mh' MMM y G},
			GyMMMd => q{d'mh' MMM y G},
			GyMd => q{d/M/y G},
			MEd => q{E, d/M},
			MMMEd => q{E, d MMM},
			MMMMW => q{'seachdain' W MMMM},
			MMMMd => q{d'mh' MMMM},
			MMMd => q{d MMM},
			MMdd => q{dd/MM},
			Md => q{d/M},
			h => q{ha},
			hm => q{h:mma},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mma v},
			yM => q{L/y},
			yMEd => q{E, d/M/y},
			yMM => q{LL/y},
			yMMM => q{LLL Y},
			yMMMEd => q{E, d MMM y},
			yMMMM => q{LLLL y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'seachdain' w 'dhe' Y},
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
		'chinese' => {
			H => {
				H => q{HH – HH},
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
				M => q{L – L},
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
				d => q{d MMM – d},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			d => {
				d => q{d – d},
			},
			h => {
				a => q{ha – ha},
				h => q{h – ha},
			},
			hm => {
				a => q{h:mma – h:mma},
				h => q{h:mm – h:mma},
				m => q{h:mm – h:mma},
			},
			hmv => {
				a => q{h:mma – h:mma v},
				h => q{h:mm – h:mma v},
				m => q{h:mm – h:mma v},
			},
			hv => {
				a => q{ha – ha v},
				h => q{h – ha v},
			},
			y => {
				y => q{U – U},
			},
			yM => {
				M => q{L/y – L/y},
				y => q{L/y – L/y},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{LLL – LLL U},
				y => q{LLL U – LLL U},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM, U},
				d => q{E, d MMM – E, d MMM, U},
				y => q{E, d MMM, U – E, d MMM, U},
			},
			yMMMM => {
				M => q{LLLL – LLLL U},
				y => q{LLLL U – LLLL U},
			},
			yMMMd => {
				M => q{d MMM – d MMM, U},
				d => q{d MMM – d, U},
				y => q{d MMM, U – d MMM, U},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
		'generic' => {
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
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{L/y GGGGG – L/y GGGGG},
				M => q{L/y – L/y GGGGG},
				y => q{L/y – L/y GGGGG},
			},
			GyMEd => {
				G => q{E, d/M/y GGGGG – E, d/M/y GGGGG},
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			GyMMM => {
				G => q{LLL y G – LLL y G},
				M => q{LLL – LLL y G},
				y => q{LLL y – LLL y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
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
				G => q{d/M/y GGGGG – d/M/y GGGGG},
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
			},
			H => {
				H => q{HH – HH},
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
				M => q{L – L},
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
				d => q{d – d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			d => {
				d => q{d – d},
			},
			h => {
				a => q{ha – ha},
				h => q{h – ha},
			},
			hm => {
				a => q{h:mma – h:mma},
				h => q{h:mm – h:mma},
				m => q{h:mm – h:mma},
			},
			hmv => {
				a => q{h:mma – h:mma v},
				h => q{h:mm – h:mma v},
				m => q{h:mm – h:mma v},
			},
			hv => {
				a => q{ha – ha v},
				h => q{h – ha v},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{L/y – L/y GGGGG},
				y => q{L/y – L/y GGGGG},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y GGGGG},
				d => q{E, d/M/y – E, d/M/y GGGGG},
				y => q{E, d/M/y – E, d/M/y GGGGG},
			},
			yMMM => {
				M => q{LLL – LLL y G},
				y => q{LLL y – LLL y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			yMMMM => {
				M => q{LLLL – LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{d MMM – d MMM y G},
				d => q{d – d MMM y G},
				y => q{d MMM y – d MMM y G},
			},
			yMd => {
				M => q{d/M/y – d/M/y GGGGG},
				d => q{d/M/y – d/M/y GGGGG},
				y => q{d/M/y – d/M/y GGGGG},
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
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{L/y G – L/y G},
				M => q{L/y – L/y G},
				y => q{L/y – L/y G},
			},
			GyMEd => {
				G => q{E, d/M/y G– E, d/M/y G},
				M => q{E, d/M/y – E, d/M/y G},
				d => q{E, d/M/y – E, d/M/y G},
				y => q{E, d/M/y – E, d/M/y G},
			},
			GyMMM => {
				G => q{LLL y G – LLL y G},
				M => q{LLL – LLL y G},
				y => q{LLL y – LLL y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
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
				G => q{d/M/y G – d/M/y G},
				M => q{d/M/y – d/M/y G},
				d => q{d/M/y – d/M/y G},
				y => q{d/M/y – d/M/y G},
			},
			H => {
				H => q{HH – HH},
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
				M => q{L – L},
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
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d – d MMM},
			},
			Md => {
				M => q{d/M – d/M},
				d => q{d/M – d/M},
			},
			d => {
				d => q{d – d},
			},
			h => {
				a => q{ha – ha},
				h => q{h – ha},
			},
			hm => {
				a => q{h:mma – h:mma},
				h => q{h:mm – h:mma},
				m => q{h:mm – h:mma},
			},
			hmv => {
				a => q{h:mma – h:mma v},
				h => q{h:mm – h:mma v},
				m => q{h:mm – h:mma v},
			},
			hv => {
				a => q{ha – ha v},
				h => q{h – ha v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{L/y – L/y},
				y => q{L/y – L/y},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{LLL – LLL y},
				y => q{LLL y – LLL y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y},
				d => q{E, d MMM – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{LLLL – LLLL y},
				y => q{LLLL y – LLLL y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
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
			'solarTerms' => {
				'format' => {
					'abbreviated' => {
						0 => q(toiseach an earraich),
						1 => q(an t-uisge),
						2 => q(dùsgadh nam biastag),
						3 => q(co-fhad-thràth an earraich),
						4 => q(soilleir),
						5 => q(uisge a’ ghràin),
						6 => q(toiseach an t-samhraidh),
						7 => q(gràn làn),
						8 => q(gràn abaich),
						9 => q(grian-stad an t-samhraidh),
						10 => q(teas beag),
						11 => q(teas mòr),
						12 => q(toiseach an fhoghair),
						13 => q(deireadh an teasa),
						14 => q(driùchd geal),
						15 => q(co-fhad-thràth an fhoghair),
						16 => q(driùchd fuar),
						17 => q(teachd an reòthaidh),
						18 => q(toiseach a’ gheamhraidh),
						19 => q(sneachd beag),
						20 => q(sneachd mòr),
						21 => q(grian-stad a’ gheamhraidh),
						22 => q(fuachd bheag),
						23 => q(fuachd mhòr),
					},
					'narrow' => {
						0 => q(toiseach earraich),
						2 => q(dùsgadh bhiastagan),
						3 => q(co-fhad-thràth earraich),
						5 => q(uisge gràin),
						6 => q(toiseach samhraidh),
						9 => q(grian-stad samhraidh),
						12 => q(toiseach foghair),
						13 => q(deireadh teasa),
						15 => q(co-fhad-thràth foghair),
						17 => q(teachd reòthaidh),
						18 => q(toiseach geamhraidh),
						21 => q(grian-stad geamhraidh),
					},
					'wide' => {
						7 => q(an gràn làn),
						8 => q(an gràn abaich),
						10 => q(an teas beag),
						11 => q(an teas mòr),
						14 => q(an driùchd geal),
						16 => q(an driùchd fuar),
						19 => q(an sneachd beag),
						20 => q(an sneachd mòr),
						22 => q(an fhuachd bheag),
						23 => q(an fhuachd mhòr),
					},
				},
			},
			'zodiacs' => {
				'format' => {
					'abbreviated' => {
						0 => q(Radan),
						1 => q(Damh),
						2 => q(Tìgear),
						3 => q(Coinean),
						4 => q(Dràgon),
						5 => q(Nathair),
						6 => q(Each),
						7 => q(Gobhar),
						8 => q(Muncaidh),
						9 => q(Coileach),
						10 => q(Cù),
						11 => q(Muc),
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
		regionFormat => q(Tìde samhraidh: {0}),
		regionFormat => q(Bun-àm: {0}),
		'Acre' => {
			long => {
				'daylight' => q#Tìde samhraidh Acre#,
				'generic' => q#Àm Acre#,
				'standard' => q#Bun-àm Acre#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Àm Afghanastàin#,
			},
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abäba#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmarà#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dàr as-Salàm#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Diobùtaidh#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Aaiún#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Hannsaborgh#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#N’Djaména#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Àm Meadhan Afraga#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Àm Afraga an Ear#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Àm Afraga a Deas#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Tìde Samhraidh Afraga an Iar#,
				'generic' => q#Àm Afraga an Iar#,
				'standard' => q#Bun-àm Afraga an Iar#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Tìde samhraidh Alaska#,
				'generic' => q#Àm Alaska#,
				'standard' => q#Bun-àm Alaska#,
			},
			short => {
				'daylight' => q#AKDT#,
				'generic' => q#AKT#,
				'standard' => q#AKST#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Tìde samhraidh Almaty#,
				'generic' => q#Àm Almaty#,
				'standard' => q#Bun-àm Almaty#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Tìde samhraidh Amasoin#,
				'generic' => q#Àm Amasoin#,
				'standard' => q#Bun-àm Amasoin#,
			},
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguillia#,
		},
		'America/Antigua' => {
			exemplarCity => q#Aintìoga#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaína#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Río Gallegos#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucumán#,
		},
		'America/Aruba' => {
			exemplarCity => q#Arùba#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Belize' => {
			exemplarCity => q#A’ Bheilìs#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Cayman' => {
			exemplarCity => q#Caimean#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Córdoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Costa Rìcea#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
		},
		'America/Dominica' => {
			exemplarCity => q#Doiminicea#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepé#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#An Salbhador#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Glasbaidh#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#An Turc Mhòr#,
		},
		'America/Grenada' => {
			exemplarCity => q#Greanàda#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadalup#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatamala#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guidheàna#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuuvik#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Diameuga#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
		},
		'America/Martinique' => {
			exemplarCity => q#Mairtinic#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Cathair Mheagsago#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Montsarat#,
		},
		'America/New_York' => {
			exemplarCity => q#Nuadh Eabhrac#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port na Spàinne#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Porto Rìceo#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Kangiqliniq#,
		},
		'America/Resolute' => {
			exemplarCity => q#Qausuittuq#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarém#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint Barthélemy#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Naomh Crìstean#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Naomh Lùisea#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Naomh Bhionsant#,
		},
		'America/Thule' => {
			exemplarCity => q#Qaanaaq#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Tìde samhraidh Meadhan Aimeireaga#,
				'generic' => q#Àm Meadhan Aimeireaga#,
				'standard' => q#Bun-àm Meadhan Aimeireaga#,
			},
			short => {
				'daylight' => q#CDT#,
				'generic' => q#CT#,
				'standard' => q#CST#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Tìde samhraidh Aimeireaga an Ear#,
				'generic' => q#Àm Aimeireaga an Ear#,
				'standard' => q#Bun-àm Aimeireaga an Ear#,
			},
			short => {
				'daylight' => q#EDT#,
				'generic' => q#ET#,
				'standard' => q#EST#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Tìde samhraidh Monadh Aimeireaga#,
				'generic' => q#Àm Monadh Aimeireaga#,
				'standard' => q#Bun-àm Monadh Aimeireaga#,
			},
			short => {
				'daylight' => q#MDT#,
				'generic' => q#MT#,
				'standard' => q#MST#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Tìde samhraidh a’ Chuain Shèimh#,
				'generic' => q#Àm a’ Chuain Shèimh#,
				'standard' => q#Bun-àm a’ Chuain Shèimh#,
			},
			short => {
				'daylight' => q#PDT#,
				'generic' => q#PT#,
				'standard' => q#PST#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Tìde samhraidh Anadyr#,
				'generic' => q#Àm Anadyr#,
				'standard' => q#Bun-àm Anadyr#,
			},
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Eilean MhicGuaire#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Tìde samhraidh Apia#,
				'generic' => q#Àm Apia#,
				'standard' => q#Bun-àm Apia#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#Tìde samhraidh Aqtau#,
				'generic' => q#Àm Aqtau#,
				'standard' => q#Bun-àm Aqtau#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#Tìde samhraidh Aqtobe#,
				'generic' => q#Àm Aqtobe#,
				'standard' => q#Bun-àm Aqtobe#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Tìde samhraidh Arabach#,
				'generic' => q#Àm Arabach#,
				'standard' => q#Bun-àm Arabach#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Tìde samhraidh na h-Argantaine#,
				'generic' => q#Àm na h-Argantaine#,
				'standard' => q#Bun-àm na h-Argantaine#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Tìde samhraidh na h-Argantaine Siaraich#,
				'generic' => q#Àm na h-Argantaine Siaraich#,
				'standard' => q#Bun-àm na h-Argantaine Siaraich#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Tìde samhraidh Airmeinia#,
				'generic' => q#Àm Airmeinia#,
				'standard' => q#Bun-àm Airmeinia#,
			},
		},
		'Asia/Amman' => {
			exemplarCity => q#Ammān#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtöbe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Aşgabat#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Baghdād#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bachrain#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Biškek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brùnaigh#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dušanbe#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gàsa#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Khovd#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Ierusalam#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karācī#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Cuibhèit#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macàthu#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pyeongyang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Catar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Qostanaı#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Qızılorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangun#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Cathair Ho Chi Minh#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singeapòr#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Toškent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#T’bilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Tehrān#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tōkyō#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Ürümqi#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Viang Chan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Tìde samhraidh a’ Chuain Shiar#,
				'generic' => q#Àm a’ Chuain Shiar#,
				'standard' => q#Bun-àm a’ Chuain Shiar#,
			},
			short => {
				'daylight' => q#ADT#,
				'generic' => q#AT#,
				'standard' => q#AST#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Ponta Delgada#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bearmùda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Na h-Eileanan Canàrach#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#An Ceap Uaine#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Fàro#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Seòrsea a Deas#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Eilean Naomh Eilidh#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sidni#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Tìde samhraidh Meadhan Astràilia#,
				'generic' => q#Àm Meadhan Astràilia#,
				'standard' => q#Bun-àm Meadhan Astràilia#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Tìde samhraidh Meadhan Astràilia an Iar#,
				'generic' => q#Àm Meadhan Astràilia an Iar#,
				'standard' => q#Bun-àm Meadhan Astràilia an Iar#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Tìde samhraidh Astràilia an Ear#,
				'generic' => q#Àm Astràilia an Ear#,
				'standard' => q#Bun-àm Astràilia an Ear#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Tìde samhraidh Astràilia an Iar#,
				'generic' => q#Àm Astràilia an Iar#,
				'standard' => q#Bun-àm Astràilia an Iar#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Tìde samhraidh Asarbaideàin#,
				'generic' => q#Àm Asarbaideàin#,
				'standard' => q#Bun-àm Asarbaideàin#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Tìde samhraidh nan Eileanan Asorach#,
				'generic' => q#Àm nan Eileanan Asorach#,
				'standard' => q#Bun-àm nan Eileanan Asorach#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Tìde samhraidh Bangladais#,
				'generic' => q#Àm Bangladais#,
				'standard' => q#Bun-àm Bangladais#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Àm Butàin#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Àm Boilibhia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Tìde samhraidh Bhrasília#,
				'generic' => q#Àm Bhrasília#,
				'standard' => q#Bun-àm Bhrasília#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Àm Bhrùnaigh Dàr as-Salàm#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Tìde samhraidh a’ Chip Uaine#,
				'generic' => q#Àm a’ Chip Uaine#,
				'standard' => q#Bun-àm a’ Chip Uaine#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#Àm Chasey#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Àm Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Tìde samhraidh Chatham#,
				'generic' => q#Àm Chatham#,
				'standard' => q#Bun-àm Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Tìde samhraidh na Sile#,
				'generic' => q#Àm na Sile#,
				'standard' => q#Bun-àm na Sile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Tìde samhraidh na Sìne#,
				'generic' => q#Àm na Sìne#,
				'standard' => q#Bun-àm na Sìne#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Àm Eilean na Nollaig#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Àm Eileanan Chocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Tìde samhraidh Coloimbia#,
				'generic' => q#Àm Coloimbia#,
				'standard' => q#Bun-àm Coloimbia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Leth-thìde samhraidh Eileanan Cook#,
				'generic' => q#Àm Eileanan Cook#,
				'standard' => q#Bun-àm Eileanan Cook#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Tìde samhraidh Cùba#,
				'generic' => q#Àm Cùba#,
				'standard' => q#Bun-àm Cùba#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Àm Dhavis#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Àm Dumont-d’Urville#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Àm Thìomor an Ear#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Tìde samhraidh Eilean na Càisge#,
				'generic' => q#Àm Eilean na Càisge#,
				'standard' => q#Bun-àm Eilean na Càisge#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Àm Eacuadoir#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Àm Uile-choitcheann Co-òrdanaichte#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Baile neo-aithnichte#,
		},
		'Europe/Athens' => {
			exemplarCity => q#An Àithne#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#A’ Bhruiseal#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chișinău#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Beirbh#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Baile Àtha Cliath#,
			long => {
				'daylight' => q#Bun-àm na h-Èireann#,
			},
			short => {
				'daylight' => q#TSÈ (Èirinn)#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Diobraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Geàrnsaidh#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Eilean Mhanainn#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Deàrsaidh#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/London' => {
			exemplarCity => q#Dùn Èideann/Lunnainn#,
			long => {
				'daylight' => q#Tìde samhraidh Bhreatainn#,
			},
			short => {
				'daylight' => q#TSB#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lugsamburg#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Mosgo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Paras#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Pràg#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Rīga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#An Ròimh#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofiya#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tiranë#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#A’ Bhatacan#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Tìde samhraidh Meadhan na Roinn-Eòrpa#,
				'generic' => q#Àm Meadhan na Roinn-Eòrpa#,
				'standard' => q#Bun-àm Meadhan na Roinn-Eòrpa#,
			},
			short => {
				'daylight' => q#CEST#,
				'generic' => q#CET#,
				'standard' => q#CET#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Tìde samhraidh na Roinn-Eòrpa an Ear#,
				'generic' => q#Àm na Roinn-Eòrpa an Ear#,
				'standard' => q#Bun-àm na Roinn-Eòrpa an Ear#,
			},
			short => {
				'daylight' => q#EEST#,
				'generic' => q#EET#,
				'standard' => q#EET#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Àm na Roinn-Eòrpa nas fhaide ear#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Tìde samhraidh na Roinn-Eòrpa an Iar#,
				'generic' => q#Àm na Roinn-Eòrpa an Iar#,
				'standard' => q#Bun-àm na Roinn-Eòrpa an Iar#,
			},
			short => {
				'daylight' => q#WEST#,
				'generic' => q#WET#,
				'standard' => q#WET#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Tìde samhraidh nan Eileanan Fàclannach#,
				'generic' => q#Àm nan Eileanan Fàclannach#,
				'standard' => q#Bun-àm nan Eileanan Fàclannach#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Tìde samhraidh Fìdi#,
				'generic' => q#Àm Fìdi#,
				'standard' => q#Bun-àm Fìdi#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Àm Guidheàna na Frainge#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Àm Deasach agus Antartaigeach na Frainge#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich Mean Time#,
			},
			short => {
				'standard' => q#GMT#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Àm Ghalapagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Àm Ghambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Tìde samhraidh na Cairtbheile#,
				'generic' => q#Àm na Cairtbheile#,
				'standard' => q#Bun-àm na Cairtbheile#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Àm Eileanan Ghileabairt#,
			},
		},
		'Greenland' => {
			long => {
				'daylight' => q#Tìde samhraidh na Graonlainne#,
				'generic' => q#Àm na Graonlainne#,
				'standard' => q#Bun-àm na Graonlainne#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Tìde samhraidh na Graonlainn an Ear#,
				'generic' => q#Àm na Graonlainn an Ear#,
				'standard' => q#Bun-àm na Graonlainn an Ear#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Tìde samhraidh na Graonlainn an Iar#,
				'generic' => q#Àm na Graonlainn an Iar#,
				'standard' => q#Bun-àm na Graonlainn an Iar#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Àm Guam#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Àm a’ Chamais#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Àm Guidheàna#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Tìde Samhraidh nan Eileanan Hawai’i ’s Aleutach#,
				'generic' => q#Àm nan Eileanan Hawai’i ’s Aleutach#,
				'standard' => q#Bun-àm nan Eileanan Hawai’i ’s Aleutach#,
			},
			short => {
				'daylight' => q#HADT#,
				'generic' => q#HAT#,
				'standard' => q#HAST#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Tìde samhraidh Hong Kong#,
				'generic' => q#Àm Hong Kong#,
				'standard' => q#Bun-àm Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Tìde samhraidh Hovd#,
				'generic' => q#Àm Hovd#,
				'standard' => q#Bun-àm Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Àm nan Innseachan#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Nollaig#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kergelenn#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Na h-Eileanan Mhaladaibh#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Na h-Eileanan Mhoiriseas#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Àm Cuan nan Innseachan#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Àm Sìn-Innseanach#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Àm Meadhan nan Innd-Innse#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Àm nan Innd-Innse an Ear#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Àm nan Innd-Innse an Iar#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Tìde samhraidh Ioràin#,
				'generic' => q#Àm Ioràin#,
				'standard' => q#Bun-àm Ioràin#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Tìde Samhraidh Irkutsk#,
				'generic' => q#Àm Irkutsk#,
				'standard' => q#Bun-àm Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Tìde samhraidh Iosrael#,
				'generic' => q#Àm Iosrael#,
				'standard' => q#Bun-àm Iosrael#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Tìde samhraidh na Seapaine#,
				'generic' => q#Àm na Seapaine#,
				'standard' => q#Bun-àm na Seapaine#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Tìde samhraidh Petropavlovsk-Kamchatsky#,
				'generic' => q#Àm Petropavlovsk-Kamchatsky#,
				'standard' => q#Bun-àm Petropavlovsk-Kamchatsky#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#Àm Casachstàin#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Àm Casachstàin an Ear#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Àm Casachstàin an Iar#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Tìde samhraidh Choirèa#,
				'generic' => q#Àm Choirèa#,
				'standard' => q#Bun-àm Choirèa#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Àm Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Tìde samhraidh Krasnoyarsk#,
				'generic' => q#Àm Krasnoyarsk#,
				'standard' => q#Bun-àm Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Àm Cìorgastain#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#Àm Lanca#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Àm Eileanan Teraina#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Tìde samhraidh Lord Howe#,
				'generic' => q#Àm Lord Howe#,
				'standard' => q#Bun-àm Lord Howe#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#Tìde samhraidh Macàthu#,
				'generic' => q#Àm Macàthu#,
				'standard' => q#Bun-àm Macàthu#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Tìde Samhraidh Magadan#,
				'generic' => q#Àm Magadan#,
				'standard' => q#Bun-àm Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Àm Mhalaidhsea#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Àm nan Eileanan Mhaladaibh#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Àm Eileanan a’ Mharcais#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Àm Eileanan Mharshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Tìde samhraidh nan Eileanan Mhoiriseas#,
				'generic' => q#Àm nan Eileanan Mhoiriseas#,
				'standard' => q#Bun-àm nan Eileanan Mhoiriseas#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Àm Mhawson#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Tìde samhraidh a’ Chuain Shèimh Mheagsago#,
				'generic' => q#Àm a’ Chuain Shèimh Mheagsago#,
				'standard' => q#Bun-àm a’ Chuain Shèimh Mheagsago#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Tìde samhraidh Ulan Bator#,
				'generic' => q#Àm Ulan Bator#,
				'standard' => q#Bun-àm Ulan Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Tìde samhraidh Mhosgo#,
				'generic' => q#Àm Mhosgo#,
				'standard' => q#Bun-àm Mhosgo#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Àm Miànmar#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Àm Nabhru#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Àm Neapàl#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Tìde samhraidh Chailleann Nuaidh#,
				'generic' => q#Àm Chailleann Nuaidh#,
				'standard' => q#Bun-àm Chailleann Nuaidh#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Tìde samhraidh Shealainn Nuaidh#,
				'generic' => q#Àm Shealainn Nuaidh#,
				'standard' => q#Bun-àm Shealainn Nuaidh#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Tìde samhraidh Talamh an Èisg#,
				'generic' => q#Àm Talamh an Èisg#,
				'standard' => q#Bun-àm Talamh an Èisg#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Àm Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Tìde samhraidh Eilein Norfolk#,
				'generic' => q#Àm Eilein Norfolk#,
				'standard' => q#Bun-àm Eilein Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Tìde Samhraidh Fernando de Noronha#,
				'generic' => q#Àm Fernando de Noronha#,
				'standard' => q#Bun-àm Fernando de Noronha#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#Àm nan Eileanan Mairianach a Tuath#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Tìde samhraidh Novosibirsk#,
				'generic' => q#Àm Novosibirsk#,
				'standard' => q#Bun-àm Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Tìde samhraidh Omsk#,
				'generic' => q#Àm Omsk#,
				'standard' => q#Bun-àm Omsk#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Rapa Nui#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fìdi#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galápagos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Mangareva#,
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
			exemplarCity => q#Eileanan a’ Mharcais#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Nabhru#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palabh#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Peit a’ Chàirn#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Uallas#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Tìde samhraidh Pagastàin#,
				'generic' => q#Àm Pagastàin#,
				'standard' => q#Bun-àm Pagastàin#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Àm Palabh#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Àm Gini Nuaidh Paputhaiche#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Tìde samhraidh Paraguaidh#,
				'generic' => q#Àm Paraguaidh#,
				'standard' => q#Bun-àm Paraguaidh#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Tìde samhraidh Pearù#,
				'generic' => q#Àm Pearù#,
				'standard' => q#Bun-àm Pearù#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Tìde samhraidh nan Eilean Filipineach#,
				'generic' => q#Àm nan Eilean Filipineach#,
				'standard' => q#Bun-àm nan Eilean Filipineach#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Àm Eileanan Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Tìde Samhraidh Saint Pierre agus Miquelon#,
				'generic' => q#Àm Saint Pierre agus Miquelon#,
				'standard' => q#Bun-àm Saint Pierre agus Miquelon#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Àm Peit a’ Chàirn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Àm Pohnpei#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Àm Pyeongyang#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#Tìde samhraidh Qızılorda#,
				'generic' => q#Àm Qızılorda#,
				'standard' => q#Bun-àm Qızılorda#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Àm Reunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Àm Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Tìde samhraidh Sakhalin#,
				'generic' => q#Àm Sakhalin#,
				'standard' => q#Bun-àm Sakhalin#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Tìde samhraidh Samara#,
				'generic' => q#Àm Samara#,
				'standard' => q#Bun-àm Samara#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Tìde samhraidh Samotha#,
				'generic' => q#Àm Samotha#,
				'standard' => q#Bun-àm Samotha#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Àm nan Eileanan Sheiseall#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Àm Singeapòr#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Àm Eileanan Sholaimh#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Àm Seòrsea a Deas#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Àm Suranaim#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Àm Shyowa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Àm Tahiti#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Tìde samhraidh Taipei#,
				'generic' => q#Àm Taipei#,
				'standard' => q#Bun-àm Taipei#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Àm Taidigeastàin#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Àm Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tìde samhraidh Tonga#,
				'generic' => q#Àm Tonga#,
				'standard' => q#Bun-àm Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Àm Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Tìde samhraidh Turcmanastàin#,
				'generic' => q#Àm Turcmanastàin#,
				'standard' => q#Bun-àm Turcmanastàin#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Àm Tubhalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Tìde samhraidh Uruguaidh#,
				'generic' => q#Àm Uruguaidh#,
				'standard' => q#Bun-àm Uruguaidh#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Tìde samhraidh Usbagastàn#,
				'generic' => q#Àm Usbagastàn#,
				'standard' => q#Bun-àm Usbagastàn#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Tìde samhraidh Vanuatu#,
				'generic' => q#Àm Vanuatu#,
				'standard' => q#Bun-àm Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Àm na Bheiniseala#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Tìde Samhraidh Vladivostok#,
				'generic' => q#Àm Vladivostok#,
				'standard' => q#Bun-àm Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Tìde samhraidh Volgograd#,
				'generic' => q#Àm Volgograd#,
				'standard' => q#Bun-àm Volgograd#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Àm Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Àm Eilean Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Àm Uallas agus Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Tìde samhraidh Yakutsk#,
				'generic' => q#Àm Yakutsk#,
				'standard' => q#Bun-àm Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Tìde samhraidh Yekaterinburg#,
				'generic' => q#Àm Yekaterinburg#,
				'standard' => q#Bun-àm Yekaterinburg#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Àm Yukon#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
