
#TITLE: Input
#REQUIRES: Gtk

  use Gtk;
  Gtk->init;
  my $mw = new Gtk::Window('toplevel');
  Gtk::Gdk->input_add(fileno(STDOUT), 'write', sub { } );
  $mw->show;
  Gtk->main;
