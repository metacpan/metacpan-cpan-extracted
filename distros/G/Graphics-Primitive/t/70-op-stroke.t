use Test::More tests => 2;

BEGIN {
    use_ok('Graphics::Primitive::Operation::Stroke');
}

my $stroke = Graphics::Primitive::Operation::Stroke->new;
isa_ok($stroke, 'Graphics::Primitive::Operation::Stroke');
