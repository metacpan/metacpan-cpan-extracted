package HTML::Tag::RADIO;

use strict;
use warnings;

use Class::AutoAccess;
use base qw(Class::AutoAccess HTML::Tag);

our $VERSION = '1.00';

BEGIN {
	our $class_def	= {
							element			=> 'RADIO',
							tag 				=> 'INPUT',
							has_end_tag	=> 0,
							value				=> {},
							selected		=> '',
							type				=> 'radio',
							attributes  => ['type'],
	}
}

sub html {
  my $self  = shift;
	my $ret		= '';
	if (ref($self->value) eq 'HASH') {
		while (my ($k,$v) = each %{$self->value}) {
			$ret	.= "<" . lc($self->tag);
			foreach (@{$self->attributes}) {
				my @attr_value = $self->$_;
			  my $attr_value = $attr_value[0];
				 if ("$attr_value" ne '') {
					 $ret .= " " . $self->_build_attribute($_,$attr_value);
		    }
		  }
			$ret		.= qq| value="$k"| . ($self->selected eq $k ? ' checked' : '');
			$ret .= $self->has_end_tag ? '>' : ' />';
			$ret .=	"$v\n";
		}
	}
	return $ret;
}


1;

# vim: set ts=2:
