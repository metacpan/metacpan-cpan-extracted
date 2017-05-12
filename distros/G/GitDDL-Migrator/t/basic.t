use strict;
use warnings;
use Test::More;
use Test::Git;
use Test::Requires::Git;

use File::Spec;
use File::Path 'make_path';
use DBI;
use Time::HiRes;

eval q[use DBD::SQLite;];
if ($@) {
    plan skip_all => 'DBD::SQLite is required to run this test';
}

test_requires_git;

use_ok 'GitDDL::Migrator';

my $repo = test_repository;#( temp => [ CLEANUP => 0 ]);

my $gd = GitDDL::Migrator->new(
    work_tree => $repo->work_tree,
    ddl_file  => File::Spec->catfile('sql', 'ddl.sql'),
    dsn       => ['dbi:SQLite:dbname=:memory:', '', ''],
);

my $first_sql = <<__SQL__;
CREATE TABLE first (
    id INTEGER NOT NULL,
    name VARCHAR(191)
);
__SQL__

make_path(File::Spec->catfile($repo->work_tree, 'sql'));

open my $fh, '>', File::Spec->catfile($repo->work_tree, 'sql', 'ddl.sql') or die $!;
print $fh $first_sql;
close $fh;

$repo->run('add', File::Spec->catfile('sql', 'ddl.sql'));
$repo->run('commit', '--author', 'Daisuke Murase <typester@cpan.org>',
                     '-m', 'initial commit');

ok !$gd->database_version;
$gd->deploy;

$gd->_dbh->do('INSERT INTO first (id, name) VALUES (1, "test")')
    or die $gd->_dbh->errstr;

my $first_version = $gd->database_version;
ok $first_version, 'first version ok';

is $gd->ddl_version, $first_version, 'ddl_version == database_version ok';
ok $gd->check_version, 'check_version ok';

my $second_sql = <<__SQL__;
CREATE TABLE second (
    id INTEGER NOT NULL,
    name VARCHAR(191)
);
__SQL__

open $fh, '>>', File::Spec->catfile($repo->work_tree, 'sql', 'ddl.sql') or die $!;
print $fh $second_sql;
close $fh;

$repo->run('add', File::Spec->catfile('sql', 'ddl.sql'));
$repo->run('commit', '--author', 'Daisuke Murase <typester@cpan.org>',
                     '-m', 'initial commit');

ok !$gd->check_version, 'check_version not ok ok';

like $gd->diff, qr/CREATE TABLE second/, 'diff looks ok';

eval {
    $gd->rollback_diff;
};
like $@, qr/No rollback/;

sleep 0.001;
$gd->upgrade_database;
like $gd->rollback_diff, qr/DROP TABLE.*second.*/;

$gd->_dbh->do('INSERT INTO second (id, name) VALUES (1, "test")')
    or die $gd->_dbh->errstr;

ok $gd->check_version, 'check_version ok again';

$gd->check_ddl_mismatch;
pass 'no mismatch';

my $version = $gd->ddl_version;
my ($short_version) = $version =~ /^(.{10})/;
is $gd->_restore_full_hash($short_version), $version;

done_testing;
