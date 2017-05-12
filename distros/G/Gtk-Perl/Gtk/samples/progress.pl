# TITLE: progress bar updating
# REQUIRES: Gtk

use Gtk;

init Gtk;

$w = new Gtk::Window;
$pbar = new Gtk::ProgressBar;
$vb = new Gtk::VBox(0, 0);
$b = new Gtk::Button('Quit');
$w->add($vb);
$vb->add($pbar);
$vb->add($b);

$b->signal_connect('clicked', sub {Gtk->exit(0)});
$w->signal_connect('destroy', sub {Gtk->exit(0)});

$w->show_all();
$i = 0;
$pbar->update($i);
Gtk->idle_add(sub {
	$i += 0.01;
	$pbar->update($i);
	while (Gtk->events_pending) {
		Gtk->main_iteration;
	}
	sleep(1);
	return 1;
});
Gtk->main;

