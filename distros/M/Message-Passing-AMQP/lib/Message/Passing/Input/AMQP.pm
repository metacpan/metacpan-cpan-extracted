package Message::Passing::Input::AMQP;
use Moose;
use AnyEvent;
use Scalar::Util qw/ weaken refaddr /;
use Try::Tiny;
use namespace::autoclean;

with qw/
    Message::Passing::AMQP::Role::BindsAQueue
    Message::Passing::Role::Input
/;


after '_set_queue' => sub {
    my $self = shift;
    weaken($self);
    $self->_channel->consume(
        on_consume => sub {
            my $message = shift;
            try {
                $self->output_to->consume($message->{body}->payload);
            }
            catch {
                warn("Error in consume_message callback: $_");
            };
        },
        consumer_tag => refaddr($self),
        on_success => sub {
        },
        on_failure => sub {
            Carp::cluck("Failed to start message consumer in $self response " . Dumper(@_));
        },
    );
};

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Message::Passing::Input::AMQP - input logstash messages from AMQP.

=head1 SYNOPSIS

    message-pass --output STDOUT --input AMQP --input_options '{"queue_name":"test","exchange_name":"test","hostname":"127.0.0.1","username":"guest","password":"guest"}'

=head1 DESCRIPTION

=head1 SEE ALSO

=over

=item L<Message::Passing::AMQP>

=item L<Message::Passing::Output::AMQP>

=item L<Message::Passing>

=item L<AMQP>

=item L<http://www.zeromq.org/>

=back

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing::AMQP>.

=cut

