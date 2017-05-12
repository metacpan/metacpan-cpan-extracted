package Fey::Test::SQLite;
{
  $Fey::Test::SQLite::VERSION = '0.10';
}

use strict;
use warnings;

use Test::More;

BEGIN {
    unless ( eval 'use DBD::SQLite 1.14; 1' ) {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        plan skip_all => 'These tests require DBD::SQLite 1.14+';
    }
}

use DBI;
use File::Spec;
use File::Temp ();

{
    my $DBH;
    my $DSN;

    sub dbh {
        my $class = shift;

        return $DBH if $DBH;

        my $dir = File::Temp::tempdir( CLEANUP => 1 );
        my $file = File::Spec->catfile( $dir, 'test_fey.sqlite' );

        $DSN = "dbi:SQLite:dbname=$file";

        my $dbh = DBI->connect( $DSN, '', '', { RaiseError => 1 } );

        $class->_run_ddl($dbh);

        return $DBH = $dbh;
    }

    sub dsn {
        shift->dbh();

        return $DSN;
    }
}

sub _run_ddl {
    my $class = shift;
    my $dbh   = shift;

    for my $ddl ( $class->_sql() ) {
        $dbh->do($ddl);
    }
}

sub _sql {
    return (
        <<'EOF',
CREATE TABLE User (
    user_id   integer  not null  primary key autoincrement,
    username  text     not null,
    email     text     null,
    UNIQUE (username)
)
EOF
        <<'EOF',
CREATE TABLE "Group" (
    group_id   integer  not null  primary key autoincrement,
    name       text     not null,
    UNIQUE (name)
)
EOF
        <<'EOF',
CREATE TABLE UserGroup (
    user_id   integer  not null,
    group_id  integer  not null,
    PRIMARY KEY (user_id, group_id)
)
EOF
        <<'EOF',
CREATE TABLE Message (
    message_id    INTEGER     NOT NULL  PRIMARY KEY AUTOINCREMENT,
    quality       REAL(5,2)   NOT NULL  DEFAULT 2.3,
    message       TEXT        NOT NULL  DEFAULT 'Some message ''" text',
    message_date  DATE        NOT NULL  DEFAULT CURRENT_DATE,
    parent_message_id  INTEGER  NULL,
    user_id       INTEGER     NOT NULL
)
EOF
        <<'EOF',
CREATE VIEW TestView
         AS SELECT user_id FROM User
EOF
    );
}

1;
