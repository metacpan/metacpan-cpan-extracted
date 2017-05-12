#!/usr/bin/perl
use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 '-init';
use Cairo;

my $window = Gtk2::Window->new;
$window->set_title("Rotation example");
$window->signal_connect( delete_event => sub { exit } );
$window->set_border_width(5);

my $rotated= Gtk2::Ex::RotatedBin->new;

my $entry=Gtk2::Entry->new;
my $button=Gtk2::Button->new_from_stock('gtk-ok');
$button->signal_connect(clicked=>sub {warn "clicked\n";});

my $checkh=Gtk2::CheckButton->new('mirror horizontally');
$checkh->signal_connect(toggled=>sub { $rotated->set_mirror( horizontal=> $_[0]->get_active ) });
my $checkv=Gtk2::CheckButton->new('mirror vertically');
$checkv->signal_connect(toggled=>sub { $rotated->set_mirror( vertical=> $_[0]->get_active ) });

my $adj=Gtk2::Adjustment->new(10, 0, 360, 1,10,0);
$adj->signal_connect(value_changed=> sub { $rotated->set_angle( $_[0]->value ); });
my $scale=Gtk2::HScale->new($adj);

my $vbox=Gtk2::VBox->new;
$vbox->add($_) for $entry,$button,$checkh,$checkv,$scale;

$rotated->add($vbox);
$window->add($rotated);
$window->show_all;

#Gtk2::Gdk::Window->set_debug_updates(1);
Gtk2->main;


#FIXME the child needs to be added before the RotatedBin is realized
# I haven't managed to make it work if the child is added or replaced after
package Gtk2::Ex::RotatedBin;
use Gtk2;
use List::Util qw/min max/;
use Glib::Object::Subclass
	Gtk2::EventBox::,
	signals =>
	{	size_allocate	=> \&do_size_allocate,
		size_request	=> \&do_size_request,
	};
use constant PI => 4 * atan2(1,1); # needed for the rotation

sub INIT_INSTANCE {
	my $self=shift;
	$self->{angle}=10;
	$self->signal_connect( expose_event	=> \&expose_cb);
	$self->signal_connect( damage_event	=> \&damage_cb);
	$self->signal_connect( realize		=> \&realize_cb);
	return $self;
}

sub do_size_request {
	my ($self,$req)=@_;
	my $border= $self->get_border_width;
	my $child_req=$self->child->size_request;
	my $w= $child_req->width;
	my $h= $child_req->height;
	my $diag= sqrt( $w**2 + $h**2 );
	$diag= 1+int $diag  unless int($diag)==$diag; #round up
	# request enough to satisfy the child request for any angle
	$req->width( $diag+$border*2 );
	$req->height( $diag+$border*2 );
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
	$self->update_matrix;
}

sub set_angle {
	my ($self,$angle)=@_;
	$self->{angle}=$angle;
	$self->update_matrix;
	$self->queue_resize;
}

sub set_mirror {
	my ($self,$h_or_v,$on)=@_;
	my $key= $h_or_v eq 'vertical' ? 'vmirror' : 'hmirror';
	$self->{$key}=$on;
	$self->update_matrix;
	$self->queue_draw;
}

# transform the rectangle and find a rectangle containing the transformed rectangle
sub transform_expose_rectangle {
	my ($self,$rect,$inv)=@_;
	my ($x,$y,$w,$h)=$rect->values;
	my $matrix= $inv ? $self->{imatrix} : $self->{matrix};
	my ($xa,$ya)=$matrix->transform_point($x,   $y);
	my ($xb,$yb)=$matrix->transform_point($x+$w,$y);
	my ($xc,$yc)=$matrix->transform_point($x,   $y+$h);
	my ($xd,$yd)=$matrix->transform_point($x+$w,$y+$h);
	$x= min($xa,$xb,$xc,$xd);
	$y= min($ya,$yb,$yc,$yd);
	$w= max($xa,$xb,$xc,$xd) -$x;
	$h= max($ya,$yb,$yc,$yd) -$y;
	return Gtk2::Gdk::Rectangle->new($x,$y,$w,$h);
}

sub update_matrix {
	my $self=shift;
	my ($x,$y,$w,$h)= $self->allocation->values;
	my $border= $self->get_border_width;
	$x+=$border; $w-=2*$border;
	$y+=$border; $h-=2*$border;
	my $angle= $self->{angle}*PI/180;
	my $matrix0=Cairo::Matrix->init_rotate($angle);
	my ($xa,$ya)=$matrix0->transform_distance(0,0);
	my ($xb,$yb)=$matrix0->transform_distance($w,0);
	my ($xc,$yc)=$matrix0->transform_distance(0,$h);
	my ($xd,$yd)=$matrix0->transform_distance($w,$h);
	my $rw= $w / ( max($xa,$xb,$xc,$xd) - min($xa,$xb,$xc,$xd) );
	my $rh= $h / ( max($ya,$yb,$yc,$yd) - min($ya,$yb,$yc,$yd) );
	my $r= min($rw,$rh);
	my $cw= $w*$r;
	my $ch= $h*$r;

	my $matrix=Cairo::Matrix->init_identity;
	$matrix->translate($w/2,$h/2);
	$matrix->rotate($angle);
	$matrix->translate( -$cw/2,-$ch/2 );
	if ($self->{hmirror}) {
		$matrix->scale(-1,1);
		$matrix->translate( -$cw,0 );
	}
	if ($self->{vmirror}) {
		$matrix->scale(1,-1);
		$matrix->translate( 0,-$ch );
	}
	$self->{matrix}=$matrix;

	my $imatrix= $matrix->multiply( Cairo::Matrix->init_identity ); #copy matrix
	$imatrix->invert;
	$self->{imatrix}= $imatrix;

	if (my $o=$self->{offscreen})
	{	$o->{matrix}= $self->{matrix};
		$o->{imatrix}=$self->{imatrix};
		$o->move_resize(0,0,$cw,$ch);
		$o->geometry_changed;
	}
	if (my $child=$self->child)
	{	my $rect=Gtk2::Gdk::Rectangle->new(0,0, $cw,$ch);
		$self->child->size_allocate($rect);
	}
}

sub damage_cb {
	my ($self,$event)=@_;
	my $rect= transform_expose_rectangle($self,$event->area);
	$self->window->invalidate_rect( $rect, 0);
	1;
}

sub realize_cb {
	my ($self)=@_;
	my ($x,$y,$w,$h)=$self->allocation->values;
	my %attr=
	 (	window_type	=> 'offscreen',
		wclass		=> 'output',
		event_mask	=> [qw/pointer-motion-mask button-press-mask button-release-mask exposure_mask/],
	 );
	$self->{offscreen}= my $offscreen= Gtk2::Gdk::Window->new($self->get_root_window,\%attr);
	$self->update_matrix;	# will resize $offscreen to the correct size
	$offscreen->set_user_data($self->Glib::Object::get_pointer());
	$self->window->signal_connect( pick_embedded_child =>sub { return $offscreen; }); #could check if transformed position is inside offscreen window
	$self->child->set_parent_window($offscreen) if $self->child;
	$offscreen->set_embedder($self->window);
	$offscreen->signal_connect( to_embedder  => sub { return $_[0]{ matrix}->transform_point($_[1],$_[2]); });
	$offscreen->signal_connect( from_embedder=> sub { return $_[0]{imatrix}->transform_point($_[1],$_[2]); });
	$self->style->set_background($offscreen,'normal');
	$offscreen->show;
}

sub expose_cb {
	my ($self,$event)=@_;
	my $offscreen= $self->{offscreen};
	if ($event->window == $self->window) {
		my $pixmap = $offscreen->get_pixmap;
		return 1 unless $pixmap;
		my $cr=Gtk2::Gdk::Cairo::Context->create($self->window);
		$cr->rectangle($event->area);
		$cr->clip;
		$cr->set_matrix( $self->{matrix} );
		$cr->set_source_pixmap($pixmap,0,0);
		$cr->paint;
	}
	elsif ($event->window == $offscreen) {
		$self->propagate_expose($self->child,$event) if $self->child;
	}
	1;
}


