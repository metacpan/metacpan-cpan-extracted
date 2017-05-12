package Message::Passing::STOMP::Role::HasAConnection;
use Moose::Role;
use namespace::autoclean;

with qw/
    Message::Passing::Role::HasAConnection
    Message::Passing::Role::HasHostnameAndPort
/;

sub _default_port { 6163 }

has ssl => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

has [qw/ username password /] => (
    is => 'ro',
    isa => 'Str',
    default => 'guest',
);

sub _connection_manager_class { 'Message::Passing::STOMP::ConnectionManager' }
sub _connection_manager_attributes { [qw/ username password ssl hostname port /] }

1;

=head1 NAME

Message::Passing::STOMP::HasAConnection - Role for instances which have a connection to a STOMP server.

=head1 ATTRIBUTES


=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing::STOMP>.

=cut

