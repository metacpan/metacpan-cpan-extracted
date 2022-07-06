package File::VirusScan::Engine::Daemon::ClamAV::Clamd;
use strict;
use warnings;
use Carp;

use File::VirusScan::Engine::Daemon;
use vars qw( @ISA );
@ISA = qw( File::VirusScan::Engine::Daemon );

use IO::Socket::UNIX;
use IO::Select;
use Scalar::Util 'blessed';
use Cwd 'abs_path';

use File::VirusScan::Result;

sub new
{
	my ($class, $conf) = @_;

	if(!$conf->{socket_name}) {
		croak "Must supply a 'socket_name' config value for $class";
	}

	if(exists $conf->{zip_fallback}) {
		unless (blessed($conf->{zip_fallback}) && $conf->{zip_fallback}->isa('File::VirusScan::Engine::Daemon')) {
			croak q{The 'zip_fallback' config value must be an object inheriting from File::VirusScan::Engine::Daemon};
		}
	}

	my $self = {
		socket_name   => $conf->{socket_name},
		ping_timeout  => $conf->{ping_timeout} || 5,
		read_timeout  => $conf->{read_timeout} || 60,
		write_timeout => $conf->{write_timeout} || 30,
		zip_fallback  => $conf->{zip_fallback} || undef,
	};

	return bless $self, $class;
}

sub _get_socket
{
	my ($self) = @_;

	my $sock = IO::Socket::UNIX->new(Peer => $self->{socket_name});
	if(!defined $sock) {
		croak "Error: Could not connect to clamd daemon at $self->{socket_name}";
	}

	return $sock;
}

sub scan
{
	my ($self, $path) = @_;

        my $abs = abs_path($path);
        if ($abs && $abs ne $path) {
                $path = $abs;
        }

	my $sock = eval { $self->_get_socket };
	if($@) {
		return File::VirusScan::Result->error($@);
	}

	my $s = IO::Select->new($sock);

	if(!$s->can_write($self->{ping_timeout})) {
		$sock->close;
		return File::VirusScan::result->error("Timeout waiting to write PING to clamd daemon at $self->{socket_name}");
	}

	if(!$sock->print("nIDSESSION\nnPING\n")) {
		$sock->close;
		return File::VirusScan::Result->error('Could not ping clamd');
	}

	if(!$sock->flush) {
		$sock->close;
		return File::VirusScan::Result->error('Could not flush clamd socket');
	}

	if(!$s->can_read($self->{ping_timeout})) {
		$sock->close;
		return File::VirusScan::Result->error("Timeout reading from clamd daemon at $self->{socket_name}");
	}

	my $ping_response;
	if(!$sock->sysread($ping_response, 256)) {
		$sock->close;
		return File::VirusScan::Result->error('Did not get ping response from clamd');
	}

	if(!defined $ping_response || $ping_response ne "1: PONG\n") {
		$sock->close;
		return File::VirusScan::Result->error('Did not get ping response from clamd');
	}

	if(!$s->can_write($self->{write_timeout})) {
		$sock->close;
		return File::VirusScan::result->error("Timeout waiting to write SCAN to clamd daemon at $self->{socket_name}");
	}

	if(!$sock->print("nSCAN $path\n")) {
		$sock->close;
		return File::VirusScan::Result->error("Could not get clamd to scan $path");
	}

	if(!$sock->flush) {
		$sock->close;
		return File::VirusScan::Result->error("Could not get clamd to scan $path");
	}

	if(!$s->can_read($self->{read_timeout})) {
		$sock->close;
		return File::VirusScan::Result->error("Timeout reading from clamd daemon at $self->{socket_name}");
	}

	# Discard our IO::Select object.
	undef $s;

	my $scan_response;

	if(!$sock->sysread($scan_response, 256)) {
		$sock->close;
		return File::VirusScan::Result->error("Did not get response from clamd while scanning $path");
	}

	# End session
	my $rc = $sock->print("nEND\n");
	$sock->close();
	if(!$rc) {
		return File::VirusScan::Result->error("Could not get clamd to scan $path");
	}

	my ($id, $file, $status) = $scan_response =~ m/(\d+):\s+([^:]+):\s+(.*)/;
	if( ! $id ) {
		return File::VirusScan::Result->error("IDSESSION response didn't contain an ID");
	}
	# TODO: what if more than one virus found?
	# TODO: can/should we capture infected filenames?
	if($status =~ m/(.+) FOUND/) {
		return File::VirusScan::Result->virus($1);
	} elsif($scan_response =~ m/(.+) ERROR/) {
		my $err_detail = $1;

		# The clam daemon may not understand certain zip files,
		# and cannot use an external decompression tool.  The
		# standalone 'clamscan' utility can, though.  So, we
		# allow another engine to be configured as a fallback.
		# It's usually File::VirusScan::ClamAV::ClamScan, but
		# doesn't have to be.
		if(        $self->{zip_fallback}
			&& $err_detail =~ /(?:zip module failure|not supported data format)/i)
		{
			return $self->{zip_fallback}->scan($path);
		}
		return File::VirusScan::Result->error("Clamd returned error: $err_detail");
	}

	return File::VirusScan::Result->clean();
}

1;
__END__

=head1 NAME

File::VirusScan::Engine::Daemon::ClamAV::Clamd - File::VirusScan backend for scanning with clamd

=head1 SYNOPSIS

    use File::VirusScan;
    my $s = File::VirusScan->new({
	engines => {
		'-Daemon::ClamAV::Clamd' => {
			socket_name => '/path/to/clamd.ctl',
		},
		...
	},
	...
}

=head1 DESCRIPTION

File::VirusScan backend for scanning using ClamAV's clamd daemon.

File::VirusScan::Engine::Daemon::ClamAV::Clamd inherits from, and follows the
conventions of, File::VirusScan::Engine::Daemon.  See the documentation of
that module for more information.

=head1 CLASS METHODS

=head2 new ( $conf )

Creates a new scanner object.  B<$conf> is a hashref containing:

=over 4

=item socket_name

Required.

This must be a fully-qualified path to the clamd socket.  Currently,
only local clamd connections over a UNIX socket are supported.

=item ping_timeout

Optional.  Defaults to 5 seconds.

Timeout in seconds waiting for a clamd 'PING' command to return.

=item read_timeout

Optional.  Defaults to 60 seconds.

Timeout in seconds for waiting on clamd socket reads.

=item write_timeout

Optional. Defaults to 30 seconds.

Timeout in seconds for waiting for clamd socket to be writeable.

=item zip_fallback

Optional.  Default is undef.

This config option can be a reference to an instance of
L<File::VirusScan::Engine::Daemon> object that will be used as a fallback in the
event that clamd returns a 'zip module failure' error.

=back

=head1 INSTANCE METHODS

=head2 scan ( $pathname )

Scan the path provided using clamd on a the configured local UNIX socket.

Returns an File::VirusScan::Result object.

=head1 DEPENDENCIES

L<IO::Socket::UNIX>, L<IO::Select>, L<Scalar::Util>, L<Cwd>,
L<File::VirusScan::Result>,

=head1 SEE ALSO

L<http://www.clamav.net/>

=head1 AUTHOR

Dianne Skoll (dianne@skoll.ca)

Dave O'Neill (dmo@roaringpenguin.com)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 Roaring Penguin Software, Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License, version 2, or
(at your option) any later version.
