#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use DBI;

my $dbh = DBI->connect('DBI:SQLite:dbname=t/testdb', '', '', {
  RaiseError => 1,
  ChopBlanks => 1,
});


$dbh->do('DROP TABLE IF EXISTS cities');
$dbh->do('DROP TABLE IF EXISTS states');

$dbh->do(<<'SQL');
create table states (
  state_id    integer not null primary key,
  state_name  varchar(50) not null,
  state_abbr  char(2) not null
);
SQL

$dbh->do(<<'SQL');
create table cities (
  city_id   integer not null primary key,
  state_id  integer not null,
  city_name varchar(100) not null,
  foreign key (state_id) references states (state_id) on delete restrict
);
SQL

ok(1, "Setup properly");

