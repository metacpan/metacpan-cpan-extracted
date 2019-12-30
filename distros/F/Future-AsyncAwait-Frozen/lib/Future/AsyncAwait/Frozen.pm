#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2019 -- leonerd@leonerd.org.uk

package Future::AsyncAwait::Frozen;

use strict;
use warnings;

our $VERSION = '0.36';

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

require Future;

=head1 NAME

C<Future::AsyncAwait::Frozen> - deferred subroutine syntax for futures

=head1 SYNOPSIS

   use Future::AsyncAwait::Frozen;

   async sub do_a_thing
   {
      my $first = await do_first_thing();

      my $second = await do_second_thing();

      return combine_things( $first, $second );
   }

   do_a_thing()->get;

=head1 DESCRIPTION

This module is merely a frozen release of L<Future::AsyncAwait> to test
experimental async/await support in L<Mojolicious>. Just the namespace has been
changed. All code belongs to the original authors.

=cut

sub import
{
   my $class = shift;
   my $caller = caller;

   $class->import_into( $caller, @_ );
}

sub import_into
{
   my $class = shift;
   my $caller = shift;

   $^H{"Future::AsyncAwait::Frozen/async"}++; # Just always turn this on

   while( @_ ) {
      my $sym = shift;

      $^H{"Future::AsyncAwait::Frozen/future"} = shift, next if $sym eq "future_class";

      croak "Unrecognised import symbol $sym";
   }
}

if( !defined &Future::AWAIT_CLONE ) {
   # TODO: These ought to be implemented by Future.pm itself, and it can do
   # these in a faster, more performant way
   *Future::AWAIT_CLONE    = sub { shift->new };
   *Future::AWAIT_NEW_DONE = *Future::AWAIT_DONE = sub { shift->done( @_ ) };
   *Future::AWAIT_NEW_FAIL = *Future::AWAIT_FAIL = sub { shift->fail( @_ ) };

   *Future::AWAIT_IS_READY     = sub { shift->is_ready };
   *Future::AWAIT_IS_CANCELLED = sub { shift->is_cancelled };

   *Future::AWAIT_ON_READY  = sub { shift->on_ready( @_ ) };
   *Future::AWAIT_ON_CANCEL = sub { shift->on_cancel( @_ ) };

   *Future::AWAIT_GET = sub { shift->get };
}

=head1 ACKNOWLEDGEMENTS

With thanks to C<Zefram>, C<ilmari> and others from C<irc.perl.org/#p5p> for
assisting with trickier bits of XS logic.

Thanks to C<genio> for project management and actually reminding me to write
some code.

Thanks to The Perl Foundation for sponsoring me to continue working on the
implementation.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
