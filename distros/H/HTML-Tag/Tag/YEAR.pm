package HTML::Tag::YEAR;

use strict;
use warnings;

use Class::AutoAccess;
use Tie::IxHash;
use base qw(Class::AutoAccess HTML::Tag::SELECT);

our $VERSION = '1.01';

BEGIN {
	our $class_def	= {
							element			=> 'YEAR',
							tag 				=> 'SELECT',
							from				=> (localtime())[5] + 1800,
							to					=> (localtime())[5] + 2000,
							selected		=> (localtime())[5] + 1900,
							maybenull		=> 0,
							permitted 	=> undef,
							value				=> '',
	}
}

sub inner {
	my $self 	= shift;
	my $ret		= '';
	$ret			.= qq|<option value=""></option>\n| if ($self->maybenull);
	my $year 	= (localtime())[5]+1900;
	my @permitted = $self->permitted ? sort @{$self->permitted} : ($self->from..$self->to);
	foreach (@permitted) {
		$_ = sprintf('%04d',$_);
		$ret		.= qq|<option value="$_"| . ($self->selected eq $_ ? ' selected' : '') .
								qq|>$_</option>\n|;
	}
	return $ret;
}




1;

# vim: set ts=2:
