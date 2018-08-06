=head1

Locale::CLDR::Locales::Lb - Package for language Luxembourgish

=cut

package Locale::CLDR::Locales::Lb;
# This file auto generated from Data\common\main\lb.xml
#	on Sun  5 Aug  6:09:40 pm GMT

use strict;
use warnings;
use version;

our $VERSION = version->declare('v0.33.0');

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
	default => sub {[ 'spellout-numbering-year','spellout-numbering','spellout-cardinal-masculine','spellout-cardinal-feminine','spellout-cardinal-neuter','spellout-ordinal-masculine','spellout-ordinal-feminine','spellout-ordinal-neuter' ]},
);

has 'algorithmic_number_format_data' => (
	is => 'ro',
	isa => HashRef,
	init_arg => undef,
	default => sub { 
		use bignum;
		return {
		'ord-M-fem' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ter),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-feminine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-feminine=),
				},
			},
		},
		'ord-M-masc' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(ten),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-masculine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-masculine=),
				},
			},
		},
		'ord-M-neut' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(t),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-neuter=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(' =%spellout-ordinal-neuter=),
				},
			},
		},
		'ord-t-fem' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(er),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%spellout-ordinal-feminine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%spellout-ordinal-feminine=),
				},
			},
		},
		'ord-t-masc' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(en),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%spellout-ordinal-masculine=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%spellout-ordinal-masculine=),
				},
			},
		},
		'ord-t-neut' => {
			'private' => {
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(et),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%spellout-ordinal-neuter=),
				},
				'max' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(=%spellout-ordinal-neuter=),
				},
			},
		},
		'spellout-cardinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(null),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(eng),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(zwou),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(­honnert­[→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←­honnert­[→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(­dausend­[→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine←­dausend­[→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Millioun}other{Milliounen})$[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Milliard}other{Milliarden})$[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Billioun}other{Billiounen})$[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Billiard}other{Billiarden})$[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'Inf' => {
					divisor => q(1),
					rule => q(Onendlechkeet),
				},
				'NaN' => {
					divisor => q(1),
					rule => q(net eng Nummer),
				},
				'max' => {
					divisor => q(1),
					rule => q(net eng Nummer),
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
					rule => q(null),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(←← Komma →→),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(eent),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(zwee),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(dräi),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(véier),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(fënnef),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sechs),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(siwen),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(aacht),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(néng),
				},
				'10' => {
					base_value => q(10),
					divisor => q(10),
					rule => q(zéng),
				},
				'11' => {
					base_value => q(11),
					divisor => q(10),
					rule => q(eelef),
				},
				'12' => {
					base_value => q(12),
					divisor => q(10),
					rule => q(zwielef),
				},
				'13' => {
					base_value => q(13),
					divisor => q(10),
					rule => q(dräizéng),
				},
				'14' => {
					base_value => q(14),
					divisor => q(10),
					rule => q(véierzéng),
				},
				'15' => {
					base_value => q(15),
					divisor => q(10),
					rule => q(fofzéng),
				},
				'16' => {
					base_value => q(16),
					divisor => q(10),
					rule => q(siechzéng),
				},
				'17' => {
					base_value => q(17),
					divisor => q(10),
					rule => q(siwwenzéng),
				},
				'18' => {
					base_value => q(18),
					divisor => q(10),
					rule => q(uechtzéng),
				},
				'19' => {
					base_value => q(19),
					divisor => q(10),
					rule => q(nonzéng),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q([→%spellout-cardinal-neuter→an]zwanzeg),
				},
				'30' => {
					base_value => q(30),
					divisor => q(10),
					rule => q([→%spellout-cardinal-neuter→an]drësseg),
				},
				'40' => {
					base_value => q(40),
					divisor => q(10),
					rule => q([→%spellout-cardinal-neuter→an]véierzeg),
				},
				'50' => {
					base_value => q(50),
					divisor => q(10),
					rule => q([→%spellout-cardinal-neuter→an]fofzeg),
				},
				'60' => {
					base_value => q(60),
					divisor => q(10),
					rule => q([→%spellout-cardinal-neuter→an]siechzeg),
				},
				'70' => {
					base_value => q(70),
					divisor => q(10),
					rule => q([→%spellout-cardinal-neuter→an]siwwenzeg),
				},
				'80' => {
					base_value => q(80),
					divisor => q(10),
					rule => q([→%spellout-cardinal-neuter→an]achtzeg),
				},
				'90' => {
					base_value => q(90),
					divisor => q(10),
					rule => q([→%spellout-cardinal-neuter→an]nonzeg),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(­honnert­[→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←­honnert­[→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(­dausend­[→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine←­dausend­[→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Millioun}other{Milliounen})$[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Milliard}other{Milliarden})$[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Billioun}other{Billiounen})$[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Billiard}other{Billiarden})$[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'Inf' => {
					divisor => q(1),
					rule => q(Onendlechkeet),
				},
				'NaN' => {
					divisor => q(1),
					rule => q(net eng Nummer),
				},
				'max' => {
					divisor => q(1),
					rule => q(net eng Nummer),
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
					rule => q(null),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(een),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(=%spellout-cardinal-masculine=),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(­honnert­[→→]),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←­honnert­[→→]),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(­dausend­[→→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine←­dausend­[→→]),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Millioun}other{Milliounen})$[ →→]),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Milliard}other{Milliarden})$[ →→]),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Billioun}other{Billiounen})$[ →→]),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Billiard}other{Billiarden})$[ →→]),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=),
				},
				'Inf' => {
					divisor => q(1),
					rule => q(Onendlechkeet),
				},
				'NaN' => {
					divisor => q(1),
					rule => q(net eng Nummer),
				},
				'max' => {
					divisor => q(1),
					rule => q(net eng Nummer),
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
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(=%spellout-cardinal-neuter=),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=0.0=),
				},
				'1010' => {
					base_value => q(1010),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←honnert[→%spellout-cardinal-neuter→]),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(=%spellout-cardinal-neuter=),
				},
				'2010' => {
					base_value => q(2010),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←honnert[→%spellout-cardinal-neuter→]),
				},
				'3000' => {
					base_value => q(3000),
					divisor => q(1000),
					rule => q(=%spellout-cardinal-neuter=),
				},
				'3010' => {
					base_value => q(3010),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←honnert[→%spellout-cardinal-neuter→]),
				},
				'4000' => {
					base_value => q(4000),
					divisor => q(1000),
					rule => q(=%spellout-cardinal-neuter=),
				},
				'4010' => {
					base_value => q(4010),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←honnert[→%spellout-cardinal-neuter→]),
				},
				'5000' => {
					base_value => q(5000),
					divisor => q(1000),
					rule => q(=%spellout-cardinal-neuter=),
				},
				'5010' => {
					base_value => q(5010),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←honnert[→%spellout-cardinal-neuter→]),
				},
				'6000' => {
					base_value => q(6000),
					divisor => q(1000),
					rule => q(=%spellout-cardinal-neuter=),
				},
				'6010' => {
					base_value => q(6010),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←honnert[→%spellout-cardinal-neuter→]),
				},
				'7000' => {
					base_value => q(7000),
					divisor => q(1000),
					rule => q(=%spellout-cardinal-neuter=),
				},
				'7010' => {
					base_value => q(7010),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←honnert[→%spellout-cardinal-neuter→]),
				},
				'8000' => {
					base_value => q(8000),
					divisor => q(1000),
					rule => q(=%spellout-cardinal-neuter=),
				},
				'8010' => {
					base_value => q(8010),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←honnert[→%spellout-cardinal-neuter→]),
				},
				'9000' => {
					base_value => q(9000),
					divisor => q(1000),
					rule => q(=%spellout-cardinal-neuter=),
				},
				'9010' => {
					base_value => q(9010),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←honnert[→%spellout-cardinal-neuter→]),
				},
				'10000' => {
					base_value => q(10000),
					divisor => q(10000),
					rule => q(=%spellout-cardinal-neuter=),
				},
				'Inf' => {
					divisor => q(1),
					rule => q(Éiwegkeet),
				},
				'NaN' => {
					divisor => q(1),
					rule => q(net eng Nummer),
				},
				'max' => {
					divisor => q(1),
					rule => q(net eng Nummer),
				},
			},
		},
		'spellout-ordinal-feminine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nullter),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.0=.),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(éischter),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(zweeter),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(drëtter),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(véierter),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(fënnefter),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sechster),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(siwenter),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(aachter),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(=%spellout-cardinal-neuter=ter),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%spellout-cardinal-neuter=ster),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(­honnert­→%%ord-t-fem→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←­honnert­→%%ord-t-fem→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(­dausend­→%%ord-t-fem→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine←­dausend­→%%ord-t-fem→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Millioun}other{Milliounen})$→%%ord-M-fem→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Milliard}other{Milliarden})$→%%ord-M-fem→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Billioun}other{Billiounen})$→%%ord-M-fem→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Billiard}other{Billiarden})$→%%ord-M-fem→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=.),
				},
				'Inf' => {
					divisor => q(1),
					rule => q(onendlechter),
				},
				'NaN' => {
					divisor => q(1),
					rule => q(net eng Nummer),
				},
				'max' => {
					divisor => q(1),
					rule => q(net eng Nummer),
				},
			},
		},
		'spellout-ordinal-masculine' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nullten),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.0=.),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(éischten),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(zweeten),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(drëtten),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(véierten),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(fënneften),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sechsten),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(siwenten),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(aachten),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(=%spellout-cardinal-neuter=ten),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%spellout-cardinal-neuter=sten),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(­honnert­→%%ord-t-masc→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←­honnert­→%%ord-t-masc→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(­dausend­→%%ord-t-masc→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine←­dausend­→%%ord-t-masc→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Millioun}other{Milliounen})$→%%ord-M-masc→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Milliard}other{Milliarden})$→%%ord-M-masc→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Billioun}other{Billiounen})$→%%ord-M-masc→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Billiard}other{Billiarden})$→%%ord-M-masc→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=.),
				},
				'Inf' => {
					divisor => q(1),
					rule => q(onendlechten),
				},
				'NaN' => {
					divisor => q(1),
					rule => q(net eng Nummer),
				},
				'max' => {
					divisor => q(1),
					rule => q(net eng Nummer),
				},
			},
		},
		'spellout-ordinal-neuter' => {
			'public' => {
				'-x' => {
					divisor => q(1),
					rule => q(minus →→),
				},
				'0' => {
					base_value => q(0),
					divisor => q(1),
					rule => q(nullt),
				},
				'x.x' => {
					divisor => q(1),
					rule => q(=#,##0.0=.),
				},
				'1' => {
					base_value => q(1),
					divisor => q(1),
					rule => q(éischt),
				},
				'2' => {
					base_value => q(2),
					divisor => q(1),
					rule => q(zweet),
				},
				'3' => {
					base_value => q(3),
					divisor => q(1),
					rule => q(drëtt),
				},
				'4' => {
					base_value => q(4),
					divisor => q(1),
					rule => q(véiert),
				},
				'5' => {
					base_value => q(5),
					divisor => q(1),
					rule => q(fënneft),
				},
				'6' => {
					base_value => q(6),
					divisor => q(1),
					rule => q(sechst),
				},
				'7' => {
					base_value => q(7),
					divisor => q(1),
					rule => q(siwent),
				},
				'8' => {
					base_value => q(8),
					divisor => q(1),
					rule => q(aacht),
				},
				'9' => {
					base_value => q(9),
					divisor => q(1),
					rule => q(=%spellout-cardinal-neuter=t),
				},
				'20' => {
					base_value => q(20),
					divisor => q(10),
					rule => q(=%spellout-cardinal-neuter=st),
				},
				'100' => {
					base_value => q(100),
					divisor => q(100),
					rule => q(­honnert­→%%ord-t-neut→),
				},
				'200' => {
					base_value => q(200),
					divisor => q(100),
					rule => q(←%spellout-cardinal-masculine←­honnert­→%%ord-t-neut→),
				},
				'1000' => {
					base_value => q(1000),
					divisor => q(1000),
					rule => q(­dausend­→%%ord-t-neut→),
				},
				'2000' => {
					base_value => q(2000),
					divisor => q(1000),
					rule => q(←%spellout-cardinal-masculine←­dausend­→%%ord-t-neut→),
				},
				'1000000' => {
					base_value => q(1000000),
					divisor => q(1000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Millioun}other{Milliounen})$→%%ord-M-neut→),
				},
				'1000000000' => {
					base_value => q(1000000000),
					divisor => q(1000000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Milliard}other{Milliarden})$→%%ord-M-neut→),
				},
				'1000000000000' => {
					base_value => q(1000000000000),
					divisor => q(1000000000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Billioun}other{Billiounen})$→%%ord-M-neut→),
				},
				'1000000000000000' => {
					base_value => q(1000000000000000),
					divisor => q(1000000000000000),
					rule => q(←%spellout-cardinal-feminine← $(cardinal,one{Billiard}other{Billiarden})$→%%ord-M-neut→),
				},
				'1000000000000000000' => {
					base_value => q(1000000000000000000),
					divisor => q(1000000000000000000),
					rule => q(=#,##0=.),
				},
				'Inf' => {
					divisor => q(1),
					rule => q(onendlecht),
				},
				'NaN' => {
					divisor => q(1),
					rule => q(net eng Nummer),
				},
				'max' => {
					divisor => q(1),
					rule => q(net eng Nummer),
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
				'aa' => 'Afar',
 				'ab' => 'Abchasesch',
 				'ace' => 'Aceh-Sprooch',
 				'ach' => 'Acholi-Sprooch',
 				'ada' => 'Adangme',
 				'ady' => 'Adygéiesch',
 				'ae' => 'Avestesch',
 				'aeb' => 'Tunesescht Arabesch',
 				'af' => 'Afrikaans',
 				'afh' => 'Afrihili',
 				'agq' => 'Aghem',
 				'ain' => 'Ainu-Sprooch',
 				'ak' => 'Akan',
 				'akk' => 'Akkadesch',
 				'akz' => 'Alabama',
 				'ale' => 'Aleutesch',
 				'aln' => 'Gegesch',
 				'alt' => 'Süd-Alaesch',
 				'am' => 'Amharesch',
 				'an' => 'Aragonesesch',
 				'ang' => 'Alenglesch',
 				'anp' => 'Angika',
 				'ar' => 'Arabesch',
 				'ar_001' => 'Modernt Héicharabesch',
 				'arc' => 'Aramäesch',
 				'arn' => 'Mapudungun',
 				'aro' => 'Araona',
 				'arp' => 'Arapaho-Sprooch',
 				'arq' => 'Algerescht Arabesch',
 				'arw' => 'Arawak-Sprooch',
 				'ary' => 'Marokkanescht Arabesch',
 				'arz' => 'Egyptescht Arabesch',
 				'as' => 'Assamesesch',
 				'asa' => 'Asu (Tanzania)',
 				'ase' => 'Amerikanesch Zeechesprooch',
 				'ast' => 'Asturianesch',
 				'av' => 'Awaresch',
 				'avk' => 'Kotava',
 				'awa' => 'Awadhi',
 				'ay' => 'Aymara',
 				'az' => 'Aserbaidschanesch',
 				'ba' => 'Baschkiresch',
 				'bal' => 'Belutschesch',
 				'ban' => 'Balinesesch',
 				'bar' => 'Bairesch',
 				'bas' => 'Basaa-Sprooch',
 				'bax' => 'Bamun',
 				'bbc' => 'Batak Toba',
 				'bbj' => 'Ghomálá’',
 				'be' => 'Wäissrussesch',
 				'bej' => 'Bedauye',
 				'bem' => 'Bemba-Sprooch',
 				'bew' => 'Betawi',
 				'bez' => 'Bena',
 				'bfd' => 'Bafut',
 				'bfq' => 'Badaga',
 				'bg' => 'Bulgaresch',
 				'bho' => 'Bhodschpuri',
 				'bi' => 'Bislama',
 				'bik' => 'Bikol-Sprooch',
 				'bin' => 'Bini-Sprooch',
 				'bjn' => 'Banjaresesch',
 				'bkm' => 'Kom',
 				'bla' => 'Blackfoot-Sprooch',
 				'bm' => 'Bambara-Sprooch',
 				'bn' => 'Bengalesch',
 				'bo' => 'Tibetesch',
 				'bpy' => 'Bishnupriya',
 				'bqi' => 'Bachtiaresch',
 				'br' => 'Bretonesch',
 				'bra' => 'Braj-Bhakha',
 				'brh' => 'Brahui',
 				'brx' => 'Bodo',
 				'bs' => 'Bosnesch',
 				'bss' => 'Akoose',
 				'bua' => 'Burjatesch',
 				'bug' => 'Buginesesch',
 				'bum' => 'Bulu',
 				'byn' => 'Blin',
 				'byv' => 'Medumba',
 				'ca' => 'Katalanesch',
 				'cad' => 'Caddo',
 				'car' => 'Karibesch',
 				'cay' => 'Cayuga',
 				'cch' => 'Atsam',
 				'ce' => 'Tschetschenesch',
 				'ceb' => 'Cebuano',
 				'cgg' => 'Kiga',
 				'ch' => 'Chamorro-Sprooch',
 				'chb' => 'Chibcha-Sprooch',
 				'chg' => 'Tschagataesch',
 				'chk' => 'Trukesesch',
 				'chm' => 'Mari',
 				'chn' => 'Chinook',
 				'cho' => 'Choctaw',
 				'chp' => 'Chipewyan',
 				'chr' => 'Cherokee',
 				'chy' => 'Cheyenne',
 				'ckb' => 'Sorani',
 				'co' => 'Korsesch',
 				'cop' => 'Koptesch',
 				'cps' => 'Capiznon',
 				'cr' => 'Cree',
 				'crh' => 'Krimtataresch',
 				'cs' => 'Tschechesch',
 				'csb' => 'Kaschubesch',
 				'cu' => 'Kiercheslawesch',
 				'cv' => 'Tschuwaschesch',
 				'cy' => 'Walisesch',
 				'da' => 'Dänesch',
 				'dak' => 'Dakota-Sprooch',
 				'dar' => 'Darginesch',
 				'dav' => 'Taita',
 				'de' => 'Däitsch',
 				'de_AT' => 'Éisträichescht Däitsch',
 				'de_CH' => 'Schwäizer Héichdäitsch',
 				'del' => 'Delaware-Sprooch',
 				'den' => 'Slave',
 				'dgr' => 'Dogrib',
 				'din' => 'Dinka-Sprooch',
 				'dje' => 'Zarma',
 				'doi' => 'Dogri',
 				'dsb' => 'Niddersorbesch',
 				'dtp' => 'Zentral-Dusun',
 				'dua' => 'Duala',
 				'dum' => 'Mëttelhollännesch',
 				'dv' => 'Maldivesch',
 				'dyo' => 'Jola-Fonyi',
 				'dyu' => 'Dyula-Sprooch',
 				'dz' => 'Bhutanesch',
 				'dzg' => 'Dazaga',
 				'ebu' => 'Kiembu',
 				'ee' => 'Ewe-Sprooch',
 				'efi' => 'Efik',
 				'egl' => 'Emilianesch',
 				'egy' => 'Egyptesch',
 				'eka' => 'Ekajuk',
 				'el' => 'Griichesch',
 				'elx' => 'Elamesch',
 				'en' => 'Englesch',
 				'en_AU' => 'Australescht Englesch',
 				'en_CA' => 'Kanadescht Englesch',
 				'en_GB' => 'Britescht Englesch',
 				'en_GB@alt=short' => 'Englesch (UK)',
 				'en_US' => 'Amerikanescht Englesch',
 				'en_US@alt=short' => 'Englesch (US)',
 				'enm' => 'Mëttelenglesch',
 				'eo' => 'Esperanto',
 				'es' => 'Spuenesch',
 				'es_419' => 'Latäinamerikanescht Spuenesch',
 				'es_ES' => 'Europäescht Spuenesch',
 				'es_MX' => 'Mexikanescht Spuenesch',
 				'esu' => 'Yup’ik',
 				'et' => 'Estnesch',
 				'eu' => 'Baskesch',
 				'ewo' => 'Ewondo',
 				'ext' => 'Extremaduresch',
 				'fa' => 'Persesch',
 				'fan' => 'Pangwe-Sprooch',
 				'fat' => 'Fanti-Sprooch',
 				'ff' => 'Ful',
 				'fi' => 'Finnesch',
 				'fil' => 'Filipino',
 				'fit' => 'Meänkieli',
 				'fj' => 'Fidschianesch',
 				'fo' => 'Färöesch',
 				'fon' => 'Fon-Sprooch',
 				'fr' => 'Franséisch',
 				'fr_CA' => 'Kanadescht Franséisch',
 				'fr_CH' => 'Schwäizer Franséisch',
 				'frc' => 'Cajun',
 				'frm' => 'Mëttelfranséisch',
 				'fro' => 'Alfranséisch',
 				'frp' => 'Frankoprovenzalesch',
 				'frr' => 'Nordfriesesch',
 				'frs' => 'Ostfriesesch',
 				'fur' => 'Friulesch',
 				'fy' => 'Westfriesesch',
 				'ga' => 'Iresch',
 				'gaa' => 'Ga-Sprooch',
 				'gag' => 'Gagausesch',
 				'gan' => 'Gan-Chinesesch',
 				'gay' => 'Gayo',
 				'gba' => 'Gbaya-Sprooch',
 				'gbz' => 'Zoroastrianescht Dari',
 				'gd' => 'Schottescht Gällesch',
 				'gez' => 'Geez',
 				'gil' => 'Gilbertesesch',
 				'gl' => 'Galizesch',
 				'glk' => 'Gilaki',
 				'gmh' => 'Mëttelhéichdäitsch',
 				'gn' => 'Guarani',
 				'goh' => 'Alhéichdäitsch',
 				'gom' => 'Goan-Konkani',
 				'gon' => 'Gondi-Sprooch',
 				'gor' => 'Mongondou',
 				'got' => 'Gotesch',
 				'grb' => 'Grebo-Sprooch',
 				'grc' => 'Algriichesch',
 				'gsw' => 'Schwäizerdäitsch',
 				'gu' => 'Gujarati',
 				'guc' => 'Wayuu',
 				'gur' => 'Farefare',
 				'guz' => 'Gusii-Sprooch',
 				'gv' => 'Manx',
 				'gwi' => 'Kutchin-Sprooch',
 				'ha' => 'Hausa',
 				'hai' => 'Haida-Sprooch',
 				'hak' => 'Hakka-Chinesesch',
 				'haw' => 'Hawaiesch',
 				'he' => 'Hebräesch',
 				'hi' => 'Hindi',
 				'hif' => 'Fidschi-Hindi',
 				'hil' => 'Hiligaynon-Sprooch',
 				'hit' => 'Hethitesch',
 				'hmn' => 'Miao-Sprooch',
 				'ho' => 'Hiri-Motu',
 				'hr' => 'Kroatesch',
 				'hsb' => 'Uewersorbesch',
 				'hsn' => 'Xiang-Chinesesch',
 				'ht' => 'Haitianesch',
 				'hu' => 'Ungaresch',
 				'hup' => 'Hupa',
 				'hy' => 'Armenesch',
 				'hz' => 'Herero-Sprooch',
 				'ia' => 'Interlingua',
 				'iba' => 'Iban',
 				'ibb' => 'Ibibio',
 				'id' => 'Indonesesch',
 				'ie' => 'Interlingue',
 				'ig' => 'Igbo-Sprooch',
 				'ii' => 'Sichuan Yi',
 				'ik' => 'Inupiak',
 				'ilo' => 'Ilokano-Sprooch',
 				'inh' => 'Inguschesch',
 				'io' => 'Ido-Sprooch',
 				'is' => 'Islännesch',
 				'it' => 'Italienesch',
 				'iu' => 'Inukitut',
 				'izh' => 'Ischoresch',
 				'ja' => 'Japanesch',
 				'jam' => 'Jamaikanesch-Kreolesch',
 				'jbo' => 'Lojban',
 				'jgo' => 'Ngomba',
 				'jmc' => 'Machame',
 				'jpr' => 'Jiddesch-Persesch',
 				'jrb' => 'Jiddesch-Arabesch',
 				'jut' => 'Jütesch',
 				'jv' => 'Javanesch',
 				'ka' => 'Georgesch',
 				'kaa' => 'Karakalpakesch',
 				'kab' => 'Kabylesch',
 				'kac' => 'Kachin-Sprooch',
 				'kaj' => 'Jju',
 				'kam' => 'Kamba',
 				'kaw' => 'Kawi',
 				'kbd' => 'Kabardinesch',
 				'kbl' => 'Kanembu',
 				'kcg' => 'Tyap',
 				'kde' => 'Makonde',
 				'kea' => 'Kabuverdianu',
 				'ken' => 'Kenyang',
 				'kfo' => 'Koro',
 				'kg' => 'Kongolesesch',
 				'kgp' => 'Kaingang',
 				'kha' => 'Khasi-Sprooch',
 				'kho' => 'Sakesch',
 				'khq' => 'Koyra Chiini',
 				'khw' => 'Khowar',
 				'ki' => 'Kikuyu-Sprooch',
 				'kiu' => 'Kirmanjki',
 				'kj' => 'Kwanyama',
 				'kk' => 'Kasachesch',
 				'kkj' => 'Kako',
 				'kl' => 'Grönlännesch',
 				'kln' => 'Kalenjin',
 				'km' => 'Kambodschanesch',
 				'kmb' => 'Kimbundu-Sprooch',
 				'kn' => 'Kannada',
 				'ko' => 'Koreanesch',
 				'koi' => 'Komi-Permiak',
 				'kok' => 'Konkani',
 				'kos' => 'Kosraeanesch',
 				'kpe' => 'Kpelle-Sprooch',
 				'kr' => 'Kanuri-Sprooch',
 				'krc' => 'Karatschaiesch-Balkaresch',
 				'kri' => 'Krio',
 				'krj' => 'Kinaray-a',
 				'krl' => 'Karelesch',
 				'kru' => 'Oraon-Sprooch',
 				'ks' => 'Kaschmiresch',
 				'ksb' => 'Shambala',
 				'ksf' => 'Bafia',
 				'ksh' => 'Kölsch',
 				'ku' => 'Kurdesch',
 				'kum' => 'Kumükesch',
 				'kut' => 'Kutenai-Sprooch',
 				'kv' => 'Komi-Sprooch',
 				'kw' => 'Kornesch',
 				'ky' => 'Kirgisesch',
 				'la' => 'Latäin',
 				'lad' => 'Ladino',
 				'lag' => 'Langi',
 				'lah' => 'Lahnda',
 				'lam' => 'Lamba-Sprooch',
 				'lb' => 'Lëtzebuergesch',
 				'lez' => 'Lesgesch',
 				'lfn' => 'Lingua Franca Nova',
 				'lg' => 'Ganda-Sprooch',
 				'li' => 'Limburgesch',
 				'lij' => 'Liguresch',
 				'liv' => 'Livesch',
 				'lkt' => 'Lakota-Sprooch',
 				'lmo' => 'Lombardesch',
 				'ln' => 'Lingala',
 				'lo' => 'Laotesch',
 				'lol' => 'Mongo',
 				'loz' => 'Rotse-Sprooch',
 				'lt' => 'Litauesch',
 				'ltg' => 'Lettgallesch',
 				'lu' => 'Luba-Katanga',
 				'lua' => 'Luba-Lulua',
 				'lui' => 'Luiseno-Sprooch',
 				'lun' => 'Lunda-Sprooch',
 				'luo' => 'Luo-Sprooch',
 				'lus' => 'Lushai-Sprooch',
 				'luy' => 'Olulujia',
 				'lv' => 'Lettesch',
 				'lzh' => 'Klassescht Chinesesch',
 				'lzz' => 'Lasesch Sprooch',
 				'mad' => 'Maduresesch',
 				'maf' => 'Mafa',
 				'mag' => 'Khotta',
 				'mai' => 'Maithili',
 				'mak' => 'Makassaresch',
 				'man' => 'Manding-Sprooch',
 				'mas' => 'Massai-Sprooch',
 				'mde' => 'Maba',
 				'mdf' => 'Moksha',
 				'mdr' => 'Mandaresesch',
 				'men' => 'Mende-Sprooch',
 				'mer' => 'Meru-Sprooch',
 				'mfe' => 'Morisyen',
 				'mg' => 'Malagassi-Sprooch',
 				'mga' => 'Mëtteliresch',
 				'mgh' => 'Makhuwa-Meetto',
 				'mgo' => 'Meta’',
 				'mh' => 'Marschallesesch',
 				'mi' => 'Maori',
 				'mic' => 'Micmac-Sprooch',
 				'min' => 'Minangkabau-Sprooch',
 				'mk' => 'Mazedonesch',
 				'ml' => 'Malayalam',
 				'mn' => 'Mongolesch',
 				'mnc' => 'Mandschuresch',
 				'mni' => 'Meithei-Sprooch',
 				'moh' => 'Mohawk-Sprooch',
 				'mos' => 'Mossi-Sprooch',
 				'mr' => 'Marathi',
 				'mrj' => 'West-Mari',
 				'ms' => 'Malaiesch',
 				'mt' => 'Maltesesch',
 				'mua' => 'Mundang',
 				'mul' => 'Méisproocheg',
 				'mus' => 'Muskogee-Sprooch',
 				'mwl' => 'Mirandesesch',
 				'mwr' => 'Marwari',
 				'mwv' => 'Mentawai',
 				'my' => 'Birmanesch',
 				'mye' => 'Myene',
 				'myv' => 'Ersja-Mordwinesch',
 				'mzn' => 'Mazandarani',
 				'na' => 'Nauruesch',
 				'nan' => 'Min-Nan-Chinesesch',
 				'nap' => 'Neapolitanesch',
 				'naq' => 'Nama',
 				'nb' => 'Norwegesch Bokmål',
 				'nd' => 'Nord-Ndebele-Sprooch',
 				'nds' => 'Nidderdäitsch',
 				'ne' => 'Nepalesesch',
 				'new' => 'Newari',
 				'ng' => 'Ndonga',
 				'nia' => 'Nias-Sprooch',
 				'niu' => 'Niue-Sprooch',
 				'njo' => 'Ao Naga',
 				'nl' => 'Hollännesch',
 				'nl_BE' => 'Flämesch',
 				'nmg' => 'Kwasio',
 				'nn' => 'Norwegesch Nynorsk',
 				'nnh' => 'Ngiemboon',
 				'no' => 'Norwegesch',
 				'nog' => 'Nogai',
 				'non' => 'Alnordesch',
 				'nov' => 'Novial',
 				'nqo' => 'N’Ko',
 				'nr' => 'Süd-Ndebele-Sprooch',
 				'nso' => 'Nord-Sotho-Sprooch',
 				'nus' => 'Nuer',
 				'nv' => 'Navajo',
 				'nwc' => 'Al-Newari',
 				'ny' => 'Nyanja-Sprooch',
 				'nym' => 'Nyamwezi-Sprooch',
 				'nyn' => 'Nyankole',
 				'nyo' => 'Nyoro',
 				'nzi' => 'Nzima',
 				'oc' => 'Okzitanesch',
 				'oj' => 'Ojibwa-Sprooch',
 				'om' => 'Oromo',
 				'or' => 'Orija',
 				'os' => 'Ossetesch',
 				'osa' => 'Osage-Sprooch',
 				'ota' => 'Osmanesch',
 				'pa' => 'Pandschabesch',
 				'pag' => 'Pangasinan-Sprooch',
 				'pal' => 'Mëttelpersesch',
 				'pam' => 'Pampanggan-Sprooch',
 				'pap' => 'Papiamento',
 				'pau' => 'Palau',
 				'pcd' => 'Picardesch',
 				'pdc' => 'Pennsylvaniadäitsch',
 				'pdt' => 'Plattdäitsch',
 				'peo' => 'Alpersesch',
 				'pfl' => 'Pfälzesch Däitsch',
 				'phn' => 'Phönikesch',
 				'pi' => 'Pali',
 				'pl' => 'Polnesch',
 				'pms' => 'Piemontesesch',
 				'pnt' => 'Pontesch',
 				'pon' => 'Ponapeanesch',
 				'prg' => 'Preisesch',
 				'pro' => 'Alprovenzalesch',
 				'ps' => 'Paschtu',
 				'pt' => 'Portugisesch',
 				'pt_BR' => 'Brasilianescht Portugisesch',
 				'pt_PT' => 'Europäescht Portugisesch',
 				'qu' => 'Quechua',
 				'quc' => 'Quiché-Sprooch',
 				'qug' => 'Kichwa (Chimborazo-Gebidder)',
 				'raj' => 'Rajasthani',
 				'rap' => 'Ouschterinsel-Sprooch',
 				'rar' => 'Rarotonganesch',
 				'rgn' => 'Romagnol',
 				'rif' => 'Tarifit',
 				'rm' => 'Rätoromanesch',
 				'rn' => 'Rundi-Sprooch',
 				'ro' => 'Rumänesch',
 				'ro_MD' => 'Moldawesch',
 				'rof' => 'Rombo',
 				'rom' => 'Romani',
 				'root' => 'Root',
 				'rtm' => 'Rotumanesch',
 				'ru' => 'Russesch',
 				'rue' => 'Russinesch',
 				'rug' => 'Roviana',
 				'rup' => 'Aromunesch',
 				'rw' => 'Ruandesch',
 				'rwk' => 'Rwa',
 				'sa' => 'Sanskrit',
 				'sad' => 'Sandawe-Sprooch',
 				'sah' => 'Jakutesch',
 				'sam' => 'Samaritanesch',
 				'saq' => 'Samburu',
 				'sas' => 'Sasak',
 				'sat' => 'Santali',
 				'saz' => 'Saurashtra',
 				'sba' => 'Ngambay',
 				'sbp' => 'Sangu',
 				'sc' => 'Sardesch',
 				'scn' => 'Sizilianesch',
 				'sco' => 'Schottesch',
 				'sd' => 'Sindhi',
 				'sdc' => 'Sassaresesch',
 				'se' => 'Nordsamesch',
 				'see' => 'Seneca',
 				'seh' => 'Sena',
 				'sei' => 'Seri',
 				'sel' => 'Selkupesch',
 				'ses' => 'Koyra Senni',
 				'sg' => 'Sango',
 				'sga' => 'Aliresch',
 				'sgs' => 'Samogitesch',
 				'sh' => 'Serbo-Kroatesch',
 				'shi' => 'Taschelhit',
 				'shn' => 'Schan-Sprooch',
 				'shu' => 'Tschadesch-Arabesch',
 				'si' => 'Singhalesesch',
 				'sid' => 'Sidamo',
 				'sk' => 'Slowakesch',
 				'sl' => 'Slowenesch',
 				'sli' => 'Nidderschlesesch',
 				'sly' => 'Selayar',
 				'sm' => 'Samoanesch',
 				'sma' => 'Südsamesch',
 				'smj' => 'Lule-Lappesch',
 				'smn' => 'Inari-Lappesch',
 				'sms' => 'Skolt-Lappesch',
 				'sn' => 'Shona',
 				'snk' => 'Soninke-Sprooch',
 				'so' => 'Somali',
 				'sog' => 'Sogdesch',
 				'sq' => 'Albanesch',
 				'sr' => 'Serbesch',
 				'srn' => 'Srananesch',
 				'srr' => 'Serer-Sprooch',
 				'ss' => 'Swazi',
 				'ssy' => 'Saho',
 				'st' => 'Süd-Sotho-Sprooch',
 				'stq' => 'Saterfriesesch',
 				'su' => 'Sundanesesch',
 				'suk' => 'Sukuma-Sprooch',
 				'sus' => 'Susu',
 				'sux' => 'Sumeresch',
 				'sv' => 'Schwedesch',
 				'sw' => 'Suaheli',
 				'sw_CD' => 'Kongo-Swahili',
 				'swb' => 'Komoresch',
 				'syc' => 'Alsyresch',
 				'syr' => 'Syresch',
 				'szl' => 'Schlesesch',
 				'ta' => 'Tamilesch',
 				'tcy' => 'Tulu',
 				'te' => 'Telugu',
 				'tem' => 'Temne',
 				'teo' => 'Teso',
 				'ter' => 'Tereno-Sprooch',
 				'tet' => 'Tetum-Sprooch',
 				'tg' => 'Tadschikesch',
 				'th' => 'Thailännesch',
 				'ti' => 'Tigrinja',
 				'tig' => 'Tigre',
 				'tiv' => 'Tiv-Sprooch',
 				'tk' => 'Turkmenesch',
 				'tkl' => 'Tokelauanesch',
 				'tkr' => 'Tsachuresch',
 				'tl' => 'Dagalog',
 				'tlh' => 'Klingonesch',
 				'tli' => 'Tlingit-Sprooch',
 				'tly' => 'Talesch',
 				'tmh' => 'Tamaseq',
 				'tn' => 'Tswana-Sprooch',
 				'to' => 'Tongaesch',
 				'tog' => 'Tsonga-Sprooch',
 				'tpi' => 'Neimelanesesch',
 				'tr' => 'Tierkesch',
 				'tru' => 'Turoyo',
 				'trv' => 'Seediq',
 				'ts' => 'Tsonga',
 				'tsd' => 'Tsakonesch',
 				'tsi' => 'Tsimshian-Sprooch',
 				'tt' => 'Tataresch',
 				'ttt' => 'Tatesch',
 				'tum' => 'Tumbuka-Sprooch',
 				'tvl' => 'Elliceanesch',
 				'tw' => 'Twi',
 				'twq' => 'Tasawaq',
 				'ty' => 'Tahitesch',
 				'tyv' => 'Tuwinesch',
 				'tzm' => 'Mëttlert-Atlas-Tamazight',
 				'udm' => 'Udmurtesch',
 				'ug' => 'Uiguresch',
 				'uga' => 'Ugaritesch',
 				'uk' => 'Ukrainesch',
 				'umb' => 'Mbundu-Sprooch',
 				'und' => 'Onbestëmmt Sprooch',
 				'ur' => 'Urdu',
 				'uz' => 'Usbekesch',
 				'vai' => 'Vai-Sprooch',
 				've' => 'Venda-Sprooch',
 				'vec' => 'Venezesch',
 				'vep' => 'Wepsesch',
 				'vi' => 'Vietnamesesch',
 				'vls' => 'Westflämesch',
 				'vmf' => 'Mainfränkesch',
 				'vo' => 'Volapük',
 				'vot' => 'Wotesch',
 				'vro' => 'Voro',
 				'vun' => 'Vunjo',
 				'wa' => 'Wallounesch',
 				'wae' => 'Walliserdäitsch',
 				'wal' => 'Walamo-Sprooch',
 				'war' => 'Waray',
 				'was' => 'Washo-Sprooch',
 				'wo' => 'Wolof',
 				'wuu' => 'Wu-Chinesesch',
 				'xal' => 'Kalmückesch',
 				'xh' => 'Xhosa',
 				'xmf' => 'Mingrelesch Sprooch',
 				'xog' => 'Soga',
 				'yao' => 'Yao-Sprooch',
 				'yap' => 'Yapesesch',
 				'yav' => 'Yangben',
 				'ybb' => 'Yemba',
 				'yi' => 'Jiddesch',
 				'yo' => 'Yoruba',
 				'yrl' => 'Nheengatu',
 				'yue' => 'Kantonesesch',
 				'za' => 'Zhuang',
 				'zap' => 'Zapotekesch',
 				'zbl' => 'Bliss-Symboler',
 				'zea' => 'Seelännesch',
 				'zen' => 'Zenaga',
 				'zgh' => 'Marokkanescht Standard-Tamazight',
 				'zh' => 'Chinesesch',
 				'zh_Hans' => 'Chinesesch (vereinfacht)',
 				'zh_Hant' => 'Chinesesch (traditionell)',
 				'zu' => 'Zulu',
 				'zun' => 'Zuni-Sprooch',
 				'zxx' => 'Keng Sproochinhalter',
 				'zza' => 'Zaza',

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
			'Arab' => 'Arabesch',
 			'Armi' => 'Armi',
 			'Armn' => 'Armenesch',
 			'Avst' => 'Avestesch',
 			'Bali' => 'Balinesesch',
 			'Batk' => 'Battakesch',
 			'Beng' => 'Bengalesch',
 			'Blis' => 'Bliss-Symboler',
 			'Bopo' => 'Bopomofo',
 			'Brah' => 'Brahmi',
 			'Brai' => 'Blanneschrëft',
 			'Bugi' => 'Buginesesch',
 			'Buhd' => 'Buhid',
 			'Cans' => 'UCAS',
 			'Cari' => 'Karesch',
 			'Cham' => 'Cham',
 			'Cher' => 'Cherokee',
 			'Cirt' => 'Cirth',
 			'Copt' => 'Koptesch',
 			'Cprt' => 'Zypriotesch',
 			'Cyrl' => 'Kyrillesch',
 			'Cyrs' => 'Alkiercheslawesch',
 			'Deva' => 'Devanagari',
 			'Dsrt' => 'Deseret',
 			'Egyd' => 'Egyptesch-Demotesch',
 			'Egyh' => 'Egyptesch-Hieratesch',
 			'Egyp' => 'Egyptesch Hieroglyphen',
 			'Ethi' => 'Ethiopesch',
 			'Geok' => 'Khutsuri',
 			'Geor' => 'Georgesch',
 			'Glag' => 'Glagolitesch',
 			'Goth' => 'Gotesch',
 			'Grek' => 'Griichesch',
 			'Gujr' => 'Gujarati',
 			'Guru' => 'Gurmukhi',
 			'Hang' => 'Hangul',
 			'Hani' => 'Chinesesch',
 			'Hano' => 'Hanunoo',
 			'Hans' => 'Vereinfacht',
 			'Hans@alt=stand-alone' => 'Vereinfacht Chinesesch',
 			'Hant' => 'Traditionell',
 			'Hant@alt=stand-alone' => 'Traditionellt Chinesesch',
 			'Hebr' => 'Hebräesch',
 			'Hira' => 'Hiragana',
 			'Hmng' => 'Pahawh Hmong',
 			'Hrkt' => 'Katakana oder Hiragana',
 			'Hung' => 'Alungaresch',
 			'Inds' => 'Indus-Schrëft',
 			'Ital' => 'Alitalesch',
 			'Java' => 'Javanesesch',
 			'Jpan' => 'Japanesch',
 			'Kali' => 'Kayah Li',
 			'Kana' => 'Katakana',
 			'Khar' => 'Kharoshthi',
 			'Khmr' => 'Khmer',
 			'Knda' => 'Kannada',
 			'Kore' => 'Koreanesch',
 			'Lana' => 'Lanna',
 			'Laoo' => 'Laotesch',
 			'Latf' => 'Laténgesch-Fraktur-Variant',
 			'Latg' => 'Laténgesch-Gällesch Variant',
 			'Latn' => 'Laténgesch',
 			'Lepc' => 'Lepcha',
 			'Limb' => 'Limbu',
 			'Lina' => 'Linear A',
 			'Linb' => 'Linear B',
 			'Lyci' => 'Lykesch',
 			'Lydi' => 'Lydesch',
 			'Mand' => 'Mandäesch',
 			'Mani' => 'Manichäesch',
 			'Maya' => 'Maya-Hieroglyphen',
 			'Mero' => 'Meroitesch',
 			'Mlym' => 'Malaysesch',
 			'Mong' => 'Mongolesch',
 			'Moon' => 'Moon',
 			'Mtei' => 'Meitei Mayek',
 			'Mymr' => 'Birmanesch',
 			'Nkoo' => 'N’Ko',
 			'Ogam' => 'Ogham',
 			'Olck' => 'Ol Chiki',
 			'Orkh' => 'Orchon-Runen',
 			'Orya' => 'Oriya',
 			'Osma' => 'Osmanesch',
 			'Perm' => 'Alpermesch',
 			'Phag' => 'Phags-pa',
 			'Phlv' => 'Pahlavi',
 			'Phnx' => 'Phönizesch',
 			'Plrd' => 'Pollard Phonetesch',
 			'Rjng' => 'Rejang',
 			'Roro' => 'Rongorongo',
 			'Runr' => 'Runeschrëft',
 			'Samr' => 'Samaritanesch',
 			'Sara' => 'Sarati',
 			'Saur' => 'Saurashtra',
 			'Sgnw' => 'Zeechesprooch',
 			'Shaw' => 'Shaw-Alphabet',
 			'Sinh' => 'Singhalesesch',
 			'Sund' => 'Sundanesesch',
 			'Sylo' => 'Syloti Nagri',
 			'Syrc' => 'Syresch',
 			'Syre' => 'Syresch-Estrangelo-Variant',
 			'Syrj' => 'Westsyresch',
 			'Syrn' => 'Ostsyresch',
 			'Tale' => 'Tai Le',
 			'Talu' => 'Tai Lue',
 			'Taml' => 'Tamilesch',
 			'Telu' => 'Telugu',
 			'Teng' => 'Tengwar',
 			'Tfng' => 'Tifinagh',
 			'Tglg' => 'Dagalog',
 			'Thaa' => 'Thaana',
 			'Thai' => 'Thai',
 			'Tibt' => 'Tibetesch',
 			'Ugar' => 'Ugaritesch',
 			'Vaii' => 'Vai',
 			'Visp' => 'Siichtbar Sprooch',
 			'Xpeo' => 'Alpersesch',
 			'Xsux' => 'Sumeresch-akkadesch Keilschrëft',
 			'Yiii' => 'Yi',
 			'Zinh' => 'Geierfte Schrëftwäert',
 			'Zsym' => 'Symboler',
 			'Zxxx' => 'Ouni Schrëft',
 			'Zyyy' => 'Onbestëmmt',
 			'Zzzz' => 'Oncodéiert Schrëft',

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
			'001' => 'Welt',
 			'002' => 'Afrika',
 			'003' => 'Nordamerika',
 			'005' => 'Südamerika',
 			'009' => 'Ozeanien',
 			'011' => 'Westafrika',
 			'013' => 'Mëttelamerika',
 			'014' => 'Ostafrika',
 			'015' => 'Nordafrika',
 			'017' => 'Zentralafrika',
 			'018' => 'Südlecht Afrika',
 			'019' => 'Amerika',
 			'021' => 'Nërdlecht Amerika',
 			'029' => 'Karibik',
 			'030' => 'Ostasien',
 			'034' => 'Südasien',
 			'035' => 'Südostasien',
 			'039' => 'Südeuropa',
 			'053' => 'Australien an Neiséiland',
 			'054' => 'Melanesien',
 			'057' => 'Mikronesescht Inselgebitt',
 			'061' => 'Polynesien',
 			'142' => 'Asien',
 			'143' => 'Zentralasien',
 			'145' => 'Westasien',
 			'150' => 'Europa',
 			'151' => 'Osteuropa',
 			'154' => 'Nordeuropa',
 			'155' => 'Westeuropa',
 			'419' => 'Latäinamerika',
 			'AC' => 'Ascension',
 			'AD' => 'Andorra',
 			'AE' => 'Vereenegt Arabesch Emirater',
 			'AF' => 'Afghanistan',
 			'AG' => 'Antigua a Barbuda',
 			'AI' => 'Anguilla',
 			'AL' => 'Albanien',
 			'AM' => 'Armenien',
 			'AO' => 'Angola',
 			'AQ' => 'Antarktis',
 			'AR' => 'Argentinien',
 			'AS' => 'Amerikanesch-Samoa',
 			'AT' => 'Éisträich',
 			'AU' => 'Australien',
 			'AW' => 'Aruba',
 			'AX' => 'Ålandinselen',
 			'AZ' => 'Aserbaidschan',
 			'BA' => 'Bosnien an Herzegowina',
 			'BB' => 'Barbados',
 			'BD' => 'Bangladesch',
 			'BE' => 'Belsch',
 			'BF' => 'Burkina Faso',
 			'BG' => 'Bulgarien',
 			'BH' => 'Bahrain',
 			'BI' => 'Burundi',
 			'BJ' => 'Benin',
 			'BL' => 'Saint-Barthélemy',
 			'BM' => 'Bermuda',
 			'BN' => 'Brunei',
 			'BO' => 'Bolivien',
 			'BQ' => 'Karibescht Holland',
 			'BR' => 'Brasilien',
 			'BS' => 'Bahamas',
 			'BT' => 'Bhutan',
 			'BV' => 'Bouvetinsel',
 			'BW' => 'Botsuana',
 			'BY' => 'Wäissrussland',
 			'BZ' => 'Belize',
 			'CA' => 'Kanada',
 			'CC' => 'Kokosinselen',
 			'CD' => 'Kongo-Kinshasa',
 			'CD@alt=variant' => 'Kongo (Demokratesch Republik)',
 			'CF' => 'Zentralafrikanesch Republik',
 			'CG' => 'Kongo-Brazzaville',
 			'CG@alt=variant' => 'Kongo (Republik)',
 			'CH' => 'Schwäiz',
 			'CI' => 'Côte d’Ivoire',
 			'CI@alt=variant' => 'Elfebeeküst',
 			'CK' => 'Cookinselen',
 			'CL' => 'Chile',
 			'CM' => 'Kamerun',
 			'CN' => 'China',
 			'CO' => 'Kolumbien',
 			'CP' => 'Clipperton-Insel',
 			'CR' => 'Costa Rica',
 			'CU' => 'Kuba',
 			'CV' => 'Kap Verde',
 			'CW' => 'Curaçao',
 			'CX' => 'Chrëschtdagsinsel',
 			'CY' => 'Zypern',
 			'CZ' => 'Tschechien',
 			'DE' => 'Däitschland',
 			'DG' => 'Diego Garcia',
 			'DJ' => 'Dschibuti',
 			'DK' => 'Dänemark',
 			'DM' => 'Dominica',
 			'DO' => 'Dominikanesch Republik',
 			'DZ' => 'Algerien',
 			'EA' => 'Ceuta a Melilla',
 			'EC' => 'Ecuador',
 			'EE' => 'Estland',
 			'EG' => 'Egypten',
 			'EH' => 'Westsahara',
 			'ER' => 'Eritrea',
 			'ES' => 'Spanien',
 			'ET' => 'Ethiopien',
 			'EU' => 'Europäesch Unioun',
 			'FI' => 'Finnland',
 			'FJ' => 'Fidschi',
 			'FK' => 'Falklandinselen',
 			'FM' => 'Mikronesien',
 			'FO' => 'Färöer',
 			'FR' => 'Frankräich',
 			'GA' => 'Gabun',
 			'GB' => 'Groussbritannien',
 			'GB@alt=short' => 'GB',
 			'GD' => 'Grenada',
 			'GE' => 'Georgien',
 			'GF' => 'Guayane',
 			'GG' => 'Guernsey',
 			'GH' => 'Ghana',
 			'GI' => 'Gibraltar',
 			'GL' => 'Grönland',
 			'GM' => 'Gambia',
 			'GN' => 'Guinea',
 			'GP' => 'Guadeloupe',
 			'GQ' => 'Equatorialguinea',
 			'GR' => 'Griicheland',
 			'GS' => 'Südgeorgien an déi Südlech Sandwichinselen',
 			'GT' => 'Guatemala',
 			'GU' => 'Guam',
 			'GW' => 'Guinea-Bissau',
 			'GY' => 'Guyana',
 			'HK' => 'Spezialverwaltungszon Hong Kong',
 			'HK@alt=short' => 'Hong Kong',
 			'HM' => 'Heard- a McDonald-Inselen',
 			'HN' => 'Honduras',
 			'HR' => 'Kroatien',
 			'HT' => 'Haiti',
 			'HU' => 'Ungarn',
 			'IC' => 'Kanaresch Inselen',
 			'ID' => 'Indonesien',
 			'IE' => 'Irland',
 			'IL' => 'Israel',
 			'IM' => 'Isle of Man',
 			'IN' => 'Indien',
 			'IO' => 'Britescht Territorium am Indeschen Ozean',
 			'IQ' => 'Irak',
 			'IR' => 'Iran',
 			'IS' => 'Island',
 			'IT' => 'Italien',
 			'JE' => 'Jersey',
 			'JM' => 'Jamaika',
 			'JO' => 'Jordanien',
 			'JP' => 'Japan',
 			'KE' => 'Kenia',
 			'KG' => 'Kirgisistan',
 			'KH' => 'Kambodscha',
 			'KI' => 'Kiribati',
 			'KM' => 'Komoren',
 			'KN' => 'St. Kitts an Nevis',
 			'KP' => 'Nordkorea',
 			'KR' => 'Südkorea',
 			'KW' => 'Kuwait',
 			'KY' => 'Kaimaninselen',
 			'KZ' => 'Kasachstan',
 			'LA' => 'Laos',
 			'LB' => 'Libanon',
 			'LC' => 'St. Lucia',
 			'LI' => 'Liechtenstein',
 			'LK' => 'Sri Lanka',
 			'LR' => 'Liberia',
 			'LS' => 'Lesotho',
 			'LT' => 'Litauen',
 			'LU' => 'Lëtzebuerg',
 			'LV' => 'Lettland',
 			'LY' => 'Libyen',
 			'MA' => 'Marokko',
 			'MC' => 'Monaco',
 			'MD' => 'Moldawien',
 			'ME' => 'Montenegro',
 			'MF' => 'St. Martin',
 			'MG' => 'Madagaskar',
 			'MH' => 'Marshallinselen',
 			'MK' => 'Mazedonien',
 			'MK@alt=variant' => 'Mazedonien (EJR)',
 			'ML' => 'Mali',
 			'MM' => 'Myanmar',
 			'MN' => 'Mongolei',
 			'MO' => 'Spezialverwaltungszon Macau',
 			'MO@alt=short' => 'Macau',
 			'MP' => 'Nërdlech Marianen',
 			'MQ' => 'Martinique',
 			'MR' => 'Mauretanien',
 			'MS' => 'Montserrat',
 			'MT' => 'Malta',
 			'MU' => 'Mauritius',
 			'MV' => 'Maldiven',
 			'MW' => 'Malawi',
 			'MX' => 'Mexiko',
 			'MY' => 'Malaysia',
 			'MZ' => 'Mosambik',
 			'NA' => 'Namibia',
 			'NC' => 'Neikaledonien',
 			'NE' => 'Niger',
 			'NF' => 'Norfolkinsel',
 			'NG' => 'Nigeria',
 			'NI' => 'Nicaragua',
 			'NL' => 'Holland',
 			'NO' => 'Norwegen',
 			'NP' => 'Nepal',
 			'NR' => 'Nauru',
 			'NU' => 'Niue',
 			'NZ' => 'Neiséiland',
 			'OM' => 'Oman',
 			'PA' => 'Panama',
 			'PE' => 'Peru',
 			'PF' => 'Franséisch-Polynesien',
 			'PG' => 'Papua-Neiguinea',
 			'PH' => 'Philippinnen',
 			'PK' => 'Pakistan',
 			'PL' => 'Polen',
 			'PM' => 'St. Pierre a Miquelon',
 			'PN' => 'Pitcairninselen',
 			'PR' => 'Puerto Rico',
 			'PS' => 'Palestinensesch Autonomiegebidder',
 			'PS@alt=short' => 'Palestina',
 			'PT' => 'Portugal',
 			'PW' => 'Palau',
 			'PY' => 'Paraguay',
 			'QA' => 'Katar',
 			'QO' => 'Baussecht Ozeanien',
 			'RE' => 'Réunion',
 			'RO' => 'Rumänien',
 			'RS' => 'Serbien',
 			'RU' => 'Russland',
 			'RW' => 'Ruanda',
 			'SA' => 'Saudi-Arabien',
 			'SB' => 'Salomonen',
 			'SC' => 'Seychellen',
 			'SD' => 'Sudan',
 			'SE' => 'Schweden',
 			'SG' => 'Singapur',
 			'SH' => 'St. Helena',
 			'SI' => 'Slowenien',
 			'SJ' => 'Svalbard a Jan Mayen',
 			'SK' => 'Slowakei',
 			'SL' => 'Sierra Leone',
 			'SM' => 'San Marino',
 			'SN' => 'Senegal',
 			'SO' => 'Somalia',
 			'SR' => 'Suriname',
 			'SS' => 'Südsudan',
 			'ST' => 'São Tomé a Príncipe',
 			'SV' => 'El Salvador',
 			'SX' => 'Sint Maarten',
 			'SY' => 'Syrien',
 			'SZ' => 'Swasiland',
 			'TA' => 'Tristan da Cunha',
 			'TC' => 'Turks- a Caicosinselen',
 			'TD' => 'Tschad',
 			'TF' => 'Franséisch Süd- an Antarktisgebidder',
 			'TG' => 'Togo',
 			'TH' => 'Thailand',
 			'TJ' => 'Tadschikistan',
 			'TK' => 'Tokelau',
 			'TL' => 'Osttimor',
 			'TM' => 'Turkmenistan',
 			'TN' => 'Tunesien',
 			'TO' => 'Tonga',
 			'TR' => 'Tierkei',
 			'TT' => 'Trinidad an Tobago',
 			'TV' => 'Tuvalu',
 			'TW' => 'Taiwan',
 			'TZ' => 'Tansania',
 			'UA' => 'Ukrain',
 			'UG' => 'Uganda',
 			'UM' => 'Amerikanesch-Ozeanien',
 			'US' => 'Vereenegt Staaten',
 			'US@alt=short' => 'US',
 			'UY' => 'Uruguay',
 			'UZ' => 'Usbekistan',
 			'VA' => 'Vatikanstad',
 			'VC' => 'St. Vincent an d’Grenadinnen',
 			'VE' => 'Venezuela',
 			'VG' => 'Britesch Joffereninselen',
 			'VI' => 'Amerikanesch Joffereninselen',
 			'VN' => 'Vietnam',
 			'VU' => 'Vanuatu',
 			'WF' => 'Wallis a Futuna',
 			'WS' => 'Samoa',
 			'XK' => 'Kosovo',
 			'YE' => 'Jemen',
 			'YT' => 'Mayotte',
 			'ZA' => 'Südafrika',
 			'ZM' => 'Sambia',
 			'ZW' => 'Simbabwe',
 			'ZZ' => 'Onbekannt Regioun',

		}
	},
);

has 'display_name_variant' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'1901' => 'Al Däitsch Rechtschreiwung',
 			'1994' => 'Standardiséiert Resianesch Rechtschreiwung',
 			'1996' => 'Nei Däitsch Rechtschreiwung',
 			'1606NICT' => 'Spéit Mëttelfranséisch',
 			'1694ACAD' => 'Klassescht Franséisch',
 			'1959ACAD' => 'Akademesch',
 			'ALALC97' => 'ALA-LC-Romaniséierung, Editioun vun 1997',
 			'ALUKU' => 'Aluku-Dialekt',
 			'AREVELA' => 'Ostarmenesch',
 			'AREVMDA' => 'Westarmenesch',
 			'BAKU1926' => 'Eenheetlecht Tierkescht Alphabet',
 			'BALANKA' => 'Balanka-Dialekt vun Anii',
 			'BARLA' => 'Barlavento-Dialektgrupp vu Kabuverdianu',
 			'BISKE' => 'Bela-Dialekt',
 			'BOHORIC' => 'Bohorič-Alphabet',
 			'BOONT' => 'Boontling',
 			'DAJNKO' => 'Dajnko-Alphabet',
 			'EKAVSK' => 'Serbesch mat Ekavian-Aussprooch',
 			'EMODENG' => 'Fréit Modernt Englesch',
 			'FONIPA' => 'Phonetesch (IPA)',
 			'FONUPA' => 'Phonetesch (UPA)',
 			'HEPBURN' => 'Hepburn-Romaniséierung',
 			'IJEKAVSK' => 'Serbesch mat Ijekavian-Aussprooch',
 			'KKCOR' => 'Allgemeng Rechtschreiwung',
 			'KSCOR' => 'Standard-Rechtschreiwung',
 			'LIPAW' => 'Lipovaz-Dialekt',
 			'METELKO' => 'Metelko-Alphabet',
 			'MONOTON' => 'Monotonesch',
 			'NDYUKA' => 'Ndyuka-Dialekt',
 			'NEDIS' => 'Natisone-Dialekt',
 			'NJIVA' => 'Njiva-Dialekt',
 			'NULIK' => 'Modernt Volapük',
 			'OSOJS' => 'Osojane-Dialekt',
 			'PAMAKA' => 'Pamaka-Dialekt',
 			'PINYIN' => 'Pinyin',
 			'POLYTON' => 'Polytonesch',
 			'POSIX' => 'Computer',
 			'REVISED' => 'Revidéiert Rechtschreiwung',
 			'ROZAJ' => 'Resianesch',
 			'SAAHO' => 'Saho',
 			'SCOTLAND' => 'Schottescht Standardenglesch',
 			'SCOUSE' => 'Scouse-Dialekt',
 			'SOLBA' => 'Solbica-Dialekt',
 			'SOTAV' => 'Sotavento-Dialekt-Grupp vu Kabuverdianu',
 			'TARASK' => 'Taraskievica-Orthographie',
 			'UCCOR' => 'Vereenheetlecht Rechtschreiwung',
 			'UCRCOR' => 'Vereenheetlecht iwwerschafft Rechtschreiwung',
 			'UNIFON' => 'Phonetescht Unifon-Alphabet',
 			'VALENCIA' => 'Valencianesch',
 			'WADEGILE' => 'Wade-Giles',

		}
	},
);

has 'display_name_key' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'calendar' => 'Kalenner',
 			'collation' => 'Zortéierung',
 			'currency' => 'Währung',
 			'numbers' => 'Zuelen',

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
 				'buddhist' => q{Buddhistesche Kalenner},
 				'chinese' => q{Chinesesche Kalenner},
 				'coptic' => q{Koptesche Kalenner},
 				'dangi' => q{Dangi-Kalenner},
 				'ethiopic' => q{Ethiopesche Kalenner},
 				'ethiopic-amete-alem' => q{Ethiopesche Kalenner "Amete Alem"},
 				'gregorian' => q{Gregorianesche Kalenner},
 				'hebrew' => q{Hebräesche Kalenner},
 				'indian' => q{Indeschen Nationalkalenner},
 				'islamic' => q{Islamesche Kalenner},
 				'islamic-civil' => q{Biergerlechen islamesche Kalenner},
 				'iso8601' => q{ISO-8601-Kalenner},
 				'japanese' => q{Japanesche Kalenner},
 				'persian' => q{Persesche Kalenner},
 				'roc' => q{Kalenner vun der Republik China},
 			},
 			'collation' => {
 				'big5han' => q{Traditionellt Chinesesch - Big5},
 				'dictionary' => q{Lexikographesch Zortéierreiefolleg},
 				'ducet' => q{Unicode-Zortéierung},
 				'eor' => q{Europäesch Zortéierregelen},
 				'gb2312han' => q{Vereinfacht Chinesesch - GB2312},
 				'phonebook' => q{Telefonsbuch-Zortéierung},
 				'pinyin' => q{Pinyin-Zortéierregelen},
 				'reformed' => q{Reforméiert Zortéierreiefolleg},
 				'search' => q{Allgemeng Sich},
 				'searchjl' => q{Sich no Ufanksbuschtawen aus dem koreaneschen Alphabet},
 				'standard' => q{Standard Zortéierreiefolleg},
 				'stroke' => q{Stréchfolleg},
 				'traditional' => q{Traditionell Zortéierregelen},
 				'unihan' => q{Radikal-Stréch-Zortéierregelen},
 				'zhuyin' => q{Zhuyin-Zortéierregelen},
 			},
 			'numbers' => {
 				'arab' => q{Arabesch-indesch Zifferen},
 				'arabext' => q{Erweidert arabesch-indesch Zifferen},
 				'armn' => q{Armenesch Zifferen},
 				'armnlow' => q{Armenesch Zifferen a Klengschrëft},
 				'beng' => q{Bengalesch Zifferen},
 				'deva' => q{Devanagari-Zifferen},
 				'ethi' => q{Ethiopesch Zifferen},
 				'fullwide' => q{Vollbreet Zifferen},
 				'geor' => q{Georgesch Zifferen},
 				'grek' => q{Griichesch Zifferen},
 				'greklow' => q{Griichesch Zifferen a Klengschrëft},
 				'gujr' => q{Gujarati-Zifferen},
 				'guru' => q{Gurmukhi-Zifferen},
 				'hanidec' => q{Chinesesch Dezimalzuelen},
 				'hans' => q{Vereinfacht-Chinesesch Zifferen},
 				'hansfin' => q{Vereinfacht-Chinesesch Finanzzifferen},
 				'hant' => q{Traditionell-Chinesesch Zifferen},
 				'hantfin' => q{Traditionell-Chinesesch Finanzzifferen},
 				'hebr' => q{Hebräesch Zifferen},
 				'jpan' => q{Japanesch Zifferen},
 				'jpanfin' => q{Japanesch Finanzzifferen},
 				'khmr' => q{Khmer-Zifferen},
 				'knda' => q{Kannada-Zifferen},
 				'laoo' => q{Laotesch Zifferen},
 				'latn' => q{Westlech Zifferen},
 				'mlym' => q{Malayalam-Zifferen},
 				'mong' => q{Mongolesch Zifferen},
 				'mymr' => q{Myanmar-Zifferen},
 				'orya' => q{Oriya-Zifferen},
 				'roman' => q{Réimesch Zifferen},
 				'romanlow' => q{Réimesch Zifferen a Klengschrëft},
 				'taml' => q{Tamilesch Zifferen},
 				'tamldec' => q{Tamil-Zifferen},
 				'telu' => q{Telugu-Zifferen},
 				'thai' => q{Thai-Zifferen},
 				'tibt' => q{Tibetesch Zifferen},
 				'vaii' => q{Vai-Zifferen},
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
			'metric' => q{Metreschen Eenheetesystem},
 			'UK' => q{Engleschen Eenheetesystem},
 			'US' => q{Angloamerikaneschen Eenheetesystem},

		}
	},
);

has 'display_name_code_patterns' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { 
		{
			'language' => 'Sprooch: {0}',
 			'script' => 'Schrëft: {0}',
 			'region' => 'Regioun: {0}',

		}
	},
);

has 'text_orientation' => (
	is			=> 'ro',
	isa			=> HashRef[Str],
	init_arg	=> undef,
	default		=> sub { return {
			lines => 'top-to-bottom',
			characters => 'left-to-right',
		}}
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
			auxiliary => qr{[á à ă â å ã ā æ ç è ĕ ê ē ğ í ì ĭ î ï İ ī ı ñ ó ò ŏ ô ö ø ō œ ş ß ú ù ŭ û ü ū ÿ]},
			index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
			main => qr{[a ä b c d e é ë f g h i j k l m n o p q r s t u v w x y z]},
			numbers => qr{[\- , . % ‰ + 0 1 2 3 4 5 6 7 8 9]},
			punctuation => qr{[\- ‐ – — , ; \: ! ? . … ' ‘ ‚ " “ „ « » ( ) \[ \] \{ \} § @ * / \& #]},
		};
	},
EOT
: sub {
		return { index => ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'], };
},
);


has 'ellipsis' => (
	is			=> 'ro',
	isa			=> HashRef,
	init_arg	=> undef,
	default		=> sub {
		return {
			'final' => '{0} …',
			'initial' => '… {0}',
			'medial' => '{0} … {1}',
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
						'name' => q(Acres),
						'one' => q({0} Acre),
						'other' => q({0} Acres),
					},
					'acre-foot' => {
						'name' => q(acre-feet),
						'one' => q({0} acre-foot),
						'other' => q({0} acre-feet),
					},
					'ampere' => {
						'name' => q(Ampère),
						'one' => q({0} Ampère),
						'other' => q({0} Ampère),
					},
					'arc-minute' => {
						'name' => q(Wénkelminutten),
						'one' => q({0} Wénkelminutt),
						'other' => q({0} Wénkelminutten),
					},
					'arc-second' => {
						'name' => q(Wénkelsekonnen),
						'one' => q({0} Wénkelsekonn),
						'other' => q({0} Wénkelsekonnen),
					},
					'astronomical-unit' => {
						'name' => q(Astronomesch Eenheeten),
						'one' => q({0} Astronomesch Eenheet),
						'other' => q({0} Astronomesch Eenheeten),
					},
					'bit' => {
						'name' => q(Bits),
						'one' => q({0} Bit),
						'other' => q({0} Bits),
					},
					'bushel' => {
						'name' => q(Bushels),
						'one' => q({0} Bushel),
						'other' => q({0} Bushels),
					},
					'byte' => {
						'name' => q(Bytes),
						'one' => q({0} Byte),
						'other' => q({0} Bytes),
					},
					'calorie' => {
						'name' => q(Kalorien),
						'one' => q({0} Kalorie),
						'other' => q({0} Kalorien),
					},
					'carat' => {
						'name' => q(Carat),
						'one' => q({0} Carat),
						'other' => q({0} Carat),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0} Grad Celsius),
						'other' => q({0} Grad Celsius),
					},
					'centiliter' => {
						'name' => q(Zentiliter),
						'one' => q({0} Zentiliter),
						'other' => q({0} Zentiliter),
					},
					'centimeter' => {
						'name' => q(Zentimeter),
						'one' => q({0} Zentimeter),
						'other' => q({0} Zentimeter),
					},
					'cubic-centimeter' => {
						'name' => q(Kubikzentimeter),
						'one' => q({0} Kubikzentimeter),
						'other' => q({0} Kubikzentimeter),
					},
					'cubic-foot' => {
						'name' => q(Kubikfouss),
						'one' => q({0} Kubikfouss),
						'other' => q({0} Kubikfouss),
					},
					'cubic-inch' => {
						'name' => q(Kubikzoll),
						'one' => q({0} Kubikzoll),
						'other' => q({0} Kubikzoll),
					},
					'cubic-kilometer' => {
						'name' => q(Kubikkilometer),
						'one' => q({0} Kubikkilometer),
						'other' => q({0} Kubikkilometer),
					},
					'cubic-meter' => {
						'name' => q(Kubikmeter),
						'one' => q({0} Kubikmeter),
						'other' => q({0} Kubikmeter),
					},
					'cubic-mile' => {
						'name' => q(Kubikmeilen),
						'one' => q({0} Kubikmeil),
						'other' => q({0} Kubikmeilen),
					},
					'cubic-yard' => {
						'name' => q(Kubikyard),
						'one' => q({0} Kubikyard),
						'other' => q({0} Kubikyard),
					},
					'cup' => {
						'name' => q(Cup),
						'one' => q({0} cup),
						'other' => q({0} cup),
					},
					'day' => {
						'name' => q(Deeg),
						'one' => q({0} Dag),
						'other' => q({0} Deeg),
					},
					'deciliter' => {
						'name' => q(Deziliter),
						'one' => q({0} Deziliter),
						'other' => q({0} Deziliter),
					},
					'decimeter' => {
						'name' => q(Dezimeter),
						'one' => q({0} Dezimeter),
						'other' => q({0} Dezimeter),
					},
					'degree' => {
						'name' => q(Grad),
						'one' => q({0} Grad),
						'other' => q({0} Grad),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0} Grad Fahrenheit),
						'other' => q({0} Grad Fahrenheit),
					},
					'fathom' => {
						'name' => q(Nautesch Fiedem),
						'one' => q({0} Nautesche Fuedem),
						'other' => q({0} Nautesch Fiedem),
					},
					'fluid-ounce' => {
						'name' => q(Flësseg-Onzen),
						'one' => q({0} Flësseg-Onz),
						'other' => q({0} Flësseg-Onzen),
					},
					'foodcalorie' => {
						'name' => q(Liewensmëttelkalorien),
						'one' => q({0} Liewensmëttelkalorie),
						'other' => q({0} Liewensmëttelkalorien),
					},
					'foot' => {
						'name' => q(Fouss),
						'one' => q({0} Fouss),
						'other' => q({0} Fouss),
					},
					'furlong' => {
						'name' => q(Furlongs),
						'one' => q({0} Furlong),
						'other' => q({0} Furlongs),
					},
					'g-force' => {
						'name' => q(Äerdacceleratioun),
						'one' => q({0}-fach Äerdacceleratioun),
						'other' => q({0}-fach Äerdacceleratioun),
					},
					'gallon' => {
						'name' => q(Gallounen),
						'one' => q({0} Galloun),
						'other' => q({0} Gallounen),
					},
					'gigabit' => {
						'name' => q(Gigabits),
						'one' => q({0} Gigabit),
						'other' => q({0} Gigabit),
					},
					'gigabyte' => {
						'name' => q(Gigabytes),
						'one' => q({0} Gigabyte),
						'other' => q({0} Gigabytes),
					},
					'gigahertz' => {
						'name' => q(Gigahertz),
						'one' => q({0} Gigahertz),
						'other' => q({0} Gigahertz),
					},
					'gigawatt' => {
						'name' => q(Gigawatt),
						'one' => q({0} Gigawatt),
						'other' => q({0} Gigawatt),
					},
					'gram' => {
						'name' => q(Gramm),
						'one' => q({0} Gramm),
						'other' => q({0} Gramm),
					},
					'hectare' => {
						'name' => q(Hektar),
						'one' => q({0} Hektar),
						'other' => q({0} Hektar),
					},
					'hectoliter' => {
						'name' => q(Hektoliter),
						'one' => q({0} Hektoliter),
						'other' => q({0} Hektoliter),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} Hektopascal),
						'other' => q({0} Hektopascal),
					},
					'hertz' => {
						'name' => q(Hertz),
						'one' => q({0} Hertz),
						'other' => q({0} Hertz),
					},
					'horsepower' => {
						'name' => q(Päerdsstäerkten),
						'one' => q({0} Päerdsstäerkt),
						'other' => q({0} Päerdsstäerkten),
					},
					'hour' => {
						'name' => q(Stonnen),
						'one' => q({0} Stonn),
						'other' => q({0} Stonnen),
						'per' => q({0} pro Stonn),
					},
					'inch' => {
						'name' => q(Zoll),
						'one' => q({0} Zoll),
						'other' => q({0} Zoll),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'one' => q({0} Zoll Quecksëlwersail),
						'other' => q({0} Zoll Quecksëlwersail),
					},
					'joule' => {
						'name' => q(Joule),
						'one' => q({0} Joule),
						'other' => q({0} Joule),
					},
					'karat' => {
						'name' => q(Karat),
						'one' => q({0} Karat),
						'other' => q({0} Karat),
					},
					'kelvin' => {
						'name' => q(K),
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilobit' => {
						'name' => q(Kilobits),
						'one' => q({0} Kilobit),
						'other' => q({0} Kilobit),
					},
					'kilobyte' => {
						'name' => q(Kilobytes),
						'one' => q({0} Kilobyte),
						'other' => q({0} Kilobytes),
					},
					'kilocalorie' => {
						'name' => q(Kilokalorien),
						'one' => q({0} Kilokalorie),
						'other' => q({0} Kilokalorien),
					},
					'kilogram' => {
						'name' => q(Kilogramm),
						'one' => q({0} Kilogramm),
						'other' => q({0} Kilogramm),
					},
					'kilohertz' => {
						'name' => q(Kilohertz),
						'one' => q({0} Kilohertz),
						'other' => q({0} Kilohertz),
					},
					'kilojoule' => {
						'name' => q(Kilojoule),
						'one' => q({0} Kilojoule),
						'other' => q({0} Kilojoule),
					},
					'kilometer' => {
						'name' => q(Kilometer),
						'one' => q({0} Kilometer),
						'other' => q({0} Kilometer),
					},
					'kilometer-per-hour' => {
						'name' => q(Kilometer pro Stonn),
						'one' => q({0} Kilometer pro Stonn),
						'other' => q({0} Kilometer pro Stonn),
					},
					'kilowatt' => {
						'name' => q(Kilowatt),
						'one' => q({0} Kilowatt),
						'other' => q({0} Kilowatt),
					},
					'kilowatt-hour' => {
						'name' => q(Kilowattstonnen),
						'one' => q({0} Kilowattstonn),
						'other' => q({0} Kilowattstonnen),
					},
					'light-year' => {
						'name' => q(Liichtjoer),
						'one' => q({0} Liichtjoer),
						'other' => q({0} Liichtjoer),
					},
					'liter' => {
						'name' => q(Liter),
						'one' => q({0} Liter),
						'other' => q({0} Liter),
					},
					'liter-per-kilometer' => {
						'name' => q(Liter pro Kilometer),
						'one' => q({0} Liter pro Kilometer),
						'other' => q({0} Liter pro Kilometer),
					},
					'lux' => {
						'name' => q(Lux),
						'one' => q({0} Lux),
						'other' => q({0} Lux),
					},
					'megabit' => {
						'name' => q(Megabits),
						'one' => q({0} Megabit),
						'other' => q({0} Megabits),
					},
					'megabyte' => {
						'name' => q(Megabytes),
						'one' => q({0} Megabyte),
						'other' => q({0} Megabytes),
					},
					'megahertz' => {
						'name' => q(Megahertz),
						'one' => q({0} Megahertz),
						'other' => q({0} Megahertz),
					},
					'megaliter' => {
						'name' => q(Megaliter),
						'one' => q({0} Megaliter),
						'other' => q({0} Megaliter),
					},
					'megawatt' => {
						'name' => q(Megawatt),
						'one' => q({0} Megawatt),
						'other' => q({0} Megawatt),
					},
					'meter' => {
						'name' => q(Meter),
						'one' => q({0} Meter),
						'other' => q({0} Meter),
					},
					'meter-per-second' => {
						'name' => q(Meter pro Sekonn),
						'one' => q({0} Meter pro Sekonn),
						'other' => q({0} Meter pro Sekonn),
					},
					'meter-per-second-squared' => {
						'name' => q(Meter pro Quadratsekonn),
						'one' => q({0} Meter pro Quadratsekonn),
						'other' => q({0} Meter pro Quadratsekonn),
					},
					'metric-ton' => {
						'name' => q(Tonnen),
						'one' => q({0} Tonn),
						'other' => q({0} Tonnen),
					},
					'microgram' => {
						'name' => q(Mikrogramm),
						'one' => q({0} Mikrogramm),
						'other' => q({0} Mikrogramm),
					},
					'micrometer' => {
						'name' => q(Mikrometer),
						'one' => q({0} Mikrometer),
						'other' => q({0} Mikrometer),
					},
					'microsecond' => {
						'name' => q(Mikrosekonnen),
						'one' => q({0} Mikrosekonn),
						'other' => q({0} Mikrosekonnen),
					},
					'mile' => {
						'name' => q(Meilen),
						'one' => q({0} Meil),
						'other' => q({0} Meilen),
					},
					'mile-per-hour' => {
						'name' => q(Meile pro Stonn),
						'one' => q({0} Meil pro Stonn),
						'other' => q({0} Meile pro Stonn),
					},
					'milliampere' => {
						'name' => q(Milliampère),
						'one' => q({0} Milliampère),
						'other' => q({0} Milliampère),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} Millibar),
						'other' => q({0} Millibar),
					},
					'milligram' => {
						'name' => q(Milligramm),
						'one' => q({0} Milligramm),
						'other' => q({0} Milligramm),
					},
					'milliliter' => {
						'name' => q(Milliliter),
						'one' => q({0} Milliliter),
						'other' => q({0} Milliliter),
					},
					'millimeter' => {
						'name' => q(Millimeter),
						'one' => q({0} Millimeter),
						'other' => q({0} Millimeter),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millisecond' => {
						'name' => q(Millisekonnen),
						'one' => q({0} Millisekonn),
						'other' => q({0} Millisekonnen),
					},
					'milliwatt' => {
						'name' => q(Milliwatt),
						'one' => q({0} Milliwatt),
						'other' => q({0} Milliwatt),
					},
					'minute' => {
						'name' => q(Minutten),
						'one' => q({0} Minutt),
						'other' => q({0} Minutten),
					},
					'month' => {
						'name' => q(Méint),
						'one' => q({0} Mount),
						'other' => q({0} Méint),
					},
					'nanometer' => {
						'name' => q(Nanometer),
						'one' => q({0} Nanometer),
						'other' => q({0} Nanometer),
					},
					'nanosecond' => {
						'name' => q(Nanosekonnen),
						'one' => q({0} Nanosekonn),
						'other' => q({0} Nanosekonnen),
					},
					'nautical-mile' => {
						'name' => q(Nautesch Meilen),
						'one' => q({0} Nautesch Meil),
						'other' => q({0} Nautesch Meilen),
					},
					'ohm' => {
						'name' => q(Ohm),
						'one' => q({0} Ohm),
						'other' => q({0} Ohm),
					},
					'ounce' => {
						'name' => q(Onz),
						'one' => q({0} Onz),
						'other' => q({0} Onzen),
					},
					'ounce-troy' => {
						'name' => q(Fäin-Onz),
						'one' => q({0} Fäin-Onz),
						'other' => q({0} Fäin-Onzen),
					},
					'parsec' => {
						'name' => q(Parsecs),
						'one' => q({0} Parsec),
						'other' => q({0} Parsecs),
					},
					'picometer' => {
						'name' => q(Pikometer),
						'one' => q({0} Pikometer),
						'other' => q({0} Pikometer),
					},
					'pint' => {
						'name' => q(Pinten),
						'one' => q({0} Pint),
						'other' => q({0} Pinten),
					},
					'pound' => {
						'name' => q(Pond),
						'one' => q({0} Pond),
						'other' => q({0} Pond),
					},
					'pound-per-square-inch' => {
						'name' => q(psi),
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'name' => q(Quarten),
						'one' => q({0} Quart),
						'other' => q({0} Quarten),
					},
					'radian' => {
						'name' => q(Radianten),
						'one' => q({0} Radiant),
						'other' => q({0} Radianten),
					},
					'second' => {
						'name' => q(Sekonnen),
						'one' => q({0} Sekonn),
						'other' => q({0} Sekonnen),
						'per' => q({0} pro Sekonn),
					},
					'square-centimeter' => {
						'name' => q(Quadratzentimeter),
						'one' => q({0} Quadratzentimeter),
						'other' => q({0} Quadratzentimeter),
					},
					'square-foot' => {
						'name' => q(Quadratfouss),
						'one' => q({0} Quadratfouss),
						'other' => q({0} Quadratfouss),
					},
					'square-inch' => {
						'name' => q(Quadratzoll),
						'one' => q({0} Quadratzoll),
						'other' => q({0} Quadratzoll),
					},
					'square-kilometer' => {
						'name' => q(Quadratkilometer),
						'one' => q({0} Quadratkilometer),
						'other' => q({0} Quadratkilometer),
					},
					'square-meter' => {
						'name' => q(Quadratmeter),
						'one' => q({0} Quadratmeter),
						'other' => q({0} Quadratmeter),
					},
					'square-mile' => {
						'name' => q(Quadratmeilen),
						'one' => q({0} Quadratmeil),
						'other' => q({0} Quadratmeilen),
					},
					'square-yard' => {
						'name' => q(Quadratyards),
						'one' => q({0} Quadratyard),
						'other' => q({0} Quadratyards),
					},
					'stone' => {
						'name' => q(Stones),
						'one' => q({0} Stone),
						'other' => q({0} Stones),
					},
					'tablespoon' => {
						'name' => q(Zoppeläffelen),
						'one' => q({0} Zoppeläffel),
						'other' => q({0} Zoppeläffelen),
					},
					'teaspoon' => {
						'name' => q(Téiläffelen),
						'one' => q({0} Téiläffel),
						'other' => q({0} Téiläffelen),
					},
					'terabit' => {
						'name' => q(Terabits),
						'one' => q({0} Terabit),
						'other' => q({0} Terabits),
					},
					'terabyte' => {
						'name' => q(Terabytes),
						'one' => q({0} Terabyte),
						'other' => q({0} Terabytes),
					},
					'ton' => {
						'name' => q(Long tons),
						'one' => q({0} Long ton),
						'other' => q({0} Long tons),
					},
					'volt' => {
						'name' => q(Volt),
						'one' => q({0} Volt),
						'other' => q({0} Volt),
					},
					'watt' => {
						'name' => q(Watt),
						'one' => q({0} Watt),
						'other' => q({0} Watt),
					},
					'week' => {
						'name' => q(Wochen),
						'one' => q({0} Woch),
						'other' => q({0} Wochen),
					},
					'yard' => {
						'name' => q(Yard),
						'one' => q({0} Yard),
						'other' => q({0} Yards),
					},
					'year' => {
						'name' => q(Joer),
						'one' => q({0} Joer),
						'other' => q({0} Joer),
					},
				},
				'narrow' => {
					'acre' => {
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'arc-minute' => {
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'one' => q({0} au),
						'other' => q({0} au),
					},
					'bushel' => {
						'name' => q(bu),
						'one' => q({0} bu),
						'other' => q({0} bu),
					},
					'carat' => {
						'one' => q({0} Kt),
						'other' => q({0} Kt),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'centiliter' => {
						'one' => q({0} cL),
						'other' => q({0} cL),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					'cubic-centimeter' => {
						'one' => q({0} cm³),
						'other' => q({0} cm³),
					},
					'cubic-foot' => {
						'one' => q({0} ft³),
						'other' => q({0} ft³),
					},
					'cubic-inch' => {
						'one' => q({0} in³),
						'other' => q({0} in³),
					},
					'cubic-kilometer' => {
						'one' => q({0} km³),
						'other' => q({0} km³),
					},
					'cubic-meter' => {
						'one' => q({0} m³),
						'other' => q({0} m³),
					},
					'cubic-mile' => {
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'one' => q({0} cup),
						'other' => q({0} cup),
					},
					'day' => {
						'name' => q(D),
						'one' => q({0} D),
						'other' => q({0} D),
					},
					'deciliter' => {
						'one' => q({0} dL),
						'other' => q({0} dL),
					},
					'decimeter' => {
						'one' => q({0} dm),
						'other' => q({0} dm),
					},
					'degree' => {
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(fm),
						'one' => q({0} fm),
						'other' => q({0} fm),
					},
					'fluid-ounce' => {
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foot' => {
						'one' => q({0} ft),
						'other' => q({0} ft),
					},
					'furlong' => {
						'name' => q(fur),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					'g-force' => {
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'one' => q({0} gal),
						'other' => q({0} gal),
					},
					'gram' => {
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					'hectare' => {
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					'hectopascal' => {
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'horsepower' => {
						'one' => q({0} PS),
						'other' => q({0} PS),
					},
					'hour' => {
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'inch' => {
						'one' => q({0} in),
						'other' => q({0} in),
					},
					'inch-hg' => {
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'kelvin' => {
						'one' => q({0} K),
						'other' => q({0} K),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'light-year' => {
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					'liter' => {
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					'megaliter' => {
						'one' => q({0} ML),
						'other' => q({0} ML),
					},
					'meter' => {
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'meter-per-second' => {
						'one' => q({0} m/s),
						'other' => q({0} m/s),
					},
					'meter-per-second-squared' => {
						'one' => q({0} m/s²),
						'other' => q({0} m/s²),
					},
					'metric-ton' => {
						'one' => q({0} t),
						'other' => q({0} t),
					},
					'microgram' => {
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-hour' => {
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'millibar' => {
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'milligram' => {
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milliliter' => {
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'minute' => {
						'name' => q(min),
						'one' => q({0} min),
						'other' => q({0} min),
					},
					'month' => {
						'name' => q(M),
						'one' => q({0} M),
						'other' => q({0} M),
					},
					'nanometer' => {
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ounce' => {
						'one' => q({0} oz),
						'other' => q({0} oz),
					},
					'ounce-troy' => {
						'one' => q({0} oz. tr.),
						'other' => q({0} oz. tr.),
					},
					'parsec' => {
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'picometer' => {
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'one' => q({0} lb),
						'other' => q({0} lb),
					},
					'pound-per-square-inch' => {
						'one' => q({0} psi),
						'other' => q({0} psi),
					},
					'quart' => {
						'one' => q({0} qt),
						'other' => q({0} qt),
					},
					'second' => {
						'name' => q(s),
						'one' => q({0} s),
						'other' => q({0} s),
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
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					'stone' => {
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'one' => q({0} ZL),
						'other' => q({0} ZL),
					},
					'teaspoon' => {
						'one' => q({0} TL),
						'other' => q({0} TL),
					},
					'ton' => {
						'one' => q({0} tn),
						'other' => q({0} tn),
					},
					'watt' => {
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'yard' => {
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
				},
				'short' => {
					'acre' => {
						'name' => q(ac),
						'one' => q({0} ac),
						'other' => q({0} ac),
					},
					'acre-foot' => {
						'name' => q(ac ft),
						'one' => q({0} ac ft),
						'other' => q({0} ac ft),
					},
					'ampere' => {
						'name' => q(A),
						'one' => q({0} A),
						'other' => q({0} A),
					},
					'arc-minute' => {
						'name' => q(′),
						'one' => q({0}′),
						'other' => q({0}′),
					},
					'arc-second' => {
						'name' => q(′′),
						'one' => q({0}″),
						'other' => q({0}″),
					},
					'astronomical-unit' => {
						'name' => q(au),
						'one' => q({0} au),
						'other' => q({0} au),
					},
					'bit' => {
						'name' => q(b),
						'one' => q({0} b),
						'other' => q({0} b),
					},
					'bushel' => {
						'name' => q(bu),
						'one' => q({0} bu),
						'other' => q({0} bu),
					},
					'byte' => {
						'name' => q(B),
						'one' => q({0} B),
						'other' => q({0} B),
					},
					'calorie' => {
						'name' => q(cal),
						'one' => q({0} cal),
						'other' => q({0} cal),
					},
					'carat' => {
						'name' => q(CD),
						'one' => q({0} CD),
						'other' => q({0} CD),
					},
					'celsius' => {
						'name' => q(°C),
						'one' => q({0}°C),
						'other' => q({0}°C),
					},
					'centiliter' => {
						'name' => q(cL),
						'one' => q({0} cL),
						'other' => q({0} cL),
					},
					'centimeter' => {
						'name' => q(cm),
						'one' => q({0} cm),
						'other' => q({0} cm),
					},
					'cubic-centimeter' => {
						'name' => q(cm³),
						'one' => q({0} cm³),
						'other' => q({0} cm³),
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
					},
					'cubic-mile' => {
						'name' => q(mi³),
						'one' => q({0} mi³),
						'other' => q({0} mi³),
					},
					'cubic-yard' => {
						'name' => q(yd³),
						'one' => q({0} yd³),
						'other' => q({0} yd³),
					},
					'cup' => {
						'name' => q(cup),
						'one' => q({0} cup),
						'other' => q({0} cup),
					},
					'day' => {
						'name' => q(D),
						'one' => q({0} D),
						'other' => q({0} D),
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
						'name' => q(°),
						'one' => q({0}°),
						'other' => q({0}°),
					},
					'fahrenheit' => {
						'name' => q(°F),
						'one' => q({0}°F),
						'other' => q({0}°F),
					},
					'fathom' => {
						'name' => q(fm),
						'one' => q({0} fm),
						'other' => q({0} fm),
					},
					'fluid-ounce' => {
						'name' => q(fl oz),
						'one' => q({0} fl oz),
						'other' => q({0} fl oz),
					},
					'foodcalorie' => {
						'name' => q(Cal),
						'one' => q({0} Cal),
						'other' => q({0} Cal),
					},
					'foot' => {
						'name' => q(ft),
						'one' => q({0} ft),
						'other' => q({0} ft),
					},
					'furlong' => {
						'name' => q(fur),
						'one' => q({0} fur),
						'other' => q({0} fur),
					},
					'g-force' => {
						'name' => q(G),
						'one' => q({0} G),
						'other' => q({0} G),
					},
					'gallon' => {
						'name' => q(gal),
						'one' => q({0} gal),
						'other' => q({0} gal),
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
						'name' => q(g),
						'one' => q({0} g),
						'other' => q({0} g),
					},
					'hectare' => {
						'name' => q(ha),
						'one' => q({0} ha),
						'other' => q({0} ha),
					},
					'hectoliter' => {
						'name' => q(hL),
						'one' => q({0} hL),
						'other' => q({0} hL),
					},
					'hectopascal' => {
						'name' => q(hPa),
						'one' => q({0} hPa),
						'other' => q({0} hPa),
					},
					'hertz' => {
						'name' => q(Hz),
						'one' => q({0} Hz),
						'other' => q({0} Hz),
					},
					'horsepower' => {
						'name' => q(PS),
						'one' => q({0} PS),
						'other' => q({0} PS),
					},
					'hour' => {
						'name' => q(St.),
						'one' => q({0} St.),
						'other' => q({0} St.),
						'per' => q({0}/St.),
					},
					'inch' => {
						'name' => q(in),
						'one' => q({0} in),
						'other' => q({0} in),
					},
					'inch-hg' => {
						'name' => q(inHg),
						'one' => q({0} inHg),
						'other' => q({0} inHg),
					},
					'joule' => {
						'name' => q(joule),
						'one' => q({0} J),
						'other' => q({0} J),
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
						'name' => q(kcal),
						'one' => q({0} kcal),
						'other' => q({0} kcal),
					},
					'kilogram' => {
						'name' => q(kg),
						'one' => q({0} kg),
						'other' => q({0} kg),
					},
					'kilohertz' => {
						'name' => q(kHz),
						'one' => q({0} kHz),
						'other' => q({0} kHz),
					},
					'kilojoule' => {
						'name' => q(kJ),
						'one' => q({0} kJ),
						'other' => q({0} kJ),
					},
					'kilometer' => {
						'name' => q(km),
						'one' => q({0} km),
						'other' => q({0} km),
					},
					'kilometer-per-hour' => {
						'name' => q(km/h),
						'one' => q({0} km/h),
						'other' => q({0} km/h),
					},
					'kilowatt' => {
						'name' => q(kW),
						'one' => q({0} kW),
						'other' => q({0} kW),
					},
					'kilowatt-hour' => {
						'name' => q(kWh),
						'one' => q({0} kWh),
						'other' => q({0} kWh),
					},
					'light-year' => {
						'name' => q(ly),
						'one' => q({0} ly),
						'other' => q({0} ly),
					},
					'liter' => {
						'name' => q(l),
						'one' => q({0} l),
						'other' => q({0} l),
					},
					'liter-per-kilometer' => {
						'name' => q(l/km),
						'one' => q({0} l/km),
						'other' => q({0} l/km),
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
						'name' => q(m),
						'one' => q({0} m),
						'other' => q({0} m),
					},
					'meter-per-second' => {
						'name' => q(m/s),
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
						'name' => q(µg),
						'one' => q({0} µg),
						'other' => q({0} µg),
					},
					'micrometer' => {
						'name' => q(µm),
						'one' => q({0} µm),
						'other' => q({0} µm),
					},
					'microsecond' => {
						'name' => q(μs),
						'one' => q({0} μs),
						'other' => q({0} μs),
					},
					'mile' => {
						'name' => q(mi),
						'one' => q({0} mi),
						'other' => q({0} mi),
					},
					'mile-per-gallon' => {
						'name' => q(mpg),
						'one' => q({0} mpg),
						'other' => q({0} mpg),
					},
					'mile-per-hour' => {
						'name' => q(mi/h),
						'one' => q({0} mi/h),
						'other' => q({0} mi/h),
					},
					'milliampere' => {
						'name' => q(mA),
						'one' => q({0} mA),
						'other' => q({0} mA),
					},
					'millibar' => {
						'name' => q(mbar),
						'one' => q({0} mbar),
						'other' => q({0} mbar),
					},
					'milligram' => {
						'name' => q(mg),
						'one' => q({0} mg),
						'other' => q({0} mg),
					},
					'milliliter' => {
						'name' => q(mL),
						'one' => q({0} mL),
						'other' => q({0} mL),
					},
					'millimeter' => {
						'name' => q(mm),
						'one' => q({0} mm),
						'other' => q({0} mm),
					},
					'millimeter-of-mercury' => {
						'name' => q(mm Hg),
						'one' => q({0} mm Hg),
						'other' => q({0} mm Hg),
					},
					'millisecond' => {
						'name' => q(ms),
						'one' => q({0} ms),
						'other' => q({0} ms),
					},
					'milliwatt' => {
						'name' => q(mW),
						'one' => q({0} mW),
						'other' => q({0} mW),
					},
					'minute' => {
						'name' => q(Min.),
						'one' => q({0} Min.),
						'other' => q({0} Min.),
					},
					'month' => {
						'name' => q(Mnt),
						'one' => q({0} Mnt),
						'other' => q({0} Mnt),
					},
					'nanometer' => {
						'name' => q(nm),
						'one' => q({0} nm),
						'other' => q({0} nm),
					},
					'nanosecond' => {
						'name' => q(ns),
						'one' => q({0} ns),
						'other' => q({0} ns),
					},
					'nautical-mile' => {
						'name' => q(nmi),
						'one' => q({0} nmi),
						'other' => q({0} nmi),
					},
					'ohm' => {
						'name' => q(Ω),
						'one' => q({0} Ω),
						'other' => q({0} Ω),
					},
					'ounce' => {
						'name' => q(oz),
						'one' => q({0} oz),
						'other' => q({0} oz),
					},
					'ounce-troy' => {
						'name' => q(oz. tr.),
						'one' => q({0} oz. tr.),
						'other' => q({0} oz. tr.),
					},
					'parsec' => {
						'name' => q(pc),
						'one' => q({0} pc),
						'other' => q({0} pc),
					},
					'picometer' => {
						'name' => q(pm),
						'one' => q({0} pm),
						'other' => q({0} pm),
					},
					'pint' => {
						'name' => q(pt),
						'one' => q({0} pt),
						'other' => q({0} pt),
					},
					'pound' => {
						'name' => q(lb),
						'one' => q({0} lb),
						'other' => q({0} lb),
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
					'second' => {
						'name' => q(Sek.),
						'one' => q({0} Sek.),
						'other' => q({0} Sek.),
						'per' => q({0}/Sek.),
					},
					'square-centimeter' => {
						'name' => q(cm²),
						'one' => q({0} cm²),
						'other' => q({0} cm²),
					},
					'square-foot' => {
						'name' => q(ft²),
						'one' => q({0} ft²),
						'other' => q({0} ft²),
					},
					'square-inch' => {
						'name' => q(in²),
						'one' => q({0} in²),
						'other' => q({0} in²),
					},
					'square-kilometer' => {
						'name' => q(km²),
						'one' => q({0} km²),
						'other' => q({0} km²),
					},
					'square-meter' => {
						'name' => q(m²),
						'one' => q({0} m²),
						'other' => q({0} m²),
					},
					'square-mile' => {
						'name' => q(mi²),
						'one' => q({0} mi²),
						'other' => q({0} mi²),
					},
					'square-yard' => {
						'name' => q(yd²),
						'one' => q({0} yd²),
						'other' => q({0} yd²),
					},
					'stone' => {
						'name' => q(st),
						'one' => q({0} st),
						'other' => q({0} st),
					},
					'tablespoon' => {
						'name' => q(ZL),
						'one' => q({0} ZL),
						'other' => q({0} ZL),
					},
					'teaspoon' => {
						'name' => q(TL),
						'one' => q({0} TL),
						'other' => q({0} TL),
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
						'name' => q(V),
						'one' => q({0} V),
						'other' => q({0} V),
					},
					'watt' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'week' => {
						'name' => q(W),
						'one' => q({0} W),
						'other' => q({0} W),
					},
					'yard' => {
						'name' => q(yd),
						'one' => q({0} yd),
						'other' => q({0} yd),
					},
					'year' => {
						'name' => q(J),
						'one' => q({0} J),
						'other' => q({0} J),
					},
				},
			} }
);

has 'yesstr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:jo|j|yes|y)$' }
);

has 'nostr' => (
	is			=> 'ro',
	isa			=> RegexpRef,
	init_arg	=> undef,
	default		=> sub { qr'^(?i:nee|n)$' }
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
					'one' => '0 Dsd'.'',
					'other' => '0 Dsd'.'',
				},
				'10000' => {
					'one' => '00 Dsd'.'',
					'other' => '00 Dsd'.'',
				},
				'100000' => {
					'one' => '000 Dsd'.'',
					'other' => '000 Dsd'.'',
				},
				'1000000' => {
					'one' => '0 Mio'.'',
					'other' => '0 Mio'.'',
				},
				'10000000' => {
					'one' => '00 Mio'.'',
					'other' => '00 Mio'.'',
				},
				'100000000' => {
					'one' => '000 Mio'.'',
					'other' => '000 Mio'.'',
				},
				'1000000000' => {
					'one' => '0 Mrd'.'',
					'other' => '0 Mrd'.'',
				},
				'10000000000' => {
					'one' => '00 Mrd'.'',
					'other' => '00 Mrd'.'',
				},
				'100000000000' => {
					'one' => '000 Mrd'.'',
					'other' => '000 Mrd'.'',
				},
				'1000000000000' => {
					'one' => '0 Bio'.'',
					'other' => '0 Bio'.'',
				},
				'10000000000000' => {
					'one' => '00 Bio'.'',
					'other' => '00 Bio'.'',
				},
				'100000000000000' => {
					'one' => '000 Bio'.'',
					'other' => '000 Bio'.'',
				},
				'standard' => {
					'default' => '#,##0.###',
				},
			},
			'long' => {
				'1000' => {
					'one' => '0 Dausend',
					'other' => '0 Dausend',
				},
				'10000' => {
					'one' => '00 Dausend',
					'other' => '00 Dausend',
				},
				'100000' => {
					'one' => '000 Dausend',
					'other' => '000 Dausend',
				},
				'1000000' => {
					'one' => '0 Millioun',
					'other' => '0 Milliounen',
				},
				'10000000' => {
					'one' => '00 Milliounen',
					'other' => '00 Milliounen',
				},
				'100000000' => {
					'one' => '000 Milliounen',
					'other' => '000 Milliounen',
				},
				'1000000000' => {
					'one' => '0 Milliard',
					'other' => '0 Milliarden',
				},
				'10000000000' => {
					'one' => '00 Milliarden',
					'other' => '00 Milliarden',
				},
				'100000000000' => {
					'one' => '000 Milliarden',
					'other' => '000 Milliarden',
				},
				'1000000000000' => {
					'one' => '0 Billioun',
					'other' => '0 Billiounen',
				},
				'10000000000000' => {
					'one' => '00 Billiounen',
					'other' => '00 Billiounen',
				},
				'100000000000000' => {
					'one' => '000 Billiounen',
					'other' => '000 Billiounen',
				},
			},
			'short' => {
				'1000' => {
					'one' => '0 Dsd'.'',
					'other' => '0 Dsd'.'',
				},
				'10000' => {
					'one' => '00 Dsd'.'',
					'other' => '00 Dsd'.'',
				},
				'100000' => {
					'one' => '000 Dsd'.'',
					'other' => '000 Dsd'.'',
				},
				'1000000' => {
					'one' => '0 Mio'.'',
					'other' => '0 Mio'.'',
				},
				'10000000' => {
					'one' => '00 Mio'.'',
					'other' => '00 Mio'.'',
				},
				'100000000' => {
					'one' => '000 Mio'.'',
					'other' => '000 Mio'.'',
				},
				'1000000000' => {
					'one' => '0 Mrd'.'',
					'other' => '0 Mrd'.'',
				},
				'10000000000' => {
					'one' => '00 Mrd'.'',
					'other' => '00 Mrd'.'',
				},
				'100000000000' => {
					'one' => '000 Mrd'.'',
					'other' => '000 Mrd'.'',
				},
				'1000000000000' => {
					'one' => '0 Bio'.'',
					'other' => '0 Bio'.'',
				},
				'10000000000000' => {
					'one' => '00 Bio'.'',
					'other' => '00 Bio'.'',
				},
				'100000000000000' => {
					'one' => '000 Bio'.'',
					'other' => '000 Bio'.'',
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
					'accounting' => {
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
				'currency' => q(Andorranesch Peseta),
				'one' => q(Andorranesch Peseta),
				'other' => q(Andorranesch Peseten),
			},
		},
		'AED' => {
			display_name => {
				'currency' => q(VAE-Dirham),
				'one' => q(VAE-Dirham),
				'other' => q(VAE-Dirham),
			},
		},
		'AFA' => {
			symbol => 'AFA',
			display_name => {
				'currency' => q(Afghanesch Afghani \(1927–2002\)),
				'one' => q(Afghanesch Afghani \(1927–2002\)),
				'other' => q(Afghanesch Afghani \(1927–2002\)),
			},
		},
		'AFN' => {
			symbol => 'AFN',
			display_name => {
				'currency' => q(Afghanesch Afghani),
				'one' => q(Afghanesch Afghani),
				'other' => q(Afghanesch Afghani),
			},
		},
		'ALL' => {
			display_name => {
				'currency' => q(Albanesche Lek),
				'one' => q(Albanesche Lek),
				'other' => q(Albanesch Lek),
			},
		},
		'AMD' => {
			display_name => {
				'currency' => q(Armeneschen Dram),
				'one' => q(Armeneschen Dram),
				'other' => q(Armenesch Dram),
			},
		},
		'ANG' => {
			display_name => {
				'currency' => q(Antillen-Gulden),
				'one' => q(Antillen-Gulden),
				'other' => q(Antillen-Gulden),
			},
		},
		'AOA' => {
			display_name => {
				'currency' => q(Angolanesche Kwanza),
				'one' => q(Angolaneschen Kwanza),
				'other' => q(Angolanesch Kwanza),
			},
		},
		'AOK' => {
			display_name => {
				'currency' => q(Angolanesche Kwanza \(1977–1990\)),
				'one' => q(Angolanesche Kwanza \(1977–1990\)),
				'other' => q(Angolanesch Kwanza \(1977–1990\)),
			},
		},
		'AON' => {
			display_name => {
				'currency' => q(Angolaneschen Neie Kwanza \(1990–2000\)),
				'one' => q(Angolaneschen Neie Kwanza \(1990–2000\)),
				'other' => q(Angolanesch Nei Kwanza \(1990–2000\)),
			},
		},
		'AOR' => {
			display_name => {
				'currency' => q(Angolanesche Kwanza Reajustado \(1995–1999\)),
				'one' => q(Angolanesche Kwanza Reajustado \(1995–1999\)),
				'other' => q(Angolanesch Kwanza Reajustado \(1995–1999\)),
			},
		},
		'ARA' => {
			display_name => {
				'currency' => q(Argentineschen Austral),
				'one' => q(Argentineschen Austral),
				'other' => q(Argentinesch Austral),
			},
		},
		'ARP' => {
			display_name => {
				'currency' => q(Argentinesche Peso \(1983–1985\)),
				'one' => q(Argentinesche Peso \(1983–1985\)),
				'other' => q(Argentinesch Pesos \(1983–1985\)),
			},
		},
		'ARS' => {
			display_name => {
				'currency' => q(Argentinesche Peso),
				'one' => q(Argentinesche Peso),
				'other' => q(Argentinesch Pesos),
			},
		},
		'ATS' => {
			symbol => 'öS',
			display_name => {
				'currency' => q(Éisträichesche Schilling),
				'one' => q(Éisträichesche Schilling),
				'other' => q(Éisträichesch Schilling),
			},
		},
		'AUD' => {
			symbol => 'AU$',
			display_name => {
				'currency' => q(Australeschen Dollar),
				'one' => q(Australeschen Dollar),
				'other' => q(Australesch Dollar),
			},
		},
		'AWG' => {
			display_name => {
				'currency' => q(Aruba-Florin),
				'one' => q(Aruba-Florin),
				'other' => q(Aruba-Florin),
			},
		},
		'AZM' => {
			display_name => {
				'currency' => q(Aserbaidschan-Manat \(1993–2006\)),
				'one' => q(Aserbaidschan-Manat \(1993–2006\)),
				'other' => q(Aserbaidschan-Manat \(1993–2006\)),
			},
		},
		'AZN' => {
			display_name => {
				'currency' => q(Aserbaidschan-Manat),
				'one' => q(Aserbaidschan-Manat),
				'other' => q(Aserbaidschan-Manat),
			},
		},
		'BAD' => {
			display_name => {
				'currency' => q(Bosnien an Herzegowina Dinar \(1992–1994\)),
				'one' => q(Bosnien an Herzegowina Dinar \(1992–1994\)),
				'other' => q(Bosnien an Herzegowina Dinaren \(1992–1994\)),
			},
		},
		'BAM' => {
			display_name => {
				'currency' => q(Bosnien an Herzegowina Konvertéierbar Mark),
				'one' => q(Bosnien an Herzegowina Konvertéierbar Mark),
				'other' => q(Bosnien an Herzegowina Konvertéierbar Mark),
			},
		},
		'BBD' => {
			display_name => {
				'currency' => q(Barbados-Dollar),
				'one' => q(Barbados-Dollar),
				'other' => q(Barbados-Dollar),
			},
		},
		'BDT' => {
			symbol => 'BDT',
			display_name => {
				'currency' => q(Bangladesch-Taka),
				'one' => q(Bangladesch-Taka),
				'other' => q(Bangladesch-Taka),
			},
		},
		'BEC' => {
			display_name => {
				'currency' => q(Belsche Frang \(konvertibel\)),
				'one' => q(Belsche Frang \(konvertibel\)),
				'other' => q(Belsch Frang \(konvertibel\)),
			},
		},
		'BEF' => {
			display_name => {
				'currency' => q(Belsche Frang),
				'one' => q(Belsche Frang),
				'other' => q(Belsch Frang),
			},
		},
		'BEL' => {
			display_name => {
				'currency' => q(Belsche Finanz-Frang),
				'one' => q(Belsche Finanz-Frang),
				'other' => q(Belsch Finanz-Frang),
			},
		},
		'BGL' => {
			display_name => {
				'currency' => q(Bulgaresch Lew \(1962–1999\)),
				'one' => q(Bulgaresche Lew \(1962–1999\)),
				'other' => q(Bulgaresch Lew \(1962–1999\)),
			},
		},
		'BGN' => {
			display_name => {
				'currency' => q(Bulgaresch Lew),
				'one' => q(Bulgaresche Lew),
				'other' => q(Bulgaresch Lew),
			},
		},
		'BHD' => {
			display_name => {
				'currency' => q(Bahrain-Dinar),
				'one' => q(Bahrain-Dinar),
				'other' => q(Bahrain-Dinaren),
			},
		},
		'BIF' => {
			display_name => {
				'currency' => q(Burundi-Frang),
				'one' => q(Burundi-Frang),
				'other' => q(Burundi-Frang),
			},
		},
		'BMD' => {
			display_name => {
				'currency' => q(Bermuda-Dollar),
				'one' => q(Bermuda-Dollar),
				'other' => q(Bermuda-Dollar),
			},
		},
		'BND' => {
			symbol => 'BND',
			display_name => {
				'currency' => q(Brunei-Dollar),
				'one' => q(Brunei-Dollar),
				'other' => q(Brunei-Dollar),
			},
		},
		'BOB' => {
			display_name => {
				'currency' => q(Bolivianesche Boliviano),
				'one' => q(Bolivianesche Boliviano),
				'other' => q(Bolivianesch Bolivianos),
			},
		},
		'BOP' => {
			display_name => {
				'currency' => q(Bolivianesche Peso),
				'one' => q(Bolivianesche Peso),
				'other' => q(Bolivianesch Pesos),
			},
		},
		'BOV' => {
			display_name => {
				'currency' => q(Bolivianseche Mvdol),
				'one' => q(Bolivianseche Mvdol),
				'other' => q(Bolivianesch Mvdol),
			},
		},
		'BRB' => {
			display_name => {
				'currency' => q(Brasilianesche Cruzeiro Novo \(1967–1986\)),
				'one' => q(Brasilianesche Cruzeiro Novo \(1967–1986\)),
				'other' => q(Brasilianesch Cruzeiros Novos \(1967–1986\)),
			},
		},
		'BRC' => {
			display_name => {
				'currency' => q(Brasilianesche Cruzado \(1986–1989\)),
				'one' => q(Brasilianesche Cruzado \(1986–1989\)),
				'other' => q(Brasilianesch Cruzados \(1986–1989\)),
			},
		},
		'BRE' => {
			display_name => {
				'currency' => q(Brasilianesche Cruzeiro \(1990–1993\)),
				'one' => q(Brasilianesche Cruzeiro \(1990–1993\)),
				'other' => q(Brasilianesch Cruzeiros \(1990–1993\)),
			},
		},
		'BRL' => {
			symbol => 'R$',
			display_name => {
				'currency' => q(Brasilianesche Real),
				'one' => q(Brasilianesche Real),
				'other' => q(Brasilianesch Reais),
			},
		},
		'BRN' => {
			display_name => {
				'currency' => q(Brasilianesche Cruzado Novo \(1989–1990\)),
				'one' => q(Brasilianeschen Cruzado Novo \(1989–1990\)),
				'other' => q(Brasilianesch Cruzados Novos \(1989–1990\)),
			},
		},
		'BRR' => {
			display_name => {
				'currency' => q(Brasilianesche Cruzeiro \(1993–1994\)),
				'one' => q(Brasilianesche Cruzeiro \(1993–1994\)),
				'other' => q(Brasilianesch Cruzeiros \(1993–1994\)),
			},
		},
		'BRZ' => {
			display_name => {
				'currency' => q(Brasilianesche Cruzeiro \(1942–1967\)),
				'one' => q(Brasilianesche Cruzeiro \(1942–1967\)),
				'other' => q(Brasilianesch Cruzeiros \(1942–1967\)),
			},
		},
		'BSD' => {
			display_name => {
				'currency' => q(Bahama-Dollar),
				'one' => q(Bahama-Dollar),
				'other' => q(Bahama-Dollar),
			},
		},
		'BTN' => {
			symbol => 'BTN',
			display_name => {
				'currency' => q(Bhutan-Ngultrum),
				'one' => q(Bhutan-Ngultrum),
				'other' => q(Bhutan-Ngultrum),
			},
		},
		'BUK' => {
			symbol => 'BUK',
			display_name => {
				'currency' => q(Birmanesche Kyat),
				'one' => q(Birmanesche Kyat),
				'other' => q(Birmanesch Kyat),
			},
		},
		'BWP' => {
			display_name => {
				'currency' => q(Botswanesch Pula),
				'one' => q(Botswanesch Pula),
				'other' => q(Botswanesch Pula),
			},
		},
		'BYB' => {
			display_name => {
				'currency' => q(Wäissrussesche Rubel \(1994–1999\)),
				'one' => q(Wäissrussesche Rubel \(1994–1999\)),
				'other' => q(Wäissrussesch Rubel \(1994–1999\)),
			},
		},
		'BYN' => {
			display_name => {
				'currency' => q(Wäissrussesche Rubel),
				'one' => q(Wäissrussesche Rubel),
				'other' => q(Wäissrussesch Rubel),
			},
		},
		'BYR' => {
			display_name => {
				'currency' => q(Wäissrussesche Rubel \(2000–2016\)),
				'one' => q(Wäissrussesche Rubel \(2000–2016\)),
				'other' => q(Wäissrussesch Rubel \(2000–2016\)),
			},
		},
		'BZD' => {
			display_name => {
				'currency' => q(Belize-Dollar),
				'one' => q(Belize-Dollar),
				'other' => q(Belize-Dollar),
			},
		},
		'CAD' => {
			symbol => 'CA$',
			display_name => {
				'currency' => q(Kanadeschen Dollar),
				'one' => q(Kanadeschen Dollar),
				'other' => q(Kanadesch Dollar),
			},
		},
		'CDF' => {
			display_name => {
				'currency' => q(Kongo-Frang),
				'one' => q(Kongo-Frang),
				'other' => q(Kongo-Frang),
			},
		},
		'CHE' => {
			display_name => {
				'currency' => q(WIR-Euro),
				'one' => q(WIR-Euro),
				'other' => q(WIR-Euro),
			},
		},
		'CHF' => {
			display_name => {
				'currency' => q(Schwäizer Frang),
				'one' => q(Schwäizer Frang),
				'other' => q(Schwäizer Frang),
			},
		},
		'CHW' => {
			display_name => {
				'currency' => q(WIR-Frang),
				'one' => q(WIR-Frang),
				'other' => q(WIR-Frang),
			},
		},
		'CLF' => {
			display_name => {
				'currency' => q(Chileneschen Unidad de Fomento),
				'one' => q(Chileneschen Unidad de Fomento),
				'other' => q(Chilenesch Unidades de Fomento),
			},
		},
		'CLP' => {
			display_name => {
				'currency' => q(Chilenesche Peso),
				'one' => q(Chilenesche Peso),
				'other' => q(Chilenesch Pesos),
			},
		},
		'CNY' => {
			symbol => 'CN¥',
			display_name => {
				'currency' => q(Renminbi Yuan),
				'one' => q(Renminbi Yuan),
				'other' => q(Renminbi Yuan),
			},
		},
		'COP' => {
			display_name => {
				'currency' => q(Kolumbianesche Peso),
				'one' => q(Kolumbianesche Peso),
				'other' => q(Kolumbianesch Pesos),
			},
		},
		'CRC' => {
			display_name => {
				'currency' => q(Costa-Rica-Colón),
				'one' => q(Costa-Rica-Colón),
				'other' => q(Costa-Rica-Colones),
			},
		},
		'CSD' => {
			display_name => {
				'currency' => q(Serbeschen Dinar \(2002–2006\)),
				'one' => q(Serbeschen Dinar \(2002–2006\)),
				'other' => q(Serbesch Dinaren \(2002–2006\)),
			},
		},
		'CSK' => {
			display_name => {
				'currency' => q(Tschechoslowakesch Kroun),
				'one' => q(Tschechoslowakesch Kroun),
				'other' => q(Tschechoslowakesch Krounen),
			},
		},
		'CUC' => {
			display_name => {
				'currency' => q(Kubanesche Peso \(konvertibel\)),
				'one' => q(Kubanesche Peso \(konvertibel\)),
				'other' => q(Kubanesch Pesos \(konvertibel\)),
			},
		},
		'CUP' => {
			display_name => {
				'currency' => q(Kubanesche Peso),
				'one' => q(Kubanesche Peso),
				'other' => q(Kubanesch Pesos),
			},
		},
		'CVE' => {
			display_name => {
				'currency' => q(Kap-Verde-Escudo),
				'one' => q(Kap-Verde-Escudo),
				'other' => q(Kap-Verde-Escudos),
			},
		},
		'CYP' => {
			display_name => {
				'currency' => q(Zypern-Pond),
				'one' => q(Zypern-Pond),
				'other' => q(Zypern-Pond),
			},
		},
		'CZK' => {
			display_name => {
				'currency' => q(Tschechesch Kroun),
				'one' => q(Tschechesch Kroun),
				'other' => q(Tschechesch Krounen),
			},
		},
		'DDM' => {
			display_name => {
				'currency' => q(DDR-Mark),
				'one' => q(DDR-Mark),
				'other' => q(DDR-Mark),
			},
		},
		'DEM' => {
			display_name => {
				'currency' => q(Däitsch Mark),
				'one' => q(Däitsch Mark),
				'other' => q(Däitsch Mark),
			},
		},
		'DJF' => {
			display_name => {
				'currency' => q(Dschibuti-Frang),
				'one' => q(Dschibuti-Frang),
				'other' => q(Dschibuti-Frang),
			},
		},
		'DKK' => {
			display_name => {
				'currency' => q(Dänesch Kroun),
				'one' => q(Dänesch Kroun),
				'other' => q(Dänesch Krounen),
			},
		},
		'DOP' => {
			display_name => {
				'currency' => q(Dominikanesche Peso),
				'one' => q(Dominikanesche Peso),
				'other' => q(Dominikanesch Pesos),
			},
		},
		'DZD' => {
			display_name => {
				'currency' => q(Algereschen Dinar),
				'one' => q(Algereschen Dinar),
				'other' => q(Algeresch Dinaren),
			},
		},
		'ECS' => {
			display_name => {
				'currency' => q(Ecuadorianesche Sucre),
				'one' => q(Ecuadorianesche Sucre),
				'other' => q(Ecuadorianesch Sucres),
			},
		},
		'ECV' => {
			display_name => {
				'currency' => q(Verrechnungseenheete fir Ecuador),
				'one' => q(Verrechnungseenheet fir Ecuador),
				'other' => q(Verrechnungseenheete fir Ecuador),
			},
		},
		'EEK' => {
			display_name => {
				'currency' => q(Estnesch Kroun),
				'one' => q(Estnesch Kroun),
				'other' => q(Estnesch Krounen),
			},
		},
		'EGP' => {
			display_name => {
				'currency' => q(Egyptescht Pond),
				'one' => q(Egyptescht Pond),
				'other' => q(Egyptesch Pond),
			},
		},
		'ERN' => {
			display_name => {
				'currency' => q(Eritréieschen Nakfa),
				'one' => q(Eritréieschen Nakfa),
				'other' => q(Eritréiesch Nakfa),
			},
		},
		'ESA' => {
			display_name => {
				'currency' => q(Spuenesch Peseta \(A–Konten\)),
				'one' => q(Spuenesch Peseta \(A–Konten\)),
				'other' => q(Spuenesch Peseten \(A–Konten\)),
			},
		},
		'ESB' => {
			display_name => {
				'currency' => q(Spuenesch Peseta \(konvertibel\)),
				'one' => q(Spuenesch Peseta \(konvertibel\)),
				'other' => q(Spuenesch Peseten \(konvertibel\)),
			},
		},
		'ESP' => {
			display_name => {
				'currency' => q(Spuenesch Peseta),
				'one' => q(Spuenesch Peseta),
				'other' => q(Spuenesch Peseten),
			},
		},
		'ETB' => {
			display_name => {
				'currency' => q(Ethiopescht Birr),
				'one' => q(Ethiopescht Birr),
				'other' => q(Ethiopesch Birr),
			},
		},
		'EUR' => {
			symbol => '€',
			display_name => {
				'currency' => q(Euro),
				'one' => q(Euro),
				'other' => q(Euro),
			},
		},
		'FIM' => {
			display_name => {
				'currency' => q(Finnesch Mark),
				'one' => q(Finnesch Mark),
				'other' => q(Finnesch Mark),
			},
		},
		'FJD' => {
			display_name => {
				'currency' => q(Fidschi-Dollar),
				'one' => q(Fidschi-Dollar),
				'other' => q(Fidschi-Dollar),
			},
		},
		'FKP' => {
			display_name => {
				'currency' => q(Falkland-Pond),
				'one' => q(Falkland-Pond),
				'other' => q(Falkland-Pond),
			},
		},
		'FRF' => {
			display_name => {
				'currency' => q(Franséische Frang),
				'one' => q(Franséische Frang),
				'other' => q(Franséisch Frang),
			},
		},
		'GBP' => {
			symbol => '£',
			display_name => {
				'currency' => q(Britescht Pond),
				'one' => q(Britescht Pond),
				'other' => q(Britesch Pond),
			},
		},
		'GEK' => {
			display_name => {
				'currency' => q(Georgesche Kupon Larit),
				'one' => q(Georgesche Kupon Larit),
				'other' => q(Georgesch Kupon Larit),
			},
		},
		'GEL' => {
			display_name => {
				'currency' => q(Georgesche Lari),
				'one' => q(Georgesche Lari),
				'other' => q(Georgesch Lari),
			},
		},
		'GHC' => {
			display_name => {
				'currency' => q(Ghanaeschen Cedi \(1979–2007\)),
				'one' => q(Ghanaeschen Cedi \(1979–2007\)),
				'other' => q(Ghanaesch Cedi \(1979–2007\)),
			},
		},
		'GHS' => {
			display_name => {
				'currency' => q(Ghanaeschen Cedi),
				'one' => q(Ghanaeschen Cedi),
				'other' => q(Ghanaesch Cedi),
			},
		},
		'GIP' => {
			display_name => {
				'currency' => q(Gibraltar-Pond),
				'one' => q(Gibraltar-Pond),
				'other' => q(Gibraltar-Pond),
			},
		},
		'GMD' => {
			display_name => {
				'currency' => q(Gambia-Dalasi),
				'one' => q(Gambia-Dalasi),
				'other' => q(Gambia-Dalasi),
			},
		},
		'GNF' => {
			display_name => {
				'currency' => q(Guinea-Frang),
				'one' => q(Guinea-Frang),
				'other' => q(Guinea-Frang),
			},
		},
		'GNS' => {
			display_name => {
				'currency' => q(Guinéiesche Syli),
				'one' => q(Guinéiesche Syli),
				'other' => q(Guinéiesch Syli),
			},
		},
		'GQE' => {
			display_name => {
				'currency' => q(Equatorialguinea-Ekwele),
				'one' => q(Equatorialguinea-Ekwele),
				'other' => q(Equatorialguinea-Ekwele),
			},
		},
		'GRD' => {
			display_name => {
				'currency' => q(Griichesch Drachme),
				'one' => q(Griichesch Drachme),
				'other' => q(Griichesch Drachmen),
			},
		},
		'GTQ' => {
			display_name => {
				'currency' => q(Guatemaltekesche Quetzal),
				'one' => q(Guatemaltekesche Quetzal),
				'other' => q(Guatemaltekesch Quetzales),
			},
		},
		'GWE' => {
			display_name => {
				'currency' => q(Portugisesch-Guinea Escudo),
				'one' => q(Portugisesch-Guinea Escudo),
				'other' => q(Portugisesch-Guinea Escudos),
			},
		},
		'GWP' => {
			display_name => {
				'currency' => q(Guinea-Bissau Peso),
				'one' => q(Guinea-Bissau Peso),
				'other' => q(Guinea-Bissau Pesos),
			},
		},
		'GYD' => {
			display_name => {
				'currency' => q(Guyana-Dollar),
				'one' => q(Guyana-Dollar),
				'other' => q(Guyana-Dollar),
			},
		},
		'HKD' => {
			symbol => 'HK$',
			display_name => {
				'currency' => q(Hong-Kong-Dollar),
				'one' => q(Hong-Kong-Dollar),
				'other' => q(Hong-Kong-Dollar),
			},
		},
		'HNL' => {
			display_name => {
				'currency' => q(Honduras-Lempira),
				'one' => q(Honduras-Lempira),
				'other' => q(Honduras-Lempira),
			},
		},
		'HRD' => {
			display_name => {
				'currency' => q(Kroateschen Dinar),
				'one' => q(Kroateschen Dinar),
				'other' => q(Kroatesch Dinaren),
			},
		},
		'HRK' => {
			display_name => {
				'currency' => q(Kroatesche Kuna),
				'one' => q(Kroatesche Kuna),
				'other' => q(Kroatesch Kuna),
			},
		},
		'HTG' => {
			display_name => {
				'currency' => q(Haitianesch Gourde),
				'one' => q(Haitianesch Gourde),
				'other' => q(Haitianesch Gourdes),
			},
		},
		'HUF' => {
			display_name => {
				'currency' => q(Ungaresche Forint),
				'one' => q(Ungaresche Forint),
				'other' => q(Ungaresch Forint),
			},
		},
		'IDR' => {
			symbol => 'IDR',
			display_name => {
				'currency' => q(Indonesesch Rupiah),
				'one' => q(Indonesesch Rupiah),
				'other' => q(Indonesesch Rupiah),
			},
		},
		'IEP' => {
			display_name => {
				'currency' => q(Irescht Pond),
				'one' => q(Irescht Pond),
				'other' => q(Iresch Pond),
			},
		},
		'ILP' => {
			display_name => {
				'currency' => q(Israelescht Pond),
				'one' => q(Israelescht Pond),
				'other' => q(Israelesch Pond),
			},
		},
		'ILS' => {
			symbol => '₪',
			display_name => {
				'currency' => q(Israeleschen Neie Schekel),
				'one' => q(Israeleschen Neie Schekel),
				'other' => q(Israelesch Nei Schekel),
			},
		},
		'INR' => {
			symbol => '₹',
			display_name => {
				'currency' => q(Indesch Rupie),
				'one' => q(Indesch Rupie),
				'other' => q(Indesch Rupien),
			},
		},
		'IQD' => {
			display_name => {
				'currency' => q(Irakeschen Dinar),
				'one' => q(Irakeschen Dinar),
				'other' => q(Irakesch Dinaren),
			},
		},
		'IRR' => {
			symbol => 'IRR',
			display_name => {
				'currency' => q(Iranesch Rial),
				'one' => q(Iranesch Rial),
				'other' => q(Iranesch Rial),
			},
		},
		'ISK' => {
			display_name => {
				'currency' => q(Islännesch Kroun),
				'one' => q(Islännesch Kroun),
				'other' => q(Islännesch Krounen),
			},
		},
		'ITL' => {
			display_name => {
				'currency' => q(Italienesch Lira),
				'one' => q(Italienesch Lira),
				'other' => q(Italienesch Lire),
			},
		},
		'JMD' => {
			display_name => {
				'currency' => q(Jamaika-Dollar),
				'one' => q(Jamaika-Dollar),
				'other' => q(Jamaika-Dollar),
			},
		},
		'JOD' => {
			display_name => {
				'currency' => q(Jordaneschen Dinar),
				'one' => q(Jordaneschen Dinar),
				'other' => q(Jordanesch Dinaren),
			},
		},
		'JPY' => {
			symbol => '¥',
			display_name => {
				'currency' => q(Japanesche Yen),
				'one' => q(Japanesche Yen),
				'other' => q(Japanesch Yen),
			},
		},
		'KES' => {
			display_name => {
				'currency' => q(Kenia-Schilling),
				'one' => q(Kenia-Schilling),
				'other' => q(Kenia-Schilling),
			},
		},
		'KGS' => {
			display_name => {
				'currency' => q(Kirgisesche Som),
				'one' => q(Kirgisesche Som),
				'other' => q(Kirgisesch Som),
			},
		},
		'KHR' => {
			symbol => 'KHR',
			display_name => {
				'currency' => q(Kambodschanesche Riel),
				'one' => q(Kambodschanesche Riel),
				'other' => q(Kambodschanesch Riel),
			},
		},
		'KMF' => {
			display_name => {
				'currency' => q(Komore-Frang),
				'one' => q(Komore-Frang),
				'other' => q(Komore-Frang),
			},
		},
		'KPW' => {
			symbol => 'KPW',
			display_name => {
				'currency' => q(Nordkoreanesche Won),
				'one' => q(Nordkoreanesche Won),
				'other' => q(Nordkoreanesch Won),
			},
		},
		'KRW' => {
			symbol => '₩',
			display_name => {
				'currency' => q(Südkoreanesche Won),
				'one' => q(Südkoreanesche Won),
				'other' => q(Südkoreanesch Won),
			},
		},
		'KWD' => {
			display_name => {
				'currency' => q(Kuwait-Dinar),
				'one' => q(Kuwait-Dinar),
				'other' => q(Kuwait-Dinaren),
			},
		},
		'KYD' => {
			display_name => {
				'currency' => q(Kaiman-Dollar),
				'one' => q(Kaiman-Dollar),
				'other' => q(Kaiman-Dollar),
			},
		},
		'KZT' => {
			display_name => {
				'currency' => q(Kasacheschen Tenge),
				'one' => q(Kasacheschen Tenge),
				'other' => q(Kasachesch Tenge),
			},
		},
		'LAK' => {
			symbol => 'LAK',
			display_name => {
				'currency' => q(Laoteschen Kip),
				'one' => q(Laoteschen Kip),
				'other' => q(Laotesch Kip),
			},
		},
		'LBP' => {
			display_name => {
				'currency' => q(Libanesescht Pond),
				'one' => q(Libanesescht Pond),
				'other' => q(Libanesesch Pond),
			},
		},
		'LKR' => {
			symbol => 'LKR',
			display_name => {
				'currency' => q(Sri-Lanka-Rupie),
				'one' => q(Sri-Lanka-Rupie),
				'other' => q(Sri-Lanka-Rupien),
			},
		},
		'LRD' => {
			display_name => {
				'currency' => q(Liberianeschen Dollar),
				'one' => q(Liberianeschen Dollar),
				'other' => q(Liberianesch Dollar),
			},
		},
		'LSL' => {
			display_name => {
				'currency' => q(Loti),
				'one' => q(Loti),
				'other' => q(Loti),
			},
		},
		'LTL' => {
			display_name => {
				'currency' => q(Litauesche Litas),
				'one' => q(Litauesche Litas),
				'other' => q(Litauesch Litas),
			},
		},
		'LTT' => {
			display_name => {
				'currency' => q(Litaueschen Talonas),
				'one' => q(Litaueschen Talonas),
				'other' => q(Litauesch Talonas),
			},
		},
		'LUC' => {
			display_name => {
				'currency' => q(Lëtzebuerger Frang \(konvertibel\)),
				'one' => q(Lëtzebuerger Frang \(konvertibel\)),
				'other' => q(Lëtzebuerger Frang \(konvertibel\)),
			},
		},
		'LUF' => {
			display_name => {
				'currency' => q(Lëtzebuerger Frang),
				'one' => q(Lëtzebuerger Frang),
				'other' => q(Lëtzebuerger Frang),
			},
		},
		'LUL' => {
			display_name => {
				'currency' => q(Lëtzebuerger Finanz-Frang),
				'one' => q(Lëtzebuerger Finanz-Frang),
				'other' => q(Lëtzebuerger Finanz-Frang),
			},
		},
		'LVL' => {
			display_name => {
				'currency' => q(Lettesche Lats),
				'one' => q(Lettesche Lats),
				'other' => q(Lettesch Lats),
			},
		},
		'LVR' => {
			display_name => {
				'currency' => q(Lettesche Rubel),
				'one' => q(Lettesche Rubel),
				'other' => q(Lettesch Rubel),
			},
		},
		'LYD' => {
			display_name => {
				'currency' => q(Libeschen Dinar),
				'one' => q(Libeschen Dinar),
				'other' => q(Libesch Dinaren),
			},
		},
		'MAD' => {
			display_name => {
				'currency' => q(Marokkaneschen Dirham),
				'one' => q(Marokkaneschen Dirham),
				'other' => q(Marokkanesch Dirham),
			},
		},
		'MAF' => {
			display_name => {
				'currency' => q(Marokkanesche Frang),
				'one' => q(Marokkanesche Frang),
				'other' => q(Marokkanesch Frang),
			},
		},
		'MDL' => {
			display_name => {
				'currency' => q(Moldawesche Leu),
				'one' => q(Moldawesche Leu),
				'other' => q(Moldawesch Leu),
			},
		},
		'MGA' => {
			display_name => {
				'currency' => q(Madagaskar-Ariary),
				'one' => q(Madagaskar-Ariary),
				'other' => q(Madagaskar-Ariary),
			},
		},
		'MGF' => {
			display_name => {
				'currency' => q(Madagaskar-Frang),
				'one' => q(Madagaskar-Frang),
				'other' => q(Madagaskar-Frang),
			},
		},
		'MKD' => {
			display_name => {
				'currency' => q(Mazedoneschen Denar),
				'one' => q(Mazedoneschen Denar),
				'other' => q(Mazedonesch Denari),
			},
		},
		'MLF' => {
			display_name => {
				'currency' => q(Malesche Frang),
				'one' => q(Malesche Frang),
				'other' => q(Malesch Frang),
			},
		},
		'MMK' => {
			symbol => 'MMK',
			display_name => {
				'currency' => q(Myanmaresche Kyat),
				'one' => q(Myanmaresche Kyat),
				'other' => q(Myanmaresch Kyat),
			},
		},
		'MNT' => {
			symbol => 'MNT',
			display_name => {
				'currency' => q(Mongoleschen Tögrög),
				'one' => q(Mongoleschen Tögrög),
				'other' => q(Mongolesch Tögrög),
			},
		},
		'MOP' => {
			symbol => 'MOP',
			display_name => {
				'currency' => q(Macau-Pataca),
				'one' => q(Macau-Pataca),
				'other' => q(Macau-Pataca),
			},
		},
		'MRO' => {
			display_name => {
				'currency' => q(Mauretaneschen Ouguiya \(1973–2017\)),
				'one' => q(Mauretaneschen Ouguiya \(1973–2017\)),
				'other' => q(Mauretanesch Ouguiya \(1973–2017\)),
			},
		},
		'MRU' => {
			display_name => {
				'currency' => q(Mauretaneschen Ouguiya),
				'one' => q(Mauretaneschen Ouguiya),
				'other' => q(Mauretanesch Ouguiya),
			},
		},
		'MTL' => {
			display_name => {
				'currency' => q(Maltesesch Lira),
				'one' => q(Maltesesch Lira),
				'other' => q(Maltesesch Lira),
			},
		},
		'MTP' => {
			display_name => {
				'currency' => q(Maltesescht Pond),
				'one' => q(Maltesescht Pond),
				'other' => q(Maltesesch Pond),
			},
		},
		'MUR' => {
			display_name => {
				'currency' => q(Mauritius-Rupie),
				'one' => q(Mauritius-Rupie),
				'other' => q(Mauritius-Rupien),
			},
		},
		'MVR' => {
			symbol => 'MVR',
			display_name => {
				'currency' => q(Maldiven-Rupie),
				'one' => q(Maldiven-Rupie),
				'other' => q(Maldiven-Rupien),
			},
		},
		'MWK' => {
			display_name => {
				'currency' => q(Malawi-Kwacha),
				'one' => q(Malawi-Kwacha),
				'other' => q(Malawi-Kwacha),
			},
		},
		'MXN' => {
			symbol => 'MX$',
			display_name => {
				'currency' => q(Mexikanesche Peso),
				'one' => q(Mexikanesche Peso),
				'other' => q(Mexikanesch Pesos),
			},
		},
		'MXP' => {
			display_name => {
				'currency' => q(Mexikanesche Sëlwer-Peso \(1861–1992\)),
				'one' => q(Mexikanesche Sëlwer-Peso \(1861–1992\)),
				'other' => q(Mexikanesch Sëlwer-Pesos \(1861–1992\)),
			},
		},
		'MXV' => {
			display_name => {
				'currency' => q(Mexikaneschen Unidad de Inversion \(UDI\)),
				'one' => q(Mexikaneschen Unidad de Inversion \(UDI\)),
				'other' => q(Mexikanesch Unidades de Inversion \(UDI\)),
			},
		},
		'MYR' => {
			symbol => 'MYR',
			display_name => {
				'currency' => q(Malayseschen Ringgit),
				'one' => q(Malayseschen Ringgit),
				'other' => q(Malaysesch Ringgit),
			},
		},
		'MZE' => {
			display_name => {
				'currency' => q(Mosambikaneschen Escudo),
				'one' => q(Mozambikanesch Escudo),
				'other' => q(Mozambikanesch Escudos),
			},
		},
		'MZM' => {
			display_name => {
				'currency' => q(Mosambikanesche Metical \(1980–2006\)),
				'one' => q(Mosambikanesche Metical \(1980–2006\)),
				'other' => q(Mosambikanesch Meticais \(1980–2006\)),
			},
		},
		'MZN' => {
			display_name => {
				'currency' => q(Mosambikanesche Metical),
				'one' => q(Mosambikanesche Metical),
				'other' => q(Mosambikanesch Meticais),
			},
		},
		'NAD' => {
			display_name => {
				'currency' => q(Namibia-Dollar),
				'one' => q(Namibia-Dollar),
				'other' => q(Namibia-Dollar),
			},
		},
		'NGN' => {
			display_name => {
				'currency' => q(Nigerianeschen Naira),
				'one' => q(Nigerianeschen Naira),
				'other' => q(Nigerianesch Naira),
			},
		},
		'NIC' => {
			display_name => {
				'currency' => q(Nicaraguanesche Córdoba \(1988–1991\)),
				'one' => q(Nicaraguanesche Córdoba \(1988–1991\)),
				'other' => q(Nicaraguanesch Córdobas \(1988–1991\)),
			},
		},
		'NIO' => {
			display_name => {
				'currency' => q(Nicaraguanesche Córdoba),
				'one' => q(Nicaraguanesche Córdoba),
				'other' => q(Nicaraguanesch Córdobas),
			},
		},
		'NLG' => {
			display_name => {
				'currency' => q(Hollännesche Gulden),
				'one' => q(Hollännesche Gulden),
				'other' => q(Hollännesch Gulden),
			},
		},
		'NOK' => {
			display_name => {
				'currency' => q(Norwegesch Kroun),
				'one' => q(Norwegesch Kroun),
				'other' => q(Norwegesch Krounen),
			},
		},
		'NPR' => {
			symbol => 'NPR',
			display_name => {
				'currency' => q(Nepalesesch Rupie),
				'one' => q(Nepalesesch Rupie),
				'other' => q(Nepalesesch Rupien),
			},
		},
		'NZD' => {
			symbol => 'NZ$',
			display_name => {
				'currency' => q(Neiséiland-Dollar),
				'one' => q(Neiséiland-Dollar),
				'other' => q(Neiséiland-Dollar),
			},
		},
		'OMR' => {
			display_name => {
				'currency' => q(Omanesche Rial),
				'one' => q(Omanesche Rial),
				'other' => q(Omanesch Rials),
			},
		},
		'PAB' => {
			display_name => {
				'currency' => q(Panamaesche Balboa),
				'one' => q(Panamaesche Balboa),
				'other' => q(Panamaesch Balboas),
			},
		},
		'PEI' => {
			display_name => {
				'currency' => q(Peruaneschen Inti),
				'one' => q(Peruaneschen Inti),
				'other' => q(Peruanesch Inti),
			},
		},
		'PEN' => {
			display_name => {
				'currency' => q(Peruaneschen Sol),
				'one' => q(Peruaneschen Sol),
				'other' => q(Peruanesch Soles),
			},
		},
		'PES' => {
			display_name => {
				'currency' => q(Peruaneschen Sol \(1863–1965\)),
				'one' => q(Peruaneschen Sol \(1863–1965\)),
				'other' => q(Peruanesch Soles \(1863–1965\)),
			},
		},
		'PGK' => {
			display_name => {
				'currency' => q(Papua-Neiguinéiesche Kina),
				'one' => q(Papua-Neiguinéiesche Kina),
				'other' => q(Papua-Neiguinéiesch Kina),
			},
		},
		'PHP' => {
			symbol => 'PHP',
			display_name => {
				'currency' => q(Philippinnesche Peso),
				'one' => q(Philippinnesche Peso),
				'other' => q(Philippinnesch Pesos),
			},
		},
		'PKR' => {
			symbol => 'PKR',
			display_name => {
				'currency' => q(Pakistanesch Rupie),
				'one' => q(Pakistanesch Rupie),
				'other' => q(Pakistanesch Rupien),
			},
		},
		'PLN' => {
			display_name => {
				'currency' => q(Polneschen Zloty),
				'one' => q(Polneschen Zloty),
				'other' => q(Polnesch Zloty),
			},
		},
		'PLZ' => {
			display_name => {
				'currency' => q(Polneschen Zloty \(1950–1995\)),
				'one' => q(Polneschen Zloty \(1950–1995\)),
				'other' => q(Polnesch Zloty \(1950–1995\)),
			},
		},
		'PTE' => {
			display_name => {
				'currency' => q(Portugiseschen Escudo),
				'one' => q(Portugiseschen Escudo),
				'other' => q(Portugisesch Escudos),
			},
		},
		'PYG' => {
			display_name => {
				'currency' => q(Paraguayeschen Guaraní),
				'one' => q(Paraguayeschen Guaraní),
				'other' => q(Paraguayesch Guaraníes),
			},
		},
		'QAR' => {
			display_name => {
				'currency' => q(Katar-Riyal),
				'one' => q(Katar-Riyal),
				'other' => q(Katar-Riyal),
			},
		},
		'RHD' => {
			display_name => {
				'currency' => q(Rhodeseschen Dollar),
				'one' => q(Rhodeseschen Dollar),
				'other' => q(Rhodesesch Dollar),
			},
		},
		'ROL' => {
			display_name => {
				'currency' => q(Rumänesche Leu \(1952–2006\)),
				'one' => q(Rumänesche Leu \(1952–2006\)),
				'other' => q(Rumänesch Leu \(1952–2006\)),
			},
		},
		'RON' => {
			display_name => {
				'currency' => q(Rumänesche Leu),
				'one' => q(Rumänesche Leu),
				'other' => q(Rumänesch Leu),
			},
		},
		'RSD' => {
			display_name => {
				'currency' => q(Serbeschen Dinar),
				'one' => q(Serbeschen Dinar),
				'other' => q(Serbesch Dinaren),
			},
		},
		'RUB' => {
			display_name => {
				'currency' => q(Russesche Rubel),
				'one' => q(Russesche Rubel),
				'other' => q(Russesch Rubel),
			},
		},
		'RUR' => {
			display_name => {
				'currency' => q(Russesche Rubel \(1991–1998\)),
				'one' => q(Russesche Rubel \(1991–1998\)),
				'other' => q(Russesch Rubel \(1991–1998\)),
			},
		},
		'RWF' => {
			display_name => {
				'currency' => q(Ruanda-Frang),
				'one' => q(Ruanda-Frang),
				'other' => q(Ruanda-Frang),
			},
		},
		'SAR' => {
			display_name => {
				'currency' => q(Saudi-Rial),
				'one' => q(Saudi-Rial),
				'other' => q(Saudi-Rial),
			},
		},
		'SBD' => {
			display_name => {
				'currency' => q(Salomonen-Dollar),
				'one' => q(Salomonen-Dollar),
				'other' => q(Salomonen-Dollar),
			},
		},
		'SCR' => {
			display_name => {
				'currency' => q(Seychellen-Rupie),
				'one' => q(Seychellen-Rupie),
				'other' => q(Seychellen-Rupien),
			},
		},
		'SDD' => {
			display_name => {
				'currency' => q(Sudaneseschen Dinar \(1992–2007\)),
				'one' => q(Sudaneseschen Dinar \(1992–2007\)),
				'other' => q(Sudanesesch Dinaren \(1992–2007\)),
			},
		},
		'SDG' => {
			display_name => {
				'currency' => q(Sudanesescht Pond),
				'one' => q(Sudanesescht Pond),
				'other' => q(Sudanesesch Pond),
			},
		},
		'SDP' => {
			display_name => {
				'currency' => q(Sudanesescht Pond \(1957–1998\)),
				'one' => q(Sudanesescht Pond \(1957–1998\)),
				'other' => q(Sudanesesch Pond \(1957–1998\)),
			},
		},
		'SEK' => {
			display_name => {
				'currency' => q(Schwedesch Kroun),
				'one' => q(Schwedesch Kroun),
				'other' => q(Schwedesch Krounen),
			},
		},
		'SGD' => {
			symbol => 'SGD',
			display_name => {
				'currency' => q(Singapur-Dollar),
				'one' => q(Singapur-Dollar),
				'other' => q(Singapur-Dollar),
			},
		},
		'SHP' => {
			display_name => {
				'currency' => q(St. Helena-Pond),
				'one' => q(St. Helena-Pond),
				'other' => q(St. Helena-Pond),
			},
		},
		'SIT' => {
			display_name => {
				'currency' => q(Sloweneschen Tolar),
				'one' => q(Sloweneschen Tolar),
				'other' => q(Slowenesch Tolar),
			},
		},
		'SKK' => {
			display_name => {
				'currency' => q(Slowakesch Kroun),
				'one' => q(Slowakesch Kroun),
				'other' => q(Slowakesch Krounen),
			},
		},
		'SLL' => {
			display_name => {
				'currency' => q(Sierra-leonesche Leone),
				'one' => q(Sierra-leonesche Leone),
				'other' => q(Sierra-leonesch Leones),
			},
		},
		'SOS' => {
			display_name => {
				'currency' => q(Somalia-Schilling),
				'one' => q(Somalia-Schilling),
				'other' => q(Somalia-Schilling),
			},
		},
		'SRD' => {
			display_name => {
				'currency' => q(Surinameschen Dollar),
				'one' => q(Surinameschen Dollar),
				'other' => q(Surinamesch Dollar),
			},
		},
		'SRG' => {
			display_name => {
				'currency' => q(Surinamesche Gulden),
				'one' => q(Surinamesche Gulden),
				'other' => q(Surinamesch Gulden),
			},
		},
		'SSP' => {
			display_name => {
				'currency' => q(Südsudanesescht Pond),
				'one' => q(Südsudanesescht Pond),
				'other' => q(Südsudanesesch Pond),
			},
		},
		'STD' => {
			display_name => {
				'currency' => q(São-toméeschen Dobra \(1977–2017\)),
				'one' => q(São-toméeschen Dobra \(1977–2017\)),
				'other' => q(São-toméesch Dobra \(1977–2017\)),
			},
		},
		'STN' => {
			display_name => {
				'currency' => q(São-toméeschen Dobra),
				'one' => q(São-toméeschen Dobra),
				'other' => q(São-toméesch Dobra),
			},
		},
		'SUR' => {
			display_name => {
				'currency' => q(Sowjetesche Rubel),
				'one' => q(Sowjetesche Rubel),
				'other' => q(Sowjetesch Rubel),
			},
		},
		'SVC' => {
			display_name => {
				'currency' => q(El-Salvador-Colón),
				'one' => q(El-Salvador-Colón),
				'other' => q(El-Salvador-Colones),
			},
		},
		'SYP' => {
			display_name => {
				'currency' => q(Syrescht Pond),
				'one' => q(Syrescht Pond),
				'other' => q(Syresch Pond),
			},
		},
		'SZL' => {
			display_name => {
				'currency' => q(Swasilännesche Lilangeni),
				'one' => q(Swasilännesche Lilangeni),
				'other' => q(Swasilännesch Lilangeni),
			},
		},
		'THB' => {
			symbol => '฿',
			display_name => {
				'currency' => q(Thailännesche Baht),
				'one' => q(Thailännesche Baht),
				'other' => q(Thailännesch Baht),
			},
		},
		'TJR' => {
			display_name => {
				'currency' => q(Tadschikistan-Rubel),
				'one' => q(Tadschikistan-Rubel),
				'other' => q(Tadschikistan-Rubel),
			},
		},
		'TJS' => {
			display_name => {
				'currency' => q(Tadschikistan-Somoni),
				'one' => q(Tadschikistan-Somoni),
				'other' => q(Tadschikistan-Somoni),
			},
		},
		'TMM' => {
			display_name => {
				'currency' => q(Turkmenistan-Manat \(1993–2009\)),
				'one' => q(Turkmenistan-Manat \(1993–2009\)),
				'other' => q(Turkmenistan-Manat \(1993–2009\)),
			},
		},
		'TMT' => {
			display_name => {
				'currency' => q(Turkmenistan-Manat),
				'one' => q(Turkmenistan-Manat),
				'other' => q(Turkmenistan-Manat),
			},
		},
		'TND' => {
			display_name => {
				'currency' => q(Tuneseschen Dinar),
				'one' => q(Tuneseschen Dinar),
				'other' => q(Tunesesch Dinaren),
			},
		},
		'TOP' => {
			display_name => {
				'currency' => q(Tongaeschen Paʻanga),
				'one' => q(Tongaeschen Paʻanga),
				'other' => q(Tongaesch Paʻanga),
			},
		},
		'TPE' => {
			display_name => {
				'currency' => q(Timor-Escudo),
				'one' => q(Timor-Escudo),
				'other' => q(Timor-Escudo),
			},
		},
		'TRL' => {
			display_name => {
				'currency' => q(Tierkesch Lira \(1922–2005\)),
				'one' => q(Tierkesch Lira \(1922–2005\)),
				'other' => q(Tierkesch Lira \(1922–2005\)),
			},
		},
		'TRY' => {
			display_name => {
				'currency' => q(Tierkesch Lira),
				'one' => q(Tierkesch Lira),
				'other' => q(Tierkesch Lira),
			},
		},
		'TTD' => {
			display_name => {
				'currency' => q(Trinidad-an-Tobago-Dollar),
				'one' => q(Trinidad-an-Tobago-Dollar),
				'other' => q(Trinidad-an-Tobago-Dollar),
			},
		},
		'TWD' => {
			symbol => 'NT$',
			display_name => {
				'currency' => q(Neien Taiwan-Dollar),
				'one' => q(Neien Taiwan-Dollar),
				'other' => q(Nei Taiwan-Dollar),
			},
		},
		'TZS' => {
			display_name => {
				'currency' => q(Tansania-Schilling),
				'one' => q(Tansania-Schilling),
				'other' => q(Tansania-Schilling),
			},
		},
		'UAH' => {
			display_name => {
				'currency' => q(Ukraineschen Hrywnja),
				'one' => q(Ukraineschen Hrywnja),
				'other' => q(Ukrainesch Hrywen),
			},
		},
		'UAK' => {
			display_name => {
				'currency' => q(Ukrainesche Karbovanetz),
				'one' => q(Ukrainesche Karbovanetz),
				'other' => q(Ukrainesch Karbovanetz),
			},
		},
		'UGS' => {
			display_name => {
				'currency' => q(Uganda-Schilling \(1966–1987\)),
				'one' => q(Uganda-Schilling \(1966–1987\)),
				'other' => q(Uganda-Schilling \(1966–1987\)),
			},
		},
		'UGX' => {
			display_name => {
				'currency' => q(Uganda-Schilling),
				'one' => q(Uganda-Schilling),
				'other' => q(Uganda-Schilling),
			},
		},
		'USD' => {
			symbol => '$',
			display_name => {
				'currency' => q(US-Dollar),
				'one' => q(US-Dollar),
				'other' => q(US-Dollar),
			},
		},
		'USN' => {
			display_name => {
				'currency' => q(US Dollar \(Nächsten Dag\)),
				'one' => q(US-Dollar \(Nächsten Dag\)),
				'other' => q(US-Dollar \(Nächsten Dag\)),
			},
		},
		'USS' => {
			display_name => {
				'currency' => q(US Dollar \(Selwechten Dag\)),
				'one' => q(US-Dollar \(Selwechten Dag\)),
				'other' => q(US-Dollar \(Selwechten Dag\)),
			},
		},
		'UYP' => {
			display_name => {
				'currency' => q(Uruguayesche Peso \(1975–1993\)),
				'one' => q(Uruguayesche Peso \(1975–1993\)),
				'other' => q(Uruguayesch Pesos \(1975–1993\)),
			},
		},
		'UYU' => {
			display_name => {
				'currency' => q(Uruguayesche Peso),
				'one' => q(Uruguayesche Peso),
				'other' => q(Uruguayesch Pesos),
			},
		},
		'UZS' => {
			display_name => {
				'currency' => q(Usbekistan-Sum),
				'one' => q(Usbekistan-Sum),
				'other' => q(Usbekistan-Sum),
			},
		},
		'VEB' => {
			display_name => {
				'currency' => q(Venezolanesche Bolívar \(1871–2008\)),
				'one' => q(Venezolanesche Bolívar \(1871–2008\)),
				'other' => q(Venezolanesch Bolívares \(1871–2008\)),
			},
		},
		'VEF' => {
			display_name => {
				'currency' => q(Venezolanesche Bolívar),
				'one' => q(Venezolanesche Bolívar),
				'other' => q(Venezolanesch Bolívares),
			},
		},
		'VND' => {
			symbol => '₫',
			display_name => {
				'currency' => q(Vietnameseschen Dong),
				'one' => q(Vietnameseschen Dong),
				'other' => q(Vietnamesesch Dong),
			},
		},
		'VUV' => {
			display_name => {
				'currency' => q(Vanuatu-Vatu),
				'one' => q(Vanuatu-Vatu),
				'other' => q(Vanuatu-Vatu),
			},
		},
		'WST' => {
			display_name => {
				'currency' => q(Samoaneschen Tala),
				'one' => q(Samoaneschen Tala),
				'other' => q(Samoanesch Tala),
			},
		},
		'XAF' => {
			symbol => 'FCFA',
			display_name => {
				'currency' => q(CFA-Frang \(BEAC\)),
				'one' => q(CFA-Frang \(BEAC\)),
				'other' => q(CFA-Frang \(BEAC\)),
			},
		},
		'XAG' => {
			display_name => {
				'currency' => q(Onze Sëlwer),
				'one' => q(Onz Sëlwer),
				'other' => q(Onze Sëlwer),
			},
		},
		'XAU' => {
			display_name => {
				'currency' => q(Onze Gold),
				'one' => q(Onz Gold),
				'other' => q(Onze Gold),
			},
		},
		'XBA' => {
			display_name => {
				'currency' => q(Europäesch Rechnungseenheet),
				'one' => q(Europäesch Rechnungseenheet),
				'other' => q(Europäesch Rechnungseenheeten),
			},
		},
		'XBB' => {
			display_name => {
				'currency' => q(Europäesch Währungseenheet \(XBB\)),
				'one' => q(Europäesch Währungseenheet \(XBB\)),
				'other' => q(Europäesch Währungseenheeten \(XBB\)),
			},
		},
		'XBC' => {
			display_name => {
				'currency' => q(Europäesch Rechnungseenheet \(XBC\)),
				'one' => q(Europäesch Rechnungseenheet \(XBC\)),
				'other' => q(Europäesch Rechnungseenheeten \(XBC\)),
			},
		},
		'XBD' => {
			display_name => {
				'currency' => q(Europäesch Rechnungseenheet \(XBD\)),
				'one' => q(Europäesch Rechnungseenheet \(XBD\)),
				'other' => q(Europäesch Rechnungseenheeten \(XBD\)),
			},
		},
		'XCD' => {
			symbol => 'EC$',
			display_name => {
				'currency' => q(Ostkaribeschen Dollar),
				'one' => q(Ostkaribeschen Dollar),
				'other' => q(Ostkaribesch Dollar),
			},
		},
		'XDR' => {
			display_name => {
				'currency' => q(Sonnerzéiungsrecht),
				'one' => q(Sonnerzéiungsrecht),
				'other' => q(Sonnerzéiungsrechter),
			},
		},
		'XEU' => {
			display_name => {
				'currency' => q(Europäesch Währungseenheet \(XEU\)),
				'one' => q(Europäesch Währungseenheet \(XEU\)),
				'other' => q(Europäesch Währungseenheeten \(XEU\)),
			},
		},
		'XFO' => {
			display_name => {
				'currency' => q(Franséische Gold-Frang),
				'one' => q(Franséische Gold-Frang),
				'other' => q(Franséisch Gold-Frang),
			},
		},
		'XFU' => {
			display_name => {
				'currency' => q(Franséischen UIC-Frang),
				'one' => q(Franséischen UIC-Frang),
				'other' => q(Franséisch UIC-Frang),
			},
		},
		'XOF' => {
			symbol => 'CFA',
			display_name => {
				'currency' => q(CFA-Frang \(BCEAO\)),
				'one' => q(CFA-Frang \(BCEAO\)),
				'other' => q(CFA-Frang \(BCEAO\)),
			},
		},
		'XPD' => {
			display_name => {
				'currency' => q(Onz Palladium),
				'one' => q(Onz Palladium),
				'other' => q(Onze Palladium),
			},
		},
		'XPF' => {
			symbol => 'CFPF',
			display_name => {
				'currency' => q(CFP-Frang),
				'one' => q(CFP-Frang),
				'other' => q(CFP-Frang),
			},
		},
		'XPT' => {
			display_name => {
				'currency' => q(Onz Platin),
				'one' => q(Onz Platin),
				'other' => q(Onze Platin),
			},
		},
		'XRE' => {
			display_name => {
				'currency' => q(RINET Funds),
				'one' => q(RINET Funds),
				'other' => q(RINET Funds),
			},
		},
		'XTS' => {
			display_name => {
				'currency' => q(Testwährung),
				'one' => q(Testwährung),
				'other' => q(Testwährung),
			},
		},
		'XXX' => {
			display_name => {
				'currency' => q(Onbekannt Währung),
				'one' => q(Onbekannt Währung),
				'other' => q(Onbekannt Währung),
			},
		},
		'YDD' => {
			display_name => {
				'currency' => q(Jemen-Dinar),
				'one' => q(Jemen-Dinar),
				'other' => q(Jemen-Dinaren),
			},
		},
		'YER' => {
			display_name => {
				'currency' => q(Jemen-Rial),
				'one' => q(Jemen-Rial),
				'other' => q(Jemen-Rial),
			},
		},
		'YUD' => {
			display_name => {
				'currency' => q(Jugoslaweschen Dinar \(1966–1990\)),
				'one' => q(Jugoslaweschen Dinar \(1966–1990\)),
				'other' => q(Jugoslawesch Dinaren \(1966–1990\)),
			},
		},
		'YUM' => {
			display_name => {
				'currency' => q(Jugoslaweschen Neien Dinar \(1994–2002\)),
				'one' => q(Jugoslaweschen Neien Dinar \(1994–2002\)),
				'other' => q(Jugoslawesch Nei Dinaren \(1994–2002\)),
			},
		},
		'YUN' => {
			display_name => {
				'currency' => q(Jugoslaweschen Dinar \(konvertibel\)),
				'one' => q(Jugoslaweschen Dinar \(konvertibel\)),
				'other' => q(Jugoslawesch Dinaren \(konvertibel\)),
			},
		},
		'ZAL' => {
			display_name => {
				'currency' => q(Südafrikanesche Rand \(Finanz\)),
				'one' => q(Südafrikanesche Rand \(Finanz\)),
				'other' => q(Südafrikaneschen Rand \(Finanz\)),
			},
		},
		'ZAR' => {
			display_name => {
				'currency' => q(Südafrikanesche Rand),
				'one' => q(Südafrikanesche Rand),
				'other' => q(Südafrikanesch Rand),
			},
		},
		'ZMK' => {
			display_name => {
				'currency' => q(Kwacha \(1968–2012\)),
				'one' => q(Kwacha \(1968–2012\)),
				'other' => q(Kwacha \(1968–2012\)),
			},
		},
		'ZMW' => {
			display_name => {
				'currency' => q(Kwacha),
				'one' => q(Kwacha),
				'other' => q(Kwacha),
			},
		},
		'ZRN' => {
			display_name => {
				'currency' => q(Zaire-Neien Zaïre \(1993–1998\)),
				'one' => q(Zaire-Neien Zaïre \(1993–1998\)),
				'other' => q(Zaire-Nei Zaïren \(1993–1998\)),
			},
		},
		'ZRZ' => {
			display_name => {
				'currency' => q(Zaire-Zaïre \(1971–1993\)),
				'one' => q(Zaire-Zaïre \(1971–1993\)),
				'other' => q(Zaire-Zaïren \(1971–1993\)),
			},
		},
		'ZWD' => {
			display_name => {
				'currency' => q(Simbabwe-Dollar \(1980–2008\)),
				'one' => q(Simbabwe-Dollar \(1980–2008\)),
				'other' => q(Simbabwe-Dollar \(1980–2008\)),
			},
		},
		'ZWL' => {
			display_name => {
				'currency' => q(Simbabwe-Dollar \(2009\)),
				'one' => q(Simbabwe-Dollar \(2009\)),
				'other' => q(Simbabwe-Dollar \(2009\)),
			},
		},
		'ZWR' => {
			display_name => {
				'currency' => q(Simbabwe-Dollar \(2008\)),
				'one' => q(Simbabwe-Dollar \(2008\)),
				'other' => q(Simbabwe-Dollar \(2008\)),
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
							'Jan.',
							'Feb.',
							'Mäe.',
							'Abr.',
							'Mee',
							'Juni',
							'Juli',
							'Aug.',
							'Sep.',
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
							'Januar',
							'Februar',
							'Mäerz',
							'Abrëll',
							'Mee',
							'Juni',
							'Juli',
							'August',
							'September',
							'Oktober',
							'November',
							'Dezember'
						],
						leap => [
							
						],
					},
				},
				'stand-alone' => {
					abbreviated => {
						nonleap => [
							'Jan',
							'Feb',
							'Mäe',
							'Abr',
							'Mee',
							'Jun',
							'Jul',
							'Aug',
							'Sep',
							'Okt',
							'Nov',
							'Dez'
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
							'Januar',
							'Februar',
							'Mäerz',
							'Abrëll',
							'Mee',
							'Juni',
							'Juli',
							'August',
							'September',
							'Oktober',
							'November',
							'Dezember'
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
						mon => 'Méi.',
						tue => 'Dën.',
						wed => 'Mët.',
						thu => 'Don.',
						fri => 'Fre.',
						sat => 'Sam.',
						sun => 'Son.'
					},
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
						mon => 'Mé.',
						tue => 'Dë.',
						wed => 'Më.',
						thu => 'Do.',
						fri => 'Fr.',
						sat => 'Sa.',
						sun => 'So.'
					},
					wide => {
						mon => 'Méindeg',
						tue => 'Dënschdeg',
						wed => 'Mëttwoch',
						thu => 'Donneschdeg',
						fri => 'Freideg',
						sat => 'Samschdeg',
						sun => 'Sonndeg'
					},
				},
				'stand-alone' => {
					abbreviated => {
						mon => 'Méi',
						tue => 'Dën',
						wed => 'Mët',
						thu => 'Don',
						fri => 'Fre',
						sat => 'Sam',
						sun => 'Son'
					},
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
						mon => 'Mé.',
						tue => 'Dë.',
						wed => 'Më.',
						thu => 'Do.',
						fri => 'Fr.',
						sat => 'Sa.',
						sun => 'So.'
					},
					wide => {
						mon => 'Méindeg',
						tue => 'Dënschdeg',
						wed => 'Mëttwoch',
						thu => 'Donneschdeg',
						fri => 'Freideg',
						sat => 'Samschdeg',
						sun => 'Sonndeg'
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
					wide => {0 => '1. Quartal',
						1 => '2. Quartal',
						2 => '3. Quartal',
						3 => '4. Quartal'
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
					wide => {0 => '1. Quartal',
						1 => '2. Quartal',
						2 => '3. Quartal',
						3 => '4. Quartal'
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
				'wide' => {
					'am' => q{moies},
					'pm' => q{nomëttes},
				},
				'narrow' => {
					'am' => q{mo.},
					'pm' => q{nomë.},
				},
				'abbreviated' => {
					'pm' => q{nomëttes},
					'am' => q{moies},
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
				'0' => 'BE'
			},
		},
		'chinese' => {
		},
		'dangi' => {
		},
		'generic' => {
		},
		'gregorian' => {
			abbreviated => {
				'0' => 'v. Chr.',
				'1' => 'n. Chr.'
			},
			wide => {
				'0' => 'v. Chr.',
				'1' => 'n. Chr.'
			},
		},
		'hebrew' => {
			abbreviated => {
				'0' => 'AM'
			},
		},
		'islamic' => {
			abbreviated => {
				'0' => 'AH'
			},
		},
		'japanese' => {
		},
		'roc' => {
			abbreviated => {
				'0' => 'Before R.O.C.',
				'1' => 'Minguo'
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
			'full' => q{EEEE, d. MMMM U},
			'long' => q{d. MMMM U},
			'medium' => q{dd.MM U},
			'short' => q{dd.MM.yy},
		},
		'dangi' => {
		},
		'generic' => {
			'full' => q{EEEE, d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{dd.MM.y G},
			'short' => q{dd.MM.yy GGGGG},
		},
		'gregorian' => {
			'full' => q{EEEE, d. MMMM y},
			'long' => q{d. MMMM y},
			'medium' => q{d. MMM y},
			'short' => q{dd.MM.yy},
		},
		'hebrew' => {
		},
		'islamic' => {
		},
		'japanese' => {
			'full' => q{EEEE, d. MMMM y G},
			'long' => q{d. MMMM y G},
			'medium' => q{dd.MM.y G},
			'short' => q{dd.MM.yy GGGGG},
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
		'dangi' => {
		},
		'generic' => {
		},
		'gregorian' => {
			'full' => q{HH:mm:ss zzzz},
			'long' => q{HH:mm:ss z},
			'medium' => q{HH:mm:ss},
			'short' => q{HH:mm},
		},
		'hebrew' => {
		},
		'islamic' => {
		},
		'japanese' => {
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
		'dangi' => {
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
		'hebrew' => {
		},
		'islamic' => {
		},
		'japanese' => {
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
		'gregorian' => {
			E => q{ccc},
			EHm => q{E, HH:mm},
			EHms => q{E, HH:mm:ss},
			Ed => q{E, d.},
			Ehm => q{E, h:mm a},
			Ehms => q{E, h:mm:ss a},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			H => q{HH 'Auer'},
			Hm => q{HH:mm},
			Hms => q{HH:mm:ss},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			d => q{d},
			h => q{h a},
			hm => q{h:mm a},
			hms => q{h:mm:ss a},
			ms => q{mm:ss},
			y => q{y},
			yM => q{M.y},
			yMEd => q{E, d.M.y},
			yMMM => q{MMM y},
			yMMMEd => q{E, d. MMM y},
			yMMMd => q{d. MMM y},
			yMd => q{d.M.y},
			yQQQ => q{QQQ y},
			yQQQQ => q{QQQQ y},
		},
		'generic' => {
			Ed => q{E, d.},
			Gy => q{y G},
			GyMMM => q{MMM y G},
			GyMMMEd => q{E, d. MMM y G},
			GyMMMd => q{d. MMM y G},
			M => q{L},
			MEd => q{E, d.M.},
			MMM => q{LLL},
			MMMEd => q{E, d. MMM},
			MMMd => q{d. MMM},
			Md => q{d.M.},
			d => q{d},
			y => q{y G},
			yyyy => q{y G},
			yyyyM => q{M.y GGGGG},
			yyyyMEd => q{E, d.M.y GGGGG},
			yyyyMMM => q{MMM y G},
			yyyyMMMEd => q{E, d. MMM y G},
			yyyyMMMd => q{d. MMM y G},
			yyyyMd => q{d.M.y GGGGG},
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
				H => q{HH–HH 'Auer'},
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
				H => q{HH–HH 'Auer' v},
			},
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, dd.MM. – E, dd.MM.},
				d => q{E, dd.MM. – E, dd.MM.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM. – dd.MM.},
				d => q{dd.MM. – dd.MM.},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0} - {1}',
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
				M => q{E, dd.MM.y – E, dd.MM.y},
				d => q{E, dd.MM.y – E, dd.MM.y},
				y => q{E, dd.MM.y – E, dd.MM.y},
			},
			yMMM => {
				M => q{MMM–MMM y},
				y => q{MMM y – MMM y},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y},
				d => q{E, d. – E, d. MMM y},
				y => q{E, d. MMM y – E, d. MMM y},
			},
			yMMMM => {
				M => q{MMMM–MMMM y},
				y => q{MMMM y – MMMM y},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y},
				d => q{d.–d. MMM y},
				y => q{d. MMM y – d. MMM y},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y},
				d => q{dd.MM.y – dd.MM.y},
				y => q{dd.MM.y – dd.MM.y},
			},
		},
		'generic' => {
			M => {
				M => q{M.–M.},
			},
			MEd => {
				M => q{E, dd.MM. – E, dd.MM.},
				d => q{E, dd.MM. – E, dd.MM.},
			},
			MMM => {
				M => q{MMM–MMM},
			},
			MMMEd => {
				M => q{E, d. MMM – E, d. MMM},
				d => q{E, d. – E, d. MMM},
			},
			MMMd => {
				M => q{d. MMM – d. MMM},
				d => q{d.–d. MMM},
			},
			Md => {
				M => q{dd.MM. – dd.MM.},
				d => q{dd.MM. – dd.MM.},
			},
			d => {
				d => q{d.–d.},
			},
			fallback => '{0} - {1}',
			y => {
				y => q{y–y G},
			},
			yM => {
				M => q{MM.y – MM.y G},
				y => q{MM.y – MM.y G},
			},
			yMEd => {
				M => q{E, dd.MM.y – E, dd.MM.y G},
				d => q{E, dd.MM.y – E, dd.MM.y G},
				y => q{E, dd.MM.y – E, dd.MM.y G},
			},
			yMMM => {
				M => q{MMM–MMM y G},
				y => q{MMM y – MMM y G},
			},
			yMMMEd => {
				M => q{E, d. MMM – E, d. MMM y G},
				d => q{E, d. – E, d. MMM y G},
				y => q{E, d. MMM y – E, d. MMM y G},
			},
			yMMMM => {
				M => q{MMMM–MMMM y G},
				y => q{MMMM y – MMMM y G},
			},
			yMMMd => {
				M => q{d. MMM – d. MMM y G},
				d => q{d.–d. MMM y G},
				y => q{d. MMM y – d. MMM y G},
			},
			yMd => {
				M => q{dd.MM.y – dd.MM.y G},
				d => q{dd.MM.y – dd.MM.y G},
				y => q{dd.MM.y – dd.MM.y G},
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
			'zodiacs' => {
				'format' => {
					'abbreviated' => {
						0 => q(Rat),
						1 => q(Ochs),
						2 => q(Tiger),
						3 => q(Kannéngchen),
						4 => q(Draach),
						5 => q(Schlaang),
						6 => q(Päerd),
						7 => q(Geess),
						8 => q(Af),
						9 => q(Hong),
						10 => q(Hond),
						11 => q(Schwäin),
					},
				},
			},
		},
		'dangi' => {
			'zodiacs' => {
				'format' => {
					'abbreviated' => {
						0 => q(Rat),
						1 => q(Ochs),
						2 => q(Tiger),
						3 => q(Kannéngchen),
						4 => q(Draach),
						5 => q(Schlaang),
						6 => q(Päerd),
						7 => q(Geess),
						8 => q(Af),
						9 => q(Hong),
						10 => q(Hond),
						11 => q(Schwäin),
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
		hourFormat => q(+HH:mm;-HH:mm),
		gmtFormat => q(GMT{0}),
		gmtZeroFormat => q(GMT),
		regionFormat => q({0} Zäit),
		regionFormat => q({0} Summerzäit),
		regionFormat => q({0} Normalzäit),
		fallbackFormat => q({1} ({0})),
		'Acre' => {
			long => {
				'daylight' => q#Acre-Summerzäit#,
				'generic' => q#Acre-Zäit#,
				'standard' => q#Acre-Normalzäit#,
			},
		},
		'Afghanistan' => {
			long => {
				'standard' => q#Afghanistan-Zäit#,
			},
		},
		'Africa/Accra' => {
			exemplarCity => q#Accra#,
		},
		'Africa/Addis_Ababa' => {
			exemplarCity => q#Addis Abeba#,
		},
		'Africa/Algiers' => {
			exemplarCity => q#Alger#,
		},
		'Africa/Asmera' => {
			exemplarCity => q#Asmara#,
		},
		'Africa/Cairo' => {
			exemplarCity => q#Kairo#,
		},
		'Africa/Dar_es_Salaam' => {
			exemplarCity => q#Dar es Salaam#,
		},
		'Africa/Djibouti' => {
			exemplarCity => q#Dschibuti#,
		},
		'Africa/El_Aaiun' => {
			exemplarCity => q#El Aaiún#,
		},
		'Africa/Khartoum' => {
			exemplarCity => q#Khartum#,
		},
		'Africa/Mogadishu' => {
			exemplarCity => q#Mogadischu#,
		},
		'Africa/Ouagadougou' => {
			exemplarCity => q#Wagadugu#,
		},
		'Africa/Sao_Tome' => {
			exemplarCity => q#São Tomé#,
		},
		'Africa/Tripoli' => {
			exemplarCity => q#Tripoli#,
		},
		'Africa_Central' => {
			long => {
				'standard' => q#Zentralafrikanesch Zäit#,
			},
		},
		'Africa_Eastern' => {
			long => {
				'standard' => q#Ostafrikanesch Zäit#,
			},
		},
		'Africa_Southern' => {
			long => {
				'standard' => q#Südafrikanesch Zäit#,
			},
		},
		'Africa_Western' => {
			long => {
				'daylight' => q#Westafrikanesch Summerzäit#,
				'generic' => q#Westafrikanesch Zäit#,
				'standard' => q#Westafrikanesch Normalzäit#,
			},
		},
		'Alaska' => {
			long => {
				'daylight' => q#Alaska-Summerzäit#,
				'generic' => q#Alaska-Zäit#,
				'standard' => q#Alaska-Normalzäit#,
			},
		},
		'Almaty' => {
			long => {
				'daylight' => q#Almaty-Summerzäit#,
				'generic' => q#Almaty-Zäit#,
				'standard' => q#Almaty-Normalzäit#,
			},
		},
		'Amazon' => {
			long => {
				'daylight' => q#Amazonas-Summerzäit#,
				'generic' => q#Amazonas-Zäit#,
				'standard' => q#Amazonas-Normalzäit#,
			},
		},
		'America/Asuncion' => {
			exemplarCity => q#Asunción#,
		},
		'America/Cayman' => {
			exemplarCity => q#Kaimaninselen#,
		},
		'America/Coral_Harbour' => {
			exemplarCity => q#Atikokan#,
		},
		'America/Curacao' => {
			exemplarCity => q#Curaçao#,
		},
		'America/El_Salvador' => {
			exemplarCity => q#Salvador#,
		},
		'America/Havana' => {
			exemplarCity => q#Havanna#,
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
		'America/Jamaica' => {
			exemplarCity => q#Jamaika#,
		},
		'America/Kentucky/Monticello' => {
			exemplarCity => q#Monticello, Kentucky#,
		},
		'America/Lower_Princes' => {
			exemplarCity => q#Lower Prince’s Quarter#,
		},
		'America/Mexico_City' => {
			exemplarCity => q#Mexiko-Stad#,
		},
		'America/North_Dakota/Beulah' => {
			exemplarCity => q#Beulah, North Dakota#,
		},
		'America/North_Dakota/Center' => {
			exemplarCity => q#Center, North Dakota#,
		},
		'America/North_Dakota/New_Salem' => {
			exemplarCity => q#New Salem, North Dakota#,
		},
		'America/Port_of_Spain' => {
			exemplarCity => q#Port-of-Spain#,
		},
		'America/St_Barthelemy' => {
			exemplarCity => q#Saint-Barthélemy#,
		},
		'America/St_Johns' => {
			exemplarCity => q#St. John’s#,
		},
		'America/St_Kitts' => {
			exemplarCity => q#St. Kitts#,
		},
		'America/St_Lucia' => {
			exemplarCity => q#St. Lucia#,
		},
		'America/St_Thomas' => {
			exemplarCity => q#St. Thomas#,
		},
		'America/St_Vincent' => {
			exemplarCity => q#St. Vincent#,
		},
		'America_Central' => {
			long => {
				'daylight' => q#Nordamerikanesch Inland-Summerzäit#,
				'generic' => q#Nordamerikanesch Inlandzäit#,
				'standard' => q#Nordamerikanesch Inland-Normalzäit#,
			},
		},
		'America_Eastern' => {
			long => {
				'daylight' => q#Nordamerikanesch Ostküsten-Summerzäit#,
				'generic' => q#Nordamerikanesch Ostküstenzäit#,
				'standard' => q#Nordamerikanesch Ostküsten-Normalzäit#,
			},
		},
		'America_Mountain' => {
			long => {
				'daylight' => q#Rocky-Mountain-Summerzäit#,
				'generic' => q#Rocky-Mountain-Zäit#,
				'standard' => q#Rocky-Mountain-Normalzäit#,
			},
		},
		'America_Pacific' => {
			long => {
				'daylight' => q#Nordamerikanesch Westküsten-Summerzäit#,
				'generic' => q#Nordamerikanesch Westküstenzäit#,
				'standard' => q#Nordamerikanesch Westküsten-Normalzäit#,
			},
		},
		'Anadyr' => {
			long => {
				'daylight' => q#Anadyr-Summerzäit#,
				'generic' => q#Anadyr-Zäit#,
				'standard' => q#Anadyr-Normalzäit#,
			},
		},
		'Antarctica/DumontDUrville' => {
			exemplarCity => q#Dumont d’Urville#,
		},
		'Antarctica/Vostok' => {
			exemplarCity => q#Wostok#,
		},
		'Arabian' => {
			long => {
				'daylight' => q#Arabesch Summerzäit#,
				'generic' => q#Arabesch Zäit#,
				'standard' => q#Arabesch Normalzäit#,
			},
		},
		'Argentina' => {
			long => {
				'daylight' => q#Argentinesch Summerzäit#,
				'generic' => q#Argentinesch Zäit#,
				'standard' => q#Argentinesch Normalzäit#,
			},
		},
		'Argentina_Western' => {
			long => {
				'daylight' => q#Westargentinesch Summerzäit#,
				'generic' => q#Westargentinesch Zäit#,
				'standard' => q#Westargentinesch Normalzäit#,
			},
		},
		'Armenia' => {
			long => {
				'daylight' => q#Armenesch Summerzäit#,
				'generic' => q#Armenesch Zäit#,
				'standard' => q#Armenesch Normalzäit#,
			},
		},
		'Asia/Aqtobe' => {
			exemplarCity => q#Aqtöbe#,
		},
		'Asia/Baghdad' => {
			exemplarCity => q#Bagdad#,
		},
		'Asia/Bishkek' => {
			exemplarCity => q#Bischkek#,
		},
		'Asia/Calcutta' => {
			exemplarCity => q#Kalkutta#,
		},
		'Asia/Damascus' => {
			exemplarCity => q#Damaskus#,
		},
		'Asia/Dushanbe' => {
			exemplarCity => q#Duschanbe#,
		},
		'Asia/Hong_Kong' => {
			exemplarCity => q#Hong Kong#,
		},
		'Asia/Jayapura' => {
			exemplarCity => q#Port Numbay#,
		},
		'Asia/Kamchatka' => {
			exemplarCity => q#Kamtschatka#,
		},
		'Asia/Katmandu' => {
			exemplarCity => q#Kathmandu#,
		},
		'Asia/Krasnoyarsk' => {
			exemplarCity => q#Krasnojarsk#,
		},
		'Asia/Macau' => {
			exemplarCity => q#Macau#,
		},
		'Asia/Muscat' => {
			exemplarCity => q#Muskat#,
		},
		'Asia/Nicosia' => {
			exemplarCity => q#Nikosia#,
		},
		'Asia/Novosibirsk' => {
			exemplarCity => q#Nowosibirsk#,
		},
		'Asia/Pyongyang' => {
			exemplarCity => q#Pjöngjang#,
		},
		'Asia/Qatar' => {
			exemplarCity => q#Katar#,
		},
		'Asia/Riyadh' => {
			exemplarCity => q#Riad#,
		},
		'Asia/Saigon' => {
			exemplarCity => q#Ho-Chi-Minh-Stad#,
		},
		'Asia/Sakhalin' => {
			exemplarCity => q#Sachalin#,
		},
		'Asia/Singapore' => {
			exemplarCity => q#Singapur#,
		},
		'Asia/Taipei' => {
			exemplarCity => q#Taipeh#,
		},
		'Asia/Tashkent' => {
			exemplarCity => q#Taschkent#,
		},
		'Asia/Tbilisi' => {
			exemplarCity => q#Tiflis#,
		},
		'Asia/Tehran' => {
			exemplarCity => q#Teheran#,
		},
		'Asia/Tokyo' => {
			exemplarCity => q#Tokio#,
		},
		'Asia/Vladivostok' => {
			exemplarCity => q#Wladiwostok#,
		},
		'Asia/Yakutsk' => {
			exemplarCity => q#Jakutsk#,
		},
		'Asia/Yekaterinburg' => {
			exemplarCity => q#Jekaterinbuerg#,
		},
		'Asia/Yerevan' => {
			exemplarCity => q#Erivan#,
		},
		'Atlantic' => {
			long => {
				'daylight' => q#Atlantik-Summerzäit#,
				'generic' => q#Atlantik-Zäit#,
				'standard' => q#Atlantik-Normalzäit#,
			},
		},
		'Atlantic/Azores' => {
			exemplarCity => q#Azoren#,
		},
		'Atlantic/Bermuda' => {
			exemplarCity => q#Bermudas#,
		},
		'Atlantic/Canary' => {
			exemplarCity => q#Kanaresch Inselen#,
		},
		'Atlantic/Cape_Verde' => {
			exemplarCity => q#Kap Verde#,
		},
		'Atlantic/Faeroe' => {
			exemplarCity => q#Färöer#,
		},
		'Atlantic/South_Georgia' => {
			exemplarCity => q#Südgeorgien#,
		},
		'Atlantic/St_Helena' => {
			exemplarCity => q#St. Helena#,
		},
		'Australia_Central' => {
			long => {
				'daylight' => q#Zentralaustralesch Summerzäit#,
				'generic' => q#Zentralaustralesch Zäit#,
				'standard' => q#Zentralaustralesch Normalzäit#,
			},
		},
		'Australia_CentralWestern' => {
			long => {
				'daylight' => q#Zentral-/Westaustralesch Summerzäit#,
				'generic' => q#Zentral-/Westaustralesch Zäit#,
				'standard' => q#Zentral-/Westaustralesch Normalzäit#,
			},
		},
		'Australia_Eastern' => {
			long => {
				'daylight' => q#Ostaustralesch Summerzäit#,
				'generic' => q#Ostaustralesch Zäit#,
				'standard' => q#Ostaustralesch Normalzäit#,
			},
		},
		'Australia_Western' => {
			long => {
				'daylight' => q#Westaustralesch Summerzäit#,
				'generic' => q#Westaustralesch Zäit#,
				'standard' => q#Westaustralesch Normalzäit#,
			},
		},
		'Azerbaijan' => {
			long => {
				'daylight' => q#Aserbaidschanesch Summerzäit#,
				'generic' => q#Aserbaidschanesch Zäit#,
				'standard' => q#Aserbeidschanesch Normalzäit#,
			},
		},
		'Azores' => {
			long => {
				'daylight' => q#Azoren-Summerzäit#,
				'generic' => q#Azoren-Zäit#,
				'standard' => q#Azoren-Normalzäit#,
			},
		},
		'Bangladesh' => {
			long => {
				'daylight' => q#Bangladesch-Summerzäit#,
				'generic' => q#Bangladesch-Zäit#,
				'standard' => q#Bangladesch-Normalzäit#,
			},
		},
		'Bhutan' => {
			long => {
				'standard' => q#Bhutan-Zäit#,
			},
		},
		'Bolivia' => {
			long => {
				'standard' => q#Bolivianesch Zäit#,
			},
		},
		'Brasilia' => {
			long => {
				'daylight' => q#Brasília-Summerzäit#,
				'generic' => q#Brasília-Zäit#,
				'standard' => q#Brasília-Normalzäit#,
			},
		},
		'Brunei' => {
			long => {
				'standard' => q#Brunei-Zäit#,
			},
		},
		'Cape_Verde' => {
			long => {
				'daylight' => q#Kap-Verde-Summerzäit#,
				'generic' => q#Kap-Verde-Zäit#,
				'standard' => q#Kap-Verde-Normalzäit#,
			},
		},
		'Chamorro' => {
			long => {
				'standard' => q#Chamorro-Zäit#,
			},
		},
		'Chatham' => {
			long => {
				'daylight' => q#Chatham-Summerzäit#,
				'generic' => q#Chatham-Zäit#,
				'standard' => q#Chatham-Normalzäit#,
			},
		},
		'Chile' => {
			long => {
				'daylight' => q#Chilenesch Summerzäit#,
				'generic' => q#Chilenesch Zäit#,
				'standard' => q#Chilenesch Normalzäit#,
			},
		},
		'China' => {
			long => {
				'daylight' => q#Chinesesch Summerzäit#,
				'generic' => q#Chinesesch Zäit#,
				'standard' => q#Chinesesch Normalzäit#,
			},
		},
		'Choibalsan' => {
			long => {
				'daylight' => q#Choibalsan-Summerzäit#,
				'generic' => q#Choibalsan-Zäit#,
				'standard' => q#Choibalsan-Normalzäit#,
			},
		},
		'Christmas' => {
			long => {
				'standard' => q#Chrëschtdagsinsel-Zäit#,
			},
		},
		'Cocos' => {
			long => {
				'standard' => q#Kokosinselen-Zäit#,
			},
		},
		'Colombia' => {
			long => {
				'daylight' => q#Kolumbianesch Summerzäit#,
				'generic' => q#Kolumbianesch Zäit#,
				'standard' => q#Kolumbianesch Normalzäit#,
			},
		},
		'Cook' => {
			long => {
				'daylight' => q#Cookinselen-Summerzäit#,
				'generic' => q#Cookinselen-Zäit#,
				'standard' => q#Cookinselen-Normalzäit#,
			},
		},
		'Cuba' => {
			long => {
				'daylight' => q#Kubanesch Summerzäit#,
				'generic' => q#Kubanesch Zäit#,
				'standard' => q#Kubanesch Normalzäit#,
			},
		},
		'Davis' => {
			long => {
				'standard' => q#Davis-Zäit#,
			},
		},
		'DumontDUrville' => {
			long => {
				'standard' => q#Dumont-d’Urville-Zäit#,
			},
		},
		'East_Timor' => {
			long => {
				'standard' => q#Osttimor-Zäit#,
			},
		},
		'Easter' => {
			long => {
				'daylight' => q#Ouschterinsel-Summerzäit#,
				'generic' => q#Ouschterinsel-Zäit#,
				'standard' => q#Ouschterinsel-Normalzäit#,
			},
		},
		'Ecuador' => {
			long => {
				'standard' => q#Ecuadorianesch Zäit#,
			},
		},
		'Etc/Unknown' => {
			exemplarCity => q#Onbekannt#,
		},
		'Europe/Athens' => {
			exemplarCity => q#Athen#,
		},
		'Europe/Belgrade' => {
			exemplarCity => q#Belgrad#,
		},
		'Europe/Brussels' => {
			exemplarCity => q#Bréissel#,
		},
		'Europe/Bucharest' => {
			exemplarCity => q#Bukarest#,
		},
		'Europe/Chisinau' => {
			exemplarCity => q#Kischinau#,
		},
		'Europe/Copenhagen' => {
			exemplarCity => q#Kopenhagen#,
		},
		'Europe/Dublin' => {
			long => {
				'daylight' => q#Iresch Summerzäit#,
			},
		},
		'Europe/Kiev' => {
			exemplarCity => q#Kiew#,
		},
		'Europe/Lisbon' => {
			exemplarCity => q#Lissabon#,
		},
		'Europe/London' => {
			long => {
				'daylight' => q#Britesch Summerzäit#,
			},
		},
		'Europe/Luxembourg' => {
			exemplarCity => q#Lëtzebuerg#,
		},
		'Europe/Moscow' => {
			exemplarCity => q#Moskau#,
		},
		'Europe/Prague' => {
			exemplarCity => q#Prag#,
		},
		'Europe/Rome' => {
			exemplarCity => q#Roum#,
		},
		'Europe/Tirane' => {
			exemplarCity => q#Tirana#,
		},
		'Europe/Uzhgorod' => {
			exemplarCity => q#Uschgorod#,
		},
		'Europe/Vatican' => {
			exemplarCity => q#Vatikan#,
		},
		'Europe/Vienna' => {
			exemplarCity => q#Wien#,
		},
		'Europe/Vilnius' => {
			exemplarCity => q#Wilna#,
		},
		'Europe/Volgograd' => {
			exemplarCity => q#Wolgograd#,
		},
		'Europe/Warsaw' => {
			exemplarCity => q#Warschau#,
		},
		'Europe/Zaporozhye' => {
			exemplarCity => q#Saporischschja#,
		},
		'Europe/Zurich' => {
			exemplarCity => q#Zürech#,
		},
		'Europe_Central' => {
			long => {
				'daylight' => q#Mëtteleuropäesch Summerzäit#,
				'generic' => q#Mëtteleuropäesch Zäit#,
				'standard' => q#Mëtteleuropäesch Normalzäit#,
			},
		},
		'Europe_Eastern' => {
			long => {
				'daylight' => q#Osteuropäesch Summerzäit#,
				'generic' => q#Osteuropäesch Zäit#,
				'standard' => q#Osteuropäesch Normalzäit#,
			},
		},
		'Europe_Western' => {
			long => {
				'daylight' => q#Westeuropäesch Summerzäit#,
				'generic' => q#Westeuropäesch Zäit#,
				'standard' => q#Westeuropäesch Normalzäit#,
			},
		},
		'Falkland' => {
			long => {
				'daylight' => q#Falklandinselen-Summerzäit#,
				'generic' => q#Falklandinselen-Zäit#,
				'standard' => q#Falklandinselen-Normalzäit#,
			},
		},
		'Fiji' => {
			long => {
				'daylight' => q#Fidschi-Summerzäit#,
				'generic' => q#Fidschi-Zäit#,
				'standard' => q#Fidschi-Normalzäit#,
			},
		},
		'French_Guiana' => {
			long => {
				'standard' => q#Franséisch-Guayane-Zäit#,
			},
		},
		'French_Southern' => {
			long => {
				'standard' => q#Franséisch Süd- an Antarktisgebidder-Zäit#,
			},
		},
		'GMT' => {
			long => {
				'standard' => q#Mëttler Greenwich-Zäit#,
			},
		},
		'Galapagos' => {
			long => {
				'standard' => q#Galapagos-Zäit#,
			},
		},
		'Gambier' => {
			long => {
				'standard' => q#Gambier-Zäit#,
			},
		},
		'Georgia' => {
			long => {
				'daylight' => q#Georgesch Summerzäit#,
				'generic' => q#Georgesch Zäit#,
				'standard' => q#Georgesch Normalzäit#,
			},
		},
		'Gilbert_Islands' => {
			long => {
				'standard' => q#Gilbert-Inselen-Zäit#,
			},
		},
		'Greenland_Eastern' => {
			long => {
				'daylight' => q#Ostgrönland-Summerzäit#,
				'generic' => q#Ostgrönland-Zäit#,
				'standard' => q#Ostgrönland-Normalzäit#,
			},
		},
		'Greenland_Western' => {
			long => {
				'daylight' => q#Westgrönland-Summerzäit#,
				'generic' => q#Westgrönland-Zäit#,
				'standard' => q#Westgrönland-Normalzäit#,
			},
		},
		'Guam' => {
			long => {
				'standard' => q#Guam-Zäit#,
			},
		},
		'Gulf' => {
			long => {
				'standard' => q#Golf-Zäit#,
			},
		},
		'Guyana' => {
			long => {
				'standard' => q#Guyana-Zäit#,
			},
		},
		'Hawaii_Aleutian' => {
			long => {
				'daylight' => q#Hawaii-Aleuten-Summerzäit#,
				'generic' => q#Hawaii-Aleuten-Zäit#,
				'standard' => q#Hawaii-Aleuten-Normalzäit#,
			},
		},
		'Hong_Kong' => {
			long => {
				'daylight' => q#Hong-Kong-Summerzäit#,
				'generic' => q#Hong-Kong-Zäit#,
				'standard' => q#Hong-Kong-Normalzäit#,
			},
		},
		'Hovd' => {
			long => {
				'daylight' => q#Hovd-Summerzäit#,
				'generic' => q#Hovd-Zäit#,
				'standard' => q#Hovd-Normalzäit#,
			},
		},
		'India' => {
			long => {
				'standard' => q#Indesch Zäit#,
			},
		},
		'Indian/Christmas' => {
			exemplarCity => q#Chrëschtdagsinsel#,
		},
		'Indian/Comoro' => {
			exemplarCity => q#Komoren#,
		},
		'Indian/Maldives' => {
			exemplarCity => q#Maldiven#,
		},
		'Indian/Reunion' => {
			exemplarCity => q#Réunion#,
		},
		'Indian_Ocean' => {
			long => {
				'standard' => q#Indeschen Ozean-Zäit#,
			},
		},
		'Indochina' => {
			long => {
				'standard' => q#Indochina-Zäit#,
			},
		},
		'Indonesia_Central' => {
			long => {
				'standard' => q#Zentralindonesesch Zäit#,
			},
		},
		'Indonesia_Eastern' => {
			long => {
				'standard' => q#Ostindonesesch Zäit#,
			},
		},
		'Indonesia_Western' => {
			long => {
				'standard' => q#Westindonesesch Zäit#,
			},
		},
		'Iran' => {
			long => {
				'daylight' => q#Iranesch Summerzäit#,
				'generic' => q#Iranesch Zäit#,
				'standard' => q#Iranesch Normalzäit#,
			},
		},
		'Irkutsk' => {
			long => {
				'daylight' => q#Irkutsk-Summerzäit#,
				'generic' => q#Irkutsk-Zäit#,
				'standard' => q#Irkutsk-Normalzäit#,
			},
		},
		'Israel' => {
			long => {
				'daylight' => q#Israelesch Summerzäit#,
				'generic' => q#Israelesch Zäit#,
				'standard' => q#Israelesch Normalzäit#,
			},
		},
		'Japan' => {
			long => {
				'daylight' => q#Japanesch Summerzäit#,
				'generic' => q#Japanesch Zäit#,
				'standard' => q#Japanesch Normalzäit#,
			},
		},
		'Kamchatka' => {
			long => {
				'daylight' => q#Kamtschatka-Summerzäit#,
				'generic' => q#Kamtschatka-Zäit#,
				'standard' => q#Kamtschatka-Normalzäit#,
			},
		},
		'Kazakhstan_Eastern' => {
			long => {
				'standard' => q#Ostkasachesch Zäit#,
			},
		},
		'Kazakhstan_Western' => {
			long => {
				'standard' => q#Westkasachesch Zäit#,
			},
		},
		'Korea' => {
			long => {
				'daylight' => q#Koreanesch Summerzäit#,
				'generic' => q#Koreanesch Zäit#,
				'standard' => q#Koreanesch Normalzäit#,
			},
		},
		'Kosrae' => {
			long => {
				'standard' => q#Kosrae-Zäit#,
			},
		},
		'Krasnoyarsk' => {
			long => {
				'daylight' => q#Krasnojarsk-Summerzäit#,
				'generic' => q#Krasnojarsk-Zäit#,
				'standard' => q#Krasnojarsk-Normalzäit#,
			},
		},
		'Kyrgystan' => {
			long => {
				'standard' => q#Kirgisistan-Zäit#,
			},
		},
		'Line_Islands' => {
			long => {
				'standard' => q#Linneninselen-Zäit#,
			},
		},
		'Lord_Howe' => {
			long => {
				'daylight' => q#Lord-Howe-Summerzäit#,
				'generic' => q#Lord-Howe-Zäit#,
				'standard' => q#Lord-Howe-Normalzäit#,
			},
		},
		'Macquarie' => {
			long => {
				'standard' => q#Macquarieinsel-Zäit#,
			},
		},
		'Magadan' => {
			long => {
				'daylight' => q#Magadan-Summerzäit#,
				'generic' => q#Magadan-Zäit#,
				'standard' => q#Magadan-Normalzäit#,
			},
		},
		'Malaysia' => {
			long => {
				'standard' => q#Malaysesch Zäit#,
			},
		},
		'Maldives' => {
			long => {
				'standard' => q#Maldiven-Zäit#,
			},
		},
		'Marquesas' => {
			long => {
				'standard' => q#Marquesas-Zäit#,
			},
		},
		'Marshall_Islands' => {
			long => {
				'standard' => q#Marshallinselen-Zäit#,
			},
		},
		'Mauritius' => {
			long => {
				'daylight' => q#Mauritius-Summerzäit#,
				'generic' => q#Mauritius-Zäit#,
				'standard' => q#Mauritius-Normalzäit#,
			},
		},
		'Mawson' => {
			long => {
				'standard' => q#Mawson-Zäit#,
			},
		},
		'Mexico_Northwest' => {
			long => {
				'daylight' => q#Nordwest-Mexiko-Summerzäit#,
				'generic' => q#Nordwest-Mexiko-Zäit#,
				'standard' => q#Nordwest-Mexiko-Normalzäit#,
			},
		},
		'Mexico_Pacific' => {
			long => {
				'daylight' => q#Mexikanesch Pazifik-Summerzäit#,
				'generic' => q#Mexikanesch Pazifikzäit#,
				'standard' => q#Mexikanesch Pazifik-Normalzäit#,
			},
		},
		'Mongolia' => {
			long => {
				'daylight' => q#Ulaanbaatar-Summerzäit#,
				'generic' => q#Ulaanbaatar-Zäit#,
				'standard' => q#Ulaanbaatar-Normalzäit#,
			},
		},
		'Moscow' => {
			long => {
				'daylight' => q#Moskauer Summerzäit#,
				'generic' => q#Moskauer Zäit#,
				'standard' => q#Moskauer Normalzäit#,
			},
		},
		'Myanmar' => {
			long => {
				'standard' => q#Myanmar-Zäit#,
			},
		},
		'Nauru' => {
			long => {
				'standard' => q#Nauru-Zäit#,
			},
		},
		'Nepal' => {
			long => {
				'standard' => q#Nepalesesch Zäit#,
			},
		},
		'New_Caledonia' => {
			long => {
				'daylight' => q#Neikaledonesch Summerzäit#,
				'generic' => q#Neikaledonesch Zäit#,
				'standard' => q#Neikaledonesch Normalzäit#,
			},
		},
		'New_Zealand' => {
			long => {
				'daylight' => q#Neiséiland-Summerzäit#,
				'generic' => q#Neiséiland-Zäit#,
				'standard' => q#Neiséiland-Normalzäit#,
			},
		},
		'Newfoundland' => {
			long => {
				'daylight' => q#Neifundland-Summerzäit#,
				'generic' => q#Neifundland-Zäit#,
				'standard' => q#Neifundland-Normalzäit#,
			},
		},
		'Niue' => {
			long => {
				'standard' => q#Niue-Zäit#,
			},
		},
		'Norfolk' => {
			long => {
				'standard' => q#Norfolkinselen-Zäit#,
			},
		},
		'Noronha' => {
			long => {
				'daylight' => q#Fernando-de-Noronha-Summerzäit#,
				'generic' => q#Fernando-de-Noronha-Zäit#,
				'standard' => q#Fernando-de-Noronha-Normalzäit#,
			},
		},
		'Novosibirsk' => {
			long => {
				'daylight' => q#Nowosibirsk-Summerzäit#,
				'generic' => q#Nowosibirsk-Zäit#,
				'standard' => q#Nowosibirsk-Normalzäit#,
			},
		},
		'Omsk' => {
			long => {
				'daylight' => q#Omsk-Summerzäit#,
				'generic' => q#Omsk-Zäit#,
				'standard' => q#Omsk-Normalzäit#,
			},
		},
		'Pacific/Easter' => {
			exemplarCity => q#Ouschterinsel#,
		},
		'Pacific/Fiji' => {
			exemplarCity => q#Fidschi#,
		},
		'Pacific/Ponape' => {
			exemplarCity => q#Pohnpei#,
		},
		'Pacific/Truk' => {
			exemplarCity => q#Chuuk#,
		},
		'Pakistan' => {
			long => {
				'daylight' => q#Pakistanesch Summerzäit#,
				'generic' => q#Pakistanesch Zäit#,
				'standard' => q#Pakistanesch Normalzäit#,
			},
		},
		'Palau' => {
			long => {
				'standard' => q#Palau-Zäit#,
			},
		},
		'Papua_New_Guinea' => {
			long => {
				'standard' => q#Papua-Neiguinea-Zäit#,
			},
		},
		'Paraguay' => {
			long => {
				'daylight' => q#Paraguayanesch Summerzäit#,
				'generic' => q#Paraguayanesch Zäit#,
				'standard' => q#Paraguayanesch Normalzäit#,
			},
		},
		'Peru' => {
			long => {
				'daylight' => q#Peruanesch Summerzäit#,
				'generic' => q#Peruanesch Zäit#,
				'standard' => q#Peruanesch Normalzäit#,
			},
		},
		'Philippines' => {
			long => {
				'daylight' => q#Philippinnesch Summerzäit#,
				'generic' => q#Philippinnesch Zäit#,
				'standard' => q#Philippinnesch Normalzäit#,
			},
		},
		'Phoenix_Islands' => {
			long => {
				'standard' => q#Phoenixinselen-Zäit#,
			},
		},
		'Pierre_Miquelon' => {
			long => {
				'daylight' => q#Saint-Pierre-a-Miquelon-Summerzäit#,
				'generic' => q#Saint-Pierre-a-Miquelon-Zäit#,
				'standard' => q#Saint-Pierre-a-Miquelon-Normalzäit#,
			},
		},
		'Pitcairn' => {
			long => {
				'standard' => q#Pitcairninselen-Zäit#,
			},
		},
		'Ponape' => {
			long => {
				'standard' => q#Ponape-Zäit#,
			},
		},
		'Reunion' => {
			long => {
				'standard' => q#Réunion-Zäit#,
			},
		},
		'Rothera' => {
			long => {
				'standard' => q#Rothera-Zäit#,
			},
		},
		'Sakhalin' => {
			long => {
				'daylight' => q#Sakhalin-Summerzäit#,
				'generic' => q#Sakhalin-Zäit#,
				'standard' => q#Sakhalin-Normalzäit#,
			},
		},
		'Samara' => {
			long => {
				'daylight' => q#Samara-Summerzäit#,
				'generic' => q#Samara-Zäit#,
				'standard' => q#Samara-Normalzäit#,
			},
		},
		'Samoa' => {
			long => {
				'daylight' => q#Samoa-Summerzäit#,
				'generic' => q#Samoa-Zäit#,
				'standard' => q#Samoa-Normalzäit#,
			},
		},
		'Seychelles' => {
			long => {
				'standard' => q#Seychellen-Zäit#,
			},
		},
		'Singapore' => {
			long => {
				'standard' => q#Singapur-Standardzäit#,
			},
		},
		'Solomon' => {
			long => {
				'standard' => q#Salomoninselen-Zäit#,
			},
		},
		'South_Georgia' => {
			long => {
				'standard' => q#Südgeorgesch Zäit#,
			},
		},
		'Suriname' => {
			long => {
				'standard' => q#Suriname-Zäit#,
			},
		},
		'Syowa' => {
			long => {
				'standard' => q#Syowa-Zäit#,
			},
		},
		'Tahiti' => {
			long => {
				'standard' => q#Tahiti-Zäit#,
			},
		},
		'Taipei' => {
			long => {
				'daylight' => q#Taipei-Summerzäit#,
				'generic' => q#Taipei-Zäit#,
				'standard' => q#Taipei-Normalzäit#,
			},
		},
		'Tajikistan' => {
			long => {
				'standard' => q#Tadschikistan-Zäit#,
			},
		},
		'Tokelau' => {
			long => {
				'standard' => q#Tokelau-Zäit#,
			},
		},
		'Tonga' => {
			long => {
				'daylight' => q#Tonganesch Summerzäit#,
				'generic' => q#Tonganesch Zäit#,
				'standard' => q#Tonganesch Normalzäit#,
			},
		},
		'Truk' => {
			long => {
				'standard' => q#Chuuk-Zäit#,
			},
		},
		'Turkmenistan' => {
			long => {
				'daylight' => q#Turkmenistan-Summerzäit#,
				'generic' => q#Turkmenistan-Zäit#,
				'standard' => q#Turkmenistan-Normalzäit#,
			},
		},
		'Tuvalu' => {
			long => {
				'standard' => q#Tuvalu-Zäit#,
			},
		},
		'Uruguay' => {
			long => {
				'daylight' => q#Uruguayanesch Summerzäit#,
				'generic' => q#Uruguayanesch Zäit#,
				'standard' => q#Uruguyanesch Normalzäit#,
			},
		},
		'Uzbekistan' => {
			long => {
				'daylight' => q#Usbekistan-Summerzäit#,
				'generic' => q#Usbekistan-Zäit#,
				'standard' => q#Usbekistan-Normalzäit#,
			},
		},
		'Vanuatu' => {
			long => {
				'daylight' => q#Vanuatu-Summerzäit#,
				'generic' => q#Vanuatu-Zäit#,
				'standard' => q#Vanuatu-Normalzäit#,
			},
		},
		'Venezuela' => {
			long => {
				'standard' => q#Venezuela-Zäit#,
			},
		},
		'Vladivostok' => {
			long => {
				'daylight' => q#Wladiwostok-Summerzäit#,
				'generic' => q#Wladiwostok-Zäit#,
				'standard' => q#Wladiwostok-Normalzäit#,
			},
		},
		'Volgograd' => {
			long => {
				'daylight' => q#Wolgograd-Summerzäit#,
				'generic' => q#Wolgograd-Zäit#,
				'standard' => q#Wolgograd-Normalzäit#,
			},
		},
		'Vostok' => {
			long => {
				'standard' => q#Wostok-Zäit#,
			},
		},
		'Wake' => {
			long => {
				'standard' => q#Wake-Insel-Zäit#,
			},
		},
		'Wallis' => {
			long => {
				'standard' => q#Wallis-a-Futuna-Zäit#,
			},
		},
		'Yakutsk' => {
			long => {
				'daylight' => q#Jakutsk-Summerzäit#,
				'generic' => q#Jakutsk-Zäit#,
				'standard' => q#Jakutsk-Normalzäit#,
			},
		},
		'Yekaterinburg' => {
			long => {
				'daylight' => q#Jekaterinbuerg-Summerzäit#,
				'generic' => q#Jekaterinbuerg-Zäit#,
				'standard' => q#Jekaterinbuerg-Normalzäit#,
			},
		},
	 } }
);
no Moo;

1;

# vim: tabstop=4
