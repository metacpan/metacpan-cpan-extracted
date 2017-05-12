use strict;
use warnings;

use JavaBin;
use Test::More;

my $javabin = to_javabin undef;

is $javabin, "\2\0", 'to_javabin';

is from_javabin($javabin), undef, 'from_javabin';

done_testing;
