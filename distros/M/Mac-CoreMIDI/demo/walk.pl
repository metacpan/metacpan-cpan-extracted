#!/usr/bin/perl

use lib qw(../blib/lib ../blib/arch);
use strict;
use warnings;

use Mac::CoreMIDI qw(GetDevices GetExternalDevices);

foreach (GetDevices GetExternalDevices) {
    $_->Dump();
    my @e = $_->GetEntities();
    foreach my $e (@e) {
        $e->Dump();
        my @es = $e->GetSources();
        map { $_->Dump() } @es;
        my @ed = $e->GetDestinations();
        map { $_->Dump() } @ed;
    }
}
