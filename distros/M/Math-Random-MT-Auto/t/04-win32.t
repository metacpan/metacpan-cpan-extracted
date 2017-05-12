# Tests for Windows XP random source

use strict;
use warnings;

use Test::More;

my @WARN;
BEGIN {
    # Warning signal handler
    $SIG{__WARN__} = sub { push(@WARN, @_); };
}

if (($^O eq 'MSWin32') || ($^O eq 'cygwin')) {
    eval { require Win32; };
    if (! $@) {
        my ($id, $major, $minor) = (Win32::GetOSVersion())[4,1,2];
        if (defined($minor) &&
            (($id > 2) ||
             ($id == 2 && $major > 5) ||
             ($id == 2 && $major == 5 && $minor >= 1)))
        {
            eval {
                # Suppress (harmless) warning about Win32::API::Type's INIT block
                local $SIG{__WARN__} = sub {
                    if ($_[0] !~ /^Too late to run INIT block/) {
                        print(STDERR "# $_[0]");    # Output other warnings
                    }
                };

                # Load Win32::API module
                require Win32::API;
            };
            if (! $@) {
                plan(tests => 92);
            } else {
                plan(skip_all => 'No Win32::API');
            }
        } else {
            plan(skip_all => 'Not Win XP');
        }
    } else {
        plan(skip_all => 'Module "Win32" missing!?!');
    }
} else {
    plan(skip_all => 'Not MSWin32 or Cygwin');
}

use_ok('Math::Random::MT::Auto', qw(rand irand), 'win32');
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
