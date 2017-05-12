#! /usr/bin/perl
#
use LaTeX::PGF::Diagram2D;

my $mp = "	1	2	-1
		2	2	0
		3	2	0.5
		4	2	1
		5	4	-1
		6	6	-0.5
		7	6	-1
		8	6	-1
		9	6	-1
		";

my $d = LaTeX::PGF::Diagram2D->new(10, 8);
$d->set_font_size(12.0);

$d->axis('b')->set_linear(0.0, 10.0)->set_grid_step(1.0)
	     ->set_tic_step(1.0)->set_label('\\(x\\)');
$d->axis('l')->set_linear(0.0,  8.0)->set_grid_step(1.0)
	     ->set_tic_step(1.0)->set_label('\\(y\\)');

my $p = $d->plot('b', 'l');
$p->set_xsplines_points_text($mp, 1.0);

my $q = $d->copy_plot($p);
$q->set_dots();

$d->write("test024a.pgf");
