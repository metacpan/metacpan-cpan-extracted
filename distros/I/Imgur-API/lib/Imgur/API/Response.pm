package Imgur::API::Response;

use strict;

sub is_success { 1; }

sub new {
	my ($class,$json) = @_;

	my $this = $json->{data};
	if (ref($this) ne "HASH") {
		$this={data=>$json->{data}};
	}

	return bless $this,$class;
}

1;

	
