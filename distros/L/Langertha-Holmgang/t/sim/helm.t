#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::TestSim qw( run_command clone need_parts without_part );

# helm on the Linux simulator, the parts of its grammar that the Helm subtest in
# t/sim/kubernetes_adv.t does not cover: no cluster, the help text, unknown commands
# and plugins, real commands without emulation (sim_gap), a refused upgrade that
# leaves the state as it was — and the neutral end of a call while the Kubernetes
# part is not installed.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $start = {
  ops => {
    type       => 'linux',
    kubernetes => {
      context           => 'test',
      default_namespace => 'default',
      namespaces        => { apps => {} },
      helm              => {
        repos  => { demo => 'https://charts.demo.test' },
        charts => { 'demo/hello' => { versions => {
          '0.1.0' => { app_version => '0.1', values => { replicas => 1 }, resources => [] },
        } } },
        releases => { apps => {
          hello => { chart => 'demo/hello', version => '0.1.0', revision => 1, status => 'pending-install', values => {},
            updated => '2026-01-02 03:04:05', description => 'Initial install underway', manifest => [], history => [] },
        } },
      },
    },
  },
};

sub run {
  my ( $s, $cmd ) = @_;
  return run_command( $s, 'ops', $cmd );
}

subtest 'without a cluster' => sub {
  my $s = { ops => { type => 'linux' } };
  my ( $o, $ok, $gap ) = run( $s, 'helm list -A' );
  ok( !$ok, 'fails' );
  like( $o, qr/\AError: Kubernetes cluster unreachable: .*connection refused\z/, '... like helm without a kubeconfig' );
  ok( !defined $gap, '... and is no gap' );
};

subtest 'Kubernetes part not installed' => sub {
  my $s = clone($start);
  my ( $o, $ok, $gap ) = without_part( Kubernetes => sub { run( $s, 'helm list -n apps' ) } );
  is( $o, '', 'neutral output' );
  ok( !$ok, 'failed' );
  is( $gap, 'Langertha::Holmgang::Sim::Linux::Kubernetes is not installed', 'sim_gap names the part' );
  is_deeply( $s, $start, 'state untouched' );
};

subtest 'grammar' => sub {
  my $why = need_parts('Kubernetes');
  plan skip_all => $why if $why;
  my $s = clone($start);
  my ( $o, $ok, $gap ) = run( $s, 'helm' );
  ok( $ok && $o =~ /\AThe Kubernetes package manager\n\nUsage:\n  helm \[command\]/, 'bare helm: usage' );
  ( $o, $ok, $gap ) = run( $s, 'helm frobnicate' );
  ok( !$ok, 'unknown command fails' );
  like( $o, qr/\AError: unknown command "frobnicate" for "helm"\nRun 'helm --help' for usage\.\z/, '... with the helm message' );
  ok( !defined $gap, '... and is no gap' );
  ( $o, $ok, $gap ) = run( $s, 'helm secrets view x' );
  ok( !$ok && $o =~ /unknown command "secrets"/ && !defined $gap, 'a plugin that is not installed is an unknown command' );
  ( $o, $ok, $gap ) = run( $s, 'helm list --frob' );
  ok( !$ok && $o eq 'Error: unknown flag: --frob', 'unknown flag' );
  for my $cmd ( 'helm lint ./chart', 'helm pull demo/hello', 'helm get hooks hello -n apps' ) {
    ( $o, $ok, $gap ) = run( $s, $cmd );
    is( $o, '', $cmd.': neutral output' );
    ok( defined $gap, '... sim_gap' );
  }
  is_deeply( $s, $start, 'none of it changes the state' );
};

subtest 'refused upgrade leaves the state' => sub {
  my $why = need_parts('Kubernetes');
  plan skip_all => $why if $why;
  my $s = clone($start);
  my ( $o, $ok ) = run( $s, 'helm upgrade hello demo/hello -n apps --set replicas=2' );
  ok( !$ok, 'pending release: upgrade refused' );
  like( $o, qr/another operation \(install\/upgrade\/rollback\) is in progress/, '... with the helm message' );
  is_deeply( $s, $start, '... nothing changed' );
};

done_testing;
