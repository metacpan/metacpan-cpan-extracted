#!/usr/bin/perl

use strict;
use warnings;

BEGIN
{
    $|         = 1;
    $^W        = 1;
    $ENV{HOME} = '';
}

use Test::More;
use File::HomeDir;

plan skip_all => "Skipping empty \$ENV{HOME} test on $^O since there is no fallback" if ($^O eq 'MSWin32');

plan(tests => 1);
my $home = (getpwuid($<))[7];
is scalar File::HomeDir->my_home, $home, 'my_home found';
