use warnings;
use Test::More;    # skip_all => 'CAS is in rebuild';
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;
use Plack::Builder;

BEGIN {
    require 't/test-lib.pm';
}

my $debug = 'error';
my ( $issuer, $sp, $res );

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register(
    builder {
        enable sub {
            my $app = shift;
            sub {
                ok( my $res = $app->(@_) );
                expectOK($res);
                ok( getHeader( $res, 'Content-Type' ) =~ m#xml#,
                    'Content is XML' )
                  or explain( $res->[1], 'Content-Type => application/xml' );
                count(2);
                return $res;
            };
        };
        mount "http://auth.idp.com/" => sub { goto $issuer->app };
        mount "http://auth.sp.com/"  => sub { goto $sp->app };
        mount "/"                    => denyLwpRequests;
    },
);

SKIP: {

    my $sp = register( 'sp', \&sp );

    subtest
      "SP-initiated flow, authorized user without activation configuration" =>
      sub {
        my $issuer = register( 'issuer', sub { get_issuer() } );
        test_activation( $issuer, $sp, 1 );
      };

    subtest
      "SP-initiated flow, authorized user with activation configuration" =>
      sub {
        my $issuer = register( 'issuer',
            sub { get_issuer( casAppMetaDataOptionsActivation => 1 ) } );
        test_activation( $issuer, $sp, 1 );
      };

    subtest
      "SP-initiated flow, authorized user with deactivation configuration" =>
      sub {
        my $issuer = register( 'issuer',
            sub { get_issuer( casAppMetaDataOptionsActivation => 0 ) } );
        test_activation( $issuer, $sp, 0 );
      };
}

sub test_activation {
    my ( $issuer, $sp, $activation ) = @_;

    # Simple SP access
    ok(
        $res = $sp->_get(
            '/', accept => 'text/html',
        ),
        'Unauth SP request'
    );
    count(1);
    expectRedirection( $res,
        'http://auth.idp.com/cas/login?service=http%3A%2F%2Fauth.sp.com%2F' );

    # Query IdP
    ok(
        $res = $issuer->_get(
            '/cas/login',
            query  => 'service=http://auth.sp.com/',
            accept => 'text/html'
        ),
        'Query CAS server'
    );
    count(1);
    expectOK($res);
    my $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Try to authenticate with an authorized to IdP
    my $body = $res->[2]->[0];
    $body =~ s/^.*?<form.*?>//s;
    $body =~ s#</form>.*$##s;
    my %fields =
      ( $body =~ /<input type="hidden".+?name="(.+?)".+?value="(.*?)"/sg );
    $fields{user} = $fields{password} = 'french';
    use URI::Escape;
    my $s = join( '&', map { "$_=" . uri_escape( $fields{$_} ) } keys %fields );
    ok(
        $res = $issuer->_post(
            '/cas/login',
            IO::String->new($s),
            cookie => $pdata,
            accept => 'text/html',
            length => length($s),
        ),
        'Post authentication'
    );

    if ($activation) {
        expectRedirection( $res, qr'http://auth.sp.com/\?ticket=(.*)' );
    }
    else {
        expectPortalError( $res, 107 );
    }
}

clean_sessions();
done_testing();

sub get_issuer {
    my %activation_configurations = @_;
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => $debug,
                domain                     => 'idp.com',
                portal                     => 'http://auth.idp.com/',
                authentication             => 'Demo',
                userDB                     => 'Same',
                issuerDBCASActivation      => 1,
                issuerDBCASRule            => '1',
                casAttr                    => 'uid',
                casAccessControlPolicy     => 'error',
                multiValuesSeparator       => ';',
                casAppMetaDataExportedVars => {
                    sp => {
                        cn   => 'cn',
                        mail => 'mail',
                        uid  => 'uid',
                    }
                },
                casAppMetaDataOptions => {
                    sp => {
                        %activation_configurations,
                        casAppMetaDataOptionsService => 'http://auth.sp.com',
                    },
                },
            }
        }
    );
}

sub sp {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel              => $debug,
                domain                => 'sp.com',
                portal                => 'http://auth.sp.com/',
                authentication        => 'CAS',
                userDB                => 'CAS',
                restSessionServer     => 1,
                issuerDBCASActivation => 0,
                multiValuesSeparator  => ';',
                exportedVars          => {
                    cn => 'cn',
                },
                casSrvMetaDataExportedVars => {
                    idp => {
                        cn   => 'cn',
                        mail => 'mail',
                        uid  => 'uid',
                    }
                },
                casSrvMetaDataOptions => {
                    idp => {
                        casSrvMetaDataOptionsUrl => 'http://auth.idp.com/cas',
                        casSrvMetaDataOptionsGateway => 0,
                    }
                },
            },
        }
    );
}
