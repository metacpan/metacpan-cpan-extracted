#!/usr/bin/perl -w
use strict;

# A simple CGI which runs a random set of points through the module
# and displays the resulting polygons using the <canvas> tag supported
# by recent versions of Firefox and Safari.  You can run it as a CGI
# or from the command line like:
#
#    perl ./voronoi.cgi > foo.html

use Math::Geometry::Voronoi;
use HTML::Template;
use CGI qw/header/;

my $text = do { local $/; <DATA> };
my $template = HTML::Template->new(scalarref         => \$text,
                                   die_on_bad_params => 0,
                                   loop_context_vars => 1);

my $cgi = CGI->new();
my $n = $cgi->param('n') || 1000;
$template->param(n => $n);

die "What are you trying to do to me?"
  if $n > 5000;

my $xsize = $cgi->param('xsize') || 1000;
$template->param(xsize => $xsize);

my $ysize = $cgi->param('ysize') || 500;
$template->param(ysize => $ysize);

my @points = map { [int(rand($xsize)), int(rand($ysize))] } (0 .. $n - 1);
my %seen;
@points = grep { not $seen{$_->[0], $_->[1]}++ } @points;

my $geo = Math::Geometry::Voronoi->new(points => \@points);
$geo->compute;
my @polygons = $geo->polygons(normalize_vertices => sub { int($_[0]) });

my @poly;
foreach my $poly ($geo->polygons) {
    my ($p, @verts) = @$poly;

    next if grep { $_->[0] > $xsize + 100 } @verts;
    next if grep { $_->[1] > $ysize + 100 } @verts;
    next if grep { $_->[0] < -100 } @verts;
    next if grep { $_->[1] < -100 } @verts;

    push @poly,
      { points => [
            map { {x => int($_->[0]), y => int($_->[1])} } (@verts, $verts[0])
        ],
        color => rand_color()};
}

$template->param(polygons => \@poly);

print header(), $template->output;

sub rand_color {
    return join(',', map int(rand(255)), (1 .. 3));
}

__DATA__
<html>
<head>
<title>Math::Geometry::Voronoi Demo</title>
</head>
<body>

<h1>Math::Geometry::Voronoi Demo</h1>

<p>This is a demo of
the <a href="http://search.cpan.org/~samtregar/Math-Geometry-Voronoi">Math::Geometry::Voronoi</a>
Perl module.  To learn
more, <a href="http://search.cpan.org/~samtregar/Math-Geometry-Voronoi/lib/Math/Geometry/Voronoi.pm">read
the fine manual</a>.</p>

<p>The image below shows a diagram containing <tmpl_var n> random
points.  Only the complete polygons returned from the polygons()
method are shown, which is why nothing is drawn around the edges.  If
you don't see anything please try again with Firefox - your browser
may not support the new HTML &lt;canvas&gt; tag.</p>

<canvas style="border: 1px solid black" id="map" width="<tmpl_var xsize>" height="<tmpl_var ysize>"></canvas>

<script language="javascript">
var canvas = document.getElementById('map');
var ctx = canvas.getContext('2d');

<tmpl_loop polygons>
  ctx.fillStyle = 'rgb(<tmpl_var color>)';
  ctx.beginPath();
  <tmpl_loop points>
    <tmpl_if __first__>
       ctx.moveTo(<tmpl_var x>,<tmpl_var y>);
    <tmpl_else>
       ctx.lineTo(<tmpl_var x>,<tmpl_var y>);
    </tmpl_if>
  </tmpl_loop>
  ctx.stroke();
  ctx.fill();
</tmpl_loop>

</script>
