# NAME

Mail::POP3 -- a module implementing a full POP3 server

# SYNOPSIS

    use Mail::POP3;
    my $config_text = Mail::POP3->from_file($config_file);
    my $config = Mail::POP3->read_config($config_text);
    Mail::POP3->make_sane($config);
    while (my $sock = $server_sock->accept) {
      my $server = Mail::POP3::Server->new(
        $config,
      );
      $server->start(
        $sock,
        $sock,
        $sock->peerhost,
      );
    }

# DESCRIPTION

`Mail::POP3` and its associated classes work together as follows:

- [Mail::POP3::Daemon](https://metacpan.org/pod/Mail::POP3::Daemon) does the socket-accepting.
- [Mail::POP3::Server](https://metacpan.org/pod/Mail::POP3::Server) does (most of) the network POP3 stuff.
- [Mail::POP3::Security::User](https://metacpan.org/pod/Mail::POP3::Security::User) and [Mail::POP3::Security::Connection](https://metacpan.org/pod/Mail::POP3::Security::Connection)
do the checks on users and connections.
- `Mail::POP3::Folder::*` classes handles the mail folders.

This last characteristic means that diverse sources of information
can be served up as though they are a POP3 mailbox by implementing
a `Mail::POP3::Folder` subclass. An example is provided in
[Mail::POP3::Folder::webscrape](https://metacpan.org/pod/Mail::POP3::Folder::webscrape), and included is a working configuration
file that makes the server connect to Jobserve (as of Jan 2014) and
provide a view of jobs as email messages in accordance with the username
which provides a colon-separated set of terms: keywords (encoding spaces
as `+`), location radius in miles, location (e.g. Berlin). E.g. the
username `perl:5:Berlin` would search for jobs relating to Perl within
5 miles of Berlin.

# OVERVIEW

[Mail::POP3](https://metacpan.org/pod/Mail::POP3) is a working POP3 server module, with a working `mpopd`
that can either work as a standalone, be called from `inetd`, or be
used in non-forking mode for use on Windows platforms that do not do
forking correctly.

# SCRIPTS

- mpopd

    The core. Read this to see how to use modules.

- mpopdctl

    Gives command-line control of a running mpopd.

- mpopdstats

    Gives command-line statistics from mpopd.

- installscript

    Helps install mpopd and create configuration.

- update-conf

    Helps you upgrade an older config (the file format changed).

# DESIGN

- Mail::POP3::Daemon does the socket-accepting.
- Mail::POP3::Server does (most of) the network POP3 stuff.
- Mail::POP3::Security::{User,Connection} do the checks on users and connections.
- Mail::POP3::Folder::\* classes handles the mail folders.

This last characteristic means that diverse sources of information can
be served up as though they are a POP3 mailbox by implementing a M::P::F
subclass. An example is provided in M::P::F::webscrape.

# FUTURE

This module will become a [Net::Server](https://metacpan.org/pod/Net::Server) subclass, such that the Folder
functionality will be folded back into the server, in a class called
(probably) `Net::Server::POP3::webscrape` (etc).

# METHODS

All class methods.

## from\_file

Given a file, returns contentx.

## make\_sane

Mutates given config hashref to have good, default values.

## read\_config

Given config text, evals it then version-checks.

# COPYRIGHT

Copyright (c) Mark Tiramani 1998-2001 - up to version 2.21.
Copyright (c) Ed J 2001+ - version 3+.
All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

# DISCLAIMER

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the Artistic License for more details.
