package #
    LogTest;

use strict;
use warnings;

use LogTest::Schema;

sub init_schema {
    my $self = shift();

    my $schema = LogTest::Schema->connect($self->_database());

    $schema->deploy;

    return $schema;
}

sub _database {
    my $self = shift();

    my $db = 't/var/LogTest.db';

    unlink($db) if -e $db;
    unlink($db.'-journal') if -e $db.'-journal';
    mkdir('t/var') unless -d 't/var';

    my $dsn = "dbi:SQLite:$db";

    my @connect = ($dsn, '', '', { AutoCommit => 1});

    return @connect;
}

1;