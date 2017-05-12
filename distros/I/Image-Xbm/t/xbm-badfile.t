#!/usr/bin/perl -w
# -*- cperl -*-

# Copyright (C) 2016 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use File::Temp qw(tempfile);
use Test::More 'no_plan';

use Image::Xbm;

for my $tempfile_template (
			   'image-xbm-0x00-XXXXXXXX', # filename contains valid hex value, causing extra wrong bits
			   'image-xbm-file with spaces-XXXXXXXX', # spaces are properly transliterated
			   'image-xbm-file^-with-^special-XXXXXXXX', # other special characters are properly transliterated
			  ) {
    my(undef, $fp) = tempfile($tempfile_template, SUFFIX => '.xbm', UNLINK => 1);
    my $i1 = Image::Xbm->new_from_string("#####\n#---#\n-###-\n--#--\n--#--\n#####");
    $i1->save($fp);

    my($width_name, $height_name, $bits_name);
    {
	open my $fh, '<', $fp
	    or die $!;
	while(<$fh>) {
	    if      (/^#define\s+(.*_width)\s+5$/) {
		$width_name = $1;
	    } elsif (/^#define\s+(.*_height)\s+6$/) {
		$height_name = $1;
	    } elsif (/^static\s+unsigned\s+char\s+(.*_bits)\[\]\s+=\s+\{$/) {
		$bits_name = $1;
	    }
	}
    }
    like $width_name, qr{^image_xbm_[A-Za-z0-9_]+_width}, 'width define without strange characters';
    like $height_name, qr{^image_xbm_[A-Za-z0-9_]+_height}, 'height define without strange characters';
    like $bits_name, qr{^image_xbm_[A-Za-z0-9_]+_bits}, 'bits variable without strange characters';

    my $i2 = Image::Xbm->new(-file => $fp);
    is $i2->as_binstring, $i1->as_binstring, "loaded image from file has same bits (tempfile template: $tempfile_template)";

    unlink $fp;
}

__END__
