use warnings;
use strict;

use Test::More;
use Time::Fake;
use t::TestLogger;
BEGIN { use_ok('Lemonldap::NG::Common::Session') }

use File::Temp;
my $dir = File::Temp::tempdir( "sessionsXXXXXX", DIR => "t/", CLEANUP => 1 );
mkdir("$dir/global");
mkdir("$dir/global-lock");
mkdir("$dir/saml");
mkdir("$dir/saml-lock");
mkdir("$dir/persistent");
mkdir("$dir/persistent-lock");

my $conf = {
    logLevel           => "info",
    timeout            => '5000',
    samlStorage        => "Apache::Session::File",
    samlStorageOptions => {
        Directory     => "$dir/saml",
        LockDirectory => "$dir/saml-lock",
    },
    persistentStorage        => "Apache::Session::File",
    persistentStorageOptions => {
        Directory     => "$dir/persistent",
        LockDirectory => "$dir/persistent-lock",
    },
    globalStorage        => "Apache::Session::File",
    globalStorageOptions => {
        Directory     => "$dir/global",
        LockDirectory => "$dir/global-lock",
    },
};

sub _sum {
    my $sum = 0;
    map { $sum += $_ } @_;
    return $sum;
}

# Helper method to create sessions
sub _storeSession {
    my ( $backend, $kind, $name, $creation_time, $last_seen ) = @_;

    my $session = Lemonldap::NG::Common::Session->new( {
            storageModule        => $conf->{"${backend}Storage"},
            storageModuleOptions => $conf->{"${backend}StorageOptions"},
            kind                 => $kind,
            info                 => {
                _utime => $creation_time,
                ( $last_seen ? ( _lastSeen => $last_seen, ) : () ),
                name => $name,
            },
        }

    );
}

# Helper to cleanup all sessions
sub _cleanSessions {
    unlink glob "$dir/*/*";
}

# Helper to get all sessions
sub _getSessionsNames {
    my ($backend) = @_;
    my $sessions =
      Lemonldap::NG::Common::Apache::Session->get_key_from_all_sessions( {
            %{ $conf->{"${backend}StorageOptions"} },
            backend => $conf->{"${backend}Storage"},
        },
        "name"
      );
    return [ sort map { $sessions->{$_}->{name} } keys %$sessions ];
}

sub _test_purge {
    my ( $time, $extra_conf, $creation_opts, $purge_opts ) = @_;
    $extra_conf    //= {};
    $creation_opts //= [];
    $purge_opts    //= [];

    my $logger = t::TestLogger->new;
    my $purge  = Lemonldap::NG::Common::Session::Purge->new(
        conf   => { %$conf, %$extra_conf },
        logger => $logger,
        @$creation_opts
    );
    Time::Fake->offset($time);
    my $result = $purge->purge(@$purge_opts);

    # Check result
    ok( $result->{success}, "Function returns success" );

    # Consistency checks in stats
    my $total = delete $result->{stats}->{total};
    my $sum_time =
      _sum( map { $_->{duration_u} } values %{ $result->{stats} } );
    my $sum_errors = _sum( map { $_->{errors} } values %{ $result->{stats} } );
    my $sum_purged = _sum( map { $_->{purged} } values %{ $result->{stats} } );

    is( $result->{errors}, $total->{errors},
        'result.errors == result.stats.total.errors' );
    is( $sum_errors, $total->{errors},
        'sum(result.stats.*.errors) == result.stats.total.errors' );

    is( $result->{purged}, $total->{purged},
        'result.purged == result.stats.total.purged' );
    is( $sum_purged, $total->{purged},
        'sum(result.stats.*.purged) == result.stats.total.purged' );

    cmp_ok( $sum_time, "<=", $total->{duration_u},
        'sum(result.stats.*.duration_u) <= result.stats.total.duration_u' );

    # Log sent at info level
    $logger->contains( "info", qr/Session purge completed/ );
    return $result;
}

use_ok( 'Lemonldap::NG::Common::Session::Purge', "Module successfully loaded" );

subtest "Purge with no timeoutActivity" => sub {
    _cleanSessions;
    _storeSession( "global", "SSO", "a", 10000 );
    _storeSession( "global", "SSO", "b", 12000 );

    _test_purge(16000);
    is_deeply( _getSessionsNames("global"),
        ["b"], "Session b is recent enough to survive" );

    _test_purge(20000);
    is_deeply( _getSessionsNames("global"), [], "No sessions remaining" );
};

subtest "Purge with timeoutActivity" => sub {
    _cleanSessions;

    # Old session, with recent activity
    _storeSession( "global", "SSO", "a", 10000, 15500 );

    # Old session, without recent activity
    _storeSession( "global", "SSO", "b", 10000, 11000 );

    # Recent session, without recent activity
    _storeSession( "global", "SSO", "c", 12000, 13000 );

    # Recent session, with recent activity
    _storeSession( "global", "SSO", "d", 12000, 15500 );

    _test_purge( 16000, { timeoutActivity => 1000 } );
    is_deeply( _getSessionsNames("global"),
        ["d"], "Only session d is recent enough to survive" );

    _test_purge( 17000, { timeoutActivity => 1000 } );
    is_deeply( _getSessionsNames("global"), [], "No sessions remaining" );
};

subtest "Multiple types in same backend" => sub {
    _cleanSessions;

    # Old SSO session
    _storeSession( "global", "SSO", "a", 10000 );

    # Recent SSO session
    _storeSession( "global", "SSO", "b", 12000 );

    # Old SAML session
    _storeSession( "global", "SAML", "sa", 10000 );

    # Recent SAML session
    _storeSession( "global", "SAML", "sb", 12000 );

    # Old persistent session
    _storeSession( "global", "Persistent", "pa", 10000 );

    # Recent persistent session
    _storeSession( "global", "Persistent", "pb", 12000 );

    _test_purge(16000);
    is_deeply(
        _getSessionsNames("global"),
        [ "b", "pa", "pb", "sb" ],
        "Only recent SSO/SAML sessions and all psessions"
    );

};
subtest "Multiple backends" => sub {
    _cleanSessions;

    # Old SSO session
    _storeSession( "global", "SSO", "a", 10000 );

    # Recent SSO session
    _storeSession( "global", "SSO", "b", 12000 );

    # Old SAML session
    _storeSession( "saml", "SAML", "sa", 10000 );

    # Recent SAML session
    _storeSession( "saml", "SAML", "sb", 12000 );

    # Old persistent session
    _storeSession( "persistent", "Persistent", "pa", 10000 );

    # Recent persistent session
    _storeSession( "persistent", "Persistent", "pb", 12000 );

    _test_purge(16000);
    is_deeply( _getSessionsNames("global"),
        ["b"], "Only SSO session b remains" );
    is_deeply( _getSessionsNames("saml"),
        ["sb"], "Only SAML session sb remains" );
    is_deeply(
        _getSessionsNames("persistent"),
        [ "pa", "pb" ],
        "Both psessions remain"
    );

};

done_testing();
