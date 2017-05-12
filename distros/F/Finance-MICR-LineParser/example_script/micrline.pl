#!/usr/bin/perl -w
use strict;
use Cwd;	
BEGIN { eval "use lib '".cwd()."/lib';"; }

use Finance::MICR::LineParser;

my $string = $ARGV[0];
$string or die('missing arg'); 

my $micr = new Finance::MICR::LineParser({ string => $string });

if ($micr->valid){
		print "A valid MICR line is present: ".$micr->micr."\n";
		print "The type of check is: ".$micr->get_check_type."\n";
		print "The routing number is: ".$micr->routing_number."\n";
		print "The check number is: ".$micr->check_number."\n";
		print "Status: ".$micr->status;
		
}

elsif ($micr->is_unknown_check){
		print "I don't see a full valid MICR line here, but this is what I can match up "
		."if this is a business check: ". $micr->micr."\n";
		print "Status: ".$micr->status;		
}

else {
		print "This is garble to me.\n";
		print "Status: ".$micr->status;	
}

exit;
