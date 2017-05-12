=head1

Locale::CLDR::Locales::Sk - Package for language Slovak

=cut

package Locale::CLDR::Locales::Sk;
# This file auto generated from Data\common\main\sk.xml
#	on Fri 29 Apr  7:24:27 pm GMT

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
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-neuter','spellout-cardinal-feminine' ]},
);

has 'algorithmic_number_format_data' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { 
		use bignum;
		return {
		'spellout-cardinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
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
					rule => q(dvasať[­→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trisať[­→→]),
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
					rule => q(←%spellout-cardinal-masculine← milión[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milióny[ →→]),
				},
				'5000000' => {
					base_value => q(5000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← miliónov[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliarda[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliardy[ →→]),
				},
				'5000000000' => {
					base_value => q(5000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliardov[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilión[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilióny[ →→]),
				},
				'5000000000000' => {
					base_value => q(5000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← biliónov[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliarda[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliardy[ →→]),
				},
				'5000000000000000' => {
					base_value => q(5000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliardov[ →→]),
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
					rule => q(minus →→),
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
					rule => q(dvaásť),
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
					rule => q(dvasať[­→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trisať[­→→]),
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
					rule => q(←%spellout-cardinal-masculine← milión[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milióny[ →→]),
				},
				'5000000' => {
					base_value => q(5000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← miliónov[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliarda[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliardy[ →→]),
				},
				'5000000000' => {
					base_value => q(5000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliardov[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilión[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilióny[ →→]),
				},
				'5000000000000' => {
					base_value => q(5000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← biliónov[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliarda[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliardy[ →→]),
				},
				'5000000000000000' => {
					base_value => q(5000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliardov[ →→]),
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
					rule => q(minus →→),
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
					rule => q(dvasať[­→→]),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(trisať[­→→]),
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
					rule => q(←%spellout-cardinal-masculine← milión[ →→]),
				},
				'2000000' => {
					base_value => q(2000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← milióny[ →→]),
				},
				'5000000' => {
					base_value => q(5000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-masculine← miliónov[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliarda[ →→]),
				},
				'2000000000' => {
					base_value => q(2000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliardy[ →→]),
				},
				'5000000000' => {
					base_value => q(5000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-masculine← miliardov[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilión[ →→]),
				},
				'2000000000000' => {
					base_value => q(2000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← bilióny[ →→]),
				},
				'5000000000000' => {
					base_value => q(5000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-masculine← biliónov[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliarda[ →→]),
				},
				'2000000000000000' => {
					base_value => q(2000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliardy[ →→]),
				},
				'5000000000000000' => {
					base_value => q(5000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-masculine← biliardov[ →→]),
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
					rule => q(=#,###0.#=),
				},
				'max' => {
					divisor => q(1),
					rule => q(=#,###0.#=),
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
				'aa' => 'afarčina',
 				'ab' => 'abcházčina',
 				'ace' => 'acehčina',
 				'ach' => 'ačoli',
 				'ada' => 'adangme',
 				'ady' => 'adygčina',
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
 				'anp' => 'angika',
 				'ar' => 'arabčina',
 				'ar_001' => 'arabčina (moderná štandardná)',
 				'arc' => 'aramejčina',
 				'arn' => 'araukánčina',
 				'arp' => 'arapaho',
 				'arw' => 'arawačtina',
 				'as' => 'ásamčina',
 				'asa' => 'asu',
 				'ast' => 'astúrčina',
 				'av' => 'avarčina',
 				'awa' => 'avadhčina',
 				'ay' => 'aymarčina',
 				'az' => 'azerbajdžančina',
 				'az@alt=short' => 'azerbajdžančina',
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
 				'bgn' => 'západná balúčtina',
 				'bho' => 'bhódžpurčina',
 				'bi' => 'bislama',
 				'bik' => 'bikol',
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
 				'car' => 'karibský',
 				'cay' => 'cayuga',
 				'cch' => 'atsam',
 				'ce' => 'čečenčina',
 				'ceb' => 'cebuánčina',
 				'cgg' => 'kiga',
 				'ch' => 'čamorčina',
 				'chb' => 'čibča',
 				'chg' => 'čagatajčina',
 				'chk' => 'truk',
 				'chm' => 'marijčina',
 				'chn' => 'činucký žargón',
 				'cho' => 'čoktavčina',
 				'chp' => 'čipevajčina',
 				'chr' => 'čerokí',
 				'chy' => 'čejenčina',
 				'ckb' => 'kurdčina (sorání)',
 				'co' => 'korzičtina',
 				'cop' => 'koptčina',
 				'cr' => 'krí',
 				'crh' => 'krymská turečtina',
 				'cs' => 'čeština',
 				'csb' => 'kašubčina',
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
 				'den' => 'slovančina',
 				'dgr' => 'dogribčina',
 				'din' => 'dinka',
 				'dje' => 'zarma',
 				'doi' => 'dógrí',
 				'dsb' => 'dolnolužická srbčina',
 				'dua' => 'duala',
 				'dum' => 'stredná holandčina',
 				'dv' => 'divehi',
 				'dyo' => 'jola-fonyi',
 				'dyu' => 'ďula',
 				'dz' => 'dzongkä',
 				'dzg' => 'dazaga',
 				'ebu' => 'embu',
 				'ee' => 'eweština',
 				'efi' => 'efik',
 				'egy' => 'staroegyptský',
 				'eka' => 'ekadžuk',
 				'el' => 'gréčtina',
 				'elx' => 'elamčina',
 				'en' => 'angličtina',
 				'en_AU' => 'angličtina (austrálska)',
 				'en_CA' => 'angličtina (kanadská)',
 				'en_GB' => 'angličtina (britská)',
 				'en_GB@alt=short' => 'angličtina (britská)',
 				'en_US' => 'angličtina (americká)',
 				'en_US@alt=short' => 'angličtina (americká)',
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
 				'frm' => 'stredná francúzština',
 				'fro' => 'stará francúzština',
 				'frr' => 'severná frízština',
 				'frs' => 'východná frízština',
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
 				'gwi' => 'gwichʼin',
 				'ha' => 'hauština',
 				'hai' => 'haida',
 				'haw' => 'havajčina',
 				'he' => 'hebrejčina',
 				'hi' => 'hindčina',
 				'hil' => 'hiligajnončina',
 				'hit' => 'chetitčina',
 				'hmn' => 'hmong',
 				'ho' => 'hiri motu',
 				'hr' => 'chorvátčina',
 				'hsb' => 'hornolužická srbčina',
 				'ht' => 'haitčina',
 				'hu' => 'maďarčina',
 				'hup' => 'hupčina',
 				'hy' => 'arménčina',
 				'hz' => 'herero',
 				'ia' => 'interlingua',
 				'iba' => 'ibančina',
 				'ibb' => 'ibibio',
 				'id' => 'indonézština',
 				'ie' => 'interlingue',
 				'ig' => 'igboština',
 				'ii' => 's’čchuanská ioština',
 				'ik' => 'inupiaq',
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
 				'krc' => 'karačajevsko-balkarský jazyk',
 				'krl' => 'karelčina',
 				'kru' => 'kurukhčina',
 				'ks' => 'kašmírčina',
 				'ksb' => 'šambala',
 				'ksf' => 'bafia',
 				'ksh' => 'kolínčina',
 				'ku' => 'kurdčina',
 				'kum' => 'kumyčtina',
 				'kut' => 'kutenajčina',
 				'kv' => 'komijčina',
 				'kw' => 'kornčina',
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
 				'lkt' => 'lakotčina',
 				'ln' => 'lingalčina',
 				'lo' => 'laoština',
 				'lol' => 'mongo',
 				'loz' => 'lozi',
 				'lrc' => 'severné luri',
 				'lt' => 'litovčina',
 				'lu' => 'lubčina (katanžská)',
 				'lua' => 'luba-luluánčina',
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
 				'men' => 'mendi',
 				'mer' => 'meru',
 				'mfe' => 'maurícijská kreolčina',
 				'mg' => 'malgaština',
 				'mga' => 'stredná írčina',
 				'mgh' => 'makua-meetto',
 				'mgo' => 'meta’',
 				'mh' => 'kajin-majol',
 				'mi' => 'maorijčina',
 				'mic' => 'mikmakčina',
 				'min' => 'minangkabaučina',
 				'mk' => 'macedónčina',
 				'ml' => 'malajálamčina',
 				'mn' => 'mongolčina',
 				'mnc' => 'mandžuština',
 				'mni' => 'manípurčina',
 				'moh' => 'mohawkčina',
 				'mos' => 'mossi',
 				'mr' => 'maráthčina',
 				'ms' => 'malajčina',
 				'mt' => 'maltčina',
 				'mua' => 'mundang',
 				'mul' => 'viaceré jazyky',
 				'mus' => 'kríkčina',
 				'mwl' => 'mirandčina',
 				'mwr' => 'marawari',
 				'my' => 'barmčina',
 				'mye' => 'myene',
 				'myv' => 'erzjančina',
 				'mzn' => 'mázandaránčina',
 				'na' => 'nauru',
 				'nap' => 'neapolčina',
 				'naq' => 'nama',
 				'nb' => 'nórčina (bokmål)',
 				'nd' => 'severné ndebele',
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
 				'nr' => 'južná ndebelčina',
 				'nso' => 'severná sothčina',
 				'nus' => 'nuer',
 				'nv' => 'navajo',
 				'nwc' => 'klasická nevárčina',
 				'ny' => 'čewa',
 				'nym' => 'ňamwezi',
 				'nyn' => 'ňankole',
 				'nyo' => 'ňoro',
 				'nzi' => 'nzima',
 				'oc' => 'okcitánčina',
 				'oj' => 'odžibva',
 				'om' => 'oromčina',
 				'or' => 'uríjčina',
 				'os' => 'osetčina',
 				'osa' => 'osagčina',
 				'ota' => 'osmanská turečtina',
 				'pa' => 'pandžábčina',
 				'pag' => 'pangasinančina',
 				'pal' => 'pahlaví',
 				'pam' => 'pampanga',
 				'pap' => 'papiamento',
 				'pau' => 'palaučina',
 				'peo' => 'stará perzština',
 				'phn' => 'feničtina',
 				'pi' => 'pálí',
 				'pl' => 'poľština',
 				'pon' => 'pohnpeičina',
 				'pro' => 'stará okcitánčina',
 				'ps' => 'paštčina',
 				'pt' => 'portugalčina',
 				'pt_BR' => 'portugalčina (brazílska)',
 				'pt_PT' => 'portugalčina (európska)',
 				'qu' => 'kečuánčina',
 				'quc' => 'kičé',
 				'raj' => 'radžastančina',
 				'rap' => 'rapanujčina',
 				'rar' => 'rarotongan',
 				'rm' => 'rétorománčina',
 				'rn' => 'kirundčina',
 				'ro' => 'rumunčina',
 				'ro_MD' => 'moldavčina',
 				'rof' => 'rombo',
 				'rom' => 'rómčina',
 				'root' => 'koreň',
 				'ru' => 'ruština',
 				'rup' => 'arumunčina',
 				'rw' => 'kiňarwanda',
 				'rwk' => 'rwa',
 				'sa' => 'sanskrit',
 				'sad' => 'sandawe',
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
 				'sdh' => 'kurdčina (južná)',
 				'se' => 'lapončina (severná)',
 				'see' => 'seneca',
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
 				'sm' => 'samojčina',
 				'sma' => 'lapončina (južná)',
 				'smj' => 'lapončina (lulská)',
 				'smn' => 'lapončina (inarijská)',
 				'sms' => 'lapončina (skoltská)',
 				'sn' => 'šončina',
 				'snk' => 'soninke',
 				'so' => 'somálčina',
 				'sog' => 'sogdijčina',
 				'sq' => 'albánčina',
 				'sr' => 'srbčina',
 				'srn' => 'sranan',
 				'srr' => 'serer',
 				'ss' => 'svazijčina',
 				'ssy' => 'saho',
 				'st' => 'južná sothčina',
 				'su' => 'sundčina',
 				'suk' => 'sukuma',
 				'sus' => 'susu',
 				'sux' => 'sumerčina',
 				'sv' => 'švédčina',
 				'sw' => 'svahilčina',
 				'sw_CD' => 'svahilčina (konžská)',
 				'swb' => 'komorčina',
 				'syc' => 'klasická sýrčina',
 				'syr' => 'sýrčina',
 				'ta' => 'tamilčina',
 				'te' => 'telugčina',
 				'tem' => 'temne',
 				'teo' => 'teso',
 				'ter' => 'tereno',
 				'tet' => 'tetum',
 				'tg' => 'tadžičtina',
 				'th' => 'thajčina',
 				'ti' => 'tigriňa',
 				'tig' => 'tigrejčina',
 				'tiv' => 'tiv',
 				'tk' => 'turkménčina',
 				'tkl' => 'tokelaučina',
 				'tl' => 'tagalčina',
 				'tlh' => 'klingónčina',
 				'tli' => 'tlingitčina',
 				'tmh' => 'tamašek',
 				'tn' => 'tswančina',
 				'to' => 'tongčina',
 				'tog' => 'ňasa tonga',
 				'tpi' => 'tok pisin',
 				'tr' => 'turečtina',
 				'trv' => 'taroko',
 				'ts' => 'tsonga',
 				'tsi' => 'tsimshijské jazyky',
 				'tt' => 'tatárčina',
 				'tum' => 'tumbuka',
 				'tvl' => 'tuvalčina',
 				'tw' => 'twi',
 				'twq' => 'tasawaq',
 				'ty' => 'tahitčina',
 				'tyv' => 'tuviančina',
 				'tzm' => 'tamašek (stredomarocký)',
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
 				'wal' => 'walamo',
 				'war' => 'waray',
 				'was' => 'washo',
 				'wbp' => 'warlpiri',
 				'wo' => 'wolofčina',
 				'xal' => 'kalmyčtina',
 				'xh' => 'xhoština',
 				'xog' => 'soga',
 				'yao' => 'jao',
 				'yap' => 'japčina',
 				'yav' => 'jangben',
 				'ybb' => 'yemba',
 				'yi' => 'jidiš',
 				'yo' => 'jorubčina',
 				'yue' => 'kantončina',
 				'za' => 'čuangčina',
 				'zap' => 'zapotéčtina',
 				'zbl' => 'systém Bliss',
 				'zen' => 'zenaga',
 				'zgh' => 'tamašek (štandardný marocký)',
 				'zh' => 'čínština',
 				'zh_Hans' => 'čínština (zjednodušená)',
 				'zh_Hant' => 'čínština (tradičná)',
 				'zu' => 'zuluština',
 				'zun' => 'zuniština',
 				'zxx' => 'bez jazykového obsahu',
 				'zza' => 'zázá',

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
			'Arab' => 'arabské',
 			'Arab@alt=variant' => 'perzsko-arabské',
 			'Armn' => 'arménske',
 			'Bali' => 'balijský',
 			'Beng' => 'bengálske',
 			'Bopo' => 'bopomofo',
 			'Brai' => 'braillovo',
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
 			'Hang' => 'hangul',
 			'Hani' => 'čínske',
 			'Hans' => 'zjednodušené',
 			'Hans@alt=stand-alone' => 'čínske zjednodušené',
 			'Hant' => 'tradičné',
 			'Hant@alt=stand-alone' => 'čínske tradičné',
 			'Hebr' => 'hebrejské',
 			'Hira' => 'hiragana',
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
 			'Mymr' => 'barmské',
 			'Orya' => 'uríjske',
 			'Osma' => 'osmanský',
 			'Runr' => 'Runové písmo',
 			'Sinh' => 'sinhálske',
 			'Taml' => 'tamilské',
 			'Telu' => 'telugské',
 			'Thaa' => 'tána',
 			'Thai' => 'thajské',
 			'Tibt' => 'tibetské',
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
 			'419' => 'Latinská Amerika',
 			'AC' => 'Ascensión',
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
 			'AX' => 'Ålandy',
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
 			'CD' => 'Kongo - Kinshasa',
 			'CD@alt=variant' => 'Konžská demokratická republika',
 			'CF' => 'Stredoafrická republika',
 			'CG' => 'Kongo - Brazzaville',
 			'CG@alt=variant' => 'Konžská republika',
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
 			'CZ' => 'Česká republika',
 			'DE' => 'Nemecko',
 			'DG' => 'Diego García',
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
 			'GF' => 'Francúzska Guayana',
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
 			'GY' => 'Guayana',
 			'HK' => 'Hongkong – OAO Číny',
 			'HK@alt=short' => 'Hongkong',
 			'HM' => 'Heardov ostrov a McDonaldove ostrovy',
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
 			'MF' => 'Svätý Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshallove ostrovy',
 			'MK' => 'Macedónsko',
 			'MK@alt=variant' => 'Macedónsko (BJRM)',
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
 			'OM' => 'Omán',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Francúzska Polynézia',
 			'PG' => 'Papua Nová Guinea',
 			'PH' => 'Filipíny',
 			'PK' => 'Pakistan',
 			'PL' => 'Poľsko',
 			'PM' => 'Saint Pierre a Miquelon',
 			'PN' => 'Pitcairnove ostrovy',
 			'PR' => 'Portoriko',
 			'PS' => 'Palestínske územia',
 			'PS@alt=short' => 'Palestína',
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
 			'SX' => 'Sint Maarten',
 			'SY' => 'Sýria',
 			'SZ' => 'Svazijsko',
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
 			'colalternate' => 'Ignorovať radenie symbolov',
 			'colbackwards' => 'Obrátené radenie akcentov',
 			'colcasefirst' => 'Radenie veľkých a malých písmen',
 			'colcaselevel' => 'Rozlišovanie veľkých a malých písmen pri radení',
 			'colhiraganaquaternary' => 'Radenie podľa slabičných písiem (kana)',
 			'collation' => 'zoradenie',
 			'colnormalization' => 'Normalizované radenie',
 			'colnumeric' => 'Číselné radenie',
 			'colstrength' => 'Sila radenia',
 			'currency' => 'mena',
 			'hc' => 'hodinový cyklus (12 vs 24)',
 			'lb' => 'štýl koncov riadka',
 			'ms' => 'merná sústava',
 			'numbers' => 'čísla',
 			'timezone' => 'Časové pásmo',
 			'va' => 'Variant miestneho nastavenia',
 			'variabletop' => 'Radiť ako symboly',
 			'x' => 'Súkromné použitie',

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
 				'coptic' => q{Koptický kalendár},
 				'dangi' => q{kórejský kalendár},
 				'ethiopic' => q{etiópsky kalendár},
 				'ethiopic-amete-alem' => q{Etiópsky kalendár Amete Alem},
 				'gregorian' => q{gregoriánsky kalendár},
 				'hebrew' => q{židovský kalendár},
 				'indian' => q{Indický národný kalendár},
 				'islamic' => q{islamský kalendár},
 				'islamic-civil' => q{Islamský občiansky kalendár},
 				'iso8601' => q{kalendár ISO 8601},
 				'japanese' => q{japonský kalendár},
 				'persian' => q{perzský kalendár},
 				'roc' => q{čínsky republikánsky kalendár},
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
 			'colhiraganaquaternary' => {
 				'no' => q{Radiť slabičné písma (kana) samostatne},
 				'yes' => q{Radiť slabičné písma (kana) inak},
 			},
 			'collation' => {
 				'big5han' => q{Tradičný čínsky Big5},
 				'dictionary' => q{Usporiadanie slovníka},
 				'ducet' => q{predvolené zoradenie unicode},
 				'gb2312han' => q{Zjednodušený čínsky GB2312},
 				'phonebook' => q{Lexikografické triedenie},
 				'phonetic' => q{Fonetické radenie},
 				'pinyin' => q{Triedenie pinyin},
 				'reformed' => q{Reformované usporiadanie},
 				'search' => q{všeobecné vyhľadávanie},
 				'searchjl' => q{Hľadať podľa počiatočnej spoluhlásky písma Hangul},
 				'standard' => q{štandardné zoradenie},
 				'stroke' => q{Tiedenie podľa ťahov},
 				'traditional' => q{Tradičné},
 				'unihan' => q{Usporiadanie podľa znakov radikál},
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
 				'jpan' => q{japonské číslice},
 				'jpanfin' => q{japonské finančné číslice},
 				'khmr' => q{khmérske číslice},
 				'knda' => q{kannadské číslice},
 				'laoo' => q{laoské číslice},
 				'latn' => q{arabské číslice},
 				'mlym' => q{malajálamske číslice},
 				'mong' => q{Mongolské číslice},
 				'mymr' => q{barmské číslice},
 				'native' => q{Natívne číslice},
 				'orya' => q{uríjske číslice},
 				'roman' => q{rímske číslice},
 				'romanlow' => q{malé rímske číslice},
 				'taml' => q{číslice tradičnej tamilčiny},
 				'tamldec' => q{tamilské číslice},
 				'telu' => q{telugské číslice},
 				'thai' => q{thajské číslice},
 				'tibt' => q{tibetské číslice},
 				'traditional' => q{Tradičné číslovky},
 				'vaii' => q{Vaiské číslice},
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

has 'display_name_transform_name' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'bgn' => 'BGN',
 			'numeric' => 'Číslice',
 			'tone' => 'Tón',
 			'ungegn' => 'UNGEGN',
 			'x-accents' => 'Diakritika',
 			'x-fullwidth' => 'Celá šírka',
 			'x-halfwidth' => 'Polovičná šírka',
 			'x-jamo' => 'Jamo',
 			'x-pinyin' => 'Pinyin',
 			'x-publishing' => 'Uverejnenie',

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
			auxiliary => qr{(?^u:[à ă â å ā æ ç è ĕ ê ë ē ì ĭ î ï ī ñ ò ŏ ö ø ō œ ř ù ŭ û ü ū ÿ])},
			index => ['A', 'Ä', 'B', 'C', 'Č', 'D', 'Ď', 'E', 'F', 'G', 'H', '{CH}', 'I', 'J', 'K', 'L', 'Ľ', 'M', 'N', 'O', 'Ô', 'P', 'Q', 'R', 'S', 'Š', 'T', 'Ť', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž'],
			main => qr{(?^u:[a á ä b c č d ď e é f g h {ch} i í j k l ĺ ľ m n ň o ó ô p q r ŕ s š t ť u ú v w x y ý z ž])},
			punctuation => qr{(?^u:[\- ‐ – , ; \: ! ? . … ‘ ‚ “ „ ( ) \[ \] § @ * / \&])},
		};
	},
EOT
: sub {
		return { index => ['A', 'Ä', 'B', 'C', 'Č', 'D', 'Ď', 'E', 'F', 'G', 'H', '{CH}', 'I', 'J', 'K', 'L', 'Ľ', 'M', 'N', 'O', 'Ô', 'P', 'Q', 'R', 'S', 'Š', 'T', 'Ť', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ž'], };
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
					'acre' => {
						'few' => q({0} akre),
						'many' => q({0} akra),
						'name' => q(akre),
						'one' => q({0} aker),
						'other' => q({0} akrov),
					},
					'acre-foot' => {
						'few' => q({0} akrové stopy),
						'many' => q({0} akrovej stopy),
						'name' => q(akrové stopy),
						'one' => q({0} akrová stopa),
						'other' => q({0} akrových stôp),
					},
					'ampere' => {
						'few' => q({0} ampéry),
						'many' => q({0} ampéra),
						'name' => q(ampéry),
						'one' => q({0} ampér),
						'other' => q({0} ampérov),
					},
					'arc-minute' => {
						'few' => q({0} minúty),
						'many' => q({0} minúty),
						'name' => q(minúty),
						'one' => q({0} minúta),
						'other' => q({0} minút),
					},
					'arc-second' => {
						'few' => q({0} sekundy),
						'many' => q({0} sekundy),
						'name' => q(sekundy),
						'one' => q({0} sekunda),
						'other' => q({0} sekúnd),
					},
					'astronomical-unit' => {
						'few' => q({0} astronomické jednotky),
						'many' => q({0} astronomickej jednotky),
						'name' => q(astronomické jednotky),
						'one' => q({0} astronomická jednotka),
						'other' => q({0} astronomických jednotiek),
					},
					'bit' => {
						'few' => q({0} bity),
						'many' => q({0} bitu),
						'name' => q(bity),
						'one' => q({0} bit),
						'other' => q({0} bitov),
					},
					'byte' => {
						'few' => q({0} bajty),
						'many' => q({0} bajtu),
						'name' => q(bajty),
						'one' => q({0} bajt),
						'other' => q({0} bajtov),
					},
					'calorie' => {
						'few' => q({0} kalórie),
						'many' => q({0} kalórie),
						'name' => q(kalórie),
						'one' => q({0} kalória),
						'other' => q({0} kalórií),
					},
					'carat' => {
						'few' => q({0} karáty),
						'many' => q({0} karátu),
						'name' => q(karáty),
						'one' => q({0} karát),
						'other' => q({0} karátov),
					},
					'celsius' => {
						'few' => q({0} stupne Celzia),
						'many' => q({0} stupňa Celzia),
						'name' => q(stupne Celzia),
						'one' => q({0} stupeň Celzia),
						'other' => q({0} stupňov Celzia),
					},
					'centiliter' => {
						'few' => q({0} centilitre),
						'many' => q({0} centilitra),
						'name' => q(centilitre),
						'one' => q({0} centiliter),
						'other' => q({0} centilitrov),
					},
					'centimeter' => {
						'few' => q({0} centimetre),
						'many' => q({0} centimetra),
						'name' => q(centimetre),
						'one' => q({0} centimeter),
						'other' => q({0} centimetrov),
						'per' => q({0} na centimeter),
					},
					'century' => {
						'few' => q({0} storočia),
						'many' => q({0} storočia),
						'name' => q(storočia),
						'one' => q({0} storočie),
						'other' => q({0} storočí),
					},
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					'cubic-centimeter' => {
						'few' => q({0} kubické centimetre),
						'many' => q({0} kubického centimetra),
						'name' => q(kubické centimetre),
						'one' => q({0} kubický centimeter),
						'other' => q({0} kubických centimetrov),
						'per' => q({0} na kubický centimeter),
					},
					'cubic-foot' => {
						'few' => q({0} kubické stopy),
						'many' => q({0} kubickej stopy),
						'name' => q(kubické stopy),
						'one' => q({0} kubická stopa),
						'other' => q({0} kubických stôp),
					},
					'cubic-inch' => {
						'few' => q({0} kubické palce),
						'many' => q({0} kubického palca),
						'name' => q(kubické palce),
						'one' => q({0} kubický palec),
						'other' => q({0} kubických palcov),
					},
					'cubic-kilometer' => {
						'few' => q({0} kubické kilometre),
						'many' => q({0} kubického kilometra),
						'name' => q(kubické kilometre),
						'one' => q({0} kubický kilometer),
						'other' => q({0} kubických kilometrov),
					},
					'cubic-meter' => {
						'few' => q({0} kubické metre),
						'many' => q({0} kubického metra),
						'name' => q(kubické metre),
						'one' => q({0} kubický meter),
						'other' => q({0} kubických metrov),
						'per' => q({0} na kubický meter),
					},
					'cubic-mile' => {
						'few' => q({0} kubické míle),
						'many' => q({0} kubickej míle),
						'name' => q(kubické míle),
						'one' => q({0} kubická míľa),
						'other' => q({0} kubických míľ),
					},
					'cubic-yard' => {
						'few' => q({0} kubické yardy),
						'many' => q({0} kubického yardu),
						'name' => q(kubické yardy),
						'one' => q({0} kubický yard),
						'other' => q({0} kubických yardov),
					},
					'cup' => {
						'few' => q({0} hrnčeky),
						'many' => q({0} hrnčeka),
						'name' => q(hrnčeky),
						'one' => q({0} hrnček),
						'other' => q({0} hrnčekov),
					},
					'cup-metric' => {
						'few' => q({0} metrické hrnčeky),
						'many' => q({0} metrického hrnčeka),
						'name' => q(metrické hrnčeky),
						'one' => q({0} metrický hrnček),
						'other' => q({0} metrických hrnčekov),
					},
					'day' => {
						'few' => q({0} dni),
						'many' => q({0} dňa),
						'name' => q(dni),
						'one' => q({0} deň),
						'other' => q({0} dní),
						'per' => q({0} za deň),
					},
					'deciliter' => {
						'few' => q({0} decilitre),
						'many' => q({0} decilitra),
						'name' => q(decilitre),
						'one' => q({0} deciliter),
						'other' => q({0} decilitrov),
					},
					'decimeter' => {
						'few' => q({0} decimetre),
						'many' => q({0} decimetra),
						'name' => q(decimetre),
						'one' => q({0} decimeter),
						'other' => q({0} decimetrov),
					},
					'degree' => {
						'few' => q({0} stupne),
						'many' => q({0} stupňa),
						'name' => q(stupne),
						'one' => q({0} stupeň),
						'other' => q({0} stupňov),
					},
					'fahrenheit' => {
						'few' => q({0} stupne Fahrenheita),
						'many' => q({0} stupňa Fahrenheita),
						'name' => q(stupne Fahrenheita),
						'one' => q({0} stupeň Fahrenheita),
						'other' => q({0} stupňov Fahrenheita),
					},
					'fluid-ounce' => {
						'few' => q({0} tekuté unce),
						'many' => q({0} tekutej unce),
						'name' => q(tekuté unce),
						'one' => q({0} tekutá unca),
						'other' => q({0} tekutých uncí),
					},
					'foodcalorie' => {
						'few' => q({0} kalórie),
						'many' => q({0} kalórie),
						'name' => q(kalórie),
						'one' => q({0} kalória),
						'other' => q({0} kalórií),
					},
					'foot' => {
						'few' => q({0} stopy),
						'many' => q({0} stopy),
						'name' => q(stopy),
						'one' => q({0} stopa),
						'other' => q({0} stôp),
						'per' => q({0} na stopu),
					},
					'g-force' => {
						'few' => q({0} jednotky preťaženia),
						'many' => q({0} jednotky preťaženia),
						'name' => q(jednotky preťaženia),
						'one' => q({0} jednotka preťaženia),
						'other' => q({0} jednotiek preťaženia),
					},
					'gallon' => {
						'few' => q({0} galóny),
						'many' => q({0} galónu),
						'name' => q(galóny),
						'one' => q({0} galón),
						'other' => q({0} galónov),
						'per' => q({0} na galón),
					},
					'generic' => {
						'few' => q({0} °),
						'many' => q({0} °),
						'name' => q(°),
						'one' => q({0} °),
						'other' => q({0} °),
					},
					'gigabit' => {
						'few' => q({0} gigabity),
						'many' => q({0} gigabitu),
						'name' => q(gigabity),
						'one' => q({0} gigabit),
						'other' => q({0} gigabitov),
					},
					'gigabyte' => {
						'few' => q({0} gigabajty),
						'many' => q({0} gigabajtu),
						'name' => q(gigabajty),
						'one' => q({0} gigabajt),
						'other' => q({0} gigabajtov),
					},
					'gigahertz' => {
						'few' => q({0} gigahertze),
						'many' => q({0} gigahertza),
						'name' => q(gigahertze),
						'one' => q({0} gigahertz),
						'other' => q({0} gigahertzov),
					},
					'gigawatt' => {
						'few' => q({0} gigawatty),
						'many' => q({0} gigawattu),
						'name' => q(gigawatty),
						'one' => q({0} gigawatt),
						'other' => q({0} gigawattov),
					},
					'gram' => {
						'few' => q({0} gramy),
						'many' => q({0} gramu),
						'name' => q(gramy),
						'one' => q({0} gram),
						'other' => q({0} gramov),
						'per' => q({0} na gram),
					},
					'hectare' => {
						'few' => q({0} hektáre),
						'many' => q({0} hektára),
						'name' => q(hektáre),
						'one' => q({0} hektár),
						'other' => q({0} hektárov),
					},
					'hectoliter' => {
						'few' => q({0} hektolitre),
						'many' => q({0} hektolitra),
						'name' => q(hektolitre),
						'one' => q({0} hektoliter),
						'other' => q({0} hektolitrov),
					},
					'hectopascal' => {
						'few' => q({0} hektopascaly),
						'many' => q({0} hektopascala),
						'name' => q(hektopascaly),
						'one' => q({0} hektopascal),
						'other' => q({0} hektopascalov),
					},
					'hertz' => {
						'few' => q({0} hertze),
						'many' => q({0} hertza),
						'name' => q(hertze),
						'one' => q({0} hertz),
						'other' => q({0} hertzov),
					},
					'horsepower' => {
						'few' => q({0} konské sily),
						'many' => q({0} konskej sily),
						'name' => q(konské sily),
						'one' => q({0} konská sila),
						'other' => q({0} konských síl),
					},
					'hour' => {
						'few' => q({0} hodiny),
						'many' => q({0} hodiny),
						'name' => q(hodiny),
						'one' => q({0} hodina),
						'other' => q({0} hodín),
						'per' => q({0} za hodinu),
					},
					'inch' => {
						'few' => q({0} palce),
						'many' => q({0} palca),
						'name' => q(palce),
						'one' => q({0} palec),
						'other' => q({0} palcov),
						'per' => q({0} na palec),
					},
					'inch-hg' => {
						'few' => q({0} palce ortuťového stĺpca),
						'many' => q({0} palca ortuťového stĺpca),
						'name' => q(palce ortuťového stĺpca),
						'one' => q({0} palec ortuťového stĺpca),
						'other' => q({0} palcov ortuťového stĺpca),
					},
					'joule' => {
						'few' => q({0} jouly),
						'many' => q({0} joulu),
						'name' => q(jouly),
						'one' => q(joule),
						'other' => q({0} joulov),
					},
					'karat' => {
						'few' => q({0} karáty),
						'many' => q({0} karátu),
						'name' => q(karáty),
						'one' => q({0} karát),
						'other' => q({0} karátov),
					},
					'kelvin' => {
						'few' => q({0} kelviny),
						'many' => q({0} kelvina),
						'name' => q(kelviny),
						'one' => q({0} kelvin),
						'other' => q({0} kelvinov),
					},
					'kilobit' => {
						'few' => q({0} kilobity),
						'many' => q({0} kilobitu),
						'name' => q(kilobity),
						'one' => q({0} kilobit),
						'other' => q({0} kilobitov),
					},
					'kilobyte' => {
						'few' => q({0} kilobajty),
						'many' => q({0} kilobajtu),
						'name' => q(kilobajty),
						'one' => q({0} kilobajt),
						'other' => q({0} kilobajtov),
					},
					'kilocalorie' => {
						'few' => q({0} kilokalórie),
						'many' => q({0} kilokalórie),
						'name' => q(kilokalórie),
						'one' => q({0} kilokalória),
						'other' => q({0} kilokalórií),
					},
					'kilogram' => {
						'few' => q({0} kilogramy),
						'many' => q({0} kilogramu),
						'name' => q(kilogramy),
						'one' => q({0} kilogram),
						'other' => q({0} kilogramov),
						'per' => q({0} na kilogram),
					},
					'kilohertz' => {
						'few' => q({0} kilohertze),
						'many' => q({0} kilohertza),
						'name' => q(kilohertze),
						'one' => q({0} kilohertz),
						'other' => q({0} kilohertzov),
					},
					'kilojoule' => {
						'few' => q({0} kilojouly),
						'many' => q({0} kilojoulu),
						'name' => q(kilojouly),
						'one' => q({0} kilojoule),
						'other' => q({0} kilojoulov),
					},
					'kilometer' => {
						'few' => q({0} kilometre),
						'many' => q({0} kilometra),
						'name' => q(kilometre),
						'one' => q({0} kilometer),
						'other' => q({0} kilometrov),
						'per' => q({0} na kilometer),
					},
					'kilometer-per-hour' => {
						'few' => q({0} kilometre za hodinu),
						'many' => q({0} kilometra za hodinu),
						'name' => q(kilometre za hodinu),
						'one' => q({0} kilometer za hodinu),
						'other' => q({0} kilometrov za hodinu),
					},
					'kilowatt' => {
						'few' => q({0} kilowatty),
						'many' => q({0} kilowattu),
						'name' => q(kilowatty),
						'one' => q({0} kilowatt),
						'other' => q({0} kilowattov),
					},
					'kilowatt-hour' => {
						'few' => q({0} kilowatthodiny),
						'many' => q({0} kilowatthodiny),
						'name' => q(kilowatthodiny),
						'one' => q({0} kilowatthodina),
						'other' => q({0} kilowatthodín),
					},
					'knot' => {
						'few' => q({0} uzly),
						'many' => q({0} uzla),
						'name' => q(uzly),
						'one' => q({0} uzol),
						'other' => q({0} uzlov),
					},
					'light-year' => {
						'few' => q({0} svetelné roky),
						'many' => q({0} svetelného roku),
						'name' => q(svetelné roky),
						'one' => q({0} svetelný rok),
						'other' => q({0} svetelných rokov),
					},
					'liter' => {
						'few' => q({0} litre),
						'many' => q({0} litra),
						'name' => q(litre),
						'one' => q({0} liter),
						'other' => q({0} litrov),
						'per' => q({0} na liter),
					},
					'liter-per-100kilometers' => {
						'few' => q({0} litre na 100 kilometrov),
						'many' => q({0} litra na 100 kilometrov),
						'name' => q(litre na 100 kilometrov),
						'one' => q({0} liter na 100 kilometrov),
						'other' => q({0} litrov na 100 kilometrov),
					},
					'liter-per-kilometer' => {
						'few' => q({0} litre na kilometer),
						'many' => q({0} litra na kilometer),
						'name' => q(litre na kilometer),
						'one' => q({0} liter na kilometer),
						'other' => q({0} litrov na kilometer),
					},
					'lux' => {
						'few' => q({0} luxy),
						'many' => q({0} luxu),
						'name' => q(luxy),
						'one' => q({0} lux),
						'other' => q({0} luxov),
					},
					'megabit' => {
						'few' => q({0} megabity),
						'many' => q({0} megabitu),
						'name' => q(megabity),
						'one' => q({0} megabit),
						'other' => q({0} megabitov),
					},
					'megabyte' => {
						'few' => q({0} megabajty),
						'many' => q({0} megabajtu),
						'name' => q(megabajty),
						'one' => q({0} megabajt),
						'other' => q({0} megabajtov),
					},
					'megahertz' => {
						'few' => q({0} megahertze),
						'many' => q({0} megahertza),
						'name' => q(megahertze),
						'one' => q({0} megahertz),
						'other' => q({0} megahertzov),
					},
					'megaliter' => {
						'few' => q({0} megalitre),
						'many' => q({0} megalitra),
						'name' => q(megalitre),
						'one' => q({0} megaliter),
						'other' => q({0} megalitrov),
					},
					'megawatt' => {
						'few' => q({0} megawatty),
						'many' => q({0} megawattu),
						'name' => q(megawatty),
						'one' => q({0} megawatt),
						'other' => q({0} megawattov),
					},
					'meter' => {
						'few' => q({0} metre),
						'many' => q({0} metra),
						'name' => q(metre),
						'one' => q({0} meter),
						'other' => q({0} metrov),
						'per' => q({0} na meter),
					},
					'meter-per-second' => {
						'few' => q({0} metre za sekundu),
						'many' => q({0} metra za sekundu),
						'name' => q(metre za sekundu),
						'one' => q({0} meter za sekundu),
						'other' => q({0} metrov za sekundu),
					},
					'meter-per-second-squared' => {
						'few' => q({0} metre za sekundu na druhú),
						'many' => q({0} metra za sekundu na druhú),
						'name' => q(metre za sekundu na druhú),
						'one' => q({0} meter za sekundu na druhú),
						'other' => q({0} metrov za sekundu na druhú),
					},
					'metric-ton' => {
						'few' => q({0} tony),
						'many' => q({0} tony),
						'name' => q(tony),
						'one' => q({0} tona),
						'other' => q({0} ton),
					},
					'microgram' => {
						'few' => q({0} mikrogramy),
						'many' => q({0} mikrogramu),
						'name' => q(mikrogramy),
						'one' => q({0} mikrogram),
						'other' => q({0} mikrogramov),
					},
					'micrometer' => {
						'few' => q({0} mikrometre),
						'many' => q({0} mikrometra),
						'name' => q(mikrometre),
						'one' => q({0} mikrometer),
						'other' => q({0} mikrometrov),
					},
					'microsecond' => {
						'few' => q({0} mikrosekundy),
						'many' => q({0} mikrosekundy),
						'name' => q(mikrosekundy),
						'one' => q({0} mikrosekunda),
						'other' => q({0} mikrosekúnd),
					},
					'mile' => {
						'few' => q({0} míle),
						'many' => q({0} míle),
						'name' => q(míle),
						'one' => q({0} míľa),
						'other' => q({0} míľ),
					},
					'mile-per-gallon' => {
						'few' => q({0} míle na galón),
						'many' => q({0} míle na galón),
						'name' => q(míle na galón),
						'one' => q({0} míľa na galón),
						'other' => q({0} míľ na galón),
					},
					'mile-per-hour' => {
						'few' => q({0} míle za hodinu),
						'many' => q({0} míle za hodinu),
						'name' => q(míle za hodinu),
						'one' => q({0} míľa za hodinu),
						'other' => q({0} míľ za hodinu),
					},
					'mile-scandinavian' => {
						'few' => q({0} škandinávske míle),
						'many' => q({0} škandinávskej míle),
						'name' => q(škandinávske míle),
						'one' => q({0} škandinávska míľa),
						'other' => q({0} škandinávskych míľ),
					},
					'milliampere' => {
						'few' => q({0} miliampéry),
						'many' => q({0} miliampéra),
						'name' => q(miliampéry),
						'one' => q({0} miliampér),
						'other' => q({0} miliampérov),
					},
					'millibar' => {
						'few' => q({0} milibary),
						'many' => q({0} milibaru),
						'name' => q(milibary),
						'one' => q({0} milibar),
						'other' => q({0} milibarov),
					},
					'milligram' => {
						'few' => q({0} miligramy),
						'many' => q({0} miligramu),
						'name' => q(miligramy),
						'one' => q({0} miligram),
						'other' => q({0} miligramov),
					},
					'milliliter' => {
						'few' => q({0} mililitre),
						'many' => q({0} mililitra),
						'name' => q(mililitre),
						'one' => q({0} mililiter),
						'other' => q({0} mililitrov),
					},
					'millimeter' => {
						'few' => q({0} milimetre),
						'many' => q({0} milimetra),
						'name' => q(milimetre),
						'one' => q({0} milimeter),
						'other' => q({0} milimetrov),
					},
					'millimeter-of-mercury' => {
						'few' => q({0} milimetre ortuťového stĺpca),
						'many' => q({0} milimetra ortuťového stĺpca),
						'name' => q(milimetre ortuťového stĺpca),
						'one' => q({0} milimeter ortuťového stĺpca),
						'other' => q({0} milimetrov ortuťového stĺpca),
					},
					'millisecond' => {
						'few' => q({0} milisekundy),
						'many' => q({0} milisekundy),
						'name' => q(milisekundy),
						'one' => q({0} milisekunda),
						'other' => q({0} milisekúnd),
					},
					'milliwatt' => {
						'few' => q({0} milliwatty),
						'many' => q({0} milliwattu),
						'name' => q(milliwatty),
						'one' => q({0} milliwatt),
						'other' => q({0} milliwattov),
					},
					'minute' => {
						'few' => q({0} minúty),
						'many' => q({0} minúty),
						'name' => q(minúty),
						'one' => q({0} minúta),
						'other' => q({0} minút),
						'per' => q({0} za minútu),
					},
					'month' => {
						'few' => q({0} mesiace),
						'many' => q({0} mesiaca),
						'name' => q(mesiace),
						'one' => q({0} mesiac),
						'other' => q({0} mesiacov),
						'per' => q({0} za mesiac),
					},
					'nanometer' => {
						'few' => q({0} nanometre),
						'many' => q({0} nanometra),
						'name' => q(nanometre),
						'one' => q({0} nanometer),
						'other' => q({0} nanometrov),
					},
					'nanosecond' => {
						'few' => q({0} nanosekundy),
						'many' => q({0} nanosekundy),
						'name' => q(nanosekundy),
						'one' => q({0} nanosekunda),
						'other' => q({0} nanosekúnd),
					},
					'nautical-mile' => {
						'few' => q({0} námorné míle),
						'many' => q({0} námornej míle),
						'name' => q(námorné míle),
						'one' => q({0} námorná míľa),
						'other' => q({0} námorných míľ),
					},
					'ohm' => {
						'few' => q({0} ohmy),
						'many' => q({0} ohmu),
						'name' => q(ohmy),
						'one' => q({0} ohm),
						'other' => q({0} ohmov),
					},
					'ounce' => {
						'few' => q({0} unce),
						'many' => q({0} unce),
						'name' => q(unce),
						'one' => q({0} unca),
						'other' => q({0} uncí),
						'per' => q({0} na uncu),
					},
					'ounce-troy' => {
						'few' => q({0} trojské unce),
						'many' => q({0} trojskej unce),
						'name' => q(trojské unce),
						'one' => q({0} trojská unca),
						'other' => q({0} trojských uncí),
					},
					'parsec' => {
						'few' => q({0} parseky),
						'many' => q({0} parseku),
						'name' => q(parseky),
						'one' => q({0} parsek),
						'other' => q({0} parsekov),
					},
					'per' => {
						'1' => q({0} za {1}),
					},
					'picometer' => {
						'few' => q({0} pikometre),
						'many' => q({0} pikometra),
						'name' => q(pikometre),
						'one' => q({0} pikometer),
						'other' => q({0} pikometrov),
					},
					'pint' => {
						'few' => q({0} pinty),
						'many' => q({0} pinty),
						'name' => q(pinty),
						'one' => q({0} pinta),
						'other' => q({0} pínt),
					},
					'pint-metric' => {
						'few' => q({0} metrické pinty),
						'many' => q({0} metrickej pinty),
						'name' => q(metrické pinty),
						'one' => q({0} metrická pinta),
						'other' => q({0} metrických pínt),
					},
					'pound' => {
						'few' => q({0} libry),
						'many' => q({0} libry),
						'name' => q(libry),
						'one' => q({0} libra),
						'other' => q({0} libier),
						'per' => q({0} na libru),
					},
					'pound-per-square-inch' => {
						'few' => q({0} libry sily na štvorcový palec),
						'many' => q({0} libry sily na štvorcový palec),
						'name' => q(libry sily na štvorcový palec),
						'one' => q({0} libra sily na štvorcový palec),
						'other' => q({0} libier sily na štvorcový palec),
					},
					'quart' => {
						'few' => q({0} quarty),
						'many' => q({0} quartu),
						'name' => q(quarty),
						'one' => q({0} quart),
						'other' => q({0} quartov),
					},
					'radian' => {
						'few' => q({0} radiány),
						'many' => q({0} radiánu),
						'name' => q(radiány),
						'one' => q({0} radián),
						'other' => q({0} radiánov),
					},
					'revolution' => {
						'few' => q({0} otáčky),
						'many' => q({0} otáčky),
						'name' => q(otáčky),
						'one' => q({0} otáčka),
						'other' => q({0} otáčok),
					},
					'second' => {
						'few' => q({0} sekundy),
						'many' => q({0} sekundy),
						'name' => q(sekundy),
						'one' => q({0} sekunda),
						'other' => q({0} sekúnd),
						'per' => q({0} za sekundu),
					},
					'square-centimeter' => {
						'few' => q({0} štvorcové centimetre),
						'many' => q({0} štvorcového centimetra),
						'name' => q(štvorcové centimetre),
						'one' => q({0} štvorcový centimeter),
						'other' => q({0} štvorcových centimetrov),
						'per' => q({0} na štvorcový centimeter),
					},
					'square-foot' => {
						'few' => q({0} štvorcové stopy),
						'many' => q({0} štvorcovej stopy),
						'name' => q(štvorcové stopy),
						'one' => q({0} štvorcová stopa),
						'other' => q({0} štvorcových stôp),
					},
					'square-inch' => {
						'few' => q({0} štvorcové palce),
						'many' => q({0} štvorcového palca),
						'name' => q(štvorcové palce),
						'one' => q({0} štvorcový palec),
						'other' => q({0} štvorcových palcov),
						'per' => q({0} na štvorcový palec),
					},
					'square-kilometer' => {
						'few' => q({0} kilometre štvorcové),
						'many' => q({0} kilometra štvorcového),
						'name' => q(štvorcové kilometre),
						'one' => q({0} kilometer štvorcový),
						'other' => q({0} kilometrov štvorcových),
					},
					'square-meter' => {
						'few' => q({0} metre štvorcové),
						'many' => q({0} metra štvorcového),
						'name' => q(štvorcové metre),
						'one' => q({0} meter štvorcový),
						'other' => q({0} metrov štvorcových),
						'per' => q({0} na meter štvorcový),
					},
					'square-mile' => {
						'few' => q({0} míle štvorcové),
						'many' => q({0} míle štvorcovej),
						'name' => q(štvorcové míle),
						'one' => q({0} míľa štvorcová),
						'other' => q({0} míľ štvorcových),
					},
					'square-yard' => {
						'few' => q({0} štvorcové yardy),
						'many' => q({0} štvorcového yardu),
						'name' => q(štvorcové yardy),
						'one' => q({0} štvorcový yard),
						'other' => q({0} štvorcových yardov),
					},
					'tablespoon' => {
						'few' => q({0} polievkové lyžice),
						'many' => q({0} polievkovej lyžice),
						'name' => q(polievkové lyžice),
						'one' => q({0} polievková lyžica),
						'other' => q({0} polievkových lyžíc),
					},
					'teaspoon' => {
						'few' => q({0} čajové lyžice),
						'many' => q({0} čajovej lyžice),
						'name' => q(čajové lyžice),
						'one' => q({0} čajová lyžica),
						'other' => q({0} čajových lyžíc),
					},
					'terabit' => {
						'few' => q({0} terabity),
						'many' => q({0} terabitu),
						'name' => q(terabity),
						'one' => q({0} terabit),
						'other' => q({0} terabitov),
					},
					'terabyte' => {
						'few' => q({0} terabajty),
						'many' => q({0} terabajtu),
						'name' => q(terabajty),
						'one' => q({0} terabajt),
						'other' => q({0} terabajtov),
					},
					'ton' => {
						'few' => q({0} americké tony),
						'many' => q({0} americkej tony),
						'name' => q(americké tony),
						'one' => q({0} americká tona),
						'other' => q({0} amerických ton),
					},
					'volt' => {
						'few' => q({0} volty),
						'many' => q({0} voltu),
						'name' => q(volty),
						'one' => q({0} volt),
						'other' => q({0} voltov),
					},
					'watt' => {
						'few' => q({0} watty),
						'many' => q({0} wattu),
						'name' => q(watty),
						'one' => q({0} watt),
						'other' => q({0} wattov),
					},
					'week' => {
						'few' => q({0} týždne),
						'many' => q({0} týždňa),
						'name' => q(týždne),
						'one' => q({0} týždeň),
						'other' => q({0} týždňov),
						'per' => q({0} za týždeň),
					},
					'yard' => {
						'few' => q({0} yardy),
						'many' => q({0} yardu),
						'name' => q(yardy),
						'one' => q({0} yard),
						'other' => q({0} yardov),
					},
					'year' => {
						'few' => q({0} roky),
						'many' => q({0} roka),
						'name' => q(roky),
						'one' => q({0} rok),
						'other' => q({0} rokov),
						'per' => q({0} za rok),
					},
				},
				'narrow' => {
					'acre' => {
						'few' => q({0}ac),
						'many' => q({0}ac),
						'one' => q({0}ac),
						'other' => q({0}ac),
					},
					'acre-foot' => {
						'few' => q({0} ac ft),
						'many' => q({0} ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'arc-minute' => {
						'few' => q({0}′),
						'many' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'few' => q({0}″),
						'many' => q({0}″),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'few' => q({0} au),
						'many' => q({0} au),
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					'bit' => {
						'few' => q({0} b),
						'many' => q({0} b),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					'byte' => {
						'few' => q({0} B),
						'many' => q({0} B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					'carat' => {
						'few' => q({0} ct),
						'many' => q({0} ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					'celsius' => {
						'few' => q({0} °C),
						'many' => q({0} °C),
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centiliter' => {
						'few' => q({0} cl),
						'many' => q({0} cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					'centimeter' => {
						'few' => q({0} cm),
						'many' => q({0} cm),
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					'cubic-centimeter' => {
						'few' => q({0} cm³),
						'many' => q({0} cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
					},
					'cubic-foot' => {
						'few' => q({0} ft³),
						'many' => q({0} ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'few' => q({0} in³),
						'many' => q({0} in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'few' => q({0}km³),
						'many' => q({0}km³),
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					'cubic-meter' => {
						'few' => q({0} m³),
						'many' => q({0} m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
					},
					'cubic-mile' => {
						'few' => q({0}mi³),
						'many' => q({0}mi³),
						'one' => q({0}mi³),
						'other' => q({0}mi³),
					},
					'cubic-yard' => {
						'few' => q({0} yd³),
						'many' => q({0} yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'few' => q({0} c),
						'many' => q({0} c),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'day' => {
						'few' => q({0} d.),
						'many' => q({0} d.),
						'name' => q(d.),
						'one' => q({0} d.),
						'other' => q({0} d.),
					},
					'deciliter' => {
						'few' => q({0} dl),
						'many' => q({0} dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					'decimeter' => {
						'few' => q({0} dm),
						'many' => q({0} dm),
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'few' => q({0}°),
						'many' => q({0}°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'few' => q({0}°F),
						'many' => q({0}°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fluid-ounce' => {
						'few' => q({0} fl oz),
						'many' => q({0} fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foot' => {
						'few' => q({0}′),
						'many' => q({0}′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'g-force' => {
						'few' => q({0}G),
						'many' => q({0}G),
						'one' => q({0}G),
						'other' => q({0}G),
					},
					'gallon' => {
						'few' => q({0} gal),
						'many' => q({0} gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
					},
					'gram' => {
						'few' => q({0} g),
						'many' => q({0} g),
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					'hectare' => {
						'few' => q({0}ha),
						'many' => q({0}ha),
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					'hectoliter' => {
						'few' => q({0} hl),
						'many' => q({0} hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					'hectopascal' => {
						'few' => q({0}hPa),
						'many' => q({0}hPa),
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					'horsepower' => {
						'few' => q({0}hp),
						'many' => q({0}hp),
						'one' => q({0}hp),
						'other' => q({0}hp),
					},
					'hour' => {
						'few' => q({0} h),
						'many' => q({0} h),
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
					},
					'inch' => {
						'few' => q({0}in),
						'many' => q({0}in),
						'one' => q({0}in),
						'other' => q({0}in),
					},
					'inch-hg' => {
						'few' => q({0}" Hg),
						'many' => q({0}" Hg),
						'one' => q({0}" Hg),
						'other' => q({0}" Hg),
					},
					'karat' => {
						'few' => q({0} kt),
						'many' => q({0} kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'few' => q({0} K),
						'many' => q({0} K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilogram' => {
						'few' => q({0} kg),
						'many' => q({0} kg),
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					'kilometer' => {
						'few' => q({0} km),
						'many' => q({0} km),
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					'kilometer-per-hour' => {
						'few' => q({0} km/h),
						'many' => q({0} km/h),
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'few' => q({0}kW),
						'many' => q({0}kW),
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					'light-year' => {
						'few' => q({0}ly),
						'many' => q({0}ly),
						'one' => q({0}ly),
						'other' => q({0}ly),
					},
					'liter' => {
						'few' => q({0} l),
						'many' => q({0} l),
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					'liter-per-100kilometers' => {
						'few' => q({0} l/100 km),
						'many' => q({0} l/100 km),
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					'liter-per-kilometer' => {
						'few' => q({0} l/km),
						'many' => q({0} l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					'lux' => {
						'few' => q({0} lx),
						'many' => q({0} lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megaliter' => {
						'few' => q({0} Ml),
						'many' => q({0} Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					'megawatt' => {
						'few' => q({0} MW),
						'many' => q({0} MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'few' => q({0} m),
						'many' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'meter-per-second' => {
						'few' => q({0}m/s),
						'many' => q({0}m/s),
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					'meter-per-second-squared' => {
						'few' => q({0} m/s²),
						'many' => q({0} m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'few' => q({0} t),
						'many' => q({0} t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'microgram' => {
						'few' => q({0} µg),
						'many' => q({0} µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'few' => q({0} µm),
						'many' => q({0} µm),
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'few' => q({0} μs),
						'many' => q({0} μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'few' => q({0}mi),
						'many' => q({0}mi),
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					'mile-per-gallon' => {
						'few' => q({0} mpg),
						'many' => q({0} mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-hour' => {
						'few' => q({0}mph),
						'many' => q({0}mph),
						'one' => q({0}mph),
						'other' => q({0}mph),
					},
					'millibar' => {
						'few' => q({0}mb),
						'many' => q({0}mb),
						'one' => q({0}mb),
						'other' => q({0}mb),
					},
					'milligram' => {
						'few' => q({0} mg),
						'many' => q({0} mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milliliter' => {
						'few' => q({0} ml),
						'many' => q({0} ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					'millimeter' => {
						'few' => q({0} mm),
						'many' => q({0} mm),
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millisecond' => {
						'few' => q({0} ms),
						'many' => q({0} ms),
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'few' => q({0} mW),
						'many' => q({0} mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'few' => q({0} min),
						'many' => q({0} min),
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
					},
					'month' => {
						'few' => q({0} m.),
						'many' => q({0} m.),
						'name' => q(m.),
						'one' => q({0} m.),
						'other' => q({0} m.),
					},
					'nanometer' => {
						'few' => q({0} nm),
						'many' => q({0} nm),
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'few' => q({0} ns),
						'many' => q({0} ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'ounce' => {
						'few' => q({0}oz),
						'many' => q({0}oz),
						'one' => q({0}oz),
						'other' => q({0}oz),
					},
					'ounce-troy' => {
						'few' => q({0} oz t),
						'many' => q({0} oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'few' => q({0}pm),
						'many' => q({0}pm),
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					'pint' => {
						'few' => q({0} pt),
						'many' => q({0} pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'few' => q({0}lb),
						'many' => q({0}lb),
						'one' => q({0}lb),
						'other' => q({0}lb),
					},
					'quart' => {
						'few' => q({0} qt),
						'many' => q({0} qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'few' => q({0} rad),
						'many' => q({0} rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'second' => {
						'few' => q({0} s),
						'many' => q({0} s),
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
					},
					'square-centimeter' => {
						'few' => q({0} cm²),
						'many' => q({0} cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
					},
					'square-foot' => {
						'few' => q({0}ft²),
						'many' => q({0}ft²),
						'one' => q({0}ft²),
						'other' => q({0}ft²),
					},
					'square-inch' => {
						'few' => q({0} in²),
						'many' => q({0} in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
					},
					'square-kilometer' => {
						'few' => q({0} km²),
						'many' => q({0} km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					'square-meter' => {
						'few' => q({0} m²),
						'many' => q({0} m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					'square-mile' => {
						'few' => q({0}mi²),
						'many' => q({0}mi²),
						'one' => q({0}mi²),
						'other' => q({0}mi²),
					},
					'square-yard' => {
						'few' => q({0} yd²),
						'many' => q({0} yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'tablespoon' => {
						'few' => q({0} tbsp),
						'many' => q({0} tbsp),
						'one' => q({0} tbsp),
						'other' => q({0} tbsp),
					},
					'teaspoon' => {
						'few' => q({0} tsp),
						'many' => q({0} tsp),
						'one' => q({0} tsp),
						'other' => q({0} tsp),
					},
					'ton' => {
						'few' => q({0} to),
						'many' => q({0} to),
						'one' => q({0} to),
						'other' => q({0} to),
					},
					'watt' => {
						'few' => q({0}W),
						'many' => q({0}W),
						'one' => q({0}W),
						'other' => q({0}W),
					},
					'week' => {
						'few' => q({0} t.),
						'many' => q({0} t.),
						'name' => q(t.),
						'one' => q({0} t.),
						'other' => q({0} t.),
					},
					'yard' => {
						'few' => q({0}yd),
						'many' => q({0}yd),
						'one' => q({0}yd),
						'other' => q({0}yd),
					},
					'year' => {
						'few' => q({0} r.),
						'many' => q({0} r.),
						'name' => q(r.),
						'one' => q({0} r.),
						'other' => q({0} r.),
					},
				},
				'short' => {
					'acre' => {
						'few' => q({0} ac),
						'many' => q({0} ac),
						'name' => q(akre),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'few' => q({0} ac ft),
						'many' => q({0} ac ft),
						'name' => q(ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'few' => q({0} A),
						'many' => q({0} A),
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'few' => q({0}′),
						'many' => q({0}′),
						'name' => q(′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'few' => q({0}″),
						'many' => q({0}″),
						'name' => q(″),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'few' => q({0} au),
						'many' => q({0} au),
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					'bit' => {
						'few' => q({0} b),
						'many' => q({0} b),
						'name' => q(bit),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					'byte' => {
						'few' => q({0} B),
						'many' => q({0} B),
						'name' => q(bajt),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					'calorie' => {
						'few' => q({0} cal),
						'many' => q({0} cal),
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'few' => q({0} ct),
						'many' => q({0} ct),
						'name' => q(ct),
						'one' => q({0} ct),
						'other' => q({0} ct),
					},
					'celsius' => {
						'few' => q({0} °C),
						'many' => q({0} °C),
						'name' => q(°C),
						'one' => q({0} °C),
						'other' => q({0} °C),
					},
					'centiliter' => {
						'few' => q({0} cl),
						'many' => q({0} cl),
						'name' => q(cl),
						'one' => q({0} cl),
						'other' => q({0} cl),
					},
					'centimeter' => {
						'few' => q({0} cm),
						'many' => q({0} cm),
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
						'per' => q({0}/cm),
					},
					'century' => {
						'few' => q({0} stor.),
						'many' => q({0} stor.),
						'name' => q(stor.),
						'one' => q({0} stor.),
						'other' => q({0} stor.),
					},
					'coordinate' => {
						'east' => q({0} E),
						'north' => q({0} N),
						'south' => q({0} S),
						'west' => q({0} W),
					},
					'cubic-centimeter' => {
						'few' => q({0} cm³),
						'many' => q({0} cm³),
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
						'per' => q({0}/cm³),
					},
					'cubic-foot' => {
						'few' => q({0} ft³),
						'many' => q({0} ft³),
						'name' => q(ft³),
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'few' => q({0} in³),
						'many' => q({0} in³),
						'name' => q(in³),
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'few' => q({0} km³),
						'many' => q({0} km³),
						'name' => q(km³),
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'few' => q({0} m³),
						'many' => q({0} m³),
						'name' => q(m³),
						'one' => q({0} m³),
						'other' => q({0} m³),
						'per' => q({0}/m³),
					},
					'cubic-mile' => {
						'few' => q({0} mi³),
						'many' => q({0} mi³),
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'few' => q({0} yd³),
						'many' => q({0} yd³),
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'few' => q({0} c),
						'many' => q({0} c),
						'name' => q(c),
						'one' => q({0} c),
						'other' => q({0} c),
					},
					'cup-metric' => {
						'few' => q({0} mc),
						'many' => q({0} mc),
						'name' => q(mc),
						'one' => q({0} mc),
						'other' => q({0} mc),
					},
					'day' => {
						'few' => q({0} dni),
						'many' => q({0} dňa),
						'name' => q(dni),
						'one' => q({0} deň),
						'other' => q({0} dní),
						'per' => q({0}/deň),
					},
					'deciliter' => {
						'few' => q({0} dl),
						'many' => q({0} dl),
						'name' => q(dl),
						'one' => q({0} dl),
						'other' => q({0} dl),
					},
					'decimeter' => {
						'few' => q({0} dm),
						'many' => q({0} dm),
						'name' => q(dm),
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'few' => q({0}°),
						'many' => q({0}°),
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'few' => q({0} °F),
						'many' => q({0} °F),
						'name' => q(°F),
						'one' => q({0} °F),
						'other' => q({0} °F),
					},
					'fluid-ounce' => {
						'few' => q({0} fl oz),
						'many' => q({0} fl oz),
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'few' => q({0} cal),
						'many' => q({0} cal),
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'foot' => {
						'few' => q({0} ft),
						'many' => q({0} ft),
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
						'per' => q({0}/ft),
					},
					'g-force' => {
						'few' => q({0} G),
						'many' => q({0} G),
						'name' => q(jednotka preťaženia),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'few' => q({0} gal),
						'many' => q({0} gal),
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
						'per' => q({0}/gal),
					},
					'generic' => {
						'few' => q({0} °),
						'many' => q({0} °),
						'name' => q(°),
						'one' => q({0} °),
						'other' => q({0} °),
					},
					'gigabit' => {
						'few' => q({0} Gb),
						'many' => q({0} Gb),
						'name' => q(Gb),
						'one' => q({0} Gb),
						'other' => q({0} Gb),
					},
					'gigabyte' => {
						'few' => q({0} GB),
						'many' => q({0} GB),
						'name' => q(GB),
						'one' => q({0} GB),
						'other' => q({0} GB),
					},
					'gigahertz' => {
						'few' => q({0} GHz),
						'many' => q({0} GHz),
						'name' => q(GHz),
						'one' => q({0} GHz),
						'other' => q({0} GHz),
					},
					'gigawatt' => {
						'few' => q({0} GW),
						'many' => q({0} GW),
						'name' => q(GW),
						'one' => q({0} GW),
						'other' => q({0} GW),
					},
					'gram' => {
						'few' => q({0} g),
						'many' => q({0} g),
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
						'per' => q({0}/g),
					},
					'hectare' => {
						'few' => q({0} ha),
						'many' => q({0} ha),
						'name' => q(hektáre),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'few' => q({0} hl),
						'many' => q({0} hl),
						'name' => q(hl),
						'one' => q({0} hl),
						'other' => q({0} hl),
					},
					'hectopascal' => {
						'few' => q({0} hPa),
						'many' => q({0} hPa),
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'few' => q({0} Hz),
						'many' => q({0} Hz),
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'few' => q({0} hp),
						'many' => q({0} hp),
						'name' => q(hp),
						'one' => q({0} hp),
						'other' => q({0} hp),
					},
					'hour' => {
						'few' => q({0} h),
						'many' => q({0} h),
						'name' => q(h),
						'one' => q({0} h),
						'other' => q({0} h),
						'per' => q({0}/h),
					},
					'inch' => {
						'few' => q({0} in),
						'many' => q({0} in),
						'name' => q(in),
						'one' => q({0} in),
						'other' => q({0} in),
						'per' => q({0}/in),
					},
					'inch-hg' => {
						'few' => q({0} inHg),
						'many' => q({0} inHg),
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'few' => q({0} J),
						'many' => q({0} J),
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
					'karat' => {
						'few' => q({0} kt),
						'many' => q({0} kt),
						'name' => q(kt),
						'one' => q({0} kt),
						'other' => q({0} kt),
					},
					'kelvin' => {
						'few' => q({0} K),
						'many' => q({0} K),
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'few' => q({0} kb),
						'many' => q({0} kb),
						'name' => q(kb),
						'one' => q({0} kb),
						'other' => q({0} kb),
					},
					'kilobyte' => {
						'few' => q({0} kB),
						'many' => q({0} kB),
						'name' => q(kB),
						'one' => q({0} kB),
						'other' => q({0} kB),
					},
					'kilocalorie' => {
						'few' => q({0} kcal),
						'many' => q({0} kcal),
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'kilogram' => {
						'few' => q({0} kg),
						'many' => q({0} kg),
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
						'per' => q({0}/kg),
					},
					'kilohertz' => {
						'few' => q({0} kHz),
						'many' => q({0} kHz),
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'few' => q({0} kJ),
						'many' => q({0} kJ),
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'few' => q({0} km),
						'many' => q({0} km),
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
						'per' => q({0}/km),
					},
					'kilometer-per-hour' => {
						'few' => q({0} km/h),
						'many' => q({0} km/h),
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'few' => q({0} kW),
						'many' => q({0} kW),
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'few' => q({0} kWh),
						'many' => q({0} kWh),
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'knot' => {
						'few' => q({0} kn),
						'many' => q({0} kn),
						'name' => q(kn),
						'one' => q({0} kn),
						'other' => q({0} kn),
					},
					'light-year' => {
						'few' => q({0} ly),
						'many' => q({0} ly),
						'name' => q(ly),
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					'liter' => {
						'few' => q({0} l),
						'many' => q({0} l),
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
						'per' => q({0}/l),
					},
					'liter-per-100kilometers' => {
						'few' => q({0} l/100 km),
						'many' => q({0} l/100 km),
						'name' => q(l/100 km),
						'one' => q({0} l/100 km),
						'other' => q({0} l/100 km),
					},
					'liter-per-kilometer' => {
						'few' => q({0} l/km),
						'many' => q({0} l/km),
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
					},
					'lux' => {
						'few' => q({0} lx),
						'many' => q({0} lx),
						'name' => q(lx),
						'one' => q({0} lx),
						'other' => q({0} lx),
					},
					'megabit' => {
						'few' => q({0} Mb),
						'many' => q({0} Mb),
						'name' => q(Mb),
						'one' => q({0} Mb),
						'other' => q({0} Mb),
					},
					'megabyte' => {
						'few' => q({0} MB),
						'many' => q({0} MB),
						'name' => q(MB),
						'one' => q({0} MB),
						'other' => q({0} MB),
					},
					'megahertz' => {
						'few' => q({0} MHz),
						'many' => q({0} MHz),
						'name' => q(MHz),
						'one' => q({0} MHz),
						'other' => q({0} MHz),
					},
					'megaliter' => {
						'few' => q({0} Ml),
						'many' => q({0} Ml),
						'name' => q(Ml),
						'one' => q({0} Ml),
						'other' => q({0} Ml),
					},
					'megawatt' => {
						'few' => q({0} MW),
						'many' => q({0} MW),
						'name' => q(MW),
						'one' => q({0} MW),
						'other' => q({0} MW),
					},
					'meter' => {
						'few' => q({0} m),
						'many' => q({0} m),
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
						'per' => q({0}/m),
					},
					'meter-per-second' => {
						'few' => q({0} m/s),
						'many' => q({0} m/s),
						'name' => q(m/s),
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'few' => q({0} m/s²),
						'many' => q({0} m/s²),
						'name' => q(m/s²),
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'few' => q({0} t),
						'many' => q({0} t),
						'name' => q(t),
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'microgram' => {
						'few' => q({0} µg),
						'many' => q({0} µg),
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'few' => q({0} µm),
						'many' => q({0} µm),
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'few' => q({0} μs),
						'many' => q({0} μs),
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'few' => q({0} mi),
						'many' => q({0} mi),
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'few' => q({0} mpg),
						'many' => q({0} mpg),
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-hour' => {
						'few' => q({0} mi/h),
						'many' => q({0} mi/h),
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'mile-scandinavian' => {
						'few' => q({0} ŠM),
						'many' => q({0} ŠM),
						'name' => q(ŠM),
						'one' => q({0} ŠM),
						'other' => q({0} ŠM),
					},
					'milliampere' => {
						'few' => q({0} mA),
						'many' => q({0} mA),
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'few' => q({0} mbar),
						'many' => q({0} mbar),
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'milligram' => {
						'few' => q({0} mg),
						'many' => q({0} mg),
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milliliter' => {
						'few' => q({0} ml),
						'many' => q({0} ml),
						'name' => q(ml),
						'one' => q({0} ml),
						'other' => q({0} ml),
					},
					'millimeter' => {
						'few' => q({0} mm),
						'many' => q({0} mm),
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'few' => q({0} mm Hg),
						'many' => q({0} mm Hg),
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millisecond' => {
						'few' => q({0} ms),
						'many' => q({0} ms),
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'few' => q({0} mW),
						'many' => q({0} mW),
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'few' => q({0} min),
						'many' => q({0} min),
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
						'per' => q({0}/min),
					},
					'month' => {
						'few' => q({0} mes.),
						'many' => q({0} mes.),
						'name' => q(mes.),
						'one' => q({0} mes.),
						'other' => q({0} mes.),
						'per' => q({0}/mes.),
					},
					'nanometer' => {
						'few' => q({0} nm),
						'many' => q({0} nm),
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'few' => q({0} ns),
						'many' => q({0} ns),
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'few' => q({0} NM),
						'many' => q({0} NM),
						'name' => q(NM),
						'one' => q({0} NM),
						'other' => q({0} NM),
					},
					'ohm' => {
						'few' => q({0} Ω),
						'many' => q({0} Ω),
						'name' => q(Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'few' => q({0} oz),
						'many' => q({0} oz),
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
						'per' => q({0}/oz),
					},
					'ounce-troy' => {
						'few' => q({0} oz t),
						'many' => q({0} oz t),
						'name' => q(oz t),
						'one' => q({0} oz t),
						'other' => q({0} oz t),
					},
					'parsec' => {
						'few' => q({0} pc),
						'many' => q({0} pc),
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'per' => {
						'1' => q({0}/{1}),
					},
					'picometer' => {
						'few' => q({0} pm),
						'many' => q({0} pm),
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'few' => q({0} pt),
						'many' => q({0} pt),
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pint-metric' => {
						'few' => q({0} mpt),
						'many' => q({0} mpt),
						'name' => q(mpt),
						'one' => q({0} mpt),
						'other' => q({0} mpt),
					},
					'pound' => {
						'few' => q({0} lb),
						'many' => q({0} lb),
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
						'per' => q({0}/lb),
					},
					'pound-per-square-inch' => {
						'few' => q({0} psi),
						'many' => q({0} psi),
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'few' => q({0} qt),
						'many' => q({0} qt),
						'name' => q(qt),
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'radian' => {
						'few' => q({0} rad),
						'many' => q({0} rad),
						'name' => q(rad),
						'one' => q({0} rad),
						'other' => q({0} rad),
					},
					'revolution' => {
						'few' => q({0} ot.),
						'many' => q({0} ot.),
						'name' => q(ot.),
						'one' => q({0} ot.),
						'other' => q({0} ot.),
					},
					'second' => {
						'few' => q({0} s),
						'many' => q({0} s),
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
						'per' => q({0}/s),
					},
					'square-centimeter' => {
						'few' => q({0} cm²),
						'many' => q({0} cm²),
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
						'per' => q({0}/cm²),
					},
					'square-foot' => {
						'few' => q({0} ft²),
						'many' => q({0} ft²),
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'few' => q({0} in²),
						'many' => q({0} in²),
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
						'per' => q({0}/in²),
					},
					'square-kilometer' => {
						'few' => q({0} km²),
						'many' => q({0} km²),
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					'square-meter' => {
						'few' => q({0} m²),
						'many' => q({0} m²),
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
						'per' => q({0}/m²),
					},
					'square-mile' => {
						'few' => q({0} mi²),
						'many' => q({0} mi²),
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					'square-yard' => {
						'few' => q({0} yd²),
						'many' => q({0} yd²),
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'tablespoon' => {
						'few' => q({0} tbsp),
						'many' => q({0} tbsp),
						'name' => q(tbsp),
						'one' => q({0} tbsp),
						'other' => q({0} tbsp),
					},
					'teaspoon' => {
						'few' => q({0} tsp),
						'many' => q({0} tsp),
						'name' => q(tsp),
						'one' => q({0} tsp),
						'other' => q({0} tsp),
					},
					'terabit' => {
						'few' => q({0} Tb),
						'many' => q({0} Tb),
						'name' => q(Tb),
						'one' => q({0} Tb),
						'other' => q({0} Tb),
					},
					'terabyte' => {
						'few' => q({0} TB),
						'many' => q({0} TB),
						'name' => q(TB),
						'one' => q({0} TB),
						'other' => q({0} TB),
					},
					'ton' => {
						'few' => q({0} to),
						'many' => q({0} to),
						'name' => q(to),
						'one' => q({0} to),
						'other' => q({0} to),
					},
					'volt' => {
						'few' => q({0} V),
						'many' => q({0} V),
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'few' => q({0} W),
						'many' => q({0} W),
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'few' => q({0} týž.),
						'many' => q({0} týž.),
						'name' => q(týž.),
						'one' => q({0} týž.),
						'other' => q({0} týž.),
						'per' => q({0}/týž.),
					},
					'yard' => {
						'few' => q({0} yd),
						'many' => q({0} yd),
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'few' => q({0} r.),
						'many' => q({0} r.),
						'name' => q(r.),
						'one' => q({0} r.),
						'other' => q({0} r.),
						'per' => q({0}/r.),
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
			'group' => q( ),
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
					'few' => '0 tis'.'',
					'many' => '0 tis'.'',
					'one' => '0 tis'.'',
					'other' => '0 tis'.'',
				},
				'10000' => {
					'few' => '00 tis'.'',
					'many' => '00 tis'.'',
					'one' => '00 tis'.'',
					'other' => '00 tis'.'',
				},
				'100000' => {
					'few' => '000 tis'.'',
					'many' => '000 tis'.'',
					'one' => '000 tis'.'',
					'other' => '000 tis'.'',
				},
				'1000000' => {
					'few' => '0 mil'.'',
					'many' => '0 mil'.'',
					'one' => '0 mil'.'',
					'other' => '0 mil'.'',
				},
				'10000000' => {
					'few' => '00 mil'.'',
					'many' => '00 mil'.'',
					'one' => '00 mil'.'',
					'other' => '00 mil'.'',
				},
				'100000000' => {
					'few' => '000 mil'.'',
					'many' => '000 mil'.'',
					'one' => '000 mil'.'',
					'other' => '000 mil'.'',
				},
				'1000000000' => {
					'few' => '0 mld'.'',
					'many' => '0 mld'.'',
					'one' => '0 mld'.'',
					'other' => '0 mld'.'',
				},
				'10000000000' => {
					'few' => '00 mld'.'',
					'many' => '00 mld'.'',
					'one' => '00 mld'.'',
					'other' => '00 mld'.'',
				},
				'100000000000' => {
					'few' => '000 mld'.'',
					'many' => '000 mld'.'',
					'one' => '000 mld'.'',
					'other' => '000 mld'.'',
				},
				'1000000000000' => {
					'few' => '0 bil'.'',
					'many' => '0 bil'.'',
					'one' => '0 bil'.'',
					'other' => '0 bil'.'',
				},
				'10000000000000' => {
					'few' => '00 bil'.'',
					'many' => '00 bil'.'',
					'one' => '00 bil'.'',
					'other' => '00 bil'.'',
				},
				'100000000000000' => {
					'few' => '000 bil'.'',
					'many' => '000 bil'.'',
					'one' => '000 bil'.'',
					'other' => '000 bil'.'',
				},
				'standard' => {
					'' => '#,##0.###',
				},
			},
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
					'few' => '0 tis'.'',
					'many' => '0 tis'.'',
					'one' => '0 tis'.'',
					'other' => '0 tis'.'',
				},
				'10000' => {
					'few' => '00 tis'.'',
					'many' => '00 tis'.'',
					'one' => '00 tis'.'',
					'other' => '00 tis'.'',
				},
				'100000' => {
					'few' => '000 tis'.'',
					'many' => '000 tis'.'',
					'one' => '000 tis'.'',
					'other' => '000 tis'.'',
				},
				'1000000' => {
					'few' => '0 mil'.'',
					'many' => '0 mil'.'',
					'one' => '0 mil'.'',
					'other' => '0 mil'.'',
				},
				'10000000' => {
					'few' => '00 mil'.'',
					'many' => '00 mil'.'',
					'one' => '00 mil'.'',
					'other' => '00 mil'.'',
				},
				'100000000' => {
					'few' => '000 mil'.'',
					'many' => '000 mil'.'',
					'one' => '000 mil'.'',
					'other' => '000 mil'.'',
				},
				'1000000000' => {
					'few' => '0 mld'.'',
					'many' => '0 mld'.'',
					'one' => '0 mld'.'',
					'other' => '0 mld'.'',
				},
				'10000000000' => {
					'few' => '00 mld'.'',
					'many' => '00 mld'.'',
					'one' => '00 mld'.'',
					'other' => '00 mld'.'',
				},
				'100000000000' => {
					'few' => '000 mld'.'',
					'many' => '000 mld'.'',
					'one' => '000 mld'.'',
					'other' => '000 mld'.'',
				},
				'1000000000000' => {
					'few' => '0 bil'.'',
					'many' => '0 bil'.'',
					'one' => '0 bil'.'',
					'other' => '0 bil'.'',
				},
				'10000000000000' => {
					'few' => '00 bil'.'',
					'many' => '00 bil'.'',
					'one' => '00 bil'.'',
					'other' => '00 bil'.'',
				},
				'100000000000000' => {
					'few' => '000 bil'.'',
					'many' => '000 bil'.'',
					'one' => '000 bil'.'',
					'other' => '000 bil'.'',
				},
			},
		},
		percentFormat => {
			'default' => {
				'standard' => {
					'' => '#,##0 %',
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
				'currency' => q(andorská peseta),
			},
		},
		'AED' => {
			symbol => 'AED',
			display_name => {
				'currency' => q(SAE dirham),
				'few' => q(SAE dirhamy),
				'many' => q(SAE dirhamu),
				'one' => q(SAE dirham),
				'other' => q(SAE dirhamov),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(afganský afgání),
				'few' => q(afganské afgání),
				'many' => q(afganského afgání),
				'one' => q(afganský afgání),
				'other' => q(afganských afgání),
			},
		},
		'ALL' => {
			symbol => 'ALL',
			display_name => {
				'currency' => q(albánsky lek),
				'few' => q(albánske leky),
				'many' => q(albánskeho leku),
				'one' => q(albánsky lek),
				'other' => q(albánskych lekov),
			},
		},
		'AMD' => {
			symbol => 'AMD',
			display_name => {
				'currency' => q(arménsky dram),
				'few' => q(arménske dramy),
				'many' => q(arménskeho dramu),
				'one' => q(arménsky dram),
				'other' => q(arménskych dramov),
			},
		},
		'ANG' => {
			symbol => 'ANG',
			display_name => {
				'currency' => q(antilský gulden),
				'few' => q(antilské guldeny),
				'many' => q(antilského guldena),
				'one' => q(antilský gulden),
				'other' => q(antilských guldenov),
			},
		},
		'AOA' => {
			symbol => 'AOA',
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
				'currency' => q(angolská kwanza \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Angolská nová kwanza \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(angolská kwanza reajustado \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(argentínsky austral),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(argentínske peso \(1983 – 1985\)),
			},
		},
		'ARS' => {
			symbol => 'ARS',
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
			symbol => 'AWG',
			display_name => {
				'currency' => q(arubský gulden),
				'few' => q(arubské guldeny),
				'many' => q(arubského guldena),
				'one' => q(arubský gulden),
				'other' => q(arubských guldenov),
			},
		},
		'AZM' => {
			symbol => 'AZM',
			display_name => {
				'currency' => q(azerbajdžanský manat \(1993–2006\)),
				'few' => q(azerbajdžanské manaty \(1993–2006\)),
				'many' => q(azerbajdžanského manatu \(1993–2006\)),
				'one' => q(azerbajdžanský manat \(1993–2006\)),
				'other' => q(azerbajdžanských manatov \(1993–2006\)),
			},
		},
		'AZN' => {
			symbol => 'AZN',
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
				'currency' => q(bosniansko-hercegovinský dinár \(1992–1994\)),
			},
		},
		'BAM' => {
			symbol => 'BAM',
			display_name => {
				'currency' => q(konvertibilná marka),
				'few' => q(konvertibilné marky),
				'many' => q(konvertibilnej marky),
				'one' => q(konvertibilná marka),
				'other' => q(konvertibilných mariek),
			},
		},
		'BBD' => {
			symbol => 'BBD',
			display_name => {
				'currency' => q(barbadoský dolár),
				'few' => q(barbadoské doláre),
				'many' => q(barbadoského dolára),
				'one' => q(barbadoský dolár),
				'other' => q(barbadoských dolárov),
			},
		},
		'BDT' => {
			symbol => 'BDT',
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
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(belgický frank),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(belgický frank \(finančný\)),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(bulharský tvrdý lev),
			},
		},
		'BGN' => {
			symbol => 'BGN',
			display_name => {
				'currency' => q(bulharský lev),
				'few' => q(bulharské leva),
				'many' => q(bulharského leva),
				'one' => q(bulharský lev),
				'other' => q(bulharských leva),
			},
		},
		'BHD' => {
			symbol => 'BHD',
			display_name => {
				'currency' => q(bahrajnský dinár),
				'few' => q(bahrajnské dináre),
				'many' => q(bahrajnského dinára),
				'one' => q(bahrajnský dinár),
				'other' => q(bahrajnských dinárov),
			},
		},
		'BIF' => {
			symbol => 'BIF',
			display_name => {
				'currency' => q(burundský frank),
				'few' => q(burundské franky),
				'many' => q(burundského franku),
				'one' => q(burundský frank),
				'other' => q(burundských frankov),
			},
		},
		'BMD' => {
			symbol => 'BMD',
			display_name => {
				'currency' => q(bermudský dolár),
				'few' => q(bermudské doláre),
				'many' => q(bermudského dolára),
				'one' => q(bermudský dolár),
				'other' => q(bermudských dolárov),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(brunejský dolár),
				'few' => q(brunejské doláre),
				'many' => q(brunejského dolára),
				'one' => q(brunejský dolár),
				'other' => q(brunejských dolárov),
			},
		},
		'BOB' => {
			symbol => 'BOB',
			display_name => {
				'currency' => q(bolívijské boliviano),
				'few' => q(bolívijské boliviana),
				'many' => q(bolívijského boliviana),
				'one' => q(bolívijské boliviano),
				'other' => q(bolívijských bolivian),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(bolívijské peso),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(bolívijské MVDOL),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(brazílske cruzeiro novo \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(brazílske cruzado \(1986 – 1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(brazílske cruzeiro \(1990 – 1993\)),
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
				'currency' => q(Brazílske Cruzado Novo),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Brazílske cruzeiro),
			},
		},
		'BSD' => {
			symbol => 'BSD',
			display_name => {
				'currency' => q(bahamský dolár),
				'few' => q(bahamské doláre),
				'many' => q(bahamského dolára),
				'one' => q(bahamský dolár),
				'other' => q(bahamských dolárov),
			},
		},
		'BTN' => {
			symbol => 'BTN',
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
				'currency' => q(Burmese Kyat),
			},
		},
		'BWP' => {
			symbol => 'BWP',
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
				'currency' => q(Bieloruský nový rubeľ \(1994–1999\)),
				'few' => q(bieloruské nové ruble \(1994–1999\)),
				'many' => q(bieloruského nového rubľa \(1994–1999\)),
				'one' => q(bieloruský nový rubeľ \(1994–1999\)),
				'other' => q(bieloruských nových rubľov \(1994–1999\)),
			},
		},
		'BYR' => {
			symbol => 'BYR',
			display_name => {
				'currency' => q(bieloruský rubeľ),
				'few' => q(bieloruské ruble),
				'many' => q(bieloruského rubľa),
				'one' => q(bieloruský rubeľ),
				'other' => q(bieloruských rubľov),
			},
		},
		'BZD' => {
			symbol => 'BZD',
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
			symbol => 'CDF',
			display_name => {
				'currency' => q(konžský frank),
				'few' => q(konžské franky),
				'many' => q(konžského franku),
				'one' => q(konžský frank),
				'other' => q(konžských frankov),
			},
		},
		'CHF' => {
			symbol => 'CHF',
			display_name => {
				'currency' => q(švajčiarsky frank),
				'few' => q(švajčiarske franky),
				'many' => q(švajčiarskeho franku),
				'one' => q(švajčiarsky frank),
				'other' => q(švajčiarskych frankov),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Čílske Unidades de Fomento),
			},
		},
		'CLP' => {
			symbol => 'CLP',
			display_name => {
				'currency' => q(čilské peso),
				'few' => q(čilské pesos),
				'many' => q(čilského pesa),
				'one' => q(čilské peso),
				'other' => q(čilských pesos),
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
			symbol => 'COP',
			display_name => {
				'currency' => q(kolumbijské peso),
				'few' => q(kolumbijské pesos),
				'many' => q(kolumbijského pesa),
				'one' => q(kolumbijské peso),
				'other' => q(kolumbijských pesos),
			},
		},
		'CRC' => {
			symbol => 'CRC',
			display_name => {
				'currency' => q(kostarický colón),
				'few' => q(kostarické colóny),
				'many' => q(kostarického colóna),
				'one' => q(kostarický colón),
				'other' => q(kostarických colónov),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Československá koruna),
			},
		},
		'CUC' => {
			symbol => 'CUC',
			display_name => {
				'currency' => q(kubánske konvertibilné peso),
				'few' => q(kubánske konvertibilné pesos),
				'many' => q(kubánskeho konvertibilného pesa),
				'one' => q(kubánske konvertibilné peso),
				'other' => q(kubánskych konvertibilných pesos),
			},
		},
		'CUP' => {
			symbol => 'CUP',
			display_name => {
				'currency' => q(kubánske peso),
				'few' => q(kubánske pesos),
				'many' => q(kubánskeho pesa),
				'one' => q(kubánske peso),
				'other' => q(kubánskych pesos),
			},
		},
		'CVE' => {
			symbol => 'CVE',
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
				'currency' => q(Cypruská libra),
			},
		},
		'CZK' => {
			symbol => 'CZK',
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
				'currency' => q(Východonemecká marka),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Nemecká marka),
			},
		},
		'DJF' => {
			symbol => 'DJF',
			display_name => {
				'currency' => q(džibutský frank),
				'few' => q(džibutské franky),
				'many' => q(džibutského franku),
				'one' => q(džibutský frank),
				'other' => q(džibutských frankov),
			},
		},
		'DKK' => {
			symbol => 'DKK',
			display_name => {
				'currency' => q(dánska koruna),
				'few' => q(dánske koruny),
				'many' => q(dánskej koruny),
				'one' => q(dánska koruna),
				'other' => q(dánskych korún),
			},
		},
		'DOP' => {
			symbol => 'DOP',
			display_name => {
				'currency' => q(dominikánske peso),
				'few' => q(dominikánske pesos),
				'many' => q(dominikánskeho pesa),
				'one' => q(dominikánske peso),
				'other' => q(dominikánske pesos),
			},
		},
		'DZD' => {
			symbol => 'DZD',
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
				'currency' => q(Ekuadorský sucre),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Ekuadorský Unidad de Valor Constante \(UVC\)),
			},
		},
		'EEK' => {
			symbol => 'EEK',
			display_name => {
				'currency' => q(Estónska kroon),
				'few' => q(estónske kroony),
				'many' => q(estónskej kroony),
				'one' => q(estónska kroon),
				'other' => q(estónskych kroon),
			},
		},
		'EGP' => {
			symbol => 'EGP',
			display_name => {
				'currency' => q(egyptská libra),
				'few' => q(egyptské libry),
				'many' => q(egyptskej libry),
				'one' => q(egyptská libra),
				'other' => q(egyptských libier),
			},
		},
		'ERN' => {
			symbol => 'ERN',
			display_name => {
				'currency' => q(eritrejská nakfa),
				'few' => q(eritrejské nakfy),
				'many' => q(eritrejskej nakfy),
				'one' => q(eritrejská nakfa),
				'other' => q(eritrejských nakief),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Španielská peseta),
			},
		},
		'ETB' => {
			symbol => 'ETB',
			display_name => {
				'currency' => q(etiópsky birr),
				'few' => q(etiópske birry),
				'many' => q(etiópskeho birru),
				'one' => q(etiópsky birr),
				'other' => q(etiópskych birrov),
			},
		},
		'EUR' => {
			symbol => '€',
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
				'currency' => q(Finská marka),
			},
		},
		'FJD' => {
			symbol => 'FJD',
			display_name => {
				'currency' => q(fidžijský dolár),
				'few' => q(fidžijské doláre),
				'many' => q(fidžijského dolára),
				'one' => q(fidžijský dolár),
				'other' => q(fidžijských dolárov),
			},
		},
		'FKP' => {
			symbol => 'FKP',
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
				'currency' => q(Francúzsky frank),
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
				'currency' => q(Gruzínsky Kupon Larit),
			},
		},
		'GEL' => {
			symbol => 'GEL',
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
				'currency' => q(Ghanský cedi \(1979–2007\)),
				'few' => q(ghanské cedi \(1979–2007\)),
				'many' => q(ghanského cedi \(1979–2007\)),
				'one' => q(ghanský cedi \(1979–2007\)),
				'other' => q(ghanských cedi \(1979–2007\)),
			},
		},
		'GHS' => {
			symbol => 'GHS',
			display_name => {
				'currency' => q(ghanské cedi),
				'few' => q(ghanské cedi),
				'many' => q(ghanského cedi),
				'one' => q(ghanské cedi),
				'other' => q(ghanských cedi),
			},
		},
		'GIP' => {
			symbol => 'GIP',
			display_name => {
				'currency' => q(gibraltárska libra),
				'few' => q(gibraltárske libry),
				'many' => q(gibraltárskej libry),
				'one' => q(gibraltárska libra),
				'other' => q(gibraltárskych libier),
			},
		},
		'GMD' => {
			symbol => 'GMD',
			display_name => {
				'currency' => q(gambijské dalasi),
				'few' => q(gambijské dalasi),
				'many' => q(gambijského dalasi),
				'one' => q(gambijské dalasi),
				'other' => q(gambijských dalasi),
			},
		},
		'GNF' => {
			symbol => 'GNF',
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
				'currency' => q(Guinejský syli),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Rovníková Guinea Ekwele Guineana),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Grécka drachma),
			},
		},
		'GTQ' => {
			symbol => 'GTQ',
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
				'currency' => q(Portugalská Guinea eskudo),
			},
		},
		'GWP' => {
			symbol => 'GWP',
			display_name => {
				'currency' => q(Guinejsko-bissauské peso),
				'few' => q(Guinea-Bissau pesos),
				'many' => q(Guinea-Bissau pesa),
				'one' => q(Guinea-Bissau peso),
				'other' => q(Guinea-Bissau pesos),
			},
		},
		'GYD' => {
			symbol => 'GYD',
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
			symbol => 'HNL',
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
				'currency' => q(Chorvátsky dinár),
			},
		},
		'HRK' => {
			symbol => 'HRK',
			display_name => {
				'currency' => q(chorvátska kuna),
				'few' => q(chorvátske kuny),
				'many' => q(chorvátskej kuny),
				'one' => q(chorvátska kuna),
				'other' => q(chorvátskych kún),
			},
		},
		'HTG' => {
			symbol => 'HTG',
			display_name => {
				'currency' => q(haitské gourde),
				'few' => q(haitské gourde),
				'many' => q(haitského gourde),
				'one' => q(haitské gourde),
				'other' => q(haitských gourde),
			},
		},
		'HUF' => {
			symbol => 'HUF',
			display_name => {
				'currency' => q(maďarský forint),
				'few' => q(maďarské forinty),
				'many' => q(maďarského forinta),
				'one' => q(maďarský forint),
				'other' => q(maďarských forintov),
			},
		},
		'IDR' => {
			symbol => 'IDR',
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
				'currency' => q(Írska libra),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Izraelská libra),
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
			symbol => 'IQD',
			display_name => {
				'currency' => q(iracký dinár),
				'few' => q(iracké dináre),
				'many' => q(irackého dinára),
				'one' => q(iracký dinár),
				'other' => q(irackých dinárov),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(iránsky rial),
				'few' => q(iránske rialy),
				'many' => q(iránskeho rialu),
				'one' => q(iránsky rial),
				'other' => q(iránskych rialov),
			},
		},
		'ISK' => {
			symbol => 'ISK',
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
				'currency' => q(Talianská lira),
			},
		},
		'JMD' => {
			symbol => 'JMD',
			display_name => {
				'currency' => q(jamajský dolár),
				'few' => q(jamajské doláre),
				'many' => q(jamajského dolára),
				'one' => q(jamajský dolár),
				'other' => q(jamajských dolárov),
			},
		},
		'JOD' => {
			symbol => 'JOD',
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
			symbol => 'KES',
			display_name => {
				'currency' => q(kenský šiling),
				'few' => q(kenské šilingy),
				'many' => q(kenského šilingu),
				'one' => q(kenský šiling),
				'other' => q(kenských šilingov),
			},
		},
		'KGS' => {
			symbol => 'KGS',
			display_name => {
				'currency' => q(kirgizský som),
				'few' => q(kirgizské somy),
				'many' => q(kirgizského somu),
				'one' => q(kirgizský som),
				'other' => q(kirgizských somov),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(kambodžský riel),
				'few' => q(kambodžské riely),
				'many' => q(kambodžského rielu),
				'one' => q(kambodžský riel),
				'other' => q(kambodžských rielov),
			},
		},
		'KMF' => {
			symbol => 'KMF',
			display_name => {
				'currency' => q(komorský frank),
				'few' => q(komorské franky),
				'many' => q(komorského franku),
				'one' => q(komorský frank),
				'other' => q(komorských frankov),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(severokórejský won),
				'few' => q(severokórejské wony),
				'many' => q(severokórejskeho wonu),
				'one' => q(severokórejský won),
				'other' => q(severokórejských wonov),
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
			symbol => 'KWD',
			display_name => {
				'currency' => q(kuvajtský dinár),
				'few' => q(kuvajtské dináre),
				'many' => q(kuvajtského dinára),
				'one' => q(kuvajtský dinár),
				'other' => q(kuvajtských dinárov),
			},
		},
		'KYD' => {
			symbol => 'KYD',
			display_name => {
				'currency' => q(kajmanský dolár),
				'few' => q(kajmanské doláre),
				'many' => q(kajmanského dolára),
				'one' => q(kajmanský dolár),
				'other' => q(kajmanských dolárov),
			},
		},
		'KZT' => {
			symbol => 'KZT',
			display_name => {
				'currency' => q(kazašské tenge),
				'few' => q(kazašské tenge),
				'many' => q(kazašského tenge),
				'one' => q(kazašské tenge),
				'other' => q(kazašských tenge),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(laoský kip),
				'few' => q(laoské kipy),
				'many' => q(laoského kipu),
				'one' => q(laoský kip),
				'other' => q(laoských kipov),
			},
		},
		'LBP' => {
			symbol => 'LBP',
			display_name => {
				'currency' => q(libanonská libra),
				'few' => q(libanonské libry),
				'many' => q(libanonskej libry),
				'one' => q(libanonská libra),
				'other' => q(libanonských libier),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(srílanská rupia),
				'few' => q(srílanské rupie),
				'many' => q(srílanskej rupie),
				'one' => q(srílanská rupia),
				'other' => q(srílanských rupií),
			},
		},
		'LRD' => {
			symbol => 'LRD',
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
				'currency' => q(Lesothský loti),
			},
		},
		'LTL' => {
			symbol => 'LTL',
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
				'currency' => q(Litevský talonas),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Luxemburský frank),
			},
		},
		'LVL' => {
			symbol => 'LVL',
			display_name => {
				'currency' => q(Lotyšský lat),
				'few' => q(lotyšské laty),
				'many' => q(lotyšského latu),
				'one' => q(lotyšský lat),
				'other' => q(lotyšských latov),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Lotyšský rubeľ),
			},
		},
		'LYD' => {
			symbol => 'LYD',
			display_name => {
				'currency' => q(líbyjský dinár),
				'few' => q(líbyjské dináre),
				'many' => q(líbyjského dinára),
				'one' => q(líbyjský dinár),
				'other' => q(líbyjských dinárov),
			},
		},
		'MAD' => {
			symbol => 'MAD',
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
				'currency' => q(Marocký frank),
			},
		},
		'MDL' => {
			symbol => 'MDL',
			display_name => {
				'currency' => q(moldavský lei),
				'few' => q(moldavské lei),
				'many' => q(moldavského lei),
				'one' => q(moldavský lei),
				'other' => q(moldavských lei),
			},
		},
		'MGA' => {
			symbol => 'MGA',
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
				'currency' => q(Madagaskarský frank),
			},
		},
		'MKD' => {
			symbol => 'MKD',
			display_name => {
				'currency' => q(macedónsky denár),
				'few' => q(macedónske denáre),
				'many' => q(macedónskeho denára),
				'one' => q(macedónsky denár),
				'other' => q(macedónskych denárov),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Malský frank),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(mjanmarský kyat),
				'few' => q(mjanmarské kyaty),
				'many' => q(mjanmarského kyatu),
				'one' => q(mjanmarský kyat),
				'other' => q(mjanmarských kyatov),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(mongolský tugrik),
				'few' => q(mongolské tugriky),
				'many' => q(mongolského tugrika),
				'one' => q(mongolský tugrik),
				'other' => q(mongolských tugrikov),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(macajská pataca),
				'few' => q(macajské patacy),
				'many' => q(macajskej patacy),
				'one' => q(macajská pataca),
				'other' => q(macajských patác),
			},
		},
		'MRO' => {
			symbol => 'MRO',
			display_name => {
				'currency' => q(mauritánska ukija),
				'few' => q(mauritánske ukije),
				'many' => q(mauritánskej ukije),
				'one' => q(mauritánska ukija),
				'other' => q(mauritánskych ukijí),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Maltská lira),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Maltská libra),
			},
		},
		'MUR' => {
			symbol => 'MUR',
			display_name => {
				'currency' => q(maurícijská rupia),
				'few' => q(maurícijské rupie),
				'many' => q(maurícijskej rupie),
				'one' => q(maurícijská rupia),
				'other' => q(maurícijských rupií),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(maldivská rupia),
				'few' => q(maldivské rupie),
				'many' => q(maldivskej rupie),
				'one' => q(maldivská rupia),
				'other' => q(maldivských rupií),
			},
		},
		'MWK' => {
			symbol => 'MWK',
			display_name => {
				'currency' => q(malawijská kwacha),
				'few' => q(malawijské kwachy),
				'many' => q(malawijskej kwachy),
				'one' => q(malawijská kwacha),
				'other' => q(malawijských kwách),
			},
		},
		'MXN' => {
			symbol => 'MX$',
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
				'currency' => q(Mexické striborné peso \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Mexické Unidad de Inversion \(UDI\)),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(malajzijský ringgit),
				'few' => q(malajzijské ringgity),
				'many' => q(malajzijského ringgitu),
				'one' => q(malajzijský ringgit),
				'other' => q(malajzijských ringgitov),
			},
		},
		'MZE' => {
			symbol => 'MZE',
			display_name => {
				'currency' => q(Mozambické escudo),
				'few' => q(mozabické escudá),
				'many' => q(mozabického escuda),
				'one' => q(mozabické escudo),
				'other' => q(mozabických escúd),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mozambický metical \(1980–2006\)),
				'few' => q(mozambické meticaly \(1980–2006\)),
				'many' => q(mozambického meticalu \(1980–2006\)),
				'one' => q(mozambický metical \(1980–2006\)),
				'other' => q(mozambických meticalov \(1980–2006\)),
			},
		},
		'MZN' => {
			symbol => 'MZN',
			display_name => {
				'currency' => q(mozambický metical),
				'few' => q(mozambické meticaly),
				'many' => q(mozambického meticalu),
				'one' => q(mozambický metical),
				'other' => q(mozambických meticalov),
			},
		},
		'NAD' => {
			symbol => 'NAD',
			display_name => {
				'currency' => q(namíbijský dolár),
				'few' => q(namíbijské doláre),
				'many' => q(namíbijského dolára),
				'one' => q(namíbijský dolár),
				'other' => q(namíbijských dolárov),
			},
		},
		'NGN' => {
			symbol => 'NGN',
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
				'currency' => q(Nikaragujská Cordoba \(1988–1991\)),
				'few' => q(nikaragujské córdoby \(1988–1991\)),
				'many' => q(nikaragujskej córdoby \(1988–1991\)),
				'one' => q(nikaragujská córdoba \(1988–1991\)),
				'other' => q(nikaragujských córdob \(1988–1991\)),
			},
		},
		'NIO' => {
			symbol => 'NIO',
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
				'currency' => q(Nizozemský guilder),
			},
		},
		'NOK' => {
			symbol => 'NOK',
			display_name => {
				'currency' => q(nórska koruna),
				'few' => q(nórske koruny),
				'many' => q(nórskej koruny),
				'one' => q(nórska koruna),
				'other' => q(nórskych korún),
			},
		},
		'NPR' => {
			symbol => 'NPR',
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
			symbol => 'OMR',
			display_name => {
				'currency' => q(ománsky rial),
				'few' => q(ománske rialy),
				'many' => q(ománskeho rialu),
				'one' => q(ománsky rial),
				'other' => q(ománskych rialov),
			},
		},
		'PAB' => {
			symbol => 'PAB',
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
				'currency' => q(Peruvský inti),
			},
		},
		'PEN' => {
			symbol => 'PEN',
			display_name => {
				'currency' => q(peruánsky nový sol),
				'few' => q(peruánske nové soly),
				'many' => q(peruánskeho nového sola),
				'one' => q(peruánsky nový sol),
				'other' => q(peruánskych nových solov),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Peruvský sol),
			},
		},
		'PGK' => {
			symbol => 'PGK',
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
			symbol => 'PKR',
			display_name => {
				'currency' => q(pakistanská rupia),
				'few' => q(pakistanské rupie),
				'many' => q(pakistanskej rupie),
				'one' => q(pakistanská rupia),
				'other' => q(pakistanských rupií),
			},
		},
		'PLN' => {
			symbol => 'PLN',
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
				'currency' => q(Polský zloty \(1950–1995\)),
				'few' => q(poľské zloté \(1950–1995\)),
				'many' => q(poľského zlotého \(1950–1995\)),
				'one' => q(poľský zlotý \(1950–1995\)),
				'other' => q(poľských zlotých \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Portugalské eskudo),
			},
		},
		'PYG' => {
			symbol => 'PYG',
			display_name => {
				'currency' => q(paraguajské guaraní),
				'few' => q(paraguajské guaraní),
				'many' => q(paraguajského guaraní),
				'one' => q(paraguajské guaraní),
				'other' => q(paraguajských guaraní),
			},
		},
		'QAR' => {
			symbol => 'QAR',
			display_name => {
				'currency' => q(katarský rial),
				'few' => q(katarské rialy),
				'many' => q(katarského rialu),
				'one' => q(katarský rial),
				'other' => q(katarských rialov),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Rumunský leu \(1952–2006\)),
				'few' => q(rumunské leu \(1952–2006\)),
				'many' => q(rumunského leu \(1952–2006\)),
				'one' => q(rumunský leu \(1952–2006\)),
				'other' => q(rumunských leu \(1952–2006\)),
			},
		},
		'RON' => {
			symbol => 'RON',
			display_name => {
				'currency' => q(rumunský lei),
				'few' => q(rumunské lei),
				'many' => q(rumunského lei),
				'one' => q(rumunský lei),
				'other' => q(rumunských lei),
			},
		},
		'RSD' => {
			symbol => 'RSD',
			display_name => {
				'currency' => q(srbský dinár),
				'few' => q(srbské dináre),
				'many' => q(srbského dinára),
				'one' => q(srbský dinár),
				'other' => q(srbských dinárov),
			},
		},
		'RUB' => {
			symbol => 'RUB',
			display_name => {
				'currency' => q(ruský rubeľ),
				'few' => q(ruské ruble),
				'many' => q(ruského rubľa),
				'one' => q(ruský rubeľ),
				'other' => q(ruských rubľov),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Ruský rubeľ \(1991–1998\)),
			},
		},
		'RWF' => {
			symbol => 'RWF',
			display_name => {
				'currency' => q(rwandský frank),
				'few' => q(rwandské franky),
				'many' => q(rwandského franku),
				'one' => q(rwandský frank),
				'other' => q(rwandských frankov),
			},
		},
		'SAR' => {
			symbol => 'SAR',
			display_name => {
				'currency' => q(saudskoarabský rial),
				'few' => q(saudskoarabské rialy),
				'many' => q(saudskoarabského rialu),
				'one' => q(saudskoarabský rial),
				'other' => q(saudskoarabských rialov),
			},
		},
		'SBD' => {
			symbol => 'SBD',
			display_name => {
				'currency' => q(šalamúnsky dolár),
				'few' => q(šalamúnske doláre),
				'many' => q(šalamúnskeho dolára),
				'one' => q(šalamúnsky dolár),
				'other' => q(šalamúnskych dolárov),
			},
		},
		'SCR' => {
			symbol => 'SCR',
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
				'currency' => q(Sudánsky dinár),
			},
		},
		'SDG' => {
			symbol => 'SDG',
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
				'currency' => q(Sudánska libra \(1957–1998\)),
				'few' => q(sudánske libry \(1957–1998\)),
				'many' => q(sudánskej libry \(1957–1998\)),
				'one' => q(sudánska libra \(1957–1998\)),
				'other' => q(sudánskych libier \(1957–1998\)),
			},
		},
		'SEK' => {
			symbol => 'SEK',
			display_name => {
				'currency' => q(švédska koruna),
				'few' => q(švédske koruny),
				'many' => q(švédskej koruny),
				'one' => q(švédska koruna),
				'other' => q(švédskych korún),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(singapurský dolár),
				'few' => q(singapurské doláre),
				'many' => q(singapurského dolára),
				'one' => q(singapurský dolár),
				'other' => q(singapurských dolárov),
			},
		},
		'SHP' => {
			symbol => 'SHP',
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
				'currency' => q(Slovinský Tolar),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Slovenská koruna),
			},
		},
		'SLL' => {
			symbol => 'SLL',
			display_name => {
				'currency' => q(sierraleonský leone),
				'few' => q(sierraleonské leone),
				'many' => q(sierraleonského leone),
				'one' => q(sierraleonský leone),
				'other' => q(sierraleonských leone),
			},
		},
		'SOS' => {
			symbol => 'SOS',
			display_name => {
				'currency' => q(somálsky šiling),
				'few' => q(somálske šilingy),
				'many' => q(somálskeho šilingu),
				'one' => q(somálsky šiling),
				'other' => q(somálskych šilingov),
			},
		},
		'SRD' => {
			symbol => 'SRD',
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
				'currency' => q(Surinamský guilder),
			},
		},
		'SSP' => {
			symbol => 'SSP',
			display_name => {
				'currency' => q(juhosudánska libra),
				'few' => q(juhosudánske libry),
				'many' => q(juhosudánskej libry),
				'one' => q(juhosudánska libra),
				'other' => q(juhosudánskych libier),
			},
		},
		'STD' => {
			symbol => 'STD',
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
				'currency' => q(Sovietsky rubeľ),
			},
		},
		'SVC' => {
			symbol => 'SVC',
			display_name => {
				'currency' => q(Salvádorský colón),
				'few' => q(salvádorské colóny),
				'many' => q(salvádorského colóna),
				'one' => q(salvádorský colón),
				'other' => q(salvádorských colónov),
			},
		},
		'SYP' => {
			symbol => 'SYP',
			display_name => {
				'currency' => q(sýrska libra),
				'few' => q(sýrske libry),
				'many' => q(sýrskej libry),
				'one' => q(sýrska libra),
				'other' => q(sýrskych libier),
			},
		},
		'SZL' => {
			symbol => 'SZL',
			display_name => {
				'currency' => q(svazijské lilangeni),
				'few' => q(svazijské lilangeni),
				'many' => q(svazijského lilangeni),
				'one' => q(svazijské lilangeni),
				'other' => q(svazijských lilangeni),
			},
		},
		'THB' => {
			symbol => 'THB',
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
				'currency' => q(Tadžický rubeľ),
			},
		},
		'TJS' => {
			symbol => 'TJS',
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
				'currency' => q(Turkménsky manat \(1993–2009\)),
				'few' => q(turkménske manaty \(1993–2009\)),
				'many' => q(turkménskeho manatu \(1993–2009\)),
				'one' => q(turkménsky manat \(1993–2009\)),
				'other' => q(turkménskych manatov \(1993–2009\)),
			},
		},
		'TMT' => {
			symbol => 'TMT',
			display_name => {
				'currency' => q(turkménsky manat),
				'few' => q(turkménske manaty),
				'many' => q(turkménskeho manatu),
				'one' => q(turkménsky manat),
				'other' => q(turkménskych manatov),
			},
		},
		'TND' => {
			symbol => 'TND',
			display_name => {
				'currency' => q(tuniský dinár),
				'few' => q(tuniské dináre),
				'many' => q(tuniského dinára),
				'one' => q(tuniský dinár),
				'other' => q(tuniských dinárov),
			},
		},
		'TOP' => {
			symbol => 'TOP',
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
				'currency' => q(Timorské eskudo),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Turecká lira \(1922–2005\)),
				'few' => q(turecké líry \(1922–2005\)),
				'many' => q(tureckej líry \(1922–2005\)),
				'one' => q(turecká líra \(1922–2005\)),
				'other' => q(tureckých lír \(1922–2005\)),
			},
		},
		'TRY' => {
			symbol => 'TRY',
			display_name => {
				'currency' => q(turecká líra),
				'few' => q(turecké líry),
				'many' => q(tureckej líry),
				'one' => q(turecká líra),
				'other' => q(tureckých lír),
			},
		},
		'TTD' => {
			symbol => 'TTD',
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
			symbol => 'TZS',
			display_name => {
				'currency' => q(tanzánsky šiling),
				'few' => q(tanzánske šilingy),
				'many' => q(tanzánskeho šilingu),
				'one' => q(tanzánsky šiling),
				'other' => q(tanzánskych šilingov),
			},
		},
		'UAH' => {
			symbol => 'UAH',
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
				'currency' => q(Ukrainský karbovanetz),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Ugandan šiling \(1966–1987\)),
			},
		},
		'UGX' => {
			symbol => 'UGX',
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
				'currency' => q(US dolár \(Next day\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(US dolár \(Same day\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Uruguajské peso \(1975–1993\)),
			},
		},
		'UYU' => {
			symbol => 'UYU',
			display_name => {
				'currency' => q(uruguajské peso),
				'few' => q(uruguajské pesos),
				'many' => q(uruguajského pesa),
				'one' => q(uruguajské peso),
				'other' => q(uruguajských pesos),
			},
		},
		'UZS' => {
			symbol => 'UZS',
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
				'currency' => q(Venezuelský bolívar \(1871–2008\)),
			},
		},
		'VEF' => {
			symbol => 'VEF',
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
		'VUV' => {
			symbol => 'VUV',
			display_name => {
				'currency' => q(vanuatské vatu),
				'few' => q(vanuatské vatu),
				'many' => q(vanuatského vatu),
				'one' => q(vanuatské vatu),
				'other' => q(vanuatských vatu),
			},
		},
		'WST' => {
			symbol => 'WST',
			display_name => {
				'currency' => q(samojská tala),
				'few' => q(samojské taly),
				'many' => q(samojskej taly),
				'one' => q(samojská tala),
				'other' => q(samojských tál),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(stredoafrický frank),
				'few' => q(stredoafrické franky),
				'many' => q(stredoafrického franku),
				'one' => q(stredoafrický frank),
				'other' => q(stredoafrických frankov),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Zlato),
			},
		},
		'XCD' => {
			symbol => 'EC$',
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
				'currency' => q(Špeciálne práva čerpania),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Francúzsky zlatý frank),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Francúzsky UIC-frank),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(západoafrický frank),
				'few' => q(západoafrické franky),
				'many' => q(západoafrického franku),
				'one' => q(západoafrický frank),
				'other' => q(západoafrických frankov),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(CFP frank),
				'few' => q(CFP franky),
				'many' => q(CFP franku),
				'one' => q(CFP frank),
				'other' => q(CFP frankov),
			},
		},
		'XXX' => {
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
				'currency' => q(Jemenský dinár),
			},
		},
		'YER' => {
			symbol => 'YER',
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
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Juhoslávsky Noviy dinár),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Juhoslávsky dinár),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Juhoafrický rand \(financial\)),
			},
		},
		'ZAR' => {
			symbol => 'ZAR',
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
				'currency' => q(Zambijská kwacha \(1968–2012\)),
				'few' => q(zambijské kwachy \(1968–2012\)),
				'many' => q(zambijskej kwachy \(1968–2012\)),
				'one' => q(zambijská kwacha \(1968–2012\)),
				'other' => q(zambijských kwách \(1968–2012\)),
			},
		},
		'ZMW' => {
			symbol => 'ZMW',
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
				'currency' => q(Zairský nový zaire),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Zairský Zaire),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Zimbabwiansky dolár \(1980–2008\)),
				'few' => q(zimbabwianske doláre \(1980–2008\)),
				'many' => q(zimbabwianskeho dolára \(1980–2008\)),
				'one' => q(zimbabwiansky dolár \(1980–2008\)),
				'other' => q(zimbabwianskych dolárov \(1980–2008\)),
			},
		},
		'ZWL' => {
			symbol => 'ZWL',
			display_name => {
				'currency' => q(Zimbabwiansky dolár \(2009\)),
				'few' => q(zimbabwianske doláre \(2009\)),
				'many' => q(zimbabwianskeho dolára \(2009\)),
				'one' => q(zimbabwiansky dolár \(2009\)),
				'other' => q(zimbabwianskych dolárov \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Zimbabwiansky dolár \(2008\)),
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
					narrow => {
						mon => 'p',
						tue => 'u',
						wed => 's',
						thu => 'š',
						fri => 'p',
						sat => 's',
						sun => 'n'
					},
					short => {
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
					abbreviated => {
						mon => 'po',
						tue => 'ut',
						wed => 'st',
						thu => 'št',
						fri => 'pi',
						sat => 'so',
						sun => 'ne'
					},
					narrow => {
						mon => 'p',
						tue => 'u',
						wed => 's',
						thu => 'š',
						fri => 'p',
						sat => 's',
						sun => 'n'
					},
					short => {
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
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
					},
					wide => {0 => '1. štvrťrok',
						1 => '2. štvrťrok',
						2 => '3. štvrťrok',
						3 => '4. štvrťrok'
					},
				},
				'stand-alone' => {
					abbreviated => {0 => 'Q1',
						1 => 'Q2',
						2 => 'Q3',
						3 => 'Q4'
					},
					narrow => {0 => '1',
						1 => '2',
						2 => '3',
						3 => '4'
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
			if ($_ eq 'generic') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'morning2' if $time >= 900
						&& $time < 1200;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
				}
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'midnight' if $time == 0;
					return 'evening1' if $time >= 1800
						&& $time < 2200;
					return 'afternoon1' if $time >= 1200
						&& $time < 1800;
					return 'night1' if $time >= 2200;
					return 'night1' if $time < 400;
					return 'morning1' if $time >= 400
						&& $time < 900;
					return 'morning2' if $time >= 900
						&& $time < 1200;
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
				'narrow' => {
					'midnight' => q{o poln.},
					'noon' => q{nap.},
					'night1' => q{v n.},
					'morning1' => q{ráno},
					'morning2' => q{dop.},
					'evening1' => q{več.},
					'afternoon1' => q{pop.},
					'pm' => q{PM},
					'am' => q{AM},
				},
				'wide' => {
					'night1' => q{v noci},
					'noon' => q{napoludnie},
					'morning1' => q{ráno},
					'midnight' => q{o polnoci},
					'morning2' => q{dopoludnia},
					'pm' => q{PM},
					'am' => q{AM},
					'afternoon1' => q{popoludní},
					'evening1' => q{večer},
				},
				'abbreviated' => {
					'pm' => q{PM},
					'am' => q{AM},
					'afternoon1' => q{popol.},
					'evening1' => q{večer},
					'morning1' => q{ráno},
					'night1' => q{v noci},
					'noon' => q{napol.},
					'midnight' => q{o poln.},
					'morning2' => q{dopol.},
				},
			},
			'stand-alone' => {
				'abbreviated' => {
					'pm' => q{PM},
					'am' => q{AM},
					'afternoon1' => q{popol.},
					'evening1' => q{večer},
					'morning1' => q{ráno},
					'night1' => q{noc},
					'noon' => q{pol.},
					'midnight' => q{poln.},
					'morning2' => q{dopol.},
				},
				'narrow' => {
					'am' => q{AM},
					'pm' => q{PM},
					'afternoon1' => q{pop.},
					'evening1' => q{več.},
					'morning2' => q{dop.},
					'night1' => q{noc},
					'noon' => q{pol.},
					'morning1' => q{ráno},
					'midnight' => q{poln.},
				},
				'wide' => {
					'evening1' => q{večer},
					'afternoon1' => q{popoludnie},
					'pm' => q{PM},
					'am' => q{AM},
					'midnight' => q{polnoc},
					'night1' => q{noc},
					'noon' => q{poludnie},
					'morning1' => q{ráno},
					'morning2' => q{dopoludnie},
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
				'0' => 'pred Kr.',
				'1' => 'po Kr.'
			},
			wide => {
				'0' => 'pred Kristom',
				'1' => 'po Kristovi'
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
			'full' => q{EEEE, d. M. y G},
			'long' => q{d. M. y G},
			'medium' => q{d. M. y G},
			'short' => q{d.M.y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d. MMMM y},
			'long' => q{d. MMMM y},
			'medium' => q{d. M. y},
			'short' => q{d.M.yy},
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
			'full' => q{H:mm:ss zzzz},
			'long' => q{H:mm:ss z},
			'medium' => q{H:mm:ss},
			'short' => q{H:mm},
		},
	} },
);

has 'datetime_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
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
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'gregorian' => {
			E => q{ccc},
			EHm => q{E HH:mm},
			EHms => q{E HH:mm:ss},
			Ed => q{E d.},
			Ehm => q{E h:mm a},
			Ehms => q{E h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{LLLL y G},
			GyMMMEd => q{E, d. M. y G},
			GyMMMMd => q{d. M. y G},
			GyMMMd => q{d. M. y G},
			H => q{H},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			Hmsv => q{H:mm:ss v},
			Hmv => q{H:mm v},
			M => q{L.},
			MEd => q{E d. M.},
			MMM => q{LLL},
			MMMEd => q{E d. M.},
			MMMMEd => q{E d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. M.},
			Md => q{d. M.},
			d => q{d.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			hmsv => q{h:mm:ss a v},
			hmv => q{h:mm a v},
			mmss => q{mm:ss},
			ms => q{mm:ss},
			y => q{y},
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
		},
		'generic' => {
			E => q{ccc},
			Ed => q{E d.},
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
			MMM => q{LLL},
			MMMEd => q{E d. M.},
			MMMMEd => q{E d. MMMM},
			MMMMd => q{d. MMMM},
			MMMd => q{d. M.},
			Md => q{d. M.},
			d => q{d.},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			mmss => q{mm:ss},
			ms => q{mm:ss},
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
		'gregorian' => {
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{H:mm – H:mm},
				m => q{H:mm – H:mm},
			},
			Hmv => {
				H => q{H:mm – H:mm v},
				m => q{H:mm – H:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M. – M.},
			},
			MEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. – E d. M.},
			},
			MMMM => {
				M => q{LLLL – LLLL},
			},
			MMMd => {
				M => q{d. M. – d. M.},
				d => q{d. – d. M.},
			},
			Md => {
				M => q{d. M. – d. M.},
				d => q{d. M. – d. M.},
			},
			d => {
				d => q{d. – d.},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{y – y},
			},
			yM => {
				M => q{M/y – M/y},
				y => q{M/y – M/y},
			},
			yMEd => {
				M => q{E d. M. y – E d. M. y},
				d => q{E d. M. y – E d. M. y},
				y => q{E d. M. y – E d. M. y},
			},
			yMMM => {
				M => q{M – M/y},
				y => q{M/y – M/y},
			},
			yMMMEd => {
				M => q{E d. M. – E d. M. y},
				d => q{E d. – E d. M. y},
				y => q{E d. M. y – E d. M. y},
			},
			yMMMM => {
				M => q{LLLL – LLLL y},
				y => q{LLLL y – LLLL y},
			},
			yMMMd => {
				M => q{d. M. – d. M. y},
				d => q{d. – d. M. y},
				y => q{d. M. y – d. M. y},
			},
			yMd => {
				M => q{d. M. y – d. M. y},
				d => q{d. M. y – d. M. y},
				y => q{d. M. y – d. M. y},
			},
		},
		'generic' => {
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{H:mm – H:mm},
				m => q{H:mm – H:mm},
			},
			Hmv => {
				H => q{H:mm – H:mm v},
				m => q{H:mm – H:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M. – M.},
			},
			MEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. M. – E d. M.},
			},
			MMM => {
				M => q{LLL – LLL},
			},
			MMMEd => {
				M => q{E d. M. – E d. M.},
				d => q{E d. – E d. M.},
			},
			MMMM => {
				M => q{LLLL – LLLL},
			},
			MMMd => {
				M => q{d. M. – d. M.},
				d => q{d. – d. M.},
			},
			Md => {
				M => q{d. M. – d. M.},
				d => q{d. M. – d. M.},
			},
			d => {
				d => q{d. – d.},
			},
			fallback => '{0} – {1}',
			h => {
				a => q{h a – h a},
				h => q{h – h a},
			},
			hm => {
				a => q{h:mm a – h:mm a},
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				a => q{h:mm a – h:mm a v},
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
				a => q{h a – h a v},
				h => q{h – h a v},
			},
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E d. M. y – E d. M. y G},
				d => q{E d. M. y – E d. M. y G},
				y => q{E d. M. y – E d. M. y G},
			},
			yMMM => {
				M => q{LLL – LLL y G},
				y => q{LLL y – LLL y G},
			},
			yMMMEd => {
				M => q{E d. M. – E d. M. y G},
				d => q{E d. – E d. M. y G},
				y => q{E d. M. y – E d. M. y G},
			},
			yMMMM => {
				M => q{LLLL – LLLL y G},
				y => q{LLLL y – LLLL y G},
			},
			yMMMd => {
				M => q{d. M. – d. M. y G},
				d => q{d. – d. M. y G},
				y => q{d. M. y – d. M. y G},
			},
			yMd => {
				M => q{d. M. y – d. M. y G},
				d => q{d. M. y – d. M. y G},
				y => q{d. M. y – d. M. y G},
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
		regionFormat => q(časové pásmo {0}),
		regionFormat => q({0} (+1)),
		regionFormat => q({0} (+0)),
		fallbackFormat => q({1} ({0})),
		'Afghanistan' => {
			long => {
				'standard' => q(afganský čas),
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#Abidjan#,
		},
		'Africa/Accra' => {
			exemplarCity => q#Accra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alžír#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmara#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#Bamako#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#Bangui#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#Banjul#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#Bissau#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#Blantyre#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#Brazzaville#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#Bujumbura#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Káhira#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#Casablanca#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#Ceuta#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#Conakry#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#Dakar#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar es Salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Džibuti#,
		},
		'Africa/Douala' => {
			exemplarCity => q#Douala#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El-Aaiún#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#Freetown#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#Gaborone#,
		},
		'Africa/Harare' => {
			exemplarCity => q#Harare#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#Johannesburg#,
		},
		'Africa/Juba' => {
			exemplarCity => q#Juba#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#Kampala#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Chartúm#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#Kigali#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#Kinshasa#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#Lagos#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#Libreville#,
		},
		'Africa/Lome' => {
			exemplarCity => q#Lomé#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#Luanda#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#Lubumbashi#,
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
			exemplarCity => q#Mogadišo#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#Monrovia#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#Nairobi#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#N’Djamena#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#Niamey#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#Nouakchott#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Ouagadougou#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#Porto-Novo#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#Svätý Tomáš#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripolis#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#Tunis#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#Windhoek#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q(stredoafrický čas),
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q(východoafrický čas),
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q(juhoafrický čas),
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q(západoafrický letný čas),
				'generic' => q(západoafrický čas),
				'standard' => q(západoafrický štandardný čas),
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q(aljašský letný čas),
				'generic' => q(aljašský čas),
				'standard' => q(aljašský štandardný čas),
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q(amazonský letný čas),
				'generic' => q(amazonský čas),
				'standard' => q(amazonský štandardný čas),
			},
		},
		'America/Adak' => {
			exemplarCity => q#Adak#,
		},
		'America/Anchorage' => {
			exemplarCity => q#Anchorage#,
		},
		'America/Anguilla' => {
			exemplarCity => q#Anguilla#,
		},
		'America/Antigua' => {
			exemplarCity => q#Antigua#,
		},
		'America/Araguaina' => {
			exemplarCity => q#Araguaina#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#La Rioja#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#Rio Gallegos#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#Salta#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#San Juan#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#San Luis#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#Tucuman#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#Ushuaia#,
		},
		'America/Aruba' => {
			exemplarCity => q#Aruba#,
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Bahia' => {
			exemplarCity => q#Bahia#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#Bahia Banderas#,
		},
		'America/Barbados' => {
			exemplarCity => q#Barbados#,
		},
		'America/Belem' => {
			exemplarCity => q#Belém#,
		},
		'America/Belize' => {
			exemplarCity => q#Belize#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#Blanc-Sablon#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#Boa Vista#,
		},
		'America/Bogota' => {
			exemplarCity => q#Bogotá#,
		},
		'America/Boise' => {
			exemplarCity => q#Boise#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#Buenos Aires#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#Cambridge Bay#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#Campo Grande#,
		},
		'America/Cancun' => {
			exemplarCity => q#Cancún#,
		},
		'America/Caracas' => {
			exemplarCity => q#Caracas#,
		},
		'America/Catamarca' => {
			exemplarCity => q#Catamarca#,
		},
		'America/Cayenne' => {
			exemplarCity => q#Cayenne#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kajmanie ostrovy#,
		},
		'America/Chicago' => {
			exemplarCity => q#Chicago#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#Chihuahua#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikokan#,
		},
		'America/Cordoba' => {
			exemplarCity => q#Córdoba#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#Kostarika#,
		},
		'America/Creston' => {
			exemplarCity => q#Creston#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#Cuiabá#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#Danmarkshavn#,
		},
		'America/Dawson' => {
			exemplarCity => q#Dawson#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#Dawson Creek#,
		},
		'America/Denver' => {
			exemplarCity => q#Denver#,
		},
		'America/Detroit' => {
			exemplarCity => q#Detroit#,
		},
		'America/Dominica' => {
			exemplarCity => q#Dominika#,
		},
		'America/Edmonton' => {
			exemplarCity => q#Edmonton#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#Eirunepé#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvádor#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#Fortaleza#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#Glace Bay#,
		},
		'America/Godthab' => {
			exemplarCity => q#Nuuk#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#Goose Bay#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#Grand Turk#,
		},
		'America/Grenada' => {
			exemplarCity => q#Grenada#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#Guadeloupe#,
		},
		'America/Guatemala' => {
			exemplarCity => q#Guatemala#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#Guayaquil#,
		},
		'America/Guyana' => {
			exemplarCity => q#Guyana#,
		},
		'America/Halifax' => {
			exemplarCity => q#Halifax#,
		},
		'America/Havana' => {
			exemplarCity => q#Havana#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#Hermosillo#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#Knox, Indiana#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#Marengo, Indiana#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#Petersburg, Indiana#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#Tell City, Indiana#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#Vevay, Indiana#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#Vincennes, Indiana#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#Winamac, Indiana#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#Indianapolis#,
		},
		'America/Inuvik' => {
			exemplarCity => q#Inuvik#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#Iqaluit#,
		},
		'America/Jamaica' => {
			exemplarCity => q#Jamajka#,
		},
		'America/Jujuy' => {
			exemplarCity => q#Jujuy#,
		},
		'America/Juneau' => {
			exemplarCity => q#Juneau#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello, Kentucky#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#Kralendijk#,
		},
		'America/La_Paz' => {
			exemplarCity => q#La Paz#,
		},
		'America/Lima' => {
			exemplarCity => q#Lima#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#Los Angeles#,
		},
		'America/Louisville' => {
			exemplarCity => q#Louisville#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lower Prince’s Quarter#,
		},
		'America/Maceio' => {
			exemplarCity => q#Maceió#,
		},
		'America/Managua' => {
			exemplarCity => q#Managua#,
		},
		'America/Manaus' => {
			exemplarCity => q#Manaus#,
		},
		'America/Marigot' => {
			exemplarCity => q#Marigot#,
		},
		'America/Martinique' => {
			exemplarCity => q#Martinik#,
		},
		'America/Matamoros' => {
			exemplarCity => q#Matamoros#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#Mazatlán#,
		},
		'America/Mendoza' => {
			exemplarCity => q#Mendoza#,
		},
		'America/Menominee' => {
			exemplarCity => q#Menominee#,
		},
		'America/Merida' => {
			exemplarCity => q#Mérida#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#Metlakatla#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#México#,
		},
		'America/Miquelon' => {
			exemplarCity => q#Miquelon#,
		},
		'America/Moncton' => {
			exemplarCity => q#Moncton#,
		},
		'America/Monterrey' => {
			exemplarCity => q#Monterrey#,
		},
		'America/Montevideo' => {
			exemplarCity => q#Montevideo#,
		},
		'America/Montserrat' => {
			exemplarCity => q#Montserrat#,
		},
		'America/Nassau' => {
			exemplarCity => q#Nassau#,
		},
		'America/New_York' => {
			exemplarCity => q#New York#,
		},
		'America/Nipigon' => {
			exemplarCity => q#Nipigon#,
		},
		'America/Nome' => {
			exemplarCity => q#Nome#,
		},
		'America/Noronha' => {
			exemplarCity => q#Noronha#,
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
		'America/Ojinaga' => {
			exemplarCity => q#Ojinaga#,
		},
		'America/Panama' => {
			exemplarCity => q#Panama#,
		},
		'America/Pangnirtung' => {
			exemplarCity => q#Pangnirtung#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#Paramaribo#,
		},
		'America/Phoenix' => {
			exemplarCity => q#Phoenix#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#Port-au-Prince#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port of Spain#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#Porto Velho#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#Portoriko#,
		},
		'America/Rainy_River' => {
			exemplarCity => q#Rainy River#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#Rankin Inlet#,
		},
		'America/Recife' => {
			exemplarCity => q#Recife#,
		},
		'America/Regina' => {
			exemplarCity => q#Regina#,
		},
		'America/Resolute' => {
			exemplarCity => q#Resolute#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#Rio Branco#,
		},
		'America/Santa_Isabel' => {
			exemplarCity => q#Santa Isabel#,
		},
		'America/Santarem' => {
			exemplarCity => q#Santarém#,
		},
		'America/Santiago' => {
			exemplarCity => q#Santiago#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#Santo Domingo#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#São Paulo#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#Ittoqqortoormiit#,
		},
		'America/Sitka' => {
			exemplarCity => q#Sitka#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Svätý Bartolomej#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St. John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#St. Kitts#,
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
		'America/Swift_Current' => {
			exemplarCity => q#Swift Current#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#Tegucigalpa#,
		},
		'America/Thule' => {
			exemplarCity => q#Thule#,
		},
		'America/Thunder_Bay' => {
			exemplarCity => q#Thunder Bay#,
		},
		'America/Tijuana' => {
			exemplarCity => q#Tijuana#,
		},
		'America/Toronto' => {
			exemplarCity => q#Toronto#,
		},
		'America/Tortola' => {
			exemplarCity => q#Tortola#,
		},
		'America/Vancouver' => {
			exemplarCity => q#Vancouver#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#Whitehorse#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#Winnipeg#,
		},
		'America/Yakutat' => {
			exemplarCity => q#Yakutat#,
		},
		'America/Yellowknife' => {
			exemplarCity => q#Yellowknife#,
		},
		'America_Central' => {
			long => {
				'daylight' => q(severoamerický centrálny letný čas),
				'generic' => q(severoamerický centrálny čas),
				'standard' => q(severoamerický centrálny štandardný čas),
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q(severoamerický východný letný čas),
				'generic' => q(severoamerický východný čas),
				'standard' => q(severoamerický východný štandardný čas),
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q(severoamerický horský letný čas),
				'generic' => q(severoamerický horský čas),
				'standard' => q(severoamerický horský štandardný čas),
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q(severoamerický tichomorský letný čas),
				'generic' => q(severoamerický tichomorský čas),
				'standard' => q(severoamerický tichomorský štandardný čas),
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q(Anadyrský letný čas),
				'generic' => q(Anadyrský čas),
				'standard' => q(Anadyrský štandardný čas),
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#Casey#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#Davis#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont D’Urville#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#Macquarie#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#Mawson#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#McMurdo#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#Palmer#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#Rothera#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#Šówa#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#Troll#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Vostok#,
		},
		'Apia' => {
			long => {
				'daylight' => q(apijský letný čas),
				'generic' => q(apijský čas),
				'standard' => q(apijský štandardný čas),
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q(arabský letný čas),
				'generic' => q(arabský čas),
				'standard' => q(arabský štandardný čas),
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#Longyearbyen#,
		},
		'Argentina' => {
			long => {
				'daylight' => q(argentínsky letný čas),
				'generic' => q(argentínsky čas),
				'standard' => q(argentínsky štandardný čas),
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q(západoargentínsky letný čas),
				'generic' => q(západoargentínsky čas),
				'standard' => q(západoargentínsky štandardný čas),
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q(arménsky letný čas),
				'generic' => q(arménsky čas),
				'standard' => q(arménsky štandardný čas),
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#Aden#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#Almaty#,
		},
		'Asia/Amman' => {
			exemplarCity => q#Ammán#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#Anadyr#,
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
		'Asia/Baku' => {
			exemplarCity => q#Baku#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#Bangkok#,
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
		'Asia/Dili' => {
			exemplarCity => q#Dili#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#Dubaj#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Dušanbe#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#Gaza#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#Hebron#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hongkong#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#Chovd#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#Irkutsk#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#Jakarta#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Jayapura#,
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
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#Kuala Lumpur#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#Kučing#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#Kuvajt#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macao#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#Magadan#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#Makassar#,
		},
		'Asia/Manila' => {
			exemplarCity => q#Manila#,
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
		'Asia/Novosibirsk' => {
			exemplarCity => q#Novosibirsk#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#Omsk#,
		},
		'Asia/Oral' => {
			exemplarCity => q#Uraľsk#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#Phnom Pénh#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#Pontianak#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pchjongjang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
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
		'Asia/Samarkand' => {
			exemplarCity => q#Samarkand#,
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
		'Asia/Srednekolymsk' => {
			exemplarCity => q#Srednekolymsk#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Tchaj-pej#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taškent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tbilisi#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teherán#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#Thimphu#,
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
		'Asia/Vladivostok' => {
			exemplarCity => q#Vladivostok#,
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
				'daylight' => q(atlantický letný čas),
				'generic' => q(atlantický čas),
				'standard' => q(atlantický štandardný čas),
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
		'Atlantic/Madeira' => {
			exemplarCity => q#Madeira#,
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
		'Atlantic/Stanley' => {
			exemplarCity => q#Stanley#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#Adelaide#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#Brisbane#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#Broken Hill#,
		},
		'Australia/Currie' => {
			exemplarCity => q#Currie#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#Darwin#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#Eucla#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#Hobart#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#Lindeman#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#Lord Howe#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#Melbourne#,
		},
		'Australia/Perth' => {
			exemplarCity => q#Perth#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#Sydney#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q(stredoaustrálsky letný čas),
				'generic' => q(stredoaustrálsky čas),
				'standard' => q(stredoaustrálsky štandardný čas),
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q(stredozápadný austrálsky letný čas),
				'generic' => q(stredozápadný austrálsky čas),
				'standard' => q(stredozápadný austrálsky štandardný čas),
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q(východoaustrálsky letný čas),
				'generic' => q(východoaustrálsky čas),
				'standard' => q(východoaustrálsky štandardný čas),
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q(západoaustrálsky letný čas),
				'generic' => q(západoaustrálsky čas),
				'standard' => q(západoaustrálsky štandardný čas),
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q(azerbajdžanský letný čas),
				'generic' => q(azerbajdžanský čas),
				'standard' => q(azerbajdžanský štandardný čas),
			},
		},
		'Azores' => {
			long => {
				'daylight' => q(azorský letný čas),
				'generic' => q(azorský čas),
				'standard' => q(azorský štandardný čas),
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q(bangladéšsky letný čas),
				'generic' => q(bangladéšsky čas),
				'standard' => q(bangladéšsky štandardný čas),
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q(bhutánsky čas),
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q(bolívijský čas),
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q(brazílsky letný čas),
				'generic' => q(brazílsky čas),
				'standard' => q(brazílsky štandardný čas),
			},
		},
		'Brunei' => {
			long => {
				'standard' => q(brunejský čas),
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q(kapverdský letný čas),
				'generic' => q(kapverdský čas),
				'standard' => q(kapverdský štandardný čas),
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q(chamorrský štandardný čas),
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q(chathamský letný čas),
				'generic' => q(chathamský čas),
				'standard' => q(chathamský štandardný čas),
			},
		},
		'Chile' => {
			long => {
				'daylight' => q(čilský letný čas),
				'generic' => q(čilský čas),
				'standard' => q(čilský štandardný čas),
			},
		},
		'China' => {
			long => {
				'daylight' => q(čínsky letný čas),
				'generic' => q(čínsky čas),
				'standard' => q(čínsky štandardný čas),
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q(čojbalsanský letný čas),
				'generic' => q(čojbalsanský čas),
				'standard' => q(čojbalsanský štandardný čas),
			},
		},
		'Christmas' => {
			long => {
				'standard' => q(čas Vianočného ostrova),
			},
		},
		'Cocos' => {
			long => {
				'standard' => q(čas Kokosových ostrovov),
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q(kolumbijský letný čas),
				'generic' => q(kolumbijský čas),
				'standard' => q(kolumbijský štandardný čas),
			},
		},
		'Cook' => {
			long => {
				'daylight' => q(letný čas Cookových ostrovov),
				'generic' => q(čas Cookových ostrovov),
				'standard' => q(štandardný čas Cookových ostrovov),
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q(kubánsky letný čas),
				'generic' => q(kubánsky čas),
				'standard' => q(kubánsky štandardný čas),
			},
		},
		'Davis' => {
			long => {
				'standard' => q(čas Davisovej stanice),
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q(čas stanice Dumonta d’Urvillea),
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q(východotimorský čas),
			},
		},
		'Easter' => {
			long => {
				'daylight' => q(letný čas Veľkonočného ostrova),
				'generic' => q(čas Veľkonočného ostrova),
				'standard' => q(štandardný čas Veľkonočného ostrova),
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q(ekvádorský čas),
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#neznáme mesto#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#Amsterdam#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#Andorra#,
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
		'Europe/Bratislava' => {
			exemplarCity => q#Bratislava#,
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
			exemplarCity => q#Dublin#,
			long => {
				'daylight' => q(írsky štandardný čas),
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#Gibraltár#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#Guernsey#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#Helsinki#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#Ostrov Man#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#Istanbul#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#Jersey#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#Kaliningrad#,
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
				'daylight' => q(britský letný čas),
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Luxembursko#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#Madrid#,
		},
		'Europe/Malta' => {
			exemplarCity => q#Malta#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#Mariehamn#,
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
			exemplarCity => q#Paríž#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#Podgorica#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Praha#,
		},
		'Europe/Riga' => {
			exemplarCity => q#Riga#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Rím#,
		},
		'Europe/Samara' => {
			exemplarCity => q#Samara#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#San Maríno#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#Sarajevo#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#Simferopol#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#Skopje#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#Sofia#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#Štokholm#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#Tallinn#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Užhorod#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#Vaduz#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikán#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Viedeň#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Vilnius#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Volgograd#,
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
				'daylight' => q(stredoeurópsky letný čas),
				'generic' => q(stredoeurópsky čas),
				'standard' => q(stredoeurópsky štandardný čas),
			},
			short => {
				'daylight' => q(SELČ),
				'generic' => q(SEČ),
				'standard' => q(SEČ),
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q(východoeurópsky letný čas),
				'generic' => q(východoeurópsky čas),
				'standard' => q(východoeurópsky štandardný čas),
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q(minský čas),
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q(západoeurópsky letný čas),
				'generic' => q(západoeurópsky čas),
				'standard' => q(západoeurópsky štandardný čas),
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q(falklandský letný čas),
				'generic' => q(falklandský čas),
				'standard' => q(falklandský štandardný čas),
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q(fidžijský letný čas),
				'generic' => q(fidžijský čas),
				'standard' => q(fidžijský štandardný čas),
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q(francúzskoguyanský čas),
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q(čas Francúzskych južných a antarktických území),
			},
		},
		'GMT' => {
			long => {
				'standard' => q(greenwichský čas),
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q(galapágsky čas),
			},
		},
		'Gambier' => {
			long => {
				'standard' => q(gambierský čas),
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q(gruzínsky letný čas),
				'generic' => q(gruzínsky čas),
				'standard' => q(gruzínsky štandardný čas),
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q(čas Gilbertových ostrovov),
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q(východogrónsky letný čas),
				'generic' => q(východogrónsky čas),
				'standard' => q(východogrónsky štandardný čas),
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q(západogrónsky letný čas),
				'generic' => q(západogrónsky čas),
				'standard' => q(západogrónsky štandardný čas),
			},
		},
		'Gulf' => {
			long => {
				'standard' => q(štandardný čas Perzského zálivu),
			},
		},
		'Guyana' => {
			long => {
				'standard' => q(guyanský čas),
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q(havajsko-aleutský letný čas),
				'generic' => q(havajsko-aleutský čas),
				'standard' => q(havajsko-aleutský štandardný čas),
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q(hongkonský letný čas),
				'generic' => q(hongkonský čas),
				'standard' => q(hongkonský štandardný čas),
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q(chovdský letný čas),
				'generic' => q(chovdský čas),
				'standard' => q(chovdský štandardný čas),
			},
		},
		'India' => {
			long => {
				'standard' => q(indický čas),
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#Antananarivo#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#Chagos#,
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
		'Indian/Mayotte' => {
			exemplarCity => q#Mayotte#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q(indickooceánsky čas),
			},
		},
		'Indochina' => {
			long => {
				'standard' => q(indočínsky čas),
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q(stredoindonézsky čas),
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q(východoindonézsky čas),
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q(západoindonézsky čas),
			},
		},
		'Iran' => {
			long => {
				'daylight' => q(iránsky letný čas),
				'generic' => q(iránsky čas),
				'standard' => q(iránsky štandardný čas),
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q(irkutský letný čas),
				'generic' => q(irkutský čas),
				'standard' => q(irkutský štandardný čas),
			},
		},
		'Israel' => {
			long => {
				'daylight' => q(izraelský letný čas),
				'generic' => q(izraelský čas),
				'standard' => q(izraelský štandardný čas),
			},
		},
		'Japan' => {
			long => {
				'daylight' => q(japonský letný čas),
				'generic' => q(japonský čas),
				'standard' => q(japonský štandardný čas),
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q(Petropavlovsk-Kamčatskijský letný čas),
				'generic' => q(Petropavlovsk-Kamčatský čas),
				'standard' => q(Petropavlovsk-Kamčatský štandardný čas),
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q(východokazachstanský čas),
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q(západokazachstanský čas),
			},
		},
		'Korea' => {
			long => {
				'daylight' => q(kórejský letný čas),
				'generic' => q(kórejský čas),
				'standard' => q(kórejský štandardný čas),
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q(kosrajský čas),
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q(krasnojarský letný čas),
				'generic' => q(krasnojarský čas),
				'standard' => q(krasnojarský štandardný čas),
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q(kirgizský čas),
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q(čas Rovníkových ostrovov),
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q(letný čas ostrova lorda Howa),
				'generic' => q(čas ostrova lorda Howa),
				'standard' => q(štandardný čas ostrova lorda Howa),
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q(čas ostrova Macquarie),
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q(magadanský letný čas),
				'generic' => q(magadanský čas),
				'standard' => q(magadanský štandardný čas),
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q(malajzijský čas),
			},
		},
		'Maldives' => {
			long => {
				'standard' => q(maldivský čas),
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q(markézsky čas),
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q(čas Marshallových ostrovov),
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q(maurícijský letný čas),
				'generic' => q(maurícijský čas),
				'standard' => q(maurícijský štandardný čas),
			},
		},
		'Mawson' => {
			long => {
				'standard' => q(čas Mawsonovej stanice),
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q(severozápadný mexický letný čas),
				'generic' => q(severozápadný mexický čas),
				'standard' => q(severozápadný mexický štandardný čas),
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q(mexický tichomorský letný čas),
				'generic' => q(mexický tichomorský čas),
				'standard' => q(mexický tichomorský štandardný čas),
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q(ulanbátarský letný čas),
				'generic' => q(ulanbátarský čas),
				'standard' => q(ulanbátarský štandardný čas),
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q(moskovský letný čas),
				'generic' => q(moskovský čas),
				'standard' => q(moskovský štandardný čas),
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q(mjanmarský čas),
			},
		},
		'Nauru' => {
			long => {
				'standard' => q(nauruský čas),
			},
		},
		'Nepal' => {
			long => {
				'standard' => q(nepálsky čas),
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q(novokaledónsky letný čas),
				'generic' => q(novokaledónsky čas),
				'standard' => q(novokaledónsky štandardný čas),
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q(novozélandský letný čas),
				'generic' => q(novozélandský čas),
				'standard' => q(novozélandský štandardný čas),
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q(newfoundlandský letný čas),
				'generic' => q(newfoundlandský čas),
				'standard' => q(newfoundlandský štandardný čas),
			},
		},
		'Niue' => {
			long => {
				'standard' => q(niuejský čas),
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q(norfolský čas),
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q(letný čas súostrovia Fernando de Noronha),
				'generic' => q(čas súostrovia Fernando de Noronha),
				'standard' => q(štandardný čas súostrovia Fernando de Noronha),
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q(novosibirský letný čas),
				'generic' => q(novosibirský čas),
				'standard' => q(novosibirský štandardný čas),
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q(omský letný čas),
				'generic' => q(omský čas),
				'standard' => q(omský štandardný čas),
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#Apia#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#Auckland#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#Bougainville#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#Chatham#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#Veľkonočný ostrov#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#Efate#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#Enderbury#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#Fakaofo#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidži#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#Funafuti#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#Galapágy#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#Gambier#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#Guadalcanal#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#Guam#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#Honolulu#,
		},
		'Pacific/Johnston' => {
			exemplarCity => q#Johnston#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#Kiritimati#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#Kosrae#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#Kwajalein#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#Majuro#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#Markézy#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#Midway#,
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
			exemplarCity => q#Nouméa#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#Pago Pago#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#Palau#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#Pitcairn#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Pohnpei#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#Port Moresby#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#Rarotonga#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#Saipan#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#Tahiti#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#Tarawa#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#Tongatapu#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Chuuk#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#Wake#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#Wallis#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q(pakistanský letný čas),
				'generic' => q(pakistanský čas),
				'standard' => q(pakistanský štandardný čas),
			},
		},
		'Palau' => {
			long => {
				'standard' => q(palauský čas),
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q(čas Papuy-Novej Guiney),
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q(paraguajský letný čas),
				'generic' => q(paraguajský čas),
				'standard' => q(paraguajský štandardný čas),
			},
		},
		'Peru' => {
			long => {
				'daylight' => q(peruánsky letný čas),
				'generic' => q(peruánsky čas),
				'standard' => q(peruánsky štandardný čas),
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q(filipínsky letný čas),
				'generic' => q(filipínsky čas),
				'standard' => q(filipínsky štandardný čas),
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q(čas Fénixových ostrovov),
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q(pierre-miquelonský letný čas),
				'generic' => q(pierre-miquelonský čas),
				'standard' => q(pierre-miquelonský štandardný čas),
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q(čas Pitcairnových ostrovov),
			},
		},
		'Ponape' => {
			long => {
				'standard' => q(ponapský čas),
			},
		},
		'Reunion' => {
			long => {
				'standard' => q(réunionský čas),
			},
		},
		'Rothera' => {
			long => {
				'standard' => q(čas Rotherovej stanice),
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q(sachalinský letný čas),
				'generic' => q(sachalinský čas),
				'standard' => q(sachalinský štandardný čas),
			},
		},
		'Samara' => {
			long => {
				'daylight' => q(Samarský letný čas),
				'generic' => q(Samarský čas),
				'standard' => q(Samarský štandardný čas),
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q(samojský letný čas),
				'generic' => q(samojský čas),
				'standard' => q(samojský štandardný čas),
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q(seychelský čas),
			},
		},
		'Singapore' => {
			long => {
				'standard' => q(singapurský štandardný čas),
			},
		},
		'Solomon' => {
			long => {
				'standard' => q(čas Šalamúnových ostrovov),
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q(čas Južnej Georgie),
			},
		},
		'Suriname' => {
			long => {
				'standard' => q(surinamský čas),
			},
		},
		'Syowa' => {
			long => {
				'standard' => q(čas stanice Šówa),
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q(tahitský čas),
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q(tchajpejský letný čas),
				'generic' => q(tchajpejský čas),
				'standard' => q(tchajpejský štandardný čas),
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q(tadžický čas),
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q(tokelauský čas),
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q(tonžský letný čas),
				'generic' => q(tonžský čas),
				'standard' => q(tonžský štandardný čas),
			},
		},
		'Truk' => {
			long => {
				'standard' => q(chuukský čas),
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q(turkménsky letný čas),
				'generic' => q(turkménsky čas),
				'standard' => q(turkménsky štandardný čas),
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q(tuvalský čas),
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q(uruguajský letný čas),
				'generic' => q(uruguajský čas),
				'standard' => q(uruguajský štandardný čas),
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q(uzbecký letný čas),
				'generic' => q(uzbecký čas),
				'standard' => q(uzbecký štandardný čas),
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q(vanuatský letný čas),
				'generic' => q(vanuatský čas),
				'standard' => q(vanuatský štandardný čas),
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q(venezuelský čas),
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q(vladivostocký letný čas),
				'generic' => q(vladivostocký čas),
				'standard' => q(vladivostocký štandardný čas),
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q(volgogradský letný čas),
				'generic' => q(volgogradský čas),
				'standard' => q(volgogradský štandardný čas),
			},
		},
		'Vostok' => {
			long => {
				'standard' => q(čas stanice Vostok),
			},
		},
		'Wake' => {
			long => {
				'standard' => q(čas ostrova Wake),
			},
		},
		'Wallis' => {
			long => {
				'standard' => q(čas ostrovov Wallis a Futuna),
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q(jakutský letný čas),
				'generic' => q(jakutský čas),
				'standard' => q(jakutský štandardný čas),
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q(jekaterinburský letný čas),
				'generic' => q(jekaterinburský čas),
				'standard' => q(jekaterinburský štandardný čas),
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
