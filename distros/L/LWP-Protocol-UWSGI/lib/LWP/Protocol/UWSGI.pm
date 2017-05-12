package LWP::Protocol::UWSGI;

use strict;
use utf8;

use version; our $VERSION = qv('v1.1.8');

use HTTP::Response	qw( );
use LWP::Protocol::http qw( );
use Encode;
use URI::Escape::XS	qw();

use base qw/LWP::Protocol::http/;

LWP::Protocol::implementor($_, __PACKAGE__) for qw( uwsgi );

our $CRLF = $LWP::Protocol::http::CRLF;

=head1 NAME

LWP::Protocol::UWSGI - uwsgi support for LWP

=head1 SYNOPSIS

  use LWP::Protocol::UWSGI;
  use LWP::UserAgent;
  $res = $ua->get("uwsgi://www.example.com");

=head1 DESCRIPTION

The LWP::Protocol::UWSGI module provide support for using uwsgi
protocol with LWP. 

This module unbundled with the libwww-perl.

=head1 SEE ALSO

L<LWP::UserAgent>, L<LWP::Protocol>

=head1 COPYRIGHT

Copyright 2015 Nikolas Shulyakovskiy.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

sub request {
	my($self, $request, $proxy, $arg, $size, $timeout) = @_;

	$size ||= 4096;

	# check method
	my $method = $request->method;
	unless ($method =~ /^[A-Za-z0-9_!\#\$%&\'*+\-.^\`|~]+$/) {  # HTTP token
		return HTTP::Response->new( &HTTP::Status::RC_BAD_REQUEST,
		                            'Library does not allow method ' .
		                            "$method for 'uwsgi:' URLs");
	}

	my $url = $request->uri;
	unless($$url =~ m,^uwsgi://([^/?\#:]+)(?:\:(\d+))/,){
		return HTTP::Response->new( &HTTP::Status::RC_BAD_REQUEST,
		                            'Library does not allow this host ' .
					    "$$url for 'uwsgi:' URLs");
	}
	my ($host,$port) = $proxy
		? ($proxy->host,$proxy->port)
		: ($1,$2);
	my $fullpath =
		$method eq 'CONNECT' 
			? $url->host . ":" . $url->port 
			: $proxy 
				? $url->as_string 
				: do {
					my $path = $url->path_query;
					$path = "/$path" if $path !~m{^/};
					$path
				};

	my $socket;
	my $conn_cache = $self->{ua}{conn_cache};
	my $cache_key;
	if ( $conn_cache ) {
		$cache_key = "$host:$port";
		if ( $socket = $conn_cache->withdraw($self->socket_type,$cache_key)) {
			if ($socket->can_read(0)) {
				# if the socket is readable, then either the peer has closed the
				# connection or there are some garbage bytes on it.  In either
				# case we abandon it.
				$socket->close;
				$socket = undef;
			} # else use $socket
		}
	}

	if ( ! $socket ) {
		# connect to remote site w/o reusing established socket
		$socket = $self->_new_socket($host, $port, $timeout );
	}

	$self->_check_sock($request, $socket);

	my %h;
	my $request_headers = $request->headers->clone;
	$self->_fixup_header($request_headers, $url, $proxy);

	$request_headers->scan(sub {
				   my($k, $v) = @_;
				   $k =~ s/^://;
				   $v =~ s/\n/ /g;
				   $h{$k}=$v;
			   });

	my $content_ref = $request->content_ref;
	$content_ref = $$content_ref if ref($$content_ref);
	my $chunked;
	my $has_content;

	if (ref($content_ref) eq 'CODE') {
		my $clen = $request_headers->header('Content-Length');
		$has_content++ if $clen;
		unless (defined $clen) {
			$h{"Transfer-Encoding"} = "chunked";
			$has_content++;
			$chunked++;
		}
	}
	else {
		# Set (or override) Content-Length header
		my $clen = $request_headers->header('Content-Length');
		if (defined($$content_ref) && length($$content_ref)) {
			$has_content = length($$content_ref);
			if (!defined($clen) || $clen ne $has_content) {
				if (defined $clen) {
					warn "Content-Length header value was wrong, fixed";
					delete $h{'Content-Length'};
				}
				$h{'Content-Length'} = $has_content;
			}
		}
		elsif ($clen) {
			warn "Content-Length set when there is no content, fixed";
			delete $h{'Content-Length'};
		}
	}

	my $env = {};
	$env->{QUERY_STRING}   = $fullpath =~ m,^[^?]+\?(.+)$, ? $1 : '';
	$env->{REQUEST_METHOD} = $method;
	$env->{CONTENT_LENGTH} = defined $request_headers->header('Content-Length') ? $request_headers->header('Content-Length') : '';
	$env->{CONTENT_TYPE}   = $method =~ /post/i ? 'application/x-www-form-urlencoded' : '';
	$env->{REQUEST_URI}    = $fullpath;
	$env->{PATH_INFO}      = $url->path;
	$env->{SERVER_PROTOCOL}= 'HTTP/1.1';
	$env->{REMOTE_ADDR}    = $socket->sockhost;
	$env->{REMOTE_PORT}    = $socket->sockport;
	$env->{SERVER_PORT}    = $port;
	$env->{SERVER_NAME}    = $host;

	if ($request->header('X-UWSGI-Nginx-Compatible-Mode')) {
		$env->{PATH_INFO} = Encode::decode('utf8', URI::Escape::XS::uri_unescape(
			$env->{PATH_INFO}
		));
	}
	
	foreach my $k (keys %h) {
		(my $env_k = uc $k) =~ tr/-/_/;
		$env->{"HTTP_$env_k"} = defined $h{$k} ? $h{$k} : '';
	}

	my $data = '';
	foreach my $k (sort keys %$env) {
		die "Undef value found for $k" unless defined $env->{$k};
		$data .= pack 'v/a*v/a*', map { Encode::encode('utf8', $_) } $k, $env->{$k};
	}

	my $req_buf = pack('C1v1C1',
		5, # PSGI_MODIFIER1,
		length($data),
		0, # PSGI_MODIFIER2,
	) . $data;

	if (!$has_content || $has_content > 8*1024) {
		WRITE:
		{
			# Since this just writes out the header block it should almost
			# always succeed to send the whole buffer in a single write call.
			my $n = $socket->syswrite($req_buf, length($req_buf));
			unless (defined $n) {
				redo WRITE if $!{EINTR};
				if ($!{EWOULDBLOCK} || $!{EAGAIN}) {
					select(undef, undef, undef, 0.1);
					redo WRITE;
				}
				die "write failed: $!";
			}
			if ($n) {
				substr($req_buf, 0, $n, "");
			}
			else {
				select(undef, undef, undef, 0.5);
			}
			redo WRITE if length $req_buf;
		}
	}

	my($code, $mess, @junk);
	my $drop_connection;

	if ($has_content) {
	my $eof;
	my $wbuf;
	my $woffset = 0;
	INITIAL_READ:
		if (ref($content_ref) eq 'CODE') {
			my $buf = &$content_ref();
			$buf = "" unless defined($buf);
			$buf = sprintf "%x%s%s%s", length($buf), $CRLF, $buf, $CRLF
				if $chunked;
			substr($buf, 0, 0) = $req_buf if $req_buf;
			$wbuf = \$buf;
		}
		else {
			if ($req_buf) {
				my $buf = $req_buf . $$content_ref;
				$wbuf = \$buf;
			}
			else {
				$wbuf = $content_ref;
			}
			$eof = 1;
		}

		my $fbits = '';
		vec($fbits, fileno($socket), 1) = 1;

	WRITE:
		while ($woffset < length($$wbuf)) {
			my $sel_timeout = $timeout;
			my $time_before;
			$time_before = time if $sel_timeout;

			my $rbits = $fbits;
			my $wbits = $fbits;
			my $sel_timeout_before = $sel_timeout;
			SELECT:
			{
				my $nfound = select($rbits, $wbits, undef, $sel_timeout);
				if ($nfound < 0) {
					if ($!{EINTR} || $!{EWOULDBLOCK} || $!{EAGAIN}) {
						if ($time_before) {
							$sel_timeout = $sel_timeout_before - (time - $time_before);
							$sel_timeout = 0 if $sel_timeout < 0;
						}
						redo SELECT;
					}
					die "select failed: $!";
				}
			}

			if (defined($rbits) && $rbits =~ /[^\0]/) {
				# readable
				my $buf = $socket->_rbuf;
				my $n = $socket->sysread($buf, 1024, length($buf));
				unless (defined $n) {
					die "read failed: $!" unless  $!{EINTR} || $!{EWOULDBLOCK} || $!{EAGAIN};
					# if we get here the rest of the block will do nothing
					# and we will retry the read on the next round
				}
				elsif ($n == 0) {
					# the server closed the connection before we finished
					# writing all the request content.  No need to write any more.
					$drop_connection++;
					last WRITE;
				}
				$socket->_rbuf($buf);
				my @h;
				if (!$code && $buf =~ /\015?\012\015?\012/) {
					# a whole response header is present, so we can read it without blocking
					($code, $mess, @h) = $socket->read_response_headers( laxed => 1, junk_out => \@junk );
					if ($code eq "100") {
						undef($code);
						goto INITIAL_READ;
					}
					else {
						$drop_connection++;
						last WRITE;
						# XXX should perhaps try to abort write in a nice way too
					}
				}
			}
			if (defined($wbits) && $wbits =~ /[^\0]/) {
				my $n = $socket->syswrite($$wbuf, length($$wbuf), $woffset);
				unless (defined $n) {
					die "write failed: $!" unless $!{EINTR} || $!{EWOULDBLOCK} || $!{EAGAIN};
					$n = 0;  # will retry write on the next round
				}
				elsif ($n == 0) {
					die "write failed: no bytes written";
				}
				$woffset += $n;

				if (!$eof && $woffset >= length($$wbuf)) {
					# need to refill buffer from $content_ref code
					my $buf = &$content_ref();
					$buf = "" unless defined($buf);
					$eof++ unless length($buf);
					$buf = sprintf "%x%s%s%s", length($buf), $CRLF, $buf, $CRLF
						if $chunked;
					$wbuf = \$buf;
					$woffset = 0;
				}
			}
		} # WRITE
	}
	
	my @h;
	($code, $mess, @h) = $socket->read_response_headers(laxed => 1, junk_out => \@junk)
		unless $code;
	($code, $mess, @h) = $socket->read_response_headers(laxed => 1, junk_out => \@junk)
		if $code eq "100";

	my $response = HTTP::Response->new($code, $mess);
	my $peer_http_version = $socket->peer_http_version;
	$response->protocol("HTTP/$peer_http_version");
	{
		local $HTTP::Headers::TRANSLATE_UNDERSCORE;
		$response->push_header(@h);
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
	$response->push_header('Client-Response-Num', scalar $socket->increment_response_count);

	my $complete;
	$response = $self->collect($arg, $response, sub {
		my $buf = ""; #prevent use of uninitialized value in SSLeay.xs
		my $n;
		READ:
		{
			$n = $socket->read_entity_body($buf, $size);
			unless (defined $n) {
				redo READ if $!{EINTR} || $!{EWOULDBLOCK} || $!{EAGAIN} || $!{ENOTTY};
				die "read failed: $!";
			}
			redo READ if $n == -1;
		}
		$complete++ if !$n;
		return \$buf;
	});
	$drop_connection++ unless $complete;

	@h = $socket->get_trailers;
	if (@h) {
		local $HTTP::Headers::TRANSLATE_UNDERSCORE;
		$response->push_header(@h);
	}

	# keep-alive support
	unless ($drop_connection) {
		if ($cache_key) {
			my %connection = map { (lc($_) => 1) }
				split(/\s*,\s*/, ($response->header("Connection") || ""));
			if (($peer_http_version eq "1.1" && !$connection{close}) || $connection{"keep-alive"}) {
				$conn_cache->deposit($self->socket_type, $cache_key, $socket);
			}
		}
	}
	$response;
}


package LWP::Protocol::UWSGI::Socket;
use base qw(IO::Socket::INET Net::HTTP);

sub ping {
	my $self = shift;
	!$self->can_read(0);
}

sub increment_response_count {
	my $self = shift;
	return ++${*$self}{'myhttp_response_count'};
}

1;
