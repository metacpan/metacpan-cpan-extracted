package Testophile;

use v5.8;

use Test::More tests => 1;

$\ = "\n";
$, = "\n\t";

BEGIN { -d './lib/foo' || mkdir './lib/foo', 0555  or die $! }
END   { -d './lib/foo' && rmdir './lib/foo'        or die $! }

use FindBin::libs qw( export subdir=foo );

my $found   = grep m{\bfoo\b}, @lib;

ok $found, 'Found foo subdir';

__END__
