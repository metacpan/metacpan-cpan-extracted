#!/usr/bin/perl

use 5.010;

use strict;
use warnings;

use Cairo;

use Math::Vector::Real;
use Math::Vector::Real::Random;
use Math::Vector::Real::Neighbors;

use Benchmark qw(cmpthese);

my $points = 100_000;

my $size = 2000;
my $margin = 0;
my $w = 0.01;

my $delta = V(0.5, 0.5);


my @p;
while (<DATA>) {
    s/\s//g;
    push @p, V($1, $2) if /\{(-?[\d\.]+)\,(-?[\d\.]+)}/;
}
if (@p >= $points) {
    say "data loaded from file";
}
else {
    @p = map Math::Vector::Real->random_normal(2, 0.2) + $delta, 1..$points;
    # print join("\n", @p, '');
}

# @p = @p[18, 17, 4, 9, 16];

my @nbf;
my @n;
my @nkdt;

cmpthese( 1, { # bf     => sub { @nbf  = Math::Vector::Real::Neighbors->neighbors_bruteforce(@p) },
              slow   => sub { @n    = Math::Vector::Real::Neighbors->neighbors_slow(@p) },
              kdtree  => sub { @n    =  Math::Vector::Real::Neighbors->neighbors_kdtree(@p) },
              kdtree2 => sub { @nkdt =  Math::Vector::Real::Neighbors->neighbors_kdtree2(@p) }
             } );

my $surface = Cairo::ImageSurface->create ('argb32', $size + 2 * $margin, $size + 2 * $margin);
my $cr = Cairo::Context->create ($surface);

$cr->set_source_rgb(1, 0, 0);
for (0..$#p) {
    arrow($p[$_], $p[$nkdt[$_]]);
}

$cr->set_source_rgb(0, 0, 1);
for (0..$#p) {
    arrow($p[$_], $p[$n[$_]]);
    #line_to($_);
    # $cr->line_to($_->[0] * $size + $margin, $_->[1] * $size + $margin);
    # say join(", ", abs($_ - $delta), $_->[0], $_->[1], $_->[0] * $size, $_->[1] * $size);
}

$cr->show_page;

$surface->write_to_png ('output.png');

system "eog output.png 2>/dev/null";

sub move_to { $cr->move_to($_[0][0] * $size + $margin, $_[0][1] * $size + $margin) }
sub line_to { $cr->line_to($_[0][0] * $size + $margin, $_[0][1] * $size + $margin) }

sub arrow {
    my ($v0, $v1) = @_;
    my $d = $v0->dist($v1);
    next unless $d;
    # say "$d <= [$v0], [$v1]";
    my $u = ($v1 - $v0)->versor;
    my $n = $u->normal_base;
    if ($d < $w) {
        move_to($v1);
        line_to($v0 + $n * $d/2);
        line_to($v0 - $n * $d/2);
        line_to($v1);
        $cr->fill;
    }
    else {
        $u *= $w;
        $n *= $w;
        move_to($v0);
        line_to($v0 + $n/4);
        line_to($v1 + $n/4 - $u);
        line_to($v1 + $n/2 - $u);
        line_to($v1);
        line_to($v1 - $n/2 - $u);
        line_to($v1 - $n/4 - $u);
        line_to($v0 - $n/4);
        line_to($v0);
        $cr->fill;
    }
}

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
