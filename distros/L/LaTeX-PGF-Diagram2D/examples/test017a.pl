#! /usr/bin/perl
use LaTeX::PGF::Diagram2D;
my $mp = "	1	2
		2	2
		3	2
		4	2
		5	4
		6	6
		7	6
		8	6
		9	6
		";
sub f
{
  my $x = shift;
  my $y = 1.7647e-16  * $x * $x * $x * $x * $x * $x * $x * $x
        - 1.9841e-3   * $x * $x * $x * $x * $x * $x * $x
	+ 6.9444e-2   * $x * $x * $x * $x * $x * $x
	- 9.8056e-1   * $x * $x * $x * $x * $x
	+ 7.1528      * $x * $x * $x * $x
	- 2.8722e1    * $x * $x * $x
	+ 6.2778e1    * $x * $x
	- 6.8295e1    * $x
	+ 30.0 ;
  return $y;
}
sub dfdx
{
  my $x = shift;
  my $y = 8.0 * 1.7647e-16  * $x * $x * $x * $x * $x * $x * $x
        - 7.0 * 1.9841e-3   * $x * $x * $x * $x * $x * $x
	+ 6.0 * 6.9444e-2   * $x * $x * $x * $x * $x
	- 5.0 * 9.8056e-1   * $x * $x * $x * $x
	+ 4.0 * 7.1528      * $x * $x * $x
	- 3.0 * 2.8722e1    * $x * $x
	+ 2.0 * 6.2778e1    * $x
	- 6.8295e1 ;
  return $y;
}
my $d = LaTeX::PGF::Diagram2D->new(10, 8);
$d->set_font_size(12.0);
$d->axis('b')->set_linear(0.0, 10.0)->set_grid_step(1.0)
	     ->set_tic_step(1.0)->set_label('\\(x\\)');
$d->axis('l')->set_linear(0.0,  8.0)->set_grid_step(1.0)
	     ->set_tic_step(1.0)->set_label('\\(y\\)');
my $p = $d->plot('b', 'l');
$p->set_xy_points_text($mp)->set_dots();

my $q = $d->plot('b', 'l');
$q->set_xy_fct(\&f, \&dfdx)->set_range(1.0, 9.0);

$d->write("test017a.pgf");
