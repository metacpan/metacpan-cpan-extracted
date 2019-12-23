package Log::Syslog::Fast;

use 5.006002;
use strict;
use warnings;

our $VERSION = '0.67';

use Log::Syslog::Fast::Constants ':all';
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw();
our %EXPORT_TAGS = %Log::Syslog::Fast::Constants::EXPORT_TAGS;
our @EXPORT_OK = @Log::Syslog::Fast::Constants::EXPORT_OK;

require XSLoader;
XSLoader::load('Log::Syslog::Fast', $VERSION);

1;
__END__

=head1 NAME

Log::Syslog::Fast - Perl extension for sending syslog messages over TCP, UDP,
or UNIX sockets with minimal CPU overhead.

=head1 SYNOPSIS

  use Log::Syslog::Fast ':all';
  my $logger = Log::Syslog::Fast->new(LOG_UDP, "127.0.0.1", 514, LOG_LOCAL0, LOG_INFO, "mymachine", "logger");
  $logger->send("log message", time);

=head1 DESCRIPTION

This module sends syslog messages over a network socket. It works like
L<Sys::Syslog> in setlogsock's 'udp', 'tcp', or 'unix' modes, but without the
significant CPU overhead of that module when used for high-volume logging. Use
of this specialized module is only recommended if 1) you must use network
syslog as a messaging transport but 2) need to minimize the time spent in the
logger.

This module supercedes the less general L<Log::Syslog::UDP>.

=head1 METHODS

=over 4

=item Log::Syslog::Fast-E<gt>new($proto, $hostname, $port, $facility, $severity, $sender, $name);

Create a new Log::Syslog::Fast object with the following parameters:

=over 4

=item $proto

The transport protocol: one of LOG_TCP, LOG_UDP, or LOG_UNIX.

If LOG_TCP or LOG_UNIX is used, calls to $logger-E<gt>send() will block until
remote receipt of the message is confirmed. If LOG_UDP is used, the call will
never block and may fail if insufficient buffer space exists in the network
stack (in which case an exception will be thrown).

With LOG_UNIX, I<< ->new >> will first attempt to connect with a SOCK_STREAM
socket, and then try a SOCK_DGRAM if that is what the server expects (e.g.
rsyslog).

=item $hostname

For LOG_TCP and LOG_UDP, the destination hostname where a syslogd is running.
For LOG_UNIX, the path to the UNIX socket where syslogd is listening (typically
/dev/log).

=item $port

For LOG_TCP and LOG_UDP, the destination port where a syslogd is listening,
usually 514. Unused for LOG_UNIX, but should not be undefined or a warning will
be emitted under strict.

=item $facility

The syslog facility constant, eg 16 for 'local0'. See RFC3164 section 4.1.1 (or
E<lt>sys/syslog.hE<gt>) for appropriate constant values. See L<EXPORTS> below
for making these available by name.

The I<priority> value is computed from the facility and severity per the RFC.

=item $severity

The syslog severity constant, eg 6 for 'info'. See RFC3164 section 4.1.1 (or
E<lt>sys/syslog.hE<gt>) for appropriate constant values. See L<EXPORTS> below
for making these available by name.

=item $sender

The originating hostname. Sys::Hostname::hostname is typically a reasonable
source for this.

=item $name

The program name or tag to use for the message.

=back

=item $logger-E<gt>send($logmsg, [$time])

=item $logger-E<gt>emit($logmsg, [$time])

Send a syslog message through the configured logger. If $time is not provided,
B<time(2)> will be called for you. That doubles the syscalls per message, so
try to pass it if you're already calling time() yourself.

->send may throw an exception if the system call fails (e.g. the transport
becomes disconnected for connected protocols, or the kernel buffer is full for
unconnected). For this reason it is usually wise to wrap calls with an
exception handler. Likewise, calling ->send from a $SIG{__DIE__} handler is
unwise.

B<emit> is an alias for B<send>.

B<NEWLINE CAVEAT>

Note that B<send> does not add any newline character(s) to its input. You will
certainly want to do this yourself for TCP connections, or the server will not
treat each message as a separate line. However with UDP the server should
accept a message without a trailing newline (though some implementations may
have difficulty with that).

=item $logger-E<gt>set_receiver($proto, $hostname, $port)

Change the protocol, destination host, and port. This will force a reconnection
in LOG_TCP or LOG_UNIX mode.

=item $logger-E<gt>set_priority($facility, $severity)

Change both the syslog facility and severity.

=item $logger-E<gt>set_facility($facility)

Change only the syslog facility.

=item $logger-E<gt>set_severity($severity)

Change only the syslog severity.

=item $logger-E<gt>set_sender($sender)

Change what is sent as the hostname of the sender.

=item $logger-E<gt>set_name($name)

Change what is sent as the name of the sending program.

=item $logger-E<gt>set_pid($name)

Change what is sent as the process id of the sending program.

=item $logger-E<gt>set_format($format)

Change the message format. This should be either the constant LOG_RFC3164 (the
default) or LOG_RFC5424 or LOG_RFC3164_LOCAL (without HOSTNAME).

=item $logger-E<gt>get_priority()

Returns the current priority value.

=item $logger-E<gt>get_facility()

Returns the current facility value.

=item $logger-E<gt>get_severity()

Returns the current severity value.

=item $logger-E<gt>get_format($format)

Returns the current message format.

=back

=head1 UNREACHABLE SERVERS

If the remote syslogd is unreachable, certain methods may throw an exception or
raise a signal:

=over 4

=item * LOG_TCP

If the server is unreachable at connect time, I<< ->new >> will fail with an
exception. If an established connection is closed remotely, I<< ->send >> will
fail with an exception.

=item * LOG_UDP

As UDP is connectionless, I<< ->new >> will not throw an error as no attempt to
connect is made then. However, if the remote server starts or becomes unreachable and
1) the host is alive but 2) not listening on the specified port, and
3) ICMP packets are routable to the client, an exception B<may> be thrown by I<<
->send >>; note that this may happen only on the second call, and subsequently
every other one. This behavior also depends on specific kernel interactions.

=item * LOG_UNIX

With both SOCK_STREAM- and SOCK_DGRAM-based servers, I<< ->new >> will throw an
exception if the socket is missing or not connectable.

With SOCK_DGRAM, I<< ->send >> to a peer that went away will throw. With
SOCK_STREAM, I<< ->send >> to a peer that went away will raise SIGPIPE.

=back

=head1 EXPORTS

Use Log::Syslog::Constants to export priority constants, e.g. LOG_INFO.

=head1 SEE ALSO

L<Log::Syslog::Constants>

L<Sys::Syslog>

=head1 BUGS

LOG_UNIX with SOCK_DGRAM has not been well tested.

=head1 AUTHOR

Adam Thomason, E<lt>athomason@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2011 by Say Media, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
