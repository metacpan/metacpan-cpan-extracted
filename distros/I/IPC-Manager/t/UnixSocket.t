use strict;
use warnings;

use Test2::Require::Module 'IO::Socket::UNIX';
use Test2::Require::Module 'IO::Select';

{
    no warnings 'once';
    $main::PROTOCOL = 'UnixSocket';
}

do './t/generic_test.pl' or die $@;
