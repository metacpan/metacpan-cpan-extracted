package Kephra::Config::Default::ToolBars;
use strict;
use warnings;

our $VERSION = '0.01';

sub get {
	return {
		main_toolbar => [
			'item file-new',
			'item file-open',
			'item file-print#', 
			'item file-close-current#',
			'item file-save-all',
			'item file-save',
			undef,
			'item edit-changes-undo',
			'item edit-changes-redo',
			undef,
			'item edit-cut',
			'item edit-copy',
			'item edit-paste',
			'item edit-replace',
			'item edit-delete',
			undef,
			'checkitem view-editpanel-line-wrap',
			'checkitem view-window-stay-on-top',
			undef,
			'item tool-interpreter-run-document',
			'checkitem view-panel-output',
			'checkitem view-panel-notepad',
			undef,
			'item view-dialog-find#',
			'item view-dialog-config#',
			'item view-dialog-keymap#',
		],
		searchbar => [
			'item view-searchbar',
			'combobox find 180',
			'item find-prev',
			'item find-next',
			undef,
			'item goto-last-edit',
			undef,
			'item marker-goto-prev-all',
			'item marker-goto-next-all',
			undef,
			'item goto-line',
			'item view-dialog-find',
		],
		statusbar => [
			'textpanel cursor 66',
			'textpanel selection 60',
			'textpanel syntaxmode 50',
			'textpanel codepage 40',
			'textpanel tab 25',
			'textpanel EOL 32',
			'textpanel message -1',
		],
	}
}

1;
