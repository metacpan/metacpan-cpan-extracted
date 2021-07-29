use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';
my $maintests = 21;

SKIP: {
    eval {
        require Convert::Base32;
        require XML::LibXML;
        require XML::LibXSLT;
    };
    if ($@) {
        skip 'Convert::Base32 is missing', $maintests;
    }
    require Lemonldap::NG::Common::TOTP;

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => 'error',
                totp2fSelfRegistration     => 1,
                totp2fActivation           => 1,
                totp2fTTL                  => 120,
                sfRemovedMsgRule           => '$uid eq "dwho"',
                sfRemovedUseNotif          => 1,
                sfRemovedNotifRef          => 'Remove_TOTP',
                portalMainLogo             => 'common/logos/logo_llng_old.png',
                notification               => 1,
                notificationStorage        => 'File',
                notificationStorageOptions => { dirName => $main::tmpDir },
                oldNotifFormat             => 1,
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
    expectRedirection( $res, qr#/2fregisters/totp$# );
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
    my $s = "code=$code&token=$token&TOTPName=myTOTP";
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
    $client->logout($id);

    # Skipping time until TOTP expiration
    Time::Fake->offset("+5m");

    # Try to sign-in
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
            accept => 'text/html',
        ),
        'Auth query'
    );
    expectOK($res);
    ok(
        $res->[2]->[0] =~
qr%<input type="hidden" name="reference1x1" value="Remove-TOTP-(\d{10})">%,
        'Notification reference found'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok( time() + 295 <= $1 && $1 <= time() + 305, 'Right reference found' )
      or print STDERR Dumper( $res->[2]->[0] ), time(), " / $1";
    ok(
        $res->[2]->[0] =~
qr%<p class="notifText">1 expired second factor\(s\) has/have been removed \(myTOTP\)!</p>%,
        'Notification message found'
    ) or print STDERR Dumper( $res->[2]->[0] );
    $id = expectCookie($res);
    $client->logout($id);
}
count($maintests);
system 'rm -f t/*_dwho_*.xml';
clean_sessions();

done_testing( count() );
