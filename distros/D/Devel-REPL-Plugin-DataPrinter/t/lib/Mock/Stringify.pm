package Mock::Stringify;

use strict;
use warnings;

use overload ('""' => \&stringify);
sub new { my $s = "internal data"; bless \$s; }
sub stringify { "stringified" }

1;
