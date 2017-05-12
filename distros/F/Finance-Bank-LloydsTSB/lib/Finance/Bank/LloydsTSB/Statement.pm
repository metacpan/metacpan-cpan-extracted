package Finance::Bank::LloydsTSB::Statement;

use strict;
use warnings;

our $VERSION = '1.35';

sub transactions { shift->{transactions} }
sub start_date   { shift->{start_date}   }
sub end_date     { shift->{end_date}     }

1;
