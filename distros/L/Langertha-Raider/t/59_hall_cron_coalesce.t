#!/usr/bin/env perl
# ABSTRACT: a coalescing cron job skips its occurrences while its previous run is still going

use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Test::Raider::Hall qw( fake_hall hall_events wait_until );
use Langertha::Raider::Hall;
use Langertha::Raider::Hall::Raider;

clear_engine_env();

sub types_since {
  my ( $events, $from, $prefix ) = @_;
  return [ map { $_->[0] } grep { index( $_->[0], $prefix ) == 0 } @$events[ $from .. $#$events ] ];
}

sub no_raiders { my ( $hall ) = @_; wait_until( $hall, sub { !%{ $hall->raiders } } ) }

subtest 'coalesce: an occurrence while the previous run is going is dropped' => sub {
  my ( $hall, $tmp ) = fake_hall();
  my $events = hall_events($hall);
  my $cron = $hall->cron_scheduler;
  $cron->add_job( id => 'nightly', cron => '0 3 * * *', name => 'bjorn', mission => 'hold', coalesce => 1 );

  $cron->_fire('nightly');
  is( scalar keys %{ $hall->raiders }, 1, 'first occurrence spawned a raider' );
  my $from = @$events;
  $cron->_fire('nightly');
  is( types_since( $events, $from, 'cron.' ), ['cron.coalesced'], 'second occurrence coalesced' );
  is( scalar keys %{ $hall->raiders }, 1, 'no second raider' );
  is( $hall->binding_queues, {}, 'nothing queued on the binding' );

  path( $ENV{FAKE_RELEASE} )->touch;
  ok( no_raiders($hall), 'first run ended' );

  $from = @$events;
  $cron->_fire('nightly');
  is( types_since( $events, $from, 'cron.' ), ['cron.fired'], 'next occurrence fires again' );
  ok( no_raiders($hall), 'and ends' );
  $cron->cancel_job('nightly');
};

subtest 'coalesce: an occurrence waiting for its slot counts as running' => sub {
  my ( $hall, $tmp ) = fake_hall();
  my $events = hall_events($hall);
  $hall->raiders->{busy} = Langertha::Raider::Hall::Raider->new(
    id => '1ivar-1', pid => 2**22 + 12345, slot_name => '1ivar', base_name => 'ivar',
    mission => 'm', log_path => $tmp->child('x.log') );
  my $cron = $hall->cron_scheduler;
  $cron->add_job( id => 'nightly', cron => '0 3 * * *', name => '1ivar', mission => 'ping', coalesce => 1 );

  $cron->_fire('nightly');
  is( scalar @{ $hall->singleton_queues->{'1ivar'} }, 1, 'first occurrence waits for the slot' );
  my $from = @$events;
  $cron->_fire('nightly');
  is( types_since( $events, $from, 'cron.' ), ['cron.coalesced'], 'second occurrence coalesced' );
  is( scalar @{ $hall->singleton_queues->{'1ivar'} }, 1, 'still one waiting' );
  $cron->cancel_job('nightly');
};

subtest 'without coalesce every occurrence runs, one after the other' => sub {
  my ( $hall, $tmp ) = fake_hall();
  my $events = hall_events($hall);
  my $cron = $hall->cron_scheduler;
  $cron->add_job( id => 'nightly', cron => '0 3 * * *', name => 'bjorn', mission => 'hold' );

  $cron->_fire('nightly');
  my $from = @$events;
  $cron->_fire('nightly');
  is( types_since( $events, $from, 'cron.' ), ['cron.fired'], 'second occurrence fired' );
  is( scalar @{ $hall->binding_queues->{'cron:nightly'} }, 1, 'and waits on the binding' );

  path( $ENV{FAKE_RELEASE} )->touch;
  ok( wait_until( $hall, sub {
    2 == grep { $_->[0] eq 'raider.done' } @$events
  } ), 'both ran' );
  $cron->cancel_job('nightly');
};

done_testing;
