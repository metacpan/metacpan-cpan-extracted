#!/usr/bin/perl -w

# TITLE: Bonobo Hello
# REQUUIRES: Gtk Gnome Bonobo

use Bonobo;
use Gnome::Print;
use strict;

my $NAME = 'Bonobo Hello';
my $VERSION = '0.1';

init Gnome $NAME,  $VERSION;
init Bonobo;

package Hello::BonoboView;

@Hello::BonoboView::ISA = qw(Gnome::BonoboView);

sub factory {
	my ($class, $embeddable, $view_frame) = @_;
	my ($self, $vbox);
	warn "started view ($embeddable -> $view_frame)\n";

	$vbox = new Gtk::VBox(0, 10);
	$self = new Gnome::BonoboView($vbox);
	$self->signal_connect('activate', sub {shift->activate_notify(shift)});
	$self->{vbox} = $vbox;
	$self->{label} = new Gtk::Label;
	$self->{button} = new Gtk::Button("Change text");
	$vbox->add($self->{label});
	$vbox->add($self->{button});
	# use a dialog here instead
	$self->{button}->signal_connect('clicked', sub {$embeddable->set_text("Mandi Mandi")});
	$vbox->show_all;
	$self->set_view_frame($view_frame);
	$self = bless ($self, ref($class)||$class);
	$self->update($embeddable);
	warn "created view $self\n";
	return $self;
	
}

sub update {
	my ($view, $embeddable) = @_;
	warn "update with $embeddable->{text}\n";
	$view->{label}->set($embeddable->{text}) if ($embeddable && exists $embeddable->{text});
}

package Hello::BonoboEmbeddable;

@Hello::BonoboEmbeddable::ISA = qw(Gnome::BonoboEmbeddable);

sub new {
	my $class = shift;
	warn "create $_[0] object\n";
	my $res = new Gnome::BonoboEmbeddable(sub {Hello::BonoboView->factory(@_)});
	# add interfaces
#	my $stream = new Gnome::BonoboPersistStream ();
#	$self->add_interface($stream);

	my $print = new Gnome::BonoboPrint (sub {$res->print(@_)});
	$res->add_interface($print);
	warn "added interfaces\n";

	$res->{text} = "Hello Perl World";
	return bless ($res, ref($class)||$class);
}

sub set_text {
	my ($self, $text) = @_;
	warn "set text to: $text\n";
	$self->{text} = $text;
	$self->foreach_view (\&Hello::BonoboView::update, $self);
}

sub print {
	my ($self, $context, $width, $height) = @_;
	my ($font, $text, $w, $h);

	$font = new Gnome::Font ("Helvetica", 10);
	$text = $self->{text};
	$context->setlinewidth(2);
	$context->setrgbcolor(0, 0, 0);
	$context->setfont($font);
	$w = $font->get_width_string($text);
	$h = $font->get_ascender+$font->get_descender;
	$context->moveto($width/2-$w/2, $height/2-$h/2);
	$context->show($text);
}

package main;

my $factory;
my $running_objects = 0;

$factory = new Gnome::BonoboGenericFactory (
	"OAFIID:Bonobo_Perl_Hello_EmbeddableFactory", \&create_instance);

sub create_instance {
		my $embeddable = new Hello::BonoboEmbeddable;
		$running_objects++;
		$embeddable->signal_connect('destroy', sub {
				Gtk->main_quit unless --$running_objects;
			});
		warn "returning embeddable: $embeddable\n";
		return $embeddable;
};

Bonobo->main;

