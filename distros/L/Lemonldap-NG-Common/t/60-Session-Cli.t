# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Manager.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
use Test::Output;
use File::Path;
use JSON;

BEGIN {
    use_ok('Lemonldap::NG::Common::Session');
    use_ok('Lemonldap::NG::Common::CliSessions');
}

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use File::Temp;
my $dir          = File::Temp::tempdir();
my $sessionsdir  = "$dir/sessions";
my $psessionsdir = "$dir/psessions";
mkdir $sessionsdir;
mkdir $psessionsdir;

my $cli = Lemonldap::NG::Common::CliSessions->new(
    conf => {
        globalStorage        => "Apache::Session::File",
        globalStorageOptions => {
            Directory     => $sessionsdir,
            LockDirectory => $sessionsdir,
        },
        persistentStorage        => "Apache::Session::File",
        persistentStorageOptions => {
            Directory     => $psessionsdir,
            LockDirectory => $psessionsdir,
        },
    }
);

# Provision test sessions
my @sessionsOpts = (
    storageModule        => "Apache::Session::File",
    storageModuleOptions => {
        Directory     => $sessionsdir,
        LockDirectory => $sessionsdir,
    },
    kind  => 'SSO',
    force => 1,
);
my @psessionsOpts = (
    storageModule        => "Apache::Session::File",
    storageModuleOptions => {
        Directory     => $psessionsdir,
        LockDirectory => $psessionsdir,
    },
    kind  => 'Persistent',
    force => 1,
);

sub resetSessions {
    Lemonldap::NG::Common::Session->new( {
            @sessionsOpts,
            id   => "1b3231655cebb7a1f783eddf27d254ca",
            info => {
                "uid" => "rtyler",
            }
        }
    );
    Lemonldap::NG::Common::Session->new( {
            @sessionsOpts,
            id   => "9684dd2a6489bf2be2fbdd799a8028e3",
            info => {
                "uid" => "dwho",
            }
        }
    );
    Lemonldap::NG::Common::Session->new( {
            @sessionsOpts,
            id   => "f90f597566f5cce47d9641377776c0c2",
            info => {
                "uid"      => "dwho",
                "deleteme" => 1,
            }
        }
    );
    Lemonldap::NG::Common::Session->new( {
            @sessionsOpts,
            id   => "1234",
            info => {
                "uid" => "foo",
            }
        }
    );
    Lemonldap::NG::Common::Session->new( {
            @sessionsOpts,
            id   => "1235",
            info => {
                "uid" => "foo",
            }
        }
    );

    Lemonldap::NG::Common::Session->new( {
            @psessionsOpts,
            id    => "5efe8af397fc3577e05b483aca964f1b",
            force => 1,
            info  => {
                "_2fDevices" => to_json( [ {
                            'type'     => 'UBK',
                            'epoch'    => 1588691690,
                            '_yubikey' => 'cccccceijfnf',
                            'name'     => 'Imported automatically'
                        },
                        {
                            'name'  => 'MyU2F',
                            'type'  => 'U2F',
                            'epoch' => 1588691728
                        },
                        {
                            '_secret' => 'mnxkiirpswuojr47kkrty7ax34fy2ix7',
                            'name'    => 'MyTOTP',
                            'type'    => 'TOTP',
                            'epoch'   => 1588691728
                        }
                    ]
                ),
                "_oidcConsents" => to_json( [ {
                            'scope' => 'openid email',
                            'rp'    => 'rp-example',
                            'epoch' => 1589288341
                        },
                        {
                            'scope' => 'openid email',
                            'epoch' => 1589291482,
                            'rp'    => 'rp-example2'
                        }
                    ]
                ),
                "_session_uid" => "dwho",
            }
        }
    );
    Lemonldap::NG::Common::Session->new( {
            @psessionsOpts,
            id    => "8d3bc3b0e14ea2a155f275aa7c07ebee",
            force => 1,
            info  => {
                "_session_uid" => "rtyler",
                "_2fDevices"   => to_json( [ {
                            'type'     => 'UBK',
                            'epoch'    => 1588691690,
                            '_yubikey' => 'cccccceijfnf',
                            'name'     => 'Imported automatically'
                        },
                        {
                            '_secret' => 'mnxkiirpswuojr47kkrty7ax34fy2ix7',
                            'name'    => 'MyTOTP',
                            'type'    => 'TOTP',
                            'epoch'   => 1588691728
                        }
                    ]
                ),
            }
        }
    );
}

resetSessions;

sub getJson {
    my @args = @_;
    my ($str) = Test::Output::output_from( sub { $cli->run(@args); } );
    return from_json($str);
}

sub getLines {
    my @args = @_;
    my ($str) = Test::Output::output_from( sub { $cli->run(@args); } );
    return [ split /\n/, $str ];
}

my $res;

# Test get
$res = getJson( "get", {}, "f90f597566f5cce47d9641377776c0c2" );

is( @{$res}, 1, "Found one session" );
is(
    $res->[0]->{_session_id},
    "f90f597566f5cce47d9641377776c0c2",
    "Found correct session ID"
);
is( $res->[0]->{deleteme}, 1, "Found deleteme session key" );

# Change backend
$res = getJson(
    "get",
    { backend => 'persistent' },
    "5efe8af397fc3577e05b483aca964f1b"
);
is( @{$res},                   1,      "Found one session" );
is( $res->[0]->{_session_uid}, 'dwho', "Found correct session" );

# Persistent mode
$res = getJson( "get", { persistent => 1 }, "dwho" );
is( @{$res},                   1,      "Found one session" );
is( $res->[0]->{_session_uid}, 'dwho', "Found correct session" );

# Test output field selection
$res = getJson(
    "get",
    { select => [ "uid", "_session_id" ] },
    "f90f597566f5cce47d9641377776c0c2"
);

is( keys %{ $res->[0] }, 2,      "Only selected fields returned" );
is( $res->[0]->{uid},    "dwho", "Found correct UID" );
is(
    $res->[0]->{_session_id},
    "f90f597566f5cce47d9641377776c0c2",
    "Found correct session ID"
);

# Test search
$res = getJson( "search", {} );
is( @{$res}, 5, "Found 5 sessions" );

# Test search with different backend
$res = getJson( "search", { backend => 'persistent' } );
is( @{$res}, 2, "Found 2 psessions" );

# Persistent mode
$res = getJson( "search", { persistent => 1 } );
is( @{$res}, 2, "Found 2 psessions" );

# Test search with where
$res = getJson( "search", { where => "uid=dwho" } );
is( @{$res},                                  2, "Found 2 sessions" );
is( ( grep { $_->{uid} eq "dwho" } @{$res} ), 2, "Both sessions are dwho" );

# Test search with where and field selection
$res = getJson( "search",
    { where => "uid=dwho", select => [ "uid", "_session_id" ] } );
is( @{$res},             2, "Found 2 sessions" );
is( keys %{ $res->[0] }, 2, "Only selected fields returned" );

# Test search with ID output
$res = getLines( "search", { where => "uid=dwho", idonly => 1 } );
is( @{$res}, 2, "Got two lines" );
is(
    ( join ':', sort @{$res} ),
    "9684dd2a6489bf2be2fbdd799a8028e3:f90f597566f5cce47d9641377776c0c2",
    "Correct session IDs"
);

# Delete session
$cli->run( 'delete', {},                  "9684dd2a6489bf2be2fbdd799a8028e3" );
$cli->run( 'delete', { persistent => 1 }, "rtyler" );

$res = getJson( "get", {}, "9684dd2a6489bf2be2fbdd799a8028e3" );
is( @{$res}, 0, "Session was removed" );
$res = getJson(
    "get",
    { backend => 'persistent' },
    "8d3bc3b0e14ea2a155f275aa7c07ebee"
);
is( @{$res}, 0, "Session was removed" );

# We should have 2 foo sessions now
$res = getJson( "search", { where => "uid=foo" } );
is( @{$res}, 2, "Found 2 foo sessions" );

# Test delete by filter, remove two foo sessions
$cli->run( 'delete', { where => "uid=foo" } );

# We should have no foo sessions left
$res = getJson( "search", { where => "uid=foo" } );
is( @{$res}, 0, "Found 0 foo sessions" );

# Set key

$cli->run( "setKey", {}, "f90f597566f5cce47d9641377776c0c2",
    "key1", "value1", "deleteme", "newvalue" );
$res = getJson( "get", {}, "f90f597566f5cce47d9641377776c0c2" );
is( $res->[0]->{key1},     "value1",   "New key was set" );
is( $res->[0]->{deleteme}, "newvalue", "Existing key was changed" );

# Delete key
$cli->run( "delKey", {}, "f90f597566f5cce47d9641377776c0c2",
    "key1", "deleteme", "missing" );
$res = getJson( "get", {}, "f90f597566f5cce47d9641377776c0c2" );
is( $res->[0]->{key1},     undef, "Key was removed" );
is( $res->[0]->{deleteme}, undef, "Key was removed" );

# Show 2FA

$res = getJson( "secondfactors", {}, "get", "dwho" );
is( ( keys %{$res} ), 3, "Found two second factors" );
is( ( grep { $_->{type} eq "UBK" } values %{$res} ),  1, "Found one Yubikey" );
is( ( grep { $_->{type} eq "TOTP" } values %{$res} ), 1, "Found one TOTP" );
is( ( grep { $_->{type} eq "U2F" } values %{$res} ),  1, "Found one U2F" );

# Delete 2FA
$cli->run( "secondfactors", {}, "delete", "dwho",
    "MTU4ODY5MTY5MDo6VUJLOjpJbXBvcnRlZCBhdXRvbWF0aWNhbGx5" );
$res = getJson( "secondfactors", {}, "get", "dwho" );
is( ( keys %{$res} ), 2, "Found two second factors" );
is( ( grep { $_->{type} eq "UBK" } values %{$res} ), 0, "Yubikey was removed" );

# Delete 2FA by type
$cli->run( "secondfactors", {}, "delType", "dwho", "U2F" );
$res = getJson( "secondfactors", {}, "get", "dwho" );
is( ( keys %{$res} ), 1, "Found one second factors" );
is( ( grep { $_->{type} eq "U2F" } values %{$res} ),  0, "U2F was removed" );
is( ( grep { $_->{type} eq "TOTP" } values %{$res} ), 1, "TOTP survived" );

# Delete 2FA by type (with search)
resetSessions;
$cli->run( "secondfactors", { where => "_session_uid=dwho" }, "delType",
    "U2F" );
$res = getJson( "secondfactors", {}, "get", "dwho" );
is( ( keys %{$res} ), 2, "Found one second factors" );
is( ( grep { $_->{type} eq "U2F" } values %{$res} ),  0, "U2F was removed" );
is( ( grep { $_->{type} eq "TOTP" } values %{$res} ), 1, "TOTP survived" );

# Delete 2FA by type (with all)
resetSessions;
$cli->run( "secondfactors", { all => 1 }, "delType", "TOTP" );
$res = getJson( "secondfactors", {}, "get", "dwho" );
is( ( keys %{$res} ), 2, "Found two second factors for dwho" );
is( ( grep { $_->{type} eq "TOTP" } values %{$res} ), 0, "TOTP was removed" );
is( ( grep { $_->{type} eq "UBK" } values %{$res} ),  1, "UBK survived" );
$res = getJson( "secondfactors", {}, "get", "rtyler" );
is( ( keys %{$res} ), 1, "Found one second factors for rtyler" );
is( ( grep { $_->{type} eq "TOTP" } values %{$res} ), 0, "TOTP was removed" );
is( ( grep { $_->{type} eq "UBK" } values %{$res} ),  1, "UBK survived" );

# Show consents
$res = getJson( "consents", {}, "get", "dwho" );
is( ( keys %{$res} ), 2, "Found two consents" );

# Delete consents

$cli->run( "consents", {}, "delete", "dwho", "rp-example" );
$res = getJson( "consents", {}, "get", "dwho" );
is( ( keys %{$res} ),     1,     "Found one consent" );
is( $res->{'rp-example'}, undef, "Consent for test-rp removed" );
ok( $res->{'rp-example2'}, "Consent for test-rp2 still present" );

rmtree $dir;
done_testing();
