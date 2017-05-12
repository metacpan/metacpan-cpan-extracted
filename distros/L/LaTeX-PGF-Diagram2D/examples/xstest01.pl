#! /usr/bin/perl
#
use LaTeX::PGF::Diagram2D;

my $mp = "	1.0	3.0	-1
		2.0	5.0	-1
		5.0	5.0	-1
		6.0	3.0	-1
		5.0	1.0	-1
		10.0	1.0	-1
		9.0	3.0	-1
		";

my $d = LaTeX::PGF::Diagram2D->new(11.0, 6.0);

$d->set_font_size(12.0);

$d->axis('b')->set_linear(0, 11.0)->set_grid_step(1.0)
	     ->set_tic_step(1)->set_label('\\(x\\)');
$d->axis('l')->set_linear(0.0,  6.0)->set_grid_step(1.0)
	     ->set_tic_step(1.0)->set_label('\\(y\\)');

my $p = $d->plot('b', 'l');
$p->set_xsplines_points_text($mp);
my $q = $d->copy_plot($p);
$q->set_lines()->set_color('blue');

$d->write("xstest01.tex");
