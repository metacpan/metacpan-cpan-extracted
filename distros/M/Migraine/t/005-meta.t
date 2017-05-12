#!/usr/bin/perl

use strict;
use warnings;

use lib qw(t);
use Test::More;
use Test::Deep;
use File::Basename;

use MigraineTester;

my $migraine_tester = MigraineTester->new(__FILE__, plan => 23);

my $migrator = $migraine_tester->migrator;

ok($migrator);
ok(!$migrator->migraine_metadata_present);
is($migrator->current_version, 0);
$migrator->create_migraine_metadata;
ok($migrator->migraine_metadata_present);
is($migrator->current_version, 0);


# Check different formats ====================================================
my $dbh = $migrator->dbh;

# Format 1 -------------------------------------------------------------------
$dbh->do("DROP TABLE migraine_meta");
$dbh->do("CREATE TABLE migraine_meta (version integer);");
$dbh->prepare("INSERT INTO migraine_meta (version) VALUES (?)")->execute(1);
is($migrator->migraine_metadata_version, 1);

# Format 2 -------------------------------------------------------------------
$dbh->do("DROP TABLE migraine_meta");
$dbh->do("CREATE TABLE migraine_meta (name varchar(20), value varchar(50));");
$dbh->prepare("INSERT INTO migraine_meta (name, value) VALUES (?, ?)")->
      execute('metadata_version', 2);
is($migrator->migraine_metadata_version, 2);

# Some future, non-integer format --------------------------------------------
$dbh->do("DROP TABLE migraine_meta");
$dbh->do("CREATE TABLE migraine_meta (name varchar(20), value varchar(50));");
$dbh->prepare("INSERT INTO migraine_meta (name, value) VALUES (?, ?)")->
      execute('metadata_version', '3.5');
is($migrator->migraine_metadata_version, 3.5);

# Unknown/broken formats -----------------------------------------------------
# Different meta name
$dbh->do("DROP TABLE migraine_meta");
$dbh->do("CREATE TABLE migraine_meta (name varchar(20), value varchar(50));");
$dbh->prepare("INSERT INTO migraine_meta (name, value) VALUES (?, ?)")->
      execute('metadata_format', 3);
my $error = 1;
eval {
    $migrator->migraine_metadata_version;
    $error = 0;
};
is($error, 1, "A strange format should throw an error (1)");

# Different column name
$dbh->do("DROP TABLE migraine_meta");
$dbh->do("CREATE TABLE migraine_meta (namez varchar(20), value varchar(50));");
$dbh->prepare("INSERT INTO migraine_meta (namez, value) VALUES (?, ?)")->
      execute('metadata_version', 3);
$error = 1;
eval {
    $migrator->migraine_metadata_version;
    $error = 0;
};
is($error, 1, "A strange format should throw an error (2)");


# Check upgrades =============================================================
# From format 0 --------------------------------------------------------------
$dbh->do("DROP TABLE migraine_meta");
$dbh->do("DROP TABLE migraine_migrations");
is($migrator->migraine_metadata_version, 0);
ok($migrator->upgrade_migraine_metadata,
   "Should be able to upgrade from format 0");
is($migrator->migraine_metadata_version, 2);

# From format 1 --------------------------------------------------------------
$dbh->do("DROP TABLE migraine_meta");
$dbh->do("DROP TABLE migraine_migrations");
$dbh->do("CREATE TABLE migraine_meta (version integer);");
$dbh->prepare("INSERT INTO migraine_meta (version) VALUES (?)")->execute(8);
is($migrator->migraine_metadata_version, 1);
ok($migrator->upgrade_migraine_metadata,
   "Should be able to upgrade from format 1");
is($migrator->migraine_metadata_version, 2);
cmp_deeply([ $migrator->applied_migrations ],
           [qw(1 2 3 4 5 6 7 8)],
           "After upgrade, the list of applied migrations should be correct");
my $res = $migrator->dbh->selectall_arrayref("SELECT COUNT(*)
                                                FROM migraine_meta");
is($res->[0]->[0], 1,
   "There shouldn't be old cruft in migraine_migrations after upgrading");

# From format 2 --------------------------------------------------------------
$dbh->do("DROP TABLE migraine_meta");
$dbh->do("DROP TABLE migraine_migrations");
$dbh->do("CREATE TABLE migraine_meta (name varchar(20), value varchar(50));");
$dbh->do("CREATE TABLE migraine_migrations (id integer,
                                            PRIMARY KEY (id));");
$dbh->prepare("INSERT INTO migraine_meta (name, value) VALUES (?, ?)")->
      execute('metadata_version', 2);
my $sth = $dbh->prepare("INSERT INTO migraine_migrations (id) VALUES (?)");
$sth->execute(1);
$sth->execute(2);
$sth->execute(3);
is($migrator->migraine_metadata_version, 2);
cmp_deeply([ $migrator->applied_migrations ], [qw(1 2 3)]);
ok($migrator->upgrade_migraine_metadata,
   "Should be able to upgrade from format 2");
is($migrator->migraine_metadata_version, 2);
cmp_deeply([ $migrator->applied_migrations ], [qw(1 2 3)]);
