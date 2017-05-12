# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..22\n"; }
END {print "not ok 1\n" unless $loaded;}
use Geography::States;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $usa = Geography::States -> new ('USA');

print $usa ? "ok 2\n" : "not ok 2\n"; die unless $usa;

print "New York" eq $usa -> state ('ny')            ? "ok 3\n" : "not ok 3\n";
print "NJ"       eq $usa -> state ('New    jerSEY') ? "ok 4\n" : "not ok 4\n";

my ($code, $name) = $usa -> state ('gu');
print $code eq 'GU' && $name eq 'Guam' ? "ok 5\n" : "not ok 5\n";

my $cnd = Geography::States -> new ('Canada');
print $cnd ? "ok 6\n" : "not ok 6\n"; die unless $cnd;
print "Quebec" eq $cnd -> state ('PQ')     ? "ok 7\n" : "not ok 7\n";
print "QC"     eq $cnd -> state ('Quebec') ? "ok 8\n" : "not ok 8\n";


$usa = Geography::States -> new ('USA', 1);
print $usa ? "ok 9\n" : "not ok 9\n"; die unless $usa;
print scalar $usa -> state ('Gu') ? "not ok 10\n" : "ok 10\n";
my @list = $usa -> state;
print 50 == @list ? "ok 11\n" : "not ok 11\n";
print 50 == $usa -> state ? "ok 12\n" : "not ok 12\n";

my $cnd1 = Geography::States -> new ('canada', 1);
print $cnd1 ? "ok 13\n" : "not ok 13\n"; die unless $cnd1;
print $cnd1 -> state ('PQ') ? "not ok 14\n" : "ok 14\n";

my $nl = Geography::States -> new ('The Netherlands');
print $nl ? "ok 15\n" : "not ok 15\n"; die unless $nl;
print "Utrecht" eq $nl -> state ('UT') ? "ok 16\n" : "not ok 16\n";

my $au = Geography::States -> new ('Australia');
print $au ? "ok 17\n" : "not ok 17\n"; die unless $au;
print "Western Australia" eq $au -> state ('WA') ? "ok 18\n" : "not ok 18\n";
print "Queensland" eq $au -> state ('QLD') ? "ok 19\n" : "not ok 19\n";

my $br = Geography::States -> new ('Brazil');
print $br ? "ok 20\n" : "not ok 20\n"; die unless $br;
print "Rondônia" eq $br -> state ('RO') ? "ok 21\n" : "not ok 21\n";

print $cnd -> state ('NL') eq "Newfoundland and Labrador"
            ? "ok 22\n" : "not ok 22\n";
