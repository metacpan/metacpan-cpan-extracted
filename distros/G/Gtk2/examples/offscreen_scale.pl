#!/usr/bin/perl
use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 '-init';
use Cairo;

my $window = Gtk2::Window->new;
$window->set_title("Resize me");
$window->signal_connect( delete_event => sub { exit } );
$window->set_border_width(5);

my $scaled= Gtk2::Ex::ScaleBin->new;

my $entry=Gtk2::Entry->new;
my $button=Gtk2::Button->new_from_stock('gtk-ok');
$button->signal_connect(clicked=>sub {warn "clicked\n";});

my $vbox=Gtk2::VBox->new;
$vbox->add($entry);
$vbox->add($button);

$scaled->add($vbox);
$window->add($scaled);
$window->show_all;


Gtk2->main;



package Gtk2::Ex::ScaleBin;
use Gtk2;
use Glib::Object::Subclass
	Gtk2::EventBox::,
	signals =>
	{	size_allocate	=> \&do_size_allocate,
	};

sub INIT_INSTANCE {
	my $self=shift;
	$self->signal_connect( expose_event	=> \&expose_cb);
	$self->signal_connect( damage_event	=> \&damage_cb);
	$self->signal_connect( realize		=> \&realize_cb);
	return $self;
}

sub do_size_allocate {
	my ($self,$alloc)=@_;
	my $border= $self->get_border_width;
	my ($x,$y,$w,$h)=$alloc->values;
	my $olda=$self->allocation;
	 $olda->x($x); $olda->width($w);
	 $olda->y($y); $olda->height($h);
	$w-= 2*$border;
	$h-= 2*$border;
	$self->window->move_resize($x+$border,$y+$border,$w,$h) if $self->window;
	my ($reqw,$reqh)= ($w,$h);
	if (my $child=$self->child) {
		my $req= $child->size_request;
		$reqw= $req->width;
		$reqh= $req->height;
		my $rect=Gtk2::Gdk::Rectangle->new(0, 0, $reqw, $reqh);
		$self->child->size_allocate($rect);
	}
	$self->{zoom_x}= $w / $reqw;
	$self->{zoom_y}= $h / $reqh;
	if (my $offscreen= $self->{offscreen}) {
		$offscreen->{zoom_x}= $self->{zoom_x};
		$offscreen->{zoom_y}= $self->{zoom_y};
		$offscreen->move_resize(0,0, $reqw, $reqh);
		$offscreen->geometry_changed;
	}
}

sub damage_cb {
	my ($self,$event)=@_;
	my ($x,$y,$w,$h)=$event->area->values;
	my $zx= $self->{zoom_x};
	my $zy= $self->{zoom_y};
	my $rect=Gtk2::Gdk::Rectangle->new($x*$zx, $y*$zy, $w*$zx, $h*$zy);
	$self->window->invalidate_rect($rect,0);
	1;
}

sub realize_cb {
	my ($self)=@_;
	my ($x,$y,$w,$h)=$self->allocation->values;
	my %attr=
	 (	window_type	=> 'offscreen',
		wclass		=> 'output',
		x		=> 0,
		y		=> 0,
		width		=> $w,
		height		=> $h,
		event_mask	=> [qw/pointer-motion-mask button-press-mask button-release-mask exposure_mask/],
	 );
	$self->{offscreen}= my $offscreen= Gtk2::Gdk::Window->new($self->get_root_window,\%attr);
	$offscreen->set_user_data($self->Glib::Object::get_pointer());
	$self->window->signal_connect( pick_embedded_child =>sub { return $offscreen; });
	$self->child->set_parent_window($offscreen) if $self->child;
	$offscreen->set_embedder($self->window);
		$offscreen->{zoom_x}= $self->{zoom_x};
		$offscreen->{zoom_y}= $self->{zoom_y};
	$offscreen->signal_connect( to_embedder  => sub {my ($offscreen,$x,$y)=@_; return $x*$offscreen->{zoom_x},$y*$offscreen->{zoom_y} });
	$offscreen->signal_connect( from_embedder=> sub {my ($offscreen,$x,$y)=@_; return $x/$offscreen->{zoom_x},$y/$offscreen->{zoom_y} });
	$self->style->set_background($offscreen,'normal');
	$offscreen->show;
}

sub expose_cb {
	my ($self,$event)=@_;
	my $offscreen= $self->{offscreen};
	if ($event->window == $self->window) {
		my $pixmap = $offscreen->get_pixmap;
		return 1 unless $pixmap;
		my ($w,$h)= $pixmap->get_size;
		my $cr=Gtk2::Gdk::Cairo::Context->create($self->window);
		$cr->rectangle($event->area);
		$cr->clip;
		$cr->scale($self->{zoom_x},$self->{zoom_y});
		$cr->set_source_pixmap($pixmap,0,0);
		$cr->paint;
	}
	elsif ($event->window == $offscreen) {
		$self->propagate_expose($self->child,$event) if $self->child;
	}
	1;
}

