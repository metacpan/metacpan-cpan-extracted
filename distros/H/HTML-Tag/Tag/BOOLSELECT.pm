package HTML::Tag::BOOLSELECT;

use strict;
use warnings;

use Class::AutoAccess;
use base qw(Class::AutoAccess HTML::Tag::SELECT);

use HTML::Tag::Lang qw(%bool_descr);

our $VERSION = '1.00';

BEGIN {
	our $class_def	= {
							element			=> 'BOOLSELECT',
							tag 				=> 'SELECT',
							selected		=> '',
							maybenull		=> 0,
							nobeforeyes => 0,
	}
}
 

sub inner {
	my $self 	= shift;
	my $ret		= '';
	$ret			.= qq|<option value=""></option>\n| if ($self->maybenull);
	my @values = $self->nobeforeyes ? (0,1) : (1,0);
	foreach (@values) {
		$ret		.= qq|<option value="$_"| . ($self->selected eq $_ ? ' selected' : '') .
								qq|>$bool_descr{$_}</option>\n|;
	}	
	return $ret;
}


1;

# vim: set ts=2:
