#!/usr/bin/perl
use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 '-init';
use Cairo;

my $window = Gtk2::Window->new;
$window->set_title("Reflection example");
$window->signal_connect( delete_event => sub { exit } );
$window->set_border_width(10);

my $reflected= Gtk2::Ex::ReflectBin->new;

my $entry=Gtk2::Entry->new;
my $button1=Gtk2::Button->new;
$button1->add( Gtk2::Image->new_from_stock('gtk-go-back','button') );
$button1->signal_connect(clicked=>sub {warn "button 1 clicked\n";});
my $button2=Gtk2::Button->new;
$button2->add( Gtk2::Image->new_from_stock('gtk-apply','button') );
$button2->signal_connect(clicked=>sub {warn "button 2 clicked\n";});

my $hbox=Gtk2::HBox->new;
$hbox->pack_start($button1,FALSE,FALSE,2);
$hbox->add($entry);
$hbox->pack_start($button2,FALSE,FALSE,2);

$reflected->add($hbox);
$window->add($reflected);
$window->show_all;

Gtk2->main;



package Gtk2::Ex::ReflectBin;
use Gtk2;
use Glib::Object::Subclass
	Gtk2::EventBox::,
	signals =>
	{	size_allocate	=> \&do_size_allocate,
		size_request	=> \&do_size_request,
	};

sub INIT_INSTANCE {
	my $self=shift;
	$self->signal_connect( expose_event	=> \&expose_cb);
	$self->signal_connect( damage_event	=> \&damage_cb);
	$self->signal_connect( realize		=> \&realize_cb);
	return $self;
}

sub do_size_request {
	my ($self,$req)=@_;
	my $border= $self->get_border_width;
	return unless $self->child;
	my $child_req=$self->child->size_request;
	my $w= $child_req->width;
	my $h= $child_req->height;
	$req->width( $w +$border*2 );
	$req->height( $h*2 +$border*2 );
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
	if (my $child=$self->child) {
		my $req= $child->size_request;
		my $rect=Gtk2::Gdk::Rectangle->new(0,0,$w,$h/2);
		$self->child->size_allocate($rect);
	}
	if (my $offscreen= $self->{offscreen}) {
		$offscreen->move_resize(0,0,$w,$h/2);
		$offscreen->geometry_changed;
	}
}

sub damage_cb {
	my ($self,$event)=@_;
	# invalidate the whole window, it could be better to invalidate $event->area and the rectangle containing its reflection
	$self->window->invalidate_rect(undef,0);
	return 1;
}

sub realize_cb {
	my ($self)=@_;
	my $border= $self->get_border_width;
	my ($x,$y,$w,$h)=$self->allocation->values;
	my %attr=
	 (	window_type	=> 'offscreen',
		wclass		=> 'output',
		x		=> 0,
		y		=> 0,
		width		=> $w-$border*2,
		height		=> ($h-$border*2)/2,
		event_mask	=> [qw/pointer-motion-mask button-press-mask button-release-mask exposure_mask/],
	 );
	$self->{offscreen}= my $offscreen= Gtk2::Gdk::Window->new($self->get_root_window,\%attr);
	$offscreen->set_user_data($self->Glib::Object::get_pointer());
	$self->window->signal_connect( pick_embedded_child =>sub { return $offscreen; });
	$self->child->set_parent_window($offscreen) if $self->child;
	$offscreen->set_embedder($self->window);
	$offscreen->signal_connect( to_embedder  => sub {my ($offscreen,$x,$y)=@_; return $x,$y });
	$offscreen->signal_connect( from_embedder=> sub {my ($offscreen,$x,$y)=@_; return $x,$y });
	$self->style->set_background($offscreen,'normal');
	$offscreen->show;
}

sub expose_cb {
	my ($self,$event)=@_;
	my $offscreen= $self->{offscreen};
	if ($event->window == $self->window) {
		my $pixmap = $offscreen->get_pixmap;
		return 1 unless $pixmap && $self->child;
		my (undef,$height)= $pixmap->get_size;
		my $cr=Gtk2::Gdk::Cairo::Context->create($self->window);
		my $child_alloc= $self->child->allocation;
		$cr->rectangle($event->area);
		$cr->clip;
		$cr->save; # the above clip is used for both draw
		 # draw normal version on upper half (0..$height)
		 $cr->rectangle($child_alloc);
		 $cr->clip;
		 $cr->set_source_pixmap($pixmap,0,0);
		 $cr->paint;
		 $cr->restore;
		# draw reflection on lower half ($height..$height*2)
		my $mask= Cairo::LinearGradient->create(0,$height,0,$height*2);
		$mask->add_color_stop_rgba(0,    0, 0, 0, 1   );
		$mask->add_color_stop_rgba(0.25, 0, 0, 0, 0.5 );
		$mask->add_color_stop_rgba(0.5,  0, 0, 0, 0.25);
		$mask->add_color_stop_rgba(0.75, 0, 0, 0, 0.1 );
		$mask->add_color_stop_rgba(1.0,  0, 0, 0, 0   );
		my $matrix= Cairo::Matrix->init(1, 0, .3, 1, 0, 0);
		$matrix->translate(-10,$height*2);
		$matrix->scale(1,-1);
		$cr->transform($matrix);
		$mask->set_matrix($matrix);
		$cr->rectangle($child_alloc);
		$cr->clip;
		$cr->set_source_pixmap($pixmap,0,0);
		$cr->mask($mask);
	}
	elsif ($event->window == $offscreen) {
		$self->propagate_expose($self->child,$event) if $self->child;
	}
	1;
}

