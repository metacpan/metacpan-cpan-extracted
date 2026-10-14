package HAMT;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('HAMT', $VERSION);

1;

__END__

=head1 NAME

HAMT - hash array mapped trie

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use HAMT::Map;

    my $m  = HAMT::Map->new(a => 1, b => 2);
    my $m2 = $m->set(c => 3);
    my $m3 = $m2->set(a => 10)->delete('b');

    $m->get('a');        # 1: $m is what it always was
    $m->exists('c');     # false
    $m2->get('c');       # 3
    $m3->get('a');       # 10, and $m2 still says 1

    use HAMT::Set;
    my $s  = HAMT::Set->new(qw(red green));
    my $s2 = $s->add('blue');
    my $both = $s->intersect($s2);

    use HAMT::Vector;
    my $v  = HAMT::Vector->new(1, 2, 3);
    my $v2 = $v->push(4)->set(0, 'one');
    my $v3 = $v->concat($v2)->slice(2, 3);

=head1 DESCRIPTION

A persistent container is one where an update returns a new container and
leaves the one it was called on exactly as it was. The two share nearly all of
their memory, so keeping the old one costs a few small nodes and not a copy.

That makes a snapshot, an undo step or a value handed to code that must not
change it as cheap as holding a reference.

"Persistent" here is about versions, not storage. Nothing is written to disk.

The name is the structure underneath. A hash array mapped trie is a tree 32
wide in which a key's place is read off its hash, five bits to a level, and
each node stores only the places that are taken. L<HAMT::Map> and
L<HAMT::Set> are one. Changing a key means replacing the few nodes between
the root and that key, a handful even among millions, and every other node
is shared between the old version and the new. L<HAMT::Vector> is the same
kind of tree read by position instead of by hash.

The containers are L<HAMT::Map>, L<HAMT::Set> and L<HAMT::Vector>. This
module loads them.

=head2 When to use one, and when not

Use one where a program would otherwise copy a hash or an array in order to
change it: a snapshot taken before a risky step, a stack of undo states, a
configuration handed to code that must not alter it, a set compared with an
earlier version of itself. A single update is thousands of times cheaper
than the copy, and two versions of one container are merged or compared by
looking only at where they differ.

Do not use one for a hash that is built once and then only read.

=head2 Values are shared, and read-only

A value is copied when it is stored and the stored copy is read-only. Reading
it hands out that scalar and not another copy, so an attempt to change it in
place dies. Every version that holds the value shares the one scalar.

This is shallow. A stored reference cannot be replaced, but what it refers
to is still the caller's to change, and every version sees the change:

    my $m  = HAMT::Map->new(list => [1, 2]);
    my $m2 = $m->set(other => 1);
    push @{ $m->get('list') }, 3;
    # $m and $m2 both see [1, 2, 3]

Store data you do not intend to change, or a copy of it. A container stored
in a container is safe all the way down.

=head2 Void context

An update whose result is thrown away has done nothing, which is nearly
always a mistake carried over from a hash:

    $m->set(k => 1);    # Useless use of HAMT::Map::set in void context

Every method that returns a new container warns this way and does nothing.
The warning is in the C<void> category, so C<no warnings 'void'> silences it
where it is meant.

=head2 Order

A map's keys and a set's members come back in an order that stays the same
for that container for the life of the process. It is not sorted, it is not
insertion order, and it differs from one process to the next. A vector is in
index order.

=head2 Threads

A container belongs to the interpreter that made it. A new thread does not
inherit the containers of the thread that started it: there those variables
hold a reference that is not a container. Containers a thread makes itself
work normally.

=head2 Serialising

A container is not data a serialiser can copy. What L<Storable> makes of one
is an object that every method refuses. Turn it into plain data first, with
C<to_hash> on a map, C<members> on a set or C<to_array> on a vector, and
build it again on the other side with C<from_hash> or C<new>.


=head1 FUNCTIONS

Each class also exports its reads as functions, for code where the read is
the hot part: C<hamt_map_get>, C<hamt_map_exists> and C<hamt_map_count> from
L<HAMT::Map>, C<hamt_set_has> and C<hamt_set_count> from L<HAMT::Set>,
C<hamt_vector_get> and C<hamt_vector_count> from L<HAMT::Vector>.

    use HAMT::Map qw(hamt_map_get);

    my $value = hamt_map_get($m, $key);

A plain call to one is compiled into the calling code and makes no sub call.
Each class documents its own.

=head1 PERFORMANCE

One run on one machine (Apple M5, perl 5.42.0). The
distribution's F<bench> directory has the scripts.

    one set on 10,000 keys            3,000 times faster than copying the hash
    one set on a vector of 100,000    3,000 times faster than copy and set
    insert in the middle of 100,000   3.5 times faster than splice in place
    union of two versions of a set    5,000 times faster than (%a, %b)
    1,000 versions of a 10,000-key map   1/249 the memory of 1,000 copies
    1,000,000 keys in a map           0.69 times the memory of a hash

    get of a present key              2.1 times slower than a hash fetch
    the same, by hamt_map_get         1.7 times slower
    get from a vector                 2.6 times slower than an array fetch
    the same, by hamt_vector_get      1.4 times slower
    building 100,000 keys             1.4 to 1.9 times slower than a hash
    building 1,000,000 keys           about level with a hash

To build, use C<new>, C<from_hash> or a transient: an update at a time in a
loop is several times slower than any of them.


=head1 C ABI

Everything the three classes do from Perl can be done from another
extension's C, with no Perl call in between: reading, updating, walking,
merging, comparing, cutting and joining, and moving containers to and from
Perl objects, hashes and arrays. A loop that would cost a method call for
each element costs a function call instead.

The interface is one header, F<hamt_abi.h>, which is installed with the
module. A consuming distribution finds it with L<ExtUtils::Depends>:

    my $pkg = ExtUtils::Depends->new('My::Module', 'HAMT');

and resolves the table once, when it loads; the header shows how. Nothing is
linked against: the table is found at run time, and it is versioned, so the
two distributions can be upgraded independently. It is at version 1.

The header is the reference. It says who owns what, which entries change the
container they are given, and how each one reports failure.

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
