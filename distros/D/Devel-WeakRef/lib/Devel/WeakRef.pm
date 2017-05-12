package Devel::WeakRef;
use strict;
use integer;
use DynaLoader;
BEGIN {@Devel::WeakRef::ISA=qw(DynaLoader)}
# $Format: "$\Devel::WeakRef::VERSION='$DevelWeakRefRelease$';"$
$Devel::WeakRef::VERSION='0.003';

bootstrap Devel::WeakRef $Devel::WeakRef::VERSION;

package Devel::WeakRef::Table;
use Tie::Hash;
BEGIN {@Devel::WeakRef::Table::ISA=qw(Tie::StdHash)}

1;

__END__

=head1 NAME

B<Devel::WeakRef> - weak references (not reference-counted)

=head1 SYNOPSIS

 my $foo={a => 1, b => 2};	# Some sort of reference scalar.
 my $foo_=new Devel::WeakRef $foo;
 my $bar=$foo_->deref;		# Hard ref through dereference
 $foo_->deref->{c}=3;		# Dereference
 $foo=$bar=77;			# OK, hash collected
 $foo_->deref;			# Yields undef now
 $foo_->empty;			# True now.

Currently this also works:

 $$foo_->{a};

But this dies with a stern message:

 $$foo_=$new_thingy;		# Nope! Weak ref must never change referents.

This hash table has weak references as values:

 tie my %table, Devel::WeakRef::Table;
 $table{key1}=$some_object;
 $table{key2}=$some_other_object;
 $table{key1}=$yet_another_object; # OK to replace keys like this

=head1 DESCRIPTION

A weak reference maintains a "pointer" to an object (specified by a reference to it,
just like C<bless>) that does not contribute to the object's reference count; thus, the
object's storage will be freed (and its destructor invoked) when only weak references
remain to it. (It is fine to have multiple weak references to a single object.) The
B<deref> method derefences the weak reference. Dereferencing a weak reference whose
target has already been destroyed results in C<undef>.

B<empty> tests if the reference is invalid; C<$ref-E<gt>empty> is equivalent to
C<!defined $ref-E<gt>deref>. I<For now>, you can just use Perl's normal scalar
dereference to the same effect; but be sure to use this for reading only. This
interface may change.

The package B<Devel::WeakRef::Table> may be used to tie hashes so as to make their
values all weak references. This is useful for caches in particular, where it would be
more annoying to have to explicitly dereference the value each time.

The most likely applications of this module are:

=over 4

=item Cyclic Structures

Various structures, like arbitrarily-traversable trees, or doubly-linked lists, or some
queues, naturally have cyclic pointer structures in them. If you are not very careful,
removing external references without breaking up the internal links will give you a
memory leak. With weak references, you need only be sure that there is no cyclic
structure of I<hard> (normal) references; back-links and other convenient links can
easily be made weak.

=item Caches

For some applications it is desirable to maintain a cache of lookups (search results)
keyed off (say) search string. The values might be some objects. To have these entries
removed when an object is destroyed, you want to leave each object's reference count
untouched (so it will be collected as it would have otherwise), and make sure its
destructor removes the appropriate keys from the caching table.

=back

=head1 AUTHORS

Jesse Glick, B<jglick@sig.bsh.com>.

=head1 BUGS

If you mess with the internal structure of a weak ref you will probably dump core.

The module attempts to catch attempts to directly set the target of a weak reference in
a scalar dereference operation as an lvalue, and dies abruptly. It tries to do so as
nicely as possible, but it is not feasible to 100% protect the environment in this
case. In other words, if you plan on having this error occur, do not plan on
C<eval-BLOCK>ing it and expecting everything to be dandy later.

Tied weak tables have not been tested as well as the bare references. There may be
unforeseen memory leaks (presumably, not in the referred-to objects themselves, but in
supporting data areas--this would affect raw memory usage, not collection of the
reference targets).

Putting a weak ref on a reference object places extension-magic (C<~>, see
L<perlguts(1P)>) on that object. This could conflict with other user extensions using
custom magic. To avoid this, B<Devel::WeakRef> specifically looks for its own magic and
only its own magic; however, another extension might not do so for itself and become
extremely confused, if it was specifically looking for its own magic (probably not so
common).

=head1 REVISION

X<$Format: "F<$Source$> last modified $Date$, release $DevelWeakRefRelease$. $Copyright$"$>
F<Devel-WeakRef/lib/Devel/WeakRef.pm> last modified Thu, 25 Sep 1997 20:32:00 -0400, release 0.003. Copyright (c) 1997 Strategic Interactive Group. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
