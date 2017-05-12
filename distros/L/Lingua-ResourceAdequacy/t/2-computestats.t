
use strict;
use warnings;

use Test::Simple tests => 3;

use Lingua::ResourceAdequacy;

my @words = ("Bacillus", "subtilis");
my @terms = ("Bacillus substilis", "B. substilis", "Bacillus substilis");

my $RA = Lingua::ResourceAdequacy->new("word_list" => \@words, 
					      "term_list" => \@terms);

ok( defined($RA) && ref $RA eq 'Lingua::ResourceAdequacy',     'new() with arguments works' );

$RA->term_list_stats();

ok(exists $RA->{"term_list_stats"}, 'term_list_stats() works');

$RA->word_list_stats();

ok(exists $RA->{"word_list_stats"}, 'word_list_stats() works');

