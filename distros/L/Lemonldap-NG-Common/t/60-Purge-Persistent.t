use warnings;
use strict;

use Test::More;
use Time::Fake;
use POSIX qw(strftime);
use t::TestLogger;
use t::TestAuditLogger;
BEGIN { use_ok('Lemonldap::NG::Common::Session') }

use File::Temp;
my $dir = File::Temp::tempdir( "sessionsXXXXXX", DIR => "t/", CLEANUP => 1 );
mkdir("$dir/global");
mkdir("$dir/global-lock");
mkdir("$dir/persistent");
mkdir("$dir/persistent-lock");

my $conf = {
    logLevel                 => "info",
    timeout                  => '5000',
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
    my (@items) = @_;
    my $sum = 0;
    map { $sum += $_ } @items;
    return $sum;
}

# Helper method to create generic sessions
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

# Helper method to create psessions
sub _storePSession {
    my ( $backend, $name, $creation_time, $update_time, $extra_info ) = @_;

    my $updateTime = strftime( "%Y%m%d%H%M%S", localtime($update_time) );
    my $session    = Lemonldap::NG::Common::Session->new( {
            storageModule        => $conf->{"${backend}Storage"},
            storageModuleOptions => $conf->{"${backend}StorageOptions"},
            kind                 => 'Persistent',
            info                 => {
                _utime => $creation_time,
                (
                    $update_time
                    ? ( _updateTime =>
                          strftime( "%Y%m%d%H%M%S", localtime($update_time) ) )
                    : ()
                ),
                _session_uid => $name,
                %{ $extra_info // {} },
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
        "_session_uid"
      );
    return [ sort map { $sessions->{$_}->{_session_uid} } keys %$sessions ];
}

sub _test_purge {
    my ( $time, $purge_opts, $extra_conf, $creation_opts ) = @_;
    $extra_conf    //= {};
    $creation_opts //= {};
    $purge_opts    //= {};

    # Help with debugging unit tests
    #    use Lemonldap::NG::Common::Logger::Std;
    # my $logger =
    #  Lemonldap::NG::Common::Logger::Std->new( { logLevel => "debug" } );

    my $logger      = t::TestLogger->new;
    my $auditLogger = t::TestAuditLogger->new;
    my $purge       = Lemonldap::NG::Common::Session::Purge->new(
        conf         => { %$conf, %$extra_conf },
        logger       => $logger,
        _auditLogger => $auditLogger,
        %$creation_opts
    );
    Time::Fake->offset($time);
    my $result = $purge->persistentPurge($purge_opts);

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
    $logger->contains( "info", qr/Persistent session purge completed/ );

    $result->{auditLogger} = $auditLogger;
    return $result;
}

use_ok( 'Lemonldap::NG::Common::Session::Purge', "Module successfully loaded" );

subtest "Purge psessions that are too old" => sub {
    _cleanSessions;

    _storePSession( "persistent", "dwho",   10000, 40000 );
    _storePSession( "persistent", "rtyler", 30000, 40000 );

    _test_purge( 50000, { age => "30000" } );
    is_deeply(
        _getSessionsNames('persistent'), ['rtyler'], "Expected remaining
        psession"
    );
};

subtest "test audit logger" => sub {
    _cleanSessions;

    _storePSession( "persistent", "dwho", 10000, 40000 );

    my $result = _test_purge( 50000, { age => "30000" } );
    is_deeply( $result->{auditLogger}->logs, [], "No audit logs generated" );

    _cleanSessions;

    _storePSession( "persistent", "dwho", 10000, 40000 );

    $result = _test_purge( 50000, { age => "30000" }, {}, { audit => 1 } );
    $result->{auditLogger}
      ->contains( 'code' => 'PSESSION_REMOVED', 'user' => 'dwho' );
};

subtest "Purge psessions that are inactive" => sub {
    _cleanSessions;

    _storePSession( "persistent", "dwho",   10000, 40000 );
    _storePSession( "persistent", "rtyler", 10000, 20000 );

    _test_purge( 50000, { update => "20000" } );
    is_deeply(
        _getSessionsNames('persistent'), ['dwho'], "Expected remaining
        psession"
    );
};

subtest "Purge psessions that have no 2FA" => sub {
    _cleanSessions;

    _storePSession( "persistent", "nokey", 10000, 40000 );
    _storePSession( "persistent", "emptykey", 10000, 20000,
        { _2fDevices => "[]" } );
    _storePSession( "persistent", "2fauser", 10000, 20000,
        { _2fDevices => '[ { "fake": "1" } ]' } );

    _test_purge( 50000, { sfdevice => 1 } );
    is_deeply(
        _getSessionsNames('persistent'), ['2fauser'], "Expected remaining
        psession"
    );
};

subtest "Purge psessions without a recent successful login" => sub {
    _cleanSessions;

    # No login history, should not be purged
    _storePSession( "persistent", "nologin", 10000, 40000 );

    # empty login history, should be purged
    _storePSession( "persistent", "emptylogin", 10000, 20000,
        { _loginHistory => {} } );

    # recent login success, should not be purged
    _storePSession( "persistent", "recentlogin", 10000, 20000,
        { _loginHistory => { successLogin => [ { _utime => "40000" } ] } } );

    # old login success, should be purged
    _storePSession( "persistent", "oldlogin", 10000, 20000,
        { _loginHistory => { successLogin => [ { _utime => "20000" } ] } } );

    _test_purge( 50000, { login => "20000" } );
    is_deeply(
        _getSessionsNames('persistent'), ["recentlogin"], "Expected remaining
        psession"
    );

};

subtest "Purge psessions without a successful login" => sub {
    _cleanSessions;

    # No login history, should not be purged
    _storePSession( "persistent", "nologin", 10000, 40000 );

    # empty login history, should be purged
    _storePSession( "persistent", "emptylogin", 10000, 20000,
        { _loginHistory => {} } );

    # recent login success, should not be purged
    _storePSession( "persistent", "recentlogin", 10000, 20000,
        { _loginHistory => { successLogin => [ { _utime => "40000" } ] } } );

    # old login success, should not be purged
    _storePSession( "persistent", "oldlogin", 10000, 20000,
        { _loginHistory => { successLogin => [ { _utime => "20000" } ] } } );

    _test_purge( 50000, { login => undef } );
    is_deeply(
        _getSessionsNames('persistent'), [ "oldlogin", "recentlogin" ],
        "Expected remaining
        psession"
    );

};

subtest "Combining filters" => sub {
    _cleanSessions;

    # Old creation date, but has a recent login
    _storePSession( "persistent", "dwho", 10000, 40000,
        { _loginHistory => { successLogin => [ { _utime => "40000" } ] } } );

    # No recent login, but recent
    _storePSession( "persistent", "rtyler", 40000, 40000,
        { _loginHistory => {} } );

    # Recently created + recent login
    _storePSession( "persistent", "msmith", 40000, 40000,
        { _loginHistory => { successLogin => [ { _utime => "40000" } ] } } );

    # Old + no recent login
    _storePSession( "persistent", "dalek", 10000, 10000,
        { _loginHistory => { successLogin => [ { _utime => "10000" } ] } } );

    _test_purge( 50000, { login => "20000", age => "20000" } );
    is_deeply(
        _getSessionsNames('persistent'), [ "dwho", "msmith", "rtyler" ],
        "Expected remaining
        psession"
    );
};

subtest "API safety, do not remove all psessions when no filters" => sub {
    _cleanSessions;

    _storePSession( "persistent", "dwho", 10000, 40000 );

    _test_purge(50000);
    is_deeply(
        _getSessionsNames('persistent'), ["dwho"],
        "Expected remaining
        psession"
    );
};

done_testing();
