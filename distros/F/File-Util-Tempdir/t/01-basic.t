#!perl

use 5.010;
use strict;
use warnings;

use File::Util::Tempdir qw(get_tempdir);
use Test::Exception;
use Test::More 0.98;

my $dir;

lives_ok { $dir = get_tempdir() };

diag "result of get_tempdir(): ", $dir;

done_testing;
