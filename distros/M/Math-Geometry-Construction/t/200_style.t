#!perl -T
use strict;
use warnings;

use Test::More tests => 45;
use Test::Exception;
use Math::Geometry::Construction;

sub point {
    my $construction = Math::Geometry::Construction->new;
    my $p;
    
    $p = $construction->add_point(position => [1, 2]);
    is_deeply($p->style_hash, {stroke => 'black', fill => 'white'},
	      'default point style');
    is($p->style('stroke'), 'black', 'default stroke');
    is($p->style('fill'), 'white', 'default fill');
    $p->style('fill', 'green');
    is($p->style('fill'), 'green', 'custom fill non-constructor');

    is_deeply($p->label_style_hash, {}, 'default label style');

    $p = $construction->add_point(position => [4, 5],
				  style    => {stroke => 'blue'});
    is_deeply($p->style_hash, {stroke => 'blue', fill => 'white'},
	      'point style');
    is($p->style('stroke'), 'blue', 'custom stroke constructor');
    is($p->style('fill'), 'white', 'default fill');
}

sub line {
    my $construction = Math::Geometry::Construction->new;
    my $line;
    
    $line = $construction->add_line(support => [[0, 0], [1, 1]]);
    is_deeply($line->style_hash, {stroke => 'black'},
	      'default line style');
    is($line->style('stroke'), 'black', 'default stroke');
    ok(!defined($line->style('fill')), 'default fill');
    $line->style('stroke', 'green');
    is($line->style('stroke'), 'green', 'custom stroke non-constructor');
    
    $line = $construction->add_line(support => [[0, 0], [1, 1]],
				    style   => {stroke => 'red'});
    is_deeply($line->style_hash, {stroke => 'red'},
	      'custom line style');
    is($line->style('stroke'), 'red', 'stroke');
    ok(!defined($line->style('fill')), 'default fill');
    $line->style('stroke', 'green');
    is($line->style('stroke'), 'green', 'custom stroke non-constructor');
}

sub circle {
    my $construction = Math::Geometry::Construction->new;
    my $circle;
    
    $circle = $construction->add_circle(center  => [0, 0],
					support => [1, 1]);
    is_deeply($circle->style_hash, {stroke => 'black', fill => 'none'},
	      'default circle style');
    is($circle->style('stroke'), 'black', 'default stroke');
    is($circle->style('fill'), 'none', 'default fill');
    $circle->style('stroke', 'green');
    is($circle->style('stroke'), 'green', 'custom stroke non-constructor');
    
    $circle = $construction->add_circle(center  => [0, 0],
					support => [1, 1],
					style   => {stroke => 'red'});
    is_deeply($circle->style_hash, {stroke => 'red', fill => 'none'},
	      'custom circle style');
    is($circle->style('stroke'), 'red', 'stroke');
    is($circle->style('fill'), 'none', 'default fill');
    $circle->style('stroke', 'green');
    is($circle->style('stroke'), 'green', 'custom stroke non-constructor');
    
    $circle = $construction->add_circle(center  => [0, 0],
					support => [1, 1],
					style   => {fill => 'red'});
    is_deeply($circle->style_hash, {fill => 'red', stroke => 'black'},
	      'custom circle style');
    is($circle->style('stroke'), 'black', 'stroke');
    is($circle->style('fill'), 'red', 'fill');
    $circle->style('fill', 'green');
    is($circle->style('fill'), 'green', 'custom fill non-constructor');
    
    $circle = $construction->add_circle(center  => [0, 0],
					support => [1, 1],
					style   => {fill   => 'red',
						    stroke => 'blue'});
    is_deeply($circle->style_hash, {fill => 'red', stroke => 'blue'},
	      'custom circle style');
    is($circle->style('stroke'), 'blue', 'stroke');
    is($circle->style('fill'), 'red', 'default red');
    $circle->style('fill', 'green');
    is($circle->style('fill'), 'green', 'custom fill non-constructor');
    $circle->style('stroke', 'magenta');
    is($circle->style('stroke'), 'magenta', 'custom stroke non-constructor');
    is_deeply($circle->style_hash, {fill => 'green', stroke => 'magenta'},
	      'custom circle style');
}

sub color {
    my $construction = Math::Geometry::Construction->new;
    my $p;
    
    # array color
    $p = $construction->add_point
	(position => [6, 7],
	 style    => {stroke => [0, 128, 0]});
    is_deeply($p->style('stroke'), [0, 128, 0], 'array color');
    $p->style('stroke', [123, 213, 2]);
    is_deeply($p->style('stroke'), [123, 213, 2], 'array color');
    $p->style('stroke', 'yellow');
    is($p->style('stroke'), 'yellow', 'color');

    $p = $construction->add_point(position => [6, 7]);
    is($p->style('stroke'), 'black', 'default color');
    $p->style('stroke', [122, 214, 67]);
    is_deeply($p->style('stroke'), [122, 214, 67], 'array color');
    $p->style('stroke', 'yellow');
    is($p->style('stroke'), 'yellow', 'color');

    $p = $construction->add_point
	(position    => [6, 7],
	 label_style => {stroke => [0, 128, 0]});
    is_deeply($p->label_style('stroke'), [0, 128, 0], 'array color');
    $p->label_style('stroke', [123, 213, 2]);
    is_deeply($p->label_style('stroke'), [123, 213, 2], 'array color');
    $p->label_style('stroke', 'yellow');
    is($p->label_style('stroke'), 'yellow', 'color');

    $p = $construction->add_point(position => [6, 7]);
    $p->label_style('stroke', [122, 214, 67]);
    is_deeply($p->label_style('stroke'), [122, 214, 67], 'array color');
    $p->label_style('stroke', 'yellow');
    is($p->label_style('stroke'), 'yellow', 'color');
}

point;
line;
circle;
color;
