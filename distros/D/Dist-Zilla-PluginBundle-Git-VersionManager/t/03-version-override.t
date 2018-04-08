use strict;
use warnings;

use Test::More;
use Path::Tiny;
my $code = path('t', '02-different-versions.t')->slurp_utf8;

$code =~ s/delete \$ENV\{V\};/\$ENV{V} = '1.23';/;
$code =~ s/is\(\$tzil->version, \K'0.002', 'version properly extracted from main module'/'1.23', 'version set via \$V override'/;

eval $code;
die $@ if $@;
