# $Id: MailAsHTML.pm,v 1.2 2001/08/10 20:12:26 joern Exp $

package JaM::GUI::MailAsHTML;

@ISA = qw ( JaM::GUI::HTMLSurface );

use strict;
use Carp;

sub widget 	    { confess "widget called" }
sub image_dir 	    { confess "image_dir called"    }

sub handle	    { confess "handle called" }
sub image_pool	    { return {} }
sub url_in_focus    { confess "url_in_focus called"  }

sub gtk_attachment_popup    { confess "gtk_attachment_popup called"  }

sub html	    { my $s = shift; $s->{html}
		      = shift if @_; $s->{html}		}

sub new {
	my $type = shift;
	my %par = @_;
	my ($quote) = @par{'quote'};
	
	my $self = bless {
		html => "",
	}, $type;

	return $self;
}

sub begin {
	my $self = shift;
	$self->write ('<html><body bgcolor="#d5d5d5">');
	1;
}

sub end {
	my $self = shift;
	$self->write ('</body></html>');
	1;
}

sub write {
	my $self = shift;
	$self->{html} .= join ("",@_);
	1;
}

sub image {
	shift->write ("[IMAGE]");
}

1;
