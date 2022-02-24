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

SKIP: {
    eval "use Authen::WebAuthn::Test; use Authen::WebAuthn;";
    if ($@) {
        skip 'Authen::WebAuthn not found';
    }
    my $dir;
    my $cli;

    sub setup_sessions {
        use File::Temp;
        $dir = File::Temp::tempdir();
        my $sessionsdir  = "$dir/sessions";
        my $psessionsdir = "$dir/psessions";
        mkdir $sessionsdir;
        mkdir $psessionsdir;

        $cli = Lemonldap::NG::Common::CliSessions->new(
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
        my @psessionsOpts = (
            storageModule        => "Apache::Session::File",
            storageModuleOptions => {
                Directory     => $psessionsdir,
                LockDirectory => $psessionsdir,
            },
            kind  => 'Persistent',
            force => 1,
        );

        #dwho
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
                                'name'       => 'U2F-1',
                                'type'       => 'U2F',
                                'epoch'      => 1588691728,
                                '_keyHandle' =>
'4aS6vXlFQpG5XZSoad6auM9fFu7Q1wazQYwfPtPKN_Hll6Up_ceeWkOgqxm49swWq4Vvcg5UlX0sQQhuRe8heA',
                                '_userKey' =>
'BMgMqKPL2PhsjCNW78UEQyNF8zlJtrAAPtWMUDBp9VfDRF5oL2xkwFuyXRMPtRZ7lNfGijDrMc06bDNfp478sQQ',
                            },
                            {
                                'name'       => 'U2F-2',
                                'type'       => 'U2F',
                                'epoch'      => 1588691730,
                                '_keyHandle' =>
'F1Kk9V_O7KDPIx-mqp6CIjbz7ljA-ihWVWyoP1xYBe_HPLHR74aTLanmn0b4vI8DumiBWO1DAle3k6N55cXreg',
                                '_userKey' =>
'BAE_svIcxLfm2Knart7DI1ScfBnCt-OFKDWugp3YMO14tamwuc_wN0vSh1D_0DV4Ao3S5GNQZXxtjtUADHTwXHA',
                            },
                            {
                                _credentialId => 'noconflict',
                                'name'        => 'Existing WebAuthn',
                                'type'        => 'WebAuthn',
                                'epoch'       => 1588691798
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

        # rtyler
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
                                'name'       => 'U2F-3',
                                'type'       => 'U2F',
                                'epoch'      => 1588691734,
                                '_keyHandle' =>
'4suXv5Cf10vbJEP72mVkLpBjhSqy5niOgfc0X_MjdxZ_g2e-V8biC6WyCTpF_kGV1FCa06YlcryPCtWUuUST_g',
                                '_userKey' =>
'BIXrgc12iGGOYIGyWKd8WeOGCKyTkFA7jXkjlLS0i1MA3vy8gDocfqYCngXMzBAmtGI7FfMlbkG6DJeSubdxAVc',
                            },
                        ]
                    ),
                }
            }
        );
    }

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

    setup_sessions();
    my $res;

    # Migrate U2F
    $cli->run( "secondfactors", {}, "migrateu2f", "dwho" );

    $res = getJson( "secondfactors", {}, "get", "rtyler" );
    is( values %{$res}, 2, "Still 2 devices" );
    is( ( grep { $_->{type} eq "WebAuthn" } values %{$res} ),
        0, "No WebAuthn sessions created" );

    $res = getJson( "secondfactors", {}, "get", "dwho" );
    is( values %{$res}, 6, "Expect 6 devices after migration" );
    is( ( grep { $_->{type} eq "U2F" } values %{$res} ),
        2, "U2F still present" );
    is( ( grep { $_->{type} eq "UBK" } values %{$res} ),
        1, "UBK still in place" );
    is( ( grep { $_->{type} eq "WebAuthn" } values %{$res} ),
        3, "New WebAuthn device" );
    my $migratedid = "MTU4ODY5MTcyODo6V2ViQXV0aG46OlUyRi0x";
    is( $res->{$migratedid}->{_signCount}, 0, "migrated signcount" );
    is(
        $res->{$migratedid}->{_credentialId},
'4aS6vXlFQpG5XZSoad6auM9fFu7Q1wazQYwfPtPKN_Hll6Up_ceeWkOgqxm49swWq4Vvcg5UlX0sQQhuRe8heA',
        "migrated credential ID"
    );
    is(
        $res->{$migratedid}->{_credentialPublicKey},
'pQECAyYgASFYIMgMqKPL2PhsjCNW78UEQyNF8zlJtrAAPtWMUDBp9VfDIlggRF5oL2xkwFuyXRMPtRZ7lNfGijDrMc06bDNfp478sQQ',
        "migrated credential key"
    );
    is( $res->{$migratedid}->{epoch}, '1588691728', "migrated epoch" );
    is( $res->{$migratedid}->{name},  "U2F-1",      "migrated name" );

    # Check idempotence
    $cli->run( "secondfactors", {}, "migrateu2f", "dwho" );
    $res = getJson( "secondfactors", {}, "get", "dwho" );
    is( values %{$res}, 6, "Expect still 6 devices after rerunning migration" );
    is( ( grep { $_->{type} eq "U2F" } values %{$res} ),
        2, "U2F still in place" );
    is( ( grep { $_->{type} eq "UBK" } values %{$res} ),
        1, "UBK still in place" );
    is( ( grep { $_->{type} eq "WebAuthn" } values %{$res} ),
        3, "Same WebAuthn devices" );

    rmtree $dir;
    setup_sessions();

    # Migrate all
    $cli->run( "secondfactors", { all => 1 }, "migrateu2f" );
    $res = getJson( "secondfactors", {}, "get", "dwho" );
    is( values %{$res}, 6, "Expect 6 devices after migration" );
    is( ( grep { $_->{type} eq "U2F" } values %{$res} ),
        2, "U2F still in place" );
    is( ( grep { $_->{type} eq "UBK" } values %{$res} ),
        1, "UBK still in place" );
    is( ( grep { $_->{type} eq "WebAuthn" } values %{$res} ),
        3, "New WebAuthn device" );

    $res = getJson( "secondfactors", {}, "get", "rtyler" );
    is( values %{$res}, 3, "Expect 3 devices after migration" );
    is( ( grep { $_->{type} eq "U2F" } values %{$res} ),
        1, "U2F still in place" );
    is( ( grep { $_->{type} eq "UBK" } values %{$res} ),
        1, "UBK still in place" );
    is( ( grep { $_->{type} eq "WebAuthn" } values %{$res} ),
        1, "New WebAuthn device" );

    rmtree $dir;
}
done_testing();
