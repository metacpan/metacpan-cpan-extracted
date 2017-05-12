#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use Language::Befunge;

use Test::More tests => 7;
use Test::Output;

my $bef;


# basic constructor.
$bef = Language::Befunge->new( {file => "t/_resources/q.bf"} );
stdout_is { $bef->run_code } '', 'constructor works';


# basic reading.
$bef = Language::Befunge->new;
$bef->read_file( 't/_resources/q.bf' );
stdout_is { $bef->run_code } '', 'basic reading';


# reading a non existent file.
eval { $bef->read_file( '/dev/a_file_that_is_not_likely_to_exist' ); };
like( $@, qr/line/, 'reading a non-existent file barfs' );


# basic storing.
$bef->store_code( <<'END_OF_CODE' );
q
END_OF_CODE
stdout_is { $bef->run_code } '', 'basic storing';


# interpreter must treat non-characters as if they were an 'r' instruction.
$bef->store_code( <<'END_OF_CODE' );
01-b0p#q1.2 q
END_OF_CODE
stdout_is { $bef->run_code } '1 2 ', 'non-chars treated as "r" instruction';


# interpreter must treat non-commands as if they were an 'r' instruction.
$bef->store_code( <<'END_OF_CODE' );
01+b0p#q1.2 q
END_OF_CODE
stdout_is { $bef->run_code } '1 2 ', 'non-commands treated as "r" instruction';


# befunge interpreter treats high/low instructions as unknown characters.
$bef->store_code( <<"END_OF_CODE" );
1#q.2h3.q
END_OF_CODE
stdout_is { $bef->run_code } '1 2 ', 'high/low treated as "r" instruction';

