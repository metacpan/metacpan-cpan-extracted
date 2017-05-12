package Lemonldap::NG::Handler::API::Nginx;

our $VERSION = '1.9.1';

use constant FORBIDDEN         => 403;
use constant HTTP_UNAUTHORIZED => 401;
use constant REDIRECT          => 302;
use constant OK                => 0;
use constant DECLINED          => -1;
use constant DONE              => -2;
use constant SERVER_ERROR      => 500;
use constant AUTH_REQUIRED     => 401;
use constant MAINTENANCE       => 503;

my $request;    # Nginx object for current request

## @method void thread_share(string $variable)
# not applicable with Nginx
sub thread_share {
}

## @method void setServerSignature(string sign)
# modifies web server signature
# @param $sign String to add to server signature
sub setServerSignature {
    my ( $class, $sign ) = @_;

    # TODO
}

sub newRequest {
    my ( $class, $r ) = @_;
    $request                  = $r;
    $Lemonldap::NG::API::mode = 'Nginx';
}

## @method void lmLog(string $msg, string $level)
# logs message $msg to Apache logs with loglevel $level
# @param $msg string message to log
# @param $level string loglevel
sub lmLog {
    my ( $class, $msg, $level ) = @_;

    # TODO
}

## @method void set_user(string user)
# sets remote_user
# @param user string username
sub set_user {
    my ( $class, $user ) = @_;
    $request->variable( 'lmremote_user', $user );
}

## @method string header_in(string header)
# returns request header value
# @param header string request header
# @return request header value
sub header_in {
    my ( $class, $header ) = @_;
    $header ||= $class;    # to use header_in as a method or as a function
    return $request->header_in($header);
}

## @method void set_header_in(hash headers)
# sets or modifies request headers
# @param headers hash containing header names => header value
sub set_header_in {
    my ( $class, %headers ) = @_;
    while ( my ( $h, $v ) = each %headers ) {
        if ( $h =~ /cookie/i ) {

            # TODO: check that variable $lmcookie is defined,
            #       else warn that LL::NG cookie will not be removed
            $request->variable( 'lmcookie', $v );
        }
        else {
            # TODO: check that header is not yet set, else throw warning
            #       or reject request if mode paranoid is set
            # TODO: check that variable nginxName($h) is defined,
            #       else warn that header will not be sent
            $request->variable( nginxName($h), $v );
        }
    }
}

## @method void unset_header_in(array headers)
# removes request headers
# @param headers array with header names to remove
sub unset_header_in {
    my ( $class, @headers ) = @_;
    foreach my $h1 (@headers) {

        # TODO: check that header is not yet set, else throw warning
        $request->variable( nginxName($h), '' );
    }
}

## @method void set_header_out(hash headers)
# sets response headers
# @param headers hash containing header names => header value
sub set_header_out {
    my ( $class, %headers ) = @_;
    while ( my ( $h, $v ) = each %headers ) {
        if ( $h =~ /location/i ) {
            $request->variable( 'lmlocation', $v );
        }
        else {
            $request->header_out( $h, $v );
        }
    }
}

## @method string hostname()
# returns host, as set by full URI or Host header
# @return host string Host value
sub hostname {
    my $class = shift;
    return $request->variable('host');
}

## @method string remote_ip
# returns client IP address
# @return IP_Addr string client IP
sub remote_ip {
    my $class = shift;
    return $request->variable('remote_addr');
}

## @method boolean is_initial_req
# returns true unless the current request is a subrequest
# @return is_initial_req boolean
sub is_initial_req {
    my $class = shift;
    return 1;
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
    return $request->uri();
}

## @method string uri_with_args
# returns the URI, with arguments and with path portion normalized
# @return URI with normalized path portion
sub uri_with_args {
    my $class = shift;
    return uri() . ( $request->args ? "?" . $request->args : "" );
}

## @method string unparsed_uri
# returns the full original request URI, with arguments
# @return full original request URI, with arguments
sub unparsed_uri {
    my $class = shift;
    return $request->variable('request_uri');
}

## @method string get_server_port
# returns the port the server is receiving the current request on
# @return port string server port
sub get_server_port {
    my $class = shift;
    return $request->variable('server_port');
}

## @method string method
# returns the method the request is sent with
# @return port string server port
sub method {
    my $class = shift;
    return $request->request_method;
}

## @method void print(string data)
# write data in HTTP response body
# @param data Text to add in response body
sub print {
    my ( $class, $data ) = @_;
    $request->print($data);
}

## @method void addToHtmlHead(string data)
# add data at end of html head: not feasible with Nginx
# @param data Text to add in html head
sub addToHtmlHead {
    my ( $class, $data ) = @_;

    # TODO: throw error log
}

## @method void setPostParams(hashref $params)
# add or modify parameters in POST request body: not feasible with Nginx
# @param $params hashref containing name => value
sub setPostParams {
    my ( $class, $params ) = @_;

    # TODO: throw error log
}

sub nginxName {
    my $h = lc(shift);
    $h =~ s/-/_/g;
    return "lm_$h";
}

1;
