# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 89;
BEGIN { use_ok('Math::Polyhedra') };

#########################

use Math::Polyhedra qw(polyhedron phi faces edges vertices tris);

ok(abs(phi() - 1.618) < 0.001, "phi approximation");

my %validations =
    ( 'cube' => 6,
      'tetrahedron' => 4,
      'octahedron' => 8,
      'dodecahedron' => 12,
      'rhombic dodecahedron' => -12,
      'icosahedron' => 20,
      'rhombic triacontahedron' => -30,
      'hexicosahedron' => 120 );

foreach (keys %validations)
{
    my $hedron = polyhedron($_);
    ok($hedron, "hedron: $_");

    my $faces = faces($hedron);
    ok($faces, "faces");
    $faces = @$faces;
    ok($faces > 0, "face count");
    ok($faces == abs($validations{$_}), "right face count");

    my $edges = edges($hedron);
    ok($edges, "edges");
    $edges = scalar (@$edges) / 2;
    ok($edges > 0, "edge count");

    my $verts = vertices($hedron);
    ok($verts, "vertices");
    $verts = @$verts;
    ok($verts > 0, "vertex count");

    my $tris = tris($hedron);
    ok($tris, "tris");
    $tris = @$tris;
    ok($faces <= $tris, "enough tris");

    if ($faces < 120)
    {
	ok($verts-$edges+$faces == 2, "euler simple test");
    }
}
