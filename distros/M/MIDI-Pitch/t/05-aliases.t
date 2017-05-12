use Test::More tests => 5 + 128 * 2;

use MIDI::Pitch qw(pitch2name name2freq freq2name freq2pitch);

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

ok(!defined freq2name());
ok(!defined name2freq());

ok(!defined freq2name('garbage'));
ok(!defined name2freq('garbage'));

# edge cases
ok(!defined freq2name(0));

# Test conversion back and forth -----------------------------------------

for (0..127) {
    my $name = pitch2name($_);
    my $freq = name2freq($name);
    
    is(freq2name($freq), $name);
    is_delta(freq2pitch($freq), $_);
}
