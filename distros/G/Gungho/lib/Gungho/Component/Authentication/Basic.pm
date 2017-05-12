# $Id: /mirror/gungho/lib/Gungho/Component/Authentication/Basic.pm 1736 2007-05-15T09:58:12.998753Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endworks.jp>
# All rights reserved.

package Gungho::Component::Authentication::Basic;
use strict;
use warnings;
use base qw(Gungho::Component::Authentication);
use MIME::Base64 ();
use URI;

__PACKAGE__->mk_classdata($_) for qw(basic_authentication);

sub setup
{
    my $self = shift;
    $self->basic_authentication({});

    my $list = $self->config->{credentials}{basic};
    if ($list) {
        foreach my $conf (@$list) {
            $self->set_basic_credentials(@$conf);
        }
    } 

    $self->next::method(@_);
}

sub authenticate
{
    my ($self, $proxy, $auth_param, $req, $res) = @_;

    my ($user, $pass) = $self->get_basic_credentials($req->url, $auth_param->{realm});

    return 0 unless defined $user and defined $pass;

    my $auth_header = $proxy ? "Proxy-Authorization" : "Authorization";
    my $auth_value = "Basic " . MIME::Base64::encode("$user:$pass", "");

    # Check if this is a repeated fialure to auth
    my $r = $res;
    while ($r) {
        my $auth = $r->request->header($auth_header);
        if ($auth && $auth eq $auth_value) {
            # here we know this failed before
            $res->header("Client-Warning" =>
                  "Credentials for '$user' failed before");
            return 0;
        }
        $r = $r->previous;
    }

    my $referral = $req->clone;
    $referral->header($auth_header => $auth_value);

    $self->send_request($referral);
    return 1;
}

sub set_basic_credentials
{
    my $self = shift;
    my ($uri, $realm, $uid, $pass) = @_;

    if (! eval { $uri->isa('URI') }) {
        $uri = URI->new($uri);
    }

    $self->basic_authentication()->{lc ($uri->host_port)}{$realm} = [$uid, $pass];
}

sub get_basic_credentials
{
    my $self = shift;
    my ($uri, $realm) = @_;

    if (! eval { $uri->isa('URI') }) {
        $uri = URI->new($uri);
    }

    if (exists $self->basic_authentication()->{lc($uri->host_port)}{$realm}) {
        return @{$self->basic_authentication()->{lc($uri->host_port)}{$realm}};
    }
    return (undef, undef);
}

1;

__END__

=head1 NAME

Gungho::Component::Authentication::Basic - Add Basic Auth To Gungho

=head1 SYNOPSIS

  ---
  components:
    - Authentication::Basic
  credentials:
    basic:
      -
        - http://example.com
        - "Admin Only"
        - username
        - password
      -
        - http://example2.com
        - "Admin Only"
        - username2
        - password2

=head1 DESCRIPTION

This module adds the capability to store basic authentication information
inside Gungho. 

=head1 METHODS

=head2 setup($c)

Sets up the component

=head2 authenticate($is_proxy, $realm, $request, $response)

Does the WWW Authentication and redispatches the request

=head2 set_basic_credentials($uri, $realm, $uid, $pass)

Sets the credentials for a uri + realm.

=head2 get_basic_credentials($uri, $realm)

Get the credentials for a uri + realm.

=head1 CAVEATS

This component merely stores data in Gungho that can be used for authentication.
The Engine type that Gungho is currently using must respect the information.

=cut