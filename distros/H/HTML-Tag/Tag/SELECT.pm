package HTML::Tag::SELECT;

use strict;
use warnings;

use Class::AutoAccess;
use base qw(Class::AutoAccess HTML::Tag);

our $VERSION = '1.01';

BEGIN {
	our $class_def	= {
							element			=> 'SELECT',
							tag 				=> 'SELECT',
							has_end_tag	=> 1,
							value				=> {},
							selected		=> '',
							maybenull		=> 0,
	}
}

sub inner {
	my $self 	= shift;
	my $ret		= '';
	$ret			.= qq|<option value=""></option>\n| if ($self->maybenull);
	if (ref($self->value) eq 'HASH') {
		while (my ($k,$v) = each %{$self->value}) {
			$ret		.= qq|<option value="$k"| . ($self->selected eq $k ? ' selected' : '') .
									qq|>$v</option>\n|;
		}
	}
	return $ret;
}


1;

# vim: set ts=2:
