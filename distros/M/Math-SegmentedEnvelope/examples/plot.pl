#!/usr/bin/env perl
use strict;
use warnings;
use Math::SegmentedEnvelope;

BEGIN {
    eval {
        require PDL;
        PDL->import;
        require PDL::Graphics::Prima::Simple;
        PDL::Graphics::Prima::Simple->import;
        1;
    } or do {
        print "This example requires PDL and PDL::Graphics::Prima::Simple\n";
        exit 0;
    };
}

my $env = "Math::SegmentedEnvelope";
my $e = $env->new(is_morph => 1, is_fold_over => 1);
my $s = $e->static;

line_plot(pdl([ map { $e->at($_ / 5000 * 8 - 4) } 0 .. 4999 ]));
line_plot(pdl([ map { $s->($_ / 5000 * 8 - 4) } 0 .. 4999 ]));
