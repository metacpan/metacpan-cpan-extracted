package ECHR::OpenData;
use strict;
use warnings;
our $VERSION = '0.01';

use JSON;
use Data::Dumper;
use File::Spec;

=pod
USAGE:

my $whole_data_subfolder = "C:/pl/testing_cpan/echr_dl/echr_2_0_0/build/echr_database/raw/preprocessed_documents";
my $fn = "001-86725_parsed.json";
ECHR::OpenData::test_print($whole_data_subfolder, $fn);

=cut

$| = 1;

sub extract_hashref_from_file{
	my $dir = shift;
	my $fn = shift;
	my $full_file_path = File::Spec->catdir($dir, $fn);
	open FH, "<$full_file_path" or die $!;
	my $json_text = do {local $/; <FH>};
	my $perl_scalar = decode_json( $json_text );
	return $perl_scalar;
}

sub test_print{
	my $whole_data_subfolder = shift;
	printf "whole_data_subfolder = %s\n", $whole_data_subfolder;
    opendir(D, "$whole_data_subfolder") || die "Can't open directory $whole_data_subfolder: $!\n";
    my @file_list = readdir(D);
    my @aoh;
	my $count = 0;
    foreach my $entry (@file_list) {
		if($entry =~ /\.json$/){
			$count++;
			my $perl_scalar = extract_hashref_from_file($whole_data_subfolder, $entry);
			printf "%6d %s\n", $count, $perl_scalar->{__conclusion};
		}
    }
    closedir(D);
	return @aoh;
}

1;
