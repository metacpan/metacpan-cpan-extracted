#!/usr/bin/perl
#
# Copyright (c) 2003 by Emmanuele Bassi (see the file AUTHORS)
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the 
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
# Boston, MA  02111-1307  USA.

# This is an example of the power of GtkSourceView.  I've taken the code inside
# the test-widget test app that comes with libgtksourceview, and translated it
# in Perl. (ebassi)

use Gtk2 '-init';
use Gtk2::SourceView;

use Gnome2;
use Gnome2::VFS '-init';
use Gnome2::Print;

use Data::Dumper;

use warnings;
use strict;
use constant TRUE	=> 1;
use constant FALSE	=> 0;

our @items = (
	[
		'/_File',
		undef,
		undef, undef,
		'<Branch>',
	],
		[
			'/File/_Open',
			'<Control>O',
			\&on_file_open, 0,
			'<StockItem>', 'gtk-open',
		],
		[
			'/File/_Print Preview',
			'<Control>P',
			\&on_print_preview, 0,
			'<StockItem>', 'gtk-print',
		],
		[
			'/File/sep1',
			undef,
			undef, undef,
			'<Separator>',
		],
		[
			'/File/_Quit',
			undef,
			sub { Gtk2->main_quit; }, 0,
			'<StockItem>', 'gtk-quit',
		],
	[
		'/_Edit',
		undef,
		undef, undef,
		'<Branch>',
	],
		[
			'/Edit/Check _Brackets',
			undef,
			\&on_edit_toggled, 6,
			'<CheckItem>',
		],
		[
			'/Edit/_Syntax Highlight',
			undef,
			\&on_edit_toggled, 7,
			'<CheckItem>',
		],
	[
		'/_View',
		undef,
		undef, undef,
		'<Branch>',
	],
		[
			'/View/Show _Line Numbers',
			undef,
			\&on_view_toggled, 1,
			'<CheckItem>',
		],
		[
			'/View/Show _Markers',
			undef,
			\&on_view_toggled, 2,
			'<CheckItem>',
		],
		[
			'/View/Show M_argin',
			undef,
			\&on_view_toggled, 3,
			'<CheckItem>',
		],
		[
			'/View/sep1',
			undef,
			undef, undef,
			'<Separator>',
		],
		[
			'/View/Enable _Auto Indent',
			undef,
			\&on_view_toggled, 4,
			'<CheckItem>',
		],
		[
			'/View/Insert _Spaces Instead of Tabs',
			undef,
			\&on_view_toggled, 5,
			'<CheckItem>',
		],
		
);

sub on_file_open
{
	my ($window, $action, $menu_item) = @_;

	my $dialog = Gtk2::FileSelection->new("Open file...");
	$dialog->signal_connect(response => sub {
			my ($dialog, $response) = @_;
			my $file = $dialog->get_filename;
			
			if ('ok' eq $response)
			{
				open_file($window->{'sourcebuffer'}, $file);
				$dialog->destroy;
			}
		});
	$dialog->show;
}

sub on_print_preview
{
	my ($window, $action, $menu_item) = @_;

	my $job = Gtk2::SourceView::PrintJob->new(undef);
	$job->setup_from_view($window->{'sourceview'});
	$job->set_wrap_mode('char');
	$job->set_highlight(TRUE);
	$job->set_print_numbers(5);	# print the line number every five lines.
	
	# header and format strings uses a strftime-like format.
	$job->set_header_format("Printed on %A", undef, "%F", TRUE);
	
	my $filename = $window->{'sourcebuffer'}->{'filename'};
	$job->set_footer_format("%T", $filename, "Page %N/%Q", TRUE);

	$job->set_print_header(TRUE);
	$job->set_print_footer(TRUE);
	
	# do an async printing, in order to show the preview and the progress; a
	# nifty dialog with a progressbar should be better...
	my ($start, $end) = $window->{'sourcebuffer'}->get_bounds;
	if ($job->print_range_async($start, $end))
	{
		$job->signal_connect(begin_page => sub {
				printf "Printing %.2f    \r",
						(100.0 * $job->get_page() / $job->get_page_count());
			});
		$job->signal_connect(finished   => sub {
				print "\n";
				my $gjob = $job->get_print_job;
				my $preview = Gnome2::Print::JobPreview->new($gjob, "$0 preview");

				$preview->show;
			});
	}
	else
	{
		print STDERR "Async print failed.\n";
	}
}

sub on_edit_toggled
{
	my ($window, $action, $menu_item) = @_;

	my $active = $menu_item->get_active;
	my $sbuffer = $window->{'sourcebuffer'};

	if    ($action == 6)
	{
		$sbuffer->set_check_brackets($active);
	}
	elsif ($action == 7)
	{
		$sbuffer->set_highlight($active);
	}
}

sub on_view_toggled
{
	my ($window, $action, $menu_item) = @_;

	my $active = $menu_item->get_active;
	my $sview = $window->{'sourceview'};

	if    ($action == 1)
	{
		$sview->set_show_line_numbers($active);
	}
	elsif ($action == 2)
	{
		$sview->set_show_line_markers($active);
	}
	elsif ($action == 3)
	{
		$sview->set_show_margin($active);
	}
	elsif ($action == 4)
	{
		$sview->set_auto_indent($active);
	}
	elsif ($action == 5)
	{
		$sview->set_insert_spaces_instead_of_tabs($active);
	}	
}

sub open_file
{
	use File::Spec;
	
	my ($source_buffer, $filename) = @_;
	my ($uri, $mime_type, $lang);
	my $manager = $source_buffer->{'languages_manager'};

	# languages definitions are accessed by mime type, via the
	# LanguagesManager object.  We use Gnome2::VFS to gather the mime
	# type from the file.
	if (File::Spec->file_name_is_absolute($filename))
	{
		$mime_type = Gnome2::VFS->get_mime_type($filename);
	}
	else
	{
		my $path = File::Spec->rel2abs($filename);
		$mime_type = Gnome2::VFS->get_mime_type($path);
		$filename = $path;
	}

	if ($mime_type)
	{
		$lang = $manager->get_language_from_mime_type($mime_type);
		unless ($lang)
		{
			print STDERR "No language found for mime type '$mime_type'\n";
			$source_buffer->set('highlight', FALSE);
		}
		else
		{
			$source_buffer->set('highlight', TRUE);
			$source_buffer->set_language($lang);
		}
	}
	else
	{
		$source_buffer->set('highlight', FALSE);
		print STDERR "Couldn't get mime type for file '$filename'\n";
	}
	
	# reset buffer
	$source_buffer->set_text('');
	
	# loading a file is an atomic operation; thus, disabling undo while filling
	# the buffer is the Right Thing To Do(tm).
	$source_buffer->begin_not_undoable_action;
	open (INFILE, $filename) or die "Unable to open file '$filename'";
	while (<INFILE>)
	{
		my $iter = $source_buffer->get_end_iter;
		$source_buffer->insert($iter, $_);
	}
	$source_buffer->end_not_undoable_action;

	# a Buffer is a TextBuffer
	$source_buffer->set_modified(FALSE);
	$source_buffer->place_cursor($source_buffer->get_start_iter());

	$source_buffer->{'filename'} = $filename;
}

sub create_source_buffer
{
	my $manager = Gtk2::SourceView::LanguagesManager->new;
	my $buffer = Gtk2::SourceView::Buffer->new(undef);
	$buffer->{'languages_manager'} = $manager;

	return $buffer;
}

sub create_window
{
	my $file = shift;
	
	our $w = Gtk2::Window->new('toplevel');
	$w->signal_connect(delete_event	=> sub { Gtk2->main_quit; });
	$w->set_title('Gtk2::SourceView demo');
	$w->set_border_width(0);
	$w->set_size_request(400, 400);

	my $vbox = Gtk2::VBox->new(FALSE, 0);
	$w->add($vbox);

	my $factory = Gtk2::ItemFactory->new('Gtk2::MenuBar', '<main>', undef);
	$factory->create_items($w, @items);
	my $menu = $factory->get_widget('<main>');
	$w->{'menu'} = $menu;
	$vbox->pack_start($menu, FALSE, FALSE, 0);

	my $sw = Gtk2::ScrolledWindow->new;
	$sw->set_policy('automatic', 'automatic');
	$sw->set_shadow_type('in');
	$vbox->pack_start($sw, TRUE, TRUE, 0);

	my $sb = create_source_buffer();
	open_file($sb, $file);
	$w->{'sourcebuffer'} = $sb;

	my $sourceview = Gtk2::SourceView::View->new_with_buffer($sb);
	# an editor using a non-proportional font? *yuk*!
	my $font_desc = Gtk2::Pango::FontDescription->from_string("monospace 10");
	if ($font_desc)
	{
		$sourceview->modify_font($font_desc);
	}
	
	$w->{'sourceview'} = $sourceview;
	$sw->add($sourceview);

	$vbox->show_all;
	
	return $w;
}

my $file = $ARGV[0] || $0;
print "file := $file\n";

my $win = create_window($file);
$win->show;

Gtk2->main;

Gnome2::VFS->shutdown;

0;
