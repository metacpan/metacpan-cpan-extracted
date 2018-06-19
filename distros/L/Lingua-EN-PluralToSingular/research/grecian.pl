#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use lib 'lib';
use Lingua::EN::PluralToSingular 'to_singular';
my %words;
my $dic = '/home/ben/projects/pron-dic-db/spellings.txt';
open my $din, "<", $dic or die $!;
while (<$din>) {
    my ($word) = split /\s+/, $_;
    $words{$word} = 1;
}
close $din or die $!;

my $txt = 'grecian.txt';
open my $in, "<:encoding(utf8)", $txt or die $!;
while (<$in>) {
    chomp;
    my ($plural, $singular) = split /\s+/, $_;
    my $w = to_singular ($plural);
    if ($words{$w}) {
	print "$plural $w\n";
    }
}
close $in or die $!;
