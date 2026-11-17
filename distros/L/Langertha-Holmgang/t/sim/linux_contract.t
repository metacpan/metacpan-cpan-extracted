#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Test::Fatal qw( exception );

use Holmgang::TestSim qw( without_part );
use Holmgang::TestSim ();
use Langertha::Holmgang::Simulators;

# Sim::Linux behind the plugin contract: the role, the result list with the
# exit status, the rule methods, and a part that is not installed. States
# written for this test.

my $sims = Langertha::Holmgang::Simulators->new;
my $sim  = $sims->simulator('linux');
isa_ok $sim, 'Langertha::Holmgang::Sim::Linux';
ok $sim->does('Langertha::Holmgang::Role::Simulator'), 'composes the simulator role';
is $sim->device_type, 'linux', 'device_type';

my $state = { box => { type => 'linux', hostname => 'box', files => { '/etc/motd' => "hallo\n" } } };

subtest 'result list and exit status' => sub {
  is_deeply [ $sims->run_command( $state, 'box', 'cat /etc/motd' ) ], [ 'hallo', 1, undef ], 'success: output, 1, no gap';
  is_deeply [ $sims->run_command( $state, 'box', 'false' ) ], [ '', 0, undef ], 'failure with status 1: no exit value';
  is_deeply [ $sims->run_command( $state, 'box', 'exit 3' ) ], [ '', 0, undef, 3 ], 'exit 3';
  is_deeply [ $sims->run_command( $state, 'box', q{bash -c 'exit 4'} ) ], [ '', 0, undef, 4 ], 'status of a sub-shell';
  is_deeply [ $sims->run_command( $state, 'box', 'ifconfig' ) ], [ 'bash: ifconfig: command not found', 0, undef ],
    'not on the system: the real error, no gap';
};

subtest 'write_file' => sub {
  my ( $o, $ok ) = $sims->write_file( $state, 'box', '/etc/motd', "neu\n" );
  ok $ok, 'written';
  is( ( $sims->run_command( $state, 'box', 'cat /etc/motd' ) )[0], 'neu', 'visible to the next read' );
};

subtest 'a part that is not installed' => sub {
  # Redis is hidden from the loader for this subtest: the contract path is always tested
  my $s = { db => { type => 'linux', redis => { service => 'redis-server' }, files => { '/etc/motd' => "hallo\n" } } };
  my $before = Holmgang::TestSim::clone($s);
  without_part( Redis => sub {
    like exception { $sims->prepare($s) }, qr/\ALangertha::Holmgang::Sim::Linux::Redis is not installed/, 'prepare dies';
    is_deeply [ $sims->run_command( $s, 'db', 'redis-cli ping' ) ],
      [ '', 0, 'Langertha::Holmgang::Sim::Linux::Redis is not installed' ], 'neutral output, failed, reported as a gap';
    is_deeply [ $sims->run_command( $s, 'db', 'cat /etc/motd' ) ], [ 'hallo', 1, undef ], 'a call that needs no part is not affected';
  } );
  is_deeply $s, $before, 'state untouched';
  ok !exception { $sims->prepare( Holmgang::TestSim::clone($s) ) }, 'with the part back, prepare works';
};

subtest 'packet_verdict' => sub {
  my $dev = { type => 'linux', nft => { 'inet filter' => { chains => { input => { type => 'filter', hook => 'input',
    priority => '0', policy => 'drop', rules => ['tcp dport 22 accept'] } } } } };
  my %pkt = ( hook => 'input', saddr => '192.0.2.1', daddr => '192.0.2.2', proto => 'tcp' );
  is( ( $sims->packet_verdict( $dev, { %pkt, dport => 22 } ) )[0], 'accept', 'accept' );
  is( ( $sims->packet_verdict( $dev, { %pkt, dport => 80 } ) )[0], 'drop', 'policy drop' );
  is( ( $sims->packet_verdict( $dev, { %pkt, dport => 22 }, '/etc/nftables.conf' ) )[0], 'accept',
    'after boot without its own file: the running ruleset is the file' );
  my ( $v, $why ) = $sims->packet_verdict( $dev, { %pkt, dport => 22 }, '/etc/nft-boot.conf' );
  ok !defined $v, 'after boot from a missing file: no verdict';
  like $why, qr{/etc/nft-boot\.conf}, '... names the file';
};

subtest 'login_check' => sub {
  without_part( SshAccess => sub {
    like exception { $sims->login_check( $state->{box}, { user => 'root', from => '192.0.2.9' }, 'box' ) },
      qr/SshAccess is not installed/, 'dies while SshAccess is missing';
  } );
};

subtest 'class method run, as parts call it' => sub {
  my $dev = { type => 'linux', files => { '/x' => "1\n" } };
  my ( $o, $ok ) = Langertha::Holmgang::Sim::Linux->run( $dev, 'cat /x', { host => 'p', state => {} } );
  is_deeply [ $o, $ok ], [ '1', 1 ], 'works on the class';
};

done_testing;
