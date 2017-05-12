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
use Math::GSL::Multimin (qw( :all ));       # for minimizer types (conjugate_fr)
use Games::Go::AGA::BayRate::GSL::Multimin  # use this hack instead of Math::GSL::Multimin
    qw(
        my_gsl_multimin_fminimizer_set
        raw_gsl_multimin_fminimizer_fval
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

minimize();

exit(0);

# debug aid
use Devel::Peek;
sub print_vector {
    my ($v, $count) = @_;

    $v = $v->raw if (ref $v eq 'Math::GSL::Vector');
#Dump($v);
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

# return the value of the function (specified by $params) at $v
sub my_f {
    my ($raw_v, $params) = @_;

print("my_f v:\n"); print_vector($raw_v);

    my $x = gsl_vector_get($raw_v, 0);
    my $y = gsl_vector_get($raw_v, 1);
    my $ret = $params->[$PAR_SCALE_X] * ($x - $params->[$PAR_CENTER_X]) * ($x - $params->[$PAR_CENTER_X])
            + $params->[$PAR_SCALE_Y] * ($y - $params->[$PAR_CENTER_Y]) * ($y - $params->[$PAR_CENTER_Y])
            + $params->[$PAR_MINIMUM];
printf("my_f returns % .24g,  v:\n", $ret); print_vector($raw_v);
    return $ret;
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
#print("init x:\n"); print_vector($x);
    # step size (1.0, 1.0)
    my $ss = Math::GSL::Vector->new([1.0, 1.0]);

    # minimizer 'state'
    my $state = my_gsl_multimin_fminimizer_set (
        $gsl_multimin_fminimizer_nmsimplex,    # minimizer type
        # gsl_multimin_function_f structure members:
            \&my_f,     # f       function
            2,          # n       number of free variables
            \@params,   # params  function params passed to f
        # end of gsl_multimin_function_f structure members:
        $x->raw,    # starting point vector
        $ss->raw,   # step size
     );

    my $iter = 0;
    my $status = $GSL_CONTINUE;

    while(     $status == $GSL_CONTINUE
           and $iter <= 100) {
        $iter++;
        $status = gsl_multimin_fminimizer_iterate($state);

        last if ($status);

        my $size = gsl_multimin_fminimizer_size ($state);
        $status = gsl_multimin_test_size($size, 1e-2);

        if ($status == $GSL_SUCCESS) {
            print "\nConverged to minimum at\n";
        }
        my $raw_x = gsl_multimin_fminimizer_x($state);
        printf("%5d %10.3e %10.3e f() = %7.3f size = %.3f\n",
            $iter,
            gsl_vector_get($raw_x, 0),
            gsl_vector_get($raw_x, 1),
          # gsl_multimin_fminimizer_fval($state),    # hmm, struct member, not a function
                                                    # ok, do it this way instead:
          raw_gsl_multimin_fminimizer_fval($state),
            $size,
        );
    }

    if ($status != $GSL_SUCCESS) {
        print "Error: ", gsl_strerror($status), "\n";
    }

    return $status;
}
