=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Ksh - Package for language Colognian

=cut

package Locale::CLDR::Locales::Ksh;
# This file auto generated from Data\common\main\ksh.xml
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

	my $display_pattern = '{0} en {1}';
	$display_pattern =~s/\{0\}/$name/g;
	my $subtags = join '{0} uß {1}', grep {$_} (
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
				'aa' => 'Afahresch',
 				'ab' => 'Abchahsesch',
 				'ace' => 'Aschenehsesch',
 				'ada' => 'Adangmesch',
 				'ady' => 'Adygehjsch',
 				'ae' => 'Avästahnesch',
 				'aeb' => 'Tonehsesch Arahbesch',
 				'af' => 'Afrikaans',
 				'afh' => 'Afrehihlesch',
 				'agq' => 'Aghehmesch',
 				'ain' => 'Aijnu',
 				'ak' => 'Akahnesch',
 				'akk' => 'Akahdesch',
 				'ale' => 'Ale’uhtesch',
 				'am' => 'Amhahresch',
 				'an' => 'Arrajonehsesch',
 				'ang' => 'Ahl Änglesch',
 				'anp' => 'Anjikahnesch',
 				'ar' => 'Arahbesch',
 				'ar_001' => 'Schtandatt Arahbesch',
 				'arp' => 'Arrappaho',
 				'arq' => 'Aljehresch Arahbesch',
 				'ary' => 'Marokahnesch Arahbesch',
 				'arz' => 'Äjiptesch Arahbesch',
 				'as' => 'Aßamehsesch',
 				'asa' => 'Pare',
 				'ase' => 'Amärrekahnesche Blendeschprohch',
 				'ast' => 'Astuhrejahnesch',
 				'av' => 'Avahresch',
 				'awa' => 'Awahdesch',
 				'ay' => 'Aimahresch',
 				'az' => 'Asserbaidschahnesch',
 				'az@alt=short' => 'Asehresch',
 				'az_Arab' => 'Södasserbaidschahnesch',
 				'ba' => 'Baschkihresch',
 				'bal' => 'Beluhtschesch',
 				'ban' => 'Balinehsesch',
 				'bar' => 'Bairesch',
 				'bas' => 'Basaa-Schprohche',
 				'be' => 'Wiißrußesch',
 				'bem' => 'Bemba',
 				'bez' => 'Bena',
 				'bg' => 'Bulljahresch',
 				'bho' => 'Bhohdschpuresch',
 				'bi' => 'Bislahmesch',
 				'bin' => 'Edo',
 				'bm' => 'Bambara',
 				'bn' => 'Bängjahlesch',
 				'bo' => 'Tibehtesch',
 				'bpy' => 'Bischnuprejahnesch',
 				'br' => 'Bettohnesch',
 				'bra' => 'Brahjesch',
 				'brh' => 'Brahuijesch',
 				'brx' => 'Boddo',
 				'bs' => 'Boßnesch',
 				'bua' => 'Burejahtesch',
 				'bug' => 'Bujinehsesch',
 				'byn' => 'Bilihnesch',
 				'ca' => 'Kattalahnesch',
 				'ce' => 'Tschätschehnesch',
 				'ceb' => 'Zebuwahnesch',
 				'cgg' => 'Kihja-Schprohch',
 				'ch' => 'Chamorru',
 				'chk' => 'Trukehsesch',
 				'chm' => 'Mahresch',
 				'cho' => 'Tschoktoh',
 				'chr' => 'Tschärrokeh',
 				'chy' => 'Tschäjänn',
 				'ckb' => 'Zäntrahl-Kurrdesch',
 				'co' => 'Korsesch',
 				'cop' => 'Koptesch',
 				'cs' => 'Tschäschesch',
 				'csb' => 'Kaschuhbesch',
 				'cu' => 'Kerscheßlahwesch',
 				'cv' => 'Tschowaschesch',
 				'cy' => 'Wallihsesch',
 				'da' => 'Dähnesch',
 				'dak' => 'Dakohtesch',
 				'dar' => 'Darjihnesch',
 				'dav' => 'Dawedahnesch',
 				'de' => 'Deutsch',
 				'de_AT' => 'Deutsch uß Öhßterich',
 				'de_CH' => 'Deutsch uß de Schweijz',
 				'dgr' => 'Dohjribesch',
 				'dje' => 'Djerma',
 				'dsb' => 'Niddersorbesch',
 				'dua' => 'Du’ala',
 				'dum' => 'Meddelnehderlängsch',
 				'dv' => 'Divehjesch',
 				'dyo' => 'Jola-Fonyisch',
 				'dz' => 'Butahnesch',
 				'dzg' => 'Dassajahnesch',
 				'ebu' => 'Kîembu',
 				'ee' => 'Ewe',
 				'efi' => 'Äffiksch',
 				'egl' => 'Emilijahnesch',
 				'egy' => 'Ahl Äjiptesch',
 				'eka' => 'Ekajukesch',
 				'el' => 'Jrihschesch',
 				'en' => 'Änglesch',
 				'en_AU' => 'Änglesch uß Außtrahlije',
 				'en_CA' => 'Änglesch uß Kanada',
 				'en_GB' => 'Änglesch uß Jruhßbrettannije',
 				'en_GB@alt=short' => 'Brettesch Änglesch',
 				'en_US' => 'Amärrekahnesch Änglesch',
 				'en_US@alt=short' => 'Änglesch uß de USA',
 				'enm' => 'Meddelänglesch',
 				'eo' => 'Esperanto',
 				'es' => 'Schpahnesch',
 				'es_419' => 'Schpahnesch uß Latting-Ammärrika',
 				'es_ES' => 'Schpahnesch en Schpahneje',
 				'es_MX' => 'Schpahnesch en Mäxikoh',
 				'esu' => 'Zäntrahl-Juppik',
 				'et' => 'Äßnesch',
 				'eu' => 'Baskesch',
 				'ewo' => 'Ewonndo',
 				'fa' => 'Pärsesch',
 				'ff' => 'Fulfulde',
 				'fi' => 'Finnesch',
 				'fil' => 'Fillipihnesch',
 				'fj' => 'Fihdschesch',
 				'fo' => 'Färröhresch',
 				'fon' => 'Fohnesch',
 				'fr' => 'Franzühsesch',
 				'fr_CA' => 'Franzühsesch uß Kanada',
 				'fr_CH' => 'Franzühsesch uß de Schweijz',
 				'fur' => 'Frijauhlesch',
 				'fy' => 'Wäßfrihsesch',
 				'ga' => 'Ihresch',
 				'gaa' => 'Jah',
 				'gez' => 'Ji’is-Ahl-Ättejohpesch',
 				'gil' => 'Jillbättehsesch',
 				'gl' => 'Jallihzesch',
 				'gn' => 'Juwarahnesch',
 				'gor' => 'Jorontalohsch',
 				'gsw' => 'Schwitzerdütsch',
 				'gu' => 'Gutscharatesch',
 				'gv' => 'Mangx',
 				'ha' => 'Haußa',
 				'haw' => 'Hauajahnesch',
 				'he' => 'Hebrähjesch',
 				'hi' => 'Hinndi',
 				'hil' => 'Hiligaynon',
 				'hmn' => 'Hmong',
 				'hr' => 'Krowatesch',
 				'hsb' => 'Bovversorrbesch',
 				'ht' => 'Ha’iihtesch',
 				'hu' => 'Unnjarresch',
 				'hup' => 'Hupa',
 				'hy' => 'Armehnesch',
 				'hz' => 'Herrehro',
 				'ia' => 'de Interlingua',
 				'iba' => 'Ibahnesch',
 				'ibb' => 'Ibibio',
 				'id' => 'Indonehsesch',
 				'ig' => 'Igbo',
 				'ilo' => 'Ilokahnesch',
 				'inh' => 'Engjuschesch',
 				'io' => 'Ihdo',
 				'is' => 'Ißlänndesch',
 				'it' => 'Etalljähnesch',
 				'iu' => 'Inuktitut',
 				'izh' => 'Ingjrijahnesch',
 				'ja' => 'Japahnesch',
 				'jam' => 'Jamaikahnesch-Änglesch',
 				'jbo' => 'Lodschbahn',
 				'jgo' => 'Njomba',
 				'jpr' => 'Jühdesch-Pärsesch',
 				'jut' => 'Jüttesch',
 				'jv' => 'Javahnesch',
 				'ka' => 'Je’orjesch',
 				'kab' => 'Kabyhlesch',
 				'kam' => 'Kamba vun Kehnija',
 				'kbd' => 'Kabadihnesch',
 				'kde' => 'Chimakonde',
 				'kea' => 'Kapvärdesch',
 				'kfo' => 'Koro vun de Älfebeijnköß',
 				'kha' => 'Khasi',
 				'khq' => 'Kojra Tschihni',
 				'ki' => 'Rekohjo',
 				'kj' => 'Oschivambo',
 				'kk' => 'Kassakkesch',
 				'kkj' => 'Kako',
 				'kl' => 'Jröhnländesch',
 				'kln' => 'Kaländjihnesch',
 				'km' => 'Khmer',
 				'kmb' => 'Kimbundu',
 				'kn' => 'Kannada',
 				'ko' => 'Korrejaanesch',
 				'kok' => 'Kon’kahnesch',
 				'kpe' => 'Kpäle',
 				'kr' => 'Kanuhresch',
 				'krc' => 'Karatschaj-Balkahresch-Törkesch',
 				'krl' => 'Karehlesch',
 				'kru' => 'Korochesch',
 				'ks' => 'Kaschmihresch',
 				'ksf' => 'Bafijahnesch',
 				'ksh' => 'Kölsch',
 				'ku' => 'Kurrdesch',
 				'kum' => 'Kumykesch',
 				'kv' => 'Kohmesch',
 				'kw' => 'Kornesch',
 				'ky' => 'Kirjihsesch',
 				'la' => 'Lateijnesch',
 				'lad' => 'Ladihnesch',
 				'lag' => 'Lango',
 				'lah' => 'de Landa-Schprooche',
 				'lb' => 'Luxemborjesch',
 				'lez' => 'Lesjesch',
 				'lg' => 'Lugannda',
 				'li' => 'Lemburjesch',
 				'lkt' => 'Lakota',
 				'ln' => 'Lingjalla',
 				'lo' => 'Lahootesch',
 				'loz' => 'Silohzi',
 				'lrc' => 'Nood-Luhresch',
 				'lt' => 'Littouesch',
 				'lu' => 'Kiluba',
 				'lua' => 'Tschiluba',
 				'lun' => 'Schilunnda',
 				'luo' => 'Luo',
 				'luy' => 'Luhjesch',
 				'lv' => 'Lättesch',
 				'mdf' => 'Mokschah',
 				'mg' => 'Madajaßkesch',
 				'mh' => 'Maschallehsesch',
 				'mi' => 'Ma’ohresch',
 				'mk' => 'Mazedohnesch',
 				'ml' => 'Mallajalam',
 				'mn' => 'Mongjohlesch',
 				'mni' => 'Meitei-Manipuhresch',
 				'mr' => 'Marrahtesch',
 				'ms' => 'Mallaijesch',
 				'mt' => 'Maltehsesch',
 				'mua' => 'Mundang',
 				'mul' => '-ongerscheidlijje Schprohche-',
 				'mus' => 'Krihk',
 				'mwl' => 'Mirandehsesch',
 				'my' => 'Burmehsesch',
 				'myv' => 'Ärsjahnesch',
 				'na' => 'Nauruhesch',
 				'nap' => 'Napolletahnesch',
 				'nb' => 'Norrwehjesch Bokmål',
 				'nd' => 'Nood-Ndebele',
 				'nds_NL' => 'Nehdersaksesch en de Nederläng',
 				'ne' => 'Nepallehsesch',
 				'new' => 'Newahresch',
 				'ng' => 'Ndongjahnesch',
 				'nl' => 'Holländesch',
 				'nl_BE' => 'Flähmesch',
 				'nmg' => 'Gyele',
 				'nn' => 'Neu Norrwehjesch',
 				'nnh' => 'Njijembohn',
 				'no' => 'Norrwehjesch',
 				'nog' => 'Nojal',
 				'nso' => 'Nood-Sohto',
 				'nv' => 'Navvacho',
 				'ny' => 'Schi-Schewa',
 				'or' => 'Oriija',
 				'os' => 'Oßeetesch',
 				'pa' => 'Panschaabesch',
 				'pl' => 'Pollnesch',
 				'ps' => 'Paschtuunesch',
 				'pt' => 'Pochtojesesch',
 				'pt_BR' => 'Brasilljaanesch Pochtojesesch',
 				'pt_PT' => 'Pochtojesesch uß Pochtojall',
 				'qu' => 'Kättschowa',
 				'quc' => 'K’ische’',
 				'rm' => 'Rätoromaanesch',
 				'rn' => 'K-Rundesch',
 				'ro' => 'Rumänesch',
 				'rof' => 'Kirombo',
 				'ru' => 'Rußßesch',
 				'rup' => 'Arromahnesch',
 				'rw' => 'Kinja-Ruandesch',
 				'sa' => 'Sanskrit',
 				'sah' => 'Jackutesch',
 				'sba' => 'Njambaij',
 				'sd' => 'Sinndi',
 				'se' => 'Nood-Lappländesch',
 				'ses' => 'Kojraboro Senni',
 				'sg' => 'Sangjo',
 				'sh' => 'Särbokowatesch',
 				'shi' => 'Taschelhittesch',
 				'si' => 'Singjaleesesch',
 				'sk' => 'ẞlovakesch',
 				'sl' => 'ẞloveenesch',
 				'sm' => 'Sammohanesch',
 				'smj' => 'Lule-Läppländesch',
 				'smn' => 'Inahri Lappländesch',
 				'sn' => 'Schi-Schona',
 				'so' => 'Somahlesch',
 				'sq' => 'Albahnesch',
 				'sr' => 'Särbesch',
 				'ss' => 'Si-Swatesch',
 				'st' => 'Söd-Sooto',
 				'su' => 'Sindanehsesch',
 				'sv' => 'Schwehdesch',
 				'sw' => 'Suahehlesch',
 				'swb' => 'Kommohresch',
 				'syr' => 'Sührejakkesch',
 				'ta' => 'Tamihlesch',
 				'te' => 'Telluhju',
 				'tet' => 'Tetumsch',
 				'tg' => 'Tadschihkesch',
 				'th' => 'Tailändesch',
 				'ti' => 'Tijrenejahnesch',
 				'tig' => 'Tigre',
 				'tk' => 'Törkmehnesch',
 				'tl' => 'Tajalloch',
 				'tlh' => 'Klingjohnesch',
 				'tn' => 'Se-Zwahnesch',
 				'to' => 'Tongjahnesch',
 				'tpi' => 'Tok Pisin',
 				'tr' => 'Törkesch',
 				'ts' => 'Xi-Zongjahnesch',
 				'tt' => 'Tattahresch',
 				'twq' => 'Tasawaq',
 				'ty' => 'Tahihtesch',
 				'tyv' => 'Tuvinijahnesch',
 				'tzm' => 'Tamasicht ussem meddlere Atlas',
 				'udm' => 'Udmuchtesch',
 				'ug' => 'Uj’juhresch',
 				'uk' => 'Ukrainesch',
 				'umb' => 'Umbundesch',
 				'und' => '-onbikannte-Schprooch-',
 				'ur' => 'Urdu/Hindi',
 				'uz' => 'Ußbehkesch',
 				've' => 'Wenda',
 				'vi' => 'Vijätnammehsesch',
 				'vo' => 'Volapük',
 				'wa' => 'Walohnesch',
 				'wae' => 'Walserdütsch',
 				'wal' => 'Welahmo',
 				'war' => 'Waray-Waray',
 				'wo' => 'Woloff',
 				'xal' => 'Kalmükkesch',
 				'xh' => 'Isi-Khohsa',
 				'ybb' => 'Jämmbah',
 				'yi' => 'Jiddesch',
 				'yo' => 'Joruhba',
 				'yue' => 'Kanton-Schinehsesch',
 				'zh' => 'Schinehsesch (Mandarin)',
 				'zh_Hans' => 'Schinehsesch (eijfache Schreff)',
 				'zh_Hant' => 'Schinehsesch (tradizjonälle Schreff)',
 				'zu' => 'Suhlu',
 				'zun' => 'Suhñi',
 				'zxx' => 'kein Schprooch',
 				'zza' => 'Sahsajesch',

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
			'Arab' => 'arraabesche Schreff',
 			'Armn' => 'armeenesche Schreff',
 			'Beng' => 'bängjaalesche Schreff',
 			'Bopo' => 'schineeseche Ömschreff Bopomofo',
 			'Brai' => 'Blindeschreff',
 			'Cyrl' => 'kürrellesche Schreff',
 			'Deva' => 'indesche Devanajari-Schreff',
 			'Ethi' => 'ätejoopesche Schreff',
 			'Geor' => 'je’orrjesche Schreff',
 			'Grek' => 'jriischesche Schreff',
 			'Gujr' => 'jujaraatesche Schreff',
 			'Guru' => 'indesche Gurmukhi-Schreff',
 			'Hang' => 'korrejaanesche Schreff',
 			'Hani' => 'en schineesesche Schreff',
 			'Hans' => 'eijfacher',
 			'Hans@alt=stand-alone' => 'eijfacher schineesesche Schreff',
 			'Hant' => 'tradizjonäll',
 			'Hant@alt=stand-alone' => 'tradizjonäll schineesesche Schreff',
 			'Hebr' => 'hebrääjesche Schreff',
 			'Hira' => 'japaanesche Hiddajaana-Schreff',
 			'Jpan' => 'en japaanesche Schreff',
 			'Kana' => 'japaanesche Kattakaana-Schreff',
 			'Khmr' => 'Khmer-Schreff',
 			'Knda' => 'indesche Kannada-Schreff',
 			'Kore' => 'korrejaanesche Schreff udder en schineesesche Schreff',
 			'Laoo' => 'lahootesche Schreff',
 			'Latn' => 'lateinesche Schreff',
 			'Mlym' => 'indesche Malajalam-Schreff',
 			'Mong' => 'mongjoolesche Schreff',
 			'Mymr' => 'birmahnesche Schreff',
 			'Orya' => 'indesche Orija-Schreff',
 			'Sinh' => 'singjaleesesche Schreff',
 			'Taml' => 'tamiilesche Schreff',
 			'Telu' => 'indesche Telugu-Schreff',
 			'Thaa' => 'malledivesche Taana-Schreff',
 			'Thai' => 'tailändesche Schreff',
 			'Tibt' => 'tibeetesche Schreff',
 			'Zsym' => '-Zeiche ävver kein Schreff-',
 			'Zxxx' => '-jaa keij Schreff-',
 			'Zyyy' => '-öhnß en Schreff-',
 			'Zzzz' => '-onbikannte Schreff-',

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
			'001' => 'de Ääd',
 			'002' => 'Affrika',
 			'003' => 'Nood-Amärrika',
 			'005' => 'Söhd-Amärrika',
 			'009' => 'Ozejahneje',
 			'011' => 'Wäß-Affrika',
 			'013' => 'Meddelammärrika',
 			'014' => 'Oß-Affrika',
 			'015' => 'Nood-Affrika',
 			'017' => 'Meddel-Affrika',
 			'018' => 'Söhd-Affrika',
 			'019' => 'Ammärrika',
 			'021' => 'der Norde vun Amärrika',
 			'029' => 'de Karribik',
 			'030' => 'Oß-Aasije',
 			'034' => 'Söhd-Aasije',
 			'035' => 'Söhd-Oß-Aasije',
 			'039' => 'Söhd-Europpa',
 			'053' => 'de Rejjohn öm Austrahlije',
 			'054' => 'Mellanehsije',
 			'057' => 'de Rejohn vun Mikronehseje',
 			'061' => 'Polinehsije',
 			'142' => 'Aasije',
 			'143' => 'Meddelaasije',
 			'145' => 'Wäß-Aasije',
 			'150' => 'Europpa',
 			'151' => 'Oß-Europpa',
 			'154' => 'Nood-Europpa',
 			'155' => 'Wäß-Europpa',
 			'419' => 'Lateinamärrika',
 			'AC' => 'Aßension',
 			'AD' => 'Andorra',
 			'AE' => 'Vereinschte Arrabesche Emmirate',
 			'AF' => 'Afjaanistahn',
 			'AG' => 'Antigwa un Barbuda',
 			'AI' => 'Anggwilla',
 			'AL' => 'Albaanije',
 			'AM' => 'Arrmeenije',
 			'AO' => 'Angjoola',
 			'AQ' => 'der Södpol',
 			'AR' => 'Ajjentiinije',
 			'AS' => 'Ammerikaanesch Sammoha',
 			'AT' => 'Öösterisch',
 			'AU' => 'Austraalije',
 			'AW' => 'Aruba',
 			'AX' => 'de Ohland-Enselle',
 			'AZ' => 'Asserbaidschahn',
 			'BA' => 'Boßnije un Herzegovina',
 			'BB' => 'de Ensel Barbados',
 			'BD' => 'Bangladesch',
 			'BE' => 'Bellje',
 			'BF' => 'Bukkinna-Faase',
 			'BG' => 'Bulljaarije',
 			'BH' => 'Bachrain',
 			'BI' => 'Burundi',
 			'BJ' => 'dä Benin',
 			'BL' => 'de Zint Battälmi-Enselle',
 			'BM' => 'de Bermudas',
 			'BN' => 'Brunei',
 			'BO' => 'Bolliivije',
 			'BQ' => 'de karribbesche Nederläng',
 			'BR' => 'Brasilije',
 			'BS' => 'de Bahamas',
 			'BT' => 'Buttaan',
 			'BV' => 'de Buvee-Ensel',
 			'BW' => 'Bozwaana',
 			'BY' => 'Wießrußland',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'de Kokkos-Enselle',
 			'CD' => 'dä Konggo (Kinschasa)',
 			'CD@alt=variant' => 'de Demmokraatesche Republik Konggo',
 			'CF' => 'de Zäntraalaffrikaanesche Republik',
 			'CG' => 'dä Konggo (Brassavill)',
 			'CG@alt=variant' => 'de Republik Konggo',
 			'CH' => 'de Schweiz',
 			'CI' => 'Älfebeijn-Köß',
 			'CI@alt=variant' => 'de Älfebeijnköß',
 			'CK' => 'de Kuuk-Enselle',
 			'CL' => 'Schiile',
 			'CM' => 'Kammeruhn',
 			'CN' => 'Schiina',
 			'CO' => 'Kolumbije',
 			'CP' => 'de Klipperton-Ensel',
 			'CR' => 'Kostarika',
 			'CU' => 'Kuhba',
 			'CV' => 'de kapvärdesche Enselle',
 			'CW' => 'Curaçao',
 			'CX' => 'de Weihnaachs-Ensel',
 			'CY' => 'Züppere',
 			'CZ' => 'de Tschäschei',
 			'DE' => 'Doütschland',
 			'DG' => 'de Diego-Garcia-Ensel',
 			'DJ' => 'Dschibutti',
 			'DK' => 'Dänemark',
 			'DM' => 'Dominnika',
 			'DO' => 'de Dommenekaanesche Reppublik',
 			'DZ' => 'Alljeerije',
 			'EA' => 'Ze’uta un Meliija',
 			'EC' => 'Äkwador',
 			'EE' => 'Äßland',
 			'EG' => 'Äjüpte',
 			'EH' => 'Wäß-Sahara',
 			'ER' => 'Äritreja',
 			'ES' => 'Schpaanije',
 			'ET' => 'Ättijoopije',
 			'EU' => 'de Europähjesche Unijon',
 			'FI' => 'Finnland',
 			'FJ' => 'de Fidschi-Endelle',
 			'FK' => 'de Falkland-Enselle',
 			'FK@alt=variant' => 'de malleviinesche Enselle',
 			'FM' => 'Mikroneesije',
 			'FO' => 'de Färrör-Enselle',
 			'FR' => 'Frankrisch',
 			'GA' => 'Jabuhn',
 			'GB' => 'Jruußbrettannije',
 			'GD' => 'Jrenahda',
 			'GE' => 'Jeorrjije',
 			'GF' => 'Franzüüsesch Jujaana',
 			'GG' => 'Jöönsei',
 			'GH' => 'Jaana',
 			'GI' => 'Jibralltaa',
 			'GL' => 'Jröhnland',
 			'GM' => 'Jambija',
 			'GN' => 'Jinneha',
 			'GP' => 'Juadelupp',
 			'GQ' => 'Äquatorial Jineeja',
 			'GR' => 'Jriescheland',
 			'GS' => 'Söd-Jeorjie un de södlijje Botteramms-Enselle',
 			'GT' => 'Juwatemahla',
 			'GU' => 'Juham',
 			'GW' => 'Jinneha_Bißau',
 			'GY' => 'Jujaana',
 			'HK' => 'Hongkong',
 			'HM' => 'de Heart Ensel un de McDonald-Enselle',
 			'HN' => 'Honduras',
 			'HR' => 'Krowazije',
 			'HT' => 'Ha’itti',
 			'HU' => 'Unjann',
 			'IC' => 'de Kannaresche Enselle',
 			'ID' => 'Indoneesije',
 			'IE' => 'Irrland',
 			'IL' => 'Ißraäl',
 			'IM' => 'de Ensel Män',
 			'IN' => 'Indije',
 			'IO' => 'Brettesche Besezunge em indesche Oozejahn',
 			'IQ' => 'Irak',
 			'IR' => 'Persije',
 			'IS' => 'Ißland',
 			'IT' => 'Itaalije',
 			'JE' => 'Jööseh',
 			'JM' => 'Jammaika',
 			'JO' => 'Jordaanije',
 			'JP' => 'Japan',
 			'KE' => 'Keenija',
 			'KG' => 'Kirrjiisije',
 			'KH' => 'Kambodscha',
 			'KI' => 'Kiribati',
 			'KM' => 'de Kommoore',
 			'KN' => 'Zint Kitts un Nevis',
 			'KP' => 'Nood-Koreja',
 			'KR' => 'Söd-Koreja',
 			'KW' => 'Kuweit',
 			'KY' => 'de Kaiman-Enselle',
 			'KZ' => 'Kassakstahn',
 			'LA' => 'La’os',
 			'LB' => 'Lebbannon',
 			'LC' => 'de Ensel Zint-Lutscha',
 			'LI' => 'Lischteschtein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Libeerija',
 			'LS' => 'Lesooto',
 			'LT' => 'Littaue',
 			'LU' => 'Luxembursch',
 			'LV' => 'Lätland',
 			'LY' => 'Libbije',
 			'MA' => 'Marokko',
 			'MC' => 'Monakko',
 			'MD' => 'Moldaavije',
 			'ME' => 'et Monteneejro',
 			'MF' => 'de Zint-Määtes-Ensel',
 			'MG' => 'Maddajaska',
 			'MH' => 'de Machschall-Enselle',
 			'ML' => 'Maali',
 			'MM' => 'Birma',
 			'MN' => 'Mongjolei',
 			'MO' => 'Makau',
 			'MP' => 'de nöödlijje Marijanne-Enselle',
 			'MQ' => 'Machtinik',
 			'MR' => 'Mautitaanije',
 			'MS' => 'Mongßerrat',
 			'MT' => 'Malta',
 			'MU' => 'Maurizijus',
 			'MV' => 'Mallediive',
 			'MW' => 'Malawi',
 			'MX' => 'Mäxiko',
 			'MY' => 'Malaisije',
 			'MZ' => 'Mosambik',
 			'NA' => 'Namiibije',
 			'NC' => 'Neuschottland',
 			'NE' => 'Nijer',
 			'NF' => 'de Noofok-Ensel',
 			'NG' => 'Nikaraagua',
 			'NI' => 'Nikarahguwa',
 			'NL' => 'de Nederläng',
 			'NO' => 'Norrweeje',
 			'NP' => 'Nepall',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Neuseeland',
 			'OM' => 'Oman',
 			'PA' => 'Pannama',
 			'PE' => 'Perruh',
 			'PF' => 'Franzüüsesch Pollineesije',
 			'PG' => 'Papuwa Neujineeja',
 			'PH' => 'Fillipiine',
 			'PK' => 'Pakistahn',
 			'PL' => 'Pole',
 			'PM' => 'Zint Pjäär un Mikelong',
 			'PN' => 'de Pitkärn-Ensel',
 			'PR' => 'Pochtoriko',
 			'PS' => 'Palästina',
 			'PT' => 'Pochtojall',
 			'PW' => 'Pallau',
 			'PY' => 'Parraguwai',
 			'QA' => 'Kataa',
 			'QO' => 'Ozejahnije ußerhallef',
 			'RE' => 'Rehunjohn',
 			'RO' => 'Romäänije',
 			'RS' => 'Särbije',
 			'RU' => 'Rußland',
 			'RW' => 'Ruanda',
 			'SA' => 'Saudi Arraabije',
 			'SB' => 'de Solomone-Enselle',
 			'SC' => 'de Seischälle',
 			'SD' => 'Noodsudahn',
 			'SE' => 'Schweede',
 			'SG' => 'Singjapuur',
 			'SH' => 'de Ensel Zint Hellena',
 			'SI' => 'ẞloveenije',
 			'SJ' => 'de Enselle Svalbard un Jan Mayen',
 			'SK' => 'ẞlovakei',
 			'SL' => 'Sjärra Lejone',
 			'SM' => 'San-Marino',
 			'SN' => 'der Sennejall',
 			'SO' => 'Somaalije',
 			'SR' => 'Sürinamm',
 			'SS' => 'Södsudahn',
 			'ST' => 'Zint Tommeh un Printschipe',
 			'SV' => 'Äl Slavadohr',
 			'SX' => 'Zint Maarten',
 			'SY' => 'Sürije',
 			'SZ' => 'ẞwaasiland',
 			'TA' => 'Tristan da Cunja',
 			'TC' => 'de Enselle Turks un Kaikos',
 			'TD' => 'der Tschadd',
 			'TF' => 'Franzüüsesche Södsee-Enselle',
 			'TG' => 'Toojo',
 			'TH' => 'Tailand',
 			'TJ' => 'Tadschikistahn',
 			'TK' => 'Tokelau',
 			'TL' => 'Oß-Timor',
 			'TM' => 'Turkmenistahn',
 			'TN' => 'Tuneesije',
 			'TO' => 'Tongga',
 			'TR' => 'de Törkei',
 			'TT' => 'Trinidad un Tobähjo',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tansanija',
 			'UA' => 'de Ukra’iine',
 			'UG' => 'Ujanda',
 			'UM' => 'de Vereineschte Schtaate vun Amärrika ier ußerhallef jelääje Enselsche',
 			'US' => 'de vereineschte Schtaate vun Ammärrika',
 			'US@alt=short' => 'USA',
 			'UY' => 'Urrujwai',
 			'UZ' => 'Ußbeekistahn',
 			'VA' => 'der Vattikahn',
 			'VC' => 'Zint Vinzänz un de Jrenadines-Enselle',
 			'VE' => 'Venezuela',
 			'VG' => 'de brettesche Juffer-Enselle',
 			'VI' => 'de ammärrikahnesche Juffer-Enselle',
 			'VN' => 'Vijätnamm',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis un Futuna',
 			'WS' => 'Sammoha',
 			'XK' => 'Kosovo',
 			'YE' => 'Jämme',
 			'YT' => 'Majott',
 			'ZA' => 'de Republik Södaffrika',
 			'ZM' => 'Sambija',
 			'ZW' => 'Simbabwe',
 			'ZZ' => '- Jähjend onbikannt -',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'1901' => 'Schriefwiiß vun 1901 aff',
 			'1994' => 'resijanesch schtandatt Schriefwiiß vun 1994',
 			'1996' => 'Schriefwiiß vun 1996 aff',
 			'1606NICT' => 'späätmeddelfranzüüsesch vör 1606',
 			'1694ACAD' => 'fröhneufranzüüsesch aff 1694',
 			'1959ACAD' => 'akademesche Schriefwiiß vun 1959',
 			'ALALC97' => 'de lateinesche Ömschreff ALA-LC vun 1997',
 			'AREVELA' => 'oß-armeensch',
 			'AREVMDA' => 'wäß-armeenesch',
 			'BAKU1926' => 'eijheijtlesch törkesch lateijnesch Allfabeet',
 			'BISKE' => 'zint jorjo’sche uder bila’sche reijanesche Dijaläk',
 			'BOONT' => 'boontlingsche Dijaläk',
 			'FONIPA' => 'IPA-Loutschreff',
 			'FONUPA' => 'UPA-Loutschreff',
 			'HEPBURN' => 'De Lateinesche Ömschreff noh Hepburn',
 			'HOGNORSK' => 'Huhnorrweejesch',
 			'KKCOR' => 'jemeinsam widderbeläf kornesche Schriefwiiß',
 			'LIPAW' => 'lipovazesch resijanesche Dijaläk',
 			'MONOTON' => 'monnotoonesch',
 			'NDYUKA' => 'ndyukanesche Dijaläk',
 			'NEDIS' => 'natisonesche Dijaläk',
 			'NJIVA' => 'gniva’sche uder njiva’sche reijanesche Dijaläk',
 			'OSOJS' => 'oseacco’sche uder osojanesche reijanesche Dijaläk',
 			'PAMAKA' => 'pamakanesche Dijaläk',
 			'PINYIN' => 'Pinjin-Ömschreff',
 			'POLYTON' => 'pollütoonesch',
 			'REVISED' => 'neu opjelate Schriefwiiß',
 			'ROZAJ' => 'resijanesche Dijaläk',
 			'SCOTLAND' => 'schottesche Dijaläk',
 			'SCOUSE' => 'scouse Dijaläk',
 			'SOLBA' => 'stolvizanesche uder solbizanesch reijanesche Dijaläk',
 			'TARASK' => 'Taraskijeviza-Schriefwiiß',
 			'UCCOR' => 'eijheijtlesch Schriefwiiß',
 			'UCRCOR' => 'eijheijtlesch, neu opjelate Schriefwiiß',
 			'VALENCIA' => 'valenzijaanesche Dijaläk',
 			'WADEGILE' => 'lateijnesche Ömschreff noh Wade-Giles',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'dä Kalländer',
 			'collation' => 'de Reijefollsch zom Zotiere',
 			'currency' => 'de Zoot Jeld',
 			'numbers' => 'de Nummere',

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
 				'buddhist' => q{buddistesche Kaländer},
 				'chinese' => q{schinehsesche Kalännder},
 				'coptic' => q{kopttesche Kaländer},
 				'dangi' => q{Dangikalännder},
 				'ethiopic' => q{ätejohpesche Kalännder},
 				'ethiopic-amete-alem' => q{ätejoopesche Amete Alem Kaländer},
 				'gregorian' => q{jrejorejahnesche Kalännder},
 				'hebrew' => q{jühdesche Kalännder},
 				'indian' => q{indesche Nazjonahl-Kaländer},
 				'islamic' => q{ißlaamesche Kaländer},
 				'islamic-civil' => q{wältlesche islaamesche Kaländer},
 				'japanese' => q{japaanesche Kaländer},
 				'persian' => q{pärsesche Kaländer},
 				'roc' => q{rotschineesesche Kaländer},
 			},
 			'collation' => {
 				'big5han' => q{zoteert nohm tradizjonäll schineesesch Big5},
 				'dictionary' => q{zotehrt wi em Wööterbohch},
 				'ducet' => q{standattmähßesch zotehrt nohm Unicode},
 				'gb2312han' => q{zoteert nohm eijfacher schineesesch GB2312},
 				'phonebook' => q{zoteert wi em Tollefoonbooch},
 				'pinyin' => q{zoteert noh de Pinjin Ömschreff vum Schineesesch},
 				'search' => q{Söhke},
 				'standard' => q{Schtandatt},
 				'stroke' => q{zoteert noh de Stresche vum tradizjonäll schineesesch},
 				'traditional' => q{tradizjonäll zoteert},
 				'unihan' => q{zoteert noh de Radikaale un Stresche vum Schineesesch},
 			},
 			'numbers' => {
 				'arab' => q{araabesche un indesche Zeffere},
 				'arabext' => q{ußjedehnt araabesche un indesche Zeffere},
 				'armn' => q{armeenesche Zahle},
 				'armnlow' => q{klein jeschrevve armeenesche Zahle},
 				'beng' => q{bängjaalesche Zeffere},
 				'deva' => q{Devanagari-Zeffere},
 				'ethi' => q{ätejoopesche Zahle},
 				'fullwide' => q{janz breede Zeffere},
 				'geor' => q{jeorjeesche Zahle},
 				'grek' => q{jriischesche Zahle},
 				'greklow' => q{klein jeschrevve jriischesche Zahle},
 				'gujr' => q{Jujarati-Zeffere},
 				'guru' => q{Jurmukhi-Zeffere},
 				'hanidec' => q{schineesesche Zehnerzahle},
 				'hans' => q{eijfache schineesesche Zahle},
 				'hansfin' => q{eijfache schineesesche Finanzzahle},
 				'hant' => q{tradizjonälle schineesesche Zahle},
 				'hantfin' => q{tradizjonälle schineesesche Finanzzahle},
 				'hebr' => q{hebräjesche Zahle},
 				'jpan' => q{japanesche Zahle},
 				'jpanfin' => q{japaanesche Finazzahle},
 				'khmr' => q{Khmer-Zeffere},
 				'knda' => q{Kannada-Zeffere},
 				'laoo' => q{laootesche Zeffere},
 				'latn' => q{wäßlejje Zeffere},
 				'mlym' => q{Malayalam-Zeffere},
 				'mong' => q{mongjoolesche Zeffere},
 				'mymr' => q{Myanmar-Zeffere},
 				'orya' => q{Oriya-Zeffere},
 				'roman' => q{römesche Zahle},
 				'romanlow' => q{klein jeschrevve römesche Zahle},
 				'taml' => q{tradizjonälle tamilesche Zahle},
 				'tamldec' => q{tamiilesche Zeffere},
 				'telu' => q{Teluju-Zeffere},
 				'thai' => q{thailändesche Zeffere},
 				'tibt' => q{tibetaanesche Zeffere},
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
			'metric' => q{SI},
 			'UK' => q{änglesch},
 			'US' => q{ammärekaanesch},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'de Schprohch afjekööz met „{0}“',
 			'script' => 'de Schreff afjekööz met „{0}“',
 			'region' => 'de Jähjend afjekööz met „{0}“',

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
			auxiliary => qr{[á à ă â ã ā ç é è ĕ ê ē ğ í ì ĭ î ï ī ĳ ı ł ñ ó ò ŏ ô ø ō ú ù ŭ û ū ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a å ä æ b c d e ë ė f g h i j k l m n o ö œ p q r s ß t u ů ü v w x y z]},
			numbers => qr{[  , % ‰ + − 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[_ ‐ – — ⸗ , ; \: ! ? . … ' ‘ ‚ " “ „ ( ) \[ \] \{ \} § @ * / \& # % † ‡ ° < = > ~]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{„},
);

has 'quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{“},
);

has 'alternate_quote_start' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‚},
);

has 'alternate_quote_end' => (
	is			=> 'ro',
	isa			=> Str,
	init_arg	=> undef,
	default		=> qq{‘},
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
					'acceleration-g-force' => {
						'name' => q(-fache Erdbeschleunigung),
						'one' => q({0}-fache Erdbeschleunigung),
						'other' => q({0}-fache Erdbeschleunigung),
						'zero' => q({0}-fache Erdbeschleunigung),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(-fache Erdbeschleunigung),
						'one' => q({0}-fache Erdbeschleunigung),
						'other' => q({0}-fache Erdbeschleunigung),
						'zero' => q({0}-fache Erdbeschleunigung),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(Winkelmenutte),
						'one' => q({0} Winkelmenutte),
						'other' => q({0} Winkelmenutte),
						'zero' => q({0} Winkelmenutte),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(Winkelmenutte),
						'one' => q({0} Winkelmenutte),
						'other' => q({0} Winkelmenutte),
						'zero' => q({0} Winkelmenutte),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(Winkelsekunde),
						'one' => q({0} Winkelsekunde),
						'other' => q({0} Winkelsekunde),
						'zero' => q({0} Winkelsekunde),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(Winkelsekunde),
						'one' => q({0} Winkelsekunde),
						'other' => q({0} Winkelsekunde),
						'zero' => q({0} Winkelsekunde),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(Graad),
						'one' => q({0} Graad),
						'other' => q({0} Graad),
						'zero' => q({0} Graad),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(Graad),
						'one' => q({0} Graad),
						'other' => q({0} Graad),
						'zero' => q({0} Graad),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(angloamerikanischen Acre),
						'one' => q({0} angloamerikanische Acre),
						'other' => q({0} angloamerikanischen Acre),
						'zero' => q({0} angloamerikanischen Acre),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(angloamerikanischen Acre),
						'one' => q({0} angloamerikanische Acre),
						'other' => q({0} angloamerikanischen Acre),
						'zero' => q({0} angloamerikanischen Acre),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektar),
						'one' => q({0} hektar),
						'other' => q({0} hektar),
						'zero' => q({0} hektar),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektar),
						'one' => q({0} hektar),
						'other' => q({0} hektar),
						'zero' => q({0} hektar),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(Quadratvoss),
						'one' => q({0} Quadratvoss),
						'other' => q({0} Quadratvoss),
						'zero' => q({0} Quadratvoss),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(Quadratvoss),
						'one' => q({0} Quadratvoss),
						'other' => q({0} Quadratvoss),
						'zero' => q({0} Quadratvoss),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(Quadratkilometer),
						'one' => q({0} Quadratkilometer),
						'other' => q({0} Quadratkilometer),
						'zero' => q({0} Quadratkilometer),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(Quadratkilometer),
						'one' => q({0} Quadratkilometer),
						'other' => q({0} Quadratkilometer),
						'zero' => q({0} Quadratkilometer),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(Quadratmeter),
						'one' => q({0} Quadratmeter),
						'other' => q({0} Quadratmeter),
						'zero' => q({0} Quadratmeter),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(Quadratmeter),
						'one' => q({0} Quadratmeter),
						'other' => q({0} Quadratmeter),
						'zero' => q({0} Quadratmeter),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(englischen Quadratmeilen),
						'one' => q({0} englische Quadratmeile),
						'other' => q({0} englischen Quadratmeilen),
						'zero' => q({0} englischen Quadratmeilen),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(englischen Quadratmeilen),
						'one' => q({0} englische Quadratmeile),
						'other' => q({0} englischen Quadratmeilen),
						'zero' => q({0} englischen Quadratmeilen),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(Dääsch),
						'one' => q({0} Dääsch),
						'other' => q({0} Dääsch),
						'per' => q({0} pro Dääsch),
						'zero' => q({0} Dääsch),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(Dääsch),
						'one' => q({0} Dääsch),
						'other' => q({0} Dääsch),
						'per' => q({0} pro Dääsch),
						'zero' => q({0} Dääsch),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(Schtunde),
						'one' => q({0} Schtunde),
						'other' => q({0} Schtunde),
						'per' => q({0} pro Schtunde),
						'zero' => q({0} Schtunde),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(Schtunde),
						'one' => q({0} Schtunde),
						'other' => q({0} Schtunde),
						'per' => q({0} pro Schtunde),
						'zero' => q({0} Schtunde),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(Millisekunde),
						'one' => q({0} Millisekunde),
						'other' => q({0} Millisekunde),
						'zero' => q({0} Millisekunde),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(Millisekunde),
						'one' => q({0} Millisekunde),
						'other' => q({0} Millisekunde),
						'zero' => q({0} Millisekunde),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(Menutte),
						'one' => q({0} Menutte),
						'other' => q({0} Menutte),
						'per' => q({0} pro Menutte),
						'zero' => q({0} Menutte),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(Menutte),
						'one' => q({0} Menutte),
						'other' => q({0} Menutte),
						'per' => q({0} pro Menutte),
						'zero' => q({0} Menutte),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(Mohnde),
						'one' => q({0} Mohnde),
						'other' => q({0} Mohnde),
						'per' => q({0} pro Mohnde),
						'zero' => q({0} Mohnde),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(Mohnde),
						'one' => q({0} Mohnde),
						'other' => q({0} Mohnde),
						'per' => q({0} pro Mohnde),
						'zero' => q({0} Mohnde),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(Sekunde),
						'one' => q({0} Sekunde),
						'other' => q({0} Sekunde),
						'per' => q({0} pro Sekunde),
						'zero' => q({0} Sekunde),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(Sekunde),
						'one' => q({0} Sekunde),
						'other' => q({0} Sekunde),
						'per' => q({0} pro Sekunde),
						'zero' => q({0} Sekunde),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(Woche),
						'one' => q({0} Woche),
						'other' => q({0} Woche),
						'per' => q({0} pro Woche),
						'zero' => q({0} Woche),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(Woche),
						'one' => q({0} Woche),
						'other' => q({0} Woche),
						'per' => q({0} pro Woche),
						'zero' => q({0} Woche),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(Johre),
						'one' => q({0} Johre),
						'other' => q({0} Johre),
						'per' => q({0} pro Johre),
						'zero' => q({0} Johre),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(Johre),
						'one' => q({0} Johre),
						'other' => q({0} Johre),
						'per' => q({0} pro Johre),
						'zero' => q({0} Johre),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(Zentimeter),
						'one' => q({0} Zentimeter),
						'other' => q({0} Zentimeter),
						'zero' => q({0} Zentimeter),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(Zentimeter),
						'one' => q({0} Zentimeter),
						'other' => q({0} Zentimeter),
						'zero' => q({0} Zentimeter),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(Voss),
						'one' => q({0} Voss),
						'other' => q({0} Voss),
						'zero' => q({0} Voss),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(Voss),
						'one' => q({0} Voss),
						'other' => q({0} Voss),
						'zero' => q({0} Voss),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(Dumm),
						'one' => q({0} Dumm),
						'other' => q({0} Dumm),
						'zero' => q({0} Dumm),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(Dumm),
						'one' => q({0} Dumm),
						'other' => q({0} Dumm),
						'zero' => q({0} Dumm),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(Kilometer),
						'one' => q({0} Kilometer),
						'other' => q({0} Kilometer),
						'per' => q({0} pro Kilometer),
						'zero' => q({0} Kilometer),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(Kilometer),
						'one' => q({0} Kilometer),
						'other' => q({0} Kilometer),
						'per' => q({0} pro Kilometer),
						'zero' => q({0} Kilometer),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(Meter),
						'one' => q({0} Meter),
						'other' => q({0} Meter),
						'zero' => q({0} Meter),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(Meter),
						'one' => q({0} Meter),
						'other' => q({0} Meter),
						'zero' => q({0} Meter),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(englischen Meilen),
						'one' => q({0} englische Meile),
						'other' => q({0} englischen Meilen),
						'zero' => q({0} englischen Meilen),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(englischen Meilen),
						'one' => q({0} englische Meile),
						'other' => q({0} englischen Meilen),
						'zero' => q({0} englischen Meilen),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(Millimeter),
						'one' => q({0} Millimeter),
						'other' => q({0} Millimeter),
						'zero' => q({0} Millimeter),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(Millimeter),
						'one' => q({0} Millimeter),
						'other' => q({0} Millimeter),
						'zero' => q({0} Millimeter),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(Pikometer),
						'one' => q({0} Pikometer),
						'other' => q({0} Pikometer),
						'zero' => q({0} Pikometer),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(Pikometer),
						'one' => q({0} Pikometer),
						'other' => q({0} Pikometer),
						'zero' => q({0} Pikometer),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(Gramm),
						'one' => q({0} Gramm),
						'other' => q({0} Gramm),
						'zero' => q({0} Gramm),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(Gramm),
						'one' => q({0} Gramm),
						'other' => q({0} Gramm),
						'zero' => q({0} Gramm),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(Kilogramm),
						'one' => q({0} Kilogramm),
						'other' => q({0} Kilogramm),
						'zero' => q({0} Kilogramm),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(Kilogramm),
						'one' => q({0} Kilogramm),
						'other' => q({0} Kilogramm),
						'zero' => q({0} Kilogramm),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(Unzen),
						'one' => q({0} Unze),
						'other' => q({0} Unzen),
						'zero' => q({0} Unzen),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(Unzen),
						'one' => q({0} Unze),
						'other' => q({0} Unzen),
						'zero' => q({0} Unzen),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(Pfund),
						'one' => q({0} Pfund),
						'other' => q({0} Pfund),
						'zero' => q({0} Pfund),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(Pfund),
						'one' => q({0} Pfund),
						'other' => q({0} Pfund),
						'zero' => q({0} Pfund),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} pro {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} pro {1}),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(Pferdestärken),
						'one' => q({0} Pferdestärke),
						'other' => q({0} Pferdestärken),
						'zero' => q({0} Pferdestärken),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(Pferdestärken),
						'one' => q({0} Pferdestärke),
						'other' => q({0} Pferdestärken),
						'zero' => q({0} Pferdestärken),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(Kilowatt),
						'one' => q({0} Kilowatt),
						'other' => q({0} Kilowatt),
						'zero' => q({0} Kilowatt),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(Kilowatt),
						'one' => q({0} Kilowatt),
						'other' => q({0} Kilowatt),
						'zero' => q({0} Kilowatt),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(Watt),
						'one' => q({0} Watt),
						'other' => q({0} Watt),
						'zero' => q({0} Watt),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(Watt),
						'one' => q({0} Watt),
						'other' => q({0} Watt),
						'zero' => q({0} Watt),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(Hektopascal),
						'one' => q({0} Hektopascal),
						'other' => q({0} Hektopascal),
						'zero' => q({0} Hektopascal),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(Hektopascal),
						'one' => q({0} Hektopascal),
						'other' => q({0} Hektopascal),
						'zero' => q({0} Hektopascal),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(Dumm Quecksilbersäule),
						'one' => q({0} Dumm Quecksilbersäule),
						'other' => q({0} Dumm Quecksilbersäule),
						'zero' => q({0} Dumm Quecksilbersäule),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(Dumm Quecksilbersäule),
						'one' => q({0} Dumm Quecksilbersäule),
						'other' => q({0} Dumm Quecksilbersäule),
						'zero' => q({0} Dumm Quecksilbersäule),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(Millibar),
						'one' => q({0} Millibar),
						'other' => q({0} Millibar),
						'zero' => q({0} Millibar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(Millibar),
						'one' => q({0} Millibar),
						'other' => q({0} Millibar),
						'zero' => q({0} Millibar),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(Kilometer pro Schtunde),
						'one' => q({0} Kilometer pro Schtunde),
						'other' => q({0} Kilometer pro Schtunde),
						'zero' => q({0} Kilometer pro Schtunde),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(Kilometer pro Schtunde),
						'one' => q({0} Kilometer pro Schtunde),
						'other' => q({0} Kilometer pro Schtunde),
						'zero' => q({0} Kilometer pro Schtunde),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(Meter pro Sekunde),
						'one' => q({0} Meter pro Sekunde),
						'other' => q({0} Meter pro Sekunde),
						'zero' => q({0} Meter pro Sekunde),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(Meter pro Sekunde),
						'one' => q({0} Meter pro Sekunde),
						'other' => q({0} Meter pro Sekunde),
						'zero' => q({0} Meter pro Sekunde),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(englischen Meilen pro Schtunde),
						'one' => q({0} englische Meile pro Schtunde),
						'other' => q({0} englischen Meilen pro Schtunde),
						'zero' => q({0} englischen Meilen pro Schtunde),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(englischen Meilen pro Schtunde),
						'one' => q({0} englische Meile pro Schtunde),
						'other' => q({0} englischen Meilen pro Schtunde),
						'zero' => q({0} englischen Meilen pro Schtunde),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(Graad Celsius),
						'one' => q({0} Graad Celsius),
						'other' => q({0} Graad Celsius),
						'zero' => q({0} Graad Celsius),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(Graad Celsius),
						'one' => q({0} Graad Celsius),
						'other' => q({0} Graad Celsius),
						'zero' => q({0} Graad Celsius),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(Graad Fahrenheit),
						'one' => q({0} Graad Fahrenheit),
						'other' => q({0} Graad Fahrenheit),
						'zero' => q({0} Graad Fahrenheit),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(Graad Fahrenheit),
						'one' => q({0} Graad Fahrenheit),
						'other' => q({0} Graad Fahrenheit),
						'zero' => q({0} Graad Fahrenheit),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(Kubikkilometer),
						'one' => q({0} Kubikkilometer),
						'other' => q({0} Kubikkilometer),
						'zero' => q({0} Kubikkilometer),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(Kubikkilometer),
						'one' => q({0} Kubikkilometer),
						'other' => q({0} Kubikkilometer),
						'zero' => q({0} Kubikkilometer),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(englischen Kubikmeilen),
						'one' => q({0} englische Kubikmeile),
						'other' => q({0} englischen Kubikmeilen),
						'zero' => q({0} englischen Kubikmeilen),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(englischen Kubikmeilen),
						'one' => q({0} englische Kubikmeile),
						'other' => q({0} englischen Kubikmeilen),
						'zero' => q({0} englischen Kubikmeilen),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(Liter),
						'one' => q({0} Liter),
						'other' => q({0} Liter),
						'zero' => q({0} Liter),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(Liter),
						'one' => q({0} Liter),
						'other' => q({0} Liter),
						'zero' => q({0} Liter),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0}G),
						'other' => q({0}G),
						'zero' => q({0}G),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0}G),
						'other' => q({0}G),
						'zero' => q({0}G),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
						'zero' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
						'zero' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
						'zero' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
						'zero' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
						'zero' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
						'zero' => q({0}°),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
						'zero' => q({0} ac),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
						'zero' => q({0} ac),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
						'zero' => q({0}ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
						'zero' => q({0}ha),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
						'zero' => q({0} ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
						'zero' => q({0} ft²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
						'zero' => q({0}km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
						'zero' => q({0}km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
						'zero' => q({0}m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
						'zero' => q({0}m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'zero' => q({0} mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'zero' => q({0} mi²),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0}d),
						'other' => q({0}d),
						'zero' => q({0}d),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0}d),
						'other' => q({0}d),
						'zero' => q({0}d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0}h),
						'other' => q({0}h),
						'zero' => q({0}h),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0}h),
						'other' => q({0}h),
						'zero' => q({0}h),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
						'zero' => q({0}ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0}ms),
						'other' => q({0}ms),
						'zero' => q({0}ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'zero' => q({0}m),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'zero' => q({0}m),
					},
					# Long Unit Identifier
					'duration-month' => {
						'one' => q({0} Mohn),
						'other' => q({0} Mohn),
						'zero' => q({0} Mohn),
					},
					# Core Unit Identifier
					'month' => {
						'one' => q({0} Mohn),
						'other' => q({0} Mohn),
						'zero' => q({0} Mohn),
					},
					# Long Unit Identifier
					'duration-second' => {
						'one' => q({0}s),
						'other' => q({0}s),
						'zero' => q({0}s),
					},
					# Core Unit Identifier
					'second' => {
						'one' => q({0}s),
						'other' => q({0}s),
						'zero' => q({0}s),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0} Jr),
						'other' => q({0} Jr),
						'zero' => q({0} Jr),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0} Jr),
						'other' => q({0} Jr),
						'zero' => q({0} Jr),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
						'zero' => q({0}cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
						'zero' => q({0}cm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0} Voss),
						'other' => q({0} Voss),
						'zero' => q({0} Voss),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0} Voss),
						'other' => q({0} Voss),
						'zero' => q({0} Voss),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0} Dumm),
						'other' => q({0} Dumm),
						'zero' => q({0} Dumm),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0} Dumm),
						'other' => q({0} Dumm),
						'zero' => q({0} Dumm),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
						'zero' => q({0}km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q({0}km),
						'other' => q({0}km),
						'zero' => q({0}km),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'zero' => q({0}m),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0}m),
						'other' => q({0}m),
						'zero' => q({0}m),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} mi),
						'other' => q({0} mi),
						'zero' => q({0} mi),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} mi),
						'other' => q({0} mi),
						'zero' => q({0} mi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
						'zero' => q({0}mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0}mm),
						'other' => q({0}mm),
						'zero' => q({0}mm),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
						'zero' => q({0}pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
						'zero' => q({0}pm),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0}g),
						'other' => q({0}g),
						'zero' => q({0}g),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0}g),
						'other' => q({0}g),
						'zero' => q({0}g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
						'zero' => q({0}kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
						'zero' => q({0}kg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q({0} Unze),
						'other' => q({0} Unzen),
						'zero' => q({0} Unzen),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0} Unze),
						'other' => q({0} Unzen),
						'zero' => q({0} Unzen),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} Pfund),
						'other' => q({0} Pfund),
						'zero' => q({0} Pfund),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} Pfund),
						'other' => q({0} Pfund),
						'zero' => q({0} Pfund),
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
						'one' => q({0}PS),
						'other' => q({0}PS),
						'zero' => q({0}PS),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0}PS),
						'other' => q({0}PS),
						'zero' => q({0}PS),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
						'zero' => q({0}kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
						'zero' => q({0}kW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
						'zero' => q({0}W),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0}W),
						'other' => q({0}W),
						'zero' => q({0}W),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
						'zero' => q({0}hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
						'zero' => q({0}hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
						'zero' => q({0} inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
						'zero' => q({0} inHg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
						'zero' => q({0}mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0}mbar),
						'other' => q({0}mbar),
						'zero' => q({0}mbar),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'one' => q({0}km/h),
						'other' => q({0}km/h),
						'zero' => q({0}km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'one' => q({0}km/h),
						'other' => q({0}km/h),
						'zero' => q({0}km/h),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
						'zero' => q({0}m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'one' => q({0}m/s),
						'other' => q({0}m/s),
						'zero' => q({0}m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
						'zero' => q({0} mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
						'zero' => q({0} mi/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'one' => q({0}°),
						'other' => q({0}°),
						'zero' => q({0}°),
					},
					# Core Unit Identifier
					'celsius' => {
						'one' => q({0}°),
						'other' => q({0}°),
						'zero' => q({0}°),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
						'zero' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
						'zero' => q({0}°F),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
						'zero' => q({0}km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
						'zero' => q({0}km³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
						'zero' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
						'zero' => q({0} mi³),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0}L),
						'other' => q({0}L),
						'zero' => q({0}L),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0}L),
						'other' => q({0}L),
						'zero' => q({0}L),
					},
				},
				'short' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(-fache Erdbeschleunigung),
						'one' => q({0} G),
						'other' => q({0} G),
						'zero' => q({0} G),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(-fache Erdbeschleunigung),
						'one' => q({0} G),
						'other' => q({0} G),
						'zero' => q({0} G),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(Winkelmenutte),
						'one' => q({0}′),
						'other' => q({0}′),
						'zero' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(Winkelmenutte),
						'one' => q({0}′),
						'other' => q({0}′),
						'zero' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(Winkelsekunde),
						'one' => q({0}″),
						'other' => q({0}″),
						'zero' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(Winkelsekunde),
						'one' => q({0}″),
						'other' => q({0}″),
						'zero' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(Graad),
						'one' => q({0}°),
						'other' => q({0}°),
						'zero' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(Graad),
						'one' => q({0}°),
						'other' => q({0}°),
						'zero' => q({0}°),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(angloamerikanischen Acre),
						'one' => q({0} ac),
						'other' => q({0} ac),
						'zero' => q({0} ac),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(angloamerikanischen Acre),
						'one' => q({0} ac),
						'other' => q({0} ac),
						'zero' => q({0} ac),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektar),
						'one' => q({0} ha),
						'other' => q({0} ha),
						'zero' => q({0} ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektar),
						'one' => q({0} ha),
						'other' => q({0} ha),
						'zero' => q({0} ha),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(Quadratvoss),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
						'zero' => q({0} ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(Quadratvoss),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
						'zero' => q({0} ft²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(Quadratkilometer),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'zero' => q({0} km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(Quadratkilometer),
						'one' => q({0} km²),
						'other' => q({0} km²),
						'zero' => q({0} km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(Quadratmeter),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'zero' => q({0} m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(Quadratmeter),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'zero' => q({0} m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(englischen Quadratmeilen),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'zero' => q({0} mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(englischen Quadratmeilen),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
						'zero' => q({0} mi²),
					},
					# Long Unit Identifier
					'duration-century' => {
						'one' => q({0} Jrh),
						'other' => q({0} Jrh),
						'zero' => q({0} Jrh),
					},
					# Core Unit Identifier
					'century' => {
						'one' => q({0} Jrh),
						'other' => q({0} Jrh),
						'zero' => q({0} Jrh),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(Dääsch),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
						'zero' => q({0} d),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(Dääsch),
						'one' => q({0} d),
						'other' => q({0} d),
						'per' => q({0}/d),
						'zero' => q({0} d),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(Schtunde),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0} pro Schtunde),
						'zero' => q({0} h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(Schtunde),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0} pro Schtunde),
						'zero' => q({0} h),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(Millisekunde),
						'one' => q({0} ms),
						'other' => q({0} ms),
						'zero' => q({0} ms),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(Millisekunde),
						'one' => q({0} ms),
						'other' => q({0} ms),
						'zero' => q({0} ms),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(Menutte),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
						'zero' => q({0} min),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(Menutte),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
						'zero' => q({0} min),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(Mohnde),
						'one' => q({0} Mohn),
						'other' => q({0} Mohn),
						'per' => q({0}/Mohn),
						'zero' => q({0} Mohn),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(Mohnde),
						'one' => q({0} Mohn),
						'other' => q({0} Mohn),
						'per' => q({0}/Mohn),
						'zero' => q({0} Mohn),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(Sekunde),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
						'zero' => q({0} s),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(Sekunde),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
						'zero' => q({0} s),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(Woche),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(Woche),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(Johre),
						'one' => q({0} Jr),
						'other' => q({0} Jr),
						'per' => q({0}/Jr),
						'zero' => q({0} Jr),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(Johre),
						'one' => q({0} Jr),
						'other' => q({0} Jr),
						'per' => q({0}/Jr),
						'zero' => q({0} Jr),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(Zentimeter),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'zero' => q({0} cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(Zentimeter),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'zero' => q({0} cm),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(Voss),
						'one' => q({0} Voss),
						'other' => q({0} Voss),
						'zero' => q({0} Voss),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(Voss),
						'one' => q({0} Voss),
						'other' => q({0} Voss),
						'zero' => q({0} Voss),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(Dumm),
						'one' => q({0} Dumm),
						'other' => q({0} Dumm),
						'zero' => q({0} Dumm),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(Dumm),
						'one' => q({0} Dumm),
						'other' => q({0} Dumm),
						'zero' => q({0} Dumm),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(Kilometer),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
						'zero' => q({0} km),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(Kilometer),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
						'zero' => q({0} km),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(Meter),
						'one' => q({0} m),
						'other' => q({0} m),
						'zero' => q({0} m),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(Meter),
						'one' => q({0} m),
						'other' => q({0} m),
						'zero' => q({0} m),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(englischen Meilen),
						'one' => q({0} mi),
						'other' => q({0} mi),
						'zero' => q({0} mi),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(englischen Meilen),
						'one' => q({0} mi),
						'other' => q({0} mi),
						'zero' => q({0} mi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(Millimeter),
						'one' => q({0} mm),
						'other' => q({0} mm),
						'zero' => q({0} mm),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(Millimeter),
						'one' => q({0} mm),
						'other' => q({0} mm),
						'zero' => q({0} mm),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(Pikometer),
						'one' => q({0} pm),
						'other' => q({0} pm),
						'zero' => q({0} pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(Pikometer),
						'one' => q({0} pm),
						'other' => q({0} pm),
						'zero' => q({0} pm),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(Gramm),
						'one' => q({0} g),
						'other' => q({0} g),
						'zero' => q({0} g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(Gramm),
						'one' => q({0} g),
						'other' => q({0} g),
						'zero' => q({0} g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(Kilogramm),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'zero' => q({0} kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(Kilogramm),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'zero' => q({0} kg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(Unzen),
						'one' => q({0} Unze),
						'other' => q({0} Unzen),
						'zero' => q({0} Unzen),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(Unzen),
						'one' => q({0} Unze),
						'other' => q({0} Unzen),
						'zero' => q({0} Unzen),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(Pfund),
						'one' => q({0} Pfund),
						'other' => q({0} Pfund),
						'zero' => q({0} Pfund),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(Pfund),
						'one' => q({0} Pfund),
						'other' => q({0} Pfund),
						'zero' => q({0} Pfund),
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
						'name' => q(Pferdestärken),
						'one' => q({0} PS),
						'other' => q({0} PS),
						'zero' => q({0} PS),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(Pferdestärken),
						'one' => q({0} PS),
						'other' => q({0} PS),
						'zero' => q({0} PS),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(Kilowatt),
						'one' => q({0} kW),
						'other' => q({0} kW),
						'zero' => q({0} kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(Kilowatt),
						'one' => q({0} kW),
						'other' => q({0} kW),
						'zero' => q({0} kW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(Watt),
						'one' => q({0} W),
						'other' => q({0} W),
						'zero' => q({0} W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(Watt),
						'one' => q({0} W),
						'other' => q({0} W),
						'zero' => q({0} W),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(Hektopascal),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
						'zero' => q({0} hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(Hektopascal),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
						'zero' => q({0} hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(Dumm Quecksilbersäule),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
						'zero' => q({0} inHg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(Dumm Quecksilbersäule),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
						'zero' => q({0} inHg),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(Millibar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
						'zero' => q({0} mbar),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(Millibar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
						'zero' => q({0} mbar),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(Kilometer pro Schtunde),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
						'zero' => q({0} km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(Kilometer pro Schtunde),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
						'zero' => q({0} km/h),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(Meter pro Sekunde),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
						'zero' => q({0} m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(Meter pro Sekunde),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
						'zero' => q({0} m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(englischen Meilen pro Schtunde),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
						'zero' => q({0} mi/h),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(englischen Meilen pro Schtunde),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
						'zero' => q({0} mi/h),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(Graad Celsius),
						'one' => q({0}°C),
						'other' => q({0}°C),
						'zero' => q({0}°C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(Graad Celsius),
						'one' => q({0}°C),
						'other' => q({0}°C),
						'zero' => q({0}°C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(Graad Fahrenheit),
						'one' => q({0}°F),
						'other' => q({0}°F),
						'zero' => q({0}°F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(Graad Fahrenheit),
						'one' => q({0}°F),
						'other' => q({0}°F),
						'zero' => q({0}°F),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(Kubikkilometer),
						'one' => q({0} km³),
						'other' => q({0} km³),
						'zero' => q({0} km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(Kubikkilometer),
						'one' => q({0} km³),
						'other' => q({0} km³),
						'zero' => q({0} km³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(englischen Kubikmeilen),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
						'zero' => q({0} mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(englischen Kubikmeilen),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
						'zero' => q({0} mi³),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(Liter),
						'one' => q({0} l),
						'other' => q({0} l),
						'zero' => q({0} l),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(Liter),
						'one' => q({0} l),
						'other' => q({0} l),
						'zero' => q({0} l),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:jo|joh|joo|j|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:nä|nää|näh|n)$' }
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
			'decimal' => q(,),
			'exponential' => q(×10^),
			'group' => q( ),
			'infinity' => q(∞),
			'list' => q(;),
			'minusSign' => q(−),
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
					'one' => '0 tsd',
					'other' => '0 tsd',
					'zero' => '0 tsd',
				},
				'10000' => {
					'one' => '00 tsd',
					'other' => '00 tsd',
					'zero' => '00 tsd',
				},
				'100000' => {
					'one' => '000 tsd',
					'other' => '000 tsd',
					'zero' => '000 tsd',
				},
				'1000000' => {
					'one' => '0 Mio',
					'other' => '0 Mio',
					'zero' => '0 Mio',
				},
				'10000000' => {
					'one' => '00 Mio',
					'other' => '00 Mio',
					'zero' => '00 Mio',
				},
				'100000000' => {
					'one' => '000 Mio',
					'other' => '000 Mio',
					'zero' => '000 Mio',
				},
				'1000000000' => {
					'one' => '0 Mrd',
					'other' => '0 Mrd',
					'zero' => '0 Mrd',
				},
				'10000000000' => {
					'one' => '00 Mrd',
					'other' => '00 Mrd',
					'zero' => '00 Mrd',
				},
				'100000000000' => {
					'one' => '000 Mrd',
					'other' => '000 Mrd',
					'zero' => '000 Mrd',
				},
				'1000000000000' => {
					'one' => '0 Bio',
					'other' => '0 Bio',
					'zero' => '0 Bio',
				},
				'10000000000000' => {
					'one' => '00 Bio',
					'other' => '00 Bio',
					'zero' => '00 Bio',
				},
				'100000000000000' => {
					'one' => '000 Bio',
					'other' => '000 Bio',
					'zero' => '000 Bio',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 Dousend',
					'other' => '0 Dousend',
					'zero' => '0 Dousend',
				},
				'10000' => {
					'one' => '00 Dousend',
					'other' => '00 Dousend',
					'zero' => '00 Dousend',
				},
				'100000' => {
					'one' => '000 Dousend',
					'other' => '000 Dousend',
					'zero' => '000 Dousend',
				},
				'1000000' => {
					'one' => '0 Million',
					'other' => '0 Milljuhne',
					'zero' => '0 Milljuhne',
				},
				'10000000' => {
					'one' => '00 Milljuhne',
					'other' => '00 Millionen',
					'zero' => '00 Milljuhne',
				},
				'100000000' => {
					'one' => '000 Milljuhne',
					'other' => '000 Millionen',
					'zero' => '000 Milljuhne',
				},
				'1000000000' => {
					'one' => '0 Milliarde',
					'other' => '0 Milljarde',
					'zero' => '0 Milljard',
				},
				'10000000000' => {
					'one' => '00 Milljarde',
					'other' => '00 Milliarden',
					'zero' => '00 Milljarde',
				},
				'100000000000' => {
					'one' => '000 Milliarde',
					'other' => '000 Milliarden',
					'zero' => '000 Milljarde',
				},
				'1000000000000' => {
					'one' => '0 Billjuhn',
					'other' => '0 Billjuhn',
					'zero' => '0 Billjuhn',
				},
				'10000000000000' => {
					'one' => '00 Billion',
					'other' => '00 Billionen',
					'zero' => '00 Billjuhn',
				},
				'100000000000000' => {
					'one' => '000 Billion',
					'other' => '000 Billionen',
					'zero' => '000 Billjuhn',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 tsd',
					'other' => '0 tsd',
					'zero' => '0 tsd',
				},
				'10000' => {
					'one' => '00 tsd',
					'other' => '00 tsd',
					'zero' => '00 tsd',
				},
				'100000' => {
					'one' => '000 tsd',
					'other' => '000 tsd',
					'zero' => '000 tsd',
				},
				'1000000' => {
					'one' => '0 Mio',
					'other' => '0 Mio',
					'zero' => '0 Mio',
				},
				'10000000' => {
					'one' => '00 Mio',
					'other' => '00 Mio',
					'zero' => '00 Mio',
				},
				'100000000' => {
					'one' => '000 Mio',
					'other' => '000 Mio',
					'zero' => '000 Mio',
				},
				'1000000000' => {
					'one' => '0 Mrd',
					'other' => '0 Mrd',
					'zero' => '0 Mrd',
				},
				'10000000000' => {
					'one' => '00 Mrd',
					'other' => '00 Mrd',
					'zero' => '00 Mrd',
				},
				'100000000000' => {
					'one' => '000 Mrd',
					'other' => '000 Mrd',
					'zero' => '000 Mrd',
				},
				'1000000000000' => {
					'one' => '0 Bio',
					'other' => '0 Bio',
					'zero' => '0 Bio',
				},
				'10000000000000' => {
					'one' => '00 Bio',
					'other' => '00 Bio',
					'zero' => '00 Bio',
				},
				'100000000000000' => {
					'one' => '000 Bio',
					'other' => '000 Bio',
					'zero' => '000 Bio',
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
		'AED' => {
			display_name => {
				'currency' => q(de vereineschte arraabesche Emiraate ier Dirham),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(Afjahni),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(albaanesche Lek),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(armeenesche Dram),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(neederlängsch antillesche Jullde),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(angjolaanesche Kwansa),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(ajentiinesche Peeso),
				'one' => q(ajentiinesche Peesos),
				'other' => q(ajentiinesche Peesos),
				'zero' => q(ajentiinesche Peesos),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(austraalesche Dollaa),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(arubesche Florin),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Asserbaidschaani Manat \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Asserbaidschaani Manat),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(ömtuuschbaa Mark us Boßnije un dä Hächejovvina),
				'one' => q(öpmtuuschbaa Mark us Boßnije un dä Hächejovvina),
				'other' => q(öpmtuuschbaa Mark us Boßnije un dä Hächejovvina),
				'zero' => q(öpmtuuschbaa Mark us Boßnije un dä Hächejovvina),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbados-Dollaa),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(Taka us Bangladäsch),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(buljaaresche Lev),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bachrainesche Denaa),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(burundesche Frang),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermuuda-Dollaa),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(Brunei-Dollaa),
				'one' => q(Brunei-Dollaaa),
				'other' => q(Brunei-Dollaaa),
				'zero' => q(Brunei-Dollaaa),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Bollivijano),
				'one' => q(Bollivijano),
				'other' => q(Bollivijano),
				'zero' => q(Bollivijano),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(brasilljaanesche Real),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(bahama’sche Dollaa),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(bhutanesesche Ngultrum),
				'one' => q(Bhutanesesche Ngultrum),
				'other' => q(Bhutanesesche Ngultrum),
				'zero' => q(Bhutanesesche Ngultrum),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Pula us Bozwaana),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(wiißrußesche Rubel),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(wiißrußesche Rubel \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(belizjaanesche Dollaa),
				'one' => q(Belizjaanesche Dollaa),
				'other' => q(Belizjaanesche Dollaa),
				'zero' => q(Belizjaanesche Dollaa),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(kannaadesche Dollaa),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(kongjoleesesche Frang),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(schweijzer Fränkli),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(schileenesche Peeso),
				'one' => q(schileenesche Peesos),
				'other' => q(schileenesche Peesos),
				'zero' => q(schileenesche Peesos),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(schineesesche Yuan Renminbi),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(kolumbesche Peso),
				'one' => q(kolumbesche Pesos),
				'other' => q(kolumbesche Pesos),
				'zero' => q(kolumbesche Pesos),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(koßtarikaanesche Colón),
				'one' => q(Kaßtarikaanesche Colón),
				'other' => q(Kaßtarikaanesche Colón),
				'zero' => q(Kaßtarikaanesche Colón),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(ömtuuschbaa kubaanesche Pesos),
				'one' => q(ömtuuschbaa kubaanesche Pesos),
				'other' => q(ömtuuschbaa kubaanesche Pesos),
				'zero' => q(ömtuuschbaa kubaanesche Pesos),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(kubaanesche Peesos),
				'one' => q(kubaanesche Peesos),
				'other' => q(kubaanesche Peesos),
				'zero' => q(kubaanesche Peesos),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(kapverdesche Eskuudos),
				'one' => q(kapverdesche Eskuudos),
				'other' => q(kapverdesche Eskuudos),
				'zero' => q(kapverdesche Eskuudos),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(tschäschesche Kruhne),
				'one' => q(tschäschesche Kruhne),
				'other' => q(tschäschesche Kruhne),
				'zero' => q(tschäschesche Kruhne),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Frang uß Dschibuti),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(dänesche Kruhne),
				'one' => q(dänesche Kruhne),
				'other' => q(dänesche Kruhne),
				'zero' => q(dänesche Kruhne),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(dommenikaanesche Peesos),
				'one' => q(dommenikaanesche Peeso),
				'other' => q(dommenikaanesche Peesos),
				'zero' => q(dommenikaanesche Peesos),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(aljeresche Denaa),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Äßnesche Kruhne),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(äjiptesche Pongk),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Nafka uß Erritreja),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(ätejoopesche Birr),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(Euro),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Fidschi-Dollaa),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Pongk vun de Falkland-Enselle),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(brittesche £),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(jeorjesche Lari),
				'one' => q(jeorjesche LAri),
				'other' => q(jeorjesche LAri),
				'zero' => q(jeorjesche LAri),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(janaaesche Cedi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(jibraltaa’sche Pongk),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(jambesche Dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Jineea-Frang),
				'one' => q(Jineea-Franke),
				'other' => q(Jineea-Franke),
				'zero' => q(Jineea-Franke),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(juatemalesche Quetzal),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Juaana-Dollaa),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(Hongkong-Dollaa),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(hondureanesche Lempira),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(krowaatesche Kuna),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(haiitesche Gourde),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(unjarresche Forint),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(indoneesesche Ruupije),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(ißraeelesche Schekel),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(indesche Ruupije),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(iraakesche Denaa),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(persesche Rial),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(ißländesche Kruhne),
				'one' => q(ißländesche Kruhne),
				'other' => q(ißländesche Kruhne),
				'zero' => q(ißländesche Kruhne),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(jamaikaanesche Dollaa),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Jordaanesche Dollaa),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(japaanesche Jen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Kenjaanesche Schillinge),
				'one' => q(Kenjaanesche Schillinge),
				'other' => q(Kenjaanesche Schillinge),
				'zero' => q(Kenjaanesche Schillinge),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(kirjiisesche Som),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(kambodschaanesche Riel),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(kommooresche Frang),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(noodkorejaansche Won),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(söödkorejaansche Won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(kuwaitesche Denaa),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Kaimann-Dollaa),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(kasakesche Tenge),
				'one' => q(kasakstaanesche Tenge),
				'other' => q(kasakstaanesche Tenge),
				'zero' => q(kasakstaanesche Tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(loaatesche Kip),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(libaneesesche Pongk),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(schrilankesche Ruupije),
				'one' => q(schri-lankesche Ruupije),
				'other' => q(schri-lankesche Ruupije),
				'zero' => q(schri-lankesche Ruupije),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(liberijaanesche Dollaa),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(lesoothesche Loti),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(littouesche Litas),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(lättesche Lats),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(libesche Denaa),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(marrokaanesche Dirhamm),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(moldaavesche Leu),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(madajaskesche Ariary),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(mazedoonesche Denaa),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(burmeesesche Kyat),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(mongjoolesche Tugrik),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(makaneesesche Pataca),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(mauretanesche Ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(mauretanesche Ouguiya),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(maurizjahnesche Ruupije),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(mallediivesche Rufiyaa),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(malaawesche Kwache),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(mexekaanesche Peeso),
				'one' => q(mexekaanesche Peeso),
				'other' => q(mexekaanesche Peeso),
				'zero' => q(mexekaanesche Peeso),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(malaisesche Ringgit),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(mosambikaanesche Metical \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(mossambikaanesche Metical),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(namiibesche Dollaa),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(nijerijaanesche Naira),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(nikarajaanesche Córdoba),
				'one' => q(nikarajaanesche Córdoba),
				'other' => q(nikarajaanesche Córdoba),
				'zero' => q(nikarajaanesche Córdoba),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(norrweejesche Kruhne),
				'one' => q(norrweejesche Kruhne),
				'other' => q(norrweejesche Kruhne),
				'zero' => q(norrweejesche Kruhne),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(nepaleesesche Ruupije),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(neuseeländesche Dollaa),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(ommaanesche Rijal),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(pannameesesche Balboa),
				'one' => q(pannameesesche Balboa),
				'other' => q(pannameesesche Balboa),
				'zero' => q(pannameesesche Balboa),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(perruaanesche Sol),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(papua neujinejaanesche Kina),
			},
		},
		'PHP' => {
			display_name => {
				'currency' => q(fillipiinesche Pesos),
				'one' => q(fillipiinesche Pesos),
				'other' => q(fillipiinesche Pesos),
				'zero' => q(fillipiinesche Pesos),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(pakestaanesche Ruupije),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(polnesche Złoty),
				'one' => q(polnesche Złoty),
				'other' => q(polnesche Złoty),
				'zero' => q(polnesche Złoty),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(parajuaanesche Juarani),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(kataaresche Rijal),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(romäänesche Leu \(1952–2006\)),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(romäänesche Leu),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(särbesche Denaare),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(russesche Ruubel),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(ruandesche Frang),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(saudesche Rijal),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(solomonesche Dollaa),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(seischellesche Ruupije),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(sudaneesesche Pongk),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(schweedesche Kruhne),
				'one' => q(schweedesche Kruhne),
				'other' => q(schweedesche Kruhne),
				'zero' => q(schweedesche Kruhne),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(singjapurejaanesche Dollaa),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(Zint-Hellena-Pongk),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(ßlovaakesche Kruhne),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(ẞjärra-lejoneesesche Leone),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(somaalesche Schillenge),
				'one' => q(somaalesche Schillenge),
				'other' => q(somaalesche Schillenge),
				'zero' => q(somaalesche Schillenge),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(sürinameesesche Dollaa),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(södsudaneesesche Pongk),
				'one' => q(södsudaneesesche Pongk),
				'other' => q(södsudaneesesche Pongk),
				'zero' => q(södsudaneesesche Pongk),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(Dobra vun São Tomé un Príncipe \(1977–2017\)),
				'one' => q(Dobra vun São Tomé un Príncipe \(1977–2017\)),
				'other' => q(Dobra vun São Tomé un Príncipe \(1977–2017\)),
				'zero' => q(Dobra vun São Tomé un Príncipe \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(Dobra vun São Tomé un Príncipe),
				'one' => q(Dobra vun São Tomé un Príncipe),
				'other' => q(Dobra vun São Tomé un Príncipe),
				'zero' => q(Dobra vun São Tomé un Príncipe),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(asalvadorejaanesche Cosan),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(süüresche Pund),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(swasiländesche Lilangeni),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(tailändesche Baht),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(tadschikißtaanesche Somoni),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(turkmeneßtaanesche Manat \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(turkmeneßtaanesche Manat),
				'one' => q(turkmeneßtaanesche Manat),
				'other' => q(turkmeneßtaanesche Manat),
				'zero' => q(turkmeneßtaanesche Manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(tuneesesche Denaa),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(tongjanes Paʻangache),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(törkesche Liire),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Dollaa uß Trinidad un Tobääjo),
				'one' => q(Dollaa uß Trinidad un Tobääjo),
				'other' => q(Dollaa uß Trinidad un Tobääjo),
				'zero' => q(Dollaa uß Trinidad un Tobääjo),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(neu taiwaneesesche Dollaa),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(tansaanesche Schillenge),
				'one' => q(tansaanesche Schillenge),
				'other' => q(tansaanesche Schillenge),
				'zero' => q(tansaanesche Schillenge),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(ukraijnesche Hryvnia),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(ujandesche Schillenge),
				'one' => q(ujandesche Schillenge),
				'other' => q(ujandesche Schillenge),
				'zero' => q(ujandesche Schillenge),
			},
		},
		'USD' => {
			display_name => {
				'currency' => q(ammärrikaanesche Dollaa),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(urrujuwaische Peeso),
				'one' => q(urrujuwaische Peeso),
				'other' => q(urrujuwaische Peeso),
				'zero' => q(urrujuwaische Peeso),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(ußbeekesche Som),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(venezuelaanesche Bolívar \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(venezuelaanesche Bolívar),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(vijätnammeesesche Dong),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vanuatesche Vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(samowaanesche Tala),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(Kmmeruhner Frang),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Sellver),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Jold),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(oß-karribbesche Dollaa),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(franzüüsesche Joldfranke),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(Frang uß de Älfebeinköß),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Palladijum),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(polineesesche Frang),
				'one' => q(polineesesche Frang),
				'other' => q(polineesesche Frang),
				'zero' => q(polineesesche Frang),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Plaatin),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(Währong zum Prööfe),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(onbikannte Währong),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(jemenitesche Rijal),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(södaffrekaanesche Rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(sambesche Kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(sambesche Kwacha),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(simbabwesche Dollaa \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(simbabwesche Dollaa \(2009\)),
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
							'Fäb',
							'Mäz',
							'Apr',
							'Mai',
							'Jun',
							'Jul',
							'Ouj',
							'Säp',
							'Okt',
							'Nov',
							'Dez'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Jannewa',
							'Fäbrowa',
							'Määz',
							'Aprell',
							'Mai',
							'Juuni',
							'Juuli',
							'Oujoß',
							'Septämber',
							'Oktohber',
							'Novämber',
							'Dezämber'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Jan.',
							'Fäb.',
							'Mäz.',
							'Apr.',
							'Mai',
							'Jun.',
							'Jul.',
							'Ouj.',
							'Säp.',
							'Okt.',
							'Nov.',
							'Dez.'
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
							'O',
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
						mon => 'Mo.',
						tue => 'Di.',
						wed => 'Me.',
						thu => 'Du.',
						fri => 'Fr.',
						sat => 'Sa.',
						sun => 'Su.'
					},
					short => {
						mon => 'Mo',
						tue => 'Di',
						wed => 'Me',
						thu => 'Du',
						fri => 'Fr',
						sat => 'Sa',
						sun => 'Su'
					},
					wide => {
						mon => 'Mohndaach',
						tue => 'Dinnsdaach',
						wed => 'Metwoch',
						thu => 'Dunnersdaach',
						fri => 'Friidaach',
						sat => 'Samsdaach',
						sun => 'Sunndaach'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'M',
						tue => 'D',
						wed => 'M',
						thu => 'D',
						fri => 'F',
						sat => 'S',
						sun => 'S'
					},
					short => {
						mon => 'Mo',
						tue => 'Di',
						wed => 'Me',
						thu => 'Du',
						fri => 'Fr',
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
					abbreviated => {0 => '1.Q.',
						1 => '2.Q.',
						2 => '3.Q.',
						3 => '4.Q.'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1. Quattahl',
						1 => '2. Quattahl',
						2 => '3. Quattahl',
						3 => '4. Quattahl'
					},
				},
				'stand-alone' => {
					narrow => {0 => '1Q',
						1 => '2Q',
						2 => '3Q',
						3 => '4Q'
					},
					wide => {0 => '1. Quattahl',
						1 => '2. Quattahl',
						2 => '3. Quattahl',
						3 => '4. Quattahl'
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
					'am' => q{v.M.},
					'pm' => q{n.M.},
				},
				'wide' => {
					'am' => q{Uhr vörmiddaachs},
					'pm' => q{Uhr nommendaachs},
				},
			},
			'stand-alone' => {
				'wide' => {
					'am' => q{Vörmeddaach},
					'pm' => q{Nommendaach},
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
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'v. Chr.',
				'1' => 'n. Chr.'
			},
			narrow => {
				'0' => 'vC',
				'1' => 'nC'
			},
			wide => {
				'0' => 'vür Krestos',
				'1' => 'noh Krestos'
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
			'full' => q{EEEE, d. MMMM y G},
		},
		'generic' => {
			'full' => q{EEEE, 'dä' d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{d. MMM. y G},
			'short' => q{d. M. y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, 'dä' d. MMMM y},
			'long' => q{d. MMMM y},
			'medium' => q{d. MMM. y},
			'short' => q{d. M. y},
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
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
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
		'buddhist' => {
		},
		'generic' => {
		},
		'gregorian' => {
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Ed => q{E 'dä' d.},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			M => q{L},
			MEd => q{E d. M.},
			MMM => q{LLL},
			MMMEd => q{E d. MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			d => q{d},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y},
			yM => q{Y-MM},
			yMEd => q{E y-MM-dd},
			yMMM => q{MMM y},
			yMMMEd => q{E d. MMM. y},
			yMMMM => q{MMMM y},
			yMMMd => q{d. MMM. y},
			yMd => q{y-MM-dd},
			yQQQ => q{QQQy},
			yQQQQ => q{QQQQ y},
		},
		'gregorian' => {
			Ed => q{E 'dä' d.},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			M => q{L},
			MEd => q{E d. M.},
			MMM => q{LLL},
			MMMEd => q{E d. MMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. MMM},
			d => q{d},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y},
			yM => q{Y-MM},
			yMEd => q{E y-MM-dd},
			yMMM => q{MMM y},
			yMMMEd => q{E d. MMM. y},
			yMMMM => q{MMMM y},
			yMMMd => q{d. MMM. y},
			yMd => q{y-MM-dd},
			yQQQ => q{QQQy},
			yQQQQ => q{QQQQ y},
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
			M => {
				M => q{M–M},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			Md => {
				d => q{dd. – dd. MM.},
			},
			d => {
				d => q{d–d},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			y => {
				y => q{y–y},
			},
			yMEd => {
				M => q{E y-MM-dd – E y-MM-dd},
				d => q{E y-MM-dd – E y-MM-dd},
				y => q{E y-MM-dd – E y-MM-dd},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM. y – MMM. y},
			},
			yMMMEd => {
				M => q{E y-MM-dd – E y-MM-dd},
				d => q{E y-MM-dd – E y-MM-dd},
				y => q{E y-MM-dd – E y-MM-dd},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
		},
		'gregorian' => {
			M => {
				M => q{M–M},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			Md => {
				d => q{dd. – dd. MM.},
			},
			d => {
				d => q{d–d},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm–h:mm a},
				m => q{h:mm–h:mm a},
			},
			y => {
				y => q{y–y},
			},
			yMEd => {
				M => q{E y-MM-dd – E y-MM-dd},
				d => q{E y-MM-dd – E y-MM-dd},
				y => q{E y-MM-dd – E y-MM-dd},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM. y – MMM. y},
			},
			yMMMEd => {
				M => q{E y-MM-dd – E y-MM-dd},
				d => q{E y-MM-dd – E y-MM-dd},
				y => q{E y-MM-dd – E y-MM-dd},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{y MMM d – MMM d},
				d => q{d.–d. MMMM y},
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
		regionFormat => q(Zick vun {0}),
		regionFormat => q(Summerzick vun {0}),
		regionFormat => q(Schtandattzick vun {0}),
		fallbackFormat => q({1} ({0})),
		'Africa/Cairo' => {
			exemplarCity => q#Kaijro#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Laajos#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhuk#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Zentraal-Affrekaanesche Zigg#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Oß-Affrekaanesche Zigg#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Söd-Affrekaanesche Zigg#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Wäß-Affrekaanesche Sommerzigg#,
				'generic' => q#Wäß-Affrekaanesche Zigg#,
				'standard' => q#Jewöhnlijje Wäß-Affrekaanesche Zigg#,
			},
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Koßtaricka#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Juayaquil#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knox en Indiana#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo en Indiana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petersburg en Indiana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell City en Indiana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vevay en Indiana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vincennes en Indiana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamac en Indiana#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello en Kentucky#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Schtadt Mexiko#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah en Nood Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Zenter en Nood Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Neu Salem en Nood Dakota#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Zint Barthélemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Zint John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#Zint Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Santa Lutschiija#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Zint Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Zint Vintschänt#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Jakutat#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont-d’Urville-Schtazjohn#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Schoowa-Schtazjohn op dä Ensel Onjul#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Wostok#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtöbe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Asshgabat#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bischkek#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaskus#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Duschanbe#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Jaasa#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamschattka#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosija#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Pnom Penh#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Qysylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Ranjun#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Rijad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Sigong (Ho-Tschi-Minh-Schtadt)#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Schanghai#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singjapuur#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taschkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tiblis#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulan Bator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urrumptschi#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Wladiwostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekaterinburg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Eriwan#,
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azoore#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kannaare#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kap Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Färör#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Zint Helena#,
		},
		'Azores' => {
			long => {
				'daylight' => q#de Azore ier Summerzick#,
				'generic' => q#de Azore ier Zick#,
				'standard' => q#de Azore ier jewöhnlijje Zick#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kapvärdejaansche Sommerzigg#,
				'generic' => q#Kapvärdejaansche Zigg#,
				'standard' => q#Jewöhnlijje Kapvärdejaansche Zigg#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#- weße mer nit -#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athen#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Beljrad#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brüssel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenharen#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Irland sing Summerzick#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Jibraltaa#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Jöönsei#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Ensel Män#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istambul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jöösei#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kalinninjraad#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Jrußbretannije sing Summerzick#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxembursch#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskau#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prag#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riija#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rom#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tiraana#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uschjorod#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#der Vatikahn#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wien#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Woljojrad#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warschau#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Sagreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Saporischschja#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Züresch#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Meddel-Europpa sing Summerzick#,
				'generic' => q#Meddel-Europpa sing Zick#,
				'standard' => q#Meddel-Europpa sing jewöhnlijje Zick#,
			},
			short => {
				'daylight' => q#MESZ#,
				'generic' => q#MEZ#,
				'standard' => q#MEZ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Oß-Europpa sing Summerzick#,
				'generic' => q#Oß-Europpa sing Zick#,
				'standard' => q#Oß-Europpa sing jewöhnlijje Zick#,
			},
			short => {
				'daylight' => q#OESZ#,
				'generic' => q#OEZ#,
				'standard' => q#OEZ#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Weß-Europpa sing Summerzick#,
				'generic' => q#Weß-Europpa sing Zick#,
				'standard' => q#Weß-Europpa sing jewöhnlijje Zick#,
			},
			short => {
				'daylight' => q#WESZ#,
				'generic' => q#WEZ#,
				'standard' => q#WEZ#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Greenwich sing Standat-Zick#,
			},
		},
		'Indian/Maldives' => {
			exemplarCity => q#Malldive#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#dem Indische Ozejan sing Zick#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Summerzigg vun Mauritius#,
				'generic' => q#Zigg vun Mauritius#,
				'standard' => q#Jewöhnlijje Zigg vun Mauritius#,
			},
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Jalappajos#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Juam#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honululu#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitkern#,
		},
		'Reunion' => {
			long => {
				'standard' => q#Zigg vun Reunion#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Zigg vun de Seischälle#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
