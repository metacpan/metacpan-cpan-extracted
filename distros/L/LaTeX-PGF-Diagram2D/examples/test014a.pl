#! /usr/bin/perl
use LaTeX::PGF::Diagram2D;
my $mp = "	0.350	 0.17
		0.355	 0.21
		0.360	 0.26
		0.365	 0.31
		0.370	 0.38
		0.375	 0.45
		0.380	 0.54
		0.385	 0.65
		0.390	 0.79
		0.395	 0.93
		0.400	 1.10
		0.405	 1.33
		0.410	 1.62
		0.415	 1.90
		0.420	 2.27
		0.425	 2.66
		0.430	 3.16
		0.435	 3.65
		0.440	 4.35
		0.445	 5.04
		0.450	 5.86
		0.455	 6.64
		0.460	 7.58
		0.465	 8.69
		0.470	 9.92
		0.475	11.20
		0.480	12.53
		0.485	13.74
		0.490	15.01	0.0
		0.495	15.07
		0.500	15.09 ";
my $d = LaTeX::PGF::Diagram2D->new(15.0, 16.0);
$d->set_font_size(12.0);
$d->axis('b')->set_linear(0.35, 0.5)->set_grid_step(0.01)
	     ->set_tic_step(0.01)->set_label('\\(U_{B1}\\)')
	     ->set_unit('V')->set_omit(1);
$d->axis('l')->set_linear(0.0,  16.0)->set_grid_step(1.0)
	     ->set_tic_step(1.0)->set_label('\\(U_{C2}\\)')
	     ->set_unit('V')->set_omit(1);
my $p = $d->plot('b', 'l');
$p->set_xy_points_text($mp);
$d->write("test014a.pgf");
