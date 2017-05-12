# See copyright, etc in below POD section.
######################################################################

package IPC::PidStat::PidServer;
require 5.004;
require Exporter;
@ISA = qw(Exporter);

use IPC::Locker;
use Socket;
use IO::Socket;

use strict;
use vars qw($VERSION $Debug $Hostname);
use Carp;

######################################################################
#### Configuration Section

# Other configurable settings.
$Debug = 0;

$VERSION = '1.496';

$Hostname = IPC::Locker::hostfqdn();

######################################################################
#### Creator

sub new {
    # Establish the server
    @_ >= 1 or croak 'usage: IPC::PidStat::PidServer->new ({options})';
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {
	#Documented
	port=>$IPC::Locker::Default_PidStat_Port,
	@_,};
    bless $self, $class;
    return $self;
}

sub start_server {
    my $self = shift;

    # Open the socket
    print "Listening on $self->{port}\n" if $Debug;
    my $server = IO::Socket::INET->new( Proto     => 'udp',
					LocalPort => $self->{port},
					Reuse     => 1)
	    or die "$0: Error, socket: $!";

    while (1) {
	my $in_msg;
	next unless $server->recv($in_msg, 8192);
	print "Got msg $in_msg\n" if $Debug;
	my ($cmd,@param) = split /\s+/, $in_msg;  # We rely on the newline to terminate the split
	# We ignore unknown parameters for forward compatibility
	# PIDR (\d+) (\S+) ([0-7])	# PID request, format after 1.480
	# PIDR (\d+) (\S+)		# PID request, format after 1.461
	# PIDR (\d+)			# PID request, format before 1.461
	if ($cmd eq 'PIDR') {
	    my $pid = $param[0];
	    my $host = $param[1] || $Hostname;  # Loop the host through, as the machine may have multiple names
	    my $which = $param[2] || 3;
	    $! = undef;
	    my $exists = IPC::PidStat::local_pid_exists($pid);
	    if ($exists) {
		if ($which & 1) {
		    my $out_msg = "EXIS $pid $exists $host";  # PID response
		    print "   Send msg $out_msg\n" if $Debug;
		    $server->send($out_msg);  # or die... But we'll ignore errors
		}
	    } elsif (defined $exists) {  # Known not to exist
		if ($which & 2) {
		    my $out_msg = "EXIS $pid $exists $host";  # PID response
		    print "   Send msg $out_msg\n" if $Debug;
		    $server->send($out_msg);  # or die... But we'll ignore errors
		}
	    } else {  # Perhaps we're not running as root?
		if ($which & 4) {
		    my $out_msg = "UNKN $pid na $host";  # PID response
		    print "   Send msg $out_msg\n" if $Debug;
		    $server->send($out_msg);  # or die... But we'll ignore errors
		}
	    }
	}
    }
}

######################################################################
#### Package return
1;
=pod

=head1 NAME

IPC::PidStat::PidServer - Process ID existence server

=head1 SYNOPSIS

  use IPC::PidStat::PidServer;

  IPC::PidStat::PidServer->new(port=>1234)->start_server;

  # Or more typically via the command line
  pidstatd

=head1 DESCRIPTION

L<IPC::PidStat::PidServer> responds to UDP requests that contain a PID with
a packet indicating the PID and if the PID currently exists.

The Perl IPC::Locker package optionally uses this daemon to break locks
for PIDs that no longer exists.

=over 4

=item new ([parameter=>value ...]);

Creates a server object.

=item start_server ([parameter=>value ...]);

Starts the server.  Does not return.

=back

=head1 PARAMETERS

=over 4

=item port

The port number (INET) or name (UNIX) of the lock server.  Defaults to
'pidstatd' looked up via /etc/services, else 1752.

=back

=head1 DISTRIBUTION

The latest version is available from CPAN and from L<http://www.veripool.org/>.

Copyright 2002-2017 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<IPC::Locker>, L<IPC::PidStat>, L<pidstatd>

=cut

######################################################################
