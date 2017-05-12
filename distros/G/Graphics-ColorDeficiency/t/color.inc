use Graphics::ColorDeficiency;

$obj1 = Graphics::ColorDeficiency->new;
my $hex = '6699cc';
my ($r, $g, $b) = map{hex($_) / 255} ($hex =~ /../g);
$obj1->setRGB($r, $g, $b);
