=head1 NAME

Deliantra::MapWidget - Gtk2 widget displaying cf maps

=head1 SYNOPSIS

  use Deliantra::MapWidget;

=head1 DESCRIPTION

=head2 METHODS

=over 4

=cut

package Deliantra::MapWidget;

use common::sense;

use Glib;
use Gtk2;
use Storable ();

use Deliantra;

use Glib::Object::Subclass
   'Gtk2::DrawingArea',
   signals => {
      stack_change => {
         flags       => [qw/run-last/],
         return_type => undef,
         param_types => ["Glib::Int", "Glib::Int", "Glib::Scalar"],
         class_closure => \&set,
      },
      swap_stack_change => {
         flags       => [qw/run-last/],
         return_type => undef,
         param_types => ["Glib::Int", "Glib::Int", "Glib::Scalar"],
         #class_closure => \&set,
      },
   };

use List::Util qw(min max);

sub INIT_INSTANCE {
   my ($self) = @_;

   $self->signal_connect (destroy => sub {
      my ($self) = @_;

      $self->{tip}->destroy if $self->{tip};

      %$self = ();

      0
   });
   $self->signal_connect (realize => sub {
      my ($self) = @_;

      $self->{window} = $self->window;

      1
   });

   $self->set_redraw_on_allocate (0);
   $self->double_buffered (0);

   $self->{tooltip} = -1; # need focus in first

   # reduces unnecessary redraws
   $self->signal_connect (focus_in_event  => sub { $self->enable_tooltip;  1 });
   $self->signal_connect (focus_out_event => sub { $self->disable_tooltip; 1 });

   $self->signal_connect_after (enter_notify_event => sub { $self->update_tooltip; 0 });
   $self->signal_connect_after (leave_notify_event => sub { $self->update_tooltip; 0 });

   $self->signal_connect (size_request => sub {
      $_[1]->width  (TILESIZE);
      $_[1]->height (TILESIZE);

      1
   });

   $self->signal_connect (expose_event => sub { $self->expose ($_[1]); 1 });

   $self->signal_connect_after (configure_event => sub {
      $self->set_viewport ($self->{x}, $self->{y});

      0
   });

   $self->signal_connect (button_press_event => sub {
      my ($self, $event) = @_;

      my ($x, $y) = ($event->x, $event->y);

#      warn "yuna ", $_[1]->button, " * ", $_[1]->state, "\n";#d#
      if (($_[1]->button == 2 || ($_[1]->button == 1 && $_[1]->state * ["mod1-mask", "meta-mask"]))
          && !$self->{in_drag}) {
         $self->disable_tooltip;

         $_[0]->grab_focus;
         $self->{in_drag} = [$self->{x}, $self->{y}, $x, $y];
         return 1;
      }

      0
   });

   $self->signal_connect (motion_notify_event => sub {
      my ($self) = @_;

      $self->update_tooltip;

      if (my $di = $self->{in_drag}) {
         my ($x, $y) = $self->get_pointer;

         $self->set_viewport (
            $di->[0] + $di->[2] - $x,
            $di->[1] + $di->[3] - $y,
         );

         return 1;
      }

      0
   });

   $self->signal_connect (button_release_event => sub {
      my ($self) = @_;

      $self->enable_tooltip 
         if delete $self->{in_drag};

      0
   });

   # gtk+ supports no motion compression, a major lacking feature. we have to pay for the
   # workaround with incorrect behaviour and extra server-turnarounds.
   $self->add_events ([qw(button_press_mask button_release_mask button-motion-mask
                          pointer-motion-mask pointer-motion-hint-mask
                          enter-notify-mask leave-notify-mask)]);
   $self->can_focus (1);

#   $self->signal_connect (key_press_event => sub { $self->handle_key ($_[1]->keyval, $_[1]->state) });
}

sub enable_tooltip {
   my ($self) = @_;

   $self->{tooltip}++;
   $self->update_tooltip;
}

sub disable_tooltip {
   my ($self) = @_;

   $self->{tooltip}--;
   $self->update_tooltip;
}

sub overlay {
   my ($self, $name, $x, $y, $w, $h, $cb) = @_;

   if (my $ov = delete $self->{overlay}{$name}) {
      my ($x, $y, $w, $h) = @$ov;

      $self->queue_draw_area ($x - $self->{x}, $y - $self->{y}, $w, $h);
   }

   if ($w && $h) {
      $self->{overlay}{$name} = [$x, $y, $w, $h, $cb];

      $self->queue_draw_area ($x - $self->{x}, $y - $self->{y}, $w, $h);
   }
}

sub update_tooltip {
   my ($self) = @_;

   if ($self->{tooltip} >= 0
       && $self->mapped
       && $self->get_toplevel->has_toplevel_focus) {
      my $screen = $self->{window}->get_screen;

      if ($self->{window} == ($screen->get_display->get_window_at_pointer)[0]) {
         my ($pscreen, $x, $y) = $screen->get_display->get_pointer;

         if ($pscreen == $screen) {
            if (!$self->{tip}) {
               $self->{tip} = new Gtk2::Window "popup";
               $self->{tip}->can_focus (0);
               $self->{tip}->set_name ("gtk-tooltips");
               $self->{tip}->set_decorated (0);
               $self->{tip}->set_border_width (4);
               $self->{tip}->set_has_frame (0);
               $self->{tip}->set_resizable (0);
               $self->{tip}->set_transient_for ($self->get_toplevel);
            }

            my ($mx, $my) = $self->coord ($self->get_pointer);

            if ($self->{tipinfo}[0] != $mx || $self->{tipinfo}[1] != $my) {
               $self->fill_tooltip ($mx, $my);

               $self->{tipinfo} = [$mx, $my];

               $self->overlay (_tooltip => $mx * TILESIZE, $my * TILESIZE, TILESIZE, TILESIZE, sub {
                  my ($self, $x, $y) = @_;

                  $self->{window}->draw_rectangle ($_ & 1 ? $self->style->black_gc : $self->style->white_gc, 0,
                                                   $x + $_, $y + $_,
                                                   TILESIZE - 1 - $_ * 2, TILESIZE - 1 - $_ * 2)
                     for 0..3;
               });

               my $req = $self->{tip}->size_request;
               $self->{tip}->resize ($req->width, $req->height);
            }

            $self->{tip}->move ($x + TILESIZE, $y);
            $self->{tip}->show_all;

            return;
         }
      }
   }

   $self->overlay ("_tooltip");
   delete $self->{tipinfo};
   (delete $self->{tip})->destroy if $self->{tip};
}

sub fill_tooltip {
   my ($self, $x, $y) = @_;

   $self->{tip}->remove ($self->{tip}->get_children)
      if $self->{tip}->get_children;

   $self->{tip}->add (my $frame = new Gtk2::Frame "($x|$y)");

   if ($x < 0 || $x >= $self->{map}{width}
       || $y < 0 || $y >= $self->{map}{height}) {
      $frame->add (new Gtk2::Label "<off-map>");
   } else {
      $frame->add (my $vbox = new Gtk2::VBox 0, 1);

      #TODO: fill tooltip via signal, defaulting to this:

      # fill tooltip with info about $x, $y
      my $as = $self->{map}{map}[$x][$y] || [];
      for (reverse @$as) {
         $vbox->add (my $hbox = new Gtk2::HBox 0, 2);

         # this is awful, is this really the best way?
         my $pb = new Gtk2::Gdk::Pixbuf 'rgb', 1, 8, TILESIZE, TILESIZE;
         $pb->fill (0x00000000);
         
         $TILE->composite ($pb,
            0, 0,
            TILESIZE, TILESIZE,
            - ($_->{_face} % CACHESTRIDE) * TILESIZE, - TILESIZE * int $_->{_face} / CACHESTRIDE,
            1, 1, 'nearest', 255
         );

         my $a = $_->{_virtual} || $_;

         $hbox->pack_start ((my $img = new_from_pixbuf Gtk2::Image $pb), 0, 1, 0);
         $img->set_alignment (0, 0.5);

         my $text = "$a->{_name}";
         if (my $o = $ARCH{$a->{_name}}) {
            $text .= "<small>";
            for my $k (grep /^[^_]/, sort keys %$a) {
               if ($a->{$k} ne $o->{$k}) {
                  if ($Glib::VERSION < 1.103) {
                     my $t = "\n$k\t$a->{$k}";
                     $t =~ s/&/&amp;/g;
                     $t =~ s/</&lt;/g;
                     $t =~ s/>/&gt;/g;
                     $text .= $t;
                  } else {
                     $text .= Glib::Markup::escape_text ("\n$k\t$a->{$k}");
                  }
               }
            }
            $text .= "</small>";
         } else {
            $text .= Glib::Markup::escape_text ("\n<unknown archetype>");
         }

         $hbox->pack_start (my $label = new Gtk2::Label, 1, 1, 0);
         $label->set_markup ($text);
         $label->set_alignment (0, 0.5);
      }
   }
}

sub set_viewport {
   my ($self, $x, $y) = @_;

   my $area = $self->allocation;

   $x = max 0, min $self->{width}  - $area->width , $x;
   $y = max 0, min $self->{height} - $area->height, $y;

   $self->window->scroll ($self->{x} - $x, $self->{y} - $y);

   ($self->{x}, $self->{y}) = ($x, $y);
}

sub set_map {
   my ($self, $map) = @_;

   $self->{map} = $map;

   $self->{width}  = $map->{width}  * TILESIZE;
   $self->{height} = $map->{height} * TILESIZE;
   
   $self->{x} =
   $self->{y} = 0;

   my $data = delete $map->{map};

   $map->{map} = [];

   for my $x (0 .. $map->{width} - 1) {
      my $col = $data->[$x];
      for my $y (0 .. $map->{height} - 1) {
         $self->set ($x, $y, delete $col->[$y]);
      }
   }

   delete $self->{tipinfo}; $self->update_tooltip;
   $self->invalidate_all;
}

sub coord {
   my ($self, $x, $y) = @_;

   (
      int +($self->{x} + $x) / TILESIZE,
      int +($self->{y} + $y) / TILESIZE,
   )
}

#sub handle_key {
#   my ($self, $key, $state) = @_;
#
#   $self->prefetch_cancel;
#
#   if ($state * "control-mask") {
#      if ($key == $Gtk2::Gdk::Keysyms{g}) {
#         my @sel = keys %{$self->{sel}};
#         $self->generate_thumbnails (@sel ? @sel : 0 .. $#{$self->{entry}});
#   }
#
#   1
#}

sub invalidate {
   my ($self, $x, $y, $w, $h) = @_;

   return unless $self->{window};

   $self->queue_draw_area (
      map $_ * TILESIZE, $x - 1 , $y - 1, $w + 2, $h + 2
   );
}

sub invalidate_all {
   my ($self) = @_;

   $self->queue_draw;
}

sub expose {
   my ($self, $event) = @_;

   no integer;

   my $ox = $self->{x}; my $ix = int $ox / TILESIZE;
   my $oy = $self->{y}; my $iy = int $oy / TILESIZE;

   # get_rectangles is buggy in older versions
   my @rectangles = $Gtk2::VERSION >= 1.104
                    ? $event->region->get_rectangles : $event->area;

   for my $area (@rectangles) {
      my ($x, $y, $w, $h) = $area->values; # x y w h

      my @x = ((int ($ox + $x) / TILESIZE) .. int +($ox + $x + $w + TILESIZE - 1) / TILESIZE);
      my @y = ((int ($oy + $y) / TILESIZE) .. int +($oy + $y + $h + TILESIZE - 1) / TILESIZE);

      my $window = $self->{window};

      my $pb = new Gtk2::Gdk::Pixbuf 'rgb', 0, 8, TILESIZE * (@x + 1), TILESIZE * (@y + 1);
      $pb->fill (0xff69b400);

      for my $x (@x) {
         my $dx = ($x - $x[0]) * TILESIZE;
         my $oss = $self->{map}{map}[$x];

         for my $y (@y) {
            my $dy = ($y - $y[0]) * TILESIZE;

            for my $a (@{$oss->[$y]}) {
               $TILE->composite ($pb,
                  $dx, $dy,
                  TILESIZE, TILESIZE,
                  $dx - ($a->{_face} % CACHESTRIDE) * TILESIZE, $dy - TILESIZE * int $a->{_face} / CACHESTRIDE,
                  1, 1, 'nearest', 255
               );
            }
         }
      }

      $pb->render_to_drawable ($window, $self->style->black_gc,
               0, 0,
               $x[0] * TILESIZE - $ox, $y[0] * TILESIZE - $oy,
               TILESIZE * @x, TILESIZE * @y,
               'max', 0, 0);
   }

   $_->[4]->($self, $_->[0] - $self->{x}, $_->[1] - $self->{y})
      for values %{ $self->{overlay} || {} };
}

# get head from _virtual tile, returning x, y, z and @$stack
sub get_head {
   my ($self, $virtual) = @_;

   my ($x, $y) = @$virtual{qw(_virtual_x _virtual_y)}
      or return;

   my $stack = $self->{map}{map}[$x][$y]
      or return;

   my ($z) = grep $stack->[$_] == $virtual->{_virtual}, 0..$#$stack
      or return;

   ($x, $y, $z, $self->get ($x, $y))
}

sub get {
   my ($self, $x, $y) = @_;

   return unless $x >= 0 && $x < $self->{map}{width}
              && $y >= 0 && $y < $self->{map}{height};

   Storable::dclone [
      map +{ %$_, ((exists $_->{_virtual}) ? (_virtual => 0+$_->{_virtual}) : ()) },
          @{ $self->{map}{map}[$x][$y] || [] }
   ]
}

# the caller promises us that he won't, in no circumstances,
# change the stack he gets.
sub get_ro {
   my ($self, $x, $y) = @_;

   return unless $x >= 0 && $x < $self->{map}{width}
              && $y >= 0 && $y < $self->{map}{height};

   [
      map +{ %$_, ((exists $_->{_virtual}) ? (_virtual => 0+$_->{_virtual}) : ()) },
          @{ $self->{map}{map}[$x][$y] || [] }
   ]
}

sub set {
   my ($self, $x, $y, $as) = @_;

   my $data = $self->{map}{map};

   my $prev_as = $data->[$x][$y] || [];

   my ($x1, $y1, $x2, $y2) = ($x, $y) x 2;

   # remove possible overlay tiles
   for my $a (@$prev_as) {
      next if $a->{_virtual};

      if (my $more = $a->{_more}) {
         for (@$more) {
            my ($x, $y) = @$_;

            $x1 = min $x1, $x; $y1 = min $y1, $y;
            $x2 = max $x2, $x; $y2 = max $y2, $y;

            $data->[$x][$y] = [ grep $_->{_virtual} != $a, @{ $data->[$x][$y] } ];
         }
      }
   }

   # preserve our overlay tiles, put them on top
   $as = [
      (grep !$_->{_virtual}, @$as),
      (grep  $_->{_virtual}, @$prev_as),
   ];

   for my $a (@$as) {
      next if $a->{_virtual};

      my $o = $ARCH{$a->{_name}} || $ARCH{empty_archetype}
         or (warn "archetype $a->{_name} is unknown at ($x|$y)\n"), next;

      my $face = $FACE{$a->{face} || $o->{face} || "blank.111"};
      unless ($face) {
         $face = $FACE{"blank.x11"}
            or (warn "no gfx found for arch '$a->{_name}' at ($x|$y)\n"), next;
      }

      $a->{_face} = $face->{idx};

      if ($face->{w} > 1 || $face->{h} > 1) {
         # bigfaces

         $x2 = max $x2, $x + $face->{w} - 1;
         $y2 = max $y2, $y + $face->{h} - 1;

         for my $ox (0 .. $face->{w} - 1) {
            for my $oy (0 .. $face->{h} - 1) {
               next unless $ox || $oy;

               push @{ $a->{_more} }, [$x+$ox, $y+$oy];
               push @{ $data->[$x+$ox][$y+$oy] }, {
                  _virtual   => $a,
                  _virtual_x => $x,
                  _virtual_y => $y,
                  _face      => $face->{idx} + $ox + $oy * $face->{w},
               };
            }
         }

      } elsif ($o->{more}) {
         # linked faces, slowest and most annoying

         while ($o = $o->{more}) {
            my $face = $FACE{$o->{face} || "blank.111"};
            unless ($face) {
               $face = $FACE{"blank.x11"}
                  or (warn "no gfx found for arch '$a->{_name}' at ($x*|$y*)\n"), next;
            }

            $x1 = min $x1, $x + $o->{x}; $y1 = min $y1, $y + $o->{y};
            $x2 = max $x2, $x + $o->{x}; $y2 = max $y2, $y + $o->{y};

            push @{ $a->{_more} }, [$x + $o->{x}, $y + $o->{y}];
            push @{ $data->[$x+$o->{x}][$y+$o->{y}] }, {
               _virtual   => $a,
               _virtual_x => $x,
               _virtual_y => $y,
               _face      => $face->{idx},
            };
         }
      }
   }

   $data->[$x][$y] = $as;

   $self->queue_draw_area (
      $x1 * TILESIZE - $self->{x}, $y1 * TILESIZE - $self->{y},
      ($x2 - $x1 + 1) * TILESIZE, ($y2 - $y1 + 1) * TILESIZE,
   );

   delete $self->{tipinfo}; $self->update_tooltip;

}

sub change_begin {
   my ($self, $title) = @_;

   $self->{change} ||= {
      title => $title,
   };
   $self->{change}{nest}++;
}

sub change_stack {
   my ($self, $x, $y, $as) = @_;

   $self->{change}{map}[$x][$y] ||= [$x, $y, $self->{map}{map}[$x][$y]];

   $self->signal_emit (stack_change => $x, $y, $as);
}

sub change_end {
   my ($self) = @_;

   --$self->{change}{nest} and return;

   my $change = delete $self->{change};

   delete $change->{nest};

   $change->{set} = [
      grep $_,
         map @$_,
            grep $_,
               @{ delete $change->{map} || [] }
   ];

   @{ $change->{set} } or return;

   $change
}

sub change_swap {
   my ($self, $change) = @_;

   for (@{ $change->{set} }) {
      my $stack = $self->get ($_->[0], $_->[1]);
      $self->set ($_->[0], $_->[1], $_->[2]);
      $self->signal_emit (swap_stack_change => $_->[0], $_->[1], $_->[2]);
      $_->[2] = $stack;
   }

   $self->invalidate_all;
}

=back

=head1 AUTHOR

Marc Lehmann <schmorp@schmorp.de>

=cut

1

