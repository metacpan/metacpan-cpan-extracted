#!/usr/bin/env/perl
use strict;
use warnings;
use Linux::Smaps;
use Linux::Smaps::Tiny;
use Linux::Smaps::Tiny::PP;
use Benchmark qw/:all :hireswallclock/;

cmpthese(10000, {
    "Linux::Smaps" => sub {
        Linux::Smaps->new->all;
        return;
    },
    "Linux::Smaps::Tiny" => sub {
        Linux::Smaps::Tiny::get_smaps_summary();
        return;
    },
    "Linux::Smaps::Tiny::PP" => sub {
        Linux::Smaps::Tiny::PP::__get_smaps_summary();
        return;
    },

});
