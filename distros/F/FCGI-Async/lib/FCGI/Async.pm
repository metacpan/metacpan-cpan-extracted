#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011 -- leonerd@leonerd.org.uk

package FCGI::Async;

use strict;
use warnings;

use base qw( Net::Async::FastCGI );

our $VERSION = '0.22';

use Carp;

# Back compat
*MAX_CONNS = \$Net::Async::FastCGI::MAX_CONNS;
*MAX_REQS  = \$Net::Async::FastCGI::MAX_REQS;

=head1 NAME

C<FCGI::Async> - use FastCGI with L<IO::Async>

=head1 SYNOPSIS

 use FCGI::Async;
 use IO::Async::Loop;

 my $loop = IO::Async::Loop->new();

 my $fcgi = FCGI::Async->new(
    loop => $loop
    service => 1234,

    on_request => sub {
       my ( $fcgi, $req ) = @_;

       # Handle the request here
    }
 );

 $loop->loop_forever;

=head1 DESCRIPTION

This subclass of L<Net::Async::FastCGI> provides a slightly different API;
where it can take an argument containing the L<IO::Async::Loop> object, rather
than be added as C<Notifier> object within one. It is provided mostly as a
backward-compatibility wrapper for older code using this interface; newer
code ought to use the C<Net::Async::FastCGI> interface directly.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $fcgi = FCGI::Async->new( %args )

Returns a new instance of a C<FCGI::Async> object.

If either a C<handle> or C<service> argument are passed to the constructor,
then the newly-created object is added to the given C<IO::Async::Loop>, then
the C<listen> method is invoked, passing the entire C<%args> hash to it.

If either of the above arguments are given, then a C<IO::Async::Loop> must
also be provided:

=over 4

=item loop => IO::Async::Loop

A reference to the C<IO::Async::Loop> which will contain the listening
sockets.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $loop = delete $args{loop};

   my $self = $class->SUPER::new( %args );

   if( defined $args{handle} ) {
      $loop or croak "Require a 'loop' argument";

      $loop->add( $self );

      my $handle = delete $args{handle};

      # IO::Async version 0.27 requires this to support ->sockname method
      bless $handle, "IO::Socket" if ref($handle) eq "GLOB" and defined getsockname($handle);

      $self->configure( handle => $handle );
   }
   elsif( defined $args{service} ) {
      $loop or croak "Require a 'loop' argument";

      $loop->add( $self );

      $self->listen(
         %args,

         # listen wants some error handling callbacks. Since this is a
         # constructor it's reasonable to provide default 'croak' ones if
         # they're not supplied
         on_resolve_error => sub { croak "Resolve error $_[0] while constructing a " . __PACKAGE__ },
         on_listen_error  => sub { croak "Cannot listen while constructing a " . __PACKAGE__ },
      );
   }

   return $self;
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>
