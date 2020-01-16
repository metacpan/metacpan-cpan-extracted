package Loctools::Net::OAuth2::Session::Google;
use parent Loctools::Net::OAuth2::Session;

use strict;

sub new {
    my ($class, %params) = @_;

    my $defautls = {
        site               => 'https://accounts.google.com',
        authorize_path     => '/o/oauth2/auth',
        access_token_path  => '/o/oauth2/token',
        refresh_token_path => '/o/oauth2/token',
        response_type      => 'code',
        redirect_uri       => 'urn:ietf:wg:oauth:2.0:oob',
    };

    map {
        $params{$_} = $defautls->{$_} unless exists $params{$_};
    } keys %$defautls;

    return $class->SUPER::new(%params);
}

1;