package HAMT::Map;

use 5.010;
use strict;
use warnings;

use HAMT ();

our $VERSION = '0.02';

1;

__END__

=head1 NAME

HAMT::Map - a persistent map from strings to values

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use HAMT::Map;

    my $m  = HAMT::Map->new(a => 1, b => 2);
    my $m2 = $m->set(c => 3);
    my $m3 = $m2->delete('a');

    $m->count;      # 2: $m is what it always was
    $m2->count;     # 3
    $m3->count;     # 2

    $m2->get('c');          # 3
    $m2->exists('zz');      # false
    my @keys = $m2->keys;
    my %copy = $m2->pairs;

=head1 DESCRIPTION

A map whose every update returns a new map and leaves the receiver unchanged.
The new map and the old one share all of their memory except the handful of
small nodes on the way to the key that changed, so keeping both costs little
and making the new one does not copy the old.

See L<HAMT> for what that is good for.

=head2 Keys

A key is a string, and two keys are the same key exactly when a Perl hash
would say so. A number is the key its string form is, a reference is the key
its string form is, and C<undef> is the empty string, with the usual warning.

=head2 Values

A value is copied when it is stored, and the copy is read-only. L</get> hands
out that stored scalar itself and not another copy of it, so:

    my $v = $m->get('k');       # an ordinary copy, yours to change
    $_++ for $m->get('k');      # dies: Modification of a read-only value

The second line is the map keeping its promise. Every version that holds the
entry shares the one scalar, and a write through an alias would change them
all.

It is shallow. A stored reference cannot be replaced, but what it refers to
is still the caller's:

    my $m  = HAMT::Map->new(list => [1, 2]);
    my $m2 = $m->set(other => 1);
    push @{ $m->get('list') }, 3;
    # $m and $m2 both see [1, 2, 3]: they share the one array

Store data you do not intend to change, or a copy of it.

=head2 Order

L</keys>, L</values> and L</pairs> return entries in an order that is the
same for all three and stays the same for a given map for the life of the
process. It is not sorted, it is not insertion order, and it differs from
one process to the next.

=head2 Void context

An update whose result is thrown away has done nothing, and is nearly always
a mistake carried over from a hash:

    $m->set(k => 1);    # Useless use of HAMT::Map::set in void context

L</set>, L</delete>, L</update> and L</merge> all warn this way, and do
nothing. The warning is in the C<void> category and is lexical, so
C<no warnings 'void'> silences it where it is meant.

=head1 METHODS

=head2 new

    my $m = HAMT::Map->new;
    my $m = HAMT::Map->new(a => 1, b => 2);

A map holding the pairs given. Where a key is given twice the later pair
wins. An odd number of arguments is an error.

Called on an existing map it makes a new map of that map's class, and does
not copy the receiver.

=head2 from_hash

    my $m = HAMT::Map->from_hash(\%h);

A map holding every pair of the hash. The values are copied, so the map does
not follow the hash afterwards.

=head2 set

    my $m2 = $m->set($key => $value);
    my $m2 = $m->set(a => 1, b => 2);

A map that holds everything the receiver holds, and these pairs as well or
instead. The receiver is unchanged.

When nothing would change, the receiver itself is returned. That is the case
with no pairs, and when a key is set to the very scalar it already holds, as
in C<< $m->set(k => $m->get('k')) >>. Values are not compared: setting a key
to an equal value from elsewhere makes a new map.

=head2 delete

    my $m2 = $m->delete($key);
    my $m2 = $m->delete(@keys);

A map that holds everything the receiver holds but these keys. The receiver
is unchanged. When none of the keys is present, the receiver itself is
returned.

=head2 get

    my $value = $m->get($key);

The value stored under the key, or C<undef> when there is none. A stored
C<undef> and a missing key look the same here; L</exists> tells them apart.

=head2 exists

    if ($m->exists($key)) { ... }

True when the key is in the map, whatever its value.

=head2 count

    my $n = $m->count;

The number of keys.

=head2 keys

    my @keys = $m->keys;

Every key. In scalar context, the number of keys.

=head2 values

    my @values = $m->values;

Every value, in the order L</keys> gives their keys. In scalar context, the
number of values.

=head2 pairs

    my %h = $m->pairs;

Every key followed by its value, as one flat list. In scalar context, the
number of pairs.

=head2 to_hash

    my $h = $m->to_hash;

A reference to a new, ordinary hash holding a copy of every pair. The hash
and its values are writable, and writing to them does not reach the map.

=head2 each

    $m->each(sub {
        my ($key, $value) = @_;
        ...
    });

Calls the sub once for every pair, in the order L</keys> gives, and returns
the map. The value is the stored, read-only scalar; the key is a copy.

The walk cannot be disturbed. The sub may build new maps from this one, or
let go of this one altogether, and the walk carries on over the map as it
was. If the sub dies, the error passes through and the walk stops there.

C<last> in the sub stops the walk, and C<next> goes on to the next pair, as
they would in the body of a loop. Perl warns C<Exiting subroutine via last>
as it does for any sub that does that; C<no warnings 'exiting'> in the sub
silences it. C<redo> is an error.

=head2 update

    my $m2 = $m->update(hits => sub { ($_[0] // 0) + 1 });

A map in which one key's value has been replaced by what the sub makes of
it. The sub is called once, in scalar context, with the current value, or
C<undef> when the key is not there, and what it returns is stored.

When the sub returns a value equal to the one already stored, nothing
changes and the receiver itself is returned. Equal here means what
L</equals> means by it.

C<last> or C<next> in the sub is the error perl gives outside a loop, and
so it is in the subs given to L</merge> and L</equals>.

=head2 merge

    my $all = $m->merge($other);
    my $sum = $m->merge($other, sub {
        my ($key, $mine, $theirs) = @_;
        return $mine + $theirs;
    });

A map holding every key of both. For a key that is in both, the other map's
value wins; or, when a sub is given, the sub is called in scalar context
with the key and the two values and what it returns is the value.

The sub is asked only about keys that are in both maps with values that are
not the same stored scalar, so merging two versions of one map asks about
what changed between them and nothing else. It costs accordingly: the parts
the two maps share are not visited at all.

When the result would be exactly the receiver, the receiver is returned;
when it would be exactly the other map, and that is of the receiver's class,
the other map is returned. Otherwise the result is a new map of the
receiver's class.

If the sub dies, the error passes through unchanged and no map is returned.

=head2 equals

    if ($m->equals($other)) { ... }
    if ($m->equals($other, sub { $_[0] == $_[1] })) { ... }

True when the other thing is a map holding the same keys with equal values.
Anything that is not a map is not equal, without complaint.

Two values are equal when they are the same stored scalar; or both are
references to the same thing; or neither is a reference and they are the
same string; or both are C<undef>. So C<1> equals C<"1"> and does not equal
C<"1.0">, and two different arrays with the same contents are not equal.

A sub, when given, replaces that rule: it is called with two values and its
truth is the answer. It is not asked about a pair that is one and the same
scalar, and it cannot make two maps with different keys equal.

Two versions of one map are compared along the paths where they differ, not
in full.

=head2 diff

    my $n = $old->diff($new, sub {
        my ($key, $was, $now, $kind) = @_;
        ...
    });

Calls the sub once for every key that is in one map and not the other, or in
both with values that are not equal as L</equals> compares them, and returns
how many keys that was. C<$kind> is one of:

=over 4

=item C<add>

The key is in C<$new> only. C<$was> is C<undef>.

=item C<remove>

The key is in C<$old> only. C<$now> is C<undef>.

=item C<change>

The key is in both.

=back

The kind is what tells a key that was removed from one whose value became
C<undef>. The order of the calls is not promised.

Like L</merge>, this costs what differs: two versions of one map are
compared without visiting what they share. A die in the sub passes through
and stops the walk. C<last> stops it too, and the count is of the calls
made; C<next> goes on, as in L</each>.

=head2 key_set

    my $keys = $m->key_set;

The map's keys as a L<HAMT::Set>, for the set operations: which keys two
maps share, which one has that the other lacks.

=head2 transient

    my $t = $m->transient;
    $t->set(a => 1)->set(b => 2)->delete('c');
    my $m2 = $t->persistent;

A L<HAMT::Map::Transient> that starts out holding what this map holds. It is
for a batch of updates: it is changed in place, call after call, and closed
into an ordinary map at the end. The map it was opened from never changes.

=head1 FUNCTIONS

The reads are also functions, for code where the read is the hot part. Each
answers exactly as the method it is named for, and costs less, because a
plain call to one is compiled into the calling code and makes no sub call.

    use HAMT::Map qw(hamt_map_get hamt_map_exists);

    my $value = hamt_map_get($m, $key);
    next unless hamt_map_exists($m, $key);

Nothing is exported unless it is asked for. C<:all> asks for all three.

=head2 hamt_map_get

    my $value = hamt_map_get($map, $key);

As L</get>: the stored value, or undef where there is none.

=head2 hamt_map_exists

    if (hamt_map_exists($map, $key)) { ... }

As L</exists>.

=head2 hamt_map_count

    my $n = hamt_map_count($map);

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

A subclass works as expected: L</new> and L</from_hash> return an object of
the class they were called on, and L</set>, L</delete>, L</update> and
L</merge> return one of the receiver's class. A subclass may define a C<DESTROY> of its own.

An object of this class cannot be made by blessing something else into it.
Every method refuses such an object by name.

=head1 THREADS

A map belongs to the interpreter that made it. A new thread does not inherit
the maps of the thread that started it: in the new thread those variables
hold a reference that is not a map. Maps a thread makes itself work normally.

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
