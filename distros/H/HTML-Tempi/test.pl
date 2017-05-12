# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..19\n"; }
END {print "not ok 1\n" unless $loaded;}
use HTML::Tempi;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

tempi_init("test1.html") || die "$!\n";
set_var("var1", 4) || die "$!\n";
set_var("var2", 6) || die "$!\n";
set_var("var3", 7) || die "$!\n";
parse_block("block1") || die "$!\n";
parse_block("block2") || die "$!\n";
parse_block("block3") || die "$!\n";
parse_block("MAIN") || die "$!\n";
($_ = tempi_out()) || die "$!\n";
s/\n+/ /g;
split;
for ($c = 2; $c <= 10; $c++)
	{
		print (($_[$c-2] == $c) ? ("ok $c\n") : ("not ok $c\n"));
	}
tempi_free() || die "$!\n";
tempi_reinit () || die "$!\n";
tempi_init ("test2.html") || die "$!\n";
set_var("var1", 13) || die "$!\n";
set_var("var2", 14) || die "$!\n";
set_var("var3", 17) || die "$!\n";
parse_block("block1") || die "$!\n";
parse_block("block2") || die "$!\n";
parse_block("block3") || die "$!\n";
parse_block("MAIN") || die "$!\n";
set_var("var4", 18) || die "$!\n";
parse_block("block4") || die "$!\n";
set_var("var4", 19) || die "$!\n";
parse_block("block4") || die "$!\n";
($_ = tempi_out()) || die "$!\n";
s/\n+/ /g;
split;
for ($c = 11; $c <= 19; $c++)
	{
		print (($_[$c-11] == $c) ? ("ok $c\n") : ("not ok $c\n"));
	}
tempi_free() || die "$!\n";
