package LWPx::TimedHTTP;

use strict;
use Carp;

require LWP::Debug;
require HTTP::Response;
require HTTP::Status;
require Net::HTTP;
use Time::HiRes qw(gettimeofday tv_interval);

use vars qw(@ISA @EXTRA_SOCK_OPTS $VERSION);

$VERSION = "1.8";

=pod

=head1 NAME

LWPx::TimedHTTP - time the different stages of an HTTP request 

=head1 SYNOPSIS

    # do the work for you
    use LWP::UserAgent;                                                                                                                 
    use LWPx::TimedHTTP qw(:autoinstall);                                                                                     

    # now just continue as normal                                                                                                               
    my $ua = LWP::UserAgent->new;                                                                                                        
    my $response = $ua->get("http://thegestalt.org");                                                                                   
    # ... with optional retrieving of metrics (in seconds)
    printf  "%f\n", $response->header('Client-Request-Connect-Time');  


    # or if you don't like magic going on in the background
    use LWP::UserAgent;                                                                                                                 
    use LWP::Protocol;                                                                                                                  
    use LWPx::TimedHTTP;    

    LWP::Protocol::implementor('http',  'LWPx::TimedHTTP');                                                                   

    # or for https ....
    LWP::Protocol::implementor('https', 'LWPx::TimedHTTP::https');

    my $ua = LWP::UserAgent->new;                                                                                                            
    my $response = $ua->get("http://thegestalt.org");                                                                                       
    printf  "%f\n", $response->header('Client-Request-Connect-Time');    

=head1 DESCRIPTION

This module performs an HTTP request exactly the same 
as B<LWP> does normally except for the fact that it 
times each stage of the request and then inserts the 
results as header.

It's useful for debugging where abouts in a connection slow downs 
are occuring.

=head1 METRICS

All times returned are in seconds

=head2 Client-Request-Dns-Time

The time it took to do a DNS lookup on the host.

B<NOTE:> The value of this timing is NOT thread safe since it 
has to smuggle the data back via a global variable.

=head2 Client-Request-Connect-Time

The time it took to connect to the remote server

=head2 Client-Request-Transmit-Time

The time it took to transmit the request 

=head2 Client-Response-Server-Time

Time it took to respond to the request

=head2 Client-Response-Receive-Time

Time it took to get the data back

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

Based entirely on work by David Carter - 
this module is a little light frobbing and some packaging of
code he posted to the libwww-perl mailing list in response to
one of my questions.

His code was, in turn, based on B<LWP::Protocol::http> by 
Gisle Aas which is distributed as part of the B<libwww> package. 

=head1 COPYING

(c)opyright 2002, Simon Wistow

Distributed under the same terms as Perl itself.

This software is under no warranty and will probably ruin your life, kill your friends, burn your house and bring about the apocalypse

=head1 BUGS

None known

=head1 SEE ALSO

L<LWP::UserAgent>, L<Time::HiRes>

=cut


sub import {
    my $class   = shift;
    my $command = shift || return;

    croak "No such option '$command'\n" unless $command eq ':autoinstall';
    eval { require LWP::Protocol };
    croak "Requiring of LWP::Protocol failed - $@" if $@;

    LWP::Protocol::implementor('http', __PACKAGE__);
    LWP::Protocol::implementor('https', "LWPx::TimedHTTP::https");

}


require LWP::Protocol::http;
@ISA = qw(LWP::Protocol::http);

my $CRLF = "\015\012";

sub request
{
    my($self, $request, $proxy, $arg, $size, $timeout) = @_;

    $size ||= 4096;

    # check method
    my $method = $request->method;
    unless ($method =~ /^[A-Za-z0-9_!\#\$%&\'*+\-.^\`|~]+$/) {  # HTTP token
        return HTTP::Response->new( &HTTP::Status::RC_BAD_REQUEST,
                                  'Library does not allow method ' .
                                  "$method for 'http:' URLs");
    }

    my $url = $request->uri;
    my($host, $port, $fullpath);

    # Check if we're proxy'ing
    if (defined $proxy) {
        # $proxy is an URL to an HTTP server which will proxy this request
        $host = $proxy->host;
        $port = $proxy->port;
        $fullpath = $method eq "CONNECT" ?
                       ($url->host . ":" . $url->port) :
                       $url->as_string;
    }
    else {
        $host = $url->host;
        $port = $url->port;
        $fullpath = $url->path_query;
        $fullpath = "/$fullpath" unless $fullpath =~ m,^/,;
    }
    
    my $prev_time = [gettimeofday];
    my $this_time;

    # connect to remote site
    my $socket = $self->_new_socket($host, $port, $timeout);

    $this_time = [gettimeofday];

    my $http_version = "";
    if (my $proto = $request->protocol) {
        if ($proto =~ /^(?:HTTP\/)?(1.\d+)$/) {
            $http_version = $1;
            $socket->http_version($http_version);
            $socket->send_te(0) if $http_version eq "1.0";
        }
    }

    $self->_check_sock($request, $socket);

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
            $has_content = length($$content_ref);
            if (!defined($clen) || $clen ne $has_content) {
                if (defined $clen) {
                    warn "Content-Length header value was wrong, fixed";
                    hlist_remove(\@h, 'Content-Length');
                }
                push(@h, 'Content-Length' => $has_content);
            }
        }
        elsif ($clen) {
            warn "Content-Length set when there is no content, fixed";
            hlist_remove(\@h, 'Content-Length');
        }
    }

    my $write_wait = 0;
    $write_wait = 2
        if ($request_headers->header("Expect") || "") =~ /100-continue/;

    my $req_buf = $socket->format_request($method, $fullpath, @h);
    #print "------\n$req_buf\n------\n";

    if (!$has_content || $write_wait || $has_content > 8*1024) {
      WRITE:
        {
            # Since this just writes out the header block it should almost
            # always succeed to send the whole buffer in a single write call.
            my $n = $socket->syswrite($req_buf, length($req_buf));
            unless (defined $n) {
                redo WRITE if $!{EINTR};
                if ($!{EAGAIN}) {
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
        if ($write_wait) {
            # skip filling $wbuf when waiting for 100-continue
            # because if the response is a redirect or auth required
            # the request will be cloned and there is no way
            # to reset the input stream
            # return here via the label after the 100-continue is read
        }
        elsif (ref($content_ref) eq 'CODE') {
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
        while ($write_wait || $woffset < length($$wbuf)) {

            my $sel_timeout = $timeout;
            if ($write_wait) {
                $sel_timeout = $write_wait if $write_wait < $sel_timeout;
            }
            my $time_before;
            $time_before = time if $sel_timeout;

            my $rbits = $fbits;
            my $wbits = $write_wait ? undef : $fbits;
            my $sel_timeout_before = $sel_timeout;
          SELECT:
            {
                my $nfound = select($rbits, $wbits, undef, $sel_timeout);
                if ($nfound < 0) {
                    if ($!{EINTR} || $!{EAGAIN}) {
                        if ($time_before) {
                            $sel_timeout = $sel_timeout_before - (time - $time_before);
                            $sel_timeout = 0 if $sel_timeout < 0;
                        }
                        redo SELECT;
                    }
                    die "select failed: $!";
                }
            }

            if ($write_wait) {
                $write_wait -= time - $time_before;
                $write_wait = 0 if $write_wait < 0;
            }

            if (defined($rbits) && $rbits =~ /[^\0]/) {
                # readable
                my $buf = $socket->_rbuf;
                my $n = $socket->sysread($buf, 1024, length($buf));
                unless (defined $n) {
                    die "read failed: $!" unless  $!{EINTR} || $!{EAGAIN};
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
                if (!$code && $buf =~ /\015?\012\015?\012/) {
                    # a whole response header is present, so we can read it without blocking
                    ($code, $mess, @h) = $socket->read_response_headers(laxed => 1,
                                                                        junk_out => \@junk,
                                                                       );
                    if ($code eq "100") {
                        $write_wait = 0;
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
                    die "write failed: $!" unless $!{EINTR} || $!{EAGAIN};
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
    
    # store the leftover info from the connect (had to wait until we had a response. . .)
    $response->push_header($_, $LWPx::TimedHTTP::Socket::timings{$_}) for keys %LWPx::TimedHTTP::Socket::timings;
    $response->push_header('Client-Request-Connect-Time', tv_interval($prev_time, $this_time));
    $prev_time = $this_time;
    $this_time = [gettimeofday];
    $response->push_header('Client-Request-Transmit-Time', tv_interval($prev_time, $this_time));
    $prev_time = $this_time;

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
                redo READ if $!{EINTR} || $!{EAGAIN};
                die "read failed: $!";
            }
            if (! defined $response->header('Client-Response-Server-Time') ) { 
                $this_time = [gettimeofday];
                $response->push_header('Client-Response-Server-Time', tv_interval($prev_time, $this_time));
                $prev_time = $this_time;
            }
            redo READ if $n == -1;
        }
        $complete++ if !$n;
        return \$buf;
    } );

    $this_time = [gettimeofday];
    $response->push_header('Client-Response-Receive-Time', tv_interval($prev_time, $this_time));
    $drop_connection++ unless $complete;
    
    @h = $socket->get_trailers;
    if (@h) {
        local $HTTP::Headers::TRANSLATE_UNDERSCORE;
        $response->push_header(@h);
    }

    # keep-alive support
    unless ($drop_connection) {
        if (my $conn_cache = $self->{ua}{conn_cache}) {
            my %connection = map { (lc($_) => 1) }
                             split(/\s*,\s*/, ($response->header("Connection") || ""));
            if (($peer_http_version eq "1.1" && !$connection{close}) ||
                $connection{"keep-alive"})
            {
                $conn_cache->deposit($self->socket_type, "$host:$port", $socket);
            }
        }
    }

    $response;
}

#-----------------------------------------------------------
package LWPx::TimedHTTP::Socket;
use vars qw(@ISA);
@ISA = qw(LWP::Protocol::http::SocketMethods Net::HTTP);
use IO::Socket;
use Socket;
use Time::HiRes qw(gettimeofday tv_interval);

our %timings;

sub _get_addr {
    my($sock,$addr_str, $multi) = @_;
    my @addr;
    my $prev_time = [gettimeofday];
    if ($multi && $addr_str !~ /^\d+(?:\.\d+){3}$/) {
        (undef, undef, undef, undef, @addr) = gethostbyname($addr_str);
    } else {
        my $h = inet_aton($addr_str);
        push(@addr, $h) if defined $h;
    }
    my $this_time = [gettimeofday];
    $timings{'Client-Request-Dns-Time'} = tv_interval($prev_time, $this_time);
    @addr;
}

package LWPx::TimedHTTP::https;
eval { require LWP::Protocol::https };
use vars qw(@ISA);
@ISA = qw(LWPx::TimedHTTP);

package LWPx::TimedHTTP::https::Socket;
use vars qw(@ISA);
@ISA = qw(LWP::Protocol::https::Socket);



1;
