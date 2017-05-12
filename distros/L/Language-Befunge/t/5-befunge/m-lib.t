#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

# -- libraries semantics

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;
use Test::Output;

use Language::Befunge;
use Config;
my $bef = Language::Befunge->new;


$bef->store_code( <<'END_OF_CODE' );
"OLEH" 4 ( P q
END_OF_CODE
stdout_is { $bef->run_code } "Hello world!\n", 'basic loading';

$bef->store_code( <<'END_OF_CODE' );
"OLEH" 4 ( S > :# #, _ q
END_OF_CODE
stdout_is { $bef->run_code } "Hello world!\n", 'interact with ip';

$bef->store_code( <<'END_OF_CODE' );
"JAVA" 4 #v( 2. q
 q . 1    <
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'unknown extension';

$bef->store_code( <<'END_OF_CODE' );
f- 1 (
END_OF_CODE
throws_ok { $bef->run_code }
    qr/Attempt to build a fingerprint with a negative number/,
    'loading a library with a negative fingerprint barfs';

$bef->store_code( <<'END_OF_CODE' );
"OLEH" 4 ( "OOF" 3 ( P q
END_OF_CODE
stdout_is { $bef->run_code } 'foo', 'extension overloading';

$bef->store_code( <<'END_OF_CODE' );
"OLEH" 4 ( "OOF" 3 ( S > :# #, _ q
END_OF_CODE
stdout_is { $bef->run_code } "Hello world!\n", 'extension inheritance';

$bef->store_code( <<'END_OF_CODE' );
"OLEH" 4 ( "OOF" 3 ( P ) P q
END_OF_CODE
stdout_is { $bef->run_code } "fooHello world!\n", 'extension unloading';

$bef->store_code( <<'END_OF_CODE' );
"AMOR" 4 ( "UDOM" 4 ( "AMOR" 4 ) M .q
END_OF_CODE
stdout_is { $bef->run_code } '1000 ', 'unloading extension under stack';

$bef->store_code( <<'END_OF_CODE' );
"OLEH" 4 ( "JAVA" 4 #v ) 2.q
                q.1  <
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'unloading non-loaded extension';

$bef->store_code( <<'END_OF_CODE' );
f- 1 )
END_OF_CODE
throws_ok { $bef->run_code }
    qr/Attempt to build a fingerprint with a negative number/,
    'unloading a library with a negative fingerprint barfs';

