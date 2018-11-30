# PSGI authentication package written for Nginx. It replace
# Lemonldap::NG::Handler::Server to manage Nginx behaviour
package Lemonldap::NG::Handler::Server::Nginx;

use strict;
use Mouse;
use Lemonldap::NG::Handler::Server::Main;

our $VERSION = '2.0.0';

extends 'Lemonldap::NG::Handler::PSGI';

sub init {
    my $self = shift;
    $self->api('Lemonldap::NG::Handler::Server::Main');
    my $tmp = $self->SUPER::init(@_);
}

## @method void _run()
# Return a subroutine that call _authAndTrace() and tranform redirection
# response code from 302 to 401 (not authenticated) ones. This is required
# because Nginx "auth_request" parameter does not accept it. The Nginx
# configuration file should transform them back to 302 using:
#
#   auth_request_set $lmlocation $upstream_http_location;
#   error_page 401 $lmlocation;
#
#@return subroutine that will be called to manage FastCGI queries
sub _run {
    my $self = shift;
    return sub {
        my $req = $_[0];
        $self->logger->debug('New request');
        my $res = $self->_authAndTrace(
            Lemonldap::NG::Common::PSGI::Request->new($req) );

        # Transform 302 responses in 401 since Nginx refuse it
        if ( $res->[0] == 302 or $res->[0] == 303 ) {
            $res->[0] = 401;
        }
        return $res;
    };
}

## @method PSGI-Response handler()
# Transform headers returned by handler main process:
# each "Name: value" is transformed to:
#  - Headername<i>: Name
#  - Headervalue<i>: value
# where <i> is an integer starting from 1
# It can be used in Nginx virtualhost configuration:
#
#    auth_request_set $headername1 $upstream_http_headername1;
#    auth_request_set $headervalue1 $upstream_http_headervalue1;
#    #proxy_set_header $headername1 $headervalue1;
#    # OR
#    #fastcgi_param $fheadername1 $headervalue1;
#
# LLNG::Handler::Server::Main add also a header called Lm-Remote-User set to
# whatToTrace value that can be used in Nginx virtualhost configuration to
# insert user id in logs
#
#    auth_request_set $llremoteuser $upstream_http_lm_remote_user
#
#@param $req Lemonldap::NG::Common::PSGI::Request
sub handler {
    my ( $self, $req ) = @_;
    my $hdrs = $req->{respHeaders};
    $req->{respHeaders} = [];
    my @convertedHdrs =
      ( 'Content-Length' => 0, Cookie => ( $req->env->{HTTP_COOKIE} // '' ) );
    my $i = 0;
    while ( my $k = shift @$hdrs ) {
        my $v = shift @$hdrs;
        if ( $k =~ /^(?:Lm-Remote-User|Cookie)$/ ) {
            push @convertedHdrs, $k, $v;
        }
        else {
            $i++;
            push @convertedHdrs, "Headername$i", $k, "Headervalue$i", $v, $k,
              $v;
        }
    }
    return [ 200, \@convertedHdrs, [] ];
}

1;
