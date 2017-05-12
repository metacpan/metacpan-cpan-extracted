#!/usr/bin/perl -w
#
# UI Manager
#
# The GtkUIManager object allows the easy creation of menus
# from an array of actions and a description of the menu hierarchy.
#

package ui_manager;

use strict;
use Glib qw(TRUE FALSE);
use Gtk2;

my $window = undef;

sub activate_action {
	my $action = shift;
	warn "Action \"".$action->get_name."\" activated\n";
}

sub activate_radio_action {
	my ($action, $current) = @_;
	warn "Radio action \"".$action->get_name."\" selected\n";
}

my @entries = (
  # name,              stock id,  label
  [ "FileMenu",        undef,     "_File"        ],
  [ "PreferencesMenu", undef,     "_Preferences" ],
  [ "ColorMenu",       undef,     "_Color"       ],
  [ "ShapeMenu",       undef,     "_Shape"       ],
  [ "HelpMenu",        undef,     "_Help"        ],
  # name,      stock id,  label,    accelerator,  tooltip  
  [ "New",    'gtk-new',  "_New",   "<control>N", "Create a new file", \&activate_action ],      
  [ "Open",   'gtk-open', "_Open",  "<control>O", "Open a file",       \&activate_action ], 
  [ "Save",   'gtk-save', "_Save",  "<control>S", "Save current file", \&activate_action ],
  [ "SaveAs", 'gtk-save', "Save _As...", undef,   "Save to a file",    \&activate_action ],
  [ "Quit",   'gtk-quit', "_Quit",  "<control>Q", "Quit",              \&activate_action ],
  [ "About",  undef,      "_About", "<control>A", "About",             \&activate_action ],
  [ "Logo",   "demo-gtk-logo", undef, undef,      "GTK+",              \&activate_action ],
);

my @toggle_entries = (
  [ "Bold", 'gtk-bold', "_Bold",               # name, stock id, label
     "<control>B", "Bold",                     # accelerator, tooltip 
    \&activate_action, TRUE ],                 # is_active 
);

use constant COLOR_RED   => 0;
use constant COLOR_GREEN => 1;
use constant COLOR_BLUE  => 2;

my @color_entries = (
  # name,    stock id, label,    accelerator,  tooltip, value 
  [ "Red",   undef,    "_Red",   "<control>R", "Blood", COLOR_RED   ],
  [ "Green", undef,    "_Green", "<control>G", "Grass", COLOR_GREEN ],
  [ "Blue",  undef,    "_Blue",  "<control>B", "Sky",   COLOR_BLUE  ],
);

use constant SHAPE_SQUARE    => 0;
use constant SHAPE_RECTANGLE => 1;
use constant SHAPE_OVAL      => 2;

my @shape_entries = (
  # name,        stock id, label,        accelerator,  tooltip,     value 
  [ "Square",    undef,    "_Square",    "<control>S", "Square",    SHAPE_SQUARE ],
  [ "Rectangle", undef,    "_Rectangle", "<control>R", "Rectangle", SHAPE_RECTANGLE ],
  [ "Oval",      undef,    "_Oval",      "<control>O", "Egg",       SHAPE_OVAL ],
);

my $ui_info = "<ui>
  <menubar name='MenuBar'>
    <menu action='FileMenu'>
      <menuitem action='New'/>
      <menuitem action='Open'/>
      <menuitem action='Save'/>
      <menuitem action='SaveAs'/>
      <separator/>
      <menuitem action='Quit'/>
    </menu>
    <menu action='PreferencesMenu'>
      <menu action='ColorMenu'>
	<menuitem action='Red'/>
	<menuitem action='Green'/>
	<menuitem action='Blue'/>
      </menu>
      <menu action='ShapeMenu'>
        <menuitem action='Square'/>
        <menuitem action='Rectangle'/>
        <menuitem action='Oval'/>
      </menu>
      <menuitem action='Bold'/>
    </menu>
    <menu action='HelpMenu'>
      <menuitem action='About'/>
    </menu>
  </menubar>
  <toolbar  name='ToolBar'>
    <toolitem action='Open'/>
    <toolitem action='Quit'/>
    <separator action='Sep1'/>
    <toolitem action='Logo'/>
  </toolbar>
</ui>";

sub do {
  my $do_widget = shift;

  ###static GtkWidget *window = NULL;
  
  if (!$window)
    {
      $window = Gtk2::Window->new;
      $window->set_screen ($do_widget->get_screen);
      
      $window->signal_connect (destroy => sub { $window = undef });
      $window->signal_connect (delete_event => sub {TRUE});

      my $actions = Gtk2::ActionGroup->new ("Actions");
      $actions->add_actions (\@entries, undef);
      $actions->add_toggle_actions (\@toggle_entries, undef);
      $actions->add_radio_actions (\@color_entries, COLOR_RED,
                                   \&activate_radio_action);
      $actions->add_radio_actions (\@shape_entries, SHAPE_OVAL,
                                   \&activate_radio_action);

      my $ui = Gtk2::UIManager->new;
      $ui->insert_action_group ($actions, 0);
      $window->add_accel_group ($ui->get_accel_group);
      $window->set_title ("UI Manager");
      $window->set_border_width (0);
      
#      eval {
          $ui->add_ui_from_string ($ui_info);
#	  Glib->message (undef, "building menus failed: %s", error->message);
#	  g_error_free (error);
 #     };

      my $box1 = Gtk2::VBox->new (FALSE, 0);
      $window->add ($box1);
      
      $box1->pack_start ($ui->get_widget ("/MenuBar"), FALSE, FALSE, 0);

      my $label = Gtk2::Label->new ("Type\n<alt>\nto start");
      $label->set_size_request (200, 200);
      $label->set_alignment (0.5, 0.5);
      $box1->pack_start ($label, TRUE, TRUE, 0);


      my $separator = Gtk2::HSeparator->new;
      $box1->pack_start ($separator, FALSE, TRUE, 0);


      my $box2 = Gtk2::VBox->new (FALSE, 10);
      $box2->set_border_width (10);
      $box1->pack_start ($box2, FALSE, TRUE, 0);

      my $button = Gtk2::Button->new_with_label ("close");
      $button->signal_connect_swapped (clicked => sub {$window->destroy});
      $box2->pack_start ($button, TRUE, TRUE, 0);
      #GTK_WIDGET_SET_FLAGS (button, GTK_CAN_DEFAULT);
      $button->set_flags ('can-default');
      $button->grab_default;

      $window->show_all;
    }
  else
    {
      $window->destroy;
      $window = undef;
    }

  return $window;
}
