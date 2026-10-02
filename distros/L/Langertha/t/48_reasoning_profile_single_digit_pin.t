#!/usr/bin/env perl
# ABSTRACT: Pins the resolution and wire output of every single-digit reasoning model id (karr k196)

use strict;
use warnings;

use Test2::Bundle::More;
use lib 't/lib';
use JSON::MaybeXS ();
use Path::Tiny qw( path );
use Test::ReasoningProfileSnapshot qw( snapshot @PIN_IDS );

# karr k196 reworks the Langertha::Reasoning::Profile registry: dotted family
# patterns gain a multi-digit guard, the chat carve-outs are generated per digit,
# and the provider default is built before the carve-outs. None of that may move
# a single-digit id: its classification decides whether the OpenAI temperature
# gate drops a caller's temperature (ADR 0025), and its wire output is what the
# provider accepts (ADR 0023). The golden file was captured from the registry as
# it stood before k196 (commit 250f341) and holds, per id, the resolved profile
# attributes plus the kwargs emitted on all five reasoning wires for all seven
# efforts ('CROAK' where Langertha::Reasoning refuses the combination, e.g. an
# effort on Gemini 2.5). Only multi-digit ids (gpt-5.10, ...) may change.

my $golden = JSON::MaybeXS->new->decode(
  path('t/data/reasoning_profile_single_digit_pin.json')->slurp_raw );

is_deeply( [ sort keys %$golden ], [ sort @PIN_IDS ],
  'golden file covers exactly the pinned id list' );

for my $id (@PIN_IDS) {
  is_deeply( snapshot($id), $golden->{$id},
    "'$id': resolution and wire output unchanged" );
}

done_testing;
