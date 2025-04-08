# Test 2F API

use warnings;
use Test::More;
use strict;
use JSON;
use IO::String;
use Lemonldap::NG::Common::Session;
use Lemonldap::NG::Common::TOTP;

eval { mkdir 't/sessions' };
`rm -rf t/sessions/*`;

require 't/test-lib.pm';

our $_json = JSON->new->allow_nonref;

sub newSession {
    my ( $uid, $ip, $kind, $sfaDevices ) = splice @_;
    my $tmp;
    ok(
        $tmp = Lemonldap::NG::Common::Session->new( {
                storageModule        => 'Apache::Session::File',
                storageModuleOptions => {
                    Directory      => 't/sessions',
                    LockDirectory  => 't/sessions',
                    backend        => 'Apache::Session::File',
                    generateModule =>
'Lemonldap::NG::Common::Apache::Session::Generate::SHA256',
                },
            }
        ),
        'Sessions module'
    );
    count(1);
    ok(
        $tmp->update( {
                ipAddr        => $ip,
                _whatToTrace  => $uid,
                uid           => $uid,
                _session_uid  => $uid,
                _utime        => time,
                _session_kind => $kind,
                (
                    defined $sfaDevices
                    ? ( _2fDevices => to_json($sfaDevices) )
                    : ()
                ),
            }
        ),
        "New $kind session for $uid"
    );
    count(1);
    return $tmp->id;
}

sub get2fDevices {
    my ($id) = @_;
    my $tmp;
    ok(
        $tmp = Lemonldap::NG::Common::Session->new( {
                storageModule        => 'Apache::Session::File',
                storageModuleOptions => {
                    Directory      => 't/sessions',
                    LockDirectory  => 't/sessions',
                    backend        => 'Apache::Session::File',
                    generateModule =>
'Lemonldap::NG::Common::Apache::Session::Generate::SHA256',
                },
                id => $id,
            }
        ),
        'Sessions module'
    );
    count(1);
    return from_json( $tmp->data->{_2fDevices}, { allow_nonref => 1 } );
}

sub checkTotpData {
    my ( $totp, $key, %attr ) = @_;

    is( $totp->{type}, "TOTP", "Correct type" );
    ok( $totp->{epoch}, "Epoch was set" );
    while ( my ( $k, $v ) = each %attr ) {
        is( $totp->{$k}, $v, "Correct $k" );
    }

    like( $totp->{_secret}, qr/llngcrypt/, "Secret was encrypted" );

    my $totp_decrypt = Lemonldap::NG::Common::TOTP->new(
        key           => "abc",
        encryptSecret => 1,
    );

    is( $totp_decrypt->get_cleartext_secret( $totp->{_secret} ),
        $key, "Correct normalized key" );

}

sub check200 {
    my ( $test, $res ) = splice @_;
    ok( $res->[0] == 200, "$test: Result code is 200" );
    count(1);
    checkJson( $test, $res );
}

sub check201 {
    my ( $test, $res ) = splice @_;

    is( $res->[0], "201", "$test: Result code is 201" );
    count(1);
    checkJson( $test, $res );
}

sub check204 {
    my ( $test, $res ) = splice @_;

    is( $res->[0], "204", "$test: Result code is 204" );
    count(1);
    is( $res->[2]->[0], undef, "204 code returns no content" );
}

sub check400 {
    my ( $test, $res, $regex ) = splice @_;
    ok( $res->[0] == 400, "$test: Result code is 400" );
    count(1);
    checkJson( $test, $res, $regex );
}

sub check404 {
    my ( $test, $res ) = splice @_;
    ok( $res->[0] == 404, "$test: Result code is 404" );
    count(1);
    checkJson( $test, $res );
}

sub check409 {
    my ( $test, $res ) = splice @_;
    is( $res->[0], "409", "$test: Result code is 409" );
    count(1);
    checkJson( $test, $res );
}

sub checkJson {
    my ( $test, $res, $regex ) = splice @_;
    my $key;

    #diag Dumper($res->[2]->[0]);
    ok( $key = from_json( $res->[2]->[0] ), "$test: Response is JSON" );
    if ($regex) {
        like( $key->{error}, $regex, "Expected error message" );
        count(1);
    }
    count(1);
}

sub checkSearchNotFound {
    my ($params) = @_;
    my $test =
      "Searching for " . ( $params || '[no params]' ) . " returns no results";
    my $res = search( $test, $params );
    check200( $test, $res );
    my $result = from_json( $res->[2]->[0] );
    is_deeply( $result, [], "Empty list was returned" );
}

sub checkSearch {
    my ( $params, $expected_list ) = @_;
    $expected_list ||= [];
    my $test =
        "Searching for "
      . ( $params || '[no params]' )
      . " returns "
      . join( ",", @$expected_list );
    my $res = search( $test, $params );
    check200( $test, $res );
    my $result = from_json( $res->[2]->[0] );
    my @names  = map { $_->{uid} } @$result;
    is_deeply( [ sort @names ], $expected_list, "Expected results" );
    return $result;
}

sub search {
    my ( $test, $params ) = @_;
    ok( my $res = &client->_get( "/api/v1/secondFactor", $params ),
        "$test: Request succeed" );
    count(1);
    return $res;
}

sub get {
    my ( $test, $uid, $type, $id ) = splice @_;
    my ($res);
    ok(
        $res = &client->_get(
            "/api/v1/secondFactor/$uid"
              . (
                defined $type ? "/type/$type" : ( defined $id ? "/id/$id" : "" )
              )
        ),
        "$test: Request succeed"
    );
    count(1);
    return $res;
}

sub checkGet {
    my ( $uid, $id ) = splice @_;
    my ( $test, $res, $ret );
    $test = "$uid should have one 2F with id \"$id\"";
    $res  = get( $test, $uid, undef, $id );
    check200( $test, $res );

    #diag Dumper($res);
    $ret = from_json( $res->[2]->[0] );
    ok( ref $ret eq 'HASH' && $ret->{id} eq $id,
        "$test: check returned type is HASH and that ids match" );
    count(1);
    return $ret;
}

sub checkGet404 {
    my ( $uid, $id ) = splice @_;
    my ( $test, $res, $ret );
    $test = "$uid should not have any 2F with id \"$id\"";
    $res  = get( $test, $uid, undef, $id );
    check404( $test, $res );
}

sub checkGetList {
    my ( $expect, $uid, $type ) = splice @_;
    my ( $test, $res, $ret );
    $test = "$uid should have $expect 2F"
      . ( defined $type ? " of type \"$type\"" : "" );
    $res = get( $test, $uid, $type );
    check200( $test, $res );

    #diag Dumper($res);
    $ret = from_json( $res->[2]->[0] );
    ok(
        scalar @$ret eq $expect,
        "$test: check if nb of 2F found ("
          . scalar @$ret
          . ") equals expectation ($expect)"
    );
    count(1);
    return $ret;
}

sub checkDisplay {
    my ( $uid, $id ) = splice @_;
    my $ret = checkGet( $uid, $id );
    is( $ret->{mydisplay}, 1, "Found display variable" );
}

sub checkGetOnIds {
    my ( $uid, $ret ) = splice @_;
    foreach (@$ret) {
        checkGet( $uid, $_->{id} );
    }
}

sub checkGetOnIdsNotFound {
    my ( $uid, $ret ) = splice @_;
    foreach (@$ret) {
        checkGet404( $uid, $_->{id} );
    }
}

sub del {
    my ( $test, $uid, $type, $id ) = splice @_;
    my ($res);
    ok(
        $res = &client->_del(
            "/api/v1/secondFactor/$uid"
              . (
                defined $type ? "/type/$type" : ( defined $id ? "/id/$id" : "" )
              )
        ),
        "$test: Request succeed"
    );
    count(1);
    return $res;
}

sub checkDelete {
    my ( $uid, $id ) = splice @_;
    my ( $test, $res );
    $test = "$uid should have a 2F with id \"$id\" to be deleted.";
    $res  = del( $test, $uid, undef, $id );
    check200( $test, $res );
}

sub checkDelete404 {
    my ( $uid, $id ) = splice @_;
    my ( $test, $res );
    $test = "$uid should not have a 2F with id \"$id\" to be deleted.";
    $res  = del( $test, $uid, undef, $id );
    check404( $test, $res );
}

sub checkDeleteList {
    my ( $expect, $uid, $type ) = splice @_;
    my ( $test, $res, $ret, $countDel );
    $test =
      "Delete all 2F from $uid" . ( defined $type ? " of type \"$type\"" : "" );
    $res = del( $test, $uid, $type );
    check200( $test, $res );
    $ret = from_json( $res->[2]->[0] );
    ($countDel) = $ret->{message} =~ m/^Successful operation: ([\d]+) /i;
    $countDel = 0 unless ( defined $countDel );
    ok(
        $countDel eq $expect,
"$test: check nb of 2FA deleted ($countDel) matches expectation ($expect)"
    );
    count(1);
}

sub checkDeleteBadType {
    my ( $uid, $type ) = splice @_;
    my ( $test, $res );
    $test = "Delete for uid $uid and type \"$type\" should get rejected.";
    $res  = del( $test, $uid, $type );
    check400( $test, $res );
}

sub replace {
    my ( $test, $uid, $id, $obj ) = splice @_;
    my $j = $_json->encode($obj);
    my $res;
    ok(
        $res = &client->_put(
            "/api/v1/secondFactor/$uid/id/$id", '',
            IO::String->new($j),                'application/json',
            length($j)
        ),
        "$test: Request succeed"
    );
    count(1);
    return $res;
}

sub checkReplace {
    my ( $test, $uid, $id, $replace ) = splice @_;
    check204( $test, replace( $test, $uid, $id, $replace ) );
}

sub checkReplaceAlreadyThere {
    my ( $test, $uid, $id, $replace ) = splice @_;
    check400( $test, replace( $test, $uid, $id, $replace ) );
}

sub checkReplaceNotFound {
    my ( $test, $uid, $id, $update ) = splice @_;
    check404( $test, replace( $test, $uid, $id, $update ) );
}

sub checkReplaceWithInvalidAttribute {
    my ( $test, $uid, $id, $replace ) = splice @_;
    check400( $test, replace( $test, $uid, $id, $replace ) );
}

sub add {
    my ( $test, $uid, $type, $obj, $query ) = splice @_;
    my $j = $_json->encode($obj);
    my $res;

    my $path = $type ? "/type/$type" : "";
    ok(
        $res = &client->_post(
            "/api/v1/secondFactor/${uid}${path}", ( $query || '' ),
            IO::String->new($j), 'application/json',
            length($j)
        ),
        "$test: Request succeed"
    );
    count(1);
    return $res;
}

sub checkAdd {
    my ( $test, $uid, $type, $add, $query ) = splice @_;
    check201( $test, add( $test, $uid, $type, $add, $query ) );
}

sub checkAddFailsIfExists {
    my ( $test, $uid, $type, $add ) = splice @_;
    check409( $test, add( $test, $uid, $type, $add ) );
}

sub checkAddWithBadAttributes {
    my ( $test, $uid, $type, $add, $regex ) = splice @_;
    $regex ||= qr/Invalid input/;
    check400( $test, add( $test, $uid, $type, $add ), $regex );
}

sub checkAddWithUnknownUser {
    my ( $test, $uid, $type, $add, $query ) = splice @_;
    check404( $test, add( $test, $uid, $type, $add, $query ) );
}

sub checkAddWithUnknownType {
    my ( $test, $uid, $type, $add ) = splice @_;
    check400( $test, add( $test, $uid, $type, $add ), qr/Invalid type: $type/ );
}

my $sfaDevices = [];
my $ret;

## Sessions creation
# msmith
newSession( 'msmith', '127.10.0.1', 'SSO',        $sfaDevices );
newSession( 'msmith', '127.10.0.1', 'Persistent', $sfaDevices );

# dwho
$sfaDevices = [ {
        "name"       => "MyU2FKey",
        "type"       => "U2F",
        "_userKey"   => "123456",
        "_keyHandle" => "654321",
        "epoch"      => time
    },
    {
        "name"      => "MyTOTP",
        "type"      => "TOTP",
        "_secret"   => "123456",
        "epoch"     => time,
        "mydisplay" => 1,
    },
    {
        "name"    => "MyYubikey",
        "type"    => "UBK",
        "_secret" => "123456",
        "epoch"   => time
    },
    {
        "_credentialId"        => "abc",
        "_credentialPublicKey" => "abc",
        "_signCount"           => "65",
        "epoch"                => "1643201784",
        "name"                 => "MyFidoKey",
        "type"                 => "WebAuthn"
    },
];
newSession( 'dwho', '127.10.0.1', 'SSO',        $sfaDevices );
newSession( 'dwho', '127.10.0.1', 'Persistent', $sfaDevices );

# rtyler
$sfaDevices = [ {
        "name"       => "MyU2FKey",
        "type"       => "U2F",
        "_userKey"   => "123456",
        "_keyHandle" => "654321",
        "epoch"      => time
    },
    {
        "name"    => "MyYubikey",
        "type"    => "UBK",
        "_secret" => "123456",
        "epoch"   => time
    },
    {
        "name"    => "MyYubikey2",
        "type"    => "UBK",
        "_secret" => "654321",
        "epoch"   => time
    }
];
newSession( 'rtyler', '127.10.0.1', 'SSO',        $sfaDevices );
newSession( 'rtyler', '127.10.0.1', 'Persistent', $sfaDevices );

# davros
$sfaDevices = [ {
        "name"       => "MyU2FKey",
        "type"       => "U2F",
        "_userKey"   => "123456",
        "_keyHandle" => "654321",
        "epoch"      => time
    },
    {
        "name"    => "MyTOTP",
        "type"    => "TOTP",
        "_secret" => "123456",
        "epoch"   => time
    }
];
newSession( 'davros', '127.10.0.1', 'SSO',        $sfaDevices );
newSession( 'davros', '127.10.0.1', 'Persistent', $sfaDevices );

# tof
$sfaDevices = [ {
        "name"       => "MyU2FKey",
        "type"       => "U2F",
        "_userKey"   => "123456",
        "_keyHandle" => "654321",
        "epoch"      => time
    }
];
newSession( 'tof', '127.10.0.1', 'SSO',        $sfaDevices );
newSession( 'tof', '127.10.0.1', 'Persistent', $sfaDevices );

# donna
newSession( 'donna', '127.10.0.1', 'SSO',        [] );
newSession( 'donna', '127.10.0.1', 'Persistent', [] );

# dwho

$ret = checkGetList( 1, 'dwho', 'TOTP' );
checkDisplay( 'dwho', $ret->[0]->{id} );

checkGetList( 1, 'dwho', 'U2F' );
checkGetList( 1, 'dwho', 'UBK' );
checkGetList( 1, 'dwho', 'WebAuthn' );
checkGetList( 0, 'dwho', 'UBKIKI' );
$ret = checkGetList( 4, 'dwho' );
checkGetOnIds( 'dwho', $ret );
checkDelete( 'dwho', @$ret[0]->{id} );
checkDelete404( 'dwho', @$ret[0]->{id} );

checkGetList( 3, 'dwho' );
checkDeleteList( 1, 'dwho', 'WebAuthn' );
checkGetList( 0, 'dwho', 'WebAuthn' );
checkDeleteList( 2, 'dwho' );
checkGetList( 0, 'dwho' );
checkDeleteList( 0, 'dwho' );

# msmith
$ret = checkGetList( 0, 'msmith' );

# rtyler
checkGetList( 1, 'rtyler', 'U2F' );
checkGetList( 0, 'rtyler', 'TOTP' );
checkGetList( 2, 'rtyler', 'UBK' );
$ret = checkGetList( 3, 'rtyler' );
checkGetOnIds( 'rtyler', $ret );
checkDeleteList( 2, 'rtyler', 'UBK' );
$ret = checkGetList( 1, 'rtyler' );
checkDelete( 'rtyler', @$ret[0]->{id} );
checkDelete404( 'rtyler', @$ret[0]->{id} );
checkDeleteList( 0, 'rtyler' );

# davros
checkGetList( 1, 'davros', 'U2F' );
checkGetList( 1, 'davros', 'TOTP' );
checkGetList( 0, 'davros', 'UBK' );
$ret = checkGetList( 2, 'davros' );
checkGetOnIds( 'davros', $ret );
checkDelete( 'davros', @$ret[0]->{id} );
checkDelete404( 'davros', @$ret[0]->{id} );
checkGetList( 1, 'davros' );
checkDeleteList( 1, 'davros', @$ret[1]->{type} );
checkGetList( 0, 'davros' );
checkDeleteList( 0, 'davros' );

# tof
checkGetList( 1, 'tof', 'U2F' );
checkGetList( 0, 'tof', 'TOTP' );
checkGetList( 0, 'tof', 'UBK' );
$ret = checkGetList( 1, 'tof' );
checkGetOnIds( 'tof', $ret );
checkDelete( 'tof', @$ret[0]->{id} );
checkDelete404( 'tof', @$ret[0]->{id} );
checkGetList( 0, 'tof' );
checkDeleteList( 0, 'tof' );

# 2FA add (generic)
checkAddWithBadAttributes( "Add/noattr ", "donna", undef, {},
    qr/Invalid input/ );
checkAddWithBadAttributes(
    "Add/epoch", "donna", undef,
    { name => "test", type => "test", epoch => 1 },
    qr/Invalid input: epoch is forbidden/
);

# Make epoch predictable
no warnings 'redefine';
*Lemonldap::NG::Manager::Api::_get_epoch = sub {
    return 123;
};

checkAdd( "Add second factor",
    "donna", undef, { type => "test", name => "test", mydisplay => 1 } );
$ret = checkGetList( 1, 'donna', 'test' );
checkDisplay( 'donna', $ret->[0]->{id} );

checkAddFailsIfExists( "Add second factor with same ID as previous",
    "donna", undef, { type => "test", name => "test" } );

checkAdd( "Add second factor with different ID",
    "donna", undef, { type => "test", name => "test2" } );
$ret = checkGetList( 2, 'donna', 'test' );
is_deeply(
    $ret,
    [ {
            'epoch'     => '123',
            'id'        => 'MTIzOjp0ZXN0Ojp0ZXN0',
            'mydisplay' => 1,
            'name'      => 'test',
            'type'      => 'test'
        },
        {
            'epoch' => '123',
            'id'    => 'MTIzOjp0ZXN0Ojp0ZXN0Mg==',
            'name'  => 'test2',
            'type'  => 'test'
        }
    ],
    "Expected second factors data"
);

# 2FA add (invalid type)
checkAddWithUnknownType( "Add/noattr ", "amy", "xxx", {} );

# 2FA add (TOTP)
newSession( 'amy', '127.10.0.1', 'SSO', [] );
my $amypsession = newSession( 'amy', '127.10.0.1', 'Persistent', [] );

checkAddWithBadAttributes( "Add/noattr ", "amy", "TOTP", {} );
checkAddWithBadAttributes( "Add/epoch", "amy", "TOTP",
    { name => "test", type => "test", epoch => 1 } );

checkAddWithBadAttributes( "Add/nokey", "amy", "TOTP", { name => "test" } );

checkAddWithBadAttributes(
    "Add/badkey", "amy", "TOTP",
    { name => "test", key => "123xxx" },
    qr/Invalid secret/
);

checkAdd( "Add/goodkey", "amy", "TOTP",
    { name => "test", key => "GEZDGNBVGY3TQOJQ GEZDGNBVG Y3TQOJQ  " } );
checkGetList( 1, 'amy', 'TOTP' );

checkTotpData(
    get2fDevices($amypsession)->[0],
    "gezdgnbvgy3tqojqgezdgnbvgy3tqojq",
    name => "test"
);

# 2FA add (TOTP) with undef 2fDevices
newSession( 'rory', '127.10.0.1', 'SSO', undef );
my $rorypsession = newSession( 'rory', '127.10.0.1', 'Persistent', undef );

checkAdd( "Add/goodkey", "rory", "TOTP",
    { name => "test", key => "GEZDGNBVGY3TQOJQ GEZDGNBVG Y3TQOJQ  " } );
checkGetList( 1, 'rory', 'TOTP' );

checkTotpData(
    get2fDevices($rorypsession)->[0],
    "gezdgnbvgy3tqojqgezdgnbvgy3tqojq",
    name => "test"
);

# 2FA add with nonexisting session
checkAddWithUnknownUser( "Add/missinguser", "unknowng", undef,
    { type => "test", name => "test" } );
checkAddWithUnknownUser( "Add/missinguser", "unknownt", "TOTP",
    { type => "test", key => "GEZDGNBVGY3TQOJQ GEZDGNBVG Y3TQOJQ  " } );
checkAddWithUnknownUser( "Add/missinguser", "unknowng", undef,
    { type => "test", name => "test" },
    "create=false" );
checkAddWithUnknownUser( "Add/missinguser", "unknownt", "TOTP",
    { type => "test", key => "GEZDGNBVGY3TQOJQ GEZDGNBVG Y3TQOJQ  " },
    "create=false" );

checkAdd( "Add/missinguser", "unknowng", undef,
    { type => "test", name => "test" },
    "create=true" );
checkGetList( 1, 'unknowng', 'test' );

checkAdd( "Add/missinguser", "unknownt", "TOTP",
    { name => "test", key => "GEZDGNBVGY3TQOJQ GEZDGNBVG Y3TQOJQ  " },
    "create=true" );
checkGetList( 1, 'unknownt', 'TOTP' );

# 2FA search

`rm -rf t/sessions/*`;

checkSearchNotFound;

# Populate some test factors
newSession(
    'dwho',
    '127.10.0.1',
    'Persistent',
    [ {
            "name"  => "MyTOTP",
            "type"  => "TOTP",
            "epoch" => "1643201784",
        },
        {
            "epoch" => "1643201784",
            "name"  => "MyFidoKey",
            "type"  => "WebAuthn"
        },
    ]
);
newSession(
    'rtyler',
    '127.10.0.1',
    'Persistent',
    [ {
            "name"  => "MyTOTP",
            "type"  => "TOTP",
            "epoch" => "1643201784",
        }
    ]
);
newSession(
    'mjones',
    '127.10.0.1',
    'Persistent',
    [ {
            "name"  => "MyUBK",
            "type"  => "Yubikey",
            "epoch" => "1643201784",
        }
    ]
);
newSession( 'msmith', '127.10.0.1', 'Persistent', [] );

checkSearch( "", [qw/dwho mjones rtyler/] );
my $result = checkSearch( "type=TOTP", [qw/dwho rtyler/] );
is_deeply(
    $result,

    [ {
            'secondFactors' => [ {
                    'id'   => 'MTY0MzIwMTc4NDo6VE9UUDo6TXlUT1RQ',
                    'name' => 'MyTOTP',
                    'type' => 'TOTP'
                },
                {
                    'id'   => 'MTY0MzIwMTc4NDo6V2ViQXV0aG46Ok15Rmlkb0tleQ==',
                    'name' => 'MyFidoKey',
                    'type' => 'WebAuthn'
                }
            ],
            'uid' => 'dwho'
        },
        {
            'secondFactors' => [ {
                    'id'   => 'MTY0MzIwMTc4NDo6VE9UUDo6TXlUT1RQ',
                    'name' => 'MyTOTP',
                    'type' => 'TOTP'
                }
            ],
            'uid' => 'rtyler'
        }
    ],
    "Expected API response"
);

checkSearch( "uid=m*",              [qw/mjones/] );
checkSearch( "uid=m*&type=Yubikey", [qw/mjones/] );
checkSearchNotFound("uid=m*&type=TOTP");
checkSearch( "uid=dwho&type=TOTP", [qw/dwho/] );
checkSearchNotFound("uid=dwho&type=Yubikey");
checkSearch( "type=TOTP&type=WebAuthn", [qw/dwho/] );

done_testing();
