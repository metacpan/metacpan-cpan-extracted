#!/usr/bin/perl
#===============================================================================
#
#     ABSTRACT: Implement the example at http://www.gnu.org/software/gsl/manual/html_node/Multimin-Examples.html
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@hellosix.com
#      CREATED:  05/25/2011 09:41:15 AM
#===============================================================================

use strict;
use warnings;

# use Math::GSL qw( :all );
use Math::GSL::Vector qw( :all );
use Math::GSL::Errno  qw( :all );           # for GSL_SUCCESS and GSL_CONTINUE
use Math::GSL::Multimin qw(
    $gsl_multimin_fdfminimizer_conjugate_fr
    gsl_multimin_fdfminimizer_iterate
    gsl_multimin_fdfminimizer_gradient
    gsl_multimin_test_gradient
    gsl_multimin_fdfminimizer_x
);
use Games::Go::AGA::BayRate::GSL::Multimin  # use this hack instead of Math::GSL::Multimin
    qw(
        my_gsl_multimin_fdfminimizer_set
        raw_gsl_multimin_fdfminimizer_f
        raw_gsl_vector_size
    );

use Readonly;

our $VERSION = '0.104'; # VERSION

# param indices:
Readonly my $PAR_CENTER_X => 0;
Readonly my $PAR_CENTER_Y => 1;
Readonly my $PAR_SCALE_X  => 2;
Readonly my $PAR_SCALE_Y  => 3;
Readonly my $PAR_MINIMUM  => 4;

# debug aid
sub print_vector {
    my ($v, $count) = @_;

    $v = $v->raw if (ref $v eq 'Math::GSL::Vector');
    if (not $count or $count <= 0) {
        $count = raw_gsl_vector_size($v);
    }
    my $ii;
    for ($ii = 0; $ii < $count; $ii ++) {
        if ($ii % 10 == 0) { printf("%3d:", $ii); }
        printf(" % .24g", gsl_vector_get($v, $ii));
        if ($ii % 10 == 9) { print("\n"); }
    }
    if ($ii % 10 != 0) { print("\n"); }
}

# return the value of the function (specified by $params) at $raw_v
sub my_f {
    my ($raw_v, $params) = @_;

print("my_f v:\n"); print_vector($raw_v);
    my $x = gsl_vector_get($raw_v, 0);
    my $y = gsl_vector_get($raw_v, 1);
    my $ret = $params->[$PAR_SCALE_X] * ($x - $params->[$PAR_CENTER_X]) * ($x - $params->[$PAR_CENTER_X])
            + $params->[$PAR_SCALE_Y] * ($y - $params->[$PAR_CENTER_Y]) * ($y - $params->[$PAR_CENTER_Y])
            + $params->[$PAR_MINIMUM];
printf("my_f returns % .24g,  v:\n", $ret);
print_vector($raw_v);
    return $ret;
}

# The value of the first derivative of f, df = (df/dx, df/dy) at $raw_v
sub my_df {
    my ($raw_v, $params, $raw_df) = @_;

# print("my_df: v:\n"); print_vector($raw_v);
# print("my_df: df:\n"); print_vector($raw_df);
    my $x = gsl_vector_get($raw_v, 0);
    my $y = gsl_vector_get($raw_v, 1);

    gsl_vector_set($raw_df, 0, 2.0 * $params->[$PAR_SCALE_X] * ($x - $params->[$PAR_CENTER_X]));
    gsl_vector_set($raw_df, 1, 2.0 * $params->[$PAR_SCALE_Y] * ($y - $params->[$PAR_CENTER_Y]));
# print("my_df returns df:\n"); print_vector($raw_df);
}

# Compute both f and df together. set ${$f} to the value of f and $raw_df to the
# value of the derivative
sub my_fdf {
    my ($raw_x, $params, $f, $raw_df) = @_;

# print("my_fdf: v:\n"); print_vector($raw_x);
# print("my_fdf: df:\n"); print_vector($raw_df);
    ${$f} = my_f($raw_x, $params);
    my_df($raw_x, $params, $raw_df);
# printf("my_fdf returns f=% .24g, df:\n", ${$f} ); print_vector($raw_df);
}

sub minimize {

    # Paraboloid center at (1,2), scale factors (10, 20),
    #   minimum value 30
    my @params = (
        1.0,    # $PAR_CENTER_X
        2.0,    # $PAR_CENTER_Y
        10.0,   # $PAR_SCALE_X
        20.0,   # $PAR_SCALE_Y
        30.0    # $PAR_MINIMUM
    );

    # Starting point (5, 7)
    my $x = Math::GSL::Vector->new([5.0, 7.0]);

    # minimizer 'state'
    my $state = my_gsl_multimin_fdfminimizer_set (
        $gsl_multimin_fdfminimizer_conjugate_fr,    #minimizer type
        # gsl_multimin_function_fdf structure members:
            \&my_f,     # f       function
            \&my_df,    # df      derivative of f
            \&my_fdf,   # fdf     f and df
            2,          # n       number of free variables
            \@params,   # params  function params passed to f, df, and fdf
        # end of gsl_multimin_function_fdf structure members:
        $x->raw,    # starting point vector
        0.01,       # step size
        1e-4,       # accuracy
     );

    my $iter = 0;
    my $status = $GSL_CONTINUE;

    while(     $status == $GSL_CONTINUE
           and $iter <= 100) {
        $iter++;
        $status = gsl_multimin_fdfminimizer_iterate($state);

        last if ($status);

        my $gradient = gsl_multimin_fdfminimizer_gradient($state);
        $status = gsl_multimin_test_gradient($gradient, 1e-3);

        if ($status == $GSL_SUCCESS) {
            print "\nConverged to minimum at\n";
        }
        my $raw_x = gsl_multimin_fdfminimizer_x($state);
        printf("%5d %.5f %.5f %10.5f\n",
            $iter,
            gsl_vector_get($raw_x, 0),
            gsl_vector_get($raw_x, 1),
          # gsl_multimin_fdfminimizer_f($state),    # hmm, no such function?
                                                    # ok, do it this way instead:
            raw_gsl_multimin_fdfminimizer_f($state),
        );
    }

    if ($status != $GSL_SUCCESS) {
        print "Error: ", gsl_strerror($status), "\n";
    }

    return $status;
}

minimize();
