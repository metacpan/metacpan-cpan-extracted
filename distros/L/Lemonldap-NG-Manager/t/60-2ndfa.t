# Test 2ndFA manager API

use Test::More;
use JSON;
use strict;
use Lemonldap::NG::Common::Session;

eval { mkdir 't/sessions' };
`rm -rf t/sessions/*`;
require 't/test-lib.pm';

sub newSession {
    my ( $uid, $ip, $kind, $sfaDevices ) = splice @_;
    my $tmp;
    ok(
        $tmp = Lemonldap::NG::Common::Session->new( {
                storageModule        => 'Apache::Session::File',
                storageModuleOptions => {
                    Directory      => 't/sessions',
                    LockDirectory  => 't/sessions',
                    generateModule =>
'Lemonldap::NG::Common::Apache::Session::Generate::SHA256',
                },
            }
        ),
        'Sessions module'
    );
    count(1);
    $tmp->update( {
            ipAddr        => $ip,
            _whatToTrace  => $uid,
            uid           => $uid,
            _utime        => time,
            _session_kind => $kind,
            _2fDevices    => to_json($sfaDevices),
        }
    );
    return $tmp->{id};
}

my @ids;
my $sfaDevices = [];
my $epoch      = time;
my $res;

## Sessions creation
# SSO session
$ids[0] = newSession( 'dwho', '127.10.0.1', 'SSO', $sfaDevices );

# Peristent sesssions
$ids[1] = newSession( 'msmith', '127.10.0.1', 'Persistent', $sfaDevices );
$sfaDevices = [ {
        "name"       => "MyU2FKey",
        "type"       => "U2F",
        "_userKey"   => "123456",
        "_keyHandle" => "654321",
        "epoch"      => $epoch
    },
    {
        "name"    => "MyYubikey",
        "type"    => "UBK",
        "_secret" => "123456",
        "epoch"   => $epoch
    }
];
$ids[2] = newSession( 'rtyler', '127.10.0.1', 'Persistent', $sfaDevices );
$sfaDevices = [ {
        "name"       => "MyU2FKey",
        "type"       => "U2F",
        "_userKey"   => "123456",
        "_keyHandle" => "654321",
        "epoch"      => $epoch
    },
    {
        "name"    => "MyTOTP",
        "type"    => "TOTP",
        "_secret" => "123456",
        "epoch"   => $epoch
    },
    {
        "name"    => "MyYubikey",
        "type"    => "UBK",
        "_secret" => "123456",
        "epoch"   => $epoch
    }
];
$ids[3] = newSession( 'dwho', '127.10.0.1', 'Persistent', $sfaDevices );
$sfaDevices = [ {
        "name"       => "MyU2FKey",
        "type"       => "U2F",
        "_userKey"   => "123456",
        "_keyHandle" => "654321",
        "epoch"      => $epoch
    },
    {
        "name"    => "MyTOTP",
        "type"    => "TOTP",
        "_secret" => "123456",
        "epoch"   => $epoch
    }
];
$ids[4] = newSession( 'davros', '127.10.0.1', 'Persistent', $sfaDevices );
$sfaDevices = [ {
        "name"       => "MyU2FKey",
        "type"       => "U2F",
        "_userKey"   => "123456",
        "_keyHandle" => "654321",
        "epoch"      => $epoch
    }
];
$ids[5] = newSession( 'tof', '127.10.0.1', 'Persistent', $sfaDevices );

## Verify sessions creation
# Single SSO session access
$res = &client->jsonResponse("/sessions/global/$ids[0]");
ok( ( $res->{uid}    and $res->{uid} eq 'dwho' ),          'UID found' );
ok( ( $res->{ipAddr} and $res->{ipAddr} eq '127.10.0.1' ), 'IP found' );
count(2);

# Single Persistent sessions access
for ( my $i = 1 ; $i < 6 ; $i++ ) {
    $res = &client->jsonResponse("/sessions/persistent/$ids[$i]");
    ok( (
                  $res->{uid}
              and $res->{uid} =~ /^(?:dwho|rtyler|msmith|davros|tof)$/
        ),
        'Persistent sessions with UID found'
    );
}
count(5);

## Single Persistent sfa access
$res = &client->jsonResponse("/sfa/persistent/$ids[3]");
ok( ( $res->{uid} and $res->{uid} eq 'dwho' ), 'UID found' )
  or print STDERR Dumper($res);
ok( ( $res->{ipAddr} and $res->{ipAddr} eq '127.10.0.1' ), 'IP found' )
  or print STDERR Dumper($res);
ok( ( $res->{_2fDevices} and $res->{_2fDevices} =~ /"type":\s*"U2F"/s ),
    'U2F found' )
  or print STDERR Dumper($res);
ok( ( $res->{_2fDevices} and $res->{_2fDevices} =~ /"type":\s*"TOTP"/s ),
    'TOTP found' )
  or print STDERR Dumper($res);
ok( ( $res->{_2fDevices} and $res->{_2fDevices} =~ /"type":\s*"UBK"/s ),
    'UBK found' )
  or print STDERR Dumper($res);
count(5);

## "All" query
$res = &client->jsonResponse( '/sfa/persistent', 'groupBy=substr(uid,1)' );
ok( $res->{result} == 1,      'Search * - Result code = 1' );
ok( $res->{count} == 3,       'Found 3 results' ) or print STDERR Dumper($res);
ok( @{ $res->{values} } == 3, 'List 3 results' );
ok( $res->{values}->[0]->{value} && $res->{values}->[0]->{value} eq 'd',
    'Result match "uid=d"' )
  or print STDERR Dumper($res);
ok( $res->{values}->[1]->{value} && $res->{values}->[1]->{value} eq 'r',
    'Result match "uid=r"' )
  or print STDERR Dumper($res);
ok( $res->{values}->[2]->{value} && $res->{values}->[2]->{value} eq 't',
    'Result match "uid=t"' )
  or print STDERR Dumper($res);
ok( $res->{values}->[0]->{count} == 2, 'Found 2 sessions starting with "d"' );
ok( $res->{values}->[1]->{count} == 1, 'Found 1 session starting with "r"' );
ok( $res->{values}->[2]->{count} == 1, 'Found 1 session starting with "t"' );
count(9);

## "Search by UID" query
# uid=d*
$res =
  &client->jsonResponse( '/sfa/persistent', 'uid=d*&groupBy=substr(uid,1)' );
ok( $res->{result} == 1,      'Search "uid"=d* - Result code = 1' );
ok( $res->{count} == 1,       'Found 1 result' ) or print STDERR Dumper($res);
ok( @{ $res->{values} } == 1, 'List 1 result' );
ok( $res->{values}->[0]->{value} && $res->{values}->[0]->{value} eq 'd',
    'Result match "uid=d"' )
  or print STDERR Dumper($res);
ok( $res->{values}->[0]->{count} == 2, 'Found 2 sessions starting with "d"' );
count(5);

# uid=dw*
$res =
  &client->jsonResponse( '/sfa/persistent', 'uid=dw*&groupBy=substr(uid,2)' );
ok( $res->{result} == 1,      'Search "uid"=dw* - Result code = 1' );
ok( $res->{count} == 1,       'Found 1 result' ) or print STDERR Dumper($res);
ok( @{ $res->{values} } == 1, 'List 1 result' );
ok( $res->{values}->[0]->{value} && $res->{values}->[0]->{value} eq 'dw',
    'Result match "uid=dw"' )
  or print STDERR Dumper($res);
ok( $res->{values}->[0]->{count} == 1, 'Found 1 session starting with "dw"' );
count(5);

# uid=d* & UBK
$res = &client->jsonResponse( '/sfa/persistent',
    'uid=d*&groupBy=substr(uid,1)&type=UBK' );
ok( $res->{result} == 1,      'Search "uid"=d* & UBK - Result code = 1' );
ok( $res->{count} == 1,       'Found 1 result' ) or print STDERR Dumper($res);
ok( @{ $res->{values} } == 1, 'List 1 result' );
ok( $res->{values}->[0]->{value} && $res->{values}->[0]->{value} eq 'd',
    'Result match "uid=d"' )
  or print STDERR Dumper($res);
ok(
    $res->{values}->[0]->{count} == 1,
    'Found 1 session starting with "d" & UBK'
);
count(5);

# uid=dw* & UBK
$res = &client->jsonResponse( '/sfa/persistent',
    'uid=dw*&groupBy=substr(uid,2)&type=UBK' );
ok( $res->{result} == 1,      'Search "uid"=dw* & UBK - Result code = 1' );
ok( $res->{count} == 1,       'Found 1 result' ) or print STDERR Dumper($res);
ok( @{ $res->{values} } == 1, 'List 1 result' );
ok( $res->{values}->[0]->{value} && $res->{values}->[0]->{value} eq 'dw',
    'Result match "uid=dw"' )
  or print STDERR Dumper($res);
ok(
    $res->{values}->[0]->{count} == 1,
    'Found 1 session starting with "dw" & UBK'
);
count(5);

# uid=da* & UBK
$res = &client->jsonResponse( '/sfa/persistent',
    'uid=da*&groupBy=substr(uid,2)&type=UBK' );
ok( $res->{result} == 1, 'Search "uid"=da* & UBK - Result code = 1' );
ok( $res->{count} == 0,  'Found 0 session with "da" & UBK' )
  or print STDERR Dumper($res);
ok( @{ $res->{values} } == 0, 'List 0 result' );
count(3);

## "Filtered by U2F" query
$res = &client->jsonResponse( '/sfa/persistent',
    'uid=*&groupBy=substr(uid,0)&type=U2F' );
ok( $res->{result} == 1,      'Search "uid"=* & UBK - Result code = 1' );
ok( $res->{count} == 3,       'Found 3 results' ) or print STDERR Dumper($res);
ok( @{ $res->{values} } == 3, 'List 3 results' );
ok( $res->{values}->[0]->{value} && $res->{values}->[0]->{value} eq 'd',
    'Result match "uid=d"' )
  or print STDERR Dumper($res);
ok( $res->{values}->[1]->{value} && $res->{values}->[1]->{value} eq 'r',
    'Result match "uid=r"' )
  or print STDERR Dumper($res);
ok( $res->{values}->[2]->{value} && $res->{values}->[2]->{value} eq 't',
    'Result match "uid=t"' )
  or print STDERR Dumper($res);
ok(
    $res->{values}->[0]->{count} == 2,
    'Found 2 sessions starting with "d" & U2F'
);
ok(
    $res->{values}->[1]->{count} == 1,
    'Found 1 session starting with "r" & U2F'
);
ok(
    $res->{values}->[2]->{count} == 1,
    'Found 1 session starting with "t" & U2F'
);
count(9);

## "Filtered by U2F & TOTP" query
$res = &client->jsonResponse( '/sfa/persistent',
    'uid=*&groupBy=substr(uid,0)&type=U2F&type=TOTP' );
ok( $res->{result} == 1,      'Search "uid"=* & UBK & TOTP - Result code = 1' );
ok( $res->{count} == 1,       'Found 1 result' ) or print STDERR Dumper($res);
ok( @{ $res->{values} } == 1, 'List 1 result' );
ok( $res->{values}->[0]->{value} && $res->{values}->[0]->{value} eq 'd',
    'Result match "uid=d"' )
  or print STDERR Dumper($res);
ok( $res->{values}->[0]->{count} == 2,
    'Found 2 sessions starting with "d" & U2F & TOTP' );
count(5);

## "Filtered by U2F & TOTP & UBK" query
$res = &client->jsonResponse( '/sfa/persistent',
    'uid=*&groupBy=substr(uid,0)&type=U2F&type=TOTP&type=UBK' );
ok( $res->{result} == 1,
    'Search "uid"=* & UBK & TOTP & UBK - Result code = 1' );
ok( $res->{count} == 1,       'Found 1 result' ) or print STDERR Dumper($res);
ok( @{ $res->{values} } == 1, 'List 1 result' );
ok( $res->{values}->[0]->{value} && $res->{values}->[0]->{value} eq 'd',
    'Result match "uid=d"' )
  or print STDERR Dumper($res);
ok( $res->{values}->[0]->{count} == 1,
    'Found 1 session starting with "d" & U2F & TOTP & UBK' );
count(5);

## "Filtered by U2F & UBK" query
$res = &client->jsonResponse( '/sfa/persistent',
    'uid=*&groupBy=substr(uid,0)&type=U2F&type=UBK' );
ok( $res->{result} == 1,      'Search "uid"=* & UBK & UBK - Result code = 1' );
ok( $res->{count} == 2,       'Found 2 results' ) or print STDERR Dumper($res);
ok( @{ $res->{values} } == 2, 'List 2 results' );
ok( $res->{values}->[0]->{value} && $res->{values}->[0]->{value} eq 'd',
    'Result match "uid=d"' )
  or print STDERR Dumper($res);
ok( $res->{values}->[1]->{value} && $res->{values}->[1]->{value} eq 'r',
    'Result match "uid=r"' )
  or print STDERR Dumper($res);
ok( $res->{values}->[0]->{count} == 1,
    'Found 1 session starting with "d" & U2F & UBK' );
ok( $res->{values}->[1]->{count} == 1,
    'Found 1 session starting with "r" & U2F & UBK' );
count(7);

## Delete 2F devices
# Delete U2F devices
foreach ( 1 .. 5 ) {
    ok(
        $res =
          &client->_del( "/sfa/persistent/$ids[$_]", "type=U2F&epoch=$epoch" ),
        "Delete U2F from $_"
    );
    ok( $res->[0] == 200, 'Result code is 200' );
    ok( from_json( $res->[2]->[0] )->{result} == 1,
        'Body is JSON and result==1' );
    count(3);
}

# Delete TOTP devices
foreach ( 3 .. 4 ) {
    ok(
        $res =
          &client->_del( "/sfa/persistent/$ids[$_]", "type=TOTP&epoch=$epoch" ),
        "Delete TOTP from $_"
    );
    ok( $res->[0] == 200, 'Result code is 200' );
    ok( from_json( $res->[2]->[0] )->{result} == 1,
        'Body is JSON and result==1' );
    count(3);
}

# Delete UBK devices
foreach ( 2 .. 3 ) {
    ok(
        $res =
          &client->_del( "/sfa/persistent/$ids[$_]", "type=UBK&epoch=$epoch" ),
        "Delete UBK from $_"
    );
    ok( $res->[0] == 200, 'Result code is 200' );
    ok( from_json( $res->[2]->[0] )->{result} == 1,
        'Body is JSON and result==1' );
    count(3);
}

## Check than all devices have been deleted with "All" query
$res = &client->jsonResponse( '/sfa/persistent', 'groupBy=substr(uid,1)' );
ok( $res->{result} == 1, 'Result code = 1' );
ok( $res->{count} == 0,  'Found 0 session with 2F device' )
  or print STDERR Dumper($res);
ok( @{ $res->{values} } == 0, 'List 0 result' );
count(3);

ok( $res = &client->_get('/2ndfa.html'), 'Succeed to get /2ndfa.html' );
like( $res->[2]->[0],
    qr,<label class="form-check-label" for="TOTPCheck">TOTP</label>, );
count(2);

done_testing( count() );

# Remove sessions directory
`rm -rf t/sessions`;
