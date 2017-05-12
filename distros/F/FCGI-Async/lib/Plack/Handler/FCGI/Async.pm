#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010 -- leonerd@leonerd.org.uk

package Plack::Handler::FCGI::Async;

use strict;
use warnings;

use FCGI::Async::PSGI;
use IO::Async::Loop;

our $VERSION = '0.22';

=head1 NAME

C<Plack::Handler::FCGI::Async> - FastCGI handler for Plack using L<FCGI::Async>

=head1 DESCRIPTION

This module allows L<Plack> to run a L<PSGI> application as a standalone
FastCGI daemon under L<IO::Async>, by using L<FCGI::Async>.

 plackup -s FCGI::Async --listen ":2000" application.psgi

This is internally implemented using L<FCGI::Async::PSGI>; further information
on environment etc.. is documented there.

=cut

sub new
{
   my $class = shift;
   my %opts = @_;

   delete $opts{host};
   delete $opts{port};

   my $self = bless {
      map { $_ => delete $opts{$_} } qw( listen server_ready socket ),
   }, $class;

   keys %opts and die "Unrecognised keys " . join( ", ", sort keys %opts );

   return $self;
}

sub run
{
   my $self = shift;
   my ( $app ) = @_;

   my $loop = IO::Async::Loop->new;

   foreach my $listen ( @{ $self->{listen} } ) {
      my $fcgi = FCGI::Async::PSGI->new(
         app => $app,
      );

      $loop->add( $fcgi );

      if( $self->{socket} ) {
         my $path = $self->{socket};

         require IO::Socket::UNIX;

         unlink $path if -e $path;

         my $socket = IO::Socket::UNIX->new(
            Local  => $path,
            Listen => 10,
         ) or die "Cannot listen on $path - $!";

         $fcgi->configure( handle => $socket );
      }
      else {
         my ( $host, $service ) = $listen =~ m/^(.*):(.*?)$/;

         $fcgi->listen(
            host    => $host,
            service => $service,

            on_notifier => sub { $self->{server_ready} and $self->{server_ready}->() },

            on_resolve_error => sub {
               die "Cannot resolve - $_[-1]\n";
            },
            on_listen_error => sub {
               die "Cannot listen - $_[-1]\n";
            },
         );
      }

   }

   $loop->loop_forever;
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 SEE ALSO

=over 4

=item *

L<FCGI::Async> - use FastCGI with L<IO::Async>

=item *

L<Plack> - Perl Superglue for Web frameworks and Web Servers (PSGI toolkit)

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>
