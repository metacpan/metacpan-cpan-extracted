#!/usr/bin/perl

#system 'lynx -dump http://www.usps.gov/ncsc/lookups/usps_abbreviations.htm > kruft.txt';
open P, 'kruft.txt';

while (<P>) {
    if (/\w/) 
    {

	$_ =~ s/^\s+//;
	$_ =~ s/\s+$//;

	if (++$line_count % 2) 
	{
	    $current_state=$_;
	} 
	else 
	{
	    $code{$current_state}=$_;
	}
    }    
}

open C, '>codes.dat';
foreach (sort keys %code) {
    print C "$code{$_}:$_\n";
}

