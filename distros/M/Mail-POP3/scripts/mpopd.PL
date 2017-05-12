#!/usr/bin/perl

use Config;

open OUTPUT, ">$ARGV[0]" or die "$ARGV[0]: $!\n";
select OUTPUT;

print << "!GROK!THIS!";
$Config{'startperl'}
!GROK!THIS!
print << '!GROK!THIS!';

use strict;
use Mail::POP3;
use POSIX qw(setsid);
use Getopt::Long;

my $USAGE = "Usage: $0 -v | [-s] config-file [portnum]\n";
my $singlethread;

GetOptions(
    v => sub { print "mpopd V$Mail::POP3::VERSION\n"; exit(0); },
    s => \$singlethread,
);

my ($config_file, $portnum) = @ARGV;
die $USAGE unless -f $config_file;
die $USAGE if defined $portnum and $portnum == 0; # ie non-numeric

my $config_text = Mail::POP3->from_file($config_file);
my $config = Mail::POP3->read_config($config_text);
Mail::POP3->make_sane($config);

# Accept a port to bind to, for special purposes
if (defined $portnum) {
    $config->{port} = $portnum;
}

if ($singlethread) {
    my $server_sock = IO::Socket::INET->new(
        Listen    => 1,
        LocalPort => $config->{port},
        Proto     => 'tcp',
    );
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
} elsif (my $paddr = getpeername STDIN) {
    # we are being called by inetd
    my ($port, $iaddr) = sockaddr_in($paddr);
    my $server = Mail::POP3::Server->new(
        $config,
    );
    $server->start(
        \*STDIN,
        \*STDOUT,
        inet_ntoa($iaddr),
    );
} else {
    # completely detach from any controlling service/terminal
    eval { setsid(); };
    # Start the POP3 server parent daemon
    my $daemon = Mail::POP3::Daemon->new(
        $config,
    );
    $daemon->start;
}

__END__

=head1 NAME

mpopd -- A POP3 stand-alone forking daemon or inetd server

mpopd complies with: RFC 1939 but one or two recommendations
can be overridden in the configuration file: mpopd allows
rejection of bogus UIDs as a configurable option. mpopd allows
a timeout of n seconds as a configuration item. mpopd supports
UIDL and TOP but not APOP. The documentation is minimal at present.
There are pod docs in the mpopd, mpodctl and mpopd_test scripts.

=head1 PREREQUISITES

Either, a local MDA that understands <username>.lock
file locking (e.g. procmail), or a local MDA that uses
the Qmail-style maildir message store.

mpopd has been tested on Linux 2.0.35 with Perl 5.005_3
and on several later versions up to 2.2.18 / 5.6.0

=head1 COREQUISITES

The following module may be required for some systems
when using crypt-MD5-hashed passwords:

    Crypt::PasswdMD5

You will need the following module if you wish to use
PAM authentication:

    Authen::PAM

The PAM authentication has only been tested on Linux 2.2.18,
Perl 5.6.0, Linux-PAM-0.74 and Authen-PAM-0.11

You will need the following module if you wish to use
the mpopd_test script:

    Time::HiRes

=head1 SYNOPSIS

mpopdctl [B<-f>] [B<-p> port] start | stop | restart | refresh | [B<-e>] config | B<-h>

or

mpopd [port] &

=head1 DESCRIPTION

=head2 To run mpopd under inetd:

Place a line like the following in inetd.conf:

pop3 stream tcp nowait root /usr/sbin/tcpd /usr/bin/mpop

The /etc/services file must have an entry similar to this:

pop3        110/tcp

=head2 To run as a standalone daemon:

Either:

Use the mpopdctl script (recommended) or if the mpopd wrapper
script is in your path path just type:
B<mpopd &>
and mpopd should detach itself.

You can also override the config value for the port mpopd
should use by giving it as a single command line argument:

B<mpopd 8110 &>

or:

B<mpopdctl start>

=head1 mpopdctl

mpopdctl is a script to make starting, stopping and sending
signals to mpopd a bit more convenient:

B<mpopdctl> [B<-f>] [B<-p> port] start | stop | restart | refresh | [B<-e>] config | B<-h>

[B<-f>] [B<-p> port] start

Start the mpopd server daemon.

The optional B<-f> flag removes any pid file left over after an
mpopd or system crash.

The optional B<-p> flag allows a port number to be specified,
which overrides the config file setting. This allows other
instances to be run in parrallel to the standard port 110
for testing.

Example:

mpopdctl B<-p> 8110 B<-f> start

Would remove a stale pid file and start mpopd in daemon mode
on port 8110

=head2 stop

Stop the mpopd server daemon.

=head2 restart

Stops the mpopd server daemon and imediately restarts it.

=head2 refresh

mpopd will send a signal to all currently executing
child servers to close. They will interrupt what they
were doing and restore the user's mailbox, ignoring any
commands to delete messages. mpopd will close its server
socket, reopen it and bind to the port set in $self->{CONFIG}->{port} in
the mpopd config file.

[B<-e>] B<config>

Call a running mpopd server and ask it to re-read the mpopd
configuration file. All subsequent child servers inherit the
new config values, with the exception of the port number
which can only be changed using the 'refresh' flag.

The optional B<-e> flag will open the mpopd config file in an
editor of your choice first. After the editor is closed mpopd
will ask you if it should re-read the modified config file.

B<-h>

Display a help screen.

=head1 Signalling a running mpopd server with 'kill'

As a daemon mpopd understands three signals:

=head2 SIGTERM

Signals mpopd to close all child servers before removing
its own pid file and exiting.

=head2 SIGHUP

Signals all child servers to close, hopefully without
losing any mail. The server socket is closed and some
cleanup is done. The config file is re-read and then the
socket is rebuilt and the port is bound to. This also
facilitates changing the port number.

=head2 SIGUSR1

Just re-read the config file. Any changes will only take
effect for subsequent child server processes.

=head1 README

The distribution of Mail::POP3 includes a sample config, access control
file samples and a couple of tool/helper scripts. You can find it on CPAN.

First read and then edit mpopd.conf to suit your system.
mpopd.conf is also the best documentation there is for now.
Next, edit the 'CONFIG' values near the top of the mpopd script
itself to reflect the location of mpopd.conf

Requires either qmail-style 'maildir' or single-file
Berkeley-style mbox mailboxes.

For mbox mail files mpopd can use an arbitrary start-of-message
and end-of-message identifier for each message.
These default to 'From ' and a blank line.

=head2 Mail storage modes

mpopd can be used in one of three modes:

1. Disk-based mailbox handling, the entire mailbox is parsed
   and each message is written to a root-owned mpopd spool
2. Fully RAM-based mailbox handling, the entire mailbox is parsed
   and each message is read into an array
3. Qmail-style maildir mailboxes. No parsing required.

mpopd accommodates virtual-users and hostname-based authentication.

Uses <username>.lock semaphore file checking for Berkeley mbox style
mailbox locking and a lock file for the per-user dirs where the temp
message files are created.

Configurable via the mpopd.conf text/perl config file.

Variable logging levels, including on/off activation
of logging on a per user basis.

=head2 mpopd can use 7 main kinds of authentication:

 1. Standard /etc/passwd or shadow file and system mailboxes.
 2. as 1. plus a fallback to hostname lookup.
 3. as 2. plus remote access via full email address as UID.
 4. hostname lookup and custom user-list authentication only.
 5. as 4. plus remote access via full email address as UID.
 6. Only the user-list and a cental mailspool are used.
 7. A basic form of user-defined plugin.

 Plus:
 Per-user configurable authentication based on 1-7.

 See the 'User authentication' section in mpopd.conf if you want
 to set-up hostname-based mailspool dirs and/or virtual users.

=head2 COPYRIGHT

Copyright (c) Mark Tiramani 1998-2001 - up to version 2.21.
Copyright (c) Ed J 2001+ - version 3+.
All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head2 DISCLAIMER:

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the Artistic License for more details.

=cut
!GROK!THIS!
