use strict;
use Test::More 0.98;
use JSON::XS;

use_ok('EveOnline::SSO');

my $sso = EveOnline::SSO->new(
        client_id     => '76df1cffb31d0289',
        client_secret => 'e3a28554de3c2afc',
    );

is( $sso->get_code(), 'https://login.eveonline.com/oauth/authorize/?response_type=code&client_id=76df1cffb31d0289&redirect_uri=http%3A%2F%2Flocalhost%3A10707%2F', 
    'get_code' );

is( $sso->get_code(state => 'a28554df'), 'https://login.eveonline.com/oauth/authorize/?response_type=code&client_id=76df1cffb31d0289&redirect_uri=http%3A%2F%2Flocalhost%3A10707%2F&state=a28554df', 
    'get_code with state' );

is( $sso->get_code(state => 'a28554df', scope=>'esi-calendar.respond_calendar_events.v1 esi-location.read_location.v1'), 'https://login.eveonline.com/oauth/authorize/?response_type=code&client_id=76df1cffb31d0289&redirect_uri=http%3A%2F%2Flocalhost%3A10707%2F&scope=esi-calendar.respond_calendar_events.v1%20esi-location.read_location.v1&state=a28554df', 
    'get_code with state and scope' );

my $sso = EveOnline::SSO->new(
        client_id     => '76df1cffb31d0289',
        client_secret => 'e3a28554de3c2afc',
        callback_url  => 'http://eveonline.com:45500/',
    );

is( $sso->get_code(), 'https://login.eveonline.com/oauth/authorize/?response_type=code&client_id=76df1cffb31d0289&redirect_uri=http%3A%2F%2Feveonline.com%3A45500%2F', 
    'get_code with custom callback url' );

my $answer = '{"token_type": "bearer", "access_token": "e93d2da298624260a848438f1d11ed07", "expires_in": 1200, "refresh_token": "berF1ZVu_bkt2ud1Jzuqmj"}';

my $sso = EveOnline::SSO->new(
        client_id     => '76df1cffb31d0289',
        client_secret => 'e3a28554de3c2afc',
        demo          => $answer,
    );

is_deeply( $sso->get_token(code=>'OHYmzbc69hg4TdzQZoqvezFQUsio2H1CY9Ud7STQH-cJFvD9E_ddCmymq0g'), JSON::XS->new->decode($answer), 'get token' );
is_deeply( $sso->get_token(refresh_token=>'OHYmzbc69hg4TdzQZoqvezFQUsio2H1CY9Ud7STQH-cJFvD9E_ddCmymq0g'), JSON::XS->new->decode($answer), 'refresh token' );



done_testing;

