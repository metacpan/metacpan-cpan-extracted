#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

# -- stack operations

use strict;
use warnings;

use Test::More tests => 7;
use Test::Output;

use Language::Befunge;
my $bef = Language::Befunge->new;


# pop
$bef->store_code( '12345$..q' );
stdout_is { $bef->run_code } '4 3 ', 'pop, normal';
$bef->store_code( '$..q' );
stdout_is { $bef->run_code } '0 0 ', 'pop, empty stack';


# duplicate
$bef->store_code( '4:..q' );
stdout_is { $bef->run_code } '4 4 ', 'duplicate, normal';
$bef->store_code( ':..q' );
stdout_is { $bef->run_code } '0 0 ', 'duplicate, empty stack';


# swap stack
$bef->store_code( '34\..q' );
stdout_is { $bef->run_code } '3 4 ', 'swap stack, normal';
$bef->store_code( '3\..q' );
stdout_is { $bef->run_code } '0 3 ', 'swap stack, empty stack';


# clear stack
$bef->store_code( '12345678"azertyuiop"n..q' );
stdout_is { $bef->run_code } '0 0 ', 'clear stack';

