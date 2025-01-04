#! perl

# this code is a fairly close translation of NLopt's test/t_python.py

# /* Copyright (c) 2007-2020 Massachusetts Institute of Technology
#  *                         and other contributors
#  *
#  * Permission is hereby granted, free of charge, to any person obtaining
#  * a copy of this software and associated documentation files (the
#  * "Software"), to deal in the Software without restriction, including
#  * without limitation the rights to use, copy, modify, merge, publish,
#  * distribute, sublicense, and/or sell copies of the Software, and to
#  * permit persons to whom the Software is furnished to do so, subject to
#  * the following conditions:
#  *
#  * The above copyright notice and this permission notice shall be
#  * included in all copies or substantial portions of the Software.
#  *
#  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#  * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#  * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#  * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
#  * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
#  * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
#  * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#  */

use v5.10;
use Test2::V0;
use Math::NLopt 'NLOPT_LD_MMA';
use POSIX 'HUGE_VAL';

sub myfunc {
    my ( $x, $grad ) = @_;

    if ( $grad ) {
        $grad->[0] = 0.0;
        $grad->[1] = 0.5 / sqrt( $x->[1] );
    }
    return sqrt( $x->[1] );
}

sub myconstraint {
    my ( $x, $grad, $aa, $bb ) = @_;

    if ( $grad ) {
        $grad->[0] = 3 * $aa * ( $aa * $x->[0] + $bb )**2;
        $grad->[1] = -1.0;
    }
    return ( $aa * $x->[0] + $bb )**3 - $x->[1];
}

my $opt = Math::NLopt->new( NLOPT_LD_MMA, 2 );

$opt->set_lower_bounds( [ -HUGE_VAL(), 0 ] );
$opt->set_min_objective( \&myfunc );

$opt->add_inequality_constraint(
    sub {
        my ( $x, $grad ) = @_;
        return myconstraint( $x, $grad, 2, 0 );
    },
    1e-8,
);

$opt->add_inequality_constraint(
    sub {
        my ( $x, $grad ) = @_;
        return myconstraint( $x, $grad, -1, 1 );
    },
    1e-8,
);
$opt->set_xtol_rel( 1e-4 );
my @x0 = ( 1.234, 5.678 );

is( $opt->optimize( \@x0 ),   [ float( 0.33333333 ), float( 0.29629629 ) ], 'optimum parameters', );
is( $opt->last_optimum_value, float( 0.5443310476200902 ),                  'minimum vlaue', );
is( $opt->last_optimize_result, 4,                                          'result code' );
is( $opt->get_numevals,         11,                                         'nevals' );
is(
    $opt->get_initial_step( \@x0 ),
    array {
        item float( 1.234,  precision => 3 );
        item float( 4.2585, precision => 4 );
    },
    'initial step'
);

done_testing;
