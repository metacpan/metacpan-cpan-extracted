#!/usr/bin/perl

# draw a RGB gamut in Lab space (uses Adobe RGB)

$space = $ARGV[0] || 'Adobe';

use Graphics::ColorObject;
use Image::Magick;

$img = Image::Magick->new;
($w, $h, $z) = (200, 200, 10);
$img->Set(size=>$w .'x'. $h);
$img->ReadImage('xc:black');

my ($r, $g, $b);
my ($hx, $hx_old);

foreach my $x (0..$w-1)
{
	foreach my $y (0..$h-1)
	{
		$hx = '000000'; $hx_old = '000000';
		foreach my $l (1..$z)
		{
			$c = Graphics::ColorObject->new_Lab([100*($l/$z),400*($x/$w-0.5), 400*(-$y/$h+0.5)], space=>$space);
			#$c = Graphics::Color->new_xyY([($x/$w), ($y/$h), 0.4], space=>'WideGamut');
			#$c = Graphics::Color->new_XYZ([($x/$w), 0.8, ($y/$h)], space=>'Adobe');
			#$c = Graphics::Color->new_HSL([360*($x/$w), ($y/$h), 0.5], space=>'Adobe');
			#$c = Graphics::Color->new_LCHab([75, 100*($x/$w), 6.24*($y/$h)], space=>'Adobe');
			
			($r, $g, $b) = @{ $c->as_RGB() };

			if ($r < 0 || $r > 1 || 
				$g < 0 || $g > 1 || 
				$b < 0 || $b > 1)
			{
				$hx = '000000'; # out of gamut
			}
			else
			{
				$hx = $c->as_RGBhex();
			}

			last if ($hx eq '000000' && $hx_old ne '000000');
			$hx_old = $hx;
		}
		#if ($X++ % 50 == 0) { print $c->as_RGBhex(), "\n"; }
		$img->Set("pixel[$x, $y]" => '#'.$hx_old);
	}
}

$img->Write('lab-gamut.png');

1;
