#! /usr/bin/env perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../../../../lib";

BEGIN {
    use_ok( 'LWP::Authen::OAuth2::ServiceProvider::Line' ) || print "Bail out!\n";
    use LWP::Authen::OAuth2;

    my $oauth2 = LWP::Authen::OAuth2->new(
        client_id => 'Test',
        client_secret => 'Test',
        service_provider => 'Line',
        redirect_uri => 'http://127.0.0.1',
    );
    isa_ok($oauth2, 'LWP::Authen::OAuth2');

    my $sp = $oauth2->{service_provider};
    is($sp->api_url_base                 => 'https://api.line.me/v2/'                                );
    is($sp->token_endpoint               => 'https://api.line.me/v2/oauth/accessToken'               );
    is($sp->authorization_endpoint       => 'https://access.line.me/dialog/oauth/weblogin'           );
    is($sp->access_token_class('bearer') => 'LWP::Authen::OAuth2::ServiceProvider::Line::AccessToken');
}

done_testing();
