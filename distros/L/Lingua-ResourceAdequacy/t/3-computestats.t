
use strict;
use warnings;

use Test::Simple tests => 4;

use Lingua::ResourceAdequacy;

my @words = ("Bacillus", "subtilis");
my @terms = ("Bacillus substilis", "B. substilis", "Bacillus substilis");

my $RA = Lingua::ResourceAdequacy->new("word_list" => \@words, 
					      "term_list" => \@terms);
$RA->term_list_stats();
$RA->word_list_stats();

my @DUP = ("Bacillus", "subtilis", "Bacillus");
my @UP = ("Bacillus substilis", "Bacillus", "Bacillus");


$RA->set_UP_list(\@UP);
ok(exists $RA->{"UsefulPart"}, 'set_UP_list() works');

$RA->set_DUP_list(\@DUP);
ok(exists $RA->{"DecompUsefulPart"}, 'set_UP_list() works');

$RA->UP_list_stats();
ok(exists $RA->{"UsefulPart_stats"}, 'UP_list_stats() works');

$RA->DUP_list_stats();
ok(exists $RA->{"DecompUsefulPart_stats"}, 'DUP_list_stats() works');
