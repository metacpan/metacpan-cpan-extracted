=head1 NAME

Event::IO::Server - general listener class, spawns client connections

=head1 METHODS

=cut
package Event::IO::Server;

use strict;
our $VERSION = '0.01';

use Event;


=head2 new ( named parameters... )

=over 4

=item spawn

Class for new connection objects, should inherit from Event::IO::Linear.

=item handle

IO::Socket handle for listener (should be ::INET or ::UNIX; it's a good idea
to set ReuseAddr for INET clients).

=item data

Optional parameter, passed to child init_event.

=back

=cut
sub new {
  my ($class,%param) = @_;

  # check parameters
  my ($spawn,$handle,$data) = delete @param{qw(spawn handle data)};
  die 'unknown parameter(s): '.(join ', ',keys %param) if keys %param;

  # create object
  my $self = bless { spawn => $spawn, data => $data, handle => $handle },
   ref $class || $class;

  # this is a listening socket
  $self->{handle}->listen();

  # we'd like to know when we get clients
  Event->io(fd => $self->{handle}, poll => 'r', cb => [$self,'client_event']);

  return $self;
}


=head2 data

Get/set data parameter to pass to init_event (can also set in new).

=cut
sub data {
  my $self = shift;
  $self->{data} = shift if @_;
  return $self->{data};
}


=head2 client_event

Called when we get a new client (select 'read' event).

=cut
sub client_event {
  my $self = shift;
  my $sock = $self->{handle}->accept();
  my $client = $self->{spawn}->new(handle => $sock, init => 0);
  $client->init_event($self->{data}) if $client->can('init_event');
}


=head1 AUTHOR

David B. Robins E<lt>dbrobins@davidrobins.netE<gt>

=cut


1;
