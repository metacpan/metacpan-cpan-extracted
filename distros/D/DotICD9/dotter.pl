#!/usr/local/bin/perl

use lib '/usr/local/perl';

use DotICD9;
my $i = new DotICD9;
print "DotICD9 version $DotICD9::VERSION\n";
(@ARGV) or
die "dotter.pl\tICD-9 Dotter Utility\nUSAGE: dotter.pl <code1> <D|O> <code2> <D|O> ... til you get tired\n\n";

while( @ARGV )
{
	my $code = shift @ARGV;
	my $arg = shift @ARGV;
	print $code, "\t==>\t", $i->dot($code, $arg),"\n";
}
