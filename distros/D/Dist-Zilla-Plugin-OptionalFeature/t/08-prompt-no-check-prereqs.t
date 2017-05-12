use strict;
use warnings;

use Path::Tiny;
my $code = path('t', '06-prompt.t')->slurp_utf8;

$code =~ s/(^\s+)-prompt => 1,\n\K/$1-check_prereqs => 0,\n/mg;
$code =~ s/check_prereqs => \K1,/0,/mg;
$code =~ s/has_module\(.+\n    \|\| //g;
$code =~ s/with -default = 1\K/ and -check_prereqs = 0/g;

eval $code;
die $@ if $@;
