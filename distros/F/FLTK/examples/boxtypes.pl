#!/usr/bin/perl
use FLTK qw( :Boxtypes :Flags );

$N = 0;
$W = 150;
$H = 50;
$ROWS = 5;
@boxes;

$window = new Fl_Window((4 * $W), ($ROWS * $H));
$window->box(FL_FLAT_BOX);
$window->color(12);
bt("FL_NO_BOX", FL_NO_BOX);
bt("FL_FLAT_BOX",FL_FLAT_BOX);
bt("FL_UP_BOX",FL_UP_BOX);
bt("FL_DOWN_BOX",FL_DOWN_BOX);
bt("FL_THIN_UP_BOX",FL_THIN_UP_BOX);
bt("FL_THIN_DOWN_BOX",FL_THIN_DOWN_BOX);
bt("FL_ENGRAVED_BOX",FL_ENGRAVED_BOX);
bt("FL_EMBOSSED_BOX",FL_EMBOSSED_BOX);
bt("FL_BORDER_BOX",FL_BORDER_BOX);
bt("FL_SHADOW_BOX",FL_SHADOW_BOX);
bt("FL_ROUNDED_BOX",FL_ROUNDED_BOX);
bt("FL_RSHADOW_BOX",FL_RSHADOW_BOX);
bt("FL_RFLAT_BOX",FL_RFLAT_BOX);
bt("FL_OVAL_BOX",FL_OVAL_BOX);
bt("FL_OSHADOW_BOX",FL_OSHADOW_BOX);
bt("FL_OFLAT_BOX",FL_OFLAT_BOX);
bt("FL_ROUND_UP_BOX",FL_ROUND_UP_BOX);
bt("FL_ROUND_DOWN_BOX",FL_ROUND_DOWN_BOX);
bt("FL_DIAMOND_UP_BOX",FL_DIAMOND_UP_BOX);
bt("FL_DIAMOND_DOWN_BOX",FL_DIAMOND_DOWN_BOX);
$window->resizable($window);
$window->end();
$window->show();

Fl::run();

sub bt {
  my ($name, $type, $square) = @_;
  if(!defined($square)) { $square = 0; }
  my $x = $N % 4;
  my $y = int($N / 4);
  $N++;
  $x = $x * $W + 10;
  $y = $y * $H + 10;
  my $box = new Fl_Box($x, $y, ($square ? ($H - 20): ($W - 20)),
                      ($H - 20), $name);
  $box->box($type);
  $box->label_size(11);
  if($square) {
    $box->clear_flag(FL_ALIGN_MASK);
    $box->set_flag(FL_ALIGN_RIGHT);
  }
  push @boxes, $box;
}
