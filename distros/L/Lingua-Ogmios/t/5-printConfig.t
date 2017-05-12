use strict;
use warnings;

use Test::More tests => 2;

use Lingua::Ogmios;


my $NLPPlatform = Lingua::Ogmios->new('rcfile' => 'etc/ogmios/nlpplatform.rc');
$NLPPlatform->printConfig;
ok( defined($NLPPlatform) && ref $NLPPlatform eq 'Lingua::Ogmios',     'new() with rcfile works' );

$NLPPlatform->getConfig->addNLPTool('etc/ogmios/Faster.rc');
$NLPPlatform->printConfig;
ok( defined($NLPPlatform) && ref $NLPPlatform eq 'Lingua::Ogmios',     'new() with rcfile works' );


# my @words = ("Bacillus", "subtilis");
# my $RA2 = Lingua::ResourceAdequacy->new("word_list" => \@words);

# ok( defined($RA2) && ref $RA2 eq 'Lingua::ResourceAdequacy',     'new() works' );


# my @terms = ("Bacillus substilis", "B. substilis", "Bacillus substilis");

# my $RA3 = Lingua::ResourceAdequacy->new("word_list" => \@words, 
# 					      "term_list" => \@terms);

# ok( defined($RA3) && ref $RA2 eq 'Lingua::ResourceAdequacy',     'new() works' );
