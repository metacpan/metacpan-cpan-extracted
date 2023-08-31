# Test 2F API

use warnings;
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
    my ( $uid, $loginHistory ) = splice @_;
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
                "_loginHistory" => $loginHistory,
                _whatToTrace    => $uid,
                uid             => $uid,
                _session_uid    => $uid,
                _utime          => time,
                _session_kind   => 'Persistent',
            }
        ),
        "New session for $uid"
    );
    count(1);
}

sub check200 {
    my ($res) = splice @_;
    is( $res->[0], 200, "Response code is 200" );
    count(1);
    return $res;
}

sub check400 {
    my ($res) = splice @_;
    is( $res->[0], 400, "Response code is 400" );
    count(1);
    return $res;
}

sub check404 {
    my ($res) = splice @_;
    is( $res->[0], 404, "Response code is 404" );
    count(1);
    return $res;
}

sub getJson {
    my ($res) = splice @_;
    my $json;

    ok( $json = from_json( $res->[2]->[0] ), "Got JSON" );
    count(1);
    return $json;
}

sub get {
    my ( $path, $query ) = splice @_;
    my ($res);
    ok( $res = &client->_get( "/api/v1/history/$path", $query ),
        "Get request on $path" );
    count(1);
    return $res;
}

my $sfaDevices = [];
my $ret;
newSession(
    'dwho',
    {
        "failedLogin" => [ {
                "_utime" => 1677062205,
                "error"  => "5",
                "ipAddr" => "10.128.239.1"
            },
            {
                "_utime" => 1676452178,
                "error"  => "5",
                "ipAddr" => "10.128.239.1"
            },
            {
                "_utime" => 1676303145,
                "error"  => "5",
                "ipAddr" => "10.128.239.1"
            },
            {
                "_utime" => 1676303099,
                "error"  => "5",
                "ipAddr" => "10.128.239.1"
            }
        ],
        "successLogin" => [ {
                "_utime" => 1677665858,
                "ipAddr" => "10.128.239.1"
            },
            {
                "_utime" => 1677665776,
                "error"  => "-4",
                "ipAddr" => "10.128.239.1"
            },
            {
                "_utime" => 1677665074,
                "ipAddr" => "10.128.239.1"
            },
            {
                "_utime" => 1677665047,
                "error"  => "-4",
                "ipAddr" => "10.128.239.1"
            },
            {
                "_utime" => 1677665000,
                "ipAddr" => "10.128.239.1"
            }
        ]
    }
);

newSession(
    'rtyler',
    {
        "failedLogin" => [ {
                "_utime" => 1677665858,
                "error"  => "5",
                "ipAddr" => "10.128.239.1"
            },
            {
                "_utime" => 1676452178,
                "error"  => "5",
                "ipAddr" => "10.128.239.1"
            },
            {
                "_utime" => 1676303145,
                "error"  => "5",
                "ipAddr" => "10.128.239.1"
            },
            {
                "_utime" => 1676303099,
                "error"  => "5",
                "ipAddr" => "10.128.239.1"
            }
        ],
    }
);

newSession( 'msmith', undef );

subtest "Get all entries for user" => sub {
    $ret = getJson check200 get("dwho");
    is( @$ret, 9, "Found 9 entries" );
};

subtest "Type any returns all entries" => sub {
    $ret = getJson check200 get( "dwho", "result=any" );
    is( @$ret, 9, "Found 9 entries" );
};

subtest "Get all successes for user" => sub {
    $ret = getJson check200 get( "dwho", "result=success" );
    is( @$ret, 5, "Found 5 entries" );
};

subtest "Get all failures for user" => sub {
    $ret = getJson check200 get( "dwho", "result=failed" );
    is( @$ret, 4, "Found 4 entries" );
};

subtest "Get last success for user" => sub {
    $ret = getJson check200 get( "dwho/last", "result=success" );
    is_deeply(
        $ret,
        {
            'date'   => 1677665858,
            'ipAddr' => '10.128.239.1',
            'result' => 'success'
        }
    );
};

subtest "Get last failure for user" => sub {
    $ret = getJson check200 get( "dwho/last", "result=failed" );
    is_deeply(
        $ret,
        {
            'date'   => 1677062205,
            'error'  => '5',
            'ipAddr' => '10.128.239.1',
            'result' => 'failed'
        }
    );
};

subtest "Get last event for user" => sub {
    $ret = getJson check200 get("dwho/last");
    is_deeply(
        $ret,
        {
            'date'   => 1677665858,
            'ipAddr' => '10.128.239.1',
            'result' => 'success'
        }
    );
};

subtest "Get last event for user" => sub {
    $ret = getJson check200 get("rtyler/last");
    is_deeply(
        $ret,
        {
            'date'   => 1677665858,
            'error'  => '5',
            'ipAddr' => '10.128.239.1',
            'result' => 'failed'
        }
    );
};

# User with empty history return empty array
is_deeply( getJson( check200 get("msmith") ), [] );
is_deeply( getJson( check200 get( "msmith", "result=success" ) ), [] );
is_deeply( getJson( check200 get( "rtyler", "result=success" ) ), [] );

# no user returns 404
is_deeply( getJson( check404 get "nobody" ), { error => "No such user" } );
is_deeply( getJson( check404 get "nobody", "result=success" ),
    { error => "No such user" } );

# Last returns a 404 in those cases
is_deeply( getJson( check404 get "msmith/last" ),
    { error => "No such event" } );
is_deeply( getJson( check404 get "rtyler/last", "result=success" ),
    { error => "No such event" } );
is_deeply( getJson( check404 get "nobody/last" ),
    { error => "No such event" } );

# Unknown type
$ret = getJson check400 get( "toto", "result=unknown" );
like( $ret->{error}, qr/Unknown result/ );

# Unknown subpath
$ret = getJson check404 get("toto/unknown");
like( $ret->{error}, qr/Unknown path/ );

# Missing UID
$ret = getJson check404 get("");
like( $ret->{error}, qr/Missing user identifier/ );

done_testing();
