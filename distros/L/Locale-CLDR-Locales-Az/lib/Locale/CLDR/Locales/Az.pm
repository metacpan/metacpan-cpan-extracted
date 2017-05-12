=head1

Locale::CLDR::Locales::Az - Package for language Azerbaijani

=cut

package Locale::CLDR::Locales::Az;
# This file auto generated from Data\common\main\az.xml
#	on Fri 29 Apr  6:51:35 pm GMT

use version;

our $VERSION = version->declare('v0.29.0');

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
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal','spellout-ordinal','digits-ordinal' ]},
);

has 'algorithmic_number_format_data' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { 
		use bignum;
		return {
		'digits-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(−→→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0==%%digits-ordinal-indicator=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=#,##0==%%digits-ordinal-indicator=),
				},
			},
		},
		'digits-ordinal-indicator' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(''inci),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(''inci),
				},
			},
		},
		'inci' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(inci),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
			},
		},
		'inci2' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ıncı),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
			},
		},
		'nci' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nci),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
			},
		},
		'spellout-cardinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(əksi →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(sıfır),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← tam →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(bir),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(iki),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(üç),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(dörd),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(beş),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(altı),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(yeddi),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(səkkiz),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(doqquz),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(on[ →→]),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(iyirmi[ →→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(otuz[ →→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(qırx[ →→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(əlli[ →→]),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(atmış[ →→]),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(yetmiş[ →→]),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(səqsən[ →→]),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(doxsan[ →→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←← yüz[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←← min[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← milyon[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← milyard[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← trilyon[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← katrilyon[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
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
					rule => q(=#,###0.#=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=#,###0.#=),
				},
			},
		},
		'spellout-ordinal' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(əksi →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(sıfırıncı),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.#=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(birinci),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(ikinci),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(üçüncü),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(dördüncü),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(beşinci),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(altıncı),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(yeddinci),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(səkkizinci),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(doqquzuncu),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(on→%%uncu→),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(iyirmi→%%nci→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(otuz→%%uncu→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(qırx→%%inci2→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(əlli→%%nci→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(altmış→%%inci2→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(yetmiş→%%inci2→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(səqsən→%%inci2→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(doxsan→%%inci2→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-numbering← yüz→%%uncu2→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-numbering← bin→%%inci→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-numbering← milyon→%%uncu→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-numbering← milyar→%%inci2→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-numbering← trilyon→%%uncu→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-numbering← katrilyon→%%uncu→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0='inci),
				},
				'max' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0='inci),
				},
			},
		},
		'uncu' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(uncu),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
			},
		},
		'uncu2' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(üncü),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal=),
				},
			},
		},
	} },
);

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
				'aa' => 'afarca',
 				'ab' => 'abxaz',
 				'ace' => 'akin',
 				'ach' => 'akoli',
 				'ada' => 'adangme',
 				'ady' => 'aduge',
 				'ae' => 'avestanca',
 				'af' => 'afrikaans',
 				'afh' => 'afrihili',
 				'agq' => 'aqhem',
 				'ain' => 'aynuca',
 				'ak' => 'akanca',
 				'akk' => 'akadianca',
 				'ale' => 'aleutca',
 				'alt' => 'cənub altay',
 				'am' => 'amhar',
 				'an' => 'aragonca',
 				'ang' => 'qədimi ingiliscə',
 				'anp' => 'angikə',
 				'ar' => 'ərəb',
 				'ar_001' => 'Modern Standart Ərəbcə',
 				'arc' => 'aramik',
 				'arn' => 'araukanca',
 				'arp' => 'arapaho',
 				'arw' => 'aravakça',
 				'as' => 'assam',
 				'asa' => 'asu',
 				'ast' => 'asturicə',
 				'av' => 'avarikcə',
 				'awa' => 'avadicə',
 				'ay' => 'aymarca',
 				'az' => 'azərbaycan dili',
 				'az@alt=short' => 'azəri',
 				'az_Arab' => 'cənubi azərbaycan',
 				'ba' => 'başqırd',
 				'bal' => 'baluc',
 				'ban' => 'balincə',
 				'bas' => 'basa',
 				'be' => 'belarus',
 				'bej' => 'beja',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bg' => 'bolqar',
 				'bgn' => 'qərbi bəluc',
 				'bho' => 'bxoçpuri',
 				'bi' => 'bislama',
 				'bik' => 'bikolca',
 				'bin' => 'bini',
 				'bla' => 'siksikə',
 				'bm' => 'bambara',
 				'bn' => 'benqal',
 				'bo' => 'tibet',
 				'br' => 'Bretonca',
 				'bra' => 'braj',
 				'brx' => 'bodo',
 				'bs' => 'bosniak',
 				'bua' => 'buryat',
 				'bug' => 'bugin',
 				'byn' => 'bilincə',
 				'ca' => 'katalan',
 				'cad' => 'kado',
 				'car' => 'karib',
 				'cch' => 'atsamca',
 				'ce' => 'çeçen',
 				'ceb' => 'kebuano',
 				'cgg' => 'çiqa',
 				'ch' => 'çamoro',
 				'chb' => 'çibçə',
 				'chg' => 'çağatay',
 				'chk' => 'çukiz',
 				'chm' => 'mari',
 				'chn' => 'çinuk ləhçəsi',
 				'cho' => 'çoktau',
 				'chp' => 'çipevyan',
 				'chr' => 'çiroki',
 				'chy' => 'çeyen',
 				'ckb' => 'sorani kürd',
 				'co' => 'korsika',
 				'cop' => 'kopt',
 				'cr' => 'kri dili',
 				'crh' => 'krım türkçə',
 				'cs' => 'çex',
 				'csb' => 'kaşubyan',
 				'cu' => 'kilsə slav',
 				'cv' => 'çuvaş',
 				'cy' => 'uels',
 				'da' => 'danimarka',
 				'dak' => 'dakota',
 				'dar' => 'darqva',
 				'dav' => 'taita',
 				'de' => 'alman',
 				'de_AT' => 'Avstriya almancası',
 				'de_CH' => 'İsveçrə yüksək almancası',
 				'del' => 'delaver',
 				'den' => 'slavey',
 				'dgr' => 'doqrib',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'doqri',
 				'dsb' => 'aşağı sorb',
 				'dua' => 'duala',
 				'dum' => 'ortacaq hollandca',
 				'dv' => 'diveh',
 				'dyo' => 'diola',
 				'dyu' => 'dyula',
 				'dz' => 'dzonqa',
 				'ebu' => 'embu',
 				'ee' => 'eve',
 				'efi' => 'efik',
 				'egy' => 'qədimi misir',
 				'eka' => 'ekacuk',
 				'el' => 'yunan',
 				'elx' => 'elamit',
 				'en' => 'ingilis',
 				'en_AU' => 'Avstraliya ingiliscəsi',
 				'en_CA' => 'Kanada ingiliscəsi',
 				'en_GB' => 'Britaniya ingiliscəsi',
 				'en_GB@alt=short' => 'ingilis (B.K.)',
 				'en_US' => 'Amerika ingiliscəsi',
 				'en_US@alt=short' => 'ingilis (A.B.Ş.)',
 				'enm' => 'ortacaq ingiliscə',
 				'eo' => 'esperanto',
 				'es' => 'ispan',
 				'es_419' => 'Latın Amerikası ispancası',
 				'es_ES' => 'Kastiliya ispancası',
 				'es_MX' => 'Meksika ispancası',
 				'et' => 'eston',
 				'eu' => 'bask',
 				'ewo' => 'evondo',
 				'fa' => 'fars',
 				'fan' => 'fang',
 				'fat' => 'fanti',
 				'ff' => 'fula',
 				'fi' => 'fin',
 				'fil' => 'filippin',
 				'fj' => 'fici',
 				'fo' => 'farer',
 				'fon' => 'fon',
 				'fr' => 'fransız',
 				'fr_CA' => 'Kanada fransızcası',
 				'fr_CH' => 'İsveçrə fransızcası',
 				'frm' => 'ortacaq fransızca',
 				'fro' => 'qədimi fransızca',
 				'frr' => 'şimal fris',
 				'fur' => 'friul',
 				'fy' => 'qərbi friz',
 				'ga' => 'irland',
 				'gaa' => 'qa',
 				'gag' => 'qaqauz',
 				'gay' => 'qayo',
 				'gba' => 'qabaya',
 				'gd' => 'skot gaelik',
 				'gez' => 'qez',
 				'gil' => 'qilbert gili',
 				'gl' => 'qalisian',
 				'gmh' => 'ortacaq yüksək almanca',
 				'gn' => 'quarani',
 				'goh' => 'qədimi almanca',
 				'gon' => 'qondi',
 				'gor' => 'qorontalo',
 				'got' => 'gotça',
 				'grb' => 'qrebo',
 				'grc' => 'qədimi yunanca',
 				'gsw' => 'İsveçrə almancası',
 				'gu' => 'qucarat',
 				'guz' => 'qusi',
 				'gv' => 'manks',
 				'gwi' => 'qviçin',
 				'ha' => 'hausa',
 				'hai' => 'hayda',
 				'haw' => 'havay',
 				'he' => 'ivrit',
 				'hi' => 'hindi',
 				'hil' => 'hiliqaynon',
 				'hit' => 'hittit',
 				'hmn' => 'monq',
 				'ho' => 'hiri motu',
 				'hr' => 'xorvat',
 				'hsb' => 'yuxarı sorb',
 				'ht' => 'haiti',
 				'hu' => 'macar',
 				'hup' => 'hupa',
 				'hy' => 'erməni',
 				'hz' => 'Herer',
 				'ia' => 'interlingua',
 				'iba' => 'iban',
 				'id' => 'indonez',
 				'ie' => 'interlingue',
 				'ig' => 'iqbo',
 				'ii' => 'siçuan yi',
 				'ik' => 'inupiaq',
 				'ilo' => 'iloko',
 				'inh' => 'inquş',
 				'io' => 'ido',
 				'is' => 'island',
 				'it' => 'italyan',
 				'iu' => 'inuktitut',
 				'ja' => 'yapon',
 				'jbo' => 'loğban',
 				'jgo' => 'nqomba',
 				'jmc' => 'maçam',
 				'jpr' => 'judo-farsca',
 				'jrb' => 'jude-ərəbcə',
 				'jv' => 'yava',
 				'ka' => 'gürcü',
 				'kaa' => 'qara-qalpaq',
 				'kab' => 'kabile',
 				'kac' => 'kaçinca',
 				'kaj' => 'ju',
 				'kam' => 'kamba',
 				'kaw' => 'kavi',
 				'kbd' => 'kabardca',
 				'kcg' => 'tiyap',
 				'kde' => 'makond',
 				'kea' => 'kabuverdian',
 				'kfo' => 'koro',
 				'kg' => 'konqo',
 				'kha' => 'xazi',
 				'kho' => 'xotan',
 				'khq' => 'koyra çiini',
 				'ki' => 'kikuyu',
 				'kj' => 'kuanyama',
 				'kk' => 'qazax',
 				'kl' => 'kalaallisut',
 				'kln' => 'kalencin',
 				'km' => 'kxmer',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannada',
 				'ko' => 'koreya',
 				'koi' => 'komi-permyak',
 				'kok' => 'konkan',
 				'kos' => 'kosreyan',
 				'kpe' => 'kpelle',
 				'kr' => 'kanur',
 				'krc' => 'qaraçay-balkar',
 				'krl' => 'karelyan',
 				'kru' => 'kurux',
 				'ks' => 'kaşmir',
 				'ksb' => 'şambala',
 				'ksf' => 'bafia',
 				'ku' => 'kürd',
 				'kum' => 'kumuk',
 				'kut' => 'kutenay',
 				'kv' => 'komi',
 				'kw' => 'korn',
 				'ky' => 'qırğız',
 				'la' => 'latın',
 				'lad' => 'ladin',
 				'lag' => 'langi',
 				'lah' => 'laxnda',
 				'lam' => 'lamba',
 				'lb' => 'lüksemburq',
 				'lez' => 'ləzqi',
 				'lg' => 'qanda',
 				'li' => 'limburqiş',
 				'lkt' => 'lakota',
 				'ln' => 'linqala',
 				'lo' => 'laos',
 				'lol' => 'monqo',
 				'loz' => 'lozi',
 				'lrc' => 'şimali luri',
 				'lt' => 'litva',
 				'lu' => 'luba-katanqa',
 				'lua' => 'luba-lulua',
 				'lui' => 'luyseno',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'lushayca',
 				'luy' => 'luyia',
 				'lv' => 'latış',
 				'mad' => 'maduriz',
 				'mag' => 'maqahi',
 				'mai' => 'maitili',
 				'mak' => 'makasar',
 				'man' => 'məndinqo',
 				'mas' => 'masay',
 				'mdf' => 'mokşa',
 				'mdr' => 'mandar',
 				'men' => 'mende',
 				'mer' => 'meru',
 				'mfe' => 'morisien',
 				'mg' => 'malaqas',
 				'mga' => 'ortacaq irlandca',
 				'mgh' => 'maxuva-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'marşal',
 				'mi' => 'maori',
 				'mic' => 'mikmak',
 				'min' => 'minanqkaban',
 				'mk' => 'makedon',
 				'ml' => 'malayalam',
 				'mn' => 'monqol',
 				'mnc' => 'mançu',
 				'mni' => 'manipüri',
 				'moh' => 'mohavk',
 				'mos' => 'mosi',
 				'mr' => 'marati',
 				'ms' => 'malay',
 				'mt' => 'malta',
 				'mua' => 'mundanq',
 				'mul' => 'digər dillər',
 				'mus' => 'krik',
 				'mwl' => 'mirand',
 				'mwr' => 'maruari',
 				'my' => 'birma',
 				'myv' => 'erzya',
 				'mzn' => 'mazandaran',
 				'na' => 'nauru',
 				'nap' => 'neapolital',
 				'naq' => 'nama',
 				'nb' => 'bokmal norveç',
 				'nd' => 'şimali ndebele',
 				'nds' => 'aşağı almanca',
 				'nds_NL' => 'aşağı sakson',
 				'ne' => 'nepal',
 				'new' => 'nevari',
 				'ng' => 'nqonka',
 				'nia' => 'nyas',
 				'niu' => 'niyuan',
 				'nl' => 'holland',
 				'nl_BE' => 'flamand',
 				'nmg' => 'kvasio',
 				'nn' => 'nünorsk norveç',
 				'no' => 'norveç',
 				'nog' => 'noqay',
 				'non' => 'qədimi norsca',
 				'nqo' => 'nqo',
 				'nr' => 'cənub ndebele',
 				'nso' => 'şimal soto',
 				'nus' => 'nuer',
 				'nv' => 'navayo',
 				'ny' => 'nyanca',
 				'nym' => 'nyamvezi',
 				'nyn' => 'nyankol',
 				'nyo' => 'niyoro',
 				'nzi' => 'nizima',
 				'oc' => 'oksitanca',
 				'oj' => 'ocibva',
 				'om' => 'oromo',
 				'or' => 'oriya',
 				'os' => 'osetik',
 				'osa' => 'osage',
 				'ota' => 'osman',
 				'pa' => 'pəncab',
 				'pag' => 'panqasinan',
 				'pal' => 'paxlavi',
 				'pam' => 'pampanqa',
 				'pap' => 'papyamento',
 				'pau' => 'palayanca',
 				'peo' => 'qədimi farsca',
 				'phn' => 'foyenik',
 				'pi' => 'pali',
 				'pl' => 'polyak',
 				'pon' => 'ponpeyan',
 				'pro' => 'qədimi provensialca',
 				'ps' => 'puştu',
 				'pt' => 'portuqal',
 				'pt_BR' => 'Braziliya portuqalcası',
 				'pt_PT' => 'Portuqaliya portuqalcası',
 				'qu' => 'keçua',
 				'quc' => 'kiçe',
 				'raj' => 'racastan',
 				'rap' => 'rapanu',
 				'rar' => 'rarotonqan',
 				'rm' => 'retoroman',
 				'rn' => 'rundi',
 				'ro' => 'rumın',
 				'ro_MD' => 'moldav',
 				'rof' => 'rombo',
 				'rom' => 'roman',
 				'root' => 'rut',
 				'ru' => 'rus',
 				'rup' => 'aromanca',
 				'rw' => 'kinyarvanda',
 				'rwk' => 'rua',
 				'sa' => 'sanskrit',
 				'sad' => 'sandave',
 				'sah' => 'yakut',
 				'sam' => 'samaritan',
 				'saq' => 'samburu',
 				'sas' => 'sasak',
 				'sat' => 'santal',
 				'sbp' => 'sanqu',
 				'sc' => 'sardin',
 				'scn' => 'sisili',
 				'sco' => 'skots',
 				'sd' => 'sindhi',
 				'sdh' => 'cənubi kürd',
 				'se' => 'şimali sami',
 				'seh' => 'sena',
 				'sel' => 'selkup',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sanqo',
 				'sga' => 'qədimi irlandca',
 				'sh' => 'serb-xorvatca',
 				'shi' => 'taçelit',
 				'shn' => 'şan',
 				'si' => 'sinhal',
 				'sid' => 'sidamo',
 				'sk' => 'slovak',
 				'sl' => 'sloven',
 				'sm' => 'samoa',
 				'sma' => 'cənubi sami',
 				'smj' => 'lule sami',
 				'smn' => 'inari sami',
 				'sms' => 'skolt',
 				'sn' => 'şona',
 				'snk' => 'soninke',
 				'so' => 'somali',
 				'sog' => 'soqdiyen',
 				'sq' => 'alban',
 				'sr' => 'serb',
 				'srn' => 'sranan tonqo',
 				'srr' => 'serer dilii',
 				'ss' => 'svati',
 				'st' => 'Sesoto',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumeryan',
 				'sv' => 'isveç',
 				'sw' => 'suahili',
 				'sw_CD' => 'Konqo suahilicəsi',
 				'syr' => 'siryak',
 				'ta' => 'tamil',
 				'te' => 'teluqu',
 				'tem' => 'timne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetum',
 				'tg' => 'tacik',
 				'th' => 'tay',
 				'ti' => 'tiqrin',
 				'tig' => 'tiqre',
 				'tiv' => 'tiv',
 				'tk' => 'türkmən',
 				'tkl' => 'tokelay',
 				'tl' => 'taqaloq',
 				'tlh' => 'klinqon',
 				'tli' => 'tlinqit',
 				'tmh' => 'tamaşek',
 				'tn' => 'svana',
 				'to' => 'tonqa',
 				'tog' => 'niyasa tonga',
 				'tpi' => 'tok pisin',
 				'tr' => 'türk',
 				'ts' => 'sonqa',
 				'tsi' => 'simşyan',
 				'tt' => 'tatar',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalu',
 				'tw' => 'Tvi',
 				'twq' => 'tasavaq',
 				'ty' => 'taxiti',
 				'tyv' => 'tuvinyan',
 				'tzm' => 'Mərkəzi Atlas tamazicəsi',
 				'udm' => 'udmurt',
 				'ug' => 'uyğur',
 				'uga' => 'uqaritik',
 				'uk' => 'ukrayna',
 				'umb' => 'umbundu',
 				'und' => 'naməlum dil',
 				'ur' => 'urdu',
 				'uz' => 'özbək',
 				'vai' => 'vai',
 				've' => 'venda',
 				'vi' => 'vyetnam',
 				'vo' => 'volapük',
 				'vot' => 'votik',
 				'vun' => 'vunyo',
 				'wa' => 'valun',
 				'wal' => 'valamo',
 				'war' => 'varay',
 				'was' => 'vaşo',
 				'wbp' => 'Valpiri',
 				'wo' => 'volof',
 				'xal' => 'kalmıqca',
 				'xh' => 'xosa',
 				'xog' => 'soqa',
 				'yao' => 'yao',
 				'yap' => 'yapiz',
 				'yi' => 'Yahudi',
 				'yo' => 'yoruba',
 				'za' => 'juənq',
 				'zap' => 'zapotek',
 				'zbl' => 'blisimbols',
 				'zen' => 'zenaqa',
 				'zgh' => 'tamazi',
 				'zh' => 'çin',
 				'zh_Hans' => 'sadələşmiş çin',
 				'zh_Hant' => 'ənənəvi çin',
 				'zu' => 'zulu',
 				'zun' => 'zuni',
 				'zxx' => 'dil məzmunu yoxdur',
 				'zza' => 'zaza',

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
			'Arab' => 'ərəb',
 			'Armi' => 'armi',
 			'Armn' => 'erməni',
 			'Avst' => 'avestan',
 			'Bali' => 'bali',
 			'Batk' => 'batak',
 			'Beng' => 'benqal',
 			'Blis' => 'blissymbols',
 			'Bopo' => 'bopomofo',
 			'Brah' => 'brahmi',
 			'Brai' => 'brayl',
 			'Bugi' => 'buqin',
 			'Buhd' => 'buhid',
 			'Cakm' => 'kakm',
 			'Cans' => 'birləşmiş kanada yerli yazısı',
 			'Cari' => 'kariyan',
 			'Cham' => 'çam',
 			'Cher' => 'çiroki',
 			'Cirt' => 'sirt',
 			'Copt' => 'koptik',
 			'Cprt' => 'kipr',
 			'Cyrl' => 'kiril',
 			'Cyrs' => 'qədimi kilsa kirili',
 			'Deva' => 'devanaqari',
 			'Dsrt' => 'deseret',
 			'Egyd' => 'misir demotik',
 			'Egyh' => 'misir hiyeratik',
 			'Egyp' => 'misir hiyeroqlif',
 			'Ethi' => 'efiop',
 			'Geok' => 'gürcü xutsuri',
 			'Geor' => 'gürcü',
 			'Glag' => 'qlaqolitik',
 			'Goth' => 'qotik',
 			'Grek' => 'yunan',
 			'Gujr' => 'qucarat',
 			'Guru' => 'qurmuxi',
 			'Hang' => 'hanqıl',
 			'Hani' => 'han',
 			'Hano' => 'hanunu',
 			'Hans' => 'sadələşmiş',
 			'Hans@alt=stand-alone' => 'Sadələşdirilmiş Han',
 			'Hant' => 'ənənəvi',
 			'Hant@alt=stand-alone' => 'Ənənəvi Han',
 			'Hebr' => 'ibrani',
 			'Hira' => 'iraqana',
 			'Hmng' => 'pahav monq',
 			'Hrkt' => 'katakana vəya hiraqana',
 			'Hung' => 'qədimi macar',
 			'Inds' => 'hindistan',
 			'Ital' => 'qədimi italyalı',
 			'Java' => 'cava',
 			'Jpan' => 'yapon',
 			'Kali' => 'kayax li',
 			'Kana' => 'katakana',
 			'Khar' => 'xaroşti',
 			'Khmr' => 'kxmer',
 			'Knda' => 'kannada',
 			'Kore' => 'koreya',
 			'Kthi' => 'kti',
 			'Lana' => 'lanna',
 			'Laoo' => 'lao',
 			'Latf' => 'fraktur latını',
 			'Latg' => 'gael latını',
 			'Latn' => 'latın',
 			'Lepc' => 'lepçə',
 			'Limb' => 'limbu',
 			'Lyci' => 'lusian',
 			'Lydi' => 'ludian',
 			'Mand' => 'mandayen',
 			'Mani' => 'maniçayen',
 			'Maya' => 'maya hiyeroqlifi',
 			'Mero' => 'meroytik',
 			'Mlym' => 'malayalam',
 			'Mong' => 'monqol',
 			'Moon' => 'mun',
 			'Mtei' => 'meytey mayek',
 			'Mymr' => 'myanmar',
 			'Nkoo' => 'nko',
 			'Ogam' => 'oğam',
 			'Olck' => 'ol çiki',
 			'Orkh' => 'orxon',
 			'Orya' => 'oriya',
 			'Osma' => 'osmanya',
 			'Perm' => 'qədimi permik',
 			'Phag' => 'faqs-pa',
 			'Phli' => 'fli',
 			'Phlp' => 'flp',
 			'Phlv' => 'kitab paxlavi',
 			'Phnx' => 'foenik',
 			'Plrd' => 'polard fonetik',
 			'Prti' => 'prti',
 			'Rjng' => 'recəng',
 			'Roro' => 'ronqoronqo',
 			'Runr' => 'runik',
 			'Samr' => 'samaritan',
 			'Sara' => 'sarati',
 			'Saur' => 'saurastra',
 			'Sgnw' => 'işarət yazısı',
 			'Shaw' => 'şavyan',
 			'Sinh' => 'sinhal',
 			'Sund' => 'sundan',
 			'Sylo' => 'siloti nəqri',
 			'Syrc' => 'siryak',
 			'Syre' => 'estrangela süryanice',
 			'Tagb' => 'taqbanva',
 			'Tale' => 'tay le',
 			'Talu' => 'təzə tay lu',
 			'Taml' => 'tamil',
 			'Tavt' => 'tavt',
 			'Telu' => 'teluqu',
 			'Teng' => 'tengvar',
 			'Tfng' => 'tifinaq',
 			'Tglg' => 'taqaloq',
 			'Thaa' => 'thana',
 			'Thai' => 'tay',
 			'Tibt' => 'tibet',
 			'Ugar' => 'uqarit',
 			'Vaii' => 'vay',
 			'Visp' => 'danışma səsləri',
 			'Xpeo' => 'qədimi fars',
 			'Xsux' => 'sumer-akadyan kuneyform',
 			'Yiii' => 'yi',
 			'Zmth' => 'zmth',
 			'Zsym' => 'simvollar',
 			'Zxxx' => 'yazısız',
 			'Zyyy' => 'ümumi yazı',
 			'Zzzz' => 'naməlum skript',

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
			'001' => 'Dünya',
 			'002' => 'Afrika',
 			'003' => 'Şimali Amerika',
 			'005' => 'Cənubi Amerika',
 			'009' => 'Okeaniya',
 			'011' => 'Qərbi Afrika',
 			'013' => 'Mərkəzi Amerika',
 			'014' => 'Şərqi Afrika',
 			'015' => 'Şimali Afrika',
 			'017' => 'Mərkəzi Afrika',
 			'018' => 'Cənubi Afrika',
 			'019' => 'Amerikalar',
 			'021' => 'Şimal Amerikası',
 			'029' => 'Karib',
 			'030' => 'Şərqi Asiya',
 			'034' => 'Cənubi Asiya',
 			'035' => 'Cənub-Şərqi Asiya',
 			'039' => 'Cənubi Avropa',
 			'053' => 'Avstralaziya',
 			'054' => 'Melaneziya',
 			'057' => 'Mikroneziya Regionu',
 			'061' => 'Polineziya',
 			'142' => 'Asiya',
 			'143' => 'Mərkəzi Asiya',
 			'145' => 'Qərbi Asiya',
 			'150' => 'Avropa',
 			'151' => 'Şərqi Avropa',
 			'154' => 'Şimali Avropa',
 			'155' => 'Qərbi Avropa',
 			'419' => 'Latın Amerikası',
 			'AC' => 'Yüksəliş Adası',
 			'AD' => 'Andorra',
 			'AE' => 'Birləşmiş Ərəb Əmirlikləri',
 			'AF' => 'Əfqanıstan',
 			'AG' => 'Antiqua və Barbuda',
 			'AI' => 'Angila',
 			'AL' => 'Albaniya',
 			'AM' => 'Ermənistan',
 			'AO' => 'Anqola',
 			'AQ' => 'Antarktika',
 			'AR' => 'Argentina',
 			'AS' => 'Amerika Samoası',
 			'AT' => 'Avstriya',
 			'AU' => 'Avstraliya',
 			'AW' => 'Aruba',
 			'AX' => 'Aland Adaları',
 			'AZ' => 'Azərbaycan',
 			'BA' => 'Bosniya və Hersoqovina',
 			'BB' => 'Barbados',
 			'BD' => 'Banqladeş',
 			'BE' => 'Belçika',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bolqariya',
 			'BH' => 'Bəhreyn',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'San Bartolomey',
 			'BM' => 'Bermuda',
 			'BN' => 'Bruney',
 			'BO' => 'Boliviya',
 			'BQ' => 'Karib Niderlandı',
 			'BR' => 'Braziliya',
 			'BS' => 'Baham Adaları',
 			'BT' => 'Butan',
 			'BV' => 'Buve Adası',
 			'BW' => 'Botsvana',
 			'BY' => 'Belarus',
 			'BZ' => 'Beliz',
 			'CA' => 'Kanada',
 			'CC' => 'Kokos Adaları',
 			'CD' => 'Konqo - Kinşasa',
 			'CD@alt=variant' => 'Konqo (KDR)',
 			'CF' => 'Mərkəzi Afrika Respublikası',
 			'CG' => 'Konqo - Brazzavil',
 			'CG@alt=variant' => 'Konqo (Respublika)',
 			'CH' => 'İsveçrə',
 			'CI' => 'Fil Dişi Sahili',
 			'CK' => 'Kuk Adaları',
 			'CL' => 'Çili',
 			'CM' => 'Kamerun',
 			'CN' => 'Çin',
 			'CO' => 'Kolumbiya',
 			'CP' => 'Klipperton Adası',
 			'CR' => 'Kosta Rika',
 			'CU' => 'Kuba',
 			'CV' => 'Kape Verde',
 			'CW' => 'Kurasao',
 			'CX' => 'Milad Adası',
 			'CY' => 'Kipr',
 			'CZ' => 'Çexiya',
 			'DE' => 'Almaniya',
 			'DG' => 'Dieqo Qarsiya',
 			'DJ' => 'Cibuti',
 			'DK' => 'Danimarka',
 			'DM' => 'Dominika',
 			'DO' => 'Dominikan Respublikası',
 			'DZ' => 'Əlcəzair',
 			'EA' => 'Seuta və Melilya',
 			'EC' => 'Ekvador',
 			'EE' => 'Estoniya',
 			'EG' => 'Misir',
 			'EH' => 'Qərbi Sahara',
 			'ER' => 'Eritreya',
 			'ES' => 'İspaniya',
 			'ET' => 'Efiopiya',
 			'EU' => 'Avropa Birliyi',
 			'FI' => 'Finlandiya',
 			'FJ' => 'Fici',
 			'FK' => 'Folklend Adaları',
 			'FK@alt=variant' => 'Folklend Adaları (Malvin Adaları)',
 			'FM' => 'Mikroneziya',
 			'FO' => 'Farer Adaları',
 			'FR' => 'Fransa',
 			'GA' => 'Qabon',
 			'GB' => 'Birləşmiş Krallıq',
 			'GB@alt=short' => 'B.K.',
 			'GD' => 'Qrenada',
 			'GE' => 'Gürcüstan',
 			'GF' => 'Fransız Qviyanası',
 			'GG' => 'Gernsey',
 			'GH' => 'Qana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Qrenlandiya',
 			'GM' => 'Qambiya',
 			'GN' => 'Qvineya',
 			'GP' => 'Qvadelupa',
 			'GQ' => 'Ekvatorial Qvineya',
 			'GR' => 'Yunanıstan',
 			'GS' => 'Cənubi Corciya və Cənubi Sendviç Adaları',
 			'GT' => 'Qvatemala',
 			'GU' => 'Quam',
 			'GW' => 'Qvineya-Bisau',
 			'GY' => 'Qviyana',
 			'HK' => 'Honq Konq Xüsusi İnzibati Ərazi Çin',
 			'HK@alt=short' => 'Honq Konq',
 			'HM' => 'Herd və Mak Donald Adaları',
 			'HN' => 'Honduras',
 			'HR' => 'Xorvatiya',
 			'HT' => 'Haiti',
 			'HU' => 'Macarıstan',
 			'IC' => 'Kanar Adaları',
 			'ID' => 'İndoneziya',
 			'IE' => 'İrlandiya',
 			'IL' => 'İsrail',
 			'IM' => 'Men Adası',
 			'IN' => 'Hindistan',
 			'IO' => 'Britaniya Hind Okeanı Ərazisi',
 			'IQ' => 'İraq',
 			'IR' => 'İran',
 			'IS' => 'İslandiya',
 			'IT' => 'İtaliya',
 			'JE' => 'Cersi',
 			'JM' => 'Yamayka',
 			'JO' => 'İordaniya',
 			'JP' => 'Yaponiya',
 			'KE' => 'Keniya',
 			'KG' => 'Qırğızıstan',
 			'KH' => 'Kamboca',
 			'KI' => 'Kiribati',
 			'KM' => 'Komor Adaları',
 			'KN' => 'San Kits və Nevis',
 			'KP' => 'Şimali Koreya',
 			'KR' => 'Cənubi Koreya',
 			'KW' => 'Küveyt',
 			'KY' => 'Kayman Adaları',
 			'KZ' => 'Qazaxıstan',
 			'LA' => 'Laos',
 			'LB' => 'Livan',
 			'LC' => 'San Lüsiya',
 			'LI' => 'Lixtenşteyn',
 			'LK' => 'Şri Lanka',
 			'LR' => 'Liberiya',
 			'LS' => 'Lesoto',
 			'LT' => 'Litva',
 			'LU' => 'Lüksemburq',
 			'LV' => 'Latviya',
 			'LY' => 'Liviya',
 			'MA' => 'Mərakeş',
 			'MC' => 'Monako',
 			'MD' => 'Moldova',
 			'ME' => 'Monteneqro',
 			'MF' => 'San Martin',
 			'MG' => 'Madaqaskar',
 			'MH' => 'Marşal Adaları',
 			'MK' => 'Makedoniya',
 			'MK@alt=variant' => 'Makedoniya (FYROM)',
 			'ML' => 'Mali',
 			'MM' => 'Myanma',
 			'MN' => 'Monqoliya',
 			'MO' => 'Makao Xüsusi İnzibati Ərazi Çin',
 			'MO@alt=short' => 'Makao',
 			'MP' => 'Şimali Mariana Adaları',
 			'MQ' => 'Martinik',
 			'MR' => 'Mavritaniya',
 			'MS' => 'Monserat',
 			'MT' => 'Malta',
 			'MU' => 'Mavriki',
 			'MV' => 'Maldiv Adaları',
 			'MW' => 'Malavi',
 			'MX' => 'Meksika',
 			'MY' => 'Malayziya',
 			'MZ' => 'Mozambik',
 			'NA' => 'Namibiya',
 			'NC' => 'Yeni Kaledoniya',
 			'NE' => 'Niger',
 			'NF' => 'Norfolk Adası',
 			'NG' => 'Nigeriya',
 			'NI' => 'Nikaraqua',
 			'NL' => 'Niderland',
 			'NO' => 'Norveç',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Yeni Zelandiya',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Fransız Polineziyası',
 			'PG' => 'Papua Yeni Qvineya',
 			'PH' => 'Filippin',
 			'PK' => 'Pakistan',
 			'PL' => 'Polşa',
 			'PM' => 'San Pier və Mikelon',
 			'PN' => 'Pitkern Adaları',
 			'PR' => 'Puerto Riko',
 			'PS' => 'Fələstin Əraziləri',
 			'PS@alt=short' => 'Fələstin',
 			'PT' => 'Portuqal',
 			'PW' => 'Palau',
 			'PY' => 'Paraqvay',
 			'QA' => 'Qatar',
 			'QO' => 'Uzaq Okeaniya',
 			'RE' => 'Reunion',
 			'RO' => 'Rumıniya',
 			'RS' => 'Serbiya',
 			'RU' => 'Rusiya',
 			'RW' => 'Ruanda',
 			'SA' => 'Səudiyyə Ərəbistanı',
 			'SB' => 'Solomon Adaları',
 			'SC' => 'Seyşel Adaları',
 			'SD' => 'Sudan',
 			'SE' => 'İsveç',
 			'SG' => 'Sinqapur',
 			'SH' => 'Müqəddəs Yelena',
 			'SI' => 'Sloveniya',
 			'SJ' => 'Svalbard və Yan Mayen',
 			'SK' => 'Slovakiya',
 			'SL' => 'Siera Leon',
 			'SM' => 'San Marino',
 			'SN' => 'Seneqal',
 			'SO' => 'Somali',
 			'SR' => 'Surinam',
 			'SS' => 'Cənubi Sudan',
 			'ST' => 'Sao Tome və Prinsip',
 			'SV' => 'Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Suriya',
 			'SZ' => 'Svazilend',
 			'TA' => 'Tristan da Kunya',
 			'TC' => 'Turks və Kaikos Adaları',
 			'TD' => 'Çad',
 			'TF' => 'Fransa Cənub Əraziləri',
 			'TG' => 'Toqo',
 			'TH' => 'Tayland',
 			'TJ' => 'Tacikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Şərqi Timor',
 			'TL@alt=variant' => 'Doğu Timor',
 			'TM' => 'Türkmənistan',
 			'TN' => 'Tunis',
 			'TO' => 'Tonqa',
 			'TR' => 'Türkiya',
 			'TT' => 'Trinidad və Tobaqo',
 			'TV' => 'Tuvalu',
 			'TW' => 'Tayvan',
 			'TZ' => 'Tanzaniya',
 			'UA' => 'Ukrayna',
 			'UG' => 'Uqanda',
 			'UM' => 'Birləşmiş Ştatlar Uzaq Adalar',
 			'US' => 'Amerika Birləşmiş Ştatları',
 			'US@alt=short' => 'A.B.Ş.',
 			'UY' => 'Uruqvay',
 			'UZ' => 'Özbəkistan',
 			'VA' => 'Vatikan',
 			'VC' => 'San Vinsent və Qrenada',
 			'VE' => 'Venesuela',
 			'VG' => 'Britaniya Vircin Adaları',
 			'VI' => 'ABŞ Vircin Adaları',
 			'VN' => 'Vyetnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Uolis və Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'Yəmən',
 			'YT' => 'Mayot',
 			'ZA' => 'Cənub Afrika',
 			'ZM' => 'Zambiya',
 			'ZW' => 'Zimbabve',
 			'ZZ' => 'Naməlum Region',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'Təqvim',
 			'collation' => 'Çeşidləmə',
 			'currency' => 'Valyuta',
 			'hc' => 'Saat Sikli (12 / 24)',
 			'lb' => 'Sətirdən sətrə keçirmə üslubu',
 			'ms' => 'Ölçü Sistemi',
 			'numbers' => 'Rəqəmlər',

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
 				'buddhist' => q{Buddist Təqvimi},
 				'chinese' => q{Çin Təqvimi},
 				'dangi' => q{Dangi Təqvimi},
 				'ethiopic' => q{Efiop Təqvimi},
 				'gregorian' => q{Qreqorian Təqvimi},
 				'hebrew' => q{Yəhudi Təqvimi},
 				'indian' => q{Hindi təqvimi},
 				'islamic' => q{İslam Təqvimi},
 				'islamic-civil' => q{Ivrit təqvimi},
 				'iso8601' => q{ISO-8601 Təqvimi},
 				'japanese' => q{Yapon Təqvimi},
 				'persian' => q{İran Təqvimi},
 				'roc' => q{Minquo Təqvimi},
 			},
 			'collation' => {
 				'ducet' => q{Defolt Unicode Çeşidləmə},
 				'pinyin' => q{Pinyin təqvimi},
 				'search' => q{Ümumi Məqsədli Axtarış},
 				'standard' => q{Standart Çeşidləmə},
 			},
 			'hc' => {
 				'h11' => q{12 Saatlıq Sistem (0–11)},
 				'h12' => q{12 Saatlıq Sistem (0–12)},
 				'h23' => q{24 Saatlıq Sistem (0–23)},
 				'h24' => q{24 Saatlıq Sistem (0–23)},
 			},
 			'lb' => {
 				'loose' => q{Sərbəst sətirdən sətrə keçirmə üslubu},
 				'normal' => q{Normal sətirdən sətrə keçirmə üslubu},
 				'strict' => q{Sərt sətirdən sətrə keçirmə üslubu},
 			},
 			'ms' => {
 				'metric' => q{Metrik Sistem},
 				'uksystem' => q{İmperial Ölçü Sistemi},
 				'ussystem' => q{ABŞ Ölçü Sistemi},
 			},
 			'numbers' => {
 				'arab' => q{Ərəb-Hind Rəqəmləri},
 				'arabext' => q{Genişlənmiş Ərəb-Hind Rəqəmləri},
 				'armn' => q{Erməni Rəqəmləri},
 				'armnlow' => q{Kiçik Erməni Rəqəmləri},
 				'beng' => q{Benqal Rəqəmləri},
 				'deva' => q{Devanaqari Rəqəmləri},
 				'ethi' => q{Efiop Rəqəmləri},
 				'fullwide' => q{Tam Geniş Rəqəmlər},
 				'geor' => q{Gürcü Rəqəmləri},
 				'grek' => q{Yunan Rəqəmləri},
 				'greklow' => q{Kiçik Yunan Rəqəmləri},
 				'gujr' => q{Qucarat Rəqəmləri},
 				'guru' => q{Qurmuxi Rəqəmləri},
 				'hanidec' => q{Onluq Çin Rəqəmləri},
 				'hans' => q{Sadələşmiş Çin Rəqəmləri},
 				'hansfin' => q{Sadələşmiş Çin Maliyyə Rəqəmləri},
 				'hant' => q{Ənənəvi Çin Rəqəmləri},
 				'hantfin' => q{Ənənəvi Çin Maliyyə Rəqəmləri},
 				'hebr' => q{İvrit Rəqəmləri},
 				'jpan' => q{Yapon Rəqəmləri},
 				'jpanfin' => q{Yapon Maliyyə Rəqəmləri},
 				'khmr' => q{Kxmer Rəqəmləri},
 				'knda' => q{Kannada Rəqəmləri},
 				'laoo' => q{Lao Rəqəmləri},
 				'latn' => q{Qərb Rəqəmləri},
 				'mlym' => q{Malayalam Rəqəmləri},
 				'mymr' => q{Myanma Rəqəmləri},
 				'orya' => q{Oriya Rəqəmləri},
 				'roman' => q{Rum Rəqəmləri},
 				'romanlow' => q{Kiçik Rum Rəqəmləri},
 				'taml' => q{Ənənəvi Tamil Rəqəmləri},
 				'tamldec' => q{Tamil Rəqəmləri},
 				'telu' => q{Teluqu Rəqəmləri},
 				'thai' => q{Tay Rəqəmləri},
 				'tibt' => q{Tibet Rəqəmləri},
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
			'metric' => q{Metrik},
 			'UK' => q{Britaniya},
 			'US' => q{ABŞ},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Dil: {0}',
 			'script' => 'Skript: {0}',
 			'region' => 'Region: {0}',

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
			auxiliary => qr{(?^u:[w])},
			index => ['A', 'B', 'C', 'Ç', 'D', 'E', 'Ə', 'F', 'G', 'Ğ', 'H', 'X', 'I', 'İ', 'J', 'K', 'Q', 'L', 'M', 'N', 'O', 'Ö', 'P', 'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'Y', 'Z', 'W'],
			main => qr{(?^u:[a b c ç d e ə f g ğ h x ı i İ j k q l m n o ö p r s ş t u ü v y z])},
			punctuation => qr{(?^u:[\- ‐ – — , ; \: ! ? . … ' ‘ ’ " “ ” ( ) \[ \] § @ * / \& # † ‡ ′ ″])},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'Ç', 'D', 'E', 'Ə', 'F', 'G', 'Ğ', 'H', 'X', 'I', 'İ', 'J', 'K', 'Q', 'L', 'M', 'N', 'O', 'Ö', 'P', 'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'Y', 'Z', 'W'], };
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
					'acre' => {
						'name' => q(akr),
						'one' => q({0} akr),
						'other' => q({0} akr),
					},
					'acre-foot' => {
						'name' => q(akr-fut),
						'one' => q({0} akr-fut),
						'other' => q({0} akr-fut),
					},
					'ampere' => {
						'name' => q(amper),
						'one' => q({0} amper),
						'other' => q({0} amper),
					},
					'arc-minute' => {
						'name' => q(dəqiqə),
						'one' => q({0} dəqiqə),
						'other' => q({0} dəqiqə),
					},
					'arc-second' => {
						'name' => q(saniyə),
						'one' => q({0} saniyə),
						'other' => q({0} saniyə),
					},
					'astronomical-unit' => {
						'name' => q(astronomik vahid),
						'one' => q({0} astronomik vahid),
						'other' => q({0} astronomik vahid),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(bayt),
						'one' => q({0} bayt),
						'other' => q({0} bayt),
					},
					'calorie' => {
						'name' => q(kalori),
						'one' => q({0} kalori),
						'other' => q({0} kalori),
					},
					'carat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					'celsius' => {
						'name' => q(dərəcə Selsi),
						'one' => q({0} dərəcə Selsi),
						'other' => q({0} dərəcə Selsi),
					},
					'centiliter' => {
						'name' => q(santilitr),
						'one' => q({0} santilitr),
						'other' => q({0} santilitr),
					},
					'centimeter' => {
						'name' => q(santimetr),
						'one' => q({0} santimetr),
						'other' => q({0} santimetr),
						'per' => q({0}/sm),
					},
					'century' => {
						'name' => q(əsr),
						'one' => q({0} əsr),
						'other' => q({0} əsr),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					'cubic-centimeter' => {
						'name' => q(kub santimetr),
						'one' => q({0} kub santimetr),
						'other' => q({0} kub santimetr),
						'per' => q({0}/sm³),
					},
					'cubic-foot' => {
						'name' => q(kub fut),
						'one' => q({0} kub fut),
						'other' => q({0} kub fut),
					},
					'cubic-inch' => {
						'name' => q(kub düym),
						'one' => q({0} kub düym),
						'other' => q({0} kub düym),
					},
					'cubic-kilometer' => {
						'name' => q(kub kilometr),
						'one' => q({0} kub kilometr),
						'other' => q({0} kub kilometr),
					},
					'cubic-meter' => {
						'name' => q(kub metr),
						'one' => q({0} kub metr),
						'other' => q({0} kub metr),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(kub mil),
						'one' => q({0} kub mil),
						'other' => q({0} kub mil),
					},
					'cubic-yard' => {
						'name' => q(kub yard),
						'one' => q({0} kub yard),
						'other' => q({0} kub yard),
					},
					'cup' => {
						'name' => q(stəkan),
						'one' => q({0} stəkan),
						'other' => q({0} stəkan),
					},
					'cup-metric' => {
						'name' => q(mcup),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					'day' => {
						'name' => q(gün),
						'one' => q({0} gün),
						'other' => q({0} gün),
						'per' => q({0}/gün),
					},
					'deciliter' => {
						'name' => q(desilitr),
						'one' => q({0} desilitr),
						'other' => q({0} desilitr),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(dərəcə),
						'one' => q({0} dərəcə),
						'other' => q({0} dərəcə),
					},
					'fahrenheit' => {
						'name' => q(dərəcə Farengeyt),
						'one' => q({0} dərəcə Farengeyt),
						'other' => q({0} dərəcə Farengeyt),
					},
					'fluid-ounce' => {
						'name' => q(maye unsiyası),
						'one' => q({0} maye unsiyası),
						'other' => q({0} maye unsiyası),
					},
					'foodcalorie' => {
						'name' => q(Kalori),
						'one' => q({0} Kalori),
						'other' => q({0} Kalori),
					},
					'foot' => {
						'name' => q(fut),
						'one' => q({0} fut),
						'other' => q({0} fut),
						'per' => q({0}/ft),
					},
					'g-force' => {
						'name' => q(g qüvvəsi),
						'one' => q({0} g qüvvəsi),
						'other' => q({0} g qüvvəsi),
					},
					'gallon' => {
						'name' => q(qallon),
						'one' => q({0} qallon),
						'other' => q({0} qallon),
						'per' => q({0}/qal),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(giqabit),
						'one' => q({0} giqabit),
						'other' => q({0} giqabit),
					},
					'gigabyte' => {
						'name' => q(giqabayt),
						'one' => q({0} giqabayt),
						'other' => q({0} giqabayt),
					},
					'gigahertz' => {
						'name' => q(giqahers),
						'one' => q({0} giqahers),
						'other' => q({0} giqahers),
					},
					'gigawatt' => {
						'name' => q(giqavatt),
						'one' => q({0} giqavatt),
						'other' => q({0} giqavatt),
					},
					'gram' => {
						'name' => q(qram),
						'one' => q({0} qram),
						'other' => q({0} qram),
						'per' => q({0}/q),
					},
					'hectare' => {
						'name' => q(hektar),
						'one' => q({0} hektar),
						'other' => q({0} hektar),
					},
					'hectoliter' => {
						'name' => q(hektolitr),
						'one' => q({0} hektolitr),
						'other' => q({0} hektolitr),
					},
					'hectopascal' => {
						'name' => q(hektopaskal),
						'one' => q({0} hektopaskal),
						'other' => q({0} hektopaskal),
					},
					'hertz' => {
						'name' => q(hers),
						'one' => q({0} hers),
						'other' => q({0} hers),
					},
					'horsepower' => {
						'name' => q(at gücü),
						'one' => q({0} at gücü),
						'other' => q({0} at gücü),
					},
					'hour' => {
						'name' => q(saat),
						'one' => q({0} saat),
						'other' => q({0} saat),
						'per' => q({0}/saat),
					},
					'inch' => {
						'name' => q(düym),
						'one' => q({0} düym),
						'other' => q({0} düym),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(civə düymü),
						'one' => q({0} civə düymü),
						'other' => q({0} civə düymü),
					},
					'joule' => {
						'name' => q(coul),
						'one' => q({0} coul),
						'other' => q({0} coul),
					},
					'karat' => {
						'name' => q(karat),
						'one' => q({0} karat),
						'other' => q({0} karat),
					},
					'kelvin' => {
						'name' => q(dərəcə Kelvin),
						'one' => q({0} dərəcə Kelvin),
						'other' => q({0} dərəcə Kelvin),
					},
					'kilobit' => {
						'name' => q(kilobit),
						'one' => q({0} kilobit),
						'other' => q({0} kilobit),
					},
					'kilobyte' => {
						'name' => q(kilobayt),
						'one' => q({0} kilobayt),
						'other' => q({0} kilobayt),
					},
					'kilocalorie' => {
						'name' => q(kilokalori),
						'one' => q({0} kilokalori),
						'other' => q({0} kilokalori),
					},
					'kilogram' => {
						'name' => q(kiloqram),
						'one' => q({0} kiloqram),
						'other' => q({0} kiloqram),
						'per' => q({0}/kq),
					},
					'kilohertz' => {
						'name' => q(kilohers),
						'one' => q({0} kilohers),
						'other' => q({0} kilohers),
					},
					'kilojoule' => {
						'name' => q(kilocoul),
						'one' => q({0} kilocoul),
						'other' => q({0} kilocoul),
					},
					'kilometer' => {
						'name' => q(kilometr),
						'one' => q({0} kilometr),
						'other' => q({0} kilometr),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(kilometr/saat),
						'one' => q({0} kilometr/saat),
						'other' => q({0} kilometr/saat),
					},
					'kilowatt' => {
						'name' => q(kilovatt),
						'one' => q({0} kilovatt),
						'other' => q({0} kilovatt),
					},
					'kilowatt-hour' => {
						'name' => q(kilovatt-saat),
						'one' => q({0} kilovatt-saat),
						'other' => q({0} kilovatt-saat),
					},
					'knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'name' => q(işıq ili),
						'one' => q({0} işıq ili),
						'other' => q({0} işıq ili),
					},
					'liter' => {
						'name' => q(litr),
						'one' => q({0} litr),
						'other' => q({0} litr),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					'liter-per-kilometer' => {
						'name' => q(litr/kilometr),
						'one' => q({0} litr/kilometr),
						'other' => q({0} litr/kilometr),
					},
					'lux' => {
						'name' => q(lüks),
						'one' => q({0} lüks),
						'other' => q({0} lüks),
					},
					'megabit' => {
						'name' => q(meqabit),
						'one' => q({0} meqabit),
						'other' => q({0} meqabit),
					},
					'megabyte' => {
						'name' => q(meqabayt),
						'one' => q({0} meqabayt),
						'other' => q({0} meqabayt),
					},
					'megahertz' => {
						'name' => q(meqahers),
						'one' => q({0} meqahers),
						'other' => q({0} meqahers),
					},
					'megaliter' => {
						'name' => q(meqalitr),
						'one' => q({0} meqalitr),
						'other' => q({0} meqalitr),
					},
					'megawatt' => {
						'name' => q(meqavatt),
						'one' => q({0} meqavatt),
						'other' => q({0} meqavatt),
					},
					'meter' => {
						'name' => q(metr),
						'one' => q({0} metr),
						'other' => q({0} metr),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(metr/saniyə),
						'one' => q({0} metr/saniyə),
						'other' => q({0} metr/saniyə),
					},
					'meter-per-second-squared' => {
						'name' => q(metr saniyə kvadratı),
						'one' => q({0} metr saniyə kvadratı),
						'other' => q({0} metr saniyə kvadratı),
					},
					'metric-ton' => {
						'name' => q(metrik ton),
						'one' => q({0} metrik ton),
						'other' => q({0} metrik ton),
					},
					'microgram' => {
						'name' => q(mikroqram),
						'one' => q({0} mikroqram),
						'other' => q({0} mikroqram),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(mikrosaniyə),
						'one' => q({0} mikrosaniyə),
						'other' => q({0} mikrosaniyə),
					},
					'mile' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					'mile-per-gallon' => {
						'name' => q(mil/qallon),
						'one' => q({0} mil/qallon),
						'other' => q({0} mil/qallon),
					},
					'mile-per-hour' => {
						'name' => q(mil/saat),
						'one' => q({0} mil/saat),
						'other' => q({0} mil/saat),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(milliamper),
						'one' => q({0} milliamper),
						'other' => q({0} milliamper),
					},
					'millibar' => {
						'name' => q(millibar),
						'one' => q({0} millibar),
						'other' => q({0} millibar),
					},
					'milligram' => {
						'name' => q(milliqram),
						'one' => q({0} milliqram),
						'other' => q({0} milliqram),
					},
					'milliliter' => {
						'name' => q(millilitr),
						'one' => q({0} millilitr),
						'other' => q({0} millilitr),
					},
					'millimeter' => {
						'name' => q(millimetr),
						'one' => q({0} millimetr),
						'other' => q({0} millimetr),
					},
					'millimeter-of-mercury' => {
						'name' => q(millimetr civə sütunu),
						'one' => q({0} millimetr civə sütunu),
						'other' => q({0} millimetr civə sütunu),
					},
					'millisecond' => {
						'name' => q(millisaniyə),
						'one' => q({0} millisaniyə),
						'other' => q({0} millisaniyə),
					},
					'milliwatt' => {
						'name' => q(millivatt),
						'one' => q({0} millivatt),
						'other' => q({0} millivatt),
					},
					'minute' => {
						'name' => q(dəqiqə),
						'one' => q({0} dəqiqə),
						'other' => q({0} dəqiqə),
						'per' => q({0}/dəqiqə),
					},
					'month' => {
						'name' => q(ay),
						'one' => q({0} ay),
						'other' => q({0} ay),
						'per' => q({0}/ay),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(nanosaniyə),
						'one' => q({0} nanosaniyə),
						'other' => q({0} nanosaniyə),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'name' => q(om),
						'one' => q({0} om),
						'other' => q({0} om),
					},
					'ounce' => {
						'name' => q(unsiya),
						'one' => q({0} unsiya),
						'other' => q({0} unsiya),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(troy unsiyası),
						'one' => q({0} troy unsiyası),
						'other' => q({0} troy unsiyası),
					},
					'parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pikometr),
						'one' => q({0} pikometr),
						'other' => q({0} pikometr),
					},
					'pint' => {
						'name' => q(pint),
						'one' => q({0} pint),
						'other' => q({0} pint),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'pound' => {
						'name' => q(funt),
						'one' => q({0} funt),
						'other' => q({0} funt),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(funt/kvadrat düym),
						'one' => q({0} funt/kvadrat düym),
						'other' => q({0} funt/kvadrat düym),
					},
					'quart' => {
						'name' => q(kvart),
						'one' => q({0} kvart),
						'other' => q({0} kvart),
					},
					'radian' => {
						'name' => q(radian),
						'one' => q({0} radian),
						'other' => q({0} radian),
					},
					'revolution' => {
						'name' => q(dövrə),
						'one' => q({0} dövrə),
						'other' => q({0} dövrə),
					},
					'second' => {
						'name' => q(saniyə),
						'one' => q({0} saniyə),
						'other' => q({0} saniyə),
						'per' => q({0}/saniyə),
					},
					'square-centimeter' => {
						'name' => q(kvadrat santimetr),
						'one' => q({0} kvadrat santimetr),
						'other' => q({0} kvadrat santimetr),
						'per' => q({0}/sm²),
					},
					'square-foot' => {
						'name' => q(kvadrat fut),
						'one' => q({0} kvadrat fut),
						'other' => q({0} kvadrat fut),
					},
					'square-inch' => {
						'name' => q(kvadrat düym),
						'one' => q({0} kvadrat düym),
						'other' => q({0} kvadrat düym),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'name' => q(kvadrat kilometr),
						'one' => q({0} kvadrat kilometr),
						'other' => q({0} kvadrat kilometr),
					},
					'square-meter' => {
						'name' => q(kvadrat metr),
						'one' => q({0} kvadrat metr),
						'other' => q({0} kvadrat metr),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(kvadrat mil),
						'one' => q({0} kvadrat mil),
						'other' => q({0} kvadrat mil),
					},
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'stone' => {
						'name' => q(stone),
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					'tablespoon' => {
						'name' => q(xörək qaşığı),
						'one' => q({0} xörək qaşığı),
						'other' => q({0} xörək qaşığı),
					},
					'teaspoon' => {
						'name' => q(çay qaşığı),
						'one' => q({0} çay qaşığı),
						'other' => q({0} çay qaşığı),
					},
					'terabit' => {
						'name' => q(terabit),
						'one' => q({0} terabit),
						'other' => q({0} terabit),
					},
					'terabyte' => {
						'name' => q(terabayt),
						'one' => q({0} terabayt),
						'other' => q({0} terabayt),
					},
					'ton' => {
						'name' => q(ton),
						'one' => q({0} ton),
						'other' => q({0} ton),
					},
					'volt' => {
						'name' => q(volt),
						'one' => q({0} volt),
						'other' => q({0} volt),
					},
					'watt' => {
						'name' => q(vatt),
						'one' => q({0} vatt),
						'other' => q({0} vatt),
					},
					'week' => {
						'name' => q(həftə),
						'one' => q({0} həftə),
						'other' => q({0} həftə),
						'per' => q({0}/həftə),
					},
					'yard' => {
						'name' => q(yard),
						'one' => q({0} yard),
						'other' => q({0} yard),
					},
					'year' => {
						'name' => q(il),
						'one' => q({0} il),
						'other' => q({0} il),
						'per' => q({0}/il),
					},
				},
				'narrow' => {
					'acre' => {
						'one' => q({0} ak),
						'other' => q({0} ak),
					},
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'centimeter' => {
						'name' => q(sm),
						'one' => q({0} sm),
						'other' => q({0} sm),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					'cubic-kilometer' => {
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-mile' => {
						'one' => q({0} mil³),
						'other' => q({0} mil³),
					},
					'day' => {
						'name' => q(gün),
						'one' => q({0} gün),
						'other' => q({0} gün),
					},
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'foot' => {
						'one' => q({0} ft),
						'other' => q({0} ft),
					},
					'g-force' => {
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gram' => {
						'name' => q(qram),
						'one' => q({0} q),
						'other' => q({0} q),
					},
					'hectare' => {
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectopascal' => {
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'horsepower' => {
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					'hour' => {
						'name' => q(saat),
						'one' => q({0} saat),
						'other' => q({0} saat),
					},
					'inch' => {
						'one' => q({0} in),
						'other' => q({0} in),
					},
					'inch-hg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'kilogram' => {
						'name' => q(kiloqram),
						'one' => q({0} kq),
						'other' => q({0} kq),
					},
					'kilometer' => {
						'name' => q(kilometr),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					'kilometer-per-hour' => {
						'name' => q(kilometr/saat),
						'one' => q({0} km/saat),
						'other' => q({0} km/saat),
					},
					'kilowatt' => {
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'light-year' => {
						'one' => q({0} ii),
						'other' => q({0} ii),
					},
					'liter' => {
						'name' => q(litr),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					'meter' => {
						'name' => q(metr),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'meter-per-second' => {
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'mile' => {
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					'mile-per-hour' => {
						'one' => q({0} mil/saat),
						'other' => q({0} mil/saat),
					},
					'millibar' => {
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					'millimeter' => {
						'name' => q(millimetr),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millisecond' => {
						'name' => q(msan),
						'one' => q({0} msan),
						'other' => q({0} msan),
					},
					'minute' => {
						'name' => q(dəq),
						'one' => q({0} dəq),
						'other' => q({0} dəq),
					},
					'month' => {
						'name' => q(ay),
						'one' => q({0} ay),
						'other' => q({0} ay),
					},
					'ounce' => {
						'one' => q({0} oz),
						'other' => q({0} oz),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pound' => {
						'one' => q({0} lb),
						'other' => q({0} lb),
					},
					'second' => {
						'name' => q(san),
						'one' => q({0} san),
						'other' => q({0} san),
					},
					'square-foot' => {
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-kilometer' => {
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					'square-meter' => {
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					'square-mile' => {
						'one' => q({0} mil²),
						'other' => q({0} mil²),
					},
					'stone' => {
						'name' => q(stone),
					},
					'watt' => {
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(hft),
						'one' => q({0} hft),
						'other' => q({0} hft),
					},
					'yard' => {
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(il),
						'one' => q({0} il),
						'other' => q({0} il),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(akr),
						'one' => q({0} ak),
						'other' => q({0} ak),
					},
					'acre-foot' => {
						'name' => q(ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'name' => q(amp),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(dəqiqə),
						'one' => q({0}dəq),
						'other' => q({0}dəq),
					},
					'arc-second' => {
						'name' => q(saniyə),
						'one' => q({0}san),
						'other' => q({0}san),
					},
					'astronomical-unit' => {
						'name' => q(av),
						'one' => q({0} av),
						'other' => q({0} av),
					},
					'bit' => {
						'name' => q(bit),
						'one' => q({0} bit),
						'other' => q({0} bit),
					},
					'byte' => {
						'name' => q(bayt),
						'one' => q({0} bayt),
						'other' => q({0} bayt),
					},
					'calorie' => {
						'name' => q(kal),
						'one' => q({0} kal),
						'other' => q({0} kal),
					},
					'carat' => {
						'name' => q(CD),
						'one' => q({0} CD),
						'other' => q({0} CD),
					},
					'celsius' => {
						'name' => q(dərəcə Selsi),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(sL),
						'one' => q({0} sL),
						'other' => q({0} sL),
					},
					'centimeter' => {
						'name' => q(sm),
						'one' => q({0} sm),
						'other' => q({0} sm),
						'per' => q({0}/sm),
					},
					'century' => {
						'name' => q(əsr),
						'one' => q({0} əsr),
						'other' => q({0} əsr),
					},
					'coordinate' => {
						'east' => q({0}E),
						'north' => q({0}N),
						'south' => q({0}S),
						'west' => q({0}W),
					},
					'cubic-centimeter' => {
						'name' => q(sm³),
						'one' => q({0} sm³),
						'other' => q({0} sm³),
						'per' => q({0}/sm³),
					},
					'cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'name' => q(kub mil),
						'one' => q({0} mil³),
						'other' => q({0} mil³),
					},
					'cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'cup-metric' => {
						'name' => q(mcup),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					'day' => {
						'name' => q(gün),
						'one' => q({0} gün),
						'other' => q({0} gün),
						'per' => q({0}/gün),
					},
					'deciliter' => {
						'name' => q(dL),
						'one' => q({0} dL),
						'other' => q({0} dL),
					},
					'decimeter' => {
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'name' => q(dərəcə),
						'one' => q({0}dər),
						'other' => q({0}dər),
					},
					'fahrenheit' => {
						'name' => q(dərəcə Farengeyt),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(Kal),
						'one' => q({0} Kal),
						'other' => q({0} Kal),
					},
					'foot' => {
						'name' => q(fut),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'g-force' => {
						'name' => q(g qüvvəsi),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(qal),
						'one' => q({0} qal),
						'other' => q({0} qal),
						'per' => q({0}/qal),
					},
					'generic' => {
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'gigabit' => {
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'name' => q(qram),
						'one' => q({0} q),
						'other' => q({0} q),
						'per' => q({0}/q),
					},
					'hectare' => {
						'name' => q(hektar),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					'hectopascal' => {
						'name' => q(hektopaskal),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'name' => q(at gücü),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					'hour' => {
						'name' => q(saat),
						'one' => q({0} saat),
						'other' => q({0} saat),
						'per' => q({0}/saat),
					},
					'inch' => {
						'name' => q(düym),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'name' => q(civə düymü),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'name' => q(coul),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'karat' => {
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'name' => q(kkal),
						'one' => q({0} kkal),
						'other' => q({0} kkal),
					},
					'kilogram' => {
						'name' => q(kiloqram),
						'one' => q({0} kq),
						'other' => q({0} kq),
						'per' => q({0}/kq),
					},
					'kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'name' => q(kc),
						'one' => q({0} kc),
						'other' => q({0} kc),
					},
					'kilometer' => {
						'name' => q(kilometr),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'name' => q(kilometr/saat),
						'one' => q({0} km/saat),
						'other' => q({0} km/saat),
					},
					'kilowatt' => {
						'name' => q(kilovatt),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'name' => q(işıq ili),
						'one' => q({0} ii),
						'other' => q({0} ii),
					},
					'liter' => {
						'name' => q(litr),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'name' => q(L/100km),
						'one' => q({0} L/100km),
						'other' => q({0} L/100km),
					},
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q({0} L/km),
						'other' => q({0} L/km),
					},
					'lux' => {
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'name' => q(ML),
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					'megawatt' => {
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'name' => q(metr),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'name' => q(metr/saniyə),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'microgram' => {
						'name' => q(µq),
						'one' => q({0} µq),
						'other' => q({0} µq),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μsan),
						'one' => q({0} μsan),
						'other' => q({0} μsan),
					},
					'mile' => {
						'name' => q(mil),
						'one' => q({0} mil),
						'other' => q({0} mil),
					},
					'mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-hour' => {
						'name' => q(mil/saat),
						'one' => q({0} mil/saat),
						'other' => q({0} mil/saat),
					},
					'mile-scandinavian' => {
						'name' => q(smi),
						'one' => q({0} smi),
						'other' => q({0} smi),
					},
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(millibar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'milligram' => {
						'name' => q(mq),
						'one' => q({0} mq),
						'other' => q({0} mq),
					},
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					'millimeter' => {
						'name' => q(millimetr),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millisecond' => {
						'name' => q(millisaniyə),
						'one' => q({0} msan),
						'other' => q({0} msan),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(dəqiqə),
						'one' => q({0} dəq),
						'other' => q({0} dəq),
						'per' => q({0}/dəq),
					},
					'month' => {
						'name' => q(ay),
						'one' => q({0} ay),
						'other' => q({0} ay),
						'per' => q({0}/ay),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(nsan),
						'one' => q({0} nsan),
						'other' => q({0} nsan),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'name' => q(om),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(unsiya),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'name' => q(pikometr),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'pound' => {
						'name' => q(funt),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'name' => q(döv),
						'one' => q({0} döv),
						'other' => q({0} döv),
					},
					'second' => {
						'name' => q(saniyə),
						'one' => q({0} san),
						'other' => q({0} san),
						'per' => q({0}/san),
					},
					'square-centimeter' => {
						'name' => q(sm²),
						'one' => q({0} sm²),
						'other' => q({0} sm²),
						'per' => q({0}/sm²),
					},
					'square-foot' => {
						'name' => q(kvadrat fut),
						'one' => q({0} kv ft),
						'other' => q({0} kv ft),
					},
					'square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'name' => q(kvadrat kilometr),
						'one' => q({0} kv km),
						'other' => q({0} kv km),
					},
					'square-meter' => {
						'name' => q(kvadrat metr),
						'one' => q({0} kv m),
						'other' => q({0} kv m),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'name' => q(kvadrat mil),
						'one' => q({0} kv mil),
						'other' => q({0} kv mil),
					},
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'stone' => {
						'name' => q(stone),
						'one' => q({0} stone),
						'other' => q({0} stone),
					},
					'tablespoon' => {
						'name' => q(xrqş),
						'one' => q({0} xrqş),
						'other' => q({0} xrqş),
					},
					'teaspoon' => {
						'name' => q(çyqş),
						'one' => q({0} çyqş),
						'other' => q({0} çyqş),
					},
					'terabit' => {
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'name' => q(tn),
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					'volt' => {
						'name' => q(volt),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(vatt),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(həftə),
						'one' => q({0} hft),
						'other' => q({0} hft),
						'per' => q({0}/hft),
					},
					'yard' => {
						'name' => q(yard),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(il),
						'one' => q({0} il),
						'other' => q({0} il),
						'per' => q({0}/il),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:hə|h)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:yox|y|no|n)$' }
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
					'one' => '0G',
					'other' => '0G',
				},
				'10000000000' => {
					'one' => '00G',
					'other' => '00G',
				},
				'100000000000' => {
					'one' => '000G',
					'other' => '000G',
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
					'' => '#,##0.###',
				},
			},
			'long' => {
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
					'one' => '0G',
					'other' => '0G',
				},
				'10000000000' => {
					'one' => '00G',
					'other' => '00G',
				},
				'100000000000' => {
					'one' => '000G',
					'other' => '000G',
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
					'one' => '0G',
					'other' => '0G',
				},
				'10000000000' => {
					'one' => '00G',
					'other' => '00G',
				},
				'100000000000' => {
					'one' => '000G',
					'other' => '000G',
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
					'' => '#,##0%',
				},
			},
		},
		scientificFormat => {
			'default' => {
				'standard' => {
					'' => '#E0',
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
				'currency' => q(Andora Pesetası),
				'one' => q(Andora pesetası),
				'other' => q(Andora pesetası),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(Birləşmiş Ərəb Əmirlikləri Dirhəmi),
				'one' => q(BƏƏ dirhəmi),
				'other' => q(BƏƏ dirhəmi),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(Əfqanıstan Əfqanisi \(1927–2002\)),
				'one' => q(Əfqanıstan əfqanisi \(1927–2002\)),
				'other' => q(Əfqanıstan əfqanisi \(1927–2002\)),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Əfqanıstan Əfqanisi),
				'one' => q(Əfqanıstan əfqanisi),
				'other' => q(Əfqanıstan əfqanisi),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(Albaniya Leki \(1946–1965\)),
				'one' => q(Albaniya leki \(1946–1965\)),
				'other' => q(Albaniya leki \(1946–1965\)),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(Albaniya Leki),
				'one' => q(Albaniya leki),
				'other' => q(Albaniya leki),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(Ermənistan Dramı),
				'one' => q(Ermənistan dramı),
				'other' => q(Ermənistan dramı),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(Niderland Antilyası Gilderi),
				'one' => q(Niderland Antilyası gilderi),
				'other' => q(Niderland Antilya gilderi),
			},
		},
		'AOA' => {
			symbol => 'AOA',
			display_name => {
				'currency' => q(Anqola Kvanzası),
				'one' => q(Anqola kvanzasi),
				'other' => q(Anqola kvanzasi),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Anqola Kvanzasi \(1977–1990\)),
				'one' => q(Anqola kvanzasi \(1977–1990\)),
				'other' => q(Anqola kvanzasi \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Anqola Yeni Kvanzası \(1990–2000\)),
				'one' => q(Anqola yeni kvanzası \(1990–2000\)),
				'other' => q(Anqola yeni kvanzası \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Anqola Kvanzası \(1995–1999\)),
				'one' => q(Anqola kvanzası \(1995–1999\)),
				'other' => q(Anqola kvanzası \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Argentina avstralı),
				'one' => q(Argentina avstralı),
				'other' => q(Argentina avstralı),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Argentina pesosu \(1983–1985\)),
				'one' => q(Argentina pesosu \(1983–1985\)),
				'other' => q(Argentina pesosu \(1983–1985\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
			display_name => {
				'currency' => q(Argentina Pesosu),
				'one' => q(Argentina pesosu),
				'other' => q(Argentina pesosu),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(Avstriya Şillinqi),
				'one' => q(Avstriya şillinqi),
				'other' => q(Avstriya şillinqi),
			},
		},
		'AUD' => {
			symbol => 'A$',
			display_name => {
				'currency' => q(Avstraliya Dolları),
				'one' => q(Avstraliya dolları),
				'other' => q(Avstraliya dolları),
			},
		},
		'AWG' => {
			symbol => 'AWG',
			display_name => {
				'currency' => q(Aruba Florini),
				'one' => q(Aruba florini),
				'other' => q(Aruba florini),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Azərbaycan Manatı \(1993–2006\)),
				'one' => q(Azərbaycan manatı \(1993–2006\)),
				'other' => q(Azərbaycan manatı \(1993–2006\)),
			},
		},
		'AZN' => {
			symbol => '₼',
			display_name => {
				'currency' => q(Azərbaycan Manatı),
				'one' => q(Azərbaycan manatı),
				'other' => q(Azərbaycan manatı),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Bosniya-Herseqovina Dinarı),
				'one' => q(Bosniya-Herseqovina dinarı),
				'other' => q(Bosniya-Herseqovina dinarı),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(Bosniya-Herseqovina Markası),
				'one' => q(Bosniya-Herseqovina markası),
				'other' => q(Bosniya-Herseqovina markası),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(Barbados Dolları),
				'one' => q(Barbados dolları),
				'other' => q(Barbados dolları),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Banqladeş Takası),
				'one' => q(Banqladeş takası),
				'other' => q(Banqladeş takası),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Belçika Frankı \(deyşirik\)),
				'one' => q(Belçika frankı \(deyşirik\)),
				'other' => q(Belçika frankı \(deyşirik\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Belçika Frankı),
				'one' => q(Belçika frankı),
				'other' => q(Belçika frankı),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Belçika Frankı \(finans\)),
				'one' => q(Belçika frankı \(finans\)),
				'other' => q(Belçika frankı \(finans\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Bolqarıstan Levası),
				'one' => q(Bolqarıstan levası),
				'other' => q(Bolqarıstan levası),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(Bolqarıstan Levi),
				'one' => q(Bolqarıstan levi),
				'other' => q(Bolqarıstan levi),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(Bəhreyn Dinarı),
				'one' => q(Bəhreyn dinarı),
				'other' => q(Bəhreyn dinarı),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(Burundi Frankı),
				'one' => q(Burundi frankı),
				'other' => q(Burundi frankı),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(Bermuda Dolları),
				'one' => q(Bermuda dolları),
				'other' => q(Bermuda dolları),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Bruney Dolları),
				'one' => q(Bruney dolları),
				'other' => q(Bruney dolları),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(Boliviya Bolivianosu),
				'one' => q(Boliviya bolivianosu),
				'other' => q(Boliviya bolivianosu),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Boliviya pesosu),
				'one' => q(Boliviya pesosu),
				'other' => q(Boliviya pesosu),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Boliviya mvdolı),
				'one' => q(Boliviya mvdolı),
				'other' => q(Boliviya mvdolı),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Braziliya kruzeyro novası),
				'one' => q(Braziliya kruzeyro novası),
				'other' => q(Braziliya kruzeyro novası),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Braziliya kruzadosu),
				'one' => q(Braziliya kruzadosu),
				'other' => q(Braziliya kruzadosu),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Braziliya kruzeyrosu \(1990–1993\)),
				'one' => q(Braziliya kruzeyrosu \(1990–1993\)),
				'other' => q(Braziliya kruzeyrosu \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Braziliya Realı),
				'one' => q(Braziliya realı),
				'other' => q(Braziliya realı),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Braziliya kruzado novası),
				'one' => q(Braziliya kruzado novası),
				'other' => q(Braziliya kruzado novası),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Braziliya kruzeyrosu),
				'one' => q(Braziliya kruzeyrosu),
				'other' => q(Braziliya kruzeyrosu),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(Bahama Dolları),
				'one' => q(Bahama dolları),
				'other' => q(Bahama dolları),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Butan Nqultrumu),
				'one' => q(Butan nqultrumu),
				'other' => q(Butan nqultrumu),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(Burmis Kyatı),
				'one' => q(Burmis kyatı),
				'other' => q(Burmis kyatı),
			},
		},
		'BWP' => {
			symbol => 'BWP',
			display_name => {
				'currency' => q(Botsvana Pulası),
				'one' => q(Botsvana pulası),
				'other' => q(Botsvana pulası),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Belarus Yeni Rublu \(1994–1999\)),
				'one' => q(Belarus yeni rublu \(1994–1999\)),
				'other' => q(Belarus yeni rublu \(1994–1999\)),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(Belarus Rublu),
				'one' => q(Belarus rublu),
				'other' => q(Belarus rublu),
			},
		},
		'BZD' => {
			symbol => 'BZD',
			display_name => {
				'currency' => q(Beliz Dolları),
				'one' => q(Beliz dolları),
				'other' => q(Beliz dolları),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Kanada Dolları),
				'one' => q(Kanada dolları),
				'other' => q(Kanada dolları),
			},
		},
		'CDF' => {
			symbol => 'CDF',
			display_name => {
				'currency' => q(Konqo Frankı),
				'one' => q(Konqo frankı),
				'other' => q(Konqo frankı),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR Avro),
				'one' => q(WIR avro),
				'other' => q(WIR avro),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(İsveçrə Frankı),
				'one' => q(İsveçrə frankı),
				'other' => q(İsveçrə frankı),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR Frankası),
				'one' => q(WIR frankası),
				'other' => q(WIR frankası),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(Çili Pesosu),
				'one' => q(Çili pesosu),
				'other' => q(Çili pesosu),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Çin Yuanı),
				'one' => q(Çin yuanı),
				'other' => q(Çin yuanı),
			},
		},
		'COP' => {
			symbol => 'COP',
			display_name => {
				'currency' => q(Kolumbiya Pesosu),
				'one' => q(Kolombiya pesosu),
				'other' => q(Kolombiya pesosu),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(Kosta Rika Kolonu),
				'one' => q(Kosta Rika kolonu),
				'other' => q(Kosta Rika kolonu),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Serbiya Dinarı \(2002–2006\)),
				'one' => q(Serbiya dinarı \(2002–2006\)),
				'other' => q(Serbiya dinarı \(2002–2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Çexoslavakiya Korunası),
				'one' => q(Çexoslavakiya korunası),
				'other' => q(Çexoslavakiya korunası),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(Kuba Çevrilən Pesosu),
				'one' => q(Kuba çevrilən pesosu),
				'other' => q(Kuba çevrilən pesosu),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(Kuba Pesosu),
				'one' => q(Kuba pesosu),
				'other' => q(Kuba pesosu),
			},
		},
		'CVE' => {
			symbol => 'CVE',
			display_name => {
				'currency' => q(Kape Verde Eskudosu),
				'one' => q(Kape Verde eskudosu),
				'other' => q(Kape Verde eskudosu),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Kipr Paundu),
				'one' => q(Kipr paundu),
				'other' => q(Kipr paundu),
			},
		},
		'CZK' => {
			symbol => 'CZK',
			display_name => {
				'currency' => q(Çexiya Korunası),
				'one' => q(Çexiya korunası),
				'other' => q(Çexiya korunası),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(Şərq Almaniya Ostmarkı),
				'one' => q(Şərq Almaniya ostmarkı),
				'other' => q(Şərq Almaniya ostmarkı),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Alman Markası),
				'one' => q(Alman markası),
				'other' => q(Alman markası),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(Cibuti Frankı),
				'one' => q(Cibuti frankı),
				'other' => q(Cibuti frankı),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(Danimarka Kronu),
				'one' => q(Danimarka kronu),
				'other' => q(Danimarka kronu),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(Dominika Pesosu),
				'one' => q(Dominika pesosu),
				'other' => q(Dominika pesosu),
			},
		},
		'DZD' => {
			symbol => 'DZD',
			display_name => {
				'currency' => q(Əlcəzair Dinarı),
				'one' => q(Əlcəzair dinarı),
				'other' => q(Əlcəzair dinarı),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Ekvador Sukresi),
				'one' => q(Ekvador sukresi),
				'other' => q(Ekvador sukresi),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Estoniya Krunu),
				'one' => q(Estoniya krunu),
				'other' => q(Estoniya krunu),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(Misir Funtu),
				'one' => q(Misir funtu),
				'other' => q(Misir funtu),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(Eritreya Nakfası),
				'one' => q(Eritreya nakfası),
				'other' => q(Eritreya nakfası),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(İspan Pesetası \(A account\)),
				'one' => q(İspan pesetası \(A account\)),
				'other' => q(İspan pesetası \(A account\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(İspan Pesetası \(dəyşirik\)),
				'one' => q(İspan pesetası \(dəyşirik\)),
				'other' => q(İspan pesetası \(dəyşirik\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(İspan Pesetası),
				'one' => q(İspan pesetası),
				'other' => q(İspan pesetası),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(Efiopiya Bırrı),
				'one' => q(Efiopiya bırrı),
				'other' => q(Efiopiya bırrı),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Avro),
				'one' => q(Avro),
				'other' => q(Avro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Fin Markası),
				'one' => q(Fin markası),
				'other' => q(Fin markası),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(Fici Dolları),
				'one' => q(Fici dolları),
				'other' => q(Fici dolları),
			},
		},
		'FKP' => {
			symbol => 'FKP',
			display_name => {
				'currency' => q(Folklend Adaları Funtu),
				'one' => q(Folklend Adaları funtu),
				'other' => q(Folklend Adaları funtu),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Fransız Markası),
				'one' => q(Fransız markası),
				'other' => q(Fransız markası),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Britaniya Funt),
				'one' => q(Britaniya funt),
				'other' => q(Britaniya funt),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Gürcüstan Kupon Lariti),
				'one' => q(Gürcüstan kupon lariti),
				'other' => q(Gürcüstan kupon lariti),
			},
		},
		'GEL' => {
			symbol => 'GEL',
			display_name => {
				'currency' => q(Gürcüstan Larisi),
				'one' => q(Gürcüstan larisi),
				'other' => q(Gürcüstan larisi),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Qana Sedisi \(1979–2007\)),
				'one' => q(Qana sedisi \(1979–2007\)),
				'other' => q(Qana sedisi \(1979–2007\)),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(Qana Sedisi),
				'one' => q(Qana sedisi),
				'other' => q(Qana sedisi),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(Gibraltar Funtu),
				'one' => q(Gibraltar funtu),
				'other' => q(Gibraltar funtu),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(Qambiya Dalasisi),
				'one' => q(Qambiya dalasisi),
				'other' => q(Qambiya dalasisi),
			},
		},
		'GNF' => {
			symbol => 'GNF',
			display_name => {
				'currency' => q(Qvineya Frankı),
				'one' => q(Qvineya frankı),
				'other' => q(Qvineya frankı),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Qvineya Sulisi),
				'one' => q(Qvineya sulisi),
				'other' => q(Qvineya sulisi),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Ekvatoriya Gvineya Ekvele Quneanası),
				'one' => q(Ekvatoriya Gvineya ekvele quneanası),
				'other' => q(Ekvatoriya Gvineya ekvele quneanası),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Yunan Draçması),
				'one' => q(Yunan draxması),
				'other' => q(Yunan draxması),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
			display_name => {
				'currency' => q(Qvatemala Küetzalı),
				'one' => q(Qvatemala küetzalı),
				'other' => q(Qvatemala küetzalı),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Portugal Qvineya Eskudosu),
				'one' => q(Portugal Qvineya eskudosu),
				'other' => q(Portugal Qvineya eskudosu),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Qvineya-Bisau Pesosu),
				'one' => q(Qvineya-Bisau pesosu),
				'other' => q(Qvineya-Bisau pesosu),
			},
		},
		'GYD' => {
			symbol => 'GYD',
			display_name => {
				'currency' => q(Qayana Dolları),
				'one' => q(Qayana dolları),
				'other' => q(Qayana dolları),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Honq Konq Dolları),
				'one' => q(Honq Konq dolları),
				'other' => q(Honq Konq dolları),
			},
		},
		'HNL' => {
			symbol => 'HNL',
			display_name => {
				'currency' => q(Honduras Lempirası),
				'one' => q(Honduras lempirası),
				'other' => q(Honduras lempirası),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Xorvatiya Dinarı),
				'one' => q(Xorvatiya dinarı),
				'other' => q(Xorvatiya dinarı),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(Xorvatiya Kunası),
				'one' => q(Xorvatiya kunası),
				'other' => q(Xorvatiya kunası),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(Haiti Qourdu),
				'one' => q(Haiti qourdu),
				'other' => q(Haiti qourdu),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(Macarıstan Forinti),
				'one' => q(Macarıstan forinti),
				'other' => q(Macarıstan forinti),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(İndoneziya Rupisi),
				'one' => q(İndoneziya rupisi),
				'other' => q(İndoneziya rupisi),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(İrlandiya Paundu),
				'one' => q(İrlandiya paundu),
				'other' => q(İrlandiya paundu),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(İzrail Paundu),
				'one' => q(İzrail paundu),
				'other' => q(İzrail paundu),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(İsrail Şekeli \(1980–1985\)),
				'one' => q(İsrail şekeli \(1980–1985\)),
				'other' => q(İsrail şekeli \(1980–1985\)),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(İsrail Yeni Şekeli),
				'one' => q(İsrail yeni şekeli),
				'other' => q(İsrail yeni şekeli),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Hindistan Rupisi),
				'one' => q(Hindistan rupisi),
				'other' => q(Hindistan rupisi),
			},
		},
		'IQD' => {
			symbol => 'IQD',
			display_name => {
				'currency' => q(İraq Dinarı),
				'one' => q(İraq dinarı),
				'other' => q(İraq dinarı),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(İran Rialı),
				'one' => q(İran rialı),
				'other' => q(İran rialı),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(İslandiya Kronu \(1918–1981\)),
				'one' => q(İslandiya kronu \(1918–1981\)),
				'other' => q(İslandiya kronu \(1918–1981\)),
			},
		},
		'ISK' => {
			symbol => 'ISK',
			display_name => {
				'currency' => q(İslandiya Kronu),
				'one' => q(İslandiya kronu),
				'other' => q(İslandiya kronu),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(İtaliya Lirası),
				'one' => q(İtaliya lirası),
				'other' => q(İtaliya lirası),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(Yamayka Dolları),
				'one' => q(Yamayka dolları),
				'other' => q(Yamayka dolları),
			},
		},
		'JOD' => {
			symbol => 'JOD',
			display_name => {
				'currency' => q(İordaniya Dinarı),
				'one' => q(İordaniya dinarı),
				'other' => q(İordaniya dinarı),
			},
		},
		'JPY' => {
			symbol => 'JP¥',
			display_name => {
				'currency' => q(Yaponiya Yeni),
				'one' => q(Yaponiya yeni),
				'other' => q(Yaponiya yeni),
			},
		},
		'KES' => {
			symbol => 'KES',
			display_name => {
				'currency' => q(Keniya Şillinqi),
				'one' => q(Keniya şillinqi),
				'other' => q(Keniya şillinqi),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(Kırğızıstan Somu),
				'one' => q(Kırğızıstan somu),
				'other' => q(Kırğızıstan somu),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Kamboca Rieli),
				'one' => q(Kamboca rieli),
				'other' => q(Kamboca rieli),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(Komor Frankı),
				'one' => q(Komor frankı),
				'other' => q(Komor frankı),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Şimali Koreya Vonu),
				'one' => q(Şimali Koreya vonu),
				'other' => q(Şimali Koreya vonu),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Cənubi Koreya Vonu),
				'one' => q(Cənubi Koreya vonu),
				'other' => q(Cənubi Koreya vonu),
			},
		},
		'KWD' => {
			symbol => 'KWD',
			display_name => {
				'currency' => q(Küveyt Dinarı),
				'one' => q(Küveyt dinarı),
				'other' => q(Küveyt dinarı),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(Kayman Adaları Dolları),
				'one' => q(Kayman Adaları dolları),
				'other' => q(Kayman Adaları dolları),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(Qazaxıstan Tengesi),
				'one' => q(Qazaxıstan tengesi),
				'other' => q(Qazaxıstan tengesi),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Laos Kipi),
				'one' => q(Laos kipi),
				'other' => q(Laos kipi),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(Livan Funtu),
				'one' => q(Livan funtu),
				'other' => q(Livan funtu),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Şri Lanka Rupisi),
				'one' => q(Şri Lanka rupisi),
				'other' => q(Şri Lanka rupisi),
			},
		},
		'LRD' => {
			symbol => 'LRD',
			display_name => {
				'currency' => q(Liberiya Dolları),
				'one' => q(Liberiya dolları),
				'other' => q(Liberiya dolları),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Lesoto Lotisi),
				'one' => q(Lesoto lotisi),
				'other' => q(Lesoto lotisi),
			},
		},
		'LTL' => {
			symbol => 'LTL',
			display_name => {
				'currency' => q(Litva Liti),
				'one' => q(Litva liti),
				'other' => q(Litva liti),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Litva Talonası),
				'one' => q(Litva talonası),
				'other' => q(Litva talonası),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Luksemburq Frankası \(dəyişik\)),
				'one' => q(Luksemburq dəyişik frankası),
				'other' => q(Luksemburq dəyişik frankası),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Luksemburq Frankası),
				'one' => q(Luksemburq frankası),
				'other' => q(Luksemburq frankası),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Luksemburq Frankası \(finans\)),
				'one' => q(Luksemburq finans frankası),
				'other' => q(Luksemburq finans frankası),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(Latviya Latı),
				'one' => q(Latviya latı),
				'other' => q(Latviya latı),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Latviya Rublu),
				'one' => q(Latviya rublu),
				'other' => q(Latviya rublu),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(Liviya Dinarı),
				'one' => q(Liviya dinarı),
				'other' => q(Liviya dinarı),
			},
		},
		'MAD' => {
			symbol => 'MAD',
			display_name => {
				'currency' => q(Mərakeş Dirhəmi),
				'one' => q(Mərakeş dirhəmi),
				'other' => q(Mərakeş dirhəmi),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Mərakeş Frankası),
				'one' => q(Mərakeş frankası),
				'other' => q(Mərakeş frankası),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(Moldova Leyi),
				'one' => q(Moldova leyi),
				'other' => q(Moldova leyi),
			},
		},
		'MGA' => {
			symbol => 'MGA',
			display_name => {
				'currency' => q(Madaqaskar Ariarisi),
				'one' => q(Madaqaskar ariarisi),
				'other' => q(Madaqaskar ariarisi),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Madaqaskar Frankası),
				'one' => q(Madaqaskar frankası),
				'other' => q(Madaqaskar frankası),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(Makedoniya Dinarı),
				'one' => q(Makedoniya dinarı),
				'other' => q(Makedoniya dinarı),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(Makedoniya Dinarı \(1992–1993\)),
				'one' => q(Makedoniya dinarı \(1992–1993\)),
				'other' => q(Makedoniya dinarı \(1992–1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Mali Frankı),
				'one' => q(Mali frankı),
				'other' => q(Mali frankı),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Myanma Kiyatı),
				'one' => q(Myanmar kiyatı),
				'other' => q(Myanmar kiyatı),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Monqoliya Tuqriki),
				'one' => q(Monqoliya tuqriki),
				'other' => q(Monqoliya tuqriki),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Makao Patakası),
				'one' => q(Makao patakası),
				'other' => q(Makao patakası),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(Mavritaniya Ugiyası),
				'one' => q(Mavritaniya ugiyası),
				'other' => q(Mavritaniya ugiyası),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Maltiz Paundu),
				'one' => q(Maltiz paundu),
				'other' => q(Maltiz paundu),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(Mavriki Rupisi),
				'one' => q(Mavriki rupisi),
				'other' => q(Mavriki rupisi),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Maldiv Rufiyası),
				'one' => q(Maldiv rufiyası),
				'other' => q(Maldiv rufiyası),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(Malavi Kvaçası),
				'one' => q(Malavi kvaçası),
				'other' => q(Malavi kvaçası),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(Meksika Pesosu),
				'one' => q(Meksika pesosu),
				'other' => q(Meksika pesosu),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Meksika gümüş pesosu),
				'one' => q(Meksika gümüş pesosu),
				'other' => q(Meksika gümüş pesosu),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Malayziya Ringiti),
				'one' => q(Malayziya ringiti),
				'other' => q(Malayziya ringiti),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Mozambik Eskudosu),
				'one' => q(Mozambik eskudosu),
				'other' => q(Mozambik eskudosu),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mozambik Metikalı \(1980–2006\)),
				'one' => q(Mozambik metikalı \(1980–2006\)),
				'other' => q(Mozambik metikalı \(1980–2006\)),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(Mozambik Metikalı),
				'one' => q(Mozambik metikalı),
				'other' => q(Mozambik metikalı),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(Namibiya Dolları),
				'one' => q(Namibiya dolları),
				'other' => q(Namibiya dolları),
			},
		},
		'NGN' => {
			symbol => 'NGN',
			display_name => {
				'currency' => q(Nigeriya Nairası),
				'one' => q(Nigeriya nairası),
				'other' => q(Nigeriya nairası),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Nikaraqua kordobu),
				'one' => q(Nikaraqua kordobu),
				'other' => q(Nikaraqua kordobu),
			},
		},
		'NIO' => {
			symbol => 'NIO',
			display_name => {
				'currency' => q(Nikaraqua Kordobası),
				'one' => q(Nikaraqua kordobası),
				'other' => q(Nikaraqua kordobası),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Hollandiya Gilderi),
				'one' => q(Hollandiya gilderi),
				'other' => q(Hollandiya gilderi),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(Norveç Kronu),
				'one' => q(Norveç kronu),
				'other' => q(Norveç kronu),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Nepal Rupisi),
				'one' => q(Nepal rupisi),
				'other' => q(Nepal rupisi),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Yeni Zelandiya Dolları),
				'one' => q(Yeni Zelandiya dolları),
				'other' => q(Yeni Zelandiya dolları),
			},
		},
		'OMR' => {
			symbol => 'OMR',
			display_name => {
				'currency' => q(Oman Rialı),
				'one' => q(Oman rialı),
				'other' => q(Oman rialı),
			},
		},
		'PAB' => {
			symbol => 'PAB',
			display_name => {
				'currency' => q(Panama Balboası),
				'one' => q(Panama balboası),
				'other' => q(Panama balboası),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Peru Inti),
				'one' => q(Peru inti),
				'other' => q(Peru inti),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(Peru Nuevo Solu),
				'one' => q(Peru Nuevo solu),
				'other' => q(Peru Nuevo solu),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Peru Solu),
				'one' => q(Peru solu),
				'other' => q(Peru solu),
			},
		},
		'PGK' => {
			symbol => 'PGK',
			display_name => {
				'currency' => q(Papua Yeni Qvineya Kinası),
				'one' => q(Papua Yeni Qvineya kinası),
				'other' => q(Papua Yeni Qvineya kinası),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Filippin Pesosu),
				'one' => q(Filippin pesosu),
				'other' => q(Filippin pesosu),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Pakistan Rupisi),
				'one' => q(Pakistan rupisi),
				'other' => q(Pakistan rupisi),
			},
		},
		'PLN' => {
			symbol => 'PLN',
			display_name => {
				'currency' => q(Polşa Zlotısı),
				'one' => q(Polşa zlotısı),
				'other' => q(Polşa zlotısı),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Polşa Zlotısı \(1950–1995\)),
				'one' => q(Polşa zlotısı \(1950–1995\)),
				'other' => q(Polşa zlotısı \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Portuqal Eskudosu),
				'one' => q(Portuqal eskudosu),
				'other' => q(Portuqal eskudosu),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(Paraqvay Quaranisi),
				'one' => q(Paraqvay quaranisi),
				'other' => q(Paraqvay quaranisi),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(Qatar Rialı),
				'one' => q(Qatar rialı),
				'other' => q(Qatar rialı),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Rodezian Dolları),
				'one' => q(Rodezian dolları),
				'other' => q(Rodezian dolları),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Rumıniya Leyi \(1952–2006\)),
				'one' => q(Rumıniya leyi \(1952–2006\)),
				'other' => q(Rumıniya leyi \(1952–2006\)),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(Rumıniya Leyi),
				'one' => q(Rumıniya leyi),
				'other' => q(Rumıniya leyi),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(Serbiya Dinarı),
				'one' => q(Serbiya dinarı),
				'other' => q(Serbiya dinarı),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(Rusiya Rublu),
				'one' => q(Rusiya rublu),
				'other' => q(Rusiya rublu),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Rusiya Rublu \(1991–1998\)),
				'one' => q(Rusiya rublu \(1991–1998\)),
				'other' => q(Rusiya rublu \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(Ruanda Frankı),
				'one' => q(Ruanda frankı),
				'other' => q(Ruanda frankı),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(Səudiyyə Riyalı),
				'one' => q(Səudiyyə riyalı),
				'other' => q(Səudiyyə riyalı),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(Solomon Adaları Dolları),
				'one' => q(Solomon Adaları dolları),
				'other' => q(Solomon Adaları dolları),
			},
		},
		'SCR' => {
			symbol => 'SCR',
			display_name => {
				'currency' => q(Seyşel Rupisi),
				'one' => q(Seyşel rupisi),
				'other' => q(Seyşel rupisi),
			},
		},
		'SDG' => {
			symbol => 'SDG',
			display_name => {
				'currency' => q(Sudan Funtu),
				'one' => q(Sudan funtu),
				'other' => q(Sudan funtu),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(İsveç Kronu),
				'one' => q(İsveç kronu),
				'other' => q(İsveç kronu),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Sinqapur Dolları),
				'one' => q(Sinqapur dolları),
				'other' => q(Sinqapur dolları),
			},
		},
		'SHP' => {
			symbol => 'SHP',
			display_name => {
				'currency' => q(Müqəddəs Yelena Funtu),
				'one' => q(Müqəddəs Yelena funtu),
				'other' => q(Müqəddəs Yelena funtu),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Sloveniya Toları),
				'one' => q(Sloveniya toları),
				'other' => q(Sloveniya toları),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Slovak Korunası),
				'one' => q(Slovak korunası),
				'other' => q(Slovak korunası),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(Sierra Leon Leonu),
				'one' => q(Sierra Leon leonu),
				'other' => q(Sierra Leon leonu),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(Somali Şillinqi),
				'one' => q(Somali şillinqi),
				'other' => q(Somali şillinqi),
			},
		},
		'SRD' => {
			symbol => 'SRD',
			display_name => {
				'currency' => q(Surinam Dolları),
				'one' => q(Surinam dolları),
				'other' => q(Surinam dolları),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(Cənubi Sudan Funtu),
				'one' => q(Cənubi Sudan funtu),
				'other' => q(Cənubi Sudan funtu),
			},
		},
		'STD' => {
			symbol => 'STD',
			display_name => {
				'currency' => q(San Tom və Prinsip Dobrası),
				'one' => q(San Tom və Prinsip dobrası),
				'other' => q(San Tom və Prinsip dobrası),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Sovet Rublu),
				'one' => q(Sovet rublu),
				'other' => q(Sovet rublu),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(El Salvador kolonu),
				'one' => q(El Salvador kolonu),
				'other' => q(El Salvador kolonu),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(Suriya Funtu),
				'one' => q(Suriya funtu),
				'other' => q(Suriya funtu),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(Svazilend Lilangenini),
				'one' => q(Svazilend lilangenini),
				'other' => q(Svazilend emalangenini),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Tayland Batı),
				'one' => q(Tayland batı),
				'other' => q(Tayland batı),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tacikistan Rublu),
				'one' => q(Tacikistan rublu),
				'other' => q(Tacikistan rublu),
			},
		},
		'TJS' => {
			symbol => 'TJS',
			display_name => {
				'currency' => q(Tacikistan Somonisi),
				'one' => q(Tacikistan somonisi),
				'other' => q(Tacikistan somonisi),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Türkmənistan Manatı \(1993–2009\)),
				'one' => q(Türkmənistan manatı \(1993–2009\)),
				'other' => q(Türkmənistan manatı \(1993–2009\)),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(Türkmənistan Manatı),
				'one' => q(Türkmənistan manatı),
				'other' => q(Türkmənistan manatı),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(Tunis Dinarı),
				'one' => q(Tunis dinarı),
				'other' => q(Tunis dinarı),
			},
		},
		'TOP' => {
			symbol => 'TOP',
			display_name => {
				'currency' => q(Tonqa Panqası),
				'one' => q(Tonqa panqası),
				'other' => q(Tonqa panqası),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Timor Eskudu),
				'one' => q(Timor eskudu),
				'other' => q(Timor eskudu),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Türkiyə Lirəsi \(1922–2005\)),
				'one' => q(Türkiyə lirəsi \(1922–2005\)),
				'other' => q(Türkiyə lirəsi \(1922–2005\)),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(Türkiyə Lirəsi),
				'one' => q(Türkiyə lirəsi),
				'other' => q(Türkiyə lirəsi),
			},
		},
		'TTD' => {
			symbol => 'TTD',
			display_name => {
				'currency' => q(Trinidad və Tobaqo Dolları),
				'one' => q(Trinidad və Tobaqo dolları),
				'other' => q(Trinidad və Tobaqo dolları),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Tayvan Yeni Dolları),
				'one' => q(Tayvan yeni dolları),
				'other' => q(Tayvan yeni dolları),
			},
		},
		'TZS' => {
			symbol => 'TZS',
			display_name => {
				'currency' => q(Tanzaniya Şillinqi),
				'one' => q(Tanzaniya şillinqi),
				'other' => q(Tanzaniya şillinqi),
			},
		},
		'UAH' => {
			symbol => 'UAH',
			display_name => {
				'currency' => q(Ukrayna Qrivnası),
				'one' => q(Ukrayna qrivnası),
				'other' => q(Ukrayna qrivnası),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Ukrayna Karbovenesası),
				'one' => q(Ukrayna karbovenesası),
				'other' => q(Ukrayna karbovenesası),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Uqanda Şillinqi \(1966–1987\)),
				'one' => q(Uqanda şillinqi \(1966–1987\)),
				'other' => q(Uqanda şillinqi \(1966–1987\)),
			},
		},
		'UGX' => {
			symbol => 'UGX',
			display_name => {
				'currency' => q(Uqanda Şillinqi),
				'one' => q(Uqanda şillinqi),
				'other' => q(Uqanda şillinqi),
			},
		},
		'USD' => {
			symbol => 'US$',
			display_name => {
				'currency' => q(ABŞ Dolları),
				'one' => q(ABŞ dolları),
				'other' => q(ABŞ dolları),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(ABŞ dolları \(yeni gün\)),
				'one' => q(ABŞ dolları \(yeni gün\)),
				'other' => q(ABŞ dolları \(yeni gün\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(ABŞ dolları \(həmin gün\)),
				'one' => q(ABŞ dolları \(həmin gün\)),
				'other' => q(ABŞ dolları \(həmin gün\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(Uruqvay pesosu Unidades Indexadas),
				'one' => q(Uruqvay pesosu unidades indexadas),
				'other' => q(Uruqvay pesosu unidades indexadas),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Uruqvay Pesosu \(1975–1993\)),
				'one' => q(Uruqvay pesosu \(1975–1993\)),
				'other' => q(Uruqvay pesosu \(1975–1993\)),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(Uruqvay Pesosu),
				'one' => q(Uruqvay pesosu),
				'other' => q(Uruqvay pesosu),
			},
		},
		'UZS' => {
			symbol => 'UZS',
			display_name => {
				'currency' => q(Özbəkistan Somu),
				'one' => q(Özbəkistan somu),
				'other' => q(Özbəkistan somu),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Venesuela Bolivarı \(1871–2008\)),
				'one' => q(Venesuela bolivarı \(1871–2008\)),
				'other' => q(Venesuela bolivarı \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
			display_name => {
				'currency' => q(Venesuela Bolivarı),
				'one' => q(Venesuela bolivarı),
				'other' => q(Venesuela bolivarı),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Vyetnam Donqu),
				'one' => q(Vyetnam donqu),
				'other' => q(Vyetnam donqu),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(Vyetnam Donqu \(1978–1985\)),
				'one' => q(Vyetnam donqu \(1978–1985\)),
				'other' => q(Vyetnam donqu \(1978–1985\)),
			},
		},
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(Vanuatu Vatusu),
				'one' => q(Vanuatu vatusu),
				'other' => q(Vanuatu vatusu),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(Samoa Talası),
				'one' => q(Samoa talası),
				'other' => q(Samoa talası),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(Kamerun Frankı),
				'one' => q(Kamerun frankı),
				'other' => q(Kamerun frankı),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(gümüş),
				'one' => q(gümüş),
				'other' => q(gümüş),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(qızıl),
				'one' => q(qızıl),
				'other' => q(qızıl),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(Şərqi Karib Dolları),
				'one' => q(Şərqi Karib dolları),
				'other' => q(Şərqi Karib dolları),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Fransız Gızıl Frankı),
				'one' => q(Fransız gızıl frankı),
				'other' => q(Fransız gızıl frankı),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Fransız UİC Frankı),
				'one' => q(Fransız UİC frankı),
				'other' => q(Fransız UİC frankı),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(Fil Dişi Sahili Frankı),
				'one' => q(Fil Dişi Sahili frankı),
				'other' => q(Fil Dişi Sahili frankı),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Palladium),
				'one' => q(Palladium),
				'other' => q(Palladium),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(Fransız Polineziyası Frankı),
				'one' => q(Fransız Polineziyası frankı),
				'other' => q(Fransız Polineziyası frankı),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Platinum),
				'one' => q(platinum),
				'other' => q(platinum),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Naməlum Valyuta),
				'one' => q(\(naməlum valyuta vahidi\)),
				'other' => q(\(naməlum valyuta\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Yəmən Dinarı),
				'one' => q(Yəmən dinarı),
				'other' => q(Yəmən dinarı),
			},
		},
		'YER' => {
			symbol => 'YER',
			display_name => {
				'currency' => q(Yəmən Rialı),
				'one' => q(Yəmən rialı),
				'other' => q(Yəmən rialı),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Yuqoslaviya Dinarı \(1966–1990\)),
				'one' => q(Yuqoslaviya dinarı \(1966–1990\)),
				'other' => q(Yuqoslaviya dinarı \(1966–1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Yuqoslaviya Yeni Dinarı \(1994–2002\)),
				'one' => q(Yuqoslaviya yeni dinarı \(1994–2002\)),
				'other' => q(Yuqoslaviya yeni dinarı \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Yuqoslaviya Dinarı \(1990–1992\)),
				'one' => q(Yuqoslaviya dinarı \(1990–1992\)),
				'other' => q(Yuqoslaviya dinarı \(1990–1992\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Cənubi Afrika Randı \(finans\)),
				'one' => q(Cənubi Afrika randı \(finans\)),
				'other' => q(Cənubi Afrika randı \(finans\)),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
			display_name => {
				'currency' => q(Cənubi Afrika Randı),
				'one' => q(Cənubi Afrika randı),
				'other' => q(Cənubi Afrika randı),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Zambiya Kvaçası \(1968–2012\)),
				'one' => q(Zambiya kvaçası \(1968–2012\)),
				'other' => q(Zambiya kvaçası \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
			display_name => {
				'currency' => q(Zambiya Kvaçası),
				'one' => q(Zambiya kvaçası),
				'other' => q(Zambiya kvaçası),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Zair Yeni Zairi \(1993–1998\)),
				'one' => q(Zair yeni zairi \(1993–1998\)),
				'other' => q(Zair yeni zairi \(1993–1998\)),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Zair Zairi \(1971–1993\)),
				'one' => q(Zair zairi \(1971–1993\)),
				'other' => q(Zair zairi \(1971–1993\)),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Zimbabve Dolları \(1980–2008\)),
				'one' => q(Zimbabve dolları \(1980–2008\)),
				'other' => q(Zimbabve dolları \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Zimbabve Dolları \(2009\)),
				'one' => q(Zimbabve dolları \(2009\)),
				'other' => q(Zimbabve dolları \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Zimbabve Dolları \(2008\)),
				'one' => q(Zimbabve dolları \(2008\)),
				'other' => q(Zimbabve dolları \(2008\)),
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
							'yan',
							'fev',
							'mar',
							'apr',
							'may',
							'iyn',
							'iyl',
							'avq',
							'sen',
							'okt',
							'noy',
							'dek'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'yanvar',
							'fevral',
							'mart',
							'aprel',
							'may',
							'iyun',
							'iyul',
							'avqust',
							'sentyabr',
							'oktyabr',
							'noyabr',
							'dekabr'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'yan',
							'fev',
							'mar',
							'apr',
							'may',
							'iyn',
							'iyl',
							'avq',
							'sen',
							'okt',
							'noy',
							'dek'
						],
						leap => [
							
						],
					},
					narrow => {
						nonleap => [
							'1',
							'2',
							'3',
							'4',
							'5',
							'6',
							'7',
							'8',
							'9',
							'10',
							'11',
							'12'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'Yanvar',
							'Fevral',
							'Mart',
							'Aprel',
							'May',
							'İyun',
							'İyul',
							'Avqust',
							'Sentyabr',
							'Oktyabr',
							'Noyabr',
							'Dekabr'
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
						mon => 'B.E.',
						tue => 'Ç.A.',
						wed => 'Ç.',
						thu => 'C.A.',
						fri => 'C.',
						sat => 'Ş.',
						sun => 'B.'
					},
					narrow => {
						mon => '1',
						tue => '2',
						wed => '3',
						thu => '4',
						fri => '5',
						sat => '6',
						sun => '7'
					},
					short => {
						mon => 'B.E.',
						tue => 'Ç.A.',
						wed => 'Ç.',
						thu => 'C.A.',
						fri => 'C.',
						sat => 'Ş.',
						sun => 'B.'
					},
					wide => {
						mon => 'bazar ertəsi',
						tue => 'çərşənbə axşamı',
						wed => 'çərşənbə',
						thu => 'cümə axşamı',
						fri => 'cümə',
						sat => 'şənbə',
						sun => 'bazar'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'B.E.',
						tue => 'Ç.A.',
						wed => 'Ç.',
						thu => 'C.A.',
						fri => 'C.',
						sat => 'Ş.',
						sun => 'B.'
					},
					narrow => {
						mon => '1',
						tue => '2',
						wed => '3',
						thu => '4',
						fri => '5',
						sat => '6',
						sun => '7'
					},
					short => {
						mon => 'B.E.',
						tue => 'Ç.A.',
						wed => 'Ç.',
						thu => 'C.A.',
						fri => 'C.',
						sat => 'Ş.',
						sun => 'B.'
					},
					wide => {
						mon => 'bazar ertəsi',
						tue => 'çərşənbə axşamı',
						wed => 'çərşənbə',
						thu => 'cümə axşamı',
						fri => 'cümə',
						sat => 'şənbə',
						sun => 'bazar'
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
					abbreviated => {0 => '1-ci kv.',
						1 => '2-ci kv.',
						2 => '3-cü kv.',
						3 => '4-cü kv.'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1-ci kvartal',
						1 => '2-ci kvartal',
						2 => '3-cü kvartal',
						3 => '4-cü kvartal'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => '1-ci kv.',
						1 => '2-ci kv.',
						2 => '3-cü kv.',
						3 => '4-cü kv.'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1-ci kvartal',
						1 => '2-ci kvartal',
						2 => '3-cü kvartal',
						3 => '4-cü kvartal'
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
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 1900;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'night2' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night2' if $time >= 0
						&& $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'evening1' if $time >= 1700
						&& $time < 1900;
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
					return 'evening1' if $time >= 1700
						&& $time < 1900;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'night2' if $time >= 0
						&& $time < 400;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'morning2' if $time >= 600
						&& $time < 1200;
					return 'night2' if $time >= 0
						&& $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 600;
					return 'night1' if $time >= 1900
						&& $time < 2400;
					return 'evening1' if $time >= 1700
						&& $time < 1900;
					return 'afternoon1' if $time >= 1200
						&& $time < 1700;
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
					'midnight' => q{gecəyarı},
					'night2' => q{gecə},
					'night1' => q{axşam},
					'noon' => q{günorta},
					'morning1' => q{sübh},
					'morning2' => q{səhər},
					'pm' => q{PM},
					'am' => q{AM},
					'evening1' => q{axşamüstü},
					'afternoon1' => q{gündüz},
				},
				'wide' => {
					'morning2' => q{səhər},
					'night1' => q{axşam},
					'morning1' => q{sübh},
					'noon' => q{günorta},
					'night2' => q{gecə},
					'midnight' => q{gecəyarı},
					'afternoon1' => q{gündüz},
					'evening1' => q{axşamüstü},
					'am' => q{AM},
					'pm' => q{PM},
				},
				'narrow' => {
					'evening1' => q{axşamüstü},
					'afternoon1' => q{gündüz},
					'am' => q{a},
					'pm' => q{p},
					'morning2' => q{səhər},
					'night2' => q{gecə},
					'midnight' => q{gecəyarı},
					'noon' => q{g},
					'night1' => q{axşam},
					'morning1' => q{sübh},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'morning2' => q{səhər},
					'morning1' => q{sübh},
					'night1' => q{axşam},
					'noon' => q{günorta},
					'night2' => q{gecə},
					'midnight' => q{gecəyarı},
					'am' => q{AM},
					'pm' => q{PM},
					'afternoon1' => q{gündüz},
					'evening1' => q{axşamüstü},
				},
				'wide' => {
					'afternoon1' => q{gündüz},
					'evening1' => q{axşamüstü},
					'am' => q{AM},
					'pm' => q{PM},
					'morning2' => q{səhər},
					'noon' => q{günorta},
					'night1' => q{axşam},
					'morning1' => q{sübh},
					'night2' => q{gecə},
					'midnight' => q{gecəyarı},
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
				'0' => 'e.ə.',
				'1' => 'b.e.'
			},
			wide => {
				'0' => 'eramızdan əvvəl',
				'1' => 'eramız'
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
			'full' => q{G d MMMM y, EEEE},
			'long' => q{G d MMMM, y},
			'medium' => q{G d MMM y},
			'short' => q{GGGGG dd.MM.y},
		},
		'gregorian' => {
			'full' => q{d MMMM y, EEEE},
			'long' => q{d MMMM y},
			'medium' => q{d MMM y},
			'short' => q{dd.MM.yy},
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
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			E => q{ccc},
			Ed => q{d, E},
			Gy => q{G y},
			GyMMM => q{G MMM y},
			GyMMMEd => q{G d MMM y, E},
			GyMMMd => q{G d MMM y},
			M => q{L},
			MEd => q{dd.MM, E},
			MMM => q{LLL},
			MMMEd => q{d MMM, E},
			MMMMd => q{MMMM d},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			d => q{d},
			y => q{G y},
			yyyy => q{G y},
			yyyyM => q{GGGGG MM y},
			yyyyMEd => q{GGGGG dd.MM.y, E},
			yyyyMMM => q{G MMM y},
			yyyyMMMEd => q{G d MMM y, E},
			yyyyMMMM => q{G y MMMM},
			yyyyMMMd => q{G d MMM y},
			yyyyMd => q{GGGGG dd.MM.y},
			yyyyQQQ => q{G y QQQ},
			yyyyQQQQ => q{G y QQQQ},
		},
		'gregorian' => {
			E => q{ccc},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{d E},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{G y},
			GyMMM => q{G MMM y},
			GyMMMEd => q{G d MMM y, E},
			GyMMMd => q{G d MMM y},
			H => q{HH},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			Hmsv => q{HH:mm:ss v},
			Hmv => q{HH:mm v},
			M => q{L},
			MEd => q{dd.MM, E},
			MMM => q{LLL},
			MMMEd => q{d MMM, E},
			MMMMd => q{MMMM d},
			MMMd => q{d MMM},
			Md => q{dd.MM},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			ms => q{mm:ss},
			y => q{y},
			yM => q{MM.y},
			yMEd => q{dd.MM.y, E},
			yMMM => q{MMM y},
			yMMMEd => q{d MMM y, E},
			yMMMM => q{y MMMM},
			yMMMd => q{d MMM y},
			yMd => q{dd.MM.y},
			yQQQ => q{y QQQ},
			yQQQQ => q{y QQQQ},
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
				M => q{MM–MM},
			},
			MEd => {
				M => q{dd.MM, E – dd.MM, E},
				d => q{dd.MM, E – dd.MM, E},
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
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
			},
			d => {
				d => q{d–d},
			},
			fallback => '{0} – {1}',
			y => {
				y => q{G y–y},
			},
			yM => {
				M => q{GGGGG MM/y – MM/y},
				y => q{GGGGG MM/y – MM/y},
			},
			yMEd => {
				M => q{GGGGG dd/MM/y , E – dd/MM/y, E},
				d => q{GGGGG dd/MM/y , E – dd/MM/y, E},
				y => q{GGGGG dd/MM/y , E – dd/MM/y, E},
			},
			yMMM => {
				M => q{G MMM–MMM y},
				y => q{G MMM y – MMM y},
			},
			yMMMEd => {
				M => q{G d MMM y, E – d MMM, E},
				d => q{G d MMM y, E – d MMM, E},
				y => q{G d MMM y, E – d MMM y, E},
			},
			yMMMM => {
				M => q{G MMMM y –MMMM},
				y => q{G MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{G d MMM y – d MMM},
				d => q{G d–d MMM y},
				y => q{G d MMM y – d MMM y},
			},
			yMd => {
				M => q{GGGGG dd/MM/y – dd/MM/y},
				d => q{GGGGG dd/MM/y – dd/MM/y},
				y => q{GGGGG dd/MM/y – dd/MM/y},
			},
		},
		'gregorian' => {
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
				M => q{dd.MM, E – dd.MM, E},
				d => q{dd.MM, E – dd.MM, E},
			},
			MMM => {
				M => q{LLL–LLL},
			},
			MMMEd => {
				M => q{d MMM, E – d MMM, E},
				d => q{d MMM, E – d MMM, E},
			},
			MMMd => {
				M => q{d MMM – d MMM},
				d => q{d–d MMM},
			},
			Md => {
				M => q{dd.MM – dd.MM},
				d => q{dd.MM – dd.MM},
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
				M => q{MM.y – MM.y},
				y => q{MM.y – MM.y},
			},
			yMEd => {
				M => q{dd.MM.y, E – dd.MM.y, E},
				d => q{dd.MM.y, E – dd.MM.y, E},
				y => q{dd.MM.y, E – dd.MM.y, E},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{d MMM y, E – d MMM, E},
				d => q{d MMM y, E – d MMM, E},
				y => q{d MMM y, E – d MMM y, E},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d MMM y – d MMM},
				d => q{y MMM d–d},
				y => q{d MMM y – d MMM y},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y},
				d => q{dd.MM.y – dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
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
		regionFormat => q({0} Vaxtı),
		regionFormat => q({0} Yay Vaxtı),
		regionFormat => q({0} Standart Vaxtı),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q(Əfqanıstan Vaxtı),
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abican#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Akkra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Əddis Əbəbə#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Əlcəzair#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Əsmərə#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamako#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Banqui#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Bancul#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bissau#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantir#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brazzavil#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Bujumbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Qahirə#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Kasablanka#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Seuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Konakri#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar es Salam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Cibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Duala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#Əl Əyun#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Fritaun#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Qaboron#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Harare#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Yohanesburq#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Xartum#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kiqali#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinşasa#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Laqos#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Librevil#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lome#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luanda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbaşi#,
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
			exemplarCity => q#Moqadişu#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovia#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#Ncamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamey#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nouakşot#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Uqaduqu#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto-Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#San Tom#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripoli#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunis#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Vindhuk#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q(Mərkəzi Afrika Vaxtı),
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q(Şərqi Afrika Vaxtı),
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q(Cənubi Afrika Vaxtı),
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q(Qərbi Afrika Yay Vaxtı),
				'generic' => q(Qərbi Afrika Vaxtı),
				'standard' => q(Qərbi Afrika Standart Vaxtı),
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q(Alyaska Yay Vaxtı),
				'generic' => q(Alyaska Vaxtı),
				'standard' => q(Alyaska Standart Vaxtı),
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q(Amazon Yay Vaxtı),
				'generic' => q(Amazon Vaxtı),
				'standard' => q(Amazon Standart Vaxtı),
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Ankorac#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Angilya#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antiqua#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguayna#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#Rioxa#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio Qalyeqos#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Salta#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San Xuan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#San Luis#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tukuman#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Uşuaya#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunsion#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahiya#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belem' => {
			exemplarCity => q#Belem#,
		},
		'America/Belize' => {
			exemplarCity => q#Beliz#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blank-Sablon#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Boa Vista#,
		},
		'America/Bogota' => {
			exemplarCity => q#Boqota#,
		},
		'America/Boise' => {
			exemplarCity => q#Boyse#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buenos Ayres#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Kembric Körfəzi#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Kampo Qrande#,
		},
		'America/Cancun' => {
			exemplarCity => q#Kankun#,
		},
		'America/Caracas' => {
			exemplarCity => q#Karakas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Katamarka#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Kayen#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kayman#,
		},
		'America/Chicago' => {
			exemplarCity => q#Cikaqo#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Çihuahua#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikokan#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Kordoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kosta Rika#,
		},
		'America/Creston' => {
			exemplarCity => q#Kreston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Kuyaba#,
		},
		'America/Curacao' => {
			exemplarCity => q#Kurasao#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Danmarkşavn#,
		},
		'America/Dawson' => {
			exemplarCity => q#Douson#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Douson Krik#,
		},
		'America/Denver' => {
			exemplarCity => q#Denver#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detroyt#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmondton#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#İrunepe#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvador#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fortaleza#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Qleys Körfəzi#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuuk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Quz Körfəzi#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Qrand Turk#,
		},
		'America/Grenada' => {
			exemplarCity => q#Qrenada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Qvadelupa#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Qvatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Quayakil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Qayana#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifaks#,
		},
		'America/Havana' => {
			exemplarCity => q#Havana#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Hermosilo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Noks#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marenqo#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Pitersburq#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vivey#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vinsen#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Vinamak#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#İndianapolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#İnuvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#İqaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Yamayka#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Jujuy#,
		},
		'America/Juneau' => {
			exemplarCity => q#Cuno#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Montiçello#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kralendik#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La Pas#,
		},
		'America/Lima' => {
			exemplarCity => q#Lima#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Los Anceles#,
		},
		'America/Louisville' => {
			exemplarCity => q#Luisvil#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Aşağı Prins Kvartalı#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maseyo#,
		},
		'America/Managua' => {
			exemplarCity => q#Manaqua#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaus#,
		},
		'America/Marigot' => {
			exemplarCity => q#Mariqot#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinik#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazaltan#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendoza#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menomini#,
		},
		'America/Merida' => {
			exemplarCity => q#Merida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexiko#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Mikelon#,
		},
		'America/Moncton' => {
			exemplarCity => q#Monkton#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Monterey#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Montevideo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Monserat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nassau#,
		},
		'America/New_York' => {
			exemplarCity => q#Nyu York#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nipiqon#,
		},
		'America/Nome' => {
			exemplarCity => q#Nom#,
		},
		'America/Noronha' => {
			exemplarCity => q#Noronya#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Şimali Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Mərkəz, Şimal Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#Nyu Salem#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#Ocinaqa#,
		},
		'America/Panama' => {
			exemplarCity => q#Panama#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Panqnirtanq#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Paramaribo#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Feniks#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Port-o-Prins#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#İspan Limanı#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Porto Velyo#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Puerto Riko#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Reyni Çayı#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rankin Girişi#,
		},
		'America/Recife' => {
			exemplarCity => q#Resif#,
		},
		'America/Regina' => {
			exemplarCity => q#Recina#,
		},
		'America/Resolute' => {
			exemplarCity => q#Rezolyut#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Rio Branko#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarem#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santyaqo#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo Dominqo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#San Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Skoresbisund#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#San Bartolomey#,
		},
		'America/St_Johns' => {
			exemplarCity => q#Sent Cons#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#San Kits#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#San Lüsiya#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#San Tomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#San Vinsent#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#Svift Kurent#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tequsiqalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Tul#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#İldırım Körfəzi#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tixuana#,
		},
		'America/Toronto' => {
			exemplarCity => q#Toronto#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tortola#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vankuver#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Uaythors#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Vinipeq#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Yakutat#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Yelounayf#,
		},
		'America_Central' => {
			long => {
				'daylight' => q(Şimali Mərkəzi Amerika Yay Vaxtı),
				'generic' => q(Şimali Mərkəzi Amerika Vaxtı),
				'standard' => q(Şimali Mərkəzi Amerika Standart Vaxtı),
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q(Şimali Şərqi Amerika Yay Vaxtı),
				'generic' => q(Şimali Şərqi Amerika Vaxtı),
				'standard' => q(Şimali Şərqi Amerika Standart Vaxtı),
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q(Şimali Dağlıq Amerika Yay Vaxtı),
				'generic' => q(Şimali Dağlıq Amerika Vaxtı),
				'standard' => q(Şimali Dağlıq Amerika Standart Vaxtı),
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q(Şimali Amerika Sakit Okean Yay Vaxtı),
				'generic' => q(Şimali Amerika Sakit Okean Vaxtı),
				'standard' => q(Şimali Amerika Sakit Okean Standart Vaxtı),
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Keysi#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Deyvis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’Urvil#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Makuari#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mouson#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#Mak Murdo#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Palmer#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rothera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Syova#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Troll#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Vostok#,
		},
		'Apia' => {
			long => {
				'daylight' => q(Apia Yay Vaxtı),
				'generic' => q(Apia Vaxtı),
				'standard' => q(Apia Standart Vaxtı),
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q(Ərəbistan Yay Vaxtı),
				'generic' => q(Ərəbistan Vaxtı),
				'standard' => q(Ərəbistan Standart Vaxtı),
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Lonqyir#,
		},
		'Argentina' => {
			long => {
				'daylight' => q(Argentina Yay Vaxtı),
				'generic' => q(Argentina Vaxtı),
				'standard' => q(Argentina Standart Vaxtı),
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q(Qərbi Argentina Yay Vaxtı),
				'generic' => q(Qərbi Argentina Vaxtı),
				'standard' => q(Qərbi Argentina Standart Vaxtı),
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q(Ermənistan Yay Vaxtı),
				'generic' => q(Ermənistan Vaxtı),
				'standard' => q(Ermənistan Standart Vaxtı),
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Aden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almatı#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Amman#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadır#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Aşqabat#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bağdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bəhreyn#,
		},
		'Asia/Baku' => {
			exemplarCity => q#Bakı#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Banqkok#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Beyrut#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bişkek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunei#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kolkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Çita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Çoybalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Dəməşq#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dəkkə#,
		},
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubay#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Düşənbə#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Qəza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Honq Konq#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Hovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#İrkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Cakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Cayapura#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Yerusəlim#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kabil#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamçatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karaçi#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Katmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Xandıqa#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnoyarsk#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kuçinq#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Küveyt#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Makao#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Maqadan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makasar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manila#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muskat#,
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
			exemplarCity => q#Pnom Pen#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pontianak#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pxenyan#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Qatar#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Qızılorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Ranqun#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riyad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho Şi Min#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Saxalin#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#Səmərqənd#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Seul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Şanxay#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Sinqapur#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolımsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipei#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Daşkənd#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Tehran#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimphu#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokyo#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulanbator#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumçi#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Ust-Nera#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#Vyentyan#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Yakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Yekaterinburq#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Yerevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q(Atlantik Yay Vaxtı),
				'generic' => q(Atlantik Vaxt),
				'standard' => q(Atlantik Standart Vaxt),
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azor#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermuda#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanar#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kape Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Farer#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeyra#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykyavik#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Cənubi Corciya#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Müqəddəs Yelena#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#Stenli#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaida#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brisbeyn#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Broken Hill#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Kuriye#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Darvin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Yukla#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hobart#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Lindeman#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lord Hau#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Melburn#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Perth#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sidney#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q(Mərkəzi Avstraliya Yay Vaxtı),
				'generic' => q(Mərkəzi Avstraliya Vaxtı),
				'standard' => q(Mərkəzi Avstraliya Standart Vaxtı),
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q(Mərkəzi Qərbi Avstraliya Yay Vaxtı),
				'generic' => q(Mərkəzi Qərbi Avstraliya Vaxtı),
				'standard' => q(Mərkəzi Qərbi Avstraliya Standart Vaxtı),
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q(Şərqi Avstraliya Yay Vaxtı),
				'generic' => q(Şərqi Avstraliya Vaxtı),
				'standard' => q(Şərqi Avstraliya Standart Vaxtı),
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q(Qərbi Avstraliya Yay Vaxtı),
				'generic' => q(Qərbi Avstraliya Vaxtı),
				'standard' => q(Qərbi Avstraliya Standart Vaxtı),
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q(Azərbaycan Yay Vaxtı),
				'generic' => q(Azərbaycan Vaxtı),
				'standard' => q(Azərbaycan Standart Vaxtı),
			},
		},
		'Azores' => {
			long => {
				'daylight' => q(Azor Yay Vaxtı),
				'generic' => q(Azor Vaxtı),
				'standard' => q(Azor Standart Vaxtı),
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q(Banqladeş Yay Vaxtı),
				'generic' => q(Banqladeş Vaxtı),
				'standard' => q(Banqladeş Standart Vaxtı),
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q(Butan Vaxtı),
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q(Boliviya Vaxtı),
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q(Braziliya Yay Vaxtı),
				'generic' => q(Braziliya Vaxtı),
				'standard' => q(Braziliya Standart Vaxtı),
			},
		},
		'Brunei' => {
			long => {
				'standard' => q(Brunei Darussalam vaxtı),
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q(Kape Verde Yay Vaxtı),
				'generic' => q(Kape Verde Vaxtı),
				'standard' => q(Kape Verde Standart Vaxtı),
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q(Çamorro Vaxtı),
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q(Çatham Yay Vaxtı),
				'generic' => q(Çatham Vaxtı),
				'standard' => q(Çatham Standart Vaxtı),
			},
		},
		'Chile' => {
			long => {
				'daylight' => q(Çili Yay Vaxtı),
				'generic' => q(Çili Vaxtı),
				'standard' => q(Çili Standart Vaxtı),
			},
		},
		'China' => {
			long => {
				'daylight' => q(Çin Yay Vaxtı),
				'generic' => q(Çin Vaxtı),
				'standard' => q(Çin Standart Vaxtı),
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q(Çoybalsan Yay Vaxtı),
				'generic' => q(Çoybalsan Vaxtı),
				'standard' => q(Çoybalsan Standart Vaxtı),
			},
		},
		'Christmas' => {
			long => {
				'standard' => q(Milad Adası Vaxtı),
			},
		},
		'Cocos' => {
			long => {
				'standard' => q(Kokos Adaları Vaxtı),
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q(Kolumbiya Yay Vaxtı),
				'generic' => q(Kolumbiya Vaxtı),
				'standard' => q(Kolumbiya Standart Vaxtı),
			},
		},
		'Cook' => {
			long => {
				'daylight' => q(Kuk Adaları Yarım Yay Vaxtı),
				'generic' => q(Kuk Adaları Vaxtı),
				'standard' => q(Kuk Adaları Standart Vaxtı),
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q(Kuba Yay Vaxtı),
				'generic' => q(Kuba Vaxtı),
				'standard' => q(Kuba Standart Vaxtı),
			},
		},
		'Davis' => {
			long => {
				'standard' => q(Devis Vaxtı),
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q(Dümon-d’Ürvil Vaxtı),
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q(Şərqi Timor Vaxtı),
			},
		},
		'Easter' => {
			long => {
				'daylight' => q(Pasxa Adası Yay Vaxtı),
				'generic' => q(Pasxa Adası Vaxtı),
				'standard' => q(Pasxa Adası Standart Vaxtı),
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q(Ekvador Vaxtı),
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Naməlum Şəhər#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Afina#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belqrad#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlin#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brüssel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Buxarest#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapeşt#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Busingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kişinyov#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q(İrlandiya Yay Vaxtı),
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltar#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Gernzey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Men Adası#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Cersi#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kalininqrad#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiyev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Lyublyana#,
		},
		'Europe/London' => {
			exemplarCity => q#London#,
			long => {
				'daylight' => q(Britaniya Yay Vaxtı),
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lüksemburq#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrid#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Malta#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariham#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#Minsk#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskva#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#Oslo#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Paris#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podqoritsa#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praqa#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riqa#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roma#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Marino#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarayevo#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferopol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopye#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofia#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Stokholm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallin#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Ujgorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduts#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Vyana#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnyus#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volqoqrad#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varşava#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Zaqreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Zaporojye#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Sürix#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q(Mərkəzi Avropa Yay Vaxtı),
				'generic' => q(Mərkəzi Avropa Vaxtı),
				'standard' => q(Mərkəzi Avropa Standart Vaxtı),
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q(Şərqi Avropa Yay Vaxtı),
				'generic' => q(Şərqi Avropa Vaxtı),
				'standard' => q(Şərqi Avropa Standart Vaxtı),
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q(Kənar Şərqi Avropa Vaxtı),
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q(Qərbi Avropa Yay Vaxtı),
				'generic' => q(Qərbi Avropa Vaxtı),
				'standard' => q(Qərbi Avropa Standart Vaxtı),
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q(Folklend Adaları Yay Vaxtı),
				'generic' => q(Folklend Adaları Vaxtı),
				'standard' => q(Folklend Adaları Standart Vaxtı),
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q(Fici Yay Vaxtı),
				'generic' => q(Fici Vaxtı),
				'standard' => q(Fici Standart Vaxtı),
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q(Fransız Qvianası Vaxtı),
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q(Fransız Cənubi və Antarktik Vaxtı),
			},
		},
		'GMT' => {
			long => {
				'standard' => q(Qrinviç Orta Vaxtı),
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q(Qalapaqos Vaxtı),
			},
		},
		'Gambier' => {
			long => {
				'standard' => q(Qambier Vaxtı),
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q(Gurcüstan Yay Vaxtı),
				'generic' => q(Gurcüstan Vaxtı),
				'standard' => q(Gurcüstan Standart Vaxtı),
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q(Gilbert Adaları Vaxtı),
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q(Şərqi Qrenlandiya Yay Vaxtı),
				'generic' => q(Şərqi Qrenlandiya Vaxtı),
				'standard' => q(Şərqi Qrenlandiya Standart Vaxtı),
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q(Qərbi Qrenlandiya Yay Vaxtı),
				'generic' => q(Qərbi Qrenlandiya Vaxtı),
				'standard' => q(Qərbi Qrenlandiya Standart Vaxtı),
			},
		},
		'Gulf' => {
			long => {
				'standard' => q(Körfəz Vaxtı),
			},
		},
		'Guyana' => {
			long => {
				'standard' => q(Qayana Vaxtı),
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q(Havay-Aleut Yay Vaxtı),
				'generic' => q(Havay-Aleut Vaxtı),
				'standard' => q(Havay-Aleut Standart Vaxtı),
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q(Honq Konq Yay Vaxtı),
				'generic' => q(Honq Konq Vaxtı),
				'standard' => q(Honq Konq Standart Vaxtı),
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q(Hovd Yay Vaxtı),
				'generic' => q(Hovd Vaxtı),
				'standard' => q(Hovd Standart Vaxtı),
			},
		},
		'India' => {
			long => {
				'standard' => q(Hindistan Vaxtı),
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Çaqos#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#Milad#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokos#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komoro#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kergelen#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahe#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldiv#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Mavriki#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#Mayot#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Reunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q(Hind Okeanı Vaxtı),
			},
		},
		'Indochina' => {
			long => {
				'standard' => q(Hindçin Vaxtı),
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q(Mərkəzi İndoneziya Vaxtı),
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q(Şərqi İndoneziya Vaxtı),
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q(Qərbi İndoneziya Vaxtı),
			},
		},
		'Iran' => {
			long => {
				'daylight' => q(İran Yay Vaxtı),
				'generic' => q(İran Vaxtı),
				'standard' => q(İran Standart Vaxtı),
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q(İrkutsk Yay Vaxtı),
				'generic' => q(İrkutsk Vaxtı),
				'standard' => q(İrkutsk Standart Vaxtı),
			},
		},
		'Israel' => {
			long => {
				'daylight' => q(İsrail Yay Vaxtı),
				'generic' => q(İsrail Vaxtı),
				'standard' => q(İsrail Standart Vaxtı),
			},
		},
		'Japan' => {
			long => {
				'daylight' => q(Yaponiya Yay Vaxtı),
				'generic' => q(Yaponiya Vaxtı),
				'standard' => q(Yaponiya Standart Vaxtı),
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q(Şərqi Qazaxıstan Vaxtı),
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q(Qərbi Qazaxıstan Vaxtı),
			},
		},
		'Korea' => {
			long => {
				'daylight' => q(Koreya Yay Vaxtı),
				'generic' => q(Koreya Vaxtı),
				'standard' => q(Koreya Standart Vaxtı),
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q(Korse Vaxtı),
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q(Krasnoyarsk Yay Vaxtı),
				'generic' => q(Krasnoyarsk Vaxtı),
				'standard' => q(Krasnoyarsk Standart Vaxtı),
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q(Qırğızıstan Vaxtı),
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q(Layn Adaları Vaxtı),
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q(Lord Hau Yay vaxtı),
				'generic' => q(Lord Hau Vaxtı),
				'standard' => q(Lord Hau Standart Vaxtı),
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q(Makari Adası Vaxtı),
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q(Maqadan Yay Vaxtı),
				'generic' => q(Maqadan Vaxtı),
				'standard' => q(Maqadan Standart Vaxtı),
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q(Malayziya Vaxtı),
			},
		},
		'Maldives' => {
			long => {
				'standard' => q(Maldiv Vaxtı),
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q(Markesas Vaxtı),
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q(Marşal Adaları Vaxtı),
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q(Mavriki Yay Vaxtı),
				'generic' => q(Mavriki Vaxtı),
				'standard' => q(Mavriki Standart Vaxtı),
			},
		},
		'Mawson' => {
			long => {
				'standard' => q(Mouson Vaxtı),
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q(Şimal-Qərbi Meksika Yay Vaxtı),
				'generic' => q(Şimal-Qərbi Meksika Vaxtı),
				'standard' => q(Şimal-Qərbi Meksika Standart Vaxtı),
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q(Meksika Sakit Okean Yay Vaxtı),
				'generic' => q(Meksika Sakit Okean Vaxtı),
				'standard' => q(Meksika Sakit Okean Standart Vaxtı),
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q(Ulanbator Yay Vaxtı),
				'generic' => q(Ulanbator Vaxtı),
				'standard' => q(Ulanbator Standart Vaxtı),
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q(Moskva Yay vaxtı),
				'generic' => q(Moskva Vaxtı),
				'standard' => q(Moskva Standart Vaxtı),
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q(Myanma Vaxtı),
			},
		},
		'Nauru' => {
			long => {
				'standard' => q(Nauru Vaxtı),
			},
		},
		'Nepal' => {
			long => {
				'standard' => q(Nepal vaxtı),
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q(Yeni Kaledoniya Yay Vaxtı),
				'generic' => q(Yeni Kaledoniya Vaxtı),
				'standard' => q(Yeni Kaledoniya Standart Vaxtı),
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q(Yeni Zelandiya Yay Vaxtı),
				'generic' => q(Yeni Zelandiya Vaxtı),
				'standard' => q(Yeni Zelandiya Standart Vaxtı),
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q(Nyufaundlend Yay Vaxtı),
				'generic' => q(Nyufaundlend Vaxtı),
				'standard' => q(Nyufaundlend Standart Vaxtı),
			},
		},
		'Niue' => {
			long => {
				'standard' => q(Niue Vaxtı),
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q(Norfolk Adası Vaxtı),
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q(Fernando de Noronya Yay Vaxtı),
				'generic' => q(Fernando de Noronya Vaxtı),
				'standard' => q(Fernando de Noronya Standart Vaxtı),
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q(Novosibirsk Yay Vaxtı),
				'generic' => q(Novosibirsk Vaxtı),
				'standard' => q(Novosibirsk Standart Vaxtı),
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q(Omsk Yay Vaxtı),
				'generic' => q(Omsk Vaxtı),
				'standard' => q(Omsk Standart Vaxtı),
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Apia#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Aukland#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Buqanvil#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Çatam#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Pasxa#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Efate#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderböri#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Fakaofo#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fici#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Qalapaqos#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Qambiyer#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Quadalkanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Quam#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Conston#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kirimati#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosraye#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kvajaleyn#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Macuro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markesas#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midvey#,
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
			exemplarCity => q#Noumea#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Paqo Paqo#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palau#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitkern#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Pohnpei#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Port Moresbi#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarotonqa#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saipan#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahiti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarava#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tonqapatu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Çuuk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Veyk#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Uollis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q(Pakistan Yay Vaxtı),
				'generic' => q(Pakistan Vaxtı),
				'standard' => q(Pakistan Standart vaxtı),
			},
		},
		'Palau' => {
			long => {
				'standard' => q(Palau Vaxtı),
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q(Papua Yeni Qvineya Vaxtı),
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q(Paraqvay Yay Vaxtı),
				'generic' => q(Paraqvay Vaxtı),
				'standard' => q(Paraqvay Standart Vaxtı),
			},
		},
		'Peru' => {
			long => {
				'daylight' => q(Peru Yay Vaxtı),
				'generic' => q(Peru Vaxtı),
				'standard' => q(Peru Standart Vaxtı),
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q(Filippin Yay Vaxtı),
				'generic' => q(Filippin Vaxtı),
				'standard' => q(Filippin Standart Vaxtı),
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q(Feniks Adaları Vaxtı),
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q(San Pier və Mikelon Yay Vaxtı),
				'generic' => q(San Pier və Mikelon Vaxtı),
				'standard' => q(San Pier və Mikelon Standart Vaxtı),
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q(Pitkern Vaxtı),
			},
		},
		'Ponape' => {
			long => {
				'standard' => q(Ponape Vaxtı),
			},
		},
		'Reunion' => {
			long => {
				'standard' => q(Reunion Vaxtı),
			},
		},
		'Rothera' => {
			long => {
				'standard' => q(Rotera Vaxtı),
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q(Saxalin Yay Vaxtı),
				'generic' => q(Saxalin Vaxtı),
				'standard' => q(Saxalin Standart Vaxtı),
			},
		},
		'Samara' => {
			long => {
				'daylight' => q(Samara yay vaxtı),
				'generic' => q(Samara vaxtı),
				'standard' => q(Samara standart vaxtı),
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q(Samoa Yay Vaxtı),
				'generic' => q(Samoa Vaxtı),
				'standard' => q(Samoa Standart Vaxtı),
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q(Seyşel Adaları Vaxtı),
			},
		},
		'Singapore' => {
			long => {
				'standard' => q(Sinqapur Vaxtı),
			},
		},
		'Solomon' => {
			long => {
				'standard' => q(Solomon Adaları Vaxtı),
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q(Cənubi Corciya Vaxtı),
			},
		},
		'Suriname' => {
			long => {
				'standard' => q(Surinam Vaxtı),
			},
		},
		'Syowa' => {
			long => {
				'standard' => q(Syova Vaxtı),
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q(Tahiti Vaxtı),
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q(Taybey Yay Vaxtı),
				'generic' => q(Taybey Vaxtı),
				'standard' => q(Taybey Standart Vaxtı),
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q(Tacikistan Vaxtı),
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q(Tokelau Vaxtı),
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q(Tonqa Yay Vaxtı),
				'generic' => q(Tonqa Vaxtı),
				'standard' => q(Tonqa Standart Vaxtı),
			},
		},
		'Truk' => {
			long => {
				'standard' => q(Çuuk Vaxtı),
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q(Türkmənistan Yay Vaxtı),
				'generic' => q(Türkmənistan Vaxtı),
				'standard' => q(Türkmənistan Standart Vaxtı),
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q(Tuvalu Vaxtı),
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q(Uruqvay Yay Vaxtı),
				'generic' => q(Uruqvay Vaxtı),
				'standard' => q(Uruqvay Standart Vaxtı),
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q(Özbəkistan Yay Vaxtı),
				'generic' => q(Özbəkistan Vaxtı),
				'standard' => q(Özbəkistan Standart Vaxtı),
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q(Vaunatu Yay Vaxtı),
				'generic' => q(Vanuatu Vaxtı),
				'standard' => q(Vanuatu Standart Vaxtı),
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q(Venesuela Vaxtı),
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q(Vladivostok Yay Vaxtı),
				'generic' => q(Vladivostok Vaxtı),
				'standard' => q(Vladivostok Standart Vaxtı),
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q(Volqoqrad Yay Vaxtı),
				'generic' => q(Volqoqrad Vaxtı),
				'standard' => q(Volqoqrad Standart Vaxtı),
			},
		},
		'Vostok' => {
			long => {
				'standard' => q(Vostok Vaxtı),
			},
		},
		'Wake' => {
			long => {
				'standard' => q(Ueyk Vaxtı),
			},
		},
		'Wallis' => {
			long => {
				'standard' => q(Uollis və Futuna Vaxtı),
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q(Yakutsk Yay Vaxtı),
				'generic' => q(Yakutsk Vaxtı),
				'standard' => q(Yakutsk Standart Vaxtı),
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q(Yekaterinburq Yay Vaxtı),
				'generic' => q(Yekaterinburq Vaxtı),
				'standard' => q(Yekaterinburq Standart Vaxtı),
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
