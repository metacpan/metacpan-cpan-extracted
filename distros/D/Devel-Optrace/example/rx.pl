#!perl -w
use strict;
use Devel::Optrace -all;

"foo" =~  m/\w/x;
"foo" =~ qr/\w/x;
