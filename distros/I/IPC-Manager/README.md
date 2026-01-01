# NAME

IPC::Manager - Decentralized local IPC through various protocols.

# DESCRIPTION

IPC::Manager provides a way to do message based IPC between local (on a single
machine) processes. It provides multiple protocols for doing this, as well as
pluggable serialization.

The idea is to first initialize a data store, provide the info to access the
data store, then any process may use that info to send/recieve messages. The
datastore can be temporary (guarded) or persistent.

# SYNOPSIS

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
You can use the string returned by `$ipcm->info` from any process to reach
the data store.

You can set up persistent data stores, in which case the `ipcm_spawn()` export
is not needed. How to set up a persistent data store is documented in each
client protocol.

Messages are instances of [IPC::Manager::Message](https://metacpan.org/pod/IPC%3A%3AManager%3A%3AMessage). You can make the instances
yourself manually and send them, or you can let `send_message()` create them
for you:

    $con1->send_message(con2 => IPC::Manager::Message->new(content => \%CONTENT, ...));
    $con1->send_message(con2 => \%CONTENT);

# EXPORTS

- $ipcm = ipcm->spawn(...)
- $con = ipcm->connect(...)
- $con = ipcm->reconnect(...)

    `ipcm()` is an alias for `IPC::Manager`. You can use it to call spawn,
    connect, or reconnect without importing `ipcm_spawn()`, `ipcm_connect()`, or
    `ipcm_reconnect()` into your namespace.

- $ipcm = ipcm\_spawn()
- $ipcm = ipcm\_spawn(protocol => $PROTOCOL)
- $ipcm = ipcm\_spawn(protocols => \\@PROTOCOLS)
- $ipcm = ipcm\_spawn(serializer => 'JSON', guard => 1, signal => $SIGNAL)

    This will create a new data store for IPC. By default it will be temporary and
    will be destroyed when the $ipcm object falls out of scope.

    You can set `guard => 0` to prevent the destruction of the datastore when
    the object falls out of scope.

    You can also set a signal, such as `'INT'` or `'TERM'` to have the signal
    sent to the PID for all clients when the instance is shut down.

    You can set the serializer with the `serializer => $CLASS` option.
    'IPC::Manager::Serializer::' will be prefixed onto the class name unless it is
    already present, or if the class name starts with '+'.

    You can pick a protocol with the `protocol => $CLASS` option.
    'IPC::Manager::Client::' will be prefixed onto the class name unless it is
    already present, or if the class name starts with '+'.

    If you do not care what protocol is used you can leave it blank, in which case
    one will be picked for you based on what your system supports. Order in which
    it will try protocols is subject to change at any time.

    If you want to narrow down to a specific set of protocols you may provide a
    list: `protocols => [ 'AtomicPipe', 'UnixSocket', 'PostgreSQL', ... ]`.
    The first viable protocol will be used.

    The object returned is an instance of [IPC::Manager::Spawn](https://metacpan.org/pod/IPC%3A%3AManager%3A%3ASpawn).

- $con = ipcm\_connect($name => $info)

    This is used to establish a connection. The `$name` should be a unique name
    for your connection, it will be used as the 'from' field for any message you
    send, and will be used by other clients to send messages to you.

    The `$info` argument must be the connection info needed to connect to the data
    store. This is always a 3 element arrayref, or a JSON string with the 3 element
    arrayref.

        [$protocol_class, $serializer_class, $route]
        '["PROTOCOL_CLASS", "SERIALIZER_CLASS", "ROUTE"]'

    The protocol should always be an [IPC::Manager::Client](https://metacpan.org/pod/IPC%3A%3AManager%3A%3AClient) subclass. The
    serializer should always be an [IPC::Manager::Serializer](https://metacpan.org/pod/IPC%3A%3AManager%3A%3ASerializer) subclass. The route
    is protocol specific, it may be a file, a directory, a DBI DSN string, etc.

- $con = ipcm\_reconnect($name => $info)

    Same as 'connect', but used to reconnect as a client that was suspended or
    otherwise disconnected.

# CLIENT PROTOCOLS

See [IPC::Manager::Client](https://metacpan.org/pod/IPC%3A%3AManager%3A%3AClient) for common methods across all client types.

## FileSystem Based

These are all based off of [IPC::Manager::Base::FS](https://metacpan.org/pod/IPC%3A%3AManager%3A%3ABase%3A%3AFS). These are all based on a
directory structure of some kind.

- MessageFiles

    [IPC::Manager::Client::MessageFiles](https://metacpan.org/pod/IPC%3A%3AManager%3A%3AClient%3A%3AMessageFiles)

    This is the most universal protocol, it works in the most places.

    This uses a directory as the 'route'. Within this directory each client creates
    a subdirectory. Messages are sent by writing a file per message to the clients
    directory. Messages are deleted from the filesystem when read.

- AtomicPipe

    [IPC::Manager::Client::AtomicPipe](https://metacpan.org/pod/IPC%3A%3AManager%3A%3AClient%3A%3AAtomicPipe)

    This uses a directory as the 'route'. This uses the [Atomic::Pipe](https://metacpan.org/pod/Atomic%3A%3APipe) library to
    send atomic messages across pipes. Each client has its own FIFO pipe any other
    process can write to when sending a message. Messages are recieved by reading
    from the pipe. (Multiple writer, single reader).

- UnixSocket

    [IPC::Manager::Client::UnixSocket](https://metacpan.org/pod/IPC%3A%3AManager%3A%3AClient%3A%3AUnixSocket)

    This uses a directory as the 'route'. This uses unix sockets, one per client.
    Messages are sent by writing them to the correct clients socket.  (Multiple
    writer, single reader).

## DBI Based

These are all based off of [IPC::Manager::Base::DBI](https://metacpan.org/pod/IPC%3A%3AManager%3A%3ABase%3A%3ADBI). These all use a database
as the message store.

These all have 1 table for tracking clients, and another for tracking messages.
Messages are deleted once read. The 'route' is a DSN. You also usually need to
provide a username and password.

    my $con = ipcm_connect(my_con => $info, user => $USER, pass => $PASS);

- MariaDB

    [IPC::Manager::Client::MariaDB](https://metacpan.org/pod/IPC%3A%3AManager%3A%3AClient%3A%3AMariaDB)

- MySQL

    [IPC::Manager::Client::MySQL](https://metacpan.org/pod/IPC%3A%3AManager%3A%3AClient%3A%3AMySQL)

- PostgreSQL

    [IPC::Manager::Client::PostgreSQL](https://metacpan.org/pod/IPC%3A%3AManager%3A%3AClient%3A%3APostgreSQL)

- SQLite

    [IPC::Manager::Client::SQLite](https://metacpan.org/pod/IPC%3A%3AManager%3A%3AClient%3A%3ASQLite)

# CLEANUP

When using a temporary instance that cleans up after itself, the cleanup
process will send terminations messages to all clients, then wait for them to
disconnect. It will also tell you if there is a mismtach between sent and
recieved messages.

See [IPC::Manager::Spawn](https://metacpan.org/pod/IPC%3A%3AManager%3A%3ASpawn) for more information.

# SOURCE

The source code repository for IPC::Manager can be found at
[https://https://github.com/exodist/IPC-Manager](https://https://github.com/exodist/IPC-Manager).

# MAINTAINERS

- Chad Granum <exodist@cpan.org>

# AUTHORS

- Chad Granum <exodist@cpan.org>

# COPYRIGHT

Copyright Chad Granum <exodist7@gmail.com>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See [https://dev.perl.org/licenses/](https://dev.perl.org/licenses/)
