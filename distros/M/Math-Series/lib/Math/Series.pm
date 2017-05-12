
=head1 NAME

Math::Series - Perl extension dealing with mathematic series

=head1 SYNOPSIS

  use Math::Series;
  my $x_n = Math::Series->new( formula       => 'n*x',
                               start_value   => 1,
                               iteration_var => 'n',
                               previous_var  => 'x',
                               start_index   => 0,
                               cached        => 1      );
  
  print $x_n->next(), "\n" foreach 0..5;
  # prints 1, 2, 6, 24...
  
  print $x_n->at_index(3);
  # prints 24

=head1 DESCRIPTION

Math::Series defines a class for simple mathematic series with a
recursive definition such as C<x_(n+1) = 1 / (x_n + 1)>. Such a recursive
definition is treated as a sequence whose elements will be added to form
a series. You can refer to the previous sequence element as well as to the
current index in the series. Creation of a
Math::Series object is described below in the paragraph about the
constructor.

Math::Series uses Math::Symbolic to parse and modify the recursive
sequence definitions. That means you specify the sequence as a string which
is parsed by Math::Symbolic. Alternatively, you can pass the constructor
a Math::Symbolic tree directly.

Because Math::Series uses Math::Symbolic for its implementation, all results
will be Math::Symbolic objects which may contain other variables than the
sequence variable and the iterator variable.

Each Math::Series object is an iterator to iterate over the elements of the
series starting at the first element (which was specified by the starting
element, the second argument to the new() constructor). It offers
facilities to cache all calculated elements and access any element directly,
though unless the element has been cached in a previous calculation, this
is just a shortcut for repeated use of the iterator.

Every element in the series may only access its predecessor, not the elements
before that.

=cut

package Math::Series;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.01';

use Carp;

use Math::Symbolic qw/:all/;
use Math::Sequence;
use base 'Math::Sequence';

=head2 CLASS DATA

Math::Series defines the following package variables:

=over 2

=item $Math::Series::Parser

This scalar contains a Parse::RecDescent parser to parse formulas.
It is derived from the Math::Symbolic::Parser grammar.

=cut

our $Parser = Math::Symbolic::Parser->new();

#$Parser->Extend(<<'GRAMMAR');
#GRAMMAR

=item $Math::Series::warnings

This scalar indicates whether Math::Series should warn about the performance
implications of using the back() method on uncached series. It defaults
to true.

=cut

our $warnings = 1;

=pod

=back

=head2 METHODS

=over 2

=item new()

The constructor for Math::Series objects. It takes named parameters. The
following parameters are required:

=over 2

=item formula

The formula is the recursive definition of a sequence whose elements up to
the current element will be summed to form the current element of the series.
The formula may contain various Math::Symbolic variables that are assigned
a value elsewhere in your code, but it may also contain two special variables:
The number of the current iteration step, starting with 0, and the previous
element of the series.

The formula may be specified as a string that can be parsed by a Math::Symbolic
parser or as a Math::Symbolic tree directly. Please refer to the Math::Symbolic
and Math::Symbolic::Parser man pages for details.

=item start_value

This parameter defines the starting value for the series. It used as the
element in the series that is defined as the lowest series element by the
start_index parameter.
The starting value may be a string that can be parsed as a valid
Math::Symbolic tree or a preconstructed Math::Symbolic tree.

=back

The following parameters are optional:

=over 2

=item iteration_var

The iteration variable is the name of the variable in the Math::Symbolic tree
that refers to the current iteration step. It defaults to the variable 'n'.

It must be a valid Math::Symbolic variable identifier. (That means it is
C</[A-Za-z][A-Za-z0-9_]*/>.)

=item previous_var

The previous_var parameter sets the name of the variable that represents the
previous iteration step. It defaults to the name 'x' and must be a valid
Math::Symbolic variable identifier just like the iteration variable.

=item cached

This parameter indicates whether or not to cache the calculated series'
elements for faster direct access. It defaults to true. At run-time,
the caching behaviour may be altered using the cached() method.

=item start_index

The lower boundary for the series' summation. It defaults to 0, but may be
set to any positive integer or zero.

=back

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    croak "Invalid number of arguments to Math::Series->new()."
      if @_ % 2;

    my %args    = @_;
    my $formula = $args{formula};

    croak "Math::Series->new() requires a formula parameter."
      if not defined $formula;

    my $parsed = $Parser->parse($formula);
    croak "Error parsing formula." if not defined $parsed;

    my $start = $args{start_value};
    croak "A starting value must be supplied to Math::Series->new() as\n"
      . "second argument."
      if not defined $start;
    $start = $Parser->parse($start);
    croak "Error parsing starting value." if not defined $start;

    my $variable = $args{previous_var};
    $variable = 'x' if not defined $variable;

    my $iter_var = $args{iteration_var};
    $iter_var = 'n' if not defined $iter_var;

    my $cached = 1;
    $cached = $args{cached} if exists $args{cached};

    my $start_index = $args{start_index};

    $start_index = 0 if not defined $start_index;

    my $self = {
        cached        => $cached,
        var           => $variable,
        formula       => $parsed,
        current       => $start_index,
        current_value => $start,
        cache         => [$start],
        iter_var      => $iter_var,
        start_index   => $start_index,
    };
    return bless $self => $class;
}

=item next()

The next() method returns the next element of the series and advances the
iterator by one. This is the prefered method of walking down a series'
recursion.

=cut

sub next {
    my $self          = shift;
    my $current_index = $self->{current};
    my $current_value = $self->{current_value};
    my $next_index    = $current_index + 1;
    my $start_index   = $self->{start_index};

    if ( $self->{cached}
        and defined $self->{cache}[ $next_index - $start_index ] )
    {
        $self->{current_value} = $self->{cache}[ $next_index - $start_index ];
        $self->{current}       = $next_index;
        return $current_value;
    }

    my $next_value = $current_value->new();
    my $add        = $self->{formula}->new();
    $add->implement(
        $self->{var}      => $current_value,
        $self->{iter_var} => $current_index + 1
    );
    $add = $add->simplify();
    $next_value += $add;
    $next_value = $next_value->simplify();

    $self->{cache}[ $next_index - $start_index ] = $next_value
      if $self->{cached};
    $self->{current}       = $next_index;
    $self->{current_value} = $next_value;

    return $current_value;
}

=item cached()

Returns a true value if the series is currently being cached, false if it
isn't. By default, new objects have caching enabled. It is suggested that you
only disable caching if space is an issue and you will only walk the series
uni-directionally and only once.

cached() can be used to change the caching behaviour. If the first argument is
true, caching will be enabled. If it is false, caching will be disabled.

=cut

# cached inherited.

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
        return undef if $index < $self->{start_index};
        $self->{current_value} = $self->at_index($index);
        $self->{current}       = $index;
        return $index;
    }
    else {
        return $self->{current};
    }
}

=item at_index()

This method returns the series element with the index denoted by the first
argument to the method. It does not change the state of the iterator.
This method is extremely slow for uncached series.

Returns undef for indices below the starting index.

=cut

sub at_index {
    my $self  = shift;
    my $index = shift;
    croak "Math::Series->at_index() takes an index as argument."
      if not defined $index;
    my $start_index = $self->{start_index};
    return undef if $index < $start_index;

    return $self->{cache}[ $index - $start_index ]
      if $self->{cached}
      and defined $self->{cache}[ $index - $start_index ];

    if ( $self->{cached} ) {
        if ( $index - $start_index > $#{ $self->{cache} } ) {
            my $old_index = $self->{current};
            $self->next() for 1 .. $index - $self->{current};
            my $value = $self->{current_value};
            $self->{current}       = $old_index;
            $self->{current_value} =
              $self->{cache}[ $old_index - $start_index ];
            return $value;
        }
        else {
            return $self->{cache}[ $index - $start_index ]
              if defined $self->{cache}[ $index - $start_index ];
            my $last_defined = $index;
            while ( not defined $self->{cache}[ $last_defined - $start_index ]
                and $last_defined >= $start_index )
            {
                $last_defined--;
            }
            die "Sanity check!" if $last_defined < $start_index;
            my $old_index = $self->{current};
            $self->{current}       = $last_defined;
            $self->{current_value} =
              $self->{cache}[ $last_defined - $start_index ];
            $self->next() for 1 .. $index - $last_defined;
            my $value = $self->{current_value};
            $self->{current}       = $old_index;
            $self->{current_value} =
              $self->{cache}[ $old_index - $start_index ];
            return $value;
        }
    }
    else {    # not $self->{cached}
        return $self->{current_value} if $index == $self->{current};
        my $old_index = $self->{current};
        my $old_value = $self->{current_value};
        my $value;
        if ( $index < $self->{current} ) {
            $self->{current}       = $start_index;
            $self->{current_value} = $self->{cache}[0];
            $self->next() for $start_index .. $index - 1;
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

This methods returns the series element previously returned by the next()
method. Since it is extremely slow on uncached series, it warns about this
performance hit by default. To turn this warning off, set the
$Math::Series::warnings scalar to a false value.

This method decrements the current iterator series element.

Returns undef if the current index goes below the starting index.

=cut

sub back {
    my $self          = shift;
    my $current_index = $self->{current};
    my $current_value = $self->{current_value};
    my $prev_index    = $current_index - 1;
    my $start_index   = $self->{start_index};
    return undef if $prev_index < $start_index;

    carp "Use of the back() method on uncached series is not advised."
      if ( not $self->{cached} )
      and $Math::Series::warnings;

    if ( $self->{cached}
        and defined $self->{cache}[ $prev_index - $start_index ] )
    {
        $self->{current_value} = $self->{cache}[ $prev_index - $start_index ];
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

Steffen Mueller, E<lt>series-module at steffen-mueller dot net<gt>

=head1 SEE ALSO

You may find the current versions of this module at http://steffen-mueller.net/
or on CPAN.

This module is based on L<Math::Sequence>.
L<Math::Symbolic> and L<Math::Symbolic::Parser> for the kinds of
formulas accepted by Math::Series.

=cut
