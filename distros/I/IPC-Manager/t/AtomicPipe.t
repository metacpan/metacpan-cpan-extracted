use strict;
use warnings;

use Test2::Require::Module 'Atomic::Pipe';

{
    no warnings 'once';
    $main::PROTOCOL = 'AtomicPipe';
}

do './t/generic_test.pl' or die $@;
