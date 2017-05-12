#! /usr/bin/perl
use LaTeX::PGF::Diagram2D;
my $mp = "	0.350	 0.17	1
		0.355	 0.21	1
		0.360	 0.26	1
		0.365	 0.31	1
		0.370	 0.38	1
		0.375	 0.45	1
		0.380	 0.54	1
		0.385	 0.65	1
		0.390	 0.79	1
		0.395	 0.93	1
		0.400	 1.10	1
		0.405	 1.33	1
		0.410	 1.62	1
		0.415	 1.90	1
		0.420	 2.27	1
		0.425	 2.66	1
		0.430	 3.16	1
		0.435	 3.65	1
		0.440	 4.35	1
		0.445	 5.04	1
		0.450	 5.86	1
		0.455	 6.64	1
		0.460	 7.58	1
		0.465	 8.69	1
		0.470	 9.92	1
		0.475	11.20	1
		0.480	12.53	1
		0.485	13.74	1
		0.490	15.01	-.5
		0.495	15.07	1
		0.500	15.09	1 ";
my $d = LaTeX::PGF::Diagram2D->new(15.0, 16.0);
$d->set_font_size(12.0);
$d->axis('b')->set_linear(0.35, 0.5)->set_grid_step(0.01)
	     ->set_tic_step(0.01)->set_label('\\(U_{B1}\\)')
	     ->set_unit('V')->set_omit(1);
$d->axis('l')->set_linear(0.0,  16.0)->set_grid_step(1.0)
	     ->set_tic_step(1.0)->set_label('\\(U_{C2}\\)')
	     ->set_unit('V')->set_omit(1);
my $p = $d->plot('b', 'l'); $p->set_xsplines_points_text($mp);
my $q = $d->copy_plot($p);  $q->set_dots();
$d->write("test015a.pgf");
