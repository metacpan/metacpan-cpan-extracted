#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

# -- concurrent funge

use strict;
use warnings;

use Test::More tests => 6;
use Test::Output;

use Language::Befunge;
my $bef = Language::Befunge->new;


# basic concurrency
$bef->store_code( <<'END_OF_CODE' );
#vtzz1.@
 >2.@
END_OF_CODE
stdout_is { $bef->run_code } '2 1 ', 'basic concurrency';


# q kills all ips running
$bef->store_code( <<'END_OF_CODE' );
#vtq
 >123...@
END_OF_CODE
stdout_is { $bef->run_code } '', 'q kills all ips running';


# cloning the stack
$bef->store_code( <<'END_OF_CODE' );
123 #vtzz...@
     >...@
END_OF_CODE
stdout_is { $bef->run_code } '3 3 2 2 1 1 ', 'threading clones the stack';


# spaces are one no-op
$bef->store_code( <<'END_OF_CODE' );
#vtzzz2.@
 >         1.@
END_OF_CODE
stdout_is { $bef->run_code } '1 2 ', 'spaces are one no-op';


# comments are one no-op
$bef->store_code( <<'END_OF_CODE' );
#vtzzz2.@
 >;this is a comment;1.@
END_OF_CODE
stdout_is { $bef->run_code } '1 2 ', 'comments are one no-op';


# repeat instructions are one op
$bef->store_code( <<'END_OF_CODE' );
#vtzzzzz2.@
 >1112k.@
END_OF_CODE
stdout_is { $bef->run_code } '1 1 2 1 ', 'repeat instr is one op';


