#!perl

use strict;

use Test::More tests => 1;
use File::Slurp qw(read_file);

my $file = 'config.log';
my $log = -f $file ? read_file($file) : "$file doesn't exist";
ok( $log, "show $file" ) and diag($log);
