use strict;
use warnings;

use Test::More;
use Test::Vars;
use Test::Pod::Coverage::TrustMe qw(all_modules);

my @modules = all_modules();
plan tests => scalar @modules;

for my $file (@modules) {
  vars_ok($file,
    ignore_vars => ['$class'],
  );
}

done_testing;
