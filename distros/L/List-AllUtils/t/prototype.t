use strict;
use warnings;

use Test::More;

use List::AllUtils qw( all pairwise rev_nsort_by );
use Sub::Util qw( prototype );

is( prototype( \&all ),          '&@',    'prototype for all' );
is( prototype( \&pairwise ),     '&\@\@', 'prototype for pairwise' );
is( prototype( \&rev_nsort_by ), '&@',    'prototype for rev_nsort_by' );

done_testing();
