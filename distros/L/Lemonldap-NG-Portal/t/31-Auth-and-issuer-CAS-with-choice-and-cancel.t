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
my $userdb = tempdb();

my $maintests = 12;
my $debug     = 'error';
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
    eval { require DBI; require DBD::SQLite; };
    if ($@) {
        skip 'DBD::SQLite not found', $maintests;
    }

    # Build SQL DB
    my $dbh = DBI->connect("dbi:SQLite:dbname=$userdb");
    $dbh->do(
'CREATE TABLE users (user text,password text,name text,uid text,cn text,mail text)'
    );
    $dbh->do(
"INSERT INTO users VALUES ('dwho','dwho','Doctor who','dwho','Doctor who','dwho\@badwolf.org')"
    );

    # Build CAS server
    $issuer = register( 'issuer', \&issuer );

    # Build CAS App
    $sp = register( 'sp', \&sp );

    # Simple SP access
    # Connect to CAS app
    ok(
        $res = $sp->_get(
            '/', accept => 'text/html',
        ),
        'Unauth SP request'
    );
    ok( $res->[2]->[0] =~ s#^.*(<form [^>]*CAS.*?</form>).*$#$1#s,
        'Found CAS entry' );

    my ( $host, $url, $query ) = expectForm($res);
    ok(
        $res = $sp->_get(
            '/',
            accept => 'text/html',
            query  => $query,
        ),
        'Unauth SP request'
    );

    # CAS idp must be sorted
    my @idp = map /idploop py-3" val="(.+?)">/g, $res->[2]->[0];
    ok( $idp[0] eq 'idp',  '1st = idp' )  or print STDERR Dumper( \@idp );
    ok( $idp[1] eq 'idp3', '2nd = idp3' ) or print STDERR Dumper( \@idp );
    ok( $idp[2] eq 'idp4', '3rd = idp4' ) or print STDERR Dumper( \@idp );
    ok( $idp[3] eq 'idp2', '4th= idp2' )  or print STDERR Dumper( \@idp );

    # Found Cancel button
    ok(
        $res->[2]->[0] =~
qr%<a href="http://auth.sp.com\/\?cancel=1" class="btn btn-primary" role="button">%,
        'Found Cancel button'
    ) or print STDERR Dumper( $res->[2]->[0] );

    # Found CAS idp logo and display name
    ok(
        $res->[2]->[0] =~
qr%<img src="/static/common/icons/sfa_manager.png" class="mr-2" alt="idp4" title="My_tooltip" />%,
        'Found CAS idp logo and tooltip'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ qr%CAS1%, 'Found CAS idp display name' )
      or print STDERR Dumper( $res->[2]->[0] );

    my $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    expectForm( $res, undef, undef );
    ok(
        $res = $sp->_get(
            '/',
            accept => 'text/html',
            query  => 'cancel=1',
            cookie => $pdata,
        ),
        'Cancel query'
    );
    $pdata = expectCookie( $res, 'lemonldappdata' );
    ok( $pdata eq '', 'pdata is empty' );
}

clean_sessions();
count($maintests);
done_testing( count() );

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                skipRenewConfirmation => 1,
                logLevel              => $debug,

                domain                   => 'idp.com',
                portal                   => 'http://auth.idp.com/',
                authentication           => 'Demo',
                userDB                   => 'Same',
                issuerDBCASActivation    => 1,
                casAttr                  => 'uid',
                casAttributes            => { cn => 'cn', uid => 'uid', },
                casAccessControlPolicy   => 'none',
                multiValuesSeparator     => ';',
                portalForceAuthnInterval => -1,
            }
        }
    );
}

sub sp {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel          => $debug,
                domain            => 'sp.com',
                portal            => 'http://auth.sp.com/',
                authentication    => 'Choice',
                userDB            => 'Same',
                authChoiceParam   => 'test',
                authChoiceModules => {
                    cas => 'CAS;CAS;Null',
                    sql => 'DBI;DBI;DBI',
                },
                dbiAuthChain               => "dbi:SQLite:dbname=$userdb",
                dbiAuthUser                => '',
                dbiAuthPassword            => '',
                dbiAuthTable               => 'users',
                dbiAuthLoginCol            => 'user',
                dbiAuthPasswordCol         => 'password',
                dbiAuthPasswordHash        => '',
                multiValuesSeparator       => ';',
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
                    },
                    idp3 => {
                        cn   => 'cn',
                        mail => 'mail',
                        uid  => 'uid',
                    },
                    idp4 => {
                        cn   => 'cn',
                        mail => 'mail',
                        uid  => 'uid',
                    },
                },
                casSrvMetaDataOptions => {
                    idp => {
                        casSrvMetaDataOptionsUrl => 'http://auth.idp.com/cas',
                        casSrvMetaDataOptionsGateway     => 0,
                        casSrvMetaDataOptionsDisplayName => 'CAS1',
                    },
                    idp2 => {
                        casSrvMetaDataOptionsUrl => 'http://auth.idp.com/cas',
                        casSrvMetaDataOptionsGateway    => 0,
                        casSrvMetaDataOptionsSortNumber => 5,
                    },
                    idp3 => {
                        casSrvMetaDataOptionsUrl => 'http://auth.idp.com/cas',
                        casSrvMetaDataOptionsGateway => 0,
                    },
                    idp4 => {
                        casSrvMetaDataOptionsUrl => 'http://auth.idp.com/cas',
                        casSrvMetaDataOptionsGateway => 0,
                        casSrvMetaDataOptionsIcon    => 'icons/sfa_manager.png',
                        casSrvMetaDataOptionsTooltip => 'My_tooltip',
                        casSrvMetaDataOptionsSortNumber => 2,
                    },
                },
            },
        }
    );
}
