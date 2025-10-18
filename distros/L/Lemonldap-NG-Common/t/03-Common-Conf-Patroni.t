use warnings;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Manager.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use LWP::Protocol::PSGI;
use Plack::Request;
use Test::More;

my $db = 'noexist/patroniConf.sql';

BEGIN {
    use_ok('Lemonldap::NG::Common::Conf');
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $h;
@ARGV = ("help=groups");

LWP::Protocol::PSGI->register(
    sub {
        my $req  = Plack::Request->new(@_);
        my $resp = <<'EOT';
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
        return [
            200,
            [
                'Content-Type'   => 'application/json',
                'Content-Length' => length($resp)
            ],
            [$resp],
        ];
    }
);

SKIP: {
    eval { require DBI; };
    skip( "DBI not installed", 13 ) if ($@);
    eval { require DBD::SQLite };
    skip( "DBD::SQLite not installed", 11 ) if ($@);
    my $skipSQLite = 0;

    ok(
        $h = new Lemonldap::NG::Common::Conf( {
                type        => 'Patroni',
                dbiChain    => "DBI:SQLite:dbname=$db",
                dbiUser     => '',
                dbiPassword => '',
                patroniUrl  => 'http://db.com/',
            }
        ),
        'CDBI object'
    );

    ok( $h->can('_dbh'), 'Driver is built' );
    $h->store( { cfgNum => 1, test => 'ascii' } );
    is( $h->{dbiChain},
        'DBI:SQLite:dbname=noexist/patroniConf.sql;host=127.0.0.235;port=5432'
    );

}

done_testing();
