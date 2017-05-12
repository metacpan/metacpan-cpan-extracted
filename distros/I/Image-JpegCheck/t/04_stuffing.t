use strict;
use warnings;
use Test::More;
use Image::JpegCheck;

my $fname = 't/foo.jpg';
open my $fh, '<', $fname or die $!;
my $src = do { local $/; <$fh> };
for my $i (0..4096) {
    test_scalarref($src.("\xFF"x$i), 1, "ff x $i");
}
done_testing;
exit;

sub test_scalarref {
    my ($src, $expected, $target) = @_;

    is((is_jpeg(\$src) ? 1 : 0), $expected, $target);
}

