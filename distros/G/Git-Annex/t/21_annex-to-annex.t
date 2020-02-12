#!/usr/bin/perl

use 5.028;
use strict;
use warnings;
use lib 't/lib';

use App::annex_to_annex;
use Test::More;
use t::Setup;
use t::Util;
use File::Path qw(make_path);
use File::Slurp;
use Capture::Tiny qw(capture_merged);
use File::Spec::Functions qw(catfile rel2abs);
use File::chdir;

plan skip_all => "device ID issues" if device_id_issues;
plan skip_all => "git-annex not available" unless git_annex_available;

my ($output, $error, $exit, @output);

with_temp_annexes {
    make_path "dest/foo/foo2";
    write_file "dest/foo/bar",      "";
    write_file "dest/foo/foo2/baz", "";
    (undef, $error, $exit)
      = run_bin qw(annex-to-annex source1/foo source2/other dest);
    ok $exit, "it exits nonzero instead of clobbering an existing file";
    ok grep(/\/dest\/foo\/bar already exists!$/, @$error),
      "it won't clobber an existing file";
};

with_temp_annexes {
    write_file catfile("source1", "quux"), "quux\n";
    (undef, $error, $exit)
      = run_bin qw(annex-to-annex --commit source1/foo/bar dest);
    ok $exit,
      "with --commit, it exits nonzero when uncommitted source changes";
    ok grep(/^git repo containing [^ ]+\/bar is not clean; please commit$/,
        @$error),
      "with --commit, it exits when uncommitted changes";
};

with_temp_annexes {
    write_file catfile("dest", "quux"), "quux\n";
    (undef, $error, $exit)
      = run_bin qw(annex-to-annex --commit source1/foo/bar dest);
    ok $exit, "with --commit, it exits nonzero when uncommitted dest changes";
    ok grep(/^git repo containing [^ ]+\/dest is not clean; please commit$/,
        @$error),
      "with --commit, it exits when uncommitted changes";
};

# following test is sensitive to changes in git-log output, but that's
# okay
with_temp_annexes {
    my (undef, $source1, $source2, $dest) = @_;

    # also implicitly test, here, that we can invoke the program by
    # passing a subroutine reference when invoking main as a class
    # method
    App::annex_to_annex->main([qw(--commit source1/foo source2/other dest)]);

    @output = $source1->RUN(qw(log -1 --oneline --name-status));
    like $output[0], qr/migrated by annex-to-annex/,
      "--commit makes a source1 commit";
    ok grep(m{^D\s+foo/bar$}, @output[1 .. $#output]),
      "--commit commit deletes bar";
    ok grep(m{^D\s+foo/foo2/baz$}, @output[1 .. $#output]),
      "--commit commit deletes baz";

    @output = $source2->RUN(qw(log -1 --oneline --name-status));
    like $output[0], qr/migrated by annex-to-annex/,
      "--commit makes a source2 commit";
    ok grep(m{^D\s+other$}, @output[1 .. $#output]),
      "--commit commit deletes other";

    @output = $dest->RUN(qw(log -1 --oneline --name-status));
    like $output[0], qr/add/, "--commit makes a dest commit";
    ok grep(m{^A\s+other$}, @output[1 .. $#output]),
      "--commit commit adds other";
};

with_temp_annexes {
    my (undef, $source1) = @_;

    corrupt_annexed_file $source1, "foo/foo2/baz";
    (undef, $error, $exit)
      = run_bin qw(annex-to-annex --commit source1/foo source2/other dest);
    ok $exit, "it exits nonzero when dest annex calculates a diff checksum";
    ok grep(/git-annex calculated a different checksum for/, @$error),
      "it warns when dest annex calculates a diff checksum";
};

with_temp_annexes {
    my (undef, $source1) = @_;

    $source1->annex(qw(drop --force foo/foo2/baz));
    ($output, undef, $exit)
      = run_bin qw(annex-to-annex --commit source1/foo source2/other dest);
    ok $exit, "it exits nonzero when an annexed file is not present";
    ok
      grep(/^Following annexed files are not present in this repo:$/, @$output),
      "it exits when annexed files are not present";
};

# this is the main integration test for the script doing its job
with_temp_annexes {
    my (undef, $source1, $source2, $dest) = @_;
    run_bin qw(annex-to-annex source1/foo source2/other dest);
    {
        local $CWD = "source1";
        ok !-e "foo/bar",      "bar should not exist in source1";
        ok !-e "foo/foo2/baz", "baz should not exist in source1";
    }
    ok !-e "source2/other", "other should not exist in source2";
    {
        local $CWD = "dest";

        ok -f "foo/bar", "bar is regular file in dest";
        ok -f "foo/foo2/baz", "baz is regular file in dest";
        ok -l "other", "other is symlink in dest";
        my @bar_find = $dest->annex(qw(find foo/bar));
        ok @bar_find == 0, "bar is not annexed in dest";

        my ($baz_key) = $dest->annex(qw(lookupkey foo/foo2/baz));
        my ($baz_content) = $dest->annex("contentlocation", $baz_key);
        my @baz_content_stat = stat $baz_content;
        ok $baz_content_stat[3] == 2, "baz was hardlinked into annex";
        ok((stat("foo/foo2/baz"))[3] == 1,
           "baz in dest working tree is a copy");

        my ($other_key) = $dest->annex(qw(lookupkey other));
        my ($other_content) = $dest->annex("contentlocation", $other_key);
        my @other_content_stat = stat $other_content;
        ok $other_content_stat[3] == 2, "other was hardlinked into annex";

        is read_file("foo/bar"), "bar\n", "bar has expected file content";
        is read_file("foo/foo2/baz"), "baz\n", "baz has expected file content";
        is read_file("other"), "other\n", "other has expected file content";
    }
    my @source1_git_status = $source1->RUN(qw(status --porcelain));
    ok grep(/D\s+foo\/bar/, @source1_git_status), "bar was removed from git";
    ok grep(/D\s+foo\/foo2\/baz/, @source1_git_status),
      "baz was removed from git";
    my @source2_git_status = $source2->RUN(qw(status --porcelain));
    ok grep(/D\s+other/, @source2_git_status), "other was removed from git";
    my @dest_git_status = $dest->RUN(qw(status --porcelain));
    ok grep(/A\s+foo\/bar/,       @dest_git_status), "bar was added to git";
    ok grep(/A\s+foo\/foo2\/baz/, @dest_git_status), "baz was added to git";
    ok grep(/A\s+other/,          @dest_git_status), "other was added to git";
};

done_testing;
