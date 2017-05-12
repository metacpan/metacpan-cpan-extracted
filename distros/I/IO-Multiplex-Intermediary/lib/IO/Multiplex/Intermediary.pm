#!/usr/bin/env perl
package IO::Multiplex::Intermediary;

our $VERSION = "0.06";

use MooseX::POE;

use JSON;
use List::MoreUtils qw(any);
use Scalar::Util qw(reftype);

use POE qw(
    Wheel::SocketFactory
    Component::Server::TCP
    Wheel::ReadWrite
    Filter::Stream
);

has filehandles => (
    is  => 'rw',
    isa => 'POE::Wheel::SocketFactory',
);

has rw_set => (
    is => 'rw',
    isa => 'HashRef[Int]',
    default => sub { +{} },
);

has external_port => (
    is  => 'ro',
    isa => 'Int',
    default => 6715
);

has client_socket => (
    is      => 'rw',
    isa     => 'POE::Wheel::ReadWrite',
);

has client_port => (
    is  => 'ro',
    isa => 'Int',
    default => 9000
);

has socket_info => (
    is  => 'rw',
    isa => 'HashRef[Int]',
    default => sub { +{} },
);

sub _client_start {
    my ($self) = @_;
    $self->filehandles(
        POE::Wheel::SocketFactory->new(
            BindPort     => $self->external_port,
            SuccessEvent => 'connect',
            FailureEvent => 'error',
            Reuse        => 'yes',
        )
    ) or die $!;

    POE::Component::Server::TCP->new(
        Port               => $self->client_port,
        ClientConnected    => sub { $self->client_connect(@_) },
        ClientDisconnected => sub { $self->client_disconnect(@_)  },
        ClientInput        => sub { $self->client_input(@_)  },
    );
}

#TODO send backup info
sub client_connect {
    my $self = shift;

    $self->client_socket($_[HEAP]->{client});

    if ( scalar(%{$self->rw_set}) ) {
        foreach my $id (keys %{ $self->rw_set }) {
            $self->send_to_client(
                {
                    param => 'connect',
                    data  => {
                        id    => $id,
                    }
                }
            );
        }
    }
}

sub _connect {
    my ($self) = @_;
    my $socket = $_[ARG0];
    my $rw = POE::Wheel::ReadWrite->new(
        Handle     => $socket,
        Driver     => POE::Driver::SysRW->new,
        Filter     => POE::Filter::Stream->new,
        InputEvent => 'input',
        ErrorEvent => 'error',
    );

    my $wheel_id = $rw->ID;
    $self->rw_set->{$wheel_id} = $rw;

    $self->send_to_client(
        {
            param => 'connect',
            data  => {
                id => $wheel_id,
            }
        }
    );
}

sub _input {
    my ($self)             = @_;
    my ($input, $wheel_id) = @_[ARG0, ARG1];
    $input =~ s/[\r\n]*$//;


    $self->send_to_client(
        {
            param => 'input',
            data => {
                id    => $wheel_id,
                value => $input,
            }
        }
    );
}

sub _process_input {
    my $self = shift;
    my $input = shift;

    my $json = eval { from_json($input) };

    {
        if ($@ || !$json) {
            warn "JSON error: $@";
        }
        elsif (!exists $json->{param}) {
            warn "Invalid JSON structure!";
        }
        else {
            last unless $json->{data}->{id};
            last unless reftype($self->rw_set);
            last unless $self->rw_set->{ $json->{data}->{id} };

            if ($json->{param} eq 'output') {
                $self->rw_set->{ $json->{data}->{id} }->put( $json->{data}->{value} );
                if ($json->{updates}) {
                    foreach my $key  (%{ $json->{updates} }) {
                        my $value = $json->{updates}->{$key};
                        $self->socket_info->{ $json->{data}->{id} }->{ $key } = $value
                    }
                }
            }
            elsif ($json->{param} eq 'disconnect') {
                my $id = $json->{data}->{id};
                $self->rw_set->{$id}->shutdown_output;
            }
        }
    }

}

sub client_input {
    my $self = shift;
    my $input = $_[ARG0];
    my @packets = split m{\e}, $input;
    s/[\r\n]*$// for @packets;
    $self->_process_input($_) for grep { $_} @packets;
}

sub _disconnect {
    my ($self)   = @_;
    my $wheel_id = $_[ARG3];
    delete $self->rw_set->{$wheel_id};
    $self->send_to_client(
        {
            param => 'disconnect',
            data => {
                id => $wheel_id,
            }
        }
    );
}

sub _error {
    my ($self) = @_;
    my ($operation, $errnum, $errstr) = @_[ARG0, ARG1, ARG2];
    warn "[SERVER] $operation error $errnum: $errstr";
}

sub client_disconnect {
    my $self = shift;
    #$_->put("Hold tight!\nThe MUD will be back up shortly.\n") for values %{$self->rw_set||{}};
}


sub send {
    my $self = shift;
    my $id = shift;
    my $data = shift;

    $self->rw_set->{$id}->put(to_json($data));
}

sub send_to_client {
    my $self   = shift;
    my $data   = shift;

    return unless defined $self->client_socket;
    $self->client_socket->put(to_json($data));
}


sub run {
    my $self = shift;
    POE::Kernel->run();
}

event START => \&_client_start;

event connect     => \&_connect;
event error       => \&_error;
event input       => \&_input;
event disconnect  => \&_disconnect;

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

IO::Multiplex::Intermediary - multiplexing with fault tolerance

=head1 SYNOPSIS

    use IO::Multiplex::Intermediary;

    my $intermediary = IO::Multiplex::Intermediary->new;

    $intermediary->run;

=head1 DESCRIPTION

B<WARNING! THIS MODULE HAS BEEN DEEMED ALPHA BY THE AUTHOR. THE API
MAY CHANGE IN SUBSEQUENT VERSIONS.>

This library is for users who want to optimize user experience. It
keeps the external connection operations and application operations
separate as separate processes, so that if the application crashes.

The core is robust in its simplicity. The library is meant for your
application to extend the L<IO::Multiplex::Intermediary::Client>
module that ships with this distribution and use its hooks. If the
application crashes, the end users on the external side will not
be disconnected. When the controller reconnects, the users will be
welcomed back to the real interaction in any way that the developer
who extends this module sees fit.

The intermediary opens two ports: one for end users to connect to,
and one for the application to connect to. The intermediary server
and client use JSON to communicate with each other. Here is an example
of the life cycle of the intermediary and application:

            User land       |  Intermediary      |  Application
                            |                    |
            Connect         |                    |
                            |  Accept user       |
                            |  connection        |
                            |                    |
                            |  Send the          |
                            |  connection        |
                            |  action to         |
                            |   the app          |
                            |                    |  Receive
                            |                    |  connection
                            |                    |
                            |                    |  Track any
                            |                    |  user data
                            |                    |
            User sends      |                    |
            something       |                    |
                            | Read the message   |
                            |                    |
                            | Send the message   |
                            | to the app         |
                            |                    |  Read the message
                            |                    |
                            |                    |  Process the message
                            |                    |  (build_response)
                            |                    |
                            |                    |  Send the response
                            |  Get the response  |
                            |                    |
                            |  Send the response |
                            |  to the appropriate|
                            |  user              |
           Disconnect       |                    |
                            |  Send the discon.  |
                            |  message to the    |
                            |  intermediary      |
                            |                    |  Become aware of
                            |                    |  the disconnect
                            |                    |  and act
                            |                    |  accordingly

=head1 EXAMPLES

B<NOTE>: Examples are in the examples/ directory supplied with the
distribution.

=head1 PARAMETERS FOR C<new>

=over

=item C<external_port>

This is the port that the end users will use to access the application.
If it is not specified, the default is 6715.

=item C<client_port>

This is the port that intermediary will use to communicate internally
with the application.

=head1 METHODS

=over

=item C<send($id, $data)>

Sends C<$data> (string format) to the socket that belongs to C<$id>

=back

=head1 HOOKS

These methods are NOT for complete overriding. They do important
things that involve communication with the client. They are here
so that you can hook I<around> these methods in any way you see fit.

=over

=item C<client_connect>

Method called when the client connects to the intermediary

=item C<client_input>

Method called when the client sends data to the intermediary

=item C<client_disconnect>

Method called when the client disconnects from the intermediary

=item C<connect>

Method called when a user connects to the intermediary

=item C<input>

Method called when a user sends data to the intermediary

=item C<disconnect>

Method called when a user disconnects from the intermediary

=back

=head1 SEE ALSO

=over

=item L<IO::Multiplex>

=back

=head1 AUTHOR

Jason May <jason.a.may@gmail.com>

=head1 LICENSE

This library is free software and may be distributed under the same
terms as perl itself.

=cut
