#!/usr/bin/perl

=doc

This example shows one way to colorize rows in a SimpleList.

The basic approach is to add a color attribute to the columns in the TreeView
(remember that a SimpleList is a TreeView), and store the color information in
a hidden column in the model.  Since the Glib type system will be used to fetch
the color attribute, the hidden column must be of type Gtk2::Gdk::Color, which
requires us to add a custom column type to SimpleList.

=cut

use strict;
use warnings;
use Glib qw/TRUE FALSE/;
use Gtk2 -init;
use Gtk2::SimpleList;

# in gtk+ 2.0.x, the cell renderers don't have the cell_background_gdk
# property, so this test doesn't work right and spews messages.  object
# properties require no extra binding glue, so if you've upgraded to 
# gtk+ 2.2.x or newer after installing Gtk2-Perl, this test will magically
# start to work.  thus, this is one of those rare times when we need to
# use the lower-case runtime version check.
my $msg = Gtk2->check_version (2,2,0);
die "This example requires gtk+ 2.2.0, but we're linked against "
  . join (".", Gtk2->get_version_info)."\n"
  . "$msg\n"
	if $msg;

# add a new hidden column that holds a Gtk2::Gdk::Color.
Gtk2::SimpleList->add_column_type(
	'color',
		type     => 'Gtk2::Gdk::Color',
		renderer => 'Gtk2::CellRendererText',   
		attr     => 'hidden',
	);


my $slist = Gtk2::SimpleList->new (
			'Text Field'    => 'text',
			'Int Field'     => 'int',
			'Bool Field'    => 'bool',
			'row color'     => 'color',
	);

#
# add a color attribute to each column, getting the color information
# from the hidden column.
#
foreach my $col ($slist->get_columns) {
	foreach my $cell ($col->get_cell_renderers) {
		$col->add_attribute ($cell, cell_background_gdk => 3);
	}
}

#
# now put some data into the list; note the data for the hidden column.
# we'll leave a couple of rows uncolored.
#
@{$slist->{data}} = (
	[ 'Red',     1, FALSE, Gtk2::Gdk::Color->new (0xFFFF, 0, 0)      ],
	[ 'Green',   2, TRUE,  Gtk2::Gdk::Color->new (0, 0xFFFF, 0)      ],
	[ 'Blue',    3, FALSE, Gtk2::Gdk::Color->new (0, 0, 0xFFFF)      ],
	[ 'Cyan',    4, TRUE,  Gtk2::Gdk::Color->new (0, 0xFFFF, 0xFFFF) ],
	[ 'Magenta', 5, FALSE, Gtk2::Gdk::Color->new (0xFFFF, 0, 0xFFFF) ],
	[ 'Yellow',  6, TRUE,  Gtk2::Gdk::Color->new (0xFFFF, 0xFFFF, 0) ],
	[ 'plain',   7, FALSE, undef ],
	[ 'plain',   8, TRUE,  undef ],
);



# the rest is uninteresting.
my $win = Gtk2::Window->new;
$win->set_title ('Colorizing A List');
$win->set_border_width (6);
$win->signal_connect (delete_event => sub { Gtk2->main_quit; });

$win->add ($slist);

$win->show_all;
Gtk2->main;
