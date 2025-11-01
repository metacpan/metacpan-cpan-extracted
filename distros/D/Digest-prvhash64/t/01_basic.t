use strict;
use warnings;
use Test::More;
use Digest::prvhash64 qw(prvhash64 prvhash64_64m prvhash64_hex);

my $msg = "hello world";

# Test prvhash64 length and basic behavior
my $h8  = prvhash64($msg, 8);
ok(defined $h8 && length($h8) == 8, 'prvhash64 returns 8 bytes');

my $h32 = prvhash64($msg, 32);
ok(defined $h32 && length($h32) == 32, 'prvhash64 returns 32 bytes');

# Test multiples of 8 required
eval { prvhash64($msg, 7) };
like($@, qr/multiple of 8/, 'rejects non-multiple-of-8 hash_len');

# Determinism with same seed
my $s1 = prvhash64($msg, 16, 123);
my $s2 = prvhash64($msg, 16, 123);
my $s3 = prvhash64($msg, 16, 456);

ok($s1 eq $s2, 'same seed produces same result');
ok($s1 ne $s3, 'different seed produces different result');

# Test minimal 64-bit variant
my $m1 = prvhash64_64m($msg);
ok(defined $m1, 'prvhash64_64m returns a value');

my $m2 = prvhash64_64m($msg, 123);
my $m3 = prvhash64_64m($msg, 123);
my $m4 = prvhash64_64m($msg, 456);

ok($m2 == $m3, '64m same seed deterministic');
ok($m2 != $m4, '64m different seeds differ');

# Changing message changes hash (very basic sanity)
my $h_other = prvhash64("hello world!", 8);
ok($h8 ne $h_other, 'different message yields different hash');

my $seed = 16129539322125092974;
is(prvhash64_64m('123'  , $seed), 17529027730393874021);
is(prvhash64_64m('456'  , $seed), 13622049536041103705);
is(prvhash64_64m(''     , $seed), 3306698058279260960);
is(prvhash64_64m('Hello', $seed), 11086547417568924555);

done_testing();
