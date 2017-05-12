use strict;
use warnings;
use Test::Declare;

use lib qw(./t ./lib);
use UniqueTest;

use FormValidator::Simple qw/DBIC::Schema::Unique/;

plan tests => blocks;

{

    {
        use DBIx::Class::ResultSet;
        package UniqueTestResultSet;
        use strict;
        use warnings;
        use base 'DBIx::Class::ResultSet';
        1;
    }
    my $sql = q{
        CREATE TABLE foo (
            id     INT,
            key   TEXT
        );
    };
    my $db_file = '/tmp/fvs_pdsu_test.db';
    my $q = {
        key => 'unique key',
    };

    my $schema;
    sub _connect {
        $schema = UniqueTest->connect("dbi:SQLite:$db_file");
    }
    sub setup_database {
        _connect;
        $schema->storage->dbh->do($sql);
    }
    sub drop_database {
        unlink $db_file;
    }
    sub _rs {
        $schema->resultset('Foo');
    }
    sub insert_data {
        _rs->create($q);
    }
    sub _my_rs {
        $schema->source('Foo')->{resultset_class} = 'UniqueTestResultSet';
        $schema->resultset('Foo');
    }

    sub check_error ($) {
        my $resultset = shift;
        my $result = FormValidator::Simple->check(
            $q => [
                key => [ [qw/DBIC_SCHEMA_UNIQUE key/, $resultset] ],
            ]
        );
        return $result->has_error;
    }
}

describe 'DBIC base resultset' => run {
    init {
        setup_database;
    };
    test 'no error' => run {
        is check_error _rs , '';
    };
    test 'has error' => run {
        insert_data;
        is check_error _rs , 1;
    };
    cleanup {
        drop_database;
    };
};

describe 'my resultset' => run {
    init {
        setup_database;
    };
    test 'no error' => run {
        is check_error _my_rs , '';
    };
    test 'has error' => run {
        insert_data;
        is check_error _my_rs , 1;
    };
    cleanup {
        drop_database;
    };
};

describe 'unknown resultset' => run {
    test 'has_error' => run {
        dies_ok( sub{ check_error 'unknown_rs' } );
    };
};


