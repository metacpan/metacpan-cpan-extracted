#!/usr/bin/perl

use strict;
use warnings;

use MIME::Base64 qw(decode_base64);

while (<STDIN>) {
	print decode_base64($_);
}
