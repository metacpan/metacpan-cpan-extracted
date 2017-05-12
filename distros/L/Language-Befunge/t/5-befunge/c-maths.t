#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

# -- math functions

use strict;
use warnings;

use Test::More tests => 21;
use Test::Exception;
use Test::Output;

use Language::Befunge;
my $bef = Language::Befunge->new;


# multiplication
$bef->store_code( '49*.q' );
stdout_is { $bef->run_code } '36 ', 'regular multiplication';
$bef->store_code( '4*.q' );
stdout_is { $bef->run_code } '0 ', 'multiplication with empty stack';
$bef->store_code( 'aaa** aaa** * aaa** aaa** *  * . q' );
throws_ok { $bef->run_code } qr/program overflow while performing multiplication/,
    'program overflow during multiplication';
$bef->store_code( '1- aaa*** aaa** * aaa** aaa** *  * . q' );
throws_ok { $bef->run_code } qr/program underflow while performing multiplication/,
    'program underflow during multiplication';


# addition
$bef->store_code( '35+.q' );
stdout_is { $bef->run_code } '8 ', 'regular addition';
$bef->store_code( 'f+.q' );
stdout_is { $bef->run_code } '15 ', 'addition with empty stack';
$bef->store_code( '2+a* 1+a* 4+a* 7+a* 4+a* 8+a* 3+a* 6+a* 4+a* 6+ f+ .q' );
throws_ok { $bef->run_code } qr/program overflow while performing addition/,
    'program overflow during addition';
$bef->store_code( '2+a* 1+a* 4+a* 7+a* 4+a* 8+a* 3+a* 6+a* 4+a* 6+ - 0f- + .q' );
throws_ok { $bef->run_code } qr/program underflow while performing addition/,
    'program underflow during addition';


# subtraction
$bef->store_code( '93-.q' );
stdout_is { $bef->run_code } '6 ', 'regular subtraction';
$bef->store_code( '35-.q' );
stdout_is { $bef->run_code } '-2 ', 'regular subtraction, negative';
$bef->store_code( 'f-.q' );
stdout_is { $bef->run_code } '-15 ', 'subtraction with empty stack';
$bef->store_code( '2+a* 1+a* 4+a* 7+a* 4+a* 8+a* 3+a* 6+a* 4+a* 6+ 0f- - .q' );
throws_ok { $bef->run_code } qr/program overflow while performing substraction/,
    'program overflow during subtraction';
$bef->store_code( '2+a* 1+a* 4+a* 7+a* 4+a* 8+a* 3+a* 6+a* 4+a* 6+ - f- .q' );
throws_ok { $bef->run_code } qr/program underflow while performing substraction/,
    'program underflow during subtraction';


# division
$bef->store_code( '93/.q' );
stdout_is { $bef->run_code } '3 ', 'regular division';
$bef->store_code( '54/.q' );
stdout_is { $bef->run_code } '1 ', 'regular division, non-integer';
$bef->store_code( 'f/.q' );
stdout_is { $bef->run_code } '0 ', 'division with empty stack';
$bef->store_code( 'a0/.q' );
stdout_is { $bef->run_code } '0 ', 'division by zero';
# can't over/underflow integer division


# remainder
$bef->store_code( '93%.q' );
stdout_is { $bef->run_code } '0 ', 'regular remainder';
$bef->store_code( '54/.q' );
stdout_is { $bef->run_code } '1 ', 'regular remainder, non-integer';
$bef->store_code( 'f%.q' );
stdout_is { $bef->run_code } '0 ', 'remainder with empty stack';
$bef->store_code( 'a0%.q' );
stdout_is { $bef->run_code } '0 ', 'remainder by zero';
# can't over/underflow integer remainder


