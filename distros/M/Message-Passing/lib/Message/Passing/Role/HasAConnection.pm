package Message::Passing::Role::HasAConnection;
use Moo::Role;
use Module::Runtime qw/ require_module /;
use Carp qw/ confess /;
use namespace::clean -except => 'meta';

with qw/
    Message::Passing::Role::HasTimeoutAndReconnectAfter
    Message::Passing::Role::HasErrorChain
/;

# requires qw/ _connection_manager_attributes _connection_manager_class /;
requires 'connected';

has connection_manager => (
    is => 'ro',
    lazy => 1,
#    isa => duck_type([qw/subscribe_to_connect/]),
    builder => '_build_connection_manager',
);

sub _build_connection_manager {
    my $self = shift;
    confess "Cannot auto-build this connection manager"
        unless $self->can('_connection_manager_attributes')
            && $self->can('_connection_manager_class');
    my %attrs = map { $_ => $self->$_ } (@{ $self->_connection_manager_attributes }, qw/timeout reconnect_after error/);
    my $class = $self->_connection_manager_class;
    require_module($class);
    $class->new(%attrs);
}

sub BUILD {}
after BUILD => sub {
    my $self = shift;
    $self->connection_manager->subscribe_to_connect($self);
};

1;

=head1 NAME

Message::Passing::Role::HasAConnection - Role for components which have a connection

=head1 DESCRIPTION

Provides a standard ->connection_manager attribute for inputs or outputs which need to
make a network connection before they can send or receive messages.

The connection manager object is assumed to have the C<< ->subscribe_to_connect >> method
(from L<Message::Passing::Role::Connection>).

=head1 REQUIRED METHODS

=head2 _build_connection_manager

Will be called at BUILD (i.e. object construction) time, should return
a connection manager object (i.e. an object that C<< ->subscribe_to_connect >>
can be called on).

=head2 connected ($client)

Called by the connection manager when a connection is made.

Usually used to do things like subscribe to queues..

=head1 OPTIONAL METHODS

=head2 disconnected ($client)

The client received an error or otherwise disconnected.

=head1 ATTRIBUTES

=head2 connection_manager

Holds the connection manger returned by the C<_build_connection_manager> method.

=head1 WRAPPED METHODS

=head2 BUILD

Is wrapped to build the connection manager object.

=head1 SEE ALSO

=over

=item L<Message::Passing::Role::ConenctionManager>.

=back

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API - 
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut