#!/usr/bin/perl

use strict;
use Test::More tests => 16;
use File::Spec::Functions qw(catfile curdir catdir rel2abs);
use File::List::Object;

BEGIN {
	$|  = 1;
	$^W = 1;
}

my @file = (
    catfile( rel2abs(curdir()), qw(t test02 file1.txt)),
    catfile( rel2abs(curdir()), qw(t test02 file2.txt)),
    catfile( rel2abs(curdir()), qw(t test02 file3.txt)),
    catfile( rel2abs(curdir()), qw(t test02 excluded file1.txt)),
    catfile( rel2abs(curdir()), qw(t test02 excluded file2.txt)),    
    catfile( rel2abs(curdir()), qw(t test02 dir2 file1.txt)),    # dir2 deliberately does not exist.
    catfile( rel2abs(curdir()), qw(t test02 dir2 file2.txt)),    
    catfile( rel2abs(curdir()), qw(t test02 dir3 file3.txt)),    
);

is( File::List::Object->new->add_file($file[0])->as_string, 
    $file[0],
    'adding single file' );

my $fl_clonetest = File::List::Object->new->load_array(@file[1, 2]);

is( $fl_clonetest->as_string, 
    "$file[1]\n$file[2]",
    'adding array' );
	
is( File::List::Object->clone($fl_clonetest)->as_string, 
    "$file[1]\n$file[2]",
    'cloning' );

is( File::List::Object->new->load_array(@file[1, 2, 5])->as_string, 
    "$file[1]\n$file[2]",
    'adding array with missing files' );
    
is( File::List::Object->new->add_files($file[0], $file[1])->remove_file($file[0])->as_string, 
    $file[1],
    'removing file' );
	
my $add1 = File::List::Object->new->add_file($file[0]);
my $add2 = File::List::Object->new->add_file($file[1]);

is( $add1->add($add2)->as_string,
    "$file[0]\n$file[1]",
    'addition' );
    
my $sub1 = File::List::Object->new->add_file($file[0])->add_file($file[1])
    ->add_file($file[2]);
my $sub2 = File::List::Object->new->add_file($file[1]);

is( $sub1->subtract($sub2)->as_string,
    "$file[0]\n$file[2]",
    'subtraction' );

my $filter = File::List::Object->new->load_array(@file);
my $re_1 = catdir( rel2abs(curdir()), qw(t test02 excluded));
my $re_2 = catdir( rel2abs(curdir()), qw(t test02 dir3));

is( $filter->filter([$re_1, $re_2])->as_string,
    "$file[0]\n$file[1]\n$file[2]",
    'filtering'); 

is( $filter->count, 3, 'counting');

is( $filter->clear->count, 0, 'clearing');
    
is (File::List::Object->new->add_file($file[0])->move($file[0], $file[6])->as_string,
    $file[6],
    'move a file' );

is (File::List::Object->new->load_array(@file[0, 1])
    ->move_dir(
        catdir( rel2abs(curdir()), qw(t test02)),
        catdir( rel2abs(curdir()), qw(t test02 dir2)))
    ->as_string,
    "$file[5]\n$file[6]",
    'move a directory' );
    
# Need to create a packlist
my $packlist_file = catfile(rel2abs(curdir()), qw(t test02 filelist.txt));
my $fh;
my $answer = open $fh, '>', $packlist_file;
if ($answer) {
	print $fh "$file[0]\n$file[2]\n$file[1]\n";
	close $fh;

	is (File::List::Object->new->load_file($packlist_file)->as_string,
		"$file[0]\n$file[1]\n$file[2]",
		'reading from packlist file' );

} else {
	fail('reading from packlist file'); 
	diag("Could not create packlist $packlist_file in test directory: $!.");
}

# Need to create a second packlist
my $packlist2_file = catfile(rel2abs(curdir()), qw(t test02 filelist2.txt));
my $fh2;
my $answer2 = open $fh2, '>', $packlist2_file;
if ($answer2) {
	print $fh2 "$file[0] test_attribute=$file[0]\n$file[2] test_attribute=$file[2]\n$file[1]\n";
	close $fh2;

	is (File::List::Object->new->load_file($packlist2_file)->as_string,
		"$file[0]\n$file[1]\n$file[2]",
		'reading from packlist file (with attributes)' );

} else {
	fail('reading from packlist file (with attributes)'); 
	diag("Could not create packlist $packlist2_file in test directory: $!.");
}

SKIP: {

	skip "Not on a Windows system", 1 if $^O ne 'MSWin32';

	# Need to create a third packlist
	my $packlist3_file = catfile(rel2abs(curdir()), qw(t test02 filelist3.txt));
	my $fh3;
	my $answer3 = open $fh3, '>', $packlist3_file;
	my $filetest = $file[1];
	$filetest =~ s{\\}{/}g;
	if ($answer3) {
		print $fh3 "$file[0] test_attribute=$file[0]\n$file[2] test_attribute=$file[2]\n${filetest}\n";
		close $fh3;

		is (File::List::Object->new->load_file($packlist3_file)->as_string,
			"$file[0]\n$file[1]\n$file[2]",
			'reading from packlist file (with Win32 filename fixes)' );
	} else {
		fail('reading from packlist file (with Win32 filename fixes)'); 
		diag("Could not create packlist $packlist3_file in test directory: $!.");
	}
}

is( File::List::Object->new->load_array(@file[1, 2, 3, 7])->as_string, 
    "$file[7]\n$file[3]\n$file[1]\n$file[2]",
    'as_string with mixed directories' );
