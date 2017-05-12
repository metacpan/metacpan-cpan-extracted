# $Id: /mirror/gungho/lib/Gungho/Component/Authentication.pm 1657 2007-04-10T02:26:11.598323Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# all rights reserved.

package Gungho::Component::Authentication;
use strict;
use warnings;
use base qw(Gungho::Component);
use Carp qw(croak);
use HTTP::Status();
use HTTP::Headers::Util();

sub authenticate
{
    croak ref($_[0]) . "::authenticate() unimplemented";
}

sub check_authentication_challenge
{
    my ($c, $req, $res) = @_;

    my $handled = 0;

    # Check if there was a Auth challenge. If yes and Gungho is configured
    # to support authentication, then do the auth magic
    my $code = $res->code;

    if ( $code == &HTTP::Status::RC_UNAUTHORIZED ||
         $code == &HTTP::Status::RC_PROXY_AUTHENTICATION_REQUIRED )
    {
        my $proxy = ($code == &HTTP::Status::RC_PROXY_AUTHENTICATION_REQUIRED);
        my $ch_header = $proxy ? "Proxy-Authenticate" : "WWW-Authenticate";
        my @challenge = $res->header($ch_header);

        if (! @challenge) {
            $c->log->debug("Response from " . $req->uri . " returned with code = $code, but is missing Authenticate header");
            $res->header("Client-Warning" => "Missing Authenticate header");
            goto DONE;
        }
CHALLENGE:
        for my $challenge (@challenge) {
            $challenge =~ tr/,/;/; # "," is used to separate auth-params!!
            ($challenge) = HTTP::Headers::Util::split_header_words($challenge);
            my $scheme = lc(shift(@$challenge));
            shift(@$challenge); # no value 
            $challenge = { @$challenge };  # make rest into a hash
            for (keys %$challenge) {       # make sure all keys are lower case
                $challenge->{lc $_} = delete $challenge->{$_};
            }

            unless ($scheme =~ /^([a-z]+(?:-[a-z]+)*)$/) {
                $c->log->debug("Response from " . $req->uri . " returned with code = $code, bad authentication scheme '$scheme'");
                $res->header("Client-Warning" => "Bad authentication scheme '$scheme'");
                goto DONE;
            }
            $scheme = ucfirst $1;  # untainted now

            if (! $c->has_feature("Authentication::$scheme")) {
                $c->log->debug("Response from " . $req->uri . " returned with code = $code, but authentication scheme '$scheme' is unsupported");
                goto DONE;
            }

            # now attempt to authenticate
            return $c->authenticate($proxy, $challenge, $req, $res);
        }
    }

DONE:
    return $handled;
}

1;

__END__

=head1 NAME

Gungho::Component::Authentication - Base Class For WWW Authentication

=head1 SYNOPSIS

   package MyAuth;
   use base qw(Gungho::Component::Authentication);

=head1 DESCRIPTION

Gungho::Component::Authentication provides the base mechanism to detect
and authenticate WWW Authentication responses.

Subclasses must override the authenticate() method.

=head1 METHODS

=head2 authenticate($is_proxy, $auth_params, $request, $response)

Should authenticate the request, and do any re-dispatching if need be.
Should return 1 if the request has been redispatched.

=head2 check_authentication_challenge($c, $req, $res)

Checks the given request/response for a WWW Authentication challenge, and
re-dispatches the request if need be.

Returns 1 if the request has been redispatched (in which case your engine
class should not forward this response to handle_response()), 0 otherwise.

=cut
