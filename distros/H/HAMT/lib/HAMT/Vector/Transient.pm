package HAMT::Vector::Transient;

use 5.010;
use strict;
use warnings;

use HAMT ();

our $VERSION = '0.02';

1;

__END__

=head1 NAME

HAMT::Vector::Transient - a vector opened for a batch of updates

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use HAMT::Vector;

    my $v = HAMT::Vector->new('a');

    my $t = $v->transient;
    $t->push($_) for 1 .. 100_000;
    $t->set(0, 'A');
    my $v2 = $t->persistent;

    $v->count;      # 1: the vector it was opened from is unchanged
    $v2->count;     # 100001

=head1 DESCRIPTION

A L<HAMT::Vector> that is changed in place for a while, and then closed into
an ordinary vector that never changes again. It is to a vector what
L<HAMT::Map::Transient> is to a map, and that page says when one is worth
using.

It is made by L<HAMT::Vector/transient>. The vector it was opened from is
not affected by anything done to it, and neither is any other transient
opened from the same vector.

L</push>, L</set> and L</pop> return the transient itself and do not warn in
void context. A transient has no C<list>, C<each> or C<equals>, and no
C<concat>, C<slice>, C<insert> or C<remove>: call L</persistent> first.

A value that is replaced or popped is let go at once, unless some vector
still holds it.

=head1 METHODS

=head2 push

    $t->push($value);
    $t->push(@values)->push($another);

Adds the values at the end and returns the transient.

=head2 pop

    $t->pop;

Removes the last value and returns the transient. Popping an empty transient
leaves it empty.

=head2 set

    $t->set($index, $value);

Replaces the value at the index and returns the transient. The index has to
name an element that is there, as for L<HAMT::Vector/set>.

=head2 get

    my $value = $t->get($index);

The value at the index, or C<undef> when there is none there.

=head2 count

    my $n = $t->count;

The number of values.

=head2 persistent

    my $v = $t->persistent;

An ordinary vector holding what the transient holds, of the class of the
vector the transient was opened from. This does not copy anything.

The transient is closed by it. Every method called on a closed transient
dies with C<this transient is closed>.

=head1 THREADS

A transient belongs to the interpreter that made it and is not inherited by
a new thread.

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
