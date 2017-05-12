#
# $Id$
#

use Gtk2::TestHelper
	at_least_version => [2, 4, 0, 'GtkFileChooser is new in 2.4'],
	tests => 43,
	skip_all => 'this test is unreliable',
	;
use File::Spec;
use Cwd;

sub update {
  Gtk2->main_iteration while Gtk2->events_pending;
}

my $file_chooser = Gtk2::FileChooserWidget->new ('save');

isa_ok ($file_chooser, 'Gtk2::FileChooser');

is ($file_chooser->get_action, 'save', 'mode option from construction');

# Filename manipulation
#
my $filename = 'something that may not exist';
my $cwd = cwd ();

$file_chooser->set_current_name ($filename);
update; is_idle (sub {$file_chooser->get_filename},
                 undef,
                 'set current name');

$filename = File::Spec->catfile ($cwd, 'gtk2perl.h');
ok ($file_chooser->set_filename ($filename),
    'set filename to something that exists');
update; is_idle (sub {$file_chooser->get_filename},
                 $filename,
                 'set current name to something that does exist');

ok ($file_chooser->select_filename ($filename));
update; is_idle (sub {$file_chooser->get_filename},
                 $filename,
                 'select something');

my @list = $file_chooser->get_filenames;
is (scalar (@list), 1, 'selected one thing');
is ($list[0], $filename, 'selected '.$filename);

$file_chooser->select_all;
@list = $file_chooser->get_filenames;
ok (scalar (@list));
$file_chooser->unselect_all;

my $folder = File::Spec->catfile ($cwd, 't');
ok ($file_chooser->set_current_folder ($folder));
update; is_idle (sub{$file_chooser->get_current_folder}, $folder);

ok ($file_chooser->set_current_folder ($cwd));
update; is_idle (sub{$file_chooser->get_current_folder}, $cwd);

# URI manipulation
#
my $uri = Glib::filename_to_uri (File::Spec->rel2abs ($0), undef);
ok ($file_chooser->set_uri ($uri));
update; is_idle (sub {$file_chooser->get_uri},
                 $uri,
                 'uri');

ok ($file_chooser->select_uri ($uri));
update; ok_idle (sub {scalar ($file_chooser->get_uris)},
                 'selected a uri');
$file_chooser->unselect_uri ($uri);

# need to get the file off the end for these
$uri =~ s{/GtkFileChooser.t$}{};
ok ($file_chooser->set_current_folder_uri ($uri));
is ($file_chooser->get_current_folder_uri, $uri);

# Preview widget
#
my $preview_widget = Gtk2::Frame->new ('whee');
$file_chooser->set_preview_widget ($preview_widget);
is ($file_chooser->get_preview_widget, $preview_widget);

$file_chooser->set_preview_widget_active (TRUE);
ok ($file_chooser->get_preview_widget_active);

$file_chooser->set_preview_widget_active (TRUE);
ok ($file_chooser->get_preview_widget_active);

$file_chooser->set_use_preview_label (TRUE);
is ($file_chooser->get_use_preview_label, TRUE);

$file_chooser->set_current_folder ($cwd);
$filename = File::Spec->catfile ($cwd, 'gtk2perl.h');
ok ($file_chooser->select_filename ($filename));

TODO: {
  local $TODO = 'GtkFileChooser trouble';

  update;
  is_idle (sub {$file_chooser->get_preview_filename},
           $filename, 'get_preview_filename');
  is_idle (sub {$file_chooser->get_preview_uri},
           'file://'.$filename, 'get_preview_uri');
}

# Extra widget
#
my $extra_widget = Gtk2::Frame->new ('extra widget');
$file_chooser->set_extra_widget ($extra_widget);
is ($file_chooser->get_extra_widget, $extra_widget);

# List of user selectable filters
#
my $filter = Gtk2::FileFilter->new;
$filter->set_name ('fred');
$filter->add_mime_type ('text/plain');

$file_chooser->add_filter ($filter);
@list = $file_chooser->list_filters;
is (scalar (@list), 1, 'list_filters after adding one filter');

$file_chooser->remove_filter ($filter);
@list = $file_chooser->list_filters;
is (scalar (@list), 0, 'list_filters after removing one filter');

# Current filter
#
$file_chooser->set_filter ($filter);
is ($filter, $file_chooser->get_filter);

# Per-application shortcut folders
#
eval {
  $file_chooser->add_shortcut_folder ($cwd);
  $file_chooser->add_shortcut_folder_uri ("file://$cwd/t");

  update; run_main sub {
    is_deeply ([$file_chooser->list_shortcut_folders], [$cwd, "$cwd/t"]);
    is_deeply ([$file_chooser->list_shortcut_folder_uris], ["file://$cwd", "file://$cwd/t"]);
  };

  $file_chooser->remove_shortcut_folder ($cwd);
  $file_chooser->remove_shortcut_folder_uri ("file://$cwd/t");
};

is ($@, '', 'no shortcut error');

# Options
#
$file_chooser->set_local_only (TRUE);
ok ($file_chooser->get_local_only, 'local files only');

$file_chooser->set_local_only (FALSE);
ok (!$file_chooser->get_local_only, 'not only local files');

# apparently it likes to complain about setting this back.
$file_chooser->set_select_multiple (FALSE);
ok (!$file_chooser->get_select_multiple, 'not select multiple');

$file_chooser->set_action ('open');
is ($file_chooser->get_action, 'open', 'change action to open');

$file_chooser->set_select_multiple (TRUE);
ok ($file_chooser->get_select_multiple, 'select multiple');

$file_chooser->set_select_multiple (FALSE);
ok (!$file_chooser->get_select_multiple, 'not select multiple');

SKIP: {
	skip('[sg]et_show_hidden are new in 2.6', 1)
		unless Gtk2->CHECK_VERSION (2, 6, 0);

	$file_chooser->set_show_hidden (TRUE);
	is ($file_chooser->get_show_hidden, TRUE);
}

SKIP: {
	skip('new 2.8 stuff', 1)
		unless Gtk2->CHECK_VERSION (2, 8, 0);

	$file_chooser->set_do_overwrite_confirmation (TRUE);
	is ($file_chooser->get_do_overwrite_confirmation, TRUE);
}

SKIP: {
	skip('new 2.18 stuff', 1)
		unless Gtk2->CHECK_VERSION (2, 18, 0);

	$file_chooser->set_create_folders (FALSE);
	is ($file_chooser->get_create_folders, FALSE, '[gs]et_create_folders');
}

__END__

Copyright (C) 2003-2005 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
