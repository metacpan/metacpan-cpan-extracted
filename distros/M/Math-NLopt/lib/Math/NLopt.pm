package Math::NLopt;

# ABSTRACT: Math::NLopt - Perl interface to the NLopt optimization library

use v5.12;
use strict;
use warnings;

#<<<

our $VERSION = '0.14';

#>>>

# don't inherit.  We're a class by-golly, and don't want Exporter's methods.
use Exporter 'import';

use Ref::Util;
use Scalar::Util;
use Math::NLopt::Exception;

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

# This AUTOLOAD is used to 'autoload' constants from the constant()
# XS function.

sub AUTOLOAD {    ## no critic (ClassHierarchies::ProhibitAutoload)

    my $constname;
    our $AUTOLOAD;
    ( $constname = $AUTOLOAD ) =~ s/.*:://;
    Math::NLopt::Exception::InvalidArgs->throw( 'Math::NLopt::constant not defined' )
      if $constname eq 'constant';
    my ( $error, $val ) = constant( $constname );
    if ( $error ) {
        Math::NLopt::Exception->throw( $error );
    }

    {
        no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)

        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}


my $check_mconstraint = sub {

    my $func = shift;
    @_ % 2 and Math::NLopt::Exception::InvalidArgs->throw( 'expected key => value pairs' );
    my %par = @_;

    Ref::Util::is_coderef( $func )
      or Math::NLopt::Exception::InvalidArgs->throw( '$func is not a coderef' );

    my %args;
    @args{ 'data', 'm', 'tol' } = delete @par{ 'data', 'm', 'tol' };

    %par
      and Math::NLopt::Exception::InvalidArgs->throw( 'extra args: ', join q{, }, keys %par );

    delete @args{ grep !defined $args{$_}, keys %args };

    # individual tests must go below

    exists $args{m}
      or exists $args{tol}
      or Math::NLopt::Exception::MissingParameter->throw( 'must specify at least one of <m> or <tol>: ',
        join q{, }, keys %par );

    exists $args{tol}
      and !Ref::Util::is_plain_arrayref( $args{tol} )
      and Math::NLopt::Exception::InvalidArgs->throw( '<tol> is not a plain arrayref' );

    exists $args{m} && exists $args{tol} && @{ $args{tol} } != $args{m}
      and Math::NLopt::Exception::InvalidArgs->throw( '<m> != number of elements in <tol>' );

    $args{m} //= exists( $args{tol} ) ? @{ $args{tol} } : 0;

    Scalar::Util::looks_like_number( $args{m} ) && $args{m} >= 1 && int( $args{m} ) == $args{m}
      or Math::NLopt::Exception::InvalidArgs->throw( "illegal value for <m>: $args{m}" );

    return ( $func, @args{ 'm', 'tol', 'data' } );
};

my $check_constraint = sub {

    my $func = shift;
    @_ % 2 and Math::NLopt::Exception::InvalidArgs->throw( 'expected key => value pairs' );
    my %par = @_;

    Ref::Util::is_coderef( $func )
      or Math::NLopt::Exception::InvalidArgs->throw( '$func is not a coderef' );

    my %args;
    @args{ 'data', 'tol' } = delete @par{ 'data', 'tol' };

    %par
      and Math::NLopt::Exception::InvalidArgs->throw( 'extra args: ', join q{, }, keys %par );

    delete @args{ grep !defined $args{$_}, keys %args };

    # individual tests must go below

    exists $args{tol}
      and Ref::Util::is_ref( $args{tol} )
      and Math::NLopt::Exception::InvalidArgs->throw( '<tol> is not a scalar' );

    return ( $func, @args{ 'tol', 'data' } );
};

sub add_equality_constraint {
    my $opt = shift;
    return $opt->_add_equality_constraint( $check_constraint->( @_ ) );
}


sub add_inequality_constraint {
    my $opt = shift;
    return $opt->_add_inequality_constraint( $check_constraint->( @_ ) );
}


sub add_equality_mconstraint {
    my $opt = shift;
    return $opt->_add_equality_mconstraint( $check_mconstraint->( @_ ) );
}


sub add_inequality_mconstraint {
    my $opt = shift;
    return $opt->_add_inequality_mconstraint( $check_mconstraint->( @_ ) );
}

require XSLoader;
XSLoader::load( 'Math::NLopt', $VERSION );


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

version 0.14

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
the C++ and Python APIs. Where the C API returns an error code,
C<Math::NLopt> normally returns the corresponding numeric result code
on success and throws an object in the corresponding exception class on
failure. These classes extend L<Math::NLopt::Exception>; see it for
more information on retrieving messages from the objects.

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

=head2 B<NLopt> Results, Errors and Exceptions

=head3 Result codes

While most methods (excluding L</new> and L</optimize>) return a
result code of B<NLOPT_SUCCESS> upon success, they will all throw on
error.

Methods returning arrays or other values either return that value or
throw if the underlying operation fails.

=head3 Exceptions

C<Math::NLopt> will throw exceptions if the underlying B<NLopt>
library detects an error.

Unfortunately, this behavior affects the results returned by
L</optimize>, which are lost when an exception is raised.  Depending
upon the error, the results may actually be valid, so this is truly
unfortunate.

There are a couple of ways to avoid the loss of information.

=over

=item *

The simplest is to retrieve them via the L</last_optimum_params>
method.

=item *

Disable exceptions from NLopt result codes for L</optimize> via the
L</set_exceptions_enabled> method. This is the approach used by the
Python and C++ APIs.

L</optimize> will always return the last set of evaluated parameters.
However, the caller will have to call L</last_optimize_result>
to determine how the optimization concluded, and whether the results
are valid.

Disabling exceptions only affects errors reported by L</optimize>.
Other methods continue to throw exceptions, and exceptions thrown by
user-provided objective, constraint, or pre-conditioner callbacks are
always propagated.

=back

=head2 Callbacks

B<NLopt> handles the optimization of the objective function, relying
upon user provided subroutines to calculate the objective function and
non-linear constraints (see below for the required calling signature).

The callback subroutines are called with a user-provided structure
which can be used to pass additional information to the callback
(or the subroutines can use closures).

=head3 Exceptions thrown by Callback subroutines

Exceptions thrown by callback subroutines during processing by
L</optimize> are caught so that they do not unwind through the NLopt C
stack. The optimization is halted with a forced stop (as if by
L</force_stop>) and the original exception is rethrown after NLopt has
returned.
L</last_optimize_result> will return C<NLOPT_FORCED_STOP>.

=head3 Objective Functions

Objective functions callbacks are registered via either

  $opt->set_min_objective( \&func, ?$data );
  $opt->set_max_objective( \&func, ?$data );

where C<$data> is an optional scalar, reference, or other Perl value
passed to the callback unchanged.

The objective function has the signature

  $value = sub ( \@params, \@gradient, $data ) { ... }

It returns the value of the optimization function for the
passed set parameters, B<@params>.

if B<\@gradient> is not C<undef>, it must be filled in by the
objective function.

C<$data> is the value registered with the callback. It will be
C<undef> if none was provided.

=head2 Non-linear Constraints

=head3 Scalar-valued Constraints

Scalar constraint callbacks are registered via either of

  $opt->add_equality_constraint( \&func, %options );
  $opt->add_inequality_constraint( \&func, %options );

C<%options> accepts the following entries.

=over

=item C<tol> I<scalar> [optional]

The tolerance. Defaults to C<0>.

=item C<data> [optional]

A structure passed to the callback function.

=back

The constraint function has the signature

  $value = sub ( \@params, \@gradient, $data ) { ... }

and must return exactly one numeric value, the value of the
constraint function for the passed set of parameters, B<@params>.

=head3 Vector-valued Constraints

Vector-valued callbacks are registered via either of

  $opt->add_equality_mconstraint( \&func, %options );
  $opt->add_inequality_mconstraint( \&func, %options );

C<%options> accepts the following entries.

=over

=item C<m> I<integer>

The length of the vector.

=item C<tol> I<arrayref>

An array of length C<m> containing the tolerance for each
component of the vector.

=item C<data> [optional]

an optional scalar, reference, or other Perl value passed to the
callback unchanged.

=back

One of C<m> or C<tol> must be provided. If C<tol> is provided without
C<m>, its length is used for C<m>. If both are provided, the number of
array elements in C<tol> must be equal to C<m>.

Vector valued constraints callbacks have the signature

  sub ( \@result, \@params, \@gradient, $data ) { ... }

The C<$m> length vector of constraints should be stored in C<\@result>.
If C<\@gradient> is not C<undef>, it is an C<$m> by C<$n>
two-dimensional array which should be filled by the callback.

The outer dimension indexes the C<$m> constraint components, and the
inner dimension indexes the C<$n> optimization parameters; in other
words, C<< $gradient->[$i][$j] >> is the derivative of constraint
C<$i> with respect to parameter C<$j>.

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
C<\@x> and C<\@v> are inputs. C<\@vpre> must be filled in by the
routine before it returns.

=head1 CONSTRUCTORS

=head2 new

  my $opt = Math::NLopt->new( $algorithm, $n );

Create an optimization object for the given algorithm and number of parameters.
B<$algorithm> is one of the algorithm constants, e.g.

  use Math::NLopt 'NLOPT_LD_MMA';
  my $opt = Math::NLopt->new( NLOPT_LD_MMA, 3 );

C<$n> must be a positive integer.

Invalid inputs or failure to create the underlying NLopt object
results in an exception.

=head1 METHODS

Most methods have the same calling signature as their C versions, but
not all!

=head2 add_equality_constraint

  $opt->add_equality_constraint( \&func, %options );

See L</Scalar-valued Constraints>.

Returns an NLopt result code, normally C<NLOPT_SUCCESS>.

=head2 add_equality_mconstraint

  $opt->add_equality_mconstraint( \&func, %options );

See L</Vector-valued Constraints>.

Returns an NLopt result code, normally C<NLOPT_SUCCESS>.

=head2 add_inequality_constraint

  $opt->add_inequality_constraint( \&func, %options );

See L</Scalar-valued Constraints>.

Returns an NLopt result code, normally C<NLOPT_SUCCESS>.

=head2 add_inequality_mconstraint

  $opt->add_inequality_mconstraint( \&func, %options );

See L</Vector-valued Constraints>.

Returns an NLopt result code, normally C<NLOPT_SUCCESS>.

=head2 force_stop

  $opt->force_stop;

Requests that the current optimization stop. Returns an NLopt result
code.

=head2 get_algorithm

  $algorithm_int_id = $opt->get_algorithm;

=head2 get_dimension

  $n = $opt->get_dimension;

=head2 get_exceptions_enabled

  $bool = $opt->get_exceptions_enabled;

Returns true if errors in the L</optimize> method will result in
exceptions.

=head2 get_errmsg

  $string = $opt->get_errmsg;

Returns the most recent error message from NLopt.

=head2 get_force_stop

  $stop = $opt->get_force_stop;

=head2 get_ftol_abs

  $tol = $opt->get_ftol_abs;

=head2 get_ftol_rel

  $tol = $opt->get_ftol_rel;

=head2 get_initial_step

  \@steps = $opt->get_initial_step( \@init_x );

Returns an arrayref of initial steps for the supplied parameter
vector, which must of length C<$n>, the length passed to L</new>.

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

Return the result code after an optimization.  Returns
C<NLOPT_FAILURE> prior to the first optimization.

=head2 last_optimum_value

  $min_f = $opt->last_optimum_value;

Return the objective value obtained during the last call to L</optimize>.
Returns NaN prior to the first call.

=head2 last_optimum_params

  \@params = $opt->last_optimum_params;

Returns the final parameter vector recorded by the last call to
L</optimize>. It is also updated when L</optimize> stops with an NLopt
error or a callback exception, so it can be used to inspect the last
available result after catching an exception.

=head2 num_params

  $n_algo_params = $opt->num_params;

Return the number of algorithm specific parameters.

=head2 optimize

  \@optimized_pars = $opt->optimize( \@input_pars );

Returns the parameter values determined from the optimization.  The
status of the optimization (e.g. NLopt's result code) can be retrieved
via the L</last_optimize_result> method. The final value of the
objective function is available via the L</last_optimum_value> method.

The input arrayref must have length C<$n>. With exceptions enabled,
NLopt errors cause this method to throw instead of returning a
parameter vector; use L</last_optimum_params> to retrieve the vector
recorded before the error. With exceptions disabled, NLopt errors are
reported by L</last_optimize_result> and the recorded parameter vector
is returned. Exceptions raised by callbacks are always rethrown.

See L</Exceptions thrown by Callback subroutines> for how
callback exceptions are handled.

=head2 remove_equality_constraints

  $opt->remove_equality_constraints;

Returns an NLopt result code.

=head2 remove_inequality_constraints

  $opt->remove_inequality_constraints;

Returns an NLopt result code.

=head2 set_exceptions_enabled

  $opt->set_exceptions_enabled( $bool );

Controls whether NLopt result-code failures from L</optimize> are
thrown. The default is true. This setting does not suppress exceptions
from other methods or from callbacks.

=head2 set_force_stop

  $opt->set_force_stop( $val );

Returns an NLopt result code.

=head2 set_ftol_abs

  $opt->set_ftol_abs( $tol );

Returns an NLopt result code.

=head2 set_ftol_rel

  $opt->set_ftol_rel( $tol );

Returns an NLopt result code.

=head2 set_initial_step

  $opt->set_initial_step(\@dx);

Set the initial step. C<@dx> must have length C<$n>, the length
passed to L</new>.

Returns an NLopt result code.

=head2 set_initial_step1

  $opt->set_initial_step1( $dx );

Sets the same initial step C<$dx> for every parameter.

Returns an NLopt result code.

=head2 set_local_optimizer

  $opt->set_local_optimizer( $local_opt );

Sets the local optimizer used by a composite algorithm. C<$local_opt>
must be another C<Math::NLopt> optimizer object.

Returns an NLopt result code.

=head2 set_lower_bound

  $opt->set_lower_bound( $i, $lb );

Set the lower bound for parameter C<$i> (zero based) to C<$lb>.

Returns an NLopt result code.

=head2 set_lower_bounds

  $opt->set_lower_bounds(\@lb);

C<@lb> must have length C<$n>, the length passed to L</new>.

Returns an NLopt result code.

=head2 set_lower_bounds1

  $opt->set_lower_bounds1( $lb );

Sets the same lower bound C<$lb> for every parameter.

Returns an NLopt result code.

=head2 set_max_objective

  $opt->set_max_objective( \&func, ?$data );

See L<Objective Functions>

Returns an NLopt result code.

=head2 set_maxeval

   $opt->set_maxeval( $max_iterations );

Returns an NLopt result code.

=head2 set_maxtime

   $opt->set_maxtime( $time );

Returns an NLopt result code.

=head2 set_min_objective

  $opt->set_min_objective( \&func, ?$data );

See L<Objective Functions>

Returns an NLopt result code.

=head2 set_param

  $opt->set_param( $name, $value );

Returns an NLopt result code.

=head2 set_population

  $opt->set_population( $pop );

Returns an NLopt result code.

=head2 set_precond_max_objective

  $opt->set_precond_max_objective( \&func, \&precond, ?$data);

Returns an NLopt result code.

See L</Preconditioned Objectives>

=head2 set_precond_min_objective

  $opt->set_precond_min_objective( \&func, \&precond, ?$data);

See L</Preconditioned Objectives>

Returns an NLopt result code.

=head2 set_stopval

  $opt->set_stopval( $stopval);

Returns an NLopt result code.

=head2 set_upper_bound

  $opt->set_upper_bound( $i, $ub );

Set the upper bound for parameter C<$i> (zero based) to C<$ub>

Returns an NLopt result code.

=head2 set_upper_bounds

  $opt->set_upper_bounds(\@ub);

C<@ub> must have length C<$n>, the length passed to L</new>.

Returns an NLopt result code.

=head2 set_upper_bounds1

  $opt->set_upper_bounds1( $ub );

Sets the same upper bound C<$ub> for every parameter.

Returns an NLopt result code.

=head2 set_vector_storage

  $opt->set_vector_storage( $dim );

Sets the amount of vector storage used by the algorithm.

Returns an NLopt result code.

=head2 set_x_weights

  $opt->set_x_weights( \@weights );

C<@weights> must have length C<$n>, the length passed to L</new>.

Returns an NLopt result code.

=head2 set_x_weights1

  $opt->set_x_weights1( $weight );

Sets the same weight for every parameter.

Returns an NLopt result code.

=head2 set_xtol_abs

  $opt->set_xtol_abs( \@tol );

C<@tol> must have length C<$n>, the length passed to L</new>.

Returns an NLopt result code.

=head2 set_xtol_abs1

  $opt->set_xtol_abs1( $tol );

Sets the same absolute tolerance for every parameter.

Returns an NLopt result code.

=head2 set_xtol_rel

  $opt->set_xtol_rel( $tol );

Returns an NLopt result code.

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

=head1 CONSTANTS

=head2 Result Codes

These are constants available for import individually, or in bulk via the C<:result> tag.

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

=head2 Algorithms

These are constants available for import individually, or in bulk via the C<:algorithms> tag.

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

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-math-nlopt@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Math-NLopt>

=head2 Source

Source is available at

  https://codeberg.org/djerius/p5-Math-NLopt

and may be cloned from

  https://codeberg.org/djerius/p5-Math-NLopt.git

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
