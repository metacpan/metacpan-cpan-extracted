package HAMT::Set;

use 5.010;
use strict;
use warnings;

use HAMT ();

our $VERSION = '0.03';

1;

__END__

=head1 NAME

HAMT::Set - a persistent set of strings

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use HAMT::Set;

    my $s  = HAMT::Set->new(qw(a b c));
    my $s2 = $s->add('d');
    my $s3 = $s2->remove('a');

    $s->count;      # 3: $s is what it always was
    $s2->has('d');  # true

    my $both   = $s->intersect($s3);
    my $either = $s->union($s3);
    my $mine   = $s->difference($s3);

    $both->is_subset($s);       # true
    $mine->is_disjoint($s3);    # true

=head1 DESCRIPTION

A set whose every update returns a new set and leaves the receiver unchanged.
The new set and the old one share all of their memory except the handful of
small nodes on the way to the member that changed.

See L<HAMT> for what that is good for, and L<HAMT::Map> for the same thing
with a value for each key.

=head2 Members

A member is a string, and two members are the same member exactly when a
Perl hash would call them the same key. So a number is the member its string
form is, C<undef> is the empty string, with the usual warning, and a set of
references is a set of their string forms: the set does not keep the things
they refer to alive, and cannot give them back.

=head2 Cost

L</union>, L</intersect>, L</difference>, L</is_subset>, L</is_disjoint> and
L</equals> compare two sets part against part, and a part the two sets share
is not looked into at all. Two sets that are versions of one another, a few
updates apart, are combined or compared for about what those few updates
cost. Two sets built separately cost what they hold.

=head2 Order

L</members> returns members in an order that stays the same for a given set
for the life of the process. It is not sorted, it is not insertion order, and
it differs from one process to the next.

=head2 Void context

An update whose result is thrown away has done nothing:

    $s->add('x');   # Useless use of HAMT::Set::add in void context

L</add>, L</remove>, L</union>, L</intersect> and L</difference> all warn
this way, and do nothing. The warning is in the C<void> category and is
lexical.

=head1 METHODS

=head2 new

    my $s = HAMT::Set->new;
    my $s = HAMT::Set->new(@members);

A set of the members given. One given twice is in the set once.

=head2 add

    my $s2 = $s->add($member);
    my $s2 = $s->add(@members);

A set holding everything the receiver holds and these as well. The receiver
is unchanged. When every one of them is already a member, the receiver
itself is returned.

=head2 remove

    my $s2 = $s->remove($member);
    my $s2 = $s->remove(@members);

A set holding everything the receiver holds but these. The receiver is
unchanged. When none of them is a member, the receiver itself is returned.

=head2 has

    if ($s->has($member)) { ... }

True when it is a member.

=head2 count

    my $n = $s->count;

The number of members.

=head2 members

    my @members = $s->members;

Every member. In scalar context, their number.

=head2 each

    $s->each(sub { my ($member) = @_; ... });

Calls the sub once for every member, in the order L</members> gives, and
returns the set. The walk cannot be disturbed by anything the sub does with
the set. A die in the sub passes through and stops the walk. C<last> and
C<next> work as they do in L<HAMT::Map/each>.

=head2 union

    my $either = $s->union($other);

A set of everything that is in either.

When that is exactly the receiver, the receiver is returned; when it is
exactly the other set, and that is of the receiver's class, the other set is
returned.

=head2 intersect

    my $both = $s->intersect($other);

A set of everything that is in both. When that is exactly the receiver, the
receiver is returned.

=head2 difference

    my $mine = $s->difference($other);

A set of everything in the receiver that is not in the other. When the two
have nothing in common, the receiver is returned.

=head2 is_subset

    if ($s->is_subset($other)) { ... }

True when every member of the receiver is a member of the other. The empty
set is a subset of every set, and every set is a subset of itself.

=head2 is_disjoint

    if ($s->is_disjoint($other)) { ... }

True when the two have no member in common.

=head2 equals

    if ($s->equals($other)) { ... }

True when the other thing is a set with the same members. Anything that is
not a set is not equal, without complaint; a L<HAMT::Map> is not a set.

=head2 transient

    my $t = $s->transient;
    $t->add($_) for @many;
    my $s2 = $t->persistent;

A L<HAMT::Set::Transient> that starts out holding what this set holds, for a
batch of updates made in place. The set it was opened from never changes.

=head1 FUNCTIONS

The reads are also functions, for code where the read is the hot part. Each
answers exactly as the method it is named for, and costs less, because a
plain call to one is compiled into the calling code and makes no sub call.

    use HAMT::Set qw(hamt_set_has);

    next unless hamt_set_has($s, $member);

Nothing is exported unless it is asked for. C<:all> asks for both.

=head2 hamt_set_has

    if (hamt_set_has($set, $member)) { ... }

As L</has>.

=head2 hamt_set_count

    my $n = hamt_set_count($set);

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
called on, and every method that returns a new set returns one of the
receiver's class. A subclass may define a C<DESTROY> of its own.

An object of this class cannot be made by blessing something else into it.

=head1 THREADS

A set belongs to the interpreter that made it and is not inherited by a new
thread.

=head1 SEE ALSO

L<HAMT::Map/key_set> makes a set of a map's keys.

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
