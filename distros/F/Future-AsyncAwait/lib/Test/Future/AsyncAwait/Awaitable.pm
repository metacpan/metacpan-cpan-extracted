#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Test::Future::AsyncAwait::Awaitable 0.54;

use v5.14;
use warnings;

use Test::More;

use Exporter 'import';
our @EXPORT_OK = qw(
   test_awaitable
);

=head1 NAME

C<Test::Future::AsyncAwait::Awaitable> - conformance tests for awaitable role API

=head1 SYNOPSIS

   use Test::More;
   use Test::Future::AsyncAwait::Awaitable;

   use My::Future::Subclass;

   test_awaitable "My subclass of Future",
      class => "My::Future::Subclass";

   done_testing;

=head1 DESCRIPTION

This module provides a single test function, which runs a suite of subtests to
check that a given class provides a useable implementation of the
L<Future::AsyncAwait::Awaitable> role. It runs tests that simulate various
ways in which L<Future::AsyncAwait> will try to use an instance of this class,
to check that the implementation is valid.

=cut

=head1 FUNCTIONS

=cut

=head2 test_awaitable

   test_awaitable( $title, %args )

Runs the API conformance tests. C<$title> is printed in the test description
output so should be some human-friendly string.

Takes the following named arguments:

=over 4

=item class => STRING

Gives the name of the class. This is the class on which the C<AWAIT_NEW_DONE>
and C<AWAIT_NEW_FAIL> methods will be invoked.

=item new => CODE

Optional. Gives a callback function to invoke to construct a new pending
instance; used by the tests to create pending instances that would be passed
into the C<await> keyword. As this is not part of the API as such, the test
code does not rely on being able to directly perform it via the API.

This argument is optional; if not provided the tests will simply try to invoke
the regular C<new> constructor on the given class name. For most
implementations this should be sufficient.

   $f = $new->()

=item cancel => CODE

Optional. Gives a callback function to invoke to cancel a pending instance, if
the implementation provides cancellation semantics. If this callback is
provided then an extra subtest suite is run to check the API around
cancellation.

   $cancel->( $f )

=item force => CODE

Optional. Gives a callback function to invoke to wait for a promise to invoke
its on-ready callbacks. Some future-like implementations will run these
immediately when the future is marked as done or failed, and so this callback
will not be required. Other implementations will defer these invocations,
perhaps until the next tick of an event loop or similar. In the latter case,
these implementations should provide a way for the test to wait for this to
happen.

   $force->( $f )

=back

=cut

sub test_awaitable
{
   my ( $title, %args ) = @_;

   my $class  = $args{class};
   my $new    = $args{new}   || sub { return $class->new() };
   my $cancel = $args{cancel};
   my $force  = $args{force};

   subtest "$title immediate done" => sub {
      ok( my $f = $class->AWAIT_NEW_DONE( "result" ), "AWAIT_NEW_DONE yields object" ); 

      ok(  $f->AWAIT_IS_READY,     'AWAIT_IS_READY true' );
      ok( !$f->AWAIT_IS_CANCELLED, 'AWAIT_IS_CANCELLED false' );

      is_deeply( [ $f->AWAIT_GET ], [ "result" ], 'AWAIT_GET in list context' );
      is( scalar $f->AWAIT_GET,     "result",     'AWAIT_GET in scalar context' );
      ok( defined eval { $f->AWAIT_GET; 1 },      'AWAIT_GET in void context' );
   };

   subtest "$title immediate fail" => sub {
      ok( my $f = $class->AWAIT_NEW_FAIL( "Oopsie\n" ), "AWAIT_NEW_FAIL yields object" );

      ok(  $f->AWAIT_IS_READY,     'AWAIT_IS_READY true' );
      ok( !$f->AWAIT_IS_CANCELLED, 'AWAIT_IS_CANCELLED false' );

      ok( !defined eval { $f->AWAIT_GET; 1 }, 'AWAIT_GET in void context' );
      is( $@, "Oopsie\n", 'AWAIT_GET throws exception' );
   };

   my $fproto = $new->() or BAIL_OUT( "new did not yield an instance" );

   subtest "$title deferred done" => sub {
      ok( my $f = $fproto->AWAIT_CLONE, 'AWAIT_CLONE yields object' );

      ok( !$f->AWAIT_IS_READY, 'AWAIT_IS_READY false' );

      $f->AWAIT_DONE( "Late result" );

      ok( $f->AWAIT_IS_READY, 'AWAIT_IS_READY true' );

      is( scalar $f->AWAIT_GET, "Late result", 'AWAIT_GET in scalar context' );
   };

   subtest "$title deferred fail" => sub {
      ok( my $f = $fproto->AWAIT_CLONE, 'AWAIT_CLONE yields object' );

      ok( !$f->AWAIT_IS_READY, 'AWAIT_IS_READY false' );

      $f->AWAIT_FAIL( "Late oopsie\n" );

      ok( $f->AWAIT_IS_READY, 'AWAIT_IS_READY true' );

      ok( !defined eval { $f->AWAIT_GET; 1 }, 'AWAIT_GET in void context' );
      is( $@, "Late oopsie\n", 'AWAIT_GET throws exception' );
   };

   subtest "$title on-ready" => sub {
      my $f = $new->() or BAIL_OUT( "new did not yield an instance" );

      my $called;
      $f->AWAIT_ON_READY( sub { $called++ } );
      ok( !$called, 'AWAIT_ON_READY CB not yet invoked' );

      $f->AWAIT_DONE( "ping" );
      $force->( $f ) if $force;
      ok( $called, 'AWAIT_ON_READY CB now invoked' );
   };

   $cancel and subtest "$title cancellation" => sub {
      my $f1 = $new->() or BAIL_OUT( "new did not yield an instance" );

      my $f2 = $f1->AWAIT_CLONE;

      $f1->AWAIT_ON_CANCEL( $f2 );

      ok( !$f2->AWAIT_IS_CANCELLED, 'AWAIT_IS_CANCELLED false before cancellation' );

      $cancel->( $f1 );

      ok(  $f2->AWAIT_IS_CANCELLED, 'AWAIT_IS_CANCELLED true after AWAIT_ON_CANCEL propagation' );

      $f1->can( "AWAIT_CHAIN_CANCEL" ) or
         diag "TODO: Class does not implement AWAIT_CHAIN_CANCEL";
   };
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
