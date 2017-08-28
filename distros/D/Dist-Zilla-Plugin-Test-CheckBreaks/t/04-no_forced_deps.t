use strict;
use warnings;

# just like t/03-x_breaks, but we set no_forced_deps => 1

use Path::Tiny;
my $code = path('t', '03-x_breaks.t')->slurp_utf8;

$code =~ s/(no_forced_deps =>) 0/$1 1/g;

$code =~ s/\^use (CPAN::Meta::Requirements)/    skip 'This information-only test requires $1', 1\\n        if not eval \\{ \\+require $1 \\}/m;
$code =~ s/\^use (CPAN::Meta::Check) (\$cmc_prereq);/    skip 'This information-only test requires $1 $2', 1\\n        if not eval \\{ \\+require $1; $1->VERSION\\\($2\\\) \\};/m;

$code =~ s/"test uses \$_"/"x_breaks checks skipped if \$_ not installed"/;

my @prereqs = $code =~ m/^(\s+'CPAN::Meta::.+,\n)/mg;

$code =~ s/^\Q$_\E//m foreach @prereqs;
my $prereqs = join('', @prereqs);
$code =~ s/^((\s+)requires => \{\n\s+[^}]+\n(\s+\},)\n)/$1$2suggests => \{\n$prereqs$3\n/m;

eval $code;
die $@ if $@;
