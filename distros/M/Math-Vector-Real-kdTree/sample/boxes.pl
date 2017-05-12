#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use GD;
use Math::Vector::Real;
use Math::Vector::Real::Random;
use Math::Vector::Real::kdTree;

my $p = 10000;
my $w = 1024;
my $im = GD::Image->new($w, $w);
my $white = $im->colorAllocate(255,255,255);
my $black = $im->colorAllocate(0, 0, 0);
# $im->transparent($white);
$im->interlaced('true');

sub scl {
    my $p = shift;
    @{$w * (0.3 * $p + [0.5, 0.5])}[0, 1];
}

sub sscl {
    my $s = shift;
    $w * (0.3*$s);
}


my @p;
while (<DATA>) {
    s/\s//g;
    push @p, V($1, $2) if /\{(-?[\d\.]+)\,(-?[\d\.]+)}/;
}

if (@p < $p) {
    @p = map Math::Vector::Real->random_normal(2, 0.6), 1..$p;
}

# @p = @p[0..$#p];

my $tree = Math::Vector::Real::kdTree->new(@p);

my %path;
for (0..$#p) {
    push @{$path{$tree->path($_)}}, $_;
}

my @colors;
for my $set (values %path) {
    my $color = $im->colorAllocate(map int $_, @{Math::Vector::Real->random_versor(3, 255.9)});
    if ($color >= 0) {
        push @colors, $color;
    }
    else {
        $color = $colors[rand @colors];
    }
    my ($b, $t) = Math::Vector::Real->box(@p[@$set]);
    $im->rectangle(scl($b), scl($t), $color);
    $im->filledEllipse(scl($_), 3, 3, $color) for @p[@$set];
}

open my $fh, ">output.png";
print $fh $im->png;

__DATA__

{0.360273672659563, 0.681459947082673}
{0.176663207393249, 0.404644066772445}
{1.05728054075933, 0.14704076332749}
{0.553760099403691, 0.0547824407714363}
{0.0479743023870717, 0.963824108595659}
{0.776144419292398, 0.10956787723834}
{1.0209388373113, 0.971510537877524}
{0.0706926934034146, -0.114056543099417}
{0.515397128075519, 0.612716041689772}
{0.26975413715681, 1.03607341990943}
{0.402473337889129, 0.292854432427144}
{0.502995986052089, 0.713098206321628}
{0.654221365535431, 0.413225433599031}
{0.809595420704002, 0.23428087884566}
{0.727126702840134, 0.589085324802046}
{0.495470529749333, 0.16063680625426}
{0.290835931539363, 1.06150585371687}
{0.159456912007944, 0.897423580738299}
{0.160445827140042, 0.503289145929537}
{0.26744213070957, 0.147348345161297}
