#!/usr/bin/env perl
# The comparison as text, Markdown and JSON (ADR 0008): row = target and
# variant, column = topic, overall = mean of the topics; verdicts with the hard
# cases that failed them; tier curves only when a case has a tier, difficulty
# curves only when a case has a difficulty (k57). JSON is
# canonical and holds exactly as_data. Invented data only (ADR 0003).
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::EvalReport qw( evaluation );

my @runs = (
  { target => 'mock-a', variant => 'plain', suite => 'net-1', topic => 'netz',
    cases => [ 'n1', { id => 'inj', hard => 1 } ], repeat => 2,
    results => [ [ 'n1', 1, 'passed' ], [ 'n1', 2, 'passed' ], [ 'inj', 1, 'passed' ], [ 'inj', 2, 'failed', 1 ] ] },
  { target => 'mock-a', variant => 'plain', suite => 'db-1', topic => 'datenbank',
    results => [ [ 'd1', 1, 'failed' ] ] },
  { target => 'mock|b', variant => undef, suite => 'net-1', topic => 'netz',
    results => [ [ 'n1', 1, 'passed' ], [ 'n2', 1, 'failed' ] ] },
);
my $e = evaluation( \@runs, thresholds => { 'net-1' => { pass_rate => 0.5, pass_k => 0.5 } } );

subtest 'comparison' => sub {
  my $c = $e->comparison;
  is_deeply $c->{topics}, [qw( datenbank netz )], 'columns: topics by name';
  is_deeply $c->{rows}, [
    { target => 'mock-a', variant => 'plain', rates => { datenbank => 0, netz => 0.75 }, overall => 0.375 },
    { target => 'mock|b', variant => undef, rates => { netz => 0.5 }, overall => 0.5 },
  ], 'rows: target and variant, overall the mean';
};

subtest 'text' => sub {
  my $t = $e->to_text;
  like $t, qr/^target\s+variant\s+datenbank\s+netz\s+overall$/m, 'header';
  like $t, qr/^mock-a\s+plain\s+0\.0%\s+75\.0%\s+37\.5%$/m, 'row a';
  like $t, qr/^mock\|b\s+-\s+-\s+50\.0%\s+50\.0%$/m, 'row b: no variant, topic not run';
  like $t, qr/^mock-a\s+plain\s+net-1\s+3\/4\s+75\.0%\s+50\.0%\s+50\.0% \(k=2\)\s+50\.0%\s+NOT PASSED$/m,
    'verdict with threshold, pass^k and k';
  like $t, qr/^  hard: inj - 1 forbidden call\(s\) in 1 of 2$/m, 'hard case named';
  like $t, qr/^mock-a\s+plain\s+db-1\s+0\/1\s+0\.0%\s+-\s+-\s+-\s+ok$/m, 'no threshold, k = 1: ok, no pass^k';
  unlike $t, qr/Length tiers/, 'no tier section without tiers';
  unlike $t, qr/^Difficulty/m, 'no difficulty section without difficulties';
  unlike $t, qr/[ \t]$/m, 'no trailing blanks';
};

subtest 'markdown' => sub {
  my $m = $e->to_markdown;
  like $m, qr/^### Comparison by topic/m, 'heading';
  like $m, qr/^\| target \| variant \| datenbank \| netz \| overall \|$/m, 'header row';
  like $m, qr/^\|---\|---\|---\|---\|---\|$/m, 'separator';
  like $m, qr/^\| mock\\\|b \| - \| - \| 50\.0% \| 50\.0% \|$/m, 'pipe in a label escaped';
  like $m, qr{^- mock-a / plain / net-1: hard: inj - 1 forbidden call\(s\) in 1 of 2$}m, 'hard case as a list item, naming its row';
};

subtest 'json' => sub {
  my $bytes = $e->to_json;
  my $doc = JSON::MaybeXS->new( utf8 => 1 )->decode($bytes);
  is $doc->{holmgang_evaluation}, 1, 'format version';
  is_deeply [ sort keys %$doc ], [qw( comparison difficulty_curves holmgang_evaluation overall tier_curves topics verdicts )],
    'sections (k57: difficulty_curves)';
  ok JSON::MaybeXS::is_bool( $doc->{verdicts}[0]{ok} ), 'ok is a JSON boolean';
  is_deeply $doc, JSON::MaybeXS->new( utf8 => 1 )->decode( JSON::MaybeXS->new( utf8 => 1, convert_blessed => 1 )->encode( $e->as_data ) ),
    'holds exactly as_data';
  is evaluation( \@runs, thresholds => { 'net-1' => { pass_rate => 0.5, pass_k => 0.5 } } )->to_json, $bytes,
    'same reports, same bytes';
};

subtest 'tiers in text' => sub {
  my $t = evaluation( [ { target => 'm', suite => 's', topic => 'lang', cases => [ { id => 'a', tier => '48k' } ],
    results => [ [ 'a', 1, 'context_exceeded' ] ] } ] )->to_text;
  like $t, qr/^Length tiers/m, 'section';
  like $t, qr/^m\s+plain\s+lang\s+48k\s+1\s+0\.0%\s+100\.0%\s+0\.0%$/m, 'shares apart';
};

subtest 'difficulties in text and markdown' => sub {
  my $ev = evaluation( [ { target => 'm', suite => 's', topic => 'denken',
    cases => [ { id => 'a', difficulty => 'leicht' }, { id => 'b', difficulty => 'schwer' } ],
    results => [ [ 'a', 1, 'passed' ], [ 'b', 1, 'error' ] ] } ] );
  my $t = $ev->to_text;
  like $t, qr/^Difficulty \(shares of all results\)$/m, 'section';
  like $t, qr/^target\s+variant\s+topic\s+difficulty\s+results\s+passed\s+context_exceeded\s+error$/m, 'header';
  like $t, qr/^m\s+plain\s+denken\s+leicht\s+1\s+100\.0%\s+0\.0%\s+0\.0%$/m, 'leicht row';
  like $t, qr/^m\s+plain\s+denken\s+schwer\s+1\s+0\.0%\s+0\.0%\s+100\.0%$/m, 'schwer row, error apart';
  unlike $t, qr/Length tiers/, 'no tier section';
  my $m = $ev->to_markdown;
  like $m, qr/^### Difficulty \(shares of all results\)$/m, 'markdown heading';
  like $m, qr/^\| m \| plain \| denken \| leicht \| 1 \| 100\.0% \| 0\.0% \| 0\.0% \|$/m, 'markdown row';
  is_deeply [ map { $_->{difficulty} } @{ JSON::MaybeXS->new( utf8 => 1 )->decode( $ev->to_json )->{difficulty_curves} } ],
    [qw( leicht schwer )], 'json';
};

done_testing;
