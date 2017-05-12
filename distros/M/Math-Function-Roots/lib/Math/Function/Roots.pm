package Math::Function::Roots;
use base Exporter;
use vars qw(@EXPORT_OK $E $Max_Iter $VERSION $Last_Iter);

use warnings;
use strict;
use Carp;

=head1 NAME

Math::Function::Roots - Functions for finding roots of arbitrary functions

=head1 VERSION

Version 0.065

=cut

$VERSION = '0.065';

=head1 SYNOPSIS

This is a collection of functions (in the perl sense) to find the root
of arbitrary functions (in the mathmatical sense). The Functions take a
sub reference and a range or guess of the answer and return the
root of the function.

    use Math::Function::Roots qw(bisection epsilon max_iter);

    epsilon(0); # Set desired accuracy
    max_iter(50_000) # Put cap on runtime

    # Find the root of 2x+1 in the range (-5,5)
    my $result = bisection( sub {2*shift()+1}, -5, 5);
    # $result == -.5

    # Alternative method of setting epsilon and max_iter
    my $result2 = bisection( sub {2*shift()+1}, -5, 5, 
        epsilon=>.00001, 
        max_iter=>20);
    
=head1 DESCRIPTION

Numerical Analysis is the method of using algorithms, often
iterative, to approximate the solution to a problem to which finding
an exact solution would be difficult. Root Finding Algorithms are used
to find the root of functions. They deal with continuous mathematical
functions (one unique value of f(x) for every x). A root is anywhere
the function evaluates to zero, i.e. where it crosses the
x-axis. Different algortihms have different capacity for finding
multiple roots, many can only find one root.

But enough of that, if you are here you probably know what a root
finding algorithm is. I have begun implementing the following
algorithms, which are described in detail below. The basic outline is
algorithm( function, guess). Each function below is named after the
underlying algorithm. 

=head1 PARAMETERS 

All of the algorithms have similar parameters, so I will describe them
once. Always mandatory is the function we are finding the root of.

=head2 I<function> Parameter

Functions are passed as code references. These can take the form of
"\&Function" or "sub{...}". Simple function can be inlined with sub{}, with more complicated functions taking the reference is recommended.

    # f(x) = 2x - 4
    # sub{ 2*shift() - 4 used as
    my $root = bisection( sub{ 2*shift() - 4 }, -10, 10 );

Often you will have a function of multiple variables. This can be done with a wrapper function, such as:

    sub foo{
       my ($x1,$x2) = @_;
       return $x1**2 + $x2**2;
    }

    sub wrapper{
       my $x2 = shift;
       return foo( 5, $x2 );
    }

    my $result = bisection( \&wrapper, -10, 10 );

Whatever subroutine is passed, it will be called with one argument,
and is expected to return a single result. Functions not fitting that
description will need a wrapper.

This will find the root of f(x) = 5**2 + x**2. Different algorithms
react differently to certain functions. There is some advice below on
good algorithms for certain types of functions.

=head2 I<guess or min/max> Parameters

Most algorithms require an initial range or guesses. If referred to as
'guesses' then the solution (root) need not be in the range
[guess1,guess2]. If a range or min and max are required, then to
solution B<must> lie within [min,max].

=head2 I<epsilon> and I<max_iter> Parameters

Epsilon (I<e>) is used to set the desired accuracy. Less accurate
answers take fewer iterations and are therefore quicker to compute. In
general I<e> referres to the maximum distance from the given solution
to the actual solution. If you need 6 decimals of accuracy, then I<e>
= .000_000_1 is appropriate, this is the default. Calculating a few
decimals beyond what you need is generally recommended to prevent
compounding rounding errors. I<epsilon> is a named parameter to set
I<e> for that particular run of the algorithm, it should always follow
mandatory parameters:

    my $result = bisection( sub{...}, -10, 10, epsilon => .01 );

The I<epsilon>() function may be used to set I<e> globally, be careful.

=cut 

$E = 0.000_000_1;
sub epsilon(;$){
    if( @_ ){
	$E = shift;
	$E = 0 if $E < 0;
    }
    return $E;
}

=pod

Similar to epsilon, the maximum number of iterations an algorithm
should run for may be set with the I<max_iter> named parameter, or
globally with I<max_iter>(i). This maximum is normally used to catch
errors, i.e. when a given function doesn't converge, or when there is
a bug (nah...). Do not use this to control run-time, if you need an
answer faster, use a larger epsilon. The only reason to change this
would be if you had a slowly converging function, and you were willing
to wait for a good answer, then you could raise the maximum to allow
the algorithm to continue working. Default is 5,000.

=cut

$Max_Iter = 50_000;
sub max_iter(;$){
    if( @_ ){
	$Max_Iter = shift;
	$Max_Iter = 1 if ($Max_Iter < 1);
    }	
    return $Max_Iter;
}

=head1 PERFORMANCE CHECKING

=head2 last_iter( )

This will return the number of iterations used to find the last
result. This might help to give an indication on how an algorithm
performs on your data. 

=cut

sub last_iter{
    return $Last_Iter;
}

=head1 ALGORITHMS

Below is a listing of availible algorithms. Many have restriction on the types of functions they work on, particularly the characteristics of the function near its root. Quick summary:

=over 4 

=item * bisection - Good for general purposes, you must provide a
range in which one and only one root exists. Basically a binary search
for the root.

=item * fixed_point - Only useful on a set of functions that can be
converted to a fixed-point function with certain properties, see
below. Fast when it can be used.

=item * secant - A fast converging algorithm which bases guesses on
the slope of the function. Because slope is used, areas of the
function where the slope is near horizontal (f'(x) == 0) should be
avoided.

=back

=cut

@EXPORT_OK = qw(epsilon 
		max_iter 
		last_iter 
		bisection 
		fixed_point 
		secant
		false_position
		find
		);

=head2 bisection( I<function, min, max> )

Uses the bisection algorithm. Average performance, but dependable. Min
and max are used to specify a range which contains the root. To ensure
this f(min) and f(max) must have opposite signs (meaning that there
must be at least one root between them). Giving a range with multiple
roots in it will not work in most cases. This method is dependable,
because it does not care about the shape of the function. It is also a
bit slower than som algorithms because it does not take hints from the
shape.

=cut

sub bisection (&$$;%){
    my $f = shift;
    my ($a,$b) = (shift, shift);
    my %optional = @_;
    my $E = $optional{epsilon} || $E;
    my $Max_Iter = $optional{max_iter} || $Max_Iter;

    my ($ay, $by ) = ( &$f($a), &$f($b) );
    if( ($ay * $by) > 0 ){
	# This algo doesn't work if a and b don't braket the root
	# f(a) must have and an opposite sign from f(b)
	# to ensure there is an odd number of roots
	croak "Bad range: f($a) and f($b) have the same sign";
    }
    my $p = 0;
    for (1..$Max_Iter){
	$Last_Iter = $_;
	
	$p = ($a+$b)/2.0;
	my $py = &$f($p);

	if( $py == 0 || abs( $a - $b ) <= $E ){
            #Uses relative change in p as stopping criteria
	    #Alternative would be size of a..b range, i.e. abs(a-b)
	    return $p;
	}
	elsif( $py * $ay < 0 ){
	    #If f at p and a have opposite sign 
	    #then there is a root between them
	    #next iteration should be a..p
	    $b = $p;
	    $by = $py;
	}
	else{
	    # If $py != 0, $ay and $by have opposite signs, $py and $ay have same sign
	    # then $py and $by must have opposite signs
	    $a = $p;
	    $ay = $py;
	}
    }
    
    carp "Maximum iterations: possible bad solution";
    return $p;
}

=head2 fixed_point( I<fixed point function, guess> )

The Fixed-Point Iteration algorithm is a fast robust method which,
unfortunately, works on a limited domain of problems, and requires
some algebra. The benefits are that it can converge rapidly, and the
range the root is in does not need to be known, any guess will
converge, eventually.

A fixed-point is where g(x) = x. The method is to find a function,
g(x), which has a fixed-point where f(x) has a root. This can be done
trivially by using g(x) = x - f(x). In more general cases it is done
by factoring an x so that g(x) = x = ff(x), where x = ff(x) is some
identity derived from f(x). 

As was mentioned there is a restriction on you choice of g(x), it is
that the absolute value of the derivative of g(x) must be less than
1. Or |g'(x)| < 1 (mathematical notation I<is> handy sometimes). The
closer g'(x) is to 0 the faster the rate of convergence.

Consider a range [a,b] which contains the fixed-point and within which
|g'(x)| < 1 holds true. This might be an infinite range or a segment
of the function. As long as your initial guess is within this range,
the algorithm will converge.

I<guess> is an approximation of the answer. The algorithm will
converge regardless of the relationship of I<guess> to the actual
answer, just so long as I<guess> is within the range [a,b].

Why go through all this hassle? Well, certain functions lend
themselves to being transformed easily into fixed-point
functions. Also, with a derivative near 0 the convergence is very
fast, regardless of initial guess. 

=cut

sub fixed_point(&$;%){
    my $g = shift;
    my $guess = shift;
    my %optional = @_;
    my $E =  $optional{epsilon} || $E;
    my $Max_Iter = $optional{max_iter} || $Max_Iter;

    my ($p,$last_p) = (0,$guess);
    for (1..$Max_Iter){
	$Last_Iter = $_;

	# Each iter we compute p = g(p')
	$p = &$g($last_p);
	if( abs( $p - $last_p ) <= $E ){
	    return $p;
	}
	$last_p = $p;
    }
    carp "Maximum iterations: divergence likely";
    return undef;
}

=head2 secant( I<function>, guess1, guess2 >)

The secant method is a simplification of the Newton method, which uses
the derivitive of the function to better predict the root of the
function. The secant method uses a secant (line between two points on
the function) as a substitute for knowing or calculating the
derivative of the function.

As usual, provide the function, then provide two guesses. Unlike
bisection, these do not need to bracket the solution. Local minimums
or maximums, where the slope is near 0, are unfriendly to this
algorithm. When the two guesses are near the solution however, this
algorithm gives rapid convergence. 

=cut

sub secant(&$$;%){
    my $f = shift;
    my ($p0,$p1) = (shift,shift);
	
    my %optional = @_;
    my $E =  $optional{epsilon} || $E;
    my $Max_Iter = $optional{max_iter} || $Max_Iter;    


    my ($q0,$q1,) = ( &$f($p0) , &$f($p1) );
    my $p;
    for (1..$Max_Iter){
	$Last_Iter = $_;

	$p = $p1 - ($q1 * ($p1 - $p0)) / ($q1 - $q0);

	# Careful, the order of the assignments below and
	# following the test are important
	$p0 = $p1;
	$q0 = $q1;
	$q1 = &$f( $p );
	
	if( $q1 eq 0 || abs( $p - $p1 ) <= $E ){
	    return $p;
	}
	
	$p1 = $p;	
    }
    carp "Maximum iterations: divergence likely";
    return undef;
}

=head2 false_position( I<function, min, max> )

False Position is an algorithm similar to Secant, it uses secants
of the function to pick better guesses. The difference is that this
method incorporates the bracketing of the Bisection method, with the
speed of the Secant method.

Bracketing is a desirable property because it makes the algorithm more
dependable. Bracketing ensures that the algorithm will stay within the
given range. This is useful with higer-order functions where you want
to restrict your search to the area directly around the root.

The only restriction is that the functions derivative must not equal 0
within the range [min,max]. There must also only be one root within
the range, which (as in Bisection) is ensured by requiring that f(min)
and f(max) have opposite signs.

=cut

sub false_position(&$$;%){
    my $f = shift;
    my ($a,$b) = (shift,shift);
	
    my %optional = @_;
    my $E =  $optional{epsilon} || $E;
    my $Max_Iter = $optional{max_iter} || $Max_Iter;    
    
    my ($ay, $by) = ( &$f($a), &$f($b) );
    # This algorithm requires that f(a) and f(b) 
    # always have opposite signs
    croak "Bad range: f($a) and f($b) have the same sign" 
	if( $ay * $by > 0 );

    my ($p,$last_py) = (0,0);
    for (1..$Max_Iter){
	$Last_Iter = $_;
	
	$p = $b - $by*($b - $a)/($by - $ay);
	
	my $py = &$f($p);
	
	if( abs($py - $last_py) <= $E ){
	    return $p;
	}
	elsif( $py * $by < 0 ){
	    # If $py and $by have opposite signs
	    # Then the root is within [p..b]
	    $a = $p;
	    $ay = $py;
	}
	else{
	    # root is in range [a..p]
	    $b = $p;
	    $by = $py;
	}
	$last_py = $py;
    }
    carp "Maximum iterations: possible bad solution";
    return $p;
}

=head2 find()

This a hybrid function which uses a combination of algorithms to find
the root of the given function. Both I<guess1> and I<guess2> are
optional. If one is provided, it is used as an approximate starting
point. If both are given, then they are taken as a range, the root
B<must> be within this range.

It will most likely return the root nearest your guess, but no
guarantees. Don't provide a range with more than one root in it, you
might find one, you might not. More information will give higher
performance and more control over which root is being found, but if
you don't know anything about the function, give it a try without a
guess. Settings from epsilon and maximum iterations apply as normal.

=cut

sub find(&;$$%){
    my $f = shift;
    my ($a,$b);

    # This is totally wrong, need to not assign to $a and $b when no 
    # arguments

    if( defined $_[0] && $_[0] =~ !/epsilon|max_iter/ ){ 
	$a = shift;
    }
    if( defined $_[0] && $_[0] =~ !/epsilon|max_iter/ ){ 
	$b = shift;
    }	

    my %optional = @_;
    my $E =  $optional{epsilon} || $E;
    my $Max_Iter = $optional{max_iter} || $Max_Iter;  

    unless( defined $b ){
	# If we don't have $b, we don't have a range, 
	# but we might have a guess
	unless( defined $a ){
	    # If we have no guess we'll use 0 for initiation
	    $a = 0;
	}
	# Start with a guess range +2 and -2 around guess
	$a -= 2; 
	$b = $a + 4;
	my ($fa,$fb);
	do{

	    # add max iteration catch to this loop
	    # irr call to this function is causing both points to go negative

	    # Until $a and $b bracket the solution
	    $fa = &$f($a);
	    $fb = &$f($b);
	    sleep 1;
	    #use Data::Dumper::Simple;
	    #warn Dumper($a,$fa,$b,$fb ); 
	    $a = $a*2;
	    $b = $b*2;
	}until( $fa * $fb < 0 );
    }
    # Now we have a possibly large range that must bracket the solution
    # It might also bracket an odd number of roots,
    # in this case, we don't know which one we might find,
    # and if the user cares, he should have given more info


    my ($approx,$result);
    eval{
	$approx = bisection( \&$f, $a, $b, epsilon => .1 );
    } || die "find: Initial bisection approximation failed: ".$@;
    eval{
	$result = false_position( \&$f, $approx - .1, $approx + .1 );
    } || die "find: false_position refinement failed: ".$@;
    return $result;
}
	

=head1 FUTURE IMPROVEMENTS

The first priority witll be adding more algorithms. Then it might be
interesting to implement a mechanism where several algorithms could be
tried on love data to choose the best algorithm for the
domain. Lastly, using Inline::C or XS to rewrite the algos in C would
be desirable for performance. Ideally I would like it to work so that
if a C compiler is availible, then the C version is compiled and used,
otherwise the Perl version is used. I've seen examples of this, but
don't know how it is done at the moment, so this is a ways off.

Finish of test coverage.

=head1 AUTHOR

Spencer Ogden, C<< <spencer@spencerogden.com> >>

=head1 BUGS

The find function is broken

Please report any bugs or feature requests to
C<bug-algorithm-bisection@rt.cpan.org>, or through the web interface
at L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Spencer Ogden, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Math::Bisection
