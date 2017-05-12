#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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


# Exercise reading from a PerlIO::via::Base64, if that module available.


use 5.006;
use strict;
use warnings;
use Test::More;

# PerlIO::via::Base64 0.07 doesn't support seek(), not even just back to the
# start of the file, so no $it->rewind test

eval { require PerlIO::via::Base64 }
  or plan skip_all => "PerlIO::via::Base64 not available -- $!";

require FindBin;
require File::Spec;
my $samp_zeros = File::Spec->catfile ($FindBin::Bin, 'samp.zeros');
my $samp_locatedb_base64
  = File::Spec->catfile ($FindBin::Bin, 'samp.locatedb.base64');
diag "File samp_locatedb_base64=$samp_locatedb_base64";

# if PerlIO not available then this can fail, or at least when mangling it
# with Test::Without::Module
eval { open my $fh, '<:via(Base64)', $samp_locatedb_base64 }
  or plan skip_all => "Oops, cannot open <:via(Base64) -- $!";

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
# samp.locatedb.base64

sub no_inf_loop {
  my ($name) = @_;
  my $count = 0;
  return sub {
    if ($count++ > 20) { die "Oops, eof not reached on $name"; }
  };
}

my $orig_RS = $/;

{
  open my $fh, '<:via(Base64)', $samp_locatedb_base64
    or die "Oops, cannot open again with Base64: $!";
  my $it = File::Locate::Iterator->new (database_fh => $fh);
  my @want = @samp_zeros;
  {
    my @got;
    my $noinfloop = no_inf_loop($samp_locatedb_base64);
    while (defined (my $filename = $it->next)) {
      push @got, $filename;
      $noinfloop->();
    }
    is_deeply (\@got, \@want, 'samp.locatedb.base64 full');
  }
}

# with 'glob'
{
  open my $fh, '<:via(Base64)', $samp_locatedb_base64
    or die "Oops, cannot open again with Base64: $!";
  my $it = File::Locate::Iterator->new (database_fh => $fh,
                                        glob => '*.c');
  my $noinfloop = no_inf_loop("$samp_locatedb_base64 with *.c");
  my @want = grep {/\.c$/} @samp_zeros;
  my @got;
  while (defined (my $filename = $it->next)) {
    push @got, $filename;
    $noinfloop->();
  }
  is_deeply (\@got, \@want, 'samp.locatedb.base64 glob *.c');
}

# with 'use_mmap=1' should fail
{
  open my $fh, '<:via(Base64)', $samp_locatedb_base64
    or die "Oops, cannot open again with Base64: $!";
  ok (! eval {
    File::Locate::Iterator->new (database_fh => $fh,
                                 use_mmap => 1);
    1 },
      'samp.locatedb.base64 with use_mmap=1 should fail');
}

is ($/, $orig_RS, 'input record separator unchanged');

exit 0;
