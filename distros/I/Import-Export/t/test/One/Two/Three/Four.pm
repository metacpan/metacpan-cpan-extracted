package One::Two::Three::Four;

use strict;
use warnings;

use One qw/all/;
use One::Two qw/all/;

sub new { bless {}, $_[0] }

1;
