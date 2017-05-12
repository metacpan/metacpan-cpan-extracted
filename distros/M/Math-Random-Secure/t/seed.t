#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::SharedFork;
use Math::Random::Secure qw(srand irand);
use Math::Random::Secure::RNG;

my $seed = srand();
cmp_ok(length($seed), '==', 64, 'seed is the right size');

my @sequence_one = map { irand() } (1..100);
srand($seed);
my @sequence_two = map { irand() } (1..100);
is_deeply(\@sequence_one, \@sequence_two,
  'Same seed generates the same sequence');

srand();
my @sequence_different = map { irand() } (1..100);
my $string1 = join(' ', @sequence_one);
my $string2 = join(' ', @sequence_different);
isnt($string2, $string1, 'Different seeds generate different sequences');

warning_like
  { Math::Random::Secure::RNG->new(seed_size => 4) }
  qr/Setting seed_size to less than/,
  "Using too-small of a seed size throws a warning";

my $int32 = 2**31;
warning_like
  { srand($int32) }
  qr/RNG seeded with a 32-bit integer/,
  "srand: Using a 32-bit integer throws a warning";
warning_like { Math::Random::Secure::RNG->new(seed => $int32) }
  qr/RNG seeded with a 32-bit integer/,
  "RNG->new: Using a 32-bit integer throws a warning";

my $short_seed = "abcde";
warning_like { srand($short_seed) } qr/Your seed is less than/,
  "srand: Short seeds throw a warning";
warning_like { Math::Random::Secure::RNG->new(seed => $short_seed) }
  qr/Your seed is less than/,
  "RNG->new: Short seeds throw a warning";

unless (Math::Random::Secure::RNG::ON_WINDOWS()) {
  srand($seed);
  my $first = irand();
  srand($seed);
  my $second = irand();
  is($first, $second, 'Same seed (duh)');
  srand($seed);
  my $pid = fork;
  die "Failed to fork: $!" if $pid == -1;

  if ($pid == 0) {
    my $third = irand();
    isnt($first, $third, 'Seed gets rebuilt after fork');
    exit;
  } else {
    waitpid($pid, 0)
  }
}

done_testing();
