#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

# -- decision making instructions

use strict;
use warnings;

use Test::More tests => 17;
use Test::Output;

use Language::Befunge;
my $bef = Language::Befunge->new;


# logical not
$bef->store_code( 'a!.q' );
stdout_is { $bef->run_code } '0 ', 'logical not';
$bef->store_code( '05-!.q' );
stdout_is { $bef->run_code } '0 ', 'logical not, negative';
$bef->store_code( '0!.q' );
stdout_is { $bef->run_code } '1 ', 'logical not, false';


# comparison
$bef->store_code( '53`.q' );
stdout_is { $bef->run_code } '1 ', 'comparison, greater';
$bef->store_code( '55`.q' );
stdout_is { $bef->run_code } '0 ', 'comparison, equal';
$bef->store_code( '35`.q' );
stdout_is { $bef->run_code } '0 ', 'comparison, smaller';


# horizontal if
$bef->store_code( <<'END_OF_CODE' );
1    v
 q.3 _ 4.q
END_OF_CODE
stdout_is { $bef->run_code } '3 ', 'horizontal if, left from north';
$bef->store_code( <<'END_OF_CODE' );
0    v
 q.3 _ 4.q
END_OF_CODE
stdout_is { $bef->run_code } '4 ', 'horizontal if, right from north';
$bef->store_code( <<'END_OF_CODE' );
1    ^
 q.3 _ 4.q
END_OF_CODE
stdout_is { $bef->run_code } '3 ', 'horizontal if, left from south';
$bef->store_code( <<'END_OF_CODE' );
0    ^
 q.3 _ 4.q
END_OF_CODE
stdout_is { $bef->run_code } '4 ', 'horizontal if, right from south';


# vertical if
$bef->store_code( <<'END_OF_CODE' );
1 v   >3.q
  >   |
      >4.q
END_OF_CODE
stdout_is { $bef->run_code } '3 ', 'vertical if, north from left';
$bef->store_code( <<'END_OF_CODE' );
0 v   >3.q
  >   |
      >4.q
END_OF_CODE
stdout_is { $bef->run_code } '4 ', 'vertical if, south from left';
$bef->store_code( <<'END_OF_CODE' );
1 v   >3.q
  <   |
      >4.q
END_OF_CODE
stdout_is { $bef->run_code } '3 ', 'vertical if, north from right';
$bef->store_code( <<'END_OF_CODE' );
0 v   >3.q
  <   |
      >4.q
END_OF_CODE
stdout_is { $bef->run_code } '4 ', 'vertical if, south from right';


# compare (3 branches if)
$bef->store_code( <<'END_OF_CODE' );
34     v
 q..1  w  01-..q
       > 0..q
END_OF_CODE
stdout_is { $bef->run_code } '-1 0 ', 'compare, greater';
$bef->store_code( <<'END_OF_CODE' );
33     v
 q..1  w  01-..q
       > 0..q
END_OF_CODE
stdout_is { $bef->run_code } '0 0 ', 'compare, equal';
$bef->store_code( <<'END_OF_CODE' );
43     v
 q..1  w  01-..q
       > 0..q
END_OF_CODE
stdout_is { $bef->run_code } '1 0 ', 'compare, smaller';

