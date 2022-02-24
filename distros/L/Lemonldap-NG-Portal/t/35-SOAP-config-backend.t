use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;

BEGIN {
    require 't/test-lib.pm';
}

my $maintests = 8;
my $debug     = 'error';
my ( $issuer, $sp, $res );

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.((?:id|s)p).com(.*)#,
            ' @ SOAP REQUEST @' );
        my $host = $1;
        my $url  = $2;
        my $res;
        my $s      = $req->content;
        my $client = ( $host eq 'idp' ? $issuer : $sp );
        ok(
            $res = $client->_post(
                $url,
                IO::String->new($s),
                length => length($s),
                type   => $req->header('Content-Type'),
                custom => {
                    HTTP_SOAPACTION => $req->header('Soapaction'),
                },
            ),
            ' Execute request'
        );
        expectOK($res);
        ok( getHeader( $res, 'Content-Type' ) =~ m#^(?:text|application)/xml#,
            ' Content is XML' )
          or explain( $res->[1], 'Content-Type => application/xml' );
        pass(' @ END OF SOAP REQUEST @');
        count(4);
        return $res;
    }
);

SKIP: {
    eval 'use SOAP::Lite';
    if ($@) {
        skip 'SOAP::Lite not found', $maintests;
    }

    $issuer = register( 'issuer', \&issuer );

    # Test SOAP config backend
    my $soap = SOAP::Lite->new( proxy => 'http://auth.idp.com/config' );
    $soap->default_ns('urn:Lemonldap/NG/Common/PSGI/SOAPService');

    # Call SOAP methods
    ok( $soap->call('lastCfg')->result() == 1, 'Last cfg is 1' );

    my $res;
    ok( $res = $soap->call('getConfig')->result(), 'Get configuration' );
    ok( $res->{cfgNum} == 1,                       'cfgNum is 1' );

    $sp = register( 'sp', \&sp );

    # Simple SP access
    ok(
        $res = $sp->_get(
            '/', accept => 'text/html',
        ),
        'Unauth SP request'
    );
    expectOK($res);

    # Try to auth
    ok(
        $res = $sp->_post(
            '/', IO::String->new('user=dwho&password=dwho'),
            length => 23,
            accept => 'text/html'
        ),
        'Post user/password'
    );
    expectRedirection( $res, 'http://auth.sp.com' );
    my $spId = expectCookie($res);

    # Test if we're authenticated
    ok( $res = $sp->_get( '/', cookie => "lemonldap=$spId" ),
        'Try to get menu' );
    expectOK($res);

    # Logout
    ok(
        $res = $sp->_get(
            '/',
            query  => 'logout',
            accept => 'text/html',
            cookie => "lemonldap=$spId"
        ),
        'Ask for logout'
    );
    expectOK($res);

    # Test if logout is done
    ok(
        $res = $sp->_get(
            '/', cookie => "lemonldap=$spId",
        ),
        'Test if user is reject on IdP'
    );
    expectReject($res);
}

count($maintests);
clean_sessions();
done_testing( count() );

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel         => $debug,
                domain           => 'idp.com',
                portal           => 'http://auth.idp.com',
                authentication   => 'Demo',
                userDB           => 'Same',
                soapConfigServer => 1,
            }
        }
    );
}

sub sp {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel       => $debug,
                domain         => 'sp.com',
                portal         => 'http://auth.sp.com',
                authentication => 'Demo',
                userDB         => 'Same',
                configStorage  => {
                    type  => 'SOAP',
                    proxy => 'http://auth.idp.com/config',
                },
            },
        }
    );
}
