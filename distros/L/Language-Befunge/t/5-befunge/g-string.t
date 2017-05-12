#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

# -- string thingies

use strict;
use warnings;

use Test::More tests => 5;
use Test::Output;

use Language::Befunge;
my $bef = Language::Befunge->new;


# string mode
$bef->store_code( '<q,,,,,,,,,,,,,"hello world!"a' );
stdout_is { $bef->run_code } "hello world!\n", 'string mode';
$bef->store_code( '<q,,,,,,,,,,,,,"hello   world!"a' );
stdout_is { $bef->run_code } "hello world!\n", 'string mode, sgml';


# fetch character
$bef->store_code( <<'END_OF_CODE' );
<q,,,,,,,,,,,,,h'e'l'l'o' 'w'o'r'l'd'!'a
END_OF_CODE
stdout_is { $bef->run_code } "hello world!\n", 'fetch char, normal output';
$bef->store_code( <<'END_OF_CODE' );
<q,,,,,,,,,,,,,,h'e'l'l'o' ' 'w'o'r'l'd'!'a
END_OF_CODE
stdout_is { $bef->run_code } "hello  world!\n", 'fetch char, space doubled';


# store character.
$bef->store_code( <<'END_OF_CODE' );
v       > .q
>   '4 s  v
        ^ <
END_OF_CODE
stdout_is { $bef->run_code } '4 ', 'store char';

