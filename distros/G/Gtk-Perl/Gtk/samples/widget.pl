
use Gtk;

init Gtk;

#TITLE: Widget creation
#REQUIRES: Gtk
 
package Foo;
use Data::Dumper;

@ISA = qw(Gtk::Button);

register_subtype Gtk::Button 'Foo';

sub new {
	print "NEW: $_[0]\n";
	return Gtk::Object::new(@_);
	#return Gtk::Widget->new(@_);
}

sub GTK_OBJECT_INIT {
	print ("init: ");
	print Dumper([@_]);
	#kill ('STOP', $$);
}

sub GTK_OBJECT_SET_ARG {
	print "set_arg: ";
	print Dumper([@_]);
}

sub GTK_OBJECT_GET_ARG {
	print "get_arg: ";
	print Dumper([@_]);
	return "$_[1]-result";
}


sub GTK_CLASS_INIT {
	my($self) = @_;
	print "class_init: ";
	print Dumper([@_]);

	add_arg_type $self "blorp", "GtkString", 3;
	add_arg_type $self "Foo::bletch", "gint", 3;

	add_signals $self 
		bloop => ['first', 'void', 'gint'], 
		blaat => ['last', 'void'];

}

package Foo::Sub;
use Data::Dumper;

@ISA = qw(Foo);

register_subtype Foo 'Foo::Sub';

sub new {
	print "NEW: $_[0]\n";
	#return Gtk::Object::new(@_);
	return Gtk::Widget->new(@_);
}

sub GTK_OBJECT_INIT {
	print ("Foo::Sub init: ");
	print Dumper([@_]);
}

sub GTK_CLASS_INIT {
	my($self) = @_;
	print "Foo::Sub class_init: ";
	print Dumper([@_]);

	add_signals $self 
		subbloop => ['first', 'void', 'gint'], 

}

package main;

use Gtk;

$w = new Gtk::Window 'toplevel';
$w->signal_connect('delete_event', sub {Gtk->exit(0)});
$vbox = new Gtk::VBox(0, 0);
$w->add($vbox);

$b = new Foo Gtk::Button::label => "Foo button";
$b2 = new Foo::Sub label => 'Foo sub (quit)';

print "TYPE: ", ref($b), ", ", ref($b2), "\n";

$b->{bibble} = 12;

#$b->signal_connect("clicked", sub { destroy $w });
$b->signal_connect("clicked", sub {my $self=shift; print "TYPE: ", ref($self)," -> ", $self->type_name(), "\n"; $b2->signal_emit("subbloop", 666)});
$b2->signal_connect("clicked", sub { Gtk->exit(0)});
$b2->signal_connect('subbloop', sub {my $self=shift; print "TYPE: ", ref($self), " -> ", $self->type_name(), "\n"; $b->signal_emit('bloop', @_)});

# Demonstration of emit
#use Data::Dumper;
#$b->signal_connect("install_accelerator", sub { 
#	print Dumper(\@_);
#	return 3;
#});
#$b->signal_connect("clicked", sub { print "ia: ",$b->signal_emit("install_accelerator", "signal", 64, 129),"\n";});

$b->signal_connect("bloop", sub {print "Bloop! ", $_[1], "\n"});

#$b->set("Foo::blorp", 'fibble');
#$b->set("Foo::bletch", 'fabble');
#print "|",$b->get("Foo::blorp"),"|\n";

$vbox->add($b);
$vbox->add($b2);

show_all $w;

main Gtk;
