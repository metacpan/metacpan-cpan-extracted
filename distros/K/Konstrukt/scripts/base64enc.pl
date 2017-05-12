#!/usr/bin/perl

use strict;
use warnings;

use MIME::Base64 qw(encode_base64);

my $buf;
while (read(STDIN, $buf, 60*57)) {
	print encode_base64($buf);
}
