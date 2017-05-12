# Math::ODE

Solve N-th Order Ordinary Differential Equations

[![Build Status](https://secure.travis-ci.org/leto/math--ode.png)](http://travis-ci.org/leto/math--ode)

# Description

This module allows you to solve N-th Order Ordinary Differential Equations with
as little pain as possible.  Currently, only IVP's (initial value problems) are
supported, but native support for BVP's (boundary value problems) may be added
in the future. To solve N-th order equations, you must first turn it into a
system of N first order equations, as in MATLAB.

# Synopsis

        use Math::ODE;
        # create new object that stores data in a file
        # and solve the given equation(s) on the interval
        # [0,10], with initial condition y(t0) = 0
        my $o = new Math::ODE ( file => '/home/user/ode-values.txt',
                        step => 0.1,
                        initial => [0],
                        DE => [ \&DE1 ],
                        t0 => 1,
                        tf => 10 );
        $o->evolve();
        # solve the equation y' = 1/$t
        # $t is the independent variable, a scalar
        # $y is the dependent variable, an array reference
        sub DE1 { my ($t,$y) = @_; return 1/$t; }


# Authors

    Jonathan "Duke" Leto <jonathan@leto.net>
