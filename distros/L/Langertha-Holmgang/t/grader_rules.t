#!/usr/bin/env perl
# The rule kinds packet and login, and a simulator plugin from outside the core
# through loader, world and grader. Every world here is invented (ADR 0003).
# Claims: the grader asks the device's simulator through the registry (never a
# part directly) and grades its answer; boot goes along; a device the rule
# names but the state lacks, or whose simulator cannot answer, misses the rule
# with a reason; the loader checks the shape of packet and login rules; a
# registered plugin type loads, dispatches and grades like a built-in.
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

{
  package Test::Sim::Gate;
  use Moose;
  with 'Langertha::Holmgang::Role::Simulator';
  sub device_type { 'gate' }
  sub run_command {
    my ( $self, $dev, $cmd ) = @_;
    if ( $cmd =~ /\Aopen (\d+)\z/ ) { push @{ $dev->{open} }, 0 + $1; return ( 'opened '.$1, 1 ) }
    if ( $cmd =~ /\Aallow (\w+)\z/ ) { $dev->{users}{$1} = 1; return ( 'ok', 1 ) }
    return ( 'gate: unknown command', 0 );
  }
  sub packet_verdict {
    my ( $self, $dev, $pkt, $boot ) = @_;
    my $set = $boot ? $dev->{saved} || [] : $dev->{open} || [];
    my $hit = grep { $_ == ( $pkt->{dport} // -1 ) } @$set;
    return ( $hit ? 'accept' : 'drop', ( $boot ? 'saved ' : '' ).'port '.( $pkt->{dport} // '-' ) );
  }
  sub login_check {
    my ( $self, $dev, $t, $host ) = @_;
    return $dev->{users}{ $t->{user} } ? ( 1, 'Welcome to '.$host ) : ( 0, $t->{user}.'@'.$host.': Permission denied', 'refused '.$t->{user} );
  }
  __PACKAGE__->meta->make_immutable;
}

use Holmgang::SuiteDir qw( try_load refused );
use Langertha::Holmgang::Case;
use Langertha::Holmgang::Grader;
use Langertha::Holmgang::Loader;
use Langertha::Holmgang::Simulators;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

my $sims = Langertha::Holmgang::Simulators->new( register_classes => ['Test::Sim::Gate'] );
my $G = Langertha::Holmgang::Grader->new( simulators => $sims );
my $pkt = { host => 'g1', hook => 'input', saddr => '192.0.2.1', daddr => '192.0.2.2', proto => 'tcp', dport => 8080 };

{
  my $case = Langertha::Holmgang::Case->new( id => 'c', simulators => $sims, state => { g1 => { type => 'gate', open => [], saved => [8080] } },
    rules => [
      { title => 'port open', packet => $pkt, verdict => 'accept' },
      { title => 'open after reboot', packet => $pkt, verdict => 'accept', boot => 1 },
      { title => 'anna gets in', login => { host => 'g1', user => 'anna', from => '192.0.2.5' }, result => 'allowed' },
      { title => 'bob stays out', login => { host => 'g1', user => 'bob', from => '192.0.2.5' }, result => 'denied' },
    ] );
  my $g = $G->grade( $case, { calls => [] } );
  is_deeply( [ map { $_->{passed} } @{ $g->{rules} } ], [ 0, 1, 0, 1 ], 'initial state: packet drop, boot accept, anna denied, bob denied' );
  is( $g->{rules}[0]{reason}, 'drop (port 8080)', 'packet: the verdict and where it came from' );
  is( $g->{rules}[1]{reason}, 'after reboot: accept (saved port 8080)', 'boot goes to the simulator' );
  like( $g->{rules}[2]{reason}, qr/\Adenied: anna\@g1: Permission denied \/ refused anna\z/, 'login: client and log lines' );
  my $end = { g1 => { type => 'gate', open => [8080], saved => [8080], users => { anna => 1 } } };
  $g = $G->grade( $case, { state => $end, calls => [] } );
  is( $g->{status}, 'passed', 'end state: every rule met' );
  is( $g->{rules}[2]{reason}, 'allowed: Welcome to g1', '... login allowed' );

  my $miss = Langertha::Holmgang::Case->new( id => 'c', simulators => $sims, state => { g1 => { type => 'gate' }, k => { type => 'kueche' } },
    rules => [ { title => 'x', packet => { %$pkt, host => 'g9' }, verdict => 'drop' },
      { title => 'y', login => { host => 'k', user => 'a', from => '192.0.2.5' }, result => 'denied' } ] );
  $g = $G->grade( $miss, { calls => [] } );
  is( $g->{rules}[0]{reason}, 'device g9 missing', 'packet: device missing' );
  ok( !$g->{rules}[1]{passed}, 'login: a simulator that cannot answer misses the rule' );
  like( $g->{rules}[1]{reason}, qr/\Ano answer: .*cannot answer a login rule/, '... with the reason' );
}

# packet on the built-in linux simulator, through the registry
{
  my $fw = { type => 'linux', nft => { 'inet filter' => { chains => { input => { type => 'filter', hook => 'input',
    priority => '0', policy => 'drop', rules => [ 'iifname "eth1" tcp dport 22 accept' ] } } } } };
  my $case = Langertha::Holmgang::Case->new( id => 'c', state => { fw => $fw },
    rules => [ { title => 'ssh from the LAN', packet => { host => 'fw', hook => 'input', iif => 'eth1', saddr => '10.1.0.7',
      daddr => '10.1.0.1', proto => 'tcp', dport => '22' }, verdict => 'accept' } ] );
  my $g = Langertha::Holmgang::Grader->new->grade( $case, { calls => [] } );
  ok( $g->{rules}[0]{passed}, 'linux: accept by the nft rule (dport as text)' ) or diag $g->{rules}[0]{reason};
}

# the plugin through the loader: device type, run_command, grading
my $HEAD = <<'Y';
format: 2
id: __ID__
version: 1
title: Gate
tools:
  - name: run_command
    description: Console.
    simulator: run_command
    parameters: { type: object, required: [host, command], properties: { host: { type: string }, command: { type: string } } }
Y
my $CASE = <<'Y';
id: c1
title: Open the web port
messages: [ { role: user, content: "Open 8080 on g1." } ]
state: { g1: { type: gate, open: [] } }
rules:
  - title: web port open
    packet: { host: g1, hook: input, saddr: 192.0.2.1, daddr: 192.0.2.2, proto: tcp, dport: 8080 }
    verdict: accept
  - { title: nothing else, unchanged_except: [ g1.open ] }
solution: [ { tool: run_command, args: { host: g1, command: open 8080 } } ]
alternatives: [ { title: twice, calls: [ { tool: run_command, args: { host: g1, command: open 8080 } }, { tool: run_command, args: { host: g1, command: open 8080 } } ] } ]
wrong_solutions: [ { title: other port, calls: [ { tool: run_command, args: { host: g1, command: open 8081 } } ] } ]
Y
my $L = Langertha::Holmgang::Loader->new( simulators => $sims );
{
  my ( $s, $err ) = try_load( $CASE, head => $HEAD, loader => $L );
  ok( $s, 'a suite on a plugin device type loads and lints' ) or diag $err;
  refused( $CASE, qr/state\.g1\.type/, qr/device type/, 'without the registration the type is unknown', head => $HEAD );
}
refused( $CASE =~ s/verdict: accept/verdict: allow/r, qr/rules\[0\]\.verdict\z/, qr/accept or drop/, 'packet: verdict', head => $HEAD, loader => $L );
refused( $CASE =~ s/hook: input/hook: inbound/r, qr/rules\[0\]\.packet\.hook\z/, qr/prerouting/, 'packet: hook', head => $HEAD, loader => $L );
refused( $CASE =~ s/daddr: 192\.0\.2\.2/daddr: 2001:db8::2/r, qr/rules\[0\]\.packet\.daddr\z/, qr/same family/, 'packet: address family', head => $HEAD, loader => $L );
refused( $CASE =~ s/, dport: 8080 \}/ }/r, qr/rules\[0\]\.packet\.dport\z/, qr/missing/, 'packet: dport for tcp', head => $HEAD, loader => $L );
refused( $CASE =~ s/proto: tcp, dport: 8080/proto: icmp, dport: 8080/r, qr/rules\[0\]\.packet\.dport\z/, qr/only with tcp\/udp/, 'packet: no port for icmp', head => $HEAD, loader => $L );
refused( $CASE =~ s/    verdict: accept\n/    verdict: accept\n    boot: [ x ]\n/r, qr/rules\[0\]\.boot\z/, qr/absolute path/, 'packet: boot', head => $HEAD, loader => $L );
{
  my $login = $CASE =~ s/  - title: web port open\n.*\n    verdict: accept\n/  - title: anna in\n    login: { host: g1, user: anna, from: 192.0.2.5 }\n    result: allowed\n/r;
  refused( $login, qr/rules\[0\]\.login\.auth\z/, qr/publickey \(with key\) or password/, 'login: auth needs a key or password', head => $HEAD, loader => $L );
  refused( $login =~ s/from: 192\.0\.2\.5 \}/from: 192.0.2.5, auth: password, port: 70000 }/r, qr/rules\[0\]\.login\.port\z/, qr/1-65535/, 'login: port', head => $HEAD, loader => $L );
  refused( $login =~ s/from: 192\.0\.2\.5 \}/from: 192.0.2.5, auth: password }/r =~ s/result: allowed/result: maybe/r,
    qr/rules\[0\]\.result\z/, qr/allowed or denied/, 'login: result', head => $HEAD, loader => $L );
  refused( $login =~ s/user: anna, /user: anna, shell: sh, /r, qr/rules\[0\]\.login\.shell\z/, qr/unknown key/, 'login: unknown key', head => $HEAD, loader => $L );
}

done_testing;
