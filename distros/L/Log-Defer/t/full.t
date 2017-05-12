use strict;

use Test::More tests => 25;

use Log::Defer;
#use Data::Dumper;
#use JSON::XS;


my $triggered;

my $log = Log::Defer->new(sub {
  my $msg = shift;

  #print Dumper($msg) . "\n";
  #print JSON::XS->new->pretty(1)->encode($msg) . "\n";

  ## start/end time

  ok(exists $msg->{start}, 'start is there');
  ok(exists $msg->{end}, 'end is there');

  ## log messages

  is(@{$msg->{logs}}, 4, 'three log msgs');
  is($msg->{logs}->[0]->[1], 20);
  is($msg->{logs}->[0]->[2], 'QQQ W');
  is($msg->{logs}->[0]->[3], 'HELLO');
  is($msg->{logs}->[0]->[4], 888);
  is($msg->{logs}->[1]->[1], 40);
  is($msg->{logs}->[1]->[2], 'QQQ D');
  is($msg->{logs}->[2]->[1], 30);
  is($msg->{logs}->[2]->[2], 'QQQ I');
  is($msg->{logs}->[3]->[1], 10);
  is($msg->{logs}->[3]->[2], 'QQQ E');

  ## timers

  ok(exists $msg->{timers});
  is(@{$msg->{timers}}, 3, 'three timers');

  is(@{$msg->{timers}->[0]}, 3);
  is(@{$msg->{timers}->[1]}, 3);
  is(@{$msg->{timers}->[2]}, 3);

  ok($msg->{timers}->[0]->[1] <= $msg->{timers}->[1]->[1]);
  ok($msg->{timers}->[1]->[1] <= $msg->{timers}->[1]->[1]);

  ok($msg->{timers}->[0]->[2] <= $msg->{timers}->[2]->[1]);
  ok($msg->{timers}->[2]->[2] <= $msg->{timers}->[1]->[2]);

  ## data

  ok($msg->{data}->{junkdata} == 123);

  $triggered = 1;
});


$log->warn('QQQ W', 'HELLO', 888);

$log->data->{junkdata} = 123;

my $timer = $log->timer('junktimer');
my $timer2 = $log->timer('junktimer2');

select undef,undef,undef,0.1;

undef $timer;

$log->debug('QQQ D');

my $timer3 = $log->timer('junktimer3');

select undef,undef,undef,0.1;

undef $timer3;

$log->info('QQQ I');
$log->error('QQQ E');

ok(!$triggered, "logging hasn't happened yet");
undef $log;
ok($triggered, "log happened");
