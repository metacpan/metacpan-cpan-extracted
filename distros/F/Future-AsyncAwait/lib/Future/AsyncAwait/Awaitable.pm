#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019-2024 -- leonerd@leonerd.org.uk

package Future::AsyncAwait::Awaitable 0.70;

use v5.14;
use warnings;

=head1 NAME

C<Future::AsyncAwait::Awaitable> - the interface required by C<Future::AsyncAwait>

=head1 DESCRIPTION

=for highlighter language=perl

This module documents the method interface required by C<Future::AsyncAwait>
to operate on future instances returned by expressions invoked by the C<await>
keyword, and returned by functions declared by C<async sub>. This information
is largely of relevance to implementors of other module integrations, event
systems, or similar. It is not necessary to make regular use of the syntax
provided by the module when working with existing event systems.

The methods required by this interface are all capitalised and prefixed with
C<AWAIT_...>, ensuring they are unlikely to clash with existing methods on a
class which may have differing semantics.

=head2 Role::Tiny

If L<Role::Tiny> is available, this module declares itself to be a role that
requires the following named methods. The role supplies no code to the applied
class, but can be useful for checking that you have in fact implemented all of
the required methods.

=head2 Conformance Test

To assist implementors of alternative future-like classes, an API conformance
test suite is provided by L<Test::Future::AsyncAwait::Awaitable>. You may find
this useful to check that your implementation is suitable.

=cut

if( defined eval { require Role::Tiny } ) {
   Role::Tiny->import;

   requires( qw(
      AWAIT_CLONE AWAIT_NEW_DONE AWAIT_NEW_FAIL

      AWAIT_DONE AWAIT_FAIL AWAIT_GET
      AWAIT_IS_READY AWAIT_ON_READY
      AWAIT_IS_CANCELLED AWAIT_ON_CANCEL

      AWAIT_WAIT
   ) );
}

=head1 CONSTRUCTORS

The following methods are expected to create new future instances. They make
use of the class set by the prevailing C<future_class> import argument, if
set, or default to C<Future> if not.

=head2 AWAIT_NEW_DONE

Generate a new immediate future that is successful. The future will already be
ready and have the list of values set as its result.

   $f = $CLASS->AWAIT_NEW_DONE( @results );

   # $f->AWAIT_IS_READY will be true
   # $f->AWAIT_GET will return @results

=head2 AWAIT_NEW_FAIL

Generate a new immediate future that is failed. The future will already be
ready and invoking the L</AWAIT_GET> method will throw the given exception.

   $f = $CLASS->AWAIT_NEW_FAIL( $message );

   # $f->AWAIT_IS_READY will be true
   # $f->AWAIT_GET will throw $message

=head1 INSTANCE METHODS

=head2 AWAIT_CLONE

Generate a new pending future of the same type as an existing one, which is
not modified by doing so. It will only be invoked on instances that are
currently pending.

   $new_f = $f->AWAIT_CLONE;

If the instance has any fields that are required for successful operation
(such as application-wide context or event system components) these ought to
be copied. The method should not otherwise copy any per-instance state such
as pending callbacks or partial results.

=head2 AWAIT_DONE

Sets the success result of an existing still-pending future. It will only be
invoked on future instances that are currently pending.

   $f->AWAIT_DONE( @results );

   # $f->AWAIT_IS_READY will now be true
   # $f->AWAIT_GET will now return @results

=head2 AWAIT_FAIL

Sets the failure result of an existing still-pending future. It will only be
invoked on future instances that are currently pending.

   $f->AWAIT_FAIL( $message );

   # $f->AWAIT_IS_READY will now be true
   # $f->AWAIT_GET will now throw $message

=head2 AWAIT_IS_READY

Returns true if a future is ready (successful, failed or cancelled); false if
still pending.

   $bool = $f->AWAIT_IS_READY;

=head2 AWAIT_IS_CANCELLED

Returns true is a future has already been cancelled; false if still pending,
successful or failed.

   $bool = $f->AWAIT_IS_CANCELLED;

An implementation that does not support cancellation can simply return a
constant false here:

   sub AWAIT_IS_CANCELLED { 0 }

=head2 AWAIT_GET

Yields the result of a successful future (or just the first value if called in
scalar context). Throws the failure message as an exception if called on a a
failed one. Will not be invoked on a pending or cancelled future.

   @result = $f->AWAIT_GET;
   $result = $f->AWAIT_GET;
   $f->AWAIT_GET;

=head2 AWAIT_ON_READY

Attach a new CODE reference to be invoked when the future becomes ready (by
success or failure). The arguments and context that C<$code> is invoked with
are unspecified.

   $f->AWAIT_ON_READY( $code );

=head2 AWAIT_CHAIN_CANCEL

Attach a future instance to be cancelled when another one is cancelled.

   $f1->AWAIT_CHAIN_CANCEL( $f2 );

When C<$f1> is cancelled, then C<$f2> is cancelled. There is no link from
C<$f2> back to C<$f1> - whenever C<$f2> changes state here, nothing special
happens to C<$f1>.

An implementation that does not support cancellation can simply ignore this
method.

   sub AWAIT_CHAIN_CANCEL { }

An older version of this API specification named this C<AWAIT_ON_CANCEL>, but
that name will be repurposed for attaching code blocks in a later version.

=head2 AWAIT_ON_CANCEL

Attach a new CODE reference to be invoked when the future is cancelled.

   $f->AWAIT_ON_CANCEL( $code );

An implementation that does not support cancellation can simply ignore this
method.

   sub AWAIT_ON_CANCEL { }

=head2 AWAIT_WAIT

Called by the toplevel C<await> expression in order to run the event system
and wait for the instance to be ready. It should return results or throw an
exception in the same manner as L</AWAIT_GET>.

   @result = $f->AWAIT_WAIT;
   $result = $f->AWAIT_WAIT;
   $f->AWAIT_WAIT;

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
