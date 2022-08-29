package Gtk2::CV::Plugin::NameCluster;

use common::sense;

use Glib::Object::Subclass
   'Gtk2::Window';

use Gtk2::SimpleList;

use Gtk2::CV::Progress;

use Gtk2::CV::Plugin;

sub INIT_INSTANCE {
   my ($self) = @_;

   $self->set_default_size (250, 500);
   $self->set_role ("group view");

   $self->add (my $sw = new Gtk2::ScrolledWindow);
   $sw->add (
      $self->{list} = new Gtk2::SimpleList
         "#"    => "int",
         "Name" => "text",
   );

   $self->{list}->get_column (0)->set_sort_column_id (0);
   $self->{list}->get_column (1)->set_sort_column_id (1);
   $self->{list}->get_model->set_sort_column_id (0, 'descending');

   $self->{list}->signal_connect (key_press_event => sub {
      my $key = $_[1]->keyval;
      my $state = $_[1]->state;

      if ($key == $Gtk2::Gdk::Keysyms{Up}) {
         return 0;
      } elsif ($key == $Gtk2::Gdk::Keysyms{Down}) {
         return 0;
      } else {
         return $self->{schnauzer}->signal_emit (key_press_event => $_[1]);
      }

      1
   });

   $self->{list}->signal_connect (cursor_changed => sub {
      my @rows = $_[0]->get_selection->get_selected_rows
         or return 1;

      my $row = scalar $rows[0]->get_indices;

      my $k = $_[0]{data}[$row][1];
      $k = $self->{cluster}{$k};

      $self->{updating} = 1;

      if ($self->{dirview}) {
         $self->{schnauzer}->chdir ($k->[0], sub {
            delete $self->{updating};
         });
      } else {
         $self->{schnauzer}->set_paths ($k, 0, sub {
            delete $self->{updating};
         });
      }

      1
   });

   $self->signal_connect (destroy => sub {
      if ($self->{signal}) {
         $self->{schnauzer}->signal_handler_disconnect (delete $self->{signal});
      }

      $self->{schnauzer}->pop_state;

      %{$_[0]} = ()
   });
}

sub analyse {
   my ($self, $clustersise) = @_;

   $self->{schnauzer}->push_state;

   my $paths = $self->{schnauzer}->get_paths;
   $self->{select} = [$paths];

   my ($progress, %groups);

   if ($self->{dirview}) {

      $progress = new Gtk2::CV::Progress title => "preparing...";

      for my $entry (@{ $self->{schnauzer}{entry} }) {
         # skip nondirs
         $entry->[Gtk2::CV::Schnauzer::E_FLAGS] & Gtk2::CV::Schnauzer::F_ISDIR
            or next;

         my $dir  = $entry->[Gtk2::CV::Schnauzer::E_DIR ];
         my $file = $entry->[Gtk2::CV::Schnauzer::E_FILE];

         $groups{$file} = ["$dir/$file"];
      }

   } else {

      $progress = new Gtk2::CV::Progress title => "splitting...";

      my %files = map {
                         my $orig = $_;
                         s/^.*\///;
                         s/(?:-\d+|\.~[~0-9]*)+$//; # remove -000, .~1~ etc.
                         s/\.[^.]*$//;
                         ($orig => [/(\pL(?:\pL+)* | \pN+)/gx])
                      }
                      grep !/\.(sfv|crc|par|par2)$/i,
                           @{ $self->{select}[-1] };

      my $cluster = ();

      $progress->update (0.25);
      $progress->set_title ("clustering...");

      for my $regex (
         qr/^\PN/,
         qr/^\pN/,
      ) {
         my %c;
         while (my ($k, $v) = each %files) {
            my $idx = "aaaaaa";
            # clusterise by component_idx . component
            push @{ $c{$idx++ . $_} }, $k
               for grep m/$regex/, @$v;
         }

         $cluster = { %c, %$cluster };

         delete @files{ @{ $c{$_} } }
            for grep @{ $c{$_} } >= 3, keys %c;
      }

      $progress->update (0.5);
      $progress->set_title ("categorize...");

      $cluster->{"000000REMAINING FILES"} = [keys %files];

      # remove component index
      while (my ($k, $v) = each %$cluster) {
         if (exists $groups{substr $k, 6}) {
            my $idx = 0;
            ++$idx while exists $groups{(substr $k, 6) . "/$idx"};
            $k .= "/$idx";
         }
         $groups{substr $k, 6} = $v;
      }

      while (my ($k, $v) = each %groups) {
         delete $groups{$k}
            unless @$v > 1;
      }
   }

   $progress->update (0.75);
   $progress->set_title ("finishing...");

   $self->{cluster} = \%groups;

   @{ $self->{list}{data} } = (
      sort { $b->[0] <=> $a->[0] }
         map [(scalar @{ $groups{$_} }), $_], sort keys %groups
   );
}

sub start {
   my ($self, $schnauzer, $dirview) = @_;

   $self->{schnauzer} = $schnauzer;
   $self->{dirview} = $dirview;

   $self->{signal} = $schnauzer->signal_connect_after (chpaths => sub {
      return if $self->{updating};

      $self->analyse;

      1
   });

   $self->analyse;

   $self->show_all;
}

sub new_schnauzer {
   my ($self, $schnauzer) = @_;

   my $namecluster;

   $schnauzer->signal_connect (popup => sub {
      my ($self, $menu, $cursor, $event) = @_;
      
      $menu->append (my $i_up = new Gtk2::MenuItem "Filename clustering...");
      $i_up->signal_connect (activate => sub {
         $namecluster = Gtk2::CV::Plugin::NameCluster->new;
         $namecluster->start ($self, 0);
      });

      $menu->append (my $i_up = new Gtk2::MenuItem "Subdir view...");
      $i_up->signal_connect (activate => sub {
         $namecluster = Gtk2::CV::Plugin::NameCluster->new;
         $namecluster->start ($self, 1);
      });
   });


   $schnauzer->signal_connect (key_press_event => sub {
      my ($self, $event) = @_;
      my $key = $event->keyval;
      my $state = $event->state;

      $state *= Gtk2::Accelerator->get_default_mod_mask;

      if (
         $state == ["control-mask"]
         && ($key == $Gtk2::Gdk::Keysyms{Up} || $key == $Gtk2::Gdk::Keysyms{Down})
      ) {
         if ($namecluster && $namecluster->{list}) {
            my ($path) = $namecluster->{list}->get_cursor;
            $key == $Gtk2::Gdk::Keysyms{Up} ? $path->prev : $path->next;
            $namecluster->{list}->set_cursor ($path);
         }
         return 1;
      }

      0
   });
}

1

