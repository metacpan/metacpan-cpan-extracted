=encoding utf8

=head1 NAME

Locale::CLDR::Locales::Chr - Package for language Cherokee

=cut

package Locale::CLDR::Locales::Chr;
# This file auto generated from Data\common\main\chr.xml
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
has 'valid_algorithmic_formats' => (
    is => 'ro',
    isa => ArrayRef,
    init_arg => undef,
    default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal' ]},
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
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
				'max' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-numbering=),
				},
			},
		},
		'spellout-numbering' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(ꭺꮳꮄꮝꮧ →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ꮭ ꭺꮝꮧ),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← ꭺꮝꮣᏹ →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(ꮠꮼ),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(ꮤꮅ),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(ꮶꭲ),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(ꮕꭹ),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(ꭿꮝꭹ),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(ꮡꮣꮅ),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(ꭶꮅꮙꭹ),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(ꮷꮑꮃ),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(ꮠꮑꮃ),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(ꮝꭺꭿ),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(ꮜꮪ),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(ꮤꮅꮪ),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(ꮶꭶꮪ),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(ꮒꭶꮪ),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(ꭿꮝꭶꮪ),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(ꮣꮃꮪ),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(ꭶꮅꮖꮪ),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(ꮑꮃꮪ),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(ꮠꮑꮃꮪ),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(ꮤꮅꮝꭺ→%%spellout-tens→),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q(ꮶꭲꮝꭺ→%%spellout-tens→),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q(ꮕꭹꮝꭺ→%%spellout-tens→),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q(ꭿꮝꭹꮝꭺ→%%spellout-tens→),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q(ꮡꮣꮅꮝꭺ→%%spellout-tens→),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q(ꭶꮅꮖꮝꭺ→%%spellout-tens→),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q(ꮷꮑꮃꮝꭺ→%%spellout-tens→),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q(ꮠꮑꮃꮝꭺ→%%spellout-tens→),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(←← ꮝꭺꭿꮵꮖ[ →→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(←← ꭲꮿꭶᏼꮅ[ →→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←← ꭲᏻꮖꮧꮕꮣ[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←← ꭲꮿꮤꮃꮧꮕꮫ[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←← ꭲꮿꮶꭰꮧꮕꮫ[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←← ꭲꮿꮕꭶꮧꮕꮫ[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'Inf' => {
					divisor => q(1),
					rule => q(ꭲꭺꭿꮣ ꭸꮢ),
				},
				'NaN' => {
					divisor => q(1),
					rule => q(ꭷꮒꭹꮣ ꮧꮞꮝꮧ),
				},
				'max' => {
					divisor => q(1),
					rule => q(ꭷꮒꭹꮣ ꮧꮞꮝꮧ),
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
		'spellout-tens' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ꭿ),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-numbering=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-numbering=),
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
				'aa' => 'ᎠᏩᎳ',
 				'ab' => 'ᎠᏆᏏᎠᏂ',
 				'ace' => 'ᎠᏥᏂᏏ',
 				'ada' => 'ᎠᏓᎾᎦᎺ',
 				'ady' => 'ᎠᏗᎨ',
 				'af' => 'ᎠᎬᎿᎨᏍᏛ',
 				'agq' => 'ᎠᎨᎹ',
 				'ain' => 'ᎠᏱᏄ',
 				'ak' => 'ᎠᎧᎾ',
 				'ale' => 'ᎠᎵᎤᏘ',
 				'alt' => 'ᏧᎦᎾᏮ ᏗᏜ ᎠᎵᏔᎢ',
 				'am' => 'ᎠᎹᎭᎵᎩ',
 				'an' => 'ᎠᏩᎪᏂᏏ',
 				'ann' => 'ᎣᏉᎶ',
 				'anp' => 'ᎠᎾᎩᎧ',
 				'ar' => 'ᎡᎳᏈ',
 				'ar_001' => 'ᎪᎯᏊ ᎢᎬᏥᎩ ᎠᏟᎶᏍᏗ ᎡᎳᏈ',
 				'arn' => 'ᎹᏊᏤ',
 				'arp' => 'ᎠᏩᏈᎰ',
 				'ars' => 'ᎾᏣᏗ ᎠᎳᏈ',
 				'as' => 'ᎠᏌᎻᏏ',
 				'asa' => 'ᎠᏑ',
 				'ast' => 'ᎠᏍᏚᎵᎠᏂ',
 				'atj' => 'ᎠᏂᏘᎧᎺᏆ',
 				'av' => 'ᎠᏩᎵᎧ',
 				'awa' => 'ᎠᏩᏗ',
 				'ay' => 'ᎠᏱᎹᎳ',
 				'az' => 'ᎠᏎᏆᏣᏂ',
 				'az@alt=short' => 'ᎠᏎᎵ',
 				'ba' => 'ᏆᏍᎯᎩᎠ',
 				'ban' => 'ᏆᎵᏁᏏ',
 				'bas' => 'ᏆᏌᎠ',
 				'be' => 'ᏇᎳᎷᏏ',
 				'bem' => 'ᏇᎹᏆ',
 				'bez' => 'ᏇᎾ',
 				'bg' => 'ᏊᎵᎨᎵᎠᏂ',
 				'bgc' => 'ᎭᏯᏅᎢ',
 				'bho' => 'ᏉᏣᏊᎵ',
 				'bi' => 'ᏈᏍᎳᎹ',
 				'bin' => 'ᏈᏂ',
 				'bla' => 'ᏏᎩᏏᎧ',
 				'blo' => 'ᎠᏂᎵ',
 				'bm' => 'ᏆᎻᏆᎳ',
 				'bn' => 'ᏇᏂᎦᎳ',
 				'bo' => 'ᏘᏇᏔᏂ',
 				'br' => 'ᏇᏙᏂ',
 				'brx' => 'ᏉᏙ',
 				'bs' => 'ᏆᏍᏂᎠᏂ',
 				'bug' => 'ᏈᎥᎩᏂᏍ',
 				'byn' => 'ᏟᏂ',
 				'ca' => 'ᎨᏔᎳᏂ',
 				'cay' => 'ᎧᏳᎦ',
 				'ccp' => 'ᏣᎧᎹ',
 				'ce' => 'ᏤᏤᏂ',
 				'ceb' => 'ᏎᏆᏃ',
 				'cgg' => 'ᏥᎦ',
 				'ch' => 'ᏣᎼᎶ',
 				'chk' => 'ᏧᎨᏎ',
 				'chm' => 'ᎹᎵ',
 				'cho' => 'ᎠᏣᏓ',
 				'chp' => 'ᎠᏥᏇᏯᏂ',
 				'chr' => 'ᏣᎳᎩ',
 				'chy' => 'ᏣᏰᏂ',
 				'ckb' => 'ᎠᏰᏟ ᎫᏗᏏ',
 				'clc' => 'ᏥᎸᎪᏘᎾ',
 				'co' => 'ᎪᎵᏍᎢᎧᏂ',
 				'crg' => 'ᎻᏥᏩ',
 				'crj' => 'ᏧᎦᏃᏮ ᏗᎧᎸᎬ Ꮯ',
 				'crk' => 'ᏠᎨᏏ Ꮯ',
 				'crl' => 'ᏧᏴᏢ ᏗᎧᎸᎬ Ꮯ',
 				'crm' => 'ᎠᏫ ᎡᏆ Ꮯ',
 				'crr' => 'ᎠᎵᎦᏂᏈᎠᎾ',
 				'crs' => 'ᏎᏎᎵᏩ ᏟᏲᎵ ᎠᏂᎦᎸ',
 				'cs' => 'ᏤᎩ',
 				'csw' => 'ᏌᎷᏱ Ꮯ',
 				'cu' => 'ᏧᏂᎳᏫᏍᏗ ᏍᎳᏫᎪ',
 				'cv' => 'ᏧᏩᏏ',
 				'cy' => 'ᏪᎵᏏ',
 				'da' => 'ᏕᏂᏍ',
 				'dak' => 'ᏓᎪᏔ',
 				'dar' => 'ᏓᎳᏆ',
 				'dav' => 'ᏔᎢᏔ',
 				'de' => 'ᏙᎢᏥ',
 				'de_AT' => 'ᎠᏟᏯᏂ ᎠᏂᏓᏥ',
 				'de_CH' => 'ᏍᏫᏏ ᎦᎸᎳᏗ ᎠᏂᏓᏥ',
 				'dgr' => 'ᎩᏟ ᎤᏄᎳᏥ',
 				'dje' => 'ᏌᎹ',
 				'doi' => 'ᏙᎦᎵ',
 				'dsb' => 'ᎡᎳᏗ ᏐᏈᎠᏂ',
 				'dua' => 'ᏚᎠᎳ',
 				'dv' => 'ᏗᏪᎯ',
 				'dyo' => 'ᏦᎳ-ᏬᏱ',
 				'dz' => 'ᏓᏐᏅᎧ',
 				'dzg' => 'ᏓᏌᎦ',
 				'ebu' => 'ᎡᎻᏊ',
 				'ee' => 'ᎡᏪ',
 				'efi' => 'ᎡᏫᎩ',
 				'eka' => 'ᎨᎧᏧᎧ',
 				'el' => 'ᎠᏂᎪᎢ',
 				'en' => 'ᎩᎵᏏ',
 				'en_AU' => 'ᎡᎳᏗᏜ ᎩᎵᏏ',
 				'en_CA' => 'ᎨᎾᏓ ᎩᎵᏏ',
 				'en_GB' => 'ᎩᎵᏏᏲ ᎩᎵᏏ',
 				'en_GB@alt=short' => 'UK ᎩᎵᏏ',
 				'en_US' => 'ᎠᎹᏰᏟ ᎩᎵᏏ',
 				'en_US@alt=short' => 'US ᎩᎵᏏ',
 				'eo' => 'ᎡᏍᏇᎳᏂᏙ',
 				'es' => 'ᏍᏆᏂ',
 				'es_419' => 'ᏔᏘᏂ ᎠᎹᏰᏟ ᏍᏆᏂ',
 				'es_ES' => 'ᎠᏂᏍᏆᏂᏱ ᏍᏆᏂ',
 				'es_MX' => 'ᏍᏆᏂᏱ ᏍᏆᏂ',
 				'et' => 'ᎡᏍᏙᏂᎠᏂ',
 				'eu' => 'ᏆᏍᎨ',
 				'ewo' => 'ᎡᏬᏂᏙ',
 				'fa' => 'ᏇᏏᎠᏂ',
 				'fa_AF' => 'ᏓᎵ',
 				'ff' => 'ᏊᎳᏂ',
 				'fi' => 'ᏈᏂᏍ',
 				'fil' => 'ᎠᏈᎵᎩ',
 				'fj' => 'ᏫᏥᎠᏂ',
 				'fo' => 'ᏇᎶᎡᏍ',
 				'fon' => 'ᏠᏂ',
 				'fr' => 'ᎦᎸᏥ',
 				'fr_CA' => 'ᎨᎾᏓ ᎦᎸᏥ',
 				'fr_CH' => 'ᏍᏫᏏ ᎦᎸᏥ',
 				'frc' => 'ᎨᏨᏂ ᎦᎸᏥ',
 				'frr' => 'ᏧᏴᏢ ᎷᏈ',
 				'fur' => 'ᏞᎤᎵᎠᏂ',
 				'fy' => 'ᏭᏕᎵᎬ ᏗᏜ ᏟᏏᎠᏂ',
 				'ga' => 'ᎨᎵᎩ',
 				'gaa' => 'Ꭶ',
 				'gd' => 'ᏍᎦᏗ ᎨᎵᎩ',
 				'gez' => 'ᎩᏏ',
 				'gil' => 'ᎩᏇᏘᏏ',
 				'gl' => 'ᎦᎵᏏᎠᏂ',
 				'gn' => 'ᏆᎳᏂ',
 				'gor' => 'ᎪᎶᏂᏔᏃ',
 				'gsw' => 'ᏍᏫᏏ ᎠᏂᏓᏥ',
 				'gu' => 'ᎫᏣᎳᏘ',
 				'guz' => 'ᎫᏏ',
 				'gv' => 'ᎹᎾᎧᏏ',
 				'gwi' => 'ᏈᏥᏂ',
 				'ha' => 'ᎭᎤᏌ',
 				'hai' => 'ᎭᏱᏓ',
 				'haw' => 'ᎭᏩᎼ',
 				'hax' => 'ᏧᎦᏃᏮ ᏗᏜ ᎭᏱᏓ',
 				'he' => 'ᎠᏂᏈᎷ',
 				'hi' => 'ᎯᏂᏗ',
 				'hi_Latn@alt=variant' => 'ᎯᏂᏲᏁᎦ',
 				'hil' => 'ᎯᎵᎨᎾᏂ',
 				'hmn' => 'ᎭᎼᏂᎩ',
 				'hr' => 'ᎧᎶᎡᏏᏂ',
 				'hsb' => 'ᎦᎸᎳᏗᎨ ᏐᏈᎠᏂ',
 				'ht' => 'ᎮᏏᎠᏂ ᏟᏲᎵ',
 				'hu' => 'ᎲᏂᎦᎵᎠᏂ',
 				'hup' => 'ᎠᏂᎱᏆ',
 				'hur' => 'ᎭᎵᎪᎺᎴᎻ',
 				'hy' => 'ᎠᎳᎻᎠᏂ',
 				'hz' => 'ᎮᎴᎶ',
 				'ia' => 'ᎠᏰᏟ ᎦᏬᏂᎯᏍᏗ',
 				'iba' => 'ᎢᏆᏂ',
 				'ibb' => 'ᎢᏈᏈᎣ',
 				'id' => 'ᎢᏂᏙᏂᏏᎠ',
 				'ie' => 'ᏈᏖᎵᏆ',
 				'ig' => 'ᎢᎦᎪ',
 				'ii' => 'ᏏᏧᏩᏂ Ᏹ',
 				'ikt' => 'ᏭᏕᎵᎬ ᎨᎾᏓ ᎢᏄᎩᏘᏚᏘ',
 				'ilo' => 'ᎢᎶᎪ',
 				'inh' => 'ᎢᏂᎫᏏ',
 				'io' => 'ᎢᏙ',
 				'is' => 'ᏧᏁᏍᏓᎸᎯᎢᎩ',
 				'it' => 'ᎬᏩᎵᏲᏥᎢ',
 				'iu' => 'ᎢᏄᎦᏘᏚ',
 				'ja' => 'ᏣᏩᏂᏏ',
 				'jbo' => 'ᎶᏣᏆᏂ',
 				'jgo' => 'ᎾᎪᏆ',
 				'jmc' => 'ᎹᏣᎺ',
 				'jv' => 'ᏆᏌ ᏣᏩ',
 				'ka' => 'ᏦᏥᎠᏂ',
 				'kab' => 'ᎧᏈᎴ',
 				'kac' => 'ᎧᏥᏂ',
 				'kaj' => 'ᏥᏧ',
 				'kam' => 'ᎧᎻᏆ',
 				'kbd' => 'ᎧᏆᏗᎠᏂ',
 				'kcg' => 'ᏔᏯᏆ',
 				'kde' => 'ᎹᎪᏕ',
 				'kea' => 'ᎧᏊᏪᏗᎠᏄ',
 				'kfo' => 'ᎪᎶ',
 				'kgp' => 'ᎨᏂᎨᏂ',
 				'kha' => 'ᎧᏏ',
 				'khq' => 'ᎪᏱᎳ ᏥᏂ',
 				'ki' => 'ᎩᎫᏳ',
 				'kj' => 'ᎫᏩᏂᎠᎹ',
 				'kk' => 'ᎧᏌᎧ',
 				'kkj' => 'ᎧᎪ',
 				'kl' => 'ᎧᎳᎵᏑᏘ',
 				'kln' => 'ᎧᎴᏂᏥᏂ',
 				'km' => 'ᎩᎻᎷ',
 				'kmb' => 'ᎩᎻᏊᏚ',
 				'kn' => 'ᎧᎾᏓ',
 				'ko' => 'ᎪᎵᎠᏂ',
 				'kok' => 'ᎧᏂᎧᏂ',
 				'kpe' => 'ᏇᎴ',
 				'kr' => 'ᎧᏄᎵ',
 				'krc' => 'ᎧᎳᏣᏱ-ᏆᎵᎧᎵ',
 				'krl' => 'ᎧᎴᎵᎠᏂ',
 				'kru' => 'ᎫᎷᎩ',
 				'ks' => 'ᎧᏏᎻᎵ',
 				'ksb' => 'ᏝᎻᏆᎸ',
 				'ksf' => 'ᏆᏫᎠ',
 				'ksh' => 'ᎪᎶᏂᎠᏂ',
 				'ku' => 'ᎫᏗᏏ',
 				'kum' => 'ᎫᎻᎧ',
 				'kv' => 'ᎪᎻ',
 				'kw' => 'ᏎᎷᎭ',
 				'kwk' => 'ᏆᏆᎳ',
 				'kxv' => 'ᎫᏈ',
 				'ky' => 'ᎩᎵᏣᎢᏍ',
 				'la' => 'ᎳᏘᏂ',
 				'lad' => 'ᎳᏗᏃ',
 				'lag' => 'ᎳᏂᎩ',
 				'lb' => 'ᎸᎦᏏᎻᏋᎢᏍ',
 				'lez' => 'ᎴᏏᎦᏂ',
 				'lg' => 'ᎦᏂᏓ',
 				'li' => 'ᎴᎹᏊᎵᏏ',
 				'lij' => 'ᎵᏇᎢᎠ',
 				'lil' => 'ᎵᎶᎡᏘ',
 				'lkt' => 'ᎳᎪᏓ',
 				'lmo' => 'ᎶᏆᏗ',
 				'ln' => 'ᎵᏂᎦᎳ',
 				'lo' => 'ᎳᎣ',
 				'lou' => 'ᎷᏫᏏᎡᎾ ᎦᏬᏂᎯᏍᏗ',
 				'loz' => 'ᎶᏏ',
 				'lrc' => 'ᏧᏴᏢ ᏗᏜ ᎷᎵ',
 				'lsm' => 'ᏌᎠᎻᎠ',
 				'lt' => 'ᎵᏚᏩᏂᎠᏂ',
 				'lu' => 'ᎷᏆ-ᎧᏔᎦ',
 				'lua' => 'ᎷᏆ-ᎷᎷᎠ',
 				'lun' => 'ᎷᎾᏓ',
 				'luo' => 'ᎷᎣ',
 				'lus' => 'ᎻᏐ',
 				'luy' => 'ᎷᏱᎠ',
 				'lv' => 'ᎳᏘᏫᎠᏂ',
 				'mad' => 'ᎹᏚᎴᏏ',
 				'mag' => 'ᎹᎦᎯ',
 				'mai' => 'ᎹᏟᎵ',
 				'mak' => 'ᎹᎧᏌ',
 				'mas' => 'ᎹᏌᏱ',
 				'mdf' => 'ᎼᎧᏌ',
 				'men' => 'ᎺᎾᏕ',
 				'mer' => 'ᎺᎷ',
 				'mfe' => 'ᎼᎵᏏᎡᏂ',
 				'mg' => 'ᎹᎳᎦᏏ',
 				'mgh' => 'ᎹᎫᏩ-ᎻᏙ',
 				'mgo' => 'ᎺᎳ’',
 				'mh' => 'ᎹᏌᎵᏏ',
 				'mi' => 'ᎹᏫ',
 				'mic' => 'ᎻᎧᎹᎩ',
 				'min' => 'ᎻᎾᎧᏆᎤ',
 				'mk' => 'ᎹᏎᏙᏂᎠᏂ',
 				'ml' => 'ᎹᎳᏯᎳᎻ',
 				'mn' => 'ᎹᏂᎪᎵᎠᏂ',
 				'mni' => 'ᎺᏂᏉᎵ',
 				'moe' => 'ᎢᏄ-ᎠᏱᏵᏂ',
 				'moh' => 'ᎼᎭᎩ',
 				'mos' => 'ᎼᏍᏏ',
 				'mr' => 'ᎹᎳᏘ',
 				'ms' => 'ᎹᎴ',
 				'mt' => 'ᎹᎵᏘᏍ',
 				'mua' => 'ᎽᏂᏓᎩ',
 				'mul' => 'ᏧᏈᏍᏗ ᏗᎦᏬᏂᎯᏍᏗ',
 				'mus' => 'ᎠᎫᏌ',
 				'mwl' => 'ᎻᎳᏕᏏ',
 				'my' => 'ᏋᎻᏍ',
 				'myv' => 'ᎡᏏᏯ',
 				'mzn' => 'ᎹᏌᏕᎳᏂ',
 				'na' => 'ᏃᎤᎷ',
 				'nap' => 'ᏂᏯᏆᎵᏔᏂ',
 				'naq' => 'ᎾᎹ',
 				'nb' => 'ᏃᎵᏪᏥᏂ ᏉᎧᎹᎵ',
 				'nd' => 'ᏧᏴᏢ ᏂᏕᏇᎴ',
 				'nds' => 'ᎡᎳᏗ ᎠᏂᏓᏥ',
 				'nds_NL' => 'ᎡᎳᏗ ᏁᏛᎳᏂ',
 				'ne' => 'ᏁᏆᎵ',
 				'new' => 'ᏁᏩᎵ',
 				'ng' => 'ᎾᏙᎦ',
 				'nia' => 'ᏂᎠᏏ',
 				'niu' => 'ᏂᏳᏫᏯᏂ',
 				'nl' => 'ᏛᏥ',
 				'nl_BE' => 'ᏊᎵᏥᎥᎻ ᏛᏥ',
 				'nmg' => 'ᏆᏏᏲ',
 				'nn' => 'ᏃᎵᏪᏥᏂ ᎾᎵᏍᎩ',
 				'nnh' => 'ᎾᏥᏰᎹᏊᏂ',
 				'no' => 'ᏃᎵᏪᏥᏂ',
 				'nog' => 'ᏃᎦᏱ',
 				'nqo' => 'ᎾᎪ',
 				'nr' => 'ᏧᎦᎾᏮ ᏂᏕᏇᎴ',
 				'nso' => 'ᏧᏴᏢ ᏗᏜ ᏐᏠ',
 				'nus' => 'ᏄᏪᎵ',
 				'nv' => 'ᎾᏩᎰ',
 				'ny' => 'ᏂᏯᏂᏣ',
 				'nyn' => 'ᏂᏯᎾᎪᎴ',
 				'oc' => 'ᎠᏏᏔᏂ',
 				'ojb' => 'ᏧᏴᏢ ᏭᏕᎵᎬ ᎣᏥᏆ',
 				'ojc' => 'ᎠᏰᏟ ᎣᏥᏆ',
 				'ojs' => 'ᎣᏥ-Ꮯ',
 				'ojw' => 'ᏭᏕᎵᎬ ᏗᏜ ᎣᏥᏆ',
 				'oka' => 'ᎣᎧᎾᎦᏂ',
 				'om' => 'ᎣᎶᎼ',
 				'or' => 'ᎣᏗᎠ',
 				'os' => 'ᎣᏎᏘᎧ',
 				'pa' => 'ᏡᏂᏣᏈ',
 				'pag' => 'ᏇᎦᏏᎠᏂ',
 				'pam' => 'ᏆᎹᏆᎾᎦ',
 				'pap' => 'ᏆᏈᏯᎺᎾᏙ',
 				'pau' => 'ᏆᎳᎤᏩᏂ',
 				'pcm' => 'ᎾᎩᎵᎠᏂ ᏈᏥᏂ',
 				'pis' => 'ᏈᏥᎾ',
 				'pl' => 'ᏉᎵᏍ',
 				'pqm' => 'ᎹᎵᏏᏘ-ᏇᏌᎹᏉᏗ',
 				'prg' => 'ᏡᏏᎠᏂ',
 				'ps' => 'ᏆᏍᏙ',
 				'pt' => 'ᏉᏧᎩᏍ',
 				'pt_BR' => 'ᏆᏏᎵᎢ ᏉᏧᎩᏍ',
 				'pt_PT' => 'ᏳᎳᏈ ᏉᏧᎩᏍ',
 				'qu' => 'ᎨᏧᏩ',
 				'quc' => 'ᎩᏤ',
 				'raj' => 'ᎳᏣᏍᎭᏂ',
 				'rap' => 'ᎳᏆᏄᏫ',
 				'rar' => 'ᎳᎶᏙᎾᎦᏂ',
 				'rhg' => 'ᎶᎯᏂᏯ',
 				'rm' => 'ᎠᏂᎶᎺᏂ',
 				'rn' => 'ᎷᏂᏗ',
 				'ro' => 'ᎶᎹᏂᎠᏂ',
 				'ro_MD' => 'ᎹᎵᏙᏫᎠ ᏣᎹᏂᎠᏂ',
 				'rof' => 'ᎶᎹᏉ',
 				'ru' => 'ᏲᏅᎯ',
 				'rup' => 'ᎠᏬᎹᏂᎠᏂ',
 				'rw' => 'ᎩᏂᏯᏩᏂᏓ',
 				'rwk' => 'Ꮖ',
 				'sa' => 'ᏍᏂᏍᎩᏗ',
 				'sad' => 'ᏌᏅᏓᏫ',
 				'sah' => 'ᏌᎧᎾ',
 				'saq' => 'ᏌᎹᏊᎷ',
 				'sat' => 'ᏌᏂᏔᎵ',
 				'sba' => 'ᎾᎦᎹᏇ',
 				'sbp' => 'ᏌᏁᎫ',
 				'sc' => 'ᏌᏗᏂᎠᏂ',
 				'scn' => 'ᏏᏏᎵᎠᏂ',
 				'sco' => 'ᏍᎦᏗ',
 				'sd' => 'ᏏᏂᏗ',
 				'se' => 'ᏧᏴᏢ ᏗᏜ ᏌᎻ',
 				'see' => 'ᏏᏂᎦ',
 				'seh' => 'ᏎᎾ',
 				'ses' => 'ᎪᏱᎳᏈᎶ ᏎᏂ',
 				'sg' => 'ᏌᏂᎪ',
 				'shi' => 'ᏔᏤᎵᎯᏘ',
 				'shn' => 'ᏝᏂ',
 				'si' => 'ᏏᎾᎭᎳ',
 				'sk' => 'ᏍᎶᏩᎩ',
 				'sl' => 'ᏍᎶᏫᏂᎠᏂ',
 				'slh' => 'ᏧᎦᏃᏮ ᏗᏜ ᎷᏑᏘᏏᏗ',
 				'sm' => 'ᏌᎼᏯᏂ',
 				'sma' => 'ᏧᎦᎾᏮ ᏗᏜ ᏌᎻ',
 				'smj' => 'ᎷᎴ ᏌᎻ',
 				'smn' => 'ᎢᎾᎵ ᏌᎻ',
 				'sms' => 'ᏍᎪᎵᏘ ᏌᎻ',
 				'sn' => 'ᏠᎾ',
 				'snk' => 'ᏐᏂᏂᎨ',
 				'so' => 'ᏐᎹᎵ',
 				'sq' => 'ᎠᎵᏇᏂ',
 				'sr' => 'ᏒᏈᎠᏂ',
 				'srn' => 'ᏏᎳᎾᏂ ᏙᏃᎪ',
 				'ss' => 'ᏍᏩᏘ',
 				'ssy' => 'ᏌᎰ',
 				'st' => 'ᏧᎦᎾᏮ ᏗᏜ ᏐᏠ',
 				'str' => 'ᏌᎵᏏ',
 				'su' => 'ᏑᏂᏓᏂᏏ',
 				'suk' => 'ᏑᎫᎹ',
 				'sv' => 'ᏍᏫᏗᏏ',
 				'sw' => 'ᏍᏩᎯᎵ',
 				'sw_CD' => 'ᎧᏂᎪ ᏍᏩᎯᎵ',
 				'swb' => 'ᎪᎼᎵᎠᏂ',
 				'syr' => 'ᏏᎵᎠᎩ',
 				'szl' => 'ᏏᎴᏏᏂ',
 				'ta' => 'ᏔᎻᎵ',
 				'tce' => 'ᏧᎦᏃᏮ ᏚᏦᏁ',
 				'te' => 'ᏖᎷᎦ',
 				'tem' => 'ᏘᎹᏁ',
 				'teo' => 'ᏖᏐ',
 				'tet' => 'ᏖᏚᎼ',
 				'tg' => 'ᏔᏥᎩ',
 				'tgx' => 'ᏔᎩᏏ',
 				'th' => 'ᏔᏱ',
 				'tht' => 'ᏔᏝᎾ',
 				'ti' => 'ᏘᎩᎵᏂᎠ',
 				'tig' => 'ᏢᏓᏥ',
 				'tk' => 'ᎠᏂᎬᎾ',
 				'tlh' => 'ᏟᎦᎾ',
 				'tli' => 'ᏟᎩᏘ',
 				'tn' => 'ᏧᏩᎾ',
 				'to' => 'ᏙᎾᎦᏂ',
 				'tok' => 'ᏙᎩ ᏉᎾ',
 				'tpi' => 'ᏙᎩ ᏈᏏᏂ',
 				'tr' => 'ᎠᎬᎾ',
 				'trv' => 'ᏔᎶᎪ',
 				'ts' => 'ᏦᎾᎦ',
 				'tt' => 'ᏔᏔ',
 				'ttm' => 'ᏧᏴᏢ ᏗᏜ ᏚᏦᏁ',
 				'tum' => 'ᏛᎹᏊᎧ',
 				'tvl' => 'ᏚᏩᎷ',
 				'twq' => 'ᏔᏌᏩᎩ',
 				'ty' => 'ᏔᎯᏘᎠᏂ',
 				'tyv' => 'ᏚᏫᏂᎠᏂ',
 				'tzm' => 'ᎠᏰᏟ ᎡᎶᎯ ᏓᏟᎶᏍᏗᏓᏅᎢ ᏔᎹᏏᏘ',
 				'udm' => 'ᎤᏚᎷᏘ',
 				'ug' => 'ᏫᎦ',
 				'uk' => 'ᏳᎧᎴᏂᎠᏂ',
 				'umb' => 'ᎤᎹᏊᏅᏚ',
 				'und' => 'ᏄᏬᎵᏍᏛᎾ ᎦᏬᏂᎯᏍᏗ',
 				'ur' => 'ᎤᎵᏚ',
 				'uz' => 'ᎤᏍᏇᎩ',
 				'vai' => 'ᏩᏱ',
 				've' => 'ᏫᏂᏓ',
 				'vec' => 'ᏈᏂᏒᏂ',
 				'vi' => 'ᏫᎡᏘᎾᎻᏍ',
 				'vmw' => 'ᎹᎱᏩ',
 				'vo' => 'ᏬᎳᏊᎩ',
 				'vun' => 'ᏭᎾᏦ',
 				'wa' => 'ᏩᎷᎾ',
 				'wae' => 'ᏩᎵᏎᎵ',
 				'wal' => 'ᏬᎳᏱᏔ',
 				'war' => 'ᏩᎴ',
 				'wo' => 'ᏬᎶᏫ',
 				'wuu' => 'Ꮽ ᏓᎶᏂᎨᏍᏛ',
 				'xal' => 'ᎧᎳᎻᎧ',
 				'xh' => 'ᏠᏌ',
 				'xnr' => 'ᎧᏈᎢ',
 				'xog' => 'ᏐᎦ',
 				'yav' => 'ᏰᎾᎦᏇᏂ',
 				'ybb' => 'ᏰᎹᏋ',
 				'yi' => 'ᏱᏗᏍ',
 				'yo' => 'ᏲᏄᏆ',
 				'yrl' => 'ᏂᎾᎦᏚ',
 				'yue' => 'ᎨᎾᏙᏂᏏ',
 				'yue@alt=menu' => 'ᏓᎶᏂᎨ, ᎨᎾᏙᏂᏏ',
 				'za' => 'ᎱᎠᏂ',
 				'zgh' => 'ᎠᏟᎶᏍᏗ ᎼᎶᎪ ᏔᎹᏏᏘ',
 				'zh' => 'ᏓᎶᏂᎨ',
 				'zh@alt=menu' => 'ᏓᎶᏂᎨ, ᎹᏓᏈᏂ',
 				'zh_Hans' => 'ᎠᎯᏗᎨ ᏓᎶᏂᎨ',
 				'zh_Hans@alt=long' => 'ᎠᎯᏗᎨ ᎹᏓᏈᏂ ᏓᎶᏂᎨ',
 				'zh_Hant' => 'ᎤᏦᏍᏗ ᏓᎶᏂᎨ',
 				'zh_Hant@alt=long' => 'ᎤᏦᏍᏗ ᎹᏓᏈᏂ ᏓᎶᏂᎨ',
 				'zu' => 'ᏑᎷ',
 				'zun' => 'ᏑᏂ',
 				'zxx' => 'Ꮭ ᎦᏬᏂᎯᏍᏗ ᎦᎸᏛᎢ ᏱᎩ',
 				'zza' => 'ᏌᏌ',

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
			'Adlm' => 'ᎠᏓᎳᎻ',
 			'Arab' => 'ᎡᎳᏈᎩ',
 			'Aran' => 'ᎾᏍᏔᎵᏆ',
 			'Armn' => 'ᎠᎳᎻᎠᏂ',
 			'Beng' => 'ᏇᏂᎦᎠ',
 			'Bopo' => 'ᏆᏉᎼᏬ',
 			'Brai' => 'ᏗᏂᎨᏫ ᎤᏃᏪᎶᏙᏗ',
 			'Cakm' => 'ᏣᎧᎹ',
 			'Cans' => 'ᏌᏊ ᎨᎾᏓ ᎠᏂᏴᏫᏯ ᏗᎪᏪᎸ',
 			'Cher' => 'ᏣᎳᎩ',
 			'Cyrl' => 'ᏲᏂᎢ ᏗᎪᏪᎵ',
 			'Deva' => 'ᏕᏫᎾᎦᎵ',
 			'Ethi' => 'ᎢᏗᏯᏈᎩ',
 			'Geor' => 'ᏦᏥᎠᏂ',
 			'Grek' => 'ᎪᎢ',
 			'Gujr' => 'ᎫᏣᎳᏘ',
 			'Guru' => 'ᎬᎹᎩ',
 			'Hanb' => 'ᎭᏂ ᎾᎿ ᏆᏉᎼᏬ',
 			'Hang' => 'ᎭᏂᎫᎵ',
 			'Hani' => 'ᎭᏂ',
 			'Hans' => 'ᎠᎯᏗᎨ',
 			'Hans@alt=stand-alone' => 'ᎠᎯᏗᎨ ᎭᏂ',
 			'Hant' => 'ᎤᏦᏍᏗ',
 			'Hant@alt=stand-alone' => 'ᎤᏦᏍᏗ ᎭᏂ',
 			'Hebr' => 'ᎠᏂᏈᎵ',
 			'Hira' => 'ᎯᎳᎦᎾ',
 			'Hrkt' => 'ᏣᏩᏂᏏ ᏧᏃᏴᎩ',
 			'Jamo' => 'ᏣᎼ',
 			'Jpan' => 'ᏣᏆᏂᏏ',
 			'Kana' => 'ᎧᏔᎧᎾ',
 			'Khmr' => 'ᎩᎻᎷ',
 			'Knda' => 'ᎧᎾᏓ',
 			'Kore' => 'ᎪᎵᎠᏂ',
 			'Laoo' => 'ᎳᎣ',
 			'Latn' => 'ᎳᏘᏂ',
 			'Mlym' => 'ᎹᎳᏯᎳᎻ',
 			'Mong' => 'ᎹᏂᎪᎵᎠᏂ',
 			'Mtei' => 'ᎺᏖ ᎹᏰᎩ',
 			'Mymr' => 'ᎹᎡᏂᎹᎳ',
 			'Nkoo' => 'ᎾᎪ',
 			'Olck' => 'ᎣᎵ ᏥᎩ',
 			'Orya' => 'ᎣᏗᎠ',
 			'Rohg' => 'ᎭᏂᏫ',
 			'Sinh' => 'ᏏᏅᎭᎳ',
 			'Sund' => 'ᏚᏓᏂᏎ',
 			'Syrc' => 'ᏏᎵᎡᎩ',
 			'Taml' => 'ᏔᎻᎵ',
 			'Telu' => 'ᏖᎷᎦ',
 			'Tfng' => 'ᏘᏫᎾᎦ',
 			'Thaa' => 'ᏔᎠᎾ',
 			'Thai' => 'ᏔᏱ ᏔᏯᎴᏂ',
 			'Tibt' => 'ᏘᏇᏔᏂ',
 			'Vaii' => 'ᏩᏱ',
 			'Yiii' => 'Ᏹ',
 			'Zmth' => 'ᎠᏰᎦᎴᏴᏫᏍᎩ ᎠᎤᏓᏗᏍᏙᏗ',
 			'Zsye' => 'ᎡᎼᏥ',
 			'Zsym' => 'ᏗᎬᏟᎶᏍᏙᏗ',
 			'Zxxx' => 'ᎪᏪᎳᏅ ᏂᎨᏒᎾ',
 			'Zyyy' => 'ᏯᏃᏉ ᏱᎬᏍᏛᏭ',
 			'Zzzz' => 'ᏄᏬᎵᏍᏛᎾ ᎠᏍᏓᏩᏛᏍᏙᏗ',

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
			'001' => 'ᎡᎶᎯ',
 			'002' => 'ᎬᎿᎨᏍᏛ',
 			'003' => 'ᏧᏴᏢ ᎠᎹᏰᏟ',
 			'005' => 'ᏧᎦᏃᏮ ᎠᎺᎵᎦ',
 			'009' => 'ᎣᏏᏰᏂᎠ',
 			'011' => 'ᏭᏕᎵᎬ ᏗᏜ ᎬᎿᎨᏍᏛ',
 			'013' => 'ᎠᏰᏟ ᎠᎹᏰᏟ',
 			'014' => 'ᏗᎧᎸᎬ ᏗᏜ ᎬᎿᎨᏍᏛ',
 			'015' => 'ᏧᏴᏢ ᏗᏜ ᎬᎿᎨᏍᏛ',
 			'017' => 'ᎠᏰᏟ ᎬᎿᎨᏍᏛ',
 			'018' => 'ᏧᎦᎾᏮ ᏗᏜ ᎬᎿᎨᏍᏛ',
 			'019' => 'ᎠᎺᎵᎦᎢ',
 			'021' => 'ᏧᏴᏢ ᏗᏜ ᎠᎹᏰᏟ',
 			'029' => 'ᎨᏆᏙᏯ',
 			'030' => 'ᏗᎧᎸᎬ ᏗᏜ ᏓᎶᏂᎨᏍᏛ',
 			'034' => 'ᏧᎦᎾᏮ ᏗᏜ ᏓᎶᏂᎨᏍᏛ',
 			'035' => 'ᏧᎦᎾᏮ ᏗᎧᎸᎬ ᏓᎶᏂᎨᏍᏛ',
 			'039' => 'ᏧᎦᎾᏮ ᏗᏜ ᏳᎳᏛ',
 			'053' => 'ᎠᏍᏔᎴᏏᎠ',
 			'054' => 'ᎺᎳᏁᏏᎠ',
 			'057' => 'ᎠᏰᏟ ᏧᎾᎵᎪᎯ ᎾᎿ ᎹᎢᏉᏂᏏᏯ ᎢᎬᎾᏕᎾ',
 			'061' => 'ᏆᎵᏂᏏᎠ',
 			'142' => 'ᏓᎶᎾᎨᏍᏛ',
 			'143' => 'ᎠᏰᏟ ᏓᎶᏂᎨᏍᏛ',
 			'145' => 'ᏭᏕᎵᎬ ᏗᏜ ᏓᎶᏂᎨᏍᏛ',
 			'150' => 'ᏳᎳᏛ',
 			'151' => 'ᏗᎧᎸᎬ ᏗᏜ ᏳᎳᏛ',
 			'154' => 'ᏧᏴᏢ ᏗᏜ ᏳᎳᏛ',
 			'155' => 'ᏭᏕᎵᎬ ᏗᏜ ᏳᎳᏛ',
 			'202' => 'ᎭᏫᏂ-ᏌᎭᏩ ᎬᎿᎨᏍᏛ',
 			'419' => 'ᎳᏘᏂ ᎠᎹᏰᏟ',
 			'AC' => 'ᎤᎵᏌᎳᏓᏅ ᎤᎦᏚᏛᎢ',
 			'AD' => 'ᎠᏂᏙᎳ',
 			'AE' => 'ᏌᏊ ᎢᏳᎾᎵᏍᏔᏅ ᎡᎳᏈ ᎢᎹᎵᏘᏏ',
 			'AF' => 'ᎠᏫᎨᏂᏍᏖᏂ',
 			'AG' => 'ᎤᏪᏘ & ᏆᏊᏓ',
 			'AI' => 'ᎠᏂᎩᎳ',
 			'AL' => 'ᎠᎵᏇᏂᏯ',
 			'AM' => 'ᎠᎵᎻᏂᎠ',
 			'AO' => 'ᎠᏂᎪᎳ',
 			'AQ' => 'ᏧᏁᏍᏓᎸ',
 			'AR' => 'ᎠᏥᏂᏘᏂᎠ',
 			'AS' => 'ᎠᎺᎵᎧ ᏌᎼᎠ',
 			'AT' => 'ᎠᏍᏟᏯ',
 			'AU' => 'ᎡᎳᏗᏜ',
 			'AW' => 'ᎠᎷᏆ',
 			'AX' => 'ᎣᎴᏅᏓ ᏚᎦᏚᏛᎢ',
 			'AZ' => 'ᎠᏎᏆᏣᏂ',
 			'BA' => 'ᏉᏏᏂᎠ & ᎲᏤᎪᏫᎾ',
 			'BB' => 'ᏆᏇᏙᏍ',
 			'BD' => 'ᏆᏂᎦᎵᏕᏍ',
 			'BE' => 'ᏇᎵᏥᎥᎻ',
 			'BF' => 'ᏋᎩᎾ ᏩᏐ',
 			'BG' => 'ᏊᎵᎨᎵᎠ',
 			'BH' => 'ᏆᎭᎴᎢᏂ',
 			'BI' => 'ᏋᎷᏂᏗ',
 			'BJ' => 'ᏆᏂᎢᏂ',
 			'BL' => 'ᎤᏓᏅᏘ ᏆᏕᎳᎻ',
 			'BM' => 'ᏆᏊᏓ',
 			'BN' => 'ᏊᎾᎢ',
 			'BO' => 'ᏉᎵᏫᎠ',
 			'BQ' => 'ᎧᎵᏈᎢᏂᎯ ᎾᏍᎩᏁᏛᎳᏂ',
 			'BR' => 'ᏆᏏᎵ',
 			'BS' => 'ᎾᏍᎩ ᏆᎭᎹᏍ',
 			'BT' => 'ᏊᏔᏂ',
 			'BV' => 'ᏊᏪ ᎤᎦᏚᏛᎢ',
 			'BW' => 'ᏆᏣᏩᎾ',
 			'BY' => 'ᏇᎳᎷᏍ',
 			'BZ' => 'ᏇᎵᏍ',
 			'CA' => 'ᎨᎾᏓ',
 			'CC' => 'ᎪᎪᏍ (ᎩᎵᏂ) ᏚᎦᏚᏛᎢ',
 			'CD' => 'ᎧᏂᎪ - ᎨᏂᏝᏌ',
 			'CD@alt=variant' => 'ᎧᏂᎪ (DRC)',
 			'CF' => 'ᎬᎿᎨᏍᏛ ᎠᏰᏟ ᏍᎦᏚᎩ',
 			'CG' => 'ᎧᏂᎪ - ᏆᏌᏩᎵ',
 			'CG@alt=variant' => 'ᎧᏂᎪ (ᏍᎦᏚᎩ)',
 			'CH' => 'ᏍᏫᏍ',
 			'CI' => 'ᎢᏬᎵ ᎾᎿ ᎠᎹᏳᎶᏗ',
 			'CI@alt=variant' => 'ᎤᏁᎬ ᎪᎳ ᎠᎹᏳᎶᏗ',
 			'CK' => 'ᎠᏓᏍᏓᏴᎲᏍᎩ ᏚᎦᏚᏛᎢ',
 			'CL' => 'ᏥᎵ',
 			'CM' => 'ᎧᎹᎷᏂ',
 			'CN' => 'ᏓᎶᏂᎨᏍᏛ',
 			'CO' => 'ᎪᎸᎻᏈᎢᎠ',
 			'CP' => 'ᎦᏂᏴᏔᏅᎣᏓᎸ ᎤᎦᏚᏛᎢ',
 			'CR' => 'ᎪᏍᏓ ᎵᎧ',
 			'CU' => 'ᎫᏆ',
 			'CV' => 'ᎢᎬᎾᏕᎾ ᎢᏤᏳᏍᏗ',
 			'CW' => 'ᎫᎳᎨᎣ',
 			'CX' => 'ᏓᏂᏍᏓᏲᎯᎲ ᎤᎦᏚᏛᎢ',
 			'CY' => 'ᏌᎢᏆᏍ',
 			'CZ' => 'ᏤᎩᎠ',
 			'CZ@alt=variant' => 'ᏤᎩ ᏍᎦᏚᎩ',
 			'DE' => 'ᎠᏂᏛᏥ',
 			'DG' => 'ᏗᏰᎪ ᎦᏏᏯ',
 			'DJ' => 'ᏥᏊᏗ',
 			'DK' => 'ᏗᏂᎹᎦ',
 			'DM' => 'ᏙᎻᏂᎧ',
 			'DO' => 'ᏙᎻᏂᎧᏂ ᏍᎦᏚᎩ',
 			'DZ' => 'ᎠᎵᏥᎵᏯ',
 			'EA' => 'ᏑᏔ ᎠᎴ ᎺᎵᏯ',
 			'EC' => 'ᎡᏆᏙᎵ',
 			'EE' => 'ᎡᏍᏙᏂᏯ',
 			'EG' => 'ᎢᏥᏈᎢ',
 			'EH' => 'ᏭᏕᎵᎬ ᏗᏜ ᏌᎮᎳ',
 			'ER' => 'ᎡᎵᏟᏯ',
 			'ES' => 'ᎠᏂᏍᏆᏂᏱ',
 			'ET' => 'ᎢᏗᎣᏈᎠ',
 			'EU' => 'ᏳᎳᏛ ᎠᏂᎤᎾᏓᏡᎬ',
 			'EZ' => 'ᏳᎶᎠᏍᏓᏅᏅ',
 			'FI' => 'ᏫᏂᎦᏙᎯ',
 			'FJ' => 'ᏫᏥ',
 			'FK' => 'ᏩᎩ ᏚᎦᏚᏛᎢ',
 			'FK@alt=variant' => 'ᏩᎩ ᏚᎦᏚᏛᎢ (ᎢᏍᎳᏍ ᎹᎸᏫᎾᏍ)',
 			'FM' => 'ᎹᎢᏉᏂᏏᏯ',
 			'FO' => 'ᏪᎶ ᏚᎦᏚᏛᎢ',
 			'FR' => 'ᎦᎸᏥᏱ',
 			'GA' => 'ᎦᏉᏂ',
 			'GB' => 'ᎩᎵᏏᏲ',
 			'GD' => 'ᏋᎾᏓ',
 			'GE' => 'ᏣᎠᏥᎢ',
 			'GF' => 'ᎠᏂᎦᎸᏥ ᎩᎠ',
 			'GG' => 'ᎬᏂᏏ',
 			'GH' => 'ᎦᎠᎾ',
 			'GI' => 'ᏥᏆᎵᏓ',
 			'GL' => 'ᎢᏤᏍᏛᏱ',
 			'GM' => 'ᎦᎹᏈᎢᎠ',
 			'GN' => 'ᎩᎢᏂ',
 			'GP' => 'ᏩᏓᎷᏇ',
 			'GQ' => 'ᎡᏆᏙᎵᎠᎵ ᎩᎢᏂ',
 			'GR' => 'ᎪᎢᎯ',
 			'GS' => 'ᏧᎦᏃᏮ ᏣᎠᏥᎢ ᎠᎴ ᎾᏍᎩ ᏧᎦᏃᏮ ᎠᏍᏛᎭᏟ ᏚᎦᏚᏛᎢ',
 			'GT' => 'ᏩᏔᎹᎳ',
 			'GU' => 'ᏆᎻ',
 			'GW' => 'ᎩᎢᏂ-ᏈᏌᎤᏫ',
 			'GY' => 'ᎦᏯᎾ',
 			'HK' => 'ᎰᏂᎩ ᎪᏂᎩ ᎤᏓᏤᎵᏓ ᏧᏂᎸᏫᏍᏓᏁᏗ ᎢᎬᎾᏕᎾ ᏓᎶᏂᎨᏍᏛ',
 			'HK@alt=short' => 'ᎰᏂᎩ ᎪᏂᎩ',
 			'HM' => 'ᎲᏗ ᎤᎦᏚᏛᎢ ᎠᎴ ᎺᎩᏓᎾᎵᏗ ᏚᎦᏚᏛᎢ',
 			'HN' => 'ᎭᏂᏚᎳᏍ',
 			'HR' => 'ᎧᎶᎡᏏᎠ',
 			'HT' => 'ᎮᎢᏘ',
 			'HU' => 'ᎲᏂᎦᎵ',
 			'IC' => 'ᏥᏍᏆ ᏚᎦᏚᏛᎢ',
 			'ID' => 'ᎢᏂᏙᏂᏍᏯ',
 			'IE' => 'ᎠᏲᎳᏂ',
 			'IL' => 'ᎢᏏᎵᏱ',
 			'IM' => 'ᎤᏍᏗ ᎤᎦᏚᏛᎢ ᎾᎿ ᎠᏍᎦᏯ',
 			'IN' => 'ᎢᏅᏗᎾ',
 			'IO' => 'ᏈᏗᏏ ᏴᏫᏯ ᎠᎺᏉ ᎢᎬᎾᏕᏅ',
 			'IQ' => 'ᎢᎳᎩ',
 			'IR' => 'ᎢᎴᏂ',
 			'IS' => 'ᏧᏁᏍᏓᎸᎯ',
 			'IT' => 'ᎢᏔᎵ',
 			'JE' => 'ᏨᎵᏏ',
 			'JM' => 'ᏣᎺᎢᎧ',
 			'JO' => 'ᏦᏓᏂ',
 			'JP' => 'ᏣᏩᏂᏏ',
 			'KE' => 'ᎨᏂᏯ',
 			'KG' => 'ᎩᎵᏣᎢᏍ',
 			'KH' => 'ᎧᎹᏉᏗᎠᏂ',
 			'KI' => 'ᎧᎵᏆᏘ',
 			'KM' => 'ᎪᎼᎳᏍ',
 			'KN' => 'ᎤᏓᏅᏘ ᎨᏘᏏ ᎠᎴ ᏁᏪᏏ',
 			'KP' => 'ᏧᏴᏢ ᎪᎵᎠ',
 			'KR' => 'ᏧᎦᏃᏮ ᎪᎵᎠ',
 			'KW' => 'ᎫᏪᎢᏘ',
 			'KY' => 'ᎨᎢᎹᏂ ᏚᎦᏚᏛᎢ',
 			'KZ' => 'ᎧᏎᎧᏍᏕᏂ',
 			'LA' => 'ᎴᎣᏍ',
 			'LB' => 'ᎴᏆᎾᏂ',
 			'LC' => 'ᎤᏓᏅᏘ ᎷᏏᏯ',
 			'LI' => 'ᎵᎦᏗᏂᏍᏓᏂ',
 			'LK' => 'ᏍᎵ ᎳᏂᎧ',
 			'LR' => 'ᎳᏈᎵᏯ',
 			'LS' => 'ᎴᏐᏙ',
 			'LT' => 'ᎵᏗᏪᏂᎠ',
 			'LU' => 'ᎸᎧᏎᏋᎩ',
 			'LV' => 'ᎳᏘᏫᎠ',
 			'LY' => 'ᎵᏈᏯ',
 			'MA' => 'ᎼᎶᎪ',
 			'MC' => 'ᎹᎾᎪ',
 			'MD' => 'ᎹᎵᏙᏫᎠ',
 			'ME' => 'ᎼᏂᏔᏁᎦᎶ',
 			'MF' => 'ᎤᏓᏅᏘ ᏡᏡ',
 			'MG' => 'ᎹᏓᎦᏍᎧᎵ',
 			'MH' => 'ᎹᏌᎵ ᏚᎦᏚᏛᎢ',
 			'MK' => 'ᏧᏴᏜ ᎹᏎᏙᏂᏯ',
 			'ML' => 'ᎹᎵ',
 			'MM' => 'ᎹᏯᎹᎵ (ᏇᎵᎹ)',
 			'MN' => 'ᎹᏂᎪᎵᎠ',
 			'MO' => 'ᎹᎧᎣ (ᎤᏓᏤᎵᏓ ᏧᏂᎸᏫᏍᏓᏁᏗ ᎢᎬᎾᏕᎾ) ᏣᎢ',
 			'MO@alt=short' => 'ᎹᎧᎣ',
 			'MP' => 'ᏧᏴᏢ ᏗᏜ ᎹᎵᎠᎾ ᏚᎦᏚᏛᎢ',
 			'MQ' => 'ᎹᏘᏂᎨ',
 			'MR' => 'ᎹᏘᎢᏯ',
 			'MS' => 'ᎹᏂᏘᏌᎳᏗ',
 			'MT' => 'ᎹᎵᏔ',
 			'MU' => 'ᎼᎵᏏᎥᏍ',
 			'MV' => 'ᎹᎵᏗᏫᏍ',
 			'MW' => 'ᎹᎳᏫ',
 			'MX' => 'ᎠᏂᏍᏆᏂ',
 			'MY' => 'ᎹᎴᏏᎢᎠ',
 			'MZ' => 'ᎼᏎᎻᏇᎩ',
 			'NA' => 'ᎾᎻᏈᎢᏯ',
 			'NC' => 'ᎢᏤ ᎧᎵᏙᏂᎠᏂ',
 			'NE' => 'ᎾᎢᏨ',
 			'NF' => 'ᏃᎵᏬᎵᎩ ᎤᎦᏚᏛᎢ',
 			'NG' => 'ᏂᏥᎵᏯ',
 			'NI' => 'ᏂᎧᎳᏆ',
 			'NL' => 'ᏁᏛᎳᏂ',
 			'NO' => 'ᏃᏪ',
 			'NP' => 'ᏁᏆᎵ',
 			'NR' => 'ᏃᎤᎷ',
 			'NU' => 'ᏂᏳ',
 			'NZ' => 'ᎢᏤ ᏏᎢᎴᏂᏗ',
 			'NZ@alt=variant' => 'ᎠᏖᎠᏉᎠ ᎢᏤ ᏏᎢᎴᏂᏗ',
 			'OM' => 'ᎣᎺᏂ',
 			'PA' => 'ᏆᎾᎹ',
 			'PE' => 'ᏇᎷ',
 			'PF' => 'ᎠᏂᎦᎸᏥ ᏆᎵᏂᏏᎠ',
 			'PG' => 'ᏆᏇ ᎢᏤ ᎩᎢᏂ',
 			'PH' => 'ᎠᏂᏈᎵᎩᏃ',
 			'PK' => 'ᏆᎩᏍᏖᏂ',
 			'PL' => 'ᏉᎳᏂ',
 			'PM' => 'ᎤᏓᏅᏘ ᏈᏰ ᎠᎴ ᎻᏇᎶᏂ',
 			'PN' => 'ᏈᎧᎵᏂ ᏚᎦᏚᏛᎢ',
 			'PR' => 'ᏇᎡᏙ ᎵᎢᎪ',
 			'PS' => 'ᏆᎴᏍᏗᏂᎠᏂ ᏄᎬᏫᏳᏌᏕᎩ',
 			'PS@alt=short' => 'ᏆᎴᏍᏗᏂ',
 			'PT' => 'ᏉᏥᎦᎳ',
 			'PW' => 'ᏆᎴᎠᏫ',
 			'PY' => 'ᏆᎳᏇᎢᏯ',
 			'QA' => 'ᎧᏔᎵ',
 			'QO' => 'ᎠᏍᏛ ᎣᏏᏰᏂᎠ',
 			'RE' => 'ᎴᏳᏂᎠᏂ',
 			'RO' => 'ᎶᎹᏂᏯ',
 			'RS' => 'ᏒᏈᏯ',
 			'RU' => 'ᏲᏂᎢ',
 			'RW' => 'ᎶᏩᏂᏓ',
 			'SA' => 'ᏌᎤᏗ ᎡᎴᏈᎠ',
 			'SB' => 'ᏐᎶᎹᏂ ᏚᎦᏚᏛᎢ',
 			'SC' => 'ᏏᎡᏥᎵᏍ',
 			'SD' => 'ᏑᏕᏂ',
 			'SE' => 'ᏍᏫᏕᏂ',
 			'SG' => 'ᏏᏂᎦᏉᎵ',
 			'SH' => 'ᎤᏓᏅᏘ ᎮᎵᎾ',
 			'SI' => 'ᏍᎶᏫᏂᎠ',
 			'SJ' => 'ᏍᏩᎵᏆᎵᏗ ᎠᎴ ᏤᏂ ᎹᏰᏂ',
 			'SK' => 'ᏍᎶᏩᎩᎠ',
 			'SL' => 'ᏏᎡᎳ ᎴᎣᏂ',
 			'SM' => 'ᎤᏓᏅᏘ ᎹᎵᎢᏃ',
 			'SN' => 'ᏏᏂᎦᎵ',
 			'SO' => 'ᏐᎹᎵ',
 			'SR' => 'ᏒᎵᎾᎻ',
 			'SS' => 'ᏧᎦᎾᏮ ᏑᏕᏂ',
 			'ST' => 'ᏌᎣ ᏙᎺ ᎠᎴ ᏈᏂᏏᏇ',
 			'SV' => 'ᎡᎵᏌᎵᏆᏙᎵ',
 			'SX' => 'ᏏᏂᏘ ᎹᏘᏂ',
 			'SY' => 'ᏏᎵᎠ',
 			'SZ' => 'ᎡᏍᏩᏘᏂ',
 			'SZ@alt=variant' => 'ᎠᏂᏍᏩᏏᎢ',
 			'TA' => 'ᏟᏍᏛᏂ Ꮣ ᎫᎾᎭ',
 			'TC' => 'ᎠᏂᏛᎵᎩ ᎠᎴ ᎨᎢᎪ ᏚᎦᏚᏛᎢ',
 			'TD' => 'ᏣᏗ',
 			'TF' => 'ᎠᏂᎦᎸᏥ ᏧᎦᎾᏮ ᎦᏙᎯ ᎤᎵᏍᏛᎢ',
 			'TG' => 'ᏙᎪ',
 			'TH' => 'ᏔᏯᎴᏂ',
 			'TJ' => 'ᏔᏥᎩᏍᏕᏂ',
 			'TK' => 'ᏙᎨᎳᏭ',
 			'TL' => 'ᏘᎼᎵ-ᎴᏍᏖ',
 			'TL@alt=variant' => 'ᏗᎧᎸᎬᎢ ᏘᎼᎵ',
 			'TM' => 'ᏛᎵᎩᎺᏂᏍᏔᏂ',
 			'TN' => 'ᏚᏂᏏᏍᎠ',
 			'TO' => 'ᏙᎾᎦ',
 			'TR' => 'ᎬᏃ',
 			'TR@alt=variant' => 'ᎬᎩᏰ',
 			'TT' => 'ᏟᏂᏕᏗ ᎠᎴ ᏙᏆᎪ',
 			'TV' => 'ᏚᏩᎷ',
 			'TW' => 'ᏔᎢᏩᏂ',
 			'TZ' => 'ᏖᏂᏏᏂᏯ',
 			'UA' => 'ᏳᎧᎴᏂ',
 			'UG' => 'ᏳᎦᏂᏓ',
 			'UM' => 'U.S. ᎠᏍᏛ ᏚᎦᏚᏛᎢ',
 			'UN' => 'ᏌᏊ ᎢᏳᎾᎵᏍᏔᏅ ᎠᏰᎵ ᏚᎾᏙᏢᏒ',
 			'US' => 'ᏌᏊ ᎢᏳᎾᎵᏍᏔᏅ ᏍᎦᏚᎩ',
 			'US@alt=short' => 'US',
 			'UY' => 'ᏳᎷᏇ',
 			'UZ' => 'ᎤᏍᏇᎩᏍᏖᏂ',
 			'VA' => 'ᎠᏥᎳᏁᏠ ᎦᏚᎲ',
 			'VC' => 'ᎤᏓᏅᏘ ᏫᏂᏏᏂᏗ ᎠᎴ ᎾᏍᎩ ᏇᎾᏗᏁᏍ',
 			'VE' => 'ᏪᏁᏑᏪᎳ',
 			'VG' => 'ᏈᏗᏍ ᎠᏒᏂᎸ ᏂᎨᏒᎾ ᏚᎦᏚᏛᎢ',
 			'VI' => 'U.S. ᎠᏒᏂᎸ ᏂᎨᏒᎾ ᏚᎦᏚᏛᎢ',
 			'VN' => 'ᏫᎡᏘᎾᎻ',
 			'VU' => 'ᏩᏂᎤᏩᏚ',
 			'WF' => 'ᏩᎵᏍ ᎠᎴ ᏊᏚᎾ',
 			'WS' => 'ᏌᎼᎠ',
 			'XA' => 'ᏡᏙ-ᏄᏍᏛᎢᎥᎧᏁᎬᎢ',
 			'XB' => 'ᏡᏙ-ᏈᏗ',
 			'XK' => 'ᎪᏐᏉ',
 			'YE' => 'ᏰᎺᏂ',
 			'YT' => 'ᎺᏯᏖ',
 			'ZA' => 'ᏧᎦᎾᏮ ᎬᎿᎨᏍᏛ',
 			'ZM' => 'ᏌᎻᏈᏯ',
 			'ZW' => 'ᏏᎻᏆᏇ',
 			'ZZ' => 'ᏄᏬᎵᏍᏛᎾ ᎤᏔᏂᏗᎦᏙᎯ',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'calendar' => 'ᏅᏙ ᏗᏎᏍᏗ',
 			'cf' => 'ᎠᏕᎳ ᏱᎬᏁᎸᎯ',
 			'collation' => 'ᏗᎦᏅᏃᏙᏗ ᏕᎦᏅᏃᏛᎢ',
 			'currency' => 'ᎠᏕᎳ',
 			'hc' => 'ᏑᏟᎶᏓ ᎠᏓᏁᏟᏴᏎᎬ (12 vs 24)',
 			'lb' => 'ᎠᏍᏓᏅᏅ ᎠᏲᏍᏔᏅᎩ ᏂᏚᏍᏛ',
 			'ms' => 'ᎠᏟᎶᏛ ᏄᏍᏗᏓᏅᎢ',
 			'numbers' => 'ᏗᏎᏍᏗ',

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
 				'buddhist' => q{ᏊᏗᏍᏘ ᏅᏙ ᏗᏎᏍᏗ},
 				'chinese' => q{ᏓᎶᏂᎨᏍᏛ ᏅᏙ ᏗᏎᏍᏗ},
 				'coptic' => q{ᎧᏘ ᏅᏙ ᏗᏎᏍᏗ},
 				'dangi' => q{ᏓᏂᎩ ᏅᏙ ᏗᏎᏍᏗ},
 				'ethiopic' => q{ᎢᏗᏯᏈᎩ ᏅᏙ ᏗᏎᏍᏗ},
 				'ethiopic-amete-alem' => q{ᎡᏘᎣᏈᎠ ᎠᎺᏖ ᎠᎴᎻ ᏅᏙ ᏗᏎᏍᏗ},
 				'gregorian' => q{ᎩᎴᎪᎵᎠᏂ ᏅᏙ ᏗᏎᏍᏗ},
 				'hebrew' => q{ᎠᏂᏈᎷ ᏅᏙ ᏗᏎᏍᏗ},
 				'islamic' => q{ᎢᏍᎳᎻᎩ ᏅᏙ ᏗᏎᏍᏗ},
 				'islamic-civil' => q{ᎢᏌᎳᎻᎩ ᏅᏙ ᏗᏎᏍᏗ (ᏴᏫ ᎡᏆᎩ)},
 				'islamic-umalqura' => q{ᎢᏌᎳᎻᎩ ᏅᏙ ᏗᏎᏍᏗ (ᎥᎻ ᎠᎵ-ᏊᎳ)},
 				'iso8601' => q{ISO-8601 ᏅᏙ ᏗᏎᏍᏗ},
 				'japanese' => q{ᏣᏆᏂᏏ ᏅᏙ ᏗᏎᏍᏗ},
 				'persian' => q{ᏇᏏᎠᏂ ᏅᏙ ᏗᏎᏍᏗ},
 				'roc' => q{ᏍᎦᏚᎩ ᎾᎿ ᏓᎶᏂᎨᏍᏛ ᏅᏙ ᏗᏎᏍᏗ},
 			},
 			'cf' => {
 				'account' => q{ᎠᏕᎳ ᏗᏎᎯᎯ ᎠᏕᎳ ᏱᎬᏁᎸᎯ},
 				'standard' => q{ᎠᏟᎶᏍᏗ ᎠᏕᎳ ᏱᎬᏁᎸᎯ},
 			},
 			'collation' => {
 				'ducet' => q{ᎠᏓᏁᏟᏴᏗᏍᎩ Unicode ᏗᎦᏅᏃᏙᏗ ᏕᎦᏅᏃᏛᎢ},
 				'search' => q{ᏂᎦᎥ-ᎢᏳᏱᎸᏗ ᎠᏱᏍᏗ},
 				'standard' => q{ᎠᏟᎶᏍᏗ ᏗᎦᏅᏃᏙᏗ ᏕᎦᏅᏃᏛᎢ},
 			},
 			'hc' => {
 				'h11' => q{12 ᎢᏳᏟᎶᏓ ᏄᏍᏗᏓᏅᎢ (0–11)},
 				'h12' => q{12 ᎢᏳᏟᎶᏓ ᏄᏍᏗᏓᏅᎢ (1–12)},
 				'h23' => q{24 ᎢᏳᏟᎶᏓ ᏄᏍᏗᏓᏅᎢ (0–23)},
 				'h24' => q{24 ᎢᏳᏟᎶᏓ ᏄᏍᏗᏓᏅᎢ (1–24)},
 			},
 			'lb' => {
 				'loose' => q{ᏩᎾᎢ ᎠᏍᏓᏅᏅ ᎠᏲᏍᏔᏅᎩ ᏂᏚᏍᏛ},
 				'normal' => q{ᏱᎬᏍᏗᎭᏊ ᎠᏍᏓᏅᏅ ᎠᏲᏍᏔᏅᎩ ᏂᏚᏍᏛ},
 				'strict' => q{ᎤᎶᏒᏍᏔᏅᎯ ᎠᏍᏓᏅᏅ ᎠᏲᏍᏔᏅᎩ ᏂᏚᏍᏛ},
 			},
 			'ms' => {
 				'metric' => q{ᎠᏂᎩᎸᏥ ᏂᏓᏳᏓᎴᏅᎯ ᏗᏎᏍᏗ ᏄᏍᏗᏓᏅᎢ},
 				'uksystem' => q{ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎠᏟᎶᏛ ᏄᏍᏗᏓᏅᎢ},
 				'ussystem' => q{US ᎠᏟᎶᏛ ᏄᏍᏗᏓᏅᎢ},
 			},
 			'numbers' => {
 				'arab' => q{ᎠᎳᏈ-ᎡᏂᏗᎩ ᏗᏎᏍᏗ},
 				'arabext' => q{ᎦᏅᎯᏛ ᎠᎳᏈ-ᎡᏂᏗᎩ ᏗᏎᏍᏗ},
 				'armn' => q{ᎠᎳᎻᎠᏂ ᏗᏎᏍᏗ},
 				'armnlow' => q{ᎠᎳᎻᎠᏂ ᏧᏍᏗ ᏗᎪᏪᎵ ᏗᏎᏍᏗ},
 				'beng' => q{ᏇᏂᎦᎳ ᏗᏎᏍᏗ},
 				'cakm' => q{ᏣᎩᎹ ᏗᏎᏍᏗ},
 				'deva' => q{ᏕᏫᎾᎦᎵ ᏗᏎᏍᏗ},
 				'ethi' => q{ᎢᏗᏯᏈᎩ ᏗᏎᏍᏗ},
 				'fullwide' => q{ᎧᎵᎢ-ᎾᏯᏛᏒ ᏗᏎᏍᏗ},
 				'geor' => q{ᎩᎴᎪᎵᎠᏂ ᏗᏎᏍᏗ},
 				'grek' => q{ᎠᏂᎪᎢ ᏗᏎᏍᏗ},
 				'greklow' => q{ᎠᏂᎪᎢ ᏧᏍᏗ ᏗᎪᏪᎵ ᏗᏎᏍᏗ},
 				'gujr' => q{ᎫᏣᎳᏘ ᏗᏎᏍᏗ},
 				'guru' => q{ᎬᎹᎩ ᏗᏎᏍᏗ},
 				'hanidec' => q{ᏓᎶᏂᎨ ᏕᏏᎹᎵ ᏗᏎᏍᏗ},
 				'hans' => q{ᎠᎯᏗᎨ ᏓᎶᏂᎨ ᏗᏎᏍᏗ},
 				'hansfin' => q{ᎠᎯᏗᎨ ᏓᎶᏂᎨ ᎠᏕᎳ ᏗᏎᏍᏗ},
 				'hant' => q{ᎤᏦᏍᏗ ᏓᎶᏂᎨ ᏗᏎᏍᏗ},
 				'hantfin' => q{ᎤᏦᏍᏗ ᏓᎶᏂᎨ ᎠᏕᎳ ᏗᏎᏍᏗ},
 				'hebr' => q{ᎠᏂᏈᎷ ᏗᏎᏍᏗ},
 				'java' => q{ᏣᏩᏂᏎ ᏗᏎᏍᏗ},
 				'jpan' => q{ᏣᏆᏂᏏ ᏗᏎᏍᏗ},
 				'jpanfin' => q{ᏣᏆᏂᏏ ᎠᏕᎳ ᏗᏎᏍᏗ},
 				'khmr' => q{ᎩᎻᎷ ᏗᏎᏍᏗ},
 				'knda' => q{ᎧᎾᏓ ᏗᏎᏍᏗ},
 				'laoo' => q{ᎳᎣ ᏗᏎᏍᏗ},
 				'latn' => q{ᏭᏗᎵᎬ ᏗᏜ ᏗᏎᏍᏗ},
 				'mlym' => q{ᎹᎳᏯᎳᎻ ᏗᏎᏍᏗ},
 				'mtei' => q{ᎻᏖ ᎹᏰᎩ ᏗᏎᏍᏗ},
 				'mymr' => q{ᎹᏯᎹᎵ ᏗᏎᏍᏗ},
 				'olck' => q{ᎣᎵ ᏥᎩ ᏗᏎᏍᏗ},
 				'orya' => q{ᎣᏗᎠ ᏗᏎᏍᏗ},
 				'roman' => q{ᎠᏂᎶᎻ ᏗᏎᏍᏗ},
 				'romanlow' => q{ᎠᏂᎶᎻ ᏧᏍᏗ ᏗᎪᏪᎵ ᏗᏎᏍᏗ},
 				'taml' => q{ᎤᏦᏍᏗ ᏔᎻᎵ ᏗᏎᏍᏗ},
 				'tamldec' => q{ᏔᎻᎵ ᏗᏎᏍᏗ},
 				'telu' => q{ᏖᎷᎦ ᏗᏎᏍᏗ},
 				'thai' => q{ᏔᏱ ᏗᏎᏍᏗ},
 				'tibt' => q{ᏘᏇᏔᏂ ᏗᏎᏍᏗ},
 				'vaii' => q{ᏩᏱ ᏗᏎᏍᏗ},
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
			'metric' => q{ᎠᏂᎩᎸᏥ ᏂᏓᏳᏓᎴᏅᎯ ᏗᏎᏍᏗ},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub {
		{
			'language' => 'ᎦᏬᏂᎯᏍᏗ: {0}',
 			'script' => 'ᎧᏁᎢᏍᏗ: {0}',
 			'region' => 'ᎢᎬᎾᏕᎾ: {0}',

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
			index => ['Ꭰ', 'Ꭶ', 'Ꭽ', 'Ꮃ', 'Ꮉ', 'Ꮎ', 'Ꮖ', 'Ꮜ', 'Ꮣ', 'Ꮬ', 'Ꮳ', 'Ꮹ', 'Ꮿ'],
			main => qr{[ꭰ ꭱ ꭲ ꭳ ꭴ ꭵ ꭶ ꭷ ꭸ ꭹ ꭺ ꭻ ꭼ ꭽ ꭾ ꭿ ꮀ ꮁ ꮂ ꮃ ꮄ ꮅ ꮆ ꮇ ꮈ ꮉ ꮊ ꮋ ꮌ ꮍ ꮎ ꮏ ꮐ ꮑ ꮒ ꮓ ꮔ ꮕ ꮖ ꮗ ꮘ ꮙ ꮚ ꮛ ꮜ ꮝ ꮞ ꮟ ꮠ ꮡ ꮢ ꮣ ꮤ ꮥ ꮦ ꮧ ꮨ ꮩ ꮪ ꮫ ꮬ ꮭ ꮮ ꮯ ꮰ ꮱ ꮲ ꮳ ꮴ ꮵ ꮶ ꮷ ꮸ ꮹ ꮺ ꮻ ꮼ ꮽ ꮾ ꮿ ᏸ ᏹ ᏺ ᏻ ᏼ]},
			punctuation => qr{[\- ‐‑ – — , ; \: ! ? . … '‘’ "“” ( ) \[ \] § @ * / \& # † ‡ ′ ″]},
		};
	},
EOT
: sub {
		return { index => ['Ꭰ', 'Ꭶ', 'Ꭽ', 'Ꮃ', 'Ꮉ', 'Ꮎ', 'Ꮖ', 'Ꮜ', 'Ꮣ', 'Ꮬ', 'Ꮳ', 'Ꮹ', 'Ꮿ'], };
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
						'name' => q(ᏅᎩ ᏫᏂᏚᏳᎪᏛᎢ),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(ᏅᎩ ᏫᏂᏚᏳᎪᏛᎢ),
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
					'10p-27' => {
						'1' => q(ronto{0}),
					},
					# Core Unit Identifier
					'27' => {
						'1' => q(ronto{0}),
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
					'10p-30' => {
						'1' => q(quecto{0}),
					},
					# Core Unit Identifier
					'30' => {
						'1' => q(quecto{0}),
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
						'1' => q(hecto{0}),
					},
					# Core Unit Identifier
					'10p2' => {
						'1' => q(hecto{0}),
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
						'one' => q({0} ᎠᏓᎾᏌᏁᏍᎩ-ᎦᏌᏙᏯᏍᏗ),
						'other' => q({0} ᎠᏓᎾᏌᏁᏍᎩ-ᎦᏌᏙᏯᏍᏗ),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0} ᎠᏓᎾᏌᏁᏍᎩ-ᎦᏌᏙᏯᏍᏗ),
						'other' => q({0} ᎠᏓᎾᏌᏁᏍᎩ-ᎦᏌᏙᏯᏍᏗ),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(ᏗᏟᎶᏗ ᎠᏎᏢ ᎢᏳᏓᎵ ᏅᎩ ᏧᏅᏏᎩ),
						'one' => q({0} ᎠᏟᎶᏗ ᎠᏎᏢ ᎢᏳᏓᎵ ᏅᎩ ᏧᏅᏏᎩ),
						'other' => q({0} ᏗᏟᎶᏗ ᎠᏎᏢ ᎢᏳᏓᎵ ᏅᎩ ᏧᏅᏏᎩ),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(ᏗᏟᎶᏗ ᎠᏎᏢ ᎢᏳᏓᎵ ᏅᎩ ᏧᏅᏏᎩ),
						'one' => q({0} ᎠᏟᎶᏗ ᎠᏎᏢ ᎢᏳᏓᎵ ᏅᎩ ᏧᏅᏏᎩ),
						'other' => q({0} ᏗᏟᎶᏗ ᎠᏎᏢ ᎢᏳᏓᎵ ᏅᎩ ᏧᏅᏏᎩ),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'one' => q({0} ᎠᏥ ᎢᏯᎦᏔᏬᏍᏔᏅ),
						'other' => q({0} ᎠᏥ ᎢᏧᏔᏬᏍᏔᏅ),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'one' => q({0} ᎠᏥ ᎢᏯᎦᏔᏬᏍᏔᏅ),
						'other' => q({0} ᎠᏥ ᎢᏧᏔᏬᏍᏔᏅ),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'one' => q({0} ᎠᏥ ᎠᏓᎾᏬᏍᎬ),
						'other' => q({0} ᎠᏥ ᏓᏓᎾᏬᏍᎬ),
					},
					# Core Unit Identifier
					'arc-second' => {
						'one' => q({0} ᎠᏥ ᎠᏓᎾᏬᏍᎬ),
						'other' => q({0} ᎠᏥ ᏓᏓᎾᏬᏍᎬ),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'one' => q({0} ᎢᎦᎢ ᎢᎦ),
						'other' => q({0} ᎢᎦᎢ ᎢᏗᎦᏘ),
					},
					# Core Unit Identifier
					'degree' => {
						'one' => q({0} ᎢᎦᎢ ᎢᎦ),
						'other' => q({0} ᎢᎦᎢ ᎢᏗᎦᏘ),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(ᎠᏥ ᏗᏟᎶᏍᏙᏗ),
						'one' => q({0} ᎠᏥ ᎠᏟᎶᏍᏙᏗ),
						'other' => q({0} ᎠᏥ ᏗᏟᎶᏍᏙᏗ),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(ᎠᏥ ᏗᏟᎶᏍᏙᏗ),
						'one' => q({0} ᎠᏥ ᎠᏟᎶᏍᏙᏗ),
						'other' => q({0} ᎠᏥ ᏗᏟᎶᏍᏙᏗ),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'one' => q({0} ᎠᏕᏲᎲ),
						'other' => q({0} ᏗᏕᏲᎯ),
					},
					# Core Unit Identifier
					'revolution' => {
						'one' => q({0} ᎠᏕᏲᎲ),
						'other' => q({0} ᏗᏕᏲᎯ),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0} ᏑᏟᎶᏓᎢ),
						'other' => q({0} ᎢᏧᏟᎶᏓ),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0} ᏑᏟᎶᏓᎢ),
						'other' => q({0} ᎢᏧᏟᎶᏓ),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'one' => q({0} ᏚᎾᎹ),
						'other' => q({0} ᏚᎾᎹᏍ),
					},
					# Core Unit Identifier
					'dunam' => {
						'one' => q({0} ᏚᎾᎹ),
						'other' => q({0} ᏚᎾᎹᏍ),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ᎮᏔ ᏑᏟᎶᏛ),
						'one' => q({0} ᎮᏔ ᏑᏟᎶᏛ),
						'other' => q({0} ᎮᏔ ᎢᏳᏟᎶᏛ),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ᎮᏔ ᏑᏟᎶᏛ),
						'one' => q({0} ᎮᏔ ᏑᏟᎶᏛ),
						'other' => q({0} ᎮᏔ ᎢᏳᏟᎶᏛ),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'name' => q(ᏅᎩ ᏧᏍᏗ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᏅᎩ ᎤᏍᏗ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏅᎩ ᏧᏍᏗ ᏗᏟᎶᏍᏗ),
						'per' => q({0} ᏅᎩ ᎤᏍᏗ ᎠᏟᎶᏍᏗ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'name' => q(ᏅᎩ ᏧᏍᏗ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᏅᎩ ᎤᏍᏗ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏅᎩ ᏧᏍᏗ ᏗᏟᎶᏍᏗ),
						'per' => q({0} ᏅᎩ ᎤᏍᏗ ᎠᏟᎶᏍᏗ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎢᏗᎳᏏᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎢᏗᎳᏏᏗ),
					},
					# Core Unit Identifier
					'square-foot' => {
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎢᏗᎳᏏᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎢᏗᎳᏏᏗ),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏱ ᎢᏗᏏᏔᏗᏍᏗ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎢᏏᏔᏗᏍᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎢᏗᏏᏔᏗᏍᏗ),
						'per' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎢᏏᏔᏗᏍᏗ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏱ ᎢᏗᏏᏔᏗᏍᏗ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎢᏏᏔᏗᏍᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎢᏗᏏᏔᏗᏍᏗ),
						'per' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎢᏏᏔᏗᏍᏗ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏱ ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎠᎦᏴᎵ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ),
						'per' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎠᎦᏴᎵ ᎠᏟᎶᏍᏗ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏱ ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎠᎦᏴᎵ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ),
						'per' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎠᎦᏴᎵ ᎠᏟᎶᏍᏗ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏱ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᏗᏟᎶᏍᏗ),
						'per' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎠᏟᎶᏍᏗ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏱ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᏗᏟᎶᏍᏗ),
						'per' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎠᏟᎶᏍᏗ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᏑᏟᎶᏓ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎢᏳᏟᎶᏓ),
						'per' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᏑᏟᎶᏓ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'square-mile' => {
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᏑᏟᎶᏓ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᎢᏳᏟᎶᏓ),
						'per' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᏑᏟᎶᏓ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏱ ᏗᏯᏯᏗ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᏯᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᏗᏯᏯᏗ),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏱ ᏗᏯᏯᏗ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᏯᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏱ ᏗᏯᏯᏗ),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'one' => q({0} ᎧᏇᏓ),
						'other' => q({0} ᏗᎧᏇᏓ),
					},
					# Core Unit Identifier
					'karat' => {
						'one' => q({0} ᎧᏇᏓ),
						'other' => q({0} ᏗᎧᏇᏓ),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'name' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎤᏍᏗ ᏂᏚᏓᎨᏒ ᏌᏉ ᎢᏳᎾᏓᎢ ᏍᎪᎯ ᎵᏔᎢ ᎢᏳᏓᎵ),
						'one' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎤᏍᏗ ᎤᏓᎨᏒ ᏌᏉ ᎢᏳᎾᏓᎢ ᏍᎪᎯ ᎵᏔᎢ ᎢᏳᏓᎵ),
						'other' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎤᏍᏗ ᏂᏚᏓᎨᏒ ᏌᏉ ᎢᏳᎾᏓᎢ ᏍᎪᎯ ᎵᏔᎢ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'name' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎤᏍᏗ ᏂᏚᏓᎨᏒ ᏌᏉ ᎢᏳᎾᏓᎢ ᏍᎪᎯ ᎵᏔᎢ ᎢᏳᏓᎵ),
						'one' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎤᏍᏗ ᎤᏓᎨᏒ ᏌᏉ ᎢᏳᎾᏓᎢ ᏍᎪᎯ ᎵᏔᎢ ᎢᏳᏓᎵ),
						'other' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎤᏍᏗ ᏂᏚᏓᎨᏒ ᏌᏉ ᎢᏳᎾᏓᎢ ᏍᎪᎯ ᎵᏔᎢ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎠᏂᎼᎵ ᎵᏔᎢ ᎢᏳᏓᎵ),
						'one' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎼᎵ ᎵᏔᎢ ᎢᏳᏓᎵ),
						'other' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎠᏂᎼᎵ ᎵᏔᎢ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎠᏂᎼᎵ ᎵᏔᎢ ᎢᏳᏓᎵ),
						'one' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎼᎵ ᎵᏔᎢ ᎢᏳᏓᎵ),
						'other' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎠᏂᎼᎵ ᎵᏔᎢ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(ᎼᎴᏍ),
						'one' => q({0} ᎼᎴ),
						'other' => q({0} ᎼᎴᏍ),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(ᎼᎴᏍ),
						'one' => q({0} ᎼᎴ),
						'other' => q({0} ᎼᎴᏍ),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'one' => q({0} ᏓᎬᏩᎶᏛ),
						'other' => q({0} ᏓᎬᏩᎶᏛ),
					},
					# Core Unit Identifier
					'percent' => {
						'one' => q({0} ᏓᎬᏩᎶᏛ),
						'other' => q({0} ᏓᎬᏩᎶᏛ),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'one' => q({0} ᏈᎻᎴ),
						'other' => q({0} ᏈᎻᎴ),
					},
					# Core Unit Identifier
					'permille' => {
						'one' => q({0} ᏈᎻᎴ),
						'other' => q({0} ᏈᎻᎴ),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ᏚᏙᏢᏒ ᎢᏳᏆᏗᏅᏛ ᎢᏳᏓᎵ),
						'one' => q({0} ᎤᏙᏢᏒ ᎢᏳᏆᏗᏅᏛ ᎢᏳᏓᎵ),
						'other' => q({0} ᏚᏙᏢᏒ ᎢᏳᏆᏗᏅᏛ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ᏚᏙᏢᏒ ᎢᏳᏆᏗᏅᏛ ᎢᏳᏓᎵ),
						'one' => q({0} ᎤᏙᏢᏒ ᎢᏳᏆᏗᏅᏛ ᎢᏳᏓᎵ),
						'other' => q({0} ᏚᏙᏢᏒ ᎢᏳᏆᏗᏅᏛ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'one' => q({0} ᏋᎻᎵᎠᏗ),
						'other' => q({0} ᏋᎻᎵᎠᏗ),
					},
					# Core Unit Identifier
					'permyriad' => {
						'one' => q({0} ᏋᎻᎵᎠᏗ),
						'other' => q({0} ᏋᎻᎵᎠᏗ),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(ᏚᏙᏢᏒ ᎢᏳᏓᎵ ᎢᏳᏔᎵᎳᏗᏅᏛ),
						'one' => q({0} ᎤᏙᏢᏒ ᎢᏳᏓᎵ ᎢᏳᏔᎵᎳᏗᏅᏛ),
						'other' => q({0} ᏚᏙᏢᏒ ᎢᏳᏓᎵ ᎢᏳᏔᎵᎳᏗᏅᏛ),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(ᏚᏙᏢᏒ ᎢᏳᏓᎵ ᎢᏳᏔᎵᎳᏗᏅᏛ),
						'one' => q({0} ᎤᏙᏢᏒ ᎢᏳᏓᎵ ᎢᏳᏔᎵᎳᏗᏅᏛ),
						'other' => q({0} ᏚᏙᏢᏒ ᎢᏳᏓᎵ ᎢᏳᏔᎵᎳᏗᏅᏛ),
					},
					# Long Unit Identifier
					'consumption-liter-per-100-kilometer' => {
						'name' => q(ᏗᎵᏔᎢ 100 ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ ᎢᏳᏓᎵ),
						'one' => q({0} ᎵᏔᎢ 100 ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ ᎢᏳᏓᎵ),
						'other' => q({0} ᏗᎵᏔᎢ 100 ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'liter-per-100-kilometer' => {
						'name' => q(ᏗᎵᏔᎢ 100 ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ ᎢᏳᏓᎵ),
						'one' => q({0} ᎵᏔᎢ 100 ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ ᎢᏳᏓᎵ),
						'other' => q({0} ᏗᎵᏔᎢ 100 ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'consumption-liter-per-kilometer' => {
						'name' => q(ᏗᎵᏔᎢ ᎠᎦᏴᎵ ᎠᏟᎶᏍᏗ ᎢᏳᏓᎵ),
						'one' => q({0} ᎵᏔᎢ ᎠᎦᏴᎵ ᎠᏟᎶᏍᏗ ᎢᏳᏓᎵ),
						'other' => q({0} ᏗᎵᏔᎢ ᎠᎦᏴᎵ ᎠᏟᎶᏍᏗ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(ᏗᎵᏔᎢ ᎠᎦᏴᎵ ᎠᏟᎶᏍᏗ ᎢᏳᏓᎵ),
						'one' => q({0} ᎵᏔᎢ ᎠᎦᏴᎵ ᎠᏟᎶᏍᏗ ᎢᏳᏓᎵ),
						'other' => q({0} ᏗᎵᏔᎢ ᎠᎦᏴᎵ ᎠᏟᎶᏍᏗ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(ᎢᏧᏟᎶᏓ ᎢᏳᎵᎶᏓ ᎢᏳᏓᎵ),
						'one' => q({0} ᏑᏟᎶᏓ ᎢᏳᎵᎶᏓ ᎢᏳᏓᎵ),
						'other' => q({0} ᎢᏧᏟᎶᏓ ᎢᏳᎵᎶᏓ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(ᎢᏧᏟᎶᏓ ᎢᏳᎵᎶᏓ ᎢᏳᏓᎵ),
						'one' => q({0} ᏑᏟᎶᏓ ᎢᏳᎵᎶᏓ ᎢᏳᏓᎵ),
						'other' => q({0} ᎢᏧᏟᎶᏓ ᎢᏳᎵᎶᏓ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(ᎢᏧᏟᎶᏓ ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎢᏳᎵᎶᏓ ᎢᏳᏓᎵ),
						'one' => q({0} ᏑᏟᎶᏓ ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎢᏳᎵᎶᏓ ᎢᏳᏓᎵ),
						'other' => q({0} ᎢᏧᏟᎶᏓ ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎢᏳᎵᎶᏓ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(ᎢᏧᏟᎶᏓ ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎢᏳᎵᎶᏓ ᎢᏳᏓᎵ),
						'one' => q({0} ᏑᏟᎶᏓ ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎢᏳᎵᎶᏓ ᎢᏳᏓᎵ),
						'other' => q({0} ᎢᏧᏟᎶᏓ ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎢᏳᎵᎶᏓ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} ᏗᎧᎸᎬ),
						'north' => q({0} ᏧᏴᏢ),
						'south' => q({0} ᏧᎦᏄᏮ),
						'west' => q({0} ᏭᏕᎵᎬ),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} ᏗᎧᎸᎬ),
						'north' => q({0} ᏧᏴᏢ),
						'south' => q({0} ᏧᎦᏄᏮ),
						'west' => q({0} ᏭᏕᎵᎬ),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(ᎤᏍᎦᎵᏨ),
						'one' => q({0} ᎤᏍᎦᎳ),
						'other' => q({0} ᎤᏍᎦᎵᏨ),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(ᎤᏍᎦᎵᏨ),
						'one' => q({0} ᎤᏍᎦᎳ),
						'other' => q({0} ᎤᏍᎦᎵᏨ),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(ᏗᏓᏍᎦᎵᎩ),
						'one' => q({0} ᎠᏍᎦᎳ),
						'other' => q({0} ᏗᏓᏍᎦᎵᎩ),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(ᏗᏓᏍᎦᎵᎩ),
						'one' => q({0} ᎠᏍᎦᎳ),
						'other' => q({0} ᏗᏓᏍᎦᎵᎩ),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(ᎩᎦᎤᏍᎦᎵᏨ),
						'one' => q({0} ᎩᎦᎤᏍᎦᎳ),
						'other' => q({0} ᎩᎦᎤᏍᎦᎵᏨ),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(ᎩᎦᎤᏍᎦᎵᏨ),
						'one' => q({0} ᎩᎦᎤᏍᎦᎳ),
						'other' => q({0} ᎩᎦᎤᏍᎦᎵᏨ),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(ᎩᎦᏗᏓᏍᎦᎵᎩ),
						'one' => q({0} ᎩᎦᎠᏍᎦᎳ),
						'other' => q({0} ᎩᎦᏗᏓᏍᎦᎵᎩ),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(ᎩᎦᏗᏓᏍᎦᎵᎩ),
						'one' => q({0} ᎩᎦᎠᏍᎦᎳ),
						'other' => q({0} ᎩᎦᏗᏓᏍᎦᎵᎩ),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(ᎠᎦᏴᎵ ᎤᏍᎦᎵᏨ),
						'one' => q({0} ᎠᎦᏴᎵ ᎤᏍᎦᎳ),
						'other' => q({0} ᎠᎦᏴᎵ ᎤᏍᎦᎵᏨ),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(ᎠᎦᏴᎵ ᎤᏍᎦᎵᏨ),
						'one' => q({0} ᎠᎦᏴᎵ ᎤᏍᎦᎳ),
						'other' => q({0} ᎠᎦᏴᎵ ᎤᏍᎦᎵᏨ),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(ᎠᎦᏴᎵ ᏗᏓᏍᎦᎵᎩ),
						'one' => q({0} ᎠᎦᏴᎵ ᎠᏍᎦᎳ),
						'other' => q({0} ᎠᎦᏴᎵ ᏗᏓᏍᎦᎵᎩ),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(ᎠᎦᏴᎵ ᏗᏓᏍᎦᎵᎩ),
						'one' => q({0} ᎠᎦᏴᎵ ᎠᏍᎦᎳ),
						'other' => q({0} ᎠᎦᏴᎵ ᏗᏓᏍᎦᎵᎩ),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(ᎺᎦ ᎤᏍᎦᎵᏨ),
						'one' => q({0} ᎺᎦ ᎤᏍᎦᎳ),
						'other' => q({0} ᎺᎦ ᎤᏍᎦᎵᏨ),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(ᎺᎦ ᎤᏍᎦᎵᏨ),
						'one' => q({0} ᎺᎦ ᎤᏍᎦᎳ),
						'other' => q({0} ᎺᎦ ᎤᏍᎦᎵᏨ),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'one' => q({0} ᎺᎦ ᎠᏍᎦᎳ),
						'other' => q({0} ᎺᎦ ᏗᏓᏍᎦᎵᎩ),
					},
					# Core Unit Identifier
					'megabyte' => {
						'one' => q({0} ᎺᎦ ᎠᏍᎦᎳ),
						'other' => q({0} ᎺᎦ ᏗᏓᏍᎦᎵᎩ),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(ᏇᏔ ᏗᏓᏍᎦᎵᎩ),
						'one' => q({0} ᏇᏔ ᏗᏓᏍᎦᎵᎩ),
						'other' => q({0} ᏇᏔ ᏗᏓᏍᎦᎵᎩ),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(ᏇᏔ ᏗᏓᏍᎦᎵᎩ),
						'one' => q({0} ᏇᏔ ᏗᏓᏍᎦᎵᎩ),
						'other' => q({0} ᏇᏔ ᏗᏓᏍᎦᎵᎩ),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(ᏕᎳ ᎤᏍᎦᎵᏨ),
						'one' => q(ᏕᎳ ᎤᏍᎦᎳ),
						'other' => q({0} ᏕᎳ ᎤᏍᎦᎵᏨ),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(ᏕᎳ ᎤᏍᎦᎵᏨ),
						'one' => q(ᏕᎳ ᎤᏍᎦᎳ),
						'other' => q({0} ᏕᎳ ᎤᏍᎦᎵᏨ),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(ᏕᎳ ᏗᏓᏍᎦᎵᎩ),
						'one' => q({0} ᏕᎳ ᎠᏍᎦᎳ),
						'other' => q({0} ᏕᎳ ᏗᏓᏍᎦᎵᎩ),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(ᏕᎳ ᏗᏓᏍᎦᎵᎩ),
						'one' => q({0} ᏕᎳ ᎠᏍᎦᎳ),
						'other' => q({0} ᏕᎳ ᏗᏓᏍᎦᎵᎩ),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(ᏍᎪᎯᏧᏈ ᏧᏕᏘᏴᏓ),
						'one' => q({0} ᏍᎪᎯᏧᏈ ᏧᏕᏘᏴᏓ),
						'other' => q({0} ᏍᎪᎯᏧᏈ ᏧᏕᏘᏴᏓ),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(ᏍᎪᎯᏧᏈ ᏧᏕᏘᏴᏓ),
						'one' => q({0} ᏍᎪᎯᏧᏈ ᏧᏕᏘᏴᏓ),
						'other' => q({0} ᏍᎪᎯᏧᏈ ᏧᏕᏘᏴᏓ),
					},
					# Long Unit Identifier
					'duration-day' => {
						'one' => q({0} ᎢᎦ),
						'other' => q({0} ᎯᎸᏍᎩ ᏧᏒᎯᏓ),
						'per' => q({0} ᎢᎦ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'day' => {
						'one' => q({0} ᎢᎦ),
						'other' => q({0} ᎯᎸᏍᎩ ᏧᏒᎯᏓ),
						'per' => q({0} ᎢᎦ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(ᏍᎪᎯ ᏧᏕᏘᏴᏓ),
						'one' => q({0} ᏍᎪᎯ ᏧᏕᏘᏴᏓ),
						'other' => q({0} ᏍᎪᎯ ᏧᏕᏘᏴᏓ),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(ᏍᎪᎯ ᏧᏕᏘᏴᏓ),
						'one' => q({0} ᏍᎪᎯ ᏧᏕᏘᏴᏓ),
						'other' => q({0} ᏍᎪᎯ ᏧᏕᏘᏴᏓ),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'one' => q({0} ᏑᏟᎶᏓ),
						'other' => q({0} ᎢᏳᏟᎶᏓ),
						'per' => q({0} ᏑᏟᎶᏓ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'hour' => {
						'one' => q({0} ᏑᏟᎶᏓ),
						'other' => q({0} ᎢᏳᏟᎶᏓ),
						'per' => q({0} ᏑᏟᎶᏓ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(ᏌᏉ ᎢᏳᏆᏗᏅᏛ ᏗᏎᏢ),
						'one' => q({0} ᏌᏉ ᎢᏳᏆᏗᏅᏛ ᎠᏎᏢ),
						'other' => q({0} ᏌᏉ ᎢᏳᏆᏗᏅᏛ ᏗᏎᏢ),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(ᏌᏉ ᎢᏳᏆᏗᏅᏛ ᏗᏎᏢ),
						'one' => q({0} ᏌᏉ ᎢᏳᏆᏗᏅᏛ ᎠᏎᏢ),
						'other' => q({0} ᏌᏉ ᎢᏳᏆᏗᏅᏛ ᏗᏎᏢ),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'one' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎠᏎᏢ),
						'other' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᏎᏢ),
					},
					# Core Unit Identifier
					'millisecond' => {
						'one' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎠᏎᏢ),
						'other' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᏎᏢ),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'one' => q({0} ᎢᏯᏔᏬᏍᏔᏅ),
						'other' => q({0} ᎢᏯᏔᏬᏍᏔᏅ),
						'per' => q({0} ᎢᏯᏔᏬᏍᏔᏅ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'minute' => {
						'one' => q({0} ᎢᏯᏔᏬᏍᏔᏅ),
						'other' => q({0} ᎢᏯᏔᏬᏍᏔᏅ),
						'per' => q({0} ᎢᏯᏔᏬᏍᏔᏅ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'duration-month' => {
						'per' => q({0} ᎧᎸᎢ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'month' => {
						'per' => q({0} ᎧᎸᎢ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'one' => q({0} ᎾᏃᎠᏎᏢ),
						'other' => q({0} ᎾᏃᏗᏎᏢ),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'one' => q({0} ᎾᏃᎠᏎᏢ),
						'other' => q({0} ᎾᏃᏗᏎᏢ),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(ᏚᎵᏏᏂᏒ),
						'one' => q({0} ᎤᏒ),
						'other' => q({0} ᏚᎵᏏᏂᏒ),
						'per' => q({0}/ᎤᏒ),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(ᏚᎵᏏᏂᏒ),
						'one' => q({0} ᎤᏒ),
						'other' => q({0} ᏚᎵᏏᏂᏒ),
						'per' => q({0}/ᎤᏒ),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(ᎯᎸᏍᎩ ᎩᏄᏘᏗ),
						'one' => q({0} ᎩᏄᏘᏗ),
						'other' => q({0} ᎯᎸᏍᎩ ᎩᏄᏘᏗ),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(ᎯᎸᏍᎩ ᎩᏄᏘᏗ),
						'one' => q({0} ᎩᏄᏘᏗ),
						'other' => q({0} ᎯᎸᏍᎩ ᎩᏄᏘᏗ),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(ᏗᏎᏢ),
						'one' => q({0} ᎠᏎᏢ),
						'other' => q({0} ᏗᏎᏢ),
						'per' => q({0} ᎠᏎᏢ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(ᏗᏎᏢ),
						'one' => q({0} ᎠᏎᏢ),
						'other' => q({0} ᏗᏎᏢ),
						'per' => q({0} ᎠᏎᏢ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'duration-week' => {
						'one' => q({0} ᏒᎾᏙᏓᏆᏍᏗ),
						'other' => q({0} ᎢᏳᎾᏙᏓᏆᏍᏗ),
						'per' => q({0} ᏒᎾᏙᏓᏆᏍᏗ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'week' => {
						'one' => q({0} ᏒᎾᏙᏓᏆᏍᏗ),
						'other' => q({0} ᎢᏳᎾᏙᏓᏆᏍᏗ),
						'per' => q({0} ᏒᎾᏙᏓᏆᏍᏗ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'duration-year' => {
						'one' => q({0} ᎤᏕᏘᏴᏌᏗᏒᎢ),
						'other' => q({0} ᏧᏕᏘᏴᏌᏗᏒᎢ),
						'per' => q({0} ᎤᏕᏘᏴᏌᏗᏒᎢ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'year' => {
						'one' => q({0} ᎤᏕᏘᏴᏌᏗᏒᎢ),
						'other' => q({0} ᏧᏕᏘᏴᏌᏗᏒᎢ),
						'per' => q({0} ᎤᏕᏘᏴᏌᏗᏒᎢ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(ᏗᎾᎦᎵᏍᎩ ᎠᏟᎶᏍᏗ),
						'one' => q({0} ᎠᎾᎦᎵᏍᎩ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏗᎾᎦᎵᏍᎩ ᎠᏟᎶᏍᏗ),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(ᏗᎾᎦᎵᏍᎩ ᎠᏟᎶᏍᏗ),
						'one' => q({0} ᎠᎾᎦᎵᏍᎩ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏗᎾᎦᎵᏍᎩ ᎠᏟᎶᏍᏗ),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᎾᎦᎵᏍᎩ ᎠᏟᎶᏍᏗ),
						'one' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎠᎾᎦᎵᏍᎩ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᎾᎦᎵᏍᎩ ᎠᏟᎶᏍᏗ),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᎾᎦᎵᏍᎩ ᎠᏟᎶᏍᏗ),
						'one' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎠᎾᎦᎵᏍᎩ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᎾᎦᎵᏍᎩ ᎠᏟᎶᏍᏗ),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'one' => q({0} ᎣᎻ),
						'other' => q({0} ᏗᎣᎻ),
					},
					# Core Unit Identifier
					'ohm' => {
						'one' => q({0} ᎣᎻ),
						'other' => q({0} ᏗᎣᎻ),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'one' => q({0} ᎠᎾᎦᎵᏍᎩ ᎢᏳᏟᏂᎩᏓ),
						'other' => q({0} ᎠᎾᎦᎵᏍᎩ ᎢᏧᏟᏂᏚᏓ),
					},
					# Core Unit Identifier
					'volt' => {
						'one' => q({0} ᎠᎾᎦᎵᏍᎩ ᎢᏳᏟᏂᎩᏓ),
						'other' => q({0} ᎠᎾᎦᎵᏍᎩ ᎢᏧᏟᏂᏚᏓ),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'name' => q(ᏈᏗᏏ ᏗᎬᏍᎦᏢᏗ ᏂᎨᏒᎾ ᏓᎪᎵᏰᎥ ᏭᏍᏗᎬ ᎧᎵᎨᏒ),
						'one' => q({0} ᏈᏗᏏ ᏗᎬᏍᎦᏢᏗ ᏂᎨᏒᎾ ᏓᎪᎵᏰᎥ ᏭᏍᏗᎬ ᎧᎵᎨᏒ),
						'other' => q({0} ᏈᏗᏏ ᏗᎬᏍᎦᏢᏗ ᏂᎨᏒᎾ ᏓᎪᎵᏰᎥ ᏭᏍᏗᎬ ᎧᎵᎨᏒ),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'name' => q(ᏈᏗᏏ ᏗᎬᏍᎦᏢᏗ ᏂᎨᏒᎾ ᏓᎪᎵᏰᎥ ᏭᏍᏗᎬ ᎧᎵᎨᏒ),
						'one' => q({0} ᏈᏗᏏ ᏗᎬᏍᎦᏢᏗ ᏂᎨᏒᎾ ᏓᎪᎵᏰᎥ ᏭᏍᏗᎬ ᎧᎵᎨᏒ),
						'other' => q({0} ᏈᏗᏏ ᏗᎬᏍᎦᏢᏗ ᏂᎨᏒᎾ ᏓᎪᎵᏰᎥ ᏭᏍᏗᎬ ᎧᎵᎨᏒ),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'name' => q(ᏗᏓᎵᏥᏍᏗᏍᎩ),
						'one' => q({0} ᎠᏓᎵᏥᏍᏗᏍᎩ),
						'other' => q({0} ᏗᏓᎵᏥᏍᏗᏍᎩ),
					},
					# Core Unit Identifier
					'calorie' => {
						'name' => q(ᏗᏓᎵᏥᏍᏗᏍᎩ),
						'one' => q({0} ᎠᏓᎵᏥᏍᏗᏍᎩ),
						'other' => q({0} ᏗᏓᎵᏥᏍᏗᏍᎩ),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(ᎡᎴᏆᎾᏉᏔᏍ),
						'one' => q({0} ᎡᎴᏆᎾᏉᏔ),
						'other' => q({0} ᎡᎴᏆᎾᏉᏔᏍ),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(ᎡᎴᏆᎾᏉᏔᏍ),
						'one' => q({0} ᎡᎴᏆᎾᏉᏔ),
						'other' => q({0} ᎡᎴᏆᎾᏉᏔᏍ),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(ᏗᏓᎵᏥᏍᏗᏍᎩ),
						'one' => q({0} ᎠᏓᎵᏥᏍᏗᏍᎩ),
						'other' => q({0} ᏗᏓᎵᏥᏍᏗᏍᎩ),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(ᏗᏓᎵᏥᏍᏗᏍᎩ),
						'one' => q({0} ᎠᏓᎵᏥᏍᏗᏍᎩ),
						'other' => q({0} ᏗᏓᎵᏥᏍᏗᏍᎩ),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'one' => q({0} ᏦᎤᎵ),
						'other' => q({0} ᏗᏦᎤᎵ),
					},
					# Core Unit Identifier
					'joule' => {
						'one' => q({0} ᏦᎤᎵ),
						'other' => q({0} ᏗᏦᎤᎵ),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'name' => q(ᎠᎦᏴᎵ ᏗᏓᎵᏥᏍᏗᏍᎩ),
						'one' => q({0} ᎠᎦᏴᎵ ᎠᏓᎵᏥᏍᏗᏍᎩ),
						'other' => q({0} ᎠᎦᏴᎵ ᏗᏓᎵᏥᏍᏗᏍᎩ),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'name' => q(ᎠᎦᏴᎵ ᏗᏓᎵᏥᏍᏗᏍᎩ),
						'one' => q({0} ᎠᎦᏴᎵ ᎠᏓᎵᏥᏍᏗᏍᎩ),
						'other' => q({0} ᎠᎦᏴᎵ ᏗᏓᎵᏥᏍᏗᏍᎩ),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(ᎠᎦᏴᎵ ᏗᏦᎤᎵ),
						'one' => q({0} ᎠᎦᏴᎵ ᏦᎤᎵ),
						'other' => q({0} ᎠᎦᏴᎵ ᏗᏦᎤᎵ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(ᎠᎦᏴᎵ ᏗᏦᎤᎵ),
						'one' => q({0} ᎠᎦᏴᎵ ᏦᎤᎵ),
						'other' => q({0} ᎠᎦᏴᎵ ᏗᏦᎤᎵ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(ᎠᎦᏴᎵ-ᎢᏧᏟᎶᏓ),
						'one' => q(ᎠᎦᏴᎵ ᎠᏟᎶᏓ),
						'other' => q({0} ᎠᎦᏴᎵ-ᎢᏧᏟᎶᏓ),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(ᎠᎦᏴᎵ-ᎢᏧᏟᎶᏓ),
						'one' => q(ᎠᎦᏴᎵ ᎠᏟᎶᏓ),
						'other' => q({0} ᎠᎦᏴᎵ-ᎢᏧᏟᎶᏓ),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'one' => q({0} US ᎤᏗᏞᎬᎢ),
						'other' => q({0} US ᎤᏗᏞᎬᎢ),
					},
					# Core Unit Identifier
					'therm-us' => {
						'one' => q({0} US ᎤᏗᏞᎬᎢ),
						'other' => q({0} US ᎤᏗᏞᎬᎢ),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'name' => q(ᎠᎦᏴᎵᏩᏘ-ᏑᏟᎶᏓ ᎾᎿ 100 ᎠᎦᏴᎵᎢᏳᏟᎶᏓ),
						'one' => q({0} ᎠᎦᏴᎵᏩᏘ-ᏑᏟᎶᏓ ᎾᎿ 100 ᎠᎦᏴᎵᎢᏳᏟᎶᏓ),
						'other' => q({0} ᎠᎦᏴᎵᏩᏘ-ᏑᏟᎶᏓ ᎾᎿ 100 ᎠᎦᏴᎵᎢᏳᏟᎶᏓ),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'name' => q(ᎠᎦᏴᎵᏩᏘ-ᏑᏟᎶᏓ ᎾᎿ 100 ᎠᎦᏴᎵᎢᏳᏟᎶᏓ),
						'one' => q({0} ᎠᎦᏴᎵᏩᏘ-ᏑᏟᎶᏓ ᎾᎿ 100 ᎠᎦᏴᎵᎢᏳᏟᎶᏓ),
						'other' => q({0} ᎠᎦᏴᎵᏩᏘ-ᏑᏟᎶᏓ ᎾᎿ 100 ᎠᎦᏴᎵᎢᏳᏟᎶᏓ),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(ᏄᏛᏅᏍ),
						'one' => q({0} ᏄᏛᏅ),
						'other' => q({0} ᏄᏛᏅᏍ),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(ᏄᏛᏅᏍ),
						'one' => q({0} ᏄᏛᏅ),
						'other' => q({0} ᏄᏛᏅᏍ),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(ᏑᏓᎨᏓ ᎾᎿ ᎦᏌᏙᏯᏍᏗ),
						'one' => q({0} ᏑᏓᎨᏓ ᎾᎿ ᎦᏌᏙᏯᏍᏗ),
						'other' => q({0} ᏑᏓᎨᏓ ᎾᎿ ᎦᏌᏙᏯᏍᏗ),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(ᏑᏓᎨᏓ ᎾᎿ ᎦᏌᏙᏯᏍᏗ),
						'one' => q({0} ᏑᏓᎨᏓ ᎾᎿ ᎦᏌᏙᏯᏍᏗ),
						'other' => q({0} ᏑᏓᎨᏓ ᎾᎿ ᎦᏌᏙᏯᏍᏗ),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'name' => q(ᎩᎦᎭᏥ),
						'one' => q({0} ᎩᎦᎭᏥ),
						'other' => q({0} ᎩᎦᎭᏥ),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'name' => q(ᎩᎦᎭᏥ),
						'one' => q({0} ᎩᎦᎭᏥ),
						'other' => q({0} ᎩᎦᎭᏥ),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'name' => q(ᎭᏥ),
						'one' => q({0} ᎭᏥ),
						'other' => q({0} ᎭᏥ),
					},
					# Core Unit Identifier
					'hertz' => {
						'name' => q(ᎭᏥ),
						'one' => q({0} ᎭᏥ),
						'other' => q({0} ᎭᏥ),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'name' => q(ᎠᎦᏴᎵᎭᏥ),
						'one' => q({0} ᎠᎦᏴᎵᎭᏥ),
						'other' => q({0} ᎠᎦᏴᎵᎭᏥ),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'name' => q(ᎠᎦᏴᎵᎭᏥ),
						'one' => q({0} ᎠᎦᏴᎵᎭᏥ),
						'other' => q({0} ᎠᎦᏴᎵᎭᏥ),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'name' => q(ᎺᎦᎭᏥ),
						'one' => q({0} ᎺᎦᎭᏥ),
						'other' => q({0} ᎺᎦᎭᏥ),
					},
					# Core Unit Identifier
					'megahertz' => {
						'name' => q(ᎺᎦᎭᏥ),
						'one' => q({0} ᎺᎦᎭᏥ),
						'other' => q({0} ᎺᎦᎭᏥ),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(ᏧᏓᏓᎸ ᎤᏍᏗ ᎠᏟᎶᏗ ᎢᏳᏓᎵ),
						'one' => q({0} ᎤᏓᏓᎸ ᎤᏍᏗ ᎠᏟᎶᏗ ᎢᏳᏓᎵ),
						'other' => q({0} ᏧᏓᏓᎸ ᎤᏍᏗ ᎠᏟᎶᏗ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(ᏧᏓᏓᎸ ᎤᏍᏗ ᎠᏟᎶᏗ ᎢᏳᏓᎵ),
						'one' => q({0} ᎤᏓᏓᎸ ᎤᏍᏗ ᎠᏟᎶᏗ ᎢᏳᏓᎵ),
						'other' => q({0} ᏧᏓᏓᎸ ᎤᏍᏗ ᎠᏟᎶᏗ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(ᏧᏓᏓᎸ ᎢᏏᎳᏗᏍᏗ ᎢᏳᏓᎵ),
						'one' => q({0} ᎤᏓᏓᎸ ᎢᏏᎳᏗᏍᏗ ᎢᏳᏓᎵ),
						'other' => q({0} ᏧᏓᏓᎸ ᎢᏏᎳᏗᏍᏗ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(ᏧᏓᏓᎸ ᎢᏏᎳᏗᏍᏗ ᎢᏳᏓᎵ),
						'one' => q({0} ᎤᏓᏓᎸ ᎢᏏᎳᏗᏍᏗ ᎢᏳᏓᎵ),
						'other' => q({0} ᏧᏓᏓᎸ ᎢᏏᎳᏗᏍᏗ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'graphics-em' => {
						'name' => q(ᎪᏪᎸ em),
					},
					# Core Unit Identifier
					'em' => {
						'name' => q(ᎪᏪᎸ em),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'one' => q({0} ᎤᏔᎾ ᏇᎦᏎᎵ),
						'other' => q({0} ᏧᏔᎾ ᏗᏇᎦᏎᎵ),
					},
					# Core Unit Identifier
					'megapixel' => {
						'one' => q({0} ᎤᏔᎾ ᏇᎦᏎᎵ),
						'other' => q({0} ᏧᏔᎾ ᏗᏇᎦᏎᎵ),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'one' => q({0} ᏇᎦᏎᎵ),
						'other' => q({0} ᏗᏇᎦᏎᎵ),
					},
					# Core Unit Identifier
					'pixel' => {
						'one' => q({0} ᏇᎦᏎᎵ),
						'other' => q({0} ᏗᏇᎦᏎᎵ),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'name' => q(ᏗᏇᎦᏎᎵ ᎤᏍᏗ ᎠᏟᎶᏗ ᎢᏳᏓᎵ),
						'one' => q({0} ᏇᎦᏎᎵ ᎤᏍᏗ ᎠᏟᎶᏗ ᎢᏳᏓᎵ),
						'other' => q({0} ᏗᏇᎦᏎᎵ ᎤᏍᏗ ᎠᏟᎶᏗ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'name' => q(ᏗᏇᎦᏎᎵ ᎤᏍᏗ ᎠᏟᎶᏗ ᎢᏳᏓᎵ),
						'one' => q({0} ᏇᎦᏎᎵ ᎤᏍᏗ ᎠᏟᎶᏗ ᎢᏳᏓᎵ),
						'other' => q({0} ᏗᏇᎦᏎᎵ ᎤᏍᏗ ᎠᏟᎶᏗ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'name' => q(ᏗᏇᎦᏎᎵ ᎢᏏᎳᏗᏍᏗ ᎢᏳᏓᎵ),
						'one' => q({0} ᏇᎦᏎᎵ ᎢᏏᎳᏗᏍᏗ ᎢᏳᏓᎵ),
						'other' => q({0} ᏗᏇᎦᏎᎵ ᎢᏏᎳᏗᏍᏗ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'name' => q(ᏗᏇᎦᏎᎵ ᎢᏏᎳᏗᏍᏗ ᎢᏳᏓᎵ),
						'one' => q({0} ᏇᎦᏎᎵ ᎢᏏᎳᏗᏍᏗ ᎢᏳᏓᎵ),
						'other' => q({0} ᏗᏇᎦᏎᎵ ᎢᏏᎳᏗᏍᏗ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'name' => q(ᎡᎶᎯ ᎠᎴ ᎤᏓ ᏭᏍᏗᎬ ᎧᎵ ᎨᏒᎢ),
						'one' => q({0} ᎡᎶᎯ ᎠᎴ ᎤᏓ ᏭᏍᏗᎬ ᎧᎵ ᎨᏒᎢ),
						'other' => q({0} ᎡᎶᎯ ᎠᎴ ᎤᏓ ᏭᏍᏗᎬ ᎧᎵ ᎨᏒᎢ),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'name' => q(ᎡᎶᎯ ᎠᎴ ᎤᏓ ᏭᏍᏗᎬ ᎧᎵ ᎨᏒᎢ),
						'one' => q({0} ᎡᎶᎯ ᎠᎴ ᎤᏓ ᏭᏍᏗᎬ ᎧᎵ ᎨᏒᎢ),
						'other' => q({0} ᎡᎶᎯ ᎠᎴ ᎤᏓ ᏭᏍᏗᎬ ᎧᎵ ᎨᏒᎢ),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'name' => q(ᏧᏍᏗ ᏗᏟᎶᏗ),
						'one' => q({0} ᎤᏍᏗ ᎠᏟᎶᏗ),
						'other' => q({0} ᏧᏍᏗ ᏗᏟᎶᏗ),
						'per' => q({0} ᎤᏍᏗ ᎠᏟᎶᏗ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'centimeter' => {
						'name' => q(ᏧᏍᏗ ᏗᏟᎶᏗ),
						'one' => q({0} ᎤᏍᏗ ᎠᏟᎶᏗ),
						'other' => q({0} ᏧᏍᏗ ᏗᏟᎶᏗ),
						'per' => q({0} ᎤᏍᏗ ᎠᏟᎶᏗ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(ᏌᏉ ᎢᏳᎾᏓᎢ ᏍᎪᎯ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᏌᏉ ᎢᏳᎾᏓᎢ ᏍᎪᎯ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏌᏉ ᎢᏳᎾᏓᎢ ᏍᎪᎯ ᏗᏟᎶᏍᏗ),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(ᏌᏉ ᎢᏳᎾᏓᎢ ᏍᎪᎯ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᏌᏉ ᎢᏳᎾᏓᎢ ᏍᎪᎯ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏌᏉ ᎢᏳᎾᏓᎢ ᏍᎪᎯ ᏗᏟᎶᏍᏗ),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'name' => q(ᎡᎶᎯ ᏯᏗ),
						'one' => q({0} ᎡᎶᎯ ᏯᏗ),
						'other' => q({0} ᎡᎶᎯ ᏯᏗ),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'name' => q(ᎡᎶᎯ ᏯᏗ),
						'one' => q({0} ᎡᎶᎯ ᏯᏗ),
						'other' => q({0} ᎡᎶᎯ ᏯᏗ),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0} ᏑᏓᎵ ᎢᏗᎳᏏᏗ ᎠᏯᏱ),
						'other' => q({0} ᏑᏓᎵ ᎢᏗᎳᏏᏗ ᎠᏯᏱ),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0} ᏑᏓᎵ ᎢᏗᎳᏏᏗ ᎠᏯᏱ),
						'other' => q({0} ᏑᏓᎵ ᎢᏗᎳᏏᏗ ᎠᏯᏱ),
					},
					# Long Unit Identifier
					'length-foot' => {
						'one' => q({0} ᎢᎳᏏᏗ),
						'other' => q({0} ᎢᏗᎳᏏᏗ),
						'per' => q({0} ᎢᎳᏏᏗ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'foot' => {
						'one' => q({0} ᎢᎳᏏᏗ),
						'other' => q({0} ᎢᏗᎳᏏᏗ),
						'per' => q({0} ᎢᎳᏏᏗ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'one' => q({0} ᎠᏰᏟ ᎩᏄᏘᏗ ᏑᏟᎶᏓ),
						'other' => q({0} ᎠᏰᏟ ᎩᏄᏘᏗ ᎢᏳᏟᎶᏓ),
					},
					# Core Unit Identifier
					'furlong' => {
						'one' => q({0} ᎠᏰᏟ ᎩᏄᏘᏗ ᏑᏟᎶᏓ),
						'other' => q({0} ᎠᏰᏟ ᎩᏄᏘᏗ ᎢᏳᏟᎶᏓ),
					},
					# Long Unit Identifier
					'length-inch' => {
						'one' => q({0} ᎢᏏᏔᏗᏍᏗ),
						'other' => q({0} ᎢᏗᏏᏔᏗᏍᏗ),
						'per' => q({0} ᎢᏏᏔᏗᏍᏗ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'inch' => {
						'one' => q({0} ᎢᏏᏔᏗᏍᏗ),
						'other' => q({0} ᎢᏗᏏᏔᏗᏍᏗ),
						'per' => q({0} ᎢᏏᏔᏗᏍᏗ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᎠᎦᏴᎵ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ),
						'per' => q({0} ᎠᎦᏴᎵ ᎠᏟᎶᏍᏗ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᎠᎦᏴᎵ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ),
						'per' => q({0} ᎠᎦᏴᎵ ᎠᏟᎶᏍᏗ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(ᏗᏨᏍᏗ ᏧᏕᏘᏴᏌᏗᏒᎢ),
						'one' => q({0} ᎠᏨᏍᏗ ᎤᏕᏘᏴᏌᏗᏒᎢ),
						'other' => q({0} ᏗᏨᏍᏗ ᏧᏕᏘᏴᏌᏗᏒᎢ),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(ᏗᏨᏍᏗ ᏧᏕᏘᏴᏌᏗᏒᎢ),
						'one' => q({0} ᎠᏨᏍᏗ ᎤᏕᏘᏴᏌᏗᏒᎢ),
						'other' => q({0} ᏗᏨᏍᏗ ᏧᏕᏘᏴᏌᏗᏒᎢ),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏗᏟᎶᏍᏗ),
						'per' => q({0} ᎠᏟᎶᏍᏗ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏗᏟᎶᏍᏗ),
						'per' => q({0} ᎠᏟᎶᏍᏗ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'name' => q(ᏌᏉ ᎢᏳᏆᏗᏅᏛ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᏌᏉ ᎢᏳᏆᏗᏅᏛ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏌᏉ ᎢᏳᏆᏗᏅᏛ ᏗᏟᎶᏍᏗ),
					},
					# Core Unit Identifier
					'micrometer' => {
						'name' => q(ᏌᏉ ᎢᏳᏆᏗᏅᏛ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᏌᏉ ᎢᏳᏆᏗᏅᏛ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏌᏉ ᎢᏳᏆᏗᏅᏛ ᏗᏟᎶᏍᏗ),
					},
					# Long Unit Identifier
					'length-mile' => {
						'one' => q({0} ᏑᏟᎶᏓ),
						'other' => q({0} ᎢᏳᏟᎶᏓ),
					},
					# Core Unit Identifier
					'mile' => {
						'one' => q({0} ᏑᏟᎶᏓ),
						'other' => q({0} ᎢᏳᏟᎶᏓ),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'name' => q(ᏑᏟᎶᏓ-ᏍᎦᎾᏗᎾᏫᎠᏂ),
						'one' => q({0} ᏑᏟᎶᏓ-ᏍᎦᎾᏗᎾᏫᎠᏂ),
						'other' => q({0} ᎢᏳᏟᎶᏓ-ᏍᎦᎾᏗᎾᏫᎠᏂ),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'name' => q(ᏑᏟᎶᏓ-ᏍᎦᎾᏗᎾᏫᎠᏂ),
						'one' => q({0} ᏑᏟᎶᏓ-ᏍᎦᎾᏗᎾᏫᎠᏂ),
						'other' => q({0} ᎢᏳᏟᎶᏓ-ᏍᎦᎾᏗᎾᏫᎠᏂ),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᏟᎶᏍᏗ),
						'one' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᏟᎶᏍᏗ),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᏟᎶᏍᏗ),
						'one' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᏟᎶᏍᏗ),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'name' => q(ᎾᏃ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᎾᏃ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᎾᏃ ᏗᏟᎶᏍᏗ),
					},
					# Core Unit Identifier
					'nanometer' => {
						'name' => q(ᎾᏃ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᎾᏃ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᎾᏃ ᏗᏟᎶᏍᏗ),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'name' => q(ᎠᎺᏉᎯ ᎢᏳᏟᎶᏓ),
						'one' => q({0} ᎠᎺᏉᎯ ᏑᏟᎶᏓ),
						'other' => q({0} ᎠᎺᏉᎯ ᎢᏳᏟᎶᏓ),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'name' => q(ᎠᎺᏉᎯ ᎢᏳᏟᎶᏓ),
						'one' => q({0} ᎠᎺᏉᎯ ᏑᏟᎶᏓ),
						'other' => q({0} ᎠᎺᏉᎯ ᎢᏳᏟᎶᏓ),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q({0} ᎢᏯᏆᏎᎦ),
						'other' => q({0} ᎢᏯᏆᏎᎦ),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q({0} ᎢᏯᏆᏎᎦ),
						'other' => q({0} ᎢᏯᏆᏎᎦ),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'name' => q(ᏇᎪ ᎢᏯᎦᎨᎵᏁᎢ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᏇᎪ ᎢᏯᎦᎨᎵᏁᎢ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏇᎪ ᎢᏯᎦᎨᎵᏁᎢ ᏗᏟᎶᏍᏗ),
					},
					# Core Unit Identifier
					'picometer' => {
						'name' => q(ᏇᎪ ᎢᏯᎦᎨᎵᏁᎢ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᏇᎪ ᎢᏯᎦᎨᎵᏁᎢ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏇᎪ ᎢᏯᎦᎨᎵᏁᎢ ᏗᏟᎶᏍᏗ),
					},
					# Long Unit Identifier
					'length-point' => {
						'one' => q({0} ᎤᏓᏓᏟ),
						'other' => q({0} ᏧᏓᏓᏟ),
					},
					# Core Unit Identifier
					'point' => {
						'one' => q({0} ᎤᏓᏓᏟ),
						'other' => q({0} ᏧᏓᏓᏟ),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'one' => q({0} ᏅᏓ ᏇᏗ),
						'other' => q({0} ᏅᏓ ᏇᏗ),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'one' => q({0} ᏅᏓ ᏇᏗ),
						'other' => q({0} ᏅᏓ ᏇᏗ),
					},
					# Long Unit Identifier
					'length-yard' => {
						'one' => q({0} ᏯᏗ),
						'other' => q({0} ᎢᏯᏯᏗ),
					},
					# Core Unit Identifier
					'yard' => {
						'one' => q({0} ᏯᏗ),
						'other' => q({0} ᎢᏯᏯᏗ),
					},
					# Long Unit Identifier
					'light-candela' => {
						'name' => q(ᎧᏂᏕᎳ),
						'one' => q({0} ᎧᏂᏕᎳ),
						'other' => q({0} ᎧᏂᏕᎳ),
					},
					# Core Unit Identifier
					'candela' => {
						'name' => q(ᎧᏂᏕᎳ),
						'one' => q({0} ᎧᏂᏕᎳ),
						'other' => q({0} ᎧᏂᏕᎳ),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'name' => q(ᎷᎺᏂ),
						'one' => q({0} ᎷᎺᏂ),
						'other' => q({0} ᎷᎺᏂ),
					},
					# Core Unit Identifier
					'lumen' => {
						'name' => q(ᎷᎺᏂ),
						'one' => q({0} ᎷᎺᏂ),
						'other' => q({0} ᎷᎺᏂ),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'one' => q({0} ᏅᏓ ᎠᏨᏍᏗ),
						'other' => q({0} ᏅᏓ ᏗᏨᏍᏗ),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'one' => q({0} ᏅᏓ ᎠᏨᏍᏗ),
						'other' => q({0} ᏅᏓ ᏗᏨᏍᏗ),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'one' => q({0} ᎨᏇᏓ),
						'other' => q({0} ᏗᎨᏇᏓ),
					},
					# Core Unit Identifier
					'carat' => {
						'one' => q({0} ᎨᏇᏓ),
						'other' => q({0} ᏗᎨᏇᏓ),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'one' => q({0} ᏓᏙᎾᏍ),
						'other' => q({0} ᏓᏙᎾᏍ),
					},
					# Core Unit Identifier
					'dalton' => {
						'one' => q({0} ᏓᏙᎾᏍ),
						'other' => q({0} ᏓᏙᎾᏍ),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'one' => q({0} ᎡᎶᎯ ᎹᏏ),
						'other' => q({0} ᎡᎶᎯ ᎹᏏ),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'one' => q({0} ᎡᎶᎯ ᎹᏏ),
						'other' => q({0} ᎡᎶᎯ ᎹᏏ),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'one' => q({0} ᎤᏍᏗ ᎤᏓᎨᏒ),
						'other' => q({0} ᎤᏍᏗ ᏂᏚᏓᎨᏒ),
						'per' => q({0} ᎤᏍᏗ ᎤᏓᎨᏒ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'gram' => {
						'one' => q({0} ᎤᏍᏗ ᎤᏓᎨᏒ),
						'other' => q({0} ᎤᏍᏗ ᏂᏚᏓᎨᏒ),
						'per' => q({0} ᎤᏍᏗ ᎤᏓᎨᏒ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'name' => q(ᎠᎦᏴᎵ ᎤᏍᏗ ᏂᏚᏓᎨᏒ),
						'one' => q({0} ᎠᎦᏴᎵ ᎤᏍᏗ ᎤᏓᎨᏒ),
						'other' => q({0} ᎠᎦᏴᎵ ᎤᏍᏗ ᏂᏚᏓᎨᏒ),
						'per' => q({0} ᎠᎦᏴᎵ ᎤᏍᏗ ᎤᏓᎨᏒ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'kilogram' => {
						'name' => q(ᎠᎦᏴᎵ ᎤᏍᏗ ᏂᏚᏓᎨᏒ),
						'one' => q({0} ᎠᎦᏴᎵ ᎤᏍᏗ ᎤᏓᎨᏒ),
						'other' => q({0} ᎠᎦᏴᎵ ᎤᏍᏗ ᏂᏚᏓᎨᏒ),
						'per' => q({0} ᎠᎦᏴᎵ ᎤᏍᏗ ᎤᏓᎨᏒ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'name' => q(ᏌᏉ ᎢᏳᏆᏗᏅᏛ ᎤᏍᏗ ᏂᏚᏓᎨᏒ),
						'one' => q({0} ᏌᏉ ᎢᏳᏆᏗᏅᏛ ᎤᏍᏗ ᎤᏓᎨᏒ),
						'other' => q({0} ᏌᏉ ᎢᏳᏆᏗᏅᏛ ᎤᏍᏗ ᏂᏚᏓᎨᏒ),
					},
					# Core Unit Identifier
					'microgram' => {
						'name' => q(ᏌᏉ ᎢᏳᏆᏗᏅᏛ ᎤᏍᏗ ᏂᏚᏓᎨᏒ),
						'one' => q({0} ᏌᏉ ᎢᏳᏆᏗᏅᏛ ᎤᏍᏗ ᎤᏓᎨᏒ),
						'other' => q({0} ᏌᏉ ᎢᏳᏆᏗᏅᏛ ᎤᏍᏗ ᏂᏚᏓᎨᏒ),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'name' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎤᏍᏗ ᏂᏚᏓᎨᏒ),
						'one' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎤᏍᏗ ᎤᏓᎨᏒ),
						'other' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎤᏍᏗ ᏂᏚᏓᎨᏒ),
					},
					# Core Unit Identifier
					'milligram' => {
						'name' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎤᏍᏗ ᏂᏚᏓᎨᏒ),
						'one' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎤᏍᏗ ᎤᏓᎨᏒ),
						'other' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎤᏍᏗ ᏂᏚᏓᎨᏒ),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'name' => q(ᎢᏯᎣᏂᏏ),
						'one' => q({0} ᎣᏂᏏ),
						'other' => q({0} ᎢᏯᎣᏂᏏ),
						'per' => q({0} ᎣᏂᏏ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'ounce' => {
						'name' => q(ᎢᏯᎣᏂᏏ),
						'one' => q({0} ᎣᏂᏏ),
						'other' => q({0} ᎢᏯᎣᏂᏏ),
						'per' => q({0} ᎣᏂᏏ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(ᏆᏯ ᎢᏯᎣᏂᏏ),
						'one' => q({0} ᏆᏯ ᎣᏂᏏ),
						'other' => q({0} ᏆᏯ ᎢᏯᎣᏂᏏ),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(ᏆᏯ ᎢᏯᎣᏂᏏ),
						'one' => q({0} ᏆᏯ ᎣᏂᏏ),
						'other' => q({0} ᏆᏯ ᎢᏯᎣᏂᏏ),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'one' => q({0} ᏑᏓᎨᏓ),
						'other' => q({0} ᎢᏧᏓᎨᏓ),
						'per' => q({0} ᎢᏧᏓᎨᏓ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'pound' => {
						'one' => q({0} ᏑᏓᎨᏓ),
						'other' => q({0} ᎢᏧᏓᎨᏓ),
						'per' => q({0} ᎢᏧᏓᎨᏓ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'one' => q({0} ᏅᏓ ᎹᏏ),
						'other' => q({0} ᏅᏓ ᎹᏏ),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'one' => q({0} ᏅᏓ ᎹᏏ),
						'other' => q({0} ᏅᏓ ᎹᏏ),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'one' => q({0} ᏅᏯ),
						'other' => q({0} ᎠᏂᏅᏯ),
					},
					# Core Unit Identifier
					'stone' => {
						'one' => q({0} ᏅᏯ),
						'other' => q({0} ᎠᏂᏅᏯ),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0} ᏈᏂ),
						'other' => q({0} ᏗᏈᏂ),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0} ᏈᏂ),
						'other' => q({0} ᏗᏈᏂ),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'name' => q(ᎠᏂᎩᎸᏥ ᏂᏓᏳᏓᎴᏅᎯ ᏗᏎᏍᏗ ᏗᏈᏂ),
						'one' => q({0} ᎠᏂᎩᎸᏥ ᏂᏓᏳᏓᎴᏅᎯ ᏗᏎᏍᏗ ᏈᏂ),
						'other' => q({0} ᎠᏂᎩᎸᏥ ᏂᏓᏳᏓᎴᏅᎯ ᏗᏎᏍᏗ ᏗᏈᏂ),
					},
					# Core Unit Identifier
					'tonne' => {
						'name' => q(ᎠᏂᎩᎸᏥ ᏂᏓᏳᏓᎴᏅᎯ ᏗᏎᏍᏗ ᏗᏈᏂ),
						'one' => q({0} ᎠᏂᎩᎸᏥ ᏂᏓᏳᏓᎴᏅᎯ ᏗᏎᏍᏗ ᏈᏂ),
						'other' => q({0} ᎠᏂᎩᎸᏥ ᏂᏓᏳᏓᎴᏅᎯ ᏗᏎᏍᏗ ᏗᏈᏂ),
					},
					# Long Unit Identifier
					'per' => {
						'1' => q({0} ᎾᎿ {1}),
					},
					# Core Unit Identifier
					'per' => {
						'1' => q({0} ᎾᎿ {1}),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'name' => q(ᎩᎦᏩᏗ),
						'one' => q({0} ᎩᎦᏩᏗ),
						'other' => q({0} ᎩᎦᏩᏗ),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'name' => q(ᎩᎦᏩᏗ),
						'one' => q({0} ᎩᎦᏩᏗ),
						'other' => q({0} ᎩᎦᏩᏗ),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'name' => q(ᏐᏈᎵ ᎢᏳᎳᏂᎩᏛ),
						'one' => q({0} ᏐᏈᎵ ᎢᏳᎳᏂᎩᏛ),
						'other' => q({0} ᏐᏈᎵ ᎢᏳᎳᏂᎩᏛ),
					},
					# Core Unit Identifier
					'horsepower' => {
						'name' => q(ᏐᏈᎵ ᎢᏳᎳᏂᎩᏛ),
						'one' => q({0} ᏐᏈᎵ ᎢᏳᎳᏂᎩᏛ),
						'other' => q({0} ᏐᏈᎵ ᎢᏳᎳᏂᎩᏛ),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'name' => q(ᎠᎦᏴᎵ ᏗᏩᏗ),
						'one' => q({0} ᎠᎦᏴᎵ ᏩᏗ),
						'other' => q({0} ᎠᎦᏴᎵ ᏗᏩᏗ),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'name' => q(ᎠᎦᏴᎵ ᏗᏩᏗ),
						'one' => q({0} ᎠᎦᏴᎵ ᏩᏗ),
						'other' => q({0} ᎠᎦᏴᎵ ᏗᏩᏗ),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'name' => q(ᎺᎦ ᏗᏩᏗ),
						'one' => q({0} ᎺᎦ ᏩᏗ),
						'other' => q({0} ᎺᎦ ᏗᏩᏗ),
					},
					# Core Unit Identifier
					'megawatt' => {
						'name' => q(ᎺᎦ ᏗᏩᏗ),
						'one' => q({0} ᎺᎦ ᏩᏗ),
						'other' => q({0} ᎺᎦ ᏗᏩᏗ),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'name' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᏩᏗ),
						'one' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏩᏗ),
						'other' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᏩᏗ),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'name' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᏩᏗ),
						'one' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏩᏗ),
						'other' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᏩᏗ),
					},
					# Long Unit Identifier
					'power-watt' => {
						'one' => q({0} ᏗᏩᏗ),
						'other' => q({0} ᏗᏩᏗ),
					},
					# Core Unit Identifier
					'watt' => {
						'one' => q({0} ᏗᏩᏗ),
						'other' => q({0} ᏗᏩᏗ),
					},
					# Long Unit Identifier
					'power2' => {
						'1' => q(ᏅᎩ ᏧᏅᏏᏯ {0}),
						'one' => q(ᏅᎩ ᏧᏅᏏᏱ {0}),
						'other' => q(ᏅᎩ ᏧᏅᏏᏱ {0}),
					},
					# Core Unit Identifier
					'power2' => {
						'1' => q(ᏅᎩ ᏧᏅᏏᏯ {0}),
						'one' => q(ᏅᎩ ᏧᏅᏏᏱ {0}),
						'other' => q(ᏅᎩ ᏧᏅᏏᏱ {0}),
					},
					# Long Unit Identifier
					'power3' => {
						'1' => q(cubic {0}),
						'one' => q(ᏣᏁᎳ ᏧᏅᏏᏱ {0}),
						'other' => q(ᏣᏁᎳ ᏧᏅᏏᏱ {0}),
					},
					# Core Unit Identifier
					'power3' => {
						'1' => q(cubic {0}),
						'one' => q(ᏣᏁᎳ ᏧᏅᏏᏱ {0}),
						'other' => q(ᏣᏁᎳ ᏧᏅᏏᏱ {0}),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'name' => q(ᏗᎦᏃᎴᏍᎬ),
						'one' => q({0} ᎦᏃᎴᏍᎬ),
						'other' => q({0} ᏗᎦᏃᎴᏍᎬ),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'name' => q(ᏗᎦᏃᎴᏍᎬ),
						'one' => q({0} ᎦᏃᎴᏍᎬ),
						'other' => q({0} ᏗᎦᏃᎴᏍᎬ),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(ᏕᎦᎾᎸᎢ),
						'one' => q({0} ᎦᎾᎸᎢ),
						'other' => q({0} ᏕᎦᎾᎸᎢ),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(ᏕᎦᎾᎸᎢ),
						'one' => q({0} ᎦᎾᎸᎢ),
						'other' => q({0} ᏕᎦᎾᎸᎢ),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'name' => q(ᎮᏔ ᏗᏆᏌᎵ),
						'one' => q({0} ᎮᏔ ᏆᏌᎵ),
						'other' => q({0} ᎮᏔ ᏗᏆᏌᎵ),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'name' => q(ᎮᏔ ᏗᏆᏌᎵ),
						'one' => q({0} ᎮᏔ ᏆᏌᎵ),
						'other' => q({0} ᎮᏔ ᏗᏆᏌᎵ),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(ᎢᏏᏔᏗᏍᏗ ᎾᎿ ᎹᎫᎢ),
						'one' => q({0} ᎢᏗᎳᏏᏗ ᎾᎿ ᎹᎫᎢ),
						'other' => q({0} ᎢᏏᏔᏗᏍᏗ ᎾᎿ ᎹᎫᎢ),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(ᎢᏏᏔᏗᏍᏗ ᎾᎿ ᎹᎫᎢ),
						'one' => q({0} ᎢᏗᎳᏏᏗ ᎾᎿ ᎹᎫᎢ),
						'other' => q({0} ᎢᏏᏔᏗᏍᏗ ᎾᎿ ᎹᎫᎢ),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'name' => q(ᎩᎶᏆᏍᎧᎵᏍ),
						'one' => q({0} ᎩᎶᏆᏍᎧᎵᏍ),
						'other' => q({0} ᎩᎶᏆᏍᎧᎵᏍ),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'name' => q(ᎩᎶᏆᏍᎧᎵᏍ),
						'one' => q({0} ᎩᎶᏆᏍᎧᎵᏍ),
						'other' => q({0} ᎩᎶᏆᏍᎧᎵᏍ),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'name' => q(ᎺᎦᏆᏍᎧᎵᏍ),
						'one' => q({0} ᎺᎦᏆᏍᎧᎵᏍ),
						'other' => q({0} ᎺᎦᏆᏍᎧᎵᏍ),
					},
					# Core Unit Identifier
					'megapascal' => {
						'name' => q(ᎺᎦᏆᏍᎧᎵᏍ),
						'one' => q({0} ᎺᎦᏆᏍᎧᎵᏍ),
						'other' => q({0} ᎺᎦᏆᏍᎧᎵᏍ),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'name' => q(ᎢᏯᎦᏴᎵ ᏕᎦᎾᎸᎢ),
						'one' => q({0} ᎢᎦᎦᏴᎵ ᎦᎾᎸᎢ),
						'other' => q({0} ᎢᏯᎦᏴᎵ ᏕᎦᎾᎸᎢ),
					},
					# Core Unit Identifier
					'millibar' => {
						'name' => q(ᎢᏯᎦᏴᎵ ᏕᎦᎾᎸᎢ),
						'one' => q({0} ᎢᎦᎦᏴᎵ ᎦᎾᎸᎢ),
						'other' => q({0} ᎢᏯᎦᏴᎵ ᏕᎦᎾᎸᎢ),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'name' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᏟᎶᏗ ᎾᎿ ᎹᎫᎢ),
						'one' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎠᏟᎶᏗ ᎾᎿ ᎹᎫᎢ),
						'other' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᏟᎶᏗ ᎾᎿ ᎹᎫᎢ),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'name' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᏟᎶᏗ ᎾᎿ ᎹᎫᎢ),
						'one' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎠᏟᎶᏗ ᎾᎿ ᎹᎫᎢ),
						'other' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᏟᎶᏗ ᎾᎿ ᎹᎫᎢ),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'name' => q(ᏗᏆᏌᎵ),
						'one' => q({0} ᏆᏌᎵ),
						'other' => q({0} ᏗᏆᏌᎵ),
					},
					# Core Unit Identifier
					'pascal' => {
						'name' => q(ᏗᏆᏌᎵ),
						'one' => q({0} ᏆᏌᎵ),
						'other' => q({0} ᏗᏆᏌᎵ),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'name' => q(ᎢᏧᏓᎨᏓ ᏅᎩ ᏧᏅᏏᎩ ᎢᏏᏔᏗᏍᏗ ᎢᏳᏓᎵ),
						'one' => q({0} ᏑᏓᎨᏓ ᏅᎩ ᏧᏅᏏᎩ ᎢᏏᏔᏗᏍᏗ ᎢᏳᏓᎵ),
						'other' => q({0} ᎢᏧᏓᎨᏓ ᏅᎩ ᏧᏅᏏᎩ ᎢᏏᏔᏗᏍᏗ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'name' => q(ᎢᏧᏓᎨᏓ ᏅᎩ ᏧᏅᏏᎩ ᎢᏏᏔᏗᏍᏗ ᎢᏳᏓᎵ),
						'one' => q({0} ᏑᏓᎨᏓ ᏅᎩ ᏧᏅᏏᎩ ᎢᏏᏔᏗᏍᏗ ᎢᏳᏓᎵ),
						'other' => q({0} ᎢᏧᏓᎨᏓ ᏅᎩ ᏧᏅᏏᎩ ᎢᏏᏔᏗᏍᏗ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'name' => q(ᏉᏙᎢ),
						'one' => q(ᏉᏙᎢ {0}),
						'other' => q(ᏉᏙᎢ {0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'name' => q(ᏉᏙᎢ),
						'one' => q(ᏉᏙᎢ {0}),
						'other' => q(ᏉᏙᎢ {0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ ᏑᏟᎶᏓ ᎢᏳᏓᎵ),
						'one' => q({0} ᎠᎦᏴᎵ ᎠᏟᎶᏍᏗ ᏑᏟᎶᏓ ᎢᏳᏓᎵ),
						'other' => q({0} ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ ᏑᏟᎶᏓ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ ᏑᏟᎶᏓ ᎢᏳᏓᎵ),
						'one' => q({0} ᎠᎦᏴᎵ ᎠᏟᎶᏍᏗ ᏑᏟᎶᏓ ᎢᏳᏓᎵ),
						'other' => q({0} ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ ᏑᏟᎶᏓ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'name' => q(ᏓᎧᏁᎲ),
						'one' => q({0} ᎠᎧᏁᎲ),
						'other' => q({0} ᏓᎧᏁᎲ),
					},
					# Core Unit Identifier
					'knot' => {
						'name' => q(ᏓᎧᏁᎲ),
						'one' => q({0} ᎠᎧᏁᎲ),
						'other' => q({0} ᏓᎧᏁᎲ),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(ᎠᏨᏍᏗ),
						'one' => q({0} ᎠᏨᏍᏗ),
						'other' => q({0} ᎠᏨᏍᏗ),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(ᎠᏨᏍᏗ),
						'one' => q({0} ᎠᏨᏍᏗ),
						'other' => q({0} ᎠᏨᏍᏗ),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(ᏗᏟᎶᏗ ᎠᏎᏢ ᎢᏳᏓᎵ),
						'one' => q({0} ᎠᏟᎶᏗ ᎠᏎᏢ ᎢᏳᏓᎵ),
						'other' => q({0} ᏗᏟᎶᏗ ᎠᏎᏢ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(ᏗᏟᎶᏗ ᎠᏎᏢ ᎢᏳᏓᎵ),
						'one' => q({0} ᎠᏟᎶᏗ ᎠᏎᏢ ᎢᏳᏓᎵ),
						'other' => q({0} ᏗᏟᎶᏗ ᎠᏎᏢ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(ᎢᏧᏟᎶᏓ ᏑᏟᎶᏛ ᎢᏳᏓᎵ),
						'one' => q({0} ᏑᏟᎶᏓ ᏑᏟᎶᏛ ᎢᏳᏓᎵ),
						'other' => q({0} ᎢᏧᏟᎶᏓ ᏑᏟᎶᏛ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(ᎢᏧᏟᎶᏓ ᏑᏟᎶᏛ ᎢᏳᏓᎵ),
						'one' => q({0} ᏑᏟᎶᏓ ᏑᏟᎶᏛ ᎢᏳᏓᎵ),
						'other' => q({0} ᎢᏧᏟᎶᏓ ᏑᏟᎶᏛ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(ᎢᎦᎢ ᎢᏗᎦᏘ ᎠᏤ ᎠᏟᎶᏍᏙᏗ),
						'one' => q({0} ᎢᎦᎢ ᎢᎦ ᎠᏤ ᎠᏟᎶᏍᏙᏗ),
						'other' => q({0} ᎢᎦᎢ ᎢᏗᎦᏘ ᎠᏤ ᎠᏟᎶᏍᏙᏗ),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(ᎢᎦᎢ ᎢᏗᎦᏘ ᎠᏤ ᎠᏟᎶᏍᏙᏗ),
						'one' => q({0} ᎢᎦᎢ ᎢᎦ ᎠᏤ ᎠᏟᎶᏍᏙᏗ),
						'other' => q({0} ᎢᎦᎢ ᎢᏗᎦᏘ ᎠᏤ ᎠᏟᎶᏍᏙᏗ),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(ᎢᎦᎢ ᎢᏗᎦᏘ ᏅᎦᏃᏋ ᎠᎴ ᏅᏴᏢ ᎠᏟᎶᏍᏙᏗ),
						'one' => q(ᎢᎦᎢ ᎢᎦ ᏅᎦᏃᏋ ᎠᎴ ᏅᏴᏢ ᎠᏟᎶᏍᏙᏗ),
						'other' => q({0} ᎢᎦᎢ ᎢᏗᎦᏘ ᏅᎦᏃᏋ ᎠᎴ ᏅᏴᏢ ᎠᏟᎶᏍᏙᏗ),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(ᎢᎦᎢ ᎢᏗᎦᏘ ᏅᎦᏃᏋ ᎠᎴ ᏅᏴᏢ ᎠᏟᎶᏍᏙᏗ),
						'one' => q(ᎢᎦᎢ ᎢᎦ ᏅᎦᏃᏋ ᎠᎴ ᏅᏴᏢ ᎠᏟᎶᏍᏙᏗ),
						'other' => q({0} ᎢᎦᎢ ᎢᏗᎦᏘ ᏅᎦᏃᏋ ᎠᎴ ᏅᏴᏢ ᎠᏟᎶᏍᏙᏗ),
					},
					# Long Unit Identifier
					'temperature-kelvin' => {
						'name' => q(ᎢᏗᎨᎸᏂ),
						'one' => q({0} ᎨᎸᏂ),
						'other' => q({0} ᎢᏗᎨᎸᏂ),
					},
					# Core Unit Identifier
					'kelvin' => {
						'name' => q(ᎢᏗᎨᎸᏂ),
						'one' => q({0} ᎨᎸᏂ),
						'other' => q({0} ᎢᏗᎨᎸᏂ),
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
						'name' => q(ᏄᏛᏅ-ᎠᏟᎶᏍᏗ),
						'one' => q({0} ᏄᏛᏅ-ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏄᏛᏅ-ᎠᏟᎶᏍᏗ),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'name' => q(ᏄᏛᏅ-ᎠᏟᎶᏍᏗ),
						'one' => q({0} ᏄᏛᏅ-ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏄᏛᏅ-ᎠᏟᎶᏍᏗ),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'name' => q(ᏑᏓᎨᏓ-ᏧᎳᏏᏕᏂ),
						'one' => q({0} ᏑᏓᎨᏓ-ᎤᎳᏏᏕᏂ),
						'other' => q({0} ᏑᏓᎨᏓ-ᏧᎳᏏᏕᏂ),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'name' => q(ᏑᏓᎨᏓ-ᏧᎳᏏᏕᏂ),
						'one' => q({0} ᏑᏓᎨᏓ-ᎤᎳᏏᏕᏂ),
						'other' => q({0} ᏑᏓᎨᏓ-ᏧᎳᏏᏕᏂ),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'one' => q({0} ᏑᏟᎶᏛ-ᎢᎳᏏᏗ),
						'other' => q({0} ᏑᏟᎶᏛ-ᎢᏗᎳᏏᏗ),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'one' => q({0} ᏑᏟᎶᏛ-ᎢᎳᏏᏗ),
						'other' => q({0} ᏑᏟᎶᏛ-ᎢᏗᎳᏏᏗ),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(ᏧᏒᏙᏂ),
						'one' => q({0} ᏒᏙᏂ),
						'other' => q({0} ᏧᏒᏙᏂ),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(ᏧᏒᏙᏂ),
						'one' => q({0} ᏒᏙᏂ),
						'other' => q({0} ᏧᏒᏙᏂ),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0} ᎤᎧᏲᏗ ᏑᏟᎶᏓ),
						'other' => q({0} ᎤᎧᏲᏗ ᏑᏟᎶᏓ),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q({0} ᎤᎧᏲᏗ ᏑᏟᎶᏓ),
						'other' => q({0} ᎤᎧᏲᏗ ᏑᏟᎶᏓ),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'name' => q(ᏧᎤᏍᏗ ᏗᎵᏔᎢ),
						'one' => q({0} ᎤᏍᏗ ᎵᏔᎢ),
						'other' => q({0} ᏧᎤᏍᏗ ᏗᎵᏔᎢ),
					},
					# Core Unit Identifier
					'centiliter' => {
						'name' => q(ᏧᎤᏍᏗ ᏗᎵᏔᎢ),
						'one' => q({0} ᎤᏍᏗ ᎵᏔᎢ),
						'other' => q({0} ᏧᎤᏍᏗ ᏗᎵᏔᎢ),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏯ ᏧᏍᏗ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎤᏍᏗ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᏧᏍᏗ ᏗᏟᎶᏍᏗ),
						'per' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎤᏍᏗ ᎠᏟᎶᏍᏗ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏯ ᏧᏍᏗ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎤᏍᏗ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᏧᏍᏗ ᏗᏟᎶᏍᏗ),
						'per' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎤᏍᏗ ᎠᏟᎶᏍᏗ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏯ ᎢᏗᎳᏏᏗ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎢᎳᏏᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎢᏗᎳᏏᏗ),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏯ ᎢᏗᎳᏏᏗ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎢᎳᏏᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎢᏗᎳᏏᏗ),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏯ ᎢᏗᏏᏔᏗᏍᏗ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎢᏏᏔᏗᏍᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎢᏗᏏᏔᏗᏍᏗ),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏯ ᎢᏗᏏᏔᏗᏍᏗ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎢᏏᏔᏗᏍᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎢᏗᏏᏔᏗᏍᏗ),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏯ ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎠᎦᏴᎵ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏯ ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎠᎦᏴᎵ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎠᎦᏴᎵ ᏗᏟᎶᏍᏗ),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏯ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᏗᏟᎶᏍᏗ),
						'per' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎠᏟᎶᏍᏗ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏯ ᏗᏟᎶᏍᏗ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎠᏟᎶᏍᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᏗᏟᎶᏍᏗ),
						'per' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎠᏟᎶᏍᏗ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏯ ᎢᏳᏟᎶᏓ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᏑᏟᎶᏓ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎤᏍᏗ ᎢᏳᏟᎶᏓ),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏯ ᎢᏳᏟᎶᏓ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᏑᏟᎶᏓ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎤᏍᏗ ᎢᏳᏟᎶᏓ),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏯ ᎢᏯᏯᏗ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᏯᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎢᏯᏯᏗ),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏯ ᎢᏯᏯᏗ),
						'one' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᏯᏗ),
						'other' => q({0} ᏅᎩ ᏧᏅᏏᏯ ᎢᏯᏯᏗ),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'one' => q({0} ᎤᎵᏍᏈᏗ),
						'other' => q({0} ᏧᎵᏍᏈᏗ),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q({0} ᎤᎵᏍᏈᏗ),
						'other' => q({0} ᏧᎵᏍᏈᏗ),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'name' => q(ᎠᏂᎩᎸᏥ ᏂᏓᏳᏓᎴᏅᎯ ᏗᏎᏍᏗ ᏧᎵᏍᏈᏗ),
						'one' => q({0} ᎠᏂᎩᎸᏥ ᏂᏓᏳᏓᎴᏅᎯ ᏗᏎᏍᏗ ᎤᎵᏍᏈᏗ),
						'other' => q({0} ᎠᏂᎩᎸᏥ ᏂᏓᏳᏓᎴᏅᎯ ᏗᏎᏍᏗ ᏧᎵᏍᏈᏗ),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'name' => q(ᎠᏂᎩᎸᏥ ᏂᏓᏳᏓᎴᏅᎯ ᏗᏎᏍᏗ ᏧᎵᏍᏈᏗ),
						'one' => q({0} ᎠᏂᎩᎸᏥ ᏂᏓᏳᏓᎴᏅᎯ ᏗᏎᏍᏗ ᎤᎵᏍᏈᏗ),
						'other' => q({0} ᎠᏂᎩᎸᏥ ᏂᏓᏳᏓᎴᏅᎯ ᏗᏎᏍᏗ ᏧᎵᏍᏈᏗ),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'name' => q(ᏌᏉ ᎢᏳᎾᏓᎢ ᏍᎪᎯ ᎢᏧᏆᏗᏅᏛ),
						'one' => q({0} ᏌᏉ ᎢᏳᎾᏓᎢ ᏍᎪᎯ ᎢᏳᏆᏗᏅᏛ),
						'other' => q({0} ᏌᏉ ᎢᏳᎾᏓᎢ ᏍᎪᎯ ᎢᏧᏆᏗᏅᏛ),
					},
					# Core Unit Identifier
					'deciliter' => {
						'name' => q(ᏌᏉ ᎢᏳᎾᏓᎢ ᏍᎪᎯ ᎢᏧᏆᏗᏅᏛ),
						'one' => q({0} ᏌᏉ ᎢᏳᎾᏓᎢ ᏍᎪᎯ ᎢᏳᏆᏗᏅᏛ),
						'other' => q({0} ᏌᏉ ᎢᏳᎾᏓᎢ ᏍᎪᎯ ᎢᏧᏆᏗᏅᏛ),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(ᎤᎦᎾᏍᏓ ᎠᏗᏙᏗ),
						'one' => q({0} ᎤᎦᎾᏍᏓ ᎠᏗᏙᏗ),
						'other' => q({0} ᎤᎦᎾᏍᏓ ᎠᏗᏙᏗ),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(ᎤᎦᎾᏍᏓ ᎠᏗᏙᏗ),
						'one' => q({0} ᎤᎦᎾᏍᏓ ᎠᏗᏙᏗ),
						'other' => q({0} ᎤᎦᎾᏍᏓ ᎠᏗᏙᏗ),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎤᎦᎾᏍᏓ ᎠᏗᏙᏗ),
						'one' => q({0} ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎤᎦᎾᏍᏓ ᎠᏗᏙᏗ),
						'other' => q({0} ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎤᎦᎾᏍᏓ ᎠᏗᏙᏗ),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎤᎦᎾᏍᏓ ᎠᏗᏙᏗ),
						'one' => q({0} ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎤᎦᎾᏍᏓ ᎠᏗᏙᏗ),
						'other' => q({0} ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎤᎦᎾᏍᏓ ᎠᏗᏙᏗ),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(ᏜᎹ),
						'one' => q({0} ᏜᎹ),
						'other' => q({0} ᏜᎹ),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(ᏜᎹ),
						'one' => q({0} ᏜᎹ),
						'other' => q({0} ᏜᎹ),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'name' => q(ᎤᏓᏁᎯ ᎢᏯᎣᏂᏏ),
						'one' => q({0} ᎤᏓᏁᎯ ᎣᏂᏏ),
						'other' => q({0} ᎤᏓᏁᎯ ᎢᏯᎣᏂᏏ),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'name' => q(ᎤᏓᏁᎯ ᎢᏯᎣᏂᏏ),
						'one' => q({0} ᎤᏓᏁᎯ ᎣᏂᏏ),
						'other' => q({0} ᎤᏓᏁᎯ ᎢᏯᎣᏂᏏ),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp. ᎤᏓᏁᎯ ᎢᏯᎣᏂᏏ),
						'one' => q({0} Imp. ᎤᏓᏁᎯ ᎣᏂᏏ),
						'other' => q({0} Imp. ᎤᏓᏁᎯ ᎢᏯᎣᏂᏏ),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp. ᎤᏓᏁᎯ ᎢᏯᎣᏂᏏ),
						'one' => q({0} Imp. ᎤᏓᏁᎯ ᎣᏂᏏ),
						'other' => q({0} Imp. ᎤᏓᏁᎯ ᎢᏯᎣᏂᏏ),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'one' => q({0} ᎢᏳᎵᎶᏓ),
						'other' => q({0} ᎢᏧᎵᎶᏓ),
						'per' => q({0} ᎢᏳᎵᎶᏓ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'gallon' => {
						'one' => q({0} ᎢᏳᎵᎶᏓ),
						'other' => q({0} ᎢᏧᎵᎶᏓ),
						'per' => q({0} ᎢᏳᎵᎶᏓ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎢᏧᎵᎶᏓ),
						'one' => q({0} ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎢᏳᎵᎶᏓ),
						'other' => q({0} ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎢᏧᎵᎶᏓ),
						'per' => q({0} ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎢᏳᎵᎶᏓ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎢᏧᎵᎶᏓ),
						'one' => q({0} ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎢᏳᎵᎶᏓ),
						'other' => q({0} ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎢᏧᎵᎶᏓ),
						'per' => q({0} ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎢᏳᎵᎶᏓ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'name' => q(ᎮᏙ ᎢᏧᏆᏗᏅᏛ),
						'one' => q({0} ᎮᏙ ᎢᏳᏆᏗᏅᏛ),
						'other' => q({0} ᎮᏙ ᎢᏧᏆᏗᏅᏛ),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'name' => q(ᎮᏙ ᎢᏧᏆᏗᏅᏛ),
						'one' => q({0} ᎮᏙ ᎢᏳᏆᏗᏅᏛ),
						'other' => q({0} ᎮᏙ ᎢᏧᏆᏗᏅᏛ),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'one' => q({0} ᎢᏳᏆᏗᏅᏛ),
						'other' => q({0} ᎢᏧᏆᏗᏅᏛ),
						'per' => q({0} ᎢᏳᏆᏗᏅᏛ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'liter' => {
						'one' => q({0} ᎢᏳᏆᏗᏅᏛ),
						'other' => q({0} ᎢᏧᏆᏗᏅᏛ),
						'per' => q({0} ᎢᏳᏆᏗᏅᏛ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'name' => q(ᎺᎦ ᎢᏧᏆᏗᏅᏛ),
						'one' => q({0} ᎺᎦ ᎢᏳᏆᏗᏅᏛ),
						'other' => q({0} ᎺᎦ ᎢᏧᏆᏗᏅᏛ),
					},
					# Core Unit Identifier
					'megaliter' => {
						'name' => q(ᎺᎦ ᎢᏧᏆᏗᏅᏛ),
						'one' => q({0} ᎺᎦ ᎢᏳᏆᏗᏅᏛ),
						'other' => q({0} ᎺᎦ ᎢᏧᏆᏗᏅᏛ),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'name' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᎵᏔᎵ),
						'one' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎵᏔᎢ),
						'other' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᎵᏔᎵ),
					},
					# Core Unit Identifier
					'milliliter' => {
						'name' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᎵᏔᎵ),
						'one' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎵᏔᎢ),
						'other' => q({0} ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᎵᏔᎵ),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'one' => q({0} ᏔᎵ ᎤᎵᏍᏈᏗ ᎠᎧᎵ),
						'other' => q({0} ᏔᎵ ᏧᎵᏍᏈᏗ ᎠᎧᎵ),
					},
					# Core Unit Identifier
					'pint' => {
						'one' => q({0} ᏔᎵ ᎤᎵᏍᏈᏗ ᎠᎧᎵ),
						'other' => q({0} ᏔᎵ ᏧᎵᏍᏈᏗ ᎠᎧᎵ),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'name' => q(ᎠᏂᎩᎸᏥ ᏂᏓᏳᏓᎴᏅᎯ ᏗᏎᏍᏗ ᏔᎵ ᏧᎵᏍᏈᏗ ᎠᎧᎵ),
						'one' => q({0} ᎠᏂᎩᎸᏥ ᏂᏓᏳᏓᎴᏅᎯ ᏗᏎᏍᏗ ᏔᎵ ᎤᎵᏍᏈᏗ ᎠᎧᎵ),
						'other' => q({0} ᎠᏂᎩᎸᏥ ᏂᏓᏳᏓᎴᏅᎯ ᏗᏎᏍᏗ ᏔᎵ ᏧᎵᏍᏈᏗ ᎠᎧᎵ),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'name' => q(ᎠᏂᎩᎸᏥ ᏂᏓᏳᏓᎴᏅᎯ ᏗᏎᏍᏗ ᏔᎵ ᏧᎵᏍᏈᏗ ᎠᎧᎵ),
						'one' => q({0} ᎠᏂᎩᎸᏥ ᏂᏓᏳᏓᎴᏅᎯ ᏗᏎᏍᏗ ᏔᎵ ᎤᎵᏍᏈᏗ ᎠᎧᎵ),
						'other' => q({0} ᎠᏂᎩᎸᏥ ᏂᏓᏳᏓᎴᏅᎯ ᏗᏎᏍᏗ ᏔᎵ ᏧᎵᏍᏈᏗ ᎠᎧᎵ),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(ᏅᎩ ᎢᏗᎧᎵᎢ),
						'one' => q({0} ᏅᎩ ᎢᏯᎧᎵᎢ),
						'other' => q({0} ᏅᎩ ᎢᏗᎧᎵᎢ),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(ᏅᎩ ᎢᏗᎧᎵᎢ),
						'one' => q({0} ᏅᎩ ᎢᏯᎧᎵᎢ),
						'other' => q({0} ᏅᎩ ᎢᏗᎧᎵᎢ),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'name' => q(ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᏅᎩ ᎢᏗᎧᎵᎢ),
						'one' => q({0} ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᏅᎩ ᎢᏗᎧᎵᎢ),
						'other' => q({0} ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᏅᎩ ᎢᏗᎧᎵᎢ),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'name' => q(ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᏅᎩ ᎢᏗᎧᎵᎢ),
						'one' => q({0} ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᏅᎩ ᎢᏗᎧᎵᎢ),
						'other' => q({0} ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᏅᎩ ᎢᏗᎧᎵᎢ),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'name' => q(ᎤᏔᏂ ᏗᏗᏙᏗ),
						'one' => q({0} ᎤᏔᏂ ᎠᏗᏙᏗ),
						'other' => q({0} ᎤᏔᏂ ᏗᏗᏙᏗ),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'name' => q(ᎤᏔᏂ ᏗᏗᏙᏗ),
						'one' => q({0} ᎤᏔᏂ ᎠᏗᏙᏗ),
						'other' => q({0} ᎤᏔᏂ ᏗᏗᏙᏗ),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'name' => q(ᎤᏍᏗ ᏗᏗᏙᏗ),
						'one' => q({0} ᎤᏍᏗ ᎠᏗᏙᏗ),
						'other' => q({0} ᎤᏍᏗ ᏗᏗᏙᏗ),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'name' => q(ᎤᏍᏗ ᏗᏗᏙᏗ),
						'one' => q({0} ᎤᏍᏗ ᎠᏗᏙᏗ),
						'other' => q({0} ᎤᏍᏗ ᏗᏗᏙᏗ),
					},
				},
				'narrow' => {
					# Long Unit Identifier
					'acceleration-g-force' => {
						'one' => q({0}G),
						'other' => q({0}Gs),
					},
					# Core Unit Identifier
					'g-force' => {
						'one' => q({0}G),
						'other' => q({0}Gs),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(m/s²),
						'one' => q({0}m/s²),
						'other' => q({0}m/s²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(arcmin),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(arcmin),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(arcsec),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(arcsec),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(deg),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(deg),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(rad),
						'one' => q({0}rad),
						'other' => q({0}rad),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(rad),
						'one' => q({0}rad),
						'other' => q({0}rad),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(rev),
						'one' => q({0}rev),
						'other' => q({0}rev),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(rev),
						'one' => q({0}rev),
						'other' => q({0}rev),
					},
					# Long Unit Identifier
					'area-acre' => {
						'one' => q({0}ac),
						'other' => q({0}ac),
					},
					# Core Unit Identifier
					'acre' => {
						'one' => q({0}ac),
						'other' => q({0}ac),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(ᏚᎾᎹ),
						'one' => q({0}ᏚᎾᎹ),
						'other' => q({0}ᏚᎾᎹ),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(ᏚᎾᎹ),
						'one' => q({0}ᏚᎾᎹ),
						'other' => q({0}ᏚᎾᎹ),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					# Core Unit Identifier
					'hectare' => {
						'one' => q({0}ha),
						'other' => q({0}ha),
					},
					# Long Unit Identifier
					'area-square-centimeter' => {
						'one' => q({0}cm²),
						'other' => q({0}cm²),
					},
					# Core Unit Identifier
					'square-centimeter' => {
						'one' => q({0}cm²),
						'other' => q({0}cm²),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ft²),
						'one' => q({0}ft²),
						'other' => q({0}ft²),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ft²),
						'one' => q({0}ft²),
						'other' => q({0}ft²),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(in²),
						'one' => q({0}in²),
						'other' => q({0}in²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(in²),
						'one' => q({0}in²),
						'other' => q({0}in²),
					},
					# Long Unit Identifier
					'area-square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
					},
					# Core Unit Identifier
					'square-kilometer' => {
						'one' => q({0}km²),
						'other' => q({0}km²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'one' => q({0}m²),
						'other' => q({0}m²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(mi²),
						'one' => q({0}mi²),
						'other' => q({0}mi²),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0}mi²),
						'other' => q({0}mi²),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(yd²),
						'one' => q({0}yd²),
						'other' => q({0}yd²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0}yd²),
						'other' => q({0}yd²),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(ᎧᏇᏓ),
						'one' => q({0}kt),
						'other' => q({0}kt),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(ᎧᏇᏓ),
						'one' => q({0}kt),
						'other' => q({0}kt),
					},
					# Long Unit Identifier
					'concentr-milligram-ofglucose-per-deciliter' => {
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
					},
					# Core Unit Identifier
					'milligram-ofglucose-per-deciliter' => {
						'one' => q({0}mg/dL),
						'other' => q({0}mg/dL),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0}mmol/L),
						'other' => q({0}mmol/L),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(mmol/L),
						'one' => q({0}mmol/L),
						'other' => q({0}mmol/L),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(mol),
						'one' => q({0}mol),
						'other' => q({0}mol),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(mol),
						'one' => q({0}mol),
						'other' => q({0}mol),
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
						'name' => q(ppm),
						'one' => q({0}ppm),
						'other' => q({0}ppm),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ppm),
						'one' => q({0}ppm),
						'other' => q({0}ppm),
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
						'one' => q({0}ppb),
						'other' => q({0}ppb),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'one' => q({0}ppb),
						'other' => q({0}ppb),
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
						'one' => q({0}L/km),
						'other' => q({0}L/km),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(L/km),
						'one' => q({0}L/km),
						'other' => q({0}L/km),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0}mpg),
						'other' => q({0}mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0}mpg),
						'other' => q({0}mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(mpg UK),
						'one' => q({0}m/gUK),
						'other' => q({0}m/gUK),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(mpg UK),
						'one' => q({0}m/gUK),
						'other' => q({0}m/gUK),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0}Ꮧ),
						'north' => q({0}ᏧᏴ),
						'south' => q({0}ᏧᎦ),
						'west' => q({0}Ꮽ),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0}Ꮧ),
						'north' => q({0}ᏧᏴ),
						'south' => q({0}ᏧᎦ),
						'west' => q({0}Ꮽ),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'one' => q({0}ᎤᏍᎦᎳ),
						'other' => q({0}ᎤᏍᎦᎳ),
					},
					# Core Unit Identifier
					'bit' => {
						'one' => q({0}ᎤᏍᎦᎳ),
						'other' => q({0}ᎤᏍᎦᎳ),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(B),
						'one' => q({0}B),
						'other' => q({0}B),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(B),
						'one' => q({0}B),
						'other' => q({0}B),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(Gb),
						'one' => q({0}Gb),
						'other' => q({0}Gb),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(Gb),
						'one' => q({0}Gb),
						'other' => q({0}Gb),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(GB),
						'one' => q({0}GB),
						'other' => q({0}GB),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(GB),
						'one' => q({0}GB),
						'other' => q({0}GB),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(kb),
						'one' => q({0}kb),
						'other' => q({0}kb),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(kb),
						'one' => q({0}kb),
						'other' => q({0}kb),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(kB),
						'one' => q({0}kB),
						'other' => q({0}kB),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(kB),
						'one' => q({0}kB),
						'other' => q({0}kB),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(Mb),
						'one' => q({0}Mb),
						'other' => q({0}Mb),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(Mb),
						'one' => q({0}Mb),
						'other' => q({0}Mb),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(MB),
						'one' => q({0}MB),
						'other' => q({0}MB),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(MB),
						'one' => q({0}MB),
						'other' => q({0}MB),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PB),
						'one' => q({0}PB),
						'other' => q({0}PB),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PB),
						'one' => q({0}PB),
						'other' => q({0}PB),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(Tb),
						'one' => q({0}Tb),
						'other' => q({0}Tb),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(Tb),
						'one' => q({0}Tb),
						'other' => q({0}Tb),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(TB),
						'one' => q({0}TB),
						'other' => q({0}TB),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(TB),
						'one' => q({0}TB),
						'other' => q({0}TB),
					},
					# Long Unit Identifier
					'duration-century' => {
						'one' => q({0}ᏍᏧ),
						'other' => q({0}ᏍᏧ),
					},
					# Core Unit Identifier
					'century' => {
						'one' => q({0}ᏍᏧ),
						'other' => q({0}ᏍᏧ),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ᎢᎦ),
						'one' => q({0}Ꭲ),
						'other' => q({0}Ꭲ),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ᎢᎦ),
						'one' => q({0}Ꭲ),
						'other' => q({0}Ꭲ),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'one' => q({0}ᏍᎪᎯ),
						'other' => q({0}ᏍᎪᎯ),
					},
					# Core Unit Identifier
					'decade' => {
						'one' => q({0}ᏍᎪᎯ),
						'other' => q({0}ᏍᎪᎯ),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ᏑᏟᎶᏓ),
						'one' => q({0}Ꮡ),
						'other' => q({0}Ꮡ),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ᏑᏟᎶᏓ),
						'one' => q({0}Ꮡ),
						'other' => q({0}Ꮡ),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'one' => q({0}μs),
						'other' => q({0}μs),
					},
					# Core Unit Identifier
					'microsecond' => {
						'one' => q({0}μs),
						'other' => q({0}μs),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ᏌᎠ),
						'one' => q({0}ᏌᎠ),
						'other' => q({0}ᏌᎠ),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ᏌᎠ),
						'one' => q({0}ᏌᎠ),
						'other' => q({0}ᏌᎠ),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(ᎢᏯᏔ),
						'one' => q({0}Ꭲ),
						'other' => q({0}Ꭲ),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(ᎢᏯᏔ),
						'one' => q({0}Ꭲ),
						'other' => q({0}Ꭲ),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(ᎧᎸᎢ),
						'one' => q({0}Ꭷ),
						'other' => q({0}Ꭷ),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(ᎧᎸᎢ),
						'one' => q({0}Ꭷ),
						'other' => q({0}Ꭷ),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'one' => q({0}ᎾᏃ),
						'other' => q({0}ᎾᏃ),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'one' => q({0}ᎾᏃ),
						'other' => q({0}ᎾᏃ),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(ᏚᎵᏏᏂᏒ),
						'one' => q({0}ᎤᏒ),
						'other' => q({0}ᏚᎵᏏᏂᏒ),
						'per' => q({0}/ᎤᏒ),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(ᏚᎵᏏᏂᏒ),
						'one' => q({0}ᎤᏒ),
						'other' => q({0}ᏚᎵᏏᏂᏒ),
						'per' => q({0}/ᎤᏒ),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'one' => q({0}Ꭿ),
						'other' => q({0}Ꭿ),
					},
					# Core Unit Identifier
					'quarter' => {
						'one' => q({0}Ꭿ),
						'other' => q({0}Ꭿ),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(ᎠᏎᏢ),
						'one' => q({0}ᎠᏎ),
						'other' => q({0}ᎠᏎ),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(ᎠᏎᏢ),
						'one' => q({0}ᎠᏎ),
						'other' => q({0}ᎠᏎ),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(ᏒᎾ),
						'one' => q({0}Ꮢ),
						'other' => q({0}Ꮢ),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(ᏒᎾ),
						'one' => q({0}Ꮢ),
						'other' => q({0}Ꮢ),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ᎤᏕ),
						'one' => q({0}Ꭴ),
						'other' => q({0}Ꭴ),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ᎤᏕ),
						'one' => q({0}Ꭴ),
						'other' => q({0}Ꭴ),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amp),
						'one' => q({0}A),
						'other' => q({0}A),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amp),
						'one' => q({0}A),
						'other' => q({0}A),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(mA),
						'one' => q({0}mA),
						'other' => q({0}mA),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0}mA),
						'other' => q({0}mA),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ᎣᎻ),
						'one' => q({0}Ω),
						'other' => q({0}Ω),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ᎣᎻ),
						'one' => q({0}Ω),
						'other' => q({0}Ω),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(ᎠᎾᎦᎵᏍᎩ ᎢᏳᏟᏂᏚᏓ),
						'one' => q({0}V),
						'other' => q({0}V),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(ᎠᎾᎦᎵᏍᎩ ᎢᏳᏟᏂᏚᏓ),
						'one' => q({0}V),
						'other' => q({0}V),
					},
					# Long Unit Identifier
					'energy-british-thermal-unit' => {
						'one' => q({0}Btu),
						'other' => q({0}Btu),
					},
					# Core Unit Identifier
					'british-thermal-unit' => {
						'one' => q({0}Btu),
						'other' => q({0}Btu),
					},
					# Long Unit Identifier
					'energy-calorie' => {
						'one' => q({0}cal),
						'other' => q({0}cal),
					},
					# Core Unit Identifier
					'calorie' => {
						'one' => q({0}cal),
						'other' => q({0}cal),
					},
					# Long Unit Identifier
					'energy-electronvolt' => {
						'name' => q(eV),
						'one' => q({0}eV),
						'other' => q({0}eV),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(eV),
						'one' => q({0}eV),
						'other' => q({0}eV),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'one' => q({0}Cal),
						'other' => q({0}Cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'one' => q({0}Cal),
						'other' => q({0}Cal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(ᏦᎤᎵ),
						'one' => q({0}J),
						'other' => q({0}J),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(ᏦᎤᎵ),
						'one' => q({0}J),
						'other' => q({0}J),
					},
					# Long Unit Identifier
					'energy-kilocalorie' => {
						'one' => q({0}kcal),
						'other' => q({0}kcal),
					},
					# Core Unit Identifier
					'kilocalorie' => {
						'one' => q({0}kcal),
						'other' => q({0}kcal),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(kJ),
						'one' => q({0}kJ),
						'other' => q({0}kJ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(kJ),
						'one' => q({0}kJ),
						'other' => q({0}kJ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0}kWh),
						'other' => q({0}kWh),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0}kWh),
						'other' => q({0}kWh),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'one' => q({0}US ᎤᏗᏞᎬ),
						'other' => q({0}US ᎤᏗᏞᎬ),
					},
					# Core Unit Identifier
					'therm-us' => {
						'one' => q({0}US ᎤᏗᏞᎬ),
						'other' => q({0}US ᎤᏗᏞᎬ),
					},
					# Long Unit Identifier
					'force-kilowatt-hour-per-100-kilometer' => {
						'one' => q({0}kWh/100km),
						'other' => q({0}kWh/100km),
					},
					# Core Unit Identifier
					'kilowatt-hour-per-100-kilometer' => {
						'one' => q({0}kWh/100km),
						'other' => q({0}kWh/100km),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(N),
						'one' => q({0}N),
						'other' => q({0}N),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(N),
						'one' => q({0}N),
						'other' => q({0}N),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(lbf),
						'one' => q({0}lbf),
						'other' => q({0}lbf),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(lbf),
						'one' => q({0}lbf),
						'other' => q({0}lbf),
					},
					# Long Unit Identifier
					'frequency-gigahertz' => {
						'one' => q({0}GHz),
						'other' => q({0}GHz),
					},
					# Core Unit Identifier
					'gigahertz' => {
						'one' => q({0}GHz),
						'other' => q({0}GHz),
					},
					# Long Unit Identifier
					'frequency-hertz' => {
						'one' => q({0}Hz),
						'other' => q({0}Hz),
					},
					# Core Unit Identifier
					'hertz' => {
						'one' => q({0}Hz),
						'other' => q({0}Hz),
					},
					# Long Unit Identifier
					'frequency-kilohertz' => {
						'one' => q({0}kHz),
						'other' => q({0}kHz),
					},
					# Core Unit Identifier
					'kilohertz' => {
						'one' => q({0}kHz),
						'other' => q({0}kHz),
					},
					# Long Unit Identifier
					'frequency-megahertz' => {
						'one' => q({0}MHz),
						'other' => q({0}MHz),
					},
					# Core Unit Identifier
					'megahertz' => {
						'one' => q({0}MHz),
						'other' => q({0}MHz),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'one' => q({0}dpcm),
						'other' => q({0}dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'one' => q({0}dpcm),
						'other' => q({0}dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'one' => q({0}dpi),
						'other' => q({0}dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'one' => q({0}dpi),
						'other' => q({0}dpi),
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
					'graphics-pixel' => {
						'name' => q(px),
						'one' => q({0}px),
						'other' => q({0}px),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(px),
						'one' => q({0}px),
						'other' => q({0}px),
					},
					# Long Unit Identifier
					'graphics-pixel-per-centimeter' => {
						'one' => q({0}ppcm),
						'other' => q({0}ppcm),
					},
					# Core Unit Identifier
					'pixel-per-centimeter' => {
						'one' => q({0}ppcm),
						'other' => q({0}ppcm),
					},
					# Long Unit Identifier
					'graphics-pixel-per-inch' => {
						'one' => q({0}ppi),
						'other' => q({0}ppi),
					},
					# Core Unit Identifier
					'pixel-per-inch' => {
						'one' => q({0}ppi),
						'other' => q({0}ppi),
					},
					# Long Unit Identifier
					'length-astronomical-unit' => {
						'one' => q({0}au),
						'other' => q({0}au),
					},
					# Core Unit Identifier
					'astronomical-unit' => {
						'one' => q({0}au),
						'other' => q({0}au),
					},
					# Long Unit Identifier
					'length-centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					# Core Unit Identifier
					'centimeter' => {
						'one' => q({0}cm),
						'other' => q({0}cm),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'one' => q({0}ᏌᏟ),
						'other' => q({0}ᏌᏟ),
					},
					# Core Unit Identifier
					'decimeter' => {
						'one' => q({0}ᏌᏟ),
						'other' => q({0}ᏌᏟ),
					},
					# Long Unit Identifier
					'length-earth-radius' => {
						'one' => q({0}R⊕),
						'other' => q({0}R⊕),
					},
					# Core Unit Identifier
					'earth-radius' => {
						'one' => q({0}R⊕),
						'other' => q({0}R⊕),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'one' => q({0}fth),
						'other' => q({0}fth),
					},
					# Core Unit Identifier
					'fathom' => {
						'one' => q({0}fth),
						'other' => q({0}fth),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ft),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ft),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(ᎠᏰᏟ ᎩᏄᏘᏗ ᏑᏟᎶᏓ),
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(ᎠᏰᏟ ᎩᏄᏘᏗ ᏑᏟᎶᏓ),
						'one' => q({0}fur),
						'other' => q({0}fur),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(in),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(in),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'one' => q({0}ᎠᏗ),
						'other' => q({0}ᎠᏗ),
					},
					# Core Unit Identifier
					'kilometer' => {
						'one' => q({0}ᎠᏗ),
						'other' => q({0}ᎠᏗ),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(ly),
						'one' => q({0}ly),
						'other' => q({0}ly),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(ly),
						'one' => q({0}ly),
						'other' => q({0}ly),
					},
					# Long Unit Identifier
					'length-meter' => {
						'one' => q({0}ᎠᏟ),
						'other' => q({0}ᎠᏟ),
					},
					# Core Unit Identifier
					'meter' => {
						'one' => q({0}ᎠᏟ),
						'other' => q({0}ᎠᏟ),
					},
					# Long Unit Identifier
					'length-micrometer' => {
						'one' => q({0}μm),
						'other' => q({0}μm),
					},
					# Core Unit Identifier
					'micrometer' => {
						'one' => q({0}μm),
						'other' => q({0}μm),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(mi),
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(mi),
						'one' => q({0}mi),
						'other' => q({0}mi),
					},
					# Long Unit Identifier
					'length-mile-scandinavian' => {
						'one' => q({0}smi),
						'other' => q({0}smi),
					},
					# Core Unit Identifier
					'mile-scandinavian' => {
						'one' => q({0}smi),
						'other' => q({0}smi),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'one' => q({0}ᏌᎢᎠ),
						'other' => q({0}ᏌᎢᎠ),
					},
					# Core Unit Identifier
					'millimeter' => {
						'one' => q({0}ᏌᎢᎠ),
						'other' => q({0}ᏌᎢᎠ),
					},
					# Long Unit Identifier
					'length-nanometer' => {
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					# Core Unit Identifier
					'nanometer' => {
						'one' => q({0}nm),
						'other' => q({0}nm),
					},
					# Long Unit Identifier
					'length-nautical-mile' => {
						'one' => q({0}nmi),
						'other' => q({0}nmi),
					},
					# Core Unit Identifier
					'nautical-mile' => {
						'one' => q({0}nmi),
						'other' => q({0}nmi),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'one' => q({0}pc),
						'other' => q({0}pc),
					},
					# Core Unit Identifier
					'parsec' => {
						'one' => q({0}pc),
						'other' => q({0}pc),
					},
					# Long Unit Identifier
					'length-picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					# Core Unit Identifier
					'picometer' => {
						'one' => q({0}pm),
						'other' => q({0}pm),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(pts),
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(pts),
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(R☉),
						'one' => q({0}R☉),
						'other' => q({0}R☉),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(R☉),
						'one' => q({0}R☉),
						'other' => q({0}R☉),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(yd),
						'one' => q({0}yd),
						'other' => q({0}yd),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(yd),
						'one' => q({0}yd),
						'other' => q({0}yd),
					},
					# Long Unit Identifier
					'light-candela' => {
						'one' => q({0}cd),
						'other' => q({0}cd),
					},
					# Core Unit Identifier
					'candela' => {
						'one' => q({0}cd),
						'other' => q({0}cd),
					},
					# Long Unit Identifier
					'light-lumen' => {
						'one' => q({0}lm),
						'other' => q({0}lm),
					},
					# Core Unit Identifier
					'lumen' => {
						'one' => q({0}lm),
						'other' => q({0}lm),
					},
					# Long Unit Identifier
					'light-lux' => {
						'one' => q({0}lx),
						'other' => q({0}lx),
					},
					# Core Unit Identifier
					'lux' => {
						'one' => q({0}lx),
						'other' => q({0}lx),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(L☉),
						'one' => q({0}L☉),
						'other' => q({0}L☉),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(L☉),
						'one' => q({0}L☉),
						'other' => q({0}L☉),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(ᎨᏇᏓ),
						'one' => q({0}CD),
						'other' => q({0}CD),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(ᎨᏇᏓ),
						'one' => q({0}CD),
						'other' => q({0}CD),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(Da),
						'one' => q({0}Da),
						'other' => q({0}Da),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(Da),
						'one' => q({0}Da),
						'other' => q({0}Da),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(M⊕),
						'one' => q({0}M⊕),
						'other' => q({0}M⊕),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(M⊕),
						'one' => q({0}M⊕),
						'other' => q({0}M⊕),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(gr),
						'one' => q({0}gr),
						'other' => q({0}gr),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(gr),
						'one' => q({0}gr),
						'other' => q({0}gr),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(ᎤᏍᏗ ᎤᏓᎨᏒ),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(ᎤᏍᏗ ᎤᏓᎨᏒ),
						'one' => q({0}g),
						'other' => q({0}g),
					},
					# Long Unit Identifier
					'mass-kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					# Core Unit Identifier
					'kilogram' => {
						'one' => q({0}kg),
						'other' => q({0}kg),
					},
					# Long Unit Identifier
					'mass-microgram' => {
						'one' => q({0}μg),
						'other' => q({0}μg),
					},
					# Core Unit Identifier
					'microgram' => {
						'one' => q({0}μg),
						'other' => q({0}μg),
					},
					# Long Unit Identifier
					'mass-milligram' => {
						'one' => q({0}mg),
						'other' => q({0}mg),
					},
					# Core Unit Identifier
					'milligram' => {
						'one' => q({0}mg),
						'other' => q({0}mg),
					},
					# Long Unit Identifier
					'mass-ounce' => {
						'one' => q({0}oz),
						'other' => q({0}oz),
					},
					# Core Unit Identifier
					'ounce' => {
						'one' => q({0}oz),
						'other' => q({0}oz),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0}oz t),
						'other' => q({0}oz t),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz t),
						'one' => q({0}oz t),
						'other' => q({0}oz t),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(lb),
						'one' => q({0}#),
						'other' => q({0}#),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(lb),
						'one' => q({0}#),
						'other' => q({0}#),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(M☉),
						'one' => q({0}M☉),
						'other' => q({0}M☉),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(M☉),
						'one' => q({0}M☉),
						'other' => q({0}M☉),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(ᏅᏯ),
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(ᏅᏯ),
						'one' => q({0}st),
						'other' => q({0}st),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'one' => q({0}tn),
						'other' => q({0}tn),
					},
					# Core Unit Identifier
					'ton' => {
						'one' => q({0}tn),
						'other' => q({0}tn),
					},
					# Long Unit Identifier
					'mass-tonne' => {
						'one' => q({0}t),
						'other' => q({0}t),
					},
					# Core Unit Identifier
					'tonne' => {
						'one' => q({0}t),
						'other' => q({0}t),
					},
					# Long Unit Identifier
					'power-gigawatt' => {
						'one' => q({0}GW),
						'other' => q({0}GW),
					},
					# Core Unit Identifier
					'gigawatt' => {
						'one' => q({0}GW),
						'other' => q({0}GW),
					},
					# Long Unit Identifier
					'power-horsepower' => {
						'one' => q({0}hp),
						'other' => q({0}hp),
					},
					# Core Unit Identifier
					'horsepower' => {
						'one' => q({0}hp),
						'other' => q({0}hp),
					},
					# Long Unit Identifier
					'power-kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					# Core Unit Identifier
					'kilowatt' => {
						'one' => q({0}kW),
						'other' => q({0}kW),
					},
					# Long Unit Identifier
					'power-megawatt' => {
						'one' => q({0}MW),
						'other' => q({0}MW),
					},
					# Core Unit Identifier
					'megawatt' => {
						'one' => q({0}MW),
						'other' => q({0}MW),
					},
					# Long Unit Identifier
					'power-milliwatt' => {
						'one' => q({0}mW),
						'other' => q({0}mW),
					},
					# Core Unit Identifier
					'milliwatt' => {
						'one' => q({0}mW),
						'other' => q({0}mW),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(ᏩᏗ),
						'one' => q({0}W),
						'other' => q({0}W),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(ᏩᏗ),
						'one' => q({0}W),
						'other' => q({0}W),
					},
					# Long Unit Identifier
					'pressure-atmosphere' => {
						'one' => q({0}atm),
						'other' => q({0}atm),
					},
					# Core Unit Identifier
					'atmosphere' => {
						'one' => q({0}atm),
						'other' => q({0}atm),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'one' => q({0}ᎦᎾᎸᎢ),
						'other' => q({0}ᎦᎾᎸᎢ),
					},
					# Core Unit Identifier
					'bar' => {
						'one' => q({0}ᎦᎾᎸᎢ),
						'other' => q({0}ᎦᎾᎸᎢ),
					},
					# Long Unit Identifier
					'pressure-hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					# Core Unit Identifier
					'hectopascal' => {
						'one' => q({0}hPa),
						'other' => q({0}hPa),
					},
					# Long Unit Identifier
					'pressure-inch-ofhg' => {
						'name' => q(″ Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					# Core Unit Identifier
					'inch-ofhg' => {
						'name' => q(″ Hg),
						'one' => q({0}″ Hg),
						'other' => q({0}″ Hg),
					},
					# Long Unit Identifier
					'pressure-kilopascal' => {
						'one' => q({0}kPa),
						'other' => q({0}kPa),
					},
					# Core Unit Identifier
					'kilopascal' => {
						'one' => q({0}kPa),
						'other' => q({0}kPa),
					},
					# Long Unit Identifier
					'pressure-megapascal' => {
						'one' => q({0}MPa),
						'other' => q({0}MPa),
					},
					# Core Unit Identifier
					'megapascal' => {
						'one' => q({0}MPa),
						'other' => q({0}MPa),
					},
					# Long Unit Identifier
					'pressure-millibar' => {
						'one' => q({0}mb),
						'other' => q({0}mb),
					},
					# Core Unit Identifier
					'millibar' => {
						'one' => q({0}mb),
						'other' => q({0}mb),
					},
					# Long Unit Identifier
					'pressure-millimeter-ofhg' => {
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
					},
					# Core Unit Identifier
					'millimeter-ofhg' => {
						'one' => q({0}mmHg),
						'other' => q({0}mmHg),
					},
					# Long Unit Identifier
					'pressure-pascal' => {
						'one' => q({0}Pa),
						'other' => q({0}Pa),
					},
					# Core Unit Identifier
					'pascal' => {
						'one' => q({0}Pa),
						'other' => q({0}Pa),
					},
					# Long Unit Identifier
					'pressure-pound-force-per-square-inch' => {
						'one' => q({0}psi),
						'other' => q({0}psi),
					},
					# Core Unit Identifier
					'pound-force-per-square-inch' => {
						'one' => q({0}psi),
						'other' => q({0}psi),
					},
					# Long Unit Identifier
					'speed-beaufort' => {
						'one' => q(B{0}),
						'other' => q(B{0}),
					},
					# Core Unit Identifier
					'beaufort' => {
						'one' => q(B{0}),
						'other' => q(B{0}),
					},
					# Long Unit Identifier
					'speed-kilometer-per-hour' => {
						'name' => q(km/hr),
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/hr),
						'one' => q({0}km/h),
						'other' => q({0}km/h),
					},
					# Long Unit Identifier
					'speed-knot' => {
						'one' => q({0}kn),
						'other' => q({0}kn),
					},
					# Core Unit Identifier
					'knot' => {
						'one' => q({0}kn),
						'other' => q({0}kn),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(ᎠᏨᏍᏗ),
						'one' => q({0}ᎠᏨᏍᏗ),
						'other' => q({0}ᎠᏨᏍᏗ),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(ᎠᏨᏍᏗ),
						'one' => q({0}ᎠᏨᏍᏗ),
						'other' => q({0}ᎠᏨᏍᏗ),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(m/s),
						'one' => q({0}m/s),
						'other' => q({0}m/s),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(mi/hr),
						'one' => q({0}mph),
						'other' => q({0}mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(mi/hr),
						'one' => q({0}mph),
						'other' => q({0}mph),
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
					'temperature-kelvin' => {
						'one' => q({0}K),
						'other' => q({0}K),
					},
					# Core Unit Identifier
					'kelvin' => {
						'one' => q({0}K),
						'other' => q({0}K),
					},
					# Long Unit Identifier
					'torque-newton-meter' => {
						'one' => q({0}N⋅m),
						'other' => q({0}N⋅m),
					},
					# Core Unit Identifier
					'newton-meter' => {
						'one' => q({0}N⋅m),
						'other' => q({0}N⋅m),
					},
					# Long Unit Identifier
					'torque-pound-force-foot' => {
						'one' => q({0}lbf⋅ft),
						'other' => q({0}lbf⋅ft),
					},
					# Core Unit Identifier
					'pound-force-foot' => {
						'one' => q({0}lbf⋅ft),
						'other' => q({0}lbf⋅ft),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'one' => q({0}ac ft),
						'other' => q({0}ac ft),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'one' => q({0}ac ft),
						'other' => q({0}ac ft),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(bbl),
						'one' => q({0}bbl),
						'other' => q({0}bbl),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(bbl),
						'one' => q({0}bbl),
						'other' => q({0}bbl),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'one' => q({0}bu),
						'other' => q({0}bu),
					},
					# Core Unit Identifier
					'bushel' => {
						'one' => q({0}bu),
						'other' => q({0}bu),
					},
					# Long Unit Identifier
					'volume-centiliter' => {
						'one' => q({0}cL),
						'other' => q({0}cL),
					},
					# Core Unit Identifier
					'centiliter' => {
						'one' => q({0}cL),
						'other' => q({0}cL),
					},
					# Long Unit Identifier
					'volume-cubic-centimeter' => {
						'one' => q({0}cm³),
						'other' => q({0}cm³),
					},
					# Core Unit Identifier
					'cubic-centimeter' => {
						'one' => q({0}cm³),
						'other' => q({0}cm³),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0}ft³),
						'other' => q({0}ft³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(ft³),
						'one' => q({0}ft³),
						'other' => q({0}ft³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(in³),
						'one' => q({0}in³),
						'other' => q({0}in³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(in³),
						'one' => q({0}in³),
						'other' => q({0}in³),
					},
					# Long Unit Identifier
					'volume-cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					# Core Unit Identifier
					'cubic-kilometer' => {
						'one' => q({0}km³),
						'other' => q({0}km³),
					},
					# Long Unit Identifier
					'volume-cubic-meter' => {
						'one' => q({0}m³),
						'other' => q({0}m³),
					},
					# Core Unit Identifier
					'cubic-meter' => {
						'one' => q({0}m³),
						'other' => q({0}m³),
					},
					# Long Unit Identifier
					'volume-cubic-mile' => {
						'one' => q({0}mi³),
						'other' => q({0}mi³),
					},
					# Core Unit Identifier
					'cubic-mile' => {
						'one' => q({0}mi³),
						'other' => q({0}mi³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0}yd³),
						'other' => q({0}yd³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0}yd³),
						'other' => q({0}yd³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'one' => q({0}c),
						'other' => q({0}c),
					},
					# Core Unit Identifier
					'cup' => {
						'one' => q({0}c),
						'other' => q({0}c),
					},
					# Long Unit Identifier
					'volume-cup-metric' => {
						'one' => q({0}mc),
						'other' => q({0}mc),
					},
					# Core Unit Identifier
					'cup-metric' => {
						'one' => q({0}mc),
						'other' => q({0}mc),
					},
					# Long Unit Identifier
					'volume-deciliter' => {
						'one' => q({0}dL),
						'other' => q({0}dL),
					},
					# Core Unit Identifier
					'deciliter' => {
						'one' => q({0}dL),
						'other' => q({0}dL),
					},
					# Long Unit Identifier
					'volume-dessert-spoon' => {
						'name' => q(dsp),
						'one' => q({0}dsp),
						'other' => q({0}dsp),
					},
					# Core Unit Identifier
					'dessert-spoon' => {
						'name' => q(dsp),
						'one' => q({0}dsp),
						'other' => q({0}dsp),
					},
					# Long Unit Identifier
					'volume-dessert-spoon-imperial' => {
						'name' => q(dsp Imp),
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Core Unit Identifier
					'dessert-spoon-imperial' => {
						'name' => q(dsp Imp),
						'one' => q({0}dsp-Imp),
						'other' => q({0}dsp-Imp),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(fl.dr.),
						'one' => q({0}fl.dr.),
						'other' => q({0}fl.dr.),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(fl.dr.),
						'one' => q({0}fl.dr.),
						'other' => q({0}fl.dr.),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(dr),
						'one' => q({0}dr),
						'other' => q({0}dr),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(dr),
						'one' => q({0}dr),
						'other' => q({0}dr),
					},
					# Long Unit Identifier
					'volume-fluid-ounce' => {
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
					},
					# Core Unit Identifier
					'fluid-ounce' => {
						'one' => q({0}fl oz),
						'other' => q({0}fl oz),
					},
					# Long Unit Identifier
					'volume-fluid-ounce-imperial' => {
						'name' => q(Imp fl oz),
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
					},
					# Core Unit Identifier
					'fluid-ounce-imperial' => {
						'name' => q(Imp fl oz),
						'one' => q({0}fl oz Im),
						'other' => q({0}fl oz Im),
					},
					# Long Unit Identifier
					'volume-gallon' => {
						'name' => q(gal),
						'one' => q({0}gal),
						'other' => q({0}gal),
						'per' => q({0}/gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(gal),
						'one' => q({0}gal),
						'other' => q({0}gal),
						'per' => q({0}/gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(Imp gal),
						'one' => q({0}galIm),
						'other' => q({0}galIm),
						'per' => q({0}/galIm),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(Imp gal),
						'one' => q({0}galIm),
						'other' => q({0}galIm),
						'per' => q({0}/galIm),
					},
					# Long Unit Identifier
					'volume-hectoliter' => {
						'one' => q({0}hL),
						'other' => q({0}hL),
					},
					# Core Unit Identifier
					'hectoliter' => {
						'one' => q({0}hL),
						'other' => q({0}hL),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'one' => q({0}ᏥᎩᎳ),
						'other' => q({0}ᏥᎩᎳ),
					},
					# Core Unit Identifier
					'jigger' => {
						'one' => q({0}ᏥᎩᎳ),
						'other' => q({0}ᏥᎩᎳ),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(ᎢᏳᏆᏗᏅᏛ),
						'one' => q({0}L),
						'other' => q({0}L),
						'per' => q({0}/L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(ᎢᏳᏆᏗᏅᏛ),
						'one' => q({0}L),
						'other' => q({0}L),
						'per' => q({0}/L),
					},
					# Long Unit Identifier
					'volume-megaliter' => {
						'one' => q({0}ML),
						'other' => q({0}ML),
					},
					# Core Unit Identifier
					'megaliter' => {
						'one' => q({0}ML),
						'other' => q({0}ML),
					},
					# Long Unit Identifier
					'volume-milliliter' => {
						'one' => q({0}mL),
						'other' => q({0}mL),
					},
					# Core Unit Identifier
					'milliliter' => {
						'one' => q({0}mL),
						'other' => q({0}mL),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(pn),
						'one' => q({0}pn),
						'other' => q({0}pn),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(pn),
						'one' => q({0}pn),
						'other' => q({0}pn),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(pt),
						'one' => q({0}pt),
						'other' => q({0}pt),
					},
					# Long Unit Identifier
					'volume-pint-metric' => {
						'one' => q({0}mp),
						'other' => q({0}mp),
					},
					# Core Unit Identifier
					'pint-metric' => {
						'one' => q({0}mp),
						'other' => q({0}mp),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(qt),
						'one' => q({0}qt),
						'other' => q({0}qt),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(qt),
						'one' => q({0}qt),
						'other' => q({0}qt),
					},
					# Long Unit Identifier
					'volume-quart-imperial' => {
						'one' => q({0}qt-Imp.),
						'other' => q({0}qt-Imp.),
					},
					# Core Unit Identifier
					'quart-imperial' => {
						'one' => q({0}qt-Imp.),
						'other' => q({0}qt-Imp.),
					},
					# Long Unit Identifier
					'volume-tablespoon' => {
						'one' => q({0}tbsp),
						'other' => q({0}tbsp),
					},
					# Core Unit Identifier
					'tablespoon' => {
						'one' => q({0}tbsp),
						'other' => q({0}tbsp),
					},
					# Long Unit Identifier
					'volume-teaspoon' => {
						'one' => q({0}tsp),
						'other' => q({0}tsp),
					},
					# Core Unit Identifier
					'teaspoon' => {
						'one' => q({0}tsp),
						'other' => q({0}tsp),
					},
				},
				'short' => {
					# Long Unit Identifier
					'' => {
						'name' => q(ᏫᏚᏳᎪᏛ),
					},
					# Core Unit Identifier
					'' => {
						'name' => q(ᏫᏚᏳᎪᏛ),
					},
					# Long Unit Identifier
					'acceleration-g-force' => {
						'name' => q(ᎠᏓᎾᏌᏁᏍᎩ-ᎦᏌᏙᏯᏍᏗ),
					},
					# Core Unit Identifier
					'g-force' => {
						'name' => q(ᎠᏓᎾᏌᏁᏍᎩ-ᎦᏌᏙᏯᏍᏗ),
					},
					# Long Unit Identifier
					'acceleration-meter-per-square-second' => {
						'name' => q(ᏗᏟᎶᏍᏗ/sec²),
					},
					# Core Unit Identifier
					'meter-per-square-second' => {
						'name' => q(ᏗᏟᎶᏍᏗ/sec²),
					},
					# Long Unit Identifier
					'angle-arc-minute' => {
						'name' => q(ᎠᏥ ᎢᏧᏔᏬᏍᏔᏅ),
						'one' => q({0} arcmin),
						'other' => q({0} arcmins),
					},
					# Core Unit Identifier
					'arc-minute' => {
						'name' => q(ᎠᏥ ᎢᏧᏔᏬᏍᏔᏅ),
						'one' => q({0} arcmin),
						'other' => q({0} arcmins),
					},
					# Long Unit Identifier
					'angle-arc-second' => {
						'name' => q(ᎠᏥ ᏓᏓᎾᏬᏍᎬ),
						'one' => q({0} arcsec),
						'other' => q({0} arcsecs),
					},
					# Core Unit Identifier
					'arc-second' => {
						'name' => q(ᎠᏥ ᏓᏓᎾᏬᏍᎬ),
						'one' => q({0} arcsec),
						'other' => q({0} arcsecs),
					},
					# Long Unit Identifier
					'angle-degree' => {
						'name' => q(ᎢᎦᎢ ᎢᏗᎦᏘ),
						'one' => q({0} deg),
						'other' => q({0} deg),
					},
					# Core Unit Identifier
					'degree' => {
						'name' => q(ᎢᎦᎢ ᎢᏗᎦᏘ),
						'one' => q({0} deg),
						'other' => q({0} deg),
					},
					# Long Unit Identifier
					'angle-radian' => {
						'name' => q(ᎠᏥ ᎠᏟᎶᏍᏙᏗ),
					},
					# Core Unit Identifier
					'radian' => {
						'name' => q(ᎠᏥ ᎠᏟᎶᏍᏙᏗ),
					},
					# Long Unit Identifier
					'angle-revolution' => {
						'name' => q(ᎠᏕᏲᎲ),
						'one' => q({0} ᎠᏕᏲᎲ),
						'other' => q({0} ᎠᏕᏲᎲ),
					},
					# Core Unit Identifier
					'revolution' => {
						'name' => q(ᎠᏕᏲᎲ),
						'one' => q({0} ᎠᏕᏲᎲ),
						'other' => q({0} ᎠᏕᏲᎲ),
					},
					# Long Unit Identifier
					'area-acre' => {
						'name' => q(ᎢᏧᏟᎶᏓ),
						'one' => q({0} ᏑᏟᎶ),
						'other' => q({0} ᏑᏟᎶ),
					},
					# Core Unit Identifier
					'acre' => {
						'name' => q(ᎢᏧᏟᎶᏓ),
						'one' => q({0} ᏑᏟᎶ),
						'other' => q({0} ᏑᏟᎶ),
					},
					# Long Unit Identifier
					'area-dunam' => {
						'name' => q(ᏚᎾᎹᏍ),
						'one' => q({0} ᏚᎾᎹ),
						'other' => q({0} ᏚᎾᎹ),
					},
					# Core Unit Identifier
					'dunam' => {
						'name' => q(ᏚᎾᎹᏍ),
						'one' => q({0} ᏚᎾᎹ),
						'other' => q({0} ᏚᎾᎹ),
					},
					# Long Unit Identifier
					'area-hectare' => {
						'name' => q(ᎮᏔ ᎢᏳᏟᎶᏛ),
					},
					# Core Unit Identifier
					'hectare' => {
						'name' => q(ᎮᏔ ᎢᏳᏟᎶᏛ),
					},
					# Long Unit Identifier
					'area-square-foot' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏱ ᎢᏗᎳᏏᏗ),
						'one' => q({0} sq ft),
						'other' => q({0} sq ft),
					},
					# Core Unit Identifier
					'square-foot' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏱ ᎢᏗᎳᏏᏗ),
						'one' => q({0} sq ft),
						'other' => q({0} sq ft),
					},
					# Long Unit Identifier
					'area-square-inch' => {
						'name' => q(ᎢᏗᏏᏔᏗᏍᏗ²),
					},
					# Core Unit Identifier
					'square-inch' => {
						'name' => q(ᎢᏗᏏᏔᏗᏍᏗ²),
					},
					# Long Unit Identifier
					'area-square-meter' => {
						'name' => q(ᏗᏟᎶᏍᏗ²),
					},
					# Core Unit Identifier
					'square-meter' => {
						'name' => q(ᏗᏟᎶᏍᏗ²),
					},
					# Long Unit Identifier
					'area-square-mile' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏱ ᎢᏳᏟᎶᏓ),
						'one' => q({0} ᏅᏧᎢ),
						'other' => q({0} ᏅᏧᎢ),
					},
					# Core Unit Identifier
					'square-mile' => {
						'name' => q(ᏅᎩ ᏧᏅᏏᏱ ᎢᏳᏟᎶᏓ),
						'one' => q({0} ᏅᏧᎢ),
						'other' => q({0} ᏅᏧᎢ),
					},
					# Long Unit Identifier
					'area-square-yard' => {
						'name' => q(ᏗᏯᏯᏗ²),
					},
					# Core Unit Identifier
					'square-yard' => {
						'name' => q(ᏗᏯᏯᏗ²),
					},
					# Long Unit Identifier
					'concentr-item' => {
						'name' => q(ᏑᏓᎴᎩ),
						'one' => q({0} ᏑᏓᎴᎩ),
						'other' => q({0} ᎢᏳᏓᎴᎩ),
					},
					# Core Unit Identifier
					'item' => {
						'name' => q(ᏑᏓᎴᎩ),
						'one' => q({0} ᏑᏓᎴᎩ),
						'other' => q({0} ᎢᏳᏓᎴᎩ),
					},
					# Long Unit Identifier
					'concentr-karat' => {
						'name' => q(ᏗᎧᏇᏓ),
					},
					# Core Unit Identifier
					'karat' => {
						'name' => q(ᏗᎧᏇᏓ),
					},
					# Long Unit Identifier
					'concentr-millimole-per-liter' => {
						'name' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎼᎵ ᎵᏔᎢ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'millimole-per-liter' => {
						'name' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᎼᎵ ᎵᏔᎢ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'concentr-mole' => {
						'name' => q(ᎼᎴ),
					},
					# Core Unit Identifier
					'mole' => {
						'name' => q(ᎼᎴ),
					},
					# Long Unit Identifier
					'concentr-percent' => {
						'name' => q(ᏓᎬᏩᎶᏛ),
					},
					# Core Unit Identifier
					'percent' => {
						'name' => q(ᏓᎬᏩᎶᏛ),
					},
					# Long Unit Identifier
					'concentr-permille' => {
						'name' => q(ᏈᎻᎴ),
					},
					# Core Unit Identifier
					'permille' => {
						'name' => q(ᏈᎻᎴ),
					},
					# Long Unit Identifier
					'concentr-permillion' => {
						'name' => q(ᏚᏙᏢᏒ/ᎢᏳᏆᏗᏅᏛ),
					},
					# Core Unit Identifier
					'permillion' => {
						'name' => q(ᏚᏙᏢᏒ/ᎢᏳᏆᏗᏅᏛ),
					},
					# Long Unit Identifier
					'concentr-permyriad' => {
						'name' => q(ᏋᎻᎵᎠᏗ),
					},
					# Core Unit Identifier
					'permyriad' => {
						'name' => q(ᏋᎻᎵᎠᏗ),
					},
					# Long Unit Identifier
					'concentr-portion-per-1e9' => {
						'name' => q(ᏚᏙᏢᏒ/ᎢᏳᏔᎵᎳᏗᏅᏛ),
					},
					# Core Unit Identifier
					'portion-per-1e9' => {
						'name' => q(ᏚᏙᏢᏒ/ᎢᏳᏔᎵᎳᏗᏅᏛ),
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
						'name' => q(ᏗᎵᏔᎢ/ᎠᎦᏴᎵ ᎠᏟᎶᏍᏗ),
					},
					# Core Unit Identifier
					'liter-per-kilometer' => {
						'name' => q(ᏗᎵᏔᎢ/ᎠᎦᏴᎵ ᎠᏟᎶᏍᏗ),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon' => {
						'name' => q(ᎢᏧᏟᎶᏓ/ᎢᏳᎵᎶᏓ),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Core Unit Identifier
					'mile-per-gallon' => {
						'name' => q(ᎢᏧᏟᎶᏓ/ᎢᏳᎵᎶᏓ),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					# Long Unit Identifier
					'consumption-mile-per-gallon-imperial' => {
						'name' => q(ᎢᏧᏟᎶᏓ/ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎢᏳᎵᎶᏓ),
					},
					# Core Unit Identifier
					'mile-per-gallon-imperial' => {
						'name' => q(ᎢᏧᏟᎶᏓ/ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎢᏳᎵᎶᏓ),
					},
					# Long Unit Identifier
					'coordinate' => {
						'east' => q({0} Ꮧ),
						'north' => q({0} ᏧᏴ),
						'south' => q({0} ᏧᎦ),
						'west' => q({0} Ꮽ),
					},
					# Core Unit Identifier
					'coordinate' => {
						'east' => q({0} Ꮧ),
						'north' => q({0} ᏧᏴ),
						'south' => q({0} ᏧᎦ),
						'west' => q({0} Ꮽ),
					},
					# Long Unit Identifier
					'digital-bit' => {
						'name' => q(ᎤᏍᎦᎳ),
						'one' => q({0} ᎤᏍᎦᎳ),
						'other' => q({0} ᎤᏍᎦᎳ),
					},
					# Core Unit Identifier
					'bit' => {
						'name' => q(ᎤᏍᎦᎳ),
						'one' => q({0} ᎤᏍᎦᎳ),
						'other' => q({0} ᎤᏍᎦᎳ),
					},
					# Long Unit Identifier
					'digital-byte' => {
						'name' => q(ᎠᏍᎦᎳ),
						'one' => q({0} ᎠᏍᎦᎳ),
						'other' => q({0} ᎠᏍᎦᎳ),
					},
					# Core Unit Identifier
					'byte' => {
						'name' => q(ᎠᏍᎦᎳ),
						'one' => q({0} ᎠᏍᎦᎳ),
						'other' => q({0} ᎠᏍᎦᎳ),
					},
					# Long Unit Identifier
					'digital-gigabit' => {
						'name' => q(ᎩᎦᎤᏍᎦᎳ),
					},
					# Core Unit Identifier
					'gigabit' => {
						'name' => q(ᎩᎦᎤᏍᎦᎳ),
					},
					# Long Unit Identifier
					'digital-gigabyte' => {
						'name' => q(ᎩᎦᎠᏍᎦᎳ),
					},
					# Core Unit Identifier
					'gigabyte' => {
						'name' => q(ᎩᎦᎠᏍᎦᎳ),
					},
					# Long Unit Identifier
					'digital-kilobit' => {
						'name' => q(ᎠᎦᏴᎵ ᎤᏍᎦᎳ),
					},
					# Core Unit Identifier
					'kilobit' => {
						'name' => q(ᎠᎦᏴᎵ ᎤᏍᎦᎳ),
					},
					# Long Unit Identifier
					'digital-kilobyte' => {
						'name' => q(ᎠᎦᏴᎵ ᎠᏍᎦᎳ),
					},
					# Core Unit Identifier
					'kilobyte' => {
						'name' => q(ᎠᎦᏴᎵ ᎠᏍᎦᎳ),
					},
					# Long Unit Identifier
					'digital-megabit' => {
						'name' => q(ᎺᎦ ᎤᏍᎦᎳ),
					},
					# Core Unit Identifier
					'megabit' => {
						'name' => q(ᎺᎦ ᎤᏍᎦᎳ),
					},
					# Long Unit Identifier
					'digital-megabyte' => {
						'name' => q(ᎺᎦ ᏗᏓᏍᎦᎵᎩ),
					},
					# Core Unit Identifier
					'megabyte' => {
						'name' => q(ᎺᎦ ᏗᏓᏍᎦᎵᎩ),
					},
					# Long Unit Identifier
					'digital-petabyte' => {
						'name' => q(PByte),
					},
					# Core Unit Identifier
					'petabyte' => {
						'name' => q(PByte),
					},
					# Long Unit Identifier
					'digital-terabit' => {
						'name' => q(ᏕᎳ ᎤᏍᎦᎳ),
					},
					# Core Unit Identifier
					'terabit' => {
						'name' => q(ᏕᎳ ᎤᏍᎦᎳ),
					},
					# Long Unit Identifier
					'digital-terabyte' => {
						'name' => q(ᏕᎳ ᎠᏍᎦᎳ),
					},
					# Core Unit Identifier
					'terabyte' => {
						'name' => q(ᏕᎳ ᎠᏍᎦᎳ),
					},
					# Long Unit Identifier
					'duration-century' => {
						'name' => q(ᏍᏧ),
						'one' => q({0} ᏍᏧ),
						'other' => q({0} ᏍᏧ),
					},
					# Core Unit Identifier
					'century' => {
						'name' => q(ᏍᏧ),
						'one' => q({0} ᏍᏧ),
						'other' => q({0} ᏍᏧ),
					},
					# Long Unit Identifier
					'duration-day' => {
						'name' => q(ᎯᎸᏍᎩ ᏧᏒᎯᏓ),
						'one' => q({0} ᎢᎦ),
						'other' => q({0} ᏧᏒᎯᏓ),
						'per' => q({0}/Ꭲ),
					},
					# Core Unit Identifier
					'day' => {
						'name' => q(ᎯᎸᏍᎩ ᏧᏒᎯᏓ),
						'one' => q({0} ᎢᎦ),
						'other' => q({0} ᏧᏒᎯᏓ),
						'per' => q({0}/Ꭲ),
					},
					# Long Unit Identifier
					'duration-decade' => {
						'name' => q(ᏍᎪᎯ),
						'one' => q({0} ᏍᎪᎯ),
						'other' => q({0} ᏍᎪᎯ),
					},
					# Core Unit Identifier
					'decade' => {
						'name' => q(ᏍᎪᎯ),
						'one' => q({0} ᏍᎪᎯ),
						'other' => q({0} ᏍᎪᎯ),
					},
					# Long Unit Identifier
					'duration-hour' => {
						'name' => q(ᎢᏳᏟᎶᏓ),
						'one' => q({0} ᏑᏟ),
						'other' => q({0} ᏑᏟ),
						'per' => q({0}/Ꮡ),
					},
					# Core Unit Identifier
					'hour' => {
						'name' => q(ᎢᏳᏟᎶᏓ),
						'one' => q({0} ᏑᏟ),
						'other' => q({0} ᏑᏟ),
						'per' => q({0}/Ꮡ),
					},
					# Long Unit Identifier
					'duration-microsecond' => {
						'name' => q(μᏗᏎᏢ),
					},
					# Core Unit Identifier
					'microsecond' => {
						'name' => q(μᏗᏎᏢ),
					},
					# Long Unit Identifier
					'duration-millisecond' => {
						'name' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᏎᏢ),
						'one' => q({0} ᏌᎠ),
						'other' => q({0} ᏌᎠ),
					},
					# Core Unit Identifier
					'millisecond' => {
						'name' => q(ᏌᏉ ᎢᏯᎦᎨᎵᏁᎢ ᏗᏎᏢ),
						'one' => q({0} ᏌᎠ),
						'other' => q({0} ᏌᎠ),
					},
					# Long Unit Identifier
					'duration-minute' => {
						'name' => q(ᎢᏯᏔᏬᏍᏔᏅ),
						'one' => q({0} ᎢᏯᏔ),
						'other' => q({0} ᎢᏯᏔ),
						'per' => q({0}/ᎢᏯᏔ),
					},
					# Core Unit Identifier
					'minute' => {
						'name' => q(ᎢᏯᏔᏬᏍᏔᏅ),
						'one' => q({0} ᎢᏯᏔ),
						'other' => q({0} ᎢᏯᏔ),
						'per' => q({0}/ᎢᏯᏔ),
					},
					# Long Unit Identifier
					'duration-month' => {
						'name' => q(ᏗᎧᎸᎢ),
						'one' => q({0} ᎧᎸᎢ),
						'other' => q({0} ᏗᎧᎸᎢ),
						'per' => q({0}/Ꭷ),
					},
					# Core Unit Identifier
					'month' => {
						'name' => q(ᏗᎧᎸᎢ),
						'one' => q({0} ᎧᎸᎢ),
						'other' => q({0} ᏗᎧᎸᎢ),
						'per' => q({0}/Ꭷ),
					},
					# Long Unit Identifier
					'duration-nanosecond' => {
						'name' => q(ᎾᏃᏗᏎᏢ),
						'one' => q({0} ᎾᏃ),
						'other' => q({0} ᎾᏃ),
					},
					# Core Unit Identifier
					'nanosecond' => {
						'name' => q(ᎾᏃᏗᏎᏢ),
						'one' => q({0} ᎾᏃ),
						'other' => q({0} ᎾᏃ),
					},
					# Long Unit Identifier
					'duration-night' => {
						'name' => q(ᏚᎵᏏᏂᏒ),
						'one' => q({0} ᎤᏒ),
						'other' => q({0} ᏚᎵᏏᏂᏒ),
						'per' => q({0}/ᎤᏒ),
					},
					# Core Unit Identifier
					'night' => {
						'name' => q(ᏚᎵᏏᏂᏒ),
						'one' => q({0} ᎤᏒ),
						'other' => q({0} ᏚᎵᏏᏂᏒ),
						'per' => q({0}/ᎤᏒ),
					},
					# Long Unit Identifier
					'duration-quarter' => {
						'name' => q(ᎯᎸᏍᎩ),
						'one' => q({0} ᎯᎸᏍᎩ),
						'other' => q({0} ᎯᎸᏍᎩ),
						'per' => q({0}/Ꭿ),
					},
					# Core Unit Identifier
					'quarter' => {
						'name' => q(ᎯᎸᏍᎩ),
						'one' => q({0} ᎯᎸᏍᎩ),
						'other' => q({0} ᎯᎸᏍᎩ),
						'per' => q({0}/Ꭿ),
					},
					# Long Unit Identifier
					'duration-second' => {
						'name' => q(ᏓᏓᎾ),
						'one' => q({0} ᎠᏎᏢ),
						'other' => q({0} ᎠᏎᏢ),
						'per' => q({0}/ᎠᏎ),
					},
					# Core Unit Identifier
					'second' => {
						'name' => q(ᏓᏓᎾ),
						'one' => q({0} ᎠᏎᏢ),
						'other' => q({0} ᎠᏎᏢ),
						'per' => q({0}/ᎠᏎ),
					},
					# Long Unit Identifier
					'duration-week' => {
						'name' => q(ᎢᏳᎾᏙᏓᏆᏍᏗ),
						'one' => q({0} ᏒᎾ),
						'other' => q({0} ᎢᏳᎾ),
						'per' => q({0}/Ꮢ),
					},
					# Core Unit Identifier
					'week' => {
						'name' => q(ᎢᏳᎾᏙᏓᏆᏍᏗ),
						'one' => q({0} ᏒᎾ),
						'other' => q({0} ᎢᏳᎾ),
						'per' => q({0}/Ꮢ),
					},
					# Long Unit Identifier
					'duration-year' => {
						'name' => q(ᏧᏕᏘᏴᏌᏗᏒᎢ),
						'one' => q({0} ᎤᏕ),
						'other' => q({0} ᏧᏕ),
						'per' => q({0}/Ꭴ),
					},
					# Core Unit Identifier
					'year' => {
						'name' => q(ᏧᏕᏘᏴᏌᏗᏒᎢ),
						'one' => q({0} ᎤᏕ),
						'other' => q({0} ᏧᏕ),
						'per' => q({0}/Ꭴ),
					},
					# Long Unit Identifier
					'electric-ampere' => {
						'name' => q(amps),
					},
					# Core Unit Identifier
					'ampere' => {
						'name' => q(amps),
					},
					# Long Unit Identifier
					'electric-milliampere' => {
						'name' => q(milliamps),
					},
					# Core Unit Identifier
					'milliampere' => {
						'name' => q(milliamps),
					},
					# Long Unit Identifier
					'electric-ohm' => {
						'name' => q(ᏗᎣᎻ),
					},
					# Core Unit Identifier
					'ohm' => {
						'name' => q(ᏗᎣᎻ),
					},
					# Long Unit Identifier
					'electric-volt' => {
						'name' => q(ᎠᎾᎦᎵᏍᎩ ᎢᏧᏟᏂᏚᏓ),
					},
					# Core Unit Identifier
					'volt' => {
						'name' => q(ᎠᎾᎦᎵᏍᎩ ᎢᏧᏟᏂᏚᏓ),
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
					'energy-electronvolt' => {
						'name' => q(ᎡᎴᏆᎾᏉᏔ),
					},
					# Core Unit Identifier
					'electronvolt' => {
						'name' => q(ᎡᎴᏆᎾᏉᏔ),
					},
					# Long Unit Identifier
					'energy-foodcalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					# Core Unit Identifier
					'foodcalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					# Long Unit Identifier
					'energy-joule' => {
						'name' => q(ᏗᏦᎤᎵ),
					},
					# Core Unit Identifier
					'joule' => {
						'name' => q(ᏗᏦᎤᎵ),
					},
					# Long Unit Identifier
					'energy-kilojoule' => {
						'name' => q(ᎠᎦᏴᎵ ᏦᎤᎵ),
					},
					# Core Unit Identifier
					'kilojoule' => {
						'name' => q(ᎠᎦᏴᎵ ᏦᎤᎵ),
					},
					# Long Unit Identifier
					'energy-kilowatt-hour' => {
						'name' => q(kW-ᎠᏟᎶᏓ),
					},
					# Core Unit Identifier
					'kilowatt-hour' => {
						'name' => q(kW-ᎠᏟᎶᏓ),
					},
					# Long Unit Identifier
					'energy-therm-us' => {
						'name' => q(US ᎤᏗᏞᎬᎢ),
						'one' => q({0} US ᎤᏗᏞᎬ),
						'other' => q({0} US ᎤᏗᏞᎬ),
					},
					# Core Unit Identifier
					'therm-us' => {
						'name' => q(US ᎤᏗᏞᎬᎢ),
						'one' => q({0} US ᎤᏗᏞᎬ),
						'other' => q({0} US ᎤᏗᏞᎬ),
					},
					# Long Unit Identifier
					'force-newton' => {
						'name' => q(ᏄᏛᏅ),
					},
					# Core Unit Identifier
					'newton' => {
						'name' => q(ᏄᏛᏅ),
					},
					# Long Unit Identifier
					'force-pound-force' => {
						'name' => q(ᏑᏓᎨᏓ-ᎦᏌᏙᏯᏍᏗ),
					},
					# Core Unit Identifier
					'pound-force' => {
						'name' => q(ᏑᏓᎨᏓ-ᎦᏌᏙᏯᏍᏗ),
					},
					# Long Unit Identifier
					'graphics-dot-per-centimeter' => {
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
					},
					# Core Unit Identifier
					'dot-per-centimeter' => {
						'name' => q(dpcm),
						'one' => q({0} dpcm),
						'other' => q({0} dpcm),
					},
					# Long Unit Identifier
					'graphics-dot-per-inch' => {
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Core Unit Identifier
					'dot-per-inch' => {
						'name' => q(dpi),
						'one' => q({0} dpi),
						'other' => q({0} dpi),
					},
					# Long Unit Identifier
					'graphics-megapixel' => {
						'name' => q(ᏧᏔᎾ ᏗᏇᎦᏎᎵ),
					},
					# Core Unit Identifier
					'megapixel' => {
						'name' => q(ᏧᏔᎾ ᏗᏇᎦᏎᎵ),
					},
					# Long Unit Identifier
					'graphics-pixel' => {
						'name' => q(ᏗᏇᎦᏎᎵ),
					},
					# Core Unit Identifier
					'pixel' => {
						'name' => q(ᏗᏇᎦᏎᎵ),
					},
					# Long Unit Identifier
					'length-decimeter' => {
						'name' => q(ᏌᏟ),
						'one' => q({0} ᏌᏟ),
						'other' => q({0} ᏌᏟ),
					},
					# Core Unit Identifier
					'decimeter' => {
						'name' => q(ᏌᏟ),
						'one' => q({0} ᏌᏟ),
						'other' => q({0} ᏌᏟ),
					},
					# Long Unit Identifier
					'length-fathom' => {
						'name' => q(ᏑᏓᎵ ᎢᏗᎳᏏᏗ ᎠᏯᏱ),
					},
					# Core Unit Identifier
					'fathom' => {
						'name' => q(ᏑᏓᎵ ᎢᏗᎳᏏᏗ ᎠᏯᏱ),
					},
					# Long Unit Identifier
					'length-foot' => {
						'name' => q(ᎢᏗᎳᏏᏗ),
					},
					# Core Unit Identifier
					'foot' => {
						'name' => q(ᎢᏗᎳᏏᏗ),
					},
					# Long Unit Identifier
					'length-furlong' => {
						'name' => q(ᎠᏰᏟ ᎩᏄᏘᏗ ᎢᏳᏟᎶᏓ),
					},
					# Core Unit Identifier
					'furlong' => {
						'name' => q(ᎠᏰᏟ ᎩᏄᏘᏗ ᎢᏳᏟᎶᏓ),
					},
					# Long Unit Identifier
					'length-inch' => {
						'name' => q(ᎢᏗᏏᏔᏗᏍᏗ),
					},
					# Core Unit Identifier
					'inch' => {
						'name' => q(ᎢᏗᏏᏔᏗᏍᏗ),
					},
					# Long Unit Identifier
					'length-kilometer' => {
						'name' => q(ᎠᏗ),
						'one' => q({0} ᎠᏗ),
						'other' => q({0} ᎠᏗ),
						'per' => q({0}/ᎠᏗ),
					},
					# Core Unit Identifier
					'kilometer' => {
						'name' => q(ᎠᏗ),
						'one' => q({0} ᎠᏗ),
						'other' => q({0} ᎠᏗ),
						'per' => q({0}/ᎠᏗ),
					},
					# Long Unit Identifier
					'length-light-year' => {
						'name' => q(ᏗᏨᏍᏗ ᏧᏕᏘ),
					},
					# Core Unit Identifier
					'light-year' => {
						'name' => q(ᏗᏨᏍᏗ ᏧᏕᏘ),
					},
					# Long Unit Identifier
					'length-meter' => {
						'name' => q(ᎠᏟ),
						'one' => q({0} ᎠᏟ),
						'other' => q({0} ᎠᏟ),
						'per' => q({0}/ᎠᏟ),
					},
					# Core Unit Identifier
					'meter' => {
						'name' => q(ᎠᏟ),
						'one' => q({0} ᎠᏟ),
						'other' => q({0} ᎠᏟ),
						'per' => q({0}/ᎠᏟ),
					},
					# Long Unit Identifier
					'length-mile' => {
						'name' => q(ᎢᏳᏟᎶᏓ),
					},
					# Core Unit Identifier
					'mile' => {
						'name' => q(ᎢᏳᏟᎶᏓ),
					},
					# Long Unit Identifier
					'length-millimeter' => {
						'name' => q(ᏌᎢᎠ),
						'one' => q({0} ᏌᎢᎠ),
						'other' => q({0} ᏌᎢᎠ),
					},
					# Core Unit Identifier
					'millimeter' => {
						'name' => q(ᏌᎢᎠ),
						'one' => q({0} ᏌᎢᎠ),
						'other' => q({0} ᏌᎢᎠ),
					},
					# Long Unit Identifier
					'length-parsec' => {
						'name' => q(ᎢᏯᏆᏎᎦ),
					},
					# Core Unit Identifier
					'parsec' => {
						'name' => q(ᎢᏯᏆᏎᎦ),
					},
					# Long Unit Identifier
					'length-point' => {
						'name' => q(ᏧᏓᏓᏟ),
					},
					# Core Unit Identifier
					'point' => {
						'name' => q(ᏧᏓᏓᏟ),
					},
					# Long Unit Identifier
					'length-solar-radius' => {
						'name' => q(ᏅᏓ ᏇᏗ),
					},
					# Core Unit Identifier
					'solar-radius' => {
						'name' => q(ᏅᏓ ᏇᏗ),
					},
					# Long Unit Identifier
					'length-yard' => {
						'name' => q(ᎢᏯᏯᏗ),
					},
					# Core Unit Identifier
					'yard' => {
						'name' => q(ᎢᏯᏯᏗ),
					},
					# Long Unit Identifier
					'light-lux' => {
						'name' => q(ᎸᏏ),
						'one' => q({0} ᎸᏏ),
						'other' => q({0} ᎸᏏ),
					},
					# Core Unit Identifier
					'lux' => {
						'name' => q(ᎸᏏ),
						'one' => q({0} ᎸᏏ),
						'other' => q({0} ᎸᏏ),
					},
					# Long Unit Identifier
					'light-solar-luminosity' => {
						'name' => q(ᏅᏓ ᏗᏨᏍᏗ),
					},
					# Core Unit Identifier
					'solar-luminosity' => {
						'name' => q(ᏅᏓ ᏗᏨᏍᏗ),
					},
					# Long Unit Identifier
					'mass-carat' => {
						'name' => q(ᏗᎨᏇᏓ),
					},
					# Core Unit Identifier
					'carat' => {
						'name' => q(ᏗᎨᏇᏓ),
					},
					# Long Unit Identifier
					'mass-dalton' => {
						'name' => q(ᏓᏙᎾᏍ),
					},
					# Core Unit Identifier
					'dalton' => {
						'name' => q(ᏓᏙᎾᏍ),
					},
					# Long Unit Identifier
					'mass-earth-mass' => {
						'name' => q(ᎡᎶᎯ ᎹᏏ),
					},
					# Core Unit Identifier
					'earth-mass' => {
						'name' => q(ᎡᎶᎯ ᎹᏏ),
					},
					# Long Unit Identifier
					'mass-grain' => {
						'name' => q(ᎤᏛᏒ ᎤᎦᏔ),
						'one' => q({0} ᎤᏛᏒ ᎤᎦᏔ),
						'other' => q({0} ᎤᏛᏒ ᎤᎦᏔ),
					},
					# Core Unit Identifier
					'grain' => {
						'name' => q(ᎤᏛᏒ ᎤᎦᏔ),
						'one' => q({0} ᎤᏛᏒ ᎤᎦᏔ),
						'other' => q({0} ᎤᏛᏒ ᎤᎦᏔ),
					},
					# Long Unit Identifier
					'mass-gram' => {
						'name' => q(ᎤᏍᏗ ᏂᏚᏓᎨᏒ),
					},
					# Core Unit Identifier
					'gram' => {
						'name' => q(ᎤᏍᏗ ᏂᏚᏓᎨᏒ),
					},
					# Long Unit Identifier
					'mass-ounce-troy' => {
						'name' => q(oz ᏆᏯ),
					},
					# Core Unit Identifier
					'ounce-troy' => {
						'name' => q(oz ᏆᏯ),
					},
					# Long Unit Identifier
					'mass-pound' => {
						'name' => q(ᎢᏧᏓᎨᏓ),
					},
					# Core Unit Identifier
					'pound' => {
						'name' => q(ᎢᏧᏓᎨᏓ),
					},
					# Long Unit Identifier
					'mass-solar-mass' => {
						'name' => q(ᏅᏓ ᎹᏏ),
					},
					# Core Unit Identifier
					'solar-mass' => {
						'name' => q(ᏅᏓ ᎹᏏ),
					},
					# Long Unit Identifier
					'mass-stone' => {
						'name' => q(ᎠᏂᏅᏯ),
					},
					# Core Unit Identifier
					'stone' => {
						'name' => q(ᎠᏂᏅᏯ),
					},
					# Long Unit Identifier
					'mass-ton' => {
						'name' => q(ᏗᏈᏂ),
					},
					# Core Unit Identifier
					'ton' => {
						'name' => q(ᏗᏈᏂ),
					},
					# Long Unit Identifier
					'power-watt' => {
						'name' => q(ᏗᏩᏗ),
					},
					# Core Unit Identifier
					'watt' => {
						'name' => q(ᏗᏩᏗ),
					},
					# Long Unit Identifier
					'pressure-bar' => {
						'name' => q(ᎦᎾᎸᎢ),
						'one' => q({0} ᎦᎾᎸᎢ),
						'other' => q({0} ᎦᎾᎸᎢ),
					},
					# Core Unit Identifier
					'bar' => {
						'name' => q(ᎦᎾᎸᎢ),
						'one' => q({0} ᎦᎾᎸᎢ),
						'other' => q({0} ᎦᎾᎸᎢ),
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
					'speed-kilometer-per-hour' => {
						'name' => q(km/ᏑᏟᎶᏓ),
					},
					# Core Unit Identifier
					'kilometer-per-hour' => {
						'name' => q(km/ᏑᏟᎶᏓ),
					},
					# Long Unit Identifier
					'speed-light-speed' => {
						'name' => q(ᎠᏨᏍᏗ),
						'one' => q({0} ᎠᏨᏍᏗ),
						'other' => q({0} ᎠᏨᏍᏗ),
					},
					# Core Unit Identifier
					'light-speed' => {
						'name' => q(ᎠᏨᏍᏗ),
						'one' => q({0} ᎠᏨᏍᏗ),
						'other' => q({0} ᎠᏨᏍᏗ),
					},
					# Long Unit Identifier
					'speed-meter-per-second' => {
						'name' => q(ᏗᏟᎶᏗ/ᎠᏎ),
					},
					# Core Unit Identifier
					'meter-per-second' => {
						'name' => q(ᏗᏟᎶᏗ/ᎠᏎ),
					},
					# Long Unit Identifier
					'speed-mile-per-hour' => {
						'name' => q(ᎢᏧᏟᎶᏓ/ᏑᏟᎶᏛ),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Core Unit Identifier
					'mile-per-hour' => {
						'name' => q(ᎢᏧᏟᎶᏓ/ᏑᏟᎶᏛ),
						'one' => q({0} mph),
						'other' => q({0} mph),
					},
					# Long Unit Identifier
					'temperature-celsius' => {
						'name' => q(deg. C),
					},
					# Core Unit Identifier
					'celsius' => {
						'name' => q(deg. C),
					},
					# Long Unit Identifier
					'temperature-fahrenheit' => {
						'name' => q(deg. F),
					},
					# Core Unit Identifier
					'fahrenheit' => {
						'name' => q(deg. F),
					},
					# Long Unit Identifier
					'volume-acre-foot' => {
						'name' => q(ᏑᏟᎶᏛ-ᎢᏗᎳᏏᏗ),
					},
					# Core Unit Identifier
					'acre-foot' => {
						'name' => q(ᏑᏟᎶᏛ-ᎢᏗᎳᏏᏗ),
					},
					# Long Unit Identifier
					'volume-barrel' => {
						'name' => q(ᏒᏙᏂ),
					},
					# Core Unit Identifier
					'barrel' => {
						'name' => q(ᏒᏙᏂ),
					},
					# Long Unit Identifier
					'volume-bushel' => {
						'name' => q(ᎤᎧᏲᏗ ᏑᏟᎶᏓ),
					},
					# Core Unit Identifier
					'bushel' => {
						'name' => q(ᎤᎧᏲᏗ ᏑᏟᎶᏓ),
					},
					# Long Unit Identifier
					'volume-cubic-foot' => {
						'name' => q(ᎢᏗᎳᏏᏗ³),
					},
					# Core Unit Identifier
					'cubic-foot' => {
						'name' => q(ᎢᏗᎳᏏᏗ³),
					},
					# Long Unit Identifier
					'volume-cubic-inch' => {
						'name' => q(ᎢᏗᏏᏔᏗᏍᏗ³),
					},
					# Core Unit Identifier
					'cubic-inch' => {
						'name' => q(ᎢᏗᏏᏔᏗᏍᏗ³),
					},
					# Long Unit Identifier
					'volume-cubic-yard' => {
						'name' => q(ᎢᏯᏯᏗ³),
					},
					# Core Unit Identifier
					'cubic-yard' => {
						'name' => q(ᎢᏯᏯᏗ³),
					},
					# Long Unit Identifier
					'volume-cup' => {
						'name' => q(ᏧᎵᏍᏈᏗ),
					},
					# Core Unit Identifier
					'cup' => {
						'name' => q(ᏧᎵᏍᏈᏗ),
					},
					# Long Unit Identifier
					'volume-dram' => {
						'name' => q(ᏜᎹ ᎠᎹ),
						'one' => q({0} ᏜᎹ ᎠᎹ),
						'other' => q({0} ᏜᎹ ᎠᎹ),
					},
					# Core Unit Identifier
					'dram' => {
						'name' => q(ᏜᎹ ᎠᎹ),
						'one' => q({0} ᏜᎹ ᎠᎹ),
						'other' => q({0} ᏜᎹ ᎠᎹ),
					},
					# Long Unit Identifier
					'volume-drop' => {
						'name' => q(ᎪᎭᏍᎬ),
						'one' => q({0} ᎪᎭᏍᎬ),
						'other' => q({0} ᎪᎭᏍᎬ),
					},
					# Core Unit Identifier
					'drop' => {
						'name' => q(ᎪᎭᏍᎬ),
						'one' => q({0} ᎪᎭᏍᎬ),
						'other' => q({0} ᎪᎭᏍᎬ),
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
					'volume-gallon' => {
						'name' => q(ᎢᏧᎵᎶᏓ),
						'one' => q({0} gal),
						'other' => q({0} gal),
					},
					# Core Unit Identifier
					'gallon' => {
						'name' => q(ᎢᏧᎵᎶᏓ),
						'one' => q({0} gal),
						'other' => q({0} gal),
					},
					# Long Unit Identifier
					'volume-gallon-imperial' => {
						'name' => q(ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎢᏳᎵᎶᏓ ᎢᏳᏓᎵ),
					},
					# Core Unit Identifier
					'gallon-imperial' => {
						'name' => q(ᏂᎬᎾᏛᎢ ᎤᏓᏤᎵᎦᏯ ᎢᏳᎵᎶᏓ ᎢᏳᏓᎵ),
					},
					# Long Unit Identifier
					'volume-jigger' => {
						'name' => q(ᏥᎩᎳ),
						'one' => q({0} ᏥᎩᎳ),
						'other' => q({0} ᏥᎩᎳ),
					},
					# Core Unit Identifier
					'jigger' => {
						'name' => q(ᏥᎩᎳ),
						'one' => q({0} ᏥᎩᎳ),
						'other' => q({0} ᏥᎩᎳ),
					},
					# Long Unit Identifier
					'volume-liter' => {
						'name' => q(ᎢᏧᏆᏗᏅᏛ),
						'one' => q({0} L),
						'other' => q({0} L),
					},
					# Core Unit Identifier
					'liter' => {
						'name' => q(ᎢᏧᏆᏗᏅᏛ),
						'one' => q({0} L),
						'other' => q({0} L),
					},
					# Long Unit Identifier
					'volume-pinch' => {
						'name' => q(ᏗᏓᏇᏄᎩᏍᏗ),
						'one' => q({0} ᏗᏓᏇᏄᎩᏍᏗ),
						'other' => q({0} ᏗᏓᏇᏄᎩᏍᏗ),
					},
					# Core Unit Identifier
					'pinch' => {
						'name' => q(ᏗᏓᏇᏄᎩᏍᏗ),
						'one' => q({0} ᏗᏓᏇᏄᎩᏍᏗ),
						'other' => q({0} ᏗᏓᏇᏄᎩᏍᏗ),
					},
					# Long Unit Identifier
					'volume-pint' => {
						'name' => q(ᏔᎵ ᏧᎵᏍᏈᏗ ᎠᎧᎵ),
					},
					# Core Unit Identifier
					'pint' => {
						'name' => q(ᏔᎵ ᏧᎵᏍᏈᏗ ᎠᎧᎵ),
					},
					# Long Unit Identifier
					'volume-quart' => {
						'name' => q(qts),
					},
					# Core Unit Identifier
					'quart' => {
						'name' => q(qts),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ᎥᎥ|Ꭵ|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:ᎥᏝ|Ꮭ|no|n)$' }
);

has 'listPatterns' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
				end => q({0}, ᎠᎴ {1}),
				2 => q({0} ᎠᎴ {1}),
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
					'one' => '0 ᎢᏯᎦᏴᎵ',
					'other' => '0 ᎢᏯᎦᏴᎵ',
				},
				'10000' => {
					'one' => '00 ᎢᏯᎦᏴᎵ',
					'other' => '00 ᎢᏯᎦᏴᎵ',
				},
				'100000' => {
					'one' => '000 ᎢᏯᎦᏴᎵ',
					'other' => '000 ᎢᏯᎦᏴᎵ',
				},
				'1000000' => {
					'one' => '0 ᎢᏳᏆᏗᏅᏛ',
					'other' => '0 ᎢᏳᏆᏗᏅᏛ',
				},
				'10000000' => {
					'one' => '00 ᎢᏳᏆᏗᏅᏛ',
					'other' => '00 ᎢᏳᏆᏗᏅᏛ',
				},
				'100000000' => {
					'one' => '000 ᎢᏳᏆᏗᏅᏛ',
					'other' => '000 ᎢᏳᏆᏗᏅᏛ',
				},
				'1000000000' => {
					'one' => '0 ᎢᏯᏔᎳᏗᏅᏛ',
					'other' => '0 ᎢᏯᏔᎳᏗᏅᏛ',
				},
				'10000000000' => {
					'one' => '00 ᎢᏯᏔᎳᏗᏅᏛ',
					'other' => '00 ᎢᏯᏔᎳᏗᏅᏛ',
				},
				'100000000000' => {
					'one' => '000 ᎢᏯᏔᎳᏗᏅᏛ',
					'other' => '000 ᎢᏯᏔᎳᏗᏅᏛ',
				},
				'1000000000000' => {
					'one' => '0 ᎢᏯᏦᎠᏗᏅᏛ',
					'other' => '0 ᎢᏯᏦᎠᏗᏅᏛ',
				},
				'10000000000000' => {
					'one' => '00 ᎢᏯᏦᎠᏗᏅᏛ',
					'other' => '00 ᎢᏯᏦᎠᏗᏅᏛ',
				},
				'100000000000000' => {
					'one' => '000 ᎢᏯᏦᎠᏗᏅᏛ',
					'other' => '000 ᎢᏯᏦᎠᏗᏅᏛ',
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
		'AED' => {
			display_name => {
				'currency' => q(ᏌᏊ ᎢᏳᎾᎵᏍᏔᏅ ᎡᎳᏈ ᎢᎹᎵᏘᏏ ᎠᏕᎳ),
				'one' => q(UAE ᎠᏕᎳ),
				'other' => q(UAE ᎠᏕᎳ),
			},
		},
		'AFN' => {
			display_name => {
				'currency' => q(ᎠᏫᎨᏂᏍᏖᏂ ᎠᏕᎳ),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(ᎠᎵᏇᏂᏯ ᎠᏕᎳ),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(ᎠᎵᎻᏂᎠ ᎠᏕᎳ),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(ᎾᏍᎩᏁᏛᎳᏂ ᎠᏂᏘᎵᏏ ᎠᏕᎳ),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(ᎠᏂᎪᎳ ᎠᏕᎳ),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(ᎠᏥᏂᏘᏂᎠ ᎠᏕᎳ),
			},
		},
		'AUD' => {
			display_name => {
				'currency' => q(ᎡᎳᏗᏜ ᎠᏕᎳ),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(ᎠᎷᏆ ᎠᏕᎳ),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(ᎠᏏᎵᏆᏌᏂ ᎠᏕᎳ),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(ᏉᏏᏂᎠ-ᎲᏤᎪᏫ ᎦᏁᏟᏴᏍᏔᏅ ᎠᏕᎳ),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(ᏆᏇᏙᏍ ᎠᏕᎳ),
			},
		},
		'BDT' => {
			display_name => {
				'currency' => q(ᏆᏂᎦᎵᏕᏍ ᎠᏕᎳ),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(ᏊᎵᎨᎵᎠ ᎠᏕᎳ),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(ᏆᎭᎴᎢᏂ ᎠᏕᎳ),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(ᏋᎷᏂᏗ ᎠᏕᎳ),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(ᏆᏊᏓ ᎠᏕᎳ),
			},
		},
		'BND' => {
			display_name => {
				'currency' => q(ᏊᎾᎢ ᎠᏕᎳ),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(ᏉᎵᏫᎠ ᎠᏕᎳ),
			},
		},
		'BRL' => {
			display_name => {
				'currency' => q(ᏆᏏᎵᎢ ᎠᏕᎳ),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(ᏆᎭᎹ ᎠᏕᎳ),
			},
		},
		'BTN' => {
			display_name => {
				'currency' => q(ᏊᏔᏂ ᎠᏕᎳ),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(ᏆᏣᏩᎾ ᎠᏕᎳ),
			},
		},
		'BYN' => {
			symbol => 'р.',
			display_name => {
				'currency' => q(ᏇᎳᎷᏍ ᎠᏕᎳ),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(ᏇᎳᎷᏍ ᎠᏕᎳ \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(ᏇᎵᏍ ᎠᏕᎳ),
			},
		},
		'CAD' => {
			display_name => {
				'currency' => q(ᎨᎾᏓ ᎠᏕᎳ),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(ᎧᏂᎪ ᎠᏕᎳ),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(ᏍᏫᏏ ᎠᏕᎳ),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(ᏥᎵ ᎠᏕᎳ),
			},
		},
		'CNH' => {
			display_name => {
				'currency' => q(ᏣᏂᏏ ᎠᏕᎳ \(ᏓᎹᏳᏟᏗ\)),
			},
		},
		'CNY' => {
			display_name => {
				'currency' => q(ᏓᎶᏂᎨ ᎠᏕᎳ),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(ᎪᎸᎻᏈᎢᎠ ᎠᏕᎳ),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(ᎪᏍᏓᎵᎧ ᎠᏕᎳ),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(ᎫᏆ ᎦᏁᏟᏴᏍᏔᏅ ᎠᏕᎳ),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(ᎫᏆ ᎠᏕᎳ),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(ᎢᎬᎾᏕᎾ ᎢᏤᏳᏍᏗ ᎠᏕᎳ),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(ᏤᎩ ᎠᏕᎳ),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(ᏥᏊᏗ ᎠᏕᎳ),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(ᏕᏂᏍ ᎠᏕᎳ),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(ᏙᎻᏂᎧᏂ ᎠᏕᎳ),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(ᎠᎵᏥᎵᏯ ᎠᏕᎳ),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(ᎢᏥᏈᎢ ᎠᏕᎳ),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(ᎡᎵᏟᏯ ᎠᏕᎳ),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(ᎢᏗᎣᏈᎠ ᎠᏕᎳ),
			},
		},
		'EUR' => {
			display_name => {
				'currency' => q(ᏳᎳᏛ ᎠᏕᎳ),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(ᏫᎩ ᎠᏕᎳ),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(ᏩᎩᎤ ᏚᎦᏚᏛᎢ ᎠᏕᎳ),
			},
		},
		'GBP' => {
			display_name => {
				'currency' => q(ᎩᎵᏏᏲ ᎠᏕᎳ),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(ᏣᎠᏥᎢ ᎠᏕᎳ),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(ᎦᎠᎾ ᎠᏕᎳ),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(ᏥᏆᎵᏓ ᎠᏕᎳ),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(ᎦᎹᏈᎢᎠ ᎠᏕᎳ),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(ᎩᎢᏂ ᎠᏕᎳ),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(ᏆᏖᎹᎳ ᎠᏕᎳ),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(ᎦᏯᎾ ᎠᏕᎳ),
			},
		},
		'HKD' => {
			display_name => {
				'currency' => q(ᎰᏂᎩ ᎪᏂᎩ ᎠᏕᎳ),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(ᎭᏂᏚᎳᏍ ᎠᏕᎳ),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(ᎧᎶᎡᏏᎠ ᎠᏕᎳ),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(ᎮᏘ ᎠᏕᎳ),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(ᎲᏂᎦᎵ ᎠᏕᎳ),
			},
		},
		'IDR' => {
			display_name => {
				'currency' => q(ᎢᏂᏙᏂᏍᏯ ᎠᏕᎳ),
			},
		},
		'ILS' => {
			display_name => {
				'currency' => q(ᎢᏏᎵᏱ ᎢᏤ ᎠᏕᎳ),
			},
		},
		'INR' => {
			display_name => {
				'currency' => q(ᎢᏂᏗᎢᎠ ᎠᏕᎳ),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(ᎢᎳᎩ ᎠᏕᎳ),
			},
		},
		'IRR' => {
			display_name => {
				'currency' => q(ᎢᎴᏂ ᎠᏕᎳ),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(ᏧᏁᏍᏓᎸᎯ ᎠᏕᎳ),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(ᏣᎺᎢᎧ ᎠᏕᎳ),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(ᏦᏓᏂ ᎠᏕᎳ),
			},
		},
		'JPY' => {
			display_name => {
				'currency' => q(ᏣᏩᏂᏏ ᎠᏕᎳ),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(ᎨᏂᏯ ᎠᏕᎳ),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(ᎩᎵᏣᎢᏍ ᎠᏕᎳ),
			},
		},
		'KHR' => {
			display_name => {
				'currency' => q(ᎧᎹᏉᏗᎠᏂ ᎠᏕᎳ),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(ᎪᎼᎳᏍ ᎠᏕᎳ),
			},
		},
		'KPW' => {
			display_name => {
				'currency' => q(ᏧᏴᏢ ᎪᎵᎠ ᎠᏕᎳ),
			},
		},
		'KRW' => {
			display_name => {
				'currency' => q(ᏧᎦᎾᏮ ᎪᎵᎠ ᎠᏕᎳ),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(ᎫᏪᎢᏘ ᎠᏕᎳ),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(ᎨᎢᎹᏂ ᏚᎦᏚᏛᎢ ᎠᏕᎳ),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(ᎧᏎᎧᏍᏕᏂ ᎠᏕᎳ),
			},
		},
		'LAK' => {
			display_name => {
				'currency' => q(ᎳᎣ ᎠᏕᎳ),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(ᎴᏆᎾᏂ ᎠᏕᎳ),
			},
		},
		'LKR' => {
			display_name => {
				'currency' => q(ᏍᎵ ᎳᏂᎧ ᎠᏕᎳ),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(ᎳᏈᎵᏯ ᎠᏕᎳ),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(ᎴᏐᏠ ᎶᏘ),
				'one' => q(ᎴᏐᏠ ᎶᏘ),
				'other' => q(ᎴᏐᏠ ᎶᏘᏍ),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(ᎵᏈᏯ ᎠᏕᎳ),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(ᎼᎶᎪ ᎠᏕᎳ),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(ᎹᎵᏙᏫᎠ ᎠᏕᎳ),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(ᎹᎳᎦᏏ ᎠᏕᎳ),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(ᎹᏎᏙᏂᎠ ᎠᏕᎳ),
			},
		},
		'MMK' => {
			display_name => {
				'currency' => q(ᎹᏯᎹᎵ ᎠᏕᎳ),
			},
		},
		'MNT' => {
			display_name => {
				'currency' => q(ᎹᏂᎪᎵᎠ ᎠᏕᎳ),
			},
		},
		'MOP' => {
			display_name => {
				'currency' => q(ᎹᎧᎣ ᎠᏕᎳ),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(ᎹᏈᏔᏂᎠ ᎠᏕᎳ \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(ᎹᏈᏔᏂᎠ ᎠᏕᎳ),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(ᎹᏘᎢᏯ ᎠᏕᎳ),
			},
		},
		'MVR' => {
			display_name => {
				'currency' => q(ᎹᎵᏗᏫᏍ ᎠᏕᎳ),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(ᎹᎳᏫ ᎠᏕᎳ),
			},
		},
		'MXN' => {
			display_name => {
				'currency' => q(ᏍᏆᏂ ᎠᏕᎳ),
			},
		},
		'MYR' => {
			display_name => {
				'currency' => q(ᎹᎴᏏᎢᎠ ᎠᏕᎳ),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(ᎼᏎᎻᏇᎩ ᎠᏕᎳ),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(ᎾᎻᏈᎢᏯ ᎠᏕᎳ),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(ᏂᏥᎵᏯ ᎠᏕᎳ),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(ᏂᎧᎳᏆ ᎠᏕᎳ),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(ᏃᏪ ᎠᏕᎳ),
			},
		},
		'NPR' => {
			display_name => {
				'currency' => q(ᏁᏆᎵ ᎠᏕᎳ),
			},
		},
		'NZD' => {
			display_name => {
				'currency' => q(ᎢᏤ ᏏᎢᎴᏂᏗ ᎠᏕᎳ),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(ᎣᎺᏂ ᎠᏕᎳ),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(ᏆᎾᎹ ᎠᏕᎳ),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(ᏇᎷ ᎠᏕᎳ),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(ᏆᏇ ᎢᏤ ᎩᎢᏂ ᎠᏕᎳ),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(ᎠᏂᏈᎵᎩᏃ ᎠᏕᎳ),
			},
		},
		'PKR' => {
			display_name => {
				'currency' => q(ᏆᎩᏍᏖᏂ ᎠᏕᎳ),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(ᏉᎳᏂ ᎠᏕᎳ),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(ᏆᎳᏇᎢᏯ ᎠᏕᎳ),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(ᎧᏔᎵ ᎠᏕᎳ),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(ᎶᎹᏂᏯ ᎠᏕᎳ),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(ᏒᏈᏯ ᎠᏕᎳ),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(ᏲᏂᎢ ᎠᏕᎳ),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(ᎶᏩᏂᏓ ᎠᏕᎳ),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(ᏌᎤᏗ ᎠᏕᎳ),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(ᏐᎶᎹᏂ ᏚᎦᏚᏛᎢ ᎠᏕᎳ),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(ᏏᎡᏥᎵᏍ ᎠᏕᎳ),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(ᏑᏕᏂ ᎠᏕᎳ),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(ᏍᏫᏕᏂ ᎠᏕᎳ),
			},
		},
		'SGD' => {
			display_name => {
				'currency' => q(ᏏᏂᎦᏉᎵ ᎠᏕᎳ),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(ᎤᏓᏅᏘ ᎮᎵᎾ ᎠᏕᎳ),
			},
		},
		'SLE' => {
			display_name => {
				'currency' => q(ᏏᎡᎳᎴᎣᏂ ᎠᏕᎳ),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(ᏏᎡᎳᎴᎣᏂ ᎠᏕᎳ \(1964—2022\)),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(ᏐᎹᎵ ᎠᏕᎳ),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(ᏒᎵᎾᎻ ᎠᏕᎳ),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(ᏧᎦᎾᏮ ᏑᏕᏂ ᎠᏕᎳ),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(ᏌᎣᏙᎺ ᎠᎴ ᏈᏂᏏᏇ ᎠᏕᎳ \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(ᏌᎣᏙᎺ & ᏈᏂᏏᏇ ᎠᏕᎳ),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(ᏏᎵᎠ ᎠᏕᎳ),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(ᏍᏩᏏ ᎠᏕᎳ),
			},
		},
		'THB' => {
			display_name => {
				'currency' => q(ᏔᏯᎴᏂ ᎠᏕᎳ),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(ᏔᏥᎩᏍᏕᏂ ᎠᏕᎳ),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(ᏛᎵᎩᎺᏂᏍᏔᏂ ᎠᏕᎳ),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(ᏚᏂᏏᏍᎠ ᎠᏕᎳ),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(ᏔᏂᎪ ᎠᏕᎳ),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(ᎬᏃ ᎠᏕᎳ),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(ᏟᏂᏕᏗ & ᏙᏆᎪ ᎠᏕᎳ),
			},
		},
		'TWD' => {
			display_name => {
				'currency' => q(ᎢᏤ ᏔᎢᏩᏂ ᎠᏕᎳ),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(ᏖᏂᏏᏂᏯ ᎠᏕᎳ),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(ᏳᎧᎴᏂ ᎠᏕᎳ),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(ᏳᎦᏂᏓ ᎠᏕᎳ),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(US ᎠᏕᎳ),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(ᏳᎷᏇ ᎠᏕᎳ),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(ᎤᏍᏇᎩᏍᏖᏂ ᎠᏕᎳ),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(ᏪᏁᏑᏪ ᎠᏕᎳ \(2008–2018\)),
				'one' => q(ᏪᏁᏑᏪᎳ ᎠᏕᎳ),
				'other' => q(ᏪᏁᏑᏪᎳ ᎠᏕᎳ),
			},
		},
		'VES' => {
			display_name => {
				'currency' => q(ᏪᏁᏑᏪ ᎠᏕᎳ),
			},
		},
		'VND' => {
			display_name => {
				'currency' => q(ᏫᎡᏘᎾᎻᏍ ᎠᏕᎳ),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(ᏩᏂᎤᏩᏚ ᎠᏕᎳ),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(ᏌᎼᎠ ᎠᏕᎳ),
			},
		},
		'XAF' => {
			display_name => {
				'currency' => q(ᎠᏰᏟ ᎬᎿᎨᏍᏛ CFA ᎠᏕᎳ),
			},
		},
		'XCD' => {
			display_name => {
				'currency' => q(ᏗᎧᎸᎬ ᎨᏆᏙᏯ ᎠᏕᎳ),
			},
		},
		'XOF' => {
			display_name => {
				'currency' => q(ᏭᏕᎵᎬ ᎬᎿᎨᏍᏛ CFA ᎠᏕᎳ),
			},
		},
		'XPF' => {
			display_name => {
				'currency' => q(CFP ᎠᏕᎳ),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(ᏄᏬᎵᏍᏛᎾ ᎠᏕᎳ),
				'one' => q(\(ᏄᏬᎵᏍᏛᎾ ᎠᏕᎳ\)),
				'other' => q(\(ᏄᏬᎵᏍᏛᎾ ᎠᏕᎳ\)),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(ᏰᎺᏂ ᎠᏕᎳ),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(ᏧᎦᎾᏮ ᎬᎿᎨᏍᏛ ᎠᏕᎳ),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(ᏏᎻᏆᏇ ᎠᏕᎳ),
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
							'ᎤᏃ',
							'ᎧᎦ',
							'ᎠᏅ',
							'ᎧᏬ',
							'ᎠᏂ',
							'ᏕᎭ',
							'ᎫᏰ',
							'ᎦᎶ',
							'ᏚᎵ',
							'ᏚᏂ',
							'ᏅᏓ',
							'ᎥᏍ'
						],
						leap => [
							
						],
					},
					wide => {
						nonleap => [
							'ᎤᏃᎸᏔᏅ',
							'ᎧᎦᎵ',
							'ᎠᏅᏱ',
							'ᎧᏬᏂ',
							'ᎠᏂᏍᎬᏘ',
							'ᏕᎭᎷᏱ',
							'ᎫᏰᏉᏂ',
							'ᎦᎶᏂ',
							'ᏚᎵᏍᏗ',
							'ᏚᏂᏅᏗ',
							'ᏅᏓᏕᏆ',
							'ᎥᏍᎩᏱ'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					narrow => {
						nonleap => [
							'Ꭴ',
							'Ꭷ',
							'Ꭰ',
							'Ꭷ',
							'Ꭰ',
							'Ꮥ',
							'Ꭻ',
							'Ꭶ',
							'Ꮪ',
							'Ꮪ',
							'Ꮕ',
							'Ꭵ'
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
						mon => 'ᏉᏅᎯ',
						tue => 'ᏔᎵᏁ',
						wed => 'ᏦᎢᏁ',
						thu => 'ᏅᎩᏁ',
						fri => 'ᏧᎾᎩ',
						sat => 'ᏈᏕᎾ',
						sun => 'ᏆᏍᎬ'
					},
					short => {
						mon => 'ᏅᎯ',
						tue => 'ᏔᎵ',
						wed => 'ᏦᎢ',
						thu => 'ᏅᎩ',
						fri => 'ᏧᎾ',
						sat => 'ᏕᎾ',
						sun => 'ᏍᎬ'
					},
					wide => {
						mon => 'ᎤᎾᏙᏓᏉᏅᎯ',
						tue => 'ᏔᎵᏁᎢᎦ',
						wed => 'ᏦᎢᏁᎢᎦ',
						thu => 'ᏅᎩᏁᎢᎦ',
						fri => 'ᏧᎾᎩᎶᏍᏗ',
						sat => 'ᎤᎾᏙᏓᏈᏕᎾ',
						sun => 'ᎤᎾᏙᏓᏆᏍᎬ'
					},
				},
				'stand-alone' => {
					narrow => {
						mon => 'Ꮙ',
						tue => 'Ꮤ',
						wed => 'Ꮶ',
						thu => 'Ꮕ',
						fri => 'Ꮷ',
						sat => 'Ꭴ',
						sun => 'Ꮖ'
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
					wide => {0 => '1st ᎩᏄᏙᏗ',
						1 => '2nd ᎩᏄᏙᏗ',
						2 => '3rd ᎩᏄᏙᏗ',
						3 => '4th ᎩᏄᏙᏗ'
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
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1200;
				}
				last SWITCH;
				}
			if ($_ eq 'gregorian') {
				if($day_period_type eq 'default') {
					return 'noon' if $time == 1200;
					return 'afternoon1' if $time >= 1200
						&& $time < 2400;
					return 'morning1' if $time >= 0
						&& $time < 1200;
				}
				if($day_period_type eq 'selection') {
					return 'afternoon1' if $time >= 1200
						&& $time < 2400;
					return 'morning1' if $time >= 0
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
				'abbreviated' => {
					'afternoon1' => q{ᏒᎯᏱᎢᏗᏢ},
					'am' => q{ᏌᎾᎴ},
					'morning1' => q{ᏌᎾᎴ},
					'noon' => q{ᎢᎦ},
					'pm' => q{ᏒᎯᏱᎢ},
				},
				'narrow' => {
					'afternoon1' => q{ᏒᎯᏱᎢᏗᏢ},
					'am' => q{Ꮜ},
					'morning1' => q{ᏌᎾᎴ},
					'noon' => q{Ꭲ},
					'pm' => q{Ꮢ},
				},
				'wide' => {
					'am' => q{ᏌᎾᎴ},
					'pm' => q{ᏒᎯᏱᎢᏗᏢ},
				},
			},
			'stand-alone' => {
				'wide' => {
					'am' => q{ᏌᎾᎴ},
					'pm' => q{ᏒᎯᏱᎢᏗᏢ},
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
				'0' => 'BC',
				'1' => 'AD'
			},
			wide => {
				'0' => 'ᏧᏓᎷᎸ ᎤᎷᎯᏍᏗ ᎦᎶᏁᏛ',
				'1' => 'ᎠᏃ ᏙᎻᏂ'
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
			'full' => q{EEEE, MMMM d, y G},
			'long' => q{MMMM d, y G},
			'medium' => q{MMM d, y G},
			'short' => q{M/d/y GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, MMMM d, y},
			'long' => q{MMMM d, y},
			'medium' => q{MMM d, y},
			'short' => q{M/d/yy},
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
			'full' => q{h:mm:ss a zzzz},
			'long' => q{h:mm:ss a z},
			'medium' => q{h:mm:ss a},
			'short' => q{h:mm a},
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
			'short' => q{{1}, {0}},
		},
	} },
);

has 'datetime_formats_available_formats' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub { {
		'generic' => {
			Ed => q{d E},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			GyMd => q{M/d/y GGGGG},
			Hm => q{H:mm},
			Hms => q{H:mm:ss},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			Md => q{M/d},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M/y GGGGG},
			yyyyMEd => q{E, M/d/y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, MMM d, y G},
			yyyyMMMM => q{MMMM y G},
			yyyyMMMd => q{MMM d, y G},
			yyyyMd => q{M/d/y GGGGG},
			yyyyQQQ => q{QQQ y G},
			yyyyQQQQ => q{QQQQ y G},
		},
		'gregorian' => {
			Ed => q{d E},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, MMM d, y G},
			GyMMMd => q{MMM d, y G},
			GyMd => q{M/d/y GGGGG},
			MEd => q{E, M/d},
			MMMEd => q{E, MMM d},
			MMMMW => q{ᏒᎾᏙᏓᏆᏍᏗ W ᎾᎿ MMMM},
			Md => q{M/d},
			yM => q{M/y},
			yMEd => q{E, M/d/y},
			yMMM => q{MMM y},
			yMMMEd => q{E, MMM d, y},
			yMMMM => q{MMMM y},
			yMMMd => q{MMM d, y},
			yMd => q{M/d/y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
			yw => q{’ᏒᎾᏙᏓᏆᏍᏗ’ w ’ᎾᎿ’ Y},
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
				h => q{h – h B},
			},
			Bhm => {
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, M/d/y – E, M/d/y GGGGG},
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d, y G – E, MMM d, y G},
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			GyMMMd => {
				G => q{MMM d, y G – MMM d, y G},
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			GyMd => {
				G => q{M/d/y GGGGG – M/d/y GGGGG},
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				d => q{MMM d – d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} – {1}',
			y => {
				y => q{y – y G},
			},
			yM => {
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			yMEd => {
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			yMMM => {
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			yMMMM => {
				M => q{MMMM – MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			yMd => {
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
		},
		'gregorian' => {
			Bh => {
				h => q{h – h B},
			},
			Bhm => {
				h => q{h:mm – h:mm B},
				m => q{h:mm – h:mm B},
			},
			Gy => {
				G => q{y G – y G},
				y => q{y G – y G},
			},
			GyM => {
				G => q{M/y GGGGG – M/y GGGGG},
				M => q{M/y – M/y GGGGG},
				y => q{M/y – M/y GGGGG},
			},
			GyMEd => {
				G => q{E, M/d/y GGGGG – E, M/d/y GGGGG},
				M => q{E, M/d/y – E, M/d/y GGGGG},
				d => q{E, M/d/y – E, M/d/y GGGGG},
				y => q{E, M/d/y – E, M/d/y GGGGG},
			},
			GyMMM => {
				G => q{MMM y G – MMM y G},
				M => q{MMM – MMM y G},
				y => q{MMM y – MMM y G},
			},
			GyMMMEd => {
				G => q{E, MMM d, y G – E, MMM d, y G},
				M => q{E, MMM d – E, MMM d, y G},
				d => q{E, MMM d – E, MMM d, y G},
				y => q{E, MMM d, y – E, MMM d, y G},
			},
			GyMMMd => {
				G => q{MMM d, y G – MMM d, y G},
				M => q{MMM d – MMM d, y G},
				d => q{MMM d – d, y G},
				y => q{MMM d, y – MMM d, y G},
			},
			GyMd => {
				G => q{M/d/y GGGGG – M/d/y GGGGG},
				M => q{M/d/y – M/d/y GGGGG},
				d => q{M/d/y – M/d/y GGGGG},
				y => q{M/d/y – M/d/y GGGGG},
			},
			H => {
				H => q{HH – HH},
			},
			Hm => {
				H => q{HH:mm – HH:mm},
				m => q{HH:mm – HH:mm},
			},
			Hmv => {
				H => q{HH:mm – HH:mm v},
				m => q{HH:mm – HH:mm v},
			},
			Hv => {
				H => q{HH – HH v},
			},
			M => {
				M => q{M – M},
			},
			MEd => {
				M => q{E, M/d – E, M/d},
				d => q{E, M/d – E, M/d},
			},
			MMM => {
				M => q{MMM – MMM},
			},
			MMMEd => {
				M => q{E, MMM d – E, MMM d},
				d => q{E, MMM d – E, MMM d},
			},
			MMMd => {
				d => q{MMM d – d},
			},
			Md => {
				M => q{M/d – M/d},
				d => q{M/d – M/d},
			},
			d => {
				d => q{d – d},
			},
			fallback => '{0} – {1}',
			h => {
				h => q{h – h a},
			},
			hm => {
				h => q{h:mm – h:mm a},
				m => q{h:mm – h:mm a},
			},
			hmv => {
				h => q{h:mm – h:mm a v},
				m => q{h:mm – h:mm a v},
			},
			hv => {
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
				M => q{E, M/d/y – E, M/d/y},
				d => q{E, M/d/y – E, M/d/y},
				y => q{E, M/d/y – E, M/d/y},
			},
			yMMM => {
				M => q{MMM – MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, MMM d – E, MMM d, y},
				d => q{E, MMM d – E, MMM d, y},
				y => q{E, MMM d, y – E, MMM d, y},
			},
			yMMMM => {
				M => q{MMMM – MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{MMM d – MMM d, y},
				d => q{MMM d – d, y},
				y => q{MMM d, y – MMM d, y},
			},
			yMd => {
				M => q{M/d/y – M/d/y},
				d => q{M/d/y – M/d/y},
				y => q{M/d/y – M/d/y},
			},
		},
	} },
);

has 'time_zone_names' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default	=> sub { {
		regionFormat => q({0} ᎠᏟᎢᎵᏒ),
		regionFormat => q({0} ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ),
		regionFormat => q({0} ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ),
		'Afghanistan' => {
			long => {
				'standard' => q#ᎠᏫᎨᏂᏍᏖᏂ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Africa/Abidjan' => {
			exemplarCity => q#ᎠᏈᏣᏂ#,
		},
		'Africa/Accra' => {
			exemplarCity => q#ᎠᏆ#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#ᎡᏗᏍ ᎠᏆᏆ#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#ᎠᎵᏥᎵ#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#ᎠᏏᎹᎳ#,
		},
		'Africa/Bamako' => {
			exemplarCity => q#ᏆᎹᎪ#,
		},
		'Africa/Bangui' => {
			exemplarCity => q#ᏇᏂᎫᏫ#,
		},
		'Africa/Banjul' => {
			exemplarCity => q#ᏆᏂᏧᎵ#,
		},
		'Africa/Bissau' => {
			exemplarCity => q#ᏇᏌᏫ#,
		},
		'Africa/Blantyre' => {
			exemplarCity => q#ᏆᏘᎴ#,
		},
		'Africa/Brazzaville' => {
			exemplarCity => q#ᏆᏌᏩᎵ#,
		},
		'Africa/Bujumbura' => {
			exemplarCity => q#ᏊᏧᎻᏊᎳ#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#ᎧᏯᎶ#,
		},
		'Africa/Casablanca' => {
			exemplarCity => q#ᎤᏁᎦ ᎦᎵᏦᏕ#,
		},
		'Africa/Ceuta' => {
			exemplarCity => q#ᏑᏔ#,
		},
		'Africa/Conakry' => {
			exemplarCity => q#ᎪᎾᏈ#,
		},
		'Africa/Dakar' => {
			exemplarCity => q#ᏓᎧᏩ#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Ꮣ ᎡᏏ ᏌᎳᎻ#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#ᏥᏊᏗ#,
		},
		'Africa/Douala' => {
			exemplarCity => q#ᏙᎤᏩᎳ#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#ᎡᎵ ᎠᏱᏳᏂ#,
		},
		'Africa/Freetown' => {
			exemplarCity => q#ᎠᏎᏇ ᎦᏚᎲ#,
		},
		'Africa/Gaborone' => {
			exemplarCity => q#ᎦᏉᎶᏁ#,
		},
		'Africa/Harare' => {
			exemplarCity => q#ᎭᎳᎴ#,
		},
		'Africa/Johannesburg' => {
			exemplarCity => q#ᏦᎭᏁᏍᏊᎦ#,
		},
		'Africa/Juba' => {
			exemplarCity => q#ᏧᏆ#,
		},
		'Africa/Kampala' => {
			exemplarCity => q#ᎧᎻᏆᎳ#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#ᎧᏚᎻ#,
		},
		'Africa/Kigali' => {
			exemplarCity => q#ᎩᎦᎵ#,
		},
		'Africa/Kinshasa' => {
			exemplarCity => q#ᎨᏂᏝᏌ#,
		},
		'Africa/Lagos' => {
			exemplarCity => q#ᎳᎪᏏ#,
		},
		'Africa/Libreville' => {
			exemplarCity => q#ᎵᏇᏫᎵ#,
		},
		'Africa/Lome' => {
			exemplarCity => q#ᎶᎺ#,
		},
		'Africa/Luanda' => {
			exemplarCity => q#ᎷᏩᏂᏓ#,
		},
		'Africa/Lubumbashi' => {
			exemplarCity => q#ᎷᏊᏆᏏ#,
		},
		'Africa/Lusaka' => {
			exemplarCity => q#ᎵᏌᎧ#,
		},
		'Africa/Malabo' => {
			exemplarCity => q#ᎹᎳᏉ#,
		},
		'Africa/Maputo' => {
			exemplarCity => q#ᎹᏊᏙ#,
		},
		'Africa/Maseru' => {
			exemplarCity => q#ᎹᏎᎵ#,
		},
		'Africa/Mbabane' => {
			exemplarCity => q#ᏆᏇᏁ#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#ᎼᎦᏗᏡ#,
		},
		'Africa/Monrovia' => {
			exemplarCity => q#ᎼᏂᎶᏫᏯ#,
		},
		'Africa/Nairobi' => {
			exemplarCity => q#ᎾᏱᎶᏈ#,
		},
		'Africa/Ndjamena' => {
			exemplarCity => q#ᎾᏣᎺᎾ#,
		},
		'Africa/Niamey' => {
			exemplarCity => q#ᏂᏯᎺ#,
		},
		'Africa/Nouakchott' => {
			exemplarCity => q#ᎾᏬᏣᏘ#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#ᎣᏩᎦᏚᎫ#,
		},
		'Africa/Porto-Novo' => {
			exemplarCity => q#ᏥᏳᏗᏔᎳᏗᏍᏗ-ᏃᏬ#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#ᏌᎣᏙᎺ#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#ᏟᏉᎵ#,
		},
		'Africa/Tunis' => {
			exemplarCity => q#ᏚᏂᏏ#,
		},
		'Africa/Windhoek' => {
			exemplarCity => q#ᏪᏄᏗᎰᎩ#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#ᎠᏰᏟ ᎬᎿᎨᏍᏛ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#ᏗᎧᎸᎬ ᎬᎿᎨᏍᏛ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#ᏧᎦᎾᏮ ᎬᎿᎨᏍᏛ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#ᏭᏕᎵᎬ ᎬᎿᎨᏍᏛ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏭᏕᎵᎬ ᎬᎿᎨᏍᏛ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏭᏕᎵᎬ ᎬᎿᎨᏍᏛ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#ᎠᎳᏍᎦ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎠᎳᏍᎦ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎠᎳᏍᎦ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
			short => {
				'daylight' => q#AKDT#,
				'generic' => q#AKT#,
				'standard' => q#AKST#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#ᎠᎺᏌᏂ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎠᎺᏌᏂ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎠᎺᏌᏂ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'America/Adak' => {
			exemplarCity => q#ᎠᏓᎧ#,
		},
		'America/Anchorage' => {
			exemplarCity => q#ᎠᏂᎪᎴᏥ#,
		},
		'America/Anguilla' => {
			exemplarCity => q#ᎠᏂᎩᎳ#,
		},
		'America/Antigua' => {
			exemplarCity => q#ᎤᏪᏘ#,
		},
		'America/Araguaina' => {
			exemplarCity => q#ᎠᎳᎫᏩᏱᎾ#,
		},
		'America/Argentina/La_Rioja' => {
			exemplarCity => q#Ꮃ ᎵᏲᎭ#,
		},
		'America/Argentina/Rio_Gallegos' => {
			exemplarCity => q#ᎦᏰᎪᏏ ᎤᏪᏴ#,
		},
		'America/Argentina/Salta' => {
			exemplarCity => q#ᏌᎳᏔ#,
		},
		'America/Argentina/San_Juan' => {
			exemplarCity => q#ᏌᏂ ᏩᏂ#,
		},
		'America/Argentina/San_Luis' => {
			exemplarCity => q#ᎤᏓᏅᏗ ᎷᏫᏏ#,
		},
		'America/Argentina/Tucuman' => {
			exemplarCity => q#ᏚᎫᎹᏂ#,
		},
		'America/Argentina/Ushuaia' => {
			exemplarCity => q#ᎤᏑᏩᏯ#,
		},
		'America/Aruba' => {
			exemplarCity => q#ᎠᎷᏆ#,
		},
		'America/Asuncion' => {
			exemplarCity => q#ᎠᏑᏏᏲᏅ#,
		},
		'America/Bahia' => {
			exemplarCity => q#ᏆᎯᏯ#,
		},
		'America/Bahia_Banderas' => {
			exemplarCity => q#ᏆᎯᏯ ᏆᏂᏕᎳᏏ#,
		},
		'America/Barbados' => {
			exemplarCity => q#ᏆᏇᏙᏍ#,
		},
		'America/Belem' => {
			exemplarCity => q#ᏇᎴᎻ#,
		},
		'America/Belize' => {
			exemplarCity => q#ᏇᎵᏍ#,
		},
		'America/Blanc-Sablon' => {
			exemplarCity => q#ᏝᏂ-ᏌᏠᏂ#,
		},
		'America/Boa_Vista' => {
			exemplarCity => q#ᎣᏍᏓ ᎠᎪᎵᏰᏗ#,
		},
		'America/Bogota' => {
			exemplarCity => q#ᏉᎪᏔ#,
		},
		'America/Boise' => {
			exemplarCity => q#ᏉᏱᏏ#,
		},
		'America/Buenos_Aires' => {
			exemplarCity => q#ᎣᏍᏓ ᎤᏃᎴ#,
		},
		'America/Cambridge_Bay' => {
			exemplarCity => q#ᎨᎻᏈᏥ ᎡᏉᏄᎸᏗ#,
		},
		'America/Campo_Grande' => {
			exemplarCity => q#ᎤᏔᎾ ᏠᎨᏏ#,
		},
		'America/Cancun' => {
			exemplarCity => q#ᎨᏂᎫᏂ#,
		},
		'America/Caracas' => {
			exemplarCity => q#ᎧᎳᎧᏏ#,
		},
		'America/Catamarca' => {
			exemplarCity => q#ᎧᏔᎹᎧ#,
		},
		'America/Cayenne' => {
			exemplarCity => q#ᎧᏰᏂ#,
		},
		'America/Cayman' => {
			exemplarCity => q#ᎨᎢᎹᏂ#,
		},
		'America/Chicago' => {
			exemplarCity => q#ᏥᎧᎩ#,
		},
		'America/Chihuahua' => {
			exemplarCity => q#ᏥᏩᏩ#,
		},
		'America/Ciudad_Juarez' => {
			exemplarCity => q#ᏏᏳᏓ ᏆᎡᏏ#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#ᎠᏘᎪᎦᏂ#,
		},
		'America/Cordoba' => {
			exemplarCity => q#ᎪᏙᏆ#,
		},
		'America/Costa_Rica' => {
			exemplarCity => q#ᎪᏍᏓᎵᎧ#,
		},
		'America/Creston' => {
			exemplarCity => q#ᏞᏍᏔᏂ#,
		},
		'America/Cuiaba' => {
			exemplarCity => q#ᏧᏫᏆ#,
		},
		'America/Curacao' => {
			exemplarCity => q#ᎫᎳᎨᎣ#,
		},
		'America/Danmarkshavn' => {
			exemplarCity => q#ᏕᎾᎹᎧᏌᏩᏂ#,
		},
		'America/Dawson' => {
			exemplarCity => q#ᏓᏌᏂ#,
		},
		'America/Dawson_Creek' => {
			exemplarCity => q#ᏓᏌᏂ ᎤᏪᏴ#,
		},
		'America/Denver' => {
			exemplarCity => q#ᎦᎸᎳᏗ ᎦᏚᎲ#,
		},
		'America/Detroit' => {
			exemplarCity => q#ᏗᏠᏘ#,
		},
		'America/Dominica' => {
			exemplarCity => q#ᏙᎻᏂᎧ#,
		},
		'America/Edmonton' => {
			exemplarCity => q#ᎡᏗᎹᏂᏔᏂ#,
		},
		'America/Eirunepe' => {
			exemplarCity => q#ᎡᎷᏁᏇ#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#ᎡᎵ ᏌᎵᏆᏙᎵ#,
		},
		'America/Fort_Nelson' => {
			exemplarCity => q#ᏗᏐᏴ ᏁᎵᏌᏂ#,
		},
		'America/Fortaleza' => {
			exemplarCity => q#ᏬᏔᎴᏎ#,
		},
		'America/Glace_Bay' => {
			exemplarCity => q#ᏞᏏ ᎡᏉᏄᎸᏗ#,
		},
		'America/Godthab' => {
			exemplarCity => q#ᏄᎩ#,
		},
		'America/Goose_Bay' => {
			exemplarCity => q#ᏌᏌ ᎡᏉᏄᎸᏗ#,
		},
		'America/Grand_Turk' => {
			exemplarCity => q#ᏄᎬᏫᏳᏒ ᎬᎾ#,
		},
		'America/Grenada' => {
			exemplarCity => q#ᏋᎾᏓ#,
		},
		'America/Guadeloupe' => {
			exemplarCity => q#ᏩᏓᎷᏇ#,
		},
		'America/Guatemala' => {
			exemplarCity => q#ᏩᏔᎹᎳ#,
		},
		'America/Guayaquil' => {
			exemplarCity => q#ᏆᏯᎩᎵ#,
		},
		'America/Guyana' => {
			exemplarCity => q#ᎦᏯᎾ#,
		},
		'America/Halifax' => {
			exemplarCity => q#ᎭᎵᏩᎧᏏ#,
		},
		'America/Havana' => {
			exemplarCity => q#ᎭᏩᎾ#,
		},
		'America/Hermosillo' => {
			exemplarCity => q#ᎮᎼᏏᎶ#,
		},
		'America/Indiana/Knox' => {
			exemplarCity => q#ᏃᏈᏏ, ᎢᏂᏗᏰᎾ#,
		},
		'America/Indiana/Marengo' => {
			exemplarCity => q#ᎹᎴᏂᎪ, ᎢᏂᏗᏰᎾ#,
		},
		'America/Indiana/Petersburg' => {
			exemplarCity => q#ᏈᏓᏈᎦ, ᎢᏂᏗᏰᎾ#,
		},
		'America/Indiana/Tell_City' => {
			exemplarCity => q#ᏖᎵ ᎦᏚᎲ, ᎢᏂᏗᏰᎾ#,
		},
		'America/Indiana/Vevay' => {
			exemplarCity => q#ᏪᏪ, ᎢᏂᏗᏰᎾ#,
		},
		'America/Indiana/Vincennes' => {
			exemplarCity => q#ᏫᏂᏎᏁᏏ, ᎢᏂᏗᏰᎾ#,
		},
		'America/Indiana/Winamac' => {
			exemplarCity => q#ᏫᎾᎹᎩ, ᎢᏂᏗᏰᎾ#,
		},
		'America/Indianapolis' => {
			exemplarCity => q#ᎢᏂᏗᎠᏂᎠᏉᎵᏏ#,
		},
		'America/Inuvik' => {
			exemplarCity => q#ᎢᏄᏫᎩ#,
		},
		'America/Iqaluit' => {
			exemplarCity => q#ᎢᏆᎷᏱᏘ#,
		},
		'America/Jamaica' => {
			exemplarCity => q#ᏣᎺᎢᎧ#,
		},
		'America/Jujuy' => {
			exemplarCity => q#ᏧᏧᏫ#,
		},
		'America/Juneau' => {
			exemplarCity => q#ᏧᏃ#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#ᎹᏂᏔᏎᎶ, ᎬᏅᏓᎩ#,
		},
		'America/Kralendijk' => {
			exemplarCity => q#ᏆᎴᏂᏗ#,
		},
		'America/La_Paz' => {
			exemplarCity => q#ᏙᎯ#,
		},
		'America/Lima' => {
			exemplarCity => q#ᎵᎹ#,
		},
		'America/Los_Angeles' => {
			exemplarCity => q#ᎾᏍᎩ ᏗᏂᎧᎿᏩᏗᏙᎯ#,
		},
		'America/Louisville' => {
			exemplarCity => q#ᎷᏫᏫᎵ#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#ᎡᎳᏗ ᏗᏜ ᎤᎬᏫᏳᎯ ᎩᏄᏙᏗ#,
		},
		'America/Maceio' => {
			exemplarCity => q#ᎹᏎᏲ#,
		},
		'America/Managua' => {
			exemplarCity => q#ᎹᎾᏆ#,
		},
		'America/Manaus' => {
			exemplarCity => q#ᎹᎾᎤᏏ#,
		},
		'America/Marigot' => {
			exemplarCity => q#ᎹᎵᎦᏘ#,
		},
		'America/Martinique' => {
			exemplarCity => q#ᎹᏘᏂᏇ#,
		},
		'America/Matamoros' => {
			exemplarCity => q#ᎹᏔᎼᎶᏏ#,
		},
		'America/Mazatlan' => {
			exemplarCity => q#ᎹᏌᏝᏂ#,
		},
		'America/Mendoza' => {
			exemplarCity => q#ᎺᎾᏙᏌ#,
		},
		'America/Menominee' => {
			exemplarCity => q#ᎺᏃᎻᏂ#,
		},
		'America/Merida' => {
			exemplarCity => q#ᎺᎵᏓ#,
		},
		'America/Metlakatla' => {
			exemplarCity => q#ᎺᏝᎧᏝ#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#ᎠᏂᏍᏆᏂ ᎦᏚᎲ#,
		},
		'America/Miquelon' => {
			exemplarCity => q#ᎻᎨᎶᏂ#,
		},
		'America/Moncton' => {
			exemplarCity => q#ᎹᎾᏔᏂ#,
		},
		'America/Monterrey' => {
			exemplarCity => q#ᎼᏖᎵ#,
		},
		'America/Montevideo' => {
			exemplarCity => q#ᎼᏂᏖᏫᏕᏲ#,
		},
		'America/Montserrat' => {
			exemplarCity => q#ᎹᏂᏘᏌᎳᏗ#,
		},
		'America/Nassau' => {
			exemplarCity => q#ᎾᏌᏫ#,
		},
		'America/New_York' => {
			exemplarCity => q#ᏄᏯᎩ#,
		},
		'America/Nome' => {
			exemplarCity => q#ᏃᎺ#,
		},
		'America/Noronha' => {
			exemplarCity => q#ᏃᎶᎾᎭ#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#ᏇᏳᎳ, ᏧᏴᏢ ᏓᎪᏔ#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#ᎠᏰᏟ, ᏧᏴᏢ ᏓᎪᏔ#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#ᎢᏤ ᏎᎴᎻ, ᏧᏴᏢ ᏓᎪᏔ#,
		},
		'America/Ojinaga' => {
			exemplarCity => q#ᎣᏥᎾᎦ#,
		},
		'America/Panama' => {
			exemplarCity => q#ᏆᎾᎹ#,
		},
		'America/Paramaribo' => {
			exemplarCity => q#ᏆᎳᎹᎴᏉ#,
		},
		'America/Phoenix' => {
			exemplarCity => q#ᏧᎴᎯᏌᏅᎯ#,
		},
		'America/Port-au-Prince' => {
			exemplarCity => q#ᏥᏳᏗᏔᎳᏗᏍᏗ-ᎾᎿ-ᎤᎬᏫᏳᎯ#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#ᏥᏳᏗᏔᎳᏗᏍᏗ ᏍᏆᏂᎨᏍᏛ#,
		},
		'America/Porto_Velho' => {
			exemplarCity => q#ᎤᏪᏘ ᏥᏳᏗᏔᎳᏗᏍᏗ#,
		},
		'America/Puerto_Rico' => {
			exemplarCity => q#ᏇᎡᏙ ᎵᎢᎪ#,
		},
		'America/Punta_Arenas' => {
			exemplarCity => q#ᏊᏔ ᎡᏫᎾᏍ#,
		},
		'America/Rankin_Inlet' => {
			exemplarCity => q#ᎴᏂᎩᏂ ᎢᏂᎴᏘ#,
		},
		'America/Recife' => {
			exemplarCity => q#ᎴᏏᏪ#,
		},
		'America/Regina' => {
			exemplarCity => q#ᎴᎩᎾ#,
		},
		'America/Resolute' => {
			exemplarCity => q#ᎴᏐᎷᏘ#,
		},
		'America/Rio_Branco' => {
			exemplarCity => q#ᎤᏁᎦ ᎤᏪᏴ#,
		},
		'America/Santarem' => {
			exemplarCity => q#ᏌᏂᏔᎴᎻ#,
		},
		'America/Santiago' => {
			exemplarCity => q#ᏌᏂᏘᏯᎪ#,
		},
		'America/Santo_Domingo' => {
			exemplarCity => q#ᏌᏂᏙ ᏙᎻᎪ#,
		},
		'America/Sao_Paulo' => {
			exemplarCity => q#ᏌᎣ ᏆᎶ#,
		},
		'America/Scoresbysund' => {
			exemplarCity => q#ᎢᏙᎪᏙᎻᏘ#,
		},
		'America/Sitka' => {
			exemplarCity => q#ᏏᏘᎧ#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#ᎤᏓᏅᏘ ᏆᎵᏞᎴᎻ#,
		},
		'America/St_Johns' => {
			exemplarCity => q#ᎤᏓᏅᏘ ᏣᏂ ᎤᏤᎵ#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#ᎤᏓᏅᏘ ᎩᏘᏏ#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#ᎤᏓᏅᏘ ᎷᏏᏯ#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#ᎤᏓᏅᏘ ᏙᎹᏏ#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#ᎤᏓᏅᏘ ᏫᏂᏎᏘ#,
		},
		'America/Swift_Current' => {
			exemplarCity => q#ᎠᏯᏄᎵ ᎤᏃᎴ#,
		},
		'America/Tegucigalpa' => {
			exemplarCity => q#ᏖᎫᏏᎦᎵᏆ#,
		},
		'America/Thule' => {
			exemplarCity => q#ᏡᎵ#,
		},
		'America/Tijuana' => {
			exemplarCity => q#ᏘᏳᏩᎾ#,
		},
		'America/Toronto' => {
			exemplarCity => q#ᏙᎳᎾᏙ#,
		},
		'America/Tortola' => {
			exemplarCity => q#ᏙᏙᎳ#,
		},
		'America/Vancouver' => {
			exemplarCity => q#ᏪᏂᎫᏪᎵ#,
		},
		'America/Whitehorse' => {
			exemplarCity => q#ᎤᏁᎦ ᏐᏈᎵ#,
		},
		'America/Winnipeg' => {
			exemplarCity => q#ᏫᏂᏇᎩ#,
		},
		'America/Yakutat' => {
			exemplarCity => q#ᏯᎫᏔᏘ#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#ᎠᏰᏟ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎠᏰᏟ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎠᏰᏟ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
			short => {
				'daylight' => q#CDT#,
				'generic' => q#CT#,
				'standard' => q#CST#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#ᏗᎧᎸᎬ ᏗᏜ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏗᎧᎸᎬ ᏗᏜ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏗᎧᎸᎬ ᏗᏜ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
			short => {
				'daylight' => q#EDT#,
				'generic' => q#ET#,
				'standard' => q#EST#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#ᎣᏓᎸ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎣᏓᎸ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎣᏓᎸ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
			short => {
				'daylight' => q#MDT#,
				'generic' => q#MT#,
				'standard' => q#MST#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#ᏭᏕᎵᎬ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏭᏕᎵᎬ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏭᏕᎵᎬ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
			short => {
				'daylight' => q#PDT#,
				'generic' => q#PT#,
				'standard' => q#PST#,
			},
		},
		'Antarctica/Casey' => {
			exemplarCity => q#ᎨᏏ#,
		},
		'Antarctica/Davis' => {
			exemplarCity => q#ᏕᏫᏏ#,
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#ᏚᎼᎾᏘ-Ꮧ’ᎤᎵᏫᎵ#,
		},
		'Antarctica/Macquarie' => {
			exemplarCity => q#ᎹᏇᎵ#,
		},
		'Antarctica/Mawson' => {
			exemplarCity => q#ᎹᏌᏂ#,
		},
		'Antarctica/McMurdo' => {
			exemplarCity => q#ᎻᎦᎽᏙ#,
		},
		'Antarctica/Palmer' => {
			exemplarCity => q#ᏆᎵᎺᎵ#,
		},
		'Antarctica/Rothera' => {
			exemplarCity => q#ᎳᏞᎳ#,
		},
		'Antarctica/Syowa' => {
			exemplarCity => q#ᏏᏲᏩ#,
		},
		'Antarctica/Troll' => {
			exemplarCity => q#ᏠᎵ#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#ᏬᏍᏙᎧ#,
		},
		'Apia' => {
			long => {
				'daylight' => q#ᎠᏈᎠ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎠᏈᎠ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎠᏈᎠ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Arabian' => {
			long => {
				'daylight' => q#ᎠᎴᏈᏯ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎠᎴᏈᏯ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎠᎴᏈᏯ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Arctic/Longyearbyen' => {
			exemplarCity => q#ᎦᏅᎯᏓ ᎤᏕᏘᏴᏌᏗᏒᎢ ᎦᏚᎲ#,
		},
		'Argentina' => {
			long => {
				'daylight' => q#ᎠᏥᏂᏘᏂᎠ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎠᏥᏂᏘᏂᎠ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎠᏥᏂᏘᏂᎠ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#ᏭᏕᎵᎬ ᏗᏜ ᎠᏥᏂᏘᏂᎠ ᎪᎩ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏭᏕᎵᎬ ᏗᏜ ᎠᏥᏂᏘᏂᎠ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏭᏕᎵᎬ ᏗᏜ ᎠᏥᏂᏘᏂᎠ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#ᎠᎵᎻᏂᎠ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎠᎵᎻᏂᎠ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎠᎵᎻᏂᎠ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Asia/Aden' => {
			exemplarCity => q#ᎡᏕᏂ#,
		},
		'Asia/Almaty' => {
			exemplarCity => q#ᎠᎵᎹᏘ#,
		},
		'Asia/Amman' => {
			exemplarCity => q#ᎠᎹᏂ#,
		},
		'Asia/Anadyr' => {
			exemplarCity => q#ᎠᎾᏗᎵ#,
		},
		'Asia/Aqtau' => {
			exemplarCity => q#ᎠᎦᏔᏫ#,
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#ᎠᎦᏙᏇ#,
		},
		'Asia/Ashgabat' => {
			exemplarCity => q#ᎠᏍᎦᏆᏘ#,
		},
		'Asia/Atyrau' => {
			exemplarCity => q#ᎠᏘᏆᎤ#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#ᏆᎩᏓᏗ#,
		},
		'Asia/Bahrain' => {
			exemplarCity => q#ᏆᎭᎴᎢᏂ#,
		},
		'Asia/Baku' => {
			exemplarCity => q#ᏆᎫ#,
		},
		'Asia/Bangkok' => {
			exemplarCity => q#ᏇᏂᎩᎪᎩ#,
		},
		'Asia/Barnaul' => {
			exemplarCity => q#ᏆᎾᎣᎵ#,
		},
		'Asia/Beirut' => {
			exemplarCity => q#ᏇᎷᏘ#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#ᏇᏍᎨᎩ#,
		},
		'Asia/Brunei' => {
			exemplarCity => q#ᏊᎾᎢ#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#ᎪᎵᎧᏔ#,
		},
		'Asia/Chita' => {
			exemplarCity => q#ᏥᏔ#,
		},
		'Asia/Colombo' => {
			exemplarCity => q#ᎪᎶᎻᏉ#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#ᏓᎹᏍᎬᏏ#,
		},
		'Asia/Dhaka' => {
			exemplarCity => q#ᏓᎧ#,
		},
		'Asia/Dili' => {
			exemplarCity => q#ᏗᎵ#,
		},
		'Asia/Dubai' => {
			exemplarCity => q#ᏚᏆᏱ#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#ᏚᏝᎾᏇ#,
		},
		'Asia/Famagusta' => {
			exemplarCity => q#ᏆᎹᎫᏍᏔ#,
		},
		'Asia/Gaza' => {
			exemplarCity => q#ᎦᏌ#,
		},
		'Asia/Hebron' => {
			exemplarCity => q#ᎮᏉᏂ#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#ᎰᏂᎩ ᎪᏂᎩ#,
		},
		'Asia/Hovd' => {
			exemplarCity => q#ᎰᏩᏗ#,
		},
		'Asia/Irkutsk' => {
			exemplarCity => q#ᎢᎫᏥᎧ#,
		},
		'Asia/Jakarta' => {
			exemplarCity => q#ᏣᎧᏔ#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#ᏣᏯᏋᎳ#,
		},
		'Asia/Jerusalem' => {
			exemplarCity => q#ᏤᎷᏌᎴᎻ#,
		},
		'Asia/Kabul' => {
			exemplarCity => q#ᎧᏊᎵ#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#ᎧᎻᏣᎧ#,
		},
		'Asia/Karachi' => {
			exemplarCity => q#ᎧᎳᏥ#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#ᎧᏘᎹᏂᏚ#,
		},
		'Asia/Khandyga' => {
			exemplarCity => q#ᎧᏂᏗᎦ#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#ᏝᏍᏃᏯᏍᎧ#,
		},
		'Asia/Kuala_Lumpur' => {
			exemplarCity => q#ᎫᏩᎳ ᎸᎻᏋ#,
		},
		'Asia/Kuching' => {
			exemplarCity => q#ᎫᏥᏂᎦ#,
		},
		'Asia/Kuwait' => {
			exemplarCity => q#ᎫᏪᏘ#,
		},
		'Asia/Macau' => {
			exemplarCity => q#ᎹᎧᎤ#,
		},
		'Asia/Magadan' => {
			exemplarCity => q#ᎹᎦᏓᏂ#,
		},
		'Asia/Makassar' => {
			exemplarCity => q#ᎹᎧᏌᎵ#,
		},
		'Asia/Manila' => {
			exemplarCity => q#ᎹᏂᎳ#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#ᎽᏍᎦᏘ#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#ᏂᎪᏏᏯ#,
		},
		'Asia/Novokuznetsk' => {
			exemplarCity => q#ᏃᏬᎫᏁᏖᏍᎧ#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#ᏃᏬᏏᏈᏍᎧ#,
		},
		'Asia/Omsk' => {
			exemplarCity => q#ᎣᎻᏍᎧ#,
		},
		'Asia/Oral' => {
			exemplarCity => q#ᎣᎳᎵ#,
		},
		'Asia/Phnom_Penh' => {
			exemplarCity => q#ᎿᎻ ᏇᏂ#,
		},
		'Asia/Pontianak' => {
			exemplarCity => q#ᏆᏂᏘᎠᎾᎩ#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#ᏈᏯᏂᎩᏰᏂᎩ#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#ᎧᏔᎵ#,
		},
		'Asia/Qostanay' => {
			exemplarCity => q#ᎧᏍᏔᏁ#,
		},
		'Asia/Qyzylorda' => {
			exemplarCity => q#ᎩᏏᎶᎳᏓ#,
		},
		'Asia/Rangoon' => {
			exemplarCity => q#ᎳᏂᎫᏂ#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#ᎵᏯᏗ#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ꮀ Ꮵ ᎻᏂ ᎦᏚᎲ#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#ᏌᎧᎵᏂ#,
		},
		'Asia/Samarkand' => {
			exemplarCity => q#ᏌᎹᎧᏂᏗ#,
		},
		'Asia/Seoul' => {
			exemplarCity => q#ᏐᎵ#,
		},
		'Asia/Shanghai' => {
			exemplarCity => q#ᏎᏂᎦᎭᏱ#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#ᏏᏂᎦᏉᎵ#,
		},
		'Asia/Srednekolymsk' => {
			exemplarCity => q#ᏍᎴᏗᏁᎪᎵᎻᏍᎧ#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#ᏔᏱᏇ#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#ᏔᏏᎨᏂᏘ#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#ᏘᏈᎵᏏ#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#ᏖᎳᏂ#,
		},
		'Asia/Thimphu' => {
			exemplarCity => q#ᏞᎻᏡ#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#ᏙᎩᏲ#,
		},
		'Asia/Tomsk' => {
			exemplarCity => q#ᏙᎻᏍᎧ#,
		},
		'Asia/Ulaanbaatar' => {
			exemplarCity => q#ᎤᎳᏂᏆᏔ#,
		},
		'Asia/Urumqi' => {
			exemplarCity => q#ᎤᎷᎻᎩ#,
		},
		'Asia/Ust-Nera' => {
			exemplarCity => q#ᎤᏍᏔ-ᏁᎳ#,
		},
		'Asia/Vientiane' => {
			exemplarCity => q#ᏫᏰᏂᏘᏯᏁ#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#ᏭᎳᏗᏬᏍᏙᎩ#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#ᏯᎫᏥᎧ#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#ᏰᎧᏖᎵᏂᏊᎦ#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#ᏰᎴᏪᏂ#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#ᏗᎧᎸᎬ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏗᎧᎸᎬ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏗᎧᎸᎬ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
			short => {
				'daylight' => q#ADT#,
				'generic' => q#AT#,
				'standard' => q#AST#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#ᎠᏐᎴᏏ#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#ᏆᏊᏓ#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#ᏥᏍᏆ#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#ᎢᎬᎾᏕᎾ ᎢᏤᏳᏍᏗ#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#ᏪᎶ#,
		},
		'Atlantic/Madeira' => {
			exemplarCity => q#ᎹᏕᎳ#,
		},
		'Atlantic/Reykjavik' => {
			exemplarCity => q#ᎴᏣᏫᎩ#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#ᏧᎦᎾᏮ ᏣᎠᏥᎢ#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#ᎤᏓᏅᏘ ᎮᎵᎾ#,
		},
		'Atlantic/Stanley' => {
			exemplarCity => q#ᏍᏕᏂᎵ#,
		},
		'Australia/Adelaide' => {
			exemplarCity => q#ᎡᏕᎴᏗ#,
		},
		'Australia/Brisbane' => {
			exemplarCity => q#ᏇᏍᏇᏂ#,
		},
		'Australia/Broken_Hill' => {
			exemplarCity => q#ᎤᏲᏨᎯ ᎦᏚᏏ#,
		},
		'Australia/Darwin' => {
			exemplarCity => q#ᏓᏩᏂ#,
		},
		'Australia/Eucla' => {
			exemplarCity => q#ᏳᏝ#,
		},
		'Australia/Hobart' => {
			exemplarCity => q#ᎰᏆᏘ#,
		},
		'Australia/Lindeman' => {
			exemplarCity => q#ᎴᎾᏕᎹᏂ#,
		},
		'Australia/Lord_Howe' => {
			exemplarCity => q#ᎤᎬᏫᏳᎯ ᎭᏫ#,
		},
		'Australia/Melbourne' => {
			exemplarCity => q#ᎺᎵᏉᏁ#,
		},
		'Australia/Perth' => {
			exemplarCity => q#ᏇᎵᏝ#,
		},
		'Australia/Sydney' => {
			exemplarCity => q#ᏏᏗᏂ#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#ᎠᏰᏟ ᎡᎳᏗᏜ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎠᏰᏟ ᎡᎳᏗᏜ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎠᏰᏟ ᎡᎳᏗᏜ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#ᎠᏰᏟ ᎡᎳᏗᏜ ᏭᏕᎵᎬ ᏗᏜ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎠᏰᏟ ᎡᎳᏗᏜ ᏭᏕᎵᎬ ᏗᏜ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎠᏰᏟ ᎡᎳᏗᏜ ᏭᏕᎵᎬ ᏗᏜ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#ᎡᎳᏗᏜ ᏗᎧᎸᎬ ᏗᏜ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎡᎳᏗᏜ ᏗᎧᎸᎬ ᏗᏜ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎡᎳᏗᏜ ᏗᎧᎸᎬ ᏗᏜ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#ᎡᎳᏗᏜ ᏭᏕᎵᎬ ᏗᏜ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎡᎳᏗᏜ ᏭᏕᎵᎬ ᏗᏜ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎡᎳᏗᏜ ᏭᏕᎵᎬ ᏗᏜ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#ᎠᏏᎵᏆᏌᏂ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎠᏏᎵᏆᏌᏂ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎠᏏᎵᏆᏌᏂ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#ᎠᏐᎴᏏ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎠᏐᎴᏏ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎠᏐᎴᏏ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#ᏆᏂᎦᎵᏕᏍ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏆᏂᎦᎵᏕᏍ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏆᏂᎦᎵᏕᏍ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#ᏊᏔᏂ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#ᏉᎵᏫᎠ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#ᏆᏏᎵᏯ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏆᏏᎵᏯ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏆᏏᎵᏯ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#ᏊᎾᎢ ᏓᎷᏌᎳᎻ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#ᎢᎬᎾᏕᎾ ᎢᏤᏳᏍᏗ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎢᎬᎾᏕᎾ ᎢᏤᏳᏍᏗ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎢᎬᎾᏕᎾ ᎢᏤᏳᏍᏗ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#ᏣᎼᎶ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#ᏣᏝᎻ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏣᏝᎻ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏣᏝᎻ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#ᏥᎵ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏥᎵ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏥᎵ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#ᏓᎶᏂᎨᏍᏛ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏓᎶᏂᎨᏍᏛ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏓᎶᏂᎨᏍᏛ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#ᏓᏂᏍᏓᏲᎯᎲ ᎤᎦᏚᏛᎢ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#ᎪᎪᏍ ᏚᎦᏚᏛᎢ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#ᎪᎸᎻᏈᎢᎠ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎪᎸᎻᏈᎢᎠ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎪᎸᎻᏈᎢᎠ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#ᎠᏓᏍᏓᏴᎲᏍᎩ ᏚᎦᏚᏛᎢ ᎠᏰᏟ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎠᏓᏍᏓᏴᎲᏍᎩ ᏚᎦᏚᏛᎢ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎠᏓᏍᏓᏴᎲᏍᎩ ᏚᎦᏚᏛᎢ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#ᎫᏆ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎫᏆ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎫᏆ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#ᏕᏫᏏ ᎠᏟᎢᎵᏒ#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#ᏚᎼᎾᏘ-Ꮧ’ᎤᎵᏫᎵ ᎠᏟᎢᎵᏒ#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#ᏗᎧᎸᎬ ᏘᎼᎵ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#ᏥᏌᏕᎴᎯᏌᏅ ᎤᎦᏚᏛᎢ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏥᏌᏕᎴᎯᏌᏅ ᎤᎦᏚᏛᎢ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏥᏌᏕᎴᎯᏌᏅ ᎤᎦᏚᏛᎢ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#ᎡᏆᏙᎵ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Etc/UTC' => {
			long => {
				'standard' => q#ᎢᎩᏠᏱ ᏂᎦᏓ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#ᏄᏬᎵᏍᏛᎾ ᎦᏚᎲ#,
		},
		'Europe/Amsterdam' => {
			exemplarCity => q#ᎠᎻᏍᏕᏓᎻ#,
		},
		'Europe/Andorra' => {
			exemplarCity => q#ᎠᏂᏙᏩ#,
		},
		'Europe/Astrakhan' => {
			exemplarCity => q#ᎠᏝᎧᏂ#,
		},
		'Europe/Athens' => {
			exemplarCity => q#ᎠᏖᏂᏏ#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#ᏇᎵᏇᏗ#,
		},
		'Europe/Berlin' => {
			exemplarCity => q#ᏇᎵᏂ#,
		},
		'Europe/Bratislava' => {
			exemplarCity => q#ᏆᏘᏍᎳᏩ#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#ᏋᏎᎵᏏ#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#ᏇᏣᎴᏍᏗ#,
		},
		'Europe/Budapest' => {
			exemplarCity => q#ᏊᏓᏇᏍᏗ#,
		},
		'Europe/Busingen' => {
			exemplarCity => q#ᏊᏏᏂᎨᏂ#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#ᏥᏏᎾᏫ#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#ᎪᏇᏂᎮᎨᏂ#,
		},
		'Europe/Dublin' => {
			exemplarCity => q#ᏛᎵᏂ#,
			long => {
				'daylight' => q#ᎨᎵᎩ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Europe/Gibraltar' => {
			exemplarCity => q#ᏥᏆᎵᏓ#,
		},
		'Europe/Guernsey' => {
			exemplarCity => q#ᎬᏂᏏ#,
		},
		'Europe/Helsinki' => {
			exemplarCity => q#ᎮᎵᏏᏂᎩ#,
		},
		'Europe/Isle_of_Man' => {
			exemplarCity => q#ᎤᏍᏗᎤᎦᏚᏛ ᎾᎿ ᎠᏍᎦᏯ#,
		},
		'Europe/Istanbul' => {
			exemplarCity => q#ᎢᏍᏔᏂᏊᎵ#,
		},
		'Europe/Jersey' => {
			exemplarCity => q#ᏨᎵᏏ#,
		},
		'Europe/Kaliningrad' => {
			exemplarCity => q#ᎧᎵᏂᏆᏗ#,
		},
		'Europe/Kiev' => {
			exemplarCity => q#ᎩᏫ#,
		},
		'Europe/Kirov' => {
			exemplarCity => q#ᎩᎶᏩ#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#ᎵᏏᏉᏂ#,
		},
		'Europe/Ljubljana' => {
			exemplarCity => q#ᏧᏣᎾ#,
		},
		'Europe/London' => {
			exemplarCity => q#ᎸᏂᏓᏂ#,
			long => {
				'daylight' => q#ᏈᏗᏏ ᎪᎩ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#ᎸᎧᏎᏋᎩ#,
		},
		'Europe/Madrid' => {
			exemplarCity => q#ᎹᏟᏗ#,
		},
		'Europe/Malta' => {
			exemplarCity => q#ᎹᎵᏔ#,
		},
		'Europe/Mariehamn' => {
			exemplarCity => q#ᎺᎵᎭᎻ#,
		},
		'Europe/Minsk' => {
			exemplarCity => q#ᎺᏂᏍᎩ#,
		},
		'Europe/Monaco' => {
			exemplarCity => q#ᎼᎾᎪ#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#ᎹᏍᎦᏫ#,
		},
		'Europe/Oslo' => {
			exemplarCity => q#ᎣᏏᎶ#,
		},
		'Europe/Paris' => {
			exemplarCity => q#ᏇᏫᏏ#,
		},
		'Europe/Podgorica' => {
			exemplarCity => q#ᏉᎪᎵᎧ#,
		},
		'Europe/Prague' => {
			exemplarCity => q#ᏆᏇ#,
		},
		'Europe/Riga' => {
			exemplarCity => q#ᎵᎦ#,
		},
		'Europe/Rome' => {
			exemplarCity => q#ᎶᎻ#,
		},
		'Europe/Samara' => {
			exemplarCity => q#ᏌᎹᎳ#,
		},
		'Europe/San_Marino' => {
			exemplarCity => q#ᎹᎵᏃ#,
		},
		'Europe/Sarajevo' => {
			exemplarCity => q#ᏌᎳᏤᏬ#,
		},
		'Europe/Saratov' => {
			exemplarCity => q#ᏌᏆᏙᎥ#,
		},
		'Europe/Simferopol' => {
			exemplarCity => q#ᏏᎻᏪᎶᏉᎵ#,
		},
		'Europe/Skopje' => {
			exemplarCity => q#ᏍᎪᏤ#,
		},
		'Europe/Sofia' => {
			exemplarCity => q#ᏐᏟᎠ#,
		},
		'Europe/Stockholm' => {
			exemplarCity => q#ᏍᏓᎩᎰᎻ#,
		},
		'Europe/Tallinn' => {
			exemplarCity => q#ᏔᎵᏂ#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#ᏘᎳᎾ#,
		},
		'Europe/Ulyanovsk' => {
			exemplarCity => q#ᎤᎵᏯᏃᏬᏍᎧ#,
		},
		'Europe/Vaduz' => {
			exemplarCity => q#ᏩᏚᏏ#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#ᎠᏥᎳᏁᏠ#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#ᏫᏰᎾ#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#ᏫᎵᏂᏴᏏ#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#ᏬᎶᎪᏝᏗ#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#ᏓᎿᏩ ᎤᎪᎲᎩ#,
		},
		'Europe/Zagreb' => {
			exemplarCity => q#ᏌᏇᏈ#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#ᏑᎵᏥ#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#ᎠᏰᏟ ᏳᎳᏈ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎠᏰᏟ ᏳᎳᏈ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎠᏰᏟ ᏳᎳᏈ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#ᏗᎧᎸᎬ ᏗᏜ ᏳᎳᏈ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏗᎧᎸᎬ ᏗᏜ ᏳᎳᏈ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏗᎧᎸᎬ ᏗᏜ ᏳᎳᏈ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Europe_Further_Eastern' => {
			long => {
				'standard' => q#ᏗᎧᎸᎬ ᏳᎳᏈ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#ᏭᏕᎵᎬ ᏗᏜ ᏳᎳᏈ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏭᏕᎵᎬ ᏗᏜ ᏳᎳᏈ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏭᏕᎵᎬ ᏗᏜ ᏳᎳᏈ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#ᏩᎩ ᏚᎦᏚᏛᎢ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏩᎩ ᏚᎦᏚᏛᎢ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏩᎩ ᏚᎦᏚᏛᎢ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#ᏫᏥ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏫᏥ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏫᏥ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#ᎠᏂᎦᎸ ᏈᏯᎾ ᎠᏟᎢᎵᏒ#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#ᎠᏂᎦᎸᏥ ᎤᎦᏃᏮ & ᎤᏁᏍᏓᎶ ᎠᏟᎢᎵᏒ#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#ᎢᏤ ᎢᏳᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#ᎡᏆ ᏓᎦᏏ ᎤᎦᏚᏛᎢ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#ᎦᎻᏇᎵ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#ᏣᎠᏥᎢ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏣᎠᏥᎢ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏣᎠᏥᎢ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#ᎩᎵᏇᏘ ᏚᎦᏚᏛᎢ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#ᏗᎧᎸᎬ ᎢᏤᏍᏛᏱ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏗᎧᎸᎬ ᎢᏤᏍᏛᏱ ᎠᎵᎢᎵᏒ#,
				'standard' => q#ᏗᎧᎸᎬ ᎢᏤᏍᏛᏱ ᎠᏟᎶᏍᏗ ᎠᎵᎢᎵᏒ#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#ᏭᏕᎵᎬ ᎢᏤᏍᏛᏱ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏭᏕᎵᎬ ᎢᏤᏍᏛᏱ ᎠᎵᎢᎵᏒ#,
				'standard' => q#ᏭᏕᎵᎬ ᎢᏤᏍᏛᏱ ᎠᏟᎶᏍᏗ ᎠᎵᎢᎵᏒ#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#ᎡᏉᏄᎸᏗ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#ᎦᏯᎾ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#ᎭᏩᏱ-ᎠᎵᏳᏏᎠᏂ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎭᏩᏱ-ᎠᎵᏳᏏᎠᏂ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎭᏩᏱ-ᎠᎵᏳᏏᎠᏂ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
			short => {
				'daylight' => q#HADT#,
				'generic' => q#HAT#,
				'standard' => q#HAST#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#ᎰᏂᎩ ᎪᏂᎩ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎰᏂᎩ ᎪᏂᎩ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎰᏂᎩ ᎪᏂᎩ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#ᎰᏩᏗ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎰᏩᏗ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎰᏩᏗ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'India' => {
			long => {
				'standard' => q#ᎢᏂᏗᎢᎠ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Indian/Antananarivo' => {
			exemplarCity => q#ᎠᏂᏔᎾᎾᎵᏬ#,
		},
		'Indian/Chagos' => {
			exemplarCity => q#ᏣᎪᏏ#,
		},
		'Indian/Christmas' => {
			exemplarCity => q#ᏓᏂᏍᏓᏲᎯᎲ#,
		},
		'Indian/Cocos' => {
			exemplarCity => q#ᎪᎪᏍ#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#ᎪᎼᎳ#,
		},
		'Indian/Kerguelen' => {
			exemplarCity => q#ᎬᎵᎫᏰᎴᏂ#,
		},
		'Indian/Mahe' => {
			exemplarCity => q#ᎹᎮ#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#ᎹᎵᏗᏫᏍ#,
		},
		'Indian/Mauritius' => {
			exemplarCity => q#ᎼᎵᏏᎥᏍ#,
		},
		'Indian/Mayotte' => {
			exemplarCity => q#ᎺᏯᏖ#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#ᎴᏳᏂᎠᏂ#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#ᎠᏂᏴᏫᏯ ᎠᎺᏉᎯ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#ᎢᏂᏙᏓᎶᏂᎨᏍᏛ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#ᎠᏰᏟ ᎢᏂᏙᏂᏍᏯ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#ᏗᎧᎸᎬ ᏗᏜ ᎢᏂᏙᏂᏍᏯ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#ᏭᏕᎵᎬ ᏗᏜ ᎢᏂᏙᏂᏍᏯ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#ᎢᎳᏂ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎢᎳᏂ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎢᎳᏂ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#ᎢᎫᏥᎧ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎢᎫᏥᎧ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎢᎫᏥᎧ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#ᎢᏏᎵᏱ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒᎩ#,
				'generic' => q#ᎢᏏᎵᏱ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎢᏏᎵᏱ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#ᏣᏩᏂᏏ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏣᏩᏂᏏ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏣᏩᏂᏏ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Kazakhstan' => {
			long => {
				'standard' => q#ᎧᏎᎧᏍᏕᏂ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#ᏗᎧᎸᎬ ᎧᏎᎧᏍᏕᏂ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#ᏭᏕᎵᎬ ᎧᏎᎧᏍᏕᏂ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#ᎪᎵᎠᏂ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎪᎵᎠᏂ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎪᎵᎠᏂ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#ᎪᏍᎴ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#ᏝᏍᏃᏯᏍᎧ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏝᏍᏃᏯᏍᎧ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏝᏍᏃᏯᏍᎧ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#ᎩᎵᏣᎢᏍ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#ᎠᏍᏓᏅᏅ ᏚᎦᏚᏛᎢ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#ᎤᎬᏫᏳᎯ ᎭᏫ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎤᎬᏫᏳᎯ ᎭᏫ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎤᎬᏫᏳᎯ ᎭᏫ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#ᎹᎦᏓᏂ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎹᎦᏓᏂ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎹᎦᏓᏂ ᎠᏟᎢᎵᏒ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#ᎹᎴᏏᎢᎠ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#ᎹᎵᏗᏫᏍ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#ᎹᎵᎨᏌᏏ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#ᎹᏌᎵ ᏚᎦᏚᏛᎢ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#ᎼᎵᏏᎥᏍ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎼᎵᏏᎥᏍ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎼᎵᏏᎥᏍ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#ᎹᏌᏂ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#ᎠᏂᏍᏆᏂ ᏭᏕᎵᎬ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎠᏂᏍᏆᏂ ᏭᏕᎵᎬ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎠᏂᏍᏆᏂ ᏭᏕᎵᎬ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#ᎤᎳᏂ ᏆᏙᎸ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎤᎳᏂ ᏆᏙᎸ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎤᎳᏂ ᏆᏙᎸ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#ᎹᏍᎦᏫ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎹᏍᎦᏫ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎹᏍᎦᏫ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#ᎹᏯᎹᎵ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#ᎾᎷ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#ᏁᏆᎵ ᎠᏟᎢᎵᏒ#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#ᎢᏤ ᎧᎵᏙᏂᎠᏂ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎢᏤ ᎧᎵᏙᏂᎠᏂ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎢᏤ ᎧᎵᏙᏂᎠᏂ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#ᎢᏤ ᏏᎢᎴᏂᏗ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎢᏤ ᏏᎢᎴᏂᏗ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎢᏤ ᏏᎢᎴᏂᏗ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#ᎢᏤᎤᏂᏩᏛᏓᎦᏙᎯ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎢᏤᎤᏂᏩᏛᏓᎦᏙᎯ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎢᏤᎤᏂᏩᏛᏓᎦᏙᎯ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#ᏂᏳ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Norfolk' => {
			long => {
				'daylight' => q#ᏃᎵᏬᎵᎩ ᎤᎦᏚᏛᎢ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏃᎵᏬᎵᎩ ᎤᎦᏚᏛᎢ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏃᎵᏬᎵᎩ ᎤᎦᏚᏛᎢ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#ᏪᎾᏅᏙ Ꮥ ᏃᎶᎾᎭ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏪᎾᏅᏙ Ꮥ ᏃᎶᎾᎭ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏪᎾᏅᏙ Ꮥ ᏃᎶᎾᎭ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#ᏃᏬᏏᏈᏍᎧ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏃᏬᏏᏈᏍᎧ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏃᏬᏏᏈᏍᎧ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#ᎣᎻᏍᎧ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎣᎻᏍᎧ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎣᎻᏍᎧ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Pacific/Apia' => {
			exemplarCity => q#ᎠᏈᎠ#,
		},
		'Pacific/Auckland' => {
			exemplarCity => q#ᎠᎦᎳᎾᏗ#,
		},
		'Pacific/Bougainville' => {
			exemplarCity => q#ᏊᎨᏂᏫᎵ#,
		},
		'Pacific/Chatham' => {
			exemplarCity => q#ᏣᏝᎻ#,
		},
		'Pacific/Easter' => {
			exemplarCity => q#ᏥᏌᏕᎴᎯᏌᏅ#,
		},
		'Pacific/Efate' => {
			exemplarCity => q#ᎡᏩᏖ#,
		},
		'Pacific/Enderbury' => {
			exemplarCity => q#ᎡᏂᏇᎵ#,
		},
		'Pacific/Fakaofo' => {
			exemplarCity => q#ᏩᎧᎣᏬ#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#ᏫᏥ#,
		},
		'Pacific/Funafuti' => {
			exemplarCity => q#ᏡᎾᏡᏘ#,
		},
		'Pacific/Galapagos' => {
			exemplarCity => q#ᎡᏆ ᏓᎦᏏ ᎤᎦᏚᏛᎢ#,
		},
		'Pacific/Gambier' => {
			exemplarCity => q#ᎦᎻᏇᎵ#,
		},
		'Pacific/Guadalcanal' => {
			exemplarCity => q#ᏆᏓᎵᎧᎾᎵ#,
		},
		'Pacific/Guam' => {
			exemplarCity => q#ᏆᎻ#,
		},
		'Pacific/Honolulu' => {
			exemplarCity => q#ᎭᏃᎷᎷ#,
			short => {
				'daylight' => q#HDT#,
				'generic' => q#HST#,
				'standard' => q#HST#,
			},
		},
		'Pacific/Kanton' => {
			exemplarCity => q#ᎧᏛᏂ#,
		},
		'Pacific/Kiritimati' => {
			exemplarCity => q#ᎩᎵᏘᎹᏘ#,
		},
		'Pacific/Kosrae' => {
			exemplarCity => q#ᎪᏍᎴ#,
		},
		'Pacific/Kwajalein' => {
			exemplarCity => q#ᏆᏣᎴᎢᏂ#,
		},
		'Pacific/Majuro' => {
			exemplarCity => q#ᎹᏧᎶ#,
		},
		'Pacific/Marquesas' => {
			exemplarCity => q#ᎹᎵᎨᏌᏏ#,
		},
		'Pacific/Midway' => {
			exemplarCity => q#ᎠᏰᏟᏴᏚ#,
		},
		'Pacific/Nauru' => {
			exemplarCity => q#ᏃᎤᎷ#,
		},
		'Pacific/Niue' => {
			exemplarCity => q#ᏂᏳ#,
		},
		'Pacific/Norfolk' => {
			exemplarCity => q#ᏃᎵᏬᎵᎩ#,
		},
		'Pacific/Noumea' => {
			exemplarCity => q#ᏃᎤᎺᎠ#,
		},
		'Pacific/Pago_Pago' => {
			exemplarCity => q#ᏆᎪ ᏆᎪ#,
		},
		'Pacific/Palau' => {
			exemplarCity => q#ᏆᎴᎠᏫ#,
		},
		'Pacific/Pitcairn' => {
			exemplarCity => q#ᏈᎧᎵᏂᎤ#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#ᏉᏂᏇ#,
		},
		'Pacific/Port_Moresby' => {
			exemplarCity => q#ᏥᏳᏗᏔᎳᏗᏍᏗ ᎼᎵᏍᏈ#,
		},
		'Pacific/Rarotonga' => {
			exemplarCity => q#ᎳᎶᏙᏂᎦ#,
		},
		'Pacific/Saipan' => {
			exemplarCity => q#ᏌᏱᏆᏂ#,
		},
		'Pacific/Tahiti' => {
			exemplarCity => q#ᏔᎯᏘ#,
		},
		'Pacific/Tarawa' => {
			exemplarCity => q#ᏔᎳᏩ#,
		},
		'Pacific/Tongatapu' => {
			exemplarCity => q#ᏙᎾᎦᏔᏊ#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#ᏧᎩ#,
		},
		'Pacific/Wake' => {
			exemplarCity => q#ᎤᏰᏨ#,
		},
		'Pacific/Wallis' => {
			exemplarCity => q#ᏩᎵᏍ#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#ᏆᎩᏍᏖᏂ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏆᎩᏍᏖᏂ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏆᎩᏍᏖᏂ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#ᏆᎷ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#ᏆᏇ ᎢᏤ ᎩᎢᏂ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#ᏆᎵᏇ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏆᎵᏇ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏆᎵᏇ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#ᏇᎷ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏇᎷ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏇᎷ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#ᎠᏂᏈᎵᎩᏃ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎠᏂᏈᎵᎩᏃ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎠᏂᏈᎵᎩᏃ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#ᏧᎴᎯᏌᏅᎯ ᏚᎦᏚᏛᎢ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#ᎤᏓᏅᏘ ᏈᏰ & ᎻᏇᎶᏂ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎤᏓᏅᏘ ᏈᏰ & ᎻᏇᎶᏂ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎤᏓᏅᏘ ᏈᏰ & ᎻᏇᎶᏂ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#ᏈᎧᎵᏂ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#ᏉᎾᏇ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Pyongyang' => {
			long => {
				'standard' => q#ᏈᏯᏂᎩᏰᏂᎩ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#ᎴᏳᏂᎠᏂ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#ᎳᏞᎳ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#ᏌᎧᎵᏂ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏌᎧᎵᏂ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏌᎧᎵᏂ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#ᏌᎼᎠ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏌᎼᎠ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏌᎼᎠ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#ᏎᏤᎴᏏ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#ᏏᏂᎦᏉᎵ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#ᏐᎶᎹᏂ ᏚᎦᏚᏛᎢ ᎠᏟᎢᎵᏒ#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#ᏧᎦᎾᏮ ᏣᎠᏥᎢ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#ᏒᎵᎾᎻ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#ᏏᏲᏩ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#ᏔᎯᏘ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#ᏔᏱᏇ ᎪᎯ ᎢᎦ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏔᏱᏇ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏔᏱᏇ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#ᏔᏥᎩᏍᏕᏂ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#ᏙᎨᎳᎤ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#ᏙᎾᎦ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏙᎾᎦ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏙᎾᎦ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#ᏧᎩ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#ᏛᎵᎩᎺᏂᏍᏔᏂ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏛᎵᎩᎺᏂᏍᏔᏂ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏛᎵᎩᎺᏂᏍᏔᏂ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#ᏚᏩᎷ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#ᏳᎷᏇ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏳᎷᏇ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏳᎷᏇ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#ᎤᏍᏇᎩᏍᏖᏂ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᎤᏍᏇᎩᏍᏖᏂ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᎤᏍᏇᎩᏍᏖᏂ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#ᏩᏄᏩᏚ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏩᏄᏩᏚ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏩᏄᏩᏚ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#ᏪᏁᏑᏪᎳ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#ᏭᎳᏗᏬᏍᏙᎩ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏭᎳᏗᏬᏍᏙᎩ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏭᎳᏗᏬᏍᏙᎩ ᎠᏟᎢᎵᏒ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#ᏬᎶᎪᏝᏗ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏬᎶᎪᏝᏗ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏬᎶᎪᏝᏗ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#ᏬᏍᏙᎧ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#ᎤᏰᏨ ᎤᎦᏚᏛᎢ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#ᏩᎵᏍ ᎠᎴ ᏊᏚᎾ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#ᏯᎫᏥᎧ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏯᎫᏥᎧ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏯᎫᏥᎧ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#ᏰᎧᏖᎵᏂᏊᎦ ᎪᎩ ᎠᏟᎢᎵᏒ#,
				'generic' => q#ᏰᎧᏖᎵᏂᏊᎦ ᎠᏟᎢᎵᏒ#,
				'standard' => q#ᏰᎧᏖᎵᏂᏊᎦ ᎠᏟᎶᏍᏗ ᎠᏟᎢᎵᏒ#,
			},
		},
		'Yukon' => {
			long => {
				'standard' => q#ᏳᎧᏂ ᎠᏟᎢᎵᏒ#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
