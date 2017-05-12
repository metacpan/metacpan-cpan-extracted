use Test::More tests => 21;

BEGIN {
    use_ok('Graphics::Color::HSV');
}

eval {
    my $color = Graphics::Color::HSV->new(
        hue => 420, saturation => .4, value => .5, alpha => 0
    );
};
ok(defined($@), 'less than/equal to 1');

my $color = Graphics::Color::HSV->new(
    hue => 120, saturation => .4, value => .5, alpha => 0
);

cmp_ok($color->hue, '==', 120, 'hue');
cmp_ok($color->saturation, '==', .4, 'saturation');
cmp_ok($color->value, '==', .5, 'values');
cmp_ok($color->alpha, '==', 0, 'alpha');

my @hsl = $color->as_array;
is_deeply(\@hsl, [120, .4, .5], 'hsv as array');

my @hsla = $color->as_array_with_alpha;
is_deeply(\@hsla, [120, .4, .5, 0], 'hsva as array');

cmp_ok($color->as_string, 'eq', '120,0.40,0.50,0.00', 'as_string');

cmp_ok($color->as_percent_string, 'eq', '120, 40%, 50%, 0.00', 'percent string');

my $color2 = $color->clone;
ok($color2->equal_to($color), 'equal_to');

my $color3 = $color2->derive({ saturation => .9 });
ok($color3->not_equal_to($color2), 'not_equal_to');

my $hsv1 = Graphics::Color::HSV->new(hue => 0, saturation => 1, value => 1);
my $rgb1 = $hsv1->to_rgb;
cmp_ok($rgb1->r, '==', 1, 'RGB conversion: R');
cmp_ok($rgb1->g, '==', 0, 'RGB conversion: G');
cmp_ok($rgb1->b, '==', 0, 'RGB conversion: B');

my $hsv2 = Graphics::Color::HSV->new(hue => 120, saturation => .5, value => 1);
my $rgb2 = $hsv2->to_rgb;
cmp_ok($rgb2->r, '==', .5, 'RGB conversion: R');
cmp_ok($rgb2->g, '==', 1, 'RGB conversion: G');
cmp_ok($rgb2->b, '==', .5, 'RGB conversion: B');

my $hsv3 = Graphics::Color::HSV->new(hue => 240, saturation => 1, value => .5);
my $rgb3 = $hsv3->to_rgb;
cmp_ok($rgb3->r, '==', 0, 'RGB conversion: R');
cmp_ok($rgb3->g, '==', 0, 'RGB conversion: G');
cmp_ok($rgb3->b, '==', .5, 'RGB conversion: B');
