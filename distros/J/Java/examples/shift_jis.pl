#!/home/markt/usr/local/Linux/bin/perl

use Java;

my $java = new Java;
#my $min_value = $java->get_field("java.lang.Byte","MIN_VALUE")->get_value;
#my $max_value = $java->get_field("java.lang.Byte","MAX_VALUE")->get_value;
#print "$min_value - $max_value\n";
# Strangely Java wants 'Bytes' from -128 to 127 !

my $glis ="\x82\xb1\x82\xea\x82\xcd\x8e\x8e\x8c\xb1\x82\xc5\x82\xb7\x81\x42";
#my $glis ="Hello World";
my $str = $java->create_raw_string("shift_jis",$glis);
my $test = $java->create_object("CharDumper");
$test->dump( $str, "shift_jis" ); # Dump bytes in this encoding
$test->dump( $str ); # Dump bytes in default encoding
			# ISO8859-1 in my case...

# This will print in local encoding so will probably be just '?'s...
$test->print($str);

