use strict;
use warnings;

use Test::More;

plan skip_all => 'Travis installation detected (but not for this distribution itself): too complicated to test.'
    if $ENV{CONTINUOUS_INTEGRATION};

plan tests => 1;
pass 'this is a placeholder test';
