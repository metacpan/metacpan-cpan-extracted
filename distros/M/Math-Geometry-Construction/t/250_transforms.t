#!perl -T
use strict;
use warnings;

use Test::More tests => 24;
use Math::Geometry::Construction;

sub is_close {
    my ($value, $reference, $message, $limit) = @_;

    cmp_ok(abs($value - $reference), '<', ($limit || 1e-12), $message);
}

sub right_handed {
    my $construction = Math::Geometry::Construction->new;

    my $p;
    my $ci;
    my $svg;
    my $element;

    $p = $construction->add_point(position => [10, 20], id => 'P01');

    $svg = $construction->as_svg(width => 100, height => 80);
    $element = $svg->getElementByID('P01');
    ok(defined($element), 'found element');
    is($element->attrib('cx'), 10, 'cx attribute');
    is($element->attrib('cy'), 20, 'cy attribute');

    $svg = $construction->as_svg(width     => 100,
				 height    => 80,
				 transform => [1, 0, 0, -1, 0, 80]);
    $element = $svg->getElementByID('P01');
    ok(defined($element), 'found element');
    is($element->attrib('cx'), 10, 'cx attribute');
    is($element->attrib('cy'), 60, 'cy attribute');

    $ci = $construction->add_circle(center => [300, 450],
				    radius => 50,
				    id     => 'C01');

    $svg = $construction->as_svg(width     => 100,
				 height    => 80,
				 transform => [0.1, 0, 0, -0.1, 0, 80]);
    $element = $svg->getElementByID('C01');
    ok(defined($element), 'found element');
    is($element->attrib('cx'), 30, 'cx attribute');
    is($element->attrib('cy'), 35, 'cy attribute');
    is($element->attrib('rx'), 5, 'rx attribute');
    is($element->attrib('ry'), 5, 'ry attribute');

    $svg = $construction->as_svg(width     => 100,
				 height    => 80,
				 transform => [0.2, 0, 0, -0.1, 0, 80]);
    $element = $svg->getElementByID('C01');
    ok(defined($element), 'found element');
    is($element->attrib('cx'), 60, 'cx attribute');
    is($element->attrib('cy'), 35, 'cy attribute');
    is($element->attrib('rx'), 10, 'rx attribute');
    is($element->attrib('ry'), 5, 'ry attribute');

    $ci = $construction->add_line(support => [[300, 450], [200, 100]],
				  id      => 'L01');

    $svg = $construction->as_svg(width     => 100,
				 height    => 80,
				 transform => [0.1, 0, 0, -0.1, 0, 80]);
    $element = $svg->getElementByID('L01');
    ok(defined($element), 'found element');
    is($element->attrib('x1'), 30, 'x1 attribute');
    is($element->attrib('y1'), 35, 'y1 attribute');
    is($element->attrib('x2'), 20, 'x2 attribute');
    is($element->attrib('y2'), 70, 'y2 attribute');

    $p = $construction->add_point(position => [500, 600],
				  id       => 'P02',
				  label    => 'P02');
    $svg = $construction->as_svg(width     => 100,
				 height    => 80,
				 transform => [0.1, 0, 0, -0.1, 0, 80]);
    $element = $svg->getElementByID('P02_label');
    ok(defined($element), 'found element');
    is($element->attrib('x'), 50, 'x attribute');
    is($element->attrib('y'), 20, 'y attribute');
}

right_handed;
