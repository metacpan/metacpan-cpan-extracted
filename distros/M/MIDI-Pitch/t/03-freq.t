use Test::More tests => 9 + 128 + 100;

use MIDI::Pitch qw(pitch2freq freq2pitch);

# command-line conversion for testing:
# perl -e '$p = 20; print exp(($p - 69) / 12 * log(2)) * 440 , "\n"'
# perl -e '$f = 164.813778456435; print 69 + 12 * log($f/440)/log(2), "\n";'

sub is_delta {
    my ($val, $is, $delta) = @_;
    $delta = .00001 unless defined $delta;

    if ($val >= $is - $delta && $val <= $is + $delta) {
        pass();
    } else {
        fail();
        diag <<EOT;
#          got: '$val'
#     expected: '$is' +/- $delta
EOT
    }
}

# Test some special cases ------------------------------------------------

ok(!defined freq2pitch());
ok(!defined pitch2freq());

ok(!defined freq2pitch('garbage'));
ok(!defined pitch2freq('garbage'));

# edge cases
ok(!defined freq2pitch(0));

# for standard setting
# freq 440 = pitch 69
is_delta(freq2pitch(440), 69);
is_delta(pitch2freq(69), 440);

# freq 440 = pitch 69
is_delta(freq2pitch(27.5), 21);
is_delta(pitch2freq(21), 27.5);

# Test conversion back and forth -----------------------------------------

for (0..127) {
    is_delta(freq2pitch(pitch2freq($_)), $_);
}

for (1..100) {
    $_ *= 100;
    is_delta(pitch2freq(freq2pitch($_)), $_);
}
