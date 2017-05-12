#!/home/markt/usr/local/Linux/bin/perl -w
use strict;
no strict 'subs';
use lib qw(..);
use Java;

###
# A long and arduous way to fetch & display a web page!
###

print "Gimmie the full URL of a page for me to fetch: (http://www.zzo.com) ";
my $page = <STDIN>;
chomp $page;
$page ||= "http://www.zzo.com";
my $java = new Java();

# This'll return a stream...
my $object = $java->create_object("java.net.URL",$page)->openConnection->getContent;

my $array = $java->create_array("byte",5000);

# Read into entire byte array 
my $back = $object->read($array);
my $val = $back->get_value;
print "got back $val chars\n";

my $len = $#{$array};
print "array length $len bytes\n";
for (my $i = 0; $i < $val; $i++)
{
	print chr($array->[$i]->get_value);
}

my $a2 = $java->create_array("double",630);
for (my $i = 0, my $index = 0; $i < 2*3.14159; $i += .01, $index++)
{
	print "Setting $index to $i\n";
	$a2->[$index] = "$i:double";
}
for (my $index = 0; $index < 630; $index++)
{
	my $val = $a2->[$index]->get_value;
	print "Float value $index: $val\n";
}
