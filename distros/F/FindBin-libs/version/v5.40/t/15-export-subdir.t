package Testophile;

use v5.8;

use Test::More;

$\ = "\n";
$, = "\n\t";

BEGIN { -d './lib/foo' || mkdir './lib/foo', 0555  or die $! }
END   { -d './lib/foo' && rmdir './lib/foo'        or die $! }

my $madness = 'FindBin::libs';

require_ok $madness;

$madness->import( qw( export subdir=foo verbose ) );

like $lib[0], qr{\b foo $}x, 'First entry is foo.';

done_testing
__END__
