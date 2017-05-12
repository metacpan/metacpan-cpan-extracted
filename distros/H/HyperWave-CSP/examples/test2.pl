#!/usr/bin/perl
#
# Just bits and pieces I'm using for testing.
#
# Last updated by gossamer on Mon Mar  2 15:09:00 EST 1998
#

use HyperWave::CSP;

#
# Main starts here
#

my $host = "xanadu.com.au";
my $post = $Default_CSP_Port;

my $HyperWave = HyperWave::CSP->new($host, $port, "gossamer", "forget!ful");

#$xindex = $HyperWave->get_objnum_by_name("gossamer/index.html");
#$xindex = $HyperWave->get_objnum_by_name("xanadu/resources.html");
#$xindex = $HyperWave->get_objnum_by_name("xanadu/index.html");
#$xindex = $HyperWave->get_objnum_by_name("xanadu/images/xanadu2.gif");
$collection = $HyperWave->get_objnum_by_name("gossamer");

#print "\n\nxanadu/index.html is objnum $xindex\n";
print "\n\ncollection gossamer is objnum $collection\n";

#print "\nattributes for xanadu/index.html:\n";
#print $HyperWave->get_attributes($xindex);

print "\nattributes for gossamer:\n";
print $HyperWave->get_attributes($collection);

#print "\nanchors for xanadu/index.html:\n";
#print $HyperWave->get_anchors($xindex);

#print "\nparents for gossamer ";
#print $HyperWave->get_parents($collection);

#print "\n\nchildren for xanadu:\n";
#print $HyperWave->get_children($xindex);

#print "\nchildren for gossamer: ";
#print $HyperWave->get_children($collection);

#print "\n\nanchor objects:\n";
#foreach (split(/\s+/,$HyperWave->get_anchors($xindex))) {
#   print "\n=$_=\n";
#   print $HyperWave->get_attributes($_);
#}

#print "\ntext for xanadu:\n";  # spammy!!
#print $HyperWave->get_text($xindex);

#print "\nhtml for xanadu:\n";  # spammy!!
#print $HyperWave->get_html($xindex);

print "\nAdd collection: ";
print $HyperWave->insert_collection($collection, "gossamer/test") || "Error: " . $HyperWave->error_message() . "\nServer error: " . $HyperWave->server_error_message() . "\n";
print "\n";

exit 1;
#
# End.
#
