#!perl
package IO::Multiplex::Intermediary::Client;
use Moose;
use namespace::autoclean;

use IO::Socket;
use IO::Select;
use Time::HiRes qw(gettimeofday);
use JSON;

local $| = 1;

has socket => (
    is         => 'rw',
    isa        => 'IO::Socket::INET',
    lazy_build => 1,
    clearer    => 'clear_socket',
);

sub _build_socket {
    my $self = shift;
    my $socket = IO::Socket::INET->new(
        PeerAddr => $self->host,
        PeerPort => $self->port,
        Proto    => 'tcp',
    ) or die $!;

    return $socket;
}

has host => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => 'localhost',
);

has port => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => 9000
);

has read_set => (
    is         => 'ro',
    isa        => 'IO::Select',
    lazy_build => 1,
);

has remaining_usecs => (
    is      => 'rw',
    isa     => 'Int',
    default => 1_000_000,
);

sub _build_read_set {
    my $self = shift;
    my $select = IO::Select->new;

    $select->add($self->socket);
    return $select;
}

sub parse_input {
    my $self  = shift;
    my $input = shift;

    $input =~ s/[\r\n]*$//s;
    my @inputs = grep { $_ } split /\e/m, $input;
    for (@inputs) {
        my $output = $self->parse_json($_);
        $self->socket->send("$output\n\e");
    }
};

sub build_response {
    my $self     = shift;
    my $wheel_id = shift;
    my $input    = shift;

    return $input;
}

sub connect_hook {
    my $self   = shift;
    my $data   = shift;

    return to_json({param => 'null'});
}

sub input_hook {
    my $self   = shift;
    my $data   = shift;

    return to_json(
        {
            param => 'output',
            data => {
                value => $self->build_response(
                    $data->{data}->{id},
                    $data->{data}->{value}
                ),
                id => $data->{data}->{id},
            }
        }
    );
}

sub disconnect_hook {
    my $self   = shift;
    my $data   = shift;

    my $id = $data->{data}->{id};

    return to_json(
        {
            param => 'disconnect',
            data  => {
                success => 1,
            },
        }
    );
}

sub parse_json {
    my $self = shift;
    my $json = shift;
    my $data = eval { from_json($json) };

    if ($@) { warn $@; return }

    my %actions = (
        'connect'    => sub { $self->connect_hook($data)    },
        'input'      => sub { $self->input_hook($data)      },
        'disconnect' => sub { $self->disconnect_hook($data) },
    );

    return $actions{ $data->{param} }->()
        if exists $actions{ $data->{param} };


    return to_json({param => 'null'});
}

sub force_disconnect {
    my $self = shift;
    my $id = shift;
    my %args = @_;

    my $output = to_json +{
        param => 'disconnect',
        data => {
            id => $id,
            %args,
        }
    };

    $self->socket->send("$output\n\e");
}

sub send {
    my $self = shift;
    my ($id, $message) = @_;

    my $output = to_json +{
        param => 'output',
        data => {
            value => $message,
            id    => $id,
        }
    };

    #warn "[C Sends]: $output";
    $self->socket->send("$output\n\e");
}

sub multisend {
    my $self = shift;
    my %ids  = @_;

    my $packet = q[];
    while (my ($id, $message) = each %ids) {
        $packet .= to_json +{
            param => 'output',
            data => {
                value => $message,
                id    => $id,
            },
        };

        $packet .= "\n\e";
    }

    #warn "[C Sends]: $output";
    $self->socket->send($packet);
}

sub tick {
    # stub
}

sub cycle {
    my $self = shift;

    my $sec_fraction = $self->remaining_usecs / 1_000_000;
    my @sockets_available = $self->read_set->can_read($sec_fraction);
    foreach my $fh (@sockets_available) {
        my $buf = <$fh>;
        return 0 unless defined $buf;
        $self->parse_input($buf);
    }

    my ($secs, $usecs) = gettimeofday;
    my $remaining      =   1_000_000 - $usecs;

    $remaining ||= 1_000_000;
    $self->remaining_usecs($remaining);

    $self->tick unless @sockets_available;

    return 1;
}

sub run {
    my $self = shift;
    1 while $self->cycle;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

IO::Multiplex::Intermediary::Client - base controller for the server

=head1 SYNOPSIS

    package Controller;
    use Moose;
    extends 'IO::Multiplex::Intermediary';

    around build_response => sub {
        my $orig = shift;
        my $self = shift;

        my $response = $self->$orig(@_);

        return rot13($response);
    };

    around connect_hook => sub {
        my $orig = shift;
        my $self = shift;
        my $data = shift;

        $players{ $data->{data}{id} } = new_player;

        return $self->$orig(@_);
    };

    around input_hook => sub {
        my $orig = shift;
        my $self = shift;

        return $self->$orig(@_);
    };

    around disconnect_hook => sub {
        my $orig   = shift;
        my $self   = shift;
        my $data   = shift;

        delete $player{ $data->{data}{id} };
        return $self->$orig($data, @_);
    };

=head1 DESCRIPTION

B<WARNING! THIS MODULE HAS BEEN DEEMED ALPHA BY THE AUTHOR. THE API
MAY CHANGE IN SUBSEQUENT VERSIONS.>

The flow of the controller starts when an end connection sends a
command.  The controller figures out who sent the command and relays
it to the logic that reads the command and comes up with a response
(Application).

   Connections
       |
       v
     Server
       ^
       |
       V
     Client
       ^
       |
       v
  Application

=head1 ATTRIBUTES

This module supplies you with these attributes which you can pass to
the constructor as named arguments:

=over

=item C<host>

This attribute is for the host on which the server runs.

=item C<port>

This attribute is for the host on which the server runs on.

=back

=head1 METHODS

=over

=item C<run>

Starts the client, which connects to the intermediary and waits for
input to respond to.

=item C<send($id, $message)>

Tells the intermediary to output C<$message> to the user with the ID
C<$id>.

=item C<multisend($id =E<gt> $message, $id =E<gt> $message, ...)>

Tells the intermediary to output various messages to its corresponding
IDs.

=back

=head1 HOOKS

These are internal methods with the primary purposes of hooking from
the outside for a more flexible and extensive use.

=over

=item C<build_response>

This hook is a method that you want to hook for doing your response
handling and output manipulateion (see the L</SYNOPSIS> section).  As the
method stands, C<build_response> returns exactly what was input to
the method, making the application a simple echo server.

=item C<connect_hook>

This hook runs after a user connects. It returns JSON data that
tells the intermediary that it has acknowledge the user has
connected.

=item C<input_hook>

This hook runs after the intermediary sends an input request. It
returns a JSON output request which contains the response build by
C<build_response>.

=item C<disconnect_hook>

This hook runs after a user disconnects. It has the same behavior
as the C<connect_hook> method, just with disconnect information.

=item C<tick>

This hook runs on the second every second. By itself, it is does
not do anything. Hooking from other applications is its only purpose.

=back

=head1 AUTHOR

Jason May <jason.a.may@gmail.com>

=head1 LICENSE

This library is free software and may be distributed under the same
terms as perl itself.

=cut
