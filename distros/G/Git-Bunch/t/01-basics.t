#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use File::chdir;
use File::Slurper qw(read_text write_text);
use File::Temp qw(tempdir);
use File::Which;
use Git::Bunch qw(check_bunch sync_bunch);
use IPC::System::Options 'system', 'readpipe', -log=>1, -lang=>'C';
use Probe::Perl;
use String::ShellQuote;

for (qw(git rsync rm rsync-new2old)) {
    plan skip_all => "$_ not available in PATH" unless which($_);
}
my $git_version = `git --version`;
diag "git version = $git_version";
$git_version =~ /(\d+\.\d+\.\d+)/ or die "Can't extract git version (x.y.z)";

# some CPAN Testers machines report failures because its git doesn't grok '-c'.
# i couldn't find out (from grep-ing the release notes back from 1.5.0.1) when
# '-c' was introduced, so to be safe i'm using a minimum version of 2.1.4 which
# i currently use.
unless (version->parse($1) >= version->parse("2.1.4")) {
    plan skip_all => "git is older than 2.1.4";
}

my $_name_email = "-c user.name=name -c user.email=name\@example.com";

# XXX sync + --create_bare / --nocreate-bare
# XXX --exclude_repos_pat
# XXX --include_repos_pat
# XXX exec

# due to shell quoting etc
my $pp = Probe::Perl->new;
plan skip_all => 'currently only test on Unix'
    unless $pp->os_type eq 'Unix';

my $rootdir = tempdir(CLEANUP=>1);
$CWD = $rootdir;
create_test_data($rootdir);

test_gb(
    sub     => "check_bunch",
    name    => "all repos in bunch are clean",
    args    => {source=>"src/bunch1"},
    status  => 200,
    test_res => sub {
        my ($res) = @_;
        #diag explain $res;
        is( $res->[2]{repo1}[0], 200, "repo1 is clean");
        is( $res->[2]{repo2}[0], 200, "repo2 is clean");
        ok(!$res->[2]{"file1"}, "file is skipped");
        ok(!$res->[2]{".nonrepo1"}, "dotdir is skipped");
    },
);
test_gb(
    sub     => "check_bunch",
    name    => "handling / suffix in bunch name",
    args    => {source=>"src/bunch1/"},
    status  => 200,
);
test_gb(
    sub     => "check_bunch",
    name    => "bunch doesn't exist",
    args    => {source=>"src/bunch1x"},
    status  => 404,
);
test_gb(
    sub     => "check_bunch",
    name    => "using repo instead of bunch will be rejected",
    args    => {source=>"src/bunch1/repo1"},
    status  => 400,
);

# disabled since 0.55 because to save one stat() call per dir, we no longer
# check DIR/.git in check_bunch().

#mkdir "src/bunch1/nonrepo2";
#test_gb(
#    sub     => "check_bunch",
#    name    => "skip nondot, nongit dir",
#    args    => {source=>"src/bunch1"},
#    status  => 200,
#    test_res => sub {
#        my ($res) = @_;
#        ok(!$res->[2]{nonrepo2}, "nonrepo2 is skipped");
#    },
#);
#rmdir "src/bunch1/nonrepo2";

write_text("src/bunch1/repo1/d/b", "");
test_gb(
    sub     => "check_bunch",
    name    => "needs commit",
    args    => {source=>"src/bunch1"},
    status  => 200,
    test_res => sub {
        my ($res) = @_;
        is  ($res->[2]{repo1}[0], 500, "repo1 is unclean (status)");
        like($res->[2]{repo1}[1], qr/needs commit/i,
             "repo1 is unclean (message)");
    },
);
system "cd src/bunch1/repo1 && git $_name_email commit -am 'commit2-repo1'";
test_gb(
    sub     => "check_bunch",
    name    => "needs commit (committed)",
    args    => {source=>"src/bunch1"},
    status  => 200,
    test_res => sub {
        my ($res) = @_;
        is( $res->[2]{repo1}[0], 200, "repo1 is clean again");
    },
);

write_text("src/bunch1/repo1/c", "cherry");
test_gb(
    sub     => "check_bunch",
    name    => "has untracked files",
    args    => {source=>"src/bunch1"},
    status  => 200,
    test_res => sub {
        my ($res) = @_;
        is  ($res->[2]{repo1}[0], 500, "repo1 is unclean");
        like($res->[2]{repo1}[1], qr/has untracked files/i,
             "repo1 is unclean (message)");
    },
);
unlink "src/bunch1/repo1/c";
test_gb(
    sub     => "check_bunch",
    name    => "has untracked files (deleted)",
    args    => {source=>"src/bunch1"},
    status  => 200,
    test_res => sub {
        my ($res) = @_;
        is( $res->[2]{repo1}[0], 200, "repo1 is clean again");
    },
);

#subtest "can't chdir to repo -> dies" => sub {
#    plan skip_all => "skipping test because user can access src/bunch1 "
#        if -x "src/bunch1";
#    test_gb(
#        sub     => "check_bunch",
#        name    => "can't chdir to repo -> dies",
#        args    => {source=>"src/bunch1"},
#        dies    => 1,
#    );
#    rmdir "src/bunch1/repo3";
#};

delete_test_data("bak") if Test::More->builder->is_passing;

test_gb(
    sub     => "sync_bunch",
    name    => "source bunch doesn't exist",
    args    => {source=>"src/bunch1x", target=>"sync"},
    status  => 404,
);
test_gb(
    sub     => "sync_bunch",
    name    => "using repo instead of bunch in source will be rejected",
    args    => {source=>"src/bunch1/repo1", target=>"sync"},
    status  => 400,
);
test_gb(
    sub     => "sync_bunch",
    name    => "using repo instead of bunch in target will be rejected",
    args    => {source=>"src/bunch1", target=>"src/bunch1/repo1"},
    status  => 400,
);
test_gb(
    sub     => "sync_bunch",
    name    => "main test", # also test handling / suffix in src & target
    args    => {source=>"src/bunch1/", target=>"sync/1/"},
    status  => 200,
    test_res => sub {
        my ($res) = @_;
        ok((-d "sync/1"), "target directory created") or return;
        is(read_text("sync/1/file1"), "foo", "files copied");
        ok((-d "sync/1/.nonrepo1"), "nongit dotdir copied (exists)");
        is(read_text("sync/1/.nonrepo1/t"), "tea",
           "nongit dotdir copied (content)");
        for my $repo (qw(repo1 repo2)) {
            ok( (-d "sync/1/$repo"), "repo $repo copied (exists)");
            ok( (-d "sync/1/$repo/.git"),
                "repo $repo copied (.git exists)");
            is( read_text("sync/1/$repo/a"), "apple",
                "repo $repo copied (working copy copied)");
            like(scalar(readpipe("cd sync/1/$repo && git log")), qr/commit1-$repo/i,
                 "repo $repo copied (git log works)");
        }
    },
);

# different length or rsync by default ignores it
write_text "src/bunch1/file1", "foobar";
write_text "src/bunch1/.nonrepo1/t", "tangerine";
# delete
unlink     "src/bunch1/repo1/a";
system  "cd src/bunch1/repo1 && git $_name_email commit -am 'commit3-repo1'";
# add
write_text "src/bunch1/repo1/e", "eggplant";
system  "cd src/bunch1/repo1 && git add e && git $_name_email commit -am 'commit4-repo1'";
# update
write_text "src/bunch1/repo1/d/b", "blackberry";
system  "cd src/bunch1/repo1 && git $_name_email commit -am 'commit5-repo1'";
# rename
system  "cd src/bunch1/repo1 && git mv k d/ && git $_name_email commit -am 'commit6-repo1'";

test_gb(
    sub     => "sync_bunch",
    name    => "update",
    args    => {source=>"src/bunch1/", target=>"sync/1/"},
    status  => 200,
    test_res => sub {
        my ($res) = @_;
        is(read_text("sync/1/file1"), "foobar", "files updated");
        is(read_text("sync/1/.nonrepo1/t"), "tangerine",
           "nongit dotdir updated");
        ok(!(-e "sync/1/repo1/a"), "repo1: a deleted");
        is(read_text("sync/1/repo1/e"), "eggplant",
           "repo1: e added");
        is(read_text("sync/1/repo1/d/b"), "blackberry",
           "repo1: b updated");
        ok(!(-e "sync/1/repo1/k"), "repo1: k moved (1)");
        is(read_text("sync/1/repo1/d/k"), "kangkung",
           "repo1: k moved (2)");
        like(scalar(readpipe("cd sync/1/repo1 && git log")),
             qr/commit6.+commit5.+commit4.+commit3/s,
             "repo1: commits sync-ed");
        my %status = (
            "file1"      => 200,
            ".nonrepo1"  => 200,
            "repo1"      => 200,
            "repo2"      => 304,
        );
        is($res->[2]{$_}[0], $status{$_}, "status of $_") for keys %status;
    },
);

write_text "src/bunch1/repo2/s1", "strawberry";
system  "cd src/bunch1/repo2 && git branch b2";
system  "cd src/bunch1/repo2 && git add s1 && ".
    "git $_name_email commit -am 'commit3-master-repo2'";
system  "cd src/bunch1/repo2 && git checkout b2";
write_text "src/bunch1/repo2/s2", "spearmint";
system  "cd src/bunch1/repo2 && git add s2 && ".
    "git $_name_email commit -am 'commit4-b2-repo2'";

test_gb(
    sub     => "sync_bunch",
    name    => "multiple branches",
    args    => {source=>"src/bunch1/", target=>"sync/1/"},
    status  => 200,
    test_res => sub {
        my ($res) = @_;
        system "cd sync/1/repo2 && git checkout master";
        is(read_text("sync/1/repo2/s1"),
           "strawberry", "branch master: s1 added");
        ok(!(-e "sync/1/repo2/s2"), "branch master: s2 not added");

        system "cd sync/1/repo2 && git checkout b2";
        is(read_text("sync/1/repo2/s2"),
           "spearmint", "branch b2: s2 added");
        ok(!(-e "sync/1/repo2/s1"), "branch b2: s2 not added");
    },
);

TODO: {
    local $TODO = "todo";
    fail("arg: delete_branch");
    fail("arg: repos (skips nonrepo as well as repo)");
    fail("sync tags");
}

# TODO: test options exclude_files=>1, exclude_non_git_dirs=>1 on sync

delete_test_data("sync") if Test::More->builder->is_passing;

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    diag "all tests successful, deleting test data dir";
    $CWD = "/";
} else {
    # don't delete test data dir if there are errors
    diag "there are failing tests, not deleting test data dir $rootdir";
}

sub test_gb {
    my (%args) = @_;
    my $sub = $args{sub};
    my $sub_args = $args{args};

    subtest "$sub: $args{name}" => sub {

        my $res;
        my $eval_err;
        if ($sub =~ /^(check|sync)_bunch$/) {
            no strict 'refs';
            eval { $res = $sub->(%$sub_args) }; $eval_err = $@;
        } else {
            die "Unknown sub to test: $sub";
        }

        if ($args{dies}) {
            ok($eval_err, "dies");
        }
        if ($args{status}) {
            is($res->[0], $args{status}, "status $args{status}")
                or diag explain($res);
        }
        if ($args{test_res}) {
            $args{test_res}->($res);
        }

    };
}

sub create_test_data {
    die unless $rootdir;
    local $CWD = $rootdir;
    use autodie;

    mkdir      "src";
    mkdir      "src/bunch1";
    mkdir      "src/bunch1/.nonrepo1";
    write_text "src/bunch1/.nonrepo1/t", "tea";
    write_text "src/bunch1/file1", "foo";

    mkdir      "src/bunch1/repo1";
    write_text "src/bunch1/repo1/a", "apple";
    mkdir      "src/bunch1/repo1/d";
    write_text "src/bunch1/repo1/d/b", "banana";
    write_text "src/bunch1/repo1/k", "kangkung";
    $CWD     = "src/bunch1/repo1";
    system     "git init";
    system     "git add .";
    system     "git $_name_email commit -am 'commit1-repo1'";
    $CWD     = "../../..";

    mkdir      "src/bunch1/repo2";
    write_text "src/bunch1/repo2/a", "avocado";
    mkdir      "src/bunch1/repo2/d";
    write_text "src/bunch1/repo2/d/b", "blueberry";
    $CWD     = "src/bunch1/repo2";
    system     "git init";
    system     "git add .";
    system     "git $_name_email commit -am 'commit1-repo2'";
    write_text   "a", "apple";
    system     "git $_name_email commit -am 'commit2-repo2'";
    $CWD     = "../../..";
}

sub delete_test_data {
    die unless $rootdir;
    my @dirs = @_ ? @_ : ("src", "sync", "bak");
    system "rm -rf ".join(" ", map {shell_quote("$rootdir/$_")} @dirs);
}
