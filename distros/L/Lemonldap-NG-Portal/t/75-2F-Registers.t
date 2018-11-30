use Test::More;
use strict;
use IO::String;
use Data::Dumper;

require 't/test-lib.pm';
my $maintests = 29;

SKIP: {
    eval { require Convert::Base32 };
    if ($@) {
        skip 'Convert::Base32 is missing', $maintests;
    }

    eval { require Crypt::U2F::Server; require Authen::U2F::Tester };
    if ( $@ or $Crypt::U2F::Server::VERSION < 0.42 ) {
        skip 'Missing libraries', $maintests;
    }

    require Lemonldap::NG::Common::TOTP;

    my $client = LLNG::Manager::Test->new(
        {
            ini => {
                logLevel               => 'error',
                totp2fSelfRegistration => 1,
                totp2fActivation       => 1,
                u2fSelfRegistration    => 1,
                u2fActivation          => 1,
                portalMainLogo         => 'common/logos/logo_llng_old.png',
            }
        }
    );
    my $res;

    # Try to authenticate
    # -------------------
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23
        ),
        'Auth query'
    );
    my $id = expectCookie($res);

    # TOTP form
    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form registration'
    );

    #expectRedirection( $res, qr#/2fregisters/totp$# );
    ok(
        $res = $client->_get(
            '/2fregisters/totp',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form registration'
    );
    ok( $res->[2]->[0] =~ /totpregistration\.(?:min\.)?js/, 'Found TOTP js' );
    ok(
        $res->[2]->[0] =~ qr%<img src="/static/common/logos/logo_llng_old.png"%,
        'Found custom Main Logo'
    ) or print STDERR Dumper( $res->[2]->[0] );
    count(1);

    # JS query
    ok(
        $res = $client->_post(
            '/2fregisters/totp/getkey', IO::String->new(''),
            cookie => "lemonldap=$id",
            length => 0,
        ),
        'Get new key'
    );
    eval { $res = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), 'Content is JSON' )
      or explain( $res->[2]->[0], 'JSON content' );
    my ( $key, $token );
    ok( $key   = $res->{secret}, 'Found secret' );
    ok( $token = $res->{token},  'Found token' );
    $key = Convert::Base32::decode_base32($key);

    # Post code
    my $code;
    ok( $code = Lemonldap::NG::Common::TOTP::_code( undef, $key, 0, 30, 6 ),
        'Code' );
    ok( $code =~ /^\d{6}$/, 'Code contains 6 digits' );
    my $s = "code=$code&token=$token";
    ok(
        $res = $client->_post(
            '/2fregisters/totp/verify',
            IO::String->new($s),
            length => length($s),
            cookie => "lemonldap=$id",
        ),
        'Post code'
    );
    eval { $res = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), 'Content is JSON' )
      or explain( $res->[2]->[0], 'JSON content' );
    ok( $res->{result} == 1, 'Key is registered' );

    # Try to sign-in
    $client->logout($id);
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
            accept => 'text/html',
        ),
        'Auth query'
    );
    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/totp2fcheck', 'token' );
    ok( $code = Lemonldap::NG::Common::TOTP::_code( undef, $key, 0, 30, 6 ),
        'Code' );
    $query =~ s/code=/code=$code/;
    ok(
        $res = $client->_post(
            '/totp2fcheck', IO::String->new($query),
            length => length($query),
        ),
        'Post code'
    );
    $id = expectCookie($res);

    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form 2fregisters'
    );
    ok( $res->[2]->[0] =~ /2fregistration\.(?:min\.)?js/,
        'Found 2f registration js' );

    ok( $res->[2]->[0] =~ qr%<img src="/static/bootstrap/totp.png".*?/>%,
        'Found totp.png' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ qr%<img src="/static/bootstrap/u2f.png".*?/>%,
        'Found u2f.png' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ qr%<a href="/2fregisters/u".*?>%,
        'Found 2fregisters/u link' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ qr%<a href="/2fregisters/totp".*?>%,
        'Found 2fregisters/totp link' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ qr%TOTP.*epoch.*(\d{10})%m, "TOTP epoch $1 found" )
      or print STDERR Dumper( $res->[2]->[0] );

    ok(
        $res = $client->_post(
            '/2fregisters/totp/delete',
            IO::String->new("epoch=$1"),
            length => 16,
            cookie => "lemonldap=$id",
        ),
        'Delete TOTP query'
    );

    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form 2fregisters'
    );

    ok( $res->[2]->[0] =~ /2fregistration\.(?:min\.)?js/,
        'Found 2f registration js' );
    ok( $res->[2]->[0] =~ qr%<a href="/2fregisters/u" class="nodecor">%,
        'Found 2fregisters/u link' )
      or print STDERR Dumper($res);
    ok( $res->[2]->[0] =~ qr%<a href="/2fregisters/totp" class="nodecor">%,
        'Found 2fregisters/totp link' )
      or print STDERR Dumper($res);
    ok(
        $res->[2]->[0] !~
qr%<td class="align-middle" >TOTP</td><td class="align-middle">(\d{10})</td><td class="data-epoch">\d{10}</td>%,
        "TOTP deleted"
    ) or print STDERR Dumper( $res->[2]->[0] );

    $client->logout($id);
}
count($maintests);

clean_sessions();

done_testing( count() );

