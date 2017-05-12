use strict;
use warnings;

use Test::More;
use Test::Git;

use File::Path 'make_path';
use GitDDL;
use Try::Tiny;

eval q[use DBD::SQLite;];
if ($@) {
    plan skip_all => 'DBD::SQLite is required to run this test';
}

my $repo = test_repository;#( temp => [ CLEANUP => 0 ]);

my $gd = GitDDL->new(
    work_tree => $repo->work_tree,
    ddl_file  => File::Spec->catfile('sql', 'ddl.sql'),
    dsn       => ['dbi:SQLite:dbname=:memory:', '', ''],
);

my $first_sql = <<__SQL__;
CREATE TABLE first (
    id INTEGER NOT NULL,
    name VARCHAR(191) -- comment
);
__SQL__

make_path(File::Spec->catfile($repo->work_tree, 'sql'));

open my $fh, '>', File::Spec->catfile($repo->work_tree, 'sql', 'ddl.sql') or die $!;
print $fh $first_sql;
close $fh;

$repo->run('add', File::Spec->catfile('sql', 'ddl.sql'));
$repo->run('commit', '--author', 'soh335 <soh@cpan.org>',
                     '-m', 'initial commit');
$gd->deploy;

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
$repo->run('commit', '--author', 'soh335 <soh@cpan.org>',
                     '-m', 'second commit');

try {
    $gd->diff;
    fail "should die";
}
catch {
    like $_, qr/Error with parser/, 'can not parse sql';
};

$gd->sql_filter(sub {
    my $sql = shift;
    $sql =~ s/--.*//;
    $sql;
});

like $gd->diff, qr/CREATE TABLE second/, 'diff looks ok';

done_testing;

