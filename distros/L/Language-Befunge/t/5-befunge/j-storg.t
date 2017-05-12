#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

# -- storage operations

use strict;
use warnings;

use Test::More tests => 6;
use Test::Output;

use Language::Befunge;
my $bef = Language::Befunge->new;


# put instruction
$bef->store_code( <<'END_OF_CODE' );
0      {  01+a*1+a*8+ 11p v
    q.2                   <
         >  1.q
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'put, new storage offset';
$bef->store_code( <<'END_OF_CODE' );
0      { 22+ 0 } 01+a*1+a*8+ 61p v
 q.2                             <
      >  1.q
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'put, retrieving old storage offset';


# get instruction
$bef->store_code( <<'END_OF_CODE' );
0  ;blah;{  04-0g ,q
END_OF_CODE
stdout_is { $bef->run_code } 'a', 'get, new storage offset';
$bef->store_code( <<'END_OF_CODE' );
0  ;blah;  { 22+ 0 } 40g ,q
END_OF_CODE
stdout_is { $bef->run_code } 'b', 'get, retrieving old storgae offset';


# medley.
$bef->store_code( <<'END_OF_CODE' );
0  'G14p . 14g ,q
END_OF_CODE
stdout_is { $bef->run_code } '0 G', 'medley, positive values';
$bef->store_code( <<'END_OF_CODE' );
0  'f01-04- p . 01-04-g ,q
END_OF_CODE
stdout_is { $bef->run_code } '0 f', 'medley, negative values';

