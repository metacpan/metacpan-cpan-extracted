#!/usr/bin/perl
use strict;
use warnings;
use Dir::Self;
use lib __DIR__;
use lf_out_test qw(logtester $Output);
use Log::Fu { target => \&logtester };
use Test::More;

sub noise {
    log_warn("Make some noise..");
}

{
    local $Log::Fu::DISPLAY_SEVERITY = -1;
    noise();
    unlike($Output, qr/WARN/, "Severity suppressed");
}

{
    local $Log::Fu::DISPLAY_SEVERITY = 1;
    noise();
    like($Output, qr/WARN/, "Severity displayed");
}

done_testing();