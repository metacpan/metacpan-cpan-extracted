package Lemonldap::NG::Handler::API::ApacheMP1;

our $VERSION = '1.9.1';

# Specific modules and constants for Apache Mod_Perl 1
use Apache;
use Apache::Log;
use Apache::Constants qw(:common :response);

## @method void setServerSignature(string sign)
# modifies web server signature
# @param $sign String to add to server signature
sub setServerSignature {
    my ( $class, $sign ) = @_;

    #TODO
}

## @method void thread_share(string $variable)
# share or not the variable (if authorized by specific module)
# @param $variable the name of the variable to share
sub thread_share {
    my ( $class, $variable ) = @_;

    # nothing to do in ApacheMP1
}

## @method void lmLog(string $msg, string $level, Apache::RequestRec $r)
# logs message $msg to Apache logs with loglevel $level
# @param $msg string message to log
# @param $level string loglevel
# @param $r Apache2::RequestRec optional Current request
sub lmLog {
    my ( $class, $msg, $level, $r ) = @_;
    Apache->server->log->$level($msg);
}

## @method void set_user(Apache2::RequestRec request, string user)
# sets remote_user
# @param request Apache2::RequestRec current request
# @param user string username
sub set_user {
    my ( $class, $r, $user ) = @_;
    $r->connection->user($user);
}

## @method string header_in(Apache2::RequestRec request, string header)
# returns request header value
# @param request Apache2::RequestRec current request
# @param header string request header
# @return request header value
sub header_in {
    my ( $class, $r, $header ) = @_;
    return $r->header_in($header);
}

## @method void set_header_in(Apache2::RequestRec request, hash headers)
# sets or modifies request headers
# @param request Apache2::RequestRec current request
# @param headers hash containing header names => header value
sub set_header_in {
    my ( $class, $r, %headers ) = @_;
    while ( my ( $h, $v ) = each %headers ) {
        $r->header_in( $h => $v );
    }
}

## @method void unset_header_in(Apache2::RequestRec request, array headers)
# removes request headers
# @param request Apache2::RequestRec current request
# @param headers array with header names to remove
sub unset_header_in {
    my ( $class, $r, @headers ) = @_;
    foreach my $h (@headers) {
        $r->header_in( $h => "" ) if ( $r->header_in($h) );
    }
}

## @method void set_header_out(Apache2::RequestRec request, hash headers)
# sets response headers
# @param request Apache2::RequestRec current request
# @param headers hash containing header names => header value
sub set_header_out {
    my ( $class, $r, %headers ) = @_;
    while ( my ( $h, $v ) = each %headers ) {
        $r->err_header_out( $h => $v );
    }
}

## @method string hostname(Apache2::RequestRec request)
# returns host, as set by full URI or Host header
# @param request Apache2::RequestRec current request
# @return host string Host value
sub hostname {
    my ( $class, $r ) = @_;
    return $r->hostname;
}

## @method string remote_ip(Apache2::RequestRec request)
# returns client IP address
# @param request Apache2::RequestRec current request
# @return IP_Addr string client IP
sub remote_ip {
    my ( $class, $r ) = @_;
    return $r->remote_ip;
}

## @method boolean is_initial_req(Apache2::RequestRec request)
# always returns true, since Apache mod_perl 1 has no such feature
# @param request Apache2::RequestRec current request
# @return is_initial_req boolean
sub is_initial_req {
    my ( $class, $r ) = @_;
    return 1;
}

## @method string args(Apache2::RequestRec request, string args)
# gets the query string
# @param request Apache2::RequestRec current request
# @return args string Query string
sub args {
    my ( $class, $r ) = @_;
    return $r->args();
}

## @method string uri(Apache2::RequestRec request)
# returns the path portion of the URI, normalized, i.e. :
# * URL decoded (characters encoded as %XX are decoded,
#   except ? in order not to merge path and query string)
# * references to relative path components "." and ".." are resolved
# * two or more adjacent slashes are merged into a single slash
# @param request Apache2::RequestRec current request
# @return path portion of the URI, normalized
sub uri {
    my ( $class, $r ) = @_;
    my $uri = $r->uri;
    $uri =~ s#//+#/#g;
    $uri =~ s#\?#%3F#g;
    return $uri;
}

## @method string uri_with_args(Apache2::RequestRec request)
# returns the URI, with arguments and with path portion normalized
# @param request Apache2::RequestRec current request
# @return URI with normalized path portion
sub uri_with_args {
    my ( $class, $r ) = @_;
    return $class->uri($r) . ( $r->args ? "?" . $r->args : "" );
}

## @method string unparsed_uri(Apache2::RequestRec request)
# returns the full original request URI, with arguments
# @param request Apache2::RequestRec current request
# @return full original request URI, with arguments
sub unparsed_uri {
    my ( $class, $r ) = @_;
    return $r->unparsed_uri;
}

## @method string get_server_port(Apache2::RequestRec request)
# returns the port the server is receiving the current request on
# @param request Apache2::RequestRec current request
# @return port string server port
sub get_server_port {
    my ( $class, $r ) = @_;
    return $r->get_server_port;
}

## @method void print(string data, Apache2::RequestRec request)
# write data in HTTP response body
# @param data Text to add in response body
# @param request Apache2::RequestRec Current request
sub print {
    my ( $class, $data, $r ) = @_;
    $r->print($data);
}

1;
