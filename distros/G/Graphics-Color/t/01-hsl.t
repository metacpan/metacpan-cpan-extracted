use Test::More tests => 12;

BEGIN {
    use_ok('Graphics::Color::HSL');
}

eval {
    my $color = Graphics::Color::HSL->new(
        hue => 420, saturation => .4, lightness => .5, alpha => 0
    );
};
ok(defined($@), 'less than/equal to 1');

my $color = Graphics::Color::HSL->new(
    hue => 120, saturation => .4, lightness => .5, alpha => 0
);

cmp_ok($color->hue, '==', 120, 'hue');
cmp_ok($color->saturation, '==', .4, 'saturation');
cmp_ok($color->lightness, '==', .5, 'lightness');
cmp_ok($color->alpha, '==', 0, 'alpha');

my @hsl = $color->as_array;
is_deeply(\@hsl, [120, .4, .5], 'hsl as array');

my @hsla = $color->as_array_with_alpha;
is_deeply(\@hsla, [120, .4, .5, 0], 'hsla as array');

cmp_ok($color->as_string, 'eq', '120,0.40,0.50,0.00', 'as_string');

cmp_ok($color->as_percent_string, 'eq', '120, 40%, 50%, 0.00', 'percent string');

my $color2 = $color->clone;
ok($color2->equal_to($color), 'equal_to');

my $color3 = $color2->derive({ saturation => .9 });
ok($color3->not_equal_to($color2), 'not_equal_to');