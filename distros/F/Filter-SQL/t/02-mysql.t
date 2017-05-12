#! /usr/bin/perl

use strict;
use warnings;
use Filter::SQL qw(:mysql);
use Test::More;

BEGIN {
    if (! defined $ENV{FILTER_SQL_DBI}
            || $ENV{FILTER_SQL_DBI} !~ /^dbi:mysql:/) {
        plan skip_all => 'Skipping MySQL specific tests';
    } else {
        plan tests => 10;
    }
};

ok(EXEC CREATE TEMPORARY TABLE filter_sql_t (
    id INT NOT NULL AUTO_INCREMENT,
    str VARCHAR (255),
    PRIMARY KEY (id),
    UNIQUE KEY str (str)
););

is(mysql_insert_id(), 0);
ok(INSERT INTO filter_sql_t (str) VALUES ("abc"););
is(mysql_insert_id(), 1);
ok(INSERT INTO filter_sql_t(str) VALUES ("def"););
is(mysql_insert_id(), 2);
ok(INSERT IGNORE INTO filter_sql_t (str) VALUES ("def"););
is(mysql_insert_id(), 0);
ok(INSERT IGNORE INTO filter_sql_t (str) VALUES ("ghi"););
isnt(mysql_insert_id(), 0); # just check it is not null
