#!perl

use strict;
use warnings;

use blib;

use LaTeX::TikZ;

# A couple of lines
my $hline = Tikz->line(-1 => 1);
my $vline = Tikz->line([ 0, -1 ] => [ 0, 1 ]);

# Paint them in red
$_->mod(Tikz->color('red')) for $hline, $vline;

# An octogon
use Math::Complex;
my $octo = Tikz->closed_polyline(
 map Math::Complex->emake(1, ($_ * pi)/4), 0 .. 7
);

# Only keep a portion of it
$octo->clip(Tikz->rectangle(-0.5*(1+i), 2*(1+i)));

# Fill it with dots
$octo->mod(Tikz->pattern(class => 'Dots'));

# Create a formatter object
my $tikz = Tikz->formatter(scale => 5);

# Put those objects all together and print them
my $seq = Tikz->seq($octo, $hline, $vline);
my ($head, $decl, $body) = $tikz->render($seq);
my @lines = (
 "\\documentclass[12pt]{article}",
 @$head,
 "\\begin{document}",
 "\\pagestyle{empty}",
 @$decl,
 "\\begin{center}",
 @$body,
 "\\end{center}",
 "\\end{document}",
);
print "$_\n" for @lines;
