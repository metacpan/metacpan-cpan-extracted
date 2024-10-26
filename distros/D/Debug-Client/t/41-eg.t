#!/usr/bin/perl

use 5.010;
use strict;
use warnings FATAL => 'all';

# turn on $output_autoflush
local $| = 1;

use Test::More tests => 1;

{
    my $exit_code = system "$^X -c eg/debugger.pl";
    is $exit_code, 0;
}

done_testing();

1;

__END__
