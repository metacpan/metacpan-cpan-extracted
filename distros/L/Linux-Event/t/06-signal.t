use v5.36;
use strict;
use warnings;

use Test::More;

for my $m (qw(Linux::Epoll Linux::Event::Clock Linux::Event::Timer Linux::FD::Signal POSIX)) {
  eval "require $m; 1" or plan skip_all => "$m not available: $@";
}

use Linux::Event::Loop;

my $loop = Linux::Event::Loop->new( model => 'reactor', backend => 'epoll' );

my @seen;

my $sub_usr1 = $loop->signal('USR1', sub ($loop, $sig, $count, $data=undef) {
  push @seen, [ 'USR1', $sig, $count, $data ];
}, data => 'A');

my $sub_usr2 = $loop->signal('USR2', sub ($loop, $sig, $count, $data=undef) {
  push @seen, [ 'USR2', $sig, $count, $data ];
}, data => 'B');

ok($sub_usr1 && $sub_usr1->can('cancel'), 'signal() returns a subscription handle');
ok($sub_usr2 && $sub_usr2->can('cancel'), 'signal() returns a subscription handle');

kill POSIX::SIGUSR1(), $$;
kill POSIX::SIGUSR2(), $$;

# Drive the loop until both callbacks have fired (or timeout).
my $t0 = time;
while (@seen < 2) {
  $loop->run_once(0.05);
  last if time - $t0 > 2;
}

is(scalar(@seen), 2, 'received both USR1 and USR2');
is($seen[0][3], 'A', 'USR1 data delivered');
is($seen[1][3], 'B', 'USR2 data delivered');
cmp_ok($seen[0][2], '>=', 1, 'USR1 count >= 1');
cmp_ok($seen[1][2], '>=', 1, 'USR2 count >= 1');


# Replacement semantics: last registration wins.
@seen = ();

$loop->signal('USR1', sub ($loop, $sig, $count, $data=undef) {
  push @seen, [ 'NEW', $data ];
}, data => 'NEW');

kill POSIX::SIGUSR1(), $$;

$t0 = time;
while (!@seen) {
  $loop->run_once(0.05);
  last if time - $t0 > 2;
}

is_deeply(\@seen, [ ['NEW', 'NEW'] ], 'replacement semantics per signal');


# Cancellation: idempotent, and prevents future callbacks.
@seen = ();
ok($sub_usr2->cancel, 'cancel returns true the first time');
ok(!$sub_usr2->cancel, 'cancel returns false after already canceled');

kill POSIX::SIGUSR2(), $$;

$t0 = time;
while (time - $t0 < 0.3) {
  $loop->run_once(0.05);
}

is_deeply(\@seen, [], 'canceled subscription does not fire');

done_testing;
