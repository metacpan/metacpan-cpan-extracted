#!/usr/bin/perl
use strict;
use warnings;

use LaTeX::TikZ as => 'TikZ';

my $seq  = TikZ->seq;
my $raw  = TikZ->raw('\path[clip] (0, 0) rectangle (1, 1)');
$seq->add($raw);
my $rect = TikZ->rectangle(TikZ->point(0, 0), TikZ->point(2, 3));
my $path = TikZ->path($rect);
my $clip = TikZ->clip($path);
$path = TikZ->path($rect);

print $raw->content, "\n";

my (undef, undef, $body) = TikZ->formatter->render($seq);
my $string = sprintf("%s\n", join("\n", @$body));
print $string;
