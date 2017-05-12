package Lemonldap::NG::Handler::API::CGI;

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

# Log level, since it can't be set in server config
# Default value 'notice' can be changed in lemonldap-ng.ini or in init args
our $logLevel = "notice";

my $request;    # object to store data about current request

## @method void setServerSignature(string sign)
# modifies web server signature
# @param $sign String to add to server signature
sub setServerSignature {
    my ( $class, $sign ) = @_;
    $ENV{SERVER_SOFTWARE} .= " $sign";
}

## @method void thread_share(string $variable)
# share or not the variable (if authorized by specific module)
# @param $variable the name of the variable to share
sub thread_share {

    # nothing to do in CGI
}

sub newRequest {
    my ( $class, $r ) = @_;
    $request                  = $r;
    $Lemonldap::NG::API::mode = 'CGI';
}

## @method void lmLog(string $msg, string $level)
# logs message $msg to STDERR with level $level
# set Env Var lmLogLevel to set loglevel; set to "info" by default
# @param $msg string message to log
# @param $level string loglevel
sub lmLog {
    my ( $class, $msg, $level ) = @_;
    print STDERR "[$level] $msg\n";
}

## @method void set_user(string user)
# sets remote_user
# @param user string username
sub set_user {
    my ( $class, $user ) = @_;
    $ENV{REMOTE_USER} = $user;
}

## @method string header_in(string header)
# returns request header value
# @param header string request header
# @return request header value
sub header_in {
    my ( $class, $header ) = @_;
    $header ||= $class;    # to use header_in as a method or as a function
    return $ENV{ cgiName($header) };
}

## @method void set_header_in(hash headers)
# sets or modifies request headers
# @param headers hash containing header names => header value
sub set_header_in {
    my ( $class, %headers ) = @_;
    while ( my ( $h, $v ) = each %headers ) {
        $ENV{ cgiName($h) } = $v;
    }
}

## @method void unset_header_in(array headers)
# removes request headers
# @param headers array with header names to remove
sub unset_header_in {
    my ( $class, @headers ) = @_;
    foreach my $h (@headers) {
        $ENV{ cgiName($h) } = undef;
    }
}

## @method void set_header_out(hash headers)
# sets response headers
# @param headers hash containing header names => header value
sub set_header_out {
    my ( $class, %headers ) = @_;
    while ( my ( $h, $v ) = each %headers ) {
        $request->{respHeaders}->{"-$h"} = $v;
    }
}

## @method string hostname
# returns host, as set by full URI or Host header
# @return host string Host value
sub hostname {
    my $s = $ENV{SERVER_NAME};
    $s =~ s/:\d+$//;
    return $s;
}

## @method string remote_ip
# returns client IP address
# @return IP_Addr string client IP
sub remote_ip {
    return $ENV{REMOTE_ADDR};
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
    return $ENV{QUERY_STRING};
}

## @method string uri
# returns the path portion of the URI, normalized, i.e. :
# * URL decoded (characters encoded as %XX are decoded,
#   except ? in order not to merge path and query string)
# * references to relative path components "." and ".." are resolved
# * two or more adjacent slashes are merged into a single slash
# @return path portion of the URI, normalized
sub uri {
    my $uri = $ENV{SCRIPT_NAME};
    $uri =~ s#//+#/#g;
    $uri =~ s#\?#%3F#g;
    return $uri;
}

## @method string uri_with_args
# returns the URI, with arguments and with path portion normalized
# @return URI with normalized path portion
sub uri_with_args {
    return &uri . ( $ENV{QUERY_STRING} ? "?$ENV{QUERY_STRING}" : "" );
}

## @method string unparsed_uri
# returns the full original request URI, with arguments
# @return full original request URI, with arguments
sub unparsed_uri {
    return $ENV{REQUEST_URI};
}

## @method string get_server_port
# returns the port the server is receiving the current request on
# @return port string server port
sub get_server_port {
    return $ENV{SERVER_PORT};
}

## @method string method
# returns the request method
# @return port string server port
sub method {
    return $ENV{METHOD};
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

1;
