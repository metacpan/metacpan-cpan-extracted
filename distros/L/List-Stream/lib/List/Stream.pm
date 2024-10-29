package List::Stream;

use strict;
use warnings;

use Exporter qw(import);
use Carp;
use Scalar::Util qw(refaddr);

our @EXPORT  = qw(stream);
our $VERSION = '0.0.3';

# ABSTRACT: Simple, fast, functional processing of list data

=pod

=head1 Name

L<List::Stream> - Simple Java-like lazy, functionally-pure manipulation of lists.

=head1 Synopsis

L<List::Stream> provides simple functionality for manipulating list data in a functional,
and simple way. L<List::Stream> is lazy, meaning it stores all operations internally, so that they're only evaluated
when entirely necessary.

=head1 Example

    use List::Stream;
    use DBI;

    my $stream = stream DBI->selectall_array('SELECT * FROM users', {Slice => {}});

    # create a sub stream that maps all users to their role
    my $mapped_stream = $stream->map(sub { $_->{role} });
    # to_list applies all pending lazy operations, ie map.
    my $number_of_users  = $mapped_stream->filter(sub { $_ eq 'USER' })->count;
    my $number_of_admins = $mapped_stream->filter(sub { $_ eq 'ADMIN' })->count;

    my %users_by_user_id = $stream->to_hash(sub { $_->{user_id} }, sub { $_ });

    my $it = $mapped_stream->to_iterator;

=cut

=pod

=head2 stream

Create a new L<List::Stream> instance from a list.

    use List::Stream;
    my @data   = (1, 2, 3, 4);
    my $stream = stream @data;

=cut

## no critic [Subroutines::ProhibitSubroutinePrototypes]
sub stream (@) {
    my (@values) = @_;
    return List::Stream->_new( values => [@values] );
}

=pod

=head2 map

Map data in a stream over a unary function. A -> B

    use List::Stream;
    my @data   = (1, 2, 3, 4);
    my $stream = stream @data;
    @data = $stream
        ->map(sub { $_ + 1 })
        ->to_list;
    say @data; # 2, 3, 4, 5

=cut

sub map {
    my ( $self, $mapper ) = @_;

    Carp::croak('Invalid operation provided to map, must be CODE')
      unless ref($mapper) eq 'CODE';

    return $self->_add_op(
        sub {
            my $stream = shift;
            my @accum;
            push @accum, $mapper->($_) for ( $stream->_values->@* );
            return stream @accum;
        }
    );
}

=pod

=head2 reduce

Reduce data to a single element, via a bi-function, with the default accumlator passed as the second arg.
Retrieved by L<List::Stream::first>. If the value reduced to is an ArrayRef, the streams data becomes
the ArrayRef.

    use List::Stream;
    my @data   = (1, 2, 3, 4);
    my $stream = stream @data;
    my $sum = $stream
        ->reduce(sub {
            my ($elem, $accum) = @_;
            $accum += $elem;
        }, 0) # pass default
        ->first;
    say $sum; # 10

=cut

sub reduce {
    my ( $self, $reducer, $accum ) = @_;

    Carp::croak('Invalid operation provided to reduce, must be CODE')
      unless ref($reducer) eq 'CODE';

    Carp::croak('No default/accumulator provided for reduce')
      unless defined $accum;

    return $self->_add_op(
        sub {
            my $stream = shift;
            my $a      = $accum;
            for my $val ( $stream->_values->@* ) {
                $a = $reducer->( $val, $a );
            }
            return stream @$a if ref($a) eq 'ARRAY';
            return stream $a;
        }
    );
}

=pod

=head2 filter

Filters elements from the stream if they do not pass a predicate.

    use List::Stream;
    my @data   = (1, 2, 3, 4);
    my $stream = stream @data;
    @data = $stream
        ->filter(sub { $_ >= 3 })
        ->to_list;
    say @data; # 3, 4

=cut

sub filter {
    my ( $self, $filterer ) = @_;

    Carp::croak('Invalid operation provided to filter, must be CODE')
      unless ref($filterer) eq 'CODE';

    return $self->_add_op(
        sub {
            my $stream = shift;
            my @accum;

            for ( @{ $stream->_values } ) {
                if ( $filterer->($_) ) {
                    push @accum, $_;
                }
            }

            return stream @accum;
        }
    );
}

=pod

=head2 flat_map

Passes the contents of the stream to a mapping function, the mapping function must then return a L<List::Stream>.

    use List::Stream;
    my @data   = (1, 2, 3, 4);
    my $stream = stream @data;
    @data = $stream
        ->flat_map(sub {
            stream(@_)->map(sub { $_ * 2 })
        })
        ->to_list;
    say @data; # 2, 4, 6, 8

=cut

sub flat_map {
    my ( $self, $mapper ) = @_;

    Carp::croak('Invalid operation provided to flat_map, must be CODE')
      unless ref($mapper) eq 'CODE';

    return $self->_add_op(
        sub {
            my $stream     = shift;
            my $new_stream = $mapper->( @{ $stream->_values } );
            Carp::croak(
                'Expected $mapper to return List::Stream, instead got a '
                  . ref($new_stream) )
              unless ref($new_stream) eq 'List::Stream';
            return $new_stream;
        }
    );
}

=pod

=head2 unique

Filters the stream down to only unique values. This uses a HASH to determine uniqueness.

    use List::Stream;
    my $stream = stream qw(a a b c b d e);
    my @values = $stream->unique->to_list;
    say @values; # a, b, c, d, e

If you'd like to use another value to represent the value in the uniquness check you can pass a sub-routine
that will be passed the value, and the result of the sub-routine will be the uniqueness identifier.

    use List::Stream;
    my $stream = stream ({ id => 123 }, { id => 456 }, { id => 123 });
    my @values = $stream->unique(sub { $_->{id} })->to_list;
    say @values; # { id => 123 }, { id => 456 }

=cut

sub unique {
    my ( $self, $mapper ) = @_;

    if ($mapper) {
        Carp::croak('Invalid operation passed to unique, must be CODE')
          unless ref($mapper) eq 'CODE';
    }

    $mapper //= sub { shift };

    return $self->_add_op(
        sub {
            my $stream = shift;
            my %vals;
            my @accum;

            for ( @{ $stream->_values } ) {
                my $unique_value = $mapper->($_);

                if ( ref($unique_value) ) {
                    $unique_value = refaddr $unique_value;
                }

                if ( exists $vals{$unique_value} ) {
                    next;
                }

                $vals{$unique_value} = 1;
                push @accum, $_;
            }

            return stream @accum;
        }
    );
}

=pod

=head2 skip

Skips C<n> elements in the stream, discarding them.

    use List::Stream;
    my @data   = (1, 2, 3, 4);
    my $stream = stream @data;
    @data = $stream
        ->skip(2)
        ->to_list;
    say @data; # 3, 4

=cut

sub skip {
    my ( $self, $n_to_skip ) = @_;

    return $self->_add_op(
        sub {
            my $stream = shift;
            my @values = @{ $stream->_values };
            shift @values for ( 0 .. ( $n_to_skip - 1 ) );
            return stream @values;
        }
    );
}

=pod

=head2 for_each

Applies a void context unary-function to the stream.

    use List::Stream;
    my @data   = (1, 2, 3, 4);
    my $stream = stream @data;
    $stream->for_each(sub { say $_; }); # says 1, then 2, then 3, then 4

=cut

sub for_each {
    my ( $self, $each ) = @_;
    Carp::croak('Invalid operation provided to for_each, must be CODE')
      unless ref($each) eq 'CODE';
    my @elems = $self->to_list;
    $each->($_) for @elems;
}

=pod

=head2 to_list

Applies all pending operations on the stream, and collects them to an array.

    my @data   = (1, 2, 3, 4);
    my $stream = stream(@data)->map(sub { $_ + 1 });
    # The mapping hasn't happened yet, we're lazy.
    @data = $stream->to_list;
    say @data; # 2, 3, 4, 5

=cut

sub to_list {
    my ($self) = @_;
    return @{ $self->_collect( [] ) };
}

=pod

=head2 to_hash

Applies all pending operations on the stream, and collects them to a hash.

    my @data   = (1, 2, 3, 4);
    my $stream = stream(@data)->map(sub { $_ + 1 });
    # The mapping hasn't happened yet, we're lazy.
    my %hash = $stream->to_hash;
    say %hash; # 2 => 3, 4 => 5

You may also provide a key, and value mapper to be applied to each element.

    my @data = (1, 2, 3, 4);
    my $stream = stream(@data)->map(sub { $_ + 1 });
    my %hash = $stream->to_hash(sub { $_ * 2 }, sub { $_ });
    say %hash; # 4 => 2, 6 => 3, 8 => 4, 10 => 5

=cut

sub to_hash {
    my ( $self, $key_mapper, $value_mapper ) = @_;

    if ( $key_mapper && $value_mapper ) {
        Carp::croak(
            'Key or value mapper provided to "to_hash" are not CODE refs.')
          unless ref($key_mapper) eq 'CODE' && ref($value_mapper) eq 'CODE';

        my @data = $self->to_list;
        my %ret;

        for (@data) {
            $ret{ $key_mapper->($_) } = $value_mapper->($_);
        }

        return %ret;
    }

    return %{ $self->_collect( {} ) };
}

=pod

=head2 first

Gets the first element of the stream, and applies all pending operations.
This is useful when using C<List::Stream::reduce>, when you've reduced to a single value.

    use List::Stream;
    my @data   = (1, 2, 3, 4);
    my $stream = stream(@data)->map(sub { $_ + 1 });
    my $first  = $stream->first;
    say $first; # 2

Since reduce reduces the stream to a single element, C<first> can be used to get the reduced value.

    use List::Stream;
    my @data   = (1, 2, 3, 4);
    my $stream = stream(@data)
        ->map(sub { $_ + 1 })
        ->reduce(sub { my ($elem, $accum) = @_; $elem += $accum }, 0);
    my $first  = $stream->first;
    say $first; # 14

=cut

sub first {
    my ($self) = @_;
    my @values = $self->to_list;
    return $values[0];
}

=pod

=head2 is_empty

Applies all pending operations, and returns true if the stream is empty or
false if the stream has at least one value.

    use List::Stream;
    my $stream = stream(1,2,3,4);
    say $stream->filter(sub { $_ > 5 })->is_empty; # true

=cut

sub is_empty {
    my ($self) = @_;
    return $self->count == 0;
}

=pod

=head2 to_iterator

Applies all pending operations on the stream, and returns an iterator in the form of a sub-routine.

    use List::Stream;
    my $stream = stream(qw(a b c d e f g))
        ->map(sub { $_ . 'f' });
    my $it = $stream->to_iterator;
    while (my $val = $it->()) {
        say $val;
    }

=cut

sub to_iterator {
    my ($self) = @_;
    my @values = $self->to_list;
    return sub {
        ## no critic [Subroutines::ProhibitExplicitReturnUndef]
        return undef if !@values;
        return shift @values;
    }
}

=pod

=head2 count

Applies all pending operations on the stream, and returns the count of elements in the stream.

    my $stream = stream(qw(a b c d e f g))
        ->map(sub { $_ . 'f' });
    my $length = $stream->length;
    say $length; # 7

=cut

sub count {
    my ($self) = @_;
    return scalar $self->to_list;
}

sub _collect {
    my ( $self, $type ) = @_;

    my @ops = @{ $self->{ops} };
    while ( my $op = shift @ops ) {
        $self = $op->($self);
    }

    my $ret = $self->_values;
    if ( ref($type) eq 'HASH' ) {
        return {@$ret};
    }

    return $ret;
}

sub _values {
    my ($self) = @_;
    return $self->{values};
}

sub _add_op {
    my ( $self, $op ) = @_;

    Carp::croak('Invalid operation provided, must be CODE')
      unless ref($op) eq 'CODE';

    push @{ $self->{ops} }, $op;

    return $self;
}

sub _new {
    my ( $class, %args ) = @_;
    return bless {
        values => ( $args{values} // [] ),
        ops    => ( $args{ops}    // [] )
    }, $class;
}

1;
