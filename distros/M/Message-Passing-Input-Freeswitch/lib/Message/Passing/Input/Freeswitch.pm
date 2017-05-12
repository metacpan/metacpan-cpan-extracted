package Message::Passing::Input::Freeswitch;
use Moose;
use AnyEvent;
use Scalar::Util qw/ weaken /;
use Try::Tiny qw/ try catch /;
use namespace::autoclean;

our $VERSION = '0.006';
$VERSION = eval $VERSION;

with qw/
    Message::Passing::Role::Input
    Message::Passing::Role::HasHostnameAndPort
/;

sub _default_port { 8021 }

has secret => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has connection_retry_timeout => (
    is => 'ro',
    isa => 'Int',
    default => 3,
);

has event_types => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { ['all'] },
);

has '_connection' => (
    isa => 'ESL::ESLconnection',
    lazy => 1,
    default => sub {
        my $self = shift;
        require ESL;
        # FIXME Retarded SWIG bindings want the port number as a string, not an int
        #       so we explicitly stringify it
        my $con = new ESL::ESLconnection($self->hostname, $self->port."", $self->secret);
        unless ($con) {
            warn("Could not connect to freeswitch on " . $self->hostname . ":" . $self->port);
            $self->_terminate_connection($self->connection_retry_timeout);
            $con = bless {}, 'ESL::ESLconnection';
        }
        foreach my $name (@{$self->event_types}) {
            $con->events("plain", $name);
        }
        $con->connected() || do {
            $con->disconnect;
            $self->_terminate_connection($self->connection_retry_timeout);
        };
        return $con;
    },
    is => 'ro',
    clearer => '_clear_connection',
    handles => {
        _connection_fd => 'socketDescriptor',
    },
);

sub _try_rx {
    my $self = shift;
    my $con = $self->_connection;
    if (!$con->connected) {
        $self->_terminate_connection;
        return;
    }
    my $e = $con->recvEventTimed(0);

    if ($e) {
        my %data;
        my $h = $e->firstHeader();
        while ($h) {
            $data{$h} = $e->getHeader($h);
            $h = $e->nextHeader();
        }
        $self->output_to->consume(\%data);
        return 1;
    }
    return;
}

has _io_reader => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $weak_self = shift;
        weaken($weak_self);
        my $fd =  $weak_self->_connection_fd;
        return unless $fd >= 0;
        AE::io $fd, 0,
            sub { my $more; do { $more = $weak_self->_try_rx } while ($more) };
    },
    clearer => '_clear_io_reader',
);

sub _terminate_connection {
    my ($self, $retry) = @_;
    $retry ||= 0;
    weaken($self);
    # Push building the io reader here as an idle task,
    # to avoid blowing up the stack.... (We're already in a callback here)
    # This probably isn't totally necessary, but avoids potential recursion issues.
    my $i; $i = AnyEvent->timer(
        after => $retry,
        cb => sub {
            undef $i;
            $self->_clear_io_reader;
            $self->_clear_connection;
            $self->_io_reader;
        },
    );
}

has _connection_checker => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        weaken($self);
        AnyEvent->timer( after => $self->connection_retry_timeout, every => $self->connection_retry_timeout,
            cb => sub {
                $self->_try_rx;
            },
        );
    },
);

sub BUILD {
    my $self = shift;
    $self->_io_reader;
    $self->_connection_checker;
}

1;

=head1 NAME

Message::Passing::Input::Freeswitch - input messages from Freeswitch.

=head1 SYNOPSIS

    message-pass --input Freeswitch --input_options \
        '{"hostname":"127.0.0.1","secret":"s3kriTk3y"}' \
        --output STDOUT

=head1 DESCRIPTION

Produces a message stream from a L<Freeswitch|http://www.freeswitch.org/>
instance.

Uses the Freeswitch L<|Event Socket Library|http://wiki.freeswitch.org/wiki/Event_Socket_Library>
to connect to a local or remote Freeswitch instance and stream event messages.

=head1 ATTRIBUTES

=head2 hostname

The Freeswitch host to connect to.

=head2 secret

The secret configured in Freeswitch for connecting to the event listener socket.

=head2 connection_retry_timeout

The number of seconds to wait after a disconnect before reconnecting. Default 3.

=head2 port

The port that Freeswitch's ESL socket is listening on. Defaults to 8021.

=head2 events

An arrayref of types of events to listen for. These types are documented
L<on the Freeswitch wiki|http://wiki.freeswitch.org/wiki/Event_List>.

By default, the special type, C<all> is used - which means all event types
are subscribed to.

=head1 SEE ALSO

=over

=item L<Message::Passing>

=item L<http://www.freeswitch.org/>

=item L<http://wiki.freeswitch.org/wiki/Event_Socket_Library>

=item L<http://wiki.freeswitch.org/wiki/Event_List>

=back

=head1 AUTHOR

Tomas (t0m) Doran <bobtfish@bobtfish.net>

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored it's development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API - 
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 COPYRIGHT

Copyright Suretec Systems Ltd. 2012.

Logstash (upon which many ideas for this project is based, but
which we do not reuse any code from) is copyright 2010 Jorden Sissel.

=head1 LICENSE

GNU Affero General Public License, Version 3

If you feel this is too restrictive to be able to use this software,
please talk to us as we'd be willing to consider re-licensing under
less restrictive terms.

=cut

