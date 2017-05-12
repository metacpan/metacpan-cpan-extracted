#! /usr/bin/perl

use LaTeX::PGF::Diagram2D;

my $Uq = 1.0;
my $Ri = 4.0;

sub I($)
{
  my $RL = shift;
  my $back = $Uq / ($Ri + $RL);
  return $back;
}


my $d = LaTeX::PGF::Diagram2D->new(10.0, 6.0);

$d->set_font_size(12.0);

$d->axis('b')->set_linear(0.0, 10.0)->set_grid_step(1.0)
	     ->set_tic_step(1.0)->set_unit("\\(\\Omega\\)")
	     ->set_label("\\(R_{\\text{L}}\\)")->set_omit(1);
$d->axis('l')->set_linear(0.0,  0.3)->set_grid_step(0.05)
	     ->set_tic_step(0.1)->set_unit("A")
	     ->set_label("\\(I\\)");

my $p = $d->plot('b', 'l');
$p->set_xy_fct(\&I)->finish();

$Ri = 6.0;
my $q = $d->plot('b', 'l');
$q->set_xy_fct(\&I)->finish();

$d->write("test004a.pgf");

