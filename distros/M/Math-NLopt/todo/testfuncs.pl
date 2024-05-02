#! perl

use Test2::V0;

use experimental 'signatures', 'declared_refs';

# use Math::NLopt ':constants';

use Math::Trig 'pi';


sub sqr ( $x ) {
    return $x * $x;
}

#define return(f) return testfuncs_status(n, x, f);

use constant {
    PI2 => 6.283185307179586,    # 2*pi
    PI3 => 9.424777960769379,    #3*pi
    PI4 => 12.5663706143592,     # 4*p
};

#****************************************************************************
sub rosenbrock_f ( $n, $x, $grad, $data ) {
    my \@x = $x;

    my $a = $x[1] - $x[0] * $x[0];
    my $b = 1 - $x[0];

    if ( $grad ) {
        my \@grad = $grad;
        $grad[0] = -400 * $a * $x[0] - 2 * $b;
        $grad[1] = 200 * $a;
    }
    return 100 * sqr( $a ) + sqr( $b );
}

my @rosenbrock_lb   = ( -2, -2 );
my @rosenbrock_ub   = ( 2,  2 );
my @rosenbrock_xmin = ( 1,  1 );

#****************************************************************************
sub mccormic_f ( $n, $x, $grad, $data ) {
    my \@x = $x;

    my $a = $x[0] + $x[1];
    my $b = $x[0] - $x[1];

    if ( $grad ) {
        my \@grad = $grad;
        $grad[0] = cos( $a ) + 2 * $b - 1.5;
        $grad[1] = cos( $a ) - 2 * $b + 2.5;
    }

    return sin( $a ) + sqr( $b ) - 1.5 * $x[0] + 2.5 * $x[1] + 1;
}

my @mccormic_lb   = ( -1.5,         -3 );
my @mccormic_ub   = ( 4,            4 );
my @mccormic_xmin = ( -0.547197553, -1.54719756 );

#****************************************************************************
sub boxbetts_f ( $n, $x, $grad, $data ) {
    my $i;
    my $f = 0;
    my \@x = $x;

    if ( $grad ) {
        $grad->@* = ( 0 ) x $n;
    }

    for my $i ( 1 .. 10 ) {

        my $e0 = exp( -0.1 * $i * $x[0] );
        my $e1 = exp( -0.1 * $i * $x[1] );
        my $e2 = exp( -0.1 * $i ) - exp( -1.0 * $i );
        my $g  = $e0 - $e1 - $e2 * $x[2];
        $f += sqr( $g );
        if ( $grad ) {
            my \@grad = $grad;
            $grad[0] += ( 2 * $g ) * ( -0.1 * $i * $e0 );
            $grad[1] += ( 2 * $g ) * ( 0.1 * $i * $e1 );
            $grad[2] += -( 2 * $g ) * $e2;
        }
    }
    return $f;
}

my @boxbetts_lb   = ( 0.9, 9,    0.9 );
my @boxbetts_ub   = ( 1.2, 11.2, 1.2 );
my @boxbetts_xmin = ( 1,   10,   1 );

#****************************************************************************
sub paviani_f ( $n, $x, $grad, $data ) {

    my \@x   = 0;
    my $f    = 0;
    my $prod = 1;

    if ( $grad ) {
        $grad->@* = ( 0 ) x $n;
    }

    for my $i ( 0 .. 9 ) {
        my $ln1 = log( $x[$i] - 2 );
        my $ln2 = log( 10 - $x[$i] );
        $f += sqr( $ln1 ) + sqr( $ln2 );
        if ( $grad ) {
            $grad->[$i] += 2 * $ln1 / ( $x[$i] - 2 ) - 2 * $ln2 / ( 10 - $x[$i] );
        }
        $prod *= $x[$i];
    }
    $f -= ( $prod = pow( $prod, 0.2 ) );
    if ( $grad ) {
        $grad->[$_] -= 0.2 * $prod / $x[$_] for 0 .. 9;
    }
    return ( $f );
}

my @paviani_lb   = ( 2.001, 2.001, 2.001, 2.001, 2.001, 2.001, 2.001, 2.001, 2.001, 2.001 );
my @paviani_ub   = ( 9.999, 9.999, 9.999, 9.999, 9.999, 9.999, 9.999, 9.999, 9.999, 9.999 );
my @paviani_xmin = (
    9.35026583, 9.35026583, 9.35026583, 9.35026583, 9.35026583, 9.35026583,
    9.35026583, 9.35026583, 9.35026583, 9.35026583
);

#****************************************************************************
sub grosenbrock_f ( $n, $x, $grad, $data ) {
    my \@x = $x;
    my $f = 0;
    if ( $grad ) {
        $grad->[0] = 0;
    }
    for my $i ( 0 .. 28 ) {
        my $a = $x[ $i + 1 ] - $x[$i] * $x[$i];
        my $b = 1 - $x[$i];
        if ( $grad ) {
            $grad->[$i] += -400 * $a * $x[$i] - 2 * $b;
            $grad->[ $i + 1 ] = 200 * $a;
        }
        $f += 100 * sqr( $a ) + sqr( $b );
    }
    return ( $f );
}

my @grosenbrock_lb = (
    -30, -30, -30, -30, -30, -30, -30, -30, -30, -30, -30, -30, -30, -30, -30, -30,
    -30, -30, -30, -30, -30, -30, -30, -30, -30, -30, -30, -30, -30, -30
);
my @grosenbrock_ub = (
    30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30,
    30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30
);
my @grosenbrock_xmin
  = ( 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 );

#****************************************************************************
sub goldsteinprice_f ( $n, $x, $grad, $data ) {
    my \@x = $x;

    my $x0  = $x[0];
    my $x1  = $x[1];
    my $a1  = $x0 + $x1 + 1;
    my $a12 = sqr( $a1 );
    my $a2  = 19 - 14 * $x0 + 3 * $x0 * $x0 - 14 * $x1 + 6 * $x0 * $x1 + 3 * $x1 * $x1;
    my $b1  = 2 * $x0 - 3 * $x1;
    my $b12 = sqr( $b1 );
    my $b2  = 18 - 32 * $x0 + 12 * $x0 * $x0 + 48 * $x1 - 36 * $x0 * $x1 + 27 * $x1 * $x1;

    if ( $grad ) {
        my \@grad = $grad;
        $grad[0] = ( 1 + $a12 * $a2 ) * ( 2 * $b1 * 2 * $b2 + $b12 * ( -32 + 24 * $x0 - 36 * $x1 ) )
          + ( 2 * $a1 * $a2 + $a12 * ( -14 + 6 * $x0 + 6 * $x1 ) ) * ( 30 + $b12 * $b2 );
        $grad[1] = ( 1 + $a12 * $a2 ) * ( 2 * $b1 * ( -3 ) * $b2 + $b12 * ( 48 - 36 * $x0 + 54 * $x1 ) )
          + ( 2 * $a1 * $a2 + $a12 * ( -14 + 6 * $x0 + 6 * $x1 ) ) * ( 30 + $b12 * $b2 );
    }
    return ( ( 1 + $a12 * $a2 ) * ( 30 + $b12 * $b2 ) );
}

my @goldsteinprice_lb   = ( -2, -2 );
my @goldsteinprice_ub   = ( 2,  2 );
my @goldsteinprice_xmin = ( 0,  -1 );

#****************************************************************************
sub shekel_f ( $n, $x, $grad, $data ) {
    my \@x = $x;
    my @A = (
        [ 4, 4,   4, 4 ],
        [ 1, 1,   1, 1 ],
        [ 8, 8,   8, 8 ],
        [ 6, 6,   6, 6 ],
        [ 3, 7,   3, 7 ],
        [ 2, 9,   2, 9 ],
        [ 5, 5,   3, 3 ],
        [ 8, 1,   8, 1 ],
        [ 6, 2,   6, 2 ],
        [ 7, 3.6, 7, 3.6 ],
    );

    my @c = ( .1, .2, .2, .4, .4, .6, .3, .7, .5, .5 );

    my $f = 0;
    my $m = $data;
    if ( $grad ) {
        $grad->@* = ( 0 ) x $n;
    }

    for my $i ( 0 .. $m - 1 ) {
        my $fi
          = 1.0 / ( $c[$i]
              + sqr( $x[0] - $A[$i][0] )
              + sqr( $x[1] - $A[$i][1] )
              + sqr( $x[2] - $A[$i][2] )
              + sqr( $x[3] - $A[$i][3] ) );
        $f -= $fi;
        if ( $grad ) {
            my \@grad = $grad;
            $grad[0] += ( 2 * $fi * $fi ) * ( $x[0] - $A[$i][0] );
            $grad[1] += ( 2 * $fi * $fi ) * ( $x[1] - $A[$i][1] );
            $grad[2] += ( 2 * $fi * $fi ) * ( $x[2] - $A[$i][2] );
            $grad[3] += ( 2 * $fi * $fi ) * ( $x[3] - $A[$i][3] );
        }
    }
    return ( $f );
}

my @shekel_m     = ( 5,           7,           10 );
my @shekel_lb    = ( 0,           0,           0,           0 );
my @shekel_ub    = ( 10,          10,          10,          10 );
my @shekel0_xmin = ( 4.000037154, 4.000133276, 4.000037154, 4.000133276 );
my @shekel1_xmin = ( 4.000572917, 4.000689366, 3.999489709, 3.999606158 );
my @shekel2_xmin = ( 4.000746531, 4.000592935, 3.999663399, 3.999509801 );

#****************************************************************************
sub levy_f ( $n, $x, $grad, $data ) {
    my \@x = $x;
    unsigned i;
    my $a = $x[ $n - 1 ] - 1;
    my $b = 1 + sqr( sin( PI2 * $x[ $n - 1 ] ) );
    my $f = sqr( sin( PI3 * $x[0] ) ) + $a * $b;

    if ( $grad ) {
        my \@grad = $grad;
        @grad = 0;
        $grad[0] = 2 * PI3 * sin( PI3 * $x[0] ) * cos( PI3 * $x[0] );
        $grad[ $n - 1 ] += $b + $a * 2 * PI2 * sin( PI2 * $x[ $n - 1 ] ) * cos( PI2 * $x[ $n - 1 ] );
    }
    for my $i ( 0 .. $n - 1 ) {
        $a = $x[$i] - 1;
        $b = 1 + sqr( sin( PI3 * $x[ $i + 1 ] ) );
        $f += sqr( $a ) * $b;
        if ( $grad ) {
            my \@grad = $grad;
            $grad[$i] += 2 * $a * $b;
            $grad[ $i + 1 ] += 2 * PI3 * sqr( $a ) * sin( PI3 * $x[ $i + 1 ] ) * cos( PI3 * $x[ $i + 1 ] );
        }
    }
    return ( $f );
}

my @levy_lb    = ( -5,  -5,  -5,  -5, -5, -5, -5 );
my @levy_ub    = ( 5,   5,   5,   5,  5,  5,  5 );
my @levy_xmin  = ( 1,   1,   1,   1,  1,  1,  -4.75440246 );
my @levy4_lb   = ( -10, -10, -10, -10 );
my @levy4_ub   = ( 10,  10,  10,  10 );
my @levy4_xmin = ( 1,   1,   1,   -9.75235596 );

#****************************************************************************
sub griewank_f ( $n, $x, $grad, $data ) {
    my \@x = $x;
    unsigned i;
    my $f = 1;
    my $p = 1;

    for my $i ( 0 .. $n - 1 ) {
        $f += sqr( $x[$i] ) * 0.00025;
        $p *= cos( $x[$i] / sqrt( $i + 1. ) );
        if ( $grad ) {
            $grad->[$i] = $x[$i] * 0.0005;
        }
    }
    $f -= $p;
    if ( $grad ) {
        for my $i ( 0 .. $n - 1 ) {
            $grad->[$i] += $p * tan( $x[$i] / sqrt( $i + 1. ) ) / sqrt( $i + 1. );
        }
    }
    return ( $f );
}

my @griewank_lb   = ( -500, -500, -500, -500, -500, -500, -500, -500, -500, -500 );
my @griewank_ub   = ( 600,  600,  600,  600,  600,  600,  600,  600,  600,  600 );
my @griewank_xmin = ( 0,    0,    0,    0,    0,    0,    0,    0,    0,    0 );

#****************************************************************************
sub sixhumpcamel_f ( $n, $x, $grad, $data ) {
    my \@x = $x;

    if ( $grad ) {
        my \@grad = $grad;
        $grad[0] = 8 * $x[0] - 2.1 * 4 * pow( $x[0], 3. ) + 2 * pow( $x[0], 5. ) + $x[1];
        $grad[1] = $x[0] - 8 * $x[1] + 16 * pow( $x[1], 3. );
    }
    return (4 * sqr( $x[0] )
          - 2.1 * pow( $x[0], 4. )
          + pow( $x[0], 6. ) / 3.
          + $x[0] * $x[1]
          - 4 * sqr( $x[1] )
          + 4 * pow( $x[1], 4. ) );
}

my @sixhumpcamel_lb   = ( -5,            -5 );
my @sixhumpcamel_ub   = ( 5,             5 );
my @sixhumpcamel_xmin = ( 0.08984201317, -0.7126564032 );

#****************************************************************************
sub convexcosh_f ( $n, $x, $grad, $data ) {
    my \@x = $x;
    my $f = 1;

    for my $i ( 0 .. $n - 1 ) {
        $f *= cosh( ( $x[$i] - $i ) * ( $i + 1 ) );
    }
    if ( $grad ) {
        my \@grad = $grad;
        for my $i ( 0 .. $n - 1 ) {
            $grad[$i] = $f * tanh( ( $x[$i] - $i ) * ( $i + 1 ) ) * ( $i + 1 );
        }
    }
    return ( $f );
}

my @convexcosh_lb   = ( -1, 0, 0, 0, 0, 0,  0,  0,  0,  0 );
my @convexcosh_ub   = ( 2,  3, 6, 7, 8, 10, 11, 13, 14, 16 );
my @convexcosh_xmin = ( 0,  1, 2, 3, 4, 5,  6,  7,  8,  9 );


#****************************************************************************
sub branin_f ( $n, $x, $grad, $data ) {
    my \@x = $x;
    my $a  = 1 - 2 * $x[1] + 0.05 * sin( PI4 * $x[1] ) - $x[0];
    my $b  = $x[1] - 0.5 * sin( PI2 * $x[0] );

    if ( $grad ) {
        my \@grad = $grad;
        $grad[0] = -2 * $a - cos( PI2 * $x[0] ) * PI2 * $b;
        $grad[1] = 2 * $a * ( 0.05 * PI4 * cos( PI4 * $x[1] ) - 2 ) + 2 * $b;
    }
    return ( sqr( $a ) + sqr( $b ) );
}


my @branin_lb   = ( -10, -10 );
my @branin_ub   = ( 10,  10 );
my @branin_xmin = ( 1,   0 );

#****************************************************************************
sub shubert_f ( $n, $x, $grad, $data ) {
    my \@x = $x;
    my $f = 0;

    for my $j ( 1 .. 5 ) {
        for my $i ( 0 .. $n - 1 ) {
            $f -= $j * sin( ( $j + 1 ) * $x[$i] + $j );
        }
    }
    if ( $grad ) {
        my \@grad = $grad;
        for my $i ( 0 .. $n - 1 ) {
            $grad[$i] = 0;
            for my $j ( 1 .. 5 ) {
                $grad[$i] -= $j * ( $j + 1 ) * cos( ( $j + 1 ) * $x[$i] + $j );
            }
        }
    }
    return ( $f );
}

my @shubert_lb   = ( -10,          -10 );
my @shubert_ub   = ( 10,           10 );
my @shubert_xmin = ( -6.774576143, -6.774576143 );


#****************************************************************************
sub hansen_f ( $n, $x, $grad, $data ) {
    my \@x = $x;
    unsigned i;
    my $a = 0;
    my $b = 0;

    for my $i ( 1 .. 5 ) {
        $a += $i * cos( ( $i - 1 ) * $x[0] + $i );
    }
    for my $i ( 1 .. 5 ) {
        $b += $i * cos( ( $i + 1 ) * $x[1] + $i );
    }
    if ( $grad ) {
        my \@grad = $grad;
        $grad[0] = 0;
        for my $i ( 1 .. 5 ) {
            $grad[0] -= $i * ( $i - $1 ) * sin( ( $i - 1 ) * $x[0] + $i );
        }
        $grad[0] *= $b;
        $grad[1] = 0;
        for my $i ( 1 .. 5 ) {
            $grad[1] -= $i * ( $i + 1 ) * sin( ( $i + 1 ) * $x[1] + $i );
        }
        $grad[1] *= $a;
    }
    return ( $a * $b );
}


my @hansen_lb   = ( -10,          -10 );
my @hansen_ub   = ( 10,           10 );
my @hansen_xmin = ( -1.306707704, -1.425128429 );


#****************************************************************************
sub osc1d_f ( $n, $x, $grad, $data ) {
    my \@x = $x;
    my $y = $x[0] - 1.23456789;

    if ( $grad ) {
        my \@grad = $grad;
        $grad[0] = $y * 0.02 + sin( $y - 2 * sin( 3 * $y ) ) * ( 1 - 6 * cos( 3 * $y ) );
    }
    return ( sqr( $y * 0.1 ) - cos( $y - 2 * sin( 3 * $y ) ) );
}

my @osc1d_lb   = ( -5 );
my @osc1d_ub   = ( 5 );
my @osc1d_xmin = ( 1.23456789 );

#****************************************************************************
sub corner4d_f ( $n, $x, $grad, $data ) {
    my \@x = $x;
    my $u  = $x[0] + $x[1] * $x[2] * sin( 2 * $x[3] );
    my $v  = $x[0] + 2 * sin( $u );

    if ( $grad ) {
        my \@grad = $grad;
        $grad[0] = 2 * $v * ( 1 + 2 * cos( $u ) );
        $grad[1] = 2 * $v * 2 * cos( $u ) * $x[2] * sin( 2 * $x[3] ) + 0.1;
        $grad[2] = 2 * $v * 2 * cos( $u ) * $x[1] * sin( 2 * $x[3] ) + 0.1;
        $grad[3] = 2 * $v * 2 * cos( $u ) * $x[1] * $x[2] * cos( 2 * $x[3] ) * 2 + 0.1;
    }
    return ( 1 + $v * $v + 0.1 * ( $x[1] + $x[2] + $x[3] ) );
}

my @corner4d_lb   = ( 0, 0, 0, 0 );
my @corner4d_ub   = ( 1, 1, 1, 1 );
my @corner4d_xmin = ( 0, 0, 0, 0 );

#****************************************************************************
sub side4d_f ( $n, $x, $grad, $data ) {
    my \@x = $x;
    my $w0 = 0.1;
    my $w1 = 0.2;
    my $w2 = 0.3;
    my $w3 = 0.4;


    my $x0 = +0.4977 * $x[0] - 0.3153 * $x[1] - 0.5066 * $x[2] - 0.4391 * $x[3];
    my $x1 = -0.3153 * $x[0] + 0.3248 * $x[1] - 0.4382 * $x[2] - 0.4096 * $x[3];
    my $x2 = -0.5066 * $x[0] - 0.4382 * $x[1] + 0.3807 * $x[2] - 0.4543 * $x[3];
    my $x3 = -0.4391 * $x[0] - 0.4096 * $x[1] - 0.4543 * $x[2] + 0.5667 * $x[3];

    my $d0 = -1. / ( $x0 * $x0 + $w0 * $w0 );
    my $d1 = -1. / ( $x1 * $x1 + $w1 * $w1 );
    my $d2 = -1. / ( $x2 * $x2 + $w2 * $w2 );
    my $d3 = -1. / ( $x3 * $x3 + $w3 * $w3 );

    if ( $grad ) {
        my \@grad = $grad;
        $grad[0]
          = 2 * ( $x0 * $d0 * $d0 * +0.4977
              + $x1 * $d1 * $d1 * -0.3153
              + $x2 * $d2 * $d2 * -0.5066
              + $x3 * $d3 * $d3 * -0.4391 );
        $grad[1]
          = 2 * ( $x0 * $d0 * $d0 * -0.3153
              + $x1 * $d1 * $d1 * +0.3248
              + $x2 * $d2 * $d2 * -0.4382
              + $x3 * $d3 * $d3 * -0.4096 );
        $grad[2]
          = 2 * ( $x0 * $d0 * $d0 * -0.5066
              + $x1 * $d1 * $d1 * -0.4382
              + $x2 * $d2 * $d2 * +0.3807
              + $x3 * $d3 * $d3 * -0.4543 );
        $grad[3]
          = 2 * ( $x0 * $d0 * $d0 * -0.4391
              + $x1 * $d1 * $d1 * -0.4096
              + $x2 * $d2 * $d2 * -0.4543
              + $x3 * $d3 * $d3 * +0.5667 );
    }
    return ( $d0 + $d1 + $d2 + $d3 );
}

my @side4d_lb   = ( 0.1, -1,          -1,           -1 );
my @side4d_ubs  = ( 1,   1,           1,            1 );
my @side4d_xmin = ( 0.1, 0.102971169, 0.0760520641, -0.0497098571 );

#****************************************************************************
#****************************************************************************

my @testfuncs = (

    [
        \&rosenbrock_f,  undef,           1,                 2,
        \&rosenbrock_lb, \&rosenbrock_ub, \&rosenbrock_xmin, 0.0,
        "Rosenbrock function"
    ],

    [
        \&mccormic_f,  undef,         1,               2,
        \&mccormic_lb, \&mccormic_ub, \&mccormic_xmin, -1.91322295,
        "McCormic function"
    ],
    [
        \&boxbetts_f, undef, 1, 3, \&boxbetts_lb, \&boxbetts_ub, \&boxbetts_xmin,
        0.0, "Box and Betts exponential quadratic sum"
    ],
    [
        \&paviani_f,  undef,        1,              10,
        \&paviani_lb, \&paviani_ub, \&paviani_xmin, -45.7784697,
        "Paviani function"
    ],
    [
        \&grosenbrock_f, undef, 1, 30, \&grosenbrock_lb, \&grosenbrock_ub, \&grosenbrock_xmin,
        0.0, "Generalized Rosenbrock function"
    ],
    [
        \&goldsteinprice_f, undef, 1, 2, \&goldsteinprice_lb, \&goldsteinprice_ub, \&goldsteinprice_xmin,
        3.0, "Goldstein and Price function"
    ],
    [
        \&shekel_f,  \&shekel_m +0, 1,              4,
        \&shekel_lb, \&shekel_ub,   \&shekel0_xmin, -10.15319968,
        "Shekel m=5 function"
    ],
    [
        \&shekel_f,  \&shekel_m + 1, 1,              4,
        \&shekel_lb, \&shekel_ub,    \&shekel1_xmin, -10.40294057,
        "Shekel m=7 function"
    ],
    [
        \&shekel_f,  \&shekel_m + 2, 1,              4,
        \&shekel_lb, \&shekel_ub,    \&shekel2_xmin, -10.53640982,
        "Shekel m=10 function"
    ],
    [ \&levy_f, undef, 1, 4, \&levy4_lb, \&levy4_ub, \&levy4_xmin,  -21.50235596, "Levy n=4 function" ],
    [ \&levy_f, undef, 1, 5, \&levy_lb, \&levy_ub, \&levy_xmin + 2, -11.50440302, "Levy n=5 function" ],
    [ \&levy_f, undef, 1, 6, \&levy_lb, \&levy_ub, \&levy_xmin + 1, -11.50440302, "Levy n=6 function" ],
    [ \&levy_f, undef, 1, 7, \&levy_lb, \&levy_ub, \&levy_xmin,     -11.50440302, "Levy n=7 function" ],
    [
        \&griewank_f,  undef,         1,               10,
        \&griewank_lb, \&griewank_ub, \&griewank_xmin, 0.0,
        "Griewank function"
    ],
    [
        \&sixhumpcamel_f, undef, 1, 2, \&sixhumpcamel_lb, \&sixhumpcamel_ub, \&sixhumpcamel_xmin,
        -1.031628453,     "Six-hump camel back function"
    ],
    [
        \&convexcosh_f, undef, 1, 10, \&convexcosh_lb, \&convexcosh_ub, \&convexcosh_xmin,
        1.0, "Convex product of cosh functions"
    ],
    [ \&branin_f, undef, 1, 2, \&branin_lb, \&branin_ub, \&branin_xmin, -.0, "Branin function" ],
    [
        \&shubert_f,  undef,        1,              2,
        \&shubert_lb, \&shubert_ub, \&shubert_xmin, -24.06249888,
        "Shubert function"
    ],
    [
        \&hansen_f,  undef,       1,             2,
        \&hansen_lb, \&hansen_ub, \&hansen_xmin, -176.5417931367,
        "Hansen function"
    ],
    [
        \&osc1d_f, undef, 1, 1, \&osc1d_lb, \&osc1d_ub, \&osc1d_xmin,
        -1.0,      "1d oscillating function with a single minimum"
    ],
    [
        \&corner4d_f, undef, 1, 4, \&corner4d_lb, \&corner4d_ub, \&corner4d_xmin,
        1.0, "4d function with minimum at corner"
    ],

    [
        \&side4d_f,     undef, 1, 4, \&side4d_lb, \&side4d_ub, \&side4d_xmin,
        -141.285020472, "4d function with minimum at side"
    ],

);
