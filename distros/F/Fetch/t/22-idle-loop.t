#!perl
use 5.008003;
use strict;
use warnings;
use Test::More tests => 4;
use Fetch;

# A loop with no fd interest and no timer can never resolve anything: the
# backend would block in the kernel with no deadline, which is not a stall a
# Perl-level alarm can interrupt, so the process just wedges. Awaiting a future
# that belongs to some other loop is how you get there, so say so instead.

my $idle = Fetch::Loop::Standalone->new;
my $f    = Fetch::Future->new;

my $ok = eval { $idle->run_until($f); 1 };
ok(!$ok, 'run_until on an empty loop does not block forever');
like($@, qr/no watchers/, 'and says why');

# A timer is a wake-up, so the same loop is legitimately runnable.
{
    my $g = Fetch::Future->new;
    $idle->timer(0.01, sub { $g->done(42) });
    my $ok = eval { $idle->run_until($g); 1 };
    ok($ok, 'a pending timer keeps the loop runnable');
    is(scalar $g->get, 42, 'and the future resolves');
}
