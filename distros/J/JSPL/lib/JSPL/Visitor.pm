package JSPL::Visitor;
1;
__END__

=head1 NAME

JSPL::Visitor - Perl things visiting JavaScript

=head1 DESCRIPTION

As described in L<JSPL/"Round trip integrity"> all perl things that you pass 
I<by reference> to JavaScript land conserve their identity, no matter how
much they have travelled between both interpreters. Thats what you expect.

Upon entering JavaScript land they will become JavaScript objects, and as such
they can be extended.

For example, your ARRAYs visiting JavaScript, as C<PerlArray> instances, can be
extended with some new non-numeric properties, and your perl subroutines,
C<PerlSub> instances, can get a 'prototype' property in its way to become
constructors. That is the way JavaScript works.

Sometimes you need to break the transparency abstraction to known from perl
land how your perl thing is being used on JavaScript.

When you call L<JSPL::Context/jsvisitor> passing to it some reference that is
visiting JavaScript you will get a C<JSPL::Visitor> instance.

That objects allows you to inspect the perl value's I<wrapper object> being
used in JavaScript land.

=head1 INSTANCE METHODS

JSPL::Visitor instances inherits from L<JSPL::Object>. See that page for details.

In addition, JSPL::Visitor object have the following:

=over 4

=item VALID ( )

Returns TRUE if the instance is still valid, FALSE otherwise.

=back

=head1 CAVEATS AND WARNINGS

A perl thing visiting JavaScript becomes a I<visitor> when it enters JavaScript
for the first time, but looses its visitor status as soon as JavaScript garbage
collects it. That is, when the thing's wrapper object isn't referenced in a
property anymore.

Perl values that you C<bind> become a I<visitor> as long as they are binded,
but perl values that you pass as arguments for JavaScript functions calls are
visitors only for the duration of the call, unless the function stores the
reference somewhere.

JSPL::Visitor objects I<don't modify in any way> the life cycle of the object
nor the life cycle of the perl thing.  if you hold a JSPL::Visitor for a long
time, the object can be garbage collected in JavaScript, invalidating the
JSPL::Visitor instance.

You should use only lexical variables in a well defined scope for JSPL::Visitor
instances.

And unless you are playing "Alice in Wonderland", never pass to JavaScript
a JSPL::Visitor. JSPL won't protect you for doing nasty things.
