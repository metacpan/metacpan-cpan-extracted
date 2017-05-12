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

# my $filename = File::Spec->catfile ($FindBin::Bin, 'zlib.pl.zcat');
#
my $filename = '/tmp/zlib.pl.zcat';

my $class = 'Filter::gunzip';
#my $class = 'Filter::gunzip::Filter';

my $defl = Compress::Raw::Zlib::Deflate->new
  (
   # '-WindowBits' => (MAX_WBITS() + WANT_GZIP()),  # gzip RFC1952
   # '-WindowBits' => (MAX_WBITS()),  # zlib RFC1950
   '-WindowBits' => (- MAX_WBITS()),  # raw deflate RFC1951
  )
  or die;


open OUT, '>', $filename or die;
#print OUT "#!/usr/bin/perl\nuse $class;\n" or die;

my $output;
$defl->deflate(<<'HERE', $output) == Z_OK or die;
print "this is zlib format\n";
HERE
print OUT $output or die;

$defl->flush($output) == Z_OK or die "flush failed\n";
print OUT $output or die;
close OUT or die;
chmod 0755, $filename or die;

{
  open my $fh, '<:gzip(auto)', $filename
    or die "cannot open: $!";
  print <$fh>;
}

my @command = ($^X,
               '-I', $libdir,
               '-I', $blibdir_lib,
               '-I', $blibdir_arch,
               "-M$class",
               $filename);
{ local $,=' '; print 'run:',@command,"\n"; }
my $status = system @command;
if ($status < 0) {
  die "cannot run: $!";
}
exit 0;
