#!/usr/bin/perl -w

use strict;
use Gtk2 '-init';
use Math::JSpline;

my($wx,$wy);

sub cb_da_event { # This is the first thing to run after the window stuff all gets set up
  my($this, $event) = @_;
  return unless ($event->type eq "expose");

  my @points=(50,50,250,50,250,250,50,250);	# square
  my %s=(0=>'red',0.5=>'green',1=>'cyan');	# the "s" in Js, and colours 

  foreach my $refinement(1,2,6) {
    foreach my $sl(sort keys %s) {
      my @spline= &xy_to_points( &JSpline( $refinement,$sl,$sl,3,&points_to_xy(@points)) );
      &draw_line($this, [@spline], $s{$sl});
    } # sl
    &draw_line($this, [@points,$points[0],$points[1]], "black");	# Show our points (drawing back to the start as well)
    for(my $i=0;$i<$#points;$i+=2){ $points[$i]+=300; }
  } # refinement
} # cb_da_Event



sub xy_to_points {
  my($px,$py)=@_; my @ppoints;
  for(my $i=0;$i<=$#{$px};$i++) {
    push @ppoints,$px->[$i];
    push @ppoints,$py->[$i];
  }
  return(@ppoints);
} # xy_to_points

sub points_to_xy {
  my @ppoints=@_; my(@x,@y);
  foreach (@ppoints) {if($#x>$#y){push @y,$_}else{push @x,$_}}
  return (\@x,\@y);
} # points_to_xy



sub create_widgets {
  my $mw = Gtk2::Window->new();
  my $screen = $mw->get_screen();
  my($sx,$sy)=($screen->get_width(),$screen->get_height());
  my $w_drawing_area = Gtk2::DrawingArea->new();
  $mw->add($w_drawing_area);
  $sx-=90; $sy-=72; # fit on my vnc screen
  $wx=$sx-1; $wy=$sy-1;
  $w_drawing_area->set_size_request($sx,$sy);
  $w_drawing_area->signal_connect(event=>\&cb_da_event);

  $mw->set_events ([qw/exposure-mask leave-notify-mask button-press-mask pointer-motion-mask pointer-motion-hint-mask/]); 
  $mw->signal_connect (button_press_event => sub { Gtk2->main_quit; }); # exit on any click
  $mw->show_all;
} # create_widgets


&create_widgets();

main Gtk2;

exit(0); # never reaches here (above is the end)




########################
# Gtk2 helper routines # 
########################

{
  my %allocated_colors;
  sub get_color {
    my ($colormap, $name) = @_;
    my $ret;
    if ($ret = $allocated_colors{$name}) { return $ret; }
    my $color = Gtk2::Gdk::Color->parse($name);
    $colormap->alloc_color($color,1,1);
    $allocated_colors{$name} = $color;
    return $color;
  } # get_color
} # private global

sub draw_line {
  my($widget, $line, $color)= @_;
  my $colormap = $widget->window->get_colormap;
  my $gc = $widget->{gc} || new Gtk2::Gdk::GC $widget->window;
  $gc->set_foreground(get_color($colormap, $color));
  $widget->window->draw_lines( $gc, @$line );
} #draw_line

