#!/usr/bin/env perl
# cai-platform `evals run --report` onto format 1 (ADR 0006, mapping table; for k13).
# The input imitates the shape of CAI::Platform::CLI::Command::Evals::Run; every
# value is invented (ADR 0003).
use strict;
use warnings;
use utf8;
use Test::More;
use JSON::MaybeXS ();

use Langertha::Holmgang::Report;

my $CLASS = 'Langertha::Holmgang::Report';
my $T = JSON::MaybeXS::true();
my $F = JSON::MaybeXS::false();

sub row {
  my (%o) = @_;
  return { case_id => 'k-1', title => 'Case one', status => 'passed', score => 1, turns => 2,
    prompt_tokens => 300, completion_tokens => 20, prompt_tokens_max => 180, duration_ms => 40,
    exceeded => $F, tool_calls => 2, sim_gaps => [], forbidden_calls => 0, injection_held => undef, %o };
}

my $cai = {
  base_url => 'https://bob:pw@gpu.example/v1?key=zzz',
  models   => ['model-x'],
  suites   => ['inv-suite'],
  repeat   => undef,
  repeat_by_suite => { 'inv-suite' => 2 },
  topics   => [ { target => 'model-x', topic => 'netz', cases => 4 } ],
  verdicts => [ { target => 'model-x', suite_id => 'inv-suite', ok => $T } ],
  runs => [
    { id => 'run-a', target => 'model-x', suite_id => 'inv-suite', topic => 'netz', status => 'done', error => undef,
      cases_total => 2, cases_passed => 1, usage => {},
      cases => [
        row( difficulty => 'schwer' ),
        row( case_id => 'k-2', title => 'Case two', status => 'ungraded', score => 0.5, exceeded => $T,
          sim_gaps => ['wobble'], prompt_tokens => 0, completion_tokens => 0, prompt_tokens_max => 0, turns => 3, tool_calls => 3 ),
      ] },
    { id => 'run-b', target => 'model-x', suite_id => 'inv-suite', topic => 'netz', status => 'cancelled',
      error => 'abgebrochen',
      cases => [
        row( difficulty => 'schwer', status => 'ungraded', score => 0.5, sim_gaps => ['wobble'], tool_calls => 1, injection_held => $T ),
        row( case_id => 'k-2', title => 'Case two', status => 'failed', score => 0.3333, exceeded => $T ),
      ] },
  ],
};

my $grading = {
  'run-a' => { 'k-2' => {
    rules => [
      { title => 'state ok', kind => 'state', required => 1, passed => 1, detail => 'ok' },
      { title => 'check it', kind => 'check', required => 1, passed => 0, detail => 'Lücke', sim_gap => 'wobble' },
      { title => 'turns', kind => 'turns', required => 1, passed => 0, detail => 'zu viele Runden' },
    ],
    diff => [ { path => 'h.files./x', before => 'a' }, { path => 'h.files./y', after => 'b' } ],
    sim_gaps => [ { index => 1, tool => 'run_command', gap => 'wobble' } ],
    forbidden_calls => 0, injection_held => undef,
  } },
};

my $r = $CLASS->from_cai_platform( $cai, grading => $grading,
  suites => { 'inv-suite' => { version => '4', digest => 'dd',
    cases => { 'k-1' => { tags => ['stufe-48k'], tier => '48k', difficulty => 'leicht', weight => 1, hard => 0, untrusted => 1 },
               'k-2' => { difficulty => 'mittel' } } } } );

my $doc = JSON::MaybeXS->new( utf8 => 1 )->decode( $r->to_json );
is scalar @{ $doc->{runs} }, 1, 'two rows of one target and suite: one run';
my $run = $doc->{runs}[0];
is_deeply $run->{target}, { label => 'model-x', engine => undef, model => 'model-x', url => 'https://gpu.example/v1' },
  'target, credentials stripped';
is_deeply $run->{suite}, { id => 'inv-suite', version => '4', topic => 'netz', digest => 'dd' }, 'suite';
is_deeply $run->{variant}, { name => undef, settings => undef }, 'variant unknown';
is $run->{repeat}, 2, 'repeat from repeat_by_suite';
is $run->{status}, 'cancelled', 'done + cancelled: cancelled';
is $run->{error}, 'abgebrochen', 'run error';
ok !exists $doc->{topics} && !exists $doc->{verdicts}, 'derived numbers not carried';

my ( $k1, $k2 ) = @{ $run->{cases} };
is_deeply [ map { $_->{case_id} } @{ $run->{cases} } ], [ 'k-1', 'k-2' ], 'case order';
is_deeply [ map { $_->{status} } @{ $k1->{repetitions} } ], [ 'passed', 'uncertain' ], 'ungraded: uncertain';
is_deeply [ map { $_->{status} } @{ $k2->{repetitions} } ], [ 'turn_limit', 'turn_limit' ], 'exceeded: turn_limit';
is_deeply [ map { $_->{seed} } @{ $k1->{repetitions} } ], [ 1, 2 ], 'seed = round with repeat > 1';
is_deeply $k1->{tags}, ['stufe-48k'], 'case meta from suites';
ok $k1->{untrusted}, 'untrusted from suites';
is $k2->{tags}, undef, 'case meta unknown: null';
is $k1->{difficulty}, 'schwer', 'difficulty from the --report row (k57)';
is $k2->{difficulty}, 'mittel', '... from suites where the row has none';

my $a1 = $k1->{repetitions}[0];
is_deeply $a1->{tokens}, { input => 300, output => 20, reasoning => undef, input_max => 180 }, 'tokens';
is scalar @{ $a1->{turns} }, 2, 'turns count as entries';
is scalar @{ $a1->{calls} }, 2, 'calls count as entries';
is $a1->{score}, 1, 'score kept without a turn limit';
is $a1->{rules}, undef, 'no grading: rules null';
is $a1->{duration_ms}, 40, 'duration';
ok !$a1->{injection_held} && !defined $a1->{injection_held}, 'injection_held null';
my $b1 = $k1->{repetitions}[1];
is_deeply $b1->{sim_gaps}, [ { call => undef, tool => undef, gap => 'wobble' } ], 'gap text only';
ok $b1->{injection_held}, 'injection_held true';

my $a2 = $k2->{repetitions}[0];
is_deeply $a2->{tokens}, { input => undef, output => undef, reasoning => undef, input_max => undef }, 'usage 0: null';
is_deeply [ map { $_->{kind} } @{ $a2->{rules} } ], [ 'state', 'check' ], 'turns rule dropped';
is_deeply $a2->{rules}[1], { title => 'check it', kind => 'check', required => $T, passed => $F, reason => 'Lücke',
  sim_gap => 'wobble' }, 'rule mapped';
is $a2->{score}, 0.5, 'score recomputed without the turns rule';
is_deeply $a2->{diff}, [ { path => 'h.files./x', before => 'a', after => undef },
  { path => 'h.files./y', before => undef, after => 'b' } ], 'diff';
is_deeply $a2->{sim_gaps}, [ { call => 1, tool => 'run_command', gap => 'wobble' } ], 'gap with index';
is_deeply $a2->{calls}[1], { tool => 'run_command', args => undef, succeeded => undef, sim_gap => 'wobble' }, 'call filled';
is $k2->{repetitions}[1]{score}, undef, 'turn limit without grading: score null';

is $CLASS->from_json( $r->to_json )->to_json, $r->to_json, 'converted report round-trips';

subtest 'refusals' => sub {
  my $bad = JSON::MaybeXS->new->decode( JSON::MaybeXS->new->encode($cai) );
  $bad->{runs}[0]{cases}[0]{status} = 'weird';
  ok !eval { $CLASS->from_cai_platform($bad); 1 }, 'unknown case status';
  like $@, qr/unknown case status weird for k-1/, 'message';
  $bad = JSON::MaybeXS->new->decode( JSON::MaybeXS->new->encode($cai) );
  $bad->{runs}[1]{status} = 'running';
  ok !eval { $CLASS->from_cai_platform($bad); 1 }, 'unfinished run';
  $bad = JSON::MaybeXS->new->decode( JSON::MaybeXS->new->encode($cai) );
  $bad->{repeat_by_suite}{'inv-suite'} = 1;
  ok !eval { $CLASS->from_cai_platform($bad); 1 }, 'more rows than repeat';
  ok !eval { $CLASS->from_cai_platform( {} ); 1 }, 'not a report';
};

done_testing;
