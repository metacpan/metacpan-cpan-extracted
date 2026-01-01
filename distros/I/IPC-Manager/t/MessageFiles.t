use strict;
use warnings;

{
    no warnings 'once';
    $main::PROTOCOL = 'MessageFiles';
}

do './t/generic_test.pl' or die $@;
