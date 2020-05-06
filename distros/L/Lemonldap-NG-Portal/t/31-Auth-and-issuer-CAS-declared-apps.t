use lib 'inc';
use Test::More;    # skip_all => 'CAS is in rebuild';
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
}

my $debug = 'error';
my ( $issuer, $sp, $res );

eval { require XML::Simple };
plan skip_all => "Missing dependencies: $@" if ($@);

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.((?:id|s)p).com([^\?]*)(?:\?(.*))?$#,
            'SOAP request' );
        my $host  = $1;
        my $url   = $2;
        my $query = $3;
        my $res;
        my $client = ( $host eq 'idp' ? $issuer : $sp );
        if ( $req->method eq 'POST' ) {
            my $s = $req->content;
            ok(
                $res = $client->_post(
                    $url, IO::String->new($s),
                    length => length($s),
                    query  => $query,
                    type   => 'application/xml',
                ),
                "Execute POST request to $url"
            );
        }
        else {
            ok(
                $res = $client->_get(
                    $url,
                    type  => 'application/xml',
                    query => $query,
                ),
                "Execute request to $url"
            );
        }
        expectOK($res);
        ok( getHeader( $res, 'Content-Type' ) =~ m#xml#, 'Content is XML' )
          or explain( $res->[1], 'Content-Type => application/xml' );
        count(3);
        return $res;
    }
);

$issuer = register( 'issuer', \&issuer );
$sp     = register( 'sp',     \&sp );

# Simple SP access
ok(
    $res = $sp->_get(
        '/', accept => 'text/html',
    ),
    'Unauth SP request'
);
count(1);

# No cancel button found
ok(
    $res->[2]->[0] !~
qr%<a href="http://auth.sp.com\?cancel=1" class="btn btn-primary" role="button">%,
    'Cancel button NOT found'
) or print STDERR Dumper( $res->[2]->[0] );
count(1);

# Query IdP
switch ('issuer');
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

clean_sessions();
done_testing( count() );

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => $debug,
                domain                     => 'idp.com',
                portal                     => 'http://auth.idp.com',
                authentication             => 'Demo',
                userDB                     => 'Same',
                issuerDBCASActivation      => 1,
                issuerDBCASRule            => '$uid eq "french"',
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
                        casAppMetaDataOptionsService => 'http://auth.sp.com',
                    },
                    sp2 => {
                        casAppMetaDataOptionsService => 'http://auth.sp2.com',
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
                portal                => 'http://auth.sp.com',
                authentication        => 'CAS',
                userDB                => 'CAS',
                compactConf           => 1,
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
                    },
                    idp2 => {
                        cn   => 'cn',
                        mail => 'mail',
                        uid  => 'uid',
                    }
                },
                casSrvMetaDataOptions => {
                    idp => {
                        casSrvMetaDataOptionsUrl => 'http://auth.idp.com/cas',
                        casSrvMetaDataOptionsGateway => 0,
                    },
                    idp2 => {
                        casSrvMetaDataOptionsUrl => 'http://auth.idp.com/cas',
                        casSrvMetaDataOptionsGateway => 0,
                    }
                },
            },
        }
    );
}
