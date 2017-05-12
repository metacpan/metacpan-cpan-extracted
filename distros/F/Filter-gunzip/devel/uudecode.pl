#!/usr/bin/perl -w

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

use 5.006;
use strict;
use warnings;
use Compress::Raw::Zlib;

use FindBin;
my $topdir = File::Spec->catdir ($FindBin::Bin, File::Spec->updir);
my $libdir = File::Spec->catdir ($topdir, 'lib');
my $blibdir = File::Spec->catdir ($topdir, 'blib');
my $blibdir_lib = File::Spec->catdir ($blibdir, 'lib');
my $blibdir_arch = File::Spec->catdir ($blibdir, 'arch');

my $filename = '/tmp/uudecode-gunzip.pl';


# {
#   open my $out, '>', $filename or die;
#   print OUT "#!/usr/bin/perl\nuse Filter::gunzip;\n" or die;
# }
#
system "uuencode hello.pl.gz <$topdir/examples/hello.pl.gz >$filename";
chmod 0755, $filename or die;

my @command = ($^X,
               '-I', $libdir,
               '-I', $blibdir_lib,
               '-I', $blibdir_arch,
               '-MFilter::UUdecode',
               '-MFilter::gunzip',
               $filename);
{ local $,=' '; print 'run:',@command,"\n"; }
my $status = system @command;
if ($status < 0) {
  die "cannot run: $!";
}
exit 0;
