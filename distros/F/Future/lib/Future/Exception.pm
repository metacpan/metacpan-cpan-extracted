#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019 -- leonerd@leonerd.org.uk

package Future::Exception;

use strict;
use warnings;

our $VERSION = '0.45';

=head1 NAME

C<Future::Exception> - an exception type for failed L<Future>s

=head1 SYNOPSIS

   use Scalar::Util qw( blessed );
   use Syntax::Keyword::Try;

   try {
      my $f = ...;
      my @result = $f->result;
      ...
   }
   catch {
      if( blessed($@) and $@->isa( "Future::Exception" ) {
         print STDERR "The ", $@->category, " failed: ", $@->message, "\n";
      }
   }

=head1 DESCRIPTION

The C<get> method on a failed L<Future> instance will throw an exception to
indicate that the future failed. A failed future can contain a failure
category name and other details as well as the failure message, so in this
case the exception will be an instance of C<Future::Exception> to make these
values accessible.

Users should not depend on exact class name matches, but instead rely on
inheritence, as a later version of this implementation might dynamically
create subclasses whose names are derived from the Future failure category
string, to assist with type matching. Note the use of C<< ->isa >> in the
SYNOPSIS example.

=cut

use overload
   '""'     => "message",
   fallback => 1;

=head1 CONSTRUCTOR

=head2 from_future

   $e = Future::Exception->from_future( $f )

Constructs a new C<Future::Exception> wrapping the given failed future.

=cut

sub from_future
{
   my $class = shift;
   my ( $f ) = @_;
   return $class->new( $f->failure );
}

sub new { my $class = shift; bless [ @_ ], $class; }

=head1 ACCESSORS

   $message  = $e->message
   $category = $e->category
   @details  = $e->details

Additionally, the object will stringify to return the message value, for the
common use-case of printing, regexp testing, or other behaviours.

=cut

sub message  { shift->[0] }
sub category { shift->[1] }
sub details  { my $self = shift; @{$self}[2..$#$self] }

=head1 METHODS

=cut

=head2 throw

   Future::Exception->throw( $message, $category, @details )

I<Since version 0.41.>

Constructs a new exception object and throws it using C<die()>. This method
will not return, as it raises the exception directly.

If C<$message> does not end in a linefeed then the calling file and line
number are appended to it, in the same way C<die()> does.

=cut

sub throw
{
   my $class = shift;
   my ( $message, $category, @details ) = @_;
   $message =~ m/\n$/ or
      $message .= sprintf " at %s line %d.\n", ( caller )[1,2];
   die $class->new( $message, $category, @details );
}

# TODO: consider a 'croak' method that uses Carp::shortmess to find a suitable
# file/linenumber

=head2 as_future

   $f = $e->as_future

Returns a new C<Future> object in a failed state matching the exception.

=cut

sub as_future
{
   my $self = shift;
   return Future->fail( $self->message, $self->category, $self->details );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
