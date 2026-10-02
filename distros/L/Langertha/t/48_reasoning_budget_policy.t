#!/usr/bin/env perl
# ABSTRACT: Langertha::Reasoning::BudgetPolicy — the (c) firewall + inbound bijection (karr k178)

# BudgetPolicy is category (c) of the ADR-0023 taxonomy: the INVENTED
# level<->token-budget interpolation. The load-bearing property is the firewall:
# every numeric output is clamped to the owning Profile's category-(b) bounds, so
# a convention can never emit a value the API would reject. These tests pin that
# firewall (including deliberately out-of-bounds anchors) and the inbound
# budget->level bijection, and assert BudgetPolicy is NOT wired in as a default.

use strict;
use warnings;

use Test2::Bundle::More;

use Langertha::Reasoning;
use Langertha::Reasoning::Profile;
use Langertha::Reasoning::BudgetPolicy;

my @LEVELS = qw( none minimal low medium high xhigh max );

my $pro   = Langertha::Reasoning::Profile->for_model('gemini-2.5-pro');    # 128..32768, no off
my $flash = Langertha::Reasoning::Profile->for_model('gemini-2.5-flash');  # 0..24576, off=0

# ---------------------------------------------------------------------------
# range form, linear curve, over gemini-2.5-pro (128..32768).
# ---------------------------------------------------------------------------
{
  my $policy = Langertha::Reasoning::BudgetPolicy->new(
    profile => $pro,
    form    => 'range',
    levels  => [qw( low medium high )],
  );

  is( $policy->budget_for('low'),    128,   'range/linear: low  -> budget_min' );
  is( $policy->budget_for('medium'), 16448, 'range/linear: medium -> midpoint' );
  is( $policy->budget_for('high'),   32768, 'range/linear: high -> budget_max' );

  # Off-ladder levels pin to the floor/ceiling — still inside the bounds.
  is( $policy->budget_for('none'), 128,   'range/linear: none below ladder -> floor' );
  is( $policy->budget_for('max'),  32768, 'range/linear: max above ladder -> ceiling' );

  # THE FIREWALL: every level, every output within the profile's (b) bounds.
  for my $level (@LEVELS) {
    my $budget = $policy->budget_for($level);
    ok( $budget >= 128 && $budget <= 32768,
      "firewall range: $level -> $budget within [128,32768]" );
  }

  # Inbound bijection, and a clean roundtrip on the anchor ladder.
  is( $policy->level_for(128),   'low',    'range: budget_min -> low' );
  is( $policy->level_for(16448), 'medium', 'range: midpoint -> medium' );
  is( $policy->level_for(32768), 'high',   'range: budget_max -> high' );
  for my $level (qw( low medium high )) {
    is( $policy->level_for( $policy->budget_for($level) ), $level,
      "range roundtrip: $level -> budget -> $level" );
  }

  # Out-of-range budgets clamp onto the boundary level, never off the ladder.
  is( $policy->level_for(-5),      'low',  'range: below-min budget -> floor level' );
  is( $policy->level_for(9_999_999), 'high', 'range: above-max budget -> ceiling level' );
}

# ---------------------------------------------------------------------------
# explicit form with anchors DELIBERATELY outside the (b) bounds — the firewall
# must clamp them so no API-rejected number can leak out.
# ---------------------------------------------------------------------------
{
  my $policy = Langertha::Reasoning::BudgetPolicy->new(
    profile => $pro,
    points  => { low => 1, medium => 8192, high => 999_999 },
  );
  is( $policy->form, 'explicit', 'form defaults to explicit when points given' );

  is( $policy->budget_for('low'),    128,   'firewall explicit: below-min anchor clamped up' );
  is( $policy->budget_for('medium'), 8192,  'explicit: in-bounds anchor unchanged' );
  is( $policy->budget_for('high'),   32768, 'firewall explicit: above-max anchor clamped down' );

  for my $level (@LEVELS) {
    my $budget = $policy->budget_for($level);
    ok( $budget >= 128 && $budget <= 32768,
      "firewall explicit: $level -> $budget within [128,32768]" );
  }

  # Inbound: nearest anchor by the CLAMPED budget.
  is( $policy->level_for(128),   'low',    'explicit: clamped-low budget -> low' );
  is( $policy->level_for(8192),  'medium', 'explicit: medium budget -> medium' );
  is( $policy->level_for(32768), 'high',   'explicit: clamped-high budget -> high' );
}

# ---------------------------------------------------------------------------
# off_value / none: gemini-2.5-flash disables at budget 0.
# ---------------------------------------------------------------------------
{
  my $policy = Langertha::Reasoning::BudgetPolicy->new(
    profile => $flash,
    points  => { none => 0, low => 2048, medium => 8192, high => 24576 },
  );
  is( $policy->budget_for('none'), 0,     'flash: none -> off_value 0' );
  is( $policy->budget_for('high'), 24576, 'flash: high -> budget_max' );
  is( $policy->level_for(0),       'none', 'flash: budget 0 (off_value) -> none' );
  is( $policy->level_for(2048),    'low',  'flash: 2048 -> low' );

  for my $level (@LEVELS) {
    my $budget = $policy->budget_for($level);
    ok( $budget >= 0 && $budget <= 24576,
      "firewall flash: $level -> $budget within [0,24576]" );
  }
}

# ---------------------------------------------------------------------------
# log curve — geometric spacing across the (b) range, still clamped.
# ---------------------------------------------------------------------------
{
  my $policy = Langertha::Reasoning::BudgetPolicy->new(
    profile => $pro,
    form    => 'range',
    curve   => 'log',
    levels  => [qw( low medium high )],
  );
  is( $policy->budget_for('low'),    128,   'log: low  -> budget_min' );
  is( $policy->budget_for('medium'), 2048,  'log: medium -> geometric midpoint' );
  is( $policy->budget_for('high'),   32768, 'log: high -> budget_max' );
  for my $level (@LEVELS) {
    my $budget = $policy->budget_for($level);
    ok( $budget >= 128 && $budget <= 32768,
      "firewall log: $level -> $budget within [128,32768]" );
  }
}

# ---------------------------------------------------------------------------
# default_bool_level — the boolean-to-level half of the inbound bijection.
# ---------------------------------------------------------------------------
{
  my $default = Langertha::Reasoning::BudgetPolicy->new(
    profile => $pro, form => 'range', levels => [qw( low medium high )] );
  is( $default->default_bool_level, 'medium', 'default_bool_level defaults to medium' );

  my $custom = Langertha::Reasoning::BudgetPolicy->new(
    profile => $pro, form => 'range', levels => [qw( low medium high )],
    default_bool_level => 'high' );
  is( $custom->default_bool_level, 'high', 'default_bool_level is overridable' );
}

# ---------------------------------------------------------------------------
# for_model convenience mirrors Profile->for_model.
# ---------------------------------------------------------------------------
{
  my $policy = Langertha::Reasoning::BudgetPolicy->for_model(
    'gemini-2.5-pro', form => 'range', levels => [qw( low medium high )] );
  is( $policy->profile->control, 'budget', 'for_model resolves the owning profile' );
  is( $policy->budget_for('high'), 32768, 'for_model policy interpolates and clamps' );
}

# ---------------------------------------------------------------------------
# BUILD wire-truth / convention guards.
# ---------------------------------------------------------------------------
like(
  eval { Langertha::Reasoning::BudgetPolicy->new(
    profile => Langertha::Reasoning::Profile->for_model('claude-opus-4-8') ); 1 } ? '' : $@,
  qr/requires the profile to carry both budget_min and budget_max/,
  'BUILD: range form on a bound-less (effort) profile croaks' );

like(
  eval { Langertha::Reasoning::BudgetPolicy->new(
    profile => $pro, form => 'explicit' ); 1 } ? '' : $@,
  qr/requires 'points'/,
  'BUILD: explicit form without points croaks' );

like(
  eval { Langertha::Reasoning::BudgetPolicy->new(
    profile => $pro, points => { superhigh => 100 } ); 1 } ? '' : $@,
  qr/unknown level 'superhigh'/,
  'BUILD: an unknown level key in points croaks' );

# ---------------------------------------------------------------------------
# NOT default-shipped: neither the Profile nor the Reasoning value object
# auto-constructs or exposes a BudgetPolicy — it is consumer-driven only.
# ---------------------------------------------------------------------------
ok( !Langertha::Reasoning::Profile->can('budget_policy'),
  'Profile does not expose a budget_policy accessor (not default-shipped)' );
ok( !Langertha::Reasoning->can('budget_policy'),
  'Reasoning does not expose a budget_policy accessor (not default-shipped)' );

done_testing;
