use strict;
use warnings;

use Test::More 0.88;

use File::LibMagic;

my $v = File::LibMagic::magic_version();
diag("libmagic version $v");
ok( defined $v, 'got a version' );

done_testing();
