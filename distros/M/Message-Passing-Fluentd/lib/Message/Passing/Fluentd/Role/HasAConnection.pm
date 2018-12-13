package Message::Passing::Fluentd::Role::HasAConnection;

use Moo::Role;
use namespace::autoclean;
use Message::Passing::Fluentd::ConnectionManager;

with qw(
  Message::Passing::Role::HasAConnection
  Message::Passing::Role::HasHostnameAndPort
);

sub _default_port { shift->connection_manager->_default_port }

sub _build_connection_manager {
  my $self = shift;
  Message::Passing::Fluentd::ConnectionManager->new(
    map { $_ => $self->$_ } qw(hostname port)
  );
}

1;
