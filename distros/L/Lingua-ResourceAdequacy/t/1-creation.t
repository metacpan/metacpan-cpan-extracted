
use strict;
use warnings;

use Test::Simple tests => 5;

use Lingua::ResourceAdequacy;

my $RA = Lingua::ResourceAdequacy->new();

ok( defined($RA) && ref $RA eq 'Lingua::ResourceAdequacy',     'new() works' );

my @words = ("Bacillus", "subtilis");
my @terms = ("Bacillus substilis", "B. substilis", "Bacillus substilis");
my @DUP = ("Bacillus", "subtilis");
my @UP = ("Bacillus substilis");


$RA->set_word_list(\@words);

ok(exists $RA->{"word_list"}, 'set_word_list() works');

$RA->set_term_list(\@terms);

ok(exists $RA->{"term_list"}, 'set_term_list() works');

$RA->set_UP_list(\@UP);

ok(exists $RA->{"UsefulPart"}, 'set_UP_list() works');

$RA->set_DUP_list(\@DUP);

ok(exists $RA->{"DecompUsefulPart"}, 'set_DUP_list() works');

