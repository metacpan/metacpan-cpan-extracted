package Kephra::Config::Default::GlobalSettings;
our $VERSION = '0.16';

use strict;
use warnings;

sub get {
	return {
		about => {
			purpose => 'build in global settings',
			version => $Kephra::VERSION || 'no',
		},
		app => {
			app_data_sub_dir => 'interface',
			cache => {
				file => 'commands.yaml',
				sub_dir => 'cache',
				use => 1,
			},
			commandlist => {
				file => 'interface/commands.conf',
				node => 'commandlist',
			},
			contextmenu => {
				defaultfile => 'interface/contextmenus.yml',
				id => {
					document_context => 'editpanel_contextmenu',
					document_list => '&document_change',
					document_selection => 'textselection_contextmenu',
					file_history => '&file_history',
					insert_templates => '&insert_templates',
					marker_margin => 'markermargin_contextmenu',
					status_eol => 'status_lineendchar_contextmenu',
					status_encoding => 'status_encoding_contextmenu',
					status_info => 'status_info_contexmenu',
					status_syntaxmode => 'status_syntaxstyle_contextmenu',
					status_tab => 'status_whitespace_contextmenu',
					toolbar_search => 'searchbar_contextmenu',
				},
			},
			error_output => 'panel',                         # (dialog|console|panel|none)
			iconset_path => 'interface/icon/set/jenne',      # rootpath for all icons
			localisation => {
				directory => 'localisation',
				file => 'english.conf',                                # file relative to the localisation directory, defines language of the texts in the program
			},
			menubar => {
				file => 'interface/mainmenu.yml',
				node => 'full_menubar',
				responsive => 1,                              # (0|1) 0 prevent menubar item shading
				visible => 1,
			},
			panel => {
				notepad => {
					content_file => 'global/data/notepad_content.txt',
					eval_with => 'eval',
					font_family => 'Courier New',
					font_size => 10,
					size => 180,
					splitter_pos => 300,
					visible => 0,
				},
				output => {
					append => 0,
					back_color => '000022',
					font_family => 'Arial',
					font_size => 10,
					fore_color => 'ffffff',
					interpreter_path => 'perl',
					size => 100,
					visible => 0,
				},
			},
			searchbar => {
				autofocus => 0,
				autohide => 0,
				contextmenu => 'toolbar_search',
				contextmenu_visible => 1,
				file => 'interface/appbars.conf',
				node => 'searchbar',
				position => 'below',        # (above|below|bottom)
				visible => 1,
			},
			statusbar => {
				contextmenu_visible => 1,
				file => 'interface/appbars.yml',
				interactive => 1,
				node => 'statusbar',
				msg_nr => 0,
				visible => 1,
			},
			tabbar => {
				close_button => 'current'     ,# (all|current|active|one|right|no) current = active
											   # one = right, on right border
				contextmenu => 'document_list',# -NI id of connected context menu
				contextmenu_visible => 1,      # (0|1) enable conextmenu over tabbar
				file_info => 'file_name',      # (file_name|firstname) which part of filename to show
				info_symbol => 1,              # (0|1) show *(unsaved) and #(write protected) symbols on end of tabs
				insert_new_tab => 'rightmost', # (left|right[most]) tab position of opened file
				mark_configs => 1,             # (0|1) set configfile names in square brackets
				max_tab_width => 25,           # max tab width in chars, longer filenames will be cut and ... added
				middle_click => 'file-close-current',# -NI command that is performed when middle click over tabbar
				movable_tabs => 1,             # (0|1) if 0 tabs can't moved by mouse or key 
				number_tabs => 0,              # (0|1) display a number before the file name in the tabs
				switch_back => 1,              # -NI (0|1) switch back if you klick on current tab
				tablist_button => 1,           # (0|1)
				visible => 1,                  # (0|1)
			},
			toolbar => {
				contextmenu => 0,
				file => 'interface/appbars.yml',
				node => 'main_toolbar',
				responsive => 1,
				size => 16,
				visible => 1,
			},
			window => {
				default => {
					position_x => 0,
					position_y => 0,
					size_x => 800,
					size_y => 600,
				},
				fullscreen => 0,
				icon => 'interface/icon/app/proton.xpm',
				max_number => 1,
				maximize_editpanel => 0,
				position_x => 10,
				position_y => 10,
				save_position => 1,
				size_x => 660,
				size_y => 531,
				stay_on_top => 0,
				title => '$filepath - $appname $version', 
										# $filepath - path of current file
										# $filename - just the name.exe
										# $docnr - nr of current file
										# $doccount - nr of all opened files
										# $appname - name of this programm
										# $version - version of this programm
				transparency => 0.2,	# how much transparent if active, 1 = 100% = invisible
				transparent => 0,		# (0|1) trancparency active ?
			},
			xp_style => 1,
		},
		dialog => {
			button_handing => 'right',
			config => {
				save_position => 1,
				position_y    => 100,
				position_x    => 100,
				tooltips      => 1,
			},
			search => {
				save_position => 1,
				position_y    => 100,
				position_x    => 100,
				tooltips      => 1,
				transparency  => 0.2,  # 0 - full visible .. 1 - invisible
				width         => 436,
			},
		},
		editpanel => {
			DND_mode => 'copy',
			auto => {
				brace => {
					glue_tangent => 0,
					indention => 1,# indet after opening braces 1 tab more
					join => 1,     # deletes closing bracket if there are 2 and 1 has no matching partner
					make => 1,     # generates closing bracket for ne blocks
				},
				focus => 0,        # set focus on editpanel while onmouseover
				indention => 1,    # indents new lines like previous
			},
			contextmenu => {
				ID_margin => 'marker_margin',
				ID_normal => 'document_context',
				ID_selection => 'document_selection',
				visible => 'custom',
				margin => 1,
			},
			control => {
				mouse => {
					'left-selection' => 'edit-copy',
					'left-middle' => 'edit-paste',
					'left-right' => 'edit-cut',
					'middle-selected' => 'edit-insert-selection-at-cursor',
					'middle-selection' => 'find-selection, find-next',
					'middle' => 'goto-last-edit',
				},
				use_advanced_mouse_functions => 1,
			},
			font => {
				family => 'Courier New',
				size   => 10,
				style  => 'normal',
				weight => 'normal',
			},
			history => {
				fast_undo_steps => '7',
			},
			indicator => {
				bracelight => {
					back_color => '99ff99',
					bad_color  => 'ff0000',
					good_color => '0000ff',
					mode       => 'adjacent',
					visible    => 1,
				},
				caret => {
					color  => '0000ff',
					period => 500,
					width  => 2
				},
				caret_line => {
					color   => 'f5f5a5',
					visible => 1,
				},
				end_of_line_marker => 0,
				indent_guide => {
					visible => 1,
					color   => 'bbbbbb',
				},
				right_margin => {
					color    => 'ccccff',
					position => 80,
					style    => 1,
				},
				selection => {
					back_color => '001177',
					fore_color => 'f3f3f3'
				},
				whitespace => {
					color   => 'cccc99',
					visible => 1,
				},
			},
			line_wrap => 0,
			margin => {
				fold => {
					back_color => 'fff5f5',
					fore_color => 'aa9977',
					flag_line => 1,
					keep_caret_visible => 1,
					style => 'boxes',          # (boxes|arrows) apearance of the fold marker
					visible => 1,
				},
				linenumber => {
					autosize   => 1,
					back_color => 'd8d8d4',
					fore_color => '777788',
					min_width  => 3,
					visible    => 1,
				},
				marker => {
					back_color => '0022ff',
					fore_color => '000055',
					visible    => 1
				},
				text => 2
			},
			scroll_width => '640',
			word_chars => '$%-@_abcdefghijklmnopqrstuvwxyzäöüßABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ0123456789',
		},
		file => {
			current => {
				directory => '',
			},
			defaultsettings => {
				new => {                  # defaults for new docs
					EOL      => 'OS',     # (OS|auto|cr|lf|cr+lf) end of line character, OS means current OS standart -NI auto means take setting of the last touched file
					codepage => 'ascii',  # (8bit|utf8) codepage, used for charset
					cursor_pos => 0,
					readonly => 'no',     # (0|1|2|on|off|protect) if =1 it set a write protection on readonly files
					syntaxmode => 'perl', # (auto|none|lang_id) which syntaxstyle on new files
					tab_size => '4',      # (0..n) how much (white)spaces equals one tab?
					tab_use  => '1',      # (0|1) use of tab chars
				},
				open => {                 # defaults for opened files
					EOL         => 'auto',# (auto|cr+lf|cr|lf) EOL of opened files, if not set to auto, 
				                          # the file automaticly will converted to set value
					codepage    => 'auto',# (ascii|utf8) codepage, used for charset
					cursor_pos  => 0,
					readonly    => 'protect', # (0|1|2|on|off|protect) if =1 it set a write protection on readonly files
					syntaxmode  => 'auto',    # (auto|none|lang_id) which syntaxstyle on new files
					tab_size    => '4',       # (0..n) how much (white)spaces equals one tab?
					tab_use     => 'auto',    # (auto|0|1) use of tab chars
				},
			},
			endings => {
				ada     => 'ada ads adb',
				as      => 'as',
				asm     => 's asm',
				ave     => 'ave',
				baan    => 'bc cln',
				batch   => 'bat cmd nt',
				conf    => 'conf',
				context => 'tuo sty',
				cpp     => 'c cc cpp cxx h',
				cs      => 'cs',
				css     => 'css',
				diff    => 'diff patch',
				err     => 'err errorlist',
				eiffel  => 'e',
				forth   => 'forth',
				fortran => 'f for f77 f90 f95 f2k',
				haskell => 'hs',
				html    => 'htm html ssi shtml xhtml tag stag',
				java    => 'jav java',
				js      => 'js',
				idl     => 'idl odl',
				latex   => 'aux toc idx',
				lisp    => 'el jl lsp lisp',
				lua     => 'lua',
				make    => 'makefile Makefile mak configure',
				matlab  => 'm octave',
				nsis    => 'nsi nsh',
				perl    => 'pl ple plx plex pm pod cgi',
				php     => 'php php3 php4 phtml',
				property => 'properties session ini inf reg url cfg cnf aut',
				ps      => 'ps',
				pascal  => 'pas dpr dpk dfm inc pp',
				python  => 'py pyw',
				ruby    => 'rb',
				scheme  => 'scm smd ss',
				sh      => 'bsh sh',
				sql     => 'sql',
				tcl     => 'tcl tk itk',
				tex     => 'tex sty',
				text    => 'txt nfo',
				vb      => 'vb bas frm cls ctl pag dsr dob',
				vbs     => 'vbs dsm',
				xml     => 'xml xsl svg xul xsd dtd xslt axl xrc rdf',
				yaml    => 'yaml yml',
			},
			group => {
				config => 'conf',
				perl   => 'perl',
				text   => 'text',
				web    => 'css html php perl js',
			},
			open => {
				dir_recursive       => 1, # opens dirs recursive
				each_once           => 1, # opens each file only once
				in_current_dir      => 1, # opens dialog with the directory of current file
				into_empty_doc      => 0, # replacing new empty documents while opening a file
				into_only_empty_doc => 1, # replacing new empty doc if the empty is the only one
				notify_change       => 30,# (0..n) timer executed check if file has changed in sec
				only_text           => 0, # to open only text files
				single_doc          => 0, # opens only 1 document at once, enables an single document editor
			},
			save => {
				auto_save     => 30,    # -NI(0|n) timer executed save after n sec
				b4_quit       => 'ask', # (yes|no|ask) filesaving before closing a file
				b4_close      => 'ask', # (yes|no|ask) filesaving before closing the progr
				change_doc    => 0,     # saves everytime you change document
				empty         => 0,     # -NI saves (restore) automaticly also empty files
				on_leave      => 0,     # -NI save on leaving focus of current document
				overwrite     => 'ask', # (yes|no|ask) before overwriting files
				reload_config => 1,     # reload config automatic after saving it
				tilde_backup  => 0,     # creates UNIX  backup files with filename+~
				unchanged     => 0,     # saves (touches) automaticly also unchanged files
			},
			session => {
				auto => {
					file => 'current.yaml',
					node => '',
					save => 1,
				},
				backup    => 'backup.yaml',
				directory => 'session', # subdir of config where to look for session files
				history   => {
					file => 'history.yml',
					length => 13,
					node => '',
					save => 1,
				},
			},
			templates => {
				directory => 'template',
				file      => 'perl.conf',
			},
		},
		search => {
			attribute => {
				auto_wrap        => 1,
				fast_steps       => 7,
				in               => 'document',
				incremental      => 1,
				match_case       => 0,
				match_regex      => 0,
				match_whole_word => 0,
				match_word_begin => 0,
			},
			data_file => 'global/data/search.yml',
			history => {
				length => 12,
				remember_only_matched => 1,
				save => 1,
				use => 1,
			},
			marker => {
				any => 1,
				wrap => 1,
			},
		},
		texts => {
			special    => 'english/special_feature.txt',
			credits    => 'english/license/credits.txt',
			feature    => 'english/all_feature.txt',
			keymap     => 'english/keymap.txt',
			license    => 'english/license/gpl.txt',
			navigation => 'english/navigation.txt',
			version    => 'english/this_version.txt',
			welcome    => 'english/welcome.txt',
		}
	}
}

1;
