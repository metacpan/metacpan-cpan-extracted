package Hash::RestrictedKeys::Tie;

use strict;
use warnings;
use Carp qw/croak/;

sub TIEHASH {
	my ($class, @keys) = @_;
	bless {
		hash => {},
		allowed_keys => \@keys
	}, $class;
}

sub STORE {
	$_[0]->{hash}->{$_[0]->VALIDKEY($_[1])} = $_[2];
}

sub FETCH {
	$_[0]->{hash}->{$_[0]->VALIDKEY($_[1])};
}

sub VALIDKEY {
	croak sprintf('Invalid key %s. Allowed keys: %s', $_[1], join( ', ', @{$_[0]->{allowed_keys}})) 
		unless grep { $_ eq $_[1] } @{$_[0]->{allowed_keys}};
	return $_[1];
}

sub FIRSTKEY {
	each %{ $_[0]->{hash} };
}

sub NEXTKEY {
	each %{ $_[0]->{hash} };
}

sub EXISTS {
	exists $_[0]->{hash}->{$_[0]->VALIDKEY($_[1])};
}

sub DELETE {
	delete $_[0]->{hash}->{$_[0]->VALIDKEY($_[1])};
}

sub CLEAR {
	%{$_[0]->{hash}} = ();
}

sub SCALAR {
	scalar %{$_[0]->{hash}};
}

1;
