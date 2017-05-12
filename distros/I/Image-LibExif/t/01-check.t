#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 56;
BEGIN {
	eval { require File::MimeInfo;1 } and *mimetype = \&File::MimeInfo::mimetype or
	eval { require File::MMagic;1 }   and *mimetype = sub { File::MMagic->new->checktype_filename($_[0]) } or
	                                      *mimetype = sub { "image/unknown" }
}
use Image::LibExif;

for my $file (<t/images/*>) {
	my $mime = mimetype($file);
	my $info = image_exif $file;
	SKIP: {
		ok $info, "$mime - $file" or skip 1;
		cmp_ok 0+keys %$info, '>', 14, "have many fields $file";
	}
}
