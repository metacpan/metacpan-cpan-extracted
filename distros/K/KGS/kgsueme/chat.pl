use utf8;

package chat;

# waaay cool widget. well... maybe at one point in the future

use Gtk2;
use Gtk2::Pango;

use Glib::Object::Subclass
   Gtk2::VBox,
   signals => {
      command => {
         flags         => [qw/run-last/],
         return_type   => undef,
         param_types   => [Glib::Scalar, Glib::Scalar],
         class_closure => sub { },
      },
      tag_event => {
         flags         => [qw/run-last/],
         return_type   => undef,
                          # tag, event, content
         param_types   => [Glib::String, Gtk2::Gdk::Event, Glib::String],
         class_closure => \&tag_event,
      },
      enter_tag => {
         flags         => [qw/run-last/],
         return_type   => undef,
                          # tag, content
         param_types   => [Glib::String, Glib::String],
         class_closure => sub { },
      },
      leave_tag => {
         flags         => [qw/run-last/],
         return_type   => undef,
                          # tag, content
         param_types   => [Glib::String, Glib::String],
         class_closure => sub { },
      },
   };

sub new {
   my ($self, %arg) = @_;

   $self = $self->Glib::Object::new;
   $self->{$_} = delete $arg{$_} for keys %arg;

   $self;
}

sub INIT_INSTANCE {
   my $self = shift;

   my $tagtable = new Gtk2::TextTagTable;

   {
      my @tags = (
         [default     => { foreground => "black", wrap_mode => "word-char" }],
         [node        => { foreground => "#0000b0", event => 1 }],
         [move        => { foreground => "#0000b0", event => 1 }],
         [user        => { foreground => "#0000b0", event => 1 }],
         [coord       => { foreground => "#0000b0", event => 1 }],
         [score       => { foreground => "#0000b0", event => 1 }],
         [error       => { foreground => "#ff0000", event => 1 }],
         [leader      => { weight => 800, pixels_above_lines => 6 }],
         [header      => { weight => 800, pixels_above_lines => 6 }],
         [undo        => { foreground => "#ffff00", background => "#ff0000", weight => 800, pixels_above_lines => 6 }],
         [challenge   => { weight => 800, pixels_above_lines => 6, background => "#ffffb0" }],
         [description => { weight => 800, foreground => "blue" }],
         [infoblock   => { weight => 700, foreground => "blue" }],
      );

      for (@tags) {
         my ($k, $v) = @$_;
         my $tag = new Gtk2::TextTag $k;
         if (delete $v->{event}) {
            $tag->signal_connect (event => sub {
               my ($tag, $view, $event, $iter) = @_;

               return 0 if $event->type eq "motion-notify";
               
               my ($a, $b) = ($iter, $iter->copy);
               $a->backward_to_tag_toggle ($tag) unless $a->begins_tag ($tag);
               $b->forward_to_tag_toggle  ($tag) unless $b->ends_tag   ($tag);

               $self->signal_emit (tag_event => $k, $event, $a->get_text ($b));

               1;
            });
         }
         $tag->set (%$v);
         $tagtable->add ($tag);
      }
   }

   $self->{tagtable} = $tagtable;

   $self->signal_connect (destroy => sub {
      remove Glib::Source delete $self->{idle} if $self->{idle};
      %{$_[0]} = ();
   });

   $self->{buffer} = new Gtk2::TextBuffer $self->{tagtable};

   $self->{widget} = new Gtk2::ScrolledWindow;
   $self->{widget}->set_policy ("automatic", "always");
   $self->pack_start ($self->{widget}, 1, 1, 0);

   $self->{widget}->add ($self->{view} = new_with_buffer Gtk2::TextView $self->{buffer});
   $self->{view}->set (
         wrap_mode      => "word-char",
         cursor_visible => 0,
         editable       => 0,
         tabs           =>
            (new Gtk2::Pango::TabArray 1, 0, left => 125000), # arbitrary... pango is underfeatured
   );

   $self->{view}->signal_connect (motion_notify_event => sub {
      my ($widget, $event) = @_;

      my $window = $widget->get_window ("text");
      if ($event->window == $window) {
         my ($win, $x, $y, $mask) = $window->get_pointer;
         ($x, $y) = $self->{view}->window_to_buffer_coords ("text", $x, $y);
         my ($iter) = $self->{view}->get_iter_at_location ($x, $y);

         my $tag = ($iter->get_tags)[01];
         
         if ($tag) {
            my ($a, $b) = ($iter, $iter->copy);
            $a->backward_to_tag_toggle ($tag) unless $a->begins_tag ($tag);
            $b->forward_to_tag_toggle  ($tag) unless $b->ends_tag   ($tag);

            $self->tag_enterleave ($tag->get ("name"), $a->get_text ($b));
         } else {
            $self->tag_enterleave ();
         }

         1;
      }
      0;
   });

   $self->{view}->signal_connect (leave_notify_event => sub {
      $self->tag_enterleave ();
      0;
   });

   $self->{view}->add_events (qw(leave_notify_mask));

   $self->pack_start (($self->{entry} = new Gtk2::Entry), 0, 1, 0);

   $self->{entry}->signal_connect (activate => sub {
      my ($entry) = @_;
      my $text = $entry->get_text;
      $entry->set_text("");

      my ($cmd, $arg);

      if ($text =~ /^\/(\S+)\s*(.*)$/) {
         ($cmd, $arg) = ($1, $2);
      } else {
         ($cmd, $arg) = ("say", $text);
      }

      $self->signal_emit (command => $cmd, $arg);
   });

   #$self->{end} = $self->{buffer}->create_mark (undef, $self->{buffer}->get_end_iter, 0);#d##todo# use this one for gtk-1.050+
   $self->{end} = $self->{buffer}->create_mark (++$USELESSNAME, $self->{buffer}->get_end_iter, 0); # workaround for gtk-perl bug

   $self->set_end;
}

sub tag_enterleave {
   my ($self, $tag, $content) = @_;

   my $cur = $self->{current_tag};

   if ($cur->[0] != $tag || $cur->[1] ne $content) {
      $self->signal_emit (leave_tag => @$cur) if $cur->[0];
      $self->{current_tag} = $cur = [$tag, $content];
      $self->signal_emit (enter_tag => @$cur) if $cur->[0];
   }
}

sub tag_event {
   my ($self, $tag, $event, $content) = @_;

   return unless $self->{app};

   if ($tag eq "user" && $event->type eq "button-release") {
      if ($event->button == 1) {
         $content =~ /^([^\x20\xa0]+)/ or return;
         $self->{app}->open_user (name => $1);
      }
   }
}

sub set_end {
   my ($self) = @_;

   # we do it both. the first scroll avoids flickering,
   # the second ensures that we scroll -- gtk+ often ignores
   # the first scroll_to_mark ...
   $self->{view}->scroll_to_mark ($self->{end}, 0, 0, 0, 0);
   $self->{idle} ||= add Glib::Idle sub {
      $self->{view}->scroll_to_mark ($self->{end}, 0, 0, 0, 0);
      delete $self->{idle};
      0;
   };
}

sub at_end {
   my ($self) = @_;

   # this is, maybe, a bad hack :/
   my $adj = $self->{widget}->get_vadjustment;
   $adj->value + $adj->page_size >= $adj->upper - 0.5;
}

sub append_text {
   my ($self, $text) = @_;

   $self->_append_text ($self->{end}, $text);
}

sub _append_text {
   my ($self, $mark, $text) = @_;

   my $at_end = $self->at_end;

   $text = "<default>$text</default>";

   my @tag;
   # pseudo-simplistic-xml-parser
   for (;;) {
      $text =~ /\G<([^>]+)>/gc or last;
      my $tag = $1;
      if ($tag =~ s/^\///) {
         pop @tag;
      } else {
         push @tag, $tag;
      }

      $text =~ /\G([^<]*)/gc or last;
      $self->{buffer}->insert_with_tags_by_name ($self->{buffer}->get_iter_at_mark ($mark), util::xmlto $1, @tag)
         if length $1;
   }

   $self->set_end if $at_end;
}

sub set_text {
   my ($self, $text) = @_;

   my $at_end = $self->at_end;
           
   $self->{buffer}->set_text ("");
   $self->append_text ($text);

   $self->set_end if $at_end;
}

sub new_eventtag {
   my ($self, $cb) = @_;

   my $tag = new Gtk2::TextTag;
   $tag->signal_connect (event => $cb);
   $self->{tagtable}->add ($tag);

   $tag
}

# create a new "subbuffer"
sub new_inlay {
   my ($self) = @_;

   my $end = $self->{buffer}->get_end_iter;

   my $self = bless {
      buffer  => $self->{buffer},
      parent  => $self,
   }, superchat::inlay;

   # $USELESSNAME is a Gtk-perl < 1.042 workaround
   $self->{l} = $self->{buffer}->create_mark (++$USELESSNAME, $end, 1);
   $self->{buffer}->insert ($end, "\x{200d}");
   $self->{r} = $self->{buffer}->create_mark (++$USELESSNAME, $self->{buffer}->get_iter_at_mark ($self->{l}), 0);

   Scalar::Util::weaken $self->{buffer};
   Scalar::Util::weaken $self->{parent};
   $self;
}

sub new_switchable_inlay {
   my ($self, $header, $cb, $visible) = @_;

   my $inlay;

   my $tag = $self->new_eventtag (sub {
      my ($tag, $view, $event, $iter) = @_;

      if ($event->type eq "button-press") {
         $inlay->set_visible (!$inlay->{visible});
         return 1;
      }

      0;
   });

   $tag->set (background => "#e0e0ff");

   $inlay = $self->new_inlay;

   $inlay->{visible} = $visible;
   $inlay->{header}  = $header;
   $inlay->{tag}     = $tag;
   $inlay->{cb}      = $cb;

   Scalar::Util::weaken $inlay->{tag};

   $inlay->refresh;

   $inlay;
}

package superchat::inlay;

sub liter { $_[0]{buffer}->get_iter_at_mark ($_[0]{l}) }
sub riter { $_[0]{buffer}->get_iter_at_mark ($_[0]{r}) }

sub clear {
   my ($self) = @_;
   $self->{buffer}->delete ($self->liter, $self->riter);
}

sub append_text {
   my ($self, $text) = @_;

   $self->{parent}->_append_text ($self->{r}, $text);
}

sub append_widget {
   my ($self, $widget) = @_;

   $widget->show_all;

   my $anchor = $self->{buffer}->create_child_anchor ($self->riter);
   $self->{parent}{view}->add_child_at_anchor ($widget, $anchor);

   $widget;
}

sub append_optionmenu {
   my ($self, $ref, @entry) = @_;

   $self->append_widget (gtk::optionmenu $ref, @entry);
}

sub append_button {
   my ($self, $label, $cb) = @_;

   $self->append_widget (gtk::button $label, $cb);
}

sub visible { $_[0]{visible} }

sub set_visible {
   my ($self, $visible) = @_;

   return if $self->{visible} == $visible;
   $self->{visible} = $visible;

   $self->refresh;
}

sub refresh {
   my ($self) = @_;

   $self->clear;

   my $arrow = $self->{visible} ? "⊟" : "⊞";

   $self->{buffer}->insert ($self->riter, "\n");
   $self->{buffer}->insert_with_tags ($self->riter, util::xmlto "$arrow $self->{header}", $self->{tag});

   return unless $self->{visible};

   $self->{cb}->($self);
}

sub destroy {
   my ($self) = @_;

   return if !$self->{l} || !$self->{buffer} || $self->{l}->get_deleted;

   $self->clear if $self->{buffer};

   delete $self->{parent};
   delete $self->{buffer};
   delete $self->{l};
   delete $self->{r};
}

sub DESTROY {
   my $self = shift;

   $self->{parent}{tagtable}->remove (delete $self->{tag}) if $self->{tag} && $self->{parent};
   #&destroy;
}

1;

