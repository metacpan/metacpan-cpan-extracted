use strict;

use Test::More tests => 6;

use Log::Defer;

use Time::HiRes qw/time/;


my $log = Log::Defer->new({ cb => sub {
  my $msg = shift;

  is_deeply([ map { $_->[2] } @{ $msg->{logs} } ], [qw/D A B C E F/]);

  is($msg->{timers}->[0]->[0], 'junk');
  is($msg->{timers}->[1]->[0], 'blah');
  ok($msg->{timers}->[1]->[1] > 1.05, 'timer offset ok');

  is($msg->{data}->{hello}, 2, 'hello overwritten');
  is($msg->{data}->{world}, 1, 'world preserved');
}});



$log->data->{hello} = 1;
$log->data->{world} = 1;


$log->info('A');
$log->info('B');

select undef,undef,undef,.1;
my $start = time();

$log->timer('junk');

$log->merge({
  start => $start,
  logs => [
            [ 100 , 30, 'E' ],
            [ -10 , 30, 'D' ],
            [ 20, 30, 'C' ],
          ],
  timers => [
    [ 'blah', 1, 2, ],
  ],
  data => {
    hello => 2,
  },
});

$log->info('F');


undef $log;
