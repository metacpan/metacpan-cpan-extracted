#!/usr/bin/env perl

use strict;
use warnings;
use English qw(-no_match_vars);
use Test2::V0;
use Test::Output 0.04;
plan 3;

use MIDI::Drummer::Tiny;

can_ok 'MIDI::Drummer::Tiny', [qw(add_fill)], 'has necessary methods';

# direct any MIDI output to a throwaway scalar reference filehandle
my $midi;
open my $midi_fh, '>', \$midi
    or bail_out "can't open MIDI output to a variable: $OS_ERROR";
my $drummer
    = MIDI::Drummer::Tiny->new( verbose => 1, file => $midi_fh );
isa_ok $drummer, [qw(MIDI::Drummer::Tiny)], 'constructed object';

# test multi-line verbose STDOUT/STDERR of default add_fill
output_like( sub { $drummer->add_fill },
    qr//m, qr/.+/m, 'add_fill has STDERR but no STDOUT' );
close $midi_fh
    or bail_out "couldn't close MIDI output variable: $OS_ERROR";
