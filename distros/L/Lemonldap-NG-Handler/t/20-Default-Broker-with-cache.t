use Test::More;
use Time::Fake;
use File::Temp 'tempdir';

require 't/test-psgi-lib.pm';

my $cacheDir = tempdir( CLEANUP => 1 );

init(
    'Lemonldap::NG::Handler::PSGI',
    {
        localStorage        => 'Cache::FileCache',
        localStorageOptions => {
            namespace            => 'lemonldap-ng-config',
            default_expires_in   => 600,
            cache_root           => $cacheDir,
            cache_depth          => 3,
            allow_cache_for_root => 1,
        },
    }
);

my $res;
unlink 't/lmConf-2.json', 't/lmConf-3.json';

# Check current conf
ok( $res = $client->_get( '/deny', undef, undef, "lemonldap=$sessionId" ),
    'Denied query' );
ok( $res->[0] == 403, ' Code is 403' ) or explain( $res->[0], 403 );

newConf( 1, '/deny', '/deny2' );

Time::Fake->offset('+6s');
ok( $res = $client->_get( '/deny', undef, undef, "lemonldap=$sessionId" ),
    'Denied query' );
ok( $res->[0] == 200, ' Conf was updated' ) or explain( $res->[0], 200 );

newConf( 2, '/deny2', '/deny' );

Time::Fake->offset('+12s');
ok( $res = $client->_get( '/deny', undef, undef, "lemonldap=$sessionId" ),
    'Denied query' );
ok( $res->[0] == 403, ' Conf was updated' ) or explain( $res->[0], 403 );

unlink(
't/sessions/lock/Apache-Session-e5eec18ebb9bc96352595e2d8ce962e8ecf7af7c9a98cb9a43f9cd181cf4b545.lock',
    't/lmConf-2.json', 't/lmConf-3.json',
);

done_testing();

clean();

sub newConf {
    my ( $cfgNum, $src, $dst ) = @_;
    my $next = $cfgNum + 1;
    open my $cur, '<', "t/lmConf-$cfgNum.json";
    open my $new, '>', "t/lmConf-$next.json";

    while ( my $line = <$cur> ) {
        $line =~ s/("cfgNum")\s*:\s*"?$cfgNum"?"?/$1:$next/;
        $line =~ s#$src#$dst#;
        print $new $line;
    }
    $new->close;
    $cur->close;
}

sub Lemonldap::NG::Handler::PSGI::handler {
    my ( $self, $req ) = @_;
    if ($SKIPUSER) {
        ok( !$req->env->{HTTP_AUTH_USER}, 'No HTTP_AUTH_USER' )
          or explain( $req->env->{HTTP_AUTH_USER}, '<empty>' );
    }
    else {
        ok( $req->env->{HTTP_AUTH_USER} eq 'dwho', 'Header is given to app' )
          or explain( $req->env->{HTTP_AUTH_USER}, 'dwho' );
    }
    count(1);
    return [ 200, [ 'Content-Type', 'text/plain' ], ['Hello'] ];
}
