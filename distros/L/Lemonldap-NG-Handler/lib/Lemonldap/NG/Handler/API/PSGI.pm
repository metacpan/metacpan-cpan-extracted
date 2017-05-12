package Lemonldap::NG::Handler::API::PSGI;

use strict;
our $VERSION = '1.9.1';

# Specific modules and constants for Test or CGI
use constant FORBIDDEN         => 403;
use constant HTTP_UNAUTHORIZED => 401;
use constant REDIRECT          => 302;
use constant OK                => 0;
use constant DECLINED          => 0;
use constant DONE              => 0;
use constant SERVER_ERROR      => 500;
use constant AUTH_REQUIRED     => 401;
use constant MAINTENANCE       => 503;
use Lemonldap::NG::Common::PSGI;

our $request;
#
## @method void setServerSignature(string sign)
# modifies web server signature
# @param $sign String to add to server signature
sub setServerSignature {
}

## @method void thread_share(string $variable)
# share or not the variable (if authorized by specific module)
# @param $variable the name of the variable to share
sub thread_share {

    # nothing to do in PSGI
}

## @method void newRequest($r)
# Store request in global $request variable
#
#@param $r Lemonldap::NG::Common::PSGI::Request
sub newRequest {
    my ( $class, $r ) = @_;
    $request                  = $r;
    $Lemonldap::NG::API::mode = 'PSGI';
}

## @method void lmLog(string $msg, string $level)
# logs message $msg to STDERR with level $level
# set Env Var lmLogLevel to set loglevel; set to "info" by default
# @param $msg string message to log
# @param $level string loglevel
BEGIN {
    *lmLog = *Lemonldap::NG::Common::PSGI::lmLog;
}

## @method void set_user(string user)
# sets remote_user in response headers
# @param user string username
sub set_user {
    my ( $class, $user ) = @_;
    $request->{respHeaders}->{'Lm-Remote-User'} = $user;
}

## @method string header_in(string header)
# returns request header value
# @param header string request header
# @return request header value
sub header_in {
    my ( $class, $header ) = @_;
    $header ||= $class;    # to use header_in as a method or as a function
    return $request->{ cgiName($header) };
}

## @method void set_header_in(hash headers)
# sets or modifies request headers
# @param headers hash containing header names => header value
sub set_header_in {
    my ( $class, %headers ) = @_;
    while ( my ( $h, $v ) = each %headers ) {
        $request->{ cgiName($h) } = $v;
    }
}

## @method void unset_header_in(array headers)
# removes request headers
# @param headers array with header names to remove
sub unset_header_in {
    my ( $class, @headers ) = @_;
    foreach my $h (@headers) {
        delete $request->{ cgiName($h) };
    }
}

## @method void set_header_out(hash headers)
# sets response headers
# @param headers hash containing header names => header value
sub set_header_out {
    my ( $class, %headers ) = @_;
    while ( my ( $h, $v ) = each %headers ) {
        $request->{respHeaders}->{$h} = $v;
    }
}

## @method string hostname
# returns host, as set by full URI or Host header
# @return host string Host value
sub hostname {
    my $h = $request->hostname;
    $h =~ s/:\d+//;
    return $h;
}

## @method string remote_ip
# returns client IP address
# @return IP_Addr string client IP
sub remote_ip {
    return $request->remote_ip;
}

## @method boolean is_initial_req
# always returns true
# @return is_initial_req boolean
sub is_initial_req {
    return 1;
}

## @method string args(string args)
# gets the query string
# @return args string Query string
sub args {
    return $request->query;
}

## @method string uri
# returns the path portion of the URI, normalized, i.e. :
# * URL decoded (characters encoded as %XX are decoded,
#   except ? in order not to merge path and query string)
# * references to relative path components "." and ".." are resolved
# * two or more adjacent slashes are merged into a single slash
# @return path portion of the URI, normalized
sub uri {
    return $request->uri;
}

## @method string uri_with_args
# returns the URI, with arguments and with path portion normalized
# @return URI with normalized path portion
sub uri_with_args {
    return $request->uri;
}

## @method string unparsed_uri
# returns the full original request URI, with arguments
# @return full original request URI, with arguments
sub unparsed_uri {
    return $request->unparsed_uri;
}

## @method string get_server_port
# returns the port the server is receiving the current request on
# @return port string server port
sub get_server_port {
    return $request->get_server_port;
}

## @method string method
# returns the request method
# @return port string server port
sub method {
    return $request->method;
}

## @method void print(string data)
# write data in HTTP response body
# @param data Text to add in response body
sub print {
    my ( $class, $data ) = @_;
    $request->{respBody} .= $data;
}

sub cgiName {
    my $h = uc(shift);
    $h =~ s/-/_/g;
    return "HTTP_$h";
}

sub addToHtmlHead {
    my $self = shift;
    $self->lmLog(
        'Features like form replay or logout_app can only be used with Apache',
        'error'
      ),
      ;
}

*setPostParams = *addToHtmlHead;

1;
