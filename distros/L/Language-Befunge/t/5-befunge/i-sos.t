#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

# -- stack of stack operations

use strict;
use warnings;

use Test::More tests => 4;
use Test::Output;

use Language::Befunge;
my $bef = Language::Befunge->new;


# the big fat one
$bef->store_code( <<'END_OF_CODE' );
123 2 { ... 3 { .... 0 { 3 .. 987 01- { . 3 u ... 4 u .. v
0u... 456 02- u 56 04- u 163 2 } .......   2 01-u 2 }  v >
..  4 01- u 0 } .. 004 03-u 02- } .. q                 >
END_OF_CODE
my $exp = "";
# (6,0) { new, >0, enough
#   * bef: ( [1 2 3 2] )      Storage (0,0)
#   * aft: ( [2 3] [1 0 0] )  Storage (7,0)
$exp .= "3 2 0 ";
# (14,0) { new, >0, not enough
#   * bef: ( [3] [1 0 0] )            Storage (7,0)
#   * aft: ( [0 0 0] [7 0] [1 0 0] )  Storage (15,0)
$exp .= "0 0 0 0 ";
# (23,0) { new, =0
#   * bef: ( [0] [7 0] [1 0 0] )        Storage (15,0)
#   * aft: ( [] [15 0] [7 0] [1 0 0] )  Storage (24,0)
$exp .= "3 0 ";
# (37,0) { new, <0
#   * bef: ( [9 8 7 -1] [15 0] [7 0] [1 0 0] )        Storage (24,0)
#   * aft: ( [] [9 8 7 0 24 0] [15 0] [7 0] [1 0 0] ) Storage (38,0)
$exp .= "0 ";
# (44,0) u transfer, >0, enough
#   * bef: ( [3] [9 8 7 0 24 0] [15 0] [7 0] [1 0 0] ) Storage (38,0)
#   * aft: ( [0 24 0] [9 8 7] [15 0] [7 0] [1 0 0] )
$exp .= "0 24 0 ";
# (51,0) u transfer, >0, not enough
#   * bef: ( [6] [9 8 7] [15 0] [7 0] [1 0 0] )  Storage (38,0)
#   * aft: ( [7 8 9 0] [] [15 0] [7 0] [1 0 0] )
$exp .= "0 9 ";
# (1,1) u transfer, =0
#   * bef: ( [7 8 0] [] [15 0] [7 0] [1 0 0] ) Storage (38,0)
#   * aft: ( [7 8] [] [15 0] [7 0] [1 0 0] )
$exp .= "8 7 0 ";
# (14,1) u transfer, <0, enough
#   * bef: ( [4 5 6 -2] [] [15 0] [7 0] [1 0 0] ) Storage (38,0)
#   * aft: ( [4] [6 5] [15 0] [7 0] [1 0 0] )
# (23,1) u transfer, <0, not enough
#   * bef: ( [4 5 6 -4] [6 5] [15 0] [7 0] [1 0 0] ) Storage (38,0)
#   * aft: ( [] [6 5 6 5 4 0] [15 0] [7 0] [1 0 0] )
# (31,1) } destroy, >0, enough
#   * bef: ( [1 6 3 2] [6 5 6 5 4 0] [15 0] [7 0] [1 0 0] ) Storage (38,0)
#   * aft: ( [6 5 6 5 6 3] [15 0] [7 0] [1 0 0] )           Storage (4,0)
$exp .= "3 6 5 6 5 6 0 ";
# (52,1) } destroy, >0, not enough
#   * bef: ( [2] [15 0 2] [7 0] [1 0 0] ) Storage (4,0)
#   * aft: ( [] [7 0] [1 0 0] )         Storage (0,2)
$exp .= "0 0 ";
# (14,2) } destroy, =0
#   * bef: ( [0] [7 0 4] [1 0 0] ) Storage (0,2)
#   * aft: ( [7] [1 0 0] )         Storage (0,4)
$exp .= "7 0 ";
# (32,2) } destroy, <0
#   * bef: ( [-2] [1 0 0 4 0 0] ) Storage (0,4)
#   * aft: ( [1 0] )          Storage (0,0)
$exp .= "0 1 ";
stdout_is { $bef->run_code } $exp, 'stack of stack operations';


# checking storage offset
$bef->store_code( <<'END_OF_CODE' );
0      {  01+a*1+a*8+ 11p v
    q.2                   <
         >  1.q
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'new storage offset';
$bef->store_code( <<'END_OF_CODE' );
0      { 22+ 0 } 01+a*1+a*8+ 61p v
 q.2                             <
      >  1.q
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'retrieving old storage offset';


# checking invalid end-of-block.
$bef->store_code( <<'END_OF_CODE' );
   #v  } 2.q
    > 1.q
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'invalid end of block';

