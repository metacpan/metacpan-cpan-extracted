# Test for https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/-/issues/2493

use warnings;
use strict;
use Data::Dumper;
use IO::String;
use JSON qw(from_json);
use Test::More;

require 't/test-lib.pm';

my $count     = 0;
my $file      = "$main::tmpdir/conf/conf.db";
my $maintests = 8;
my ( $res, $client );
eval { unlink $file };

sub count {
    my $c = shift;
    $count += $c if ($c);
    return $count;
}

SKIP: {
    eval { require DBI; require DBD::SQLite; };
    if ($@) {
        skip 'DBD::SQLite not found', $maintests;
    }

    my $dbh = DBI->connect("dbi:SQLite:dbname=$file");
    $dbh->do(
"CREATE TABLE lmConfig ( cfgNum int not null, field varchar(255) NOT NULL DEFAULT '', value longblob, PRIMARY KEY (cfgNum,field))"
    ) or die $DBI::errstr;
    use_ok('Lemonldap::NG::Common::Conf');
    my $h;
    ok(
        $h = new Lemonldap::NG::Common::Conf( {
                type        => 'RDBI',
                dbiChain    => "DBI:SQLite:dbname=$file",
                dbiUser     => '',
                dbiPassword => '',
            }
        ),
        'RDBI object'
    );
    {
        local $/ = undef;
        open my $f, '<', "$main::tmpdir/conf/lmConf-1.json";
        my $content = <$f>;
        close $f;
        ok( $h->store( from_json($content) ), 'Conf 1 saved' );
    }

    use_ok('Lemonldap::NG::Manager::Cli::Lib');
    ok(
        $client = Lemonldap::NG::Manager::Cli::Lib->new(
            iniFile => "$main::tmpdir/lemonldap-ng-DBI-conf.ini"
        ),
        'Client object'
    );

    use_ok('Lemonldap::NG::Manager::Cli');

    my @args = (qw(-yes 1 -force 1 set ldapSetPassword 0));
    $ENV{LLNG_DEFAULTCONFFILE} = "$main::tmpdir/lemonldap-ng-DBI-conf.ini";
    Lemonldap::NG::Manager::Cli->run(@args);
    my $res = $dbh->selectrow_hashref(
        "SELECT * FROM lmConfig WHERE field='ldapSetPassword'");
    ok( $res,                         'Key inserted' );
    ok( $res && $res->{value} == '0', 'Value is 0' );
}

eval { unlink $file };
done_testing( count($maintests) );
