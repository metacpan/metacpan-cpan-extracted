# Tests for /dev/urandom

use strict;
use warnings;

use Test::More;

my @WARN;
BEGIN {
    # Warning signal handler
    $SIG{__WARN__} = sub { push(@WARN, @_); };
}

if (! -e '/dev/urandom') {
    plan skip_all => '/dev/urandom not available';
} else {
    plan tests => 92;
}

use_ok('Math::Random::MT::Auto', qw(rand irand), '/dev/urandom');
can_ok('main', qw(rand irand));

# Check for warnings
if (! ok(! @WARN, 'Acquired seed data')) {
    diag('Seed warnings: ' . join(' | ', @WARN));
}
undef(@WARN);

my ($rn, @rn);

# Test rand()
eval { $rn = rand(); };
ok(! $@,                    'rand() died: ' . $@);
ok(defined($rn),            'Got a random number');
ok(Scalar::Util::looks_like_number($rn),  'Is a number: ' . $rn);
ok($rn >= 0.0 && $rn < 1.0, 'In range: ' . $rn);

# Test several values from irand()
for my $ii (0 .. 9) {
    eval { $rn[$ii] = irand(); };
    ok(! $@,                        'irand() died: ' . $@);
    ok(defined($rn[$ii]),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rn[$ii]), 'Is a number: ' . $rn[$ii]);
    ok(int($rn[$ii]) == $rn[$ii],   'Integer: ' . $rn[$ii]);
    for my $jj (0 .. $ii-1) {
        ok($rn[$jj] != $rn[$ii],    'Randomized');
    }
}

exit(0);

# EOF
