use strict;
use warnings;

use Path::Tiny;
my $code = path('t', '02-mcl-too-old.t')->slurp_utf8;

$code =~ s/(\$ENV\{DZIL_ANY_PERL\}) = 0/$1 = 1/;

my $new_test = <<'NEW_TEST';
is(
    exception { $tzil->release },
    undef,
    'release proceeds normally when DZIL_ANY_PERL is set',
);

cmp_deeply(
    $tzil->log_messages,
    superbagof('[EnsureLatestPerl] DZIL_ANY_PERL set: skipping perl version check'),
    'short-circuiting message logged',
);
NEW_TEST

$code =~ s/### BEGIN \$tzil->release check.*### END \$tzil->release check/$new_test/s;

eval $code;
die $@ if $@;
