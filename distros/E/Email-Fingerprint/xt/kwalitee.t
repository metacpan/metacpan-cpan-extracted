use strict;
use warnings;

use Test::More;

# Checked by Test::Kwalitee
$ENV{AUTHOR_TESTING} = 1;

eval { require Test::Kwalitee; };
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

Test::Kwalitee->import();
