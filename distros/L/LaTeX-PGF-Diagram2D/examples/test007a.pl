#! /usr/bin/perl

use LaTeX::PGF::Diagram2D;

my $Uq = 1.0;
my $Ri = 4.0;

sub I($)
{
  my $RL = shift;
  my $back = 1000.0 * $Uq / ($Ri + $RL);
  return $back;
}

sub P($)
{
  my $RL = shift;
  my $back = $Uq * $Uq * $RL / (($RL + $Ri) * ($RL + $Ri));
  $back = 1000.0 * $back;
  return $back;
}

my $d = LaTeX::PGF::Diagram2D->new(10.0, 8.0);

$d->set_font_size(12.0);

$d->axis('b')->set_linear(0.0, 10.0)->set_grid_step(1.0)
	     ->set_tic_step(1.0)->set_unit("\\(\\Omega\\)")
	     ->set_label("\\(R_{\\text{L}}\\)")->set_omit(1);
$d->axis('l')->set_linear(0.0,  400.0)->set_grid_step(50.0)
	     ->set_tic_step(100.0)->set_unit("mA")
	     ->set_label("\\(I\\)");
$d->axis('r')->set_linear(0.0, 80.0)->set_tic_step(10.0)
	     ->set_unit("mW")->set_label("\\(P\\)")
	     ->set_tic_offset(1.0)->set_label_offset(1.4)
	     ->set_border(2.2)->set_omit(1);

my $p = $d->plot('b', 'l');
$p->set_xy_fct(\&I);

my $q = $d->plot('b', 'r');
$q->set_xy_fct(\&P);

$d->label('b', 'l', 6.5, 325.0, "\\(P\\)");
$d->label('b', 'l', 6.5, 125.0, "\\(I\\)");

$d->write("test007a.pgf");

