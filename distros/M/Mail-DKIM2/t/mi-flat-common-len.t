use strict; use warnings;
use utf8;
use Test::More;
use lib 'lib';
use Mail::DKIM2::MessageInstance;

# _common_prefix_len and _common_suffix_len compare a block at a time; they
# must give exactly what a character-at-a-time loop gives, at and around the
# block boundaries, and for strings with wide characters.

sub slow_prefix {
    my ($x, $y, $max) = @_;
    my $n = 0;
    $n++ while $n < $max and substr($x, $n, 1) eq substr($y, $n, 1);
    return $n;
}

sub slow_suffix {
    my ($x, $y, $max) = @_;
    my $n = 0;
    $n++ while $n < $max and substr($x, -1 - $n, 1) eq substr($y, -1 - $n, 1);
    return $n;
}

my $B = Mail::DKIM2::MessageInstance::CMP_BLOCK();
srand 20261008;

sub check {
    my ($x, $y, $why) = @_;
    my $min = length $x < length $y ? length $x : length $y;
    my $p = Mail::DKIM2::MessageInstance::_common_prefix_len($x, $y, $min);
    is $p, slow_prefix($x, $y, $min), "prefix: $why";
    my $s = Mail::DKIM2::MessageInstance::_common_suffix_len($x, $y, $min - $p);
    is $s, slow_suffix($x, $y, $min - $p), "suffix: $why";
}

my $base = join '', map { chr(97 + int rand 26) } 1 .. 3 * $B + 17;

for my $at (0, 1, $B - 1, $B, $B + 1, 2 * $B, 3 * $B, length($base) - 1) {
    (my $y = $base) =~ s/\A(.{$at})./$1#/s;
    check($base, $y, "one change at $at");
}

check($base, $base, 'identical');
check($base, substr($base, 0, $B), 'one a prefix of the other');
check($base, substr($base, $B + 5), 'one a suffix of the other');
check($base, $base . 'tail', 'appended');
check($base, 'head' . $base, 'prepended');
check($base, substr($base, 0, $B) . 'middle' . substr($base, $B), 'inserted in the middle');
check('', $base, 'one empty');

my $wide = join '', map { chr(0x4e00 + int rand 500) } 1 .. 2 * $B + 3;
(my $wide2 = $wide) =~ s/\A(.{$B})./$1☃/s;
check($wide, $wide2, 'wide characters, one change at a block boundary');
check($wide . "\x{263a}", $wide . "\x{263b}", 'wide characters, last character differs');

done_testing;
