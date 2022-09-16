# Test 2F API

use Test::More;
use strict;
use JSON;
use IO::String;
use Lemonldap::NG::Common::Session;

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
                _2fDevices    => to_json($sfaDevices),
            }
        ),
        "New $kind session for $uid"
    );
    count(1);
}

sub check200 {
    my ( $test, $res ) = splice @_;
    ok( $res->[0] == 200, "$test: Result code is 200" );
    count(1);
    checkJson( $test, $res );
}

sub check400 {
    my ( $test, $res ) = splice @_;
    ok( $res->[0] == 400, "$test: Result code is 400" );
    count(1);
    checkJson( $test, $res );
}

sub check404 {
    my ( $test, $res ) = splice @_;
    ok( $res->[0] == 404, "$test: Result code is 404" );
    count(1);
    checkJson( $test, $res );
}

sub checkJson {
    my ( $test, $res ) = splice @_;
    my $key;

    #diag Dumper($res->[2]->[0]);
    ok( $key = from_json( $res->[2]->[0] ), "$test: Response is JSON" );
    count(1);
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
        "name"    => "MyTOTP",
        "type"    => "TOTP",
        "_secret" => "123456",
        "epoch"   => time
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

# dwho
checkGetList( 1, 'dwho', 'U2F' );
checkGetList( 1, 'dwho', 'TOTP' );
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
checkGetList( 0, 'msmith' );

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

done_testing();
