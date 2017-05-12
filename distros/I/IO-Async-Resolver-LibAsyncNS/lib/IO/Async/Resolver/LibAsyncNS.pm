#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package IO::Async::Resolver::LibAsyncNS;

use strict;
use warnings;
use base qw( IO::Async::Resolver );

our $VERSION = '0.01';

use Carp;

use Future;
use IO::Async::Handle;

use Net::LibAsyncNS;

=head1 NAME

C<IO::Async::Resolver::LibAsyncNS> - use F<libasyncns> for C<IO::Async> resolver queries

=head1 SYNOPSIS

 use IO::Async::Loop;
 use IO::Async::Resolver::LibAsyncNS;

 my $loop = IO::Async::Loop->new;

 my $resolver = IO::Async::Resolver::LibAsyncNS->new;
 $loop->add( $resolver );

 $resolver->getaddrinfo(
    host => "metacpan.org",
    service => "http",
    socktype => "stream",
 )->on_done( sub {
    my @res = @_;
    print "metacpan.org available at\n";
    printf "  family=%d addr=%v02x\n", $_->{family}, $_->{addr} for @res;
 })->get;

=head1 DESCRIPTION

This subclass of L<IO::Async::Resolver> applies special handling to the
C<getaddrinfo_hash> and C<getnameinfo> resolvers to use a L<Net::LibAsyncNS>
instance, rather than using the usual L<IO::Async::Function> wrapper around
the system resolver functions. This may lead to higher performance in some
applications.

It provides no additional methods, configuration options or events besides
those supported by C<IO::Async::Resolver> itself. It exists purely to
implement the same behaviours in a more efficient manner.

=cut

sub new
{
   my $class = shift;
   my $self = $class->SUPER::new( @_ );

   my $asyncns = Net::LibAsyncNS->new( 4 ); # TODO: configurable
   $self->{asyncns} = $asyncns;

   $self->add_child( IO::Async::Handle->new(
      read_handle => $asyncns->new_handle_for_fd,
      on_read_ready => $self->_replace_weakself( '_on_asyncns_read_ready' ),
   ) );

   return $self;
}

sub _on_asyncns_read_ready
{
   my $self = shift;

   my $asyncns = $self->{asyncns};

   $asyncns->wait( 0 ); # perform some IO but don't block

   while( my $q = $asyncns->getnext ) {
      my $code = delete $self->{on_query_ready}{"$q"} or next;

      $code->( $self, $q );
   }
}

sub resolve
{
   my $self = shift;
   my %args = @_;

   my $type = delete $args{type} or croak "Expected 'type'";

   my $f;
   if( $type eq "getaddrinfo_hash" ) {
      $f = $self->_getaddrinfo_via_asyncns( @{ $args{data} } );
   }
   elsif( $type eq "getnameinfo" ) {
      $f = $self->_getnameinfo_via_asyncns( @{ $args{data} } );
   }
   else {
      return $self->SUPER::resolve( @_ );
   }

   $f = Future->wait_any(
      $f,
      $self->loop->timeout_future( after => $args{timeout} )
   ) if defined $args{timeout};

   return $f;
}

sub _getaddrinfo_via_asyncns
{
   my $self = shift;
   my %args = @_;

   my %hints;
   defined $args{$_} and $hints{$_} = $args{$_} for qw( flags family socktype protocol );

   my $asyncns = $self->{asyncns};

   my $q = $asyncns->getaddrinfo( $args{host}, $args{service}, \%hints );

   my $f = $self->loop->new_future;
   $f->on_cancel( sub { $asyncns->cancel( $q ) } );

   $self->{on_query_ready}{"$q"} = sub {
      my ( $self, $q ) = @_;

      my ( $err, @res ) = $self->{asyncns}->getaddrinfo_done( $q );

      if( $err ) {
         $f->fail( "$err\n", resolve => getaddrinfo => );
      }
      else {
         $f->done( @res );
      }
   };

   return $f;
}

sub _getnameinfo_via_asyncns
{
   my $self = shift;
   my ( $addr, $flags ) = @_;

   my $asyncns = $self->{asyncns};

   my $q = $asyncns->getnameinfo( $addr, $flags, 1, 1 );

   my $f = $self->loop->new_future;
   $f->on_cancel( sub { $asyncns->cancel( $q ) } );

   $self->{on_query_ready}{"$q"} = sub {
      my ( $self, $q ) = @_;

      my ( $err, $host, $service ) = $self->{asyncns}->getnameinfo_done( $q );

      if( $err ) {
         $f->fail( "$err\n", resolve => getnameinfo => );
      }
      else {
         $f->done( [ $host, $service ] );
      }
   };

   return $f;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
