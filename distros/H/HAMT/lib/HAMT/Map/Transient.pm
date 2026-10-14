package HAMT::Map::Transient;

use 5.010;
use strict;
use warnings;

use HAMT ();

our $VERSION = '0.02';

1;

__END__

=head1 NAME

HAMT::Map::Transient - a map opened for a batch of updates

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use HAMT::Map;

    my $m = HAMT::Map->new(a => 1);

    my $t = $m->transient;
    $t->set("key$_" => $_) for 1 .. 100_000;
    $t->delete('a');
    my $m2 = $t->persistent;

    $m->count;      # 1: the map it was opened from is unchanged
    $m2->count;     # 100000

=head1 DESCRIPTION

A L<HAMT::Map> pays for never changing: each update makes a new map, and a
loop of a hundred thousand updates makes a hundred thousand of them, all but
the last thrown away at once.

A transient is the same map with that promise suspended for a while. It is
made by L<HAMT::Map/transient>, it B<is> changed by L</set> and L</delete>,
and L</persistent> turns it back into an ordinary map that never changes
again. The map it was opened from is not affected by any of it, and neither
is any other map or transient opened from the same one.

Use one where a piece of code builds or reworks a map in several steps and
nobody else needs to see the steps in between. C<< HAMT::Map->new >>,
C<from_hash> and a C<set> or C<delete> with several arguments already work
this way inside, so a transient is for the loops those cannot express.

=head2 Differences from a map

L</set> and L</delete> return the transient itself, and do not warn in void
context.

A transient has no C<keys>, C<each>, C<merge> or C<equals>. Call
L</persistent> first; it costs nothing, and L<HAMT::Map/transient> on the
result opens another.

A value that is replaced or deleted is let go at once, unless some map still
holds it.

=head1 METHODS

=head2 set

    $t->set($key => $value);
    $t->set(a => 1, b => 2)->set(c => 3);

Stores the pairs in the transient and returns the transient. Keys and values
are treated exactly as L<HAMT::Map/set> treats them.

=head2 delete

    $t->delete($key);
    $t->delete(@keys);

Removes the keys from the transient and returns the transient. A key that is
not there is ignored.

=head2 get

    my $value = $t->get($key);

The value stored under the key, or C<undef> when there is none.

=head2 exists

    if ($t->exists($key)) { ... }

True when the key is in the transient.

=head2 count

    my $n = $t->count;

The number of keys.

=head2 persistent

    my $m = $t->persistent;

An ordinary map holding what the transient holds, of the class of the map
the transient was opened from. This does not copy anything.

The transient is closed by it. Every method called on a closed transient
dies with C<this transient is closed>, including a second C<persistent>.

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
