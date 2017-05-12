open MANI, "<MANIFEST";
my @files = <MANI>;
close MANI;

foreach (@files)
{
	chop;
	s/\s//g;
	my $f = $_;
	open INFILE, "<$f";
	open OUTFILE, ">$f.tmp";
	while (<INFILE>) {
		s/\r//g;
		print OUTFILE $_;
	}
	close INFILE;
	close OUTFILE;
	system("mv $f.tmp $f");
}
