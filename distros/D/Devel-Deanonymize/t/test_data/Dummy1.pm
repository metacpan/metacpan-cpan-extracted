package Dummy1;
use strict;
use warnings FATAL => 'all';

=head3 test2()

This is a comment for this function containing evil characters
1;

=cut
sub test2 {
    my $val = 1;
    my $val2 = "__DATA__";
}



1;