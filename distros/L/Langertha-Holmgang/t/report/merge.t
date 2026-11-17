#!/usr/bin/env perl
# Merging reports without counting anything twice (ADR 0006). Invented data only.
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS ();

use Langertha::Holmgang::Report;

my $CLASS = 'Langertha::Holmgang::Report';

sub report {
  my (%o) = @_;
  my $r = $CLASS->new( started_at => $o{started_at} // '2026-11-04T10:00:00Z' );
  $r->add_run(
    target  => { label => $o{label} // 'mock-a', engine => 'Virtual', model => 'mock-1', url => undef },
    variant => { name => 'plain', settings => {} },
    suite   => { id => 'demo-suite', version => '1', topic => 'netz', digest => 'd1' },
    repeat  => 3, status => $o{status} // 'complete', error => $o{error},
    cases   => [ map { { case_id => $_, title => 'T '.$_, tags => [], weight => 1 } } @{ $o{cases} // ['c-1'] } ],
    results => [ map { my ( $c, $n, $st, $ms ) = @$_;
      { case_id => $c, repetition => $n, status => $st,
        turns => [ { input_tokens => 10, duration_ms => $ms // 5, calls => 0 } ] } } @{ $o{results} } ],
  );
  $r->finish( $o{finished_at} // '2026-11-04T11:00:00Z' );
  return $r;
}

sub reps {
  my ( $r, $case ) = @_;
  my ($c) = grep { $_->{case_id} eq $case } @{ $r->runs->[0]{cases} };
  return [ map { "$_->{repetition}:$_->{status}" } @{ $c->{repetitions} } ];
}

subtest 'repetitions from two files join' => sub {
  my $a = report( results => [ [ 'c-1', 1, 'passed' ] ], status => 'cancelled', error => 'stopped' );
  my $b = report( results => [ [ 'c-1', 2, 'failed' ], [ 'c-1', 3, 'passed' ] ],
    started_at => '2026-11-04T09:00:00Z', finished_at => '2026-11-04T12:00:00Z' );
  my $m = $CLASS->merge( $a, $b );
  is scalar @{ $m->runs }, 1, 'one run';
  is_deeply reps( $m, 'c-1' ), [ '1:passed', '2:failed', '3:passed' ], 'repetitions 1..3';
  is $m->runs->[0]{status}, 'cancelled', 'worst status';
  is $m->runs->[0]{error}, 'stopped', 'first error';
  is $m->started_at, '2026-11-04T09:00:00Z', 'earliest start';
  is $m->finished_at, '2026-11-04T12:00:00Z', 'latest finish';
  my $again = $CLASS->from_json( $m->to_json );
  is $again->to_json, $m->to_json, 'merged report round-trips';
};

subtest 'same file twice counts once' => sub {
  my $a = report( results => [ [ 'c-1', 1, 'passed' ], [ 'c-1', 2, 'failed' ] ] );
  my $m = $CLASS->merge( $a, $CLASS->from_json( $a->to_json ) );
  is_deeply reps( $m, 'c-1' ), [ '1:passed', '2:failed' ], 'no double repetitions';
  my $v = report( results => [ [ 'c-1', 1, 'passed', 99 ] ] );
  is_deeply reps( $CLASS->merge( $a, $v ), 'c-1' ), [ '1:passed', '2:failed' ], 'differing only in volatile duration: kept once';
};

subtest 'conflicts croak' => sub {
  my $a = report( results => [ [ 'c-1', 1, 'passed' ] ] );
  my $b = report( results => [ [ 'c-1', 1, 'failed' ] ] );
  ok !eval { $CLASS->merge( $a, $b ); 1 }, 'same repetition, different result';
  like $@, qr/case c-1 repetition 1 of suite demo-suite is in two reports with different results/, 'message';
  my $c = report( results => [] );
  $c->runs->[0]{cases}[0]{title} = 'Other title';
  ok !eval { $CLASS->merge( $a, $c ); 1 }, 'case meta differs';
  like $@, qr/case c-1 of suite demo-suite differs/, 'message';
  my $d = report( results => [] );
  $d->runs->[0]{cases}[0]{difficulty} = 'schwer';
  my $e = report( results => [] );
  $e->runs->[0]{cases}[0]{difficulty} = 'leicht';
  ok !eval { $CLASS->merge( $d, $e ); 1 }, 'different difficulties differ';
};

subtest 'a report without difficulty merges with one that has it (k57)' => sub {
  my $old = report( results => [ [ 'c-1', 1, 'passed' ] ] );
  my $new = report( results => [ [ 'c-1', 2, 'failed' ] ] );
  $new->runs->[0]{cases}[0]{difficulty} = 'mittel';
  for my $pair ( [ $old, $new ], [ $new, $old ] ) {
    my $m = $CLASS->merge(@$pair);
    is $m->runs->[0]{cases}[0]{difficulty}, 'mittel', 'the known difficulty holds';
    is_deeply reps( $m, 'c-1' ), [ '1:passed', '2:failed' ], 'repetitions joined';
  }
  is $old->runs->[0]{cases}[0]{difficulty}, undef, 'the inputs stay as they were';
};

subtest 'different targets stay apart' => sub {
  my $a = report( results => [ [ 'c-1', 1, 'passed' ] ] );
  my $b = report( label => 'mock-b', results => [ [ 'c-1', 1, 'failed' ] ], cases => [ 'c-1', 'c-2' ] );
  my $m = $CLASS->merge( $a, $b );
  is_deeply [ map { $_->{target}{label} } @{ $m->runs } ], [ 'mock-a', 'mock-b' ], 'two runs, in order';
  is_deeply [ map { $_->{case_id} } @{ $m->runs->[1]{cases} } ], [ 'c-1', 'c-2' ], 'cases kept';
};

subtest 'cases from a later file are appended' => sub {
  my $a = report( results => [ [ 'c-1', 1, 'passed' ] ] );
  my $b = report( results => [ [ 'c-2', 1, 'passed' ] ], cases => ['c-2'] );
  is_deeply [ map { $_->{case_id} } @{ $CLASS->merge( $a, $b )->runs->[0]{cases} } ], [ 'c-1', 'c-2' ], 'union';
};

done_testing;
