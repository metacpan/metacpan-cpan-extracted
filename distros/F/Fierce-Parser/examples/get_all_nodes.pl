#!/usr/bin/perl -w
# $Id: session.pl 17 2009-03-02 01:58:09Z jabra $ 
#  
# get_all_nodes example script
#
# Example: 
# 
#  $ ./get_all_nodes.pl yahoo-google.xml 
#  yahoo.com
#  google.com
#
#
use strict;
use Fierce::Parser;
my $fp = new Fierce::Parser;

if (defined($ARGV[0])){
    my $file = $ARGV[0];
    my $parser = $fp->parse_file($file);
    my @nodes    = $parser->get_all_nodes();

    foreach my $n (@nodes){
        print $n->domain . "\n";
    }
}
else {
    print "Usage: $0 [fierce-xml]\n";
}
