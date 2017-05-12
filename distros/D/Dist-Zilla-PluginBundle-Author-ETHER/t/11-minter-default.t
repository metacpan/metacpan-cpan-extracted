use strict;
use warnings;

# this is just like t/02-minter-default.t as the two profiles behave the same.

use Path::Tiny;
my $code = path('t', '02-minter-github.t')->slurp_utf8;

$code =~ s/'github'/'default'/g;

eval $code;
die $@ if $@;
