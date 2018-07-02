#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

get '/' => sub {
    +{ -content => <<"EOF" };
As expected
*** WARNING ***
If you see this message, test probably failed.
File a bug in MVC::Neaf!
EOF
};

my $content;
{
    local *STDOUT;
    open STDOUT, ">", \$content
        or die "Failed to redirect stdout: $!";
    neaf->run; # void context
    1;
};

like $content, qr/\bAs expected\b/s, "Data as expected";

done_testing;
