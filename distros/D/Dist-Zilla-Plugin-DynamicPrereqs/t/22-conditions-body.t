use strict;
use warnings;

use Path::Tiny;
my $code = path('t', '15-conditions-raw.t')->slurp_utf8;

$code =~ s/-raw/-body/g;

eval $code;
die $@ if $@;
