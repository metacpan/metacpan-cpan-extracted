=encoding utf8

=head1 NAME

Locale::CLDR::Locales::To - Package for language Tongan

=cut

package Locale::CLDR::Locales::To;
# This file auto generated from Data\common\main\to.xml
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
				'aa' => 'lea fakaʻafāla',
 				'ab' => 'lea fakaʻapakasia',
 				'ace' => 'lea fakaʻatisē',
 				'ach' => 'lea fakaʻakoli',
 				'ada' => 'lea fakaʻatangimē',
 				'ady' => 'lea fakaʻatikē',
 				'ae' => 'lea fakaʻavesitani',
 				'aeb' => 'lea fakaʻalepea-tunīsia',
 				'af' => 'lea fakaʻafilikana',
 				'afh' => 'lea fakaʻafilihili',
 				'agq' => 'lea fakaʻakihemi',
 				'ain' => 'lea fakaʻainu',
 				'ak' => 'lea fakaʻakani',
 				'akk' => 'lea fakaʻakatia',
 				'akz' => 'lea fakaʻalapama',
 				'ale' => 'lea fakaʻaleuti',
 				'aln' => 'lea fakaʻalapēnia-keki',
 				'alt' => 'lea fakaʻalitai-tonga',
 				'am' => 'lea fakaʻameliki',
 				'an' => 'lea fakaʻalakoni',
 				'ang' => 'lea fakapālangi-motuʻa',
 				'ann' => 'lea fakaʻopolo',
 				'anp' => 'lea fakaʻangika',
 				'apc' => 'lea fakaʻalepea-levaniti',
 				'ar' => 'lea fakaʻalepea',
 				'ar_001' => 'lea fakaʻalepea (māmani)',
 				'arc' => 'lea fakaʻalāmiti',
 				'arn' => 'lea fakamapuse',
 				'aro' => 'lea fakaʻalaona',
 				'arp' => 'lea fakaʻalapaho',
 				'arq' => 'lea fakaʻalepea-ʻaisilia',
 				'ars' => 'lea fakaʻalepea-nāsiti',
 				'arw' => 'lea fakaʻalauaki',
 				'ary' => 'lea fakaʻalepea-moloko',
 				'arz' => 'lea fakaʻalepea-ʻisipite',
 				'as' => 'lea fakaʻasamia',
 				'asa' => 'lea fakaʻasu',
 				'ase' => 'lea fakaʻilonga-ʻamelika',
 				'ast' => 'lea fakaʻasitūlia',
 				'atj' => 'lea fakaʻatikameku',
 				'av' => 'lea fakaʻavaliki',
 				'avk' => 'lea fakakotava',
 				'awa' => 'lea fakaʻauati',
 				'ay' => 'lea fakaʻaimala',
 				'az' => 'lea fakaʻasepaisani',
 				'az@alt=short' => 'lea fakaʻaseli',
 				'ba' => 'lea fakapasikili',
 				'bal' => 'lea fakapalusi',
 				'ban' => 'lea fakapali',
 				'bar' => 'lea fakapavālia',
 				'bas' => 'lea fakapasaʻa',
 				'bax' => 'lea fakapamuni',
 				'bbc' => 'lea fakatōpe-pēteki',
 				'bbj' => 'lea fakakomala',
 				'be' => 'lea fakapelalusi',
 				'bej' => 'lea fakapesa',
 				'bem' => 'lea fakapēmipa',
 				'bew' => 'lea fakapetavi',
 				'bez' => 'lea fakapena',
 				'bfd' => 'lea fakapafuti',
 				'bfq' => 'lea fakapataka',
 				'bg' => 'lea fakapulukalia',
 				'bgc' => 'lea fakahalaiānivi',
 				'bgn' => 'lea fakapalusi-hihifo',
 				'bho' => 'lea fakaposipuli',
 				'bi' => 'lea fakapisilama',
 				'bik' => 'lea fakapikoli',
 				'bin' => 'lea fakapini',
 				'bjn' => 'lea fakapanisali',
 				'bkm' => 'lea fakakome',
 				'bla' => 'lea fakasikesikā',
 				'bm' => 'lea fakapamipala',
 				'bn' => 'lea fakapāngilā',
 				'bo' => 'lea fakatipeti',
 				'bpy' => 'lea fakapisinupilia',
 				'bqi' => 'lea fakapakitiāli',
 				'br' => 'lea fakapeletoni',
 				'bra' => 'lea fakapalai',
 				'brh' => 'lea fakapalahui',
 				'brx' => 'lea fakapōto',
 				'bs' => 'lea fakaposinia',
 				'bss' => 'lea fakaʻakōse',
 				'bua' => 'lea fakapuliati',
 				'bug' => 'lea fakapukisi',
 				'bum' => 'lea fakapulu',
 				'byn' => 'lea fakapilini',
 				'byv' => 'lea fakametūmipa',
 				'ca' => 'lea fakakatalani',
 				'cad' => 'lea fakakato',
 				'car' => 'lea fakakalipa',
 				'cay' => 'lea fakakaiuka',
 				'cch' => 'lea fakaʻatisami',
 				'ccp' => 'lea fakasākima',
 				'ce' => 'lea fakasese',
 				'ceb' => 'lea fakasepuano',
 				'cgg' => 'lea fakakika',
 				'ch' => 'lea fakakamolo',
 				'chb' => 'lea fakasīpisa',
 				'chg' => 'lea fakasakatāi',
 				'chk' => 'lea fakatūke',
 				'chm' => 'lea fakamalī',
 				'chn' => 'lea fakasinuki-takote',
 				'cho' => 'lea fakasokitau',
 				'chp' => 'lea fakasipeuiani',
 				'chr' => 'lea fakaselokī',
 				'chy' => 'lea fakaseiene',
 				'ckb' => 'lea fakakūtisi-loloto',
 				'ckb@alt=variant' => 'lea fakakūtisi-solani',
 				'clc' => 'lea fakatisilikōtini',
 				'co' => 'lea fakakōsika',
 				'cop' => 'lea fakakopitika',
 				'cps' => 'lea fakakapiseno',
 				'cr' => 'lea fakakelī',
 				'crg' => 'lea fakametisifi',
 				'crh' => 'lea fakatatali-kilimea',
 				'crj' => 'lea fakakilī-tongahahake',
 				'crk' => 'lea fakakilī-toafa',
 				'crl' => 'lea fakakilī-tokelauhahake',
 				'crm' => 'lea fakamose-kilī',
 				'crr' => 'lea fakaʻalakonikuia-kalolina',
 				'crs' => 'lea fakaseselua-falanisē',
 				'cs' => 'lea fakaseki',
 				'csb' => 'lea fakakasiupia',
 				'csw' => 'lea fakakilī-ano',
 				'cu' => 'lea fakasilavia-fakasiasi',
 				'cv' => 'lea fakasuvasa',
 				'cy' => 'lea fakauēlesi',
 				'da' => 'lea fakatenimaʻake',
 				'dak' => 'lea fakatakota',
 				'dar' => 'lea fakatalakuā',
 				'dav' => 'lea fakataita',
 				'de' => 'lea fakasiamane',
 				'de_AT' => 'lea fakasiamane-ʻaositulia',
 				'de_CH' => 'lea fakasiamane-hake-suisilani',
 				'del' => 'lea fakatelauale',
 				'den' => 'lea fakasilave',
 				'dgr' => 'lea fakatōkelipi',
 				'din' => 'lea fakatingikā',
 				'dje' => 'lea fakatisāma',
 				'doi' => 'lea fakatokili',
 				'dsb' => 'lea fakasōpia-hifo',
 				'dtp' => 'lea fakatusuni-loloto',
 				'dua' => 'lea fakatuala',
 				'dum' => 'lea fakahōlani-lotoloto',
 				'dv' => 'lea fakativehi',
 				'dyo' => 'lea fakaiola-fonī',
 				'dyu' => 'lea fakatiula',
 				'dz' => 'lea fakatisōngika',
 				'dzg' => 'lea fakatasaka',
 				'ebu' => 'lea fakaʻemipū',
 				'ee' => 'lea fakaʻeue',
 				'efi' => 'lea fakaʻefiki',
 				'egl' => 'lea fakaʻemilia',
 				'egy' => 'lea fakaʻisipitemuʻa',
 				'eka' => 'lea fakaʻekaiuki',
 				'el' => 'lea fakakalisi',
 				'elx' => 'lea fakaʻelamite',
 				'en' => 'lea fakapālangi',
 				'en_AU' => 'lea fakapālangi-ʻaositelēlia',
 				'en_CA' => 'lea fakapālangi-kānata',
 				'en_GB' => 'lea fakapilitānia',
 				'en_US' => 'lea fakapālangi-ʻamelika',
 				'en_US@alt=short' => 'lea fakapālangi-ʻAmelika',
 				'enm' => 'lea fakapālangi-lotoloto',
 				'eo' => 'lea fakaʻesipulanito',
 				'es' => 'lea fakasipēnisi',
 				'es_419' => 'lea fakasipeini-lātini-ʻamelika',
 				'es_ES' => 'lea fakasipeini-ʻeulope',
 				'es_MX' => 'lea fakasipeini-mekisikou',
 				'esu' => 'lea fakaiūpiki-loloto',
 				'et' => 'lea fakaʻesitōnia',
 				'eu' => 'lea fakapāsiki',
 				'ewo' => 'lea fakaʻeuōnito',
 				'ext' => 'lea fakaʻekisitematula',
 				'fa' => 'lea fakapēsia',
 				'fa_AF' => 'lea fakapēsia (ʻtalī)',
 				'fan' => 'lea fakafangi',
 				'fat' => 'lea fakafanitē',
 				'ff' => 'lea fakafulā',
 				'fi' => 'lea fakafinilani',
 				'fil' => 'lea fakafilipaini',
 				'fit' => 'lea fakafinilani-tōnetale',
 				'fj' => 'lea fakafisi',
 				'fo' => 'lea fakafaloe',
 				'fon' => 'lea fakafōngi',
 				'fr' => 'lea fakafalanisē',
 				'fr_CA' => 'lea fakafalanisē-kānata',
 				'fr_CH' => 'lea fakafalanisē-suisilani',
 				'frc' => 'lea fakafalanisē-kasuni',
 				'frm' => 'lea fakafalanisē-lotoloto',
 				'fro' => 'lea fakafalanisē-motuʻa',
 				'frp' => 'lea fakaʻāpitano',
 				'frr' => 'lea fakafilisia-tokelau',
 				'frs' => 'lea fakafilisia-hahake',
 				'fur' => 'lea fakafulilāni',
 				'fy' => 'lea fakafilisia-hihifo',
 				'ga' => 'lea fakaʻaelani',
 				'gaa' => 'lea fakakā',
 				'gag' => 'lea fakakakausi',
 				'gan' => 'lea fakasiaina-kani',
 				'gay' => 'lea fakakaio',
 				'gba' => 'lea fakakapaia',
 				'gbz' => 'lea fakateli-soloasitelia',
 				'gd' => 'lea fakakaeliki',
 				'gez' => 'lea fakasiʻisi',
 				'gil' => 'lea fakakilipasi',
 				'gl' => 'lea fakakalisia',
 				'glk' => 'lea fakakilaki',
 				'gmh' => 'lea fakasiamane-hake-lotoloto',
 				'gn' => 'lea fakakualani',
 				'goh' => 'lea fakasiamane-hake-motuʻa',
 				'gom' => 'lea fakakonikanī-koani',
 				'gon' => 'lea fakakonitī',
 				'gor' => 'lea fakakolonitalo',
 				'got' => 'lea fakakotika',
 				'grb' => 'lea fakakēpo',
 				'grc' => 'lea fakakalisimuʻa',
 				'gsw' => 'lea fakasiamane-suisilani',
 				'gu' => 'lea fakakutalati',
 				'guc' => 'lea fakaʻuaiū',
 				'gur' => 'lea fakafalefale',
 				'guz' => 'lea fakakusī',
 				'gv' => 'lea fakamangikī',
 				'gwi' => 'lea fakaʻuīsini',
 				'ha' => 'lea fakahausa',
 				'hai' => 'lea fakahaita',
 				'hak' => 'lea fakasiaina-haka',
 				'haw' => 'lea fakahauaiʻi',
 				'hax' => 'lea fakahaita-tonga',
 				'he' => 'lea fakahepelū',
 				'hi' => 'lea fakahinitī',
 				'hi_Latn' => 'lea fakahinitī (fakalatina)',
 				'hi_Latn@alt=variant' => 'lea fakahinitī (fakapilitānia)',
 				'hif' => 'lea fakahinitī-fisi',
 				'hil' => 'lea fakahilikainoni',
 				'hit' => 'lea fakahitite',
 				'hmn' => 'lea fakamōngi',
 				'ho' => 'lea fakahili-motu',
 				'hr' => 'lea fakakuloisia',
 				'hsb' => 'lea fakasōpia-hake',
 				'hsn' => 'lea fakasiaina-siangi',
 				'ht' => 'lea fakahaiti',
 				'hu' => 'lea fakahungakalia',
 				'hup' => 'lea fakahupa',
 				'hur' => 'lea fakahalikomele',
 				'hy' => 'lea fakaʻāmenia',
 				'hz' => 'lea fakahelelo',
 				'ia' => 'lea fakavahaʻalea',
 				'iba' => 'lea fakaʻipani',
 				'ibb' => 'lea fakaʻipipio',
 				'id' => 'lea fakaʻinitōnesia',
 				'ie' => 'lea fakavahaʻalingikē',
 				'ig' => 'lea fakaʻikipō',
 				'ii' => 'lea fakasisiuani-ī',
 				'ik' => 'lea fakaʻinupiaki',
 				'ikt' => 'lea fakaʻinuketītuti-kānata-hihifo',
 				'ilo' => 'lea fakaʻiloko',
 				'inh' => 'lea fakaʻingusi',
 				'io' => 'lea fakaʻito',
 				'is' => 'lea fakaʻaisilani',
 				'it' => 'lea fakaʻītali',
 				'iu' => 'lea fakaʻinuketītuti',
 				'izh' => 'lea fakaʻingiliani',
 				'ja' => 'lea fakasiapani',
 				'jam' => 'lea fakapālangi-samaika',
 				'jbo' => 'lea fakalosipani',
 				'jgo' => 'lea fakanikōmipa',
 				'jmc' => 'lea fakamasame',
 				'jpr' => 'lea fakaʻiuteo-pēsia',
 				'jrb' => 'lea fakaʻiuteo-ʻalepea',
 				'jut' => 'lea fakaʻiutilani',
 				'jv' => 'lea fakasava',
 				'ka' => 'lea fakaseōsia',
 				'kaa' => 'lea fakakala-kalipaki',
 				'kab' => 'lea fakakapile',
 				'kac' => 'lea fakakasini',
 				'kaj' => 'lea fakasisū',
 				'kam' => 'lea fakakamipa',
 				'kaw' => 'lea fakakavi',
 				'kbd' => 'lea fakakapālitia',
 				'kbl' => 'lea fakakanēmipu',
 				'kcg' => 'lea fakatiapi',
 				'kde' => 'lea fakamakōnite',
 				'kea' => 'lea fakakapuvelitianu',
 				'ken' => 'lea fakakeniangi',
 				'kfo' => 'lea fakakolo',
 				'kg' => 'lea fakakongikō',
 				'kgp' => 'lea fakakaingangi',
 				'kha' => 'lea fakakāsi',
 				'kho' => 'lea fakakōtani',
 				'khq' => 'lea fakakoila-sīni',
 				'khw' => 'lea fakakouali',
 				'ki' => 'lea fakakikuiu',
 				'kiu' => 'lea fakakilimanisikī',
 				'kj' => 'lea fakakuaniama',
 				'kk' => 'lea fakakasaki',
 				'kkj' => 'lea fakakako',
 				'kl' => 'lea fakakalaʻalisuti',
 				'kln' => 'lea fakakalenisini',
 				'km' => 'lea fakakamipōtia',
 				'kmb' => 'lea fakakimipūnitu',
 				'kn' => 'lea fakakanata',
 				'ko' => 'lea fakakōlea',
 				'koi' => 'lea fakakomi-pelemiaki',
 				'kok' => 'lea fakakonikanī',
 				'kos' => 'lea fakakosilae',
 				'kpe' => 'lea fakakepele',
 				'kr' => 'lea fakakanuli',
 				'krc' => 'lea fakakalate-palakili',
 				'kri' => 'lea fakakilio',
 				'krj' => 'lea fakakinaraiā',
 				'krl' => 'lea fakakalelia',
 				'kru' => 'lea fakakuluki',
 				'ks' => 'lea fakakāsimila',
 				'ksb' => 'lea fakasiamipala',
 				'ksf' => 'lea fakapafia',
 				'ksh' => 'lea fakakolongia',
 				'ku' => 'lea fakakulitī',
 				'kum' => 'lea fakakumiki',
 				'kut' => 'lea fakakutenai',
 				'kv' => 'lea fakakomi',
 				'kw' => 'lea fakakoniuali',
 				'kwk' => 'lea fakakuakuala',
 				'ky' => 'lea fakakīsisi',
 				'la' => 'lea fakalatina',
 				'lad' => 'lea fakalatino',
 				'lag' => 'lea fakalangi',
 				'lah' => 'lea fakapunisapi-hihifoi',
 				'lam' => 'lea fakalamipā',
 				'lb' => 'lea fakalakisimipeki',
 				'lez' => 'lea fakalesikia',
 				'lfn' => 'lea fakakavakava-foʻou',
 				'lg' => 'lea fakakanita',
 				'li' => 'lea fakalimipūliki',
 				'lij' => 'lea fakalikulia',
 				'lil' => 'lea fakalilōeti',
 				'liv' => 'lea fakalivonia',
 				'lkt' => 'lea fakalakota',
 				'lmo' => 'lea fakalomipāti',
 				'ln' => 'lea lingikala',
 				'lo' => 'lea fakalau',
 				'lol' => 'lea fakamongikō',
 				'lou' => 'lea fakaluisiana',
 				'loz' => 'lea fakalosi',
 				'lrc' => 'lea fakaluli-tokelau',
 				'lsm' => 'lea fakasāmia',
 				'lt' => 'lea fakalituania',
 				'ltg' => 'lea fakalatakale',
 				'lu' => 'lea fakalupa-katanga',
 				'lua' => 'lea fakalupa-lulua',
 				'lui' => 'lea fakaluiseno',
 				'lun' => 'lea fakalunitā',
 				'luo' => 'lea fakaluo',
 				'lus' => 'lea fakamiso',
 				'luy' => 'lea fakaluīa',
 				'lv' => 'lea fakalativia',
 				'lzh' => 'lea fakasiaina-faʻutohi',
 				'lzz' => 'lea fakalasu',
 				'mad' => 'lea fakamatula',
 				'maf' => 'lea fakamafa',
 				'mag' => 'lea fakamakahi',
 				'mai' => 'lea fakamaitili',
 				'mak' => 'lea fakamakasali',
 				'man' => 'lea fakamanitīngiko',
 				'mas' => 'lea fakamasai',
 				'mde' => 'lea fakamapa',
 				'mdf' => 'lea fakamokisiā',
 				'mdr' => 'lea fakamanetali',
 				'men' => 'lea fakamenetī',
 				'mer' => 'lea fakamelu',
 				'mfe' => 'lea fakamolisieni',
 				'mg' => 'lea fakamalakasi',
 				'mga' => 'lea fakaʻaelani-lotoloto',
 				'mgh' => 'lea fakamakūa-meʻeto',
 				'mgo' => 'lea fakametā',
 				'mh' => 'lea fakamāsolo',
 				'mi' => 'lea fakamāuli',
 				'mic' => 'lea fakamikemaki',
 				'min' => 'lea fakaminangikapau',
 				'mk' => 'lea fakamasitōnia',
 				'ml' => 'lea fakaʻinitia-malāialami',
 				'mn' => 'lea fakamongokōlia',
 				'mnc' => 'lea fakamanisū',
 				'mni' => 'lea fakamanipuli',
 				'moe' => 'lea fakaʻinuʻaimuni',
 				'moh' => 'lea fakamohauki',
 				'mos' => 'lea fakamosi',
 				'mr' => 'lea fakamalati',
 				'mrj' => 'lea fakamali-hihifo',
 				'ms' => 'lea fakamalei',
 				'mt' => 'lea fakamalita',
 				'mua' => 'lea fakamunitangi',
 				'mul' => 'lea tuifio',
 				'mus' => 'lea fakakileki',
 				'mwl' => 'lea fakamilanitēsi',
 				'mwr' => 'lea fakamaliwali',
 				'mwv' => 'lea fakamenitauai',
 				'my' => 'lea fakapema',
 				'mye' => 'lea fakamiene',
 				'myv' => 'lea fakaʻelisia',
 				'mzn' => 'lea fakamasanitelani',
 				'na' => 'lea fakanaulu',
 				'nan' => 'lea fakasiaina-mininani',
 				'nap' => 'lea fakanapoletano',
 				'naq' => 'lea fakanama',
 				'nb' => 'lea fakanouaē-pokimali',
 				'nd' => 'lea fakanetepele-tokelau',
 				'nds' => 'lea fakasiamane-hifo',
 				'nds_NL' => 'lea fakasakisoni-hifo',
 				'ne' => 'lea fakanepali',
 				'new' => 'lea fakaneuali',
 				'ng' => 'lea fakanetongikā',
 				'nia' => 'lea fakaniasi',
 				'niu' => 'lea fakaniuē',
 				'njo' => 'lea fakaʻaonasa',
 				'nl' => 'lea fakahōlani',
 				'nl_BE' => 'lea fakahōlani-pelesiume',
 				'nmg' => 'lea fakakuasio',
 				'nn' => 'lea fakanoauē-ninosiki',
 				'nnh' => 'lea fakangiemipōni',
 				'no' => 'lea fakanouaē',
 				'nog' => 'lea fakanokai',
 				'non' => 'lea fakanoauē-motuʻa',
 				'nov' => 'lea fakanoviale',
 				'nqo' => 'lea fakanikō',
 				'nr' => 'lea fakanetepele-tonga',
 				'nso' => 'lea fakasoto-tokelau',
 				'nus' => 'lea fakanueli',
 				'nv' => 'lea fakanavaho',
 				'nwc' => 'lea fakaneuali-motuʻa',
 				'ny' => 'lea fakanianisa',
 				'nym' => 'lea fakaniamiuesi',
 				'nyn' => 'lea fakanianikole',
 				'nyo' => 'lea fakaniolo',
 				'nzi' => 'lea fakanesima',
 				'oc' => 'lea fakaʻokitane',
 				'oj' => 'lea fakaʻosipiuā',
 				'ojb' => 'lea fakaʻosipiuā-tokelauhihifo',
 				'ojc' => 'lea fakaʻosipiuā-loto',
 				'ojs' => 'lea fakakilī-osi',
 				'ojw' => 'lea fakaʻosipiuā-hihifo',
 				'oka' => 'lea faka-ʻokanākani',
 				'om' => 'lea fakaʻolomo',
 				'or' => 'lea fakaʻotia',
 				'os' => 'lea fakaʻosetiki',
 				'osa' => 'lea fakaʻosēse',
 				'ota' => 'lea fakatoake-ʻotomani',
 				'pa' => 'lea fakapūnusapi',
 				'pag' => 'lea fakapangasinani',
 				'pal' => 'lea fakapālavi',
 				'pam' => 'lea fakapamipanga',
 				'pap' => 'lea fakapapiamēnito',
 				'pau' => 'lea fakapalau',
 				'pcd' => 'lea fakapikāti',
 				'pcm' => 'lea fakanaisilia',
 				'pdc' => 'lea fakasiamane-penisilivania',
 				'pdt' => 'lea fakasiamane-lafalafa',
 				'peo' => 'lea fakapēsia-motuʻa',
 				'pfl' => 'lea fakasiamane-palatine',
 				'phn' => 'lea fakafoinikia',
 				'pi' => 'lea fakapāli',
 				'pis' => 'lea fakapisini',
 				'pl' => 'lea fakapolani',
 				'pms' => 'lea fakapiemonite',
 				'pnt' => 'lea fakaponitiki',
 				'pon' => 'lea fakaponapē',
 				'pqm' => 'lea fakamaliseti-pasamakuoti',
 				'prg' => 'lea fakapulūsia',
 				'pro' => 'lea fakapolovenisi-motuʻa',
 				'ps' => 'lea fakapasitō',
 				'pt' => 'lea fakapotukali',
 				'qu' => 'lea fakakuetisa',
 				'quc' => 'lea fakakīsē',
 				'qug' => 'lea fakakuitisa-simipolaso',
 				'raj' => 'lea fakalasasitani',
 				'rap' => 'lea fakalapanui',
 				'rar' => 'lea fakalalotonga',
 				'rgn' => 'lea fakalomaniolo',
 				'rhg' => 'lea fakalouhingia',
 				'rif' => 'lea fakalifi',
 				'rm' => 'lea fakalaito-lomēnia',
 				'rn' => 'lea fakaluaniti',
 				'ro' => 'lea fakalōmenia',
 				'ro_MD' => 'lea fakamolitāvia',
 				'rof' => 'lea fakalomipō',
 				'rom' => 'lea fakalomani',
 				'rtm' => 'lea fakalotuma',
 				'ru' => 'lea fakalūsia',
 				'rue' => 'lea fakalusini',
 				'rug' => 'lea fakaloviana',
 				'rup' => 'lea fakaʻalomania',
 				'rw' => 'lea fakakiniāuanita',
 				'rwk' => 'lea fakaluā',
 				'sa' => 'lea fakasanisukuliti',
 				'sad' => 'lea fakasanitaue',
 				'sah' => 'lea fakaiakuti',
 				'sam' => 'lea fakasamalitani-ʻalāmiti',
 				'saq' => 'lea fakasamipulu',
 				'sas' => 'lea fakasasaki',
 				'sat' => 'lea fakasanitali',
 				'saz' => 'lea fakasaulasitilā',
 				'sba' => 'lea fakangāmipai',
 				'sbp' => 'lea fakasangu',
 				'sc' => 'lea fakasaletīnia',
 				'scn' => 'lea fakasisīlia',
 				'sco' => 'lea fakasikotilani',
 				'sd' => 'lea fakasīniti',
 				'sdc' => 'lea fakasaletīnia-sasalesu',
 				'sdh' => 'lea faka-tonga ‘o Ketesi',
 				'se' => 'lea fakasami-tokelau',
 				'see' => 'lea fakaseneka',
 				'seh' => 'lea fakasena',
 				'sei' => 'lea fakaseli',
 				'sel' => 'lea fakaselikupi',
 				'ses' => 'lea fakakoilapolo-seni',
 				'sg' => 'lea fakasangikō',
 				'sga' => 'lea fakaʻaelani-motuʻa',
 				'sgs' => 'lea fakasamositia',
 				'sh' => 'lea fakakuloisia-sēpia',
 				'shi' => 'lea fakataselihiti',
 				'shn' => 'lea fakasiani',
 				'shu' => 'lea fakaʻalepea-sāti',
 				'si' => 'lea fakasingihala',
 				'sid' => 'lea fakasitamo',
 				'sk' => 'lea fakasolāvaki',
 				'sl' => 'lea fakasolovenia',
 				'slh' => 'lea fakalusūtisiti',
 				'sli' => 'lea fakasilesia-hifo',
 				'sly' => 'lea fakaselaiā',
 				'sm' => 'lea fakahaʻamoa',
 				'sma' => 'lea fakasami-tonga',
 				'smj' => 'lea fakasami-lule',
 				'smn' => 'lea fakasami-ʻinali',
 				'sms' => 'lea fakasami-sikolita',
 				'sn' => 'lea fakasiona',
 				'snk' => 'lea fakasoninekē',
 				'so' => 'lea fakasomali',
 				'sog' => 'lea fakasokitiana',
 				'sq' => 'lea fakaʻalapēnia',
 				'sr' => 'lea fakasēpia',
 				'srn' => 'lea fakasulanane-tongikō',
 				'srr' => 'lea fakasēlēle',
 				'ss' => 'lea fakasuati',
 				'ssy' => 'lea fakasaho',
 				'st' => 'lea fakasoto-tonga',
 				'stq' => 'lea fakafilisia-satēlani',
 				'str' => 'lea fakasalisi-vahatokelau',
 				'su' => 'lea fakasunitā',
 				'suk' => 'lea fakasukuma',
 				'sus' => 'lea fakasusū',
 				'sux' => 'lea fakasumelia',
 				'sv' => 'lea fakasuēteni',
 				'sw' => 'lea fakasuahili',
 				'sw_CD' => 'lea fakasuahili-kongikō',
 				'swb' => 'lea fakakomolo',
 				'syc' => 'lea fakasuliāiā-muʻa',
 				'syr' => 'lea fakasuliāiā',
 				'szl' => 'lea fakasilesia',
 				'ta' => 'lea fakatamili',
 				'tce' => 'lea fakatutisone-tonga',
 				'tcy' => 'lea fakatulu',
 				'te' => 'lea fakaʻinitia-teluku',
 				'tem' => 'lea fakatimenē',
 				'teo' => 'lea fakateso',
 				'ter' => 'lea fakateleno',
 				'tet' => 'lea fakatetumu',
 				'tg' => 'lea fakatāsiki',
 				'tgx' => 'lea fakatākisi',
 				'th' => 'lea fakatailani',
 				'tht' => 'lea fakatālitāni',
 				'ti' => 'lea fakatikilinia',
 				'tig' => 'lea fakatikilē',
 				'tiv' => 'lea fakativi',
 				'tk' => 'lea fakatēkimeni',
 				'tkl' => 'lea fakatokelau',
 				'tkr' => 'lea fakasākuli',
 				'tl' => 'lea fakatakāloka',
 				'tlh' => 'lea fakakilingoni',
 				'tli' => 'lea fakatilingikīte',
 				'tly' => 'lea fakatalisi',
 				'tmh' => 'lea fakatamasieki',
 				'tn' => 'lea fakatisuana',
 				'to' => 'lea fakatonga',
 				'tog' => 'lea fakaniasa-tonga',
 				'tok' => 'lea fakatoki-pona',
 				'tpi' => 'lea fakatoki-pisini',
 				'tr' => 'lea fakatoake',
 				'tru' => 'lea fakatuloio',
 				'trv' => 'lea fakataloko',
 				'ts' => 'lea fakatisonga',
 				'tsd' => 'lea fakasakōnia',
 				'tsi' => 'lea fakatisīmisiani',
 				'tt' => 'lea fakatatale',
 				'ttm' => 'lea fakatutisone-tokelau',
 				'ttt' => 'lea fakatati-moselemi',
 				'tum' => 'lea fakatumepuka',
 				'tvl' => 'lea fakatūvalu',
 				'tw' => 'lea fakatusuī',
 				'twq' => 'lea fakatasauaki',
 				'ty' => 'lea fakatahiti',
 				'tyv' => 'lea fakatuvīnia',
 				'tzm' => 'lea fakatamasaiti-ʻatilasi-loloto',
 				'udm' => 'lea fakaʻutimuliti',
 				'ug' => 'lea fakaʻuikūli',
 				'uga' => 'lea fakaʻūkaliti',
 				'uk' => 'lea fakaʻūkalaʻine',
 				'umb' => 'lea fakaʻumipūnitu',
 				'und' => 'lea taʻeʻiloa',
 				'ur' => 'lea fakaʻūtū',
 				'uz' => 'lea fakaʻusipeki',
 				'vai' => 'lea fakavai',
 				've' => 'lea fakavenitā',
 				'vec' => 'lea fakavenēsia',
 				'vep' => 'lea fakavepisi',
 				'vi' => 'lea fakavietinami',
 				'vls' => 'lea fakavelamingi-hihifo',
 				'vmf' => 'lea fakafalanikoni-loloto',
 				'vo' => 'lea fakavolapiki',
 				'vot' => 'lea fakavotiki',
 				'vro' => 'lea fakavōlo',
 				'vun' => 'lea fakavūniso',
 				'wa' => 'lea fakaʻualonia',
 				'wae' => 'lea fakaʻualiseli',
 				'wal' => 'lea fakaʻuolaita',
 				'war' => 'lea fakaʻualai',
 				'was' => 'lea fakaʻuasiō',
 				'wbp' => 'lea fakaʻuālipili',
 				'wo' => 'lea fakaʻuolofo',
 				'wuu' => 'lea fakasiaina-uū',
 				'xal' => 'lea fakakalimiki',
 				'xh' => 'lea fakatōsa',
 				'xmf' => 'lea fakamingilelia',
 				'xog' => 'lea fakasoka',
 				'yao' => 'lea fakaʻiao',
 				'yap' => 'lea fakaʻiapi',
 				'yav' => 'lea fakaʻiangipeni',
 				'ybb' => 'lea fakaʻiēmipa',
 				'yi' => 'lea fakaītisi',
 				'yo' => 'lea fakaʻiōlupa',
 				'yrl' => 'lea fakaneʻēngatū',
 				'yue' => 'lea fakakuangitongi',
 				'yue@alt=menu' => 'lea fakakuangitongi (Siaina)',
 				'za' => 'lea fakasuangi',
 				'zap' => 'lea fakasapoteki',
 				'zbl' => 'lea fakaʻilonga-pilisi',
 				'zea' => 'lea fakasēlani',
 				'zen' => 'lea fakasenaka',
 				'zgh' => 'lea fakatamasaiti-moloko',
 				'zh' => 'lea fakasiaina',
 				'zh@alt=menu' => 'lea fakasiaina-mānitali',
 				'zh_Hans' => 'lea fakasiaina-fakafaingofua',
 				'zh_Hans@alt=long' => 'lea fakasiaina-mānitali-fakafaingofua',
 				'zh_Hant' => 'lea fakasiaina-tukufakaholo',
 				'zh_Hant@alt=long' => 'lea fakasiaina-mānitali-tukufakaholo',
 				'zu' => 'lea fakasulu',
 				'zun' => 'lea fakasuni',
 				'zxx' => 'ʻikai ha lea',
 				'zza' => 'lea fakasāsā',

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
			'Adlm' => 'tohinima fakaʻatilami',
 			'Afak' => 'tohinima fakaʻafaka',
 			'Aghb' => 'tohinima fakaʻalapēnia-kaukasia',
 			'Ahom' => 'tohinima fakaʻahomi',
 			'Arab' => 'tohinima fakaʻalepea',
 			'Aran' => 'tohinima fakanasatalīki',
 			'Armi' => 'tohinima fakaʻalāmiti-ʻemipaea',
 			'Armn' => 'tohinima fakaʻāmenia',
 			'Avst' => 'tohinima fakaʻavesitani',
 			'Bali' => 'tohinima fakapali',
 			'Bamu' => 'tohinima fakapamumi',
 			'Bass' => 'tohinima fakapasa-vā',
 			'Batk' => 'tohinima fakapātaki',
 			'Beng' => 'tohinima fakapāngilā',
 			'Bhks' => 'tohinima fakapaikisuki',
 			'Blis' => 'tohinima fakaʻilonga-pilisi',
 			'Bopo' => 'tohinima fakapopomofo',
 			'Brah' => 'tohinima fakapalāmī',
 			'Brai' => 'tohinima laukonga ki he kui',
 			'Bugi' => 'tohinima fakapukisi',
 			'Buhd' => 'tohinima fakapuhiti',
 			'Cakm' => 'tohinima fakasakimā',
 			'Cans' => 'tohinima fakatupuʻi-kānata-fakatahataha',
 			'Cari' => 'tohinima fakakali',
 			'Cham' => 'tohinima fakasami',
 			'Cher' => 'tohinima fakaselokī',
 			'Chrs' => 'tohinima fakakōlasimia',
 			'Cirt' => 'tohinima fakakīliti',
 			'Copt' => 'tohinima fakakopitika',
 			'Cpmn' => 'tohinima fakasaipalesi-minoa',
 			'Cprt' => 'tohinima fakasaipalesi',
 			'Cyrl' => 'tohinima fakalūsia',
 			'Cyrs' => 'tohinima fakalūsia-lotu-motuʻa',
 			'Deva' => 'tohinima fakaʻinitia-tevanākalī',
 			'Diak' => 'tohinima fakativehi-akulu',
 			'Dogr' => 'tohinima fakatokala',
 			'Dsrt' => 'tohinima fakateseleti',
 			'Dupl' => 'tohinimanounou fakatupoloiē',
 			'Egyd' => 'tohinima temotika-fakaʻisipite',
 			'Egyh' => 'tohinima hielatika-fakaʻisipite',
 			'Egyp' => 'tohinima tongitapu-fakaʻisipite',
 			'Elba' => 'tohinima fakaʻelepasani',
 			'Elym' => 'tohinima fakaʻelimiti',
 			'Ethi' => 'tohinima fakaʻītiōpia',
 			'Geok' => 'tohinima fakakutusuli-seōsia',
 			'Geor' => 'tohinima fakaseōsia',
 			'Glag' => 'tohinima fakakalakoliti',
 			'Gong' => 'tohinima fakakunisala-kōniti',
 			'Gonm' => 'tohinima fakakōniti-masalami',
 			'Goth' => 'tohinima fakakotika',
 			'Gran' => 'tohinima fakasilanitā',
 			'Grek' => 'tohinima fakakalisi',
 			'Gujr' => 'tohinima fakaʻinitia-kutalati',
 			'Guru' => 'tohinima fakakūmuki',
 			'Hanb' => 'tohinima fakahānipi',
 			'Hang' => 'tohinima fakakōlea-hāngūlu',
 			'Hani' => 'tohinima fakasiaina',
 			'Hano' => 'tohinima fakahanunōʻo',
 			'Hans' => 'fakafaingofua',
 			'Hans@alt=stand-alone' => 'tohinima fakasiaina-fakafaingofua',
 			'Hant' => 'tukufakaholo',
 			'Hant@alt=stand-alone' => 'tohinima fakasiaina-tukufakaholo',
 			'Hatr' => 'tohinima fakahatalani',
 			'Hebr' => 'tohinima fakahepelū',
 			'Hira' => 'tohinima fakasiapani-hilakana',
 			'Hluw' => 'tohinima tongitapu-fakaʻanatolia',
 			'Hmng' => 'tohinima fakapahaumongi',
 			'Hmnp' => 'tohinima fakaniakengi-puasue-hamongi',
 			'Hrkt' => 'tohinima fakasilapa-siapani',
 			'Hung' => 'tohinima fakahungakalia-motuʻa',
 			'Inds' => 'tohinima fakaʻinitusi',
 			'Ital' => 'tohinima fakaʻītali-motuʻa',
 			'Jamo' => 'tohinima fakasamo',
 			'Java' => 'tohinima fakasava',
 			'Jpan' => 'tohinima fakasiapani',
 			'Jurc' => 'tohinima fakaiūkeni',
 			'Kali' => 'tohinima fakakaialī',
 			'Kana' => 'tohinima fakasiapani-katakana',
 			'Kawi' => 'tohinima fakakaui',
 			'Khar' => 'tohinima fakakalositī',
 			'Khmr' => 'tohinima fakakamipōtia',
 			'Khoj' => 'tohinima fakakosikī',
 			'Kits' => 'tohinima fakakitanisiʻi',
 			'Knda' => 'tohinima fakaʻinitia-kanata',
 			'Kore' => 'tohinima fakakōlea',
 			'Kpel' => 'tohinima fakakepele',
 			'Kthi' => 'tohinima fakakaiatī',
 			'Lana' => 'tohinima fakalana',
 			'Laoo' => 'tohinima fakalau',
 			'Latf' => 'tohinima fakalatina-falakituli',
 			'Latg' => 'tohinima fakalatina-kaeliki',
 			'Latn' => 'tohinima fakalatina',
 			'Lepc' => 'tohinima fakalepasā',
 			'Limb' => 'tohinima fakalimipū',
 			'Lina' => 'tohinima fakalinea-A',
 			'Linb' => 'tohinima fakalinea-P',
 			'Lisu' => 'tohinima fakafalāse',
 			'Loma' => 'tohinima fakaloma',
 			'Lyci' => 'tohinima fakalīsia',
 			'Lydi' => 'tohinima fakalītia',
 			'Mahj' => 'tohinima fakamahasani',
 			'Maka' => 'tohinima fakamakasā',
 			'Mand' => 'tohinima fakamanitaea',
 			'Mani' => 'tohinima fakamanikaea',
 			'Marc' => 'tohinima fakamaʻake',
 			'Maya' => 'tohinima tongitapu fakamaia',
 			'Medf' => 'tohinima fakametefaitili',
 			'Mend' => 'tohinima fakamēniti',
 			'Merc' => 'tohinima fakameloue-heihei',
 			'Mero' => 'tohinima fakameloue',
 			'Mlym' => 'tohinima fakaʻinitia-malāialami',
 			'Modi' => 'tohinima fakamotī',
 			'Mong' => 'tohinima fakamongokōlia',
 			'Moon' => 'tohinima laukonga ki he kui-māhina',
 			'Mroo' => 'tohinima fakamolō',
 			'Mtei' => 'tohinima fakametei-maieki',
 			'Mult' => 'tohinima fakamulitani',
 			'Mymr' => 'tohinima fakapema',
 			'Nagm' => 'tohinima fakamunitali-pani',
 			'Nand' => 'tohinima fakananitinakali',
 			'Narb' => 'tohinima fakaʻalepea-tokelau-motuʻa',
 			'Nbat' => 'tohinima fakanapatea',
 			'Newa' => 'tohinima fakaneua',
 			'Nkgb' => 'tohinima fakanati-sepa',
 			'Nkoo' => 'tohinima fakanikō',
 			'Nshu' => 'tohinima fakanasiū',
 			'Ogam' => 'tohinima fakaʻokami',
 			'Olck' => 'tohinima fakaʻolisiki',
 			'Orkh' => 'tohinima fakaʻolikoni',
 			'Orya' => 'tohinima fakaʻotia',
 			'Osge' => 'tohinima fakaʻosase',
 			'Osma' => 'tohinima fakaʻosimānia',
 			'Ougr' => 'tohinima fakauikeli-motuʻa',
 			'Palm' => 'tohinima fakapalamilene',
 			'Pauc' => 'tohinima fakapausinihau',
 			'Perm' => 'tohinima fakapēmi-motuʻa',
 			'Phag' => 'tohinima fakapākisipā',
 			'Phli' => 'tohinima fakapālavi-tongi',
 			'Phlp' => 'tohinima fakapālavi-saame',
 			'Phlv' => 'tohinima fakapālavi-tohi',
 			'Phnx' => 'tohinima fakafoinikia',
 			'Plrd' => 'tohinima fakafonētiki-polāti',
 			'Prti' => 'tohinima fakapātia-tongi',
 			'Qaag' => 'tohinima fakakāki',
 			'Rjng' => 'tohinima fakalesiangi',
 			'Rohg' => 'tohinima fakahanifi-lohingia',
 			'Roro' => 'tohinima fakalongolongo',
 			'Runr' => 'tohinima fakaluniki',
 			'Samr' => 'tohinima fakasamalitane',
 			'Sara' => 'tohinima fakasalati',
 			'Sarb' => 'tohinima fakaʻalepea-tonga-motuʻa',
 			'Saur' => 'tohinima fakasaulasitā',
 			'Sgnw' => 'tohinima fakaʻilonga-tohi',
 			'Shaw' => 'tohinima fakasiavi',
 			'Shrd' => 'tohinima fakasiālatā',
 			'Sidd' => 'tohinima fakasititami',
 			'Sind' => 'tohinima fakakutauāti',
 			'Sinh' => 'tohinima fakasingihala',
 			'Sogd' => 'tohinima fakasokitia',
 			'Sogo' => 'tohinima fakasokitia-motuʻa',
 			'Sora' => 'tohinima fakasolasomipengi',
 			'Soyo' => 'tohinima fakasoiōmipo',
 			'Sund' => 'tohinima fakasunitā',
 			'Sylo' => 'tohinima fakasailoti-nakili',
 			'Syrc' => 'tohinima fakasuliāiā',
 			'Syre' => 'tohinima fakasuliāiā-ʻesitelangelo',
 			'Syrj' => 'tohinima fakasuliāiā-hihifo',
 			'Syrn' => 'tohinima fakasuliāiā-hahake',
 			'Tagb' => 'tohinima fakatakipaneuā',
 			'Takr' => 'tohinima fakatakili',
 			'Tale' => 'tohinima fakatai-lue',
 			'Talu' => 'tohinima fakatai-lue-foʻou',
 			'Taml' => 'tohinima fakatamili',
 			'Tang' => 'tohinima fakatanguti',
 			'Tavt' => 'tohinima fakatai-vieti',
 			'Telu' => 'tohinima fakaʻinitia-teluku',
 			'Teng' => 'tohinima fakatengiuali',
 			'Tfng' => 'tohinima fakatifināki',
 			'Tglg' => 'tohinima fakatakaloka',
 			'Thaa' => 'tohinima fakatāna',
 			'Thai' => 'tohinima fakatailani',
 			'Tibt' => 'tohinima fakataipeti',
 			'Tirh' => 'tohinima fakatīhuta',
 			'Tnsa' => 'tohinima fakatangisā',
 			'Toto' => 'tohinima fakatoto',
 			'Ugar' => 'tohinima fakaʻūkaliti',
 			'Vaii' => 'tohinima fakavai',
 			'Visp' => 'tohinima fakafonētiki-hāmai',
 			'Vith' => 'tohinima fakavitikuki',
 			'Wara' => 'tohinima fakavalangi-kisitī',
 			'Wcho' => 'tohinima fakauāniso',
 			'Wole' => 'tohinima fakauoleai',
 			'Xpeo' => 'tohinima fakapēsiamuʻa',
 			'Xsux' => 'tohinima fakamataʻingahau-sumelo-akatia',
 			'Yezi' => 'tohinima fakasesiti',
 			'Yiii' => 'tohinima fakaīī',
 			'Zanb' => 'tohinima fakasanapasā-tapafā',
 			'Zinh' => 'tohinima hokosi',
 			'Zmth' => 'tohinima fakamatematika',
 			'Zsye' => 'tohinima fakatātā',
 			'Zsym' => 'tohinima fakaʻilonga',
 			'Zxxx' => 'tohinima taʻetohitohiʻi',
 			'Zyyy' => 'tohinima fakatatau',
 			'Zzzz' => 'tohinima taʻeʻiloa',

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
			'001' => 'Māmani',
 			'002' => 'ʻAfilika',
 			'003' => 'ʻAmelika tokelau',
 			'005' => 'ʻAmelika tonga',
 			'009' => 'ʻOsēnia',
 			'011' => 'ʻAfilika fakahihifo',
 			'013' => 'ʻAmelika lotoloto',
 			'014' => 'ʻAfilika fakahahake',
 			'015' => 'ʻAfilika fakatokelau',
 			'017' => 'ʻAfilika lotoloto',
 			'018' => 'ʻAfilika fakatonga',
 			'019' => 'Ongo ʻAmelika',
 			'021' => 'ʻAmelika fakatokelau',
 			'029' => 'Kalipiane',
 			'030' => 'ʻĒsia fakahahake',
 			'034' => 'ʻĒsia fakatonga',
 			'035' => 'ʻĒsia fakatongahahake',
 			'039' => 'ʻEulope fakatonga',
 			'053' => 'ʻAositelēlēsia',
 			'054' => 'Melanīsia',
 			'057' => 'Potu fonua Mikolonīsia',
 			'061' => 'Polinīsia',
 			'142' => 'ʻĒsia',
 			'143' => 'ʻĒsia lotoloto',
 			'145' => 'ʻĒsia fakahihifo',
 			'150' => 'ʻEulope',
 			'151' => 'ʻEulope fakahahake',
 			'154' => 'ʻEulope fakatokelau',
 			'155' => 'ʻEulope fakahihifo',
 			'202' => 'ʻAfilika fakasahala-tonga',
 			'419' => 'ʻAmelika fakalatina',
 			'AC' => 'Motu ʻAsenisini',
 			'AD' => 'ʻAnitola',
 			'AE' => 'ʻAlepea Fakatahataha',
 			'AF' => 'ʻAfikānisitani',
 			'AG' => 'Anitikua mo Palaputa',
 			'AI' => 'Anikuila',
 			'AL' => 'ʻAlipania',
 			'AM' => 'ʻĀmenia',
 			'AO' => 'ʻAngikola',
 			'AQ' => 'ʻAnitātika',
 			'AR' => 'ʻAsenitina',
 			'AS' => 'Haʻamoa ʻAmelika',
 			'AT' => 'ʻAositulia',
 			'AU' => 'ʻAositelēlia',
 			'AW' => 'ʻAlupa',
 			'AX' => 'ʻOtumotu ʻAlani',
 			'AZ' => 'ʻAsapaisani',
 			'BA' => 'Posinia mo Hesikōvina',
 			'BB' => 'Pāpeitosi',
 			'BD' => 'Pengilātesi',
 			'BE' => 'Pelesiume',
 			'BF' => 'Pekano Faso',
 			'BG' => 'Pulukalia',
 			'BH' => 'Paleini',
 			'BI' => 'Puluniti',
 			'BJ' => 'Penini',
 			'BL' => 'Sā Patēlemi',
 			'BM' => 'Pēmuta',
 			'BN' => 'Pulunei',
 			'BO' => 'Polīvia',
 			'BQ' => 'Kalipiane fakahōlani',
 			'BR' => 'Palāsili',
 			'BS' => 'Pahama',
 			'BT' => 'Pūtani',
 			'BV' => 'Motu Puveti',
 			'BW' => 'Potisiuana',
 			'BY' => 'Pelalusi',
 			'BZ' => 'Pelise',
 			'CA' => 'Kānata',
 			'CC' => 'ʻOtumotu Koko',
 			'CD' => 'Kongo - Kinisasa',
 			'CD@alt=variant' => 'Kongo (LTK)',
 			'CF' => 'Lepupelika ʻAfilika Lotoloto',
 			'CG' => 'Kongo - Palasavila',
 			'CG@alt=variant' => 'Kongo (Lepupelika)',
 			'CH' => 'Suisilani',
 			'CI' => 'Matafonua ʻAivolī',
 			'CK' => 'ʻOtumotu Kuki',
 			'CL' => 'Sili',
 			'CM' => 'Kameluni',
 			'CN' => 'Siaina',
 			'CO' => 'Kolomipia',
 			'CP' => 'Motu Kilipatoni',
 			'CQ' => 'Saaki',
 			'CR' => 'Kosita Lika',
 			'CU' => 'Kiupa',
 			'CV' => 'Muiʻi Vēte',
 			'CW' => 'Kulasao',
 			'CX' => 'Motu Kilisimasi',
 			'CY' => 'Saipalesi',
 			'CZ' => 'Sēkia',
 			'CZ@alt=variant' => 'Lepupelika Seki',
 			'DE' => 'Siamane',
 			'DG' => 'Tieko Kāsia',
 			'DJ' => 'Siputi',
 			'DK' => 'Tenimaʻake',
 			'DM' => 'Tominika',
 			'DO' => 'Lepupelika Tominika',
 			'DZ' => 'ʻAlisilia',
 			'EA' => 'Siuta mo Melila',
 			'EC' => 'ʻEkuetoa',
 			'EE' => 'ʻEsitōnia',
 			'EG' => 'ʻIsipite',
 			'EH' => 'Sahala fakahihifo',
 			'ER' => 'ʻElitulia',
 			'ES' => 'Sipeini',
 			'ET' => 'ʻĪtiōpia',
 			'EU' => 'ʻEulope fakatahataha',
 			'EZ' => 'ʻEulope fekauʻaki-paʻanga',
 			'FI' => 'Finilani',
 			'FJ' => 'Fisi',
 			'FK' => 'ʻOtumotu Fokulani',
 			'FK@alt=variant' => 'ʻOtumotu Malivina',
 			'FM' => 'Mikolonīsia',
 			'FO' => 'ʻOtumotu Faloe',
 			'FR' => 'Falanisē',
 			'GA' => 'Kaponi',
 			'GB' => 'Pilitānia',
 			'GD' => 'Kelenatā',
 			'GE' => 'Seōsia',
 			'GF' => 'Kuiana fakafalanisē',
 			'GG' => 'Kuenisī',
 			'GH' => 'Kana',
 			'GI' => 'Sipalālitā',
 			'GL' => 'Kulinilani',
 			'GM' => 'Kamipia',
 			'GN' => 'Kini',
 			'GP' => 'Kuatalupe',
 			'GQ' => 'ʻEkueta Kini',
 			'GR' => 'Kalisi',
 			'GS' => 'ʻOtumotu Seōsia-tonga mo Saniuisi-tonga',
 			'GT' => 'Kuatamala',
 			'GU' => 'Kuamu',
 			'GW' => 'Kini-Pisau',
 			'GY' => 'Kuiana',
 			'HK' => 'Hongi Kongi SAR Siaina',
 			'HK@alt=short' => 'Hongi Kongi',
 			'HM' => 'ʻOtumotu Heati mo Makitonali',
 			'HN' => 'Honitulasi',
 			'HR' => 'Kuloisia',
 			'HT' => 'Haiti',
 			'HU' => 'Hungakalia',
 			'IC' => 'ʻOtumotu Kaneli',
 			'ID' => 'ʻInitonēsia',
 			'IE' => 'ʻAealani',
 			'IL' => 'ʻIsileli',
 			'IM' => 'Motu Mani',
 			'IN' => 'ʻInitia',
 			'IO' => 'Potu fonua moana ʻInitia fakapilitānia',
 			'IO@alt=chagos' => 'ʻOtu motu Sakōsi',
 			'IQ' => 'ʻIlaaki',
 			'IR' => 'ʻIlaani',
 			'IS' => 'ʻAisilani',
 			'IT' => 'ʻĪtali',
 			'JE' => 'Selusī',
 			'JM' => 'Samaika',
 			'JO' => 'Soatane',
 			'JP' => 'Siapani',
 			'KE' => 'Keniā',
 			'KG' => 'Kīkisitani',
 			'KH' => 'Kamipōtia',
 			'KI' => 'Kilipasi',
 			'KM' => 'Komolosi',
 			'KN' => 'Sā Kitisi mo Nevisi',
 			'KP' => 'Kōlea tokelau',
 			'KR' => 'Kōlea tonga',
 			'KW' => 'Kueiti',
 			'KY' => 'ʻOtumotu Keimeni',
 			'KZ' => 'Kasakitani',
 			'LA' => 'Lau',
 			'LB' => 'Lepanoni',
 			'LC' => 'Sā Lūsia',
 			'LI' => 'Likitenisiteini',
 			'LK' => 'Sīlangikā',
 			'LR' => 'Laipelia',
 			'LS' => 'Lesoto',
 			'LT' => 'Lituania',
 			'LU' => 'Lakisimipeki',
 			'LV' => 'Lativia',
 			'LY' => 'Līpia',
 			'MA' => 'Moloko',
 			'MC' => 'Monako',
 			'MD' => 'Molotova',
 			'ME' => 'Monitenikalo',
 			'MF' => 'Sā Mātini (fakafalanisē)',
 			'MG' => 'Matakasika',
 			'MH' => 'ʻOtumotu Māsolo',
 			'MK' => 'Masetōnia fakatokelau',
 			'ML' => 'Māli',
 			'MM' => 'Mianimā (Pema)',
 			'MN' => 'Mongokōlia',
 			'MO' => 'Makau SAR Siaina',
 			'MO@alt=short' => 'Makau',
 			'MP' => 'ʻOtumotu Maliana tokelau',
 			'MQ' => 'Mātiniki',
 			'MR' => 'Maulitenia',
 			'MS' => 'Moʻungaselati',
 			'MT' => 'Malita',
 			'MU' => 'Maulitiusi',
 			'MV' => 'Malativisi',
 			'MW' => 'Malaui',
 			'MX' => 'Mekisikou',
 			'MY' => 'Malēsia',
 			'MZ' => 'Mosēmipiki',
 			'NA' => 'Namipia',
 			'NC' => 'Niu Kaletōnia',
 			'NE' => 'Nisia',
 			'NF' => 'Motu Nōfoliki',
 			'NG' => 'Naisilia',
 			'NI' => 'Nikalakua',
 			'NL' => 'Hōlani',
 			'NO' => 'Noauē',
 			'NP' => 'Nepali',
 			'NR' => 'Naulu',
 			'NU' => 'Niuē',
 			'NZ' => 'Nuʻusila',
 			'NZ@alt=variant' => 'ʻAotealoa',
 			'OM' => 'ʻOmani',
 			'PA' => 'Panamā',
 			'PE' => 'Pelū',
 			'PF' => 'Polinisia fakafalanisē',
 			'PG' => 'Papuaniukini',
 			'PH' => 'Filipaini',
 			'PK' => 'Pākisitani',
 			'PL' => 'Polani',
 			'PM' => 'Sā Piea mo Mikeloni',
 			'PN' => 'ʻOtumotu Pitikeni',
 			'PR' => 'Puēto Liko',
 			'PS' => 'Potu Palesitaine',
 			'PS@alt=short' => 'Palesitaine',
 			'PT' => 'Potukali',
 			'PW' => 'Palau',
 			'PY' => 'Palakuai',
 			'QA' => 'Katā',
 			'QO' => 'ʻOsēnia mamaʻo',
 			'RE' => 'Lēunioni',
 			'RO' => 'Lomēnia',
 			'RS' => 'Sēpia',
 			'RU' => 'Lūsia',
 			'RW' => 'Luanitā',
 			'SA' => 'Saute ʻAlepea',
 			'SB' => 'ʻOtumotu Solomone',
 			'SC' => 'ʻOtumotu Seiseli',
 			'SD' => 'Sūteni',
 			'SE' => 'Suēteni',
 			'SG' => 'Singapoa',
 			'SH' => 'Sā Helena',
 			'SI' => 'Silōvenia',
 			'SJ' => 'Sivolopāti mo Sani Maieni',
 			'SK' => 'Silōvakia',
 			'SL' => 'Siela Leone',
 			'SM' => 'Sā Malino',
 			'SN' => 'Senekalo',
 			'SO' => 'Sōmalia',
 			'SR' => 'Suliname',
 			'SS' => 'Sūtani fakatonga',
 			'ST' => 'Sao Tomē mo Pilinisipe',
 			'SV' => 'ʻEle Salavatoa',
 			'SX' => 'Sā Mātini (fakahōlani)',
 			'SY' => 'Sīlia',
 			'SZ' => 'ʻEsuatini',
 			'SZ@alt=variant' => 'Suasilani',
 			'TA' => 'Tulisitani ta Kunuha',
 			'TC' => 'ʻOtumotu Tuki mo Kaikosi',
 			'TD' => 'Sāti',
 			'TF' => 'Potu fonua tonga fakafalanisē',
 			'TG' => 'Toko',
 			'TH' => 'Tailani',
 			'TJ' => 'Tasikitani',
 			'TK' => 'Tokelau',
 			'TL' => 'Timoa fakahahake',
 			'TM' => 'Tūkimenisitani',
 			'TN' => 'Tunīsia',
 			'TO' => 'Tonga',
 			'TR' => 'Toake',
 			'TT' => 'Tilinitati mo Topako',
 			'TV' => 'Tūvalu',
 			'TW' => 'Taiuani',
 			'TZ' => 'Tenisānia',
 			'UA' => 'ʻŪkalaʻine',
 			'UG' => 'ʻIukanitā',
 			'UM' => 'ʻOtumotu siʻi ʻo ʻAmelika',
 			'UN' => 'ʻŪ fonua fakatahataha',
 			'US' => 'Puleʻanga fakatahataha ʻAmelika',
 			'US@alt=short' => 'ʻAmelika',
 			'UY' => 'ʻUlukuai',
 			'UZ' => 'ʻUsipekitani',
 			'VA' => 'Kolo Vatikani',
 			'VC' => 'Sā Viniseni mo Kulenatini',
 			'VE' => 'Venesuela',
 			'VG' => 'ʻOtumotu Vilikini fakapilitānia',
 			'VI' => 'ʻOtumotu Vilikini fakaʻamelika',
 			'VN' => 'Vietinami',
 			'VU' => 'Vanuatu',
 			'WF' => 'ʻUvea mo Futuna',
 			'WS' => 'Haʻamoa',
 			'XA' => 'fasiʻalea loi',
 			'XB' => 'fua-ua loi',
 			'XK' => 'Kōsovo',
 			'YE' => 'Iemeni',
 			'YT' => 'Maiote',
 			'ZA' => 'ʻAfilika tonga',
 			'ZM' => 'Semipia',
 			'ZW' => 'Simipapuei',
 			'ZZ' => 'Potu fonua taʻeʻiloa pe hala',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'sipelatotonu ʻoe lea fakasiamane tukufakaholo',
 			'1994' => 'sipelatotonu fakasīpinga ʻo Lesia',
 			'1996' => 'sipelatotonu ʻoe lea fakasiamane 1996',
 			'1606NICT' => 'lea fakafalanisē fakaloto-tōmui',
 			'1694ACAD' => 'lea fakafalanisē fakaonopooni-tōmuʻa',
 			'1959ACAD' => 'fakaako',
 			'ABL1943' => 'sipelatotonu fokotuʻu 1943',
 			'AKUAPEM' => 'lea fakafeituʻu fakaʻakuapemi',
 			'ALALC97' => 'mataʻitohi liliu laipeli ʻamelika 1997',
 			'ALUKU' => 'lea fakafeituʻu fakaʻaluku',
 			'AO1990' => 'sipelatotonu ʻoe lea fakapotukali he 1990',
 			'ARANES' => 'lea fakafeituʻu fakaʻalanese',
 			'AREVELA' => 'lea fakaʻāmenia-hahake',
 			'AREVMDA' => 'lea fakaʻāmenia-hihifo',
 			'ARKAIKA' => 'lea fakaʻesepelanito-motuʻa',
 			'ASANTE' => 'lea fakafeituʻu fakaʻasanitē',
 			'AUVERN' => 'lea fakafeituʻu fakaʻauvēniati',
 			'BAKU1926' => 'motuʻalea fakalatina fakatahataha ki Toake',
 			'BALANKA' => 'lea fakafeituʻu fakapalanika ʻo Anii',
 			'BARLA' => 'lea fakafeituʻu fakapālavenito-pupunga',
 			'BASICENG' => 'lea fakapilitānia fakafaingofua',
 			'BAUDDHA' => 'lea fakafeituʻu fakaputa-sanisikiliti-tuifio',
 			'BISCAYAN' => 'lea fakafeituʻu fakapisikaea',
 			'BISKE' => 'lea fakafeituʻu fakapila mo fakasā-siōsio',
 			'BOHORIC' => 'motuʻalea fakapoholisi',
 			'BOONT' => 'lea fakafeituʻu fakapunavila',
 			'BORNHOLM' => 'lea fakafeituʻu fakapōnihōmi',
 			'CISAUP' => 'lea fakafeituʻu fakasisalipine',
 			'COLB1945' => 'sipelatotonu ʻoe lea fakapotukali-palāsili he 1945',
 			'CORNU' => 'lea fakafeituʻu fakakoanisi',
 			'CREISS' => 'lea fakafeituʻu fakaʻokisitania-kuasani',
 			'DAJNKO' => 'motuʻalea fakatainikō',
 			'EKAVSK' => 'lea fakasēpia (puʻaki fakaʻekavia)',
 			'EMODENG' => 'lea fakapilitānia fakonopooni-tōmuʻa',
 			'FONIPA' => 'fonētiki IPA',
 			'FONKIRSH' => 'lea fakafeituʻu fakakilisipaumi',
 			'FONNAPA' => 'fonētiki fakaʻamelika-tokelau',
 			'FONUPA' => 'fonētiki UPA',
 			'FONXSAMP' => 'fonētiki fakakomipiuta fakalahi',
 			'GALLO' => 'lea fakafeituʻu fakakalo',
 			'GASCON' => 'lea fakafeituʻu fakakasikō',
 			'GRCLASS' => 'lea fakafeituʻu fakaʻokisitania-motuʻa',
 			'GRITAL' => 'lea fakafeituʻu fakaʻokisitania-ʻĪtali',
 			'GRMISTR' => 'lea fakafeituʻu fakaʻokisitania-misitalali',
 			'HEPBURN' => 'mataʻitohi liliu fakahepipūnu',
 			'HOGNORSK' => 'lea fakafeituʻu fakanoauē-hake',
 			'HSISTEMO' => 'motuʻalea fonētiki fakaʻesipelanito-founga-H',
 			'IJEKAVSK' => 'lea fakasēpia (puʻaki fakaʻisekavia)',
 			'ITIHASA' => 'lea fakafeituʻu fakasanisikiliti-lave',
 			'IVANCHOV' => 'lea fakapulukalia-motuʻa',
 			'JAUER' => 'lea fakafeituʻu fakatiaue',
 			'JYUTPING' => 'mataʻitohi liliu fakakuangitongi',
 			'KKCOR' => 'sipelatotonu fakatatau',
 			'KOCIEWIE' => 'lea fakafeituʻu fakakosivie',
 			'KSCOR' => 'sipelatotonu fakasīpinga',
 			'LAUKIKA' => 'lea fakafeituʻu fakasanisikiliti-motuʻa',
 			'LEMOSIN' => 'lea fakafeituʻu fakalemosini',
 			'LENGADOC' => 'lea fakafeituʻu fakalangetoki',
 			'LIPAW' => 'lea fakafeituʻu fakalipovasi ʻo Lesia',
 			'LTG1929' => 'lea fakalatakalīsu (motuʻa)',
 			'LTG2007' => 'lea fakalatakalīsu (foʻou)',
 			'LUNA1918' => 'lea fakalūsia-soviete',
 			'METELKO' => 'motuʻalea fakametēliko',
 			'MONOTON' => 'fasiʻalea taha',
 			'NDYUKA' => 'lea fakafeituʻu fakanitiuka',
 			'NEDIS' => 'lea fakafeituʻu fakanatisone',
 			'NEWFOUND' => 'lea fakafeituʻu fakapilitānia-fonua-ʻilo-foʻou',
 			'NICARD' => 'lea fakafeituʻu fakanisāti',
 			'NJIVA' => 'lea fakafeituʻu fakangiva',
 			'NULIK' => 'lea fakavolapuki fakaonopooni',
 			'OSOJS' => 'lea fakafeituʻu fakaʻoseako',
 			'OXENDICT' => 'sipelatotonu fakapilitānia tikisinale fakaʻokisifooti',
 			'PAHAWH2' => 'lea fakafeituʻu pahau-mongi, sitepu hono ua',
 			'PAHAWH3' => 'lea fakafeituʻu pahau-mongi, sitepu hono tolu',
 			'PAHAWH4' => 'lea fakafeituʻu pahau-mongi, sitepu hono fā',
 			'PAMAKA' => 'lea fakafeituʻu fakapamaka',
 			'PEANO' => 'lea fakalatina-peano',
 			'PETR1708' => 'lea fakafeituʻu fakalūsia-peterine',
 			'PINYIN' => 'mataʻitohi liliu fakapīnīni',
 			'POLYTON' => 'fasiʻalea lahi',
 			'POSIX' => 'fakakomipiuta',
 			'PROVENC' => 'lea fakafeituʻu fakapolevenise',
 			'PUTER' => 'lea fakafeituʻu fakaputeli',
 			'REVISED' => 'sipelatotonu kuo sivi',
 			'RIGIK' => 'lea fakavolapuki motuʻa',
 			'ROZAJ' => 'lea fakafeituʻu fakalesia',
 			'RUMGR' => 'lea fakafeituʻu fakakilisone',
 			'SAAHO' => 'lea fakasaho',
 			'SCOTLAND' => 'lea fakasikotilani fakasīpinga',
 			'SCOUSE' => 'lea fakafeituʻu fakasikause',
 			'SIMPLE' => 'motuʻalea fakangofua',
 			'SOLBA' => 'lea fakafeituʻu fakasolipika',
 			'SOTAV' => 'lea fakafeituʻu fakasotavenito-pupunga',
 			'SPANGLIS' => 'lea fakapilitānia-sipeini-tuifio',
 			'SURMIRAN' => 'lea fakafeituʻu fakasulimila',
 			'SURSILV' => 'lea fakafeituʻu fakasulisiliva',
 			'SUTSILV' => 'lea fakafeituʻu fakasutisiliva',
 			'SYNNEJYL' => 'lea fakafeituʻu fakafonuasuti',
 			'TARASK' => 'sipelatotunu fakatalasikievika',
 			'TONGYONG' => 'lea fakafeituʻu fakasiaina-tōngiongi',
 			'TUNUMIIT' => 'lea fakafeituʻu fakatunimīti',
 			'UCCOR' => 'sipelatotonu fakatahataha',
 			'UCRCOR' => 'sipelatotonu fakatahataha kuo sivi',
 			'ULSTER' => 'lea fakafeituʻu fakaʻulisitā',
 			'UNIFON' => 'motuʻalea fonētiki ʻo Unifoni',
 			'VAIDIKA' => 'lea fakafeituʻu fakasanisikiliti-vetā',
 			'VALENCIA' => 'lea fakafeituʻu fakavalenisia',
 			'VALLADER' => 'lea fakafeituʻu fakavalate',
 			'VECDRUKA' => 'lea fakafeituʻu fakalativia-vekātuluka',
 			'VIVARAUP' => 'lea fakafeituʻu fakavivalo-alapeno',
 			'WADEGILE' => 'mataʻitohi liliu fakauate-kilesi',
 			'XSISTEMO' => 'motuʻalea fonētiki fakaʻesipelanito-founga-X',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'tohi māhina',
 			'cf' => 'anga paʻanga',
 			'collation' => 'tohi hokohoko',
 			'currency' => 'paʻanga',
 			'hc' => 'takai houa',
 			'lb' => 'fesiʻilaine',
 			'ms' => 'founga fakafuofua',
 			'numbers' => 'fika',

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
 				'buddhist' => q{fakaputa},
 				'chinese' => q{fakasiaina},
 				'coptic' => q{fakakopitika},
 				'dangi' => q{fakataniki},
 				'ethiopic' => q{fakaʻītiōpia},
 				'ethiopic-amete-alem' => q{fakaʻītiōpia-ʻamete-ʻalemi},
 				'gregorian' => q{fakakelekolia},
 				'hebrew' => q{fakahepelū},
 				'indian' => q{fakaʻinitia},
 				'islamic' => q{fakamohameti},
 				'islamic-civil' => q{fakamohameti-sivile},
 				'islamic-rgsa' => q{fakamohameti-ʻasimāhina},
 				'islamic-tbla' => q{fakamohameti -fakatēpile},
 				'islamic-umalqura' => q{fakamohameti-ʻumalakula},
 				'iso8601' => q{faka-iso8601},
 				'japanese' => q{fakasiapani},
 				'persian' => q{fakapēsia},
 				'roc' => q{fakalepupelika siaina},
 			},
 			'cf' => {
 				'account' => q{anga paʻanga-kalake},
 				'standard' => q{anga paʻanga-sīpinga},
 			},
 			'collation' => {
 				'big5han' => q{siaina-nimalahi},
 				'compat' => q{ki muʻa, hoa},
 				'dictionary' => q{tikisinale},
 				'ducet' => q{ʻunikōti},
 				'emoji' => q{ngaahi ongo},
 				'eor' => q{fakaʻeulope},
 				'gb2312han' => q{siaina-fakafaingofua},
 				'phonebook' => q{fika telefoni},
 				'pinyin' => q{piniini},
 				'reformed' => q{fakafoʻou},
 				'search' => q{fakakumi ʻi hono anga lahi},
 				'searchjl' => q{konisinanite ʻuluaki},
 				'standard' => q{fakasīpinga},
 				'stroke' => q{tongi},
 				'traditional' => q{tukufakaholo},
 				'unihan' => q{tongi tefitoʻi},
 				'zhuyin' => q{sūini},
 			},
 			'hc' => {
 				'h11' => q{takai houa 0–11},
 				'h12' => q{takai houa 1–12},
 				'h23' => q{takai houa 0–23},
 				'h24' => q{takai houa 1–24},
 			},
 			'lb' => {
 				'loose' => q{fesiʻilaine ngaloku},
 				'normal' => q{fesiʻilaine faʻafai},
 				'strict' => q{fesiʻilaine mafao},
 			},
 			'ms' => {
 				'metric' => q{founga fakamita},
 				'uksystem' => q{founga fakapilitānia},
 				'ussystem' => q{founga fakaʻamelika},
 			},
 			'numbers' => {
 				'ahom' => q{fika fakaʻahomi},
 				'arab' => q{fika fakaʻalepea},
 				'arabext' => q{fika fakaʻalepea fakalahi},
 				'armn' => q{fika fakaʻāmenia},
 				'armnlow' => q{fika fakaʻāmenia fakalalo},
 				'bali' => q{fika fakapali},
 				'beng' => q{faka fakapāngilā},
 				'brah' => q{fika fakapalami},
 				'cakm' => q{fika fakakakema},
 				'cham' => q{fika fakakami},
 				'cyrl' => q{fika fakalūsia},
 				'deva' => q{fika fakatevanākalī},
 				'diak' => q{fika fakativehi-akuru},
 				'ethi' => q{fika fakaʻītiōpia},
 				'fullwide' => q{fika laulahi},
 				'geor' => q{fika fakaseōsia},
 				'gong' => q{fika fakakoniti-kunisala},
 				'gonm' => q{fika fakakoniti–masalami},
 				'grek' => q{fika fakakalisi},
 				'greklow' => q{fika fakakalisi fakalalo},
 				'gujr' => q{fika fakakutalati},
 				'guru' => q{fika fakakūmuki},
 				'hanidec' => q{fika fakasiaina},
 				'hans' => q{fika fakasiaina fakafaingofua},
 				'hansfin' => q{fika fakasiaina fakafaingofua fakapaʻanga},
 				'hant' => q{fika fakasiaina tukufakaholo},
 				'hantfin' => q{fika fakasiaina tukufakaholo fakapaʻanga},
 				'hebr' => q{fika fakahepelū},
 				'hmng' => q{fika fakamōngi-pahau},
 				'hmnp' => q{fika fakamōngi-niakengi},
 				'java' => q{fika fakasava},
 				'jpan' => q{fika fakasiapani},
 				'jpanfin' => q{fika fakasiapani fakapaʻanga},
 				'kali' => q{fika fakakaialī},
 				'kawi' => q{fika fakakaui},
 				'khmr' => q{fika fakakamipōtia},
 				'knda' => q{fika fakakanata},
 				'lana' => q{fika fakatai-tami-hola},
 				'lanatham' => q{fika fakatai-tami-tami},
 				'laoo' => q{fika fakalau},
 				'latn' => q{fika fakalatina},
 				'lepc' => q{fika fakalepasā},
 				'limb' => q{fika fakalimipū},
 				'mathbold' => q{fika fakamatematika-lotolahi},
 				'mathdbl' => q{fika fakamatematika-tukiua},
 				'mathmono' => q{fika fakamatematika-vahataha},
 				'mathsanb' => q{fika fakamatematika-taʻehiku-lotolahi},
 				'mathsans' => q{fika fakamatematika-taʻehiku},
 				'mlym' => q{fika fakamalāialami},
 				'modi' => q{fika fakamotī},
 				'mong' => q{fika fakamongokōlia},
 				'mroo' => q{fika fakamolō},
 				'mtei' => q{fika fakametei-maieki},
 				'mymr' => q{fika fakapema},
 				'mymrshan' => q{fika fakapema-siani},
 				'mymrtlng' => q{fika fakapema-tai},
 				'nagm' => q{fika fakamunitali-naki},
 				'nkoo' => q{fika fakanikō},
 				'olck' => q{fika fakaʻolisiki},
 				'orya' => q{fika fakaʻotia},
 				'osma' => q{fika fakaʻosimania},
 				'rohg' => q{fika fakalohingia-hanifi},
 				'roman' => q{fika fakaloma},
 				'romanlow' => q{fika fakaloma fakalalo},
 				'saur' => q{fika fakasaulasitā},
 				'shrd' => q{fika fakasalata},
 				'sind' => q{fika fakakutasuāti},
 				'sinh' => q{fika fakasingihala},
 				'sora' => q{fika fakasola-somipenga},
 				'sund' => q{fika fakasunitā},
 				'takr' => q{fika fakatakili},
 				'talu' => q{fika fakatai-lue foʻou},
 				'taml' => q{fika fakatamili tukufakaholo},
 				'tamldec' => q{fika fakatamili},
 				'telu' => q{fika fakateluku},
 				'thai' => q{fika fakatailani},
 				'tibt' => q{fika fakatipeti},
 				'tirh' => q{fika fakatīhuta},
 				'tnsa' => q{fika fakatangisā},
 				'vaii' => q{fika fakavai},
 				'wara' => q{fika fakavalangi},
 				'wcho' => q{fika fakauāniko},
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
			'metric' => q{fakamita},
 			'UK' => q{fakapilitānia},
 			'US' => q{fakaʻamelika},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Lea: {0}',
 			'script' => 'Tohinima: {0}',
 			'region' => 'Feituʻu: {0}',

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
			auxiliary => qr{[àăâåä æ b cç d èĕêë g ìĭîï j ñ òŏôöø œ q r ùŭûü w x yÿ z]},
			index => ['A', 'E', 'F', 'H', 'I', 'K', 'L', 'M', 'N', '{NG}', 'O', 'P', 'S', 'T', 'U', 'V', 'ʻ'],
			main => qr{[aáā eéē f h iíī k l m n {ng} oóō p s t uúū v ʻ]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['A', 'E', 'F', 'H', 'I', 'K', 'L', 'M', 'N', '{NG}', 'O', 'P', 'S', 'T', 'U', 'V', 'ʻ'], };
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
						'name' => q(fua tefitoʻi),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(fua tefitoʻi),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(kipi{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(kipi{0}),
					},
					# Long Unit Identifier
					'1024p2' => {
						'1' => q(Mepi{0}),
					},
					# Core Unit Identifier
					'1024p2' => {
						'1' => q(Mepi{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(Kipi{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(Kipi{0}),
					},
					# Long Unit Identifier
					'1024p4' => {
						'1' => q(Tepi{0}),
					},
					# Core Unit Identifier
					'1024p4' => {
						'1' => q(Tepi{0}),
					},
					# Long Unit Identifier
					'1024p5' => {
						'1' => q(Pepi{0}),
					},
					# Core Unit Identifier
					'1024p5' => {
						'1' => q(Pepi{0}),
					},
					# Long Unit Identifier
					'1024p6' => {
						'1' => q(Ēkipi{0}),
					},
					# Core Unit Identifier
					'1024p6' => {
						'1' => q(Ēkipi{0}),
					},
					# Long Unit Identifier
					'1024p7' => {
						'1' => q(Sepi{0}),
					},
					# Core Unit Identifier
					'1024p7' => {
						'1' => q(Sepi{0}),
					},
					# Long Unit Identifier
					'1024p8' => {
						'1' => q(Iopi{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(Iopi{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(tesi{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(tesi{0}),
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
						'1' => q(fēmito{0}),
					},
					# Core Unit Identifier
					'15' => {
						'1' => q(fēmito{0}),
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
						'1' => q(seniti{0}),
					},
					# Core Unit Identifier
					'2' => {
						'1' => q(seniti{0}),
					},
					# Long Unit Identifier
					'10p-21' => {
						'1' => q(sēpito{0}),
					},
					# Core Unit Identifier
					'21' => {
						'1' => q(sēpito{0}),
					},
					# Long Unit Identifier
					'10p-24' => {
						'1' => q(iōkito{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(iōkito{0}),
					},
					# Long Unit Identifier
					'10p-27' => {
						'1' => q(lonito{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(lonito{0}),
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
						'1' => q(kuekito{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(kuekito{0}),
					},
					# Long Unit Identifier
					'10p-6' => {
						'1' => q(maikolo{0}),
					},
					# Core Unit Identifier
					'6' => {
						'1' => q(maikolo{0}),
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
						'1' => q(teka{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(teka{0}),
					},
					# Long Unit Identifier
					'10p12' => {
						'1' => q(tela{0}),
					},
					# Core Unit Identifier
					'10p12' => {
						'1' => q(tela{0}),
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
						'1' => q(ēkisa{0}),
					},
					# Core Unit Identifier
					'10p18' => {
						'1' => q(ēkisa{0}),
					},
					# Long Unit Identifier
					'10p2' => {
						'1' => q(hēkito{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hēkito{0}),
					},
					# Long Unit Identifier
					'10p21' => {
						'1' => q(seta{0}),
					},
					# Core Unit Identifier
					'10p21' => {
						'1' => q(seta{0}),
					},
					# Long Unit Identifier
					'10p24' => {
						'1' => q(iota{0}),
					},
					# Core Unit Identifier
					'10p24' => {
						'1' => q(iota{0}),
					},
					# Long Unit Identifier
					'10p27' => {
						'1' => q(lona{0}),
					},
					# Core Unit Identifier
					'10p27' => {
						'1' => q(lona{0}),
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
						'1' => q(kueta{0}),
					},
					# Core Unit Identifier
					'10p30' => {
						'1' => q(kueta{0}),
					},
					# Long Unit Identifier
					'10p6' => {
						'1' => q(meka{0}),
					},
					# Core Unit Identifier
					'10p6' => {
						'1' => q(meka{0}),
					},
					# Long Unit Identifier
					'10p9' => {
						'1' => q(kika{0}),
					},
					# Core Unit Identifier
					'10p9' => {
						'1' => q(kika{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(k-mālohi),
						'other' => q(k-mālohi ʻe {0}),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(k-mālohi),
						'other' => q(k-mālohi ʻe {0}),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(mita he sekoni sikuea),
						'other' => q(mita he sekoni sikuea ʻe {0}),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(mita he sekoni sikuea),
						'other' => q(mita he sekoni sikuea ʻe {0}),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(miniti seakale),
						'other' => q(miniti seakale ʻe {0}),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(miniti seakale),
						'other' => q(miniti seakale ʻe {0}),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(sekoni seakale),
						'other' => q(sekoni seakale ʻe {0}),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(sekoni seakale),
						'other' => q(sekoni seakale ʻe {0}),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(tikili seakale),
						'other' => q(tikili seakale ʻe {0}),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(tikili seakale),
						'other' => q(tikili seakale ʻe {0}),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(lētiani),
						'other' => q(lētiani ʻe {0}),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(lētiani),
						'other' => q(lētiani ʻe {0}),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(takai),
						'other' => q(takai ʻe {0}),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(takai),
						'other' => q(takai ʻe {0}),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ʻeka),
						'other' => q(ʻeka ʻe {0}),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ʻeka),
						'other' => q(ʻeka ʻe {0}),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hekitale),
						'other' => q(hekitale ʻe {0}),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hekitale),
						'other' => q(hekitale ʻe {0}),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(senitimita sikuea),
						'other' => q(senitimita sikuea ʻe {0}),
						'per' => q({0} he senitimita sikuea),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(senitimita sikuea),
						'other' => q(senitimita sikuea ʻe {0}),
						'per' => q({0} he senitimita sikuea),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(fute sikuea),
						'other' => q(fute sikuea ʻe {0}),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(fute sikuea),
						'other' => q(fute sikuea ʻe {0}),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(ʻinisi sikuea),
						'other' => q(ʻinisi sikuea ʻe {0}),
						'per' => q({0} he ʻinisi sikuea),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(ʻinisi sikuea),
						'other' => q(ʻinisi sikuea ʻe {0}),
						'per' => q({0} he ʻinisi sikuea),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(kilomita sikuea),
						'other' => q(kilomita sikuea ʻe {0}),
						'per' => q({0} ki he kilomita sikuea),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(kilomita sikuea),
						'other' => q(kilomita sikuea ʻe {0}),
						'per' => q({0} ki he kilomita sikuea),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(mita sikuea),
						'other' => q(mita sikuea ʻe {0}),
						'per' => q({0} he mita sikuea),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(mita sikuea),
						'other' => q(mita sikuea ʻe {0}),
						'per' => q({0} he mita sikuea),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(maile sikuea),
						'other' => q(maile sikuea ʻe {0}),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(maile sikuea),
						'other' => q(maile sikuea ʻe {0}),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(iate sikuea),
						'other' => q(iate sikuea ʻe {0}),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(iate sikuea),
						'other' => q(iate sikuea ʻe {0}),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(kongokonga),
						'other' => q(kongokonga ʻe {0}),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(kongokonga),
						'other' => q(kongokonga ʻe {0}),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(kalati),
						'other' => q(kalati ʻe {0}),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(kalati),
						'other' => q(kalati ʻe {0}),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(milikalami he tesilita),
						'other' => q(milikalami ʻe {0} he tesilita),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(milikalami he tesilita),
						'other' => q(milikalami ʻe {0} he tesilita),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(milimole he lita),
						'other' => q(milimole ʻe {0} he lita),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(milimole he lita),
						'other' => q(milimole ʻe {0} he lita),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(molo),
						'other' => q(molo ʻe {0}),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(molo),
						'other' => q(molo ʻe {0}),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(peseti),
						'other' => q(peseti ʻe {0}),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(peseti),
						'other' => q(peseti ʻe {0}),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(pemili),
						'other' => q(pemili ʻe {0}),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(pemili),
						'other' => q(pemili ʻe {0}),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(konga he miliona),
						'other' => q(konga ʻe {0} he miliona),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(konga he miliona),
						'other' => q(konga ʻe {0} he miliona),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(pemano),
						'other' => q(pemano ʻe {0}),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(pemano),
						'other' => q(pemano ʻe {0}),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(lita he kilomita ʻe 100),
						'other' => q(lita ʻe {0} he kilomita ʻe 100),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(lita he kilomita ʻe 100),
						'other' => q(lita ʻe {0} he kilomita ʻe 100),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(lita he kilomita),
						'other' => q(lita ʻe {0} he kilomita),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(lita he kilomita),
						'other' => q(lita ʻe {0} he kilomita),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(maile he kālani),
						'other' => q(maile ʻe {0} he kālani),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(maile he kālani),
						'other' => q(maile ʻe {0} he kālani),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(maile he kālani fakaʻemipaea),
						'other' => q(maile ʻe {0} he kālani fakaʻemipaea),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(maile he kālani fakaʻemipaea),
						'other' => q(maile ʻe {0} he kālani fakaʻemipaea),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q(hahake ʻe {0}),
						'north' => q(tokelau ʻe {0}),
						'south' => q(tonga ʻe {0}),
						'west' => q(hihifo ʻe {0}),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q(hahake ʻe {0}),
						'north' => q(tokelau ʻe {0}),
						'south' => q(tonga ʻe {0}),
						'west' => q(hihifo ʻe {0}),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'other' => q(kikapiti ʻe {0}),
					},
					# Core Unit Identifier
					'gigabit' => {
						'other' => q(kikapiti ʻe {0}),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'other' => q(kikapaiti ʻe {0}),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'other' => q(kikapaiti ʻe {0}),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'other' => q(kilopiti ʻe {0}),
					},
					# Core Unit Identifier
					'kilobit' => {
						'other' => q(kilopiti ʻe {0}),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'other' => q(kilopaiti ʻe {0}),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'other' => q(kilopaiti ʻe {0}),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'other' => q(mekapiti ʻe {0}),
					},
					# Core Unit Identifier
					'megabit' => {
						'other' => q(mekapiti ʻe {0}),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'other' => q(mekapaiti ʻe {0}),
					},
					# Core Unit Identifier
					'megabyte' => {
						'other' => q(mekapaiti ʻe {0}),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'other' => q(petapaiti ʻe {0}),
					},
					# Core Unit Identifier
					'petabyte' => {
						'other' => q(petapaiti ʻe {0}),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'other' => q(telapiti ʻe {0}),
					},
					# Core Unit Identifier
					'terabit' => {
						'other' => q(telapiti ʻe {0}),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'other' => q(telapaiti ʻe {0}),
					},
					# Core Unit Identifier
					'terabyte' => {
						'other' => q(telapaiti ʻe {0}),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(teautaʻu),
						'other' => q(teautaʻu ʻe {0}),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(teautaʻu),
						'other' => q(teautaʻu ʻe {0}),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ʻaho),
						'other' => q(ʻaho ʻe {0}),
						'per' => q({0} he ʻaho),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ʻaho),
						'other' => q(ʻaho ʻe {0}),
						'per' => q({0} he ʻaho),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(honofuluʻitaʻu),
						'other' => q(honofuluʻitaʻu ʻe {0}),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(honofuluʻitaʻu),
						'other' => q(honofuluʻitaʻu ʻe {0}),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(houa),
						'other' => q(houa ʻe {0}),
						'per' => q({0} ki he houa),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(houa),
						'other' => q(houa ʻe {0}),
						'per' => q({0} ki he houa),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(mikolosekoni),
						'other' => q(mikolosekoni ʻe {0}),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(mikolosekoni),
						'other' => q(mikolosekoni ʻe {0}),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(milisekoni),
						'other' => q(milisekoni ʻe {0}),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(milisekoni),
						'other' => q(milisekoni ʻe {0}),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(miniti),
						'other' => q(miniti ʻe {0}),
						'per' => q({0} he miniti),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(miniti),
						'other' => q(miniti ʻe {0}),
						'per' => q({0} he miniti),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(māhina),
						'other' => q(māhina ʻe {0}),
						'per' => q({0} he māhina),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(māhina),
						'other' => q(māhina ʻe {0}),
						'per' => q({0} he māhina),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(nanosekoni),
						'other' => q(nanosekoni ʻe {0}),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(nanosekoni),
						'other' => q(nanosekoni ʻe {0}),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'per' => q({0} he kuata),
					},
					# Core Unit Identifier
					'quarter' => {
						'per' => q({0} he kuata),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(sekoni),
						'other' => q(sekoni ʻe {0}),
						'per' => q({0} ki he sekoni),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(sekoni),
						'other' => q(sekoni ʻe {0}),
						'per' => q({0} ki he sekoni),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(uike),
						'other' => q(uike ʻe {0}),
						'per' => q({0} he uike),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(uike),
						'other' => q(uike ʻe {0}),
						'per' => q({0} he uike),
					},
					# Long Unit Identifier
					'duration-year' => {
						'per' => q({0} he taʻu),
					},
					# Core Unit Identifier
					'year' => {
						'per' => q({0} he taʻu),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ʻamipele),
						'other' => q(ʻamipele ʻe {0}),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ʻamipele),
						'other' => q(ʻamipele ʻe {0}),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(miliʻamipele),
						'other' => q(miliʻamipele ʻe {0}),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(miliʻamipele),
						'other' => q(miliʻamipele ʻe {0}),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ʻōmi),
						'other' => q(ʻōmi ʻe {0}),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ʻōmi),
						'other' => q(ʻōmi ʻe {0}),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'other' => q(volotā ʻe {0}),
					},
					# Core Unit Identifier
					'volt' => {
						'other' => q(volotā ʻe {0}),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(ʻiuniti māfana fakapilitānia),
						'other' => q(ʻiuniti māfana fakapilitānia ʻe {0}),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(ʻiuniti māfana fakapilitānia),
						'other' => q(ʻiuniti māfana fakapilitānia ʻe {0}),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kaloli),
						'other' => q(kaloli ʻe {0}),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kaloli),
						'other' => q(kaloli ʻe {0}),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(volotāʻelekitō),
						'other' => q(volotāʻelekitō ʻe {0}),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(volotāʻelekitō),
						'other' => q(volotāʻelekitō ʻe {0}),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(kaloli-kai),
						'other' => q(kaloli-kai ʻe {0}),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(kaloli-kai),
						'other' => q(kaloli-kai ʻe {0}),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(siule),
						'other' => q(siule ʻe {0}),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(siule),
						'other' => q(siule ʻe {0}),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kilokaloli),
						'other' => q(kilokaloli ʻe {0}),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kilokaloli),
						'other' => q(kilokaloli ʻe {0}),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kilosiule),
						'other' => q(kilosiule ʻe {0}),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kilosiule),
						'other' => q(kilosiule ʻe {0}),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kilouate-houa),
						'other' => q(kilouate-houa ʻe {0}),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kilouate-houa),
						'other' => q(kilouate-houa ʻe {0}),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(ʻiuniti māfana fakaʻamelika),
						'other' => q(ʻiuniti māfana fakaʻamelika ʻe {0}),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(ʻiuniti māfana fakaʻamelika),
						'other' => q(ʻiuniti māfana fakaʻamelika ʻe {0}),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilouate-houa he kilomita ʻe 100),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(kilouate-houa he kilomita ʻe 100),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(Niutoni),
						'other' => q(Niutoni ʻe {0}),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(Niutoni),
						'other' => q(Niutoni ʻe {0}),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(pāunimālohi),
						'other' => q(pāunimālohi ʻe {0}),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pāunimālohi),
						'other' => q(pāunimālohi ʻe {0}),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(kikahēti),
						'other' => q(kikahēti ʻe {0}),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(kikahēti),
						'other' => q(kikahēti ʻe {0}),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(hēti),
						'other' => q(hēti ʻe {0}),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(hēti),
						'other' => q(hēti ʻe {0}),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(kilohēti),
						'other' => q(kilohēti ʻe {0}),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(kilohēti),
						'other' => q(kilohēti ʻe {0}),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(megahēti),
						'other' => q(megahēti ʻe {0}),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(megahēti),
						'other' => q(megahēti ʻe {0}),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(toti he senitimita),
						'other' => q(toti ʻe {0} he senitimita),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(toti he senitimita),
						'other' => q(toti ʻe {0} he senitimita),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(toti he ʻinisi),
						'other' => q(toti ʻe {0} he ʻinisi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(toti he ʻinisi),
						'other' => q(toti ʻe {0} he ʻinisi),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(ʻemi fakataipe),
						'other' => q(ʻemi fakataipe ʻe {0}),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(ʻemi fakataipe),
						'other' => q(ʻemi fakataipe ʻe {0}),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(Mekameʻatā),
						'other' => q(Mekameʻatā ʻe {0}),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(Mekameʻatā),
						'other' => q(Mekameʻatā ʻe {0}),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(meʻatā he senitimita),
						'other' => q(meʻatā ʻe {0} he senitimita),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(meʻatā he senitimita),
						'other' => q(meʻatā ʻe {0} he senitimita),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(meʻatā he ʻinisi),
						'other' => q(meʻatā ʻe {0} he ʻinisi),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(meʻatā he ʻinisi),
						'other' => q(meʻatā ʻe {0} he ʻinisi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(ʻiuniti fakaʻasitalōnoma),
						'other' => q(ʻiuniti fakaʻasitalōnoma ʻe {0}),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ʻiuniti fakaʻasitalōnoma),
						'other' => q(ʻiuniti fakaʻasitalōnoma ʻe {0}),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(senitimita),
						'other' => q(senitimita ʻe {0}),
						'per' => q({0} he senitimita),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(senitimita),
						'other' => q(senitimita ʻe {0}),
						'per' => q({0} he senitimita),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(tesimita),
						'other' => q(tesimita ʻe {0}),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(tesimita),
						'other' => q(tesimita ʻe {0}),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(lētiasi fakamāmani),
						'other' => q(lētiasi fakamāmani ʻe {0}),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(lētiasi fakamāmani),
						'other' => q(lētiasi fakamāmani ʻe {0}),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(fute),
						'other' => q(fute ʻe {0}),
						'per' => q({0} he fute),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(fute),
						'other' => q(fute ʻe {0}),
						'per' => q({0} he fute),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(fālongo),
						'other' => q(fālongo ʻe {0}),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(fālongo),
						'other' => q(fālongo ʻe {0}),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(ʻinisi),
						'other' => q(ʻinisi ʻe {0}),
						'per' => q({0} he ʻinisi),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(ʻinisi),
						'other' => q(ʻinisi ʻe {0}),
						'per' => q({0} he ʻinisi),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(kilomita),
						'other' => q(kilomita ʻe {0}),
						'per' => q({0} he kilomita),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(kilomita),
						'other' => q(kilomita ʻe {0}),
						'per' => q({0} he kilomita),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(taʻumaama),
						'other' => q(taʻumaama ʻe {0}),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(taʻumaama),
						'other' => q(taʻumaama ʻe {0}),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(mita),
						'other' => q(mita ʻe {0}),
						'per' => q({0} he mita),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(mita),
						'other' => q(mita ʻe {0}),
						'per' => q({0} he mita),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(maikolomita),
						'other' => q(maikolomita ʻe {0}),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(maikolomita),
						'other' => q(maikolomita ʻe {0}),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(maile),
						'other' => q(maile ʻe {0}),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(maile),
						'other' => q(maile ʻe {0}),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(maile fakasikanitinavia),
						'other' => q(maile fakasikanitinavia ʻe {0}),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(maile fakasikanitinavia),
						'other' => q(maile fakasikanitinavia ʻe {0}),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(milimita),
						'other' => q(milimita ʻe {0}),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(milimita),
						'other' => q(milimita ʻe {0}),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(nanomita),
						'other' => q(nanomita ʻe {0}),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(nanomita),
						'other' => q(nanomita ʻe {0}),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(maile ʻi tahi),
						'other' => q(maile ʻi tahi ʻe {0}),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(maile ʻi tahi),
						'other' => q(maile ʻi tahi ʻe {0}),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(ngaofesekoni),
						'other' => q(ngaofesekoni ʻe {0}),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(ngaofesekoni),
						'other' => q(ngaofesekoni ʻe {0}),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(pikomita),
						'other' => q(pikomita ʻe {0}),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(pikomita),
						'other' => q(pikomita ʻe {0}),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(poini),
						'other' => q(poini ʻe {0}),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(poini),
						'other' => q(poini ʻe {0}),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(lētiasi fakalaʻā),
						'other' => q(lētiasi fakalaʻā ʻe {0}),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(lētiasi fakalaʻā),
						'other' => q(lētiasi fakalaʻā ʻe {0}),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(iate),
						'other' => q(iate ʻe {0}),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(iate),
						'other' => q(iate ʻe {0}),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(kaniteli),
						'other' => q(kaniteli ʻe {0}),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(kaniteli),
						'other' => q(kaniteli ʻe {0}),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(lumeni),
						'other' => q(lumeni ʻe {0}),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(lumeni),
						'other' => q(lumeni ʻe {0}),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(lukisi),
						'other' => q(lukisi ʻe {0}),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(lukisi),
						'other' => q(lukisi ʻe {0}),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(huhulu fakalaʻā),
						'other' => q(huhulu fakalaʻā ʻe {0}),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(huhulu fakalaʻā),
						'other' => q(huhulu fakalaʻā ʻe {0}),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(kalati),
						'other' => q(kalati ʻe {0}),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(kalati),
						'other' => q(kalati ʻe {0}),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(talatoni),
						'other' => q(talatoni ʻe {0}),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(talatoni),
						'other' => q(talatoni ʻe {0}),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(mamafa ʻo māmani),
						'other' => q(mamafa ʻo māmani ʻe {0}),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(mamafa ʻo māmani),
						'other' => q(mamafa ʻo māmani ʻe {0}),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(kalami),
						'other' => q(kalami ʻe {0}),
						'per' => q({0} he kalami),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(kalami),
						'other' => q(kalami ʻe {0}),
						'per' => q({0} he kalami),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kilokalami),
						'other' => q(kilokalami ʻe {0}),
						'per' => q({0} he kilokalami),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kilokalami),
						'other' => q(kilokalami ʻe {0}),
						'per' => q({0} he kilokalami),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(maikolokalami),
						'other' => q(maikolokalami ʻe {0}),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(maikolokalami),
						'other' => q(maikolokalami ʻe {0}),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(milikalami),
						'other' => q(milikalami ʻe {0}),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(milikalami),
						'other' => q(milikalami ʻe {0}),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(ʻaunise),
						'other' => q(ʻaunisi ʻe {0}),
						'per' => q({0} he ʻaunise),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(ʻaunise),
						'other' => q(ʻaunisi ʻe {0}),
						'per' => q({0} he ʻaunise),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(ʻaunisi koula),
						'other' => q(ʻaunisi koula ʻe {0}),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(ʻaunisi koula),
						'other' => q(ʻaunisi koula ʻe {0}),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(pāuni),
						'other' => q(pāuni ʻe {0}),
						'per' => q({0} he pāuni),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(pāuni),
						'other' => q(pāuni ʻe {0}),
						'per' => q({0} he pāuni),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(mamafa ʻo e laʻā),
						'other' => q(mamafa ʻo e laʻā ʻe {0}),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(mamafa ʻo e laʻā),
						'other' => q(mamafa ʻo e laʻā ʻe {0}),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(sitoni),
						'other' => q(sitoni ʻe {0}),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(sitoni),
						'other' => q(sitoni ʻe {0}),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(toni nounou),
						'other' => q(toni nounou ʻe {0}),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(toni nounou),
						'other' => q(toni nounou ʻe {0}),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(toni),
						'other' => q(toni ʻe {0}),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(toni),
						'other' => q(toni ʻe {0}),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} ʻi he {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} ʻi he {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(kikauate),
						'other' => q(kikauate ʻe {0}),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(kikauate),
						'other' => q(kikauate ʻe {0}),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(hoosipaoa),
						'other' => q(hoosipaoa ʻe {0}),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(hoosipaoa),
						'other' => q(hoosipaoa ʻe {0}),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(kilouate),
						'other' => q(kilouate ʻe {0}),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(kilouate),
						'other' => q(kilouate ʻe {0}),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(mekauate),
						'other' => q(mekauate ʻe {0}),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(mekauate),
						'other' => q(mekauate ʻe {0}),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(miliuate),
						'other' => q(miliuate ʻe {0}),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(miliuate),
						'other' => q(miliuate ʻe {0}),
					},
					# Long Unit Identifier
					'power-watt' => {
						'other' => q(uate ʻe {0}),
					},
					# Core Unit Identifier
					'watt' => {
						'other' => q(uate ʻe {0}),
					},
					# Long Unit Identifier
					'power2' => {
						'other' => q({0} sikuea),
					},
					# Core Unit Identifier
					'power2' => {
						'other' => q({0} sikuea),
					},
					# Long Unit Identifier
					'power3' => {
						'other' => q({0} kiupite),
					},
					# Core Unit Identifier
					'power3' => {
						'other' => q({0} kiupite),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(ʻatimosifia),
						'other' => q(ʻatimosifia ʻe {0}),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(ʻatimosifia),
						'other' => q(ʻatimosifia ʻe {0}),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(hēkitopasikale),
						'other' => q(hēkitopasikale ʻe {0}),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(hēkitopasikale),
						'other' => q(hēkitopasikale ʻe {0}),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(ʻinisi meakuli),
						'other' => q(ʻinisi meakuli ʻe {0}),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(ʻinisi meakuli),
						'other' => q(ʻinisi meakuli ʻe {0}),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(kilopasikale),
						'other' => q(kilopasikale ʻe {0}),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(kilopasikale),
						'other' => q(kilopasikale ʻe {0}),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(mekapasikale),
						'other' => q(mekapasikale ʻe {0}),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(mekapasikale),
						'other' => q(mekapasikale ʻe {0}),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(milipā),
						'other' => q(milipā ʻe {0}),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(milipā),
						'other' => q(milipā ʻe {0}),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(milimita meakuli),
						'other' => q(milimita meakuli ʻe {0}),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(milimita meakuli),
						'other' => q(milimita meakuli ʻe {0}),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(pasikale),
						'other' => q(pasikale ʻe {0}),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(pasikale),
						'other' => q(pasikale ʻe {0}),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(pāuni he ʻinisi sikuea),
						'other' => q(pāuni he ʻinisi sikuea ʻe {0}),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(pāuni he ʻinisi sikuea),
						'other' => q(pāuni he ʻinisi sikuea ʻe {0}),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Pōfooti),
						'other' => q(Pōfooti ʻe {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Pōfooti),
						'other' => q(Pōfooti ʻe {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(kilomita he houa),
						'other' => q(kilomita he houa ʻe {0}),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(kilomita he houa),
						'other' => q(kilomita he houa ʻe {0}),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(fakapona),
						'other' => q(fakapona ʻe {0}),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(fakapona),
						'other' => q(fakapona ʻe {0}),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(mita he sekoni),
						'other' => q(mita he sekoni ʻe {0}),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(mita he sekoni),
						'other' => q(mita he sekoni ʻe {0}),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(maile he houa),
						'other' => q(maile he houa ʻe {0}),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(maile he houa),
						'other' => q(maile he houa ʻe {0}),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(tikili selisiasi),
						'other' => q(tikili selisiasi ʻe {0}),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(tikili selisiasi),
						'other' => q(tikili selisiasi ʻe {0}),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(tikili felenihaiti),
						'other' => q(tikili felenihaiti ʻe {0}),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(tikili felenihaiti),
						'other' => q(tikili felenihaiti ʻe {0}),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'name' => q(tikili),
						'other' => q(tikili ʻe {0}),
					},
					# Core Unit Identifier
					'generic' => {
						'name' => q(tikili),
						'other' => q(tikili ʻe {0}),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(kelevini),
						'other' => q(kelevini ʻe {0}),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(kelevini),
						'other' => q(kelevini ʻe {0}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'name' => q(Niutonimita),
						'other' => q(Niutonimita ʻe {0}),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(Niutonimita),
						'other' => q(Niutonimita ʻe {0}),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pāunifute),
						'other' => q(pāunifute ʻe {0}),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pāunifute),
						'other' => q(pāunifute ʻe {0}),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ʻeka-fute),
						'other' => q(ʻeka-fute ʻe {0}),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ʻeka-fute),
						'other' => q(ʻeka-fute ʻe {0}),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(pūseli),
						'other' => q(pūseli ʻe {0}),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(pūseli),
						'other' => q(pūseli ʻe {0}),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(senitilita),
						'other' => q(senitilita ʻe {0}),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(senitilita),
						'other' => q(senitilita ʻe {0}),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(senitimita kiupiki),
						'other' => q(senitimita kiupiki ʻe {0}),
						'per' => q({0} he senitimita kiupiki),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(senitimita kiupiki),
						'other' => q(senitimita kiupiki ʻe {0}),
						'per' => q({0} he senitimita kiupiki),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(fute kiupiki),
						'other' => q(fute kiupiki ʻe {0}),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(fute kiupiki),
						'other' => q(fute kiupiki ʻe {0}),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(ʻinisi kiupiki),
						'other' => q(ʻinisi kiupiki ʻe {0}),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(ʻinisi kiupiki),
						'other' => q(ʻinisi kiupiki ʻe {0}),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(kilomita kiupiki),
						'other' => q(kilomita kiupiki ʻe {0}),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(kilomita kiupiki),
						'other' => q(kilomita kiupiki ʻe {0}),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(mita kiupiki),
						'other' => q(mita kiupiki ʻe {0}),
						'per' => q({0} he mita kiupiki),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(mita kiupiki),
						'other' => q(mita kiupiki ʻe {0}),
						'per' => q({0} he mita kiupiki),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(maile kiupiki),
						'other' => q(maile kiupiki ʻe {0}),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(maile kiupiki),
						'other' => q(maile kiupiki ʻe {0}),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(iate kiupiki),
						'other' => q(iate kiupiki ʻe {0}),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(iate kiupiki),
						'other' => q(iate kiupiki ʻe {0}),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(ipu),
						'other' => q(ipu ʻe {0}),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(ipu),
						'other' => q(ipu ʻe {0}),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(ipu fakamita),
						'other' => q(ipu fakamita ʻe {0}),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(ipu fakamita),
						'other' => q(ipu fakamita ʻe {0}),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(tesilita),
						'other' => q(tesilita ʻe {0}),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(tesilita),
						'other' => q(tesilita ʻe {0}),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(sēpuni puteni),
						'other' => q(sēpuni puteni ʻe {0}),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(sēpuni puteni),
						'other' => q(sēpuni puteni ʻe {0}),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(sēpuni puteni fakaʻemipaea),
						'other' => q(sēpuni puteni fakaʻemipaea ʻe {0}),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(sēpuni puteni fakaʻemipaea),
						'other' => q(sēpuni puteni fakaʻemipaea ʻe {0}),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(talamu tafe),
						'other' => q(talamu tafe ʻe {0}),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(talamu tafe),
						'other' => q(talamu tafe ʻe {0}),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(tulutā),
						'other' => q(tulutā ʻe {0}),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(tulutā),
						'other' => q(tulutā ʻe {0}),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(ʻaunise tafe),
						'other' => q(ʻaunise tafe ʻe {0}),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(ʻaunise tafe),
						'other' => q(ʻaunise tafe ʻe {0}),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(ʻaunise fakaʻemipaea),
						'other' => q(ʻaunise fakaʻemipaea ʻe {0}),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(ʻaunise fakaʻemipaea),
						'other' => q(ʻaunise fakaʻemipaea ʻe {0}),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(kālani),
						'other' => q(kālani ʻe {0}),
						'per' => q({0} he kālani),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(kālani),
						'other' => q(kālani ʻe {0}),
						'per' => q({0} he kālani),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(kālani fakaʻemipaea),
						'other' => q(kālani fakaʻemipaea ʻe {0}),
						'per' => q({0} ki he kālani fakaʻemipaea),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(kālani fakaʻemipaea),
						'other' => q(kālani fakaʻemipaea ʻe {0}),
						'per' => q({0} ki he kālani fakaʻemipaea),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hēkitolita),
						'other' => q(hēkitolita ʻe {0}),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hēkitolita),
						'other' => q(hēkitolita ʻe {0}),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(lita),
						'other' => q(lita ʻe {0}),
						'per' => q({0} he lita),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(lita),
						'other' => q(lita ʻe {0}),
						'per' => q({0} he lita),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(mekalita),
						'other' => q(mekalita ʻe {0}),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(mekalita),
						'other' => q(mekalita ʻe {0}),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(mililita),
						'other' => q(mililita ʻe {0}),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(mililita),
						'other' => q(mililita ʻe {0}),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(painite),
						'other' => q(painite ʻe {0}),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(painite),
						'other' => q(painite ʻe {0}),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(painite fakamita),
						'other' => q(painite fakamita ʻe {0}),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(painite fakamita),
						'other' => q(painite fakamita ʻe {0}),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(kuata),
						'other' => q(kuata ʻe {0}),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(kuata),
						'other' => q(kuata ʻe {0}),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(kuata fakaʻemipaea),
						'other' => q(kuata fakaʻemipaea ʻe {0}),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(kuata fakaʻemipaea),
						'other' => q(kuata fakaʻemipaea ʻe {0}),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(sēpuni tēpile),
						'other' => q(sēpuni tēpile ʻe {0}),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(sēpuni tēpile),
						'other' => q(sēpuni tēpile ʻe {0}),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(sēpuni tī),
						'other' => q(sēpuni tī ʻe {0}),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(sēpuni tī),
						'other' => q(sēpuni tī ʻe {0}),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'other' => q({0} k-mā),
					},
					# Core Unit Identifier
					'g-force' => {
						'other' => q({0} k-mā),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'other' => q({0} m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'other' => q({0} m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'other' => q({0} lēt),
					},
					# Core Unit Identifier
					'radian' => {
						'other' => q({0} lēt),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'other' => q({0} tak),
					},
					# Core Unit Identifier
					'revolution' => {
						'other' => q({0} tak),
					},
					# Long Unit Identifier
					'area-acre' => {
						'other' => q({0} ʻek),
					},
					# Core Unit Identifier
					'acre' => {
						'other' => q({0} ʻek),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(tu),
						'other' => q({0} tu),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(tu),
						'other' => q({0} tu),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'other' => q({0} ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'other' => q({0} ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'other' => q({0} sm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'other' => q({0} sm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'other' => q({0} ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'other' => q({0} ft²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'other' => q({0} in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'other' => q({0} in²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'other' => q({0} km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'other' => q({0} km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'other' => q({0} m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'other' => q({0} m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'other' => q({0} mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'other' => q({0} mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'other' => q({0} it²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'other' => q({0} it²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(kk),
						'other' => q(kk ʻe {0}),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(kk),
						'other' => q(kk ʻe {0}),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'other' => q({0} kt),
					},
					# Core Unit Identifier
					'karat' => {
						'other' => q({0} kt),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'other' => q({0} mk/tl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'other' => q({0} mk/tl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'other' => q({0} mol),
					},
					# Core Unit Identifier
					'mole' => {
						'other' => q({0} mol),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'other' => q({0}%),
					},
					# Core Unit Identifier
					'percent' => {
						'other' => q({0}%),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'other' => q({0}‰),
					},
					# Core Unit Identifier
					'permille' => {
						'other' => q({0}‰),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'other' => q({0} khm),
					},
					# Core Unit Identifier
					'permillion' => {
						'other' => q({0} khm),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'other' => q({0}‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'other' => q({0}‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'other' => q({0} l/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'other' => q({0} l/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'other' => q({0} mi/kā),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'other' => q({0} mi/kā),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mi/kāʻ-em),
						'other' => q({0} mi/kāʻem),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mi/kāʻ-em),
						'other' => q({0} mi/kāʻem),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} ha),
						'north' => q({0} tk),
						'south' => q({0} to),
						'west' => q({0} hi),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} ha),
						'north' => q({0} tk),
						'south' => q({0} to),
						'west' => q({0} hi),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(b),
						'other' => q({0} b),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(b),
						'other' => q({0} b),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(B),
						'other' => q({0} B),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(B),
						'other' => q({0} B),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gb),
						'other' => q({0} Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gb),
						'other' => q({0} Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GB),
						'other' => q({0} GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GB),
						'other' => q({0} GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kb),
						'other' => q({0} kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kb),
						'other' => q({0} kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kB),
						'other' => q({0} kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kB),
						'other' => q({0} kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mb),
						'other' => q({0} Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mb),
						'other' => q({0} Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MB),
						'other' => q({0} MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MB),
						'other' => q({0} MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PB),
						'other' => q({0} PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PB),
						'other' => q({0} PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tb),
						'other' => q({0} Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tb),
						'other' => q({0} Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TB),
						'other' => q({0} TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TB),
						'other' => q({0} TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'other' => q({0} tt),
					},
					# Core Unit Identifier
					'century' => {
						'other' => q({0} tt),
					},
					# Long Unit Identifier
					'duration-day' => {
						'other' => q({0} ʻa),
						'per' => q({0}/ʻa),
					},
					# Core Unit Identifier
					'day' => {
						'other' => q({0} ʻa),
						'per' => q({0}/ʻa),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'other' => q({0} ht),
					},
					# Core Unit Identifier
					'decade' => {
						'other' => q({0} ht),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'other' => q({0} h),
					},
					# Core Unit Identifier
					'hour' => {
						'other' => q({0} h),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'other' => q({0} μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'other' => q({0} μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'other' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'other' => q({0} ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'minute' => {
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'other' => q({0} ns),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'other' => q({0} ns),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(kt),
						'other' => q({0} kt),
						'per' => q({0}/kt),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(kt),
						'other' => q({0} kt),
						'per' => q({0}/kt),
					},
					# Long Unit Identifier
					'duration-second' => {
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					# Core Unit Identifier
					'second' => {
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'other' => q({0} u),
						'per' => q({0}/u),
					},
					# Core Unit Identifier
					'week' => {
						'other' => q({0} u),
						'per' => q({0}/u),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(t),
						'other' => q({0} t),
						'per' => q({0}/t),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(t),
						'other' => q({0} t),
						'per' => q({0}/t),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'other' => q({0} A),
					},
					# Core Unit Identifier
					'ampere' => {
						'other' => q({0} A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'other' => q({0} mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'other' => q({0} mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'other' => q({0} Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'other' => q({0} Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(V),
						'other' => q({0} V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(V),
						'other' => q({0} V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'other' => q({0} imfP),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'other' => q({0} imfP),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'other' => q({0} kal),
					},
					# Core Unit Identifier
					'calorie' => {
						'other' => q({0} kal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'other' => q({0} eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'other' => q({0} eV),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'other' => q({0} kal-k),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'other' => q({0} kal-k),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'other' => q({0} J),
					},
					# Core Unit Identifier
					'joule' => {
						'other' => q({0} J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'other' => q({0} kkal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'other' => q({0} kkal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'other' => q({0} kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'other' => q({0} kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'other' => q({0} kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'other' => q({0} kWh),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'other' => q({0} imfA),
					},
					# Core Unit Identifier
					'therm-us' => {
						'other' => q({0} imfA),
					},
					# Long Unit Identifier
					'force-newton' => {
						'other' => q({0} N),
					},
					# Core Unit Identifier
					'newton' => {
						'other' => q({0} N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'other' => q({0} pāmā),
					},
					# Core Unit Identifier
					'pound-force' => {
						'other' => q({0} pāmā),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'other' => q({0} GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'other' => q({0} GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'other' => q({0} Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'other' => q({0} Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'other' => q({0} kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'other' => q({0} kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'other' => q({0} MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'other' => q({0} MHz),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(t),
						'other' => q({0}t),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(t),
						'other' => q({0}t),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(t/sm),
						'other' => q({0}t/sm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(t/sm),
						'other' => q({0}t/sm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(t/in),
						'other' => q({0}t/in),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(t/in),
						'other' => q({0}t/in),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'other' => q({0}ʻemi),
					},
					# Core Unit Identifier
					'em' => {
						'other' => q({0}ʻemi),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(Mmt),
						'other' => q({0}Mmt),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(Mmt),
						'other' => q({0}Mmt),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(mt),
						'other' => q({0}mt),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(mt),
						'other' => q({0}mt),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(mt/sm),
						'other' => q({0}mt/sm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(mt/sm),
						'other' => q({0}mt/sm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(mt/in),
						'other' => q({0}mt/in),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(mt/in),
						'other' => q({0}mt/in),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'other' => q({0} ʻiʻa),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'other' => q({0} ʻiʻa),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'other' => q({0} sm),
						'per' => q({0}/sm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'other' => q({0} sm),
						'per' => q({0}/sm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'other' => q({0} tm),
					},
					# Core Unit Identifier
					'decimeter' => {
						'other' => q({0} tm),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'other' => q({0} L⊕),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'other' => q({0} L⊕),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(o),
						'other' => q({0} o),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(o),
						'other' => q({0} o),
					},
					# Long Unit Identifier
					'length-foot' => {
						'other' => q({0} ft),
					},
					# Core Unit Identifier
					'foot' => {
						'other' => q({0} ft),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'other' => q({0} fāl),
					},
					# Core Unit Identifier
					'furlong' => {
						'other' => q({0} fāl),
					},
					# Long Unit Identifier
					'length-inch' => {
						'other' => q({0} in),
					},
					# Core Unit Identifier
					'inch' => {
						'other' => q({0} in),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'other' => q({0} km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'other' => q({0} km),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'other' => q({0} tma),
					},
					# Core Unit Identifier
					'light-year' => {
						'other' => q({0} tma),
					},
					# Long Unit Identifier
					'length-meter' => {
						'other' => q({0} m),
					},
					# Core Unit Identifier
					'meter' => {
						'other' => q({0} m),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'other' => q({0} μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'other' => q({0} μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'other' => q({0} mi),
					},
					# Core Unit Identifier
					'mile' => {
						'other' => q({0} mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'other' => q({0} msi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'other' => q({0} msi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'other' => q({0} mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'other' => q({0} mm),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'other' => q({0} nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'other' => q({0} nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'other' => q({0} mt),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'other' => q({0} mt),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'other' => q({0} ngs),
					},
					# Core Unit Identifier
					'parsec' => {
						'other' => q({0} ngs),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'other' => q({0} pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'other' => q({0} pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'other' => q({0} pn),
					},
					# Core Unit Identifier
					'point' => {
						'other' => q({0} pn),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'other' => q({0} L☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'other' => q({0} L☉),
					},
					# Long Unit Identifier
					'length-yard' => {
						'other' => q({0} it),
					},
					# Core Unit Identifier
					'yard' => {
						'other' => q({0} it),
					},
					# Long Unit Identifier
					'light-candela' => {
						'other' => q({0} ktl),
					},
					# Core Unit Identifier
					'candela' => {
						'other' => q({0} ktl),
					},
					# Long Unit Identifier
					'light-lux' => {
						'other' => q({0} lx),
					},
					# Core Unit Identifier
					'lux' => {
						'other' => q({0} lx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'other' => q({0} H☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'other' => q({0} H☉),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'other' => q({0} kt),
					},
					# Core Unit Identifier
					'carat' => {
						'other' => q({0} kt),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'other' => q({0} tlt),
					},
					# Core Unit Identifier
					'dalton' => {
						'other' => q({0} tlt),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(M⊕),
						'other' => q({0} M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(M⊕),
						'other' => q({0} M⊕),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'other' => q({0} tenga),
					},
					# Core Unit Identifier
					'grain' => {
						'other' => q({0} tenga),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'other' => q({0} k),
					},
					# Core Unit Identifier
					'gram' => {
						'other' => q({0} k),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'other' => q({0} kk),
					},
					# Core Unit Identifier
					'kilogram' => {
						'other' => q({0} kk),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'other' => q({0} μk),
					},
					# Core Unit Identifier
					'microgram' => {
						'other' => q({0} μk),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'other' => q({0} mk),
					},
					# Core Unit Identifier
					'milligram' => {
						'other' => q({0} mk),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'other' => q({0} ʻau),
					},
					# Core Unit Identifier
					'ounce' => {
						'other' => q({0} ʻau),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'other' => q({0} ʻau-k),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'other' => q({0} ʻau-k),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'other' => q({0} pāu),
					},
					# Core Unit Identifier
					'pound' => {
						'other' => q({0} pāu),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(M☉),
						'other' => q({0} M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(M☉),
						'other' => q({0} M☉),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'other' => q({0} st),
					},
					# Core Unit Identifier
					'stone' => {
						'other' => q({0} st),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'other' => q({0} tn),
					},
					# Core Unit Identifier
					'ton' => {
						'other' => q({0} tn),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'other' => q({0} to),
					},
					# Core Unit Identifier
					'tonne' => {
						'other' => q({0} to),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'other' => q({0} GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'other' => q({0} GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'other' => q({0} hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'other' => q({0} hp),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'other' => q({0} kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'other' => q({0} kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'other' => q({0} MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'other' => q({0} MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'other' => q({0} mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'other' => q({0} mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(W),
						'other' => q({0} W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(W),
						'other' => q({0} W),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'other' => q({0} ʻati),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'other' => q({0} ʻati),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'other' => q({0} pā),
					},
					# Core Unit Identifier
					'bar' => {
						'other' => q({0} pā),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'other' => q({0} hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'other' => q({0} hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'other' => q({0} in-Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'other' => q({0} in-Hg),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'other' => q({0} kPa),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'other' => q({0} kPa),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'other' => q({0} MPa),
					},
					# Core Unit Identifier
					'megapascal' => {
						'other' => q({0} MPa),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'other' => q({0} mpā),
					},
					# Core Unit Identifier
					'millibar' => {
						'other' => q({0} mpā),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'other' => q({0} mm-Hg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'other' => q({0} mm-Hg),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'other' => q({0} Pa),
					},
					# Core Unit Identifier
					'pascal' => {
						'other' => q({0} Pa),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'other' => q({0} pā/in²),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'other' => q({0} pā/in²),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'other' => q({0} km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'other' => q({0} km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'other' => q({0} fp),
					},
					# Core Unit Identifier
					'knot' => {
						'other' => q({0} fp),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'other' => q({0} m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'other' => q({0} m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'other' => q({0} mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'other' => q({0} mi/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'other' => q({0}°S),
					},
					# Core Unit Identifier
					'celsius' => {
						'other' => q({0}°S),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'other' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'other' => q({0}°F),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'generic' => {
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'other' => q({0} K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'other' => q({0} K),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'other' => q({0} N⋅m),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'other' => q({0} N⋅m),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'other' => q({0} pā⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'other' => q({0} pā⋅ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'other' => q({0} ʻe-ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'other' => q({0} ʻe-ft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(plo),
						'other' => q({0} plo),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(plo),
						'other' => q({0} plo),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'other' => q({0} pū),
					},
					# Core Unit Identifier
					'bushel' => {
						'other' => q({0} pū),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'other' => q({0} sl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'other' => q({0} sl),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'other' => q({0} sm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'other' => q({0} sm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'other' => q({0} ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'other' => q({0} ft³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'other' => q({0} in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'other' => q({0} in³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'other' => q({0} km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'other' => q({0} km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'other' => q({0} m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'other' => q({0} m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'other' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'other' => q({0} mi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'other' => q({0} it³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'other' => q({0} it³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'other' => q({0} ip),
					},
					# Core Unit Identifier
					'cup' => {
						'other' => q({0} ip),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'other' => q({0} ipm),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'other' => q({0} ipm),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'other' => q({0} tl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'other' => q({0} tl),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'other' => q({0} sēpu),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'other' => q({0} sēpu),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'other' => q({0} sēp-ʻem),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'other' => q({0} sēp-ʻem),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'other' => q({0} tlmu-tf),
					},
					# Core Unit Identifier
					'dram' => {
						'other' => q({0} tlmu-tf),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'other' => q({0} tltā),
					},
					# Core Unit Identifier
					'drop' => {
						'other' => q({0} tltā),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'other' => q({0} ʻau-tf),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'other' => q({0} ʻau-tf),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'other' => q({0}ʻau-ʻem),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'other' => q({0}ʻau-ʻem),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'other' => q({0} kā),
					},
					# Core Unit Identifier
					'gallon' => {
						'other' => q({0} kā),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(kā-ʻem),
						'other' => q({0} kā-ʻem),
						'per' => q({0}/kā-ʻem),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(kā-ʻem),
						'other' => q({0} kā-ʻem),
						'per' => q({0}/kā-ʻem),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'other' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'other' => q({0} hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'other' => q({0} sike),
					},
					# Core Unit Identifier
					'jigger' => {
						'other' => q({0} sike),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'other' => q({0} l),
					},
					# Core Unit Identifier
					'liter' => {
						'other' => q({0} l),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'other' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'other' => q({0} Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'other' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'other' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'other' => q({0} kiʻimeʻi),
					},
					# Core Unit Identifier
					'pinch' => {
						'other' => q({0} kiʻimeʻi),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'other' => q({0} pt),
					},
					# Core Unit Identifier
					'pint' => {
						'other' => q({0} pt),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'other' => q({0} ptm),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'other' => q({0} ptm),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'other' => q({0} ku),
					},
					# Core Unit Identifier
					'quart' => {
						'other' => q({0} ku),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'other' => q({0} ku-ʻem),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'other' => q({0} ku-ʻem),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'other' => q({0} sētē),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'other' => q({0} sētē),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'other' => q({0} sētī),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'other' => q({0} sētī),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(fua),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(fua),
					},
					# Long Unit Identifier
					'1024p1' => {
						'1' => q(ki{0}),
					},
					# Core Unit Identifier
					'1024p1' => {
						'1' => q(ki{0}),
					},
					# Long Unit Identifier
					'1024p3' => {
						'1' => q(Ki{0}),
					},
					# Core Unit Identifier
					'1024p3' => {
						'1' => q(Ki{0}),
					},
					# Long Unit Identifier
					'10p-1' => {
						'1' => q(t{0}),
					},
					# Core Unit Identifier
					'1' => {
						'1' => q(t{0}),
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
					'10p1' => {
						'1' => q(ta{0}),
					},
					# Core Unit Identifier
					'10p1' => {
						'1' => q(ta{0}),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(k-mā),
						'other' => q(k-mā ʻe {0}),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(k-mā),
						'other' => q(k-mā ʻe {0}),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'other' => q(m/s² ʻe {0}),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'other' => q(m/s² ʻe {0}),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(msk),
						'other' => q(msk ʻe {0}),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(msk),
						'other' => q(msk ʻe {0}),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(ssk),
						'other' => q(ssk ʻe {0}),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(ssk),
						'other' => q(ssk ʻe {0}),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(tsk),
						'other' => q(tsk ʻe {0}),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(tsk),
						'other' => q(tsk ʻe {0}),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(lēt),
						'other' => q(lēt ʻe {0}),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(lēt),
						'other' => q(lēt ʻe {0}),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(tak),
						'other' => q(tak ʻe {0}),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(tak),
						'other' => q(tak ʻe {0}),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ʻek),
						'other' => q(ʻek ʻe {0}),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ʻek),
						'other' => q(ʻek ʻe {0}),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(tunami),
						'other' => q(tunami ʻe {0}),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(tunami),
						'other' => q(tunami ʻe {0}),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ha),
						'other' => q(ha ʻe {0}),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ha),
						'other' => q(ha ʻe {0}),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(sm²),
						'other' => q(sm² ʻe {0}),
						'per' => q({0}/sm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(sm²),
						'other' => q(sm² ʻe {0}),
						'per' => q({0}/sm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'other' => q(ft² ʻe {0}),
					},
					# Core Unit Identifier
					'square-foot' => {
						'other' => q(ft² ʻe {0}),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'other' => q(in² ʻe {0}),
					},
					# Core Unit Identifier
					'square-inch' => {
						'other' => q(in² ʻe {0}),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'other' => q(km² ʻe {0}),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'other' => q(km² ʻe {0}),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'other' => q(m² ʻe {0}),
					},
					# Core Unit Identifier
					'square-meter' => {
						'other' => q(m² ʻe {0}),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'other' => q(mi² ʻe {0}),
					},
					# Core Unit Identifier
					'square-mile' => {
						'other' => q(mi² ʻe {0}),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(it²),
						'other' => q(it² ʻe {0}),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(it²),
						'other' => q(it² ʻe {0}),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(kkonga),
						'other' => q(kkonga ʻe {0}),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(kkonga),
						'other' => q(kkonga ʻe {0}),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'other' => q(kt ʻe {0}),
					},
					# Core Unit Identifier
					'karat' => {
						'other' => q(kt ʻe {0}),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(mk/tl),
						'other' => q(mk ʻe {0}/tl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(mk/tl),
						'other' => q(mk ʻe {0}/tl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/l),
						'other' => q(mmol ʻe {0}/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/l),
						'other' => q(mmol ʻe {0}/l),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'other' => q(mol ʻe {0}),
					},
					# Core Unit Identifier
					'mole' => {
						'other' => q(mol ʻe {0}),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'other' => q(% ʻe {0}),
					},
					# Core Unit Identifier
					'percent' => {
						'other' => q(% ʻe {0}),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'other' => q(‰ ʻe {0}),
					},
					# Core Unit Identifier
					'permille' => {
						'other' => q(‰ ʻe {0}),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(khm),
						'other' => q(khm ʻe {0}),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(khm),
						'other' => q(khm ʻe {0}),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'other' => q(‱ ʻe {0}),
					},
					# Core Unit Identifier
					'permyriad' => {
						'other' => q(‱ ʻe {0}),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'other' => q(l ʻe {0}/100km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100km),
						'other' => q(l ʻe {0}/100km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(l/km),
						'other' => q(l ʻe {0}/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'other' => q(l ʻe {0}/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mi/kā),
						'other' => q(mi ʻe {0}/kā),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mi/kā),
						'other' => q(mi ʻe {0}/kā),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mi/kā-ʻem),
						'other' => q(mi ʻe {0}/kā-ʻem),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mi/kā-ʻem),
						'other' => q(mi ʻe {0}/kā-ʻem),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q(ha ʻe {0}),
						'north' => q(tk ʻe {0}),
						'south' => q(to ʻe {0}),
						'west' => q(hi ʻe {0}),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q(ha ʻe {0}),
						'north' => q(tk ʻe {0}),
						'south' => q(to ʻe {0}),
						'west' => q(hi ʻe {0}),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(piti),
						'other' => q(piti ʻe {0}),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(piti),
						'other' => q(piti ʻe {0}),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(paiti),
						'other' => q(paiti ʻe {0}),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(paiti),
						'other' => q(paiti ʻe {0}),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(kikapiti),
						'other' => q(Gb ʻe {0}),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(kikapiti),
						'other' => q(Gb ʻe {0}),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(kikapaiti),
						'other' => q(GB ʻe {0}),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(kikapaiti),
						'other' => q(GB ʻe {0}),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kilopiti),
						'other' => q(kb ʻe {0}),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kilopiti),
						'other' => q(kb ʻe {0}),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kilopaiti),
						'other' => q(kB ʻe {0}),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kilopaiti),
						'other' => q(kB ʻe {0}),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(mekapiti),
						'other' => q(Mb ʻe {0}),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(mekapiti),
						'other' => q(Mb ʻe {0}),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(mekapaiti),
						'other' => q(MB ʻe {0}),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(mekapaiti),
						'other' => q(MB ʻe {0}),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(petapaiti),
						'other' => q(PB ʻe {0}),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(petapaiti),
						'other' => q(PB ʻe {0}),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(telapiti),
						'other' => q(Tb ʻe {0}),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(telapiti),
						'other' => q(Tb ʻe {0}),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(telapaiti),
						'other' => q(TB ʻe {0}),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(telapaiti),
						'other' => q(TB ʻe {0}),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(tt),
						'other' => q(tt ʻe {0}),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(tt),
						'other' => q(tt ʻe {0}),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ʻa),
						'other' => q(ʻa ʻe {0}),
						'per' => q({0} /ʻa),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ʻa),
						'other' => q(ʻa ʻe {0}),
						'per' => q({0} /ʻa),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(ht),
						'other' => q(ht ʻe {0}),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(ht),
						'other' => q(ht ʻe {0}),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(h),
						'other' => q(h ʻe {0}),
						'per' => q({0} /h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(h),
						'other' => q(h ʻe {0}),
						'per' => q({0} /h),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'other' => q(μs ʻe {0}),
					},
					# Core Unit Identifier
					'microsecond' => {
						'other' => q(μs ʻe {0}),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'other' => q(ms ʻe {0}),
					},
					# Core Unit Identifier
					'millisecond' => {
						'other' => q(ms ʻe {0}),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(m),
						'other' => q(m ʻe {0}),
						'per' => q({0} /m),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(m),
						'other' => q(m ʻe {0}),
						'per' => q({0} /m),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(mā),
						'other' => q(mā ʻe {0}),
						'per' => q({0} /mā),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(mā),
						'other' => q(mā ʻe {0}),
						'per' => q({0} /mā),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'other' => q(ns ʻe {0}),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'other' => q(ns ʻe {0}),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(kuata),
						'other' => q(kuata ʻe {0}),
						'per' => q({0} /kt),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(kuata),
						'other' => q(kuata ʻe {0}),
						'per' => q({0} /kt),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(s),
						'other' => q(s ʻe {0}),
						'per' => q({0} /s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(s),
						'other' => q(s ʻe {0}),
						'per' => q({0} /s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(u),
						'other' => q(u ʻe {0}),
						'per' => q({0} /u),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(u),
						'other' => q(u ʻe {0}),
						'per' => q({0} /u),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(taʻu),
						'other' => q(taʻu ʻe {0}),
						'per' => q({0} /t),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(taʻu),
						'other' => q(taʻu ʻe {0}),
						'per' => q({0} /t),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(A),
						'other' => q(A ʻe {0}),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(A),
						'other' => q(A ʻe {0}),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'other' => q(mA ʻe {0}),
					},
					# Core Unit Identifier
					'milliampere' => {
						'other' => q(mA ʻe {0}),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(Ω),
						'other' => q(Ω ʻe {0}),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(Ω),
						'other' => q(Ω ʻe {0}),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(volotā),
						'other' => q(V ʻe {0}),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(volotā),
						'other' => q(V ʻe {0}),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(imfP),
						'other' => q(imfP ʻe {0}),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(imfP),
						'other' => q(imfP ʻe {0}),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(kal),
						'other' => q(kal ʻe {0}),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(kal),
						'other' => q(kal ʻe {0}),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'other' => q(eV ʻe {0}),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'other' => q(eV ʻe {0}),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(kal-k),
						'other' => q(kal-k ʻe {0}),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(kal-k),
						'other' => q(kal-k ʻe {0}),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(J),
						'other' => q(J ʻe {0}),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(J),
						'other' => q(J ʻe {0}),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(kkal),
						'other' => q(kkal ʻe {0}),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(kkal),
						'other' => q(kkal ʻe {0}),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'other' => q(kJ ʻe {0}),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'other' => q(kJ ʻe {0}),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'other' => q(kWh ʻe {0}),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'other' => q(kWh ʻe {0}),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(imfA),
						'other' => q(imfA ʻe {0}),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(imfA),
						'other' => q(imfA ʻe {0}),
					},
					# Long Unit Identifier
					'force-newton' => {
						'other' => q(N ʻe {0}),
					},
					# Core Unit Identifier
					'newton' => {
						'other' => q(N ʻe {0}),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(pāmā),
						'other' => q(pāmā ʻe {0}),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(pāmā),
						'other' => q(pāmā ʻe {0}),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'other' => q(GHz ʻe {0}),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'other' => q(GHz ʻe {0}),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'other' => q(Hz ʻe {0}),
					},
					# Core Unit Identifier
					'hertz' => {
						'other' => q(Hz ʻe {0}),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'other' => q(kHz ʻe {0}),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'other' => q(kHz ʻe {0}),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'other' => q(MHz ʻe {0}),
					},
					# Core Unit Identifier
					'megahertz' => {
						'other' => q(MHz ʻe {0}),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(toti),
						'other' => q(toti ʻe {0}),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(toti),
						'other' => q(toti ʻe {0}),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(toti/sm),
						'other' => q(toti ʻe {0}/sm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(toti/sm),
						'other' => q(toti ʻe {0}/sm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(toti/in),
						'other' => q(toti ʻe {0}/in),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(toti/in),
						'other' => q(toti ʻe {0}/in),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(ʻemi),
						'other' => q(ʻemi ʻe {0}),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(ʻemi),
						'other' => q(ʻemi ʻe {0}),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(Mmeʻatā),
						'other' => q(Mmeʻatā ʻe {0}),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(Mmeʻatā),
						'other' => q(Mmeʻatā ʻe {0}),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(meʻatā),
						'other' => q(meʻatā ʻe {0}),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(meʻatā),
						'other' => q(meʻatā ʻe {0}),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(meʻatā/sm),
						'other' => q(meʻatā ʻe {0}/sm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(meʻatā/sm),
						'other' => q(meʻatā ʻe {0}/sm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(meʻatā/in),
						'other' => q(meʻatā ʻe {0}/in),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(meʻatā/in),
						'other' => q(meʻatā ʻe {0}/in),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(ʻiʻa),
						'other' => q(ʻiʻa ʻe {0}),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ʻiʻa),
						'other' => q(ʻiʻa ʻe {0}),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(sm),
						'other' => q(sm ʻe {0}),
						'per' => q({0} /sm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(sm),
						'other' => q(sm ʻe {0}),
						'per' => q({0} /sm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(tm),
						'other' => q(tm ʻe {0}),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(tm),
						'other' => q(tm ʻe {0}),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(L⊕),
						'other' => q(L⊕ ʻe {0}),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(L⊕),
						'other' => q(L⊕ ʻe {0}),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(ofa),
						'other' => q(ofa ʻe {0}),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(ofa),
						'other' => q(ofa ʻe {0}),
					},
					# Long Unit Identifier
					'length-foot' => {
						'other' => q(ft ʻe {0}),
					},
					# Core Unit Identifier
					'foot' => {
						'other' => q(ft ʻe {0}),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(fāl),
						'other' => q(fāl ʻe {0}),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(fāl),
						'other' => q(fāl ʻe {0}),
					},
					# Long Unit Identifier
					'length-inch' => {
						'other' => q(in ʻe {0}),
					},
					# Core Unit Identifier
					'inch' => {
						'other' => q(in ʻe {0}),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'other' => q(km ʻe {0}),
					},
					# Core Unit Identifier
					'kilometer' => {
						'other' => q(km ʻe {0}),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(tma),
						'other' => q(tma ʻe {0}),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(tma),
						'other' => q(tma ʻe {0}),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(m),
						'other' => q(m ʻe {0}),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(m),
						'other' => q(m ʻe {0}),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'other' => q(μm ʻe {0}),
					},
					# Core Unit Identifier
					'micrometer' => {
						'other' => q(μm ʻe {0}),
					},
					# Long Unit Identifier
					'length-mile' => {
						'other' => q(mi ʻe {0}),
					},
					# Core Unit Identifier
					'mile' => {
						'other' => q(mi ʻe {0}),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(msi),
						'other' => q(msi ʻe {0}),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(msi),
						'other' => q(msi ʻe {0}),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'other' => q(mm ʻe {0}),
					},
					# Core Unit Identifier
					'millimeter' => {
						'other' => q(mm ʻe {0}),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'other' => q(nm ʻe {0}),
					},
					# Core Unit Identifier
					'nanometer' => {
						'other' => q(nm ʻe {0}),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(mt),
						'other' => q(mt ʻe {0}),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(mt),
						'other' => q(mt ʻe {0}),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(ngs),
						'other' => q(ngs ʻe {0}),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(ngs),
						'other' => q(ngs ʻe {0}),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'other' => q(pm ʻe {0}),
					},
					# Core Unit Identifier
					'picometer' => {
						'other' => q(pm ʻe {0}),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pn),
						'other' => q(pn ʻe {0}),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pn),
						'other' => q(pn ʻe {0}),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(L☉),
						'other' => q(L☉ ʻe {0}),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(L☉),
						'other' => q(L☉ ʻe {0}),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(it),
						'other' => q(it ʻe {0}),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(it),
						'other' => q(it ʻe {0}),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(ktl),
						'other' => q(ktl ʻe {0}),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(ktl),
						'other' => q(ktl ʻe {0}),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'other' => q(lm ʻe {0}),
					},
					# Core Unit Identifier
					'lumen' => {
						'other' => q(lm ʻe {0}),
					},
					# Long Unit Identifier
					'light-lux' => {
						'other' => q(lx ʻe {0}),
					},
					# Core Unit Identifier
					'lux' => {
						'other' => q(lx ʻe {0}),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(H☉),
						'other' => q(H☉ ʻe {0}),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(H☉),
						'other' => q(H☉ ʻe {0}),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(kt),
						'other' => q(kt ʻe {0}),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(kt),
						'other' => q(kt ʻe {0}),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(tlt),
						'other' => q(tlt ʻe {0}),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(tlt),
						'other' => q(tlt ʻe {0}),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(mamafa ⊕),
						'other' => q(mamafa ⊕ ʻe {0}),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(mamafa ⊕),
						'other' => q(mamafa ⊕ ʻe {0}),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(tenga),
						'other' => q(tenga ʻe {0}),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(tenga),
						'other' => q(tenga ʻe {0}),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(k),
						'other' => q(k ʻe {0}),
						'per' => q({0}/k),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(k),
						'other' => q(k ʻe {0}),
						'per' => q({0}/k),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(kk),
						'other' => q(kk ʻe {0}),
						'per' => q({0}/kk),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(kk),
						'other' => q(kk ʻe {0}),
						'per' => q({0}/kk),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(μk),
						'other' => q(μk ʻe {0}),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(μk),
						'other' => q(μk ʻe {0}),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(mk),
						'other' => q(mk ʻe {0}),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(mk),
						'other' => q(mk ʻe {0}),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(ʻau),
						'other' => q(ʻau ʻe {0}),
						'per' => q({0}/ʻau),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(ʻau),
						'other' => q(ʻau ʻe {0}),
						'per' => q({0}/ʻau),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(ʻau-k),
						'other' => q(ʻau-k ʻe {0}),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(ʻau-k),
						'other' => q(ʻau-k ʻe {0}),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(pāu),
						'other' => q(pāu ʻe {0}),
						'per' => q({0}/pāu),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(pāu),
						'other' => q(pāu ʻe {0}),
						'per' => q({0}/pāu),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(mamafa ☉),
						'other' => q(mamafa ☉ ʻe {0}),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(mamafa ☉),
						'other' => q(mamafa ☉ ʻe {0}),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'other' => q(st ʻe {0}),
					},
					# Core Unit Identifier
					'stone' => {
						'other' => q(st ʻe {0}),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'other' => q(tn ʻe {0}),
					},
					# Core Unit Identifier
					'ton' => {
						'other' => q(tn ʻe {0}),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(to),
						'other' => q(to ʻe {0}),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(to),
						'other' => q(to ʻe {0}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'other' => q(GW ʻe {0}),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'other' => q(GW ʻe {0}),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'other' => q(hp ʻe {0}),
					},
					# Core Unit Identifier
					'horsepower' => {
						'other' => q(hp ʻe {0}),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'other' => q(kW ʻe {0}),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'other' => q(kW ʻe {0}),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'other' => q(MW ʻe {0}),
					},
					# Core Unit Identifier
					'megawatt' => {
						'other' => q(MW ʻe {0}),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'other' => q(mW ʻe {0}),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'other' => q(mW ʻe {0}),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(uate),
						'other' => q(W ʻe {0}),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(uate),
						'other' => q(W ʻe {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(ʻati),
						'other' => q(ʻati ʻe {0}),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(ʻati),
						'other' => q(ʻati ʻe {0}),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(pā),
						'other' => q(pā ʻe {0}),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(pā),
						'other' => q(pā ʻe {0}),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'other' => q(hPa ʻe {0}),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'other' => q(hPa ʻe {0}),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(in-Hg),
						'other' => q(in-Hg ʻe {0}),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(in-Hg),
						'other' => q(in-Hg ʻe {0}),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'other' => q(kPa ʻe {0}),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'other' => q(kPa ʻe {0}),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'other' => q(MPa ʻe {0}),
					},
					# Core Unit Identifier
					'megapascal' => {
						'other' => q(MPa ʻe {0}),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(mpā),
						'other' => q(mpā ʻe {0}),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(mpā),
						'other' => q(mpā ʻe {0}),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(mm-Hg),
						'other' => q(mm-Hg ʻe {0}),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(mm-Hg),
						'other' => q(mm-Hg ʻe {0}),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'other' => q(Pa ʻe {0}),
					},
					# Core Unit Identifier
					'pascal' => {
						'other' => q(Pa ʻe {0}),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(pā/in²),
						'other' => q(pā/in² ʻe {0}),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(pā/in²),
						'other' => q(pā/in² ʻe {0}),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(Pft),
						'other' => q(Pft ʻe {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(Pft),
						'other' => q(Pft ʻe {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'other' => q(km/h ʻe {0}),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'other' => q(km/h ʻe {0}),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(fp),
						'other' => q(fp ʻe {0}),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(fp),
						'other' => q(fp ʻe {0}),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'other' => q(m/s ʻe {0}),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'other' => q(m/s ʻe {0}),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'other' => q(mi/h ʻe {0}),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'other' => q(mi/h ʻe {0}),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(°S),
						'other' => q(°S ʻe {0}),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(°S),
						'other' => q(°S ʻe {0}),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'other' => q(°F ʻe {0}),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'other' => q(°F ʻe {0}),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'other' => q(° ʻe {0}),
					},
					# Core Unit Identifier
					'generic' => {
						'other' => q(° ʻe {0}),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'other' => q(K ʻe {0}),
					},
					# Core Unit Identifier
					'kelvin' => {
						'other' => q(K ʻe {0}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'other' => q(N⋅m ʻe {0}),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'other' => q(N⋅m ʻe {0}),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(pā⋅ft),
						'other' => q(pā⋅ft ʻe {0}),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(pā⋅ft),
						'other' => q(pā⋅ft ʻe {0}),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ʻe-ft),
						'other' => q(ʻe-ft ʻe {0}),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ʻe-ft),
						'other' => q(ʻe-ft ʻe {0}),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(paelo),
						'other' => q(paelo ʻe {0}),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(paelo),
						'other' => q(paelo ʻe {0}),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(pū),
						'other' => q(pū ʻe {0}),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(pū),
						'other' => q(pū ʻe {0}),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(sl),
						'other' => q(sl ʻe {0}),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(sl),
						'other' => q(sl ʻe {0}),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(sm³),
						'other' => q(sm³ ʻe {0}),
						'per' => q({0}/sm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(sm³),
						'other' => q(sm³ ʻe {0}),
						'per' => q({0}/sm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'other' => q(ft³ ʻe {0}),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'other' => q(ft³ ʻe {0}),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'other' => q(in³ ʻe {0}),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'other' => q(in³ ʻe {0}),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'other' => q(km³ ʻe {0}),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'other' => q(km³ ʻe {0}),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'other' => q(m³ ʻe {0}),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'other' => q(m³ ʻe {0}),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'other' => q(mi³ ʻe {0}),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'other' => q(mi³ ʻe {0}),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(it³),
						'other' => q(it³ ʻe {0}),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(it³),
						'other' => q(it³ ʻe {0}),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(ip),
						'other' => q(ip ʻe {0}),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(ip),
						'other' => q(ip ʻe {0}),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(ipm),
						'other' => q(ipm ʻe {0}),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(ipm),
						'other' => q(ipm ʻe {0}),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(tl),
						'other' => q(tl ʻe {0}),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(tl),
						'other' => q(tl ʻe {0}),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(sēpu),
						'other' => q(sēpu ʻe {0}),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(sēpu),
						'other' => q(sēpu ʻe {0}),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(sēpu-ʻem),
						'other' => q(sēpu-ʻem ʻe {0}),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(sēpu-ʻem),
						'other' => q(sēpu-ʻem ʻe {0}),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(tlmu-tf),
						'other' => q(tlmu-tf ʻe {0}),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(tlmu-tf),
						'other' => q(tlmu-tf ʻe {0}),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(tltā),
						'other' => q(tltā ʻe {0}),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(tltā),
						'other' => q(tltā ʻe {0}),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(ʻau-tf),
						'other' => q(ʻau-tf ʻe {0}),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(ʻau-tf),
						'other' => q(ʻau-tf ʻe {0}),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(ʻau-ʻem),
						'other' => q(ʻau-ʻem ʻe {0}),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(ʻau-ʻem),
						'other' => q(ʻau-ʻem ʻe {0}),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(kā),
						'other' => q(kā ʻe {0}),
						'per' => q({0}/kā),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(kā),
						'other' => q(kā ʻe {0}),
						'per' => q({0}/kā),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(kāʻ-em),
						'other' => q(kā-ʻem ʻe {0}),
						'per' => q({0} / kā-ʻem),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(kāʻ-em),
						'other' => q(kā-ʻem ʻe {0}),
						'per' => q({0} / kā-ʻem),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(hl),
						'other' => q(hl ʻe {0}),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(hl),
						'other' => q(hl ʻe {0}),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(sike),
						'other' => q(sike ʻe {0}),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(sike),
						'other' => q(sike ʻe {0}),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(l),
						'other' => q(l ʻe {0}),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(l),
						'other' => q(l ʻe {0}),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(Ml),
						'other' => q(Ml ʻe {0}),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(Ml),
						'other' => q(Ml ʻe {0}),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ml),
						'other' => q(ml ʻe {0}),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ml),
						'other' => q(ml ʻe {0}),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(kiʻimeʻi),
						'other' => q(kiʻimeʻi ʻe {0}),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(kiʻimeʻi),
						'other' => q(kiʻimeʻi ʻe {0}),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'other' => q(pt ʻe {0}),
					},
					# Core Unit Identifier
					'pint' => {
						'other' => q(pt ʻe {0}),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(ptm),
						'other' => q(ptm ʻe {0}),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(ptm),
						'other' => q(ptm ʻe {0}),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(ku),
						'other' => q(ku ʻe {0}),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(ku),
						'other' => q(ku ʻe {0}),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(ku-ʻem),
						'other' => q(ku-ʻem ʻe {0}),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(ku-ʻem),
						'other' => q(ku-ʻem ʻe {0}),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(sētē),
						'other' => q(sētē ʻe {0}),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(sētē),
						'other' => q(sētē ʻe {0}),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(sētī),
						'other' => q(sētī ʻe {0}),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(sētī),
						'other' => q(sētī ʻe {0}),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ʻio|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ʻikai|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				start => q({0} mo {1}),
				middle => q({0} mo {1}),
				end => q({0} mo {1}),
				2 => q({0} mo {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'arab' => {
			'minusSign' => q(‏-),
			'nan' => q(TF),
			'plusSign' => q(‏+),
		},
		'arabext' => {
			'nan' => q(TF),
		},
		'latn' => {
			'nan' => q(TF),
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
					'other' => '0 afe',
				},
				'10000' => {
					'other' => '0 mano',
				},
				'100000' => {
					'other' => '0 kilu',
				},
				'1000000' => {
					'other' => '0 miliona',
				},
				'10000000' => {
					'other' => '00 miliona',
				},
				'100000000' => {
					'other' => '000 miliona',
				},
				'1000000000' => {
					'other' => '0 piliona',
				},
				'10000000000' => {
					'other' => '00 piliona',
				},
				'100000000000' => {
					'other' => '000 piliona',
				},
				'1000000000000' => {
					'other' => '0 tiliona',
				},
				'10000000000000' => {
					'other' => '00 tiliona',
				},
				'100000000000000' => {
					'other' => '000 tiliona',
				},
			},
			'short' => {
				'1000' => {
					'other' => '0a',
				},
				'10000' => {
					'other' => '0m',
				},
				'100000' => {
					'other' => '0k',
				},
				'1000000000' => {
					'other' => '0P',
				},
				'10000000000' => {
					'other' => '00P',
				},
				'100000000000' => {
					'other' => '000P',
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

has 'currencies' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'AUD' => {
			symbol => 'AUD$',
			display_name => {
				'currency' => q(Tola fakaʻaositelēlia),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(ʻEulo),
				'other' => q(ʻeulo),
			},
		},
		'FJD' => {
			symbol => 'F$',
			display_name => {
				'currency' => q(Tola fakafisi),
			},
		},
		'NZD' => {
			symbol => 'NZD$',
			display_name => {
				'currency' => q(Tola fakanuʻusila),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Kina fakapapuaniukini),
			},
		},
		'SBD' => {
			symbol => 'S$',
			display_name => {
				'currency' => q(Tola fakaʻotusolomone),
			},
		},
		'TOP' => {
			symbol => 'T$',
			display_name => {
				'currency' => q(Paʻanga fakatonga),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vatu fakavanuatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Tala fakahaʻamoa),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(Falaniki fakapasifika),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Pa’anga Ta’e’ilo),
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
							'Sān',
							'Fēp',
							'Maʻa',
							'ʻEpe',
							'Mē',
							'Sun',
							'Siu',
							'ʻAok',
							'Sēp',
							'ʻOka',
							'Nōv',
							'Tīs'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Sānuali',
							'Fēpueli',
							'Maʻasi',
							'ʻEpeleli',
							'Mē',
							'Sune',
							'Siulai',
							'ʻAokosi',
							'Sēpitema',
							'ʻOkatopa',
							'Nōvema',
							'Tīsema'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'S',
							'F',
							'M',
							'ʻE',
							'M',
							'S',
							'S',
							'ʻA',
							'S',
							'ʻO',
							'N',
							'T'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Sānuali',
							'Fēpueli',
							'Maʻasi',
							'ʻEpeleli',
							'Mē',
							'Sune',
							'Siulai',
							'ʻAokosi',
							'Sepitema',
							'ʻOkatopa',
							'Nōvema',
							'Tīsema'
						],
						leap => [
							
						],
					},
				},
			},
			'hebrew' => {
				'format' => {
					wide => {
						nonleap => [
							'Tisili',
							'Sesivani',
							'Sisilēvi',
							'Tēpēti',
							'Sēpati',
							'ʻAtā ʻuluaki',
							'ʻAtā',
							'Nisāni',
							'ʻĪāli',
							'Sivāni',
							'Tamusi',
							'ʻĀpi',
							'ʻEluli'
						],
						leap => [
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							undef(),
							
						],
					},
				},
			},
			'indian' => {
				'format' => {
					wide => {
						nonleap => [
							'Kaītira',
							'Vaisāka',
							'Siēsita',
							'Āsiāta',
							'Silāvana',
							'Pātila',
							'Asivini',
							'Kalitika',
							'Akalahāiana',
							'Pausa',
							'Mākiha',
							'Pālikuna'
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
							'Muh',
							'Saf',
							'Lap I',
							'Lap II',
							'Sum I',
							'Sum II',
							'Las',
							'Saʻa',
							'Lam',
							'Sav',
							'Sū-k',
							'Sū-h'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Muhalami',
							'Safali',
							'Lapī I',
							'Lapī II',
							'Sumatā I',
							'Sumatā II',
							'Lasapi',
							'Saʻapāni',
							'Lamatāni',
							'Savāli',
							'Sū-kaʻata',
							'Sū-hisa'
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
						mon => 'Mōn',
						tue => 'Tūs',
						wed => 'Pul',
						thu => 'Tuʻa',
						fri => 'Fal',
						sat => 'Tok',
						sun => 'Sāp'
					},
					wide => {
						mon => 'Mōnite',
						tue => 'Tūsite',
						wed => 'Pulelulu',
						thu => 'Tuʻapulelulu',
						fri => 'Falaite',
						sat => 'Tokonaki',
						sun => 'Sāpate'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'M',
						tue => 'T',
						wed => 'P',
						thu => 'T',
						fri => 'F',
						sat => 'T',
						sun => 'S'
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
					wide => {0 => 'kuata ʻuluaki',
						1 => 'kuata ua',
						2 => 'kuata tolu',
						3 => 'kuata fā'
					},
				},
				'stand-alone' => {
					wide => {0 => 'kuata 1',
						1 => 'kuata 2',
						2 => 'kuata 3',
						3 => 'kuata 4'
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
					'am' => q{HH},
					'pm' => q{EA},
				},
				'wide' => {
					'am' => q{hengihengi},
					'pm' => q{efiafi},
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
				'0' => 'TP'
			},
			wide => {
				'0' => 'Taʻu Puta'
			},
		},
		'chinese' => {
		},
		'coptic' => {
			abbreviated => {
				'0' => 'TMT'
			},
			wide => {
				'0' => 'Taʻu maletile'
			},
		},
		'ethiopic' => {
			abbreviated => {
				'0' => 'TI'
			},
			wide => {
				'0' => 'Taʻu ʻĪtiōpia'
			},
		},
		'ethiopic-amete-alem' => {
			abbreviated => {
				'0' => 'TIAA'
			},
			wide => {
				'0' => 'Taʻu ʻĪtiōpia-ʻAmete-ʻAlemi'
			},
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'KM',
				'1' => 'TS'
			},
			wide => {
				'0' => 'ki muʻa',
				'1' => 'taʻu ʻo Sīsū'
			},
		},
		'hebrew' => {
			abbreviated => {
				'0' => 'TM'
			},
			wide => {
				'0' => 'Taʻu māmani'
			},
		},
		'indian' => {
			abbreviated => {
				'0' => 'TSK'
			},
			wide => {
				'0' => 'Taʻu saka'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'TH'
			},
			wide => {
				'0' => 'Taʻu hola'
			},
		},
		'persian' => {
			abbreviated => {
				'0' => 'TP'
			},
			wide => {
				'0' => 'Taʻu Pēsia'
			},
		},
		'roc' => {
			abbreviated => {
				'0' => 'KMLS',
				'1' => 'TLS'
			},
			wide => {
				'0' => 'Ki muʻa lēpupelika Siaina',
				'1' => 'Taʻu lēpupelika Siaina'
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
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'ethiopic-amete-alem' => {
		},
		'generic' => {
			'full' => q{EEEE d MMMM y G},
			'long' => q{d MMMM y G},
			'medium' => q{d MMM y G},
			'short' => q{d/M/yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d MMMM y},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{d/M/yy},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
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
		'chinese' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'ethiopic-amete-alem' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
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
		'chinese' => {
		},
		'coptic' => {
		},
		'ethiopic' => {
		},
		'ethiopic-amete-alem' => {
		},
		'generic' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1}, {0}},
		},
		'gregorian' => {
			'full' => q{{1}, {0}},
			'long' => q{{1}, {0}},
			'medium' => q{{1}, {0}},
			'short' => q{{1} {0}},
		},
		'hebrew' => {
		},
		'indian' => {
		},
		'islamic' => {
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
		'buddhist' => {
			yyyyMMMM => q{G y MMMM},
		},
		'generic' => {
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{dd MM y GGGGG},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			MEd => q{E d/M},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			y => q{y G},
			yM => q{M-y},
			yMEd => q{E d/M/y},
			yMM => q{MM-y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d-M-y},
			yQQQ => q{y QQQ},
			yQQQQ => q{y QQQQ},
			yyyy => q{y G},
			yyyyM => q{y/MM GGGGG},
			yyyyMEd => q{E dd-MM-y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E d MMM y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{d MMM y G},
			yyyyMd => q{dd/MM/y GGGGG},
			yyyyQQQ => q{y QQQ G},
			yyyyQQQQ => q{y QQQQ G},
		},
		'gregorian' => {
			Ed => q{E d},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E d MMM y G},
			GyMMMd => q{d MMM y G},
			GyMd => q{dd MM y GGGGG},
			MEd => q{E d/M},
			MMMEd => q{E d MMM},
			MMMMEd => q{E d MMMM},
			MMMMW => q{'uike' 'hono' W ʻ'o' MMMM},
			MMMMd => q{d MMMM},
			MMMd => q{d MMM},
			Md => q{d/M},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			yM => q{M/y},
			yMEd => q{E d/M/y},
			yMM => q{MM-y},
			yMMM => q{MMM y},
			yMMMEd => q{E d MMM y},
			yMMMM => q{MMMM y},
			yMMMd => q{d MMM y},
			yMd => q{d/M/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{'uike' 'hono' w ʻ'o' Y},
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
		'generic' => {
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E d/M/y GGGGG – E d/M/y GGGGG},
				M => q{E d/M/y – E d/M/y GGGGG},
				d => q{E d/M/y – E d/M/y GGGGG},
				y => q{E d/M/y – E d/M/y GGGGG},
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
				M => q{M – M},
			},
			MEd => {
				M => q{E d/M – E d/M},
				d => q{E d/M – E d/M},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d MMM – E d MMM},
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
				y => q{y – y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E d/M/y – E d/M/y GGGGG},
				d => q{E d/M/y – E d/M/y GGGGG},
				y => q{E d/M/y – E d/M/y GGGGG},
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
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E d/M/y GGGGG – E d/M/y GGGGG},
				M => q{E d/M/y – E d/M/y GGGGG},
				d => q{E d/M/y – E d/M/y GGGGG},
				y => q{E d/M/y– E d/M/y GGGGG},
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
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E d/M – E d/M},
				d => q{E d/M – E d/M},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E d MMM – E d MMM},
				d => q{E d MMM – E d MMM},
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
				h => q{h – h a v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E d/M/y – E d/M/y},
				d => q{E d/M/y – E d/M/y},
				y => q{E d/M/y – E d/M/y},
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
						0 => q(kamata faʻahitaʻu matala),
						1 => q(vai ʻuha),
						2 => q(fakaʻā ʻinisēkite),
						3 => q(pōtatau faʻahitaʻu matala),
						4 => q(lāofie moe ʻatā),
						5 => q(ʻuha tenga),
						6 => q(kamata faʻahitaʻu mafana),
						7 => q(tenga fonu),
						8 => q(foʻi tenga),
						9 => q(laʻātuʻumaʻu māʻolunga),
						10 => q(vevela siʻi),
						11 => q(vevela lahi),
						12 => q(kamata faʻahitaʻu tōlau),
						13 => q(ʻosi vevala),
						14 => q(hahau hinehina),
						15 => q(pōtatau faʻʻahitaʻu tōlau),
						16 => q(hahau momoko),
						17 => q(haʻu falōsite),
						18 => q(kamata faʻahitaʻu momoko),
						19 => q(sinou siʻi),
						20 => q(sinou lahi),
						21 => q(laʻātuʻumaʻu māʻulalo),
						22 => q(momoko siʻi),
						23 => q(momoko lahi),
					},
				},
			},
			'zodiacs' => {
				'format' => {
					'abbreviated' => {
						0 => q(Kumā),
						1 => q(Pulupokaʻi),
						2 => q(Taika),
						3 => q(Lapisi),
						4 => q(Talakoni),
						5 => q(Ngata),
						6 => q(Hoosi),
						7 => q(Kosi),
						8 => q(Ngeli),
						9 => q(Moataʻane),
						10 => q(Kulī),
						11 => q(Puaka),
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
		regionFormat => q(Taimi {0}),
		regionFormat => q({0} Taimi liliu),
		regionFormat => q({0} Taimi totonu),
		'Acre' => {
			long => {
				'daylight' => q#houa fakaʻakelī taimi liliu#,
				'generic' => q#houa fakaʻakelī#,
				'standard' => q#houa fakaʻakelī taimi totonu#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#houa fakaʻafikānisitani#,
			},
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Sao Tomé#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#houa fakaʻafelika-loto#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#houa fakaʻafelika-hahake#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#houa fakaʻafelika-tonga#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#houa fakaʻafelika-hihifo taimi liliu#,
				'generic' => q#houa fakaʻafelika-hihifo#,
				'standard' => q#houa fakaʻafelika-hihifo taimi totonu#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#houa fakaʻalasika taimi liliu#,
				'generic' => q#houa fakaʻalasika#,
				'standard' => q#houa fakaʻalasika taimi totonu#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#houa fakaʻalamati taimi liliu#,
				'generic' => q#houa fakaʻalamati#,
				'standard' => q#houa fakaʻalamati taimi totonu#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#houa fakaʻamasōne taimi liliu#,
				'generic' => q#houa fakaʻamasōne#,
				'standard' => q#houa fakaʻamasōne taimi totonu#,
			},
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancun#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/New_York' => {
			exemplarCity => q#Niu ʻIoke#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#St. Barthélemy#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#houa fakaʻamelika-tokelau loto taimi liliu#,
				'generic' => q#houa fakaʻamelika-tokelau loto#,
				'standard' => q#houa fakaʻamelika-tokelau loto taimi totonu#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#houa fakaʻamelika-tokelau hahake taimi liliu#,
				'generic' => q#houa fakaʻamelika-tokelau hahake#,
				'standard' => q#houa fakaʻamelika-tokelau hahake taimi totonu#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#houa fakaʻamelika-tokelau moʻunga taimi liliu#,
				'generic' => q#houa fakaʻamelika-tokelau moʻunga#,
				'standard' => q#houa fakaʻamelika-tokelau moʻunga taimi totonu#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#houa fakaʻamelika-tokelau pasifika taimi liliu#,
				'generic' => q#houa fakaʻamelika-tokelau pasifika#,
				'standard' => q#houa fakaʻamelika-tokelau pasifika taimi totonu#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#houa fakalūsia-ʻanatili taimi liliu#,
				'generic' => q#houa fakalūsia-ʻanatili#,
				'standard' => q#houa fakalūsia-ʻanatili taimi totonu#,
			},
		},
		'Apia' => {
			long => {
				'daylight' => q#houa fakaapia taimi liliu#,
				'generic' => q#houa fakaapia#,
				'standard' => q#houa fakaapia taimi totonu#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#houa fakaʻakitau taimi liliu#,
				'generic' => q#houa fakaʻakitau#,
				'standard' => q#houa fakaʻakitau taimi totonu#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#houa fakaʻakitōpe taimi liliu#,
				'generic' => q#houa fakaʻakitōpe#,
				'standard' => q#houa fakaʻakitōpe taimi totonu#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#houa fakaʻalepea taimi liliu#,
				'generic' => q#houa fakaʻalepea#,
				'standard' => q#houa fakaʻalepea taimi totonu#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#houa fakaʻasenitina taimi liliu#,
				'generic' => q#houa fakaʻasenitina#,
				'standard' => q#houa fakaʻasenitina taimi totonu#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#houa fakaʻasenitina-hihifo taimi liliu#,
				'generic' => q#houa fakaʻasenitina-hihifo#,
				'standard' => q#houa fakaʻasenitina-hihifo taimi totonu#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#houa fakaʻāmenia taimi liliu#,
				'generic' => q#houa fakaʻāmenia#,
				'standard' => q#houa fakaʻāmenia taimi totonu#,
			},
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hepeloni#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Selūsalema#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangoon#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#houa fakaʻamelika-tokelau ʻatalanitiki taimi liliu#,
				'generic' => q#houa fakaʻamelika-tokelau ʻatalanitiki#,
				'standard' => q#houa fakaʻamelika-tokelau ʻatalanitiki taimi totonu#,
			},
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Atelaite#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Pelisipane#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Melipoane#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Senē#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#houa fakaʻaositelēlia-loto taimi liliu#,
				'generic' => q#houa fakaʻaositelēlia-loto#,
				'standard' => q#houa fakaʻaositelēlia-loto taimi totonu#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#houa fakaʻaositelēlia-loto-hihifo taimi liliu#,
				'generic' => q#houa fakaʻaositelēlia-loto-hihifo#,
				'standard' => q#houa fakaʻaositelēlia-loto-hihifo taimi totonu#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#houa fakaʻaositelēlia-hahake taimi liliu#,
				'generic' => q#houa fakaʻaositelēlia-hahake#,
				'standard' => q#houa fakaʻaositelēlia-hahake taimi totonu#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#houa fakaʻaositelēlia-hihifo taimi liliu#,
				'generic' => q#houa fakaʻaositelēlia-hihifo#,
				'standard' => q#houa fakaʻaositelēlia-hihifo taimi totonu#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#houa fakaʻasapaisani taimi liliu#,
				'generic' => q#houa fakaʻasapaisani#,
				'standard' => q#houa fakaʻasapaisani taimi totonu#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#houa fakaʻāsolesi taimi liliu#,
				'generic' => q#houa fakaʻāsolesi#,
				'standard' => q#houa fakaʻāsolesi taimi totonu#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#houa fakapāngilātesi taimi liliu#,
				'generic' => q#houa fakapāngilātesi#,
				'standard' => q#houa fakapāngilātesi taimi totonu#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#houa fakapūtani#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#houa fakapolīvia#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#houa fakapalāsila taimi liliu#,
				'generic' => q#houa fakapalāsila#,
				'standard' => q#houa fakapalāsila taimi totonu#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#houa fakapulunei#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#houa fakamuiʻi-vēte taimi liliu#,
				'generic' => q#houa fakamuiʻi-vēte#,
				'standard' => q#houa fakamuiʻi-vēte taimi totonu#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#houa fakakeesi#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#houa fakakamolo#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#houa fakasatihami taimi liliu#,
				'generic' => q#houa fakasatihami#,
				'standard' => q#houa fakasatihami taimi totonu#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#houa fakasili taimi liliu#,
				'generic' => q#houa fakasili#,
				'standard' => q#houa fakasili taimi totonu#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#houa fakasiaina taimi liliu#,
				'generic' => q#houa fakasiaina#,
				'standard' => q#houa fakasiaina taimi totonu#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#houa fakakoipalisani taimi liliu#,
				'generic' => q#houa fakakoipalisani#,
				'standard' => q#houa fakakoipalisani taimi totonu#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#houa fakamotukilisimasi#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#houa fakamotukokosi#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#houa fakakolomipia taimi liliu#,
				'generic' => q#houa fakakolomipia#,
				'standard' => q#houa fakakolomipia taimi totonu#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#houa fakaʻotumotukuki taimi liliu#,
				'generic' => q#houa fakaʻotumotukuki#,
				'standard' => q#houa fakaʻotumotukuki taimi totonu#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#houa fakakiupa taimi liliu#,
				'generic' => q#houa fakakiupa#,
				'standard' => q#houa fakakiupa taimi totonu#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#houa fakatavisi#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#houa fakatūmoni-tūvile#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#houa fakatimoa-hahake#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#houa fakalapanui taimi liliu#,
				'generic' => q#houa fakalapanui#,
				'standard' => q#houa fakalapanui taimi totonu#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#houa fakaʻekuetoa#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#taimi fakaemāmani#,
			},
			short => {
				'standard' => q#TMT#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Feituʻu taʻeʻiloa#,
		},
		'Europe/Athens' => {
			exemplarCity => q#ʻAtenisi#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#houa fakaʻaealani taimi totonu#,
			},
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiev#,
		},
		'Europe/London' => {
			exemplarCity => q#Lonitoni#,
			long => {
				'daylight' => q#houa fakapilitānia taimi liliu#,
			},
		},
		'Europe/Moscow' => {
			exemplarCity => q#Mosikou#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Palesi#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Loma#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uzhhorod#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikani#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#houa fakaʻeulope-loto taimi liliu#,
				'generic' => q#houa fakaʻeulope-loto#,
				'standard' => q#houa fakaʻeulope-loto taimi totonu#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#houa fakaʻeulope-hahake taimi liliu#,
				'generic' => q#houa fakaʻeulope-hahake#,
				'standard' => q#houa fakaʻeulope-hahake taimi totonu#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#houa fakaʻeulope-hahake-ange#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#houa fakaʻeulope-hihifo taimi liliu#,
				'generic' => q#houa fakaʻeulope-hihifo#,
				'standard' => q#houa fakaʻeulope-hihifo taimi totonu#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#houa fakaʻotumotu-fokulani taimi liliu#,
				'generic' => q#houa fakaʻotumotu-fokulani#,
				'standard' => q#houa fakaʻotumotu-fokulani taimi totonu#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#houa fakafisi taimi liliu#,
				'generic' => q#houa fakafisi#,
				'standard' => q#houa fakafisi taimi totonu#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#houa fakakuiana-fakafalanisē#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#houa fakaʻanetātikafalanisē#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#houa fakakiliniuisi mālie#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#houa fakakalapakosi#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#houa fakakamipiē#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#houa fakaseōsia taimi liliu#,
				'generic' => q#houa fakaseōsia#,
				'standard' => q#houa fakaseōsia taimi totonu#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#houa fakakilipasi#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#houa fakafonuamata-hahake taimi liliu#,
				'generic' => q#houa fakafonuamata-hahake#,
				'standard' => q#houa fakafonuamata-hahake taimi totonu#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#houa fakafonuamata-hihifo taimi liliu#,
				'generic' => q#houa fakafonuamata-hihifo#,
				'standard' => q#houa fakafonuamata-hihifo taimi totonu#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#houa fakakuami#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#houa fakakūlifi#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#houa fakakuiana#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#houa fakahauaiʻi-aleuti taimi liliu#,
				'generic' => q#houa fakahauaiʻi-aleuti#,
				'standard' => q#houa fakahauaiʻi-aleuti taimi totonu#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#houa fakahongi-kongi taimi liliu#,
				'generic' => q#houa fakahongi-kongi#,
				'standard' => q#houa fakahongi-kongi taimi totonu#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#houa fakahovite taimi liliu#,
				'generic' => q#houa fakahovite#,
				'standard' => q#houa fakahovite taimi totonu#,
			},
		},
		'India' => {
			long => {
				'standard' => q#houa fakaʻinitia#,
			},
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#houa fakamoanaʻinitia#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#houa fakaʻinitosiaina#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#houa fakaʻinitonisia-loto#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#houa fakaʻinitonisia-hahake#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#houa fakaʻinitonisia-hihifo#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#houa fakaʻilaani taimi liliu#,
				'generic' => q#houa fakaʻilaani#,
				'standard' => q#houa fakaʻilaani taimi totonu#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#houa fakalūsia-ʻīkutisiki taimi liliu#,
				'generic' => q#houa fakalūsia-ʻīkutisiki#,
				'standard' => q#houa fakalūsia-ʻīkutisiki taimi totonu#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#houa fakaʻisileli taimi liliu#,
				'generic' => q#houa fakaʻisileli#,
				'standard' => q#houa fakaʻisileli taimi totonu#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#houa fakasiapani taimi liliu#,
				'generic' => q#houa fakasiapani#,
				'standard' => q#houa fakasiapani taimi totonu#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#houa fakalūsia-petelopavilovisiki taimi liliu#,
				'generic' => q#houa fakalūsia-petelopavilovisiki#,
				'standard' => q#houa fakalūsia-petelopavilovisiki taimi totonu#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#houa fakakasakitani-hahake#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#houa fakakasakitani-hihifo#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#houa fakakōlea taimi liliu#,
				'generic' => q#houa fakakōlea#,
				'standard' => q#houa fakakōlea taimi totonu#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#houa fakakosilae#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#houa fakalūsia-kalasinoiāsiki taimi liliu#,
				'generic' => q#houa fakalūsia-kalasinoiāsiki#,
				'standard' => q#houa fakalūsia-kalasinoiāsiki taimi totonu#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#houa fakakīkisitani#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#houa fakalangikā#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#houa fakaʻotumotulaine#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#houa fakamotuʻeikihoue taimi liliu#,
				'generic' => q#houa fakamotuʻeikihoue#,
				'standard' => q#houa fakamotuʻeikihoue taimi totonu#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#houa fakamakau taimi liliu#,
				'generic' => q#houa fakamakau#,
				'standard' => q#houa fakamakau taimi totonu#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#houa fakamotumakuali#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#houa fakalūsia-makatani taimi liliu#,
				'generic' => q#houa fakalūsia-makatani#,
				'standard' => q#houa fakalūsia-makatani taimi totonu#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#houa fakamaleisia#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#houa fakamalativisi#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#houa fakamākesasi#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#houa fakaʻotumotumasolo#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#houa fakamaulitiusi taimi liliu#,
				'generic' => q#houa fakamaulitiusi#,
				'standard' => q#houa fakamaulitiusi taimi totonu#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#houa fakamausoni#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#houa fakamekisikou-tokelauhihifo taimi liliu#,
				'generic' => q#houa fakamekisikou-tokelauhihifo#,
				'standard' => q#houa fakamekisikou-tokelauhihifo taimi totonu#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#houa fakamekisikou-pasifika taimi liliu#,
				'generic' => q#houa fakamekisikou-pasifika#,
				'standard' => q#houa fakamekisikou-pasifika taimi totonu#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#houa fakaʻulānipātā taimi liliu#,
				'generic' => q#houa fakaʻulānipātā#,
				'standard' => q#houa fakaʻulānipātā taimi totonu#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#houa fakalūsia-mosikou taimi liliu#,
				'generic' => q#houa fakalūsia-mosikou#,
				'standard' => q#houa fakalūsia-mosikou taimi totonu#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#houa fakapema#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#houa fakanaulu#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#houa fakanepali#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#houa fakakaletōniafoʻou taimi liliu#,
				'generic' => q#houa fakakaletōniafoʻou#,
				'standard' => q#houa fakakaletōniafoʻou taimi totonu#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#houa fakanuʻusila taimi liliu#,
				'generic' => q#houa fakanuʻusila#,
				'standard' => q#houa fakanuʻusila taimi totonu#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#houa fakafonuaʻilofoʻou taimi liliu#,
				'generic' => q#houa fakafonuaʻilofoʻou#,
				'standard' => q#houa fakafonuaʻilofoʻou taimi totonu#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#houa fakaniuē#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#houa fakanoafōki taimi liliu#,
				'generic' => q#houa fakanoafōki#,
				'standard' => q#houa fakanoafōki taimi totonu#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#houa fakafēnanito-te-nolōnia taimi liliu#,
				'generic' => q#houa fakafēnanito-te-nolōnia#,
				'standard' => q#houa fakafēnanito-te-nolōnia taimi totonu#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#houa fakamalianatokelau#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#houa fakalūsia-novosipīsiki taimi liliu#,
				'generic' => q#houa fakalūsia-novosipīsiki#,
				'standard' => q#houa fakalūsia-novosipīsiki taimi totonu#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#houa fakalūsia-ʻomisiki taimi liliu#,
				'generic' => q#houa fakalūsia-ʻomisiki#,
				'standard' => q#houa fakalūsia-ʻomisiki taimi totonu#,
			},
		},
		'Pacific/Auckland' => {
			exemplarCity => q#ʻAokalani#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Pukanivila#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Lapanui#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#ʻEnitipulī#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fisi#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Kamipiē#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Kuatākanali#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Kuami#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
			short => {
				'daylight' => q#HTL#,
				'generic' => q#HTT#,
				'standard' => q#HTT#,
			},
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Sionesitoni#,
		},
		'Pacific/Kanton' => {
			exemplarCity => q#Kanitoni#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kilisimasi#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosilae#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kuasaleni#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Masulo#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Malikuesa#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Mitiuai#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#Naulu#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#Niuē#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#Noafōki#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pangopango#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitikeni#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Ponapē#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Taulanga Molesipi#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Lalotonga#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saʻipani#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahisi#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Talava#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Tūke#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Ueke#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#ʻUvea#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#houa fakapākisitani taimi liliu#,
				'generic' => q#houa fakapākisitani#,
				'standard' => q#houa fakapākisitani taimi totonu#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#houa fakapalau#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#houa fakapapuaniukini#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#houa fakapalakuai taimi liliu#,
				'generic' => q#houa fakapalakuai#,
				'standard' => q#houa fakapalakuai taimi totonu#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#houa fakapelū taimi liliu#,
				'generic' => q#houa fakapelū#,
				'standard' => q#houa fakapelū taimi totonu#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#houa fakafilipaine taimi liliu#,
				'generic' => q#houa fakafilipaine#,
				'standard' => q#houa fakafilipaine taimi totonu#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#houa fakaʻotumotufoinikisi#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#houa fakasā-piea-mo-mikeloni taimi liliu#,
				'generic' => q#houa fakasā-piea-mo-mikeloni#,
				'standard' => q#houa fakasā-piea-mo-mikeloni taimi totonu#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#houa fakapitikani#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#houa fakapōnapē#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#houa fakapiongiangi#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#houa fakakisilōta taimi liliu#,
				'generic' => q#houa fakakisilōta#,
				'standard' => q#houa fakakisilōta taimi totonu#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#houa fakalēunioni#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#houa fakalotela#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#houa fakalūsia-sakāline taimi liliu#,
				'generic' => q#houa fakalūsia-sakāline#,
				'standard' => q#houa fakalūsia-sakāline taimi totonu#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#houa fakalūsia-samala taimi liliu#,
				'generic' => q#houa fakalūsia-samala#,
				'standard' => q#houa fakalūsia-samala taimi totonu#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#houa fakahaʻamoa taimi liliu#,
				'generic' => q#houa fakahaʻamoa#,
				'standard' => q#houa fakahaʻamoa taimi totonu#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#houa fakaʻotumotu-seiseli#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#houa fakasingapoa#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#houa fakaʻotumotusolomone#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#houa fakasiosiatonga#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#houa fakasuliname#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#houa fakasioua#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#houa fakatahisi#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#houa fakataipei taimi liliu#,
				'generic' => q#houa fakataipei#,
				'standard' => q#houa fakataipei taimi totonu#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#houa fakatasikitani#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#houa fakatokelau#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#houa fakatonga taimi liliu#,
				'generic' => q#houa fakatonga#,
				'standard' => q#houa fakatonga taimi totonu#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#houa fakatūke#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#houa fakatūkimenisitani taimi liliu#,
				'generic' => q#houa fakatūkimenisitani#,
				'standard' => q#houa fakatūkimenisitani taimi totonu#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#houa fakatūvalu#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#houa fakaʻulukuai taimi liliu#,
				'generic' => q#houa fakaʻulukuai#,
				'standard' => q#houa fakaʻulukuai taimi totonu#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#houa fakaʻusipekitani taimi liliu#,
				'generic' => q#houa fakaʻusipekitani#,
				'standard' => q#houa fakaʻusipekitani taimi totonu#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#houa fakavanuatu taimi liliu#,
				'generic' => q#houa fakavanuatu#,
				'standard' => q#houa fakavanuatu taimi totonu#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#houa fakavenesuela#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#houa fakalūsia-valativositoki taimi liliu#,
				'generic' => q#houa fakalūsia-valativositoki#,
				'standard' => q#houa fakalūsia-valativositoki taimi totonu#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#houa fakalūsia-volikokalati taimi liliu#,
				'generic' => q#houa fakalūsia-volikokalati#,
				'standard' => q#houa fakalūsia-volikokalati taimi totonu#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#houa fakavositoki#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#houa fakamotuueke#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#houa fakaʻuvea mo futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#houa fakalūsia-ʻiākutisiki taimi liliu#,
				'generic' => q#houa fakalūsia-ʻiākutisiki#,
				'standard' => q#houa fakalūsia-ʻiākutisiki taimi totonu#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#houa fakalūsia-ʻiekatelinepūki taimi liliu#,
				'generic' => q#houa fakalūsia-ʻiekatelinepūki#,
				'standard' => q#houa fakalūsia-ʻiekatelinepūki taimi totonu#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#houa fakaiukoni#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
