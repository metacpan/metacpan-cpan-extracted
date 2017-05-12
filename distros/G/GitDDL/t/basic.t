use strict;
use warnings;
use Test::More;
use Test::Git;

use File::Spec;
use File::Path 'make_path';
use DBI;

eval q[use DBD::SQLite;];
if ($@) {
    plan skip_all => 'DBD::SQLite is required to run this test';
}

has_git;

use_ok 'GitDDL';

my $repo = test_repository;#( temp => [ CLEANUP => 0 ]);

my $gd = GitDDL->new(
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

eval {
    $gd->database_version;
};
ok $@, 'error ok';
like $@, qr/Failed to get database version, please deploy first/, 'error msg ok';

$gd->deploy;
#
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

$gd->upgrade_database;

$gd->_dbh->do('INSERT INTO second (id, name) VALUES (1, "test")')
    or die $gd->_dbh->errstr;

ok $gd->check_version, 'check_version ok again';

done_testing;
