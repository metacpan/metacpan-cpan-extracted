use 5.006;
use strict;
use warnings;

package Math::Random::OO;
# ABSTRACT: Consistent object-oriented interface for generating random numbers
our $VERSION = '0.22'; # VERSION

use Carp;

sub import {
    my ( $class, @symbols ) = @_;
    my $caller = caller;
    for (@symbols) {
        no strict 'refs';
        my $subclass = "Math::Random::OO::$_";
        eval "require $subclass";
        *{"${caller}::$_"} = sub { return ${subclass}->new(@_) };
    }
}

sub new {
    my $class = shift;
    return bless( {}, ref($class) ? ref($class) : $class );
}

sub seed { die "call to abstract method 'seed'" }

sub next { die "call to abstract method 'next'" }

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Math::Random::OO - Consistent object-oriented interface for generating random numbers

=head1 VERSION

version 0.22

=head1 SYNOPSIS

  # Using factory functions
  use Math::Random::OO qw( Uniform UniformInt );
  push @prngs, Uniform(), UniformInt(1,6);
 
  # Explicit creation of subclasses
  use Math::Random::OO::Normal;
  push @prngs, Math::Random::OO::Normal->new(0,2);
 
  $_->seed(23) for (@prngs);
  print( $_->next(), "\n") for (@prngs);

=head1 DESCRIPTION

CPAN contains many modules for generating random numbers in various ways
and from various probability distributions using pseudo-random number
generation algorithms or other entropy sources.  (The L</"SEE ALSO"> section
has some examples.)  Unfortunately, no standard interface exists across these
modules.  This module defines an abstract interface for random number
generation.  Subclasses of this model will implement specific types of random
number generators or will wrap existing random number generators.

This consistency will come at the cost of some efficiency, but will enable
generic routines to be written that can manipulate any provided random number
generator that adheres to the interface.  E.g., a stochastic simulation could
take a number of user-supplied parameters, each of which is a Math::Random::OO
subclass object and which represent a stochastic variable with a particular
probability distribution.

=head1 USAGE

=head2 Factory Functions

 use Math::Random::OO qw( Uniform UniformInt Normal Bootstrap );
 $uniform = Uniform(-1,1);
 $uni_int = UniformInt(1,6);
 $normal  = Normal(1,1);
 $boot    = Bootstrap( 2, 3, 3, 4, 4, 4, 5, 5, 5 );

In addition to defining the abstract interface for subclasses, this module
imports subclasses and exports factory functions upon request to simplify
creating many random number generators at once without typing
C<Math::Random::OO::Subclass-E<gt>new()> each time.  The factory function names are
the same as the suffix of the subclass following C<Math::Random::OO>.  When
called, they pass their arguments directly to the C<new> constructor method of
the corresponding subclass and return a new object of the subclass type.
Supported functions and their subclasses include:

=over

=item *

C<Uniform> -- L<Math::Random::OO::Uniform> (uniform distribution over a range)

=item *

C<UniformInt> -- L<Math::Random::OO::UniformInt> (uniform distribution of
integers over a range)

=item *

C<Normal> -- L<Math::Random::OO::Normal> (normal distribution with specified
mean and standard deviation)

=item *

C<Bootstrap> -- L<Math::Random::OO::Bootstrap> (bootstrap resampling from
a non-parameteric distribution)

=back

=head1 INTERFACE

All Math::Random::OO subclasses must follow a standard interface.  They must
provide a C<new> method, a C<seed> method, and a C<next> method.  Specific 
details are left to each interface.

=head2 C<new>

This is the standard constructor.  Each subclass will define parameters specific to the subclass.

=head2 C<seed>

 $prng->seed( @seeds );

This method takes seed (or list of seeds) and uses it to set the initial state
of the random number generator.  As some subclasses may optionally use/require
a list of seeds, the interface mandates that a list must be acceptable.
Generators requiring a single seed must use the first value in the list.

As seeds may be passed to the built-in C<srand()> function, they may be 
truncated as integers, so 0.12 and 0.34 would be the same seed.  Only
positive integers should be used.

=head2 C<next>

 $rnd = $prng->next();

This method returns the next random number from the random number generator.
It does not take (and must not use) any parameters. 

=head1 SEE ALSO

This is not an exhaustive list -- search CPAN for that -- but represents some of
the more common or established random number generators that I've come across.

=over

=item L<Math::Random> -- multiple random number generators for different
distributions (a port of the C randlib)

=item L<Math::Rand48> -- perl bindings for the drand48 library (according to
perl56delta, this may already be the default after perl 5.005_52 if available)

=item L<Math::Random::MT> -- The Mersenne Twister PRNG (good and fast)

=item L<Math::TrulyRandom> -- an interface to random numbers from interrupt timing discrepancies

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/math-random-oo/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/math-random-oo>

  git clone git://github.com/dagolden/math-random-oo.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
