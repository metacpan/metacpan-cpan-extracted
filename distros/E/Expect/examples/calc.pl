use strict;
use warnings;

while (my $row = <>) {
	chomp $row;
	print "Input: '$row' = ";
	my $res = eval $row;
	print "'$res' :Output\n";
}
