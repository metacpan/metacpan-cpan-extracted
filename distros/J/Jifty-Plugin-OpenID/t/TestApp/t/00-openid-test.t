#!/usr/bin/env perl
use Jifty::Test tests => 12;
use strict;
use warnings;
use Jifty::Test::WWW::Mechanize;



use Test::OpenID::Server;
my $test_openid_server   = Test::OpenID::Server->new;
my $test_openid_url = $test_openid_server->started_ok("server started ok");

diag $test_openid_url;

my $openid = "$test_openid_url/c9s";


my $server = Jifty::Test->make_server;
isa_ok( $server, 'Jifty::Server' );
my $URL = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new;
$mech->get_ok( $URL . '/' , "get mainpage" );
$mech->content_contains( 'Login with OpenID' );
$mech->content_contains( 'OpenID URL' );
$mech->content_contains( 'For example:' );

$mech->submit_form(
    form_name => 'openid-form',
    fields    => { 
        'J:A:F-openid-authenticateopenid'  => $openid,
    },
    # button    => 'Login with OpenID'
); 

$mech->content_contains( 'Set your username' );


# match this name="J:A:F-name-auto-86d3fcd1a158d85fd2e6165fc00113c7-1"
my $content = $mech->content();
my ($field_name) = ($content =~ m[name="(J:A:F-email-auto-\w+-\d)"]gsm);

diag $field_name;

$mech->submit_form(
    form_name => 'openid-user-create',
    fields    => { 
        # $field_name  => 'c9s'
        $field_name  => 'c9s@c9s'
    },
    # button    => 'Continue'
); 

$mech->content_contains( 'Welcome' );


my $u = TestApp::Model::User->new;
$u->load_by_cols( email => 'c9s@c9s' );

ok( $u->id , 'found user' );
is( $u->email , 'c9s@c9s' , 'found openid register user' );
is( $u->openid , $openid , 'match openid' );
