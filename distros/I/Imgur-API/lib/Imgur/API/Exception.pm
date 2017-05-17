package Imgur::API::Exception;

use strict;

sub new {
	my ($class,%options) = @_;

	my ($code,$message);
	my $this={};
	if (ref($options{message})) {
		$this->{message} = $options{message}->{message};
		$this->{code} = $options{message}->{code};
	} else {
		$this->{message} = $options{message};
		$this->{code} = $options{code};
	}
	return bless $this,$class;
}

sub is_success { 0; }

1;
__DATA__
