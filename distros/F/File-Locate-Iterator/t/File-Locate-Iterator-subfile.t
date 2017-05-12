#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

# This file is part of File-Locate-Iterator.
#
# File-Locate-Iterator is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# File-Locate-Iterator is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with File-Locate-Iterator.  If not, see <http://www.gnu.org/licenses/>.


# Exercise reading from a PerlIO::subfile, if that module available.
# Including a rewind in that subfile.

use 5.006;
use strict;
use warnings;
use Test::More;

# no need to preload layers, this only to check availability
eval { require PerlIO::subfile }
  or plan skip_all => "PerlIO::subfile not available -- $!";

# Creating samp.locatedb.subfile file ...
# {
#   open my $fh, '<', 't/samp.locatedb.offset' or die;
#   my $contents = do { local $/ = undef; <$fh> }; # slurp
#   close $fh or die;
#   undef $fh;
#   open $fh, '>', 't/samp.locatedb.subfile' or die;
#   print $fh $contents;
#   print $fh "\0" x 45;
#   close $fh or die;
#   exit 0;
# }

require FindBin;
require File::Spec;
my $samp_zeros = File::Spec->catfile ($FindBin::Bin, 'samp.zeros');
my $samp_locatedb_subfile
  = File::Spec->catfile ($FindBin::Bin, 'samp.locatedb.subfile');
diag "File samp_locatedb_subfile=$samp_locatedb_subfile";

# if PerlIO not available then this can fail, at least when mangling with
# Test::Without::Module
eval { open my $fh, '< :raw :subfile(start=87,end=3770)', $samp_locatedb_subfile }
  or plan skip_all => "skip, cannot open < :raw :subfile(start=87,end=3770) -- $!";

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

plan tests => 4;
require File::Locate::Iterator;


my @samp_zeros;
{
  open my $fh, '<', $samp_zeros
    or die "oops, cannot open $samp_zeros: $!";
  binmode($fh)
    or die "oops, cannot set binary mode on $samp_zeros";
  {
    local $/ = "\0";
    @samp_zeros = <$fh>;
    foreach (@samp_zeros) { chomp }
  }
  close $fh
    or die "Error reading $samp_zeros: $!";
}

#-----------------------------------------------------------------------------
# samp.locatedb.subfile

sub no_inf_loop {
  my ($name) = @_;
  my $count = 0;
  return sub {
    if ($count++ > 50) { die "Oops, eof not reached on $name"; }
  };
}

my $orig_RS = $/;

{
  open my $fh, '<', $samp_locatedb_subfile
    or die "Oops, cannot open again with :subfile: $!";
  binmode $fh 
    or die "Oops, binmode(): $!";
  binmode $fh, ':subfile(start=87,end=3770)'
    or die "Oops, cannot binmode(:subfile): $!";
  # binmode ($fh) or die "Oops, cannot set binmode on subfile: $!";;
  if (PerlIO->can('get_layers')) {
    diag "Layers: ", join(', ', map {defined $_ ? $_ : '[undef]'} PerlIO::get_layers($fh, details=>1));
  }

  my $it = File::Locate::Iterator->new (database_fh => $fh);
  my @want = @samp_zeros;
  {
    my @got;
    my $noinfloop = no_inf_loop($samp_locatedb_subfile);
    while (defined (my $filename = $it->next)) {
      push @got, $filename;
      $noinfloop->();
    }
    is_deeply (\@got, \@want, 'samp.locatedb.subfile full');
  }
  $it->rewind;
  {
    my @got;
    my $noinfloop = no_inf_loop($samp_locatedb_subfile);
    while (defined (my $filename = $it->next)) {
      push @got, $filename;
      $noinfloop->();
    }
    is_deeply (\@got, \@want, 'samp.locatedb.subfile full, after rewind');
  }
}

# with 'glob'
{
  open my $fh, '< :raw :subfile(start=87,end=3770)', $samp_locatedb_subfile
    or die "Oops, cannot open again with :subfile: $!";

  my $it = File::Locate::Iterator->new (database_fh => $fh,
                                        glob => '*.c');
  my $noinfloop = no_inf_loop("$samp_locatedb_subfile with *.c");
  my @want = grep {/\.c$/} @samp_zeros;
  my @got;
  while (defined (my $filename = $it->next)) {
    push @got, $filename;
    $noinfloop->();
  }
  is_deeply (\@got, \@want, 'samp.locatedb.subfile glob *.c');
}

is ($/, $orig_RS, 'input record separator unchanged');

exit 0;
