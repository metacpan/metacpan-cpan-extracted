use strict;
use warnings;

use Test::Most;

use constant MODULE => 'Google::Tasks';

BEGIN { use_ok(MODULE); }
require_ok(MODULE);

my $obj;
ok( $obj = MODULE->new(), MODULE . '->new()' );
is( ref $obj, MODULE, 'ref $object' );

done_testing;
