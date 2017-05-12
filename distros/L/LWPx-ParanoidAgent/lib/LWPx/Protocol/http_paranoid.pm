# $Id: http_paranoid.pm 2 2005-06-01 23:12:25Z bradfitz $
#

package LWPx::Protocol::http_paranoid;

use strict;

require LWP::Debug;
require HTTP::Response;
require HTTP::Status;
require Net::HTTP;

use Errno qw(EAGAIN);

use vars qw(@ISA $TOO_LATE $TIME_REMAIN);

require LWP::Protocol;
@ISA = qw(LWP::Protocol);

use vars qw(@ISA @EXTRA_SOCK_OPTS);

my $CRLF = "\015\012";

# lame hack using globals in this package to communicate to sysread in the
# package at bottom, but whatchya gonna do?  Don't want to go modify
# Net::HTTP::* to pass explicit timeouts to all the sysreads.
sub _set_time_remain {
    my $now = time;
    return unless defined $TOO_LATE;
    $TIME_REMAIN = $TOO_LATE - $now;
    $TIME_REMAIN = 0 if $TIME_REMAIN < 0;
}


sub _extra_sock_opts  # to be overridden by subclass
{
    return @EXTRA_SOCK_OPTS;
}

sub _new_socket
{
    my($self, $host, $port, $timeout, $request) = @_;

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

    my @addrs = $self->{ua}->_resolve($host, $request, $timeout);
    unless (@addrs) {
	die "Can't connect to $host:$port (No suitable addresses found)";
    }

    my $sock;
    local($^W) = 0;  # IO::Socket::INET can be noisy

    while (! $sock && @addrs) {
        my $addr = shift @addrs;

        my $conn_timeout = $request->{_timebegin} ?
            (time() - $request->{_timebegin}) :
            $timeout;
        $sock = $self->socket_class->new(PeerAddr => $addr,
                                         PeerHost => $host,
                                         SSL_hostname => $host,
                                         PeerPort => $port,
                                         Proto    => 'tcp',
                                         Timeout  => $conn_timeout,
                                         KeepAlive => !!$conn_cache,
                                         SendTE    => 1,
                                         $self->_extra_sock_opts($addr,$port),
                                         );
    }

    unless ($sock) {
	# IO::Socket::INET leaves additional error messages in $@
	$@ =~ s/^.*?: //;
	die "Can't connect to $host:$port ($@)";
    }

    # perl 5.005's IO::Socket does not have the blocking method.
    eval { $sock->blocking(0); };

    $sock;
}



sub socket_class
{
    my $self = shift;
    (ref($self) || $self) . "::Socket";
}

sub _get_sock_info
{
    my($self, $res, $sock) = @_;
    if (defined(my $peerhost = $sock->peerhost)) {
        $res->header("Client-Peer" => "$peerhost:" . $sock->peerport);
    }
}

sub _fixup_header
{
    my($self, $h, $url, $proxy) = @_;

    # Extract 'Host' header
    my $hhost = $url->authority;
    if ($hhost =~ s/^([^\@]*)\@//) {  # get rid of potential "user:pass@"
	# add authorization header if we need them.  HTTP URLs do
	# not really support specification of user and password, but
	# we allow it.
	if (defined($1) && not $h->header('Authorization')) {
	    require URI::Escape;
	    $h->authorization_basic(map URI::Escape::uri_unescape($_),
				    split(":", $1, 2));
	}
    }
    $h->init_header('Host' => $hhost);

}

sub hlist_remove {
    my($hlist, $k) = @_;
    $k = lc $k;
    for (my $i = @$hlist - 2; $i >= 0; $i -= 2) {
	next unless lc($hlist->[$i]) eq $k;
	splice(@$hlist, $i, 2);
    }
}

sub request
{
    my($self, $request, $proxy, $arg, $size, $timeout) = @_;
    LWP::Debug::trace('()');

    # paranoid:  now $timeout means total time, not just between bytes coming in.
    # avoids attacker servers from tarpitting a service that fetches URLs.
    $TOO_LATE     = undef;
    $TIME_REMAIN  = undef;
    if ($timeout) {
        my $start_time = $request->{_time_begin} || time();
        $TOO_LATE = $start_time + $timeout;
    }

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
    $fullpath = "/$fullpath" unless $fullpath =~ m,^/,;

    # connect to remote sites

    my $socket = $self->_new_socket($host, $port, $timeout, $request);
    
    my @h;
    my $request_headers = $request->headers->clone;
    $self->_fixup_header($request_headers, $url, $proxy);

    $request_headers->scan(sub {
			       my($k, $v) = @_;
			       $k =~ s/^://;
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

    my $req_buf = $socket->format_request($method, $fullpath, @h);
    #print "------\n$req_buf\n------\n";

    # XXX need to watch out for write timeouts
    # FIXME_BRAD: make it non-blocking and select during the write
    {
	my $n = $socket->syswrite($req_buf, length($req_buf));
	die $! unless defined($n);
	die "short write" unless $n == length($req_buf);
    
	#LWP::Debug::conns($req_buf);
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
    
                my $now = time();
                if ($now > $TOO_LATE) {
                    die "Request took too long.";
                }
    
    	    my $sel_timeout = $TOO_LATE - $now;
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
    
                    _set_time_remain();
    
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

    _set_time_remain();

    ## Now we connected to host
    ## Check host started to send any data in return
    my $rbits = '';
    vec($rbits, fileno($socket), 1) = 1;
    my $nfound = select($rbits, undef, undef, $TIME_REMAIN);
    die "Headers not came for $TIME_REMAIN sec" unless $nfound;

    _set_time_remain();

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
        _set_time_remain();
	    $n = $socket->read_entity_body($buf, $size);
	    redo READ if not defined $n and $! == EAGAIN;
	    redo READ if $n == -1;
	    die "Can't read entity body: $!" unless defined $n;
	    die 'read timeout' unless($TIME_REMAIN - 1);
	}
	$complete++ if !$n;
        return \$buf;
    } );
    $drop_connection++ unless $complete;

    _set_time_remain();
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
		LWP::Debug::debug("Keep the http connection to $host:$port");
		$conn_cache->deposit("http", "$host:$port", $socket);
	    }
	}
    }

    $response;
}


#-----------------------------------------------------------
package LWPx::Protocol::http_paranoid::SocketMethods;

sub sysread {
    my $self = shift;
    my $timeout = $LWPx::Protocol::http_paranoid::TIME_REMAIN;

    if (defined $timeout) {
	die "read timeout" unless $self->can_read($timeout);
    }
    else {
	# since we have made the socket non-blocking we
	# use select to wait for some data to arrive
	$self->can_read(undef) || die "Assert";
    }
    sysread($self, $_[0], $_[1], $_[2] || 0);
}

sub can_read {
    my($self, $timeout) = @_;

    $timeout ||= $LWPx::Protocol::http_paranoid::TIME_REMAIN;
    my $fbits = '';
    vec($fbits, fileno($self), 1) = 1;
    my $nfound = select($fbits, undef, undef, $timeout);
    die "select failed: $!" unless defined $nfound;
    return $nfound > 0;
}

sub ping {
    my $self = shift;
    !$self->can_read(0);
}

sub increment_response_count {
    my $self = shift;
    return ++${*$self}{'myhttp_response_count'};
}

#-----------------------------------------------------------
package LWPx::Protocol::http_paranoid::Socket;
use vars qw(@ISA);
@ISA = qw(LWPx::Protocol::http_paranoid::SocketMethods Net::HTTP);

1;
