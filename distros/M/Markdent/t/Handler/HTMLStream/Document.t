use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/../../../t/lib";

use Test2::V0;
use Test::Markdent;

test_all_html('document');

done_testing();
