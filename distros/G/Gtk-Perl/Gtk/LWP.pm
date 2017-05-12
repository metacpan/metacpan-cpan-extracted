package Gtk::LWP;
require Gtk::io;
require Gtk::LWP::http;
LWP::Protocol::implementor('http', 'Gtk::LWP::http');
1;
