package Fey::Test::mysql;
{
  $Fey::Test::mysql::VERSION = '0.10';
}

use strict;
use warnings;

use Test::More;

BEGIN {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    unless ( eval { require DBD::mysql; 1 } ) {
        plan skip_all => 'These tests require DBD::mysql';
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
            'dbi:mysql:', q{}, q{},
            { PrintError => 0, RaiseError => 1 }
        );

        $dbh->func( 'dropdb', 'test_Fey', 'admin' );

        # The dropdb command apparently disconnects the handle.
        $dbh = DBI->connect(
            'dbi:mysql:', q{}, q{},
            { PrintError => 0, RaiseError => 1 }
        );

        $dbh->func( 'createdb', 'test_Fey', 'admin' )
            or die $dbh->errstr();

        $dbh = DBI->connect(
            'dbi:mysql:test_Fey', q{}, q{},
            { PrintError => 0, RaiseError => 1 }
        );

        $dbh->do('SET sql_mode = ANSI');

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
CREATE TABLE User (
    user_id   integer       not null  auto_increment,
    username  varchar(255)  unique not null,
    email     text          null,
    PRIMARY KEY (user_id)
) TYPE=INNODB
EOF
        <<'EOF',
CREATE TABLE "Group" (
    group_id   integer       not null  auto_increment,
    name       varchar(255)  not null,
    PRIMARY KEY (group_id),
    UNIQUE (name)
) TYPE=INNODB
EOF
        <<'EOF',
CREATE TABLE UserGroup (
    user_id   integer  not null,
    group_id  integer  not null,
    PRIMARY KEY (user_id, group_id),
    FOREIGN KEY (user_id)  REFERENCES User    (user_id),
    FOREIGN KEY (group_id) REFERENCES "Group" (group_id)
) TYPE=INNODB
EOF
        <<'EOF',
CREATE TABLE Message (
    message_id    INTEGER       NOT NULL  AUTO_INCREMENT,
    quality       DECIMAL(5,2)  NOT NULL  DEFAULT 2.3,
    message       VARCHAR(255)  NOT NULL  DEFAULT 'Some message \'" text',
    message_date  TIMESTAMP     NOT NULL  DEFAULT CURRENT_TIMESTAMP,
    parent_message_id  INTEGER  NULL,
    user_id       INTEGER       NOT NULL,
    PRIMARY KEY (message_id)
) TYPE=INNODB
EOF

        # This has to be done afterwards because the referenced
        # column doesn't exist until the create table is finished,
        # as far as mysql is concerned.
        <<'EOF',
ALTER TABLE Message
    ADD FOREIGN KEY (parent_message_id) REFERENCES Message (message_id)
EOF

        # I have no idea why this doesn't work when it's part of the
        # CREATE for Message
        <<'EOF',
ALTER TABLE Message
    ADD FOREIGN KEY (user_id) REFERENCES User (user_id)
EOF
        <<'EOF',
CREATE VIEW TestView
         AS SELECT user_id FROM User
EOF
    );
}

1;
