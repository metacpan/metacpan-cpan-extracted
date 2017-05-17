use strict;
use warnings;

use Path::Tiny;
my $code = path('t', '01-basic.t')->slurp_utf8;

# fake the current perl version to be something old.
$code =~ s/^plan skip_all.*$/local \$\] = '5.010000';/m;

my $new_test = <<'NEW_TEST';
    like(
        exception { $tzil->release },
        qr/^\[UseUnsafeInc\] Perl must be 5.025007 or newer to test with PERL_USE_UNSAFE_INC -- disable check with DZIL_ANY_PERL=1/,
        'release halts if perl is too old',
    );
NEW_TEST

$code =~ s/### BEGIN \$tzil->release check.*### END \$tzil->release check/$new_test/s;

eval $code;
die $@ if $@;
