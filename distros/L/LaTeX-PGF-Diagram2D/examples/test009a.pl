#! /usr/bin/perl
use LaTeX::PGF::Diagram2D;
my $tau = 2.0 * 3.1415926; my $end = 6.0 * 3.1415926;
sub xfct($)
{
  my $t = shift; my $back = 5.0 * exp(-1.0*$t/$tau)*cos($t);
  return $back;
}
sub yfct($)
{
  my $t = shift; my $back = 5.0 * exp(-1.0*$t/$tau)*sin($t);
  return $back;
}
sub dxdt($)
{
  my $t = shift;
  my $back =
  (-1.0*(5.0*$tau*sin($t)+5.0*cos($t))*exp(-1.0*$t/$tau))/$tau;
  return $back;
}
sub dydt($)
{
  my $t = shift;
  my $back =
  ((5.0*$tau*cos($t)-5.0*sin($t))*exp(-1.0*$t/$tau))/$tau;
  return $back;
}

my $d = LaTeX::PGF::Diagram2D->new(10.0, 10.0);
$d->set_font_size(12.0);
$d->axis('b')->set_linear(-5.0, 5.0)->set_grid_step(1.0)
  ->set_tic_step(1.0)->set_label('\\(x\\)');;
$d->axis('l')->set_linear(-5.0,  5.0)->set_grid_step(1.0)
  ->set_tic_step(1.0)->set_label('\\(y\\)');

my $p = $d->plot('b', 'l');
$p->set_parametric_fct(0.0,$end,\&xfct,\&yfct,\&dxdt,\&dydt)
  ->set_intervals(100);

$d->write("test009a.pgf");
