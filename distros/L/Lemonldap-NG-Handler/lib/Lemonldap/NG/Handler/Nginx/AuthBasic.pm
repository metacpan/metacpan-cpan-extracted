package Lemonldap::NG::Handler::Nginx::AuthBasic;

use strict;
use Mouse;

extends 'Lemonldap::NG::Handler::PSGI::AuthBasic';

our $VERSION = '1.9.6';

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
#    #fastcgi_param $headername1 $headervalue1;
#
# LLNG::Handler::API::PSGI add also a header called Lm-Remote-User set to
# whatToTrace value that can be used in Nginx virtualhost configuration to
# insert user id in logs
#
#    auth_request_set $llremoteuser $upstream_http_lm_remote_user
#
#@param $req Lemonldap::NG::Common::PSGI::Request
sub handler {
    my ( $self, $req ) = @_;
    my $hdrs = $req->{respHeaders};
    $req->{respHeaders} = {};
    my @convertedHdrs =
      ( 'Content-Length' => 0, Cookie => ( $req->cookies // '' ) );
    my $i = 0;
    foreach my $k ( keys %$hdrs ) {
        if ( $k =~ /^(?:Lm-Remote-User|Cookie)$/ ) {
            push @convertedHdrs, $k, $hdrs->{$k};
        }
        else {
            $i++;
            push @convertedHdrs, "Headername$i", $k, "Headervalue$i",
              $hdrs->{$k}, $k, $hdrs->{$k};
        }
    }
    return [ 200, \@convertedHdrs, [] ];
}

1;
