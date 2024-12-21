#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2024 -- leonerd@leonerd.org.uk

package Test::Future::AsyncAwait::Awaitable 0.70;

use v5.14;
use warnings;

use Test2::V0;

use Exporter 'import';
our @EXPORT_OK = qw(
   test_awaitable
);

=head1 NAME

C<Test::Future::AsyncAwait::Awaitable> - conformance tests for awaitable role API

=head1 SYNOPSIS

=for highlighter language=perl

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

   test_awaitable( $title, %args );

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

   $f = $new->();

=item cancel => CODE

Optional. Gives a callback function to invoke to cancel a pending instance, if
the implementation provides cancellation semantics. If this callback is
provided then an extra subtest suite is run to check the API around
cancellation.

   $cancel->( $f );

=item force => CODE

Optional. Gives a callback function to invoke to wait for a promise to invoke
its on-ready callbacks. Some future-like implementations will run these
immediately when the future is marked as done or failed, and so this callback
will not be required. Other implementations will defer these invocations,
perhaps until the next tick of an event loop or similar. In the latter case,
these implementations should provide a way for the test to wait for this to
happen.

   $force->( $f );

=back

=cut

my $FILE = __FILE__;

my %FIXED_MODULE_VERSIONS = (
   'Future::PP' => '0.50',
   'Future::XS' => '0.09',
);

sub _complain_package_version
{
   my ( $pkg ) = @_;

   # Drill down to the most base class that isn't Future::_base
   {
      no strict 'refs';
      $pkg = ${"${pkg}::ISA"}[0] while @{"${pkg}::ISA"} and ${"${pkg}::ISA"}[0] ne "Future::_base";
   }

   my $pkgver = do { no strict 'refs'; ${"${pkg}::VERSION"} };
   my $wantver = $FIXED_MODULE_VERSIONS{$pkg};

   if( defined $wantver && $pkgver < $wantver ) {
      diag( "$pkg VERSION is only $pkgver; this might be fixed by updating to version $wantver" );
   }
   else {
      diag( "$pkg VERSION is $pkgver; maybe a later version fixes it?" );
   }
}

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

      is( [ $f->AWAIT_GET ], [ "result" ],    'AWAIT_GET in list context' );
      is( scalar $f->AWAIT_GET,     "result", 'AWAIT_GET in scalar context' );
      ok( defined eval { $f->AWAIT_GET; 1 },  'AWAIT_GET in void context' );
   };

   subtest "$title immediate fail" => sub {
      ok( my $f = $class->AWAIT_NEW_FAIL( "Oopsie" ), "AWAIT_NEW_FAIL yields object" );

      ok(  $f->AWAIT_IS_READY,     'AWAIT_IS_READY true' );
      ok( !$f->AWAIT_IS_CANCELLED, 'AWAIT_IS_CANCELLED false' );

      my $LINE = __LINE__+1;
      ok( !defined eval { $f->AWAIT_GET; 1 }, 'AWAIT_GET in void context' );
      is( $@, "Oopsie at $FILE line $LINE.\n", 'AWAIT_GET throws exception' ) or
         _complain_package_version( ref $f );
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

      $f->AWAIT_FAIL( "Late oopsie" );

      ok( $f->AWAIT_IS_READY, 'AWAIT_IS_READY true' );

      my $LINE = __LINE__+1;
      ok( !defined eval { $f->AWAIT_GET; 1 }, 'AWAIT_GET in void context' );
      is( $@, "Late oopsie at $FILE line $LINE.\n", 'AWAIT_GET throws exception' ) or
         _complain_package_version( ref $f );
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

      $f1->AWAIT_CHAIN_CANCEL( $f2 );

      ok( !$f2->AWAIT_IS_CANCELLED, 'AWAIT_IS_CANCELLED false before cancellation' );

      $cancel->( $f1 );

      ok(  $f2->AWAIT_IS_CANCELLED, 'AWAIT_IS_CANCELLED true after AWAIT_ON_CANCEL propagation' );

      my $f3 = $new->() or BAIL_OUT( "new did not yield an instance" );

      my $cancelled;
      $f3->AWAIT_ON_CANCEL( sub { $cancelled++ } );

      $cancel->( $f3 );

      ok( $cancelled, 'AWAIT_ON_CANCEL invoked callback' );
   };
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
