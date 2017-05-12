package MyDie;

use strict;
use warnings;

sub mydie
{
    local *I;
    open I, "<", "ChangeLog";
    my $s = <I>;








    die "Hello";
}

1;
