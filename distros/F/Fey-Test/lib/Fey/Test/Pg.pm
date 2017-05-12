package Fey::Test::Pg;
{
  $Fey::Test::Pg::VERSION = '0.10';
}

use strict;
use warnings;

use Test::More;

BEGIN {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    unless ( eval { require DBD::Pg; 1 } ) {
        plan skip_all => 'These tests require DBD::Pg';
    }
}

use DBI;
use File::Spec;
use File::Temp ();

{
    my $DBH;

    sub dbh {
        my $class = shift;

        return $DBH if $DBH;

        my $dbh = DBI->connect(
            'dbi:Pg:dbname=template1', q{}, q{},
            { PrintError => 0, RaiseError => 1 }
        );

        eval { $dbh->do('DROP DATABASE test_fey') };
        $dbh->do('CREATE DATABASE test_fey');

        $dbh = DBI->connect(
            'dbi:Pg:dbname=test_fey', q{}, q{},
            { PrintError => 0, RaiseError => 1 }
        );

        # Shuts up "NOTICE" warnings from Pg.
        local $dbh->{PrintWarn} = 0;
        $class->_run_ddl($dbh);

        return $DBH = $dbh;
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
CREATE TABLE "User" (
    user_id   serial   not null,
    username  text     unique not null,
    email     text     null,
    PRIMARY KEY (user_id)
)
EOF
        <<'EOF',
CREATE TABLE "Group" (
    group_id   serial   not null,
    name       text     not null,
    PRIMARY KEY (group_id),
    UNIQUE (name)
)
EOF
        <<'EOF',
CREATE TABLE "UserGroup" (
    user_id   integer  not null,
    group_id  integer  not null,
    PRIMARY KEY (user_id, group_id),
    FOREIGN KEY (user_id)  REFERENCES "User"  (user_id),
    FOREIGN KEY (group_id) REFERENCES "Group" (group_id)
)
EOF
        <<'EOF',
CREATE TABLE "Message" (
    message_id    SERIAL        NOT NULL,
    quality       DECIMAL(5,2)  NOT NULL  DEFAULT 2.3,
    message       VARCHAR(255)  NOT NULL  DEFAULT 'Some message \'" text',
    message_date  DATE          NOT NULL  DEFAULT NOW(),
    parent_message_id  INTEGER  NULL,
    user_id       INTEGER       NOT NULL,
    PRIMARY KEY (message_id),
    FOREIGN KEY (parent_message_id) REFERENCES  "Message" (message_id),
    FOREIGN KEY (user_id)           REFERENCES  "User"  (user_id)
)
EOF
        <<'EOF',
CREATE VIEW "TestView"
         AS SELECT user_id FROM "User"
EOF
    );
}

1;
