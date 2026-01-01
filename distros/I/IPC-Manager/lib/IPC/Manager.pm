package IPC::Manager;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/croak/;

use IPC::Manager::Spawn();
use IPC::Manager::Serializer::JSON();

use Importer Importer => 'import';

our @EXPORT_OK = qw/ipcm_connect ipcm_reconnect ipcm_spawn ipcm/;

sub ipcm()         { __PACKAGE__ }
sub connect        { shift; ipcm_connect(@_) }
sub reconnect      { shift; ipcm_reconnect(@_) }
sub spawn          { shift; ipcm_spawn(@_) }
sub ipcm_connect   { _connect(connect   => @_) }
sub ipcm_reconnect { _connect(reconnect => @_) }

sub _parse_cinfo {
    my $cinfo = shift;

    my ($protocol, $route, $serializer);

    my $rtype = ref $cinfo;
    if ($rtype eq 'ARRAY') {
        ($protocol, $serializer, $route) = @$cinfo;
    }
    elsif (!$rtype) {
        ($protocol, $serializer, $route) = @{IPC::Manager::Serializer::JSON->deserialize($cinfo)};
        $protocol   = _parse_protocol($protocol);
        $serializer = _parse_serializer($serializer);
    }
    else {
        croak "Not sure what to do with $cinfo";
    }

    _require_mod($protocol);
    _require_mod($serializer);

    return ($protocol, $serializer, $route);
}

sub _parse_protocol {
    my $protocol = shift;
    $protocol = "IPC::Manager::Client::$protocol" unless $protocol =~ s/^\+// || $protocol =~ m/^IPC::Manager::Client::/;
    return $protocol;
}

sub _parse_serializer {
    my $serializer = shift;
    $serializer = "IPC::Manager::Serializer::$serializer" unless $serializer =~ s/^\+// || $serializer =~ m/^IPC::Manager::Serializer::/;
    return $serializer;
}

sub _connect {
    my ($meth, $id, $cinfo, %params) = @_;

    my ($protocol, $serializer, $route) = _parse_cinfo($cinfo);

    return $protocol->$meth($id, $serializer, $route, %params);
}

sub _require_mod {
    my $mod = shift;

    my $file = $mod;
    $file =~ s{::}{/}g;
    $file .= ".pm";

    require($file);
}

sub ipcm_spawn {
    my %params = @_;

    my $guard      = delete $params{guard}      // 1;
    my $serializer = delete $params{serializer} // 'JSON';
    my $protocol   = delete $params{protocol};
    my $protocols  = delete $params{procotols} // [
        'PostgreSQL',
        'MariaDB',
        'MySQL',
        'SQLite',
        'UnixSocket',
        'AtomicPipe',
        'MessageFiles',
    ];

    if ($protocol) {
        $protocol = _parse_protocol($protocol);
        _require_mod($protocol);
    }
    else {
        for my $prot (@$protocols) {
            $prot = _parse_protocol($prot);

            local $@;
            eval { _require_mod($prot); $prot->viable } or next;

            $protocol = $prot;
            last;
        }
    }

    $serializer = _parse_serializer($serializer);
    _require_mod($serializer);

    my ($route, $stash) = $protocol->spawn(%params, serializer => $serializer);

    return IPC::Manager::Spawn->new(
        protocol   => $protocol,
        serializer => $serializer,
        route      => $route,
        stash      => $stash,
        guard      => $guard,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager - Decentralized local IPC through various protocols.

=head1 DESCRIPTION

IPC::Manager provides a way to do message based IPC between local (on a single
machine) processes. It provides multiple protocols for doing this, as well as
pluggable serialization.

The idea is to first initialize a data store, provide the info to access the
data store, then any process may use that info to send/recieve messages. The
datastore can be temporary (guarded) or persistent.

=head1 SYNOPSIS

    use IPC::Manager qw/ipcm_connect ipcm_spawn/;

    # Let the system pick a protocol and serialization
    my $ipcm = ipcm_spawn();

    my $info = $ipcm->info;
    print "You can connect to the IPC using this string: $info\n";

    # Get a connection
    my $con1 = ipcm_connect(con1 => $info);
    my $con2 = ipcm_connect(con2 => $info);

    # Send a message
    $con1->send_message(con2 => {hello => 'world'});

    # Get messages
    if (my @messages = $con2->get_messages) {
        # hashref: {hello => 'world'}
        my $payload = $message[0]->content;
        ...
    }

    # Cleanup the datastore (unless `guard => 0` was passed in).
    $guard = undef;

The idea is to use the ipcm data store as the medium for transferring messages.
You can use the string returned by C<< $ipcm->info >> from any process to reach
the data store.

You can set up persistent data stores, in which case the C<ipcm_spawn()> export
is not needed. How to set up a persistent data store is documented in each
client protocol.

Messages are instances of L<IPC::Manager::Message>. You can make the instances
yourself manually and send them, or you can let C<send_message()> create them
for you:

    $con1->send_message(con2 => IPC::Manager::Message->new(content => \%CONTENT, ...));
    $con1->send_message(con2 => \%CONTENT);

=head1 EXPORTS

=over 4

=item $ipcm = ipcm->spawn(...)

=item $con = ipcm->connect(...)

=item $con = ipcm->reconnect(...)

C<ipcm()> is an alias for C<IPC::Manager>. You can use it to call spawn,
connect, or reconnect without importing C<ipcm_spawn()>, C<ipcm_connect()>, or
C<ipcm_reconnect()> into your namespace.

=item $ipcm = ipcm_spawn()

=item $ipcm = ipcm_spawn(protocol => $PROTOCOL)

=item $ipcm = ipcm_spawn(protocols => \@PROTOCOLS)

=item $ipcm = ipcm_spawn(serializer => 'JSON', guard => 1, signal => $SIGNAL)

This will create a new data store for IPC. By default it will be temporary and
will be destroyed when the $ipcm object falls out of scope.

You can set C<< guard => 0 >> to prevent the destruction of the datastore when
the object falls out of scope.

You can also set a signal, such as C<'INT'> or C<'TERM'> to have the signal
sent to the PID for all clients when the instance is shut down.

You can set the serializer with the C<< serializer => $CLASS >> option.
'IPC::Manager::Serializer::' will be prefixed onto the class name unless it is
already present, or if the class name starts with '+'.

You can pick a protocol with the C<< protocol => $CLASS >> option.
'IPC::Manager::Client::' will be prefixed onto the class name unless it is
already present, or if the class name starts with '+'.

If you do not care what protocol is used you can leave it blank, in which case
one will be picked for you based on what your system supports. Order in which
it will try protocols is subject to change at any time.

If you want to narrow down to a specific set of protocols you may provide a
list: C<< protocols => [ 'AtomicPipe', 'UnixSocket', 'PostgreSQL', ... ] >>.
The first viable protocol will be used.

The object returned is an instance of L<IPC::Manager::Spawn>.

=item $con = ipcm_connect($name => $info)

This is used to establish a connection. The C<$name> should be a unique name
for your connection, it will be used as the 'from' field for any message you
send, and will be used by other clients to send messages to you.

The C<$info> argument must be the connection info needed to connect to the data
store. This is always a 3 element arrayref, or a JSON string with the 3 element
arrayref.

    [$protocol_class, $serializer_class, $route]
    '["PROTOCOL_CLASS", "SERIALIZER_CLASS", "ROUTE"]'

The protocol should always be an L<IPC::Manager::Client> subclass. The
serializer should always be an L<IPC::Manager::Serializer> subclass. The route
is protocol specific, it may be a file, a directory, a DBI DSN string, etc.

=item $con = ipcm_reconnect($name => $info)

Same as 'connect', but used to reconnect as a client that was suspended or
otherwise disconnected.

=back

=head1 CLIENT PROTOCOLS

See L<IPC::Manager::Client> for common methods across all client types.

=head2 FileSystem Based

These are all based off of L<IPC::Manager::Base::FS>. These are all based on a
directory structure of some kind.

=over 4

=item MessageFiles

L<IPC::Manager::Client::MessageFiles>

This is the most universal protocol, it works in the most places.

This uses a directory as the 'route'. Within this directory each client creates
a subdirectory. Messages are sent by writing a file per message to the clients
directory. Messages are deleted from the filesystem when read.

=item AtomicPipe

L<IPC::Manager::Client::AtomicPipe>

This uses a directory as the 'route'. This uses the L<Atomic::Pipe> library to
send atomic messages across pipes. Each client has its own FIFO pipe any other
process can write to when sending a message. Messages are recieved by reading
from the pipe. (Multiple writer, single reader).

=item UnixSocket

L<IPC::Manager::Client::UnixSocket>

This uses a directory as the 'route'. This uses unix sockets, one per client.
Messages are sent by writing them to the correct clients socket.  (Multiple
writer, single reader).

=back

=head2 DBI Based

These are all based off of L<IPC::Manager::Base::DBI>. These all use a database
as the message store.

These all have 1 table for tracking clients, and another for tracking messages.
Messages are deleted once read. The 'route' is a DSN. You also usually need to
provide a username and password.

    my $con = ipcm_connect(my_con => $info, user => $USER, pass => $PASS);

=over 4

=item MariaDB

L<IPC::Manager::Client::MariaDB>

=item MySQL

L<IPC::Manager::Client::MySQL>

=item PostgreSQL

L<IPC::Manager::Client::PostgreSQL>

=item SQLite

L<IPC::Manager::Client::SQLite>

=back

=head1 CLEANUP

When using a temporary instance that cleans up after itself, the cleanup
process will send terminations messages to all clients, then wait for them to
disconnect. It will also tell you if there is a mismtach between sent and
recieved messages.

See L<IPC::Manager::Spawn> for more information.

=head1 SOURCE

The source code repository for IPC::Manager can be found at
L<https://https://github.com/exodist/IPC-Manager>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
