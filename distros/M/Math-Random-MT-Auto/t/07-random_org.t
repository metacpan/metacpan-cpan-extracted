# Tests for random.org site

use strict;
use warnings;

use Test::More;

# Warning signal handler
my @WARN;
BEGIN {
    $SIG{__WARN__} = sub { push(@WARN, @_); };
}

use Math::Random::MT::Auto qw(rand irand), 'random_org';

if (grep(/^Failure creating user-agent/, @WARN)) {
    plan skip_all => 'LWP::Useragent not available';
} elsif (grep(/^Failure contacting/, @WARN)) {
    plan skip_all => 'random.org not reachable';
} elsif ((grep(/^Failure getting data/, @WARN)) ||
         (grep(/^No seed data/, @WARN)))
{
    plan skip_all => 'Seed not obtained from random.org';
}
plan tests => 91;

@WARN = grep(!/^Partial seed/, @WARN);
@WARN = grep(!/only once/, @WARN);   # Ingnore 'once' warnings from other modules
ok(! @WARN, 'No warnings');
diag('Warnings: ' . join(' | ', @WARN)) if (@WARN);

can_ok('main', qw(rand irand));

# Test rand()
my ($rn, @rn);
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
