=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Pcm - Package for language Nigerian Pidgin

=cut

package Locale::CLDR::Locales::Pcm;
# This file auto generated from Data\common\main\pcm.xml
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
				'af' => 'Áfríkaans Lángwej',
 				'agq' => 'Aghẹ́m Lángwej',
 				'ak' => 'Akan Lángwej',
 				'am' => 'Amhárík Lángwej',
 				'ar' => 'Arábík Lángwej',
 				'ar_001' => 'Gẹ́nárál Arábík Lángwej fọ dís taim',
 				'as' => 'Asamíz Lángwej',
 				'asa' => 'Asu Lángwej',
 				'ast' => 'Astúriá Lángwej',
 				'az' => 'Azẹrbaijáni Lángwej',
 				'bas' => 'Básaa Lángwej',
 				'be' => 'Bẹlarúsiá Lángwej',
 				'bem' => 'Bẹ́mba Lángwej',
 				'bez' => 'Bẹ́na Lángwej',
 				'bg' => 'Bọlgériá Lángwej',
 				'bm' => 'Bambára Lángwej',
 				'bn' => 'Bángla Lángwej',
 				'bo' => 'Tibẹ́tan',
 				'br' => 'Brẹ́tọn Lángwej',
 				'brx' => 'Bódo Lángwej',
 				'bs' => 'Bọ́sniá Lángwej',
 				'ca' => 'Kátála Lángwej',
 				'ccp' => 'Chákma Lángwej',
 				'ce' => 'Chẹ́chẹn Lángwej',
 				'ceb' => 'Sẹbuáno Lángwej',
 				'cgg' => 'Chíga Lángwej',
 				'chr' => 'Chẹ́rókii Lángwej',
 				'ckb' => 'Mídúl Kọ́dish Lángwej',
 				'ckb@alt=menu' => 'Sẹ́ntrál Kọ́dísh Lángwej',
 				'ckb@alt=variant' => 'Sorání Kọ́dísh Lángwej',
 				'co' => 'Kọsíkan Lángwej',
 				'cs' => 'Chẹ́k Lángwej',
 				'cu' => 'Chọ́ch Slávik',
 				'cy' => 'Wẹlsh',
 				'da' => 'Dénísh Lángwej',
 				'dav' => 'Taíta',
 				'de' => 'Jámán Lángwej',
 				'de_AT' => 'Ọ́stria Jámán',
 				'de_CH' => 'Swítzaland Haí Jámán',
 				'dje' => 'Zármá',
 				'doi' => 'Dogri',
 				'dsb' => 'Lówá Sorbiá',
 				'dua' => 'Duála Lángwej',
 				'dyo' => 'Jóla-Fónyi Lángwej',
 				'dz' => 'Zọ́ngka Lángwej',
 				'ebu' => 'Ẹmbu Lángwej',
 				'ee' => 'Ẹ́wẹ́ Lángwej',
 				'el' => 'Grík Lángwej',
 				'en' => 'Ínglish',
 				'en_AU' => 'Ọstréliá Ínglish',
 				'en_CA' => 'Kánáda Ínglish',
 				'en_GB' => 'Brítísh Ínglish',
 				'en_GB@alt=short' => 'UK Ínglish',
 				'en_US' => 'Amẹ́ríka Ínglish',
 				'en_US@alt=short' => 'US Ínglish',
 				'eo' => 'Ẹsperánto Lángwej',
 				'es' => 'Spánish Lángwej',
 				'es_419' => 'Látín Amẹ́ríka Spánish',
 				'es_ES' => 'Yúrop Spánish',
 				'es_MX' => 'Mẹ́ksiko Spánish',
 				'et' => 'Ẹstóniá Lángwej',
 				'eu' => 'Básk Lángwej',
 				'ewo' => 'Ẹwondo Lángwej',
 				'fa' => 'Pẹ́shiá Lángwej',
 				'fa_AF' => 'Dári',
 				'ff' => 'Fúlaní Lángwej',
 				'fi' => 'Fínísh Lángwej',
 				'fil' => 'Filipínó Lángwej',
 				'fo' => 'Fáróís Lángwej',
 				'fr' => 'Frẹ́nch Lángwej',
 				'fr_CA' => 'Kánádá Frẹnch',
 				'fr_CH' => 'Swítzalánd Frẹnch',
 				'fur' => 'Friúlián Lángwej',
 				'fy' => 'Wẹ́stán Frísiá Lángwej',
 				'ga' => 'Aírísh Lángwej',
 				'gd' => 'Gaelík Lángwej ọf Gael Pípol fọ Skọ́tland',
 				'gl' => 'Galísiá Lángwej',
 				'gsw' => 'Jámán Swis',
 				'gu' => 'Gujarátí Lángwej',
 				'guz' => 'Gusí Lángwej',
 				'gv' => 'Mánks Lángwej',
 				'ha' => 'Háusá Lángwej',
 				'haw' => 'Hawaii Lángwej',
 				'he' => 'Híbru Lángwej',
 				'hi' => 'Híndi Lángwej',
 				'hmn' => 'Mọ́ng Lángwej',
 				'hr' => 'Kroéshia Lángwej',
 				'hsb' => 'Sóbiá Lángwej di ọ́p-ọ́p wan',
 				'ht' => 'Haítí Kriol',
 				'hu' => 'Họngári Lángwej',
 				'hy' => 'Armẹ́niá Lángwej',
 				'ia' => 'Intalíngwuá Lángwej',
 				'id' => 'Indoníshia Lángwej',
 				'ig' => 'Igbo Lángwej',
 				'ii' => 'Síchuan Yi',
 				'is' => 'Aíslánd Lángwej',
 				'it' => 'Ítáli Lángwej',
 				'ja' => 'Japan Lángwej',
 				'jgo' => 'Ngómbá Lángwej',
 				'jmc' => 'Machámẹ́ Lángwej',
 				'jv' => 'Javáníz Lángwej',
 				'ka' => 'Jọ́jiá Lángwej',
 				'kab' => 'Kabail Lángwej',
 				'kam' => 'Kámbá Lángwej',
 				'kde' => 'Makọ́ndẹ́ Lángwej',
 				'kea' => 'Kábúvẹrdiánu Lángwej',
 				'khq' => 'Koyra Chíní Lángwej',
 				'ki' => 'Kikúyú Lángwej',
 				'kk' => 'Kazák Lángwej',
 				'kkj' => 'Kákó Lángwej',
 				'kl' => 'Kalálísút Lángwej',
 				'kln' => 'Kálẹ́njín Lángwej',
 				'km' => 'Kmaí Lángwej',
 				'kn' => 'Kánnáda Lángwej',
 				'ko' => 'Koriá Lángwej',
 				'kok' => 'Kónkéní Lángwej',
 				'ks' => 'Kashmírí Lángwej',
 				'ksb' => 'Shambala',
 				'ksf' => 'Bafiá Lángwej',
 				'ksh' => 'Kọlónián Lángwej',
 				'ku' => 'Kọ́dísh Lángwej',
 				'kw' => 'Kọ́nish Lángwej',
 				'ky' => 'Kiẹ́gíz Lángwej',
 				'la' => 'Látín Lángwej',
 				'lag' => 'Langi Lángwej',
 				'lb' => 'Lọ́ksémbọ́g Lángwej',
 				'lg' => 'Gánda Lángwej',
 				'lkt' => 'Lakótá Lángwej',
 				'ln' => 'Lingálá Lángwej',
 				'lo' => 'Láo Lángwej',
 				'lrc' => 'Nọ́tán Lúrí Lángwej',
 				'lt' => 'Lituéniá Lángwej',
 				'lu' => 'Lúbá-Katángá Lángwej',
 				'luo' => 'Luó Lángwej',
 				'luy' => 'Luyia Lángwej',
 				'lv' => 'Látvián Lángwej',
 				'mai' => 'Maítíli',
 				'mas' => 'Masaí Lángwej',
 				'mer' => 'Mẹ́rú Lángwej',
 				'mfe' => 'Morísiẹ́n Lángwej',
 				'mg' => 'Malagásí Lángwej',
 				'mgh' => 'Makúwá-Mító',
 				'mgo' => 'Mẹta’ Lángwej',
 				'mi' => 'Maórí Lángwej',
 				'mk' => 'Masẹdóniá Lángwej',
 				'ml' => 'Maléyálám Lángwej',
 				'mn' => 'Mọngóliá Lángwej',
 				'mni' => 'Manípuri',
 				'mr' => 'Marátí Lángwej',
 				'ms' => 'Malé Lángwej',
 				'mt' => 'Mọ́ltá Lángwej',
 				'mua' => 'Mundáng Lángwej',
 				'mul' => 'Plẹ́ntí Lángwej-dẹm',
 				'my' => 'Bọ́ma Lángwej',
 				'mzn' => 'Mazandẹrání Lángwej',
 				'naq' => 'Naámá Lángwej',
 				'nb' => 'Nọwẹ́jiá Bokmál Lángwej',
 				'nd' => 'Nọ́tán Ndẹbẹlẹ Lángwej',
 				'nds' => 'Ló Jámán Lángwej',
 				'ne' => 'Nẹpálí Lángwej',
 				'nl' => 'Dọch Lángwej',
 				'nl_BE' => 'Flẹ́mish Lángwej',
 				'nmg' => 'Kwasió Lángwej',
 				'nn' => 'Nọwẹ́jiá Niúnọsk',
 				'nnh' => 'Ngiẹ́mbọn Lángwej',
 				'no' => 'Nọ́wẹ́jiá Lángwej',
 				'nus' => 'Núa',
 				'ny' => 'Nyánja',
 				'nyn' => 'Nyankólẹ',
 				'om' => 'Orómó',
 				'or' => 'Ódiá',
 				'os' => 'Osẹ́tik',
 				'pa' => 'Punjábi',
 				'pcm' => 'Naijíriá Píjin',
 				'pl' => 'Pólánd Lángwej',
 				'prg' => 'Prúshia',
 				'ps' => 'Páshto',
 				'pt' => 'Pọtiugiz',
 				'pt_BR' => 'Brazíl Pọtiugíz',
 				'pt_PT' => 'Yúróp Pọtiugíz',
 				'qu' => 'Kẹchuá',
 				'rhg' => 'Rohínjia',
 				'rm' => 'Románsh',
 				'rn' => 'Rúndi',
 				'ro' => 'Romániá Lángwej',
 				'rof' => 'Rómbo',
 				'ru' => 'Rọshiá Lángwej',
 				'rw' => 'Kinyarwánda Lángwej',
 				'rwk' => 'Rwa',
 				'sa' => 'Sánskrit',
 				'sah' => 'Sakhá',
 				'saq' => 'Sambúru',
 				'sat' => 'Sántáli',
 				'sbp' => 'Sangu',
 				'sd' => 'Síndí',
 				'se' => 'Nọ́tán Sámí Lángwej',
 				'seh' => 'Sẹ́ná',
 				'ses' => 'Kóiraboró Sẹ́nní Lángwej',
 				'sg' => 'sàngo',
 				'shi' => 'Táchẹ́lit',
 				'si' => 'Sínhala',
 				'sk' => 'Slóvak',
 				'sl' => 'Slovẹ́niá Lángwej',
 				'sm' => 'Samóá Lángwej',
 				'smn' => 'Ínárí Sámí Lángwej',
 				'sn' => 'Shóna',
 				'so' => 'Sọmáli',
 				'sq' => 'Albéniá Lángwej',
 				'sr' => 'Sẹrbiá Lángwej',
 				'st' => 'Saútán Sóto',
 				'su' => 'Sọ́ndaniz',
 				'sv' => 'Suwídẹ́n Lángwej',
 				'sw' => 'Swahíli',
 				'ta' => 'tàmil',
 				'te' => 'Tẹlugu',
 				'teo' => 'Tẹ́so',
 				'tg' => 'Tájik',
 				'th' => 'Taí',
 				'ti' => 'Tigrínyá',
 				'tk' => 'Tọ́kmẹn',
 				'to' => 'Tóngan',
 				'tr' => 'Tọ́ki',
 				'tt' => 'Tatá',
 				'twq' => 'Tasawak',
 				'tzm' => 'Mídúl Atlás Támazígt Lángwej',
 				'ug' => 'Wiúgọ',
 				'uk' => 'Yukrénia',
 				'und' => 'Lángwej wé nóbọ́di sabi',
 				'ur' => 'Úrdú',
 				'uz' => 'Úzbẹk',
 				'vai' => 'Vaí',
 				'vi' => 'Viẹ́tnám Lángwej',
 				'vo' => 'Vólapiuk',
 				'vun' => 'Vúnjo',
 				'wae' => 'Wọ́lsa',
 				'wo' => 'Wólof',
 				'xh' => 'Kọ́sa',
 				'xog' => 'sóga',
 				'yav' => 'Yangbẹn',
 				'yi' => 'Yídish',
 				'yo' => 'Yorubá',
 				'yue' => 'Kántọn Lángwej',
 				'yue@alt=menu' => 'Chainiz Kántọniz',
 				'zgh' => 'Gẹ́nárál Morókó Támazígt Lángwej',
 				'zh' => 'Mandarín Chainíz Lángwej',
 				'zh@alt=menu' => 'Chainiz, Mandarin',
 				'zh_Hans' => 'Ízí Chainíz Lángwej',
 				'zh_Hans@alt=long' => 'Ízí Mandarín Chainíz Lángwej',
 				'zh_Hant' => 'Tradíshọ́nál Chainíz Lángwej',
 				'zh_Hant@alt=long' => 'Tradíshọ́nál Mandarín Chainíz Lángwej',
 				'zu' => 'Zúlu',
 				'zxx' => 'Nó Lángwéj Kọ́ntẹnt',

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
			'Arab' => 'Arábík',
 			'Armn' => 'Armẹ́nia',
 			'Beng' => 'Bángla',
 			'Bopo' => 'Bopomófo',
 			'Brai' => 'Blaínd Pípol Raítín Sístẹm',
 			'Cyrl' => 'Sírílik',
 			'Deva' => 'Dẹvanágári',
 			'Ethi' => 'Ẹtiópik',
 			'Geor' => 'Jọ́jia',
 			'Grek' => 'Grík',
 			'Gujr' => 'Gujaráti',
 			'Guru' => 'Gúrmukhi',
 			'Hanb' => 'Han Wit Bopomófo',
 			'Hang' => 'Hángul',
 			'Hani' => 'Chainiz',
 			'Hans' => 'Ízí Chainíz Lángwej',
 			'Hans@alt=stand-alone' => 'Ízí Chainíz Lang',
 			'Hant' => 'Nọ́mal',
 			'Hant@alt=stand-alone' => 'Nọ́mál Chainiz',
 			'Hebr' => 'Híbrú',
 			'Hira' => 'Hiagána',
 			'Hrkt' => 'Pát ọf Japán Raítín Sístẹm',
 			'Jamo' => 'Jámo',
 			'Jpan' => 'Japan',
 			'Kana' => 'Katákána',
 			'Khmr' => 'Kemẹẹ',
 			'Knda' => 'Kánnad Raítín Sístẹm',
 			'Kore' => 'Koria',
 			'Laoo' => 'Lao',
 			'Latn' => 'Látin',
 			'Mlym' => 'Maléyálam',
 			'Mong' => 'Mọngólia',
 			'Mymr' => 'Miánmar',
 			'Orya' => 'Ódia',
 			'Sinh' => 'Sinhála',
 			'Taml' => 'Támil',
 			'Telu' => 'Tẹ́lúgu',
 			'Thaa' => 'Tána',
 			'Thai' => 'Taí',
 			'Tibt' => 'Tíbẹt',
 			'Zmth' => 'Matimátiks Sains',
 			'Zsye' => 'Ẹ́móji',
 			'Zsym' => 'Símbuls',
 			'Zxxx' => 'Wétín Dẹm Nó Rait',
 			'Zyyy' => 'Jẹ́náral',
 			'Zzzz' => 'Raítín Sístẹm Wé Nóbọ́di Sabí',

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
			'001' => 'Wọld',
 			'002' => 'Áfríka',
 			'003' => 'Nọ́t Amẹ́ríka',
 			'005' => 'Saút Amẹ́ríka',
 			'009' => 'Oshẹnia',
 			'011' => 'Wẹ́stán Áfríka',
 			'013' => 'Mídúl Amẹ́ríka',
 			'014' => 'Ístán Áfríká',
 			'015' => 'Nọ́tán Áfríka',
 			'017' => 'Mídúl Áfríka',
 			'018' => 'Saútán Áfríka',
 			'019' => 'Amẹ́ríkas',
 			'021' => 'Nọ́tán Amẹ́ríka',
 			'029' => 'Karíbián',
 			'030' => 'Ístán Éshia',
 			'034' => 'Saútán Éshia',
 			'035' => 'Saútíst Éshiá',
 			'039' => 'Saútán Yúrop',
 			'053' => 'Ọstraléshia',
 			'054' => 'Mẹlanẹíshia',
 			'057' => 'Maikroníshia Ríjọn',
 			'061' => 'Poliníshiá',
 			'142' => 'Éshia',
 			'143' => 'Mídúl Éshia',
 			'145' => 'Wẹ́stán Éshia',
 			'150' => 'Yúrop',
 			'151' => 'Ístán Yúrop',
 			'154' => 'Nọ́tán Yúrop',
 			'155' => 'Wẹ́stán Yúrop',
 			'202' => 'Áfríka Éria Biló Sahára',
 			'419' => 'Látín Amẹ́ríka',
 			'AC' => 'Asẹ́nshọ́n Aíland',
 			'AD' => 'Andọ́ra',
 			'AE' => 'Yunaítẹ́d Áráb Ẹ́mírets',
 			'AF' => 'Afgánístan',
 			'AG' => 'Antígwua & Barbúda',
 			'AI' => 'Angwíla',
 			'AL' => 'Albénia',
 			'AM' => 'Armẹ́niá',
 			'AO' => 'Angóla',
 			'AQ' => 'Antáktíka',
 			'AR' => 'Ajẹntína',
 			'AS' => 'Amẹ́ríká Samoa',
 			'AT' => 'Ọ́stria',
 			'AU' => 'Ọstrélia',
 			'AW' => 'Arúba',
 			'AX' => 'Ọ́lánd Aílands',
 			'AZ' => 'Azẹrbaijan',
 			'BA' => 'Bọ́zniá & Hẹzẹgovína',
 			'BB' => 'Barbédọs',
 			'BD' => 'Bangladẹsh',
 			'BE' => 'Bẹ́ljọm',
 			'BF' => 'Burkína Fáso',
 			'BG' => 'Bọlgéria',
 			'BH' => 'Barein',
 			'BI' => 'Burúndi',
 			'BJ' => 'Binin',
 			'BL' => 'Sént Batẹlẹ́mi',
 			'BM' => 'Bẹmiúda',
 			'BN' => 'Brunẹi',
 			'BO' => 'Bolívia',
 			'BQ' => 'Karíbián Nẹ́dalands',
 			'BR' => 'Brázil',
 			'BS' => 'Bahámas',
 			'BT' => 'Butan',
 			'BV' => 'Buvẹ́ Aíland',
 			'BW' => 'Botswána',
 			'BY' => 'Bẹ́larus',
 			'BZ' => 'Bẹliz',
 			'CA' => 'Kánáda',
 			'CC' => 'Kókós Aílands',
 			'CD' => 'Kóngó – Kinshása',
 			'CD@alt=variant' => 'Kóngo (DRC)',
 			'CF' => 'Sẹ́ntrál Áfríkán Ripọ́blik',
 			'CG' => 'Kóngo – Brázavil',
 			'CG@alt=variant' => 'Kóngó (Ripọ́blik)',
 			'CH' => 'Swítsaland',
 			'CI' => 'Aívri Kost',
 			'CI@alt=variant' => 'Kót Divua',
 			'CK' => 'Kúk Aílands',
 			'CL' => 'Chílẹ',
 			'CM' => 'Kamẹrun',
 			'CN' => 'Chaína',
 			'CO' => 'Kolómbia',
 			'CP' => 'Klipatọ́n Aíland',
 			'CR' => 'Kósta Ríka',
 			'CU' => 'Kiúbá',
 			'CV' => 'Kép Vẹ́d',
 			'CW' => 'Kiurásao',
 			'CX' => 'Krísmás Aíland',
 			'CY' => 'Saíprọs',
 			'CZ' => 'Chẹ́kia',
 			'CZ@alt=variant' => 'Chẹ́k Ripọ́blik',
 			'DE' => 'Jámáni',
 			'DG' => 'Diẹ́gó Garsia',
 			'DJ' => 'Jibúti',
 			'DK' => 'Dẹ́nmak',
 			'DM' => 'Dọmíníka',
 			'DO' => 'Dọmíníka Ripọ́blik',
 			'DZ' => 'Aljíria',
 			'EA' => 'Sẹúta & Mẹ́líla',
 			'EC' => 'Ẹ́kwuádọ',
 			'EE' => 'Ẹstónia',
 			'EG' => 'Íjipt',
 			'EH' => 'Wẹ́stán Sahára',
 			'ER' => 'Ẹritrẹ́a',
 			'ES' => 'Spen',
 			'ET' => 'Ẹtiópia',
 			'EU' => 'Yurópián Yúniọ́n',
 			'EZ' => 'Yúróéria',
 			'FI' => 'Fínland',
 			'FJ' => 'Fíji',
 			'FK' => 'Fọ́klánd Aílands',
 			'FK@alt=variant' => 'Fọ́klánd Aílands (Íslás Malvínas)',
 			'FM' => 'Maikroníshia',
 			'FO' => 'Fáro Aílands',
 			'FR' => 'Frans',
 			'GA' => 'Gabọn',
 			'GB' => 'Yunáítẹ́d Kíndọm',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Grẹnéda',
 			'GE' => 'Jọ́jia',
 			'GF' => 'Frẹ́nch Giána',
 			'GG' => 'Guẹnzi',
 			'GH' => 'Gána',
 			'GI' => 'Jibrọ́lta',
 			'GL' => 'Grínland',
 			'GM' => 'Gámbia',
 			'GN' => 'Gíni',
 			'GP' => 'Guadalúpẹ',
 			'GQ' => 'Ikwétóriál Gíni',
 			'GR' => 'Gris',
 			'GS' => 'Saút Jọ́jia an Saút Sándwích Aílands',
 			'GT' => 'Guátẹmála',
 			'GU' => 'Guam',
 			'GW' => 'Gíní-Bisáu',
 			'GY' => 'Gayána',
 			'HK' => 'Họng Kọng SAR',
 			'HK@alt=short' => 'Họng Kọng',
 			'HM' => 'Hiád & MakDónáld Aílands',
 			'HN' => 'Họndúras',
 			'HR' => 'Kroéshia',
 			'HT' => 'Haíti',
 			'HU' => 'Họ́ngári',
 			'IC' => 'Kenerí Aílands',
 			'ID' => 'Indoníshia',
 			'IE' => 'Ayaland',
 			'IL' => 'Ízrẹl',
 			'IM' => 'Aíl ọf Man',
 			'IN' => 'Índia',
 			'IO' => 'Brítísh Índián Óshen Tẹ́rẹ́tri',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Aísland',
 			'IT' => 'Ítáli',
 			'JE' => 'Jẹ́si',
 			'JM' => 'Jamaíka',
 			'JO' => 'Jọ́dan',
 			'JP' => 'Japan',
 			'KE' => 'Kẹ́nya',
 			'KG' => 'Kẹjístan',
 			'KH' => 'Kambódia',
 			'KI' => 'Kiribáti',
 			'KM' => 'Kọ́mọ́ros',
 			'KN' => 'Sent Kits & Nẹ́vis',
 			'KP' => 'Nọ́t Koria',
 			'KR' => 'Saút Koria',
 			'KW' => 'Kuwét',
 			'KY' => 'Kéman Aílands',
 			'KZ' => 'Kazakstan',
 			'LA' => 'Laos',
 			'LB' => 'Lẹ́bánọn',
 			'LC' => 'Sent Lúshia',
 			'LI' => 'Líktẹ́nstain',
 			'LK' => 'Sri Lánka',
 			'LR' => 'Laibẹ́ria',
 			'LS' => 'Lẹsóto',
 			'LT' => 'Lituénia',
 			'LU' => 'Lọ́ksẹ́mbọg',
 			'LV' => 'Látvia',
 			'LY' => 'Líbia',
 			'MA' => 'Morọko',
 			'MC' => 'Mọ́náko',
 			'MD' => 'Mọldóva',
 			'ME' => 'Mọntinígro',
 			'MF' => 'Sent Mátin',
 			'MG' => 'Madagáska',
 			'MH' => 'Máshál Aílands',
 			'MK' => 'Nọ́t Masidónia',
 			'ML' => 'Máli',
 			'MM' => 'Miánma (Bọ́ma)',
 			'MN' => 'Mọngólia',
 			'MO' => 'Makáo SAR Chaína',
 			'MO@alt=short' => 'Makáo',
 			'MP' => 'Nọ́tán Mariána Aílands',
 			'MQ' => 'Matínik',
 			'MR' => 'Mọriténia',
 			'MS' => 'Mọntsẹrat',
 			'MT' => 'Mọ́lta',
 			'MU' => 'Mọríshọs',
 			'MV' => 'Mọ́ldivs',
 			'MW' => 'Maláwi',
 			'MX' => 'Mẹ́ksíko',
 			'MY' => 'Maléshia',
 			'MZ' => 'Mozámbik',
 			'NA' => 'Namíbia',
 			'NC' => 'Niú Kalẹdónia',
 			'NE' => 'Nizhẹr',
 			'NF' => 'Nọ́fọlk Aíland',
 			'NG' => 'Naijíria',
 			'NI' => 'Nikarágwua',
 			'NL' => 'Nẹ́dalands',
 			'NO' => 'Nọ́we',
 			'NP' => 'Nẹ́pal',
 			'NR' => 'Náuru',
 			'NU' => 'Niúẹ',
 			'NZ' => 'Niú Zíland',
 			'OM' => 'Oman',
 			'PA' => 'Pánáma',
 			'PE' => 'Pẹ́ru',
 			'PF' => 'Frẹ́nch Poliníshia',
 			'PG' => 'Pápuá Niú Gíni',
 			'PH' => 'Fílípins',
 			'PK' => 'Pakístan',
 			'PL' => 'Póland',
 			'PM' => 'Sent Piẹr & Míkẹlọn',
 			'PN' => 'Pítkén Aílands',
 			'PR' => 'Puẹ́rto Ríkọ',
 			'PS' => 'Pálẹ́staín Éria-dẹm',
 			'PS@alt=short' => 'Pálẹ́stain',
 			'PT' => 'Pọ́túgal',
 			'PW' => 'Palau',
 			'PY' => 'Párágwue',
 			'QA' => 'Kata',
 			'QO' => 'Rimót Pát ọf Oshẹ́nia',
 			'RE' => 'Réyúniọn',
 			'RO' => 'Ruménia',
 			'RS' => 'Sẹ́bia',
 			'RU' => 'Rọ́shia',
 			'RW' => 'Ruwánda',
 			'SA' => 'Saúdí Arébia',
 			'SB' => 'Sólómọ́n Aílands',
 			'SC' => 'Sẹ́chẹls',
 			'SD' => 'Sudan',
 			'SE' => 'Swídẹn',
 			'SG' => 'Singapọ',
 			'SH' => 'Sent Hẹlẹ́na',
 			'SI' => 'Slovẹ́nia',
 			'SJ' => 'Sválbad & Jén Meyẹn',
 			'SK' => 'Slovékia',
 			'SL' => 'Siẹ́ra Líon',
 			'SM' => 'San Maríno',
 			'SN' => 'Sẹ́nẹ́gal',
 			'SO' => 'Sọmália',
 			'SR' => 'Súrínam',
 			'SS' => 'Saút Sudan',
 			'ST' => 'Sao Tómé & Prínsípẹ',
 			'SV' => 'El Sálvádọ',
 			'SX' => 'Sint Mátin',
 			'SY' => 'Síria',
 			'SZ' => 'Ẹswatíni',
 			'SZ@alt=variant' => 'Swáziland',
 			'TA' => 'Trístán da Kúna',
 			'TC' => 'Tọks an Kaíkọ́s Aílands',
 			'TD' => 'Chad',
 			'TF' => 'Frẹ́nch Saútán Tẹ́rẹ́tris',
 			'TG' => 'Tógo',
 			'TH' => 'Taíland',
 			'TJ' => 'Tajíkstan',
 			'TK' => 'Tókẹ́lau',
 			'TL' => 'Íst Tímọ',
 			'TM' => 'Tọkmẹ́nístan',
 			'TN' => 'Tuníshia',
 			'TO' => 'Tónga',
 			'TR' => 'Tọ́ki',
 			'TT' => 'Trínídad & Tobágo',
 			'TV' => 'Tuválu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzánia',
 			'UA' => 'Yukrein',
 			'UG' => 'Yugánda',
 			'UM' => 'U.S. Faá Faá Aílands',
 			'UN' => 'Yunaítẹd Néshọns',
 			'US' => 'Yunaítẹ́d Stets',
 			'US@alt=short' => 'US',
 			'UY' => 'Yúrugwue',
 			'UZ' => 'Uzbẹ́kistan',
 			'VA' => 'Vátíkán Síti',
 			'VC' => 'Sent Vínsẹnt & Grẹ́nádians',
 			'VE' => 'Vẹnẹzuẹ́la',
 			'VG' => 'Brítísh Vájín Aílands',
 			'VI' => 'U.S. Vájín Aílands',
 			'VN' => 'Viẹ́tnam',
 			'VU' => 'Vanuátu',
 			'WF' => 'Wọ́lis & Fiutúna',
 			'WS' => 'Samóa',
 			'XA' => 'To yúz atifíshál vọis wẹ́n yu de tọk',
 			'XB' => 'Atífíshál Tú-Wé Dairẹ́kshọn',
 			'XK' => 'Kósóvo',
 			'YE' => 'Yẹ́mẹn',
 			'YT' => 'Meyọt',
 			'ZA' => 'Saút Áfríka',
 			'ZM' => 'Zámbia',
 			'ZW' => 'Zimbábwẹ',
 			'ZZ' => 'Ríjọn Wé Nóbọ́di Sabí',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'Kalẹ́nda',
 			'cf' => 'Haú To Arénj Mọní',
 			'collation' => 'Arénj Tins Wẹl',
 			'currency' => 'Mọní',
 			'hc' => 'Awá Saíkul (12 vs 24)',
 			'lb' => 'Laín Brẹk Staíl',
 			'ms' => 'Sístẹm fọ Mẹ́zhọ́mẹnt',
 			'numbers' => 'Nọ́mba-dẹm',

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
 				'buddhist' => q{Búdíst Kalẹ́nda},
 				'chinese' => q{Chaíníz Kalẹ́nda},
 				'dangi' => q{Dangi Kalẹ́nda},
 				'ethiopic' => q{Ẹtiópiá Kalẹ́nda},
 				'gregorian' => q{Grẹ́górí Kalẹ́nda},
 				'hebrew' => q{Híbrú Kalẹ́nda},
 				'islamic' => q{Múslím Kalẹ́nda},
 				'iso8601' => q{ISO-8601 Kalẹ́nda},
 				'japanese' => q{Japán Kalẹ́nda},
 				'persian' => q{Pẹ́shia Kalẹ́nda},
 				'roc' => q{Ripọ́blík ọf Chaíná Kalẹ́nda},
 			},
 			'cf' => {
 				'account' => q{Akáunt To Ték Arénj Mọní},
 				'standard' => q{Nọ́mál Wè To Arénj Mọní},
 			},
 			'collation' => {
 				'ducet' => q{Yúníkód Mén Wè To Arénj Tins Wẹl},
 				'search' => q{Jẹ́nárál Sachin},
 				'standard' => q{Nọ́mál Wè To Arénj Tins Wẹl},
 			},
 			'hc' => {
 				'h11' => q{12 Áwa Sístẹm (0–11)},
 				'h12' => q{12 Áwa Sístẹm (1–12)},
 				'h23' => q{24 Áwa Sístẹm (0–23)},
 				'h24' => q{24 Áwa Sístẹm (1–24)},
 			},
 			'lb' => {
 				'loose' => q{Lúz Laín Brẹk Staíl},
 				'normal' => q{Nọ́mál Laín Brẹk Staíl},
 				'strict' => q{Fíksd Laín Brẹk Staíl},
 			},
 			'ms' => {
 				'metric' => q{Mẹ́trík Sístẹm},
 				'uksystem' => q{Impẹ́riál Sístẹm fọ Mẹ́zhọ́mẹnt},
 				'ussystem' => q{US Sístẹm fọ Mẹ́zhọ́mẹnt},
 			},
 			'numbers' => {
 				'arab' => q{Arábík Nọ́mba-dẹm},
 				'arabext' => q{Ẹstrá Arábík Nọ́mba-dẹm},
 				'armn' => q{Armẹ́niá Nọ́mba-dẹm},
 				'armnlow' => q{Smọ́l Taíp Armẹ́niá Nọ́mba-dẹm},
 				'beng' => q{Bánglá Nọ́mba-dẹm},
 				'deva' => q{Dẹvanágári Nọ́mba-dẹm},
 				'ethi' => q{Ẹtiópiá Nọ́mba-dẹm},
 				'fullwide' => q{Fúl-Waid Nọ́mba-dẹm},
 				'geor' => q{Jọ́jiá Nọ́mba-dẹm},
 				'grek' => q{Grík Nọ́mba-dẹm},
 				'greklow' => q{Smọ́l Taíp Grík Nọ́mba-dẹm},
 				'gujr' => q{Gujarátí Nọ́mba-dẹm},
 				'guru' => q{Gúrmukhi Nọ́mba-dẹm},
 				'hanidec' => q{Chainíz Nọ́mba-dẹm},
 				'hans' => q{Ízí Chainíz Nọ́mba-dẹm},
 				'hansfin' => q{Ízí Chainíz Mọní Nọ́mba-dẹm},
 				'hant' => q{Nọ́mál Chainíz Nọ́mba-dẹm},
 				'hantfin' => q{Nọ́mál Chainíz Mọní Nọ́mba-dẹm},
 				'hebr' => q{Híbru Nọ́mba-dẹm},
 				'jpan' => q{Japán Nọ́mba-dẹm},
 				'jpanfin' => q{Japán Mọní Nọ́mba-dẹm},
 				'khmr' => q{Kmai Nọ́mba-dẹm},
 				'knda' => q{Kánnád Nọ́mba-dẹm},
 				'laoo' => q{Lao Nọ́mba-dẹm},
 				'latn' => q{Wẹ́stán Nọ́mba-dẹm},
 				'mlym' => q{Maléyálam Nọ́mba-dẹm},
 				'mymr' => q{Miánma Nọ́mba-dẹm},
 				'orya' => q{Ódia Nọ́mba-dẹm},
 				'roman' => q{Rómán Nọ́mba-dẹm},
 				'romanlow' => q{Smọ́l Taíp Rómán Nọ́mba-dẹm},
 				'taml' => q{Nọ́mál Támíl Nọ́mba-dẹm},
 				'tamldec' => q{Támíl Nọ́mba-dẹm},
 				'telu' => q{Tẹ́lúgu Nọ́mba-dẹm},
 				'thai' => q{Taí Nọ́mba-dẹm},
 				'tibt' => q{Tíbẹt Nọ́mba-dẹm},
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
			'metric' => q{Mẹ́trik},
 			'UK' => q{Brítish},
 			'US' => q{US},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Lángwej: {0}',
 			'script' => 'Haú to raít tins: {0}',
 			'region' => 'Éria: {0}',

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
			auxiliary => qr{[à c è {ẹ̀} ì ò {ọ̀} q ù x]},
			index => ['A', 'B', '{CH}', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'],
			main => qr{[a á b {ch} d e é ẹ {ẹ́} f g {gb} h i í j k {kp} l m n o ó ọ {ọ́} p r s {sh} t u ú v w y z {zh}]},
			numbers => qr{[\- ‑ , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ ‑ – — , ; \: ! ? . … ' ‘ ’ " “ ” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', '{CH}', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z'], };
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
			'word-final' => '{0} …',
			'word-initial' => '… {0}',
			'word-medial' => '{0} … {1}',
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
	default		=> qq{‘},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{’},
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
						'name' => q(Kádínál Pọint),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(Kádínál Pọint),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(Pébi{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(Pébi{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(Ẹ́ksbi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(Ẹ́ksbi{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(Zébi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(Zébi{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(Yóbẹ{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(Yóbẹ{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(Dẹsí{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(Dẹsí{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(Pikó{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(Pikó{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(Fẹ́mto{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(Fẹ́mto{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(Áto{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(Áto{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(Sẹ́ntí{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(Sẹ́ntí{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(Zẹ́pto{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(Zẹ́pto{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(Yókto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(Yókto{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(Mílí{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(Mílí{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(Maíkro{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(Maíkro{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(Náno{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(Náno{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(Dẹ́ka{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(Dẹ́ka{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(Tẹ́rá{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(Tẹ́rá{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(Pẹ́tá{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(Pẹ́tá{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q({0}Ẹ́ksa),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q({0}Ẹ́ksa),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(Hẹ́kto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(Hẹ́kto{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(Zẹ́ta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(Zẹ́ta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(Yóta{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(Yóta{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(Kíló{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(Kíló{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(Mẹ́gá{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(Mẹ́gá{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(Gíga{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(Gíga{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(Grávíti Fọs),
						'one' => q({0} g-Fọs),
						'other' => q({0} g-Fọs),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(Grávíti Fọs),
						'one' => q({0} g-Fọs),
						'other' => q({0} g-Fọs),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(Míta Fọ Ẹ́vrí Skwiá Sẹ́kọn),
						'one' => q({0} Míta Fọ Ẹ́vrí Skwiá Sẹ́kọn),
						'other' => q({0} Míta Fọ Ẹ́vrí Skwiá Sẹ́kọn),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(Míta Fọ Ẹ́vrí Skwiá Sẹ́kọn),
						'one' => q({0} Míta Fọ Ẹ́vrí Skwiá Sẹ́kọn),
						'other' => q({0} Míta Fọ Ẹ́vrí Skwiá Sẹ́kọn),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(Ákmínit-dẹm),
						'one' => q({0} Ákmínit),
						'other' => q({0} Ákmínit),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(Ákmínit-dẹm),
						'one' => q({0} Ákmínit),
						'other' => q({0} Ákmínit),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(Áksẹ́kọn-dẹm),
						'one' => q({0} Áksẹ́kọn),
						'other' => q({0} Áksẹ́kọn),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(Áksẹ́kọn-dẹm),
						'one' => q({0} Áksẹ́kọn),
						'other' => q({0} Áksẹ́kọn),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(Digrii-dẹm),
						'one' => q({0} Digrii),
						'other' => q({0} Digrii),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(Digrii-dẹm),
						'one' => q({0} Digrii),
						'other' => q({0} Digrii),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(Rédian-dẹm fọ Ángúl Mẹ́zhọ́mẹnt),
						'one' => q({0} Rédian),
						'other' => q({0} Rédian),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(Rédian-dẹm fọ Ángúl Mẹ́zhọ́mẹnt),
						'one' => q({0} Rédian),
						'other' => q({0} Rédian),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(Rẹvolúshọn),
						'one' => q({0} Rẹvolúshọn),
						'other' => q({0} Rẹvolúshọn),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(Rẹvolúshọn),
						'one' => q({0} Rẹvolúshọn),
						'other' => q({0} Rẹvolúshọn),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(Éka-dẹm),
						'one' => q({0} Éka),
						'other' => q({0} Éka),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(Éka-dẹm),
						'one' => q({0} Éka),
						'other' => q({0} Éka),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(Dúnam-dẹm),
						'one' => q({0} Dúnam),
						'other' => q({0} Dúnam),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(Dúnam-dẹm),
						'one' => q({0} Dúnam),
						'other' => q({0} Dúnam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(Hẹ́kta-dẹm),
						'one' => q({0} Hẹ́kta),
						'other' => q({0} Hẹ́kta),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(Hẹ́kta-dẹm),
						'one' => q({0} Hẹ́kta),
						'other' => q({0} Hẹ́kta),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(Skwiá Sẹntímíta-dẹm),
						'one' => q({0} Skwiá Sẹntímíta),
						'other' => q({0} Skwiá Sẹntímíta),
						'per' => q({0} Fọ Ích Skwiá Sẹntímíta),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(Skwiá Sẹntímíta-dẹm),
						'one' => q({0} Skwiá Sẹntímíta),
						'other' => q({0} Skwiá Sẹntímíta),
						'per' => q({0} Fọ Ích Skwiá Sẹntímíta),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(Skwiá Fut-dẹm),
						'one' => q({0} Skwiá Fut),
						'other' => q({0} Skwiá Fut),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(Skwiá Fut-dẹm),
						'one' => q({0} Skwiá Fut),
						'other' => q({0} Skwiá Fut),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(Skwiá Inch-dẹm),
						'one' => q({0} Skwiá Inch),
						'other' => q({0} Skwiá Inch),
						'per' => q({0} Fọ Ích Skwiá Inch),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(Skwiá Inch-dẹm),
						'one' => q({0} Skwiá Inch),
						'other' => q({0} Skwiá Inch),
						'per' => q({0} Fọ Ích Skwiá Inch),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(Skwiá Kilómíta-dẹm),
						'one' => q({0} Skwiá Kilómíta),
						'other' => q({0} Skwiá Kilómíta),
						'per' => q({0} Fọ Ích Skwiá Kilómíta),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(Skwiá Kilómíta-dẹm),
						'one' => q({0} Skwiá Kilómíta),
						'other' => q({0} Skwiá Kilómíta),
						'per' => q({0} Fọ Ích Skwiá Kilómíta),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(Skwiá Míta-dẹm),
						'one' => q({0} Skwiá Míta),
						'other' => q({0} Skwiá Míta),
						'per' => q({0} Fọ Ích Skwiá Míta),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(Skwiá Míta-dẹm),
						'one' => q({0} Skwiá Míta),
						'other' => q({0} Skwiá Míta),
						'per' => q({0} Fọ Ích Skwiá Míta),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(Skwiá Mail-dẹm),
						'one' => q({0} Skwiá Mail),
						'other' => q({0} Skwiá Mail),
						'per' => q({0} Fọ Ích Skwiá Mail),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(Skwiá Mail-dẹm),
						'one' => q({0} Skwiá Mail),
						'other' => q({0} Skwiá Mail),
						'per' => q({0} Fọ Ích Skwiá Mail),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(Skwiá Yad-dẹm),
						'one' => q({0} Skwiá Yad),
						'other' => q({0} Skwiá Yad),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(Skwiá Yad-dẹm),
						'one' => q({0} Skwiá Yad),
						'other' => q({0} Skwiá Yad),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(Karat-dẹm),
						'one' => q({0} Karat),
						'other' => q({0} Karat),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(Karat-dẹm),
						'one' => q({0} Karat),
						'other' => q({0} Karat),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(Mílígram-dẹm Fọ Ẹ́vrí Dẹsílíta),
						'one' => q({0} Mílígram Fọ Ẹ́vrí Dẹsílíta),
						'other' => q({0} Mílígram Fọ Ẹ́vrí Dẹsílíta),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(Mílígram-dẹm Fọ Ẹ́vrí Dẹsílíta),
						'one' => q({0} Mílígram Fọ Ẹ́vrí Dẹsílíta),
						'other' => q({0} Mílígram Fọ Ẹ́vrí Dẹsílíta),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(Mílimol-dẹm Fọ Ẹ́vrí Líta),
						'one' => q({0} Mílimol Fọ Ẹ́vrí Líta),
						'other' => q({0} Mílimol Fọ Ẹ́vrí Líta),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(Mílimol-dẹm Fọ Ẹ́vrí Líta),
						'one' => q({0} Mílimol Fọ Ẹ́vrí Líta),
						'other' => q({0} Mílimol Fọ Ẹ́vrí Líta),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(Mol-dẹm),
						'one' => q({0} Mol),
						'other' => q({0} Mol),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(Mol-dẹm),
						'one' => q({0} Mol),
						'other' => q({0} Mol),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(Pasẹnt),
						'one' => q({0} Pasẹnt),
						'other' => q({0} Pasẹnt),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(Pasẹnt),
						'one' => q({0} Pasẹnt),
						'other' => q({0} Pasẹnt),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(Fọ Ích Taúzan),
						'one' => q({0} Fọ Ích Taúzan),
						'other' => q({0} Fọ Ích Taúzan),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(Fọ Ích Taúzan),
						'one' => q({0} Fọ Ích Taúzan),
						'other' => q({0} Fọ Ích Taúzan),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(Pat-dẹm Fọ Ích Míliọn),
						'one' => q({0} Pat Fọ Ích Míliọn),
						'other' => q({0} Pat Fọ Ích Míliọn),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(Pat-dẹm Fọ Ích Míliọn),
						'one' => q({0} Pat Fọ Ích Míliọn),
						'other' => q({0} Pat Fọ Ích Míliọn),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(Fọ Ích Tẹ́n Taúzan),
						'one' => q({0} Fọ Ích Tẹ́n Taúzan),
						'other' => q({0} Fọ Ích Tẹ́n Taúzan),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(Fọ Ích Tẹ́n Taúzan),
						'one' => q({0} Fọ Ích Tẹ́n Taúzan),
						'other' => q({0} Fọ Ích Tẹ́n Taúzan),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(Líta-dẹm Fọ Ẹ́vrí 100 Kilómíta),
						'one' => q({0} Líta Fọ Ẹ́vrí 100 Kilómíta),
						'other' => q({0} Líta Fọ Ẹ́vrí 100 Kilómíta),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(Líta-dẹm Fọ Ẹ́vrí 100 Kilómíta),
						'one' => q({0} Líta Fọ Ẹ́vrí 100 Kilómíta),
						'other' => q({0} Líta Fọ Ẹ́vrí 100 Kilómíta),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(Líta-dẹm Fọ Ẹ́vrí Kilómíta),
						'one' => q({0} Líta Fọ Ẹ́vrí Kilómíta),
						'other' => q({0} Líta Fọ Ẹ́vrí Kilómíta),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(Líta-dẹm Fọ Ẹ́vrí Kilómíta),
						'one' => q({0} Líta Fọ Ẹ́vrí Kilómíta),
						'other' => q({0} Líta Fọ Ẹ́vrí Kilómíta),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(Mail-dẹm Fọ Ẹ́vrí Gálọn),
						'one' => q({0} Mail Fọ Ẹ́vrí Gálọn),
						'other' => q({0} Mail Fọ Ẹ́vrí Gálọn),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(Mail-dẹm Fọ Ẹ́vrí Gálọn),
						'one' => q({0} Mail Fọ Ẹ́vrí Gálọn),
						'other' => q({0} Mail Fọ Ẹ́vrí Gálọn),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(Mail-dẹm Fọ Ẹ́vrí Brítísh Gálọn),
						'one' => q({0} Mail Fọ Ẹ́vrí Brítísh Gálọn),
						'other' => q({0} Mail Fọ Ẹ́vrí Brítísh Gálọn),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(Mail-dẹm Fọ Ẹ́vrí Brítísh Gálọn),
						'one' => q({0} Mail Fọ Ẹ́vrí Brítísh Gálọn),
						'other' => q({0} Mail Fọ Ẹ́vrí Brítísh Gálọn),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} Ist),
						'north' => q({0} Nọt),
						'south' => q({0} Sáut),
						'west' => q({0} Wẹst),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} Ist),
						'north' => q({0} Nọt),
						'south' => q({0} Sáut),
						'west' => q({0} Wẹst),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(Bit-dem),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(Bit-dem),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(Bait-dẹm),
						'one' => q({0} Bait),
						'other' => q({0} Bait),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(Bait-dẹm),
						'one' => q({0} Bait),
						'other' => q({0} Bait),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gígábit-dẹm),
						'one' => q({0} Gígábit),
						'other' => q({0} Gígábit),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gígábit-dẹm),
						'one' => q({0} Gígábit),
						'other' => q({0} Gígábit),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(Gígábait-dẹm),
						'one' => q({0} Gígábait),
						'other' => q({0} Gígábait),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(Gígábait-dẹm),
						'one' => q({0} Gígábait),
						'other' => q({0} Gígábait),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(Kílóbit-dẹm),
						'one' => q({0} Kílóbit),
						'other' => q({0} Kílóbit),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(Kílóbit-dẹm),
						'one' => q({0} Kílóbit),
						'other' => q({0} Kílóbit),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(Kílóbait-dẹm),
						'one' => q({0} Kílóbait),
						'other' => q({0} Kílóbait),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(Kílóbait-dẹm),
						'one' => q({0} Kílóbait),
						'other' => q({0} Kílóbait),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mẹ́gábit-dẹm),
						'one' => q({0} Mẹ́gábit),
						'other' => q({0} Mẹ́gábit),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mẹ́gábit-dẹm),
						'one' => q({0} Mẹ́gábit),
						'other' => q({0} Mẹ́gábit),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(Mẹ́gábait-dẹm),
						'one' => q({0} Mẹ́gábait),
						'other' => q({0} Mẹ́gábait),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(Mẹ́gábait-dẹm),
						'one' => q({0} Mẹ́gábait),
						'other' => q({0} Mẹ́gábait),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(Pẹ́tábait-dẹm),
						'one' => q({0} Pẹ́tábait),
						'other' => q({0} Pẹ́tábait),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(Pẹ́tábait-dẹm),
						'one' => q({0} Pẹ́tábait),
						'other' => q({0} Pẹ́tábait),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tẹ́rábit-dẹm),
						'one' => q({0} Tẹ́rábit),
						'other' => q({0} Tẹ́rábit),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tẹ́rábit-dẹm),
						'one' => q({0} Tẹ́rábit),
						'other' => q({0} Tẹ́rábit),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(Tẹ́rábait-dẹm),
						'one' => q({0} Tẹ́rábait),
						'other' => q({0} Tẹ́rábait),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(Tẹ́rábait-dẹm),
						'one' => q({0} Tẹ́rábait),
						'other' => q({0} Tẹ́rábait),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(Họ́ndrẹ́d-họ́ndrẹ́d-yiẹ́),
						'one' => q({0} Họ́ndrẹ́d-yiẹ́),
						'other' => q({0} Họ́ndrẹ́d-yiẹ́),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(Họ́ndrẹ́d-họ́ndrẹ́d-yiẹ́),
						'one' => q({0} Họ́ndrẹ́d-yiẹ́),
						'other' => q({0} Họ́ndrẹ́d-yiẹ́),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(Dè-dẹm),
						'one' => q({0} Dè),
						'other' => q({0} Dè),
						'per' => q({0} Ích Dè),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(Dè-dẹm),
						'one' => q({0} Dè),
						'other' => q({0} Dè),
						'per' => q({0} Ích Dè),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(Tẹ́n-tẹ́n-yiẹ),
						'one' => q({0} Tẹ́n-yiẹ),
						'other' => q({0} Tẹ́n-yiẹ́),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(Tẹ́n-tẹ́n-yiẹ),
						'one' => q({0} Tẹ́n-yiẹ),
						'other' => q({0} Tẹ́n-yiẹ́),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(Áwa-dẹm),
						'one' => q({0} Áwa),
						'other' => q({0} Áwa),
						'per' => q({0} Ích Áwa),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(Áwa-dẹm),
						'one' => q({0} Áwa),
						'other' => q({0} Áwa),
						'per' => q({0} Ích Áwa),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(Maíkrosẹ́kọn-dẹm),
						'one' => q({0} Maíkrosẹ́kọn),
						'other' => q({0} Maíkrosẹ́kọn),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(Maíkrosẹ́kọn-dẹm),
						'one' => q({0} Maíkrosẹ́kọn),
						'other' => q({0} Maíkrosẹ́kọn),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(Mílisẹ́kọn-dẹm),
						'one' => q({0} Mílisẹ́kọn),
						'other' => q({0} Mílisẹ́kọn),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(Mílisẹ́kọn-dẹm),
						'one' => q({0} Mílisẹ́kọn),
						'other' => q({0} Mílisẹ́kọn),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(Mínit-dẹm),
						'one' => q({0} Mínit),
						'other' => q({0} Mínit),
						'per' => q({0} Ích Mínit),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(Mínit-dẹm),
						'one' => q({0} Mínit),
						'other' => q({0} Mínit),
						'per' => q({0} Ích Mínit),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(Mọnt-dẹm),
						'one' => q({0} Mọnt),
						'other' => q({0} Mọnt),
						'per' => q({0} Ích mọnt),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(Mọnt-dẹm),
						'one' => q({0} Mọnt),
						'other' => q({0} Mọnt),
						'per' => q({0} Ích mọnt),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(Nánosẹ́kọn-dẹm),
						'one' => q({0} Nánosẹ́kọn),
						'other' => q({0} Nánosẹ́kọn),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(Nánosẹ́kọn-dẹm),
						'one' => q({0} Nánosẹ́kọn),
						'other' => q({0} Nánosẹ́kọn),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(Sẹ́kọn-dẹm),
						'one' => q({0} Sẹ́kọn),
						'other' => q({0} Sẹ́kọn),
						'per' => q({0} Ích Sẹ́kọn),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(Sẹ́kọn-dẹm),
						'one' => q({0} Sẹ́kọn),
						'other' => q({0} Sẹ́kọn),
						'per' => q({0} Ích Sẹ́kọn),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(Wik-dẹm),
						'one' => q({0} Wik),
						'other' => q({0} Wik),
						'per' => q({0} Ích Wik),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(Wik-dẹm),
						'one' => q({0} Wik),
						'other' => q({0} Wik),
						'per' => q({0} Ích Wik),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(Yiẹ-dẹm),
						'one' => q({0} Yiẹ),
						'other' => q({0} Yiẹ),
						'per' => q({0} Ích yiẹ),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(Yiẹ-dẹm),
						'one' => q({0} Yiẹ),
						'other' => q({0} Yiẹ),
						'per' => q({0} Ích yiẹ),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(Ámpẹ́a-dẹm),
						'one' => q({0} ámpẹ́a),
						'other' => q({0} ámpẹ́a),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(Ámpẹ́a-dẹm),
						'one' => q({0} ámpẹ́a),
						'other' => q({0} ámpẹ́a),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(Míliámpẹ́a-dẹm),
						'one' => q({0} Míliámpẹ́a),
						'other' => q({0} Míliámpẹ́a),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(Míliámpẹ́a-dẹm),
						'one' => q({0} Míliámpẹ́a),
						'other' => q({0} Míliámpẹ́a),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(Om-dẹm),
						'one' => q({0} Om),
						'other' => q({0} Om),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(Om-dẹm),
						'one' => q({0} Om),
						'other' => q({0} Om),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(Volt-dẹm),
						'one' => q({0} Volt),
						'other' => q({0} Volt),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(Volt-dẹm),
						'one' => q({0} Volt),
						'other' => q({0} Volt),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(Brítísh Támál Yúnit-dẹm),
						'one' => q({0} Brítísh Támál Yúnit),
						'other' => q({0} Brítísh Támál Yúnit),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(Brítísh Támál Yúnit-dẹm),
						'one' => q({0} Brítísh Támál Yúnit),
						'other' => q({0} Brítísh Támál Yúnit),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(Kálọ́ri-dẹm),
						'one' => q({0} Kálọ́ri),
						'other' => q({0} Kálọ́ri),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(Kálọ́ri-dẹm),
						'one' => q({0} Kálọ́ri),
						'other' => q({0} Kálọ́ri),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(Ẹlẹ́ktrọ́nvolt-dẹm),
						'one' => q({0} Ẹlẹ́ktrọ́nvolt),
						'other' => q({0} Ẹlẹ́ktrọ́nvolt),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(Ẹlẹ́ktrọ́nvolt-dẹm),
						'one' => q({0} Ẹlẹ́ktrọ́nvolt),
						'other' => q({0} Ẹlẹ́ktrọ́nvolt),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Kálọ́ri-dẹm),
						'one' => q({0} Kálọ́ri),
						'other' => q({0} Kálọ́ri),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Kálọ́ri-dẹm),
						'one' => q({0} Kálọ́ri),
						'other' => q({0} Kálọ́ri),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(Jul-dẹm),
						'one' => q({0} Jul),
						'other' => q({0} Jul),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(Jul-dẹm),
						'one' => q({0} Jul),
						'other' => q({0} Jul),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(Kílokálọ́ri-dẹm),
						'one' => q({0} Kílokálọ́ri),
						'other' => q({0} Kílokálọ́ri),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(Kílokálọ́ri-dẹm),
						'one' => q({0} Kílokálọ́ri),
						'other' => q({0} Kílokálọ́ri),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(Kílojul-dẹm),
						'one' => q({0} Kílojul),
						'other' => q({0} Kílojul),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(Kílojul-dẹm),
						'one' => q({0} Kílojul),
						'other' => q({0} Kílojul),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(Kílowát-Áwa-dẹm),
						'one' => q({0} Kílowát-Áwa),
						'other' => q({0} Kílowát-Áwa),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(Kílowát-Áwa-dẹm),
						'one' => q({0} Kílowát-Áwa),
						'other' => q({0} Kílowát-Áwa),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(US Támál Yúnit-dẹm),
						'one' => q({0} US Támál Yúnit),
						'other' => q({0} US Támál Yúnit),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(US Támál Yúnit-dẹm),
						'one' => q({0} US Támál Yúnit),
						'other' => q({0} US Támál Yúnit),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(Kílowát-áwa Fọ Ẹ́vrí 100 Kilómíta),
						'one' => q({0} Kílowát-áwa Fọ Ẹ́vrí 100 Kilómíta),
						'other' => q({0} Kílowát-áwa Fọ Ẹ́vrí 100 Kilómíta),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(Kílowát-áwa Fọ Ẹ́vrí 100 Kilómíta),
						'one' => q({0} Kílowát-áwa Fọ Ẹ́vrí 100 Kilómíta),
						'other' => q({0} Kílowát-áwa Fọ Ẹ́vrí 100 Kilómíta),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(Niútons),
						'one' => q({0} Niúton),
						'other' => q({0} Niúton),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(Niútons),
						'one' => q({0} Niúton),
						'other' => q({0} Niúton),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(Páund-dẹm ọf Fọs),
						'one' => q({0} Paúnd ọf Fọs),
						'other' => q({0} Paúnd ọf Fọs),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(Páund-dẹm ọf Fọs),
						'one' => q({0} Paúnd ọf Fọs),
						'other' => q({0} Paúnd ọf Fọs),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(Gígahẹtz-dẹm),
						'one' => q({0} Gígahẹtz),
						'other' => q({0} Gígahẹtz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(Gígahẹtz-dẹm),
						'one' => q({0} Gígahẹtz),
						'other' => q({0} Gígahẹtz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(Hẹtz-dẹm),
						'one' => q({0} Hẹtz),
						'other' => q({0} Hẹtz),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(Hẹtz-dẹm),
						'one' => q({0} Hẹtz),
						'other' => q({0} Hẹtz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(Kílohẹtz-dẹm),
						'one' => q({0} Kílohẹtz),
						'other' => q({0} Kílohẹtz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(Kílohẹtz-dẹm),
						'one' => q({0} Kílohẹtz),
						'other' => q({0} Kílohẹtz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(Mẹ́gahẹtz-dẹm),
						'one' => q({0} Mẹ́gahẹtz),
						'other' => q({0} Mẹ́gahẹtz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(Mẹ́gahẹtz-dẹm),
						'one' => q({0} Mẹ́gahẹtz),
						'other' => q({0} Mẹ́gahẹtz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(dọt),
						'one' => q({0}dọt),
						'other' => q({0}dọt),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(dọt),
						'one' => q({0}dọt),
						'other' => q({0}dọt),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(Pọint-dẹm fọ ích sẹntímíta),
						'one' => q({0} Pọint fọ ích sẹntímíta),
						'other' => q({0} Pọint fọ ích sẹntímíta),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(Pọint-dẹm fọ ích sẹntímíta),
						'one' => q({0} Pọint fọ ích sẹntímíta),
						'other' => q({0} Pọint fọ ích sẹntímíta),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(Pọint-Dẹm Fọ Ẹ́vrí Inch),
						'one' => q({0} Pọint Fọ Ẹ́vrí Inch),
						'other' => q({0} Pọint Fọ Ẹ́vrí Inch),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(Pọint-Dẹm Fọ Ẹ́vrí Inch),
						'one' => q({0} Pọint Fọ Ẹ́vrí Inch),
						'other' => q({0} Pọint Fọ Ẹ́vrí Inch),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(Taipógráfik em),
						'one' => q({0} em),
						'other' => q({0} ems),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(Taipógráfik em),
						'one' => q({0} em),
						'other' => q({0} ems),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(Mẹ́gapíksẹl-dẹm),
						'one' => q({0} Mẹ́gapíksẹl),
						'other' => q({0} Mẹ́gapíksẹl),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(Mẹ́gapíksẹl-dẹm),
						'one' => q({0} Mẹ́gapíksẹl),
						'other' => q({0} Mẹ́gapíksẹl),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(Píksẹl-dẹm),
						'one' => q({0} Píksẹl),
						'other' => q({0} Píksẹl),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(Píksẹl-dẹm),
						'one' => q({0} Píksẹl),
						'other' => q({0} Píksẹl),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(Píksẹl-dẹm Fọ Ích Sẹntímíta),
						'one' => q({0} Píksẹl Fọ Ích Sẹntímíta),
						'other' => q({0} Píksẹl Fọ Ích Sẹntímíta),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(Píksẹl-dẹm Fọ Ích Sẹntímíta),
						'one' => q({0} Píksẹl Fọ Ích Sẹntímíta),
						'other' => q({0} Píksẹl Fọ Ích Sẹntímíta),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(Píksẹl-dẹm Fọ Ẹ́vrí Inch),
						'one' => q({0} Píksẹl Fọ Ẹ́vrí Inch),
						'other' => q({0} Píksẹl Fọ Ẹ́vrí Inch),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(Píksẹl-dẹm Fọ Ẹ́vrí Inch),
						'one' => q({0} Píksẹl Fọ Ẹ́vrí Inch),
						'other' => q({0} Píksẹl Fọ Ẹ́vrí Inch),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(Astrọnọ́míkál Yúnit-dem),
						'one' => q({0} Astrọnọ́míkál Yúnit),
						'other' => q({0} Astrọnọ́míkál Yúnit),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(Astrọnọ́míkál Yúnit-dem),
						'one' => q({0} Astrọnọ́míkál Yúnit),
						'other' => q({0} Astrọnọ́míkál Yúnit),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(Sẹ́ntímíta-dẹm),
						'one' => q({0} Sẹ́ntímíta),
						'other' => q({0} Sẹ́ntímíta),
						'per' => q({0} Fọ Ích Sẹ́ntímíta),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(Sẹ́ntímíta-dẹm),
						'one' => q({0} Sẹ́ntímíta),
						'other' => q({0} Sẹ́ntímíta),
						'per' => q({0} Fọ Ích Sẹ́ntímíta),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(Dẹsímíta-dẹm),
						'one' => q({0} Dẹsímíta),
						'other' => q({0} Dẹsímíta),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(Dẹsímíta-dẹm),
						'one' => q({0} Dẹsímíta),
						'other' => q({0} Dẹsímíta),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(Wọ́ld Rédiọs),
						'one' => q({0} Wọ́ld Rédiọs),
						'other' => q({0} Wọ́ld Rédiọs),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(Wọ́ld Rédiọs),
						'one' => q({0} Wọ́ld Rédiọs),
						'other' => q({0} Wọ́ld Rédiọs),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(Fátọm),
						'one' => q({0} fátọm),
						'other' => q({0} fátọm),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(Fátọm),
						'one' => q({0} fátọm),
						'other' => q({0} fátọm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(Fut-dẹm),
						'one' => q({0} Fut),
						'other' => q({0} Fut),
						'per' => q({0} Fọ Ích Fut),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(Fut-dẹm),
						'one' => q({0} Fut),
						'other' => q({0} Fut),
						'per' => q({0} Fọ Ích Fut),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(Fọ́lọng),
						'one' => q({0} fọ́lọng),
						'other' => q({0} fọ́lọng),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(Fọ́lọng),
						'one' => q({0} fọ́lọng),
						'other' => q({0} fọ́lọng),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(Inch-dẹm),
						'one' => q({0} inch),
						'other' => q({0} inch),
						'per' => q({0} Fọ Ẹ́vrí Inch),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(Inch-dẹm),
						'one' => q({0} inch),
						'other' => q({0} inch),
						'per' => q({0} Fọ Ẹ́vrí Inch),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(Kílómíta-dẹm),
						'one' => q({0} Kílómíta),
						'other' => q({0} Kílómíta),
						'per' => q({0} Fọ Ích Kilómíta),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(Kílómíta-dẹm),
						'one' => q({0} Kílómíta),
						'other' => q({0} Kílómíta),
						'per' => q({0} Fọ Ích Kilómíta),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(Laít Yiẹ-dẹm),
						'one' => q({0} Laít Yiẹ),
						'other' => q({0} Laít Yiẹ),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(Laít Yiẹ-dẹm),
						'one' => q({0} Laít Yiẹ),
						'other' => q({0} Laít Yiẹ),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(Míta-dẹm),
						'one' => q({0} Míta),
						'other' => q({0} Míta),
						'per' => q({0} Fọ Ích Míta),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(Míta-dẹm),
						'one' => q({0} Míta),
						'other' => q({0} Míta),
						'per' => q({0} Fọ Ích Míta),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(Maíkrómíta-dẹm),
						'one' => q({0} Maíkrómíta),
						'other' => q({0} Maíkrómíta),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(Maíkrómíta-dẹm),
						'one' => q({0} Maíkrómíta),
						'other' => q({0} Maíkrómíta),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(Mail-dẹm),
						'one' => q({0} Mail),
						'other' => q({0} Mail),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(Mail-dẹm),
						'one' => q({0} Mail),
						'other' => q({0} Mail),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(Mail-Skandínévia),
						'one' => q({0} Mail-Skandínévia),
						'other' => q({0} Mail-Skandínévia),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(Mail-Skandínévia),
						'one' => q({0} Mail-Skandínévia),
						'other' => q({0} Mail-Skandínévia),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(Milímíta-dẹm),
						'one' => q({0} Milímíta),
						'other' => q({0} Milímíta),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(Milímíta-dẹm),
						'one' => q({0} Milímíta),
						'other' => q({0} Milímíta),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(Nanómíta-dẹm),
						'one' => q({0} Nanómíta),
						'other' => q({0} Nanómíta),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(Nanómíta-dẹm),
						'one' => q({0} Nanómíta),
						'other' => q({0} Nanómíta),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(Nọ́tíkál Mail-dẹm),
						'one' => q({0} Nọ́tíkál Mail),
						'other' => q({0} Nọ́tíkál Mail),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(Nọ́tíkál Mail-dẹm),
						'one' => q({0} Nọ́tíkál Mail),
						'other' => q({0} Nọ́tíkál Mail),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(Ích Sẹ́k),
						'one' => q({0} Ích Sẹ́k),
						'other' => q({0} Ích Sẹ́k),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(Ích Sẹ́k),
						'one' => q({0} Ích Sẹ́k),
						'other' => q({0} Ích Sẹ́k),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(Pikómíta-dẹm),
						'one' => q({0} Pikómíta),
						'other' => q({0} Pikómíta),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(Pikómíta-dẹm),
						'one' => q({0} Pikómíta),
						'other' => q({0} Pikómíta),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(Point-dẹm),
						'one' => q({0} point),
						'other' => q({0} point),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(Point-dẹm),
						'one' => q({0} point),
						'other' => q({0} point),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(Sólá Rédiọs-dẹm),
						'one' => q({0} Sólá Rédiọs),
						'other' => q({0} Sólá Rédiọs),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(Sólá Rédiọs-dẹm),
						'one' => q({0} Sólá Rédiọs),
						'other' => q({0} Sólá Rédiọs),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(Yad-dẹm),
						'one' => q({0} Yad),
						'other' => q({0} Yad),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(Yad-dẹm),
						'one' => q({0} Yad),
						'other' => q({0} Yad),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(Kandíla),
						'one' => q({0} Kandíla),
						'other' => q({0} Kandíla),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(Kandíla),
						'one' => q({0} Kandíla),
						'other' => q({0} Kandíla),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(Lúmẹn),
						'one' => q({0} Lúmẹn),
						'other' => q({0} Lúmẹn),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(Lúmẹn),
						'one' => q({0} Lúmẹn),
						'other' => q({0} Lúmẹn),
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
						'name' => q(Sólá Luminósíti-dẹm),
						'one' => q({0} Sólá Luminósíti),
						'other' => q({0} Sólá Luminósíti),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(Sólá Luminósíti-dẹm),
						'one' => q({0} Sólá Luminósíti),
						'other' => q({0} Sólá Luminósíti),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(Kárat-dẹm),
						'one' => q({0} Kárat),
						'other' => q({0} Kárat),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(Kárat-dẹm),
						'one' => q({0} Kárat),
						'other' => q({0} Kárat),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(Dọ́lton-dẹm),
						'one' => q({0} Dọ́lton),
						'other' => q({0} Dọ́lton),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(Dọ́lton-dẹm),
						'one' => q({0} Dọ́lton),
						'other' => q({0} Dọ́lton),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(Ẹ́t Mas-dẹm),
						'one' => q({0} Ẹ́t Mas),
						'other' => q({0} Ẹ́t Mas),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(Ẹ́t Mas-dẹm),
						'one' => q({0} Ẹ́t Mas),
						'other' => q({0} Ẹ́t Mas),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(Gren),
						'one' => q({0} gren),
						'other' => q({0} gren),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(Gren),
						'one' => q({0} gren),
						'other' => q({0} gren),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(Gram-dẹm),
						'one' => q({0} Gram),
						'other' => q({0} Gram),
						'per' => q({0} Fọ Ích Gram),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(Gram-dẹm),
						'one' => q({0} Gram),
						'other' => q({0} Gram),
						'per' => q({0} Fọ Ích Gram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(Kílógram-dẹm),
						'one' => q({0} Kílógram),
						'other' => q({0} Kílógram),
						'per' => q({0} Fọ Ích Kílógram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(Kílógram-dẹm),
						'one' => q({0} Kílógram),
						'other' => q({0} Kílógram),
						'per' => q({0} Fọ Ích Kílógram),
					},
					# Long Unit Identifier
					'mass-metric-ton' => {
						'name' => q(Mẹ́trík Tọn-dẹm),
						'one' => q({0} Mẹ́trík Tọn),
						'other' => q({0} Mẹ́trík Tọn),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'name' => q(Mẹ́trík Tọn-dẹm),
						'one' => q({0} Mẹ́trík Tọn),
						'other' => q({0} Mẹ́trík Tọn),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(Maíkrógram-dẹm),
						'one' => q({0} Maíkrógram),
						'other' => q({0} Maíkrógram),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(Maíkrógram-dẹm),
						'one' => q({0} Maíkrógram),
						'other' => q({0} Maíkrógram),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(Mílígram-dẹm),
						'one' => q({0} Mílígram),
						'other' => q({0} Mílígram),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(Mílígram-dẹm),
						'one' => q({0} Mílígram),
						'other' => q({0} Mílígram),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(Áuns-dẹm),
						'one' => q({0} Áuns),
						'other' => q({0} Áuns),
						'per' => q({0} Fọ Ích Áuns),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(Áuns-dẹm),
						'one' => q({0} Áuns),
						'other' => q({0} Áuns),
						'per' => q({0} Fọ Ích Áuns),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(Trọí Áuns-dẹm),
						'one' => q({0} Trọí Áuns),
						'other' => q({0} Trọí Áuns),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(Trọí Áuns-dẹm),
						'one' => q({0} Trọí Áuns),
						'other' => q({0} Trọí Áuns),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(Paund-dẹm),
						'one' => q({0} Paund),
						'other' => q({0} Paund),
						'per' => q({0} Fọ Ích Paund),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(Paund-dẹm),
						'one' => q({0} Paund),
						'other' => q({0} Paund),
						'per' => q({0} Fọ Ích Paund),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(Sólá Mas-dẹm),
						'one' => q({0} Sólá Mas),
						'other' => q({0} Sólá Mas),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(Sólá Mas-dẹm),
						'one' => q({0} Sólá Mas),
						'other' => q({0} Sólá Mas),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(Ston),
						'one' => q({0} ston),
						'other' => q({0} ston),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(Ston),
						'one' => q({0} ston),
						'other' => q({0} ston),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(Tọn-dẹm),
						'one' => q({0} Tọn),
						'other' => q({0} Tọn),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(Tọn-dẹm),
						'one' => q({0} Tọn),
						'other' => q({0} Tọn),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} Fọ Ẹ́vri {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} Fọ Ẹ́vri {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(Gígáwat-dẹm),
						'one' => q({0} Gígáwat),
						'other' => q({0} Gígáwat),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(Gígáwat-dẹm),
						'one' => q({0} Gígáwat),
						'other' => q({0} Gígáwat),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(Họ́spáwa),
						'one' => q({0} Họ́spáwa),
						'other' => q({0} Họ́spáwa),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(Họ́spáwa),
						'one' => q({0} Họ́spáwa),
						'other' => q({0} Họ́spáwa),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(Kílówat-dẹm),
						'one' => q({0} Kílówat),
						'other' => q({0} Kílówat),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(Kílówat-dẹm),
						'one' => q({0} Kílówat),
						'other' => q({0} Kílówat),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(Mẹ́gáwat-dẹm),
						'one' => q({0} Mẹ́gáwat),
						'other' => q({0} Mẹ́gáwat),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(Mẹ́gáwat-dẹm),
						'one' => q({0} Mẹ́gáwat),
						'other' => q({0} Mẹ́gáwat),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(Míliwat-dẹm),
						'one' => q({0} Míliwat),
						'other' => q({0} Míliwat),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(Míliwat-dẹm),
						'one' => q({0} Míliwat),
						'other' => q({0} Míliwat),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(Wat-dẹm),
						'one' => q({0} Wat),
						'other' => q({0} Wat),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(Wat-dẹm),
						'one' => q({0} Wat),
						'other' => q({0} Wat),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q(Skwia {0}),
						'one' => q(Skwiá {0}),
						'other' => q(Skwiá {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q(Skwia {0}),
						'one' => q(Skwiá {0}),
						'other' => q(Skwiá {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q(Kúbik {0}),
						'one' => q(Kúbík {0}),
						'other' => q(Kúbík {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q(Kúbik {0}),
						'one' => q(Kúbík {0}),
						'other' => q(Kúbík {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(Átmósfẹ-dẹm),
						'one' => q({0} Átmósfẹ),
						'other' => q({0} Átmósfẹ),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(Átmósfẹ-dẹm),
						'one' => q({0} Átmósfẹ),
						'other' => q({0} Átmósfẹ),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(Baa-dẹm),
						'one' => q({0} Baa),
						'other' => q({0} Baa),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(Baa-dẹm),
						'one' => q({0} Baa),
						'other' => q({0} Baa),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(Hẹ́ktopáskal-dẹm),
						'one' => q({0} Hẹ́ktopáskal),
						'other' => q({0} Hẹ́ktopáskal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(Hẹ́ktopáskal-dẹm),
						'one' => q({0} Hẹ́ktopáskal),
						'other' => q({0} Hẹ́ktopáskal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(Ínchís ọf Mẹ́kúri),
						'one' => q({0} Inch ọf Mẹ́kúri),
						'other' => q({0} Inch ọf Mẹ́kúri),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(Ínchís ọf Mẹ́kúri),
						'one' => q({0} Inch ọf Mẹ́kúri),
						'other' => q({0} Inch ọf Mẹ́kúri),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(Kílopáskal-dẹm),
						'one' => q({0} Kílopáskal),
						'other' => q({0} Kílopáskal),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(Kílopáskal-dẹm),
						'one' => q({0} Kílopáskal),
						'other' => q({0} Kílopáskal),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(Mẹ́gapáskal-dẹm),
						'one' => q({0} Mẹ́gapáskal),
						'other' => q({0} Mẹ́gapáskal),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(Mẹ́gapáskal-dẹm),
						'one' => q({0} Mẹ́gapáskal),
						'other' => q({0} Mẹ́gapáskal),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(Mílibaa-dẹm),
						'one' => q({0} Mílibaa),
						'other' => q({0} Mílibaa),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(Mílibaa-dẹm),
						'one' => q({0} Mílibaa),
						'other' => q({0} Mílibaa),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(Milímítá-dẹm-ọf-Mẹ́kúri),
						'one' => q({0} Milímítá Mẹ́kúri),
						'other' => q({0} Milímítá Mẹ́kúri),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(Milímítá-dẹm-ọf-Mẹ́kúri),
						'one' => q({0} Milímítá Mẹ́kúri),
						'other' => q({0} Milímítá Mẹ́kúri),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(Páskal-dẹm),
						'one' => q({0} Páskal),
						'other' => q({0} Páskal),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(Páskal-dẹm),
						'one' => q({0} Páskal),
						'other' => q({0} Páskal),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(Páund-dẹm Fọ Ẹ́vrí Skwiá Inch),
						'one' => q({0} Páund Fọ Ẹ́vrí Skwiá Inch),
						'other' => q({0} Páund Fọ Ẹ́vrí Skwiá Inch),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(Páund-dẹm Fọ Ẹ́vrí Skwiá Inch),
						'one' => q({0} Páund Fọ Ẹ́vrí Skwiá Inch),
						'other' => q({0} Páund Fọ Ẹ́vrí Skwiá Inch),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(Kílómíta-dẹm Fọ Ẹ́vrí Áwa),
						'one' => q({0} Kílómíta Fọ Ẹ́vrí Áwa),
						'other' => q({0} Kílómíta Fọ Ẹ́vrí Áwa),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(Kílómíta-dẹm Fọ Ẹ́vrí Áwa),
						'one' => q({0} Kílómíta Fọ Ẹ́vrí Áwa),
						'other' => q({0} Kílómíta Fọ Ẹ́vrí Áwa),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(Nọt-dẹm),
						'one' => q({0} Nọt),
						'other' => q({0} Nọt),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(Nọt-dẹm),
						'one' => q({0} Nọt),
						'other' => q({0} Nọt),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(Míta-dẹm Fọ Ẹ́vrí Sẹ́kọn),
						'one' => q({0} Míta Fọ Ẹ́vrí Sẹ́kọn),
						'other' => q({0} Míta Fọ Ẹ́vrí Sẹ́kọn),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(Míta-dẹm Fọ Ẹ́vrí Sẹ́kọn),
						'one' => q({0} Míta Fọ Ẹ́vrí Sẹ́kọn),
						'other' => q({0} Míta Fọ Ẹ́vrí Sẹ́kọn),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(Mail-dẹm Fọ Ẹ́vrí Áwa),
						'one' => q({0} Mail Fọ Ẹ́vrí Áwa),
						'other' => q({0} Mail Fọ Ẹ́vrí Áwa),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(Mail-dẹm Fọ Ẹ́vrí Áwa),
						'one' => q({0} Mail Fọ Ẹ́vrí Áwa),
						'other' => q({0} Mail Fọ Ẹ́vrí Áwa),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(Digrís Sẹ́lsiọs),
						'one' => q({0} Digrí Sẹ́lsiọs),
						'other' => q({0} Digrís Sẹ́lsiọs),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(Digrís Sẹ́lsiọs),
						'one' => q({0} Digrí Sẹ́lsiọs),
						'other' => q({0} Digrís Sẹ́lsiọs),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(Digrís Fárẹ́nhait),
						'one' => q({0} Digrí Fárẹ́nhait),
						'other' => q({0} Digrís Fárẹ́nhait),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(Digrís Fárẹ́nhait),
						'one' => q({0} Digrí Fárẹ́nhait),
						'other' => q({0} Digrís Fárẹ́nhait),
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
						'name' => q(Kẹ́lvin-dẹm),
						'one' => q({0} Kẹ́lvin),
						'other' => q({0} Kẹ́lvin),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(Kẹ́lvin-dẹm),
						'one' => q({0} Kẹ́lvin),
						'other' => q({0} Kẹ́lvin),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(Niúton-Míta-dẹm),
						'one' => q({0} Niúton-Míta),
						'other' => q({0} Niúton-Míta),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(Niúton-Míta-dẹm),
						'one' => q({0} Niúton-Míta),
						'other' => q({0} Niúton-Míta),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(Paund-Fit),
						'one' => q({0} Paund-Fọs-Fut),
						'other' => q({0} Paund-Fit),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(Paund-Fit),
						'one' => q({0} Paund-Fọs-Fut),
						'other' => q({0} Paund-Fit),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(Éka-Fut-dẹm),
						'one' => q({0} Éka-Fut),
						'other' => q({0} Éka-Fut),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(Éka-Fut-dẹm),
						'one' => q({0} Éka-Fut),
						'other' => q({0} Éka-Fut),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(Drọm-dẹm),
						'one' => q({0} Drọm),
						'other' => q({0} Drọm),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(Drọm-dẹm),
						'one' => q({0} Drọm),
						'other' => q({0} Drọm),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(Búshẹl),
						'one' => q({0} Búshẹl),
						'other' => q({0} Búshẹl),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(Búshẹl),
						'one' => q({0} Búshẹl),
						'other' => q({0} Búshẹl),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(Sẹntílíta-dẹm),
						'one' => q({0} Sẹntílíta),
						'other' => q({0} Sẹntílíta),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(Sẹntílíta-dẹm),
						'one' => q({0} Sẹntílíta),
						'other' => q({0} Sẹntílíta),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(Kúbík Sẹntímíta-dẹm),
						'one' => q({0} Kúbík Sẹntímíta),
						'other' => q({0} Kúbík Sẹntímíta),
						'per' => q({0} Fọ Ích Kúbík Sẹntímíta),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(Kúbík Sẹntímíta-dẹm),
						'one' => q({0} Kúbík Sẹntímíta),
						'other' => q({0} Kúbík Sẹntímíta),
						'per' => q({0} Fọ Ích Kúbík Sẹntímíta),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(Kúbík Fut-dẹm),
						'one' => q({0} Kúbík Fut),
						'other' => q({0} Kúbík Fut),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(Kúbík Fut-dẹm),
						'one' => q({0} Kúbík Fut),
						'other' => q({0} Kúbík Fut),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(Kúbík Ínchis),
						'one' => q({0} Kúbík Ínch),
						'other' => q({0} Kúbík Ínchis),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(Kúbík Ínchis),
						'one' => q({0} Kúbík Ínch),
						'other' => q({0} Kúbík Ínchis),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(Kúbík Kílómíta-dẹm),
						'one' => q({0} Kúbík Kílómíta),
						'other' => q({0} Kúbík Kílómíta),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(Kúbík Kílómíta-dẹm),
						'one' => q({0} Kúbík Kílómíta),
						'other' => q({0} Kúbík Kílómíta),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(Kúbík Míta-dẹm),
						'one' => q({0} Kúbík Míta),
						'other' => q({0} Kúbík Míta),
						'per' => q({0} Fọ Ích Kúbík Míta),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(Kúbík Míta-dẹm),
						'one' => q({0} Kúbík Míta),
						'other' => q({0} Kúbík Míta),
						'per' => q({0} Fọ Ích Kúbík Míta),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(Kúbík Mail-dẹm),
						'one' => q({0} Kúbík Mail),
						'other' => q({0} Kúbík Mail),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(Kúbík Mail-dẹm),
						'one' => q({0} Kúbík Mail),
						'other' => q({0} Kúbík Mail),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(Kúbík Yad-dẹm),
						'one' => q({0} Kúbík Yad),
						'other' => q({0} Kúbík Yad),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(Kúbík Yad-dẹm),
						'one' => q({0} Kúbík Yad),
						'other' => q({0} Kúbík Yad),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(Kọp-dẹm),
						'one' => q({0} Kọp),
						'other' => q({0} Kọp),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(Kọp-dẹm),
						'one' => q({0} Kọp),
						'other' => q({0} Kọp),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(Mẹ́trík Kọp-dẹm),
						'one' => q({0} Mẹ́trík Kọp),
						'other' => q({0} Mẹ́trík Kọp),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(Mẹ́trík Kọp-dẹm),
						'one' => q({0} Mẹ́trík Kọp),
						'other' => q({0} Mẹ́trík Kọp),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(Dẹsílíta-dẹm),
						'one' => q({0} Dẹsílíta),
						'other' => q({0} Dẹsílíta),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(Dẹsílíta-dẹm),
						'one' => q({0} Dẹsílíta),
						'other' => q({0} Dẹsílíta),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(Dizát Spun),
						'one' => q({0} Dizát Spun),
						'other' => q({0} Dizát Spun),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(Dizát Spun),
						'one' => q({0} Dizát Spun),
						'other' => q({0} Dizát Spun),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Impẹ́riál Dizát Spun),
						'one' => q({0} Impẹ́riál Dizát Spun),
						'other' => q({0} Impẹ́riál Dizát Spun),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Impẹ́riál Dizát Spun),
						'one' => q({0} Impẹ́riál Dizát Spun),
						'other' => q({0} Impẹ́riál Dizát Spun),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(Dram),
						'one' => q({0} Dram),
						'other' => q({0} Dram),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(Dram),
						'one' => q({0} Dram),
						'other' => q({0} Dram),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(Drọp),
						'one' => q({0} Drọp),
						'other' => q({0} Drọp),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(Drọp),
						'one' => q({0} Drọp),
						'other' => q({0} Drọp),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(Líkwíd Áuns-dẹm),
						'one' => q({0} Líkwíd Áuns),
						'other' => q({0} Líkwíd Áuns),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(Líkwíd Áuns-dẹm),
						'one' => q({0} Líkwíd Áuns),
						'other' => q({0} Líkwíd Áuns),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Brítísh Líkwíd Aúnsis-dẹm),
						'one' => q({0} Brítísh Líkwíd Aúns),
						'other' => q({0} Brítísh Líkwíd Aúns),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Brítísh Líkwíd Aúnsis-dẹm),
						'one' => q({0} Brítísh Líkwíd Aúns),
						'other' => q({0} Brítísh Líkwíd Aúns),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(Gálọn-dẹm),
						'one' => q({0} Gálọn),
						'other' => q({0} Gálọn),
						'per' => q({0} Fọ Ích Gálọn),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(Gálọn-dẹm),
						'one' => q({0} Gálọn),
						'other' => q({0} Gálọn),
						'per' => q({0} Fọ Ích Gálọn),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(Brítísh Galọn-dẹm),
						'one' => q({0} Brítísh Galọn),
						'other' => q({0} Brítísh Galọn),
						'per' => q({0} Fọ Ích Brítísh Galọn),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(Brítísh Galọn-dẹm),
						'one' => q({0} Brítísh Galọn),
						'other' => q({0} Brítísh Galọn),
						'per' => q({0} Fọ Ích Brítísh Galọn),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(Hẹ́któlíta-dẹm),
						'one' => q({0} Hẹ́któlíta),
						'other' => q({0} Hẹ́któlíta),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(Hẹ́któlíta-dẹm),
						'one' => q({0} Hẹ́któlíta),
						'other' => q({0} Hẹ́któlíta),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(Jigá),
						'one' => q({0} Jigá),
						'other' => q({0} Jigá),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(Jigá),
						'one' => q({0} Jigá),
						'other' => q({0} Jigá),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(Líta-dẹm),
						'one' => q({0}Líta),
						'other' => q({0}Líta),
						'per' => q({0} Fọ Ích Líta),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(Líta-dẹm),
						'one' => q({0}Líta),
						'other' => q({0}Líta),
						'per' => q({0} Fọ Ích Líta),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(Mẹ́galíta-dẹm),
						'one' => q({0} Mẹ́galíta),
						'other' => q({0} Mẹ́galíta),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(Mẹ́galíta-dẹm),
						'one' => q({0} Mẹ́galíta),
						'other' => q({0} Mẹ́galíta),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(Milílíta-dẹm),
						'one' => q({0} Milílíta),
						'other' => q({0} Milílíta),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(Milílíta-dẹm),
						'one' => q({0} Milílíta),
						'other' => q({0} Milílíta),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(Pinch),
						'one' => q({0} Pinch),
						'other' => q({0} Pinch),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(Pinch),
						'one' => q({0} Pinch),
						'other' => q({0} Pinch),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(Paint-dẹm),
						'one' => q({0} Paint),
						'other' => q({0} Paint),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(Paint-dẹm),
						'one' => q({0} Paint),
						'other' => q({0} Paint),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(Mẹ́trík Paint-dẹm),
						'one' => q({0} Mẹ́trík Paint),
						'other' => q({0} Mẹ́trík Paint),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(Mẹ́trík Paint-dẹm),
						'one' => q({0} Mẹ́trík Paint),
						'other' => q({0} Mẹ́trík Paint),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(Kwọt-dẹm),
						'one' => q({0} Kwọt),
						'other' => q({0} Kwọt),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(Kwọt-dẹm),
						'one' => q({0} Kwọt),
						'other' => q({0} Kwọt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(Impẹ́riál Kwọt),
						'one' => q({0} Impẹ́riál Kwọt),
						'other' => q({0} Impẹ́riál Kwọt),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(Impẹ́riál Kwọt),
						'one' => q({0} Impẹ́riál Kwọt),
						'other' => q({0} Impẹ́riál Kwọt),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(Tébulspun-dẹm),
						'one' => q({0} Tébulspun),
						'other' => q({0} Tébulspun),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(Tébulspun-dẹm),
						'one' => q({0} Tébulspun),
						'other' => q({0} Tébulspun),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(Tíspun-dẹm),
						'one' => q({0} Tíspun),
						'other' => q({0} Tíspun),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(Tíspun-dẹm),
						'one' => q({0} Tíspun),
						'other' => q({0} Tíspun),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'' => {
						'name' => q(Pọint),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(Pọint),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(Kí{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(Kí{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(Mím{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(Mím{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(Gím{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(Gím{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(Tím{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(Tím{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(Pím{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(Pím{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(Ẹím{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(Ẹím{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(Zím{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(Zím{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(Yím{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(Yím{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(D{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(D{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(p{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(p{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(Fẹ́{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(Fẹ́{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(Á{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(Á{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(s{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(s{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(Zẹ́{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(Zẹ́{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(Yó{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(Yó{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(m{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(m{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(μ{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(μ{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(n{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(n{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(Dẹ́{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(Dẹ́{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(T{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(T{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(P{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(P{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q({0}Ẹ),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q({0}Ẹ),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(h{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(h{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(Zẹ́{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(Zẹ́{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(Yó{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(Yó{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(k{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(k{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(M{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(M{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(G{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(G{0}),
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
						'name' => q(Dig),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(Dig),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'one' => q({0} kárá),
						'other' => q({0} kárá),
					},
					# Core Unit Identifier
					'karat' => {
						'one' => q({0} kárá),
						'other' => q({0} kárá),
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
					'concentr-permille' => {
						'name' => q(‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(Pfim),
						'one' => q({0} pfim),
						'other' => q({0} pfim),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(Pfim),
						'one' => q({0} pfim),
						'other' => q({0} pfim),
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
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100km),
						'one' => q({0}L/100km),
						'other' => q({0}L/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(L/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(Mfeg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(Mfeg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mfeg Brít),
						'one' => q({0} m/g Brít),
						'other' => q({0} m/g Brít),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mfeg Brít),
						'one' => q({0} m/g Brít),
						'other' => q({0} m/g Brít),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
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
					'duration-century' => {
						'name' => q(H),
						'one' => q({0}h),
						'other' => q({0}h),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(H),
						'one' => q({0}h),
						'other' => q({0}h),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(Dè),
						'one' => q({0}Dè),
						'other' => q({0}Dè),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(Dè),
						'one' => q({0}Dè),
						'other' => q({0}Dè),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(Áwa),
						'one' => q({0}Áwa),
						'other' => q({0}Áwa),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(Áwa),
						'one' => q({0}Áwa),
						'other' => q({0}Áwa),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(Mílisẹ́kọns),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(Mílisẹ́kọns),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(Mínit),
						'one' => q({0}Mínit),
						'other' => q({0}Mínit),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(Mínit),
						'one' => q({0}Mínit),
						'other' => q({0}Mínit),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(Mọnt),
						'one' => q({0}Mọnt),
						'other' => q({0}Mọnt),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(Mọnt),
						'one' => q({0}Mọnt),
						'other' => q({0}Mọnt),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(Sẹ́kọn),
						'one' => q({0}Sẹ́kọn),
						'other' => q({0}Sẹ́kọn),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(Sẹ́kọn),
						'one' => q({0}Sẹ́kọn),
						'other' => q({0}Sẹ́kọn),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(Wik),
						'one' => q({0}Wik),
						'other' => q({0}Wik),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(Wik),
						'one' => q({0}Wik),
						'other' => q({0}Wik),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(Yiẹ),
						'one' => q({0}Yiẹ),
						'other' => q({0}Yiẹ),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(Yiẹ),
						'one' => q({0}Yiẹ),
						'other' => q({0}Yiẹ),
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
					'length-astronomical-unit' => {
						'name' => q(ay),
						'one' => q({0} ay),
						'other' => q({0} ay),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ay),
						'one' => q({0} ay),
						'other' => q({0} ay),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sm),
						'one' => q({0}sm),
						'other' => q({0}sm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sm),
						'one' => q({0}sm),
						'other' => q({0}sm),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0} fátọ),
						'other' => q({0} fátọ),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0} fátọ),
						'other' => q({0} fátọ),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q({0} fọlọ),
						'other' => q({0} fọlọ),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q({0} fọlọ),
						'other' => q({0} fọlọ),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(km),
						'one' => q({0}km),
						'other' => q({0}km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(km),
						'one' => q({0}km),
						'other' => q({0}km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'one' => q({0}ly),
						'other' => q({0}ly),
					},
					# Core Unit Identifier
					'light-year' => {
						'one' => q({0}ly),
						'other' => q({0}ly),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
						'one' => q({0}m),
						'other' => q({0}m),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0}mm),
						'other' => q({0}mm),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q({0} is),
						'other' => q({0} is),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q({0} is),
						'other' => q({0} is),
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
					'mass-gram' => {
						'name' => q(Gram),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(Gram),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kg),
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0}kg),
						'other' => q({0}kg),
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
					'power2' => {
						'1' => q({0}²),
						'one' => q({0}²),
						'other' => q({0}²),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q({0}²),
						'one' => q({0}²),
						'other' => q({0}²),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q({0}³),
						'one' => q({0}³),
						'other' => q({0}³),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q({0}³),
						'one' => q({0}³),
						'other' => q({0}³),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(átmó),
						'one' => q({0} átmó),
						'other' => q({0} átmó),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(átmó),
						'one' => q({0} átmó),
						'other' => q({0} átmó),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(pfẹsi),
						'one' => q({0} pfẹsi),
						'other' => q({0} pfẹsi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(pfẹsi),
						'one' => q({0} pfẹsi),
						'other' => q({0} pfẹsi),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/áw),
						'one' => q({0} km/á),
						'other' => q({0} km/á),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/áw),
						'one' => q({0} km/á),
						'other' => q({0} km/á),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(N⋅m),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(N⋅m),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'one' => q({0}dzp-Imp),
						'other' => q({0}dzp-Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'one' => q({0}dzp-Imp),
						'other' => q({0}dzp-Imp),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(Líta),
						'one' => q({0}L),
						'other' => q({0}L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(Líta),
						'one' => q({0}L),
						'other' => q({0}L),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(Pọint),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(Pọint),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(Kí{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(Kí{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(Mím{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(Mím{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(Gím{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(Gím{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(Tím{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(Tím{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(Pím{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(Pím{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(Ẹím{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(Ẹím{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(Zím{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(Zím{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(Yím{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(Yím{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(D{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(D{0}),
					},
					# Long Unit Identifier
					'10p-12' => {
						'1' => q(p{0}),
					},
					# Core Unit Identifier
					'12' => {
						'1' => q(p{0}),
					},
					# Long Unit Identifier
					'10p-15' => {
						'1' => q(Fẹ́{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(Fẹ́{0}),
					},
					# Long Unit Identifier
					'10p-18' => {
						'1' => q(Á{0}),
					},
					# Core Unit Identifier
					'18' => {
						'1' => q(Á{0}),
					},
					# Long Unit Identifier
					'10p-2' => {
						'1' => q(s{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(s{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(Zẹ{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(Zẹ{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(Yo{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(Yo{0}),
					},
					# Long Unit Identifier
					'10p-3' => {
						'1' => q(m{0}),
					},
					# Core Unit Identifier
					'3' => {
						'1' => q(m{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(μ{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(μ{0}),
					},
					# Long Unit Identifier
					'10p-9' => {
						'1' => q(n{0}),
					},
					# Core Unit Identifier
					'9' => {
						'1' => q(n{0}),
					},
					# Long Unit Identifier
					'10p1' => {
						'1' => q(Dẹ́{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(Dẹ́{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(T{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(T{0}),
					},
					# Long Unit Identifier
					'10p15' => {
						'1' => q(P{0}),
					},
					# Core Unit Identifier
					'10p15' => {
						'1' => q(P{0}),
					},
					# Long Unit Identifier
					'10p18' => {
						'1' => q({0}Ẹ),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q({0}Ẹ),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(h{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(h{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(Zẹ́{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(Zẹ́{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(Yó{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(Yó{0}),
					},
					# Long Unit Identifier
					'10p3' => {
						'1' => q(k{0}),
					},
					# Core Unit Identifier
					'10p3' => {
						'1' => q(k{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(M{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(M{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(G{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(G{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(g-Fọs),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(g-Fọs),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(Míta/sẹk²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(Míta/sẹk²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(Ákmínits),
						'one' => q({0} Ákmín),
						'other' => q({0} Ákmín),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(Ákmínits),
						'one' => q({0} Ákmín),
						'other' => q({0} Ákmín),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(Áksẹ́kọns),
						'one' => q({0} Áksẹ́k),
						'other' => q({0} Áksẹ́k),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(Áksẹ́kọns),
						'one' => q({0} Áksẹ́k),
						'other' => q({0} Áksẹ́k),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(Digriis),
						'one' => q({0} dig),
						'other' => q({0} dig),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(Digriis),
						'one' => q({0} dig),
						'other' => q({0} dig),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(Rédians),
						'one' => q({0}Réd),
						'other' => q({0}Réd),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(Rédians),
						'one' => q({0}Réd),
						'other' => q({0}Réd),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(rẹv),
						'one' => q({0} rẹv),
						'other' => q({0} rẹv),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(rẹv),
						'one' => q({0} rẹv),
						'other' => q({0} rẹv),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(Ékas),
						'one' => q({0} ék),
						'other' => q({0} ék),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(Ékas),
						'one' => q({0} ék),
						'other' => q({0} ék),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(Dúnams),
						'one' => q({0} Dúnam),
						'other' => q({0} Dúnam),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(Dúnams),
						'one' => q({0} Dúnam),
						'other' => q({0} Dúnam),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(Hẹ́ktas),
						'one' => q({0} hẹ),
						'other' => q({0} hẹ),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(Hẹ́ktas),
						'one' => q({0} hẹ),
						'other' => q({0} hẹ),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(sm²),
						'one' => q({0} sm²),
						'other' => q({0} sm²),
						'per' => q({0}/sm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(sm²),
						'one' => q({0} sm²),
						'other' => q({0} sm²),
						'per' => q({0}/sm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(Skw Fut-dẹm),
						'one' => q({0} Skw ft),
						'other' => q({0} Skw ft),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(Skw Fut-dẹm),
						'one' => q({0} Skw ft),
						'other' => q({0} Skw ft),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(Ínchis2),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(Ínchis2),
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
						'name' => q(Mítas²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(Mítas²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(Skwiá Mails),
						'one' => q({0} skw ma),
						'other' => q({0} skw ma),
						'per' => q({0}/ma²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(Skwiá Mails),
						'one' => q({0} skw ma),
						'other' => q({0} skw ma),
						'per' => q({0}/ma²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(Yads²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(Yads²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(Karats),
						'one' => q({0} kar),
						'other' => q({0} kar),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(Karats),
						'one' => q({0} kar),
						'other' => q({0} kar),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mg/dL),
						'one' => q({0} mg/dL),
						'other' => q({0} mg/dL),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(Mílimol/Líta),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(Mílimol/Líta),
						'one' => q({0} mmol/L),
						'other' => q({0} mmol/L),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(mol),
						'one' => q({0} mol),
						'other' => q({0} mol),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mol),
						'one' => q({0} mol),
						'other' => q({0} mol),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(Pasẹnt),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(Pasẹnt),
						'one' => q({0}%),
						'other' => q({0}%),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(Fọ Ích Taúzan),
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(Fọ Ích Taúzan),
						'one' => q({0}‰),
						'other' => q({0}‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(Pat/Míliọn),
						'one' => q({0} pfim),
						'other' => q({0} pfim),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(Pat/Míliọn),
						'one' => q({0} pfim),
						'other' => q({0} pfim),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(Fọ Ích Tẹ́n Taúzan),
						'one' => q({0}‱),
						'other' => q({0}‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(Fọ Ích Tẹ́n Taúzan),
						'one' => q({0}‱),
						'other' => q({0}‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(L/100 km),
						'one' => q({0} L/100 km),
						'other' => q({0} L/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(Lítas/km),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(Lítas/km),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(Mails/gal),
						'one' => q({0} mfeg),
						'other' => q({0} mfeg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(Mails/gal),
						'one' => q({0} mfeg),
						'other' => q({0} mfeg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(Mails/gal Brítish),
						'one' => q({0} mfeg Brít),
						'other' => q({0} mfeg Brít),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(Mails/gal Brítish),
						'one' => q({0} mfeg Brít),
						'other' => q({0} mfeg Brít),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(Bit),
						'one' => q({0} Bit),
						'other' => q({0} Bit),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(Bit),
						'one' => q({0} Bit),
						'other' => q({0} Bit),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(Bait),
						'one' => q({0} Bait),
						'other' => q({0} Bait),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(Bait),
						'one' => q({0} Bait),
						'other' => q({0} Bait),
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
						'name' => q(GBait),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GBait),
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
						'name' => q(KBait),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(KBait),
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
						'name' => q(MBait),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MBait),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PBaít),
						'one' => q({0} PB),
						'other' => q({0} PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PBaít),
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
						'name' => q(TBait),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TBait),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(Họ́ndrẹ́d-yiẹ),
						'one' => q({0} Họ́nd-yiẹ́),
						'other' => q({0} Họ́nd-yiẹ́),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(Họ́ndrẹ́d-yiẹ),
						'one' => q({0} Họ́nd-yiẹ́),
						'other' => q({0} Họ́nd-yiẹ́),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(Dez),
						'one' => q({0} dè),
						'other' => q({0} dez),
						'per' => q({0}/d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(Dez),
						'one' => q({0} dè),
						'other' => q({0} dez),
						'per' => q({0}/d),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(Tẹ́n-tẹ́n-yiẹ),
						'one' => q({0} Tẹ́n-yiẹ),
						'other' => q({0}Tẹ́n-yiẹ),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(Tẹ́n-tẹ́n-yiẹ),
						'one' => q({0} Tẹ́n-yiẹ),
						'other' => q({0}Tẹ́n-yiẹ),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(Áwas),
						'one' => q({0} Áwa),
						'other' => q({0} Áwa),
						'per' => q({0}/a),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(Áwas),
						'one' => q({0} Áwa),
						'other' => q({0} Áwa),
						'per' => q({0}/a),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(Maíkrosẹ́kọns),
						'one' => q({0}Maíksẹ́k),
						'other' => q({0}Maiksẹk),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(Maíkrosẹ́kọns),
						'one' => q({0}Maíksẹ́k),
						'other' => q({0}Maiksẹk),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(Mílisẹ́kọn),
						'one' => q({0} Mílisẹ́kọn),
						'other' => q({0} Mílisẹ́kọn),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(Mílisẹ́kọn),
						'one' => q({0} Mílisẹ́kọn),
						'other' => q({0} Mílisẹ́kọn),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(Mínit),
						'one' => q({0} Mínit),
						'other' => q({0} Mínit),
						'per' => q({0}/min),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(Mínit),
						'one' => q({0} Mínit),
						'other' => q({0} Mínit),
						'per' => q({0}/min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(Mọnt-dẹm),
						'one' => q({0} Mọnt),
						'other' => q({0} Mọnt),
						'per' => q({0}/Mt),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(Mọnt-dẹm),
						'one' => q({0} Mọnt),
						'other' => q({0} Mọnt),
						'per' => q({0}/Mt),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(Nánosẹ́kọns),
						'one' => q({0} Nansẹk),
						'other' => q({0} Nansẹk),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(Nánosẹ́kọns),
						'one' => q({0} Nansẹk),
						'other' => q({0} Nansẹk),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(Sẹ́kọns),
						'one' => q({0} Sẹ́kọn),
						'other' => q({0} Sẹ́kọn),
						'per' => q({0}/sẹ́k),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(Sẹ́kọns),
						'one' => q({0} Sẹ́kọn),
						'other' => q({0} Sẹ́kọn),
						'per' => q({0}/sẹ́k),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(Wik),
						'one' => q({0} Wik),
						'other' => q(Wik {0}),
						'per' => q({0} Wik),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(Wik),
						'one' => q({0} Wik),
						'other' => q(Wik {0}),
						'per' => q({0} Wik),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(Yiẹ),
						'one' => q({0} Yiẹ),
						'other' => q({0} Yiẹ),
						'per' => q({0}/Yiẹ),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(Yiẹ),
						'one' => q({0} Yiẹ),
						'other' => q({0} Yiẹ),
						'per' => q({0}/Yiẹ),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amps),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amps),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(Míliámps),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(Míliámps),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(Oms),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(Oms),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(Volts),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(Volts),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(BTY),
						'one' => q({0}Bty),
						'other' => q({0}Bty),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(BTY),
						'one' => q({0}Bty),
						'other' => q({0}Bty),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kal),
						'one' => q({0} kal),
						'other' => q({0} kal),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kal),
						'one' => q({0} kal),
						'other' => q({0} kal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(Ẹlẹ́ktrọ́nvolt),
						'one' => q({0} ẹV),
						'other' => q({0} ẹV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(Ẹlẹ́ktrọ́nvolt),
						'one' => q({0} ẹV),
						'other' => q({0} ẹV),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Kal),
						'one' => q({0} Kal),
						'other' => q({0} Kal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Kal),
						'one' => q({0} Kal),
						'other' => q({0} Kal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(Joules),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(Joules),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kkal),
						'one' => q({0} kkal),
						'other' => q({0} kkal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kkal),
						'one' => q({0} kkal),
						'other' => q({0} kkal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(Kílojul),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(Kílojul),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(KW-áwa),
						'one' => q({0} kWa),
						'other' => q({0} kWa),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(KW-áwa),
						'one' => q({0} kWa),
						'other' => q({0} kWa),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(US Támál),
						'one' => q({0} US Támal),
						'other' => q({0} US Támal),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(US Támál),
						'one' => q({0} US Támal),
						'other' => q({0} US Támal),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(Niúton),
						'one' => q({0} N),
						'other' => q({0} N),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(Niúton),
						'one' => q({0} N),
						'other' => q({0} N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(Páund-Fọs),
						'one' => q({0} lbf),
						'other' => q({0} lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(Páund-Fọs),
						'one' => q({0} lbf),
						'other' => q({0} lbf),
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
						'name' => q(dọt),
						'one' => q({0} dọt),
						'other' => q({0} dọt),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(dọt),
						'one' => q({0} dọt),
						'other' => q({0} dọt),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(Pọints fọ ích sẹntímíta),
						'one' => q({0} PFIS),
						'other' => q({0} PFIS),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(Pọints fọ ích sẹntímíta),
						'one' => q({0} PFIS),
						'other' => q({0} PFIS),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(Pọints Fọ Ẹ́vrí Inch),
						'one' => q({0} PFẸI),
						'other' => q({0} PFẸI),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(Pọints Fọ Ẹ́vrí Inch),
						'one' => q({0} PFẸI),
						'other' => q({0} PFẸI),
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
						'name' => q(Mẹ́gapíksẹls),
						'one' => q({0} Mẹ́gapíks),
						'other' => q({0} Mẹ́gapíks),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(Mẹ́gapíksẹls),
						'one' => q({0} Mẹ́gapíks),
						'other' => q({0} Mẹ́gapíks),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(Píksẹls),
						'one' => q({0} Píksẹl),
						'other' => q({0} Píksẹl),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(Píksẹls),
						'one' => q({0} Píksẹl),
						'other' => q({0} Píksẹl),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(Píksẹls Fọ Ích Sẹntímíta),
						'one' => q({0} PFS),
						'other' => q({0} PFS),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(Píksẹls Fọ Ích Sẹntímíta),
						'one' => q({0} PFS),
						'other' => q({0} PFS),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(Píksẹl Fọ Ẹ́vrí Inch),
						'one' => q({0} PFI),
						'other' => q({0} PFI),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(Píksẹl Fọ Ẹ́vrí Inch),
						'one' => q({0} PFI),
						'other' => q({0} PFI),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(ay),
						'one' => q({0} ay),
						'other' => q({0} ay),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ay),
						'one' => q({0} ay),
						'other' => q({0} ay),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sm),
						'one' => q({0} sm),
						'other' => q({0} sm),
						'per' => q({0}/sm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sm),
						'one' => q({0} sm),
						'other' => q({0} sm),
						'per' => q({0}/sm),
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
						'name' => q(Fátọm),
						'one' => q({0} fátọ),
						'other' => q({0} fátọ),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(Fátọm),
						'one' => q({0} fátọ),
						'other' => q({0} fátọ),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(Fut-dẹm),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(Fut-dẹm),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(Fọ́lọng),
						'one' => q({0} fọl),
						'other' => q({0} fọl),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(Fọ́lọng),
						'one' => q({0} fọl),
						'other' => q({0} fọl),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(Ínchis),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(Ínchis),
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
						'name' => q(Laít Yiẹ),
						'one' => q({0}ly),
						'other' => q({0}ly),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(Laít Yiẹ),
						'one' => q({0}ly),
						'other' => q({0}ly),
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
						'name' => q(μmíta),
						'one' => q({0} μm),
						'other' => q({0} μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(μmíta),
						'one' => q({0} μm),
						'other' => q({0} μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(Mails),
						'one' => q({0} ma),
						'other' => q({0} ma),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(Mails),
						'one' => q({0} ma),
						'other' => q({0} ma),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(smi),
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
						'name' => q(Ích Sẹ́k),
						'one' => q({0} is),
						'other' => q({0} is),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(Ích Sẹ́k),
						'one' => q({0} is),
						'other' => q({0} is),
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
						'name' => q(points),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(points),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(Sólá Rédiọs-Dẹm),
						'one' => q({0} R☉),
						'other' => q({0} R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(Sólá Rédiọs-Dẹm),
						'one' => q({0} R☉),
						'other' => q({0} R☉),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(Yads),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(Yads),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kd),
						'one' => q({0} kd),
						'other' => q({0} kd),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kd),
						'one' => q({0} kd),
						'other' => q({0} kd),
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
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lux),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(Sólá Luminósítis),
						'one' => q({0} L☉),
						'other' => q({0} L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(Sólá Luminósítis),
						'one' => q({0} L☉),
						'other' => q({0} L☉),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(Kárats),
						'one' => q({0} Kt),
						'other' => q({0} Kt),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(Kárats),
						'one' => q({0} Kt),
						'other' => q({0} Kt),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(Dọ́ltons),
						'one' => q({0} Dọ),
						'other' => q({0} Dọ),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(Dọ́ltons),
						'one' => q({0} Dọ),
						'other' => q({0} Dọ),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(Ẹ́t Masís),
						'one' => q({0} M⊕),
						'other' => q({0} M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(Ẹ́t Masís),
						'one' => q({0} M⊕),
						'other' => q({0} M⊕),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(Gren),
						'one' => q({0} gren),
						'other' => q({0} gren),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(Gren),
						'one' => q({0} gren),
						'other' => q({0} gren),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(Grams),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(Grams),
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
						'name' => q(T),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					# Core Unit Identifier
					'metric-ton' => {
						'name' => q(T),
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
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz trọi),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz trọi),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(Paunds),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(Paunds),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(Sólá Masís),
						'one' => q({0} M☉),
						'other' => q({0} M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(Sólá Masís),
						'one' => q({0} M☉),
						'other' => q({0} M☉),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(Ston),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(Ston),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(Tọns),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(Tọns),
						'one' => q({0} tn),
						'other' => q({0} tn),
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
						'name' => q(Wats),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(Wats),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q({0}²),
						'one' => q({0}²),
						'other' => q({0}²),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q({0}²),
						'one' => q({0}²),
						'other' => q({0}²),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q({0}³),
						'one' => q({0}³),
						'other' => q({0}³),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q({0}³),
						'one' => q({0}³),
						'other' => q({0}³),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(átmó),
						'one' => q({0} átmó),
						'other' => q({0} átmó),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(átmó),
						'one' => q({0} átmó),
						'other' => q({0} átmó),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(Baa),
						'one' => q({0} Baa),
						'other' => q({0} Baa),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(Baa),
						'one' => q({0} Baa),
						'other' => q({0} Baa),
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
						'name' => q(mbaa),
						'one' => q({0} mbaa),
						'other' => q({0} mbaa),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(mbaa),
						'one' => q({0} mbaa),
						'other' => q({0} mbaa),
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
						'name' => q(pfẹsi),
						'one' => q({0} pfẹsi),
						'other' => q({0} pfẹsi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(pfẹsi),
						'one' => q({0} pfẹsi),
						'other' => q({0} pfẹsi),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/áwa),
						'one' => q({0} km/á),
						'other' => q({0} km/á),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/áwa),
						'one' => q({0} km/á),
						'other' => q({0} km/á),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(Nọt),
						'one' => q({0} Nọt),
						'other' => q({0} Nọt),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(Nọt),
						'one' => q({0} Nọt),
						'other' => q({0} Nọt),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(Mítas/Sẹk),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(Mítas/Sẹk),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(Mails/Áwa),
						'one' => q({0} mfẹa),
						'other' => q({0} mfẹa),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(Mails/Áwa),
						'one' => q({0} mfẹa),
						'other' => q({0} mfẹa),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(Dig. C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(Dig. C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(dig. F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(dig. F),
						'one' => q({0}°F),
						'other' => q({0}°F),
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
						'1' => q({0}⋅{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}⋅{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(N.m),
						'one' => q({0} N⋅m),
						'other' => q({0} N⋅m),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(N.m),
						'one' => q({0} N⋅m),
						'other' => q({0} N⋅m),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(lbf⋅ft),
						'one' => q({0} lbf⋅ft),
						'other' => q({0} lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(lbf⋅ft),
						'one' => q({0} lbf⋅ft),
						'other' => q({0} lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(Éka ft),
						'one' => q({0} ek ft),
						'other' => q({0} ek ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(Éka ft),
						'one' => q({0} ek ft),
						'other' => q({0} ek ft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(Drọm),
						'one' => q({0}dr),
						'other' => q({0}dr),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(Drọm),
						'one' => q({0}dr),
						'other' => q({0}dr),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(Búshẹl),
						'one' => q({0} bú),
						'other' => q({0} bú),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(Búshẹl),
						'one' => q({0} bú),
						'other' => q({0} bú),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sl),
						'one' => q({0} sl),
						'other' => q({0} sl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sl),
						'one' => q({0} sl),
						'other' => q({0} sl),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(sm³),
						'one' => q({0} sm³),
						'other' => q({0} sm³),
						'per' => q({0}/sm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(sm³),
						'one' => q({0} sm³),
						'other' => q({0} sm³),
						'per' => q({0}/sm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(Fut³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(Fut³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(Ínchis³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(Ínchis³),
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
						'name' => q(ma³),
						'one' => q({0} ma³),
						'other' => q({0} ma³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(ma³),
						'one' => q({0} ma³),
						'other' => q({0} ma³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(Yáds³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(Yáds³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(Kọps),
						'one' => q({0} Kọp),
						'other' => q({0} Kọp),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(Kọps),
						'one' => q({0} Kọp),
						'other' => q({0} Kọp),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(mkọp),
						'one' => q({0} mk),
						'other' => q({0} mk),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(mkọp),
						'one' => q({0} mk),
						'other' => q({0} mk),
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
						'name' => q(Dztspn),
						'one' => q({0} dztspn),
						'other' => q({0} dztspn),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(Dztspn),
						'one' => q({0} dztspn),
						'other' => q({0} dztspn),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(Dztspn Imp),
						'one' => q({0} dzsp Imp),
						'other' => q({0} dzsp Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(Dztspn Imp),
						'one' => q({0} dzsp Imp),
						'other' => q({0} dzsp Imp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(Drám Líkwid),
						'one' => q({0} Dram lí),
						'other' => q({0} Dram lí),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(Drám Líkwid),
						'one' => q({0} Dram lí),
						'other' => q({0} Dram lí),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(Drọp),
						'one' => q({0} Drọp),
						'other' => q({0} Drọp),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(Drọp),
						'one' => q({0} Drọp),
						'other' => q({0} Drọp),
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
					'volume-fluid-ounce-imperial' => {
						'name' => q(Brít. Fl oz),
						'one' => q({0} fl oz Brit.),
						'other' => q({0} fl oz Brit.),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Brít. Fl oz),
						'one' => q({0} fl oz Brit.),
						'other' => q({0} fl oz Brit.),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal US),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal US),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(Brít. gal),
						'one' => q({0} Brít. gal),
						'other' => q({0} Brít. gal),
						'per' => q({0} Brít. gal),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(Brít. gal),
						'one' => q({0} Brít. gal),
						'other' => q({0} Brít. gal),
						'per' => q({0} Brít. gal),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(Jigá),
						'one' => q({0} Jigá),
						'other' => q({0} Jigá),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(Jigá),
						'one' => q({0} Jigá),
						'other' => q({0} Jigá),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(Lítas),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(Lítas),
						'one' => q({0} L),
						'other' => q({0} L),
						'per' => q({0}/L),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
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
						'name' => q(Pinch),
						'one' => q({0} Pinch),
						'other' => q({0} Pinch),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(Pinch),
						'one' => q({0} Pinch),
						'other' => q({0} Pinch),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(Paints),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(Paints),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kwts),
						'one' => q({0} kwt),
						'other' => q({0} kwt),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kwts),
						'one' => q({0} kwt),
						'other' => q({0} kwt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(Kt Impẹ́riál),
						'one' => q({0} Kt Imp),
						'other' => q({0} Kt Imp),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(Kt Impẹ́riál),
						'one' => q({0} Kt Imp),
						'other' => q({0} Kt Imp),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(Tbsp),
						'one' => q({0} Tbsp),
						'other' => q({0} Tbsp),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(Tbsp),
						'one' => q({0} Tbsp),
						'other' => q({0} Tbsp),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(Tsp),
						'one' => q({0} Tsp),
						'other' => q({0} Tsp),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(Tsp),
						'one' => q({0} Tsp),
						'other' => q({0} Tsp),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:yẹs|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0}, {1}),
				middle => q({0}, {1}),
				end => q({0}, {1}),
				2 => q({0}, {1}),
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

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(.),
			'exponential' => q(E),
			'group' => q(,),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(-),
			'nan' => q(NaN),
			'perMille' => q(‰),
			'percentSign' => q(%),
			'plusSign' => q(+),
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
					'one' => '0 Taúzan',
					'other' => '0 Taúzan',
				},
				'10000' => {
					'one' => '00 Taúzan',
					'other' => '00 Taúzan',
				},
				'100000' => {
					'one' => '000 Taúzan',
					'other' => '000 Taúzan',
				},
				'1000000' => {
					'one' => '0 Míliọn',
					'other' => '0 Míliọn',
				},
				'10000000' => {
					'one' => '00 Míliọn',
					'other' => '00 Míliọn',
				},
				'100000000' => {
					'one' => '000 Míliọn',
					'other' => '000 Míliọn',
				},
				'1000000000' => {
					'one' => '0 Bíliọn',
					'other' => '0 Bíliọn',
				},
				'10000000000' => {
					'one' => '00 Bíliọn',
					'other' => '00 Bíliọn',
				},
				'100000000000' => {
					'one' => '000 Bíliọn',
					'other' => '000 Bíliọn',
				},
				'1000000000000' => {
					'one' => '0 Tríliọn',
					'other' => '0 Tríliọn',
				},
				'10000000000000' => {
					'one' => '00 Tríliọn',
					'other' => '00 Tríliọn',
				},
				'100000000000000' => {
					'one' => '000 Tríliọn',
					'other' => '000 Tríliọn',
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
		'latn' => {
			'pattern' => {
				'default' => {
					'accounting' => {
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
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(Yunaítẹ́d Áráb Ẹ́míréts Dírham),
				'one' => q(Yunaítẹ́d Áráb Ẹ́míréts dírham),
				'other' => q(Yunaítẹ́d Áráb Ẹ́míréts dírhams),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Afgán Afgáni),
				'one' => q(Afgán afgáni),
				'other' => q(Afgán afgánis),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(Albéniá Lẹk),
				'one' => q(Albéniá Lẹk),
				'other' => q(Albéniá Lẹk),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Armẹ́niá Dram),
				'one' => q(Armẹ́nia ́dram),
				'other' => q(Armẹ́niá drams),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Nẹ́dalánds Antílián Gílda),
				'one' => q(Nẹ́dalánds Antílián Gílda),
				'other' => q(Nẹ́dalánds Antílián Gílda),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Angólá Kwánza),
				'one' => q(Angólá kwánza),
				'other' => q(Angólá kwánzas),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Ajẹntína Pẹ́so),
				'one' => q(Ajẹntína Pẹ́so),
				'other' => q(Ajẹntína Pẹ́so),
			},
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(Ọstréliá Dọ́la),
				'one' => q(Ọstréliá dọ́la),
				'other' => q(Ọstréliá dọ́las),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Arúba Flọ́rin),
				'one' => q(Arúba Flọ́rin),
				'other' => q(Arúba Flọ́rin),
			},
		},
		'AZN' => {
			symbol => 'AZN',
			display_name => {
				'currency' => q(Azẹrbaiján Mánat),
				'one' => q(Azẹrbaiján mánat),
				'other' => q(Azẹrbaiján mánats),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Bọ́sniá an Hẹzẹgovína Mak Wé Pẹ́sin Fít Chenj),
				'one' => q(Bọ́sniá an Hẹzẹgovína Mak Wé Pẹ́sin Fít Chenj),
				'other' => q(Bọ́sniá an Hẹzẹgovína Mak Wé Pẹ́sin Fít Chenj),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Barbédọs Dọ́la),
				'one' => q(Barbédọs Dọ́la),
				'other' => q(Barbédọs Dọ́la),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Bangladẹ́sh Táka),
				'one' => q(Bangladẹ́sh táka),
				'other' => q(Bangladẹ́sh táka),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Bọlgériá Lẹv),
				'one' => q(Bọlgériá Lẹv),
				'other' => q(Bọlgériá Lẹv),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Baréin Dínar),
				'one' => q(Baréin dínar),
				'other' => q(Baréin dínars),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Burúndí Frank),
				'one' => q(Burúndí frank),
				'other' => q(Burúndí franks),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Bẹmiúda Dọ́la),
				'one' => q(Bẹmiúda Dọ́la),
				'other' => q(Bẹmiúda Dọ́la),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Brunẹí Dọ́la),
				'one' => q(Brunẹí dọ́la),
				'other' => q(Brunẹí dọ́las),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Bolíviá Boliviáno),
				'one' => q(Bolíviá Boliviáno),
				'other' => q(Bolíviá Boliviáno),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Brazíl Rẹal),
				'one' => q(Brazíl Rẹal),
				'other' => q(Brazíl Rẹal),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Bahámas Dọ́la),
				'one' => q(Bahámas Dọ́la),
				'other' => q(Bahámas Dọ́la),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Bután Ngúltrum),
				'one' => q(Bután ngúltrum),
				'other' => q(Bután ngúltrums),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Botswáná Púla),
				'one' => q(Botswáná púla),
				'other' => q(Botswáná púlas),
			},
		},
		'BYN' => {
			symbol => 'BYN',
			display_name => {
				'currency' => q(Bẹlarús Rúbul),
				'one' => q(Bẹlarús Rúbul),
				'other' => q(Bẹlarús Rúbul),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Bẹliz Dọ́la),
				'one' => q(Bẹliz Dọ́la),
				'other' => q(Bẹliz Dọ́la),
			},
		},
		'CAD' => {
			symbol => 'KA$',
			display_name => {
				'currency' => q(Kánádá Dọ́la),
				'one' => q(Kánádá Dọ́la),
				'other' => q(Kánádá Dọ́la),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Kóngó Frank),
				'one' => q(Kóngó frank),
				'other' => q(Kóngó franks),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(Swís Frank),
				'one' => q(Swís Frank),
				'other' => q(Swís Frank),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Chílí Pẹ́so),
				'one' => q(Chílí Pẹ́so),
				'other' => q(Chílí Pẹ́so),
			},
		},
		'CNH' => {
			symbol => 'CNH',
			display_name => {
				'currency' => q(Chaíná Yuan \(ples-dẹm aúsaíd chaína\)),
				'one' => q(Chaíná yuan \(ples-dẹm aúsaíd chaína\)),
				'other' => q(Chaíná yuans \(ples-dẹm aúsaíd chaína\)),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Chaíná Yuan),
				'one' => q(Chaíná yuan),
				'other' => q(Chaíná yuans),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Kolómbiá Pẹ́so),
				'one' => q(Kolómbiá pẹ́so),
				'other' => q(Kolómbiá pẹ́sos),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Kósta Ríka Kólọn),
				'one' => q(Kósta Ríka Kólọn),
				'other' => q(Kósta Ríka Kólọn),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Kiúbá Pẹ́so Wé Pẹ́sin Fít Chenj),
				'one' => q(Kiúbá Pẹ́so Wé Pẹ́sin Fít Chenj),
				'other' => q(Kiúbá Pẹ́so Wé Pẹ́sin Fít Chenj),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Kiúbá Pẹ́so),
				'one' => q(Kiúbá Pẹ́so),
				'other' => q(Kiúbá Pẹ́so),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Kép Vẹ́d Ẹskúdo),
				'one' => q(Kép Vẹ́d ẹskúdo),
				'other' => q(Kép Vẹ́d ẹskúdos),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Chẹ́k Kórúna),
				'one' => q(Chẹ́k Kórúna),
				'other' => q(Chẹ́k Kórúna),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Jibútí Frank),
				'one' => q(Jibútí frank),
				'other' => q(Jibútí franks),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Dẹ́nmák Króna),
				'one' => q(Dẹ́nmák Króna),
				'other' => q(Dẹ́nmák Króna),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Dọmíníkan Pẹ́so),
				'one' => q(Dọmíníkan Pẹ́so),
				'other' => q(Dọmíníkan Pẹ́so),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Aljíria Dínar),
				'one' => q(Aljíria Dínar),
				'other' => q(Aljíria Dínar),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Íjípt Paund),
				'one' => q(Íjípt Paund),
				'other' => q(Íjípt Paund),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Ẹritrẹá Nákfa),
				'one' => q(Ẹritrẹá nákfa),
				'other' => q(Ẹritrẹá nákfas),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Ẹtiópiá Berr),
				'one' => q(Ẹtiópiá berr),
				'other' => q(Ẹtiópiá berrs),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Yúro),
				'one' => q(eúro),
				'other' => q(eúros),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(Fíjí Dọ́la),
				'one' => q(Fíjí dọ́la),
				'other' => q(Fíjí dọ́las),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Fọlkland Aílands Paund),
				'one' => q(Fọlkland Aílands paund),
				'other' => q(Fọlkland Aílands paunds),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Brítísh Páund),
				'one' => q(Brítísh Páund),
				'other' => q(Brítísh Páund),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Jọ́jiá Lári),
				'one' => q(Jọ́jiá lári),
				'other' => q(Jọ́jiá láris),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Ganá Sídi),
				'one' => q(Ganá sídi),
				'other' => q(Ganá sídis),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Jibrọ́lta Páund),
				'one' => q(Jibrọ́lta Páund),
				'other' => q(Jibrọ́lta Páund),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Gámbiá Dalási),
				'one' => q(Gámbiá dalási),
				'other' => q(Gámbiá dalásis),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(Gíní Frank),
				'one' => q(Gíní frank),
				'other' => q(Gíní franks),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Guátẹmála Kwuẹ́tzal),
				'one' => q(Guátẹmála Kwuẹ́tzal),
				'other' => q(Guátẹmála Kwuẹ́tzal),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Giyána Dọ́la),
				'one' => q(Giyána dọ́la),
				'other' => q(Giyána dọ́las),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Họng Kọ́ng Dọ́la),
				'one' => q(Họng Kọ́ng dọ́la),
				'other' => q(Họng Kọ́ng dọ́las),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Họndúrán Lẹmpíra),
				'one' => q(Họndúrán Lẹmpíra),
				'other' => q(Họndúrán Lẹmpíra),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Kroéshia Kúna),
				'one' => q(Kroéshia Kúna),
				'other' => q(Kroéshia Kúna),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Haíti Gourd),
				'one' => q(Haíti Gourd),
				'other' => q(Haíti Gourd),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Họngériá Fọ́rint),
				'one' => q(Họngériá Fọ́rint),
				'other' => q(Họngériá Fọ́rint),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Indoníshiá Rupia),
				'one' => q(Indoníshiá rupia),
				'other' => q(Indoníshiá rupias),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(Ízrẹ́l Niú Shẹ́kẹl),
				'one' => q(Ízrẹ́l niú shẹ́kẹl),
				'other' => q(Ízrẹ́l niú shẹ́kẹls),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Índiá Rúpi),
				'one' => q(Índiá rúpi),
				'other' => q(Índiá rúpis),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(Irák Dínar),
				'one' => q(Irák dínar),
				'other' => q(Irák dínars),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Irán Rial),
				'one' => q(Irán rial),
				'other' => q(Irán rials),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(Aíslánd Króna),
				'one' => q(Aíslánd Króna),
				'other' => q(Aíslánd Króna),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Jamaíka Dọla),
				'one' => q(Jamaíka Dọla),
				'other' => q(Jamaíka Dọla),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(Jọ́dán Dínar),
				'one' => q(Jọ́dán dínar),
				'other' => q(Jọ́dán dínars),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Japán Yẹn),
				'one' => q(Japán yẹn),
				'other' => q(Japán yẹns),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Kẹ́nyá Shílin),
				'one' => q(Kẹ́nyá shílin),
				'other' => q(Kẹ́nyá shílins),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Kẹjístan Som),
				'one' => q(Kẹjístan som),
				'other' => q(Kẹjístan soms),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Kambódiá Riẹl),
				'one' => q(Kambódiá riẹl),
				'other' => q(Kambódiá riẹls),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Kọ́mọ́ros Frank),
				'one' => q(Kọ́mọ́ros frank),
				'other' => q(Kọ́mọ́ros franks),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Nọ́t Koriá Wọn),
				'one' => q(Nọ́t Koriá wọn),
				'other' => q(Nọ́t Koriá wọns),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Saút Koriá Wọn),
				'one' => q(Saút Koriá wọn),
				'other' => q(Saút Koriá wọns),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Kuwét Dínar),
				'one' => q(Kuwét dínar),
				'other' => q(Kuwét dínars),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Kéman Aílands Dọla),
				'one' => q(Kéman Aílands Dọla),
				'other' => q(Kéman Aílands Dọla),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Kazakstan Tẹ́nj),
				'one' => q(Kazakstan tẹ́nj),
				'other' => q(Kazakstan tẹ́njs),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Laós Kip),
				'one' => q(Laós kip),
				'other' => q(Laós kips),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Lẹ́bánọ́n Paund),
				'one' => q(Lẹ́bánọ́n paund),
				'other' => q(Lẹ́bánọ́n paunds),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Sri Lánká Rúpi),
				'one' => q(Sri Lánká rúpi),
				'other' => q(Sri Lánká rúpis),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Laibẹ́riá Dọ́la),
				'one' => q(Laibẹ́riá dọ́la),
				'other' => q(Laibẹ́riá dọ́las),
			},
		},
		'LSL' => {
			symbol => 'LSL',
			display_name => {
				'currency' => q(Lẹsóto Lọ́ti),
				'one' => q(Lẹsóto Lọ́ti),
				'other' => q(Lẹsóto Lọ́tis),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Líbia Dínar),
				'one' => q(Líbia Dínar),
				'other' => q(Líbia Dínar),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Morọko Dírham),
				'one' => q(Morọko Dírham),
				'other' => q(Morọko Dírham),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Mọldóva Lu),
				'one' => q(Mọldóva Lu),
				'other' => q(Mọldóva Lu),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Malagásí Ariári),
				'one' => q(Malagásí ariári),
				'other' => q(Malagásí ariáris),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Masẹdónia Dínar),
				'one' => q(Masẹdónia Dínar),
				'other' => q(Masẹdónia Dínar),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Miánmá Kiat),
				'one' => q(Miánmá kiat),
				'other' => q(Miánmá kiats),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Mọngóliá Túgrik),
				'one' => q(Mọngóliá túgrik),
				'other' => q(Mọngóliá túgriks),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Makáo Pátáka),
				'one' => q(Makáo pátáka),
				'other' => q(Makáo pátákas),
			},
		},
		'MRU' => {
			symbol => 'MRU',
			display_name => {
				'currency' => q(Mọriténiá Uguíya),
				'one' => q(Mọriténiá uguíya),
				'other' => q(Mọriténiá uguíyas),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Mọríshọ́s Rúpi),
				'one' => q(Mọríshọ́s rúpi),
				'other' => q(Mọríshọ́s rúpis),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Mọ́ldívs Rúfíya),
				'one' => q(Mọ́ldívs rúfíya),
				'other' => q(Mọ́ldívs rúfíyas),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Maláwi ́Kwácha),
				'one' => q(Maláwi ́kwácha),
				'other' => q(Maláwí kwáchas),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(Mẹ́ksíko Pẹ́so),
				'one' => q(Mẹ́ksíko Pẹ́so),
				'other' => q(Mẹ́ksíko Pẹ́so),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Maléshiá Ríngit),
				'one' => q(Maléshiá ríngit),
				'other' => q(Maléshiá ríngits),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Mozámbík Métíkal),
				'one' => q(Mozámbík métíkal),
				'other' => q(Mozámbík métíkals),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Namíbiá Dọ́la),
				'one' => q(Namíbiá dọ́la),
				'other' => q(Namíbiá dọ́las),
			},
		},
		'NGN' => {
			symbol => '₦',
			display_name => {
				'currency' => q(Naijíriá Naíra),
				'one' => q(Naijíriá naíra),
				'other' => q(Naijíriá naíras),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Nikarágwua Kordóba),
				'one' => q(Nikarágwua Kordóba),
				'other' => q(Nikarágwua Kordóba),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Nọ́wé Króna),
				'one' => q(Nọ́wé Króna),
				'other' => q(Nọ́wé Króna),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Nẹ́pál Rúpi),
				'one' => q(Nẹ́pál rúpi),
				'other' => q(Nẹ́pál rúpis),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Niú Zílánd Dọ́las),
				'one' => q(Niú Zílánd dọ́la),
				'other' => q(Niú Zílánd dọ́las),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Omán Rial),
				'one' => q(Omán rial),
				'other' => q(Omán rials),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Pánáma Balbóa),
				'one' => q(Pánáma Balbóa),
				'other' => q(Pánáma Balbóa),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Pẹrúvián Sol),
				'one' => q(Pẹrúvián Sol),
				'other' => q(Pẹrúvián Sol),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Pápuá Niú Gíni Kína),
				'one' => q(Pápuá Niú Gíni kína),
				'other' => q(Pápuá Niú Gíni kínas),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Fílípíns Píso),
				'one' => q(Fílípíns píso),
				'other' => q(Fílípíns písos),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Pakístán Rúpi),
				'one' => q(Pakístán rúpi),
				'other' => q(Pakístán rúpis),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Pólánd Zílọ́ti),
				'one' => q(Pólánd Zílọ́ti),
				'other' => q(Pólánd Zílọ́ti),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Páragwuá Guaráni),
				'one' => q(Páragwuá Guaráni),
				'other' => q(Páragwuá Guaráni),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Kata Ríal),
				'one' => q(Kata ríal),
				'other' => q(Kata ríals),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Roméniá Lu),
				'one' => q(Roméniá Lu),
				'other' => q(Roméniá Lu),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Sẹrbia Dínar),
				'one' => q(Sẹrbia Dínar),
				'other' => q(Sẹrbia Dínar),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Rọ́shiá Rúbul),
				'one' => q(Rọ́shiá Rúbul),
				'other' => q(Rọ́shiá Rúbul),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Ruwándá Frank),
				'one' => q(Ruwándá frank),
				'other' => q(Ruwándá franks),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Saúdí Arébiá Riyal),
				'one' => q(Saúdí Arébiá riyal),
				'other' => q(Saúdí Arébiá riyals),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Sólómọ́n Aílands Dọ́la),
				'one' => q(Sólómọ́n Aílands dọ́la),
				'other' => q(Sólómọ́n Aílands dọ́las),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Sẹ́chẹ́ls Rúpi),
				'one' => q(Sẹ́chẹ́ls rúpi),
				'other' => q(Sẹ́chẹ́ls rúpis),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Sudan Paund),
				'one' => q(Sudan Paund),
				'other' => q(Sudan Paund),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(Swídẹ́n Króna),
				'one' => q(Swídẹ́n Króna),
				'other' => q(Swídẹ́n Króna),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Singapọ́ Dọ́la),
				'one' => q(Singapọ́ dọ́la),
				'other' => q(Singapọ́ dọ́las),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Sent Hẹlẹ́ná Paund),
				'one' => q(Sent Hẹlẹ́ná paund),
				'other' => q(Sent Hẹlẹ́ná paunds),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Siẹ́ra Líoniá Liọn),
				'one' => q(Siẹ́ra Líoniá liọn),
				'other' => q(Siẹ́ra Líoniá liọns),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Sọmáliá Shílin),
				'one' => q(Sọmáliá shílin),
				'other' => q(Sọmáliá shílins),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Súrínám Dọla),
				'one' => q(Súrínám Dọla),
				'other' => q(Súrínám Dọla),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Saút Sudán Paund),
				'one' => q(Saút Sudán paund),
				'other' => q(Saút Sudán paunds),
			},
		},
		'STN' => {
			symbol => 'STN',
			display_name => {
				'currency' => q(Sao Tómẹ & Prínsípẹ Dóbra),
				'one' => q(Sao Tómẹ & Prínsípẹ dóbra),
				'other' => q(Sao Tómẹ & Prínsípẹ dóbras),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Síriá Paund),
				'one' => q(Síriá paund),
				'other' => q(Síriá paunds),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Swází Lilánjẹ́ni),
				'one' => q(Swází lilánjẹ́ni),
				'other' => q(Swází ẹmalánjẹ́ni),
			},
		},
		'THB' => {
			symbol => 'THB',
			display_name => {
				'currency' => q(Taílánd Baht),
				'one' => q(Taílánd baht),
				'other' => q(Taílánd bahts),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Tajíkstan Sómóni),
				'one' => q(Tajíkstan sómóni),
				'other' => q(Tajíkstan sómónis),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Tọkmẹ́nístán Mánat),
				'one' => q(Tọkmẹ́nístán mánat),
				'other' => q(Tọkmẹ́nístán mánats),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Tuníshia Dínar),
				'one' => q(Tuníshia Dínar),
				'other' => q(Tuníshia Dínar),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Tónga Pánga),
				'one' => q(Tónga pánga),
				'other' => q(Tónga pángas),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Tọ́kí Líra),
				'one' => q(Tọ́kí líra),
				'other' => q(Tọ́kí líras),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Trínídad & Tobágo Dọ́la),
				'one' => q(Trínídad & Tobágo Dọ́la),
				'other' => q(Trínídad & Tobágo Dọ́la),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Niú Taiwán Dọ́la),
				'one' => q(Niú Taiwán dọ́la),
				'other' => q(Niú Taiwán dọ́las),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Tanzániá Shílin),
				'one' => q(Tanzániá shílin),
				'other' => q(Tanzániá shílins),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Yukrẹín Rívnia),
				'one' => q(Yukrẹín Rívnia),
				'other' => q(Yukrẹín Rívnia),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Yugándá Shílin),
				'one' => q(Yugándá shílin),
				'other' => q(Yugándá shílins),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(US Dọ́la),
				'one' => q(US Dọ́la),
				'other' => q(Amẹ́ríká Dọ́la),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Yurugwaí Pẹ́so),
				'one' => q(Yurugwaí Pẹ́so),
				'other' => q(Yurugwaí Pẹ́so),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(Uzbẹ́kistan Som),
				'one' => q(Uzbẹ́kistan som),
				'other' => q(Uzbẹ́kistan soms),
			},
		},
		'VES' => {
			symbol => 'VES',
			display_name => {
				'currency' => q(Vẹnẹzuẹlá Bolívar),
				'one' => q(Vẹnẹzuẹlá Bolívar),
				'other' => q(Vẹnẹzuẹlá Bolívar),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Viẹ́tnám Dọng),
				'one' => q(Viẹ́tnám dọng),
				'other' => q(Viẹ́tnám dọngs),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Vanuátú Vátu),
				'one' => q(Vanuátú vátu),
				'other' => q(Vanuátú vátus),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Samóa Tála),
				'one' => q(Samóa tála),
				'other' => q(Samóa tálas),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(Sẹ́ntrál Áfríká Frank),
				'one' => q(Sẹ́ntrál Áfríká frank),
				'other' => q(Sẹ́ntrál Áfríká franks),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(Íst Karíbián Dọla),
				'one' => q(Íst Karíbián Dọla),
				'other' => q(Íst Karíbián Dọla),
			},
		},
		'XOF' => {
			symbol => 'F CFA',
			display_name => {
				'currency' => q(Wẹ́st Afríká Sẹ́fa Frank),
				'one' => q(Wẹ́st Afríká Sẹ́fa frank),
				'other' => q(Wẹ́st Afríká Sẹ́fa franks),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(Frẹ́nch Poliníshiá Frank),
				'one' => q(Frẹ́nch Poliníshiá frank),
				'other' => q(Frẹ́nch Poliníshiá franks),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Mọní Wé Pípol Nọ No),
				'one' => q(mọní wé pípul nọ́ no),
				'other' => q(\(mọní wé pípol nọ no\)),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Yẹ́mẹ́n Rial),
				'one' => q(Yẹ́mẹ́n rial),
				'other' => q(Yẹ́mẹ́n rials),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Saút Áfríká Rand),
				'one' => q(Saút Áfríká rand),
				'other' => q(Saút Áfríká rands),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Zámbiá Kwácha),
				'one' => q(Zámbiá kwácha),
				'other' => q(Zámbiá kwáchas),
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
							'Jén',
							'Fẹ́b',
							'Mach',
							'Épr',
							'Mee',
							'Jun',
							'Jul',
							'Ọgọ',
							'Sẹp',
							'Ọkt',
							'Nọv',
							'Dis'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'J',
							'F',
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
					wide => {
						nonleap => [
							'Jénúári',
							'Fẹ́búári',
							'Mach',
							'Éprel',
							'Mee',
							'Jun',
							'Julai',
							'Ọgọst',
							'Sẹptẹ́mba',
							'Ọktóba',
							'Nọvẹ́mba',
							'Disẹ́mba'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Jén',
							'Fẹ́b',
							'Mach',
							'Épr',
							'Mee',
							'Jun',
							'Jul',
							'Ọ́gọ',
							'Sẹp',
							'Ọkt',
							'Nọv',
							'Dis'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'J',
							'F',
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
					wide => {
						nonleap => [
							'Jénúári',
							'Fẹ́búári',
							'Mach',
							'Éprel',
							'Mee',
							'Jun',
							'Julai',
							'Ọgọst',
							'Sẹptẹ́mba',
							'Ọktóba',
							'Nọvẹ́mba',
							'Disẹ́mba'
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
						mon => 'Mọ́n',
						tue => 'Tiú',
						wed => 'Wẹ́n',
						thu => 'Tọ́z',
						fri => 'Fraí',
						sat => 'Sát',
						sun => 'Sọ́n'
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
						mon => 'Mọ́n',
						tue => 'Tiú',
						wed => 'Wẹ́n',
						thu => 'Tọ́z',
						fri => 'Fraí',
						sat => 'Sát',
						sun => 'Sọ́n'
					},
					wide => {
						mon => 'Mọ́ndè',
						tue => 'Tiúzdè',
						wed => 'Wẹ́nẹ́zdè',
						thu => 'Tọ́zdè',
						fri => 'Fraídè',
						sat => 'Sátọdè',
						sun => 'Sọ́ndè'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Mọ́n',
						tue => 'Tiú',
						wed => 'Wẹ́n',
						thu => 'Tọ́z',
						fri => 'Fraí',
						sat => 'Sát',
						sun => 'Sọ́n'
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
						mon => 'Mọ́n',
						tue => 'Tiú',
						wed => 'Wẹ́n',
						thu => 'Tọ́z',
						fri => 'Fraí',
						sat => 'Sát',
						sun => 'Sọ́n'
					},
					wide => {
						mon => 'Mọ́ndè',
						tue => 'Tiúzdè',
						wed => 'Wẹ́nẹ́zdè',
						thu => 'Tọ́zdè',
						fri => 'Fraídè',
						sat => 'Sátọdè',
						sun => 'Sọ́ndè'
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
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Fẹ́st Kwọ́ta',
						1 => 'Sẹ́kọ́n Kwọ́ta',
						2 => 'Tọ́d Kwọ́ta',
						3 => 'Fọ́t Kwọ́ta'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'K1',
						1 => 'K2',
						2 => 'K3',
						3 => 'K4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => 'Fẹ́st Kwọ́ta',
						1 => 'Sẹ́kọ́n Kwọ́ta',
						2 => 'Tọ́d Kwọ́ta',
						3 => 'Fọ́t Kwọ́ta'
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
					'am' => q{AM},
					'pm' => q{PM},
				},
				'narrow' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'wide' => {
					'am' => q{Fọ mọ́nin},
					'pm' => q{Fọ ívnin},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'narrow' => {
					'am' => q{AM},
					'pm' => q{PM},
				},
				'wide' => {
					'am' => q{Fọ mọ́nin},
					'pm' => q{Fọ ívnin},
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
				'0' => 'BK',
				'1' => 'KIY'
			},
			wide => {
				'0' => 'Bifọ́ Kraist',
				'1' => 'Kraist Im Yiẹ'
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
			'full' => q{HH:mm:ss zzzz},
			'long' => q{H:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			'full' => q{{1} 'fọ' {0}},
			'long' => q{{1} 'fọ' {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1} 'fọ' {0}},
			'long' => q{{1} 'fọ' {0}},
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
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d, E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, M/d},
			MMM => q{LLL},
			MMMEd => q{E, MMM d},
			MMMMd => q{MMMM d},
			MMMd => q{MMM d},
			Md => q{M/d},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{GGGGG y-MM},
			yyyyMEd => q{GGGGG y-MM-dd, E},
			yyyyMMM => q{G y MMM},
			yyyyMMMEd => q{G y MMM d, E},
			yyyyMMMM => q{G y MMMM},
			yyyyMMMd => q{G y MMM d},
			yyyyMd => q{GGGGG y-MM-dd},
			yyyyQQQ => q{G y QQQ},
			yyyyQQQQ => q{G y QQQQ},
		},
		'gregorian' => {
			Bh => q{h B},
			Bhm => q{h:mm B},
			Bhms => q{h:mm:ss B},
			E => q{ccc},
			EBhm => q{E h:mm B},
			EBhms => q{E h:mm:ss B},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{G y MMM},
			GyMMMEd => q{G y MMM d, E},
			GyMMMd => q{G y MMM d},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{E, d/M},
			MMM => q{LLL},
			MMMEd => q{E, d MMM},
			MMMMW => q{'Wik' W 'fọ' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d /M},
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
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'Wiik' w 'fọ' Y},
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
				h => q{h–h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
			Gy => {
				G => q{G y – G y},
				y => q{G y–y},
			},
			GyM => {
				G => q{GGGGG y-MM – GGGGG y-MM},
				M => q{GGGGG y-MM – y-MM},
				y => q{GGGGG y-MM – y-MM},
			},
			GyMEd => {
				G => q{GGGGG y-MM-dd, E – GGGGG y-MM-dd, E},
				M => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				d => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				y => q{GGGGG y-MM-dd, E – y-MM-dd, E},
			},
			GyMMM => {
				G => q{G y MMM – G y MMM},
				M => q{G y MMM–MMM},
				y => q{G y MMM – y MMM},
			},
			GyMMMEd => {
				G => q{G y MMM d, E – G y MMM d, E},
				M => q{G y MMM d, E – MMM d, E},
				d => q{G y MMM d, E – MMM d, E},
				y => q{G y MMM d, E – y MMM d, E},
			},
			GyMMMd => {
				G => q{G y MMM d – G y MMM d},
				M => q{G y MMM d – MMM d},
				d => q{G y MMM d–d},
				y => q{G y MMM d – y MMM d},
			},
			GyMd => {
				G => q{GGGGG y-MM-dd – GGGGG y-MM-dd},
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
			M => {
				M => q{MM–MM},
			},
			MEd => {
				M => q{MM-dd, E – MM-dd, E},
				d => q{MM-dd, E – MM-dd, E},
			},
			MMM => {
				M => q{LLL–LLL},
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
				M => q{MM-dd – MM-dd},
				d => q{MM-dd – MM-dd},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			y => {
				y => q{G y–y},
			},
			yM => {
				M => q{GGGGG y-MM – y-MM},
				y => q{GGGGG y-MM – y-MM},
			},
			yMEd => {
				M => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				d => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				y => q{GGGGG y-MM-dd, E – y-MM-dd, E},
			},
			yMMM => {
				M => q{G y MMM–MMM},
				y => q{G y MMM – y MMM},
			},
			yMMMEd => {
				M => q{G y MMM d, E – MMM d, E},
				d => q{G y MMM d, E – MMM d, E},
				y => q{G y MMM d, E – y MMM d, E},
			},
			yMMMM => {
				M => q{G y MMMM–MMMM},
				y => q{G y MMMM – y MMMM},
			},
			yMMMd => {
				M => q{G y MMM d – MMM d},
				d => q{G y MMM d–d},
				y => q{G y MMM d – y MMM d},
			},
			yMd => {
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
			},
		},
		'gregorian' => {
			Bh => {
				B => q{h B – h B},
				h => q{h–h B},
			},
			Bhm => {
				B => q{h:mm B – h:mm B},
				h => q{h:mm–h:mm B},
				m => q{h:mm–h:mm B},
			},
			Gy => {
				G => q{Gy – Gy},
				y => q{G y–y},
			},
			GyM => {
				G => q{GGGGG y-MM – GGGGG y-MM},
				M => q{GGGGG y-MM – y-MM},
				y => q{GGGGG y-MM – y-MM},
			},
			GyMEd => {
				G => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				M => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				d => q{GGGGG y-MM-dd, E – y-MM-dd, E},
				y => q{GGGGG y-MM-dd, E – y-MM-dd, E},
			},
			GyMMM => {
				G => q{G y MMM – G y MMM},
				M => q{G y MMM–MMM},
				y => q{G y MMM – y MMM},
			},
			GyMMMEd => {
				G => q{G y MMM d, E – G y MMM},
				M => q{G y MMM d, E – MMM d, E},
				d => q{G y MMM d, E – MMM d, E},
				y => q{G y MMM d, E – y MMM d, E},
			},
			GyMMMd => {
				G => q{G y MMM d – G y MMM d},
				M => q{G y MMM d – MMM d},
				d => q{G y MMM d–d},
				y => q{G y MMM d – y MMM d},
			},
			GyMd => {
				G => q{GGGGG y-MM-dd – GGGGG y-MM-dd},
				M => q{GGGGG y-MM-dd – y-MM-dd},
				d => q{GGGGG y-MM-dd – y-MM-dd},
				y => q{GGGGG y-MM-dd – y-MM-dd},
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
				M => q{MM–MM},
			},
			MEd => {
				M => q{E, dd-MM – E, dd/MM},
				d => q{E, dd/MM – E, dd/MM},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{E, d MMM – E, d MMM},
				d => q{E, d MMM – E, d MMM},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd/MM – dd/MM},
				d => q{dd/MM – dd/MM},
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
				M => q{MM/y – MM/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E, dd/MM/y – E, dd/MM/y},
				d => q{E, dd/MM/y – E, dd/MM/y},
				y => q{E, dd/MM/y – E, dd/MM/y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d MMM y – E, d MMM y},
				d => q{E, d MMM y – E, d MMM y},
				y => q{E, d MMM y – E, d MMM y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM – d MMM y},
				d => q{d – d MMM y},
				y => q{d MMM y – d MMM y},
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
		regionFormat => q({0} Taim),
		regionFormat => q({0} Délaít Taim),
		regionFormat => q({0} Fíksd Taim),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q#Afgánístan Taim#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Ábijan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akrá#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Adí Abába#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Aljíẹz#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmára#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamáko#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bangúi#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Banjul#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bisau#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantáya#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brázavil#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Bujumbúra#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kaíro#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kasablánka#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Sẹúta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Kọnákri#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakár#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar ẹ́s Salam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Jibúti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Duála#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Ẹl Aiun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Frítaun#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Háborónẹ#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Harárẹ#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Johánísbọg#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Júba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampála#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Kartum#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kigáli#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinshásha#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Légos#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Líbrẹvil#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lómẹ#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luánda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbáshi#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#Lusáka#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#Malábo#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#Mapúto#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#Masẹ́ru#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#Mbabánẹ#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mọgádíshu#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monróvia#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Naíróbi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Njamẹ́na#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niáme#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nouákshọt#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Ouagadúgu#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Pọto-Nóvo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sao Tómẹ#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Trípọ́li#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Túnis#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Wíndhok#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Mídúl Áfríká Taim#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Íst Áfríká Taim#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Saút Áfríká Fíksd Taim#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Wẹ́st Áfríká Họ́t Sízin Taim#,
				'generic' => q#Wẹ́st Áfríká Taim#,
				'standard' => q#Wẹ́st Áfríká Fíksd Taim#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Aláská Délaít Taim#,
				'generic' => q#Aláská Taim#,
				'standard' => q#Aláská Fíksd Taim#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Ámázọn Họ́t Sízín Taim#,
				'generic' => q#Ámázọn Taim#,
				'standard' => q#Ámázọn Fíksd Taim#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#Ádak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Ánkọ́rej#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Angwíla#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antígwua#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Aragwuaína#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Riókha#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rió Galẹ́gọs#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Sálta#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San Hwan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#San Luis#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Túkúman#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Usuáya#,
		},
		'America/Aruba' => {
			exemplarCity => q#Arúba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunsiọn#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahía#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahía Bandẹ́ras#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbédọs#,
		},
		'America/Belem' => {
			exemplarCity => q#Bẹlẹm#,
		},
		'America/Belize' => {
			exemplarCity => q#Bẹliz#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blank-Sáblọn#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Bóa Vísta#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogota#,
		},
		'America/Boise' => {
			exemplarCity => q#Bọísi#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buẹnos Aírẹs#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Kémbríj Bè#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Kampó Grándẹ#,
		},
		'America/Cancun' => {
			exemplarCity => q#Kankun#,
		},
		'America/Caracas' => {
			exemplarCity => q#Karákas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Katamáka#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Kayẹn#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kéman#,
		},
		'America/Chicago' => {
			exemplarCity => q#Chikágo#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Chiwuáwua#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atíkókan#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kórdoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kósta Ríka#,
		},
		'America/Creston' => {
			exemplarCity => q#Krẹ́stọn#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Kúyábaa#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kiurásao#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Danmákshávun#,
		},
		'America/Dawson' => {
			exemplarCity => q#Dọ́sọn#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Dọ́sọn Krik#,
		},
		'America/Denver' => {
			exemplarCity => q#Dẹ́nva#,
		},
		'America/Detroit' => {
			exemplarCity => q#Ditrọit#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dọmíníka#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Ẹ́dmọ́ntọn#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Ẹirunẹpẹ#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#El Sálvádọ#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#Fọt Nẹ́lson#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fọtalẹ́za#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Glás Bè#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuuk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Gúz Bè#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Gránd Tọk#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grẹnéda#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadalúpẹ#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guátẹmála#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guáyakil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Gayána#,
		},
		'America/Halifax' => {
			exemplarCity => q#Hálífaks#,
		},
		'America/Havana' => {
			exemplarCity => q#Havána#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Hẹ́mósílo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Nọks, Indiána#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marẹ́ngo, Indiána#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Pításbọg, Indiána#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tẹ́l Síti, Indiána#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vẹ́ve, Indiána#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vínsẹn, Indiána#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Wínámak, Indiána#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indiánápọ́lis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inúvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Ikáluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamaíka#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Huhui#,
		},
		'America/Juneau' => {
			exemplarCity => q#Júno#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Mọntẹchẹ́lo, Kẹ́ntọ́ki#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Králẹ́ndijk#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La Paz#,
		},
		'America/Lima' => {
			exemplarCity => q#Líma#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Lọs Ánjẹ́lis#,
		},
		'America/Louisville' => {
			exemplarCity => q#Luívil#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lówá Príns Im Kwọ́ta#,
		},
		'America/Maceio' => {
			exemplarCity => q#Masẹ́io#,
		},
		'America/Managua' => {
			exemplarCity => q#Manágua#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manáus#,
		},
		'America/Marigot' => {
			exemplarCity => q#Márígọt#,
		},
		'America/Martinique' => {
			exemplarCity => q#Matínik#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Mátamóros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazátlan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mẹndóza#,
		},
		'America/Menominee' => {
			exemplarCity => q#Mẹnọ́minii#,
		},
		'America/Merida' => {
			exemplarCity => q#Mẹ́rída#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Mẹtlakátla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mẹ́ksíkó Síti#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Míkẹlọn#,
		},
		'America/Moncton' => {
			exemplarCity => q#Mọ́nktọn#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Mọntẹrẹẹ#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Mọntẹvidẹo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Mọntsẹrat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nássọu#,
		},
		'America/New_York' => {
			exemplarCity => q#Niú Yọk#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nípígọn#,
		},
		'America/Nome' => {
			exemplarCity => q#Noom#,
		},
		'America/Noronha' => {
			exemplarCity => q#Nọrónia#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Biúla, Nọ́t Dakóta#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Sẹ́nta, Nọ́t Dakóta#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Niú Sélẹm, Nọ́t Dakóta#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Okhinága#,
		},
		'America/Panama' => {
			exemplarCity => q#Pánáma#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Pangnírtung#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Párámaribo#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Fíniks#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Pọt-o-Prins#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Pọ́t ọf Spen#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Pọto Vẹ́lho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puẹ́rto Ríkọ#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#Púntá Arẹ́nas#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Réní Ríva#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Ránkín Ínlẹt#,
		},
		'America/Recife' => {
			exemplarCity => q#Rẹsífẹ#,
		},
		'America/Regina' => {
			exemplarCity => q#Rẹjína#,
		},
		'America/Resolute' => {
			exemplarCity => q#Rẹ́zólut#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Rió Bránko#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarẹm#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiágo#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Sántó Domíngo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#Sao Paúlo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Itókotúrmit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Sent Batẹlẹ́mi#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Sent Jọn#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Sent Kits#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Sent Lúshia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Sent Tọmọs#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Sent Vínsẹnt#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Swíft Kọ́rẹnt#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tẹgúsigálpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Túli#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Tọ́nda Bè#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tikhuána#,
		},
		'America/Toronto' => {
			exemplarCity => q#Torónto#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tọtóla#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vankúva#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Waíthọs#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Wínípẹg#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Yakútat#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Yẹ́lónaif#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Nọ́t Amẹ́ríká Mídúl Ériá Délaít Taim#,
				'generic' => q#Nọ́t Amẹ́ríká Mídúl Ériá Taim#,
				'standard' => q#Nọ́t Amẹ́ríká Mídúl Ériá Fíksd Taim#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Nọ́t Amẹ́ríká Ístán Ériá Délaít Taim#,
				'generic' => q#Nọ́t Amẹ́ríká Ístán Ériá Taim#,
				'standard' => q#Nọ́t Amẹ́ríká Ístán Ériá Fíksd Taim#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Nọ́t Amẹ́ríká Maúntin Ériá Délaít Taim#,
				'generic' => q#Nọ́t Amẹ́ríká Maúntin Ériá Taim#,
				'standard' => q#Nọ́t Amẹ́ríká Maúntin Ériá Fíksd Taim#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Nọ́t Amẹ́ríká Pasífík Ériá Délaít Taim#,
				'generic' => q#Nọ́t Amẹ́ríká Pasífík Ériá Taim#,
				'standard' => q#Nọ́t Amẹ́ríká Pasífík Ériá Fíksd Taim#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Kési#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Dévis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Diúmọ́n-d’Uvil#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Makwuéí#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mọ́sọn#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#McMọ́do#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Páma#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rotẹ́ra#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Siówa#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Trol#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Vọ́stọk#,
		},
		'Apia' => {
			long => {
				'daylight' => q#Ápia Délaít Taim#,
				'generic' => q#Ápia Taim#,
				'standard' => q#Ápia Fíksd Taim#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arébiá Délaít Taim#,
				'generic' => q#Arébiá Taim#,
				'standard' => q#Arébiá Fíksd Taim#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Lọngyẹ́abiẹn#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#Ajẹntína Họ́t Sízín Taim#,
				'generic' => q#Ajẹntína Taim#,
				'standard' => q#Ajẹntína Fíksd Taim#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Wẹ́stán Ajẹntína Họ́t Sízín Taim#,
				'generic' => q#Wẹ́stán Ajẹntína Taim#,
				'standard' => q#Wẹ́stán Ajẹntína Fíksd Taim#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armẹ́nia Họ́t Sízin Taim#,
				'generic' => q#Armẹ́nia Taim#,
				'standard' => q#Armẹ́nia Fíksd Taim#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Édẹn#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Álmáti#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Aman#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Ánadiar#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktáu#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktóbẹ#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Áshgabat#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#Átírau#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bágdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrén#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Baku#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bánkọk#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#Bárnául#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Bẹrut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bishkẹk#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunẹi#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kolkáta#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Chítá#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Choibálsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolómbo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damáskọs#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dáka#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Díli#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubai#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dushánbẹ#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#Fagústa#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gáza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hẹ́brọn#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Họng Kọng#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkútsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakáta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapúra#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jẹrúsálẹm#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamchátké#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karáchi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmándu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Kandíga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoyask#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuála Lúmpọ#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuching#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuwet#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makáo#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Mágádan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makása#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Maníla#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Múskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosia#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuznẹ́sk#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Novosibisk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Ọmsk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Ọ́ral#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Fnọ́m Pẹn#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pọntiának#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Piọngyang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Káta#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostánai#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kízilọ́da#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Yangọn#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyád#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Hó Chi Mín Síti#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sákhalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Sámákand#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Sol#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Shánghai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapọ#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srẹ́dnẹkolimsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipẹi#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Táshkẹnt#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tiblísi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Tẹran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Tímfu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tókyo#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#Tomsk#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulanbáta#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Yurọ́mki#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Nẹ́ra#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Viẹ́ntiẹn#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivọstọk#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yékútsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Yẹketẹrínbug#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yẹrẹ́van#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlántík Délaít Taim#,
				'generic' => q#Atlántík Taim#,
				'standard' => q#Atlántík Fíksd Taim#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azọz#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bẹmiúda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kenerí#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kép Vẹd#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Fáróis#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madíra#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Rẹ́kjávik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Saút Jọ́jia#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Sent Hẹlẹ́na#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stánli#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adleid#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brísben#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Brókún Hil#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Kọ́ri#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Dárwin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Yúkla#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hóbat#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Líndẹman#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lọd Haú#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Mẹ́lbọn#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Pẹrt#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sídni#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Ọstrélia Mídúl Délaít Taim#,
				'generic' => q#Mídúl Ọstrélia Taim#,
				'standard' => q#Ọstrélia Mídúl Fíksd Taim#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Ọstrélia Mídúl Wẹ́stán Délaít Taim#,
				'generic' => q#Ọstrélia Mídúl Wẹ́stán Taim#,
				'standard' => q#Ọstrélia Mídúl Wẹ́stán Fíksd Taim#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Ọstrélia Ístán Délaít Taim#,
				'generic' => q#Ístán Ọstrélia Taim#,
				'standard' => q#Ọstrélia Ístán Fíksd Taim#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Ọstrélia Wẹ́stán Délaít Taim#,
				'generic' => q#Wẹ́stán Ọstrélia Taim#,
				'standard' => q#Ọstrélia Wẹ́stán Fíksd Taim#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Azẹrbaijan Họ́t Sízin Taim#,
				'generic' => q#Azẹrbaijan Taim#,
				'standard' => q#Azẹrbaijan Fíksd Taim#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azọz Họ́t Sízin Taim#,
				'generic' => q#Azọz Taim#,
				'standard' => q#Azọz Fíksd Taim#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladẹsh Délaít Taim#,
				'generic' => q#Bangladẹsh Taim#,
				'standard' => q#Bangladẹsh Fíksd Taim#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Butan Taim#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolívia Fíksd Taim#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasília Họ́t Sízín Taim#,
				'generic' => q#Brasília Taim#,
				'standard' => q#Brasília Fíksd Taim#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunẹi Darúsalam Taim#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kep Vẹ́d Họ́t Sízin Taim#,
				'generic' => q#Kep Vẹ́d Taim#,
				'standard' => q#Kep Vẹ́d Fíksd Taim#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamóro Fíksd Taim#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chátam Délaít Taim#,
				'generic' => q#Chátam Taim#,
				'standard' => q#Chátam Fíksd Taim#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Chílẹ Họ́t Sízín Taim#,
				'generic' => q#Chílẹ Taim#,
				'standard' => q#Chílẹ Fíksd Taim#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Chaína Délaít Taim#,
				'generic' => q#Chaína Taim#,
				'standard' => q#Chaína Fíksd Taim#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Choibálsan Họ́t Sízin Taim#,
				'generic' => q#Choibálsan Taim#,
				'standard' => q#Choibálsan Fíksd Taim#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Krísmás Aíland Taim#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Kókós Aílands Taim#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolómbia Họ́t Sízín Taim#,
				'generic' => q#Kolómbia Taim#,
				'standard' => q#Kolómbia Fíksd Taim#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Kúk Aílands Haf Họ́t Sízin Taim#,
				'generic' => q#Kúk Aílands Taim#,
				'standard' => q#Kúk Aílands Fíksd Taim#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kúba Délaít Taim#,
				'generic' => q#Kúba Taim#,
				'standard' => q#Kúba Fíksd Taim#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Dévis Taim#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Diúmọ́n-d’Uvil Taim#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Íst Tímọ Taim#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Ísta Họ́t Sízín Taim#,
				'generic' => q#Ísta Taim#,
				'standard' => q#Ísta Fíksd Taim#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ẹ́kwuádọ Taim#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#Arénjmẹnt ọf Di Hól Wọld Taim#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Taun wé Pẹ́sin Nọ́ No#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Ámstádam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andọ́ra#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Ástrahán#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Átẹns#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Bẹ́lgréd#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Bẹlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratísláva#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brúsuls#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Búkárẹst#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Búdápẹst#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busíngẹn#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Chisináu#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kọpẹnhágẹn#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dọ́blin#,
			long => {
				'daylight' => q#Aírísh Fíksd Taim#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Jibrọ́lta#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guẹnzi#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Hẹlsínki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Aíl ọf Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Ístánbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jẹ́si#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kalíníngrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiẹv#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#Kirọv#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lísbọn#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Lubliána#,
		},
		'Europe/London' => {
			exemplarCity => q#Lọ́ndọn#,
			long => {
				'daylight' => q#Brítísh Họ́t Sízin Taim#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lọ́ksẹ́mbọg#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrid#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Mọ́lta#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Maríahámn#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Mọ́náko#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Mọ́sko#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Ọ́slo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Páris#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Pọ́jóríka#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prag#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Ríga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rom#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samára#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Maríno#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarayẹ́vo#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#Sárátov#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Símfẹrópol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skọ́pyẹ#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofía#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stọ́khọm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tálin#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tiránẹ#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uliánọvsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Ọ́zhọrọd#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vátíkan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viẹ́na#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vílnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volvógrad#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Wọ́sọ#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zágrẹb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporózhia#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zúrik#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Mídúl Yúrop Họ́t Sízin Taim#,
				'generic' => q#Mídúl Yúrop Taim#,
				'standard' => q#Mídúl Yúrop Fíksd Taim#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Ístán Yúrop Họ́t Sízin Taim#,
				'generic' => q#Ístán Yúrop Taim#,
				'standard' => q#Ístán Yúrop Fíksd Taim#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#Faá-Ístán Yúrop Taim#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Wẹ́stán Yúrop Họ́t Sízin Taim#,
				'generic' => q#Wẹ́stán Yúrop Taim#,
				'standard' => q#Wẹ́stán Yúrop Fíksd Taim#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Fọ́lkland Họ́t Sízín Taim#,
				'generic' => q#Fọ́lkland Taim#,
				'standard' => q#Fọ́lkland Fíksd Taim#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fíji Họ́t Sízín Taim#,
				'generic' => q#Fíji Taim#,
				'standard' => q#Fíji Fíksd Taim#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Frẹ́nch Giána Taim#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Frẹ́nch Saútan an Antátík Taim#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Grínwích Mín Taim#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galápágọs Taim#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gámbiẹr Taim#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Jọ́jia Họ́t Sízin Taim#,
				'generic' => q#Jọ́jia Taim#,
				'standard' => q#Jọ́jia Fíksd Taim#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gílbat Aílands Taim#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Íist Grínlánd Họ́t Sízin Taim#,
				'generic' => q#Íist Grínlánd Taim#,
				'standard' => q#Íist Grínlánd Fíksd Taim#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Wẹ́st Grínlánd Họ́t Sízin Taim#,
				'generic' => q#Wẹ́st Grínlánd Taim#,
				'standard' => q#Wẹ́st Grínlánd Fíksd Taim#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Gọ́lf Fíksd Taim#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Gayána Taim#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaií-Elúshián Délaít Taim#,
				'generic' => q#Hawaií-Elúshián Taim#,
				'standard' => q#Hawaií-Elúshián Fíksd Taim#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Họng Kọng Họ́t Sízin Taim#,
				'generic' => q#Họng Kọng Taim#,
				'standard' => q#Họng Kọng Fíksd Taim#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovd Họ́t Sízin Taim#,
				'generic' => q#Hovd Taim#,
				'standard' => q#Hovd Fíksd Taim#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Índia Fíksd Taim#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antánánarívo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chágọs#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Krísmas#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kókos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Kọ́mọ́ros#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kẹ́rgúlẹn#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahẹ́#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Mọ́ldivs#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mọríshọs#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Meyọt#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Riyúniọn#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Índián Óshẹ́n Taim#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indochaína Taim#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Mídúl Indonẹ́shia Taim#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Ístán Indonẹ́shia Taim#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Wẹ́stán Indonẹ́shia Taim#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iran Délaít Taim#,
				'generic' => q#Iran Taim#,
				'standard' => q#Iran Fíksd Taim#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkútsk Họ́t Sízin Taim#,
				'generic' => q#Irkútsk Taim#,
				'standard' => q#Irkútsk Fíksd Taim#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Ízrẹl Délaít Taim#,
				'generic' => q#Ízrẹl Taim#,
				'standard' => q#Ízrẹl Fíksd Taim#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japan Délaít Taim#,
				'generic' => q#Japan Taim#,
				'standard' => q#Japan Fíksd Taim#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Íst Kazékstan Taim#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Wẹ́st Kazékstan Taim#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Koria Délaít Taim#,
				'generic' => q#Koria Taim#,
				'standard' => q#Koria Fíksd Taim#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kọ́sraẹ Taim#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnoyask Họ́t Sízin Taim#,
				'generic' => q#Krasnoyask Taim#,
				'standard' => q#Krasnoyask Fíksd Taim#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kẹgistan Taim#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Laín Aílands Taim#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lọd Haú Délaít Taim#,
				'generic' => q#Lọd Haú Taim#,
				'standard' => q#Lọd Haú Fíksd Taim#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Makwuéí Aíland Taim#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Mágádan Họ́t Sízin Taim#,
				'generic' => q#Mágádan Taim#,
				'standard' => q#Mágádan Fíksd Taim#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Maléshia Taim#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Mọ́divs Taim#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Makwẹ́sas Taim#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Máshal Aílands Taim#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mọríshọs Họ́t Sízin Taim#,
				'generic' => q#Mọríshọs Taim#,
				'standard' => q#Mọríshọs Fíksd Taim#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mọ́sọn Taim#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Nọ́twẹ́st Mẹ́ksíko Délaít Taim#,
				'generic' => q#Nọ́twẹ́st Mẹ́ksíko Taim#,
				'standard' => q#Nọ́twẹ́st Mẹ́ksíko Fíksd Taim#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Mẹ́ksíkó Pasífík Délaít Taim#,
				'generic' => q#Mẹ́ksíkó Pasífík Taim#,
				'standard' => q#Mẹ́ksíkó Pasífík Fíksd Taim#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Mọngólia Họ́t Sízin Taim#,
				'generic' => q#Mọngólia Taim#,
				'standard' => q#Mọngólia Fíksd Taim#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Mọ́sko Họ́t Sízin Taim#,
				'generic' => q#Mọ́sko Taim#,
				'standard' => q#Mọ́sko Fíksd Taim#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Miánma Taim#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Naúru Taim#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nẹpọl Taim#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Niú Kalẹdónia Họ́t Sízin Taim#,
				'generic' => q#Niú Kalẹdónia Taim#,
				'standard' => q#Niú Kalẹdónia Fíksd Taim#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Niú Ziland Délaít Taim#,
				'generic' => q#Niú Ziland Taim#,
				'standard' => q#Niú Ziland Fíksd Taim#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Niúfaúndlánd Délaít Taim#,
				'generic' => q#Niúfaúndlánd Taim#,
				'standard' => q#Niúfaúndlánd Fíksd Taim#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niúẹ Taim#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#Nọ́rfọ́lk Aíland Délaít Taim#,
				'generic' => q#Nọ́rfọ́lk Aíland Taim#,
				'standard' => q#Nọ́rfọ́lk Aíland Fíksd Taim#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fẹrnándó di Nọrónia Họ́t Sízín Taim#,
				'generic' => q#Fẹrnándó di Nọrónia Taim#,
				'standard' => q#Fẹrnándó di Nọrónia Fíksd Taim#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Novosibisk Họ́t Sízin Taim#,
				'generic' => q#Novosibisk Taim#,
				'standard' => q#Novosibisk Fíksd Taim#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Ọmsk Họ́t Sízin Taim#,
				'generic' => q#Ọmsk Taim#,
				'standard' => q#Ọmsk Fíksd Taim#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Ápia#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Ọ́kland#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Bugenvília#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Chátam#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Ísta#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Ẹfátẹ#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Ẹ́ndábẹ́ri#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Fakáófo#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fíji#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafúti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galápágọs#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gámbiẹr#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guádálkanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guam#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Jọ́nstun#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kritímáti#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kọ́sraẹ#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kwájalẹn#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Majúro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Makwẹ́sas#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Mídwè#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Naúru#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Niú#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Nọ́rfọ́lk#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Númẹ́a#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Págo Págo#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Paláu#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pítkan#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Pọnpẹ́i#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Pọt Mọrẹ́sbi#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Raratónga#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saipan#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahíti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Taráwa#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tongatápu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Chuk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Wek#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Wáli#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pákístan Họ́t Sízin Taim#,
				'generic' => q#Pákístan Taim#,
				'standard' => q#Pákístan Fíksd Taim#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Paláu Taim#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Pápuá Niú Gíni Taim#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Párágwue Họ́t Sízín Taim#,
				'generic' => q#Párágwue Taim#,
				'standard' => q#Párágwue Fíksd Taim#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Pẹru Họ́t Sízín Taim#,
				'generic' => q#Pẹru Taim#,
				'standard' => q#Pẹru Fíksd Taim#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Fílípin Họt Sízin Taim#,
				'generic' => q#Fílípin Taim#,
				'standard' => q#Fílípin Fíksd Taim#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Fíniks Aílands Taim#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Sent Piẹr an Míkẹlọn Délaít Taim#,
				'generic' => q#Sent Piẹr & Míkẹlọn Taim#,
				'standard' => q#Sent Piẹr an Míkẹlọn Fíksd Taim#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pítkan Taim#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Pónápẹ Taim#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#Piọngyang Taim#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Riyúniọn Taim#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rotẹ́ra Taim#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sákhalin Họ́t Sízin Taim#,
				'generic' => q#Sákhalin Taim#,
				'standard' => q#Sákhalin Fíksd Taim#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Sámoá Délaít Taim#,
				'generic' => q#Sámoá Taim#,
				'standard' => q#Sámoá Fíksd Taim#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Sẹ́chẹls Taim#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapọ Taim#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Sólómọ́n Aílands Taim#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Saút Jọ́jia Taim#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Súrínam Taim#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Siówa Taim#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahíti Taim#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipẹi Délaít Taim#,
				'generic' => q#Taipẹi Taim#,
				'standard' => q#Taipẹi Fíksd Taim#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tajíkistan Taim#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokẹláu Taim#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tọ́nga Họ́t Sízin Taim#,
				'generic' => q#Tọ́nga Taim#,
				'standard' => q#Tọ́nga Fíksd Taim#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuk Taim#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Tọkmẹnistan Họ́t Sízin Taim#,
				'generic' => q#Tọkmẹnistan Taim#,
				'standard' => q#Tọkmẹnistan Fíksd Taim#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuválu Taim#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Yúrugwue Họ́t Sízín Taim#,
				'generic' => q#Yúrugwue Taim#,
				'standard' => q#Yúrugwue Fíksd Taim#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Uzbẹkistan Họ́t Sízin Taim#,
				'generic' => q#Uzbẹkistan Taim#,
				'standard' => q#Uzbẹkistan Fíksd Taim#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuátu Sízin Taim#,
				'generic' => q#Vanuátu Taim#,
				'standard' => q#Vanuátu Fíksd Taim#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Vẹnẹzuẹ́la Taim#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Vladivostok Họ́t Sízin Taim#,
				'generic' => q#Vladivọstọk Taim#,
				'standard' => q#Vladivọstọk Fíksd Taim#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Volvógrad Họ́t Sízin Taim#,
				'generic' => q#Volvógrad Taim#,
				'standard' => q#Volvógrad Fíksd Taim#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Vọ́stọk Taim#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wék Aíland Taim#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wális an Fútúna Taim#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Yékútsk Họ́t Sízin Taim#,
				'generic' => q#Yékútsk Taim#,
				'standard' => q#Yékútsk Fíksd Taim#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Yẹketẹrínbug Họ́t Sízin Taim#,
				'generic' => q#Yẹketẹrínbug Taim#,
				'standard' => q#Yẹketẹrínbug Fíksd Taim#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#Yukón Taim#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
