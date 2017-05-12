#! /usr/bin/perl
use LaTeX::PGF::Diagram2D;

my $d = LaTeX::PGF::Diagram2D->new(12.0, 8.0);
$d->set_font_size(12.0);

sub vudb($)
{
  my $x = shift;
  my $back = -10.0 * log($x * $x + 1) / log(10.0);
  return $back;
}

sub dvudbdx($)
{
  my $x = shift;
  my $back = -20.0 * $x / (($x * $x + 1) * log(10.0));
  return $back;
}

$d->axis('b')->set_logarithmic(0.001, 1000.0)
	     ->set_grid_step(10.0)->set_tic_step(10.0)
	     ->set_label("\\(\\frac{f}{f_{\\text{G}}}\\)");

$d->axis('l')->set_linear(-60.0,  20.0)->set_grid_step(20.0)
	     ->set_tic_step(20.0)->set_unit("dB")
	     ->set_label("\\(v_U\\)")
	     ->set_label_offset(1.5)->set_border(2.0);

my $p = $d->plot('b', 'l'); $p->set_xy_fct(\&vudb, \&dvudbdx);
$d->write("test012a.pgf");

