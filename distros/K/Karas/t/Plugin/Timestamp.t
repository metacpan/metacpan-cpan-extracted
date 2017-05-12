use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'DBD::SQLite', 'Test::Time';
use Test::Time;
use Karas;
use Karas::Loader;
use feature 'state';

{
    package MyDB;
    use parent qw/Karas/;
    __PACKAGE__->load_plugin('Timestamp');
}

sub create_karas($) {
    my $dbh = shift;
    state $i = 0;
    my $schema = Karas::Loader->load_schema(
        connect_info => [
            'dbi:PassThrough:', '', '', {
            pass_through_source => $dbh
        }],
        namespace => "MyDB" . $i++,
    );
    my $db = MyDB->new(
        connect_info => [
            'dbi:PassThrough:', '', '', {
            pass_through_source => $dbh
        }],
        row_class_map => $schema,
    );
    return $db;
}


subtest 'SQLite' => sub {
    my $create_dbh = sub {
        my $dbh = DBI->connect(
            'dbi:SQLite::memory:', '', '', {
            RaiseError => 1,
            PrintError => 0,
        });
        $dbh->do(q{CREATE TABLE foo (id integer PRIMARY KEY, name VARCHAR(255), created_on integer, updated_on integer)});
        return $dbh;
    };
    run_test($create_dbh);
};

subtest 'mysql' => sub {
    no warnings 'once';
    eval q{ require Test::mysqld; 1; } or plan skip_all => "Missing Test::mysqld";
    my $mysqld = Test::mysqld->new(
        my_cnf => {
            'skip-networking' => '',    # no TCP socket
        }
    ) or plan skip_all => $Test::mysqld::errstr;
    my $dbh = DBI->connect( $mysqld->dsn(dbname => 'test'), {RaiseError => 1} );
    $dbh->do(q{CREATE TABLE foo (id integer PRIMARY KEY, name VARCHAR(255), created_on integer, updated_on integer)});

    my $create_dbh = sub {
        $dbh->do(q{TRUNCATE TABLE foo});
        return $dbh;
    };
    run_test($create_dbh);
};

done_testing;

sub run_test {
    my $create_dbh = shift;

    subtest 'insert' => sub {
        my $dbh = $create_dbh->();
        my $db = create_karas($dbh);
        $db->insert(foo => {
            id => 1,
            name => 'heh',
        });
        my $row = $db->retrieve(foo => 1);
        ok($row->created_on);
        ok($row->updated_on);
    };

    subtest 'replace' => sub {
        my $dbh = $create_dbh->();
        my $db = create_karas($dbh);
        $db->replace(foo => {
            id => 1,
            name => 'heh',
        });
        my $row = $db->retrieve(foo => 1);
        ok($row->created_on);
        ok($row->updated_on);
    };

    subtest 'bulk_insert' => sub {
        my $dbh = $create_dbh->();
        my $db = create_karas($dbh);
        $db->bulk_insert(foo => [
            {id => 1, name => 'heh'},
            {id => 2, name => 'bar'},
        ]);
        {
            my $row = $db->retrieve(foo => 1);
            ok($row);
            ok($row->created_on);
            ok($row->updated_on);
        }
        {
            my $row = $db->retrieve(foo => 2);
            ok($row);
            ok($row->created_on);
            ok($row->updated_on);
        }
    };

    subtest 'update_row' => sub {
        my $dbh = $create_dbh->();
        my $db = create_karas($dbh);
        $db->insert(foo => {
            id => 1,
            name => 'heh',
        });
        my $row = $db->retrieve(foo => 1);
        sleep 2;
        $db->update($row, {name => 'Yoshio'});
        $row = $db->refetch($row);
        isnt($row->created_on, $row->updated_on);
    };

    subtest 'update_direct' => sub {
        my $dbh = $create_dbh->();
        my $db = create_karas($dbh);
        $db->insert(foo => {
            id => 1,
            name => 'heh',
        });
        my $row = $db->retrieve(foo => 1);
        sleep 2;
        $db->update('foo' => {name => 'Yoshio'}, {id => 1});
        $row = $db->refetch($row);
        isnt($row->created_on, $row->updated_on);
    };
}
