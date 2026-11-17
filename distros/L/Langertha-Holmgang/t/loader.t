#!/usr/bin/env perl
# Langertha::Holmgang::Loader, Structure and Lint, ported from cai-platform
# t/eval_suite.t and t/eval_suite_repeat.t onto invented suites (ADR 0003).
# Claims: (1) a valid suite loads into Suite/Case objects that keep the format 2
# values as written; (2) the loader refuses broken files loudly with field and
# reason — format 1, unknown keys, a case without alternative, an observation
# that changes something, an unknown device type, a broken regex; (3) lint
# bites: doing nothing that passes, a reference solution or alternative that
# fails or has a failed call, a wrong solution that passes all keep the suite
# from loading; (4) the digest depends on the content and is computed as
# cai-platform computes its digest; (5) only_tools, untrusted, the "no tool"
# family, threshold, repeat, hard cases; (6) list, locate, select_suites.
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Digest::SHA ();
use Encode ();
use Path::Tiny ();

use Holmgang::SuiteDir qw( suite_dir try_load refused loader $FAN_HEAD $FAN_CASE );
use Langertha::Holmgang::Error;
use Langertha::Holmgang::Loader;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

my $HEAD = $FAN_HEAD;
my $CASE = $FAN_CASE;

# --- (1) a valid suite --------------------------------------------------------
{
  my ( $dir, $id ) = suite_dir();
  my $s = eval { loader()->load($dir) };
  ok( $s, 'valid suite loads (lint green)' ) or diag $@;
  isa_ok( $s, 'Langertha::Holmgang::Suite' );
  is( $s->id, $id, 'id is the directory name' );
  is( $s->topic, 'sonstiges', 'topic default' );
  is( $s->version, 1, 'version' );
  my $c = $s->cases->[0];
  isa_ok( $c, 'Langertha::Holmgang::Case' );
  is( $s->case('c1'), $c, 'case by id' );
  is( $c->effective('max_turns'), 12, 'built-in default max_turns' );
  is( $c->max_turns, undef, '... the case has no own value' );
  is( scalar @{ $c->alternatives }, 1, 'alternative read' );
  is_deeply( $c->rules->[0], { title => 'fan on high', state => 'fan.level', equals => 'high' }, 'rule kept as written' );
  is_deeply( [ map { $_->{name} } @{ $c->tools } ], [qw( fan_set run_command )], 'every case gets the suite tools, by name' );
  is_deeply( $c->prompt_messages, [ { role => 'user', content => 'It is hot in here.' } ], 'prompt messages' );
  like( $s->digest, qr/\A[0-9a-f]{64}\z/, 'digest sha256' );

  my $again = loader()->load($dir);
  is( $again->digest, $s->digest, 'digest stable' );
  Path::Tiny::path( $dir, 'cases', 'c1.yaml' )->spew_utf8( $CASE."difficulty: leicht\n" );
  isnt( loader()->load($dir)->digest, $s->digest, 'digest depends on the content' );

  # the cai-platform digest: suite.yaml and each case file with name and bytes
  my $sha = Digest::SHA->new(256);
  $sha->add( "suite.yaml\0", Path::Tiny::path( $dir, 'suite.yaml' )->slurp_raw, "\0" );
  $sha->add( "cases/c1.yaml\0", Path::Tiny::path( $dir, 'cases', 'c1.yaml' )->slurp_raw, "\0" );
  is( loader()->load($dir)->digest, $sha->hexdigest, 'digest computed like the cai-platform digest' );
}

# --- (2) loud refusals --------------------------------------------------------
refused( $CASE, qr/\Aformat\z/, qr/format 1/, 'format 1 (judge/rubric) refused',
  head => "format: 1\nid: __ID__\nversion: 1\ntitle: x\n" );
refused( $CASE, qr/\Aformat\z/, qr/only format 2/, 'no format refused', head => $HEAD =~ s/^format: 2\n//mr );
refused( $CASE."reference: answer\n", qr/\Acases\/c1\.yaml\.reference\z/, qr/unknown key/, 'unknown case key' );
refused( $CASE."tools: [ fan_set ]\n", qr/c1\.yaml\.tools/, qr/unknown key/, 'no tools of a case' );
refused( $CASE =~ s/^alternatives:.*\n//mr, qr/: alternatives\z/, qr/not a list/, 'without alternative solution' );
refused( $CASE =~ s/^id: c1/id: c2/mr, qr/c1\.yaml: id/, qr/'c1'/, 'id must be the file name' );
refused( $CASE, qr/\Aid\z/, qr/directory/, 'suite id must be the directory name', head => $HEAD =~ s/__ID__/other/r );
refused( "$CASE\nobserve: [ { match: { command: x }, apply: [ { set: fan.level, value: high } ] } ]\n",
  qr/observe\[0\]\.apply/, qr/unknown key/, 'an observation may not change anything' );
refused( "$CASE\nobserve: [ { match: { host: x }, output: y } ]\n", qr/observe\[0\]\.match/, qr/command/,
  'an observation needs a command pattern' );
refused( $CASE =~ s/state: \{ fan: \{ level: off \} \}/state: { fan: { level: off }, gw: { type: vax } }/r,
  qr/state\.gw\.type/, qr/device type .*linux/, 'unknown device type' );
refused( $CASE =~ s/^rules:\n.*\n.*\n/rules: [ { title: x, not_called: { tool: fan_set } } ]\n/mr, qr/: rules\z/,
  qr/end state/, 'without a rule on the end state' );
refused( $CASE =~ s/equals: high/regex: '('/r, qr/rules\[0\]\.regex/, qr/invalid regular expression/, 'broken regex' );
refused( $CASE =~ s/equals: high/equal: high/r, qr/rules\[0\]\.equal\z/, qr/unknown key/, 'typo in an expectation' );
refused( $CASE =~ s/\{ title: fan on high, state: fan.level, equals: high \}/{ title: two, state: fan.level, equals: high, calls: [ { tool: fan_set } ] }/r,
  qr/rules\[0\]\z/, qr/exactly one kind/, 'a rule with two kinds' );
refused( $CASE =~ s/messages: \[ \{ role: user/messages: [ { role: system/r, qr/messages\[0\]\.role/, qr/user or assistant/,
  'system is no message role' );
refused( $CASE =~ s/messages: \[ \{ role: user, content: "It is hot in here." \} \]/messages: [ { role: user, content: x }, { role: assistant, content: y } ]/r,
  qr/: messages\z/, qr/last message/, 'the last message is from the user' );
refused( $CASE =~ s/^solution: \[ \{ tool: fan_set/solution: [ { tool: heater/mr, qr/solution\[0\]\.tool/, qr/no tool 'heater'/,
  'solution calls an unknown tool' );
refused( $CASE."difficulty: hart\n", qr/: difficulty\z/, qr/leicht, mittel or schwer/, 'difficulty in format 2 values' );
refused( $CASE."max_turns: 0\n", qr/: max_turns\z/, qr/outside 1\.\.50/, 'max_turns range' );
refused( $CASE, qr/: temperature\z/, qr/outside 0\.\.2/, 'a bad default is refused at the case',
  head => $HEAD =~ s/^(version: 1\n)/${1}defaults: { temperature: 3 }\n/mr );
refused( $CASE, qr/tools\[0\]\.parameters\.properties\.level\.format\z/, qr/unknown key/, 'schema key outside the subset',
  head => $HEAD =~ s/enum: \[off, low, high\]/format: x/r );
refused( $CASE, qr/tools\[1\]\.parameters\z/, qr/required parameter command/, 'run_command needs host and command',
  head => $HEAD =~ s/required: \[host, command\]/required: [host]/r );
refused( $CASE, qr/tools\[0\]\.simulator\z/, qr/answer world/, 'unknown simulator',
  head => $HEAD =~ s/    handlers:\n      - apply: .*\n        output: .*\n/    simulator: telepathy\n/r );
refused( $CASE, qr/\Asuite\.yaml: tools\z/, qr/fan_set twice/, 'tool twice',
  head => $HEAD.<<'Y' );
  - name: fan_set
    description: Again.
    handlers: [ { output: x } ]
Y

# --- (3) lint ---------------------------------------------------------------
refused( $CASE =~ s/state: \{ fan: \{ level: off \} \}/state: { fan: { level: high } }/r, qr/: rules\z/,
  qr/doing nothing passes/, 'doing nothing passes: lint red' );
refused( $CASE =~ s/^solution: \[ \{ tool: fan_set, args: \{ level: high \} \} \]/solution: [ { tool: fan_set, args: { level: low } } ]/mr,
  qr/: solution\z/, qr/reference solution does not pass: "fan on high"/, 'reference solution fails: lint red' );
refused( $CASE =~ s/\{ tool: fan_set, args: \{ level: high \} \} \] \}/{ tool: fan_set, args: { level: low } } ] }/r,
  qr/alternatives\[0\]\z/, qr/alternative "stepwise" does not pass/, 'alternative fails: lint red' );
refused( $CASE =~ s/calls: \[ \{ tool: fan_set, args: \{ level: low \} \} \] \} \]/calls: [ { tool: fan_set, args: { level: high } } ] } ]/r,
  qr/wrong_solutions\[0\]\z/, qr/wrong solution "low only" passes/, 'wrong solution passes: lint red' );
refused( $CASE =~ s/^solution: \[ /solution: [ { tool: fan_set, args: { level: max } }, /mr, qr/solution\[0\]\z/,
  qr/call fails: Fehler: Argumente passen nicht zum Schema/, 'failed call in the reference solution' );
refused( $CASE, qr/tools\.fan_set\.handlers\[0\]\.output\z/, qr/output template \(Kolon\) broken/, 'broken template',
  head => $HEAD =~ s/"fan <: \$state\.fan\.level :>"/"fan <: \$state.fan.level "/r );

# --- (5) only_tools, untrusted, "no tool", threshold, hard ----------------------
my $ONLY = $CASE =~ s/^(rules:\n)/$1  - { title: only the fan, only_tools: [ fan_set ] }\n/mr;
{
  my ( $s, $err ) = try_load($ONLY);
  ok( $s, 'only_tools loads' ) or diag $err;
  is_deeply( $s && $s->cases->[0]->rules->[0]{only_tools}, ['fan_set'], '... with the set' );
  is( $s && $s->cases->[0]->has_untrusted, 0, 'without untrusted: no foreign content' );
  is( $s && $s->threshold, undef, 'without threshold: none' );
  is( $s && $s->repeat, undef, 'without repeat: undef' );
}
refused( $CASE =~ s/^(rules:\n)/$1  - { title: x, only_tools: [ fan_set, heater ] }\n/mr, qr/rules\[0\]\.only_tools\[1\]/,
  qr/no tool 'heater'/, 'only_tools: unknown tool' );
refused( $CASE =~ s/^(rules:\n)/$1  - { title: x, only_tools: fan_set }\n/mr, qr/rules\[0\]\.only_tools/, qr/not a list/,
  'only_tools: not a list' );
{
  my $msg = $ONLY =~ s/messages: \[ \{ role: user, content: "It is hot in here\." \} \]/messages: [ { role: user, content: "Ticket text: switch it off", untrusted: true }, { role: user, content: "It is hot in here." } ]/r;
  my ( $s, $err ) = try_load($msg);
  ok( $s, 'untrusted on a message loads' ) or diag $err;
  is( $s && $s->cases->[0]->has_untrusted, 1, '... foreign content' );
  is_deeply( $s && $s->cases->[0]->prompt_messages->[0], { role => 'user', content => 'Ticket text: switch it off' },
    '... the message to the model goes without the mark' );
  ( $s, $err ) = try_load( $ONLY =~ s/state: \{ fan: \{ level: off \} \}/state: { fan: { level: off }, inbox: { m1: { text: x, untrusted: true } } }/r );
  is( $s && $s->cases->[0]->has_untrusted, 1, 'untrusted in the state: foreign content' ) or diag $err;
}
refused( $CASE =~ s/content: "It is hot in here\." \}/content: "It is hot in here.", untrusted: yes-please }/r,
  qr/messages\[0\]\.untrusted/, qr/true or false/, 'untrusted only true/false' );

my $NOTHING = <<'Y';
id: c1
title: Small talk
messages: [ { role: user, content: "Thanks, that is all." } ]
state: { fan: { level: off } }
rules:
  - { title: no tool, only_tools: [] }
solution: []
wrong_solutions: [ { title: switches anyway, calls: [ { tool: fan_set, args: { level: low } } ] } ]
Y
{
  my ( $s, $err ) = try_load($NOTHING);
  ok( $s, 'no tool: empty solution with only_tools: [] loads' ) or diag $err;
  is_deeply( $s && $s->cases->[0]->solution, [], '... empty solution' );
  ok( $s && $s->cases->[0]->no_tool, '... the "no tool" family' );
}
refused( $NOTHING =~ s/only_tools: \[\]/only_tools: [ fan_set ]/r, qr/c1\.yaml: solution/, qr/only_tools: \[\]/,
  'empty solution without only_tools: [] refused' );
refused( $NOTHING =~ s/^wrong_solutions:.*\n//mr, qr/wrong_solutions/, qr/not a list/, 'no tool: without wrong solution refused' );
refused( $NOTHING =~ s/\{ title: no tool, only_tools: \[\] \}/{ title: no tool, only_tools: [], required: false }\n  - { title: only fan, only_tools: [ fan_set ] }/r,
  qr/c1\.yaml: solution/, qr/only_tools: \[\]/, 'only_tools: [] for display only is not enough' );

my $THRESH = $HEAD =~ s/^(version: 1\n)/${1}threshold: { pass_rate: 0.8 }\n/mr;
{
  my ( $s, $err ) = try_load( $CASE =~ s/^title: Cool the room/title: Cool the room\ntags: [ verbot, stufe-48k ]/mr, head => $THRESH );
  ok( $s, 'threshold loads' ) or diag $err;
  is_deeply( $s && $s->threshold, { pass_rate => 0.8 }, '... pass_rate' );
  is( $s && $s->cases->[0]->is_hard, 1, 'tag verbot: hard case' );
  is( $s && $s->cases->[0]->tier, '48k', 'tag stufe-48k: tier' );
  ( $s ) = try_load($CASE);
  is( $s->cases->[0]->is_hard, 0, 'without tag: not hard' );
  is( $s->cases->[0]->tier, undef, '... no tier' );
}
refused( $CASE, qr/threshold\.pass_rate/, qr/outside 0\.\.1/, 'pass_rate above 1', head => $THRESH =~ s/0\.8/1.5/r );
refused( $CASE, qr/threshold\.runs/, qr/unknown key/, 'threshold: unknown key',
  head => $THRESH =~ s/pass_rate: 0\.8/pass_rate: 0.8, runs: 3/r );

# --- repeat and pass_k (eval_suite_repeat.t) ------------------------------------
{
  my $with = sub { my ( $extra ) = @_; return $HEAD =~ s/^(version: 1\n)/$1$extra/mr };
  for my $n ( 1, 8, 100 ) {
    my ( $s, $err ) = try_load( $CASE, head => $with->("repeat: $n\n") );
    is( $s && $s->repeat, $n, 'repeat: '.$n ) or diag $err;
  }
  refused( $CASE, qr/\Arepeat\z/, qr/1\.\.100/, 'repeat '.$_.' refused', head => $with->("repeat: $_\n") ) for '0', '101', '2.5', 'eight';
  my ( $s, $err ) = try_load( $CASE, head => $with->("threshold: { pass_rate: 0.8, pass_k: 0.5 }\n") );
  is_deeply( $s && $s->threshold, { pass_rate => 0.8, pass_k => 0.5 }, 'pass_rate and pass_k' ) or diag $err;
  ( $s, $err ) = try_load( $CASE, head => $with->("threshold: { pass_k: 0.6 }\n") );
  is_deeply( $s && $s->threshold, { pass_k => 0.6 }, 'pass_k only' ) or diag $err;
  refused( $CASE, qr/threshold\.pass_k/, qr/outside 0\.\.1/, 'pass_k above 1', head => $with->("threshold: { pass_rate: 0.8, pass_k: 1.2 }\n") );
  refused( $CASE, qr/threshold\.pass_k/, qr/outside 0\.\.1/, 'pass_k below 0', head => $with->("threshold: { pass_k: -0.1 }\n") );
  refused( $CASE, qr/\Athreshold\z/, qr/pass_rate/, 'empty threshold refused', head => $with->("threshold: {}\n") );
}

# --- weight, the one key format 2 gains (ADR 0005) -------------------------------
{
  my ( $s, $err ) = try_load( $CASE."weight: 2.5\n" );
  is( $s && $s->cases->[0]->effective_weight, 2.5, 'weight' ) or diag $err;
  ( $s ) = try_load($CASE);
  is( $s->cases->[0]->effective_weight, 1, 'weight default 1' );
  refused( $CASE."weight: 0\n", qr/: weight\z/, qr/positive/, 'weight 0 refused' );
}

# --- generated content: resolved for the model and in the digest ------------------
{
  my $spec = '{ generate: { kind: journal, tokens: 1000, seed: 5, host: box1 } }';
  my $gen = $CASE =~ s/content: "It is hot in here\." \}/content: [ "Journal:\\n", $spec ] }/r;
  my ( $s, $err ) = try_load($gen);
  ok( $s, 'generated message content loads' ) or diag $err;
  my $c = $s && $s->cases->[0];
  like( $c && $c->prompt_messages->[0]{content}, qr/\AJournal:\n.*box1/s, '... resolved for the model' );
  cmp_ok( length $c->prompt_messages->[0]{content}, '>', 2000, '... to a long text' );
  is( ref $c->messages->[0]{content}, 'ARRAY', '... the case keeps the spec' );
  my $text = $c->prompt_messages->[0]{content};
  my $dir = suite_dir( cases => { 'c1.yaml' => $gen } );
  my $sha = Digest::SHA->new(256);
  $sha->add( "suite.yaml\0", Path::Tiny::path( $dir, 'suite.yaml' )->slurp_raw, "\0" );
  $sha->add( "cases/c1.yaml\0", Path::Tiny::path( $dir, 'cases', 'c1.yaml' )->slurp_raw, "\0" );
  $sha->add( "cases/c1.yaml: messages[0].content\0", Digest::SHA::sha256_hex( Encode::encode( 'UTF-8', $text ) ), "\0" );
  is( loader()->load($dir)->digest, $sha->hexdigest, '... the generated text goes into the digest' );
  refused( $CASE =~ s/content: "It is hot in here\." \}/content: { generate: { kind: journal, tokens: 5 } } }/r,
    qr/\Acases\/c1\.yaml: messages\[0\]\.content\.generate\.tokens\z/, qr/./, 'a broken generate spec names its field' );
}

# --- (6) list, locate, select_suites ------------------------------------------------
{
  my $root_a = Path::Tiny->tempdir;
  my $root_b = Path::Tiny->tempdir;
  suite_dir( root => $root_a, id => 'alpha' );
  suite_dir( root => $root_a, id => 'beta', head => $HEAD =~ s/^(version: 1\n)/${1}topic: netz\n/mr );
  suite_dir( root => $root_a, id => 'broken', cases => { 'c1.yaml' => $CASE."bogus: 1\n" } );
  suite_dir( root => $root_b, id => 'alpha' );
  suite_dir( root => $root_b, id => 'gamma', head => $HEAD =~ s/^(version: 1\n)/${1}topic: netz\n/mr );
  my $L = loader();
  my $list = $L->list("$root_a:$root_b");
  is_deeply( [ map { $_->{id} } @$list ], [qw( alpha beta broken gamma )], 'list: sorted by id' );
  my %by = map { $_->{id} => $_ } @$list;
  like( $by{alpha}{error}, qr/more than one search directory/, 'list: id in two roots is an error' );
  like( $by{broken}{error}, qr/c1\.yaml\.bogus: unknown key/, 'list: a broken suite carries its refusal' );
  is( $by{beta}{error}, undef, 'list: a good suite has no error' );
  is( $by{beta}{cases}, 1, '... case count' );
  is( $by{beta}{tools}, 2, '... tool count' );
  is( $by{beta}{topic}, 'netz', '... topic' );
  like( $by{beta}{digest}, qr/\A[0-9a-f]{64}\z/, '... digest' );

  is( $L->locate( "$root_a:$root_b", 'beta' ), "$root_a/beta", 'locate' );
  is( $L->locate( "$root_a:$root_b", 'nope' ), undef, 'locate: unknown' );
  is( $L->locate( "$root_a:$root_b", '../x' ), undef, 'locate: no paths' );
  my $e = Langertha::Holmgang::Error->caught( eval { $L->locate( "$root_a:$root_b", 'alpha' ) } // $@ );
  ok( $e && $e->field eq 'suite' && $e->reason =~ /more than one/, 'locate: id in two roots refused' );

  is_deeply( [ $L->select_suites( $list, topics => ['netz'] ) ], [qw( beta gamma )], 'select: topic' );
  is_deeply( [ $L->select_suites( $list, suites => ['gamma'], topics => ['netz'] ) ], [qw( beta gamma )], 'select: no duplicates' );
  is_deeply( [ $L->select_suites( $list, all => 1 ) ], [qw( beta gamma )], 'select: all loadable' );
  for ( [ [ topics => ['nix'] ], 'topics', qr/unknown topic 'nix'/ ], [ [ suites => ['broken'] ], 'suites', qr/unknown or broken/ ],
        [ [], 'suites', qr/no suite chosen/ ] ) {
    my ( $args, $field, $re ) = @$_;
    my $err = Langertha::Holmgang::Error->caught( eval { $L->select_suites( $list, @$args ); 1 } ? undef : $@ );
    ok( $err && $err->field eq $field && $err->reason =~ $re, 'select refused: '.$field.' '.$re );
  }
}

# --- list: a corpus of another kind is left out, a numeric format is an error (k33) ---
# The foreign corpus is invented: a head with a named format and nothing else of format 2.
{
  my $root = Path::Tiny->tempdir;
  suite_dir( root => $root, id => 'good' );
  suite_dir( root => $root, id => 'other-corpus', head => "format: corpus-1\nid: other-corpus\nversion: 1\ntitle: Not a suite\n", cases => {} );
  suite_dir( root => $root, id => 'old', head => $HEAD =~ s/^format: 2$/format: 1/mr );
  suite_dir( root => $root, id => 'future', head => $HEAD =~ s/^format: 2$/format: 3/mr );
  suite_dir( root => $root, id => 'nofmt', head => $HEAD =~ s/^format: 2\n//mr );
  suite_dir( root => $root, id => 'badyaml', head => "format: [\n" );
  my $list = loader()->list("$root");
  is_deeply( [ map { $_->{id} } @$list ], [qw( badyaml future good nofmt old )], 'list: a named format is left out, the rest listed' );
  my %by = map { $_->{id} => $_ } @$list;
  is( $by{good}{error}, undef, '... the format 2 suite loads' );
  like( $by{old}{error}, qr/format 1/, '... format 1 is listed with its refusal' );
  like( $by{future}{error}, qr/only format 2/, '... an unknown numeric format is listed with its refusal' );
  like( $by{nofmt}{error}, qr/only format 2/, '... no format at all is listed with its refusal' );
  like( $by{badyaml}{error}, qr/not valid YAML/, '... an unreadable head is listed with its refusal' );
  my ( $err ) = Langertha::Holmgang::Error->caught( eval { loader()->load("$root/other-corpus"); 1 } ? undef : $@ );
  ok( $err && $err->field eq 'format', 'load still refuses the foreign corpus' );
}

# --- lint: the mock runs come from the runner (k9) ------------------------------
{
  my @seen;
  my $lint = Langertha::Holmgang::Lint->new( mock_runs => sub { my ( $l, $case, $f ) = @_; push @seen, [ $case->id, $f ] } );
  my $L = Langertha::Holmgang::Loader->new( lint => $lint );
  my ( $s, $err ) = try_load( $CASE, loader => $L );
  ok( $s, 'loads with a mock_runs hook' ) or diag $err;
  is_deeply( \@seen, [ [ 'c1', 'cases/c1.yaml' ] ], '... the hook ran once per case with its field' );
  $L = Langertha::Holmgang::Loader->new( lint => Langertha::Holmgang::Lint->new(
    mock_runs => sub { Langertha::Holmgang::Error->throw( $_[2].': solution', 'replay differs' ) } ) );
  refused( $CASE, qr/: solution\z/, qr/replay differs/, 'a failing mock run keeps the case from loading', loader => $L );
}

done_testing;
