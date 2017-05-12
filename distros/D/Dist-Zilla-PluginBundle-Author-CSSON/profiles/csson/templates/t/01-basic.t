use strict;
use warnings FATAL => 'all';
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use {{ (my $mod = $dist->name) =~ s/-/::/g; $mod }};

# replace with the actual test
ok 1;

done_testing;
