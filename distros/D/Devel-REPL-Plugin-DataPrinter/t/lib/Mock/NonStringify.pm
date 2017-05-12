package Mock::NonStringify;

use strict;
use warnings;

sub new { my $s = "internal data"; bless \$s; }

1;
