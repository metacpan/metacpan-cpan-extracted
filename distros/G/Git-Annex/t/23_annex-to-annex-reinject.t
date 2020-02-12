#!/usr/bin/perl

use 5.028;
use strict;
use warnings;
use lib 't/lib';

use App::annex_to_annex;
use App::annex_to_annex_reinject;
use Test::More;
use File::Spec::Functions qw(rel2abs);
use t::Setup;
use t::Util;
use File::chdir;

plan skip_all => "git-annex not available" unless git_annex_available;

with_temp_annexes {
    my (undef, undef, $source2) = @_;

    run_bin qw(annex-to-annex --commit source1/foo source2/other dest);
    {
        local $CWD = "source2";
        $source2->checkout("master~1");
        ok $source2->annex(qw(find --in=here other)) == 1,
          "other is initially present";
        $source2->checkout("master");
    }
    run_bin qw(annex-to-annex-reinject source2 dest);
    {
        local $CWD = "source2";
        $source2->checkout("master~1");
        ok $source2->annex(qw(find --in=here other)) == 0,
          "other is reinjected";
        $source2->checkout("master");
    }
};

done_testing;
