use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Test::Markdent;

test_all_html('document');

done_testing();
