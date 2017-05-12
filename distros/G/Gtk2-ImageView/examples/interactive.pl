#!/usr/bin/perl -w

# Copyright (c) 2007 by Muppet <scott@asofyet.org>
# based on the original gtkimageview/tests/interactive.c
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# -*- Mode: perl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4; coding: utf-8 -*-
# vim: set expandtab softtabstop=4 shiftwidth=4 :

use strict;

# Library under test.
use Gtk2::ImageView;

use Glib ':constants';

# //////////////////////////////////////////////////////////////////////
# ///// Global data ////////////////////////////////////////////////////
# //////////////////////////////////////////////////////////////////////
my $open_dialog;
my $view;
my $main_window;
my $default_group;
my $image_group;
my $transform_group;
my $is_fullscreen;
my $statusbar;

# Label that displays the active selection.
my $sel_info_label;

# Tools
my $dragger;
my $selector;
my $painter;

# Context ID:s for the Statusbar
my $help_msg_cid;
my $image_info_cid;

# //////////////////////////////////////////////////////////////////////
# ///// Opener dialog //////////////////////////////////////////////////
# //////////////////////////////////////////////////////////////////////
sub init_open_dialog {
    $open_dialog = Gtk2::FileChooserDialog->new ("Open Image",
                                                 $main_window,
                                                 'open',
                                                 'gtk-cancel' => 'cancel',
                                                 'gtk-open'   => 'accept');
}

# //////////////////////////////////////////////////////////////////////
# ///// ImageViewerApp /////////////////////////////////////////////////
# //////////////////////////////////////////////////////////////////////
sub push_image_info {
    my ($basename, $anim) = @_;
    $statusbar->push ($image_info_cid,
                      sprintf ("%s, %d x %d pixels",
                               $basename, $anim->get_width, $anim->get_height));
}


sub load_filename {
    my ($path) = @_;

    eval {
        my $anim = Gtk2::Gdk::PixbufAnimation->new_from_file ($path);

        $view->set_anim ($anim);

        my $basename = Glib::filename_display_basename ($path);
        $main_window->set_title ($basename);
        push_image_info ($basename, $anim);

        $image_group->set_sensitive (TRUE);

        # Only active the transform_group if the loaded object is a single
        # image -- transformations cannot be applied to animations.
        $transform_group->set_sensitive ($anim->is_static_image);
    };
    if ($@) {
        print "No anim!  $@\n";
    }
}

sub gdk_rectangle_to_str {
    my $r = shift;
    sprintf "(%d, %d)-[%d, %d]", $r->x, $r->y, $r->width, $r->height;
}

sub get_enum_nick {
    my ($package, $value) = @_;
    my @v = Glib::Type->list_values ($package);
    return $v[$value]{nick};
}

sub get_enum_value {
    my ($package, $string) = @_;
    my @v = Glib::Type->list_values ($package);
    for (my $i = 0 ; $i < @v ; $i++) {
        return $i if $v[$i]{name} eq $string or $v[$i]{nick} eq $string;
    }
}
sub GTK_IMAGE_TRANSP_COLOR { get_enum_value ('Gtk2::ImageView::Transp', 'color') }
sub GTK_IMAGE_TRANSP_BACKGROUND { get_enum_value 'Gtk2::ImageView::Transp', 'background' }
sub GTK_IMAGE_TRANSP_GRID { get_enum_value 'Gtk2::ImageView::Transp', 'grid' }

#sub GTK_IMAGE_TRANSP_COLOR { 0 }
#sub GTK_IMAGE_TRANSP_BACKGROUND { 1 }
#sub GTK_IMAGE_TRANSP_GRID { 2 }


# //////////////////////////////////////////////////////////////////////
# ///// Callbacks //////////////////////////////////////////////////////
# //////////////////////////////////////////////////////////////////////
sub sel_changed_cb {
    my ($selector, $label) = @_;
    my $sel = $selector->get_selection;
    if (defined $sel) {
        $label->set_text (gdk_rectangle_to_str($sel));
    } else {
        $label->set_text ("");
    }
}

sub change_image_tool_cb {
    my ($action, $current) = @_;
    my $value = $current->get_current_value ();
    my $tool = $selector;
    if ($value == 10) {
        $tool = $dragger;
    } elsif ($value == 30) {
        $tool = $painter;
    }
    $view->set_tool ($tool);
    if ($value == 20) {
        sel_changed_cb ($selector, $sel_info_label);
    } else {
        $sel_info_label->set_text ("");
    }
}

sub zoom_in_cb {
    $view->zoom_in ();
}

sub zoom_out_cb {
    $view->zoom_out ();
}

sub zoom_100_cb {
    $view->set_zoom (1.0);
}

sub zoom_to_fit_cb {
    $view->set_fitting (TRUE);
}

sub open_image_cb {
    my ($action) = @_;
    if (!$open_dialog) {
        init_open_dialog ();
    }
    if ($open_dialog->run () eq 'accept') {
        load_filename ($open_dialog->get_filename ());
    }
    $open_dialog->hide ();
}

sub fullscreen_cb {
    # I do not have the patience to implement all things you do to
    # fullscreen for real. This is a faked approximation.
    $is_fullscreen = !$is_fullscreen;
    if ($is_fullscreen) {
        $main_window->fullscreen ();
    } else {
        $main_window->unfullscreen ();
    }

    $view->set_show_cursor (!$is_fullscreen);
    $view->set_show_frame (!$is_fullscreen);
    $view->set_black_bg ($is_fullscreen);
}

sub transform_cb {
    my $pixbuf = $view->get_pixbuf ();
# Not doing this just now, as perl is very inefficient for such things
#    my $pixels = $pixbuf->get_pixels ();
#    my $rowstride = $pixbuf->get_rowstride ();
#    my $n_channels = $pixbuf->get_n_channels ();
#    for (int y = 0; y < $pixbuf->get_height (); y++)
#        for (int x = 0; x < $pixbuf->get_width (); x++)
#        {
#            guchar *p = pixels + y * rowstride + x * n_channels;
#            for (int n  = 0; n < 3; n++)
#                p[n] ^= 0xff;
#        }
    $view->set_pixbuf ($pixbuf, FALSE);
}

sub change_zoom_quality_cb {
    my ($action, $current) = @_;
    $view->set_interpolation ($current->get_current_value ()
                              ? 'bilinear'
                              : 'nearest');
}

sub change_transp_type_cb {
    my ($action, $current) = @_;
    my $color = 0;
    my $transp = $current->get_current_value;
    if ($transp == GTK_IMAGE_TRANSP_COLOR) {
        $color = 0x000000;
    }
    $view->set_transp (get_enum_nick('Gtk2::ImageView::Transp', $transp), $color);
}

sub menu_item_select_cb {
    my ($proxy) = @_;

#    GtkAction *action = g_object_get_data (G_OBJECT (proxy), "gtk-action");
    my $action =
        Glib::Object->new_from_pointer ($proxy->get_data ('gtk-action'));

    my $msg = $action->get ('tooltip');
    $statusbar->push ($help_msg_cid, $msg) if $msg;
}

sub menu_item_deselect_cb {
    my ($item) = @_;
    $statusbar->pop ($help_msg_cid);
}

sub connect_proxy_cb {
    my ($ui, $action, $proxy) = @_;
    return unless $proxy->isa ('Gtk2::MenuItem');
    $proxy->signal_connect (select => \&menu_item_select_cb);
    $proxy->signal_connect (deselect => \&menu_item_deselect_cb);
}

sub disconnect_proxy_cb {
    my ($ui, $action, $proxy) = @_;
    return unless $proxy->isa ('Gtk2::MenuItem');
    $proxy->signal_handlers_disconnect_by_func (\&menu_item_select_cb);
    $proxy->signal_handlers_disconnect_by_func (\&menu_item_deselect_cb);
}

sub zoom_changed_cb {
    my ($view, $label) = @_;
    $label->set_text (sprintf "%d%%", int ($view->get_zoom () * 100.0));
}

# //////////////////////////////////////////////////////////////////////
# ///// MainWindow /////////////////////////////////////////////////////
# //////////////////////////////////////////////////////////////////////
sub main_window_new {
    my ($widget, $width, $height) = @_;
    my $window = Gtk2::Window->new ();
    $window->set_default_size ($width, $height);
    $window->add ($widget);
    $window->signal_connect (delete_event => sub { Gtk2->main_quit } );
    return $window;
}

# //////////////////////////////////////////////////////////////////////
# ///// UI Setup ///////////////////////////////////////////////////////
# //////////////////////////////////////////////////////////////////////
my @default_actions = (
    [ "FileMenu", undef, "_File" ],
    [
        "Open",
        'gtk-open',
        "_Open image",
        undef,
        "Open an image",
        \&open_image_cb
    ],
    [
        "Quit",
        'gtk-quit',
        "_Quit me!",
        undef,
        "Quit the program",
        sub { Gtk2->main_quit },
    ],
    ["EditMenu", undef, "_Edit"],
    ["ViewMenu", undef, "_View"],
    ["TranspMenu", undef, "_Transparency"]
);

my @quality_actions = (
    [
        "QualityHigh",
        undef,
        "_High Quality",
        undef,
        "Use high quality zoom",
        TRUE
    ],
    [
        "QualityLow",
        undef,
        "_Low Quality",
        undef,
        "Use low quality zoom",
        FALSE
    ]
);

my @transp_actions = (
    [
        "TranspGrid",
        undef,
        "Square _Grid",
        undef,
        "Draw a grid on transparent parts",
        GTK_IMAGE_TRANSP_GRID
    ],
    [
        "TranspBackground",
        undef,
        "_Background",
        undef,
        "Draw background color on transparent parts",
        GTK_IMAGE_TRANSP_BACKGROUND
    ],
    [
        "TranspBlack",
        undef,
        "_Black",
        undef,
        "Draw black color on transparent parts",
        GTK_IMAGE_TRANSP_COLOR
    ]
);

my @image_actions = (
    [
        "ZoomIn",
        'gtk-zoom-in',
        "Zoom _In",
        "<control>plus",
        "Zoom in one step",
        \&zoom_in_cb
    ],
    [
        "ZoomOut",
        'gtk-zoom-out',
        "Zoom _Out",
        "<control>minus",
        "Zoom out one step",
        \&zoom_out_cb
    ],
    [
        "ZoomNormal",
        'gtk-zoom-100',
        "_Normal Size",
        "<control>0",
        "Set zoom to natural size of the image",
        \&zoom_100_cb
    ],
    [
        "ZoomFit",
        'gtk-zoom-fit',
        "Best _Fit",
        undef,
        "Adapt zoom to fit image",
        \&zoom_to_fit_cb
    ],
    [
        "Fullscreen",
        'gtk-fullscreen',
        "_Fullscreen Mode",
        "F11",
        "View image in fullscreen",
        \&fullscreen_cb
    ]
);

my @image_tools = (
    [
        "DraggerTool",
        'gtk-refresh',
        "_Drag",
        undef,
        "Use the hand tool",
        10
    ],
    [
        "SelectorTool",
        'gtk-media-pause',
        "_Select",
        undef,
        "Use the rectangular selection tool",
        20
    ],
    [
        "PainterTool",
        'gtk-media-play',
        "_Paint",
        undef,
        "Use the painter tool",
        30
    ]
);

my @transform_actions = (
    [
        "Transform",
        undef,
        "_Transform",
        "<control>T",
        "Apply an XOR transformation to the image",
        \&transform_cb
    ]
);

my $ui_info = "
<ui>
  <menubar name = 'MenuBar'>
    <menu action = 'FileMenu'>
      <menuitem action = 'Open'/>
      <menuitem action = 'Quit'/>
    </menu>
    <menu action = 'EditMenu'>
      <menuitem action = 'Transform'/>
      <separator/> 
      <menuitem action = 'DraggerTool'/>
      <menuitem action = 'SelectorTool'/>
      <menuitem action = 'PainterTool'/>
    </menu>
    <menu action = 'ViewMenu'>
      <menuitem action = 'Fullscreen'/>
      <separator/>
      <menuitem action = 'ZoomIn'/>
      <menuitem action = 'ZoomOut'/>
      <menuitem action = 'ZoomNormal'/>
      <menuitem action = 'ZoomFit'/>
      <separator/>
      <menu action = 'TranspMenu'>
        <menuitem action = 'TranspGrid'/>
        <menuitem action = 'TranspBackground'/>
        <menuitem action = 'TranspBlack'/>
      </menu>
      <separator/>
      <menuitem action = 'QualityHigh'/>
      <menuitem action = 'QualityLow'/>
    </menu>
  </menubar>
  <toolbar name = 'ToolBar'>
    <toolitem action='Quit'/>
    <toolitem action='Open'/>
    <separator/>
    <toolitem action='DraggerTool'/>
    <toolitem action='SelectorTool'/>
    <toolitem action='PainterTool'/>
    <separator/>
    <toolitem action='ZoomIn'/>
    <toolitem action='ZoomOut'/>
    <toolitem action='ZoomNormal'/>
    <toolitem action='ZoomFit'/>
  </toolbar>
</ui>";


sub parse_ui {
    my $uimanager = shift;

    eval { $uimanager->add_ui_from_string ($ui_info) };

    if ($@) {
        die "Unable to create menus: $@\n";
    }
}

sub add_action_groups {
    my $uimanager = shift;

    # Setup the default group.
    $default_group = Gtk2::ActionGroup->new ("default");
    $default_group->add_actions (\@default_actions);
    $default_group->add_radio_actions (\@image_tools,
                                       10,
                                       \&change_image_tool_cb);
    $uimanager->insert_action_group ($default_group, 0);

    # Setup the image group.
    $image_group = Gtk2::ActionGroup->new ("image");
    $image_group->add_actions (\@image_actions);
    $image_group->add_radio_actions (\@quality_actions,
                                     TRUE,
                                     \&change_zoom_quality_cb);
    $image_group->add_radio_actions (\@transp_actions,
                                     GTK_IMAGE_TRANSP_GRID,
                                     \&change_transp_type_cb);
    $image_group->set_sensitive (FALSE);
    $uimanager->insert_action_group ($image_group, 0);

    # Transform group
    $transform_group = Gtk2::ActionGroup->new ("transform");
    if ($transform_group) {
        $transform_group->add_actions (\@transform_actions);
        $transform_group->set_sensitive (FALSE);
        $uimanager->insert_action_group ($transform_group, 0);
    }
}

sub setup_layout {
    my $uimanager = shift;

    my $box = Gtk2::VBox->new (FALSE, 0);
    
    my $menu = $uimanager->get_widget ("/MenuBar");
    $box->pack_start ($menu, FALSE, FALSE, 0);

    my $toolbar = $uimanager->get_widget ("/ToolBar");
    $box->pack_start ($toolbar, FALSE, FALSE, 0);

    my $scroll_win = Gtk2::ImageView::ScrollWin->new ($view);

    $box->pack_start ($scroll_win, TRUE, TRUE, 0); 

    $statusbar = Gtk2::Statusbar->new ();

    # A label in the statusbar that displays the current selection if
    # there is one.
    my $sel_info_frame = Gtk2::Frame->new ();
    $sel_info_frame->set_shadow_type ('in');

    $sel_info_label = Gtk2::Label->new ("");
    $sel_info_frame->add ($sel_info_label);

    $selector->signal_connect (selection_changed => \&sel_changed_cb,
                               $sel_info_label);
    
    $statusbar->pack_start ($sel_info_frame, FALSE, FALSE, 0);

    # A label in the statusbar that displays the current zoom. It
    # updates its text when the zoom-changed signal is fired from the
    # view.
    my $zoom_info_frame = Gtk2::Frame->new ();
    $zoom_info_frame->set_shadow_type ('in');

    my $zoom_info_label = Gtk2::Label->new ("100%");
    $zoom_info_frame->add ($zoom_info_label);

    $view->signal_connect (zoom_changed => \&zoom_changed_cb, $zoom_info_label);

    $statusbar->pack_start ($zoom_info_frame, FALSE, FALSE, 0);

    $box->pack_end ($statusbar, FALSE, FALSE, 0);
    return $box;
}

sub setup_main_window {
    my $uimanager = Gtk2::UIManager->new ();

    $uimanager->signal_connect (connect_proxy => \&connect_proxy_cb);
    $uimanager->signal_connect (disconnect_proxy => \&disconnect_proxy_cb);

    add_action_groups ($uimanager);
    parse_ui ($uimanager);

    my $accels = $uimanager->get_accel_group ();
    die "no accels!" unless $accels;

    my $vbox = setup_layout ($uimanager);
    $main_window = main_window_new ($vbox, 700, 500);
    $main_window->add_accel_group ($accels);

    $view->grab_focus ();

    # Setup context ID:s
    $help_msg_cid = $statusbar->get_context_id ("help_msg");
    $image_info_cid = $statusbar->get_context_id ("image_info");
}

#	char **filenames = NULL;
#	GOptionEntry options[] = {
#		{
#			G_OPTION_REMAINING, '\0', 0, G_OPTION_ARG_FILENAME_ARRAY,
#			&filenames, NULL, "[FILE...]"
#		},
#		{NULL}
#	};
#	GOptionContext *ctx = g_option_context_new ("Sample image viewer");
#	g_option_context_add_main_entries (ctx, options, "example1");
#	g_option_context_parse (ctx, &argc, &argv, NULL);
#	g_option_context_free (ctx);
	
Gtk2->init;

$view = Gtk2::ImageView::Anim->new ();
print "Using GtkImageView version ", $view->library_version, "\n";

$dragger = Gtk2::ImageView::Tool::Dragger->new ($view);
$selector = Gtk2::ImageView::Tool::Selector->new ($view);
$painter = Gtk2::ImageView::Tool::Painter->new ($view);

setup_main_window ();

load_filename ($ARGV[0]) if @ARGV;

$main_window->show_all ();
Gtk2->main ();
