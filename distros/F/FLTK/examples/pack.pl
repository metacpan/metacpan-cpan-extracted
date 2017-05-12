#!/usr/bin/perl

use FLTK qw( :Boxtypes :Slidertypes :Buttons :Flags);

$window = new Fl_Window(365, 525);
  $scroll = new Fl_Scroll(10, 10, 345, 285);
    $pack = new Fl_Pack(10, 10, 345, 285);
    $pack->box(FL_DOWN_BOX);
      $c = 1;
      $x = 35;
      while($c < 25) {
        push @buttons, new Fl_Button($x, $x, 25, 25);
        $buttons[$#buttons]->copy_label("b$c");
        $c++;
        $x += 10;
      }
    $pack->end();
  $window->resizable($pack);
  $scroll->end();

  $horiz = new Fl_Radio_Light_Button(10, 325, 175, 25, "HORIZONTAL");
  $horiz->value(1);
  $horiz->callback(\&type_cb, Fl_Pack::HORIZONTAL);

  $vert = new Fl_Radio_Light_Button(10, 350, 175, 25, "VERTICAL");
  $vert->callback(\&type_cb, Fl_Pack::VERTICAL);

  $slider = new Fl_Value_Slider(50, 375, 295, 25, "spacing:");
  $slider->clear_flag(FL_ALIGN_MASK);
  $slider->set_flag(FL_ALIGN_LEFT);
  $slider->type(FL_HORIZONTAL);
  $slider->range(0,30);
  $slider->step(1);
  $slider->callback(\&spacing_cb);
$window->end();

$window->show();
Fl::run();

sub type_cb {
  my ($w, $type) = @_;
  foreach my $button (@buttons) {
    $button->resize(0,0,25,25);
  }
  $pack->resize($scroll->x(), $scroll->y(), $scroll->w(), $scroll->h());
  $pack->type($type);
  $pack->redraw();
  $scroll->redraw();
}

sub spacing_cb {
  my ($w) = @_;
  $pack->spacing($w->value());
  $scroll->redraw();
}
