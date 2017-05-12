#!/usr/bin/perl

use FLTK qw( :Boxtypes :Keytypes :Labeltypes);

$window = new Fl_Window(321, 324);
$tabs = new Fl_Tabs(10, 10, 300, 200);
$tabs->color(47);
$tabs->selection_color(15);
  $g1 = new Fl_Group(10, 30, 300, 180, "Label1");
  $g1->hide();
    $i1 = new Fl_Input(60, 50, 240, 40, "input:");
    $i2 = new Fl_Input(60, 90, 240, 30, "input2:");
    $i3 = new Fl_Input(60, 120, 240, 80, "input3:");
  $g1->end();
  $g2 = new Fl_Group(10, 30, 300, 180, "tab2");
  $g2->hide();
    $b1 = new Fl_Button(20, 60, 100, 30, "button1");
    $i4 = new Fl_Input(140, 100, 100, 30, "input in box2");
    $b2 = new Fl_Button(30, 140, 260, 30, "This is stuff inside the Fl_Group \"tab2\"");
  $g2->end();
  $g3 = new Fl_Group(10, 30, 300, 180, "tab3");
  $g3->hide();
    $b3 = new Fl_Button(20, 60, 60, 80, "button2");
    $b4 = new Fl_Button(80, 60, 60, 80, "button");
    $b5 = new Fl_Button(140, 60, 60, 80, "button");
  $g3->end();
  $g4 = new Fl_Group(10, 30, 300, 180, "tab4");
#  $g5->label_font(); # Fonts not done yet.
  $g4->hide();
    $b6 = new Fl_Button(20, 50, 60, 110, "button2");
    $b7 = new Fl_Button(80, 50, 60, 110, "button");
    $b8 = new Fl_Button(140, 50, 60, 110, "button");
  $g4->end();
  $g5 = new Fl_Group(10, 30, 300, 180, "     tab5     ");
  $g5->label_type(FL_ENGRAVED_LABEL);
  $g5->hide();
    $b9 = new Fl_Button(20, 80, 60, 80, "button2");
    $b10 = new Fl_Button(90, 90, 60, 80, "button");
  $g5->end();
$tabs->end();
$window->resizable($window);

$i5 = new Fl_Input(60, 220, 130, 30, "inputA:");
$i6 = new Fl_Input(60, 250, 250, 30, "inputB:");
$cancel = new Fl_Button(180, 290, 60, 30, "cancel");
$cancel->callback(sub { exit 1;});
$ok = new Fl_Return_Button(250, 290, 60, 30, "OK");
$ok->shortcut(0xff0d);
$ok->callback(sub { exit 0;});

$window->end();

$window->show();
Fl::run();

