use strict;
use warnings;

use Test::More;

my @exes = glob "bin/*";

plan tests => 1 + @exes;
foreach my $exe (@exes) {
	is system("$^X -c $exe"), 0, $exe;
}
ok 1;

