#!/usr/bin/env perl
# Acceptance 2 (CONTEXT.md, k13): a mock run over the cai-platform suites gives what
# cai-platform's runner gave. Runs only against copies kept outside this checkout
# (ADR 0003): HOLMGANG_ACCEPTANCE_SUITES names the suites (as in acceptance_load.t),
# HOLMGANG_ACCEPTANCE_BASELINE a directory of cai-platform mock-run results, one
# <suite>.<solution|text>.json per suite and mode:
#   { report, grading, suites }  the arguments of Report->from_cai_platform
#   calls  => { "<suite>/<mode>/<round>" => { <case> => [ { name, args, sim_gap } ] } }
#   errors => { "<suite>/<mode>/<round>" => { <case> => text | null } }
# made with cai-platform's Eval::Runner::run_case against Eval::FakeTarget, repeat
# per suite. Skips without both. Nothing of the cases is printed beyond ids.
#
# Claim: per suite, mode, case and repetition the Holmgang mock run
# (Runner->mock_engine) has the status after the ADR 0006 mapping, the score,
# every rule (reason translated, see below), the diff, the calls with their
# arguments and gaps, the sim_gaps, forbidden_calls, injection_held, the
# number of turns and the error that cai-platform recorded; the suite digest
# and the case list are the same. Deliberate differences not compared: tokens
# (the mock estimates none, ADR 0005 k9), seed (the CLI sends none, ADR 0009),
# duration_ms, and the error of a turn limit (none here, ADR 0006).
use strict;
use warnings;
use utf8;
use Test::More;

use JSON::MaybeXS ();
use Path::Tiny qw( path );
use Langertha::Holmgang::Loader;
use Langertha::Holmgang::Report;
use Langertha::Holmgang::Runner;
use Langertha::Holmgang::Target;

my $roots = $ENV{HOLMGANG_ACCEPTANCE_SUITES};
my $base  = $ENV{HOLMGANG_ACCEPTANCE_BASELINE};
plan skip_all => 'set HOLMGANG_ACCEPTANCE_SUITES and HOLMGANG_ACCEPTANCE_BASELINE (cai-platform mock-run results)'
  unless $roots && $base;

my $JSON = JSON::MaybeXS->new( utf8 => 0, canonical => 1, allow_nonref => 1 );
sub plain { $JSON->decode( $JSON->encode( $_[0] ) ) }

# The grader's reasons are English (Grader POD, k2); cai-platform's are German.
# Its fixed phrases (Eval::Grader, Eval::World::condition) translated:
my @DE = (
  [ qr/\Akeine weiteren Änderungen\z/,          sub { 'no other changes' } ],
  [ qr/\Aauch geändert: /,                       sub { 'also changed: ' } ],
  [ qr/\Ain dieser Reihenfolge aufgerufen\z/,    sub { 'called in this order' } ],
  [ qr/\Afehlt: /,                               sub { 'missing: ' } ],
  [ qr/\A(\d+)-mal aufgerufen\z/,                sub { "called $1×" } ],
  [ qr/\Anicht aufgerufen\z/,                    sub { 'not called' } ],
  [ qr/\Anur erlaubte Werkzeuge\z/,              sub { 'only allowed tools' } ],
  [ qr/\Aaußerhalb: /,                           sub { 'outside: ' } ],
  [ qr/\AGerät (\S+) fehlt\z/,                   sub { "device $1 missing" } ],
  [ qr/\Akein Urteil: /,                         sub { 'no verdict: ' } ],
  [ qr/\Anach Neustart: /,                       sub { 'after reboot: ' } ],
  [ qr/\ALücke der Simulation im Prüfbefehl: /,  sub { 'gap of the simulation in the check command: ' } ],
  [ qr/\AExit (\d+) statt (\d+)/,                sub { "exit $1 instead of $2" } ],
  [ qr/\AZeilen der Ausgabe passt nicht \(/,     sub { 'lines of the output do not fit (' } ],
  [ qr/\AAusgabe passt nicht \(/,                sub { 'output do not fit (' } ],
  [ qr/\AExit (\d+), Ausgabe passt\z/,           sub { "exit $1, output fits" } ],
  [ qr/\Avorhanden: /,                           sub { 'present: ' } ],
  [ qr/\Afehlt\z/,                               sub { 'missing' } ],
  [ qr/\Anicht vorhanden\z/,                     sub { 'not present' } ],
  [ qr/\Aist /,                                  sub { 'is ' } ],
  [ qr/\Akeine Liste: /,                         sub { 'not a list: ' } ],
  [ qr/ fehlt in /,                              sub { ' missing in ' } ],
  [ qr/ steht in /,                              sub { ' present in ' } ],
  [ qr/\A(\d+) Einträge\z/,                      sub { "$1 entries" } ],
  [ qr/\Akein passender Eintrag in /,            sub { 'no matching entry in ' } ],
  [ qr/\Aunerwünschter Eintrag: /,               sub { 'unwanted entry: ' } ],
  [ qr/\Aerster Eintrag fehlt\z/,                sub { 'first entry missing' } ],
  [ qr/\Azweiter Eintrag fehlt\z/,               sub { 'second entry missing' } ],
  [ qr/\AReihenfolge: (\S+) nach (\S+)\z/,       sub { "order: $1 after $2" } ],
);

sub en {
  my ( $t ) = @_;
  return $t unless defined $t;
  for my $p ( @DE ) {
    my ( $re, $to ) = @$p;
    next unless $t =~ $re;
    my $r = $to->();
    $t =~ s/$re/$r/;
    # a check's output condition carries a condition reason in parentheses
    if ( $t =~ /\A((?:lines of the )?output do not fit) \((.*)\)\z/s ) {
      my ( $head, $inner ) = ( $1, $2 );
      $t = $head.' ('.en($inner).')';
    }
    return $t;
  }
  return $t;
}

my $loader = Langertha::Holmgang::Loader->new;
my @files = sort grep { $_->basename =~ /\.(?:solution|text)\.json\z/ } path($base)->children;
ok( scalar @files, 'baseline files found' );

for my $file ( @files ) {
  my ( $id, $mode ) = $file->basename =~ /\A(.+)\.(solution|text)\.json\z/;
  subtest "$id $mode" => sub {
    my $b = JSON::MaybeXS->new( utf8 => 1 )->decode( $file->slurp_raw );
    my $dir = $loader->locate( $roots, $id );
    ok( $dir, 'suite found' ) or return;
    my $suite = $loader->load($dir);
    my ($cai) = @{ Langertha::Holmgang::Report->from_cai_platform(
      $b->{report}, grading => $b->{grading}, suites => $b->{suites} )->as_data->{runs} };
    is( $suite->digest, $cai->{suite}{digest}, 'digest' );
    is( $suite->topic, $cai->{suite}{topic}, 'topic' );
    is_deeply( [ map { $_->id } @{ $suite->cases } ], [ map { $_->{case_id} } @{ $cai->{cases} } ], 'cases' );
    my $repeat = $cai->{repeat};
    is( $repeat, $suite->repeat // 1, 'repeat' );
    my %want = map { $_->{case_id} => $_ } @{ $cai->{cases} };
    for my $n ( 1 .. $repeat ) {
      my $key = "$id/$mode/$n";
      for my $case ( @{ $suite->cases } ) {
        my $w   = $want{ $case->id } or next;
        my $exp = $w->{repetitions}[ $n - 1 ];
        my $at  = $case->id.' #'.$n;
        is( $case->is_hard ? 1 : 0, $w->{hard} ? 1 : 0, "$at hard" ) if $n == 1;
        is( $case->has_untrusted ? 1 : 0, $w->{untrusted} ? 1 : 0, "$at untrusted" ) if $n == 1;
        my $got = Langertha::Holmgang::Runner->new(
          target => Langertha::Holmgang::Target->new( engine => Langertha::Holmgang::Runner->mock_engine( $case, $mode ) ),
        )->run_case( $case, repetition => $n );
        is( $got->{status}, $exp->{status}, "$at status" );
        is( $got->{score}, $exp->{score}, "$at score" );
        is_deeply( plain( $got->{rules} ),
          plain( [ map { +{ %$_, reason => en( $_->{reason} ) } } @{ $exp->{rules} || [] } ] ), "$at rules" );
        # as the report writes it: before/after null for a path added or removed
        is_deeply( plain( [ map { +{ path => $_->{path}, before => $_->{before}, after => $_->{after} } } @{ $got->{diff} } ] ),
          plain( $exp->{diff} ), "$at diff" );
        is_deeply( plain( $got->{sim_gaps} ), plain( $exp->{sim_gaps} ), "$at sim_gaps" );
        is( $got->{forbidden_calls}, $exp->{forbidden_calls}, "$at forbidden_calls" );
        is( defined $got->{injection_held} ? ( $got->{injection_held} ? 1 : 0 ) : undef,
          defined $exp->{injection_held} ? ( $exp->{injection_held} ? 1 : 0 ) : undef, "$at injection_held" );
        is( scalar @{ $got->{turns} }, scalar @{ $exp->{turns} }, "$at turns" );
        is_deeply(
          plain( [ map { +{ tool => $_->{tool}, args => $_->{args}, sim_gap => $_->{sim_gap} } } @{ $got->{calls} } ] ),
          plain( [ map { +{ tool => $_->{name}, args => $_->{args}, sim_gap => $_->{sim_gap} } }
            @{ ( $b->{calls}{$key} || {} )->{ $case->id } || [] } ] ),
          "$at calls" );
        next if $exp->{status} eq 'turn_limit';
        my $err = ( $b->{errors}{$key} || {} )->{ $case->id };
        $err =~ s/\AZiel: // if defined $err;
        is( $got->{error}, $err, "$at error" );
      }
    }
  };
}

done_testing;
