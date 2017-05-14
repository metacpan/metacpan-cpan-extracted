# $Id: Component.pm,v 1.2 2001/08/10 20:12:26 joern Exp $

package JaM::GUI::Component;

@ISA = qw ( JaM::GUI::Base );

use strict;
use JaM::GUI::Base;

# constructor of components takes additional 'win' argument
sub new {
	my $type = shift;
	my %par = @_;
	my $self = bless $type->SUPER::new (@_), $type;
	$self->gtk_win ($par{gtk_win});
	return $self;
}

# get/set toplevel gtk widget for this component
sub widget		{ my $s = shift; $s->{widget}
		          = shift if @_; $s->{widget}	}

# get/set main GTK window object
sub gtk_win		{ my $s = shift; $s->{gtk_win}
		          = shift if @_; $s->{gtk_win}	}


1;
