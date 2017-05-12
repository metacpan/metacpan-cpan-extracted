use Test::More tests => 5;
use vars '$pkg';

use IO::File;
use File::Spec;

use strict;
use Filter::Include;

# no. 1, 2
#include 't/sample_recurse.pl';

# no. 3, 4
is($::sample_test,    'a string',      '$::sample_test is set');
is($::sample_recurse, 'I am a string', '$::sample_recurse is set');

# no. 5
is(__LINE__, 28, "Line numbers incremented correctly");
