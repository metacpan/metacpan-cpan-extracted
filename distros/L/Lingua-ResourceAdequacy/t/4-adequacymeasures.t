
use strict;
use warnings;

use Test::Simple tests => 2;

use Lingua::ResourceAdequacy;

my @words = ("Bacillus", "subtilis");
my @terms = ("Bacillus substilis", "B. substilis", "Bacillus substilis");
my @DUP = ("Bacillus", "subtilis", "Bacillus");
my @UP = ("Bacillus substilis", "Bacillus", "Bacillus");

my $RA = Lingua::ResourceAdequacy->new("word_list" => \@words, 
 				       "term_list" => \@terms,
				       "UP_list" => \@UP,
				       "DUP_list" => \@DUP);

ok(defined $RA, 'new() with all the arguments works');

$RA->term_list_stats();
$RA->word_list_stats();
$RA->UP_list_stats();
$RA->DUP_list_stats();

$RA->AdequacyMeasures();

ok(exists $RA->{"AdequacyMeasures"}, 'Computing adequacy measures with AdequacyMeasures() works');
