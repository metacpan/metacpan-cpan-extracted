use strict;
use warnings;

use Path::Tiny;
my $code = path('t', '01-basic.t')->slurp_utf8;

# fake the current perl version to be something old.
$code =~ s/^plan skip_all.*$/local \$\] = '5.010000';/m;

$code =~ s/(\$ENV\{DZIL_ANY_PERL\}) = 0/$1 = 1/;

my $new_test = <<'NEW_TEST';
    is(
        exception { $tzil->release },
        undef,
        'release proceeds normally when DZIL_ANY_PERL is set',
    );

    cmp_deeply(
        $tzil->log_messages,
        superbagof('[UseUnsafeInc] DZIL_ANY_PERL set: skipping perl version check'),
        'short-circuiting message logged',
    );
NEW_TEST

$code =~ s/### BEGIN \$tzil->release check.*### END \$tzil->release check/$new_test/s;

eval $code;
die $@ if $@;
