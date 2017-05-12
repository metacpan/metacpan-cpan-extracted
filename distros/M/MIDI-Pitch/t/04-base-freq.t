use Test::More tests => 8 + 128 + 100;

use MIDI::Pitch qw(basefreq pitch2freq freq2pitch);

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

is(basefreq(), 440);
is(basefreq(0), 440);
is(basefreq(-1), 440);
is(basefreq(432), 432);

is_delta(freq2pitch(432), 69);
is_delta(pitch2freq(69), 432);

is_delta(freq2pitch(27), 21);
is_delta(pitch2freq(21), 27);

# Test conversion back and forth -----------------------------------------

for (0..127) {
    is_delta(freq2pitch(pitch2freq($_)), $_);
}

for (1..100) {
    $_ *= 100;
    is_delta(pitch2freq(freq2pitch($_)), $_);
}
