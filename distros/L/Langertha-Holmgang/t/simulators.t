#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Langertha::Holmgang::Simulators;

# Invented simulators for the contract, not a port of anything.
{
  package Test::Sim::Lamp;
  use Moose;
  with 'Langertha::Holmgang::Role::Simulator';
  sub device_type { 'lamp' }
  sub run_command {
    my ( $self, $dev, $command, $ctx ) = @_;
    return ( $ctx->{host}.' is '.( $dev->{on} ? 'on' : 'off' ), 1 ) if $command eq 'status';
    if ( $command eq 'toggle' ) { $dev->{on} = $dev->{on} ? 0 : 1; return ( '', 1 ) }
    return ( '', 0, 'lamp: dim is not modelled' ) if $command eq 'dim';
    return ( 'lamp: broken', 0, undef, 3 ) if $command eq 'fuse';
    return ( 'lamp: '.$command.': command not found', 0 );
  }
  sub prepare { my ( $self, $dev ) = @_; $dev->{on} //= 0; return }
  sub packet_verdict { my ( $self, $dev, $pkt, $boot ) = @_; return ( $pkt->{dport} == 80 ? 'accept' : 'drop', $boot ? 'boot' : 'live' ) }
  __PACKAGE__->meta->make_immutable;
}
{
  package Test::Sim::Shelf;
  use Moose;
  with 'Langertha::Holmgang::Role::AnswerWorld';
  sub device_type { 'shelf' }
  sub tools { return { put => [qw( item )], list => [] } }
  sub tool {
    my ( $self, $w, $name, $args ) = @_;
    if ( $name eq 'put' ) { push @{ $w->{items} }, $args->{item}; return ( 'ok', 1 ) }
    return ( join( ', ', @{ $w->{items} || [] } ), 1 );
  }
  __PACKAGE__->meta->make_immutable;
}
{
  package Test::Sim::NotOne;
  use Moose;
  sub device_type { 'nothing' }
}

my $sims = Langertha::Holmgang::Simulators->new( register_classes => ['Test::Sim::Lamp'] );
$sims->register('Test::Sim::Shelf');

like exception { $sims->register('Test::Sim::NotOne') }, qr/composes neither/, 'a class without a role is refused';
like exception { $sims->register('Test::Sim::Does::Not::Exist') }, qr/Can't locate/, 'a class that does not load is refused';

ok( ( grep { $_ eq 'lamp' } $sims->types ), 'registered type is listed' );
ok( ( grep { $_ eq 'linux' } $sims->types ), 'linux is built in' );
ok !$sims->simulator('nope'), 'unknown type: no simulator';

my $state = {
  hall  => { type => 'lamp' },
  attic => { type => 'mystery' },
  store => { type => 'shelf', items => ['box'] },
};
$sims->prepare($state);
is $state->{hall}{on}, 0, 'prepare filled in the boot value';

is_deeply [ $sims->run_command( $state, 'hall', 'status' ) ], [ 'hall is off', 1 ], 'ctx carries the host';
is_deeply [ $sims->run_command( $state, 'hall', 'toggle' ) ], [ '', 1 ], 'a change';
is_deeply [ $sims->run_command( $state, 'hall', 'status' ) ], [ 'hall is on', 1 ], '... is visible to the next read';
is_deeply [ $sims->run_command( $state, 'hall', 'dim' ) ], [ '', 0, 'lamp: dim is not modelled' ], 'sim_gap passes through';
is_deeply [ $sims->run_command( $state, 'hall', 'fuse' ) ], [ 'lamp: broken', 0, undef, 3 ], 'exit status passes through';
is_deeply [ $sims->run_command( $state, 'cellar', 'ls' ) ],
  [ 'ssh: Could not resolve hostname cellar: Name or service not known', 0 ], 'unknown host';
is_deeply [ $sims->run_command( $state, 'attic', 'ls' ) ], [ 'ssh: connect to host attic port 22: Connection refused', 0 ], 'type without simulator';
is_deeply [ $sims->run_command( $state, 'store', 'ls' ) ], [ 'ssh: connect to host store port 22: Connection refused', 0 ], 'answer world has no shell';
my ( $o, $ok ) = $sims->write_file( $state, 'hall', '/etc/x', 'y' );
ok !$ok, 'write_file refused without write_file';
like $o, qr/\Ascp: hall: /, '... like scp';

is_deeply $sims->world_tools('shelf'), { put => ['item'], list => [] }, 'world tools';
ok !defined $sims->world_tools('lamp'), 'a device simulator has no world tools';
is_deeply [ $sims->tool_call( $state, shelf => put => { item => 'jar' } ) ], [ 'ok', 1 ], 'tool call';
is_deeply [ $sims->tool_call( $state, shelf => list => {} ) ], [ 'box, jar', 1 ], '... changed the world';
is_deeply [ $sims->tool_call( $state, garden => list => {} ) ], [ 'Fehler: diese Umgebung hat keine garden.', 0 ], 'world missing';

is_deeply [ $sims->packet_verdict( $state->{hall}, { dport => 80 } ) ], [ 'accept', 'live' ], 'packet verdict';
is_deeply [ $sims->packet_verdict( $state->{hall}, { dport => 22 }, 1 ) ], [ 'drop', 'boot' ], '... after boot';
like exception { $sims->login_check( $state->{hall}, {}, 'hall' ) }, qr/cannot answer a login rule/, 'login without login_check croaks';

{
  package Test::Sim::Linux2;
  use Moose;
  with 'Langertha::Holmgang::Role::Simulator';
  sub device_type { 'linux' }
  sub run_command { return ( 'mine', 1 ) }
}
my $own = Langertha::Holmgang::Simulators->new;
$own->register('Test::Sim::Linux2');
is_deeply [ $own->run_command( { a => { type => 'linux' } }, 'a', 'x' ) ], [ 'mine', 1 ], 'registration replaces a built-in';
ok !( grep { $_ eq 'lamp' } $own->types ), 'registrations are per registry';

done_testing;
