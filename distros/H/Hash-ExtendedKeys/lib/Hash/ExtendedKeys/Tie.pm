package Hash::ExtendedKeys::Tie;

use strict;
use warnings;
use Hash::Util qw(fieldhash);
use Struct::Match qw/match/;

sub TIEHASH {
	my ($class) = @_;

	fieldhash my %fieldhash;

	my $self = {
		fieldhash  => \%fieldhash,
	};

	bless $self, $class;
}

sub STORE {
	my ($self, $key, $value) = @_;

	my $k = $self->{fieldhash}->{$key} ? $key : $self->FINDKEY($key);;
	if ($k) {
		$self->{fieldhash}->{$k}->{value} = $value;
	} else {
		$self->{fieldhash}->{$key} = {
			key => $key,
			value => $value
		};
	}

 	return $self;
}

sub FETCH {
	my ($self, $key) = @_;
	my $k = $self->{fieldhash}->{$key} ? $key : $self->FINDKEY($key);
	return $k ? $self->{fieldhash}->{$k}->{value}  : undef;
}

sub FINDKEY { 
	# uncoverable pod
	for my $k (keys %{$_[0]->{fieldhash}}) {
		if (match($_[0]->{fieldhash}->{$k}->{key}, $_[1])) {
			return $_[0]->{fieldhash}->{$k}->{key};
		}
	}
	return undef;
}

sub FIRSTKEY {
	my ($key, $value) = each %{$_[0]->{fieldhash}};
	return $value->{key};
}

sub NEXTKEY { 
	my ($key, $value) = each %{$_[0]->{fieldhash}};
	return $value->{key};
}

sub EXISTS {
	my $k = $_[0]->{fieldhash}->{$_[1]} ? $_[1] : $_[0]->FINDKEY($_[1]);
	$k ? exists $_[0]->{fieldhash}->{$k} : undef; 
}

sub DELETE { 
	my $k = $_[0]->{fieldhash}->{$_[1]} ? $_[1] : $_[0]->FINDKEY($_[1]);
	$k ? delete $_[0]->{fieldhash}->{$k} : undef; 
}

sub CLEAR { 
	%{$_[0]->{fieldhash}} = () 
}

sub SCALAR { 
	scalar keys %{$_[0]->{fieldhash}} 
}

1;
