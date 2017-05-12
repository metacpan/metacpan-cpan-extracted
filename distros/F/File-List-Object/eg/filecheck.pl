#! perl

# Example of comparing two lists of files, a list of files that get 
# extracted from a .zip file, and a list of files that get installed when
# an .msi file finishes. The file lists are gotten using dir /s /w /b,
# and then the files are compared.
#
# This script is used to check whether there are files that were missed in
# creating the .msi's for Strawberry Perl. 

use File::List::Object 0.189; # There is a bug in clone() in previous versions. 

my $msi = File::List::Object->new()->load_file('spmsi.txt');
my $zip = File::List::Object->new()->load_file('spzip.txt');

my $not_in_msi = File::List::Object->clone($zip)->subtract($msi);
my $not_in_zip = File::List::Object->clone($msi)->subtract($zip);

print "Files not in MSI:\n";
print $not_in_msi->as_string;

print "\nFiles not in ZIP:\n";
print $not_in_zip->as_string;


