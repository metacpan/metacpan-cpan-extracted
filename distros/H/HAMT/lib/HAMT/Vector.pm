package HAMT::Vector;

use 5.010;
use strict;
use warnings;

use HAMT ();

our $VERSION = '0.03';

1;

__END__

=head1 NAME

HAMT::Vector - a persistent vector

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use HAMT::Vector;

    my $v  = HAMT::Vector->new(qw(a b c));
    my $v2 = $v->push('d');
    my $v3 = $v2->set(0, 'A');
    my $v4 = $v3->pop;

    $v->count;          # 3: $v is what it always was
    $v3->get(0);        # 'A'
    $v3->get(-1);       # 'd'
    my @all = $v4->list;

    my $both  = $v->concat($v2);        # a b c a b c d
    my $mid   = $both->slice(2, 3);     # c a b
    my $wider = $both->insert(1, 'x');  # a x b c a b c d
    my $fewer = $both->remove(0, 2);    # c a b c d

=head1 DESCRIPTION

An indexed sequence whose every update returns a new vector and leaves the
receiver unchanged. The new vector and the old one share all of their memory
except a few small nodes: one, for most pushes and pops, and one short path
of them for a L</set> in the middle of a million elements.

It can also be cut and joined. L</concat>, L</slice>, L</insert> and
L</remove> copy the nodes along the cut or the join and share everything
else, so putting one value into the middle of a million, or joining two
vectors of a million each, costs a few dozen small nodes and not the
million.

See L<HAMT> for what that is good for.

=head2 Indexes

An index is taken as an array takes one. It counts from zero, a negative
index counts back from the end, and a fraction is cut down to a whole
number.

=head2 Values

Values are treated as L<HAMT::Map> treats them. A value is copied when it is
stored and the copy is read-only; L</get>, L</first>, L</last> and L</list>
hand out the stored scalar itself, so assigning it gives an ordinary copy and
writing to it through an alias dies. A stored reference cannot be replaced,
but what it refers to is still the caller's to change.

=head2 Void context

An update whose result is thrown away has done nothing:

    $v->push('x');  # Useless use of HAMT::Vector::push in void context

Every method that returns a changed vector warns this way, and does nothing:
L</push>, L</pop>, L</set>, L</concat>, L</slice>, L</insert> and
L</remove>. The warning is in the C<void> category and is lexical.

=head1 METHODS

=head2 new

    my $v = HAMT::Vector->new;
    my $v = HAMT::Vector->new(@values);

A vector of the values given, in order.

=head2 push

    my $v2 = $v->push($value);
    my $v2 = $v->push(@values);

A vector with the values added at the end. The receiver is unchanged. With
no values, the receiver itself is returned.

=head2 pop

    my $v2 = $v->pop;

A vector without the last value. The receiver is unchanged. It returns the
vector and not the value, since the vector is the result: read the value
with L</last> first. Popping an empty vector returns it.

=head2 set

    my $v2 = $v->set($index, $value);

A vector with one value replaced. The receiver is unchanged.

The index has to name an element that is there. There is no growing a vector
by setting past its end, as an array grows; use L</push>. An index that is
out of range is an error.

When the value is the very scalar already stored at that index, as in
C<< $v->set(0, $v->get(0)) >>, the receiver itself is returned. Values are
not compared.

=head2 concat

    my $both = $v->concat($other);

A vector of every value of the receiver followed by every value of the
other. Neither is changed, and the result shares with both.

Joining an empty vector on returns the receiver. Joining onto an empty
vector returns the other vector, when that is of the receiver's class.

=head2 slice

    my $part = $v->slice($from);
    my $part = $v->slice($from, $length);

A vector of the values from an index on: all of them, or as many as the
length says. The receiver is unchanged.

A negative start counts back from the end. Nothing here is an error but a
negative length: a start before the beginning is the beginning, a start at
or past the end gives an empty vector, and a length that runs past the end
stops at the end. A slice that is the whole vector returns the receiver.

=head2 insert

    my $v2 = $v->insert($index, @values);

A vector with the values put in before the index, so that the first of them
is at that index in the result. The receiver is unchanged.

The index may be anything from 0 to the count itself, which puts the values
at the end; a negative index counts back from the end, so that C<-1> is
before the last value. Any other index is an error. With no values, the
receiver is returned.

=head2 remove

    my $v2 = $v->remove($index);
    my $v2 = $v->remove($index, $length);

A vector without the value at the index, or without as many as the length
says from there on. The receiver is unchanged.

A length that runs past the end stops at the end, and a negative length is
an error. An index that names no element removes nothing, and then the
receiver is returned, as it is for a length of zero.

=head2 get

    my $value = $v->get($index);

The value at the index, or C<undef> when there is none there.

=head2 first

    my $value = $v->first;

The value at index 0, or C<undef> for an empty vector.

=head2 last

    my $value = $v->last;

The value at the end, or C<undef> for an empty vector.

=head2 count

    my $n = $v->count;

The number of values.

=head2 list

    my @values = $v->list;

Every value, in order. In scalar context, their number.

=head2 to_array

    my $array = $v->to_array;

A reference to a new, ordinary array holding a copy of every value. The
array and its values are writable, and writing to them does not reach the
vector.

=head2 each

    $v->each(sub { my ($value, $index) = @_; ... });

Calls the sub once for every value, in order, with the value and its index,
and returns the vector. The walk cannot be disturbed by anything the sub
does with the vector. A die in the sub passes through and stops the walk.
C<last> and C<next> work as they do in L<HAMT::Map/each>.

=head2 equals

    if ($v->equals($other)) { ... }
    if ($v->equals($other, sub { $_[0] == $_[1] })) { ... }

True when the other thing is a vector holding equal values in the same
order. Anything that is not a vector is not equal, without complaint.

Values are compared as L<HAMT::Map/equals> compares them, and a sub replaces
that rule in the same way. Two versions of one vector are compared for the
parts where they differ, not in full.

=head2 transient

    my $t = $v->transient;
    $t->push($_) for @many;
    my $v2 = $t->persistent;

A L<HAMT::Vector::Transient> that starts out holding what this vector holds,
for a batch of updates made in place. The vector it was opened from never
changes.

=head1 FUNCTIONS

The reads are also functions, for code where the read is the hot part. Each
answers exactly as the method it is named for, and costs less, because a
plain call to one is compiled into the calling code and makes no sub call.

    use HAMT::Vector qw(hamt_vector_get);

    my $value = hamt_vector_get($v, $index);

Nothing is exported unless it is asked for. C<:all> asks for both.

=head2 hamt_vector_get

    my $value = hamt_vector_get($vector, $index);

As L</get>: a negative index counts from the end, and an index outside the
vector is undef.

=head2 hamt_vector_count

    my $n = hamt_vector_count($vector);

As L</count>.

=head2 What differs from a method

Each function has a prototype, so the number of arguments is checked when the
code is compiled, and each argument is in scalar context: an array passed as
an argument is its length, not its elements. A call with an ampersand, or
through a reference, is an ordinary sub call with neither the prototype nor
the saving.

The first argument must be the container itself. A function does not look at
the class, so a subclass that overrides the method is not consulted.

Below perl 5.14 the functions work and are ordinary sub calls.

=head1 SUBCLASSING

A subclass works as expected: L</new> returns an object of the class it was
called on, and every method that returns a changed vector returns one of the
receiver's class. A subclass may define a C<DESTROY> of its own.

An object of this class cannot be made by blessing something else into it.

=head1 THREADS

A vector belongs to the interpreter that made it and is not inherited by a
new thread.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hamt at rt.cpan.org>, or
through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=HAMT>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
