# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Manager.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test::More tests => 14;

BEGIN {
    use_ok('Lemonldap::NG::Common::Conf');
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $h;
@ARGV = ("help=groups");
unlink 't/rdbiConf.sql';

SKIP: {
    eval { require DBI; };
    skip( "DBI not installed", 13 ) if ($@);
    my $skipSQLite = 0;

    ok(
        $h = new Lemonldap::NG::Common::Conf( {
                type        => 'RDBI',
                dbiChain    => "DBI:SQLite:dbname=t/rdbiConf.sql",
                dbiUser     => '',
                dbiPassword => '',
            }
        ),
        'RDBI object'
    );

    ok( $h->can('_dbh'), 'Driver is build' );
    eval { require DBD::SQLite };
    skip( "DBD::SQLite not installed", 11 ) if ($@);
    ok( $h->_dbh->{sqlite_unicode} = 1, 'Set unicode' );
    ok(
        $h->_dbh->do(
"CREATE TABLE lmConfig ( cfgNum int not null, field varchar(255) NOT NULL DEFAULT '', value longblob, PRIMARY KEY (cfgNum,field))"
        ),
        'Test database created'
    );

    my @test = (

        #  simple ascii
        { cfgNum => 1, test => 'ascii' },

        #  utf-8
        { cfgNum => 2, test => 'Русский' },

        #  compatible utf8/latin-1 char but with different codes
        { cfgNum => 3, test => 'éà' }
    );

    for ( my $i = 0 ; $i < @test ; $i++ ) {
        ok( $h->store( $test[$i] ) == $i + 1, "Test $i is stored" )
          or print STDERR "$Lemonldap::NG::Common::Conf::msg $!";
        my $cfg;
        ok( $cfg = $h->load( $i + 1 ), "Test $i can be read" )
          or print STDERR "$Lemonldap::NG::Common::Conf::msg $!$@";
        ok( $cfg->{test} eq $test[$i]->{test}, "Test $i is restored" );
    }

    unlink 't/rdbiConf.sql';
}

