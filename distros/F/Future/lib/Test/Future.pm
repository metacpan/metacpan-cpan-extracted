#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2015 -- leonerd@leonerd.org.uk

package Test::Future;

use strict;
use warnings;
use base qw( Test::Builder::Module );

our $VERSION = '0.45';

our @EXPORT = qw(
   no_pending_futures
);

use Scalar::Util qw( refaddr );

use constant HAVE_DEVEL_MAT_DUMPER => defined eval { require Devel::MAT::Dumper };

=head1 NAME

C<Test::Future> - unit test assertions for L<Future> instances

=head1 SYNOPSIS

 use Test::More tests => 2;
 use Test::Future;

 no_pending_futures {
    my $f = some_function();

    is( $f->get, "result", 'Result of the some_function()' );
 } 'some_function() leaves no pending Futures';

=head1 DESCRIPTION

This module provides unit testing assertions that may be useful when testing
code based on, or using L<Future> instances or subclasses.

=cut

=head1 FUNCTIONS

=cut

=head2 no_pending_futures

   no_pending_futures( \&code, $name )

I<Since version 0.29.>

Runs the given block of code, while keeping track of every C<Future> instance
constructed while doing so. After the code has returned, each of these
instances are inspected to check that they are not still pending. If they are
all either ready (by success or failure) or cancelled, the test will pass. If
any are still pending then the test fails.

If L<Devel::MAT> is installed, it will be used to write a memory state dump
after a failure. It will create a F<.pmat> file named the same as the unit
test, but with the trailing F<.t> suffix replaced with F<-TEST.pmat> where
C<TEST> is the number of the test that failed (in case there was more than
one). A list of addresses of C<Future> instances that are still pending is
also printed to assist in debugging the issue.

It is not an error if the code does not construct any C<Future> instances at
all. The block of code may contain other testing assertions; they will be run
before the assertion by C<no_pending_futures> itself.

=cut

sub no_pending_futures(&@)
{
   my ( $code, $name ) = @_;

   my @futures;

   no warnings 'redefine';

   my $new = Future->can( "new" );
   local *Future::new = sub {
      my $f = $new->(@_);
      push @futures, $f;
      $f->on_ready( sub {
         my $f = shift;
         for ( 0 .. $#futures ) {
            refaddr( $futures[$_] ) == refaddr( $f ) or next;

            splice @futures, $_, 1, ();
            return;
         }
      });
      return $f;
   };

   my $done = Future->can( "done" );
   local *Future::done = sub {
      my $f = $done->(@_);
      pop @futures if !ref $_[0]; # class method
      return $f;
   };

   my $fail = Future->can( "fail" );
   local *Future::fail = sub {
      my $f = $fail->(@_);
      pop @futures if !ref $_[0]; # class method
      return $f;
   };

   my $tb = __PACKAGE__->builder;

   $code->();

   my @pending = grep { !$_->is_ready } @futures;

   return $tb->ok( 1, $name ) if !@pending;

   my $ok = $tb->ok( 0, $name );

   $tb->diag( "The following Futures are still pending:" );
   $tb->diag( join ", ", map { sprintf "0x%x", refaddr $_ } @pending );

   if( HAVE_DEVEL_MAT_DUMPER ) {
      my $file = $0;
      my $num = $tb->current_test;

      # Trim the .t off first then append -$num.pmat, in case $0 wasn't a .t file
      $file =~ s/\.(?:t|pm|pl)$//;
      $file .= "-$num.pmat";

      $tb->diag( "Writing heap dump to $file" );
      Devel::MAT::Dumper::dump( $file );
   }

   return $ok;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
