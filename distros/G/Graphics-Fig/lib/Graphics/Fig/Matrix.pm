#
# XFig Drawing Library
#
# Copyright (c) 2017 D Scott Guthridge <scott_guthridge@rompromity.net>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the Artistic License as published by the Perl Foundation, either
# version 2.0 of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the Artistic License for more details.
# 
# You should have received a copy of the Artistic License along with this
# program.  If not, see <http://www.perlfoundation.org/artistic_license_2_0>.
#
package Graphics::Fig::Matrix;
our $VERSION = 'v1.0.2';

use strict;
use warnings;
use Carp;

use constant EPS => 1.0e-14;

#
# matrix_reduce: reduce a matrix (in-place) to reduced row eschelon form
#   $a: matrix [ [ a, b, ... ], [ d, e, ...], ... ]
#
# Return:
#   determinant
#
sub reduce {
    my $a = shift;

    my $m = scalar(@{$a});
    my $n = ($m == 0) ? 0 : scalar(@{${$a}[0]});
    my $i = 0;
    my $j = 0;
    my $d = 1.0;

    while ($i < $m && $j < $n) {
	my $scale;

	#
	# Find the largest value at or below row $i in column $j and
	# swap with row $i.
	#
	my $max_abs = 0.0;
	my $max_idx = undef;
	for (my $r = $i; $r < $m; ++$r) {
	    if (abs(${$a}[$r][$j]) > $max_abs) {
		$max_abs = abs(${$a}[$r][$j]);
		$max_idx = $r;
	    }
	}
	if ($max_abs <= EPS) {
	    $d = 0.0;
	    ++$j;
	    next;
	}
	if ($max_idx != $i) {
	    ( ${$a}[$i], ${$a}[$max_idx] ) = ( ${$a}[$max_idx], ${$a}[$i] );
	}

	#
	# Scale pivot to 1.0.
	#
	$scale = ${$a}[$i][$j];
	$d *= $scale;
	for (my $s = $j; $s < $n; ++$s) {
	    ${$a}[$i][$s] /= $scale;
	}

	#
	# Clear other entries in column.
	#
	for (my $r = 0; $r < $m; ++$r) {
	    if ($r != $i) {
		$scale = -${$a}[$r][$j];
		for (my $s = $j; $s < $n; ++$s) {
		    ${$a}[$r][$s] += $scale * ${$a}[$i][$s];
		}
	    }
	}
	++$i;
	++$j;
    }
    return $d;
}

#
# matrix_print: print a matrix
#   $a: matrix [ [ a, b, ... ], [ d, e, ...], ... ]
#
sub print {
    my $a = shift;

    my $m = scalar(@{$a});
    my $n = ($m == 0) ? 0 : scalar(@{${$a}[0]});
    for (my $i = 0; $i < $m; ++$i) {
	for (my $j = 0; $j < $n; ++$j) {
	    printf(" %10.5g", ${$a}[$i][$j]);
	}
	printf("\n");
    }
    printf("\n");
}

1;
