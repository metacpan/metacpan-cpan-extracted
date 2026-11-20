#!/usr/bin/env perl
# Runner and batch with a sandbox (ADR 0011): a real program the Linux
# simulator does not model is a gap without a sandbox and runs in it with one.
# Claimed: the model gets the program's output, the end state carries what the
# program wrote, the call names how many programs ran for real, the case is not
# uncertain any more; loading and lint never touch the sandbox; the report
# keeps the mark and names the sandbox, and a report without one is unchanged.
# The sandbox is a stand-in: no Docker, no network.
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::SuiteDir qw( suite_dir );
use Langertha::Engine::Virtual;
use Langertha::Virtual::Rules qw( answer tool );
use Langertha::Holmgang::Batch;
use Langertha::Holmgang::Loader;
use Langertha::Holmgang::Report;
use Langertha::Holmgang::Runner;
use Langertha::Holmgang::Target;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

{
  package Fake::Sandbox;
  sub new { return bless { calls => [], log => [] }, shift }
  sub run {
    my ( $self, %a ) = @_;
    push @{ $self->{calls} }, \%a;
    push @{ $self->{log} }, { argv => $a{argv}, exit => 0, ms => 1 };
    return { output => "COUNTED-4\n", exit => 0, deleted => [],
      changed => { '/srv/app/data.json' => { content => qq({"n": 4}\n), mode => 0644 } } };
  }
  sub take_log { my ( $self ) = @_; return splice @{ $self->{log} } }
}

my $HEAD = <<'Y';
format: 2
id: __ID__
version: 1
title: Counter
topic: zaehler
defaults: { system: "You look after the counter.", max_turns: 4 }
tools:
  - name: run_command
    description: Runs a shell command on a host.
    simulator: run_command
    parameters: { type: object, required: [host, command], properties: { host: { type: string }, command: { type: string } } }
Y

my %CASES = ( 'count.yaml' => <<'Y' );
id: count
title: Raise the counter
messages: [ { role: user, content: "Raise n in /srv/app/data.json on h by one." } ]
state: { h: { type: linux, files: { /srv/app/data.json: "{\"n\": 3}\n" } } }
rules:
  - { title: n is 4, state: [ h, files, /srv/app/data.json ], regex: '"n":\s*4\b' }
solution: [ { tool: run_command, args: { host: h, command: "sed -i 's/\"n\": 3/\"n\": 4/' /srv/app/data.json" } } ]
alternatives: [ { title: rewritten, calls: [ { tool: run_command, args: { host: h, command: "echo '{\"n\": 4}' > /srv/app/data.json" } } ] } ]
wrong_solutions: [ { title: read only, calls: [ { tool: run_command, args: { host: h, command: "cat /srv/app/data.json" } } ] } ]
Y

my $suite = Langertha::Holmgang::Loader->new->load( scalar suite_dir( head => $HEAD, cases => \%CASES, id => 'counter' ) );
my ( $case ) = @{ $suite->cases };
ok( $case, 'the invented suite loads and lints without any sandbox' );

my $PY = q{python3 -c 'import json; p="/srv/app/data.json"; d=json.load(open(p)); d["n"]+=1; json.dump(d,open(p,"w")); print("COUNTED-%d" % d["n"])'};
sub script { [ tool( run_command => { host => 'h', command => $PY } ), answer('done') ] }
sub engine { Langertha::Engine::Virtual->new( script => script() ) }

# --- without a sandbox: the gap, the case uncertain -------------------------------------
{
  my $r = Langertha::Holmgang::Runner->new( target => Langertha::Holmgang::Target->new( engine => engine() ) )->run_case($case);
  is( $r->{status}, 'uncertain', 'without a sandbox the python call is a gap and the case uncertain' );
  like( $r->{calls}[0]{sim_gap}, qr/\Apython3 -c/, '... the call carries the gap' );
  ok( !exists $r->{calls}[0]{sandbox}, '... and no sandbox mark' );
}

# --- with a sandbox: the program ran, the case is graded ------------------------------------
{
  my $sb = Fake::Sandbox->new;
  my $e  = engine();
  my $r  = Langertha::Holmgang::Runner->new( target => Langertha::Holmgang::Target->new( engine => $e ), sandbox => $sb )->run_case($case);
  is( $r->{status}, 'passed', 'with a sandbox the case passes' );
  is( $r->{calls}[0]{sim_gap}, undef, '... no gap' );
  is( $r->{calls}[0]{sandbox}, 1, '... the call names one program that ran for real' );
  ok( $r->{calls}[0]{succeeded}, '... and succeeded' );
  is( $r->{state}{h}{files}{'/srv/app/data.json'}, qq({"n": 4}\n), 'the end state carries what the program wrote' );
  my $wire = JSON::MaybeXS->new( canonical => 1 )->encode( [ map { $_->{body} } @{ $e->requests } ] );
  like( $wire, qr/COUNTED-4/, 'the model gets the program\'s output' );
  is( scalar @{ $sb->{calls} }, 1, 'one program went to the sandbox' );
  is( $sb->{calls}[0]{argv}[0], 'python3', '... the python call' );
  is( scalar @{ $sb->{log} }, 0, 'the log is taken into the call' );
}

# --- batch and report ---------------------------------------------------------------------
{
  my $sb = Fake::Sandbox->new;
  my $batch = Langertha::Holmgang::Batch->new(
    suites  => [$suite],
    targets => [ { target => { label => 't', engine => 'Virtual', model => 'm' }, engine => sub { engine() } } ],
    sandbox => $sb, sandbox_label => 'docker example:1 sha256:abc',
  );
  my $report = $batch->run;
  my $data = $report->as_data;
  is( $data->{generator}{sandbox}, 'docker example:1 sha256:abc', 'the report names the sandbox' );
  my $rep = $data->{runs}[0]{cases}[0]{repetitions}[0];
  is( $rep->{status}, 'passed', 'the batch hands the sandbox to its runners' );
  is( $rep->{calls}[0]{sandbox}, 1, 'the report keeps the mark of the call' );
  my $again = Langertha::Holmgang::Report->from_json( $report->to_json );
  is( $again->as_data->{runs}[0]{cases}[0]{repetitions}[0]{calls}[0]{sandbox}, 1, '... and reads it back' );

  my $plain = Langertha::Holmgang::Batch->new(
    suites  => [$suite],
    targets => [ { target => { label => 't', engine => 'Virtual', model => 'm' }, engine => sub { engine() } } ],
  )->run->as_data;
  ok( !exists $plain->{generator}{sandbox}, 'a report without a sandbox does not name one' );
  ok( !exists $plain->{runs}[0]{cases}[0]{repetitions}[0]{calls}[0]{sandbox}, '... and its calls carry no mark' );
}

done_testing;
