package gtk;

use Carp;
use File::Temp;
use Gtk2;

# I have not yet found a way to simply default style properties
Gtk2::Rc->parse_string(<<EOF);

   style "base" {
      GtkTreeView::vertical_separator = 0
   }
   widget_class "*" style "base"

   style "whitestyle" {
      fg[NORMAL] = "#000000"
      bg[NORMAL] = "#ffffff"
   }
   style "blackstyle" {
      fg[NORMAL] = "#ffffff"
      bg[NORMAL] = "#000000"
   }

   widget "*.userpanel-0.*" style "blackstyle"
   widget "*.userpanel-1.*" style "whitestyle"

EOF

sub flush {
   do {
      flush Gtk2::Gdk;
      Glib::MainContext->default->iteration (0);
   } while Gtk2::Gdk->events_pending;
}

sub for_all($) {
   (
      $_[0],
      $_[0]->isa (Gtk2::Container)
         ? map for_all ($_), $_[0]->get_children
         : ()
   )
}

sub double_buffered {
   return;#d#
   my ($widget, $state) = @_;

   for (for_all $widget) {
      $_->set_double_buffered ($state);
      print "$_\n";#d#
   }
      print "<<<\n";#d#
}

our $text_renderer = new Gtk2::CellRendererText;
our $int_renderer  = new Gtk2::CellRendererText;
$int_renderer->set (xalign => 1);

our $state = $util::state->{gtk} ||= {};

# shows the properties of a glib object
sub info {
   my ($idx, $obj) = @_;
   return if $seen{$idx}++;
   print "\n$idx\n";
   for ($obj->list_properties) {
      printf "%-16s %-24s %-24s %s\n", $_->{name}, $_->{type}, (join ":", @{$_->{flags}}), $_->{descr};
   }
}

my %get = (
   window_size     => sub { [ ($_[0]->allocation->values)[2,3] ] },
   #window_pos     => sub { die KGS::Listener::Debug::dumpval [ $_[0]->get_root_origin ] },
   column_size     => sub { $_[0]->get("width") || $_[0]->get("fixed_width") },
   modelsortorder  => sub { [ $_[0]->get_sort_column_id ] },
);

my %set = (
   window_size     => sub { $_[0]->set_default_size (@{$_[1]}) },
   #window_pos     => sub { $_[0]->set_uposition (@{$_[1]}) if @{$_[1]} },
   column_size     => sub { $_[0]->set (fixed_width => $_[1]) },
   modelsortorder  => sub { $_[0]->set_sort_column_id (@{$_[1]}) },
);

my %widget;

sub state {
   my ($widget, $class, $instance, %attr) = @_;

   while (my ($k, $v) = each %attr) {
      my ($set, $get) = $k =~ /=/ ? split /=/, $k : ($k, $k);

      $v = $state->{$class}{"*"}{$get}
         if exists $state->{$class}{"*"} && exists $state->{$class}{"*"}{$get};

      $v = $state->{$class}{$instance}{$get}
         if defined $instance
         && exists $state->{$class}{$instance} && exists $state->{$class}{$instance}{$get};

      $set{$get} ? $set{$get}->($widget, $v) : $widget->set($set => $v);

      #my $vx = KGS::Listener::Debug::dumpval $v; $vx =~ s/\s+/ /g; warn "set $class ($instance) $set => $vx\n";#d#
   }

   #$widget->signal_connect(destroy => sub { delete $widget{$widget}; 0 });

   $widget{$widget} = [$widget, $class, $instance, \%attr];
   Scalar::Util::weaken $widget{$widget}[0];
}

sub save_state {
   for (grep $_, values %widget) {
      my ($widget, $class, $instance, $attr) = @$_;

      next unless $widget; # no destroy => widget may be undef

      $widget->realize if $widget->can("realize");

      while (my ($k, $v) = each %$attr) {
         my ($set, $get) = $k =~ /=/ ? split /=/, $k : ($k, $k);
         $v = $get{$get} ? $get{$get}->($widget) : $widget->get($get);

         $state->{$class}{"*"}{$get}       = $v;
         $state->{$class}{$instance}{$get} = $v if defined $instance;

         #my $vx = KGS::Listener::Debug::dumpval $v; $vx =~ s/\s+/ /g; warn "get $class ($instance) $get => $vx\n";#d#
      }
   }
}

# string => Gtk2::Image
sub image_from_data {
   my ($data) = @_;
   my $img;
   
   if (defined $data) {
      # need to write to file first :/
      my ($fh, $filename) = File::Temp::tempfile ();
      syswrite $fh, $data;
      close $fh;
      $img = new_from_file Gtk2::Image $filename;
      unlink $filename;
   } else {
      $img = new_from_file Gtk2::Image KGS::Constants::findfile "KGS/kgsueme/images/default_userpic.png";
   }

   $img;
}

#############################################################################

sub optionmenu {
   my ($ref, @entry) = @_;

   my @vals;

   my $widget = new Gtk2::OptionMenu;
   $widget->set (menu => my $menu = new Gtk2::Menu);

   my $idx = 0;

   while (@entry >= 2) {
      my $value = shift @entry;
      my $label = shift @entry;

      $menu->append (new Gtk2::MenuItem $label);
      push @vals, $value;

      if ($value eq $$ref && $idx >= 0) {
         $widget->set_history ($idx);
         $idx = -1e6;
      }
      $idx++;
   }

   my $cb = shift @entry;

   $widget->signal_connect (changed => sub {
      my $new = $vals[$_[0]->get_history];

      if ($new ne $$ref) {
         $$ref = $new;
         $cb->($new) if $cb;
      }
   });

   $widget;
}

sub textentry {
   my ($ref, $width, $cb) = @_;

   my $widget = new Gtk2::Entry;
   $widget->set (text => $$ref, width_chars => $width);
   $widget->signal_connect (changed => sub {
      $$ref = $_[0]->get_text;
      $cb->($$ref) if $cb;
   });

   $widget;
}

sub numentry {
   my ($ref, $width, $cb) = @_;

   my $widget = new Gtk2::Entry;
   $widget->set (text => $$ref, width_chars => $width, xalign => 1);
   $widget->signal_connect (changed => sub {
      $$ref = $_[0]->get_text;
      $cb->($$ref) if $cb;
   });

   $widget;
}

sub timeentry {
   my ($ref, $width, $cb) = @_;

   my $widget = new Gtk2::Entry;
   $widget->set (text => util::format_time $$ref, width_chars => $width, xalign => 1);
   $widget->signal_connect (changed => sub {
      $$ref = util::parse_time $_[0]->get_text;
      $cb->($$ref) if $cb;
   });

   $widget;
}

sub button {
   my ($label, $cb) = @_;

   my $widget = new_with_label Gtk2::Button $label;
   $widget->signal_connect (clicked => sub { $cb->() if $cb });

   $widget;
}

1;

