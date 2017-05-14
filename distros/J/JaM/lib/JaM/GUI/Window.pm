# $Id: Window.pm,v 1.2 2001/08/28 18:58:23 joern Exp $

package JaM::GUI::Window;

@ISA = qw ( JaM::GUI::Component );

use strict;
use Carp;
use JaM::GUI::Component;

my %SINGLE_INSTANCE_OBJECTS;

sub gtk_window_widget	   { my $s = shift; $s->{gtk_box}
		             = shift if @_; $s->{gtk_box}		 }
sub single_instance_window { 0 }
sub multi_instance_window  { 0 }

sub new {
	my $type = shift;

	my $single_instance = $type->single_instance_window;
	my $multi_instance  = $type->multi_instance_window;
	
	confess ("Window component '$type' did not classify itself as single\n".
		 "or multi instance window")
		if not $single_instance and not $multi_instance;

	my $self;
	if ( $single_instance ) {
		$self = $SINGLE_INSTANCE_OBJECTS{$type};
		return $self if $self;
		$self = $type->SUPER::new(@_);
		$SINGLE_INSTANCE_OBJECTS{$type} = $self;
	} else {
		$self = $type->SUPER::new(@_);
	}
	
	return $self;
}

sub instance_closed {
	my $self = shift;
	return 1 if $self->multi_instance_window;
	my $type = ref $self;
	$SINGLE_INSTANCE_OBJECTS{$type} = undef;
	1;
}

sub open_window {
	my $self = shift;

	return if $self->single_instance_window and
	          $self->gtk_window_widget;
	
	$self->build(@_);

	confess ("Window component didn't set gtk_window_widget")
		if not $self->gtk_window_widget;

	$self->gtk_window_widget->signal_connect (
		"destroy", sub { $self->instance_closed }
	);
	
	1;
}

1;
