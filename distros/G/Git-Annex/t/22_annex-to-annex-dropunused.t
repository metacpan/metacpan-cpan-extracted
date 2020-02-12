#!/usr/bin/perl

use 5.028;
use strict;
use warnings;
use lib 't/lib';

use App::annex_to_annex;
use App::annex_to_annex_dropunused;
use Test::More;
use File::Spec::Functions qw(rel2abs);
use t::Setup;
use t::Util;
use File::chdir;
use File::Basename qw(dirname);
use File::Copy qw(copy);

plan skip_all => "device ID issues" if device_id_issues;
plan skip_all => "git-annex not available" unless git_annex_available;

with_temp_annexes {
    my (undef, undef, $source2) = @_;

    run_bin qw(annex-to-annex --commit source1/foo source2/other dest);

    {
        local $CWD = "source2";
        run_bin "annex-to-annex-dropunused";
        $source2->checkout("master~1");
        ok((lstat "other" and not stat "other"), "other was dropped");
    }
};

with_temp_annexes {
    my (undef, undef, $source2) = @_;

    run_bin qw(annex-to-annex --commit source1/foo source2/other dest);

    {
        local $CWD = "source2";

        $source2->checkout("master~1");
        my ($other_key) = $source2->annex(qw(lookupkey other));
        my ($other_content) = $source2->annex("contentlocation", $other_key);
        $source2->checkout("master");

        # break the hardlink
        chmod 0755, dirname $other_content;
        copy $other_content, "$other_content.tmp";
        system "mv", "-f", "$other_content.tmp", $other_content;
        chmod 0555, dirname $other_content;

        run_bin "annex-to-annex-dropunused";
        $source2->checkout("master~1");
        ok((lstat "other" and stat "other"), "other was not dropped");
        # $source2->checkout("master");
        # run_bin qw(annex-to-annex-dropunused --dest=../dest);
        # $source2->checkout("master~1");
        # ok((lstat "other" and not stat "other"), "other was dropped");
    }
};

# with_temp_annexes {
#     my (undef, undef, $source2, $dest) = @_;

#     run_bin qw(annex-to-annex --commit source1/foo source2/other dest);

#     $dest->annex(qw(drop --force other));
#     {
#         local $CWD = "source2";

#         $source2->checkout("master~1");
#         my ($other_key) = $source2->annex(qw(lookupkey other));
#         my ($other_content) = $source2->annex("contentlocation", $other_key);
#         $source2->checkout("master");

#         # break the hardlink
#         chmod 0755, dirname $other_content;
#         copy $other_content, "$other_content.tmp";
#         system "mv", "-f", "$other_content.tmp", $other_content;
#         chmod 0555, dirname $other_content;

#         run_bin qw(annex-to-annex-dropunused --dest=../dest);
#         $source2->checkout("master~1");
#         ok((lstat "other" and stat "other"), "other was not dropped");
#     }
# };

done_testing;
