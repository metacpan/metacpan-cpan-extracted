package Local::Test;

use 5.008;
use Moo;

sub live { return $_[1] }
sub die  { die $_[1] }

1;
