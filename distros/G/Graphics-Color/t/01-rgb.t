use Test::More tests => 44;

use Test::Number::Delta within => 1e-3;

BEGIN {
    use_ok('Graphics::Color::RGB');
}

eval {
    my $color = Graphics::Color::RGB->new(
        red => 10, green => .4, blue => .5, alpha => 0
    );
};
ok(defined($@), 'less than/equal to 1');

my $color = Graphics::Color::RGB->new(
    red => 1, green => .4, blue => .5, alpha => 0
);

cmp_ok($color->red, '==', 1, 'red');
cmp_ok($color->r, '==', 1, 'red short');
cmp_ok($color->green, '==', .4, 'green');
cmp_ok($color->blue, '==', .5, 'blue');
cmp_ok($color->alpha, '==', 0, 'alpha');

my @rgb = $color->as_array;
is_deeply(\@rgb, [1, .4, .5], 'rgb as array');

my @rgba = $color->as_array_with_alpha;
is_deeply(\@rgba, [1, .4, .5, 0], 'rgba as array');

cmp_ok($color->as_string, 'eq', '1.00,0.40,0.50,0.00', 'as_string');

cmp_ok($color->as_integer_string, 'eq', '255, 102, 127, 0.00', 'integer string');
cmp_ok($color->as_hex_string, 'eq', 'ff667f', 'hex string');
cmp_ok($color->as_hex_string('YAY'), 'eq', 'YAYff667f', 'hex string with prepend');
cmp_ok($color->as_css_hex, 'eq', '#ff667f', 'hex string with prepend');
cmp_ok($color->as_percent_string, 'eq', '100%, 40%, 50%, 0.00', 'percent string');
{
    my $color_z = Graphics::Color::RGB->new(
        red => 0, green => .4, blue => .5, alpha => 0
    );
    is($color_z->as_hex_string, '00667f', 'hex string with a zero value');
}

my $rgbc = $color->clone;
ok($rgbc->equal_to($color), 'equal_to');

my $new = $color->derive({green => 1});
cmp_ok($new->green, '==', 1, 'derived color, green');
cmp_ok($new->blue, '==', .5, 'derived color, blue');

ok(!$new->equal_to($color), 'not equal_to');

my $rgb1 = Graphics::Color::RGB->new(red => 1, green => 0, blue => 0);
my $hsl1 = $rgb1->to_hsl;
cmp_ok($hsl1->h, '==', 0, 'HSL conversion: H');
cmp_ok($hsl1->s, '==', 1, 'HSL conversion: S');
cmp_ok($hsl1->l, '==', .5, 'HSL conversion: L');

my $hsv1 = $rgb1->to_hsv;
cmp_ok($hsv1->h, '==', 0, 'HSV conversion: H');
cmp_ok($hsv1->s, '==', 1, 'HSV conversion: S');
cmp_ok($hsv1->v, '==', 1, 'HSV conversion: V');

my $rgb2 = Graphics::Color::RGB->new(red => .5, green => 1, blue => .5);
my $hsl2 = $rgb2->to_hsl;
cmp_ok($hsl2->h, '==', 120, 'HSV conversion: H');
cmp_ok($hsl2->s, '==', 1, 'HSV conversion: S');
cmp_ok($hsl2->l, '==', .75, 'HSV conversion: V');

my $hsv2 = $rgb2->to_hsv;
cmp_ok($hsv2->h, '==', 120, 'HSV conversion: H');
cmp_ok($hsv2->s, '==', .5, 'HSV conversion: S');
cmp_ok($hsv2->v, '==', 1, 'HSV conversion: V');

my $rgb3 = Graphics::Color::RGB->new(red => 0, green => 0, blue => .5);
my $hsl3 = $rgb3->to_hsl;
cmp_ok($hsl3->h, '==', 240, 'HSL conversion: H');
cmp_ok($hsl3->s, '==', 1, 'HSL conversion: S');
cmp_ok($hsl3->l, '==', .25, 'HSL conversion: L');

my $hsv3 = $rgb3->to_hsv;
cmp_ok($hsv3->h, '==', 240, 'HSV conversion: H');
cmp_ok($hsv3->s, '==', 1, 'HSV conversion: S');
cmp_ok($hsv3->v, '==', .5, 'HSV conversion: V');

my $h_white = Graphics::Color::RGB->from_hex_string('#ffffff');
cmp_ok($h_white->r, '==', 1, 'from_hex_string red');
cmp_ok($h_white->g, '==', 1, 'from_hex_string green');
cmp_ok($h_white->b, '==', 1, 'from_hex_string blue');

my $h_wtf = Graphics::Color::RGB->from_hex_string('#f0aacd');
delta_ok($h_wtf->r, 0.941, 'from_hex_string red');
delta_ok($h_wtf->g, 0.666, 'from_hex_string green');
delta_ok($h_wtf->b, 0.803, 'from_hex_string blue');
