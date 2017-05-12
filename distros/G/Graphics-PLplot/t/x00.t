#!perl

# Test basic non-plotting interface
#
# This version Copyright (C) 2004 Tim Jenness. All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful,but WITHOUT ANY# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place,Suite 330, Boston, MA  02111-1307, USA
#

use strict;
use Test::More tests => 8;
BEGIN {
  use_ok("Graphics::PLplot");
  Graphics::PLplot->import(qw/ :all /);
}

my $vers = plgver(); # in M.N.P format
$vers =~ s/\.\d+$//;  # throw away patch level

print "# Version: ".plgver()."\n";
ok(($vers > 0 && $vers < 100), "Check version number");

plSetUsage( $0, "$0");
my ($status, $unprocessed) = plParseOpts(\@ARGV, PARSE_QUIET);

# Set device name and verify it was set
my $driver = "psc";
plsdev( $driver );

my $fname = "pl_psc_dummy";
plsfnam($fname);
is(plgdev, $driver, "Check device is what we think it is");

# Can use plsfile but the problem here is that plend tries to 
# close the filehandle itself (as does perl). We need to intercept that before
# this can be used. We get a SEGV.
# plsfile( \*STDOUT );

plinit();

is( plP_getinitdriverlist(), $driver, "Check driver is initialised");
ok( plP_checkdriverinit($driver), "Alternative init check");

is( plgesc(plsesc("%")),"%", "Check escape sequence");
is( plgfnam(), $fname, "Check file name");

ok( !plxormod(1), "Can not do interactive mode");

plClearOpts();
plResetOpts();
plSetUsage($0,"Some usage info");

# will confuse test harness
# plOptUsage();

# Causes SEGV when both perl and plplot close the file
#my $file = plgfile();
#isa_ok($file, "Graphics::PLplot");

plend();

# Tidy up
unlink $fname;
