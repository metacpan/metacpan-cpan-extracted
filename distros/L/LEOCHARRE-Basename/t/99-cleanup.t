use Test::Simple 'no_plan';
use strict;
use lib './lib';
use vars qw($_part $cwd);





ok 1;

unlink 't/file.tmp';
`rm -rf 't/dirtmp'`;










sub ok_part { printf STDERR "\n%s\nPART %s %s\n\n", '='x80, $_part++, "@_"; }

