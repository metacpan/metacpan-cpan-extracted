package File::VirusScan::Engine::Daemon::FPROT::V6;
use strict;
use warnings;
use Carp;

use File::VirusScan::Engine::Daemon;
use vars qw( @ISA );
@ISA = qw( File::VirusScan::Engine::Daemon );

use IO::Socket::INET;
use Cwd 'abs_path';
use File::VirusScan::Result;

sub new
{
	my ($class, $conf) = @_;

	if(!$conf->{host}) {
		croak "Must supply a 'host' config value for $class";
	}

	my $port;
	if($conf->{host}) {
		if($conf->{host} =~ s/:(\d+)\Z//) {
			$port = $1;
		}
	}
	my $self = {
		host            => $conf->{host}            || 127.0.0.1,
		port            => $conf->{port}            || $port || 10200,
		connect_timeout => $conf->{connect_timeout} || 10,
		read_timeout    => $conf->{read_timeout}    || 60,
		options         => $conf->{options}         || [

			# Instructs the Daemon Scanner which scanlevel to use:
			# 0 => Disable regular scanning (only heuristics).
			# 1 => Skip suspicious data files. Not recommended if filename is unavailable.
			# 2 => (Default) Unknown and/or wrong extensions will be emulated.
			# 3 => Unknown binaries emulated.
			# 4 => For scanning virus collections, no limits for emulation
			'--scanlevel=2',

			# archive depth
			'--archive=2',

			# How aggressive heuristic should be used, 0..4
			# the higher the more  heuristic tests are done which increases
			# both detection rates AND risk of false positives.
			'--heurlevel=2',

			# to flag adware
			'--adware',

			# to flag potentially unwanted applications
			'--applications',
		],
	};

	return bless $self, $class;
}

sub scan
{
	my ($self, $path) = @_;

	if(abs_path($path) ne $path) {
		return File::VirusScan::Result->error("Path $path is not absolute");
	}

	# The F-Prot demon cannot scan directories, but files only
	# hence, we recurse any directories manually
	my @files = eval { $self->list_files($path) };
	if($@) {
		return File::VirusScan::Result->error($@);
	}

	foreach my $file_path (@files) {
		my $result = $self->_scan($file_path);

		if(!$result->is_clean()) {
			return $result;
		}
	}

}

# Scans a single path.
sub _scan
{
	my ($self, $path) = @_;

	my $sock = eval { $self->_get_socket };
	if($@) {
		return File::VirusScan::Result->error($@);
	}

	# Stringify our options
	my $options = join(' ', $self->{options});

	# SCAN options FILE fnam\n	(local daemon)
	# -or- SCAN options STREAM fnam SIZE length\n	(remote daemon)
	#   length bytes of data
	# assume local daemon ==> implement FILE variant only
	#		, supports spaces in fnam
	if(!$sock->print("SCAN $options FILE $path\n")) {
		my $err = $!;
		$sock->close;
		return File::VirusScan::Result->error("Could not write to socket: $err");
	}

	if(!$sock->flush) {
		my $err = $!;
		$sock->close;
		return File::VirusScan::Result->error("Could not flush socket: $err");
	}

	my $s = IO::Select->new($sock);
	if(!$s->can_read($self->{read_timeout})) {
		$sock->close;
		return File::VirusScan::Result->error("Timeout reading from fprot daemon");
	}

	my $resp = $sock->getline;
	if(!$resp) {
		$sock->close;
		return File::VirusScan::Result->error("Did not get response from fprot while scanning $path");
	}

	my ($code, $desc, $name);
	unless (($code, $desc, $name) = $resp =~ /\A(\d+)\s<(.*?)>\s(.*)\Z/) {
		return File::VirusScan::Result->error("Failed to parse response from fprotd: $path");
	}

	# Clean up $desc
	$desc =~ s/\A(?:contains infected objects|infected):\s//i;

	# Our output should contain:
	# 1) A code.  The code is a bitmask of:
	# bit num Meaning
	#  0   1  At least one virus-infected object was found (and remains).
	#  1   2  At least one suspicious (heuristic match) object was found (and remains).
	#  2   4  Interrupted by user. (SIGINT, SIGBREAK).
	#  3   8  Scan restriction caused scan to skip files (maxdepth directories, maxdepth archives, exclusion list, etc).
	#  4  16  Platform error (out of memory, real I/O errors, insufficient file permission etc.).
	#  5  32  Internal engine error (whatever the engine fails at)
	#  6  64  At least one object was not scanned (encrypted file, unsupported/unknown compression method, corrupted or invalid file).
	#  7 128  At least one object was disinfected (clean now) (treat same as virus for File::VirusScan)
	#
	# 2) The description, including virus name
	#
	# 3) The item name, incl. member of archive etc.  We ignore
	# this for now.

	if($code & (1 | 128)) {
		my $virus_name = $desc;
		$virus_name ||= 'unknown-FPROTD-virus';
		return File::VirusScan::Result->virus($virus_name);
	} elsif($code & 2) {
		my $virus_name = $desc;
		$virus_name ||= 'unknown-FPROTD-virus';
		return File::VirusScan::Result->virus($virus_name);
	} elsif($code & 4) {
		return File::VirusScan::Result->error('FPROTD scanning interrupted by user');
	} elsif($code & 16) {
		return File::VirusScan::Result->error('FPROTD platform error');
	} elsif($code & 32) {
		return File::VirusScan::Result->error('FPROTD internal engine error');
	}

	return File::VirusScan::Result->clean();
}

# Returns preconfigured socket, or opens a new connection.
sub _get_socket
{
	my ($self) = @_;

	if(!$self->{sock}) {
		$self->{sock} = IO::Socket::INET->new(
			PeerAddr => $self->{host},
			PeerPort => $self->{port},
			Timeout  => $self->{connect_timeout},
		);
	}

	return $self->{sock};
}

1;
__END__

=head1 NAME

File::VirusScan::Engine::Daemon::FPROT::V6 - File::VirusScan backend for scanning with F-PROT daemon, version 4

=head1 SYNOPSIS

    use File::VirusScan;
    my $s = File::VirusScan->new({
	engines => {
		'-Daemon::FPROT::V6' => {
			host      => '127.0.0.1',
			port      => 10200,
		},
		...
	},
	...
}

=head1 DESCRIPTION

File::VirusScan backend for scanning using F-PROT's scanner daemon

This class inherits from, and follows the conventions of,
File::VirusScan::Engine::Daemon.  See the documentation of that module for
more information.

=head1 CLASS METHODS

=head2 new ( $conf )

Creates a new scanner object.  B<$conf> is a hashref containing:

=over 4

=item host

Optional.  Defaults to 127.0.0.1

Host name or IP address of F-PROT daemon.  Will not work for anything
other than localhost or 127.0.0.1, as we perform local path scanning
rather than transmission of the file over the socket.

=item port

Optional.  Defaults to 10200.

=item connect_timeout

In seconds.  Optional.  Defaults to 10.

Timeout on connection to the F-PROT socket.

=item read_timeout

In seconds.  Optional.  Defaults to 60.

Timeout for reading response from F-PROT.

=item options

Reference to array of commandline-style options to be given to SCAN
command.

Optional.  Defaults to:

    [
        '--scanlevel=2',
        '--archive=2',
        '--heurlevel=2',
        '--adware',
        '--applications',
    ]

=back

=head1 INSTANCE METHODS

=head2 scan ( $pathname )

Scan the path provided using the daemon on a the configured host.

Returns an File::VirusScan::Result object.

=head1 DEPENDENCIES

L<IO::Socket::INET>, L<Cwd>, L<File::VirusScan::Result>

=head1 SEE ALSO

L<http://www.f-prot.com/>

=head1 AUTHOR

Dave O'Neill (dmo@roaringpenguin.com)

Steffen Kaiser

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 Roaring Penguin Software, Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License, version 2, or
(at your option) any later version.
