#!/usr/bin/perl
########################################################################
# misc.t:
#   v0.042: add reduce_hand() to miscFunctions
#       make sure that it will shrink the hand_tile string
########################################################################

use 5.008;

use warnings;
use strict;
use Test::More tests => 3;

use IO::String;
use File::Basename qw/dirname/;
use Cwd qw/abs_path chdir/;
BEGIN: { chdir(dirname($0)); }

use Games::Literati 0.042 qw/:miscFunctions/;


#     print reduce_hand( "rstlnec", "lest");  # prints "rnc"
is reduce_hand( "rstlnec", "lest"), "rnc", "reduce_hand(rstlnec,lest)";
is reduce_hand( "rst?nec", "?est"), "rnc", "reduce_hand(rst?nec,?est)";
eval { reduce_hand( "rstlnec", "hdm"); 1; };
like $@, qr/^\Qreduce_hand(): could not remove 'hdm' from hand tiles 'rstlnec'\E/, "reduce_hand(rstlnec,hdm): expect error";

done_testing();
