use strict;
use warnings;

use Test::More;

use IO::Uring;

my $ring = IO::Uring->new(32);

my %hash = %{ $ring->probe };
$_ += 0 for values %hash;
diag explain \%hash;

pass("This is just diagnostics");

done_testing(1);
