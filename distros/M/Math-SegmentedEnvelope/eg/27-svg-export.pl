#!/usr/bin/env perl
# SVG export: envelope shapes as inline SVG for web/documentation
use strict;
use warnings;
use Math::SegmentedEnvelope qw(adsr perc asr spline env);

my $out_dir = $ARGV[0] // '.';

# Generate SVGs for standard envelope types
my @envelopes = (
    ['adsr',     adsr(0.1, 0.15, 0.7, 0.3)],
    ['perc',     perc(0.01, 0.5)],
    ['asr',      asr(0.2, 0.5, 0.3)],
    ['spline',   spline([0, 0.2, 0.5, 0.8, 1.0], [0, 0.9, 0.3, 0.8, 0])],
    ['bounce',   env([[0,1],[1],[1]], morpher_formula => 'bounce_out')],
    ['elastic',  env([[0,1],[1],[1]], morpher_formula => 'elastic_out')],
);

# HTML page with all envelopes
my $html = <<'HEAD';
<!DOCTYPE html>
<html><head><meta charset="utf-8">
<title>Math::SegmentedEnvelope Gallery</title>
<style>
body { font-family: system-ui; max-width: 800px; margin: 2em auto; background: #fafafa; }
.card { background: white; border: 1px solid #e5e7eb; border-radius: 8px; padding: 16px; margin: 16px 0; }
h2 { margin: 0 0 8px; font-size: 14px; color: #6b7280; }
svg { display: block; width: 100%; }
.grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
</style></head><body>
<h1>Envelope Gallery</h1>
HEAD

# Standard envelopes
$html .= "<div class='grid'>\n";
for my $pair (@envelopes) {
    my ($name, $e) = @$pair;
    my $svg = $e->to_svg(width => 380, height => 120, stroke => '#2563eb');
    $html .= "<div class='card'><h2>$name</h2>$svg</div>\n";
}
$html .= "</div>\n";

# Easing curves comparison
$html .= "<h1>Easing Curves</h1>\n<div class='grid'>\n";
my $def = [[0, 1], [1], [1]];
for my $name (qw(quad_out cubic_out circ_out back_out elastic_out bounce_out)) {
    my $e = env($def, morpher_formula => $name);
    my $svg = $e->to_svg(width => 380, height => 100, stroke => '#dc2626');
    $html .= "<div class='card'><h2>$name</h2>$svg</div>\n";
}
$html .= "</div>\n";

# Transform chain
$html .= "<h1>Transforms</h1>\n<div class='grid'>\n";
my $base = perc(0.05, 0.4, peak => 1.0);
my @transforms = (
    ['original',  $base],
    ['reverse',   $base->reverse],
    ['invert',    $base->invert],
    ['stretch(2)', $base->stretch(2)],
    ['quantize(4)', $base->quantize(4)],
    ['offset(0.3)', $base->offset(0.3)],
);
for my $pair (@transforms) {
    my ($label, $e) = @$pair;
    my $svg = $e->to_svg(width => 380, height => 100, stroke => '#059669');
    $html .= "<div class='card'><h2>$label</h2>$svg</div>\n";
}
$html .= "</div>\n</body></html>\n";

my $path = "$out_dir/envelopes.html";
open my $fh, '>', $path or die "Cannot write $path: $!";
print $fh $html;
close $fh;
printf "Wrote %s (%d bytes)\n", $path, length($html);

# Also write individual SVGs
for my $pair (@envelopes) {
    my ($name, $e) = @$pair;
    my $svg = $e->to_svg(width => 600, height => 200);
    my $file = "$out_dir/$name.svg";
    open my $fh, '>', $file or die "Cannot write $file: $!";
    print $fh $svg;
    close $fh;
    printf "  %s (%d bytes)\n", $file, length($svg);
}
