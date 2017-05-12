#!/usr/bin/perl

use lib qw(../blib/lib ../blib/arch);
use strict;
use warnings;

use Mac::CoreMIDI qw(GetDevices GetSources GetDestinations GetExternalDevices);

print "-" x 70, "\nDevices\n";
foreach (GetDevices()) {
    $_->Dump();
}

print "-" x 70, "\nSources\n";
foreach (GetSources()) {
    $_->Dump();
}

print "-" x 70, "\nDestinations\n";
foreach (GetDestinations()) {
    $_->Dump();
}

# print "-" x 70, "\nExternal devices\n";
# foreach (GetExternalDevices()) {
#     $_->Dump();
# }



