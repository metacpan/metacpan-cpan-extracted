#!/usr/bin/env perl
use strict;
use warnings;
use v5.10;

use Hash::Util::Set::PP qw[];
use Hash::Util::Set::XS qw[];

use Benchmark qw[:hireswallclock];

sub rand_hash {
  my ($max_key) = @_;
  my %h;
  for my $k (0 .. $max_key - 1) {
    $h{$k} = 1 if rand() < 0.5;
  }
  return %h;
}

sub benchmark_operation {
  my ($name, $pp_sub, $xs_sub) = @_;
  say "\nComparing - $name:";
  Benchmark::cmpthese(-3, {
    'PP' => $pp_sub,
    'XS' => $xs_sub,
  });
}

for my $size (64, 256, 1024) {
  say "=" x 60;
  say "Testing with MAX_KEY = $size";
  say "=" x 60;

  my %x = rand_hash($size);
  my %y = rand_hash($size);

  say sprintf('Hash sizes: x=%d, y=%d', scalar keys %x, scalar keys %y);

  benchmark_operation('keys_union',
    sub { my @keys = Hash::Util::Set::PP::keys_union(%x, %y); },
    sub { my @keys = Hash::Util::Set::XS::keys_union(%x, %y); }
  );

  benchmark_operation('keys_intersection',
    sub { my @keys = Hash::Util::Set::PP::keys_intersection(%x, %y); },
    sub { my @keys = Hash::Util::Set::XS::keys_intersection(%x, %y); }
  );

  benchmark_operation('keys_difference',
    sub { my @keys = Hash::Util::Set::PP::keys_difference(%x, %y); },
    sub { my @keys = Hash::Util::Set::XS::keys_difference(%x, %y); }
  );

  benchmark_operation('keys_symmetric_difference',
    sub { my @keys = Hash::Util::Set::PP::keys_symmetric_difference(%x, %y); },
    sub { my @keys = Hash::Util::Set::XS::keys_symmetric_difference(%x, %y); }
  );

  benchmark_operation('keys_disjoint',
    sub { my $bool = Hash::Util::Set::PP::keys_disjoint(%x, %y); },
    sub { my $bool = Hash::Util::Set::XS::keys_disjoint(%x, %y); }
  );

  benchmark_operation('keys_equal',
    sub { my $bool = Hash::Util::Set::PP::keys_equal(%x, %y); },
    sub { my $bool = Hash::Util::Set::XS::keys_equal(%x, %y); }
  );

  benchmark_operation('keys_subset',
    sub { my $bool = Hash::Util::Set::PP::keys_subset(%x, %y); },
    sub { my $bool = Hash::Util::Set::XS::keys_subset(%x, %y); }
  );

  benchmark_operation('keys_proper_subset',
    sub { my $bool = Hash::Util::Set::PP::keys_proper_subset(%x, %y); },
    sub { my $bool = Hash::Util::Set::XS::keys_proper_subset(%x, %y); }
  );
}

say "=" x 60;
say "Testing keys_all/any/none operations";
say "=" x 60;

my %test_hash = map { $_ => 1 } 0..99;
my @existing_keys = (0, 10, 20, 30, 40);
my @mixed_keys = (0, 10, 999, 20, 888);
my @nonexistent_keys = (1000, 1001, 1002);

benchmark_operation('keys_all (all exist)',
  sub { my $bool = Hash::Util::Set::PP::keys_all(%test_hash, @existing_keys); },
  sub { my $bool = Hash::Util::Set::XS::keys_all(%test_hash, @existing_keys); }
);

benchmark_operation('keys_any (some exist)',
  sub { my $bool = Hash::Util::Set::PP::keys_any(%test_hash, @mixed_keys); },
  sub { my $bool = Hash::Util::Set::XS::keys_any(%test_hash, @mixed_keys); }
);

benchmark_operation('keys_none (none exist)',
  sub { my $bool = Hash::Util::Set::PP::keys_none(%test_hash, @nonexistent_keys); },
  sub { my $bool = Hash::Util::Set::XS::keys_none(%test_hash, @nonexistent_keys); }
);
