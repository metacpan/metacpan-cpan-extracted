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

# -- TEST library

# this test is not like the others, where we check whether the output matches
# what is expected. indeed, since we're testing a test library, we're just
# running the befunge snippets, which should output some regular tap.

use Language::Befunge;
my $bef = Language::Befunge->new;

# TEST.pm and this test script share the same plan.

# plan (2 tests)
$bef->store_code( <<'END_OF_CODE' );
0"TSET"4(#@2P)@
END_OF_CODE
$bef->run_code;

# ok
$bef->store_code( <<'END_OF_CODE' );
0"TSET"4(0"dnammoc O"1O)@
END_OF_CODE
$bef->run_code;

# is
$bef->store_code( <<'END_OF_CODE' );
0"TSET"4(0"dnammoc I"44I)@
END_OF_CODE
$bef->run_code;

