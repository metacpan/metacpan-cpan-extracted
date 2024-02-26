=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Sk - Package for language Slovak

=cut

package Locale::CLDR::Locales::Sk;
# This file auto generated from Data\common\main\sk.xml
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
has 'valid_algorithmic_formats' => (
    is => 'ro',
    isa => ArrayRef,
    init_arg => undef,
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-neuter','spellout-cardinal-feminine' ]},
);

has 'algorithmic_number_format_data' => (
    is => 'ro',
    isa => HashRef,
    init_arg => undef,
    default => sub {
        use bigfloat;
        return {
		'spellout-cardinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(mínus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nula),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← čiarka →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(jedna),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dve),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(dvadsať[­→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(tridsať[­→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(štyridsať[­→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(←←desiat[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine←­sto[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← tisíc[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{milión}few{milióny}other{miliónov})$[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{miliarda}few{miliardy}other{miliardov})$[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{bilión}few{bilióny}other{biliónov})$[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{biliarda}few{biliardy}other{biliardov})$[ →→]),
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
		'spellout-cardinal-masculine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(mínus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nula),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← čiarka →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(jeden),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dva),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(tri),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(štyri),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(päť),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(šesť),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(sedem),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(osem),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(deväť),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(desať),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(jedenásť),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(dvanásť),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(trinásť),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(štrnásť),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(pätnásť),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(šestnásť),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(sedemnásť),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(osemnásť),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(devätnásť),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(dvadsať[­→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(tridsať[­→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(štyridsať[­→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(←←desiat[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine←­sto[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← tisíc[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{milión}few{milióny}other{miliónov})$[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{miliarda}few{miliardy}other{miliardov})$[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{bilión}few{bilióny}other{biliónov})$[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{biliarda}few{biliardy}other{biliardov})$[ →→]),
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
		'spellout-cardinal-neuter' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(mínus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nula),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← čiarka →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(jedno),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(dve),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(dvadsať[­→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(tridsať[­→→]),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(štyridsať[­→→]),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(←←desiat[­→→]),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←%spellout-cardinal-feminine←­sto[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-feminine← tisíc[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{milión}few{milióny}other{miliónov})$[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{miliarda}few{miliardy}other{miliardov})$[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{bilión}few{bilióny}other{biliónov})$[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← $(cardinal,one{biliarda}few{biliardy}other{biliardov})$[ →→]),
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
					rule => q(=%spellout-cardinal-masculine=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
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
    } },
);

has 'display_name_language' => (
	is			=> 'ro',
	isa			=> CodeRef,
	init_arg	=> undef,
	default		=> sub {
		 sub {
			 my %languages = (
				'aa' => 'afarčina',
 				'ab' => 'abcházčina',
 				'ace' => 'acehčina',
 				'ach' => 'ačoli',
 				'ada' => 'adangme',
 				'ady' => 'adygejčina',
 				'ae' => 'avestčina',
 				'af' => 'afrikánčina',
 				'afh' => 'afrihili',
 				'agq' => 'aghem',
 				'ain' => 'ainčina',
 				'ak' => 'akančina',
 				'akk' => 'akkadčina',
 				'ale' => 'aleutčina',
 				'alt' => 'južná altajčina',
 				'am' => 'amharčina',
 				'an' => 'aragónčina',
 				'ang' => 'stará angličtina',
 				'ann' => 'obolo',
 				'anp' => 'angika',
 				'ar' => 'arabčina',
 				'ar_001' => 'arabčina (moderná štandardná)',
 				'arc' => 'aramejčina',
 				'arn' => 'mapudungun',
 				'arp' => 'arapažština',
 				'ars' => 'arabčina (nadždská)',
 				'arw' => 'arawačtina',
 				'as' => 'ásamčina',
 				'asa' => 'asu',
 				'ast' => 'astúrčina',
 				'atj' => 'atikamekwčina',
 				'av' => 'avarčina',
 				'awa' => 'awadhi',
 				'ay' => 'aymarčina',
 				'az' => 'azerbajdžančina',
 				'ba' => 'baškirčina',
 				'bal' => 'balúčtina',
 				'ban' => 'balijčina',
 				'bas' => 'basa',
 				'bax' => 'bamun',
 				'bbj' => 'ghomala',
 				'be' => 'bieloruština',
 				'bej' => 'bedža',
 				'bem' => 'bemba',
 				'bez' => 'bena',
 				'bfd' => 'bafut',
 				'bg' => 'bulharčina',
 				'bgc' => 'haryanvi',
 				'bgn' => 'západná balúčtina',
 				'bho' => 'bhódžpurčina',
 				'bi' => 'bislama',
 				'bik' => 'bikolčina',
 				'bin' => 'bini',
 				'bkm' => 'kom',
 				'bla' => 'siksika',
 				'bm' => 'bambarčina',
 				'bn' => 'bengálčina',
 				'bo' => 'tibetčina',
 				'br' => 'bretónčina',
 				'bra' => 'bradžčina',
 				'brx' => 'bodo',
 				'bs' => 'bosniačtina',
 				'bss' => 'akoose',
 				'bua' => 'buriatčina',
 				'bug' => 'bugiština',
 				'bum' => 'bulu',
 				'byn' => 'blin',
 				'byv' => 'medumba',
 				'ca' => 'katalánčina',
 				'cad' => 'kaddo',
 				'car' => 'karibčina',
 				'cay' => 'kajugčina',
 				'cch' => 'atsam',
 				'ccp' => 'čakma',
 				'ce' => 'čečenčina',
 				'ceb' => 'cebuánčina',
 				'cgg' => 'kiga',
 				'ch' => 'čamorčina',
 				'chb' => 'čibča',
 				'chg' => 'čagatajčina',
 				'chk' => 'chuuk',
 				'chm' => 'marijčina',
 				'chn' => 'činucký žargón',
 				'cho' => 'čoktčina',
 				'chp' => 'čipevajčina',
 				'chr' => 'čerokí',
 				'chy' => 'čejenčina',
 				'ckb' => 'kurdčina (sorání)',
 				'ckb@alt=menu' => 'kurdčina (centrálna)',
 				'clc' => 'chilcotin',
 				'co' => 'korzičtina',
 				'cop' => 'koptčina',
 				'cr' => 'krí',
 				'crg' => 'michif',
 				'crh' => 'krymská tatárčina',
 				'crj' => 'cree (juhovýchod)',
 				'crk' => 'plains cree',
 				'crl' => 'northern east cree',
 				'crm' => 'moose cree',
 				'crr' => 'karolínska algonkčina',
 				'crs' => 'seychelská kreolčina',
 				'cs' => 'čeština',
 				'csb' => 'kašubčina',
 				'csw' => 'swampy cree',
 				'cu' => 'cirkevná slovančina',
 				'cv' => 'čuvaština',
 				'cy' => 'waleština',
 				'da' => 'dánčina',
 				'dak' => 'dakotčina',
 				'dar' => 'darginčina',
 				'dav' => 'taita',
 				'de' => 'nemčina',
 				'de_AT' => 'nemčina (rakúska)',
 				'de_CH' => 'nemčina (švajčiarska spisovná)',
 				'del' => 'delawarčina',
 				'den' => 'slavé',
 				'dgr' => 'dogribčina',
 				'din' => 'dinkčina',
 				'dje' => 'zarma',
 				'doi' => 'dógrí',
 				'dsb' => 'dolnolužická srbčina',
 				'dua' => 'duala',
 				'dum' => 'stredná holandčina',
 				'dv' => 'maldivčina',
 				'dyo' => 'jola-fonyi',
 				'dyu' => 'ďula',
 				'dz' => 'dzongkha',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'eweština',
 				'efi' => 'efik',
 				'egy' => 'staroegyptčina',
 				'eka' => 'ekadžuk',
 				'el' => 'gréčtina',
 				'elx' => 'elamčina',
 				'en' => 'angličtina',
 				'en_AU' => 'angličtina (austrálska)',
 				'en_CA' => 'angličtina (kanadská)',
 				'en_GB' => 'angličtina (britská)',
 				'en_US' => 'angličtina (americká)',
 				'enm' => 'stredná angličtina',
 				'eo' => 'esperanto',
 				'es' => 'španielčina',
 				'es_419' => 'španielčina (latinskoamerická)',
 				'es_ES' => 'španielčina (európska)',
 				'es_MX' => 'španielčina (mexická)',
 				'et' => 'estónčina',
 				'eu' => 'baskičtina',
 				'ewo' => 'ewondo',
 				'fa' => 'perzština',
 				'fa_AF' => 'daríjčina',
 				'fan' => 'fangčina',
 				'fat' => 'fanti',
 				'ff' => 'fulbčina',
 				'fi' => 'fínčina',
 				'fil' => 'filipínčina',
 				'fj' => 'fidžijčina',
 				'fo' => 'faerčina',
 				'fon' => 'fončina',
 				'fr' => 'francúzština',
 				'fr_CA' => 'francúzština (kanadská)',
 				'fr_CH' => 'francúzština (švajčiarska)',
 				'frc' => 'francúzština (cajunská)',
 				'frm' => 'stredná francúzština',
 				'fro' => 'stará francúzština',
 				'frr' => 'severná frízština',
 				'frs' => 'východofrízština',
 				'fur' => 'friulčina',
 				'fy' => 'západná frízština',
 				'ga' => 'írčina',
 				'gaa' => 'ga',
 				'gag' => 'gagauzština',
 				'gay' => 'gayo',
 				'gba' => 'gbaja',
 				'gd' => 'škótska gaelčina',
 				'gez' => 'etiópčina',
 				'gil' => 'kiribatčina',
 				'gl' => 'galícijčina',
 				'gmh' => 'stredná horná nemčina',
 				'gn' => 'guaraníjčina',
 				'goh' => 'stará horná nemčina',
 				'gon' => 'góndčina',
 				'gor' => 'gorontalo',
 				'got' => 'gótčina',
 				'grb' => 'grebo',
 				'grc' => 'starogréčtina',
 				'gsw' => 'nemčina (švajčiarska)',
 				'gu' => 'gudžarátčina',
 				'guz' => 'gusii',
 				'gv' => 'mančina',
 				'gwi' => 'kučinčina',
 				'ha' => 'hauština',
 				'hai' => 'haida',
 				'haw' => 'havajčina',
 				'hax' => 'haida (juh)',
 				'he' => 'hebrejčina',
 				'hi' => 'hindčina',
 				'hi_Latn@alt=variant' => 'hingliš',
 				'hil' => 'hiligajnončina',
 				'hit' => 'chetitčina',
 				'hmn' => 'hmongčina',
 				'ho' => 'hiri motu',
 				'hr' => 'chorvátčina',
 				'hsb' => 'hornolužická srbčina',
 				'ht' => 'haitská kreolčina',
 				'hu' => 'maďarčina',
 				'hup' => 'hupčina',
 				'hur' => 'halkomelem',
 				'hy' => 'arménčina',
 				'hz' => 'herero',
 				'ia' => 'interlingua',
 				'iba' => 'ibančina',
 				'ibb' => 'ibibio',
 				'id' => 'indonézština',
 				'ie' => 'interlingue',
 				'ig' => 'igboština',
 				'ii' => 's’čchuanská iovčina',
 				'ik' => 'inupik',
 				'ikt' => 'inuktitut (západná Kanada)',
 				'ilo' => 'ilokánčina',
 				'inh' => 'inguština',
 				'io' => 'ido',
 				'is' => 'islandčina',
 				'it' => 'taliančina',
 				'iu' => 'inuktitut',
 				'ja' => 'japončina',
 				'jbo' => 'lojban',
 				'jgo' => 'ngomba',
 				'jmc' => 'mašame',
 				'jpr' => 'židovská perzština',
 				'jrb' => 'židovská arabčina',
 				'jv' => 'jávčina',
 				'ka' => 'gruzínčina',
 				'kaa' => 'karakalpačtina',
 				'kab' => 'kabylčina',
 				'kac' => 'kačjinčina',
 				'kaj' => 'jju',
 				'kam' => 'kamba',
 				'kaw' => 'kawi',
 				'kbd' => 'kabardčina',
 				'kbl' => 'kanembu',
 				'kcg' => 'tyap',
 				'kde' => 'makonde',
 				'kea' => 'kapverdčina',
 				'kfo' => 'koro',
 				'kg' => 'kongčina',
 				'kgp' => 'kaingang',
 				'kha' => 'khasijčina',
 				'kho' => 'chotančina',
 				'khq' => 'západná songhajčina',
 				'ki' => 'kikujčina',
 				'kj' => 'kuaňama',
 				'kk' => 'kazaština',
 				'kkj' => 'kako',
 				'kl' => 'grónčina',
 				'kln' => 'kalendžin',
 				'km' => 'khmérčina',
 				'kmb' => 'kimbundu',
 				'kn' => 'kannadčina',
 				'ko' => 'kórejčina',
 				'koi' => 'komi-permiačtina',
 				'kok' => 'konkánčina',
 				'kos' => 'kusaie',
 				'kpe' => 'kpelle',
 				'kr' => 'kanurijčina',
 				'krc' => 'karačajevsko-balkarčina',
 				'krl' => 'karelčina',
 				'kru' => 'kuruchčina',
 				'ks' => 'kašmírčina',
 				'ksb' => 'šambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kolínčina',
 				'ku' => 'kurdčina',
 				'kum' => 'kumyčtina',
 				'kut' => 'kutenajčina',
 				'kv' => 'komijčina',
 				'kw' => 'kornčina',
 				'kwk' => 'kwakʼwala',
 				'ky' => 'kirgizština',
 				'la' => 'latinčina',
 				'lad' => 'židovská španielčina',
 				'lag' => 'langi',
 				'lah' => 'lahandčina',
 				'lam' => 'lamba',
 				'lb' => 'luxemburčina',
 				'lez' => 'lezginčina',
 				'lg' => 'gandčina',
 				'li' => 'limburčina',
 				'lil' => 'lillooet',
 				'lkt' => 'lakotčina',
 				'ln' => 'lingalčina',
 				'lo' => 'laoština',
 				'lol' => 'mongo',
 				'lou' => 'kreolčina (Louisiana)',
 				'loz' => 'lozi',
 				'lrc' => 'severné luri',
 				'lsm' => 'saamia',
 				'lt' => 'litovčina',
 				'lu' => 'lubčina (katanžská)',
 				'lua' => 'lubčina (luluánska)',
 				'lui' => 'luiseňo',
 				'lun' => 'lunda',
 				'luo' => 'luo',
 				'lus' => 'mizorámčina',
 				'luy' => 'luhja',
 				'lv' => 'lotyština',
 				'mad' => 'madurčina',
 				'maf' => 'mafa',
 				'mag' => 'magadhčina',
 				'mai' => 'maithilčina',
 				'mak' => 'makasarčina',
 				'man' => 'mandingo',
 				'mas' => 'masajčina',
 				'mde' => 'maba',
 				'mdf' => 'mokšiančina',
 				'mdr' => 'mandarčina',
 				'men' => 'mendejčina',
 				'mer' => 'meru',
 				'mfe' => 'maurícijská kreolčina',
 				'mg' => 'malgaština',
 				'mga' => 'stredná írčina',
 				'mgh' => 'makua-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'marshallčina',
 				'mi' => 'maorijčina',
 				'mic' => 'mikmakčina',
 				'min' => 'minangkabaučina',
 				'mk' => 'macedónčina',
 				'ml' => 'malajálamčina',
 				'mn' => 'mongolčina',
 				'mnc' => 'mandžuština',
 				'mni' => 'manípurčina',
 				'moe' => 'innu-aimunčina',
 				'moh' => 'mohawkčina',
 				'mos' => 'mossi',
 				'mr' => 'maráthčina',
 				'ms' => 'malajčina',
 				'mt' => 'maltčina',
 				'mua' => 'mundang',
 				'mul' => 'viaceré jazyky',
 				'mus' => 'kríkčina',
 				'mwl' => 'mirandčina',
 				'mwr' => 'marwari',
 				'my' => 'barmčina',
 				'mye' => 'myene',
 				'myv' => 'erzjančina',
 				'mzn' => 'mázandaránčina',
 				'na' => 'nauruština',
 				'nap' => 'neapolčina',
 				'naq' => 'nama',
 				'nb' => 'nórčina (bokmal)',
 				'nd' => 'ndebelčina (severná)',
 				'nds' => 'dolná nemčina',
 				'nds_NL' => 'dolná saština',
 				'ne' => 'nepálčina',
 				'new' => 'nevárčina',
 				'ng' => 'ndonga',
 				'nia' => 'niasánčina',
 				'niu' => 'niueština',
 				'nl' => 'holandčina',
 				'nl_BE' => 'flámčina',
 				'nmg' => 'kwasio',
 				'nn' => 'nórčina (nynorsk)',
 				'nnh' => 'ngiemboon',
 				'no' => 'nórčina',
 				'nog' => 'nogajčina',
 				'non' => 'stará nórčina',
 				'nqo' => 'n’ko',
 				'nr' => 'ndebelčina (južná)',
 				'nso' => 'sothčina (severná)',
 				'nus' => 'nuer',
 				'nv' => 'navaho',
 				'nwc' => 'klasická nevárčina',
 				'ny' => 'ňandža',
 				'nym' => 'ňamwezi',
 				'nyn' => 'ňankole',
 				'nyo' => 'ňoro',
 				'nzi' => 'nzima',
 				'oc' => 'okcitánčina',
 				'oj' => 'odžibva',
 				'ojb' => 'northwestern ojibwa',
 				'ojc' => 'centrálna odžibvejčina',
 				'ojs' => 'oji-cree',
 				'ojw' => 'ojibwa (západ)',
 				'oka' => 'okanagan',
 				'om' => 'oromčina',
 				'or' => 'uríjčina',
 				'os' => 'osetčina',
 				'osa' => 'osedžština',
 				'ota' => 'osmanská turečtina',
 				'pa' => 'pandžábčina',
 				'pag' => 'pangasinančina',
 				'pal' => 'pahlaví',
 				'pam' => 'kapampangančina',
 				'pap' => 'papiamento',
 				'pau' => 'palaučina',
 				'pcm' => 'nigerijský pidžin',
 				'peo' => 'stará perzština',
 				'phn' => 'feničtina',
 				'pi' => 'pálí',
 				'pis' => 'pidžin',
 				'pl' => 'poľština',
 				'pon' => 'pohnpeiština',
 				'pqm' => 'maliseet-passamaquoddy',
 				'prg' => 'pruština',
 				'pro' => 'stará okcitánčina',
 				'ps' => 'paštčina',
 				'pt' => 'portugalčina',
 				'pt_BR' => 'portugalčina (brazílska)',
 				'pt_PT' => 'portugalčina (európska)',
 				'qu' => 'kečuánčina',
 				'quc' => 'quiché',
 				'raj' => 'radžastančina',
 				'rap' => 'rapanujčina',
 				'rar' => 'rarotongská maorijčina',
 				'rhg' => 'rohingčina',
 				'rm' => 'rétorománčina',
 				'rn' => 'rundčina',
 				'ro' => 'rumunčina',
 				'ro_MD' => 'moldavčina',
 				'rof' => 'rombo',
 				'rom' => 'rómčina',
 				'ru' => 'ruština',
 				'rup' => 'arumunčina',
 				'rw' => 'rwandčina',
 				'rwk' => 'rwa',
 				'sa' => 'sanskrit',
 				'sad' => 'sandaweština',
 				'sah' => 'jakutčina',
 				'sam' => 'samaritánska aramejčina',
 				'saq' => 'samburu',
 				'sas' => 'sasačtina',
 				'sat' => 'santalčina',
 				'sba' => 'ngambay',
 				'sbp' => 'sangu',
 				'sc' => 'sardínčina',
 				'scn' => 'sicílčina',
 				'sco' => 'škótčina',
 				'sd' => 'sindhčina',
 				'sdh' => 'južná kurdčina',
 				'se' => 'saamčina (severná)',
 				'see' => 'senekčina',
 				'seh' => 'sena',
 				'sel' => 'selkupčina',
 				'ses' => 'koyraboro senni',
 				'sg' => 'sango',
 				'sga' => 'stará írčina',
 				'sh' => 'srbochorvátčina',
 				'shi' => 'tachelhit',
 				'shn' => 'šančina',
 				'shu' => 'čadská arabčina',
 				'si' => 'sinhalčina',
 				'sid' => 'sidamo',
 				'sk' => 'slovenčina',
 				'sl' => 'slovinčina',
 				'slh' => 'lushootseed (juh)',
 				'sm' => 'samojčina',
 				'sma' => 'saamčina (južná)',
 				'smj' => 'saamčina (lulská)',
 				'smn' => 'saamčina (inarijská)',
 				'sms' => 'saamčina (skoltská)',
 				'sn' => 'šončina',
 				'snk' => 'soninke',
 				'so' => 'somálčina',
 				'sog' => 'sogdijčina',
 				'sq' => 'albánčina',
 				'sr' => 'srbčina',
 				'srn' => 'surinamčina',
 				'srr' => 'sererčina',
 				'ss' => 'svazijčina',
 				'ssy' => 'saho',
 				'st' => 'sothčina (južná)',
 				'str' => 'straits salish',
 				'su' => 'sundčina',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumerčina',
 				'sv' => 'švédčina',
 				'sw' => 'swahilčina',
 				'sw_CD' => 'svahilčina (konžská)',
 				'swb' => 'komorčina',
 				'syc' => 'sýrčina (klasická)',
 				'syr' => 'sýrčina',
 				'ta' => 'tamilčina',
 				'tce' => 'tutchone (juh)',
 				'te' => 'telugčina',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'ter' => 'terêna',
 				'tet' => 'tetumčina',
 				'tg' => 'tadžičtina',
 				'tgx' => 'tagiš',
 				'th' => 'thajčina',
 				'tht' => 'tahltan',
 				'ti' => 'tigriňa',
 				'tig' => 'tigrejčina',
 				'tiv' => 'tiv',
 				'tk' => 'turkménčina',
 				'tkl' => 'tokelauština',
 				'tl' => 'tagalčina',
 				'tlh' => 'klingónčina',
 				'tli' => 'tlingitčina',
 				'tmh' => 'tuaregčina',
 				'tn' => 'tswančina',
 				'to' => 'tongčina',
 				'tog' => 'ňasa tonga',
 				'tok' => 'toki pona',
 				'tpi' => 'novoguinejský pidžin',
 				'tr' => 'turečtina',
 				'trv' => 'taroko',
 				'ts' => 'tsongčina',
 				'tsi' => 'cimšjančina',
 				'tt' => 'tatárčina',
 				'ttm' => 'northern tutchone',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalčina',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitčina',
 				'tyv' => 'tuviančina',
 				'tzm' => 'tamazight (stredomarocký)',
 				'udm' => 'udmurtčina',
 				'ug' => 'ujgurčina',
 				'uga' => 'ugaritčina',
 				'uk' => 'ukrajinčina',
 				'umb' => 'umbundu',
 				'und' => 'neznámy jazyk',
 				'ur' => 'urdčina',
 				'uz' => 'uzbečtina',
 				'vai' => 'vai',
 				've' => 'vendčina',
 				'vi' => 'vietnamčina',
 				'vo' => 'volapük',
 				'vot' => 'vodčina',
 				'vun' => 'vunjo',
 				'wa' => 'valónčina',
 				'wae' => 'walserčina',
 				'wal' => 'walamčina',
 				'war' => 'waray',
 				'was' => 'washo',
 				'wbp' => 'warlpiri',
 				'wo' => 'wolofčina',
 				'wuu' => 'čínština (wu)',
 				'xal' => 'kalmyčtina',
 				'xh' => 'xhoština',
 				'xog' => 'soga',
 				'yao' => 'jao',
 				'yap' => 'japčina',
 				'yav' => 'jangben',
 				'ybb' => 'yemba',
 				'yi' => 'jidiš',
 				'yo' => 'jorubčina',
 				'yrl' => 'nheengatu',
 				'yue' => 'kantončina',
 				'yue@alt=menu' => 'čínština (kantonská)',
 				'za' => 'čuangčina',
 				'zap' => 'zapotéčtina',
 				'zbl' => 'systém Bliss',
 				'zen' => 'zenaga',
 				'zgh' => 'tuaregčina (marocká štandardná)',
 				'zh' => 'čínština',
 				'zh@alt=menu' => 'čínština (mandarínska)',
 				'zh_Hans' => 'čínština (zjednodušená)',
 				'zh_Hans@alt=long' => 'čínština (mandarínska zjednodušená)',
 				'zh_Hant' => 'čínština (tradičná)',
 				'zh_Hant@alt=long' => 'čínština (mandarínska tradičná)',
 				'zu' => 'zuluština',
 				'zun' => 'zuniština',
 				'zxx' => 'bez jazykového obsahu',
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
			'Adlm' => 'adlam',
 			'Arab' => 'arabské',
 			'Arab@alt=variant' => 'perzsko-arabské',
 			'Aran' => 'nastaliq',
 			'Armn' => 'arménske',
 			'Bali' => 'balijský',
 			'Beng' => 'bengálske',
 			'Bopo' => 'bopomofo',
 			'Brai' => 'braillovo',
 			'Cakm' => 'čakma',
 			'Cans' => 'zjednotené kanadské domorodé slabiky',
 			'Cher' => 'čerokézčina',
 			'Cyrl' => 'cyrilika',
 			'Deva' => 'dévanágarí',
 			'Egyp' => 'egyptské hieroglyfy',
 			'Ethi' => 'etiópske',
 			'Geor' => 'gruzínske',
 			'Glag' => 'hlaholika',
 			'Goth' => 'gotický',
 			'Grek' => 'grécke',
 			'Gujr' => 'gudžarátí',
 			'Guru' => 'gurmukhi',
 			'Hanb' => 'čínske a bopomofo',
 			'Hang' => 'hangul',
 			'Hani' => 'čínske',
 			'Hans' => 'zjednodušené',
 			'Hans@alt=stand-alone' => 'čínske zjednodušené',
 			'Hant' => 'tradičné',
 			'Hant@alt=stand-alone' => 'čínske tradičné',
 			'Hebr' => 'hebrejské',
 			'Hira' => 'hiragana',
 			'Hrkt' => 'kana',
 			'Jamo' => 'jamo',
 			'Jpan' => 'japonské',
 			'Kana' => 'katakana',
 			'Khmr' => 'khmérske',
 			'Knda' => 'kannadské',
 			'Kore' => 'kórejské',
 			'Laoo' => 'laoské',
 			'Latn' => 'latinka',
 			'Lina' => 'lineárna A',
 			'Linb' => 'lineárna B',
 			'Maya' => 'mayské hieroglyfy',
 			'Mlym' => 'malajálamske',
 			'Mong' => 'mongolské',
 			'Mtei' => 'mejtej majek (manipurské)',
 			'Mymr' => 'barmské',
 			'Nkoo' => 'bambarčina',
 			'Olck' => 'santálske (ol chiki)',
 			'Orya' => 'uríjske',
 			'Osma' => 'osmanský',
 			'Qaag' => 'zawgyi',
 			'Rohg' => 'hanifi',
 			'Runr' => 'Runové písmo',
 			'Sinh' => 'sinhálske',
 			'Sund' => 'sundčina',
 			'Syrc' => 'sýrčina',
 			'Taml' => 'tamilské',
 			'Telu' => 'telugské',
 			'Tfng' => 'tifinagh',
 			'Thaa' => 'tána',
 			'Thai' => 'thajské',
 			'Tibt' => 'tibetské',
 			'Vaii' => 'vai',
 			'Yiii' => 'yi',
 			'Zmth' => 'matematický zápis',
 			'Zsye' => 'emodži',
 			'Zsym' => 'symboly',
 			'Zxxx' => 'bez zápisu',
 			'Zyyy' => 'všeobecné',
 			'Zzzz' => 'neznáme písmo',

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
			'001' => 'svet',
 			'002' => 'Afrika',
 			'003' => 'Severná Amerika',
 			'005' => 'Južná Amerika',
 			'009' => 'Oceánia',
 			'011' => 'západná Afrika',
 			'013' => 'Stredná Amerika',
 			'014' => 'východná Afrika',
 			'015' => 'severná Afrika',
 			'017' => 'stredná Afrika',
 			'018' => 'južné územia Afriky',
 			'019' => 'Amerika',
 			'021' => 'severné územia Ameriky',
 			'029' => 'Karibik',
 			'030' => 'východná Ázia',
 			'034' => 'južná Ázia',
 			'035' => 'juhovýchodná Ázia',
 			'039' => 'južná Európa',
 			'053' => 'Australázia',
 			'054' => 'Melanézia',
 			'057' => 'oblasť Mikronézie',
 			'061' => 'Polynézia',
 			'142' => 'Ázia',
 			'143' => 'stredná Ázia',
 			'145' => 'západná Ázia',
 			'150' => 'Európa',
 			'151' => 'východná Európa',
 			'154' => 'severná Európa',
 			'155' => 'západná Európa',
 			'202' => 'subsaharská Afrika',
 			'419' => 'Latinská Amerika',
 			'AC' => 'Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Spojené arabské emiráty',
 			'AF' => 'Afganistan',
 			'AG' => 'Antigua a Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albánsko',
 			'AM' => 'Arménsko',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktída',
 			'AR' => 'Argentína',
 			'AS' => 'Americká Samoa',
 			'AT' => 'Rakúsko',
 			'AU' => 'Austrália',
 			'AW' => 'Aruba',
 			'AX' => 'Alandy',
 			'AZ' => 'Azerbajdžan',
 			'BA' => 'Bosna a Hercegovina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladéš',
 			'BE' => 'Belgicko',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulharsko',
 			'BH' => 'Bahrajn',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Svätý Bartolomej',
 			'BM' => 'Bermudy',
 			'BN' => 'Brunej',
 			'BO' => 'Bolívia',
 			'BQ' => 'Karibské Holandsko',
 			'BR' => 'Brazília',
 			'BS' => 'Bahamy',
 			'BT' => 'Bhután',
 			'BV' => 'Bouvetov ostrov',
 			'BW' => 'Botswana',
 			'BY' => 'Bielorusko',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kokosové ostrovy',
 			'CD' => 'Konžská demokratická republika',
 			'CD@alt=variant' => 'Kongo (DRK)',
 			'CF' => 'Stredoafrická republika',
 			'CG' => 'Konžská republika',
 			'CG@alt=variant' => 'Kongo (republika)',
 			'CH' => 'Švajčiarsko',
 			'CI' => 'Pobrežie Slonoviny',
 			'CK' => 'Cookove ostrovy',
 			'CL' => 'Čile',
 			'CM' => 'Kamerun',
 			'CN' => 'Čína',
 			'CO' => 'Kolumbia',
 			'CP' => 'Clipperton',
 			'CR' => 'Kostarika',
 			'CU' => 'Kuba',
 			'CV' => 'Kapverdy',
 			'CW' => 'Curaçao',
 			'CX' => 'Vianočný ostrov',
 			'CY' => 'Cyprus',
 			'CZ' => 'Česko',
 			'CZ@alt=variant' => 'Česká republika',
 			'DE' => 'Nemecko',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Džibutsko',
 			'DK' => 'Dánsko',
 			'DM' => 'Dominika',
 			'DO' => 'Dominikánska republika',
 			'DZ' => 'Alžírsko',
 			'EA' => 'Ceuta a Melilla',
 			'EC' => 'Ekvádor',
 			'EE' => 'Estónsko',
 			'EG' => 'Egypt',
 			'EH' => 'Západná Sahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Španielsko',
 			'ET' => 'Etiópia',
 			'EU' => 'Európska únia',
 			'EZ' => 'eurozóna',
 			'FI' => 'Fínsko',
 			'FJ' => 'Fidži',
 			'FK' => 'Falklandy',
 			'FK@alt=variant' => 'Falklandy (Malvíny)',
 			'FM' => 'Mikronézia',
 			'FO' => 'Faerské ostrovy',
 			'FR' => 'Francúzsko',
 			'GA' => 'Gabon',
 			'GB' => 'Spojené kráľovstvo',
 			'GB@alt=short' => 'UK',
 			'GD' => 'Grenada',
 			'GE' => 'Gruzínsko',
 			'GF' => 'Francúzska Guyana',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltár',
 			'GL' => 'Grónsko',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Rovníková Guinea',
 			'GR' => 'Grécko',
 			'GS' => 'Južná Georgia a Južné Sandwichove ostrovy',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Hongkong – OAO Číny',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heardov ostrov a Macdonaldove ostrovy',
 			'HN' => 'Honduras',
 			'HR' => 'Chorvátsko',
 			'HT' => 'Haiti',
 			'HU' => 'Maďarsko',
 			'IC' => 'Kanárske ostrovy',
 			'ID' => 'Indonézia',
 			'IE' => 'Írsko',
 			'IL' => 'Izrael',
 			'IM' => 'Ostrov Man',
 			'IN' => 'India',
 			'IO' => 'Britské indickooceánske územie',
 			'IO@alt=chagos' => 'Čagoské ostrovy',
 			'IQ' => 'Irak',
 			'IR' => 'Irán',
 			'IS' => 'Island',
 			'IT' => 'Taliansko',
 			'JE' => 'Jersey',
 			'JM' => 'Jamajka',
 			'JO' => 'Jordánsko',
 			'JP' => 'Japonsko',
 			'KE' => 'Keňa',
 			'KG' => 'Kirgizsko',
 			'KH' => 'Kambodža',
 			'KI' => 'Kiribati',
 			'KM' => 'Komory',
 			'KN' => 'Svätý Krištof a Nevis',
 			'KP' => 'Severná Kórea',
 			'KR' => 'Južná Kórea',
 			'KW' => 'Kuvajt',
 			'KY' => 'Kajmanie ostrovy',
 			'KZ' => 'Kazachstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'Svätá Lucia',
 			'LI' => 'Lichtenštajnsko',
 			'LK' => 'Srí Lanka',
 			'LR' => 'Libéria',
 			'LS' => 'Lesotho',
 			'LT' => 'Litva',
 			'LU' => 'Luxembursko',
 			'LV' => 'Lotyšsko',
 			'LY' => 'Líbya',
 			'MA' => 'Maroko',
 			'MC' => 'Monako',
 			'MD' => 'Moldavsko',
 			'ME' => 'Čierna Hora',
 			'MF' => 'Svätý Martin (fr.)',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshallove ostrovy',
 			'MK' => 'Severné Macedónsko',
 			'ML' => 'Mali',
 			'MM' => 'Mjanmarsko',
 			'MN' => 'Mongolsko',
 			'MO' => 'Macao – OAO Číny',
 			'MO@alt=short' => 'Macao',
 			'MP' => 'Severné Mariány',
 			'MQ' => 'Martinik',
 			'MR' => 'Mauritánia',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Maurícius',
 			'MV' => 'Maldivy',
 			'MW' => 'Malawi',
 			'MX' => 'Mexiko',
 			'MY' => 'Malajzia',
 			'MZ' => 'Mozambik',
 			'NA' => 'Namíbia',
 			'NC' => 'Nová Kaledónia',
 			'NE' => 'Niger',
 			'NF' => 'Norfolk',
 			'NG' => 'Nigéria',
 			'NI' => 'Nikaragua',
 			'NL' => 'Holandsko',
 			'NO' => 'Nórsko',
 			'NP' => 'Nepál',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Nový Zéland',
 			'NZ@alt=variant' => 'Aotearoa – Nový Zéland',
 			'OM' => 'Omán',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Francúzska Polynézia',
 			'PG' => 'Papua-Nová Guinea',
 			'PH' => 'Filipíny',
 			'PK' => 'Pakistan',
 			'PL' => 'Poľsko',
 			'PM' => 'Saint Pierre a Miquelon',
 			'PN' => 'Pitcairnove ostrovy',
 			'PR' => 'Portoriko',
 			'PS' => 'Palestínske územia',
 			'PS@alt=short' => 'Palestínska samospráva',
 			'PT' => 'Portugalsko',
 			'PW' => 'Palau',
 			'PY' => 'Paraguaj',
 			'QA' => 'Katar',
 			'QO' => 'ostatné Tichomorie',
 			'RE' => 'Réunion',
 			'RO' => 'Rumunsko',
 			'RS' => 'Srbsko',
 			'RU' => 'Rusko',
 			'RW' => 'Rwanda',
 			'SA' => 'Saudská Arábia',
 			'SB' => 'Šalamúnove ostrovy',
 			'SC' => 'Seychely',
 			'SD' => 'Sudán',
 			'SE' => 'Švédsko',
 			'SG' => 'Singapur',
 			'SH' => 'Svätá Helena',
 			'SI' => 'Slovinsko',
 			'SJ' => 'Svalbard a Jan Mayen',
 			'SK' => 'Slovensko',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Maríno',
 			'SN' => 'Senegal',
 			'SO' => 'Somálsko',
 			'SR' => 'Surinam',
 			'SS' => 'Južný Sudán',
 			'ST' => 'Svätý Tomáš a Princov ostrov',
 			'SV' => 'Salvádor',
 			'SX' => 'Svätý Martin (hol.)',
 			'SY' => 'Sýria',
 			'SZ' => 'Eswatini',
 			'SZ@alt=variant' => 'Svazijsko',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks a Caicos',
 			'TD' => 'Čad',
 			'TF' => 'Francúzske južné a antarktické územia',
 			'TG' => 'Togo',
 			'TH' => 'Thajsko',
 			'TJ' => 'Tadžikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Východný Timor',
 			'TM' => 'Turkménsko',
 			'TN' => 'Tunisko',
 			'TO' => 'Tonga',
 			'TR' => 'Turecko',
 			'TT' => 'Trinidad a Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tanzánia',
 			'UA' => 'Ukrajina',
 			'UG' => 'Uganda',
 			'UM' => 'Menšie odľahlé ostrovy USA',
 			'UN' => 'Organizácia Spojených národov',
 			'UN@alt=short' => 'OSN',
 			'US' => 'Spojené štáty',
 			'US@alt=short' => 'USA',
 			'UY' => 'Uruguaj',
 			'UZ' => 'Uzbekistan',
 			'VA' => 'Vatikán',
 			'VC' => 'Svätý Vincent a Grenadíny',
 			'VE' => 'Venezuela',
 			'VG' => 'Britské Panenské ostrovy',
 			'VI' => 'Americké Panenské ostrovy',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis a Futuna',
 			'WS' => 'Samoa',
 			'XA' => 'falošná diakritika',
 			'XB' => 'obrátenie sprava doľava',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Južná Afrika',
 			'ZM' => 'Zambia',
 			'ZW' => 'Zimbabwe',
 			'ZZ' => 'neznámy región',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'PINYIN' => 'romanizovaná mandarínčina',
 			'SCOTLAND' => 'škótska štandardná angličtina',
 			'WADEGILE' => 'romanizovaná mandarínčina Wade-Giles',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'kalendár',
 			'cf' => 'formát meny',
 			'colalternate' => 'ignorovať radenie symbolov',
 			'colbackwards' => 'obrátené radenie diakritiky',
 			'colcasefirst' => 'radenie veľkých a malých písmen',
 			'colcaselevel' => 'rozlišovanie veľkých a malých písmen pri radení',
 			'collation' => 'zoradenie',
 			'colnormalization' => 'normálne radenie',
 			'colnumeric' => 'číselné radenie',
 			'colstrength' => 'sila radenia',
 			'currency' => 'mena',
 			'hc' => 'hodinový cyklus (12 vs 24)',
 			'lb' => 'štýl koncov riadka',
 			'ms' => 'merná sústava',
 			'numbers' => 'čísla',
 			'timezone' => 'časové pásmo',
 			'va' => 'variant miestneho nastavenia',
 			'x' => 'súkromné použitie',

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
 				'buddhist' => q{buddhistický kalendár},
 				'chinese' => q{čínsky kalendár},
 				'coptic' => q{koptský kalendár},
 				'dangi' => q{kórejský kalendár},
 				'ethiopic' => q{etiópsky kalendár},
 				'ethiopic-amete-alem' => q{etiópsky kalendár Amete Alem},
 				'gregorian' => q{gregoriánsky kalendár},
 				'hebrew' => q{židovský kalendár},
 				'indian' => q{Indický národný kalendár},
 				'islamic' => q{kalendár podľa hidžry},
 				'islamic-civil' => q{kalendár podľa hidžry (občiansky)},
 				'islamic-umalqura' => q{kalendár podľa hidžry (Umm al-Qura)},
 				'iso8601' => q{kalendár ISO 8601},
 				'japanese' => q{japonský kalendár},
 				'persian' => q{perzský kalendár},
 				'roc' => q{čínsky republikánsky kalendár},
 			},
 			'cf' => {
 				'account' => q{účtovný formát meny},
 				'standard' => q{štandardný formát meny},
 			},
 			'colalternate' => {
 				'non-ignorable' => q{Radiť symboly},
 				'shifted' => q{Pri radení ignorovať symboly},
 			},
 			'colbackwards' => {
 				'no' => q{Normálne radenie akcentov},
 				'yes' => q{Radiť akcenty opačne},
 			},
 			'colcasefirst' => {
 				'lower' => q{Najprv radiť malé písmená},
 				'no' => q{Normálne radenie veľkých a malých písmen},
 				'upper' => q{Najprv radiť veľké písmená},
 			},
 			'colcaselevel' => {
 				'no' => q{Pri radení nerozlišovať veľké a malé písmená},
 				'yes' => q{Pri radení rozlišovať veľké a malé písmená},
 			},
 			'collation' => {
 				'big5han' => q{tradičný čínsky Big5},
 				'compat' => q{predchádzajúce zoradenie, kompatibilita},
 				'dictionary' => q{slovníkové zoradenie},
 				'ducet' => q{predvolené zoradenie unicode},
 				'eor' => q{európske zoradenie},
 				'gb2312han' => q{zjednodušený čínsky GB2312},
 				'phonebook' => q{lexikografické zoradenie},
 				'phonetic' => q{fonetické zoradenie},
 				'pinyin' => q{zoradenie pinyin},
 				'reformed' => q{reformované zoradenie},
 				'search' => q{všeobecné vyhľadávanie},
 				'searchjl' => q{Hľadať podľa počiatočnej spoluhlásky písma Hangul},
 				'standard' => q{štandardné zoradenie},
 				'stroke' => q{zoradenie podľa ťahov},
 				'traditional' => q{tradičné poradie zoradenia},
 				'unihan' => q{zoradenie podľa znakov radikál},
 				'zhuyin' => q{zoradenie zhuyin},
 			},
 			'colnormalization' => {
 				'no' => q{Radiť bez normalizácie},
 				'yes' => q{Radenie podľa normalizovaného kódovania Unicode},
 			},
 			'colnumeric' => {
 				'no' => q{Radiť číslice jednotlivo},
 				'yes' => q{Numerické radenie číslic},
 			},
 			'colstrength' => {
 				'identical' => q{Radiť všetko},
 				'primary' => q{Radiť iba základné písmená},
 				'quaternary' => q{Radiť akcenty/veľké a malé písmená/šírku/kana},
 				'secondary' => q{Radiť akcenty},
 				'tertiary' => q{Radiť akcenty/veľké a malé písmená/šírku},
 			},
 			'd0' => {
 				'fwidth' => q{celá šírka},
 				'hwidth' => q{polovičná šírka},
 				'npinyin' => q{Číslice},
 			},
 			'hc' => {
 				'h11' => q{12-hodinový cyklus (0 – 11)},
 				'h12' => q{12-hodinový cyklus (1 – 12)},
 				'h23' => q{24-hodinový cyklus (0 – 23)},
 				'h24' => q{24-hodinový cyklus (1 – 24)},
 			},
 			'lb' => {
 				'loose' => q{voľný štýl koncov riadka},
 				'normal' => q{bežný štýl koncov riadka},
 				'strict' => q{presný štýl koncov riadka},
 			},
 			'm0' => {
 				'bgn' => q{americká transliterácia BGN},
 				'ungegn' => q{medzinárodná transliterácia GEGN},
 			},
 			'ms' => {
 				'metric' => q{metrická sústava},
 				'uksystem' => q{britská merná sústava},
 				'ussystem' => q{americká merná sústava},
 			},
 			'numbers' => {
 				'arab' => q{arabsko-indické číslice},
 				'arabext' => q{rozšírené arabsko-indické číslice},
 				'armn' => q{arménske číslice},
 				'armnlow' => q{malé arménske číslice},
 				'beng' => q{bengálske číslice},
 				'cakm' => q{číslice chakma},
 				'deva' => q{číslice dévanágarí},
 				'ethi' => q{etiópske číslice},
 				'finance' => q{Finančnícky zápis čísiel},
 				'fullwide' => q{číslice s celou šírkou},
 				'geor' => q{gruzínske číslice},
 				'grek' => q{grécke číslice},
 				'greklow' => q{malé grécke číslice},
 				'gujr' => q{gudžarátske číslice},
 				'guru' => q{číslice gurumukhí},
 				'hanidec' => q{čínske desiatkové číslice},
 				'hans' => q{číslice zjednodušenej čínštiny},
 				'hansfin' => q{finančné číslice zjednodušenej čínštiny},
 				'hant' => q{číslice tradičnej čínštiny},
 				'hantfin' => q{finančné číslice tradičnej čínštiny},
 				'hebr' => q{hebrejské číslice},
 				'java' => q{jávske číslice},
 				'jpan' => q{japonské číslice},
 				'jpanfin' => q{japonské finančné číslice},
 				'khmr' => q{khmérske číslice},
 				'knda' => q{kannadské číslice},
 				'laoo' => q{laoské číslice},
 				'latn' => q{arabské číslice},
 				'mlym' => q{malajálamske číslice},
 				'mong' => q{Mongolské číslice},
 				'mtei' => q{číslice meetei mayek},
 				'mymr' => q{barmské číslice},
 				'native' => q{natívne číslice},
 				'olck' => q{číslice ol chiki},
 				'orya' => q{uríjske číslice},
 				'roman' => q{rímske číslice},
 				'romanlow' => q{malé rímske číslice},
 				'taml' => q{číslice tradičnej tamilčiny},
 				'tamldec' => q{tamilské číslice},
 				'telu' => q{telugské číslice},
 				'thai' => q{thajské číslice},
 				'tibt' => q{tibetské číslice},
 				'traditional' => q{Tradičné číslovky},
 				'vaii' => q{vaiské číslice},
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
			'metric' => q{metrický},
 			'UK' => q{britský},
 			'US' => q{americký},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'Jazyk: {0}',
 			'script' => 'Písmo: {0}',
 			'region' => 'Región: {0}',

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
			auxiliary => qr{[àăâåā æ ç èĕêëē ìĭîïī ñ òŏöőøō œ ř ùŭûüűū ÿ]},
			index => ['A', 'Ä', 'B', 'C', 'Č', 'DĎ', 'E', 'F', 'G', 'H', '{CH}', 'I', 'J', 'K', 'LĽ', 'M', 'N', 'O', 'Ô', 'P', 'Q', 'R', 'S', 'Š', 'TŤ', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž'],
			main => qr{[aá ä b c č dď {dz} {dž} eé f g h {ch} ií j k lĺľ m nň oó ô p q rŕ s š tť uú v w x yý z ž]},
			numbers => qr{[  \- ‑ , % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐‑ – , ; \: ! ? . … ‘‚ “„ ( ) \[ \] § @ * / \&]},
		};
	},
EOT
: sub {
		return { index => ['A', 'Ä', 'B', 'C', 'Č', 'DĎ', 'E', 'F', 'G', 'H', '{CH}', 'I', 'J', 'K', 'LĽ', 'M', 'N', 'O', 'Ô', 'P', 'Q', 'R', 'S', 'Š', 'TŤ', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž'], };
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
						'1' => q(yobi{0}),
					},
					# Core Unit Identifier
					'1024p8' => {
						'1' => q(yobi{0}),
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
						'1' => q(yokto{0}),
					},
					# Core Unit Identifier
					'24' => {
						'1' => q(yokto{0}),
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
						'1' => q(feminine),
						'few' => q({0} jednotky preťaženia),
						'many' => q({0} jednotky preťaženia),
						'name' => q(jednotky preťaženia),
						'one' => q({0} jednotka preťaženia),
						'other' => q({0} jednotiek preťaženia),
					},
					# Core Unit Identifier
					'g-force' => {
						'1' => q(feminine),
						'few' => q({0} jednotky preťaženia),
						'many' => q({0} jednotky preťaženia),
						'name' => q(jednotky preťaženia),
						'one' => q({0} jednotka preťaženia),
						'other' => q({0} jednotiek preťaženia),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'1' => q(inanimate),
						'few' => q({0} metre za sekundu na druhú),
						'many' => q({0} metra za sekundu na druhú),
						'name' => q(metre za sekundu na druhú),
						'one' => q({0} meter za sekundu na druhú),
						'other' => q({0} metrov za sekundu na druhú),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'1' => q(inanimate),
						'few' => q({0} metre za sekundu na druhú),
						'many' => q({0} metra za sekundu na druhú),
						'name' => q(metre za sekundu na druhú),
						'one' => q({0} meter za sekundu na druhú),
						'other' => q({0} metrov za sekundu na druhú),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'1' => q(feminine),
						'few' => q({0} arcminúty),
						'many' => q({0} arcminúty),
						'name' => q(arcminúty),
						'one' => q({0} arcminúta),
						'other' => q({0} arcminút),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'1' => q(feminine),
						'few' => q({0} arcminúty),
						'many' => q({0} arcminúty),
						'name' => q(arcminúty),
						'one' => q({0} arcminúta),
						'other' => q({0} arcminút),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'1' => q(feminine),
						'few' => q({0} arcsekundy),
						'many' => q({0} arcsekundy),
						'name' => q(arcsekundy),
						'one' => q({0} arcsekunda),
						'other' => q({0} arcsekúnd),
					},
					# Core Unit Identifier
					'arc-second' => {
						'1' => q(feminine),
						'few' => q({0} arcsekundy),
						'many' => q({0} arcsekundy),
						'name' => q(arcsekundy),
						'one' => q({0} arcsekunda),
						'other' => q({0} arcsekúnd),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'1' => q(inanimate),
						'few' => q({0} stupne),
						'many' => q({0} stupňa),
						'name' => q(stupne),
						'one' => q({0} stupeň),
						'other' => q({0} stupňov),
					},
					# Core Unit Identifier
					'degree' => {
						'1' => q(inanimate),
						'few' => q({0} stupne),
						'many' => q({0} stupňa),
						'name' => q(stupne),
						'one' => q({0} stupeň),
						'other' => q({0} stupňov),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'1' => q(inanimate),
						'few' => q({0} radiány),
						'many' => q({0} radiánu),
						'name' => q(radiány),
						'one' => q({0} radián),
						'other' => q({0} radiánov),
					},
					# Core Unit Identifier
					'radian' => {
						'1' => q(inanimate),
						'few' => q({0} radiány),
						'many' => q({0} radiánu),
						'name' => q(radiány),
						'one' => q({0} radián),
						'other' => q({0} radiánov),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'1' => q(feminine),
						'few' => q({0} otáčky),
						'many' => q({0} otáčky),
						'name' => q(otáčky),
						'one' => q({0} otáčka),
						'other' => q({0} otáčok),
					},
					# Core Unit Identifier
					'revolution' => {
						'1' => q(feminine),
						'few' => q({0} otáčky),
						'many' => q({0} otáčky),
						'name' => q(otáčky),
						'one' => q({0} otáčka),
						'other' => q({0} otáčok),
					},
					# Long Unit Identifier
					'area-acre' => {
						'few' => q({0} akre),
						'many' => q({0} akra),
						'one' => q({0} aker),
						'other' => q({0} akrov),
					},
					# Core Unit Identifier
					'acre' => {
						'few' => q({0} akre),
						'many' => q({0} akra),
						'one' => q({0} aker),
						'other' => q({0} akrov),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0} dunamy),
						'many' => q({0} dunamu),
						'name' => q(dunamy),
						'one' => q({0} dunam),
						'other' => q({0} dunamov),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0} dunamy),
						'many' => q({0} dunamu),
						'name' => q(dunamy),
						'one' => q({0} dunam),
						'other' => q({0} dunamov),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'1' => q(inanimate),
						'few' => q({0} hektáre),
						'many' => q({0} hektára),
						'one' => q({0} hektár),
						'other' => q({0} hektárov),
					},
					# Core Unit Identifier
					'hectare' => {
						'1' => q(inanimate),
						'few' => q({0} hektáre),
						'many' => q({0} hektára),
						'one' => q({0} hektár),
						'other' => q({0} hektárov),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} centimetre štvorcové),
						'many' => q({0} centimetra štvorcového),
						'name' => q(štvorcové centimetre),
						'one' => q({0} centimeter štvorcový),
						'other' => q({0} centimetrov štvorcových),
						'per' => q({0} na centimeter štvorcový),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} centimetre štvorcové),
						'many' => q({0} centimetra štvorcového),
						'name' => q(štvorcové centimetre),
						'one' => q({0} centimeter štvorcový),
						'other' => q({0} centimetrov štvorcových),
						'per' => q({0} na centimeter štvorcový),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'few' => q({0} štvorcové stopy),
						'many' => q({0} štvorcovej stopy),
						'name' => q(štvorcové stopy),
						'one' => q({0} štvorcová stopa),
						'other' => q({0} štvorcových stôp),
					},
					# Core Unit Identifier
					'square-foot' => {
						'few' => q({0} štvorcové stopy),
						'many' => q({0} štvorcovej stopy),
						'name' => q(štvorcové stopy),
						'one' => q({0} štvorcová stopa),
						'other' => q({0} štvorcových stôp),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'few' => q({0} štvorcové palce),
						'many' => q({0} štvorcového palca),
						'name' => q(štvorcové palce),
						'one' => q({0} štvorcový palec),
						'other' => q({0} štvorcových palcov),
						'per' => q({0} na štvorcový palec),
					},
					# Core Unit Identifier
					'square-inch' => {
						'few' => q({0} štvorcové palce),
						'many' => q({0} štvorcového palca),
						'name' => q(štvorcové palce),
						'one' => q({0} štvorcový palec),
						'other' => q({0} štvorcových palcov),
						'per' => q({0} na štvorcový palec),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} kilometre štvorcové),
						'many' => q({0} kilometra štvorcového),
						'name' => q(štvorcové kilometre),
						'one' => q({0} kilometer štvorcový),
						'other' => q({0} kilometrov štvorcových),
						'per' => q({0} na kilometer štvorcový),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} kilometre štvorcové),
						'many' => q({0} kilometra štvorcového),
						'name' => q(štvorcové kilometre),
						'one' => q({0} kilometer štvorcový),
						'other' => q({0} kilometrov štvorcových),
						'per' => q({0} na kilometer štvorcový),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'1' => q(inanimate),
						'few' => q({0} metre štvorcové),
						'many' => q({0} metra štvorcového),
						'name' => q(štvorcové metre),
						'one' => q({0} meter štvorcový),
						'other' => q({0} metrov štvorcových),
						'per' => q({0} na meter štvorcový),
					},
					# Core Unit Identifier
					'square-meter' => {
						'1' => q(inanimate),
						'few' => q({0} metre štvorcové),
						'many' => q({0} metra štvorcového),
						'name' => q(štvorcové metre),
						'one' => q({0} meter štvorcový),
						'other' => q({0} metrov štvorcových),
						'per' => q({0} na meter štvorcový),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'few' => q({0} míle štvorcové),
						'many' => q({0} míle štvorcovej),
						'name' => q(štvorcové míle),
						'one' => q({0} míľa štvorcová),
						'other' => q({0} míľ štvorcových),
						'per' => q({0} na míľu štvorcovú),
					},
					# Core Unit Identifier
					'square-mile' => {
						'few' => q({0} míle štvorcové),
						'many' => q({0} míle štvorcovej),
						'name' => q(štvorcové míle),
						'one' => q({0} míľa štvorcová),
						'other' => q({0} míľ štvorcových),
						'per' => q({0} na míľu štvorcovú),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'few' => q({0} štvorcové yardy),
						'many' => q({0} štvorcového yardu),
						'name' => q(štvorcové yardy),
						'one' => q({0} štvorcový yard),
						'other' => q({0} štvorcových yardov),
					},
					# Core Unit Identifier
					'square-yard' => {
						'few' => q({0} štvorcové yardy),
						'many' => q({0} štvorcového yardu),
						'name' => q(štvorcové yardy),
						'one' => q({0} štvorcový yard),
						'other' => q({0} štvorcových yardov),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'1' => q(feminine),
						'few' => q({0} položky),
						'many' => q({0} položky),
						'name' => q(položky),
						'one' => q({0} položka),
						'other' => q({0} položiek),
					},
					# Core Unit Identifier
					'item' => {
						'1' => q(feminine),
						'few' => q({0} položky),
						'many' => q({0} položky),
						'name' => q(položky),
						'one' => q({0} položka),
						'other' => q({0} položiek),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'1' => q(inanimate),
						'few' => q({0} karáty),
						'many' => q({0} karátu),
						'name' => q(karáty),
						'one' => q({0} karát),
						'other' => q({0} karátov),
					},
					# Core Unit Identifier
					'karat' => {
						'1' => q(inanimate),
						'few' => q({0} karáty),
						'many' => q({0} karátu),
						'name' => q(karáty),
						'one' => q({0} karát),
						'other' => q({0} karátov),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} miligramy na deciliter),
						'many' => q({0} miligramu na deciliter),
						'name' => q(miligramy na deciliter),
						'one' => q({0} miligram na deciliter),
						'other' => q({0} miligramov na deciliter),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} miligramy na deciliter),
						'many' => q({0} miligramu na deciliter),
						'name' => q(miligramy na deciliter),
						'one' => q({0} miligram na deciliter),
						'other' => q({0} miligramov na deciliter),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'1' => q(inanimate),
						'few' => q({0} milimoly na liter),
						'many' => q({0} milimolu na liter),
						'name' => q(milimoly na liter),
						'one' => q({0} milimol na liter),
						'other' => q({0} milimolov na liter),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'1' => q(inanimate),
						'few' => q({0} milimoly na liter),
						'many' => q({0} milimolu na liter),
						'name' => q(milimoly na liter),
						'one' => q({0} milimol na liter),
						'other' => q({0} milimolov na liter),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'1' => q(inanimate),
						'few' => q({0} moly),
						'many' => q({0} molu),
						'name' => q(moly),
						'one' => q({0} mol),
						'other' => q({0} molov),
					},
					# Core Unit Identifier
					'mole' => {
						'1' => q(inanimate),
						'few' => q({0} moly),
						'many' => q({0} molu),
						'name' => q(moly),
						'one' => q({0} mol),
						'other' => q({0} molov),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'1' => q(neuter),
						'few' => q({0} percentá),
						'many' => q({0} percenta),
						'name' => q(percentá),
						'one' => q({0} percento),
						'other' => q({0} percent),
					},
					# Core Unit Identifier
					'percent' => {
						'1' => q(neuter),
						'few' => q({0} percentá),
						'many' => q({0} percenta),
						'name' => q(percentá),
						'one' => q({0} percento),
						'other' => q({0} percent),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'1' => q(neuter),
						'few' => q({0} promile),
						'many' => q({0} promile),
						'name' => q(promile),
						'one' => q({0} promile),
						'other' => q({0} promile),
					},
					# Core Unit Identifier
					'permille' => {
						'1' => q(neuter),
						'few' => q({0} promile),
						'many' => q({0} promile),
						'name' => q(promile),
						'one' => q({0} promile),
						'other' => q({0} promile),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'1' => q(feminine),
						'few' => q({0} milióntiny),
						'many' => q({0} milióntiny),
						'name' => q(milióntiny),
						'one' => q({0} milióntina),
						'other' => q({0} milióntin),
					},
					# Core Unit Identifier
					'permillion' => {
						'1' => q(feminine),
						'few' => q({0} milióntiny),
						'many' => q({0} milióntiny),
						'name' => q(milióntiny),
						'one' => q({0} milióntina),
						'other' => q({0} milióntin),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'1' => q(feminine),
						'few' => q({0} desatiny promile),
						'many' => q({0} desatiny promile),
						'name' => q(desatiny promile),
						'one' => q({0} desatina promile),
						'other' => q({0} desatín promile),
					},
					# Core Unit Identifier
					'permyriad' => {
						'1' => q(feminine),
						'few' => q({0} desatiny promile),
						'many' => q({0} desatiny promile),
						'name' => q(desatiny promile),
						'one' => q({0} desatina promile),
						'other' => q({0} desatín promile),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} litre na 100 kilometrov),
						'many' => q({0} litra na 100 kilometrov),
						'name' => q(litre na 100 kilometrov),
						'one' => q({0} liter na 100 kilometrov),
						'other' => q({0} litrov na 100 kilometrov),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} litre na 100 kilometrov),
						'many' => q({0} litra na 100 kilometrov),
						'name' => q(litre na 100 kilometrov),
						'one' => q({0} liter na 100 kilometrov),
						'other' => q({0} litrov na 100 kilometrov),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} litre na kilometer),
						'many' => q({0} litra na kilometer),
						'name' => q(litre na kilometer),
						'one' => q({0} liter na kilometer),
						'other' => q({0} litrov na kilometer),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} litre na kilometer),
						'many' => q({0} litra na kilometer),
						'name' => q(litre na kilometer),
						'one' => q({0} liter na kilometer),
						'other' => q({0} litrov na kilometer),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} míle na galón),
						'many' => q({0} míle na galón),
						'name' => q(míle na galón),
						'one' => q({0} míľa na galón),
						'other' => q({0} míľ na galón),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} míle na galón),
						'many' => q({0} míle na galón),
						'name' => q(míle na galón),
						'one' => q({0} míľa na galón),
						'other' => q({0} míľ na galón),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} míle na britský galón),
						'many' => q({0} míle na britský galón),
						'name' => q(míle na britský galón),
						'one' => q({0} míľa na britský galón),
						'other' => q({0} míľ na britský galón),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} míle na britský galón),
						'many' => q({0} míle na britský galón),
						'name' => q(míle na britský galón),
						'one' => q({0} míľa na britský galón),
						'other' => q({0} míľ na britský galón),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'1' => q(inanimate),
						'few' => q({0} bity),
						'many' => q({0} bitu),
						'name' => q(bity),
						'one' => q({0} bit),
						'other' => q({0} bitov),
					},
					# Core Unit Identifier
					'bit' => {
						'1' => q(inanimate),
						'few' => q({0} bity),
						'many' => q({0} bitu),
						'name' => q(bity),
						'one' => q({0} bit),
						'other' => q({0} bitov),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'1' => q(inanimate),
						'few' => q({0} bajty),
						'many' => q({0} bajtu),
						'name' => q(bajty),
						'one' => q({0} bajt),
						'other' => q({0} bajtov),
					},
					# Core Unit Identifier
					'byte' => {
						'1' => q(inanimate),
						'few' => q({0} bajty),
						'many' => q({0} bajtu),
						'name' => q(bajty),
						'one' => q({0} bajt),
						'other' => q({0} bajtov),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'1' => q(inanimate),
						'few' => q({0} gigabity),
						'many' => q({0} gigabitu),
						'name' => q(gigabity),
						'one' => q({0} gigabit),
						'other' => q({0} gigabitov),
					},
					# Core Unit Identifier
					'gigabit' => {
						'1' => q(inanimate),
						'few' => q({0} gigabity),
						'many' => q({0} gigabitu),
						'name' => q(gigabity),
						'one' => q({0} gigabit),
						'other' => q({0} gigabitov),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'1' => q(inanimate),
						'few' => q({0} gigabajty),
						'many' => q({0} gigabajtu),
						'name' => q(gigabajty),
						'one' => q({0} gigabajt),
						'other' => q({0} gigabajtov),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'1' => q(inanimate),
						'few' => q({0} gigabajty),
						'many' => q({0} gigabajtu),
						'name' => q(gigabajty),
						'one' => q({0} gigabajt),
						'other' => q({0} gigabajtov),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'1' => q(inanimate),
						'few' => q({0} kilobity),
						'many' => q({0} kilobitu),
						'name' => q(kilobity),
						'one' => q({0} kilobit),
						'other' => q({0} kilobitov),
					},
					# Core Unit Identifier
					'kilobit' => {
						'1' => q(inanimate),
						'few' => q({0} kilobity),
						'many' => q({0} kilobitu),
						'name' => q(kilobity),
						'one' => q({0} kilobit),
						'other' => q({0} kilobitov),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'1' => q(inanimate),
						'few' => q({0} kilobajty),
						'many' => q({0} kilobajtu),
						'name' => q(kilobajty),
						'one' => q({0} kilobajt),
						'other' => q({0} kilobajtov),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'1' => q(inanimate),
						'few' => q({0} kilobajty),
						'many' => q({0} kilobajtu),
						'name' => q(kilobajty),
						'one' => q({0} kilobajt),
						'other' => q({0} kilobajtov),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'1' => q(inanimate),
						'few' => q({0} megabity),
						'many' => q({0} megabitu),
						'name' => q(megabity),
						'one' => q({0} megabit),
						'other' => q({0} megabitov),
					},
					# Core Unit Identifier
					'megabit' => {
						'1' => q(inanimate),
						'few' => q({0} megabity),
						'many' => q({0} megabitu),
						'name' => q(megabity),
						'one' => q({0} megabit),
						'other' => q({0} megabitov),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'1' => q(inanimate),
						'few' => q({0} megabajty),
						'many' => q({0} megabajtu),
						'name' => q(megabajty),
						'one' => q({0} megabajt),
						'other' => q({0} megabajtov),
					},
					# Core Unit Identifier
					'megabyte' => {
						'1' => q(inanimate),
						'few' => q({0} megabajty),
						'many' => q({0} megabajtu),
						'name' => q(megabajty),
						'one' => q({0} megabajt),
						'other' => q({0} megabajtov),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'1' => q(inanimate),
						'few' => q({0} petabajty),
						'many' => q({0} petabajtu),
						'name' => q(petabajty),
						'one' => q({0} petabajt),
						'other' => q({0} petabajtov),
					},
					# Core Unit Identifier
					'petabyte' => {
						'1' => q(inanimate),
						'few' => q({0} petabajty),
						'many' => q({0} petabajtu),
						'name' => q(petabajty),
						'one' => q({0} petabajt),
						'other' => q({0} petabajtov),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'1' => q(inanimate),
						'few' => q({0} terabity),
						'many' => q({0} terabitu),
						'name' => q(terabity),
						'one' => q({0} terabit),
						'other' => q({0} terabitov),
					},
					# Core Unit Identifier
					'terabit' => {
						'1' => q(inanimate),
						'few' => q({0} terabity),
						'many' => q({0} terabitu),
						'name' => q(terabity),
						'one' => q({0} terabit),
						'other' => q({0} terabitov),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'1' => q(inanimate),
						'few' => q({0} terabajty),
						'many' => q({0} terabajtu),
						'name' => q(terabajty),
						'one' => q({0} terabajt),
						'other' => q({0} terabajtov),
					},
					# Core Unit Identifier
					'terabyte' => {
						'1' => q(inanimate),
						'few' => q({0} terabajty),
						'many' => q({0} terabajtu),
						'name' => q(terabajty),
						'one' => q({0} terabajt),
						'other' => q({0} terabajtov),
					},
					# Long Unit Identifier
					'duration-century' => {
						'1' => q(neuter),
						'few' => q({0} storočia),
						'many' => q({0} storočia),
						'name' => q(storočia),
						'one' => q({0} storočie),
						'other' => q({0} storočí),
					},
					# Core Unit Identifier
					'century' => {
						'1' => q(neuter),
						'few' => q({0} storočia),
						'many' => q({0} storočia),
						'name' => q(storočia),
						'one' => q({0} storočie),
						'other' => q({0} storočí),
					},
					# Long Unit Identifier
					'duration-day' => {
						'1' => q(inanimate),
						'few' => q({0} dni),
						'many' => q({0} dňa),
						'one' => q({0} deň),
						'other' => q({0} dní),
						'per' => q({0} za deň),
					},
					# Core Unit Identifier
					'day' => {
						'1' => q(inanimate),
						'few' => q({0} dni),
						'many' => q({0} dňa),
						'one' => q({0} deň),
						'other' => q({0} dní),
						'per' => q({0} za deň),
					},
					# Long Unit Identifier
					'duration-day-person' => {
						'1' => q(inanimate),
						'few' => q({0} dni),
						'many' => q({0} dňa),
						'one' => q({0} deň),
						'other' => q({0} dní),
					},
					# Core Unit Identifier
					'day-person' => {
						'1' => q(inanimate),
						'few' => q({0} dni),
						'many' => q({0} dňa),
						'one' => q({0} deň),
						'other' => q({0} dní),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'1' => q(neuter),
						'few' => q({0} desaťročia),
						'many' => q({0} desaťročia),
						'name' => q(desaťročia),
						'one' => q({0} desaťročie),
						'other' => q({0} desaťročí),
					},
					# Core Unit Identifier
					'decade' => {
						'1' => q(neuter),
						'few' => q({0} desaťročia),
						'many' => q({0} desaťročia),
						'name' => q(desaťročia),
						'one' => q({0} desaťročie),
						'other' => q({0} desaťročí),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'1' => q(feminine),
						'few' => q({0} hodiny),
						'many' => q({0} hodiny),
						'name' => q(hodiny),
						'one' => q({0} hodina),
						'other' => q({0} hodín),
						'per' => q({0} za hodinu),
					},
					# Core Unit Identifier
					'hour' => {
						'1' => q(feminine),
						'few' => q({0} hodiny),
						'many' => q({0} hodiny),
						'name' => q(hodiny),
						'one' => q({0} hodina),
						'other' => q({0} hodín),
						'per' => q({0} za hodinu),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'1' => q(feminine),
						'few' => q({0} mikrosekundy),
						'many' => q({0} mikrosekundy),
						'name' => q(mikrosekundy),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekúnd),
					},
					# Core Unit Identifier
					'microsecond' => {
						'1' => q(feminine),
						'few' => q({0} mikrosekundy),
						'many' => q({0} mikrosekundy),
						'name' => q(mikrosekundy),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekúnd),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'1' => q(feminine),
						'few' => q({0} milisekundy),
						'many' => q({0} milisekundy),
						'name' => q(milisekundy),
						'one' => q({0} milisekunda),
						'other' => q({0} milisekúnd),
					},
					# Core Unit Identifier
					'millisecond' => {
						'1' => q(feminine),
						'few' => q({0} milisekundy),
						'many' => q({0} milisekundy),
						'name' => q(milisekundy),
						'one' => q({0} milisekunda),
						'other' => q({0} milisekúnd),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'1' => q(feminine),
						'few' => q({0} minúty),
						'many' => q({0} minúty),
						'name' => q(minúty),
						'one' => q({0} minúta),
						'other' => q({0} minút),
						'per' => q({0} za minútu),
					},
					# Core Unit Identifier
					'minute' => {
						'1' => q(feminine),
						'few' => q({0} minúty),
						'many' => q({0} minúty),
						'name' => q(minúty),
						'one' => q({0} minúta),
						'other' => q({0} minút),
						'per' => q({0} za minútu),
					},
					# Long Unit Identifier
					'duration-month' => {
						'1' => q(inanimate),
						'few' => q({0} mesiace),
						'many' => q({0} mesiaca),
						'name' => q(mesiace),
						'one' => q({0} mesiac),
						'other' => q({0} mesiacov),
						'per' => q({0} za mesiac),
					},
					# Core Unit Identifier
					'month' => {
						'1' => q(inanimate),
						'few' => q({0} mesiace),
						'many' => q({0} mesiaca),
						'name' => q(mesiace),
						'one' => q({0} mesiac),
						'other' => q({0} mesiacov),
						'per' => q({0} za mesiac),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'1' => q(feminine),
						'few' => q({0} nanosekundy),
						'many' => q({0} nanosekundy),
						'name' => q(nanosekundy),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekúnd),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'1' => q(feminine),
						'few' => q({0} nanosekundy),
						'many' => q({0} nanosekundy),
						'name' => q(nanosekundy),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekúnd),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'1' => q(inanimate),
						'few' => q({0} štvrťroky),
						'many' => q({0} štvrťroka),
						'name' => q(štvrťroky),
						'one' => q({0} štvrťrok),
						'other' => q({0} štvrťrokov),
					},
					# Core Unit Identifier
					'quarter' => {
						'1' => q(inanimate),
						'few' => q({0} štvrťroky),
						'many' => q({0} štvrťroka),
						'name' => q(štvrťroky),
						'one' => q({0} štvrťrok),
						'other' => q({0} štvrťrokov),
					},
					# Long Unit Identifier
					'duration-second' => {
						'1' => q(feminine),
						'few' => q({0} sekundy),
						'many' => q({0} sekundy),
						'name' => q(sekundy),
						'one' => q({0} sekunda),
						'other' => q({0} sekúnd),
						'per' => q({0} za sekundu),
					},
					# Core Unit Identifier
					'second' => {
						'1' => q(feminine),
						'few' => q({0} sekundy),
						'many' => q({0} sekundy),
						'name' => q(sekundy),
						'one' => q({0} sekunda),
						'other' => q({0} sekúnd),
						'per' => q({0} za sekundu),
					},
					# Long Unit Identifier
					'duration-week' => {
						'1' => q(inanimate),
						'few' => q({0} týždne),
						'many' => q({0} týždňa),
						'name' => q(týždne),
						'one' => q({0} týždeň),
						'other' => q({0} týždňov),
						'per' => q({0} za týždeň),
					},
					# Core Unit Identifier
					'week' => {
						'1' => q(inanimate),
						'few' => q({0} týždne),
						'many' => q({0} týždňa),
						'name' => q(týždne),
						'one' => q({0} týždeň),
						'other' => q({0} týždňov),
						'per' => q({0} za týždeň),
					},
					# Long Unit Identifier
					'duration-year' => {
						'1' => q(inanimate),
						'few' => q({0} roky),
						'many' => q({0} roka),
						'name' => q(roky),
						'one' => q({0} rok),
						'other' => q({0} rokov),
						'per' => q({0} za rok),
					},
					# Core Unit Identifier
					'year' => {
						'1' => q(inanimate),
						'few' => q({0} roky),
						'many' => q({0} roka),
						'name' => q(roky),
						'one' => q({0} rok),
						'other' => q({0} rokov),
						'per' => q({0} za rok),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'1' => q(inanimate),
						'few' => q({0} ampéry),
						'many' => q({0} ampéra),
						'name' => q(ampéry),
						'one' => q({0} ampér),
						'other' => q({0} ampérov),
					},
					# Core Unit Identifier
					'ampere' => {
						'1' => q(inanimate),
						'few' => q({0} ampéry),
						'many' => q({0} ampéra),
						'name' => q(ampéry),
						'one' => q({0} ampér),
						'other' => q({0} ampérov),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'1' => q(inanimate),
						'few' => q({0} miliampéry),
						'many' => q({0} miliampéra),
						'name' => q(miliampéry),
						'one' => q({0} miliampér),
						'other' => q({0} miliampérov),
					},
					# Core Unit Identifier
					'milliampere' => {
						'1' => q(inanimate),
						'few' => q({0} miliampéry),
						'many' => q({0} miliampéra),
						'name' => q(miliampéry),
						'one' => q({0} miliampér),
						'other' => q({0} miliampérov),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'1' => q(inanimate),
						'few' => q({0} ohmy),
						'many' => q({0} ohmu),
						'name' => q(ohmy),
						'one' => q({0} ohm),
						'other' => q({0} ohmov),
					},
					# Core Unit Identifier
					'ohm' => {
						'1' => q(inanimate),
						'few' => q({0} ohmy),
						'many' => q({0} ohmu),
						'name' => q(ohmy),
						'one' => q({0} ohm),
						'other' => q({0} ohmov),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'1' => q(inanimate),
						'few' => q({0} volty),
						'many' => q({0} voltu),
						'name' => q(volty),
						'one' => q({0} volt),
						'other' => q({0} voltov),
					},
					# Core Unit Identifier
					'volt' => {
						'1' => q(inanimate),
						'few' => q({0} volty),
						'many' => q({0} voltu),
						'name' => q(volty),
						'one' => q({0} volt),
						'other' => q({0} voltov),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'few' => q({0} britské tepelné jednotky),
						'many' => q({0} britskej tepelnej jednotky),
						'name' => q(britské tepelné jednotky),
						'one' => q({0} britská tepelná jednotka),
						'other' => q({0} britských tepelných jednotiek),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'few' => q({0} britské tepelné jednotky),
						'many' => q({0} britskej tepelnej jednotky),
						'name' => q(britské tepelné jednotky),
						'one' => q({0} britská tepelná jednotka),
						'other' => q({0} britských tepelných jednotiek),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'1' => q(feminine),
						'few' => q({0} kalórie),
						'many' => q({0} kalórie),
						'name' => q(kalórie),
						'one' => q({0} kalória),
						'other' => q({0} kalórií),
					},
					# Core Unit Identifier
					'calorie' => {
						'1' => q(feminine),
						'few' => q({0} kalórie),
						'many' => q({0} kalórie),
						'name' => q(kalórie),
						'one' => q({0} kalória),
						'other' => q({0} kalórií),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'few' => q({0} elektrónvolty),
						'many' => q({0} elektrónvoltu),
						'name' => q(elektrónvolty),
						'one' => q({0} elektrónvolt),
						'other' => q({0} elektrónvoltov),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'few' => q({0} elektrónvolty),
						'many' => q({0} elektrónvoltu),
						'name' => q(elektrónvolty),
						'one' => q({0} elektrónvolt),
						'other' => q({0} elektrónvoltov),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} kalórie),
						'many' => q({0} kalórie),
						'name' => q(kalórie),
						'one' => q({0} kalória),
						'other' => q({0} kalórií),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} kalórie),
						'many' => q({0} kalórie),
						'name' => q(kalórie),
						'one' => q({0} kalória),
						'other' => q({0} kalórií),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'1' => q(inanimate),
						'few' => q({0} jouly),
						'many' => q({0} joulu),
						'name' => q(jouly),
						'one' => q(joule),
						'other' => q({0} joulov),
					},
					# Core Unit Identifier
					'joule' => {
						'1' => q(inanimate),
						'few' => q({0} jouly),
						'many' => q({0} joulu),
						'name' => q(jouly),
						'one' => q(joule),
						'other' => q({0} joulov),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'few' => q({0} kilokalórie),
						'many' => q({0} kilokalórie),
						'name' => q(kilokalórie),
						'one' => q({0} kilokalória),
						'other' => q({0} kilokalórií),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'few' => q({0} kilokalórie),
						'many' => q({0} kilokalórie),
						'name' => q(kilokalórie),
						'one' => q({0} kilokalória),
						'other' => q({0} kilokalórií),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'1' => q(inanimate),
						'few' => q({0} kilojouly),
						'many' => q({0} kilojoulu),
						'name' => q(kilojouly),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoulov),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'1' => q(inanimate),
						'few' => q({0} kilojouly),
						'many' => q({0} kilojoulu),
						'name' => q(kilojouly),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoulov),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'1' => q(feminine),
						'few' => q({0} kilowatthodiny),
						'many' => q({0} kilowatthodiny),
						'name' => q(kilowatthodiny),
						'one' => q({0} kilowatthodina),
						'other' => q({0} kilowatthodín),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'1' => q(feminine),
						'few' => q({0} kilowatthodiny),
						'many' => q({0} kilowatthodiny),
						'name' => q(kilowatthodiny),
						'one' => q({0} kilowatthodina),
						'other' => q({0} kilowatthodín),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'few' => q({0} americké termy),
						'many' => q({0} amerického termu),
						'name' => q(americké termy),
						'one' => q({0} americký term),
						'other' => q({0} amerických termov),
					},
					# Core Unit Identifier
					'therm-us' => {
						'few' => q({0} americké termy),
						'many' => q({0} amerického termu),
						'name' => q(americké termy),
						'one' => q({0} americký term),
						'other' => q({0} amerických termov),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'1' => q(feminine),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'1' => q(feminine),
					},
					# Long Unit Identifier
					'force-newton' => {
						'1' => q(inanimate),
						'few' => q({0} newtony),
						'many' => q({0} newtona),
						'name' => q(newtony),
						'one' => q({0} newton),
						'other' => q({0} newtonov),
					},
					# Core Unit Identifier
					'newton' => {
						'1' => q(inanimate),
						'few' => q({0} newtony),
						'many' => q({0} newtona),
						'name' => q(newtony),
						'one' => q({0} newton),
						'other' => q({0} newtonov),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'few' => q({0} libry sily),
						'many' => q({0} libry sily),
						'name' => q(libry sily),
						'one' => q({0} libra sily),
						'other' => q({0} libier sily),
					},
					# Core Unit Identifier
					'pound-force' => {
						'few' => q({0} libry sily),
						'many' => q({0} libry sily),
						'name' => q(libry sily),
						'one' => q({0} libra sily),
						'other' => q({0} libier sily),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'1' => q(inanimate),
						'few' => q({0} gigahertze),
						'many' => q({0} gigahertza),
						'name' => q(gigahertze),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertzov),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'1' => q(inanimate),
						'few' => q({0} gigahertze),
						'many' => q({0} gigahertza),
						'name' => q(gigahertze),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertzov),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'1' => q(inanimate),
						'few' => q({0} hertze),
						'many' => q({0} hertza),
						'name' => q(hertze),
						'one' => q({0} hertz),
						'other' => q({0} hertzov),
					},
					# Core Unit Identifier
					'hertz' => {
						'1' => q(inanimate),
						'few' => q({0} hertze),
						'many' => q({0} hertza),
						'name' => q(hertze),
						'one' => q({0} hertz),
						'other' => q({0} hertzov),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'1' => q(inanimate),
						'few' => q({0} kilohertze),
						'many' => q({0} kilohertza),
						'name' => q(kilohertze),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertzov),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'1' => q(inanimate),
						'few' => q({0} kilohertze),
						'many' => q({0} kilohertza),
						'name' => q(kilohertze),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertzov),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'1' => q(inanimate),
						'few' => q({0} megahertze),
						'many' => q({0} megahertza),
						'name' => q(megahertze),
						'one' => q({0} megahertz),
						'other' => q({0} megahertzov),
					},
					# Core Unit Identifier
					'megahertz' => {
						'1' => q(inanimate),
						'few' => q({0} megahertze),
						'many' => q({0} megahertza),
						'name' => q(megahertze),
						'one' => q({0} megahertz),
						'other' => q({0} megahertzov),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'few' => q({0} body),
						'many' => q({0} bodu),
						'one' => q({0} bod),
						'other' => q({0} bodov),
					},
					# Core Unit Identifier
					'dot' => {
						'few' => q({0} body),
						'many' => q({0} bodu),
						'one' => q({0} bod),
						'other' => q({0} bodov),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} body na centimeter),
						'many' => q({0} bodu na centimeter),
						'name' => q(body na centimeter),
						'one' => q({0} bod na centimeter),
						'other' => q({0} bodov na centimeter),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} body na centimeter),
						'many' => q({0} bodu na centimeter),
						'name' => q(body na centimeter),
						'one' => q({0} bod na centimeter),
						'other' => q({0} bodov na centimeter),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} body na palec),
						'many' => q({0} bodu na palec),
						'name' => q(body na palec),
						'one' => q({0} bod na palec),
						'other' => q({0} bodov na palec),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} body na palec),
						'many' => q({0} bodu na palec),
						'name' => q(body na palec),
						'one' => q({0} bod na palec),
						'other' => q({0} bodov na palec),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'1' => q(inanimate),
					},
					# Core Unit Identifier
					'em' => {
						'1' => q(inanimate),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'1' => q(inanimate),
						'few' => q({0} megapixely),
						'many' => q({0} megapixela),
						'name' => q(megapixely),
						'one' => q({0} megapixel),
						'other' => q({0} megapixelov),
					},
					# Core Unit Identifier
					'megapixel' => {
						'1' => q(inanimate),
						'few' => q({0} megapixely),
						'many' => q({0} megapixela),
						'name' => q(megapixely),
						'one' => q({0} megapixel),
						'other' => q({0} megapixelov),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'1' => q(inanimate),
						'few' => q({0} pixely),
						'many' => q({0} pixela),
						'name' => q(pixely),
						'one' => q({0} pixel),
						'other' => q({0} pixelov),
					},
					# Core Unit Identifier
					'pixel' => {
						'1' => q(inanimate),
						'few' => q({0} pixely),
						'many' => q({0} pixela),
						'name' => q(pixely),
						'one' => q({0} pixel),
						'other' => q({0} pixelov),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} pixely na centimeter),
						'many' => q({0} pixela na centimeter),
						'name' => q(pixely na centimeter),
						'one' => q({0} pixel na centimeter),
						'other' => q({0} pixelov na centimeter),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} pixely na centimeter),
						'many' => q({0} pixela na centimeter),
						'name' => q(pixely na centimeter),
						'one' => q({0} pixel na centimeter),
						'other' => q({0} pixelov na centimeter),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'few' => q({0} pixely na palec),
						'many' => q({0} pixela na palec),
						'name' => q(pixely na palec),
						'one' => q({0} pixel na palec),
						'other' => q({0} pixelov na palec),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'few' => q({0} pixely na palec),
						'many' => q({0} pixela na palec),
						'name' => q(pixely na palec),
						'one' => q({0} pixel na palec),
						'other' => q({0} pixelov na palec),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'few' => q({0} astronomické jednotky),
						'many' => q({0} astronomickej jednotky),
						'name' => q(astronomické jednotky),
						'one' => q({0} astronomická jednotka),
						'other' => q({0} astronomických jednotiek),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'few' => q({0} astronomické jednotky),
						'many' => q({0} astronomickej jednotky),
						'name' => q(astronomické jednotky),
						'one' => q({0} astronomická jednotka),
						'other' => q({0} astronomických jednotiek),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} centimetre),
						'many' => q({0} centimetra),
						'name' => q(centimetre),
						'one' => q({0} centimeter),
						'other' => q({0} centimetrov),
						'per' => q({0} na centimeter),
					},
					# Core Unit Identifier
					'centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} centimetre),
						'many' => q({0} centimetra),
						'name' => q(centimetre),
						'one' => q({0} centimeter),
						'other' => q({0} centimetrov),
						'per' => q({0} na centimeter),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'1' => q(inanimate),
						'few' => q({0} decimetre),
						'many' => q({0} decimetra),
						'name' => q(decimetre),
						'one' => q({0} decimeter),
						'other' => q({0} decimetrov),
					},
					# Core Unit Identifier
					'decimeter' => {
						'1' => q(inanimate),
						'few' => q({0} decimetre),
						'many' => q({0} decimetra),
						'name' => q(decimetre),
						'one' => q({0} decimeter),
						'other' => q({0} decimetrov),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'few' => q({0} siahy),
						'many' => q({0} siahy),
						'name' => q(siahy),
						'one' => q({0} siaha),
						'other' => q({0} siah),
					},
					# Core Unit Identifier
					'fathom' => {
						'few' => q({0} siahy),
						'many' => q({0} siahy),
						'name' => q(siahy),
						'one' => q({0} siaha),
						'other' => q({0} siah),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0} stopy),
						'many' => q({0} stopy),
						'name' => q(stopy),
						'one' => q({0} stopa),
						'other' => q({0} stôp),
						'per' => q({0} na stopu),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0} stopy),
						'many' => q({0} stopy),
						'name' => q(stopy),
						'one' => q({0} stopa),
						'other' => q({0} stôp),
						'per' => q({0} na stopu),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'few' => q({0} furlongy),
						'many' => q({0} furlongu),
						'name' => q(furlongy),
						'one' => q({0} furlong),
						'other' => q({0} furlongov),
					},
					# Core Unit Identifier
					'furlong' => {
						'few' => q({0} furlongy),
						'many' => q({0} furlongu),
						'name' => q(furlongy),
						'one' => q({0} furlong),
						'other' => q({0} furlongov),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0} palce),
						'many' => q({0} palca),
						'name' => q(palce),
						'one' => q({0} palec),
						'other' => q({0} palcov),
						'per' => q({0} na palec),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0} palce),
						'many' => q({0} palca),
						'name' => q(palce),
						'one' => q({0} palec),
						'other' => q({0} palcov),
						'per' => q({0} na palec),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} kilometre),
						'many' => q({0} kilometra),
						'name' => q(kilometre),
						'one' => q({0} kilometer),
						'other' => q({0} kilometrov),
						'per' => q({0} na kilometer),
					},
					# Core Unit Identifier
					'kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} kilometre),
						'many' => q({0} kilometra),
						'name' => q(kilometre),
						'one' => q({0} kilometer),
						'other' => q({0} kilometrov),
						'per' => q({0} na kilometer),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'few' => q({0} svetelné roky),
						'many' => q({0} svetelného roku),
						'name' => q(svetelné roky),
						'one' => q({0} svetelný rok),
						'other' => q({0} svetelných rokov),
					},
					# Core Unit Identifier
					'light-year' => {
						'few' => q({0} svetelné roky),
						'many' => q({0} svetelného roku),
						'name' => q(svetelné roky),
						'one' => q({0} svetelný rok),
						'other' => q({0} svetelných rokov),
					},
					# Long Unit Identifier
					'length-meter' => {
						'1' => q(inanimate),
						'few' => q({0} metre),
						'many' => q({0} metra),
						'name' => q(metre),
						'one' => q({0} meter),
						'other' => q({0} metrov),
						'per' => q({0} na meter),
					},
					# Core Unit Identifier
					'meter' => {
						'1' => q(inanimate),
						'few' => q({0} metre),
						'many' => q({0} metra),
						'name' => q(metre),
						'one' => q({0} meter),
						'other' => q({0} metrov),
						'per' => q({0} na meter),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'1' => q(inanimate),
						'few' => q({0} mikrometre),
						'many' => q({0} mikrometra),
						'name' => q(mikrometre),
						'one' => q({0} mikrometer),
						'other' => q({0} mikrometrov),
					},
					# Core Unit Identifier
					'micrometer' => {
						'1' => q(inanimate),
						'few' => q({0} mikrometre),
						'many' => q({0} mikrometra),
						'name' => q(mikrometre),
						'one' => q({0} mikrometer),
						'other' => q({0} mikrometrov),
					},
					# Long Unit Identifier
					'length-mile' => {
						'few' => q({0} míle),
						'many' => q({0} míle),
						'name' => q(míle),
						'one' => q({0} míľa),
						'other' => q({0} míľ),
					},
					# Core Unit Identifier
					'mile' => {
						'few' => q({0} míle),
						'many' => q({0} míle),
						'name' => q(míle),
						'one' => q({0} míľa),
						'other' => q({0} míľ),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'1' => q(feminine),
						'few' => q({0} škandinávske míle),
						'many' => q({0} škandinávskej míle),
						'name' => q(škandinávske míle),
						'one' => q({0} škandinávska míľa),
						'other' => q({0} škandinávskych míľ),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'1' => q(feminine),
						'few' => q({0} škandinávske míle),
						'many' => q({0} škandinávskej míle),
						'name' => q(škandinávske míle),
						'one' => q({0} škandinávska míľa),
						'other' => q({0} škandinávskych míľ),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'1' => q(inanimate),
						'few' => q({0} milimetre),
						'many' => q({0} milimetra),
						'name' => q(milimetre),
						'one' => q({0} milimeter),
						'other' => q({0} milimetrov),
					},
					# Core Unit Identifier
					'millimeter' => {
						'1' => q(inanimate),
						'few' => q({0} milimetre),
						'many' => q({0} milimetra),
						'name' => q(milimetre),
						'one' => q({0} milimeter),
						'other' => q({0} milimetrov),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'1' => q(inanimate),
						'few' => q({0} nanometre),
						'many' => q({0} nanometra),
						'name' => q(nanometre),
						'one' => q({0} nanometer),
						'other' => q({0} nanometrov),
					},
					# Core Unit Identifier
					'nanometer' => {
						'1' => q(inanimate),
						'few' => q({0} nanometre),
						'many' => q({0} nanometra),
						'name' => q(nanometre),
						'one' => q({0} nanometer),
						'other' => q({0} nanometrov),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0} námorné míle),
						'many' => q({0} námornej míle),
						'name' => q(námorné míle),
						'one' => q({0} námorná míľa),
						'other' => q({0} námorných míľ),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} námorné míle),
						'many' => q({0} námornej míle),
						'name' => q(námorné míle),
						'one' => q({0} námorná míľa),
						'other' => q({0} námorných míľ),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'few' => q({0} parseky),
						'many' => q({0} parseku),
						'name' => q(parseky),
						'one' => q({0} parsek),
						'other' => q({0} parsekov),
					},
					# Core Unit Identifier
					'parsec' => {
						'few' => q({0} parseky),
						'many' => q({0} parseku),
						'name' => q(parseky),
						'one' => q({0} parsek),
						'other' => q({0} parsekov),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'1' => q(inanimate),
						'few' => q({0} pikometre),
						'many' => q({0} pikometra),
						'name' => q(pikometre),
						'one' => q({0} pikometer),
						'other' => q({0} pikometrov),
					},
					# Core Unit Identifier
					'picometer' => {
						'1' => q(inanimate),
						'few' => q({0} pikometre),
						'many' => q({0} pikometra),
						'name' => q(pikometre),
						'one' => q({0} pikometer),
						'other' => q({0} pikometrov),
					},
					# Long Unit Identifier
					'length-point' => {
						'few' => q({0} typografické body),
						'many' => q({0} typografického bodu),
						'name' => q(typografické body),
						'one' => q({0} typografický bod),
						'other' => q({0} typografických bodov),
					},
					# Core Unit Identifier
					'point' => {
						'few' => q({0} typografické body),
						'many' => q({0} typografického bodu),
						'name' => q(typografické body),
						'one' => q({0} typografický bod),
						'other' => q({0} typografických bodov),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'few' => q({0} polomery Slnka),
						'many' => q({0} polomeru Slnka),
						'name' => q(polomer Slnka),
						'one' => q({0} polomer Slnka),
						'other' => q({0} polomerov Slnka),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'few' => q({0} polomery Slnka),
						'many' => q({0} polomeru Slnka),
						'name' => q(polomer Slnka),
						'one' => q({0} polomer Slnka),
						'other' => q({0} polomerov Slnka),
					},
					# Long Unit Identifier
					'length-yard' => {
						'few' => q({0} yardy),
						'many' => q({0} yardu),
						'name' => q(yardy),
						'one' => q({0} yard),
						'other' => q({0} yardov),
					},
					# Core Unit Identifier
					'yard' => {
						'few' => q({0} yardy),
						'many' => q({0} yardu),
						'name' => q(yardy),
						'one' => q({0} yard),
						'other' => q({0} yardov),
					},
					# Long Unit Identifier
					'light-candela' => {
						'1' => q(feminine),
						'few' => q({0} kandely),
						'many' => q({0} kandely),
						'name' => q(kandely),
						'one' => q({0} kandela),
						'other' => q({0} kandel),
					},
					# Core Unit Identifier
					'candela' => {
						'1' => q(feminine),
						'few' => q({0} kandely),
						'many' => q({0} kandely),
						'name' => q(kandely),
						'one' => q({0} kandela),
						'other' => q({0} kandel),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'1' => q(inanimate),
						'few' => q({0} lúmeny),
						'many' => q({0} lúmenu),
						'name' => q(lúmeny),
						'one' => q({0} lúmen),
						'other' => q({0} lúmenov),
					},
					# Core Unit Identifier
					'lumen' => {
						'1' => q(inanimate),
						'few' => q({0} lúmeny),
						'many' => q({0} lúmenu),
						'name' => q(lúmeny),
						'one' => q({0} lúmen),
						'other' => q({0} lúmenov),
					},
					# Long Unit Identifier
					'light-lux' => {
						'1' => q(inanimate),
						'few' => q({0} luxy),
						'many' => q({0} luxu),
						'name' => q(luxy),
						'one' => q({0} lux),
						'other' => q({0} luxov),
					},
					# Core Unit Identifier
					'lux' => {
						'1' => q(inanimate),
						'few' => q({0} luxy),
						'many' => q({0} luxu),
						'name' => q(luxy),
						'one' => q({0} lux),
						'other' => q({0} luxov),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'few' => q({0} svietivosti Slnka),
						'many' => q({0} svietivosti Slnka),
						'name' => q(svietivosti Slnka),
						'one' => q({0} svietivosť Slnka),
						'other' => q({0} svietivostí Slnka),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'few' => q({0} svietivosti Slnka),
						'many' => q({0} svietivosti Slnka),
						'name' => q(svietivosti Slnka),
						'one' => q({0} svietivosť Slnka),
						'other' => q({0} svietivostí Slnka),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'1' => q(inanimate),
						'few' => q({0} karáty),
						'many' => q({0} karátu),
						'name' => q(karáty),
						'one' => q({0} karát),
						'other' => q({0} karátov),
					},
					# Core Unit Identifier
					'carat' => {
						'1' => q(inanimate),
						'few' => q({0} karáty),
						'many' => q({0} karátu),
						'name' => q(karáty),
						'one' => q({0} karát),
						'other' => q({0} karátov),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'few' => q({0} daltony),
						'many' => q({0} daltona),
						'name' => q(daltony),
						'one' => q({0} dalton),
						'other' => q({0} daltonov),
					},
					# Core Unit Identifier
					'dalton' => {
						'few' => q({0} daltony),
						'many' => q({0} daltona),
						'name' => q(daltony),
						'one' => q({0} dalton),
						'other' => q({0} daltonov),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'few' => q({0} hmotnosti Zeme),
						'many' => q({0} hmotnosti Zeme),
						'name' => q(hmotnosti Zeme),
						'one' => q({0} hmotnosť Zeme),
						'other' => q({0} hmotností Zeme),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'few' => q({0} hmotnosti Zeme),
						'many' => q({0} hmotnosti Zeme),
						'name' => q(hmotnosti Zeme),
						'one' => q({0} hmotnosť Zeme),
						'other' => q({0} hmotností Zeme),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'1' => q(inanimate),
						'few' => q({0} gramy),
						'many' => q({0} gramu),
						'name' => q(gramy),
						'one' => q({0} gram),
						'other' => q({0} gramov),
						'per' => q({0} na gram),
					},
					# Core Unit Identifier
					'gram' => {
						'1' => q(inanimate),
						'few' => q({0} gramy),
						'many' => q({0} gramu),
						'name' => q(gramy),
						'one' => q({0} gram),
						'other' => q({0} gramov),
						'per' => q({0} na gram),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'1' => q(inanimate),
						'few' => q({0} kilogramy),
						'many' => q({0} kilogramu),
						'name' => q(kilogramy),
						'one' => q({0} kilogram),
						'other' => q({0} kilogramov),
						'per' => q({0} na kilogram),
					},
					# Core Unit Identifier
					'kilogram' => {
						'1' => q(inanimate),
						'few' => q({0} kilogramy),
						'many' => q({0} kilogramu),
						'name' => q(kilogramy),
						'one' => q({0} kilogram),
						'other' => q({0} kilogramov),
						'per' => q({0} na kilogram),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'1' => q(inanimate),
						'few' => q({0} mikrogramy),
						'many' => q({0} mikrogramu),
						'name' => q(mikrogramy),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogramov),
					},
					# Core Unit Identifier
					'microgram' => {
						'1' => q(inanimate),
						'few' => q({0} mikrogramy),
						'many' => q({0} mikrogramu),
						'name' => q(mikrogramy),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogramov),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'1' => q(inanimate),
						'few' => q({0} miligramy),
						'many' => q({0} miligramu),
						'name' => q(miligramy),
						'one' => q({0} miligram),
						'other' => q({0} miligramov),
					},
					# Core Unit Identifier
					'milligram' => {
						'1' => q(inanimate),
						'few' => q({0} miligramy),
						'many' => q({0} miligramu),
						'name' => q(miligramy),
						'one' => q({0} miligram),
						'other' => q({0} miligramov),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'few' => q({0} unce),
						'many' => q({0} unce),
						'name' => q(unce),
						'one' => q({0} unca),
						'other' => q({0} uncí),
						'per' => q({0} na uncu),
					},
					# Core Unit Identifier
					'ounce' => {
						'few' => q({0} unce),
						'many' => q({0} unce),
						'name' => q(unce),
						'one' => q({0} unca),
						'other' => q({0} uncí),
						'per' => q({0} na uncu),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'few' => q({0} trojské unce),
						'many' => q({0} trojskej unce),
						'name' => q(trojské unce),
						'one' => q({0} trojská unca),
						'other' => q({0} trojských uncí),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'few' => q({0} trojské unce),
						'many' => q({0} trojskej unce),
						'name' => q(trojské unce),
						'one' => q({0} trojská unca),
						'other' => q({0} trojských uncí),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'few' => q({0} libry),
						'many' => q({0} libry),
						'name' => q(libry),
						'one' => q({0} libra),
						'other' => q({0} libier),
						'per' => q({0} na libru),
					},
					# Core Unit Identifier
					'pound' => {
						'few' => q({0} libry),
						'many' => q({0} libry),
						'name' => q(libry),
						'one' => q({0} libra),
						'other' => q({0} libier),
						'per' => q({0} na libru),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'few' => q({0} hmotnosti Slnka),
						'many' => q({0} hmotnosti Slnka),
						'name' => q(hmotnosti Slnka),
						'one' => q({0} hmotnosť Slnka),
						'other' => q({0} hmotností Slnka),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'few' => q({0} hmotnosti Slnka),
						'many' => q({0} hmotnosti Slnka),
						'name' => q(hmotnosti Slnka),
						'one' => q({0} hmotnosť Slnka),
						'other' => q({0} hmotností Slnka),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'few' => q({0} kamene),
						'many' => q({0} kameňa),
						'name' => q(kamene),
						'one' => q({0} kameň),
						'other' => q({0} kameňov),
					},
					# Core Unit Identifier
					'stone' => {
						'few' => q({0} kamene),
						'many' => q({0} kameňa),
						'name' => q(kamene),
						'one' => q({0} kameň),
						'other' => q({0} kameňov),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'few' => q({0} americké tony),
						'many' => q({0} americkej tony),
						'name' => q(americké tony),
						'one' => q({0} americká tona),
						'other' => q({0} amerických ton),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} americké tony),
						'many' => q({0} americkej tony),
						'name' => q(americké tony),
						'one' => q({0} americká tona),
						'other' => q({0} amerických ton),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'1' => q(feminine),
						'few' => q({0} tony),
						'many' => q({0} tony),
						'name' => q(tony),
						'one' => q({0} tona),
						'other' => q({0} ton),
					},
					# Core Unit Identifier
					'tonne' => {
						'1' => q(feminine),
						'few' => q({0} tony),
						'many' => q({0} tony),
						'name' => q(tony),
						'one' => q({0} tona),
						'other' => q({0} ton),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'1' => q(inanimate),
						'few' => q({0} gigawatty),
						'many' => q({0} gigawattu),
						'name' => q(gigawatty),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawattov),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'1' => q(inanimate),
						'few' => q({0} gigawatty),
						'many' => q({0} gigawattu),
						'name' => q(gigawatty),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawattov),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'few' => q({0} konské sily),
						'many' => q({0} konskej sily),
						'name' => q(konské sily),
						'one' => q({0} konská sila),
						'other' => q({0} konských síl),
					},
					# Core Unit Identifier
					'horsepower' => {
						'few' => q({0} konské sily),
						'many' => q({0} konskej sily),
						'name' => q(konské sily),
						'one' => q({0} konská sila),
						'other' => q({0} konských síl),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'1' => q(inanimate),
						'few' => q({0} kilowatty),
						'many' => q({0} kilowattu),
						'name' => q(kilowatty),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowattov),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'1' => q(inanimate),
						'few' => q({0} kilowatty),
						'many' => q({0} kilowattu),
						'name' => q(kilowatty),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowattov),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'1' => q(inanimate),
						'few' => q({0} megawatty),
						'many' => q({0} megawattu),
						'name' => q(megawatty),
						'one' => q({0} megawatt),
						'other' => q({0} megawattov),
					},
					# Core Unit Identifier
					'megawatt' => {
						'1' => q(inanimate),
						'few' => q({0} megawatty),
						'many' => q({0} megawattu),
						'name' => q(megawatty),
						'one' => q({0} megawatt),
						'other' => q({0} megawattov),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'1' => q(inanimate),
						'few' => q({0} milliwatty),
						'many' => q({0} milliwattu),
						'name' => q(milliwatty),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwattov),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'1' => q(inanimate),
						'few' => q({0} milliwatty),
						'many' => q({0} milliwattu),
						'name' => q(milliwatty),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwattov),
					},
					# Long Unit Identifier
					'power-watt' => {
						'1' => q(inanimate),
						'few' => q({0} watty),
						'many' => q({0} wattu),
						'name' => q(watty),
						'one' => q({0} watt),
						'other' => q({0} wattov),
					},
					# Core Unit Identifier
					'watt' => {
						'1' => q(inanimate),
						'few' => q({0} watty),
						'many' => q({0} wattu),
						'name' => q(watty),
						'one' => q({0} watt),
						'other' => q({0} wattov),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q(štvorcové {0}),
						'few' => q(štvorcové {0}),
						'many' => q(štvorcového {0}),
						'one' => q(štvorcový {0}),
						'other' => q(štvorcových {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q(štvorcové {0}),
						'few' => q(štvorcové {0}),
						'many' => q(štvorcového {0}),
						'one' => q(štvorcový {0}),
						'other' => q(štvorcových {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q(kubické {0}),
						'few' => q(kubické {0}),
						'many' => q(kubického {0}),
						'one' => q(kubický {0}),
						'other' => q(kubických {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q(kubické {0}),
						'few' => q(kubické {0}),
						'many' => q(kubického {0}),
						'one' => q(kubický {0}),
						'other' => q(kubických {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'1' => q(feminine),
						'few' => q({0} atmosféry),
						'many' => q({0} atmosféry),
						'name' => q(atmosféry),
						'one' => q({0} atmosféra),
						'other' => q({0} atmosfér),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'1' => q(feminine),
						'few' => q({0} atmosféry),
						'many' => q({0} atmosféry),
						'name' => q(atmosféry),
						'one' => q({0} atmosféra),
						'other' => q({0} atmosfér),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'1' => q(inanimate),
						'few' => q({0} bary),
						'many' => q({0} baru),
						'name' => q(bary),
						'one' => q({0} bar),
						'other' => q({0} barov),
					},
					# Core Unit Identifier
					'bar' => {
						'1' => q(inanimate),
						'few' => q({0} bary),
						'many' => q({0} baru),
						'name' => q(bary),
						'one' => q({0} bar),
						'other' => q({0} barov),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'1' => q(inanimate),
						'few' => q({0} hektopascaly),
						'many' => q({0} hektopascala),
						'name' => q(hektopascaly),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascalov),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'1' => q(inanimate),
						'few' => q({0} hektopascaly),
						'many' => q({0} hektopascala),
						'name' => q(hektopascaly),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascalov),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'few' => q({0} palce ortuťového stĺpca),
						'many' => q({0} palca ortuťového stĺpca),
						'name' => q(palce ortuťového stĺpca),
						'one' => q({0} palec ortuťového stĺpca),
						'other' => q({0} palcov ortuťového stĺpca),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'few' => q({0} palce ortuťového stĺpca),
						'many' => q({0} palca ortuťového stĺpca),
						'name' => q(palce ortuťového stĺpca),
						'one' => q({0} palec ortuťového stĺpca),
						'other' => q({0} palcov ortuťového stĺpca),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'1' => q(inanimate),
						'few' => q({0} kilopascaly),
						'many' => q({0} kilopascala),
						'name' => q(kilopascaly),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascalov),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'1' => q(inanimate),
						'few' => q({0} kilopascaly),
						'many' => q({0} kilopascala),
						'name' => q(kilopascaly),
						'one' => q({0} kilopascal),
						'other' => q({0} kilopascalov),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'1' => q(inanimate),
						'few' => q({0} megapascaly),
						'many' => q({0} megapascala),
						'name' => q(megapascaly),
						'one' => q({0} megapascal),
						'other' => q({0} megapascalov),
					},
					# Core Unit Identifier
					'megapascal' => {
						'1' => q(inanimate),
						'few' => q({0} megapascaly),
						'many' => q({0} megapascala),
						'name' => q(megapascaly),
						'one' => q({0} megapascal),
						'other' => q({0} megapascalov),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'1' => q(inanimate),
						'few' => q({0} milibary),
						'many' => q({0} milibaru),
						'name' => q(milibary),
						'one' => q({0} milibar),
						'other' => q({0} milibarov),
					},
					# Core Unit Identifier
					'millibar' => {
						'1' => q(inanimate),
						'few' => q({0} milibary),
						'many' => q({0} milibaru),
						'name' => q(milibary),
						'one' => q({0} milibar),
						'other' => q({0} milibarov),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'few' => q({0} milimetre ortuťového stĺpca),
						'many' => q({0} milimetra ortuťového stĺpca),
						'name' => q(milimetre ortuťového stĺpca),
						'one' => q({0} milimeter ortuťového stĺpca),
						'other' => q({0} milimetrov ortuťového stĺpca),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'few' => q({0} milimetre ortuťového stĺpca),
						'many' => q({0} milimetra ortuťového stĺpca),
						'name' => q(milimetre ortuťového stĺpca),
						'one' => q({0} milimeter ortuťového stĺpca),
						'other' => q({0} milimetrov ortuťového stĺpca),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'1' => q(inanimate),
						'few' => q({0} pascaly),
						'many' => q({0} pascala),
						'name' => q(pascaly),
						'one' => q(pascal),
						'other' => q({0} pascalov),
					},
					# Core Unit Identifier
					'pascal' => {
						'1' => q(inanimate),
						'few' => q({0} pascaly),
						'many' => q({0} pascala),
						'name' => q(pascaly),
						'one' => q(pascal),
						'other' => q({0} pascalov),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'few' => q({0} libry sily na štvorcový palec),
						'many' => q({0} libry sily na štvorcový palec),
						'name' => q(libry sily na štvorcový palec),
						'one' => q({0} libra sily na štvorcový palec),
						'other' => q({0} libier sily na štvorcový palec),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'few' => q({0} libry sily na štvorcový palec),
						'many' => q({0} libry sily na štvorcový palec),
						'name' => q(libry sily na štvorcový palec),
						'one' => q({0} libra sily na štvorcový palec),
						'other' => q({0} libier sily na štvorcový palec),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'few' => q({0} stupne Beaufortovej stupnice),
						'many' => q({0} stupňa Beaufortovej stupnice),
						'name' => q(stupeň Beaufortovej stupnice),
						'one' => q({0} stupeň Beaufortovej stupnice),
						'other' => q({0} stupňov Beaufortovej stupnice),
					},
					# Core Unit Identifier
					'beaufort' => {
						'few' => q({0} stupne Beaufortovej stupnice),
						'many' => q({0} stupňa Beaufortovej stupnice),
						'name' => q(stupeň Beaufortovej stupnice),
						'one' => q({0} stupeň Beaufortovej stupnice),
						'other' => q({0} stupňov Beaufortovej stupnice),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'1' => q(inanimate),
						'few' => q({0} kilometre za hodinu),
						'many' => q({0} kilometra za hodinu),
						'name' => q(kilometre za hodinu),
						'one' => q({0} kilometer za hodinu),
						'other' => q({0} kilometrov za hodinu),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'1' => q(inanimate),
						'few' => q({0} kilometre za hodinu),
						'many' => q({0} kilometra za hodinu),
						'name' => q(kilometre za hodinu),
						'one' => q({0} kilometer za hodinu),
						'other' => q({0} kilometrov za hodinu),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'few' => q({0} uzly),
						'many' => q({0} uzla),
						'name' => q(uzly),
						'one' => q({0} uzol),
						'other' => q({0} uzlov),
					},
					# Core Unit Identifier
					'knot' => {
						'few' => q({0} uzly),
						'many' => q({0} uzla),
						'name' => q(uzly),
						'one' => q({0} uzol),
						'other' => q({0} uzlov),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'1' => q(inanimate),
						'few' => q({0} metre za sekundu),
						'many' => q({0} metra za sekundu),
						'name' => q(metre za sekundu),
						'one' => q({0} meter za sekundu),
						'other' => q({0} metrov za sekundu),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'1' => q(inanimate),
						'few' => q({0} metre za sekundu),
						'many' => q({0} metra za sekundu),
						'name' => q(metre za sekundu),
						'one' => q({0} meter za sekundu),
						'other' => q({0} metrov za sekundu),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'few' => q({0} míle za hodinu),
						'many' => q({0} míle za hodinu),
						'name' => q(míle za hodinu),
						'one' => q({0} míľa za hodinu),
						'other' => q({0} míľ za hodinu),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'few' => q({0} míle za hodinu),
						'many' => q({0} míle za hodinu),
						'name' => q(míle za hodinu),
						'one' => q({0} míľa za hodinu),
						'other' => q({0} míľ za hodinu),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'1' => q(inanimate),
						'few' => q({0} stupne Celzia),
						'many' => q({0} stupňa Celzia),
						'name' => q(stupne Celzia),
						'one' => q({0} stupeň Celzia),
						'other' => q({0} stupňov Celzia),
					},
					# Core Unit Identifier
					'celsius' => {
						'1' => q(inanimate),
						'few' => q({0} stupne Celzia),
						'many' => q({0} stupňa Celzia),
						'name' => q(stupne Celzia),
						'one' => q({0} stupeň Celzia),
						'other' => q({0} stupňov Celzia),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0} stupne Fahrenheita),
						'many' => q({0} stupňa Fahrenheita),
						'name' => q(stupne Fahrenheita),
						'one' => q({0} stupeň Fahrenheita),
						'other' => q({0} stupňov Fahrenheita),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0} stupne Fahrenheita),
						'many' => q({0} stupňa Fahrenheita),
						'name' => q(stupne Fahrenheita),
						'one' => q({0} stupeň Fahrenheita),
						'other' => q({0} stupňov Fahrenheita),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'1' => q(inanimate),
						'few' => q({0} stupne),
						'many' => q({0} stupňa),
						'name' => q(stupne),
						'one' => q({0} stupeň),
						'other' => q({0} stupňov),
					},
					# Core Unit Identifier
					'generic' => {
						'1' => q(inanimate),
						'few' => q({0} stupne),
						'many' => q({0} stupňa),
						'name' => q(stupne),
						'one' => q({0} stupeň),
						'other' => q({0} stupňov),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'1' => q(inanimate),
						'few' => q({0} kelviny),
						'many' => q({0} kelvina),
						'name' => q(kelviny),
						'one' => q({0} kelvin),
						'other' => q({0} kelvinov),
					},
					# Core Unit Identifier
					'kelvin' => {
						'1' => q(inanimate),
						'few' => q({0} kelviny),
						'many' => q({0} kelvina),
						'name' => q(kelviny),
						'one' => q({0} kelvin),
						'other' => q({0} kelvinov),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'1' => q(inanimate),
						'few' => q({0} newtonmetre),
						'many' => q({0} newtonmetra),
						'name' => q(newtonmetre),
						'one' => q({0} newtonmeter),
						'other' => q({0} newtonmetrov),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'1' => q(inanimate),
						'few' => q({0} newtonmetre),
						'many' => q({0} newtonmetra),
						'name' => q(newtonmetre),
						'one' => q({0} newtonmeter),
						'other' => q({0} newtonmetrov),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'few' => q({0} librostopy),
						'many' => q({0} librostopy),
						'name' => q(librostopy),
						'one' => q({0} librostopa),
						'other' => q({0} librostôp),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'few' => q({0} librostopy),
						'many' => q({0} librostopy),
						'name' => q(librostopy),
						'one' => q({0} librostopa),
						'other' => q({0} librostôp),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'few' => q({0} akrové stopy),
						'many' => q({0} akrovej stopy),
						'name' => q(akrové stopy),
						'one' => q({0} akrová stopa),
						'other' => q({0} akrových stôp),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'few' => q({0} akrové stopy),
						'many' => q({0} akrovej stopy),
						'name' => q(akrové stopy),
						'one' => q({0} akrová stopa),
						'other' => q({0} akrových stôp),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'few' => q({0} barely),
						'many' => q({0} barelu),
						'name' => q(barely),
						'one' => q({0} barel),
						'other' => q({0} barelov),
					},
					# Core Unit Identifier
					'barrel' => {
						'few' => q({0} barely),
						'many' => q({0} barelu),
						'name' => q(barely),
						'one' => q({0} barel),
						'other' => q({0} barelov),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'few' => q({0} bušle),
						'many' => q({0} bušla),
						'name' => q(bušle),
						'one' => q({0} bušel),
						'other' => q({0} bušlov),
					},
					# Core Unit Identifier
					'bushel' => {
						'few' => q({0} bušle),
						'many' => q({0} bušla),
						'name' => q(bušle),
						'one' => q({0} bušel),
						'other' => q({0} bušlov),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'1' => q(inanimate),
						'few' => q({0} centilitre),
						'many' => q({0} centilitra),
						'name' => q(centilitre),
						'one' => q({0} centiliter),
						'other' => q({0} centilitrov),
					},
					# Core Unit Identifier
					'centiliter' => {
						'1' => q(inanimate),
						'few' => q({0} centilitre),
						'many' => q({0} centilitra),
						'name' => q(centilitre),
						'one' => q({0} centiliter),
						'other' => q({0} centilitrov),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} kubické centimetre),
						'many' => q({0} kubického centimetra),
						'name' => q(kubické centimetre),
						'one' => q({0} kubický centimeter),
						'other' => q({0} kubických centimetrov),
						'per' => q({0} na kubický centimeter),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'1' => q(inanimate),
						'few' => q({0} kubické centimetre),
						'many' => q({0} kubického centimetra),
						'name' => q(kubické centimetre),
						'one' => q({0} kubický centimeter),
						'other' => q({0} kubických centimetrov),
						'per' => q({0} na kubický centimeter),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'few' => q({0} kubické stopy),
						'many' => q({0} kubickej stopy),
						'name' => q(kubické stopy),
						'one' => q({0} kubická stopa),
						'other' => q({0} kubických stôp),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'few' => q({0} kubické stopy),
						'many' => q({0} kubickej stopy),
						'name' => q(kubické stopy),
						'one' => q({0} kubická stopa),
						'other' => q({0} kubických stôp),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'few' => q({0} kubické palce),
						'many' => q({0} kubického palca),
						'name' => q(kubické palce),
						'one' => q({0} kubický palec),
						'other' => q({0} kubických palcov),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'few' => q({0} kubické palce),
						'many' => q({0} kubického palca),
						'name' => q(kubické palce),
						'one' => q({0} kubický palec),
						'other' => q({0} kubických palcov),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} kubické kilometre),
						'many' => q({0} kubického kilometra),
						'name' => q(kubické kilometre),
						'one' => q({0} kubický kilometer),
						'other' => q({0} kubických kilometrov),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'1' => q(inanimate),
						'few' => q({0} kubické kilometre),
						'many' => q({0} kubického kilometra),
						'name' => q(kubické kilometre),
						'one' => q({0} kubický kilometer),
						'other' => q({0} kubických kilometrov),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'1' => q(inanimate),
						'few' => q({0} kubické metre),
						'many' => q({0} kubického metra),
						'name' => q(kubické metre),
						'one' => q({0} kubický meter),
						'other' => q({0} kubických metrov),
						'per' => q({0} na kubický meter),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'1' => q(inanimate),
						'few' => q({0} kubické metre),
						'many' => q({0} kubického metra),
						'name' => q(kubické metre),
						'one' => q({0} kubický meter),
						'other' => q({0} kubických metrov),
						'per' => q({0} na kubický meter),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'few' => q({0} kubické míle),
						'many' => q({0} kubickej míle),
						'name' => q(kubické míle),
						'one' => q({0} kubická míľa),
						'other' => q({0} kubických míľ),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'few' => q({0} kubické míle),
						'many' => q({0} kubickej míle),
						'name' => q(kubické míle),
						'one' => q({0} kubická míľa),
						'other' => q({0} kubických míľ),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'few' => q({0} kubické yardy),
						'many' => q({0} kubického yardu),
						'name' => q(kubické yardy),
						'one' => q({0} kubický yard),
						'other' => q({0} kubických yardov),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'few' => q({0} kubické yardy),
						'many' => q({0} kubického yardu),
						'name' => q(kubické yardy),
						'one' => q({0} kubický yard),
						'other' => q({0} kubických yardov),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'few' => q({0} hrnčeky),
						'many' => q({0} hrnčeka),
						'name' => q(hrnčeky),
						'one' => q({0} hrnček),
						'other' => q({0} hrnčekov),
					},
					# Core Unit Identifier
					'cup' => {
						'few' => q({0} hrnčeky),
						'many' => q({0} hrnčeka),
						'name' => q(hrnčeky),
						'one' => q({0} hrnček),
						'other' => q({0} hrnčekov),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'1' => q(inanimate),
						'few' => q({0} metrické hrnčeky),
						'many' => q({0} metrického hrnčeka),
						'name' => q(metrické hrnčeky),
						'one' => q({0} metrický hrnček),
						'other' => q({0} metrických hrnčekov),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'1' => q(inanimate),
						'few' => q({0} metrické hrnčeky),
						'many' => q({0} metrického hrnčeka),
						'name' => q(metrické hrnčeky),
						'one' => q({0} metrický hrnček),
						'other' => q({0} metrických hrnčekov),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'1' => q(inanimate),
						'few' => q({0} decilitre),
						'many' => q({0} decilitra),
						'name' => q(decilitre),
						'one' => q({0} deciliter),
						'other' => q({0} decilitrov),
					},
					# Core Unit Identifier
					'deciliter' => {
						'1' => q(inanimate),
						'few' => q({0} decilitre),
						'many' => q({0} decilitra),
						'name' => q(decilitre),
						'one' => q({0} deciliter),
						'other' => q({0} decilitrov),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'few' => q({0} dezertné lyžičky),
						'many' => q({0} dezertnej lyžičky),
						'name' => q(dezertné lyžičky),
						'one' => q({0} dezertná lyžička),
						'other' => q({0} dezertných lyžičiek),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'few' => q({0} dezertné lyžičky),
						'many' => q({0} dezertnej lyžičky),
						'name' => q(dezertné lyžičky),
						'one' => q({0} dezertná lyžička),
						'other' => q({0} dezertných lyžičiek),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'few' => q({0} britské dezertné lyžičky),
						'many' => q({0} britskej dezertnej lyžičky),
						'name' => q(britské dezertné lyžičky),
						'one' => q({0} britská dezertná lyžička),
						'other' => q({0} britských dezertných lyžičiek),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'few' => q({0} britské dezertné lyžičky),
						'many' => q({0} britskej dezertnej lyžičky),
						'name' => q(britské dezertné lyžičky),
						'one' => q({0} britská dezertná lyžička),
						'other' => q({0} britských dezertných lyžičiek),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} drachmy),
						'many' => q({0} drachmy),
						'name' => q(drachmy),
						'one' => q({0} drachma),
						'other' => q({0} drachiem),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} drachmy),
						'many' => q({0} drachmy),
						'name' => q(drachmy),
						'one' => q({0} drachma),
						'other' => q({0} drachiem),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} tekuté unce),
						'many' => q({0} tekutej unce),
						'name' => q(tekuté unce),
						'one' => q({0} tekutá unca),
						'other' => q({0} tekutých uncí),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} tekuté unce),
						'many' => q({0} tekutej unce),
						'name' => q(tekuté unce),
						'one' => q({0} tekutá unca),
						'other' => q({0} tekutých uncí),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} britské tekuté unce),
						'many' => q({0} britskej tekutej unce),
						'name' => q(britské tekuté unce),
						'one' => q({0} britská tekutá unca),
						'other' => q({0} britských tekutých uncí),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} britské tekuté unce),
						'many' => q({0} britskej tekutej unce),
						'name' => q(britské tekuté unce),
						'one' => q({0} britská tekutá unca),
						'other' => q({0} britských tekutých uncí),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} galóny),
						'many' => q({0} galónu),
						'name' => q(galóny),
						'one' => q({0} galón),
						'other' => q({0} galónov),
						'per' => q({0} na galón),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} galóny),
						'many' => q({0} galónu),
						'name' => q(galóny),
						'one' => q({0} galón),
						'other' => q({0} galónov),
						'per' => q({0} na galón),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} britské galóny),
						'many' => q({0} britského galónu),
						'name' => q(britské galóny),
						'one' => q({0} britský galón),
						'other' => q({0} britských galónov),
						'per' => q({0} na britský galón),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} britské galóny),
						'many' => q({0} britského galónu),
						'name' => q(britské galóny),
						'one' => q({0} britský galón),
						'other' => q({0} britských galónov),
						'per' => q({0} na britský galón),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'1' => q(inanimate),
						'few' => q({0} hektolitre),
						'many' => q({0} hektolitra),
						'name' => q(hektolitre),
						'one' => q({0} hektoliter),
						'other' => q({0} hektolitrov),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'1' => q(inanimate),
						'few' => q({0} hektolitre),
						'many' => q({0} hektolitra),
						'name' => q(hektolitre),
						'one' => q({0} hektoliter),
						'other' => q({0} hektolitrov),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} barmanské odmerky),
						'many' => q({0} barmanskej odmerky),
						'name' => q(barmanské odmerky),
						'one' => q({0} barmanská odmerka),
						'other' => q({0} barmanských odmeriek),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} barmanské odmerky),
						'many' => q({0} barmanskej odmerky),
						'name' => q(barmanské odmerky),
						'one' => q({0} barmanská odmerka),
						'other' => q({0} barmanských odmeriek),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'1' => q(inanimate),
						'few' => q({0} litre),
						'many' => q({0} litra),
						'name' => q(litre),
						'one' => q({0} liter),
						'other' => q({0} litrov),
						'per' => q({0} na liter),
					},
					# Core Unit Identifier
					'liter' => {
						'1' => q(inanimate),
						'few' => q({0} litre),
						'many' => q({0} litra),
						'name' => q(litre),
						'one' => q({0} liter),
						'other' => q({0} litrov),
						'per' => q({0} na liter),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'1' => q(inanimate),
						'few' => q({0} megalitre),
						'many' => q({0} megalitra),
						'name' => q(megalitre),
						'one' => q({0} megaliter),
						'other' => q({0} megalitrov),
					},
					# Core Unit Identifier
					'megaliter' => {
						'1' => q(inanimate),
						'few' => q({0} megalitre),
						'many' => q({0} megalitra),
						'name' => q(megalitre),
						'one' => q({0} megaliter),
						'other' => q({0} megalitrov),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'1' => q(inanimate),
						'few' => q({0} mililitre),
						'many' => q({0} mililitra),
						'name' => q(mililitre),
						'one' => q({0} mililiter),
						'other' => q({0} mililitrov),
					},
					# Core Unit Identifier
					'milliliter' => {
						'1' => q(inanimate),
						'few' => q({0} mililitre),
						'many' => q({0} mililitra),
						'name' => q(mililitre),
						'one' => q({0} mililiter),
						'other' => q({0} mililitrov),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'few' => q({0} pinty),
						'many' => q({0} pinty),
						'name' => q(pinty),
						'one' => q({0} pinta),
						'other' => q({0} pínt),
					},
					# Core Unit Identifier
					'pint' => {
						'few' => q({0} pinty),
						'many' => q({0} pinty),
						'name' => q(pinty),
						'one' => q({0} pinta),
						'other' => q({0} pínt),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'1' => q(feminine),
						'few' => q({0} metrické pinty),
						'many' => q({0} metrickej pinty),
						'name' => q(metrické pinty),
						'one' => q({0} metrická pinta),
						'other' => q({0} metrických pínt),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'1' => q(feminine),
						'few' => q({0} metrické pinty),
						'many' => q({0} metrickej pinty),
						'name' => q(metrické pinty),
						'one' => q({0} metrická pinta),
						'other' => q({0} metrických pínt),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'few' => q({0} quarty),
						'many' => q({0} quartu),
						'name' => q(quarty),
						'one' => q({0} quart),
						'other' => q({0} quartov),
					},
					# Core Unit Identifier
					'quart' => {
						'few' => q({0} quarty),
						'many' => q({0} quartu),
						'name' => q(quarty),
						'one' => q({0} quart),
						'other' => q({0} quartov),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} britské kvarty),
						'many' => q({0} britského kvartu),
						'name' => q(britské kvarty),
						'one' => q({0} britský kvart),
						'other' => q({0} britských kvartov),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} britské kvarty),
						'many' => q({0} britského kvartu),
						'name' => q(britské kvarty),
						'one' => q({0} britský kvart),
						'other' => q({0} britských kvartov),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'few' => q({0} polievkové lyžice),
						'many' => q({0} polievkovej lyžice),
						'name' => q(polievkové lyžice),
						'one' => q({0} polievková lyžica),
						'other' => q({0} polievkových lyžíc),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'few' => q({0} polievkové lyžice),
						'many' => q({0} polievkovej lyžice),
						'name' => q(polievkové lyžice),
						'one' => q({0} polievková lyžica),
						'other' => q({0} polievkových lyžíc),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'few' => q({0} čajové lyžice),
						'many' => q({0} čajovej lyžice),
						'name' => q(čajové lyžice),
						'one' => q({0} čajová lyžica),
						'other' => q({0} čajových lyžíc),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'few' => q({0} čajové lyžice),
						'many' => q({0} čajovej lyžice),
						'name' => q(čajové lyžice),
						'one' => q({0} čajová lyžica),
						'other' => q({0} čajových lyžíc),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'few' => q({0}G),
						'many' => q({0}G),
						'name' => q(G),
						'one' => q({0}G),
						'other' => q({0}G),
					},
					# Core Unit Identifier
					'g-force' => {
						'few' => q({0}G),
						'many' => q({0}G),
						'name' => q(G),
						'one' => q({0}G),
						'other' => q({0}G),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ac),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ac),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ha),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(l/100 km),
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
					'duration-day' => {
						'few' => q({0} d.),
						'many' => q({0} d.),
						'name' => q(d.),
						'one' => q({0} d.),
						'other' => q({0} d.),
						'per' => q({0}/d.),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} d.),
						'many' => q({0} d.),
						'name' => q(d.),
						'one' => q({0} d.),
						'other' => q({0} d.),
						'per' => q({0}/d.),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} m.),
						'many' => q({0} m.),
						'name' => q(m.),
						'one' => q({0} m.),
						'other' => q({0} m.),
						'per' => q({0}/m.),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} m.),
						'many' => q({0} m.),
						'name' => q(m.),
						'one' => q({0} m.),
						'other' => q({0} m.),
						'per' => q({0}/m.),
					},
					# Long Unit Identifier
					'duration-week' => {
						'few' => q({0} t.),
						'many' => q({0} t.),
						'name' => q(t.),
						'one' => q({0} t.),
						'other' => q({0} t.),
						'per' => q({0}/t.),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} t.),
						'many' => q({0} t.),
						'name' => q(t.),
						'one' => q({0} t.),
						'other' => q({0} t.),
						'per' => q({0}/t.),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'name' => q(bod),
					},
					# Core Unit Identifier
					'dot' => {
						'name' => q(bod),
					},
					# Long Unit Identifier
					'length-foot' => {
						'few' => q({0}′),
						'many' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'foot' => {
						'few' => q({0}′),
						'many' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'length-inch' => {
						'few' => q({0}″),
						'many' => q({0}″),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'inch' => {
						'few' => q({0}″),
						'many' => q({0}″),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'few' => q({0} mb),
						'many' => q({0} mb),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'few' => q({0} mb),
						'many' => q({0} mb),
						'one' => q({0} mb),
						'other' => q({0} mb),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(svetová strana),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(svetová strana),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(jednotka preťaženia),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(jednotka preťaženia),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(°),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'few' => q({0} ot.),
						'many' => q({0} ot.),
						'name' => q(ot.),
						'one' => q({0} ot.),
						'other' => q({0} ot.),
					},
					# Core Unit Identifier
					'revolution' => {
						'few' => q({0} ot.),
						'many' => q({0} ot.),
						'name' => q(ot.),
						'one' => q({0} ot.),
						'other' => q({0} ot.),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(akre),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(akre),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'few' => q({0} dun.),
						'many' => q({0} dun.),
						'name' => q(dun.),
						'one' => q({0} dun.),
						'other' => q({0} dun.),
					},
					# Core Unit Identifier
					'dunam' => {
						'few' => q({0} dun.),
						'many' => q({0} dun.),
						'name' => q(dun.),
						'one' => q({0} dun.),
						'other' => q({0} dun.),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(hektáre),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(hektáre),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'few' => q({0} pol.),
						'many' => q({0} pol.),
						'name' => q(pol.),
						'one' => q({0} pol.),
						'other' => q({0} pol.),
					},
					# Core Unit Identifier
					'item' => {
						'few' => q({0} pol.),
						'many' => q({0} pol.),
						'name' => q(pol.),
						'one' => q({0} pol.),
						'other' => q({0} pol.),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'few' => q({0} mg/dl),
						'many' => q({0} mg/dl),
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'few' => q({0} mg/dl),
						'many' => q({0} mg/dl),
						'name' => q(mg/dl),
						'one' => q({0} mg/dl),
						'other' => q({0} mg/dl),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'few' => q({0} mmol/l),
						'many' => q({0} mmol/l),
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'few' => q({0} mmol/l),
						'many' => q({0} mmol/l),
						'name' => q(mmol/l),
						'one' => q({0} mmol/l),
						'other' => q({0} mmol/l),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'few' => q({0} %),
						'many' => q({0} %),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Core Unit Identifier
					'percent' => {
						'few' => q({0} %),
						'many' => q({0} %),
						'one' => q({0} %),
						'other' => q({0} %),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'few' => q({0} ‰),
						'many' => q({0} ‰),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Core Unit Identifier
					'permille' => {
						'few' => q({0} ‰),
						'many' => q({0} ‰),
						'one' => q({0} ‰),
						'other' => q({0} ‰),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'few' => q({0} ‱),
						'many' => q({0} ‱),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Core Unit Identifier
					'permyriad' => {
						'few' => q({0} ‱),
						'many' => q({0} ‱),
						'one' => q({0} ‱),
						'other' => q({0} ‱),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'few' => q({0} l/100 km),
						'many' => q({0} l/100 km),
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'few' => q({0} l/100 km),
						'many' => q({0} l/100 km),
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'few' => q({0} l/km),
						'many' => q({0} l/km),
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'few' => q({0} l/km),
						'many' => q({0} l/km),
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'few' => q({0} mpg),
						'many' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'few' => q({0} mpg),
						'many' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'few' => q({0} mpg brit.),
						'many' => q({0} mpg brit.),
						'name' => q(mpg brit.),
						'one' => q({0} mpg brit.),
						'other' => q({0} mpg brit.),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'few' => q({0} mpg brit.),
						'many' => q({0} mpg brit.),
						'name' => q(mpg brit.),
						'one' => q({0} mpg brit.),
						'other' => q({0} mpg brit.),
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
						'few' => q({0} b),
						'many' => q({0} b),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					# Core Unit Identifier
					'bit' => {
						'few' => q({0} b),
						'many' => q({0} b),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'few' => q({0} B),
						'many' => q({0} B),
						'name' => q(bajt),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Core Unit Identifier
					'byte' => {
						'few' => q({0} B),
						'many' => q({0} B),
						'name' => q(bajt),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					# Long Unit Identifier
					'duration-century' => {
						'few' => q({0} stor.),
						'many' => q({0} stor.),
						'name' => q(stor.),
						'one' => q({0} stor.),
						'other' => q({0} stor.),
					},
					# Core Unit Identifier
					'century' => {
						'few' => q({0} stor.),
						'many' => q({0} stor.),
						'name' => q(stor.),
						'one' => q({0} stor.),
						'other' => q({0} stor.),
					},
					# Long Unit Identifier
					'duration-day' => {
						'few' => q({0} dni),
						'many' => q({0} dňa),
						'name' => q(dni),
						'one' => q({0} deň),
						'other' => q({0} dní),
						'per' => q({0}/deň),
					},
					# Core Unit Identifier
					'day' => {
						'few' => q({0} dni),
						'many' => q({0} dňa),
						'name' => q(dni),
						'one' => q({0} deň),
						'other' => q({0} dní),
						'per' => q({0}/deň),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'few' => q({0} desaťr.),
						'many' => q({0} desaťr.),
						'name' => q(desaťr.),
						'one' => q({0} desaťr.),
						'other' => q({0} desaťr.),
					},
					# Core Unit Identifier
					'decade' => {
						'few' => q({0} desaťr.),
						'many' => q({0} desaťr.),
						'name' => q(desaťr.),
						'one' => q({0} desaťr.),
						'other' => q({0} desaťr.),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(h),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(h),
					},
					# Long Unit Identifier
					'duration-month' => {
						'few' => q({0} mes.),
						'many' => q({0} mes.),
						'name' => q(mes.),
						'one' => q({0} mes.),
						'other' => q({0} mes.),
						'per' => q({0}/mes.),
					},
					# Core Unit Identifier
					'month' => {
						'few' => q({0} mes.),
						'many' => q({0} mes.),
						'name' => q(mes.),
						'one' => q({0} mes.),
						'other' => q({0} mes.),
						'per' => q({0}/mes.),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'few' => q({0} štvrťroky),
						'many' => q({0} štvrťroka),
						'name' => q(štvrťrok),
						'one' => q({0} štvrťrok),
						'other' => q({0} štvrťrokov),
						'per' => q({0}/štvrťrok),
					},
					# Core Unit Identifier
					'quarter' => {
						'few' => q({0} štvrťroky),
						'many' => q({0} štvrťroka),
						'name' => q(štvrťrok),
						'one' => q({0} štvrťrok),
						'other' => q({0} štvrťrokov),
						'per' => q({0}/štvrťrok),
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
					'duration-week' => {
						'few' => q({0} týž.),
						'many' => q({0} týž.),
						'name' => q(týž.),
						'one' => q({0} týž.),
						'other' => q({0} týž.),
						'per' => q({0}/týž.),
					},
					# Core Unit Identifier
					'week' => {
						'few' => q({0} týž.),
						'many' => q({0} týž.),
						'name' => q(týž.),
						'one' => q({0} týž.),
						'other' => q({0} týž.),
						'per' => q({0}/týž.),
					},
					# Long Unit Identifier
					'duration-year' => {
						'few' => q({0} r.),
						'many' => q({0} r.),
						'name' => q(r.),
						'one' => q({0} r.),
						'other' => q({0} r.),
						'per' => q({0}/r.),
					},
					# Core Unit Identifier
					'year' => {
						'few' => q({0} r.),
						'many' => q({0} r.),
						'name' => q(r.),
						'one' => q({0} r.),
						'other' => q({0} r.),
						'per' => q({0}/r.),
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
					'energy-british-thermal-unit' => {
						'few' => q({0} BTU),
						'many' => q({0} BTU),
						'name' => q(BTU),
						'one' => q({0} BTU),
						'other' => q({0} BTU),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'few' => q({0} BTU),
						'many' => q({0} BTU),
						'name' => q(BTU),
						'one' => q({0} BTU),
						'other' => q({0} BTU),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'few' => q({0} cal),
						'many' => q({0} cal),
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'few' => q({0} cal),
						'many' => q({0} cal),
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
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
						'few' => q({0} thm),
						'many' => q({0} thm),
						'name' => q(thm),
						'one' => q({0} thm),
						'other' => q({0} thm),
					},
					# Core Unit Identifier
					'therm-us' => {
						'few' => q({0} thm),
						'many' => q({0} thm),
						'name' => q(thm),
						'one' => q({0} thm),
						'other' => q({0} thm),
					},
					# Long Unit Identifier
					'graphics-dot' => {
						'few' => q({0} px),
						'many' => q({0} px),
						'name' => q(body),
						'one' => q({0} bod),
						'other' => q({0} px),
					},
					# Core Unit Identifier
					'dot' => {
						'few' => q({0} px),
						'many' => q({0} px),
						'name' => q(body),
						'one' => q({0} bod),
						'other' => q({0} px),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'few' => q({0} dpcm),
						'many' => q({0} dpcm),
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'few' => q({0} dpcm),
						'many' => q({0} dpcm),
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'few' => q({0} dpi),
						'many' => q({0} dpi),
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'few' => q({0} dpi),
						'many' => q({0} dpi),
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'few' => q({0} Mpx),
						'many' => q({0} Mpx),
						'name' => q(Mpx),
						'one' => q({0} Mpx),
						'other' => q({0} Mpx),
					},
					# Core Unit Identifier
					'megapixel' => {
						'few' => q({0} Mpx),
						'many' => q({0} Mpx),
						'name' => q(Mpx),
						'one' => q({0} Mpx),
						'other' => q({0} Mpx),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(fth),
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
					'length-mile-scandinavian' => {
						'few' => q({0} ŠM),
						'many' => q({0} ŠM),
						'name' => q(ŠM),
						'one' => q({0} ŠM),
						'other' => q({0} ŠM),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'few' => q({0} ŠM),
						'many' => q({0} ŠM),
						'name' => q(ŠM),
						'one' => q({0} ŠM),
						'other' => q({0} ŠM),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'few' => q({0} NM),
						'many' => q({0} NM),
						'name' => q(NM),
						'one' => q({0} NM),
						'other' => q({0} NM),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'few' => q({0} NM),
						'many' => q({0} NM),
						'name' => q(NM),
						'one' => q({0} NM),
						'other' => q({0} NM),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'few' => q({0} ct),
						'many' => q({0} ct),
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Core Unit Identifier
					'carat' => {
						'few' => q({0} ct),
						'many' => q({0} ct),
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'few' => q({0} grany),
						'many' => q({0} granu),
						'name' => q(gran),
						'one' => q({0} gran),
						'other' => q({0} granov),
					},
					# Core Unit Identifier
					'grain' => {
						'few' => q({0} grany),
						'many' => q({0} granu),
						'name' => q(gran),
						'one' => q({0} gran),
						'other' => q({0} granov),
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
					'mass-ton' => {
						'few' => q({0} to),
						'many' => q({0} to),
						'name' => q(to),
						'one' => q({0} to),
						'other' => q({0} to),
					},
					# Core Unit Identifier
					'ton' => {
						'few' => q({0} to),
						'many' => q({0} to),
						'name' => q(to),
						'one' => q({0} to),
						'other' => q({0} to),
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
					'temperature-celsius' => {
						'few' => q({0} °C),
						'many' => q({0} °C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Core Unit Identifier
					'celsius' => {
						'few' => q({0} °C),
						'many' => q({0} °C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'few' => q({0} °F),
						'many' => q({0} °F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'few' => q({0} °F),
						'many' => q({0} °F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					# Long Unit Identifier
					'temperature-generic' => {
						'few' => q({0} °),
						'many' => q({0} °),
						'one' => q({0} °),
						'other' => q({0} °),
					},
					# Core Unit Identifier
					'generic' => {
						'few' => q({0} °),
						'many' => q({0} °),
						'one' => q({0} °),
						'other' => q({0} °),
					},
					# Long Unit Identifier
					'times' => {
						'1' => q({0}{1}),
					},
					# Core Unit Identifier
					'times' => {
						'1' => q({0}{1}),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'few' => q({0} Nm),
						'many' => q({0} Nm),
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'few' => q({0} Nm),
						'many' => q({0} Nm),
						'name' => q(Nm),
						'one' => q({0} Nm),
						'other' => q({0} Nm),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'few' => q({0} cl),
						'many' => q({0} cl),
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Core Unit Identifier
					'centiliter' => {
						'few' => q({0} cl),
						'many' => q({0} cl),
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(c),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(c),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(mc),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(mc),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'few' => q({0} dl),
						'many' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Core Unit Identifier
					'deciliter' => {
						'few' => q({0} dl),
						'many' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'few' => q({0} dr),
						'many' => q({0} dr),
						'name' => q(dr),
						'one' => q({0} dr),
						'other' => q({0} dr),
					},
					# Core Unit Identifier
					'dram' => {
						'few' => q({0} dr),
						'many' => q({0} dr),
						'name' => q(dr),
						'one' => q({0} dr),
						'other' => q({0} dr),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'few' => q({0} kvapky),
						'many' => q({0} kvapky),
						'name' => q(kvapky),
						'one' => q({0} kvapka),
						'other' => q({0} kvapiek),
					},
					# Core Unit Identifier
					'drop' => {
						'few' => q({0} kvapky),
						'many' => q({0} kvapky),
						'name' => q(kvapky),
						'one' => q({0} kvapka),
						'other' => q({0} kvapiek),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'few' => q({0} fl oz),
						'many' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'few' => q({0} fl oz),
						'many' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'few' => q({0} brit. fl oz),
						'many' => q({0} brit. fl oz),
						'name' => q(brit. fl oz),
						'one' => q({0} brit. fl oz),
						'other' => q({0} brit. fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'few' => q({0} brit. fl oz),
						'many' => q({0} brit. fl oz),
						'name' => q(brit. fl oz),
						'one' => q({0} brit. fl oz),
						'other' => q({0} brit. fl oz),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'few' => q({0} gal),
						'many' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'few' => q({0} gal),
						'many' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'few' => q({0} brit. gal.),
						'many' => q({0} brit. gal.),
						'name' => q(brit. gal.),
						'one' => q({0} brit. gal.),
						'other' => q({0} brit. gal.),
						'per' => q({0}/brit. gal.),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'few' => q({0} brit. gal.),
						'many' => q({0} brit. gal.),
						'name' => q(brit. gal.),
						'one' => q({0} brit. gal.),
						'other' => q({0} brit. gal.),
						'per' => q({0}/brit. gal.),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'few' => q({0} hl),
						'many' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'few' => q({0} hl),
						'many' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'few' => q({0} odmerky),
						'many' => q({0} odmerky),
						'name' => q(odmerky),
						'one' => q({0} odmerka),
						'other' => q({0} odmeriek),
					},
					# Core Unit Identifier
					'jigger' => {
						'few' => q({0} odmerky),
						'many' => q({0} odmerky),
						'name' => q(odmerky),
						'one' => q({0} odmerka),
						'other' => q({0} odmeriek),
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
						'few' => q({0} Ml),
						'many' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Core Unit Identifier
					'megaliter' => {
						'few' => q({0} Ml),
						'many' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'few' => q({0} ml),
						'many' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Core Unit Identifier
					'milliliter' => {
						'few' => q({0} ml),
						'many' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'few' => q({0} štipky),
						'many' => q({0} štipky),
						'name' => q(štipky),
						'one' => q({0} štipka),
						'other' => q({0} štipiek),
					},
					# Core Unit Identifier
					'pinch' => {
						'few' => q({0} štipky),
						'many' => q({0} štipky),
						'name' => q(štipky),
						'one' => q({0} štipka),
						'other' => q({0} štipiek),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'few' => q({0} qt Imp),
						'many' => q({0} qt Imp),
						'one' => q({0} qt Imp),
						'other' => q({0} qt Imp),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'few' => q({0} qt Imp),
						'many' => q({0} qt Imp),
						'one' => q({0} qt Imp),
						'other' => q({0} qt Imp),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:áno|a|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:nie|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0} a {1}),
				2 => q({0} a {1}),
		} }
);

has 'number_symbols' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'latn' => {
			'decimal' => q(,),
			'exponential' => q(e),
			'group' => q( ),
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
					'few' => '0 tisíce',
					'many' => '0 tisíca',
					'one' => '0 tisíc',
					'other' => '0 tisíc',
				},
				'10000' => {
					'few' => '00 tisíc',
					'many' => '00 tisíca',
					'one' => '00 tisíc',
					'other' => '00 tisíc',
				},
				'100000' => {
					'few' => '000 tisíc',
					'many' => '000 tisíca',
					'one' => '000 tisíc',
					'other' => '000 tisíc',
				},
				'1000000' => {
					'few' => '0 milióny',
					'many' => '0 milióna',
					'one' => '0 milión',
					'other' => '0 miliónov',
				},
				'10000000' => {
					'few' => '00 miliónov',
					'many' => '00 milióna',
					'one' => '00 miliónov',
					'other' => '00 miliónov',
				},
				'100000000' => {
					'few' => '000 miliónov',
					'many' => '000 milióna',
					'one' => '000 miliónov',
					'other' => '000 miliónov',
				},
				'1000000000' => {
					'few' => '0 miliardy',
					'many' => '0 miliardy',
					'one' => '0 miliarda',
					'other' => '0 miliárd',
				},
				'10000000000' => {
					'few' => '00 miliárd',
					'many' => '00 miliardy',
					'one' => '00 miliárd',
					'other' => '00 miliárd',
				},
				'100000000000' => {
					'few' => '000 miliárd',
					'many' => '000 miliardy',
					'one' => '000 miliárd',
					'other' => '000 miliárd',
				},
				'1000000000000' => {
					'few' => '0 bilióny',
					'many' => '0 bilióna',
					'one' => '0 bilión',
					'other' => '0 biliónov',
				},
				'10000000000000' => {
					'few' => '00 biliónov',
					'many' => '00 bilióna',
					'one' => '00 biliónov',
					'other' => '00 biliónov',
				},
				'100000000000000' => {
					'few' => '000 biliónov',
					'many' => '000 bilióna',
					'one' => '000 biliónov',
					'other' => '000 biliónov',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 tis'.'',
					'other' => '0 tis'.'',
				},
				'10000' => {
					'one' => '00 tis'.'',
					'other' => '00 tis'.'',
				},
				'100000' => {
					'one' => '000 tis'.'',
					'other' => '000 tis'.'',
				},
				'1000000' => {
					'one' => '0 mil'.'',
					'other' => '0 mil'.'',
				},
				'10000000' => {
					'one' => '00 mil'.'',
					'other' => '00 mil'.'',
				},
				'100000000' => {
					'one' => '000 mil'.'',
					'other' => '000 mil'.'',
				},
				'1000000000' => {
					'one' => '0 mld'.'',
					'other' => '0 mld'.'',
				},
				'10000000000' => {
					'one' => '00 mld'.'',
					'other' => '00 mld'.'',
				},
				'100000000000' => {
					'one' => '000 mld'.'',
					'other' => '000 mld'.'',
				},
				'1000000000000' => {
					'one' => '0 bil'.'',
					'other' => '0 bil'.'',
				},
				'10000000000000' => {
					'one' => '00 bil'.'',
					'other' => '00 bil'.'',
				},
				'100000000000000' => {
					'one' => '000 bil'.'',
					'other' => '000 bil'.'',
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
				'currency' => q(andorrská peseta),
				'few' => q(andorrské pesety),
				'many' => q(andorrskej pesety),
				'one' => q(andorrská peseta),
				'other' => q(andorrských pesiet),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(SAE dirham),
				'few' => q(SAE dirhamy),
				'many' => q(SAE dirhamu),
				'one' => q(SAE dirham),
				'other' => q(SAE dirhamov),
			},
		},
		'AFA' => {
			display_name => {
				'currency' => q(afganský afgání \(1927 – 2002\)),
				'few' => q(afganské afgání \(1927 – 2002\)),
				'many' => q(afganského afgání \(1927 – 2002\)),
				'one' => q(afganský afgání \(1927 – 2002\)),
				'other' => q(afganských afgání \(1927 – 2002\)),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(afganský afgání),
				'few' => q(afganské afgání),
				'many' => q(afganského afgání),
				'one' => q(afganský afgání),
				'other' => q(afganských afgání),
			},
		},
		'ALK' => {
			display_name => {
				'currency' => q(albánsky lek \(1946 – 1965\)),
				'few' => q(albánske leky \(1946 – 1965\)),
				'many' => q(albánskeho leku \(1946 – 1965\)),
				'one' => q(albánsky lek \(1946 – 1965\)),
				'other' => q(albánskych lekov \(1946 – 1965\)),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(albánsky lek),
				'few' => q(albánske leky),
				'many' => q(albánskeho leku),
				'one' => q(albánsky lek),
				'other' => q(albánskych lekov),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(arménsky dram),
				'few' => q(arménske dramy),
				'many' => q(arménskeho dramu),
				'one' => q(arménsky dram),
				'other' => q(arménskych dramov),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(antilský gulden),
				'few' => q(antilské guldeny),
				'many' => q(antilského guldena),
				'one' => q(antilský gulden),
				'other' => q(antilských guldenov),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(angolská kwanza),
				'few' => q(angolské kwanzy),
				'many' => q(angolskej kwanzy),
				'one' => q(angolská kwanza),
				'other' => q(angolských kwánz),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(angolská kwanza \(1977 – 1990\)),
				'few' => q(angolské kwanzy \(1977 – 1990\)),
				'many' => q(angolskej kwanzy \(1977 – 1990\)),
				'one' => q(angolská kwanza \(1977 – 1990\)),
				'other' => q(angolských kwánz \(1977 – 1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(angolská nová kwanza \(1990 – 2000\)),
				'few' => q(angolské nové kwanzy \(1990 – 2000\)),
				'many' => q(angolskej novej kwanzy \(1990 – 2000\)),
				'one' => q(angolská nová kwanza \(1990 – 2000\)),
				'other' => q(angolských nových kwánz \(1990 – 2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(angolská upravená kwanza \(1995 – 1999\)),
				'few' => q(angolské upravené kwanzy \(1995 – 1999\)),
				'many' => q(angolskej upravenej kwanzy \(1995 – 1999\)),
				'one' => q(angolská upravená kwanza \(1995 – 1999\)),
				'other' => q(angolských upravených kwánz \(1995 – 1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(argentínsky austral),
				'few' => q(argentínske australy),
				'many' => q(argentínskeho australu),
				'one' => q(argentínsky austral),
				'other' => q(argentínskych australov),
			},
		},
		'ARL' => {
			display_name => {
				'currency' => q(argentínske peso ley \(1970 – 1983\)),
				'few' => q(argentínske pesos ley \(1970 – 1983\)),
				'many' => q(argentínskeho pesa ley \(1970 – 1983\)),
				'one' => q(argentínske peso ley \(1970 – 1983\)),
				'other' => q(argentínskych pesos ley \(1970 – 1983\)),
			},
		},
		'ARM' => {
			display_name => {
				'currency' => q(argentínske peso \(1881 – 1970\)),
				'few' => q(argentínske pesos \(1881 – 1970\)),
				'many' => q(argentínskeho pesa \(1881 – 1970\)),
				'one' => q(argentínske peso \(1881 – 1970\)),
				'other' => q(argentínskych pesos \(1881 – 1970\)),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(argentínske peso \(1983 – 1985\)),
				'few' => q(argentínske pesos \(1983 – 1985\)),
				'many' => q(argentínskeho pesa \(1983 – 1985\)),
				'one' => q(argentínske peso \(1983 – 1985\)),
				'other' => q(argentínskych pesos \(1983 – 1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(argentínske peso),
				'few' => q(argentínske pesos),
				'many' => q(argentínskeho pesa),
				'one' => q(argentínske peso),
				'other' => q(argentínskych pesos),
			},
		},
		'ATS' => {
			display_name => {
				'currency' => q(rakúsky šiling),
				'few' => q(rakúske šilingy),
				'many' => q(rakúskeho šilingu),
				'one' => q(rakúsky šiling),
				'other' => q(rakúskych šilingov),
			},
		},
		'AUD' => {
			symbol => 'AUD',
			display_name => {
				'currency' => q(austrálsky dolár),
				'few' => q(austrálske doláre),
				'many' => q(austrálskeho dolára),
				'one' => q(austrálsky dolár),
				'other' => q(austrálskych dolárov),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(arubský gulden),
				'few' => q(arubské guldeny),
				'many' => q(arubského guldena),
				'one' => q(arubský gulden),
				'other' => q(arubských guldenov),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(azerbajdžanský manat \(1993–2006\)),
				'few' => q(azerbajdžanské manaty \(1993–2006\)),
				'many' => q(azerbajdžanského manatu \(1993–2006\)),
				'one' => q(azerbajdžanský manat \(1993–2006\)),
				'other' => q(azerbajdžanských manatov \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(azerbajdžanský manat),
				'few' => q(azerbajdžanské manaty),
				'many' => q(azerbajdžanského manatu),
				'one' => q(azerbajdžanský manat),
				'other' => q(azerbajdžanských manatov),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(bosniansko-hercegovinský dinár \(1992 – 1994\)),
				'few' => q(bosniansko-hercegovinské dináre \(1992 – 1994\)),
				'many' => q(bosniansko-hercegovinského dinára \(1992 – 1994\)),
				'one' => q(bosniansko-hercegovinský dinár \(1992 – 1994\)),
				'other' => q(bosniansko-hercegovinských dinárov \(1992 – 1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(bosniansko-hercegovinská konvertibilná marka),
				'few' => q(bosniansko-hercegovinské konvertibilné marky),
				'many' => q(bosniansko-hercegovinskej konvertibilnej marky),
				'one' => q(bosniansko-hercegovinská konvertibilná marka),
				'other' => q(bosniansko-hercegovinských konvertibilných mariek),
			},
		},
		'BAN' => {
			display_name => {
				'currency' => q(bosniansko-hercegovinský nový dinár \(1994 – 1997\)),
				'few' => q(bosniansko-hercegovinské nové dináre \(1994 – 1997\)),
				'many' => q(bosniansko-hercegovinského nového dinára \(1994 – 1997\)),
				'one' => q(bosniansko-hercegovinský nový dinár \(1994 – 1997\)),
				'other' => q(bosniansko-hercegovinské nové dináre \(1994 – 1997\)),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(barbadoský dolár),
				'few' => q(barbadoské doláre),
				'many' => q(barbadoského dolára),
				'one' => q(barbadoský dolár),
				'other' => q(barbadoských dolárov),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(bangladéšska taka),
				'few' => q(bangladéšske taky),
				'many' => q(bangladéšskej taky),
				'one' => q(bangladéšska taka),
				'other' => q(bangladéšskych ták),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(belgický frank \(konvertibilný\)),
				'few' => q(belgické franky \(konvertibilné\)),
				'many' => q(belgického franku \(konvertibilného\)),
				'one' => q(belgický frank \(konvertibilný\)),
				'other' => q(belgických frankov \(konvertibilných\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(belgický frank),
				'few' => q(belgické franky),
				'many' => q(belgického franku),
				'one' => q(belgický frank),
				'other' => q(belgických frankov),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(belgický frank \(finančný\)),
				'few' => q(belgické franky \(finančné\)),
				'many' => q(belgického franku \(finančného\)),
				'one' => q(belgický frank \(finančný\)),
				'other' => q(belgických frankov \(finančných\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(bulharský tvrdý lev),
				'few' => q(bulharské tvrdé leva),
				'many' => q(bulharského tvrdého leva),
				'one' => q(bulharský tvrdý lev),
				'other' => q(bulharských tvrdých leva),
			},
		},
		'BGM' => {
			display_name => {
				'currency' => q(bulharský socialistický lev),
				'few' => q(bulharské socialistické leva),
				'many' => q(bulharského socialistického leva),
				'one' => q(bulharský socialistický lev),
				'other' => q(bulharských socialistických leva),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(bulharský lev),
				'few' => q(bulharské leva),
				'many' => q(bulharského leva),
				'one' => q(bulharský lev),
				'other' => q(bulharských leva),
			},
		},
		'BGO' => {
			display_name => {
				'currency' => q(bulharský lev \(1879 – 1952\)),
				'few' => q(bulharské leva \(1879 – 1952\)),
				'many' => q(bulharského leva \(1879 – 1952\)),
				'one' => q(bulharský lev \(1879 – 1952\)),
				'other' => q(bulharských leva \(1879 – 1952\)),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(bahrajnský dinár),
				'few' => q(bahrajnské dináre),
				'many' => q(bahrajnského dinára),
				'one' => q(bahrajnský dinár),
				'other' => q(bahrajnských dinárov),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(burundský frank),
				'few' => q(burundské franky),
				'many' => q(burundského franku),
				'one' => q(burundský frank),
				'other' => q(burundských frankov),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(bermudský dolár),
				'few' => q(bermudské doláre),
				'many' => q(bermudského dolára),
				'one' => q(bermudský dolár),
				'other' => q(bermudských dolárov),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(brunejský dolár),
				'few' => q(brunejské doláre),
				'many' => q(brunejského dolára),
				'one' => q(brunejský dolár),
				'other' => q(brunejských dolárov),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(bolívijské boliviano),
				'few' => q(bolívijské boliviana),
				'many' => q(bolívijského boliviana),
				'one' => q(bolívijské boliviano),
				'other' => q(bolívijských bolivian),
			},
		},
		'BOL' => {
			display_name => {
				'currency' => q(bolívijské boliviano \(1863 – 1963\)),
				'few' => q(bolívijské boliviana \(1863 – 1963\)),
				'many' => q(bolívijského boliviana \(1863 – 1963\)),
				'one' => q(bolívijské boliviano \(1863 – 1963\)),
				'other' => q(bolívijských bolivian \(1863 – 1963\)),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(bolívijské peso),
				'few' => q(bolívijské pesos),
				'many' => q(bolívijského pesa),
				'one' => q(bolívijské peso),
				'other' => q(bolívijských pesos),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(bolívijské MVDOL),
				'few' => q(bolívijské mvdoly),
				'many' => q(bolívijského mvdolu),
				'one' => q(bolívijský mvdol),
				'other' => q(bolívijských mvdolov),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(brazílske nové cruzeiro \(1967 – 1986\)),
				'few' => q(brazílske nové cruzeirá \(1967 – 1986\)),
				'many' => q(brazílskeho nového cruzeira \(1967 – 1986\)),
				'one' => q(brazílske nové cruzeiro \(1967 – 1986\)),
				'other' => q(brazílskych nových cruzeir \(1967 – 1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(brazílske cruzado \(1986 – 1989\)),
				'few' => q(brazílske cruzadá \(1986 – 1989\)),
				'many' => q(brazílskeho cruzada \(1986 – 1989\)),
				'one' => q(brazílske cruzado \(1986 – 1989\)),
				'other' => q(brazílskych cruzad \(1986 – 1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(brazílske cruzeiro \(1990 – 1993\)),
				'few' => q(brazílske cruzeirá \(1990 – 1993\)),
				'many' => q(brazílskeho cruzeira \(1990 – 1993\)),
				'one' => q(brazílske cruzeiro \(1990 – 1993\)),
				'other' => q(brazílskych cruzeir \(1990 – 1993\)),
			},
		},
		'BRL' => {
			symbol => 'BRL',
			display_name => {
				'currency' => q(brazílsky real),
				'few' => q(brazílske realy),
				'many' => q(brazílskeho realu),
				'one' => q(brazílsky real),
				'other' => q(brazílskych realov),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(brazílske nové cruzado \(1989 – 1990\)),
				'few' => q(brazílske nové cruzadá \(1989 – 1990\)),
				'many' => q(brazílskeho nového cruzada \(1989 – 1990\)),
				'one' => q(brazílske nové cruzado \(1989 – 1990\)),
				'other' => q(brazílskych nových cruzad \(1989 – 1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Brazílske cruzeiro),
				'few' => q(brazílske cruzeirá \(1993 – 1994\)),
				'many' => q(brazílskeho cruzeira \(1993 – 1994\)),
				'one' => q(brazílske cruzeiro \(1993 – 1994\)),
				'other' => q(brazílskych cruzeir \(1993 – 1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(brazílske cruzeiro \(1942 – 1967\)),
				'few' => q(brazílske cruzeirá \(1942 – 1967\)),
				'many' => q(brazílskeho cruzeira \(1942 – 1967\)),
				'one' => q(brazílske cruzeiro \(1942 – 1967\)),
				'other' => q(brazílskych cruzeir \(1942 – 1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(bahamský dolár),
				'few' => q(bahamské doláre),
				'many' => q(bahamského dolára),
				'one' => q(bahamský dolár),
				'other' => q(bahamských dolárov),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(bhutánsky ngultrum),
				'few' => q(bhutánske ngultrumy),
				'many' => q(bhutánskeho ngultrumu),
				'one' => q(bhutánsky ngultrum),
				'other' => q(bhutánskych ngultrumov),
			},
		},
		'BUK' => {
			display_name => {
				'currency' => q(barmský kyat),
				'few' => q(barmské kyaty),
				'many' => q(barmského kyatu),
				'one' => q(barmský kyat),
				'other' => q(barmských kyatov),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(botswanská pula),
				'few' => q(botswanské puly),
				'many' => q(botswanskej puly),
				'one' => q(botswanská pula),
				'other' => q(botswanských púl),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(bieloruský rubeľ \(1994 – 1999\)),
				'few' => q(bieloruské ruble \(1994 – 1999\)),
				'many' => q(bieloruského rubľa \(1994 – 1999\)),
				'one' => q(bieloruský rubeľ \(1994 – 1999\)),
				'other' => q(bieloruských rubľov \(1994 – 1999\)),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(bieloruský rubeľ),
				'few' => q(bieloruské ruble),
				'many' => q(bieloruského rubľa),
				'one' => q(bieloruský rubeľ),
				'other' => q(bieloruských rubľov),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(bieloruský rubeľ \(2000–2016\)),
				'few' => q(bieloruské ruble \(2000–2016\)),
				'many' => q(bieloruského rubľa \(2000–2016\)),
				'one' => q(bieloruský rubeľ \(2000–2016\)),
				'other' => q(bieloruských rubľov \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(belizský dolár),
				'few' => q(belizské doláre),
				'many' => q(belizského dolára),
				'one' => q(belizský dolár),
				'other' => q(belizských dolárov),
			},
		},
		'CAD' => {
			symbol => 'CAD',
			display_name => {
				'currency' => q(kanadský dolár),
				'few' => q(kanadské doláre),
				'many' => q(kanadského dolára),
				'one' => q(kanadský dolár),
				'other' => q(kanadských dolárov),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(konžský frank),
				'few' => q(konžské franky),
				'many' => q(konžského franku),
				'one' => q(konžský frank),
				'other' => q(konžských frankov),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(švajčiarske WIR euro),
				'few' => q(švajčiarske WIR eurá),
				'many' => q(švajčiarskeho WIR eura),
				'one' => q(švajčiarske WIR euro),
				'other' => q(švajčiarskych WIR eur),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(švajčiarsky frank),
				'few' => q(švajčiarske franky),
				'many' => q(švajčiarskeho franku),
				'one' => q(švajčiarsky frank),
				'other' => q(švajčiarskych frankov),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(švajčiarsky WIR frank),
				'few' => q(švajčiarske WIR franky),
				'many' => q(švajčiarskeho WIR franku),
				'one' => q(švajčiarsky WIR frank),
				'other' => q(švajčiarskych WIR frankov),
			},
		},
		'CLE' => {
			display_name => {
				'currency' => q(čilské escudo),
				'few' => q(čilské escudá),
				'many' => q(čilského escuda),
				'one' => q(čilské escudo),
				'other' => q(čilských escúd),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(čilská účtovná jednotka \(UF\)),
				'few' => q(čilské účtovné jednotky \(UF\)),
				'many' => q(čilskej účtovnej jednotky \(UF\)),
				'one' => q(čilská účtovná jednotka \(UF\)),
				'other' => q(čilských účtovných jednotiek \(UF\)),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(čilské peso),
				'few' => q(čilské pesos),
				'many' => q(čilského pesa),
				'one' => q(čilské peso),
				'other' => q(čilských pesos),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(čínsky jüan \(pobrežný\)),
				'few' => q(čínske jüany \(pobrežné\)),
				'many' => q(čínskeho jüana \(pobrežného\)),
				'one' => q(čínsky jüan \(pobrežný\)),
				'other' => q(čínskych jüanov \(pobrežných\)),
			},
		},
		'CNX' => {
			display_name => {
				'currency' => q(čínsky dolár ČĽB),
				'few' => q(čínske doláre ČĽB),
				'many' => q(čínskeho dolára ČĽB),
				'one' => q(čínsky dolár ČĽB),
				'other' => q(čínskych dolárov ČĽB),
			},
		},
		'CNY' => {
			symbol => 'CNY',
			display_name => {
				'currency' => q(čínsky jüan),
				'few' => q(čínske jüany),
				'many' => q(čínskeho jüana),
				'one' => q(čínsky jüan),
				'other' => q(čínskych jüanov),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(kolumbijské peso),
				'few' => q(kolumbijské pesos),
				'many' => q(kolumbijského pesa),
				'one' => q(kolumbijské peso),
				'other' => q(kolumbijských pesos),
			},
		},
		'COU' => {
			display_name => {
				'currency' => q(kolumbijská jednotka reálnej hodnoty),
				'few' => q(kolumbijské jednotky reálnej hodnoty),
				'many' => q(kolumbijskej jednotky reálnej hodnoty),
				'one' => q(kolumbijská jednotka reálnej hodnoty),
				'other' => q(kolumbijských jednotiek reálnej hodnoty),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(kostarický colón),
				'few' => q(kostarické colóny),
				'many' => q(kostarického colóna),
				'one' => q(kostarický colón),
				'other' => q(kostarických colónov),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(srbský dinár \(2002 – 2006\)),
				'few' => q(srbské dináre \(2002 – 2006\)),
				'many' => q(srbského dinára \(2002 – 2006\)),
				'one' => q(srbský dinár \(2002 – 2006\)),
				'other' => q(srbských dinárov \(2002 – 2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(československá koruna),
				'few' => q(československé koruny),
				'many' => q(československej koruny),
				'one' => q(československá koruna),
				'other' => q(československých korún),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(kubánske konvertibilné peso),
				'few' => q(kubánske konvertibilné pesos),
				'many' => q(kubánskeho konvertibilného pesa),
				'one' => q(kubánske konvertibilné peso),
				'other' => q(kubánskych konvertibilných pesos),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(kubánske peso),
				'few' => q(kubánske pesos),
				'many' => q(kubánskeho pesa),
				'one' => q(kubánske peso),
				'other' => q(kubánskych pesos),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(kapverdské escudo),
				'few' => q(kapverdské escudá),
				'many' => q(kapverdského escuda),
				'one' => q(kapverdské escudo),
				'other' => q(kapverdských escúd),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(cyperská libra),
				'few' => q(cyperské libry),
				'many' => q(cyperskej libry),
				'one' => q(cyperská libra),
				'other' => q(cyperských libier),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(česká koruna),
				'few' => q(české koruny),
				'many' => q(českej koruny),
				'one' => q(česká koruna),
				'other' => q(českých korún),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(východonemecká marka),
				'few' => q(východonemecké marky),
				'many' => q(východonemeckej marky),
				'one' => q(východonemecká marka),
				'other' => q(východonemeckých mariek),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(nemecká marka),
				'few' => q(nemecké marky),
				'many' => q(nemeckej marky),
				'one' => q(nemecká marka),
				'other' => q(nemeckých mariek),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(džibutský frank),
				'few' => q(džibutské franky),
				'many' => q(džibutského franku),
				'one' => q(džibutský frank),
				'other' => q(džibutských frankov),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(dánska koruna),
				'few' => q(dánske koruny),
				'many' => q(dánskej koruny),
				'one' => q(dánska koruna),
				'other' => q(dánskych korún),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(dominikánske peso),
				'few' => q(dominikánske pesos),
				'many' => q(dominikánskeho pesa),
				'one' => q(dominikánske peso),
				'other' => q(dominikánske pesos),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(alžírsky dinár),
				'few' => q(alžírske dináre),
				'many' => q(alžírskeho dinára),
				'one' => q(alžírsky dinár),
				'other' => q(alžírskych dinárov),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(ekvádorský sucre),
				'few' => q(ekvádorské sucre),
				'many' => q(ekvádorského sucre),
				'one' => q(ekvádorský sucre),
				'other' => q(ekvádorských sucre),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(ekvádorská jednotka konštantnej hodnoty),
				'few' => q(ekvádorské jednotky konštantnej hodnoty),
				'many' => q(ekvádorskej jednotky konštantnej hodnoty),
				'one' => q(ekvádorská jednotka konštantnej hodnoty),
				'other' => q(ekvádorských jednotiek konštantnej hodnoty),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(estónska koruna),
				'few' => q(estónske koruny),
				'many' => q(estónskej koruny),
				'one' => q(estónska koruna),
				'other' => q(estónskych korún),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(egyptská libra),
				'few' => q(egyptské libry),
				'many' => q(egyptskej libry),
				'one' => q(egyptská libra),
				'other' => q(egyptských libier),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(eritrejská nakfa),
				'few' => q(eritrejské nakfy),
				'many' => q(eritrejskej nakfy),
				'one' => q(eritrejská nakfa),
				'other' => q(eritrejských nakief),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(španielska peseta \(účet A\)),
				'few' => q(španielske pesety \(účet A\)),
				'many' => q(španielskej pesety \(účet A\)),
				'one' => q(španielska peseta \(účet A\)),
				'other' => q(španielskych pesiet \(účet A\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(španielska peseta \(konvertibilný účet\)),
				'few' => q(španielske pesety \(konvertibilný účet\)),
				'many' => q(španielskej pesety \(konvertibilný účet\)),
				'one' => q(španielska peseta \(konvertibilný účet\)),
				'other' => q(španielskych pesiet \(konvertibilný účet\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(španielska peseta),
				'few' => q(španielske pesety),
				'many' => q(španielskej pesety),
				'one' => q(španielska peseta),
				'other' => q(španielskych pesiet),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(etiópsky birr),
				'few' => q(etiópske birry),
				'many' => q(etiópskeho birru),
				'one' => q(etiópsky birr),
				'other' => q(etiópskych birrov),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(euro),
				'few' => q(eurá),
				'many' => q(eura),
				'one' => q(euro),
				'other' => q(eur),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(fínska marka),
				'few' => q(fínske marky),
				'many' => q(fínskej marky),
				'one' => q(fínska marka),
				'other' => q(fínskych mariek),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(fidžijský dolár),
				'few' => q(fidžijské doláre),
				'many' => q(fidžijského dolára),
				'one' => q(fidžijský dolár),
				'other' => q(fidžijských dolárov),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(falklandská libra),
				'few' => q(falklandské libry),
				'many' => q(falklandskej libry),
				'one' => q(falklandská libra),
				'other' => q(falklandských libier),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(francúzsky frank),
				'few' => q(francúzske franky),
				'many' => q(francúzskeho franku),
				'one' => q(francúzsky frank),
				'other' => q(francúzskych frankov),
			},
		},
		'GBP' => {
			symbol => 'GBP',
			display_name => {
				'currency' => q(britská libra),
				'few' => q(britské libry),
				'many' => q(britskej libry),
				'one' => q(britská libra),
				'other' => q(britských libier),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(gruzínske kupónové lari),
				'few' => q(gruzínske kupónové lari),
				'many' => q(gruzínskeho kupónového lari),
				'one' => q(gruzínske kupónové lari),
				'other' => q(gruzínskych kupónových lari),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(gruzínske lari),
				'few' => q(gruzínske lari),
				'many' => q(gruzínskeho lari),
				'one' => q(gruzínske lari),
				'other' => q(gruzínskych lari),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(ghanské cedi \(1979 – 2007\)),
				'few' => q(ghanské cedi \(1979 – 2007\)),
				'many' => q(ghanského cedi \(1979 – 2007\)),
				'one' => q(ghanské cedi \(1979 – 2007\)),
				'other' => q(ghanských cedi \(1979 – 2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(ghanské cedi),
				'few' => q(ghanské cedi),
				'many' => q(ghanského cedi),
				'one' => q(ghanské cedi),
				'other' => q(ghanských cedi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(gibraltárska libra),
				'few' => q(gibraltárske libry),
				'many' => q(gibraltárskej libry),
				'one' => q(gibraltárska libra),
				'other' => q(gibraltárskych libier),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(gambijské dalasi),
				'few' => q(gambijské dalasi),
				'many' => q(gambijského dalasi),
				'one' => q(gambijské dalasi),
				'other' => q(gambijských dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(guinejský frank),
				'few' => q(guinejské franky),
				'many' => q(guinejského franku),
				'one' => q(guinejský frank),
				'other' => q(guinejských frankov),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(guinejské syli),
				'few' => q(guinejské syli),
				'many' => q(guinejského syli),
				'one' => q(guinejské syli),
				'other' => q(guinejských syli),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(rovníkovoguinejský ekwele),
				'few' => q(rovníkovoguinejské ekwele),
				'many' => q(rovníkovoguinejského ekwele),
				'one' => q(rovníkovoguinejský ekwele),
				'other' => q(rovníkovoguinejských ekwele),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(grécka drachma),
				'few' => q(grécke drachmy),
				'many' => q(gréckej drachmy),
				'one' => q(grécka drachma),
				'other' => q(gréckych drachiem),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(guatemalský quetzal),
				'few' => q(guatemalské quetzaly),
				'many' => q(guatemalského quetzala),
				'one' => q(guatemalský quetzal),
				'other' => q(guatemalských quetzalov),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(portugalsko-guinejské escudo),
				'few' => q(portugalsko-guinejské escudá),
				'many' => q(portugalsko-guinejského escuda),
				'one' => q(portugalsko-guinejské escudo),
				'other' => q(portugalsko-guinejských escúd),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(guinejsko-bissauské peso),
				'few' => q(guinejsko-bissauské pesos),
				'many' => q(guinejsko-bissauského pesa),
				'one' => q(guinejsko-bissauské peso),
				'other' => q(guinejsko-bissauských pesos),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(guyanský dolár),
				'few' => q(guyanské doláre),
				'many' => q(guyanského dolára),
				'one' => q(guyanský dolár),
				'other' => q(guyanských dolárov),
			},
		},
		'HKD' => {
			symbol => 'HKD',
			display_name => {
				'currency' => q(hongkonský dolár),
				'few' => q(hongkonské doláre),
				'many' => q(hongkonského dolára),
				'one' => q(hongkonský dolár),
				'other' => q(hongkonských dolárov),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(honduraská lempira),
				'few' => q(honduraské lempiry),
				'many' => q(honduraskej lempiry),
				'one' => q(honduraská lempira),
				'other' => q(honduraských lempír),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(chorvátsky dinár),
				'few' => q(chorvátske dináre),
				'many' => q(chorvátskeho dinára),
				'one' => q(chorvátsky dinár),
				'other' => q(chorvátskych dinárov),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(chorvátska kuna),
				'few' => q(chorvátske kuny),
				'many' => q(chorvátskej kuny),
				'one' => q(chorvátska kuna),
				'other' => q(chorvátskych kún),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(haitské gourde),
				'few' => q(haitské gourde),
				'many' => q(haitského gourde),
				'one' => q(haitské gourde),
				'other' => q(haitských gourde),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(maďarský forint),
				'few' => q(maďarské forinty),
				'many' => q(maďarského forinta),
				'one' => q(maďarský forint),
				'other' => q(maďarských forintov),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(indonézska rupia),
				'few' => q(indonézske rupie),
				'many' => q(indonézskej rupie),
				'one' => q(indonézska rupia),
				'other' => q(indonézskych rupií),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(írska libra),
				'few' => q(írske libry),
				'many' => q(írskej libry),
				'one' => q(írska libra),
				'other' => q(írskych libier),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(izraelská libra),
				'few' => q(izraelské libry),
				'many' => q(izraelskej libry),
				'one' => q(izraelská libra),
				'other' => q(izraelských libier),
			},
		},
		'ILR' => {
			display_name => {
				'currency' => q(izraelský šekel \(1980 – 1985\)),
				'few' => q(izraelské šekely \(1980 – 1985\)),
				'many' => q(izraelského šekela \(1980 – 1985\)),
				'one' => q(izraelský šekel \(1980 – 1985\)),
				'other' => q(izraelských šekelov \(1980 – 1985\)),
			},
		},
		'ILS' => {
			symbol => 'NIS',
			display_name => {
				'currency' => q(izraelský šekel),
				'few' => q(izraelské šekely),
				'many' => q(izraelského šekela),
				'one' => q(izraelský šekel),
				'other' => q(izraelských šekelov),
			},
		},
		'INR' => {
			symbol => 'INR',
			display_name => {
				'currency' => q(indická rupia),
				'few' => q(indické rupie),
				'many' => q(indickej rupie),
				'one' => q(indická rupia),
				'other' => q(indických rupií),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(iracký dinár),
				'few' => q(iracké dináre),
				'many' => q(irackého dinára),
				'one' => q(iracký dinár),
				'other' => q(irackých dinárov),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(iránsky rial),
				'few' => q(iránske rialy),
				'many' => q(iránskeho rialu),
				'one' => q(iránsky rial),
				'other' => q(iránskych rialov),
			},
		},
		'ISJ' => {
			display_name => {
				'currency' => q(islandská koruna \(1918 – 1981\)),
				'few' => q(islandské koruny \(1918 – 1981\)),
				'many' => q(islandskej koruny \(1918 – 1981\)),
				'one' => q(islandská koruna \(1918 – 1981\)),
				'other' => q(islandských korún \(1918 – 1981\)),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(islandská koruna),
				'few' => q(islandské koruny),
				'many' => q(islandskej koruny),
				'one' => q(islandská koruna),
				'other' => q(islandských korún),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(talianska líra),
				'few' => q(talianske líry),
				'many' => q(talianskej líry),
				'one' => q(talianska líra),
				'other' => q(talianskych lír),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(jamajský dolár),
				'few' => q(jamajské doláre),
				'many' => q(jamajského dolára),
				'one' => q(jamajský dolár),
				'other' => q(jamajských dolárov),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(jordánsky dinár),
				'few' => q(jordánske dináre),
				'many' => q(jordánskeho dinára),
				'one' => q(jordánsky dinár),
				'other' => q(jordánskych dinárov),
			},
		},
		'JPY' => {
			symbol => 'JPY',
			display_name => {
				'currency' => q(japonský jen),
				'few' => q(japonské jeny),
				'many' => q(japonského jenu),
				'one' => q(japonský jen),
				'other' => q(japonských jenov),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(kenský šiling),
				'few' => q(kenské šilingy),
				'many' => q(kenského šilingu),
				'one' => q(kenský šiling),
				'other' => q(kenských šilingov),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(kirgizský som),
				'few' => q(kirgizské somy),
				'many' => q(kirgizského somu),
				'one' => q(kirgizský som),
				'other' => q(kirgizských somov),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(kambodžský riel),
				'few' => q(kambodžské riely),
				'many' => q(kambodžského rielu),
				'one' => q(kambodžský riel),
				'other' => q(kambodžských rielov),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(komorský frank),
				'few' => q(komorské franky),
				'many' => q(komorského franku),
				'one' => q(komorský frank),
				'other' => q(komorských frankov),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(severokórejský won),
				'few' => q(severokórejské wony),
				'many' => q(severokórejskeho wonu),
				'one' => q(severokórejský won),
				'other' => q(severokórejských wonov),
			},
		},
		'KRH' => {
			display_name => {
				'currency' => q(juhokórejský hwan \(1953 – 1962\)),
				'few' => q(juhokórejské hwany \(1953 – 1962\)),
				'many' => q(juhokórejského hwanu \(1953 – 1962\)),
				'one' => q(juhokórejský hwan \(1953 – 1962\)),
				'other' => q(juhokórejských hwanov \(1953 – 1962\)),
			},
		},
		'KRO' => {
			display_name => {
				'currency' => q(juhokórejský won \(1945 – 1953\)),
				'few' => q(juhokórejské wony \(1945 – 1953\)),
				'many' => q(juhokórejského wonu \(1945 – 1953\)),
				'one' => q(juhokórejský won \(1945 – 1953\)),
				'other' => q(juhokórejských wonov \(1945 – 1953\)),
			},
		},
		'KRW' => {
			symbol => 'KRW',
			display_name => {
				'currency' => q(juhokórejský won),
				'few' => q(juhokórejské wony),
				'many' => q(juhokórejského wonu),
				'one' => q(juhokórejský won),
				'other' => q(juhokórejských wonov),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(kuvajtský dinár),
				'few' => q(kuvajtské dináre),
				'many' => q(kuvajtského dinára),
				'one' => q(kuvajtský dinár),
				'other' => q(kuvajtských dinárov),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(kajmanský dolár),
				'few' => q(kajmanské doláre),
				'many' => q(kajmanského dolára),
				'one' => q(kajmanský dolár),
				'other' => q(kajmanských dolárov),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(kazašské tenge),
				'few' => q(kazašské tenge),
				'many' => q(kazašského tenge),
				'one' => q(kazašské tenge),
				'other' => q(kazašských tenge),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(laoský kip),
				'few' => q(laoské kipy),
				'many' => q(laoského kipu),
				'one' => q(laoský kip),
				'other' => q(laoských kipov),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(libanonská libra),
				'few' => q(libanonské libry),
				'many' => q(libanonskej libry),
				'one' => q(libanonská libra),
				'other' => q(libanonských libier),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(srílanská rupia),
				'few' => q(srílanské rupie),
				'many' => q(srílanskej rupie),
				'one' => q(srílanská rupia),
				'other' => q(srílanských rupií),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(libérijský dolár),
				'few' => q(libérijské doláre),
				'many' => q(libérijského dolára),
				'one' => q(libérijský dolár),
				'other' => q(libérijských dolárov),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(lesothský loti),
				'few' => q(lesothské loti),
				'many' => q(lesothského loti),
				'one' => q(lesothský loti),
				'other' => q(lesothských loti),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(litovský litas),
				'few' => q(litovské lity),
				'many' => q(litovského litu),
				'one' => q(litovský litas),
				'other' => q(litovských litov),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(litovský talonas),
				'few' => q(litovské talony),
				'many' => q(litovského talonu),
				'one' => q(litovský talonas),
				'other' => q(litovských talonov),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(luxemburský frank \(konvertibilný\)),
				'few' => q(luxemburské franky \(konvertibilné\)),
				'many' => q(luxemburského franku \(konvertibilného\)),
				'one' => q(luxemburský frank \(konvertibilný\)),
				'other' => q(luxemburských frankov \(konvertibilných\)),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(luxemburský frank),
				'few' => q(luxemburské franky),
				'many' => q(luxemburského franku),
				'one' => q(luxemburský frank),
				'other' => q(luxemburských frankov),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(luxemburský frank \(finančný\)),
				'few' => q(luxemburské franky \(finančné\)),
				'many' => q(luxemburského franku \(finančného\)),
				'one' => q(luxemburský frank \(finančný\)),
				'other' => q(luxemburských frankov \(finančných\)),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(lotyšský lat),
				'few' => q(lotyšské laty),
				'many' => q(lotyšského latu),
				'one' => q(lotyšský lat),
				'other' => q(lotyšských latov),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(lotyšský rubeľ),
				'few' => q(lotyšské ruble),
				'many' => q(lotyšského rubľa),
				'one' => q(lotyšský rubeľ),
				'other' => q(lotyšských rubľov),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(líbyjský dinár),
				'few' => q(líbyjské dináre),
				'many' => q(líbyjského dinára),
				'one' => q(líbyjský dinár),
				'other' => q(líbyjských dinárov),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(marocký dirham),
				'few' => q(marocké dirhamy),
				'many' => q(marockého dirhamu),
				'one' => q(marocký dirham),
				'other' => q(marockých dirhamov),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(marocký frank),
				'few' => q(marocké franky),
				'many' => q(marockého franku),
				'one' => q(marocký frank),
				'other' => q(marockých frankov),
			},
		},
		'MCF' => {
			display_name => {
				'currency' => q(monacký frank),
				'few' => q(monacké franky),
				'many' => q(monackého franku),
				'one' => q(monacký frank),
				'other' => q(monackých frankov),
			},
		},
		'MDC' => {
			display_name => {
				'currency' => q(moldavský kupón),
				'few' => q(moldavské kupóny),
				'many' => q(moldavského kupónu),
				'one' => q(moldavský kupón),
				'other' => q(moldavských kupónov),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(moldavský lei),
				'few' => q(moldavské lei),
				'many' => q(moldavského lei),
				'one' => q(moldavský lei),
				'other' => q(moldavských lei),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(malgašský ariary),
				'few' => q(malgašské ariary),
				'many' => q(malgašského ariary),
				'one' => q(malgašský ariary),
				'other' => q(malgašských ariary),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(madagaskarský frank),
				'few' => q(madagaskarské franky),
				'many' => q(madagaskarského franku),
				'one' => q(madagaskarský frank),
				'other' => q(madagaskarských frankov),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(macedónsky denár),
				'few' => q(macedónske denáre),
				'many' => q(macedónskeho denára),
				'one' => q(macedónsky denár),
				'other' => q(macedónskych denárov),
			},
		},
		'MKN' => {
			display_name => {
				'currency' => q(macedónsky denár \(1992 – 1993\)),
				'few' => q(macedónske denáre \(1992 – 1993\)),
				'many' => q(macedónskeho denára \(1992 – 1993\)),
				'one' => q(macedónsky denár \(1992 – 1993\)),
				'other' => q(macedónskych denárov \(1992 – 1993\)),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(malijský frank),
				'few' => q(malijské franky),
				'many' => q(malijského franku),
				'one' => q(malijský frank),
				'other' => q(malijské franky),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(mjanmarský kyat),
				'few' => q(mjanmarské kyaty),
				'many' => q(mjanmarského kyatu),
				'one' => q(mjanmarský kyat),
				'other' => q(mjanmarských kyatov),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(mongolský tugrik),
				'few' => q(mongolské tugriky),
				'many' => q(mongolského tugrika),
				'one' => q(mongolský tugrik),
				'other' => q(mongolských tugrikov),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(macajská pataca),
				'few' => q(macajské patacy),
				'many' => q(macajskej patacy),
				'one' => q(macajská pataca),
				'other' => q(macajských patác),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(mauritánska ukija \(1973–2017\)),
				'few' => q(mauritánske ukije \(1973–2017\)),
				'many' => q(mauritánskej ukije \(1973–2017\)),
				'one' => q(mauritánska ukija \(1973–2017\)),
				'other' => q(mauritánskych ukijí \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(mauritánska ouguiya),
				'few' => q(mauritánske ouguiye),
				'many' => q(mauritánskej ouguiye),
				'one' => q(mauritánska ouguiya),
				'other' => q(mauritánskych ouguiyí),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(maltská líra),
				'few' => q(maltské líry),
				'many' => q(maltskej líry),
				'one' => q(maltská líra),
				'other' => q(maltských lír),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(maltská libra),
				'few' => q(maltské libry),
				'many' => q(maltskej libry),
				'one' => q(maltská libra),
				'other' => q(maltských libier),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(maurícijská rupia),
				'few' => q(maurícijské rupie),
				'many' => q(maurícijskej rupie),
				'one' => q(maurícijská rupia),
				'other' => q(maurícijských rupií),
			},
		},
		'MVP' => {
			display_name => {
				'currency' => q(maldivská rupia \(1947 – 1981\)),
				'few' => q(maldivské rupie \(1947 – 1981\)),
				'many' => q(maldivskej rupie \(1947 – 1981\)),
				'one' => q(maldivská rupia \(1947 – 1981\)),
				'other' => q(maldivských rupií \(1947 – 1981\)),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(maldivská rupia),
				'few' => q(maldivské rupie),
				'many' => q(maldivskej rupie),
				'one' => q(maldivská rupia),
				'other' => q(maldivských rupií),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(malawijská kwacha),
				'few' => q(malawijské kwachy),
				'many' => q(malawijskej kwachy),
				'one' => q(malawijská kwacha),
				'other' => q(malawijských kwách),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(mexické peso),
				'few' => q(mexické pesos),
				'many' => q(mexického pesa),
				'one' => q(mexické peso),
				'other' => q(mexických pesos),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(mexické strieborné peso \(1861 – 1992\)),
				'few' => q(mexické strieborné pesos \(1861 – 1992\)),
				'many' => q(mexického strieborného pesa \(1861 – 1992\)),
				'one' => q(mexické strieborné peso \(1861 – 1992\)),
				'other' => q(mexických strieborných pesos \(1861 – 1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(mexická investičná jednotka),
				'few' => q(mexické investičné jednotky),
				'many' => q(mexickej investičnej jednotky),
				'one' => q(mexická investičná jednotka),
				'other' => q(mexických investičných jednotiek),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(malajzijský ringgit),
				'few' => q(malajzijské ringgity),
				'many' => q(malajzijského ringgitu),
				'one' => q(malajzijský ringgit),
				'other' => q(malajzijských ringgitov),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(mozambické escudo),
				'few' => q(mozambické escudá),
				'many' => q(mozambického escuda),
				'one' => q(mozambické escudo),
				'other' => q(mozambických escúd),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(mozambický metical \(1980 – 2006\)),
				'few' => q(mozambické meticaly \(1980–2006\)),
				'many' => q(mozambického meticalu \(1980–2006\)),
				'one' => q(mozambický metical \(1980–2006\)),
				'other' => q(mozambických meticalov \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(mozambický metical),
				'few' => q(mozambické meticaly),
				'many' => q(mozambického meticalu),
				'one' => q(mozambický metical),
				'other' => q(mozambických meticalov),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(namíbijský dolár),
				'few' => q(namíbijské doláre),
				'many' => q(namíbijského dolára),
				'one' => q(namíbijský dolár),
				'other' => q(namíbijských dolárov),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(nigérijská naira),
				'few' => q(nigérijské nairy),
				'many' => q(nigérijskej nairy),
				'one' => q(nigérijská naira),
				'other' => q(nigérijských nair),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(nikaragujská córdoba \(1988 – 1991\)),
				'few' => q(nikaragujské córdoby \(1988–1991\)),
				'many' => q(nikaragujskej córdoby \(1988–1991\)),
				'one' => q(nikaragujská córdoba \(1988–1991\)),
				'other' => q(nikaragujských córdob \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(nikaragujská córdoba),
				'few' => q(nikaragujské córdoby),
				'many' => q(nikaragujskej córdoby),
				'one' => q(nikaragujská córdoba),
				'other' => q(nikaragujských córdob),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(holandský gulden),
				'few' => q(holandské guldeny),
				'many' => q(holandského guldena),
				'one' => q(holandský gulden),
				'other' => q(holandských guldenov),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(nórska koruna),
				'few' => q(nórske koruny),
				'many' => q(nórskej koruny),
				'one' => q(nórska koruna),
				'other' => q(nórskych korún),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(nepálska rupia),
				'few' => q(nepálske rupie),
				'many' => q(nepálskej rupie),
				'one' => q(nepálska rupia),
				'other' => q(nepálskych rupií),
			},
		},
		'NZD' => {
			symbol => 'NZD',
			display_name => {
				'currency' => q(novozélandský dolár),
				'few' => q(novozélandské doláre),
				'many' => q(novozélandského dolára),
				'one' => q(novozélandský dolár),
				'other' => q(novozélandských dolárov),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(ománsky rial),
				'few' => q(ománske rialy),
				'many' => q(ománskeho rialu),
				'one' => q(ománsky rial),
				'other' => q(ománskych rialov),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(panamská balboa),
				'few' => q(panamské balboy),
				'many' => q(panamskej balboy),
				'one' => q(panamská balboa),
				'other' => q(panamských balboí),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(peruánsky inti),
				'few' => q(peruánske inti),
				'many' => q(peruánskeho inti),
				'one' => q(peruánsky inti),
				'other' => q(peruánskych inti),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(peruánsky sol),
				'few' => q(peruánske soly),
				'many' => q(peruánskeho sola),
				'one' => q(peruánsky sol),
				'other' => q(peruánskych solov),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(peruánsky sol \(1863 – 1965\)),
				'few' => q(peruánske soly \(1863–1965\)),
				'many' => q(peruánskeho sola \(1863–1965\)),
				'one' => q(peruánsky sol \(1863–1965\)),
				'other' => q(peruánskych solov \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(papuánska kina),
				'few' => q(papuánske kiny),
				'many' => q(papuánskej kiny),
				'one' => q(papuánska kina),
				'other' => q(papuánskych kín),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(filipínske peso),
				'few' => q(filipínske pesos),
				'many' => q(filipínskeho pesa),
				'one' => q(filipínske peso),
				'other' => q(filipínskych pesos),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(pakistanská rupia),
				'few' => q(pakistanské rupie),
				'many' => q(pakistanskej rupie),
				'one' => q(pakistanská rupia),
				'other' => q(pakistanských rupií),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(poľský zlotý),
				'few' => q(poľské zloté),
				'many' => q(poľského zlotého),
				'one' => q(poľský zlotý),
				'other' => q(poľských zlotých),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(poľský zlotý \(1950 – 1995\)),
				'few' => q(poľské zloté \(1950 – 1995\)),
				'many' => q(poľského zlotého \(1950 – 1995\)),
				'one' => q(poľský zlotý \(1950 – 1995\)),
				'other' => q(poľských zlotých \(1950 – 1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(portugalské escudo),
				'few' => q(portugalské escudá),
				'many' => q(portugalského escuda),
				'one' => q(portugalské escudo),
				'other' => q(portugalských escúd),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(paraguajské guaraní),
				'few' => q(paraguajské guaraní),
				'many' => q(paraguajského guaraní),
				'one' => q(paraguajské guaraní),
				'other' => q(paraguajských guaraní),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(katarský rial),
				'few' => q(katarské rialy),
				'many' => q(katarského rialu),
				'one' => q(katarský rial),
				'other' => q(katarských rialov),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(rodézsky dolár),
				'few' => q(rodézske doláre),
				'many' => q(rodézskeho dolára),
				'one' => q(rodézsky dolár),
				'other' => q(rodézskych dolárov),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(rumunský lei \(1952 – 2006\)),
				'few' => q(rumunské lei \(1952 – 2006\)),
				'many' => q(rumunského lei \(1952 – 2006\)),
				'one' => q(rumunský lei \(1952 – 2006\)),
				'other' => q(rumunských lei \(1952 – 2006\)),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(rumunský lei),
				'few' => q(rumunské lei),
				'many' => q(rumunského lei),
				'one' => q(rumunský lei),
				'other' => q(rumunských lei),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(srbský dinár),
				'few' => q(srbské dináre),
				'many' => q(srbského dinára),
				'one' => q(srbský dinár),
				'other' => q(srbských dinárov),
			},
		},
		'RUB' => {
			symbol => '₽',
			display_name => {
				'currency' => q(ruský rubeľ),
				'few' => q(ruské ruble),
				'many' => q(ruského rubľa),
				'one' => q(ruský rubeľ),
				'other' => q(ruských rubľov),
			},
		},
		'RUR' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(ruský rubeľ \(1991 – 1998\)),
				'few' => q(ruské ruble \(1991 – 1998\)),
				'many' => q(ruského rubľa \(1991 – 1998\)),
				'one' => q(ruský rubeľ \(1991 – 1998\)),
				'other' => q(ruských rubľov \(1991 – 1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(rwandský frank),
				'few' => q(rwandské franky),
				'many' => q(rwandského franku),
				'one' => q(rwandský frank),
				'other' => q(rwandských frankov),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(saudskoarabský rial),
				'few' => q(saudskoarabské rialy),
				'many' => q(saudskoarabského rialu),
				'one' => q(saudskoarabský rial),
				'other' => q(saudskoarabských rialov),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(šalamúnsky dolár),
				'few' => q(šalamúnske doláre),
				'many' => q(šalamúnskeho dolára),
				'one' => q(šalamúnsky dolár),
				'other' => q(šalamúnskych dolárov),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(seychelská rupia),
				'few' => q(seychelské rupie),
				'many' => q(seychelskej rupie),
				'one' => q(seychelská rupia),
				'other' => q(seychelských rupií),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(sudánsky dinár \(1992 – 2007\)),
				'few' => q(sudánske dináre \(1992 – 2007\)),
				'many' => q(sudánskeho dinára \(1992 – 2007\)),
				'one' => q(sudánsky dinár \(1992 – 2007\)),
				'other' => q(sudánskych dinárov \(1992 – 2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(sudánska libra),
				'few' => q(sudánske libry),
				'many' => q(sudánskej libry),
				'one' => q(sudánska libra),
				'other' => q(sudánskych libier),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(sudánska libra \(1957 – 1998\)),
				'few' => q(sudánske libry \(1957 – 1998\)),
				'many' => q(sudánskej libry \(1957 – 1998\)),
				'one' => q(sudánska libra \(1957 – 1998\)),
				'other' => q(sudánskych libier \(1957 – 1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(švédska koruna),
				'few' => q(švédske koruny),
				'many' => q(švédskej koruny),
				'one' => q(švédska koruna),
				'other' => q(švédskych korún),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(singapurský dolár),
				'few' => q(singapurské doláre),
				'many' => q(singapurského dolára),
				'one' => q(singapurský dolár),
				'other' => q(singapurských dolárov),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(svätohelenská libra),
				'few' => q(svätohelenské libry),
				'many' => q(svätohelenskej libry),
				'one' => q(svätohelenská libra),
				'other' => q(svätohelenských libier),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(slovinský toliar),
				'few' => q(slovinské toliare),
				'many' => q(slovinského toliara),
				'one' => q(slovinský toliar),
				'other' => q(slovinských toliarov),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(slovenská koruna),
				'few' => q(slovenské koruny),
				'many' => q(slovenskej koruny),
				'one' => q(slovenská koruna),
				'other' => q(slovenských korún),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(sierraleonský leone),
				'few' => q(sierraleonské leone),
				'many' => q(sierraleonského leone),
				'one' => q(sierraleonský leone),
				'other' => q(sierraleonských leone),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(sierraleonský leone \(1964—2022\)),
				'few' => q(sierraleonské leone \(1964—2022\)),
				'many' => q(sierraleonského leone \(1964—2022\)),
				'one' => q(sierraleonský leone \(1964—2022\)),
				'other' => q(sierraleonských leone \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(somálsky šiling),
				'few' => q(somálske šilingy),
				'many' => q(somálskeho šilingu),
				'one' => q(somálsky šiling),
				'other' => q(somálskych šilingov),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(surinamský dolár),
				'few' => q(surinamské doláre),
				'many' => q(surinamského dolára),
				'one' => q(surinamský dolár),
				'other' => q(surinamských dolárov),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(surinamský zlatý),
				'few' => q(surinamské zlaté),
				'many' => q(surinamského zlatého),
				'one' => q(surinamský zlatý),
				'other' => q(surinamských zlatých),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(juhosudánska libra),
				'few' => q(juhosudánske libry),
				'many' => q(juhosudánskej libry),
				'one' => q(juhosudánska libra),
				'other' => q(juhosudánskych libier),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(svätotomášska dobra \(1977–2017\)),
				'few' => q(svätotomášske dobry \(1977–2017\)),
				'many' => q(svätotomášskej dobry \(1977–2017\)),
				'one' => q(svätotomášska dobra \(1977–2017\)),
				'other' => q(svätotomášskych dobier \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(svätotomášska dobra),
				'few' => q(svätotomášske dobry),
				'many' => q(svätotomášskej dobry),
				'one' => q(svätotomášska dobra),
				'other' => q(svätotomášskych dobier),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(sovietsky rubeľ),
				'few' => q(sovietske ruble),
				'many' => q(sovietskeho rubľa),
				'one' => q(sovietsky rubeľ),
				'other' => q(sovietskych rubľov),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(salvádorský colón),
				'few' => q(salvádorské colóny),
				'many' => q(salvádorského colóna),
				'one' => q(salvádorský colón),
				'other' => q(salvádorských colónov),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(sýrska libra),
				'few' => q(sýrske libry),
				'many' => q(sýrskej libry),
				'one' => q(sýrska libra),
				'other' => q(sýrskych libier),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(svazijský lilangeni),
				'few' => q(svazijské lilangeni),
				'many' => q(svazijského lilangeni),
				'one' => q(svazijský lilangeni),
				'other' => q(svazijských lilangeni),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(thajský baht),
				'few' => q(thajské bahty),
				'many' => q(thajského bahtu),
				'one' => q(thajský baht),
				'other' => q(thajských bahtov),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(tadžický rubeľ),
				'few' => q(tadžické ruble),
				'many' => q(tadžického rubľa),
				'one' => q(tadžický rubeľ),
				'other' => q(tadžických rubľov),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(tadžické somoni),
				'few' => q(tadžické somoni),
				'many' => q(tadžického somoni),
				'one' => q(tadžické somoni),
				'other' => q(tadžických somoni),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(turkménsky manat \(1993 – 2009\)),
				'few' => q(turkménske manaty \(1993 – 2009\)),
				'many' => q(turkménskeho manatu \(1993 – 2009\)),
				'one' => q(turkménsky manat \(1993 – 2009\)),
				'other' => q(turkménskych manatov \(1993 – 2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(turkménsky manat),
				'few' => q(turkménske manaty),
				'many' => q(turkménskeho manatu),
				'one' => q(turkménsky manat),
				'other' => q(turkménskych manatov),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(tuniský dinár),
				'few' => q(tuniské dináre),
				'many' => q(tuniského dinára),
				'one' => q(tuniský dinár),
				'other' => q(tuniských dinárov),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(tongská paʻanga),
				'few' => q(tongské pa’anga),
				'many' => q(tongského pa’anga),
				'one' => q(tongská pa’anga),
				'other' => q(tongských pa’anga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(timorské escudo),
				'few' => q(timorské escudá),
				'many' => q(timorského escuda),
				'one' => q(timorské escudo),
				'other' => q(timorských escúd),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(turecká líra \(1922 – 2005\)),
				'few' => q(turecké líry \(1922 – 2005\)),
				'many' => q(tureckej líry \(1922 – 2005\)),
				'one' => q(turecká líra \(1922 – 2005\)),
				'other' => q(tureckých lír \(1922 – 2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(turecká líra),
				'few' => q(turecké líry),
				'many' => q(tureckej líry),
				'one' => q(turecká líra),
				'other' => q(tureckých lír),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(trinidadsko-tobažský dolár),
				'few' => q(trinidadsko-tobažské doláre),
				'many' => q(trinidadsko-tobažského dolára),
				'one' => q(trinidadsko-tobažský dolár),
				'other' => q(trinidadsko-tobažských dolárov),
			},
		},
		'TWD' => {
			symbol => 'TWD',
			display_name => {
				'currency' => q(nový taiwanský dolár),
				'few' => q(nové taiwanské doláre),
				'many' => q(nového taiwanského dolára),
				'one' => q(nový taiwanský dolár),
				'other' => q(nových taiwanských dolárov),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(tanzánsky šiling),
				'few' => q(tanzánske šilingy),
				'many' => q(tanzánskeho šilingu),
				'one' => q(tanzánsky šiling),
				'other' => q(tanzánskych šilingov),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(ukrajinská hrivna),
				'few' => q(ukrajinské hrivny),
				'many' => q(ukrajinskej hrivny),
				'one' => q(ukrajinská hrivna),
				'other' => q(ukrajinských hrivien),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(ukrajinský karbovanec),
				'few' => q(ukrajinské karbovance),
				'many' => q(ukrajinského karbovanca),
				'one' => q(ukrajinský karbovanec),
				'other' => q(ukrajinských karbovancov),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(ugandský šiling \(1966 – 1987\)),
				'few' => q(ugandské šilingy \(1966 – 1987\)),
				'many' => q(ugandského šilingu \(1966 – 1987\)),
				'one' => q(ugandský šiling \(1966 – 1987\)),
				'other' => q(ugandských šilingov \(1966 – 1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(ugandský šiling),
				'few' => q(ugandské šilingy),
				'many' => q(ugandského šilingu),
				'one' => q(ugandský šiling),
				'other' => q(ugandských šilingov),
			},
		},
		'USD' => {
			symbol => 'USD',
			display_name => {
				'currency' => q(americký dolár),
				'few' => q(americké doláre),
				'many' => q(amerického dolára),
				'one' => q(americký dolár),
				'other' => q(amerických dolárov),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(americký dolár \(ďalší deň\)),
				'few' => q(americké doláre \(ďalší deň\)),
				'many' => q(amerického dolára \(ďalší deň\)),
				'one' => q(americký dolár \(ďalší deň\)),
				'other' => q(amerických dolárov \(ďalší deň\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(americký dolár \(rovnaký deň\)),
				'few' => q(americké doláre \(rovnaký deň\)),
				'many' => q(amerického dolára \(rovnaký deň\)),
				'one' => q(americký dolár \(rovnaký deň\)),
				'other' => q(amerických dolárov \(rovnaký deň\)),
			},
		},
		'UYI' => {
			display_name => {
				'currency' => q(uruguajské peso \(v indexovaných jednotkách\)),
				'few' => q(uruguajské pesos \(v indexovaných jednotkách\)),
				'many' => q(uruguajského pesa \(v indexovaných jednotkách\)),
				'one' => q(uruguajské peso \(v indexovaných jednotkách\)),
				'other' => q(uruguajských pesos \(v indexovaných jednotkách\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(uruguajské peso \(1975 – 1993\)),
				'few' => q(uruguajské pesos \(1975 – 1993\)),
				'many' => q(uruguajského pesa \(1975 – 1993\)),
				'one' => q(uruguajské peso \(1975 – 1993\)),
				'other' => q(uruguajských pesos \(1975 – 1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(uruguajské peso),
				'few' => q(uruguajské pesos),
				'many' => q(uruguajského pesa),
				'one' => q(uruguajské peso),
				'other' => q(uruguajských pesos),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(uzbecký sum),
				'few' => q(uzbecké sumy),
				'many' => q(uzbeckého sumu),
				'one' => q(uzbecký sum),
				'other' => q(uzbeckých sumov),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(venezuelský bolívar \(1871 – 2008\)),
				'few' => q(venezuelské bolívary \(1871 – 2008\)),
				'many' => q(venezuelského bolívaru \(1871 – 2008\)),
				'one' => q(venezuelský bolívar \(1871 – 2008\)),
				'other' => q(venezuelských bolívarov \(1871 – 2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(venezuelský bolívar \(2008–2018\)),
				'few' => q(venezuelské bolívary \(2008–2018\)),
				'many' => q(venezuelského bolívaru \(2008–2018\)),
				'one' => q(venezuelský bolívar \(2008–2018\)),
				'other' => q(venezuelských bolívarov \(2008–2018\)),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(venezuelský bolívar),
				'few' => q(venezuelské bolívary),
				'many' => q(venezuelského bolívaru),
				'one' => q(venezuelský bolívar),
				'other' => q(venezuelských bolívarov),
			},
		},
		'VND' => {
			symbol => 'VND',
			display_name => {
				'currency' => q(vietnamský dong),
				'few' => q(vietnamské dongy),
				'many' => q(vietnamského dongu),
				'one' => q(vietnamský dong),
				'other' => q(vietnamských dongov),
			},
		},
		'VNN' => {
			display_name => {
				'currency' => q(vietnamský dong \(1978 – 1985\)),
				'few' => q(vietnamské dongy \(1978 – 1985\)),
				'many' => q(vietnamského dongu \(1978 – 1985\)),
				'one' => q(vietnamský dong \(1978 – 1985\)),
				'other' => q(vietnamských dongov \(1978 – 1985\)),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(vanuatské vatu),
				'few' => q(vanuatské vatu),
				'many' => q(vanuatského vatu),
				'one' => q(vanuatské vatu),
				'other' => q(vanuatských vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(samojská tala),
				'few' => q(samojské taly),
				'many' => q(samojskej taly),
				'one' => q(samojská tala),
				'other' => q(samojských tál),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(stredoafrický frank),
				'few' => q(stredoafrické franky),
				'many' => q(stredoafrického franku),
				'one' => q(stredoafrický frank),
				'other' => q(stredoafrických frankov),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(striebro),
				'few' => q(trójske unce striebra),
				'many' => q(trójskej unce striebra),
				'one' => q(trójska unca striebra),
				'other' => q(trójskych uncí striebra),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(zlato),
				'few' => q(trójske unce zlata),
				'many' => q(trójskej unce zlata),
				'one' => q(trójska unca zlata),
				'other' => q(trójskych uncí zlata),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(európska zmiešaná jednotka),
				'few' => q(európske zmiešané jednotky),
				'many' => q(európskej zmiešanej jednotky),
				'one' => q(európska zmiešaná jednotka),
				'other' => q(európskych zmiešaných jednotiek),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(európska peňažná jednotka),
				'few' => q(európske peňažné jednotky),
				'many' => q(európskej peňažnek jednotky),
				'one' => q(európska peňažná jednotka),
				'other' => q(európskych peňažných jednotiek),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(európska jednotka účtu 9 \(XBC\)),
				'few' => q(európske jednotky účtu 9 \(XBC\)),
				'many' => q(európskej jednotky účtu 9 \(XBC\)),
				'one' => q(európska jednotka účtu 9 \(XBC\)),
				'other' => q(európskych jednotiek účtu 9 \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(európska jednotka účtu 17 \(XBC\)),
				'few' => q(európske jednotky účtu 17 \(XBC\)),
				'many' => q(európskej jednotky účtu 17 \(XBC\)),
				'one' => q(európska jednotka účtu 17 \(XBC\)),
				'other' => q(európskych jednotiek účtu 17 \(XBC\)),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(východokaribský dolár),
				'few' => q(východokaribské doláre),
				'many' => q(východokaribského dolára),
				'one' => q(východokaribský dolár),
				'other' => q(východokaribských dolárov),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(SDR),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(európska menová jednotka),
				'few' => q(európske menové jednotky),
				'many' => q(európskej menovej jednotky),
				'one' => q(európska menová jednotka),
				'other' => q(európskych menových jednotiek),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(francúzsky zlatý frank),
				'few' => q(francúzske zlaté franky),
				'many' => q(francúzskeho zlatého franku),
				'one' => q(francúzsky zlatý frank),
				'other' => q(francúzskych zlatých frankov),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(francúzsky UIC frank),
				'few' => q(francúzske UIC franky),
				'many' => q(francúzskeho UIC franku),
				'one' => q(francúzsky UIC frank),
				'other' => q(francúzskych UIC frankov),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(západoafrický frank),
				'few' => q(západoafrické franky),
				'many' => q(západoafrického franku),
				'one' => q(západoafrický frank),
				'other' => q(západoafrických frankov),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(paládium),
				'few' => q(trójske unce paládia),
				'many' => q(trójskej unce paládia),
				'one' => q(trójska unca paládia),
				'other' => q(trójskych uncí paládia),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP frank),
				'few' => q(CFP franky),
				'many' => q(CFP franku),
				'one' => q(CFP frank),
				'other' => q(CFP frankov),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(platina),
				'few' => q(trójske unce platiny),
				'many' => q(trójskej unce platiny),
				'one' => q(trójska unca platiny),
				'other' => q(trójskej unce platiny),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(fondy RINET),
				'few' => q(jednotky fondov RINET),
				'many' => q(jednotky fondov RINET),
				'one' => q(jednotka fondov RINET),
				'other' => q(jednotiek fondov RINET),
			},
		},
		'XSU' => {
			display_name => {
				'currency' => q(sucre),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(kód testovacej meny),
				'few' => q(jednotky testovacej meny),
				'many' => q(jednotky testovacej meny),
				'one' => q(jednotka testovacej meny),
				'other' => q(jednotiek testovacej meny),
			},
		},
		'XUA' => {
			display_name => {
				'currency' => q(jednotka účtu ADB),
				'few' => q(jednotky účtu ADB),
				'many' => q(jednotky účtu ADB),
				'one' => q(jednotka účtu ADB),
				'other' => q(jednotiek účtu ADB),
			},
		},
		'XXX' => {
			symbol => 'XXX',
			display_name => {
				'currency' => q(neznáma mena),
				'few' => q(\(neznáma mena\)),
				'many' => q(\(neznáma mena\)),
				'one' => q(\(neznáma mena\)),
				'other' => q(\(neznáma mena\)),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(jemenský dinár),
				'few' => q(jemenské dináre),
				'many' => q(jemenského dinára),
				'one' => q(jemenský dinár),
				'other' => q(jemenských dinárov),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(jemenský rial),
				'few' => q(jemenské rialy),
				'many' => q(jemenského rialu),
				'one' => q(jemenský rial),
				'other' => q(jemenských rialov),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Juhoslávsky dinár [YUD]),
				'few' => q(juhoslovanské dináre \(1966 – 1990\)),
				'many' => q(juhoslovanského dinára \(1966 – 1990\)),
				'one' => q(juhoslovanský dinár \(1966 – 1990\)),
				'other' => q(juhoslovanských dinárov \(1966 – 1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(juhoslovanský nový dinár \(1994 – 2002\)),
				'few' => q(juhoslovanské nové dináre \(1994 – 2002\)),
				'many' => q(juhoslovanského nového dinára \(1994 – 2002\)),
				'one' => q(juhoslovanský nový dinár \(1994 – 2002\)),
				'other' => q(juhoslovanských nových dinárov \(1994 – 2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(juhoslovanský konvertibilný dinár \(1990 – 1992\)),
				'few' => q(juhoslovanské konvertibilné dináre \(1990 – 1992\)),
				'many' => q(juhoslovanského konvertibilného dinára \(1990 – 1992\)),
				'one' => q(juhoslovanský konvertibilný dinár \(1990 – 1992\)),
				'other' => q(juhoslovanských konvertibilných dinárov \(1990 – 1992\)),
			},
		},
		'YUR' => {
			display_name => {
				'currency' => q(juhoslovanský reformovaný dinár \(1992 – 1993\)),
				'few' => q(juhoslovanské reformované dináre \(1992 – 1993\)),
				'many' => q(juhoslovanského reformovaného dinára \(1992 – 1993\)),
				'one' => q(juhoslovanský reformovaný dinár \(1992 – 1993\)),
				'other' => q(juhoslovanských reformovaných dinárov \(1992 – 1993\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(juhoafrický rand \(finančný\)),
				'few' => q(juhoafrické randy \(finančné\)),
				'many' => q(juhoafrického randu \(finančného\)),
				'one' => q(juhoafrický rand \(finančný\)),
				'other' => q(juhoafrických randov \(finančných\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(juhoafrický rand),
				'few' => q(juhoafrické randy),
				'many' => q(juhoafrického randu),
				'one' => q(juhoafrický rand),
				'other' => q(juhoafrických randov),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(zambijská kwacha \(1968 – 2012\)),
				'few' => q(zambijské kwachy \(1968 – 2012\)),
				'many' => q(zambijskej kwachy \(1968 – 2012\)),
				'one' => q(zambijská kwacha \(1968 – 2012\)),
				'other' => q(zambijských kwách \(1968 – 2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(zambijská kwacha),
				'few' => q(zambijské kwachy),
				'many' => q(zambijskej kwachy),
				'one' => q(zambijská kwacha),
				'other' => q(zambijských kwách),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(zairský nový zaire \(1993 – 1998\)),
				'few' => q(zairské nové zairy \(1993 – 1998\)),
				'many' => q(zairského nového zairu \(1993 – 1998\)),
				'one' => q(zairský nový zaire \(1993 – 1998\)),
				'other' => q(zairských nových zairov \(1993 – 1998\)),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(zairský zaire \(1971 – 1993\)),
				'few' => q(zairské zairy \(1971 – 1993\)),
				'many' => q(zairského zairu \(1971 – 1993\)),
				'one' => q(zairský zaire \(1971 – 1993\)),
				'other' => q(zairských zairov \(1971 – 1993\)),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(zimbabwiansky dolár \(1980 – 2008\)),
				'few' => q(zimbabwianske doláre \(1980 – 2008\)),
				'many' => q(zimbabwianskeho dolára \(1980 – 2008\)),
				'one' => q(zimbabwiansky dolár \(1980 – 2008\)),
				'other' => q(zimbabwianskych dolárov \(1980 – 2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(zimbabwiansky dolár \(2009\)),
				'few' => q(zimbabwianske doláre \(2009\)),
				'many' => q(zimbabwianskeho dolára \(2009\)),
				'one' => q(zimbabwiansky dolár \(2009\)),
				'other' => q(zimbabwianskych dolárov \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(zimbabwiansky dolár \(2008\)),
				'few' => q(zimbabwianske doláre \(2008\)),
				'many' => q(zimbabwianskeho dolára \(2008\)),
				'one' => q(zimbabwiansky dolár \(2008\)),
				'other' => q(zimbabwianskych dolárov \(2008\)),
			},
		},
	} },
);


has 'calendar_months' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
			'coptic' => {
				'format' => {
					wide => {
						nonleap => [
							'tout',
							'baba',
							'hator',
							'kiahk',
							'toba',
							'amshir',
							'baramhat',
							'baramouda',
							'bashans',
							'ba’ouna',
							'abib',
							'mesra',
							'nasie'
						],
						leap => [
							
						],
					},
				},
			},
			'ethiopic' => {
				'format' => {
					wide => {
						nonleap => [
							'meskerem',
							'tikemet',
							'hidar',
							'tahesas',
							'tir',
							'yekatit',
							'megabit',
							'miyaza',
							'ginbot',
							'sene',
							'hamle',
							'nehase',
							'pagume'
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
							'jan',
							'feb',
							'mar',
							'apr',
							'máj',
							'jún',
							'júl',
							'aug',
							'sep',
							'okt',
							'nov',
							'dec'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'januára',
							'februára',
							'marca',
							'apríla',
							'mája',
							'júna',
							'júla',
							'augusta',
							'septembra',
							'októbra',
							'novembra',
							'decembra'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'j',
							'f',
							'm',
							'a',
							'm',
							'j',
							'j',
							'a',
							's',
							'o',
							'n',
							'd'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'január',
							'február',
							'marec',
							'apríl',
							'máj',
							'jún',
							'júl',
							'august',
							'september',
							'október',
							'november',
							'december'
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
							'tišri',
							'chešvan',
							'kislev',
							'tevet',
							'ševat',
							'adar I',
							'adar',
							'nisan',
							'ijar',
							'sivan',
							'tamuz',
							'av',
							'elul'
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
							'čaitra',
							'vaišákh',
							'džjéšth',
							'ášádh',
							'šrávana',
							'bhádrapad',
							'ášvin',
							'kártik',
							'agrahajana',
							'pauš',
							'mágh',
							'phálgun'
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
							'muh.',
							'saf.',
							'rab. I',
							'rab. II',
							'džum. I',
							'džum. II',
							'rad.',
							'ša.',
							'ram.',
							'šau.',
							'dhú l-k.',
							'dhú l-h.'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'al-muharram',
							'safar',
							'rabí´ al-avval',
							'rabí´ath-thání',
							'džumádá l-úlá',
							'džumádá l-áchira',
							'radžab',
							'ša´ bán',
							'ramadán',
							'šauvál',
							'dhú l-ka´ da',
							'dhú l-hidždža'
						],
						leap => [
							
						],
					},
				},
			},
			'persian' => {
				'format' => {
					wide => {
						nonleap => [
							'farvardin',
							'ordibehešt',
							'chordád',
							'tír',
							'mordád',
							'šahrívar',
							'mehr',
							'ábán',
							'ázar',
							'dei',
							'bahman',
							'esfand'
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
						mon => 'po',
						tue => 'ut',
						wed => 'st',
						thu => 'št',
						fri => 'pi',
						sat => 'so',
						sun => 'ne'
					},
					wide => {
						mon => 'pondelok',
						tue => 'utorok',
						wed => 'streda',
						thu => 'štvrtok',
						fri => 'piatok',
						sat => 'sobota',
						sun => 'nedeľa'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'p',
						tue => 'u',
						wed => 's',
						thu => 'š',
						fri => 'p',
						sat => 's',
						sun => 'n'
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
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					wide => {0 => '1. štvrťrok',
						1 => '2. štvrťrok',
						2 => '3. štvrťrok',
						3 => '4. štvrťrok'
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
			if ($_ eq 'coptic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'ethiopic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'generic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'hebrew') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'indian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'islamic') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'persian') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				last SWITCH;
				}
			if ($_ eq 'roc') {
				if($day_period_type eq 'default') {
					return 'midnight' if $time == 0;
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
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
					'afternoon1' => q{popol.},
					'evening1' => q{večer},
					'midnight' => q{o poln.},
					'morning1' => q{ráno},
					'morning2' => q{dopol.},
					'night1' => q{v noci},
					'noon' => q{napol.},
				},
				'narrow' => {
					'afternoon1' => q{pop.},
					'evening1' => q{več.},
					'midnight' => q{o poln.},
					'morning1' => q{ráno},
					'morning2' => q{dop.},
					'night1' => q{v n.},
					'noon' => q{nap.},
				},
				'wide' => {
					'afternoon1' => q{popoludní},
					'evening1' => q{večer},
					'midnight' => q{o polnoci},
					'morning1' => q{ráno},
					'morning2' => q{dopoludnia},
					'night1' => q{v noci},
					'noon' => q{napoludnie},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'afternoon1' => q{popol.},
					'evening1' => q{večer},
					'midnight' => q{poln.},
					'morning1' => q{ráno},
					'morning2' => q{dopol.},
					'night1' => q{noc},
					'noon' => q{pol.},
				},
				'narrow' => {
					'afternoon1' => q{pop.},
					'evening1' => q{več.},
					'morning1' => q{ráno},
					'morning2' => q{dop.},
					'night1' => q{noc},
				},
				'wide' => {
					'afternoon1' => q{popoludnie},
					'evening1' => q{večer},
					'midnight' => q{polnoc},
					'morning1' => q{ráno},
					'morning2' => q{dopoludnie},
					'night1' => q{noc},
					'noon' => q{poludnie},
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
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'pred Kr.',
				'1' => 'po Kr.'
			},
			wide => {
				'0' => 'pred Kristom',
				'1' => 'po Kristovi'
			},
		},
		'hebrew' => {
		},
		'indian' => {
			abbreviated => {
				'0' => 'Šaka'
			},
		},
		'islamic' => {
		},
		'persian' => {
		},
		'roc' => {
			abbreviated => {
				'0' => 'pred ROC',
				'1' => 'ROC'
			},
		},
	} },
);

has 'date_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
			'full' => q{EEEE, d. M. y G},
			'long' => q{d. M. y G},
			'medium' => q{d. M. y G},
			'short' => q{d.M.y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE d. MMMM y},
			'long' => q{d. MMMM y},
			'medium' => q{d. M. y},
			'short' => q{d. M. y},
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
		'coptic' => {
		},
		'ethiopic' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{H:mm:ss zzzz},
			'long' => q{H:mm:ss z},
			'medium' => q{H:mm:ss},
			'short' => q{H:mm},
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
		'coptic' => {
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
		'generic' => {
			EHm => q{E H:mm},
			EHms => q{E H:mm:ss},
			Ed => q{E d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{LLL y G},
			GyMMMEd => q{E d. M. y G},
			GyMMMMd => q{d. M. y G},
			GyMMMd => q{d. M. y G},
			H => q{H},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			M => q{M.},
			MEd => q{E d. M.},
			MMMEd => q{E d. M.},
			MMMMEd => q{E d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. M.},
			Md => q{d. M.},
			d => q{d.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			mmss => q{mm:ss},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E d. M. y GGGGG},
			yyyyMMM => q{LLL y G},
			yyyyMMMEd => q{E d. M. y G},
			yyyyMMMM => q{LLLL y G},
			yyyyMMMMd => q{d. MMMM y G},
			yyyyMMMd => q{d. M. y G},
			yyyyMd => q{d. M. y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{E d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{LLLL y G},
			GyMMMEd => q{E d. M. y G},
			GyMMMMd => q{d. M. y G},
			GyMMMd => q{d. M. y G},
			GyMd => q{d. M. y GGGGG},
			H => q{H},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			Hmsv => q{H:mm:ss v},
			Hmv => q{H:mm v},
			M => q{L.},
			MEd => q{E d. M.},
			MMMEd => q{E d. M.},
			MMMMEd => q{E d. MMMM},
			MMMMW => q{W. 'týždeň' MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. M.},
			Md => q{d. M.},
			d => q{d.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			mmss => q{mm:ss},
			yM => q{M/y},
			yMEd => q{E d. M. y},
			yMMM => q{M/y},
			yMMMEd => q{E d. M. y},
			yMMMM => q{LLLL y},
			yMMMMd => q{d. MMMM y},
			yMMMd => q{d. M. y},
			yMd => q{d. M. y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{w. 'týždeň' 'roka' Y},
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
			Bh => {
				h => q{h – h B},
			},
			Bhm => {
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
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
				G => q{E d. M. y GGGGG – E d. M. y GGGGG},
				M => q{E d. M. y – E d. M. y GGGGG},
				d => q{E d. M. y – E d. M. y GGGGG},
				y => q{E d. M. y – E d. M. y GGGGG},
			},
			GyMMM => {
				G => q{LLL y G – LLL y G},
				M => q{LLL – LLL y G},
				y => q{LLL y – LLL y G},
			},
			GyMMMEd => {
				G => q{E d. M. y G – E d. M. y G},
				M => q{E d. M. – E d. M. y G},
				d => q{E d. M. – E d. M. y G},
				y => q{E d. M. y – E d. M. y G},
			},
			GyMMMd => {
				G => q{d. M. y G – d. M. y G},
				M => q{d. M. – d. M. y G},
				d => q{d. – d. M. y G},
				y => q{d. M. y – d. M. y G},
			},
			GyMd => {
				G => q{d. M. y GGGGG – d. M. y GGGGG},
				M => q{d. M. y – d. M. y GGGGG},
				d => q{d. M. y – d. M. y GGGGG},
				y => q{d. M. y – d. M. y GGGGG},
			},
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{H:mm – H:mm},
				m => q{H:mm – H:mm},
			},
			Hmv => {
				H => q{H:mm – H:mm v},
				m => q{H:mm – H:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M. – M.},
			},
			MEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. – E d. M.},
			},
			MMMM => {
				M => q{LLLL – LLLL},
			},
			MMMd => {
				M => q{d. M. – d. M.},
				d => q{d. – d. M.},
			},
			Md => {
				M => q{d. M. – d. M.},
				d => q{d. M. – d. M.},
			},
			d => {
				d => q{d. – d.},
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
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E d. M. y – E d. M. y G},
				d => q{E d. M. y – E d. M. y G},
				y => q{E d. M. y – E d. M. y G},
			},
			yMMM => {
				M => q{LLL – LLL y G},
				y => q{LLL y – LLL y G},
			},
			yMMMEd => {
				M => q{E d. M. – E d. M. y G},
				d => q{E d. – E d. M. y G},
				y => q{E d. M. y – E d. M. y G},
			},
			yMMMM => {
				M => q{LLLL – LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{d. M. – d. M. y G},
				d => q{d. – d. M. y G},
				y => q{d. M. y – d. M. y G},
			},
			yMd => {
				M => q{d. M. y – d. M. y G},
				d => q{d. M. y – d. M. y G},
				y => q{d. M. y – d. M. y G},
			},
		},
		'gregorian' => {
			Bh => {
				h => q{h – h B},
			},
			Bhm => {
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
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
				G => q{E d. M. y GGGGG – E d. M. y GGGGG},
				M => q{E d. M. y – E d. M. y GGGGG},
				d => q{E d. M. y – E d. M. y GGGGG},
				y => q{E d. M. y – E d. M. y GGGGG},
			},
			GyMMM => {
				G => q{LLLL y G – LLLL y G},
				M => q{LLLL – LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			GyMMMEd => {
				G => q{E d. M. y G – E d. M. y G},
				M => q{E d. M. – E d. M. y G},
				d => q{E d. M. – E d. M. y G},
				y => q{E d. M. y – E d. M. y G},
			},
			GyMMMd => {
				G => q{d. M. y G – d. M. y G},
				M => q{d. M. – d. M. y G},
				d => q{d. – d. M. y G},
				y => q{d. M. y – d. M. y G},
			},
			GyMd => {
				G => q{d. M. y GGGGG – d. M. y GGGGG},
				M => q{d. M. y – d. M. y GGGGG},
				d => q{d. M. y – d. M. y GGGGG},
				y => q{d. M. y – d. M. y GGGGG},
			},
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{H:mm – H:mm},
				m => q{H:mm – H:mm},
			},
			Hmv => {
				H => q{H:mm – H:mm v},
				m => q{H:mm – H:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M. – M.},
			},
			MEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. – E d. M.},
			},
			MMMM => {
				M => q{LLLL – LLLL},
			},
			MMMd => {
				M => q{d. M. – d. M.},
				d => q{d. – d. M.},
			},
			Md => {
				M => q{d. M. – d. M.},
				d => q{d. M. – d. M.},
			},
			d => {
				d => q{d. – d.},
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
				m => q{h:mm – h:mm a v},
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
				M => q{E d. M. y – E d. M. y},
				d => q{E d. M. y – E d. M. y},
				y => q{E d. M. y – E d. M. y},
			},
			yMMM => {
				M => q{M – M/y},
				y => q{M/y – M/y},
			},
			yMMMEd => {
				M => q{E d. M. – E d. M. y},
				d => q{E d. – E d. M. y},
				y => q{E d. M. y – E d. M. y},
			},
			yMMMM => {
				M => q{LLLL – LLLL y},
				y => q{LLLL y – LLLL y},
			},
			yMMMd => {
				M => q{d. M. – d. M. y},
				d => q{d. – d. M. y},
				y => q{d. M. y – d. M. y},
			},
			yMd => {
				M => q{d. M. y – d. M. y},
				d => q{d. M. y – d. M. y},
				y => q{d. M. y – d. M. y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q(časové pásmo {0}),
		'Acre' => {
			long => {
				'daylight' => q#acrejský letný čas#,
				'generic' => q#acrejský čas#,
				'standard' => q#acrejský štandardný čas#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#afganský čas#,
			},
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alžír#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Káhira#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Džibuti#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El-Aaiún#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Chartúm#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadišo#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#N’Djamena#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Svätý Tomáš#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripolis#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#stredoafrický čas#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#východoafrický čas#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#juhoafrický čas#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#západoafrický letný čas#,
				'generic' => q#západoafrický čas#,
				'standard' => q#západoafrický štandardný čas#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#aljašský letný čas#,
				'generic' => q#aljašský čas#,
				'standard' => q#aljašský štandardný čas#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#almaatský letný čas#,
				'generic' => q#almaatský čas#,
				'standard' => q#almaatský štandardný čas#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#amazonský letný čas#,
				'generic' => q#amazonský čas#,
				'standard' => q#amazonský štandardný čas#,
			},
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kajmanie ostrovy#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Córdoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kostarika#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepé#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvádor#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamajka#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinik#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#México#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, Severná Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, Severná Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, Severná Dakota#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Portoriko#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarém#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Svätý Bartolomej#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#Svätá Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#Sv. Tomáš#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#Sv. Vincent#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#severoamerický centrálny letný čas#,
				'generic' => q#severoamerický centrálny čas#,
				'standard' => q#severoamerický centrálny štandardný čas#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#severoamerický východný letný čas#,
				'generic' => q#severoamerický východný čas#,
				'standard' => q#severoamerický východný štandardný čas#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#severoamerický horský letný čas#,
				'generic' => q#severoamerický horský čas#,
				'standard' => q#severoamerický horský štandardný čas#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#severoamerický tichomorský letný čas#,
				'generic' => q#severoamerický tichomorský čas#,
				'standard' => q#severoamerický tichomorský štandardný čas#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadyrský letný čas#,
				'generic' => q#Anadyrský čas#,
				'standard' => q#Anadyrský štandardný čas#,
			},
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Šówa#,
		},
		'Apia' => {
			long => {
				'daylight' => q#apijský letný čas#,
				'generic' => q#apijský čas#,
				'standard' => q#apijský štandardný čas#,
			},
		},
		'Aqtau' => {
			long => {
				'daylight' => q#aktauský letný čas#,
				'generic' => q#aktauský čas#,
				'standard' => q#aktauský štandardný čas#,
			},
		},
		'Aqtobe' => {
			long => {
				'daylight' => q#aktobský letný čas#,
				'generic' => q#aktobský čas#,
				'standard' => q#aktobský štandardný čas#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#arabský letný čas#,
				'generic' => q#arabský čas#,
				'standard' => q#arabský štandardný čas#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#argentínsky letný čas#,
				'generic' => q#argentínsky čas#,
				'standard' => q#argentínsky štandardný čas#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#západoargentínsky letný čas#,
				'generic' => q#západoargentínsky čas#,
				'standard' => q#západoargentínsky štandardný čas#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#arménsky letný čas#,
				'generic' => q#arménsky čas#,
				'standard' => q#arménsky štandardný čas#,
			},
		},
		'Asia/Amman' => {
			exemplarCity => q#Ammán#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#Aktau#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aktobe#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#Ašchabad#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#Bahrajn#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#Bejrút#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Biškek#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#Brunej#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkata#,
		},
		'Asia/Chita' => {
			exemplarCity => q#Čita#,
		},
		'Asia/Choibalsan' => {
			exemplarCity => q#Čojbalsan#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#Kolombo#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damask#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#Dháka#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubaj#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dušanbe#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Chovd#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#Jeruzalem#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#Kábul#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamčatka#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#Karáči#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Káthmandu#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#Chandyga#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kučing#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuvajt#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Maskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikózia#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#Novokuzneck#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Uraľsk#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Phnom Pénh#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pchjongjang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#Kostanaj#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#Kyzylorda#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#Rangún#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Rijád#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Hočiminovo Mesto#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sachalin#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#Soul#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#Šanghaj#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Tchaj-pej#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taškent#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teherán#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#Ulanbátar#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#Urumči#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#Usť-Nera#,
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
			exemplarCity => q#Jerevan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#atlantický letný čas#,
				'generic' => q#atlantický čas#,
				'standard' => q#atlantický štandardný čas#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azory#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermudy#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanárske ostrovy#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kapverdy#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Faerské ostrovy#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#Reykjavík#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Južná Georgia#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#Svätá Helena#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#stredoaustrálsky letný čas#,
				'generic' => q#stredoaustrálsky čas#,
				'standard' => q#stredoaustrálsky štandardný čas#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#stredozápadný austrálsky letný čas#,
				'generic' => q#stredozápadný austrálsky čas#,
				'standard' => q#stredozápadný austrálsky štandardný čas#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#východoaustrálsky letný čas#,
				'generic' => q#východoaustrálsky čas#,
				'standard' => q#východoaustrálsky štandardný čas#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#západoaustrálsky letný čas#,
				'generic' => q#západoaustrálsky čas#,
				'standard' => q#západoaustrálsky štandardný čas#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#azerbajdžanský letný čas#,
				'generic' => q#azerbajdžanský čas#,
				'standard' => q#azerbajdžanský štandardný čas#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#azorský letný čas#,
				'generic' => q#azorský čas#,
				'standard' => q#azorský štandardný čas#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#bangladéšsky letný čas#,
				'generic' => q#bangladéšsky čas#,
				'standard' => q#bangladéšsky štandardný čas#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#bhutánsky čas#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#bolívijský čas#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#brazílsky letný čas#,
				'generic' => q#brazílsky čas#,
				'standard' => q#brazílsky štandardný čas#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#brunejský čas#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#kapverdský letný čas#,
				'generic' => q#kapverdský čas#,
				'standard' => q#kapverdský štandardný čas#,
			},
		},
		'Casey' => {
			long => {
				'standard' => q#čas Caseyho stanice#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#chamorrský čas#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#chathamský letný čas#,
				'generic' => q#chathamský čas#,
				'standard' => q#chathamský štandardný čas#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#čilský letný čas#,
				'generic' => q#čilský čas#,
				'standard' => q#čilský štandardný čas#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#čínsky letný čas#,
				'generic' => q#čínsky čas#,
				'standard' => q#čínsky štandardný čas#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#čojbalsanský letný čas#,
				'generic' => q#čojbalsanský čas#,
				'standard' => q#čojbalsanský štandardný čas#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#čas Vianočného ostrova#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#čas Kokosových ostrovov#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#kolumbijský letný čas#,
				'generic' => q#kolumbijský čas#,
				'standard' => q#kolumbijský štandardný čas#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#letný čas Cookových ostrovov#,
				'generic' => q#čas Cookových ostrovov#,
				'standard' => q#štandardný čas Cookových ostrovov#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#kubánsky letný čas#,
				'generic' => q#kubánsky čas#,
				'standard' => q#kubánsky štandardný čas#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#čas Davisovej stanice#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#čas stanice Dumonta d’Urvillea#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#východotimorský čas#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#letný čas Veľkonočného ostrova#,
				'generic' => q#čas Veľkonočného ostrova#,
				'standard' => q#štandardný čas Veľkonočného ostrova#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#ekvádorský čas#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#koordinovaný svetový čas#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#neznáme mesto#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#Astrachán#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Atény#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belehrad#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#Berlín#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Brusel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukurešť#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#Budapešť#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#Büsingen#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kišiňov#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kodaň#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#írsky štandardný čas#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltár#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Ostrov Man#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kyjev#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lisabon#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#Ľubľana#,
		},
		'Europe/London' => {
			exemplarCity => q#Londýn#,
			long => {
				'daylight' => q#britský letný čas#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxembursko#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#Monako#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskva#,
		},
		'Europe/Paris' => {
			exemplarCity => q#Paríž#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praha#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rím#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Maríno#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Štokholm#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#Uľjanovsk#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Užhorod#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikán#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viedeň#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Varšava#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#Záhreb#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Záporožie#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürich#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#stredoeurópsky letný čas#,
				'generic' => q#stredoeurópsky čas#,
				'standard' => q#stredoeurópsky štandardný čas#,
			},
			short => {
				'daylight' => q#SELČ#,
				'generic' => q#SEČ#,
				'standard' => q#SEČ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#východoeurópsky letný čas#,
				'generic' => q#východoeurópsky čas#,
				'standard' => q#východoeurópsky štandardný čas#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#minský čas#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#západoeurópsky letný čas#,
				'generic' => q#západoeurópsky čas#,
				'standard' => q#západoeurópsky štandardný čas#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#falklandský letný čas#,
				'generic' => q#falklandský čas#,
				'standard' => q#falklandský štandardný čas#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#fidžijský letný čas#,
				'generic' => q#fidžijský čas#,
				'standard' => q#fidžijský štandardný čas#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#francúzskoguyanský čas#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#čas Francúzskych južných a antarktických území#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#greenwichský čas#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#galapágsky čas#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#gambierský čas#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#gruzínsky letný čas#,
				'generic' => q#gruzínsky čas#,
				'standard' => q#gruzínsky štandardný čas#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#čas Gilbertových ostrovov#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#východogrónsky letný čas#,
				'generic' => q#východogrónsky čas#,
				'standard' => q#východogrónsky štandardný čas#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#západogrónsky letný čas#,
				'generic' => q#západogrónsky čas#,
				'standard' => q#západogrónsky štandardný čas#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#guamský čas#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#štandardný čas Perzského zálivu#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#guyanský čas#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#havajsko-aleutský letný čas#,
				'generic' => q#havajsko-aleutský čas#,
				'standard' => q#havajsko-aleutský štandardný čas#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#hongkonský letný čas#,
				'generic' => q#hongkonský čas#,
				'standard' => q#hongkonský štandardný čas#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#chovdský letný čas#,
				'generic' => q#chovdský čas#,
				'standard' => q#chovdský štandardný čas#,
			},
		},
		'India' => {
			long => {
				'standard' => q#indický čas#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Vianočný ostrov#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#Kokosové ostrovy#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komory#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#Kergueleny#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#Mahé#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldivy#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#Maurícius#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#indickooceánsky čas#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#indočínsky čas#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#stredoindonézsky čas#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#východoindonézsky čas#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#západoindonézsky čas#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#iránsky letný čas#,
				'generic' => q#iránsky čas#,
				'standard' => q#iránsky štandardný čas#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#irkutský letný čas#,
				'generic' => q#irkutský čas#,
				'standard' => q#irkutský štandardný čas#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#izraelský letný čas#,
				'generic' => q#izraelský čas#,
				'standard' => q#izraelský štandardný čas#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#japonský letný čas#,
				'generic' => q#japonský čas#,
				'standard' => q#japonský štandardný čas#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Petropavlovsk-Kamčatskijský letný čas#,
				'generic' => q#Petropavlovsk-Kamčatský čas#,
				'standard' => q#Petropavlovsk-Kamčatský štandardný čas#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#východokazachstanský čas#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#západokazachstanský čas#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#kórejský letný čas#,
				'generic' => q#kórejský čas#,
				'standard' => q#kórejský štandardný čas#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#kosrajský čas#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#krasnojarský letný čas#,
				'generic' => q#krasnojarský čas#,
				'standard' => q#krasnojarský štandardný čas#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#kirgizský čas#,
			},
		},
		'Lanka' => {
			long => {
				'standard' => q#srílanský čas#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#čas Rovníkových ostrovov#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#letný čas ostrova lorda Howa#,
				'generic' => q#čas ostrova lorda Howa#,
				'standard' => q#štandardný čas ostrova lorda Howa#,
			},
		},
		'Macau' => {
			long => {
				'daylight' => q#macajský letný čas#,
				'generic' => q#macajský čas#,
				'standard' => q#macajský štandardný čas#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#čas ostrova Macquarie#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#magadanský letný čas#,
				'generic' => q#magadanský čas#,
				'standard' => q#magadanský štandardný čas#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#malajzijský čas#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#maldivský čas#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#markézsky čas#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#čas Marshallových ostrovov#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#maurícijský letný čas#,
				'generic' => q#maurícijský čas#,
				'standard' => q#maurícijský štandardný čas#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#čas Mawsonovej stanice#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#severozápadný mexický letný čas#,
				'generic' => q#severozápadný mexický čas#,
				'standard' => q#severozápadný mexický štandardný čas#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#mexický tichomorský letný čas#,
				'generic' => q#mexický tichomorský čas#,
				'standard' => q#mexický tichomorský štandardný čas#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#ulanbátarský letný čas#,
				'generic' => q#ulanbátarský čas#,
				'standard' => q#ulanbátarský štandardný čas#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#moskovský letný čas#,
				'generic' => q#moskovský čas#,
				'standard' => q#moskovský štandardný čas#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#mjanmarský čas#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#nauruský čas#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#nepálsky čas#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#novokaledónsky letný čas#,
				'generic' => q#novokaledónsky čas#,
				'standard' => q#novokaledónsky štandardný čas#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#novozélandský letný čas#,
				'generic' => q#novozélandský čas#,
				'standard' => q#novozélandský štandardný čas#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#newfoundlandský letný čas#,
				'generic' => q#newfoundlandský čas#,
				'standard' => q#newfoundlandský štandardný čas#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#niuejský čas#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#norfolský letný čas#,
				'generic' => q#norfolský čas#,
				'standard' => q#norfolský štandardný čas#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#letný čas súostrovia Fernando de Noronha#,
				'generic' => q#čas súostrovia Fernando de Noronha#,
				'standard' => q#štandardný čas súostrovia Fernando de Noronha#,
			},
		},
		'North_Mariana' => {
			long => {
				'standard' => q#severomariánsky čas#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#novosibirský letný čas#,
				'generic' => q#novosibirský čas#,
				'standard' => q#novosibirský štandardný čas#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#omský letný čas#,
				'generic' => q#omský čas#,
				'standard' => q#omský štandardný čas#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Veľkonočný ostrov#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidži#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapágy#,
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
			exemplarCity => q#Markézy#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#Nouméa#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#pakistanský letný čas#,
				'generic' => q#pakistanský čas#,
				'standard' => q#pakistanský štandardný čas#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#palauský čas#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#čas Papuy-Novej Guiney#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#paraguajský letný čas#,
				'generic' => q#paraguajský čas#,
				'standard' => q#paraguajský štandardný čas#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#peruánsky letný čas#,
				'generic' => q#peruánsky čas#,
				'standard' => q#peruánsky štandardný čas#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#filipínsky letný čas#,
				'generic' => q#filipínsky čas#,
				'standard' => q#filipínsky štandardný čas#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#čas Fénixových ostrovov#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#pierre-miquelonský letný čas#,
				'generic' => q#pierre-miquelonský čas#,
				'standard' => q#pierre-miquelonský štandardný čas#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#čas Pitcairnových ostrovov#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#ponapský čas#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#pchjongjanský čas#,
			},
		},
		'Qyzylorda' => {
			long => {
				'daylight' => q#kyzylordský letný čas#,
				'generic' => q#kyzylordský čas#,
				'standard' => q#kyzylordský štandardný čas#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#réunionský čas#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#čas Rotherovej stanice#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#sachalinský letný čas#,
				'generic' => q#sachalinský čas#,
				'standard' => q#sachalinský štandardný čas#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samarský letný čas#,
				'generic' => q#Samarský čas#,
				'standard' => q#Samarský štandardný čas#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#samojský letný čas#,
				'generic' => q#samojský čas#,
				'standard' => q#samojský štandardný čas#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#seychelský čas#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#singapurský štandardný čas#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#čas Šalamúnových ostrovov#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#čas Južnej Georgie#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#surinamský čas#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#čas stanice Šówa#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#tahitský čas#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#tchajpejský letný čas#,
				'generic' => q#tchajpejský čas#,
				'standard' => q#tchajpejský štandardný čas#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#tadžický čas#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#tokelauský čas#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#tonžský letný čas#,
				'generic' => q#tonžský čas#,
				'standard' => q#tonžský štandardný čas#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#chuukský čas#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#turkménsky letný čas#,
				'generic' => q#turkménsky čas#,
				'standard' => q#turkménsky štandardný čas#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#tuvalský čas#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#uruguajský letný čas#,
				'generic' => q#uruguajský čas#,
				'standard' => q#uruguajský štandardný čas#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#uzbecký letný čas#,
				'generic' => q#uzbecký čas#,
				'standard' => q#uzbecký štandardný čas#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#vanuatský letný čas#,
				'generic' => q#vanuatský čas#,
				'standard' => q#vanuatský štandardný čas#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#venezuelský čas#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#vladivostocký letný čas#,
				'generic' => q#vladivostocký čas#,
				'standard' => q#vladivostocký štandardný čas#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#volgogradský letný čas#,
				'generic' => q#volgogradský čas#,
				'standard' => q#volgogradský štandardný čas#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#čas stanice Vostok#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#čas ostrova Wake#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#čas ostrovov Wallis a Futuna#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#jakutský letný čas#,
				'generic' => q#jakutský čas#,
				'standard' => q#jakutský štandardný čas#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#jekaterinburský letný čas#,
				'generic' => q#jekaterinburský čas#,
				'standard' => q#jekaterinburský štandardný čas#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#yukonský čas#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
