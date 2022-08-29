package Gtk2::CV::Plugin::MetaCluster;

use common::sense;

use Image::Size ();
use POSIX ();

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
         or return;

      my $row = scalar $rows[0]->get_indices;

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

   my $progress = new Gtk2::CV::Progress title => "analysing...";

   my $paths = $self->{schnauzer}->get_paths;

   my $getid = $self->{getid};
   my %cluster;

   for my $path (@$paths) {
      push @{ $cluster{$_} }, $path
         for $getid->($path);
   }

   $self->{cluster} = \%cluster;

   $progress->update (0.5);
   $progress->set_title ("categorize...");

   @{ $self->{list}{data} } = (
      sort { $b->[0] <=> $a->[0] }
         map [(scalar @{ $cluster{$_} }), $_], keys %cluster
   );
}

sub start {
   my ($self, $schnauzer, $getid) = @_;

   $self->{getid} = $getid;
   $self->{schnauzer} = $schnauzer;

   $self->{signal} = $schnauzer->signal_connect_after (chpaths => sub {
      return if $self->{updating};

      $self->analyse;

      1
   });

   $self->analyse;

   $self->show_all;
}

sub imgsize {
   local $Image::Size::NO_CACHE = 1;

   my ($w, $h, $t) = Image::Size::imgsize $_[0];

   ("${w}x${h}=$t", "W=$w=$t", "H=$h=$t", "T=$t")
}

sub mtime {
   POSIX::strftime "%Y-%m-%d %H", gmtime +(stat $_[0])[9]
}

sub size {
   sprintf "%2d", 2 / (log 10) * log 1 + -s $_[0]
}

sub nlink {
   my $nlink = sprintf "%4d", (stat $_[0])[3];
   $nlink =~ s/(\d)(\d+)$/$1 . ("x" x length $2)/ge;
   $nlink
}

sub custom {#TODO
   $_[0] =~ $::CUSTOM_CLUSTERING
      ? $1 : "???"
}

sub new_schnauzer {
   my ($self, $schnauzer) = @_;

   my $metacluster;

   $schnauzer->signal_connect (popup => sub {
      my ($self, $menu, $cursor, $event) = @_;
      
      $menu->append (my $i_up = new Gtk2::MenuItem "Imagesize clustering...");
      $i_up->signal_connect (activate => sub {
         ($metacluster = Gtk2::CV::Plugin::MetaCluster->new)->start ($self, \&imgsize);
      });

      $menu->append (my $i_up = new Gtk2::MenuItem "Filetime clustering...");
      $i_up->signal_connect (activate => sub {
         ($metacluster = Gtk2::CV::Plugin::MetaCluster->new)->start ($self, \&mtime);
      });

      $menu->append (my $i_up = new Gtk2::MenuItem "Filesize clustering...");
      $i_up->signal_connect (activate => sub {
         ($metacluster = Gtk2::CV::Plugin::MetaCluster->new)->start ($self, \&size);
      });

      $menu->append (my $i_up = new Gtk2::MenuItem "Link count clustering...");
      $i_up->signal_connect (activate => sub {
         ($metacluster = Gtk2::CV::Plugin::MetaCluster->new)->start ($self, \&nlink);
      });

      if ($::CUSTOM_CLUSTERING) {
         $menu->append (my $i_up = new Gtk2::MenuItem "Custom clustering...");
         $i_up->signal_connect (activate => sub {
            ($metacluster = Gtk2::CV::Plugin::MetaCluster->new)->start ($self, \&custom);
         });
      }
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
         if ($metacluster && $metacluster->{list}) {
            my ($path) = $metacluster->{list}->get_cursor;
            $key == $Gtk2::Gdk::Keysyms{Up} ? $path->prev : $path->next;
            $metacluster->{list}->set_cursor ($path);
            return 1;
         }
      }

      0
   });
}

1

