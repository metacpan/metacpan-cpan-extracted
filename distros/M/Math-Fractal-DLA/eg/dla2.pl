#!/usr/bin/perl -w

use strict;
use Math::Fractal::DLA;
use XML::XPath;
use XML::XPath::XMLParser;

my %config = 
(
  type => "Explode",
  width => 800,
  height => 640,
  points => 5000,
  file => "dla.png",
  startX => 400,
  startY => 320,
  colors => 5
);
my @bg = (0,0,0);
my @base = (0,0,0);
my @interval = (50,0,0);

print "Starting DLA Generator\n";

my $configFile = $ARGV[0] || "dla-config.xml";
if (-s $configFile) {}
else { die "Can't find ".$configFile." in directory ".$ENV{'PWD'}."\n"; }

my $xp = XML::XPath->new(filename => $configFile);

my $nodeset = $xp->find('/config/property');
foreach my $node ($nodeset->get_nodelist)
{
  my @attrs = $node->getAttributes;
  my $key = ""; my $val = "";
  foreach my $attr (@attrs)
  {
    if ($attr->getLocalName eq "key")
    { $key = $attr->getNodeValue; }
    if ($attr->getLocalName eq "value")
    { $val = $attr->getNodeValue; }
  }
  if (!$key || !$val) { next; }
  if (($key eq "background") || ($key eq "base") || ($key eq "interval"))
  {
    $val =~ /^(\d{1,3}),(\d{1,3}),(\d{1,3})$/;
    if ($key eq "background") { $bg[0] = $1; $bg[1] = $2; $bg[2] = $3; }
    if ($key eq "base") { $base[0] = $1; $base[1] = $2; $base[2] = $3; }
    if ($key eq "interval") { $interval[0] = $1; $interval[1] = $2; $interval[2] = $3; }
  }
  elsif ($key eq "type")
  {
    if (($val eq "Explode") || ($val eq "GrowUp") || ($val eq "Race2Center") || ($val eq "Surrounding"))
    { $config{'type'} = $val; }
  }
  else
  {
    $config{$key} = $val;
  }

}
print "Using the following configuration settings:\n";
foreach my $c (keys %config)
{
  print $c.": ".$config{$c}."\n";
}

my $fractal = new Math::Fractal::DLA;
if ($config{'log'}) { $fractal->debug(debug => 1, logfile => $config{'log'}); }
$fractal->setType($config{'type'});

$fractal->setSize(width => $config{'width'}, height => $config{'height'});
$fractal->setBackground(r => $bg[0], g => $bg[1], b => $bg[2]);
$fractal->setColors($config{'colors'});
$fractal->setBaseColor(base_r => $base[0], base_g => $base[1], base_b => $base[2], add_r => $interval[0], add_g => $interval[1], add_b => $interval[2]);
if ($config{'type'} eq "Explode")
{ $fractal->setStartPosition(x => $config{'startX'}, y => $config{'startY'}); }
$fractal->setPoints($config{'points'});
$fractal->setFile($config{'file'});
print "Generating..\n";
$fractal->generate(); 
$fractal->writeFile();
undef $fractal;

print "Done\n";

