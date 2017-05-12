# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}
use Geography::Countries qw /:DEFAULT :LISTS :FLAGS :INDICES/;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $test = 1;

printf "%sok %d\n", "Germany"                     eq country ( "DE")
                    ? "" : "not ", ++ $test;
printf "%sok %d\n", "Netherlands"                 eq country ("NLD")
                    ? "" : "not ", ++ $test;
printf "%sok %d\n", "Mali"                        eq country ( 466 )
                    ? "" : "not ", ++ $test;
printf "%sok %d\n", "Europe"                      eq country ( 150, CNT_F_ANY)
                    ? "" : "not ", ++ $test;
printf "%sok %d\n", "Federal Republic of Germany" eq country ( 280, CNT_F_OLD)
                    ? "" : "not ", ++ $test;

my $e = country 150;
printf "%sok %d\n", defined $e
                    ? "not " : "", ++ $test;

my @list = country "United Kingdom";
printf "%sok %d\n", $list [CNT_I_COUNTRY] eq "United Kingdom"
                    ? "" : "not ", ++ $test;
printf "%sok %d\n", $list [CNT_I_CODE3]   eq "GBR"           
                    ? "" : "not ", ++ $test;

my @codes = code3;
printf "%sok %d\n", @codes == 230
                    ? "" : "not ", ++ $test;

eval {my $c = &country (1, 2, 3)};
printf "%sok %d\n", $@ =~ /^Too many arguments/
                    ? "" : "not ", ++ $test;

eval {my $c = country 1, "foobah"};
printf "%sok %d\n", $@ =~ /^Illegal second argument/
                    ? "" : "not ", ++ $test;

printf "%sok %d\n", defined $Geography::Countries::VERSION
                    ? "" : "not ", ++ $test;
