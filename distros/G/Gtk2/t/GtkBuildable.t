#!/usr/bin/perl
use strict;
use warnings;
use Gtk2::TestHelper
  tests => 7,
  at_least_version => [2, 12, 0, 'GtkBuildable: it appeared in 2.12'];

# $Id$

# --------------------------------------------------------------------------- #

my $builder = Gtk2::Builder->new;

my $buildable = Gtk2::ListStore->new (qw/Glib::String/);
isa_ok ($buildable, 'Gtk2::Buildable');

$buildable->set_name ('store');
is ($buildable->get_name, 'store');

# --------------------------------------------------------------------------- #

$buildable = Gtk2::HBox->new;
isa_ok ($buildable, 'Gtk2::Buildable');

my $button = Gtk2::Button->new ('Button');
my $label = Gtk2::Label->new ('Label');
$buildable->add_child ($builder, $button, undef);
$buildable->add_child ($builder, $label, undef);
is_deeply([$buildable->get_children], [$button, $label]);

$buildable->set_buildable_property($builder,
                                   border_width => 23,
                                   resize_mode => 'parent');
is_deeply([$buildable->get (qw/border_width resize_mode/)], [23, 'parent']);

# --------------------------------------------------------------------------- #

$buildable = Gtk2::UIManager->new;

$buildable->add_ui_from_string (<<__EOD__);
<ui>
  <menubar name='MenuBar'>
  </menubar>
</ui>
__EOD__

isa_ok ($buildable->construct_child ($builder, "MenuBar"), "Gtk2::MenuBar");

$buildable->parser_finished ($builder);

# --------------------------------------------------------------------------- #

$buildable = Gtk2::Dialog->new;

isa_ok ($buildable->get_internal_child ($builder, 'vbox'), 'Gtk2::VBox');

__END__

Copyright (C) 2007 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
