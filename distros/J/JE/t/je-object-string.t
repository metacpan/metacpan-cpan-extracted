#!perl  -T

use Test::More tests => 7;
use strict; no warnings 'utf8'; use utf8;



#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok 'JE::Object::String' }



# Bug in 0.028 and earlier (was returning the ‘value’ property instead of
# the value):
require JE;
my $j = new JE;
is +JE::Object::String->new($j, '𐄂')->value, '𐄂', 'value returns Unicode';
ok !ref JE::Object::String->new($j, '𐄂')->value,
	'value returns a simple scalar';


is +JE::Object::String->new($j, '𐄂')->value16, "\x{d800}\x{dd02}",
	'value16 returns surrogates';
ok !ref JE::Object::String->new($j, '𐄂')->value,
	'value returns a simple scalar';

is +JE::Object::String->class, 'String', 'class';

# Bug in 0.029 and earlier:
for("foo") {
	ok !JE::Object::String->new($j, '')->is_readonly(3),
	"is_readonly doesn't return true for prop whose name is length \$_"
}

diag "TODO: Finish writing this script";
