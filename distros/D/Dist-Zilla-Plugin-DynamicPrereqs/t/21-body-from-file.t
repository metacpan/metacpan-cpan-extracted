use strict;
use warnings;

use Path::Tiny;
my $code = path('t', '10-raw-from-file.t')->slurp_utf8;

$code =~ s/-raw/-body/g;

eval $code;
die $@ if $@;
