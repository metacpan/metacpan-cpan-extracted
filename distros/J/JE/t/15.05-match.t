#!perl

# This file tests that string.match() works if JE::Object::RegExp is not
# already loaded, so it has to be in its own file.

print "1..1\n";

use JE;
if (new JE->eval(q _"foombedd".match("be")_) ne 'be' ) {
 print "# $@not ";
}
print "ok 1 - string.match() without RegExp already loaded\n";
