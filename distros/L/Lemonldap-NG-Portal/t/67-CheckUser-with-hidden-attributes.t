use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                         => 'error',
            authentication                   => 'Demo',
            userDB                           => 'Same',
            checkUser                        => 1,
            checkUserHiddenAttributes        => 'hGroups, authenticationLevel',
            checkUserDisplayHiddenAttributes => '$uid eq "dwho"',
        }
    }
);

## Try to authenticate
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'user', 'password' );
$query =~ s/user=/user=dwho/;
$query =~ s/password=/password=dwho/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Auth query'
);
count(2);
my $id = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

# CheckUser form
# ------------------------
ok(
    $res = $client->_get(
        '/checkuser', cookie => "lemonldap=$id"
    ),
    'GET CheckUser',
);

my $data = eval { JSON::from_json( $res->[2]->[0] ) };
ok( not($@), ' Content is JSON' )
  or explain( [ $@, $res->[2] ], 'JSON content' );
my @hiddenAttributes =
  map { $_->{key} =~ /\b(?:hGroups|authenticationLevel)\b/ ? $_ : () }
  @{ $data->{ATTRIBUTES} };
ok( @hiddenAttributes == 2, 'Hidden attributes found' )
  or explain( \@hiddenAttributes, 'Hidden attributes' );
count(3);
$client->logout($id);

## Try to authenticate
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
( $host, $url, $query ) = expectForm( $res, '#', undef, 'user', 'password' );
$query =~ s/user=/user=msmith/;
$query =~ s/password=/password=msmith/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Auth query'
);
count(2);
$id = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

# CheckUser form
# ------------------------
ok(
    $res = $client->_get(
        '/checkuser', cookie => "lemonldap=$id"
    ),
    'GET CheckUser',
);

$data = eval { JSON::from_json( $res->[2]->[0] ) };
ok( not($@), ' Content is JSON' )
  or explain( [ $@, $res->[2] ], 'JSON content' );
@hiddenAttributes =
  map { $_->{key} =~ /\b(?:hGroups|authenticationLevel)\b/ ? $_ : () }
  @{ $data->{ATTRIBUTES} };
ok( @hiddenAttributes == 0, 'No hidden attribute found' )
  or explain( \@hiddenAttributes, 'No hidden attribute' );
count(3);
$client->logout($id);

clean_sessions();

done_testing( count() );
