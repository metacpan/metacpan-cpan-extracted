#!perl  -T

use Test::More tests => 5;
use strict;
use utf8;


#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok 'JE::String' } # Make sure it can load without JE
BEGIN { use_ok 'JE' }         # already loaded


# Bug in 0.016 (was returning a Perl scalar):
isa_ok +JE::String->new(new JE, 'aoeu')->prop('length'), "JE::Number",
	'result of ->prop("length")';

{no warnings 'utf8';
is +JE::String->new(new JE, '𐄂')->value16, "\x{d800}\x{dd02}",'value16'}

is +JE::String->class, 'String', 'class';

diag "TODO: Finish writing this script";