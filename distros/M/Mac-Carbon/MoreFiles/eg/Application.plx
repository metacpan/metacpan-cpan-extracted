Perl -Sx "{0}" {"Parameters"}; Exit {Status}

#!perl
#
# Application.t - Demonstrate %Application
#

use Mac::MoreFiles;

if ($Application{McPL}) {
	print "MacPerl apparently is in $Application{McPL}\n";
}
if ($Application{MACS}) {
	print "Finder apparently is in $Application{MACS}\n";
}
die "Oops! You have Microsoft Word on your machine" if $Application{"MSWD"};

