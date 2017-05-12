use Test::More tests => 4;

BEGIN {
    use_ok('Geometry::Primitive::Ellipse');
};

my $circ = Geometry::Primitive::Ellipse->new(width => 4 , height => 2);
isa_ok($circ, 'Geometry::Primitive::Ellipse');

$circ->origin([1, 2]);
isa_ok($circ->origin, 'Geometry::Primitive::Point');

ok($circ->area =~ /^6.28/, 'area');
