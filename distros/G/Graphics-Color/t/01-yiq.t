use Test::More tests => 9;

BEGIN {
    use_ok('Graphics::Color::YIQ');
}

my $color = Graphics::Color::YIQ->new(
    luminance => 1, in_phase => .4, quadrature => .5,
);

cmp_ok($color->luminance, '==', 1, 'luminance');
cmp_ok($color->y, '==', 1, 'luminance short');
cmp_ok($color->in_phase, '==', .4, 'in_phase');
cmp_ok($color->quadrature, '==', .5, 'lightness');

my @yiq = $color->as_array;
is_deeply(\@yiq, [1, .4, .5], 'yiq as array');

cmp_ok($color->as_string, 'eq', '1,0.4,0.5', 'as_string');

my $color2 = $color->clone;
ok($color2->equal_to($color), 'equal_to');

my $color3 = $color2->derive({ in_phase => .9 });
ok($color3->not_equal_to($color2), 'not_equal_to');
