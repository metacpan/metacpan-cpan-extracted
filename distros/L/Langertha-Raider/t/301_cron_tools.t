#!/usr/bin/env perl
# ABSTRACT: The session cron jobs: cron_create, cron_delete, cron_list on the task registry, with a clock the test moves (ADR 0031, k169)
use strict;
use warnings;
use Test2::V0;
use POSIX ();
use IO::Async::Loop;
use Langertha::Raider::CronTools;
use Langertha::Raider::Tasks;

$ENV{TZ} = 'UTC';
POSIX::tzset();

sub at { my ( $y, $m, $d, $H, $M, $S ) = @_; POSIX::mktime( $S // 0, $M, $H, $d, $m - 1, $y - 1900, -1 ) }

my $now;
my $loop = IO::Async::Loop->new;

sub scheduler {
  my ( %o ) = @_;
  $now = at( 2026, 10, 20, 10, 3, 0 );
  my $tasks = Langertha::Raider::Tasks->new( loop => $loop );
  my $cron  = Langertha::Raider::CronTools->new(
    loop => $loop, tasks => $tasks, clock => sub { $now }, timer => 0, %o,
  );
  return ( $cron, $tasks );
}

subtest 'the tools are the Claude Code ones' => sub {
  my ( $cron ) = scheduler();
  my %tool = map { $_->name => $_ } @{ $cron->server->tools };
  is( [ sort keys %tool ], [qw( cron_create cron_delete cron_list )], 'three tools' );
  my $schema = $tool{cron_create}->input_schema;
  is( [ sort keys %{ $schema->{properties} } ], [qw( cron durable prompt recurring )], 'cron, prompt, recurring, durable' );
  is( $schema->{required}, [qw( cron prompt )], 'cron and prompt are required' );
  like( $tool{cron_create}->description, qr/5-field cron.*local timezone/s, 'the text says local time' );
  is( $tool{cron_delete}->input_schema->{required}, ['id'], 'cron_delete takes an id' );
};

subtest 'create, list, delete' => sub {
  my ( $cron, $tasks ) = scheduler();
  my ( $text, $err ) = $cron->create({ cron => '7 * * * *', prompt => 'check the deploy' });
  ok( !$err, 'scheduled' );
  like( $text, qr/\AScheduled recurring job cron_1 \(7 \* \* \* \*\)\. Session-only .* Auto-expires after 7 days\. Use cron_delete to cancel sooner\.\z/,
    'the answer names the job, the session scope and the expiry' );
  ( $text, $err ) = $cron->create({ cron => '30 14 15 3 *', prompt => 'once', recurring => 0 });
  like( $text, qr/\AScheduled one-shot job cron_2 \(30 14 15 3 \*\)\. It fires once/, 'a one-shot' );

  my $entry = $tasks->get('cron_1');
  is( $entry->{kind}, 'cron', 'the job is an entry of the registry' );
  is( $entry->{status}, 'running', 'running' );
  ok( $entry->{fire_at} >= at( 2026, 10, 20, 10, 7 ), 'it never fires before its minute' );
  ok( $entry->{fire_at} <= at( 2026, 10, 20, 10, 7 ) + 1800, 'and at most 30 minutes after' );

  ( $text ) = $cron->list({});
  my @lines = split /\n/, $text;
  is( scalar @lines, 2, 'two lines' );
  like( $lines[0], qr/\Acron_1 - 7 \* \* \* \* \(recurring, next run 2026-10-20 \d\d:\d\d:\d\d\): check the deploy\z/, 'recurring line' );
  like( $lines[1], qr/\Acron_2 - 30 14 15 3 \* \(one-shot, next run 2027-03-15 14:\d\d:\d\d\): once\z/, 'one-shot line' );

  ( $text, $err ) = $cron->delete({ id => 'cron_1' });
  is( [ $text, $err ], [ 'Cancelled job cron_1.', 0 ], 'deleted' );
  is( $tasks->get('cron_1')->{status}, 'killed', 'the entry ends' );
  ( $text, $err ) = $cron->delete({ id => 'cron_1' });
  is( [ $text, $err ], [ 'No scheduled job with ID: cron_1', 1 ], 'a second delete is an error' );
  ( $text, $err ) = $cron->delete({ id => 'bash_1' });
  is( $err, 1, 'an ID of another kind is no job' );
  ( $text ) = $cron->list({});
  like( $text, qr/\Acron_2 /, 'one left' );
  $cron->delete({ id => 'cron_2' });
  is( [ $cron->list({}) ], [ 'No scheduled jobs.', 0 ], 'none left' );
};

subtest 'bad input' => sub {
  my ( $cron ) = scheduler( max_jobs => 2 );
  my ( $text, $err ) = $cron->create({ cron => '* * * *', prompt => 'x' });
  is( $err, 1, 'four fields' );
  like( $text, qr/\AInvalid cron expression "\* \* \* \*": expected five fields/, 'the reason is named' );
  ( $text, $err ) = $cron->create({ cron => '0 0 31 2 *', prompt => 'x' });
  like( $text, qr/does not match any date/, 'an impossible date' );
  ( $text, $err ) = $cron->create({ cron => '* * * * *', prompt => '  ' });
  like( $text, qr/\ANo prompt given/, 'no prompt' );
  ( $text, $err ) = $cron->create({ cron => '* * * * *' });
  is( $err, 1, 'no prompt at all' );
  $cron->create({ cron => '1 * * * *', prompt => 'a' });
  $cron->create({ cron => '2 * * * *', prompt => 'b' });
  ( $text, $err ) = $cron->create({ cron => '3 * * * *', prompt => 'c' });
  is( [ $text, $err ], [ 'Too many scheduled jobs (2). Cancel one with cron_delete first.', 1 ], 'the limit' );
};

subtest 'a due job posts its prompt for the surface, once' => sub {
  my ( $cron, $tasks ) = scheduler();
  $cron->create({ cron => '*/5 * * * *', prompt => 'poll the queue' });
  my $job = $tasks->get('cron_1');
  is( $job->{fire_at}, at( 2026, 10, 20, 10, 5 ) - 15, 'every five minutes: 15 seconds sooner than the minute' );

  $now = $job->{fire_at} - 1;
  is( [ $cron->tick ], [], 'not yet' );
  is( $tasks->pending('cron'), 0, 'nothing waits' );

  $now = $job->{fire_at};
  is( [ $cron->tick ], ['cron_1'], 'due' );
  my @items = $tasks->take('cron');
  is( scalar @items, 1, 'one prompt waits' );
  is( $items[0]{text}, 'poll the queue', 'its text is the prompt' );
  is( $items[0]{id}, 'cron_1', 'it names the job' );
  ok( $items[0]{scheduled}, 'it is marked as scheduled' );
  is( $tasks->pending('main'), 0, 'main, where notifications go, is untouched' );
  is( $job->{fires}, 1, 'counted' );
  is( $job->{fire_at}, at( 2026, 10, 20, 10, 10 ) - 15, 'the next run is five minutes on' );

  # busy: three runs pass, nobody takes the prompt
  $now = at( 2026, 10, 20, 10, 40 );
  $cron->tick;
  $now = at( 2026, 10, 20, 10, 45 );
  $cron->tick;
  $now = at( 2026, 10, 20, 10, 50 );
  $cron->tick;
  is( $tasks->pending('cron'), 1, 'a prompt that waits is not queued again' );
  $tasks->take('cron');

  # no catch-up: the clock jumps an hour
  $now = at( 2026, 10, 20, 12, 0 );
  is( [ $cron->tick ], ['cron_1'], 'one fire' );
  is( $tasks->pending('cron'), 1, 'not twelve' );
  ok( $job->{fire_at} > $now, 'the next run is in the future' );
  is( $job->{fire_at}, at( 2026, 10, 20, 12, 5 ) - 15, 'counted from now' );
};

subtest 'a one-shot fires once and is gone' => sub {
  my ( $cron, $tasks ) = scheduler();
  $cron->create({ cron => '3 11 * * *', prompt => 'remind me', recurring => 0 });
  my $job = $tasks->get('cron_1');
  $now = $job->{fire_at};
  is( [ $cron->tick ], ['cron_1'], 'fired' );
  is( $job->{status}, 'completed', 'its entry is complete' );
  is( [ $cron->list({}) ], [ 'No scheduled jobs.', 0 ], 'and gone from the list' );
  $now += 86400 * 2;
  is( [ $cron->tick ], [], 'it does not come back' );
  is( ( $tasks->take('cron') )[0]{text}, 'remind me', 'its prompt was queued' );
};

subtest 'a recurring job expires after seven days with one last fire' => sub {
  my ( $cron, $tasks ) = scheduler();
  $cron->create({ cron => '0 9 * * *', prompt => 'daily' });
  my $job = $tasks->get('cron_1');
  my $start = $now;
  my $fired = 0;
  while ( $now < $start + 7 * 86400 + 86400 * 2 && $job->{status} eq 'running' ) {
    $now = $job->{fire_at};
    $fired++ if $cron->tick;
    $tasks->take('cron');
  }
  is( $job->{status}, 'completed', 'the job deleted itself' );
  ok( $now >= $start + 7 * 86400, 'not before seven days' );
  ok( $now <= $start + 8 * 86400 + 1800, 'and with the first fire past them' );
  is( $fired, 8, 'seven daily fires and the final one' );
};

subtest 'the registry stops jobs; the timer follows the jobs' => sub {
  my ( $cron, $tasks ) = scheduler( timer => 1 );
  ok( !$cron->_timer, 'no timer without jobs' );
  $cron->create({ cron => '1 * * * *', prompt => 'a' });
  ok( $cron->_timer && $cron->_timer->is_running, 'a timer runs on the loop' );
  ok( $cron->_timer->loop == $loop, 'the application loop' );
  $tasks->stop('cron_1');
  is( $tasks->get('cron_1')->{status}, 'killed', 'stopping the entry deletes the job' );
  ok( !$cron->_timer, 'the last job takes the timer with it' );
  $cron->create({ cron => '2 * * * *', prompt => 'b' });
  $cron->create({ cron => '3 * * * *', prompt => 'c' });
  $cron->stop_all;
  is( scalar( () = $cron->jobs ), 0, 'stop_all deletes all' );
  ok( !$cron->_timer, 'and the timer' );
};

subtest 'the timer ticks on the loop' => sub {
  my ( $cron, $tasks ) = scheduler( timer => 1, tick_interval => 0.02 );
  $cron->create({ cron => '* * * * *', prompt => 'every minute' });
  $now = $tasks->get('cron_1')->{fire_at};
  $loop->await( $tasks->wait_f('cron') );
  is( $tasks->pending('cron'), 1, 'the timer fired the job without a call to tick' );
  $cron->stop_all;
};

done_testing;
