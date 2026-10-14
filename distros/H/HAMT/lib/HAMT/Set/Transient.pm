package HAMT::Set::Transient;

use 5.010;
use strict;
use warnings;

use HAMT ();

our $VERSION = '0.02';

1;

__END__

=head1 NAME

HAMT::Set::Transient - a set opened for a batch of updates

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use HAMT::Set;

    my $s = HAMT::Set->new('a');

    my $t = $s->transient;
    $t->add("member$_") for 1 .. 100_000;
    $t->remove('a');
    my $s2 = $t->persistent;

    $s->count;      # 1: the set it was opened from is unchanged
    $s2->count;     # 100000

=head1 DESCRIPTION

A L<HAMT::Set> that is changed in place for a while, and then closed into an
ordinary set that never changes again. It is to a set what
L<HAMT::Map::Transient> is to a map, and that page says when one is worth
using.

It is made by L<HAMT::Set/transient>. The set it was opened from is not
affected by anything done to it, and neither is any other transient opened
from the same set.

L</add> and L</remove> return the transient itself and do not warn in void
context. A transient has no C<members>, C<each>, C<union>, C<intersect>,
C<difference> or C<equals>: call L</persistent> first.

=head1 METHODS

=head2 add

    $t->add($member);
    $t->add(@members)->add($another);

Adds the members to the transient and returns the transient.

=head2 remove

    $t->remove($member);
    $t->remove(@members);

Removes the members from the transient and returns the transient. One that
is not there is ignored.

=head2 has

    if ($t->has($member)) { ... }

True when it is a member.

=head2 count

    my $n = $t->count;

The number of members.

=head2 persistent

    my $s = $t->persistent;

An ordinary set holding what the transient holds, of the class of the set
the transient was opened from. This does not copy anything.

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
