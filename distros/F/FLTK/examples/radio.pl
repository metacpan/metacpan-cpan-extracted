#!/usr/bin/perl

use FLTK qw( :Boxtypes :Flags );

$window = new Fl_Window(380, 274, "Radio buttons and Tooltips");
$window->tooltip("This is a window");

  $btn = new Fl_Button(20, 10, 160, 30, "Fl_Button");
  $btn->tooltip("This is a button");

  $rbtn = new Fl_Return_Button(20, 50, 160, 30, "Fl_Return_Button");
  $rbtn->shortcut(0xff0d);
  $rbtn->tooltip("This is a return button");
  
  $lbtn = new Fl_Light_Button(20, 90, 160, 30, "Fl_Light_Button");
  $lbtn->tooltip("This is a light button!  This particular button has a very long tooltip.  This tooltip should demonstrate that very long tooltips are wrapped across multiple lines.");

  $cbtn = new Fl_Check_Button(20, 130, 160, 30, "Fl_Check_Button");
  $cbtn->tooltip("This is a check button");

  $rndbtn = new Fl_Round_Button(20, 170, 160, 30, "Fl_Round_Button");
  $rndbtn->tooltip("This is a round button");

  $g1 = new Fl_Group(190, 10, 70, 120);
  $g1->tooltip("This is a group");

    $c1 = new Fl_Check_Button(190, 10, 70, 30, "radio");
    $c1->type(102);
    $c1->tooltip("This is a check button");

    $c2 = new Fl_Check_Button(190, 40, 70, 30, "radio");
    $c2->type(102);
    $c2->tooltip("This is a check button");

    $c3 = new Fl_Check_Button(190, 70, 70, 30, "radio");
    $c3->type(102);
    $c3->tooltip("This is a check button");

    $c4 = new Fl_Check_Button(190, 100, 70, 30, "radio");
    $c4->type(102);
    $c4->tooltip("This is a check button");

  $g1->end();
  $g2 = new Fl_Group(270, 10, 90, 115);
  $g2->box(FL_THIN_UP_BOX);
  $g2->tooltip("This is a group");

    $b1 = new Fl_Button(280, 20, 20, 20, "radio");
    $b1->type(102);
    $b1->align(FL_ALIGN_RIGHT);
    $b1->tooltip("This is the first button of the group");

    $b2 = new Fl_Button(280, 45, 20, 20, "radio");
    $b2->type(102);
    $b2->align(FL_ALIGN_RIGHT);
    $b2->tooltip("This is the second button of the group");

    $b3 = new Fl_Button(280, 70, 20, 20, "radio");
    $b3->type(102);
    $b3->align(FL_ALIGN_RIGHT);
    $b3->tooltip("This is the third button of the group");

    $b4 = new Fl_Button(280, 95, 20, 20, "radio");
    $b4->type(102);
    $b4->align(FL_ALIGN_RIGHT);
    $b4->tooltip("This is the fourth button of the group");

  $g2->end();

  $ttlb = new Fl_Light_Button(120, 230, 130, 30, "Show Tooltips");
  $ttlb->value(1);
  $ttlb->callback(\&cb_ttlb);
  $ttlb->tooltip("This button enables or disables tooltips");
$window->end();

$window->show();
Fl::run();

sub cb_ttlb {
  my ($w) = @_;
  Fl_Tooltip::enable($w->value());
  my $x = 0;
  my $y = 0;
  Fl::get_mouse($x, $y);
  print "Mouse position: $x, $y\n";
}
