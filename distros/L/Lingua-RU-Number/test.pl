# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded; print "not ok 2\n" unless $words;}
use utf8;
use Lingua::RU::Number;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$words = Lingua::RU::Number::rur_in_words(30989.56);
print "30989.56 is $words\n";
$words = Lingua::RU::Number::rur_in_words(10.57);
print "10.57 is $words\n";
$words = Lingua::RU::Number::rur_in_words(10.29);
print "10.29 is $words\n";
$words = Lingua::RU::Number::rur_in_words(10.58);
print "10.58 is $words\n";
$words = Lingua::RU::Number::rur_in_words(11.11);
print "11.11 is $words\n";
$words = Lingua::RU::Number::num2words(11);
print "11 бутылок пива is $words бутылок пива\n";
$words = Lingua::RU::Number::num2words(21, 2);
print "21 очко is $words очко\n";
$words = Lingua::RU::Number::num2words(31, 1);
print "31 телефон is $words телефон\n";
$words = Lingua::RU::Number::num2words(32, 0);
print "32 девушки is $words девушки\n";

print "ok 2\n";
