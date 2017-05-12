#!/usr/bin/perl
use FLTK qw( :Boxtypes :Flags );

$0 =~ s/\.\///;
$window = new Fl_Window(300, 300, "$0");
$window->box(FL_NO_BOX);
$window->resizable($window);
  $tile = new Fl_Tile(0, 0, 300, 300);
    $box0 = new Fl_Group(0, 0, 150, 150, "0");
    $box0->box(FL_DOWN_BOX);
    $box0->color(9);
    $box0->label_size(36);
    $box0->set_flag(FL_ALIGN_CLIP);
  
      $but = new Fl_Button(20, 20, 100, 30, "Button");
    $box0->end();

    $w1 = new Fl_Window(150, 0, 150, 150, "1");
    $w1->box(FL_DOWN_BOX);
    $w1->color(39);
      $box1 = new Fl_Box(0, 0, 150, 150, "1\nThis is a\nchild\nX window");
      $box1->color(19);
      $box1->label_size(18);
      $box1->set_flag(FL_ALIGN_CLIP);
    $w1->resizable($box1);
    $w1->end();

    $box2a = new Fl_Box(0, 150, 70, 150, "2a");
    $box2a->box(FL_DOWN_BOX);
    $box2a->color(12);
    $box2a->label_size(36);
    $box2a->set_flag(FL_ALIGN_CLIP);

    $box2b = new Fl_Box(70, 150, 80, 150, "2b");
    $box2b->box(FL_DOWN_BOX);
    $box2b->color(13);
    $box2b->label_size(36);
    $box2b->set_flag(FL_ALIGN_CLIP);

    $box3a = new Fl_Box(150, 150, 150, 70, "3a");
    $box3a->box(FL_DOWN_BOX);
    $box3a->color(12);
    $box3a->label_size(36);
    $box3a->set_flag(FL_ALIGN_CLIP);

    $box3b = new Fl_Box(150, (150 + 70), 150, 80, "3b");
    $box3b->box(FL_DOWN_BOX);
    $box3b->color(13);
    $box3b->label_size(36);
    $box3b->set_flag(FL_ALIGN_CLIP);

    $r = new Fl_Box(10, 0, (300 - 10), (300 - 10));

  $tile->resizable($r);
  $tile->end();
$window->end();

$window->show();
$w1->show();
Fl::run();
