use v5.36;
use strict;
use warnings;
use Test::More;

use Linux::Event::Scheduler;

{
  package t::Clock;
  sub new ($class) { bless { now => 100 }, $class }
  sub now_ns ($self) { $self->{now} }
  sub deadline_in_ns ($self, $delta) { $self->{now} + $delta }
  sub set ($self, $now) { $self->{now} = $now; return }
}

my $clock = t::Clock->new;
my $sched = Linux::Event::Scheduler->new(clock => $clock);

my @fired;
my $b = $sched->at_ns(200, sub { push @fired, 'b' });
my $a = $sched->at_ns(150, sub { push @fired, 'a' });
my $c = $sched->after_ns(75, sub { push @fired, 'c' });

is($sched->next_deadline_ns, 150, 'next deadline is root');
ok($sched->cancel($b), 'cancel live timer');
ok(!$sched->cancel($b), 'cancel twice returns false');

$clock->set(174);
my @ready = $sched->pop_expired;
is(scalar @ready, 1, 'one expired timer');
is($ready[0][0], $a, 'expired id is correct');
$ready[0][1]->();
is_deeply(\@fired, ['a'], 'callback preserved');

is($sched->next_deadline_ns, 175, 'cancelled root skipped and next live timer found');

$clock->set(200);
@ready = $sched->pop_expired;
is(scalar @ready, 1, 'cancelled timer skipped');
is($ready[0][0], $c, 'remaining timer expired');
$ready[0][1]->();
is_deeply(\@fired, [qw(a c)], 'remaining callback fired');

is($sched->next_deadline_ns, undef, 'no remaining deadline');

my $bad = eval { $sched->at_ns(1, 'not a callback'); 1 };
ok(!$bad, 'non-coderef rejected');

my $bad_new = eval { Linux::Event::Scheduler->new; 1 };
ok(!$bad_new, 'clock required');

done_testing;
