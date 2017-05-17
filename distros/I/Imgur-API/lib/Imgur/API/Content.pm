package Imgur::API::Content;

use strict;
use MIME::Base64;

sub encode {
	my ($class,$path) = @_;

	if (!-f $path) {
		return undef;
	}
	my $op='';
	my $buff='';
	open(FI,$path);
	while(read(FI,$buff,128*57)) {
		$op.=encode_base64($buff);
	}
	return $op;
}

1;
	
