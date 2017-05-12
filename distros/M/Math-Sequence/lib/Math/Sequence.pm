
=head1 NAME

Math::Sequence - Perl extension dealing with mathematic sequences

=head1 SYNOPSIS

  use Math::Sequence;
  my $x_n = Math::Sequence->new('x^2 - 1', 2);
  print $x_n->next(), "\n" foreach 0..9;
  # prints 2, 3, 8, 63...
  
  print $x_n->at_index(5);
  # prints 15745023

  $x_n->cached(0); # don't cache the results (slow!)
  $x_n->cached(1); # cache the results (default)

=head1 DESCRIPTION

Math::Sequence defines a class for simple mathematic sequences with a
recursive definition such as C<x_(n+1) = 1 / (x_n + 1)>. Creation of a
Math::Sequence object is described below in the paragraph about the
constructor.

Math::Sequence uses Math::Symbolic to parse and modify the recursive
sequence definitions. That means you specify the sequence as a string which
is parsed by Math::Symbolic. Alternatively, you can pass the constructor
a Math::Symbolic tree directly.

Because Math::Sequence uses Math::Symbolic for its implementation, all results
will be Math::Symbolic objects which may contain other variables than the
sequence variable itself.

Each Math::Sequence object is an iterator to iterate over the elements of the
sequence starting at the first element (which was specified by the starting
element, the second argument to the new() constructor). It offers
facilities to cache all calculated elements and access any element directly,
though unless the element has been cached in a previous calculation, this
is just a shortcut for repeated use of the iterator.

Every element in the sequence may only access its predecessor, not the elements
before that.

=head2 EXAMPLE

  use strict;
  use warnings;
  use Math::Sequence;
  
  my $seq = Math::Sequence->new('x+a', 0, 'x');
  print($seq->current_index(), ' => ', $seq->next(), "\n") for 1..10;

=cut

package Math::Sequence;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.00';

use Carp;

use Math::Symbolic qw/:all/;

=head2 CLASS DATA

Math::Sequence defines the following package variables:

=over 2

=item $Math::Sequence::Parser

This scalar contains a Parse::RecDescent parser to parse formulas.
It is derived from the Math::Symbolic::Parser grammar.

=cut

our $Parser = Math::Symbolic::Parser->new();

#$Parser->Extend(<<'GRAMMAR');
#GRAMMAR

=item $Math::Sequence::warnings

This scalar indicates whether Math::Sequence should warn about the performance
implications of using the back() method on uncached sequences. It defaults
to true.

=cut

our $warnings = 1;

=pod

=back

=head2 METHODS

=over 2

=item new()

The constructor for Math::Sequence objects. Takes two or three arguments.
In the two argument form, the first argument specifies the recursion
definition. It must be either a string to be parsed by a Math::Symbolic
parser or a Math::Symbolic tree. In the two argument version, the
recursion variable (the one which will be recursively replaced by its
predecessor) will be inferred from the function signature. Thus, the formula
must contain exactly one variable. The second argument must be a starting
value. It may either be a constant or a Math::Symbolic tree or a string to be
parsed as such.

The three argument version adds to the two argument version a string indicating
a variable name to be used as the recursion variable. Then, the recursion
formula may contain any number of variables.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $formula = shift;
    croak "Sequence->new() takes a formula as first argument."
      if not defined $formula;

    my $parsed = $Parser->parse($formula);
    croak "Error parsing formula" if not defined $parsed;

    my $start = shift;
    croak "A starting value must be supplied to Sequence->new() as second\n"
      . "argument."
      if not defined $start;
    $start = $Parser->parse($start);
    croak "Error parsing starting value." if not defined $start;

    my $variable = shift;
    my @sig      = $parsed->signature();

    if ( @sig != 1 and not defined $variable ) {
        croak "Formula must have one variable or a user defined\n"
          . "variable must be supplied.";
    }
    $variable = $sig[0] if not defined $variable;

    my $self = {
        cached        => 1,
        var           => $variable,
        formula       => $parsed,
        current       => 0,
        current_value => $start,
        cache         => [$start],
    };
    return bless $self => $class;
}

=item next()

The next() method returns the next element of the sequence and advances the
iterator by one. This is the prefered method of walking down a sequence's
recursion.

=cut

sub next {
    my $self          = shift;
    my $current_index = $self->{current};
    my $current_value = $self->{current_value};
    my $next_index    = $current_index + 1;

    if ( $self->{cached} and defined $self->{cache}[$next_index] ) {
        $self->{current_value} = $self->{cache}[$next_index];
        $self->{current}       = $next_index;
        return $current_value;
    }

    my $next_value = $self->{formula}->new();
    $next_value->implement( $self->{var} => $current_value );
    $next_value = $next_value->simplify();

    $self->{cache}[$next_index] = $next_value if $self->{cached};
    $self->{current}            = $next_index;
    $self->{current_value}      = $next_value;

    return $current_value;
}

=item cached()

Returns a true value if the sequence is currently being cached, false if it
isn't. By default, new objects have caching enabled. It is suggested that you
only disable caching if space is an issue and you will only walk the sequence
uni-directionally and only once.

cached() can be used to change the caching behaviour. If the first argument is
true, caching will be enabled. If it is false, caching will be disabled.

=cut

sub cached {
    my $self = shift;
    $self->{cached} = shift if @_;
    return $self->{cached};
}

=item current_index()

Returns the index of the current element. That is, the index of the element
that will be returned by the next call to the next() method.

This method also allows (re-)setting the element that will be next returned by
the next() method. In that case, the first argument shoudl be the appropriate
index.

Returns undef and doesn't set the current index if the argument is below 0.

=cut

sub current_index {
    my $self = shift;
    if ( @_ and defined $_[0] ) {
        my $index = shift;
	return undef if $index < 0;
        $self->{current_value} = $self->at_index($index);
        $self->{current}       = $index;
        return $index;
    }
    else {
        return $self->{current};
    }
}

=item at_index()

This method returns the sequence element with the index denoted by the first
argument to the method. It does not change the state of the iterator.
This method is extremely slow for uncached sequences.

Returns undef for indices below 0.

=cut

sub at_index {
    my $self  = shift;
    my $index = shift;
    croak "Sequence->at_index() takes an index as argument."
      if not defined $index;
    return undef if $index < 0;

    return $self->{cache}[$index]
      if $self->{cached}
      and defined $self->{cache}[$index];

    if ( $self->{cached} ) {
        if ( $index > $#{ $self->{cache} } ) {
            my $old_index = $self->{current};
            $self->next() for 1 .. $index - $self->{current};
            my $value = $self->{current_value};
            $self->{current}       = $old_index;
            $self->{current_value} = $self->{cache}[$old_index];
            return $value;
        }
        else {
            return $self->{cache}[$index]
              if defined $self->{cache}[$index];
            my $last_defined = $index;
            while ( not defined $self->{cache}[$last_defined]
                and $last_defined >= 0 )
            {
                $last_defined--;
            }
            die "Sanity check!" if $last_defined < 0;
            my $old_index = $self->{current};
            $self->{current}       = $last_defined;
            $self->{current_value} = $self->{cache}[$last_defined];
            $self->next() for 1 .. $index - $last_defined;
            my $value = $self->{current_value};
            $self->{current}       = $old_index;
            $self->{current_value} = $self->{cache}[$old_index];
            return $value;
        }
    }
    else {    # not $self->{cached}
        return $self->{current_value} if $index == $self->{current};
        my $old_index = $self->{current};
        my $old_value = $self->{current_value};
        my $value;
        if ( $index < $self->{current} ) {
            $self->{current}       = 0;
            $self->{current_value} = $self->{cache}[0];
            $self->next() for 1 .. $index;
            $value = $self->{current_value};
        }
        else {
            $self->next() for 1 .. $index - $old_index;
            $value = $self->{current_value};
        }
        $self->{current}       = $old_index;
        $self->{current_value} = $old_value;
        return $value;
    }
}

=item back()

This methods returns the sequence element previously returned by the next()
method. Since it is extremely slow on uncached sequences, it warns about this
performance hit by default. To turn this warning off, set the
$Math::Sequence::warnings scalar to a false value.

This method decrements the current iterator sequence element.

Returns undef if the current index goes below 0.

=cut

sub back {
    my $self          = shift;
    my $current_index = $self->{current};
    my $current_value = $self->{current_value};
    my $prev_index    = $current_index - 1;
    return undef if $prev_index < 0;

    carp "Use of the back() method on uncached sequence is not advised."
      if ( not $self->{cached} )
      and $Math::Sequence::warnings;

    if ( $self->{cached} and defined $self->{cache}[$prev_index] ) {
        $self->{current_value} = $self->{cache}[$prev_index];
        $self->{current}       = $prev_index;
        return $self->{current_value};
    }

    my $prev_value = $self->at_index($prev_index);
    $self->{current}       = $prev_index;
    $self->{current_value} = $prev_value;

    return $prev_value;
}

1;
__END__

=back

=head1 AUTHOR

Steffen Mueller, E<lt>sequence-module at steffen-mueller dot net<gt>

=head1 SEE ALSO

L<Math::Symbolic> and L<Math::Symbolic::Parser> for the kinds of
formulas accepted by Math::Sequence.

=cut
