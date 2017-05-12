#!/usr/bin/perl-thread -w

# TITLE: Thread sample
# REQUIRES: Gtk

use Gtk;
use Thread;

init Gtk;

$yeas_or_no = 1;
$die = 0;

$window = new Gtk::Window;
$window->signal_connect('destroy', sub {Gtk->main_quit()});
$window->set_border_width(10);

$label = new Gtk::Label("And now for something completely different ...");
$window->add($label);

$label->show;
$window->show;

new Thread \&argument_thread, $label, 1;
new Thread \&argument_thread, $label, 0;

Gtk::Gdk->threads_enter;
Gtk->main();
$die = 1;
Gtk::Gdk->threads_leave;

sub argument_thread {
	my ($label, $what) = @_;
	my ($say_something);

	while (!$die) {
		sleep(int(rand(3)+0.5));

		{
			# scope for lock
			lock $yeas_or_no;
			$say_something = $what != $yeas_or_no;

			$yeas_or_no = $what  if $say_something;
		}
		if ($say_something) {
			Gtk::Gdk->threads_enter();
			$label->set($what?"o yes, it is!":"O no, it isn't!");
			Gtk::Gdk->threads_leave();
		}
		
	}
}

