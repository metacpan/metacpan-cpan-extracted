#!/usr/bin/perl

$|=1;
use Lingua::Jspell;
use Data::Dumper;

my $dict = Lingua::Jspell->new( "port");
$Data::Dumper::Indent = 0;
while (<>) {
	chomp;
	my $dump = Dumper [$dict->fea($_)];
	$dump =~ s/\$VAR1 = //;
	$dump =~ s/;$//;
	print "$dump\n";
}

