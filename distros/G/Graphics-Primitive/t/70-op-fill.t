use Test::More tests => 2;

use Graphics::Primitive::Paint::Solid;

BEGIN {
    use_ok('Graphics::Primitive::Operation::Fill');
}

my $stroke = Graphics::Primitive::Operation::Fill->new(
    paint => Graphics::Primitive::Paint::Solid->new
);
isa_ok($stroke, 'Graphics::Primitive::Operation::Fill');
