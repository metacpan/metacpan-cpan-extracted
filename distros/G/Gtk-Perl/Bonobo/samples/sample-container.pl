#!/usr/bin/perl -w

#TITLE: Bonobo sample control container
#REQUIRES: Gtk Gnome Bonobo

# out listener class
package MyListener;
@ISA = qw(Bonobo::ListenerImpl);

sub event {
	my ($self, $event, $any) = @_;
	my $clist = $self->{clist};
	my ($name) = $event =~ m[Bonobo/Property:change:(.*)];
	#warn "$self GOT event: $event ($name)\n";
	$clist->set_text($clist->{$name}, 1, $any->value);
}

package main;

use Bonobo;

init Gnome('sample-container');

if (!Bonobo->init) {
	die "Can't initialize bonobo\n";
}

my $pb;

Gtk->idle_add(\&container_create);
Bonobo->main;
exit(0);

sub container_create {
	my ($app, $uic, $uico, $box, $control, $button, $clock_button, $container, $cf, $listener);
	$app = new Gnome::BonoboWindow("sample-control-container", "Sample Bonobo Control Container");
	$app->set_default_size(400, 600);
	$app->set_policy(1, 1, 0);
	$app->signal_connect('delete_event', sub {shift->destroy; return 0;});
	$app->signal_connect('destroy', sub {Gtk->main_quit;});

	$container = new Gnome::BonoboItemContainer;
	$uic = new Gnome::BonoboUIContainer();
	$uic->set_win($app);
	$uic->signal_connect('system_exception', sub {
		my ($c, $o) = @_;
		Gnome::DialogUtil->warning("Container encountered a fatal CORBA exception! Shutting down...");
		$o->destroy;
		$app->destroy;
		Gtk->main_quit;
	});
	$uico = $uic->corba_objref;
	$box = new Gtk::VBox(0, 0);
	$app->set_contents($box);
	
	$control = new_control Gnome::BonoboWidget("OAFIID:Bonobo_Sample_Calculator", $uico);
	$box->pack_start($control, 1, 1, 0) if $control;
	$button = new Gtk::Button("Increment result");
	$button->signal_connect('clicked', \&increment_cb, $control);

	$cf = $control->get_control_frame;
	$pb = $cf->get_control_property_bag;
	$proplist = create_proplist ($control);

	$control = new_control Gnome::BonoboWidget("OAFIID:Bonobo_Sample_Clock", $uico);
	$box->pack_start($control, 1, 1, 0) if $control;
	$clock_button = new Gtk::Button("Pause/Resume Clock");
	$clock_button->signal_connect('clicked', \&toggle_clock, $control);
	
	$box->pack_start($clock_button, 1, 1, 0);

	$control = new_control Gnome::BonoboWidget ("OAFIID:Bonobo_perlentry", $uico);
	$box->pack_start($control, 1, 1, 0) if $control;

	$box->pack_start($proplist, 1, 1, 0);
	$box->pack_start($button, 0, 0, 0);

	$app->show_all;

	return 0;
}

sub increment_cb {
	my ($button, $control) = @_;
	my $i;
	$i = $control->get_property('value');
	$i += 0.37;
	$control->set_property('value', $i);
}

sub toggle_clock {
	my ($button, $control) = @_;
	my ($state);
	$state = $control->get_property('running');
	$control->set_property('running', !$state);
}

sub edit_property {
	my ($w, $e, $c) = @_;
	return 0;
}

sub populate_property_list {
	my ($control, $clist) = @_;
	my $props = $pb->getPropertyNames;
	my $listener = new MyListener (clist => $clist);
	foreach (@$props) {
		my $prop = $pb->getPropertyByName($_);
		$prop->addListener($listener->queryInterface);
		my $row = $clist->append($_, $prop->getValue->value);
		$clist->{$_} = $row;
	}
}

sub create_proplist {
	my $control = shift;
	my $clist = new_with_titles Gtk::CList("Property Name", "Value");
	$clist->signal_connect("button-press-event", \&edit_property, $control);
	populate_property_list($control, $clist);
	return $clist;
}


