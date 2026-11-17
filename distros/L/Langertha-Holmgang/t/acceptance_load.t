#!/usr/bin/env perl
# Acceptance 1 (CONTEXT.md): the cai-platform suites load unchanged and their lint
# is green. Runs only against a copy kept outside this checkout (ADR 0003), named by
# HOLMGANG_ACCEPTANCE_SUITES (a search directory, or several separated by ':');
# skips without it. Nothing of the cases is printed — only suite ids and refusals.
#
# Only a suite whose suite.yaml says format pii-* (a corpus of cai-platform's
# privacy filter, not a model suite) is left out as not measured; every other
# refusal, a wrong or missing format included, fails. HOLMGANG_ACCEPTANCE_CASES,
# when set, is the number of cases cai-platform's own loader sees in the copy;
# the measured suites must load exactly that many.
use strict;
use warnings;
use Test::More;
use YAML::XS ();
use Path::Tiny qw( path );

use Langertha::Holmgang::Loader;

my $roots = $ENV{HOLMGANG_ACCEPTANCE_SUITES};
plan skip_all => 'set HOLMGANG_ACCEPTANCE_SUITES to a copy of the cai-platform suites' unless $roots;

my $L = Langertha::Holmgang::Loader->new;
my $list = $L->list($roots);
ok( scalar @$list, 'suites found' );
my $cases = 0;
for my $s ( @$list ) {
  my $dir = eval { $L->locate( $roots, $s->{id} ) };    # undef for an id in two roots
  my $head = $dir ? eval { YAML::XS::Load( path( $dir, 'suite.yaml' )->slurp_raw ) } : undef;
  if ( ref $head eq 'HASH' && ( $head->{format} // '' ) =~ /\Apii-/ ) {
    note( $s->{id}.': format pii-*, not a model suite, not measured' );
    next;
  }
  is( $s->{error}, undef, $s->{id}.' loads, lint green' );
  $cases += $s->{cases} // 0;
}
if ( defined( my $want = $ENV{HOLMGANG_ACCEPTANCE_CASES} ) ) {
  is( $cases, $want, 'measured suites load as many cases as cai-platform sees' );
}

done_testing;
