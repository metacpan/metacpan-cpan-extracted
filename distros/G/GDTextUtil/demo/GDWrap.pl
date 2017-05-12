#!/usr/bin/perl -w
use strict;
use GD;
use GD::Text::Wrap;

my $outfile = shift || "GDWrap.png";

my $gd = GD::Image->new(400,240);
my $white = $gd->colorAllocate(255,255,255);
my $black = $gd->colorAllocate(  0,  0,  0);
my $blue  = $gd->colorAllocate(127,127,255);
my $red   = $gd->colorAllocate(127,  0,  0);

#print "No colours: $black ", $gd->colorsTotal, "\n";

my $text = 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit, 
sed diam 

nonummy nibh euismod 
tincidunt ut laoreet dolore magna aliquam erat volutpat.';

my $wp = GD::Text::Wrap->new($gd,
    width       => 180,
    line_space  => 4,
    color       => $black,
    text        => $text,
);

$wp->set(align => 'left');
$gd->rectangle($wp->get_bounds(10,10), $blue);
$wp->draw(10,10);

$gd->rectangle($wp->get_bounds(210,10), $blue);
$wp->set(para_space => 5, preserve_nl => 1);
$wp->set_font('Dustismo_Sans', 10);
$wp->set(align => 'justified', line_space => 0);
$wp->draw(210,10);

$wp->set(para_space => 10, preserve_nl => 0);
# Assume the user has set FONT_PATH or TTF_FONT_PATH
#$wp->font_path('/usr/share/fonts/ttfonts');
$wp->set_font(['arial', 'Dustismo_Sans'], 10);
$wp->set(align => 'right');
$gd->rectangle($wp->get_bounds(10,120), $blue);
$wp->draw(10,120);

$text =~ tr/\n//d;
$wp->set(text => $text);
$wp->set(colour => $white, align => 'center', line_space => 2);
$wp->set_font(gdMediumBoldFont, 12);
$gd->filledRectangle($wp->get_bounds(210,120), $red);
$wp->draw(210,120);

print "Writing $outfile\n";

open(GD, ">$outfile") or die "Cannot open '$outfile' for write: $!";
binmode GD ;
print GD $gd->png();
close GD;

