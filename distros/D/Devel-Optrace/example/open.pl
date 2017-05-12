#!perl -w
use strict;
use Devel::Optrace -all;
open my $in, '<', __FILE__;
print while <$in>;
