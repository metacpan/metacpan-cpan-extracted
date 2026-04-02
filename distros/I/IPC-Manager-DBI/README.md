# NAME

IPC::Manager:DBI - Database based clients for [IPC::Manager](https://metacpan.org/pod/IPC%3A%3AManager).

# DESCRIPTION

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

# SOURCE

The source code repository for IPC::Manager can be found at
[https://github.com/exodist/IPC-Manager](https://github.com/exodist/IPC-Manager).

# MAINTAINERS

- Chad Granum <exodist@cpan.org>

# AUTHORS

- Chad Granum <exodist@cpan.org>

# COPYRIGHT

Copyright Chad Granum <exodist7@gmail.com>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See [https://dev.perl.org/licenses/](https://dev.perl.org/licenses/)
