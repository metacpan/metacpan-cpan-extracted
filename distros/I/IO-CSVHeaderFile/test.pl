# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use IO::CSVHeaderFile;

ok(sub{
	# write test
	my $csv = IO::CSVHeaderFile->new("> CSVHeaderFile.csv" , 
        {col => ['Title1', 'Title2', 'Title1']}) or return;
    $csv->csv_print({Title1 => 'First', Title2 => 'Second'}) or return;
    $csv->csv_print(['Uno', 'Duo', 'Tre']) or return;
    $csv->csv_print(
    	Title1 => 'One',
    	Title2 => 'Two to be rewritten',
    	Title2 => 'Two',
    	Title1 => 'Three with the same name as One'
    	) or return;
    $csv->close;
}); 

ok(sub{
	# read test
	my $csv = IO::CSVHeaderFile->new("< CSVHeaderFile.csv" ) or return;
	my $line1 = $csv->csv_read or return;
	print "Hash read l1: $line1->{Title1},$line1->{Title2}\n";
	my $line2 = $csv->csv_read or return;
	print "Hash read l2: $line2->{Title1},$line2->{Title2}\n";
	my @line3 = $csv->csv_read or return;
	print "Array read l2: ".join(',',@line3)."\n";
    $csv->close;
    unlink "CSVHeaderFile.csv";
}); 

# If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

