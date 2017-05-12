#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.


# Check that the supported fields described in each pod matches what the
# code says.

use 5.005;
use strict;
use FindBin;
use ExtUtils::Manifest;
use List::Util 'max';
use File::Spec;
use Test::More;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Smart::Comments;

# new in 5.6, so unless got it separately with 5.005
eval { require Pod::Parser }
  or plan skip_all => "Pod::Parser not available -- $@";
plan tests => 1;

my $toplevel_dir = File::Spec->catdir ($FindBin::Bin, File::Spec->updir);
my $manifest_file = File::Spec->catfile ($toplevel_dir, 'MANIFEST');
my $manifest = ExtUtils::Manifest::maniread ($manifest_file);

my @lib_modules
  = map {m{^lib/Math/NumSeq/([^/]+)\.pm$} ? $1 : ()} keys %$manifest;
@lib_modules = sort @lib_modules;
diag "module count ",scalar(@lib_modules);

#------------------------------------------------------------------------------

{
  open FH, 'lib/Math/NumSeq.pm' or die $!;
  my $content = do { local $/; <FH> }; # slurp
  close FH or die;
  ### $content

  {
    $content =~ /=for my_pod see_also begin(.*)=for my_pod see_also end/s
      or die "see_also not matched";
    my $see_also = $1;

    my @see_also;
    while ($see_also =~ /L<Math::NumSeq::([^>]+)>/g) {
      push @see_also, $1;
    }
    @see_also = sort @see_also;

    my $s = join(', ',@see_also);
    my $l = join(', ',@lib_modules);
    is ($s, $l);

    my $j = "$s\n$l";
    $j =~ /^(.*)(.*)\n\1(.*)/ or die;
    my $sd = $2;
    my $ld = $3;
    if ($sd) {
      diag "see also: ",$sd;
      diag "library:  ",$ld;
    }
  }
}

#------------------------------------------------------------------------------

exit 0;
