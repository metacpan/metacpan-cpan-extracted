use strict;
use warnings;

use Test::More tests => 1;
use JavaScript::Prepare;



my $jsprep = JavaScript::Prepare->new();
isa_ok( $jsprep, 'JavaScript::Prepare' );