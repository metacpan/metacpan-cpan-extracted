use strict;
use Test::More;

use_ok 'Hash::Unique';

my @names = qw(tanaka sato suzuki tobaru kamikawa miyaguni aizawa);
my @hashes = map {
 +{ 
    id => $_,
    name => $names[rand @names]
  }
} 1..100000;

my $count = Hash::Unique->get_unique_hash(\@hashes, "name");
my $expected = @names;

ok($count == $expected, "got `$count`, expected `$expected`");

done_testing;

