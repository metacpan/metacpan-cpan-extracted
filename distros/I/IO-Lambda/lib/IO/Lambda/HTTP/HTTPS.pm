# $Id: HTTPS.pm,v 1.14 2012/03/13 03:23:24 dk Exp $
package IO::Lambda::HTTP::HTTPS;

use strict;
use warnings;
use Socket;
use IO::Socket::SSL;
use IO::Lambda qw(:lambda :stream :dev :constants);
use Errno qw(EWOULDBLOCK EAGAIN);

our $DEBUG = $IO::Lambda::DEBUG{https};

# check for SSL error condition, wait for read or write if necessary
# return ioresult
sub https_wrapper
{
	my ($sock, $deadline) = @_;
	tail {
		my ( $bytes, $error) = @_;
		warn 
			"SSL on fh(", fileno($sock), ") = ",
			(defined($bytes) ? "$bytes bytes" : "error $error"),
			"\n" if $DEBUG;
		return $bytes if defined $bytes;
		return undef, $error if $error eq 'timeout';

		if ( $error == SSL_WANT_READ) {
			warn "SSL_WANT_READ on fh(", fileno($sock), ")\n" if $DEBUG;
			my @ctx = context;
			context $sock, $deadline;
			readable { 
				return 'timeout' unless shift;
				context @ctx;
				https_wrapper($sock, $deadline)
			}
		} elsif ( $error == SSL_WANT_WRITE) {
			warn "SSL_WANT_WRITE on fh(", fileno($sock), ")\n" if $DEBUG;
			my @ctx = context;
			context $sock, $deadline;
			writable { 
				return 'timeout' unless shift;
				context @ctx;
				https_wrapper($sock, $deadline)
			}
		} else {
			warn 
				"SSL retry on fh(", fileno($sock), ") = ",
				(defined($bytes) ? "$bytes bytes" : "error $error"),
				"\n" if $DEBUG;
			return $bytes, $error;
		}
	}
}

sub https_connect
{
	my ($sock, $deadline) = @_;
	IO::Socket::SSL-> start_SSL( $sock, SSL_startHandshake => 0 );

	lambda {
		# emulate sysreader/syswriter to be able to 
		# reuse https_wrapper
		context lambda { $sock-> connect_SSL ? 1 : (undef, $SSL_ERROR) };
		https_wrapper( $sock, $deadline );
	}
}

sub https_syscall
{
	my ( $read, $fh, $buf, $length, $offset) = @_;
	$$buf = '' unless defined $$buf;
	local $SIG{PIPE} = 'IGNORE';
	my $n = $read ? 
		sysread( $fh, $$buf, $length, $offset) : 
		syswrite( $fh, $$buf, $length, $offset);
	unless ( defined $n ) {
		my $err = $!;
		warn "fh(", fileno($fh), ") ", ( $read ? 'read' : 'write'), " error $err\n" if $DEBUG;
		return undef, $err;
	}
	if ( $DEBUG ) {
		warn "fh(", fileno($fh), ") ", ( $read ? 'read' : 'wrote'), "$n bytes\n";
		warn substr( $$buf, length($$buf) - $n), "\n" if $DEBUG > 1 and $n > 0;
	}
	return $n;
}

sub https_syscall_watcher
{
	my $read = shift;
	lambda {
		my ( $fh, $buf, $length, $offset, $deadline) = @_;

		($deadline, $offset) = ($offset, length($$buf) || 0) if $read;

		my ( $n, $err ) = https_syscall( $read, $fh, $buf, $length, $offset );
		return ($n, $err) if defined($n) || ($err != EAGAIN && $err != EWOULDBLOCK);

		this-> watch_io( $read ? IO_READ : IO_WRITE, $fh, $deadline, _subname https_syscall_watcher => sub {
			return undef, 'timeout' unless $_[1];
			my ( $n, $err ) = https_syscall( $read, $fh, $buf, $length, $offset );
			return $n if defined $n;
			$err = $SSL_ERROR if $err == EWOULDBLOCK || $err == EAGAIN;
			return undef, $err;
		});
	};
}

sub https_writer
{
	my $cached = shift;
	my $writer = https_syscall_watcher(0);

	lambda {
		my ( $sock, $req, $length, $offset, $deadline) = @_;
		if ( $cached ) {
			context $writer, $sock, $req, $length, $offset, $deadline;
			return https_wrapper($sock, $deadline);
		}
		context https_connect($sock, $deadline);
	tail {
		my ( $bytes, $error) = @_;
		return @_ if defined $error;

		context $writer, $sock, $req, $length, $offset, $deadline;
		https_wrapper($sock, $deadline);
	}}
}

sub https_reader
{
	my $reader = https_syscall_watcher(1);
	lambda {
		my ( $sock, $buf, $length, $deadline) = @_;
		context $reader, $sock, $buf, $length, $deadline;
		https_wrapper($sock, $deadline);
	}
}


1;

__DATA__

=pod

=head1 NAME

IO::Lambda::HTTP::HTTPS - https requests lambda style

=head1 DESCRIPTION

The module is used internally by L<IO::Lambda::HTTP>, and is a separate module
for the sake of installations that contain C<IO::Socket::SSL> and
C<Net::SSLeay> prerequisite modules.  The module is not to be used directly.

=head1 SEE ALSO

L<IO::Lambda::HTTP>

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut
