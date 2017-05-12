use Test::More tests => 5;

BEGIN {
    use_ok('Graphics::Primitive::Font');
}

my $obj = Graphics::Primitive::Font->new(
    family    => 'Myriad Pro',
    size    => 15,
    slant   => 'italic',
    weight  => 'bold'
);

cmp_ok($obj->family, 'eq', 'Myriad Pro', 'face');
cmp_ok($obj->size, '==', 15, 'size');
cmp_ok($obj->slant, 'eq', 'italic', 'slant');
cmp_ok($obj->weight, 'eq', 'bold', 'weight');
