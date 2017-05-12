use Test::More tests => 3;

BEGIN
{
  use_ok('Math::Fractal::DLA');
}

my $type = "Explode";
my $width = 500;
my $height = 500;
my $fractal = new Math::Fractal::DLA;

can_ok($fractal,("setType","setSize","setBackground","setColors","setBaseColor","setPoints","setFile"));

eval
{
  $fractal->setType($type);
  $fractal->setSize(width => $width, height => $height);
  $fractal->setBackground(r => 245, g => 245, b => 180);
  $fractal->setColors(5);
  $fractal->setBaseColor(base_r => 10, base_g => 100, base_b => 100, add_r         => 50, add_g => 0, add_b => 0);
  $fractal->setStartPosition(x => 250, y => 250);
  $fractal->setPoints(500);
  $fractal->setFile("dla.png");
  $fractal->generate(); 
};
if ($@)
{ fail("Fractal-Generation"); }
else
{ pass("Fractal-Generation"); }

