#!/usr/bin/perl
# -*- mode: cperl -*-

use lib 't/lib';
use DBI;
use Test::More;
use Kwiki::DB::Test;

eval 'require DBD::SQLite;';

if($@) {
    plan skip_all => 'Test require DBD::SQLite';
} else {
    plan tests => 4;
}

my $hub = Kwiki::DB::Test::load_hub('t/config.dbi.yaml');

ok($hub->db);

my $dbi = $hub->db;
my $dbh = $dbi->connect("dbi:SQLite:dbname=t/dbfile");

$dbh->do("CREATE TABLE foo (f1,f2)");

ok(-f "t/dbfile");

$dbh->do("INSERT INTO foo VALUES (1,2)");

$dbh->disconnect;

$dbh = DBI->connect("dbi:SQLite:dbname=t/dbfile");

my $sth = $dbh->prepare("SELECT * FROM foo");
$sth->execute;
my $h = $sth->fetchrow_hashref;
ok($h->{f1} == 1);
ok($h->{f2} == 2);

unlink("t/dbfile");


