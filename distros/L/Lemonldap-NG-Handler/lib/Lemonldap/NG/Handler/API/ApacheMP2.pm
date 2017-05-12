package Lemonldap::NG::Handler::API::ApacheMP2;

our $VERSION = '1.9.1';

# Specific modules and constants for Apache Mod_Perl 2
use strict;
use AutoLoader 'AUTOLOAD';
use Apache2::RequestUtil;
use Apache2::RequestRec;
use Apache2::Log;
use Apache2::ServerUtil;
use Apache2::Connection;
use Apache2::RequestIO;
use Apache2::Const;
use Apache2::Filter;
use APR::Table;
use Apache2::Const -compile =>
  qw(FORBIDDEN HTTP_UNAUTHORIZED REDIRECT OK DECLINED DONE SERVER_ERROR AUTH_REQUIRED HTTP_SERVICE_UNAVAILABLE);

use constant FORBIDDEN         => Apache2::Const::FORBIDDEN;
use constant HTTP_UNAUTHORIZED => Apache2::Const::HTTP_UNAUTHORIZED;
use constant REDIRECT          => Apache2::Const::REDIRECT;
use constant OK                => Apache2::Const::OK;
use constant DECLINED          => Apache2::Const::DECLINED;
use constant DONE              => Apache2::Const::DONE;
use constant SERVER_ERROR      => Apache2::Const::SERVER_ERROR;
use constant AUTH_REQUIRED     => Apache2::Const::AUTH_REQUIRED;
use constant MAINTENANCE       => Apache2::Const::HTTP_SERVICE_UNAVAILABLE;
use constant BUFF_LEN          => 8192;

eval { require threads::shared; };
print STDERR
  "You probably would have better perfs by enabling threads::shared\n"
  if ($@);

our $request;    # Apache2::RequestRec object for current request

## @method void thread_share(string $variable)
# try to share $variable between threads
# note: eval is needed,
# else it fails to compile if threads::shared is not loaded
# @param $variable the name of the variable to share
sub thread_share {
    my ( $class, $variable ) = @_;
    eval "threads::shared::share(\$variable);";
}

## @method void setServerSignature(string sign)
# modifies web server signature
# @param $sign String to add to server signature
sub setServerSignature {
    my ( $class, $sign ) = @_;
    Apache2::ServerUtil->server->push_handlers(
        PerlPostConfigHandler => sub {
            my ( $c, $l, $t, $s ) = @_;
            $s->add_version_component($sign);
        }
    );
}

sub newRequest {
    my ( $class, $r ) = @_;
    $request                  = $r;
    $Lemonldap::NG::API::mode = 'ApacheMP2';
}

## @method void lmLog(string $msg, string $level)
# logs message $msg to Apache logs with loglevel $level
# @param $msg string message to log
# @param $level string loglevel
sub lmLog {
    my ( $class, $msg, $level ) = @_;

    # TODO: remove the useless tag 'ApacheMP2.pm(70):' in debug logs
    Apache2::ServerRec->log->$level($msg);
}

## @method void set_user(string user)
# sets remote_user
# @param user string username
sub set_user {
    my ( $class, $user ) = @_;
    $request->user($user);
}

## @method string header_in(string header)
# returns request header value
# @param header string request header
# @return request header value
sub header_in {
    my ( $class, $header ) = @_;
    $header ||= $class;    # to use header_in as a method or as a function
    return $request->headers_in->{$header};
}

## @method void set_header_in(hash headers)
# sets or modifies request headers
# @param headers hash containing header names => header value
sub set_header_in {
    my ( $class, %headers ) = @_;
    while ( my ( $h, $v ) = each %headers ) {
        $request->headers_in->set( $h => $v );
    }
}

## @method void unset_header_in(array headers)
# removes request headers
# This function looks a bit heavy: it is to ensure that if a request
# header 'Auth-User' is removed, 'Auth_User' be removed also
# @param headers array with header names to remove
sub unset_header_in {
    my ( $class, @headers ) = @_;
    foreach my $h1 (@headers) {
        $h1 = lc $h1;
        $h1 =~ s/-/_/g;
        $request->headers_in->do(
            sub {
                my $h  = shift;
                my $h2 = lc $h;
                $h2 =~ s/-/_/g;
                $request->headers_in->unset($h) if ( $h1 eq $h2 );
                return 1;
            }
        );
    }
}

## @method void set_header_out(hash headers)
# sets response headers
# @param headers hash containing header names => header value
sub set_header_out {
    my ( $class, %headers ) = @_;
    while ( my ( $h, $v ) = each %headers ) {
        $request->err_headers_out->set( $h => $v );
    }
}

## @method string hostname()
# returns host, as set by full URI or Host header
# @return host string Host value
sub hostname {
    my $class = shift;
    return $request->hostname;
}

## @method string remote_ip
# returns client IP address
# @return IP_Addr string client IP
sub remote_ip {
    my $class     = shift;
    my $remote_ip = (
          $request->connection->can('remote_ip')
        ? $request->connection->remote_ip
        : $request->connection->client_ip
    );
    return $remote_ip;
}

## @method boolean is_initial_req
# returns true unless the current request is a subrequest
# @return is_initial_req boolean
sub is_initial_req {
    my $class = shift;
    return $request->is_initial_req;
}

## @method string args(string args)
# gets the query string
# @return args string Query string
sub args {
    my $class = shift;
    return $request->args();
}

## @method string uri
# returns the path portion of the URI, normalized, i.e. :
# * URL decoded (characters encoded as %XX are decoded,
#   except ? in order not to merge path and query string)
# * references to relative path components "." and ".." are resolved
# * two or more adjacent slashes are merged into a single slash
# @return path portion of the URI, normalized
sub uri {
    my $class = shift;
    my $uri   = $request->uri;
    $uri =~ s#//+#/#g;
    $uri =~ s#\?#%3F#g;
    return $uri;
}

## @method string uri_with_args
# returns the URI, with arguments and with path portion normalized
# @return URI with normalized path portion
sub uri_with_args {
    my $class = shift;
    return uri . ( $request->args ? "?" . $request->args : "" );
}

## @method string unparsed_uri
# returns the full original request URI, with arguments
# @return full original request URI, with arguments
sub unparsed_uri {
    my $class = shift;
    return $request->unparsed_uri;
}

## @method string get_server_port
# returns the port the server is receiving the current request on
# @return port string server port
sub get_server_port {
    my $class = shift;
    return $request->get_server_port;
}

## @method string method
# returns the port the server is receiving the current request on
# @return port string server port
sub method {
    my $class = shift;
    return $request->method;
}

## @method void print(string data)
# write data in HTTP response body
# @param data Text to add in response body
sub print {
    my ( $class, $data ) = @_;
    $request->print($data);
}

1;
__END__

## @method void addToHtmlHead(string data)
# add data at end of html head
# @param data Text to add in html head
sub addToHtmlHead {
    use APR::Bucket  ();
    use APR::Brigade ();
    my ( $class, $data ) = @_;
    $request->add_output_filter(
        sub {
            my $f   = shift;
            my $bb  = shift;
            my $ctx = $f->ctx;

            #unless ($ctx) {
            #    $f->r->headers_out->unset('Content-Length');
            #}
            my $done = 0;
            my $buffer = $ctx->{data} ? $ctx->{data} : '';
            my ( $bdata, $seen_eos ) = flatten_bb($bb);
            unless ($done) {
                $done = 1
                  if ( $bdata =~ s/(<\/head>)/$data$1/si
                    or $bdata =~ s/(<body>)/$1$data/si );
            }
            $buffer .= $bdata if ($bdata);
            if ($seen_eos) {
                my $len = length $buffer;
                $f->r->headers_out->set( 'Content-Length', $len );
                $f->print($buffer) if ($buffer);
            }
            else {
                $ctx->{data} = $buffer;
                $f->ctx($ctx);
            }
            return OK;
        }
    );
}

sub flatten_bb {
    my ($bb) = shift;

    my $seen_eos = 0;

    my @data;
    for ( my $b = $bb->first ; $b ; $b = $bb->next($b) ) {
        $seen_eos++, last if $b->is_eos;
        $b->read( my $bdata );
        push @data, $bdata;
    }
    return ( join( '', @data ), $seen_eos );
}

## @method void setPostParams(hashref $params)
# add or modify parameters in POST request body
# @param $params hashref containing name => value
sub setPostParams {
    my ( $class, $params ) = @_;
    $request->add_input_filter(
        sub {
            my $f = shift;
            my $buffer;

            # Filter only POST request body
            if ( $f->r->method eq "POST" ) {
                my $body;
                while ( $f->read($buffer) ) { $body .= $buffer; }
                while ( my ( $name, $value ) = each(%$params) ) {
                    $body =~ s/((^|&))$name=[^\&]*/$1$name=$value/
                      or $body .= "&$name=$value";
                }
                $body =~ s/^&//;
                $f->print($body);
            }
            else {
                $f->print($buffer) while ( $f->read($buffer) );
            }
            return OK;
        }
    );
}

