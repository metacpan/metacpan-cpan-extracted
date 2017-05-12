#!perl -wT

use Filter::Encoding;  # Check that it works with no arguments.

use Filter::Encoding 'iso-8859-7';

print "1..3\n";

# I am deliberately using package vars so that I can access them via
# "\x{...}" notation as well (to make sure they are named correctly).
$αριθμός = '65';
$αριθμός ++;

print "not " unless ${"\x{3b1}\x{3c1}\x{3b9}\x{3b8}\x{3bc}\x{3cc}\x{3c2}"}
     == 66;
print "ok 1 - variable names\n";

print "not " unless "φουμπαρ"
     eq "\x{3c6}\x{3bf}\x{3c5}\x{3bc}\x{3c0}\x{3b1}\x{3c1}";
print "ok 2 - strings\n";

$φου = "μπαρ";
$φου =~ y/α/ε/;
print "not " unless $φου eq "\x{3bc}\x{3c0}\x{3b5}\x{3c1}";
print "ok 3 - y\n";
