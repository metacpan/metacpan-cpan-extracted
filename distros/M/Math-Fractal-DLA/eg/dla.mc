<%doc>
Diffusion limited aggregation (DLA) fractal
Copyright 2002 by Wolfgang Gruber

Example file for HTML::Mason
</%doc>

<%init>
use Math::Fractal::DLA;
$r->content_type("image/png");
my $fractal = new Math::Fractal::DLA;
$fractal->debug(debug => 0);

# Set the type of the fractal
if    ($mode == 0)
{
  $fractal->setType("Explode");
  $fractal->setStartPosition(x => int($width / 2), y => int($height / 2));
}
elsif ($mode == 1)
{ $fractal->setType("Race2Center"); }
elsif ($mode == 2)
{ $fractal->setType("Surrounding"); }
elsif ($mode == 3)
{ $fractal->setType("GrowUp"); }
$fractal->setPoints($pixels);

# Limit size to 300 x 300 pixels
if ($width > 300) { $width = 300; }
if ($height > 300) { $height = 300; }
$fractal->setSize(width => $width, height => $height);

# Set colors
$fractal->setBackground(r => $bgred, g => $bggreen, b => $bgblue);
$fractal->setColors($colors);
$fractal->setBaseColor(base_r => $bsred, base_g => $bsgreen, base_b => $bsblue,add_r => $ared, add_g => $agreen, add_b => $ablue);

$fractal->generate(); 
$m->print($fractal->getFractal());
</%init>
<%args>
$pixels => 500
$mode => 0
$width => 300
$height => 300
$colors => 1
$bgred => 255
$bggreen => 255
$bgblue => 255
$bsred => 0 
$bsgreen => 255 
$bsblue => 255 
$ared => 0
$agreen => 0
$ablue => 0
</%args>

<%flags>
  inherit => undef
</%flags>
