# NAME

IPC::Manager::Client::SharedMem - SysV shared memory as a message store

# DESCRIPTION

This protocol stores all client state, messages, and statistics in a SysV
shared memory segment.  Access is serialised with a SysV semaphore.  Every
mutation acquires the semaphore, reads the segment, modifies the in-memory
structure, writes it back, and releases the semaphore.

The data is stored as JSON prefixed with a 4-byte network-order length.
When the data outgrows the current segment, a new larger segment is
allocated and the old one is removed.

This protocol requires [IPC::SysV](https://metacpan.org/pod/IPC%3A%3ASysV) version 2.09 or later (a core module).

# SYNOPSIS

    use IPC::Manager qw/ipcm_spawn ipcm_connect/;

    my $spawn = ipcm_spawn(protocol => 'SharedMem');

    my $con1 = $spawn->connect('con1');
    my $con2 = ipcm_connect(con2 => $spawn->info);

    $con1->send_message(con2 => {hello => 'world'});

    my @messages = $con2->get_messages;

# ROUTE FORMAT

The route is a colon-separated string: `shmid:semid`, where `shmid`
and `semid` are SysV IPC identifiers (integers).  The segment capacity
is stored in the segment header itself, so it does not need to appear
in the route.

# METHODS

See [IPC::Manager::Client](https://metacpan.org/pod/IPC%3A%3AManager%3A%3AClient) for inherited methods.

# SOURCE

The source code repository for IPC::Manager::Client::SharedMem can be found
at [https://github.com/exodist/IPC-Manager-Client-SharedMem](https://github.com/exodist/IPC-Manager-Client-SharedMem).

# MAINTAINERS

- Chad Granum <exodist@cpan.org>

# AUTHORS

- Chad Granum <exodist@cpan.org>

# COPYRIGHT

Copyright Chad Granum <exodist7@gmail.com>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See [https://dev.perl.org/licenses/](https://dev.perl.org/licenses/)
