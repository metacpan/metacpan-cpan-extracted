use warnings;
use Time::Fake;
use t::TestConfBackend;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Manager.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { use_ok('Lemonldap::NG::Common::Conf') }

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $h;
my $inifile     = "t/lemonldap-ng.ini";
my $confsection = "configuration";

ok( (
        Lemonldap::NG::Common::Conf->new( type => 'bad' ) == 0
          and $Lemonldap::NG::Common::Conf::msg =~
          /Error: failed to load Lemonldap::NG::Common::Conf::Backends::bad/
    ),
    'Bad module'
) or print STDERR "Msg: $Lemonldap::NG::Common::Conf::msg\n";

$h = bless {}, 'Lemonldap::NG::Common::Conf';

ok( (
        %$h = ( %$h, %{ $h->getLocalConf( $confsection, $inifile, 0 ) } )
          and exists $h->{localStorage}
    ),
    "Read $inifile"
);

# A helper function for this test. It calls getConf on a confAccessor with
# supplied arguments.
# After getConf returns, it runs a series of tests on:
# * The resulting status message (msg)
# * The obtained configuration (keys)
# * How many times Conf::Backend methods were called (stats)
sub getConfTest {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $confAcc, $args, %args ) = @_;

    # Store current stats
    my %stats;
    if ( ref( $args{stats} ) eq "HASH" ) {
        while ( my ( $key, $value ) = each %{ $args{stats} } ) {
            $stats{$key} = $t::TestConfBackend::stats{$key} || 0;
        }
    }

    # Invoke getConf
    $Lemonldap::NG::Common::Conf::msg = "";
    note "Invoking getConf with args ", explain $args;

# The test suite runs as root in CI, we need to explicitely enable caching for root
    my $conf = $confAcc->getConf($args);

    # Test result keys
    if ( ref( $args{keys} ) eq "HASH" ) {
        while ( my ( $key, $value ) = each %{ $args{keys} } ) {
            is( $conf->{$key}, $value, "Found expected $key in conf" );
        }
    }

    # Test message
    if ( $args{msg} ) {
        like( $Lemonldap::NG::Common::Conf::msg,
            $args{msg}, "Found expected message" );
    }

    # Test stats
    if ( ref( $args{stats} ) eq "HASH" ) {
        while ( my ( $key, $value ) = each %{ $args{stats} } ) {
            is( $t::TestConfBackend::stats{$key} - $stats{$key},
                $value, "$key counter increased by $value" );
        }
    }

}

subtest "Invalid backend configuration" => sub {
    $Lemonldap::NG::Common::Conf::msg = "";
    t::TestConfBackend::testReset();
    t::TestConfBackend::fail_prereq();

    ok( !Lemonldap::NG::Common::Conf->new( confFile => 't/lemonldap-ng.ini' ),
        "Invalid configuration" );
    like(
        $Lemonldap::NG::Common::Conf::msg,
        qr/Module was set to fail/,
        "Found correct error message"
    );
};

subtest "Cache expiration" => sub {

    Time::Fake->reset;
    t::TestConfBackend::testReset();

    $Lemonldap::NG::Common::Conf::msg = "";
    ok(
        my $c =
          Lemonldap::NG::Common::Conf->new( confFile => 't/lemonldap-ng.ini' ),
        "Valid configuration"
    );
    $c->{refLocalStorage}->Clear();

    getConfTest(
        $c, { local => 1 },
        msg   => qr/Get configuration 1/,
        keys  => { cfgNum  => 1 },
        stats => { lastCfg => 1, load => 1 }
    );

    # Publish new configuration
    push @t::TestConfBackend::conf, { cfgNum => 2, newvalue => "new" };

    # Cache is not expired yet, new value not available
    getConfTest(
        $c, { local => 1 },
        msg   => qr/Get configuration from cache without verification/,
        keys  => { newvalue => undef },
        stats => { lastCfg  => 0, load => 0 }
    );

    # Expire cache
    Time::Fake->offset('+700s');

    # Cache expired, we fetch conf again and expose new value
    getConfTest(
        $c, { local => 1 },
        msg   => qr/Get configuration 2/,
        keys  => { cfgNum  => 2, newvalue => 'new' },
        stats => { lastCfg => 1, load     => 1 }
    );
};

subtest "Configuration reload" => sub {

    Time::Fake->reset;
    t::TestConfBackend::testReset();

    $Lemonldap::NG::Common::Conf::msg = "";
    ok(
        my $c =
          Lemonldap::NG::Common::Conf->new( confFile => 't/lemonldap-ng.ini' ),
        "Valid configuration"
    );
    $c->{refLocalStorage}->Clear();

    # Load initial configuration in cache
    getConfTest(
        $c, { local => 1 },
        msg   => qr/Get configuration 1/,
        keys  => { cfgNum  => 1 },
        stats => { lastCfg => 1, load => 1 }
    );

    # Publish new configuration
    push @t::TestConfBackend::conf, { cfgNum => 2, newvalue => "new" };

    # Force reload
    getConfTest(
        $c, { local => 0 },
        msg   => qr/Get configuration 2/,
        keys  => { cfgNum  => 2, newvalue => "new" },
        stats => { lastCfg => 1, load     => 1 }
    );

    # A new cache enabled access sees the new values
    getConfTest(
        $c, { local => 1 },
        msg   => qr/Get configuration from cache without verification/,
        keys  => { cfgNum  => 2, newvalue => "new" },
        stats => { lastCfg => 0, load     => 0 }
    );
};

subtest "Configuration cache manual clear" => sub {

    Time::Fake->reset;
    t::TestConfBackend::testReset();

    $Lemonldap::NG::Common::Conf::msg = "";
    ok(
        my $c =
          Lemonldap::NG::Common::Conf->new( confFile => 't/lemonldap-ng.ini' ),
        "Valid configuration"
    );
    $c->{refLocalStorage}->Clear();

    # Load initial configuration in cache
    getConfTest(
        $c, { local => 1 },
        msg   => qr/Get configuration 1/,
        keys  => { cfgNum  => 1 },
        stats => { lastCfg => 1, load => 1 }
    );

    # Publish new configuration
    $t::TestConfBackend::conf[0]->{'newvalue'} = "new";

    # Not visible yet
    getConfTest(
        $c, { local => 1 },
        msg   => qr/Get configuration from cache without verification/,
        keys  => { cfgNum  => 1, newvalue => undef },
        stats => { lastCfg => 0, load     => 0 }
    );

    # Force update-cache
    getConfTest(
        $c, { noCache => 2 },
        msg   => qr/Get configuration 1/,
        keys  => { cfgNum  => 1, newvalue => "new" },
        stats => { lastCfg => 1, load     => 1 }
    );

    # Read again directly from cache
    getConfTest(
        $c, { local => 1 },
        msg   => qr/Get configuration from cache without verification/,
        keys  => { cfgNum  => 1, newvalue => "new" },
        stats => { lastCfg => 0, load     => 0 }
    );
};

subtest "local param behavior" => sub {

    Time::Fake->reset;
    t::TestConfBackend::testReset();

    $Lemonldap::NG::Common::Conf::msg = "";
    ok(
        my $c =
          Lemonldap::NG::Common::Conf->new( confFile => 't/lemonldap-ng.ini' ),
        "Valid configuration"
    );
    $c->{refLocalStorage}->Clear();

    # Initial access with a local param
    getConfTest(
        $c, { local => 1, localPrm => { myLocalPrm => 1 } },
        msg   => qr/Get configuration 1/,
        keys  => { cfgNum  => 1, myLocalPrm => 1 },
        stats => { lastCfg => 1, load       => 1 }
    );

    # Store new configuration
    push @t::TestConfBackend::conf, { cfgNum => 2, newvalue => "new" };

    # New access, local param should be kept
    getConfTest(
        $c, {},
        msg   => qr/Get configuration 2/,
        keys  => { cfgNum  => 2, myLocalPrm => 1 },
        stats => { lastCfg => 1, load       => 1 }
    );

    ok(
        my $c2 =
          Lemonldap::NG::Common::Conf->new( confFile => 't/lemonldap-ng.ini' ),
        "Another confAccess object from another process"
    );

    # Store new configuration
    push @t::TestConfBackend::conf, { cfgNum => 3 };

    # Update cache from another process wihout localPrm
    getConfTest(
        $c2, {},
        msg   => qr/Get configuration 3/,
        keys  => { cfgNum  => 3, myLocalPrm => undef },
        stats => { lastCfg => 1, load       => 1 }
    );

    # First process gets config again
    getConfTest(
        $c, { local => 1 },
        msg   => qr/Get configuration from cache without verification/,
        keys  => { cfgNum  => 3, myLocalPrm => 1 },
        stats => { lastCfg => 0, load       => 0 }
    );
};

done_testing;
