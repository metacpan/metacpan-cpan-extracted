use Test::More;
use strict;
use IO::String;
use Test::MockObject;

require 't/test-lib.pm';

my $res;
my $mock   = Test::MockObject->new();
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel           => 'error',
            authentication     => 'Radius',
            userDB             => 'Demo',
            radiusServer       => '127.0.0.1',
            radiusSecret       => 'test',
            requireToken       => 1,
            portalDisplayOrder => 'Logout LoginHistory , Appslist'
        }
    }
);

# Test normal first access
ok( $res = $client->_get( '/', accept => 'text/html' ), 'First request' );
count(1);
my ( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'token' );

# Fake Radius server (bad password)
$mock->fake_module( 'Authen::Radius', check_pwd => sub { 0 } );

# Try to authenticate with bad password
$query =~ s/user=[^&]*/user=dwho/;
$query =~ s/password=/password=jdoe/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html'
    ),
    'Auth query'
);
count(1);
( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'token' );

# Fake Radius server
$mock->fake_module( 'Authen::Radius', check_pwd => sub { 1 } );

# Try to authenticate
$query =~ s/user=[^&]*/user=dwho/;
$query =~ s/password=/password=dwho/;
ok(
    $res = $client->_post(
        '/', IO::String->new($query), length => length($query)
    ),
    'Auth query'
);
count(1);
expectOK($res);
my $id = expectCookie($res);
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Get Portal menu'
);
count(1);
expectAuthenticatedAs( $res, 'dwho' );
my @tabs = map m#<div id="(appslist|loginHistory|logout)">#g, $res->[2]->[0];
ok( $#tabs == 2, 'Right number of categories' )
  or explain( $#tabs, '3 categories' );
ok(
    $tabs[0] eq 'logout'
      && $tabs[1] eq 'loginHistory'
      && $tabs[2] eq 'appslist',
    'Categories are well sorted'
) or explain( \@tabs, 'Sorted categories (logout, loginHistory, appslist)' );
count(2);
$client->logout($id);

clean_sessions();
done_testing( count() );
