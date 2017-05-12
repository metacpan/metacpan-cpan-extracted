#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Image::SVG::Path 'extract_path_info';
my @path_info = extract_path_info ('M6.93,103.36c3.61-2.46,6.65-6.21,6.65-13.29c0-1.68-1.36-3.03-3.03-3.03s-3.03,1.36-3.03,3.03s1.36,3.03,3.03,3.03C15.17,93.1,10.4,100.18,6.93,103.36z');

my $count = 0;
for my $element (@path_info) {                
    $count++;                                 
    print "Element $count:\n";                
    for my $k (sort keys %$element) {              
	my $val = $element->{$k};             
	if (ref $val eq 'ARRAY') {            
	    $val = "[$val->[0], $val->[1]]";  
	}                                     
	print "   $k -> $val\n";              
    }                                         
}
