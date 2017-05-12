########################################################################
#
# $Id: SocksChain.pm,v 1.7 2009-12-28 15:12:16 gosha Exp $
#
# Copyright (C) Igor V. Okunev gosha<at>prv.mts-nn.ru 2005 - 2009
#
#      All rights reserved. This library is free software;
#      you can redistribute it and/or modify it under the
#               same terms as Perl itself.
#
########################################################################
package LWP::Protocol::http::SocksChain;

use strict;
use vars qw( @ISA $VERSION @EXTRA_SOCK_OPTS );
use LWP::Protocol::http;

@ISA = qw( LWP::Protocol::http );

($VERSION='$Revision: 1.7 $')=~s/^\S+\s+(\S+)\s+.*/$1/;

local $^W = 1;

my $CRLF = "\015\012";

sub _new_socket
{
    my($self, $host, $port, $timeout) = @_;
    my $conn_cache = $self->{ua}{conn_cache};
    if ($conn_cache) {
	if (my $sock = $conn_cache->withdraw("http", "$host:$port")) {
	    return $sock if $sock && !$sock->can_read(0);
	    # if the socket is readable, then either the peer has closed the
	    # connection or there are some garbage bytes on it.  In either
	    # case we abandon it.
	    $sock->close;
	}
    }

	local($^W) = 0;

	my $sock = $self->socket_class->new(
			PeerHost	=> $host,
			PeerPort	=> $port,
			TimeOut		=> $timeout,
			KeepAlive => !!$conn_cache,
			SendTE    => 1,
			$self->_extra_sock_opts($host, $port),
	);

	unless ($sock) {
	# IO::Socket leaves additional error messages in $@
	$@ =~ s/^.*?: //;
	die "Can't connect to $host:$port ($@)";
    }

    # perl 5.005's IO::Socket does not have the blocking method.
    eval { $sock->blocking(0); };

    return $sock;
}

sub _extra_sock_opts  # to be overridden by subclass
{
	return @EXTRA_SOCK_OPTS;
}

sub request
{
    my($self, $request, undef, $arg, $size, $timeout) = @_;

    $size ||= 4096;

    # check method
    my $method = $request->method;
    unless ($method =~ /^[A-Za-z0-9_!\#\$%&\'*+\-.^\`|~]+$/) {  # HTTP token
	return new HTTP::Response &HTTP::Status::RC_BAD_REQUEST,
				  'Library does not allow method ' .
				  "$method for 'http:' URLs";
    }

    my $url = $request->url;
    my($host, $port, $fullpath);

	$host = $url->host;
	$port = $url->port;
	$fullpath = $url->path_query;
	$fullpath = "/" unless length $fullpath;

    # connect to remote site
    my $socket = $self->_new_socket( $host, $port, $timeout );
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
    }
    else {
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
	}
	elsif ($clen) {
	    warn "Content-Length set when there is not content, fixed";
	    hlist_remove(\@h, 'Content-Length');
	}
    }

    my $req_buf = $socket->format_request($method, $fullpath, @h) || die $!;

#	print STDERR "------\n$req_buf\n------\n";

    # XXX need to watch out for write timeouts
    {
	my $n = $socket->syswrite($req_buf, length($req_buf));
	die $! unless defined($n);
	die "short write" unless $n == length($req_buf);
    }

    my($code, $mess, @junk);
    my $drop_connection;

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
	    $buf = sprintf "%x%s%s%s", length($buf), $CRLF, $buf, $CRLF
		if $chunked;
	    $wbuf = \$buf;
	}
	else {
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
		    }
		    else {
			$drop_connection++;
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
		    $buf = sprintf "%x%s%s%s", length($buf), $CRLF, $buf, $CRLF
			if $chunked;
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
    $drop_connection++ unless $complete;

    @h = $socket->get_trailers;
    while (@h) {
	my($k, $v) = splice(@h, 0, 2);
	$response->push_header($k, $v);
    }

    # keep-alive support
    unless ($drop_connection) {
	if (my $conn_cache = $self->{ua}{conn_cache}) {
	    my %connection = map { (lc($_) => 1) }
		             split(/\s*,\s*/, ($response->header("Connection") || ""));
	    if (($peer_http_version eq "1.1" && !$connection{close}) ||
		$connection{"keep-alive"})
	    {
		$conn_cache->deposit("http", "$host:$port", $socket);
	    }
	}
    }

    $response;
}

#-----------------------------------------------------------
package LWP::Protocol::http::SocksChain::Socket;
use Net::SC;
use vars qw(@ISA);
@ISA = qw(	LWP::Protocol::http::SocketMethods 
			Net::HTTP
		);

sub new {
	my ( $self, %cfg ) = @_;
	
	my $host = $cfg{ PeerHost };
	my $port = $cfg{ PeerPort };
	
	my $sc = Net::SC->new( %cfg ) || die $!;
	
	unless ( ( my $rc = $sc->connect( $host, $port ) ) == SOCKS_OKAY ) {
		die socks_error($rc) . "\n";
	}

	my $obj = bless $sc->sh, $self;
	
	$obj->http_configure( \%cfg );
	
	return $obj;
}

sub http_connect {
	return shift;
}

1;

__END__

=head1 NAME

LWP::Protocol::http::SocksChain - Speak HTTP through Net::SC

=head1 SYNOPSIS

 use LWP::UserAgent;
 use LWP::Protocol::http::SocksChain;
 LWP::Protocol::implementor( http => 'LWP::Protocol::http::SocksChain' );

 @LWP::Protocol::http::SocksChain::EXTRA_SOCK_OPTS = ( Chain_Len    => 1,
                                                       Debug        => 0,
                                                       Random_Chain => 1,
                                                       Auto_Save    => 1,
                                                       Restore_Type => 1 );

 my $ua = LWP::UserAgent->new();

 my $req = HTTP::Request->new(
              GET => 'http://home.sinn.ru/~gosha/perl-scripts/');

 my $res = $ua->request($req) || die $!;

 if ($res->is_success) {
  ...
 } else {
  ...
 }


 or


 use LWP::UserAgent;
 use LWP::Protocol::http::SocksChain;
 LWP::Protocol::implementor( http => 'LWP::Protocol::http::SocksChain' );

 @LWP::Protocol::http::SocksChain::EXTRA_SOCK_OPTS = ( Chain_Len    => 1,
                                                       Debug        => 0,
                                                       Random_Chain => 1,
                                                       Chain_File_Data => [
                                                          '2x0.41.23.164:1080:::4:383 b/s Argentina',
                                                          '24.2x2.88.160:1080:::4:1155 b/s Argentina',
                                                       ],
                                                       Auto_Save    => 0,
                                                       Restore_Type => 0 );

 my $ua = LWP::UserAgent->new();

 my $req = HTTP::Request->new(
              GET => 'http://home.sinn.ru/~gosha/perl-scripts/');

 my $res = $ua->request($req) || die $!;

 if ($res->is_success) {
  ...
 } else {
  ...
 }

=head1 DESCRIPTION

LWP::Protocol::http::SocksChain enables you to speak HTTP through SocksChain ( Net::SC ).
To use it you need to overwrite the implementor class of the LWP 'http' scheme.

The interface of LWP::Protocol::http::SocksChain is similar to
LWP::Protocol::http. To enable the old HTTP/1.0 protocol driver
instead of the new HTTP/1.1 driver use LWP::Protocol::http::SocksChain10.

=head1 SEE ALSO

LWP, LWP::Protocol, Net::SC


=head1 AUTHOR

 Igor V. Okunev  mailto:igor<at>prv.mts-nn.ru
                 http://www.mts-nn.ru/~gosha
                 icq:106183300


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 - 2006  by Igor V. Okunev

All rights reserved. This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

