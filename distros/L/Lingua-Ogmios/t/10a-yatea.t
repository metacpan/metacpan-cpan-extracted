use strict;
use warnings;

use Test::More tests => 4;

use Lingua::Ogmios;
use Lingua::Ogmios::Annotations::Token;
use Lingua::Ogmios::Annotations::LogProcessing;

my $NLPPlatform = Lingua::Ogmios->new('rcfile' => 't/etc/nlpplatform-yatea.rc');


# $NLPPlatform->loadDocuments(['examples/FrenchText.xml']);
ok(defined $NLPPlatform, 'Creation of the platform works');

# $NLPPlatform->loadDocuments(['examples/InputDocument3.xml']);
# ok(defined $NLPPlatform);

# $NLPPlatform->loadDocuments(['examples/pmid10788508-v3.xml']);

# $NLPPlatform->tokenisation;

# print STDERR $NLPPlatform->XMLout;

# ok(defined $NLPPlatform);

my $doc= "examples/twodocs.xml";
warn "processing $doc\n";


# #$NLPPlatform->loadDocuments(['examples/FrenchText.xml']);
$NLPPlatform->loadDocuments([$doc]);

# warn keys($NLPPlatform->getDocumentCollection->[0]->getDocuments);
# warn $NLPPlatform->getDocumentCollection->[0]->getDocuments->{"73863"};

ok(scalar($NLPPlatform->getDocumentCollection->[0]->getDocumentList) > 0, 'Loading document works');


ok($NLPPlatform->tokenisation == 0, "tokenisation works");

# ok(defined($NLPPlatform->getDocumentCollection->[0]->getDocument('73863')->getAnnotations->getTokenLevel), 'tokenisation OK');

# #print STDERR $NLPPlatform->XMLout;

# my $tool_config = $NLPPlatform->getConfig->getNLPToolFromIndex("DEFT 2013 Named Entity Recognizer");
# my $wrapper = $tool_config->wrapper;

# # my $wrapper = $NLPPlatform->getConfig->getNLPToolFromIndex("DEFT 2013 Named Entity Recognizer")->wrapper;
# eval "require $wrapper";
# my $NLPTool = $wrapper->new($tool_config, $NLPPlatform->getConfig->getOgmiosTMPFILE, $NLPPlatform->getConfig->getOgmiosLOGFILE, 1, $NLPPlatform->getConfig->xmloutput_noStdXmlOutput);
# $NLPTool->_printRE(*STDERR);

ok($NLPPlatform->linguisticProcessing == 0, "Linguistic processing works");


# #print STDERR $NLPPlatform->XMLout;


# ok(defined $NLPPlatform);

