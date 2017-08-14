#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# This file is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  See the file COPYING.  If not, see
# <http://www.gnu.org/licenses/>.

use strict;
use 5.004;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

plan tests => 2;


#------------------------------------------------------------------------------
# graphs in MANIFEST same as in Makefile.PL

my $manifest = do { open my $fh, '<MANIFEST' or die;
                    local $/; <$fh> };
my @manifest;
while ($manifest =~ m{^lib/Graph/Maker/([^.]+)\.pm$}mg) {
  push @manifest, $1;
}
@manifest = sort @manifest;
MyTestHelpers::diag ("manifest ",scalar(@manifest)," modules");
$manifest = join(',',@manifest);

my $makefile = do { open my $fh, '<Makefile.PL' or die;
                    local $/; <$fh> };
my @makefile;
while ($makefile =~ m{file[ \t]*=>[ \t]*'lib/Graph/Maker/([^.]+)\.pm'}mg) {
  push @makefile, $1;
}
@makefile = sort @makefile;
MyTestHelpers::diag ("makefile ",scalar(@makefile)," modules");
$makefile = join(',',@makefile);

ok(scalar(@manifest) >= 7);
ok($manifest eq $makefile);

unless ($manifest eq $makefile) {
  MyTestHelpers::diag ("manifest $manifest");
  MyTestHelpers::diag ("makefile $makefile");
}

#------------------------------------------------------------------------------
exit 0;
