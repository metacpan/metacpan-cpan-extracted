#!/usr/bin/perl -2

# Copyright 2010 Kevin Ryde

# This file is part of Filter-gunzip.
#
# Filter-gunzip is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Filter-gunzip is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Filter-gunzip.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use FindBin;
use Compress::Zlib;


open my $fh, "$FindBin::Bin/foo.pl.gz" or die $!;
my $str = do { local $/; <$fh> };
print length($str),"\n";

my ($x, $ini);
($x, $ini) = inflateInit (-WindowBits => 32 + 15)
  or die "inflateInit error $ini" ;
print STDERR "ini: $ini\n";
print STDERR "$x\n";

my ($out, $err) = $x->inflate($str) ;
print STDERR "err: $err ",0+$err,"\n";
print STDERR "output: $out\n";
print STDERR "left: $str\n";

exit 0;
