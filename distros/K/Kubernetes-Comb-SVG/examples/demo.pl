#!/usr/bin/env perl
# Renders examples/demo.json to examples/demo.svg, the picture the README
# shows:
#
#   perl -Ilib examples/demo.pl
#
# and the same Combs in the packed layout, the status monitor, to
# examples/monitor.svg.
#
# All files are found next to this script, so it runs from any directory.
# With a path as argument demo.svg is written there instead and monitor.svg
# next to it; that is how t/50-demo.t checks that the committed pictures are
# current.
#
# demo.png and monitor.png are those two pictures in light mode, 1400 pixels
# wide, for the README and the documentation: examples/png.sh makes them with
# a headless Chromium. No test checks them, so run it after the pictures
# changed.

use strict;
use warnings;
use JSON::MaybeXS;
use Path::Tiny;
use Kubernetes::Comb::SVG;

my $here = path(__FILE__)->absolute->parent;
my $out  = @ARGV ? path( $ARGV[0] ) : $here->child('demo.svg');

my $combs = JSON::MaybeXS->new( utf8 => 1 )->decode( $here->child('demo.json')->slurp_raw );

$out->spew_raw( Kubernetes::Comb::SVG->new(
  combs       => $combs,
  title       => 'Shop',
  group_label => 'app.kubernetes.io/part-of',
  columns     => 6
)->render );

$out->sibling('monitor.svg')->spew_raw( Kubernetes::Comb::SVG->new(
  combs  => $combs,
  title  => 'Shop',
  layout => 'packed',
  blink  => ['Error']
)->render );
