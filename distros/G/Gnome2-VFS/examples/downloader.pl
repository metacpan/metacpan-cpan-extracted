#!/usr/bin/perl -w

use Switch;
use Gtk2 -init;
use Gnome2::VFS -init;

###############################################################################

package Gtk2::CellRendererProgress;

use Glib::Object::Subclass
  Gtk2::CellRenderer::,
  properties => [
    Glib::ParamSpec -> double("progress",
                              "Progress",
                              "Are we there, yet?",
                              0.0, 1.0, 0.0,
                              [qw(readable writable)])
  ]
;

use constant x_padding => 2;
use constant y_padding => 3;

sub INIT_INSTANCE {
  my ($self) = @_;
  $self -> { progress } = 0.0;
}

sub GET_SIZE {
  my ($cell, $widget, $cell_area) = @_;
  my ($width, $height) = (100, 10);

  if (defined($cell_area)) {
    $width = $cell_area -> width() - x_padding * 2;
    $height = $cell_area -> height() - y_padding * 2;
  }

  return (0,
          0,
          $width + x_padding * 2,
          $height + y_padding * 2);
}

sub RENDER {
  my ($cell, $window, $widget, $background_area, $cell_area, $expose_area, $flags) = @_;
  my ($x_offset, $y_offset, $width, $height) = $cell -> GET_SIZE($widget, $cell_area);

  if ($cell -> { progress } > 0) {
    $widget -> get_style -> paint_box($window,
                                      $flags & "selected" ? "normal" : "prelight",
                                      "out",
                                      $cell_area,
                                      $widget,
                                      undef,
                                      $cell_area -> x() + $x_offset,
                                      $cell_area -> y() + $y_offset,
                                      $width * $cell -> { progress },
                                      $height - 1);
  }
}

###############################################################################

package main;

use Cwd qw(cwd);

use constant {
  COLUMN_ADDRESS => 0,
  COLUMN_STATUS => 1,
  COLUMN_PROGRESS => 2
};

my $window = Gtk2::Window -> new("toplevel");

$window -> set_title("Async Downloader");
$window -> set_border_width(5);
$window -> set_default_size(100, 200);

$window -> signal_connect(delete_event => sub { quit(); });

my $vbox = Gtk2::VBox -> new(0, 5);

my $hbox = Gtk2::HBox -> new(0, 5);

my $entry = Gtk2::Entry -> new();
my $button = Gtk2::Button -> new("_Download");

$button -> signal_connect(clicked => sub {
  start_new_download($entry -> get_text());
});
$entry -> signal_connect(activate => sub {
  $button->clicked;
});

$hbox -> pack_start($entry, 1, 1, 0);
$hbox -> pack_start($button, 0, 0, 0);

$vbox -> pack_start($hbox, 0, 0, 0);

my $model = Gtk2::ListStore -> new(qw(Glib::String Glib::String Glib::Double));
my $view = Gtk2::TreeView -> new($model);

my $column_address =
  Gtk2::TreeViewColumn -> new_with_attributes("Address",
                                              Gtk2::CellRendererText -> new(),
                                              text => COLUMN_ADDRESS);

my $column_status =
  Gtk2::TreeViewColumn -> new_with_attributes("Status",
                                              Gtk2::CellRendererText -> new(),
                                              text => COLUMN_STATUS);

my $column_progress =
  Gtk2::TreeViewColumn -> new_with_attributes("Progress",
                                              Gtk2::CellRendererProgress -> new(),
                                              progress => COLUMN_PROGRESS);

$column_address -> set_sizing("autosize");
$column_status -> set_sizing("autosize");

$view -> append_column($column_address);
$view -> append_column($column_status);
$view -> append_column($column_progress);

$vbox -> pack_start($view, 1, 1, 0);

$window -> add($vbox);
$window -> show_all();

Gtk2 -> main();

###############################################################################

my %iters;

sub start_new_download {
  my ($address) = @_;

  return unless ($address ne "");

  my $source = Gnome2::VFS::URI -> new($address);
  my $target = Gnome2::VFS::URI -> new(cwd() . "/" . $source -> extract_short_path_name());

  my $source_string = $source -> to_string();

  my ($result, $handle) = Gnome2::VFS::Async -> xfer([$source],
                                                     [$target],
                                                     qw(default),
                                                     qw(query),
                                                     qw(query),
                                                     0,
                                                     \&progress_update,
                                                     $source_string,
                                                     \&progress_sync,
                                                     $source_string);

  if ($result eq "ok") {
    my $iter = $model -> append();

    $entry -> set_text("");
    $model -> set($iter, COLUMN_ADDRESS, $source_string);

    $iters{ $source_string } = $iter; # -> copy();
  }
  else {
    $handle -> cancel();
  }
}

sub progress_update {
  my ($handle, $info, $source_string) = @_;
  my $status;

  switch ($info -> { phase }) {
    case "phase-completed"      { $status = "Completed"; }
    case "phase-initial"        { $status = "Initializing"; }
    case "checking-destination" { $status = "Checking destination"; }
    case "phase-collecting"     { $status = "Collecting"; }
    case "phase-readytogo"      { $status = "Ready to go"; }
    case "phase-opentarget"     { $status = "Opening target"; }
    case "phase-copying"        { $status = "Copying"; }
    else                        { warn $info -> { phase }; $status = ""; }
  }

  $model -> set($iters{ $source_string },
                COLUMN_STATUS, $status);

  if (defined($info -> { file_size }) &&
      defined($info -> { bytes_copied }) &&
      $info -> { file_size } != 0) {
    $model -> set($iters{ $source_string },
                  COLUMN_PROGRESS,
                  $info -> { bytes_copied } / $info -> { file_size });
  }
}

sub progress_sync {
  my ($info) = @_;

  if ($info -> { status } eq "ok") {
    return 1;
  }
  elsif ($info -> { status } eq "vfserror") {
    warn $info -> { vfs_status };
    return "abort";
  }
  elsif ($info -> { status } eq "overwrite") {
    return "abort";
  }

  return 0;
}

###############################################################################

sub quit {
  Gtk2 -> main_quit();
  Gnome2::VFS -> shutdown();
}
