use Test::More tests => 1;

use JSONY;

open my $fh, 'Changes' or die "Can't open 'Changes' for input";

my $jsony = do { local $/; <$fh> };

'JSONY'->new->load($jsony);

pass 'Changes file is valid JSONY';
