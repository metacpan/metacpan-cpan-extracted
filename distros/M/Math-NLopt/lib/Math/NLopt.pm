package Math::NLopt;

# ABSTRACT: Math::NLopt - Perl interface to the NLopt optimization library

use v5.12;
use strict;
use warnings;

#<<<

our $VERSION = '0.11';

#>>>

# don't inherit.  We're a class by-golly, and don't want Exporter's methods.
use Exporter 'import';

use Math::NLopt::Exception;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Math::NLopt ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = (
    algorithms => [ qw(
          NLOPT_AUGLAG
          NLOPT_AUGLAG_EQ
          NLOPT_GD_MLSL
          NLOPT_GD_MLSL_LDS
          NLOPT_GD_STOGO
          NLOPT_GD_STOGO_RAND
          NLOPT_GN_AGS
          NLOPT_GN_CRS2_LM
          NLOPT_GN_DIRECT
          NLOPT_GN_DIRECT_L
          NLOPT_GN_DIRECT_L_NOSCAL
          NLOPT_GN_DIRECT_L_RAND
          NLOPT_GN_DIRECT_L_RAND_NOSCAL
          NLOPT_GN_DIRECT_NOSCAL
          NLOPT_GN_ESCH
          NLOPT_GN_ISRES
          NLOPT_GN_MLSL
          NLOPT_GN_MLSL_LDS
          NLOPT_GN_ORIG_DIRECT
          NLOPT_GN_ORIG_DIRECT_L
          NLOPT_G_MLSL
          NLOPT_G_MLSL_LDS
          NLOPT_LD_AUGLAG
          NLOPT_LD_AUGLAG_EQ
          NLOPT_LD_CCSAQ
          NLOPT_LD_LBFGS
          NLOPT_LD_MMA
          NLOPT_LD_SLSQP
          NLOPT_LD_TNEWTON
          NLOPT_LD_TNEWTON_PRECOND
          NLOPT_LD_TNEWTON_PRECOND_RESTART
          NLOPT_LD_TNEWTON_RESTART
          NLOPT_LD_VAR1
          NLOPT_LD_VAR2
          NLOPT_LN_AUGLAG
          NLOPT_LN_AUGLAG_EQ
          NLOPT_LN_BOBYQA
          NLOPT_LN_COBYLA
          NLOPT_LN_NELDERMEAD
          NLOPT_LN_NEWUOA
          NLOPT_LN_NEWUOA_BOUND
          NLOPT_LN_PRAXIS
          NLOPT_LN_SBPLX
          NLOPT_NUM_ALGORITHMS
        ),
    ],
    results => [ qw(
          NLOPT_FAILURE
          NLOPT_FORCED_STOP
          NLOPT_FTOL_REACHED
          NLOPT_INVALID_ARGS
          NLOPT_MAXEVAL_REACHED
          NLOPT_MAXTIME_REACHED
          NLOPT_MINF_MAX_REACHED
          NLOPT_NUM_FAILURES
          NLOPT_NUM_RESULTS
          NLOPT_OUT_OF_MEMORY
          NLOPT_ROUNDOFF_LIMITED
          NLOPT_STOPVAL_REACHED
          NLOPT_SUCCESS
          NLOPT_XTOL_REACHED
        ),
    ],
    utils => [ qw(
          algorithm_from_string
          algorithm_name
          algorithm_to_string
          result_from_string
          result_to_string
          srand
          srand_time
          version
        ),
    ],
);

$EXPORT_TAGS{all} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );


sub _croak {
    require Carp;
    goto \&Carp::croak;
}

# This AUTOLOAD is used to 'autoload' constants from the constant()
# XS function.

sub AUTOLOAD {    ## no critic (ClassHierarchies::ProhibitAutoload)

    my $constname;
    our $AUTOLOAD;
    ( $constname = $AUTOLOAD ) =~ s/.*:://;
    _croak Math::NLopt::Exception->new( 'Math::NLopt::constant not defined' )
      if $constname eq 'constant';
    my ( $error, $val ) = constant( $constname );
    if ( $error ) {
        _croak Math::NLopt::Exception->new( $error );
    }

    {
        no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)

        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load( 'Math::NLopt', $VERSION );

# Preloaded methods go here.

1;

#
# This file is part of Math-NLopt
#
# This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory PDL tunable en-masse
ndarrays

=head1 NAME

Math::NLopt - Math::NLopt - Perl interface to the NLopt optimization library

=head1 VERSION

version 0.11

=head1 SYNOPSIS

  use Math::NLopt ':algorithms';

  my $opt = Math::NLopt->new( NLOPT_LD_MMA, 2 );
  $opt->set_lower_bounds( [ -HUGE_VAL(), 0 ] );
  $opt->set_min_objective( sub ( $x, $grad, $data ) { ... } );
  $opt->set_xtol_rel( ... );
  \@optimized_pars = $opt->optimize( \@initial_pars );

=head1 DESCRIPTION

L<NLopt|https://github.com/stevengj/nlopt> is a

  library for nonlinear local and global optimization, for functions
  with and without gradient information. It is designed as a simple,
  unified interface and packaging of several free/open-source
  nonlinear optimization libraries.

B<Math::NLopt> is a Perl binding to B<NLopt>.  It uses the
L<Alien::NLopt> module to find or install a Perl local instance of the
B<NLopt> library.

This module provides an interface using native Perl arrays.

The main documentation for B<NLopt> may be found at L<<
https://nlopt.readthedocs.io/ >>; this document focuses on the
Perl specific implementation, which is more Perlish than the C API
(and is very similar to the Python one).

=head2 API

The Perl API uses an object, constructed by the L</new> class method,
to maintain state. The optimization process is controlled by
invoking methods on the object.

I<In general> results are returned directly from the methods; method
parameters are used primarily as input data for the methods (the
objective and constraint callbacks more closely follow the C API).

The Perl methods are named similarly to the C functions, e.g.

   nlopt_<method>( opt, ... );

becomes

  $opt->method( ... );

Where C<$opt> is provided by the L</new> class method.

As an example,  the C API for starting
the optimization process is

   nlopt_result nlopt_optimize(nlopt_opt opt, double *x, double *opt_f);

where B<x> is used for both passing in the initial model parameters as
well as retrieving their final values. The final value of the
optimization function is stored in B<opt_f>. A code specifying the
success or failure of the process is returned.

The Perl interface (similar to the Python and C++ versions) is

   \@final = $opt->optimize( \@initial_pars );
   $opt_f = $opt->last_optimum_value;
   $result_code = $opt->last_optimize_result;

The Perl API throws exceptions on failures, similar to the behavior of
the C++ and Python API's.  Where the C API returns error codes,
C<Math::NLopt> throws objects in similarly named exception classes:

  Math::NLopt::Exception::Failure
  Math::NLopt::Exception::OutOfMemory
  Math::NLopt::Exception::InvalidArgs
  Math::NLopt::Exception::RoundoffLimited>
  Math::NLopt::Exception::ForcedStop

These all extend the L<Math::NLopt::Exception> class; see it for more
information on retrieving messages from the objects.

=head2 Constants

B<Math::NLopt> defines constants for the optimization algorithms,
result codes, and utilities.

The algorithm constants have the same names as the B<NLopt> constants,
and may be imported individually by name or en-masse with the
':algorithms' tag:

  use Math::NLopt 'NLOPT_LD_MMA';
  use Math::NLopt ':algorithms';

Importing result codes is similar:

  use Math::NLopt 'NLOPT_FORCED_STOP';
  use Math::NLopt ':results';

As are the utility subroutines:

  use Math::NLopt 'algorithm_from_string';
  use Math::NLopt ':utils';

=head2 Callbacks

B<NLopt> handles the optimization of the objective function, relying
upon user provided subroutines to calculate the objective function and
non-linear constraints (see below for the required calling signature).

The callback subroutines are called with a user-provided structure
which can be used to pass additional information to the callback
(or the subroutines can use closures).

=head3 Objective Functions

Objective functions callbacks are registered via either

  $opt->set_min_objective( \&func, ?$data );
  $opt->set_max_objective( \&func, ?$data );

where C<$data> is an optional structure passed to the callback which
can be used for any purpose.

The objective function has the signature

  $value = sub ( \@params, \@gradient, $data ) { ... }

It returns the value of the optimization function for the
passed set parameters, B<@params>.

if B<\@gradient> is not C<undef>, it must be filled in by the
objective function.

C<$data> is the structure registered with the callback. It will be
C<undef> if none was provided.

=head2 Non-linear Constraints

Nonlinear constraint callbacks are registered via either of

  $opt->add_equality_constraint( \&func, ?$data, ?$tol = 0 );
  $opt->add_inequality_constraint( \&func, ?$data, ?$tol = 0 );

where C<$data> is an optional structure passed to the callback which
can be used for any purpose, and C<$tol> is a tolerance.  Pass
C<undef> for C<$data> if a tolerance is required but C<$data> is not.

The callbacks have the same signature as the objective callbacks.

=head3 Vector-valued Constraints

Vector-valued constraint callbacks are registered via either of

  $opt->add_equality_mconstraint( \&func, $m, ?$data, ?\@tol );
  $opt->add_inequality_mconstraint( \&func, $m, ?$data, ?\@tol );

where C<$m> is the length of the vector, C<$data> is an optional
structure passed on to the callback function, and C<@tol> is an
optional array of length C<$m> containing the tolerance for each
component of the vector

Vector valued constraints callbacks have the signature

  sub ( \@result, \@params, \@gradient, $data ) { ... }

The C<$m> length vector of constraints should be stored in C<\@result>.
If C<\@gradient> is not C<undef>, it is a I<< $n x $m >> length
array which should be filled by the callback.

C<$data> is the optional structure passed to the callback.

=head3 Preconditioned Objectives

These are registered via one of

  $opt->set_precond_min_objective( \&func, \&precond, ?$data);
  $opt->set_precond_max_objective( \&func, \&precond, ?$data);

C<\&func> has the same signature as before (see L</Objective Functions>),
and C<$data> is as before.

The C<\&precond> fallback has this signature:

   sub (\@x, \@v, \@vpre, $data) {...}

C<\@x>, C<\@v>, and C<\@vpre> are arrays of length C<$n>.
C<\@x>, C<\@v>  are input and C<\@vpre> should be filled in by the routine.

=head1 CONSTRUCTORS

=head2 new

  my $opt = Math::NLopt->new( $algorithm, $n );

Create an optimization object for the given algorithm and number of parameters.
B<$algorithm> is one of the algorithm constants, e.g.

  use Math::NLopt 'NLOPT_LD_MMA';
  my $opt = Math::NLopt->new( NLOPT_LD_MMA, 3 );

=head1 METHODS

Most methods have the same calling signature as their C versions, but
not all!

=head2 add_equality_constraint

  $opt->add_equality_constraint( \&func, ?$data, ?$tol = 0 );

=head2 add_equality_mconstraint

  $opt->add_equality_mconstraint( \&func, $m, ?$data, ?\@tol );

=head2 add_inequality_constraint

  $opt->add_inequality_constraint( \&func, ?$data, ?$tol = 0 );

=head2 add_inequality_mconstraint

  $opt->add_inequality_mconstraint( \&func, $m, ?$data, ?\@tol );

=head2 force_stop

  $opt->force_stop;

=head2 get_algorithm

  $algorithm_int_id = $opt->get_algorithm;

=head2 get_dimension

  $n = $opt->get_dimension;

=head2 get_errmsg

  $string  $opt->get_errmsg;

=head2 get_force_stop

  $stop = $opt->get_force_stop;

=head2 get_ftol_abs

  $tol = $opt->get_ftol_abs;

=head2 get_ftol_rel

  $tol = $opt->get_ftol_rel;

=head2 get_initial_step

  \@steps = $opt->get_initial_step( \@init_x );

=head2 get_lower_bounds

  \@lb = $opt->get_lower_bounds;

=head2 get_maxeval

  $max_eval = $opt->get_maxeval;

=head2 get_maxtime

  $max_time = $opt->get_maxtime;

=head2 get_numevals

  $num_evals = $opt->get_numevals;

=head2 get_param

  $val = $opt->get_param( $name, $defaultval);

Return parameter value, or C<$defaultval> if not set.

=head2 get_population

  $pop = $opt->get_population;

=head2 get_stopval

  $val = $opt->get_stopval;

=head2 get_upper_bounds

  \@ub = $opt->get_upper_bounds;

=head2 get_vector_storage

  $dim = $opt->get_vector_storage;

=head2 get_x_weights

  \@weights = $opt->get_x_weights;

=head2 get_xtol_abs

  \@tol = $opt->get_xtol_abs;

=head2 get_xtol_rel

  $tol = $opt->get_xtol_rel;

=head2 has_param

  $bool = $opt->has_param( $name );

True if the parameter with C<$name> was set.

=head2 nth_param

  $name = $opt->nth_param( $i );

Return the name of algorithm specific parameter C<$i>.

=head2 last_optimize_result

  $result_code = $opt->last_optimize_result;

Return the result code after an optimization.

=head2 last_optimum_value

  $min_f = $opt->last_optimum_value;

Return the objective value obtained after an optimization.

=head2 num_params

  $n_algo_params = $opt->num_params;

Return the number of algorithm specific parameters.

=head2 optimize

  \@optimized_pars = $opt->optimize( \@input_pars );

Returns the parameter values determined from the optimization.  The
status of the optimization (e.g. NLopt's result code) can be retrieved
via the L</last_optimize_result> method. The final value of the
objective function is available via the L</last_aptimum_value> method.

=head2 remove_equality_constraints

  $opt->remove_equality_constraints;

=head2 remove_inequality_constraints

  $opt->remove_inequality_constraints;

=head2 set_force_stop

  $opt->set_force_stop( $val );

=head2 set_ftol_abs

  $opt->set_ftol_abs( $tol );

=head2 set_ftol_rel

  $opt->set_ftol_rel( $tol );

=head2 set_initial_step

  $opt->set_initial_step(\@dx);

C<@dx> has length C<$n>.

=head2 set_initial_step1

  $opt->set_initial_step1( $dx );

=head2 set_local_optimizer

  $opt->set_local_optmizer( $local_opt );

=head2 set_lower_bound

  $opt->set_lower_bound( $i, $ub );

Set the lower bound for parameter C<$i> (zero based) to C<$ub>

=head2 set_lower_bounds

  $opt->set_lower_bounds(\@ub);

C<@ub> has length C<$n>.

=head2 set_lower_bounds1

  $opt->set_lower_bounds1 ($ub);

=head2 set_max_objective

  $opt->set_max_objective( \&func, ?$data );

See L<Objective Functions>

=head2 set_maxeval

   $opt->set_maxeval( $max_iterations );

=head2 set_maxtime

   $opt->set_maxtime( $time );

=head2 set_min_objective

  $opt->set_min_objective( \&func, ?$data );

See L<Objective Functions>

=head2 set_param

  $opt->set_param( $name, $value );

=head2 set_population

  $opt->set_population( $pop );

=head2 set_precond_max_objective

  $opt->set_precond_max_objective( \&func, \&precond, ?$data);

See L</Preconditioned Objectives>

=head2 set_precond_min_objective

  $opt->set_precond_min_objective( \&func, \&precond, ?$data);

See L</Preconditioned Objectives>

=head2 set_stopval

  $opt->set_stopval( $stopval);

=head2 set_upper_bound

  $opt->set_upper_bound( $i, $ub );

Set the upper bound for parameter C<$i> (zero based) to C<$ub>

=head2 set_upper_bounds

  $opt->set_upper_bounds(\@ub);

C<@ub> has length C<$n>.

=head2 set_upper_bounds1

  $opt->set_upper_bounds1 ($ub);

=head2 set_vector_storage

  $opt->set_vector_storage( $dim )

=head2 set_x_weights

  $opt->set_x_weights( \@weights );

C<@weights> has length C<$n>.

=head2 set_x_weights1

  $opt->set_x_weights1( $weight );

=head2 set_xtol_abs

  $opt->set_xtol_abs( \@tol );

C<@tol> has length C<$n>.

=head2 set_xtol_abs1

  $opt->set_xtol_abs1( $tol );

=head2 set_xtol_rel

  $opt->set_xtol_rel( $tol );

=head1 SUBROUTINES

These are exportable individually, or en-masse via the C<:utils> tag,
but beware that B<srand> has same name as the Perl C<srand> routine, and
C<version> is rather generic.

=head2 algorithm_from_string

  $algorithm_int_id = algorithm_from_string( $algorithm_string_id );

return an integer id (e.g. B<NLOPT_LD_MMA>) from a string id (e.g. 'LD_MMA').

=head2 algorithm_name

  $algorithm_name = algorithm_from_string( $algorithm_int_id );

return a descriptive name from an integer id

=head2 algorithm_to_string

  $algorithm_string_id = algorithm_to_string( $algorithm_int_id );

=head2 result_from_string

  $result_int_id = result_from_string( $result_string_id );

return an integer id (e.g. B<NLOPT_SUCCESS>) from a string id (e.g. 'SUCCESS').

=head2 result_to_string

  $result_string_id = result_to_string( $result_int_id );

=head2 srand

  srand( $seed )

=head2 srand_time

=head2 version

  ($major, $minor, $bugfix ) = Math::NLopt::version()

=for Pod::Coverage constant
create

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-math-nlopt@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Math-NLopt>

=head2 Source

Source is available at

  https://gitlab.com/djerius/math-nlopt

and may be cloned from

  https://gitlab.com/djerius/math-nlopt.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<https://github.com/stevengj/nlopt>

=item *

L<Alien::NLopt>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
