package Message::Passing::Output::Redis;
use Moo;
use MooX::Types::MooseLike::Base qw/ Str /;
use namespace::clean -except => 'meta';

with qw/
    Message::Passing::Redis::Role::HasAConnection
    Message::Passing::Role::Output
/;

has topic => (
    isa => Str,
    is => 'ro',
    required => 1,
);

sub consume {
    my $self = shift;
    my $data = shift;
    my $headers = undef;
    $self->connection_manager->connection->publish($self->topic, $data);
}

sub connected {}

1;

=head1 NAME

Message::Passing::Output::Redis - A Redis publisher for Message::Passing

=head1 SYNOPSIS

    $ message-pass --input STDIN --output Redis --output_options '{"topic":"foo","hostname":"127.0.0.1","port":"6379"}'

=head1 DESCRIPTION

A simple message output which publishes messages to a Redis PubSub topic.

=head1 ATTRIBUTES

=head2 hostname

The hostname of the Redis server. Required.

=head2 port

The port number of the Redis server. Defaults to 6379.

=head2 topic

The topic to publish messages to.

=head1 METHODS

=head2 consume

Publishes a message to Redis if connected.

=head2 connected

Called by L<Message::Passing::Redis::ConnectionManager> when connected.
Does nothing in this class.

=head1 SEE ALSO

=over

=item L<Message::Passing::Input::Redis>

=item L<Message::Passing::Redis>

=back

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing::Redis>.

=cut

