use strict;
use warnings;
use Test::More;
use Test::Mock::Furl;

use File::Path qw/make_path/;
use File::Spec;
use File::Temp qw/tempdir/;
use Try::Tiny;
use DBI;

eval q[use DBD::SQLite;];
if ($@) {
    plan skip_all => 'DBD::SQLite is required to run this test';
}

use_ok 'GitHubDDL';

my $github_user = "mackee";
my $github_repo = "GitHubDDL";
my $github_token = "my_github_token";
my $ddl_file = File::Spec->catfile('sql', 'ddl.sql');

my $mocking_furl = sub {
    my ($commit_hash, $ddl) = @_;
    $Mock_furl->mock(
        request => sub {
            my ($self, %args) = @_;
            is $args{method}, "GET", "to github request method is valid";
            is $args{url}, sprintf(
                "https://raw.githubusercontent.com/%s/%s/%s/%s",
                $github_user,
                $github_repo,
                $commit_hash,
                $ddl_file,
            ), "to github request url is valid";
            my %headers = @{$args{headers}};
            is $headers{Authorization}, "token " . $github_token, "to github request token is valid";
            is $headers{Accept}, "application/vnd.github.v3+raw", "to github request accept header is valid";

            $args{write_code}->(200, "OK", [], $ddl);
        },
    );
};

my $dir = tempdir(CLEANUP => 1);
make_path(File::Spec->catfile($dir, 'sql'));

my $ddl_version1 = join("", map { sprintf("%x", int(rand(16))) } 1..40);
my $first_sql = <<__SQL__;
CREATE TABLE first (
    id INTEGER NOT NULL,
    name VARCHAR(191)
);
__SQL__

subtest "deploy" => sub {
    open my $fh, '>', File::Spec->catfile($dir, 'sql', 'ddl.sql') or die $!;
    print $fh $first_sql;
    close $fh;

    $mocking_furl->($ddl_version1, $first_sql);

    my $gd = GitHubDDL->new(
        work_dir     => $dir,
        ddl_file     => $ddl_file,
        dsn          => ["dbi:SQLite:dbname=$dir/target.db", '', ''],
        ddl_version  => $ddl_version1,
        github_user  => $github_user,
        github_repo  => $github_repo,
        github_token => $github_token,
    );

    eval {
        $gd->database_version;
    };
    ok $@, 'error ok';
    like $@, qr/Failed to get database version, please deploy first/, 'error msg ok';

    $gd->deploy;
    $gd->_dbh->do('INSERT INTO first (id, name) VALUES (1, "test")')
        or die $gd->_dbh->errstr;

    my $first_version = $gd->database_version;
    ok $first_version, 'first version ok';

    is $gd->ddl_version, $first_version, 'ddl_version == database_version ok';
    ok $gd->check_version, 'check_version ok';
};

my $ddl_version2 = join("", map { sprintf("%x", int(rand(16))) } 1..40);
my $second_sql = <<__SQL__;
CREATE TABLE second (
    id INTEGER NOT NULL,
    name VARCHAR(191)
);
__SQL__

subtest "upgrade_database" => sub {
    open my $fh, '>>', File::Spec->catfile($dir, 'sql', 'ddl.sql') or die $!;
    print $fh $second_sql;
    close $fh;

    my $gd = GitHubDDL->new(
        work_dir     => $dir,
        ddl_file     => $ddl_file,
        dsn          => ["dbi:SQLite:dbname=$dir/target.db", '', ''],
        ddl_version  => $ddl_version2,
        github_user  => $github_user,
        github_repo  => $github_repo,
        github_token => $github_token,
    );

    ok !$gd->check_version, 'check_version not ok ok';

    like $gd->diff, qr/CREATE TABLE second/, 'diff looks ok';

    $gd->upgrade_database;

    $gd->_dbh->do('INSERT INTO second (id, name) VALUES (1, "test")')
        or die $gd->_dbh->errstr;

    ok $gd->check_version, 'check_version ok again';
};

my $ddl_version3 = join("", map { sprintf("%x", int(rand(16))) } 1..40);
my $third_sql = <<__SQL__;
CREATE TABLE third (
    id INTEGER NOT NULL,
    name VARCHAR(191) -- comment
);
__SQL__

subtest "sql_filter" => sub {
    $mocking_furl->($ddl_version2, $first_sql . "\n" . $second_sql);

    open my $fh, '>>', File::Spec->catfile($dir, 'sql', 'ddl.sql') or die $!;
    print $fh $third_sql;
    close $fh;

    my $gd1 = GitHubDDL->new(
        work_dir     => $dir,
        ddl_file     => $ddl_file,
        dsn          => ["dbi:SQLite:dbname=$dir/target.db", '', ''],
        ddl_version  => $ddl_version3,
        github_user  => $github_user,
        github_repo  => $github_repo,
        github_token => $github_token,
    );

    ok !$gd1->check_version, 'check_version not ok ok';
    try {
        $gd1->diff;
        fail "should die";
    }
    catch {
        like $_, qr/Error with parser/, 'can not parse sql';
    };

    my $gd2 = GitHubDDL->new(
        work_dir     => $dir,
        ddl_file     => $ddl_file,
        dsn          => ["dbi:SQLite:dbname=$dir/target.db", '', ''],
        ddl_version  => $ddl_version3,
        github_user  => $github_user,
        github_repo  => $github_repo,
        github_token => $github_token,
        sql_filter   => sub {
            my $sql = shift;
            $sql =~ s/--.*//;
            $sql;
        },
    );

    like $gd2->diff, qr/CREATE TABLE third/, 'diff looks ok';

    $gd2->upgrade_database;

    $gd2->_dbh->do('INSERT INTO third (id, name) VALUES (1, "test")')
        or die $gd2->_dbh->errstr;

    ok $gd2->check_version, 'check_version ok again';
};

subtest "dump_sql_specified_commit_method" => sub {
    my $ddl_version4 = join("", map { sprintf("%x", int(rand(16))) } 1..40);
    # not used this test
    # if use this, fail test
    $mocking_furl->($ddl_version1, 'INVALID DDL');

    my $forth_sql = <<__SQL__;
CREATE TABLE forth (
    id INTEGER NOT NULL,
    name VARCHAR(191)
);
__SQL__

    open my $fh, '>>', File::Spec->catfile($dir, 'sql', 'ddl.sql') or die $!;
    print $fh $forth_sql;
    close $fh;

    my $gd = GitHubDDL->new(
        work_dir     => $dir,
        ddl_file     => $ddl_file,
        dsn          => ["dbi:SQLite:dbname=$dir/target.db", '', ''],
        ddl_version  => $ddl_version4,
        github_user  => $github_user,
        github_repo  => $github_repo,
        github_token => $github_token,
        sql_filter   => sub {
            my $sql = shift;
            $sql =~ s/--.*//;
            $sql;
        },

        dump_sql_specified_commit_method => sub {
            my $commit = shift;

            is $commit, $ddl_version3;
            return join("\n", $first_sql, $second_sql, $third_sql);
        },
    );

    like $gd->diff, qr/CREATE TABLE forth/, 'diff looks ok';

    $gd->upgrade_database;

    $gd->_dbh->do('INSERT INTO forth (id, name) VALUES (1, "test")')
        or die $gd->_dbh->errstr;

    ok $gd->check_version, 'check_version ok again';
};


done_testing;
