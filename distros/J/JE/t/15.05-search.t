#!perl

# This file tests that string.match() works if JE::Object::RegExp is not
# already loaded, so it has to be in its own file.

print "1..1\n";

use JE;
if (new JE->eval(q _"foombedd".search("be")_) ne '4' ) {
 print "# $@not ";
}
print "ok 1 - string.search() without RegExp already loaded\n";
