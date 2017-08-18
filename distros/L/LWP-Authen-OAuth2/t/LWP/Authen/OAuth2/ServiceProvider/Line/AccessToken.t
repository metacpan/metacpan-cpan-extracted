#! /usr/bin/env perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../../../../../lib";

BEGIN {
    use_ok( 'LWP::Authen::OAuth2::ServiceProvider::Line::AccessToken' ) || print "Bail out!\n";
}

is($LWP::Authen::OAuth2::ServiceProvider::Line::AccessToken::REFRESH_PERIOD, 10*24*60*60);

my $token = LWP::Authen::OAuth2::ServiceProvider::Line::AccessToken->from_ref({
    expires_in    =>  60,
    access_token  => 'dummy_access_token',
    refresh_token => 'dummy_refresh_token',
    _class        => 'LWP::Authen::OAuth2::ServiceProvider::Line::AccessToken',
});
is(ref $token, 'LWP::Authen::OAuth2::ServiceProvider::Line::AccessToken');
is($token->access_token,  'dummy_access_token' );
is($token->refresh_token, 'dummy_refresh_token');
ok(!$token->should_refresh(0), 'not expired');

$token = LWP::Authen::OAuth2::ServiceProvider::Line::AccessToken->from_ref({
    expires_in    =>  -60,
    access_token  => 'dummy_access_token',
    refresh_token => 'dummy_refresh_token',
    _class        => 'LWP::Authen::OAuth2::ServiceProvider::Line::AccessToken',
});
ok($token->should_refresh(0), 'expired, refreshable');

$token = LWP::Authen::OAuth2::ServiceProvider::Line::AccessToken->from_ref({
    expires_in    =>  -1_000_000,
    access_token  => 'dummy_access_token',
    refresh_token => 'dummy_refresh_token',
    _class        => 'LWP::Authen::OAuth2::ServiceProvider::Line::AccessToken',
});
ok(!$token->should_refresh(0), 'expired, not refreshable');

local $LWP::Authen::OAuth2::ServiceProvider::Line::AccessToken::REFRESH_PERIOD = 2_000_000;
ok($token->should_refresh(0), 'REFRESH_PERIOD global is obeyed');

done_testing();
