use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;
my $maintests = 7;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => 'error',
            authentication => 'Choice',
            userDB         => 'Same',
            passwordDB     => 'Choice',

            authChoiceParam   => 'lmAuth',
            authChoiceModules => {
                slavechoice => 'Slave;Demo;Demo',
            },

            slaveUserHeader  => 'userid',
            slaveDisplayLogo => 1,

            rememberAuthChoiceRule => 1,
            rememberCookieName     => "llngrememberauthchoice",
            rememberCookieTimeout  => 31536000,
            rememberDefaultChecked => 0,
            rememberTimer          => 10,
        }
    }
);

# Check web form
ok( $res = $client->_get( '/', accept => 'text/html' ),
    'Get authentication portal' );
my @form = ( $res->[2]->[0] =~ m#<form.*?</form>#sg );
ok( @form == 1, 'Display 1 choice' ) or explain( scalar(@form), 1 );
expectForm( [ $res->[0], $res->[1], [ $form[0] ] ], undef, undef, 'lmAuth' );
ok( $form[0] =~ /input type="hidden" id="rememberauthchoice"/ );

# authentication with rememberauthchoice enabled
ok(
    $res = $client->_get(
        '/',
        'accept' => 'text/html',
        'query'  => 'lmAuth=slavechoice&rememberauthchoice=true',
        'custom' => { 'HTTP_USERID' => 'dwho' }
    ),
    'Auth query with rememberauthchoice enabled'
);
my $id       = expectCookie($res);
my $remember = expectCookie( $res, "llngrememberauthchoice" );
ok( $remember eq "slavechoice", 'Get cookie with authentication' );

$client->logout($id);

# authentication with rememberauthchoice disabled
ok(
    $res = $client->_get(
        '/',
        'accept' => 'text/html',
        'query'  => 'lmAuth=slavechoice&rememberauthchoice=false',
        'custom' => { 'HTTP_USERID' => 'dwho' }
    ),
    'Auth query with rememberauthchoice disabled'
);
$id       = expectCookie($res);
$remember = expectCookie( $res, "llngrememberauthchoice" );
ok( $remember eq "0", 'Get cookie removal' );

$client->logout($id);

count($maintests);
clean_sessions();
done_testing( count() );
