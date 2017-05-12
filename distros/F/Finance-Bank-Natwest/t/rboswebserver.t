#!/usr/bin/perl -w

use strict;

use lib 't/lib';

use Carp;
use Test::More tests => 207;
use Test::Exception;
use Mock::NatwestWebServer::Tests;
use_ok( 'Mock::NatwestWebServer' );

my $nws;
ok( $nws = Mock::NatwestWebServer->new(), 'created M:NWS object successfully' );

isa_ok( $nws, 'Mock::NatwestWebServer' );
for my $method (qw/ add_account expire_session session_id 
                    logonmessage_enable logonmessage_disable
		    set_scheme set_host set_port set_path_prefix /) {
   can_ok( $nws, $method );
}

$nws->set_host('www.rbsdigital.com');
$nws->set_pin_desc('Security Number');

$nws->add_account( dob => '010179', uid => '0001',
                   pin => '1234', pass => 'abcdefgh' );
$nws->logonmessage_disable();

is( $nws->next_call(), undef, 'nothing but new() called yet' );
$nws->clear();

my $ua;
ok( $ua = LWP::UserAgent->new(), 'created mock L:UA object successfully' );

isa_ok( $ua, 'Mock::NatwestWebServer' );
can_ok( $ua, 'post' );

my $resp;

ok( $resp = $ua->post(), 'got response object successfully' );
isa_ok( $resp, 'Mock::NatwestWebServer' );
for my $method (qw/ is_success message content /) {
   can_ok( $resp, $method );
}
if (can_ok( $resp, 'base' )) {
   can_ok( $resp->base, 'as_string' );
   can_ok( $resp->base, 'path_segments' );
}

my @invalid_requests = (['', 'emty url'], 
                        ['http://www.rbsdigital.com/', 'not https'],
                        ['https://www.notrbsdigital.com/', 'not www.rbsdigital.com'],
                        ['https://www.rbsdigital.com:8443/', 'not port 443'],
                       );

for my $request (@invalid_requests) {
   $nws->clear;
   request_fail( $ua, $request->[0], undef, $request->[1] );
};

my $url;

for $url ('https://www.rbsdigital.com/',
          'https://www.rbsdigital.com/not/secure/') {
   $nws->clear;
   $resp = request_ok( $ua, UNKNOWN_PAGE, $url );
}

$url = 'https://www.rbsdigital.com/secure/';
$nws->expire_session;
$resp = request_ok( $ua, UNKNOWN_PAGE, $url );
is( $nws->session_id, undef, 'should not have been session redirected' );

$url = 'https://www.rbsdigital.com/secure';
$nws->expire_session;
$resp = request_ok( $ua, UNKNOWN_PAGE, $url );
is( $nws->session_id, undef, 'should not have been session redirected' );

$url = 'https://www.rbsdigital.com/secure/login.asp';
$nws->expire_session;
$resp = request_ok( $ua, UNKNOWN_PAGE, $url );
is( $nws->session_id, undef, 'should not have been session redirected' );

$url = 'https://www.rbsdigital.com/secure/logon.asp';
$nws->expire_session;
$resp = request_ok( $ua, ERROR, $url );
isnt( $nws->session_id, undef, 'should have been session redirected' );

my ($params1, $params2);

$params1 = { DBIDa => '010179',
             DBIDb => '0001',
             radType => '',
             scriptingon => 'no' };
$resp = request_ok( $ua, ERROR, $url, $params1 );

$params1->{scriptingon} = 'yup';
$resp = request_ok( $ua, PINPASS_REQUEST, $url, $params1 );
$nws->expire_session;

$params2 = { pin1 => '2', pin2 => '4', pin3 => '0',
             pass1 => 'g', pass2 => 'c', pass3 => 'e',
             buttonComplete => 'Submitted', buttonFinish => 'Finish' };
$url = 'https://www.rbsdigital.com/secure/' . 
       ($resp->base->path_segments)[2] .
       '/logon-pinpass.asp';
$nws->clear;
$resp = request_ok( $ua, SESSION_EXPIRED, $url, $params2 );
$nws->expire_session;

$url = 'https://www.rbsdigital.com/secure/logon.asp';
$nws->set_pinpass( [1, 3, 0], [6, 2, 4] );
$resp = request_ok( $ua, PINPASS_REQUEST, $url, $params1 );

$url = 'https://www.rbsdigital.com/secure/' . 
       ($resp->base->path_segments)[2] .
       '/logon-pinpass.asp';
$resp = request_ok( $ua, ERROR_NOREDIR, $url, $params2 );
$nws->expire_session;

$url = 'https://www.rbsdigital.com/secure/logon.asp';
$nws->set_pinpass( [1, 3, 0], [6, 2, 4] );
$resp = request_ok( $ua, PINPASS_REQUEST, $url, $params1 );

$params2->{pin3} = '1';
$params2->{pass3} = 'f';
$url = 'https://www.rbsdigital.com/secure/' . 
       ($resp->base->path_segments)[2] .
       '/logon-pinpass.asp';
$resp = request_ok( $ua, ERROR_NOREDIR, $url, $params2 );
$nws->expire_session;

$url = 'https://www.rbsdigital.com/secure/logon.asp';
$nws->set_pinpass( [1, 3, 0], [6, 2, 4] );
$resp = request_ok( $ua, PINPASS_REQUEST, $url, $params1 );

$params2->{pass3} = 'e';
$url = 'https://www.rbsdigital.com/secure/' . 
       ($resp->base->path_segments)[2] .
       '/logon-pinpass.asp';
$resp = request_ok( $ua, LOGIN_OK, $url, $params2 );

$url = 'https://www.rbsdigital.com/secure/' .
       ($resp->base->path_segments)[2] .
       '/Balances.asp?0';
$resp = request_ok( $ua, BALANCES, $url );

$url = 'https://www.rbsdigital.com/secure/' .
       ($resp->base->path_segments)[2] .
       '/Balances.asp?1';
$resp = request_ok( $ua, BALANCES, $url );

$url = 'https://www.rbsdigital.com/secure/' .
       ($resp->base->path_segments)[2] .
       '/Balances.asp?2';
$resp = request_ok( $ua, ERROR, $url );
ok( !defined $resp->session_id(), 'Session expired as expected' );

