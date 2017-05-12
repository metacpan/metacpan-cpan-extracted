package LWP::Protocol::http::SocketUnixAlt;

use 5.010001;
use strict;
use warnings;
use vars qw( @ISA $VERSION );
use IO::Socket;
use LWP::Protocol::http;

@ISA = qw( LWP::Protocol::http );

our $VERSION = '0.0204'; # VERSION

sub _new_socket {
	my ($self, $path, $timeout) = @_;

	local($^W) = 0;
	my $sock = $self->socket_class->new(
			Peer	=> $path,
			Type	=> SOCK_STREAM,
			Timeout	=> $timeout,
			Host    => 'localhost',
	);

	unless($sock) {
		$@ =~ s/^.*?: //;
		die "Can't open socket $path\: $@";
	}

	eval { $sock->blocking(0); };

	$sock;
}

sub request {
    my($self, $request, undef, $arg, $size, $timeout) = @_;
    #LWP::Debug::trace('()');

    $size ||= 4096;

    # check method
    my $method = $request->method;
    unless ($method =~ /^[A-Za-z0-9_!\#\$%&\'*+\-.^\`|~]+$/) {  # HTTP token
		return new HTTP::Response &HTTP::Status::RC_BAD_REQUEST,
				  'Library does not allow method ' .
				  "$method for 'http:' URLs";
    }

    my $url = $request->url;
	my $path = $url->path_query;
	my $fullpath;
	if ($path =~ s!/(/.+)!!) {
		$fullpath = $1;
	} else {
		$fullpath = "/";
	}

    # connect to remote site
    my $socket = $self->_new_socket($path, $timeout);
    $self->_check_sock($request, $socket);

    my @h;
    my $request_headers = $request->headers->clone;
    $self->_fixup_header($request_headers, $url);

    $request_headers->scan(sub {
			       my($k, $v) = @_;
			       $v =~ s/\n/ /g;
			       push(@h, $k, $v);
			   });

    my $content_ref = $request->content_ref;
    $content_ref = $$content_ref if ref($$content_ref);
    my $chunked;
    my $has_content;

    if (ref($content_ref) eq 'CODE') {
		my $clen = $request_headers->header('Content-Length');
		$has_content++ if $clen;
		unless (defined $clen) {
			push(@h, "Transfer-Encoding" => "chunked");
			$has_content++;
			$chunked++;
		}
    } else {
		# Set (or override) Content-Length header
		my $clen = $request_headers->header('Content-Length');
		if (defined($$content_ref) && length($$content_ref)) {
			$has_content++;
			if (!defined($clen) || $clen ne length($$content_ref)) {
				if (defined $clen) {
					warn "Content-Length header value was wrong, fixed";
					hlist_remove(\@h, 'Content-Length');
				}
				push(@h, 'Content-Length' => length($$content_ref));
			}
		} elsif ($clen) {
			warn "Content-Length set when there is not content, fixed";
			hlist_remove(\@h, 'Content-Length');
		}
    }

    my $req_buf = $socket->format_request($method, $fullpath, @h);
    #print "------\n$req_buf\n------\n";

    # XXX need to watch out for write timeouts
    {
		my $n = $socket->syswrite($req_buf, length($req_buf));
		die $! unless defined($n);
		die "short write" unless $n == length($req_buf);
		#LWP::Debug::conns($req_buf);
    }

    my($code, $mess, @junk);

    if ($has_content) {
		my $write_wait = 0;
		$write_wait = 2
			if ($request_headers->header("Expect") || "") =~ /100-continue/;

		my $eof;
		my $wbuf;
		my $woffset = 0;
		if (ref($content_ref) eq 'CODE') {
			my $buf = &$content_ref();
			$buf = "" unless defined($buf);
			$buf = sprintf "%x%s%s%s", length($buf), $LWP::Protocol::http::CRLF,
				$buf, $LWP::Protocol::http::CRLF if $chunked;
			$wbuf = \$buf;
		} else {
			$wbuf = $content_ref;
			$eof = 1;
		}

		my $fbits = '';
		vec($fbits, fileno($socket), 1) = 1;

		while ($woffset < length($$wbuf)) {

			my $time_before;
			my $sel_timeout = $timeout;
			if ($write_wait) {
				$time_before = time;
				$sel_timeout = $write_wait if $write_wait < $sel_timeout;
			}

			my $rbits = $fbits;
			my $wbits = $write_wait ? undef : $fbits;
			my $nfound = select($rbits, $wbits, undef, $sel_timeout);
			unless (defined $nfound) {
				die "select failed: $!";
			}

			if ($write_wait) {
				$write_wait -= time - $time_before;
				$write_wait = 0 if $write_wait < 0;
			}

			if (defined($rbits) && $rbits =~ /[^\0]/) {
				# readable
				my $buf = $socket->_rbuf;
				my $n = $socket->sysread($buf, 1024, length($buf));
				unless ($n) {
					die "EOF";
				}
				$socket->_rbuf($buf);
				if ($buf =~ /\015?\012\015?\012/) {
					# a whole response present
					($code, $mess, @h) = $socket->read_response_headers(laxed => 1,
											junk_out => \@junk,
											   );
					if ($code eq "100") {
						$write_wait = 0;
						undef($code);
					} else {
						last;
						# XXX should perhaps try to abort write in a nice way too
					}
				}
			}
			if (defined($wbits) && $wbits =~ /[^\0]/) {
				my $n = $socket->syswrite($$wbuf, length($$wbuf), $woffset);
				unless ($n) {
					die "syswrite: $!" unless defined $n;
					die "syswrite: no bytes written";
				}
				$woffset += $n;

				if (!$eof && $woffset >= length($$wbuf)) {
					# need to refill buffer from $content_ref code
					my $buf = &$content_ref();
					$buf = "" unless defined($buf);
					$eof++ unless length($buf);
					$buf = sprintf "%x%s%s%s", length($buf), $LWP::Protocol::http::CRLF,
						$buf, $LWP::Protocol::http::CRLF if $chunked;
					$wbuf = \$buf;
					$woffset = 0;
				}
			}
		}
    }

    ($code, $mess, @h) = $socket->read_response_headers(laxed => 1, junk_out => \@junk)
	unless $code;
    ($code, $mess, @h) = $socket->read_response_headers(laxed => 1, junk_out => \@junk)
	if $code eq "100";

    my $response = HTTP::Response->new($code, $mess);
    my $peer_http_version = $socket->peer_http_version;
    $response->protocol("HTTP/$peer_http_version");
    while (@h) {
		my($k, $v) = splice(@h, 0, 2);
		$response->push_header($k, $v);
    }
    $response->push_header("Client-Junk" => \@junk) if @junk;

    $response->request($request);
    $self->_get_sock_info($response, $socket);

    if ($method eq "CONNECT") {
		$response->{client_socket} = $socket;  # so it can be picked up
		return $response;
    }

    if (my @te = $response->remove_header('Transfer-Encoding')) {
		$response->push_header('Client-Transfer-Encoding', \@te);
    }
    $response->push_header('Client-Response-Num', $socket->increment_response_count);

    my $complete;
    $response = $self->collect($arg, $response, sub {
		my $buf = ""; #prevent use of uninitialized value in SSLeay.xs
		my $n;
		READ:
		{
			$n = $socket->read_entity_body($buf, $size);
			die "Can't read entity body: $!" unless defined $n;
			redo READ if $n == -1;
		}
		$complete++ if !$n;
			return \$buf;
    } );

    @h = $socket->get_trailers;
    while (@h) {
		my($k, $v) = splice(@h, 0, 2);
		$response->push_header($k, $v);
    }

    $response;
}

package LWP::Protocol::http::SocketUnixAlt::Socket;

use strict;
use warnings;
use vars qw( @ISA );

@ISA =qw(	LWP::Protocol::http::SocketMethods
			Net::HTTP::Methods
			IO::Socket::UNIX
		);

sub configure {
	my ($self, $cnf) = @_;
	$self->http_configure($cnf);
}

sub http_connect {
	my ($self, $cnf) = @_;
	$self->SUPER::configure($cnf);
}

# Just to avoid some errors. We don't really need this.
sub peerport { }
sub peerhost { }

1;
# ABSTRACT: Speak HTTP through Unix sockets

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::Protocol::http::SocketUnixAlt - Speak HTTP through Unix sockets

=head1 VERSION

version 0.0204

=head1 SYNOPSIS

  use LWP::Protocol::http::SocketUnixAlt;
  LWP::Protocol::implementor( http => 'LWP::Protocol::http::SocketUnixAlt' );
  ...

=head1 DESCRIPTION

LWP::Protocol::http::UnixSocketAlt is a fork of Florian Ragwitz's
L<LWP::Protocol::http::SocketUnix> 0.02. It fixes a few issues including:

=over 4

=item * remedy 'No Host options provided' error

As suggested in https://rt.cpan.org/Public/Bug/Display.html?id=65670

=item * allow specifying URI path

Currently using "//" as separator, e.g.: "http:path/to/unix.socket//uri/path"

=back

=head1 SEE ALSO

L<LWP>, L<LWP::Protocol>

L<HTTP::Daemon::UNIX>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/LWP-Protocol-http-SocketUnixAlt>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-LWP-Protocol-http-SocketUnixAlt>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=LWP-Protocol-http-SocketUnixAlt>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
