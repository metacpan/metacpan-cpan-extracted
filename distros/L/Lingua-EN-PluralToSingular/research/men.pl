#!/home/ben/software/install/bin/perl
use warnings;
use strict;
my $dic = '/home/ben/projects/pron-dic-db/spellings.txt';
my @words;
open my $in, "<", $dic or die $!;
while (<$in>) {
    my ($word) = split /\s+/, $_;
    if ($word =~ /men$/) {
	print "$word\n";
    }
}
close $in or die $!;
