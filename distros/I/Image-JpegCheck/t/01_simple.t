use strict;
use warnings;
use Test::More;
use Image::JpegCheck;

our $target;

my @tests = (
    't/foo.jpg'      => 1,
    't/bar.jpg'      => 1,
    't/stuffing.jpg' => 1,
    't/01_simple.t'  => 0,
);
while (my ($src, $expected) = splice(@tests, 0, 2)) {
    test_whole($src, $expected);
}
done_testing;
exit;

sub test_whole {
    my ($src, $expected) = @_;
    local $target = $src;
    test($src, $expected);
    test_fh($src, $expected);
    test_scalarref($src, $expected);
}

sub test_fh {
    my ($fname, $expected) = @_;

    open my $fh, '<', $fname or die;
    test($fh, $expected);
    close $fh;
}

sub test_scalarref {
    my ($fname, $expected) = @_;

    open my $fh, '<', $fname or die "$fname: $!";
    my $src = do { local $/; <$fh> };
    close $fh;

    test(\$src, $expected);
}

sub test {
    my ($src, $expected) = @_;
    is((is_jpeg($src) ? 1 : 0), $expected, $target);
}

