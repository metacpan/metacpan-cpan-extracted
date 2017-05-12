use strict; use warnings;
use Test::More tests => 1;
use Email::Address::List;
use Time::HiRes;

my $start = Time::HiRes::time();
my @addresses = Email::Address::List->parse("a" x 25);

# Realistic expected is ~0.0001s.  In the pathological case, however, it
# will take ~80s.  0.5s is thus unlikely to trip either false-positive
# of false-negative, being approximitely two orders of magnitude away
# from both.  We use actual elapsed time, rather than alarm(), for
# portability.
ok(Time::HiRes::time() - $start < 0.5,
   "Extracting from a long string should take finite time");
