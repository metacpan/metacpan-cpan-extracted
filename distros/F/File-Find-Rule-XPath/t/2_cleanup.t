# $Id: 2_cleanup.t,v 1.1.1.1 2002/12/18 09:21:18 grantm Exp $
# vim: syntax=perl

use strict;
use File::Spec;
use File::Path;

use Test::More tests => 1;

# Clean up test data files

my $path = File::Spec->catfile('t', 'testdata');
rmtree($path) if($path);

ok(1);

