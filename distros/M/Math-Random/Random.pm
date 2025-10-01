package Math::Random;

use v5.10;
use strict;
use warnings;

use Carp;

use parent qw( Exporter DynaLoader);

our $VERSION = '0.75';

## no critic ( Wantarray DollarAB ComplexMappings )

our @EXPORT = qw(random_normal
  random_permutation
  random_permuted_index
  random_uniform
  random_uniform_integer
  random_seed_from_phrase
  random_get_seed
  random_set_seed_from_phrase
  random_set_seed
);

our @EXPORT_OK = qw(random_beta
  random_chi_square
  random_exponential
  random_f
  random_gamma
  random_multivariate_normal
  random_multinomial
  random_noncentral_chi_square
  random_noncentral_f
  random_normal
  random_permutation
  random_permuted_index
  random_uniform
  random_poisson
  random_uniform_integer
  random_negative_binomial
  random_binomial
  random_seed_from_phrase
  random_get_seed
  random_set_seed_from_phrase
  random_set_seed
  random_integer
  random_init_generator
  random_set_antithetic
  random_advance_state
  random_get_generator_num
  random_set_generator_num
);

our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

bootstrap Math::Random $VERSION;


### set seeds by default
salfph( get_seed() || scalar( localtime ) );

#####################################################################
#		      RANDOM DEVIATE GENERATORS                     #
#####################################################################

sub random_beta {    # Arguments: ($n,$aa,$bb)

    croak 'Usage: random_beta($n,$aa,$bb)' if @_ < 3;

    my ( $n, $aa, $bb ) = @_;
    croak( "random_beta: ($aa = \$aa < 1.0E-37) or ($bb = \$bb < 1.0E-37)" )
      if ( $aa < 1.0E-37 ) || ( $bb < 1.0E-37 );

    return wantarray
      ? map { genbet( $aa, $bb ) } 1 .. $n
      : genbet( $aa, $bb );
}

sub random_chi_square {    # Arguments: ($n,$df)
    croak 'Usage: random_chi_square(\$n,\$df)'
      if @_ < 2;

    my ( $n, $df ) = @_;
    croak "random_chi_square: $df = \$df <= 0"
      if $df <= 0;

    return wantarray
      ? map { genchi( $df ) } 1 .. $n
      : genchi( $df );
}

sub random_exponential {    # Arguments: ($n,$av), defaults (1,1)
    return wantarray() ? ( genexp( 1 ) ) : genexp( 1 )
      if @_ == 0;           # default behavior if no arguments

    my ( $n, $av ) = @_;
    $av //= 1;              # default $av is 1
    croak "random_exponential: $av = \$av < 0"
      if $av < 0;

    return wantarray
      ? map { genexp( $av ) } 1 .. $n
      : genexp( $av );
}

sub random_f {    # Arguments: ($n,$dfn,$dfd)
    croak 'Usage: random_f($n,$dfn,$dfd)' if @_ < 3;
    my ( $n, $dfn, $dfd ) = @_;
    croak( "random_f: ($dfn = \$dfn <= 0) or ($dfd = \$dfd <= 0" )
      if ( $dfn <= 0 ) || ( $dfd <= 0 );

    return wantarray
      ? map { genf( $dfn, $dfd ) } 1 .. $n
      : genf( $dfn, $dfd );
}

sub random_gamma {    # Arguments: ($n,$a,$r)
    croak 'Usage: random_gamma($n,$a,$r)' if @_ < 3;
    my ( $n, $a, $r ) = @_;
    croak "random_gamma: ($a = \$a <= 0) or ($r = \$r <= 0)"
      if ( $a <= 0 ) || ( $r <= 0 );

    return wantarray
      ? map { gengam( $a, $r ) } 1 .. $n
      : gengam( $a, $r );
}

sub random_multivariate_normal {    # Arguments: ($n, @mean, @covar(2-dimensional))

    croak 'Usage: random_multivariate_normal($n,@mean,@covar(2-dimensional))'
      if @_ < 3;
    my $n = shift( @_ );            # first element is number of obs. desired
    my $p = @_ / 2;                 # best guess at dimension of deviate

    # check outline of arguments
    croak( q{random_multivariate_normal: Sizes of @mean and @covar don't match} )
      if $p != int( $p )
      || ref $_[ $p - 1 ] eq 'ARRAY'
      || ref $_[$p] ne 'ARRAY';

    # linearize input - it seems faster to push
    my @linear = splice( @_, 0, $p );    # fill first $p slots w/ mean

    # expand array references
    foreach my $ref ( @_ ) {             # for the rest of the input

        # check length of row of @covariance
        croak( 'random_multivariate_normal: @covar is not a $p x $p array ($p is size of @mean)' )
          unless @{$ref} == $p;

        push @linear, @{$ref};
    }

    # load float working array with linearized input
    putflt( @linear )
      or croak 'random_multivariate_normal: unable to allocate memory';

    # initialize parameter array for multivariate normal generator
    psetmn( $p )
      or croak 'random_multivariate_normal: unable to allocate memory';

    unless ( wantarray() ) {
        ### if called in a scalar context, returns single reference to obs
        pgenmn();
        return [ getflt( $p ) ];
    }

    # otherwise return an $n by $p array of obs.
    return map {
        pgenmn();
        [ getflt( $p ) ]
    } 1 .. $n;
}

sub random_multinomial {    # Arguments: ($n,@p)
    my ( $n, @p ) = @_;
    my $ncat = @p;          # number of categories
    $n = int( $n );

    croak "random_multinomial: $n = \$n < 0"
      if $n < 0;

    croak "random_multinomial: $ncat = (length of \@p) < 2"
      if $ncat < 2;

    rspriw( $ncat )
      or croak 'random_multinomial: Unable to allocate memory';

    pop @p;
    rsprfw( scalar( @p ) )
      or croak 'random_multinomial: Unable to allocate memory';

    my ( $i, $sum ) = ( 0, 0 );
    foreach my $val ( @p ) {
        croak "random_multinomial: $val = (some \$p[i]) < 0 or > 1"
          if $val < 0 || $val > 1;
        svprfw( $i++, $val );
        $sum += $val;
    }
    croak 'random_multinomial: sum of \@p > 1'
      if $sum > 0.99999;

    pgnmul( $n, $ncat );
    ### get the results
    $i = 0;
    $_ = gvpriw( $i++ ) for @p;
    push @p, gvpriw( $i );
    return @p;
}

sub random_noncentral_chi_square {    # Arguments: ($n,$df,$nonc)
    croak 'Usage: random_noncentral_chi_square($n,$df,$nonc)'
      if @_ < 3;
    my ( $n, $df, $nonc ) = @_;
    croak( "random_noncentral_chi_square: ($df = \$df < 1) or ($nonc = \$nonc) < 0" )
      if $df < 1 || $nonc < 0;

    return wantarray
      ? map { gennch( $df, $nonc ) } 1 .. $n
      : gennch( $df, $nonc );
}

sub random_noncentral_f {    # Arguments: ($n,$dfn,$dfd,$nonc)
    croak 'Usage: random_noncentral_f($n,$dfn,$dfd,$nonc)'
      if @_ < 4;
    my ( $n, $dfn, $dfd, $nonc ) = @_;

    croak( "random_noncentral_f: ($dfn = \$dfn < 1) or ($dfd = \$dfd <= 0) or ($nonc = \$nonc < 0)" )
      if $dfn < 1 || $dfd <= 0 || $nonc < 0;

    return wantarray
      ? map { gennf( $dfn, $dfd, $nonc ) } 1 .. $n
      : gennf( $dfn, $dfd, $nonc );
}

sub random_normal {    # Arguments: ($n,$av,$sd), defaults (1,0,1)
    return wantarray() ? ( gennor( 0, 1 ) ) : gennor( 0, 1 )
      if @_ == 0;      # default behavior if no arguments
    my ( $n, $av, $sd ) = @_;

    $av //= 0;         # $av defaults to 0
    $sd //= 1;         # $sd defaults to 1, even if $av specified
    croak "random_normal: $sd = \$sd < 0)"
      if $sd < 0;

    return wantarray
      ? map { gennor( $av, $sd ) } 1 .. $n
      : gennor( $av, $sd );
}

sub random_permutation {    # Argument: (@array) - array to be permuted.
    my $n = @_;             # number of elements to be permuted
    return () if $n == 0;
    rspriw( $n )
      or croak 'random_permutation: unable to allocate memory';

    pgnprm( $n );
    my @ans = map { gvpriw( $_ ) } 0 .. $n - 1;
    return @_[@ans];
}

sub random_permuted_index {    # Argument: $n = scalar(@array) (for permutation)

    croak 'Usage: random_permuted_index($n)'
      if @_ < 1;

    my $n = int( shift( @_ ) );    # number of elements to be permuted
    croak "random_permuted_index: $n = \$n < 0"
      if $n < 0;
    return () if $n == 0;
    rspriw( $n )
      or croak 'random_permuted_index: unable to allocate memory';

    pgnprm( $n );
    return map { gvpriw( $_ ) } 0 .. $n - 1;
}

sub random_uniform {    # Arguments: ($n,$low,$high), defaults (1,0,1)
    return wantarray() ? ( genunf( 0, 1 ) ) : genunf( 0, 1 )
      if @_ == 0;

    croak 'Usage: random_uniform([$n,[$low,$high]])'
      if @_ == 2;       # only default is (0,1) for ($low,$high) both undef

    my ( $n, $low, $high ) = @_;
    $low  //= 0;        # default for $low is 0
    $high //= 1;        # default for $high is 1

    croak( "random_uniform: $low = \$low > \$high = $high" )
      if $low > $high;

    return wantarray
      ? map { genunf( $low, $high ) } 1 .. $n
      : genunf( $low, $high );
}

sub random_poisson {    # Arguments: ($n, $mu)
    croak 'Usage: random_poisson($n,$mu)' if @_ < 2;

    my ( $n, $mu ) = @_;
    croak "random_poisson: $mu = \$mu < 0"
      if $mu < 0;

    return wantarray
      ? map { ignpoi( $mu ) } 1 .. $n
      : ignpoi( $mu );
}

sub random_uniform_integer {    # Arguments: ($n,$low,$high)

    croak 'Usage: random_uniform_integer($n,$low,$high)' if @_ < 3;

    my ( $n, $low, $high ) = @_;
    $low  = int( $low );
    $high = int( $high );
    croak( "random_uniform_integer: $low = \$low > \$high = $high" )
      if $low > $high;
    my $range = $high - $low;

    croak( "random_uniform_integer: $range = (\$high - \$low) > 2147483561" )
      if $range > 2_147_483_561;

    return wantarray
      ? map { $low + ignuin( 0, $range ) } 1 .. $n
      : $low + ignuin( 0, $range );
}

sub random_negative_binomial {    # Arguments: ($n,$ne,$p)

    croak 'Usage: random_negative_binomial($n,$ne,$p)'
      if @_ < 3;

    my ( $n, $ne, $p ) = @_;
    $ne = int( $ne );
    croak( "random_negative_binomial: ($ne = \$ne <= 0) or ($p = \$p <= 0 or >= 1)" )
      if $ne <= 0 || $p <= 0 || $p >= 1;

    return wantarray
      ? map { ignnbn( $ne, $p ) } 1 .. $n
      : ignnbn( $ne, $p );
}

sub random_binomial {    # Arguments: ($n,$nt,$p)
    croak 'Usage: random_binomial($n,$nt,$p)'
      if @_ < 3;

    my ( $n, $nt, $p ) = @_;
    $nt = int( $nt );
    croak( "random_binomial: ($nt = \$nt < 0) or ($p = \$p < 0 or > 1)" )
      if $nt < 0 || $p < 0 || $p > 1;

    return wantarray
      ? map { ignbin( $nt, $p ) } 1 .. $n
      : ignbin( $nt, $p );
}


#####################################################################
#			SEED HANDLER FUNCTIONS                      #
#####################################################################

sub random_seed_from_phrase {    # Argument $phrase
    my $phrase = shift( @_ );
    $phrase ||= q{};
    return phrtsd( $phrase );
}

sub random_set_seed_from_phrase {    # Argument $phrase
    my $phrase = shift( @_ );
    $phrase ||= q{};
    salfph( $phrase );
    return 1;
}

sub random_set_seed {    # Argument @seed
    my ( $seed1, $seed2 ) = @_;
    croak(  'Usage: random_set_seed(\@seed)\n\@seed[0,1] must be two integers '
          . "in the range (1,1) to (2147483562,2147483398)\nand usually comes "
          . 'from a call to random_get_seed() '
          . "or\nrandom_seed_from_phrase(\$phrase)." )
      unless ( $seed1 == int( $seed1 ) && $seed1 > 0 && $seed1 < 2_147_483_563 )
      && ( $seed2 == int( $seed2 ) && $seed2 > 0 && $seed2 < 2_147_483_399 );

    setall( $seed1, $seed2 );
    return 1;
}

#####################################################################
#			   HELPER ROUTINES                          #
#    These use the C work arrays and are not intended for export    #
#	 (Currently only used in random_multivariate_normal)        #
#####################################################################

sub getflt {
    my $n = shift;
    return map { gvprfw( $_ ) } 0 .. $n - 1;
}

sub putflt {
    my $n = @_;
    rsprfw( $n )
      or return 0;
    my $i = 0;
    svprfw( $i++, $_ ) for @_;
    return 1;
}

1;

__END__

=head1 NAME

B<Math::Random> - Random Number Generators

=head1 SYNOPSIS

=over 4

=item *

 use Math::Random;

Exports the following routines by default (see L<"Default Routines">):

 random_set_seed_from_phrase
 random_get_seed
 random_seed_from_phrase
 random_set_seed
 random_uniform
 random_uniform_integer
 random_permutation
 random_permuted_index
 random_normal

In this case the extended routines (see L<"Extended Routines">) can be
used by    qualifying  them  explicitly  with C<Math::Random::>,   for
example: C<$stdexp = Math::Random::random_exponential();>

=item *

 use Math::Random qw(random_beta
                     random_chi_square
                     random_exponential
                     random_f
                     random_gamma
                     random_multivariate_normal
                     random_multinomial
                     random_noncentral_chi_square
                     random_noncentral_f
                     random_normal
                     random_permutation
                     random_permuted_index
                     random_uniform
                     random_poisson
                     random_uniform_integer
                     random_negative_binomial
                     random_binomial
                     random_seed_from_phrase
                     random_get_seed
                     random_set_seed_from_phrase
                     random_set_seed );

Exports all the routines explicitly.  Use a subset of the list for the
routines you want.

=item *

 use Math::Random qw(:all);

Exports all the routines, as well.

=back

=head1 DESCRIPTION

B<Math::Random> is  a B<Perl> port  of the B<C> version of B<randlib>,
which is   a suite of  routines for  generating  random deviates.  See
L<"RANDLIB"> for more information.

This port supports all of the distributions  from which the B<Fortran>
and B<C>  versions generate deviates.   The major functionalities that
are excluded  are   the  multiple  generators/splitting  facility  and
antithetic  random number  generation.   These facilities,  along with
some of  the distributions which I<are>  included, are probably not of
interest   except  to the   very  sophisticated   user.  If there   is
sufficient interest, the excluded   facilities will be included in   a
future  release.   The code  to   perform the  excluded facilities  is
available as B<randlib> in B<Fortran> and B<C> source.

=head2 Default Routines

The routines which are exported by default are  the only ones that the
average Perl programmer is likely to need.

=over 4

=item C<random_set_seed_from_phrase($phrase)>

Sets  the  seed   of the  base  generator  to   a  value determined by
I<$phrase>.  If  the module is installed with  the default option, the
value depends on the  machine collating sequence.  It should, however,
be the  same for 7-bit ASCII character  strings on all ASCII machines.
In the  original randlib, the value  generated for  a given I<$phrase>
was consistent from implementation to implementation  (it did not rely
on the machine collating sequence).  Check with your Perl
administrator to see if the module was installed with the original
seed generator.
B<Note:>  When the Perl processor loads
package  B<Math::Random>  the seed  is set   to a value  based on  the
current time.  The seed  changes  each time B<Math::Random>  generates
something random.

The ability to set the seed is useful for debugging,  or for those who
like reproducible runs.

=item C<random_get_seed()>

Returns  an   array of  length two  which  contains  the  two integers
constituting  the seed   (assuming   a call   in array   context).  An
invocation   in  a scalar  context  returns   the  integer 2, which is
probably not useful.

=item C<random_seed_from_phrase($phrase)>

Returns   an  array of  length  two which  contains   the two integers
constituting   the seed  (assuming a    call  in array  context).   An
invocation   in  a scalar  context returns  the   integer  2, which is
probably not useful.  The  seed generated is the seed  used to set the
seed in a  call to C<random_set_seed_from_phrase>.

B<Note:>   the  following  two calls  (for   the  same I<$phrase>) are
equivalent:

 random_set_seed(random_seed_from_phrase($phrase));

and

 random_set_seed_from_phrase($phrase);

=item C<random_set_seed(@seed)>

Sets  the  seed  of the  base  generator  to  the value I<@seed>[0,1].
Usually, the  argument  I<@seed> should be  the result  of  a  call to
C<random_get_seed>  or C<random_seed_from_phrase>.  I<@seed>[0,1] must
be two integers in the range S<(1, 1)> to S<(2147483562, 2147483398)>,
inclusive.

=item C<random_integer()>

Returns a raw random long integer.

=item C<random_uniform($n, $low, $high)>

=item C<random_uniform($n)>

=item C<random_uniform()>

When called  in an array context,  returns an array of  I<$n> deviates
generated from   a I<uniform($low,>S< >I<$high)> distribution.    When
called in  a scalar context,    generates and returns only  one   such
deviate as a scalar, regardless of the value of I<$n>.

Argument restrictions: I<$low> must be less than or equal to I<$high>.

Defaults are  (1, 0, 1).    B<Note:>  I<$high> must   be specified if
I<$low> is specified.

=item C<random_uniform_integer($n, $low, $high)>

When called  in an array context,  returns  an array of  I<$n> integer
deviates generated from  a  I<uniform($low,>S< >I<$high)> distribution
on the   integers.  When called   in a  scalar context, generates  and
returns only one such deviate as a  scalar, regardless of the value of
I<$n>.

Argument  restrictions: I<$low> and I<$high>  are  first rounded using
C<int()>; the resulting I<$low> must be less than or equal to I<$high>,
and the resulting  range I<($high - $low)>  must not  be  greater than
2147483561.

There are no defaults; all three arguments must be provided.

=item C<random_permutation(@array)>

Returns I<@array>, randomly permuted.

=item C<random_permuted_index($n)>

Returns  an array  of  array indices, randomly  permuted.  The indices
used are S<(0, ... ,>(I<$n>S< -  >1)).  This produces the indices used
by C<random_permutation> for a given seed, without passing arrays.

B<Note:> the following are equivalent:

 random_set_seed_from_phrase('jjv');
 random_permutation(@array);

and

 random_set_seed_from_phrase('jjv');
 @array[(random_permuted_index(scalar(@array)))];

=item C<random_normal($n, $av, $sd)>

=item C<random_normal($n, $av)>

=item C<random_normal($n)>

=item C<random_normal()>

When called in  an array context, returns  an array  of I<$n> deviates
generated from a I<normal($av, $sd^2)> distribution.  When called in a
scalar context,  generates  and returns  only one  such   deviate as a
scalar, regardless of the value of I<$n>.

Argument restrictions: I<$sd> must be non-negative.

Defaults are (1, 0, 1).

=back

=head2 Extended Routines

These routines generate deviates from many other distributions.

B<Note:> The parameterizations of these deviates are standard (insofar
as there I<is> a  standard ...  ) but  particular attention  should be
paid to the distributions of the I<beta>  and I<gamma> deviates (noted
in C<random_beta> and C<random_gamma> below).

=over 4

=item C<random_beta($n, $aa, $bb)>

When called in an array  context, returns an  array of I<$n>  deviates
generated from  the  I<beta> distribution  with parameters  I<$aa> and
I<$bb>.  The density of the beta is:

X^(I<$aa> - 1) * (1 - X)^(I<$bb> - 1) / S<B>(I<$aa> , I<$bb>) for 0 < X <
1.

When called in  a scalar context, generates  and returns only one such
deviate as a scalar, regardless of the value of I<$n>.

Argument restrictions:  Both I<$aa> and I<$bb> must  not  be less than
C<1.0E-37>.

There are no defaults; all three arguments must be provided.

=item C<random_binomial($n, $nt, $p)>

When called  in an array context,  returns an array  of I<$n> outcomes
generated  from the  I<binomial>  distribution with  number  of trials
I<$nt> and probability of an  event in each  trial I<$p>.  When called
in a scalar context, generates and returns  only one such outcome as a
scalar, regardless of the value of I<$n>.

Argument restrictions: I<$nt>  is rounded  using C<int()>; the  result
must be non-negative.  I<$p> must be between 0 and 1 inclusive.

There are no defaults; both arguments must be provided.

=item C<random_chi_square($n, $df)>

When called in an  array context, returns an  array of I<$n>  deviates
generated from the I<chi-square>  distribution with I<$df> degrees  of
freedom.  When called in a  scalar context, generates and returns only
one such deviate as a scalar, regardless of the value of I<$n>.

Argument restrictions: I<$df> must be positive.

There are no defaults; both arguments must be provided.

=item C<random_exponential($n, $av)>

=item C<random_exponential($n)>

=item C<random_exponential()>

When  called in an  array context, returns  an array of I<$n> deviates
generated from the I<exponential> distribution with mean I<$av>.  When
called    in a scalar  context, generates   and  returns only one such
deviate as a scalar, regardless of the value of I<$n>.

Argument restrictions: I<$av> must be non-negative.

Defaults are (1, 1).

=item C<random_f($n, $dfn, $dfd)>

When called  in an array  context, returns an  array of I<$n> deviates
generated from the I<F>  (variance ratio) distribution with degrees of
freedom I<$dfn> (numerator) and I<$dfd> (denominator).  When called in
a scalar context,  generates and  returns only  one such deviate  as a
scalar, regardless of the value of I<$n>.

Argument restrictions: Both I<$dfn> and I<$dfd> must be positive.

There are no defaults; all three arguments must be provided.

=item C<random_gamma($n, $a, $r)>

When called in  an array context, returns  an array of  I<$n> deviates
generated from  the  I<gamma> distribution  with  parameters I<$a> and
I<$r>.  The density of the gamma is:

(I<$a>**I<$r>) / Gamma(I<$r>) * X**(I<$r> - 1) * Exp(-I<$a>*X)

When called in  a scalar context, generates and  returns only one such
deviate as a scalar, regardless of the value of I<$n>.

Argument restrictions: Both I<$a> and I<$r> must be positive.

There are no defaults; all three arguments must be provided.

=item C<random_multinomial($n, @p)>

When called in an array  context, returns single observation from  the
I<multinomial> distribution, with I<$n> events classified into as many
categories as the length of I<@p>.   The probability of an event being
classified into category I<i> is given by the I<i>th element of I<@p>.
The observation is an array with length equal to I<@p>, so when called
in a scalar  context it  returns  the length  of @p.   The sum of  the
elements of the observation is equal to I<$n>.

Argument  restrictions: I<$n> is  rounded  with C<int()> before it  is
used; the  result  must be  non-negative.   I<@p> must have  length at
least 2.  All elements of I<@p> except the  last must be between 0 and
1  inclusive, and sum to  no  more than   0.99999.  B<Note:> The  last
element of I<@p> is a dummy to indicate  the number of categories, and
it is adjusted to bring the sum of the elements of I<@p> to 1.

There are no defaults; both arguments must be provided.

=item C<random_multivariate_normal($n, @mean, @covar)>

When  called in an array context,  returns  an array of I<$n> deviates
(each   deviate  being    an  array  reference) generated   from   the
I<multivariate  normal>  distribution with  mean  vector I<@mean>  and
variance-covariance  matrix  I<@covar>.     When called  in  a  scalar
context,  generates and  returns only  one  such  deviate  as an array
reference, regardless of the value of I<$n>.

Argument restrictions: If the dimension of the deviate to be generated
is I<p>,  I<@mean>  should be a   length I<p> array  of real  numbers.
I<@covar> should be  a length I<p> array of  references to length I<p>
arrays of real  numbers  (i.e.  a  I<p>  by  I<p>  matrix).   Further,
I<@covar> should be a symmetric positive-definite matrix, although the
B<Perl> code does  not check positive-definiteness, and the underlying
B<C> code    assumes  the  matrix  is   symmetric.    Given that   the
variance-covariance matrix is  symmetric, it   doesn't matter if   the
references  refer   to rows  or columns.   If  a non-positive definite
matrix is passed  to the function,  it  will abort with the  following
message:

 COVM not positive definite in SETGMN

Also,  a    non-symmetric   I<@covar> may    produce  deviates without
complaint,  although they may not  be  from the expected distribution.
For  these reasons, you  are   encouraged  to I<verify  the  arguments
passed>.

The B<Perl> code I<does>   check  the dimensionality of I<@mean>   and
I<@covar> for consistency.  It does so by  checking that the length of
the argument  vector  passed is  odd,  that  what  should be the  last
element of I<@mean> and the first element  of I<@covar> look like they
are a number followed by an array reference respectively, and that the
arrays referred to in I<@covar> are as long as I<@mean>.

There are no defaults; all three arguments must be provided.

=item C<random_negative_binomial($n, $ne, $p)>

When  called in an  array context, returns  an array of I<$n> outcomes
generated from the  I<negative  binomial> distribution with number  of
events I<$ne> and  probability of an event  in each trial I<$p>.  When
called  in  a scalar   context, generates  and  returns only  one such
outcome as a scalar, regardless of the value of I<$n>.

Argument restrictions: I<$ne> is   rounded using C<int()>, the  result
must be positive.  I<$p> must be between 0 and 1 exclusive.

There are no defaults; both arguments must be provided.

=item C<random_noncentral_chi_square($n, $df, $nonc)>

When called in  an array context, returns  an array  of I<$n> deviates
generated  from the I<noncentral  chi-square> distribution with I<$df>
degrees of freedom and noncentrality  parameter I<$nonc>.  When called
in a scalar context, generates and returns only  one such deviate as a
scalar, regardless of the value of I<$n>.

Argument restrictions:   I<$df> must be at  least  1, I<$nonc> must be
non-negative.

There are no defaults; all three arguments must be provided.

=item C<random_noncentral_f($n, $dfn, $dfd, $nonc)>

When called in  an array context, returns an  array of  I<$n> deviates
generated from the I<noncentral F>  (variance ratio) distribution with
degrees of freedom I<$dfn> (numerator)  and I<$dfd> (denominator); and
noncentrality parameter I<$nonc>.   When  called in a  scalar context,
generates and returns only one such deviate as a scalar, regardless of
the value of I<$n>.

Argument restrictions:  I<$dfn> must  be at least   1, I<$dfd> must be
positive, and I<$nonc> must be non-negative.

There are no defaults; all four arguments must be provided.

=item C<random_poisson($n, $mu)>

When called  in an array context,  returns an array  of I<$n> outcomes
generated  from the I<Poisson>  distribution  with mean  I<$mu>.  When
called  in a  scalar   context, generates and  returns  only  one such
outcome as a scalar, regardless of the value of I<$n>.

Argument restrictions: I<$mu> must be non-negative.

There are no defaults; both arguments must be provided.

=back

=head2 Base Generator Routines

These routines control the underlying base random number generator.

=over

=item C<random_init_generator($type)>

Sets the seeds of the current random number generator based on C<$type>:

=over

=item  Z<>-1

initial value

=item  Z<> 0

first value of the current block

=item  Z<> 1

first value of the next block

=back


=item C<random_set_antithetic($bool)>

Sets whether to return antithetic random numbers.
A non-zero value enables antithetic mode.

=item C<random_advance_state($k)>

Advances the state of the current generator by C<2**$k> values and
resets the initial seed to that value.

=item C<random_get_generator_num()>

Returns the number of the current random number generator.

=item C<random_set_generator_num($g)>

Sets the current random number generator to C<$g>.

=back

=head1 ERROR HANDLING

The B<Perl> code should C<croak> if bad arguments are passed or if the
underlying B<C> code  cannot allocate the  necessary memory.  The only
error which should kill the job without  C<croak>ing is a non-positive
definite         variance-covariance      matrix      passed        to
C<random_multivarite_normal> (see L<"Extended Routines">).

=head1 RANDLIB

B<randlib>  is available in B<Fortran> and  B<C> source form, and will
soon be available in B<Fortran90> source as well.  B<randlib.c> can be
obtained from     B<statlib>.  Send mail   whose  message   is I<'send
randlib.c.shar from general'> to:

                       statlib@lib.stat.cmu.edu

B<randlib.c>   can  also  be    obtained    by  anonymous  B<ftp>   to:

                  odin.mdacc.tmc.edu (143.111.62.32)

where it is available as

                   /pub/source/randlib.c-1.3.tar.gz

For obvious reasons, the original B<randlib>  (in B<Fortran>) has been
renamed to

                   /pub/source/randlib.f-1.3.tar.gz

on the same machine.

Our FTP index is on file C<./pub/index>.

If you have Internet access and a browser you might note the following
web site addresses:

University of Texas M. D. Anderson Cancer Center Home Page:

                   http://www.mdanderson.org/

Department of Biomathematics Home Page:

                   http://odin.mdacc.tmc.edu/

Available software:

       http://biostatistics.mdanderson.org/SoftwareDownload/

=head1 SUPPORT

This work  was supported  in part by  grant CA-16672 from the National
Cancer Institute.  We are grateful  to Larry and  Pat McNeil of Corpus
Cristi for their generous support.  Some equipment used in this effort
was provided by IBM as part of a cooperative study agreement; we thank
them.

=head1 CODE MANIPULATION

The   B<C>  version of  B<randlib>  was  obtained  by  translating the
original   B<Fortran>     B<randlib>  using  B<PROMULA.FORTRAN>,   and
performing some hand crafting of the result.

Information on B<PROMULA.FORTRAN> can be obtained from:

                   PROMULA Development Corporation
                    3620 N. High Street, Suite 301
                         Columbus, Ohio 43214
                            (614) 263-5454

F<wrapper.c>  (now  obsolete)   was  created   by  using B<SWIG>,  and
performing some modification of the result.  B<SWIG> also produced the
skeleton of F<Random.pm>.

Information on B<SWIG> can be obtained from:

                   http://www.swig.org

=head1 SOURCES

The following routines,  which  were  written by others   and  lightly
modified for consistency in packaging, are included in B<randlib>.

=over 4

=item Bottom Level Routines

These routines are a transliteration of the B<Pascal> in the reference
to B<Fortran>, and thence to B<C>.

L'Ecuyer, P., and Cote, S. "Implementing  a Random Number Package with
Splitting  Facilities."  ACM  Transactions   on Mathematical Software,
17:98-111 (1991).

=item Exponential

This code was obtained from Netlib.

Ahrens, J. H., and Dieter, U.  "Computer Methods for Sampling from the
Exponential and Normal  Distributions."  Comm. ACM, 15,10 (Oct. 1972),
873-882.

=item Gamma

(Case R >= 1.0)

Ahrens, J. H., and Dieter, U. "Generating Gamma Variates by a Modified
Rejection Technique."  Comm. ACM, 25,1 (Jan. 1982), 47-54.
Algorithm GD

(Case 0.0 <= R <= 1.0)

Ahrens, J. H.,  and  Dieter, U.  "Computer Methods  for Sampling  from
Gamma, Beta, Poisson and Binomial Distributions."  Computing, 12 (1974),
223-246.  Adaptation of algorithm GS.

=item Normal

This code was obtained from netlib.

Ahrens, J. H., and  Dieter, U.   "Extensions of  Forsythe's Method for
Random Sampling  from the Normal Distribution."  Math. Comput., 27,124
(Oct. 1973), 927-937.

=item Binomial

This code was kindly sent to Dr. Brown by Dr. Kachitvichyanukul.

Kachitvichyanukul, V., and Schmeiser,  B. W.  "Binomial Random Variate
Generation."  Comm. ACM, 31, 2 (Feb. 1988), 216.

=item Poisson

This code was obtained from netlib.

Ahrens, J. H., and Dieter, U. "Computer Generation of Poisson Deviates
from Modified Normal Distributions."  ACM Trans.  Math. Software, 8, 2
(June 1982), 163-179.

=item Beta

This code was written by us following the recipe in the following.

Cheng, R. C. H.  "Generating  Beta Variables  with  Nonintegral  Shape
Parameters."  Comm. ACM, 21:317-322 (1978). (Algorithms BB and BC)

=item Linpack

Routines   C<SPOFA> and  C<SDOT> are  used    to perform  the Cholesky
decomposition of   the covariance matrix  in  C<SETGMN>  (used for the
generation of multivariate normal deviates).

Dongarra, J. J., Moler,   C.  B., Bunch, J.   R., and  Stewart, G.  W.
Linpack User's Guide.  SIAM Press, Philadelphia.  (1979)

=item Multinomial

The  algorithm is from  page 559  of Devroye,  Luc Non-Uniform  Random
Variate Generation.  New York: Springer-Verlag, 1986.

=item Negative Binomial

The  algorithm is from  page 480  of Devroye,  Luc Non-Uniform  Random
Variate Generation.  New York: Springer-Verlag, 1986.

=back

=head1 VERSION

This POD documents B<Math::Random> version 0.75.

=head1 AUTHORS

=over 4

=item *

B<Math::Random> (the B<Perl> port  of B<Randlib>) was put  together by
John Venier  and Barry W. Brown with help from  B<SWIG>.  For  version
0.61, Geoffrey Rommel made various cosmetic changes. Version 0.64 uses
plain vanilla XS rather than SWIG.

=item *

B<randlib> was compiled and written  by  Barry W. Brown, James Lovato,
Kathy Russell, and John Venier.

=item *

Correspondence regarding B<randlib> should be addressed to John Venier
by email to

                      jvenier@mdanderson.org

Issues with B<Math::Random> should be filed at the CPAN bugtracker at

  https://rt.cpan.org/Public/Dist/Display.html?Name=Math-Random


=item *

Our address is:

                Department of Biomathematics, Box 237
         The University of Texas, M.D. Anderson Cancer Center
                       1515 Holcombe Boulevard
                          Houston, TX 77030

=item *

Geoffrey Rommel may be reached at grommel [at] cpan [dot] org.

=back

=head1 LEGALITIES

=over 4

=item *

The programs in the  B<Perl> code distributed with B<Math::Random> and
in    the B<C> code F<helper.c>, as    well as  the documentation, are
copyright by John  Venier and  Barry  W.  Brown for the  University of
Texas M.  D.  Anderson Cancer Center in 1997.  They may be distributed
and used under the same conditions as B<Perl>.

=item *

F<randlib.c>,  F<com.c>,  and F<randlib.h>   are from  B<randlib> (See
L<"RANDLIB">) and are distributed with the following legalities.

Code that appeared  in an    ACM  publication  is subject  to    their
algorithms policy:

Submittal of  an  algorithm    for publication  in   one of   the  ACM
Transactions implies that unrestricted use  of the algorithm within  a
computer is permissible.   General permission  to copy and  distribute
the algorithm without fee is granted provided that the copies  are not
made  or   distributed for  direct   commercial  advantage.    The ACM
copyright notice and the title of the publication and its date appear,
and  notice is given that copying  is by permission of the Association
for Computing Machinery.  To copy otherwise, or to republish, requires
a fee and/or specific permission.

Krogh, F.  "Algorithms Policy."  ACM  Tran.  Math.  Softw.  13 (1987),
183-186.

Note, however, that only the particular expression of an algorithm can
be copyrighted, not the algorithm per se; see 17 USC 102E<40>bE<41>.

We place the Randlib code that we have written in the public domain.

=item *

B<Math::Randlib> and B<randlib>  are distributed  with B<NO WARRANTY>.
See L<"NO WARRANTY">.

=back

=head1 NO WARRANTY

WE PROVIDE  ABSOLUTELY  NO WARRANTY  OF ANY  KIND  EITHER  EXPRESS  OR
IMPLIED,  INCLUDING BUT   NOT LIMITED TO,  THE  IMPLIED  WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK
AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS  WITH YOU.  SHOULD
THIS PROGRAM PROVE  DEFECTIVE, YOU ASSUME  THE COST  OF  ALL NECESSARY
SERVICING, REPAIR OR CORRECTION.

IN NO  EVENT  SHALL THE UNIVERSITY  OF TEXAS OR  ANY  OF ITS COMPONENT
INSTITUTIONS INCLUDING M. D.   ANDERSON HOSPITAL BE LIABLE  TO YOU FOR
DAMAGES, INCLUDING ANY  LOST PROFITS, LOST MONIES,   OR OTHER SPECIAL,
INCIDENTAL   OR  CONSEQUENTIAL DAMAGES   ARISING   OUT  OF  THE USE OR
INABILITY TO USE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA OR
ITS ANALYSIS BEING  RENDERED INACCURATE OR  LOSSES SUSTAINED  BY THIRD
PARTIES FROM) THE PROGRAM.

(Above NO WARRANTY modified from the GNU NO WARRANTY statement.)

=cut
