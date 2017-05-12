package File::VirusScan::Engine::Daemon::Sophos::Sophie;
use strict;
use warnings;
use Carp;

use File::VirusScan::Engine::Daemon;
use vars qw( @ISA );
@ISA = qw( File::VirusScan::Engine::Daemon );

use IO::Socket::UNIX;
use Cwd 'abs_path';

use File::VirusScan::Result;

sub new
{
	my ($class, $conf) = @_;

	if(!$conf->{socket_name}) {
		croak "Must supply a 'socket_name' config value for $class";
	}

	my $self = { socket_name => $conf->{socket_name}, };

	return bless $self, $class;
}

sub _get_socket
{
	my ($self) = @_;

	my $sock = IO::Socket::UNIX->new(Peer => $self->{socket_name});
	if(!defined $sock) {
		croak "Error: Could not connect to sophie daemon at $self->{socket_name}";
	}

	return $sock;
}

sub scan
{
	my ($self, $path) = @_;

	if(abs_path($path) ne $path) {
		return File::VirusScan::Result->error("Path $path is not absolute");
	}

	my $sock = eval { $self->_get_socket };
	if($@) {
		return File::VirusScan::Result->error($@);
	}

	if(!$sock->print("$path\n")) {
		$sock->close;
		return File::VirusScan::Result->error("Could not get sophie to scan $path");
	}

	if(!$sock->flush) {
		$sock->close;
		return File::VirusScan::Result->error("Could not get sophie to scan $path");
	}

	my $scan_response;
	my $rc = $sock->sysread($scan_response, 256);
	$sock->close();

	if(!$rc) {
		return File::VirusScan::Result->error("Did not get response from sophie while scanning $path");
	}

	if($scan_response =~ m/^0/) {
		return File::VirusScan::Result->clean();
	}

	if($scan_response =~ m/^1/) {
		my ($virus_name) = $scan_response =~ /^1:(.*)$/;
		$virus_name ||= 'Unknown-sophie-virus';
		return File::VirusScan::Result->virus($virus_name);
	}

	if($scan_response =~ m/^-1:(.*)$/) {
		my $error_message = $1;
		$error_message ||= 'unknown error';
		return File::VirusScan::Result->error($error_message);
	}

	return File::VirusScan::Result->error('Unknown response from sophie');
}

1;
__END__

=head1 NAME

File::VirusScan::Engine::Daemon::Sophos::Sophie - File::VirusScan backend for scanning with sophie

=head1 SYNOPSIS

    use File::VirusScan;
    my $s = File::VirusScan->new({
	engines => {
		'-Daemon::Sophos::Sophie' => {
			socket_name => '/path/to/sophie.ctl',
		},
		...
	},
	...
}

=head1 DESCRIPTION

File::VirusScan backend for scanning using Sophos's sophie daemon.

File::VirusScan::Engine::Daemon::Sophos::Sophie inherits from, and follows the
conventions of, File::VirusScan::Engine::Daemon.  See the documentation of
that module for more information.

=head1 CLASS METHODS

=head2 new ( $conf )

Creates a new scanner object.  B<$conf> is a hashref containing:

=over 4

=item socket_name

Required.

This must be a fully-qualified path to the sophie socket.  Currently,
only local sophie connections over a UNIX socket are supported.

=back

=head1 INSTANCE METHODS

=head2 scan ( $pathname )

Scan the path provided using sophie on a the configured local UNIX socket.

Returns an File::VirusScan::Result object.

=head1 DEPENDENCIES

L<IO::Socket::UNIX>, L<Cwd>, L<File::VirusScan::Result>,

=head1 SEE ALSO

L<http://www.clanfield.info/sophie/>
L<http://www.sophos.com>

=head1 AUTHOR

Dianne Skoll (dfs@roaringpenguin.com)

Dave O'Neill (dmo@roaringpenguin.com)

Jason Englander

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 Roaring Penguin Software, Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License, version 2, or
(at your option) any later version.
