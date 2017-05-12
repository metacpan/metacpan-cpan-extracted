use Test::More tests => 4;

BEGIN {
    use_ok('Geometry::Primitive::Circle');
};

my $circ = Geometry::Primitive::Circle->new( radius => 5 );
isa_ok($circ, 'Geometry::Primitive::Circle');

cmp_ok($circ->radius, '==', 5, 'radius');
cmp_ok($circ->diameter, '==', 10, 'diameter');
