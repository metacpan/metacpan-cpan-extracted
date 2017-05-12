use strict;
use warnings;

use Test::More;

eval { require Test::Kwalitee; };
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

Test::Kwalitee->import();
