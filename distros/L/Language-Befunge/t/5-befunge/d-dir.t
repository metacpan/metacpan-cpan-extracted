#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

# -- direction changing

use strict;
use warnings;

use Test::More tests => 19;
use Test::Output;

use Language::Befunge;
my $bef = Language::Befunge->new;


# go west
$bef->store_code( '<q.a' );
stdout_is { $bef->run_code } '10 ', 'go west';


# go south
$bef->store_code( <<'END_OF_CODE' );
v
a
.
q
END_OF_CODE
stdout_is { $bef->run_code } '10 ', 'go south';


# go north
$bef->store_code( <<'END_OF_CODE' );
^
q
.
a
END_OF_CODE
stdout_is { $bef->run_code } '10 ', 'go north';


# go east
$bef->store_code( <<'END_OF_CODE' );
v   > a . q
>   ^
END_OF_CODE
stdout_is { $bef->run_code } '10 ', 'go east';


# go away
$bef->store_code( <<'END_OF_CODE' );
v    > 2.q
>  #v? 1.q
     > 3.q
    >  4.q
END_OF_CODE
stdout_like { $bef->run_code } qr/^[1-4] $/, 'go away';


# turn left
$bef->store_code( <<'END_OF_CODE' );
v  > 1.q
>  [
   > 2.q
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'turn left, from west';
$bef->store_code( <<'END_OF_CODE' );
v  > 1.q
<  [
   > 2.q
END_OF_CODE
stdout_is { $bef->run_code } '2 ', 'turn left, from east';
$bef->store_code( <<'END_OF_CODE' );
>     v
  q.2 [ 1.q
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'turn left, from north';
$bef->store_code( <<'END_OF_CODE' );
>     ^
  q.2 [ 1.q
END_OF_CODE
stdout_is { $bef->run_code } '2 ', 'turn left, from south';


# turn right
$bef->store_code( <<'END_OF_CODE' );
v  > 1.q
>  ]
   > 2.q
END_OF_CODE
stdout_is { $bef->run_code } '2 ', 'turn right, from west';
$bef->store_code( <<'END_OF_CODE' );
v  > 1.q
<  ]
   > 2.q
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'turn right, from east';
$bef->store_code( <<'END_OF_CODE' );
>     v
  q.2 ] 1.q
END_OF_CODE
stdout_is { $bef->run_code } '2 ', 'turn right, from north';
$bef->store_code( <<'END_OF_CODE' );
>     ^
  q.2 ] 1.q
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'turn right, from south';


# reverse
$bef->store_code( <<'END_OF_CODE' );
>  #vr 2.q
    >  1.q
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'reverse, from west';
$bef->store_code( <<'END_OF_CODE' );
<  q.2  rv#
   q.1   <
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'reverse, from east';
$bef->store_code( <<'END_OF_CODE' );
>     v
      #
      > 1.q
      r
      > 2.q
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'reverse, from north';
$bef->store_code( <<'END_OF_CODE' );
>     ^
      > 2.q
      r
      > 1.q
      #
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'reverse, from south';


# absolute vector
$bef->store_code( <<'END_OF_CODE' );
11x
   1
    .
     q
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'absolute vectore, diagonal';
$bef->store_code( <<'END_OF_CODE' );
101-x
   q
  .
 1
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'absolute vectore, diagonal out of bounds';
$bef->run_code;

