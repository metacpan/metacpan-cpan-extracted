use Test::More tests => 9;

BEGIN {
    use_ok('Graphics::Color::YUV');
}

my $color = Graphics::Color::YUV->new(
    luma => 1, blue_luminance=> .5, red_luminance => .2,
);

cmp_ok($color->luma, '==', 1, 'luma');
cmp_ok($color->y, '==', 1, 'luminance short');
cmp_ok($color->blue_luminance, '==', .5, 'blue');
cmp_ok($color->red_luminance, '==', .2, 'red');

my @yuv = $color->as_array;
is_deeply(\@yuv, [1, .5, .2], 'yiq as array');

cmp_ok($color->as_string, 'eq', '1,0.5,0.2', 'as_string');

my $color2 = $color->clone;
ok($color2->equal_to($color), 'equal_to');

my $color3 = $color2->derive({ luma => .9 });
ok($color3->not_equal_to($color2), 'not_equal_to');
