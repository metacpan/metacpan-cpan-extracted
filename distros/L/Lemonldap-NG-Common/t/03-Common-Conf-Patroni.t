use warnings;
use strict;
use LWP::Protocol::PSGI;
use Test::More;

my $db = 'noexist/patroniConf.sql';

BEGIN {
    use_ok('Lemonldap::NG::Common::Conf');
}

my $h;
@ARGV = ("help=groups");

# Normal Patroni response helper
my $patroni_response;

sub setup_patroni_mock {
    LWP::Protocol::PSGI->register(
        sub {
            return [
                200,
                [
                    'Content-Type'   => 'application/json',
                    'Content-Length' => length($patroni_response)
                ],
                [$patroni_response],
            ];
        }
    );
}

SKIP: {
    eval { require DBI; };
    skip( "DBI not installed", 5 ) if ($@);
    eval { require DBD::SQLite };
    skip( "DBD::SQLite not installed", 5 ) if ($@);

    subtest 'Basic Patroni functionality' => sub {
        plan tests => 7;

        $patroni_response = <<'EOT';
{
  "members": [
    {
      "role":"leader",
      "host":"127.0.0.235",
      "port":"5432"
    }
  ]
}
EOT
        setup_patroni_mock();

        ok(
            $h = new Lemonldap::NG::Common::Conf( {
                    type        => 'Patroni',
                    dbiChain    => "DBI:SQLite:dbname=$db",
                    dbiUser     => '',
                    dbiPassword => '',
                    patroniUrl  => 'http://db.com/',
                }
            ),
            'Create Patroni backend object'
        );

        ok( $h->can('_dbh'), 'Driver has _dbh method' );
        $h->store( { cfgNum => 1, test => 'ascii' } );
        is(
            $h->{dbiChain},
'DBI:SQLite:dbname=noexist/patroniConf.sql;host=127.0.0.235;port=5432',
            'dbiChain updated with leader host/port'
        );

        ok( $h->{patroniLastLeader}, 'Leader info cached' );
        is( $h->{patroniLastLeader}->{host},
            '127.0.0.235', 'Cached leader host is correct' );
        is( $h->{patroniLastLeader}->{port},
            '5432', 'Cached leader port is correct' );
        ok( $h->{patroniLastLeader}->{time}, 'Cache timestamp set' );
    };

    subtest 'Configuration options' => sub {
        plan tests => 2;

        ok(
            $h = new Lemonldap::NG::Common::Conf( {
                    type           => 'Patroni',
                    dbiChain       => "DBI:SQLite:dbname=$db",
                    dbiUser        => '',
                    dbiPassword    => '',
                    patroniUrl     => 'http://db.com/',
                    patroniTimeout => 5,
                }
            ),
            'Create Patroni backend with custom timeout'
        );

        ok(
            $h = new Lemonldap::NG::Common::Conf( {
                    type        => 'Patroni',
                    dbiChain    => "DBI:SQLite:dbname=$db",
                    dbiUser     => '',
                    dbiPassword => '',
                    patroniUrl  =>
                      'http://db1.com/, http://db2.com/, http://db3.com/',
                }
            ),
            'Create Patroni backend with multiple URLs'
        );
    };

    subtest 'Cache fallback mechanism' => sub {
        plan tests => 3;

        $patroni_response = <<'EOT';
{
  "members": [
    {
      "role":"leader",
      "host":"127.0.0.100",
      "port":"5433"
    }
  ]
}
EOT
        setup_patroni_mock();

        ok(
            $h = new Lemonldap::NG::Common::Conf( {
                    type            => 'Patroni',
                    dbiChain        => "DBI:SQLite:dbname=$db",
                    dbiUser         => '',
                    dbiPassword     => '',
                    patroniUrl      => 'http://db.com/',
                    patroniCacheTTL => 120,
                }
            ),
            'Create backend with custom cache TTL'
        );

        $h->store( { cfgNum => 5, test => 'test1' } );
        ok( $h->{patroniLastLeader}, 'Leader cached after first store' );

        # Simulate Patroni API failure
        LWP::Protocol::PSGI->register(
            sub {
                return [
                    500, [ 'Content-Type' => 'text/plain' ],
                    ['Server Error']
                ];
            }
        );

        delete $h->{_dbh};    # Force reconnection
        eval { $h->store( { cfgNum => 6, test => 'test2' } ); };

        like(
            $h->{dbiChain},
            qr/host=127\.0\.0\.100;port=5433/,
            'Uses cached leader when Patroni API unavailable'
        );
    };

    subtest 'Split-brain detection' => sub {
        plan tests => 1;

        $patroni_response = <<'EOT';
{
  "members": [
    {
      "role":"leader",
      "host":"127.0.0.1",
      "port":"5432",
      "state":"running"
    },
    {
      "role":"leader",
      "host":"127.0.0.2",
      "port":"5432",
      "state":"running"
    }
  ]
}
EOT
        setup_patroni_mock();

        $h = new Lemonldap::NG::Common::Conf( {
                type        => 'Patroni',
                dbiChain    => "DBI:SQLite:dbname=$db",
                dbiUser     => '',
                dbiPassword => '',
                patroniUrl  => 'http://db.com/',
            }
        );

        my $stderr;
        {
            local *STDERR;
            open STDERR, '>', \$stderr;
            eval { $h->store( { cfgNum => 7, test => 'split' } ); };
        }

        like(
            $stderr,
            qr/Multiple leaders detected/,
            'Split-brain warning logged'
        );
    };

    subtest 'Leader health state validation' => sub {
        plan tests => 3;

        # Non-running state should be rejected
        $patroni_response = <<'EOT';
{
  "members": [
    {
      "role":"leader",
      "host":"127.0.0.50",
      "port":"5432",
      "state":"starting"
    }
  ]
}
EOT
        setup_patroni_mock();

        $h = new Lemonldap::NG::Common::Conf( {
                type        => 'Patroni',
                dbiChain    => "DBI:SQLite:dbname=$db",
                dbiUser     => '',
                dbiPassword => '',
                patroniUrl  => 'http://db.com/',
            }
        );

        my $stderr;
        {
            local *STDERR;
            open STDERR, '>', \$stderr;
            eval { $h->store( { cfgNum => 8, test => 'starting' } ); };
        }

        like(
            $stderr,
            qr/not in running state/,
            'Non-running leader state warning logged'
        );

        # Running state should be accepted
        $patroni_response = <<'EOT';
{
  "members": [
    {
      "role":"leader",
      "host":"127.0.0.60",
      "port":"5432",
      "state":"running"
    }
  ]
}
EOT
        setup_patroni_mock();

        $h = new Lemonldap::NG::Common::Conf( {
                type        => 'Patroni',
                dbiChain    => "DBI:SQLite:dbname=$db",
                dbiUser     => '',
                dbiPassword => '',
                patroniUrl  => 'http://db.com/',
            }
        );

        eval { $h->store( { cfgNum => 9, test => 'running_state' } ); };
        like(
            $h->{dbiChain},
            qr/host=127\.0\.0\.60;port=5432/,
            'Leader with running state accepted'
        );

        # Missing state field (backward compatibility)
        $patroni_response = <<'EOT';
{
  "members": [
    {
      "role":"leader",
      "host":"127.0.0.70",
      "port":"5432"
    }
  ]
}
EOT
        setup_patroni_mock();

        $h = new Lemonldap::NG::Common::Conf( {
                type        => 'Patroni',
                dbiChain    => "DBI:SQLite:dbname=$db",
                dbiUser     => '',
                dbiPassword => '',
                patroniUrl  => 'http://db.com/',
            }
        );

        eval { $h->store( { cfgNum => 10, test => 'no_state' } ); };
        like(
            $h->{dbiChain},
            qr/host=127\.0\.0\.70;port=5432/,
            'Leader without state field accepted (backward compat)'
        );
    };

}

done_testing();
