#! /usr/bin/perl

use LaTeX::PGF::Diagram2D;

my $d = LaTeX::PGF::Diagram2D->new(10.0, 6.0);
$d->set_font_size(12.0);

my $pi = 3.1415926;
my $t1 = 0.025; my $t2 = 0.0375; my $t3 = 0.075; my $a = 0.25;

sub U
{
  my $t = shift;
  if($t < 0.0) { $back = U($t + 1.0) }
  else {
    if($t > 1.0) {
      $back = U($t - 1.0);
    } else {
      if($t > 0.5) {
        $back = -1.0 * U($t - 0.5);
      } else {
        if($t > 0.25) {
	  $back = U(0.5 - $t);
	} else {
	  $back = (1.0 - exp(-1.0*$t/$t1)) +
	          $a * sin(2.0*$pi*$t/$t3) * exp(-1.0*$t/$t2);
	}
      }
    }
  }
  return $back;
}

$d->axis('b')->set_linear(0.0, 2.0)->set_grid_step(0.2)
	     ->set_tic_step(0.2)->set_unit("ms")
	     ->set_label("\\(t\\)")->set_omit(1);
$d->axis('l')->set_linear(-1.5,  1.5)->set_grid_step(0.5)
	     ->set_tic_step(0.5)->set_unit("V")
	     ->set_label("\\(U\\)")->set_omit(1)
	     ->set_label_offset(1.5)->set_border(2.0);

my $p = $d->plot('b', 'l');
$p->set_xy_fct(\&U)->set_intervals(500)->set_lines();

$d->write("test011a.pgf");
