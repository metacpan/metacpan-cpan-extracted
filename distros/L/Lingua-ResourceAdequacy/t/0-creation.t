
use strict;
use warnings;

use Test::Simple tests => 3;

use Lingua::ResourceAdequacy;

my $RA = Lingua::ResourceAdequacy->new();

ok( defined($RA) && ref $RA eq 'Lingua::ResourceAdequacy',     'new() works' );

my @words = ("Bacillus", "subtilis");
my $RA2 = Lingua::ResourceAdequacy->new("word_list" => \@words);

ok( defined($RA2) && ref $RA2 eq 'Lingua::ResourceAdequacy',     'new() works' );


my @terms = ("Bacillus substilis", "B. substilis", "Bacillus substilis");

my $RA3 = Lingua::ResourceAdequacy->new("word_list" => \@words, 
					      "term_list" => \@terms);

ok( defined($RA3) && ref $RA2 eq 'Lingua::ResourceAdequacy',     'new() works' );
