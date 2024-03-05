package Locale::CLDR::Plurals;
# This file auto generated from Data\common\supplemental\pluralRanges.xml
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
use Moo::Role;

sub _parse_number_plurals {
    use bigfloat;
    my $number = shift;
    my $e = my $c = ($number =~ /[ce](.*)$/ // 0);

    if ($e) {
        $number =~ s/[ce].*$//;
    }

    $number *= 10 ** $e
        if $e;

    my $n = abs($number);
    my $i = int($n);
    my ($f) = $number =~ /\.(.*)$/;
    $f //= '';
    my $t = length $f ? $f + 0 : '';
    my $v = length $f;
    my $w = length $t;
    $t ||= 0;

    return ( $n, $i, $v, $w, $f, $t, $c, $e );
}

my %_plurals = (

	cardinal => {
		af => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		ak => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (0..1)) ;
			},
		},
		am => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (0)) ||  scalar (grep {$n == $_} (1)) ;
			},
		},
		an => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		ar => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 100 == $_} (3..10)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 100 == $_} (11..99)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2)) ;
			},
			zero => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (0)) ;
			},
		},
		ars => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 100 == $_} (3..10)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 100 == $_} (11..99)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2)) ;
			},
			zero => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (0)) ;
			},
		},
		as => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (0)) ||  scalar (grep {$n == $_} (1)) ;
			},
		},
		asa => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		ast => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		az => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		bal => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		be => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (2..4)) && ! scalar (grep {$n % 100 == $_} (12..14)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (0)) ||  scalar (grep {$n % 10 == $_} (5..9)) ||  scalar (grep {$n % 100 == $_} (11..14)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (1)) && ! scalar (grep {$n % 100 == $_} (11)) ;
			},
		},
		bem => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		bez => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		bg => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		bho => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (0..1)) ;
			},
		},
		blo => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			zero => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (0)) ;
			},
		},
		bn => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (0)) ||  scalar (grep {$n == $_} (1)) ;
			},
		},
		br => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (3..4,9)) && ! scalar (grep {$n % 100 == $_} (10..19,70..79,90..99)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return ! scalar (grep {$n == $_} (0)) &&  scalar (grep {$n % 1000000 == $_} (0)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (1)) && ! scalar (grep {$n % 100 == $_} (11,71,91)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (2)) && ! scalar (grep {$n % 100 == $_} (12,72,92)) ;
			},
		},
		brx => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		bs => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (2..4)) && ! scalar (grep {$i % 100 == $_} (12..14)) ||  scalar (grep {$f % 10 == $_} (2..4)) && ! scalar (grep {$f % 100 == $_} (12..14)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (1)) && ! scalar (grep {$i % 100 == $_} (11)) ||  scalar (grep {$f % 10 == $_} (1)) && ! scalar (grep {$f % 100 == $_} (11)) ;
			},
		},
		ca => {
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$e == $_} (0)) && ! scalar (grep {$i == $_} (0)) &&  scalar (grep {$i % 1000000 == $_} (0)) &&  scalar (grep {$v == $_} (0)) || ! scalar (grep {$e == $_} (0..5)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		ce => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		ceb => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i == $_} (1,2,3)) ||  scalar (grep {$v == $_} (0)) && ! scalar (grep {$i % 10 == $_} (4,6,9)) || ! scalar (grep {$v == $_} (0)) && ! scalar (grep {$f % 10 == $_} (4,6,9)) ;
			},
		},
		cgg => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		chr => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		ckb => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		cs => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (2..4)) &&  scalar (grep {$v == $_} (0)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return ! scalar (grep {$v == $_} (0))   ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		cy => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (3)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (6)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2)) ;
			},
			zero => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (0)) ;
			},
		},
		da => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) || ! scalar (grep {$t == $_} (0)) &&  scalar (grep {$i == $_} (0,1)) ;
			},
		},
		de => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		doi => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (0)) ||  scalar (grep {$n == $_} (1)) ;
			},
		},
		dsb => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 100 == $_} (3..4)) ||  scalar (grep {$f % 100 == $_} (3..4)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 100 == $_} (1)) ||  scalar (grep {$f % 100 == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 100 == $_} (2)) ||  scalar (grep {$f % 100 == $_} (2)) ;
			},
		},
		dv => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		ee => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		el => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		en => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		eo => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		es => {
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$e == $_} (0)) && ! scalar (grep {$i == $_} (0)) &&  scalar (grep {$i % 1000000 == $_} (0)) &&  scalar (grep {$v == $_} (0)) || ! scalar (grep {$e == $_} (0..5)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		et => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		eu => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		fa => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (0)) ||  scalar (grep {$n == $_} (1)) ;
			},
		},
		ff => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (0,1)) ;
			},
		},
		fi => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		fil => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i == $_} (1,2,3)) ||  scalar (grep {$v == $_} (0)) && ! scalar (grep {$i % 10 == $_} (4,6,9)) || ! scalar (grep {$v == $_} (0)) && ! scalar (grep {$f % 10 == $_} (4,6,9)) ;
			},
		},
		fo => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		fr => {
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$e == $_} (0)) && ! scalar (grep {$i == $_} (0)) &&  scalar (grep {$i % 1000000 == $_} (0)) &&  scalar (grep {$v == $_} (0)) || ! scalar (grep {$e == $_} (0..5)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (0,1)) ;
			},
		},
		fur => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		fy => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		ga => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (3..6)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (7..10)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2)) ;
			},
		},
		gd => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (3..10,13..19)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1,11)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2,12)) ;
			},
		},
		gl => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		gsw => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		gu => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (0)) ||  scalar (grep {$n == $_} (1)) ;
			},
		},
		guw => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (0..1)) ;
			},
		},
		gv => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 100 == $_} (0,20,40,60,80)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return ! scalar (grep {$v == $_} (0))   ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (2)) ;
			},
		},
		ha => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		haw => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		he => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ||  scalar (grep {$i == $_} (0)) && ! scalar (grep {$v == $_} (0)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (2)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		hi => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (0)) ||  scalar (grep {$n == $_} (1)) ;
			},
		},
		hr => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (2..4)) && ! scalar (grep {$i % 100 == $_} (12..14)) ||  scalar (grep {$f % 10 == $_} (2..4)) && ! scalar (grep {$f % 100 == $_} (12..14)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (1)) && ! scalar (grep {$i % 100 == $_} (11)) ||  scalar (grep {$f % 10 == $_} (1)) && ! scalar (grep {$f % 100 == $_} (11)) ;
			},
		},
		hsb => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 100 == $_} (3..4)) ||  scalar (grep {$f % 100 == $_} (3..4)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 100 == $_} (1)) ||  scalar (grep {$f % 100 == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 100 == $_} (2)) ||  scalar (grep {$f % 100 == $_} (2)) ;
			},
		},
		hu => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		hy => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (0,1)) ;
			},
		},
		ia => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		io => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		is => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$t == $_} (0)) &&  scalar (grep {$i % 10 == $_} (1)) && ! scalar (grep {$i % 100 == $_} (11)) ||  scalar (grep {$t % 10 == $_} (1)) && ! scalar (grep {$t % 100 == $_} (11)) ;
			},
		},
		it => {
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$e == $_} (0)) && ! scalar (grep {$i == $_} (0)) &&  scalar (grep {$i % 1000000 == $_} (0)) &&  scalar (grep {$v == $_} (0)) || ! scalar (grep {$e == $_} (0..5)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		iu => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2)) ;
			},
		},
		iw => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ||  scalar (grep {$i == $_} (0)) && ! scalar (grep {$v == $_} (0)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (2)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		jgo => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		ji => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		jmc => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		ka => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		kab => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (0,1)) ;
			},
		},
		kaj => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		kcg => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		kk => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		kkj => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		kl => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		kn => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (0)) ||  scalar (grep {$n == $_} (1)) ;
			},
		},
		ks => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		ksb => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		ksh => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			zero => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (0)) ;
			},
		},
		ku => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		kw => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 100 == $_} (3,23,43,63,83)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return ! scalar (grep {$n == $_} (1)) &&  scalar (grep {$n % 100 == $_} (1,21,41,61,81)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 100 == $_} (2,22,42,62,82)) ||  scalar (grep {$n % 1000 == $_} (0)) &&  scalar (grep {$n % 100000 == $_} (1000..20000,40000,60000,80000)) || ! scalar (grep {$n == $_} (0)) &&  scalar (grep {$n % 1000000 == $_} (100000)) ;
			},
			zero => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (0)) ;
			},
		},
		ky => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		lag => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (0,1)) && ! scalar (grep {$n == $_} (0)) ;
			},
			zero => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (0)) ;
			},
		},
		lb => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		lg => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		lij => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		ln => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (0..1)) ;
			},
		},
		lt => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (2..9)) && ! scalar (grep {$n % 100 == $_} (11..19)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return ! scalar (grep {$f == $_} (0))   ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (1)) && ! scalar (grep {$n % 100 == $_} (11..19)) ;
			},
		},
		lv => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (1)) && ! scalar (grep {$n % 100 == $_} (11)) ||  scalar (grep {$v == $_} (2)) &&  scalar (grep {$f % 10 == $_} (1)) && ! scalar (grep {$f % 100 == $_} (11)) || ! scalar (grep {$v == $_} (2)) &&  scalar (grep {$f % 10 == $_} (1)) ;
			},
			zero => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (0)) ||  scalar (grep {$n % 100 == $_} (11..19)) ||  scalar (grep {$v == $_} (2)) &&  scalar (grep {$f % 100 == $_} (11..19)) ;
			},
		},
		mas => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		mg => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (0..1)) ;
			},
		},
		mgo => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		mk => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (1)) && ! scalar (grep {$i % 100 == $_} (11)) ||  scalar (grep {$f % 10 == $_} (1)) && ! scalar (grep {$f % 100 == $_} (11)) ;
			},
		},
		ml => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		mn => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		mo => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return ! scalar (grep {$v == $_} (0)) ||  scalar (grep {$n == $_} (0)) || ! scalar (grep {$n == $_} (1)) &&  scalar (grep {$n % 100 == $_} (1..19)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		mr => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		mt => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (0)) ||  scalar (grep {$n % 100 == $_} (3..10)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 100 == $_} (11..19)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2)) ;
			},
		},
		nah => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		naq => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2)) ;
			},
		},
		nb => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		nd => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		ne => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		nl => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		nn => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		nnh => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		no => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		nr => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		nso => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (0..1)) ;
			},
		},
		ny => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		nyn => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		om => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		or => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		os => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		pa => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (0..1)) ;
			},
		},
		pap => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		pcm => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (0)) ||  scalar (grep {$n == $_} (1)) ;
			},
		},
		pl => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (2..4)) && ! scalar (grep {$i % 100 == $_} (12..14)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) && ! scalar (grep {$i == $_} (1)) &&  scalar (grep {$i % 10 == $_} (0..1)) ||  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (5..9)) ||  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 100 == $_} (12..14)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		prg => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (1)) && ! scalar (grep {$n % 100 == $_} (11)) ||  scalar (grep {$v == $_} (2)) &&  scalar (grep {$f % 10 == $_} (1)) && ! scalar (grep {$f % 100 == $_} (11)) || ! scalar (grep {$v == $_} (2)) &&  scalar (grep {$f % 10 == $_} (1)) ;
			},
			zero => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (0)) ||  scalar (grep {$n % 100 == $_} (11..19)) ||  scalar (grep {$v == $_} (2)) &&  scalar (grep {$f % 100 == $_} (11..19)) ;
			},
		},
		ps => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		pt => {
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$e == $_} (0)) && ! scalar (grep {$i == $_} (0)) &&  scalar (grep {$i % 1000000 == $_} (0)) &&  scalar (grep {$v == $_} (0)) || ! scalar (grep {$e == $_} (0..5)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (0..1)) ;
			},
		},
		pt_PT => {
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$e == $_} (0)) && ! scalar (grep {$i == $_} (0)) &&  scalar (grep {$i % 1000000 == $_} (0)) &&  scalar (grep {$v == $_} (0)) || ! scalar (grep {$e == $_} (0..5)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		rm => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		ro => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return ! scalar (grep {$v == $_} (0)) ||  scalar (grep {$n == $_} (0)) || ! scalar (grep {$n == $_} (1)) &&  scalar (grep {$n % 100 == $_} (1..19)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		rof => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		ru => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (2..4)) && ! scalar (grep {$i % 100 == $_} (12..14)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (0)) ||  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (5..9)) ||  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 100 == $_} (11..14)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (1)) && ! scalar (grep {$i % 100 == $_} (11)) ;
			},
		},
		rwk => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		saq => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		sat => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2)) ;
			},
		},
		sc => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		scn => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		sd => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		sdh => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		se => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2)) ;
			},
		},
		seh => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		sh => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (2..4)) && ! scalar (grep {$i % 100 == $_} (12..14)) ||  scalar (grep {$f % 10 == $_} (2..4)) && ! scalar (grep {$f % 100 == $_} (12..14)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (1)) && ! scalar (grep {$i % 100 == $_} (11)) ||  scalar (grep {$f % 10 == $_} (1)) && ! scalar (grep {$f % 100 == $_} (11)) ;
			},
		},
		shi => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2..10)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (0)) ||  scalar (grep {$n == $_} (1)) ;
			},
		},
		si => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (0,1)) ||  scalar (grep {$i == $_} (0)) &&  scalar (grep {$f == $_} (1)) ;
			},
		},
		sk => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (2..4)) &&  scalar (grep {$v == $_} (0)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return ! scalar (grep {$v == $_} (0))   ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		sl => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 100 == $_} (3..4)) || ! scalar (grep {$v == $_} (0)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 100 == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 100 == $_} (2)) ;
			},
		},
		sma => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2)) ;
			},
		},
		smi => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2)) ;
			},
		},
		smj => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2)) ;
			},
		},
		smn => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2)) ;
			},
		},
		sms => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2)) ;
			},
		},
		sn => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		so => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		sq => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		sr => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (2..4)) && ! scalar (grep {$i % 100 == $_} (12..14)) ||  scalar (grep {$f % 10 == $_} (2..4)) && ! scalar (grep {$f % 100 == $_} (12..14)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (1)) && ! scalar (grep {$i % 100 == $_} (11)) ||  scalar (grep {$f % 10 == $_} (1)) && ! scalar (grep {$f % 100 == $_} (11)) ;
			},
		},
		ss => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		ssy => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		st => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		sv => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		sw => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		syr => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		ta => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		te => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		teo => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		ti => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (0..1)) ;
			},
		},
		tig => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		tk => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		tl => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i == $_} (1,2,3)) ||  scalar (grep {$v == $_} (0)) && ! scalar (grep {$i % 10 == $_} (4,6,9)) || ! scalar (grep {$v == $_} (0)) && ! scalar (grep {$f % 10 == $_} (4,6,9)) ;
			},
		},
		tn => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		tr => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		ts => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		tzm => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (0..1)) ||  scalar (grep {$n == $_} (11..99)) ;
			},
		},
		ug => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		uk => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (2..4)) && ! scalar (grep {$i % 100 == $_} (12..14)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (0)) ||  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (5..9)) ||  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 100 == $_} (11..14)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$v == $_} (0)) &&  scalar (grep {$i % 10 == $_} (1)) && ! scalar (grep {$i % 100 == $_} (11)) ;
			},
		},
		ur => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		uz => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		ve => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		vec => {
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$e == $_} (0)) && ! scalar (grep {$i == $_} (0)) &&  scalar (grep {$i % 1000000 == $_} (0)) &&  scalar (grep {$v == $_} (0)) || ! scalar (grep {$e == $_} (0..5)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		vo => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		vun => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		wa => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (0..1)) ;
			},
		},
		wae => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		xh => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		xog => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		yi => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) &&  scalar (grep {$v == $_} (0)) ;
			},
		},
		zu => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (0)) ||  scalar (grep {$n == $_} (1)) ;
			},
		},
	},
	ordinal => {
		as => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (4)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (6)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1,5,7,8,9,10)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2,3)) ;
			},
		},
		az => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i % 10 == $_} (3,4)) ||  scalar (grep {$i % 1000 == $_} (100,200,300,400,500,600,700,800,900)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (0)) ||  scalar (grep {$i % 10 == $_} (6)) ||  scalar (grep {$i % 100 == $_} (40,60,90)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i % 10 == $_} (1,2,5,7,8)) ||  scalar (grep {$i % 100 == $_} (20,50,70,80)) ;
			},
		},
		bal => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		be => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (2,3)) && ! scalar (grep {$n % 100 == $_} (12,13)) ;
			},
		},
		blo => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (2,3,4,5,6)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) ;
			},
			zero => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (0)) ;
			},
		},
		bn => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (4)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (6)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1,5,7,8,9,10)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2,3)) ;
			},
		},
		ca => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (4)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1,3)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2)) ;
			},
		},
		cy => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (3,4)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (5,6)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2)) ;
			},
			zero => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (0,7,8,9)) ;
			},
		},
		en => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (3)) && ! scalar (grep {$n % 100 == $_} (13)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (1)) && ! scalar (grep {$n % 100 == $_} (11)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (2)) && ! scalar (grep {$n % 100 == $_} (12)) ;
			},
		},
		fil => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		fr => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		ga => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		gd => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (3,13)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1,11)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2,12)) ;
			},
		},
		gu => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (4)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (6)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2,3)) ;
			},
		},
		hi => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (4)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (6)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2,3)) ;
			},
		},
		hu => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1,5)) ;
			},
		},
		hy => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		it => {
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (11,8,80,800)) ;
			},
		},
		ka => {
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (0)) ||  scalar (grep {$i % 100 == $_} (2..20,40,60,80)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i == $_} (1)) ;
			},
		},
		kk => {
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (6)) ||  scalar (grep {$n % 10 == $_} (9)) ||  scalar (grep {$n % 10 == $_} (0)) && ! scalar (grep {$n == $_} (0)) ;
			},
		},
		kw => {
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (5)) ||  scalar (grep {$n % 100 == $_} (5)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1..4)) ||  scalar (grep {$n % 100 == $_} (1..4,21..24,41..44,61..64,81..84)) ;
			},
		},
		lij => {
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (11,8,80..89,800..899)) ;
			},
		},
		lo => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		mk => {
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i % 10 == $_} (7,8)) && ! scalar (grep {$i % 100 == $_} (17,18)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i % 10 == $_} (1)) && ! scalar (grep {$i % 100 == $_} (11)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$i % 10 == $_} (2)) && ! scalar (grep {$i % 100 == $_} (12)) ;
			},
		},
		mo => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		mr => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (4)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2,3)) ;
			},
		},
		ms => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		ne => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1..4)) ;
			},
		},
		or => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (4)) ;
			},
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (6)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1,5,7..9)) ;
			},
			two => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (2,3)) ;
			},
		},
		ro => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		sc => {
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (11,8,80,800)) ;
			},
		},
		scn => {
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (11,8,80,800)) ;
			},
		},
		sq => {
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (4)) && ! scalar (grep {$n % 100 == $_} (14)) ;
			},
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		sv => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (1,2)) && ! scalar (grep {$n % 100 == $_} (11,12)) ;
			},
		},
		tk => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (6,9)) ||  scalar (grep {$n == $_} (10)) ;
			},
		},
		tl => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
		uk => {
			few => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n % 10 == $_} (3)) && ! scalar (grep {$n % 100 == $_} (13)) ;
			},
		},
		vec => {
			many => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (11,8,80,800)) ;
			},
		},
		vi => {
			one => sub {
				my $number = shift;
				my ( $n, $i, $v, $w, $f, $t, $c, $e ) = _parse_number_plurals( $number );
				return  scalar (grep {$n == $_} (1)) ;
			},
		},
	},
);

sub plural {
    my ($self, $number, $type) = @_;
    $type //= 'cardinal';
    my $language_id = $self->language_id || $self->likely_subtag->language_id;

    foreach my $count (qw( zero one two few many )) {
        next unless exists $_plurals{$type}{$language_id}{$count};
        return $count if $_plurals{$type}{$language_id}{$count}->($number);
    }
    return 'other';
}

my %_plural_ranges = (
	af => {
		one => {
			other => 'other',
		},
		other => {
			one => 'other',
			other => 'other',
		},
	},
	ak => {
		one => {
			one => 'other',
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	am => {
		one => {
			one => 'one',
			other => 'other',
		},
		other => {
			other => 'other',
		},
	},
	an => {
		one => {
			other => 'other',
		},
		other => {
			one => 'other',
			other => 'other',
		},
	},
	ar => {
		few => {
			few => 'few',
			many => 'many',
			other => 'other',
		},
		many => {
			few => 'few',
			many => 'many',
			other => 'other',
		},
		one => {
			few => 'few',
			many => 'many',
			other => 'other',
			two => 'other',
		},
		other => {
			few => 'few',
			many => 'many',
			one => 'other',
			other => 'other',
			two => 'other',
		},
		two => {
			few => 'few',
			many => 'many',
			other => 'other',
		},
		zero => {
			few => 'few',
			many => 'many',
			one => 'zero',
			other => 'other',
			two => 'zero',
		},
	},
	as => {
		one => {
			one => 'one',
			other => 'other',
		},
		other => {
			other => 'other',
		},
	},
	az => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	be => {
		few => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
		many => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
		one => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
		other => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
	},
	bg => {
		one => {
			other => 'other',
		},
		other => {
			one => 'other',
			other => 'other',
		},
	},
	bn => {
		one => {
			one => 'one',
			other => 'other',
		},
		other => {
			other => 'other',
		},
	},
	bs => {
		few => {
			few => 'few',
			one => 'one',
			other => 'other',
		},
		one => {
			few => 'few',
			one => 'one',
			other => 'other',
		},
		other => {
			few => 'few',
			one => 'one',
			other => 'other',
		},
	},
	ca => {
		one => {
			other => 'other',
		},
		other => {
			one => 'other',
			other => 'other',
		},
	},
	cs => {
		few => {
			few => 'few',
			many => 'many',
			other => 'other',
		},
		many => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
		one => {
			few => 'few',
			many => 'many',
			other => 'other',
		},
		other => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
	},
	cy => {
		few => {
			many => 'many',
			other => 'other',
		},
		many => {
			other => 'other',
		},
		one => {
			few => 'few',
			many => 'many',
			other => 'other',
			two => 'two',
		},
		other => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
			two => 'two',
		},
		two => {
			few => 'few',
			many => 'many',
			other => 'other',
		},
		zero => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
			two => 'two',
		},
	},
	da => {
		one => {
			one => 'one',
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	de => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	el => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	en => {
		one => {
			other => 'other',
		},
		other => {
			one => 'other',
			other => 'other',
		},
	},
	es => {
		one => {
			other => 'other',
		},
		other => {
			one => 'other',
			other => 'other',
		},
	},
	et => {
		one => {
			other => 'other',
		},
		other => {
			one => 'other',
			other => 'other',
		},
	},
	eu => {
		one => {
			other => 'other',
		},
		other => {
			one => 'other',
			other => 'other',
		},
	},
	fa => {
		one => {
			one => 'other',
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	fi => {
		one => {
			other => 'other',
		},
		other => {
			one => 'other',
			other => 'other',
		},
	},
	fil => {
		one => {
			one => 'one',
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	fr => {
		one => {
			one => 'one',
			other => 'other',
		},
		other => {
			other => 'other',
		},
	},
	ga => {
		few => {
			few => 'few',
			many => 'many',
			other => 'other',
		},
		many => {
			many => 'many',
			other => 'other',
		},
		one => {
			few => 'few',
			many => 'many',
			other => 'other',
			two => 'two',
		},
		other => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
			two => 'two',
		},
		two => {
			few => 'few',
			many => 'many',
			other => 'other',
		},
	},
	gl => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	gsw => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	gu => {
		one => {
			one => 'one',
			other => 'other',
		},
		other => {
			other => 'other',
		},
	},
	he => {
		one => {
			other => 'other',
			two => 'other',
		},
		other => {
			one => 'other',
			other => 'other',
			two => 'other',
		},
		two => {
			other => 'other',
		},
	},
	hi => {
		one => {
			one => 'one',
			other => 'other',
		},
		other => {
			other => 'other',
		},
	},
	hr => {
		few => {
			few => 'few',
			one => 'one',
			other => 'other',
		},
		one => {
			few => 'few',
			one => 'one',
			other => 'other',
		},
		other => {
			few => 'few',
			one => 'one',
			other => 'other',
		},
	},
	hu => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	hy => {
		one => {
			one => 'one',
			other => 'other',
		},
		other => {
			other => 'other',
		},
	},
	ia => {
		one => {
			other => 'other',
		},
		other => {
			one => 'other',
			other => 'other',
		},
	},
	id => {
		other => {
			other => 'other',
		},
	},
	io => {
		one => {
			other => 'other',
		},
		other => {
			one => 'other',
			other => 'other',
		},
	},
	is => {
		one => {
			one => 'one',
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	it => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	ja => {
		other => {
			other => 'other',
		},
	},
	ka => {
		one => {
			other => 'one',
		},
		other => {
			one => 'other',
			other => 'other',
		},
	},
	kk => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	km => {
		other => {
			other => 'other',
		},
	},
	kn => {
		one => {
			one => 'one',
			other => 'other',
		},
		other => {
			other => 'other',
		},
	},
	ko => {
		other => {
			other => 'other',
		},
	},
	ky => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	lij => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	lo => {
		other => {
			other => 'other',
		},
	},
	lt => {
		few => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
		many => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
		one => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
		other => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
	},
	lv => {
		one => {
			one => 'one',
			other => 'other',
			zero => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
			zero => 'other',
		},
		zero => {
			one => 'one',
			other => 'other',
			zero => 'other',
		},
	},
	mk => {
		one => {
			one => 'other',
			other => 'other',
		},
		other => {
			one => 'other',
			other => 'other',
		},
	},
	ml => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	mn => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	mr => {
		one => {
			one => 'one',
			other => 'other',
		},
		other => {
			other => 'other',
		},
	},
	ms => {
		other => {
			other => 'other',
		},
	},
	my => {
		other => {
			other => 'other',
		},
	},
	nb => {
		one => {
			other => 'other',
		},
		other => {
			one => 'other',
			other => 'other',
		},
	},
	ne => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	nl => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	no => {
		one => {
			other => 'other',
		},
		other => {
			one => 'other',
			other => 'other',
		},
	},
	or => {
		one => {
			one => 'other',
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	pa => {
		one => {
			one => 'one',
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	pcm => {
		one => {
			other => 'other',
		},
		other => {
			one => 'other',
			other => 'other',
		},
	},
	pl => {
		few => {
			few => 'few',
			many => 'many',
			other => 'other',
		},
		many => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
		one => {
			few => 'few',
			many => 'many',
			other => 'other',
		},
		other => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
	},
	ps => {
		one => {
			one => 'one',
			other => 'other',
		},
		other => {
			other => 'other',
		},
	},
	pt => {
		one => {
			one => 'one',
			other => 'other',
		},
		other => {
			other => 'other',
		},
	},
	ro => {
		few => {
			few => 'few',
			one => 'few',
			other => 'other',
		},
		one => {
			few => 'few',
			other => 'other',
		},
		other => {
			few => 'few',
			other => 'other',
		},
	},
	ru => {
		few => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
		many => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
		one => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
		other => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
	},
	sc => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	scn => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	sd => {
		one => {
			one => 'other',
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	si => {
		one => {
			one => 'one',
			other => 'other',
		},
		other => {
			one => 'other',
			other => 'other',
		},
	},
	sk => {
		few => {
			few => 'few',
			many => 'many',
			other => 'other',
		},
		many => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
		one => {
			few => 'few',
			many => 'many',
			other => 'other',
		},
		other => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
	},
	sl => {
		few => {
			few => 'few',
			one => 'few',
			other => 'other',
			two => 'two',
		},
		one => {
			few => 'few',
			one => 'few',
			other => 'other',
			two => 'two',
		},
		other => {
			few => 'few',
			one => 'few',
			other => 'other',
			two => 'two',
		},
		two => {
			few => 'few',
			one => 'few',
			other => 'other',
			two => 'two',
		},
	},
	sq => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	sr => {
		few => {
			few => 'few',
			one => 'one',
			other => 'other',
		},
		one => {
			few => 'few',
			one => 'one',
			other => 'other',
		},
		other => {
			few => 'few',
			one => 'one',
			other => 'other',
		},
	},
	sv => {
		one => {
			other => 'other',
		},
		other => {
			one => 'other',
			other => 'other',
		},
	},
	sw => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	ta => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	te => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	th => {
		other => {
			other => 'other',
		},
	},
	tk => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	tr => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	ug => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	uk => {
		few => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
		many => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
		one => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
		other => {
			few => 'few',
			many => 'many',
			one => 'one',
			other => 'other',
		},
	},
	ur => {
		one => {
			other => 'other',
		},
		other => {
			one => 'other',
			other => 'other',
		},
	},
	uz => {
		one => {
			other => 'other',
		},
		other => {
			one => 'one',
			other => 'other',
		},
	},
	vi => {
		other => {
			other => 'other',
		},
	},
	yue => {
		other => {
			other => 'other',
		},
	},
	zh => {
		other => {
			other => 'other',
		},
	},
	zu => {
		one => {
			one => 'one',
			other => 'other',
		},
		other => {
			other => 'other',
		},
	},
);

sub plural_range {
    my ($self, $start, $end) = @_;
    my $language_id = $self->language_id || $self->likely_subtag->language_id;

    $start = $self->plural($start) if $start =~ /^-?(?:[0-9]+\.)?[0-9]+$/;
    $end   = $self->plural($end)   if $end   =~ /^-?(?:[0-9]+\.)?[0-9]+$/;

    return $_plural_ranges{$language_id}{$start}{$end} // 'other';
}


no Moo::Role;

1;

# vim: tabstop=4
