#!bin/jspl
require('Gtk2', 'Gtk2');
install('Gtk2.Window', 'Gtk2::Window');
install('Gtk2.Button', 'Gtk2::Button');

Gtk2.init();

var window = new Gtk2.Window('toplevel');
var button = new Gtk2.Button('Quit');

button.signal_connect('clicked', function() { Gtk2.main_quit() });
window.add(button);
window.show_all();

Gtk2.main();
say('Thats all folks!');
