#! perl

# this code is a fairly close translation of NLopt's test/lorentzfit.c

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

use Test2::V0;
use Math::NLopt ':algorithms';
use POSIX 'HUGE_VAL';

use Class::Struct lorentzdata => { N => q{$}, x => q{@}, y => q{@} };
use Devel::Peek;

sub urand {
    my ( $aa, $bb ) = @_;
    return $aa + ( $bb - $aa ) * rand;
}

sub sqr {
    my ( $x ) = @_;
    return $x * $x;
}

my $count = 0;

sub lorentzerr {
    my ( $p, $grad, $d ) = @_;

    my $N   = $d->N;
    my $n   = @{$p};
    my $xs  = $d->x;
    my $ys  = $d->y;
    my $val = 0;

    for my $i ( 0 .. $N - 1 ) {
        my $x      = $xs->[$i];
        my $y      = $ys->[$i];
        my $lorsum = 0;

        for ( my $j = 0 ; $j < $n ; $j += 3 ) {
            my $A   = $p->[ $j +0 ];
            my $w   = $p->[ $j + 1 ];
            my $G   = $p->[ $j + 2 ];
            my $lor = $A / ( sqr( $x - $w ) + $G * $G );

            $lorsum += $lor;
        }

        $val += sqr( $y - $lorsum );

        if ( $grad ) {
            for ( my $j = 0 ; $j < $n ; $j += 3 ) {
                my $A      = $p->[ $j +0 ];
                my $w      = $p->[ $j + 1 ];
                my $G      = $p->[ $j + 2 ];
                my $deninv = 1.0 / ( sqr( $x - $w ) + $G * $G );

                $grad->[ $j +0 ]  += -2 * ( $y - $lorsum ) * $deninv;
                $grad->[ $j + 1 ] += 4 * $A * ( $w - $x ) * ( $y - $lorsum ) * sqr( $deninv );
                $grad->[ $j + 2 ] += 4 * $A * $G * ( $y - $lorsum ) * sqr( $deninv );
            }
        }
    }
    ++$count;
    # printf STDERR ("%d: f(%g,%g,%g) = %g\n", $count, $p->[0],$p->[1],$p->[2], $val);
    return $val;
}


sub nlopt_minimize {
    my (
        $algorithm, $n,        $f,        $f_data,   $lb,       $ub,      $x, $minf,
        $minf_max,  $ftol_rel, $ftol_abs, $xtol_rel, $xtol_abs, $maxeval, $maxtime,
    ) = @_;
    my $opt = Math::NLopt::create( $algorithm, $n );

    $opt->set_min_objective( $f, $f_data );

    $opt->set_xtol_rel( $xtol_rel );

    $opt->set_lower_bounds( $lb );
    $opt->set_upper_bounds( $ub );

    $opt->set_stopval( $minf_max );
    $opt->set_ftol_rel( $ftol_rel );
    $opt->set_ftol_abs( $ftol_abs );

    $opt->set_xtol_abs( $xtol_abs ) if $xtol_abs;
    $opt->set_maxeval( $maxeval );
    $opt->set_maxtime( $maxtime );

    @$x = @{ $opt->optimize( $x ) };

    $$minf = $opt->last_optimum_value;
    return $opt->last_optimize_result;

}

sub main {
    my $d = lorentzdata->new;

    my ( $A, $w, $G, $noise ) = ( 1, 0, 1, 0.01 );

    my @lb = ( -HUGE_VAL(), -HUGE_VAL(), 0 );
    my @ub = ( HUGE_VAL(), HUGE_VAL(), HUGE_VAL() );
    my @p  = ( 0, 1, 2 );
    my $minf;

    srand( 0 );

    $d->N( 200 );
    my ( $x, $y ) = ( $d->x, $d->y );
    for my $i ( 0 .. $d->N - 1 ) {
        $x->[$i] = urand( -.5, .5 ) * 8 * $G + $w;
        $y->[$i] = 2 * $noise * urand( -.5, .5 ) + $A / ( sqr( $x->[$i] - $w ) + $G * $G );
    }

    subtest NLOPT_LN_NEWUOA_BOUND => sub {
        # 94 minf=0.00639855 at A=1.00146, w=-0.000287406, G=1.00039
        $count = 0;
        nlopt_minimize( NLOPT_LN_NEWUOA_BOUND, 3, \&lorentzerr, $d, \@lb, \@ub, \@p, \$minf, -HUGE_VAL(),
            0, 0, 1e-6, undef, 0, 0 );

        is( {
                # count => $count,
                minf => $minf,
                A    => $p[0],
                w    => $p[1],
                G    => $p[2],
            },

            {
                # count => 94,
                minf => float(  0.00639855,  precision => 5 ),
                A    => float(  1.00146,     precision => 3 ),
                w    => float( -0.000287406, precision => 4 ),
                G    => float(  1.00039,     precision => 3 ),
            },
        );
    };


    subtest NLOPT_LN_COBYLA => sub {
        # 231 minf=0.00639851 at A=1.00137, w=-0.000287383, G=1.00033
        $count = 0;
        nlopt_minimize( NLOPT_LN_COBYLA, 3, \&lorentzerr, $d, \@lb, \@ub, \@p, \$minf, -HUGE_VAL(), 0, 0,
            1e-6, undef, 0, 0 );

        is( {
                # count => $count,
                minf => $minf,
                A    => $p[0],
                w    => $p[1],
                G    => $p[2],
            },

            {
                # count => 137,
                minf => float(  0.00639851,  precision => 5 ),
                A    => float(  1.0013,      precision => 3 ),
                w    => float( -0.000287383, precision => 4 ),
                G    => float(  1.0003,      precision => 4 ),
            },
        );
    };

    subtest NLOPT_LN_NELDERMEAD => sub {
        # 118 minf=0.00639851 at A=1.00135, w=-0.000277813, G=1.00032
        $count = 0;
        nlopt_minimize( NLOPT_LN_NELDERMEAD, 3, \&lorentzerr, $d, \@lb, \@ub, \@p, \$minf, -HUGE_VAL(), 0,
            0, 1e-6, undef, 0, 0 );
        is( {
                # count => $count,
                minf => $minf,
                A    => $p[0],
                w    => $p[1],
                G    => $p[2],
            },

            {
                # count => 118,
                minf => float(  0.00639851,  precision => 5 ),
                A    => float(  1.00135,     precision => 5 ),
                w    => float( -0.000277813, precision => 5 ),
                G    => float(  1.00032,     precision => 5 ),
            },
        );
    };


    subtest NLOPT_LN_SBPLX => sub {
        # 102 minf=0.00639851 at A=1.00135, w=-0.00027781, G=1.00032
        $count = 0;
        nlopt_minimize( NLOPT_LN_SBPLX, 3, \&lorentzerr, $d, \@lb, \@ub, \@p, \$minf, -HUGE_VAL(), 0, 0,
            1e-6, undef, 0, 0 );
        is( {
                # count => $count,
                minf => $minf,
                A    => $p[0],
                w    => $p[1],
                G    => $p[2],
            },

            {
                # count => 102,
                minf => float(  0.00639851, precision => 5 ),
                A    => float(  1.00135,    precision => 5 ),
                w    => float( -0.00027781, precision => 5 ),
                G    => float(  1.00032,    precision => 5 ),
            },
        );
    };

}

main();
done_testing;
