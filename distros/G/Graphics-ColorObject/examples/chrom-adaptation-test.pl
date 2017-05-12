$| = 1;

use Graphics::ColorObject;

$c = Graphics::ColorObject->new_RGB([0.2, 0.5, 0.1], space=>'NTSC');
while (1)
{
	$c->set_white_point('D93');
	$c->set_white_point('C');
	if ($i++ % 1000 == 0)
	{
		print '<font color="'.$c->as_RGBhex.'">X</font>'."\n";
	}
}

