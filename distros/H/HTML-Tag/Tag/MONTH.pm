package HTML::Tag::MONTH;

use strict;
use warnings;

use base qw(Class::AutoAccess HTML::Tag::SELECT);

use Tie::IxHash;
use Class::AutoAccess;

use HTML::Tag::Lang qw(@month);

our $VERSION = '1.00';

BEGIN {
	our $class_def	= {
							element			=> 'MONTH',
							tag 				=> 'SELECT',
							selected		=> '',
							value				=> '',
							maybenull		=> 0,
							permitted 	=> undef ,
	}
}

sub inner {
	my $self 	= shift;
	my $ret		= '';
	$ret			.= qq|<option value=""></option>\n| if ($self->maybenull);
	my @permitted;
	if ($self->permitted) {
		# to be sure that permitted are real numbers
		push @permitted,$_+0 for (@{$self->permitted});
	} else {
		@permitted = (1..12);
	}
	my @cmonth = localtime();
	my $cmonth = $cmonth[4]+1;
	my @mlist	 = ($cmonth..12);
	# intersect @permitted with mlist
	my @msect; tie my %munion,'Tie::IxHash'; tie my %msect,'Tie::IxHash';
	foreach my $e (@mlist, @permitted) { $munion{$e}++ && $msect{$e}++ }
	@msect = keys %msect;
	foreach (@msect) {
		$_ = sprintf('%02d',$_);
		$ret		.= qq|<option value="$_"| . ($self->selected eq $_ ? ' selected' : '') .
								qq|>$_ - $month[$_-1]</option>\n|;
	}	
	unless ($cmonth == 1) {
		@mlist	= (1..$cmonth-1);
		# intersect @permitted with mlist
		%munion = () ;%msect = ();
		foreach my $e (@mlist, @permitted) { $munion{$e}++ && $msect{$e}++ }
		@msect = keys %msect;
		foreach (@msect) {
			$_ = sprintf('%02d',$_);
			$ret		.= qq|<option value="$_"| . ($self->selected eq $_ ? ' selected' : '') .
									qq|>$_ - $month[$_-1]</option>\n|;
		}
	}
	return $ret;
}


1;

# vim: set ts=2:
