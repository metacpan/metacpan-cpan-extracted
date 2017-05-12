package File::VirusScan::Engine::Daemon::FPROT::V4;
use strict;
use warnings;
use Carp;

use File::VirusScan::Engine::Daemon;
use vars qw( @ISA );
@ISA = qw( File::VirusScan::Engine::Daemon );

use IO::Socket::INET;
use Cwd 'abs_path';
use HTML::TokeParser;
use File::VirusScan::Result;

sub new
{
	my ($class, $conf) = @_;

	if(!$conf->{host}) {
		croak "Must supply a 'host' config value for $class";
	}

	my $self = {
		host      => $conf->{host},
		base_port => $conf->{base_port} || 10200
	};

	return bless $self, $class;
}

sub scan
{
	my ($self, $path) = @_;

	if(abs_path($path) ne $path) {
		return File::VirusScan::Result->error("Path $path is not absolute");
	}

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

# TODO FIXME
# This is unbelievably ugly code, but as I have no way of testing it
# against an F-PROT daemon, it's been ported nearly verbatim from
# MIMEDefang.  It is in desperate need of cleanup!
sub _scan
{
	my ($self, $item) = @_;

	my $host     = $self->{host};
	my $baseport = $self->{base_port};

	# Default error message when reaching end of function
	my $errmsg = "Could not connect to F-Prot Daemon at $host:$baseport";

	# Try 5 ports in order to find an active scanner; they may
	# change the port when they find and spawn an updated demon
	# executable
	SEARCH_DEMON: foreach my $port ($baseport .. ($baseport + 4)) {

		# TODO: Timeout value?
		# TODO: Why aren't we using a HTTP client instead of
		# rolling our own HTTP?
		my $sock = IO::Socket::INET->new(
			PeerAddr => $host,
			PeerPort => $port
		);

		next if !defined $sock;

		# The arguments (following the '?' sign in the HTTP
		# request) are the same as for the command line F-Prot,
		# the additional -remote-dtd suppresses the unuseful
		# XML DTD prefix
		my @args = qw( -dumb -archive -packed -remote-dtd );
		my $uri = "$item?" . join('%20', @args);
		if(!$sock->print("GET $uri HTTP/1.0\n\n")) {
			my $err = $!;
			$sock->close;
			return File::VirusScan::Result->error("Could not write to socket: $err");
		}

		if(!$sock->flush) {
			my $err = $!;
			$sock->close;
			return File::VirusScan::Result->error("Could not flush socket: $err");
		}

		# Fetch HTTP Header
		## Maybe dropped, if no validation checks are to be made
		while (my $output = $sock->getline) {
			if($output =~ /^\s*$/) {
				last;  # End of headers
				#### Below here: Validating the protocol
				#### If the protocol is not recognized, it's assumed that the
				#### endpoint is not an F-Prot demon, hence,
				#### the next port is probed.
			} elsif($output =~ /^HTTP(.*)/) {
				my $h = $1;
				next SEARCH_DEMON unless $h =~ m!/1\.0\s+200\s!;
			} elsif($output =~ /^Server:\s*(\S*)/) {
				next SEARCH_DEMON if $1 !~ /^fprotd/;
			}
		}

		# Parsing XML results
		my $xml = HTML::TokeParser->new($sock);
		my $t   = $xml->get_tag('fprot-results');
		unless ($t) {  # This is an essential tag --> assume a broken demon
			$errmsg = 'Demon did not return <fprot-results> tag';
			last SEARCH_DEMON;
		}

		if($t->[1]{'version'} ne '1.0') {
			$errmsg = "Incompatible F-Protd results version: " . $t->[1]{'version'};
			last SEARCH_DEMON;
		}

		my $curText;   # temporarily accumulated information
		my $virii = '';  # name(s) of virus(es) found
		my $code;        # overall exit code
		my $msg = '';    # accumulated message of virus scanner
		while ($t = $xml->get_token) {
			my $tag = $t->[1];
			if($t->[0] eq 'S') {  # Start tag
				              # Accumulate the information temporarily
				              # into $curText until the </detected> tag is found
				my $text = $xml->get_trimmed_text;

				# $tag 'filename' of no use in MIMEDefang
				if($tag eq 'name') {
					$virii .= (length $virii ? " " : "") . $text;
					$curText .= "Found the virus: '$text'\n";
				} elsif($tag eq 'accuracy' || $tag eq 'disinfectable' || $tag eq 'message') {
					$curText .= "\t$tag: $text\n";
				} elsif($tag eq 'error') {
					$msg .= "\nError: $text\n";
				} elsif($tag eq 'summary') {
					$code = $t->[2]{'code'} if defined $t->[2]{'code'};
				}
			} elsif($t->[0] eq 'E') {  # End tag
				if($tag eq 'detected') {

					# move the cached information to the
					# accumulated message
					$msg .= "\n$curText" if $curText;
					undef $curText;
				} elsif($tag eq 'fprot-results') {
					last;      # security check
				}
			}
		}
		$sock->close;

## Check the exit code (man f-protd)
## NOTE: These codes are different from the ones of the command line version!
		#  0      Not scanned, unable to handle the object.
		#  1      Not scanned due to an I/O error.
		#  2      Not scanned, as the scanner ran out of memory.
		#  3  X   The object is not of a type the scanner knows. This
		#         may  either mean it was misidentified or that it is
		#         corrupted.
		#  4  X   The object was valid, but encrypted and  could  not
		#         be scanned.
		#  5      Scanning of the object was interrupted.
		#  7  X   The  object was identified as an "innocent" object.
		#  9  X   The object was successfully scanned and nothing was
		#         found.
		#  11     The object is infected.
		#  13     The object was disinfected.
		unless (defined $code) {
			$errmsg = "No summary code found";
			last SEARCH_DEMON;
		}

		# I/O error, unable to handle, out of mem,
		# any filesystem error less than zero,
		# interrupted
		if($code < 3 || $code == 5) {
			#w
			## assume this a temporary failure
			$errmsg = "Scan error #$code: $msg";
			last SEARCH_DEMON;
		}

		if($code > 10) {  # infected; (disinfected: Should never happen!)
			my $virus_name = '';
			if(length $virii) {
				$virus_name = $virii;
			} elsif($msg =~ /^\tmessage:\s+(\S.*)/m) {
				$virus_name = $1;
			} else {

				# no virus name found, log message returned by fprot
				$virus_name = 'unknown-FPROTD-virus';
			}

			return File::VirusScan::Result->virus($virus_name);
		}
###### These codes are left to be handled:
		#  3  X   The object is not of a type the scanner knows. This
		#         may  either mean it was misidentified or that it is
		#         corrupted.
		#  4  X   The object was valid, but encrypted and  could  not
		#         be scanned.
		#  7  X   The  object was identified as an "innocent" object.
		#  9  X   The object was successfully scanned and nothing was

		#	9 is trival; 7 is probably trival
		#	4 & 3 we can't do anything really, because if the attachement
		#	is some unknown archive format, the scanner wouldn't had known
		#	this issue anyway, hence, I consider it "clean"

		return File::VirusScan::Result->clean();
	}  # End SEARCH_DEMON

	# Could not connect to daemon or some error occured during the
	# communication with it
	$errmsg =~ s/\s*\.*\s*\n+\s*/\. /g;
	return File::VirusScan::Result->error($errmsg);
}

1;
__END__

=head1 NAME

File::VirusScan::Engine::Daemon::FPROT::V4 - File::VirusScan backend for scanning with F-PROT daemon, version 4

=head1 SYNOPSIS

    use File::VirusScan;
    my $s = File::VirusScan->new({
	engines => {
		'-Daemon::FPROT::V4' => {
			host      => '127.0.0.1',
			base_port => 10200,
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

Required.

Host name or IP address of F-PROT daemon.  Probably will not work for
anything other than localhost or 127.0.0.1.

=item base_port

Optional.  Defaults to 10200.

Port at which we start looking for an F-PROT daemon.  We will try this
port, and four more above it.

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

Dianne Skoll (dfs@roaringpenguin.com)

Dave O'Neill (dmo@roaringpenguin.com)

Steffen Kaiser

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 Roaring Penguin Software, Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License, version 2, or
(at your option) any later version.
