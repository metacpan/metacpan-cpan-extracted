#!/usr/bin/perl
use FLTK qw( :Utils :When :Colors);

$when = 0;

$window = new Fl_Window(400, 350);
  $y = 10;
  push @input, new Fl_Input(70, $y, 300, 23, "Normal:");
  $y += 27;
  push @input, new Fl_Float_Input(70, $y, 300, 23, "Float:"); 
  $y += 27;
  push @input, new Fl_Int_Input(70, $y, 300, 23, "Int:");
  $y += 27;
  push @input, new Fl_Secret_Input(70, $y, 300, 23, "Secret:");
  $y += 27;
  push @input, new Fl_Wordwrap_Input(70, $y, 300, 100, "Wordwrap:");
  $y += 105;

  foreach $i (@input) {
    $i->when(0);
    $i->callback(\&cb);
  }
  
  $y1 = $y;

  push @button, new Fl_Toggle_Button(10, $y, 200, 23, 'FL_WHEN_&CHANGED');
  $button[$#button]->callback(\&toggle_cb, FL_WHEN_CHANGED);
  $y += 23;
  
  push@button, new Fl_Toggle_Button(10, $y, 200, 23, 'FL_WHEN_&RELEASE');
  $button[$#button]->callback(\&toggle_cb, FL_WHEN_RELEASE);
  $y += 23;

  push @button, new Fl_Toggle_Button(10, $y, 200, 23, 'FL_WHEN_&ENTER_KEY');
  $button[$#button]->callback(\&toggle_cb, FL_WHEN_ENTER_KEY);
  $y += 23;

  push @button, new Fl_Toggle_Button(10, $y, 200, 23, 'FL_WHEN_&NOT_CHANGED');
  $button[$#button]->callback(\&toggle_cb, FL_WHEN_NOT_CHANGED);
  $y += 23;
  $y += 5;

  push @button, new Fl_Button(10, $y, 200, 23, '&print changed()');
  $button[$#button]->callback(\&button_cb);
  $y += 23;

  push @button, new Fl_Button(220, $y1, 100, 23, "color");
  $button[$#button]->color($input[0]->color());
  $button[$#button]->callback(\&color_cb, 0);
  $button[$#button]->label_color(fl_contrast(FL_BLACK,$button[$#button]->color()));
  $y1 += 23;

  push @button, new Fl_Button(220, $y1, 100, 23, "selection_color");
  $button[$#button]->color($input[0]->selection_color());
  $button[$#button]->callback(\&color_cb, 1);
  $button[$#button]->label_color(fl_contrast(FL_BLACK,$button[$#button]->color()));
  $y1 += 23;

  push @button, new Fl_Button(220, $y1, 100, 23, "text_color");
  $button[$#button]->color($input[0]->text_color());
  $button[$#button]->callback(\&color_cb, 2);
  $button[$#button]->label_color(fl_contrast(FL_BLACK,$button[$#button]->color()));

  $window->resizable($window);
$window->end();
$window->show();
Fl::run();

sub cb {
  my ($w) = @_;
  my $l = $w->label();
  my $v;

  # How to 'cast' a widget pointer in Perl
  bless $w, "Fl_Input" unless (widget_type($w) =~ /_Input/);
  $v = $w->value();
    
  print "Callback for $l '$v'\n";
}

sub toggle_cb {
  my ($w, $v) = @_;
  bless $w, "Fl_Toggle_Button" 
        unless (widget_type($w) eq "Fl_Toggle_Button");

  if($w->value()) {
    $when |= $v;
  } else {
    $when &= ~$v;
  }

  foreach my $i (@input) {
    $i->when($when);
  }
}

sub button_cb {
  my ($w) = @_;
  foreach my $i (@input) {
    if($i->changed()) {
      $i->clear_changed();
      print $i->label()." '".$i->value()."'\n";
    }
  }
}

sub color_cb {
  my ($w, $v) = @_;
  my $c;
  
  my $in = $input[0];
  if($v == 0) {
    $c = $in->text_background();
  } elsif($v == 1) {
    $c = $in->selection_color();
  } else {
    $c = $in->text_color();
  }

  $c = fl_show_colormap($c);

  my $i;
  my $sc;
  foreach $i (@input) {
    if($v == 0) {
      $i->text_background($c);
    } elsif($v == 1) {
      $i->selection_color($c);
    } else {
      $i->text_color($c);
    }
    $i->selection_text_color(fl_contrast($in->text_color(), 
                                         $in->selection_color()));
  }

  $w->color($c);
  $w->label_color(fl_contrast(FL_BLACK, $c));
  Fl::redraw();
}
