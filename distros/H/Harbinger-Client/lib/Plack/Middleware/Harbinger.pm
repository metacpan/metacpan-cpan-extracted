package Plack::Middleware::Harbinger;
$Plack::Middleware::Harbinger::VERSION = '0.001002';
use Moo;
use warnings NONFATAL => 'all';

extends 'Plack::Middleware';
use Harbinger::Client;
use namespace::clean;
use IO::Socket::INET;

has _harbinger_client => (
   is => 'ro',
   lazy => 1,
   builder => sub {
      my $self = shift;

      Harbinger::Client->new(
         harbinger_ip => $self->_harbinger_ip,
         harbinger_port => $self->_harbinger_port,
         default_args => $self->_default_args,
      )
   },
);

has _harbinger_ip => (
   is => 'ro',
   default => '127.0.0.1',
   init_arg => 'harbinger_ip',
);

has _harbinger_port => (
   is => 'ro',
   default => '8001',
   init_arg => 'harbinger_port',
);

has _default_args => (
   is => 'ro',
   default => sub { [] },
   init_arg => 'default_args',
);

has _udp_handle => (
   is => 'ro',
   builder => sub {
      IO::Socket::INET->new(
         PeerAddr => $_[0]->_harbinger_ip,
         PeerPort => $_[0]->_harbinger_port,
         Proto => 'udp'
      ) or die "couldn't connect to socket: $@" # might make this not so lethal
   },
);

sub call {
   my ($self, $env) = @_;

   my $doom = $self->_harbinger_client->start;
   # this needs to somehow pass through / wrap the other logger too
   $env->{'harbinger.querylog'} = $doom->query_logger;
   my $res = $self->app->($env);

   $self->response_cb($res, sub {
      my $ident = $env->{'harbinger.ident'} || $env->{PATH_INFO};
      $ident = "/$ident" unless $ident =~ m(^/);
      $doom->finish(
         server => $env->{'harbinger.server'},
         ident  => $ident,
         port   => $env->{'harbinger.port'} || $env->{SERVER_PORT},
         count  => $env->{'harbinger.count'},
      );

      $self->_harbinger_client->send($doom)
   })
}

1;
