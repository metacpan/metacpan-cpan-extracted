#!/usr/bin/perl
use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2 -init;
use Gnome2::Dia;

my $window = Gtk2::Window -> new();
my $scroller = Gtk2::ScrolledWindow -> new();
my $box = Gtk2::VBox -> new(FALSE, 5);

my $canvas = Gnome2::Dia::Canvas -> new();
my $view = Gnome2::Dia::CanvasView -> new($canvas, TRUE);

my $buttons = Gtk2::HBox -> new(TRUE, 5);

my $selection = Gtk2::Button -> new("Select");
my $line = Gtk2::Button -> new("Line");
my $rectangle = Gtk2::Button -> new("Rectangle");
my $text = Gtk2::Button -> new("Text");

# --------------------------------------------------------------------------- #

my $selection_tool = Gnome2::Dia::StackTool -> new();

sub unset_tool {
  $view -> set_tool($selection_tool);
}

$selection -> signal_connect(clicked => \&unset_tool);

$line -> signal_connect(clicked => sub {
  my $tool = Gnome2::Dia::PlacementTool -> new("Gnome2::Dia::CanvasLine");

  $tool -> signal_connect(button_release_event => \&unset_tool);

  $view -> set_tool($tool);
});

$rectangle -> signal_connect(clicked => sub {
  my $tool = Gnome2::Dia::PlacementTool -> new("Gnome2::Dia::CanvasBox");

  $tool -> signal_connect(button_release_event => \&unset_tool);

  $view -> set_tool($tool);
});

$text -> signal_connect(clicked => sub {
  my $tool = Gnome2::Dia::PlacementTool -> new("MyTextBox");

  $tool -> signal_connect(button_release_event => \&unset_tool);

  $view -> set_tool($tool);
});

# --------------------------------------------------------------------------- #

$buttons -> pack_start($selection, TRUE, TRUE, 0);
$buttons -> pack_start($line, TRUE, TRUE, 0);
$buttons -> pack_start($rectangle, TRUE, TRUE, 0);
$buttons -> pack_start($text, TRUE, TRUE, 0);

$scroller -> set_policy("automatic", "automatic");
$scroller -> add($view);

$box -> set_border_width(2);
$box -> pack_start($scroller, TRUE, TRUE, 0);
$box -> pack_start($buttons, FALSE, FALSE, 0);

$window -> signal_connect(delete_event => sub {
  Gtk2 -> main_quit();
  return FALSE;
});

$window -> add($box);
$window -> set_default_size(600, 400);
$window -> set_title("Sample Editor");
$window -> show_all();

Gtk2 -> main();

# --------------------------------------------------------------------------- #

package MyTextBox;

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gnome2::Dia;

use Glib::Object::Subclass
  Gnome2::Dia::CanvasBox::,
  interfaces => [ Gnome2::Dia::CanvasGroupable:: ];

sub INIT_INSTANCE {
  my ($self) = @_;

  my $text = Gnome2::Dia::CanvasText -> new(text => "Urgs!", editable => TRUE);
  $text -> set_child_of($self);

  $text -> signal_connect(editing_done => sub {
    my ($text, $shape, $new) = @_;

    # $shape -> set_alignment("right");
    # $shape -> set_affine([cos(90*(3.14/180)), -sin(90*(3.14/180)), cos(90*(3.14/180)), sin(90*(3.14/180)), 0, 0]);
    $text -> rotate(90);
  });

  $self -> { _children } = [$text];
}

# ----------------------------- DiaCanvasItem ------------------------------- #

sub UPDATE {
  my ($self, $affine) = @_;

  $self -> SUPER::UPDATE($affine);

  foreach (@{$self -> { _children }}) {
    $_ -> set(width => $self -> get("width"),
              height => $self -> get("height"));
    $self -> update_child($_, $affine);
  }
}

# --------------------------- DiaCanvasGroupable ---------------------------- #

sub ADD {
  warn "add: " . join ", ", @_;
}

sub REMOVE {
  warn "remove: " . join ", ", @_;
}

sub GET_ITER {
  my ($self) = @_;

  $self -> { _stamp } = int(rand(23));

  return [ $self -> { _stamp }, 0, "schmuh", "bla" ];
}

sub NEXT {
  my ($self, $iter) = @_;

  unless (defined $iter) {
    return undef;
  }

  my ($stamp, $index, $schmuh, $bla) = @$iter;

  unless ($stamp == $self -> { _stamp } &&
          $index < $#{$self -> { _children }}) {
    return undef;
  }

  return [ $stamp, ++$index, $schmuh, $bla ];
}

sub VALUE {
  my ($self, $iter) = @_;

  unless (defined $iter) {
    return undef;
  }

  my ($stamp, $index, $schmuh, $bla) = @$iter;

  unless ($stamp == $self -> { _stamp } &&
          $index <= $#{$self -> { _children }}) {
    return undef;
  }

  return $self -> { _children } -> [$index];
}
