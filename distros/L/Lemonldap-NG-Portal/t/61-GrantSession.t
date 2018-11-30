use Test::More;
use strict;
use IO::String;
use Data::Dumper;

BEGIN {
    require 't/test-lib.pm';
}

my $res;

my $client = LLNG::Manager::Test->new(
    {
        ini => {
            logLevel          => 'error',
            authentication    => 'Demo',
            userdb            => 'Same',
            portalMainLogo    => 'common/logos/logo_llng_old.png',
            grantSessionRules => {
                '$uid . " not allowed"##rule1' => '$uid ne "dwho"',
                'Rtyler_Allowed##rule3'        => '$uid eq "rtyler"',
                '##rule2'                      => '$uid ne "mrsmith"',
            }
        }
    }
);

ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        accept => 'text/html',
        length => 23
    ),
    'Auth query'
);
count(1);
ok( $res->[2]->[0] =~ /<h3 trspan="dwho not allowed">dwho not allowed<\/h3>/,
    'dwho rejected with custom message and session data' )
  or print STDERR Dumper( $res->[2]->[0] );
count(1);
ok( $res->[2]->[0] =~ qr%src="/static/common/js/info.(?:min\.)?js"></script>%,
    'Found INFO js' )
  or print STDERR Dumper( $res->[2]->[0] );
count(1);
ok( $res->[2]->[0] =~ qr%<img src="/static/common/logos/logo_llng_old.png"%,
    'Found custom Main Logo' )
  or print STDERR Dumper( $res->[2]->[0] );
count(1);
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=rtyler&password=rtyler'),
        length => 27
    ),
    'Auth query'
);
count(1);
expectOK($res);
expectCookie($res);

ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=mrsmith&password=mrsmith'),
        accept => 'text/html',
        length => 29
    ),
    'Auth query'
);
count(1);
ok(
    $res->[2]->[0] =~ /<span trmsg="4"><\/span><\/div>/,
    'rtyler rejected with PE_SESSIONNOTGRANTED'
) or print STDERR Dumper( $res->[2]->[0] );
count(1);
ok( $res->[2]->[0] =~ qr%<img src="/static/common/logos/logo_llng_old.png"%,
    'Found custom Main Logo' )
  or print STDERR Dumper( $res->[2]->[0] );
count(1);

my $c = getCookies($res);
ok( not(%$c), 'No cookie' );
count(1);

&Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
$client = LLNG::Manager::Test->new(
    {
        ini => {
            authentication    => 'Demo',
            userdb            => 'Same',
            grantSessionRules => { '' => '$uid eq "dwho"', }
        }
    }
);

ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23
    ),
    'auth query'
);
count(1);
expectOK($res);
expectCookie($res);

clean_sessions();

done_testing( count() );
