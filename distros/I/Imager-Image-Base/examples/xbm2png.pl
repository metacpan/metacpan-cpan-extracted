#!/usr/bin/perl -w
# -*- perl -*-

# Copyright (C) 2015 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use Getopt::Long;
use Imager::Image::Xbm;

my $force;
GetOptions('f|force' => \$force)
    or die "usage: $0 [-f] xbmfile pngfile\n";

my $in  = shift or die "xbm file?";
my $out = shift or die "out file?";
!-e $out or $force or die "$out must not exist (or use -f)\n";

Imager::Image::Xbm->new(file => $in)->write(file => $out, type => 'png');

__END__
