# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use File::Searcher;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# setup test files
eval{require Fcntl;};
mkdir (test, 0777);
open(FILEX, ">./test/cases.txt") || die $!;
print FILEX qq~the quick brown fox jumped over the lazy dog~;
close(FILEX);
open(FILEX, ">./test/punctuation.txt") || die $!;
print FILEX qq~the words of "these" sentance's, have punctuation; therefore, its some-what of a puzzle! right?~;
close(FILEX);
open(FILEX, ">./test/sm.txt") || die $!;
print FILEX "<head><title>test\n</title>\n</head>";
close(FILEX);


# test 2
# test \@files
my $search2 = File::Searcher->new(['cases.txt','sm.txt']);
$search2->start;
my @files_matched = $search2->files_matched;
print (scalar(@files_matched) == 2 ? "ok 2\n" : "not ok 2\n");

# test 3
# test file expression
my $search3 = File::Searcher->new('*.txt');
$search3->start;
my @files_matched3 = $search3->files_matched;
print (scalar(@files_matched3) == 3 ? "ok 3\n" : "not ok 3\n");


## test 4
## test eval
my $search4 = File::Searcher->new(['cases.txt']);
$search4->add_expression(name=>'1',search=>'(\w+)', replace=>'uc($1)',options=>'e');
$search4->do_replace(1);
$search4->start;
my @files_matched4 = $search4->files_matched;
my $file4 = '';
open(FILEX, "$files_matched4[0]") || die $!;
while(<FILEX>){$file4.=$_;}
close(FILEX);
print ($file4 eq "THE QUICK BROWN FOX JUMPED OVER THE LAZY DOG" ? "ok 4\n" : "not ok 4\n");

# test 5
# test single/multi line
# and expression processing
my $search5 = File::Searcher->new(['sm.txt']);
$search5->add_expression(name=>'1',search=>'<title>(.*?)<\/title>', replace=>'$1',options=>'mi');
$search5->add_expression(name=>'2',search=>'<title>(.*?)<\/title>', replace=>'$1',options=>'si');
$search5->add_expression(name=>'3',search=>'<head>(.*?)<\/head>', replace=>'$1',options=>'mi');
$search5->add_expression(name=>'4',search=>'<head>(.*?)<\/head>', replace=>'$1',options=>'si');
$search5->do_replace(1);
$search5->start;
my @files_matched5 = $search5->files_matched;
open(FILE, "$files_matched5[0]");
my @file5 = <FILE>;
close(FILE);
my $file5 = join('', @file5);
my @files_replacedE1 = $search5->expression('1')->files_replaced;
my @files_replacedE2 = $search5->expression('2')->files_replaced;
my @files_replacedE3 = $search5->expression('3')->files_replaced;
my @files_replacedE4 = $search5->expression('4')->files_replaced;
my $Etotal = scalar(@files_replacedE1) + scalar(@files_replacedE2)
	+ scalar(@files_replacedE3) + scalar(@files_replacedE4);
my %replacements = $search5->expression('4')->replacements;
foreach my $file (@files_replacedE4){$Etotal += $replacements{$file};}
print ($file5 eq "test\n\n" && $Etotal == 3 ?  "ok 5\n" : "not ok 5\n");

# test 6
# test option form
mkdir('./test');
system('cat /dev/null > ./test/test.tgz');
my $search6 = File::Searcher->new(
	file_expression=>'*.txt',
	start_directory=>'./',
	backup_extension=>'.bak',
	do_backup=>0,
	recurse_subs=>0,
	do_replace=>0,
	archive=>'./test/test.tgz',
	do_archive=>0,
);
$search6->start;
my @files_matched6 = $search6->files_matched;
print (scalar(@files_matched6) == 0 ? "ok 6\n" : "not ok 6\n");

# test 7/8/9
# test changing options, verify output
$search6->recurse_subs(1);
$search6->backup_extension('.back');
$search6->do_backup(1);
$search6->do_archive(1);
$search6->start;

#my $search7 = File::Searcher->new('*.back');
my $search7 = File::Searcher->new(['sm.txt.back','punctuation.txt.back','cases.txt.back']);
$search7->start;
@files_matched7 = $search7->files_matched;
print (scalar(@files_matched7) == 3 ? "ok 7\n" : "not ok 7\n");

my $search8 = File::Searcher->new('*.tgz');
$search8->start;
print ($search8->file_binary_cnt == 1 ? "ok 8\n" : "not ok 8\n");
print ($search8->file_text_cnt == 0 ? "ok 9\n" : "not ok 9\n");

# test cleanup

opendir(DIRTEST, "./test");
while(defined($file = readdir(DIRTEST)))
{
	next if $file =~ /^\.\.?$/;
	unlink("./test/$file");
}
close(DIRTEST);
rmdir("./test");
