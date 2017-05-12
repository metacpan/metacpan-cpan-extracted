use strict;
use warnings;

use Test::More tests => 3;
use File::Which;

# Look for a very common program
my $tool = 'perl';
my $path = which($tool);
ok( defined $path, "Found path to $tool" );
ok( $path, "Found path to $tool" );
ok( -f $path, "$tool exists" );

