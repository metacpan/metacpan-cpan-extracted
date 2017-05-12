#!bin/jspl

/*
 Application main window

 Demonstrates a typical application window, with menubar, toolbar, statusbar.

 Transliterated from perl-Gtk to JavaScript.
*/

require('Gtk2', 'Gtk2');

[
    'Glib', 'Gtk2::Window', 'Gtk2::Button',
    'Gtk2::ItemFactory', 'Gtk2::Table', 'Gtk2::UIManager',
    'Gtk2::AccelGroup', 'Gtk2::MessageDialog', 'Gtk2::IconFactory',
    'Gtk2::ActionGroup', 'Gtk2::Toolbar', 'Gtk2::ScrolledWindow',
    'Gtk2::TextView', 'Gtk2::Statusbar', 'Gtk2::Gdk', 'Gtk2::Gdk::Pixbuf',
    'Gtk2::IconSet', 'Gtk2::Stock'
].forEach(
    function(i) {
	install(i.replace(/::/g,'.'), i)
    }
);

Gtk2.init();

function show_dialog(get_msg) {
    return function() {
	var opts = get_msg.apply(this, arguments);
	var dialog = new Gtk2.MessageDialog(
	    opts.win, 'destroy-with-parent', 'info', 'close',
	    opts.msg
	);
	dialog.signal_connect('response',
	    function(d) { d.destroy(); return 1;}
	);
	dialog.show();
    }
}

var radiomenu_cb = show_dialog(function (action, current, win) {
    return {
	msg: "radio activated",
	win: win
    };
});

var menuitem_cb = show_dialog(function(action, win) {
    return {
	msg: sprintf('You selected or toggled the menu item: "%s"',
	        action.get_name()),
	win: win
    };
});

var exit_cb = function () {
    Gtk2.main_quit(); 
};

var toolbar_cb = show_dialog(function(button, win) {
    return {
	msg: "you selected a toolbar button",
	win: win
    };
});


/*
 This function registers our custom toolbar icons, so they can be themed.

 It's totally optional to do this, you could just manually insert icons
 and have them not be themeable, especially if you never expect people
 to theme your app.
*/

function register_stock_icons() {
    // stock_id   label   modifier   keyval   translation_domain
    Gtk2.Stock.add(
	{ stock_id : "demo-gtk-logo", label : "_GTK!", modifier: 'mod1-mask', keyval: 0, translation_domain: ''}
    );

    var factory = new Gtk2.IconFactory();
    factory.add_default();

    try {
	 var pixbuf = Gtk2.Gdk.Pixbuf.new_from_file(
	    '/usr/share/gtk-2.0/demo/gtk-logo-rgb.gif'
	);
	 factory.add("demo-gtk-logo",
	    Gtk2.IconSet.new_from_pixbuf(
		pixbuf.add_alpha(true, 0xff, 0xff, 0xff)));
    }
    catch (e) {
	say(e);
	warn("failed to load GTK logo");
    }
}

function update_statusbar(buffer, statusbar) {
    statusbar.pop(0);
    var count = buffer.get_char_count();
    var iter = buffer.get_iter_at_mark(buffer.get_insert());
    var row = iter.get_line();
    var col = iter.get_line_offset();

    statusbar.push(0,
	sprintf(
	    "Cursor at row %d column %2d - %d chars in document",
	    row, col, count
	)
    );
}

function mark_set_callback(buffer, new_location, mark, data) {
    update_statusbar(buffer, data);
}

register_stock_icons ();

var window = new Gtk2.Window('toplevel');
window.set_title ("Application Window");
window.signal_connect('destroy', exit_cb);

var table = new Gtk2.Table(1, 4, Glib.FALSE);
window.add(table);

var entries = [
  // name,              stock id,  label
  [ "FileMenu",        undefined,     "_File"        ],
  [ "PreferencesMenu", undefined,     "_Preferences" ],
  [ "ColorMenu",       undefined,     "_Color"       ],
  [ "ShapeMenu",       undefined,     "_Shape"       ],
  [ "HelpMenu",        undefined,     "_Help"        ],
  // name,      stock id,  label,    accelerator,  tooltip  
  [ "New",    'gtk-new',  "_New",   "<control>N", "Create a new file", menuitem_cb ],      
  [ "Open",   'gtk-open', "_Open",  "<control>O", "Open a file",       menuitem_cb ], 
  [ "Save",   'gtk-save', "_Save",  "<control>S", "Save current file", menuitem_cb ],
  [ "SaveAs", 'gtk-save', "Save _As...", undefined,   "Save to a file", menuitem_cb ],
  [ "Quit",   'gtk-quit', "_Quit",  "<control>Q", "Quit",              exit_cb ],
  [ "About",  undefined,      "_About", "<control>A", "About",             menuitem_cb ],
  [ "Logo",   "demo-gtk-logo", undefined, undefined,      "GTK+",              menuitem_cb ],
];

var toggle_entries = [
  ["Bold", 'gtk-bold', "_Bold", "<control>B", "Bold", menuitem_cb, true ]
];

var COLOR_RED   = 0;
var COLOR_GREEN = 1;
var COLOR_BLUE  = 2;

var color_entries = [
  [ "Red",   undefined,    "_Red",   "<control>R", "Blood", COLOR_RED   ],
  [ "Green", undefined,    "_Green", "<control>G", "Grass", COLOR_GREEN ],
  [ "Blue",  undefined,    "_Blue",  "<control>B", "Sky",   COLOR_BLUE  ],
];

var SHAPE_SQUARE    = 0;
var SHAPE_RECTANGLE = 1;
var SHAPE_OVAL      = 2;

var shape_entries = [
  [ "Square",    undefined,    "_Square",    "<control>S", "Square",    SHAPE_SQUARE ],
  [ "Rectangle", undefined,    "_Rectangle", "<control>R", "Rectangle", SHAPE_RECTANGLE ],
  [ "Oval",      undefined,    "_Oval",      "<control>O", "Egg",       SHAPE_OVAL ],
];

var actions = new Gtk2.ActionGroup('Actions');
actions.add_actions(entries, window);
actions.add_toggle_actions(toggle_entries, window);
actions.add_radio_actions(color_entries, COLOR_RED, radiomenu_cb, window);
actions.add_radio_actions(shape_entries, SHAPE_SQUARE, radiomenu_cb, window);

uimanager = new Gtk2.UIManager();
uimanager.insert_action_group(actions, 0);
window.add_accel_group(uimanager.get_accel_group());

uimanager.add_ui_from_string(
<ui>
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
</ui>
);

table.attach(
    uimanager.get_widget('/MenuBar'),
    0, 1, 0, 1, ['expand', 'fill'], [], 0, 0
);

table.attach(
    uimanager.get_widget('/ToolBar'),
    0, 1, 1, 2, ['expand', 'fill'], [], 0, 0
);

var sw = new Gtk2.ScrolledWindow();
sw.set_policy('automatic', 'automatic');
sw.set_shadow_type('in');
table.attach(sw, 0, 1, 2, 3, ['expand', 'fill'], ['expand', 'fill'], 0, 0);
window.set_default_size(640, 480);
var contents = new Gtk2.TextView();
sw.add(contents);

var statusbar = new Gtk2.Statusbar();
table.attach(statusbar, 0, 1, 3, 4, ['expand', 'fill'], [], 0, 0);

var buffer = contents.get_buffer();
buffer.signal_connect('changed', update_statusbar, statusbar);
buffer.signal_connect('mark_set', mark_set_callback, statusbar);

update_statusbar(buffer, statusbar);

window.show_all();

Gtk2.main();
