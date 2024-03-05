=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Qu - Package for language Quechua

=cut

package Locale::CLDR::Locales::Qu;
# This file auto generated from Data\common\main\qu.xml
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
has 'valid_algorithmic_formats' => (
    is => 'ro',
    isa => ArrayRef,
    init_arg => undef,
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal','spellout-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minusu →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(chusaq),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(huk),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(iskay),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(kinsa),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(tawa),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(phisqa),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(suqta),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(qanchis),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(pusaq),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(isqun),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(chunka[ →%%spellout-cardinal-with→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(←← chunka[ →%%spellout-cardinal-with→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←← pachak[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←← waranqa[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← hunu[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← lluna[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← trilionu[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← kvadrilionu[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0.#=),
				},
				'Inf' => {
					divisor => q(1),
					rule => q(mana usay),
				},
				'NaN' => {
					divisor => q(1),
					rule => q(mana yupay),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← comma →→),
				},
				'max' => {
					divisor => q(1),
					rule => q(←← comma →→),
				},
			},
		},
		'spellout-cardinal-with' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=-ni-yuq),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal=-yuq),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(=%spellout-cardinal=-ni-yuq),
				},
				'max' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(=%spellout-cardinal=-ni-yuq),
				},
			},
		},
		'spellout-numbering' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=),
				},
			},
		},
		'spellout-numbering-year' => {
			'public' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
			},
		},
		'spellout-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minusu →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal=-ñiqin),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
			},
		},
    } },
);

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'ab' => 'Abjasia',
 				'ace' => 'Achinese',
 				'ada' => 'Adangme',
 				'ady' => 'Adyghe',
 				'af' => 'Afrikaans Simi',
 				'agq' => 'Aghem Simi',
 				'ain' => 'Ainu',
 				'ak' => 'Akan Simi',
 				'ale' => 'Aleut',
 				'alt' => 'Altai Meridional',
 				'am' => 'Amarico Simi',
 				'an' => 'Aragonesa',
 				'ann' => 'Obolo Simi',
 				'anp' => 'Angika',
 				'ar' => 'Arabe Simi',
 				'arn' => 'Mapuche Simi',
 				'arp' => 'Arapaho',
 				'ars' => 'Árabe Najdi Simi',
 				'as' => 'Asames Simi',
 				'asa' => 'Asu Simi',
 				'ast' => 'Asturiano Simi',
 				'atj' => 'Atikamekw',
 				'av' => 'Avaric',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymara Simi',
 				'az' => 'Azerbaiyano Simi',
 				'az@alt=short' => 'Azerí Simi',
 				'ba' => 'Baskir Simi',
 				'ban' => 'Balines Simi',
 				'bas' => 'Basaa Simi',
 				'be' => 'Bielorruso Simi',
 				'bem' => 'Bemba Simi',
 				'bez' => 'Bena Simi',
 				'bg' => 'Bulgaro Simi',
 				'bgc' => 'Haryanvi',
 				'bho' => 'Bhojpuri',
 				'bi' => 'Bislama',
 				'bin' => 'Bini',
 				'bla' => 'Siksiká Simi',
 				'bm' => 'Bambara Simi',
 				'bn' => 'Bangla Simi',
 				'bo' => 'Tibetano Simi',
 				'br' => 'Breton Simi',
 				'brx' => 'Bodo Simi',
 				'bs' => 'Bosnio Simi',
 				'bug' => 'Buginese',
 				'byn' => 'Blin',
 				'ca' => 'Catalan Simi',
 				'cay' => 'Cayugá',
 				'ccp' => 'Chakma Simi',
 				'ce' => 'Checheno Simi',
 				'ceb' => 'Cebuano Simi',
 				'cgg' => 'Kiga Simi',
 				'ch' => 'Chamorro Simi',
 				'chk' => 'Chuukese Simi',
 				'chm' => 'Mari Simi',
 				'cho' => 'Choctaw Simi',
 				'chp' => 'Chipewyan Simi',
 				'chr' => 'Cheroqui Simi',
 				'chy' => 'Cheyenne',
 				'ckb' => 'Chawpi Kurdo Simi',
 				'ckb@alt=menu' => 'Kurdo Simi, Chawpi',
 				'ckb@alt=variant' => 'Kurdo Simi, Sorani',
 				'clc' => 'Chilcotin Simi',
 				'co' => 'Corso Simi',
 				'crg' => 'Michif Simi',
 				'crj' => 'Cree Este del Sur Simi',
 				'crk' => 'Plains Cree Simi',
 				'crl' => 'Cree del Noreste Simi',
 				'crm' => 'Moose Cree Simi',
 				'crr' => 'Algonquian Carolina',
 				'cs' => 'Checo Simi',
 				'csw' => 'Swampy Cree Simi',
 				'cu' => 'Eslavo Eclesiástico Simi',
 				'cv' => 'Chuvash Simi',
 				'cy' => 'Gales Simi',
 				'da' => 'Danes Simi',
 				'dak' => 'Dakota Simi',
 				'dar' => 'Dargwa Simi',
 				'dav' => 'Taita Simi',
 				'de' => 'Aleman Simi',
 				'dgr' => 'Dogrib Simi',
 				'dje' => 'Zarma Simi',
 				'doi' => 'Dogri Simi',
 				'dsb' => 'Bajo Sorbio Simi',
 				'dua' => 'Duala Simi',
 				'dv' => 'Divehi Simi',
 				'dyo' => 'Jola-Fonyi Simi',
 				'dz' => 'Butanés Simi',
 				'dzg' => 'Dazaga Simi',
 				'ebu' => 'Embu Simi',
 				'ee' => 'Ewé Simi',
 				'efi' => 'Efik Simi',
 				'eka' => 'Ekajuk Simi',
 				'el' => 'Griego Simi',
 				'en' => 'Ingles Simi',
 				'en_GB@alt=short' => 'Ingles Simi (GB)',
 				'en_US@alt=short' => 'Ingles Simi (US)',
 				'eo' => 'Esperanto Simi',
 				'es' => 'Español Simi',
 				'es_419' => 'Español Simi (Latino América)',
 				'et' => 'Estonio Simi',
 				'eu' => 'Euskera Simi',
 				'ewo' => 'Ewondo Simi',
 				'fa' => 'Persa Simi',
 				'fa_AF' => 'Dari Simi',
 				'ff' => 'Fulah Simi',
 				'fi' => 'Fines Simi',
 				'fil' => 'Filipino Simi',
 				'fj' => 'Fiyiano Simi',
 				'fo' => 'Feroes Simi',
 				'fon' => 'Fon Simi',
 				'fr' => 'Frances Simi',
 				'frc' => 'Francés Cajun',
 				'frr' => 'Frisón del Norte Simi',
 				'fur' => 'Friulano Simi',
 				'fy' => 'Frison Simi',
 				'ga' => 'Irlandes Simi',
 				'gaa' => 'Ga Simi',
 				'gd' => 'Gaelico Escoces Simi',
 				'gez' => 'Geez Simi',
 				'gil' => 'Gilbertese Simi',
 				'gl' => 'Gallego Simi',
 				'gn' => 'Guaraní Simi',
 				'gor' => 'Gorontalo Simi',
 				'gsw' => 'Alsaciano Simi',
 				'gu' => 'Gujarati Simi',
 				'guz' => 'Guzí Simi',
 				'gv' => 'Manés Simi',
 				'gwi' => 'Gwichʼin Simi',
 				'ha' => 'Hausa Simi',
 				'hai' => 'Haida Simi',
 				'haw' => 'Hawaiano Simi',
 				'hax' => 'Haida Meridional',
 				'he' => 'Hebreo Simi',
 				'hi' => 'Hindi Simi',
 				'hi_Latn@alt=variant' => 'Hinglish Simi',
 				'hil' => 'Hiligaynon Simi',
 				'hmn' => 'Hmong Daw Simi',
 				'hr' => 'Croata Simi',
 				'hsb' => 'Alto Sorbio Simi',
 				'ht' => 'Haitiano Criollo Simi',
 				'hu' => 'Hungaro Simi',
 				'hup' => 'Hupa Simi',
 				'hur' => 'Halkomelem Simi',
 				'hy' => 'Armenio Simi',
 				'hz' => 'Herero Simi',
 				'ia' => 'Interlingua Simi',
 				'iba' => 'Iban Simi',
 				'ibb' => 'Ibibio Simi',
 				'id' => 'Indonesio Simi',
 				'ig' => 'Igbo Simi',
 				'ii' => 'Yi Simi',
 				'ikt' => 'Inuktitut Simi (Canadá occidental)',
 				'ilo' => 'Iloko Simi',
 				'inh' => 'Ingush Simi',
 				'io' => 'Ido Simi',
 				'is' => 'Islandes Simi',
 				'it' => 'Italiano Simi',
 				'iu' => 'Inuktitut Simi',
 				'ja' => 'Japones Simi',
 				'jbo' => 'Lojban Simi',
 				'jgo' => 'Ngomba Simi',
 				'jmc' => 'Machame Simi',
 				'jv' => 'Javanés Simi',
 				'ka' => 'Georgiano Simi',
 				'kab' => 'Cabilio Simi',
 				'kac' => 'Kachin Simi',
 				'kaj' => 'Jju Simi',
 				'kam' => 'Kamba Simi',
 				'kbd' => 'Kabardiano Simi',
 				'kcg' => 'Tyap Simi',
 				'kde' => 'Makonde Simi',
 				'kea' => 'Caboverdiano Simi',
 				'kfo' => 'Koro Simi',
 				'kgp' => 'Kaingang Simi',
 				'kha' => 'Khasi Simi',
 				'khq' => 'Koyra Chiini Simi',
 				'ki' => 'Kikuyu Simi',
 				'kj' => 'Kuanyama Simi',
 				'kk' => 'Kazajo Simi',
 				'kkj' => 'Kako Simi',
 				'kl' => 'Groenlandes Simi',
 				'kln' => 'Kalenjin Simi',
 				'km' => 'Khmer Simi',
 				'kmb' => 'Kimbundu Simi',
 				'kn' => 'Kannada Simi',
 				'ko' => 'Coreano Simi',
 				'kok' => 'Konkani Simi',
 				'kpe' => 'Kpelle Simi',
 				'kr' => 'Kanuri Simi',
 				'krc' => 'Karachay-Balkar Simi',
 				'krl' => 'Karelian Simi',
 				'kru' => 'Kurukh Simi',
 				'ks' => 'Cachemir Simi',
 				'ksb' => 'Shambala Simi',
 				'ksf' => 'Bafia Simi',
 				'ksh' => 'Kölsch Simi',
 				'ku' => 'Kurdo Simi',
 				'kum' => 'Kumyk Simi',
 				'kv' => 'Komi Simi',
 				'kw' => 'Córnico Simi',
 				'kwk' => 'Kwakʼwala Simi',
 				'ky' => 'Kirghiz Simi',
 				'la' => 'Latín Simi',
 				'lad' => 'Ladino Simi',
 				'lag' => 'Langi Simi',
 				'lb' => 'Luxemburgues Simi',
 				'lez' => 'Lezghian Simi',
 				'lg' => 'Luganda Simi',
 				'li' => 'Limburgues Simi',
 				'lil' => 'Lillooet Simi',
 				'lkt' => 'Lakota Simi',
 				'ln' => 'Lingala Simi',
 				'lo' => 'Lao Simi',
 				'lou' => 'Luisiana Criollo',
 				'loz' => 'Lozi Simi',
 				'lrc' => 'Luri septentrional Simi',
 				'lsm' => 'Saamia Simi',
 				'lt' => 'Lituano Simi',
 				'lu' => 'Luba-Katanga Simi',
 				'lua' => 'Luba-Lulua Simi',
 				'lun' => 'Lunda Simi',
 				'luo' => 'Luo Simi',
 				'lus' => 'Mizo Simi',
 				'luy' => 'Luyia Simi',
 				'lv' => 'Leton Simi',
 				'mad' => 'Madurese Simi',
 				'mag' => 'Magahi Simi',
 				'mai' => 'Maithili Simi',
 				'mak' => 'Makasar Simi',
 				'mas' => 'Masai Simi',
 				'mdf' => 'Moksha Simi',
 				'men' => 'Mende Simi',
 				'mer' => 'Meru Simi',
 				'mfe' => 'Mauriciano Simi',
 				'mg' => 'Malgache Simi',
 				'mgh' => 'Makhuwa-Meetto Simi',
 				'mgo' => 'Metaʼ Simi',
 				'mh' => 'Marshallese Simi',
 				'mi' => 'Maori Simi',
 				'mic' => 'Mi\'kmaq Simi',
 				'min' => 'Minangkabau Simi',
 				'mk' => 'Macedonio Simi',
 				'ml' => 'Malayalam Simi',
 				'mn' => 'Mongol Simi',
 				'mni' => 'Manipuri Simi',
 				'moe' => 'Innu-aimun Simi',
 				'moh' => 'Mohawk Simi',
 				'mos' => 'Mossi Simi',
 				'mr' => 'Marathi Simi',
 				'ms' => 'Malayo Simi',
 				'mt' => 'Maltes Simi',
 				'mua' => 'Mundang Simi',
 				'mul' => 'Idiomas M´últiples Simi',
 				'mus' => 'Muscogee Simi',
 				'mwl' => 'Mirandés Simi',
 				'my' => 'Birmano Simi',
 				'myv' => 'Erzya Simi',
 				'mzn' => 'Mazandaraní Simi',
 				'na' => 'Nauru Simi',
 				'nap' => 'Neapolitan Simi',
 				'naq' => 'Nama Simi',
 				'nb' => 'Noruego Bokmål Simi',
 				'nd' => 'Ndebele septentrional Simi',
 				'nds' => 'Bajo Alemán Simi',
 				'ne' => 'Nepali Simi',
 				'new' => 'Newari Simi',
 				'ng' => 'Ndonga Simi',
 				'nia' => 'Nias Simi',
 				'niu' => 'Niuean Simi',
 				'nl' => 'Neerlandes Simi',
 				'nl_BE' => 'Flamenco Simi',
 				'nmg' => 'Kwasio Ngumba Simi',
 				'nn' => 'Noruego Nynorsk Simi',
 				'nnh' => 'Ngiemboon Simi',
 				'no' => 'Noruego Simi',
 				'nog' => 'Nogai Simi',
 				'nqo' => 'N’Ko Simi',
 				'nr' => 'Ndebele del Sur Simi',
 				'nso' => 'Sesotho Sa Leboa Simi',
 				'nus' => 'Nuer Simi',
 				'nv' => 'Navajo Simi',
 				'ny' => 'Nyanja Simi',
 				'nyn' => 'Nyankole Simi',
 				'oc' => 'Occitano Simi',
 				'ojb' => 'Ojibwa del noroeste Simi',
 				'ojc' => 'Ojibwa Central',
 				'ojs' => 'Oji-Cree Simi',
 				'ojw' => 'Ojibwa Occidental',
 				'oka' => 'Okanagan Simi',
 				'om' => 'Oromo Simi',
 				'or' => 'Odia Simi',
 				'os' => 'Osetio Simi',
 				'pa' => 'Punyabi Simi',
 				'pag' => 'Pangasinan Simi',
 				'pam' => 'Pampanga Simi',
 				'pap' => 'Papiamento Simi',
 				'pau' => 'Palauan Simi',
 				'pcm' => 'Pidgin Nigeriano Simi',
 				'pis' => 'Pijin Simi',
 				'pl' => 'Polaco Simi',
 				'pqm' => 'Maliseet-Passamaquoddy Simi',
 				'prg' => 'Prusiano Simi',
 				'ps' => 'Pashto Simi',
 				'pt' => 'Portugues Simi',
 				'qu' => 'Runasimi',
 				'quc' => 'Kʼicheʼ Simi',
 				'raj' => 'Rajasthani',
 				'rap' => 'Rapanui Simi',
 				'rar' => 'Rarotongan Simi',
 				'rhg' => 'Rohingya Simi',
 				'rm' => 'Romanche Simi',
 				'rn' => 'Rundi Simi',
 				'ro' => 'Rumano Simi',
 				'rof' => 'Rombo Simi',
 				'ru' => 'Ruso Simi',
 				'rup' => 'Arrumano',
 				'rw' => 'Kinyarwanda Simi',
 				'rwk' => 'Rwa Simi',
 				'sa' => 'Sanscrito Simi',
 				'sad' => 'Sandawe Simi',
 				'sah' => 'Sakha Simi',
 				'saq' => 'Samburu Simi',
 				'sat' => 'Santali Simi',
 				'sba' => 'Ngambay Simi',
 				'sbp' => 'Sangu Simi',
 				'sc' => 'Sardinian Simi',
 				'scn' => 'Siciliano Simi',
 				'sco' => 'Scots Simi',
 				'sd' => 'Sindhi Simi',
 				'se' => 'Chincha Sami Simi',
 				'seh' => 'Sena Simi',
 				'ses' => 'Koyraboro Senni Simi',
 				'sg' => 'Sango Simi',
 				'shi' => 'Tashelhit Simi',
 				'shn' => 'Shan Simi',
 				'si' => 'Cingales Simi',
 				'sk' => 'Eslovaco Simi',
 				'sl' => 'Esloveno Simi',
 				'slh' => 'Lushootseed Meridional',
 				'sm' => 'Samoano Simi',
 				'sma' => 'Qulla Sami Simi',
 				'smj' => 'Sami Lule Simi',
 				'smn' => 'Sami Inari Simi',
 				'sms' => 'Sami Skolt Simi',
 				'sn' => 'Shona Simi',
 				'snk' => 'Soninke Simi',
 				'so' => 'Somali Simi',
 				'sq' => 'Albanes Simi',
 				'sr' => 'Serbio Simi',
 				'srn' => 'Sranan Tongo Simi',
 				'ss' => 'Swati Simi',
 				'st' => 'Soto Meridional Simi',
 				'str' => 'Straits Salish Simi',
 				'su' => 'Sundanés Simi',
 				'suk' => 'Sukuma Simi',
 				'sv' => 'Sueco Simi',
 				'sw' => 'Suajili Simi',
 				'sw_CD' => 'Suajili Simi (Congo (RDC))',
 				'swb' => 'Comorian Simi',
 				'syr' => 'Siriaco Simi',
 				'ta' => 'Tamil Simi',
 				'tce' => 'Tutchone Meridional',
 				'te' => 'Telugu Simi',
 				'tem' => 'Timne Simi',
 				'teo' => 'Teso Simi',
 				'tet' => 'Tetum Simi',
 				'tg' => 'Tayiko Simi',
 				'tgx' => 'Tagish Simi',
 				'th' => 'Tailandes Simi',
 				'tht' => 'Tahltan Simi',
 				'ti' => 'Tigriña Simi',
 				'tig' => 'Tigre Simi',
 				'tk' => 'Turcomano Simi',
 				'tlh' => 'Klingon Simi',
 				'tli' => 'Tlingit Simi',
 				'tn' => 'Setsuana Simi',
 				'to' => 'Tongano Simi',
 				'tok' => 'Toki Pona Simi',
 				'tpi' => 'Tok Pisin Simi',
 				'tr' => 'Turco Simi',
 				'trv' => 'Taroko Simi',
 				'ts' => 'Tsonga Simi',
 				'tt' => 'Tartaro Simi',
 				'ttm' => 'Tutchone del Norte Simi',
 				'tum' => 'Tumbuka Simi',
 				'tvl' => 'Tuvalu Simi',
 				'twq' => 'Tasawaq Simi',
 				'ty' => 'Tahití Simi',
 				'tyv' => 'Tuviniano Simi',
 				'tzm' => 'Tamazight Simi',
 				'udm' => 'Udmurt Simi',
 				'ug' => 'Uigur Simi',
 				'uk' => 'Ucraniano Simi',
 				'umb' => 'Umbundu Simi',
 				'und' => 'Mana Riqsisqa Simi',
 				'ur' => 'Urdu Simi',
 				'uz' => 'Uzbeko Simi',
 				'vai' => 'Vai Simi',
 				've' => 'Venda Simi',
 				'vi' => 'Vietnamita Simi',
 				'vo' => 'Volapük Simi',
 				'vun' => 'Vunjo Simi',
 				'wa' => 'Valona Simi',
 				'wae' => 'Walser Simi',
 				'wal' => 'Wolaytta Simi',
 				'war' => 'Waray Simi',
 				'wo' => 'Wolof Simi',
 				'wuu' => 'Wu Chino',
 				'xal' => 'Kalmyk Simi',
 				'xh' => 'Isixhosa Simi',
 				'xog' => 'Soga Simi',
 				'yav' => 'Yangben Simi',
 				'ybb' => 'Yemba Simi',
 				'yi' => 'Yiddish Simi',
 				'yo' => 'Yoruba Simi',
 				'yrl' => 'Nheengatu Simi',
 				'yue' => 'Cantonés Simi',
 				'yue@alt=menu' => 'Chino Cantonés Simi',
 				'zgh' => 'Bereber Marroquí Estándar Simi',
 				'zh' => 'Chino Simi',
 				'zh@alt=menu' => 'Chino Mandarín Simi',
 				'zh_Hans' => 'Chino Simplificado Simi',
 				'zh_Hans@alt=long' => 'Chino Mandarín Simplificado Simi',
 				'zh_Hant' => 'Chino Tradicional Simi',
 				'zh_Hant@alt=long' => 'Chino Mandarín Tradicional Simi',
 				'zu' => 'Isizulu Simi',
 				'zun' => 'Zuni Simi',
 				'zxx' => 'Manaraq simi yachana',
 				'zza' => 'Zaza Simi',

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
			'Adlm' => 'Adlam Simi',
 			'Arab' => 'Arabe Simi',
 			'Aran' => 'Nastaliq qillqa',
 			'Armn' => 'Armenio Simi',
 			'Beng' => 'Bangla Simi',
 			'Bopo' => 'Bopomofo Simi',
 			'Brai' => 'Braile',
 			'Cakm' => 'Chakma Simi',
 			'Cans' => 'Silabeo aborigen Simi (Canadiense unificado)',
 			'Cher' => 'Cherokee Simi',
 			'Cyrl' => 'Cirilico',
 			'Deva' => 'Devanagari',
 			'Ethi' => 'Etiope',
 			'Geor' => 'Georgiano',
 			'Grek' => 'Griego Simi',
 			'Gujr' => 'Gujarati Simi',
 			'Guru' => 'Gurmukhi Simi',
 			'Hanb' => 'Han with Bopomofo',
 			'Hang' => 'Hangul',
 			'Hani' => 'Han',
 			'Hans' => 'Simplificado',
 			'Hans@alt=stand-alone' => 'Simplificado Han',
 			'Hant' => 'Tradicional',
 			'Hant@alt=stand-alone' => 'Tradicional Han',
 			'Hebr' => 'Hebreo Simi',
 			'Hira' => 'Hiragana',
 			'Hrkt' => 'Japones silabico sananpakuna',
 			'Jamo' => 'Jamo',
 			'Jpan' => 'Japones Simi',
 			'Kana' => 'Katakana',
 			'Khmr' => 'Khmer',
 			'Knda' => 'Kannada Simi',
 			'Kore' => 'Coreano Simi',
 			'Laoo' => 'Lao Simi',
 			'Latn' => 'Latin Simi',
 			'Mlym' => 'Malayalam Simi',
 			'Mong' => 'Mongol Simi',
 			'Mtei' => 'Meitei Mayek Simi',
 			'Mymr' => 'Myanmar',
 			'Nkoo' => 'N’Ko Simi',
 			'Olck' => 'Ol Chiki Simi',
 			'Orya' => 'Odia Simi',
 			'Rohg' => 'Hanifi Simi',
 			'Sinh' => 'Cingales Simi',
 			'Sund' => 'Sundanese Simi',
 			'Syrc' => 'Sirio Simi',
 			'Taml' => 'Tamil Simi',
 			'Telu' => 'Tegulu Simi',
 			'Tfng' => 'Tifinagh Simi',
 			'Thaa' => 'Thaana Simi',
 			'Thai' => 'Tailandes Simi',
 			'Tibt' => 'Tibetano Simi',
 			'Vaii' => 'Vai Simi',
 			'Yiii' => 'Yi Simi',
 			'Zmth' => 'Matimatica Willay',
 			'Zsye' => 'Emoji',
 			'Zsym' => 'Unanchakuna',
 			'Zxxx' => 'Mana qillqasqa',
 			'Zyyy' => 'Common Simi',
 			'Zzzz' => 'Mana yachasqa Qillqa',

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
			'001' => 'Pacha',
 			'002' => 'Africa',
 			'003' => 'Norte America',
 			'005' => 'Sud America',
 			'009' => 'Oceania',
 			'011' => 'Africa Occidental',
 			'013' => 'America Central',
 			'014' => 'Africa Oriental',
 			'015' => 'Africa del Norte',
 			'017' => 'Africa Media',
 			'018' => 'Sud Africa',
 			'019' => 'America',
 			'021' => 'America del Norte',
 			'029' => 'Caribe',
 			'030' => 'Asia Oriental',
 			'034' => 'Asia del Sur',
 			'035' => 'Sureste de Asia',
 			'039' => 'Europa del Sur',
 			'053' => 'Australasia',
 			'054' => 'Melanesia',
 			'057' => 'Región Micronesia',
 			'061' => 'Polinesia',
 			'142' => 'Asia',
 			'143' => 'Asia Central',
 			'145' => 'Asia Occidental',
 			'150' => 'Europa',
 			'151' => 'Europa Oriental',
 			'154' => 'Europa del Norte',
 			'155' => 'Europa Occidental',
 			'202' => 'Africa Sub-Sahariana',
 			'419' => 'AmericaLatina',
 			'AC' => 'Islas Ascensión',
 			'AD' => 'Andorra',
 			'AE' => 'Emiratos Árabes Unidos',
 			'AF' => 'Afganistán',
 			'AG' => 'Antigua y Barbuda',
 			'AI' => 'Anguila',
 			'AL' => 'Albania',
 			'AM' => 'Armenia',
 			'AO' => 'Angola',
 			'AQ' => 'Antártida',
 			'AR' => 'Argentina',
 			'AS' => 'Samoa Americana',
 			'AT' => 'Austria',
 			'AU' => 'Australia',
 			'AW' => 'Aruba',
 			'AX' => 'Islas Åland',
 			'AZ' => 'Azerbaiyán',
 			'BA' => 'Bosnia y Herzegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesh',
 			'BE' => 'Bélgica',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgaria',
 			'BH' => 'Baréin',
 			'BI' => 'Burundi',
 			'BJ' => 'Benín',
 			'BL' => 'San Bartolomé',
 			'BM' => 'Bermudas',
 			'BN' => 'Brunéi',
 			'BO' => 'Bolivia',
 			'BQ' => 'Bonaire',
 			'BR' => 'Brasil',
 			'BS' => 'Bahamas',
 			'BT' => 'Bután',
 			'BV' => 'Isla Bouvet',
 			'BW' => 'Botsuana',
 			'BY' => 'Belarús',
 			'BZ' => 'Belice',
 			'CA' => 'Canadá',
 			'CC' => 'Islas Cocos',
 			'CD' => 'Congo (RDC)',
 			'CF' => 'República Centroafricana',
 			'CG' => 'Congo',
 			'CH' => 'Suiza',
 			'CI' => 'Côte d’Ivoire',
 			'CK' => 'Islas Cook',
 			'CL' => 'Chile',
 			'CM' => 'Camerún',
 			'CN' => 'China',
 			'CO' => 'Colombia',
 			'CP' => 'Isla Clipperton',
 			'CR' => 'Costa Rica',
 			'CU' => 'Cuba',
 			'CV' => 'Cabo Verde',
 			'CW' => 'Curazao',
 			'CX' => 'Isla Christmas',
 			'CY' => 'Chipre',
 			'CZ' => 'Chequia',
 			'CZ@alt=variant' => 'República Checa',
 			'DE' => 'Alemania',
 			'DG' => 'Diego García',
 			'DJ' => 'Yibuti',
 			'DK' => 'Dinamarca',
 			'DM' => 'Dominica',
 			'DO' => 'República Dominicana',
 			'DZ' => 'Argelia',
 			'EA' => 'Ceuta y Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estonia',
 			'EG' => 'Egipto',
 			'EH' => 'Sahara Occidental',
 			'ER' => 'Eritrea',
 			'ES' => 'España',
 			'ET' => 'Etiopía',
 			'EU' => 'Union Europea',
 			'EZ' => 'Eurozona',
 			'FI' => 'Finlandia',
 			'FJ' => 'Fiyi',
 			'FK' => 'Islas Malvinas',
 			'FM' => 'Micronesia',
 			'FO' => 'Islas Feroe',
 			'FR' => 'Francia',
 			'GA' => 'Gabón',
 			'GB' => 'Reino Unido',
 			'GD' => 'Granada',
 			'GE' => 'Georgia',
 			'GF' => 'Guayana Francesa',
 			'GG' => 'Guernesey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Groenlandia',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadalupe',
 			'GQ' => 'Guinea Ecuatorial',
 			'GR' => 'Grecia',
 			'GS' => 'Georgia del Sur e Islas Sandwich del Sur',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bisáu',
 			'GY' => 'Guyana',
 			'HK' => 'Hong Kong RAE China',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Islas Heard y McDonald',
 			'HN' => 'Honduras',
 			'HR' => 'Croacia',
 			'HT' => 'Haití',
 			'HU' => 'Hungría',
 			'IC' => 'Islas Canarias',
 			'ID' => 'Indonesia',
 			'IE' => 'Irlanda',
 			'IL' => 'Israel',
 			'IM' => 'Isla de Man',
 			'IN' => 'India',
 			'IO' => 'Territorio Británico del Océano Índico',
 			'IO@alt=chagos' => 'Chagos Archipielago',
 			'IQ' => 'Irak',
 			'IR' => 'Irán',
 			'IS' => 'Islandia',
 			'IT' => 'Italia',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaica',
 			'JO' => 'Jordania',
 			'JP' => 'Japón',
 			'KE' => 'Kenia',
 			'KG' => 'Kirguistán',
 			'KH' => 'Camboya',
 			'KI' => 'Kiribati',
 			'KM' => 'Comoras',
 			'KN' => 'San Cristóbal y Nieves',
 			'KP' => 'Corea del Norte',
 			'KR' => 'Corea del Sur',
 			'KW' => 'Kuwait',
 			'KY' => 'Islas Caimán',
 			'KZ' => 'Kazajistán',
 			'LA' => 'Laos',
 			'LB' => 'Líbano',
 			'LC' => 'Santa Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesoto',
 			'LT' => 'Lituania',
 			'LU' => 'Luxemburgo',
 			'LV' => 'Letonia',
 			'LY' => 'Libia',
 			'MA' => 'Marruecos',
 			'MC' => 'Mónaco',
 			'MD' => 'Moldova',
 			'ME' => 'Montenegro',
 			'MF' => 'San Martín',
 			'MG' => 'Madagascar',
 			'MH' => 'Islas Marshall',
 			'MK' => 'Macedonia del Norte',
 			'ML' => 'Malí',
 			'MM' => 'Myanmar',
 			'MN' => 'Mongolia',
 			'MO' => 'Macao RAE China',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Islas Marianas del Norte',
 			'MQ' => 'Martinica',
 			'MR' => 'Mauritania',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauricio',
 			'MV' => 'Maldivas',
 			'MW' => 'Malawi',
 			'MX' => 'México',
 			'MY' => 'Malasia',
 			'MZ' => 'Mozambique',
 			'NA' => 'Namibia',
 			'NC' => 'Nueva Caledonia',
 			'NE' => 'Níger',
 			'NF' => 'Isla Norfolk',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Países Bajos',
 			'NO' => 'Noruega',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nueva Zelanda',
 			'NZ@alt=variant' => 'Aotearoa Nueva Zelanda',
 			'OM' => 'Omán',
 			'PA' => 'Panamá',
 			'PE' => 'Perú',
 			'PF' => 'Polinesia Francesa',
 			'PG' => 'Papúa Nueva Guinea',
 			'PH' => 'Filipinas',
 			'PK' => 'Pakistán',
 			'PL' => 'Polonia',
 			'PM' => 'San Pedro y Miquelón',
 			'PN' => 'Islas Pitcairn',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestina Kamachikuq',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palaos',
 			'PY' => 'Paraguay',
 			'QA' => 'Qatar',
 			'QO' => 'Oceanía Periférica',
 			'RE' => 'Reunión',
 			'RO' => 'Rumania',
 			'RS' => 'Serbia',
 			'RU' => 'Rusia',
 			'RW' => 'Ruanda',
 			'SA' => 'Arabia Saudí',
 			'SB' => 'Islas Salomón',
 			'SC' => 'Seychelles',
 			'SD' => 'Sudán',
 			'SE' => 'Suecia',
 			'SG' => 'Singapur',
 			'SH' => 'Santa Elena',
 			'SI' => 'Eslovenia',
 			'SJ' => 'Svalbard y Jan Mayen',
 			'SK' => 'Eslovaquia',
 			'SL' => 'Sierra Leona',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Surinam',
 			'SS' => 'Sudán del Sur',
 			'ST' => 'Santo Tomé y Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Siria',
 			'SZ' => 'Esuatini',
 			'SZ@alt=variant' => 'Suazilandia',
 			'TA' => 'Tristán de Acuña',
 			'TC' => 'Islas Turcas y Caicos',
 			'TD' => 'Chad',
 			'TF' => 'Territorios Australes Franceses',
 			'TG' => 'Togo',
 			'TH' => 'Tailandia',
 			'TJ' => 'Tayikistán',
 			'TK' => 'Tokelau',
 			'TL' => 'Timor-Leste',
 			'TM' => 'Turkmenistán',
 			'TN' => 'Túnez',
 			'TO' => 'Tonga',
 			'TR' => 'Turquía',
 			'TT' => 'Trinidad y Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwán',
 			'TZ' => 'Tanzania',
 			'UA' => 'Ucrania',
 			'UG' => 'Uganda',
 			'UM' => 'Islas menores alejadas de los EE.UU.',
 			'UN' => 'Naciones Unidas',
 			'US' => 'Estados Unidos',
 			'UY' => 'Uruguay',
 			'UZ' => 'Uzbekistán',
 			'VA' => 'Santa Sede (Ciudad del Vaticano)',
 			'VC' => 'San Vicente y las Granadinas',
 			'VE' => 'Venezuela',
 			'VG' => 'Islas Vírgenes Británicas',
 			'VI' => 'EE.UU. Islas Vírgenes',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis y Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'Seudo-Acentos',
 			'XB' => 'Seudo-Bidi',
 			'XK' => 'Kosovo',
 			'YE' => 'Yemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Sudáfrica',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabue',
 			'ZZ' => 'Mana yachasqa Suyu',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Intiwatana',
 			'cf' => 'Imayna Qullqi kaynin',
 			'collation' => 'Ñiqinchana',
 			'currency' => 'qullqi',
 			'hc' => 'Ciclo de Horas (12 vs 24)',
 			'lb' => 'Siqi paway kaynin',
 			'ms' => 'Tupuy Kamay',
 			'numbers' => 'Yupaykuna',

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
 				'buddhist' => q{Budista Intiwatana},
 				'chinese' => q{Chino Intiwatana},
 				'coptic' => q{Copto Intiwatana},
 				'dangi' => q{Dangi Intiwatana},
 				'ethiopic' => q{Etiope Intiwatana},
 				'ethiopic-amete-alem' => q{Etíope Amete Alem Intiwatana},
 				'gregorian' => q{Gregoriano Intiwatana},
 				'hebrew' => q{Hebreo Intiwatana},
 				'islamic' => q{Hijri Intiwatana},
 				'islamic-civil' => q{Hijri Intiwatana (tabular, epoca civil)},
 				'islamic-umalqura' => q{Hijri Intiwatana (Umm al-Qura)},
 				'iso8601' => q{ISO-8601 Intiwatana},
 				'japanese' => q{Japones Intiwatana},
 				'persian' => q{Persa Intiwatana},
 				'roc' => q{Minguo Intiwatana},
 			},
 			'cf' => {
 				'account' => q{Yupana Qullqi imayna kaynin},
 				'standard' => q{Estandar nisqa qullqi imayna kaynin},
 			},
 			'collation' => {
 				'ducet' => q{Ñawpaqchasqa Unicode Nisqa Ñiqinchana},
 				'search' => q{Llapanpaq maskana},
 				'standard' => q{Estandar nisqa Ñiqinchana},
 			},
 			'hc' => {
 				'h11' => q{12 hora kaynin (0–11)},
 				'h12' => q{12 hora kaynin (1–12)},
 				'h23' => q{24 hora kaynin (0–23)},
 				'h24' => q{24 hora kaynin (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Siqi paway chinkachiy kaynin},
 				'normal' => q{Siqi paway Normal kaynin},
 				'strict' => q{Siqi paway Chiqa kaynin},
 			},
 			'ms' => {
 				'metric' => q{Metrico Kamay},
 				'uksystem' => q{Metrico Ingles Kamay},
 				'ussystem' => q{Metrico Americano Kamay},
 			},
 			'numbers' => {
 				'arab' => q{Arabe Sananpakuna},
 				'arabext' => q{Arabe Mirachisqa Sananpakuna},
 				'armn' => q{Armenio Sananpakuna},
 				'armnlow' => q{Armenio Uchuy Sananpakuna},
 				'beng' => q{Bangla Sananpakuna},
 				'cakm' => q{Chakma Sananpakuna},
 				'deva' => q{Devanagari Sananpakuna},
 				'ethi' => q{Etiope Sananpakuna},
 				'fullwide' => q{Llapan kinray Sananpakuna},
 				'geor' => q{Gregoriano Yupaykuna},
 				'grek' => q{Griego Yupaykuna},
 				'greklow' => q{Griego Uchuy Yupaykuna},
 				'gujr' => q{Gujarati Sananpakuna},
 				'guru' => q{Gurmukhi Sananpakuna},
 				'hanidec' => q{Chunkachasqa Chino Yupaykuna},
 				'hans' => q{Uchuyachusqa Chino Yupaypakuna},
 				'hansfin' => q{Uchuyachisqa Qullqi Chino Yupaypakuna},
 				'hant' => q{Kikin Chino Yupaypakuna},
 				'hantfin' => q{Kikin Qullqi Chino Yupaypakuna},
 				'hebr' => q{Hebreo Yupaykuna},
 				'java' => q{Javaneses Yupaykuna},
 				'jpan' => q{Japones Yupaykuna},
 				'jpanfin' => q{Japones Qullqi Yupaykuna},
 				'khmr' => q{Khmer Sananpakuna},
 				'knda' => q{Kannada Sananpakuna},
 				'laoo' => q{Lao Sananpakuna},
 				'latn' => q{Occidental Sananpakuna},
 				'mlym' => q{Malayalam Sananpakuna},
 				'mtei' => q{Meetei Mayek Yupaykuna},
 				'mymr' => q{Myanmar Sananpakuna},
 				'olck' => q{Ol Chiki Yupaykuna},
 				'orya' => q{Odia Sananpakuna},
 				'roman' => q{Romano Sananpakuna},
 				'romanlow' => q{Roman Uchuy Yupaykuna},
 				'taml' => q{Kikin Tamil Yupaykuna},
 				'tamldec' => q{Tamil Sananpakuna},
 				'telu' => q{Telegu Sananpakuna},
 				'thai' => q{Thai Sananpakuna},
 				'tibt' => q{Tibetano Sananpakuna},
 				'vaii' => q{Vai Yupaykuna},
 			},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Simi: {0}',
 			'script' => 'Qillqa: {0}',
 			'region' => 'Suyu: {0}',

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
			auxiliary => qr{[áàăâåäãā æ b cç d eéèĕêëē f g íìĭîïī j oóòŏôöøō œ r úùŭûüū v x ÿ z]},
			index => ['A', '{Ch}', 'H', 'I', 'K', 'L', '{Ll}', 'M', 'NÑ', 'P', 'Q', 'S', 'T', 'U', 'W', 'Y'],
			main => qr{[a {ch} {chʼ} h i k {kʼ} l {ll} m nñ p {pʼ} q {qʼ} s t {tʼ} u w y]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', '{Ch}', 'H', 'I', 'K', 'L', '{Ll}', 'M', 'NÑ', 'P', 'Q', 'S', 'T', 'U', 'W', 'Y'], };
},
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
						'1' => q(deci{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(deci{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(pico{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(pico{0}),
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
						'1' => q(yocto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yocto{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(milli{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(milli{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(micro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(micro{0}),
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
						'1' => q({0} hectopa),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q({0} hectopa),
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
					'acceleration-meter-per-square-second' => {
						'name' => q(metros por segundo cuadrado),
						'other' => q({0} metros por segundo cuadrado),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metros por segundo cuadrado),
						'other' => q({0} metros por segundo cuadrado),
					},
					# Long Unit Identifier
					'area-acre' => {
						'other' => q({0} acre),
					},
					# Core Unit Identifier
					'acre' => {
						'other' => q({0} acre),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hectárea),
						'other' => q({0} hectárea),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hectárea),
						'other' => q({0} hectárea),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(centímetro cuadrado),
						'other' => q({0} centímetro cuadrado),
						'per' => q({0}/centímetro cuadrado),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(centímetro cuadrado),
						'other' => q({0} centímetro cuadrado),
						'per' => q({0}/centímetro cuadrado),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(pie cuadrado),
						'other' => q({0} pie cuadrado),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(pie cuadrado),
						'other' => q({0} pie cuadrado),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(pulgada cuadrada),
						'other' => q({0} pulgada cuadrada),
						'per' => q({0}/pulgada cuadrada),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(pulgada cuadrada),
						'other' => q({0} pulgada cuadrada),
						'per' => q({0}/pulgada cuadrada),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kilómetro cuadrado),
						'other' => q({0} kilómetro cuadrado),
						'per' => q({0}/kilómetro cuadrado),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kilómetro cuadrado),
						'other' => q({0} kilómetro cuadrado),
						'per' => q({0}/kilómetro cuadrado),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(metro cuadrado),
						'other' => q({0} metro cuadrado),
						'per' => q({0}/metro cuadrado),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(metro cuadrado),
						'other' => q({0} metro cuadrado),
						'per' => q({0}/metro cuadrado),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(milla cuadrada),
						'other' => q({0} milla cuadrada),
						'per' => q({0}/milla cuadrada),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(milla cuadrada),
						'other' => q({0} milla cuadrada),
						'per' => q({0}/milla cuadrada),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yarda cuadrada),
						'other' => q({0} yarda cuadrada),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yarda cuadrada),
						'other' => q({0} yarda cuadrada),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(imakuna),
						'other' => q({0} imakuna),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(imakuna),
						'other' => q({0} imakuna),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(partes por millon),
						'other' => q({0} partes por millon),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(partes por millon),
						'other' => q({0} partes por millon),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(litros por 100 kilometros),
						'other' => q({0} litros por 100 kilometros),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(litros por 100 kilometros),
						'other' => q({0} litros por 100 kilometros),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(siglos),
						'other' => q({0} siglos),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(siglos),
						'other' => q({0} siglos),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(punchaw),
						'other' => q({0} punchaw),
						'per' => q({0}/p),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(punchaw),
						'other' => q({0} punchaw),
						'per' => q({0}/p),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(décadas),
						'other' => q({0} décadas),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(décadas),
						'other' => q({0} décadas),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(hora),
						'other' => q({0} hora),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(hora),
						'other' => q({0} hora),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(microsegundo),
						'other' => q({0} microsegundo),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(microsegundo),
						'other' => q({0} microsegundo),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisegundo),
						'other' => q({0} milisegundo),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisegundo),
						'other' => q({0} milisegundo),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(minuto),
						'other' => q({0} minuto),
						'per' => q({0} por minuto),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(minuto),
						'other' => q({0} minuto),
						'per' => q({0} por minuto),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(killa),
						'other' => q({0} killa),
						'per' => q({0}/k),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(killa),
						'other' => q({0} killa),
						'per' => q({0}/k),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosegundo),
						'other' => q({0} nanosegundo),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosegundo),
						'other' => q({0} nanosegundo),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(sapa kimsa killa),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(sapa kimsa killa),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(segundo),
						'other' => q({0} segundo),
						'per' => q({0} por segundo),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(segundo),
						'other' => q({0} segundo),
						'per' => q({0} por segundo),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(semana),
						'other' => q({0} semana),
						'per' => q({0} por semana),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(semana),
						'other' => q({0} semana),
						'per' => q({0} por semana),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(wata),
						'other' => q({0} wata),
						'per' => q({0} sapa wata),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(wata),
						'other' => q({0} wata),
						'per' => q({0} sapa wata),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Calorias),
						'other' => q({0} calorias),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Calorias),
						'other' => q({0} calorias),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-ura sapa 100 kilometrokuna),
						'other' => q({0} kilowatt-ura sapa 100 kilometrokuna),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilowatt-ura sapa 100 kilometrokuna),
						'other' => q({0} kilowatt-ura sapa 100 kilometrokuna),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(chiku),
						'other' => q({0} chiku),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(chiku),
						'other' => q({0} chiku),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(puntos por centímetro),
						'other' => q({0} puntos por centímetro),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(puntos por centímetro),
						'other' => q({0} puntos por centímetro),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(puntos por pulgada),
						'other' => q({0} puntos por pulgada),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(puntos por pulgada),
						'other' => q({0} puntos por pulgada),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(tipográfico em),
						'other' => q({0} tipográfico em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(tipográfico em),
						'other' => q({0} tipográfico em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(megapixels),
						'other' => q({0} megapixels),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(megapixels),
						'other' => q({0} megapixels),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(pixels),
						'other' => q({0} pixels),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(pixels),
						'other' => q({0} pixels),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(pixels por centímetro),
						'other' => q({0} pixels por centímetro),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(pixels por centímetro),
						'other' => q({0} pixels por centímetro),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(pixels por pulgada),
						'other' => q({0} pixels por pulgada),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(pixels por pulgada),
						'other' => q({0} pixels por pulgada),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(unidades astronómicas),
						'other' => q({0} unidades astronómicas),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(unidades astronómicas),
						'other' => q({0} unidades astronómicas),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(centímetro),
						'other' => q({0} centímetro),
						'per' => q({0}/centímetro),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(centímetro),
						'other' => q({0} centímetro),
						'per' => q({0}/centímetro),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(decímetro),
						'other' => q({0} decímetro),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(decímetro),
						'other' => q({0} decímetro),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(radio de la tierra),
						'other' => q({0} radio de la tierra),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(radio de la tierra),
						'other' => q({0} radio de la tierra),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fathoms),
						'other' => q({0} fathoms),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fathoms),
						'other' => q({0} fathoms),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(pie),
						'other' => q({0} pie),
						'per' => q({0}/pie),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(pie),
						'other' => q({0} pie),
						'per' => q({0}/pie),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(furlongs),
						'other' => q({0} furlongs),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(furlongs),
						'other' => q({0} furlongs),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(pulgada),
						'other' => q({0} pulgada),
						'per' => q({0}/pulgada),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(pulgada),
						'other' => q({0} pulgada),
						'per' => q({0}/pulgada),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilómetro),
						'other' => q({0} kilómetro),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilómetro),
						'other' => q({0} kilómetro),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(años luz),
						'other' => q({0} años luz),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(años luz),
						'other' => q({0} años luz),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metro),
						'other' => q({0} metro),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metro),
						'other' => q({0} metro),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(micrómetro),
						'other' => q({0} micrómetro),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(micrómetro),
						'other' => q({0} micrómetro),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(milla),
						'other' => q({0} milla),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(milla),
						'other' => q({0} milla),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(milla escandinava),
						'other' => q({0} milla escandinava),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(milla escandinava),
						'other' => q({0} milla escandinava),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milímetro),
						'other' => q({0} milímetro),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milímetro),
						'other' => q({0} milímetro),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanómetro),
						'other' => q({0} nanómetro),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanómetro),
						'other' => q({0} nanómetro),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(millas naúticas),
						'other' => q({0} millas naúticas),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(millas naúticas),
						'other' => q({0} millas naúticas),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(parsecs),
						'other' => q({0} parsecs),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(parsecs),
						'other' => q({0} parsecs),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(picómetro),
						'other' => q({0} picómetro),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(picómetro),
						'other' => q({0} picómetro),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(puntos),
						'other' => q({0} puntos),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(puntos),
						'other' => q({0} puntos),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(radiación solar),
						'other' => q({0} radiación solar),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(radiación solar),
						'other' => q({0} radiación solar),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yarda),
						'other' => q({0} yarda),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yarda),
						'other' => q({0} yarda),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(candela),
						'other' => q({0} candela),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(candela),
						'other' => q({0} candela),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumen),
						'other' => q({0} lumen),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumen),
						'other' => q({0} lumen),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(toneladas metricas),
						'other' => q({0} toneladas metricas),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(toneladas metricas),
						'other' => q({0} toneladas metricas),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} sapa {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} sapa {1}),
					},
					# Long Unit Identifier
					'power2' => {
						'other' => q({0} cuadrado),
					},
					# Core Unit Identifier
					'power2' => {
						'other' => q({0} cuadrado),
					},
					# Long Unit Identifier
					'power3' => {
						'other' => q({0} cubico),
					},
					# Core Unit Identifier
					'power3' => {
						'other' => q({0} cubico),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(pulgadas por mercurio),
						'other' => q({0} pulgadas por mercurio),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(pulgadas por mercurio),
						'other' => q({0} pulgadas por mercurio),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(milimetros de mercurio),
						'other' => q({0} milimetros de mercurio),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(milimetros de mercurio),
						'other' => q({0} milimetros de mercurio),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(libras por pulgada cuadrada),
						'other' => q({0} libras por pulgada cuadrada),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(libras por pulgada cuadrada),
						'other' => q({0} libras por pulgada cuadrada),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(libras-pies),
						'other' => q({0} libras-pies),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(libras-pies),
						'other' => q({0} libras-pies),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(acre-pie),
						'other' => q({0} acre-pie),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(acre-pie),
						'other' => q({0} acre-pie),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(barril),
						'other' => q({0} barril),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(barril),
						'other' => q({0} barril),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bushels),
						'other' => q({0} bushels),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bushels),
						'other' => q({0} bushels),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(centilitro),
						'other' => q({0} centilitro),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(centilitro),
						'other' => q({0} centilitro),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(centímetro cúbico),
						'other' => q({0} centímetro cúbico),
						'per' => q({0}/centímetro cúbico),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(centímetro cúbico),
						'other' => q({0} centímetro cúbico),
						'per' => q({0}/centímetro cúbico),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(pie cúbico),
						'other' => q({0} pie cúbico),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(pie cúbico),
						'other' => q({0} pie cúbico),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(pulgada cúbica),
						'other' => q({0} pulgada cúbica),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(pulgada cúbica),
						'other' => q({0} pulgada cúbica),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kilómetro cúbico),
						'other' => q({0} kilómetro cúbico),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kilómetro cúbico),
						'other' => q({0} kilómetro cúbico),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(metro cúbico),
						'other' => q({0} metro cúbico),
						'per' => q({0}/metro cúbico),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(metro cúbico),
						'other' => q({0} metro cúbico),
						'per' => q({0}/metro cúbico),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(milla cúbica),
						'other' => q({0} milla cúbica),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(milla cúbica),
						'other' => q({0} milla cúbica),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yarda cúbica),
						'other' => q({0} yarda cúbica),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yarda cúbica),
						'other' => q({0} yarda cúbica),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(taza),
						'other' => q({0} taza),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(taza),
						'other' => q({0} taza),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(taza métrica),
						'other' => q({0} taza métrica),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(taza métrica),
						'other' => q({0} taza métrica),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(decilitro),
						'other' => q({0} decilitro),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(decilitro),
						'other' => q({0} decilitro),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(cuchara para postes),
						'other' => q({0} cuchara para postres),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(cuchara para postes),
						'other' => q({0} cuchara para postres),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Imp. cuchara para postres),
						'other' => q({0} Imp. cuchara para postres),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Imp. cuchara para postres),
						'other' => q({0} Imp. cuchara para postres),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(trago),
						'other' => q({0} trago),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(trago),
						'other' => q({0} trago),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(Onza líquida),
						'other' => q({0} US Onza líquida),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(Onza líquida),
						'other' => q({0} US Onza líquida),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(UK Onza líquida),
						'other' => q({0} UK Onza líquida),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(UK Onza líquida),
						'other' => q({0} UK Onza líquida),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(galón),
						'other' => q({0} US galón),
						'per' => q({0}/US galón),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(galón),
						'other' => q({0} US galón),
						'per' => q({0}/US galón),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(UK galón),
						'other' => q({0} UK galón),
						'per' => q({0}/UK galón),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(UK galón),
						'other' => q({0} UK galón),
						'per' => q({0}/UK galón),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hectolitro),
						'other' => q({0} hectolitro),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hectolitro),
						'other' => q({0} hectolitro),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litro),
						'other' => q({0} litro),
						'per' => q({0}/litro),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litro),
						'other' => q({0} litro),
						'per' => q({0}/litro),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(megalitro),
						'other' => q({0} megalitro),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(megalitro),
						'other' => q({0} megalitro),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mililitro),
						'other' => q({0} mililitro),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mililitro),
						'other' => q({0} mililitro),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pinta),
						'other' => q({0} pinta),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pinta),
						'other' => q({0} pinta),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(pinta métrica),
						'other' => q({0} pinta métrica),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(pinta métrica),
						'other' => q({0} pinta métrica),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(cuarto),
						'other' => q({0} cuarto),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(cuarto),
						'other' => q({0} cuarto),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(Imp. cuarta),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(Imp. cuarta),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(cucharada),
						'other' => q({0} cucharada),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(cucharada),
						'other' => q({0} cucharada),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(cucharadita),
						'other' => q({0} cucharadita),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(cucharadita),
						'other' => q({0} cucharadita),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'10p15' => {
						'1' => q(P{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(P{0}),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(punchaw),
						'other' => q({0} p),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(punchaw),
						'other' => q({0} p),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(hora),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(hora),
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
						'name' => q(killa),
						'other' => q({0} k),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(killa),
						'other' => q({0} k),
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
						'name' => q(semana),
						'other' => q({0} s),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(semana),
						'other' => q({0} s),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(wata),
						'other' => q({0} w),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(wata),
						'other' => q({0} w),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'other' => q({0}km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'other' => q({0}km),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(metro),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(metro),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(taza),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(taza),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(litro),
						'other' => q({0} litro),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(litro),
						'other' => q({0} litro),
					},
				},
				'short' => {
					# Long Unit Identifier
					'10p15' => {
						'1' => q({0} PB),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q({0} PB),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(metros/sec²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(metros/sec²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(ima),
						'other' => q({0} ima),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(ima),
						'other' => q({0} ima),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(partes/millon),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(partes/millon),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'other' => q({0} L/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'other' => q({0} L/100 km),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(punto),
						'other' => q({0} punto),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(punto),
						'other' => q({0} punto),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fathom),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fathom),
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
					'mass-grain' => {
						'name' => q(grano),
						'other' => q({0} grano),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(grano),
						'other' => q({0} grano),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(catorce libras),
						'other' => q({0} catorce libras),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(catorce libras),
						'other' => q({0} catorce libras),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(bushel),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(bushel),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(cucharilla),
						'other' => q({0} cucharilla),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(cucharilla),
						'other' => q({0} cucharilla),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Imp cucharilla),
						'other' => q({0} Imp cucharilla),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Imp cucharilla),
						'other' => q({0} Imp cucharilla),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(trago fluido),
						'other' => q({0} trago fluido),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(trago fluido),
						'other' => q({0} trago fluido),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(gota),
						'other' => q({0} gota),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(gota),
						'other' => q({0} gota),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(medida),
						'other' => q({0} medida),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(medida),
						'other' => q({0} medida),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(pizca),
						'other' => q({0} pizca),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pizca),
						'other' => q({0} pizca),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(Imp cuarta),
						'other' => q({0} Imp. cuarta),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(Imp cuarta),
						'other' => q({0} Imp. cuarta),
					},
				},
			} }
);

has 'number_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
					'accounting' => {
						'negative' => '(#,##0.00)',
						'positive' => '#,##0.00',
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
				'currency' => q(Dirham de Emiratos Árabes Unidos),
				'other' => q(UAE dirhams),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afgani Afgano),
				'other' => q(Afgani afgano),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Lek albanés),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Dram Armenio),
				'other' => q(drams Armenios),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Florín Antillano Neerlandés),
				'other' => q(Florín antillano neerlandés),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Kwanza Angoleño),
				'other' => q(Kwanza angoleño),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Peso Argentino),
				'other' => q(Peso argentino),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(Dólar Australiano),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Florín Arubeño),
				'other' => q(Florín arubeño),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Manat Azerbaiyano),
				'other' => q(manats Azerbaiyanos),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Marco Bosnioherzegovino),
				'other' => q(Marco bosnioherzegovino),
			},
		},
		'BBD' => {
			symbol => 'BBG',
			display_name => {
				'currency' => q(Dólar de Barbados),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka Bangladesí),
				'other' => q(Taka bangladesí),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Lev),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Dinar Bareiní),
				'other' => q(Dinar bareiní),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Franco Burundés),
				'other' => q(Franco burundés),
			},
		},
		'BMD' => {
			symbol => 'DBM',
			display_name => {
				'currency' => q(Dólar Bermudeño),
				'other' => q(Dólar bermudeño),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Dólar de Brunéi),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Boliviano),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(Real Brasileño),
				'other' => q(Real brasileño),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Dólar Bahameño),
				'other' => q(Dólar bahameño),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(Ngultrum Butanés),
				'other' => q(Ngultrum butanés),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula Botswano),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Nuevo Rublo Bielorruso),
				'other' => q(Nuevo rublo bielorruso),
			},
		},
		'BZD' => {
			symbol => 'DBZ',
			display_name => {
				'currency' => q(Dólar Beliceño),
				'other' => q(Dólar beliceño),
			},
		},
		'CAD' => {
			symbol => '$CA',
			display_name => {
				'currency' => q(Dólar Canadiense),
				'other' => q(Dólar canadiense),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Franco Congoleño),
				'other' => q(Franco congoleño),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Franco Suizo),
				'other' => q(Franco suizo),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Peso Chileno),
				'other' => q(Peso chileno),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(Yuan Chino \(offshore\)),
				'other' => q(Yuan chino \(offshore\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(Yuan Chino),
				'other' => q(Yuan chino),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Peso Colombiano),
				'other' => q(Peso colombiano),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Colón Costarricense),
				'other' => q(Colón costarricense),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Peso Cubano Convertible),
				'other' => q(Peso cubano convertible),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Peso Cubano),
				'other' => q(Peso cubano),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Escudo Caboverdiano),
				'other' => q(Escudo caboverdiano),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Corona Checa),
				'other' => q(Corona checa),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Franco Yibutiano),
				'other' => q(Franco yibutiano),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Corona Danesa),
				'other' => q(Corona danesa),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Peso Dominicano),
				'other' => q(Peso dominicano),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Dinar Argelino),
				'other' => q(Dinar argelino),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Libra Egipcia),
				'other' => q(Libra egipcia),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nakfa Eritreano),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Birr Etíope),
				'other' => q(Birr etíope),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
				'other' => q(euro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Dólar Fiyiano),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Libra Malvinense),
				'other' => q(Libra malvinense),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(Libra Esterlina),
				'other' => q(Libra esterlina),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Lari Georgiano),
				'other' => q(Lari georgiano),
			},
		},
		'GHS' => {
			symbol => 'GHC',
			display_name => {
				'currency' => q(Cedi Ganés),
				'other' => q(Cedi ganés),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Libra Gibraltareña),
				'other' => q(Libra gibraltareña),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Franco Guineano),
				'other' => q(Franco guineano),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Quetzal Guatemalteco),
				'other' => q(Quetzal guatemalteco),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Dólar Guyanés),
				'other' => q(Dólar guyanés),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Dólar de Hong Kong),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Lempira Hondureño),
				'other' => q(Lempira hondureño),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kuna Croata),
				'other' => q(Kuna croata),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Gourde Haitiano),
				'other' => q(Gourde haitiano),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Florín Húngaro),
				'other' => q(Florín húngaro),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(Rupia Indonesia),
				'other' => q(Rupia indonesia),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(Nuevo Séquel),
				'other' => q(Nuevo séquel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(Rupia India),
				'other' => q(Rupia india),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Dinar Iraquí),
				'other' => q(Dinar iraquí),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(Rial Iraní),
				'other' => q(Rial iraní),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Corona Islandesa),
				'other' => q(Corona islandesa),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Dólar Jamaiquino),
				'other' => q(Dólar jamaiquino),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Dinar Jordano),
				'other' => q(Dinar jordano),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(Yen Japonés),
				'other' => q(Yen japonés),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Chelín Keniano),
				'other' => q(Chelín keniano),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Som Kirguís),
				'other' => q(Som kirguís),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(Riel Camboyano),
				'other' => q(Riel camboyano),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Franco Comorense),
				'other' => q(Franco comorense),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(Won Norcoreano),
				'other' => q(Won norcoreano),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(Won Surcoreano),
				'other' => q(Won surcoreano),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Dinar Kuwaití),
				'other' => q(Dinar kuwaití),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Dólar de las Islas Caimán),
				'other' => q(Dólar de las islas caimán),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Tenge Kazajo),
				'other' => q(Tenge kazajo),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(Kip Laosiano),
				'other' => q(Kip laosiano),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Libra Libanesa),
				'other' => q(Libra libanesa),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(Rupia de Sri Lanka),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Dólar Liberiano),
				'other' => q(Dólar liberiano),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesoto Loti Qullqi),
				'other' => q(Lesoto lotis qullqi),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Dinar Libio),
				'other' => q(Dinar libio),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Dírham Marroquí),
				'other' => q(Dírham marroquí),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Leu Moldavo),
				'other' => q(Leu moldavo),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Ariary Malgache),
				'other' => q(Ariary malgache),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Dinar Macedonio),
				'other' => q(Dinar macedonio),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(Kyat Birmano),
				'other' => q(Kyat birmano),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(Tugrik Mongol),
				'other' => q(Tugrik mongol),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(Pataca Macaense),
				'other' => q(Pataca macaense),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Uguiya Mauritano),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Rupia de Mauricio),
				'other' => q(Rupia de mauricio),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(Rupia de Maldivas),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Kwacha Malauí),
				'other' => q(Kwacha malauí),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(Peso Mexicano),
				'other' => q(Peso mexicano),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(Ringgit Malayo),
				'other' => q(Ringgit malayo),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Metical Mozambiqueño),
				'other' => q(Metical mozambiqueño),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Dólar Namibio),
				'other' => q(Dólar namibio),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Naira Nigeriano),
				'other' => q(Naira nigeriano),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Córdova Nicaragüense),
				'other' => q(Córdova nicaragüense),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Corona Noruega),
				'other' => q(Corona noruega),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(Rupia Nepalí),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(Dólar Neozelandés),
				'other' => q(Dólar neozelandés),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Rial Omaní),
				'other' => q(Rial omaní),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Balboa Panameño),
				'other' => q(Balboa panameño),
			},
		},
		'PEN' => {
			symbol => 'S/',
			display_name => {
				'currency' => q(Sol Peruano),
				'other' => q(Sol peruano),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina Papuano),
				'other' => q(Kina papuano),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Peso Filipino),
				'other' => q(Peso filipino),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(Rupia Pakistaní),
				'other' => q(Rupia pakistaní),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Zloty),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Guaraní Paraguayo),
				'other' => q(Guaraní paraguayo),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Riyal Catarí),
				'other' => q(Riyal catarí),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Leu Rumano),
				'other' => q(Leu rumano),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Dinar Serbio),
				'other' => q(Dinar serbio),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Rublo Ruso),
				'other' => q(Rublo ruso),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Franco Ruandés),
				'other' => q(Franco ruandés),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Riyal Saudí),
				'other' => q(Riyal saudí),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Dólar de las Islas Salomón),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Rupia de Seychelles),
				'other' => q(Rupia de seychelles),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Libra Sudanesa),
				'other' => q(Libra sudanesa),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Corona Sueca),
				'other' => q(Corona sueca),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(Dólar de Singapur),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Libra de Santa Helena),
				'other' => q(Libra de santa helena),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(Leone de Sierra Leona),
				'other' => q(Leone de sierra leona),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Leone de Sierra Leona \(1964—2022\)),
				'other' => q(Leone de sierra leona \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Chelín Somalí),
				'other' => q(Chelín somalí),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Dólar Surinamés),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Libra Sursudanesa),
				'other' => q(Libra sursudanesa),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra Santotomense),
				'other' => q(Dobra santotomense),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Libra Siria),
				'other' => q(Libra siria),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Lilangeni Swazi),
				'other' => q(Lilangeni swazi),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(Baht Tailandés),
				'other' => q(Baht tailandés),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Somoni Tayiko),
				'other' => q(Somoni tayiko),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Manat Turcomano),
				'other' => q(Manat turcomano),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Dinar Tunecino),
				'other' => q(Dinar tunecino),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Paʻanga Tongano),
				'other' => q(Paʻanga tongano),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Lira Turca),
				'other' => q(Lira turca),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dólar de Trinidad y Tobago),
				'other' => q(Dólar de trinidad y tobago),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(Nuevo Dólar Taiwanés),
				'other' => q(Nuevo dólar taiwanés),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Chelín Tanzano),
				'other' => q(Chelín tanzano),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Grivna),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Chelín Ugandés),
				'other' => q(Chelín ugandés),
			},
		},
		'USD' => {
			symbol => '$US',
			display_name => {
				'currency' => q(Dólar Americano),
				'other' => q(Dólar americano),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Peso Uruguayo),
				'other' => q(Peso uruguayo),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Som Ubzeko),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(Bolívar Venezolano),
				'other' => q(Bolívar venezolano),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(Dong Vietnamita),
				'other' => q(Dong vietnamita),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vatu Vanuatu),
				'other' => q(Vatu vanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tala Samoano),
				'other' => q(Tala samoano),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Franco CFA de África Central),
				'other' => q(Franco CFA de áfrica central),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(Dólar del Caribe Oriental),
				'other' => q(Dólar del caribe oriental),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Franco CFA de África Occidental),
				'other' => q(Franco CFA de áfrica occidental),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Franco CFP),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Mana riqsisqa Qullqi),
				'other' => q(Mana riqsisqa qullqi),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Rial Yemení),
				'other' => q(Rial yemení),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Rand Sudafricano),
				'other' => q(Rand sudafricano),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwacha Zambiano),
				'other' => q(Kwacha zambiano),
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
							'Ene',
							'Feb',
							'Mar',
							'Abr',
							'May',
							'Jun',
							'Jul',
							'Ago',
							'Set',
							'Oct',
							'Nov',
							'Dic'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Enero',
							'Febrero',
							'Marzo',
							'Abril',
							'Mayo',
							'Junio',
							'Julio',
							'Agosto',
							'Setiembre',
							'Octubre',
							'Noviembre',
							'Diciembre'
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
						tue => 'Mar',
						wed => 'Mié',
						thu => 'Jue',
						fri => 'Vie',
						sat => 'Sab',
						sun => 'Dom'
					},
					wide => {
						mon => 'Lunes',
						tue => 'Martes',
						wed => 'Miércoles',
						thu => 'Jueves',
						fri => 'Viernes',
						sat => 'Sábado',
						sun => 'Domingo'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'L',
						tue => 'M',
						wed => 'X',
						thu => 'J',
						fri => 'V',
						sat => 'S',
						sun => 'D'
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
					'am' => q{a.m.},
					'pm' => q{p.m.},
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
				'0' => 'a.d.',
				'1' => 'd.C.'
			},
			narrow => {
				'1' => 'dC'
			},
			wide => {
				'0' => 'ñawpa cristu',
				'1' => 'chanta cristu'
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
			'full' => q{EEEE, d MMMM y, G},
			'long' => q{d MMMM y, G},
			'medium' => q{d MMM y, G},
			'short' => q{d/M/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d MMMM, y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{d/M/yy},
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
			'long' => q{{0} {1}},
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
			Ed => q{E, d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d MMMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{M/d/y GGGGG},
			MEd => q{E, dd-MM},
			MMMEd => q{E, d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{dd-MM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{MM-y GGGGG},
			yyyyMEd => q{E, dd-MM-y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{dd-MM-y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			GyMMM => q{G MMM y},
			GyMMMEd => q{E, d MMM, y G},
			GyMMMd => q{G d MMM, y},
			GyMd => q{G d/M/y},
			MMMEd => q{E, d MMM},
			MMMMW => q{W 'semana' MMMM 'killapa'},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yMEd => q{E, dd-MM-y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d MMM, y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{dd-MM-y},
			yw => q{w 'semana' Y 'watapa'},
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
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{MM-y GGGGG – MM-y GGGGG},
				M => q{MM-y GGGGG – MM-y GGGGG},
				y => q{MM-y – MM-y GGGGG},
			},
			GyMEd => {
				G => q{E, d-MM-y GGGG – E, d-MM-y GGGGG},
				M => q{E, d-MM-y – E, d-MM-y GGGGG},
				d => q{E, d-MM-y – E, d-MM-y GGGGG},
				y => q{E, d-MM-y – E, d-MM-y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
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
				G => q{d-MM-y GGGG – d-MM-y GGGGG},
				M => q{d-MM-y – d-MM-y GGGGG},
				d => q{d-MM-y – d–MM-y GGGGG},
				y => q{d-MM-y – d-MM-y GGGGG},
			},
			MEd => {
				M => q{E, dd-MM – E, dd-MM},
				d => q{E, dd-MM – E, dd-MM},
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
				M => q{dd-MM – dd-MM},
				d => q{dd-MM – dd-MM},
			},
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{MM-y – MM-y GGGGG},
				y => q{MM-y – MM-y GGGGG},
			},
			yMEd => {
				M => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				d => q{E, dd-MM-y – E, dd-MM-y GGGGG},
				y => q{E, dd-MM-y – E, dd-MM-y GGGGG},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM y G},
				d => q{E, d MMM y – E, d MMM y G},
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
				M => q{dd-MM-y – dd-MM-y GGGGG},
				d => q{dd-MM-y – dd-MM-y GGGGG},
				y => q{dd-MM-y – dd-MM-y GGGGG},
			},
		},
		'gregorian' => {
			GyM => {
				G => q{MM-y GGGGG – MM-y GGGGG},
			},
			GyMMM => {
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, d MMM y G – E, d MMM y G},
				M => q{E, d MMM d – E, d MMM y G},
				d => q{E, d MMM – E, d MMM y G},
				y => q{E, d MMM y – E, d MMM y G},
			},
			GyMMMd => {
				G => q{d, MMM y G – d, MMM y G},
				M => q{d, MMM – d, MMM y G},
				d => q{d – d, MMM y G},
				y => q{d, MMM y – d, MMM y G},
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
				d => q{d – d MMM},
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
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, d/M/y – E, d/M/y},
				d => q{E, d/M/y – E, d/M/y},
				y => q{E, d/M/y – E, d/M/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM – E, d MMM, y},
				d => q{E, d MMM – E, d MMM, y},
				y => q{E, d MMM, y – E, d MMM, y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM, y},
				d => q{d – d MMM, y},
				y => q{d MMM, y – d MMM, y},
			},
			yMd => {
				M => q{d/M/y – d/M/y},
				d => q{d/M/y – d/M/y},
				y => q{d/M/y – d/M/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		'Afghanistan' => {
			long => {
				'standard' => q#Hora de Afganistán#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abiyán#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Acra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Adís Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Argel#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#El Cairo#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Yibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Duala#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Johannesburgo#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Jartum#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadiscio#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunez#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Hora de Africa Central#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Hora de Africa Oriental#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Hora de Sudafrica#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Hora Estandar de Verano de Africa Occidental#,
				'generic' => q#Hora de Africa Occidental#,
				'standard' => q#Hora Estandar de Africa Occidental#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Hora de Verano de Alaska#,
				'generic' => q#Hora de Alaska#,
				'standard' => q#Hora Estandar de Alaska#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Hora de Verano de Amazonas#,
				'generic' => q#Hora de Amazonas#,
				'standard' => q#Hora Estandar de Amazonas#,
			},
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguila#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Belize' => {
			exemplarCity => q#Belice#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curazao#,
		},
		'America/Grenada' => {
			exemplarCity => q#Granada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadalupe#,
		},
		'America/Havana' => {
			exemplarCity => q#La Habana#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinica#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Ciudad de Mexico#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Puerto Príncipe#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Puerto España#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#San Bartolomé#,
		},
		'America/St_Johns' => {
			exemplarCity => q#San Juan de Terranova#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#San Cristobal#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Santa Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Santo Tomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#San Vicente#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Hora Central de Verano#,
				'generic' => q#Hora Central#,
				'standard' => q#Estandard Hora Central#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Hora de Verano del Este#,
				'generic' => q#Hora del Este#,
				'standard' => q#Hora Estandar del Este#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Hora de Verano de la Montaña#,
				'generic' => q#Hora de la Montaña#,
				'standard' => q#Hora Estandar de la Montaña#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Hora de Verano del Pacífico#,
				'generic' => q#Hora del Pacífico#,
				'standard' => q#Hora Estandar del Pacífico#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#Hora de Verano de Apia#,
				'generic' => q#Hora de Apia#,
				'standard' => q#Hora Estandar de Apia#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Hora de Verano de Arabia#,
				'generic' => q#Hora de Arabia#,
				'standard' => q#Hora Estandar de Arabia#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Hora de Verano de Argentina#,
				'generic' => q#Hora de Argentina#,
				'standard' => q#Hora Estandar de Argentina#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Hora de Verano del Oeste de Argentina#,
				'generic' => q#Hora del Oeste de Argentina#,
				'standard' => q#Hora Estandar del Oeste de Argentina#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Hora de Verano de Armenia#,
				'generic' => q#Hora de Armenia#,
				'standard' => q#Hora Estandar de Armenia#,
			},
		},
		'Asia/Amman' => {
			exemplarCity => q#Amán#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Asjabad#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Baréin#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damasco#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dusambé#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Yakarta#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandú#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Macasar#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Mascate#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pionyang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Catar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanái#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangún#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riad#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Samarcanda#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seúl#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shangái#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taskent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tiflis#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teherán#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Ekaterinburgo#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Ereván#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Hora De Verano del Atlántico#,
				'generic' => q#Hora del Atlántico#,
				'standard' => q#Hora Estandar del Atlántico#,
			},
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Canarias#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Cabo Verde#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Georgia del Sur#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Santa Elena#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaida#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sidney#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Hora de Verano de Australia Central#,
				'generic' => q#Hora de Australia Central#,
				'standard' => q#Hora Estandar de Australia Central#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Hora de Verano de Australia Central Occidental#,
				'generic' => q#Hora de Australia Central Occidental#,
				'standard' => q#Hora Estandar de Australia Central Occidental#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Hora de Verano de Australia Oriental#,
				'generic' => q#Hora de Australia Oriental#,
				'standard' => q#Hora Estandar de Australia Oriental#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Hora de Verano de Australia Occidental#,
				'generic' => q#Hora de Australia Occidental#,
				'standard' => q#Hora Estandar de Australia Occidental#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Hora de Verano de Azerbaiyán#,
				'generic' => q#Hora de Azerbaiyán#,
				'standard' => q#Hora Estandar de Azerbaiyán#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Hora de Verano de las Azores#,
				'generic' => q#Hora de las Azores#,
				'standard' => q#Hora Estandar de las Azores#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Hora de Verano de Bangladesh#,
				'generic' => q#Hora de Bangladesh#,
				'standard' => q#Hora Estandar de Bangladesh#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Hora de Bután#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolivia Time#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Hora de Verano de Brasilia#,
				'generic' => q#Hora de Brasilia#,
				'standard' => q#Hora Estandar de Brasilia#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Hora de Brunei Darussalam#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Hora de Verano de Cabo Verde#,
				'generic' => q#Hora de Cabo Verde#,
				'standard' => q#Hora Estandar de Cabo Verde#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Hora Estandar de Chamorro#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Hora de Verano de Chatham#,
				'generic' => q#Hora de Chatham#,
				'standard' => q#Hora Estandar de Chatham#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Hora de Verano de Chile#,
				'generic' => q#Hora de Chile#,
				'standard' => q#Hora Estandar de Chile#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Hora de Verano de China#,
				'generic' => q#Hora de China#,
				'standard' => q#Hora Estandar de China#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Hora de Verano de Choybalsan#,
				'generic' => q#Hora de Choybalsan#,
				'standard' => q#Hora Estandar de Choybalsan#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Hora de Isla Christmas#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Hora de Islas Cocos#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Hora de Verano de Colombia#,
				'generic' => q#Hora de Colombia#,
				'standard' => q#Hora Estandar de Colombia#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Hora de Verano de Isla Cocos#,
				'generic' => q#Hora de Islas Cook#,
				'standard' => q#Hora Estandar de Isla Cocos#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Hora de Verano de Cuba#,
				'generic' => q#Hora de Cuba#,
				'standard' => q#Hora Estandar de Cuba#,
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
				'daylight' => q#Hora de Verano de Isla de Pascua#,
				'generic' => q#Hora de Isla de Pascua#,
				'standard' => q#Hora Estandar de Isla de Pascua#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Hora de Ecuador#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Tiqsimuyuntin Tupachisqa Hora#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Mana risisqa llaqta#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bruselas#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bucarest#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Copenhague#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Hora Estandar de Irlanda#,
			},
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Isla de Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Estambul#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrado#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
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
				'daylight' => q#Hora de Verano Británico#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxemburgo#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moscú#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Estocolmo#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#El Vaticano#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viena#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgogrado#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varsovia#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Hora de Verano de Europa Central#,
				'generic' => q#Hora de Europa Central#,
				'standard' => q#Hora Estandar de Europa Central#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Hora de Verano de Europa Oriental#,
				'generic' => q#Hora de Europa Oriental#,
				'standard' => q#Hora Estandar de Europa Oriental#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Hora de Verano más Oriental de Europa#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Hora de Verano de Europa Occidental#,
				'generic' => q#Hora de Europa Occidental#,
				'standard' => q#Hora Estandar de Europa Occidental#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Hora de Verano de Islas Malvinas#,
				'generic' => q#Hora de Islas Malvinas#,
				'standard' => q#Hora Estandar de Islas Malvinas#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Hora de Verano de Fiji#,
				'generic' => q#Hora de Fiji#,
				'standard' => q#Hora Estandar de Fiji#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Hora de Guayana Francesa#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Hora Francés meridional y antártico#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Hora del Meridiano de Greenwich#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Hora de Islas Galápagos#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Hora de Gambier#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Hora de Verano de Georgia#,
				'generic' => q#Hora de Georgia#,
				'standard' => q#Hora Estandar de Georgia#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Hora de Islas Gilbert#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Hora de Verano de Groenlandia#,
				'generic' => q#Hora de Groenlandia#,
				'standard' => q#Hora Estandar de Groenlandia#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Hora de Verano de Groenlandia Occidental#,
				'generic' => q#Hora de Groenlandia Occidental#,
				'standard' => q#Hora Estandar de Groenlandia Occidental#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Hora Estandar del Golfo#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Hora de Guyana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hora de Verano de Hawai-Aleutiano#,
				'generic' => q#Hora de Hawai-Aleutiano#,
				'standard' => q#Hora Estandar de Hawai-Aleutiano#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hora de Verano de Hong Kong#,
				'generic' => q#Hora de Hong Kong#,
				'standard' => q#Hora Estandar de Hong Kong#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hora de Verano de Hovd#,
				'generic' => q#Hora de Hovd#,
				'standard' => q#Hora Estandar de Hovd#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Hora Estandar de India#,
			},
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivas#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Hora del Oceano Índico#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Hora de Indochina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Hora de Indonesia Central#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Hora de Indonesia Oriental#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Hora de Indonesia Occidental#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Hora de Verano de Irán#,
				'generic' => q#Hora de Irán#,
				'standard' => q#Hora Estandar de Irán#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Hora de Verano de Irkutsk#,
				'generic' => q#Hora de Irkutsk#,
				'standard' => q#Hora Estandar de Irkutsk#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Hora de Verano de Israel#,
				'generic' => q#Hora de Israel#,
				'standard' => q#Hora Estandar de Israel#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Hora de Verano de Japón#,
				'generic' => q#Hora de Japón#,
				'standard' => q#Hora Estandar de Japón#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Hora de Kazajistán Oriental#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Hora de Kazajistán del Oeste#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Hora de Verano de Corea#,
				'generic' => q#Hora de Corea#,
				'standard' => q#Hora Estandar de Corea#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Hora de Kosrae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Hora de Verano de Krasnoyarsk#,
				'generic' => q#Hora de Krasnoyarsk#,
				'standard' => q#Hora Estandar de Krasnoyarsk#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Hora de Kirguistán#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Hora de Espóradas Ecuatoriales#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Hora de Verano de Lord Howe#,
				'generic' => q#Hora de Lord Howe#,
				'standard' => q#Hora Estandar de Lord Howe#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Hora de Isla Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Hora de Verano de Magadan#,
				'generic' => q#Hora de Magadan#,
				'standard' => q#Hora Estandar de Magadan#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Hora de Malasia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Hora de Maldivas#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Hora de Marquesas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Hora de Islas Marshall#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Hora de Verano de Mauricio#,
				'generic' => q#Hora de Mauricio#,
				'standard' => q#Hora Estandar de Mauricio#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Hora de Mawson#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Hora de Verano del Noroeste de México#,
				'generic' => q#Hora Estandar de Verano de México#,
				'standard' => q#Hora Estandar del Noroeste de México#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Hora de Verano del Pacífico Mexicano#,
				'generic' => q#Hora del Pacífico Mexicano#,
				'standard' => q#Hora Estandar del Pacífico Mexicano#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Hora de Verano de Ulán Bator#,
				'generic' => q#Hora de Ulán Bator#,
				'standard' => q#Hora Estandar de Ulán Bator#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Hora de Verano de Moscú#,
				'generic' => q#Hora de Moscú#,
				'standard' => q#Hora Estandar de Moscú#,
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
				'standard' => q#Hora de Nepal#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Hora de Verano de Nueva Caledonia#,
				'generic' => q#Hora de Nueva Caledonia#,
				'standard' => q#Hora Estandar de Nueva Caledonia#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Hora de Verano de Nueva Zelanda#,
				'generic' => q#Hora de Nueva Zelanda#,
				'standard' => q#Hora Estandar de Nueva Zelanda#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Hora de Verano de Terranova#,
				'generic' => q#Hora de Terranova#,
				'standard' => q#Hora Estandar de Terranova#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Hora de Niue#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Hora de Verano de la Isla Norfolk#,
				'generic' => q#Hora de la Isla Norfolk#,
				'standard' => q#Hora Estandar de la Isla Norfolk#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Hora de Verano de Fernando de Noronha#,
				'generic' => q#Hora de Fernando de Noronha#,
				'standard' => q#Hora Estandar de Fernando de Noronha#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Hora de Verano de Novosibirsk#,
				'generic' => q#Hora de Novosibirsk#,
				'standard' => q#Hora Estandar de Novosibirsk#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Hora de Verano de Omsk#,
				'generic' => q#Hora de Omsk#,
				'standard' => q#Hora Estandar de Omsk#,
			},
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Hora de Verano de Pakistán#,
				'generic' => q#Hora de Pakistán#,
				'standard' => q#Hora Estandar de Pakistán#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Hora de Palau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Hora de Papua Nueva Guinea#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Hora de Verano de Paraguay#,
				'generic' => q#Hora de Paraguay#,
				'standard' => q#Hora Estandar de Paraguay#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Hora de Verano de Perú#,
				'generic' => q#Hora de Perú#,
				'standard' => q#Hora Estandar de Perú#,
			},
			short => {
				'daylight' => q#PEST#,
				'generic' => q#PET#,
				'standard' => q#PET#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Hora de Verano de Filipinas#,
				'generic' => q#Hora de Filipinas#,
				'standard' => q#Hora Estandar de Filipinas#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Hora de Islas Phoenix#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Hora de Verano de San Pedro y Miquelón#,
				'generic' => q#Hora de San Pedro y Miquelón#,
				'standard' => q#Hora Estandar de San Pedro y Miquelón#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Hora de Pitcairn#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Hora de Pohnpei#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Hora de Pionyang#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Hora de Réunion#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Hora de Rothera#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Hora de Verano de Sakhalin#,
				'generic' => q#Hora de Sakhalin#,
				'standard' => q#Hora Estandar de Sakhalin#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Hora de Verano de Samoa#,
				'generic' => q#Hora de Samoa#,
				'standard' => q#Hora Estandar de Samoa#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Hora de Seychelles#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Hora Estandar de Singapur#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Hora de Islas Salomón#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Hora de Georgia del Sur#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Hora de Surinam#,
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
				'daylight' => q#Hora de Verano de Taipéi#,
				'generic' => q#Hora de Taipéi#,
				'standard' => q#Hora Estandar de Taipéi#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Hora de Tayikistán#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Hora de Tokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Hora de Verano de Tonga#,
				'generic' => q#Hora de Tonga#,
				'standard' => q#Hora Estandar de Tonga#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Hora de Chuuk#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Hora de Verano de Turkmenistán#,
				'generic' => q#Hora de Turkmenistán#,
				'standard' => q#Hora Estandar de Turkmenistán#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Hora de Tuvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Hora de Verano de Uruguay#,
				'generic' => q#Hora de Uruguay#,
				'standard' => q#Hora Estandar de Uruguay#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Hora de Verano de Uzbekistán#,
				'generic' => q#Hora de Uzbekistán#,
				'standard' => q#Hora Estandar de Uzbekistán#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Hora de Verano de Vanuatu#,
				'generic' => q#Hora de Vanuatu#,
				'standard' => q#Hora Estandar de Vanuatu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Hora de Venezuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Hora de Verano de Vladivostok#,
				'generic' => q#Hora de Vladivostok#,
				'standard' => q#Hora Estandar de Vladivostok#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Hora de Verano de Volgogrado#,
				'generic' => q#Hora de Volgogrado#,
				'standard' => q#Hora Estandar de Volgogrado#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Hora de Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Hora de Isla Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Hora de Wallis y Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Hora de Verano de Yakutsk#,
				'generic' => q#Hora de Yakutsk#,
				'standard' => q#Hora Estandar de Yakutsk#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Hora de Verano de Ekaterinburgo#,
				'generic' => q#Hora de Ekaterinburgo#,
				'standard' => q#Hora Estandar de Ekaterinburgo#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Yukon Ura#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
