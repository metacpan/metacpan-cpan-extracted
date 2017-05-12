#!/home/markt/usr/local/Linux/bin/perl -w
use strict;
no strict 'subs';
use lib '..';
use Java;

use utf8;
# Localization example...


##
# See http://www.javasoft.com/products/jdk/1.1/docs/guide/intl/encoding.doc.html
#	for list of valid Java string encodings...
###
my $java = new Java;

my $new;
# A unicode string - god know what it is...
my $glis = "\x{395}\x{3CD}\x{3B1}\x{3B3}\x{3B3}\x{3B5}\x{3BB}\x{3CA}\x{3B1}\x{65}\x{66}";

print "\n\n\n";
my $enc_string = $java->create_raw_string("UTF8",$glis);
my $val = $enc_string->get_value;
print "VAL: $val";
my $ll = $enc_string->length->get_value;
print "LEN: $ll";
my $utf_bytes = $enc_string->getBytes("UTF8");
my $reg_bytes = $enc_string->getBytes();
for (my $i = 0; $i < $reg_bytes->get_length; $i++)
{
	print "UTF: ",$utf_bytes->get_field($i)->get_value,"\tReg: ",$reg_bytes->get_field($i)->get_value,"\n";
}

my $test = $java->create_object("test");
$test->dump( $enc_string, "UTF8" );
$test->print($enc_string);
print "Same\n" if ($enc_string->get_value eq $glis);


