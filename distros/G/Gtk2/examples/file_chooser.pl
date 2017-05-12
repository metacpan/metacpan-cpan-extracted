#!/usr/bin/perl -w

=doc

Gtk+ 2.4 introduces a new file dialog to replace the aged Gtk2::FileSelection.
This new widget is actually an interface known as Gtk2::FileChooser; the
most-commonly-used implementation of that interface would be
Gtk2::FileChooserDialog, a Gtk2::Dialog which has all the methods defined by
Gtk2::FileChooser.

This example shows how to use the file chooser to ask the user for a file name;
we also add a preview widget and a shortcut, because we can.

=cut

use Glib qw(TRUE);
use Gtk2 -init;

die "This example requires gtk+ 2.4.0, but we're compiled for "
  . join (".", Gtk2->GET_VERSION_INFO)."\n"
	unless Gtk2->CHECK_VERSION (2,4,0);

my $file_chooser =
	Gtk2::FileChooserDialog->new ('This is the spiffy new file chooser!',
	                              undef, 'open',
	                              'gtk-cancel' => 'cancel',
                                      'gtk-ok' => 'ok');

# create a preview widget, which will show a quick summary of information
# about the selected file, updated whenever the selection changes.
# note that this assumes you're on a unix-like system with the 'file'
# utility installed.
my $preview_widget = Gtk2::Label->new ('wheeeee');
$preview_widget->set_line_wrap (TRUE);
$preview_widget->set_size_request (150, -1);
$file_chooser->set (preview_widget => $preview_widget,
                    preview_widget_active => TRUE);
$file_chooser->signal_connect (selection_changed => sub {
	my $filename = $file_chooser->get_preview_filename;
	# we'll hide the preview widget if the selected item is a directory.
	# in practice, you may find this really annoying, as it causes the
	# window to change size.
	my $active = defined $filename && not -d $filename;
	if ($active) {
		my $size = sprintf '%.1fK', (-s $filename) / 1024;
		my $desc = `file '$filename'`;
		$desc =~ s/^$filename:\s*//;
		$preview_widget->set_text ("$size\n$desc");
	}
	$file_chooser->set (preview_widget_active => $active);
});

# add an app-specific entry to the shortcut list.
$file_chooser->add_shortcut_folder ('/tmp');
eval { $file_chooser->add_shortcut_folder_uri ('http://localhost/'); };
warn "couldn't add shortcut: $@\n" if $@;

if ('ok' eq $file_chooser->run) {
	# you can get the user's selection as a filename or a uri.
	my $uri = $file_chooser->get_uri;
	print "uri $uri\n";
	my $filename = $file_chooser->get_filename;
	print "filename $filename\n";
}

$file_chooser->destroy;
