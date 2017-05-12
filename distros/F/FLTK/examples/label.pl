#!/usr/bin/perl
use FLTK qw( :Flags :When :Labeltypes );

$window = new Fl_Double_Window(400, 400);
  $input = new Fl_Input(50, 375, 350, 25);
  $input->value("The quick brown fox jumps over the lazy dog.");
  $input->when(FL_WHEN_CHANGED);
  $input->callback(\&input_cb);

  $sizes = new Fl_Hor_Value_Slider(50, 350, 350, 25, "Size:");
  $sizes->clear_flag(FL_ALIGN_MASK);
  $sizes->set_flag(FL_ALIGN_LEFT);
  $sizes->range(1,64);
  $sizes->step(1);
  $sizes->value(14);
  $sizes->callback(\&size_cb);

  $fonts = new Fl_Hor_Value_Slider(50,325,350,25,"Font:");
  $fonts->clear_flag(FL_ALIGN_MASK);
  $fonts->set_flag(FL_ALIGN_LEFT);
  $fonts->range(0,15);
  $fonts->step(1);
  $fonts->value(0);
  $fonts->callback(\&font_cb);

  $g = new Fl_Group(50, 300, 350, 25);

  $leftb = new Fl_Toggle_Button(50,300,50,25,"left");
  $leftb->callback(\&button_cb);
  $rightb = new Fl_Toggle_Button(100,300,50,25,"right");
  $rightb->callback(\&button_cb);
  $topb = new Fl_Toggle_Button(150,300,50,25,"top");
  $topb->callback(\&button_cb);
  $bottomb = new Fl_Toggle_Button(200,300,50,25,"bottom");
  $bottomb->callback(\&button_cb);
  $insideb = new Fl_Toggle_Button(250,300,50,25,"inside");
  $insideb->callback(\&button_cb);
  $wrapb = new Fl_Toggle_Button(300,300,50,25,"wrap");
  $wrapb->callback(\&button_cb);
  $clipb = new Fl_Toggle_Button(350,300,50,25,"clip");
  $clipb->callback(\&button_cb);
  $g->end();

  $c = new Fl_Choice(50, 275, 200, 25);
  $c->begin();
    push @menu, new Fl_Item("FL_NORMAL_LABEL");
    $menu[$#menu]->callback(\&label_cb, FL_NORMAL_LABEL);
    push @menu, new Fl_Item("FL_SYMBOL_LABEL");
    $menu[$#menu]->callback(\&label_cb, FL_SYMBOL_LABEL, 1);
    push @menu, new Fl_Item("FL_SHADOW_LABEL");
    $menu[$#menu]->callback(\&label_cb, FL_SHADOW_LABEL);
    push @menu, new Fl_Item("FL_ENGRAVED_LABEL");
    $menu[$#menu]->callback(\&label_cb, FL_ENGRAVED_LABEL);
    push @menu, new Fl_Item("FL_EMBOSSED_LABEL");
    $menu[$#menu]->callback(\&label_cb, FL_EMBOSSED_LABEL);
  $c->end();

  $text = new Fl_Box(100, 75, 200, 100, $input->value());
  $text->box(FL_ENGRAVED_BOX);
  $text->clear_flag(FL_ALIGN_MASK);
  $text->set_flag(FL_ALIGN_CENTER);

  $window->resizable($text);
$window->end();
$window->show();
Fl::run();

sub button_cb {
  my ($w) = @_;
  my $i = 0;

  if($leftb->value()) { $i |= FL_ALIGN_LEFT; }
  if($rightb->value()) { $i |= FL_ALIGN_RIGHT; }
  if($topb->value()) { $i |= FL_ALIGN_TOP; }
  if($bottomb->value()) { $i |= FL_ALIGN_BOTTOM; }
  if($insideb->value()) { $i |= FL_ALIGN_INSIDE; }
  if($clipb->value()) { $i |= FL_ALIGN_CLIP; }
  if($wrapb->value()) { $i |= FL_ALIGN_WRAP; }

  $text->align($i);
  $window->redraw();
}

sub font_cb {
  my ($w) = @_;
  print "Fonts not implemented yet.\n";
}

sub size_cb {
  my ($w) = @_;
  $text->label_size(int($sizes->value()));
  $window->redraw();
}

sub input_cb {
  my ($w) = @_;
  $text->label($input->value());
  $window->redraw();
}

sub label_cb {
  my ($w, $v, $f) = @_;
  $text->label_type($v);
  if($f && !($input->value() =~ /^@/)) {
    $input->value('@->');
    $text->label('@->');
  }
  $window->redraw();
}
