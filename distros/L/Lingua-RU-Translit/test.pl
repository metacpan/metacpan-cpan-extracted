# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Lingua::RU::Translit qw(translit2koi);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print "not " if
  translit2koi("Eto vseGo liSh' pRoverka") ne "Это всеГо лиШь пРоверка";
print "ok 2\n";

print "not " if
  translit2koi("а теперь по-русски") ne "а теперь по-русски";
print "ok 3\n";

print "not " if
  translit2koi("this one must be left as is") ne "this one must be left as is";
print "ok 4\n";

