# Tests for /dev/random

use strict;
use warnings;

use Test::More;

my @WARN;
BEGIN {
    # Warning signal handler
    $SIG{__WARN__} = sub { push(@WARN, @_); };
}

if (-e '/dev/random') {
    my $FH;
    if (open($FH, '<', '/dev/random')) {
        binmode($FH);
        my $data;
        my $cnt = read($FH, $data, 8);
        if (! defined($cnt)) {
            plan skip_all => "Couldn't read from /dev/random: $!";
        } elsif ($cnt == 8) {
            plan tests => 92;
        } else {
            plan skip_all => "/dev/random exhausted ($cnt of 8 bytes)";
        }
        close($FH);
    } else {
        plan skip_all => "/dev/random not usable: $!";
    }
} else {
    plan skip_all => '/dev/random not available';
}

use_ok('Math::Random::MT::Auto', qw(rand irand), '/dev/random');
can_ok('main', qw(rand irand));

# Check for warnings
if (grep { /exhausted/ } @WARN) {
    diag('/dev/random exhausted');
    undef(@WARN);
}
if (grep { /unavailable/ } @WARN) {
    diag('/dev/random unavailable');
    undef(@WARN);
}
if (grep { /Failure reading/ } @WARN) {
    diag('Seed warning ignored: ' . join(' | ', @WARN));
    undef(@WARN);
}
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
