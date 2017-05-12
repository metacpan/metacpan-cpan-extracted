
use Gtk;

#TITLE: Inheritance
#REQUIRES: Gtk

package mywindow;

@ISA = qw(Gtk::Window);

sub new {
	my($class) = @_;
	my($self) = new Gtk::Window('toplevel');
	$self->set_title("a mywindow");
	$self->{"george"} = "bill";
	bless $self, $class;
}

package main;

init Gtk;

$window = new mywindow;

$button = new Gtk::Button "hello";
signal_connect $button "clicked", sub { print "Hello\n" };
$window->add($button);
$button->can_default(1);
$button->grab_default();
$button->show();
show $window;

main Gtk;
