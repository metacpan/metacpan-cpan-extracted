#!/usr/bin/perl
use strict;
use warnings;

use Glib qw(TRUE FALSE);
use GStreamer -init;
use Gtk2 -init;
use Gtk2::GladeXML;

$/ = undef;
my $xml = Gtk2::GladeXML -> new_from_buffer(<DATA>);
$xml -> signal_autoconnect_from_package("main");

sub my_bus_callback {
  my ($bus, $message, $loop) = @_;
  my $done = FALSE;

  if ($message -> type & "tag") {
    my $tags = $message -> tag_list;
    foreach (qw(artist title album)) {
      if (exists $tags -> { $_ }) {
        $xml -> get_widget("entry_$_") -> set_text($tags -> { $_ } -> [0]);
        $done = TRUE;
      }
    }
  }

  elsif ($message -> type & "error") {
    warn $message -> error;
    $loop -> quit();
  }

  elsif ($message -> type & "eos") {
    $loop -> quit();
  }

  $loop -> quit() if $done;

  # remove message from the queue
  return TRUE;
}

sub on_delete_event {
  Gtk2 -> main_quit();
}

sub on_selection_changed {
  my ($chooser) = @_;

  my $file = $chooser -> get_filename();
  return unless $file;

  my $pipeline = GStreamer::Pipeline -> new("pipe");

  my ($source, $decoder) =
    GStreamer::ElementFactory -> make(filesrc => "source",
                                      decodebin => "decoder");

  $pipeline -> add($source, $decoder);
  $source -> link($decoder);

  my $loop = Glib::MainLoop -> new(undef, FALSE);

  $source -> set(location => Glib::filename_to_unicode $file);
  $pipeline -> get_bus() -> add_watch(\&my_bus_callback, $loop);

  $pipeline -> set_state("playing") or die "Could not start playing";
  $loop -> run();
  $pipeline -> set_state("null");
}

sub on_save_clicked {
  my $chooser = $xml -> get_widget("chooser");

  warn "Saving doesn't work yet";
  return;

  my $file = $chooser -> get_filename();

  my $pipeline = GStreamer::Pipeline -> new("pipeline");
  my ($source, $tagger, $sink) =
    GStreamer::ElementFactory -> make(filesrc => "src",
                                      id3mux => "tagger",
                                      filesink => "sink");

  my $backup = $file . ".bak";
  rename $file, $backup;

  $source -> set(location => Glib::filename_to_unicode $backup);
  $sink -> set(location => Glib::filename_to_unicode $file);

  $tagger -> set_tag_merge_mode("keep");

  foreach my $tag (qw(artist title album)) {
    my $value = $xml -> get_widget("entry_$tag") -> get_text();
    $tagger -> add_tags("replace", $tag => $value);
  }

  $source -> link($tagger, $sink) or die "Could not link";
  $pipeline -> add($source, $tagger, $sink);
  $pipeline -> set_state("playing") or die "Could not start playing";

  while ($pipeline -> iterate()) { }

  $pipeline -> set_state("null");
}

Gtk2 -> main();

__DATA__
<?xml version="1.0" standalone="no"?> <!--*- mode: xml -*-->
<!DOCTYPE glade-interface SYSTEM "http://glade.gnome.org/glade-2.0.dtd">

<glade-interface>

<widget class="GtkWindow" id="main_window">
  <property name="visible">True</property>
  <property name="title" translatable="yes">Tag Writer</property>
  <property name="type">GTK_WINDOW_TOPLEVEL</property>
  <property name="window_position">GTK_WIN_POS_NONE</property>
  <property name="modal">False</property>
  <property name="resizable">True</property>
  <property name="destroy_with_parent">False</property>
  <property name="decorated">True</property>
  <property name="skip_taskbar_hint">False</property>
  <property name="skip_pager_hint">False</property>
  <property name="type_hint">GDK_WINDOW_TYPE_HINT_NORMAL</property>
  <property name="gravity">GDK_GRAVITY_NORTH_WEST</property>
  <property name="focus_on_map">True</property>
  <signal name="delete_event" handler="on_delete_event" last_modification_time="Sun, 12 Jun 2005 18:16:58 GMT"/>

  <child>
    <widget class="GtkVBox" id="vbox1">
      <property name="border_width">5</property>
      <property name="visible">True</property>
      <property name="homogeneous">False</property>
      <property name="spacing">0</property>

      <child>
	<widget class="GtkFileChooserButton" id="chooser">
	  <property name="visible">True</property>
	  <property name="title" translatable="yes">Select a File</property>
	  <property name="action">GTK_FILE_CHOOSER_ACTION_OPEN</property>
	  <property name="local_only">True</property>
	  <property name="show_hidden">False</property>
	  <property name="width_chars">-1</property>
	  <signal name="selection_changed" handler="on_selection_changed" last_modification_time="Sun, 12 Jun 2005 18:04:45 GMT"/>
	</widget>
	<packing>
	  <property name="padding">0</property>
	  <property name="expand">False</property>
	  <property name="fill">True</property>
	</packing>
      </child>

      <child>
	<widget class="GtkHSeparator" id="hseparator1">
	  <property name="visible">True</property>
	</widget>
	<packing>
	  <property name="padding">5</property>
	  <property name="expand">True</property>
	  <property name="fill">True</property>
	</packing>
      </child>

      <child>
	<widget class="GtkTable" id="table1">
	  <property name="visible">True</property>
	  <property name="n_rows">3</property>
	  <property name="n_columns">2</property>
	  <property name="homogeneous">False</property>
	  <property name="row_spacing">0</property>
	  <property name="column_spacing">0</property>

	  <child>
	    <widget class="GtkLabel" id="label1">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Artist: </property>
	      <property name="use_underline">False</property>
	      <property name="use_markup">False</property>
	      <property name="justify">GTK_JUSTIFY_LEFT</property>
	      <property name="wrap">False</property>
	      <property name="selectable">False</property>
	      <property name="xalign">0</property>
	      <property name="yalign">0.5</property>
	      <property name="xpad">0</property>
	      <property name="ypad">0</property>
	      <property name="ellipsize">PANGO_ELLIPSIZE_NONE</property>
	      <property name="width_chars">-1</property>
	      <property name="single_line_mode">False</property>
	      <property name="angle">0</property>
	    </widget>
	    <packing>
	      <property name="left_attach">0</property>
	      <property name="right_attach">1</property>
	      <property name="top_attach">0</property>
	      <property name="bottom_attach">1</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkLabel" id="label2">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Title: </property>
	      <property name="use_underline">False</property>
	      <property name="use_markup">False</property>
	      <property name="justify">GTK_JUSTIFY_LEFT</property>
	      <property name="wrap">False</property>
	      <property name="selectable">False</property>
	      <property name="xalign">0</property>
	      <property name="yalign">0.5</property>
	      <property name="xpad">0</property>
	      <property name="ypad">0</property>
	      <property name="ellipsize">PANGO_ELLIPSIZE_NONE</property>
	      <property name="width_chars">-1</property>
	      <property name="single_line_mode">False</property>
	      <property name="angle">0</property>
	    </widget>
	    <packing>
	      <property name="left_attach">0</property>
	      <property name="right_attach">1</property>
	      <property name="top_attach">1</property>
	      <property name="bottom_attach">2</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkLabel" id="label3">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">Album: </property>
	      <property name="use_underline">False</property>
	      <property name="use_markup">False</property>
	      <property name="justify">GTK_JUSTIFY_LEFT</property>
	      <property name="wrap">False</property>
	      <property name="selectable">False</property>
	      <property name="xalign">0</property>
	      <property name="yalign">0.5</property>
	      <property name="xpad">0</property>
	      <property name="ypad">0</property>
	      <property name="ellipsize">PANGO_ELLIPSIZE_NONE</property>
	      <property name="width_chars">-1</property>
	      <property name="single_line_mode">False</property>
	      <property name="angle">0</property>
	    </widget>
	    <packing>
	      <property name="left_attach">0</property>
	      <property name="right_attach">1</property>
	      <property name="top_attach">2</property>
	      <property name="bottom_attach">3</property>
	      <property name="x_options">fill</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkEntry" id="entry_artist">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="editable">True</property>
	      <property name="visibility">True</property>
	      <property name="max_length">0</property>
	      <property name="text" translatable="yes"></property>
	      <property name="has_frame">True</property>
	      <property name="invisible_char">*</property>
	      <property name="activates_default">False</property>
	    </widget>
	    <packing>
	      <property name="left_attach">1</property>
	      <property name="right_attach">2</property>
	      <property name="top_attach">0</property>
	      <property name="bottom_attach">1</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkEntry" id="entry_title">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="editable">True</property>
	      <property name="visibility">True</property>
	      <property name="max_length">0</property>
	      <property name="text" translatable="yes"></property>
	      <property name="has_frame">True</property>
	      <property name="invisible_char">*</property>
	      <property name="activates_default">False</property>
	    </widget>
	    <packing>
	      <property name="left_attach">1</property>
	      <property name="right_attach">2</property>
	      <property name="top_attach">1</property>
	      <property name="bottom_attach">2</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkEntry" id="entry_album">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>
	      <property name="editable">True</property>
	      <property name="visibility">True</property>
	      <property name="max_length">0</property>
	      <property name="text" translatable="yes"></property>
	      <property name="has_frame">True</property>
	      <property name="invisible_char">*</property>
	      <property name="activates_default">False</property>
	    </widget>
	    <packing>
	      <property name="left_attach">1</property>
	      <property name="right_attach">2</property>
	      <property name="top_attach">2</property>
	      <property name="bottom_attach">3</property>
	      <property name="y_options"></property>
	    </packing>
	  </child>
	</widget>
	<packing>
	  <property name="padding">0</property>
	  <property name="expand">True</property>
	  <property name="fill">True</property>
	</packing>
      </child>

      <child>
	<widget class="GtkHSeparator" id="hseparator2">
	  <property name="visible">True</property>
	</widget>
	<packing>
	  <property name="padding">5</property>
	  <property name="expand">True</property>
	  <property name="fill">True</property>
	</packing>
      </child>

      <child>
	<widget class="GtkButton" id="button_save">
	  <property name="visible">True</property>
	  <property name="can_default">True</property>
	  <property name="can_focus">True</property>
	  <property name="relief">GTK_RELIEF_NORMAL</property>
	  <property name="focus_on_click">True</property>
	  <signal name="clicked" handler="on_save_clicked" last_modification_time="Sun, 12 Jun 2005 18:09:53 GMT"/>

	  <child>
	    <widget class="GtkAlignment" id="alignment1">
	      <property name="visible">True</property>
	      <property name="xalign">0.5</property>
	      <property name="yalign">0.5</property>
	      <property name="xscale">0</property>
	      <property name="yscale">0</property>
	      <property name="top_padding">0</property>
	      <property name="bottom_padding">0</property>
	      <property name="left_padding">0</property>
	      <property name="right_padding">0</property>

	      <child>
		<widget class="GtkHBox" id="hbox1">
		  <property name="visible">True</property>
		  <property name="homogeneous">False</property>
		  <property name="spacing">2</property>

		  <child>
		    <widget class="GtkImage" id="image1">
		      <property name="visible">True</property>
		      <property name="stock">gtk-save</property>
		      <property name="icon_size">4</property>
		      <property name="xalign">0.5</property>
		      <property name="yalign">0.5</property>
		      <property name="xpad">0</property>
		      <property name="ypad">0</property>
		    </widget>
		    <packing>
		      <property name="padding">0</property>
		      <property name="expand">False</property>
		      <property name="fill">False</property>
		    </packing>
		  </child>

		  <child>
		    <widget class="GtkLabel" id="label4">
		      <property name="visible">True</property>
		      <property name="label" translatable="yes">Save</property>
		      <property name="use_underline">True</property>
		      <property name="use_markup">False</property>
		      <property name="justify">GTK_JUSTIFY_LEFT</property>
		      <property name="wrap">False</property>
		      <property name="selectable">False</property>
		      <property name="xalign">0.5</property>
		      <property name="yalign">0.5</property>
		      <property name="xpad">0</property>
		      <property name="ypad">0</property>
		      <property name="ellipsize">PANGO_ELLIPSIZE_NONE</property>
		      <property name="width_chars">-1</property>
		      <property name="single_line_mode">False</property>
		      <property name="angle">0</property>
		    </widget>
		    <packing>
		      <property name="padding">0</property>
		      <property name="expand">True</property>
		      <property name="fill">True</property>
		    </packing>
		  </child>
		</widget>
	      </child>
	    </widget>
	  </child>
	</widget>
	<packing>
	  <property name="padding">0</property>
	  <property name="expand">False</property>
	  <property name="fill">False</property>
	</packing>
      </child>
    </widget>
  </child>
</widget>

</glade-interface>
