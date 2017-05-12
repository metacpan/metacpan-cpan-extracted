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

      my $ctrl = grep $_ eq "control-mask", @{$_[1]->state};

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
      my $row = scalar +($_[0]->get_selection->get_selected_rows)[0]->get_indices;

      my $k = $_[0]{data}[$row][1];
      $k = $self->{cluster}{$k};

      $self->{updating} = 1;
      $self->{schnauzer}->set_paths ($k, 0, sub {
         delete $self->{updating};
      });

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
   my ($self) = @_;

   $self->{schnauzer}->push_state;

   my $progress = new Gtk2::CV::Progress title => "splitting...";

   my $paths = $self->{schnauzer}->get_paths;
   $self->{select} = [$paths];

   my %files = map {
                      my $orig = $_;
                      s/^.*\///;
                      s/(?:-\d+|\.~[~0-9]*)+$//; # remove -000, .~1~ etc.
                      s/\.[^.]*$//;
                      ($orig => [/(\pL(?:\pL+|\pP(?=\pL))* | \pN+)/gx])
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
   my %clean;
   while (my ($k, $v) = each %$cluster) {
      if (exists $clean{substr $k, 6}) {
         my $idx = 0;
         ++$idx while exists $clean{(substr $k, 6) . "/$idx"};
         $k .= "/$idx";
      }
      $clean{substr $k, 6} = $v;
   }

   $self->{cluster} = \%clean;

   $progress->update (0.75);
   $progress->set_title ("finishing...");

   @{ $self->{list}{data} } = (
      sort { $b->[0] <=> $a->[0] }
         grep $_->[0] > 1,
              map [(scalar @{ $self->{cluster}{$_} }), $_], keys %{ $self->{cluster} }
   );
}

sub start {
   my ($self, $schnauzer) = @_;

   $self->{schnauzer} = $schnauzer;

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

   $schnauzer->signal_connect (popup => sub {
      my ($self, $menu, $cursor, $event) = @_;
      
      $menu->append (my $i_up = new Gtk2::MenuItem "Filename clustering...");
      $i_up->signal_connect (activate => sub {
         Gtk2::CV::Plugin::NameCluster->new->start ($self);
      });
   });
}

1

