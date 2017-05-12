#!/usr/bin/perl
use FLTK;

$window = new Fl_Window(320, 170);
push @buttons, new Fl_Button(10, 10, 130, 30, "Fl_Button");
push @buttons, new Fl_Return_Button(150, 10, 160, 30, "Fl_Return_Button");
push @buttons, new Fl_Repeat_Button(10,50,130,30,"Fl_Repeat_Button");
push @buttons, new Fl_Radio_Button(150,50,160,30,"Fl_Radio_Button");
push @buttons, new Fl_Radio_Button(150,90,160,30,"Fl_Radio_Button");
push @buttons, new Fl_Light_Button(10,90,130,30,"Fl_Light_Button");
push @buttons, new Fl_Check_Button(150,130,160,30,"Fl_Check_Button");
push @buttons, new Fl_Highlight_Button(10,130,130,30,"Fl_Highlight_Button");

$window->resizable($window);
$window->end();
$window->show();
Fl::run();
