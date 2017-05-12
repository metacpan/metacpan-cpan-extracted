#!perl -T
use strict;
use warnings;

use Test::More tests => 144;
use Test::Exception;
use Test::Warn;
use Math::Geometry::Construction;
use Math::Vector::Real;

sub is_close {
    my ($value, $reference, $message, $limit) = @_;

    cmp_ok(abs($value - $reference), '<', ($limit || 1e-12), $message);
}

sub position_ok {
    my ($pos, $x, $y) = @_;

    ok(defined($pos), 'position is defined');
    isa_ok($pos, 'Math::Vector::Real');
    is(@$pos, 2, 'position has 2 components');

    if(defined($x)) {
	is($pos->[0], $x, "x coordinate is $x");
    }
    if(defined($y)) {
	is($pos->[1], $y, "y coordinate is $y");
    }
}

sub support_ok {
    my ($line, $pos) = @_;
    my @support;

    @support = $line->support;
    is(@support, 2, 'two support points');
    for(my $i=0;$i<2;$i++) {
	ok(defined($support[$i]), 'support point defined');
	isa_ok($support[$i], 'Math::Geometry::Construction::Point');
	position_ok($support[$i]->position, @{$pos->[$i]});
    }
}

sub constructs_ok {
    my ($construction, $args, $pos) = @_;
    my $line;

    warning_is { $line = $construction->add_line(%$args) } undef,
        'no warnings in constructor';

    ok(defined($line), 'line is defined');
    isa_ok($line, 'Math::Geometry::Construction::Line');
    support_ok($line, $pos);

    return $line;
}

sub directions_ok {
    my ($line, $parallel, $normal) = @_;
    my $dir;

    $dir = $line->parallel;
    ok(defined($dir), 'parallel defined');
    isa_ok($dir, 'Math::Vector::Real');
    is_close($dir->[0], $parallel->[0],
	     'parallel x direction is '.$parallel->[0]);
    is_close($dir->[1], $parallel->[1],
	     'parallel y direction is '.$parallel->[1]);
    $dir = $line->normal;
    ok(defined($dir), 'normal defined');
    isa_ok($dir, 'Math::Vector::Real');
    is_close($dir->[0], $normal->[0],
	     'normal x direction is '.$normal->[0]);
    is_close($dir->[1], $normal->[1],
	     'normal y direction is '.$normal->[1]);
}

sub line {
    my $construction = Math::Geometry::Construction->new;
    my $line;
    my @support;

    @support = ($construction->add_point(position => [0.1, 0.2]),
		$construction->add_point(position => [0.3, 0.4]));

    $line = constructs_ok($construction, {support => [@support]},
			  [[0.1, 0.2], [0.3, 0.4]]);
    directions_ok($line,
		  [0.2 / (sqrt(2 * 0.2**2)), 0.2 / (sqrt(2 * 0.2**2))],
		  [-0.2 / (sqrt(2 * 0.2**2)), 0.2 / (sqrt(2 * 0.2**2))]);

    $line = constructs_ok($construction, {support => [[3, 5], V(-1, 12)]},
			  [[3, 5], [-1, 12]]);
    directions_ok($line,
		  [-4 / (sqrt(4**2 + 7**2)), 7 / (sqrt(4**2 + 7**2))],
		  [-7 / (sqrt(4**2 + 7**2)), -4 / (sqrt(4**2 + 7**2))]);
}

sub defaults {
    my $construction = Math::Geometry::Construction->new;
    my $line;

    $line = constructs_ok($construction, {support => [[-1, 2], [3, 9]]},
			  [[-1, 2], [3, 9]]);
    is_deeply($line->extend, [0, 0], 'default extend');
    $line->extend(50);
    is_deeply($line->extend, [50, 50], 'can set extend');

    $line = constructs_ok($construction,
			  {support => [[-1, 2], [3, 9]], extend => 30},
			  [[-1, 2], [3, 9]]);
    is_deeply($line->extend, [30, 30], 'default extend in constructor');

    $line = constructs_ok($construction,
			  {support => [[-1, 2], [3, 9]],
			   extend  => [0, 30]},
			  [[-1, 2], [3, 9]]);
    is_deeply($line->extend, [0, 30], 'mixed extend in constructor');
}

sub vector_and_line {
    my $construction = Math::Geometry::Construction->new;
    my $l;
    my $vector;
    my $value;
    my @template;

    $l = $construction->add_line(support => [[1, 2], [3, 5]]);

    @template = ([$l, [2, 3]]);

    foreach(@template) {
	$vector = Math::Geometry::Construction::Vector->new
	    (point_point => $_->[0]);
	ok(defined($vector), 'vector is defined');
	isa_ok($vector, 'Math::Geometry::Construction::Vector');
	$value = $vector->value;
	ok(defined($value), 'value is defined');
	isa_ok($value, 'Math::Vector::Real');
	is($value->[0], $_->[1]->[0], 'x = '.$_->[1]->[0]);
	is($value->[1], $_->[1]->[1], 'y = '.$_->[1]->[1]);
    }

    constructs_ok($construction,
		  {support => [$l, [6, 7]]},
		  [[2, 3], [6, 7]]);

    $vector = Math::Geometry::Construction::Vector->new
	(point => $l->single_support(0));
    $value  = $vector->value;
    is($value->[0], 1, 'x = 1');
    is($value->[1], 2, 'y = 2');
    foreach('vector', 'point_point') {
	my $predicate = "_has_${_}";
	ok(!$vector->$predicate, "$_ is clear");
    }

    $vector->point_point($l);
    $value  = $vector->value;
    is($value->[0], 2, 'x = 2');
    is($value->[1], 3, 'y = 3');
    foreach('vector', 'point') {
	my $predicate = "_has_${_}";
	ok(!$vector->$predicate, "$_ is clear");
    }
}

sub draw {
    my $construction;

    $construction = Math::Geometry::Construction->new;
    $construction->add_line(support => [[1, 2], [3, 5]]);

    lives_ok(sub { $construction->as_svg(width => 800, height => 300) },
	     'construction with line lives through as_svg');
    lives_ok(sub { $construction->as_tikz(width => 800, height => 300) },
	     'construction with line lives through as_tikz');
}

line;
defaults;
vector_and_line;
draw;
