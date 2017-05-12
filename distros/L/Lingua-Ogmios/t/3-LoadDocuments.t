use strict;
use warnings;

use Test::More tests => 5;

use Lingua::Ogmios;
use Lingua::Ogmios::FileManager;

my $NLPPlatform = Lingua::Ogmios->new('rcfile' => 'etc/ogmios/nlpplatform-test.rc');

my $Filemanager = Lingua::Ogmios::FileManager->new($NLPPlatform->getConfig->getSupplementaryMagicFile);

my $type = $Filemanager->getType('.');
ok(defined($type) && ($type eq "directory"), 'FileManager->getType for directory works');

$type = $Filemanager->getType('examples/InputDocument.xml');
ok(defined($type) && ($type eq "text/xml ns=http://alvis.info/enriched/"), 'FileManager->getType for ALVIS XML (genuine format) works');

# More tests on file type later...


$NLPPlatform->loadDocuments(['examples/FrenchText.xml']);
ok(defined $NLPPlatform);

$NLPPlatform->loadDocuments(['examples/InputDocument3.xml']);
ok(defined $NLPPlatform);

# $NLPPlatform->loadDocuments(['examples/pmid10788508-v3.xml']);
# ok(defined $NLPPlatform);

$NLPPlatform->loadDocuments(['examples/OutputDocument4.xml']);
ok(defined $NLPPlatform);



# 
# $NLPPlatform->loadDocuments;
# ok( defined($NLPPlatform) && ref $NLPPlatform eq 'Lingua::Ogmios',     'new() with rcfile works' );

# my @words = ("Bacillus", "subtilis");
# my $RA2 = Lingua::ResourceAdequacy->new("word_list" => \@words);

# ok( defined($RA2) && ref $RA2 eq 'Lingua::ResourceAdequacy',     'new() works' );


# my @terms = ("Bacillus substilis", "B. substilis", "Bacillus substilis");

# my $RA3 = Lingua::ResourceAdequacy->new("word_list" => \@words, 
# 					      "term_list" => \@terms);

# ok( defined($RA3) && ref $RA2 eq 'Lingua::ResourceAdequacy',     'new() works' );
