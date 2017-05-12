=head1 NAME

Log::Syslog::DangaSocket - Danga::Socket wrapper around a syslog sending socket
(TCP, UDP, or UNIX).

=head1 SYNOPSIS

    my $logger = Log::Syslog::DangaSocket->new(
        $proto,         # 'udp', 'tcp', or 'unix'
        $dest_host,     # destination hostname or filename
        $dest_port,     # destination port (ignored for unix socket)
        $sender_host,   # sender hostname (informational only)
        $sender_name,   # sender application name (informational only)
        $facility,      # syslog facility number
        $severity,      # syslog severity number
        $reconnect      # whether to reconnect on error
    );

    Danga::Socket->AddTimer(5, sub { $logger->send("5 seconds elapsed") });

    Danga::Socket->EventLoop;

=head1 DESCRIPTION

This module constructs and asynchronously sends syslog packets to a syslogd
listening on a TCP or UDP port, or a UNIX socket. Calls to
C<$logger-E<gt>send()> are guaranteed to never block; though naturally, this
only works in the context of a running Danga::Socket event loop.

UDP support is present primarily for completeness; an implementation like
L<Log::Syslog::Fast> will provide non-blocking behavior with less overhead.
Only in the unlikely case of the local socket buffer being full will this
module benefit you by buffering the failed write and retrying it when possible,
instead of silently dropping the message. But you should really be using TCP
or a domain socket if you care about reliability.

Trailing newlines are added automatically to log messages.

=head2 ERROR HANDLING

If a fatal occur occurs during sending (e.g. the connection is remotely closed
or reset), Log::Syslog::DangaSocket will attempt to automatically reconnect if
$reconnect is true. Any pending writes from the closed connection will be
retried in the new one.

=head1 SEE ALSO

L<Danga::Socket>

L<Log::Syslog::Constants>

L<Log::Syslog::Fast>

=head1 AUTHOR

Adam Thomason, E<lt>athomason@sixapart.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Six Apart, E<lt>cpan@sixapart.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

package Log::Syslog::DangaSocket;

use strict;
use warnings;

our $VERSION = '1.06';

our $CONNECT_TIMEOUT = 1;

use Log::Syslog::DangaSocket::Socket;
use POSIX 'strftime';

use base 'fields';

use fields (
    # ->new params
    'send_host',    # where log message originated
    'name',         # application-defined logger name
    'facility',     # syslog facility constant
    'severity',     # syslog severity constant
    'reconnect',    # whether to attempt reconnect on error

    # state vars
    'sock',         # Log::Syslog::DangaSocket::Socket object
    'last_time',    # last epoch time when a prefix was generated
    'prefix',       # stringified time changes only once per second, so cache it and rest of prefix
);

sub new {
    my $ref   = shift;
    my $class = ref $ref || $ref;

    my $proto = shift;
    my $host  = shift;
    my $port  = shift;

    my Log::Syslog::DangaSocket $self = fields::new($class);

    ( $self->{send_host},
      $self->{name},
      $self->{facility},
      $self->{severity},
      $self->{reconnect} ) = @_;

    my $connecter;
    $connecter = sub {
        my $unsent = shift;
        $self->{sock} = Log::Syslog::DangaSocket::Socket->new(
            $proto, $host, $port, $connecter, $unsent,
            ($self->{reconnect} ? $connecter : ()),
        );
    };
    $connecter->();

    for (qw/ send_host name facility severity /) {
        die "missing parameter $_" unless $self->{$_};
    }

    $self->_update_prefix(time);

    return $self;
}

sub facility {
    my $self = shift;
    if (@_) {
        $self->{facility} = shift;
        $self->_update_prefix(time);
    }
    return $self->{facility};
}

sub severity {
    my $self = shift;
    if (@_) {
        $self->{severity} = shift;
        $self->_update_prefix(time);
    }
    return $self->{severity};
}

sub _update_prefix {
    my Log::Syslog::DangaSocket $self = shift;

    # based on http://www.faqs.org/rfcs/rfc3164.html
    my $time_str = strftime('%b %d %H:%M:%S', localtime($self->{last_time} = shift));

    my $priority = ($self->{facility} << 3) | $self->{severity}; # RFC3164/4.1.1 PRI Part

    $self->{prefix} = "<$priority>$time_str $self->{send_host} $self->{name}\[$$]: ";
}

sub send {
    my Log::Syslog::DangaSocket $self = shift;

    # update the log-line prefix only if the time has changed
    my $time = time;
    $self->_update_prefix($time) if $time != $self->{last_time};

    $self->{sock}->write_buffered(\join '', $self->{prefix}, $_[0], "\n");
}

1;
